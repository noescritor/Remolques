-- Migración 20261027_01_acero_precios.sql
-- Sub-bloque 2R-13: calculadoras de acero (costeo de placa + comparador de precios de acero)
-- Esquema y seed idempotente para acero_materiales, acero_precios y acero_precios_historial

BEGIN;

-- 1. Tabla acero_materiales
CREATE TABLE IF NOT EXISTS acero_materiales (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organizacion_id UUID NOT NULL REFERENCES organizaciones(id) ON DELETE CASCADE,
    nombre TEXT NOT NULL,
    tipo TEXT NOT NULL CHECK (tipo IN ('placa', 'lamina', 'solera', 'canal', 'ptr', 'tubo', 'angulo', 'redondo')),
    ancho_ft NUMERIC,
    largo_ft NUMERIC,
    activo BOOLEAN NOT NULL DEFAULT true,
    notas TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(organizacion_id, nombre)
);

ALTER TABLE acero_materiales ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "org_acero_materiales_policy" ON acero_materiales;
CREATE POLICY "org_acero_materiales_policy" ON acero_materiales FOR ALL USING (organizacion_id = get_current_org_id());

CREATE INDEX IF NOT EXISTS idx_acero_materiales_org ON acero_materiales(organizacion_id);
CREATE INDEX IF NOT EXISTS idx_acero_materiales_tipo ON acero_materiales(organizacion_id, tipo);

-- 2. Tabla acero_precios
CREATE TABLE IF NOT EXISTS acero_precios (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organizacion_id UUID NOT NULL REFERENCES organizaciones(id) ON DELETE CASCADE,
    material_id UUID NOT NULL REFERENCES acero_materiales(id) ON DELETE CASCADE,
    proveedor TEXT NOT NULL,
    precio NUMERIC(14,4) NOT NULL,
    incluye_iva BOOLEAN NOT NULL DEFAULT true,
    fuente TEXT,
    actualizado_el TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    notas TEXT,
    UNIQUE(material_id, proveedor)
);

ALTER TABLE acero_precios ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "org_acero_precios_policy" ON acero_precios;
CREATE POLICY "org_acero_precios_policy" ON acero_precios FOR ALL USING (organizacion_id = get_current_org_id());

CREATE INDEX IF NOT EXISTS idx_acero_precios_material_id ON acero_precios(material_id);
CREATE INDEX IF NOT EXISTS idx_acero_precios_org ON acero_precios(organizacion_id);

