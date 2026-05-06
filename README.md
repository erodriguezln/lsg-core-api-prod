# LSG Core API (LifeSync-Games)

Servicio FastAPI que expone la lógica de dominio de LifeSync-Games sobre la base de datos `db_lsg` (MySQL 8).

**Versión:** 1.2.0 | **Swagger:** https://lsg.diinf.usach.cl/lsg-core-api/docs  
**Requiere token de:** https://lsg.diinf.usach.cl/lsg-auth/docs

---

## Estructura del proyecto

```text
lsg-core-api-prod/
│
├── app/
│   ├── api/
│   │   ├── health.py          # GET /health, /health/full
│   │   ├── meta.py            # GET /meta/info
│   │   ├── players.py         # /players/... (lista, detalle con roles, timeline)
│   │   ├── points.py          # /attributes, /points/ledger, balances, ajustes
│   │   ├── games.py           # /videogames/... (canjes, sesiones, bulk mecánicas)
│   │   ├── sensors.py         # /sensors/... (config e ingest con ownership check)
│   │   ├── analytics.py       # /analytics/... (balances, overview, calidad)
│   │   ├── admin_config.py    # /admin/... (atributos, subatributos, dimensiones, mecánicas)
│   │   ├── admin_points.py    # /admin/points/consistency-check
│   │   ├── research_export.py # /research/export/... (CSV/JSON seudonimizado)
│   │   ├── ic2.py             # /ic2/... (Índice Compuesto IC² LSG)     ← v1.2
│   │   └── offline.py         # /offline/... (puntos offline Starbound/BG3) ← v1.2
│   │
│   ├── security.py            # JWT decode, require_roles, guard_player_access
│   ├── db.py                  # Conexión SQLAlchemy a MySQL
│   └── main.py                # Instancia FastAPI + registro de routers
│
├── db/
│   └── init/
│       ├── 01_db_lsg_dump.sql   # Schema base + datos semilla
│       └── 02_migrations.sql    # PATCH-01→06: player_roles, IC², offline, etc.
│
├── .env.example
├── docker-compose.yml
├── Dockerfile
└── requirements.txt
```

---

## Despliegue en producción (DIINF-USACH)

### 1. Prerequisitos

```bash
# Red compartida con lsg-auth (crear solo una vez por VM)
docker network create lsg_shared
```

### 2. Variables de entorno

```bash
cp .env.example .env
# Editar .env con los valores reales del entorno DIINF
```

Variables requeridas:

| Variable | Descripción |
|----------|-------------|
| `MYSQL_ROOT_PASSWORD` | Contraseña root MySQL (solo init) |
| `DB_NAME` / `DB_USER` / `DB_PASSWORD` | Credenciales BD |
| `API_PORT` | Puerto host para Nginx (default: `8012`) |
| `AUTH_JWT_SECRET` | **Mismo valor** que en lsg-auth |
| `AUTH_JWT_ALGORITHM` | `HS256` |
| `AUTH_JWT_ISSUER` | `lsg-auth` |
| `AUTH_JWT_AUDIENCE` | `lsg-core-api` |
| `AUTH_OPEN_ALL` | `false` en producción (activa guards de roles) |
| `AUTH_DISABLED` | `false` en producción |
| `LSG_CORE_API_ROOT_PATH` | `/lsg-core-api` |
| `RESEARCH_PSEUDONYM_SALT` | Salt seudonimización FONDECYT (hex 64 chars) |
| `OFFLINE_SYNC_MAX_AGE_DAYS` | Ventana offline (default: `30`) |

### 3. Levantar el stack

```bash
docker compose up -d --build
docker ps
docker logs -n 100 lsg_core_api
```

### 4. Inicialización de BD (entorno fresco)

En un entorno nuevo, `docker-entrypoint-initdb.d` ejecuta automáticamente los archivos en `db/init/` al crear el volumen. El orden es:

1. `01_db_lsg_dump.sql` — schema base y datos semilla
2. `02_migrations.sql` — PATCH-01 a 06 (player_roles, IC², offline, etc.)

Para aplicar migraciones en una BD existente:

```bash
docker compose exec db mysql \
  -u${DB_USER} -p${DB_PASSWORD} ${DB_NAME} \
  < db/init/02_migrations.sql
```

### 5. Verificar

```bash
# Swagger
open https://lsg.diinf.usach.cl/lsg-core-api/docs

# Health
curl https://lsg.diinf.usach.cl/lsg-core-api/health/full
```

---

## Flujo de autenticación

