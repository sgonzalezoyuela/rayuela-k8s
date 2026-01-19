-- Tenant 2 Database Test Data for Rayuela
-- Inserts two business units for Organization 2

-- Insert Business Unit 1 for Organization 2
-- CUIT: 30-22222221-0 (valid Argentine CUIT for legal entity)
INSERT INTO business_units (id, organization_id, name, code, version, cuit)
VALUES (
    'b2c3d4e5-f6a7-4890-b123-456789012345',
    'df766dc2-6d4c-44d4-90ad-19d9ab69fa9d',
    'Business Unit 2A',
    'BU2A',
    0,
    '30222222210'
)
ON CONFLICT (id) DO UPDATE SET
    organization_id = EXCLUDED.organization_id,
    name = EXCLUDED.name,
    code = EXCLUDED.code,
    version = EXCLUDED.version,
    cuit = EXCLUDED.cuit;

-- Insert Business Unit 2 for Organization 2
-- CUIT: 30-22222222-9 (valid Argentine CUIT for legal entity)
INSERT INTO business_units (id, organization_id, name, code, version, cuit)
VALUES (
    'c3d4e5f6-a7b8-4901-c234-567890123456',
    'df766dc2-6d4c-44d4-90ad-19d9ab69fa9d',
    'Business Unit 2B',
    'BU2B',
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

-- Insert tenant user Carlos Ghio (no business_unit_id in new schema)
INSERT INTO tenant_users (id, email, first_name, last_name, status, version)
VALUES (
    'cccccccc-cccc-4ccc-cccc-cccccccccccc',
    'cghio@grex.com.ar',
    'Carlos',
    'Ghio',
    'ENABLED',
    0
)
ON CONFLICT (email) DO UPDATE SET
    first_name = EXCLUDED.first_name,
    last_name = EXCLUDED.last_name,
    status = EXCLUDED.status,
    version = EXCLUDED.version;

-- Associate Carlos Ghio with Business Unit 2A (using new join table)
INSERT INTO tenant_user_business_units (tenant_user_id, business_unit_id)
VALUES (
    'cccccccc-cccc-4ccc-cccc-cccccccccccc',
    'b2c3d4e5-f6a7-4890-b123-456789012345'
)
ON CONFLICT (tenant_user_id, business_unit_id) DO NOTHING;

-- Associate Carlos Ghio with Business Unit 2B (using new join table)
INSERT INTO tenant_user_business_units (tenant_user_id, business_unit_id)
VALUES (
    'cccccccc-cccc-4ccc-cccc-cccccccccccc',
    'c3d4e5f6-a7b8-4901-c234-567890123456'
)
ON CONFLICT (tenant_user_id, business_unit_id) DO NOTHING;

-- Assign ADMIN role to Carlos Ghio
INSERT INTO tenant_user_roles (tenant_user_id, role_id)
VALUES (
    'cccccccc-cccc-4ccc-cccc-cccccccccccc',
    'aaaaaaaa-aaaa-4aaa-aaaa-aaaaaaaaaaaa'
)
ON CONFLICT (tenant_user_id, role_id) DO NOTHING;
