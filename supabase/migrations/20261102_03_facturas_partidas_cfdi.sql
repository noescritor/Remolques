-- Migración 20261102_03_facturas_partidas_cfdi.sql
-- Sub-bloque T4: Partidas por factura, XML CFDI 3.3/4.0 e importación segura
-- Idempotente: diseñada para ejecutarse múltiples veces con los mismos resultados.

BEGIN;

-- 1. Ampliación de facturas_proveedor (columnas para desglose fiscal y UUID CFDI)
ALTER TABLE facturas_proveedor
    ADD COLUMN IF NOT EXISTS uuid_fiscal TEXT,
    ADD COLUMN IF NOT EXISTS subtotal NUMERIC(14,2),
    ADD COLUMN IF NOT EXISTS descuento NUMERIC(14,2) DEFAULT 0,
    ADD COLUMN IF NOT EXISTS impuestos_trasladados NUMERIC(14,2) DEFAULT 0,
    ADD COLUMN IF NOT EXISTS impuestos_retenidos NUMERIC(14,2) DEFAULT 0;

CREATE INDEX IF NOT EXISTS idx_facturas_proveedor_org_uuid 
    ON facturas_proveedor(organizacion_id, uuid_fiscal);

-- 2. Tabla factura_proveedor_partidas (cargos, conceptos, impuestos y descuentos desglosados)
CREATE TABLE IF NOT EXISTS factura_proveedor_partidas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organizacion_id UUID NOT NULL REFERENCES organizaciones(id) ON DELETE CASCADE,
    factura_id UUID NOT NULL REFERENCES facturas_proveedor(id) ON DELETE CASCADE,
    tipo TEXT NOT NULL CHECK (tipo IN ('concepto', 'impuesto_trasladado', 'retencion', 'descuento', 'otro_cargo')),
    descripcion TEXT NOT NULL,
    cantidad NUMERIC(14,4) NOT NULL DEFAULT 1 CHECK (cantidad > 0),
    precio_unitario NUMERIC(14,4) NOT NULL DEFAULT 0 CHECK (precio_unitario >= 0),
    importe NUMERIC(14,2) NOT NULL CHECK (importe >= 0),
    tasa_o_cuota NUMERIC(8,4),
    clave_sat TEXT,
    clave_unidad TEXT,
    orden INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

CREATE INDEX IF NOT EXISTS idx_factura_proveedor_partidas_factura 
    ON factura_proveedor_partidas(factura_id);
CREATE INDEX IF NOT EXISTS idx_factura_proveedor_partidas_org 
    ON factura_proveedor_partidas(organizacion_id);

ALTER TABLE factura_proveedor_partidas ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "org_factura_proveedor_partidas_policy" ON factura_proveedor_partidas;
CREATE POLICY "org_factura_proveedor_partidas_policy" ON factura_proveedor_partidas
    FOR ALL TO authenticated
    USING (organizacion_id = get_current_org_id())
    WITH CHECK (organizacion_id = get_current_org_id());

-- 3. Tabla facturas_proveedor_cfdi (repositorio seguro de XML originales con unicidad por UUID fiscal)
CREATE TABLE IF NOT EXISTS facturas_proveedor_cfdi (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organizacion_id UUID NOT NULL REFERENCES organizaciones(id) ON DELETE CASCADE,
    factura_id UUID REFERENCES facturas_proveedor(id) ON DELETE SET NULL,
    uuid_fiscal TEXT NOT NULL,
    version TEXT NOT NULL CHECK (version IN ('3.3', '4.0')),
    rfc_emisor TEXT NOT NULL,
    nombre_emisor TEXT,
    rfc_receptor TEXT NOT NULL,
    serie TEXT,
    folio TEXT,
    fecha_emision TIMESTAMPTZ NOT NULL,
    moneda TEXT NOT NULL DEFAULT 'MXN' CHECK (moneda IN ('MXN', 'USD')),
    tipo_cambio NUMERIC(12,4) DEFAULT 1.0000,
    subtotal NUMERIC(14,2) NOT NULL,
    descuento NUMERIC(14,2) NOT NULL DEFAULT 0,
    impuestos_trasladados NUMERIC(14,2) NOT NULL DEFAULT 0,
    impuestos_retenidos NUMERIC(14,2) NOT NULL DEFAULT 0,
    total NUMERIC(14,2) NOT NULL CHECK (total > 0),
    metodo_pago TEXT,
    forma_pago TEXT,
    xml_contenido TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    CONSTRAINT uq_facturas_cfdi_org_uuid UNIQUE (organizacion_id, uuid_fiscal)
);

CREATE INDEX IF NOT EXISTS idx_facturas_cfdi_org_uuid 
    ON facturas_proveedor_cfdi(organizacion_id, uuid_fiscal);
CREATE INDEX IF NOT EXISTS idx_facturas_cfdi_factura 
    ON facturas_proveedor_cfdi(factura_id);

ALTER TABLE facturas_proveedor_cfdi ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "org_facturas_proveedor_cfdi_policy" ON facturas_proveedor_cfdi;
CREATE POLICY "org_facturas_proveedor_cfdi_policy" ON facturas_proveedor_cfdi
    FOR ALL TO authenticated
    USING (organizacion_id = get_current_org_id())
    WITH CHECK (organizacion_id = get_current_org_id());

