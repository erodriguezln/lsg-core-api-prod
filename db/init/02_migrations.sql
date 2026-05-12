-- Verificar si ya fue aplicado (idempotente)
SET @patch01 = (SELECT COUNT(*) FROM information_schema.tables
                WHERE table_schema = DATABASE()
                  AND table_name = 'player_roles');

SET @sql01 = IF(@patch01 = 0,
  'SELECT 1',   -- ya existe, saltar
  'SELECT 1'    -- placeholder, ver bloque real abajo
);

-- Aplicar solo si player_roles no existe
CREATE TABLE IF NOT EXISTS `player_roles` (
  `id_player_role`  INT          NOT NULL AUTO_INCREMENT,
  `id_players`      INT          NOT NULL,
  `role`            VARCHAR(32)  NOT NULL,
  `assigned_at`     TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `assigned_by`     INT          NULL COMMENT 'id_players del admin asignador',
  `revoked_at`      TIMESTAMP    NULL     COMMENT 'NULL = rol activo',
  PRIMARY KEY (`id_player_role`),
  UNIQUE KEY `uq_player_role_active` (`id_players`, `role`, `revoked_at`),
  KEY `ix_pr_player`  (`id_players`),
  KEY `ix_pr_active`  (`id_players`, `revoked_at`),
  CONSTRAINT `fk_pr_player`      FOREIGN KEY (`id_players`)  REFERENCES `players` (`id_players`),
  CONSTRAINT `fk_pr_assigned_by` FOREIGN KEY (`assigned_by`) REFERENCES `players` (`id_players`),
  CONSTRAINT `chk_pr_role`       CHECK (`role` IN ('player','researcher','admin','teacher'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
  COMMENT='Roles activos/históricos por jugador. Reemplaza players.role (deprecated).';

-- Migrar rol existente de players → player_roles (solo si role aún existe en players)
-- Si players.role ya fue eliminado, este bloque falla silenciosamente por el IF.
SET @has_role_col = (
  SELECT COUNT(*) FROM information_schema.columns
  WHERE table_schema = DATABASE()
    AND table_name   = 'players'
    AND column_name  = 'role'
);

-- Insertar roles existentes (bootstrap desde players.role si existe)
-- Si players.role no existe, asignar 'player' como rol por defecto a todos.
INSERT IGNORE INTO `player_roles` (`id_players`, `role`, `assigned_at`, `assigned_by`)
SELECT
  id_players,
  COALESCE(
    (SELECT column_default FROM information_schema.columns
     WHERE table_schema = DATABASE() AND table_name = 'players' AND column_name = 'role'
     LIMIT 1),
    'player'
  ),
  created_at,
  NULL
FROM `players`
WHERE id_players NOT IN (SELECT DISTINCT id_players FROM player_roles);

-- Asignar roles correctos para usuarios conocidos del equipo LSG
-- (ajustar id_players según tu BD si difieren del dump de referencia)
UPDATE `player_roles` SET `role` = 'admin'
WHERE `id_players` IN (
  SELECT id_players FROM players WHERE email IN (
    'joaquin.macias@usach.cl',
    'roberto.gonzalez.i@usach.cl'
  )
) AND `revoked_at` IS NULL;

UPDATE `player_roles` SET `role` = 'researcher'
WHERE `id_players` IN (
  SELECT id_players FROM players WHERE email IN (
    'alejandro.aldea@usach.cl',
    'hernan.herrera@usach.cl',
    'luis.mellado.v@usach.cl',
    'williams.jimenez@usach.cl',
    'aracely.castro@usach.cl',
    'ricardo.avaca@usach.cl',
    'enrique.rodriguez-lapuente@usach.cl',
    'nicolas.gabrielli@usach.cl'
  )
) AND `revoked_at` IS NULL;

-- Vista helper: roles activos por jugador
CREATE OR REPLACE VIEW `v_player_active_roles` AS
SELECT
  p.id_players,
  p.name         AS player_name,
  p.email,
  pr.role,
  pr.assigned_at,
  pr.assigned_by
FROM `players`      p
JOIN `player_roles` pr ON pr.id_players = p.id_players
                       AND pr.revoked_at IS NULL;

-- Stored procedure: asignar/revocar rol (usado por PATCH /admin/players/:id/roles)
DROP PROCEDURE IF EXISTS `sp_assign_role`;
DELIMITER $$
CREATE PROCEDURE `sp_assign_role`(
  IN  p_target_player_id  INT,
  IN  p_role              VARCHAR(32),
  IN  p_admin_player_id   INT,
  IN  p_action            ENUM('grant','revoke')
)
BEGIN
  IF p_action = 'grant' THEN
    INSERT IGNORE INTO `player_roles`
      (`id_players`, `role`, `assigned_by`)
    VALUES
      (p_target_player_id, p_role, p_admin_player_id);
  ELSEIF p_action = 'revoke' THEN
    UPDATE `player_roles`
    SET    `revoked_at` = NOW()
    WHERE  `id_players` = p_target_player_id
      AND  `role`       = p_role
      AND  `revoked_at` IS NULL;
  END IF;
END$$
DELIMITER ;

CREATE TABLE IF NOT EXISTS `interaction_logs` (
  `id_interaction_log`  BIGINT        NOT NULL AUTO_INCREMENT,
  `id_players`          INT           NOT NULL,
  `id_videogame`        INT UNSIGNED  NOT NULL DEFAULT 0
    COMMENT '0 = evento sin videojuego específico (ej: ic2_compute)',
  `event_type`          VARCHAR(64)   NOT NULL
    COMMENT 'ej: redeem, sensor_ingest, session_start, ic2_compute',
  `experiment_tag`      VARCHAR(128)  NULL
    COMMENT 'etiqueta FONDECYT (ej: LSG_PILOT_2026_T1)',
  `occurred_at`         TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `metrics`             JSON          NULL
    COMMENT 'payload de métricas: {IC_fis, IC_ment, IC_LSG, IAR, ...}',
  `created_at`          TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_interaction_log`),
  KEY `ix_il_player_time`  (`id_players`, `occurred_at`),
  KEY `ix_il_experiment`   (`experiment_tag`),
  KEY `ix_il_event_type`   (`event_type`),
  CONSTRAINT `fk_il_player` FOREIGN KEY (`id_players`) REFERENCES `players` (`id_players`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
  COMMENT='Bitácora de interacciones para análisis longitudinal FONDECYT';

-- 3a. Catálogo de goalposts versionados
CREATE TABLE IF NOT EXISTS `ic2_goalpost_version` (
  `id_version`    INT          NOT NULL AUTO_INCREMENT,
  `version_tag`   VARCHAR(32)  NOT NULL COMMENT 'ej: v1.0-SCCC2026',
  `published_at`  DATE         NOT NULL,
  `description`   VARCHAR(300) NULL,
  `is_active`     TINYINT(1)   NOT NULL DEFAULT 1,
  `goalposts`     JSON         NOT NULL,
  `created_at`    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_version`),
  UNIQUE KEY `uq_version_tag` (`version_tag`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Insertar versión baseline (paper SCCC 2026)
INSERT IGNORE INTO `ic2_goalpost_version`
  (`version_tag`, `published_at`, `description`, `goalposts`)
VALUES (
  'v1.0-SCCC2026',
  '2026-05-06',
  'Goalposts baseline IC2_LSG - Macías-Cáceres et al., SCCC 2026',
  JSON_OBJECT(
    'Icf', JSON_OBJECT(
      'MVPA',  JSON_OBJECT('min',0,'max',300,'strategy','F2','direction','+'),
      'steps', JSON_OBJECT('min',0,'max',12000,'strategy','F2','direction','+')
    ),
    'Isfg', JSON_OBJECT(
      'resting_hr',    JSON_OBJECT('min',40,'max',100,'strategy','F3',
                                   'direction','-','theta',60,'alpha',0.2),
      'sleep_quality', JSON_OBJECT('min',0,'max',10,'strategy','F4','direction','+')
    ),
    'Ipma', JSON_OBJECT(
      'memory_accuracy', JSON_OBJECT('min',0,'max',100,'strategy','F1','direction','+'),
      'recall_speed_ms', JSON_OBJECT('min',200,'max',1800,'strategy','F1','direction','-')
    ),
    'Itd', JSON_OBJECT(
      'decision_accuracy', JSON_OBJECT('min',0,'max',100,'strategy','F1','direction','+'),
      'reaction_time_ms',  JSON_OBJECT('min',150,'max',1000,'strategy','F1','direction','-')
    )
  )
);

-- 3b. Resultados IC² por jugador/período
CREATE TABLE IF NOT EXISTS `ic2_result` (
  `id_ic2_result`  BIGINT       NOT NULL AUTO_INCREMENT,
  `id_players`     INT          NOT NULL,
  `id_version`     INT          NOT NULL,
  `window_start`   DATE         NOT NULL,
  `window_end`     DATE         NOT NULL,
  `Icf`            DECIMAL(6,4) NULL,
  `Isfg`           DECIMAL(6,4) NULL,
  `Ipma`           DECIMAL(6,4) NULL,
  `Itd`            DECIMAL(6,4) NULL,
  `IC_fis`         DECIMAL(6,4) NULL,
  `IC_ment`        DECIMAL(6,4) NULL,
  `IC_LSG`         DECIMAL(6,4) NULL,
  `IAR`            DECIMAL(6,4) NULL,
  `admissibility`  JSON         NULL,
  `raw_inputs`     JSON         NULL,
  `experiment_tag` VARCHAR(128) NULL,
  `computed_at`    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_ic2_result`),
  UNIQUE KEY `uq_ic2_player_window` (`id_players`,`id_version`,`window_start`),
  KEY `ix_ic2_player`     (`id_players`),
  KEY `ix_ic2_experiment` (`experiment_tag`),
  CONSTRAINT `fk_ic2_player`  FOREIGN KEY (`id_players`) REFERENCES `players` (`id_players`),
  CONSTRAINT `fk_ic2_version` FOREIGN KEY (`id_version`) REFERENCES `ic2_goalpost_version` (`id_version`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 3c. Reglas del catálogo versionadas
CREATE TABLE IF NOT EXISTS `ic2_rule` (
  `id_rule`        INT          NOT NULL AUTO_INCREMENT,
  `id_version`     INT          NOT NULL,
  `rule_code`      VARCHAR(8)   NOT NULL,
  `rule_type`      ENUM('reward','guardrail','synergy') NOT NULL,
  `condition_json` JSON         NOT NULL,
  `effect_json`    JSON         NOT NULL,
  `duration_hrs`   INT          NULL,
  `description`    VARCHAR(300) NULL,
  PRIMARY KEY (`id_rule`),
  KEY `ix_rule_version` (`id_version`),
  CONSTRAINT `fk_rule_version` FOREIGN KEY (`id_version`) REFERENCES `ic2_goalpost_version` (`id_version`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS `offline_points_queue` (
  `id_offline_queue`      BIGINT       NOT NULL AUTO_INCREMENT,
  `id_players`            INT          NOT NULL,
  `id_videogame`          INT UNSIGNED NOT NULL,
  `id_point_dimension`    INT          NOT NULL,
  `direction`             ENUM('CREDIT','DEBIT') NOT NULL,
  `amount`                INT          NOT NULL,
  `source_type`           VARCHAR(32)  NOT NULL DEFAULT 'OFFLINE_GAME',
  `client_ref`            VARCHAR(128) NOT NULL
    COMMENT 'UUID generado por cliente - garantiza idempotencia',
  `client_generated_at`   TIMESTAMP    NOT NULL,
  `payload`               JSON         NULL,
  `status`                ENUM('PENDING','SYNCED','REJECTED','DUPLICATE') NOT NULL DEFAULT 'PENDING',
  `sync_attempt_at`       TIMESTAMP    NULL,
  `synced_at`             TIMESTAMP    NULL,
  `id_points_ledger`      BIGINT       NULL
    COMMENT 'FK al ledger tras sincronización exitosa',
  `rejection_reason`      VARCHAR(300) NULL,
  `created_at`            TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_offline_queue`),
  UNIQUE KEY `uq_offline_client_ref` (`client_ref`),
  KEY `ix_offline_player_status` (`id_players`, `status`),
  CONSTRAINT `fk_oq_player`  FOREIGN KEY (`id_players`)      REFERENCES `players` (`id_players`),
  CONSTRAINT `fk_oq_dim`     FOREIGN KEY (`id_point_dimension`) REFERENCES `point_dimension` (`id_point_dimension`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
  COMMENT='Cola de puntos generados offline. Sincroniza en reconexión. Ventana: 30 días.';

DROP PROCEDURE IF EXISTS `sp_bulk_attach_mechanics`;
DELIMITER $$
CREATE PROCEDURE `sp_bulk_attach_mechanics`(
  IN p_videogame_id   INT,
  IN p_mechanics_json JSON
)
proc_label: BEGIN
  DECLARE i         INT DEFAULT 0;
  DECLARE total     INT;
  DECLARE mec_name  VARCHAR(150);
  DECLARE mec_desc  VARCHAR(300);
  DECLARE mec_type  VARCHAR(50);
  DECLARE mec_opts  JSON;
  DECLARE new_mm_id INT;

  SET total = JSON_LENGTH(p_mechanics_json);

  IF total = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lista de mecánicas vacía';
  END IF;

  START TRANSACTION;
  WHILE i < total DO
    SET mec_name = JSON_UNQUOTE(JSON_EXTRACT(p_mechanics_json,
                                  CONCAT('$[', i, '].name')));
    SET mec_desc = JSON_UNQUOTE(JSON_EXTRACT(p_mechanics_json,
                                  CONCAT('$[', i, '].description')));
    SET mec_type = JSON_UNQUOTE(JSON_EXTRACT(p_mechanics_json,
                                  CONCAT('$[', i, '].type')));
    SET mec_opts = JSON_EXTRACT(p_mechanics_json,
                                  CONCAT('$[', i, '].options'));

    INSERT IGNORE INTO `modifiable_mechanic` (`name`, `description`, `type`)
    VALUES (mec_name, mec_desc, mec_type);

    SELECT `id_modifiable_mechanic` INTO new_mm_id
    FROM   `modifiable_mechanic` WHERE `name` = mec_name LIMIT 1;

    INSERT IGNORE INTO `modifiable_mechanic_videogames`
      (`id_videogame`, `id_modifiable_mechanic`, `options`)
    VALUES (p_videogame_id, new_mm_id, mec_opts);

    SET i = i + 1;
  END WHILE;
  COMMIT;

  SELECT CONCAT('OK: ', total, ' mecánicas procesadas para videojuego ',
                p_videogame_id) AS result;
END$$
DELIMITER ;

-- Insertar reglas R1-R6 (idempotente con INSERT IGNORE)
INSERT IGNORE INTO `ic2_rule`
  (`id_version`, `rule_code`, `rule_type`, `condition_json`, `effect_json`,
   `duration_hrs`, `description`)
SELECT
  v.id_version,
  t.rule_code, t.rule_type, t.condition_json, t.effect_json,
  t.duration_hrs, t.description
FROM `ic2_goalpost_version` v
CROSS JOIN (
  SELECT 'R1' AS rule_code, 'reward' AS rule_type,
    JSON_OBJECT('IC_fis',JSON_OBJECT('gte',0.60),'consecutive_days',7) AS condition_json,
    JSON_OBJECT('stamina_pct',10,'regen_speed_pct',5)                  AS effect_json,
    48 AS duration_hrs,
    '+10% stamina; +5% velocidad de regeneración durante 48 hrs.'      AS description
  UNION ALL
  SELECT 'R2','reward',
    JSON_OBJECT('IC_ment',JSON_OBJECT('gte',0.55)),
    JSON_OBJECT('skill_cooldown_pct',-15),
    24,'-15% cooldown de habilidades cognitivas durante 24 hrs.'
  UNION ALL
  SELECT 'R3','reward',
    JSON_OBJECT('IC_LSG',JSON_OBJECT('gte',0.60),'IC_fis',JSON_OBJECT('gte',0.60),
                'IC_ment',JSON_OBJECT('gte',0.55)),
    JSON_OBJECT('drop_rate_pct',5,'special_quest',true),
    72,'+5% drop-rate; acceso a quest especial durante 72 hrs.'
  UNION ALL
  SELECT 'R4','guardrail',
    JSON_OBJECT('IC_fis',JSON_OBJECT('lt',0.40),'consecutive_days',3),
    JSON_OBJECT('active_pause_mission',true,'boost_softlimit',true,
                'boost_resume_threshold',JSON_OBJECT('IC_fis_gte',0.45)),
    NULL,'Misión de recuperación (pausa activa); softlimit de boosts hasta IC_fis≥0.45.'
  UNION ALL
  SELECT 'R5','guardrail',
    JSON_OBJECT('IC_ment',JSON_OBJECT('lt',0.35)),
    JSON_OBJECT('cognitive_mission_suggested',true,'mission_duration_min',5),
    NULL,'Misión cognitiva breve (test 5 min.) sugerida al inicio de sesión.'
  UNION ALL
  SELECT 'R6','synergy',
    JSON_OBJECT('IC_fis',JSON_OBJECT('gte',0.70),'IC_ment',JSON_OBJECT('gte',0.65)),
    JSON_OBJECT('region_unlock',true,'special_narrative_event',true),
    96,'Sinergia: desbloqueo de región/evento narrativo especial durante 96 hrs.'
) t
WHERE v.version_tag = 'v1.0-SCCC2026';

-- Vista v_ic2_latest: último resultado IC² por jugador y versión
CREATE OR REPLACE VIEW `v_ic2_latest` AS
SELECT
  r.id_ic2_result,
  r.id_players,
  p.name               AS player_name,
  p.email              AS player_email,
  v.version_tag,
  r.window_start,
  r.window_end,
  r.Icf, r.Isfg, r.Ipma, r.Itd,
  r.IC_fis, r.IC_ment, r.IC_LSG, r.IAR,
  r.admissibility,
  r.experiment_tag,
  r.computed_at
FROM `ic2_result`          r
JOIN `players`              p ON p.id_players  = r.id_players
JOIN `ic2_goalpost_version` v ON v.id_version  = r.id_version
WHERE r.computed_at = (
  SELECT MAX(r2.computed_at)
  FROM   `ic2_result` r2
  WHERE  r2.id_players = r.id_players
    AND  r2.id_version  = r.id_version
);