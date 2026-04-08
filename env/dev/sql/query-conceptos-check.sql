-- Query to verify concepto + concepto_versiones data
SELECT
    c.codigo,
    c.descripcion AS nombre,
    cv.remunerativo,
    cv.bonificable
FROM conceptos c
JOIN concepto_versiones cv ON cv.concepto_id = c.id
ORDER BY c.tipo, c.codigo;
