<?php

use App\Core\Migration;

/**
 * Add ID Number to Users Table Migration
 * 
 * Adds id_number field to users table for storing national ID or passport number.
 */
class AddIdNumberToUsers extends Migration
{
    /**
     * Run the migration
     */
    public function up(): void
    {
        $this->execute("
            ALTER TABLE users 
            ADD COLUMN id_number VARCHAR(50) NULL AFTER phone
        ");
    }

    /**
     * Reverse the migration
     */
    public function down(): void
    {
        $this->execute("
            ALTER TABLE users 
            DROP COLUMN id_number
        ");
    }
}
