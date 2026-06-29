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

    **Regla fundamental:** los puntos SIEMPRE se acreditan al atributo base
    (FISICO_BASE, MENTAL_BASE, etc.), nunca directamente a un subatributo.
    Si se indica un subatributo, se usa solo como trazabilidad en el payload;
    los puntos van al atributo padre correspondiente.

    Indica la dimensión usando **una** de estas opciones (prioridad: 1->2->3->4):

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
        description="Código de point_dimension (ej.: FISICO_BASE, CONDICION_FISICA, MENTAL_BASE)"
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

    Retorna el **saldo de puntos por dimensión** del jugador, enriquecido con el
    nombre del atributo y el código de la dimensión.

    Cada fila representa una dimensión de `point_dimension` en la que el jugador
    tiene movimientos registrados en `points_ledger`. El balance se calcula como:

    ```
    balance = SUM(amount WHERE direction='CREDIT') - SUM(amount WHERE direction='DEBIT')
    ```

    **Cuándo usar este endpoint:**
    - Cuando el mod/sensor necesita saber si el jugador tiene suficientes puntos para canjear una mecánica específica de una dimensión.
    - Para mostrar el saldo operacional antes de un canje.

    **Diferencia con `/attributes/points`:**
    - Este endpoint agrupa por **dimensión** (`id_point_dimension`), que es la unidad mínima del ledger. Incluye tanto dimensiones de atributo base (FISICO_BASE) como de subatributo (CONDICION_FISICA).
    - `/attributes/points` agrupa por **atributo** (Social, Físico, etc.), sumando todas sus dimensiones. Es más semántico pero menos granular.

    **Ejemplo de respuesta:**
    ```json
    [
      {
        "id_players": 46,
        "id_point_dimension": 2,
        "dimension_code": "FISICO_BASE",
        "dimension_name": "Puntos de actividad física",
        "id_attributes": 2,
        "attribute_name": "Fisico",
        "id_subattributes": null,
        "subattribute_name": null,
        "balance": 131
      },
      {
        "id_point_dimension": 5,
        "dimension_code": "CONDICION_FISICA",
        "id_attributes": null,
        "id_subattributes": 6,
        "subattribute_name": "Condición física",
        "balance": 10
      }
    ]
    ```

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

    Retorna el **saldo de puntos por atributo** del jugador (Social, Físico, Afectivo, Mental, etc.), agregando todas las dimensiones que pertenecen a cada atributo.

    Además del balance actual calculado desde `points_ledger` (`balance_ledger`), incluye el **snapshot** almacenado en `players_attributes` (`snapshot_points`) y la diferencia entre ambos.

    **Cuándo usar este endpoint:**
    - Para mostrar al jugador su progreso general por área (ej.: "Tienes 245 puntos en Físico").
    - Para el dashboard del investigador: ver el perfil de salud del participante.
    - Para detectar inconsistencias: si `diff_ledger_minus_snapshot` es muy grande, el snapshot está desactualizado y conviene llamar `POST /players/{id}/attributes/init` para sincronizarlo.

    **Diferencia con `/points/balance`:**
    - Este endpoint agrupa por **atributo** (nivel alto: Social, Físico...). Suma FISICO_BASE + CONDICION_FISICA + cualquier otra dimensión que pertenezca al atributo Físico.
    - `/points/balance` es más granular: muestra cada dimensión por separado.

    **Campos:**
    - `balance_ledger`: saldo real calculado en tiempo real desde `points_ledger`.
    - `snapshot_points`: caché almacenado en `players_attributes`. Se actualiza manualmente (no en tiempo real).
    - `diff_ledger_minus_snapshot`: diferencia. Si > 0, ocurrieron transacciones desde el último snapshot. Si < 0, hay una anomalía (nunca debería ocurrir).

    **Ejemplo de respuesta:**
    ```json
    [
      {
        "id_players": 46,
        "player_name": "jmacias",
        "id_attributes": 2,
        "attribute_name": "Fisico",
        "balance_ledger": 245,
        "snapshot_points": 200,
        "diff_ledger_minus_snapshot": 45
      },
      {
        "id_attributes": 4,
        "attribute_name": "Mental",
        "balance_ledger": 89,
        "snapshot_points": 89,
        "diff_ledger_minus_snapshot": 0
      }
    ]
    ```

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

    Inserta un movimiento manual de puntos en `points_ledger` con `source_type='ADJUST'`. Se usa cuando los puntos no provienen de un sensor (SENSOR) ni de un canje (REDEMPTION), sino de una asignación directa: pruebas de integración, compensaciones, correcciones, etc.

    ---

    **¿Cómo indicar la dimensión?**

    Usa **una sola** de estas cuatro formas (prioridad de izquierda a derecha):

    | Campo               | Ejemplo          | Cuándo usar                                      |
    |---------------------|------------------|--------------------------------------------------|
    | `attribute_id`      | `2`              | Recomendado. Usa el `id_attributes` del atributo base (Social=1, Físico=2, Afectivo=3, Mental=4). |
    | `subattribute_id`   | `6`              | Para dimensiones de subatributo (Condición Física=6, Regulación Emocional=11). |
    | `dimension_code`    | `"FISICO_BASE"`  | Si conoces el código exacto de `point_dimension`. |
    | `point_dimension_id`| `2`              | FK directo a `point_dimension`. Funciona pero puede confundirse con `id_attributes`. |

    Consulta `GET /admin/point-dimensions` para ver todas las dimensiones disponibles y el mapeo completo `attribute_id` -> `id_point_dimension`.

    ---

    **Referencia rápida de dimensiones disponibles:**

    ```
    attribute_id=1 ->  SOCIAL_BASE      (Puntos de desarrollo social)
    attribute_id=2 ->  FISICO_BASE      (Puntos de actividad física)
    attribute_id=3 ->  AFECTIVO_BASE    (Puntos de bienestar afectivo)
    attribute_id=4 ->  MENTAL_BASE      (Puntos de desarrollo mental)
    attribute_id=5 ->  LINGUISTICO_BASE (Puntos de desarrollo lingüístico)
    subattribute_id=6 ->  CONDICION_FISICA  (Condición física, subatributo de Físico)
    subattribute_id=11 -> REG_EMOCIONAL     (Regulación emocional, subatributo de Afectivo)
    ```

    ---

    **Ejemplos de uso:**

    ```bash
    # Forma recomendada: attribute_id
    curl -X POST '.../players/46/points/adjust' \
      -d '{"attribute_id": 2, "direction": "CREDIT", "amount": 50,
           "reason": "meta_hidratacion_2026-06-25", "videogame_id": 14}'

    # Subatributo específico
    curl -X POST '.../players/46/points/adjust' \
      -d '{"subattribute_id": 6, "direction": "CREDIT", "amount": 30,
           "reason": "condicion_fisica_sensor"}'

    # Descontar puntos (canje manual / corrección)
    curl -X POST '.../players/46/points/adjust' \
      -d '{"attribute_id": 2, "direction": "DEBIT", "amount": 20,
           "reason": "correccion_duplicado"}'
    ```

    ---

    **Respuesta exitosa (200):**
    ```json
    {
      "status": "ok",
      "source_ref": "ADJUST-uuid...",
      "id_point_dimension": 2,
      "dimension_code": "FISICO_BASE",
      "dimension_name": "Puntos de actividad física",
      "attribute_name": "Fisico",
      "direction": "CREDIT",
      "amount": 50
    }
    ```

    **Roles disponibles:** "admin", "researcher", "developer"
    """
    from uuid import uuid4
    import json as _json

    source_ref = f"ADJUST-{uuid4()}"

    # ── Helper: dado un id_point_dimension, verificar si es subatributo y
    #    resolver al atributo padre. Devuelve (pd_id_final, subattr_meta).
    def _resolve_to_base_dimension(pd_id: int):
        """
        Si la dimensión es de subatributo (id_attributes IS NULL), sube al
        atributo padre y retorna la dimensión base correspondiente.
        Los puntos SIEMPRE van al atributo base; el subatributo queda en el log.
        """
        dim = db.execute(
            text("""
                SELECT pd.id_point_dimension, pd.code, pd.id_attributes,
                       pd.id_subattributes, s.name AS subattribute_name,
                       s.attributes_id_attributes AS parent_attr_id
                FROM point_dimension pd
                LEFT JOIN subattributes s ON s.id_subattributes = pd.id_subattributes
                WHERE pd.id_point_dimension = :pd_id
            """),
            {"pd_id": pd_id},
        ).mappings().first()

        if not dim:
            return None, None

        # Si ya es atributo base → devuelve directo
        if dim["id_attributes"] is not None:
            return pd_id, None

        # Es subatributo → resolver al atributo padre
        parent_pd = db.execute(
            text("""
                SELECT id_point_dimension, code
                FROM point_dimension
                WHERE id_attributes = :attr_id
                  AND id_subattributes IS NULL
                LIMIT 1
            """),
            {"attr_id": dim["parent_attr_id"]},
        ).mappings().first()

        if not parent_pd:
            raise HTTPException(status_code=404, detail={
                "code":    "PARENT_DIMENSION_NOT_FOUND",
                "message": f"No se encontró dimensión base para el subatributo {dim['id_subattributes']}.",
            })

        # Meta del subatributo para trazabilidad en el payload
        subattr_meta = {
            "subattribute_id":   dim["id_subattributes"],
            "subattribute_name": dim["subattribute_name"],
            "subattribute_code": dim["code"],
        }
        return parent_pd["id_point_dimension"], subattr_meta

    # ── Resolver id_point_dimension según el campo recibido ───────────────────
    resolved_pd_id: Optional[int] = None
    subattr_meta = None

    if payload.attribute_id is not None:
        row = db.execute(
            text("SELECT id_point_dimension FROM point_dimension "
                 "WHERE id_attributes = :v AND id_subattributes IS NULL LIMIT 1"),
            {"v": payload.attribute_id},
        ).mappings().first()
        if not row:
            raise HTTPException(status_code=404, detail={
                "code":    "ATTRIBUTE_DIMENSION_NOT_FOUND",
                "message": f"No existe dimensión base para attribute_id={payload.attribute_id}.",
                "hint":    "Consulta GET /admin/point-dimensions.",
            })
        resolved_pd_id = row["id_point_dimension"]

    elif payload.subattribute_id is not None:
        # Primero encontrar la dimensión del subatributo
        sub_pd = db.execute(
            text("SELECT id_point_dimension FROM point_dimension "
                 "WHERE id_subattributes = :v LIMIT 1"),
            {"v": payload.subattribute_id},
        ).mappings().first()
        if not sub_pd:
            raise HTTPException(status_code=404, detail={
                "code":    "SUBATTRIBUTE_DIMENSION_NOT_FOUND",
                "message": f"No existe dimensión para subattribute_id={payload.subattribute_id}.",
                "hint":    "Consulta GET /admin/point-dimensions.",
            })
        # Resolver al atributo base
        resolved_pd_id, subattr_meta = _resolve_to_base_dimension(sub_pd["id_point_dimension"])

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
                "hint":    "Códigos base válidos: SOCIAL_BASE, FISICO_BASE, AFECTIVO_BASE, MENTAL_BASE.",
            })
        # Si el código apunta a un subatributo, resolver al padre
        resolved_pd_id, subattr_meta = _resolve_to_base_dimension(row["id_point_dimension"])

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
            })
        resolved_pd_id, subattr_meta = _resolve_to_base_dimension(payload.point_dimension_id)

    else:
        raise HTTPException(status_code=422, detail={
            "code":    "DIMENSION_REQUIRED",
            "message": "Debes indicar: attribute_id, subattribute_id, dimension_code o point_dimension_id.",
            "ejemplo": {"attribute_id": 2, "direction": "CREDIT", "amount": 50,
                        "reason": "meta_hidratacion"},
        })

    # ── Info de la dimensión base (para response) ──────────────────────────────
    dim_info = db.execute(
        text("""
            SELECT pd.code, pd.name AS dimension_name, a.name AS attribute_name
            FROM point_dimension pd
            LEFT JOIN attributes a ON a.id_attributes = pd.id_attributes
            WHERE pd.id_point_dimension = :pd_id
        """),
        {"pd_id": resolved_pd_id},
    ).mappings().first()

    # ── Construir payload: reason + trazabilidad de subatributo si aplica ──────
    ledger_payload: dict = {}
    if payload.reason:
        ledger_payload["reason"] = payload.reason
    if subattr_meta:
        ledger_payload["subattribute_trace"] = subattr_meta

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
                "payload":            _json.dumps(ledger_payload) if ledger_payload else None,
            },
        )
        db.commit()
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=400, detail=f"Error adjusting points: {e}")

    response = {
        "status":             "ok",
        "source_ref":         source_ref,
        "id_point_dimension": resolved_pd_id,
        "dimension_code":     dim_info["code"]           if dim_info else None,
        "dimension_name":     dim_info["dimension_name"] if dim_info else None,
        "attribute_name":     dim_info["attribute_name"] if dim_info else None,
        "direction":          payload.direction,
        "amount":             payload.amount,
    }
    if subattr_meta:
        response["subattribute_trace"] = subattr_meta
    return response