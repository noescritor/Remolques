-- Script de verificación para Sub-bloque 2R-8:
-- Rines, llantas y matracas con selección mixta y cantidad
-- Verifica que los 3 grupos tengan seleccion = 'multiple_con_cantidad' y sus reglas max_total

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
        WHEN clave IN ('rines', 'llantas') THEN regla = '{"max_total":{"por_eje":4}}'::jsonb
        WHEN clave = 'matracas' THEN regla = '{"max_total":{"fija":12}}'::jsonb
        ELSE false
    END AS regla_ok,
    (notas = 'import-2r8') AS notas_ok
FROM grupos_configuracion
WHERE clave IN ('rines', 'llantas', 'matracas')
ORDER BY clave;
