from typing import Literal, Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field
from sqlalchemy import text
from sqlalchemy.orm import Session
import json

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

class PointsAdjustRequest(BaseModel):
    """
    Cuerpo para POST /players/{id}/points/adjust.

    Indica la dimensión usando **una** de estas opciones (prioridad: 1→2→3→4):

    | Campo               | Ejemplo          | Cuándo usar                              |
    |---------------------|------------------|------------------------------------------|
    | `attribute_id`      | 2                | Atributo base (Social=1, Físico=2, ...)  |
    | `subattribute_id`   | 6                | Subatributo (Condición Física=6, ...)    |
    | `dimension_code`    | "FISICO_BASE"    | Código exacto de point_dimension         |
    | `point_dimension_id`| 2                | FK directo (deprecado, backward-compat)  |

    Consulta GET /admin/point-dimensions para ver todas las dimensiones disponibles.
    """
    attribute_id:       Optional[int] = Field(
        None,
        description="id_attributes — RECOMENDADO (Social=1, Físico=2, Afectivo=3, Mental=4)"
    )
    subattribute_id:    Optional[int] = Field(
        None,
        description="id_subattributes — para dimensiones de subatributo (ej: Condición Física=6)"
    )
    dimension_code:     Optional[str] = Field(
        None,
        description="Código de point_dimension (ej: FISICO_BASE, CONDICION_FISICA, MENTAL_BASE)"
    )
    point_dimension_id: Optional[int] = Field(
        None,
        description="[DEPRECADO] FK directo a point_dimension. Usar attribute_id en su lugar."
    )

    direction:    Literal["CREDIT", "DEBIT"]
    amount:       int = Field(..., gt=0)
    reason:       Optional[str] = None
    videogame_id: Optional[int] = None

    model_config = {"populate_by_name": True}

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

# Attributes & Subattributes

@router.get("/attributes", tags=["attributes"], dependencies=[Depends(require_roles(ROLE_ALL))])
def list_attributes(
    db: Session = Depends(get_db),
):
    """
    # GET /attributes

    **Roles disponibles:** "admin", "researcher", "teacher", "player", "developer"    
    """
    rows = db.execute(
        text(
            """
            SELECT id_attributes, name, description, data_type, created_at, updated_at
            FROM attributes
            ORDER BY id_attributes
            """
        )
    ).mappings().all()
    return list(rows)


@router.get("/attributes/{attribute_id}/subattributes", tags=["attributes"], dependencies=[Depends(require_roles(ROLE_ALL))])
def list_subattributes(
    attribute_id: int,
    db: Session = Depends(get_db),
):
    """
    # GET /attributes/{attribute_id}/subattributes

    **Roles disponibles:** "admin", "researcher", "teacher", "player", "developer"    
    """
    rows = db.execute(
        text(
            """
            SELECT
              id_subattributes,
              name,
              description,
              created_at,
              updated_at
            FROM subattributes
            WHERE attributes_id_attributes = :attr_id
            ORDER BY id_subattributes
            """
        ),
        {"attr_id": attribute_id},
    ).mappings().all()
    return list(rows)


@router.get("/attributes-map", tags=["attributes"], dependencies=[Depends(require_roles(ROLE_ALL))])
def get_attributes_map(
    db: Session = Depends(get_db),
):
    """
    # GET /attributes-map

    Usa la función sp_get_att_subattributes_name() que retorna JSON.

    **Roles disponibles:** "admin", "researcher", "teacher", "player", "developer"    
    """
    row = db.execute(
        text("SELECT sp_get_att_subattributes_name() AS data")
    ).mappings().first()

    if not row or row["data"] is None:
        return []

    data = row["data"]
    # SQLAlchemy text() puede retornar JSON como string en MySQL
    if isinstance(data, str):
        import json
        try:
            data = json.loads(data)
        except (ValueError, TypeError):
            pass
    return data


# Points & Balances

@router.get("/players/{player_id}/points/balance", tags=["points"], dependencies=[Depends(guard_player_access)])
def get_player_points_balance(
    player_id: int,
    db: Session = Depends(get_db),
):
    """
    # GET /players/{player_id}/points/balance

    Lee desde v_points_balance.

    **Roles disponibles:** "admin", "researcher", "teacher", "player", "developer"    
    """
    rows = db.execute(
        text("""
            SELECT
              vpb.id_players,
              vpb.id_point_dimension,
              pd.code         AS dimension_code,
              pd.name         AS dimension_name,
              pd.id_attributes,
              a.name          AS attribute_name,
              pd.id_subattributes,
              s.name          AS subattribute_name,
              vpb.balance
            FROM v_points_balance vpb
            JOIN  point_dimension pd ON pd.id_point_dimension = vpb.id_point_dimension
            LEFT JOIN attributes   a ON a.id_attributes       = pd.id_attributes
            LEFT JOIN subattributes s ON s.id_subattributes   = pd.id_subattributes
            WHERE vpb.id_players = :player_id
            ORDER BY vpb.id_point_dimension
        """),
        {"player_id": player_id},
    ).mappings().all()

    return list(rows)


