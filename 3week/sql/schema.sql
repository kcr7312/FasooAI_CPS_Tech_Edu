-- Week 03 - Maintenance DB schema
-- TODO: 교육생이 직접 작성/보완할 것.

CREATE DATABASE IF NOT EXISTS Maintenance;
USE Maintenance;

CREATE TABLE IF NOT EXISTS server_health_check (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    server_name VARCHAR(64) NOT NULL,
    server_ip VARCHAR(45) NOT NULL,
    check_time DATETIME NOT NULL,
    cpu_usage DECIMAL(5,2),
    memory_usage DECIMAL(5,2),
    disk_usage DECIMAL(5,2),
    status VARCHAR(32),
    note TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
