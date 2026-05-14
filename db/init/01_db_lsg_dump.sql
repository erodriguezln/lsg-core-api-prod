-- MySQL dump 10.13  Distrib 8.0.32, for Win64 (x86_64)
--
-- Host: localhost    Database: db_lsg
-- ------------------------------------------------------
-- Server version	8.0.43

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `adquired_subattribute`
--

DROP TABLE IF EXISTS `adquired_subattribute`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `adquired_subattribute` (
  `id_adquired_subattribute` int NOT NULL AUTO_INCREMENT,
  `id_players` int NOT NULL,
  `id_subattributes_conversion_sensor_endpoint` int NOT NULL,
  `data` int DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_adquired_subattribute`),
  KEY `fk_as_player` (`id_players`),
  KEY `fk_as_scse` (`id_subattributes_conversion_sensor_endpoint`),
  CONSTRAINT `fk_as_player` FOREIGN KEY (`id_players`) REFERENCES `players` (`id_players`),
  CONSTRAINT `fk_as_scse` FOREIGN KEY (`id_subattributes_conversion_sensor_endpoint`) REFERENCES `subattributes_conversion_sensor_endpoint` (`id_subattributes_conversion_sensor_endpoint`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `adquired_subattribute`
--

LOCK TABLES `adquired_subattribute` WRITE;
/*!40000 ALTER TABLE `adquired_subattribute` DISABLE KEYS */;
/*!40000 ALTER TABLE `adquired_subattribute` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `attributes`
--

DROP TABLE IF EXISTS `attributes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `attributes` (
  `id_attributes` int NOT NULL AUTO_INCREMENT,
  `name` varchar(45) DEFAULT NULL,
  `description` varchar(300) DEFAULT NULL,
  `data_type` varchar(45) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id_attributes`),
  UNIQUE KEY `uq_attr_name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `attributes`
--

LOCK TABLES `attributes` WRITE;
/*!40000 ALTER TABLE `attributes` DISABLE KEYS */;
INSERT INTO `attributes` VALUES (1,'Social','placeholder','placeholder','2022-04-20 03:14:07','2022-04-20 03:14:07'),(2,'Fisico','placeholder','placeholder','2022-04-20 03:14:07','2022-04-20 03:14:07'),(3,'Afectivo','placeholder','placeholder','2022-04-20 03:14:07','2022-04-20 03:14:07'),(4,'Mental','placeholder','placeholder','2022-04-20 03:14:07','2022-04-20 03:14:07'),(5,'Linguistico','placeholder','placeholder','2022-04-20 03:14:07','2022-04-20 03:14:07');
/*!40000 ALTER TABLE `attributes` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`%`*/ /*!50003 TRIGGER `trg_attributes_ins` AFTER INSERT ON `attributes` FOR EACH ROW BEGIN
  INSERT INTO audit_log(table_name, op, row_pk, changed_by, new_row)
  VALUES (
    'attributes',
    'INSERT',
    CAST(NEW.id_attributes AS CHAR),
    COALESCE(@app_user, CURRENT_USER()),
    JSON_OBJECT(
      'id_attributes', NEW.id_attributes,
      'name',         NEW.name,
      'description',  NEW.description,
      'data_type',    NEW.data_type,
      'created_at',   NEW.created_at,
      'updated_at',   NEW.updated_at
    )
  );
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`%`*/ /*!50003 TRIGGER `trg_attributes_upd` AFTER UPDATE ON `attributes` FOR EACH ROW BEGIN
  INSERT INTO audit_log(table_name, op, row_pk, changed_by, old_row, new_row)
  VALUES (
    'attributes',
    'UPDATE',
    CAST(NEW.id_attributes AS CHAR),
    COALESCE(@app_user, CURRENT_USER()),
    JSON_OBJECT(
      'id_attributes', OLD.id_attributes,
      'name',         OLD.name,
      'description',  OLD.description,
      'data_type',    OLD.data_type,
      'created_at',   OLD.created_at,
      'updated_at',   OLD.updated_at
    ),
    JSON_OBJECT(
      'id_attributes', NEW.id_attributes,
      'name',         NEW.name,
      'description',  NEW.description,
      'data_type',    NEW.data_type,
      'created_at',   NEW.created_at,
      'updated_at',   NEW.updated_at
    )
  );
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`%`*/ /*!50003 TRIGGER `trg_attributes_del` AFTER DELETE ON `attributes` FOR EACH ROW BEGIN
  INSERT INTO audit_log(table_name, op, row_pk, changed_by, old_row)
  VALUES (
    'attributes',
    'DELETE',
    CAST(OLD.id_attributes AS CHAR),
    COALESCE(@app_user, CURRENT_USER()),
    JSON_OBJECT(
      'id_attributes', OLD.id_attributes,
      'name',         OLD.name,
      'description',  OLD.description,
      'data_type',    OLD.data_type,
      'created_at',   OLD.created_at,
      'updated_at',   OLD.updated_at
    )
  );
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `audit_log`
--

DROP TABLE IF EXISTS `audit_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `audit_log` (
  `id_audit_log` bigint NOT NULL AUTO_INCREMENT,
  `table_name` varchar(64) NOT NULL,
  `op` enum('INSERT','UPDATE','DELETE') NOT NULL,
  `row_pk` varchar(128) NOT NULL,
  `changed_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `changed_by` varchar(128) DEFAULT NULL,
  `old_row` json DEFAULT NULL,
  `new_row` json DEFAULT NULL,
  PRIMARY KEY (`id_audit_log`),
  KEY `ix_audit_table_time` (`table_name`,`changed_at`),
  KEY `ix_audit_op_time` (`op`,`changed_at`)
) ENGINE=InnoDB AUTO_INCREMENT=34 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `audit_log`
--

LOCK TABLES `audit_log` WRITE;
/*!40000 ALTER TABLE `audit_log` DISABLE KEYS */;
INSERT INTO `audit_log` VALUES (1,'attributes','DELETE','8','2025-12-11 18:53:50','system','{\"name\": \"auto_attr_0\", \"data_type\": null, \"created_at\": null, \"updated_at\": null, \"description\": null, \"id_attributes\": 8}',NULL),(2,'attributes','DELETE','6','2025-12-11 20:50:04','system','{\"name\": \"pendiente_nombre\", \"data_type\": null, \"created_at\": null, \"updated_at\": null, \"description\": null, \"id_attributes\": 6}',NULL),(3,'attributes','DELETE','7','2025-12-11 20:50:12','system','{\"name\": \"auto_attr_0\", \"data_type\": null, \"created_at\": null, \"updated_at\": null, \"description\": null, \"id_attributes\": 7}',NULL),(4,'players','DELETE','35','2025-12-16 23:47:19','root@%','{\"age\": 33, \"name\": \"pconcepcion\", \"email\": \"pedro.concepcion@usach.cl\", \"created_at\": \"2025-12-16 23:45:14.000000\", \"id_players\": 35, \"updated_at\": \"2025-12-16 23:45:58.000000\", \"external_id\": null, \"external_type\": null}',NULL),(5,'players','DELETE','36','2025-12-17 01:23:37','root@%','{\"age\": 30, \"name\": \"pconcepcion\", \"email\": \"pedro.concepcion@usach.cl\", \"created_at\": \"2025-12-16 23:50:03.000000\", \"id_players\": 36, \"updated_at\": \"2025-12-16 23:50:40.000000\", \"external_id\": null, \"external_type\": null}',NULL),(6,'players','DELETE','34','2025-12-17 12:48:52','root@%','{\"age\": 35, \"name\": \"admin\", \"email\": \"joaquin.macias.caceres@gmail.com\", \"created_at\": \"2025-12-16 19:56:43.000000\", \"id_players\": 34, \"updated_at\": \"2025-12-16 21:44:42.000000\", \"external_id\": null, \"external_type\": null}',NULL),(7,'players','DELETE','33','2025-12-17 12:56:48','root@%','{\"age\": 0, \"name\": \"ngabrielli\", \"email\": \"nicolas.gabrielli@usach.cl\", \"created_at\": \"2025-12-11 20:47:16.000000\", \"id_players\": 33, \"updated_at\": \"2025-12-11 20:47:16.000000\", \"external_id\": null, \"external_type\": null}',NULL),(8,'players','DELETE','32','2025-12-17 12:58:14','root@%','{\"age\": 0, \"name\": \"erodriguez\", \"email\": \"enrique.rodriguez-lapuente@usach.cl\", \"created_at\": \"2025-12-11 20:46:47.000000\", \"id_players\": 32, \"updated_at\": \"2025-12-11 20:46:47.000000\", \"external_id\": null, \"external_type\": null}',NULL),(9,'players','DELETE','31','2025-12-17 12:59:28','root@%','{\"age\": 0, \"name\": \"ravaca\", \"email\": \"ricardo.avaca@usach.cl\", \"created_at\": \"2025-12-11 20:46:25.000000\", \"id_players\": 31, \"updated_at\": \"2025-12-11 20:46:25.000000\", \"external_id\": null, \"external_type\": null}',NULL),(10,'players','DELETE','30','2025-12-17 13:00:35','root@%','{\"age\": 0, \"name\": \"acastro\", \"email\": \"aracely.castro@usach.cl\", \"created_at\": \"2025-12-11 20:46:01.000000\", \"id_players\": 30, \"updated_at\": \"2025-12-11 20:46:01.000000\", \"external_id\": null, \"external_type\": null}',NULL),(11,'players','DELETE','28','2025-12-17 13:01:40','root@%','{\"age\": 0, \"name\": \"wjimenez\", \"email\": \"williams.jimenez@usach.cl\", \"created_at\": \"2025-12-11 20:45:26.000000\", \"id_players\": 28, \"updated_at\": \"2025-12-11 20:45:26.000000\", \"external_id\": null, \"external_type\": null}',NULL),(12,'players','DELETE','27','2025-12-17 13:02:58','root@%','{\"age\": 0, \"name\": \"rgonzalez\", \"email\": \"roberto.gonzalez.i@usach.cl\", \"created_at\": \"2025-12-11 20:44:59.000000\", \"id_players\": 27, \"updated_at\": \"2025-12-16 23:36:32.000000\", \"external_id\": null, \"external_type\": null}',NULL),(13,'redemption_event','DELETE','1','2025-12-17 13:04:09','root@%','{\"metadata\": {\"note\": \"Primer canje jmacias en UpperWish\"}, \"redeemed_at\": \"2025-12-10 19:06:00.000000\", \"redeemed_points\": 30, \"id_points_ledger\": 3, \"id_redemption_event\": 1, \"id_modifiable_mechanic_videogame\": 1}',NULL),(14,'points_ledger','DELETE','1','2025-12-17 13:04:09','root@%','{\"amount\": 80, \"payload\": {\"steps\": 8000, \"reason\": \"steps_to_points\"}, \"direction\": \"CREDIT\", \"created_at\": \"2025-12-10 08:00:05.000000\", \"id_players\": 26, \"source_ref\": \"d26d1e08-d6d7-11f0-bb4d-0242ac120002\", \"occurred_at\": \"2025-12-10 08:00:00.000000\", \"source_type\": \"SENSOR\", \"id_videogame\": 1, \"id_points_ledger\": 1, \"id_point_dimension\": 2, \"id_sensor_ingest_event\": 1}',NULL),(15,'points_ledger','DELETE','2','2025-12-17 13:04:09','root@%','{\"amount\": 40, \"payload\": {\"reason\": \"sleep_to_points\", \"minutes_asleep\": 420}, \"direction\": \"CREDIT\", \"created_at\": \"2025-12-11 00:00:05.000000\", \"id_players\": 26, \"source_ref\": \"d26d3cb4-d6d7-11f0-bb4d-0242ac120002\", \"occurred_at\": \"2025-12-11 00:00:00.000000\", \"source_type\": \"SENSOR\", \"id_videogame\": 1, \"id_points_ledger\": 2, \"id_point_dimension\": 3, \"id_sensor_ingest_event\": 2}',NULL),(16,'points_ledger','DELETE','3','2025-12-17 13:04:09','root@%','{\"amount\": 30, \"payload\": {\"mechanic\": \"Faster Peasants\"}, \"direction\": \"DEBIT\", \"created_at\": \"2025-12-10 19:05:05.000000\", \"id_players\": 26, \"source_ref\": \"redeem_26_uw_1\", \"occurred_at\": \"2025-12-10 19:05:00.000000\", \"source_type\": \"REDEMPTION\", \"id_videogame\": 1, \"id_points_ledger\": 3, \"id_point_dimension\": 2, \"id_sensor_ingest_event\": null}',NULL),(17,'sensor_ingest_event','DELETE','1','2025-12-17 13:04:09','root@%','{\"status\": \"OK\", \"created_at\": \"2025-12-10 07:30:05.000000\", \"id_players\": 26, \"occurred_at\": \"2025-12-10 07:30:00.000000\", \"raw_payload\": {\"date\": \"2025-12-10\", \"steps\": 8000}, \"parsed_value\": 8000.000000, \"error_message\": null, \"id_sensor_endpoint\": 1, \"id_sensor_ingest_event\": 1, \"id_players_sensor_endpoint\": 1}',NULL),(18,'sensor_ingest_event','DELETE','2','2025-12-17 13:04:09','root@%','{\"status\": \"OK\", \"created_at\": \"2025-12-10 23:30:05.000000\", \"id_players\": 26, \"occurred_at\": \"2025-12-10 23:30:00.000000\", \"raw_payload\": {\"date\": \"2025-12-10\", \"minutes_asleep\": 420}, \"parsed_value\": 420.000000, \"error_message\": null, \"id_sensor_endpoint\": 2, \"id_sensor_ingest_event\": 2, \"id_players_sensor_endpoint\": 2}',NULL),(19,'lsg_game_session','DELETE','1','2025-12-17 13:04:09','root@%','{\"ended_at\": \"2025-12-10 19:30:00.000000\", \"created_at\": \"2025-12-10 19:30:05.000000\", \"started_at\": \"2025-12-10 18:00:00.000000\", \"session_metrics\": {\"events\": 120, \"redeems\": 1}, \"duration_seconds\": 5400, \"id_lsg_game_session\": 1, \"id_player_videogame\": 1}',NULL),(20,'lsg_game_session','DELETE','2','2025-12-17 13:04:09','root@%','{\"ended_at\": \"2025-12-09 21:15:00.000000\", \"created_at\": \"2025-12-09 21:15:10.000000\", \"started_at\": \"2025-12-09 20:00:00.000000\", \"session_metrics\": {\"events\": 90, \"redeems\": 0}, \"duration_seconds\": 4500, \"id_lsg_game_session\": 2, \"id_player_videogame\": 1}',NULL),(21,'players','DELETE','26','2025-12-17 13:04:09','root@%','{\"age\": 35, \"name\": \"jmacias\", \"email\": \"joaquin.macias@usach.cl\", \"created_at\": \"2025-12-11 20:44:31.000000\", \"id_players\": 26, \"updated_at\": \"2025-12-11 20:44:31.000000\", \"external_id\": null, \"external_type\": null}',NULL),(22,'players','DELETE','25','2025-12-17 13:05:15','root@%','{\"age\": 0, \"name\": \"lmellado\", \"email\": \"luis.mellado.v@usach.cl\", \"created_at\": \"2025-12-11 20:44:02.000000\", \"id_players\": 25, \"updated_at\": \"2025-12-11 20:44:02.000000\", \"external_id\": null, \"external_type\": null}',NULL),(23,'redemption_event','DELETE','2','2025-12-17 13:05:18','root@%','{\"metadata\": {\"note\": \"Primer canje hherrera en UpperWish\"}, \"redeemed_at\": \"2025-12-09 21:01:00.000000\", \"redeemed_points\": 50, \"id_points_ledger\": 6, \"id_redemption_event\": 2, \"id_modifiable_mechanic_videogame\": 1}',NULL),(24,'points_ledger','DELETE','5','2025-12-17 13:05:18','root@%','{\"amount\": 100, \"payload\": {\"steps\": 10000, \"reason\": \"steps_to_points\"}, \"direction\": \"CREDIT\", \"created_at\": \"2025-12-09 18:45:05.000000\", \"id_players\": 24, \"source_ref\": \"d26d5867-d6d7-11f0-bb4d-0242ac120002\", \"occurred_at\": \"2025-12-09 18:45:00.000000\", \"source_type\": \"SENSOR\", \"id_videogame\": 1, \"id_points_ledger\": 5, \"id_point_dimension\": 2, \"id_sensor_ingest_event\": 4}',NULL),(25,'points_ledger','DELETE','6','2025-12-17 13:05:18','root@%','{\"amount\": 50, \"payload\": {\"mechanic\": \"Faster Peasants\"}, \"direction\": \"DEBIT\", \"created_at\": \"2025-12-09 21:00:05.000000\", \"id_players\": 24, \"source_ref\": \"redeem_24_uw_1\", \"occurred_at\": \"2025-12-09 21:00:00.000000\", \"source_type\": \"REDEMPTION\", \"id_videogame\": 1, \"id_points_ledger\": 6, \"id_point_dimension\": 2, \"id_sensor_ingest_event\": null}',NULL),(26,'sensor_ingest_event','DELETE','4','2025-12-17 13:05:18','root@%','{\"status\": \"OK\", \"created_at\": \"2025-12-09 18:30:05.000000\", \"id_players\": 24, \"occurred_at\": \"2025-12-09 18:30:00.000000\", \"raw_payload\": {\"date\": \"2025-12-09\", \"steps\": 10000}, \"parsed_value\": 10000.000000, \"error_message\": null, \"id_sensor_endpoint\": 1, \"id_sensor_ingest_event\": 4, \"id_players_sensor_endpoint\": 5}',NULL),(27,'lsg_game_session','DELETE','4','2025-12-17 13:05:18','root@%','{\"ended_at\": \"2025-12-09 21:45:00.000000\", \"created_at\": \"2025-12-09 21:45:10.000000\", \"started_at\": \"2025-12-09 20:00:00.000000\", \"session_metrics\": {\"events\": 110, \"redeems\": 2}, \"duration_seconds\": 6300, \"id_lsg_game_session\": 4, \"id_player_videogame\": 5}',NULL),(28,'players','DELETE','24','2025-12-17 13:05:18','root@%','{\"age\": 0, \"name\": \"hherrera\", \"email\": \"hernan.herrera@usach.cl\", \"created_at\": \"2025-12-11 20:43:24.000000\", \"id_players\": 24, \"updated_at\": \"2025-12-11 20:43:24.000000\", \"external_id\": null, \"external_type\": null}',NULL),(29,'points_ledger','DELETE','4','2025-12-17 13:05:21','root@%','{\"amount\": 60, \"payload\": {\"steps\": 6000, \"reason\": \"steps_to_points\"}, \"direction\": \"CREDIT\", \"created_at\": \"2025-12-09 08:30:05.000000\", \"id_players\": 22, \"source_ref\": \"d26d4f4c-d6d7-11f0-bb4d-0242ac120002\", \"occurred_at\": \"2025-12-09 08:30:00.000000\", \"source_type\": \"SENSOR\", \"id_videogame\": 14, \"id_points_ledger\": 4, \"id_point_dimension\": 2, \"id_sensor_ingest_event\": 3}',NULL),(30,'sensor_ingest_event','DELETE','3','2025-12-17 13:05:21','root@%','{\"status\": \"OK\", \"created_at\": \"2025-12-09 08:00:05.000000\", \"id_players\": 22, \"occurred_at\": \"2025-12-09 08:00:00.000000\", \"raw_payload\": {\"date\": \"2025-12-09\", \"steps\": 6000}, \"parsed_value\": 6000.000000, \"error_message\": null, \"id_sensor_endpoint\": 1, \"id_sensor_ingest_event\": 3, \"id_players_sensor_endpoint\": 3}',NULL),(31,'lsg_game_session','DELETE','3','2025-12-17 13:05:21','root@%','{\"ended_at\": \"2025-12-09 22:10:00.000000\", \"created_at\": \"2025-12-09 22:10:05.000000\", \"started_at\": \"2025-12-09 21:30:00.000000\", \"session_metrics\": {\"events\": 60, \"redeems\": 1}, \"duration_seconds\": 2400, \"id_lsg_game_session\": 3, \"id_player_videogame\": 3}',NULL),(32,'players','DELETE','22','2025-12-17 13:05:21','root@%','{\"age\": 0, \"name\": \"aaldea\", \"email\": \"alejandro.aldea@usach.cl\", \"created_at\": \"2025-12-11 20:42:33.000000\", \"id_players\": 22, \"updated_at\": \"2025-12-11 20:42:33.000000\", \"external_id\": null, \"external_type\": null}',NULL),(33,'player_roles','UPDATE','21','2026-05-06 20:45:52','root@%','{\"role\": \"player\", \"revoked_at\": null}','{\"role\": \"player\", \"revoked_at\": \"2026-05-06 20:45:52.000000\"}');
/*!40000 ALTER TABLE `audit_log` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `conversion`
--

DROP TABLE IF EXISTS `conversion`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `conversion` (
  `id_conversion` int NOT NULL AUTO_INCREMENT,
  `name` varchar(100) DEFAULT NULL,
  `description` varchar(300) DEFAULT NULL,
  `operations` varchar(200) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id_conversion`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `conversion`
--

LOCK TABLES `conversion` WRITE;
/*!40000 ALTER TABLE `conversion` DISABLE KEYS */;
INSERT INTO `conversion` VALUES (1,'conversion','conversion','placeholder','2022-04-20 03:14:07','2022-04-20 03:14:07');
/*!40000 ALTER TABLE `conversion` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `expended_attribute`
--

DROP TABLE IF EXISTS `expended_attribute`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `expended_attribute` (
  `id_expended_attribute` int NOT NULL AUTO_INCREMENT,
  `id_players` int NOT NULL,
  `id_videogame` int unsigned NOT NULL,
  `id_modifiable_conversion_attribute` int NOT NULL,
  `data` int NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id_expended_attribute`),
  KEY `fk_ea_player` (`id_players`),
  KEY `fk_ea_game` (`id_videogame`),
  KEY `fk_ea_mca` (`id_modifiable_conversion_attribute`),
  CONSTRAINT `fk_ea_game` FOREIGN KEY (`id_videogame`) REFERENCES `videogame` (`id_videogame`),
  CONSTRAINT `fk_ea_mca` FOREIGN KEY (`id_modifiable_conversion_attribute`) REFERENCES `modifiable_conversion_attribute` (`id_modifiable_conversion_attribute`),
  CONSTRAINT `fk_ea_player` FOREIGN KEY (`id_players`) REFERENCES `players` (`id_players`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `expended_attribute`
--

LOCK TABLES `expended_attribute` WRITE;
/*!40000 ALTER TABLE `expended_attribute` DISABLE KEYS */;
/*!40000 ALTER TABLE `expended_attribute` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ic2_goalpost_version`
--

DROP TABLE IF EXISTS `ic2_goalpost_version`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ic2_goalpost_version` (
  `id_version` int NOT NULL AUTO_INCREMENT,
  `version_tag` varchar(32) NOT NULL COMMENT 'ej: v1.0-SCCC2026',
  `published_at` date NOT NULL,
  `description` varchar(300) DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `goalposts` json NOT NULL COMMENT '{Icf:{MVPA:{min:0,max:300,strategy:"F2"}, steps:{min:0,max:12000,strategy:"F2"}}, ...}',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_version`),
  UNIQUE KEY `uq_version_tag` (`version_tag`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ic2_goalpost_version`
--

LOCK TABLES `ic2_goalpost_version` WRITE;
/*!40000 ALTER TABLE `ic2_goalpost_version` DISABLE KEYS */;
INSERT INTO `ic2_goalpost_version` VALUES (1,'v1.0','2026-05-06','Goalposts baseline definidos en IC2_LSG paper SCCC 2026 (Macías-Cáceres et al.)',1,'{\"Icf\": {\"MVPA\": {\"max\": 300, \"min\": 0, \"strategy\": \"F2\", \"direction\": \"+\"}, \"steps\": {\"max\": 12000, \"min\": 0, \"strategy\": \"F2\", \"direction\": \"+\"}}, \"Itd\": {\"reaction_time_ms\": {\"max\": 1000, \"min\": 150, \"strategy\": \"F1\", \"direction\": \"-\"}, \"decision_accuracy\": {\"max\": 100, \"min\": 0, \"strategy\": \"F1\", \"direction\": \"+\"}}, \"Ipma\": {\"memory_accuracy\": {\"max\": 100, \"min\": 0, \"strategy\": \"F1\", \"direction\": \"+\"}, \"recall_speed_ms\": {\"max\": 1800, \"min\": 200, \"strategy\": \"F1\", \"direction\": \"-\"}}, \"Isfg\": {\"resting_hr\": {\"max\": 100, \"min\": 40, \"alpha\": 0.2, \"theta\": 60, \"strategy\": \"F3\", \"direction\": \"-\"}, \"sleep_quality\": {\"max\": 10, \"min\": 0, \"strategy\": \"F4\", \"direction\": \"+\"}}}','2026-05-06 10:01:48');
/*!40000 ALTER TABLE `ic2_goalpost_version` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ic2_result`
--

DROP TABLE IF EXISTS `ic2_result`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ic2_result` (
  `id_ic2_result` bigint NOT NULL AUTO_INCREMENT,
  `id_players` int NOT NULL,
  `id_version` int NOT NULL,
  `window_start` date NOT NULL COMMENT 'inicio de ventana 7 días',
  `window_end` date NOT NULL,
  `Icf` decimal(6,4) DEFAULT NULL,
  `Isfg` decimal(6,4) DEFAULT NULL,
  `Ipma` decimal(6,4) DEFAULT NULL,
  `Itd` decimal(6,4) DEFAULT NULL,
  `IC_fis` decimal(6,4) DEFAULT NULL COMMENT 'sqrt(Icf * Isfg)',
  `IC_ment` decimal(6,4) DEFAULT NULL COMMENT 'sqrt(Ipma * Itd)',
  `IC_LSG` decimal(6,4) DEFAULT NULL COMMENT '(Icf*Isfg*Ipma*Itd)^(1/4)',
  `IAR` decimal(6,4) DEFAULT NULL COMMENT 'Índice de autorregulación (Ec.8 paper)',
  `admissibility` json DEFAULT NULL COMMENT '{Icf: true, Isfg: false (NA), ...}',
  `raw_inputs` json DEFAULT NULL COMMENT 'valores crudos usados en el cálculo',
  `experiment_tag` varchar(128) DEFAULT NULL,
  `computed_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_ic2_result`),
  UNIQUE KEY `uq_ic2_player_window` (`id_players`,`id_version`,`window_start`),
  KEY `ix_ic2_player` (`id_players`),
  KEY `ix_ic2_experiment` (`experiment_tag`),
  KEY `fk_ic2_version` (`id_version`),
  CONSTRAINT `fk_ic2_player` FOREIGN KEY (`id_players`) REFERENCES `players` (`id_players`),
  CONSTRAINT `fk_ic2_version` FOREIGN KEY (`id_version`) REFERENCES `ic2_goalpost_version` (`id_version`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ic2_result`
--

LOCK TABLES `ic2_result` WRITE;
/*!40000 ALTER TABLE `ic2_result` DISABLE KEYS */;
INSERT INTO `ic2_result` VALUES (1,46,1,'2026-05-01','2026-05-07',0.9338,0.9910,0.6375,0.2941,0.9620,0.4330,0.6454,0.7428,'{\"Icf\": true, \"Itd\": true, \"Ipma\": true, \"Isfg\": true}','{\"steps_day\": 9700.0, \"MVPA_min_week\": 160.0, \"resting_hr_bpm\": 80.0, \"recall_speed_ms\": 1200.0, \"reaction_time_ms\": 670.0, \"memory_accuracy_pct\": 90.0, \"sleep_quality_score\": 10.0, \"decision_accuracy_pct\": 20.0}','LSG_C1_T1_CV','2026-05-07 09:53:05');
/*!40000 ALTER TABLE `ic2_result` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ic2_rule`
--

DROP TABLE IF EXISTS `ic2_rule`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ic2_rule` (
  `id_rule` int NOT NULL AUTO_INCREMENT,
  `id_version` int NOT NULL,
  `rule_code` varchar(8) NOT NULL COMMENT 'ej: R1, R2, R6',
  `rule_type` enum('reward','guardrail','synergy') NOT NULL,
  `condition_json` json NOT NULL COMMENT '{IC_fis:{gte:0.60}, days:{gte:7}}',
  `effect_json` json NOT NULL COMMENT '{stamina:0.10, regen_speed:0.05}',
  `duration_hrs` int DEFAULT NULL COMMENT 'NULL = hasta condición',
  `description` varchar(300) DEFAULT NULL,
  PRIMARY KEY (`id_rule`),
  KEY `ix_rule_version` (`id_version`),
  CONSTRAINT `fk_rule_version` FOREIGN KEY (`id_version`) REFERENCES `ic2_goalpost_version` (`id_version`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ic2_rule`
--

LOCK TABLES `ic2_rule` WRITE;
/*!40000 ALTER TABLE `ic2_rule` DISABLE KEYS */;
INSERT INTO `ic2_rule` VALUES (1,1,'R1','reward','{\"IC_fis\": {\"gte\": 0.60}, \"consecutive_days\": 7}','{\"stamina_pct\": 10, \"regen_speed_pct\": 5}',48,'+10% stamina; +5% velocidad de regeneración durante 48 hrs.'),(2,1,'R2','reward','{\"IC_ment\": {\"gte\": 0.55}}','{\"skill_cooldown_pct\": -15}',24,'-15% cooldown de habilidades cognitivas durante 24 hrs.'),(3,1,'R3','reward','{\"IC_LSG\": {\"gte\": 0.60}, \"IC_fis\": {\"gte\": 0.60}, \"IC_ment\": {\"gte\": 0.55}}','{\"drop_rate_pct\": 5, \"special_quest\": true}',72,'+5% drop-rate; acceso a quest especial durante 72 hrs.'),(4,1,'R4','guardrail','{\"IC_fis\": {\"lt\": 0.40}, \"consecutive_days\": 3}','{\"boost_softlimit\": true, \"active_pause_mission\": true, \"boost_resume_threshold\": {\"IC_fis_gte\": 0.45}}',NULL,'Misión de recuperación (pausa activa); softlimit de boosts hasta IC_fis≥0.45.'),(5,1,'R5','guardrail','{\"IC_ment\": {\"lt\": 0.35}}','{\"mission_duration_min\": 5, \"cognitive_mission_suggested\": true}',NULL,'Misión cognitiva breve (test 5 min.) sugerida al inicio de sesión.'),(6,1,'R6','synergy','{\"IC_fis\": {\"gte\": 0.70}, \"IC_ment\": {\"gte\": 0.65}}','{\"region_unlock\": true, \"special_narrative_event\": true}',96,'Sinergia: desbloqueo de región/evento narrativo especial durante 96 hrs.');
/*!40000 ALTER TABLE `ic2_rule` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `interaction_logs`
--

DROP TABLE IF EXISTS `interaction_logs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `interaction_logs` (
  `id_interaction_log` bigint NOT NULL AUTO_INCREMENT,
  `id_players` int NOT NULL,
  `id_videogame` int unsigned NOT NULL,
  `event_type` varchar(64) NOT NULL COMMENT 'ej: redeem, sensor_ingest, session_start, ic2_compute',
  `experiment_tag` varchar(128) DEFAULT NULL COMMENT 'etiqueta para filtrado en análisis FONDECYT (ej: LSG_PILOT_2026)',
  `occurred_at` timestamp NOT NULL,
  `metrics` json DEFAULT NULL COMMENT 'payload de métricas: {IC_fis, IC_ment, IC_LSG, IAR, raw_signals:{...}}',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_interaction_log`),
  KEY `ix_il_player_time` (`id_players`,`occurred_at`),
  KEY `ix_il_experiment` (`experiment_tag`),
  KEY `ix_il_event_type` (`event_type`),
  KEY `fk_il_game` (`id_videogame`),
  CONSTRAINT `fk_il_game` FOREIGN KEY (`id_videogame`) REFERENCES `videogame` (`id_videogame`),
  CONSTRAINT `fk_il_player` FOREIGN KEY (`id_players`) REFERENCES `players` (`id_players`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='Bitácora de interacciones para análisis longitudinal FONDECYT';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `interaction_logs`
--

LOCK TABLES `interaction_logs` WRITE;
/*!40000 ALTER TABLE `interaction_logs` DISABLE KEYS */;
INSERT INTO `interaction_logs` VALUES (2,46,14,'redeem',NULL,'2026-05-07 15:07:21','{\"pl_id\": 84, \"amount\": 10, \"mmv_id\": 5, \"dimension\": 2, \"resulting_balance\": 121}','2026-05-07 15:07:21');
/*!40000 ALTER TABLE `interaction_logs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `lsg_game_session`
--

DROP TABLE IF EXISTS `lsg_game_session`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `lsg_game_session` (
  `id_lsg_game_session` bigint NOT NULL AUTO_INCREMENT,
  `id_player_videogame` int NOT NULL,
  `started_at` timestamp NOT NULL,
  `ended_at` timestamp NULL DEFAULT NULL,
  `session_metrics` json DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `duration_seconds` int GENERATED ALWAYS AS ((case when (`ended_at` is null) then NULL else timestampdiff(SECOND,`started_at`,`ended_at`) end)) STORED,
  PRIMARY KEY (`id_lsg_game_session`),
  KEY `ix_session_pvg_start` (`id_player_videogame`,`started_at`),
  KEY `ix_session_time` (`started_at`),
  KEY `ix_session_pvg_end` (`id_player_videogame`,`ended_at`),
  CONSTRAINT `fk_sess_pvg` FOREIGN KEY (`id_player_videogame`) REFERENCES `player_videogame` (`id_player_videogame`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `lsg_game_session`
--

LOCK TABLES `lsg_game_session` WRITE;
/*!40000 ALTER TABLE `lsg_game_session` DISABLE KEYS */;
INSERT INTO `lsg_game_session` (`id_lsg_game_session`, `id_player_videogame`, `started_at`, `ended_at`, `session_metrics`, `created_at`) VALUES (5,14,'2026-05-05 20:06:26','2026-05-05 20:08:42','{\"additionalProp1\": {}}','2026-05-05 20:06:45'),(6,14,'2026-05-05 20:17:07','2026-05-05 20:17:37','{\"additionalProp1\": {}}','2026-05-05 20:17:14'),(7,16,'2026-05-05 20:52:53','2026-05-05 20:52:59',NULL,'2026-05-05 20:52:52'),(8,16,'2026-05-05 21:19:18','2026-05-05 21:19:24',NULL,'2026-05-05 21:19:17'),(9,16,'2026-05-05 22:37:41','2026-05-05 22:37:47',NULL,'2026-05-05 22:37:40'),(10,7,'2026-05-07 08:41:33','2026-05-07 08:49:31','{\"additionalProp1\": {}}','2026-05-07 08:44:48');
/*!40000 ALTER TABLE `lsg_game_session` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`%`*/ /*!50003 TRIGGER `trg_lsg_game_session_del` AFTER DELETE ON `lsg_game_session` FOR EACH ROW BEGIN
  INSERT INTO audit_log (table_name, op, row_pk, changed_by, old_row)
  VALUES (
    'lsg_game_session',
    'DELETE',
    CAST(OLD.id_lsg_game_session AS CHAR),
    COALESCE(@app_user, CURRENT_USER()),
    JSON_OBJECT(
      'id_lsg_game_session', OLD.id_lsg_game_session,
      'id_player_videogame', OLD.id_player_videogame,
      'started_at',          OLD.started_at,
      'ended_at',            OLD.ended_at,
      'duration_seconds',    OLD.duration_seconds,
      'session_metrics',     OLD.session_metrics,
      'created_at',          OLD.created_at
    )
  );
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `modifiable_conversion_attribute`
--

DROP TABLE IF EXISTS `modifiable_conversion_attribute`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `modifiable_conversion_attribute` (
  `id_modifiable_conversion_attribute` int NOT NULL AUTO_INCREMENT,
  `id_attribute` int NOT NULL,
  `id_conversion` int NOT NULL,
  `id_modifiable_mechanic` int NOT NULL,
  PRIMARY KEY (`id_modifiable_conversion_attribute`),
  KEY `fk_mca_attr` (`id_attribute`),
  KEY `fk_mca_conv` (`id_conversion`),
  KEY `fk_mca_mech` (`id_modifiable_mechanic`),
  CONSTRAINT `fk_mca_attr` FOREIGN KEY (`id_attribute`) REFERENCES `attributes` (`id_attributes`),
  CONSTRAINT `fk_mca_conv` FOREIGN KEY (`id_conversion`) REFERENCES `conversion` (`id_conversion`),
  CONSTRAINT `fk_mca_mech` FOREIGN KEY (`id_modifiable_mechanic`) REFERENCES `modifiable_mechanic` (`id_modifiable_mechanic`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `modifiable_conversion_attribute`
--

LOCK TABLES `modifiable_conversion_attribute` WRITE;
/*!40000 ALTER TABLE `modifiable_conversion_attribute` DISABLE KEYS */;
INSERT INTO `modifiable_conversion_attribute` VALUES (1,2,1,1),(2,3,1,1);
/*!40000 ALTER TABLE `modifiable_conversion_attribute` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `modifiable_mechanic`
--

DROP TABLE IF EXISTS `modifiable_mechanic`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `modifiable_mechanic` (
  `id_modifiable_mechanic` int NOT NULL AUTO_INCREMENT,
  `name` varchar(100) DEFAULT NULL,
  `description` varchar(200) DEFAULT NULL,
  `type` enum('buff','nerf','speed','health','economy','modifier') DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id_modifiable_mechanic`)
) ENGINE=InnoDB AUTO_INCREMENT=31 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `modifiable_mechanic`
--

LOCK TABLES `modifiable_mechanic` WRITE;
/*!40000 ALTER TABLE `modifiable_mechanic` DISABLE KEYS */;
INSERT INTO `modifiable_mechanic` VALUES (1,'Faster Peasants','placeholder','nerf','2022-04-20 03:14:07','2022-04-20 03:14:07'),(2,'Prolonged jump','placeholder','buff','2026-02-02 16:05:07',NULL),(3,'Greater resistance','placeholder','buff',NULL,NULL),(4,'Cash income bonus','placeholder','economy','2026-03-03 23:57:04',NULL),(5,'Enhanced learning','placeholder','buff',NULL,NULL),(6,'Faster Attack Speed','Aumenta la velocidad de ataque del jugador aplicando un multiplicador sobre el cooldown base de las armas','buff',NULL,NULL),(7,'Reduced Enemy HP','Reduce los puntos de vida de todos los enemigos en el mundo activo, facilitando el combate','nerf',NULL,NULL),(8,'Increased Player Max HP','Incrementa el tope de vida máxima del jugador sin requerir el consumo de Corazones de Vida adicionales','buff',NULL,NULL),(9,'Increased Mining Speed','Acelera la velocidad de minería de bloques aplicando un multiplicador sobre el tiempo de golpe de pico','buff',NULL,NULL),(10,'Reduced Crafting Time','Disminuye el tiempo necesario para craftear ítems en estaciones de trabajo (e.g., Work Bench, Furnace)','buff',NULL,NULL),(11,'Increased Mana Capacity','Incrementa la capacidad de maná máxima del jugador sin consumir Estrellas de Maná adicionales','buff',NULL,NULL),(12,'Increased Loot Drop Rate','Aumenta la probabilidad de que los enemigos suelten ítems raros o adicionales al ser derrotados','buff',NULL,NULL),(13,'Player Movement Speed','Modifica la velocidad horizontal de desplazamiento del personaje en superficie y en el aire','buff',NULL,NULL),(14,'Jump Height Multiplier','Amplía la altura máxima de salto del jugador modificando el impulso vertical inicial','buff',NULL,NULL),(15,'Fall Damage Reduction','Reduce el daño recibido al caer desde alturas elevadas, como porcentaje del daño calculado','buff',NULL,NULL),(16,'Inventory Slot Expansion','Agrega casillas adicionales al inventario principal del jugador, aumentando su capacidad de carga','buff',NULL,NULL),(17,'Player Defense Bonus','Añade puntos fijos de defensa al jugador por encima de los provistos por su equipamiento actual','buff',NULL,NULL),(18,'Critical Hit Chance Increase','Incrementa el porcentaje de probabilidad de golpe crítico en ataques cuerpo a cuerpo, distancia y magia','buff',NULL,NULL),(19,'Projectile Speed Multiplier','Aumenta la velocidad de vuelo de proyectiles disparados por el jugador (flechas, balas, hechizos)','buff',NULL,NULL),(20,'Knockback Reduction','Reduce el retroceso (knockback) que recibe el jugador al ser golpeado por enemigos','buff',NULL,NULL),(21,'Life Regeneration Rate','Modifica la tasa de regeneración pasiva de vida del jugador expresada en HP recuperados por segundo','buff',NULL,NULL),(22,'Mana Regeneration Rate','Ajusta la velocidad de recarga de maná del jugador tras usar hechizos o armas mágicas','buff',NULL,NULL),(23,'Respawn Time Reduction','Acorta el tiempo de espera tras la muerte del jugador antes de poder reaparecer en el punto de reaparición','buff',NULL,NULL),(24,'Wing Flight Duration','Extiende el tiempo máximo de vuelo de las alas equipadas por el jugador antes de iniciar la caída','buff',NULL,NULL),(25,'Reduced Gravity','Reduce la gravedad global del mundo, permitiendo saltos más altos y caídas más lentas','modifier',NULL,NULL),(26,'Enemy Spawn Rate Multiplier','Escala la tasa de aparición de enemigos en el mundo, afectando la densidad de encuentros por zona','modifier',NULL,NULL),(27,'Boss HP Multiplier','Modifica los puntos de vida de todos los jefes (bosses) del juego mediante un factor global configurable','modifier',NULL,NULL),(28,'Day Night Cycle Speed','Acelera o desacelera el ciclo día/noche del mundo, afectando la duración de cada fase de tiempo','modifier',NULL,NULL),(29,'NPC Shop Price Modifier','Aplica un factor de descuento o recargo sobre los precios de todos los NPCs mercaderes del mundo','modifier',NULL,NULL),(30,'Enemy Damage Multiplier','Escala el daño base que infligen los enemigos al jugador, útil para ajustar la dificultad global','modifier',NULL,NULL);
/*!40000 ALTER TABLE `modifiable_mechanic` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `modifiable_mechanic_videogames`
--

DROP TABLE IF EXISTS `modifiable_mechanic_videogames`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `modifiable_mechanic_videogames` (
  `id_modifiable_mechanic_videogame` int NOT NULL AUTO_INCREMENT,
  `id_modifiable_mechanic` int NOT NULL,
  `id_videogame` int unsigned DEFAULT NULL,
  `options` json DEFAULT NULL,
  PRIMARY KEY (`id_modifiable_mechanic_videogame`),
  KEY `fk_mmv_game` (`id_videogame`),
  KEY `fk_mmv_mech` (`id_modifiable_mechanic`),
  CONSTRAINT `fk_mmv_game` FOREIGN KEY (`id_videogame`) REFERENCES `videogame` (`id_videogame`),
  CONSTRAINT `fk_mmv_mech` FOREIGN KEY (`id_modifiable_mechanic`) REFERENCES `modifiable_mechanic` (`id_modifiable_mechanic`)
) ENGINE=InnoDB AUTO_INCREMENT=34 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `modifiable_mechanic_videogames`
--

LOCK TABLES `modifiable_mechanic_videogames` WRITE;
/*!40000 ALTER TABLE `modifiable_mechanic_videogames` DISABLE KEYS */;
INSERT INTO `modifiable_mechanic_videogames` VALUES (1,1,1,'null'),(2,1,1,'{\"note\": \"Modificación de prueba\"}'),(3,1,1,'{\"note\": \"Modificación de prueba 2\"}'),(4,3,20,'{\"Greater resistance\": \"Mayor resistencia del personaje\"}'),(5,4,14,'{\"Cash income bonus\": \"Aumento del dinero en el juego\"}'),(6,1,12,'{\"speed\": 1, \"effect\": \"BUFF_SPEED\", \"duration_seconds\": 180}'),(7,2,8,'{\"Prolonged jump\": \"Salto extendido del personaje\"}'),(8,5,23,'{\"Enhanced learning\": \"Aumento en la rapidez de aprendizaje de nuevas habilidades\"}'),(9,6,8,'{\"multiplier\": 1.25}'),(10,7,8,'{\"reduction\": 0.2}'),(11,8,8,'{\"bonus_hp\": 100}'),(12,9,8,'{\"speed_multiplier\": 1.5}'),(13,10,8,'{\"time_reduction_pct\": 0.4}'),(14,11,8,'{\"bonus_mana\": 60}'),(15,12,8,'{\"drop_multiplier\": 1.8}'),(16,13,8,'{\"speed_multiplier\": 1.3}'),(17,14,8,'{\"height_multiplier\": 1.4}'),(18,15,8,'{\"damage_reduction\": 0.5}'),(19,16,8,'{\"extra_slots\": 20}'),(20,17,8,'{\"defense_bonus\": 15}'),(21,18,8,'{\"crit_bonus_pct\": 10}'),(22,19,8,'{\"velocity_multiplier\": 1.35}'),(23,20,8,'{\"kb_reduction\": 0.6}'),(24,21,8,'{\"regen_per_second\": 3}'),(25,22,8,'{\"regen_per_second\": 8}'),(26,23,8,'{\"time_reduction_ms\": 3000}'),(27,24,8,'{\"flight_time_ms\": 2500}'),(28,25,8,NULL),(29,26,8,NULL),(30,27,8,NULL),(31,28,8,NULL),(32,29,8,NULL),(33,30,8,NULL);
/*!40000 ALTER TABLE `modifiable_mechanic_videogames` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `offline_points_queue`
--

DROP TABLE IF EXISTS `offline_points_queue`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `offline_points_queue` (
  `id_offline_queue` bigint NOT NULL AUTO_INCREMENT,
  `id_players` int NOT NULL,
  `id_videogame` int unsigned NOT NULL,
  `id_point_dimension` int NOT NULL,
  `direction` enum('CREDIT','DEBIT') NOT NULL,
  `amount` int NOT NULL,
  `source_type` varchar(32) NOT NULL DEFAULT 'OFFLINE_GAME',
  `client_ref` varchar(128) NOT NULL COMMENT 'UUID generado por el cliente/mod offline',
  `client_generated_at` timestamp NOT NULL COMMENT 'timestamp del evento en el cliente',
  `payload` json DEFAULT NULL,
  `status` enum('PENDING','SYNCED','REJECTED','DUPLICATE') NOT NULL DEFAULT 'PENDING',
  `sync_attempt_at` timestamp NULL DEFAULT NULL,
  `synced_at` timestamp NULL DEFAULT NULL,
  `id_points_ledger` bigint DEFAULT NULL COMMENT 'FK al ledger tras sincronización exitosa',
  `rejection_reason` varchar(300) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_offline_queue`),
  UNIQUE KEY `uq_offline_client_ref` (`client_ref`) COMMENT 'idempotencia de envío',
  KEY `ix_offline_player_status` (`id_players`,`status`),
  KEY `ix_offline_game` (`id_videogame`),
  KEY `fk_oq_dim` (`id_point_dimension`),
  CONSTRAINT `fk_oq_dim` FOREIGN KEY (`id_point_dimension`) REFERENCES `point_dimension` (`id_point_dimension`),
  CONSTRAINT `fk_oq_game` FOREIGN KEY (`id_videogame`) REFERENCES `videogame` (`id_videogame`),
  CONSTRAINT `fk_oq_player` FOREIGN KEY (`id_players`) REFERENCES `players` (`id_players`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='Cola de puntos generados offline (Starbound, BG3). Sincroniza en reconexión.';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `offline_points_queue`
--

LOCK TABLES `offline_points_queue` WRITE;
/*!40000 ALTER TABLE `offline_points_queue` DISABLE KEYS */;
/*!40000 ALTER TABLE `offline_points_queue` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `online_sensor`
--

DROP TABLE IF EXISTS `online_sensor`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `online_sensor` (
  `id_online_sensor` int NOT NULL AUTO_INCREMENT,
  `name` varchar(100) DEFAULT NULL,
  `description` varchar(200) DEFAULT NULL,
  `base_url` varchar(1000) DEFAULT NULL,
  `initiated_date` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id_online_sensor`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `online_sensor`
--

LOCK TABLES `online_sensor` WRITE;
/*!40000 ALTER TABLE `online_sensor` DISABLE KEYS */;
INSERT INTO `online_sensor` VALUES (1,'Fitbit Demo','API ficticia para pasos diarios','https://api.fitbit.local','2025-12-11 21:23:38','2025-12-11 21:23:38'),(2,'SleepTracker Demo','API ficticia para horas de sueño','https://api.sleep.local','2025-12-11 21:23:38','2025-12-11 21:23:38'),(3,'Hygiene and Safety','S/I',NULL,'2026-04-28 12:04:00',NULL),(4,'Chess.com','Repositorio de Chess.com','https://github.com/Stupidoodle/chess-com-api','2026-05-07 00:00:00',NULL);
/*!40000 ALTER TABLE `online_sensor` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `player_online_sensor`
--

DROP TABLE IF EXISTS `player_online_sensor`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `player_online_sensor` (
  `id_players_online_sensor` int NOT NULL AUTO_INCREMENT,
  `id_players` int NOT NULL,
  `id_online_sensor` int NOT NULL,
  `tokens` json DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `rotated_at` timestamp NULL DEFAULT NULL,
  `expires_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id_players_online_sensor`),
  UNIQUE KEY `uq_pos` (`id_players`,`id_online_sensor`),
  KEY `fk_pos_online` (`id_online_sensor`),
  KEY `ix_pos_exp` (`expires_at`),
  CONSTRAINT `fk_pos_online` FOREIGN KEY (`id_online_sensor`) REFERENCES `online_sensor` (`id_online_sensor`),
  CONSTRAINT `fk_pos_player` FOREIGN KEY (`id_players`) REFERENCES `players` (`id_players`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `player_online_sensor`
--

LOCK TABLES `player_online_sensor` WRITE;
/*!40000 ALTER TABLE `player_online_sensor` DISABLE KEYS */;
INSERT INTO `player_online_sensor` VALUES (7,52,3,NULL,'2026-04-28 12:08:00',NULL,NULL,'2031-04-28 12:08:00'),(8,46,1,'{\"additionalProp1\": {}}',NULL,NULL,NULL,'2026-05-07 15:12:54');
/*!40000 ALTER TABLE `player_online_sensor` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `player_roles`
--

DROP TABLE IF EXISTS `player_roles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `player_roles` (
  `id_player_role` int NOT NULL AUTO_INCREMENT,
  `id_players` int NOT NULL,
  `role` varchar(32) NOT NULL,
  `assigned_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `assigned_by` int DEFAULT NULL COMMENT 'id_players del admin que asignó el rol',
  `revoked_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id_player_role`),
  UNIQUE KEY `uq_player_role_active` (`id_players`,`role`,`revoked_at`),
  KEY `ix_pr_player` (`id_players`),
  CONSTRAINT `fk_pr_player` FOREIGN KEY (`id_players`) REFERENCES `players` (`id_players`),
  CONSTRAINT `chk_pr_role` CHECK ((`role` in (_utf8mb4'player',_utf8mb4'researcher',_utf8mb4'admin',_utf8mb4'teacher',_utf8mb4'developer')))
) ENGINE=InnoDB AUTO_INCREMENT=42 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `player_roles`
--

LOCK TABLES `player_roles` WRITE;
/*!40000 ALTER TABLE `player_roles` DISABLE KEYS */;
INSERT INTO `player_roles` VALUES (1,37,'researcher','2025-12-17 01:24:42',NULL,NULL),(2,38,'admin','2025-12-17 12:50:20',NULL,NULL),(3,39,'player','2025-12-17 12:56:54',NULL,NULL),(4,41,'player','2025-12-17 12:58:20',NULL,NULL),(5,42,'player','2025-12-17 12:59:32',NULL,NULL),(6,43,'player','2025-12-17 13:00:38',NULL,NULL),(7,44,'player','2025-12-17 13:01:44',NULL,NULL),(8,45,'teacher','2025-12-17 13:03:01',NULL,NULL),(9,46,'player','2025-12-17 13:04:30',NULL,NULL),(10,47,'player','2025-12-17 13:05:40',NULL,NULL),(11,48,'player','2025-12-17 13:06:24',NULL,NULL),(12,49,'player','2025-12-17 13:07:09',NULL,NULL),(13,50,'player','2026-04-02 13:25:14',NULL,NULL),(14,51,'player','2026-04-02 13:27:41',NULL,NULL),(15,52,'player','2026-04-02 13:28:14',NULL,NULL),(16,53,'player','2026-04-24 20:49:05',NULL,NULL),(17,54,'player','2026-04-28 03:54:52',NULL,NULL),(18,55,'player','2026-05-05 18:27:16',NULL,NULL),(19,46,'admin','2026-05-05 22:41:16',NULL,NULL),(20,56,'player','2026-05-06 20:43:57',46,NULL),(21,45,'player','2026-05-06 20:45:30',46,'2026-05-06 20:45:52'),(22,57,'player','2026-05-07 10:48:52',46,NULL),(23,57,'teacher','2026-05-07 10:52:46',46,NULL),(24,58,'player','2026-05-07 20:23:45',46,NULL),(25,59,'player','2026-05-07 20:24:23',46,NULL),(26,60,'player','2026-05-13 14:01:17',46,NULL),(27,61,'player','2026-05-13 14:01:18',46,NULL),(28,62,'player','2026-05-13 14:01:18',46,NULL),(29,39,'developer','2026-05-13 20:44:10',46,NULL),(30,41,'developer','2026-05-13 20:44:56',46,NULL),(31,42,'developer','2026-05-13 20:45:03',46,NULL),(32,43,'developer','2026-05-13 20:45:11',46,NULL),(33,44,'developer','2026-05-13 20:45:19',46,NULL),(34,46,'developer','2026-05-13 20:45:28',46,NULL),(35,45,'developer','2026-05-13 20:45:33',46,NULL),(36,47,'developer','2026-05-13 20:45:38',46,NULL),(37,50,'developer','2026-05-13 20:45:46',46,NULL),(38,52,'developer','2026-05-13 20:46:00',46,NULL),(39,53,'developer','2026-05-13 20:46:08',46,NULL),(40,55,'developer','2026-05-13 20:46:14',46,NULL),(41,56,'developer','2026-05-13 20:46:19',46,NULL);
/*!40000 ALTER TABLE `player_roles` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`%`*/ /*!50003 TRIGGER `trg_player_roles_upd` AFTER UPDATE ON `player_roles` FOR EACH ROW BEGIN
  INSERT INTO audit_log(table_name, op, row_pk, changed_by, old_row, new_row)
  VALUES (
    'player_roles', 'UPDATE',
    CAST(NEW.id_player_role AS CHAR),
    COALESCE(@app_user, CURRENT_USER()),
    JSON_OBJECT('role', OLD.role, 'revoked_at', OLD.revoked_at),
    JSON_OBJECT('role', NEW.role, 'revoked_at', NEW.revoked_at)
  );
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `player_videogame`
--

DROP TABLE IF EXISTS `player_videogame`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `player_videogame` (
  `id_player_videogame` int NOT NULL AUTO_INCREMENT,
  `id_players` int NOT NULL,
  `id_videogame` int unsigned NOT NULL,
  `lsg_enabled` tinyint(1) NOT NULL DEFAULT '1',
  `first_seen` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `last_seen` timestamp NULL DEFAULT NULL,
  `plugin_version` varchar(32) DEFAULT NULL,
  `settings` json DEFAULT NULL,
  PRIMARY KEY (`id_player_videogame`),
  UNIQUE KEY `uq_player_game` (`id_players`,`id_videogame`),
  KEY `ix_pvg_player_game` (`id_players`,`id_videogame`),
  KEY `fk_pvg_game` (`id_videogame`),
  CONSTRAINT `fk_pvg_game` FOREIGN KEY (`id_videogame`) REFERENCES `videogame` (`id_videogame`),
  CONSTRAINT `fk_pvg_player` FOREIGN KEY (`id_players`) REFERENCES `players` (`id_players`)
) ENGINE=InnoDB AUTO_INCREMENT=20 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `player_videogame`
--

LOCK TABLES `player_videogame` WRITE;
/*!40000 ALTER TABLE `player_videogame` DISABLE KEYS */;
INSERT INTO `player_videogame` VALUES (6,46,12,1,'2026-03-05 16:15:50','2026-03-09 21:44:42','0.1.0','{}'),(7,46,14,1,'2026-03-06 15:49:54','2026-05-07 08:44:48','string','{\"additionalProp1\": {}}'),(8,46,8,1,'2026-03-06 16:05:55','2026-03-06 16:05:55','0.1.0',NULL),(13,50,22,1,'2026-04-02 13:33:52','2026-04-02 13:33:52','string','{\"additionalProp1\": {}}'),(14,53,23,1,'2026-05-05 20:06:45','2026-05-05 20:17:14','string','{\"additionalProp1\": {}}'),(16,53,1,1,'2026-05-05 20:52:52','2026-05-05 22:37:40',NULL,NULL);
/*!40000 ALTER TABLE `player_videogame` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `players`
--

DROP TABLE IF EXISTS `players`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `players` (
  `id_players` int NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL,
  `password_hash` char(95) DEFAULT NULL,
  `email` varchar(128) NOT NULL,
  `age` int DEFAULT NULL,
  `external_type` varchar(16) DEFAULT NULL,
  `external_id` varchar(128) DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `temp_expires_at` timestamp NULL DEFAULT NULL COMMENT 'NULL = cuenta permanente. Fecha = cuenta temporal expira en esa fecha.',
  PRIMARY KEY (`id_players`),
  UNIQUE KEY `uq_playerss_email` (`email`),
  KEY `ix_players_temp_expires` (`temp_expires_at`),
  CONSTRAINT `chk_players_auth` CHECK ((((`password_hash` is not null) and (`external_type` is null) and (`external_id` is null)) or ((`password_hash` is null) and (`external_type` is not null) and (`external_id` is not null)) or ((`password_hash` is null) and (`external_type` is null) and (`external_id` is null))))
) ENGINE=InnoDB AUTO_INCREMENT=63 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `players`
--

LOCK TABLES `players` WRITE;
/*!40000 ALTER TABLE `players` DISABLE KEYS */;
INSERT INTO `players` VALUES (37,'pconcepcion','$2b$12$5g9k8TbQY3mlRaRC8BMRe.gk1qiY29w6HhqKHM9IAvzcq9u0zZDCG','pedro.concepcion@usach.cl',30,NULL,NULL,'2025-12-17 01:24:56','2025-12-17 01:24:42',NULL),(38,'admin','$2b$12$nklvM1YTJvFTU9irupap5.3M47q5xR8GIvgFWWAs9pn9LH0EL7gn6','joaquin.macias.2@usach.cl',30,NULL,NULL,'2026-05-08 09:48:11','2025-12-17 12:50:20',NULL),(39,'ngabrielli','$2b$12$H5JatBUm4zwtiFRlACzJ6eAoIv.cAOLnZZt2FlPA5O5OGcc0zJB4m','nicolas.gabrielli@usach.cl',30,NULL,NULL,'2025-12-17 12:56:54','2025-12-17 12:56:54',NULL),(41,'erodriguez','$2b$12$4KHmJQH0j9ipEbn7bt.pIOFH9DUVTsIJT2BxSxifN6AcLU5MfUDbm','enrique.rodriguez-lapuente@usach.cl',30,NULL,NULL,'2025-12-17 12:58:20','2025-12-17 12:58:20',NULL),(42,'ravaca','$2b$12$tdHG7s8UI.jDaEg.BfDT2OTnS3nFDBvY110BIkmntGEN8A0OYsrYO','ricardo.avaca@usach.cl',30,NULL,NULL,'2025-12-17 12:59:32','2025-12-17 12:59:32',NULL),(43,'acastro','$2b$12$Iy7bu5PQM40BtnhPS4rxE.j3JXGOGITgCYLAlKSyn7AI6INKPRO4.','aracely.castro@usach.cl',30,NULL,NULL,'2025-12-17 13:00:38','2025-12-17 13:00:38',NULL),(44,'wjimenez','$2b$12$dLLTTVHvVZK7/Y/2vp/kFOh6fvG93yhU7AxKyDdnOG6Vv0Cz4PtR.','williams.jimenez@usach.cl',30,NULL,NULL,'2025-12-17 13:01:44','2025-12-17 13:01:44',NULL),(45,'rgonzalez','$2b$12$hlcPEL.StH15YRBCwvMvqO0.pQGo10cOQadtVwJ3pp40LqZkm.SMS','roberto.gonzalez.i@usach.cl',30,NULL,NULL,'2025-12-17 13:03:01','2025-12-17 13:03:01',NULL),(46,'jmacias','$2b$12$ACzvgIVkhBKdcR02jOqSRO6ZfVuDMblGA8gKf8neJ3Sad7co8JlIK','joaquin.macias@usach.cl',30,NULL,NULL,'2025-12-17 13:04:30','2025-12-17 13:04:30',NULL),(47,'lmellado','$2b$12$IJnO6KwLcKsCBt2L.BfYGe/UABn0NY4hShSLVktLfNVycNhepZoLm','luis.mellado.v@usach.cl',30,NULL,NULL,'2025-12-17 13:05:40','2025-12-17 13:05:40',NULL),(48,'hherrera','$2b$12$eXCazb71v5UNGP719Kw9TOsa8eNIWLAN.eD2VUvyZgMNUZRm1B2Y.','hernan.herrera@usach.cl',30,NULL,NULL,'2025-12-17 13:06:24','2025-12-17 13:06:24',NULL),(49,'aaldea','$2b$12$y6fjR7dcrZAvciFwfsMjLOWGaR1wsy3jFQK23vzDYE5Ox5qrNQdDG','alejandro.aldea@usach.cl',30,NULL,NULL,'2025-12-17 13:07:09','2025-12-17 13:07:09',NULL),(50,'irojas','$2b$12$.qaYT6IvNGNQxKsQdBhaxOFDPaO2nBTPsd9919p44RWEuGj2nbCpG','isidora.rojas.a@usach.cl',30,NULL,NULL,'2026-04-02 13:25:14','2026-04-02 13:25:14',NULL),(51,'lllancaleo','$2b$12$wY7tEstNXL.9S1sZ.cLYcuacakynhCJmquv7Io7rGq705uw8WiWTS','linkoyan.llancaleo@usach.cl',30,NULL,NULL,'2026-04-02 13:27:41','2026-04-02 13:27:41',NULL),(52,'bguerrero','$2b$12$4Czoi3Ip0RTLYLUDdIJDt.vQEp7eqjcATE4yQw1.ZbBqIQMZIVQJC','bastian.guerrero.a@usach.cl',30,NULL,NULL,'2026-04-02 13:28:14','2026-04-02 13:28:14',NULL),(53,'mvicencio','$2b$12$cyhJWzSHWU5UtddWo7isWO9KqoKWtGAf8.9w15dzWLWohnCfEXVsy','mauricio.vicencio@usach.cl',30,NULL,NULL,'2026-04-24 20:49:05','2026-04-24 20:49:05',NULL),(54,'TesteoR','$2b$12$Ab2u/vyPXCwNik0Docx2LesYND84YSUoRLpK/bJhWq.o2VcsG/DZ6','test@test.com',24,NULL,NULL,'2026-04-28 03:54:52','2026-04-28 03:54:52',NULL),(55,'nsaavedra','$2b$12$LyWNlBnHOPxXh4M7F0eRfuKQ/R9/zHeGvaNSaYbOmgGRQ/J9pXa3u','nicolas.saavedra.ch@usach.cl',30,NULL,NULL,'2026-05-05 18:27:16','2026-05-05 18:27:16',NULL),(56,'pmancuada','$2b$12$fFlfgTj0h.FEspcb236.ZuFjUBHnYLvR6EXWVQoLAc2VY2gAX7G3y','pablo.macuada@usach.cl',30,NULL,NULL,'2026-05-06 20:43:57','2026-05-06 20:43:57',NULL),(57,'dgacitua','$2b$12$zFUpt.J1u3RGTvgcETkg3eZyab5h/94geBeHqVJwCHZOqtsT0Wje2','daniel.gacitua@usach.cl',30,NULL,NULL,'2026-05-07 10:49:13','2026-05-07 10:48:52',NULL),(58,'chernandez','$2b$12$G6FgtvLbd2yuu1LCjOIJue41ujO.zfmczM3Mgitt9qAYYZVMzijMC','claudio.hernandez.h@usach.cl',30,NULL,NULL,'2026-05-07 20:23:45','2026-05-07 20:23:45',NULL),(59,'amunoz','$2b$12$Wvd3aNpKnyDtYJUyKW0UZOXjkjQJ3zs6JOVMXcSdRKyaHZEoiSBcq','alvaro.munoz.a@usach.cl',30,NULL,NULL,'2026-05-07 20:24:23','2026-05-07 20:24:23',NULL),(60,'test_dcb5nl','$2b$12$mj5M5DL0p6njEn10vmKpher18NjlbOIS14YLBcdkHbDv2kjYWPafK','test_dcb5nl@lsg.temp',NULL,NULL,NULL,'2026-05-13 14:01:17','2026-05-13 14:01:17','2026-05-14 14:01:17'),(61,'test_10pno7','$2b$12$3M9mAJ.iA/qErCOMggjVROGN7B4NZJeHzWueFSGP/mxSfDeWSx3gi','test_10pno7@lsg.temp',NULL,NULL,NULL,'2026-05-13 14:01:17','2026-05-13 14:01:17','2026-05-14 14:01:17'),(62,'test_320hjh','$2b$12$N81WrZWiv0t2BGBbY9p/o.EDOabAHRBvdrysD9HLLxd/FaetN12pW','test_320hjh@lsg.temp',NULL,NULL,NULL,'2026-05-13 14:01:18','2026-05-13 14:01:18','2026-05-14 14:01:17');
/*!40000 ALTER TABLE `players` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`%`*/ /*!50003 TRIGGER `trg_players_bi` BEFORE INSERT ON `players` FOR EACH ROW BEGIN
  IF NOT (
       (NEW.password_hash IS NOT NULL AND NEW.external_type IS NULL AND NEW.external_id IS NULL)
    OR (NEW.password_hash IS NULL     AND NEW.external_type IS NOT NULL AND NEW.external_id IS NOT NULL)
  ) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Regla XOR de autenticación violada (players)';
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`%`*/ /*!50003 TRIGGER `trg_players_bu` BEFORE UPDATE ON `players` FOR EACH ROW BEGIN
  IF NOT (
       (NEW.password_hash IS NOT NULL AND NEW.external_type IS NULL AND NEW.external_id IS NULL)
    OR (NEW.password_hash IS NULL     AND NEW.external_type IS NOT NULL AND NEW.external_id IS NOT NULL)
  ) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Regla XOR de autenticación violada (players)';
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`%`*/ /*!50003 TRIGGER `trg_players_del` AFTER DELETE ON `players` FOR EACH ROW BEGIN
  INSERT INTO audit_log (table_name, op, row_pk, changed_by, old_row)
  VALUES (
    'players',
    'DELETE',
    CAST(OLD.id_players AS CHAR),
    COALESCE(@app_user, CURRENT_USER()),
    JSON_OBJECT(
      'id_players',      OLD.id_players,
      'name',            OLD.name,
      'email',           OLD.email,
      'age',             OLD.age,
      'external_type',   OLD.external_type,
      'external_id',     OLD.external_id,
      'created_at',      OLD.created_at,
      'updated_at',      OLD.updated_at
    )
  );
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `players_attributes`
--

DROP TABLE IF EXISTS `players_attributes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `players_attributes` (
  `id_players_attributes` int NOT NULL AUTO_INCREMENT,
  `id_players` int NOT NULL,
  `id_attributes` int NOT NULL,
  `data` int DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_players_attributes`),
  UNIQUE KEY `uq_pa` (`id_players`,`id_attributes`),
  KEY `ix_pa_player` (`id_players`),
  KEY `ix_pa_attr` (`id_attributes`),
  KEY `ix_pa_attr_player` (`id_attributes`,`id_players`),
  CONSTRAINT `fk_pa_attr` FOREIGN KEY (`id_attributes`) REFERENCES `attributes` (`id_attributes`),
  CONSTRAINT `fk_pa_player` FOREIGN KEY (`id_players`) REFERENCES `players` (`id_players`)
) ENGINE=InnoDB AUTO_INCREMENT=368 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `players_attributes`
--

LOCK TABLES `players_attributes` WRITE;
/*!40000 ALTER TABLE `players_attributes` DISABLE KEYS */;
INSERT INTO `players_attributes` VALUES (152,47,1,100,'2026-02-16 21:23:03'),(156,47,2,35,'2026-02-18 20:36:11'),(157,47,3,100,'2026-04-30 16:16:05'),(158,47,4,110,'2026-02-16 21:23:29'),(188,46,1,168,'2026-05-13 14:24:04'),(189,46,2,121,'2026-05-07 15:07:21'),(190,46,3,88,'2026-03-04 14:59:49'),(191,46,4,87,'2026-03-04 14:59:52'),(201,46,5,0,'2026-03-05 00:18:54'),(202,47,5,0,'2026-03-05 15:49:36'),(225,49,1,0,'2026-04-24 20:41:08'),(226,49,4,0,'2026-04-24 20:41:08'),(227,49,5,0,'2026-04-24 20:41:08'),(228,49,2,0,'2026-04-24 20:41:08'),(229,49,3,0,'2026-04-24 20:41:08'),(230,43,1,0,'2026-04-24 20:41:08'),(231,43,4,0,'2026-04-24 20:41:08'),(232,43,5,0,'2026-04-24 20:41:08'),(233,43,2,0,'2026-04-24 20:41:08'),(234,43,3,0,'2026-04-24 20:41:08'),(235,52,1,0,'2026-04-24 20:41:08'),(236,52,4,0,'2026-04-24 20:41:08'),(237,52,5,0,'2026-04-24 20:41:08'),(238,52,2,0,'2026-04-24 20:41:08'),(239,52,3,0,'2026-04-24 20:41:08'),(240,41,1,0,'2026-04-24 20:41:08'),(241,41,4,0,'2026-04-24 20:41:08'),(242,41,5,0,'2026-04-24 20:41:08'),(243,41,2,0,'2026-04-24 20:41:08'),(244,41,3,0,'2026-04-24 20:41:08'),(245,48,1,0,'2026-04-24 20:41:08'),(246,48,4,0,'2026-04-24 20:41:08'),(247,48,5,0,'2026-04-24 20:41:08'),(248,48,2,0,'2026-04-24 20:41:08'),(249,48,3,0,'2026-04-24 20:41:08'),(250,50,1,0,'2026-04-24 20:41:08'),(251,50,4,0,'2026-04-24 20:41:08'),(252,50,5,0,'2026-04-24 20:41:08'),(253,50,2,0,'2026-04-24 20:41:08'),(254,50,3,0,'2026-04-24 20:41:08'),(255,38,1,0,'2026-04-24 20:41:08'),(256,38,4,0,'2026-04-24 20:41:08'),(257,38,5,0,'2026-04-24 20:41:08'),(258,38,2,0,'2026-04-24 20:41:08'),(259,38,3,0,'2026-04-24 20:41:08'),(260,51,1,0,'2026-04-24 20:41:08'),(261,51,4,0,'2026-04-24 20:41:08'),(262,51,5,0,'2026-04-24 20:41:08'),(263,51,2,0,'2026-04-24 20:41:08'),(264,51,3,0,'2026-04-24 20:41:08'),(265,39,1,0,'2026-04-24 20:41:08'),(266,39,4,0,'2026-04-24 20:41:08'),(267,39,5,0,'2026-04-24 20:41:08'),(268,39,2,0,'2026-04-24 20:41:08'),(269,39,3,0,'2026-04-24 20:41:08'),(270,37,1,0,'2026-04-24 20:41:08'),(271,37,4,0,'2026-04-24 20:41:08'),(272,37,5,0,'2026-04-24 20:41:08'),(273,37,2,0,'2026-04-24 20:41:08'),(274,37,3,0,'2026-04-24 20:41:08'),(275,42,1,0,'2026-04-24 20:41:08'),(276,42,4,0,'2026-04-24 20:41:08'),(277,42,5,0,'2026-04-24 20:41:08'),(278,42,2,0,'2026-04-24 20:41:08'),(279,42,3,0,'2026-04-24 20:41:08'),(280,45,1,0,'2026-04-24 20:41:08'),(281,45,4,0,'2026-04-24 20:41:08'),(282,45,5,0,'2026-04-24 20:41:08'),(283,45,2,0,'2026-04-24 20:41:08'),(284,45,3,0,'2026-04-24 20:41:08'),(285,44,1,0,'2026-04-24 20:41:08'),(286,44,4,0,'2026-04-24 20:41:08'),(287,44,5,0,'2026-04-24 20:41:08'),(288,44,2,0,'2026-04-24 20:41:08'),(289,44,3,0,'2026-04-24 20:41:08'),(353,53,3,0,'2026-05-04 21:00:36'),(354,53,2,120,'2026-05-13 14:24:12'),(355,53,5,0,'2026-05-04 21:00:36'),(356,53,4,0,'2026-05-04 21:00:36'),(357,53,1,10,'2026-05-05 19:23:30');
/*!40000 ALTER TABLE `players_attributes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `players_sensor_endpoint`
--

DROP TABLE IF EXISTS `players_sensor_endpoint`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `players_sensor_endpoint` (
  `id_players_sensor_endpoint` int NOT NULL AUTO_INCREMENT,
  `id_players` int NOT NULL,
  `id_sensor_endpoint` int NOT NULL,
  `specific_parameters` json DEFAULT NULL,
  `activated` tinyint(1) DEFAULT NULL,
  `schedule_time` int DEFAULT NULL,
  PRIMARY KEY (`id_players_sensor_endpoint`),
  KEY `ix_pse_player` (`id_players`),
  KEY `ix_pse_endpoint` (`id_sensor_endpoint`),
  CONSTRAINT `fk_pse_endpoint` FOREIGN KEY (`id_sensor_endpoint`) REFERENCES `sensor_endpoint` (`id_sensor_endpoint`),
  CONSTRAINT `fk_pse_player` FOREIGN KEY (`id_players`) REFERENCES `players` (`id_players`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `players_sensor_endpoint`
--

LOCK TABLES `players_sensor_endpoint` WRITE;
/*!40000 ALTER TABLE `players_sensor_endpoint` DISABLE KEYS */;
INSERT INTO `players_sensor_endpoint` VALUES (7,46,1,NULL,1,0);
/*!40000 ALTER TABLE `players_sensor_endpoint` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `point_dimension`
--

DROP TABLE IF EXISTS `point_dimension`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `point_dimension` (
  `id_point_dimension` int NOT NULL AUTO_INCREMENT,
  `id_attributes` int DEFAULT NULL,
  `id_subattributes` int DEFAULT NULL,
  `code` varchar(64) NOT NULL,
  `name` varchar(128) NOT NULL,
  PRIMARY KEY (`id_point_dimension`),
  UNIQUE KEY `uq_point_dimension_code` (`code`),
  KEY `fk_pd_attr` (`id_attributes`),
  KEY `fk_pd_sub` (`id_subattributes`),
  CONSTRAINT `fk_pd_attr` FOREIGN KEY (`id_attributes`) REFERENCES `attributes` (`id_attributes`),
  CONSTRAINT `fk_pd_sub` FOREIGN KEY (`id_subattributes`) REFERENCES `subattributes` (`id_subattributes`),
  CONSTRAINT `chk_pd_one` CHECK (((`id_attributes` is not null) xor (`id_subattributes` is not null)))
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `point_dimension`
--

LOCK TABLES `point_dimension` WRITE;
/*!40000 ALTER TABLE `point_dimension` DISABLE KEYS */;
INSERT INTO `point_dimension` VALUES (1,1,NULL,'SOCIAL_BASE','Puntos de desarrollo social'),(2,2,NULL,'FISICO_BASE','Puntos de actividad física'),(3,3,NULL,'AFECTIVO_BASE','Puntos de bienestar afectivo'),(4,4,NULL,'MENTAL_BASE','Puntos de desarrollo mental'),(5,NULL,6,'CONDICION_FISICA','Condición física (subatributo)'),(6,NULL,11,'REG_EMOCIONAL','Regulación emocional (subatributo)');
/*!40000 ALTER TABLE `point_dimension` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `points_ledger`
--

DROP TABLE IF EXISTS `points_ledger`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `points_ledger` (
  `id_points_ledger` bigint NOT NULL AUTO_INCREMENT,
  `id_players` int NOT NULL,
  `id_point_dimension` int NOT NULL,
  `id_videogame` int unsigned DEFAULT NULL,
  `direction` enum('CREDIT','DEBIT') NOT NULL,
  `amount` int NOT NULL,
  `source_type` enum('SENSOR','API','MANUAL','IMPORT','ADJUST','REDEMPTION','OFFLINE_GAME') NOT NULL,
  `source_ref` varchar(128) NOT NULL,
  `payload` json DEFAULT NULL,
  `occurred_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `id_sensor_ingest_event` bigint DEFAULT NULL,
  PRIMARY KEY (`id_points_ledger`),
  UNIQUE KEY `uq_points_idem` (`id_players`,`source_type`,`source_ref`),
  KEY `ix_points_player_time` (`id_players`,`occurred_at`),
  KEY `ix_points_dimension` (`id_point_dimension`),
  KEY `fk_pl_sie` (`id_sensor_ingest_event`),
  KEY `ix_pl_game_time` (`id_videogame`,`occurred_at`),
  KEY `ix_pl_game_dir_time` (`id_videogame`,`direction`,`occurred_at`),
  CONSTRAINT `fk_pl_dim` FOREIGN KEY (`id_point_dimension`) REFERENCES `point_dimension` (`id_point_dimension`),
  CONSTRAINT `fk_pl_game` FOREIGN KEY (`id_videogame`) REFERENCES `videogame` (`id_videogame`),
  CONSTRAINT `fk_pl_player` FOREIGN KEY (`id_players`) REFERENCES `players` (`id_players`),
  CONSTRAINT `fk_pl_sie` FOREIGN KEY (`id_sensor_ingest_event`) REFERENCES `sensor_ingest_event` (`id_sensor_ingest_event`),
  CONSTRAINT `points_ledger_chk_1` CHECK ((`amount` > 0))
) ENGINE=InnoDB AUTO_INCREMENT=89 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `points_ledger`
--

LOCK TABLES `points_ledger` WRITE;
/*!40000 ALTER TABLE `points_ledger` DISABLE KEYS */;
INSERT INTO `points_ledger` VALUES (7,47,1,20,'CREDIT',100,'ADJUST','ADJUST-184a7da3-47b4-46ed-8488-01b03a8823e4','{\"reason\": \"testing\"}','2026-01-09 22:02:12','2026-01-09 22:02:12',NULL),(8,47,1,20,'CREDIT',80,'ADJUST','ADJUST-85b8a167-4acf-402c-97e5-b9ad09cced9e','{\"reason\": \"testing\"}','2026-01-09 22:05:09','2026-01-09 22:05:09',NULL),(10,47,1,20,'DEBIT',50,'REDEMPTION','REDEMPTION-e625cd7e-af31-4a80-a38d-771e3a5f5097','{\"additionalProp1\": {}}','2026-01-19 18:17:20','2026-01-19 18:17:20',NULL),(11,47,2,20,'CREDIT',50,'ADJUST','ADJUST-d352b685-99f9-4b4d-9d04-82387fb22407','{\"reason\": \"pruebas\"}','2026-01-20 14:20:11','2026-01-20 14:20:11',NULL),(12,47,3,20,'CREDIT',80,'ADJUST','ADJUST-086e8881-3993-4fa1-9a04-8259927c534a','{\"reason\": \"pruebas\"}','2026-01-20 14:20:48','2026-01-20 14:20:48',NULL),(13,47,4,20,'CREDIT',100,'ADJUST','ADJUST-941a4162-8ff1-4871-b858-4f9b5058c35e','{\"reason\": \"pruebas\"}','2026-01-20 14:21:02','2026-01-20 14:21:02',NULL),(14,47,4,20,'CREDIT',120,'ADJUST','ADJUST-12c39b64-a05f-4639-a966-95df039f6caa','{\"reason\": \"pruebas\"}','2026-01-20 14:21:09','2026-01-20 14:21:09',NULL),(15,47,5,20,'CREDIT',140,'ADJUST','ADJUST-7cb14c1a-05e7-4d15-9f39-3b8546ef6bb6','{\"reason\": \"pruebas\"}','2026-01-20 14:21:45','2026-01-20 14:21:45',NULL),(24,47,4,20,'DEBIT',20,'REDEMPTION','REDEMPTION-4e93f3cb-957c-47c8-bf6e-dbacb116707f','{\"additionalProp1\": {}}','2026-02-02 20:09:12','2026-02-02 20:09:12',NULL),(25,47,4,20,'DEBIT',10,'REDEMPTION','REDEMPTION-f0d3e5b0-14a8-4adc-a941-3d9bf21c0624','{\"additionalProp1\": {}}','2026-02-16 19:27:05','2026-02-16 19:27:05',NULL),(26,47,1,20,'DEBIT',10,'REDEMPTION','REDEMPTION-1140880f-659a-4e38-a060-13df306b4544',NULL,'2026-02-16 19:50:06','2026-02-16 19:50:06',NULL),(27,47,2,20,'DEBIT',10,'REDEMPTION','REDEMPTION-0db4bc66-16f5-41c8-9374-9276134c0522',NULL,'2026-02-16 19:50:07','2026-02-16 19:50:07',NULL),(28,47,3,20,'DEBIT',10,'REDEMPTION','REDEMPTION-3c5fa9c5-25f4-4e31-b686-1785a1876bd8',NULL,'2026-02-16 19:50:08','2026-02-16 19:50:08',NULL),(29,47,4,20,'DEBIT',10,'REDEMPTION','REDEMPTION-6f61d56f-9ed7-4e97-a528-4b7257619063',NULL,'2026-02-16 19:50:10','2026-02-16 19:50:10',NULL),(30,47,5,20,'DEBIT',10,'REDEMPTION','REDEMPTION-ace967c0-0411-408e-b0d3-2bed41e5bd9c',NULL,'2026-02-16 19:50:10','2026-02-16 19:50:10',NULL),(31,47,1,20,'DEBIT',10,'REDEMPTION','REDEMPTION-e4ecc6fa-0009-40a0-90a8-b9964196e961',NULL,'2026-02-16 19:51:09','2026-02-16 19:51:09',NULL),(32,47,2,20,'DEBIT',10,'REDEMPTION','REDEMPTION-6873a386-b578-42af-a940-d1264338b7fe',NULL,'2026-02-16 19:51:13','2026-02-16 19:51:13',NULL),(33,47,3,20,'DEBIT',10,'REDEMPTION','REDEMPTION-2411e5f9-84a5-4ec5-ae10-3c381379315d',NULL,'2026-02-16 19:51:16','2026-02-16 19:51:16',NULL),(34,47,4,20,'DEBIT',10,'REDEMPTION','REDEMPTION-3249d049-4b33-4c8f-8f7d-ce5d835b4c75',NULL,'2026-02-16 19:51:19','2026-02-16 19:51:19',NULL),(35,47,5,20,'DEBIT',10,'REDEMPTION','REDEMPTION-fe1c6512-def4-45ea-8e81-982d190442c6',NULL,'2026-02-16 19:51:19','2026-02-16 19:51:19',NULL),(36,47,1,20,'DEBIT',10,'REDEMPTION','REDEMPTION-5297af50-a3cf-4819-a6d3-65313b561563',NULL,'2026-02-16 21:23:03','2026-02-16 21:23:03',NULL),(37,47,2,20,'DEBIT',10,'REDEMPTION','REDEMPTION-e2404391-a87e-4d03-9a1a-de6d2f21c6de',NULL,'2026-02-16 21:23:28','2026-02-16 21:23:28',NULL),(38,47,3,20,'DEBIT',10,'REDEMPTION','REDEMPTION-0dafe698-a408-43a3-8123-f0cf6f8dd294',NULL,'2026-02-16 21:23:28','2026-02-16 21:23:28',NULL),(39,47,4,20,'DEBIT',60,'REDEMPTION','REDEMPTION-7402a994-ccf0-42eb-b9e7-d70ab428e41c',NULL,'2026-02-16 21:23:29','2026-02-16 21:23:29',NULL),(40,47,5,20,'DEBIT',10,'REDEMPTION','REDEMPTION-e586758e-49a9-4939-a0bc-93af2c8cafa6',NULL,'2026-02-16 21:23:30','2026-02-16 21:23:30',NULL),(41,47,5,20,'DEBIT',90,'REDEMPTION','REDEMPTION-576b5b7b-f1ea-4cf5-b0ab-2cecf39db2fc','{\"additionalProp1\": {}}','2026-02-18 20:35:38','2026-02-18 20:35:38',NULL),(42,47,5,20,'DEBIT',5,'REDEMPTION','REDEMPTION-8ebdd5c2-2df6-4553-a638-5f62d8339546','{\"additionalProp1\": {}}','2026-02-18 20:36:11','2026-02-18 20:36:11',NULL),(44,46,1,14,'CREDIT',100,'ADJUST','ADJUST-44786b78-8620-48b7-923a-e884fd1cd6d5','{\"reason\": \"string\"}','2026-03-04 14:16:20','2026-03-04 14:16:20',NULL),(45,46,2,14,'CREDIT',100,'ADJUST','ADJUST-25ae78e6-9932-41ee-9b90-a1110bdd040e','{\"reason\": \"string\"}','2026-03-04 14:21:51','2026-03-04 14:21:51',NULL),(46,46,3,14,'CREDIT',100,'ADJUST','ADJUST-d707763d-b4f0-4420-bfad-327604485c90','{\"reason\": \"string\"}','2026-03-04 14:21:57','2026-03-04 14:21:57',NULL),(47,46,4,14,'CREDIT',100,'ADJUST','ADJUST-43198e6e-d240-477b-8dec-3538828999e5','{\"reason\": \"string\"}','2026-03-04 14:22:03','2026-03-04 14:22:03',NULL),(48,46,1,14,'DEBIT',49,'REDEMPTION','REDEMPTION-f54574ba-3579-4b2c-9d12-5fce5588ea77','{\"additionalProp1\": {}}','2026-03-04 14:29:04','2026-03-04 14:29:04',NULL),(49,46,1,14,'DEBIT',10,'REDEMPTION','REDEMPTION-9777e6ee-eefd-4342-be9c-ce6d288ec607',NULL,'2026-03-04 14:59:28','2026-03-04 14:59:28',NULL),(50,46,2,14,'DEBIT',11,'REDEMPTION','REDEMPTION-e3b79056-7a73-458b-97ac-8da4632cd9dc',NULL,'2026-03-04 14:59:43','2026-03-04 14:59:43',NULL),(51,46,3,14,'DEBIT',11,'REDEMPTION','REDEMPTION-e6e070c8-616b-4e16-9793-ff49926e773b',NULL,'2026-03-04 14:59:46','2026-03-04 14:59:46',NULL),(52,46,3,14,'DEBIT',1,'REDEMPTION','REDEMPTION-1fc74ca7-fe79-4e72-ae98-3704faf05f9b',NULL,'2026-03-04 14:59:49','2026-03-04 14:59:49',NULL),(53,46,4,14,'DEBIT',13,'REDEMPTION','REDEMPTION-8e429032-45be-42c8-a410-bee064591acd',NULL,'2026-03-04 14:59:52','2026-03-04 14:59:52',NULL),(54,46,1,14,'DEBIT',10,'REDEMPTION','REDEMPTION-09e57d6e-3f7e-4032-b9df-de85bb64c479',NULL,'2026-03-04 18:15:30','2026-03-04 18:15:30',NULL),(55,46,1,14,'DEBIT',11,'REDEMPTION','REDEMPTION-b49f4dfb-2f0a-49ce-babd-25c0df26be3f',NULL,'2026-03-04 18:47:59','2026-03-04 18:47:59',NULL),(56,46,1,14,'DEBIT',2,'REDEMPTION','REDEMPTION-4a10322a-e4c5-4b9d-ba06-bf3cf12bafe6',NULL,'2026-03-04 21:06:12','2026-03-04 21:06:12',NULL),(57,46,2,12,'CREDIT',50,'ADJUST','ADJUST-SDV-bfd9a4f7-18ae-11f1-84b7-0242ac160003','{\"reason\": \"testing_stardew\"}','2026-03-05 16:17:04','2026-03-05 16:17:04',NULL),(58,46,2,12,'DEBIT',8,'REDEMPTION','REDEMPTION-4ef7444d-ab56-41a4-8edc-9d71e77c3756',NULL,'2026-03-05 16:30:58','2026-03-05 16:30:58',NULL),(79,47,3,20,'CREDIT',50,'ADJUST','ADJUST-5ef22048-2e93-4c41-a4ba-cfcda5615dd7','{\"reason\": \"spotify-sensor\"}','2026-04-30 16:16:05','2026-04-30 16:16:05',NULL),(81,53,1,23,'CREDIT',10,'ADJUST','ADJUST-37a1ff24-08f5-4826-9c8f-2abcdf5cbaba','{\"reason\": \"string\"}','2026-05-05 19:23:30','2026-05-05 19:23:30',NULL),(84,46,2,14,'DEBIT',10,'REDEMPTION','REDEMPTION-590b8fc4-3806-4248-a945-1f70fa4e2668','{\"metadata\": {\"additionalProp1\": {}}, \"modifiable_mechanic_videogame_id\": 5}','2026-05-07 15:07:21','2026-05-07 15:07:21',NULL),(85,46,1,14,'CREDIT',200,'ADJUST','ADJUST-test-tofr-player46-game14',NULL,'2026-05-07 08:41:00','2026-05-13 14:23:59',NULL),(86,46,1,14,'DEBIT',50,'REDEMPTION','REDEMPTION-test-tofr-player46-game14',NULL,'2026-05-07 08:56:33','2026-05-13 14:24:04',NULL),(87,53,2,23,'CREDIT',150,'ADJUST','ADJUST-test-tofr-player53-game23',NULL,'2026-05-05 20:06:00','2026-05-13 14:24:08',NULL),(88,53,2,23,'DEBIT',30,'REDEMPTION','REDEMPTION-test-tofr-player53-game23',NULL,'2026-05-05 20:51:26','2026-05-13 14:24:12',NULL);
/*!40000 ALTER TABLE `points_ledger` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`%`*/ /*!50003 TRIGGER `trg_points_ledger_before_ai` BEFORE INSERT ON `points_ledger` FOR EACH ROW BEGIN
  IF NEW.source_ref IS NULL AND NEW.source_type IN ('SENSOR','API','IMPORT','ADJUST') THEN
    SET NEW.source_ref = UUID();
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`%`*/ /*!50003 TRIGGER `trg_points_ledger_snapshot_ai` AFTER INSERT ON `points_ledger` FOR EACH ROW BEGIN
  DECLARE v_attr INT;

  /* Determinar el atributo asociado a la dimensión de puntos */
  SELECT COALESCE(pd.id_attributes,
                  (SELECT attributes_id_attributes 
                     FROM subattributes 
                    WHERE id_subattributes = pd.id_subattributes))
    INTO v_attr
  FROM point_dimension pd
  WHERE pd.id_point_dimension = NEW.id_point_dimension;

  IF v_attr IS NOT NULL THEN
    INSERT INTO players_attributes (id_players, id_attributes, data, updated_at)
    VALUES (
      NEW.id_players,
      v_attr,
      CASE 
        WHEN NEW.direction = 'CREDIT' THEN NEW.amount
        ELSE -NEW.amount
      END,
      NOW()
    )
    ON DUPLICATE KEY UPDATE
      data       = data + (CASE 
                              WHEN NEW.direction = 'CREDIT' THEN NEW.amount
                              ELSE -NEW.amount
                            END),
      updated_at = NOW();
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`%`*/ /*!50003 TRIGGER `trg_points_ledger_del` AFTER DELETE ON `points_ledger` FOR EACH ROW BEGIN
  INSERT INTO audit_log (table_name, op, row_pk, changed_by, old_row)
  VALUES (
    'points_ledger',
    'DELETE',
    CAST(OLD.id_points_ledger AS CHAR),
    COALESCE(@app_user, CURRENT_USER()),
    JSON_OBJECT(
      'id_points_ledger', OLD.id_points_ledger,
      'id_players',       OLD.id_players,
      'id_point_dimension', OLD.id_point_dimension,
      'id_videogame',     OLD.id_videogame,
      'direction',        OLD.direction,
      'amount',           OLD.amount,
      'source_type',      OLD.source_type,
      'source_ref',       OLD.source_ref,
      'payload',          OLD.payload,
      'occurred_at',      OLD.occurred_at,
      'created_at',       OLD.created_at,
      'id_sensor_ingest_event', OLD.id_sensor_ingest_event
    )
  );
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `redemption_event`
--

DROP TABLE IF EXISTS `redemption_event`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `redemption_event` (
  `id_redemption_event` bigint NOT NULL AUTO_INCREMENT,
  `id_points_ledger` bigint NOT NULL,
  `id_modifiable_mechanic_videogame` int NOT NULL,
  `redeemed_points` int NOT NULL,
  `redeemed_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `metadata` json DEFAULT NULL,
  PRIMARY KEY (`id_redemption_event`),
  UNIQUE KEY `uq_re_ledger` (`id_points_ledger`),
  KEY `ix_redeem_time` (`redeemed_at`),
  KEY `fk_re_mmv` (`id_modifiable_mechanic_videogame`),
  CONSTRAINT `fk_re_ledger` FOREIGN KEY (`id_points_ledger`) REFERENCES `points_ledger` (`id_points_ledger`),
  CONSTRAINT `fk_re_mmv` FOREIGN KEY (`id_modifiable_mechanic_videogame`) REFERENCES `modifiable_mechanic_videogames` (`id_modifiable_mechanic_videogame`)
) ENGINE=InnoDB AUTO_INCREMENT=65 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `redemption_event`
--

LOCK TABLES `redemption_event` WRITE;
/*!40000 ALTER TABLE `redemption_event` DISABLE KEYS */;
INSERT INTO `redemption_event` VALUES (4,10,1,50,'2026-01-19 18:17:20',NULL),(13,24,4,20,'2026-02-02 20:09:12',NULL),(14,25,4,10,'2026-02-16 19:27:06',NULL),(15,26,4,10,'2026-02-16 19:50:06',NULL),(16,27,4,10,'2026-02-16 19:50:07',NULL),(17,28,4,10,'2026-02-16 19:50:08',NULL),(18,29,4,10,'2026-02-16 19:50:10',NULL),(19,30,4,10,'2026-02-16 19:50:10',NULL),(20,31,4,10,'2026-02-16 19:51:09',NULL),(21,32,4,10,'2026-02-16 19:51:14',NULL),(22,33,4,10,'2026-02-16 19:51:16',NULL),(23,34,4,10,'2026-02-16 19:51:19',NULL),(24,35,4,10,'2026-02-16 19:51:19',NULL),(25,36,4,10,'2026-02-16 21:23:03',NULL),(26,37,4,10,'2026-02-16 21:23:28',NULL),(27,38,4,10,'2026-02-16 21:23:28',NULL),(28,39,4,60,'2026-02-16 21:23:29',NULL),(29,40,4,10,'2026-02-16 21:23:30',NULL),(30,41,4,90,'2026-02-18 20:35:38',NULL),(31,42,4,5,'2026-02-18 20:36:11',NULL),(32,48,5,49,'2026-03-04 14:29:04',NULL),(33,49,5,10,'2026-03-04 14:59:28',NULL),(34,50,5,11,'2026-03-04 14:59:43',NULL),(35,51,5,11,'2026-03-04 14:59:46',NULL),(36,52,5,1,'2026-03-04 14:59:49',NULL),(37,53,5,13,'2026-03-04 14:59:52',NULL),(38,54,5,10,'2026-03-04 18:15:30',NULL),(39,55,5,11,'2026-03-04 18:47:59',NULL),(40,56,5,2,'2026-03-04 21:06:12',NULL),(41,58,6,8,'2026-03-05 16:30:58',NULL),(64,84,5,10,'2026-05-07 15:07:21',NULL);
/*!40000 ALTER TABLE `redemption_event` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`%`*/ /*!50003 TRIGGER `trg_redemption_event_del` AFTER DELETE ON `redemption_event` FOR EACH ROW BEGIN
  INSERT INTO audit_log (table_name, op, row_pk, changed_by, old_row)
  VALUES (
    'redemption_event',
    'DELETE',
    CAST(OLD.id_redemption_event AS CHAR),
    COALESCE(@app_user, CURRENT_USER()),
    JSON_OBJECT(
      'id_redemption_event',          OLD.id_redemption_event,
      'id_points_ledger',            OLD.id_points_ledger,
      'id_modifiable_mechanic_videogame', OLD.id_modifiable_mechanic_videogame,
      'redeemed_points',             OLD.redeemed_points,
      'redeemed_at',                 OLD.redeemed_at,
      'metadata',                    OLD.metadata
    )
  );
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `research_pseudonym`
--

DROP TABLE IF EXISTS `research_pseudonym`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `research_pseudonym` (
  `id_players` int NOT NULL,
  `pseudo_code` varchar(16) NOT NULL COMMENT 'Código LSG-PXXX asignado para exportaciones FONDECYT',
  `assigned_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_players`),
  UNIQUE KEY `uq_pseudo_code` (`pseudo_code`),
  CONSTRAINT `fk_rp_player` FOREIGN KEY (`id_players`) REFERENCES `players` (`id_players`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='Mapeo estable jugador → LSG-PXXX para seudonimización FONDECYT.';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `research_pseudonym`
--

LOCK TABLES `research_pseudonym` WRITE;
/*!40000 ALTER TABLE `research_pseudonym` DISABLE KEYS */;
INSERT INTO `research_pseudonym` VALUES (37,'LSG-P001','2026-05-07 14:54:11'),(38,'LSG-P002','2026-05-07 14:54:11'),(39,'LSG-P003','2026-05-07 14:54:11'),(41,'LSG-P004','2026-05-07 14:54:11'),(42,'LSG-P005','2026-05-07 14:54:11'),(43,'LSG-P006','2026-05-07 14:54:11'),(44,'LSG-P007','2026-05-07 14:54:11'),(45,'LSG-P008','2026-05-07 14:54:11'),(46,'LSG-P009','2026-05-07 14:54:11'),(47,'LSG-P010','2026-05-07 14:54:11'),(48,'LSG-P011','2026-05-07 14:54:11'),(49,'LSG-P012','2026-05-07 14:54:11'),(50,'LSG-P013','2026-05-07 14:54:11'),(51,'LSG-P014','2026-05-07 14:54:11'),(52,'LSG-P015','2026-05-07 14:54:11'),(53,'LSG-P016','2026-05-07 14:54:11'),(54,'LSG-P017','2026-05-07 14:54:11'),(55,'LSG-P018','2026-05-07 14:54:11'),(56,'LSG-P019','2026-05-07 14:54:11'),(57,'LSG-P020','2026-05-07 14:54:11');
/*!40000 ALTER TABLE `research_pseudonym` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sensor_endpoint`
--

DROP TABLE IF EXISTS `sensor_endpoint`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sensor_endpoint` (
  `id_sensor_endpoint` int NOT NULL AUTO_INCREMENT,
  `sensor_endpoint_id_online_sensor` int NOT NULL,
  `name` varchar(100) DEFAULT NULL,
  `description` varchar(1000) DEFAULT NULL,
  `url_endpoint` varchar(1000) DEFAULT NULL,
  `token_parameters` json DEFAULT NULL,
  `specific_parameters` json DEFAULT NULL,
  `watch_parameters` json DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id_sensor_endpoint`),
  KEY `fk_se_online` (`sensor_endpoint_id_online_sensor`),
  CONSTRAINT `fk_se_online` FOREIGN KEY (`sensor_endpoint_id_online_sensor`) REFERENCES `online_sensor` (`id_online_sensor`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sensor_endpoint`
--

LOCK TABLES `sensor_endpoint` WRITE;
/*!40000 ALTER TABLE `sensor_endpoint` DISABLE KEYS */;
INSERT INTO `sensor_endpoint` VALUES (1,1,'Daily Steps','Pasos diarios desde Fitbit Demo','/v1/steps','{\"grant_type\": \"bearer\"}','{\"granularity\": \"day\"}','{\"field\": \"steps\"}','2025-12-11 21:23:46','2025-12-11 21:23:46'),(2,2,'Nightly Sleep','Horas de sueño desde SleepTracker Demo','/v1/sleep','{\"grant_type\": \"bearer\"}','{\"granularity\": \"night\"}','{\"field\": \"minutes_asleep\"}','2025-12-11 21:23:46','2025-12-11 21:23:46'),(3,3,'Hygiene and Safety','Sensor para la higiense y seguridad en dispositivos móviles','/v1/sleep','{\"grant_type\": \"bearer\"}','{\"granularity\": \"week\"}','{\"field\": \"days\"}','2026-04-28 12:05:00',NULL),(4,4,'Chess games won','Partidas ganadas de ajedres','/v1/matchs','{\"grant_type\": \"bearer\"}','{\"granularity\": \"day\"}','{\"field\": \"numbers\"}',NULL,NULL);
/*!40000 ALTER TABLE `sensor_endpoint` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sensor_ingest_event`
--

DROP TABLE IF EXISTS `sensor_ingest_event`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sensor_ingest_event` (
  `id_sensor_ingest_event` bigint NOT NULL AUTO_INCREMENT,
  `id_players` int NOT NULL,
  `id_players_sensor_endpoint` int DEFAULT NULL,
  `id_sensor_endpoint` int DEFAULT NULL,
  `raw_payload` json NOT NULL,
  `parsed_value` decimal(18,6) DEFAULT NULL,
  `status` enum('OK','ERROR','IGNORED') NOT NULL DEFAULT 'OK',
  `error_message` varchar(512) DEFAULT NULL,
  `occurred_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_sensor_ingest_event`),
  KEY `ix_sie_time` (`occurred_at`),
  KEY `ix_sie_player_time` (`id_players`,`occurred_at`),
  KEY `fk_sie_pse` (`id_players_sensor_endpoint`),
  KEY `fk_sie_se` (`id_sensor_endpoint`),
  CONSTRAINT `fk_sie_player` FOREIGN KEY (`id_players`) REFERENCES `players` (`id_players`),
  CONSTRAINT `fk_sie_pse` FOREIGN KEY (`id_players_sensor_endpoint`) REFERENCES `players_sensor_endpoint` (`id_players_sensor_endpoint`),
  CONSTRAINT `fk_sie_se` FOREIGN KEY (`id_sensor_endpoint`) REFERENCES `sensor_endpoint` (`id_sensor_endpoint`)
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sensor_ingest_event`
--

LOCK TABLES `sensor_ingest_event` WRITE;
/*!40000 ALTER TABLE `sensor_ingest_event` DISABLE KEYS */;
INSERT INTO `sensor_ingest_event` VALUES (11,46,7,1,'{\"date\": \"2026-05-07\", \"steps\": 8500}',8500.000000,'OK',NULL,'2026-05-07 15:36:36','2026-05-07 15:45:40');
/*!40000 ALTER TABLE `sensor_ingest_event` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`%`*/ /*!50003 TRIGGER `trg_sensor_ingest_event_del` AFTER DELETE ON `sensor_ingest_event` FOR EACH ROW BEGIN
  INSERT INTO audit_log (table_name, op, row_pk, changed_by, old_row)
  VALUES (
    'sensor_ingest_event',
    'DELETE',
    CAST(OLD.id_sensor_ingest_event AS CHAR),
    COALESCE(@app_user, CURRENT_USER()),
    JSON_OBJECT(
      'id_sensor_ingest_event',    OLD.id_sensor_ingest_event,
      'id_players',                OLD.id_players,
      'id_players_sensor_endpoint',OLD.id_players_sensor_endpoint,
      'id_sensor_endpoint',        OLD.id_sensor_endpoint,
      'raw_payload',               OLD.raw_payload,
      'parsed_value',              OLD.parsed_value,
      'status',                    OLD.status,
      'error_message',             OLD.error_message,
      'occurred_at',               OLD.occurred_at,
      'created_at',                OLD.created_at
    )
  );
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `subattributes`
--

DROP TABLE IF EXISTS `subattributes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `subattributes` (
  `id_subattributes` int NOT NULL AUTO_INCREMENT,
  `name` varchar(45) DEFAULT NULL,
  `description` varchar(300) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `attributes_id_attributes` int NOT NULL,
  PRIMARY KEY (`id_subattributes`),
  UNIQUE KEY `uq_sub_name_per_attr` (`attributes_id_attributes`,`name`),
  KEY `ix_subattr_attr` (`attributes_id_attributes`),
  CONSTRAINT `fk_subattr_attr` FOREIGN KEY (`attributes_id_attributes`) REFERENCES `attributes` (`id_attributes`)
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `subattributes`
--

LOCK TABLES `subattributes` WRITE;
/*!40000 ALTER TABLE `subattributes` DISABLE KEYS */;
INSERT INTO `subattributes` VALUES (1,'Habilidades de comunicación interpersonal','placeholder','2025-09-26 03:14:07','2025-09-26 03:14:07',1),(2,'Red de apoyo social','placeholder','2025-09-26 03:14:07','2025-09-26 03:14:07',1),(3,'Resolución de conflictos','placeholder','2025-09-26 03:14:07','2025-09-26 03:14:07',1),(4,'Participación comunitaria','placeholder','2025-09-26 03:14:07','2025-09-26 03:14:07',1),(5,'Empatía y habilidades emocionales','placeholder','2025-09-26 03:14:07','2025-09-26 03:14:07',1),(6,'Condición física','placeholder','2025-09-26 03:14:07','2025-09-26 03:14:07',2),(7,'Desarrollo motor grueso y fino','placeholder','2025-09-26 03:14:07','2025-09-26 03:14:07',2),(8,'Coordinación viso-motora','placeholder','2025-09-26 03:14:07','2025-09-26 03:14:07',2),(9,'Nutrición y metabolismo','placeholder','2025-09-26 03:14:07','2025-09-26 03:14:07',2),(10,'Salud física general','placeholder','2025-09-26 03:14:07','2025-09-26 03:14:07',2),(11,'Regulación emocional','placeholder','2025-09-26 03:14:07','2025-09-26 03:14:07',3),(12,'Reconocimiento de emociones propias y ajenas','placeholder','2025-09-26 03:14:07','2025-09-26 03:14:07',3),(13,'Manejo de estrés','placeholder','2025-09-26 03:14:07','2025-09-26 03:14:07',3),(14,'Relación afectiva con otros','placeholder','2025-09-26 03:14:07','2025-09-26 03:14:07',3),(15,'Expresión emocional','placeholder','2025-09-26 03:14:07','2025-09-26 03:14:07',3),(16,'Procesos de memoria y aprendizaje','placeholder','2025-09-26 03:14:07','2025-09-26 03:14:07',4),(17,'Razonamiento lógico y analítico','placeholder','2025-09-26 03:14:07','2025-09-26 03:14:07',4),(18,'Toma de decisiones','placeholder','2025-09-26 03:14:07','2025-09-26 03:14:07',4),(19,'Pensamiento creativo','placeholder','2025-09-26 03:14:07','2025-09-26 03:14:07',4),(20,'Resolución de problemas','placeholder','2025-09-26 03:14:07','2025-09-26 03:14:07',4);
/*!40000 ALTER TABLE `subattributes` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`%`*/ /*!50003 TRIGGER `trg_subattributes_ins` AFTER INSERT ON `subattributes` FOR EACH ROW BEGIN
  INSERT INTO audit_log(table_name, op, row_pk, changed_by, new_row)
  VALUES ('subattributes','INSERT', CAST(NEW.id_subattributes AS CHAR),
          COALESCE(@app_user, CURRENT_USER()),
          JSON_OBJECT('id_subattributes',NEW.id_subattributes,'name',NEW.name,
                      'description',NEW.description,'attributes_id_attributes',NEW.attributes_id_attributes,
                      'created_at',NEW.created_at,'updated_at',NEW.updated_at));
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`%`*/ /*!50003 TRIGGER `trg_subattributes_upd` AFTER UPDATE ON `subattributes` FOR EACH ROW BEGIN
  INSERT INTO audit_log(table_name, op, row_pk, changed_by, old_row, new_row)
  VALUES ('subattributes','UPDATE', CAST(NEW.id_subattributes AS CHAR),
          COALESCE(@app_user, CURRENT_USER()),
          JSON_OBJECT('id_subattributes',OLD.id_subattributes,'name',OLD.name,
                      'description',OLD.description,'attributes_id_attributes',OLD.attributes_id_attributes,
                      'created_at',OLD.created_at,'updated_at',OLD.updated_at),
          JSON_OBJECT('id_subattributes',NEW.id_subattributes,'name',NEW.name,
                      'description',NEW.description,'attributes_id_attributes',NEW.attributes_id_attributes,
                      'created_at',NEW.created_at,'updated_at',NEW.updated_at));
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`%`*/ /*!50003 TRIGGER `trg_subattributes_del` AFTER DELETE ON `subattributes` FOR EACH ROW BEGIN
  INSERT INTO audit_log(table_name, op, row_pk, changed_by, old_row)
  VALUES ('subattributes','DELETE', CAST(OLD.id_subattributes AS CHAR),
          COALESCE(@app_user, CURRENT_USER()),
          JSON_OBJECT('id_subattributes',OLD.id_subattributes,'name',OLD.name,
                      'description',OLD.description,'attributes_id_attributes',OLD.attributes_id_attributes,
                      'created_at',OLD.created_at,'updated_at',OLD.updated_at));
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `subattributes_conversion_sensor_endpoint`
--

DROP TABLE IF EXISTS `subattributes_conversion_sensor_endpoint`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `subattributes_conversion_sensor_endpoint` (
  `id_subattributes_conversion_sensor_endpoint` int NOT NULL AUTO_INCREMENT,
  `id_subattributes` int NOT NULL,
  `id_sensor_endpoint` int NOT NULL,
  `id_conversion` int NOT NULL,
  `parameters_watched` json DEFAULT NULL,
  PRIMARY KEY (`id_subattributes_conversion_sensor_endpoint`),
  KEY `fk_scse_sub` (`id_subattributes`),
  KEY `fk_scse_se` (`id_sensor_endpoint`),
  KEY `fk_scse_conv` (`id_conversion`),
  CONSTRAINT `fk_scse_conv` FOREIGN KEY (`id_conversion`) REFERENCES `conversion` (`id_conversion`),
  CONSTRAINT `fk_scse_se` FOREIGN KEY (`id_sensor_endpoint`) REFERENCES `sensor_endpoint` (`id_sensor_endpoint`),
  CONSTRAINT `fk_scse_sub` FOREIGN KEY (`id_subattributes`) REFERENCES `subattributes` (`id_subattributes`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `subattributes_conversion_sensor_endpoint`
--

LOCK TABLES `subattributes_conversion_sensor_endpoint` WRITE;
/*!40000 ALTER TABLE `subattributes_conversion_sensor_endpoint` DISABLE KEYS */;
INSERT INTO `subattributes_conversion_sensor_endpoint` VALUES (1,6,1,1,'{\"unit\": \"count\", \"metric\": \"steps\"}'),(2,11,2,1,'{\"unit\": \"min\", \"metric\": \"minutes_asleep\"}');
/*!40000 ALTER TABLE `subattributes_conversion_sensor_endpoint` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Temporary view structure for view `v_audit_export`
--

DROP TABLE IF EXISTS `v_audit_export`;
/*!50001 DROP VIEW IF EXISTS `v_audit_export`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_audit_export` AS SELECT 
 1 AS `player_pseudo`,
 1 AS `experiment_tag`,
 1 AS `condicion`,
 1 AS `periodo`,
 1 AS `window_start`,
 1 AS `window_end`,
 1 AS `Icf`,
 1 AS `Isfg`,
 1 AS `Ipma`,
 1 AS `Itd`,
 1 AS `IC_fis`,
 1 AS `IC_ment`,
 1 AS `IC_LSG`,
 1 AS `IAR`,
 1 AS `adm_Icf`,
 1 AS `adm_Isfg`,
 1 AS `adm_Ipma`,
 1 AS `adm_Itd`,
 1 AS `steps_day`,
 1 AS `MVPA_min_week`,
 1 AS `resting_hr_bpm`,
 1 AS `sleep_quality_score`,
 1 AS `memory_accuracy_pct`,
 1 AS `recall_speed_ms`,
 1 AS `decision_accuracy_pct`,
 1 AS `reaction_time_ms`,
 1 AS `computed_at`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `v_game_usage_points`
--

DROP TABLE IF EXISTS `v_game_usage_points`;
/*!50001 DROP VIEW IF EXISTS `v_game_usage_points`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_game_usage_points` AS SELECT 
 1 AS `id_players`,
 1 AS `id_videogame`,
 1 AS `points_spent`,
 1 AS `seconds_with_lsg`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `v_ic2_latest`
--

DROP TABLE IF EXISTS `v_ic2_latest`;
/*!50001 DROP VIEW IF EXISTS `v_ic2_latest`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_ic2_latest` AS SELECT 
 1 AS `id_ic2_result`,
 1 AS `id_players`,
 1 AS `player_name`,
 1 AS `player_email`,
 1 AS `version_tag`,
 1 AS `window_start`,
 1 AS `window_end`,
 1 AS `Icf`,
 1 AS `Isfg`,
 1 AS `Ipma`,
 1 AS `Itd`,
 1 AS `IC_fis`,
 1 AS `IC_ment`,
 1 AS `IC_LSG`,
 1 AS `IAR`,
 1 AS `admissibility`,
 1 AS `experiment_tag`,
 1 AS `computed_at`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `v_player_active_roles`
--

DROP TABLE IF EXISTS `v_player_active_roles`;
/*!50001 DROP VIEW IF EXISTS `v_player_active_roles`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_player_active_roles` AS SELECT 
 1 AS `id_players`,
 1 AS `player_name`,
 1 AS `email`,
 1 AS `role`,
 1 AS `assigned_at`,
 1 AS `assigned_by`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `v_player_attribute_balance`
--

DROP TABLE IF EXISTS `v_player_attribute_balance`;
/*!50001 DROP VIEW IF EXISTS `v_player_attribute_balance`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_player_attribute_balance` AS SELECT 
 1 AS `id_players`,
 1 AS `player_name`,
 1 AS `player_email`,
 1 AS `id_attributes`,
 1 AS `attribute_name`,
 1 AS `balance_ledger`,
 1 AS `snapshot_points`,
 1 AS `diff_ledger_minus_snapshot`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `v_player_game_overview`
--

DROP TABLE IF EXISTS `v_player_game_overview`;
/*!50001 DROP VIEW IF EXISTS `v_player_game_overview`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_player_game_overview` AS SELECT 
 1 AS `id_players`,
 1 AS `player_name`,
 1 AS `player_email`,
 1 AS `id_videogame`,
 1 AS `videogame_name`,
 1 AS `points_spent`,
 1 AS `seconds_with_lsg`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `v_points_balance`
--

DROP TABLE IF EXISTS `v_points_balance`;
/*!50001 DROP VIEW IF EXISTS `v_points_balance`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_points_balance` AS SELECT 
 1 AS `id_players`,
 1 AS `id_point_dimension`,
 1 AS `balance`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `v_temp_players_active`
--

DROP TABLE IF EXISTS `v_temp_players_active`;
/*!50001 DROP VIEW IF EXISTS `v_temp_players_active`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_temp_players_active` AS SELECT 
 1 AS `id_players`,
 1 AS `name`,
 1 AS `email`,
 1 AS `temp_expires_at`,
 1 AS `hours_remaining`,
 1 AS `roles`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `v_temp_players_expired`
--

DROP TABLE IF EXISTS `v_temp_players_expired`;
/*!50001 DROP VIEW IF EXISTS `v_temp_players_expired`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_temp_players_expired` AS SELECT 
 1 AS `id_players`,
 1 AS `name`,
 1 AS `email`,
 1 AS `temp_expires_at`,
 1 AS `hours_since_expiry`*/;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `videogame`
--

DROP TABLE IF EXISTS `videogame`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `videogame` (
  `id_videogame` int unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(100) DEFAULT NULL,
  `genre` varchar(45) DEFAULT NULL,
  `description` varchar(128) DEFAULT NULL,
  `engine` varchar(45) DEFAULT NULL,
  `developer` varchar(128) DEFAULT NULL,
  `publisher` varchar(128) DEFAULT NULL,
  `launch` varchar(45) DEFAULT NULL,
  `version` varchar(128) DEFAULT NULL,
  `type` varchar(45) DEFAULT NULL,
  PRIMARY KEY (`id_videogame`),
  KEY `ix_videogame_name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=26 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `videogame`
--

LOCK TABLES `videogame` WRITE;
/*!40000 ALTER TABLE `videogame` DISABLE KEYS */;
INSERT INTO `videogame` VALUES (1,'UpperWish','RPG-TBS',NULL,'none','Estudiantes USACH','none','2022','1.0','GFS (Game From Scratch)'),(2,'Spirit Adventure','RPG',NULL,'none','Ricardo Ruz','none','2022','1.0','GFS (Game From Scratch)'),(3,'Village Defender','RTS',NULL,'none','Gustavo Ternero','none','2022','1.0','GFS (Game From Scratch)'),(4,'Street Blocks','AVG',NULL,'none','Eduardo Lizama','none','2022','1.0','GFS (Game From Scratch)'),(5,'Blazing Duel','AVG',NULL,'none','Bastían Onetto','none','2023','1.0','GFS (Game From Scratch)'),(6,'ZonaCero','FPS',NULL,'none','Ignacio Fernández','none','2023','1.0','GFS (Game From Scratch)'),(7,'Minecraft','RPG',NULL,'Forge; Fabric','Gary Simken','CurseForge','2023','1.0','MOD'),(8,'Terraria','RPG',NULL,'tModLoader','Claudio Muñoz','Steam Workshop','2024','1.0','MOD'),(9,'WealthQuest','TG',NULL,'none','Jonathan Soto','none','2024','1.0','GFS (Game From Scratch)'),(10,'Nightmare Survivor','AVG',NULL,'none','Jeison Fiorentino','none','2024','1.0','GFS (Game From Scratch)'),(11,'Digital Masters','SGS',NULL,'none','Vicente Vargas','none','2024','1.0','GFS (Game From Scratch)'),(12,'Stardew Valley','RPG',NULL,'none','Moisés Godoy','none','2024','1.0','MOD'),(13,'Bulletland','AVG',NULL,'none','Gianfranco Piccinini','none','2024','1.0','GFS (Game From Scratch)'),(14,'Cities: Skylines','Simulation',NULL,'none','Alejandro Aldea','none','2025','1.0','MOD'),(15,'Starbound','RPG',NULL,'none','Hernan Herrera','none','2025','1.0','MOD'),(16,'Corekeeper','RPG',NULL,'none','Joaquín Macías-Cáceres','none','none','none','MOD'),(17,'Valheim','PRG',NULL,'none','Nicolas Gabrielli','none','2026','none','MOD'),(18,'Ark: Survival Evolved','RPG',NULL,'none','William Jimenez','none','2026','none','MOD'),(19,'Subnautica: Below Zero','RPG',NULL,'none','Ricardo Avaca','none','2026','none','MOD'),(20,'PEAK','Co-op Survival Climbing',NULL,'none','Luis Mellado','none','2026','none','MOD'),(21,'Doom 3 BFG Edition','First-Person',NULL,'none','Joaquín Macías-Cáceres','none','2026','none','MOD'),(22,'R.E.P.O','Action',NULL,'none','Isidora Rojas','none','2026','none','MOD'),(23,'Baldurs Gate 3','RPG','Larian Studios; 03-08-2023, Diving Engine 4.0','none','Mauricio Vicencio','none','2026','none','MOD'),(24,'Vampire Survivors','Roguelike, Bullet Hell','Poncle; 17-12-2021; Phaser, Electron','none','Joaquín Macías-Cáceres','none','none','none','MOD'),(25,'HumanitZ','Supervivencia / Sandbox','Yobubzz Studios; Indie.io; 18-09-2023; Unreal Engine 4','none','Joaquín Macías-Cáceres','none','none','none','MOD');
/*!40000 ALTER TABLE `videogame` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping events for database 'db_lsg'
--

--
-- Dumping routines for database 'db_lsg'
--
/*!50003 DROP FUNCTION IF EXISTS `sp_get_att_subattributes_id` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`%` FUNCTION `sp_get_att_subattributes_id`() RETURNS json
    READS SQL DATA
    DETERMINISTIC
BEGIN
  RETURN (
    SELECT JSON_ARRAYAGG(
             JSON_OBJECT(
               'attribute', id_attributes,
               'subattribute', sub.id_subattributes
             )
           )
    FROM attributes att
    JOIN subattributes sub
      ON att.id_attributes = sub.attributes_id_attributes
    ORDER BY att.id_attributes, sub.id_subattributes
  );
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP FUNCTION IF EXISTS `sp_get_att_subattributes_name` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`%` FUNCTION `sp_get_att_subattributes_name`() RETURNS json
    READS SQL DATA
    DETERMINISTIC
BEGIN
  RETURN (
    SELECT JSON_ARRAYAGG(
             JSON_OBJECT(
               'attribute', att.name,
               'subattribute', sub.name
             )
           )
    FROM attributes att
    JOIN subattributes sub
      ON att.id_attributes = sub.attributes_id_attributes
    ORDER BY att.id_attributes, sub.id_subattributes
  );
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP FUNCTION IF EXISTS `sp_get_players_att_points` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`%` FUNCTION `sp_get_players_att_points`() RETURNS json
    READS SQL DATA
    DETERMINISTIC
BEGIN
  RETURN (
    SELECT JSON_ARRAYAGG(
             JSON_OBJECT(
               'name_players', pla.name,
               'email_players', pla.email,
               'attributes', att.name,
               'points', plaatt.data
             )
           )
    FROM players pla
    JOIN players_attributes plaatt
      ON pla.id_players = plaatt.id_players
    JOIN attributes att
      ON plaatt.id_attributes = att.id_attributes
    ORDER BY pla.name, pla.email
  );
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP FUNCTION IF EXISTS `sp_get_videogame` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`%` FUNCTION `sp_get_videogame`() RETURNS json
    READS SQL DATA
    DETERMINISTIC
BEGIN
  RETURN (
    SELECT JSON_ARRAYAGG(
             JSON_OBJECT(
               'name', vid.name,
               'developer', vid.developer,
               'launch', vid.launch,
               'genre', vid.genre,
               'type', vid.type,
               'version', vid.version
             )
           )
    FROM videogame vid
    ORDER BY vid.name, vid.developer
  );
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_assign_pseudo_code` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`%` PROCEDURE `sp_assign_pseudo_code`(IN p_player_id INT)
BEGIN
  DECLARE v_next_num INT;

  -- Obtener el siguiente número secuencial disponible
  SELECT COALESCE(MAX(
    CAST(SUBSTRING(pseudo_code, 6) AS UNSIGNED)
  ), 0) + 1
  INTO v_next_num
  FROM research_pseudonym;

  -- Insertar solo si no existe ya (idempotente)
  INSERT IGNORE INTO research_pseudonym (id_players, pseudo_code)
  VALUES (p_player_id, CONCAT('LSG-P', LPAD(v_next_num, 3, '0')));
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_bulk_attach_mechanics` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`%` PROCEDURE `sp_bulk_attach_mechanics`(
  IN p_videogame_id   INT,
  IN p_mechanics_json JSON   -- Array: [{name, description, type, options}, ...]
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
    SET mec_name  = JSON_UNQUOTE(JSON_EXTRACT(p_mechanics_json, CONCAT('$[', i, '].name')));
    SET mec_desc  = JSON_UNQUOTE(JSON_EXTRACT(p_mechanics_json, CONCAT('$[', i, '].description')));
    SET mec_type  = JSON_UNQUOTE(JSON_EXTRACT(p_mechanics_json, CONCAT('$[', i, '].type')));
    SET mec_opts  = JSON_EXTRACT(p_mechanics_json, CONCAT('$[', i, '].options'));

    -- Insertar en catálogo si no existe (por nombre)
    INSERT IGNORE INTO `modifiable_mechanic` (`name`, `description`, `type`)
    VALUES (mec_name, mec_desc, mec_type);

    SELECT `id_modifiable_mechanic` INTO new_mm_id
    FROM   `modifiable_mechanic` WHERE `name` = mec_name LIMIT 1;

    -- Vincular al videojuego (ignorar duplicados)
    INSERT IGNORE INTO `modifiable_mechanic_videogames` (`id_videogame`, `id_modifiable_mechanic`, `options`)
    VALUES (p_videogame_id, new_mm_id, mec_opts);

    SET i = i + 1;
  END WHILE;
  COMMIT;

  SELECT CONCAT('OK: ', total, ' mecánicas procesadas para videojuego ', p_videogame_id) AS result;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_delete_player_cascade` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`%` PROCEDURE `sp_delete_player_cascade`(IN p_id INT)
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Error al borrar en cascada al player';
  END;

  START TRANSACTION;

  /* 1) Eventos de canje que dependen del ledger */
  DELETE re
    FROM redemption_event re
    JOIN points_ledger pl ON pl.id_points_ledger = re.id_points_ledger
   WHERE pl.id_players = p_id;

  /* 2) Ledger de puntos */
  DELETE FROM points_ledger WHERE id_players = p_id;

  /* 3) Ingestas de sensores (referencia directa a players y opcional a PSE/SE) */
  DELETE FROM sensor_ingest_event WHERE id_players = p_id;

  /* 4) Sesiones LSG (hija de player_videogame) */
  DELETE s
    FROM lsg_game_session s
    JOIN player_videogame pvg ON pvg.id_player_videogame = s.id_player_videogame
   WHERE pvg.id_players = p_id;

  /* 5) Relación jugador–videojuego */
  DELETE FROM player_videogame WHERE id_players = p_id;

  /* 6) Vínculos con sensores (online y endpoints) */
  DELETE FROM player_online_sensor    WHERE id_players = p_id;
  DELETE FROM players_sensor_endpoint WHERE id_players = p_id;

  /* 7) Tablas legacy de acumulados/gastos por atributo */
  DELETE FROM adquired_subattribute   WHERE id_players = p_id;
  DELETE FROM expended_attribute      WHERE id_players = p_id;

  /* 8) Snapshot/caché de atributos */
  DELETE FROM players_attributes      WHERE id_players = p_id;

  /* 9) Finalmente, el jugador */
  DELETE FROM players                 WHERE id_players = p_id;

  COMMIT;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_init_all_players_attributes` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`%` PROCEDURE `sp_init_all_players_attributes`()
    MODIFIES SQL DATA
BEGIN
  INSERT INTO players_attributes (id_players, id_attributes, data)
  SELECT 
    p.id_players,
    a.id_attributes,
    0 AS data
  FROM players p
  CROSS JOIN attributes a
  LEFT JOIN players_attributes pa
    ON pa.id_players   = p.id_players
   AND pa.id_attributes = a.id_attributes
  WHERE pa.id_players IS NULL;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_init_player_attributes` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`%` PROCEDURE `sp_init_player_attributes`(IN p_id_players INT)
    MODIFIES SQL DATA
BEGIN
  /* Inserta filas en players_attributes para todos los attributes
     que aún no existen para este jugador, con data = 0 */
  INSERT INTO players_attributes (id_players, id_attributes, data)
  SELECT 
      p_id_players        AS id_players,
      a.id_attributes     AS id_attributes,
      0                   AS data
  FROM attributes a
  LEFT JOIN players_attributes pa
    ON pa.id_players   = p_id_players
   AND pa.id_attributes = a.id_attributes
  WHERE pa.id_players IS NULL;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Final view structure for view `v_audit_export`
--

/*!50001 DROP VIEW IF EXISTS `v_audit_export`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`%` SQL SECURITY DEFINER */
/*!50001 VIEW `v_audit_export` AS select sha2(concat('LSG-FONDECYT-2026:',`r`.`id_players`),256) AS `player_pseudo`,`r`.`experiment_tag` AS `experiment_tag`,substring_index(`r`.`experiment_tag`,'_',-(1)) AS `condicion`,substring_index(substring_index(`r`.`experiment_tag`,'_',3),'_',-(1)) AS `periodo`,`r`.`window_start` AS `window_start`,`r`.`window_end` AS `window_end`,`r`.`Icf` AS `Icf`,`r`.`Isfg` AS `Isfg`,`r`.`Ipma` AS `Ipma`,`r`.`Itd` AS `Itd`,`r`.`IC_fis` AS `IC_fis`,`r`.`IC_ment` AS `IC_ment`,`r`.`IC_LSG` AS `IC_LSG`,`r`.`IAR` AS `IAR`,json_value(`r`.`admissibility`, '$.Icf' returning char(512)) AS `adm_Icf`,json_value(`r`.`admissibility`, '$.Isfg' returning char(512)) AS `adm_Isfg`,json_value(`r`.`admissibility`, '$.Ipma' returning char(512)) AS `adm_Ipma`,json_value(`r`.`admissibility`, '$.Itd' returning char(512)) AS `adm_Itd`,json_value(`r`.`raw_inputs`, '$.steps_day' returning char(512)) AS `steps_day`,json_value(`r`.`raw_inputs`, '$.MVPA_min_week' returning char(512)) AS `MVPA_min_week`,json_value(`r`.`raw_inputs`, '$.resting_hr_bpm' returning char(512)) AS `resting_hr_bpm`,json_value(`r`.`raw_inputs`, '$.sleep_quality_score' returning char(512)) AS `sleep_quality_score`,json_value(`r`.`raw_inputs`, '$.memory_accuracy_pct' returning char(512)) AS `memory_accuracy_pct`,json_value(`r`.`raw_inputs`, '$.recall_speed_ms' returning char(512)) AS `recall_speed_ms`,json_value(`r`.`raw_inputs`, '$.decision_accuracy_pct' returning char(512)) AS `decision_accuracy_pct`,json_value(`r`.`raw_inputs`, '$.reaction_time_ms' returning char(512)) AS `reaction_time_ms`,`r`.`computed_at` AS `computed_at` from `ic2_result` `r` where (`r`.`experiment_tag` is not null) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_game_usage_points`
--

/*!50001 DROP VIEW IF EXISTS `v_game_usage_points`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`%` SQL SECURITY DEFINER */
/*!50001 VIEW `v_game_usage_points` AS select `pvg`.`id_players` AS `id_players`,`pvg`.`id_videogame` AS `id_videogame`,sum((case when (`pl`.`direction` = 'DEBIT') then `pl`.`amount` else 0 end)) AS `points_spent`,sum(`s`.`duration_seconds`) AS `seconds_with_lsg` from ((`player_videogame` `pvg` left join `lsg_game_session` `s` on((`s`.`id_player_videogame` = `pvg`.`id_player_videogame`))) left join `points_ledger` `pl` on(((`pl`.`id_players` = `pvg`.`id_players`) and (`pl`.`id_videogame` = `pvg`.`id_videogame`)))) group by `pvg`.`id_players`,`pvg`.`id_videogame` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_ic2_latest`
--

/*!50001 DROP VIEW IF EXISTS `v_ic2_latest`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`%` SQL SECURITY DEFINER */
/*!50001 VIEW `v_ic2_latest` AS select `r`.`id_ic2_result` AS `id_ic2_result`,`r`.`id_players` AS `id_players`,`p`.`name` AS `player_name`,`p`.`email` AS `player_email`,`v`.`version_tag` AS `version_tag`,`r`.`window_start` AS `window_start`,`r`.`window_end` AS `window_end`,`r`.`Icf` AS `Icf`,`r`.`Isfg` AS `Isfg`,`r`.`Ipma` AS `Ipma`,`r`.`Itd` AS `Itd`,`r`.`IC_fis` AS `IC_fis`,`r`.`IC_ment` AS `IC_ment`,`r`.`IC_LSG` AS `IC_LSG`,`r`.`IAR` AS `IAR`,`r`.`admissibility` AS `admissibility`,`r`.`experiment_tag` AS `experiment_tag`,`r`.`computed_at` AS `computed_at` from ((`ic2_result` `r` join `players` `p` on((`p`.`id_players` = `r`.`id_players`))) join `ic2_goalpost_version` `v` on((`v`.`id_version` = `r`.`id_version`))) where (`r`.`computed_at` = (select max(`r2`.`computed_at`) from `ic2_result` `r2` where ((`r2`.`id_players` = `r`.`id_players`) and (`r2`.`id_version` = `r`.`id_version`)))) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_player_active_roles`
--

/*!50001 DROP VIEW IF EXISTS `v_player_active_roles`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`%` SQL SECURITY DEFINER */
/*!50001 VIEW `v_player_active_roles` AS select `p`.`id_players` AS `id_players`,`p`.`name` AS `player_name`,`p`.`email` AS `email`,`pr`.`role` AS `role`,`pr`.`assigned_at` AS `assigned_at`,`pr`.`assigned_by` AS `assigned_by` from (`players` `p` join `player_roles` `pr` on(((`pr`.`id_players` = `p`.`id_players`) and (`pr`.`revoked_at` is null)))) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_player_attribute_balance`
--

/*!50001 DROP VIEW IF EXISTS `v_player_attribute_balance`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`%` SQL SECURITY DEFINER */
/*!50001 VIEW `v_player_attribute_balance` AS select `p`.`id_players` AS `id_players`,`p`.`name` AS `player_name`,`p`.`email` AS `player_email`,`a`.`id_attributes` AS `id_attributes`,`a`.`name` AS `attribute_name`,coalesce(sum(`vpb`.`balance`),0) AS `balance_ledger`,coalesce(`pa`.`data`,0) AS `snapshot_points`,(coalesce(sum(`vpb`.`balance`),0) - coalesce(`pa`.`data`,0)) AS `diff_ledger_minus_snapshot` from ((((`players` `p` join `attributes` `a`) left join `players_attributes` `pa` on(((`pa`.`id_players` = `p`.`id_players`) and (`pa`.`id_attributes` = `a`.`id_attributes`)))) left join (select `pd`.`id_point_dimension` AS `id_point_dimension`,coalesce(`pd`.`id_attributes`,`s`.`attributes_id_attributes`) AS `id_attributes` from (`point_dimension` `pd` left join `subattributes` `s` on((`s`.`id_subattributes` = `pd`.`id_subattributes`)))) `pd_map` on((`pd_map`.`id_attributes` = `a`.`id_attributes`))) left join `v_points_balance` `vpb` on(((`vpb`.`id_players` = `p`.`id_players`) and (`vpb`.`id_point_dimension` = `pd_map`.`id_point_dimension`)))) group by `p`.`id_players`,`p`.`name`,`p`.`email`,`a`.`id_attributes`,`a`.`name`,`pa`.`data` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_player_game_overview`
--

/*!50001 DROP VIEW IF EXISTS `v_player_game_overview`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`%` SQL SECURITY DEFINER */
/*!50001 VIEW `v_player_game_overview` AS select `p`.`id_players` AS `id_players`,`p`.`name` AS `player_name`,`p`.`email` AS `player_email`,`vg`.`id_videogame` AS `id_videogame`,`vg`.`name` AS `videogame_name`,coalesce(`gup`.`points_spent`,0) AS `points_spent`,coalesce(`gup`.`seconds_with_lsg`,0) AS `seconds_with_lsg` from (((`players` `p` join `player_videogame` `pvg` on((`pvg`.`id_players` = `p`.`id_players`))) join `videogame` `vg` on((`vg`.`id_videogame` = `pvg`.`id_videogame`))) left join `v_game_usage_points` `gup` on(((`gup`.`id_players` = `p`.`id_players`) and (`gup`.`id_videogame` = `vg`.`id_videogame`)))) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_points_balance`
--

/*!50001 DROP VIEW IF EXISTS `v_points_balance`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`%` SQL SECURITY DEFINER */
/*!50001 VIEW `v_points_balance` AS select `points_ledger`.`id_players` AS `id_players`,`points_ledger`.`id_point_dimension` AS `id_point_dimension`,sum((case when (`points_ledger`.`direction` = 'CREDIT') then `points_ledger`.`amount` else -(`points_ledger`.`amount`) end)) AS `balance` from `points_ledger` group by `points_ledger`.`id_players`,`points_ledger`.`id_point_dimension` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_temp_players_active`
--

/*!50001 DROP VIEW IF EXISTS `v_temp_players_active`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`%` SQL SECURITY DEFINER */
/*!50001 VIEW `v_temp_players_active` AS select `p`.`id_players` AS `id_players`,`p`.`name` AS `name`,`p`.`email` AS `email`,`p`.`temp_expires_at` AS `temp_expires_at`,timestampdiff(HOUR,now(),`p`.`temp_expires_at`) AS `hours_remaining`,group_concat(`pr`.`role` order by `pr`.`assigned_at` ASC separator ',') AS `roles` from (`players` `p` join `player_roles` `pr` on(((`pr`.`id_players` = `p`.`id_players`) and (`pr`.`revoked_at` is null)))) where ((`p`.`temp_expires_at` is not null) and (`p`.`temp_expires_at` > now())) group by `p`.`id_players`,`p`.`name`,`p`.`email`,`p`.`temp_expires_at` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_temp_players_expired`
--

/*!50001 DROP VIEW IF EXISTS `v_temp_players_expired`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`%` SQL SECURITY DEFINER */
/*!50001 VIEW `v_temp_players_expired` AS select `p`.`id_players` AS `id_players`,`p`.`name` AS `name`,`p`.`email` AS `email`,`p`.`temp_expires_at` AS `temp_expires_at`,timestampdiff(HOUR,`p`.`temp_expires_at`,now()) AS `hours_since_expiry` from `players` `p` where ((`p`.`temp_expires_at` is not null) and (`p`.`temp_expires_at` <= now())) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-05-14 16:48:53