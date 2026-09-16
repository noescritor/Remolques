-- Migración: Tablero de Producción (Catálogos y Kanban)

CREATE TABLE IF NOT EXISTS lineas_producto (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    clave text NOT NULL UNIQUE,
    nombre text NOT NULL,
    grupo text,
    organizacion_id uuid REFERENCES organizaciones(id) ON DELETE CASCADE,
    created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS fases_produccion (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    linea_producto_id uuid NOT NULL REFERENCES lineas_producto(id) ON DELETE CASCADE,
    orden integer NOT NULL,
    nombre text NOT NULL,
    organizacion_id uuid REFERENCES organizaciones(id) ON DELETE CASCADE,
    created_at timestamptz DEFAULT now(),
    UNIQUE (linea_producto_id, orden)
);

-- Modificar ordenes_trabajo existente
ALTER TABLE ordenes_trabajo 
ADD COLUMN IF NOT EXISTS linea_producto_id uuid REFERENCES lineas_producto(id) ON DELETE SET NULL,
ADD COLUMN IF NOT EXISTS orden_relacionada_id uuid REFERENCES ordenes_trabajo(id) ON DELETE SET NULL,
ADD COLUMN IF NOT EXISTS fase_actual_id uuid REFERENCES fases_produccion(id) ON DELETE SET NULL,
ADD COLUMN IF NOT EXISTS estado_kanban text DEFAULT 'pendiente' CHECK (estado_kanban IN ('pendiente', 'en_proceso', 'pausada', 'incompleta', 'en_espera', 'completada')),
ADD COLUMN IF NOT EXISTS material_faltante text;

CREATE TABLE IF NOT EXISTS historial_fases (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    orden_trabajo_id uuid NOT NULL REFERENCES ordenes_trabajo(id) ON DELETE CASCADE,
    fase_id uuid REFERENCES fases_produccion(id) ON DELETE SET NULL,
    estado text NOT NULL,
    usuario_id uuid, -- Reference auth.users usually, but since we don't have strict auth binding here, uuid is fine
    organizacion_id uuid REFERENCES organizaciones(id) ON DELETE CASCADE,
    fecha_cambio timestamptz DEFAULT now()
);

ALTER TABLE lineas_producto ENABLE ROW LEVEL SECURITY;
ALTER TABLE fases_produccion ENABLE ROW LEVEL SECURITY;
ALTER TABLE historial_fases ENABLE ROW LEVEL SECURITY;

CREATE POLICY "rls_lineas_producto" ON lineas_producto FOR ALL TO authenticated
    USING (organizacion_id = get_current_org_id()) WITH CHECK (organizacion_id = get_current_org_id());

CREATE POLICY "rls_fases_produccion" ON fases_produccion FOR ALL TO authenticated
    USING (organizacion_id = get_current_org_id()) WITH CHECK (organizacion_id = get_current_org_id());

CREATE POLICY "rls_historial_fases" ON historial_fases FOR ALL TO authenticated
    USING (organizacion_id = get_current_org_id()) WITH CHECK (organizacion_id = get_current_org_id());
