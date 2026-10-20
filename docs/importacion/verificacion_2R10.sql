-- Script de verificación para Sub-bloque 2R-10:
-- Matracas hasta 20 piezas y varios sistemas retráctiles por equipo
-- Verifica que los 4 grupos tengan seleccion = 'multiple_con_cantidad' y sus reglas max_total y cantidad_defecto

SELECT 
    clave,
    nombre,
    seleccion,
    regla,
    cantidad,
    unidad_precio,
    notas,
    (seleccion = 'multiple_con_cantidad') AS seleccion_ok,
    CASE 
        WHEN clave = 'rines' THEN regla = '{"max_total":{"por_eje":4},"cantidad_defecto":"max"}'::jsonb
        WHEN clave = 'llantas' THEN regla = '{"max_total":{"por_eje":4},"cantidad_defecto":"max"}'::jsonb
        WHEN clave = 'matracas' THEN regla = '{"max_total":{"fija":20},"cantidad_defecto":12}'::jsonb
        WHEN clave = 'retractil' THEN regla = '{"max_total":{"por_eje":1},"cantidad_defecto":1}'::jsonb
        ELSE false
    END AS regla_ok,
    (notas = 'import-2r10') AS notas_ok
FROM grupos_configuracion
WHERE clave IN ('rines', 'llantas', 'matracas', 'retractil')
ORDER BY clave;
