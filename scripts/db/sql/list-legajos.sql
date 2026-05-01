-- =============================================================================
-- list-legajos.sql — List all legajos in the current tenant
-- =============================================================================
-- Tenant-scoped query. Set the search_path to the tenant whose legajos you
-- want to inspect *before* running this file (works in any client — harlequin,
-- psql, DataGrip, …):
--
--     SET search_path TO "tenant_<uuid>", public;
--
-- List available tenant schemas with:
--     SELECT schema_name FROM information_schema.schemata
--      WHERE schema_name LIKE 'tenant_%' ORDER BY schema_name;
--
-- For a multi-tenant view across every schema at once, use
-- scripts/db/list-legajos.sh (which UNION ALLs them in bash).
-- =============================================================================

SELECT
    l.cuil,
    l.dni,
    l.apellido,
    l.nombre,
    bu.code                          AS business_unit,
    l.fecha_alta,
    l.fecha_baja,
    l.activo,
    l.condicion,
    l.obra_social_codigo             AS obra_social,
    z.codigo                         AS zona,
    a.codigo                         AS actividad,
    mc.codigo                        AS modalidad_contratacion,
    sr.codigo                        AS situacion_revista_nac,
    l.importado_automaticamente      AS importado,
    l.created_at
FROM legajos                              l
JOIN business_units                       bu ON bu.id = l.business_unit_id
LEFT JOIN public.zonas                    z  ON z.id  = l.zona_id
LEFT JOIN public.actividades              a  ON a.id  = l.actividad_id
LEFT JOIN public.modalidades_contratacion mc ON mc.id = l.modalidad_contratacion_id
LEFT JOIN public.situaciones_revista_nac  sr ON sr.id = l.situacion_revista_nac_id
ORDER BY l.activo DESC, bu.code, l.apellido, l.nombre;
