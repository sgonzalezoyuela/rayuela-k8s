-- Update legajos.cbu and legajos.banco_id from INST_STELLA_MARIS_-_CBU_MACRO_Y_CBA.xlsx
-- Match: legajos.cuil = 11-digit CUIL (separators stripped)
-- banco_id resolved from public.bancos.codigo (values: MACRO, COR)
-- Review inside the transaction before COMMIT.

BEGIN;

UPDATE legajos SET
    cbu      = '2850705940095872134638',
    banco_id = (SELECT id FROM public.bancos WHERE codigo = 'MACRO')
WHERE cuil = '23370934819';  -- Castillo José Andres

UPDATE legajos SET
    cbu      = '2850705940094996255858',
    banco_id = (SELECT id FROM public.bancos WHERE codigo = 'MACRO')
WHERE cuil = '27333714197';  -- López  María Magdalena

UPDATE legajos SET
    cbu      = '0200322911000012298044',
    banco_id = (SELECT id FROM public.bancos WHERE codigo = 'COR')
WHERE cuil = '27295366244';  -- Silva Lucía Valeria

UPDATE legajos SET
    cbu      = '0200322911000001921494',
    banco_id = (SELECT id FROM public.bancos WHERE codigo = 'COR')
WHERE cuil = '20179743117';  -- Delía  Juan Pablo

UPDATE legajos SET
    cbu      = '2850705940096074237488',
    banco_id = (SELECT id FROM public.bancos WHERE codigo = 'MACRO')
WHERE cuil = '27179441131';  -- Altamirano  Claudia Roxana

UPDATE legajos SET
    cbu      = '2850705940095363119298',
    banco_id = (SELECT id FROM public.bancos WHERE codigo = 'MACRO')
WHERE cuil = '27393962173';  -- Quiroga Anahi Aylen

UPDATE legajos SET
    cbu      = '2850705940095452368538',
    banco_id = (SELECT id FROM public.bancos WHERE codigo = 'MACRO')
WHERE cuil = '27391726952';  -- Brito Lucila Belén

UPDATE legajos SET
    cbu      = '0200322911000014172380',
    banco_id = (SELECT id FROM public.bancos WHERE codigo = 'COR')
WHERE cuil = '27274682391';  -- Suau Mercedes Belén

UPDATE legajos SET
    cbu      = '2850705940095482537528',
    banco_id = (SELECT id FROM public.bancos WHERE codigo = 'MACRO')
WHERE cuil = '27396128956';  -- Barrera Anahi Esmeralda

UPDATE legajos SET
    cbu      = '0200322911000001766130',
    banco_id = (SELECT id FROM public.bancos WHERE codigo = 'COR')
WHERE cuil = '27270342618';  -- Saldaña  Mariana Emilia

UPDATE legajos SET
    cbu      = '2850705940000010669280',
    banco_id = (SELECT id FROM public.bancos WHERE codigo = 'MACRO')
WHERE cuil = '20285302278';  -- López  Ginés

UPDATE legajos SET
    cbu      = '2850705940095158652098',
    banco_id = (SELECT id FROM public.bancos WHERE codigo = 'MACRO')
WHERE cuil = '27263224286';  -- Cuadrado  María Belén

UPDATE legajos SET
    cbu      = '2850705940095634924958',
    banco_id = (SELECT id FROM public.bancos WHERE codigo = 'MACRO')
WHERE cuil = '20424412377';  -- Manzanares Gonzalo

UPDATE legajos SET
    cbu      = '2850705940095502266258',
    banco_id = (SELECT id FROM public.bancos WHERE codigo = 'MACRO')
WHERE cuil = '27404191662';  -- Gomez  Elizabeth

UPDATE legajos SET
    cbu      = '0200322911000054061008',
    banco_id = (SELECT id FROM public.bancos WHERE codigo = 'COR')
WHERE cuil = '27214792813';  -- García  María Beatriz

UPDATE legajos SET
    cbu      = '0200322911000001385858',
    banco_id = (SELECT id FROM public.bancos WHERE codigo = 'COR')
WHERE cuil = '20333716322';  -- Calderón  Carlos Micael

