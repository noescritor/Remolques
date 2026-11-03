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

-- Índice único parcial por organización y UUID fiscal (impide duplicar CFDI en una misma org)
DROP INDEX IF EXISTS idx_facturas_proveedor_org_uuid;
CREATE UNIQUE INDEX IF NOT EXISTS uq_facturas_proveedor_org_uuid 
    ON facturas_proveedor(organizacion_id, uuid_fiscal)
    WHERE uuid_fiscal IS NOT NULL;

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

-- RLS: authenticated solo tiene permisos de lectura SELECT; mutaciones exclusivas vía RPC o service_role
ALTER TABLE factura_proveedor_partidas ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "org_factura_proveedor_partidas_policy" ON factura_proveedor_partidas;
DROP POLICY IF EXISTS "factura_proveedor_partidas_org_select" ON factura_proveedor_partidas;
CREATE POLICY "factura_proveedor_partidas_org_select" ON factura_proveedor_partidas
    FOR SELECT TO authenticated
    USING (organizacion_id = get_current_org_id());

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

-- RLS: authenticated solo SELECT
ALTER TABLE facturas_proveedor_cfdi ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "org_facturas_proveedor_cfdi_policy" ON facturas_proveedor_cfdi;
DROP POLICY IF EXISTS "facturas_proveedor_cfdi_org_select" ON facturas_proveedor_cfdi;
CREATE POLICY "facturas_proveedor_cfdi_org_select" ON facturas_proveedor_cfdi
    FOR SELECT TO authenticated
    USING (organizacion_id = get_current_org_id());

-- 4. Actualizar vista v_facturas_proveedor_saldo con columnas fiscales y uuid_fiscal al final
CREATE OR REPLACE VIEW v_facturas_proveedor_saldo
WITH (security_invoker = true)
AS
SELECT 
    f.id,
    f.organizacion_id,
    f.proveedor_id,
    f.compra_id,
    f.sucursal,
    f.folio,
    f.nota,
    f.fecha_emision,
    f.dias_credito,
    f.fecha_vencimiento,
    f.moneda,
    f.importe,
    f.tipo_cambio_emision,
    f.concepto,
    f.estado,
    f.created_at,
    f.updated_at,
    COALESCE(p.pagado, 0)::NUMERIC(14,2) AS pagado,
    (f.importe - COALESCE(p.pagado, 0))::NUMERIC(14,2) AS saldo,
    p.fecha_ultimo_pago,
    f.uuid_fiscal,
    COALESCE(f.subtotal, f.importe)::NUMERIC(14,2) AS subtotal,
    COALESCE(f.descuento, 0)::NUMERIC(14,2) AS descuento,
    COALESCE(f.impuestos_trasladados, 0)::NUMERIC(14,2) AS impuestos_trasladados,
    COALESCE(f.impuestos_retenidos, 0)::NUMERIC(14,2) AS impuestos_retenidos,
    COALESCE(p.pagado, 0)::NUMERIC(14,2) AS total_pagado,
    (f.importe - COALESCE(p.pagado, 0))::NUMERIC(14,2) AS saldo_pendiente,
    (f.fecha_vencimiento - (now() AT TIME ZONE 'America/Mexico_City')::date) AS dias_vencimiento,
    CASE 
        WHEN COALESCE(p.pagado, 0) >= f.importe THEN 'pagada'
        WHEN (now() AT TIME ZONE 'America/Mexico_City')::date > f.fecha_vencimiento THEN 'vencida'
        WHEN (now() AT TIME ZONE 'America/Mexico_City')::date >= f.fecha_vencimiento - 7 THEN 'por_vencer'
        ELSE 'al_corriente'
    END AS estado_vencimiento
FROM facturas_proveedor f
LEFT JOIN (
    SELECT 
        factura_id,
        SUM(monto)::NUMERIC(14,2) AS pagado,
        MAX(fecha_pago) AS fecha_ultimo_pago
    FROM pagos_factura
    WHERE anulado = false
    GROUP BY factura_id
) p ON p.factura_id = f.id;

