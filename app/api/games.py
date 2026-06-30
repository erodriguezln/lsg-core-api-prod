import json
from datetime import datetime
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy import text
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError

from app.db import get_db

from app.security import (
    require_roles,
    guard_player_access,
    CurrentUser,
    ROLE_ALL,
)

router = APIRouter()

# Models

class RedeemRequest(BaseModel):
    modifiable_mechanic_videogame_id: int
    point_dimension_id: Optional[int] = None
    attribute_id: Optional[int] = None
    amount: int
    metadata: Optional[dict] = None


class SessionStartRequest(BaseModel):
    started_at: Optional[datetime] = None
    session_metrics: Optional[dict] = None
    plugin_version: Optional[str] = None
    settings: Optional[dict] = None


class SessionEndRequest(BaseModel):
    ended_at: Optional[datetime] = None

class ModifiableMechanicCreateRequest(BaseModel):
    name: str
    description: Optional[str] = None
    type: Optional[str] = None


class ModifiableMechanicVideogameCreateRequest(BaseModel):
    id_modifiable_mechanic: int
    options: Optional[dict] = None


class ConnectRequest(BaseModel):
    lsg_enabled: Optional[bool] = True
    plugin_version: Optional[str] = None
    settings: Optional[dict] = None


# Helpers

def _get_player_global_dimension_balance(
    db: Session,
    player_id: int,
    point_dimension_id: int,
    for_update: bool = False,
) -> int:
    """
    Balance GLOBAL por jugador + dimensión.
    Ignora id_videogame para permitir canje cross-game.
    Si for_update=True: usa FOR UPDATE para evitar double-spend en redeem.
    """
    sql = """
        SELECT COALESCE(SUM(
          CASE
            WHEN direction = 'CREDIT' THEN amount
            WHEN direction = 'DEBIT'  THEN -amount
            ELSE 0
          END
        ), 0) AS balance
        FROM points_ledger
        WHERE id_players = :pid
          AND id_point_dimension = :pdid
    """
    if for_update:
        sql += " FOR UPDATE"

    row = db.execute(
        text(sql),
        {"pid": player_id, "pdid": point_dimension_id},
    ).mappings().first()

    return int(row["balance"]) if row and row["balance"] is not None else 0


def _resolve_redeem_dimension(db: Session, payload: "RedeemRequest") -> int:
    """
    Resuelve id_point_dimension para el canje.
    Los puntos siempre van a la dimensión BASE — no se aceptan subdimensiones.
    Prioridad: attribute_id > point_dimension_id.
    """
    if payload.attribute_id is not None:
        row = db.execute(
            text("SELECT id_point_dimension FROM point_dimension "
                 "WHERE id_attributes = :v AND id_subattributes IS NULL LIMIT 1"),
            {"v": payload.attribute_id},
        ).mappings().first()
        if not row:
            raise HTTPException(status_code=404, detail={
                "code":    "ATTRIBUTE_DIMENSION_NOT_FOUND",
                "message": f"No existe dimensión BASE para attribute_id={payload.attribute_id}.",
                "hint":    "Consulta GET /admin/point-dimensions.",
            })
        return row["id_point_dimension"]

    elif payload.point_dimension_id is not None:
        row = db.execute(
            text("SELECT id_point_dimension, id_subattributes FROM point_dimension "
                 "WHERE id_point_dimension = :v LIMIT 1"),
            {"v": payload.point_dimension_id},
        ).mappings().first()
        if not row:
            raise HTTPException(status_code=404, detail={
                "code":    "POINT_DIMENSION_NOT_FOUND",
                "message": f"No existe id_point_dimension={payload.point_dimension_id}.",
            })
        if row["id_subattributes"] is not None:
            raise HTTPException(status_code=400, detail={
                "code":    "SUBATTRIBUTE_DIMENSION_NOT_ALLOWED",
                "message": f"id_point_dimension={payload.point_dimension_id} es de subatributo. Los canjes usan la dimensión BASE.",
                "hint":    "Usa attribute_id (ej: attribute_id=2 para FISICO_BASE).",
            })
        return payload.point_dimension_id

    else:
        raise HTTPException(status_code=422, detail={
            "code":    "DIMENSION_REQUIRED",
            "message": "Indica la dimensión: attribute_id o point_dimension_id (solo BASE).",
            "ejemplo": {"attribute_id": 2, "amount": 50, "modifiable_mechanic_videogame_id": 9},
        })


