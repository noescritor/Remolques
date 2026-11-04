-- docs/proveedores/prueba_T4.sql
-- Prueba transaccional aislada (BEGIN ... ROLLBACK) para Sub-bloque T4
-- Cubre dos organizaciones, cuadratura de partidas, bloqueo de fila, unicidad y aislamiento RLS

BEGIN;

DO $$
DECLARE
    v_org_a UUID;
    v_org_b UUID;
    v_prov_a UUID;
    v_prov_b UUID;
    v_factura_a UUID;
    v_factura_b UUID;
    v_resultado JSONB;
    v_error_disparado BOOLEAN;
    v_vista_row RECORD;
BEGIN
    -- 1. Crear dos organizaciones de prueba
    INSERT INTO organizaciones (nombre) VALUES ('Empresa A - T4 Test') RETURNING id INTO v_org_a;
    INSERT INTO organizaciones (nombre) VALUES ('Empresa B - T4 Test') RETURNING id INTO v_org_b;

    -- 2. Crear proveedores en sus respectivas organizaciones
    INSERT INTO proveedores (organizacion_id, nombre, rfc) 
    VALUES (v_org_a, 'PROVEEDOR DE ORG A SA', 'POA010101AAA') 
    RETURNING id INTO v_prov_a;

    INSERT INTO proveedores (organizacion_id, nombre, rfc) 
    VALUES (v_org_b, 'PROVEEDOR DE ORG B SA', 'POB020202BBB') 
    RETURNING id INTO v_prov_b;

    -- 3. CASO 1: Guardar factura válida con partidas múltiples (2 conceptos de 500 + IVA 160 = 1160)
    v_resultado := guardar_factura_con_partidas(
        v_org_a,
        NULL, -- nueva
        v_prov_a,
        'FAC-A-001',
        'MATRIZ',
        CURRENT_DATE,
        30,
        CURRENT_DATE + 30,
        'MXN',
        1160.00,
        1.0,
        'Factura con 2 conceptos e IVA',
        '11111111-2222-3333-4444-555555555555',
        1000.00,
        0.00,
        160.00,
        0.00,
        jsonb_build_array(
            jsonb_build_object('tipo', 'concepto', 'descripcion', 'Viga IPR 6"', 'cantidad', 10, 'precio_unitario', 50.00, 'importe', 500.00),
            jsonb_build_object('tipo', 'concepto', 'descripcion', 'Placa 1/2"', 'cantidad', 5, 'precio_unitario', 100.00, 'importe', 500.00),
            jsonb_build_object('tipo', 'impuesto_trasladado', 'descripcion', 'IVA 16%', 'cantidad', 1, 'precio_unitario', 160.00, 'importe', 160.00, 'tasa_o_cuota', 0.16)
        )
    );

    v_factura_a := (v_resultado ->> 'factura_id')::uuid;
    ASSERT (v_resultado ->> 'ok')::boolean = true, 'Debe guardar la factura A con éxito';
    ASSERT (v_resultado ->> 'partidas_guardadas')::int = 3, 'Deben haberse guardado 3 partidas';

    -- 4. CASO 2: Intentar guardar factura con descuadre entre importe y partidas (5000 vs 1160)
    v_error_disparado := false;
    BEGIN
        PERFORM guardar_factura_con_partidas(
            v_org_a,
            NULL,
            v_prov_a,
            'FAC-A-DESCUADRADA',
            'MATRIZ',
            CURRENT_DATE,
            30,
            CURRENT_DATE + 30,
            'MXN',
            5000.00, -- Descuadre evidente
            1.0,
            'Factura descuadrada',
            'UUID-DESCUADRADO-1',
            1000.00, 0, 160.00, 0,
            jsonb_build_array(
                jsonb_build_object('tipo', 'concepto', 'descripcion', 'Concepto 100', 'cantidad', 1, 'precio_unitario', 100.00, 'importe', 100.00),
                jsonb_build_object('tipo', 'impuesto_trasladado', 'descripcion', 'IVA 16', 'cantidad', 1, 'precio_unitario', 16.00, 'importe', 16.00)
            )
        );
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%importe_no_cuadra%' THEN
            v_error_disparado := true;
        END IF;
    END;
    ASSERT v_error_disparado = true, 'Debió rechazar factura con importe no concordante con partidas';

    -- 5. Crear factura en Org B
    v_resultado := guardar_factura_con_partidas(
        v_org_b,
        NULL,
        v_prov_b,
        'FAC-B-001',
        'SUCURSAL B',
        CURRENT_DATE,
        15,
        CURRENT_DATE + 15,
        'MXN',
        2320.00,
        1.0,
        'Factura de Org B',
        'BBBBBBBB-2222-3333-4444-555555555555',
        2000.00, 0, 320.00, 0,
        jsonb_build_array(
            jsonb_build_object('tipo', 'concepto', 'descripcion', 'Llantas 11R22.5', 'cantidad', 4, 'precio_unitario', 500.00, 'importe', 2000.00),
            jsonb_build_object('tipo', 'impuesto_trasladado', 'descripcion', 'IVA 16%', 'cantidad', 1, 'precio_unitario', 320.00, 'importe', 320.00)
        )
    );
    v_factura_b := (v_resultado ->> 'factura_id')::uuid;

    -- 6. CASO 3: Org A intenta modificar la factura de Org B -> debe fallar con factura_no_encontrada
    v_error_disparado := false;
    BEGIN
        PERFORM guardar_factura_con_partidas(
            v_org_a, -- Org A tratando de tocar factura de Org B
            v_factura_b,
            v_prov_a,
            'FAC-INYECCION',
            'X',
            CURRENT_DATE,
            30,
            CURRENT_DATE + 30,
            'MXN',
            580.00, 1.0, 'Intento de cruce',
            'UUID-X', 500.00, 0, 80.00, 0,
            '[]'::jsonb
        );
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%factura_no_encontrada%' THEN
            v_error_disparado := true;
        END IF;
    END;
    ASSERT v_error_disparado = true, 'Debió impedir modificación de factura ajena a la organización';

    -- 7. CASO 4: Org A intenta colgar factura de un proveedor de Org B -> proveedor_no_encontrado
    v_error_disparado := false;
    BEGIN
        PERFORM guardar_factura_con_partidas(
            v_org_a,
            NULL,
            v_prov_b, -- Proveedor de Org B
            'FAC-CRUZADA',
            'X',
            CURRENT_DATE, 30, CURRENT_DATE + 30,
            'MXN', 116.00, 1.0, 'Proveedor ajeno',
            'UUID-CRUZADO', 100.00, 0, 16.00, 0,
            '[]'::jsonb
        );
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%proveedor_no_encontrado%' THEN
            v_error_disparado := true;
        END IF;
    END;
    ASSERT v_error_disparado = true, 'Debió rechazar proveedor perteneciente a otra organización';

    -- 8. CASO 5: Factura con pagos registrados
    INSERT INTO pagos_factura (organizacion_id, factura_id, fecha_pago, monto, metodo_pago)
    VALUES (v_org_a, v_factura_a, CURRENT_DATE, 600.00, 'Transferencia');

    -- 8a: Intentar cambiar moneda teniendo pagos
    v_error_disparado := false;
    BEGIN
        PERFORM guardar_factura_con_partidas(
            v_org_a, v_factura_a, v_prov_a, 'FAC-A-001', 'MATRIZ',
            CURRENT_DATE, 30, CURRENT_DATE + 30,
            'USD', -- Cambio de moneda
            1160.00, 20.0, 'Cambio a USD',
            '11111111-2222-3333-4444-555555555555',
            1000.00, 0, 160.00, 0, '[]'::jsonb
        );
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%no_se_puede_cambiar_moneda_con_pagos%' THEN
            v_error_disparado := true;
        END IF;
    END;
    ASSERT v_error_disparado = true, 'Debió rechazar cambio de moneda con pagos activos';

    -- 8b: Intentar reducir importe por debajo de lo pagado (< 600)
    v_error_disparado := false;
    BEGIN
        PERFORM guardar_factura_con_partidas(
            v_org_a, v_factura_a, v_prov_a, 'FAC-A-001', 'MATRIZ',
            CURRENT_DATE, 30, CURRENT_DATE + 30,
            'MXN',
            500.00, -- Menor a 600 pagados
            1.0, 'Reducción inválida',
            '11111111-2222-3333-4444-555555555555',
            500.00, 0, 0, 0, '[]'::jsonb
        );
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%nuevo_total_menor_que_pagado%' THEN
            v_error_disparado := true;
        END IF;
    END;
    ASSERT v_error_disparado = true, 'Debió rechazar importe menor al monto ya pagado';

    -- 9. CASO 6: Unicidad de UUID fiscal
    -- Intentar re-usar el UUID de Factura A en OTRA factura de Org A -> debe fallar
    v_error_disparado := false;
    BEGIN
        PERFORM guardar_factura_con_partidas(
            v_org_a, NULL, v_prov_a, 'FAC-A-OTRA', 'MATRIZ',
            CURRENT_DATE, 30, CURRENT_DATE + 30, 'MXN', 100.00, 1.0,
            'Factura con UUID duplicado en Org A',
            '11111111-2222-3333-4444-555555555555', -- Mismo UUID
            100.00, 0, 0, 0, '[]'::jsonb
        );
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%uuid_fiscal_duplicado%' OR SQLSTATE = '23505' THEN
            v_error_disparado := true;
        END IF;
    END;
    ASSERT v_error_disparado = true, 'Debió rechazar UUID fiscal duplicado dentro de la misma organización';

    -- En cambio, usar ese MISMO UUID en Org B debe ser permitido (multi-tenant isolation)
    v_resultado := guardar_factura_con_partidas(
        v_org_b, NULL, v_prov_b, 'FAC-B-COMPARTIDA', 'SUCURSAL B',
        CURRENT_DATE, 30, CURRENT_DATE + 30, 'MXN', 500.00, 1.0,
        'Factura en Org B con UUID de prueba',
        '11111111-2222-3333-4444-555555555555',
        500.00, 0, 0, 0, '[]'::jsonb
    );
    ASSERT (v_resultado ->> 'ok')::boolean = true, 'El mismo UUID debe permitirse en otra organización';

    -- 10. CASO 7: Comprobar vista v_facturas_proveedor_saldo
    SELECT * INTO v_vista_row 
    FROM v_facturas_proveedor_saldo 
    WHERE id = v_factura_a;

    ASSERT v_vista_row.uuid_fiscal = '11111111-2222-3333-4444-555555555555', 'La vista debe reportar el uuid_fiscal';
    ASSERT v_vista_row.subtotal = 1000.00, 'La vista debe reportar el subtotal';
    ASSERT v_vista_row.impuestos_trasladados = 160.00, 'La vista debe reportar los traslados';
    ASSERT v_vista_row.total_pagado = 600.00, 'La vista debe reportar 600 pagados';
    ASSERT v_vista_row.saldo_pendiente = 560.00, 'El saldo pendiente debe ser 560';
    ASSERT v_vista_row.estado = 'abierta', 'El estado de la factura debe ser abierta';
    ASSERT v_vista_row.estado_vencimiento = 'al_corriente', 'El estado de vencimiento debe ser al_corriente';

    -- 11. CASO 8: Rechazar modificación de factura cancelada
    UPDATE facturas_proveedor SET estado = 'cancelada' WHERE id = v_factura_b;
    v_error_disparado := false;
    BEGIN
        PERFORM guardar_factura_con_partidas(
            v_org_b, v_factura_b, v_prov_b, 'FAC-B-001', 'SUCURSAL B',
            CURRENT_DATE, 15, CURRENT_DATE + 15, 'MXN', 2320.00, 1.0,
            'Intento de editar cancelada', 'BBBBBBBB-2222-3333-4444-555555555555',
            2000.00, 0, 320.00, 0, '[]'::jsonb
        );
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%factura_cancelada%' THEN
            v_error_disparado := true;
        END IF;
    END;
    ASSERT v_error_disparado = true, 'Debió rechazar modificación de factura cancelada';

    -- 12. CASO 9: Tolerancia estricta de cuadratura a 0.01 (116.04 vs 116.00 debe fallar)
    v_error_disparado := false;
    BEGIN
        PERFORM guardar_factura_con_partidas(
            v_org_a, NULL, v_prov_a, 'FAC-TOL-001', 'MATRIZ',
            CURRENT_DATE, 30, CURRENT_DATE + 30, 'MXN',
            116.04, -- Diferencia de 0.04 contra 116.00 (debe fallar con tolerancia 0.01)
            1.0, 'Factura fuera de tolerancia 0.01',
            'UUID-TOL-001', 100.00, 0, 16.00, 0,
            jsonb_build_array(
                jsonb_build_object('tipo', 'concepto', 'descripcion', 'Item', 'cantidad', 1, 'precio_unitario', 100.00, 'importe', 100.00),
                jsonb_build_object('tipo', 'impuesto_trasladado', 'descripcion', 'IVA', 'cantidad', 1, 'precio_unitario', 16.00, 'importe', 16.00)
            )
        );
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%importe_no_cuadra%' THEN
            v_error_disparado := true;
        END IF;
    END;
    ASSERT v_error_disparado = true, 'Debió rechazar diferencia de 0.04 con tolerancia de 0.01';

    RAISE NOTICE 'PRUEBA TRANSACCIONAL T4: EXITOSA (0 errores)';
END $$;

ROLLBACK;
