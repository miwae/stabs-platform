-- Enable pgcrypto extension for encryption
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Documents table with encrypted fields
CREATE TABLE documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID,
    original_scan BYTEA,  -- Encrypted image
    extracted_text BYTEA,  -- Encrypted OCR result
    file_hash VARCHAR(64),
    processing_status VARCHAR(50) DEFAULT 'pending',
    data_classification VARCHAR(20) DEFAULT 'personal',
    retention_until DATE DEFAULT NOW() + INTERVAL '7 years',
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    CONSTRAINT retention_check CHECK (retention_until >= created_at)
);

-- Extracted data table
CREATE TABLE extracted_data (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id UUID NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
    first_name VARCHAR(255),
    last_name VARCHAR(255),
    date_of_birth DATE,
    birth_place VARCHAR(255),
    address TEXT,
    document_type VARCHAR(50),
    document_number VARCHAR(100),
    issue_date DATE,
    expiry_date DATE,
    confidence_scores JSONB,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Registrations table
CREATE TABLE registrations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id UUID NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
    person_id UUID,
    event_id UUID,
    status VARCHAR(50) DEFAULT 'draft',
    field_data JSONB,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Audit logging table
CREATE TABLE audit_log (
    id BIGSERIAL PRIMARY KEY,
    event_type VARCHAR(50),
    user_id UUID,
    timestamp TIMESTAMP DEFAULT NOW(),
    document_id UUID,
    person_id UUID,
    action VARCHAR(100),
    ip_address INET,
    data_retention DATE DEFAULT NOW() + INTERVAL '7 years'
);

-- Person index for duplicate detection
CREATE TABLE person_index (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    first_name VARCHAR(255),
    last_name VARCHAR(255),
    date_of_birth DATE,
    document_count INTEGER DEFAULT 1,
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(first_name, last_name, date_of_birth)
);

-- Indexes for performance
CREATE INDEX idx_documents_user_id ON documents(user_id);
CREATE INDEX idx_documents_processing_status ON documents(processing_status);
CREATE INDEX idx_documents_created_at ON documents(created_at);
CREATE INDEX idx_extracted_data_document_id ON extracted_data(document_id);
CREATE INDEX idx_registrations_document_id ON registrations(document_id);
CREATE INDEX idx_audit_log_timestamp ON audit_log(timestamp);
CREATE INDEX idx_audit_log_document_id ON audit_log(document_id);
CREATE INDEX idx_person_index_name_dob ON person_index(first_name, last_name, date_of_birth);

-- Function for audit logging
CREATE OR REPLACE FUNCTION log_audit()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO audit_log (event_type, user_id, document_id, action, timestamp)
    VALUES (TG_ARGV[0], NULL, NEW.id, TG_OP, NOW());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for audit logging
CREATE TRIGGER audit_document_insert
AFTER INSERT ON documents
FOR EACH ROW EXECUTE FUNCTION log_audit('document_created');

CREATE TRIGGER audit_registration_insert
AFTER INSERT ON registrations
FOR EACH ROW EXECUTE FUNCTION log_audit('registration_created');

-- Cleanup trigger for expired documents
CREATE OR REPLACE FUNCTION cleanup_expired_documents()
RETURNS void AS $$
BEGIN
    DELETE FROM documents
    WHERE retention_until < NOW()
    AND data_classification = 'personal';
END;
$$ LANGUAGE plpgsql;