@router.get("/players/{player_id}/attributes/points", tags=["points"], dependencies=[Depends(guard_player_access)])
def get_player_attribute_points(
    player_id: int,
    db: Session = Depends(get_db),
):
    """
    # GET /players/{player_id}/attributes/points

    Usa la vista v_player_attribute_balance.

    **Roles disponibles:** "admin", "researcher", "teacher", "player", "developer"    
    """
    rows = db.execute(
        text(
            """
            SELECT
              id_players,
              player_name,
              player_email,
              id_attributes,
              attribute_name,
              balance_ledger,
              snapshot_points,
              diff_ledger_minus_snapshot
            FROM v_player_attribute_balance
            WHERE id_players = :player_id
            """
        ),
        {"player_id": player_id},
    ).mappings().all()

    return list(rows)


@router.get("/points/ledger", tags=["points"], dependencies=[Depends(require_roles(ROLE_ALL))])
def get_points_ledger(
    player_id: Optional[int] = Query(None),
    videogame_id: Optional[int] = Query(None),
    source_type: Optional[str] = Query(None),
    from_ts: Optional[str] = Query(None, description="YYYY-MM-DD HH:MM:SS"),
    to_ts: Optional[str] = Query(None, description="YYYY-MM-DD HH:MM:SS"),
    db: Session = Depends(get_db),
):
    """
    # GET /points/ledger

    Consulta filtrable del ledger de puntos.

    **Roles disponibles:** "admin", "researcher", "teacher", "player", "developer"    
    """
    base = """
        SELECT
          pl.id_points_ledger,
          pl.id_players,
          pl.id_point_dimension,
          pd.code         AS dimension_code,
          pd.name         AS dimension_name,
          COALESCE(pd.id_attributes, NULL)     AS id_attributes,
          a.name          AS attribute_name,
          pl.id_videogame,
          pl.direction,
          pl.amount,
          pl.source_type,
          pl.source_ref,
          pl.payload,
          pl.occurred_at,
          pl.created_at,
          pl.id_sensor_ingest_event
        FROM points_ledger pl
        LEFT JOIN point_dimension pd ON pd.id_point_dimension = pl.id_point_dimension
        LEFT JOIN attributes       a ON a.id_attributes       = pd.id_attributes
    """
    conditions = []
    params: dict = {}

    if player_id is not None:
        conditions.append("id_players = :player_id")
        params["player_id"] = player_id
    if videogame_id is not None:
        conditions.append("id_videogame = :videogame_id")
        params["videogame_id"] = videogame_id
    if source_type is not None:
        conditions.append("source_type = :source_type")
        params["source_type"] = source_type
    if from_ts is not None:
        conditions.append("occurred_at >= :from_ts")
        params["from_ts"] = from_ts
    if to_ts is not None:
        conditions.append("occurred_at <= :to_ts")
        params["to_ts"] = to_ts

    if conditions:
        base += " WHERE " + " AND ".join(conditions)

    base += " ORDER BY occurred_at DESC LIMIT 500"  # cap defensivo

    rows = db.execute(text(base), params).mappings().all()

    result = []
    for r in rows:
        d = dict(r)
        d["payload"] = _parse_json(d.get("payload"))
        result.append(d)
    return result


