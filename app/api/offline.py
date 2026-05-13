from __future__ import annotations

import json
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, List, Literal, Optional
from uuid import uuid4

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field
from sqlalchemy import text
from sqlalchemy.orm import Session

from app.db import get_db
from app.security import CurrentUser, get_current_user

router = APIRouter()

# Configuración

OFFLINE_MAX_AGE_DAYS      = 30
OFFLINE_MAX_AMOUNT        = 10_000
OFFLINE_FUTURE_MARGIN_SEC = 60

# Schemas

class OfflineEvent(BaseModel):
    """Un evento de puntos generado offline por el cliente (mod)."""
    client_ref:          str   = Field(
        ..., description="UUID único generado por el cliente; garantiza idempotencia"
    )
    client_generated_at: datetime = Field(
        ..., description="Timestamp del evento en el cliente (ISO-8601)"
    )
    point_dimension_id:  int
    direction:           Literal["CREDIT", "DEBIT"]
    amount:              int  = Field(..., gt=0, le=OFFLINE_MAX_AMOUNT)
    source_type:         str  = "OFFLINE_GAME"
    payload:             Optional[dict] = None


class OfflineSyncRequest(BaseModel):
    player_id:  int
    game_id:    int
    events:     List[OfflineEvent] = Field(..., min_length=1, max_length=500)


class OfflineEventResult(BaseModel):
    client_ref:       str
    status:           Literal["SYNCED", "REJECTED", "DUPLICATE"]
    id_points_ledger: Optional[int] = None
    rejection_reason: Optional[str] = None


class OfflineSyncResponse(BaseModel):
    total:     int
    synced:    int
    rejected:  int
    duplicate: int
    results:   List[OfflineEventResult]


# Helpers

def _validate_event_timing(event: OfflineEvent) -> Optional[str]:
    """
    Valida la ventana temporal del evento.
    Retorna mensaje de rechazo o None si es válido.
    """
    now_utc = datetime.now(timezone.utc)

    # Asegurar que client_generated_at tiene timezone
    evt_ts = event.client_generated_at
    if evt_ts.tzinfo is None:
        evt_ts = evt_ts.replace(tzinfo=timezone.utc)

    # Anti-futuro: no puede ser posterior a ahora + margen de clock skew
    if evt_ts > now_utc + timedelta(seconds=OFFLINE_FUTURE_MARGIN_SEC):
        return f"client_generated_at ({evt_ts.isoformat()}) es posterior a la hora actual"

    # Anti-antigüedad: no mayor a OFFLINE_MAX_AGE_DAYS
    cutoff = now_utc - timedelta(days=OFFLINE_MAX_AGE_DAYS)
    if evt_ts < cutoff:
        return (
            f"client_generated_at supera la ventana máxima de {OFFLINE_MAX_AGE_DAYS} días"
        )

    return None


# Endpoints

