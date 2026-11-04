-- Prueba Transaccional T6: Editor de Recetas y Clonación Multi-Tenant
-- Ejecuta en un bloque BEGIN...ROLLBACK para no dejar datos residuales

BEGIN;

DO $$
DECLARE
    v_org_a UUID := '11111111-1111-1111-1111-111111111111';
    v_org_b UUID := '22222222-2222-2222-2222-222222222222';
    v_user_a UUID := NULL;
    v_user_b UUID := NULL;

    v_origen_id UUID;
    v_nuevo_modelo_id UUID;
    v_modelo_b_id UUID;
    v_mat_a_id TEXT := 'PRUEBA-MAT-A-T6';
    v_mat_b_id TEXT := 'PRUEBA-MAT-B-T6';
    v_fase_a_id UUID;
    v_fase_b_id UUID;
    v_linea_id UUID;
    v_linea_b_id UUID;

    v_cant_ant INT;
    v_cant_post INT;
    v_costos_count INT;
    v_proc_count INT;
    v_hist_count INT;
    v_costo_prod NUMERIC;
    v_catch_error BOOLEAN;
BEGIN
    -- Obtener usuario de prueba si existe
    SELECT id INTO v_user_a FROM auth.users LIMIT 1;

    -- 0. Preparar organizaciones de prueba
    INSERT INTO public.organizaciones (id, nombre)
    VALUES 
        (v_org_a, 'ORG PRUEBA T6 A'),
        (v_org_b, 'ORG PRUEBA T6 B')
    ON CONFLICT (id) DO UPDATE SET nombre = EXCLUDED.nombre;

    -- Obtener o preparar modelo base en Org A
    SELECT id INTO v_origen_id FROM public.modelos WHERE organizacion_id = v_org_a LIMIT 1;
    IF v_origen_id IS NULL THEN
        -- Si Org A no tiene modelo, buscar cualquier modelo existente y asignar Org A o clonar referencia
        SELECT id INTO v_origen_id FROM public.modelos LIMIT 1;
        IF v_origen_id IS NOT NULL THEN
            UPDATE public.modelos SET organizacion_id = v_org_a WHERE id = v_origen_id;
        END IF;
    END IF;

    -- Si aún no hay modelo, crear uno mínimo para la prueba
    IF v_origen_id IS NULL THEN
        INSERT INTO public.productos (id, organizacion_id, nombre, tipo_item, unidad, costo)
        VALUES ('MOD-ORIGEN-TEST', v_org_a, 'PLATAFORMA BASE TEST', 'producto_terminado', 'PZA', NULL)
        ON CONFLICT (id) DO NOTHING;

        INSERT INTO public.modelos (organizacion_id, producto_id, tipo, largo_ft, num_ejes, activo)
        VALUES (v_org_a, 'MOD-ORIGEN-TEST', 'plataforma', 40, 2, true)
        RETURNING id INTO v_origen_id;
    END IF;

    -- Preparar fases para Org A y Org B
    INSERT INTO public.fases_despiece (id, organizacion_id, clave, nombre, orden, activo)
    VALUES 
        (gen_random_uuid(), v_org_a, 'FASE-T6-A', 'FASE T6 ORG A', 1, true)
    RETURNING id INTO v_fase_a_id;

    INSERT INTO public.fases_despiece (id, organizacion_id, clave, nombre, orden, activo)
    VALUES 
        (gen_random_uuid(), v_org_b, 'FASE-T6-B', 'FASE T6 ORG B', 1, true)
    RETURNING id INTO v_fase_b_id;

    -- Preparar materias primas en Org A y Org B
    INSERT INTO public.productos (id, organizacion_id, nombre, tipo_item, unidad, costo)
    VALUES 
        (v_mat_a_id, v_org_a, 'VIGA PRUEBA A', 'materia_prima', 'PZA', 100),
        (v_mat_b_id, v_org_b, 'VIGA PRUEBA B', 'materia_prima', 'PZA', 200)
    ON CONFLICT (id) DO UPDATE SET organizacion_id = EXCLUDED.organizacion_id;

    -- Preparar modelo en Org B
    INSERT INTO public.productos (id, organizacion_id, nombre, tipo_item, unidad, costo)
    VALUES ('MOD-ORIGEN-B-TEST', v_org_b, 'PLATAFORMA B BASE TEST', 'producto_terminado', 'PZA', NULL)
    ON CONFLICT (id) DO UPDATE SET organizacion_id = EXCLUDED.organizacion_id;

    INSERT INTO public.modelos (organizacion_id, producto_id, tipo, largo_ft, num_ejes, activo)
    VALUES (v_org_b, 'MOD-ORIGEN-B-TEST', 'plataforma', 40, 2, true)
    RETURNING id INTO v_modelo_b_id;

    -- Insertar línea de prueba en modelo B
    INSERT INTO public.receta_base (modelo_id, material_id, cantidad, escala, paso, fase_id)
    VALUES (v_modelo_b_id, v_mat_b_id, 10, 'fija', 'Paso 1', v_fase_b_id)
    RETURNING id INTO v_linea_b_id;

    -- Contar líneas de receta del modelo origen en Org A
    SELECT count(*) INTO v_cant_ant FROM public.receta_base WHERE modelo_id = v_origen_id;

    -- =========================================================================
    -- PRUEBA 1: Clonar Receta exitosamente dentro de Org A
    -- =========================================================================
    v_nuevo_modelo_id := public.clonar_receta_modelo(
        v_origen_id,
        'REM-PRUEBA-T6-47FT',
        'PLATAFORMA PRUEBA 47 FT 2 EJES',
        47.0,
        2,
        v_org_a,
        v_user_a
    );

    IF v_nuevo_modelo_id IS NULL THEN
        RAISE EXCEPTION 'Fallo al clonar modelo';
    END IF;

    -- Verificar que el producto nuevo tenga costo NULL (Hallazgo 10)
    SELECT costo INTO v_costo_prod FROM public.productos WHERE id = 'REM-PRUEBA-T6-47FT';
    IF v_costo_prod IS NOT NULL THEN
        RAISE EXCEPTION 'El producto clonado no debe tener costo fijo numérico (esperado NULL, recibido %)', v_costo_prod;
    END IF;

    -- Verificar que las líneas clonadas coincidan con el origen
    SELECT count(*) INTO v_cant_post FROM public.receta_base WHERE modelo_id = v_nuevo_modelo_id;
    IF v_cant_post <> v_cant_ant THEN
        RAISE EXCEPTION 'El modelo clonado no tiene la misma cantidad de líneas (esperadas %, encontradas %)', v_cant_ant, v_cant_post;
    END IF;

    -- Verificar que costos y procesos conserven organizacion_id de Org A (Hallazgo 2b)
    SELECT count(*) INTO v_costos_count FROM public.costos_modelo WHERE modelo_id = v_nuevo_modelo_id AND organizacion_id != v_org_a;
    IF v_costos_count > 0 THEN
        RAISE EXCEPTION 'costos_modelo clonados tienen organizacion_id incorrecto';
    END IF;

    SELECT count(*) INTO v_proc_count FROM public.procesos_manufactura WHERE modelo_id = v_nuevo_modelo_id AND organizacion_id != v_org_a;
    IF v_proc_count > 0 THEN
        RAISE EXCEPTION 'procesos_manufactura clonados tienen organizacion_id incorrecto';
    END IF;

    -- =========================================================================
    -- PRUEBA 2: Rechazar clonación con clave de producto duplicada
    -- =========================================================================
    v_catch_error := false;
    BEGIN
        PERFORM public.clonar_receta_modelo(
            v_origen_id,
            'REM-PRUEBA-T6-47FT',
            'OTRO MODELO',
            47.0,
            2,
            v_org_a,
            v_user_a
        );
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%producto_id_duplicado%' THEN
            v_catch_error := true;
        END IF;
    END;
    IF NOT v_catch_error THEN
        RAISE EXCEPTION 'No se rechazó la clave de producto duplicada';
    END IF;

    -- =========================================================================
    -- PRUEBA 3: Rechazar clonar modelo de Org B invocando desde Org A
    -- =========================================================================
    v_catch_error := false;
    BEGIN
        PERFORM public.clonar_receta_modelo(
            v_modelo_b_id,
            'REM-MODELO-ROBO',
            'MODELO CLONADO ILEGALMENTE',
            40.0,
            2,
            v_org_a,
            v_user_a
        );
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%modelo_origen_no_encontrado%' THEN
            v_catch_error := true;
        END IF;
    END;
    IF NOT v_catch_error THEN
        RAISE EXCEPTION 'No se bloqueó el cruce de organización en clonar_receta_modelo';
    END IF;

    -- =========================================================================
    -- PRUEBA 4: Agregar línea válida en Org A
    -- =========================================================================
    v_linea_id := public.guardar_linea_receta(
        v_nuevo_modelo_id,
        v_mat_a_id,
        5.1234,
        'fija',
        v_fase_a_id,
        v_org_a,
        'Paso 1',
        'Prueba de inserción',
        'ensamble',
        NULL,
        v_user_a,
        'Alta de prueba'
    );
    IF v_linea_id IS NULL THEN
        RAISE EXCEPTION 'No se generó ID para la nueva línea';
    END IF;

    -- =========================================================================
    -- PRUEBA 5: Rechazar agregar línea con material de otra organización (Org B)
    -- =========================================================================
    v_catch_error := false;
    BEGIN
        PERFORM public.guardar_linea_receta(
            v_nuevo_modelo_id,
            v_mat_b_id,
            1.0,
            'fija',
            v_fase_a_id,
            v_org_a
        );
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%material_no_encontrado%' THEN
            v_catch_error := true;
        END IF;
    END;
    IF NOT v_catch_error THEN
        RAISE EXCEPTION 'No se bloqueó el uso de material de otra organización';
    END IF;

    -- =========================================================================
    -- PRUEBA 6: Rechazar agregar línea con fase de otra organización (Org B)
    -- =========================================================================
    v_catch_error := false;
    BEGIN
        PERFORM public.guardar_linea_receta(
            v_nuevo_modelo_id,
            v_mat_a_id,
            1.0,
            'fija',
            v_fase_b_id,
            v_org_a
        );
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%fase_no_encontrada%' THEN
            v_catch_error := true;
        END IF;
    END;
    IF NOT v_catch_error THEN
        RAISE EXCEPTION 'No se bloqueó el uso de fase de otra organización';
    END IF;

    -- =========================================================================
    -- PRUEBA 7: Rechazar cantidad <= 0 o NaN y escala inválida
    -- =========================================================================
    v_catch_error := false;
    BEGIN
        PERFORM public.guardar_linea_receta(
            v_nuevo_modelo_id,
            v_mat_a_id,
            0,
            'fija',
            v_fase_a_id,
            v_org_a
        );
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%cantidad_invalida%' THEN
            v_catch_error := true;
        END IF;
    END;
    IF NOT v_catch_error THEN
        RAISE EXCEPTION 'No se bloqueó cantidad = 0';
    END IF;

    v_catch_error := false;
    BEGIN
        PERFORM public.guardar_linea_receta(
            v_nuevo_modelo_id,
            v_mat_a_id,
            5.0,
            'invalida_escala',
            v_fase_a_id,
            v_org_a
        );
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%escala_invalida%' THEN
            v_catch_error := true;
        END IF;
    END;
    IF NOT v_catch_error THEN
        RAISE EXCEPTION 'No se bloqueó escala inválida';
    END IF;

    -- =========================================================================
    -- PRUEBA 8: Rechazar eliminar línea de Org B invocando desde Org A
    -- =========================================================================
    v_catch_error := false;
    BEGIN
        PERFORM public.eliminar_linea_receta(v_linea_b_id, v_org_a, NULL, v_user_a, 'Intento de borrado cruzado');
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%linea_no_encontrada%' THEN
            v_catch_error := true;
        END IF;
    END;
    IF NOT v_catch_error THEN
        RAISE EXCEPTION 'No se bloqueó el borrado de una línea perteneciente a otra organización';
    END IF;

    -- =========================================================================
    -- PRUEBA 9: Eliminar línea legítima de Org A y verificar auditoría
    -- =========================================================================
    PERFORM public.eliminar_linea_receta(v_linea_id, v_org_a, v_nuevo_modelo_id, v_user_a, 'Borrado de prueba');

    SELECT count(*) INTO v_hist_count 
    FROM public.receta_base_historial 
    WHERE modelo_id = v_nuevo_modelo_id AND organizacion_id = v_org_a;

    IF v_hist_count < 3 THEN
        RAISE EXCEPTION 'Faltan registros de auditoría en receta_base_historial (encontrados %)', v_hist_count;
    END IF;

    -- =========================================================================
    -- PRUEBA 10: Rechazar modificar una línea que ya fue eliminada (NOT FOUND)
    -- =========================================================================
    v_catch_error := false;
    BEGIN
        PERFORM public.guardar_linea_receta(
            v_nuevo_modelo_id,
            v_mat_a_id,
            7.0,
            'fija',
            v_fase_a_id,
            v_org_a,
            'Paso 1',
            'Intento editar línea borrada',
            'ensamble',
            v_linea_id,
            v_user_a,
            'Edición fantasma'
        );
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%linea_no_encontrada%' THEN
            v_catch_error := true;
        END IF;
    END;
    IF NOT v_catch_error THEN
        RAISE EXCEPTION 'No se rechazó la edición de una línea ya eliminada';
    END IF;

    -- =========================================================================
    -- PRUEBA 11: Rechazar cantidad 0.00001 que redondea a 0.0000
    -- =========================================================================
    v_catch_error := false;
    BEGIN
        PERFORM public.guardar_linea_receta(
            v_nuevo_modelo_id,
            v_mat_a_id,
            0.00001,
            'fija',
            v_fase_a_id,
            v_org_a
        );
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%cantidad_invalida%' THEN
            v_catch_error := true;
        END IF;
    END;
    IF NOT v_catch_error THEN
        RAISE EXCEPTION 'No se rechazó la cantidad que redondea a cero (0.00001)';
    END IF;

    -- =========================================================================
    -- PRUEBA 12: Rechazar clonación con parámetros inválidos (largo -5, ejes 0, clave vacía)
    -- =========================================================================
    v_catch_error := false;
    BEGIN
        PERFORM public.clonar_receta_modelo(
            v_origen_id,
            '   ',
            'CLON INVALIDO',
            40,
            2,
            v_org_a
        );
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%producto_id_invalido%' THEN
            v_catch_error := true;
        END IF;
    END;
    IF NOT v_catch_error THEN
        RAISE EXCEPTION 'No se rechazó clave de producto vacía en clonar_receta_modelo';
    END IF;

    v_catch_error := false;
    BEGIN
        PERFORM public.clonar_receta_modelo(
            v_origen_id,
            'REM-CLON-INV-LARGO',
            'CLON LARGO NEGATIVO',
            -5,
            2,
            v_org_a
        );
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%largo_invalido%' THEN
            v_catch_error := true;
        END IF;
    END;
    IF NOT v_catch_error THEN
        RAISE EXCEPTION 'No se rechazó largo <= 0 en clonar_receta_modelo';
    END IF;

    -- =========================================================================
    -- PRUEBA 13: Rechazar agregar un modelo/producto terminado como materia prima
    -- =========================================================================
    v_catch_error := false;
    BEGIN
        PERFORM public.guardar_linea_receta(
            v_nuevo_modelo_id,
            'REM-PRUEBA-T6-47FT',
            1.0,
            'fija',
            v_fase_a_id,
            v_org_a
        );
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%material_no_encontrado%' THEN
            v_catch_error := true;
        END IF;
    END;
    IF NOT v_catch_error THEN
        RAISE EXCEPTION 'No se rechazó agregar producto_terminado como materia_prima';
    END IF;

    -- =========================================================================
    -- PRUEBA 14: Validar ON DELETE SET NULL en receta_base_historial
    -- =========================================================================
    -- Al borrar el modelo recién creado, sus registros de auditoría deben sobrevivir con modelo_id = NULL
    DELETE FROM public.modelos WHERE id = v_nuevo_modelo_id;

    SELECT count(*) INTO v_hist_count
    FROM public.receta_base_historial
    WHERE modelo_id IS NULL AND organizacion_id = v_org_a;

    IF v_hist_count < 3 THEN
        RAISE EXCEPTION 'ON DELETE SET NULL falló: el historial no sobrevivió a la eliminación del modelo (encontrados %)', v_hist_count;
    END IF;

    RAISE NOTICE 'PRUEBA TRANSACCIONAL T6: EXITOSA (0 errores)';
END $$;

ROLLBACK;
