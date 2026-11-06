BEGIN;
DO $$
DECLARE
    v_linea_id uuid;
    v_modelo_id uuid;
    v_org_id uuid := '11111111-1111-1111-1111-111111111111';
    v_mat_id text := 'MAT-TEST-CONCURRENCIA';
BEGIN
    SELECT rb.id, rb.modelo_id INTO v_linea_id, v_modelo_id
    FROM public.receta_base rb
    JOIN public.modelos m ON m.id = rb.modelo_id
    WHERE m.producto_id = 'PROD-TEST-CONC'
    LIMIT 1;

    RAISE NOTICE '[SESION A] Actualizando a cantidad=5.0 a las %', clock_timestamp();
    PERFORM public.guardar_linea_receta(
        p_modelo_id := v_modelo_id,
        p_material_id := v_mat_id,
        p_cantidad := 5.0,
        p_escala := 'fija',
        p_fase_id := NULL,
        p_organizacion_id := v_org_id,
        p_usuario_id := NULL,
        p_paso := 'ensamble',
        p_uso := 'Prueba Concurrencia',
        p_seccion := 'acero',
        p_linea_id := v_linea_id
    );
    RAISE NOTICE '[SESION A] Actualizacion ejecutada. Durmiendo 4 segundos...';
    PERFORM pg_sleep(4);
    RAISE NOTICE '[SESION A] Despertando y haciendo COMMIT a las %', clock_timestamp();
END;
$$;
COMMIT;
