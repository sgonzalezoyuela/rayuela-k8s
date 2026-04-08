# Feature: db.init-script — Rewrite init-db.sh

## Problem
Current init-db.sh creates 3 separate databases (grexc, grext1, grext2).
The app now uses a single `rayuela` database with tenant schemas.

## Reference Implementation
The dev docker setup (`../rayuela/dev/postgres/init-databases.sh`) is the working reference:
- Creates tenant schemas: `CREATE SCHEMA IF NOT EXISTS "tenant_{uuid}"`
- Grants privileges on schemas
- Grants `CREATE ON DATABASE rayuela` for runtime schema creation

## Design: Option A (hardcoded per-env via TENANT_SCHEMAS env var)

Add a `TENANT_SCHEMAS` env var to the configmap, defined per-environment via Kustomize patches.
The init script reads this var and creates one schema per comma-separated UUID.

### ConfigMap additions

**env/prod/patches/configmap.yaml** — add:
```yaml
  TENANT_SCHEMAS: "f780d30d-20a4-4d0a-a2f7-b3a1523eb3d6"
```

**env/dev/patches/configmap.yaml** — add:
```yaml
  TENANT_SCHEMAS: "f780d30d-20a4-4d0a-a2f7-b3a1523eb3d6,df766dc2-6d4c-44d4-90ad-19d9ab69fa9d"
```

### New init-db.sh structure

**IMPORTANT:** The init container uses `postgres:17-alpine` which runs `sh` (not bash).
Must use POSIX-compatible shell syntax. No bash arrays (`<<<`), use `echo | tr` for splitting.

```sh
#!/bin/sh
set -e

# Wait for PostgreSQL readiness
# Use DB_HOST, DB_PORT, DB_USERNAME, DB_PASSWORD from configmap/secret
MAX_RETRIES=30; RETRY_COUNT=0
until PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USERNAME" -d "$DB_NAME" -c '\q' 2>/dev/null; do
    RETRY_COUNT=$((RETRY_COUNT + 1))
    if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then exit 1; fi
    sleep 2
done

# Grant privileges on public schema + CREATE ON DATABASE
PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USERNAME" -d "$DB_NAME" <<-EOSQL
    GRANT ALL PRIVILEGES ON SCHEMA public TO $DB_USERNAME;
    GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO $DB_USERNAME;
    GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO $DB_USERNAME;
    ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON TABLES TO $DB_USERNAME;
    ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON SEQUENCES TO $DB_USERNAME;
    GRANT CREATE ON DATABASE $DB_NAME TO $DB_USERNAME;
EOSQL

# Create tenant schemas from TENANT_SCHEMAS env var (comma-separated UUIDs)
if [ -n "$TENANT_SCHEMAS" ]; then
    echo "$TENANT_SCHEMAS" | tr ',' '\n' | while read -r uuid; do
        uuid=$(echo "$uuid" | tr -d '[:space:]')
        [ -z "$uuid" ] && continue
        SCHEMA_NAME="tenant_${uuid}"
        PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USERNAME" -d "$DB_NAME" <<-EOSQL
            CREATE SCHEMA IF NOT EXISTS "$SCHEMA_NAME" AUTHORIZATION $DB_USERNAME;
            GRANT ALL PRIVILEGES ON SCHEMA "$SCHEMA_NAME" TO $DB_USERNAME;
            ALTER DEFAULT PRIVILEGES IN SCHEMA "$SCHEMA_NAME" GRANT ALL PRIVILEGES ON TABLES TO $DB_USERNAME;
            ALTER DEFAULT PRIVILEGES IN SCHEMA "$SCHEMA_NAME" GRANT ALL PRIVILEGES ON SEQUENCES TO $DB_USERNAME;
        EOSQL
    done
fi
```

### Deployment.yaml
The init container already mounts `rayuela-config` via envFrom (line 41-42),
so `TENANT_SCHEMAS` will be available automatically once added to the configmap patches.

## Acceptance Criteria

1. init-db.sh creates tenant schemas inside 'rayuela' database (not separate databases)
2. Grants CREATE ON DATABASE for runtime tenant provisioning
3. Grants ALL PRIVILEGES on public and tenant schemas
4. Prod creates tenant_f780d30d-20a4-4d0a-a2f7-b3a1523eb3d6
5. Dev creates both tenant_f780d30d-... and tenant_df766dc2-...
6. POSIX sh compatible (not bash)
