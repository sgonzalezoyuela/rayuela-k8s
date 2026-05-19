-- =============================================================================
-- list-cuil-cargo-for-empresa.sql — (cuil, cargo_codigo) pairs for one empresa
-- =============================================================================
-- Tenant-scoped. Set search_path first, e.g.
--     SET search_path TO "tenant_<uuid>", public;
--
-- Returns one row per distinct (legajo.cuil, cargo.codigo) pair across the
-- posiciones of legajos belonging to the given empresa (business_unit). The
-- empresa is identified by business_units.code.
--
-- ── Required: replace the placeholder empresa code below ────────────────────
-- The `params` CTE is the single point where you change the empresa.
--
-- List candidate empresas with:
--     SELECT code, name FROM business_units ORDER BY code;
-- =============================================================================

WITH params AS (
    SELECT 'EMPRESA-XYZ'::varchar AS empresa_code
)
SELECT
    l.cuil,
    c.codigo AS posicion_codigo
FROM legajos          l
JOIN business_units   bu ON bu.id       = l.business_unit_id
JOIN posiciones       p  ON p.legajo_id = l.id
JOIN public.cargos    c  ON c.id        = p.cargo_id
WHERE bu.code = (SELECT empresa_code FROM params)
GROUP BY l.cuil, c.codigo
ORDER BY l.cuil, c.codigo;
