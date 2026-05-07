from datetime import datetime
from typing import Literal, Optional, List

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel
from sqlalchemy import text
from sqlalchemy.orm import Session

from app.db import get_db
from app.security import (
    require_roles,
    guard_player_access,
    get_current_user,
    CurrentUser,
    ROLE_ALL,
)

router = APIRouter()


# Models

class SensorIngestRequest(BaseModel):
    player_id:                  int
    sensor_endpoint_id:         int
    players_sensor_endpoint_id: Optional[int]  = None
    raw_payload:                dict
    parsed_value:               Optional[float] = None
    status:                     Literal["OK", "ERROR", "IGNORED"] = "OK"
    error_message:              Optional[str]   = None
    occurred_at:                Optional[datetime] = None


class SensorCreateRequest(BaseModel):
    name:           str
    description:    Optional[str] = None
    base_url:       Optional[str] = None


class SensorEndpointCreateRequest(BaseModel):
    name:                str
    description:         Optional[str] = None
    url_endpoint:        Optional[str] = None
    token_parameters:    Optional[dict] = None
    specific_parameters: Optional[dict] = None
    watch_parameters:    Optional[dict] = None


class SensorPlayerLinkRequest(BaseModel):
    """Vincula un sensor online a un jugador (guarda tokens de autenticación)."""
    sensor_id:   int
    tokens:      Optional[dict] = None
    expires_at:  Optional[datetime] = None


class SensorEndpointPlayerLinkRequest(BaseModel):
    """Activa un sensor_endpoint para un jugador específico."""
    sensor_endpoint_id: int
    activated:          bool          = True
    schedule_time:      Optional[str] = None   # ej: "08:00" para ingesta diaria


# GET: catálogo de sensores

@router.get(
    "",
    dependencies=[Depends(require_roles(ROLE_ALL))],
    summary="Listado de sensores disponibles",
)
def list_sensors(db: Session = Depends(get_db)):
    """
    Devuelve el catálogo de proveedores de sensores online configurados en LSG.

    Ejemplos de sensores: Google Fit, Apple Health, Fitbit, Garmin, wearable propio.

    **Acceso:** todos los roles.
    """
    rows = db.execute(
        text("""
            SELECT id_online_sensor, name, description, base_url,
                   initiated_date, updated_at
            FROM   online_sensor
            ORDER  BY id_online_sensor
        """)
    ).mappings().all()
    return list(rows)


# POST: crear sensor

@router.post(
    "",
    status_code=201,
    dependencies=[Depends(require_roles(["admin", "researcher"]))],
    summary="Crear nuevo sensor (admin, researcher)",
)
def create_sensor(
    payload: SensorCreateRequest,
    db: Session = Depends(get_db),
):
    """
    Agrega un nuevo proveedor de sensor al catálogo LSG.

    Después de crear el sensor, usa `POST /sensors/{id}/endpoints`
    para agregar sus endpoints de ingestión.

    **Acceso:** admin, researcher.
    """
    try:
        result = db.execute(
            text("""
                INSERT INTO online_sensor (name, description, base_url, initiated_date)
                VALUES (:name, :desc, :base_url, CURDATE())
            """),
            {"name": payload.name, "desc": payload.description, "base_url": payload.base_url},
        )
        db.commit()
        new_id = result.lastrowid
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=400, detail=f"Error creando sensor: {e}")

    row = db.execute(
        text("SELECT * FROM online_sensor WHERE id_online_sensor = :id"),
        {"id": new_id},
    ).mappings().first()
    return dict(row)


# GET: endpoints de un sensor

