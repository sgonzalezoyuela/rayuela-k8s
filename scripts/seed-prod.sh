#!/usr/bin/env bash
# =============================================================================
# seed-prod.sh - Seed production data into the rayuela database
# =============================================================================
# All data lives in a single 'rayuela' database. Each SQL file sets its own
# search_path to target the correct schema:
#   - Public schema: organizations, users, catalogs (convenios, cargos, etc.)
#   - Tenant schema: business units, tenant users, roles, permissions
# =============================================================================

set -e

NS="rayuela-prod"
DB="rayuela"
POD="rayuela-db-0"

echo "Seeding production data into ${DB}..."

# ─────────────────────────────────────────────────────────────────
# 1. Public schema data (organizations, users, user-org assignments)
# ─────────────────────────────────────────────────────────────────
echo "  [public] central-data.sql"
kubectl exec -it "${POD}" -n "${NS}" -- psql -U grex -d "${DB}" -f /sql/central-data.sql

# ─────────────────────────────────────────────────────────────────
# 2. Shared catalog data (public schema, loaded once for all tenants)
# ─────────────────────────────────────────────────────────────────
echo "  [public] convenios-data.sql"
kubectl exec -it "${POD}" -n "${NS}" -- psql -U grex -d "${DB}" -f /sql/convenios-data.sql
echo "  [public] cargos-data.sql"
kubectl exec -it "${POD}" -n "${NS}" -- psql -U grex -d "${DB}" -f /sql/cargos-data.sql
echo "  [public] conceptos-data.sql"
kubectl exec -it "${POD}" -n "${NS}" -- psql -U grex -d "${DB}" -f /sql/conceptos-data.sql
echo "  [public] concepto-versiones-data.sql"
kubectl exec -it "${POD}" -n "${NS}" -- psql -U grex -d "${DB}" -f /sql/concepto-versiones-data.sql

# ─────────────────────────────────────────────────────────────────
# 3. Tenant schema data (each file sets its own search_path)
# ─────────────────────────────────────────────────────────────────
echo "  [tenant] tenant1-data.sql (Obispado de Cruz del Eje)"
kubectl exec -it "${POD}" -n "${NS}" -- psql -U grex -d "${DB}" -f /sql/tenant1-data.sql

echo ""
echo "Production seeding complete!"
