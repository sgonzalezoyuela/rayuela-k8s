-- Modalidades de Contratación (Employment Contract Modality Codes) for Rayuela
-- Extracted from dev/modContratacion/mod-contratacion.txt (AFIP/ARCA registry)
-- UUIDs are deterministic based on codigo + desde for reproducibility
--
-- Source date format YYYYMM is converted to DATE (YYYY-MM-01).
-- Only currently active entries (hasta = NULL) are included.

INSERT INTO modalidades_contratacion (id, codigo, desde, hasta, descripcion, aporte_obra_social, contribucion_obra_social, version) VALUES
    ('00000000-0000-4000-b001-000020180200', 1, '2018-02-01', NULL, 'A tiempo parcial: Indeterminado /permanente', TRUE, TRUE, 0),
    ('00000000-0000-4000-b002-000019960600', 2, '1996-06-01', NULL, 'Becarios- Residencias médicas Ley 22127', FALSE, FALSE, 0),
    ('00000000-0000-4000-b003-000019981000', 3, '1998-10-01', NULL, 'De aprendizaje l.25013', TRUE, TRUE, 0),
    ('00000000-0000-4000-b008-000020180200', 8, '2018-02-01', NULL, 'A Tiempo completo indeterminado /Trabajo permanente', TRUE, TRUE, 0),
    ('00000000-0000-4000-b010-000020090100', 10, '2009-01-01', NULL, 'Práctica profesionalizante-Dcto. 1374/11-Pasantías -sin obra social', FALSE, FALSE, 0),
    ('00000000-0000-4000-b011-000020180200', 11, '2018-02-01', NULL, 'Trabajo de temporada.', TRUE, TRUE, 0),
    ('00000000-0000-4000-b012-000020180200', 12, '2018-02-01', NULL, 'Trabajo eventual.', TRUE, TRUE, 0),
    ('00000000-0000-4000-b014-000020180200', 14, '2018-02-01', NULL, 'Nuevo Período de Prueba.', TRUE, TRUE, 0)
ON CONFLICT (codigo, desde) DO UPDATE SET
    hasta = EXCLUDED.hasta,
    descripcion = EXCLUDED.descripcion,
    aporte_obra_social = EXCLUDED.aporte_obra_social,
    contribucion_obra_social = EXCLUDED.contribucion_obra_social,
    version = EXCLUDED.version;
