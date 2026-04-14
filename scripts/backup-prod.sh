#!/usr/bin/env bash
# =============================================================================
# backup-prod.sh - Create a local backup of the production database
# =============================================================================
# Dumps the 'rayuela' database (all schemas: public + tenant_*) from the
# production pod and copies it locally to ./backups/.
#
# Filename format: prod-v<VERSION>-<YYYY-MM-DD>.pgdump
# Version is read from base/app/configmap.yaml (RAYUELA_VERSION).
#
# Usage:
#   ./scripts/backup-prod.sh
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

NS="rayuela-prod"
DB="rayuela"
POD="rayuela-db-0"
USER="grex"
BACKUP_DIR="${PROJECT_ROOT}/backups"

# Parse version from configmap
CONFIGMAP="${PROJECT_ROOT}/base/app/configmap.yaml"
VERSION=$(grep 'RAYUELA_VERSION' "$CONFIGMAP" | sed 's/.*"\(.*\)"/\1/')

if [ -z "$VERSION" ]; then
  echo "ERROR: Could not parse RAYUELA_VERSION from ${CONFIGMAP}"
  exit 1
fi

DATE=$(date +%Y-%m-%d)
FILENAME="prod-v${VERSION}-${DATE}.pgdump"

mkdir -p "$BACKUP_DIR"

echo "=========================================="
echo "Rayuela Production Backup (local)"
echo "=========================================="
echo "  Namespace: ${NS}"
echo "  Pod:       ${POD}"
echo "  Database:  ${DB}"
echo "  Version:   v${VERSION}"
echo "  File:      ${FILENAME}"
echo ""

# Dump inside the pod
echo "Dumping database..."
kubectl exec "${POD}" -n "${NS}" -- \
  pg_dump -U "${USER}" -d "${DB}" --format=custom -f "/tmp/${FILENAME}"

# Copy to local
echo "Copying to ${BACKUP_DIR}/${FILENAME}..."
kubectl cp "${NS}/${POD}:/tmp/${FILENAME}" "${BACKUP_DIR}/${FILENAME}"

# Cleanup pod temp file
kubectl exec "${POD}" -n "${NS}" -- rm -f "/tmp/${FILENAME}"

SIZE=$(du -h "${BACKUP_DIR}/${FILENAME}" | cut -f1)

echo ""
echo "=========================================="
echo "Backup complete!"
echo "=========================================="
echo "  ${BACKUP_DIR}/${FILENAME} (${SIZE})"
