-- =============================================================================
-- update-fecha-alta-legajos.sql
-- =============================================================================
-- Maintenance data fix: set each legajo's fecha_alta to the EARLIEST (minimum)
-- fecha_desde among its ACTIVE posiciones (posiciones.estado = 'ACTIVO'),
-- applied across ALL tenant schemas (every tenant_% schema).
--
-- Inactive posiciones (estado = 'INACTIVO') are ignored. Legajos with no active
-- posiciones are left untouched (fecha_alta is NOT NULL and cannot be derived
-- from zero rows); the per-schema count of those is emitted as a NOTICE.
--
-- legajos.version is intentionally NOT bumped (consistent with the other one-off
-- fix update-fecha-escalafon.sql). Run during a maintenance window.
--
-- Run (psql):
--   psql -U grex -d rayuela -f env/prod/sql/update-fecha-alta-legajos.sql
--
-- In-cluster (prod) example:
--   kubectl cp env/prod/sql/update-fecha-alta-legajos.sql \
--     rayuela-prod/rayuela-db-0:/tmp/update-fecha-alta-legajos.sql
--   kubectl exec -it rayuela-db-0 -n rayuela-prod -- \
--     psql -U grex -d rayuela -f /tmp/update-fecha-alta-legajos.sql
--
-- Single tenant only: add a filter to the FOR loop below, e.g.
--   AND schema_name = 'tenant_<uuid>'
--
-- Dry run: change the final COMMIT to ROLLBACK to roll back every update while
-- still printing the per-schema NOTICE report.
-- =============================================================================

\set ON_ERROR_STOP on

BEGIN;

DO $$
DECLARE
    v_schema   TEXT;
    v_changed  INTEGER;
    v_noactive INTEGER;
    v_total    INTEGER := 0;
BEGIN
    FOR v_schema IN
        SELECT schema_name FROM information_schema.schemata
         WHERE schema_name LIKE 'tenant_%'
         ORDER BY schema_name
    LOOP
        -- Count legajos with no ACTIVE posiciones (these stay unchanged).
        EXECUTE format(
            'SELECT count(*) FROM %I.legajos l
              WHERE NOT EXISTS (
                  SELECT 1 FROM %I.posiciones p
                   WHERE p.legajo_id = l.id AND p.estado = ''ACTIVO'')',
            v_schema, v_schema)
        INTO v_noactive;

        -- Apply: fecha_alta <- earliest fecha_desde among ACTIVE posiciones.
        EXECUTE format(
            'UPDATE %I.legajos l
                SET fecha_alta = p.min_fecha_desde
                FROM (SELECT legajo_id, MIN(fecha_desde) AS min_fecha_desde
                        FROM %I.posiciones
                       WHERE estado = ''ACTIVO''
                       GROUP BY legajo_id) p
               WHERE l.id = p.legajo_id
                 AND l.fecha_alta IS DISTINCT FROM p.min_fecha_desde',
            v_schema, v_schema);
        GET DIAGNOSTICS v_changed = ROW_COUNT;
        v_total := v_total + v_changed;

        RAISE NOTICE 'Schema % -> % legajo(s) updated; % legajo(s) with no active posiciones (unchanged)',
            v_schema, v_changed, v_noactive;
    END LOOP;

    RAISE NOTICE '==========================================';
    RAISE NOTICE 'Done. Total legajos updated: %', v_total;
    RAISE NOTICE '==========================================';
END $$;

COMMIT;
