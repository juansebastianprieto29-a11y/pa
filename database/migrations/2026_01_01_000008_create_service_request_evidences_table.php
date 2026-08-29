<?php

use App\Core\Migration;

/**
 * Create Service Request Evidences Table Migration
 *
 * Creates the service_request_evidences table for storing photographic
 * evidence (before, during, after) associated with service requests.
 */
class CreateServiceRequestEvidencesTable extends Migration
{
    /**
     * Run the migration
     */
    public function up(): void
    {
        $this->execute("
            CREATE TABLE service_request_evidences (
                id BIGSERIAL PRIMARY KEY,
                service_request_id BIGINT NOT NULL,
                uploaded_by BIGINT NOT NULL,
                evidence_type VARCHAR(50) NOT NULL,
                image_url VARCHAR(500) NOT NULL,
                original_filename VARCHAR(255) NULL,
                file_size INTEGER NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

                INDEX idx_service_request_id (service_request_id),

                CONSTRAINT fk_evidence_service_request FOREIGN KEY (service_request_id) REFERENCES service_requests(id) ON DELETE CASCADE,
                CONSTRAINT fk_evidence_user FOREIGN KEY (uploaded_by) REFERENCES users(id))
        ");
    }

    /**
     * Reverse the migration
     */
    public function down(): void
    {
        $this->dropTable('service_request_evidences');
    }
}
