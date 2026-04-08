-- =============================================================================
-- Development Seed Data - Public Schema (rayuela database)
-- =============================================================================
-- Two organizations for development/testing
-- =============================================================================

SET search_path = 'public';

-- -----------------------------------------------------------------------------
-- Organization 1
-- schema_name links to the tenant schema for this organization
-- -----------------------------------------------------------------------------
INSERT INTO organizations (id, name, cuit, status, schema_name, version)
VALUES (
    'f780d30d-20a4-4d0a-a2f7-b3a1523eb3d6',
    'Dev Organization 1',
    '30000000007',
    'ACTIVA',
    'tenant_f780d30d-20a4-4d0a-a2f7-b3a1523eb3d6',
    0
)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    cuit = EXCLUDED.cuit,
    status = EXCLUDED.status,
    schema_name = EXCLUDED.schema_name,
    version = EXCLUDED.version;

-- -----------------------------------------------------------------------------
-- Organization 2
-- schema_name links to the tenant schema for this organization
-- -----------------------------------------------------------------------------
INSERT INTO organizations (id, name, cuit, status, schema_name, version)
VALUES (
    'df766dc2-6d4c-44d4-90ad-19d9ab69fa9d',
    'Dev Organization 2',
    '30000000015',
    'ACTIVA',
    'tenant_df766dc2-6d4c-44d4-90ad-19d9ab69fa9d',
    0
)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    cuit = EXCLUDED.cuit,
    status = EXCLUDED.status,
    schema_name = EXCLUDED.schema_name,
    version = EXCLUDED.version;

-- -----------------------------------------------------------------------------
-- Users
-- -----------------------------------------------------------------------------

-- Dev User 1
INSERT INTO users (id, email, first_name, last_name, status, version)
VALUES (
    '20000000-0000-0000-0001-000000000001',
    'dev-user1@example.com',
    'Dev',
    'User One',
    'HABILITADO',
    0
)
ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    first_name = EXCLUDED.first_name,
    last_name = EXCLUDED.last_name,
    status = EXCLUDED.status,
    version = EXCLUDED.version;

-- User 2: Sebastian Gonzalez Oyuela
INSERT INTO users (id, email, first_name, last_name, status, version)
VALUES (
    '10000000-0000-0000-0001-000000000002',
    'sgonzalezoyuela@gmail.com',
    'Sebastian',
    'Gonzalez Oyuela',
    'HABILITADO',
    0
)
ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    first_name = EXCLUDED.first_name,
    last_name = EXCLUDED.last_name,
    status = EXCLUDED.status,
    version = EXCLUDED.version;

-- User 3: Maria Cecilia Ghio
INSERT INTO users (id, email, first_name, last_name, status, version)
VALUES (
    '10000000-0000-0000-0001-000000000001',
    'ceciliaghio49@gmail.com',
    'Maria Cecilia',
    'Ghio',
    'HABILITADO',
    0
)
ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    first_name = EXCLUDED.first_name,
    last_name = EXCLUDED.last_name,
    status = EXCLUDED.status,
    version = EXCLUDED.version;

-- User 4: Fernanda Ochoa
INSERT INTO users (id, email, first_name, last_name, status, version)
VALUES (
    '10000000-0000-0000-0001-000000000003',
    'cra.ochoafernanda84@gmail.com',
    'Fernanda',
    'Ochoa',
    'HABILITADO',
    0
)
ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    first_name = EXCLUDED.first_name,
    last_name = EXCLUDED.last_name,
    status = EXCLUDED.status,
    version = EXCLUDED.version;

-- -----------------------------------------------------------------------------
-- User-Organization Assignments
-- -----------------------------------------------------------------------------

-- Dev User 1 -> Dev Organization 1
INSERT INTO user_org_assignments (id, user_id, organization_id, version)
VALUES (
    '20000000-0000-0000-0005-000000000001',
    '20000000-0000-0000-0001-000000000001',
    'f780d30d-20a4-4d0a-a2f7-b3a1523eb3d6',
    0
)
ON CONFLICT (user_id, organization_id) DO UPDATE SET
    version = EXCLUDED.version;

-- Sebastian Gonzalez Oyuela -> Dev Organization 1
INSERT INTO user_org_assignments (id, user_id, organization_id, version)
VALUES (
    '20000000-0000-0000-0005-000000000010',
    '10000000-0000-0000-0001-000000000002',
    'f780d30d-20a4-4d0a-a2f7-b3a1523eb3d6',
    0
)
ON CONFLICT (user_id, organization_id) DO UPDATE SET
    version = EXCLUDED.version;

-- Sebastian Gonzalez Oyuela -> Dev Organization 2
INSERT INTO user_org_assignments (id, user_id, organization_id, version)
VALUES (
    '20000000-0000-0000-0005-000000000011',
    '10000000-0000-0000-0001-000000000002',
    'df766dc2-6d4c-44d4-90ad-19d9ab69fa9d',
    0
)
ON CONFLICT (user_id, organization_id) DO UPDATE SET
    version = EXCLUDED.version;

-- Maria Cecilia Ghio -> Dev Organization 1
INSERT INTO user_org_assignments (id, user_id, organization_id, version)
VALUES (
    '20000000-0000-0000-0005-000000000020',
    '10000000-0000-0000-0001-000000000001',
    'f780d30d-20a4-4d0a-a2f7-b3a1523eb3d6',
    0
)
ON CONFLICT (user_id, organization_id) DO UPDATE SET
    version = EXCLUDED.version;

-- Maria Cecilia Ghio -> Dev Organization 2
INSERT INTO user_org_assignments (id, user_id, organization_id, version)
VALUES (
    '20000000-0000-0000-0005-000000000021',
    '10000000-0000-0000-0001-000000000001',
    'df766dc2-6d4c-44d4-90ad-19d9ab69fa9d',
    0
)
ON CONFLICT (user_id, organization_id) DO UPDATE SET
    version = EXCLUDED.version;

-- Fernanda Ochoa -> Dev Organization 1
INSERT INTO user_org_assignments (id, user_id, organization_id, version)
VALUES (
    '20000000-0000-0000-0005-000000000030',
    '10000000-0000-0000-0001-000000000003',
    'f780d30d-20a4-4d0a-a2f7-b3a1523eb3d6',
    0
)
ON CONFLICT (user_id, organization_id) DO UPDATE SET
    version = EXCLUDED.version;

-- Fernanda Ochoa -> Dev Organization 2
INSERT INTO user_org_assignments (id, user_id, organization_id, version)
VALUES (
    '20000000-0000-0000-0005-000000000031',
    '10000000-0000-0000-0001-000000000003',
    'df766dc2-6d4c-44d4-90ad-19d9ab69fa9d',
    0
)
ON CONFLICT (user_id, organization_id) DO UPDATE SET
    version = EXCLUDED.version;
