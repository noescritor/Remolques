-- Migración 2: Proveedores

CREATE TABLE IF NOT EXISTS proveedores (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    organizacion_id uuid NOT NULL REFERENCES organizaciones(id) ON DELETE CASCADE,
    nombre text NOT NULL,
    contacto text,
    telefono text,
    tiempo_entrega_dias integer DEFAULT 0,
    condiciones_pago text,
    created_at timestamptz DEFAULT now()
);

ALTER TABLE proveedores ENABLE ROW LEVEL SECURITY;

CREATE POLICY "rls_proveedores" ON proveedores
    FOR ALL TO authenticated
    USING (organizacion_id = get_current_org_id())
    WITH CHECK (organizacion_id = get_current_org_id());

CREATE TABLE IF NOT EXISTS proveedor_materiales (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    proveedor_id uuid NOT NULL REFERENCES proveedores(id) ON DELETE CASCADE,
    material_id text NOT NULL REFERENCES productos(id) ON DELETE CASCADE,
    created_at timestamptz DEFAULT now(),
    UNIQUE (proveedor_id, material_id)
);

ALTER TABLE proveedor_materiales ENABLE ROW LEVEL SECURITY;

CREATE POLICY "rls_proveedor_materiales" ON proveedor_materiales
    FOR ALL TO authenticated
    USING (
        proveedor_id IN (SELECT id FROM proveedores WHERE organizacion_id = get_current_org_id())
    )
    WITH CHECK (
        proveedor_id IN (SELECT id FROM proveedores WHERE organizacion_id = get_current_org_id())
    );