@router.get(
    "/{sensor_id}/endpoints",
    dependencies=[Depends(require_roles(ROLE_ALL))],
    summary="Endpoints de un sensor",
)
def list_sensor_endpoints(
    sensor_id: int,
    db: Session = Depends(get_db),
):
    """
    Lista los endpoints de ingestión disponibles para un sensor.

    El `id_sensor_endpoint` obtenido aquí es el que se usa en
    `POST /sensors/ingest/webhook` como parámetro `sensor_endpoint_id`.

    **Acceso:** todos los roles.
    """
    rows = db.execute(
        text("""
            SELECT id_sensor_endpoint, sensor_endpoint_id_online_sensor,
                   name, description, url_endpoint,
                   token_parameters, specific_parameters, watch_parameters,
                   created_at, updated_at
            FROM   sensor_endpoint
            WHERE  sensor_endpoint_id_online_sensor = :sid
        """),
        {"sid": sensor_id},
    ).mappings().all()
    return list(rows)


# POST: crear endpoint de sensor

@router.post(
    "/{sensor_id}/endpoints",
    status_code=201,
    dependencies=[Depends(require_roles(["admin", "researcher"]))],
    summary="Agregar endpoint a un sensor (admin, researcher)",
)
def create_sensor_endpoint(
    sensor_id: int,
    payload: SensorEndpointCreateRequest,
    db: Session = Depends(get_db),
):
    """
    Agrega un endpoint de ingestión a un sensor existente.

    El `id_sensor_endpoint` generado es necesario para:
    - `POST /sensors/players/{player_id}/link-endpoint`
    - `POST /sensors/ingest/webhook`

    **Acceso:** admin, researcher.
    """
    import json
    try:
        result = db.execute(
            text("""
                INSERT INTO sensor_endpoint
                  (sensor_endpoint_id_online_sensor, name, description,
                   url_endpoint, token_parameters, specific_parameters, watch_parameters)
                VALUES
                  (:sid, :name, :desc, :url,
                   :token_params, :specific_params, :watch_params)
            """),
            {
                "sid":            sensor_id,
                "name":           payload.name,
                "desc":           payload.description,
                "url":            payload.url_endpoint,
                "token_params":   json.dumps(payload.token_parameters) if payload.token_parameters else None,
                "specific_params":json.dumps(payload.specific_parameters) if payload.specific_parameters else None,
                "watch_params":   json.dumps(payload.watch_parameters) if payload.watch_parameters else None,
            },
        )
        db.commit()
        new_id = result.lastrowid
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=400, detail=f"Error creando endpoint: {e}")

    row = db.execute(
        text("SELECT * FROM sensor_endpoint WHERE id_sensor_endpoint = :id"),
        {"id": new_id},
    ).mappings().first()
    return dict(row)


# GET: sensores de un jugador

@router.get(
    "/players/{player_id}",
    dependencies=[Depends(guard_player_access)],
    summary="Sensores vinculados a un jugador",
)
def get_player_sensors(
    player_id: int,
    db: Session = Depends(get_db),
):
    """
    Devuelve todos los sensores y endpoints activos asociados a un jugador.

    Incluye:
    - `id_players_online_sensor`: ID del vínculo jugador↔sensor (para desvincular).
    - `id_players_sensor_endpoint`: ID del vínculo jugador↔endpoint (para ingest).
    - `activated`: si el endpoint está activo para ingesta automática.

    **Acceso:** player (solo sus datos), teacher, researcher, admin.
    """
    rows = db.execute(
        text("""
            SELECT
              pos.id_players_online_sensor,
              pos.id_players,
              pos.id_online_sensor,
              os.name                    AS sensor_name,
              os.description             AS sensor_description,
              pos.tokens,
              pos.expires_at,
              pos.rotated_at,
              se.id_sensor_endpoint,
              se.name                    AS endpoint_name,
              se.description             AS endpoint_description,
              se.url_endpoint,
              pse.id_players_sensor_endpoint,
              pse.activated,
              pse.schedule_time
            FROM player_online_sensor pos
            JOIN online_sensor os
              ON pos.id_online_sensor = os.id_online_sensor
            LEFT JOIN players_sensor_endpoint pse
              ON pse.id_players = pos.id_players
            LEFT JOIN sensor_endpoint se
              ON se.id_sensor_endpoint = pse.Id_sensor_endpoint
            WHERE pos.id_players = :pid
        """),
        {"pid": player_id},
    ).mappings().all()
    return list(rows)


