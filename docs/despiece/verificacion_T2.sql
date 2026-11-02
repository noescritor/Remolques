-- Verificación de esquema y datos para T2 (Despiece por fases UNION)
-- Debe retornar todo_ok = true y conteos positivos

WITH conteos AS (
    SELECT
        (SELECT count(*) FROM fases_despiece) AS total_fases,
        (SELECT count(*) FROM fases_despiece_equivalencias) AS total_equiv,
        (SELECT count(*) FROM productos WHERE notas LIKE '%import-union-2026-11%') AS total_productos_union,
        (SELECT count(*) FROM receta_base WHERE fase_id IS NOT NULL) AS recetas_con_fase,
        (SELECT count(*) FROM opcion_componentes WHERE fase_id IS NOT NULL) AS opciones_con_fase
)
SELECT
    total_fases,
    total_equiv,
    total_productos_union,
    recetas_con_fase,
    opciones_con_fase,
    (total_fases >= 14 AND total_equiv >= 20 AND total_productos_union > 0) AS todo_ok
FROM conteos;
