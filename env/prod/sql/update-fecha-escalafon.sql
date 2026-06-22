-- =============================================================================
-- update-fecha-escalafon.sql
-- =============================================================================
-- One-off data fix: set legajos.fecha_escalafon = "FECHA ANTIG" (fecha de
-- antiguedad) for the legajos listed in the two source CSVs, matching by DNI
-- scoped to each business unit.
--
-- Source files (transcribed into the VALUES list below):
--   env/prod/sql/alberdi.csv       -> Inst. Alberdi - Secundaria      (code ALBE)
--   env/prod/sql/stella_maris.csv  -> Inst. Agrotecnico Stella Maris  (code SMAR)
--
-- CSV columns: DNI, FECHA ALTA, FECHA ANTIG  (dates are DD/MM/YYYY).
-- Only the 3rd column (FECHA ANTIG) is used; FECHA ALTA is ignored.
--
-- Why scope by business unit: the legajos UNIQUE constraint is
-- (dni, business_unit_id), so a DNI is only unique *within* a business unit.
-- Each CSV belongs to one school, so every row is matched on (dni, bu).
--
-- Tenant: Obispado de Cruz del Eje
--
-- Run (from a host with kubectl access to the prod cluster):
--   kubectl cp env/prod/sql/update-fecha-escalafon.sql \
--     rayuela-prod/rayuela-db-0:/tmp/update-fecha-escalafon.sql
--   kubectl exec -it rayuela-db-0 -n rayuela-prod -- \
--     psql -U grex -d rayuela -f /tmp/update-fecha-escalafon.sql
--
-- Dry run: change the final COMMIT to ROLLBACK to preview the report below
-- without persisting any changes.
-- =============================================================================

\set ON_ERROR_STOP on

BEGIN;

SET search_path = 'tenant_f780d30d-20a4-4d0a-a2f7-b3a1523eb3d6';

-- Staging table holding the CSV rows: (business-unit code, dni, fecha antiguedad)
CREATE TEMP TABLE _fecha_antig (
    bu_code     text NOT NULL,
    dni         text NOT NULL,
    fecha_antig date NOT NULL
) ON COMMIT DROP;

