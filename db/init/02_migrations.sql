-- 02_migrations.sql - LSG Core API  |  Estado al 2026-05-14
-- Ejecutar DESPUÉS de 01_db_lsg_dump.sql
--
-- Contenido: objetos que NO están en el dump de producción actual
-- pero son necesarios para el funcionamiento completo del sistema.
--
-- NOTA: Si usas docker-entrypoint-initdb.d, estos archivos se
-- ejecutan automáticamente en orden alfabético (01 → 02) solo al
-- crear el volumen por primera vez (docker compose up -v).
--
-- Para aplicar en una BD existente:
--   docker compose exec db mysql -u$DB_USER -p$DB_PASSWORD $DB_NAME \
--     < db/init/02_migrations.sql

-- 1. sp_assign_role

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

-- 2. v_export

CREATE OR REPLACE VIEW `v_export` AS
SELECT
  SHA2(CONCAT('LSG_2026:', r.id_players), 256) AS player_pseudo,
  r.experiment_tag,
  SUBSTRING_INDEX(r.experiment_tag, '_', -1)             AS condicion,
  SUBSTRING_INDEX(SUBSTRING_INDEX(r.experiment_tag,'_',3),'_',-1) AS periodo,
  r.window_start,
  r.window_end,
  r.Icf, r.Isfg, r.Ipma, r.Itd,
  r.IC_fis, r.IC_ment, r.IC_LSG, r.IAR,
  JSON_VALUE(r.admissibility,'$.Icf')   AS adm_Icf,
  JSON_VALUE(r.admissibility,'$.Isfg')  AS adm_Isfg,
  JSON_VALUE(r.admissibility,'$.Ipma')  AS adm_Ipma,
  JSON_VALUE(r.admissibility,'$.Itd')   AS adm_Itd,
  JSON_VALUE(r.raw_inputs,'$.steps_day')              AS steps_day,
  JSON_VALUE(r.raw_inputs,'$.MVPA_min_week')          AS MVPA_min_week,
  JSON_VALUE(r.raw_inputs,'$.resting_hr_bpm')         AS resting_hr_bpm,
  JSON_VALUE(r.raw_inputs,'$.sleep_quality_score')    AS sleep_quality_score,
  JSON_VALUE(r.raw_inputs,'$.memory_accuracy_pct')    AS memory_accuracy_pct,
  JSON_VALUE(r.raw_inputs,'$.recall_speed_ms')        AS recall_speed_ms,
  JSON_VALUE(r.raw_inputs,'$.decision_accuracy_pct')  AS decision_accuracy_pct,
  JSON_VALUE(r.raw_inputs,'$.reaction_time_ms')       AS reaction_time_ms,
  r.computed_at
FROM `ic2_result` r
WHERE r.experiment_tag IS NOT NULL;

-- 3. Verificación final

SELECT CONCAT(
  '02_migrations.sql aplicado correctamente — ',
  NOW()
) AS status;

SELECT routine_name AS procedimiento_disponible
FROM information_schema.ROUTINES
WHERE routine_schema = DATABASE()
  AND routine_type   = 'PROCEDURE'
ORDER BY routine_name;

SELECT table_name AS vista_disponible
FROM information_schema.VIEWS
WHERE table_schema = DATABASE()
ORDER BY table_name;