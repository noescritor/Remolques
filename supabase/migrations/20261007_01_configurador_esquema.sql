BEGIN;

-- 1. parametros_costeo
CREATE TABLE IF NOT EXISTS parametros_costeo (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organizacion_id UUID NOT NULL REFERENCES organizaciones(id) ON DELETE CASCADE,
    clave TEXT NOT NULL,
    valor JSONB NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(organizacion_id, clave)
);

ALTER TABLE parametros_costeo ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "org_parametros_costeo_policy" ON parametros_costeo;
CREATE POLICY "org_parametros_costeo_policy" ON parametros_costeo FOR ALL USING (organizacion_id = get_current_org_id());

-- 2. modelos
CREATE TABLE IF NOT EXISTS modelos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organizacion_id UUID NOT NULL REFERENCES organizaciones(id) ON DELETE CASCADE,
    producto_id TEXT NOT NULL REFERENCES productos(id) ON DELETE CASCADE,
    tipo TEXT NOT NULL CHECK (tipo IN ('plataforma', 'dolly', 'gondola', 'jaula', 'caja_seca', 'traila')),
    largo_ft NUMERIC,
    num_ejes INTEGER,
    datos_tecnicos JSONB DEFAULT '{}'::jsonb,
    activo BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(organizacion_id, producto_id)
);

ALTER TABLE modelos ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "org_modelos_policy" ON modelos;
CREATE POLICY "org_modelos_policy" ON modelos FOR ALL USING (organizacion_id = get_current_org_id());

CREATE INDEX IF NOT EXISTS idx_modelos_producto_id ON modelos(producto_id);

-- 3. grupos_configuracion
CREATE TABLE IF NOT EXISTS grupos_configuracion (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organizacion_id UUID NOT NULL REFERENCES organizaciones(id) ON DELETE CASCADE,
    clave TEXT NOT NULL,
    nombre TEXT NOT NULL,
    seleccion TEXT NOT NULL CHECK (seleccion IN ('unica', 'unica_con_medida', 'unica_con_cantidad', 'cantidad', 'derivada', 'multiple_con_cantidad', 'multiple')),
    aplica_a TEXT[],
    depende_de TEXT,
    regla JSONB,
    notas TEXT,
    unidad_precio TEXT,
    cantidad TEXT,
    medidas JSONB,
    orden INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(organizacion_id, clave)
);

ALTER TABLE grupos_configuracion ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "org_grupos_configuracion_policy" ON grupos_configuracion;
CREATE POLICY "org_grupos_configuracion_policy" ON grupos_configuracion FOR ALL USING (organizacion_id = get_current_org_id());

-- 4. opciones_configuracion
CREATE TABLE IF NOT EXISTS opciones_configuracion (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    grupo_id UUID NOT NULL REFERENCES grupos_configuracion(id) ON DELETE CASCADE,
    organizacion_id UUID NOT NULL REFERENCES organizaciones(id) ON DELETE CASCADE,
    clave TEXT NOT NULL,
    nombre TEXT NOT NULL,
    precio_venta NUMERIC,
    medidas JSONB,
    clase TEXT,
    activo BOOLEAN DEFAULT true,
    notas TEXT,
    precio_fuente TEXT,
    otros_precios JSONB,
    marcas TEXT[],
    proveedor TEXT,
    aliases TEXT[],
    datos JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(grupo_id, clave)
);

ALTER TABLE opciones_configuracion ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "org_opciones_configuracion_policy" ON opciones_configuracion;
CREATE POLICY "org_opciones_configuracion_policy" ON opciones_configuracion FOR ALL USING (organizacion_id = get_current_org_id());

CREATE INDEX IF NOT EXISTS idx_opciones_grupo_id ON opciones_configuracion(grupo_id);

-- 5. opcion_componentes
CREATE TABLE IF NOT EXISTS opcion_componentes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    opcion_id UUID NOT NULL REFERENCES opciones_configuracion(id) ON DELETE CASCADE,
    material_id TEXT NOT NULL REFERENCES productos(id) ON DELETE CASCADE,
    cantidad NUMERIC NOT NULL DEFAULT 1,
    escala TEXT CHECK (escala IN ('fija', 'por_eje', 'por_largo')),
    rol TEXT CHECK (rol IN ('componente', 'sustituto', 'independiente')),
    paso TEXT,
    uso TEXT,
    seccion TEXT,
    condicion JSONB,
    notas TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
    -- SIN UNIQUE(opcion_id, material_id) porque un material se puede sumar en la misma opcion
);

ALTER TABLE opcion_componentes ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "org_opcion_componentes_policy" ON opcion_componentes;
CREATE POLICY "org_opcion_componentes_policy" ON opcion_componentes FOR ALL USING (
    opcion_id IN (SELECT id FROM opciones_configuracion WHERE organizacion_id = get_current_org_id())
);

CREATE INDEX IF NOT EXISTS idx_opcion_componentes_opcion_id ON opcion_componentes(opcion_id);
CREATE INDEX IF NOT EXISTS idx_opcion_componentes_material_id ON opcion_componentes(material_id);

-- 6. receta_base
CREATE TABLE IF NOT EXISTS receta_base (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    modelo_id UUID NOT NULL REFERENCES modelos(id) ON DELETE CASCADE,
    material_id TEXT NOT NULL REFERENCES productos(id) ON DELETE CASCADE,
    cantidad NUMERIC NOT NULL DEFAULT 1,
    escala TEXT CHECK (escala IN ('fija', 'por_eje', 'por_largo')),
    paso TEXT,
    uso TEXT,
    seccion TEXT,
    condicion JSONB,
    notas TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
    -- SIN UNIQUE(modelo_id, material_id)
);

ALTER TABLE receta_base ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "org_receta_base_policy" ON receta_base;
CREATE POLICY "org_receta_base_policy" ON receta_base FOR ALL USING (
    modelo_id IN (SELECT id FROM modelos WHERE organizacion_id = get_current_org_id())
);

CREATE INDEX IF NOT EXISTS idx_receta_base_modelo_id ON receta_base(modelo_id);
CREATE INDEX IF NOT EXISTS idx_receta_base_material_id ON receta_base(material_id);

-- 7. material_proveedores
CREATE TABLE IF NOT EXISTS material_proveedores (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organizacion_id UUID NOT NULL REFERENCES organizaciones(id) ON DELETE CASCADE,
    material_id TEXT NOT NULL REFERENCES productos(id) ON DELETE CASCADE,
    proveedor_id UUID NOT NULL REFERENCES proveedores(id) ON DELETE CASCADE,
    costo NUMERIC NOT NULL DEFAULT 0,
    tiempo_entrega_dias INTEGER NOT NULL DEFAULT 0,
    unidad TEXT,
    vigente_desde TIMESTAMPTZ,
    preferido BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(material_id, proveedor_id)
);

ALTER TABLE material_proveedores ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "org_material_proveedores_policy" ON material_proveedores;
CREATE POLICY "org_material_proveedores_policy" ON material_proveedores FOR ALL USING (organizacion_id = get_current_org_id());

CREATE INDEX IF NOT EXISTS idx_material_proveedores_material_id ON material_proveedores(material_id);
CREATE INDEX IF NOT EXISTS idx_material_proveedores_proveedor_id ON material_proveedores(proveedor_id);

COMMIT;
