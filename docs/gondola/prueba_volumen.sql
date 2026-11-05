-- Prueba Funcional: Cálculo de cantidades escaladas por volumen para Góndola
-- Ejecutar en SQL Editor de Supabase. Todo se revierte al final (ROLLBACK).

BEGIN;

DO $$
DECLARE
    v_model_2e_id uuid;
    v_cant_alma_base numeric;
    v_cant_alma_30 numeric;
    v_cant_puente_base numeric;
    v_cant_puente_30 numeric;
BEGIN
    -- 1. Obtener modelo góndola 2 ejes
    SELECT id INTO v_model_2e_id FROM modelos WHERE tipo = 'gondola' AND num_ejes = 2 LIMIT 1;
    IF v_model_2e_id IS NULL THEN
        RAISE EXCEPTION 'Modelo góndola 2 ejes no encontrado';
    END IF;

    -- 2. Verificar renglón de tina (Alma, por_volumen)
    SELECT cantidad INTO v_cant_alma_base
    FROM receta_base
    WHERE modelo_id = v_model_2e_id AND uso = 'Alma' AND escala = 'por_volumen'
    LIMIT 1;

    IF v_cant_alma_base IS NULL THEN
        RAISE EXCEPTION 'Renglón Alma con escala por_volumen no encontrado';
    END IF;

    -- Escalar a 30 m³: factor = 30 / 45 = 2/3
    v_cant_alma_30 := round(v_cant_alma_base * (30.0 / 45.0), 4);
    IF v_cant_alma_30 <> round(2.0 * (30.0 / 45.0), 4) THEN
        RAISE EXCEPTION 'Cálculo de Alma a 30 m³ incorrecto: esperado %, obtenido %', round(2.0 * (30.0 / 45.0), 4), v_cant_alma_30;
    END IF;

    -- 3. Verificar renglón de chasis (Puentes de suspensión, fija)
    SELECT cantidad INTO v_cant_puente_base
    FROM receta_base
    WHERE modelo_id = v_model_2e_id AND uso = 'Puentes de suspensión' AND escala = 'fija'
    LIMIT 1;

    IF v_cant_puente_base IS NULL THEN
        RAISE EXCEPTION 'Renglón Puentes de suspensión con escala fija no encontrado';
    END IF;

    -- En escala fija a 30 m³ la cantidad permanece idéntica a la base
    v_cant_puente_30 := v_cant_puente_base;
    IF v_cant_puente_30 <> 9 THEN
        RAISE EXCEPTION 'Cantidad fija alterada para puentes de suspensión: %', v_cant_puente_30;
    END IF;

    -- 4. Verificar opcion_costos para tina_material (a36 y hardox_450 con por_volumen)
    DECLARE
        v_costo_a36_base numeric;
        v_costo_a36_30 numeric;
        v_costo_hardox_base numeric;
        v_costo_hardox_30 numeric;
        v_escala_a36 text;
        v_escala_hardox text;
    BEGIN
        SELECT oc.costo_unitario, oc.escala INTO v_costo_a36_base, v_escala_a36
        FROM opcion_costos oc
        JOIN opciones_configuracion o ON oc.opcion_id = o.id
        JOIN grupos_configuracion g ON o.grupo_id = g.id
        WHERE oc.tipo_modelo = 'gondola' AND g.clave = 'tina_material' AND o.clave = 'a36'
        LIMIT 1;

        IF v_escala_a36 <> 'por_volumen' THEN
            RAISE EXCEPTION 'opcion_costos para tina a36 debe ser por_volumen, encontrado: %', v_escala_a36;
        END IF;

        v_costo_a36_30 := round(v_costo_a36_base * (30.0 / 45.0), 2);
        IF v_costo_a36_30 <> 111670.51 THEN
            RAISE EXCEPTION 'Costo escalado de tina A-36 incorrecto: esperado 111670.51, obtenido %', v_costo_a36_30;
        END IF;

        SELECT oc.costo_unitario, oc.escala INTO v_costo_hardox_base, v_escala_hardox
        FROM opcion_costos oc
        JOIN opciones_configuracion o ON oc.opcion_id = o.id
        JOIN grupos_configuracion g ON o.grupo_id = g.id
        WHERE oc.tipo_modelo = 'gondola' AND g.clave = 'tina_material' AND o.clave = 'hardox_450'
        LIMIT 1;

        IF v_escala_hardox <> 'por_volumen' THEN
            RAISE EXCEPTION 'opcion_costos para tina hardox_450 debe ser por_volumen, encontrado: %', v_escala_hardox;
        END IF;

        v_costo_hardox_30 := round(v_costo_hardox_base * (30.0 / 45.0), 2);
        IF v_costo_hardox_30 <> 191165.61 THEN
            RAISE EXCEPTION 'Costo escalado de tina Hardox incorrecto: esperado 191165.61, obtenido %', v_costo_hardox_30;
        END IF;

        RAISE NOTICE 'PRUEBA EXITOSA OPCION_COSTOS: Tina A-36 escala a % (de %), Tina Hardox escala a % (de %).',
            v_costo_a36_30, v_costo_a36_base, v_costo_hardox_30, v_costo_hardox_base;
    END;

    RAISE NOTICE 'PRUEBA EXITOSA: Alma escala a % pz (de % pz base). Puentes suspensión se mantienen en % pz.',
        v_cant_alma_30, v_cant_alma_base, v_cant_puente_30;
END;
$$;

ROLLBACK;
