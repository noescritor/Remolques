-- Prueba transaccional de T3 (Checklist de almacén)
-- Se ejecuta dentro de un bloque BEGIN ... ROLLBACK

BEGIN;

DO $$
DECLARE
    v_org_id UUID;
    v_org2_id UUID := '00000000-0000-0000-0000-000000000002';
    v_ot_id UUID;
    v_linea_id UUID;
    v_res JSONB;
    v_entrega_id UUID;
    v_error_capturado BOOLEAN := false;
BEGIN
    SELECT id INTO v_org_id FROM organizaciones LIMIT 1;
    IF v_org_id IS NULL THEN
        RAISE EXCEPTION 'No se encontró organización de prueba';
    END IF;

    -- 1. Crear OT ficticia para la prueba
    INSERT INTO ordenes_trabajo (organizacion_id, cotizacion_id, cliente_id, nomenclatura_id, modelo, estado)
    VALUES (v_org_id, 'COT-TEST-T3', 'CLI-TEST', 'NOM-T3', 'PLATAFORMA 2 40 FT', 'En Producción')
    RETURNING id INTO v_ot_id;

    -- 2. Insertar línea de prueba (ej. 2 loderas requeridas)
    INSERT INTO orden_despiece_lineas (
        organizacion_id,
        orden_trabajo_id,
        equipo_indice,
        fase_clave,
        descripcion,
        cantidad_requerida,
        clave_origen
    ) VALUES (
        v_org_id,
        v_ot_id,
        1,
        'paso_12',
        'LODERA LEOLCA BLANCA',
        2,
        'paso_12::lodera::1'
    )
    RETURNING id INTO v_linea_id;

    -- 3. Entrega válida de 1 pieza
    v_res := registrar_entrega_despiece(
        p_org_id := v_org_id,
        p_linea_id := v_linea_id,
        p_cantidad := 1,
        p_tipo := 'entrega',
        p_operario_nombre := 'Juan Perez',
        p_motivo := 'Entrega inicial'
    );

    IF (v_res->>'pendiente')::numeric != 1 THEN
        RAISE EXCEPTION 'Pendiente esperado 1, obtenido %', v_res->>'pendiente';
    END IF;

    v_entrega_id := (v_res->>'entrega_id')::uuid;

    -- 4. Intento de sobre-entrega (intentar entregar 2 cuando solo queda 1) -> debe rechazar con excede_requerido
    v_error_capturado := false;
    BEGIN
        PERFORM registrar_entrega_despiece(
            p_org_id := v_org_id,
            p_linea_id := v_linea_id,
            p_cantidad := 2,
            p_tipo := 'entrega',
            p_operario_nombre := 'Pedro Gomez'
        );
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%excede_requerido%' THEN
            v_error_capturado := true;
        END IF;
    END;

    IF NOT v_error_capturado THEN
        RAISE EXCEPTION 'Fallo: Debió rechazar entrega que excede lo requerido';
    END IF;

    -- 5. Reposición sin motivo -> debe rechazar
    v_error_capturado := false;
    BEGIN
        PERFORM registrar_entrega_despiece(
            p_org_id := v_org_id,
            p_linea_id := v_linea_id,
            p_cantidad := 1,
            p_tipo := 'reposicion',
            p_motivo := ''
        );
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%motivo_requerido%' THEN
            v_error_capturado := true;
        END IF;
    END;

    IF NOT v_error_capturado THEN
        RAISE EXCEPTION 'Fallo: Reposición sin motivo debió ser rechazada';
    END IF;

    -- 6. Reposición con motivo válido (ej. pieza rota) -> debe aceptar y no afectar lo pendiente
    v_res := registrar_entrega_despiece(
        p_org_id := v_org_id,
        p_linea_id := v_linea_id,
        p_cantidad := 1,
        p_tipo := 'reposicion',
        p_motivo := 'Pieza dañada en maniobra de armado'
    );

    IF (v_res->>'pendiente')::numeric != 1 THEN
        RAISE EXCEPTION 'Reposición no debe alterar cantidad_pendiente de entrega regular';
    END IF;

    -- 7. Anulación de entrega inicial
    v_res := anular_entrega_despiece(
        p_org_id := v_org_id,
        p_entrega_id := v_entrega_id,
        p_motivo := 'Error de captura por el almacenista'
    );

    IF (v_res->>'pendiente')::numeric != 2 THEN
        RAISE EXCEPTION 'Tras anular entrega de 1, el pendiente debe regresar a 2';
    END IF;

    -- 8. Probar cantidad fraccionaria (0.25 de consumible)
    INSERT INTO orden_despiece_lineas (
        organizacion_id,
        orden_trabajo_id,
        equipo_indice,
        fase_clave,
        descripcion,
        cantidad_requerida,
        clave_origen
    ) VALUES (
        v_org_id,
        v_ot_id,
        1,
        'paso_1',
        'DISCO DE DESBASTE 9',
        1,
        'paso_1::disco_9::1'
    )
    RETURNING id INTO v_linea_id;

    v_res := registrar_entrega_despiece(
        p_org_id := v_org_id,
        p_linea_id := v_linea_id,
        p_cantidad := 0.25,
        p_tipo := 'entrega'
    );

    IF (v_res->>'pendiente')::numeric != 0.75 THEN
        RAISE EXCEPTION 'Pendiente fraccionario esperado 0.75, obtenido %', v_res->>'pendiente';
    END IF;

    -- 9. Aislamiento multi-org (operar con otra org debe fallar)
    v_error_capturado := false;
    BEGIN
        PERFORM registrar_entrega_despiece(
            p_org_id := v_org2_id,
            p_linea_id := v_linea_id,
            p_cantidad := 0.25,
            p_tipo := 'entrega'
        );
    EXCEPTION WHEN OTHERS THEN
        v_error_capturado := true;
    END;

    IF NOT v_error_capturado THEN
        RAISE EXCEPTION 'Fallo: Se permitió acceso cruzado entre organizaciones';
    END IF;

    RAISE NOTICE 'Prueba transaccional T3 finalizada con éxito. Ejecutando ROLLBACK.';
END $$;

ROLLBACK;
