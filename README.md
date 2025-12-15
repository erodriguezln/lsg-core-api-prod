# LSG Core API (LifeSync-Games)

Servicio FastAPI que expone la lógica de dominio de LifeSync-Games sobre la base de datos `db_lsg` (MySQL 8).

Integra:

- MySQL 8 con el dump oficial de `db_lsg`.
- FastAPI con routers por dominio (`players`, `points`, `games`, `sensors`, `analytics`).
- Capa de autenticación/autorización vía JWT (integrable con `lsg-auth`).
- Endpoints administrativos para configuración (`/admin/...`), consistencia de puntos, calidad de sensores y exportación de datos para investigación.

---

## Requisitos

- Docker y Docker Compose instalados.
- Dump actualizado de `db_lsg` (archivo `.sql` incluido en `db/init/`).

---

## Estructura del proyecto

```text
lsg-core-api/
│
├── app/
│   ├── api/
│   │   ├── health.py          # /health, /health/full
│   │   ├── meta.py            # /meta/info
│   │   ├── players.py         # /players/... (+ /players/{id}/timeline)
│   │   ├── points.py          # /attributes..., /points..., /players/{id}/points/...
│   │   ├── games.py           # /videogames/..., canjes y sesiones de juego
│   │   ├── sensors.py         # /sensors/... (config e ingest)
│   │   ├── analytics.py       # /analytics/... (puntos, juegos, sensores)
│   │   ├── admin_config.py    # /admin/... (atributos, dimensiones, mecánicas)
│   │   ├── admin_points.py    # /admin/points/consistency-check
│   │   └── research_export.py # /research/export/... (puntos, sesiones, sensores)
│   │
│   ├── security.py            # JWT, roles y dependencias de autorización
│   ├── db.py                  # conexión SQLAlchemy a MySQL
│   └── main.py                # instancia FastAPI y registro de routers
│
├── db/
│   └── init/
│       └── 01_db_lsg_dump.sql # dump de la base de datos
│
├── Dockerfile
├── docker-compose.yml
└── requirements.txt
```

### Puesta en marcha local

1. Clonar el repositorio y ubicar el dump de db_lsg en db/init/01_db_lsg_dump.sql.
2. Levantar el stack: `docker compose up --build`
3. Endpoints principales:
- API base: `http://localhost:8000`
- Documentación interactiva (Swagger): `http://localhost:8000/docs`
- Health básico: `GET /health`
- Health extendido: `GET /health/full`

En el `docker-compose.yml` se definen por defecto las variables de conexión a MySQL y el modo de autenticación

### Variables de entorno

#### Base de datos

Definidas típicamente en el servicio api de docker-compose.yml:
- DB_HOST (p.ej. db)
- DB_PORT (p.ej. 3306)
- DB_NAME (p.ej. db_lsg)
- DB_USER (p.ej. lsg_user)
- DB_PASSWORD

#### API / entorno

- APP_ENV: Entorno lógico (local, dev, prod, etc.).
- API_VERSION: Versión de la API expuesta (usada en /meta/info).
- GIT_COMMIT: Identificador de commit (opcional, también expuesto en /meta/info).

#### Seguridad (JWT)

- AUTH_DISABLED

true: modo desarrollo (no se exige JWT, se asume un usuario admin ficticio).
false: se exige JWT válido en los endpoints protegidos.

- AUTH_JWT_SECRET
- AUTH_JWT_ALGORITHM (por ejemplo, HS256)
- AUTH_JWT_ISSUER (opcional)
- AUTH_JWT_AUDIENCE (opcional)

#### Seudonimización para investigación

- RESEARCH_PSEUDONYM_SALT
Salt para generar identificadores seudonimizados (player_pseudo) en los exports de investigación.

#### Autenticación y roles

La API está preparada para integrarse con el servicio de autenticación lsg-auth vía JWT.

En app/security.py se define:

- Decodificación de JWT y extracción de claims (sub, role, player_id, email, etc.).
- Modelo CurrentUser.
- Dependencias de autorización por rol:
- require_admin
- require_admin_or_researcher
- require_teacher_or_higher
- guard_player_access (jugador solo accede a sus propios datos; roles altos con acceso ampliado).

En modo local (AUTH_DISABLED=true), las dependencias se resuelven con un usuario admin ficticio para facilitar pruebas.

#### Endpoints por dominio (resumen)

##### Salud y metadatos

- GET /health
Liveness básico.

- GET /health/full
Health extendido: conexión a DB + vistas críticas (v_points_balance, v_player_game_overview, v_player_attribute_balance).

- GET /meta/info
Información de versión, entorno y base de datos (api_version, environment, git_commit, database.host, database.name).

##### Jugadores (/players)