@router.post("/players/{player_id}/points/adjust", tags=["points"], dependencies=[Depends(require_roles(["admin", "researcher", "developer"]))])
def adjust_player_points(
    player_id: int,
    payload: PointsAdjustRequest,
    db: Session = Depends(get_db),
):
    """
    # POST /players/{player_id}/points/adjust

    Inserta un ajuste manual en points_ledger (source_type='ADJUST').

    **Roles disponibles:** "admin", "researcher", "developer"  
    """
    from uuid import uuid4
    import json

    source_ref = f"ADJUST-{uuid4()}"

    # ── Resolver id_point_dimension desde el argumento recibido ─────────────────
    # Prioridad: attribute_id > subattribute_id > dimension_code > point_dimension_id
    resolved_pd_id: Optional[int] = None

    if payload.attribute_id is not None:
        row = db.execute(
            text("SELECT id_point_dimension FROM point_dimension "
                 "WHERE id_attributes = :v LIMIT 1"),
            {"v": payload.attribute_id},
        ).mappings().first()
        if not row:
            raise HTTPException(status_code=404, detail={
                "code":    "ATTRIBUTE_DIMENSION_NOT_FOUND",
                "message": f"No existe dimensión de puntos para attribute_id={payload.attribute_id}.",
                "hint":    "Consulta GET /admin/point-dimensions para ver las dimensiones disponibles.",
            })
        resolved_pd_id = row["id_point_dimension"]

    elif payload.subattribute_id is not None:
        row = db.execute(
            text("SELECT id_point_dimension FROM point_dimension "
                 "WHERE id_subattributes = :v LIMIT 1"),
            {"v": payload.subattribute_id},
        ).mappings().first()
        if not row:
            raise HTTPException(status_code=404, detail={
                "code":    "SUBATTRIBUTE_DIMENSION_NOT_FOUND",
                "message": f"No existe dimensión de puntos para subattribute_id={payload.subattribute_id}.",
                "hint":    "Consulta GET /admin/point-dimensions para ver las dimensiones disponibles.",
            })
        resolved_pd_id = row["id_point_dimension"]

    elif payload.dimension_code is not None:
        row = db.execute(
            text("SELECT id_point_dimension FROM point_dimension "
                 "WHERE code = :v LIMIT 1"),
            {"v": payload.dimension_code},
        ).mappings().first()
        if not row:
            raise HTTPException(status_code=404, detail={
                "code":    "DIMENSION_CODE_NOT_FOUND",
                "message": f"No existe dimensión con code='{payload.dimension_code}'.",
                "hint":    "Códigos válidos: SOCIAL_BASE, FISICO_BASE, AFECTIVO_BASE, MENTAL_BASE, CONDICION_FISICA, REG_EMOCIONAL",
            })
        resolved_pd_id = row["id_point_dimension"]

    elif payload.point_dimension_id is not None:
        row = db.execute(
            text("SELECT id_point_dimension FROM point_dimension "
                 "WHERE id_point_dimension = :v LIMIT 1"),
            {"v": payload.point_dimension_id},
        ).mappings().first()
        if not row:
            raise HTTPException(status_code=404, detail={
                "code":    "POINT_DIMENSION_NOT_FOUND",
                "message": f"No existe id_point_dimension={payload.point_dimension_id}.",
                "hint":    "Usa attribute_id en su lugar (attribute_id=2 para Físico, etc.).",
            })
        resolved_pd_id = payload.point_dimension_id

    else:
        raise HTTPException(status_code=422, detail={
            "code":    "DIMENSION_REQUIRED",
            "message": "Debes indicar la dimensión: attribute_id, subattribute_id, dimension_code o point_dimension_id.",
            "ejemplo": {"attribute_id": 2, "direction": "CREDIT", "amount": 50,
                        "reason": "Puntos por actividad física"},
        })

    # ── Info de la dimensión para enriquecer la respuesta ───────────────────────
    dim = db.execute(
        text("""
            SELECT pd.code, pd.name AS dimension_name,
                   a.name AS attribute_name, s.name AS subattribute_name
            FROM point_dimension pd
            LEFT JOIN attributes   a ON a.id_attributes   = pd.id_attributes
            LEFT JOIN subattributes s ON s.id_subattributes = pd.id_subattributes
            WHERE pd.id_point_dimension = :pd_id
        """),
        {"pd_id": resolved_pd_id},
    ).mappings().first()

    try:
        db.execute(
            text("""
                INSERT INTO points_ledger (
                  id_players, id_point_dimension, id_videogame,
                  direction, amount, source_type, source_ref, payload
                ) VALUES (
                  :id_players, :id_point_dimension, :id_videogame,
                  :direction, :amount, 'ADJUST', :source_ref, :payload
                )
            """),
            {
                "id_players":         player_id,
                "id_point_dimension": resolved_pd_id,
                "id_videogame":       payload.videogame_id,
                "direction":          payload.direction,
                "amount":             payload.amount,
                "source_ref":         source_ref,
                "payload":            json.dumps({"reason": payload.reason}) if payload.reason else None,
            },
        )
        db.commit()
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=400, detail=f"Error adjusting points: {e}")

    return {
        "status":             "ok",
        "source_ref":         source_ref,
        "id_point_dimension": resolved_pd_id,
        "dimension_code":     dim["code"]            if dim else None,
        "dimension_name":     dim["dimension_name"]  if dim else None,
        "attribute_name":     dim["attribute_name"]  if dim else None,
        "direction":          payload.direction,
        "amount":             payload.amount,
    }