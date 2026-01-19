#!/bin/sh
# init-db.sh - Initialize Rayuela databases and load seed data
#
# This script runs as an init container before the app starts.
# It creates the central and tenant databases if they don't exist,
# then loads seed data from SQL files.
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
#
# SQL files loaded (from /sql directory):
#   - central-data.sql   -> grexc
#   - cargos-data.sql    -> grext1, grext2
#   - conceptos-data.sql -> grext1, grext2
#   - tenant1-data.sql   -> grext1
#   - tenant2-data.sql   -> grext2

set -e

SQL_DIR="/sql"

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
        return 1  # Return 1 to indicate DB already existed
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
        return 0  # Return 0 to indicate DB was created
    fi
}

# Function to run SQL file against a database
run_sql_file() {
    DB_NAME=$1
    SQL_FILE=$2
    
    if [ -f "${SQL_DIR}/${SQL_FILE}" ]; then
        echo "  Loading ${SQL_FILE} into ${DB_NAME}..."
        PGPASSWORD="${CENTRAL_DB_PASSWORD}" psql -h "${CENTRAL_DB_HOST}" -p "${CENTRAL_DB_PORT}" -U "${CENTRAL_DB_USERNAME}" -d "${DB_NAME}" -f "${SQL_DIR}/${SQL_FILE}" > /dev/null 2>&1
        echo "    Done"
    else
        echo "  Skipping ${SQL_FILE} (file not found)"
    fi
}

# Function to check if a table has data
table_has_data() {
    DB_NAME=$1
    TABLE_NAME=$2
    
    COUNT=$(PGPASSWORD="${CENTRAL_DB_PASSWORD}" psql -h "${CENTRAL_DB_HOST}" -p "${CENTRAL_DB_PORT}" -U "${CENTRAL_DB_USERNAME}" -d "${DB_NAME}" -tAc "SELECT COUNT(*) FROM ${TABLE_NAME}" 2>/dev/null || echo "0")
    [ "$COUNT" != "0" ] && [ "$COUNT" != "" ]
}

echo "=========================================="
echo "Phase 1: Creating databases"
echo "=========================================="
echo ""

# Create databases and track if they're new
GREXC_NEW=false
GREXT1_NEW=false
GREXT2_NEW=false

create_db_if_not_exists "grexc" && GREXC_NEW=true || true
create_db_if_not_exists "grext1" && GREXT1_NEW=true || true
create_db_if_not_exists "grext2" && GREXT2_NEW=true || true

echo ""
echo "=========================================="
echo "Phase 2: Loading seed data"
echo "=========================================="
echo ""

# Check if SQL directory exists
if [ ! -d "${SQL_DIR}" ]; then
    echo "No SQL directory found at ${SQL_DIR}, skipping seed data"
else
    echo "SQL files found in ${SQL_DIR}:"
    ls -la "${SQL_DIR}"/*.sql 2>/dev/null || echo "  (no .sql files)"
    echo ""
    
    # Load central data (always idempotent with ON CONFLICT)
    echo "Loading central database data..."
    run_sql_file "grexc" "central-data.sql"
    echo ""
    
    # Load tenant 1 data
    echo "Loading tenant 1 database data..."
    run_sql_file "grext1" "cargos-data.sql"
    run_sql_file "grext1" "conceptos-data.sql"
    run_sql_file "grext1" "tenant1-data.sql"
    echo ""
    
    # Load tenant 2 data
    echo "Loading tenant 2 database data..."
    run_sql_file "grext2" "cargos-data.sql"
    run_sql_file "grext2" "conceptos-data.sql"
    run_sql_file "grext2" "tenant2-data.sql"
    echo ""
fi

echo "=========================================="
echo "Database Initialization Complete!"
echo "=========================================="
echo ""
echo "Databases available:"
echo "  - grexc  (Central database)"
echo "  - grext1 (Tenant 1 database)"
echo "  - grext2 (Tenant 2 database)"
echo ""
echo "Flyway will handle schema migrations when the app starts."
echo "=========================================="
