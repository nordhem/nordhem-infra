-- ─────────────────────────────────────────────────────────────────────────────
-- 03_nordhem_source_ddl.sql
-- Full DDL for nordhem_source — reference and operational schemas
-- All operational tables follow these standards:
--   - UUID primary keys (gen_random_uuid())
--   - tenant_id on every operational table
--   - created_at, updated_at audit columns
--   - is_deleted soft delete flag
--   - Indexes on tenant_id and all foreign keys
-- ─────────────────────────────────────────────────────────────────────────────

\connect nordhem_source

-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ─────────────────────────────────────────────────────────────────────────────
-- REFERENCE SCHEMA — shared, no tenant_id
-- ─────────────────────────────────────────────────────────────────────────────

-- ICD-10 diagnosis codes
CREATE TABLE IF NOT EXISTS reference.diagnoses (
    diagnosis_code      VARCHAR(20) PRIMARY KEY,
    description         VARCHAR(500) NOT NULL,
    category            VARCHAR(100),
    created_at          TIMESTAMP NOT NULL DEFAULT now()
);

-- CPT procedure codes
CREATE TABLE IF NOT EXISTS reference.procedure_codes (
    procedure_code      VARCHAR(20) PRIMARY KEY,
    description         VARCHAR(500) NOT NULL,
    category            VARCHAR(100),
    created_at          TIMESTAMP NOT NULL DEFAULT now()
);

-- Benefit plan type definitions
CREATE TABLE IF NOT EXISTS reference.plan_types (
    plan_type_code      VARCHAR(20) PRIMARY KEY,
    plan_type_name      VARCHAR(100) NOT NULL,
    description         VARCHAR(500),
    created_at          TIMESTAMP NOT NULL DEFAULT now()
);

-- NPI master provider directory
CREATE TABLE IF NOT EXISTS reference.providers (
    provider_npi        VARCHAR(20) PRIMARY KEY,
    provider_name       VARCHAR(255) NOT NULL,
    provider_type       VARCHAR(100),
    specialty           VARCHAR(255),
    address_line_1      VARCHAR(255),
    address_line_2      VARCHAR(255),
    city                VARCHAR(100),
    state               VARCHAR(50),
    zip_code            VARCHAR(20),
    phone               VARCHAR(20),
    created_at          TIMESTAMP NOT NULL DEFAULT now(),
    updated_at          TIMESTAMP NOT NULL DEFAULT now()
);

-- ─────────────────────────────────────────────────────────────────────────────
-- OPERATIONAL SCHEMA — tenant-owned, every table has tenant_id
-- ─────────────────────────────────────────────────────────────────────────────

