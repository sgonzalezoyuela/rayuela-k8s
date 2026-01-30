#!/bin/sh
# backup.sh - Backup Rayuela PostgreSQL databases to restic REST server
#
# This script runs as a Kubernetes CronJob to:
# 1. Dump all Rayuela databases (grexc, grext1, grext2)
# 2. Backup dumps to restic REST server via nginx proxy
# 3. Apply retention policy (7 daily, 4 weekly, 12 monthly)
#
# Required environment variables:
#   RESTIC_REPOSITORY - restic REST server URL (e.g., rest:http://10.0.3.2:8000/rayuela)
#   RESTIC_PASSWORD   - restic repository password
#   PGPASSWORD        - PostgreSQL password
#   DB_HOST           - PostgreSQL host (default: rayuela-db)
#   DB_USER           - PostgreSQL user (default: grex)

set -e

BACKUP_DIR="/tmp/backup"
DB_HOST="${DB_HOST:-rayuela-db}"
DB_USER="${DB_USER:-grex}"
DATABASES="grexc grext1 grext2"

echo "=========================================="
echo "Rayuela Database Backup"
echo "=========================================="
echo "Date: $(date -Iseconds)"
echo "Host: ${DB_HOST}"
echo "Databases: ${DATABASES}"
echo "Repository: ${RESTIC_REPOSITORY}"
echo ""

# Restic is provided via init container at /tools/restic
export PATH="/tools:$PATH"

if ! command -v restic &> /dev/null; then
    echo "ERROR: restic not found at /tools/restic"
    echo "The init container should have copied it there."
    exit 1
fi

echo "Using restic: $(restic version)"

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Verify restic repository is accessible
echo "Checking restic repository..."
if ! restic snapshots 2>&1; then
    echo "ERROR: Cannot access restic repository"
    exit 1
fi
echo "Repository accessible."

# Dump each database
echo ""
echo "=========================================="
echo "Dumping databases"
echo "=========================================="
for db in $DATABASES; do
    echo "Dumping ${db}..."
    
    # Check if database exists
    if psql -h "$DB_HOST" -U "$DB_USER" -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='${db}'" | grep -q 1; then
        pg_dump -h "$DB_HOST" -U "$DB_USER" -d "$db" --format=custom --file="$BACKUP_DIR/${db}.dump"
        echo "  Created ${db}.dump ($(du -h "$BACKUP_DIR/${db}.dump" | cut -f1))"
    else
        echo "  Skipping ${db} (database does not exist)"
    fi
done

# Create metadata file
echo ""
echo "Creating metadata..."
cat > "$BACKUP_DIR/backup-metadata.json" << EOF
{
    "timestamp": "$(date -Iseconds)",
    "host": "${DB_HOST}",
    "databases": "$(echo $DATABASES | tr ' ' ',')",
    "kubernetes_namespace": "${POD_NAMESPACE:-unknown}",
    "kubernetes_pod": "${POD_NAME:-unknown}"
}
EOF

# Backup to restic
echo ""
echo "=========================================="
echo "Backing up to restic"
echo "=========================================="
restic backup "$BACKUP_DIR" \
    --tag rayuela \
    --tag postgres \
    --tag prod \
    --host rayuela-k8s \
    --verbose

# Apply retention policy
echo ""
echo "=========================================="
echo "Applying retention policy"
echo "=========================================="
restic forget \
    --keep-daily 7 \
    --keep-weekly 4 \
    --keep-monthly 12 \
    --prune \
    --verbose

# Show current snapshots
echo ""
echo "=========================================="
echo "Current snapshots"
echo "=========================================="
restic snapshots --tag rayuela

# Cleanup
rm -rf "$BACKUP_DIR"

echo ""
echo "=========================================="
echo "Backup completed successfully!"
echo "=========================================="
