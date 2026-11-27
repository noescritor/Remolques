-- Verificación integral SQL (PG 17 real) del bloque Gestión de Equipos
-- Cubre: esquema/CHECK estado, RLS 2 orgs, permisos anon/authenticated, todas las reglas
-- de cancelar/reactivar/cambiar cliente, inmutabilidad de cobros/entregas/fases/stock,
-- vistas filtradas y rechazo de escrituras sobre equipos cancelados.

\set ON_ERROR_STOP on

DO $$
DECLARE
    v_org_a UUID := '11111111-1111-4111-8111-111111111111';
    v_org_b UUID := '22222222-2222-4222-8222-222222222222';
    v_user_a UUID := 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
    v_user_b UUID := 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
    v_cli_a1 TEXT := 'cli-eq-a1';
    v_cli_a2 TEXT := 'cli-eq-a2';
    v_cli_b1 TEXT := 'cli-eq-b1';
    v_cot_a TEXT := 'cot-eq-a1';
    v_prod_a TEXT := 'prod-eq-a1';
    v_linea_a UUID;
    v_fase_a UUID;
    v_frente_a UUID;
    v_area_a UUID;
    v_fase_desp_a UUID;
    v_ot_cot UUID;
    v_ot_man UUID;
    v_ot_mat UUID;
    v_ot_b UUID;
    v_linea_desp UUID;
    v_res JSONB;
    v_cnt INT;
    v_stock_antes NUMERIC;
    v_stock_despues NUMERIC;
    v_fases_antes JSONB;
    v_fases_despues JSONB;
    v_entregas_antes INT;
    v_entregas_despues INT;
    v_folio_antes TEXT;
    v_folio_despues TEXT;
    v_pago_id TEXT;
    v_err TEXT;
