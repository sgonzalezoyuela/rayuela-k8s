-- Actividades (National Activity Codes) for Rayuela
-- Based on dev/actividades/actividades.txt (AFIP activity classification)
-- UUIDs are deterministic sequential for reproducibility
-- Safe to re-run: skips existing rows (ON CONFLICT DO NOTHING).
--

INSERT INTO actividades (id, codigo, desde, hasta, descripcion, aporte_obra_social, contribucion_obra_social, version) VALUES
    ('00000000-0000-4000-b000-000000000001', 7, '1994-07-01', NULL, 'Enseñanza Privada L.13047 no comprendidos en el D 137/05', true, true, 0),
    ('00000000-0000-4000-b000-000000000015', 15, '2009-03-01', NULL, 'L.R.T.-Directores SA, municipios, org, cent y descent. Emp mixt provin y otros-', true, true, 0),
    ('00000000-0000-4000-b000-000000000016', 16, '1994-07-01', NULL, 'No obligados con el SIJP (colegios, reciprocidad previsional y otros)', true, true, 0),
    ('00000000-0000-4000-b000-000000000038', 38, '2005-05-01', NULL, 'Docentes privados Res 71/99 SSS - Dec 137/05', true, true, 0),
    ('00000000-0000-4000-b000-000000000039', 39, '2005-05-01', NULL, 'No docentes privados Res 71/99 SSS', true, true, 0),
    ('00000000-0000-4000-b000-000000000049', 49, '1994-07-01', NULL, 'Actividades no Clasificadas', true, true, 0),
    ('00000000-0000-4000-b000-000000000084', 84, '2005-07-01', NULL, 'Docentes privados Res 71/99 SSS - Dec 137/05 sin Obra Social', false, false, 0)
ON CONFLICT DO NOTHING;