-- 3. Tabla acero_precios_historial
CREATE TABLE IF NOT EXISTS acero_precios_historial (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organizacion_id UUID NOT NULL REFERENCES organizaciones(id) ON DELETE CASCADE,
    material_id UUID NOT NULL REFERENCES acero_materiales(id) ON DELETE CASCADE,
    proveedor TEXT NOT NULL,
    precio_anterior NUMERIC(14,4),
    precio_nuevo NUMERIC(14,4) NOT NULL,
    usuario_id UUID,
    creado_el TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE acero_precios_historial ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "org_acero_precios_historial_policy" ON acero_precios_historial;
CREATE POLICY "org_acero_precios_historial_policy" ON acero_precios_historial FOR ALL USING (organizacion_id = get_current_org_id());

CREATE INDEX IF NOT EXISTS idx_acero_precios_historial_org ON acero_precios_historial(organizacion_id, creado_el DESC);
CREATE INDEX IF NOT EXISTS idx_acero_precios_historial_mat ON acero_precios_historial(material_id);

-- 4. Seed de materiales y precios por organización
DO $$
DECLARE
    r_org RECORD;
    v_mat_id UUID;
BEGIN
    FOR r_org IN SELECT id FROM organizaciones LOOP

        -- Material: Canal "U" de 6" (15Kg) a 12.20m
        INSERT INTO acero_materiales (organizacion_id, nombre, tipo, ancho_ft, largo_ft, activo, notas)
        VALUES (r_org.id, 'Canal "U" de 6" (15Kg) a 12.20m', 'canal', NULL, NULL, true, 'import-2r13')
        ON CONFLICT (organizacion_id, nombre)
        DO UPDATE SET tipo = EXCLUDED.tipo, ancho_ft = EXCLUDED.ancho_ft, largo_ft = EXCLUDED.largo_ft, activo = EXCLUDED.activo, notas = EXCLUDED.notas
        RETURNING id INTO v_mat_id;
        INSERT INTO acero_precios (organizacion_id, material_id, proveedor, precio, incluye_iva, fuente, notas)
        VALUES (r_org.id, v_mat_id, 'SERVIACERO', 4822.1664, true, 'PRECIOS DE ACERO.xlsx (Hoja1)', 'import-2r13')
        ON CONFLICT (material_id, proveedor)
        DO UPDATE SET precio = EXCLUDED.precio, incluye_iva = EXCLUDED.incluye_iva, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;
        INSERT INTO acero_precios (organizacion_id, material_id, proveedor, precio, incluye_iva, fuente, notas)
        VALUES (r_org.id, v_mat_id, 'TPI', 5473.75, true, 'PRECIOS DE ACERO.xlsx (Hoja1)', 'import-2r13')
        ON CONFLICT (material_id, proveedor)
        DO UPDATE SET precio = EXCLUDED.precio, incluye_iva = EXCLUDED.incluye_iva, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;

        -- Material: Canal "U" de 6" (12Kg) a 12.20m
        INSERT INTO acero_materiales (organizacion_id, nombre, tipo, ancho_ft, largo_ft, activo, notas)
        VALUES (r_org.id, 'Canal "U" de 6" (12Kg) a 12.20m', 'canal', NULL, NULL, true, 'import-2r13')
        ON CONFLICT (organizacion_id, nombre)
        DO UPDATE SET tipo = EXCLUDED.tipo, ancho_ft = EXCLUDED.ancho_ft, largo_ft = EXCLUDED.largo_ft, activo = EXCLUDED.activo, notas = EXCLUDED.notas
        RETURNING id INTO v_mat_id;
        INSERT INTO acero_precios (organizacion_id, material_id, proveedor, precio, incluye_iva, fuente, notas)
        VALUES (r_org.id, v_mat_id, 'FORTACERO', 3891.6318, true, 'PRECIOS DE ACERO.xlsx (Hoja1)', 'import-2r13')
        ON CONFLICT (material_id, proveedor)
        DO UPDATE SET precio = EXCLUDED.precio, incluye_iva = EXCLUDED.incluye_iva, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;
        INSERT INTO acero_precios (organizacion_id, material_id, proveedor, precio, incluye_iva, fuente, notas)
        VALUES (r_org.id, v_mat_id, 'SERVIACERO', 3764.1188, true, 'PRECIOS DE ACERO.xlsx (Hoja1)', 'import-2r13')
        ON CONFLICT (material_id, proveedor)
        DO UPDATE SET precio = EXCLUDED.precio, incluye_iva = EXCLUDED.incluye_iva, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;
        INSERT INTO acero_precios (organizacion_id, material_id, proveedor, precio, incluye_iva, fuente, notas)
        VALUES (r_org.id, v_mat_id, 'TPI', 4140.9, true, 'PRECIOS DE ACERO.xlsx (Hoja1)', 'import-2r13')
        ON CONFLICT (material_id, proveedor)
        DO UPDATE SET precio = EXCLUDED.precio, incluye_iva = EXCLUDED.incluye_iva, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;

        -- Material: Canal "U" de 6" (12Kg) a 6.10m
        INSERT INTO acero_materiales (organizacion_id, nombre, tipo, ancho_ft, largo_ft, activo, notas)
        VALUES (r_org.id, 'Canal "U" de 6" (12Kg) a 6.10m', 'canal', NULL, NULL, true, 'import-2r13')
        ON CONFLICT (organizacion_id, nombre)
        DO UPDATE SET tipo = EXCLUDED.tipo, ancho_ft = EXCLUDED.ancho_ft, largo_ft = EXCLUDED.largo_ft, activo = EXCLUDED.activo, notas = EXCLUDED.notas
        RETURNING id INTO v_mat_id;
        INSERT INTO acero_precios (organizacion_id, material_id, proveedor, precio, incluye_iva, fuente, notas)
        VALUES (r_org.id, v_mat_id, 'PIRAMIDE', 2549.97, true, 'PRECIOS DE ACERO.xlsx (Hoja1)', 'import-2r13')
        ON CONFLICT (material_id, proveedor)
        DO UPDATE SET precio = EXCLUDED.precio, incluye_iva = EXCLUDED.incluye_iva, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;

        -- Material: PTR 6X4" Cal. 3/16 a 12.20m
        INSERT INTO acero_materiales (organizacion_id, nombre, tipo, ancho_ft, largo_ft, activo, notas)
        VALUES (r_org.id, 'PTR 6X4" Cal. 3/16 a 12.20m', 'ptr', NULL, NULL, true, 'import-2r13')
        ON CONFLICT (organizacion_id, nombre)
        DO UPDATE SET tipo = EXCLUDED.tipo, ancho_ft = EXCLUDED.ancho_ft, largo_ft = EXCLUDED.largo_ft, activo = EXCLUDED.activo, notas = EXCLUDED.notas
        RETURNING id INTO v_mat_id;
        INSERT INTO acero_precios (organizacion_id, material_id, proveedor, precio, incluye_iva, fuente, notas)
        VALUES (r_org.id, v_mat_id, 'FORTACERO', 5201.48, true, 'PRECIOS DE ACERO.xlsx (Hoja1)', 'import-2r13')
        ON CONFLICT (material_id, proveedor)
        DO UPDATE SET precio = EXCLUDED.precio, incluye_iva = EXCLUDED.incluye_iva, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;
        INSERT INTO acero_precios (organizacion_id, material_id, proveedor, precio, incluye_iva, fuente, notas)
        VALUES (r_org.id, v_mat_id, 'SERVIACERO', 5230.614, true, 'PRECIOS DE ACERO.xlsx (Hoja1)', 'import-2r13')
        ON CONFLICT (material_id, proveedor)
        DO UPDATE SET precio = EXCLUDED.precio, incluye_iva = EXCLUDED.incluye_iva, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;

        -- Material: PTR de 6X2" Cal. 3/16"
        INSERT INTO acero_materiales (organizacion_id, nombre, tipo, ancho_ft, largo_ft, activo, notas)
        VALUES (r_org.id, 'PTR de 6X2" Cal. 3/16"', 'ptr', NULL, NULL, true, 'import-2r13')
        ON CONFLICT (organizacion_id, nombre)
        DO UPDATE SET tipo = EXCLUDED.tipo, ancho_ft = EXCLUDED.ancho_ft, largo_ft = EXCLUDED.largo_ft, activo = EXCLUDED.activo, notas = EXCLUDED.notas
        RETURNING id INTO v_mat_id;
        INSERT INTO acero_precios (organizacion_id, material_id, proveedor, precio, incluye_iva, fuente, notas)
        VALUES (r_org.id, v_mat_id, 'FORTACERO', 2108.1227, true, 'PRECIOS DE ACERO.xlsx (Hoja1)', 'import-2r13')
        ON CONFLICT (material_id, proveedor)
        DO UPDATE SET precio = EXCLUDED.precio, incluye_iva = EXCLUDED.incluye_iva, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;
        INSERT INTO acero_precios (organizacion_id, material_id, proveedor, precio, incluye_iva, fuente, notas)
        VALUES (r_org.id, v_mat_id, 'PIRAMIDE', 5050, true, 'PRECIOS DE ACERO.xlsx (Hoja1)', 'import-2r13')
        ON CONFLICT (material_id, proveedor)
        DO UPDATE SET precio = EXCLUDED.precio, incluye_iva = EXCLUDED.incluye_iva, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;
        INSERT INTO acero_precios (organizacion_id, material_id, proveedor, precio, incluye_iva, fuente, notas)
        VALUES (r_org.id, v_mat_id, 'TPI', 2143.96, true, 'PRECIOS DE ACERO.xlsx (Hoja1)', 'import-2r13')
        ON CONFLICT (material_id, proveedor)
        DO UPDATE SET precio = EXCLUDED.precio, incluye_iva = EXCLUDED.incluye_iva, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;

        -- Material: PTR de 2X4" Cal. 7
        INSERT INTO acero_materiales (organizacion_id, nombre, tipo, ancho_ft, largo_ft, activo, notas)
        VALUES (r_org.id, 'PTR de 2X4" Cal. 7', 'ptr', NULL, NULL, true, 'import-2r13')
        ON CONFLICT (organizacion_id, nombre)
        DO UPDATE SET tipo = EXCLUDED.tipo, ancho_ft = EXCLUDED.ancho_ft, largo_ft = EXCLUDED.largo_ft, activo = EXCLUDED.activo, notas = EXCLUDED.notas
        RETURNING id INTO v_mat_id;
        INSERT INTO acero_precios (organizacion_id, material_id, proveedor, precio, incluye_iva, fuente, notas)
        VALUES (r_org.id, v_mat_id, 'TANOS', 1568.75, true, 'PRECIOS DE ACERO.xlsx (Hoja1)', 'import-2r13')
        ON CONFLICT (material_id, proveedor)
        DO UPDATE SET precio = EXCLUDED.precio, incluye_iva = EXCLUDED.incluye_iva, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;
        INSERT INTO acero_precios (organizacion_id, material_id, proveedor, precio, incluye_iva, fuente, notas)
        VALUES (r_org.id, v_mat_id, 'SERVIACERO', 1337.94, true, 'PRECIOS DE ACERO.xlsx (Hoja1)', 'import-2r13')
        ON CONFLICT (material_id, proveedor)
        DO UPDATE SET precio = EXCLUDED.precio, incluye_iva = EXCLUDED.incluye_iva, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;
        INSERT INTO acero_precios (organizacion_id, material_id, proveedor, precio, incluye_iva, fuente, notas)
        VALUES (r_org.id, v_mat_id, 'TPI', 2047.27, true, 'PRECIOS DE ACERO.xlsx (Hoja1)', 'import-2r13')
        ON CONFLICT (material_id, proveedor)
        DO UPDATE SET precio = EXCLUDED.precio, incluye_iva = EXCLUDED.incluye_iva, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;

        -- Material: PTR de 1-1/2X3" Cal. 14
        INSERT INTO acero_materiales (organizacion_id, nombre, tipo, ancho_ft, largo_ft, activo, notas)
        VALUES (r_org.id, 'PTR de 1-1/2X3" Cal. 14', 'ptr', NULL, NULL, true, 'import-2r13')
        ON CONFLICT (organizacion_id, nombre)
        DO UPDATE SET tipo = EXCLUDED.tipo, ancho_ft = EXCLUDED.ancho_ft, largo_ft = EXCLUDED.largo_ft, activo = EXCLUDED.activo, notas = EXCLUDED.notas
        RETURNING id INTO v_mat_id;
        INSERT INTO acero_precios (organizacion_id, material_id, proveedor, precio, incluye_iva, fuente, notas)
        VALUES (r_org.id, v_mat_id, 'TANOS', 494.7464, true, 'PRECIOS DE ACERO.xlsx (Hoja1)', 'import-2r13')
        ON CONFLICT (material_id, proveedor)
        DO UPDATE SET precio = EXCLUDED.precio, incluye_iva = EXCLUDED.incluye_iva, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;
        INSERT INTO acero_precios (organizacion_id, material_id, proveedor, precio, incluye_iva, fuente, notas)
        VALUES (r_org.id, v_mat_id, 'SERVIACERO', 495.27, true, 'PRECIOS DE ACERO.xlsx (Hoja1)', 'import-2r13')
        ON CONFLICT (material_id, proveedor)
        DO UPDATE SET precio = EXCLUDED.precio, incluye_iva = EXCLUDED.incluye_iva, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;
        INSERT INTO acero_precios (organizacion_id, material_id, proveedor, precio, incluye_iva, fuente, notas)
        VALUES (r_org.id, v_mat_id, 'PIRAMIDE', 554.448, true, 'PRECIOS DE ACERO.xlsx (Hoja1)', 'import-2r13')
        ON CONFLICT (material_id, proveedor)
        DO UPDATE SET precio = EXCLUDED.precio, incluye_iva = EXCLUDED.incluye_iva, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;

        -- Material: PTR de 2X4" Cal. 9
        INSERT INTO acero_materiales (organizacion_id, nombre, tipo, ancho_ft, largo_ft, activo, notas)
        VALUES (r_org.id, 'PTR de 2X4" Cal. 9', 'ptr', NULL, NULL, true, 'import-2r13')
        ON CONFLICT (organizacion_id, nombre)
        DO UPDATE SET tipo = EXCLUDED.tipo, ancho_ft = EXCLUDED.ancho_ft, largo_ft = EXCLUDED.largo_ft, activo = EXCLUDED.activo, notas = EXCLUDED.notas
        RETURNING id INTO v_mat_id;
        INSERT INTO acero_precios (organizacion_id, material_id, proveedor, precio, incluye_iva, fuente, notas)
        VALUES (r_org.id, v_mat_id, 'TANOS', 1264.6262, true, 'PRECIOS DE ACERO.xlsx (Hoja1)', 'import-2r13')
        ON CONFLICT (material_id, proveedor)
        DO UPDATE SET precio = EXCLUDED.precio, incluye_iva = EXCLUDED.incluye_iva, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;
        INSERT INTO acero_precios (organizacion_id, material_id, proveedor, precio, incluye_iva, fuente, notas)
        VALUES (r_org.id, v_mat_id, 'SERVIACERO', 1239.1816, true, 'PRECIOS DE ACERO.xlsx (Hoja1)', 'import-2r13')
        ON CONFLICT (material_id, proveedor)
        DO UPDATE SET precio = EXCLUDED.precio, incluye_iva = EXCLUDED.incluye_iva, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;

        -- Material: PTR de 2X3" Cal. 10
        INSERT INTO acero_materiales (organizacion_id, nombre, tipo, ancho_ft, largo_ft, activo, notas)
        VALUES (r_org.id, 'PTR de 2X3" Cal. 10', 'ptr', NULL, NULL, true, 'import-2r13')
        ON CONFLICT (organizacion_id, nombre)
        DO UPDATE SET tipo = EXCLUDED.tipo, ancho_ft = EXCLUDED.ancho_ft, largo_ft = EXCLUDED.largo_ft, activo = EXCLUDED.activo, notas = EXCLUDED.notas
        RETURNING id INTO v_mat_id;
        INSERT INTO acero_precios (organizacion_id, material_id, proveedor, precio, incluye_iva, fuente, notas)
        VALUES (r_org.id, v_mat_id, 'SERVIACERO', 933.2664, true, 'PRECIOS DE ACERO.xlsx (Hoja1)', 'import-2r13')
        ON CONFLICT (material_id, proveedor)
        DO UPDATE SET precio = EXCLUDED.precio, incluye_iva = EXCLUDED.incluye_iva, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;

        -- Material: PTR de 2X3" Cal. 9
        INSERT INTO acero_materiales (organizacion_id, nombre, tipo, ancho_ft, largo_ft, activo, notas)
        VALUES (r_org.id, 'PTR de 2X3" Cal. 9', 'ptr', NULL, NULL, true, 'import-2r13')
        ON CONFLICT (organizacion_id, nombre)
        DO UPDATE SET tipo = EXCLUDED.tipo, ancho_ft = EXCLUDED.ancho_ft, largo_ft = EXCLUDED.largo_ft, activo = EXCLUDED.activo, notas = EXCLUDED.notas
        RETURNING id INTO v_mat_id;
        INSERT INTO acero_precios (organizacion_id, material_id, proveedor, precio, incluye_iva, fuente, notas)
        VALUES (r_org.id, v_mat_id, 'TANOS', 996.8947, true, 'PRECIOS DE ACERO.xlsx (Hoja1)', 'import-2r13')
        ON CONFLICT (material_id, proveedor)
        DO UPDATE SET precio = EXCLUDED.precio, incluye_iva = EXCLUDED.incluye_iva, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;

        -- Material: PTR de 2" Cal. 12
        INSERT INTO acero_materiales (organizacion_id, nombre, tipo, ancho_ft, largo_ft, activo, notas)
        VALUES (r_org.id, 'PTR de 2" Cal. 12', 'ptr', NULL, NULL, true, 'import-2r13')
        ON CONFLICT (organizacion_id, nombre)
        DO UPDATE SET tipo = EXCLUDED.tipo, ancho_ft = EXCLUDED.ancho_ft, largo_ft = EXCLUDED.largo_ft, activo = EXCLUDED.activo, notas = EXCLUDED.notas
        RETURNING id INTO v_mat_id;
        INSERT INTO acero_precios (organizacion_id, material_id, proveedor, precio, incluye_iva, fuente, notas)
        VALUES (r_org.id, v_mat_id, 'TANOS', 602.0864, true, 'PRECIOS DE ACERO.xlsx (Hoja1)', 'import-2r13')
        ON CONFLICT (material_id, proveedor)
        DO UPDATE SET precio = EXCLUDED.precio, incluye_iva = EXCLUDED.incluye_iva, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;
        INSERT INTO acero_precios (organizacion_id, material_id, proveedor, precio, incluye_iva, fuente, notas)
        VALUES (r_org.id, v_mat_id, 'SERVIACERO', 625.6112, true, 'PRECIOS DE ACERO.xlsx (Hoja1)', 'import-2r13')
        ON CONFLICT (material_id, proveedor)
        DO UPDATE SET precio = EXCLUDED.precio, incluye_iva = EXCLUDED.incluye_iva, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;

        -- Material: PTR de 2" Cal. 14
        INSERT INTO acero_materiales (organizacion_id, nombre, tipo, ancho_ft, largo_ft, activo, notas)
        VALUES (r_org.id, 'PTR de 2" Cal. 14', 'ptr', NULL, NULL, true, 'import-2r13')
        ON CONFLICT (organizacion_id, nombre)
        DO UPDATE SET tipo = EXCLUDED.tipo, ancho_ft = EXCLUDED.ancho_ft, largo_ft = EXCLUDED.largo_ft, activo = EXCLUDED.activo, notas = EXCLUDED.notas
        RETURNING id INTO v_mat_id;
        INSERT INTO acero_precios (organizacion_id, material_id, proveedor, precio, incluye_iva, fuente, notas)
        VALUES (r_org.id, v_mat_id, 'TANOS', 432.9457, true, 'PRECIOS DE ACERO.xlsx (Hoja1)', 'import-2r13')
        ON CONFLICT (material_id, proveedor)
        DO UPDATE SET precio = EXCLUDED.precio, incluye_iva = EXCLUDED.incluye_iva, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;
        INSERT INTO acero_precios (organizacion_id, material_id, proveedor, precio, incluye_iva, fuente, notas)
        VALUES (r_org.id, v_mat_id, 'SERVIACERO', 454.6968, true, 'PRECIOS DE ACERO.xlsx (Hoja1)', 'import-2r13')
        ON CONFLICT (material_id, proveedor)
        DO UPDATE SET precio = EXCLUDED.precio, incluye_iva = EXCLUDED.incluye_iva, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;

        -- Material: PTR de 4" Cal. 7
        INSERT INTO acero_materiales (organizacion_id, nombre, tipo, ancho_ft, largo_ft, activo, notas)
        VALUES (r_org.id, 'PTR de 4" Cal. 7', 'ptr', NULL, NULL, true, 'import-2r13')
        ON CONFLICT (organizacion_id, nombre)
        DO UPDATE SET tipo = EXCLUDED.tipo, ancho_ft = EXCLUDED.ancho_ft, largo_ft = EXCLUDED.largo_ft, activo = EXCLUDED.activo, notas = EXCLUDED.notas
        RETURNING id INTO v_mat_id;
        INSERT INTO acero_precios (organizacion_id, material_id, proveedor, precio, incluye_iva, fuente, notas)
        VALUES (r_org.id, v_mat_id, 'SERVIACERO', 2114.4132, true, 'PRECIOS DE ACERO.xlsx (Hoja1)', 'import-2r13')
        ON CONFLICT (material_id, proveedor)
        DO UPDATE SET precio = EXCLUDED.precio, incluye_iva = EXCLUDED.incluye_iva, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;

        -- Material: PTR de 4" Cal. 11
        INSERT INTO acero_materiales (organizacion_id, nombre, tipo, ancho_ft, largo_ft, activo, notas)
        VALUES (r_org.id, 'PTR de 4" Cal. 11', 'ptr', NULL, NULL, true, 'import-2r13')
        ON CONFLICT (organizacion_id, nombre)
        DO UPDATE SET tipo = EXCLUDED.tipo, ancho_ft = EXCLUDED.ancho_ft, largo_ft = EXCLUDED.largo_ft, activo = EXCLUDED.activo, notas = EXCLUDED.notas
        RETURNING id INTO v_mat_id;
        INSERT INTO acero_precios (organizacion_id, material_id, proveedor, precio, incluye_iva, fuente, notas)
        VALUES (r_org.id, v_mat_id, 'PIRAMIDE', 1612.938, true, 'PRECIOS DE ACERO.xlsx (Hoja1)', 'import-2r13')
        ON CONFLICT (material_id, proveedor)
        DO UPDATE SET precio = EXCLUDED.precio, incluye_iva = EXCLUDED.incluye_iva, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;

        -- Material: Tubo negro mecanico Ced. 40 2"
        INSERT INTO acero_materiales (organizacion_id, nombre, tipo, ancho_ft, largo_ft, activo, notas)
        VALUES (r_org.id, 'Tubo negro mecanico Ced. 40 2"', 'tubo', NULL, NULL, true, 'import-2r13')
        ON CONFLICT (organizacion_id, nombre)
        DO UPDATE SET tipo = EXCLUDED.tipo, ancho_ft = EXCLUDED.ancho_ft, largo_ft = EXCLUDED.largo_ft, activo = EXCLUDED.activo, notas = EXCLUDED.notas
        RETURNING id INTO v_mat_id;
        INSERT INTO acero_precios (organizacion_id, material_id, proveedor, precio, incluye_iva, fuente, notas)
        VALUES (r_org.id, v_mat_id, 'TANOS', 789.6236, true, 'PRECIOS DE ACERO.xlsx (Hoja1)', 'import-2r13')
        ON CONFLICT (material_id, proveedor)
        DO UPDATE SET precio = EXCLUDED.precio, incluye_iva = EXCLUDED.incluye_iva, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;
        INSERT INTO acero_precios (organizacion_id, material_id, proveedor, precio, incluye_iva, fuente, notas)
        VALUES (r_org.id, v_mat_id, 'FORTACERO', 798.6832, true, 'PRECIOS DE ACERO.xlsx (Hoja1)', 'import-2r13')
        ON CONFLICT (material_id, proveedor)
        DO UPDATE SET precio = EXCLUDED.precio, incluye_iva = EXCLUDED.incluye_iva, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;
        INSERT INTO acero_precios (organizacion_id, material_id, proveedor, precio, incluye_iva, fuente, notas)
        VALUES (r_org.id, v_mat_id, 'SERVIACERO', 832.6828, true, 'PRECIOS DE ACERO.xlsx (Hoja1)', 'import-2r13')
        ON CONFLICT (material_id, proveedor)
        DO UPDATE SET precio = EXCLUDED.precio, incluye_iva = EXCLUDED.incluye_iva, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;
        INSERT INTO acero_precios (organizacion_id, material_id, proveedor, precio, incluye_iva, fuente, notas)
        VALUES (r_org.id, v_mat_id, 'PIRAMIDE', 982.04, true, 'PRECIOS DE ACERO.xlsx (Hoja1)', 'import-2r13')
        ON CONFLICT (material_id, proveedor)
        DO UPDATE SET precio = EXCLUDED.precio, incluye_iva = EXCLUDED.incluye_iva, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;

        -- Material: Tubo negro mecanico Ced. 40 1-1/4"
        INSERT INTO acero_materiales (organizacion_id, nombre, tipo, ancho_ft, largo_ft, activo, notas)
        VALUES (r_org.id, 'Tubo negro mecanico Ced. 40 1-1/4"', 'tubo', NULL, NULL, true, 'import-2r13')
        ON CONFLICT (organizacion_id, nombre)
        DO UPDATE SET tipo = EXCLUDED.tipo, ancho_ft = EXCLUDED.ancho_ft, largo_ft = EXCLUDED.largo_ft, activo = EXCLUDED.activo, notas = EXCLUDED.notas
        RETURNING id INTO v_mat_id;
        INSERT INTO acero_precios (organizacion_id, material_id, proveedor, precio, incluye_iva, fuente, notas)
        VALUES (r_org.id, v_mat_id, 'SERVIACERO', 513.2304, true, 'PRECIOS DE ACERO.xlsx (Hoja1)', 'import-2r13')
        ON CONFLICT (material_id, proveedor)
        DO UPDATE SET precio = EXCLUDED.precio, incluye_iva = EXCLUDED.incluye_iva, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;
        INSERT INTO acero_precios (organizacion_id, material_id, proveedor, precio, incluye_iva, fuente, notas)
        VALUES (r_org.id, v_mat_id, 'PIRAMIDE', 609.332, true, 'PRECIOS DE ACERO.xlsx (Hoja1)', 'import-2r13')
        ON CONFLICT (material_id, proveedor)
        DO UPDATE SET precio = EXCLUDED.precio, incluye_iva = EXCLUDED.incluye_iva, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;

        -- Material: Tubo negro mecanico Ced. 40 3/4"
        INSERT INTO acero_materiales (organizacion_id, nombre, tipo, ancho_ft, largo_ft, activo, notas)
        VALUES (r_org.id, 'Tubo negro mecanico Ced. 40 3/4"', 'tubo', NULL, NULL, true, 'import-2r13')
        ON CONFLICT (organizacion_id, nombre)
        DO UPDATE SET tipo = EXCLUDED.tipo, ancho_ft = EXCLUDED.ancho_ft, largo_ft = EXCLUDED.largo_ft, activo = EXCLUDED.activo, notas = EXCLUDED.notas
        RETURNING id INTO v_mat_id;
        INSERT INTO acero_precios (organizacion_id, material_id, proveedor, precio, incluye_iva, fuente, notas)
        VALUES (r_org.id, v_mat_id, 'PIRAMIDE', 301.026, true, 'PRECIOS DE ACERO.xlsx (Hoja1)', 'import-2r13')
        ON CONFLICT (material_id, proveedor)
        DO UPDATE SET precio = EXCLUDED.precio, incluye_iva = EXCLUDED.incluye_iva, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;

        -- Material: Solera 3/16X1-1/2"
        INSERT INTO acero_materiales (organizacion_id, nombre, tipo, ancho_ft, largo_ft, activo, notas)
        VALUES (r_org.id, 'Solera 3/16X1-1/2"', 'solera', NULL, NULL, true, 'import-2r13')
        ON CONFLICT (organizacion_id, nombre)
        DO UPDATE SET tipo = EXCLUDED.tipo, ancho_ft = EXCLUDED.ancho_ft, largo_ft = EXCLUDED.largo_ft, activo = EXCLUDED.activo, notas = EXCLUDED.notas
        RETURNING id INTO v_mat_id;
        INSERT INTO acero_precios (organizacion_id, material_id, proveedor, precio, incluye_iva, fuente, notas)
        VALUES (r_org.id, v_mat_id, 'PIRAMIDE', 295.116, true, 'PRECIOS DE ACERO.xlsx (Hoja1)', 'import-2r13')
        ON CONFLICT (material_id, proveedor)
        DO UPDATE SET precio = EXCLUDED.precio, incluye_iva = EXCLUDED.incluye_iva, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;

        -- Material: Solera 3/8 X 2"
        INSERT INTO acero_materiales (organizacion_id, nombre, tipo, ancho_ft, largo_ft, activo, notas)
        VALUES (r_org.id, 'Solera 3/8 X 2"', 'solera', NULL, NULL, true, 'import-2r13')
        ON CONFLICT (organizacion_id, nombre)
        DO UPDATE SET tipo = EXCLUDED.tipo, ancho_ft = EXCLUDED.ancho_ft, largo_ft = EXCLUDED.largo_ft, activo = EXCLUDED.activo, notas = EXCLUDED.notas
        RETURNING id INTO v_mat_id;
        INSERT INTO acero_precios (organizacion_id, material_id, proveedor, precio, incluye_iva, fuente, notas)
        VALUES (r_org.id, v_mat_id, 'TANOS', 601.3687, true, 'PRECIOS DE ACERO.xlsx (Hoja1)', 'import-2r13')
        ON CONFLICT (material_id, proveedor)
        DO UPDATE SET precio = EXCLUDED.precio, incluye_iva = EXCLUDED.incluye_iva, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;
        INSERT INTO acero_precios (organizacion_id, material_id, proveedor, precio, incluye_iva, fuente, notas)
        VALUES (r_org.id, v_mat_id, 'FORTACERO', 602.6036, true, 'PRECIOS DE ACERO.xlsx (Hoja1)', 'import-2r13')
        ON CONFLICT (material_id, proveedor)
        DO UPDATE SET precio = EXCLUDED.precio, incluye_iva = EXCLUDED.incluye_iva, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;
        INSERT INTO acero_precios (organizacion_id, material_id, proveedor, precio, incluye_iva, fuente, notas)
        VALUES (r_org.id, v_mat_id, 'SERVIACERO', 586.4264, true, 'PRECIOS DE ACERO.xlsx (Hoja1)', 'import-2r13')
        ON CONFLICT (material_id, proveedor)
        DO UPDATE SET precio = EXCLUDED.precio, incluye_iva = EXCLUDED.incluye_iva, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;
        INSERT INTO acero_precios (organizacion_id, material_id, proveedor, precio, incluye_iva, fuente, notas)
        VALUES (r_org.id, v_mat_id, 'TPI', 626.18, true, 'PRECIOS DE ACERO.xlsx (Hoja1)', 'import-2r13')
        ON CONFLICT (material_id, proveedor)
        DO UPDATE SET precio = EXCLUDED.precio, incluye_iva = EXCLUDED.incluye_iva, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;

        -- Material: Solera 1/2 X 3"
        INSERT INTO acero_materiales (organizacion_id, nombre, tipo, ancho_ft, largo_ft, activo, notas)
        VALUES (r_org.id, 'Solera 1/2 X 3"', 'solera', NULL, NULL, true, 'import-2r13')
        ON CONFLICT (organizacion_id, nombre)
        DO UPDATE SET tipo = EXCLUDED.tipo, ancho_ft = EXCLUDED.ancho_ft, largo_ft = EXCLUDED.largo_ft, activo = EXCLUDED.activo, notas = EXCLUDED.notas
        RETURNING id INTO v_mat_id;
        INSERT INTO acero_precios (organizacion_id, material_id, proveedor, precio, incluye_iva, fuente, notas)
        VALUES (r_org.id, v_mat_id, 'TANOS', 1199.2776, true, 'PRECIOS DE ACERO.xlsx (Hoja1)', 'import-2r13')
        ON CONFLICT (material_id, proveedor)
        DO UPDATE SET precio = EXCLUDED.precio, incluye_iva = EXCLUDED.incluye_iva, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;
        INSERT INTO acero_precios (organizacion_id, material_id, proveedor, precio, incluye_iva, fuente, notas)
        VALUES (r_org.id, v_mat_id, 'FORTACERO', 1205.2091, true, 'PRECIOS DE ACERO.xlsx (Hoja1)', 'import-2r13')
        ON CONFLICT (material_id, proveedor)
        DO UPDATE SET precio = EXCLUDED.precio, incluye_iva = EXCLUDED.incluye_iva, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;
        INSERT INTO acero_precios (organizacion_id, material_id, proveedor, precio, incluye_iva, fuente, notas)
        VALUES (r_org.id, v_mat_id, 'SERVIACERO', 1172.5976, true, 'PRECIOS DE ACERO.xlsx (Hoja1)', 'import-2r13')
        ON CONFLICT (material_id, proveedor)
        DO UPDATE SET precio = EXCLUDED.precio, incluye_iva = EXCLUDED.incluye_iva, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;
        INSERT INTO acero_precios (organizacion_id, material_id, proveedor, precio, incluye_iva, fuente, notas)
        VALUES (r_org.id, v_mat_id, 'PIRAMIDE', 1574.182, true, 'PRECIOS DE ACERO.xlsx (Hoja1)', 'import-2r13')
        ON CONFLICT (material_id, proveedor)
        DO UPDATE SET precio = EXCLUDED.precio, incluye_iva = EXCLUDED.incluye_iva, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;

        -- Material: Solera 1/2 X 6" a 12.20m
        INSERT INTO acero_materiales (organizacion_id, nombre, tipo, ancho_ft, largo_ft, activo, notas)
        VALUES (r_org.id, 'Solera 1/2 X 6" a 12.20m', 'solera', NULL, NULL, true, 'import-2r13')
        ON CONFLICT (organizacion_id, nombre)
        DO UPDATE SET tipo = EXCLUDED.tipo, ancho_ft = EXCLUDED.ancho_ft, largo_ft = EXCLUDED.largo_ft, activo = EXCLUDED.activo, notas = EXCLUDED.notas
        RETURNING id INTO v_mat_id;
        INSERT INTO acero_precios (organizacion_id, material_id, proveedor, precio, incluye_iva, fuente, notas)
        VALUES (r_org.id, v_mat_id, 'FORTACERO', 4884.7527, true, 'PRECIOS DE ACERO.xlsx (Hoja1)', 'import-2r13')
        ON CONFLICT (material_id, proveedor)
        DO UPDATE SET precio = EXCLUDED.precio, incluye_iva = EXCLUDED.incluye_iva, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;
        INSERT INTO acero_precios (organizacion_id, material_id, proveedor, precio, incluye_iva, fuente, notas)
        VALUES (r_org.id, v_mat_id, 'SERVIACERO', 4697.7448, true, 'PRECIOS DE ACERO.xlsx (Hoja1)', 'import-2r13')
        ON CONFLICT (material_id, proveedor)
        DO UPDATE SET precio = EXCLUDED.precio, incluye_iva = EXCLUDED.incluye_iva, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;
        INSERT INTO acero_precios (organizacion_id, material_id, proveedor, precio, incluye_iva, fuente, notas)
        VALUES (r_org.id, v_mat_id, 'TPI', 5016, true, 'PRECIOS DE ACERO.xlsx (Hoja1)', 'import-2r13')
        ON CONFLICT (material_id, proveedor)
        DO UPDATE SET precio = EXCLUDED.precio, incluye_iva = EXCLUDED.incluye_iva, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;

        -- Material: Angulo 3/16 X 1-1/2" a 6.10m
        INSERT INTO acero_materiales (organizacion_id, nombre, tipo, ancho_ft, largo_ft, activo, notas)
        VALUES (r_org.id, 'Angulo 3/16 X 1-1/2" a 6.10m', 'angulo', NULL, NULL, true, 'import-2r13')
        ON CONFLICT (organizacion_id, nombre)
        DO UPDATE SET tipo = EXCLUDED.tipo, ancho_ft = EXCLUDED.ancho_ft, largo_ft = EXCLUDED.largo_ft, activo = EXCLUDED.activo, notas = EXCLUDED.notas
        RETURNING id INTO v_mat_id;
        INSERT INTO acero_precios (organizacion_id, material_id, proveedor, precio, incluye_iva, fuente, notas)
        VALUES (r_org.id, v_mat_id, 'TANOS', 897.6405, true, 'PRECIOS DE ACERO.xlsx (Hoja1)', 'import-2r13')
        ON CONFLICT (material_id, proveedor)
        DO UPDATE SET precio = EXCLUDED.precio, incluye_iva = EXCLUDED.incluye_iva, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;
        INSERT INTO acero_precios (organizacion_id, material_id, proveedor, precio, incluye_iva, fuente, notas)
        VALUES (r_org.id, v_mat_id, 'FORTACERO', 417.4492, true, 'PRECIOS DE ACERO.xlsx (Hoja1)', 'import-2r13')
        ON CONFLICT (material_id, proveedor)
        DO UPDATE SET precio = EXCLUDED.precio, incluye_iva = EXCLUDED.incluye_iva, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;
        INSERT INTO acero_precios (organizacion_id, material_id, proveedor, precio, incluye_iva, fuente, notas)
        VALUES (r_org.id, v_mat_id, 'SERVIACERO', 394.4928, true, 'PRECIOS DE ACERO.xlsx (Hoja1)', 'import-2r13')
        ON CONFLICT (material_id, proveedor)
        DO UPDATE SET precio = EXCLUDED.precio, incluye_iva = EXCLUDED.incluye_iva, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;

        -- Material: Redondo 1-1/2"
        INSERT INTO acero_materiales (organizacion_id, nombre, tipo, ancho_ft, largo_ft, activo, notas)
        VALUES (r_org.id, 'Redondo 1-1/2"', 'redondo', NULL, NULL, true, 'import-2r13')
        ON CONFLICT (organizacion_id, nombre)
        DO UPDATE SET tipo = EXCLUDED.tipo, ancho_ft = EXCLUDED.ancho_ft, largo_ft = EXCLUDED.largo_ft, activo = EXCLUDED.activo, notas = EXCLUDED.notas
        RETURNING id INTO v_mat_id;
        INSERT INTO acero_precios (organizacion_id, material_id, proveedor, precio, incluye_iva, fuente, notas)
        VALUES (r_org.id, v_mat_id, 'PIRAMIDE', 1854.34, true, 'PRECIOS DE ACERO.xlsx (Hoja1)', 'import-2r13')
        ON CONFLICT (material_id, proveedor)
        DO UPDATE SET precio = EXCLUDED.precio, incluye_iva = EXCLUDED.incluye_iva, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;

        -- Material: Redondo 1"
        INSERT INTO acero_materiales (organizacion_id, nombre, tipo, ancho_ft, largo_ft, activo, notas)
        VALUES (r_org.id, 'Redondo 1"', 'redondo', NULL, NULL, true, 'import-2r13')
        ON CONFLICT (organizacion_id, nombre)
        DO UPDATE SET tipo = EXCLUDED.tipo, ancho_ft = EXCLUDED.ancho_ft, largo_ft = EXCLUDED.largo_ft, activo = EXCLUDED.activo, notas = EXCLUDED.notas
        RETURNING id INTO v_mat_id;
        INSERT INTO acero_precios (organizacion_id, material_id, proveedor, precio, incluye_iva, fuente, notas)
        VALUES (r_org.id, v_mat_id, 'PIRAMIDE', 824.15, true, 'PRECIOS DE ACERO.xlsx (Hoja1)', 'import-2r13')
        ON CONFLICT (material_id, proveedor)
        DO UPDATE SET precio = EXCLUDED.precio, incluye_iva = EXCLUDED.incluye_iva, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;

        -- Material: Redondo 1/2"
        INSERT INTO acero_materiales (organizacion_id, nombre, tipo, ancho_ft, largo_ft, activo, notas)
        VALUES (r_org.id, 'Redondo 1/2"', 'redondo', NULL, NULL, true, 'import-2r13')
        ON CONFLICT (organizacion_id, nombre)
        DO UPDATE SET tipo = EXCLUDED.tipo, ancho_ft = EXCLUDED.ancho_ft, largo_ft = EXCLUDED.largo_ft, activo = EXCLUDED.activo, notas = EXCLUDED.notas
        RETURNING id INTO v_mat_id;
        INSERT INTO acero_precios (organizacion_id, material_id, proveedor, precio, incluye_iva, fuente, notas)
        VALUES (r_org.id, v_mat_id, 'PIRAMIDE', 230.004, true, 'PRECIOS DE ACERO.xlsx (Hoja1)', 'import-2r13')
        ON CONFLICT (material_id, proveedor)
        DO UPDATE SET precio = EXCLUDED.precio, incluye_iva = EXCLUDED.incluye_iva, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;

        -- Material: Lamina Negra Cal. 10 4X10'
        INSERT INTO acero_materiales (organizacion_id, nombre, tipo, ancho_ft, largo_ft, activo, notas)
        VALUES (r_org.id, 'Lamina Negra Cal. 10 4X10''', 'lamina', 4, 10, true, 'import-2r13')
        ON CONFLICT (organizacion_id, nombre)
        DO UPDATE SET tipo = EXCLUDED.tipo, ancho_ft = EXCLUDED.ancho_ft, largo_ft = EXCLUDED.largo_ft, activo = EXCLUDED.activo, notas = EXCLUDED.notas
        RETURNING id INTO v_mat_id;
        INSERT INTO acero_precios (organizacion_id, material_id, proveedor, precio, incluye_iva, fuente, notas)
        VALUES (r_org.id, v_mat_id, 'FORTACERO', 2148.1344, true, 'PRECIOS DE ACERO.xlsx (Hoja1)', 'import-2r13')
        ON CONFLICT (material_id, proveedor)
        DO UPDATE SET precio = EXCLUDED.precio, incluye_iva = EXCLUDED.incluye_iva, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;
        INSERT INTO acero_precios (organizacion_id, material_id, proveedor, precio, incluye_iva, fuente, notas)
        VALUES (r_org.id, v_mat_id, 'SERVIACERO', 2221.11, true, 'PRECIOS DE ACERO.xlsx (Hoja1)', 'import-2r13')
        ON CONFLICT (material_id, proveedor)
        DO UPDATE SET precio = EXCLUDED.precio, incluye_iva = EXCLUDED.incluye_iva, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;

        -- Material: Placa de grado A-36 de 3/16" en 5X10'
        INSERT INTO acero_materiales (organizacion_id, nombre, tipo, ancho_ft, largo_ft, activo, notas)
        VALUES (r_org.id, 'Placa de grado A-36 de 3/16" en 5X10''', 'placa', 5, 10, true, 'import-2r13')
        ON CONFLICT (organizacion_id, nombre)
        DO UPDATE SET tipo = EXCLUDED.tipo, ancho_ft = EXCLUDED.ancho_ft, largo_ft = EXCLUDED.largo_ft, activo = EXCLUDED.activo, notas = EXCLUDED.notas
        RETURNING id INTO v_mat_id;
        INSERT INTO acero_precios (organizacion_id, material_id, proveedor, precio, incluye_iva, fuente, notas)
        VALUES (r_org.id, v_mat_id, 'FORTACERO', 3912.738, true, 'PRECIOS DE ACERO.xlsx (Hoja1)', 'import-2r13')
        ON CONFLICT (material_id, proveedor)
        DO UPDATE SET precio = EXCLUDED.precio, incluye_iva = EXCLUDED.incluye_iva, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;
        INSERT INTO acero_precios (organizacion_id, material_id, proveedor, precio, incluye_iva, fuente, notas)
        VALUES (r_org.id, v_mat_id, 'SERVIACERO', 3664.44, true, 'PRECIOS DE ACERO.xlsx (Hoja1)', 'import-2r13')
        ON CONFLICT (material_id, proveedor)
        DO UPDATE SET precio = EXCLUDED.precio, incluye_iva = EXCLUDED.incluye_iva, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;

        -- Material: Placa de grado A-36 de 3/16" en 4X10'
        INSERT INTO acero_materiales (organizacion_id, nombre, tipo, ancho_ft, largo_ft, activo, notas)
        VALUES (r_org.id, 'Placa de grado A-36 de 3/16" en 4X10''', 'placa', 4, 10, true, 'import-2r13')
        ON CONFLICT (organizacion_id, nombre)
        DO UPDATE SET tipo = EXCLUDED.tipo, ancho_ft = EXCLUDED.ancho_ft, largo_ft = EXCLUDED.largo_ft, activo = EXCLUDED.activo, notas = EXCLUDED.notas
        RETURNING id INTO v_mat_id;
        INSERT INTO acero_precios (organizacion_id, material_id, proveedor, precio, incluye_iva, fuente, notas)
        VALUES (r_org.id, v_mat_id, 'TANOS', 3123.0139, true, 'PRECIOS DE ACERO.xlsx (Hoja1)', 'import-2r13')
        ON CONFLICT (material_id, proveedor)
        DO UPDATE SET precio = EXCLUDED.precio, incluye_iva = EXCLUDED.incluye_iva, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;
        INSERT INTO acero_precios (organizacion_id, material_id, proveedor, precio, incluye_iva, fuente, notas)
        VALUES (r_org.id, v_mat_id, 'FORTACERO', 3136.7238, true, 'PRECIOS DE ACERO.xlsx (Hoja1)', 'import-2r13')
        ON CONFLICT (material_id, proveedor)
        DO UPDATE SET precio = EXCLUDED.precio, incluye_iva = EXCLUDED.incluye_iva, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;
        INSERT INTO acero_precios (organizacion_id, material_id, proveedor, precio, incluye_iva, fuente, notas)
        VALUES (r_org.id, v_mat_id, 'SERVIACERO', 3027.1476, true, 'PRECIOS DE ACERO.xlsx (Hoja1)', 'import-2r13')
        ON CONFLICT (material_id, proveedor)
        DO UPDATE SET precio = EXCLUDED.precio, incluye_iva = EXCLUDED.incluye_iva, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;

        -- Material: Placa de grado A-36 de 3/16" en 3X10'
        INSERT INTO acero_materiales (organizacion_id, nombre, tipo, ancho_ft, largo_ft, activo, notas)
        VALUES (r_org.id, 'Placa de grado A-36 de 3/16" en 3X10''', 'placa', 3, 10, true, 'import-2r13')
        ON CONFLICT (organizacion_id, nombre)
        DO UPDATE SET tipo = EXCLUDED.tipo, ancho_ft = EXCLUDED.ancho_ft, largo_ft = EXCLUDED.largo_ft, activo = EXCLUDED.activo, notas = EXCLUDED.notas
        RETURNING id INTO v_mat_id;
        INSERT INTO acero_precios (organizacion_id, material_id, proveedor, precio, incluye_iva, fuente, notas)
        VALUES (r_org.id, v_mat_id, 'FORTACERO', 2384.96, true, 'PRECIOS DE ACERO.xlsx (Hoja1)', 'import-2r13')
        ON CONFLICT (material_id, proveedor)
        DO UPDATE SET precio = EXCLUDED.precio, incluye_iva = EXCLUDED.incluye_iva, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;
        INSERT INTO acero_precios (organizacion_id, material_id, proveedor, precio, incluye_iva, fuente, notas)
        VALUES (r_org.id, v_mat_id, 'SERVIACERO', 2296.162, true, 'PRECIOS DE ACERO.xlsx (Hoja1)', 'import-2r13')
        ON CONFLICT (material_id, proveedor)
        DO UPDATE SET precio = EXCLUDED.precio, incluye_iva = EXCLUDED.incluye_iva, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;

        -- Material: Placa de grado A-572-50 de 1/4" en 4X40'
        INSERT INTO acero_materiales (organizacion_id, nombre, tipo, ancho_ft, largo_ft, activo, notas)
        VALUES (r_org.id, 'Placa de grado A-572-50 de 1/4" en 4X40''', 'placa', 4, 40, true, 'import-2r13')
        ON CONFLICT (organizacion_id, nombre)
        DO UPDATE SET tipo = EXCLUDED.tipo, ancho_ft = EXCLUDED.ancho_ft, largo_ft = EXCLUDED.largo_ft, activo = EXCLUDED.activo, notas = EXCLUDED.notas
        RETURNING id INTO v_mat_id;
        INSERT INTO acero_precios (organizacion_id, material_id, proveedor, precio, incluye_iva, fuente, notas)
        VALUES (r_org.id, v_mat_id, 'SERVIACERO', 16876.028, true, 'PRECIOS DE ACERO.xlsx (Hoja1)', 'import-2r13')
        ON CONFLICT (material_id, proveedor)
        DO UPDATE SET precio = EXCLUDED.precio, incluye_iva = EXCLUDED.incluye_iva, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;
        INSERT INTO acero_precios (organizacion_id, material_id, proveedor, precio, incluye_iva, fuente, notas)
        VALUES (r_org.id, v_mat_id, 'TPI', 19528.6, true, 'PRECIOS DE ACERO.xlsx (Hoja1)', 'import-2r13')
        ON CONFLICT (material_id, proveedor)
        DO UPDATE SET precio = EXCLUDED.precio, incluye_iva = EXCLUDED.incluye_iva, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;

        -- Material: Placa de grado A-36 de 1/4" en 5X20'
        INSERT INTO acero_materiales (organizacion_id, nombre, tipo, ancho_ft, largo_ft, activo, notas)
        VALUES (r_org.id, 'Placa de grado A-36 de 1/4" en 5X20''', 'placa', 5, 20, true, 'import-2r13')
        ON CONFLICT (organizacion_id, nombre)
        DO UPDATE SET tipo = EXCLUDED.tipo, ancho_ft = EXCLUDED.ancho_ft, largo_ft = EXCLUDED.largo_ft, activo = EXCLUDED.activo, notas = EXCLUDED.notas
        RETURNING id INTO v_mat_id;
        INSERT INTO acero_precios (organizacion_id, material_id, proveedor, precio, incluye_iva, fuente, notas)
        VALUES (r_org.id, v_mat_id, 'SERVIACERO', 9771.84, true, 'PRECIOS DE ACERO.xlsx (Hoja1)', 'import-2r13')
        ON CONFLICT (material_id, proveedor)
        DO UPDATE SET precio = EXCLUDED.precio, incluye_iva = EXCLUDED.incluye_iva, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;

        -- Material: Placa de grado A-36 de 1/4" en 5X10'
        INSERT INTO acero_materiales (organizacion_id, nombre, tipo, ancho_ft, largo_ft, activo, notas)
        VALUES (r_org.id, 'Placa de grado A-36 de 1/4" en 5X10''', 'placa', 5, 10, true, 'import-2r13')
        ON CONFLICT (organizacion_id, nombre)
        DO UPDATE SET tipo = EXCLUDED.tipo, ancho_ft = EXCLUDED.ancho_ft, largo_ft = EXCLUDED.largo_ft, activo = EXCLUDED.activo, notas = EXCLUDED.notas
        RETURNING id INTO v_mat_id;
        INSERT INTO acero_precios (organizacion_id, material_id, proveedor, precio, incluye_iva, fuente, notas)
        VALUES (r_org.id, v_mat_id, 'FORTACERO', 5230.9272, true, 'PRECIOS DE ACERO.xlsx (Hoja1)', 'import-2r13')
        ON CONFLICT (material_id, proveedor)
        DO UPDATE SET precio = EXCLUDED.precio, incluye_iva = EXCLUDED.incluye_iva, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;
        INSERT INTO acero_precios (organizacion_id, material_id, proveedor, precio, incluye_iva, fuente, notas)
        VALUES (r_org.id, v_mat_id, 'SERVIACERO', 4885.92, true, 'PRECIOS DE ACERO.xlsx (Hoja1)', 'import-2r13')
        ON CONFLICT (material_id, proveedor)
        DO UPDATE SET precio = EXCLUDED.precio, incluye_iva = EXCLUDED.incluye_iva, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;

        -- Material: Placa de grado A-36 de 1/4" en 4X10'
        INSERT INTO acero_materiales (organizacion_id, nombre, tipo, ancho_ft, largo_ft, activo, notas)
        VALUES (r_org.id, 'Placa de grado A-36 de 1/4" en 4X10''', 'placa', 4, 10, true, 'import-2r13')
        ON CONFLICT (organizacion_id, nombre)
        DO UPDATE SET tipo = EXCLUDED.tipo, ancho_ft = EXCLUDED.ancho_ft, largo_ft = EXCLUDED.largo_ft, activo = EXCLUDED.activo, notas = EXCLUDED.notas
        RETURNING id INTO v_mat_id;
        INSERT INTO acero_precios (organizacion_id, material_id, proveedor, precio, incluye_iva, fuente, notas)
        VALUES (r_org.id, v_mat_id, 'TANOS', 4163.3966, true, 'PRECIOS DE ACERO.xlsx (Hoja1)', 'import-2r13')
        ON CONFLICT (material_id, proveedor)
        DO UPDATE SET precio = EXCLUDED.precio, incluye_iva = EXCLUDED.incluye_iva, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;
        INSERT INTO acero_precios (organizacion_id, material_id, proveedor, precio, incluye_iva, fuente, notas)
        VALUES (r_org.id, v_mat_id, 'FORTACERO', 4193.3374, true, 'PRECIOS DE ACERO.xlsx (Hoja1)', 'import-2r13')
        ON CONFLICT (material_id, proveedor)
        DO UPDATE SET precio = EXCLUDED.precio, incluye_iva = EXCLUDED.incluye_iva, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;
        INSERT INTO acero_precios (organizacion_id, material_id, proveedor, precio, incluye_iva, fuente, notas)
        VALUES (r_org.id, v_mat_id, 'SERVIACERO', 4036.1968, true, 'PRECIOS DE ACERO.xlsx (Hoja1)', 'import-2r13')
        ON CONFLICT (material_id, proveedor)
        DO UPDATE SET precio = EXCLUDED.precio, incluye_iva = EXCLUDED.incluye_iva, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;

        -- Material: Placa de grado A-36 de 3/8" en 4X10'
        INSERT INTO acero_materiales (organizacion_id, nombre, tipo, ancho_ft, largo_ft, activo, notas)
        VALUES (r_org.id, 'Placa de grado A-36 de 3/8" en 4X10''', 'placa', 4, 10, true, 'import-2r13')
        ON CONFLICT (organizacion_id, nombre)
        DO UPDATE SET tipo = EXCLUDED.tipo, ancho_ft = EXCLUDED.ancho_ft, largo_ft = EXCLUDED.largo_ft, activo = EXCLUDED.activo, notas = EXCLUDED.notas
        RETURNING id INTO v_mat_id;
        INSERT INTO acero_precios (organizacion_id, material_id, proveedor, precio, incluye_iva, fuente, notas)
        VALUES (r_org.id, v_mat_id, 'TANOS', 6231.0908, true, 'PRECIOS DE ACERO.xlsx (Hoja1)', 'import-2r13')
        ON CONFLICT (material_id, proveedor)
        DO UPDATE SET precio = EXCLUDED.precio, incluye_iva = EXCLUDED.incluye_iva, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;
        INSERT INTO acero_precios (organizacion_id, material_id, proveedor, precio, incluye_iva, fuente, notas)
        VALUES (r_org.id, v_mat_id, 'FORTACERO', 6290.2299, true, 'PRECIOS DE ACERO.xlsx (Hoja1)', 'import-2r13')
        ON CONFLICT (material_id, proveedor)
        DO UPDATE SET precio = EXCLUDED.precio, incluye_iva = EXCLUDED.incluye_iva, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;
        INSERT INTO acero_precios (organizacion_id, material_id, proveedor, precio, incluye_iva, fuente, notas)
        VALUES (r_org.id, v_mat_id, 'SERVIACERO', 6054.2952, true, 'PRECIOS DE ACERO.xlsx (Hoja1)', 'import-2r13')
        ON CONFLICT (material_id, proveedor)
        DO UPDATE SET precio = EXCLUDED.precio, incluye_iva = EXCLUDED.incluye_iva, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;

        -- Material: Placa de grado A-36 de 1/2" en 5X20'
        INSERT INTO acero_materiales (organizacion_id, nombre, tipo, ancho_ft, largo_ft, activo, notas)
        VALUES (r_org.id, 'Placa de grado A-36 de 1/2" en 5X20''', 'placa', 5, 20, true, 'import-2r13')
        ON CONFLICT (organizacion_id, nombre)
        DO UPDATE SET tipo = EXCLUDED.tipo, ancho_ft = EXCLUDED.ancho_ft, largo_ft = EXCLUDED.largo_ft, activo = EXCLUDED.activo, notas = EXCLUDED.notas
        RETURNING id INTO v_mat_id;
        INSERT INTO acero_precios (organizacion_id, material_id, proveedor, precio, incluye_iva, fuente, notas)
        VALUES (r_org.id, v_mat_id, 'SERVIACERO', 20086.7688, true, 'PRECIOS DE ACERO.xlsx (Hoja1)', 'import-2r13')
        ON CONFLICT (material_id, proveedor)
        DO UPDATE SET precio = EXCLUDED.precio, incluye_iva = EXCLUDED.incluye_iva, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;

        -- Material: Placa de grado A-36 de 1/2" en 5X10'
        INSERT INTO acero_materiales (organizacion_id, nombre, tipo, ancho_ft, largo_ft, activo, notas)
        VALUES (r_org.id, 'Placa de grado A-36 de 1/2" en 5X10''', 'placa', 5, 10, true, 'import-2r13')
        ON CONFLICT (organizacion_id, nombre)
        DO UPDATE SET tipo = EXCLUDED.tipo, ancho_ft = EXCLUDED.ancho_ft, largo_ft = EXCLUDED.largo_ft, activo = EXCLUDED.activo, notas = EXCLUDED.notas
        RETURNING id INTO v_mat_id;
        INSERT INTO acero_precios (organizacion_id, material_id, proveedor, precio, incluye_iva, fuente, notas)
        VALUES (r_org.id, v_mat_id, 'FORTACERO', 10895.7408, true, 'PRECIOS DE ACERO.xlsx (Hoja1)', 'import-2r13')
        ON CONFLICT (material_id, proveedor)
        DO UPDATE SET precio = EXCLUDED.precio, incluye_iva = EXCLUDED.incluye_iva, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;

        -- Material: Lamina Negra Cal. 12 4X10'
        INSERT INTO acero_materiales (organizacion_id, nombre, tipo, ancho_ft, largo_ft, activo, notas)
        VALUES (r_org.id, 'Lamina Negra Cal. 12 4X10''', 'lamina', 4, 10, true, 'import-2r13')
        ON CONFLICT (organizacion_id, nombre)
        DO UPDATE SET tipo = EXCLUDED.tipo, ancho_ft = EXCLUDED.ancho_ft, largo_ft = EXCLUDED.largo_ft, activo = EXCLUDED.activo, notas = EXCLUDED.notas
        RETURNING id INTO v_mat_id;
        INSERT INTO acero_precios (organizacion_id, material_id, proveedor, precio, incluye_iva, fuente, notas)
        VALUES (r_org.id, v_mat_id, 'REFERENCIA (Excel costeo)', 1786, true, 'COSTEO DE PLACA.xlsx; proveedor no indicado, medida 4X10 supuesta', 'import-2r13')
        ON CONFLICT (material_id, proveedor)
        DO UPDATE SET precio = EXCLUDED.precio, incluye_iva = EXCLUDED.incluye_iva, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;

        -- Material: Lamina Negra Cal. 14 4X10'
        INSERT INTO acero_materiales (organizacion_id, nombre, tipo, ancho_ft, largo_ft, activo, notas)
        VALUES (r_org.id, 'Lamina Negra Cal. 14 4X10''', 'lamina', 4, 10, true, 'import-2r13')
        ON CONFLICT (organizacion_id, nombre)
        DO UPDATE SET tipo = EXCLUDED.tipo, ancho_ft = EXCLUDED.ancho_ft, largo_ft = EXCLUDED.largo_ft, activo = EXCLUDED.activo, notas = EXCLUDED.notas
        RETURNING id INTO v_mat_id;
        INSERT INTO acero_precios (organizacion_id, material_id, proveedor, precio, incluye_iva, fuente, notas)
        VALUES (r_org.id, v_mat_id, 'REFERENCIA (Excel costeo)', 1435, true, 'COSTEO DE PLACA.xlsx; proveedor no indicado, medida 4X10 supuesta', 'import-2r13')
        ON CONFLICT (material_id, proveedor)
        DO UPDATE SET precio = EXCLUDED.precio, incluye_iva = EXCLUDED.incluye_iva, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;
    END LOOP;
END $$;

COMMIT;
