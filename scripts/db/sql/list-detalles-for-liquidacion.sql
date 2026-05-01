-- =============================================================================
-- list-detalles-for-liquidacion.sql — All detalles for one liquidación
-- =============================================================================
-- Returns one row per (legajo, cargo, concepto). For a detalle with no
-- detalle_conceptos rows (rare), the concepto columns will come back NULL.
--
-- ── Required: replace the placeholder UUID below ────────────────────────────
-- The `params` CTE is the single point where you change the liquidacion id.
--
-- Tenant-scoped: set search_path first, e.g.
--     SET search_path TO "tenant_<uuid>", public;
--
-- Find candidate liquidaciones with:
--     SELECT id, fecha_pago, fecha_desde, fecha_hasta, estado
--       FROM liquidaciones
--      ORDER BY fecha_pago DESC LIMIT 20;
-- =============================================================================

WITH params AS (
    SELECT '00000000-0000-0000-0000-000000000000'::uuid AS liquidacion_id
)
SELECT
    l.cuil,
    l.apellido || ', ' || l.nombre   AS legajo,
    bu.code                          AS business_unit,
    car.codigo                       AS cargo_codigo,
    car.descripcion                  AS cargo,
    d.centro_costo,
    d.dias_trabajados,
    d.horas,
    d.horas_50,
    d.horas_100,
    co.codigo                        AS concepto_codigo,
    co.alias                         AS concepto_alias,
    co.descripcion                   AS concepto,
    dc.tipo                          AS concepto_tipo,   -- 'H' = haber, 'D' = descuento
    dc.importe
FROM detalles                  d
JOIN posiciones                p   ON p.id   = d.posicion_id
JOIN legajos                   l   ON l.id   = p.legajo_id
JOIN business_units            bu  ON bu.id  = l.business_unit_id
LEFT JOIN public.cargos        car ON car.id = d.cargo_id
LEFT JOIN detalle_conceptos    dc  ON dc.detalle_id = d.id
LEFT JOIN public.conceptos     co  ON co.id  = dc.concepto_id
WHERE d.liquidacion_id = (SELECT liquidacion_id FROM params)
ORDER BY l.apellido, l.nombre, car.codigo, dc.tipo, co.codigo;
