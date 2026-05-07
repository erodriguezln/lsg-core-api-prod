# LSG Core API (LifeSync-Games)

Servicio FastAPI que expone la lógica de dominio de LifeSync-Games sobre la base de datos `db_lsg` (MySQL 8).

**Versión:** 1.2.1 | **Swagger:** https://lsg.diinf.usach.cl/lsg-core-api/docs  
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
│   │   ├── players.py         # /players/... (lista con roles, detalle, timeline)
│   │   ├── points.py          # /attributes, /points/ledger, balances, ajustes
│   │   ├── games.py           # /videogames/... (canjes, sesiones, bulk mecánicas)
│   │   ├── sensors.py         # /sensors/... (gestión + ingest con ownership check)
│   │   ├── analytics.py       # /analytics/... (balances, overview, calidad, IC²)
│   │   ├── admin_config.py    # /admin/... (atributos, dimensiones, mecánicas)
│   │   ├── admin_points.py    # /admin/points/consistency-check
│   │   ├── research_export.py # /research/export/... (CSV/JSON seudonimizado + IC²)
│   │   ├── ic2.py             # /ic2/... (Índice Compuesto IC² LSG)      ← v1.2
│   │   └── offline.py         # /offline/... (puntos offline, por ej. en juegos como: Starbound/BG3) ← v1.2
│   │
│   ├── security.py            # JWT decode, require_roles, guard_player_access
│   ├── db.py                  # Conexión SQLAlchemy a MySQL
│   └── main.py                # Instancia FastAPI + registro de routers
│
├── db/
│   └── init/
│       ├── 01_db_lsg_dump.sql   # Schema base + datos semilla
│       └── 02_migrations.sql    # PATCH-01→07: player_roles, IC², offline, fixes
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

| Variable | Descripción |
|----------|-------------|
| `MYSQL_ROOT_PASSWORD` | Contraseña root MySQL (solo init) |
| `DB_NAME` / `DB_USER` / `DB_PASSWORD` | Credenciales BD |
| `API_PORT` | Puerto host para Nginx (default: `8012`) |
| `AUTH_JWT_SECRET` | **Mismo valor** que en lsg-auth |
| `AUTH_JWT_ALGORITHM` | `HS256` |
| `AUTH_JWT_ISSUER` / `AUTH_JWT_AUDIENCE` | `lsg-auth` / `lsg-core-api` |
| `AUTH_OPEN_ALL` | `false` en producción |
| `AUTH_DISABLED` | `false` en producción |
| `LSG_CORE_API_ROOT_PATH` | `/lsg-core-api` |
| `RESEARCH_PSEUDONYM_SALT` | Salt seudonimización (hex 64 chars) |
| `OFFLINE_SYNC_MAX_AGE_DAYS` | Ventana offline máxima (default: `30`) |

### 3. Levantar el stack

```bash
docker compose up -d --build
docker ps
docker logs -n 100 lsg_core_api
```

### 4. Inicialización de BD

`docker-entrypoint-initdb.d` ejecuta los archivos de `db/init/` en orden al crear el volumen:

1. `01_db_lsg_dump.sql` — schema base y datos semilla
2. `02_migrations.sql` — PATCH-01 a 07 (player_roles, IC², offline, source_type fix)

Para aplicar en BD existente:
```bash
docker compose exec db mysql -u${DB_USER} -p${DB_PASSWORD} ${DB_NAME} \
  < db/init/02_migrations.sql
```

### 5. Verificar

```bash
curl https://lsg.diinf.usach.cl/lsg-core-api/health/full
# → {"status": "ok", "checks": {"database": ..., "views": [...], "feature_tables": [...]}}
```

---

## Flujo de autenticación

```
1. Obtener token → lsg-auth
   POST https://lsg.diinf.usach.cl/lsg-auth/login
   Body: username=email&password=...
   → {"access_token": "eyJ...", "token_type": "bearer"}
   Vigencia: 120 minutos. Consultar: GET /lsg-auth/token/remaining

2. Autorizar en Swagger
   Botón "Authorize" → Bearer <access_token>

3. Usar endpoints normalmente
```

---

## Sistema de roles

El JWT incluye el claim `"roles": [...]` (lista). Un jugador puede tener múltiples roles activos.

| Rol | Descripción |
|-----|-------------|
| `player` | Sus propios datos: balance, sesiones, canjes, IC², sensores |
| `teacher` | Lectura de todos los jugadores y analíticas |
| `researcher` | Todo lo de teacher + ajuste de puntos, exportación, IC² ajeno |
| `admin` | Acceso completo incluyendo configuración del sistema |

---

## Endpoints

### Core

| Método | Ruta | Roles | Descripción |
|--------|------|-------|-------------|
| `GET` | `/health` | — | Liveness |
| `GET` | `/health/full` | todos | Readiness: BD + vistas + tablas IC²/offline |
| `GET` | `/meta/info` | todos | Versión, entorno, BD |

### Jugadores

