-- Tenant 1 Database Test Data for Rayuela
-- Inserts 5 business units for Organization 1:
--   - 4 for Instituto Brizuela (Jardín, Primaria, Secundaria, Superior)
--   - 1 for Instituto Alberdi (Secundaria)

-- Insert Business Unit: Inst. Brizuela - Jardín for Organization 1
INSERT INTO business_units (id, organization_id, name, code, version, cuit)
VALUES (
    'a1b2c3d4-e5f6-4789-a012-345678901111',
    'f780d30d-20a4-4d0a-a2f7-b3a1523eb3d6',
    'Inst. Brizuela - Jardín',
    'BRIZJ',
    0,
    '30111111118'
)
ON CONFLICT (id) DO UPDATE SET
    organization_id = EXCLUDED.organization_id,
    name = EXCLUDED.name,
    code = EXCLUDED.code,
    version = EXCLUDED.version,
    cuit = EXCLUDED.cuit;

-- Insert Business Unit: Inst. Brizuela - Primaria for Organization 1
INSERT INTO business_units (id, organization_id, name, code, version, cuit)
VALUES (
    'a1b2c3d4-e5f6-4789-a012-345678902222',
    'f780d30d-20a4-4d0a-a2f7-b3a1523eb3d6',
    'Inst. Brizuela - Primaria',
    'BRIZP',
    0,
    '30111111118'
)
ON CONFLICT (id) DO UPDATE SET
    organization_id = EXCLUDED.organization_id,
    name = EXCLUDED.name,
    code = EXCLUDED.code,
    version = EXCLUDED.version,
    cuit = EXCLUDED.cuit;

-- Insert Business Unit: Inst. Brizuela - Secundaria for Organization 1
INSERT INTO business_units (id, organization_id, name, code, version, cuit)
VALUES (
    'a1b2c3d4-e5f6-4789-a012-345678903333',
    'f780d30d-20a4-4d0a-a2f7-b3a1523eb3d6',
    'Inst. Brizuela - Secundaria',
    'BRIZS',
    0,
    '30111111118'
)
ON CONFLICT (id) DO UPDATE SET
    organization_id = EXCLUDED.organization_id,
    name = EXCLUDED.name,
    code = EXCLUDED.code,
    version = EXCLUDED.version,
    cuit = EXCLUDED.cuit;

-- Insert Business Unit: Inst. Brizuela - Superior for Organization 1
INSERT INTO business_units (id, organization_id, name, code, version, cuit)
VALUES (
    'a1b2c3d4-e5f6-4789-a012-345678904444',
    'f780d30d-20a4-4d0a-a2f7-b3a1523eb3d6',
    'Inst. Brizuela - Superior',
    'BRIZSU',
    0,
    '30111111118'
)
ON CONFLICT (id) DO UPDATE SET
    organization_id = EXCLUDED.organization_id,
    name = EXCLUDED.name,
    code = EXCLUDED.code,
    version = EXCLUDED.version,
    cuit = EXCLUDED.cuit;

-- Insert Business Unit: Inst. Alberdi - Secundaria for Organization 1
INSERT INTO business_units (id, organization_id, name, code, version, cuit)
VALUES (
    'b2c3d4e5-f6a7-4890-b123-456789012345',
    'f780d30d-20a4-4d0a-a2f7-b3a1523eb3d6',
    'Inst. Alberdi - Secundaria',
    'ALBE',
    0,
    '30222222229'
)
ON CONFLICT (id) DO UPDATE SET
    organization_id = EXCLUDED.organization_id,
    name = EXCLUDED.name,
    code = EXCLUDED.code,
    version = EXCLUDED.version,
    cuit = EXCLUDED.cuit;

-- Insert ADMIN role
INSERT INTO roles (id, name, version)
VALUES (
    'aaaaaaaa-aaaa-4aaa-aaaa-aaaaaaaaaaaa',
    'ADMIN',
    0
)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    version = EXCLUDED.version;

-- Insert org.all permission
INSERT INTO permissions (id, name, version)
VALUES (
    'bbbbbbbb-bbbb-4bbb-bbbb-bbbbbbbbbbbb',
    'org.all',
    0
)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    version = EXCLUDED.version;

-- Assign org.all permission to ADMIN role
INSERT INTO role_permissions (role_id, permission_id)
VALUES (
    'aaaaaaaa-aaaa-4aaa-aaaa-aaaaaaaaaaaa',
    'bbbbbbbb-bbbb-4bbb-bbbb-bbbbbbbbbbbb'
)
ON CONFLICT (role_id, permission_id) DO NOTHING;

-- Insert tenant user Cecilia Ghio
INSERT INTO tenant_users (id, email, first_name, last_name, status, version)
VALUES (
    'cccccccc-cccc-4ccc-cccc-cccccccccccc',
    'cghio@grex.com.ar',
    'Cecilia',
    'Ghio',
    'ENABLED',
    0
)
ON CONFLICT (email) DO UPDATE SET
    first_name = EXCLUDED.first_name,
    last_name = EXCLUDED.last_name,
    status = EXCLUDED.status,
    version = EXCLUDED.version;

-- Associate Cecilia Ghio with Inst. Brizuela - Jardín
INSERT INTO tenant_user_business_units (tenant_user_id, business_unit_id)
VALUES (
    'cccccccc-cccc-4ccc-cccc-cccccccccccc',
    'a1b2c3d4-e5f6-4789-a012-345678901111'
)
ON CONFLICT (tenant_user_id, business_unit_id) DO NOTHING;

-- Associate Cecilia Ghio with Inst. Brizuela - Primaria
INSERT INTO tenant_user_business_units (tenant_user_id, business_unit_id)
VALUES (
    'cccccccc-cccc-4ccc-cccc-cccccccccccc',
    'a1b2c3d4-e5f6-4789-a012-345678902222'
)
ON CONFLICT (tenant_user_id, business_unit_id) DO NOTHING;

-- Associate Cecilia Ghio with Inst. Brizuela - Secundaria
INSERT INTO tenant_user_business_units (tenant_user_id, business_unit_id)
VALUES (
    'cccccccc-cccc-4ccc-cccc-cccccccccccc',
    'a1b2c3d4-e5f6-4789-a012-345678903333'
)
ON CONFLICT (tenant_user_id, business_unit_id) DO NOTHING;

-- Associate Cecilia Ghio with Inst. Brizuela - Superior
INSERT INTO tenant_user_business_units (tenant_user_id, business_unit_id)
VALUES (
    'cccccccc-cccc-4ccc-cccc-cccccccccccc',
    'a1b2c3d4-e5f6-4789-a012-345678904444'
)
ON CONFLICT (tenant_user_id, business_unit_id) DO NOTHING;

-- Associate Cecilia Ghio with Inst. Alberdi - Secundaria
INSERT INTO tenant_user_business_units (tenant_user_id, business_unit_id)
VALUES (
    'cccccccc-cccc-4ccc-cccc-cccccccccccc',
    'b2c3d4e5-f6a7-4890-b123-456789012345'
)
ON CONFLICT (tenant_user_id, business_unit_id) DO NOTHING;

-- Assign ADMIN role to Cecilia Ghio
INSERT INTO tenant_user_roles (tenant_user_id, role_id)
VALUES (
    'cccccccc-cccc-4ccc-cccc-cccccccccccc',
    'aaaaaaaa-aaaa-4aaa-aaaa-aaaaaaaaaaaa'
)
ON CONFLICT (tenant_user_id, role_id) DO NOTHING;
