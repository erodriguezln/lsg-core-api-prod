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
    game_logs,
)
from app.api import ic2      
from app.api import offline  

ROOT_PATH = os.getenv("LSG_CORE_API_ROOT_PATH", "")

CORE_DOCS_DESCRIPTION = """
## Flujo de uso (Token → Core API)

1. **Obtén un token en LSG-auth**:
   - Swagger Auth: `/lsg-auth/docs`
   - `POST /login` → copia `access_token`
   - El token expira en **120 minutos** (`JWT_EXPIRE_MINUTES=120`)
   - Consulta tiempo restante: `GET /lsg-auth/token/remaining`

2. **Autoriza en este Swagger**:
   - Botón **Authorize**
   - Pega: `Bearer <access_token>`

3. **Todos los endpoints requieren JWT válido.**

   | Rol | Acceso |
   |---|---|
   | `player` | Solo sus propios datos, canjes, sesiones e IC² |
   | `teacher` | Lectura de todos los jugadores y analíticas |
   | `researcher` | Todo lo de teacher + ajuste de puntos, exportación e IC² ajeno |
   | `admin` | Acceso completo, incluyendo configuración del sistema |
   | `developer` | Acceso completo, incluyendo configuración del sistema y endpoints de mantenimiento |

4. **IC² LSG** (`/ic2`): calcula el Índice Compuesto Físico-Mental a partir de
   estrategias de normalización y reglas de mecánica.

5. **Puntos offline** (`/offline`): sincroniza eventos generados sin conexión.
   Ventana máxima: 30 días. Idempotencia por `client_ref`.

Fuente:
- R. González-Ibáñez, J. I. Macías-Cáceres and M. V. Paucar, "LifeSync-Games: A Technical Note on a Novel Framework for Video Game Development," 2025 44th International Conference of the Chilean Computer Science Society (SCCC), Valparaiso, Chile, 2025, pp. 1-4, doi: 10.1109/SCCC67219.2025.11420722.
- González-Ibáñez R., Macías-Cáceres J., Villalta-Paucar M. (2025). *LifeSync-Games: Toward a Video Game Paradigm for Promoting Responsible Gaming and Human Development*. arXiv:2510.19691 [cs.HC]. DOI: https://arxiv.org/abs/2510.19691

"""

app = FastAPI(
    title="LifeSync-Games Core API",
    version="1.2.3",
    root_path=ROOT_PATH,
    description=CORE_DOCS_DESCRIPTION,
)

# Routers existentes

app.include_router(health.router)

app.include_router(players.router,   prefix="/players",    tags=["players"])
app.include_router(points.router)
app.include_router(games.router,     prefix="/videogames", tags=["videogames"])
app.include_router(sensors.router,   prefix="/sensors",    tags=["sensors"])

app.include_router(analytics.router, prefix="/analytics",  tags=["analytics"])
app.include_router(meta.router,      prefix="/meta",        tags=["meta"])

app.include_router(game_logs.router, prefix="/game-logs", tags=["game-logs"])

app.include_router(admin_config.router)     # prefix="/admin" incluido
app.include_router(admin_points.router)     # prefix="/admin/points" incluido
app.include_router(research_export.router)  # prefix="/research/export" incluido

app.include_router(ic2.router,     prefix="/ic2",     tags=["ic2"])
app.include_router(offline.router, prefix="/offline", tags=["offline"])