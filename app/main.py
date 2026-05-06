import os
from fastapi import FastAPI

from app.api import (
    health,
    analytics,
    players,
    points,
    games,
    sensors,
    meta,
    admin_config,
    admin_points,
    research_export,
)

ROOT_PATH = os.getenv("LSG_CORE_API_ROOT_PATH", "")

CORE_DOCS_DESCRIPTION = """
## Flujo de uso (Token → Core API)

1. **Obtén un token en LSG-auth**:
   - Swagger Auth: `/lsg-auth/docs`
   - `POST /login` → copia `access_token`
   - El token expira en **10 minutos** (`JWT_EXPIRE_MINUTES=10`)
   - Consulta tiempo restante: `GET /lsg-auth/token/remaining`

2. **Autoriza en este Swagger**:
   - Botón **Authorize**
   - Pega: `Bearer <access_token>`

3. **Todos los endpoints requieren JWT válido.**
   Los roles determinan el nivel de acceso:

   | Rol | Acceso |
   |---|---|
   | `player` | Solo sus propios datos, canjes y sesiones |
   | `teacher` | Lectura de todos los jugadores y analíticas |
   | `researcher` | Todo lo de teacher + ajuste de puntos y exportación |
   | `admin` | Acceso completo, incluyendo configuración del sistema |

Fuente:
- González-Ibáñez, R., Macías-Cáceres, J., Villalta-Paucar, M. (2025).
  LifeSync-Games: Toward a Video Game Paradigm for Promoting Responsible
  Gaming and Human Development. arXiv:2510.19691 [cs.HC].

"""

app = FastAPI(
    title="LifeSync-Games Core API",
    version="1.1.0",
    root_path=ROOT_PATH,
    description=CORE_DOCS_DESCRIPTION,
)

# ── Routers ────────────────────────────────────────────────────────────────────

app.include_router(health.router)

app.include_router(players.router,   prefix="/players",    tags=["players"])
app.include_router(points.router)
app.include_router(games.router,     prefix="/videogames", tags=["videogames"])
app.include_router(sensors.router,   prefix="/sensors",    tags=["sensors"])

app.include_router(analytics.router, prefix="/analytics",  tags=["analytics"])
app.include_router(meta.router,      prefix="/meta",        tags=["meta"])

app.include_router(admin_config.router)   # prefix="/admin" ya incluido
app.include_router(admin_points.router)   # prefix="/admin/points" ya incluido
app.include_router(research_export.router)  # prefix="/research/export" ya incluido