from __future__ import annotations

import json
import math
from datetime import date, timedelta
from typing import Any, Dict, List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel
from sqlalchemy import text
from sqlalchemy.orm import Session

from app.db import get_db
from app.security import CurrentUser, get_current_user

router = APIRouter()

# Constantes del modelo

T_MAX_MINUTES = 90.0    # límite de sesión para IAR
IAR_W1        = 0.6     # peso IC_LSG en IAR
IAR_W2        = 0.4     # peso tiempo en IAR (w1+w2=1)
WINDOW_DAYS   = 7       # ventana temporal del índice


# Schemas

class RawSignals(BaseModel):
    """
    Señales crudas de entrada. Todas opcionales: si falta una señal completa,
    la subdimensión se marca NA y no participa en la agregación.
    """
    MVPA_min_week:         Optional[float] = None  # Icf  - F2
    steps_day:             Optional[float] = None  # Icf  - F2
    resting_hr_bpm:        Optional[float] = None  # Isfg - F3, dirección '-'
    sleep_quality_score:   Optional[float] = None  # Isfg - F4
    memory_accuracy_pct:   Optional[float] = None  # Ipma - F1
    recall_speed_ms:       Optional[float] = None  # Ipma - F1, dirección '-'
    decision_accuracy_pct: Optional[float] = None  # Itd  - F1
    reaction_time_ms:      Optional[float] = None  # Itd  - F1, dirección '-'


class IC2ComputeRequest(BaseModel):
    player_id:            int
    version_tag:          str            = "v1.0"
    experiment_tag:       Optional[str]  = None
    session_time_minutes: Optional[float] = None   # para IAR (Ec.8)
    signals:              RawSignals


class IC2ComputeResponse(BaseModel):
    player_id:       int
    version_tag:     str
    window:          Dict[str, str]
    indices:         Dict[str, Optional[float]]
    rules_triggered: List[str]
    admissibility:   Dict[str, bool]
    id_ic2_result:   int


# Normalización F1-F4

def _normalize(value: Optional[float], cfg: dict) -> Optional[float]:
    """
    Aplica la estrategia de normalización del goalpost cfg.
    Retorna None si value es None (señal NA).
    cfg: {min, max, strategy, direction, [theta, alpha, ordinal_map]}
    """
    if value is None:
        return None

    xmin, xmax = cfg["min"], cfg["max"]
    strategy   = cfg["strategy"]
    direction  = cfg.get("direction", "+")

    if strategy == "F1":
        raw = (value - xmin) / (xmax - xmin) if xmax > xmin else 0.0

    elif strategy == "F2":
        raw = math.log(value + 1) / math.log(xmax + 1) if xmax > 0 else 0.0

    elif strategy == "F3":
        theta = cfg.get("theta", (xmin + xmax) / 2)
        alpha = cfg.get("alpha", 0.2)
        raw   = 1.0 / (1.0 + math.exp(alpha * (value - theta)))

    elif strategy == "F4":
        ordinal_map = cfg.get("ordinal_map", {0: 0.0, 1: 0.5})
        raw = ordinal_map.get(int(value), 1.0 if value >= 2 else 0.0)

    else:
        raw = 0.0

    normalized = max(0.0, min(1.0, raw))
    return round(1.0 - normalized if direction == "-" else normalized, 4)


def _arith_mean(*vals: Optional[float]) -> Optional[float]:
    valid = [v for v in vals if v is not None]
    return round(sum(valid) / len(valid), 4) if valid else None


def _geo_mean(*vals: Optional[float]) -> Optional[float]:
    """Promedio geométrico sin ponderación (Ec.5-7). None si todos son None."""
    valid = [v for v in vals if v is not None]
    if not valid:
        return None
    product = 1.0
    for v in valid:
        product *= max(v, 1e-9)
    return round(product ** (1.0 / len(valid)), 4)


# Catálogo de reglas R1-R6

def _evaluate_rules(IC_fis: Optional[float], IC_ment: Optional[float],
                    IC_LSG: Optional[float]) -> List[str]:
    rules: List[str] = []
    if IC_fis  is not None and IC_fis  >= 0.60: rules.append("R1")
    if IC_ment is not None and IC_ment >= 0.55: rules.append("R2")
    if (IC_LSG is not None and IC_LSG  >= 0.60
            and IC_fis  is not None and IC_fis  >= 0.60
            and IC_ment is not None and IC_ment >= 0.55):
        rules.append("R3")
    if IC_fis  is not None and IC_fis  <  0.40: rules.append("R4")
    if IC_ment is not None and IC_ment <  0.35: rules.append("R5")
    if (IC_fis  is not None and IC_fis  >= 0.70
            and IC_ment is not None and IC_ment >= 0.65):
        rules.append("R6")
    return rules


# Endpoints

@router.post("/compute", response_model=IC2ComputeResponse,
             summary="Calcular IC² LSG para un jugador")