| Método | Ruta | Roles | Descripción |
|--------|------|-------|-------------|
| `GET` | `/players` | teacher, researcher, admin | Lista paginada con `roles: []` |
| `GET` | `/players/{id}` | todos | Detalle + `roles: []` activos |
| `DELETE` | `/players/{id}` | admin | Borrado en cascada |
| `POST` | `/players/{id}/attributes/init` | admin, teacher, researcher | Inicializar atributos |
| `GET` | `/players/{id}/games` | todos | Videojuegos del jugador |
| `GET` | `/players/{id}/timeline` | todos | Timeline unificado de eventos |

### Puntos y atributos

| Método | Ruta | Roles | Descripción |
|--------|------|-------|-------------|
| `GET` | `/attributes` | todos | Catálogo de atributos |
| `GET` | `/attributes/{id}/subattributes` | todos | Subatributos del atributo |
| `GET` | `/attributes-map` | todos | Mapa JSON completo atributos↔subatributos |
| `GET` | `/players/{id}/points/balance` | todos | Balance por dimensión |
| `GET` | `/players/{id}/attributes/points` | todos | Balance por atributo |
| `GET` | `/points/ledger` | todos* | Historial de movimientos |
| `POST` | `/players/{id}/points/adjust` | admin, researcher | Ajuste manual de puntos |

*`player` solo ve su propio ledger (filtro forzado por token).

### Videojuegos

| Método | Ruta | Roles | Descripción |
|--------|------|-------|-------------|
| `GET` | `/videogames` | todos | Catálogo de juegos |
| `POST` | `/videogames` | admin, researcher | Crear videojuego |
| `GET` | `/videogames/{id}/mechanics` | todos | Mecánicas del juego (options como JSON) |
| `POST` | `/videogames/{id}/mechanics` | admin, researcher | Agregar mecánica unitaria |
| `POST` | `/videogames/{id}/mechanics/bulk` | admin, researcher | Carga masiva hasta 500 mecánicas (HTTP 207) |
| `POST` | `/videogames/{id}/players/{pid}/connect` | todos | Vincular jugador↔juego (upsert) |
| `POST` | `/videogames/{id}/players/{pid}/sessions` | todos | Iniciar sesión de juego |
| `PATCH` | `/videogames/{id}/players/{pid}/sessions/{sid}/end` | todos | Cerrar sesión + calcular `duration_seconds` |
| `POST` | `/videogames/{id}/players/{pid}/redeem/preview` | todos | Preview de canje sin modificar BD |
| `POST` | `/videogames/{id}/players/{pid}/redeem` | todos | Canje de puntos (atómico, registra en `interaction_logs`) |

### Sensores

| Método | Ruta | Roles | Descripción |
|--------|------|-------|-------------|
| `GET` | `/sensors` | todos | Catálogo de proveedores de sensores |
| `POST` | `/sensors` | admin, researcher | Crear nuevo proveedor de sensor |
| `GET` | `/sensors/{id}/endpoints` | todos | Endpoints del sensor (para obtener `sensor_endpoint_id`) |
| `POST` | `/sensors/{id}/endpoints` | admin, researcher | Agregar endpoint a un sensor |
| `GET` | `/sensors/players/{id}` | todos* | Sensores y endpoints activos del jugador |
| `POST` | `/sensors/players/{id}/link` | admin, researcher | Vincular sensor a jugador |
| `POST` | `/sensors/players/{id}/link-endpoint` | admin, researcher | Activar endpoint para jugador (obtiene `players_sensor_endpoint_id`) |
| `POST` | `/sensors/ingest/webhook` | todos** | Ingestar evento de sensor |
| `GET` | `/sensors/players/{id}/ingest-events` | todos* | Historial de ingestas |

*player solo sus propios datos. **player solo su propio `player_id`.

**Flujo para primera configuración de sensor:**
```
1. GET /sensors → id_online_sensor
2. POST /sensors/players/{id}/link → vincula sensor al jugador
3. GET /sensors/{id}/endpoints → id_sensor_endpoint
4. POST /sensors/players/{id}/link-endpoint → id_players_sensor_endpoint
5. POST /sensors/ingest/webhook usando los IDs obtenidos
```

### IC² LSG ← v1.2

| Método | Ruta | Roles | Descripción |
|--------|------|-------|-------------|
| `POST` | `/ic2/compute` | todos* | Calcula IC² (F1-F4, Ec.5-7, IAR). Registra en `ic2_result` e `interaction_logs` |
| `GET` | `/ic2/history` | todos* | Historial de resultados por jugador |
| `GET` | `/ic2/goalposts` | todos | Goalposts y estrategias de normalización de una versión |

*player solo su propio `player_id`.

