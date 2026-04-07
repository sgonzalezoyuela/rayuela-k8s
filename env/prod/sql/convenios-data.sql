-- =============================================================================
-- Convenios (Salary Agreements) - Shared Catalog Data
-- =============================================================================
-- Public schema seed data for the convenios table.
-- Each convenio groups a set of cargos and conceptos under a single agreement.
-- This data is identical for all environments (dev, prod).
--
-- UUIDs are deterministic for reproducibility.
-- =============================================================================

INSERT INTO convenios (id, codigo, descripcion, version) VALUES
    ('00000000-0000-4000-8000-000000000001', 'ESC-DOC-CBA', 'Escala Salarial Docente - CBA', 0)
ON CONFLICT (codigo) DO UPDATE SET
    descripcion = EXCLUDED.descripcion,
    version = EXCLUDED.version;
