#!/usr/bin/env bash
# =============================================================================
# restore-local.sh - Restore a .pgdump backup into the local dev PostgreSQL
# =============================================================================
# Restores a pg_dump custom-format backup (from backup-prod.sh or the restic
# CronJob) into the locally running Docker PostgreSQL container.
#
# This drops and recreates the 'rayuela' database, so ALL local data is lost.
# The restored database will contain prod schemas (public + tenant_*) and data.
#
# Prerequisites:
#   - Docker container 'rayuela-dev-postgres' running
#     (start with: docker-compose -f ../rayuela/dev/docker-compose.yml up -d)
#
# Usage:
#   ./scripts/db/restore-local.sh <file.pgdump>
#   ./scripts/db/restore-local.sh --list
#
# Options:
#   --list        List available backups in ./backups/
#   --no-confirm  Skip the confirmation prompt
#   -h, --help    Show this help message
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

CONTAINER="rayuela-dev-postgres"
DB="rayuela"
APP_USER="grex"
SUPERUSER="postgres"
BACKUP_DIR="${PROJECT_ROOT}/backups"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ─────────────────────────────────────────────────────────────────
# Parse arguments
# ─────────────────────────────────────────────────────────────────
usage() {
  echo "Usage: $0 <file.pgdump> [OPTIONS]"
  echo "       $0 --list"
  echo ""
  echo "Arguments:"
  echo "  <file.pgdump>    Path to a pg_dump custom-format backup file"
  echo ""
  echo "Options:"
  echo "  --list            List available backups in ./backups/"
  echo "  --no-confirm      Skip the confirmation prompt"
  echo "  -h, --help        Show this help message"
  echo ""
  echo "Examples:"
  echo "  $0 --list"
  echo "  $0 backups/prod-v0.2.4-2026-04-14.pgdump"
  echo "  $0 backups/prod-v0.2.4-2026-04-14.pgdump --no-confirm"
  exit 0
}

