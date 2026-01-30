-- =============================================================================
-- Production Database - Tenant 1 (grext1) - Obispado de Cruz del Eje
-- =============================================================================
-- Business Unit: Inst. Alberdi - Secundaria
-- Users: 3 admin users with ADMIN role
--
-- IMPORTANT: organization_id must match the tenant ID in application.yml
-- that maps to this database (grext1):
--   f780d30d-20a4-4d0a-a2f7-b3a1523eb3d6
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Business Unit: Inst. Alberdi - Secundaria
-- -----------------------------------------------------------------------------
INSERT INTO business_units (id, organization_id, name, code, version, cuit)
VALUES (
    '10000000-0000-0000-0002-000000000001',
    'f780d30d-20a4-4d0a-a2f7-b3a1523eb3d6',
    'Inst. Alberdi - Secundaria',
    'ALBE',
    0,
    '30593655586'
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
    '10000000-0000-0000-0003-000000000001',
    'ADMIN',
    0
)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    version = EXCLUDED.version;

-- org.all Permission
INSERT INTO permissions (id, name, version)
VALUES (
    '10000000-0000-0000-0004-000000000001',
    'org.all',
    0
)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    version = EXCLUDED.version;

-- Assign org.all permission to ADMIN role
INSERT INTO role_permissions (role_id, permission_id)
VALUES (
    '10000000-0000-0000-0003-000000000001',
    '10000000-0000-0000-0004-000000000001'
)
ON CONFLICT (role_id, permission_id) DO NOTHING;

-- -----------------------------------------------------------------------------
-- Tenant Users (same UUIDs as central users)
-- -----------------------------------------------------------------------------

-- Tenant User 1: Maria Cecilia Ghio
INSERT INTO tenant_users (id, email, first_name, last_name, status, version)
VALUES (
    '10000000-0000-0000-0001-000000000001',
    'ceciliaghio49@gmail.com',
    'Maria Cecilia',
    'Ghio',
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

-- Tenant User 3: Fernanda Ochoa
INSERT INTO tenant_users (id, email, first_name, last_name, status, version)
VALUES (
    '10000000-0000-0000-0001-000000000003',
    'cra.ochoafernanda84@gmail.com',
    'Fernanda',
    'Ochoa',
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
-- All users associated with Inst. Alberdi - Secundaria
-- -----------------------------------------------------------------------------

-- Maria Cecilia Ghio -> Inst. Alberdi - Secundaria
INSERT INTO tenant_user_business_units (tenant_user_id, business_unit_id)
VALUES (
    '10000000-0000-0000-0001-000000000001',
    '10000000-0000-0000-0002-000000000001'
)
ON CONFLICT (tenant_user_id, business_unit_id) DO NOTHING;

-- Sebastian Gonzalez Oyuela -> Inst. Alberdi - Secundaria
INSERT INTO tenant_user_business_units (tenant_user_id, business_unit_id)
VALUES (
    '10000000-0000-0000-0001-000000000002',
    '10000000-0000-0000-0002-000000000001'
)
ON CONFLICT (tenant_user_id, business_unit_id) DO NOTHING;

-- Fernanda Ochoa -> Inst. Alberdi - Secundaria
INSERT INTO tenant_user_business_units (tenant_user_id, business_unit_id)
VALUES (
    '10000000-0000-0000-0001-000000000003',
    '10000000-0000-0000-0002-000000000001'
)
ON CONFLICT (tenant_user_id, business_unit_id) DO NOTHING;

-- -----------------------------------------------------------------------------
-- User-Role Assignments
-- All users assigned ADMIN role
-- -----------------------------------------------------------------------------

-- Maria Cecilia Ghio -> ADMIN
INSERT INTO tenant_user_roles (tenant_user_id, role_id)
VALUES (
    '10000000-0000-0000-0001-000000000001',
    '10000000-0000-0000-0003-000000000001'
)
ON CONFLICT (tenant_user_id, role_id) DO NOTHING;

-- Sebastian Gonzalez Oyuela -> ADMIN
INSERT INTO tenant_user_roles (tenant_user_id, role_id)
VALUES (
    '10000000-0000-0000-0001-000000000002',
    '10000000-0000-0000-0003-000000000001'
)
ON CONFLICT (tenant_user_id, role_id) DO NOTHING;

-- Fernanda Ochoa -> ADMIN
INSERT INTO tenant_user_roles (tenant_user_id, role_id)
VALUES (
    '10000000-0000-0000-0001-000000000003',
    '10000000-0000-0000-0003-000000000001'
)
ON CONFLICT (tenant_user_id, role_id) DO NOTHING;
