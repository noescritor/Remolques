-- ============================================================================
-- 01c_productos_terminados.sql                  SOLO LECTURA (un solo SELECT)
-- Muestra, por cada producto terminado, el tamaño de su receta y 3 señales
-- de los defectos que trae la migración del 1-oct (20261001_03_migracion_bom.sql):
--   lineas_de_piso      -> debe ser 1; si es 8 hay TODOS los pisos sumados
--   lineas_mano_de_obra -> debe ser 0; la mano de obra no es un material
--   cantidad_maxima     -> si es 3000 o 50, el PRECIO se cargó como CANTIDAD
-- Pegar todas las filas del resultado.
-- ============================================================================
SELECT p.nombre                                                        AS producto_terminado,
       count(pm.id)                                                    AS lineas,
       count(*) FILTER (WHERE m.nombre ILIKE 'PISO%')                  AS lineas_de_piso,
       count(*) FILTER (WHERE m.nombre ILIKE 'MANO DE OBRA%'
                           OR m.nombre ILIKE 'MONTADA%')               AS lineas_mano_de_obra,
       max(pm.cantidad)                                                AS cantidad_maxima
FROM productos p
LEFT JOIN producto_materiales pm ON pm.producto_id = p.id
LEFT JOIN productos m            ON m.id = pm.material_id
WHERE p.tipo_item = 'producto_terminado'
GROUP BY p.nombre
ORDER BY p.nombre;
