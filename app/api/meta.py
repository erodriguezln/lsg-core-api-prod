import os
from fastapi import APIRouter

from app.db import DB_HOST, DB_NAME

router = APIRouter(tags=["meta"])


@router.get("/info")
def get_meta_info():
    """
    Metadatos de la API y del entorno.
    Pensado para debugging / monitoreo.
    """
    api_version = os.getenv("API_VERSION", "1.0.2")
    environment = os.getenv("APP_ENV", "local")
    git_commit = os.getenv("GIT_COMMIT", "unknown")

    return {
        "api_version": api_version,
        "environment": environment,
        "git_commit": git_commit,
        "database": {
            "host": DB_HOST,
            "name": DB_NAME,
        },
    }
