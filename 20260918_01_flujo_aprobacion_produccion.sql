
-- Migración para Flujo de Aprobación, Producción y Compras (Bloque 1)

-- 1. Actualizar tabla productos con tipo_item
ALTER TABLE productos 
ADD COLUMN IF NOT EXISTS tipo_item TEXT CHECK (tipo_item IN ('producto_terminado', 'materia_prima'));

-- 2. Tabla BOM (producto_materiales)
-- La tabla ya existía, así que añadimos las columnas faltantes
ALTER TABLE producto_materiales 
ADD COLUMN IF NOT EXISTS organizacion_id UUID REFERENCES organizaciones(id) ON DELETE CASCADE;

DO $$
BEGIN
  IF EXISTS(SELECT 1
    FROM information_schema.columns
    WHERE table_name='producto_materiales' and column_name='cantidad_por_unidad')
  THEN
      ALTER TABLE producto_materiales RENAME COLUMN cantidad_por_unidad TO cantidad;
  END IF;
END $$;

ALTER TABLE producto_materiales 
ADD COLUMN IF NOT EXISTS cantidad NUMERIC NOT NULL DEFAULT 1;

-- Índices para búsqueda rápida
CREATE INDEX IF NOT EXISTS idx_producto_materiales_producto ON producto_materiales(producto_id);
CREATE INDEX IF NOT EXISTS idx_producto_materiales_org ON producto_materiales(organizacion_id);

-- Habilitar RLS en producto_materiales
ALTER TABLE producto_materiales ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Acceso a producto_materiales por organizacion" ON producto_materiales;
CREATE POLICY "Acceso a producto_materiales por organizacion" ON producto_materiales
    FOR ALL
    USING (organizacion_id = get_current_org_id())
    WITH CHECK (organizacion_id = get_current_org_id());

-- 3. Actualizar compras_proveedor con folio y estado
ALTER TABLE compras_proveedor
ADD COLUMN IF NOT EXISTS folio TEXT;

-- Opcional: asegurarnos de que la tabla compra_items tenga todo correcto
ALTER TABLE compra_items
ADD COLUMN IF NOT EXISTS material_id UUID REFERENCES productos(id) ON DELETE SET NULL;

-- 4. Función SQL atómica para ajustar el stock previniendo race conditions
CREATE OR REPLACE FUNCTION ajustar_stock(p_producto_id UUID, p_delta NUMERIC)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE productos
    SET stock_actual = COALESCE(stock_actual, 0) + p_delta
    WHERE id = p_producto_id;
END;
$$;

-- 5. Secuencia para nomenclatura de órdenes de producción (usada en generar-ordenes)
CREATE SEQUENCE IF NOT EXISTS seq_produccion_folio START 100;

CREATE OR REPLACE FUNCTION obtener_siguiente_produccion()
RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    next_val INT;
BEGIN
    next_val := nextval('seq_produccion_folio');
    RETURN next_val;
END;
$$;