```bash
# Calcular IC² para jugador 26
curl -X POST 'https://lsg.diinf.usach.cl/lsg-core-api/ic2/compute' \
  -H 'Authorization: Bearer <TOKEN>' \
  -H 'Content-Type: application/json' \
  -d '{
    "player_id": 26,
    "version_tag": "v1.0",
    "experiment_tag": "LSG_C1_T1_CV",
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
| `POST` | `/offline/sync` | todos* | Sincroniza lote offline. HTTP 207. Idempotente por `client_ref` UUID. Ventana: 30 días |
| `GET` | `/offline/queue` | todos* | Estado de la cola (PENDING/SYNCED/REJECTED/DUPLICATE) |

*player solo su propia cola.

**`source_type` en `points_ledger`:** los puntos offline se registran con `source_type = 'OFFLINE_GAME'`. El `client_ref` (UUID generado por el mod) garantiza idempotencia.

### Analytics

| Método | Ruta | Roles | Descripción |
|--------|------|-------|-------------|
| `GET` | `/analytics/points-balance` | admin, researcher | Balance global de puntos |
| `GET` | `/analytics/player-game-overview` | admin, researcher | Resumen por jugador y juego |
| `GET` | `/analytics/player-attribute-balance` | admin, researcher | Balance por atributo |
| `GET` | `/analytics/games/time-to-first-redeem` | admin, researcher | Tiempo hasta primer canje |
| `GET` | `/analytics/sensors/quality` | admin, researcher | Calidad de ingestión por sensor |
| `GET` | `/analytics/sensors/ingest-vs-points` | admin, researcher | Tasa de conversión sensor→puntos |
| `GET` | `/analytics/ic2/summary` | admin, researcher | Estadísticos IC² por condición y período (compatible Q01 FONDECYT) |

### Admin configuración

| Método | Ruta | Roles | Descripción |
|--------|------|-------|-------------|
| `GET/POST/PUT/DELETE` | `/admin/attributes` | admin (write), researcher (read) | CRUD atributos |
| `GET/POST/PUT/DELETE` | `/admin/subattributes` | admin (write), researcher (read) | CRUD subatributos |
| `GET/POST/PUT/DELETE` | `/admin/point-dimensions` | admin (write), researcher (read) | CRUD dimensiones de puntos |
| `GET/POST/PUT/DELETE` | `/admin/modifiable-mechanics` | admin (write), researcher (read) | CRUD mecánicas |
| `GET/POST/PUT/DELETE` | `/admin/modifiable-mechanics-videogames` | admin (write), researcher (read) | Vínculo mecánica↔juego |
| `GET` | `/admin/points/consistency-check` | admin, researcher | Checks de integridad del ledger |

### Exportación investigación

| Método | Ruta | Roles | Descripción |
|--------|------|-------|-------------|
| `GET` | `/research/export/points` | admin, researcher | Ledger seudonimizado (JSON/CSV) |
| `GET` | `/research/export/sessions` | admin, researcher | Sesiones de juego (JSON/CSV) |
| `GET` | `/research/export/sensors` | admin, researcher | Eventos de sensor (JSON/CSV) |
| `GET` | `/research/export/ic2` | admin, researcher | Resultados IC² con señales crudas (JSON/CSV). Compatible con Q01-Q07 FONDECYT |

```bash
# Exportar IC² a CSV para análisis en R/Python
curl -X GET \
  'https://lsg.diinf.usach.cl/lsg-core-api/research/export/ic2?experiment_tag=LSG_C1_T1_CV&format=csv' \
  -H 'Authorization: Bearer <TOKEN>' \
  --output ic2_export.csv
```

---

## Changelog

### v1.2.1 (2026-05) — fixes de producción

- **BD — PATCH-07:** `source_type` ENUM de `points_ledger` extendido con `OFFLINE_GAME`. Resuelve error `Data truncated` en `POST /offline/sync`.
- **`games.py`:** campo `options` en `GET /videogames/{id}/mechanics` parseado como JSON (era string). `interaction_logs` de `session_end` y `redeem` corregidos (`strftime` en vez de `str()` para timestamp).
- **`ic2.py`:** campo `goalposts` en `GET /ic2/goalposts` parseado como JSON (era string).
- **`points.py`:** `GET /attributes-map` parsea resultado del stored procedure como JSON.
- **`sensors.py`:** 4 nuevos endpoints de gestión: `POST /sensors`, `POST /sensors/{id}/endpoints`, `POST /sensors/players/{id}/link`, `POST /sensors/players/{id}/link-endpoint`. Documentación del webhook mejorada con flujo de IDs.
- **`analytics.py`:** `GET /analytics/ic2/summary` integrado (estadísticos por condición/período).
- **`research_export.py`:** `GET /research/export/ic2` integrado con soporte CSV flat y seudonimización.

### v1.2.0 (2026-05)

- `ic2.py` — nuevo módulo: `POST /ic2/compute`, `GET /ic2/history`, `GET /ic2/goalposts`.
- `offline.py` — nuevo módulo: `POST /offline/sync` (idempotente), `GET /offline/queue`.
- `games.py` — `POST /{id}/mechanics/bulk` (hasta 500 mecánicas, HTTP 207). `PATCH sessions/{sid}/end` calcula `duration_seconds`.
- BD: PATCH-03 (tablas IC²), PATCH-04 (offline queue), PATCH-05 (sp_bulk_attach), PATCH-06 (R1-R6 + v_ic2_latest).

### v1.1.0 (2026-05)

- `security.py` — `AUTH_OPEN_ALL=false` por defecto. `CurrentUser.roles` como lista con fallback legacy.
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