-- Root tenant registry
CREATE TABLE IF NOT EXISTS operational.tenants (
    tenant_id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_code         VARCHAR(100) UNIQUE NOT NULL,
    tenant_name         VARCHAR(255) NOT NULL,
    is_active           BOOLEAN NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMP NOT NULL DEFAULT now(),
    updated_at          TIMESTAMP NOT NULL DEFAULT now(),
    is_deleted          BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE INDEX IF NOT EXISTS idx_tenants_tenant_code ON operational.tenants(tenant_code);

-- Employers — companies purchasing benefits from Nordhem Inc.
CREATE TABLE IF NOT EXISTS operational.employers (
    employer_id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id           UUID NOT NULL REFERENCES operational.tenants(tenant_id),
    employer_name       VARCHAR(255) NOT NULL,
    industry_code       VARCHAR(20),
    employee_count      INTEGER,
    state               VARCHAR(50),
    city                VARCHAR(100),
    zip_code            VARCHAR(20),
    effective_date      DATE NOT NULL,
    termination_date    DATE,
    is_active           BOOLEAN NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMP NOT NULL DEFAULT now(),
    updated_at          TIMESTAMP NOT NULL DEFAULT now(),
    is_deleted          BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE INDEX IF NOT EXISTS idx_employers_tenant_id ON operational.employers(tenant_id);
CREATE INDEX IF NOT EXISTS idx_employers_tenant_active ON operational.employers(tenant_id, is_active);

-- Members — employees enrolled in benefit plans
CREATE TABLE IF NOT EXISTS operational.members (
    member_id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id           UUID NOT NULL REFERENCES operational.tenants(tenant_id),
    employer_id         UUID NOT NULL REFERENCES operational.employers(employer_id),
    external_id         VARCHAR(100),
    first_name          VARCHAR(100) NOT NULL,
    middle_name         VARCHAR(100),
    last_name           VARCHAR(100) NOT NULL,
    date_of_birth       DATE NOT NULL,
    gender              VARCHAR(20),
    race                VARCHAR(50),
    ethnicity           VARCHAR(50),
    marital_status      VARCHAR(20),
    is_active           BOOLEAN NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMP NOT NULL DEFAULT now(),
    updated_at          TIMESTAMP NOT NULL DEFAULT now(),
    is_deleted          BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE INDEX IF NOT EXISTS idx_members_tenant_id ON operational.members(tenant_id);
CREATE INDEX IF NOT EXISTS idx_members_employer_id ON operational.members(employer_id);
CREATE INDEX IF NOT EXISTS idx_members_tenant_employer ON operational.members(tenant_id, employer_id);
CREATE INDEX IF NOT EXISTS idx_members_external_id ON operational.members(tenant_id, external_id);

-- Member contact details — kept narrow and separate
CREATE TABLE IF NOT EXISTS operational.member_contact (
    contact_id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id           UUID NOT NULL REFERENCES operational.tenants(tenant_id),
    member_id           UUID NOT NULL REFERENCES operational.members(member_id),
    address_line_1      VARCHAR(255),
    address_line_2      VARCHAR(255),
    city                VARCHAR(100),
    state               VARCHAR(50),
    county              VARCHAR(100),
    zip_code            VARCHAR(20),
    latitude            NUMERIC(10, 7),
    longitude           NUMERIC(10, 7),
    email               VARCHAR(255),
    phone               VARCHAR(20),
    effective_date      DATE NOT NULL DEFAULT CURRENT_DATE,
    end_date            DATE,
    created_at          TIMESTAMP NOT NULL DEFAULT now(),
    updated_at          TIMESTAMP NOT NULL DEFAULT now(),
    is_deleted          BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE INDEX IF NOT EXISTS idx_member_contact_tenant_id ON operational.member_contact(tenant_id);
CREATE INDEX IF NOT EXISTS idx_member_contact_member_id ON operational.member_contact(member_id);

-- Member status history — state changes over time
CREATE TABLE IF NOT EXISTS operational.member_status_history (
    status_id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id           UUID NOT NULL REFERENCES operational.tenants(tenant_id),
    member_id           UUID NOT NULL REFERENCES operational.members(member_id),
    status              VARCHAR(50) NOT NULL,
    effective_date      DATE NOT NULL,
    end_date            DATE,
    reason              VARCHAR(255),
    created_at          TIMESTAMP NOT NULL DEFAULT now(),
    updated_at          TIMESTAMP NOT NULL DEFAULT now(),
    is_deleted          BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE INDEX IF NOT EXISTS idx_member_status_tenant_id ON operational.member_status_history(tenant_id);
CREATE INDEX IF NOT EXISTS idx_member_status_member_id ON operational.member_status_history(member_id);

-- Plans — benefit plan definitions
CREATE TABLE IF NOT EXISTS operational.plans (
    plan_id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id           UUID NOT NULL REFERENCES operational.tenants(tenant_id),
    plan_code           VARCHAR(100) NOT NULL,
    plan_name           VARCHAR(255) NOT NULL,
    plan_type_code      VARCHAR(20) REFERENCES reference.plan_types(plan_type_code),
    payer_name          VARCHAR(255),
    ownership_type      VARCHAR(50),
    effective_date      DATE NOT NULL,
    termination_date    DATE,
    is_active           BOOLEAN NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMP NOT NULL DEFAULT now(),
    updated_at          TIMESTAMP NOT NULL DEFAULT now(),
    is_deleted          BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE INDEX IF NOT EXISTS idx_plans_tenant_id ON operational.plans(tenant_id);
CREATE INDEX IF NOT EXISTS idx_plans_tenant_active ON operational.plans(tenant_id, is_active);

-- Policies — employer to plan associations
CREATE TABLE IF NOT EXISTS operational.policies (
    policy_id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id           UUID NOT NULL REFERENCES operational.tenants(tenant_id),
    employer_id         UUID NOT NULL REFERENCES operational.employers(employer_id),
    plan_id             UUID NOT NULL REFERENCES operational.plans(plan_id),
    policy_number       VARCHAR(100),
    effective_date      DATE NOT NULL,
    termination_date    DATE,
    is_active           BOOLEAN NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMP NOT NULL DEFAULT now(),
    updated_at          TIMESTAMP NOT NULL DEFAULT now(),
    is_deleted          BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE INDEX IF NOT EXISTS idx_policies_tenant_id ON operational.policies(tenant_id);
CREATE INDEX IF NOT EXISTS idx_policies_employer_id ON operational.policies(employer_id);
CREATE INDEX IF NOT EXISTS idx_policies_plan_id ON operational.policies(plan_id);

-- Provider networks — tenant-specific provider associations
CREATE TABLE IF NOT EXISTS operational.provider_networks (
    network_id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id           UUID NOT NULL REFERENCES operational.tenants(tenant_id),
    provider_npi        VARCHAR(20) REFERENCES reference.providers(provider_npi),
    network_name        VARCHAR(255) NOT NULL,
    effective_date      DATE NOT NULL,
    end_date            DATE,
    is_active           BOOLEAN NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMP NOT NULL DEFAULT now(),
    updated_at          TIMESTAMP NOT NULL DEFAULT now(),
    is_deleted          BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE INDEX IF NOT EXISTS idx_provider_networks_tenant_id ON operational.provider_networks(tenant_id);
CREATE INDEX IF NOT EXISTS idx_provider_networks_npi ON operational.provider_networks(provider_npi);

-- Enrollments — member enrollment history per plan
CREATE TABLE IF NOT EXISTS operational.enrollments (
    enrollment_id       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id           UUID NOT NULL REFERENCES operational.tenants(tenant_id),
    member_id           UUID NOT NULL REFERENCES operational.members(member_id),
    plan_id             UUID NOT NULL REFERENCES operational.plans(plan_id),
    policy_id           UUID NOT NULL REFERENCES operational.policies(policy_id),
    enrollment_date     DATE NOT NULL,
    termination_date    DATE,
    enrollment_status   VARCHAR(50) NOT NULL,
    monthly_premium     NUMERIC(12, 2),
    is_active           BOOLEAN NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMP NOT NULL DEFAULT now(),
    updated_at          TIMESTAMP NOT NULL DEFAULT now(),
    is_deleted          BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE INDEX IF NOT EXISTS idx_enrollments_tenant_id ON operational.enrollments(tenant_id);
CREATE INDEX IF NOT EXISTS idx_enrollments_member_id ON operational.enrollments(member_id);
CREATE INDEX IF NOT EXISTS idx_enrollments_plan_id ON operational.enrollments(plan_id);
CREATE INDEX IF NOT EXISTS idx_enrollments_tenant_member ON operational.enrollments(tenant_id, member_id);

-- Claims — medical claims submitted by members
CREATE TABLE IF NOT EXISTS operational.claims (
    claim_id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id           UUID NOT NULL REFERENCES operational.tenants(tenant_id),
    member_id           UUID NOT NULL REFERENCES operational.members(member_id),
    provider_npi        VARCHAR(20) REFERENCES reference.providers(provider_npi),
    plan_id             UUID REFERENCES operational.plans(plan_id),
    external_claim_id   VARCHAR(100),
    claim_type          VARCHAR(50),
    service_date        DATE NOT NULL,
    submitted_date      DATE,
    adjudicated_date    DATE,
    claim_status        VARCHAR(50) NOT NULL,
    total_charge        NUMERIC(12, 2),
    allowed_amount      NUMERIC(12, 2),
    paid_amount         NUMERIC(12, 2),
    patient_responsibility NUMERIC(12, 2),
    primary_diagnosis_code VARCHAR(20) REFERENCES reference.diagnoses(diagnosis_code),
    created_at          TIMESTAMP NOT NULL DEFAULT now(),
    updated_at          TIMESTAMP NOT NULL DEFAULT now(),
    is_deleted          BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE INDEX IF NOT EXISTS idx_claims_tenant_id ON operational.claims(tenant_id);
CREATE INDEX IF NOT EXISTS idx_claims_member_id ON operational.claims(member_id);
CREATE INDEX IF NOT EXISTS idx_claims_service_date ON operational.claims(tenant_id, service_date);
CREATE INDEX IF NOT EXISTS idx_claims_tenant_member ON operational.claims(tenant_id, member_id);
CREATE INDEX IF NOT EXISTS idx_claims_status ON operational.claims(tenant_id, claim_status);

-- Claim lines — line items within each claim
CREATE TABLE IF NOT EXISTS operational.claim_lines (
    claim_line_id       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id           UUID NOT NULL REFERENCES operational.tenants(tenant_id),
    claim_id            UUID NOT NULL REFERENCES operational.claims(claim_id),
    line_number         INTEGER NOT NULL,
    service_date        DATE NOT NULL,
    procedure_code      VARCHAR(20) REFERENCES reference.procedure_codes(procedure_code),
    diagnosis_code      VARCHAR(20) REFERENCES reference.diagnoses(diagnosis_code),
    quantity            NUMERIC(10, 2),
    unit_cost           NUMERIC(12, 2),
    charge_amount       NUMERIC(12, 2),
    allowed_amount      NUMERIC(12, 2),
    paid_amount         NUMERIC(12, 2),
    line_status         VARCHAR(50),
    description         VARCHAR(500),
    created_at          TIMESTAMP NOT NULL DEFAULT now(),
    updated_at          TIMESTAMP NOT NULL DEFAULT now(),
    is_deleted          BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE INDEX IF NOT EXISTS idx_claim_lines_tenant_id ON operational.claim_lines(tenant_id);
CREATE INDEX IF NOT EXISTS idx_claim_lines_claim_id ON operational.claim_lines(claim_id);
CREATE INDEX IF NOT EXISTS idx_claim_lines_tenant_claim ON operational.claim_lines(tenant_id, claim_id);

-- ─────────────────────────────────────────────────────────────────────────────
-- ROW LEVEL SECURITY — tenant isolation at database level
-- ─────────────────────────────────────────────────────────────────────────────

ALTER TABLE operational.employers ENABLE ROW LEVEL SECURITY;
ALTER TABLE operational.members ENABLE ROW LEVEL SECURITY;
ALTER TABLE operational.member_contact ENABLE ROW LEVEL SECURITY;
ALTER TABLE operational.member_status_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE operational.plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE operational.policies ENABLE ROW LEVEL SECURITY;
ALTER TABLE operational.provider_networks ENABLE ROW LEVEL SECURITY;
ALTER TABLE operational.enrollments ENABLE ROW LEVEL SECURITY;
ALTER TABLE operational.claims ENABLE ROW LEVEL SECURITY;
ALTER TABLE operational.claim_lines ENABLE ROW LEVEL SECURITY;
