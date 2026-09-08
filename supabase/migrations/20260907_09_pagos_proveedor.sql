-- Pagos a proveedores (Cuentas por Pagar)
CREATE TABLE IF NOT EXISTS pagos_proveedor (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    compra_id UUID REFERENCES compras_proveedor(id) ON DELETE CASCADE,
    monto DECIMAL(12, 2) NOT NULL,
    fecha_pago TIMESTAMPTZ DEFAULT NOW(),
    metodo_pago TEXT NOT NULL,
    referencia TEXT,
    comprobante_url TEXT,
    notas TEXT,
    usuario_id UUID,
    organizacion_id UUID,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Habilitar RLS
ALTER TABLE pagos_proveedor ENABLE ROW LEVEL SECURITY;

-- Políticas de seguridad para pagos_proveedor
CREATE POLICY "Usuarios pueden ver pagos a proveedores de su organización"
    ON pagos_proveedor FOR SELECT
    USING (organizacion_id = auth.uid() OR organizacion_id IN (
        SELECT organizacion_id FROM perfiles_organizacion WHERE usuario_id = auth.uid()
    ));

CREATE POLICY "Usuarios pueden insertar pagos a proveedores"
    ON pagos_proveedor FOR INSERT
    WITH CHECK (organizacion_id = auth.uid() OR organizacion_id IN (
        SELECT organizacion_id FROM perfiles_organizacion WHERE usuario_id = auth.uid()
    ));

CREATE POLICY "Usuarios pueden actualizar pagos a proveedores"
    ON pagos_proveedor FOR UPDATE
    USING (organizacion_id = auth.uid() OR organizacion_id IN (
        SELECT organizacion_id FROM perfiles_organizacion WHERE usuario_id = auth.uid()
    ));

CREATE POLICY "Usuarios pueden eliminar pagos a proveedores"
    ON pagos_proveedor FOR DELETE
    USING (organizacion_id = auth.uid() OR organizacion_id IN (
        SELECT organizacion_id FROM perfiles_organizacion WHERE usuario_id = auth.uid()
    ));