BEGIN
    -- 0. Sembrar dos organizaciones, usuarios, clientes, cotización, producto, líneas y fases
    INSERT INTO organizaciones (id, nombre) VALUES (v_org_a, 'Org Equipos A') ON CONFLICT (id) DO NOTHING;
    INSERT INTO organizaciones (id, nombre) VALUES (v_org_b, 'Org Equipos B') ON CONFLICT (id) DO NOTHING;

    INSERT INTO auth.users (id, email) VALUES (v_user_a, 'admin_a@test.local') ON CONFLICT (id) DO NOTHING;
    INSERT INTO auth.users (id, email) VALUES (v_user_b, 'admin_b@test.local') ON CONFLICT (id) DO NOTHING;

    INSERT INTO perfiles_organizacion (organizacion_id, usuario_id, rol)
    VALUES (v_org_a, v_user_a, 'propietario'), (v_org_b, v_user_b, 'admin')
    ON CONFLICT DO NOTHING;

    INSERT INTO clientes (id, organizacion_id, nombre_razon_social)
    VALUES
        (v_cli_a1, v_org_a, 'Transportes Alfa'),
        (v_cli_a2, v_org_a, 'Logística Beta'),
        (v_cli_b1, v_org_b, 'Cliente Org B')
    ON CONFLICT (id) DO NOTHING;

    INSERT INTO productos (id, organizacion_id, nombre, unidad, precio_unitario, stock_actual)
    VALUES (v_prod_a, v_org_a, 'Placa Acero Test', 'pz', 100, 50)
    ON CONFLICT (id) DO UPDATE SET stock_actual = 50;

    INSERT INTO cotizaciones (id, organizacion_id, cliente_id, folio, estado, total)
    VALUES (v_cot_a, v_org_a, v_cli_a1, 'COT-EQ-001', 'Aprobada', 100000)
    ON CONFLICT (id) DO UPDATE SET estado = 'Aprobada', total = 100000;

    PERFORM sembrar_tablero_produccion(v_org_a);
    PERFORM sembrar_tablero_produccion(v_org_b);
    PERFORM sembrar_calidad_plantillas(v_org_a);

    SELECT id INTO v_linea_a FROM lineas_producto WHERE organizacion_id = v_org_a AND clave = 'plataforma' LIMIT 1;
    SELECT id INTO v_fase_a FROM fases_produccion WHERE linea_producto_id = v_linea_a AND activo = true ORDER BY orden ASC LIMIT 1;

    -- Área y frente para plan semanal
    INSERT INTO produccion_areas (organizacion_id, clave, nombre, orden)
    VALUES (v_org_a, 'armado_test', 'Armado Test', 1)
    ON CONFLICT DO NOTHING;
    SELECT id INTO v_area_a FROM produccion_areas WHERE organizacion_id = v_org_a LIMIT 1;

    INSERT INTO produccion_frentes (organizacion_id, area_id, nombre, orden, activo)
    VALUES (v_org_a, v_area_a, 'Frente 1', 1, true)
    ON CONFLICT DO NOTHING;
    SELECT id INTO v_frente_a FROM produccion_frentes WHERE organizacion_id = v_org_a AND activo = true LIMIT 1;

    -- Fase despiece
    INSERT INTO fases_despiece (organizacion_id, clave, nombre, orden, activo)
    VALUES (v_org_a, 'paso_1', 'Paso 1', 1, true)
    ON CONFLICT DO NOTHING;
    SELECT id INTO v_fase_desp_a FROM fases_despiece WHERE organizacion_id = v_org_a AND activo = true LIMIT 1;

    -- Crear 4 órdenes: cotización, manual, con material entregado, y una en Org B
    INSERT INTO ordenes_trabajo (organizacion_id, cotizacion_id, cliente_id, nomenclatura_id, modelo, tipo_equipo, origen, linea_producto_id, estado, fecha_pedido)
    VALUES (v_org_a, v_cot_a, v_cli_a1, '901-TRA011126-1', 'Plataforma 40 ft', '01', 'cotizacion', v_linea_a, 'Pendiente', '2026-11-20')
    RETURNING id INTO v_ot_cot;

    INSERT INTO ordenes_trabajo (organizacion_id, cotizacion_id, cliente_id, etiqueta, nomenclatura_id, modelo, tipo_equipo, origen, linea_producto_id, estado, fecha_pedido)
    VALUES (v_org_a, NULL, v_cli_a1, 'Manual Alfa', '902-TRA011126-1', 'Plataforma 40 ft', '01', 'manual', v_linea_a, 'Pendiente', '2026-11-21')
    RETURNING id INTO v_ot_man;

    INSERT INTO ordenes_trabajo (organizacion_id, cotizacion_id, cliente_id, etiqueta, nomenclatura_id, modelo, tipo_equipo, origen, linea_producto_id, estado)
    VALUES (v_org_a, NULL, NULL, 'Stock Material', '903-INV011126-1', 'Plataforma 40 ft', '01', 'manual', v_linea_a, 'Pendiente')
    RETURNING id INTO v_ot_mat;

    INSERT INTO ordenes_trabajo (organizacion_id, cotizacion_id, cliente_id, etiqueta, nomenclatura_id, modelo, tipo_equipo, origen, estado)
    VALUES (v_org_b, NULL, v_cli_b1, 'Org B', '904-CLB011126-1', 'Dolly', '02', 'manual', 'Pendiente')
    RETURNING id INTO v_ot_b;

    PERFORM crear_fases_orden(v_org_a, v_ot_cot);
    PERFORM crear_fases_orden(v_org_a, v_ot_man);
    PERFORM crear_fases_orden(v_org_a, v_ot_mat);

    -- Avanzar una fase en v_ot_mat para que quede En Producción
    PERFORM actualizar_fase_orden(v_org_a, v_ot_mat, v_fase_a, 'en_proceso', NULL, 'Iniciada', v_user_a);

    -- 1. Confirmar que NO se agregó 'Cancelado' al CHECK de estado
    BEGIN
        UPDATE ordenes_trabajo SET estado = 'Cancelado' WHERE id = v_ot_man;
        RAISE EXCEPTION 'FALLO: estado Cancelado no debe existir';
    EXCEPTION WHEN check_violation THEN
        NULL; -- Esperado
    END;

    -- 2. Regla: motivo obligatorio
    BEGIN
        PERFORM cancelar_orden_trabajo(v_org_a, v_user_a, v_ot_man, '   ', false);
        RAISE EXCEPTION 'FALLO: debió rechazar motivo vacío';
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM NOT LIKE '%motivo_requerido%' THEN
            RAISE EXCEPTION 'FALLO inesperado motivo: %', SQLERRM;
        END IF;
    END;

    -- 3. Regla: aislamiento org (Org B no puede cancelar orden de Org A)
    BEGIN
        PERFORM cancelar_orden_trabajo(v_org_b, v_user_b, v_ot_man, 'Intento ajeno', false);
        RAISE EXCEPTION 'FALLO: debió rechazar org ajena';
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM NOT LIKE '%orden_no_encontrada%' THEN
            RAISE EXCEPTION 'FALLO inesperado org ajena: %', SQLERRM;
        END IF;
    END;

    -- 4. Regla: cobros aplicados vigentes -> rechazar cancelación; si se anula el cobro, permite cancelar
    v_res := registrar_cobro(
        v_org_a, v_cot_a, 25000, DATE '2026-11-26', 'Transferencia', 'REF-1', NULL, NULL,
        jsonb_build_array(jsonb_build_object('orden_trabajo_id', v_ot_cot, 'monto', 25000)),
        false, v_user_a
    );
    v_pago_id := v_res->'pago'->>'id';

    BEGIN
        PERFORM cancelar_orden_trabajo(v_org_a, v_user_a, v_ot_cot, 'Cliente canceló', false);
        RAISE EXCEPTION 'FALLO: debió rechazar por cobros vigentes';
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM NOT LIKE '%orden_con_cobros_vigentes%' THEN
            RAISE EXCEPTION 'FALLO inesperado cobros vigentes: %', SQLERRM;
        END IF;
    END;

    -- Anular el cobro y verificar que ahora sí permite cancelar
    PERFORM anular_cobro(v_org_a, v_pago_id, 'Reverso para cancelar equipo', v_user_a);
    v_res := cancelar_orden_trabajo(v_org_a, v_user_a, v_ot_cot, 'Cliente canceló tras anular cobro', false);
    IF (v_res->>'ya_cancelada')::BOOLEAN IS DISTINCT FROM false THEN
        RAISE EXCEPTION 'FALLO: esperaba ya_cancelada=false';
    END IF;

    -- 5. Regla: material entregado sin anular -> pide confirmación explícita; con confirmación cancela sin tocar stock, entregas ni fases
    INSERT INTO orden_despiece_lineas (organizacion_id, orden_trabajo_id, equipo_indice, fase_id, fase_clave, material_id, descripcion, unidad, cantidad_requerida, origen, clave_origen)
    VALUES (v_org_a, v_ot_mat, 1, v_fase_desp_a, 'paso_1', v_prod_a, 'Placa Acero Test', 'pz', 10, 'manual', 'manual::test1')
    RETURNING id INTO v_linea_desp;

    PERFORM registrar_entrega_despiece(v_org_a, v_linea_desp, 4, 'entrega', NULL, 'Juan Operario', 'Entrega inicial', v_user_a);

    SELECT stock_actual INTO v_stock_antes FROM productos WHERE id = v_prod_a;
    SELECT COUNT(*) INTO v_entregas_antes FROM orden_despiece_entregas WHERE orden_trabajo_id = v_ot_mat AND anulada = false;
    SELECT jsonb_agg(jsonb_build_object('fase_id', fase_id, 'estado', estado) ORDER BY fase_id)
    INTO v_fases_antes FROM orden_fases WHERE orden_trabajo_id = v_ot_mat;

    BEGIN
        PERFORM cancelar_orden_trabajo(v_org_a, v_user_a, v_ot_mat, 'Error de línea', false);
        RAISE EXCEPTION 'FALLO: debió pedir confirmación de material entregado';
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM NOT LIKE '%orden_con_material_entregado%' THEN
            RAISE EXCEPTION 'FALLO inesperado material entregado: %', SQLERRM;
        END IF;
    END;

    -- Con confirmación explícita
    v_res := cancelar_orden_trabajo(v_org_a, v_user_a, v_ot_mat, 'Error de línea', true);
    IF (v_res->>'entregas_vigentes')::INT <> 1 OR (v_res->>'cantidad_entregada_vigente')::NUMERIC <> 4 THEN
        RAISE EXCEPTION 'FALLO: resumen entregas incorrecto: %', v_res;
    END IF;

    -- Verificar inmutabilidad de stock, entregas, fases y estado
    SELECT stock_actual INTO v_stock_despues FROM productos WHERE id = v_prod_a;
    SELECT COUNT(*) INTO v_entregas_despues FROM orden_despiece_entregas WHERE orden_trabajo_id = v_ot_mat AND anulada = false;
    SELECT jsonb_agg(jsonb_build_object('fase_id', fase_id, 'estado', estado) ORDER BY fase_id)
    INTO v_fases_despues FROM orden_fases WHERE orden_trabajo_id = v_ot_mat;

    IF v_stock_antes <> v_stock_despues THEN
        RAISE EXCEPTION 'FALLO: stock cambió al cancelar (% -> %)', v_stock_antes, v_stock_despues;
    END IF;
    IF v_entregas_antes <> v_entregas_despues THEN
        RAISE EXCEPTION 'FALLO: entregas cambiaron al cancelar';
    END IF;
    IF v_fases_antes <> v_fases_despues THEN
        RAISE EXCEPTION 'FALLO: fases cambiaron al cancelar';
    END IF;
    IF (SELECT estado FROM ordenes_trabajo WHERE id = v_ot_mat) <> 'En Producción' THEN
        RAISE EXCEPTION 'FALLO: estado no conservado al cancelar';
    END IF;

    -- 6. Idempotencia: cancelar dos veces no da error ni duplica bitácora
    v_res := cancelar_orden_trabajo(v_org_a, v_user_a, v_ot_mat, 'Segundo intento', true);
    IF (v_res->>'ya_cancelada')::BOOLEAN IS DISTINCT FROM true THEN
        RAISE EXCEPTION 'FALLO: segundo cancelar debió devolver ya_cancelada=true';
    END IF;
    SELECT COUNT(*) INTO v_cnt FROM orden_cambios WHERE orden_trabajo_id = v_ot_mat AND accion = 'cancelar';
    IF v_cnt <> 1 THEN
        RAISE EXCEPTION 'FALLO: duplicó bitácora al cancelar dos veces (count=%)', v_cnt;
    END IF;

    -- 7. Vistas excluyen cancelados
    SELECT COUNT(*) INTO v_cnt FROM v_orden_despiece_avance WHERE orden_trabajo_id = v_ot_mat;
    IF v_cnt <> 0 THEN
        RAISE EXCEPTION 'FALLO: v_orden_despiece_avance incluyó equipo cancelado';
    END IF;
    SELECT COUNT(*) INTO v_cnt FROM v_cobranza_equipo WHERE orden_trabajo_id = v_ot_cot;
    IF v_cnt <> 0 THEN
        RAISE EXCEPTION 'FALLO: v_cobranza_equipo incluyó equipo cancelado';
    END IF;

    -- 8. Escrituras sobre equipo cancelado se rechazan en SQL
    BEGIN
        PERFORM actualizar_fase_orden(v_org_a, v_ot_mat, v_fase_a, 'terminada', NULL, NULL, v_user_a);
        RAISE EXCEPTION 'FALLO: permitió actualizar fase en orden cancelada';
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM NOT LIKE '%orden_cancelada%' THEN RAISE EXCEPTION 'Error inesperado fase: %', SQLERRM; END IF;
    END;

    BEGIN
        PERFORM registrar_entrega_despiece(v_org_a, v_linea_desp, 1, 'entrega', NULL, 'Juan', NULL, v_user_a);
        RAISE EXCEPTION 'FALLO: permitió entrega en orden cancelada';
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM NOT LIKE '%orden_cancelada%' THEN RAISE EXCEPTION 'Error inesperado entrega: %', SQLERRM; END IF;
    END;

    v_res := guardar_plan_tarea(v_org_a, v_user_a, NULL, DATE '2026-11-27', v_frente_a, v_ot_mat, 'Tarea test', NULL, NULL, false, NULL, ARRAY[]::UUID[], '[]'::JSONB);
    IF (v_res->>'exito')::BOOLEAN <> false OR v_res->>'error' <> 'orden_cancelada' THEN
        RAISE EXCEPTION 'FALLO: permitió tarea en orden cancelada: %', v_res;
    END IF;

    BEGIN
        PERFORM crear_inspeccion_calidad(v_org_a, v_ot_mat, 'control_total', NULL, v_user_a);
        RAISE EXCEPTION 'FALLO: permitió inspección de calidad en orden cancelada';
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM NOT LIKE '%ORDEN_CANCELADA%' THEN RAISE EXCEPTION 'Error inesperado calidad: %', SQLERRM; END IF;
    END;

    BEGIN
        PERFORM registrar_cobro(
            v_org_a, v_cot_a, 1000, DATE '2026-11-26', 'Efectivo', NULL, NULL, NULL,
            jsonb_build_array(jsonb_build_object('orden_trabajo_id', v_ot_cot, 'monto', 1000)),
            false, v_user_a
        );
        RAISE EXCEPTION 'FALLO: permitió cobro aplicado a orden cancelada';
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM NOT LIKE '%orden_cancelada%' THEN RAISE EXCEPTION 'Error inesperado cobro: %', SQLERRM; END IF;
    END;

    -- 9. Reactivar: deja estado y fases exactamente iguales + idempotencia
    v_res := reactivar_orden_trabajo(v_org_a, v_user_a, v_ot_mat, 'Se retoma producción');
    IF (v_res->>'ya_activa')::BOOLEAN IS DISTINCT FROM false THEN
        RAISE EXCEPTION 'FALLO: reactivar debió devolver ya_activa=false';
    END IF;
    IF (SELECT estado FROM ordenes_trabajo WHERE id = v_ot_mat) <> 'En Producción' THEN
        RAISE EXCEPTION 'FALLO: estado alterado tras reactivar';
    END IF;
    IF (SELECT cancelada_el FROM ordenes_trabajo WHERE id = v_ot_mat) IS NOT NULL THEN
        RAISE EXCEPTION 'FALLO: cancelada_el no quedó NULL tras reactivar';
    END IF;
    SELECT jsonb_agg(jsonb_build_object('fase_id', fase_id, 'estado', estado) ORDER BY fase_id)
    INTO v_fases_despues FROM orden_fases WHERE orden_trabajo_id = v_ot_mat;
    IF v_fases_antes <> v_fases_despues THEN
        RAISE EXCEPTION 'FALLO: fases cambiaron tras reactivar';
    END IF;
    -- Segunda reactivación idempotente
    v_res := reactivar_orden_trabajo(v_org_a, v_user_a, v_ot_mat, 'Repetido');
    IF (v_res->>'ya_activa')::BOOLEAN IS DISTINCT FROM true THEN
        RAISE EXCEPTION 'FALLO: segunda reactivación debió ser ya_activa=true';
    END IF;

    -- 10. Cambiar cliente: solo manual, folio intacto, bitácora registrada
    -- 10a. Reactivar v_ot_cot primero y verificar rechazo por origen='cotizacion'
    PERFORM reactivar_orden_trabajo(v_org_a, v_user_a, v_ot_cot, 'Reactivar para probar cambio cliente');
    BEGIN
        PERFORM cambiar_cliente_orden_trabajo(v_org_a, v_user_a, v_ot_cot, v_cli_a2, NULL, 'Intento cotización');
        RAISE EXCEPTION 'FALLO: permitió cambiar cliente en orden de cotización';
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM NOT LIKE '%orden_origen_cotizacion%' THEN RAISE EXCEPTION 'Error inesperado origen: %', SQLERRM; END IF;
    END;

    -- 10b. Manual: cambiar a otro cliente de la misma org (folio no cambia)
    SELECT nomenclatura_id INTO v_folio_antes FROM ordenes_trabajo WHERE id = v_ot_man;
    v_res := cambiar_cliente_orden_trabajo(v_org_a, v_user_a, v_ot_man, v_cli_a2, 'Manual Beta', 'Reasignación');
    SELECT nomenclatura_id INTO v_folio_despues FROM ordenes_trabajo WHERE id = v_ot_man;
    IF v_folio_antes <> v_folio_despues THEN
        RAISE EXCEPTION 'FALLO: el folio cambió al cambiar cliente (% -> %)', v_folio_antes, v_folio_despues;
    END IF;
    IF (SELECT cliente_id FROM ordenes_trabajo WHERE id = v_ot_man) <> v_cli_a2 THEN
        RAISE EXCEPTION 'FALLO: cliente_id no se actualizó';
    END IF;

    -- 10c. Manual: dejar sin cliente con etiqueta
    v_res := cambiar_cliente_orden_trabajo(v_org_a, v_user_a, v_ot_man, NULL, 'Inventario Planta', 'Pasa a stock');
    IF (SELECT cliente_id FROM ordenes_trabajo WHERE id = v_ot_man) IS NOT NULL
       OR (SELECT etiqueta FROM ordenes_trabajo WHERE id = v_ot_man) <> 'Inventario Planta' THEN
        RAISE EXCEPTION 'FALLO: no dejó sin cliente con etiqueta';
    END IF;

    -- 10d. Manual: sin cliente ni etiqueta -> rechazo
    BEGIN
        PERFORM cambiar_cliente_orden_trabajo(v_org_a, v_user_a, v_ot_man, NULL, '   ', 'Vacío');
        RAISE EXCEPTION 'FALLO: permitió dejar sin cliente ni etiqueta';
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM NOT LIKE '%cliente_o_etiqueta_requerido%' THEN RAISE EXCEPTION 'Error inesperado sin ambos: %', SQLERRM; END IF;
    END;

    -- 10e. Manual: cliente de otra org -> rechazo
    BEGIN
        PERFORM cambiar_cliente_orden_trabajo(v_org_a, v_user_a, v_ot_man, v_cli_b1, NULL, 'Ajeno');
        RAISE EXCEPTION 'FALLO: permitió cliente de otra org';
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM NOT LIKE '%cliente_no_encontrado%' THEN RAISE EXCEPTION 'Error inesperado cli ajeno: %', SQLERRM; END IF;
    END;

    -- Cancelar orden en Org B para probar RLS entre 2 orgs
    PERFORM cancelar_orden_trabajo(v_org_b, v_user_b, v_ot_b, 'Cancelación Org B', false);

    RAISE NOTICE 'OK: Todas las reglas SQL de Gestión de Equipos pasaron.';
