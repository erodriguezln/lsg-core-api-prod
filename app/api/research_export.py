import csv
import hashlib
import io
import os
from datetime import datetime
from typing import Any, Dict, List, Optional, Annotated
from urllib.parse import unquote

from fastapi import APIRouter, Depends, HTTPException, Query
from fastapi.responses import Response
from pydantic import BeforeValidator
from sqlalchemy import text
from sqlalchemy.orm import Session
import json

from app.db import get_db
from app.security import (
    require_roles,
    guard_player_access,
    CurrentUser,
    ROLE_ALL,
)

router = APIRouter(prefix="/research/export", tags=["research-export"])


# Helpers

RESEARCH_PSEUDONYM_SALT = os.getenv("RESEARCH_PSEUDONYM_SALT", "change-me-for-prod")


def decode_ts(v: Any) -> Any:
    if isinstance(v, str):
        return unquote(v)
    return v


def _pseudonymize_player(player_id: Optional[int]) -> Optional[str]:
    """Genera un ID seudonimizado estable usando RESEARCH_PSEUDONYM_SALT."""
    if player_id is None:
        return None
    base = f"{RESEARCH_PSEUDONYM_SALT}:{player_id}".encode("utf-8")
    return hashlib.sha256(base).hexdigest()[:16]


def _apply_pseudonymization(
    rows: List[Dict[str, Any]],
    include_raw_ids: bool,
) -> List[Dict[str, Any]]:
    """Agrega player_pseudo y opcionalmente elimina id_players, player_name, player_email."""
    out: List[Dict[str, Any]] = []
    for r in rows:
        r = dict(r)
        pid = r.get("id_players")
        r["player_pseudo"] = _pseudonymize_player(pid)
        if not include_raw_ids:
            r.pop("id_players", None)
            r.pop("player_name", None)
            r.pop("player_email", None)
        out.append(r)
    return out


def _build_csv_response(rows: List[Dict[str, Any]], filename: str) -> Response:
    """Convierte lista de dicts a CSV y retorna Response."""
    buf = io.StringIO()
    if not rows:
        buf.write("")
    else:
        fieldnames = list(rows[0].keys())
        writer = csv.DictWriter(buf, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)
    content = buf.getvalue()
    buf.close()
    return Response(
        content=content,
        media_type="text/csv",
        headers={"Content-Disposition": f'attachment; filename="{filename}"'},
    )

# Functions

def _parse_json(value):
    """
    Convierte a dict/lista si es JSON string, o devuelve None si es null/None.
    Si falla el parsing, devuelve el valor original (raw).
    """
    if value is None:
        return None
    if isinstance(value, (dict, list)):
        return value
    # Si es string, intenta parsear
    try:
        return json.loads(value)
    except (json.JSONDecodeError, TypeError):
        return value


# Export: Points ledger