def _assert_mmv_exists_for_game(db: Session, game_id: int, mmv_id: int) -> None:
    """
    Valida que el id_modifiable_mechanic_videogame exista y pertenezca al juego del path.
    """
    row = db.execute(
        text(
            """
            SELECT 1
            FROM modifiable_mechanic_videogames
            WHERE id_modifiable_mechanic_videogame = :mmv_id
              AND id_videogame = :game_id
            """
        ),
        {"mmv_id": mmv_id, "game_id": game_id},
    ).mappings().first()

    if not row:
        raise HTTPException(
            status_code=404,
            detail={
                "code": "MODIFIABLE_MECHANIC_VIDEOGAME_NOT_FOUND",
                "message": "No existe modifiable_mechanic_videogame_id para el game_id indicado.",
                "game_id": game_id,
                "modifiable_mechanic_videogame_id": mmv_id,
            },
        )


# Videogames

@router.get("", dependencies=[Depends(require_roles(ROLE_ALL))])
def list_videogames(
    db: Session = Depends(get_db),
):
    """
    # GET /videogames

    **Roles disponibles:** "admin", "researcher", "teacher", "player", "developer"
    """
    rows = db.execute(
        text(
            """
            SELECT
              id_videogame,
              name,
              genre,
              description,
              engine,
              developer,
              publisher,
              launch,
              version,
              type,
              executable
            FROM videogame
            ORDER BY name
            """
        )
    ).mappings().all()
    return list(rows)


@router.get("/{game_id}", dependencies=[Depends(require_roles(ROLE_ALL))])
def get_videogame(
    game_id: int,
    db: Session = Depends(get_db),
):
    """
    # GET /videogames/{game_id}

    **Roles disponibles:** "admin", "researcher", "teacher", "player", "developer"
    """
    row = db.execute(
        text(
            """
            SELECT
              id_videogame,
              name,
              genre,
              description,
              engine,
              developer,
              publisher,
              launch,
              version,
              type,
              executable
            FROM videogame
            WHERE id_videogame = :id
            """
        ),
        {"id": game_id},
    ).mappings().first()

    if not row:
        raise HTTPException(status_code=404, detail="Videogame not found")

    return dict(row)


class VideogameCreateRequest(BaseModel):
    id_videogame: Optional[int] = None
    name: str
    genre: Optional[str] = None
    description: Optional[str] = None
    engine: Optional[str] = None
    developer: Optional[str] = None
    publisher: Optional[str] = None
    launch: Optional[str] = None
    version: Optional[str] = None
    type: Optional[str] = None
    executable: Optional[str] = None


@router.post("", status_code=201, dependencies=[Depends(require_roles(["admin", "researcher", "developer"]))])
def create_videogame(
    payload: VideogameCreateRequest,
    db: Session = Depends(get_db),
):
    """
    # POST /videogames

    Crea un nuevo videojuego.

    **Roles disponibles:** "admin", "researcher", "developer"    
    """
    exists = db.execute(
        text(
            """
            SELECT id_videogame
            FROM videogame
            WHERE LOWER(name) = LOWER(:name)
            LIMIT 1
            """
        ),
        {"name": payload.name},
    ).mappings().first()

    if exists:
        raise HTTPException(
            status_code=409,
            detail={
                "code": "VIDEOGAME_ALREADY_EXISTS",
                "message": "Ya existe un videojuego con ese nombre.",
                "id_videogame": exists["id_videogame"],
                "name": payload.name,
            },
        )

    params = {
        "id_videogame": payload.id_videogame,
        "name": payload.name,
        "genre": payload.genre,
        "description": payload.description,
        "engine": payload.engine,
        "developer": payload.developer,
        "publisher": payload.publisher,
        "launch": payload.launch,
        "version": payload.version,
        "type": payload.type,
        "executable": payload.executable
    }

    try:
        if payload.id_videogame is None:
            result = db.execute(
                text(
                    """
                    INSERT INTO videogame (
                      name, genre, description, engine, developer, publisher, launch, version, type, executable
                    ) VALUES (
                      :name, :genre, :description, :engine, :developer, :publisher, :launch, :version, :type, :executable
                    )
                    """
                ),
                params,
            )
            new_id = int(result.lastrowid)
        else:
            db.execute(
                text(
                    """
                    INSERT INTO videogame (
                      id_videogame, name, genre, description, engine, developer, publisher, launch, version, type, executable
                    ) VALUES (
                      :id_videogame, :name, :genre, :description, :engine, :developer, :publisher, :launch, :version, :type, :executable
                    )
                    """
                ),
                params,
            )
            new_id = int(payload.id_videogame)

        db.commit()

    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=400, detail=f"Error creating videogame: {e}")

    row = db.execute(
        text(
            """
            SELECT
              id_videogame, name, genre, description, engine, developer, publisher, launch, version, type, executable
            FROM videogame
            WHERE id_videogame = :id
            """
        ),
        {"id": new_id},
    ).mappings().first()

    return dict(row)


