SELECT 
    h.accion,
    h.datos_anteriores->>'cantidad' AS cant_anterior,
    h.datos_nuevos->>'cantidad' AS cant_nueva,
    h.created_at
FROM public.receta_base_historial h
JOIN public.modelos m ON m.id = h.modelo_id
WHERE m.producto_id = 'PROD-TEST-CONC'
ORDER BY h.created_at ASC;

DO $$
DECLARE
    r1 RECORD;
    r2 RECORD;
    v_count int;
BEGIN
    SELECT count(*) INTO v_count
    FROM public.receta_base_historial h
    JOIN public.modelos m ON m.id = h.modelo_id
    WHERE m.producto_id = 'PROD-TEST-CONC' AND h.accion = 'modificar_linea';

    IF v_count <> 2 THEN
        RAISE EXCEPTION 'Se esperaban 2 modificaciones en historial, encontradas: %', v_count;
    END IF;

    SELECT h.datos_anteriores->>'cantidad' AS c_ant, h.datos_nuevos->>'cantidad' AS c_post
    INTO r1
    FROM public.receta_base_historial h
    JOIN public.modelos m ON m.id = h.modelo_id
    WHERE m.producto_id = 'PROD-TEST-CONC' AND h.accion = 'modificar_linea'
    ORDER BY h.created_at ASC LIMIT 1;

    SELECT h.datos_anteriores->>'cantidad' AS c_ant, h.datos_nuevos->>'cantidad' AS c_post
    INTO r2
    FROM public.receta_base_historial h
    JOIN public.modelos m ON m.id = h.modelo_id
    WHERE m.producto_id = 'PROD-TEST-CONC' AND h.accion = 'modificar_linea'
    ORDER BY h.created_at DESC LIMIT 1;

    IF r1.c_ant::numeric <> 9 OR r1.c_post::numeric <> 5 THEN
        RAISE EXCEPTION 'Transicion 1 incorrecta: esperada 9 -> 5, obtenida % -> %', r1.c_ant, r1.c_post;
    END IF;

    IF r2.c_ant::numeric <> 5 OR r2.c_post::numeric <> 7 THEN
        RAISE EXCEPTION 'Transicion 2 incorrecta (lost update): esperada 5 -> 7, obtenida % -> %', r2.c_ant, r2.c_post;
    END IF;

    RAISE NOTICE '=======================================================';
    RAISE NOTICE 'PRUEBA CONCURRENCIA EXITOSA: Historial encadenado 9 -> 5 y 5 -> 7';
    RAISE NOTICE 'FOR UPDATE OF rb previene sobreescrituras concurrentes.';
    RAISE NOTICE '=======================================================';
END;
$$;
