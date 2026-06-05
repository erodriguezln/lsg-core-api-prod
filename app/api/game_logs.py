# game_logs.py — lsg-core-api-prod
# Endpoints para recibir y consultar los output del sensor logger de cada mod.
# PATCH-10: requiere tabla game_session_logger en la BD.
#
# Endpoints:
#   POST /game-logs/sessions           → subir log de sesión (mod → API)
#   GET  /game-logs/sessions/{id}      → detalle de un log
#   GET  /game-logs/players/{pid}      → logs de un jugador
#   GET  /game-logs/videogames/{gid}   → logs de un videojuego

import json as _json
from datetime import datetime
from typing import Optional, Any

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field
from sqlalchemy import text
from sqlalchemy.orm import Session

from app.db import get_db
from app.security import (
    require_roles,
    guard_player_access,
    ROLE_ALL,
)

router = APIRouter()


# Schemas

class SessionLogUpload(BaseModel):
    """
    Payload que envía el mod al cerrar una sesión de juego.
    Compatible con los archivos .json que genera el sensor logger.
    """
    player_id:           int   = Field(..., description="id_players del jugador")
    videogame_id:        int   = Field(..., description="id_videogame del juego")
    session_start:       str   = Field(..., description="ISO-8601: inicio de sesión")
    session_end:         Optional[str] = Field(None, description="ISO-8601: cierre de sesión")
    mod_version:         Optional[str] = Field(None, description="Versión del mod/plugin")
    experiment_tag:      Optional[str] = Field(None, description="Etiqueta del experimento")
    id_lsg_game_session: Optional[int] = Field(None, description="FK a lsg_game_session (si fue abierta vía API)")

    # Métricas resumen (opcionales — se calculan desde raw_log si no se envían)
    total_points_earned: Optional[int] = Field(None, ge=0)
    total_points_spent:  Optional[int] = Field(None, ge=0)
    redemptions_count:   Optional[int] = Field(None, ge=0)

    # Timeline completo: lista de eventos del sensor logger
    raw_log: Any = Field(
        ...,
        description=(
            "Timeline completo de la sesión. Puede ser: "
            "lista de eventos [{type, timestamp, data}], "
            "dict con secciones {events, summary, redemptions}, "
            "o cualquier estructura JSON del logger del mod."
        ),
    )


# POST /game-logs/sessions — subir log de sesión

