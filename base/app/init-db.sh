#!/bin/sh
# init-db.sh - Initialize Rayuela database schemas
#
# This script runs as an init container before the app starts.
# It creates tenant schemas inside the 'rayuela' database and grants
# the necessary privileges. Flyway handles table migrations.
#
# Seed data must be loaded MANUALLY after deployment since tables
# don't exist until Flyway runs. See /sql directory for seed files.
#
# Required environment variables:
#   DB_HOST          - PostgreSQL host
#   DB_PORT          - PostgreSQL port
#   DB_NAME          - PostgreSQL database name (rayuela)
#   DB_USERNAME      - PostgreSQL username
#   DB_PASSWORD      - PostgreSQL password
#   TENANT_SCHEMAS   - Comma-separated tenant UUIDs (from Kustomize patches)

set -e

echo "=========================================="
echo "Rayuela Database Initialization"
echo "=========================================="
echo ""
echo "Host: ${DB_HOST}:${DB_PORT}"
echo "Database: ${DB_NAME}"
echo "User: ${DB_USERNAME}"
echo "Tenant schemas: ${TENANT_SCHEMAS}"
echo ""

# Wait for PostgreSQL to be ready
echo "Waiting for PostgreSQL to be ready..."
MAX_RETRIES=30
RETRY_COUNT=0

until PGPASSWORD="${DB_PASSWORD}" psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USERNAME}" -d "${DB_NAME}" -c '\q' 2>/dev/null; do
    RETRY_COUNT=$((RETRY_COUNT + 1))
    if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then
        echo "ERROR: PostgreSQL not ready after ${MAX_RETRIES} attempts"
        exit 1
    fi
    echo "  Attempt ${RETRY_COUNT}/${MAX_RETRIES} - PostgreSQL not ready, waiting..."
    sleep 2
done

echo "PostgreSQL is ready!"
echo ""

# ──────────────────────────────────────────────────────────────────
# Grant privileges on public schema + CREATE ON DATABASE
# ──────────────────────────────────────────────────────────────────
echo "=========================================="
echo "Granting privileges on public schema"
echo "=========================================="
echo ""

PGPASSWORD="${DB_PASSWORD}" psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USERNAME}" -d "${DB_NAME}" <<-EOSQL
    GRANT ALL PRIVILEGES ON SCHEMA public TO ${DB_USERNAME};
    GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO ${DB_USERNAME};
    GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO ${DB_USERNAME};
    ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON TABLES TO ${DB_USERNAME};
    ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON SEQUENCES TO ${DB_USERNAME};
    GRANT CREATE ON DATABASE ${DB_NAME} TO ${DB_USERNAME};
EOSQL

echo "  Public schema privileges granted"
echo "  CREATE ON DATABASE ${DB_NAME} granted"
echo ""

# ──────────────────────────────────────────────────────────────────
# Create tenant schemas from TENANT_SCHEMAS env var
# ──────────────────────────────────────────────────────────────────
echo "=========================================="
echo "Creating tenant schemas"
echo "=========================================="
echo ""

if [ -n "${TENANT_SCHEMAS}" ]; then
    echo "${TENANT_SCHEMAS}" | tr ',' '\n' | while read -r uuid; do
        uuid=$(echo "${uuid}" | tr -d '[:space:]')
        [ -z "${uuid}" ] && continue
        SCHEMA_NAME="tenant_${uuid}"
        echo "  Creating schema: ${SCHEMA_NAME}"
        PGPASSWORD="${DB_PASSWORD}" psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USERNAME}" -d "${DB_NAME}" <<-EOSQL
            CREATE SCHEMA IF NOT EXISTS "${SCHEMA_NAME}" AUTHORIZATION ${DB_USERNAME};
            GRANT ALL PRIVILEGES ON SCHEMA "${SCHEMA_NAME}" TO ${DB_USERNAME};
            ALTER DEFAULT PRIVILEGES IN SCHEMA "${SCHEMA_NAME}" GRANT ALL PRIVILEGES ON TABLES TO ${DB_USERNAME};
            ALTER DEFAULT PRIVILEGES IN SCHEMA "${SCHEMA_NAME}" GRANT ALL PRIVILEGES ON SEQUENCES TO ${DB_USERNAME};
EOSQL
        echo "  Schema ${SCHEMA_NAME} ready"
    done
else
    echo "  No TENANT_SCHEMAS defined, skipping tenant schema creation"
fi

echo ""
echo "=========================================="
echo "Database Initialization Complete!"
echo "=========================================="
echo ""
echo "Schemas available:"
echo "  - public (central/shared data)"
if [ -n "${TENANT_SCHEMAS}" ]; then
    echo "${TENANT_SCHEMAS}" | tr ',' '\n' | while read -r uuid; do
        uuid=$(echo "${uuid}" | tr -d '[:space:]')
        [ -z "${uuid}" ] && continue
        echo "  - tenant_${uuid}"
    done
fi
echo ""
echo "Next steps:"
echo "  1. Flyway will create tables when the app starts"
echo "  2. Seed data manually after app is running:"
echo "     scripts/seed-{env}.sh"
echo "=========================================="