# POST: vincular sensor a jugador

@router.post(
    "/players/{player_id}/link",
    status_code=201,
    dependencies=[Depends(require_roles(["admin", "researcher"]))],
    summary="Vincular sensor a un jugador (admin, researcher)",
)
def link_sensor_to_player(
    player_id: int,
    payload: SensorPlayerLinkRequest,
    db: Session = Depends(get_db),
):
    """
    Asocia un sensor online a un jugador (crea entrada en `player_online_sensor`).

    **Flujo completo para un nuevo sensor:**
    1. `GET /sensors` → obtener `id_online_sensor` del sensor deseado.
    2. `POST /sensors/players/{player_id}/link` → vincular (este endpoint).
    3. `GET /sensors/{sensor_id}/endpoints` → obtener `id_sensor_endpoint`.
    4. `POST /sensors/players/{player_id}/link-endpoint` → activar endpoint.
    5. Ahora se puede usar `POST /sensors/ingest/webhook` con los IDs obtenidos.

    **Acceso:** admin, researcher.
    """
    import json
    try:
        result = db.execute(
            text("""
                INSERT INTO player_online_sensor
                  (id_players, id_online_sensor, tokens, expires_at)
                VALUES
                  (:pid, :sid, :tokens, :expires_at)
                ON DUPLICATE KEY UPDATE
                  tokens     = VALUES(tokens),
                  expires_at = VALUES(expires_at),
                  rotated_at = NOW()
            """),
            {
                "pid":        player_id,
                "sid":        payload.sensor_id,
                "tokens":     json.dumps(payload.tokens) if payload.tokens else None,
                "expires_at": payload.expires_at,
            },
        )
        db.commit()
        link_id = result.lastrowid or db.execute(
            text("""SELECT id_players_online_sensor FROM player_online_sensor
                    WHERE id_players=:pid AND id_online_sensor=:sid"""),
            {"pid": player_id, "sid": payload.sensor_id},
        ).scalar()
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=400, detail=f"Error vinculando sensor: {e}")

    return {
        "status": "linked",
        "id_players_online_sensor": link_id,
        "player_id": player_id,
        "sensor_id": payload.sensor_id,
    }


# POST: activar endpoint de sensor para jugador

@router.post(
    "/players/{player_id}/link-endpoint",
    status_code=201,
    dependencies=[Depends(require_roles(["admin", "researcher"]))],
    summary="Activar endpoint de sensor para un jugador (admin, researcher)",
)
def link_endpoint_to_player(
    player_id: int,
    payload: SensorEndpointPlayerLinkRequest,
    db: Session = Depends(get_db),
):
    """
    Activa un `sensor_endpoint` específico para un jugador.
    El `id_players_sensor_endpoint` generado es el que se usa en
    `POST /sensors/ingest/webhook` como `players_sensor_endpoint_id`.

    **Prerequisito:** el jugador ya debe estar vinculado al sensor padre
    via `POST /sensors/players/{player_id}/link`.

    **Acceso:** admin, researcher.
    """
    try:
        result = db.execute(
            text("""
                INSERT INTO players_sensor_endpoint
                  (id_players, Id_sensor_endpoint, activated, schedule_time)
                VALUES
                  (:pid, :seid, :activated, :schedule_time)
                ON DUPLICATE KEY UPDATE
                  activated     = VALUES(activated),
                  schedule_time = VALUES(schedule_time)
            """),
            {
                "pid":           player_id,
                "seid":          payload.sensor_endpoint_id,
                "activated":     1 if payload.activated else 0,
                "schedule_time": payload.schedule_time,
            },
        )
        db.commit()
        pse_id = result.lastrowid or db.execute(
            text("""SELECT id_players_sensor_endpoint FROM players_sensor_endpoint
                    WHERE id_players=:pid AND Id_sensor_endpoint=:seid"""),
            {"pid": player_id, "seid": payload.sensor_endpoint_id},
        ).scalar()
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=400, detail=f"Error activando endpoint: {e}")

    return {
        "status":                      "linked",
        "id_players_sensor_endpoint":  pse_id,
        "player_id":                   player_id,
        "sensor_endpoint_id":          payload.sensor_endpoint_id,
        "activated":                   payload.activated,
    }


