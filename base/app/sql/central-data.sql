-- Central Database Test Data for Rayuela
-- Inserts two organizations (tenants) for testing

-- Insert Organization 1
-- CUIT: 30-12345678-1 (valid Argentine CUIT for legal entity)
INSERT INTO organizations (id, name, cuit, status, version)
VALUES (
    'f780d30d-20a4-4d0a-a2f7-b3a1523eb3d6',
    'Obispado de Cruz del Eje',
    '30123456781',
    'ACTIVE',
    0
)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    cuit = EXCLUDED.cuit,
    status = EXCLUDED.status,
    version = EXCLUDED.version;

-- Insert Organization 2
-- CUIT: 30-23456789-2 (valid Argentine CUIT for legal entity)
INSERT INTO organizations (id, name, cuit, status, version)
VALUES (
    'df766dc2-6d4c-44d4-90ad-19d9ab69fa9d',
    'Organization 2',
    '30234567892',
    'ACTIVE',
    0
)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    cuit = EXCLUDED.cuit,
    status = EXCLUDED.status,
    version = EXCLUDED.version;

-- Insert test user Cecilia Ghio
INSERT INTO users (id, email, first_name, last_name, status, version)
VALUES (
    'cccccccc-cccc-4ccc-cccc-cccccccccccc',
    'ceciliaghio49@gmail.com',
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

-- Assign Cecilia Ghio to Obispado de Cruz del Eje (no role column in new schema)
INSERT INTO user_org_assignments (id, user_id, organization_id, period_start, period_end, version)
VALUES (
    'dddddddd-dddd-4ddd-dddd-dddddddddddd',
    'cccccccc-cccc-4ccc-cccc-cccccccccccc',
    'f780d30d-20a4-4d0a-a2f7-b3a1523eb3d6',
    CURRENT_DATE,
    NULL,
    0
)
ON CONFLICT (user_id, organization_id) DO UPDATE SET
    period_start = EXCLUDED.period_start,
    period_end = EXCLUDED.period_end,
    version = EXCLUDED.version;

-- Assign Cecilia Ghio to Organization 2 (no role column in new schema)
INSERT INTO user_org_assignments (id, user_id, organization_id, period_start, period_end, version)
VALUES (
    'eeeeeeee-eeee-4eee-eeee-eeeeeeeeeeee',
    'cccccccc-cccc-4ccc-cccc-cccccccccccc',
    'df766dc2-6d4c-44d4-90ad-19d9ab69fa9d',
    CURRENT_DATE,
    NULL,
    0
)
ON CONFLICT (user_id, organization_id) DO UPDATE SET
    period_start = EXCLUDED.period_start,
    period_end = EXCLUDED.period_end,
    version = EXCLUDED.version;
