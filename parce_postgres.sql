-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1
-- Tiempo de generación: 14-08-2026 a las 20:20:48
-- Versión del servidor: 10.4.32-MariaDB
-- Versión de PHP: 8.2.12
BEGIN;
;
;
;
;
--
-- Base de datos: "parce"
--
-- --------------------------------------------------------
--
-- Estructura de tabla para la tabla "admin_access_requests"
--
CREATE TABLE IF NOT EXISTS "admin_access_requests" (
  "id" bigint NOT NULL,
  "user_id" bigint NOT NULL,
  "requested_role_id" integer NOT NULL,
  "justification" text NOT NULL,
  "status" VARCHAR(255) NOT NULL DEFAULT 'pending',
  "reviewed_by" bigint DEFAULT NULL,
  "approved_by" bigint DEFAULT NULL,
  "review_notes" text DEFAULT NULL,
  "rejection_reason" text DEFAULT NULL,
  "reviewed_at" timestamp NULL DEFAULT NULL,
  "approved_at" timestamp NULL DEFAULT NULL,
  "created_at" timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updated_at" timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ;
-- --------------------------------------------------------
--
-- Estructura de tabla para la tabla "migrations"
--
CREATE TABLE IF NOT EXISTS "migrations" (
  "id" integer NOT NULL,
  "migration" varchar(255) NOT NULL,
  "batch" integer NOT NULL,
  "created_at" timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
);
--
-- --------------------------------------------------------
--
-- Estructura de tabla para la tabla "password_reset_tokens"
--
CREATE TABLE IF NOT EXISTS "password_reset_tokens" (
  "id" bigint NOT NULL,
  "user_id" bigint NOT NULL,
  "token" varchar(255) NOT NULL,
  "expires_at" timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "created_at" timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "used_at" timestamp NULL DEFAULT NULL
);
--
-- --------------------------------------------------------
--
-- Estructura de tabla para la tabla "pqr"
--
CREATE TABLE IF NOT EXISTS "pqr" (
  "id" bigint NOT NULL,
  "user_id" bigint NOT NULL,
  "ticket_code" varchar(20) NOT NULL,
  "type" VARCHAR(255) NOT NULL,
  "subject" varchar(150) NOT NULL,
  "description" text NOT NULL,
  "status" VARCHAR(255) NOT NULL DEFAULT 'pending',
  "admin_response" text DEFAULT NULL,
  "responded_by" bigint DEFAULT NULL,
  "responded_at" timestamp NULL DEFAULT NULL,
  "created_at" timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updated_at" timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "deleted_at" timestamp NULL DEFAULT NULL
);
--
-- --------------------------------------------------------
--
-- Estructura de tabla para la tabla "roles"
--
CREATE TABLE IF NOT EXISTS "roles" (
  "id" integer NOT NULL,
  "name" varchar(50) NOT NULL,
  "slug" varchar(50) NOT NULL,
  "description" text DEFAULT NULL,
  "is_system_role" boolean NOT NULL DEFAULT 0,
  "is_active" boolean NOT NULL DEFAULT 1,
  "created_at" timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updated_at" timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
);
--
-- --------------------------------------------------------
--
-- Estructura de tabla para la tabla "service_requests"
--
CREATE TABLE IF NOT EXISTS "service_requests" (
  "id" bigint NOT NULL,
  "service_code" varchar(20) NOT NULL,
  "customer_id" bigint NOT NULL,
  "vehicle_id" bigint NOT NULL,
  "mechanic_id" bigint DEFAULT NULL,
  "resolved_by" bigint DEFAULT NULL,
  "emergency_type" varchar(50) NOT NULL,
  "description" text NOT NULL,
  "priority" varchar(20) NOT NULL DEFAULT 'normal',
  "latitude" decimal(10,8) NOT NULL,
  "longitude" decimal(11,8) NOT NULL,
  "status" varchar(20) NOT NULL DEFAULT 'pending',
  "requested_at" timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "assigned_at" timestamp NULL DEFAULT NULL,
  "started_at" timestamp NULL DEFAULT NULL,
  "completed_at" timestamp NULL DEFAULT NULL,
  "cancelled_at" timestamp NULL DEFAULT NULL,
  "expired_at" timestamp NULL DEFAULT NULL,
  "cancellation_reason" text DEFAULT NULL,
  "cancelled_by" bigint DEFAULT NULL,
  "estimated_cost" decimal(10,2) DEFAULT NULL,
  "final_cost" decimal(10,2) DEFAULT NULL,
  "customer_rating" boolean DEFAULT NULL,
  "customer_feedback" text DEFAULT NULL,
  "created_at" timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updated_at" timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "deleted_at" timestamp NULL DEFAULT NULL,
  "punctuality_rating" boolean DEFAULT NULL,
  "service_quality_rating" boolean DEFAULT NULL
) ;
--
-- --------------------------------------------------------
--
-- Estructura de tabla para la tabla "service_request_evidences"
--
CREATE TABLE IF NOT EXISTS "service_request_evidences" (
  "id" bigint NOT NULL,
  "service_request_id" bigint NOT NULL,
  "uploaded_by" bigint NOT NULL,
  "evidence_type" VARCHAR(255) NOT NULL,
  "image_url" varchar(500) NOT NULL,
  "original_filename" varchar(255) DEFAULT NULL,
  "description" varchar(500) DEFAULT NULL,
  "file_size" integer DEFAULT NULL,
  "created_at" timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
);
-- --------------------------------------------------------
--
-- Estructura de tabla para la tabla "sessions"
--
CREATE TABLE IF NOT EXISTS "sessions" (
  "id" varchar(255) NOT NULL,
  "user_id" bigint DEFAULT NULL,
  "ip_address" varchar(45) DEFAULT NULL,
  "user_agent" text DEFAULT NULL,
  "payload" longtext NOT NULL,
  "last_activity" integer NOT NULL,
  "created_at" timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
);
--
-- --------------------------------------------------------
--
-- Estructura de tabla para la tabla "surveys"
--
CREATE TABLE IF NOT EXISTS "surveys" (
  "id" bigint NOT NULL,
  "service_request_id" bigint NOT NULL,
  "customer_id" bigint NOT NULL,
  "overall_satisfaction" boolean NOT NULL,
  "would_recommend" boolean NOT NULL,
  "comments" text DEFAULT NULL,
  "created_at" timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updated_at" timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "deleted_at" timestamp NULL DEFAULT NULL
) ;
--
-- --------------------------------------------------------
--
-- Estructura de tabla para la tabla "users"
--
CREATE TABLE IF NOT EXISTS "users" (
  "id" bigint NOT NULL,
  "email" varchar(255) NOT NULL,
  "password_hash" varchar(255) NOT NULL,
  "first_name" varchar(100) NOT NULL,
  "last_name" varchar(100) NOT NULL,
  "phone" varchar(20) DEFAULT NULL,
  "profile_picture_url" varchar(500) DEFAULT NULL,
  "account_status" VARCHAR(255) NOT NULL DEFAULT 'active',
  "email_verification_status" VARCHAR(255) NOT NULL DEFAULT 'unverified',
  "phone_verification_status" VARCHAR(255) NOT NULL DEFAULT 'unverified',
  "email_verified_at" timestamp NULL DEFAULT NULL,
  "phone_verified_at" timestamp NULL DEFAULT NULL,
  "last_login_at" timestamp NULL DEFAULT NULL,
  "last_login_ip" varchar(45) DEFAULT NULL,
  "created_at" timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updated_at" timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "deleted_at" timestamp NULL DEFAULT NULL,
  "driver_license_number" varchar(50) DEFAULT NULL,
  "driver_license_expiration_date" date DEFAULT NULL,
  "driver_license_document_url" varchar(500) DEFAULT NULL,
  "driver_license_status" VARCHAR(255) NOT NULL DEFAULT 'not_set',
  "driver_license_uploaded_at" timestamp NULL DEFAULT NULL
) ;
--
-- Volcado de datos para la tabla "users"
--
INSERT INTO "users" ("id", "email", "password_hash", "first_name", "last_name", "phone", "profile_picture_url", "account_status", "email_verification_status", "phone_verification_status", "email_verified_at", "phone_verified_at", "last_login_at", "last_login_ip", "created_at", "updated_at", "deleted_at", "driver_license_number", "driver_license_expiration_date", "driver_license_document_url", "driver_license_status", "driver_license_uploaded_at") VALUES
(1, 'cliente.demo@parcedemo.local', '$argon2id$v=19$m=65536,t=4,p=1$a1NPTTFTRzVzV214eUo0Zg$/zF9nbBetZL1l7jhiwLUMnFBKhfriZHv3gae63ibHwU', 'Cliente', 'Demo', '3001234567', NULL, 'active', 'unverified', 'unverified', NULL, NULL, NULL, NULL, '2026-08-06 00:47:54', '2026-08-06 00:47:54', NULL, NULL, NULL, NULL, 'not_set', NULL),
(2, 'mecanico.demo@parcedemo.local', '$argon2id$v=19$m=65536,t=4,p=1$M2ptTWlJWVE1RW9oSUZFeQ$+IuyI1G5eyYsSRFwzRzgFpiEOvIYEeZUT9/8s+buLM8', 'Mecánico', 'Demo', '3007654321', NULL, 'active', 'unverified', 'unverified', NULL, NULL, NULL, NULL, '2026-08-06 00:47:54', '2026-08-06 00:47:54', NULL, NULL, NULL, NULL, 'not_set', NULL),
(3, 'admin.demo@parcedemo.local', '$argon2id$v=19$m=65536,t=4,p=1$bUIyNXZxTzBQODZ5SjR4Qw$uHH1S0db6wycOhYwu8hPhKyd2bYgRfpG6rclRiQE2W0', 'Administrador', 'Demo', '3009998888', NULL, 'active', 'unverified', 'unverified', NULL, NULL, '2026-08-13 03:09:01', '::1', '2026-08-06 00:47:54', '2026-08-12 20:09:01', NULL, NULL, NULL, NULL, 'not_set', NULL),
(4, 'juansebastianprieto29@gmail.com', '$argon2id$v=19$m=65536,t=4,p=1$Rk12dHlJbUhIdWd3QmgwZw$NW5efzbPO84szQ2I9EzSkWapCCC6JDZ7eXyoYBjBSo0', 'Juan', 'Prieto', '3219419326', NULL, 'active', 'unverified', 'unverified', NULL, NULL, '2026-08-13 02:51:10', '::1', '2026-08-06 00:59:50', '2026-08-12 19:51:10', NULL, NULL, NULL, NULL, 'not_set', NULL),
(5, 'andresrt545l@gmail.com', '$argon2id$v=19$m=65536,t=4,p=1$ZllLSlVLYTYzV29BZjJ3Qg$1zLI9JGayFC/6ogUCtUjkldKZMQu0mEGnL9Fo35vBu4', 'Andres', 'rodriguez', '3214919458', NULL, 'active', 'unverified', 'unverified', NULL, NULL, '2026-08-06 01:16:46', '::1', '2026-08-06 01:04:50', '2026-08-05 20:16:46', NULL, NULL, NULL, NULL, 'not_set', NULL),
(6, 'santisotoo311224@gmail.com', '$argon2id$v=19$m=65536,t=4,p=1$OHpQSWtSZjNuOTN2Lm14MQ$8WovbMoEXGNKN1fXaPKOwI3PHwJfLowTlStBmd3OWYA', 'santiago', 'soto', '3214567894', NULL, 'active', 'unverified', 'unverified', NULL, NULL, '2026-08-13 02:51:48', '::1', '2026-08-06 01:19:33', '2026-08-12 19:51:48', NULL, NULL, NULL, NULL, 'not_set', NULL);
-- --------------------------------------------------------
--
-- Estructura de tabla para la tabla "user_roles"
--
CREATE TABLE IF NOT EXISTS "user_roles" (
  "id" bigint NOT NULL,
  "user_id" bigint NOT NULL,
  "role_id" integer NOT NULL,
  "assigned_by" bigint DEFAULT NULL,
  "assigned_at" timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "expires_at" timestamp NULL DEFAULT NULL,
  "is_active" boolean NOT NULL DEFAULT 1,
  "created_at" timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updated_at" timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ;
--
-- Volcado de datos para la tabla "user_roles"
--
INSERT INTO "user_roles" ("id", "user_id", "role_id", "assigned_by", "assigned_at", "expires_at", "is_active", "created_at", "updated_at") VALUES
(1, true, true, NULL, '2026-08-06 00:47:54', NULL, true, '2026-08-05 19:47:54', '2026-08-05 19:47:54'),
(2, 2, 2, NULL, '2026-08-06 00:47:54', NULL, true, '2026-08-05 19:47:54', '2026-08-05 19:47:54'),
(3, 3, 3, NULL, '2026-08-06 00:47:54', NULL, true, '2026-08-05 19:47:54', '2026-08-05 19:47:54'),
(4, 4, true, NULL, '2026-08-06 00:59:50', NULL, true, '2026-08-05 19:59:50', '2026-08-05 19:59:50'),
(5, 5, true, NULL, '2026-08-06 01:04:50', NULL, true, '2026-08-05 20:04:50', '2026-08-05 20:04:50'),
(6, 6, true, NULL, '2026-08-06 01:19:33', NULL, true, '2026-08-05 20:19:33', '2026-08-05 20:19:33');
-- --------------------------------------------------------
--
-- Estructura de tabla para la tabla "vehicles"
--
CREATE TABLE IF NOT EXISTS "vehicles" (
  "id" bigint NOT NULL,
  "user_id" bigint NOT NULL,
  "license_plate" varchar(20) NOT NULL,
  "make" varchar(50) NOT NULL,
  "model" varchar(50) NOT NULL,
  "year" smallinteger NOT NULL,
  "color" varchar(30) DEFAULT NULL,
  "vin" varchar(17) DEFAULT NULL,
  "vehicle_type" varchar(20) NOT NULL DEFAULT 'sedan',
  "fuel_type" varchar(20) NOT NULL DEFAULT 'gasoline',
  "nickname" varchar(50) DEFAULT NULL,
  "primary_photo_url" varchar(255) DEFAULT NULL,
  "is_primary" boolean NOT NULL DEFAULT 0,
  "status" varchar(20) NOT NULL DEFAULT 'active',
  "created_at" timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updated_at" timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "deleted_at" timestamp NULL DEFAULT NULL,
  "soat_number" varchar(50) DEFAULT NULL,
  "soat_expiration_date" date DEFAULT NULL,
  "soat_document_url" varchar(500) DEFAULT NULL,
  "soat_uploaded_at" timestamp NULL DEFAULT NULL,
  "tecnomecanica_number" varchar(50) DEFAULT NULL,
  "tecnomecanica_expiration_date" date DEFAULT NULL,
  "tecnomecanica_document_url" varchar(500) DEFAULT NULL,
  "tecnomecanica_uploaded_at" timestamp NULL DEFAULT NULL
);
--
--
-- Índices para tablas volcadas
--
--
-- Indices de la tabla "admin_access_requests"
--
--
-- Indices de la tabla "migrations"
--
--
-- Indices de la tabla "password_reset_tokens"
--
--
-- Indices de la tabla "pqr"
--
--
-- Indices de la tabla "roles"
--
--
-- Indices de la tabla "service_requests"
--
--
-- Indices de la tabla "service_request_evidences"
--
--
-- Indices de la tabla "surveys"
--
--
-- Indices de la tabla "users"
--
--
-- Indices de la tabla "user_roles"
--
--
-- Indices de la tabla "vehicles"
--
--
-- AUTO_INCREMENT de las tablas volcadas
--
--
-- AUTO_INCREMENT de la tabla "admin_access_requests"
--
--
-- AUTO_INCREMENT de la tabla "migrations"
--
--
-- AUTO_INCREMENT de la tabla "password_reset_tokens"
--
--
-- AUTO_INCREMENT de la tabla "pqr"
--
--
-- AUTO_INCREMENT de la tabla "roles"
--
--
-- AUTO_INCREMENT de la tabla "service_requests"
--
--
-- AUTO_INCREMENT de la tabla "service_request_evidences"
--
--
-- AUTO_INCREMENT de la tabla "surveys"
--
--
-- AUTO_INCREMENT de la tabla "users"
--
--
-- AUTO_INCREMENT de la tabla "user_roles"
--
--
-- AUTO_INCREMENT de la tabla "vehicles"
--
--
-- Restricciones para tablas volcadas
--
--
-- Filtros para la tabla "admin_access_requests"
--
--
-- Filtros para la tabla "password_reset_tokens"
--
--
-- Filtros para la tabla "pqr"
--
--
-- Filtros para la tabla "service_requests"
--
--
-- Filtros para la tabla "service_request_evidences"
--
--
-- Filtros para la tabla "sessions"
--
--
-- Filtros para la tabla "surveys"
--
--
-- Filtros para la tabla "user_roles"
--
--
-- Filtros para la tabla "vehicles"
--
COMMIT;
;
;
;