# POST: ingest webhook

@router.post(
    "/ingest/webhook",
    summary="Ingestar evento de sensor",
)
def ingest_sensor_event(
    payload: SensorIngestRequest,
    db: Session = Depends(get_db),
    current: CurrentUser = Depends(get_current_user),
):
    """
    Inserta un evento de sensor en `sensor_ingest_event`.

    **Flujo para obtener los IDs requeridos:**

    | Campo | Cómo obtenerlo |
    |-------|----------------|
    | `sensor_endpoint_id` | `GET /sensors` → `GET /sensors/{id}/endpoints` → `id_sensor_endpoint` |
    | `players_sensor_endpoint_id` | `GET /sensors/players/{player_id}` → `id_players_sensor_endpoint` |
    | `player_id` | ID del jugador (visible en `GET /whoami` de lsg-auth) |

    Si `players_sensor_endpoint_id` es null, el evento se registra
    sin vínculo a un endpoint configurado (ingesta manual/directa).

    **Acceso:** todos los roles autenticados.
    - `player`: solo puede ingestar para su propio `player_id`.
    - `teacher / researcher / admin`: pueden ingestar para cualquier `player_id`.
    """
    import json

    # SECURITY: player solo puede ingestar sus propios datos
    elevated = {"admin", "researcher", "teacher"}
    if not any(r in elevated for r in current.roles):
        if current.player_id is None or current.player_id != payload.player_id:
            raise HTTPException(
                status_code=403,
                detail={
                    "code":    "PLAYER_ACCESS_DENIED",
                    "message": "Solo puedes ingestar datos de sensor para tu propio player_id.",
                },
            )

    occurred_at = payload.occurred_at or datetime.utcnow()

    try:
        result = db.execute(
            text("""
                INSERT INTO sensor_ingest_event (
                  id_players, id_players_sensor_endpoint, id_sensor_endpoint,
                  raw_payload, parsed_value, status, error_message, occurred_at
                ) VALUES (
                  :id_players, :id_pse, :id_se,
                  :raw_payload, :parsed_value, :status, :error_message, :occurred_at
                )
            """),
            {
                "id_players":   payload.player_id,
                "id_pse":       payload.players_sensor_endpoint_id,
                "id_se":        payload.sensor_endpoint_id,
                "raw_payload":  json.dumps(payload.raw_payload),
                "parsed_value": payload.parsed_value,
                "status":       payload.status,
                "error_message":payload.error_message,
                "occurred_at":  occurred_at,
            },
        )
        sie_id = result.lastrowid
        db.commit()
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=400, detail=f"Error ingesting sensor data: {e}")

    return {"status": "ok", "id_sensor_ingest_event": sie_id}


# GET: historial de ingestas de un jugador

@router.get(
    "/players/{player_id}/ingest-events",
    dependencies=[Depends(guard_player_access)],
    summary="Historial de eventos de sensor de un jugador",
)
def list_player_ingest_events(
    player_id: int,
    limit: int = Query(100, ge=1, le=500),
    db: Session = Depends(get_db),
):
    """
    Devuelve los últimos eventos de sensor ingresados para un jugador,
    ordenados por fecha de ocurrencia descendente.

    **Acceso:** player (solo sus datos), teacher, researcher, admin.
    """
    rows = db.execute(
        text("""
            SELECT
              id_sensor_ingest_event, id_players,
              id_players_sensor_endpoint, id_sensor_endpoint,
              raw_payload, parsed_value, status, error_message,
              occurred_at, created_at
            FROM sensor_ingest_event
            WHERE id_players = :pid
            ORDER BY occurred_at DESC
            LIMIT :limit
        """),
        {"pid": player_id, "limit": limit},
    ).mappings().all()
    return list(rows)