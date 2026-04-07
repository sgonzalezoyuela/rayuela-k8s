-- =============================================================================
-- Migration 002: Add Convenio "Escala Salarial Docente - CBA"
-- =============================================================================
-- Target database: grext1 (applies to public schema via search_path)
--
-- PREREQUISITE: DDL schema changes must be applied BEFORE this migration.
--   The new schema must have:
--   - convenios table in public schema
--   - convenio_id column on cargos table
--   - convenio_id + alias columns on conceptos table (fecha_desde/hasta,
--     remunerativo, bonificable removed)
--   - concepto_versiones table in public schema
--   - empresas_convenios table in tenant schema
--
-- Apply to running prod:
--   kubectl exec -it rayuela-db-0 -n rayuela-prod -- \
--     psql -U grex -d grext1 -f /sql/002-add-convenio-escala-salarial.sql
--
-- Safe to re-run (all statements use ON CONFLICT / conditional updates).
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Insert the Convenio
-- -----------------------------------------------------------------------------
INSERT INTO convenios (id, codigo, descripcion, version)
VALUES (
    '00000000-0000-4000-8000-000000000001',
    'ESC-DOC-CBA',
    'Escala Salarial Docente - CBA',
    0
)
ON CONFLICT (codigo) DO NOTHING;

-- -----------------------------------------------------------------------------
-- 2. Assign all existing cargos to this convenio
-- Only updates rows where convenio_id is still NULL (not yet assigned).
-- -----------------------------------------------------------------------------
UPDATE cargos
SET convenio_id = '00000000-0000-4000-8000-000000000001'
WHERE convenio_id IS NULL;

-- -----------------------------------------------------------------------------
-- 3. Assign all existing conceptos to this convenio and set alias = codigo
-- Only updates rows where convenio_id is still NULL (not yet assigned).
-- alias defaults to codigo (matching the JPA entity init block behavior).
-- -----------------------------------------------------------------------------
UPDATE conceptos
SET convenio_id = '00000000-0000-4000-8000-000000000001',
    alias = codigo
WHERE convenio_id IS NULL;

-- -----------------------------------------------------------------------------
-- 4. Create initial concepto_versiones from old concepto temporal data
-- This migrates fecha_desde/hasta, remunerativo, bonificable from the old
-- conceptos columns (if they still exist) into concepto_versiones rows.
-- Only creates versions for conceptos that don't already have one.
--
-- NOTE: This step assumes the old temporal columns still exist at migration
-- time. If the DDL migration already dropped them, skip this step and run
-- the concepto-versiones-data.sql seed file instead.
-- -----------------------------------------------------------------------------
-- Uncomment the block below if old temporal columns are still available:
--
-- INSERT INTO concepto_versiones (id, concepto_id, fecha_desde, fecha_hasta,
--     remunerativo, bonificable, formulas, dependencias, version)
-- SELECT
--     gen_random_uuid(), id, fecha_desde, fecha_hasta,
--     remunerativo, bonificable, '{}'::jsonb, '[]'::jsonb, 0
-- FROM conceptos
-- WHERE NOT EXISTS (
--     SELECT 1 FROM concepto_versiones cv WHERE cv.concepto_id = conceptos.id
-- );
--
-- If old columns are already dropped, run concepto-versiones-data.sql instead:
--   kubectl exec -it rayuela-db-0 -n rayuela-prod -- \
--     psql -U grex -d grext1 -f /sql/concepto-versiones-data.sql

-- -----------------------------------------------------------------------------
-- 5. Link Business Units to the Convenio
-- Both Inst. Alberdi - Secundaria and Inst. Agrotécnico Stella Maris
-- are linked to the Escala Salarial Docente - CBA convenio.
-- -----------------------------------------------------------------------------

-- Inst. Alberdi - Secundaria -> Escala Salarial Docente - CBA
INSERT INTO empresas_convenios (empresa_id, convenio_id)
VALUES (
    '10000000-0000-0000-0002-000000000001',
    '00000000-0000-4000-8000-000000000001'
)
ON CONFLICT (empresa_id, convenio_id) DO NOTHING;

-- Inst. Agrotécnico Stella Maris -> Escala Salarial Docente - CBA
INSERT INTO empresas_convenios (empresa_id, convenio_id)
VALUES (
    '10000000-0000-0000-0002-000000000002',
    '00000000-0000-4000-8000-000000000001'
)
ON CONFLICT (empresa_id, convenio_id) DO NOTHING;
