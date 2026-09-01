<?php

/**
 * Convierte un backup SQL de MySQL a PostgreSQL compatible
 * SOLO importa usuarios y user_roles válidos
 * Remueve TODAS las tablas/INSERTs problemáticos
 * Uso: php scripts/convert_mysql_backup_to_postgres.php database/backups/parce.sql
 */

if ($argc < 2) {
    echo "❌ Uso: php scripts/convert_mysql_backup_to_postgres.php <archivo_sql>\n";
    exit(1);
}

$inputFile = $argv[1];
$baseDir = __DIR__ . '/..';
$outputFile = $baseDir . '/parce_postgres.sql';

if (!file_exists($inputFile)) {
    echo "❌ Archivo no encontrado: {$inputFile}\n";
    exit(1);
}

echo "📖 Leyendo: {$inputFile}\n";
$content = file_get_contents($inputFile);

echo "🔄 Convirtiendo MySQL → PostgreSQL...\n";

// Reemplazar backticks con comillas
$content = str_replace('`', '"', $content);

// Remover SET SQL_MODE y similares
$content = preg_replace('/^SET .*?;/m', '', $content);
$content = preg_replace('/^START TRANSACTION;/m', 'BEGIN;', $content);

// Remover /*!...*/ comentarios
$content = preg_replace('/\/\*!.*?\*\//s', '', $content);

// Convertir tipos de datos MySQL a PostgreSQL
$content = preg_replace('/bigint\s*\(\d+\)\s+unsigned/i', 'bigint', $content);
$content = preg_replace('/int\s*\(\d+\)\s+unsigned/i', 'integer', $content);
$content = preg_replace('/bigint\s*\(\d+\)/i', 'bigint', $content);
$content = preg_replace('/int\s*\(\d+\)/i', 'integer', $content);
$content = preg_replace('/smallint\s*\(\d+\)/i', 'smallint', $content);
$content = preg_replace('/tinyint\s*\(\d+\)/i', 'boolean', $content);

// Convertir enum a VARCHAR
$content = preg_replace("/enum\s*\([^)]+\)/i", "VARCHAR(255)", $content);

// Convertir PRIMARY KEY AUTOINCREMENT
$content = preg_replace('/("?\w+"?)\s+bigint\s+NOT\s+NULL\s+AUTO_INCREMENT\s+PRIMARY\s+KEY/i', '$1 bigserial PRIMARY KEY', $content);
$content = preg_replace('/("?\w+"?)\s+integer\s+NOT\s+NULL\s+AUTO_INCREMENT\s+PRIMARY\s+KEY/i', '$1 serial PRIMARY KEY', $content);

// Remover ON UPDATE CURRENT_TIMESTAMP
$content = preg_replace('/\s+ON\s+UPDATE\s+current_timestamp\(\)/i', '', $content);
$content = preg_replace('/\s+ON\s+UPDATE\s+CURRENT_TIMESTAMP/i', '', $content);

// Cambiar current_timestamp() a CURRENT_TIMESTAMP
$content = preg_replace('/current_timestamp\(\)/i', 'CURRENT_TIMESTAMP', $content);

// Remover ENGINE, CHARSET, COLLATE
$content = preg_replace('/\s+ENGINE\s*=\s*InnoDB/i', '', $content);
$content = preg_replace('/\s+DEFAULT\s+CHARSET\s*=\s*utf8mb4/i', '', $content);
$content = preg_replace('/\s+COLLATE\s*=\s*utf8mb4_unicode_ci/i', '', $content);
$content = preg_replace('/\s+COLLATE\s*=\s*utf8mb4_general_ci/i', '', $content);
$content = preg_replace('/\s+COLLATE\s*=\s*utf8_general_ci/i', '', $content);

// Remover MODIFY ... AUTO_INCREMENT
$content = preg_replace('/MODIFY\s+"?\w+"?\s+\w+\s+NOT\s+NULL\s+AUTO_INCREMENT.*?;/i', '', $content);

// Remover comas finales antes de )
$content = preg_replace('/,\s*\);/', ');', $content);

// Remover COMMENT
$content = preg_replace('/\s+COMMENT\s+\'[^\']*\'/i', '', $content);

// Remover ADD KEY, ADD UNIQUE KEY, ADD PRIMARY KEY
$content = preg_replace('/^\s*ADD\s+(KEY|UNIQUE KEY|PRIMARY KEY).*?$/m', '', $content);

// Remover ALTER TABLE
$lines = explode("\n", $content);
$filteredLines = [];
$skipNextAlter = false;