@router.put(
    "/{game_id}",
    dependencies=[Depends(require_roles(["admin", "researcher", "developer"]))],
)
def update_videogame(
    game_id: int,
    payload: VideogameUpdateRequest,
    db: Session = Depends(get_db),
):
    """
    # PUT /videogames/{game_id}

    Actualiza parcialmente los datos de un videojuego.
    Solo se modifican los campos enviados en el body; los campos ausentes
    o `null` se ignoran (semántica PATCH sobre PUT).

    **Roles disponibles:** "admin", "researcher", "developer"

    **cURL de ejemplo:**
    ```bash
    curl -X PUT 'https://lsg.diinf.usach.cl/lsg-core-api/videogames/54' \\
      -H 'Authorization: Bearer <TOKEN>' \\
      -H 'Content-Type: application/json' \\
      -d '{
        "version": "1.1",
        "description": "Descripción actualizada",
        "executable": "CyberSwipe.exe"
      }'
    ```
    """
    # 1. Verificar existencia
    exists = db.execute(
        text("SELECT id_videogame FROM videogame WHERE id_videogame = :id"),
        {"id": game_id},
    ).mappings().first()
    if not exists:
        raise HTTPException(status_code=404, detail="Videogame not found")

    # 2. Construir SET dinámico — solo campos no-None del payload
    fields = []
    params: dict = {"id": game_id}

    field_map = {
        "name":        payload.name,
        "genre":       payload.genre,
        "description": payload.description,
        "engine":      payload.engine,
        "developer":   payload.developer,
        "publisher":   payload.publisher,
        "launch":      payload.launch,
        "version":     payload.version,
        "type":        payload.type,
        "executable":  payload.executable,
    }

    for col, val in field_map.items():
        if val is not None:
            fields.append(f"{col} = :{col}")
            params[col] = val

    # 3. Si no se envió ningún campo, devolver el registro sin tocar la BD
    if not fields:
        return get_videogame(game_id, db)

    # 4. Conflicto de nombre único (solo si name cambia)
    if payload.name is not None:
        duplicate = db.execute(
            text(
                """
                SELECT id_videogame FROM videogame
                WHERE LOWER(name) = LOWER(:name)
                  AND id_videogame != :id
                LIMIT 1
                """
            ),
            {"name": payload.name, "id": game_id},
        ).mappings().first()
        if duplicate:
            raise HTTPException(
                status_code=409,
                detail={
                    "code":        "VIDEOGAME_NAME_CONFLICT",
                    "message":     "Ya existe otro videojuego con ese nombre.",
                    "id_videogame": duplicate["id_videogame"],
                    "name":        payload.name,
                },
            )

    # 5. Ejecutar UPDATE
    sql = "UPDATE videogame SET " + ", ".join(fields) + " WHERE id_videogame = :id"
    try:
        db.execute(text(sql), params)
        db.commit()
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=400, detail=f"Error updating videogame: {e}")

    return get_videogame(game_id, db)


