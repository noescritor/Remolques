-- docs/proveedores/prueba_T4.sql
-- Prueba transaccional aislada (BEGIN ... ROLLBACK) para Sub-bloque T4

BEGIN;

DO $$
DECLARE
    v_org_id UUID;
    v_prov_id UUID;
    v_factura_id UUID;
    v_resultado JSONB;
    v_error_disparado BOOLEAN := false;
BEGIN
    -- 1. Obtener organización y proveedor de prueba
    SELECT id INTO v_org_id FROM organizaciones LIMIT 1;
    IF v_org_id IS NULL THEN
        INSERT INTO organizaciones (nombre) VALUES ('Org Prueba T4') RETURNING id INTO v_org_id;
    END IF;

    SELECT id INTO v_prov_id FROM proveedores WHERE organizacion_id = v_org_id LIMIT 1;
    IF v_prov_id IS NULL THEN
        INSERT INTO proveedores (organizacion_id, nombre, rfc) 
        VALUES (v_org_id, 'PROVEEDOR PRUEBA T4 SA DE CV', 'PPT010101XYZ') 
        RETURNING id INTO v_prov_id;
    END IF;

    -- 2. Guardar factura con partidas múltiples (2 conceptos + IVA trasladado 16%)
    v_resultado := guardar_factura_con_partidas(
        v_org_id,
        NULL, -- nueva
        v_prov_id,
        'TEST-T4-001',
        'MATRIZ',
        CURRENT_DATE,
        30,
        CURRENT_DATE + 30,
        'MXN',
        1160.00,
        1.0,
        'Factura con 2 conceptos e IVA',
        'A1B2C3D4-E5F6-7890-ABCD-123456789012',
        1000.00,
        0.00,
        160.00,
        0.00,
        jsonb_build_array(
            jsonb_build_object('tipo', 'concepto', 'descripcion', 'Tornillos alta resistencia', 'cantidad', 100, 'precio_unitario', 5.00, 'importe', 500.00),
            jsonb_build_object('tipo', 'concepto', 'descripcion', 'Placa de acero 1/4', 'cantidad', 5, 'precio_unitario', 100.00, 'importe', 500.00),
            jsonb_build_object('tipo', 'impuesto_trasladado', 'descripcion', 'IVA 16%', 'cantidad', 1, 'precio_unitario', 160.00, 'importe', 160.00, 'tasa_o_cuota', 0.16)
        )
    );

    v_factura_id := (v_resultado ->> 'factura_id')::uuid;
    ASSERT (v_resultado ->> 'ok')::boolean = true, 'Debe guardar la factura con éxito';
    ASSERT (v_resultado ->> 'partidas_guardadas')::int = 3, 'Deben haberse guardado 3 partidas';

    -- 3. Registrar un pago parcial de 600 pesos
    INSERT INTO pagos_factura (organizacion_id, factura_id, fecha_pago, monto, metodo_pago)
    VALUES (v_org_id, v_factura_id, CURRENT_DATE, 600.00, 'Transferencia');

    -- 4. Intentar reducir el total de la factura a 500 (menor a los 600 ya pagados) -> debe fallar
    BEGIN
        PERFORM guardar_factura_con_partidas(
            v_org_id,
            v_factura_id,
            v_prov_id,
            'TEST-T4-001',
            'MATRIZ',
            CURRENT_DATE,
            30,
            CURRENT_DATE + 30,
            'MXN',
            500.00, -- Menor que 600 pagados
            1.0,
            'Reducción indebida',
            'A1B2C3D4-E5F6-7890-ABCD-123456789012',
            500.00, 0, 0, 0,
            '[]'::jsonb
        );
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%nuevo_total_menor_que_pagado%' THEN
            v_error_disparado := true;
        ELSE
            RAISE EXCEPTION 'Error inesperado: %', SQLERRM;
        END IF;
    END;

    ASSERT v_error_disparado = true, 'Debió rechazar reducción de importe por debajo de lo pagado';

    -- 5. Probar inserción en facturas_proveedor_cfdi y restricción de unicidad
    INSERT INTO facturas_proveedor_cfdi (
        organizacion_id, factura_id, uuid_fiscal, version, rfc_emisor, nombre_emisor,
        rfc_receptor, serie, folio, fecha_emision, moneda, subtotal, total, xml_contenido
    ) VALUES (
        v_org_id, v_factura_id, 'UUID-UNICO-PRUEBA-123', '4.0', 'PPT010101XYZ',
        'PROVEEDOR PRUEBA', 'REC010101ABC', 'A', '100', now(), 'MXN', 1000.00, 1160.00, '<cfdi:Comprobante />'
    );

    v_error_disparado := false;
    BEGIN
        INSERT INTO facturas_proveedor_cfdi (
            organizacion_id, factura_id, uuid_fiscal, version, rfc_emisor, nombre_emisor,
            rfc_receptor, serie, folio, fecha_emision, moneda, subtotal, total, xml_contenido
        ) VALUES (
            v_org_id, v_factura_id, 'UUID-UNICO-PRUEBA-123', '4.0', 'PPT010101XYZ',
            'PROVEEDOR PRUEBA', 'REC010101ABC', 'A', '100', now(), 'MXN', 1000.00, 1160.00, '<cfdi:Comprobante />'
        );
    EXCEPTION WHEN unique_violation THEN
        v_error_disparado := true;
    END;

    ASSERT v_error_disparado = true, 'Debió violar unicidad por UUID fiscal duplicado en la misma org';

    RAISE NOTICE 'PRUEBA TRANSACCIONAL T4: EXITOSA';
END $$;

ROLLBACK;
