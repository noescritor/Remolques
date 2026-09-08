-- Migración 7: Devoluciones en Movimientos de Inventario

ALTER TABLE movimientos_inventario 
DROP CONSTRAINT IF EXISTS movimientos_inventario_tipo_movimiento_check;

ALTER TABLE movimientos_inventario 
ADD CONSTRAINT movimientos_inventario_tipo_movimiento_check 
CHECK (tipo_movimiento IN ('Entrada', 'Salida', 'Reserva', 'Liberacion', 'Ajuste', 'Devolucion_Interna', 'Devolucion_Cliente', 'Devolucion_Proveedor'));
