-- Migración 20261030_01_cxp_facturas.sql
-- Sub-bloque 2R-16: Cuentas por pagar con facturas, dólares y conciliación
-- Idempotente: diseñada para ejecutarse múltiples veces con los mismos resultados.

BEGIN;

-- 1. Modificación a la tabla proveedores (campos de crédito, razón social, RFC y moneda)
ALTER TABLE proveedores
    ADD COLUMN IF NOT EXISTS razon_social TEXT,
    ADD COLUMN IF NOT EXISTS rfc TEXT,
    ADD COLUMN IF NOT EXISTS moneda_default TEXT DEFAULT 'MXN',
    ADD COLUMN IF NOT EXISTS dias_credito INTEGER,
    ADD COLUMN IF NOT EXISTS limite_credito NUMERIC(14,2),
    ADD COLUMN IF NOT EXISTS limite_credito_moneda TEXT,
    ADD COLUMN IF NOT EXISTS notas_credito TEXT;

-- Restricciones de chequeo en proveedores (idempotentes mediante bloque DO)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_proveedores_moneda_default') THEN
        ALTER TABLE proveedores ADD CONSTRAINT chk_proveedores_moneda_default 
            CHECK (moneda_default IN ('MXN', 'USD'));
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_proveedores_dias_credito') THEN
        ALTER TABLE proveedores ADD CONSTRAINT chk_proveedores_dias_credito 
            CHECK (dias_credito IS NULL OR dias_credito >= 0);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_proveedores_limite_credito') THEN
        ALTER TABLE proveedores ADD CONSTRAINT chk_proveedores_limite_credito 
            CHECK (limite_credito IS NULL OR limite_credito >= 0);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_proveedores_limite_credito_moneda') THEN
        ALTER TABLE proveedores ADD CONSTRAINT chk_proveedores_limite_credito_moneda 
            CHECK (limite_credito_moneda IS NULL OR limite_credito_moneda IN ('MXN', 'USD'));
    END IF;
END $$;

-- 2. Tabla tipos_cambio
CREATE TABLE IF NOT EXISTS tipos_cambio (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organizacion_id UUID NOT NULL REFERENCES organizaciones(id) ON DELETE CASCADE,
    fecha DATE NOT NULL,
    moneda TEXT NOT NULL CHECK (moneda = 'USD'),
    valor NUMERIC(12,4) NOT NULL CHECK (valor > 0),
    fuente TEXT,
    notas TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_tipos_cambio_org_fecha_moneda UNIQUE (organizacion_id, fecha, moneda)
);

ALTER TABLE tipos_cambio ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "org_tipos_cambio_policy" ON tipos_cambio;
CREATE POLICY "org_tipos_cambio_policy" ON tipos_cambio
    FOR ALL TO authenticated
    USING (organizacion_id = get_current_org_id())
    WITH CHECK (organizacion_id = get_current_org_id());

CREATE INDEX IF NOT EXISTS idx_tipos_cambio_org_fecha ON tipos_cambio(organizacion_id, fecha DESC);

