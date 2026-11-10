-- Migración 20261110_01_cxp_pagos_por_partida.sql
-- Cuentas por pagar: pago por partida (concepto por concepto) o factura completa
-- Idempotente: diseñada para ejecutarse múltiples veces con los mismos resultados sin alterar datos ya migrados.

BEGIN;

-- 1. Tabla pagos_factura_partidas (distribución de pagos entre partidas individuales)
CREATE TABLE IF NOT EXISTS pagos_factura_partidas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organizacion_id UUID NOT NULL REFERENCES organizaciones(id) ON DELETE CASCADE,
    pago_id UUID NOT NULL REFERENCES pagos_factura(id) ON DELETE CASCADE,
    partida_id UUID NOT NULL REFERENCES factura_proveedor_partidas(id) ON DELETE RESTRICT,
    monto NUMERIC(14,2) NOT NULL CHECK (monto > 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

CREATE INDEX IF NOT EXISTS idx_pagos_factura_partidas_pago 
    ON pagos_factura_partidas(pago_id);
CREATE INDEX IF NOT EXISTS idx_pagos_factura_partidas_partida 
    ON pagos_factura_partidas(partida_id);
CREATE INDEX IF NOT EXISTS idx_pagos_factura_partidas_org 
    ON pagos_factura_partidas(organizacion_id);

-- RLS: authenticated solo tiene permisos de lectura SELECT; escritura exclusiva por RPC / service_role
ALTER TABLE pagos_factura_partidas ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "pagos_factura_partidas_org_select" ON pagos_factura_partidas;
DROP POLICY IF EXISTS "org_pagos_factura_partidas_policy" ON pagos_factura_partidas;

CREATE POLICY "pagos_factura_partidas_org_select" ON pagos_factura_partidas
    FOR SELECT TO authenticated
    USING (organizacion_id = get_current_org_id());

-- 2. Vista v_factura_partidas_saldo con cálculo de importe_a_pagar prorrateado, pagado, saldo y estado
DROP VIEW IF EXISTS v_factura_partidas_saldo CASCADE;
CREATE VIEW v_factura_partidas_saldo
WITH (security_invoker = true)
AS
WITH totales_factura AS (
    SELECT 
        factura_id,
        COALESCE(SUM(CASE WHEN tipo = 'concepto' THEN importe ELSE 0 END), 0)::NUMERIC(14,2) AS subtotal_conceptos,
        COALESCE(SUM(CASE WHEN tipo = 'otro_cargo' THEN importe ELSE 0 END), 0)::NUMERIC(14,2) AS subtotal_otros_cargos,
        COALESCE(SUM(CASE 
            WHEN tipo = 'impuesto_trasladado' THEN importe 
            WHEN tipo IN ('retencion', 'descuento') THEN -importe 
            ELSE 0 
        END), 0)::NUMERIC(14,2) AS neto_ajustes
    FROM factura_proveedor_partidas
    GROUP BY factura_id
),
partidas_base AS (
    SELECT 
        p.*,
        tf.subtotal_conceptos,
        tf.subtotal_otros_cargos,
        tf.neto_ajustes,
        CASE 
            WHEN tf.subtotal_conceptos > 0 AND p.tipo = 'concepto' THEN
                ROUND(tf.neto_ajustes * (p.importe / tf.subtotal_conceptos), 2)
            WHEN tf.subtotal_conceptos = 0 AND tf.subtotal_otros_cargos > 0 AND p.tipo = 'otro_cargo' THEN
                ROUND(tf.neto_ajustes * (p.importe / tf.subtotal_otros_cargos), 2)
            ELSE 0
        END AS ajuste_prorrateado,
        CASE 
            WHEN tf.subtotal_conceptos > 0 AND p.tipo = 'concepto' THEN
                ROW_NUMBER() OVER (
                    PARTITION BY p.factura_id, (p.tipo = 'concepto') 
                    ORDER BY p.orden DESC, p.id DESC
                )
            WHEN tf.subtotal_conceptos = 0 AND tf.subtotal_otros_cargos > 0 AND p.tipo = 'otro_cargo' THEN
                ROW_NUMBER() OVER (
                    PARTITION BY p.factura_id, (p.tipo = 'otro_cargo') 
                    ORDER BY p.orden DESC, p.id DESC
                )
            ELSE 0
        END AS ranking_ultimo
    FROM factura_proveedor_partidas p
    JOIN totales_factura tf ON tf.factura_id = p.factura_id
),
residuos_calculados AS (
    SELECT 
        factura_id,
        (neto_ajustes - SUM(ajuste_prorrateado))::NUMERIC(14,2) AS residuo
    FROM partidas_base
    WHERE (subtotal_conceptos > 0 AND tipo = 'concepto') 
       OR (subtotal_conceptos = 0 AND subtotal_otros_cargos > 0 AND tipo = 'otro_cargo')
    GROUP BY factura_id, neto_ajustes
),
partidas_con_importe AS (
    SELECT 
        pb.id AS partida_id,
        pb.factura_id,
        pb.organizacion_id,
        pb.tipo,
        pb.descripcion,
        pb.cantidad,
        pb.precio_unitario,
        pb.importe,
        CASE 
            WHEN pb.tipo IN ('impuesto_trasladado', 'retencion', 'descuento') THEN 0::NUMERIC(14,2)
            WHEN (pb.subtotal_conceptos > 0 AND pb.tipo = 'concepto') OR 
                 (pb.subtotal_conceptos = 0 AND pb.subtotal_otros_cargos > 0 AND pb.tipo = 'otro_cargo') THEN
                (pb.importe + pb.ajuste_prorrateado + CASE WHEN pb.ranking_ultimo = 1 THEN COALESCE(rc.residuo, 0) ELSE 0 END)::NUMERIC(14,2)
            ELSE
                pb.importe::NUMERIC(14,2)
        END AS importe_a_pagar,
        pb.tasa_o_cuota,
        pb.clave_sat,
        pb.clave_unidad,
        pb.orden,
        pb.created_at
    FROM partidas_base pb
    LEFT JOIN residuos_calculados rc ON rc.factura_id = pb.factura_id
)
SELECT 
    pi.partida_id AS id,
    pi.partida_id,
    pi.factura_id,
    pi.organizacion_id,
    pi.tipo,
    pi.descripcion,
    pi.cantidad,
    pi.precio_unitario,
    pi.importe,
    pi.importe_a_pagar,
    COALESCE(pag.monto_pagado, 0)::NUMERIC(14,2) AS pagado,
    GREATEST(0, (pi.importe_a_pagar - COALESCE(pag.monto_pagado, 0)))::NUMERIC(14,2) AS saldo,
    CASE 
        WHEN pi.tipo IN ('impuesto_trasladado', 'retencion', 'descuento') THEN 'Liquidada'
        WHEN COALESCE(pag.monto_pagado, 0) >= pi.importe_a_pagar AND pi.importe_a_pagar > 0 THEN 'Liquidada'
        WHEN COALESCE(pag.monto_pagado, 0) > 0 THEN 'Parcial'
        ELSE 'Pendiente'
    END AS estado,
    pi.tasa_o_cuota,
    pi.clave_sat,
    pi.clave_unidad,
    pi.orden,
    pi.created_at
FROM partidas_con_importe pi
LEFT JOIN (
    SELECT 
        pfp.partida_id,
        SUM(pfp.monto)::NUMERIC(14,2) AS monto_pagado
    FROM pagos_factura_partidas pfp
    JOIN pagos_factura pf ON pf.id = pfp.pago_id
    WHERE pf.anulado = false
    GROUP BY pfp.partida_id
) pag ON pag.partida_id = pi.partida_id;

-- 3. Ampliación de registrar_pago_factura con parámetro opcional p_asignaciones jsonb
-- Se elimina la firma previa de 9 argumentos para evitar ambigüedades en resolución de sobrecargas;
-- la función de 10 argumentos con DEFAULT NULL la reemplaza de forma 100% retrocompatible.
DROP FUNCTION IF EXISTS registrar_pago_factura(UUID, UUID, DATE, NUMERIC, NUMERIC, TEXT, TEXT, TEXT, TEXT);

CREATE OR REPLACE FUNCTION registrar_pago_factura(
    p_org UUID,
    p_factura_id UUID,
    p_fecha DATE,
    p_monto NUMERIC,
    p_tipo_cambio NUMERIC,
    p_metodo TEXT,
    p_referencia TEXT,
    p_complemento TEXT,
    p_notas TEXT,
    p_asignaciones JSONB DEFAULT NULL
) RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
    v_factura RECORD;
    v_pagado NUMERIC(14,2);
    v_saldo NUMERIC(14,2);
    v_pago_id UUID;
    v_saldo_restante NUMERIC(14,2);
    v_num_partidas INTEGER;
    v_asig RECORD;
    v_suma_asig NUMERIC(14,2) := 0;
    v_partida_saldo RECORD;
    v_monto_restante NUMERIC(14,2);
    v_monto_a_asignar NUMERIC(14,2);
BEGIN
    -- Redondear monto del pago a 2 decimales
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

    -- Contar partidas pagables (concepto y otro_cargo) de la factura
    SELECT COUNT(*) INTO v_num_partidas
    FROM factura_proveedor_partidas
    WHERE factura_id = p_factura_id AND organizacion_id = p_org
      AND tipo IN ('concepto', 'otro_cargo');

    -- Validaciones previas si se proporcionaron asignaciones explícitas
    IF p_asignaciones IS NOT NULL AND jsonb_typeof(p_asignaciones) = 'array' AND jsonb_array_length(p_asignaciones) > 0 THEN
        IF v_num_partidas = 0 THEN
            RETURN jsonb_build_object('exito', false, 'error', 'factura_sin_partidas', 'mensaje', 'La factura no tiene partidas para asignar pagos específicos');
        END IF;

        -- Sumar y validar montos de las asignaciones
        FOR v_asig IN 
            SELECT 
                (elem->>'partida_id')::UUID AS partida_id,
                ROUND(COALESCE((elem->>'monto')::NUMERIC, 0), 2) AS monto
            FROM jsonb_array_elements(p_asignaciones) AS elem
        LOOP
            IF v_asig.monto <= 0 THEN
                RETURN jsonb_build_object('exito', false, 'error', 'monto_partida_invalido', 'mensaje', 'El monto asignado a cada partida debe ser mayor a 0');
            END IF;

            v_suma_asig := v_suma_asig + v_asig.monto;

            -- Obtener y validar partida contra saldo actual
            SELECT * INTO v_partida_saldo
            FROM v_factura_partidas_saldo
            WHERE partida_id = v_asig.partida_id 
              AND factura_id = p_factura_id 
              AND organizacion_id = p_org;

            IF v_partida_saldo.partida_id IS NULL THEN
                RETURN jsonb_build_object('exito', false, 'error', 'partida_no_encontrada', 'mensaje', 'Una o más partidas no pertenecen a esta factura');
            END IF;

            IF v_asig.monto > v_partida_saldo.saldo THEN
                RETURN jsonb_build_object(
                    'exito', false,
                    'error', 'excede_saldo_partida',
                    'mensaje', format('El monto de %s excede el saldo pendiente (%s) de la partida "%s"', v_asig.monto, v_partida_saldo.saldo, v_partida_saldo.descripcion),
                    'partida_id', v_asig.partida_id,
                    'saldo_partida', v_partida_saldo.saldo
                );
            END IF;
        END LOOP;

        IF abs(v_suma_asig - p_monto) > 0.001 THEN
            RETURN jsonb_build_object(
                'exito', false,
                'error', 'suma_asignaciones_no_coincide',
                'mensaje', format('La suma de las asignaciones (%s) no coincide con el monto total del pago (%s)', v_suma_asig, p_monto)
            );
        END IF;
    END IF;

    -- Generar ID y registrar pago
    v_pago_id := gen_random_uuid();

    INSERT INTO pagos_factura (
        id, organizacion_id, factura_id, fecha_pago, monto,
        tipo_cambio, metodo_pago, referencia, complemento_pago, notas
    ) VALUES (
        v_pago_id, p_org, p_factura_id, p_fecha, p_monto,
        p_tipo_cambio, coalesce(nullif(trim(p_metodo), ''), 'Transferencia'),
        nullif(trim(p_referencia), ''), nullif(trim(p_complemento), ''), nullif(trim(p_notas), '')
    );

    -- Si la factura tiene partidas, aplicar la repartición correspondiente
    IF v_num_partidas > 0 THEN
        IF p_asignaciones IS NOT NULL AND jsonb_typeof(p_asignaciones) = 'array' AND jsonb_array_length(p_asignaciones) > 0 THEN
            -- Modo explícito: insertar las asignaciones validadas
            FOR v_asig IN 
                SELECT 
                    (elem->>'partida_id')::UUID AS partida_id,
                    ROUND(COALESCE((elem->>'monto')::NUMERIC, 0), 2) AS monto
                FROM jsonb_array_elements(p_asignaciones) AS elem
            LOOP
                INSERT INTO pagos_factura_partidas (
                    organizacion_id, pago_id, partida_id, monto
                ) VALUES (
                    p_org, v_pago_id, v_asig.partida_id, v_asig.monto
                );
            END LOOP;
        ELSE
            -- Modo automático / abono libre: repartir en orden de partida
            v_monto_restante := p_monto;

            FOR v_partida_saldo IN 
                SELECT partida_id, saldo
                FROM v_factura_partidas_saldo
                WHERE factura_id = p_factura_id
                  AND organizacion_id = p_org
                  AND tipo IN ('concepto', 'otro_cargo')
                  AND saldo > 0
                ORDER BY orden ASC, partida_id ASC
            LOOP
                v_monto_a_asignar := LEAST(v_monto_restante, v_partida_saldo.saldo);
                IF v_monto_a_asignar > 0 THEN
                    INSERT INTO pagos_factura_partidas (
                        organizacion_id, pago_id, partida_id, monto
                    ) VALUES (
                        p_org, v_pago_id, v_partida_saldo.partida_id, v_monto_a_asignar
                    );
                    v_monto_restante := v_monto_restante - v_monto_a_asignar;
                END IF;

                IF v_monto_restante <= 0 THEN
                    EXIT;
                END IF;
            END LOOP;

            -- Salvaguarda de centavos: si tras el recorrido queda remanente, asociarlo a la última partida pagable
            IF v_monto_restante > 0 THEN
                SELECT partida_id INTO v_partida_saldo
                FROM v_factura_partidas_saldo
                WHERE factura_id = p_factura_id AND organizacion_id = p_org AND tipo IN ('concepto', 'otro_cargo')
                ORDER BY orden DESC, partida_id DESC
                LIMIT 1;

                IF v_partida_saldo.partida_id IS NOT NULL THEN
                    INSERT INTO pagos_factura_partidas (
                        organizacion_id, pago_id, partida_id, monto
                    ) VALUES (
                        p_org, v_pago_id, v_partida_saldo.partida_id, v_monto_restante
                    );
                END IF;
            END IF;
        END IF;
    END IF;

    v_saldo_restante := (v_saldo - p_monto)::NUMERIC(14,2);

    RETURN jsonb_build_object(
        'exito', true,
        'pago_id', v_pago_id,
        'saldo_restante', v_saldo_restante
    );
END;
$$;

REVOKE ALL ON FUNCTION registrar_pago_factura(UUID, UUID, DATE, NUMERIC, NUMERIC, TEXT, TEXT, TEXT, TEXT, JSONB) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION registrar_pago_factura(UUID, UUID, DATE, NUMERIC, NUMERIC, TEXT, TEXT, TEXT, TEXT, JSONB) TO authenticated;

GRANT EXECUTE ON FUNCTION registrar_pago_factura(UUID, UUID, DATE, NUMERIC, NUMERIC, TEXT, TEXT, TEXT, TEXT, JSONB) TO service_role;

ALTER FUNCTION registrar_pago_factura(UUID, UUID, DATE, NUMERIC, NUMERIC, TEXT, TEXT, TEXT, TEXT, JSONB) SET search_path = public;

-- 5. Candado en guardar_factura_con_partidas para impedir reemplazo de partidas con pagos activos asignados
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
    v_pagos_asignados_activos INTEGER := 0;
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

        IF v_factura.estado = 'cancelada' THEN
            RAISE EXCEPTION 'factura_cancelada: No se puede modificar una factura que ya ha sido cancelada'
                USING ERRCODE = '23514';
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

            -- Verificar si existen asignaciones a partidas activas
            SELECT COUNT(*) INTO v_pagos_asignados_activos
            FROM pagos_factura_partidas pfp
            JOIN pagos_factura pf ON pf.id = pfp.pago_id
            WHERE pf.factura_id = v_factura_id
              AND pf.organizacion_id = p_organizacion_id
              AND pf.anulado = false;

            IF v_pagos_asignados_activos > 0 AND p_partidas IS NOT NULL THEN
                RAISE EXCEPTION 'pagos_asignados_activos: Anula los pagos asignados antes de modificar las partidas'
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

        IF abs(v_importe_redondeado - v_suma_partidas) > 0.01 THEN
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

        -- Reemplazar partidas de esta factura y organizacion (permitido solo si no hay pagos asignados activos)
        IF v_hay_partidas THEN
            DELETE FROM factura_proveedor_partidas 
            WHERE factura_id = v_factura_id AND organizacion_id = p_organizacion_id;
        END IF;
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

-- 6. Repartición idempotente de pagos históricos en facturas que ya tienen partidas
DO $$
DECLARE
    r_factura RECORD;
    r_pago RECORD;
    r_partida RECORD;
    v_monto_restante NUMERIC(14,2);
    v_a_asignar NUMERIC(14,2);
BEGIN
    -- Recorrer facturas con partidas y con pagos activos no asignados
    FOR r_factura IN
        SELECT DISTINCT f.id, f.organizacion_id
        FROM facturas_proveedor f
        JOIN factura_proveedor_partidas fpp ON fpp.factura_id = f.id
        JOIN pagos_factura pf ON pf.factura_id = f.id AND pf.anulado = false
        WHERE NOT EXISTS (
            SELECT 1 FROM pagos_factura_partidas pfp WHERE pfp.pago_id = pf.id
        )
    LOOP
        -- Procesar cada pago cronológicamente
        FOR r_pago IN
            SELECT id, monto
            FROM pagos_factura
            WHERE factura_id = r_factura.id 
              AND anulado = false
              AND NOT EXISTS (
                  SELECT 1 FROM pagos_factura_partidas pfp WHERE pfp.pago_id = pagos_factura.id
              )
            ORDER BY fecha_pago ASC, created_at ASC, id ASC
        LOOP
            v_monto_restante := r_pago.monto;

            FOR r_partida IN
                SELECT partida_id, saldo
                FROM v_factura_partidas_saldo
                WHERE factura_id = r_factura.id
                  AND organizacion_id = r_factura.organizacion_id
                  AND tipo IN ('concepto', 'otro_cargo')
                  AND saldo > 0
                ORDER BY orden ASC, partida_id ASC
            LOOP
                v_a_asignar := LEAST(v_monto_restante, r_partida.saldo);
                IF v_a_asignar > 0 THEN
                    INSERT INTO pagos_factura_partidas (
                        organizacion_id, pago_id, partida_id, monto
                    ) VALUES (
                        r_factura.organizacion_id, r_pago.id, r_partida.partida_id, v_a_asignar
                    );
                    v_monto_restante := v_monto_restante - v_a_asignar;
                END IF;

                IF v_monto_restante <= 0 THEN
                    EXIT;
                END IF;
            END LOOP;

            -- Si queda residuo, asignar a la última partida pagable
            IF v_monto_restante > 0 THEN
                SELECT partida_id INTO r_partida
                FROM v_factura_partidas_saldo
                WHERE factura_id = r_factura.id
                  AND organizacion_id = r_factura.organizacion_id
                  AND tipo IN ('concepto', 'otro_cargo')
                ORDER BY orden DESC, partida_id DESC
                LIMIT 1;

                IF r_partida.partida_id IS NOT NULL THEN
                    INSERT INTO pagos_factura_partidas (
                        organizacion_id, pago_id, partida_id, monto
                    ) VALUES (
                        r_factura.organizacion_id, r_pago.id, r_partida.partida_id, v_monto_restante
                    );
                END IF;
            END IF;
        END LOOP;
    END LOOP;
END $$;

COMMIT;
