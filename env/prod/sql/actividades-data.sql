-- Actividades (National Activity Codes) for Rayuela
-- Based on dev/actividades/actividades.txt (AFIP activity classification)
-- UUIDs are deterministic sequential for reproducibility
--

INSERT INTO actividades (id, codigo, desde, hasta, descripcion, aporte_obra_social, contribucion_obra_social, version) VALUES
    ('00000000-0000-4000-b000-000000000001', 7, '1994-07-01', NULL, 'Enseñanza Privada L.13047 no comprendidos en el D 137/05', true, true, 0);
