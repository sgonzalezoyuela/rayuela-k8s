#!/usr/bin/env bash
# =============================================================================
# update-931-registro4-corresponde-reduccion.sh
# =============================================================================
# One-time migration that sets corresponde_reduccion = 1 on ALL records in
# dj931_registros_tipo4 across ALL tenant schemas.
#
# Background:
#   The corresponde_reduccion field (position 227 in AFIP SICOSS v42 TXT)
#   indicates whether employer contribution reductions apply.  All existing
#   Registro 4 records need this flag set to 1 because the employer type
#   is "7" (enseñanza privada con reducciones).
#
# Prerequisites:
#   - kubectl context pointing to the correct cluster
#   - Access to the rayuela-prod namespace
#
# Usage:
#   ./scripts/db/update-931-registro4-corresponde-reduccion.sh
# =============================================================================

set -e

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

echo ""
echo -e "${BOLD}══════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}  Update dj931_registros_tipo4 → corresponde_reduccion = 1${NC}"
echo -e "${BOLD}══════════════════════════════════════════════════════${NC}"
echo ""
echo -e "  Namespace:  ${CYAN}${NS}${NC}"
echo -e "  Database:   ${CYAN}${DB}${NC}"
echo -e "  Pod:        ${CYAN}${POD}${NC}"
echo ""

kubectl exec -i "${POD}" -n "${NS}" -- psql -U grex -d "${DB}" <<'EOSQL'
DO $$
DECLARE
    v_schema   TEXT;
    v_count    INTEGER;
    v_total    INTEGER := 0;
BEGIN
    RAISE NOTICE '==========================================';
    RAISE NOTICE 'Setting corresponde_reduccion = 1 on all';
    RAISE NOTICE 'dj931_registros_tipo4 records';
    RAISE NOTICE '==========================================';
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
            'UPDATE %I.dj931_registros_tipo4
                SET corresponde_reduccion = 1
              WHERE corresponde_reduccion <> 1',
            v_schema
        );

        GET DIAGNOSTICS v_count = ROW_COUNT;
        v_total := v_total + v_count;
        RAISE NOTICE '  -> Updated % record(s)', v_count;
    END LOOP;

    RAISE NOTICE '';
    RAISE NOTICE '==========================================';
    RAISE NOTICE 'Done. Total records updated: %', v_total;
    RAISE NOTICE '==========================================';
END
$$;
EOSQL

echo ""
echo -e "${GREEN}${BOLD}Migration complete!${NC}"
echo ""