DUMP_FILE=""
NO_CONFIRM=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --list)
      echo ""
      echo -e "${BOLD}Available backups in ${BACKUP_DIR}/${NC}"
      echo ""
      if [[ -d "$BACKUP_DIR" ]] && ls "$BACKUP_DIR"/*.pgdump &>/dev/null; then
        ls -lhS "$BACKUP_DIR"/*.pgdump | awk '{print "  " $NF " (" $5 ")"}'
      else
        echo "  (none)"
        echo ""
        echo "Create one with: ./scripts/db/backup-prod.sh"
      fi
      echo ""
      exit 0
      ;;
    --no-confirm) NO_CONFIRM=true; shift ;;
    -h|--help)    usage ;;
    -*)           echo -e "${RED}Unknown option: $1${NC}"; usage ;;
    *)
      if [[ -z "$DUMP_FILE" ]]; then
        DUMP_FILE="$1"; shift
      else
        echo -e "${RED}Unexpected argument: $1${NC}"; usage
      fi
      ;;
  esac
done

if [[ -z "$DUMP_FILE" ]]; then
  echo -e "${RED}Error: Backup file required${NC}"
  echo ""
  usage
fi

if [[ ! -f "$DUMP_FILE" ]]; then
  echo -e "${RED}Error: File not found: ${DUMP_FILE}${NC}"
  exit 1
fi

# ─────────────────────────────────────────────────────────────────
# Prerequisites
# ─────────────────────────────────────────────────────────────────
if ! command -v docker &>/dev/null; then
  echo -e "${RED}Error: docker is not installed${NC}"
  exit 1
fi

if ! docker inspect "$CONTAINER" &>/dev/null; then
  echo -e "${RED}Error: Container '${CONTAINER}' is not running${NC}"
  echo ""
  echo "Start it with:"
  echo "  docker-compose -f ../rayuela/dev/docker-compose.yml up -d"
  exit 1
fi

CONTAINER_STATUS=$(docker inspect -f '{{.State.Status}}' "$CONTAINER" 2>/dev/null)
if [[ "$CONTAINER_STATUS" != "running" ]]; then
  echo -e "${RED}Error: Container '${CONTAINER}' exists but is not running (status: ${CONTAINER_STATUS})${NC}"
  exit 1
fi

FILE_SIZE=$(du -h "$DUMP_FILE" | cut -f1)

# ─────────────────────────────────────────────────────────────────
# Confirmation
# ─────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}=========================================="
echo -e "Rayuela Local Database Restore"
echo -e "==========================================${NC}"
echo ""
echo -e "  File:        ${DUMP_FILE} (${FILE_SIZE})"
echo -e "  Container:   ${CONTAINER}"
echo -e "  Database:    ${DB}"
echo -e "  App user:    ${APP_USER}"
echo ""
echo -e "  ${RED}WARNING: This will DROP and recreate the '${DB}' database.${NC}"
echo -e "  ${RED}All existing local data will be lost.${NC}"
echo ""

if [[ "$NO_CONFIRM" != true ]]; then
  read -p "  Continue? (yes/no): " -r
  if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo "  Cancelled."
    exit 0
  fi
  echo ""
fi

# ─────────────────────────────────────────────────────────────────
# 1. Copy dump file into container
# ─────────────────────────────────────────────────────────────────
DUMP_BASENAME=$(basename "$DUMP_FILE")
echo -e "${CYAN}Copying dump into container...${NC}"
docker cp "$DUMP_FILE" "${CONTAINER}:/tmp/${DUMP_BASENAME}"

# ─────────────────────────────────────────────────────────────────
# 2. Drop and recreate the database
# ─────────────────────────────────────────────────────────────────
echo -e "${CYAN}Terminating existing connections to '${DB}'...${NC}"
docker exec "$CONTAINER" psql -U "$SUPERUSER" -d postgres -c \
  "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '${DB}' AND pid <> pg_backend_pid();" \
  >/dev/null 2>&1 || true

echo -e "${CYAN}Dropping database '${DB}'...${NC}"
docker exec "$CONTAINER" psql -U "$SUPERUSER" -d postgres -c \
  "DROP DATABASE IF EXISTS ${DB};"

echo -e "${CYAN}Creating database '${DB}' (owner: ${APP_USER})...${NC}"
docker exec "$CONTAINER" psql -U "$SUPERUSER" -d postgres -c \
  "CREATE DATABASE ${DB} OWNER ${APP_USER};"

# ─────────────────────────────────────────────────────────────────
# 3. Restore the dump
# ─────────────────────────────────────────────────────────────────
echo -e "${CYAN}Restoring from ${DUMP_BASENAME}...${NC}"
docker exec "$CONTAINER" pg_restore \
  -U "$APP_USER" \
  -d "$DB" \
  --no-owner \
  --no-privileges \
  --verbose \
  "/tmp/${DUMP_BASENAME}" 2>&1 | tail -5

# ─────────────────────────────────────────────────────────────────
# 4. Grant permissions (match dev init-databases.sh)
# ─────────────────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}Granting permissions...${NC}"
docker exec "$CONTAINER" psql -U "$SUPERUSER" -d "$DB" <<-EOSQL
  GRANT ALL PRIVILEGES ON DATABASE ${DB} TO ${APP_USER};
  GRANT ALL PRIVILEGES ON SCHEMA public TO ${APP_USER};
  GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO ${APP_USER};
  GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO ${APP_USER};
  ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON TABLES TO ${APP_USER};
  ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON SEQUENCES TO ${APP_USER};
  GRANT CREATE ON DATABASE ${DB} TO ${APP_USER};
EOSQL

# Grant on all tenant schemas
TENANT_SCHEMAS=$(docker exec "$CONTAINER" psql -U "$APP_USER" -d "$DB" -tAc \
  "SELECT schema_name FROM information_schema.schemata WHERE schema_name LIKE 'tenant_%';")

for schema in $TENANT_SCHEMAS; do
  docker exec "$CONTAINER" psql -U "$SUPERUSER" -d "$DB" -c \
    "GRANT ALL PRIVILEGES ON SCHEMA \"${schema}\" TO ${APP_USER};
     GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA \"${schema}\" TO ${APP_USER};
     GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA \"${schema}\" TO ${APP_USER};
     ALTER DEFAULT PRIVILEGES IN SCHEMA \"${schema}\" GRANT ALL PRIVILEGES ON TABLES TO ${APP_USER};
     ALTER DEFAULT PRIVILEGES IN SCHEMA \"${schema}\" GRANT ALL PRIVILEGES ON SEQUENCES TO ${APP_USER};" \
    >/dev/null 2>&1
  echo "  Granted on ${schema}"
done

# ─────────────────────────────────────────────────────────────────
# 5. Cleanup and summary
# ─────────────────────────────────────────────────────────────────
docker exec "$CONTAINER" rm -f "/tmp/${DUMP_BASENAME}"

# Count schemas and tables
SCHEMA_COUNT=$(docker exec "$CONTAINER" psql -U "$APP_USER" -d "$DB" -tAc \
  "SELECT count(*) FROM information_schema.schemata WHERE schema_name LIKE 'tenant_%';")
TABLE_COUNT=$(docker exec "$CONTAINER" psql -U "$APP_USER" -d "$DB" -tAc \
  "SELECT count(*) FROM information_schema.tables WHERE table_schema NOT IN ('pg_catalog', 'information_schema');")

echo ""
echo -e "${GREEN}=========================================="
echo -e "Restore complete!"
echo -e "==========================================${NC}"
echo ""
echo "  Database:    ${DB}"
echo "  Schemas:     public + ${SCHEMA_COUNT} tenant(s)"
echo "  Tables:      ${TABLE_COUNT}"
echo ""
echo "  Connect:     docker exec -it ${CONTAINER} psql -U ${APP_USER} -d ${DB}"
echo ""
