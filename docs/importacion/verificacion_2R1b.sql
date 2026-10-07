SELECT 
    'materiales_nuevos' AS metrica,
    (SELECT count(*) FROM productos WHERE descripcion = 'SIN PRECIO') AS valor
UNION ALL
SELECT
    'lineas_receta_base_por_modelo' AS metrica,
    (SELECT count(*) FROM receta_base WHERE modelo_id = (SELECT id FROM modelos WHERE tipo = 'plataforma' LIMIT 1)) AS valor
UNION ALL
SELECT
    'componentes_por_opcion_total' AS metrica,
    (SELECT count(*) FROM opcion_componentes) AS valor
UNION ALL
SELECT
    'lineas_base_sin_material' AS metrica,
    (SELECT count(*) FROM receta_base WHERE material_id IS NULL) AS valor
UNION ALL
SELECT
    'consumible_65_plataforma_2_40' AS metrica,
    (SELECT sum(cantidad) FROM receta_base WHERE material_id = (SELECT id FROM productos WHERE nombre = 'CONSUMIBLE 65' LIMIT 1) AND modelo_id = (SELECT id FROM modelos WHERE tipo = 'plataforma' AND num_ejes = 2 AND largo_ft = 40)) AS valor;
