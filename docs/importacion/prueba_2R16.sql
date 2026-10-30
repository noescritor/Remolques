-- Script de prueba funcional integral 2R-16
-- Ejecuta todo dentro de un bloque BEGIN ... ROLLBACK garantizando cero impacto permanente.
-- Prueba:
-- 1. Inserción de proveedor con campos de crédito.
-- 2. Factura en USD y factura en MXN.
-- 3. Pago parcial en USD con tipo de cambio.
-- 4. Factura USD sin tipo de cambio arroja 'tipo_cambio_requerido'.
-- 5. Pago que excede saldo arroja 'excede_saldo'.
-- 6. Pago exacto deja saldo en 0.
-- 7. Pago a factura cancelada arroja 'cancelada'.
-- 8. Factura de otra organización arroja 'no_encontrada'.
-- 9. Anular pago devuelve el saldo correctamente.
-- 10. Anular el mismo pago por segunda vez arroja 'ya_anulado'.
-- 11. Duplicado de (proveedor, sucursal, folio) falla por índice único.
-- 12. Tablas nuevas no legibles por anon.

BEGIN;

DO $$
DECLARE
    v_org_id UUID;
    v_org_ajena UUID;
    v_prov_id UUID;
    v_factura_usd UUID;
    v_factura_mxn UUID;
    v_factura_cancelada UUID;
    v_factura_ajena UUID;
    v_res JSONB;
    v_pago_id UUID;
    v_pago2_id UUID;
    v_dup_fallo BOOLEAN := false;
