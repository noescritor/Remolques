-- Prueba transaccional de T3 (Checklist de almacén)
-- Se ejecuta dentro de un bloque BEGIN ... ROLLBACK para no dejar basura

BEGIN;

DO $$
DECLARE
    v_org_a UUID;
    v_org_b UUID := '00000000-0000-0000-0000-000000000002';
    v_cli_id TEXT := 'CLI-TEST-T3';
    v_cot_id TEXT := 'COT-TEST-T3';
    v_ot_id UUID;
    v_ot_b_id UUID;
    v_linea_id UUID;
    v_linea_b_id UUID;
    v_linea_manual_id UUID;
    v_res JSONB;
    v_entrega_id UUID;
    v_error_capturado BOOLEAN := false;
BEGIN
    SELECT id INTO v_org_a FROM organizaciones LIMIT 1;
    IF v_org_a IS NULL THEN
        RAISE EXCEPTION 'No se encontró organización de prueba';
    END IF;

    -- 0. Crear segunda organización si no existe
    INSERT INTO organizaciones (id, nombre)
    VALUES (v_org_b, 'Organización Test B')
    ON CONFLICT (id) DO NOTHING;

    -- 1. Crear cliente y cotización ficticios para satisfacer FKs
    INSERT INTO clientes (id, organizacion_id, nombre_razon_social)
    VALUES (v_cli_id, v_org_a, 'CLIENTE TEST CHECKLIST')
    ON CONFLICT (id) DO NOTHING;

    INSERT INTO cotizaciones (id, organizacion_id, cliente_id, folio, fecha)
    VALUES (v_cot_id, v_org_a, v_cli_id, 'COT-TEST-999', CURRENT_DATE)
    ON CONFLICT (id) DO NOTHING;

    -- 2. Crear OT ficticia para la prueba en Org A
    INSERT INTO ordenes_trabajo (organizacion_id, cotizacion_id, cliente_id, nomenclatura_id, modelo, estado)
    VALUES (v_org_a, v_cot_id, v_cli_id, 'NOM-T3', 'PLATAFORMA 2 40 FT', 'En Producción')
    RETURNING id INTO v_ot_id;

    -- Crear OT ficticia en Org B
    INSERT INTO clientes (id, organizacion_id, nombre_razon_social)
    VALUES ('CLI-TEST-B', v_org_b, 'CLIENTE B')
    ON CONFLICT (id) DO NOTHING;

    INSERT INTO cotizaciones (id, organizacion_id, cliente_id, folio, fecha)
    VALUES ('COT-TEST-B', v_org_b, 'CLI-TEST-B', 'COT-B-999', CURRENT_DATE)
    ON CONFLICT (id) DO NOTHING;

    INSERT INTO ordenes_trabajo (organizacion_id, cotizacion_id, cliente_id, nomenclatura_id, modelo, estado)
    VALUES (v_org_b, 'COT-TEST-B', 'CLI-TEST-B', 'NOM-T3-B', 'PLATAFORMA 3 40 FT', 'En Producción')
    RETURNING id INTO v_ot_b_id;

    -- 3. Insertar línea de prueba en Org A (ej. 2 loderas requeridas)
    INSERT INTO orden_despiece_lineas (
        organizacion_id,
        orden_trabajo_id,
        equipo_indice,
        fase_clave,
        descripcion,
        cantidad_requerida,
        clave_origen
    ) VALUES (
        v_org_a,
        v_ot_id,
        1,
        'paso_12',
        'LODERA LEOLCA BLANCA',
        2,
        'paso_12::lodera::base'
    )
    RETURNING id INTO v_linea_id;

    -- Insertar línea de prueba en Org B
    INSERT INTO orden_despiece_lineas (
        organizacion_id,
        orden_trabajo_id,
        equipo_indice,
        fase_clave,
        descripcion,
        cantidad_requerida,
        clave_origen
    ) VALUES (
        v_org_b,
        v_ot_b_id,
        1,
        'paso_12',
        'LODERA LEOLCA NEGRA',
        4,
        'paso_12::lodera_negra::base'
    )
    RETURNING id INTO v_linea_b_id;

    -- 4. Entrega válida de 1 pieza en Org A -> pendiente debe ser 1
    v_res := registrar_entrega_despiece(
        p_org_id := v_org_a,
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

    -- 5. Intento de sobre-entrega (intentar entregar 2 cuando solo queda 1) -> debe rechazar con excede_requerido
    v_error_capturado := false;
    BEGIN
        PERFORM registrar_entrega_despiece(
            p_org_id := v_org_a,
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

    -- 6. Reposición sin motivo -> debe rechazar con motivo_requerido
    v_error_capturado := false;
    BEGIN
        PERFORM registrar_entrega_despiece(
            p_org_id := v_org_a,
            p_linea_id := v_linea_id,
            p_cantidad := 1,
            p_tipo := 'reposicion',
            p_motivo := '   '
        );
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%motivo_requerido%' THEN
            v_error_capturado := true;
        END IF;
    END;

    IF NOT v_error_capturado THEN
        RAISE EXCEPTION 'Fallo: Reposición sin motivo debió ser rechazada';
    END IF;

    -- 7. Reposición con motivo válido -> debe aceptar y no reducir cantidad_pendiente
    v_res := registrar_entrega_despiece(
        p_org_id := v_org_a,
        p_linea_id := v_linea_id,
        p_cantidad := 1,
        p_tipo := 'reposicion',
        p_motivo := 'Pieza dañada en maniobra de armado'
    );

    IF (v_res->>'pendiente')::numeric != 1 THEN
        RAISE EXCEPTION 'Reposición no debe alterar cantidad_pendiente de entrega regular';
    END IF;

    -- 8. Probar ajuste de cantidad requerida (ajustar_cantidad_despiece)
    -- Intentar reducir por debajo de lo ya entregado (1 entregado vs nueva requerida 0.5) -> debe fallar
    v_error_capturado := false;
    BEGIN
        PERFORM ajustar_cantidad_despiece(
            p_org_id := v_org_a,
            p_linea_id := v_linea_id,
            p_nueva_cantidad := 0.5,
            p_motivo := 'Reducción excesiva'
        );
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%excede_entregado%' THEN
            v_error_capturado := true;
        END IF;
    END;

    IF NOT v_error_capturado THEN
        RAISE EXCEPTION 'Fallo: Debió rechazar ajuste por debajo de lo ya entregado';
    END IF;

    -- Ajuste válido a 3 piezas -> pendiente debe subir a 2
    v_res := ajustar_cantidad_despiece(
        p_org_id := v_org_a,
        p_linea_id := v_linea_id,
        p_nueva_cantidad := 3,
        p_motivo := 'Se solicita 1 lodera de repuesto para chasis'
    );

    IF (v_res->>'pendiente')::numeric != 2 THEN
        RAISE EXCEPTION 'Tras ajuste a 3 piezas con 1 entregada, pendiente debe ser 2, obtenido %', v_res->>'pendiente';
    END IF;

    -- 9. Trigger trg_lineas_requerida_vs_entregada: update directo por debajo de entregado debe abortar
    v_error_capturado := false;
    BEGIN
        UPDATE orden_despiece_lineas
        SET cantidad_requerida = 0.8
        WHERE id = v_linea_id;
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%cantidad_requerida_invalida%' THEN
            v_error_capturado := true;
        END IF;
    END;

    IF NOT v_error_capturado THEN
        RAISE EXCEPTION 'Fallo: Trigger debió impedir que UPDATE deje cantidad_requerida < entregado';
    END IF;

    -- 10. Anulación de entrega inicial -> pendiente debe regresar a 3
    v_res := anular_entrega_despiece(
        p_org_id := v_org_a,
        p_entrega_id := v_entrega_id,
        p_motivo := 'Error de captura por el almacenista'
    );

    IF (v_res->>'pendiente')::numeric != 3 THEN
        RAISE EXCEPTION 'Tras anular entrega de 1, el pendiente debe regresar a 3, obtenido %', v_res->>'pendiente';
    END IF;

    -- 11. Eliminar línea: no se puede eliminar si tiene entregas en el historial
    v_error_capturado := false;
    BEGIN
        PERFORM eliminar_linea_despiece(
            p_org_id := v_org_a,
            p_linea_id := v_linea_id
        );
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%linea_con_historial%' OR SQLERRM LIKE '%linea_no_eliminable%' THEN
            v_error_capturado := true;
        END IF;
    END;

    IF NOT v_error_capturado THEN
        RAISE EXCEPTION 'Fallo: Debió impedir borrar línea con historial de entregas';
    END IF;

    -- 12. Crear línea manual y eliminarla limpiamente
    INSERT INTO orden_despiece_lineas (
        organizacion_id,
        orden_trabajo_id,
        equipo_indice,
        fase_clave,
        descripcion,
        cantidad_requerida,
        origen,
        clave_origen
    ) VALUES (
        v_org_a,
        v_ot_id,
        1,
        'paso_1',
        'TORNILLO MANUAL EXTRA',
        10,
        'manual',
        'manual::test::1'
    )
    RETURNING id INTO v_linea_manual_id;

    v_res := eliminar_linea_despiece(
        p_org_id := v_org_a,
        p_linea_id := v_linea_manual_id
    );

    IF (v_res->>'eliminada')::boolean != true THEN
        RAISE EXCEPTION 'Línea manual sin entregas debió ser eliminada exitosamente';
    END IF;

    -- 13. Aislamiento multi-org: Org B intentando operar línea de Org A debe fallar
    v_error_capturado := false;
    BEGIN
        PERFORM registrar_entrega_despiece(
            p_org_id := v_org_b,
            p_linea_id := v_linea_id,
            p_cantidad := 1,
            p_tipo := 'entrega'
        );
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%linea_no_encontrada%' THEN
            v_error_capturado := true;
        END IF;
    END;

    IF NOT v_error_capturado THEN
        RAISE EXCEPTION 'Fallo: Se permitió acceso cruzado entre organizaciones';
    END IF;

    -- 14. Rechazar 'NaN'::numeric en registrar_entrega_despiece
    v_error_capturado := false;
    BEGIN
        PERFORM registrar_entrega_despiece(
            p_org_id := v_org_a,
            p_linea_id := v_linea_id,
            p_cantidad := 'NaN'::numeric,
            p_tipo := 'entrega'
        );
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%cantidad_invalida%' THEN
            v_error_capturado := true;
        END IF;
    END;

    IF NOT v_error_capturado THEN
        RAISE EXCEPTION 'Fallo: Debió rechazar NaN en registrar_entrega_despiece';
    END IF;

    -- 15. Rechazar 'NaN'::numeric en ajustar_cantidad_despiece
    v_error_capturado := false;
    BEGIN
        PERFORM ajustar_cantidad_despiece(
            p_org_id := v_org_a,
            p_linea_id := v_linea_id,
            p_nueva_cantidad := 'NaN'::numeric,
            p_motivo := 'Ajuste NaN'
        );
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%cantidad_invalida%' THEN
            v_error_capturado := true;
        END IF;
    END;

    IF NOT v_error_capturado THEN
        RAISE EXCEPTION 'Fallo: Debió rechazar NaN en ajustar_cantidad_despiece';
    END IF;

    -- 16. Probar entregar_fase_despiece atómico
    DECLARE
        v_fase_test_id UUID;
        v_lin_fase_1 UUID;
        v_lin_fase_2 UUID;
        v_res_fase JSONB;
    BEGIN
        INSERT INTO fases_despiece (organizacion_id, clave, nombre, orden)
        VALUES (v_org_a, 'paso_fase_test', 'Fase Test Atomica', 99)
        ON CONFLICT (organizacion_id, clave) DO UPDATE SET nombre = EXCLUDED.nombre
        RETURNING id INTO v_fase_test_id;

        INSERT INTO orden_despiece_lineas (
            organizacion_id, orden_trabajo_id, equipo_indice, fase_id, fase_clave,
            descripcion, cantidad_requerida, clave_origen
        ) VALUES
        (v_org_a, v_ot_id, 1, v_fase_test_id, 'paso_fase_test', 'PIEZA FASE 1', 5, 'fase::test::p1');

        INSERT INTO orden_despiece_lineas (
            organizacion_id, orden_trabajo_id, equipo_indice, fase_id, fase_clave,
            descripcion, cantidad_requerida, clave_origen
        ) VALUES
        (v_org_a, v_ot_id, 1, v_fase_test_id, 'paso_fase_test', 'PIEZA FASE 2', 3, 'fase::test::p2');

        v_res_fase := entregar_fase_despiece(
            p_org_id := v_org_a,
            p_orden_trabajo_id := v_ot_id,
            p_equipo_indice := 1,
            p_fase_id := v_fase_test_id,
            p_operario_nombre := 'Operario Fase Completa'
        );

        IF (v_res_fase->>'lineas_entregadas')::int != 2 THEN
            RAISE EXCEPTION 'Fase completa debió entregar 2 líneas, entregó %', v_res_fase->>'lineas_entregadas';
        END IF;

        -- Verificar que las entregas registraron el orden_trabajo_id correctamente
        IF NOT EXISTS (
            SELECT 1 FROM orden_despiece_entregas
            WHERE orden_trabajo_id = v_ot_id AND operario_nombre = 'Operario Fase Completa'
        ) THEN
            RAISE EXCEPTION 'Las entregas de fase no guardaron el orden_trabajo_id esperado';
        END IF;
    END;

    RAISE NOTICE 'Prueba transaccional T3 completada exitosamente (0 errores). Ejecutando ROLLBACK.';
END $$;

ROLLBACK;
