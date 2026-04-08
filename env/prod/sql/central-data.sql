-- =============================================================================
-- Production Seed Data - Public Schema (rayuela database)
-- =============================================================================
-- Organization: Obispado de Cruz del Eje
-- Users: 3 admin users with full access
-- =============================================================================

SET search_path = 'public';

-- -----------------------------------------------------------------------------
-- Organization: Obispado de Cruz del Eje
-- schema_name links to the tenant schema for this organization
-- -----------------------------------------------------------------------------
INSERT INTO organizations (id, name, cuit, status, schema_name, version)
VALUES (
    'f780d30d-20a4-4d0a-a2f7-b3a1523eb3d6',
    'Obispado de Cruz del Eje',
    '30593655586',
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
-- Users
-- -----------------------------------------------------------------------------

-- User 1: Maria Cecilia Ghio
INSERT INTO users (id, email, first_name, last_name, status, version)
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

-- User 2: Sebastian Gonzalez Oyuela
INSERT INTO users (id, email, first_name, last_name, status, version)
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

-- User 3: Fernanda Ochoa
INSERT INTO users (id, email, first_name, last_name, status, version)
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
-- User-Organization Assignments
-- All users assigned to Obispado de Cruz del Eje
-- -----------------------------------------------------------------------------

-- Assignment 1: Maria Cecilia Ghio -> Obispado de Cruz del Eje
INSERT INTO user_org_assignments (id, user_id, organization_id, version)
VALUES (
    '10000000-0000-0000-0005-000000000001',
    '10000000-0000-0000-0001-000000000001',
    'f780d30d-20a4-4d0a-a2f7-b3a1523eb3d6',
    0
)
ON CONFLICT (user_id, organization_id) DO UPDATE SET
    version = EXCLUDED.version;

-- Assignment 2: Sebastian Gonzalez Oyuela -> Obispado de Cruz del Eje
INSERT INTO user_org_assignments (id, user_id, organization_id, version)
VALUES (
    '10000000-0000-0000-0005-000000000002',
    '10000000-0000-0000-0001-000000000002',
    'f780d30d-20a4-4d0a-a2f7-b3a1523eb3d6',
    0
)
ON CONFLICT (user_id, organization_id) DO UPDATE SET
    version = EXCLUDED.version;

-- Assignment 3: Fernanda Ochoa -> Obispado de Cruz del Eje
INSERT INTO user_org_assignments (id, user_id, organization_id, version)
VALUES (
    '10000000-0000-0000-0005-000000000003',
    '10000000-0000-0000-0001-000000000003',
    'f780d30d-20a4-4d0a-a2f7-b3a1523eb3d6',
    0
)
ON CONFLICT (user_id, organization_id) DO UPDATE SET
    version = EXCLUDED.version;
