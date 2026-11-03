-- Verificación de esquema y datos para T2 Ronda 2 (Despiece oficial por fases UNION)
-- Debe retornar todo_ok = true y cero inconsistencias de RLS o referencias cruzadas

WITH checks AS (
    SELECT
        (SELECT count(*) FROM fases_despiece) AS total_fases,
        (SELECT count(*) FROM fases_despiece_equivalencias) AS total_equiv,
        (SELECT count(*) FROM productos WHERE notas LIKE '%import-union-2026-11%') AS total_productos_union,
        (SELECT count(*) FROM productos WHERE notas LIKE '%import-union-2026-11%' AND categoria_id IS NOT NULL) AS productos_union_categorizados,
        (SELECT count(*) FROM productos WHERE notas LIKE '%import-union-2026-11%' AND precio_unitario = 0) AS prods_precio_unitario_cero,
        (SELECT count(*) FROM receta_base WHERE fase_id IS NOT NULL) AS recetas_con_fase,
        (SELECT count(*) FROM receta_base WHERE fase_id IS NULL) AS recetas_sin_fase,
        (SELECT count(*) FROM opcion_componentes WHERE fase_id IS NOT NULL) AS opciones_con_fase,
        -- Verificación estricta de aislamiento de tenant (debe ser 0)
        (SELECT count(*)
         FROM receta_base rb
         JOIN modelos m ON m.id = rb.modelo_id
         JOIN fases_despiece f ON f.id = rb.fase_id
         WHERE f.organizacion_id <> m.organizacion_id) AS recetas_fase_cruzada,
        (SELECT count(*)
         FROM opcion_componentes oc
         JOIN opciones_configuracion o ON o.id = oc.opcion_id
         JOIN fases_despiece f ON f.id = oc.fase_id
         WHERE f.organizacion_id <> o.organizacion_id) AS opciones_fase_cruzada
)
SELECT
    total_fases,
    total_equiv,
    total_productos_union,
    productos_union_categorizados,
    prods_precio_unitario_cero,
    recetas_con_fase,
    recetas_sin_fase,
    opciones_con_fase,
    recetas_fase_cruzada,
    opciones_fase_cruzada,
    (
        total_fases >= 14 AND
        total_equiv >= 22 AND
        total_productos_union > 0 AND
        productos_union_categorizados = total_productos_union AND
        prods_precio_unitario_cero = 0 AND
        recetas_sin_fase = 0 AND
        recetas_fase_cruzada = 0 AND
        opciones_fase_cruzada = 0
    ) AS todo_ok
FROM checks;
