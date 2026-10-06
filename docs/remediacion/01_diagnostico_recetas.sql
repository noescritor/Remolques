-- 01_diagnostico_recetas.sql
-- Ejecutar en el SQL Editor de Supabase
-- Propósito: Ver qué productos terminados tienen recetas afectadas por la carga plana del bloque anterior

-- 1. Resumen de recetas afectadas
SELECT 
    p.nombre AS producto,
    COUNT(pm.material_id) AS total_materiales,
    SUM(pm.cantidad) AS suma_total_cantidades
FROM 
    productos p
JOIN 
    producto_materiales pm ON p.id = pm.producto_id
WHERE 
    p.tipo_item = 'producto_terminado'
GROUP BY 
    p.nombre
ORDER BY 
    total_materiales DESC;

-- 2. Conteo de llantas/rines o ejes anormales (indicador claro de problema)
SELECT 
    p.nombre AS producto,
    m.nombre AS material,
    pm.cantidad
FROM 
    productos p
JOIN 
    producto_materiales pm ON p.id = pm.producto_id
JOIN 
    productos m ON pm.material_id = m.id
WHERE 
    p.tipo_item = 'producto_terminado' 
    AND (m.nombre ILIKE '%LLANTA%' OR m.nombre ILIKE '%RIN%' OR m.nombre ILIKE '%EJE%')
    AND pm.cantidad > 4 -- Cualquier remolque con más de 4 ejes o más de 12 llantas sumadas indica problema
ORDER BY 
    pm.cantidad DESC;