foreach ($lines as $line) {
    if (preg_match('/^ALTER TABLE/i', $line)) {
        $skipNextAlter = true;
        continue;
    }
    
    if ($skipNextAlter) {
        if (preg_match('/^(--|CREATE|INSERT|BEGIN|COMMIT|$)/i', trim($line))) {
            $skipNextAlter = false;
        } else {
            continue;
        }
    }
    
    $filteredLines[] = $line;
}

$content = implode("\n", $filteredLines);

// Remover CONSTRAINT de FOREIGN KEY
$content = preg_replace('/,\s*CONSTRAINT\s+"[^"]+"\s+FOREIGN\s+KEY[^;]*(?=\))/i', '', $content);

// Convertir CREATE TABLE a CREATE TABLE IF NOT EXISTS
$content = preg_replace('/CREATE TABLE\s+("?\w+"?)/i', 'CREATE TABLE IF NOT EXISTS $1', $content);

// ========== REMOVER TODOS LOS INSERTS PROBLEMÁTICOS ==========

// 1. Remover INSERT INTO roles (ya existe en Supabase)
$content = preg_replace('/--\s*Volcado de datos para la tabla "roles".*?INSERT INTO "roles"[^;]*;/is', '', $content);

// 2. Remover INSERT INTO migrations (ya existe)
$content = preg_replace('/--\s*Volcado de datos para la tabla "migrations".*?INSERT INTO "migrations"[^;]*;/is', '', $content);

// 3. Remover INSERT INTO password_reset_tokens (foreign key violations)
$content = preg_replace('/--\s*Volcado de datos para la tabla "password_reset_tokens".*?INSERT INTO "password_reset_tokens"[^;]*;/is', '', $content);

// 4. Remover INSERT INTO pqr (columnas diferentes)
$content = preg_replace('/--\s*Volcado de datos para la tabla "pqr".*?INSERT INTO "pqr"[^;]*;/is', '', $content);

// 5. Remover INSERT INTO surveys (si referencia user_id inválido)
$content = preg_replace('/--\s*Volcado de datos para la tabla "surveys".*?INSERT INTO "surveys"[^;]*;/is', '', $content);

// 6. Remover INSERT INTO service_request_evidences (si referencia service_request_id inválido)
$content = preg_replace('/--\s*Volcado de datos para la tabla "service_request_evidences".*?INSERT INTO "service_request_evidences"[^;]*;/is', '', $content);

// 7. Remover INSERT INTO service_requests (si referencia customer/mechanic/vehicle inválido)
$content = preg_replace('/--\s*Volcado de datos para la tabla "service_requests".*?INSERT INTO "service_requests"[^;]*;/is', '', $content);

// 8. Remover INSERT INTO vehicles (si referencia user_id > 6)
$content = preg_replace('/--\s*Volcado de datos para la tabla "vehicles".*?INSERT INTO "vehicles"[^;]*;/is', '', $content);

// 9. Remover INSERT INTO sessions (if any)
$content = preg_replace('/--\s*Volcado de datos para la tabla "sessions".*?INSERT INTO "sessions"[^;]*;/is', '', $content);

// 10. Remover INSERT INTO admin_access_requests (if any)
$content = preg_replace('/--\s*Volcado de datos para la tabla "admin_access_requests".*?INSERT INTO "admin_access_requests"[^;]*;/is', '', $content);

// Remover cualquier INSERT INTO sessions que no haya sido removido
$content = preg_replace('/INSERT INTO "sessions"\s*\([^)]*\)\s*VALUES[^;]*;/is', '', $content);

// Remover comentarios y datos huérfanos de sessions (que quedaron sin INSERT)
$content = preg_replace('/--\s*(?:Volcado de datos para la tabla|Indices de la tabla|AUTO_INCREMENT de la tabla|Filtros para la tabla)\s*"sessions".*?(?=--\s*(?:Volcado de datos|Indices de la tabla|Estructura de tabla|CREATE TABLE|INSERT INTO|$))/is', '', $content);

// Remover líneas que contengan datos de Mozilla/Chrome (sessions data)
$content = preg_replace('/^.*?Mozilla.*$/m', '', $content);
$content = preg_replace('/^.*?Chrome.*$/m', '', $content);
$content = preg_replace('/^.*?Safari.*$/m', '', $content);