END $$;

-- 11. Permisos con roles reales (anon y authenticated) y RLS en orden_cambios entre 2 organizaciones
DO $$
DECLARE
    v_cnt INT;
BEGIN
    -- Como anon: no puede ejecutar RPCs ni leer orden_cambios
    EXECUTE 'SET LOCAL ROLE anon';
    BEGIN
        PERFORM cancelar_orden_trabajo('11111111-1111-4111-8111-111111111111'::UUID, NULL, gen_random_uuid(), 'test', false);
        RAISE EXCEPTION 'FALLO: anon pudo ejecutar cancelar_orden_trabajo';
    EXCEPTION WHEN insufficient_privilege THEN NULL;
    END;

    BEGIN
        PERFORM reactivar_orden_trabajo('11111111-1111-4111-8111-111111111111'::UUID, NULL, gen_random_uuid(), NULL);
        RAISE EXCEPTION 'FALLO: anon pudo ejecutar reactivar_orden_trabajo';
    EXCEPTION WHEN insufficient_privilege THEN NULL;
    END;

    BEGIN
        PERFORM cambiar_cliente_orden_trabajo('11111111-1111-4111-8111-111111111111'::UUID, NULL, gen_random_uuid(), NULL, 'X', NULL);
        RAISE EXCEPTION 'FALLO: anon pudo ejecutar cambiar_cliente_orden_trabajo';
    EXCEPTION WHEN insufficient_privilege THEN NULL;
    END;

    BEGIN
        PERFORM COUNT(*) FROM orden_cambios;
        RAISE EXCEPTION 'FALLO: anon pudo leer orden_cambios';
    EXCEPTION WHEN insufficient_privilege THEN NULL;
    END;

    RESET ROLE;

    -- Como authenticated (usuario Org A):
    EXECUTE 'SET LOCAL ROLE authenticated';
    PERFORM set_config('request.jwt.claims', '{"sub":"aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa","role":"authenticated"}', true);

    -- No puede ejecutar las RPCs SECURITY DEFINER
    BEGIN
        PERFORM cancelar_orden_trabajo('11111111-1111-4111-8111-111111111111'::UUID, NULL, gen_random_uuid(), 'test', false);
        RAISE EXCEPTION 'FALLO: authenticated pudo ejecutar cancelar_orden_trabajo';
    EXCEPTION WHEN insufficient_privilege THEN NULL;
    END;

    -- Solo ve orden_cambios de Org A, cero de Org B
    SELECT COUNT(*) INTO v_cnt FROM orden_cambios WHERE organizacion_id = '11111111-1111-4111-8111-111111111111'::UUID;
    IF v_cnt < 4 THEN
        RAISE EXCEPTION 'FALLO RLS: Org A esperaba >=4 cambios, vio %', v_cnt;
    END IF;
    SELECT COUNT(*) INTO v_cnt FROM orden_cambios WHERE organizacion_id = '22222222-2222-4222-8222-222222222222'::UUID;
    IF v_cnt <> 0 THEN
        RAISE EXCEPTION 'FALLO RLS: Org A vio % cambios de Org B', v_cnt;
    END IF;

    -- No puede escribir en orden_cambios
    BEGIN
        INSERT INTO orden_cambios (organizacion_id, orden_trabajo_id, accion, motivo)
        VALUES ('11111111-1111-4111-8111-111111111111'::UUID, gen_random_uuid(), 'cancelar', 'hack');
        RAISE EXCEPTION 'FALLO: authenticated pudo insertar en orden_cambios';
    EXCEPTION WHEN insufficient_privilege THEN NULL;
    END;

    -- Cambiar a usuario Org B: solo ve Org B, cero de Org A
    PERFORM set_config('request.jwt.claims', '{"sub":"bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb","role":"authenticated"}', true);
    SELECT COUNT(*) INTO v_cnt FROM orden_cambios WHERE organizacion_id = '22222222-2222-4222-8222-222222222222'::UUID;
    IF v_cnt <> 1 THEN
        RAISE EXCEPTION 'FALLO RLS: Org B esperaba 1 cambio, vio %', v_cnt;
    END IF;
    SELECT COUNT(*) INTO v_cnt FROM orden_cambios WHERE organizacion_id = '11111111-1111-4111-8111-111111111111'::UUID;
    IF v_cnt <> 0 THEN
        RAISE EXCEPTION 'FALLO RLS: Org B vio % cambios de Org A', v_cnt;
    END IF;

    RESET ROLE;
    RAISE NOTICE 'OK: RLS entre 2 organizaciones y permisos con roles reales (anon/authenticated) pasaron.';
END $$;
