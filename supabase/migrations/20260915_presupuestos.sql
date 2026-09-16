CREATE TABLE IF NOT EXISTS presupuestos (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    organizacion_id uuid NOT NULL REFERENCES organizaciones(id) ON DELETE CASCADE,
    cliente_id text REFERENCES clientes(id) ON DELETE SET NULL,
    folio text NOT NULL,
    nomenclatura_id text,
    fecha timestamptz DEFAULT now(),
    concepto text,
    datos jsonb DEFAULT '{}'::jsonb,
    total_costo numeric DEFAULT 0,
    precio_venta numeric DEFAULT 0,
    created_at timestamptz DEFAULT now()
);

ALTER TABLE presupuestos ENABLE ROW LEVEL SECURITY;

CREATE POLICY "rls_presupuestos" ON presupuestos
    FOR ALL TO authenticated
    USING (organizacion_id = get_current_org_id())
    WITH CHECK (organizacion_id = get_current_org_id());