def compute_ic2(
    body: IC2ComputeRequest,
    db: Session = Depends(get_db),
    current: CurrentUser = Depends(get_current_user),
):
    """
    # POST /ic2/compute

    Recibe señales crudas, normaliza con F1-F4, agrega con
    promedio geométrico y calcula IAR.
    Persiste en `ic2_result` e `interaction_logs` (trazabilidad).

    **Acceso:**
    - `player`: solo su propio IC².

    **Roles disponibles:** "admin", "researcher", "teacher", "student"
    """
    elevated = {"admin", "researcher", "teacher"}
    if not any(r in elevated for r in current.roles):
        if current.player_id != body.player_id:
            raise HTTPException(
                status_code=403,
                detail={"code": "PLAYER_ACCESS_DENIED",
                        "message": "Un player solo puede calcular su propio IC²."},
            )

    # 1. Goalposts versionados
    version_row = db.execute(
        text("""
            SELECT id_version, goalposts
            FROM ic2_goalpost_version
            WHERE version_tag = :tag AND is_active = 1 LIMIT 1
        """),
        {"tag": body.version_tag},
    ).mappings().first()

    if not version_row:
        raise HTTPException(
            status_code=404,
            detail=f"Versión de goalposts '{body.version_tag}' no encontrada.",
        )

    gp_raw = version_row["goalposts"]
    gp = gp_raw if isinstance(gp_raw, dict) else json.loads(gp_raw)
    s  = body.signals

    # 2. Normalizar indicadores
    Icf_MVPA   = _normalize(s.MVPA_min_week,         gp["Icf"]["MVPA"])
    Icf_steps  = _normalize(s.steps_day,              gp["Icf"]["steps"])
    Isfg_hr    = _normalize(s.resting_hr_bpm,         gp["Isfg"]["resting_hr"])
    Isfg_sleep = _normalize(s.sleep_quality_score,    gp["Isfg"]["sleep_quality"])
    Ipma_acc   = _normalize(s.memory_accuracy_pct,    gp["Ipma"]["memory_accuracy"])
    Ipma_spd   = _normalize(s.recall_speed_ms,        gp["Ipma"]["recall_speed_ms"])
    Itd_acc    = _normalize(s.decision_accuracy_pct,  gp["Itd"]["decision_accuracy"])
    Itd_rt     = _normalize(s.reaction_time_ms,       gp["Itd"]["reaction_time_ms"])

    # 3. Subdimensiones
    Icf  = _arith_mean(Icf_MVPA, Icf_steps)
    Isfg = _arith_mean(Isfg_hr,  Isfg_sleep)
    Ipma = _arith_mean(Ipma_acc, Ipma_spd)
    Itd  = _arith_mean(Itd_acc,  Itd_rt)

    # 4. Índices compuestos (Ec.5-7)
    IC_fis  = _geo_mean(Icf, Isfg)
    IC_ment = _geo_mean(Ipma, Itd)
    IC_LSG  = _geo_mean(Icf, Isfg, Ipma, Itd)

    # 5. IAR (Ec.8)
    IAR: Optional[float] = None
    if body.session_time_minutes is not None and IC_LSG is not None:
        Tj  = min(body.session_time_minutes, T_MAX_MINUTES)
        IAR = round(IAR_W1 * IC_LSG + IAR_W2 * (1.0 - Tj / T_MAX_MINUTES), 4)

    # 6. Admisibilidad y reglas
    admissibility   = {"Icf": Icf is not None, "Isfg": Isfg is not None,
                       "Ipma": Ipma is not None, "Itd": Itd is not None}
    rules_triggered = _evaluate_rules(IC_fis, IC_ment, IC_LSG)

    # 7. Ventana temporal
    window_end   = date.today()
    window_start = window_end - timedelta(days=WINDOW_DAYS - 1)

    # 8. Persistir en ic2_result
    try:
        result = db.execute(
            text("""
                INSERT INTO ic2_result
                  (id_players, id_version, window_start, window_end,
                   Icf, Isfg, Ipma, Itd, IC_fis, IC_ment, IC_LSG, IAR,
                   admissibility, raw_inputs, experiment_tag)
                VALUES
                  (:pid, :vid, :ws, :we,
                   :Icf, :Isfg, :Ipma, :Itd, :IC_fis, :IC_ment, :IC_LSG, :IAR,
                   :adm, :raw, :tag)
                ON DUPLICATE KEY UPDATE
                  Icf=VALUES(Icf), Isfg=VALUES(Isfg),
                  Ipma=VALUES(Ipma), Itd=VALUES(Itd),
                  IC_fis=VALUES(IC_fis), IC_ment=VALUES(IC_ment),
                  IC_LSG=VALUES(IC_LSG), IAR=VALUES(IAR),
                  admissibility=VALUES(admissibility),
                  raw_inputs=VALUES(raw_inputs)
            """),
            {
                "pid": body.player_id, "vid": version_row["id_version"],
                "ws":  window_start,   "we":  window_end,
                "Icf": Icf, "Isfg": Isfg, "Ipma": Ipma, "Itd": Itd,
                "IC_fis": IC_fis, "IC_ment": IC_ment,
                "IC_LSG": IC_LSG, "IAR": IAR,
                "adm": json.dumps(admissibility),
                "raw": json.dumps(body.signals.model_dump()),
                "tag": body.experiment_tag,
            },
        )
        ic2_id = result.lastrowid or db.execute(
            text("""SELECT id_ic2_result FROM ic2_result
                    WHERE id_players=:pid AND id_version=:vid AND window_start=:ws"""),
            {"pid": body.player_id, "vid": version_row["id_version"], "ws": window_start},
        ).scalar()
        db.commit()
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Error persistiendo IC²: {e}")

    # 9. Registrar en interaction_logs (no bloqueante)
    try:
        db.execute(
            text("""
                INSERT INTO interaction_logs
                  (id_players, id_videogame, event_type, experiment_tag,
                   occurred_at, metrics)
                VALUES (:pid, 0, 'ic2_compute', :tag, NOW(),
                   JSON_OBJECT('IC_fis',:IC_fis,'IC_ment',:IC_ment,
                               'IC_LSG',:IC_LSG,'IAR',:IAR,'rules',:rules))
            """),
            {"pid": body.player_id, "tag": body.experiment_tag,
             "IC_fis": IC_fis, "IC_ment": IC_ment, "IC_LSG": IC_LSG,
             "IAR": IAR, "rules": json.dumps(rules_triggered)},
        )
        db.commit()
    except Exception:
        db.rollback()

    return IC2ComputeResponse(
        player_id       = body.player_id,
        version_tag     = body.version_tag,
        window          = {"start": str(window_start), "end": str(window_end)},
        indices         = {"Icf": Icf, "Isfg": Isfg, "Ipma": Ipma, "Itd": Itd,
                           "IC_fis": IC_fis, "IC_ment": IC_ment,
                           "IC_LSG": IC_LSG, "IAR": IAR},
        rules_triggered = rules_triggered,
        admissibility   = admissibility,
        id_ic2_result   = int(ic2_id),
    )


