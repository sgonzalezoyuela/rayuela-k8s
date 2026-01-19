#!/bin/bash
# PostgreSQL Database Initialization Script for Rayuela (Kubernetes)
#
# This script runs when the PostgreSQL container starts for the first time.
# It creates the necessary databases for Rayuela's multi-tenant architecture.
#
# Databases created:
#   - grexc  : Central database (organizations, users, assignments) - created by default
#   - grext1 : Tenant 1 database (business units, employees, payroll)
#   - grext2 : Tenant 2 database (business units, employees, payroll)
#
# Note: Schema is managed by Flyway migrations, not by this script.

set -e

echo "=========================================="
echo "Rayuela Database Initialization"
echo "=========================================="
echo ""

# The grex user and grexc database are created by default via POSTGRES_USER and POSTGRES_DB
# We just need to create the tenant databases

# Create and configure tenant databases
for tenant_db in grext1 grext2
do
    echo "Creating tenant database: $tenant_db"
    
    # Create database if it doesn't exist
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
        SELECT 'CREATE DATABASE $tenant_db OWNER $POSTGRES_USER'
        WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '$tenant_db')\gexec
EOSQL
    
    # Connect to the new database and set schema privileges
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$tenant_db" <<-EOSQL
        GRANT ALL PRIVILEGES ON SCHEMA public TO $POSTGRES_USER;
        ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON TABLES TO $POSTGRES_USER;
        ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON SEQUENCES TO $POSTGRES_USER;
EOSQL
    
    echo "Tenant database $tenant_db created and configured"
    echo ""
done

echo "=========================================="
echo "Database Initialization Complete!"
echo "=========================================="
echo ""
echo "Databases created:"
echo "  - grexc  (Central database)"
echo "  - grext1 (Tenant 1 database)"
echo "  - grext2 (Tenant 2 database)"
echo ""
echo "Connection details:"
echo "  Host:     rayuela-db"
echo "  Port:     5432"
echo "  User:     $POSTGRES_USER"
echo ""
echo "Note: Schema will be created by Flyway migrations when the application starts."
echo "=========================================="
