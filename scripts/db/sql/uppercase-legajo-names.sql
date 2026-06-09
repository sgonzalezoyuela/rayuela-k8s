-- =============================================================================
-- uppercase-legajo-names.sql — Uppercase nombre/apellido on legajos
-- =============================================================================
-- Tenant-scoped UPDATE. Set the search_path to the tenant whose legajos you
-- want to update *before* running this file (works in any client — harlequin,
-- psql, DataGrip, …):
--
--     SET search_path TO "tenant_<uuid>", public;
--
-- List available tenant schemas with:
--     SELECT schema_name FROM information_schema.schemata
--      WHERE schema_name LIKE 'tenant_%' ORDER BY schema_name;
--
-- Only touches rows where nombre or apellido is not already uppercase, and
-- returns the affected rows so you can eyeball the result.
-- =============================================================================

UPDATE legajos
   SET nombre   = upper(nombre),
       apellido = upper(apellido)
 WHERE nombre   IS DISTINCT FROM upper(nombre)
    OR apellido IS DISTINCT FROM upper(apellido)
RETURNING cuil, apellido, nombre;