- Listado y detalle de jugadores.

- Inicialización de atributos (/players/{id}/attributes/init).

- Juegos asociados a un jugador (/players/{id}/games).

- Timeline unificado de eventos del jugador:

- GET /players/{player_id}/timeline
Combina sesiones de juego, movimientos de puntos, ingestas de sensor y canjes en un solo flujo temporal.

##### Puntos y atributos (/attributes, /points, /players/{id}/points/...)

- GET /attributes

- GET /attributes/{id}/subattributes

- GET /attributes-map (usa función sp_get_att_subattributes_name()).

- GET /players/{id}/points/balance
Lectura desde v_points_balance.

- GET /players/{id}/attributes/points
Lectura desde v_player_attribute_balance.

- GET /points/ledger
Consulta filtrable del ledger de puntos (por jugador, juego, tipo de fuente, rango temporal).

- POST /players/{id}/points/adjust
Inserta ajustes manuales de puntos (DEBIT/CREDIT) con source_type='ADJUST'.

##### Videojuegos y canjes (/videogames)

- Listado y detalle de videojuegos.

- Mecánicas modificables por juego.

Sesiones de juego

- POST /videogames/{game_id}/players/{player_id}/sessions

- PATCH /videogames/{game_id}/players/{player_id}/sessions/{session_id}/end

Canjes de puntos

- POST /videogames/{game_id}/players/{player_id}/redeem/preview
Calcula si el jugador tiene saldo suficiente y cuál sería el saldo resultante, sin aplicar cambios.

- POST /videogames/{game_id}/players/{player_id}/redeem

Canje robusto:

- Verifica saldo contra v_points_balance.

- Inserta DEBIT en points_ledger con source_type='REDEMPTION'.

- Registra el canje en redemption_event.

##### Sensores (/sensors)

- Listado de sensores y endpoints de sensor.

- Asociación jugador-sensor.

Ingesta de eventos desde sensores

- POST /sensors/ingest/webhook
Guarda eventos en sensor_ingest_event (incluye status, parsed_value, raw_payload, etc.).

- Consulta de ingestas por jugador.

##### Analítica (/analytics)

Endpoints de lectura para análisis:

- GET /analytics/points-balance
Lectura genérica sobre v_points_balance.

- GET /analytics/player-game-overview
Basado en v_player_game_overview (puntos gastados, tiempo de juego con LSG, etc.).

- GET /analytics/player-attribute-balance
Lectura de v_player_attribute_balance por jugador/atributo.

- GET /analytics/games/time-to-first-redeem
Tiempo promedio (en minutos) desde la primera sesión hasta el primer canje, por juego.

##### Calidad de datos de sensores

- GET /analytics/sensors/quality
Agrega por jugador + endpoint:
- total_events
- ok_events, error_events, ignored_events
- tasas (ok_rate, error_rate, ignored_rate)
- first_event_at, last_event_at
- active_days, avg_events_per_day
- estadísticas básicas de parsed_value (min/avg/max)

- GET /analytics/sensors/ingest-vs-points
Cadena sensor_ingest_event → points_ledger (source_type='SENSOR'):
- ingest_events, points_events
- total_points
- conversion_rate
- avg_points_per_event

#### Administración de configuración (/admin)

En admin_config.py se expone CRUD seguro (solo admin/researcher) sobre tablas maestras:

- attributes y subattributes
- point_dimension
- modifiable_mechanic
- modifiable_mechanic_videogames

Ejemplos:

- GET /admin/attributes, POST /admin/attributes, PUT /admin/attributes/{id}, DELETE /admin/attributes/{id}
- GET /admin/point-dimensions, POST /admin/point-dimensions, etc.

Los deletes manejan conflictos de integridad referencial devolviendo 409 cuando un registro está en uso.

#### Consistencia de puntos (/admin/points)

- GET /admin/points/consistency-check

Ejecuta checks de consistencia:

1. Diferencias entre snapshot (players_attributes) y ledger (v_player_attribute_balance.diff_ledger_minus_snapshot).
2. Movimientos inválidos en points_ledger (amount <= 0).
3. Saldos negativos en v_points_balance.
4. Coherencia redemption_event ↔ points_ledger:
- Canjes huérfanos (sin fila en ledger).
- Ledger asociado a canje con direction/source_type incorrectos.

Devuelve un resumen por tipo de check (status, count, sample) y un status global (ok / issues_found).

#### Exportación de datos de investigación (/research)

- GET /research/export/points
- GET /research/export/games

## Estado actual endpoints (actualizado 2025-12-12)

- https://docs.google.com/spreadsheets/d/1UahJayUw2_KfOKv8wuGyeXMbrYnWpVx9YMGHSRPoxsA/edit?usp=sharing
