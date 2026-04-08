# Feature: sql.seed-schema-migration — Adapt SQL Seed Files

## Problem
SQL seed files target separate databases (grexc, grext1, grext2). Must target schemas in single `rayuela` DB.
Also, column names and enum values in the SQL don't match the actual Flyway-created schema.

## Verified DDL Column Names (from Flyway migrations in ../rayuela)

### organizations (public schema — central/V1__initial_schema.sql)
```sql
    id              UUID PRIMARY KEY,
    name            VARCHAR(200)  NOT NULL,
    cuit            VARCHAR(11)   NOT NULL,
    status          VARCHAR(20)   NOT NULL,       -- 'ACTIVA' or 'APROVISIONANDO'
    schema_name     VARCHAR(255),                 -- 'tenant_f780d30d-...' (NOT nombre_esquema)
    version         BIGINT        NOT NULL DEFAULT 0,
    created_at      TIMESTAMP,
    updated_at      TIMESTAMP
```

### tenant_users (tenant schema — tenant/V1__initial_schema.sql)
```sql
    status      VARCHAR(20)   NOT NULL DEFAULT 'HABILITADO'  -- NOT 'ENABLED'
```

## Changes per file

### Public schema files — add at top of each:
```sql
SET search_path = 'public';
```
Applies to: central-data.sql, convenios-data.sql, cargos-data.sql, conceptos-data.sql, concepto-versiones-data.sql (both env/prod/sql/ and env/dev/sql/)

### central-data.sql (prod) — fix organizations INSERT:
```sql
-- Add schema_name column, fix status value
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
```

### central-data.sql (dev) — both orgs need schema_name:
- Org 1 (f780d30d-...): schema_name = 'tenant_f780d30d-20a4-4d0a-a2f7-b3a1523eb3d6', status = 'ACTIVA'
- Org 2 (df766dc2-...): schema_name = 'tenant_df766dc2-6d4c-44d4-90ad-19d9ab69fa9d', status = 'ACTIVA'

### Tenant SQL files — add SET search_path at top:

| File | search_path |
|------|------------|
| env/prod/sql/tenant1-data.sql | `SET search_path = 'tenant_f780d30d-20a4-4d0a-a2f7-b3a1523eb3d6';` |
| env/prod/sql/tenant2-data.sql | (still empty — just update comments) |
| env/dev/sql/tenant1-data.sql | `SET search_path = 'tenant_f780d30d-20a4-4d0a-a2f7-b3a1523eb3d6';` |
| env/dev/sql/tenant2-data.sql | `SET search_path = 'tenant_df766dc2-6d4c-44d4-90ad-19d9ab69fa9d';` |

### tenant_users status fix:
In ALL tenant SQL files (prod and dev), change `'ENABLED'` → `'HABILITADO'`

### Comment updates:
- Remove all references to "grexc", "grext1", "grext2" databases
- Replace with "rayuela database, public schema" or "rayuela database, tenant schema"
- Remove references to "application.yml tenant ID mapping" (no longer relevant)
- Remove references to "database (grext1)" style comments

### Dev-shared catalog files (convenios, cargos, conceptos, concepto-versiones):
These files are identical between dev and prod. They target `public` schema. Just add `SET search_path = 'public';` at top and update comments.

## Edge Cases
- empresas_convenios table is in tenant schema (not public). The INSERT in tenant1-data.sql is correct since search_path will be set to the tenant schema.
- The convenios table is in public schema, but empresas_convenios references it via FK across schemas — PostgreSQL handles this fine with search_path.