@router.post(
    "/sessions",
    status_code=201,
    dependencies=[Depends(require_roles(["admin", "researcher", "developer", "player"]))],
    summary="Subir log de sesión del sensor logger",
)
def upload_session_log(
    payload: SessionLogUpload,
    db: Session = Depends(get_db),
):
    """
    # POST /game-logs/sessions

    Recibe el output del sensor logger al cerrar una sesión de juego.

    El mod puede enviar el archivo .json directamente como body de este endpoint.

    **Campos obligatorios:** `player_id`, `videogame_id`, `session_start`, `raw_log`

    **`raw_log`:** acepta cualquier estructura JSON que genere el logger:
    - Lista de eventos: `[{type, timestamp, data}, ...]`
    - Dict con secciones: `{events: [...], summary: {...}, redemptions: [...]}`
    - Cualquier otra estructura — se guarda tal cual sin transformaciones

    **Métricas resumen opcionales:** si no se envían `total_points_earned`,
    `total_points_spent`, `redemptions_count`, se intentan extraer de `raw_log`.

    **Roles disponibles:** "admin", "researcher", "developer", "player"

    **cURL de ejemplo:**
    ```bash
    curl -X POST 'https://lsg.diinf.usach.cl/lsg-core-api/game-logs/sessions' \\
      -H 'Authorization: Bearer <TOKEN>' \\
      -H 'Content-Type: application/json' \\
      -d '{
        "player_id": 46,
        "videogame_id": 8,
        "session_start": "2026-06-05T10:00:00",
        "session_end":   "2026-06-05T11:30:00",
        "mod_version": "1.2.0",
        "experiment_tag": "LSG_C1_T1_CV",
        "total_points_earned": 45,
        "total_points_spent": 30,
        "redemptions_count": 2,
        "raw_log": {
          "events": [
            {"type": "session_start", "timestamp": "2026-06-05T10:00:00", "data": {}},
            {"type": "points_earned", "timestamp": "2026-06-05T10:15:00",
             "data": {"amount": 20, "reason": "quest_completed"}},
            {"type": "mechanic_redeemed", "timestamp": "2026-06-05T10:45:00",
             "data": {"mechanic": "Faster Attack Speed", "cost": 30}},
            {"type": "session_end",   "timestamp": "2026-06-05T11:30:00", "data": {}}
          ],
          "summary": {
            "total_play_time_minutes": 90,
            "quests_completed": 3,
            "enemies_defeated": 47
          }
        }
      }'
    ```
    """
    # Extraer métricas desde raw_log si no se enviaron explícitamente
    raw = payload.raw_log
    events_count      = 0
    points_earned     = payload.total_points_earned
    points_spent      = payload.total_points_spent
    redemptions_count = payload.redemptions_count

    if isinstance(raw, list):
        events_count = len(raw)
        if points_earned is None:
            points_earned = sum(
                e.get("data", {}).get("amount", 0)
                for e in raw
                if isinstance(e, dict) and e.get("type") == "points_earned"
            )
        if redemptions_count is None:
            redemptions_count = sum(
                1 for e in raw
                if isinstance(e, dict) and e.get("type") == "mechanic_redeemed"
            )
    elif isinstance(raw, dict):
        events = raw.get("events", [])
        events_count = len(events)
        if points_earned is None:
            points_earned = raw.get("summary", {}).get("total_points_earned", 0)
        if points_spent is None:
            points_spent = raw.get("summary", {}).get("total_points_spent", 0)
        if redemptions_count is None:
            redemptions_count = len(raw.get("redemptions", []))

    # Calcular duration_seconds
    duration_seconds = None
    if payload.session_start and payload.session_end:
        try:
            fmt = "%Y-%m-%dT%H:%M:%S"
            start_dt = datetime.fromisoformat(payload.session_start)
            end_dt   = datetime.fromisoformat(payload.session_end)
            duration_seconds = max(0, int((end_dt - start_dt).total_seconds()))
        except (ValueError, TypeError):
            pass

    # INSERT
    try:
        result = db.execute(
            text("""
                INSERT INTO game_session_logger (
                  id_lsg_game_session, id_players, id_videogame,
                  mod_version, session_start, session_end, duration_seconds,
                  total_points_earned, total_points_spent, redemptions_count,
                  events_count, raw_log, experiment_tag
                ) VALUES (
                  :session_id, :pid, :gid,
                  :mod_ver, :start, :end, :dur,
                  :earned, :spent, :redeems,
                  :ev_count, :raw_log, :exp_tag
                )
            """),
            {
                "session_id": payload.id_lsg_game_session,
                "pid":        payload.player_id,
                "gid":        payload.videogame_id,
                "mod_ver":    payload.mod_version,
                "start":      payload.session_start,
                "end":        payload.session_end,
                "dur":        duration_seconds,
                "earned":     points_earned or 0,
                "spent":      points_spent  or 0,
                "redeems":    redemptions_count or 0,
                "ev_count":   events_count,
                "raw_log":    _json.dumps(raw) if not isinstance(raw, str) else raw,
                "exp_tag":    payload.experiment_tag,
            },
        )
        db.commit()
        new_id = result.lastrowid
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=400, detail=f"Error guardando log de sesión: {e}")

    return {
        "status":                   "created",
        "id_game_session_logger":   new_id,
        "player_id":                payload.player_id,
        "videogame_id":             payload.videogame_id,
        "duration_seconds":         duration_seconds,
        "events_count":             events_count,
        "total_points_earned":      points_earned or 0,
        "total_points_spent":       points_spent  or 0,
        "redemptions_count":        redemptions_count or 0,
    }


# GET /game-logs/sessions/{id} — detalle de un log

@router.get(
    "/sessions/{log_id}",
    dependencies=[Depends(require_roles(["admin", "researcher", "developer"]))],
    summary="Detalle de un log de sesión",
)
def get_session_log(
    log_id: int,
    db: Session = Depends(get_db),
):
    """
    # GET /game-logs/sessions/{id}

    Retorna el log completo de una sesión, incluyendo el `raw_log` con el
    timeline completo enviado por el sensor logger.

    **Roles disponibles:** "admin", "researcher", "developer"
    """
    row = db.execute(
        text("SELECT * FROM game_session_logger WHERE id_game_session_logger = :id"),
        {"id": log_id},
    ).mappings().first()

    if not row:
        raise HTTPException(status_code=404, detail=f"Log {log_id} no encontrado.")

    result = dict(row)
    if isinstance(result.get("raw_log"), str):
        try:
            result["raw_log"] = _json.loads(result["raw_log"])
        except (ValueError, TypeError):
            pass
    return result


# GET /game-logs/players/{pid} — logs de un jugador