-- 5. Función RPC atómica guardar_factura_con_partidas con FOR UPDATE, validaciones y cuadratura
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
    p_partidas JSONB,
    p_cfdi JSONB DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_factura_id UUID := p_factura_id;
    v_factura RECORD;
    v_total_pagado NUMERIC(14,2) := 0;
    v_importe_redondeado NUMERIC(14,2);
    v_uuid_norm TEXT := NULL;
    v_suma_partidas NUMERIC(14,2) := 0;
    v_partida RECORD;
    v_orden INTEGER := 0;
    v_hay_partidas BOOLEAN := false;
BEGIN
    v_importe_redondeado := round(p_importe, 2);

    IF v_importe_redondeado <= 0 THEN
        RAISE EXCEPTION 'importe_invalido: El importe de la factura debe ser mayor a 0'
            USING ERRCODE = '22003';
    END IF;

    -- Validar que el proveedor pertenezca a la organización
    IF NOT EXISTS (
        SELECT 1 FROM proveedores 
        WHERE id = p_proveedor_id AND organizacion_id = p_organizacion_id
    ) THEN
        RAISE EXCEPTION 'proveedor_no_encontrado: El proveedor no existe o no pertenece a la organización'
            USING ERRCODE = 'P0002';
    END IF;

    -- Normalizar UUID si se proporcionó
    IF p_uuid_fiscal IS NOT NULL AND TRIM(p_uuid_fiscal) <> '' THEN
        v_uuid_norm := UPPER(TRIM(p_uuid_fiscal));
        -- Validar unicidad de UUID dentro de la organización
        IF EXISTS (
            SELECT 1 FROM facturas_proveedor 
            WHERE organizacion_id = p_organizacion_id 
              AND uuid_fiscal = v_uuid_norm 
              AND (v_factura_id IS NULL OR id <> v_factura_id)
        ) THEN
            RAISE EXCEPTION 'uuid_fiscal_duplicado: Ya existe una factura registrada con el UUID % en esta organización', v_uuid_norm
                USING ERRCODE = '23505';
        END IF;
    END IF;

    -- Validar si la factura ya existe y verificar candado FOR UPDATE y pagos previos
    IF v_factura_id IS NOT NULL THEN
        SELECT * INTO v_factura 
        FROM facturas_proveedor 
        WHERE id = v_factura_id AND organizacion_id = p_organizacion_id 
        FOR UPDATE;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'factura_no_encontrada: La factura con ID % no existe o no pertenece a la organización', v_factura_id
                USING ERRCODE = 'P0002';
        END IF;

        -- Sumar pagos vigentes con aislamiento estricto de organización
        SELECT COALESCE(SUM(round(monto, 2)), 0)
        INTO v_total_pagado
        FROM pagos_factura
        WHERE factura_id = v_factura_id
          AND organizacion_id = p_organizacion_id
          AND anulado = false;

        -- Reglas de inmutabilidad si la factura ya tiene pagos registrados
        IF v_total_pagado > 0 THEN
            IF p_moneda <> v_factura.moneda THEN
                RAISE EXCEPTION 'no_se_puede_cambiar_moneda_con_pagos: No se puede cambiar la moneda de una factura que ya cuenta con pagos registrados'
                    USING ERRCODE = '23514';
            END IF;
            IF p_proveedor_id <> v_factura.proveedor_id THEN
                RAISE EXCEPTION 'no_se_puede_cambiar_proveedor_con_pagos: No se puede cambiar el proveedor de una factura que ya cuenta con pagos registrados'
                    USING ERRCODE = '23514';
            END IF;
            IF v_importe_redondeado < v_total_pagado THEN
                RAISE EXCEPTION 'nuevo_total_menor_que_pagado: El nuevo importe (%) no puede ser menor al monto ya pagado (%)', 
                    v_importe_redondeado, v_total_pagado
                    USING ERRCODE = '23514';
            END IF;
        END IF;
    END IF;

    -- Validar cuadratura del importe contra partidas si vienen partidas en el payload
    IF p_partidas IS NOT NULL AND jsonb_typeof(p_partidas) = 'array' AND jsonb_array_length(p_partidas) > 0 THEN
        v_hay_partidas := true;
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
            IF v_partida.tipo IN ('concepto', 'impuesto_trasladado', 'otro_cargo') THEN
                v_suma_partidas := v_suma_partidas + round(COALESCE(v_partida.importe, 0), 2);
            ELSIF v_partida.tipo IN ('descuento', 'retencion') THEN
                v_suma_partidas := v_suma_partidas - round(COALESCE(v_partida.importe, 0), 2);
            END IF;
        END LOOP;

        IF abs(v_importe_redondeado - v_suma_partidas) > 0.05 THEN
            RAISE EXCEPTION 'importe_no_cuadra: El importe de la factura (%) no coincide con la suma neta de las partidas (%)',
                v_importe_redondeado, v_suma_partidas
                USING ERRCODE = '22000',
                      DETAIL = format('Importe factura: %s, Suma calculada de partidas: %s', v_importe_redondeado, v_suma_partidas);
        END IF;
    END IF;

    -- Actualizar o insertar factura
    IF v_factura_id IS NOT NULL THEN
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
            uuid_fiscal = v_uuid_norm,
            subtotal = p_subtotal,
            descuento = COALESCE(p_descuento, 0),
            impuestos_trasladados = COALESCE(p_impuestos_trasladados, 0),
            impuestos_retenidos = COALESCE(p_impuestos_retenidos, 0),
            updated_at = timezone('utc', now())
        WHERE id = v_factura_id
          AND organizacion_id = p_organizacion_id;

        -- Reemplazar partidas de esta factura y organizacion
        DELETE FROM factura_proveedor_partidas 
        WHERE factura_id = v_factura_id AND organizacion_id = p_organizacion_id;
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
            v_uuid_norm,
            p_subtotal,
            COALESCE(p_descuento, 0),
            COALESCE(p_impuestos_trasladados, 0),
            COALESCE(p_impuestos_retenidos, 0)
        )
        RETURNING id INTO v_factura_id;
    END IF;

    -- Insertar partidas si vienen en el payload JSONB
    IF v_hay_partidas THEN
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

    -- Si se incluyó objeto CFDI para registro atómico simultáneo
    IF p_cfdi IS NOT NULL AND v_uuid_norm IS NOT NULL THEN
        INSERT INTO facturas_proveedor_cfdi (
            organizacion_id,
            factura_id,
            uuid_fiscal,
            version,
            rfc_emisor,
            nombre_emisor,
            rfc_receptor,
            serie,
            folio,
            fecha_emision,
            moneda,
            tipo_cambio,
            subtotal,
            descuento,
            impuestos_trasladados,
            impuestos_retenidos,
            total,
            metodo_pago,
            forma_pago,
            xml_contenido
        ) VALUES (
            p_organizacion_id,
            v_factura_id,
            v_uuid_norm,
            COALESCE(p_cfdi->>'version', '4.0'),
            UPPER(COALESCE(p_cfdi->>'rfc_emisor', '')),
            COALESCE(p_cfdi->>'nombre_emisor', 'PROVEEDOR'),
            UPPER(COALESCE(p_cfdi->>'rfc_receptor', '')),
            p_cfdi->>'serie',
            p_cfdi->>'folio',
            COALESCE((p_cfdi->>'fecha_emision')::timestamptz, timezone('utc', now())),
            COALESCE(p_cfdi->>'moneda', p_moneda),
            COALESCE((p_cfdi->>'tipo_cambio')::numeric, p_tipo_cambio_emision, 1.0),
            COALESCE((p_cfdi->>'subtotal')::numeric, p_subtotal, v_importe_redondeado),
            COALESCE((p_cfdi->>'descuento')::numeric, p_descuento, 0),
            COALESCE((p_cfdi->>'impuestos_trasladados')::numeric, p_impuestos_trasladados, 0),
            COALESCE((p_cfdi->>'impuestos_retenidos')::numeric, p_impuestos_retenidos, 0),
            v_importe_redondeado,
            p_cfdi->>'metodo_pago',
            p_cfdi->>'forma_pago',
            COALESCE(p_cfdi->>'xml_contenido', '')
        )
        ON CONFLICT (organizacion_id, uuid_fiscal) DO NOTHING;
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
