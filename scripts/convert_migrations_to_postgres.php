<?php

/**
 * Script to convert MySQL migrations to PostgreSQL compatible format
 * Converts MySQL-specific syntax to PostgreSQL equivalent
 * 
 * Usage: php scripts/convert_migrations_to_postgres.php
 */

$migrationsDir = __DIR__ . '/../database/migrations';
$backupDir = __DIR__ . '/../database/migrations_backup';

if (!is_dir($migrationsDir)) {
    echo "❌ Migrations directory not found: {$migrationsDir}\n";
    exit(1);
}

// Create backup directory
if (!is_dir($backupDir)) {
    mkdir($backupDir, 0755, true);
    echo "✅ Created backup directory: {$backupDir}\n";
}

$files = glob($migrationsDir . '/*.php');
$convertedCount = 0;

foreach ($files as $file) {
    $filename = basename($file);
    
    // Skip non-migration files
    if (strpos($filename, 'Seeder') !== false || strpos($filename, 'Factory') !== false) {
        continue;
    }
    
    echo "\n📝 Processing: {$filename}...\n";
    
    // Read original file
    $content = file_get_contents($file);
    $originalContent = $content;
    
    // Backup original
    copy($file, $backupDir . '/' . $filename);
    
    // Convert MySQL syntax to PostgreSQL
    $content = convertMySQLToPostgreSQL($content);
    
    // Only write if changed
    if ($content !== $originalContent) {
        file_put_contents($file, $content);
        $convertedCount++;
        echo "   ✅ Converted\n";
    } else {
        echo "   ⏭️  No changes needed\n";
    }
}

echo "\n" . str_repeat("=", 50) . "\n";
echo "✅ Conversion complete!\n";
echo "   📊 Files converted: {$convertedCount}\n";
echo "   💾 Backups saved in: {$backupDir}\n";
echo str_repeat("=", 50) . "\n";

/**
 * Convert MySQL specific SQL to PostgreSQL equivalent
 */
function convertMySQLToPostgreSQL(string $sql): string
{
    // 1. Convert BIGINT UNSIGNED to BIGINT
    $sql = preg_replace('/BIGINT\s+UNSIGNED/i', 'BIGINT', $sql);
    
    // 2. Convert INT UNSIGNED to INTEGER
    $sql = preg_replace('/INT\s+UNSIGNED/i', 'INTEGER', $sql);
    
    // 3. Convert AUTO_INCREMENT PRIMARY KEY to SERIAL/BIGSERIAL
    $sql = preg_replace_callback(
        '/(\w+)\s+BIGINT\s+AUTO_INCREMENT\s+PRIMARY\s+KEY/i',
        function ($m) {
            return $m[1] . ' BIGSERIAL PRIMARY KEY';
        },
        $sql
    );
    
    $sql = preg_replace_callback(
        '/(\w+)\s+INTEGER\s+AUTO_INCREMENT\s+PRIMARY\s+KEY/i',
        function ($m) {
            return $m[1] . ' SERIAL PRIMARY KEY';
        },
        $sql
    );
    
    // 4. Remove remaining AUTO_INCREMENT keywords
    $sql = preg_replace('/\s+AUTO_INCREMENT/i', '', $sql);
    
    // 5. Convert ENUM to VARCHAR - simple version
    $sql = preg_replace(
        "/ENUM\s*\([^)]*\)/i",
        "VARCHAR(50)",
        $sql
    );
    
    // 6. Remove ON UPDATE CURRENT_TIMESTAMP
    $sql = preg_replace('/\s+ON\s+UPDATE\s+CURRENT_TIMESTAMP/i', '', $sql);
    
    // 7. Remove ENGINE=InnoDB
    $sql = preg_replace('/\s+ENGINE\s*=\s*InnoDB/i', '', $sql);
    
    // 8. Remove CHARSET and COLLATE
    $sql = preg_replace(
        '/\s+(DEFAULT\s+)?CHARSET\s*=\s*utf8mb4/i',
        '',
        $sql
    );
    $sql = preg_replace(
        '/\s+COLLATE\s*=\s*utf8mb4_unicode_ci/i',
        '',
        $sql
    );
    
    // 9. Clean up comments (remove COMMENT clauses for now)
    $sql = preg_replace("/\s+COMMENT\s*=\s*'[^']*'/i", '', $sql);
    
    // 10. Clean up multiple spaces and trailing spaces before )
    $sql = preg_replace('/\s+\)/', ')', $sql);
    $sql = preg_replace('/\s+,/', ',', $sql);
    $sql = preg_replace('/,\s*\n\s*\)/', '\n)', $sql);
    
    return $sql;
}