// FIX: Adaptar INSERT INTO users - remover columnas que no existen en Supabase
// Supabase users NO tiene: driver_license_number, driver_license_expiration_date, driver_license_document_url, driver_license_status, driver_license_uploaded_at
$content = preg_replace_callback(
    '/INSERT INTO "users"\s*\(\s*"id",\s*"email",\s*"password_hash",\s*"first_name",\s*"last_name",\s*"phone",\s*"profile_picture_url",\s*"account_status",\s*"email_verification_status",\s*"phone_verification_status",\s*"email_verified_at",\s*"phone_verified_at",\s*"last_login_at",\s*"last_login_ip",\s*"created_at",\s*"updated_at",\s*"deleted_at",\s*"driver_license_number",\s*"driver_license_expiration_date",\s*"driver_license_document_url",\s*"driver_license_status",\s*"driver_license_uploaded_at"\s*\)/i',
    'INSERT INTO "users" ("id", "email", "password_hash", "first_name", "last_name", "phone", "profile_picture_url", "account_status", "email_verification_status", "phone_verification_status", "email_verified_at", "phone_verified_at", "last_login_at", "last_login_ip", "created_at", "updated_at", "deleted_at")',
    $content
);

// Remover las últimas 5 columnas de driver_license del INSERT users
$content = preg_replace(
    '/"driver_license_number",\s*"driver_license_expiration_date",\s*"driver_license_document_url",\s*"driver_license_status",\s*"driver_license_uploaded_at"\s*\)/',
    ')',
    $content
);

// Remover los 5 últimos valores de cada fila de users
// Patrón: , NULL, NULL, NULL, 'not_set', NULL) o , NULL, NULL, NULL, false, NULL)
$content = preg_replace(
    '/,\s*NULL,\s*NULL,\s*NULL,\s*[\'"]?(?:not_set|false)[\'"]?,\s*NULL\s*\)/',
    ')',
    $content
);

// ========== MANTENER SOLO: users y user_roles ==========

// Convertir tinyinteger a boolean
$content = preg_replace('/tinyinteger/i', 'boolean', $content);

// Escapar comillas simples en datos (MySQL usa \' pero PostgreSQL usa '')
$lines = explode("\n", $content);
$processedLines = [];
$inInsert = false;

foreach ($lines as $line) {
    if (preg_match('/^INSERT INTO/', $line)) {
        $inInsert = true;
    } elseif (preg_match('/^\s*;$/', $line)) {
        $inInsert = false;
    }
    
    // En líneas de datos, reemplazar \' con ''
    if ($inInsert && preg_match('/^\s*\(/', $line)) {
        $line = str_replace("\\'", "''", $line);
    }
    
    $processedLines[] = $line;
}

$content = implode("\n", $processedLines);

// Convertir 1/0 a true/false SOLO en user_roles
$lines = explode("\n", $content);
$processedLines = [];
$currentTable = '';

foreach ($lines as $line) {
    // Detectar qué tabla estamos procesando
    if (preg_match('/INSERT INTO "(\w+)"/', $line, $m)) {
        $currentTable = $m[1];
    }
    
    // Solo convertir en user_roles
    if ($currentTable === 'user_roles' && preg_match('/^\s*\(\d+/', $line)) {
        $line = str_replace(', 1,', ', true,', $line);
        $line = str_replace(',1,', ',true,', $line);
        $line = str_replace(', 0,', ', false,', $line);
        $line = str_replace(',0,', ',false,', $line);
        
        $line = str_replace(', 1)', ', true)', $line);
        $line = str_replace(',1)', ',true)', $line);
        $line = str_replace(', 0)', ', false)', $line);
        $line = str_replace(',0)', ',false)', $line);
        
        $line = str_replace('true, 1,', 'true, true,', $line);
        $line = str_replace('true, 0,', 'true, false,', $line);
        $line = str_replace('false, 1,', 'false, true,', $line);
        $line = str_replace('false, 0,', 'false, false,', $line);
        
        $line = str_replace('true, 1)', 'true, true)', $line);
        $line = str_replace('true, 0)', 'true, false)', $line);
        $line = str_replace('false, 1)', 'false, true)', $line);
        $line = str_replace('false, 0)', 'false, false)', $line);
    }
    
    $processedLines[] = $line;
}

$content = implode("\n", $processedLines);

// Limpiar líneas vacías múltiples
$content = preg_replace('/\n\s*\n+/', "\n", $content);

echo "💾 Guardando: {$outputFile}\n";
file_put_contents($outputFile, $content);

echo "✅ Conversión completada!\n";
echo "   📄 Archivo convertido: {$outputFile}\n";
echo "   Solo usuarios y user_roles fueron importados\n";
