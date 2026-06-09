#!/usr/bin/env bash
# =============================================================================
# uppercase-legajo-names.sh - Uppercase nombre/apellido on legajos, all tenants
# =============================================================================
# Updates nombre and apellido to uppercase on ALL legajos across ALL tenant
# schemas. Only touches rows where at least one of the two columns is not
# already uppercase (NULL-safe via IS DISTINCT FROM).
#
# Single-tenant variant (run from any SQL client):
#   scripts/db/sql/uppercase-legajo-names.sql
#
# Usage:
#   ./scripts/db/uppercase-legajo-names.sh
# =============================================================================

set -e

NS="rayuela-prod"
DB="rayuela"
POD="rayuela-db-0"

echo "=========================================="
echo "Uppercase legajo nombre/apellido"
echo "=========================================="
echo "Namespace: ${NS}"
echo "Database:  ${DB}"
echo "Pod:       ${POD}"
echo ""

kubectl exec -it "${POD}" -n "${NS}" -- psql -U grex -d "${DB}" <<'EOSQL'
DO $$
DECLARE
    v_schema TEXT;
    v_count  INTEGER;
    v_total  INTEGER := 0;
BEGIN
    FOR v_schema IN
        SELECT schema_name
          FROM information_schema.schemata
         WHERE schema_name LIKE 'tenant_%'
         ORDER BY schema_name
    LOOP
        RAISE NOTICE 'Processing schema: %', v_schema;

        EXECUTE format(
            'UPDATE %I.legajos
                SET nombre   = upper(nombre),
                    apellido = upper(apellido)
              WHERE nombre   IS DISTINCT FROM upper(nombre)
                 OR apellido IS DISTINCT FROM upper(apellido)',
            v_schema
        );

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
echo "Uppercase update complete!"