@router.post(
    "/sync",
    response_model=OfflineSyncResponse,
    status_code=207,   # Multi-status: algunos eventos pueden rechazarse
    summary="Sincronizar lote de puntos offline",
)
def sync_offline_events(
    body: OfflineSyncRequest,
    db: Session = Depends(get_db),
    current: CurrentUser = Depends(get_current_user),
):
    """
    # POST /offline/sync

    Sincroniza un lote de eventos de puntos generados offline por el mod
    del cliente (Starbound, BG3, etc.).

    Cada evento se procesa independientemente:
    - **SYNCED**: evento aceptado y aplicado al ledger.
    - **DUPLICATE**: `client_ref` ya existe en la cola (idempotente).
    - **REJECTED**: evento inválido (fuera de ventana, monto excedido, etc.).

    **Roles disponibles:** "admin"
    """
    elevated = {"admin"}
    if not any(r in elevated for r in current.roles):
        if current.player_id != body.player_id:
            raise HTTPException(
                status_code=403,
                detail={"code": "PLAYER_ACCESS_DENIED",
                        "message": "Solo puedes sincronizar tus propios puntos offline."},
            )

    results: List[OfflineEventResult] = []
    synced = rejected = duplicate = 0

    for event in body.events:

        # 1. Verificar idempotencia por client_ref
        existing = db.execute(
            text("SELECT status FROM offline_points_queue WHERE client_ref = :ref"),
            {"ref": event.client_ref},
        ).mappings().first()

        if existing:
            results.append(OfflineEventResult(
                client_ref=event.client_ref,
                status="DUPLICATE",
            ))
            duplicate += 1
            continue

        # 2. Validación de ventana temporal
        timing_error = _validate_event_timing(event)
        if timing_error:
            db.execute(
                text("""
                    INSERT INTO offline_points_queue
                      (id_players, id_videogame, id_point_dimension, direction, amount,
                       source_type, client_ref, client_generated_at, payload,
                       status, sync_attempt_at, rejection_reason)
                    VALUES
                      (:pid, :gid, :dim, :dir, :amt,
                       :stype, :ref, :gen_at, :payload,
                       'REJECTED', NOW(), :reason)
                """),
                {
                    "pid": body.player_id, "gid": body.game_id,
                    "dim": event.point_dimension_id, "dir": event.direction,
                    "amt": event.amount, "stype": event.source_type,
                    "ref": event.client_ref, "gen_at": event.client_generated_at,
                    "payload": json.dumps(event.payload) if event.payload else None,
                    "reason": timing_error,
                },
            )
            db.commit()
            results.append(OfflineEventResult(
                client_ref=event.client_ref,
                status="REJECTED",
                rejection_reason=timing_error,
            ))
            rejected += 1
            continue

        # 3. Verificar saldo si es DEBIT (anti-negativo)
        if event.direction == "DEBIT":
            balance = db.execute(
                text("""
                    SELECT COALESCE(SUM(
                      CASE WHEN direction='CREDIT' THEN amount
                           WHEN direction='DEBIT'  THEN -amount ELSE 0 END
                    ), 0) AS balance
                    FROM points_ledger
                    WHERE id_players=:pid AND id_point_dimension=:dim
                """),
                {"pid": body.player_id, "dim": event.point_dimension_id},
            ).scalar()

            if (balance or 0) < event.amount:
                reason = (
                    f"Saldo insuficiente (balance={balance}, requerido={event.amount})"
                )
                db.execute(
                    text("""
                        INSERT INTO offline_points_queue
                          (id_players, id_videogame, id_point_dimension, direction, amount,
                           source_type, client_ref, client_generated_at, payload,
                           status, sync_attempt_at, rejection_reason)
                        VALUES
                          (:pid, :gid, :dim, :dir, :amt,
                           :stype, :ref, :gen_at, :payload,
                           'REJECTED', NOW(), :reason)
                    """),
                    {
                        "pid": body.player_id, "gid": body.game_id,
                        "dim": event.point_dimension_id, "dir": event.direction,
                        "amt": event.amount, "stype": event.source_type,
                        "ref": event.client_ref, "gen_at": event.client_generated_at,
                        "payload": json.dumps(event.payload) if event.payload else None,
                        "reason": reason,
                    },
                )
                db.commit()
                results.append(OfflineEventResult(
                    client_ref=event.client_ref,
                    status="REJECTED",
                    rejection_reason=reason,
                ))
                rejected += 1
                continue

        # 4. Insertar en points_ledger
        try:
            source_ref = f"OFFLINE-{event.client_ref[:8]}"
            ledger_result = db.execute(
                text("""
                    INSERT INTO points_ledger
                      (id_players, id_point_dimension, id_videogame,
                       direction, amount, source_type, source_ref, payload, occurred_at)
                    VALUES
                      (:pid, :dim, :gid,
                       :dir, :amt, :stype, :ref, :payload, :occurred_at)
                """),
                {
                    "pid": body.player_id, "dim": event.point_dimension_id,
                    "gid": body.game_id,   "dir": event.direction,
                    "amt": event.amount,   "stype": event.source_type,
                    "ref": source_ref,
                    "payload": json.dumps({
                        "client_ref": event.client_ref,
                        **(event.payload or {}),
                    }),
                    "occurred_at": event.client_generated_at,
                },
            )
            ledger_id = ledger_result.lastrowid

            # 5. Registrar en cola como SYNCED
            db.execute(
                text("""
                    INSERT INTO offline_points_queue
                      (id_players, id_videogame, id_point_dimension, direction, amount,
                       source_type, client_ref, client_generated_at, payload,
                       status, sync_attempt_at, synced_at, id_points_ledger)
                    VALUES
                      (:pid, :gid, :dim, :dir, :amt,
                       :stype, :ref, :gen_at, :payload,
                       'SYNCED', NOW(), NOW(), :ledger_id)
                """),
                {
                    "pid": body.player_id, "gid": body.game_id,
                    "dim": event.point_dimension_id, "dir": event.direction,
                    "amt": event.amount, "stype": event.source_type,
                    "ref": event.client_ref, "gen_at": event.client_generated_at,
                    "payload": json.dumps(event.payload) if event.payload else None,
                    "ledger_id": ledger_id,
                },
            )
            db.commit()
            results.append(OfflineEventResult(
                client_ref=event.client_ref,
                status="SYNCED",
                id_points_ledger=ledger_id,
            ))
            synced += 1

        except Exception as e:
            db.rollback()
            reason = f"Error interno al insertar: {e}"
            results.append(OfflineEventResult(
                client_ref=event.client_ref,
                status="REJECTED",
                rejection_reason=reason,
            ))
            rejected += 1

    return OfflineSyncResponse(
        total     = len(body.events),
        synced    = synced,
        rejected  = rejected,
        duplicate = duplicate,
        results   = results,
    )


@router.get(
    "/queue",
    summary="Estado de la cola offline de un jugador",
)
def get_offline_queue(
    player_id: int = Query(...),
    status: Optional[Literal["PENDING", "SYNCED", "REJECTED", "DUPLICATE"]] = Query(None),
    limit: int = Query(50, ge=1, le=500),
    db: Session = Depends(get_db),
    current: CurrentUser = Depends(get_current_user),
):
    """ 
    # GET /offline/queue

    Consulta el estado de los eventos en la cola offline de un jugador.

    **Roles disponibles:** "admin", "researcher", "developer", "teacher"
    """
    elevated = {"admin", "researcher", "developer", "teacher"}
    if not any(r in elevated for r in current.roles):
        if current.player_id != player_id:
            raise HTTPException(status_code=403,
                                detail="Solo puedes consultar tu propia cola offline.")

    base = """
        SELECT id_offline_queue, id_players, id_videogame, id_point_dimension,
               direction, amount, source_type, client_ref, client_generated_at,
               status, sync_attempt_at, synced_at, id_points_ledger, rejection_reason,
               created_at
        FROM offline_points_queue
        WHERE id_players = :pid
    """
    params: Dict[str, Any] = {"pid": player_id, "limit": limit}

    if status:
        base += " AND status = :status"
        params["status"] = status

    base += " ORDER BY client_generated_at DESC LIMIT :limit"
    rows = db.execute(text(base), params).mappings().all()
    return {"player_id": player_id, "count": len(rows), "items": list(rows)}