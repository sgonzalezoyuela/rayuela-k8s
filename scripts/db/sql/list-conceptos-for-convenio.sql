-- =============================================================================
-- list-conceptos-for-convenio.sql — All conceptos for one convenio
-- =============================================================================
-- Public-schema query (no tenant search_path required).
--
-- ── Required: replace the placeholder convenio code below ───────────────────
-- The `params` CTE is the single point where you change the convenio. By
-- default this filters on convenios.codigo (most readable for humans). To
-- filter by id instead, swap the active SELECT/WHERE pair for the commented
-- one further down.
--
-- List candidate convenios with:
--     SELECT codigo, descripcion FROM convenios ORDER BY codigo;
-- =============================================================================

WITH params AS (
    SELECT 'UOMA'::varchar AS convenio_codigo
    -- , '00000000-0000-0000-0000-000000000000'::uuid AS convenio_id
)
SELECT
    cv.codigo                AS convenio_codigo,
    cv.descripcion           AS convenio,
    co.codigo                AS concepto_codigo,
    co.alias,
    co.descripcion           AS concepto,
    co.tipo                  AS tipo,             -- 'H' = haber, 'D' = descuento
    co.tipo_configuracion    AS configuracion,    -- 'S' = simple, 'E' = escala
    co.created_at
FROM conceptos                co
JOIN convenios                cv ON cv.id = co.convenio_id
WHERE cv.codigo = (SELECT convenio_codigo FROM params)
-- WHERE cv.id  = (SELECT convenio_id     FROM params)
ORDER BY co.tipo, co.codigo;