```
1. Obtener token → lsg-auth
   POST https://lsg.diinf.usach.cl/lsg-auth/login
   Body: username=email&password=...
   → {"access_token": "eyJ...", "token_type": "bearer"}

   El token expira en 120 minutos (JWT_EXPIRE_MINUTES=120).
   Consultar tiempo restante: GET /lsg-auth/token/remaining

2. Autorizar en Swagger de Core API
   Botón "Authorize" → Bearer <access_token>

3. Usar endpoints normalmente
```

---

## Sistema de roles

El JWT incluye el claim `"roles": [...]` (lista). Un jugador puede tener múltiples roles activos (tabla `player_roles`).

| Rol | Descripción |
|-----|-------------|
| `player` | Sus propios datos: balance, sesiones, canjes, IC², sensores |
| `teacher` | Lectura de todos los jugadores y analíticas |
| `researcher` | Todo lo de teacher + ajuste de puntos, exportación e IC² ajeno |
| `admin` | Acceso completo incluyendo configuración del sistema |

---

## Endpoints

### Core

| Método | Ruta | Roles | Descripción |
|--------|------|-------|-------------|
| `GET` | `/health` | — | Liveness |
| `GET` | `/health/full` | todos | Readiness + vistas críticas |
| `GET` | `/meta/info` | todos | Versión, entorno, BD |

### Jugadores

| Método | Ruta | Roles | Descripción |
|--------|------|-------|-------------|
| `GET` | `/players` | teacher, researcher, admin | Lista paginada con roles |
| `GET` | `/players/{id}` | todos | Detalle + roles activos |
| `DELETE` | `/players/{id}` | admin | Borrado en cascada |
| `POST` | `/players/{id}/attributes/init` | admin, teacher, researcher | Inicializar atributos |
| `GET` | `/players/{id}/games` | todos | Videojuegos del jugador |
| `GET` | `/players/{id}/timeline` | todos | Timeline unificado de eventos |

### Puntos y atributos

| Método | Ruta | Roles | Descripción |
|--------|------|-------|-------------|
| `GET` | `/attributes` | todos | Catálogo de atributos |
| `GET` | `/attributes/{id}/subattributes` | todos | Subatributos |
| `GET` | `/attributes-map` | todos | Mapa JSON atributos↔subatributos |
| `GET` | `/players/{id}/points/balance` | todos | Balance por dimensión |
| `GET` | `/players/{id}/attributes/points` | todos | Balance por atributo |
| `GET` | `/points/ledger` | todos* | Historial ledger |
| `POST` | `/players/{id}/points/adjust` | admin, researcher | Ajuste manual |

*`player` solo ve su propio ledger.

### Videojuegos

| Método | Ruta | Roles | Descripción |
|--------|------|-------|-------------|
| `GET` | `/videogames` | todos | Catálogo de juegos |
| `POST` | `/videogames` | admin, researcher | Crear videojuego |
| `GET` | `/videogames/{id}/mechanics` | todos | Mecánicas del juego |
| `POST` | `/videogames/{id}/mechanics` | admin, researcher | Agregar mecánica |
| `POST` | `/videogames/{id}/mechanics/bulk` | admin, researcher | Carga masiva (hasta 500) |
| `POST` | `/videogames/{id}/players/{pid}/connect` | todos | Vincular jugador↔juego |
| `POST` | `/videogames/{id}/players/{pid}/sessions` | todos | Iniciar sesión |
| `PATCH` | `/videogames/{id}/players/{pid}/sessions/{sid}/end` | todos | Cerrar sesión |
| `POST` | `/videogames/{id}/players/{pid}/redeem/preview` | todos | Preview canje |
| `POST` | `/videogames/{id}/players/{pid}/redeem` | todos | Canje de puntos |

### Sensores

| Método | Ruta | Roles | Descripción |
|--------|------|-------|-------------|
| `GET` | `/sensors` | todos | Catálogo sensores |
| `GET` | `/sensors/{id}/endpoints` | todos | Endpoints del sensor |
| `GET` | `/sensors/players/{id}` | todos | Sensores del jugador |
| `POST` | `/sensors/ingest/webhook` | todos* | Ingestar evento |
| `GET` | `/sensors/players/{id}/ingest-events` | todos | Historial de ingestas |

*`player` solo puede ingestar para su propio `player_id`.

### IC² LSG ← v1.2

| Método | Ruta | Roles | Descripción |
|--------|------|-------|-------------|
| `POST` | `/ic2/compute` | todos* | Calcular IC² (F1-F4, Ec.5-7, IAR) |
| `GET` | `/ic2/history` | todos* | Historial de resultados |
| `GET` | `/ic2/goalposts` | todos | Goalposts de una versión |

*`player` solo para su propio `player_id`.