@router.get(
    "/players/{player_id}",
    dependencies=[Depends(guard_player_access)],
    summary="Logs de sesiones de un jugador",
)
def get_player_logs(
    player_id:      int,
    videogame_id:   Optional[int] = Query(None),
    experiment_tag: Optional[str] = Query(None),
    from_date:      Optional[str] = Query(None, description="YYYY-MM-DD"),
    to_date:        Optional[str] = Query(None, description="YYYY-MM-DD"),
    include_raw:    bool          = Query(False, description="Incluir raw_log en la respuesta"),
    limit:          int           = Query(50, ge=1, le=500),
    db: Session = Depends(get_db),
):
    """
    # GET /game-logs/players/{pid}

    Lista los logs de sesiones de un jugador, ordenados por fecha descendente.

    Por defecto NO incluye `raw_log` (solo métricas resumen) para respuestas
    más livianas. Usar `include_raw=true` para obtener el timeline completo.

    **Roles disponibles:** "player" (solo sus propios datos), "teacher", "researcher", "admin", "developer"
    """
    cols = """
        id_game_session_logger, id_lsg_game_session, id_players, id_videogame,
        mod_version, session_start, session_end, duration_seconds,
        total_points_earned, total_points_spent, redemptions_count,
        events_count, experiment_tag, uploaded_at
    """
    if include_raw:
        cols += ", raw_log"

    base = f"SELECT {cols} FROM game_session_logger WHERE id_players = :pid"
    params: dict = {"pid": player_id}

    if videogame_id:
        base += " AND id_videogame = :gid"; params["gid"] = videogame_id
    if experiment_tag:
        base += " AND experiment_tag = :etag"; params["etag"] = experiment_tag
    if from_date:
        base += " AND session_start >= :fd"; params["fd"] = from_date
    if to_date:
        base += " AND session_start <= :td"; params["td"] = to_date

    base += " ORDER BY session_start DESC LIMIT :limit"
    params["limit"] = limit

    rows = db.execute(text(base), params).mappings().all()

    result = []
    for r in rows:
        d = dict(r)
        if include_raw and isinstance(d.get("raw_log"), str):
            try:
                d["raw_log"] = _json.loads(d["raw_log"])
            except (ValueError, TypeError):
                pass
        result.append(d)

    return {"player_id": player_id, "count": len(result), "items": result}


# GET /game-logs/videogames/{gid} — logs de un videojuego

@router.get(
    "/videogames/{videogame_id}",
    dependencies=[Depends(require_roles(["admin", "researcher"]))],
    summary="Logs de sesiones de un videojuego (investigación)",
)
def get_videogame_logs(
    videogame_id:   int,
    experiment_tag: Optional[str] = Query(None),
    from_date:      Optional[str] = Query(None, description="YYYY-MM-DD"),
    to_date:        Optional[str] = Query(None, description="YYYY-MM-DD"),
    limit:          int           = Query(100, ge=1, le=1000),
    db: Session = Depends(get_db),
):
    """
    # GET /game-logs/videogames/{videogame_id}

    Lista todos los logs de sesiones de un videojuego. Solo métricas resumen,
    sin `raw_log` (usar `GET /game-logs/sessions/{id}` para el detalle completo).

    Compatible con análisis longitudinal FONDECYT.

    **Roles disponibles:** "admin", "researcher", "developer"
    """
    base = """
        SELECT
          gsl.id_game_session_logger,
          gsl.id_players,
          p.name       AS player_name,
          gsl.id_videogame,
          gsl.mod_version,
          gsl.session_start, gsl.session_end,
          gsl.duration_seconds,
          gsl.total_points_earned, gsl.total_points_spent,
          gsl.redemptions_count, gsl.events_count,
          gsl.experiment_tag, gsl.uploaded_at
        FROM game_session_logger gsl
        JOIN players p ON p.id_players = gsl.id_players
        WHERE gsl.id_videogame = :gid
    """
    params: dict = {"gid": videogame_id}

    if experiment_tag:
        base += " AND gsl.experiment_tag = :etag"; params["etag"] = experiment_tag
    if from_date:
        base += " AND gsl.session_start >= :fd"; params["fd"] = from_date
    if to_date:
        base += " AND gsl.session_start <= :td"; params["td"] = to_date

    base += " ORDER BY gsl.session_start DESC LIMIT :limit"
    params["limit"] = limit

    rows = db.execute(text(base), params).mappings().all()
    return {"videogame_id": videogame_id, "count": len(rows), "items": list(rows)}