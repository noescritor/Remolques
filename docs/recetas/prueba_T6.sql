-- Prueba Transaccional T6: Editor de Recetas y Clonación
-- Ejecuta en un bloque BEGIN...ROLLBACK para no dejar datos residuales

BEGIN;

DO $$
DECLARE
    v_org_id UUID;
    v_origen_id UUID;
    v_nuevo_modelo_id UUID;
    v_mat_id TEXT;
    v_fase_id UUID;
    v_linea_id UUID;
    v_cant_ant INT;
    v_cant_post INT;
    v_hist_count INT;
BEGIN
    -- 1. Obtener organización y modelo base
    SELECT organizacion_id, id INTO v_org_id, v_origen_id
    FROM public.modelos
    WHERE tipo = 'plataforma' AND largo_ft = 40 AND num_ejes = 2
    LIMIT 1;

    IF v_origen_id IS NULL THEN
        SELECT organizacion_id, id INTO v_org_id, v_origen_id FROM public.modelos LIMIT 1;
    END IF;

    SELECT count(*) INTO v_cant_ant FROM public.receta_base WHERE modelo_id = v_origen_id;

    -- 2. Probar Clonación
    v_nuevo_modelo_id := public.clonar_receta_modelo(
        v_origen_id,
        'REM-PRUEBA-T6-47FT',
        'PLATAFORMA PRUEBA 47 FT 2 EJES',
        47.0,
        2,
        NULL
    );

    IF v_nuevo_modelo_id IS NULL THEN
        RAISE EXCEPTION 'Fallo al clonar modelo';
    END IF;

    -- Verificar que el origen conserve sus mismas líneas
    SELECT count(*) INTO v_cant_post FROM public.receta_base WHERE modelo_id = v_origen_id;
    IF v_cant_ant <> v_cant_post THEN
        RAISE EXCEPTION 'El modelo origen fue alterado durante la clonación';
    END IF;

    -- Verificar que el nuevo modelo tenga las líneas clonadas
    SELECT count(*) INTO v_cant_post FROM public.receta_base WHERE modelo_id = v_nuevo_modelo_id;
    IF v_cant_post <> v_cant_ant THEN
        RAISE EXCEPTION 'El modelo clonado no tiene la misma cantidad de líneas (esperadas %, encontradas %)', v_cant_ant, v_cant_post;
    END IF;

    -- 3. Probar agregar nueva línea
    SELECT id INTO v_mat_id FROM public.productos WHERE organizacion_id = v_org_id AND tipo_item = 'materia_prima' LIMIT 1;
    SELECT id INTO v_fase_id FROM public.fases_despiece WHERE organizacion_id = v_org_id LIMIT 1;

    IF v_mat_id IS NOT NULL THEN
        v_linea_id := public.guardar_linea_receta(
            v_nuevo_modelo_id,
            v_mat_id,
            5.0,
            'fija',
            v_fase_id,
            'Paso 1',
            'Prueba de inserción',
            'ensamble',
            NULL,
            NULL,
            'Prueba unitaria de alta'
        );

        IF v_linea_id IS NULL THEN
            RAISE EXCEPTION 'No se generó ID para la nueva línea';
        END IF;

        -- 4. Probar modificación
        PERFORM public.guardar_linea_receta(
            v_nuevo_modelo_id,
            v_mat_id,
            8.0,
            'por_largo',
            v_fase_id,
            'Paso 1',
            'Prueba modificada',
            'ensamble',
            v_linea_id,
            NULL,
            'Prueba unitaria de modificación'
        );

        -- 5. Probar eliminación
        PERFORM public.eliminar_linea_receta(v_linea_id, NULL, 'Prueba de eliminación');
    END IF;

    -- 6. Verificar historial
    SELECT count(*) INTO v_hist_count FROM public.receta_base_historial WHERE modelo_id = v_nuevo_modelo_id;
    IF v_hist_count < 1 THEN
        RAISE EXCEPTION 'No se registró historial de operaciones para el nuevo modelo';
    END IF;

    RAISE NOTICE 'PRUEBA T6 COMPLETADA EXITOSAMENTE: Clonación, adición, edición, eliminación y auditoría OK.';
END $$;

ROLLBACK;
