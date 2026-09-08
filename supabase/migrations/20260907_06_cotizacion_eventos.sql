-- Migración 6: Bitácora de Trazabilidad

CREATE TABLE IF NOT EXISTS cotizacion_eventos (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    organizacion_id uuid NOT NULL REFERENCES organizaciones(id) ON DELETE CASCADE,
    cotizacion_id text NOT NULL REFERENCES cotizaciones(id) ON DELETE CASCADE,
    evento text NOT NULL,
    usuario_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at timestamptz DEFAULT now()
);

ALTER TABLE cotizacion_eventos ENABLE ROW LEVEL SECURITY;

CREATE POLICY "rls_cotizacion_eventos" ON cotizacion_eventos
    FOR ALL TO authenticated
    USING (organizacion_id = get_current_org_id())
    WITH CHECK (organizacion_id = get_current_org_id());
