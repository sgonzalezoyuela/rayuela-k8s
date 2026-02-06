-- =============================================================================
-- Development Database - Tenant 1 (grext1)
-- =============================================================================
-- TODO: Replace placeholder data with actual dev environment data.
--
-- organization_id must match the tenant ID in application.yml
-- that maps to this database (grext1):
--   f780d30d-20a4-4d0a-a2f7-b3a1523eb3d6
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Business Unit
-- -----------------------------------------------------------------------------
INSERT INTO business_units (id, organization_id, name, code, version, cuit)
VALUES (
    '20000000-0000-0000-0002-000000000001',
    'f780d30d-20a4-4d0a-a2f7-b3a1523eb3d6',
    'Inst. Alberdi - Secundaria',
    'ALBE',
    0,
    '33709409579'
)
ON CONFLICT (id) DO UPDATE SET
    organization_id = EXCLUDED.organization_id,
    name = EXCLUDED.name,
    code = EXCLUDED.code,
    version = EXCLUDED.version,
    cuit = EXCLUDED.cuit;

-- -----------------------------------------------------------------------------
-- RBAC: Role and Permission
-- -----------------------------------------------------------------------------

-- ADMIN Role
INSERT INTO roles (id, name, version)
VALUES (
    '20000000-0000-0000-0003-000000000001',
    'ADMIN',
    0
)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    version = EXCLUDED.version;

-- org.all Permission
INSERT INTO permissions (id, name, version)
VALUES (
    '20000000-0000-0000-0004-000000000001',
    'org.all',
    0
)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    version = EXCLUDED.version;

-- Assign org.all permission to ADMIN role
INSERT INTO role_permissions (role_id, permission_id)
VALUES (
    '20000000-0000-0000-0003-000000000001',
    '20000000-0000-0000-0004-000000000001'
)
ON CONFLICT (role_id, permission_id) DO NOTHING;

-- -----------------------------------------------------------------------------
-- Tenant Users (same UUIDs as central users)
-- -----------------------------------------------------------------------------

-- Dev Tenant User 1
INSERT INTO tenant_users (id, email, first_name, last_name, status, version)
VALUES (
    '20000000-0000-0000-0001-000000000001',
    'dev-user1@example.com',
    'Dev',
    'User One',
    'ENABLED',
    0
)
ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    first_name = EXCLUDED.first_name,
    last_name = EXCLUDED.last_name,
    status = EXCLUDED.status,
    version = EXCLUDED.version;

-- Tenant User 2: Sebastian Gonzalez Oyuela
INSERT INTO tenant_users (id, email, first_name, last_name, status, version)
VALUES (
    '10000000-0000-0000-0001-000000000002',
    'sgonzalezoyuela@gmail.com',
    'Sebastian',
    'Gonzalez Oyuela',
    'ENABLED',
    0
)
ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    first_name = EXCLUDED.first_name,
    last_name = EXCLUDED.last_name,
    status = EXCLUDED.status,
    version = EXCLUDED.version;

-- -----------------------------------------------------------------------------
-- User-Business Unit Associations
-- -----------------------------------------------------------------------------

-- Dev User 1 -> Dev Business Unit 1
INSERT INTO tenant_user_business_units (tenant_user_id, business_unit_id)
VALUES (
    '20000000-0000-0000-0001-000000000001',
    '20000000-0000-0000-0002-000000000001'
)
ON CONFLICT (tenant_user_id, business_unit_id) DO NOTHING;

-- Sebastian Gonzalez Oyuela -> Dev Business Unit 1
INSERT INTO tenant_user_business_units (tenant_user_id, business_unit_id)
VALUES (
    '10000000-0000-0000-0001-000000000002',
    '20000000-0000-0000-0002-000000000001'
)
ON CONFLICT (tenant_user_id, business_unit_id) DO NOTHING;

-- -----------------------------------------------------------------------------
-- User-Role Assignments
-- -----------------------------------------------------------------------------

-- Dev User 1 -> ADMIN
INSERT INTO tenant_user_roles (tenant_user_id, role_id)
VALUES (
    '20000000-0000-0000-0001-000000000001',
    '20000000-0000-0000-0003-000000000001'
)
ON CONFLICT (tenant_user_id, role_id) DO NOTHING;

-- Sebastian Gonzalez Oyuela -> ADMIN
INSERT INTO tenant_user_roles (tenant_user_id, role_id)
VALUES (
    '10000000-0000-0000-0001-000000000002',
    '20000000-0000-0000-0003-000000000001'
)
ON CONFLICT (tenant_user_id, role_id) DO NOTHING;
