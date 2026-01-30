#!/bin/sh
# init-db.sh - Initialize Rayuela databases
#
# This script runs as an init container before the app starts.
# It ONLY creates the databases - Flyway handles schema migrations.
#
# Seed data must be loaded MANUALLY after deployment since tables
# don't exist until Flyway runs. See /sql directory for seed files.
#
# Required environment variables:
#   CENTRAL_DB_HOST     - PostgreSQL host
#   CENTRAL_DB_PORT     - PostgreSQL port
#   CENTRAL_DB_USERNAME - PostgreSQL username
#   CENTRAL_DB_PASSWORD - PostgreSQL password
#
# Databases created:
#   - grexc  : Central database (organizations, users)
#   - grext1 : Tenant 1 database
#   - grext2 : Tenant 2 database

set -e

echo "=========================================="
echo "Rayuela Database Initialization"
echo "=========================================="
echo ""
echo "Host: ${CENTRAL_DB_HOST}:${CENTRAL_DB_PORT}"
echo "User: ${CENTRAL_DB_USERNAME}"
echo ""

# Wait for PostgreSQL to be ready
echo "Waiting for PostgreSQL to be ready..."
MAX_RETRIES=30
RETRY_COUNT=0

until PGPASSWORD="${CENTRAL_DB_PASSWORD}" psql -h "${CENTRAL_DB_HOST}" -p "${CENTRAL_DB_PORT}" -U "${CENTRAL_DB_USERNAME}" -d postgres -c '\q' 2>/dev/null; do
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

# Function to create database if it doesn't exist
create_db_if_not_exists() {
    DB_NAME=$1
    echo "Checking database: ${DB_NAME}"
    
    EXISTS=$(PGPASSWORD="${CENTRAL_DB_PASSWORD}" psql -h "${CENTRAL_DB_HOST}" -p "${CENTRAL_DB_PORT}" -U "${CENTRAL_DB_USERNAME}" -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='${DB_NAME}'")
    
    if [ "$EXISTS" = "1" ]; then
        echo "  Database ${DB_NAME} already exists"
    else
        echo "  Creating database ${DB_NAME}..."
        PGPASSWORD="${CENTRAL_DB_PASSWORD}" psql -h "${CENTRAL_DB_HOST}" -p "${CENTRAL_DB_PORT}" -U "${CENTRAL_DB_USERNAME}" -d postgres <<-EOSQL
            CREATE DATABASE ${DB_NAME}
                WITH OWNER = ${CENTRAL_DB_USERNAME}
                ENCODING = 'UTF8'
                LC_COLLATE = 'en_US.utf8'
                LC_CTYPE = 'en_US.utf8'
                CONNECTION LIMIT = -1;
EOSQL
        echo "  Database ${DB_NAME} created successfully"
    fi
}

echo "=========================================="
echo "Creating databases"
echo "=========================================="
echo ""

create_db_if_not_exists "grexc"
create_db_if_not_exists "grext1"
create_db_if_not_exists "grext2"

echo ""
echo "=========================================="
echo "Database Initialization Complete!"
echo "=========================================="
echo ""
echo "Databases available:"
echo "  - grexc  (Central database)"
echo "  - grext1 (Tenant 1 database)"
echo "  - grext2 (Tenant 2 database)"
echo ""
echo "Next steps:"
echo "  1. Flyway will create tables when the app starts"
echo "  2. Seed data manually after app is running:"
echo "     kubectl exec -it rayuela-db-0 -n rayuela -- psql -U grex -d grexc -f /path/to/central-data.sql"
echo "     kubectl exec -it rayuela-db-0 -n rayuela -- psql -U grex -d grext1 -f /path/to/tenant1-data.sql"
echo "     kubectl exec -it rayuela-db-0 -n rayuela -- psql -U grex -d grext2 -f /path/to/tenant2-data.sql"
echo "=========================================="