@router.get("/{game_id}/mechanics", dependencies=[Depends(require_roles(ROLE_ALL))])
def get_videogame_mechanics(
    game_id: int,
    db: Session = Depends(get_db),
):
    """
    # GET /videogames/{game_id}/mechanics

    **Roles disponibles:** "admin", "researcher", "teacher", "player", "developer"
    """
    rows = db.execute(
        text(
            """
            SELECT
              mmv.id_modifiable_mechanic_videogame,
              mmv.id_videogame,
              (SELECT name FROM videogame WHERE id_videogame = mmv.id_videogame) AS videogame_name,
              mmv.options,
              mm.id_modifiable_mechanic,
              mm.name AS modifiable_mechanic_name,
              mm.description AS modifiable_mechanic_description,
              mm.type AS modifiable_mechanic_type
            FROM modifiable_mechanic_videogames mmv
            JOIN modifiable_mechanic mm
              ON mmv.id_modifiable_mechanic = mm.id_modifiable_mechanic
            WHERE mmv.id_videogame = :game_id
            """
        ),
        {"game_id": game_id},
    ).mappings().all()

    result = []
    for row in rows:
        r = dict(row)
        # options stored as JSON string in MySQL → parse to dict
        if r.get("options") and isinstance(r["options"], str):
            try:
                r["options"] = json.loads(r["options"])
            except (ValueError, TypeError):
                pass
        result.append(r)
    return result


# Redemptions

@router.post("/{game_id}/players/{player_id}/redeem/preview", dependencies=[Depends(guard_player_access)])
def preview_redeem_mechanic(
    game_id: int,
    player_id: int,
    payload: RedeemRequest,
    db: Session = Depends(get_db),
):
    """
    # POST /videogames/{game_id}/players/{player_id}/redeem/preview

    **Roles disponibles:** "admin", "researcher", "teacher", "player", "developer"
    """
    _assert_mmv_exists_for_game(db, game_id, payload.modifiable_mechanic_videogame_id)

    resolved_pd_id = _resolve_redeem_dimension(db, payload)

    current_balance = _get_player_global_dimension_balance(
        db=db,
        player_id=player_id,
        point_dimension_id=resolved_pd_id,
        for_update=False,
    )

    would_be_enough = current_balance >= payload.amount
    new_balance = current_balance - payload.amount if would_be_enough else current_balance

    return {
        "can_redeem": would_be_enough,
        "current_balance": current_balance,
        "required_amount": payload.amount,
        "resulting_balance": new_balance,
        "game_id": game_id,
        "player_id": player_id,
        "point_dimension_id": resolved_pd_id,
        "modifiable_mechanic_videogame_id": payload.modifiable_mechanic_videogame_id,
    }


@router.post("/{game_id}/players/{player_id}/redeem", dependencies=[Depends(guard_player_access)])
def redeem_mechanic(
    game_id: int,
    player_id: int,
    payload: RedeemRequest,
    db: Session = Depends(get_db),
):
    """
    # POST /videogames/{game_id}/players/{player_id}/redeem

    **Roles disponibles:** "admin", "researcher", "teacher", "player", "developer"
    """
    from uuid import uuid4
    import json

    _assert_mmv_exists_for_game(db, game_id, payload.modifiable_mechanic_videogame_id)

    resolved_pd_id = _resolve_redeem_dimension(db, payload)

    current_balance = _get_player_global_dimension_balance(
        db=db,
        player_id=player_id,
        point_dimension_id=resolved_pd_id,
        for_update=True,
    )

    if current_balance < payload.amount:
        raise HTTPException(
            status_code=400,
            detail={
                "code": "INSUFFICIENT_POINTS",
                "message": "Saldo insuficiente para realizar el canje.",
                "current_balance": current_balance,
                "required_amount": payload.amount,
                "game_id": game_id,
                "player_id": player_id,
                "point_dimension_id": resolved_pd_id,
            },
        )

    source_ref = f"REDEMPTION-{uuid4()}"

    try:
        with db.begin_nested():
            result = db.execute(
                text(
                    """
                    INSERT INTO points_ledger (
                      id_players, id_point_dimension, id_videogame,
                      direction, amount, source_type, source_ref, payload
                    ) VALUES (
                      :id_players, :id_point_dimension, :id_videogame,
                      'DEBIT', :amount, 'REDEMPTION', :source_ref, :payload
                    )
                    """
                ),
                {
                    "id_players": player_id,
                    "id_point_dimension": resolved_pd_id,
                    "id_videogame": game_id,
                    "amount": payload.amount,
                    "source_ref": source_ref,
                    "payload": json.dumps({
                        "modifiable_mechanic_videogame_id": payload.modifiable_mechanic_videogame_id,
                        "metadata": payload.metadata or {},
                    }),
                },
            )
            pl_id = result.lastrowid

            db.execute(
                text(
                    """
                    INSERT INTO redemption_event (
                      id_points_ledger, id_modifiable_mechanic_videogame, redeemed_points
                    ) VALUES (
                      :pl_id, :mmv_id, :points
                    )
                    """
                ),
                {
                    "pl_id": pl_id,
                    "mmv_id": payload.modifiable_mechanic_videogame_id,
                    "points": payload.amount,
                },
            )

        resulting_balance = current_balance - payload.amount

    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=400, detail=f"Error redeeming: {e}")

    # Registrar en interaction_logs (no bloqueante)
    try:
        db.execute(text("""
            INSERT INTO interaction_logs
              (id_players, id_videogame, event_type, occurred_at, metrics)
            VALUES (:pid, :gid, 'redeem', NOW(),
              JSON_OBJECT('pl_id',:pl_id,'amount',:amt,'dimension',:dim,
                          'resulting_balance',:bal,'mmv_id',:mmv))
        """), {"pid": player_id, "gid": game_id, "pl_id": pl_id,
               "amt": payload.amount, "dim": resolved_pd_id,
               "bal": resulting_balance, "mmv": payload.modifiable_mechanic_videogame_id})
        db.commit()
    except Exception:
        db.rollback()

    return {
        "status": "redeemed",
        "points_ledger_id": pl_id,
        "source_ref": source_ref,
        "current_balance": current_balance,
        "redeemed_amount": payload.amount,
        "resulting_balance": resulting_balance,
        "game_id": game_id,
        "player_id": player_id,
        "point_dimension_id": resolved_pd_id,
        "modifiable_mechanic_videogame_id": payload.modifiable_mechanic_videogame_id,
    }


