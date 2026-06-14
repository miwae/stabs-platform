-- Stabs-Platform Database Schema

-- Users Table
CREATE TABLE IF NOT EXISTS users (
  id SERIAL PRIMARY KEY,
  username VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  role VARCHAR(50) DEFAULT 'user',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Incidents Table
CREATE TABLE IF NOT EXISTS incidents (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  status VARCHAR(50) DEFAULT 'active',
  description TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Resources Table
CREATE TABLE IF NOT EXISTS resources (
  id SERIAL PRIMARY KEY,
  incident_id INT REFERENCES incidents(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  type VARCHAR(50),
  status VARCHAR(50) DEFAULT 'available',
  crew_count INT DEFAULT 0,
  latitude FLOAT,
  longitude FLOAT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Markers Table (für Lagekarte)
CREATE TABLE IF NOT EXISTS markers (
  id SERIAL PRIMARY KEY,
  incident_id INT REFERENCES incidents(id) ON DELETE CASCADE,
  type VARCHAR(50),
  label VARCHAR(255),
  latitude FLOAT NOT NULL,
  longitude FLOAT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Sessions Table
CREATE TABLE IF NOT EXISTS sessions (
  id SERIAL PRIMARY KEY,
  incident_id INT REFERENCES incidents(id),
  user_id INT REFERENCES users(id) ON DELETE CASCADE,
  socket_id VARCHAR(255),
  ip_address VARCHAR(45),
  user_agent TEXT,
  expires_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Audit Log Table (DSGVO-Compliance)
CREATE TABLE IF NOT EXISTS audit_log (
  id SERIAL PRIMARY KEY,
  user_id INT REFERENCES users(id) ON DELETE SET NULL,
  action VARCHAR(100),
  entity_type VARCHAR(50),
  entity_id INT,
  details JSONB,
  ip_address VARCHAR(45),
  timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- User Permissions Table
CREATE TABLE IF NOT EXISTS user_permissions (
  id SERIAL PRIMARY KEY,
  user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  incident_id INT REFERENCES incidents(id) ON DELETE CASCADE,
  can_view BOOLEAN DEFAULT TRUE,
  can_edit BOOLEAN DEFAULT FALSE,
  can_delete BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create Indexes
CREATE INDEX IF NOT EXISTS idx_audit_timestamp ON audit_log(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_audit_user ON audit_log(user_id);
CREATE INDEX IF NOT EXISTS idx_resources_incident ON resources(incident_id);
CREATE INDEX IF NOT EXISTS idx_markers_incident ON markers(incident_id);

-- Insert Demo Users (PLAIN TEXT für Demo!)
-- In Production sollten diese gehashed sein
INSERT INTO users (username, password_hash, role) VALUES 
  ('demo', 'demo123', 'user'),
  ('admin', 'admin123', 'admin')
ON CONFLICT (username) DO NOTHING;

-- Insert Demo Incident
INSERT INTO incidents (name, status, description) VALUES 
  ('Test Einsatzlage', 'active', 'Demo-Lagekarte zum Testen')
ON CONFLICT DO NOTHING;

-- Grant Permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO stabs_user;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO stabs_user;

-- PostGIS Extension (für Geografische Daten)
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS postgis_topology;

COMMIT;
