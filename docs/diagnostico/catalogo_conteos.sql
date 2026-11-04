-- ============================================================================
-- DIAGNÓSTICO DE CONTEOS: CATÁLOGO DE PRODUCTOS Y TABLAS DEL COTIZADOR
-- Script de solo lectura para ejecutar en SQL Editor de Supabase
-- No modifica ninguna fila ni estructura de datos.
-- ============================================================================

-- 1. Resumen general de la tabla `productos`
SELECT 
    COUNT(*) AS total_productos,
    COUNT(CASE WHEN categoria_id IS NULL THEN 1 END) AS productos_sin_categoria,
    COUNT(CASE WHEN categoria_id IS NOT NULL THEN 1 END) AS productos_con_categoria,
    COUNT(CASE WHEN costo IS NULL OR costo = 0 THEN 1 END) AS productos_sin_costo,
    COUNT(CASE WHEN precio_unitario IS NULL OR precio_unitario = 0 THEN 1 END) AS productos_sin_precio_venta
FROM productos;

-- 2. Conteo por `tipo_item`
SELECT 
    COALESCE(tipo_item, '(sin tipo_item)') AS tipo_item,
    COUNT(*) AS total,
    COUNT(CASE WHEN costo IS NULL OR costo = 0 THEN 1 END) AS sin_costo,
    COUNT(CASE WHEN categoria_id IS NULL THEN 1 END) AS sin_categoria
FROM productos
GROUP BY tipo_item
ORDER BY total DESC;

-- 3. Conteo por `categoria_id` y nombre de categoría
SELECT 
    COALESCE(c.nombre, '(Sin categoría / NULL)') AS categoria,
    c.id AS categoria_id,
    COUNT(p.id) AS total_productos,
    COUNT(CASE WHEN p.costo IS NULL OR p.costo = 0 THEN 1 END) AS sin_costo
FROM productos p
LEFT JOIN categorias_producto c ON c.id = p.categoria_id
GROUP BY c.id, c.nombre
ORDER BY total_productos DESC;

-- 4. Conteos en tablas dedicadas del Cotizador (no están en `productos`)
SELECT 
    'acero_materiales' AS tabla,
    COUNT(*) AS total_filas,
    COUNT(CASE WHEN activo = true THEN 1 END) AS filas_activas
FROM acero_materiales
UNION ALL
SELECT 
    'acero_precios' AS tabla,
    COUNT(*) AS total_filas,
    COUNT(CASE WHEN precio IS NOT NULL AND precio > 0 THEN 1 END) AS filas_activas
FROM acero_precios
UNION ALL
SELECT 
    'opciones_configuracion' AS tabla,
    COUNT(*) AS total_filas,
    COUNT(CASE WHEN activo = true THEN 1 END) AS filas_activas
FROM opciones_configuracion
UNION ALL
SELECT 
    'opcion_costos' AS tabla,
    COUNT(*) AS total_filas,
    COUNT(CASE WHEN costo_unitario IS NOT NULL AND costo_unitario > 0 THEN 1 END) AS filas_activas
FROM opcion_costos
UNION ALL
SELECT 
    'opcion_componentes' AS tabla,
    COUNT(*) AS total_filas,
    COUNT(CASE WHEN cantidad > 0 THEN 1 END) AS filas_activas
FROM opcion_componentes;

-- 5. Muestra de productos sin categoría cargados recientemente (primeros 20)
SELECT 
    id,
    nombre,
    tipo_item,
    unidad,
    costo,
    precio_unitario,
    created_at
FROM productos
WHERE categoria_id IS NULL
ORDER BY created_at DESC
LIMIT 20;
