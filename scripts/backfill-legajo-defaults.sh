#!/usr/bin/env bash
# =============================================================================
# backfill-legajo-defaults.sh - One-time backfill of catalog defaults on legajos
# =============================================================================
# Sets the following catalog values on ALL legajos across ALL tenant schemas:
#   - modalidad_contratacion_id  ->  codigo 8  (A Tiempo completo indeterminado)
#   - situacion_revista_nac_id   ->  codigo 1  vigente (Activo)
#   - actividad_id               ->  codigo 7  (Enseñanza Privada L.13047)
#   - zona_id                    ->  codigo 16 (Cordoba - San Alberto)
#   - condicion                  ->  '01'
#
# Prerequisites: catalog seed data must already be loaded (actividades, zonas,
#   modalidades_contratacion, situaciones_revista_nac).
#
# Usage:
#   ./scripts/backfill-legajo-defaults.sh
# =============================================================================

set -e

NS="rayuela-prod"
DB="rayuela"
POD="rayuela-db-0"

echo "=========================================="
echo "Backfill legajo default catalog values"
echo "=========================================="
echo "Namespace: ${NS}"
echo "Database:  ${DB}"
echo "Pod:       ${POD}"
echo ""

kubectl exec -it "${POD}" -n "${NS}" -- psql -U grex -d "${DB}" <<'EOSQL'
DO $$
DECLARE
    v_modalidad_id UUID;
    v_situacion_id UUID;
    v_actividad_id UUID;
    v_zona_id      UUID;
    v_schema       TEXT;
    v_count        INTEGER;
    v_total        INTEGER := 0;
BEGIN
    -- ----------------------------------------------------------------
    -- 1. Resolve catalog UUIDs from public schema
    --    INTO STRICT fails if not exactly 1 row (safety check)
    -- ----------------------------------------------------------------
    SELECT id INTO STRICT v_modalidad_id
      FROM public.modalidades_contratacion
     WHERE codigo = 8 AND hasta IS NULL;

    SELECT id INTO STRICT v_situacion_id
      FROM public.situaciones_revista_nac
     WHERE codigo = 1 AND hasta IS NULL;

    SELECT id INTO STRICT v_actividad_id
      FROM public.actividades
     WHERE codigo = 49 AND hasta IS NULL;

    SELECT id INTO STRICT v_zona_id
      FROM public.zonas
     WHERE codigo = '16';

    RAISE NOTICE 'Resolved catalog UUIDs:';
    RAISE NOTICE '  modalidad_contratacion (codigo 8) : %', v_modalidad_id;
    RAISE NOTICE '  situacion_revista_nac  (codigo 1) : %', v_situacion_id;
    RAISE NOTICE '  actividad              (codigo 7) : %', v_actividad_id;
    RAISE NOTICE '  zona                   (codigo 16): %', v_zona_id;
    RAISE NOTICE '';

    -- ----------------------------------------------------------------
    -- 2. Loop through every tenant schema and update all legajos
    -- ----------------------------------------------------------------
    FOR v_schema IN
        SELECT schema_name
          FROM information_schema.schemata
         WHERE schema_name LIKE 'tenant_%'
         ORDER BY schema_name
    LOOP
        RAISE NOTICE 'Processing schema: %', v_schema;

        EXECUTE format(
            'UPDATE %I.legajos SET
                modalidad_contratacion_id = $1,
                situacion_revista_nac_id  = $2,
                actividad_id              = $3,
                zona_id                   = $4,
                condicion                 = ''01''',
            v_schema
        ) USING v_modalidad_id, v_situacion_id, v_actividad_id, v_zona_id;

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
echo "Backfill complete!"
