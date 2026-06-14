-- Agregar columna stock_reservado a productos
ALTER TABLE productos ADD COLUMN stock_reservado INT DEFAULT 0;

-- Crear tabla de movimientos_inventario
CREATE TABLE movimientos_inventario (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organizacion_id UUID NOT NULL REFERENCES organizaciones(id) ON DELETE CASCADE,
  producto_id TEXT NOT NULL REFERENCES productos(id) ON DELETE CASCADE,
  tipo_movimiento TEXT NOT NULL CHECK (tipo_movimiento IN ('Entrada', 'Salida', 'Reserva', 'Liberacion', 'Ajuste')),
  cantidad INT NOT NULL,
  referencia TEXT,
  cotizacion_id TEXT REFERENCES cotizaciones(id) ON DELETE SET NULL,
  usuario_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Habilitar RLS en movimientos_inventario
ALTER TABLE movimientos_inventario ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Usuarios ven movimientos de su org" ON movimientos_inventario FOR SELECT USING (organizacion_id IN (SELECT organizacion_id FROM perfiles_organizacion WHERE usuario_id = auth.uid()));
CREATE POLICY "Usuarios insertan movimientos en su org" ON movimientos_inventario FOR INSERT WITH CHECK (organizacion_id IN (SELECT organizacion_id FROM perfiles_organizacion WHERE usuario_id = auth.uid()));
CREATE POLICY "Usuarios actualizan movimientos de su org" ON movimientos_inventario FOR UPDATE USING (organizacion_id IN (SELECT organizacion_id FROM perfiles_organizacion WHERE usuario_id = auth.uid()));
CREATE POLICY "Usuarios borran movimientos de su org" ON movimientos_inventario FOR DELETE USING (organizacion_id IN (SELECT organizacion_id FROM perfiles_organizacion WHERE usuario_id = auth.uid()));

-- FUNCION Y TRIGGER PARA ACTUALIZAR STOCK AL CAMBIAR ESTADO DE COTIZACION
CREATE OR REPLACE FUNCTION procesar_inventario_por_cotizacion()
RETURNS TRIGGER AS $$
DECLARE
  rec RECORD;
BEGIN
  IF NEW.estado = 'Aprobada' AND OLD.estado IS DISTINCT FROM 'Aprobada' THEN
    FOR rec IN SELECT i.organizacion_id, i.producto_id, i.cantidad FROM items_cotizacion i JOIN productos p ON i.producto_id = p.id WHERE i.cotizacion_id = NEW.id AND p.tipo = 'bien' LOOP
      INSERT INTO movimientos_inventario (organizacion_id, producto_id, tipo_movimiento, cantidad, referencia, cotizacion_id)
      VALUES (rec.organizacion_id, rec.producto_id, 'Reserva', rec.cantidad, 'Reserva por Cotización ' || NEW.folio, NEW.id);
      
      UPDATE productos SET stock_reservado = stock_reservado + rec.cantidad WHERE id = rec.producto_id;
    END LOOP;
  ELSIF NEW.estado = 'Pagada' AND OLD.estado IS DISTINCT FROM 'Pagada' THEN
    FOR rec IN SELECT i.organizacion_id, i.producto_id, i.cantidad FROM items_cotizacion i JOIN productos p ON i.producto_id = p.id WHERE i.cotizacion_id = NEW.id AND p.tipo = 'bien' LOOP
      IF OLD.estado = 'Aprobada' THEN
        INSERT INTO movimientos_inventario (organizacion_id, producto_id, tipo_movimiento, cantidad, referencia, cotizacion_id)
        VALUES (rec.organizacion_id, rec.producto_id, 'Salida', rec.cantidad, 'Venta (Stock reservado liquidado) Cotización ' || NEW.folio, NEW.id);
        
        UPDATE productos SET stock_actual = stock_actual - rec.cantidad, stock_reservado = stock_reservado - rec.cantidad WHERE id = rec.producto_id;
      ELSE
        INSERT INTO movimientos_inventario (organizacion_id, producto_id, tipo_movimiento, cantidad, referencia, cotizacion_id)
        VALUES (rec.organizacion_id, rec.producto_id, 'Salida', rec.cantidad, 'Venta Directa Cotización ' || NEW.folio, NEW.id);
        
        UPDATE productos SET stock_actual = stock_actual - rec.cantidad WHERE id = rec.producto_id;
      END IF;
    END LOOP;
  ELSIF NEW.estado IN ('Cancelada', 'Rechazada') AND OLD.estado = 'Aprobada' THEN
    FOR rec IN SELECT i.organizacion_id, i.producto_id, i.cantidad FROM items_cotizacion i JOIN productos p ON i.producto_id = p.id WHERE i.cotizacion_id = NEW.id AND p.tipo = 'bien' LOOP
      INSERT INTO movimientos_inventario (organizacion_id, producto_id, tipo_movimiento, cantidad, referencia, cotizacion_id)
      VALUES (rec.organizacion_id, rec.producto_id, 'Liberacion', rec.cantidad, 'Liberación por Cancelación ' || NEW.folio, NEW.id);
      
      UPDATE productos SET stock_reservado = stock_reservado - rec.cantidad WHERE id = rec.producto_id;
    END LOOP;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_procesar_inventario
AFTER UPDATE OF estado ON cotizaciones
FOR EACH ROW
EXECUTE FUNCTION procesar_inventario_por_cotizacion();
