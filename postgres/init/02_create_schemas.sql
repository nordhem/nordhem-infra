-- ─────────────────────────────────────────────────────────────────────────────
-- 02_create_schemas.sql
-- Creates schemas inside nordhem_source
-- ─────────────────────────────────────────────────────────────────────────────

\connect nordhem_source

-- Shared reference data — no tenant_id, industry-standard codes
CREATE SCHEMA IF NOT EXISTS reference;

-- Tenant-owned transactional data — every table has tenant_id
CREATE SCHEMA IF NOT EXISTS operational;
