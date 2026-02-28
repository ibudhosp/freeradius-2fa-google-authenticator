-- FreeRADIUS 2FA User Database Schema
-- PostgreSQL

-- Users table
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(64) NOT NULL UNIQUE,
    totp_secret VARCHAR(64) NOT NULL,
    enabled BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Authentication log table
CREATE TABLE IF NOT EXISTS auth_log (
    id SERIAL PRIMARY KEY,
    username VARCHAR(64) NOT NULL,
    success BOOLEAN NOT NULL,
    source_ip VARCHAR(45),
    nas_ip VARCHAR(45),
    reason VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Sessions table (RADIUS accounting)
CREATE TABLE IF NOT EXISTS accounting (
    id SERIAL PRIMARY KEY,
    username VARCHAR(64) NOT NULL,
    nas_ip VARCHAR(45),
    nas_port INTEGER,
    acct_session_id VARCHAR(64),
    acct_status_type VARCHAR(32),
    acct_input_octets BIGINT DEFAULT 0,
    acct_output_octets BIGINT DEFAULT 0,
    acct_session_time INTEGER DEFAULT 0,
    framed_ip_address VARCHAR(45),
    called_station_id VARCHAR(64),
    calling_station_id VARCHAR(64),
    start_time TIMESTAMP WITH TIME ZONE,
    stop_time TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_users_enabled ON users(enabled);
CREATE INDEX IF NOT EXISTS idx_auth_log_username ON auth_log(username);
CREATE INDEX IF NOT EXISTS idx_auth_log_created_at ON auth_log(created_at);
CREATE INDEX IF NOT EXISTS idx_accounting_username ON accounting(username);
CREATE INDEX IF NOT EXISTS idx_accounting_session_id ON accounting(acct_session_id);

-- Function to auto-update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for users table
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();