@router.get("/points", dependencies=[Depends(require_roles(["admin", "researcher", "developer"]))])
def export_points(
    from_ts: Optional[Annotated[datetime, BeforeValidator(decode_ts)]] = Query(
        None, description="YYYY-MM-DD HH:MM:SS (inicio ventana tiempo, opcional)"
    ),
    to_ts: Optional[Annotated[datetime, BeforeValidator(decode_ts)]] = Query(
        None, description="YYYY-MM-DD HH:MM:SS (fin ventana tiempo, opcional)"
    ),
    player_id: Optional[int] = Query(None, description="Filtra por id_players (opcional)"),
    videogame_id: Optional[int] = Query(None, description="Filtra por id_videogame (opcional)"),
    source_type: Optional[str] = Query(None, description="Filtra por source_type (ej. SENSOR, REDEMPTION)"),
    format: str = Query("json", pattern="^(json|csv)$", description="Formato: json o csv"),
    include_raw_ids: bool = Query(False, description="Si false, elimina id_players/nombre/email"),
    limit: Optional[int] = Query(None, ge=1, le=100000, description="Límite máximo de filas"),
    db: Session = Depends(get_db),
):
    """
    # GET /research/export/points

    Exporta movimientos de puntos (points_ledger) para análisis de investigación.
    Incluye seudonimización de identidad del jugador.

    **Roles disponibles:** "admin", "researcher", "developer"  
    """
    base = """
        SELECT
          pl.id_points_ledger,
          pl.id_players,
          p.name AS player_name,
          p.email AS player_email,
          pl.id_point_dimension,
          pd.code AS point_dimension_code,
          pd.name AS point_dimension_name,
          pl.id_videogame,
          vg.name AS videogame_name,
          pl.direction,
          pl.amount,
          pl.source_type,
          pl.source_ref,
          pl.payload,
          pl.occurred_at,
          pl.created_at,
          pl.id_sensor_ingest_event
        FROM points_ledger pl
        JOIN players p
          ON p.id_players = pl.id_players
        LEFT JOIN point_dimension pd
          ON pd.id_point_dimension = pl.id_point_dimension
        LEFT JOIN videogame vg
          ON vg.id_videogame = pl.id_videogame
    """

    conditions = []
    params: Dict[str, Any] = {}

    if from_ts is not None:
        conditions.append("pl.occurred_at >= :from_ts")
        params["from_ts"] = from_ts
    if to_ts is not None:
        conditions.append("pl.occurred_at <= :to_ts")
        params["to_ts"] = to_ts
    if player_id is not None:
        conditions.append("pl.id_players = :pid")
        params["pid"] = player_id
    if videogame_id is not None:
        conditions.append("pl.id_videogame = :vgid")
        params["vgid"] = videogame_id
    if source_type is not None:
        conditions.append("pl.source_type = :stype")
        params["stype"] = source_type

    if conditions:
        base += " WHERE " + " AND ".join(conditions)

    base += " ORDER BY pl.occurred_at"

    if limit is not None:
        base += " LIMIT :limit"
        params["limit"] = limit

    rows = db.execute(text(base), params).mappings().all()

    processed = []
    for r in rows:
        r = dict(r)
        r["payload"] = _parse_json(r.get("payload"))
        processed.append(r)
    data = _apply_pseudonymization(processed, include_raw_ids)

    if format == "csv":
        return _build_csv_response(data, "points_export.csv")

    return {"items": data, "count": len(data)}


# Export: Game sessions

@router.get("/sessions", dependencies=[Depends(require_roles(["admin", "researcher", "developer"]))])
def export_sessions(
    from_ts: Optional[Annotated[datetime, BeforeValidator(decode_ts)]] = Query(
        None, description="YYYY-MM-DD HH:MM:SS (inicio ventana tiempo, opcional)"
    ),
    to_ts: Optional[Annotated[datetime, BeforeValidator(decode_ts)]] = Query(
        None, description="YYYY-MM-DD HH:MM:SS (fin ventana tiempo, opcional)"
    ),
    player_id: Optional[int] = Query(None, description="Filtra por id_players (opcional)"),
    videogame_id: Optional[int] = Query(None, description="Filtra por id_videogame (opcional)"),
    format: str = Query("json", pattern="^(json|csv)$", description="Formato: json o csv"),
    include_raw_ids: bool = Query(False, description="Si false, elimina id_players/nombre/email"),
    limit: Optional[int] = Query(None, ge=1, le=100000, description="Límite máximo de filas"),
    db: Session = Depends(get_db),
):
    """
    # GET /research/export/sessions

    Exporta sesiones de juego (lsg_game_session + player_videogame + players).

    **Roles disponibles:** "admin", "researcher", "developer"  
    """
    base = """
        SELECT
          s.id_lsg_game_session,
          s.id_player_videogame,
          s.started_at,
          s.ended_at,
          s.duration_seconds,
          s.session_metrics,
          pvg.id_players,
          p.name AS player_name,
          p.email AS player_email,
          pvg.id_videogame,
          vg.name AS videogame_name
        FROM lsg_game_session s
        JOIN player_videogame pvg
          ON pvg.id_player_videogame = s.id_player_videogame
        JOIN players p
          ON p.id_players = pvg.id_players
        JOIN videogame vg
          ON vg.id_videogame = pvg.id_videogame
    """

    conditions = []
    params: Dict[str, Any] = {}

    if from_ts is not None:
        conditions.append("s.started_at >= :from_ts")
        params["from_ts"] = from_ts
    if to_ts is not None:
        conditions.append("s.started_at <= :to_ts")
        params["to_ts"] = to_ts
    if player_id is not None:
        conditions.append("pvg.id_players = :pid")
        params["pid"] = player_id
    if videogame_id is not None:
        conditions.append("pvg.id_videogame = :vgid")
        params["vgid"] = videogame_id

    if conditions:
        base += " WHERE " + " AND ".join(conditions)

    base += " ORDER BY s.started_at"

    if limit is not None:
        base += " LIMIT :limit"
        params["limit"] = limit

    rows = db.execute(text(base), params).mappings().all()

    processed = []
    for r in rows:
        r = dict(r)
        r["session_metrics"] = _parse_json(r.get("session_metrics"))
        processed.append(r)
    data = _apply_pseudonymization(processed, include_raw_ids)

    if format == "csv":
        return _build_csv_response(data, "sessions_export.csv")

    return {"items": data, "count": len(data)}