INSERT INTO _fecha_antig (bu_code, dni, fecha_antig) VALUES
    -- ---- Inst. Alberdi - Secundaria (alberdi.csv) ----
    ('ALBE', '16561942', to_date('01/04/2009', 'DD/MM/YYYY')),
    ('ALBE', '16613182', to_date('05/06/2003', 'DD/MM/YYYY')),
    ('ALBE', '16858321', to_date('22/04/1996', 'DD/MM/YYYY')),
    ('ALBE', '22702216', to_date('01/03/2011', 'DD/MM/YYYY')),
    ('ALBE', '23335299', to_date('15/02/2018', 'DD/MM/YYYY')),
    ('ALBE', '23445547', to_date('01/05/2003', 'DD/MM/YYYY')),
    ('ALBE', '23456778', to_date('01/03/1996', 'DD/MM/YYYY')),
    ('ALBE', '24975582', to_date('06/04/2004', 'DD/MM/YYYY')),
    ('ALBE', '25427595', to_date('01/03/2011', 'DD/MM/YYYY')),
    ('ALBE', '25517975', to_date('23/10/2001', 'DD/MM/YYYY')),
    ('ALBE', '25532901', to_date('01/03/2005', 'DD/MM/YYYY')),
    ('ALBE', '25771483', to_date('04/02/2024', 'DD/MM/YYYY')),
    ('ALBE', '25921988', to_date('01/04/2001', 'DD/MM/YYYY')),
    ('ALBE', '27846336', to_date('02/03/2022', 'DD/MM/YYYY')),
    ('ALBE', '27898379', to_date('22/09/2007', 'DD/MM/YYYY')),
    ('ALBE', '28246779', to_date('30/07/2003', 'DD/MM/YYYY')),
    ('ALBE', '28482835', to_date('25/08/2006', 'DD/MM/YYYY')),
    ('ALBE', '28580118', to_date('02/10/2003', 'DD/MM/YYYY')),
    ('ALBE', '30375255', to_date('20/03/2006', 'DD/MM/YYYY')),
    ('ALBE', '33371553', to_date('20/03/2019', 'DD/MM/YYYY')),
    ('ALBE', '33515277', to_date('26/02/2025', 'DD/MM/YYYY')),
    ('ALBE', '33654327', to_date('24/06/2014', 'DD/MM/YYYY')),
    ('ALBE', '33810065', to_date('04/06/2011', 'DD/MM/YYYY')),
    ('ALBE', '34673063', to_date('09/08/2016', 'DD/MM/YYYY')),
    ('ALBE', '35170532', to_date('20/10/2022', 'DD/MM/YYYY')),
    ('ALBE', '35676423', to_date('01/07/2016', 'DD/MM/YYYY')),
    ('ALBE', '35882535', to_date('21/04/2024', 'DD/MM/YYYY')),
    ('ALBE', '37875357', to_date('05/11/2017', 'DD/MM/YYYY')),
    ('ALBE', '40396699', to_date('02/03/2026', 'DD/MM/YYYY')),
    ('ALBE', '40572625', to_date('13/10/2025', 'DD/MM/YYYY')),
    -- ---- Inst. Agrotecnico Stella Maris (stella_maris.csv) ----
    ('SMAR', '13484267', to_date('01/07/2007', 'DD/MM/YYYY')),
    ('SMAR', '13858165', to_date('01/04/2004', 'DD/MM/YYYY')),
    ('SMAR', '17944113', to_date('01/09/1987', 'DD/MM/YYYY')),
    ('SMAR', '17974311', to_date('01/08/2001', 'DD/MM/YYYY')),
    ('SMAR', '18535902', to_date('01/03/1996', 'DD/MM/YYYY')),
    ('SMAR', '20212160', to_date('01/03/2003', 'DD/MM/YYYY')),
    ('SMAR', '20212173', to_date('01/04/1999', 'DD/MM/YYYY')),
    ('SMAR', '21479281', to_date('01/08/1993', 'DD/MM/YYYY')),
    ('SMAR', '21784421', to_date('25/06/2009', 'DD/MM/YYYY')),
    ('SMAR', '21819223', to_date('01/03/1996', 'DD/MM/YYYY')),
    ('SMAR', '21933779', to_date('01/06/1997', 'DD/MM/YYYY')),
    ('SMAR', '21941342', to_date('01/04/1997', 'DD/MM/YYYY')),
    ('SMAR', '22224081', to_date('01/03/2006', 'DD/MM/YYYY')),
    ('SMAR', '22499105', to_date('20/06/1996', 'DD/MM/YYYY')),
    ('SMAR', '22568459', to_date('15/03/2018', 'DD/MM/YYYY')),
    ('SMAR', '23114611', to_date('11/03/2005', 'DD/MM/YYYY')),
    ('SMAR', '23823742', to_date('01/03/2000', 'DD/MM/YYYY')),
    ('SMAR', '23869025', to_date('01/10/1994', 'DD/MM/YYYY')),
    ('SMAR', '24149742', to_date('01/03/1995', 'DD/MM/YYYY')),
    ('SMAR', '24590254', to_date('01/08/2002', 'DD/MM/YYYY')),
    ('SMAR', '24590285', to_date('24/09/2025', 'DD/MM/YYYY')),
    ('SMAR', '24680091', to_date('23/07/2012', 'DD/MM/YYYY')),
    ('SMAR', '24942761', to_date('29/09/2003', 'DD/MM/YYYY')),
    ('SMAR', '25008992', to_date('30/09/2001', 'DD/MM/YYYY')),
    ('SMAR', '25229718', to_date('01/03/2005', 'DD/MM/YYYY')),
    ('SMAR', '25750763', to_date('03/01/2001', 'DD/MM/YYYY')),
    ('SMAR', '26322428', to_date('01/06/2006', 'DD/MM/YYYY')),
    ('SMAR', '27034261', to_date('01/08/2001', 'DD/MM/YYYY')),
    ('SMAR', '27468239', to_date('07/02/2019', 'DD/MM/YYYY')),
    ('SMAR', '28530227', to_date('05/07/2005', 'DD/MM/YYYY')),
    ('SMAR', '29536624', to_date('01/05/2003', 'DD/MM/YYYY')),
    ('SMAR', '30180267', to_date('01/03/2007', 'DD/MM/YYYY')),
    ('SMAR', '30941185', to_date('15/10/2012', 'DD/MM/YYYY')),
    ('SMAR', '32256284', to_date('03/03/2008', 'DD/MM/YYYY')),
    ('SMAR', '32458820', to_date('12/12/2022', 'DD/MM/YYYY')),
    ('SMAR', '32979599', to_date('14/09/2023', 'DD/MM/YYYY')),
    ('SMAR', '33371419', to_date('05/03/2018', 'DD/MM/YYYY')),
    ('SMAR', '33371632', to_date('24/03/2018', 'DD/MM/YYYY')),
    ('SMAR', '35080057', to_date('31/10/2025', 'DD/MM/YYYY')),
    ('SMAR', '35636123', to_date('22/03/2017', 'DD/MM/YYYY')),
    ('SMAR', '36139667', to_date('25/11/2015', 'DD/MM/YYYY')),
    ('SMAR', '36220058', to_date('18/03/2015', 'DD/MM/YYYY')),
    ('SMAR', '37492038', to_date('01/08/2023', 'DD/MM/YYYY')),
    ('SMAR', '39172695', to_date('27/07/2022', 'DD/MM/YYYY')),
    ('SMAR', '39396217', to_date('11/11/2022', 'DD/MM/YYYY')),
    ('SMAR', '39612895', to_date('01/07/2023', 'DD/MM/YYYY')),
    ('SMAR', '40419166', to_date('27/09/2023', 'DD/MM/YYYY')),
    ('SMAR', '42441237', to_date('01/08/2023', 'DD/MM/YYYY'));

-- Report any source rows with no matching legajo (these are NOT updated).
\echo ''
\echo '-- Source rows with no matching legajo (dni not found in its business unit):'
SELECT s.bu_code, s.dni, to_char(s.fecha_antig, 'DD/MM/YYYY') AS fecha_antig
FROM _fecha_antig s
LEFT JOIN business_units bu ON bu.code = s.bu_code
LEFT JOIN legajos        l  ON l.dni = s.dni AND l.business_unit_id = bu.id
WHERE l.id IS NULL
ORDER BY s.bu_code, s.dni;

-- Apply the update: fecha_escalafon <- FECHA ANTIG, matched on (dni, business_unit).
UPDATE legajos l
SET    fecha_escalafon = s.fecha_antig
FROM   _fecha_antig s
JOIN   business_units bu ON bu.code = s.bu_code
WHERE  l.dni = s.dni
  AND  l.business_unit_id = bu.id;

-- Per-business-unit summary of legajos now carrying the expected fecha_escalafon.
\echo ''
\echo '-- Legajos with fecha_escalafon set from source, per business unit:'
SELECT bu.code AS bu, count(*) AS legajos_set
FROM _fecha_antig s
JOIN business_units bu ON bu.code = s.bu_code
JOIN legajos        l  ON l.dni = s.dni
                      AND l.business_unit_id = bu.id
                      AND l.fecha_escalafon = s.fecha_antig
GROUP BY bu.code
ORDER BY bu.code;

COMMIT;
