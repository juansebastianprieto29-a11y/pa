-- Dump corregido para importar en phpMyAdmin (MariaDB 10.4 / MySQL 8)
-- Base de datos: parce

/*!40101 SET NAMES utf8mb4 */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET UNIQUE_CHECKS=0 */;
SET FOREIGN_KEY_CHECKS=0;
/*!40101 SET SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;

CREATE DATABASE IF NOT EXISTS `parce` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `parce`;

DROP TABLE IF EXISTS `user_roles`;
DROP TABLE IF EXISTS `surveys`;
DROP TABLE IF EXISTS `sessions`;
DROP TABLE IF EXISTS `pqr`;
DROP TABLE IF EXISTS `password_reset_tokens`;
DROP TABLE IF EXISTS `migrations`;
DROP TABLE IF EXISTS `admin_access_requests`;
DROP TABLE IF EXISTS `service_request_evidences`;
DROP TABLE IF EXISTS `service_requests`;
DROP TABLE IF EXISTS `vehicles`;
DROP TABLE IF EXISTS `users`;
DROP TABLE IF EXISTS `roles`;

CREATE TABLE `roles` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL,
  `slug` varchar(50) NOT NULL,
  `description` text DEFAULT NULL,
  `is_system_role` tinyint(1) NOT NULL DEFAULT 0,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`),
  UNIQUE KEY `slug` (`slug`),
  KEY `idx_is_active` (`is_active`),
  KEY `idx_is_system_role` (`is_system_role`),
  KEY `idx_active_system` (`is_active`,`is_system_role`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `roles` (`id`, `name`, `slug`, `description`, `is_system_role`, `is_active`, `created_at`, `updated_at`) VALUES (1,'Customer','customer','Standard customer user with service request capabilities',1,1,'2026-08-05 19:47:53','2026-08-05 19:47:53'),(2,'Mechanic','mechanic','Mechanic user with service execution and vehicle management capabilities',1,1,'2026-08-05 19:47:53','2026-08-05 19:47:53'),(3,'Administrator','administrator','Administrative access to manage users, services, and platform operations',1,1,'2026-08-05 19:47:53','2026-08-05 19:47:53'),(4,'Super Administrator','super_admin','Full system access with all permissions including role and system configuration',1,1,'2026-08-05 19:47:53','2026-08-05 19:47:53'),(5,'Support Staff','support','Customer support staff with read-only access to assist users',0,1,'2026-08-05 19:47:53','2026-08-05 19:47:53');

CREATE TABLE `users` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `email` varchar(255) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `first_name` varchar(100) NOT NULL,
  `last_name` varchar(100) NOT NULL,
  `phone` varchar(20) DEFAULT NULL,
  `id_number` varchar(50) DEFAULT NULL,
  `profile_picture_url` varchar(500) DEFAULT NULL,
  `account_status` enum('active','suspended','deactivated','pending_verification') NOT NULL DEFAULT 'active' COMMENT 'MVP: Users active by default. Email verification planned for production.',
  `email_verification_status` enum('unverified','verified') NOT NULL DEFAULT 'unverified',
  `phone_verification_status` enum('unverified','verified') NOT NULL DEFAULT 'unverified',
  `email_verified_at` timestamp NULL DEFAULT NULL,
  `phone_verified_at` timestamp NULL DEFAULT NULL,
  `last_login_at` timestamp NULL DEFAULT NULL,
  `last_login_ip` varchar(45) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `deleted_at` timestamp NULL DEFAULT NULL,
  `driver_license_number` varchar(50) DEFAULT NULL,
  `driver_license_expiration_date` date DEFAULT NULL,
  `driver_license_document_url` varchar(500) DEFAULT NULL,
  `driver_license_status` enum('not_set','valid','expiring_soon','expired') NOT NULL DEFAULT 'not_set',
  `driver_license_uploaded_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `email` (`email`),
  KEY `idx_account_status` (`account_status`),
  KEY `idx_email_verification_status` (`email_verification_status`),
  KEY `idx_phone_verification_status` (`phone_verification_status`),
  KEY `idx_last_login_at` (`last_login_at`),
  KEY `idx_deleted_at` (`deleted_at`),
  KEY `idx_created_at` (`created_at`),
  KEY `idx_account_email_status` (`account_status`,`email_verification_status`),
  KEY `idx_last_login_account` (`last_login_at`,`account_status`),
  CONSTRAINT `chk_email_verification` CHECK (`email_verification_status` = 'verified' and `email_verified_at` is not null or `email_verification_status` = 'unverified'),
  CONSTRAINT `chk_phone_verification` CHECK (`phone_verification_status` = 'verified' and `phone_verified_at` is not null or `phone_verification_status` = 'unverified')
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `users` (`id`, `email`, `password_hash`, `first_name`, `last_name`, `phone`, `id_number`, `profile_picture_url`, `account_status`, `email_verification_status`, `phone_verification_status`, `email_verified_at`, `phone_verified_at`, `last_login_at`, `last_login_ip`, `created_at`, `updated_at`, `deleted_at`, `driver_license_number`, `driver_license_expiration_date`, `driver_license_document_url`, `driver_license_status`, `driver_license_uploaded_at`) VALUES (1,'cliente.demo@parcedemo.local','$argon2id$v=19$m=65536,t=4,p=1$a1NPTTFTRzVzV214eUo0Zg$/zF9nbBetZL1l7jhiwLUMnFBKhfriZHv3gae63ibHwU','Cliente','Demo','3001234567',NULL,NULL,'active','unverified','unverified',NULL,NULL,NULL,NULL,'2026-08-06 00:47:54','2026-08-06 00:47:54',NULL,NULL,NULL,NULL,'not_set',NULL),(2,'mecanico.demo@parcedemo.local','$argon2id$v=19$m=65536,t=4,p=1$M2ptTWlJWVE1RW9oSUZFeQ$+IuyI1G5eyYsSRFwzRzgFpiEOvIYEeZUT9/8s+buLM8','Mecánico','Demo','3007654321',NULL,NULL,'active','unverified','unverified',NULL,NULL,NULL,NULL,'2026-08-06 00:47:54','2026-08-06 00:47:54',NULL,NULL,NULL,NULL,'not_set',NULL),(3,'admin.demo@parcedemo.local','$argon2id$v=19$m=65536,t=4,p=1$bUIyNXZxTzBQODZ5SjR4Qw$uHH1S0db6wycOhYwu8hPhKyd2bYgRfpG6rclRiQE2W0','Administrador','Demo','3009998888',NULL,NULL,'active','unverified','unverified',NULL,NULL,'2026-09-03 06:57:07','::1','2026-08-06 00:47:54','2026-09-02 23:57:07',NULL,NULL,NULL,NULL,'not_set',NULL),(4,'juansebastianprieto29@gmail.com','$argon2id$v=19$m=65536,t=4,p=1$Rk12dHlJbUhIdWd3QmgwZw$NW5efzbPO84szQ2I9EzSkWapCCC6JDZ7eXyoYBjBSo0','Juan','Prieto','3219419326',NULL,NULL,'active','unverified','unverified',NULL,NULL,'2026-09-03 07:01:51','::1','2026-08-06 00:59:50','2026-09-03 00:01:51',NULL,NULL,NULL,NULL,'not_set',NULL),(5,'andresrt545l@gmail.com','$argon2id$v=19$m=65536,t=4,p=1$ZllLSlVLYTYzV29BZjJ3Qg$1zLI9JGayFC/6ogUCtUjkldKZMQu0mEGnL9Fo35vBu4','Andres','rodriguez','3214919458',NULL,NULL,'active','unverified','unverified',NULL,NULL,'2026-08-06 01:16:46','::1','2026-08-06 01:04:50','2026-08-05 20:16:46',NULL,NULL,NULL,NULL,'not_set',NULL),(6,'santisotoo311224@gmail.com','$argon2id$v=19$m=65536,t=4,p=1$OHpQSWtSZjNuOTN2Lm14MQ$8WovbMoEXGNKN1fXaPKOwI3PHwJfLowTlStBmd3OWYA','santiago','soto','3214567894',NULL,NULL,'active','unverified','unverified',NULL,NULL,'2026-09-03 06:39:21','::1','2026-08-06 01:19:33','2026-09-02 23:39:21',NULL,NULL,NULL,NULL,'not_set',NULL),(7,'juangnzalezb@gmail.com','$argon2id$v=19$m=65536,t=4,p=1$aEFCbjFFSUtsRnZqay53Ug$2sWKfIRsmp34fAHzjA/OgvcteXJ3TvDmic1pgCm4D8Y','Juan','Gonzalez','3203731424','1028863870',NULL,'active','unverified','unverified',NULL,NULL,'2026-09-03 06:43:24','::1','2026-09-03 06:43:23','2026-09-02 23:43:24',NULL,'45545454545',NULL,NULL,'not_set','2026-09-03 06:43:23');

CREATE TABLE `vehicles` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` bigint(20) unsigned NOT NULL COMMENT 'Owner of the vehicle',
  `license_plate` varchar(20) NOT NULL COMMENT 'Normalized license plate (uppercase, trimmed)',
  `make` varchar(50) NOT NULL COMMENT 'Vehicle manufacturer',
  `model` varchar(50) NOT NULL COMMENT 'Vehicle model',
  `year` smallint(5) unsigned NOT NULL COMMENT 'Manufacturing year',
  `color` varchar(30) DEFAULT NULL COMMENT 'Vehicle color',
  `vin` varchar(17) DEFAULT NULL COMMENT 'Vehicle Identification Number (17 chars)',
  `vehicle_type` varchar(20) NOT NULL DEFAULT 'sedan' COMMENT 'sedan, suv, truck, motorcycle, van, other',
  `fuel_type` varchar(20) NOT NULL DEFAULT 'gasoline' COMMENT 'gasoline, diesel, electric, hybrid, other',
  `nickname` varchar(50) DEFAULT NULL COMMENT 'User-friendly name for the vehicle',
  `primary_photo_url` varchar(255) DEFAULT NULL COMMENT 'URL to primary vehicle photo',
  `is_primary` tinyint(1) NOT NULL DEFAULT 0 COMMENT 'Is this the user primary vehicle?',
  `status` varchar(20) NOT NULL DEFAULT 'active' COMMENT 'active or inactive',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `deleted_at` timestamp NULL DEFAULT NULL COMMENT 'Soft delete timestamp',
  `soat_number` varchar(50) DEFAULT NULL COMMENT 'SOAT policy number',
  `soat_expiration_date` date DEFAULT NULL COMMENT 'SOAT expiration date',
  `soat_document_url` varchar(500) DEFAULT NULL COMMENT 'URL to uploaded SOAT document',
  `soat_uploaded_at` timestamp NULL DEFAULT NULL COMMENT 'When the SOAT document was uploaded',
  `tecnomecanica_number` varchar(50) DEFAULT NULL COMMENT 'Tecnomecánica certificate number',
  `tecnomecanica_expiration_date` date DEFAULT NULL COMMENT 'Tecnomecánica expiration date',
  `tecnomecanica_document_url` varchar(500) DEFAULT NULL COMMENT 'URL to uploaded Tecnomecánica document',
  `tecnomecanica_uploaded_at` timestamp NULL DEFAULT NULL COMMENT 'When the Tecnomecánica document was uploaded',
  PRIMARY KEY (`id`),
  KEY `idx_vehicles_user_id` (`user_id`),
  KEY `idx_vehicles_license_plate` (`license_plate`),
  KEY `idx_vehicles_status` (`status`),
  KEY `idx_vehicles_deleted_at` (`deleted_at`),
  KEY `idx_vehicles_is_primary` (`is_primary`),
  KEY `idx_vehicles_created_at` (`created_at`),
  KEY `idx_vehicles_user_status` (`user_id`,`status`),
  KEY `idx_vehicles_user_deleted` (`user_id`,`deleted_at`),
  KEY `idx_vehicles_vin` (`vin`),
  CONSTRAINT `fk_vehicles_user_id` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `vehicles` (`id`, `user_id`, `license_plate`, `make`, `model`, `year`, `color`, `vin`, `vehicle_type`, `fuel_type`, `nickname`, `primary_photo_url`, `is_primary`, `status`, `created_at`, `updated_at`, `deleted_at`, `soat_number`, `soat_expiration_date`, `soat_document_url`, `soat_uploaded_at`, `tecnomecanica_number`, `tecnomecanica_expiration_date`, `tecnomecanica_document_url`, `tecnomecanica_uploaded_at`) VALUES (1,1,'DEM001','Chevrolet','Spark GT',2020,'Blanco',NULL,'sedan','gasoline','Vehículo Demo',NULL,1,'active','2026-08-05 19:47:54','2026-08-05 19:47:54',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),(2,6,'ABC-123','Chevrolet','Spark',2020,'Gris',NULL,'car','gasoline',NULL,NULL,1,'active','2026-08-05 20:45:08','2026-08-05 20:45:08',NULL,'SOAT-2024-123456',NULL,NULL,'2026-08-05 20:45:08','TM-2024-789012',NULL,NULL,'2026-08-05 20:45:08'),(3,7,'FGH-456','Mazda','R12',2020,'Blanco',NULL,'car','gasoline',NULL,NULL,1,'active','2026-09-03 06:43:23','2026-09-03 06:43:23',NULL,'2323254520',NULL,NULL,'2026-09-03 06:43:23','253151321',NULL,NULL,'2026-09-03 06:43:23');

CREATE TABLE `service_requests` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `service_code` varchar(20) NOT NULL COMMENT 'Public tracking code (e.g., SR-2024-001234)',
  `customer_id` bigint(20) unsigned NOT NULL COMMENT 'Customer who created the request',
  `vehicle_id` bigint(20) unsigned NOT NULL COMMENT 'Vehicle needing service',
  `mechanic_id` bigint(20) unsigned DEFAULT NULL COMMENT 'Assigned mechanic (null until assigned)',
  `resolved_by` bigint(20) unsigned DEFAULT NULL COMMENT 'Mechanic who completed the service',
  `emergency_type` varchar(50) NOT NULL COMMENT 'tire, battery, fuel, lockout, tow, engine, other',
  `description` text NOT NULL COMMENT 'Customer description of the problem',
  `priority` varchar(20) NOT NULL DEFAULT 'normal' COMMENT 'normal, urgent, critical',
  `latitude` decimal(10,8) NOT NULL COMMENT 'Latitude where help is needed',
  `longitude` decimal(11,8) NOT NULL COMMENT 'Longitude where help is needed',
  `status` varchar(20) NOT NULL DEFAULT 'pending' COMMENT 'pending, assigned, in_progress, completed, cancelled, expired',
  `requested_at` timestamp NOT NULL DEFAULT current_timestamp() COMMENT 'When request was created',
  `assigned_at` timestamp NULL DEFAULT NULL COMMENT 'When mechanic was assigned',
  `started_at` timestamp NULL DEFAULT NULL COMMENT 'When mechanic started work',
  `completed_at` timestamp NULL DEFAULT NULL COMMENT 'When service was completed',
  `cancelled_at` timestamp NULL DEFAULT NULL COMMENT 'When request was cancelled',
  `expired_at` timestamp NULL DEFAULT NULL COMMENT 'When request expired',
  `cancellation_reason` text DEFAULT NULL COMMENT 'Why the request was cancelled',
  `cancelled_by` bigint(20) unsigned DEFAULT NULL COMMENT 'User who cancelled (customer or admin)',
  `estimated_cost` decimal(10,2) DEFAULT NULL COMMENT 'Mechanic estimated cost',
  `final_cost` decimal(10,2) DEFAULT NULL COMMENT 'Actual final cost',
  `customer_rating` tinyint(3) unsigned DEFAULT NULL COMMENT 'Customer rating 1-5',
  `customer_feedback` text DEFAULT NULL COMMENT 'Customer review',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `deleted_at` timestamp NULL DEFAULT NULL COMMENT 'Soft delete (admin only)',
  `punctuality_rating` tinyint(3) unsigned DEFAULT NULL COMMENT 'Punctuality rating 1-5',
  `service_quality_rating` tinyint(3) unsigned DEFAULT NULL COMMENT 'Service quality rating 1-5',
  PRIMARY KEY (`id`),
  UNIQUE KEY `service_code` (`service_code`),
  KEY `fk_service_requests_resolved_by` (`resolved_by`),
  KEY `fk_service_requests_cancelled_by` (`cancelled_by`),
  KEY `idx_service_requests_customer_id` (`customer_id`),
  KEY `idx_service_requests_vehicle_id` (`vehicle_id`),
  KEY `idx_service_requests_mechanic_id` (`mechanic_id`),
  KEY `idx_service_requests_status` (`status`),
  KEY `idx_service_requests_emergency_type` (`emergency_type`),
  KEY `idx_service_requests_priority` (`priority`),
  KEY `idx_service_requests_requested_at` (`requested_at`),
  KEY `idx_service_requests_deleted_at` (`deleted_at`),
  KEY `idx_service_requests_customer_status` (`customer_id`,`status`),
  KEY `idx_service_requests_mechanic_status` (`mechanic_id`,`status`),
  KEY `idx_service_requests_status_requested` (`status`,`requested_at`),
  KEY `idx_service_requests_status_priority` (`status`,`priority`,`requested_at`),
  KEY `idx_service_requests_location` (`latitude`,`longitude`),
  CONSTRAINT `fk_service_requests_cancelled_by` FOREIGN KEY (`cancelled_by`) REFERENCES `users` (`id`),
  CONSTRAINT `fk_service_requests_customer_id` FOREIGN KEY (`customer_id`) REFERENCES `users` (`id`),
  CONSTRAINT `fk_service_requests_mechanic_id` FOREIGN KEY (`mechanic_id`) REFERENCES `users` (`id`),
  CONSTRAINT `fk_service_requests_resolved_by` FOREIGN KEY (`resolved_by`) REFERENCES `users` (`id`),
  CONSTRAINT `fk_service_requests_vehicle_id` FOREIGN KEY (`vehicle_id`) REFERENCES `vehicles` (`id`),
  CONSTRAINT `chk_punctuality_rating` CHECK (`punctuality_rating` is null or `punctuality_rating` >= 1 and `punctuality_rating` <= 5),
  CONSTRAINT `chk_service_quality_rating` CHECK (`service_quality_rating` is null or `service_quality_rating` >= 1 and `service_quality_rating` <= 5)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `service_requests` (`id`, `service_code`, `customer_id`, `vehicle_id`, `mechanic_id`, `resolved_by`, `emergency_type`, `description`, `priority`, `latitude`, `longitude`, `status`, `requested_at`, `assigned_at`, `started_at`, `completed_at`, `cancelled_at`, `expired_at`, `cancellation_reason`, `cancelled_by`, `estimated_cost`, `final_cost`, `customer_rating`, `customer_feedback`, `created_at`, `updated_at`, `deleted_at`, `punctuality_rating`, `service_quality_rating`) VALUES (1,'SR-2026-000001',1,1,2,2,'battery','Batería descargada en zona norte de Bogotá (dato de demostración).','normal',4.71100000,-74.07210000,'completed','2026-08-06 00:47:54','2026-08-06 00:47:54','2026-08-06 00:47:54','2026-08-06 00:47:54',NULL,NULL,NULL,NULL,80000.00,75000.00,5,'Excelente atención, muy puntual y profesional (dato de demostración).','2026-08-06 00:47:54','2026-08-05 19:47:54',NULL,5,5);

CREATE TABLE `service_request_evidences` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `service_request_id` bigint(20) unsigned NOT NULL,
  `uploaded_by` bigint(20) unsigned NOT NULL,
  `evidence_type` enum('before','during','after') NOT NULL,
  `image_url` varchar(500) NOT NULL,
  `original_filename` varchar(255) DEFAULT NULL,
  `description` varchar(500) DEFAULT NULL,
  `file_size` int(10) unsigned DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_service_request_id` (`service_request_id`),
  KEY `fk_evidence_user` (`uploaded_by`),
  CONSTRAINT `fk_evidence_service_request` FOREIGN KEY (`service_request_id`) REFERENCES `service_requests` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_evidence_user` FOREIGN KEY (`uploaded_by`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `admin_access_requests` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` bigint(20) unsigned NOT NULL,
  `requested_role_id` int(10) unsigned NOT NULL,
  `justification` text NOT NULL,
  `status` enum('pending','approved','rejected','cancelled') NOT NULL DEFAULT 'pending',
  `reviewed_by` bigint(20) unsigned DEFAULT NULL,
  `approved_by` bigint(20) unsigned DEFAULT NULL,
  `review_notes` text DEFAULT NULL,
  `rejection_reason` text DEFAULT NULL,
  `reviewed_at` timestamp NULL DEFAULT NULL,
  `approved_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_requested_role_id` (`requested_role_id`),
  KEY `idx_status` (`status`),
  KEY `idx_reviewed_by` (`reviewed_by`),
  KEY `idx_approved_by` (`approved_by`),
  KEY `idx_reviewed_at` (`reviewed_at`),
  KEY `idx_created_at` (`created_at`),
  KEY `idx_status_created` (`status`,`created_at`),
  KEY `idx_status_reviewed_approved` (`status`,`reviewed_at`,`approved_at`),
  CONSTRAINT `admin_access_requests_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `admin_access_requests_ibfk_2` FOREIGN KEY (`requested_role_id`) REFERENCES `roles` (`id`) ON DELETE CASCADE,
  CONSTRAINT `admin_access_requests_ibfk_3` FOREIGN KEY (`reviewed_by`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `admin_access_requests_ibfk_4` FOREIGN KEY (`approved_by`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `chk_rejection_reason` CHECK (`status` <> 'rejected' or `rejection_reason` is not null)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `migrations` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `migration` varchar(255) NOT NULL,
  `batch` int(11) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_migration` (`migration`)
) ENGINE=InnoDB AUTO_INCREMENT=19 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `migrations` (`id`, `migration`, `batch`, `created_at`) VALUES (1,'2024_01_01_000001_create_users_and_roles_tables',1,'2026-08-05 19:47:53'),(2,'2024_01_01_000002_create_sessions_table',2,'2026-08-05 19:47:53'),(3,'2024_01_01_000003_create_vehicles_table',3,'2026-08-05 19:47:53'),(4,'2024_01_01_000004_create_service_requests_table',4,'2026-08-05 19:47:53'),(5,'2026_01_01_000005_add_document_fields_to_vehicles',5,'2026-08-05 19:47:53'),(6,'2026_01_01_000006_add_driver_license_to_users',6,'2026-08-05 19:47:53'),(7,'2026_01_01_000007_add_detailed_ratings_to_service_requests',7,'2026-08-05 19:47:54'),(8,'2026_01_01_000008_create_service_request_evidences_table',8,'2026-08-05 19:47:54'),(9,'2026_07_10_000009_create_pqr_table',9,'2026-08-05 19:47:54'),(10,'2026_07_10_000010_create_surveys_table',10,'2026-08-05 19:47:54'),(11,'2026_07_10_000011_add_missing_rating_columns_to_service_requests',11,'2026-08-05 19:47:54'),(12,'2026_07_10_000012_seed_demo_users_and_sample_data',12,'2026-08-05 19:47:54'),(13,'2026_07_10_000013_add_driver_license_status_to_users',13,'2026-08-05 19:47:54'),(14,'2026_07_10_000014_add_description_to_service_request_evidences',14,'2026-08-05 19:47:55'),(15,'2026_07_10_000015_restore_document_fields_to_vehicles',15,'2026-08-05 19:49:24'),(16,'2026_07_16_000016_drop_unique_constraint_from_vehicle_plate_vin',16,'2026-08-05 19:49:31'),(17,'2026_08_12_000017_create_password_reset_tokens_table',17,'2026-09-02 19:34:48'),(18,'2026_09_02_000018_add_id_number_to_users',18,'2026-09-02 19:34:48');

CREATE TABLE `password_reset_tokens` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` bigint(20) unsigned NOT NULL,
  `token` varchar(255) NOT NULL,
  `expires_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `used_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `token` (`token`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_expires_at` (`expires_at`),
  CONSTRAINT `password_reset_tokens_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=15 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `password_reset_tokens` (`id`, `user_id`, `token`, `expires_at`, `created_at`, `used_at`) VALUES (1,4,'abaa9a154f3c6faee7cbc65a549c1b094b1171a0abe27bff5cdad29d26bc524b','2026-08-13 23:53:38','2026-08-12 18:53:38',NULL),(2,3,'312c936765491e3a613994b8f0107e78a8b61d1e5d32caea80e34c15d7345f37','2026-08-14 02:11:48','2026-08-12 19:11:48',NULL),(3,3,'36b6a0ad738e2a2c5f0b72b7fe79dcdb4b44929290b780380bf09d384a24b8db','2026-08-12 19:12:00','2026-08-12 19:12:00','2026-08-13 02:12:00'),(4,3,'9bf623ba65aae8e6fffcf232a889e547fbb15a21c019830ab82c0b5bac8c2d02','2026-08-12 19:12:10','2026-08-12 19:12:09','2026-08-13 02:12:10'),(5,3,'6d16d6f9758f4af74677931e5e107a399ba854500ab5fad153ce9c8c50efe879','2026-08-12 19:13:33','2026-08-12 19:13:32','2026-08-13 02:13:33'),(6,3,'a30f68d7273f75340ca9e5d2a11e0dd74be2370072c4fc0e300a44372703beee','2026-08-12 19:13:59','2026-08-12 19:13:58','2026-08-13 02:13:59'),(7,4,'2e855f38d9aa8a9c41d4326e6749bdc35ef6702342993e20d63e68c5e4bd9eb7','2026-08-14 02:18:07','2026-08-12 19:18:07',NULL),(8,4,'3c317f9faf391a01c544ff2e67ca389715fcf23471cd8fbf9b704daf76aa622f','2026-08-14 02:36:53','2026-08-12 19:36:53',NULL),(9,4,'798d068dd0821f30336a1222c1763f978fb195fca604922ded986700eaecc6c7','2026-08-14 02:40:25','2026-08-12 19:40:25',NULL),(10,4,'9af05944648e449f42a16fe4a0ba0e6ae44f869e790f071ab5c0446ebb14bbb6','2026-08-14 02:47:44','2026-08-12 19:47:44',NULL),(11,4,'9494bb6f9aa3ce8e190f708540c6b6ce726ae632ffcea401589f39c96f842c39','2026-08-12 19:50:22','2026-08-12 19:49:47','2026-08-13 02:50:22'),(12,3,'892de54c72af82bbe166fbdee920281376382a56f51de47bc6f30e408a1a9db2','2026-08-14 02:58:25','2026-08-12 19:58:25',NULL),(13,3,'b6377f37ca26deae5c31e66af180678a106249362fc7a9836472e1982c21ef17','2026-08-12 19:59:35','2026-08-12 19:59:08','2026-08-13 02:59:35'),(14,6,'ff402b24203140bf9c86ed56130888e4424333788aee1a28520be2d1bd7da9d7','2026-08-14 03:05:39','2026-08-12 20:05:39',NULL);

CREATE TABLE `pqr` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` bigint(20) unsigned NOT NULL,
  `ticket_code` varchar(20) NOT NULL,
  `type` enum('peticion','queja','reclamo','sugerencia') NOT NULL,
  `subject` varchar(150) NOT NULL,
  `description` text NOT NULL,
  `status` enum('pending','in_review','resolved','rejected') NOT NULL DEFAULT 'pending',
  `admin_response` text DEFAULT NULL,
  `responded_by` bigint(20) unsigned DEFAULT NULL,
  `responded_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `ticket_code` (`ticket_code`),
  KEY `fk_pqr_responded_by` (`responded_by`),
  KEY `idx_pqr_user_id` (`user_id`),
  KEY `idx_pqr_status` (`status`),
  KEY `idx_pqr_type` (`type`),
  KEY `idx_pqr_created_at` (`created_at`),
  KEY `idx_pqr_deleted_at` (`deleted_at`),
  CONSTRAINT `fk_pqr_responded_by` FOREIGN KEY (`responded_by`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_pqr_user_id` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `pqr` (`id`, `user_id`, `ticket_code`, `type`, `subject`, `description`, `status`, `admin_response`, `responded_by`, `responded_at`, `created_at`, `updated_at`, `deleted_at`) VALUES (1,1,'PQR-2026-000001','peticion','Solicitud de factura del servicio','Quisiera recibir la factura electrónica de mi último servicio (dato de demostración).','pending',NULL,NULL,NULL,'2026-08-05 19:47:54','2026-08-05 19:47:54',NULL);

CREATE TABLE `sessions` (
  `id` varchar(255) NOT NULL,
  `user_id` bigint(20) unsigned DEFAULT NULL,
  `ip_address` varchar(45) DEFAULT NULL,
  `user_agent` text DEFAULT NULL,
  `payload` longtext NOT NULL,
  `last_activity` int(10) unsigned NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_last_activity` (`last_activity`),
  CONSTRAINT `sessions_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- (Se omiten las filas de `sessions`: eran sesiones ya expiradas.)

CREATE TABLE `surveys` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `service_request_id` bigint(20) unsigned NOT NULL,
  `customer_id` bigint(20) unsigned NOT NULL,
  `overall_satisfaction` tinyint(3) unsigned NOT NULL,
  `would_recommend` tinyint(1) NOT NULL,
  `comments` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `service_request_id` (`service_request_id`),
  KEY `idx_surveys_customer_id` (`customer_id`),
  KEY `idx_surveys_created_at` (`created_at`),
  CONSTRAINT `fk_surveys_customer_id` FOREIGN KEY (`customer_id`) REFERENCES `users` (`id`),
  CONSTRAINT `fk_surveys_service_request_id` FOREIGN KEY (`service_request_id`) REFERENCES `service_requests` (`id`) ON DELETE CASCADE,
  CONSTRAINT `chk_overall_satisfaction` CHECK (`overall_satisfaction` between 1 and 5)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `surveys` (`id`, `service_request_id`, `customer_id`, `overall_satisfaction`, `would_recommend`, `comments`, `created_at`, `updated_at`, `deleted_at`) VALUES (1,1,1,5,1,'Muy buena experiencia con el mecánico asignado (dato de demostración).','2026-08-05 19:47:54','2026-08-05 19:47:54',NULL);

CREATE TABLE `user_roles` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` bigint(20) unsigned NOT NULL,
  `role_id` int(10) unsigned NOT NULL,
  `assigned_by` bigint(20) unsigned DEFAULT NULL,
  `assigned_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `expires_at` timestamp NULL DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_user_role` (`user_id`,`role_id`),
  KEY `idx_role_id` (`role_id`),
  KEY `idx_assigned_by` (`assigned_by`),
  KEY `idx_is_active` (`is_active`),
  KEY `idx_expires_at` (`expires_at`),
  KEY `idx_assigned_at` (`assigned_at`),
  KEY `idx_user_role_active_expires` (`user_id`,`role_id`,`is_active`,`expires_at`),
  KEY `idx_expires_active` (`expires_at`,`is_active`),
  CONSTRAINT `user_roles_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `user_roles_ibfk_2` FOREIGN KEY (`role_id`) REFERENCES `roles` (`id`) ON DELETE CASCADE,
  CONSTRAINT `user_roles_ibfk_3` FOREIGN KEY (`assigned_by`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `chk_expires_future` CHECK (`expires_at` is null or `expires_at` > `assigned_at`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `user_roles` (`id`, `user_id`, `role_id`, `assigned_by`, `assigned_at`, `expires_at`, `is_active`, `created_at`, `updated_at`) VALUES (1,1,1,NULL,'2026-08-06 00:47:54',NULL,1,'2026-08-05 19:47:54','2026-08-05 19:47:54'),(2,2,2,NULL,'2026-08-06 00:47:54',NULL,1,'2026-08-05 19:47:54','2026-08-05 19:47:54'),(3,3,3,NULL,'2026-08-06 00:47:54',NULL,1,'2026-08-05 19:47:54','2026-08-05 19:47:54'),(4,4,1,NULL,'2026-08-06 00:59:50',NULL,1,'2026-08-05 19:59:50','2026-08-05 19:59:50'),(5,5,1,NULL,'2026-08-06 01:04:50',NULL,1,'2026-08-05 20:04:50','2026-08-05 20:04:50'),(6,6,1,NULL,'2026-08-06 01:19:33',NULL,1,'2026-08-05 20:19:33','2026-08-05 20:19:33'),(7,7,1,NULL,'2026-09-03 06:43:23',NULL,1,'2026-09-02 23:43:23','2026-09-02 23:43:23');

SET FOREIGN_KEY_CHECKS=1;
/*!40014 SET UNIQUE_CHECKS=1 */;