# Export: Sensor ingest

@router.get("/sensors", dependencies=[Depends(require_roles(["admin", "researcher", "developer"]))])
def export_sensors(
    from_ts: Optional[Annotated[datetime, BeforeValidator(decode_ts)]] = Query(
        None, description="YYYY-MM-DD HH:MM:SS (inicio ventana tiempo, opcional)"
    ),
    to_ts: Optional[Annotated[datetime, BeforeValidator(decode_ts)]] = Query(
        None, description="YYYY-MM-DD HH:MM:SS (fin ventana tiempo, opcional)"
    ),
    player_id: Optional[int] = Query(None, description="Filtra por id_players (opcional)"),
    sensor_endpoint_id: Optional[int] = Query(None, description="Filtra por id_sensor_endpoint"),
    format: str = Query("json", pattern="^(json|csv)$", description="Formato: json o csv"),
    include_raw_ids: bool = Query(False, description="Si false, elimina id_players/nombre/email"),
    limit: Optional[int] = Query(None, ge=1, le=100000, description="Límite máximo de filas"),
    db: Session = Depends(get_db),
):
    """
    # GET /research/export/sensors

    Exporta eventos de sensor (sensor_ingest_event) con contexto.
    Nota ética: incluye raw_payload tal como existe en la tabla.

    **Roles disponibles:** "admin", "researcher", "developer"  
    """
    base = """
        SELECT
          sie.id_sensor_ingest_event,
          sie.id_players,
          p.name AS player_name,
          p.email AS player_email,
          sie.id_players_sensor_endpoint,
          sie.id_sensor_endpoint,
          se.name AS sensor_endpoint_name,
          sie.raw_payload,
          sie.parsed_value,
          sie.status,
          sie.error_message,
          sie.occurred_at,
          sie.created_at
        FROM sensor_ingest_event sie
        JOIN players p
          ON p.id_players = sie.id_players
        LEFT JOIN sensor_endpoint se
          ON se.id_sensor_endpoint = sie.id_sensor_endpoint
    """

    conditions = []
    params: Dict[str, Any] = {}

    if from_ts is not None:
        conditions.append("sie.occurred_at >= :from_ts")
        params["from_ts"] = from_ts
    if to_ts is not None:
        conditions.append("sie.occurred_at <= :to_ts")
        params["to_ts"] = to_ts
    if player_id is not None:
        conditions.append("sie.id_players = :pid")
        params["pid"] = player_id
    if sensor_endpoint_id is not None:
        conditions.append("sie.id_sensor_endpoint = :seid")
        params["seid"] = sensor_endpoint_id

    if conditions:
        base += " WHERE " + " AND ".join(conditions)

    base += " ORDER BY sie.occurred_at"

    if limit is not None:
        base += " LIMIT :limit"
        params["limit"] = limit

    rows = db.execute(text(base), params).mappings().all()

    processed = []
    for r in rows:
        r = dict(r)
        r["raw_payload"] = _parse_json(r.get("raw_payload"))
        processed.append(r)
    data = _apply_pseudonymization(processed, include_raw_ids)

    if format == "csv":
        return _build_csv_response(data, "sensors_export.csv")

    return {"items": data, "count": len(data)}