```bash
# Ejemplo: calcular IC² para jugador 26
curl -X POST 'https://lsg.diinf.usach.cl/lsg-core-api/ic2/compute' \
  -H 'Authorization: Bearer <TOKEN>' \
  -H 'Content-Type: application/json' \
  -d '{
    "player_id": 26,
    "version_tag": "v1.0-SCCC2026",
    "experiment_tag": "LSG_PILOT_2026_T1",
    "session_time_minutes": 45,
    "signals": {
      "MVPA_min_week": 180, "steps_day": 7500,
      "resting_hr_bpm": 65, "sleep_quality_score": 7,
      "memory_accuracy_pct": 82, "recall_speed_ms": 650,
      "decision_accuracy_pct": 78, "reaction_time_ms": 420
    }
  }'
```

### Puntos offline ← v1.2

| Método | Ruta | Roles | Descripción |
|--------|------|-------|-------------|
| `POST` | `/offline/sync` | todos* | Sincronizar lote offline (HTTP 207) |
| `GET` | `/offline/queue` | todos* | Estado de la cola |

*`player` solo su propia cola. Ventana máxima: 30 días. Idempotencia por `client_ref` (UUID).

### Analytics

| Método | Ruta | Roles | Descripción |
|--------|------|-------|-------------|
| `GET` | `/analytics/points-balance` | admin, researcher | Balance global |
| `GET` | `/analytics/player-game-overview` | admin, researcher | Resumen por juego |
| `GET` | `/analytics/player-attribute-balance` | admin, researcher | Balance por atributo |
| `GET` | `/analytics/games/time-to-first-redeem` | admin, researcher | Tiempo hasta primer canje |
| `GET` | `/analytics/sensors/quality` | admin, researcher | Calidad de ingestión |
| `GET` | `/analytics/sensors/ingest-vs-points` | admin, researcher | Conversión sensor→puntos |

### Admin configuración

| Método | Ruta | Roles | Descripción |
|--------|------|-------|-------------|
| `GET/POST/PUT/DELETE` | `/admin/attributes` | admin (write), researcher (read) | CRUD atributos |
| `GET/POST/PUT/DELETE` | `/admin/subattributes` | admin (write), researcher (read) | CRUD subatributos |
| `GET/POST/PUT/DELETE` | `/admin/point-dimensions` | admin (write), researcher (read) | CRUD dimensiones |
| `GET/POST/PUT/DELETE` | `/admin/modifiable-mechanics` | admin (write), researcher (read) | CRUD mecánicas |
| `GET/POST/PUT/DELETE` | `/admin/modifiable-mechanics-videogames` | admin (write), researcher (read) | Vínculo mecánica↔juego |
| `GET` | `/admin/points/consistency-check` | admin, researcher | Checks de integridad |

### Exportación investigación

| Método | Ruta | Roles | Descripción |
|--------|------|-------|-------------|
| `GET` | `/research/export/points` | admin, researcher | Ledger seudonimizado (JSON/CSV) |
| `GET` | `/research/export/sessions` | admin, researcher | Sesiones (JSON/CSV) |
| `GET` | `/research/export/sensors` | admin, researcher | Eventos de sensor (JSON/CSV) |

---

## Changelog

### v1.2.0 (2026-05)
- `ic2.py` — nuevo módulo: `POST /ic2/compute`, `GET /ic2/history`, `GET /ic2/goalposts`.
- `offline.py` — nuevo módulo: `POST /offline/sync` (idempotente), `GET /offline/queue`.
- `games.py` — `POST /{id}/mechanics/bulk` (hasta 500 mecánicas, HTTP 207).
- BD: PATCH-03 (tablas IC²), PATCH-04 (offline queue), PATCH-05 (sp_bulk_attach), PATCH-06 (reglas R1-R6 + vista v_ic2_latest).

### v1.1.0 (2026-05)
- `security.py` — `AUTH_OPEN_ALL=false` por defecto. `CurrentUser.roles` como lista.
- `games.py` — escritura restringida a researcher/admin.
- `research_export.py` — acceso restringido a researcher/admin; guard duplicado eliminado.
- `points.py` — `GET /points/ledger` fuerza filtro propio para rol `player`.
- `sensors.py` — `POST /ingest/webhook` valida ownership de `player_id`.
- `players.py` — `GET /players` y `GET /players/{id}` incluyen campo `roles: []`.
- `admin_config.py` — migración a Pydantic v2 (`model_validator`).
- BD: PATCH-01 (player_roles multi-rol), PATCH-02 (interaction_logs).

---

## Referencias

- González-Ibáñez R., Macías-Cáceres J., Villalta-Paucar M. (2025). *LifeSync-Games: Toward a Video Game Paradigm for Promoting Responsible Gaming and Human Development*. arXiv:2510.19691 [cs.HC]. DOI: https://arxiv.org/abs/2510.19691