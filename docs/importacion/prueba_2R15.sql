-- Script de prueba funcional para Sub-bloque 2R-15: Plan semanal de producción
-- Ejecuta un ciclo completo de:
-- 1. Alta de un operario de prueba
-- 2. Creación atómica de una tarea con operarios y materiales vía guardar_plan_tarea
-- 3. Verificación de integridad en plan_tareas, plan_tarea_operarios, plan_tarea_materiales e historial
-- 4. Transición de estado a 'en_proceso' fijando inicio_real vía cambiar_estado_plan_tarea
-- 5. Transición de estado a 'terminada' fijando fin_real
-- 6. Lectura y validación de la línea de tiempo de trazabilidad
-- 7. Eliminación de la tarea preservando bitácora de historial vía eliminar_plan_tarea
-- 8. ROLLBACK al final: el script no deja ningún cambio en la base de datos

BEGIN;

DO $$
DECLARE
    v_org_id UUID;
    v_user_id UUID;
    v_frente_id UUID;
    v_prod_id TEXT;
    v_prod_nombre TEXT;
    v_prod_unidad TEXT;
    v_operario_id UUID;
    v_tarea_id UUID;
    v_res JSONB;
    v_hist_cnt INT;
    v_estado_actual TEXT;
BEGIN
    -- 1. Obtener organización
    SELECT id INTO v_org_id FROM organizaciones ORDER BY id LIMIT 1;
    IF v_org_id IS NULL THEN
        RAISE EXCEPTION 'No se encontró ninguna organización en la base de datos';
    END IF;

    -- Obtener un usuario de la organización (o NULL)
    SELECT usuario_id INTO v_user_id FROM perfiles_organizacion WHERE organizacion_id = v_org_id LIMIT 1;

    -- Obtener un frente de la organización
    SELECT id INTO v_frente_id FROM produccion_frentes WHERE organizacion_id = v_org_id AND activo = true ORDER BY orden LIMIT 1;
    IF v_frente_id IS NULL THEN
        RAISE EXCEPTION 'No se encontró ningún frente activo para la org %', v_org_id;
    END IF;

    -- Obtener un producto de la organización
    SELECT id, nombre, unidad INTO v_prod_id, v_prod_nombre, v_prod_unidad
    FROM productos
    WHERE organizacion_id = v_org_id
    ORDER BY id LIMIT 1;

    IF v_prod_id IS NULL THEN
        -- Si no hay producto, crear uno temporal para la prueba
        v_prod_id := gen_random_uuid()::text;
        v_prod_nombre := 'Material Prueba 2R15';
        v_prod_unidad := 'PZA';
        INSERT INTO productos (id, organizacion_id, nombre, unidad, tipo, tipo_item, costo)
        VALUES (v_prod_id, v_org_id, v_prod_nombre, v_prod_unidad, 'bien', 'materia_prima', 100);
    END IF;

    -- 2. Crear operario de prueba
    INSERT INTO operarios (
        organizacion_id, nombre, puesto, telefono, activo, notas
    ) VALUES (
        v_org_id, 'Operario Prueba 2R-15 Antigravity', 'Soldador', '555-0199', true, 'import-2r15'
    ) RETURNING id INTO v_operario_id;

    RAISE NOTICE 'Operario creado: %', v_operario_id;

    -- 3. Crear tarea atómica con operario y material vía guardar_plan_tarea
    v_res := guardar_plan_tarea(
        v_org_id,
        v_user_id,
        NULL, -- nueva tarea
        CURRENT_DATE,
        v_frente_id,
        NULL, -- sin orden de trabajo específica
        'Labor de prueba: Armado de estructura',
        'Montacargas 1',
        'Observación de prueba 2R15',
        false,
        'planeada',
        ARRAY[v_operario_id],
        jsonb_build_array(
            jsonb_build_object(
                'producto_id', v_prod_id,
                'descripcion', v_prod_nombre,
                'cantidad', 4.5,
                'unidad', v_prod_unidad
            )
        )
    );

    RAISE NOTICE 'Resultado guardar_plan_tarea: %', v_res;

    IF (v_res->>'exito')::boolean <> true THEN
        RAISE EXCEPTION 'Fallo al guardar tarea: %', v_res;
    END IF;

    v_tarea_id := (v_res->>'tarea_id')::uuid;

    -- 4. Validar tablas tras creación
    IF NOT EXISTS (SELECT 1 FROM plan_tareas WHERE id = v_tarea_id AND organizacion_id = v_org_id) THEN
        RAISE EXCEPTION 'La tarea no se encuentra en plan_tareas';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM plan_tarea_operarios WHERE tarea_id = v_tarea_id AND operario_id = v_operario_id) THEN
        RAISE EXCEPTION 'El operario no se asoció a plan_tarea_operarios';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM plan_tarea_materiales WHERE tarea_id = v_tarea_id AND cantidad = 4.5) THEN
        RAISE EXCEPTION 'El material no se insertó en plan_tarea_materiales';
    END IF;

    SELECT count(*) INTO v_hist_cnt FROM plan_tareas_historial WHERE tarea_id = v_tarea_id AND evento = 'creada';
    IF v_hist_cnt <> 1 THEN
        RAISE EXCEPTION 'No se registró el evento creada en el historial (conteo: %)', v_hist_cnt;
    END IF;

    -- 5. Transición a en_proceso
    v_res := cambiar_estado_plan_tarea(
        v_org_id,
        v_user_id,
        v_tarea_id,
        'en_proceso',
        clock_timestamp(),
        NULL
    );

    IF (v_res->>'exito')::boolean <> true THEN
        RAISE EXCEPTION 'Fallo al cambiar estado a en_proceso: %', v_res;
    END IF;

    SELECT estado INTO v_estado_actual FROM plan_tareas WHERE id = v_tarea_id;
    IF v_estado_actual <> 'en_proceso' THEN
        RAISE EXCEPTION 'El estado esperado era en_proceso pero es %', v_estado_actual;
    END IF;

    -- 6. Transición a terminada
    v_res := cambiar_estado_plan_tarea(
        v_org_id,
        v_user_id,
        v_tarea_id,
        'terminada',
        NULL,
        clock_timestamp()
    );

    IF (v_res->>'exito')::boolean <> true THEN
        RAISE EXCEPTION 'Fallo al cambiar estado a terminada: %', v_res;
    END IF;

    SELECT estado INTO v_estado_actual FROM plan_tareas WHERE id = v_tarea_id;
    IF v_estado_actual <> 'terminada' THEN
        RAISE EXCEPTION 'El estado esperado era terminada pero es %', v_estado_actual;
    END IF;

    -- 7. Validar historial de trazabilidad completo
    SELECT count(*) INTO v_hist_cnt FROM plan_tareas_historial WHERE tarea_id = v_tarea_id;
    -- Debe haber al menos 3 eventos: creada, estado (en_proceso), estado (terminada)
    IF v_hist_cnt < 3 THEN
        RAISE EXCEPTION 'Trazabilidad incompleta: esperados >= 3 eventos, encontrados %', v_hist_cnt;
    END IF;

    -- 8. Eliminar tarea preservando bitácora
    v_res := eliminar_plan_tarea(
        v_org_id,
        v_user_id,
        v_tarea_id
    );

    IF (v_res->>'exito')::boolean <> true THEN
        RAISE EXCEPTION 'Fallo al eliminar tarea: %', v_res;
    END IF;

    -- Confirmar que la tarea ya no existe en plan_tareas
    IF EXISTS (SELECT 1 FROM plan_tareas WHERE id = v_tarea_id) THEN
        RAISE EXCEPTION 'La tarea todavía existe en plan_tareas tras eliminar_plan_tarea';
    END IF;

    -- Confirmar que el evento eliminada se guardó en el historial con tarea_id IS NULL
    IF NOT EXISTS (
        SELECT 1 FROM plan_tareas_historial
        WHERE organizacion_id = v_org_id AND evento = 'eliminada' AND (detalle->>'tarea_id_eliminada')::uuid = v_tarea_id
    ) THEN
        RAISE EXCEPTION 'No se encontró el evento eliminada en la bitácora tras el borrado';
    END IF;

    RAISE NOTICE '=======================================================';
    RAISE NOTICE 'PRUEBA 2R-15 EXITOSA: Flujo completo probado con éxito.';
    RAISE NOTICE 'Operario, tarea, materiales, estados y trazabilidad OK.';
    RAISE NOTICE '=======================================================';
END $$;

ROLLBACK;