UPDATE legajos SET
    cbu      = '2850705940096074237488',
    banco_id = (SELECT id FROM public.bancos WHERE codigo = 'MACRO')
WHERE cuil = '27179441131';  -- Altamirano  Claudia Roxana

UPDATE legajos SET
    cbu      = '0200322911000001923230',
    banco_id = (SELECT id FROM public.bancos WHERE codigo = 'COR')
WHERE cuil = '23252297189';  -- Calderon Cristian Javier

UPDATE legajos SET
    cbu      = '0200322911000012573376',
    banco_id = (SELECT id FROM public.bancos WHERE codigo = 'COR')
WHERE cuil = '27134842674';  -- Coli Graciela Elizabeth

UPDATE legajos SET
    cbu      = '0200322911000014145430',
    banco_id = (SELECT id FROM public.bancos WHERE codigo = 'COR')
WHERE cuil = '27362200585';  -- Palacio  Eliana Guadalupe

UPDATE legajos SET
    cbu      = '2850705940096074308928',
    banco_id = (SELECT id FROM public.bancos WHERE codigo = 'MACRO')
WHERE cuil = '27306927405';  -- MORETTA CALVO ANDREA JIMENA

UPDATE legajos SET
    cbu      = '0200322911000012218862',
    banco_id = (SELECT id FROM public.bancos WHERE codigo = 'COR')
WHERE cuil = '20361396678';  -- TELLO CRISTIAN MARTIN

UPDATE legajos SET
    cbu      = '0200322911000014451744',
    banco_id = (SELECT id FROM public.bancos WHERE codigo = 'COR')
WHERE cuil = '20219337796';  -- HURVITZ PABLO ADRIAN

UPDATE legajos SET
    cbu      = '0200322911000014451676',
    banco_id = (SELECT id FROM public.bancos WHERE codigo = 'COR')
WHERE cuil = '27218192233';  -- Altamirano  Ana Mariela

UPDATE legajos SET
    cbu      = '0200322911000030119644',
    banco_id = (SELECT id FROM public.bancos WHERE codigo = 'COR')
WHERE cuil = '20265674853';  -- Zarate Lucas David

UPDATE legajos SET
    cbu      = '0200322911000001929962',
    banco_id = (SELECT id FROM public.bancos WHERE codigo = 'COR')
WHERE cuil = '23238237424';  -- Asia Maria Paula

UPDATE legajos SET
    cbu      = '2850705940094920687058',
    banco_id = (SELECT id FROM public.bancos WHERE codigo = 'MACRO')
WHERE cuil = '20238690251';  -- BUSTO MARIO RUBEN

UPDATE legajos SET
    cbu      = '2850705940094993063128',
    banco_id = (SELECT id FROM public.bancos WHERE codigo = 'MACRO')
WHERE cuil = '23224899733';  -- Quiroga Alicia Ester Quiroga

UPDATE legajos SET
    cbu      = '2850705940000010686658',
    banco_id = (SELECT id FROM public.bancos WHERE codigo = 'MACRO')
WHERE cuil = '27222240811';  -- Gómez  Sonia Eliana

UPDATE legajos SET
    cbu      = '20020032910999998464',
    banco_id = (SELECT id FROM public.bancos WHERE codigo = 'COR')
WHERE cuil = '27245902544';  -- Aguero Marisa

COMMIT;
-- ROLLBACK;  -- use instead of COMMIT to discard

-- ===========================================================================
-- MALFORMED SOURCE ROWS — NOT APPLIED. Fix at source, then run manually.
-- ===========================================================================
-- Aguero Marisa: CUIL has 10 digits (expected 11); CBU has 20 digits (expected 22)
-- UPDATE legajos SET
--     cbu      = '20020032910999998464',
--     banco_id = (SELECT id FROM public.bancos WHERE codigo = 'COR')
-- WHERE cuil = '2724590254';  -- Aguero Marisa

-- Gómez  Sonia Eliana: CUIL has 8 digits (expected 11)
-- UPDATE legajos SET
--     cbu      = '2850705940000010686658',
--     banco_id = (SELECT id FROM public.bancos WHERE codigo = 'MACRO')
-- WHERE cuil = '27222240811';  -- Gómez  Sonia Eliana