# Game Sessions

def _get_or_create_player_videogame(
    db: Session,
    player_id: int,
    game_id: int,
    plugin_version: Optional[str],
    settings: Optional[dict],
) -> int:
    """Obtiene id_player_videogame o lo crea. Helper interno (sin inyección de deps)."""
    row = db.execute(
        text("""
            SELECT id_player_videogame
            FROM player_videogame
            WHERE id_players = :pid AND id_videogame = :gid
        """),
        {"pid": player_id, "gid": game_id},
    ).mappings().first()

    if row:
        db.execute(
            text("""
                UPDATE player_videogame
                SET last_seen = NOW(),
                    plugin_version = COALESCE(:plugin_version, plugin_version),
                    settings = COALESCE(:settings, settings)
                WHERE id_player_videogame = :pvg_id
            """),
            {
                "pvg_id": row["id_player_videogame"],
                "plugin_version": plugin_version,
                "settings": json.dumps(settings) if settings else None,
            },
        )
        return row["id_player_videogame"]

    result = db.execute(
        text("""
            INSERT INTO player_videogame (
              id_players, id_videogame, lsg_enabled,
              first_seen, last_seen, plugin_version, settings
            ) VALUES (
              :pid, :gid, 1, NOW(), NOW(), :plugin_version, :settings
            )
        """),
        {
            "pid": player_id,
            "gid": game_id,
            "plugin_version": plugin_version,
            "settings": json.dumps(settings) if settings else None,
        },
    )

    return result.lastrowid


@router.post("/{game_id}/players/{player_id}/sessions", dependencies=[Depends(guard_player_access)])
def start_session(
    game_id: int,
    player_id: int,
    payload: SessionStartRequest,
    db: Session = Depends(get_db),
):
    """
    # POST /videogames/{game_id}/players/{player_id}/sessions

    **Roles disponibles:** "admin", "researcher", "teacher", "player", "developer"
    """
    started_at = payload.started_at or datetime.utcnow()

    try:
        pvg_id = _get_or_create_player_videogame(
            db=db,
            player_id=player_id,
            game_id=game_id,
            plugin_version=payload.plugin_version,
            settings=payload.settings,
        )

        result = db.execute(
            text(
                """
                INSERT INTO lsg_game_session (
                  id_player_videogame, started_at, session_metrics
                ) VALUES (
                  :pvg_id, :started_at, :session_metrics
                )
                """
            ),
            {
                "pvg_id": pvg_id,
                "started_at": started_at,
                "session_metrics": json.dumps(payload.session_metrics)
                if payload.session_metrics
                else None,
            },
        )
        db.commit()
        session_id = result.lastrowid
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=400, detail=f"Error starting session: {e}")

    return {"status": "started", "id_session": session_id}


