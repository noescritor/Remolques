-- Migración 20261013_02_costos_variantes_plataforma.sql
-- Generada automáticamente por scripts/generar_costos_variantes_sql.cjs
-- Sub-bloque 2R-1d: Costos de variantes de plataforma (derivadas de la 40/2)
-- Idempotente, ejecutable en una sola transacción.

BEGIN;

DO $$
DECLARE
    v_org_id uuid := '00000000-0000-0000-0000-000000000001';
    v_origen_id uuid;
    v_origen_count int;
    v_acero_count int;
    v_kits_count int;
    v_proc_count int;
    v_cargador_mat_id text;
    v_cargador_count int;
    v_dest_count int;
    v_destino_id uuid;
    v_destinos_ids uuid[] := ARRAY[]::uuid[];
BEGIN

    -- 1. Validar modelo origen (plataforma 40 ft / 2 ejes)
    SELECT count(*) INTO v_origen_count FROM modelos WHERE tipo = 'plataforma' AND largo_ft = 40 AND num_ejes = 2 AND organizacion_id = v_org_id;
    IF v_origen_count <> 1 THEN
        RAISE EXCEPTION 'Se esperaba exactamente 1 modelo origen plataforma 40 ft / 2 ejes, pero se encontraron %', v_origen_count;
    END IF;
    SELECT id INTO v_origen_id FROM modelos WHERE tipo = 'plataforma' AND largo_ft = 40 AND num_ejes = 2 AND organizacion_id = v_org_id;

    -- 2. Validar que el origen tenga exactamente 61 renglones de receta_base con seccion=acero
    SELECT count(*) INTO v_acero_count FROM receta_base WHERE modelo_id = v_origen_id AND seccion = 'acero';
    IF v_acero_count <> 61 THEN
        RAISE EXCEPTION 'El modelo origen 40/2 no tiene exactamente 61 renglones de acero en receta_base (encontrados: %)', v_acero_count;
    END IF;

    -- 3. Validar material determinista del cargador de 4"
    SELECT id INTO v_cargador_mat_id FROM productos WHERE nombre = 'CARGADOR (IPR DE 4")' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_cargador_mat_id IS NULL THEN
        RAISE EXCEPTION 'Material determinista de cargador no encontrado: CARGADOR (IPR DE 4")';
    END IF;

    SELECT count(*) INTO v_cargador_count FROM receta_base WHERE modelo_id = v_origen_id AND material_id = v_cargador_mat_id AND seccion = 'acero';
    IF v_cargador_count <> 1 THEN
        RAISE EXCEPTION 'Se esperaba exactamente 1 renglón del cargador en receta_base del origen 40/2, pero se encontraron %', v_cargador_count;
    END IF;

    -- 4. Validar que el origen tenga 12 costos_modelo y 80 procesos_manufactura
    SELECT count(*) INTO v_kits_count FROM costos_modelo WHERE modelo_id = v_origen_id;
    IF v_kits_count <> 12 THEN
        RAISE EXCEPTION 'El modelo origen 40/2 debe tener 12 costos_modelo, encontrados %', v_kits_count;
    END IF;

    SELECT count(*) INTO v_proc_count FROM procesos_manufactura WHERE modelo_id = v_origen_id;
    IF v_proc_count <> 80 THEN
        RAISE EXCEPTION 'El modelo origen 40/2 debe tener 80 procesos_manufactura, encontrados %', v_proc_count;
    END IF;

    -- 5. Validar y recolectar IDs de los 8 modelos destino
    SELECT count(*) INTO v_dest_count FROM modelos WHERE tipo = 'plataforma' AND largo_ft = 35 AND num_ejes = 2 AND organizacion_id = v_org_id;
    IF v_dest_count <> 1 THEN
        RAISE EXCEPTION 'Se esperaba exactamente 1 modelo plataforma 35 ft / 2 ejes, pero se encontraron %', v_dest_count;
    END IF;
    SELECT id INTO v_destino_id FROM modelos WHERE tipo = 'plataforma' AND largo_ft = 35 AND num_ejes = 2 AND organizacion_id = v_org_id;
    v_destinos_ids := array_append(v_destinos_ids, v_destino_id);
    SELECT count(*) INTO v_dest_count FROM modelos WHERE tipo = 'plataforma' AND largo_ft = 40 AND num_ejes = 3 AND organizacion_id = v_org_id;
    IF v_dest_count <> 1 THEN
        RAISE EXCEPTION 'Se esperaba exactamente 1 modelo plataforma 40 ft / 3 ejes, pero se encontraron %', v_dest_count;
    END IF;
    SELECT id INTO v_destino_id FROM modelos WHERE tipo = 'plataforma' AND largo_ft = 40 AND num_ejes = 3 AND organizacion_id = v_org_id;
    v_destinos_ids := array_append(v_destinos_ids, v_destino_id);
    SELECT count(*) INTO v_dest_count FROM modelos WHERE tipo = 'plataforma' AND largo_ft = 42 AND num_ejes = 2 AND organizacion_id = v_org_id;
    IF v_dest_count <> 1 THEN
        RAISE EXCEPTION 'Se esperaba exactamente 1 modelo plataforma 42 ft / 2 ejes, pero se encontraron %', v_dest_count;
    END IF;
    SELECT id INTO v_destino_id FROM modelos WHERE tipo = 'plataforma' AND largo_ft = 42 AND num_ejes = 2 AND organizacion_id = v_org_id;
    v_destinos_ids := array_append(v_destinos_ids, v_destino_id);
    SELECT count(*) INTO v_dest_count FROM modelos WHERE tipo = 'plataforma' AND largo_ft = 42 AND num_ejes = 3 AND organizacion_id = v_org_id;
    IF v_dest_count <> 1 THEN
        RAISE EXCEPTION 'Se esperaba exactamente 1 modelo plataforma 42 ft / 3 ejes, pero se encontraron %', v_dest_count;
    END IF;
    SELECT id INTO v_destino_id FROM modelos WHERE tipo = 'plataforma' AND largo_ft = 42 AND num_ejes = 3 AND organizacion_id = v_org_id;
    v_destinos_ids := array_append(v_destinos_ids, v_destino_id);
    SELECT count(*) INTO v_dest_count FROM modelos WHERE tipo = 'plataforma' AND largo_ft = 45 AND num_ejes = 2 AND organizacion_id = v_org_id;
    IF v_dest_count <> 1 THEN
        RAISE EXCEPTION 'Se esperaba exactamente 1 modelo plataforma 45 ft / 2 ejes, pero se encontraron %', v_dest_count;
    END IF;
    SELECT id INTO v_destino_id FROM modelos WHERE tipo = 'plataforma' AND largo_ft = 45 AND num_ejes = 2 AND organizacion_id = v_org_id;
    v_destinos_ids := array_append(v_destinos_ids, v_destino_id);
    SELECT count(*) INTO v_dest_count FROM modelos WHERE tipo = 'plataforma' AND largo_ft = 45 AND num_ejes = 3 AND organizacion_id = v_org_id;
    IF v_dest_count <> 1 THEN
        RAISE EXCEPTION 'Se esperaba exactamente 1 modelo plataforma 45 ft / 3 ejes, pero se encontraron %', v_dest_count;
    END IF;
    SELECT id INTO v_destino_id FROM modelos WHERE tipo = 'plataforma' AND largo_ft = 45 AND num_ejes = 3 AND organizacion_id = v_org_id;
    v_destinos_ids := array_append(v_destinos_ids, v_destino_id);
    SELECT count(*) INTO v_dest_count FROM modelos WHERE tipo = 'plataforma' AND largo_ft = 48 AND num_ejes = 2 AND organizacion_id = v_org_id;
    IF v_dest_count <> 1 THEN
        RAISE EXCEPTION 'Se esperaba exactamente 1 modelo plataforma 48 ft / 2 ejes, pero se encontraron %', v_dest_count;
    END IF;
    SELECT id INTO v_destino_id FROM modelos WHERE tipo = 'plataforma' AND largo_ft = 48 AND num_ejes = 2 AND organizacion_id = v_org_id;
    v_destinos_ids := array_append(v_destinos_ids, v_destino_id);
    SELECT count(*) INTO v_dest_count FROM modelos WHERE tipo = 'plataforma' AND largo_ft = 48 AND num_ejes = 3 AND organizacion_id = v_org_id;
    IF v_dest_count <> 1 THEN
        RAISE EXCEPTION 'Se esperaba exactamente 1 modelo plataforma 48 ft / 3 ejes, pero se encontraron %', v_dest_count;
    END IF;
    SELECT id INTO v_destino_id FROM modelos WHERE tipo = 'plataforma' AND largo_ft = 48 AND num_ejes = 3 AND organizacion_id = v_org_id;
    v_destinos_ids := array_append(v_destinos_ids, v_destino_id);

    -- 6. Limpieza idempotente previa: SOLO notas = 'import-2r1d' para los modelos destino
    DELETE FROM receta_base WHERE notas = 'import-2r1d' AND modelo_id = ANY(v_destinos_ids);
    DELETE FROM costos_modelo WHERE notas = 'import-2r1d' AND modelo_id = ANY(v_destinos_ids);
    DELETE FROM procesos_manufactura WHERE notas = 'import-2r1d' AND modelo_id = ANY(v_destinos_ids);

    -- 7. Copia e inserción para cada modelo destino
    -- Destino: Plataforma 35 ft / 2 ejes (cargadores: 34)
    SELECT id INTO v_destino_id FROM modelos WHERE tipo = 'plataforma' AND largo_ft = 35 AND num_ejes = 2 AND organizacion_id = v_org_id;

    -- 7.1 receta_base acero (61 renglones, cargador con cantidad 34)
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    SELECT
        v_destino_id,
        material_id,
        CASE WHEN material_id = v_cargador_mat_id THEN 34 ELSE cantidad END,
        escala,
        paso,
        uso,
        seccion,
        condicion,
        'import-2r1d'
    FROM receta_base
    WHERE modelo_id = v_origen_id AND seccion = 'acero';

    -- 7.2 costos_modelo (12 renglones)
    INSERT INTO costos_modelo (organizacion_id, modelo_id, seccion, concepto, cantidad, costo_unitario, escala, fuente, notas)
    SELECT
        v_org_id,
        v_destino_id,
        seccion,
        concepto,
        cantidad,
        costo_unitario,
        escala,
        fuente,
        'import-2r1d'
    FROM costos_modelo
    WHERE modelo_id = v_origen_id;

    -- 7.3 procesos_manufactura (80 renglones)
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    SELECT
        v_org_id,
        v_destino_id,
        orden,
        proceso,
        subproceso,
        minutos,
        tarifa_hora,
        'import-2r1d'
    FROM procesos_manufactura
    WHERE modelo_id = v_origen_id;

    -- 7.4 Actualizar modelo con costos_derivados_de
    UPDATE modelos SET costos_derivados_de = v_origen_id WHERE id = v_destino_id;

    -- Destino: Plataforma 40 ft / 3 ejes (cargadores: 38)
    SELECT id INTO v_destino_id FROM modelos WHERE tipo = 'plataforma' AND largo_ft = 40 AND num_ejes = 3 AND organizacion_id = v_org_id;

    -- 7.1 receta_base acero (61 renglones, cargador con cantidad 38)
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    SELECT
        v_destino_id,
        material_id,
        CASE WHEN material_id = v_cargador_mat_id THEN 38 ELSE cantidad END,
        escala,
        paso,
        uso,
        seccion,
        condicion,
        'import-2r1d'
    FROM receta_base
    WHERE modelo_id = v_origen_id AND seccion = 'acero';

    -- 7.2 costos_modelo (12 renglones)
    INSERT INTO costos_modelo (organizacion_id, modelo_id, seccion, concepto, cantidad, costo_unitario, escala, fuente, notas)
    SELECT
        v_org_id,
        v_destino_id,
        seccion,
        concepto,
        cantidad,
        costo_unitario,
        escala,
        fuente,
        'import-2r1d'
    FROM costos_modelo
    WHERE modelo_id = v_origen_id;

    -- 7.3 procesos_manufactura (80 renglones)
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    SELECT
        v_org_id,
        v_destino_id,
        orden,
        proceso,
        subproceso,
        minutos,
        tarifa_hora,
        'import-2r1d'
    FROM procesos_manufactura
    WHERE modelo_id = v_origen_id;

    -- 7.4 Actualizar modelo con costos_derivados_de
    UPDATE modelos SET costos_derivados_de = v_origen_id WHERE id = v_destino_id;

    -- Destino: Plataforma 42 ft / 2 ejes (cargadores: 40)
    SELECT id INTO v_destino_id FROM modelos WHERE tipo = 'plataforma' AND largo_ft = 42 AND num_ejes = 2 AND organizacion_id = v_org_id;

    -- 7.1 receta_base acero (61 renglones, cargador con cantidad 40)
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    SELECT
        v_destino_id,
        material_id,
        CASE WHEN material_id = v_cargador_mat_id THEN 40 ELSE cantidad END,
        escala,
        paso,
        uso,
        seccion,
        condicion,
        'import-2r1d'
    FROM receta_base
    WHERE modelo_id = v_origen_id AND seccion = 'acero';

    -- 7.2 costos_modelo (12 renglones)
    INSERT INTO costos_modelo (organizacion_id, modelo_id, seccion, concepto, cantidad, costo_unitario, escala, fuente, notas)
    SELECT
        v_org_id,
        v_destino_id,
        seccion,
        concepto,
        cantidad,
        costo_unitario,
        escala,
        fuente,
        'import-2r1d'
    FROM costos_modelo
    WHERE modelo_id = v_origen_id;

    -- 7.3 procesos_manufactura (80 renglones)
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    SELECT
        v_org_id,
        v_destino_id,
        orden,
        proceso,
        subproceso,
        minutos,
        tarifa_hora,
        'import-2r1d'
    FROM procesos_manufactura
    WHERE modelo_id = v_origen_id;

    -- 7.4 Actualizar modelo con costos_derivados_de
    UPDATE modelos SET costos_derivados_de = v_origen_id WHERE id = v_destino_id;

    -- Destino: Plataforma 42 ft / 3 ejes (cargadores: 40)
    SELECT id INTO v_destino_id FROM modelos WHERE tipo = 'plataforma' AND largo_ft = 42 AND num_ejes = 3 AND organizacion_id = v_org_id;

    -- 7.1 receta_base acero (61 renglones, cargador con cantidad 40)
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    SELECT
        v_destino_id,
        material_id,
        CASE WHEN material_id = v_cargador_mat_id THEN 40 ELSE cantidad END,
        escala,
        paso,
        uso,
        seccion,
        condicion,
        'import-2r1d'
    FROM receta_base
    WHERE modelo_id = v_origen_id AND seccion = 'acero';

    -- 7.2 costos_modelo (12 renglones)
    INSERT INTO costos_modelo (organizacion_id, modelo_id, seccion, concepto, cantidad, costo_unitario, escala, fuente, notas)
    SELECT
        v_org_id,
        v_destino_id,
        seccion,
        concepto,
        cantidad,
        costo_unitario,
        escala,
        fuente,
        'import-2r1d'
    FROM costos_modelo
    WHERE modelo_id = v_origen_id;

    -- 7.3 procesos_manufactura (80 renglones)
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    SELECT
        v_org_id,
        v_destino_id,
        orden,
        proceso,
        subproceso,
        minutos,
        tarifa_hora,
        'import-2r1d'
    FROM procesos_manufactura
    WHERE modelo_id = v_origen_id;

    -- 7.4 Actualizar modelo con costos_derivados_de
    UPDATE modelos SET costos_derivados_de = v_origen_id WHERE id = v_destino_id;

    -- Destino: Plataforma 45 ft / 2 ejes (cargadores: 43)
    SELECT id INTO v_destino_id FROM modelos WHERE tipo = 'plataforma' AND largo_ft = 45 AND num_ejes = 2 AND organizacion_id = v_org_id;

    -- 7.1 receta_base acero (61 renglones, cargador con cantidad 43)
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    SELECT
        v_destino_id,
        material_id,
        CASE WHEN material_id = v_cargador_mat_id THEN 43 ELSE cantidad END,
        escala,
        paso,
        uso,
        seccion,
        condicion,
        'import-2r1d'
    FROM receta_base
    WHERE modelo_id = v_origen_id AND seccion = 'acero';

    -- 7.2 costos_modelo (12 renglones)
    INSERT INTO costos_modelo (organizacion_id, modelo_id, seccion, concepto, cantidad, costo_unitario, escala, fuente, notas)
    SELECT
        v_org_id,
        v_destino_id,
        seccion,
        concepto,
        cantidad,
        costo_unitario,
        escala,
        fuente,
        'import-2r1d'
    FROM costos_modelo
    WHERE modelo_id = v_origen_id;

    -- 7.3 procesos_manufactura (80 renglones)
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    SELECT
        v_org_id,
        v_destino_id,
        orden,
        proceso,
        subproceso,
        minutos,
        tarifa_hora,
        'import-2r1d'
    FROM procesos_manufactura
    WHERE modelo_id = v_origen_id;

    -- 7.4 Actualizar modelo con costos_derivados_de
    UPDATE modelos SET costos_derivados_de = v_origen_id WHERE id = v_destino_id;

    -- Destino: Plataforma 45 ft / 3 ejes (cargadores: 43)
    SELECT id INTO v_destino_id FROM modelos WHERE tipo = 'plataforma' AND largo_ft = 45 AND num_ejes = 3 AND organizacion_id = v_org_id;

    -- 7.1 receta_base acero (61 renglones, cargador con cantidad 43)
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    SELECT
        v_destino_id,
        material_id,
        CASE WHEN material_id = v_cargador_mat_id THEN 43 ELSE cantidad END,
        escala,
        paso,
        uso,
        seccion,
        condicion,
        'import-2r1d'
    FROM receta_base
    WHERE modelo_id = v_origen_id AND seccion = 'acero';

    -- 7.2 costos_modelo (12 renglones)
    INSERT INTO costos_modelo (organizacion_id, modelo_id, seccion, concepto, cantidad, costo_unitario, escala, fuente, notas)
    SELECT
        v_org_id,
        v_destino_id,
        seccion,
        concepto,
        cantidad,
        costo_unitario,
        escala,
        fuente,
        'import-2r1d'
    FROM costos_modelo
    WHERE modelo_id = v_origen_id;

    -- 7.3 procesos_manufactura (80 renglones)
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    SELECT
        v_org_id,
        v_destino_id,
        orden,
        proceso,
        subproceso,
        minutos,
        tarifa_hora,
        'import-2r1d'
    FROM procesos_manufactura
    WHERE modelo_id = v_origen_id;

    -- 7.4 Actualizar modelo con costos_derivados_de
    UPDATE modelos SET costos_derivados_de = v_origen_id WHERE id = v_destino_id;

    -- Destino: Plataforma 48 ft / 2 ejes (cargadores: 46)
    SELECT id INTO v_destino_id FROM modelos WHERE tipo = 'plataforma' AND largo_ft = 48 AND num_ejes = 2 AND organizacion_id = v_org_id;

    -- 7.1 receta_base acero (61 renglones, cargador con cantidad 46)
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    SELECT
        v_destino_id,
        material_id,
        CASE WHEN material_id = v_cargador_mat_id THEN 46 ELSE cantidad END,
        escala,
        paso,
        uso,
        seccion,
        condicion,
        'import-2r1d'
    FROM receta_base
    WHERE modelo_id = v_origen_id AND seccion = 'acero';

    -- 7.2 costos_modelo (12 renglones)
    INSERT INTO costos_modelo (organizacion_id, modelo_id, seccion, concepto, cantidad, costo_unitario, escala, fuente, notas)
    SELECT
        v_org_id,
        v_destino_id,
        seccion,
        concepto,
        cantidad,
        costo_unitario,
        escala,
        fuente,
        'import-2r1d'
    FROM costos_modelo
    WHERE modelo_id = v_origen_id;

    -- 7.3 procesos_manufactura (80 renglones)
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    SELECT
        v_org_id,
        v_destino_id,
        orden,
        proceso,
        subproceso,
        minutos,
        tarifa_hora,
        'import-2r1d'
    FROM procesos_manufactura
    WHERE modelo_id = v_origen_id;

    -- 7.4 Actualizar modelo con costos_derivados_de
    UPDATE modelos SET costos_derivados_de = v_origen_id WHERE id = v_destino_id;

    -- Destino: Plataforma 48 ft / 3 ejes (cargadores: 46)
    SELECT id INTO v_destino_id FROM modelos WHERE tipo = 'plataforma' AND largo_ft = 48 AND num_ejes = 3 AND organizacion_id = v_org_id;

    -- 7.1 receta_base acero (61 renglones, cargador con cantidad 46)
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    SELECT
        v_destino_id,
        material_id,
        CASE WHEN material_id = v_cargador_mat_id THEN 46 ELSE cantidad END,
        escala,
        paso,
        uso,
        seccion,
        condicion,
        'import-2r1d'
    FROM receta_base
    WHERE modelo_id = v_origen_id AND seccion = 'acero';

    -- 7.2 costos_modelo (12 renglones)
    INSERT INTO costos_modelo (organizacion_id, modelo_id, seccion, concepto, cantidad, costo_unitario, escala, fuente, notas)
    SELECT
        v_org_id,
        v_destino_id,
        seccion,
        concepto,
        cantidad,
        costo_unitario,
        escala,
        fuente,
        'import-2r1d'
    FROM costos_modelo
    WHERE modelo_id = v_origen_id;

    -- 7.3 procesos_manufactura (80 renglones)
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    SELECT
        v_org_id,
        v_destino_id,
        orden,
        proceso,
        subproceso,
        minutos,
        tarifa_hora,
        'import-2r1d'
    FROM procesos_manufactura
    WHERE modelo_id = v_origen_id;

    -- 7.4 Actualizar modelo con costos_derivados_de
    UPDATE modelos SET costos_derivados_de = v_origen_id WHERE id = v_destino_id;

END $$;

COMMIT;
