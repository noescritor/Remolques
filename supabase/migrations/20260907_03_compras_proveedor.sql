-- Migración 3: Compras a Proveedor

CREATE TABLE IF NOT EXISTS compras_proveedor (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    organizacion_id uuid NOT NULL REFERENCES organizaciones(id) ON DELETE CASCADE,
    folio text NOT NULL,
    cotizacion_id text REFERENCES cotizaciones(id) ON DELETE SET NULL,
    proveedor_id uuid REFERENCES proveedores(id) ON DELETE SET NULL,
    estado text DEFAULT 'Pendiente' CHECK (estado IN ('Pendiente', 'Recibida', 'Cancelada')),
    fecha timestamptz DEFAULT now(),
    created_at timestamptz DEFAULT now()
);

ALTER TABLE compras_proveedor ENABLE ROW LEVEL SECURITY;

CREATE POLICY "rls_compras_proveedor" ON compras_proveedor
    FOR ALL TO authenticated
    USING (organizacion_id = get_current_org_id())
    WITH CHECK (organizacion_id = get_current_org_id());

CREATE TABLE IF NOT EXISTS compra_items (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    compra_id uuid NOT NULL REFERENCES compras_proveedor(id) ON DELETE CASCADE,
    material_id text NOT NULL REFERENCES productos(id) ON DELETE CASCADE,
    cantidad numeric NOT NULL CHECK (cantidad > 0),
    costo_unitario numeric NOT NULL CHECK (costo_unitario >= 0),
    created_at timestamptz DEFAULT now()
);

ALTER TABLE compra_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "rls_compra_items" ON compra_items
    FOR ALL TO authenticated
    USING (
        compra_id IN (SELECT id FROM compras_proveedor WHERE organizacion_id = get_current_org_id())
    )
    WITH CHECK (
        compra_id IN (SELECT id FROM compras_proveedor WHERE organizacion_id = get_current_org_id())
    );