@router.patch("/{game_id}/players/{player_id}/sessions/{session_id}/end", dependencies=[Depends(guard_player_access)])
def end_session(
    game_id: int,
    player_id: int,
    session_id: int,
    payload: SessionEndRequest,
    db: Session = Depends(get_db),
):
    """
    # PATCH /videogames/{game_id}/players/{player_id}/sessions/{session_id}/end

    **Roles disponibles:** "admin", "researcher", "teacher", "player", "developer"
    """
    ended_at = payload.ended_at or datetime.utcnow()

    try:
        result = db.execute(
            text(
                """
                UPDATE lsg_game_session s
                JOIN player_videogame pvg
                  ON s.id_player_videogame = pvg.id_player_videogame
                SET s.ended_at = :ended_at
                WHERE s.id_lsg_game_session = :sid
                  AND pvg.id_players = :pid
                  AND pvg.id_videogame = :gid
                """
            ),
            {
                "ended_at": ended_at,
                "sid": session_id,
                "pid": player_id,
                "gid": game_id,
            },
        )
        if result.rowcount == 0:
            raise HTTPException(status_code=404, detail="Session not found")
        db.commit()
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=400, detail=f"Error ending session: {e}")

    # Registrar en interaction_logs (no bloqueante)
    try:
        db.execute(text("""
            INSERT INTO interaction_logs
              (id_players, id_videogame, event_type, occurred_at, metrics)
            VALUES (:pid, :gid, 'session_end', :ended_at,
              JSON_OBJECT('id_session', :sid, 'ended_at', :ended_at))
        """), {
            "pid": player_id,
            "gid": game_id,
            "sid": session_id,
            # strftime garantiza formato compatible con MySQL TIMESTAMP
            "ended_at": ended_at.strftime('%Y-%m-%d %H:%M:%S'),
        })
        db.commit()
    except Exception:
        db.rollback()  # no bloqueante: sesión ya fue guardada

    return {"status": "ended", "id_session": session_id}


# Mechanics

@router.post("/mechanics/catalog", status_code=201, dependencies=[Depends(require_roles(["admin", "researcher", "developer"]))])
def create_modifiable_mechanic(
    payload: ModifiableMechanicCreateRequest,
    db: Session = Depends(get_db),
):
    """
    # POST /videogames/mechanics/catalog

    **Roles disponibles:** "admin", "researcher", "developer"  
    """
    exists = db.execute(
        text("""
            SELECT id_modifiable_mechanic
            FROM modifiable_mechanic
            WHERE LOWER(name) = LOWER(:name)
            LIMIT 1
        """),
        {"name": payload.name},
    ).mappings().first()

    if exists:
        raise HTTPException(
            status_code=409,
            detail={
                "code": "MECHANIC_ALREADY_EXISTS",
                "message": "Ya existe una mecánica con ese name.",
                "id_modifiable_mechanic": exists["id_modifiable_mechanic"],
                "name": payload.name,
            },
        )

    try:
        result = db.execute(
            text("""
                INSERT INTO modifiable_mechanic (name, description, type)
                VALUES (:name, :description, :type)
            """),
            {
                "name": payload.name,
                "description": payload.description,
                "type": payload.type,
            },
        )
        db.commit()
        new_id = int(result.lastrowid)
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=400, detail=f"Error creating mechanic: {e}")

    row = db.execute(
        text("""
            SELECT id_modifiable_mechanic, name, description, type
            FROM modifiable_mechanic
            WHERE id_modifiable_mechanic = :id
        """),
        {"id": new_id},
    ).mappings().first()

    return dict(row)


