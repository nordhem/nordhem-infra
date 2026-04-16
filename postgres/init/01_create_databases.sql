-- ─────────────────────────────────────────────────────────────────────────────
-- 01_create_databases.sql
-- Creates Nordhem databases on first Postgres startup
-- ─────────────────────────────────────────────────────────────────────────────

-- Dagster internal metadata store
CREATE DATABASE dagster_state;

-- Nordhem Inc. operational OLTP source system
CREATE DATABASE nordhem_source;
