from fastapi import APIRouter, Depends
from sqlalchemy import text
from sqlalchemy.orm import Session

from app.security import (
    require_roles,
    guard_player_access,
    CurrentUser,
    ROLE_ALL,
)   
from app.db import get_db

router = APIRouter(tags=["health"])


@router.get("/health")
def health_check():
    """
    # GET /health

    Liveness básico: solo indica que la app está levantada.
    """
    return {"status": "ok"}


@router.get("/health/full")
def health_full(db: Session = Depends(get_db)):
    """
    # GET /health/full

    Readiness / health extendido:
    - Chequea conexión a la base de datos.
    - Verifica acceso a vistas críticas.
    """
    checks = {}

    # Conexión a DB
    try:
        db.execute(text("SELECT 1"))
        checks["database"] = {"status": "ok"}
    except Exception as e:
        checks["database"] = {"status": "error", "detail": str(e)}

    # Vistas críticas para LSG
    views = [
        "v_points_balance",
        "v_player_game_overview",
        "v_player_attribute_balance",
        "v_ic2_latest",
        "v_player_active_roles",
    ]
    # Tablas de features nuevas
    feature_tables = ["ic2_result", "offline_points_queue", "interaction_logs", "player_roles"]
    view_results = []

    for view in views:
        try:
            # Si la vista existe, esto debería funcionar aunque esté vacía
            db.execute(text(f"SELECT 1 FROM {view} LIMIT 1"))
            view_results.append({"name": view, "status": "ok"})
        except Exception as e:
            view_results.append(
                {"name": view, "status": "error", "detail": str(e)}
            )

    checks["views"] = view_results

    # 2b) Tablas de features nuevas
    table_results = []
    for tbl in feature_tables:
        try:
            db.execute(text(f"SELECT 1 FROM {tbl} LIMIT 1"))
            table_results.append({"name": tbl, "status": "ok"})
        except Exception as e:
            table_results.append({"name": tbl, "status": "error", "detail": str(e)})

    checks["feature_tables"] = table_results

    # 3) Estado global
    if checks["database"]["status"] != "ok":
        status = "error"
    elif any(v["status"] != "ok" for v in view_results + table_results):
        status = "degraded"
    else:
        status = "ok"

    return {
        "status": status,
        "checks": checks,
    }