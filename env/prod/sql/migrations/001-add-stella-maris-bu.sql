-- =============================================================================
-- Migration 001: Add Business Unit "Inst. Agrotécnico Stella Maris"
-- =============================================================================
-- Target database: grext1
-- Organization: Obispado de Cruz del Eje (f780d30d-20a4-4d0a-a2f7-b3a1523eb3d6)
--
-- Apply to running prod:
--   kubectl exec -it rayuela-db-0 -n rayuela -- \
--     psql -U grex -d grext1 -f /sql/001-add-stella-maris-bu.sql
--
-- Safe to re-run (all statements use ON CONFLICT).
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Business Unit: Inst. Agrotécnico Stella Maris
-- -----------------------------------------------------------------------------
INSERT INTO business_units (id, organization_id, name, code, version, cuit)
VALUES (
    '10000000-0000-0000-0002-000000000002',
    'f780d30d-20a4-4d0a-a2f7-b3a1523eb3d6',
    'Inst. Agrotécnico Stella Maris',
    'SMAR',
    0,
    '30608940746'
)
ON CONFLICT (id) DO UPDATE SET
    organization_id = EXCLUDED.organization_id,
    name = EXCLUDED.name,
    code = EXCLUDED.code,
    version = EXCLUDED.version,
    cuit = EXCLUDED.cuit;

-- -----------------------------------------------------------------------------
-- User-Business Unit Associations
-- All existing users assigned to Inst. Agrotécnico Stella Maris
-- -----------------------------------------------------------------------------

-- Maria Cecilia Ghio -> Inst. Agrotécnico Stella Maris
INSERT INTO tenant_user_business_units (tenant_user_id, business_unit_id)
VALUES (
    '10000000-0000-0000-0001-000000000001',
    '10000000-0000-0000-0002-000000000002'
)
ON CONFLICT (tenant_user_id, business_unit_id) DO NOTHING;

-- Sebastian Gonzalez Oyuela -> Inst. Agrotécnico Stella Maris
INSERT INTO tenant_user_business_units (tenant_user_id, business_unit_id)
VALUES (
    '10000000-0000-0000-0001-000000000002',
    '10000000-0000-0000-0002-000000000002'
)
ON CONFLICT (tenant_user_id, business_unit_id) DO NOTHING;

-- Fernanda Ochoa -> Inst. Agrotécnico Stella Maris
INSERT INTO tenant_user_business_units (tenant_user_id, business_unit_id)
VALUES (
    '10000000-0000-0000-0001-000000000003',
    '10000000-0000-0000-0002-000000000002'
)
ON CONFLICT (tenant_user_id, business_unit_id) DO NOTHING;