@router.get("/history", summary="Historial de IC² de un jugador")
def get_ic2_history(
    player_id: int = Query(...),
    version_tag: Optional[str] = Query(None),
    experiment_tag: Optional[str] = Query(None),
    from_date: Optional[str] = Query(None, description="YYYY-MM-DD"),
    to_date: Optional[str] = Query(None, description="YYYY-MM-DD"),
    limit: int = Query(50, ge=1, le=500),
    db: Session = Depends(get_db),
    current: CurrentUser = Depends(get_current_user),
):
    """
    # GET /ic2/history

    Historial de resultados IC² de un jugador, ordenado cronológicamente inverso.

    **Roles disponibles:** "admin", "researcher", "teacher", "student"
    """
    elevated = {"admin", "researcher", "teacher"}
    if not any(r in elevated for r in current.roles):
        if current.player_id != player_id:
            raise HTTPException(status_code=403,
                                detail="Un player solo puede consultar su propio historial.")

    base = """
        SELECT r.id_ic2_result, r.id_players, v.version_tag,
               r.window_start, r.window_end,
               r.Icf, r.Isfg, r.Ipma, r.Itd,
               r.IC_fis, r.IC_ment, r.IC_LSG, r.IAR,
               r.admissibility, r.experiment_tag, r.computed_at
        FROM ic2_result r
        JOIN ic2_goalpost_version v ON v.id_version = r.id_version
        WHERE r.id_players = :pid
    """
    params: Dict[str, Any] = {"pid": player_id, "limit": limit}

    if version_tag:
        base += " AND v.version_tag = :vtag"
        params["vtag"] = version_tag
    if experiment_tag:
        base += " AND r.experiment_tag = :etag"
        params["etag"] = experiment_tag
    if from_date:
        base += " AND r.window_start >= :fd"
        params["fd"] = from_date
    if to_date:
        base += " AND r.window_end <= :td"
        params["td"] = to_date

    base += " ORDER BY r.computed_at DESC LIMIT :limit"
    rows = db.execute(text(base), params).mappings().all()
    items = []
    for r in rows:
        d = dict(r)
        if isinstance(d.get("admissibility"), str):
            try:
                d["admissibility"] = json.loads(d["admissibility"])
            except (ValueError, TypeError):
                pass
        items.append(d)
    return {"player_id": player_id, "count": len(items), "items": items}


@router.get("/goalposts", summary="Goalposts vigentes de una versión IC²")
def get_goalposts(
    version_tag: str = Query("v1.0"),
    db: Session = Depends(get_db),
    _: CurrentUser = Depends(get_current_user),
):
    """
    # GET /ic2/goalposts

    Retorna los goalposts y estrategias de normalización de una versión.

    **Roles disponibles:** "admin", "researcher", "teacher", "student"
    """
    row = db.execute(
        text("""SELECT version_tag, published_at, description, goalposts, is_active
                FROM ic2_goalpost_version WHERE version_tag = :tag LIMIT 1"""),
        {"tag": version_tag},
    ).mappings().first()

    if not row:
        raise HTTPException(status_code=404, detail=f"Versión '{version_tag}' no encontrada.")

    result = dict(row)
    # goalposts almacenado como JSON en MySQL - puede venir como string
    if isinstance(result.get("goalposts"), str):
        try:
            result["goalposts"] = json.loads(result["goalposts"])
        except (ValueError, TypeError):
            pass
    return result