-- ==========================================
-- Migración para Rediseño UI y Nuevos Módulos
-- ==========================================

-- 1. Añadir nuevos campos a cotizaciones
ALTER TABLE cotizaciones
ADD COLUMN IF NOT EXISTS estado_produccion text DEFAULT 'Pendiente',
ADD COLUMN IF NOT EXISTS fecha_entrega timestamptz;

-- 2. Crear tabla de categorías de producto
CREATE TABLE IF NOT EXISTS categorias_producto (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organizacion_id uuid NOT NULL REFERENCES organizaciones(id) ON DELETE CASCADE,
  nombre text NOT NULL,
  color text,
  icono text,
  orden int DEFAULT 0,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE categorias_producto ENABLE ROW LEVEL SECURITY;

CREATE POLICY "rls_categorias_producto" ON categorias_producto 
  FOR ALL TO authenticated 
  USING (organizacion_id = get_current_org_id()) 
  WITH CHECK (organizacion_id = get_current_org_id());

-- 3. Crear tabla de campos dinámicos para clientes (capas de personalización)
CREATE TABLE IF NOT EXISTS categorias_cliente (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organizacion_id uuid NOT NULL REFERENCES organizaciones(id) ON DELETE CASCADE,
  nombre text NOT NULL,
  color text,
  icono text,
  orden int DEFAULT 0,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE categorias_cliente ENABLE ROW LEVEL SECURITY;

CREATE POLICY "rls_categorias_cliente" ON categorias_cliente 
  FOR ALL TO authenticated 
  USING (organizacion_id = get_current_org_id()) 
  WITH CHECK (organizacion_id = get_current_org_id());

-- 4. Añadir columnas de categoría foráneas a productos y clientes
ALTER TABLE productos
ADD COLUMN IF NOT EXISTS categoria_id uuid REFERENCES categorias_producto(id) ON DELETE SET NULL,
ADD COLUMN IF NOT EXISTS imagen_url text;

ALTER TABLE clientes
ADD COLUMN IF NOT EXISTS categoria_id uuid REFERENCES categorias_cliente(id) ON DELETE SET NULL,
ADD COLUMN IF NOT EXISTS origen_lead text,
ADD COLUMN IF NOT EXISTS giro_empresa text;
