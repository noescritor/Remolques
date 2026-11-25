-- Diagnóstico de solo lectura: stock_actual vs movimientos_inventario y compras Recibida
-- Uso: ejecutar en el SQL Editor de Supabase (antes y después del despliegue). Solo SELECT.

-- 1. Comparación por producto: stock_actual contra suma neta de movimientos
WITH movs AS (
  SELECT
    organizacion_id,
    producto_id,
    COALESCE(SUM(
      CASE
        WHEN tipo_movimiento IN ('Entrada', 'Devolucion_Interna', 'Devolucion_Cliente') THEN cantidad
        WHEN tipo_movimiento IN ('Salida', 'Devolucion_Proveedor') THEN -cantidad
        WHEN tipo_movimiento = 'Ajuste' THEN cantidad
        ELSE 0
      END
    ), 0) AS neto_movimientos,
    COUNT(*) AS total_movimientos
  FROM public.movimientos_inventario
  GROUP BY organizacion_id, producto_id
)
SELECT
  p.organizacion_id,
  p.id AS producto_id,
  p.nombre,
  COALESCE(p.stock_actual, 0) AS stock_actual,
  COALESCE(m.neto_movimientos, 0) AS neto_movimientos,
  COALESCE(p.stock_actual, 0) - COALESCE(m.neto_movimientos, 0) AS diferencia,
  COALESCE(m.total_movimientos, 0) AS total_movimientos
FROM public.productos p
LEFT JOIN movs m
  ON m.organizacion_id = p.organizacion_id
 AND m.producto_id = p.id
WHERE p.tipo = 'bien'
  AND (COALESCE(p.stock_actual, 0) <> COALESCE(m.neto_movimientos, 0) OR COALESCE(m.total_movimientos, 0) > 0)
ORDER BY ABS(COALESCE(p.stock_actual, 0) - COALESCE(m.neto_movimientos, 0)) DESC, p.nombre;

-- 2. Compras marcadas como 'Recibida' y verificación de sus movimientos 'Compra <folio>'
SELECT
  cp.organizacion_id,
  cp.id AS compra_id,
  cp.folio,
  cp.fecha,
  cp.estado,
  (SELECT COUNT(*) FROM public.compra_items ci WHERE ci.compra_id = cp.id) AS total_partidas,
  (SELECT COALESCE(SUM(ci.cantidad), 0) FROM public.compra_items ci WHERE ci.compra_id = cp.id) AS suma_cantidad_partidas,
  (SELECT COUNT(*) FROM public.movimientos_inventario mi
    WHERE mi.organizacion_id = cp.organizacion_id
      AND mi.tipo_movimiento = 'Entrada'
      AND mi.referencia = 'Compra ' || cp.folio) AS movimientos_entrada,
  (SELECT COALESCE(SUM(mi.cantidad), 0) FROM public.movimientos_inventario mi
    WHERE mi.organizacion_id = cp.organizacion_id
      AND mi.tipo_movimiento = 'Entrada'
      AND mi.referencia = 'Compra ' || cp.folio) AS suma_movimientos_entrada
FROM public.compras_proveedor cp
WHERE cp.estado = 'Recibida'
ORDER BY cp.fecha DESC, cp.folio;

-- 3. Compras Pendiente sin partidas (para decisión antes/después del despliegue)
SELECT
  cp.organizacion_id,
  cp.id AS compra_id,
  cp.folio,
  cp.fecha,
  cp.estado
FROM public.compras_proveedor cp
LEFT JOIN public.compra_items ci ON ci.compra_id = cp.id
WHERE cp.estado = 'Pendiente'
GROUP BY cp.organizacion_id, cp.id, cp.folio, cp.fecha, cp.estado
HAVING COUNT(ci.id) = 0
ORDER BY cp.fecha DESC;
