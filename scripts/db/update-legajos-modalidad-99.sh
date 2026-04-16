#!/usr/bin/env bash
# =============================================================================
# update-legajos-modalidad-99.sh - Update all legajos to modalidad code 99 (LRT)
# =============================================================================
# One-time migration that changes modalidad_contratacion_id on ALL legajos
# across ALL tenant schemas to code 99 (LRT — Ley de Riesgos del Trabajo).
#
# Previously, legajos were set to code 8 (A Tiempo completo indeterminado) by
# the backfill-legajo-defaults.sh script.
#
# Steps:
#   1. Seeds the modalidades_contratacion table from the LOCAL sql file
#      (piped via stdin, independent of the pod's mounted configmap)
#   2. Updates every legajo in every tenant schema to use code 99
#
# Prerequisites:
#   - Run from the project root, or anywhere under rayuela-k8s/
#
# Usage:
#   ./scripts/db/update-legajos-modalidad-99.sh
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SQL_FILE="${PROJECT_ROOT}/env/prod/sql/modalidades-contratacion-data.sql"

NS="rayuela-prod"
DB="rayuela"
POD="rayuela-db-0"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

if [[ ! -f "$SQL_FILE" ]]; then
  echo -e "${RED}Error: SQL file not found: ${SQL_FILE}${NC}"
  exit 1
fi

echo ""
echo -e "${BOLD}══════════════════════════════════════════${NC}"
echo -e "${BOLD}  Update legajos → modalidad code 99${NC}"
echo -e "${BOLD}══════════════════════════════════════════${NC}"
echo ""
echo -e "  Namespace:  ${CYAN}${NS}${NC}"
echo -e "  Database:   ${CYAN}${DB}${NC}"
echo -e "  Pod:        ${CYAN}${POD}${NC}"
echo -e "  SQL file:   ${CYAN}${SQL_FILE}${NC}"
echo ""

# ─────────────────────────────────────────────────────────────────
# Step 1 — Seed modalidades_contratacion (ensure code 99 exists)
# ─────────────────────────────────────────────────────────────────
echo -e "${BOLD}── Step 1 ──────────────────────────────${NC}"
echo ""
echo "  [1/2] Seeding modalidades_contratacion (ensuring code 99 exists)..."
kubectl exec -i "${POD}" -n "${NS}" -- psql -U grex -d "${DB}" < "$SQL_FILE"
echo ""

# ─────────────────────────────────────────────────────────────────
# Step 2 — Update all legajos to modalidad code 99
# ─────────────────────────────────────────────────────────────────
echo -e "${BOLD}── Step 2 ──────────────────────────────${NC}"
echo ""
echo "  [2/2] Updating all legajos across all tenant schemas..."
echo ""

kubectl exec -i "${POD}" -n "${NS}" -- psql -U grex -d "${DB}" <<'EOSQL'
DO $$
DECLARE
    v_new_id   UUID;
    v_old_id   UUID;
    v_schema   TEXT;
    v_count    INTEGER;
    v_total    INTEGER := 0;
BEGIN
    -- Resolve new modalidad (code 99, active)
    SELECT id INTO STRICT v_new_id
      FROM public.modalidades_contratacion
     WHERE codigo = 99 AND hasta IS NULL;

    -- Resolve old modalidad (code 8, active) for reporting
    SELECT id INTO v_old_id
      FROM public.modalidades_contratacion
     WHERE codigo = 8 AND hasta IS NULL;

    RAISE NOTICE 'Modalidad change: codigo 8 (%) -> codigo 99 (%)', v_old_id, v_new_id;
    RAISE NOTICE '';

    -- Loop through every tenant schema
    FOR v_schema IN
        SELECT schema_name
          FROM information_schema.schemata
         WHERE schema_name LIKE 'tenant_%'
         ORDER BY schema_name
    LOOP
        RAISE NOTICE 'Processing schema: %', v_schema;

        EXECUTE format(
            'UPDATE %I.legajos SET modalidad_contratacion_id = $1',
            v_schema
        ) USING v_new_id;

        GET DIAGNOSTICS v_count = ROW_COUNT;
        v_total := v_total + v_count;
        RAISE NOTICE '  -> Updated % legajo(s)', v_count;
    END LOOP;

    RAISE NOTICE '';
    RAISE NOTICE '==========================================';
    RAISE NOTICE 'Done. Total legajos updated: %', v_total;
    RAISE NOTICE '==========================================';
END
$$;
EOSQL

echo ""
echo -e "${GREEN}${BOLD}Migration complete!${NC}"
echo ""