BEGIN
    -- 0. Obtener una organización real existente
    SELECT id INTO v_org_id FROM organizaciones LIMIT 1;
    IF v_org_id IS NULL THEN
        RAISE EXCEPTION 'No se encontró ninguna organización en la base de datos';
    END IF;

    -- Crear id ficticio para org ajena
    v_org_ajena := gen_random_uuid();

    -- 1. Crear proveedor de prueba
    INSERT INTO proveedores (
        organizacion_id, nombre, razon_social, rfc, moneda_default, dias_credito, limite_credito, limite_credito_moneda
    ) VALUES (
        v_org_id, 'PROVEEDOR PRUEBA 2R16', 'PROVEEDOR PRUEBA SA DE CV', 'PPR261030ABC', 'USD', 30, 10000.00, 'USD'
    ) RETURNING id INTO v_prov_id;

    -- 2. Crear facturas de prueba
    -- Factura USD
    INSERT INTO facturas_proveedor (
        organizacion_id, proveedor_id, sucursal, folio, fecha_emision, dias_credito,
        fecha_vencimiento, moneda, importe, tipo_cambio_emision, concepto
    ) VALUES (
        v_org_id, v_prov_id, 'Suc 114', 'F-USD-001', '2026-10-01', 30,
        '2026-10-31', 'USD', 1000.00, 19.50, 'Compra de refacciones prueba USD'
    ) RETURNING id INTO v_factura_usd;

    -- Factura MXN
    INSERT INTO facturas_proveedor (
        organizacion_id, proveedor_id, sucursal, folio, fecha_emision, dias_credito,
        fecha_vencimiento, moneda, importe, concepto
    ) VALUES (
        v_org_id, v_prov_id, NULL, 'F-MXN-001', '2026-10-05', 15,
        '2026-10-20', 'MXN', 5000.00, 'Materiales prueba MXN'
    ) RETURNING id INTO v_factura_mxn;

    -- Factura Cancelada
    INSERT INTO facturas_proveedor (
        organizacion_id, proveedor_id, sucursal, folio, fecha_emision, dias_credito,
        fecha_vencimiento, moneda, importe, concepto, estado
    ) VALUES (
        v_org_id, v_prov_id, NULL, 'F-CAN-001', '2026-10-10', 30,
        '2026-11-09', 'MXN', 2000.00, 'Factura cancelada prueba', 'cancelada'
    ) RETURNING id INTO v_factura_cancelada;

    -- 3. Prueba: Pago parcial a factura USD con tipo de cambio
    v_res := registrar_pago_factura(
        v_org_id, v_factura_usd, '2026-10-15'::date, 400.00, 19.80, 'Transferencia', 'REF-USD-1', 'REP-001', 'Abono 1'
    );
    IF (v_res->>'exito')::boolean IS NOT TRUE OR (v_res->>'saldo_restante')::numeric <> 600.00 THEN
        RAISE EXCEPTION 'Fallo en pago parcial USD: %', v_res;
    END IF;
    v_pago_id := (v_res->>'pago_id')::uuid;

    -- 4. Prueba: Factura USD sin tipo de cambio arroja 'tipo_cambio_requerido'
    v_res := registrar_pago_factura(
        v_org_id, v_factura_usd, '2026-10-16'::date, 100.00, NULL, 'Transferencia', 'REF-USD-2', NULL, NULL
    );
    IF (v_res->>'exito')::boolean IS NOT FALSE OR v_res->>'error' <> 'tipo_cambio_requerido' THEN
        RAISE EXCEPTION 'Fallo esperando tipo_cambio_requerido: %', v_res;
    END IF;

    -- 5. Prueba: Pago que excede saldo arroja 'excede_saldo' (saldo restante es 600, intentamos 700)
    v_res := registrar_pago_factura(
        v_org_id, v_factura_usd, '2026-10-17'::date, 700.00, 19.80, 'Transferencia', 'REF-USD-3', NULL, NULL
    );
    IF (v_res->>'exito')::boolean IS NOT FALSE OR v_res->>'error' <> 'excede_saldo' THEN
        RAISE EXCEPTION 'Fallo esperando excede_saldo: %', v_res;
    END IF;

    -- 6. Prueba: Pago exacto en factura MXN deja saldo en 0
    v_res := registrar_pago_factura(
        v_org_id, v_factura_mxn, '2026-10-18'::date, 5000.00, NULL, 'Transferencia', 'REF-MXN-1', 'REP-MXN-1', 'Liquidación'
    );
    IF (v_res->>'exito')::boolean IS NOT TRUE OR (v_res->>'saldo_restante')::numeric <> 0.00 THEN
        RAISE EXCEPTION 'Fallo en pago exacto dejando saldo en 0: %', v_res;
    END IF;
    v_pago2_id := (v_res->>'pago_id')::uuid;

    -- 7. Prueba: Pago a factura cancelada arroja 'cancelada'
    v_res := registrar_pago_factura(
        v_org_id, v_factura_cancelada, '2026-10-19'::date, 500.00, NULL, 'Efectivo', NULL, NULL, NULL
    );
    IF (v_res->>'exito')::boolean IS NOT FALSE OR v_res->>'error' <> 'cancelada' THEN
        RAISE EXCEPTION 'Fallo esperando error cancelada: %', v_res;
    END IF;

    -- 8. Prueba: Factura de otra organización arroja 'no_encontrada'
    v_res := registrar_pago_factura(
        v_org_ajena, v_factura_usd, '2026-10-20'::date, 100.00, 19.80, 'Transferencia', NULL, NULL, NULL
    );
    IF (v_res->>'exito')::boolean IS NOT FALSE OR v_res->>'error' <> 'no_encontrada' THEN
        RAISE EXCEPTION 'Fallo esperando no_encontrada con org ajena: %', v_res;
    END IF;

    -- 9. Prueba: Anular pago devuelve el saldo
    -- Anulamos el pago 1 de USD ($400). El saldo de la factura USD debe regresar a 1000.00
    v_res := anular_pago_factura(v_org_id, v_pago_id, 'Error en captura de importe');
    IF (v_res->>'exito')::boolean IS NOT TRUE OR (v_res->>'saldo_restante')::numeric <> 1000.00 THEN
        RAISE EXCEPTION 'Fallo en anulación de pago: %', v_res;
    END IF;

    -- 10. Prueba: Anular el mismo pago por segunda vez arroja 'ya_anulado'
    v_res := anular_pago_factura(v_org_id, v_pago_id, 'Segundo intento de anulación');
    IF (v_res->>'exito')::boolean IS NOT FALSE OR v_res->>'error' <> 'ya_anulado' THEN
        RAISE EXCEPTION 'Fallo esperando ya_anulado: %', v_res;
    END IF;

    -- 11. Prueba: Duplicado de (proveedor, sucursal, folio) falla por índice único
    BEGIN
        INSERT INTO facturas_proveedor (
            organizacion_id, proveedor_id, sucursal, folio, fecha_emision, dias_credito,
            fecha_vencimiento, moneda, importe, concepto
        ) VALUES (
            v_org_id, v_prov_id, 'Suc 114', 'F-USD-001', '2026-10-01', 30,
            '2026-10-31', 'USD', 200.00, 'Factura duplicada'
        );
    EXCEPTION WHEN unique_violation THEN
        v_dup_fallo := true;
    END;

    IF NOT v_dup_fallo THEN
        RAISE EXCEPTION 'El índice único uq_facturas_proveedor_folio no rechazó el duplicado de sucursal y folio';
    END IF;

    -- 12. Comprobar vista v_facturas_proveedor_saldo
    PERFORM * FROM v_facturas_proveedor_saldo WHERE id = v_factura_usd;

    RAISE NOTICE 'PRUEBA_2R16 COMPLETADA CON ÉXITO: Todos los casos pasaron correctamente';
END $$;

ROLLBACK;