-- 3. Tabla facturas_proveedor
CREATE TABLE IF NOT EXISTS facturas_proveedor (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organizacion_id UUID NOT NULL REFERENCES organizaciones(id) ON DELETE CASCADE,
    proveedor_id UUID NOT NULL REFERENCES proveedores(id) ON DELETE RESTRICT,
    compra_id UUID REFERENCES compras_proveedor(id) ON DELETE SET NULL,
    sucursal TEXT,
    folio TEXT NOT NULL,
    nota TEXT,
    fecha_emision DATE NOT NULL,
    dias_credito INTEGER NOT NULL DEFAULT 30 CHECK (dias_credito >= 0),
    fecha_vencimiento DATE NOT NULL,
    moneda TEXT NOT NULL CHECK (moneda IN ('MXN', 'USD')),
    importe NUMERIC(14,2) NOT NULL CHECK (importe > 0),
    tipo_cambio_emision NUMERIC(12,4),
    concepto TEXT,
    estado TEXT NOT NULL DEFAULT 'abierta' CHECK (estado IN ('abierta', 'cancelada')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE facturas_proveedor ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "org_facturas_proveedor_policy" ON facturas_proveedor;
CREATE POLICY "org_facturas_proveedor_policy" ON facturas_proveedor
    FOR ALL TO authenticated
    USING (organizacion_id = get_current_org_id())
    WITH CHECK (organizacion_id = get_current_org_id());

-- Índice único por organización, proveedor, sucursal (coalescida a vacío) y folio
CREATE UNIQUE INDEX IF NOT EXISTS uq_facturas_proveedor_folio 
    ON facturas_proveedor (organizacion_id, proveedor_id, coalesce(sucursal, ''), folio);

CREATE INDEX IF NOT EXISTS idx_facturas_proveedor_org_vence 
    ON facturas_proveedor (organizacion_id, fecha_vencimiento);
CREATE INDEX IF NOT EXISTS idx_facturas_proveedor_org_prov 
    ON facturas_proveedor (organizacion_id, proveedor_id, estado);

-- 4. Tabla pagos_factura
CREATE TABLE IF NOT EXISTS pagos_factura (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organizacion_id UUID NOT NULL REFERENCES organizaciones(id) ON DELETE CASCADE,
    factura_id UUID NOT NULL REFERENCES facturas_proveedor(id) ON DELETE RESTRICT,
    fecha_pago DATE NOT NULL,
    monto NUMERIC(14,2) NOT NULL CHECK (monto > 0),
    tipo_cambio NUMERIC(12,4),
    metodo_pago TEXT NOT NULL,
    referencia TEXT,
    complemento_pago TEXT,
    notas TEXT,
    anulado BOOLEAN NOT NULL DEFAULT false,
    anulado_motivo TEXT,
    anulado_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE pagos_factura ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "org_pagos_factura_policy" ON pagos_factura;
CREATE POLICY "org_pagos_factura_policy" ON pagos_factura
    FOR ALL TO authenticated
    USING (organizacion_id = get_current_org_id())
    WITH CHECK (organizacion_id = get_current_org_id());

CREATE INDEX IF NOT EXISTS idx_pagos_factura_factura 
    ON pagos_factura (factura_id, anulado);
CREATE INDEX IF NOT EXISTS idx_pagos_factura_org_fecha 
    ON pagos_factura (organizacion_id, fecha_pago DESC);

-- 5. Tabla estados_cuenta_proveedor
CREATE TABLE IF NOT EXISTS estados_cuenta_proveedor (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organizacion_id UUID NOT NULL REFERENCES organizaciones(id) ON DELETE CASCADE,
    proveedor_id UUID NOT NULL REFERENCES proveedores(id) ON DELETE RESTRICT,
    fecha DATE NOT NULL,
    moneda TEXT NOT NULL CHECK (moneda IN ('MXN', 'USD')),
    saldo NUMERIC(14,2) NOT NULL,
    notas TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_estados_cuenta_org_prov_fecha_moneda UNIQUE (organizacion_id, proveedor_id, fecha, moneda)
);

ALTER TABLE estados_cuenta_proveedor ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "org_estados_cuenta_policy" ON estados_cuenta_proveedor;
CREATE POLICY "org_estados_cuenta_policy" ON estados_cuenta_proveedor
    FOR ALL TO authenticated
    USING (organizacion_id = get_current_org_id())
    WITH CHECK (organizacion_id = get_current_org_id());

CREATE INDEX IF NOT EXISTS idx_estados_cuenta_org_prov 
    ON estados_cuenta_proveedor (organizacion_id, proveedor_id, fecha DESC);

-- 6. Vista v_facturas_proveedor_saldo con WITH (security_invoker = true)
CREATE OR REPLACE VIEW v_facturas_proveedor_saldo
WITH (security_invoker = true) AS
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
    p.fecha_ultimo_pago
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

-- 7. Función registrar_pago_factura (SECURITY DEFINER con bloqueo FOR UPDATE)
CREATE OR REPLACE FUNCTION registrar_pago_factura(
    p_org UUID,
    p_factura_id UUID,
    p_fecha DATE,
    p_monto NUMERIC,
    p_tipo_cambio NUMERIC,
    p_metodo TEXT,
    p_referencia TEXT,
    p_complemento TEXT,
    p_notas TEXT
) RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
    v_factura RECORD;
    v_pagado NUMERIC(14,2);
    v_saldo NUMERIC(14,2);
    v_pago_id UUID;
    v_saldo_restante NUMERIC(14,2);
BEGIN
    -- Redondear monto a 2 decimales
    p_monto := ROUND(COALESCE(p_monto, 0), 2);

    -- Validar monto
    IF p_monto IS NULL OR p_monto <= 0 THEN
        RETURN jsonb_build_object('exito', false, 'error', 'monto_invalido', 'mensaje', 'El monto del pago debe ser mayor a 0');
    END IF;

    -- Validar fecha
    IF p_fecha IS NULL THEN
        RETURN jsonb_build_object('exito', false, 'error', 'fecha_invalida', 'mensaje', 'La fecha de pago es obligatoria');
    END IF;

    -- Bloquear y obtener factura
    SELECT * INTO v_factura
    FROM facturas_proveedor
    WHERE id = p_factura_id AND organizacion_id = p_org
    FOR UPDATE;

    IF v_factura.id IS NULL THEN
        RETURN jsonb_build_object('exito', false, 'error', 'no_encontrada', 'mensaje', 'Factura no encontrada o pertenece a otra organización');
    END IF;

    IF v_factura.estado = 'cancelada' THEN
        RETURN jsonb_build_object('exito', false, 'error', 'cancelada', 'mensaje', 'No se pueden registrar pagos a una factura cancelada');
    END IF;

    -- Si la factura es en USD, el tipo de cambio es obligatorio y debe ser > 0
    IF v_factura.moneda = 'USD' AND (p_tipo_cambio IS NULL OR p_tipo_cambio <= 0) THEN
        RETURN jsonb_build_object('exito', false, 'error', 'tipo_cambio_requerido', 'mensaje', 'El tipo de cambio es obligatorio para pagos de facturas en dólares');
    END IF;

    -- Recalcular saldo bloqueado
    SELECT COALESCE(SUM(monto), 0)::NUMERIC(14,2) INTO v_pagado
    FROM pagos_factura
    WHERE factura_id = p_factura_id AND anulado = false;

    v_saldo := (v_factura.importe - v_pagado)::NUMERIC(14,2);

    IF p_monto > v_saldo THEN
        RETURN jsonb_build_object(
            'exito', false,
            'error', 'excede_saldo',
            'mensaje', 'El monto a pagar excede el saldo restante de la factura',
            'saldo_actual', v_saldo
        );
    END IF;

    v_pago_id := gen_random_uuid();

    INSERT INTO pagos_factura (
        id, organizacion_id, factura_id, fecha_pago, monto,
        tipo_cambio, metodo_pago, referencia, complemento_pago, notas
    ) VALUES (
        v_pago_id, p_org, p_factura_id, p_fecha, p_monto,
        p_tipo_cambio, coalesce(nullif(trim(p_metodo), ''), 'Transferencia'),
        nullif(trim(p_referencia), ''), nullif(trim(p_complemento), ''), nullif(trim(p_notas), '')
    );

    v_saldo_restante := (v_saldo - p_monto)::NUMERIC(14,2);

    RETURN jsonb_build_object(
        'exito', true,
        'pago_id', v_pago_id,
        'saldo_restante', v_saldo_restante
    );
END;
$$;

-- 8. Función anular_pago_factura (SECURITY DEFINER)
CREATE OR REPLACE FUNCTION anular_pago_factura(
    p_org UUID,
    p_pago_id UUID,
    p_motivo TEXT
) RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
    v_pago RECORD;
    v_saldo_restante NUMERIC(14,2);
BEGIN
    IF p_motivo IS NULL OR trim(p_motivo) = '' THEN
        RETURN jsonb_build_object('exito', false, 'error', 'motivo_requerido', 'mensaje', 'Debe especificar el motivo de anulación');
    END IF;

    -- Bloquear pago
    SELECT * INTO v_pago
    FROM pagos_factura
    WHERE id = p_pago_id AND organizacion_id = p_org
    FOR UPDATE;

    IF v_pago.id IS NULL THEN
        RETURN jsonb_build_object('exito', false, 'error', 'no_encontrado', 'mensaje', 'Pago no encontrado o pertenece a otra organización');
    END IF;

    IF v_pago.anulado THEN
        RETURN jsonb_build_object('exito', false, 'error', 'ya_anulado', 'mensaje', 'El pago ya se encuentra anulado');
    END IF;

    UPDATE pagos_factura
    SET anulado = true,
        anulado_motivo = trim(p_motivo),
        anulado_at = now()
    WHERE id = p_pago_id;

    -- Recalcular saldo restante de la factura asociada
    SELECT (f.importe - COALESCE(SUM(p.monto), 0))::NUMERIC(14,2) INTO v_saldo_restante
    FROM facturas_proveedor f
    LEFT JOIN pagos_factura p ON p.factura_id = f.id AND p.anulado = false
    WHERE f.id = v_pago.factura_id
    GROUP BY f.id, f.importe;

    RETURN jsonb_build_object(
        'exito', true,
        'pago_id', p_pago_id,
        'saldo_restante', v_saldo_restante
    );
END;
$$;

-- 9. Restricción estricta de permisos EXECUTE (SECURITY DEFINER exclusivo para service_role)
REVOKE ALL ON FUNCTION registrar_pago_factura(UUID, UUID, DATE, NUMERIC, NUMERIC, TEXT, TEXT, TEXT, TEXT) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION anular_pago_factura(UUID, UUID, TEXT) FROM PUBLIC, anon, authenticated;

GRANT EXECUTE ON FUNCTION registrar_pago_factura(UUID, UUID, DATE, NUMERIC, NUMERIC, TEXT, TEXT, TEXT, TEXT) TO service_role;
GRANT EXECUTE ON FUNCTION anular_pago_factura(UUID, UUID, TEXT) TO service_role;

ALTER FUNCTION registrar_pago_factura(UUID, UUID, DATE, NUMERIC, NUMERIC, TEXT, TEXT, TEXT, TEXT) SET search_path = public;
ALTER FUNCTION anular_pago_factura(UUID, UUID, TEXT) SET search_path = public;

COMMIT;