-- 4. Función RPC atómica guardar_factura_con_partidas
CREATE OR REPLACE FUNCTION guardar_factura_con_partidas(
    p_organizacion_id UUID,
    p_factura_id UUID,
    p_proveedor_id UUID,
    p_folio TEXT,
    p_sucursal TEXT,
    p_fecha_emision DATE,
    p_dias_credito INTEGER,
    p_fecha_vencimiento DATE,
    p_moneda TEXT,
    p_importe NUMERIC,
    p_tipo_cambio_emision NUMERIC,
    p_concepto TEXT,
    p_uuid_fiscal TEXT,
    p_subtotal NUMERIC,
    p_descuento NUMERIC,
    p_impuestos_trasladados NUMERIC,
    p_impuestos_retenidos NUMERIC,
    p_partidas JSONB
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_factura_id UUID := p_factura_id;
    v_total_pagado NUMERIC(14,2) := 0;
    v_importe_redondeado NUMERIC(14,2);
    v_partida RECORD;
    v_orden INTEGER := 0;
BEGIN
    v_importe_redondeado := round(p_importe, 2);

    IF v_importe_redondeado <= 0 THEN
        RAISE EXCEPTION 'importe_invalido: El importe de la factura debe ser mayor a 0';
    END IF;

    -- Validar si la factura ya existe y verificar pagos previos
    IF v_factura_id IS NOT NULL THEN
        SELECT COALESCE(SUM(round(monto, 2)), 0)
        INTO v_total_pagado
        FROM pagos_factura
        WHERE factura_id = v_factura_id
          AND anulado = false;

        IF v_importe_redondeado < v_total_pagado THEN
            RAISE EXCEPTION 'nuevo_total_menor_que_pagado: El nuevo importe (%) no puede ser menor al monto ya pagado (%)', 
                v_importe_redondeado, v_total_pagado;
        END IF;

        UPDATE facturas_proveedor
        SET proveedor_id = p_proveedor_id,
            folio = p_folio,
            sucursal = p_sucursal,
            fecha_emision = p_fecha_emision,
            dias_credito = COALESCE(p_dias_credito, 30),
            fecha_vencimiento = p_fecha_vencimiento,
            moneda = p_moneda,
            importe = v_importe_redondeado,
            tipo_cambio_emision = p_tipo_cambio_emision,
            concepto = p_concepto,
            uuid_fiscal = p_uuid_fiscal,
            subtotal = p_subtotal,
            descuento = COALESCE(p_descuento, 0),
            impuestos_trasladados = COALESCE(p_impuestos_trasladados, 0),
            impuestos_retenidos = COALESCE(p_impuestos_retenidos, 0),
            updated_at = timezone('utc', now())
        WHERE id = v_factura_id
          AND organizacion_id = p_organizacion_id;

        -- Reemplazar partidas
        DELETE FROM factura_proveedor_partidas WHERE factura_id = v_factura_id;
    ELSE
        INSERT INTO facturas_proveedor (
            organizacion_id,
            proveedor_id,
            folio,
            sucursal,
            fecha_emision,
            dias_credito,
            fecha_vencimiento,
            moneda,
            importe,
            tipo_cambio_emision,
            concepto,
            uuid_fiscal,
            subtotal,
            descuento,
            impuestos_trasladados,
            impuestos_retenidos
        ) VALUES (
            p_organizacion_id,
            p_proveedor_id,
            p_folio,
            p_sucursal,
            p_fecha_emision,
            COALESCE(p_dias_credito, 30),
            p_fecha_vencimiento,
            p_moneda,
            v_importe_redondeado,
            p_tipo_cambio_emision,
            p_concepto,
            p_uuid_fiscal,
            p_subtotal,
            COALESCE(p_descuento, 0),
            COALESCE(p_impuestos_trasladados, 0),
            COALESCE(p_impuestos_retenidos, 0)
        )
        RETURNING id INTO v_factura_id;
    END IF;

    -- Insertar partidas si vienen en el payload JSONB
    IF p_partidas IS NOT NULL AND jsonb_typeof(p_partidas) = 'array' THEN
        FOR v_partida IN 
            SELECT * FROM jsonb_to_recordset(p_partidas) AS x(
                tipo TEXT,
                descripcion TEXT,
                cantidad NUMERIC,
                precio_unitario NUMERIC,
                importe NUMERIC,
                tasa_o_cuota NUMERIC,
                clave_sat TEXT,
                clave_unidad TEXT
            )
        LOOP
            v_orden := v_orden + 1;
            INSERT INTO factura_proveedor_partidas (
                organizacion_id,
                factura_id,
                tipo,
                descripcion,
                cantidad,
                precio_unitario,
                importe,
                tasa_o_cuota,
                clave_sat,
                clave_unidad,
                orden
            ) VALUES (
                p_organizacion_id,
                v_factura_id,
                COALESCE(v_partida.tipo, 'concepto'),
                COALESCE(v_partida.descripcion, 'Partida sin descripción'),
                COALESCE(v_partida.cantidad, 1),
                COALESCE(v_partida.precio_unitario, 0),
                round(COALESCE(v_partida.importe, 0), 2),
                v_partida.tasa_o_cuota,
                v_partida.clave_sat,
                v_partida.clave_unidad,
                v_orden
            );
        END LOOP;
    END IF;

    RETURN jsonb_build_object(
        'ok', true,
        'factura_id', v_factura_id,
        'importe', v_importe_redondeado,
        'total_pagado', v_total_pagado,
        'partidas_guardadas', v_orden
    );
END;
$$;

REVOKE ALL ON FUNCTION guardar_factura_con_partidas FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION guardar_factura_con_partidas TO service_role;

COMMIT;
