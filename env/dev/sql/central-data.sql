-- =============================================================================
-- Development Database - Central (grexc)
-- =============================================================================
-- TODO: Replace placeholder data with actual dev environment data.
--
-- Organization IDs must match tenant IDs in application.yml:
--   f780d30d-20a4-4d0a-a2f7-b3a1523eb3d6 -> grext1
--   df766dc2-6d4c-44d4-90ad-19d9ab69fa9d -> grext2
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Organization
-- ID must match the tenant ID in application.yml that maps to grext1
-- -----------------------------------------------------------------------------
INSERT INTO organizations (id, name, cuit, status, version)
VALUES (
    'f780d30d-20a4-4d0a-a2f7-b3a1523eb3d6',
    'Dev Organization 1',
    '30000000007',
    'ACTIVE',
    0
)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    cuit = EXCLUDED.cuit,
    status = EXCLUDED.status,
    version = EXCLUDED.version;

-- -----------------------------------------------------------------------------
-- Organization 2
-- ID must match the tenant ID in application.yml that maps to grext2
-- -----------------------------------------------------------------------------
INSERT INTO organizations (id, name, cuit, status, version)
VALUES (
    'df766dc2-6d4c-44d4-90ad-19d9ab69fa9d',
    'Dev Organization 2',
    '30000000015',
    'ACTIVE',
    0
)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    cuit = EXCLUDED.cuit,
    status = EXCLUDED.status,
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

-- -----------------------------------------------------------------------------
-- User-Organization Assignments
-- -----------------------------------------------------------------------------

-- Dev User 1 -> Dev Organization 1
INSERT INTO user_org_assignments (id, user_id, organization_id, period_start, period_end, version)
VALUES (
    '20000000-0000-0000-0005-000000000001',
    '20000000-0000-0000-0001-000000000001',
    'f780d30d-20a4-4d0a-a2f7-b3a1523eb3d6',
    CURRENT_DATE,
    NULL,
    0
)
ON CONFLICT (user_id, organization_id) DO UPDATE SET
    period_start = EXCLUDED.period_start,
    period_end = EXCLUDED.period_end,
    version = EXCLUDED.version;

-- Sebastian Gonzalez Oyuela -> Dev Organization 1
INSERT INTO user_org_assignments (id, user_id, organization_id, period_start, period_end, version)
VALUES (
    '20000000-0000-0000-0005-000000000010',
    '10000000-0000-0000-0001-000000000002',
    'f780d30d-20a4-4d0a-a2f7-b3a1523eb3d6',
    CURRENT_DATE,
    NULL,
    0
)
ON CONFLICT (user_id, organization_id) DO UPDATE SET
    period_start = EXCLUDED.period_start,
    period_end = EXCLUDED.period_end,
    version = EXCLUDED.version;

-- Sebastian Gonzalez Oyuela -> Dev Organization 2
INSERT INTO user_org_assignments (id, user_id, organization_id, period_start, period_end, version)
VALUES (
    '20000000-0000-0000-0005-000000000011',
    '10000000-0000-0000-0001-000000000002',
    'df766dc2-6d4c-44d4-90ad-19d9ab69fa9d',
    CURRENT_DATE,
    NULL,
    0
)
ON CONFLICT (user_id, organization_id) DO UPDATE SET
    period_start = EXCLUDED.period_start,
    period_end = EXCLUDED.period_end,
    version = EXCLUDED.version;