@router.post("/{game_id}/mechanics", status_code=201, dependencies=[Depends(require_roles(["admin", "researcher", "developer"]))])
def attach_mechanic_to_videogame(
    game_id: int,
    payload: ModifiableMechanicVideogameCreateRequest,
    db: Session = Depends(get_db),
):
    """
    # POST /videogames/{game_id}/mechanics

    **Roles disponibles:** "admin", "researcher", "developer"
    """
    vg = db.execute(
        text("SELECT 1 FROM videogame WHERE id_videogame = :gid"),
        {"gid": game_id},
    ).mappings().first()
    if not vg:
        raise HTTPException(status_code=404, detail="Videogame not found")

    mech = db.execute(
        text("SELECT 1 FROM modifiable_mechanic WHERE id_modifiable_mechanic = :mid"),
        {"mid": payload.id_modifiable_mechanic},
    ).mappings().first()
    if not mech:
        raise HTTPException(status_code=404, detail="Modifiable mechanic not found")

    exists = db.execute(
        text("""
            SELECT id_modifiable_mechanic_videogame
            FROM modifiable_mechanic_videogames
            WHERE id_videogame = :gid AND id_modifiable_mechanic = :mid
            LIMIT 1
        """),
        {"gid": game_id, "mid": payload.id_modifiable_mechanic},
    ).mappings().first()

    if exists:
        raise HTTPException(
            status_code=409,
            detail={
                "code": "MECHANIC_ALREADY_ATTACHED",
                "message": "La mecánica ya está asociada a este juego.",
                "id_modifiable_mechanic_videogame": exists["id_modifiable_mechanic_videogame"],
                "game_id": game_id,
                "id_modifiable_mechanic": payload.id_modifiable_mechanic,
            },
        )

    try:
        result = db.execute(
            text("""
                INSERT INTO modifiable_mechanic_videogames (id_videogame, id_modifiable_mechanic, options)
                VALUES (:gid, :mid, :options)
            """),
            {
                "gid": game_id,
                "mid": payload.id_modifiable_mechanic,
                "options": json.dumps(payload.options) if payload.options else None,
            },
        )
        db.commit()
        mmv_id = int(result.lastrowid)
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=400, detail=f"Error attaching mechanic: {e}")

    return {
        "id_modifiable_mechanic_videogame": mmv_id,
        "game_id": game_id,
        "id_modifiable_mechanic": payload.id_modifiable_mechanic,
        "options": payload.options,
    }


@router.post("/{game_id}/players/{player_id}/connect", dependencies=[Depends(guard_player_access)])
def connect_player_videogame(
    game_id: int,
    player_id: int,
    payload: ConnectRequest,
    db: Session = Depends(get_db),
):
    """
    # POST /videogames/{game_id}/players/{player_id}/connect

    **Roles disponibles:** "admin", "researcher", "teacher", "player", "developer"
    """
    enabled_val = 1 if (payload.lsg_enabled is None or payload.lsg_enabled) else 0
    settings_json = json.dumps(payload.settings) if payload.settings is not None else None

    try:
        db.execute(
            text(
                """
                INSERT INTO player_videogame (
                  id_players, id_videogame, lsg_enabled,
                  first_seen, last_seen, plugin_version, settings
                ) VALUES (
                  :pid, :gid, :enabled, NOW(), NOW(), :plugin_version, :settings
                )
                ON DUPLICATE KEY UPDATE
                  lsg_enabled    = VALUES(lsg_enabled),
                  last_seen      = NOW(),
                  plugin_version = COALESCE(VALUES(plugin_version), plugin_version),
                  settings       = COALESCE(VALUES(settings), settings)
                """
            ),
            {
                "pid": player_id,
                "gid": game_id,
                "enabled": enabled_val,
                "plugin_version": payload.plugin_version,
                "settings": settings_json,
            },
        )
        db.commit()

    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=400, detail=f"Error connecting player to videogame: {e}")

    return {
        "status": "ok",
        "player_id": player_id,
        "game_id": game_id,
        "lsg_enabled": bool(enabled_val),
        "plugin_version": payload.plugin_version,
    }


class BulkMechanicItem(BaseModel):
    name:        str
    description: Optional[str] = None
    type:        Optional[str] = None
    options:     Optional[dict] = None
 
 
class BulkMechanicsRequest(BaseModel):
    mechanics: list = []


