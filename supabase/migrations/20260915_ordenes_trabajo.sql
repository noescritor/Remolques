-- Migración: Órdenes de Trabajo y Liberación

CREATE TABLE IF NOT EXISTS ordenes_trabajo (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    organizacion_id uuid NOT NULL REFERENCES organizaciones(id) ON DELETE CASCADE,
    cotizacion_id text NOT NULL REFERENCES cotizaciones(id) ON DELETE CASCADE,
    cliente_id text NOT NULL REFERENCES clientes(id) ON DELETE CASCADE,
    nomenclatura_id text NOT NULL,
    niv text,
    modelo text,
    tipo_equipo text,
    caracteristicas jsonb DEFAULT '{}'::jsonb,
    estado text DEFAULT 'Pendiente' CHECK (estado IN ('Pendiente', 'En Producción', 'Terminado', 'Liberado')),
    fecha_inicio timestamptz,
    fecha_fin timestamptz,
    created_at timestamptz DEFAULT now()
);

ALTER TABLE ordenes_trabajo ENABLE ROW LEVEL SECURITY;

CREATE POLICY "rls_ordenes_trabajo" ON ordenes_trabajo
    FOR ALL TO authenticated
    USING (organizacion_id = get_current_org_id())
    WITH CHECK (organizacion_id = get_current_org_id());

-- Secuencia para el número global en producción (El primer número de la nomenclatura)
CREATE SEQUENCE IF NOT EXISTS seq_produccion_global START 1;
