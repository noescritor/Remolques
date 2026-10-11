BEGIN;

-- 1. opcion_costos
CREATE TABLE IF NOT EXISTS opcion_costos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organizacion_id UUID NOT NULL REFERENCES organizaciones(id) ON DELETE CASCADE,
    opcion_id UUID NOT NULL REFERENCES opciones_configuracion(id) ON DELETE CASCADE,
    tipo_modelo TEXT NOT NULL CHECK (tipo_modelo IN ('plataforma', 'dolly', 'gondola')),
    cantidad_base NUMERIC NOT NULL DEFAULT 1,
    escala TEXT NOT NULL DEFAULT 'fija' CHECK (escala IN ('fija', 'por_eje', 'por_largo')),
    costo_unitario NUMERIC NOT NULL,
    fuente TEXT,
    notas TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(opcion_id, tipo_modelo)
);

ALTER TABLE opcion_costos ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "org_opcion_costos_policy" ON opcion_costos;
CREATE POLICY "org_opcion_costos_policy" ON opcion_costos FOR ALL USING (organizacion_id = get_current_org_id());

CREATE INDEX IF NOT EXISTS idx_opcion_costos_opcion_id ON opcion_costos(opcion_id);
CREATE INDEX IF NOT EXISTS idx_opcion_costos_org_id ON opcion_costos(organizacion_id);

-- 2. procesos_manufactura
CREATE TABLE IF NOT EXISTS procesos_manufactura (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organizacion_id UUID NOT NULL REFERENCES organizaciones(id) ON DELETE CASCADE,
    modelo_id UUID NOT NULL REFERENCES modelos(id) ON DELETE CASCADE,
    orden INT NOT NULL,
    proceso TEXT NOT NULL,
    subproceso TEXT,
    minutos NUMERIC NOT NULL,
    tarifa_hora NUMERIC NOT NULL,
    notas TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE procesos_manufactura ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "org_procesos_manufactura_policy" ON procesos_manufactura;
CREATE POLICY "org_procesos_manufactura_policy" ON procesos_manufactura FOR ALL USING (organizacion_id = get_current_org_id());

CREATE INDEX IF NOT EXISTS idx_procesos_manufactura_modelo_id ON procesos_manufactura(modelo_id);
CREATE INDEX IF NOT EXISTS idx_procesos_manufactura_org_id ON procesos_manufactura(organizacion_id);

-- 3. costos_modelo
CREATE TABLE IF NOT EXISTS costos_modelo (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organizacion_id UUID NOT NULL REFERENCES organizaciones(id) ON DELETE CASCADE,
    modelo_id UUID NOT NULL REFERENCES modelos(id) ON DELETE CASCADE,
    seccion TEXT NOT NULL,
    concepto TEXT NOT NULL,
    cantidad NUMERIC NOT NULL DEFAULT 1,
    costo_unitario NUMERIC NOT NULL,
    escala TEXT NOT NULL DEFAULT 'fija' CHECK (escala IN ('fija', 'por_eje', 'por_largo')),
    fuente TEXT,
    notas TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE costos_modelo ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "org_costos_modelo_policy" ON costos_modelo;
CREATE POLICY "org_costos_modelo_policy" ON costos_modelo FOR ALL USING (organizacion_id = get_current_org_id());

CREATE INDEX IF NOT EXISTS idx_costos_modelo_modelo_id ON costos_modelo(modelo_id);
CREATE INDEX IF NOT EXISTS idx_costos_modelo_org_id ON costos_modelo(organizacion_id);

COMMIT;