# Export: IC² results

@router.get("/ic2", dependencies=[Depends(require_roles(["admin", "researcher", "developer"]))])
def export_ic2_results(
    from_date: Optional[str] = Query(
        None, description="YYYY-MM-DD (inicio ventana)"
    ),
    to_date: Optional[str] = Query(
        None, description="YYYY-MM-DD (fin ventana)"
    ),
    player_id: Optional[int] = Query(
        None, description="Filtra por id_players (opcional)"
    ),
    experiment_tag: Optional[str] = Query(
        None, description="Etiqueta personalizada (ej: LSG_C1_T1_CV)"
    ),
    version_tag: Optional[str] = Query(
        None, description="Versión de goalposts (default: todos)"
    ),
    format: str = Query(
        "json", pattern="^(json|csv)$", description="Formato de salida"
    ),
    include_raw_ids: bool = Query(
        False, description="Si false, elimina id_players/nombre/email"
    ),
    limit: Optional[int] = Query(
        None, ge=1, le=100000, description="Límite máximo de filas"
    ),
    db: Session = Depends(get_db),
):
    """
    # GET /research/export/ic2

    Exporta resultados IC² (ic2_result) para análisis.

    Incluye: índices IC² (Icf, Isfg, Ipma, Itd, IC_fis, IC_ment, IC_LSG, IAR),
    señales crudas (raw_inputs), admisibilidad por subdimensión, experiment_tag
    y ventana temporal. Soporta seudonimización de identidad del jugador.

    **Roles disponibles:** "admin", "researcher", "developer"  

    **cURL (CSV para análisis en R/Python):**
    ```bash
    curl -X GET '/lsg-core-api/research/export/ic2?experiment_tag=LSG_C1_T1_CV&format=csv' \\
      -H 'Authorization: Bearer <TOKEN>' --output ic2_export.csv
    ```
    """
    import json as _json

    base = """
        SELECT
          r.id_ic2_result,
          r.id_players,
          p.name AS player_name,
          p.email AS player_email,
          v.version_tag,
          r.window_start,
          r.window_end,
          r.Icf, r.Isfg, r.Ipma, r.Itd,
          r.IC_fis, r.IC_ment, r.IC_LSG, r.IAR,
          r.admissibility,
          r.raw_inputs,
          r.experiment_tag,
          r.computed_at
        FROM ic2_result r
        JOIN players p ON p.id_players = r.id_players
        JOIN ic2_goalpost_version v ON v.id_version = r.id_version
    """
    conditions, params = [], {}

    if from_date:
        conditions.append("r.window_start >= :fd");   params["fd"] = from_date
    if to_date:
        conditions.append("r.window_end <= :td");     params["td"] = to_date
    if player_id:
        conditions.append("r.id_players = :pid");     params["pid"] = player_id
    if experiment_tag:
        conditions.append("r.experiment_tag = :etag");params["etag"] = experiment_tag
    if version_tag:
        conditions.append("v.version_tag = :vtag");   params["vtag"] = version_tag

    if conditions:
        base += " WHERE " + " AND ".join(conditions)
    base += " ORDER BY r.id_players, r.window_start"
    if limit:
        base += " LIMIT :limit"; params["limit"] = limit

    rows = db.execute(text(base), params).mappings().all()

    # Parse JSON fields stored as strings
    data_raw = []
    for row in rows:
        r = dict(row)
        for field in ("admissibility", "raw_inputs"):
            if isinstance(r.get(field), str):
                try:
                    r[field] = _json.loads(r[field])
                except (ValueError, TypeError):
                    pass
        data_raw.append(r)

    data = _apply_pseudonymization(data_raw, include_raw_ids)

    if format == "csv":
        # Flatten JSON fields for CSV compatibility
        flat = []
        for r in data:
            row_flat = {}
            for k, v in r.items():
                if isinstance(v, (dict, list)):
                    row_flat[k] = str(v)
                else:
                    row_flat[k] = v
            flat.append(row_flat)
        return _build_csv_response(flat, "ic2_export.csv")

    return {"items": data, "count": len(data)}