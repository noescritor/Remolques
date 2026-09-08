-- Migración 1: Materiales y Lista de Materiales (BOM)

ALTER TABLE productos 
ADD COLUMN IF NOT EXISTS tipo_item text DEFAULT 'producto_terminado' 
CHECK (tipo_item IN ('producto_terminado', 'materia_prima'));

CREATE TABLE IF NOT EXISTS producto_materiales (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    producto_id TEXT NOT NULL REFERENCES productos(id) ON DELETE CASCADE,
    material_id TEXT NOT NULL REFERENCES productos(id) ON DELETE CASCADE,
    cantidad_por_unidad numeric NOT NULL CHECK (cantidad_por_unidad > 0),
    created_at timestamptz DEFAULT now(),
    UNIQUE (producto_id, material_id)
);

ALTER TABLE producto_materiales ENABLE ROW LEVEL SECURITY;

CREATE POLICY "rls_producto_materiales" ON producto_materiales
    FOR ALL TO authenticated
    USING (
        producto_id IN (SELECT id FROM productos WHERE organizacion_id = get_current_org_id())
    )
    WITH CHECK (
        producto_id IN (SELECT id FROM productos WHERE organizacion_id = get_current_org_id())
    );
