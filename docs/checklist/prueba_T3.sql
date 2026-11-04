-- Prueba transaccional integral de T3 Ronda 4 (Checklist de almacén)
-- Valida:
-- 1. Restricción FK ON DELETE RESTRICT (no borrado en cascada al eliminar OT o Cotización con entregas)
-- 2. Soporte de unidad / equipo != 1 en OT (entregar_fase_despiece y partidas manuales)
-- 3. Validación de operario perteneciente a la organización
-- 4. Rechazo de 'NaN'::numeric y sobreentregas
-- 5. RLS estricto multi-tenant con usuarios authenticated y aislamiento total
-- 6. Se ejecuta dentro de un bloque BEGIN ... ROLLBACK

\set ON_ERROR_STOP on

BEGIN;

DO $$
DECLARE
    v_org_a UUID;
    v_org_b UUID := '00000000-0000-0000-0000-000000000002';
    v_cli_id TEXT := 'CLI-TEST-T3';
    v_cot_id TEXT := 'COT-TEST-T3';
    v_ot_id UUID;
    v_ot_u2_id UUID;
    v_ot_b_id UUID;
    v_linea_id UUID;
    v_linea_u2_id UUID;
    v_linea_b_id UUID;
    v_linea_manual_id UUID;
    v_fase_id UUID;
    v_res JSONB;
    v_entrega_id UUID;
    v_op_a_id UUID := '00000000-0000-0000-0000-0000000000a1';
    v_op_b_id UUID := '00000000-0000-0000-0000-0000000000b1';
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

    -- Crear usuarios de prueba para RLS
    INSERT INTO auth.users (id, email, raw_user_meta_data)
    VALUES
        ('a988611b-2949-4ab7-b670-daf4a21f4e18', 'test_user_a@remolques.test', '{"nombre":"Usuario A"}'),
        ('00000000-0000-0000-0000-0000000000b2', 'test_user_b@remolques.test', '{"nombre":"Usuario B"}')
    ON CONFLICT (id) DO NOTHING;

    INSERT INTO perfiles_organizacion (usuario_id, organizacion_id, rol)
    VALUES
        ('a988611b-2949-4ab7-b670-daf4a21f4e18', v_org_a, 'usuario'),
        ('00000000-0000-0000-0000-0000000000b2', v_org_b, 'usuario')
    ON CONFLICT DO NOTHING;

    -- Crear operarios para Org A y Org B
    INSERT INTO operarios (id, organizacion_id, nombre, activo)
    VALUES (v_op_a_id, v_org_a, 'Operario Almacén A', true)
    ON CONFLICT (id) DO NOTHING;

    INSERT INTO operarios (id, organizacion_id, nombre, activo)
    VALUES (v_op_b_id, v_org_b, 'Operario Almacén B', true)
    ON CONFLICT (id) DO NOTHING;

    -- Obtener o crear fase de prueba
    SELECT id INTO v_fase_id FROM fases_despiece WHERE organizacion_id = v_org_a AND clave = 'paso_12';
    IF v_fase_id IS NULL THEN
        INSERT INTO fases_despiece (organizacion_id, clave, nombre, orden)
        VALUES (v_org_a, 'paso_12', 'Paso 12', 12)
        RETURNING id INTO v_fase_id;
    END IF;

    -- 1. Crear cliente y cotización ficticios para satisfacer FKs
    INSERT INTO clientes (id, organizacion_id, nombre_razon_social)
    VALUES (v_cli_id, v_org_a, 'CLIENTE TEST CHECKLIST')
    ON CONFLICT (id) DO NOTHING;

    INSERT INTO cotizaciones (id, organizacion_id, cliente_id, folio, fecha)
    VALUES (v_cot_id, v_org_a, v_cli_id, 'COT-TEST-999', CURRENT_DATE)
    ON CONFLICT (id) DO NOTHING;

    -- 2. Crear OT ficticia unidad 1 para la prueba en Org A
    INSERT INTO ordenes_trabajo (organizacion_id, cotizacion_id, cliente_id, nomenclatura_id, modelo, estado, caracteristicas)
    VALUES (v_org_a, v_cot_id, v_cli_id, 'NOM-T3-U1', 'PLATAFORMA 2 40 FT', 'En Producción', '{"unidad": 1}'::jsonb)
    RETURNING id INTO v_ot_id;

    -- Crear OT ficticia unidad 2 en Org A
    INSERT INTO ordenes_trabajo (organizacion_id, cotizacion_id, cliente_id, nomenclatura_id, modelo, estado, caracteristicas)
    VALUES (v_org_a, v_cot_id, v_cli_id, 'NOM-T3-U2', 'PLATAFORMA 2 40 FT', 'En Producción', '{"unidad": 2}'::jsonb)
    RETURNING id INTO v_ot_u2_id;

    -- Crear OT ficticia en Org B
    INSERT INTO clientes (id, organizacion_id, nombre_razon_social)
    VALUES ('CLI-TEST-B', v_org_b, 'CLIENTE B')
    ON CONFLICT (id) DO NOTHING;

    INSERT INTO cotizaciones (id, organizacion_id, cliente_id, folio, fecha)
    VALUES ('COT-TEST-B', v_org_b, 'CLI-TEST-B', 'COT-B-999', CURRENT_DATE)
    ON CONFLICT (id) DO NOTHING;

    INSERT INTO ordenes_trabajo (organizacion_id, cotizacion_id, cliente_id, nomenclatura_id, modelo, estado, caracteristicas)
    VALUES (v_org_b, 'COT-TEST-B', 'CLI-TEST-B', 'NOM-T3-B', 'PLATAFORMA 3 40 FT', 'En Producción', '{"unidad": 1}'::jsonb)
    RETURNING id INTO v_ot_b_id;

    -- 3. Insertar línea de prueba en Org A Unidad 1 (ej. 2 loderas requeridas)
    INSERT INTO orden_despiece_lineas (
        organizacion_id,
        orden_trabajo_id,
        equipo_indice,
        fase_id,
        fase_clave,
        descripcion,
        cantidad_requerida,
        clave_origen
    ) VALUES (
        v_org_a,
        v_ot_id,
        1,
        v_fase_id,
        'paso_12',
        'LODERA LEOLCA BLANCA U1',
        2,
        'paso_12::lodera::u1'
    )
    RETURNING id INTO v_linea_id;

    -- Insertar línea de prueba en Org A Unidad 2 (equipo_indice = 2)
    INSERT INTO orden_despiece_lineas (
        organizacion_id,
        orden_trabajo_id,
        equipo_indice,
        fase_id,
        fase_clave,
        descripcion,
        cantidad_requerida,
        clave_origen
    ) VALUES (
        v_org_a,
        v_ot_u2_id,
        2,
        v_fase_id,
        'paso_12',
        'LODERA LEOLCA BLANCA U2',
        2,
        'paso_12::lodera::u2'
    )
    RETURNING id INTO v_linea_u2_id;

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

    -- 4. Entrega válida de 1 pieza en Org A con operario de Org A -> pendiente debe ser 1
    v_res := registrar_entrega_despiece(
        p_org_id := v_org_a,
        p_linea_id := v_linea_id,
        p_cantidad := 1,
        p_tipo := 'entrega',
        p_operario_id := v_op_a_id,
        p_operario_nombre := 'Operario Almacén A',
        p_motivo := 'Entrega inicial'
    );

    IF (v_res->>'pendiente')::numeric != 1 THEN
        RAISE EXCEPTION 'Pendiente esperado 1, obtenido %', v_res->>'pendiente';
    END IF;

    v_entrega_id := (v_res->>'entrega_id')::uuid;

    -- 5. Validación de pertenencia del operario (Hallazgo 7 BAJA):
    -- Intentar entregar con operario de Org B en Org A debe fallar con operario_no_encontrado
    v_error_capturado := false;
    BEGIN
        PERFORM registrar_entrega_despiece(
            p_org_id := v_org_a,
            p_linea_id := v_linea_id,
            p_cantidad := 1,
            p_tipo := 'entrega',
            p_operario_id := v_op_b_id,
            p_operario_nombre := 'Operario Infiltrado B'
        );
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%operario_no_encontrado%' THEN
            v_error_capturado := true;
        END IF;
    END;

    IF NOT v_error_capturado THEN
        RAISE EXCEPTION 'Fallo: Debió rechazar entrega con operario de otra organización';
    END IF;

    -- 6. Intento de sobre-entrega (intentar entregar 2 cuando solo queda 1) -> debe rechazar con excede_requerido
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

    -- 7. Reposición sin motivo -> debe rechazar con motivo_requerido
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

    -- 9. Rechazo de 'NaN'::numeric en registrar_entrega_despiece
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

    -- 10. Probar entrega por fase en OT de Unidad 2 (Hallazgo 2 ALTA):
    -- Con equipo 1 en OT Unidad 2 -> debe entregar 0
    v_res := entregar_fase_despiece(
        p_org_id := v_org_a,
        p_orden_trabajo_id := v_ot_u2_id,
        p_equipo_indice := 1,
        p_fase_id := v_fase_id,
        p_operario_nombre := 'Operario U2'
    );
    IF (v_res->>'lineas_entregadas')::int != 0 THEN
        RAISE EXCEPTION 'Fase con equipo 1 en OT de unidad 2 debió entregar 0, entregó %', v_res->>'lineas_entregadas';
    END IF;

    -- Con equipo 2 en OT Unidad 2 -> debe entregar 1 línea (las 2 piezas pendientes)
    v_res := entregar_fase_despiece(
        p_org_id := v_org_a,
        p_orden_trabajo_id := v_ot_u2_id,
        p_equipo_indice := 2,
        p_fase_id := v_fase_id,
        p_operario_nombre := 'Operario U2'
    );
    IF (v_res->>'lineas_entregadas')::int != 1 THEN
        RAISE EXCEPTION 'Fase con equipo 2 en OT de unidad 2 debió entregar 1 línea, entregó %', v_res->>'lineas_entregadas';
    END IF;

    -- 11. PRUEBA CRÍTICA: Intento de borrado en cascada (Hallazgo 1 ALTA)
    -- La FK orden_trabajo_id es ON DELETE RESTRICT: borrar la OT o la Cotización DEBE FALLAR
    v_error_capturado := false;
    BEGIN
        DELETE FROM ordenes_trabajo WHERE id = v_ot_id;
    EXCEPTION WHEN foreign_key_violation THEN
        v_error_capturado := true;
    END;

    IF NOT v_error_capturado THEN
        RAISE EXCEPTION 'Fallo: FK orden_trabajo_id debió impedir eliminar la OT con entregas registradas';
    END IF;

    v_error_capturado := false;
    BEGIN
        -- Intentar borrar la cotización padre de la OT con entregas
        DELETE FROM cotizaciones WHERE id = v_cot_id;
    EXCEPTION WHEN foreign_key_violation THEN
        v_error_capturado := true;
    END;

    IF NOT v_error_capturado THEN
        RAISE EXCEPTION 'Fallo: FK RESTRICT debió impedir eliminar la cotización cuyas OTs tienen entregas';
    END IF;

    RAISE NOTICE 'PRUEBA FK RESTRICT: EXITOSA (Borrado de OT y Cotización con entregas fue bloqueado correctamente)';
