DO $$
DECLARE
    v_org_id uuid := '11111111-1111-1111-1111-111111111111';
    v_modelo_id uuid;
    v_mat_id text := 'MAT-TEST-CONCURRENCIA';
    v_linea_id uuid;
BEGIN
    INSERT INTO public.organizaciones (id, nombre)
    VALUES (v_org_id, 'ORG TEST CONCURRENCIA')
    ON CONFLICT (id) DO NOTHING;

    INSERT INTO public.productos (id, organizacion_id, nombre, tipo_item, unidad, costo)
    VALUES 
        ('PROD-TEST-CONC', v_org_id, 'EQUIPO CONCURRENCIA', 'producto_terminado', 'PZA', NULL),
        (v_mat_id, v_org_id, 'MATERIAL CONCURRENCIA', 'materia_prima', 'PZA', 100)
    ON CONFLICT (id) DO UPDATE SET organizacion_id = EXCLUDED.organizacion_id;

    SELECT id INTO v_modelo_id FROM public.modelos WHERE producto_id = 'PROD-TEST-CONC' LIMIT 1;
    IF v_modelo_id IS NULL THEN
        INSERT INTO public.modelos (organizacion_id, producto_id, tipo, largo_ft, num_ejes, activo)
        VALUES (v_org_id, 'PROD-TEST-CONC', 'gondola', NULL, 2, true)
        RETURNING id INTO v_modelo_id;
    END IF;

    DELETE FROM public.receta_base_historial WHERE modelo_id = v_modelo_id;
    DELETE FROM public.receta_base WHERE modelo_id = v_modelo_id;

    v_linea_id := public.guardar_linea_receta(
        p_modelo_id := v_modelo_id,
        p_material_id := v_mat_id,
        p_cantidad := 9.0,
        p_escala := 'fija',
        p_fase_id := NULL,
        p_organizacion_id := v_org_id,
        p_usuario_id := NULL,
        p_paso := 'ensamble',
        p_uso := 'Prueba Concurrencia',
        p_seccion := 'acero',
        p_linea_id := NULL
    );

    RAISE NOTICE 'LINEA_PREPARADA: modelo_id=%, linea_id=%, cantidad_inicial=9.0', v_modelo_id, v_linea_id;
END;
$$;