@router.post(
    "/{game_id}/mechanics/bulk",
    status_code=207,
    summary="Carga masiva de mecánicas para un videojuego",
    dependencies=[Depends(require_roles(["admin", "researcher", "developer"]))],
)
def bulk_attach_mechanics(
    game_id: int,
    body: BulkMechanicsRequest,
    db: Session = Depends(get_db),
):
    """
    # POST /videogames/{game_id}/mechanics/bulk

    Vincula un lote de mecánicas a un videojuego. Retorna HTTP 207 multi-status.
 
    Por cada ítem del lote:
    - Si la mecánica **no existe** (por nombre exacto) → la crea en el catálogo.
    - La vincula al juego en `modifiable_mechanic_videogames`.
    - Si el vínculo **ya existe** → lo omite (idempotente, status: "existing").
 
    **Tipos válidos:** `buff`, `nerf`, `speed`, `health`, `economy`, `modifier`
 
    **Roles disponibles:** "admin", "researcher", "developer"
 
    **cURL de ejemplo (Terraria — 2 mecánicas):**
    ```bash
    curl -X POST '/lsg-core-api/videogames/8/mechanics/bulk' \\
      -H 'Authorization: Bearer <TOKEN>' \\
      -H 'Content-Type: application/json' \\
      -d '{
        "mechanics": [
          {"name":"Faster Attack Speed","description":"...","type":"buff","options":{"multiplier":1.25}},
          {"name":"Reduced Gravity","description":"...","type":"modifier","options":{"gravity_multiplier":0.6}}
        ]
      }'
    ```
    """
    vg = db.execute(
        text("SELECT 1 FROM videogame WHERE id_videogame = :gid"),
        {"gid": game_id},
    ).mappings().first()
    if not vg:
        raise HTTPException(status_code=404, detail="Videogame not found")
 
    if not body.mechanics:
        raise HTTPException(status_code=400, detail="El lote de mecánicas está vacío")
 
    results = []
 
    for item in body.mechanics:
        # Soporte dict o BulkMechanicItem
        if isinstance(item, dict):
            name        = item.get("name", "")
            description = item.get("description")
            mtype       = item.get("type")
            options     = item.get("options")
        else:
            name        = item.name
            description = item.description
            mtype       = item.type
            options     = item.options
 
        if not name:
            results.append({"name": "", "status": "error", "detail": "Campo 'name' requerido"})
            continue
 
        try:
            # 1. Buscar o crear la mecánica en el catálogo
            existing_mech = db.execute(
                text("SELECT id_modifiable_mechanic FROM modifiable_mechanic WHERE name = :name LIMIT 1"),
                {"name": name},
            ).mappings().first()
 
            if existing_mech:
                mm_id  = existing_mech["id_modifiable_mechanic"]
                status = "existing"
            else:
                res = db.execute(
                    text("INSERT INTO modifiable_mechanic (name, description, type) VALUES (:name, :desc, :type)"),
                    {"name": name, "desc": description, "type": mtype},
                )
                mm_id  = res.lastrowid
                status = "created"
 
            # 2. Vincular al juego (idempotente)
            existing_link = db.execute(
                text("""SELECT id_modifiable_mechanic_videogame
                        FROM modifiable_mechanic_videogames
                        WHERE id_videogame = :gid
                          AND id_modifiable_mechanic = :mid
                        LIMIT 1"""),
                {"gid": game_id, "mid": mm_id},
            ).mappings().first()
 
            if existing_link:
                mmv_id = existing_link["id_modifiable_mechanic_videogame"]
            else:
                res2 = db.execute(
                    text("""INSERT INTO modifiable_mechanic_videogames
                              (id_videogame, id_modifiable_mechanic, options)
                            VALUES (:gid, :mid, :opts)"""),
                    {
                        "gid":  game_id,
                        "mid":  mm_id,
                        "opts": json.dumps(options) if options else None,
                    },
                )
                mmv_id = res2.lastrowid
 
            db.commit()
            results.append({
                "name":                             name,
                "status":                           status,
                "id_modifiable_mechanic":           mm_id,
                "id_modifiable_mechanic_videogame": mmv_id,
            })
 
        except Exception as e:
            db.rollback()
            results.append({"name": name, "status": "error", "detail": str(e)})
 
    synced  = sum(1 for r in results if r.get("status") in ("created", "existing"))
    errored = sum(1 for r in results if r.get("status") == "error")
 
    return {
        "game_id": game_id,
        "total":   len(results),
        "synced":  synced,
        "errors":  errored,
        "results": results,
    }