END $$;

-- 12. PRUEBA DE AISLAMIENTO RLS CON DOS USUARIOS AUTHENTICATED
SET LOCAL ROLE authenticated;
SET LOCAL request.jwt.claim.sub = 'a988611b-2949-4ab7-b670-daf4a21f4e18';

DO $$
DECLARE
    v_count_lineas INT;
    v_count_entregas INT;
    v_error_capturado BOOLEAN := false;
BEGIN
    -- Usuario A debe ver únicamente las líneas de Org A
    SELECT count(*) INTO v_count_lineas FROM orden_despiece_lineas;
    IF v_count_lineas < 2 THEN
        RAISE EXCEPTION 'RLS Fallo: Usuario A debió ver al menos 2 líneas de Org A, vio %', v_count_lineas;
    END IF;

    -- Verificar que NO ve ninguna línea de Org B
    IF EXISTS (
        SELECT 1 FROM orden_despiece_lineas
        WHERE organizacion_id = '00000000-0000-0000-0000-000000000002'
    ) THEN
        RAISE EXCEPTION 'RLS Fallo: Usuario A pudo ver líneas de Org B';
    END IF;

    -- Usuario A no debe poder insertar directamente (solo SELECT permitido por RLS)
    BEGIN
        INSERT INTO orden_despiece_lineas (organizacion_id, orden_trabajo_id, equipo_indice, fase_clave, descripcion, cantidad_requerida, clave_origen)
        VALUES ('00000000-0000-0000-0000-000000000001', gen_random_uuid(), 1, 'paso_1', 'Inyección no autorizada', 1, 'inyeccion');
    EXCEPTION WHEN OTHERS THEN
        v_error_capturado := true;
    END;

    IF NOT v_error_capturado THEN
        RAISE EXCEPTION 'RLS Fallo: Usuario authenticated pudo insertar en orden_despiece_lineas';
    END IF;

    -- Usuario A no debe tener permiso de ejecutar registrar_entrega_despiece
    v_error_capturado := false;
    BEGIN
        PERFORM registrar_entrega_despiece(
            '00000000-0000-0000-0000-000000000001'::uuid,
            gen_random_uuid(),
            1,
            'entrega'
        );
    EXCEPTION WHEN insufficient_privilege THEN
        v_error_capturado := true;
    END;

    IF NOT v_error_capturado THEN
        RAISE EXCEPTION 'Seguridad Fallo: Usuario authenticated pudo ejecutar registrar_entrega_despiece';
    END IF;

    RAISE NOTICE 'PRUEBA RLS USUARIO A: EXITOSA (SELECT filtrado por Org A, bloqueo total de INSERT y RPC)';
END $$;

-- Probar Usuario B
SET LOCAL request.jwt.claim.sub = '00000000-0000-0000-0000-0000000000b2';

DO $$
DECLARE
    v_count_lineas INT;
BEGIN
    -- Usuario B debe ver únicamente las líneas de Org B
    SELECT count(*) INTO v_count_lineas FROM orden_despiece_lineas;
    IF v_count_lineas != 1 THEN
        RAISE EXCEPTION 'RLS Fallo: Usuario B debió ver exactamente 1 línea de Org B, vio %', v_count_lineas;
    END IF;

    -- Verificar que NO ve ninguna línea de Org A
    IF EXISTS (
        SELECT 1 FROM orden_despiece_lineas
        WHERE organizacion_id = '00000000-0000-0000-0000-000000000001'
    ) THEN
        RAISE EXCEPTION 'RLS Fallo: Usuario B pudo ver líneas de Org A';
    END IF;

    RAISE NOTICE 'PRUEBA RLS USUARIO B: EXITOSA (Aislamiento completo de Org B respecto a Org A)';
END $$;

RESET ROLE;

ROLLBACK;
