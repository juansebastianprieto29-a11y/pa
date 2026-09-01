-- Create roles table
CREATE TABLE roles (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    slug VARCHAR(50) NOT NULL UNIQUE,
    description TEXT,
    is_system_role BOOLEAN NOT NULL DEFAULT FALSE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert initial roles
INSERT INTO roles (name, slug, description, is_system_role, is_active) VALUES
('Customer', 'customer', 'Standard customer user with service request capabilities', TRUE, TRUE),
('Mechanic', 'mechanic', 'Mechanic user with service execution and vehicle management capabilities', TRUE, TRUE),
('Administrator', 'administrator', 'Administrative access to manage users, services, and platform operations', TRUE, TRUE),
('Super Administrator', 'super_admin', 'Full system access with all permissions including role and system configuration', TRUE, TRUE),
('Support Staff', 'support', 'Customer support staff with read-only access to assist users', FALSE, TRUE);

-- Create users table
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    profile_picture_url VARCHAR(500) NULL,
    account_status VARCHAR(50) NOT NULL DEFAULT 'active',
    email_verification_status VARCHAR(50) NOT NULL DEFAULT 'unverified',
    phone_verification_status VARCHAR(50) NOT NULL DEFAULT 'unverified',
    email_verified_at TIMESTAMP NULL,
    phone_verified_at TIMESTAMP NULL,
    last_login_at TIMESTAMP NULL,
    last_login_ip VARCHAR(45) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL
);

-- Create user_roles table
CREATE TABLE user_roles (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    role_id INTEGER NOT NULL,
    assigned_by BIGINT NULL,
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE,
    FOREIGN KEY (assigned_by) REFERENCES users(id) ON DELETE SET NULL,
    UNIQUE (user_id, role_id)
);

-- Insert demo user (email: santisotoo311224@gmail.com, password: Santi1234)
INSERT INTO users (email, password_hash, first_name, last_name, phone, account_status, email_verification_status, phone_verification_status, email_verified_at, phone_verified_at) VALUES
('santisotoo311224@gmail.com', '$2y$10$V3P0r1pF0C3j5q0c4h8q3eG8k4Z2x1Y9W6v5U8t7S4r3Q2p1O0N9M', 'Santiago', 'Sotoo', '+57', 'active', 'verified', 'verified', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- Assign customer role to demo user
INSERT INTO user_roles (user_id, role_id, is_active) VALUES
((SELECT id FROM users WHERE email = 'santisotoo311224@gmail.com'), (SELECT id FROM roles WHERE slug = 'customer'), TRUE);

-- Create sessions table
CREATE TABLE sessions (
    id VARCHAR(255) PRIMARY KEY,
    user_id BIGINT NOT NULL,
    ip_address VARCHAR(45) NOT NULL,
    user_agent TEXT NOT NULL,
    payload TEXT NOT NULL,
    last_activity INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Create vehicles table
CREATE TABLE vehicles (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    plate VARCHAR(20) NOT NULL,
    vin VARCHAR(50),
    make VARCHAR(100) NOT NULL,
    model VARCHAR(100) NOT NULL,
    year INTEGER NOT NULL,
    color VARCHAR(50),
    vehicle_type VARCHAR(50) NOT NULL,
    fuel_type VARCHAR(50) NOT NULL,
    registration_date DATE,
    documents_expiration_date DATE,
    documents_url VARCHAR(500),
    registration_url VARCHAR(500),
    insurance_url VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Create service_requests table
CREATE TABLE service_requests (
    id BIGSERIAL PRIMARY KEY,
    customer_id BIGINT NOT NULL,
    vehicle_id BIGINT NOT NULL,
    mechanic_id BIGINT,
    status VARCHAR(50) NOT NULL DEFAULT 'pending',
    service_type VARCHAR(100) NOT NULL,
    description TEXT NOT NULL,
    location VARCHAR(255),
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    estimated_cost DECIMAL(10, 2),
    actual_cost DECIMAL(10, 2),
    rating INTEGER,
    mechanic_rating INTEGER,
    vehicle_condition_rating INTEGER,
    communication_rating INTEGER,
    professionalism_rating INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP NULL,
    cancelled_at TIMESTAMP NULL,
    
    FOREIGN KEY (customer_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (vehicle_id) REFERENCES vehicles(id) ON DELETE CASCADE,
    FOREIGN KEY (mechanic_id) REFERENCES users(id) ON DELETE SET NULL
);

-- Create service_request_evidences table
CREATE TABLE service_request_evidences (
    id BIGSERIAL PRIMARY KEY,
    service_request_id BIGINT NOT NULL,
    evidence_url VARCHAR(500) NOT NULL,
    evidence_type VARCHAR(50) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (service_request_id) REFERENCES service_requests(id) ON DELETE CASCADE
);

-- Create pqr table (complaints, claims, requests)
CREATE TABLE pqr (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    type VARCHAR(50) NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'open',
    priority VARCHAR(50) NOT NULL DEFAULT 'normal',
    response TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP NULL,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Create surveys table
CREATE TABLE surveys (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    service_request_id BIGINT,
    overall_satisfaction INTEGER,
    mechanic_professionalism INTEGER,
    response_time INTEGER,
    quality_of_service INTEGER,
    comments TEXT,
    would_recommend BOOLEAN,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (service_request_id) REFERENCES service_requests(id) ON DELETE SET NULL
);

-- Create password_reset_tokens table
CREATE TABLE password_reset_tokens (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    token VARCHAR(255) NOT NULL UNIQUE,
    expires_at TIMESTAMP NOT NULL,
    used_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Create indexes
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_account_status ON users(account_status);
CREATE INDEX idx_users_created_at ON users(created_at);
CREATE INDEX idx_user_roles_user_id ON user_roles(user_id);
CREATE INDEX idx_user_roles_role_id ON user_roles(role_id);
CREATE INDEX idx_sessions_user_id ON sessions(user_id);
CREATE INDEX idx_vehicles_user_id ON vehicles(user_id);
CREATE INDEX idx_service_requests_customer_id ON service_requests(customer_id);
CREATE INDEX idx_service_requests_mechanic_id ON service_requests(mechanic_id);
CREATE INDEX idx_service_requests_status ON service_requests(status);
CREATE INDEX idx_pqr_user_id ON pqr(user_id);
CREATE INDEX idx_surveys_user_id ON surveys(user_id);
CREATE INDEX idx_password_reset_tokens_user_id ON password_reset_tokens(user_id);
