-- Sub-bloque 2R-1g: Costos de respaldo para opciones no cubiertas por Factura
-- Generado automáticamente por scripts/generar_costos_respaldo_sql.cjs
-- Idempotente, ejecutable en una sola transacción.

BEGIN;

DO $$
DECLARE
    v_org_id uuid := '00000000-0000-0000-0000-000000000001';
    v_opt_id uuid;
    v_pv numeric;
BEGIN

    -- 1. Borrado idempotente previo de import-2r1g únicamente
    DELETE FROM opcion_costos WHERE notas = 'import-2r1g';

    -- 2. Inserción con resolución y guardia de coherencia

    -- Opción: piso / pino (Factura Leolca, costo: 22000)
    SELECT oc.id, oc.precio_venta INTO v_opt_id, v_pv
    FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'piso' AND oc.clave = 'pino' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'piso', 'pino'; END IF;
    IF v_pv IS DISTINCT FROM 22000 THEN
        RAISE EXCEPTION 'Guardia de coherencia falló en % / %: precio_venta en catálogo es %, pero se esperaba %', 'piso', 'pino', v_pv, 22000;
    END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'plataforma', 1, 'por_largo', 22000, 'Factura Leolca', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'plataforma'
    );

    -- Opción: piso / encino (Factura Leolca, costo: 22000)
    SELECT oc.id, oc.precio_venta INTO v_opt_id, v_pv
    FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'piso' AND oc.clave = 'encino' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'piso', 'encino'; END IF;
    IF v_pv IS DISTINCT FROM 22000 THEN
        RAISE EXCEPTION 'Guardia de coherencia falló en % / %: precio_venta en catálogo es %, pero se esperaba %', 'piso', 'encino', v_pv, 22000;
    END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'plataforma', 1, 'por_largo', 22000, 'Factura Leolca', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'plataforma'
    );

    -- Opción: piso / plastico_cafe (Factura Leolca, costo: 35000)
    SELECT oc.id, oc.precio_venta INTO v_opt_id, v_pv
    FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'piso' AND oc.clave = 'plastico_cafe' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'piso', 'plastico_cafe'; END IF;
    IF v_pv IS DISTINCT FROM 35000 THEN
        RAISE EXCEPTION 'Guardia de coherencia falló en % / %: precio_venta en catálogo es %, pero se esperaba %', 'piso', 'plastico_cafe', v_pv, 35000;
    END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'plataforma', 1, 'por_largo', 35000, 'Factura Leolca', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'plataforma'
    );

    -- Opción: riel / con_riel (Factura Leolca, costo: 5808)
    SELECT oc.id, oc.precio_venta INTO v_opt_id, v_pv
    FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'riel' AND oc.clave = 'con_riel' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'riel', 'con_riel'; END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'plataforma', 1, 'fija', 5808, 'Factura Leolca', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'plataforma'
    );

    -- Opción: matracas / corrediza (Factura Leolca, costo: 307.4)
    SELECT oc.id, oc.precio_venta INTO v_opt_id, v_pv
    FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'matracas' AND oc.clave = 'corrediza' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'matracas', 'corrediza'; END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'plataforma', 12, 'fija', 307.4, 'Factura Leolca', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'plataforma'
    );

    -- Opción: adicionales / polinera_grande (Factura Leolca, costo: 6000)
    SELECT oc.id, oc.precio_venta INTO v_opt_id, v_pv
    FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'adicionales' AND oc.clave = 'polinera_grande' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'adicionales', 'polinera_grande'; END IF;
    IF v_pv IS DISTINCT FROM 6000 THEN
        RAISE EXCEPTION 'Guardia de coherencia falló en % / %: precio_venta en catálogo es %, pero se esperaba %', 'adicionales', 'polinera_grande', v_pv, 6000;
    END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'plataforma', 1, 'fija', 6000, 'Factura Leolca', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'plataforma'
    );
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'dolly', 1, 'fija', 6000, 'Factura Leolca', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'dolly'
    );
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'gondola', 1, 'fija', 6000, 'Factura Leolca', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'gondola'
    );

    -- Opción: adicionales / bicicletera (Factura Leolca, costo: 2004)
    SELECT oc.id, oc.precio_venta INTO v_opt_id, v_pv
    FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'adicionales' AND oc.clave = 'bicicletera' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'adicionales', 'bicicletera'; END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'plataforma', 1, 'fija', 2004, 'Factura Leolca', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'plataforma'
    );
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'dolly', 1, 'fija', 2004, 'Factura Leolca', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'dolly'
    );
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'gondola', 1, 'fija', 2004, 'Factura Leolca', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'gondola'
    );

    -- Opción: adicionales / canastilla (Factura Leolca, costo: 5784.5)
    SELECT oc.id, oc.precio_venta INTO v_opt_id, v_pv
    FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'adicionales' AND oc.clave = 'canastilla' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'adicionales', 'canastilla'; END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'plataforma', 1, 'fija', 5784.5, 'Factura Leolca', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'plataforma'
    );
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'dolly', 1, 'fija', 5784.5, 'Factura Leolca', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'dolly'
    );
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'gondola', 1, 'fija', 5784.5, 'Factura Leolca', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'gondola'
    );

    -- Opción: suspension / hj_alta (Tarifario, costo: 24550)
    SELECT oc.id, oc.precio_venta INTO v_opt_id, v_pv
    FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'suspension' AND oc.clave = 'hj_alta' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'suspension', 'hj_alta'; END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'plataforma', 1, 'por_eje', 24550, 'Tarifario', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'plataforma'
    );
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'dolly', 1, 'por_eje', 24550, 'Tarifario', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'dolly'
    );
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'gondola', 1, 'por_eje', 24550, 'Tarifario', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'gondola'
    );

    -- Opción: piso / plastico_negro (Tarifario, costo: 36182.72)
    SELECT oc.id, oc.precio_venta INTO v_opt_id, v_pv
    FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'piso' AND oc.clave = 'plastico_negro' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'piso', 'plastico_negro'; END IF;
    IF v_pv IS DISTINCT FROM 36182.72 THEN
        RAISE EXCEPTION 'Guardia de coherencia falló en % / %: precio_venta en catálogo es %, pero se esperaba %', 'piso', 'plastico_negro', v_pv, 36182.72;
    END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'plataforma', 1, 'por_largo', 36182.72, 'Tarifario', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'plataforma'
    );

    -- Opción: piso / laminado (Tarifario, costo: 28224)
    SELECT oc.id, oc.precio_venta INTO v_opt_id, v_pv
    FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'piso' AND oc.clave = 'laminado' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'piso', 'laminado'; END IF;
    IF v_pv IS DISTINCT FROM 28224 THEN
        RAISE EXCEPTION 'Guardia de coherencia falló en % / %: precio_venta en catálogo es %, pero se esperaba %', 'piso', 'laminado', v_pv, 28224;
    END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'plataforma', 1, 'por_largo', 28224, 'Tarifario', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'plataforma'
    );

    -- Opción: piso / antiderrapante (Tarifario, costo: 22000)
    SELECT oc.id, oc.precio_venta INTO v_opt_id, v_pv
    FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'piso' AND oc.clave = 'antiderrapante' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'piso', 'antiderrapante'; END IF;
    IF v_pv IS DISTINCT FROM 22000 THEN
        RAISE EXCEPTION 'Guardia de coherencia falló en % / %: precio_venta en catálogo es %, pero se esperaba %', 'piso', 'antiderrapante', v_pv, 22000;
    END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'plataforma', 1, 'por_largo', 22000, 'Tarifario', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'plataforma'
    );

    -- Opción: redilas / 70 (Tarifario, costo: 35000)
    SELECT oc.id, oc.precio_venta INTO v_opt_id, v_pv
    FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'redilas' AND oc.clave = '70' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'redilas', '70'; END IF;
    IF v_pv IS DISTINCT FROM 35000 THEN
        RAISE EXCEPTION 'Guardia de coherencia falló en % / %: precio_venta en catálogo es %, pero se esperaba %', 'redilas', '70', v_pv, 35000;
    END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'plataforma', 1, 'fija', 35000, 'Tarifario', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'plataforma'
    );

    -- Opción: redilas / 75 (Tarifario, costo: 35500)
    SELECT oc.id, oc.precio_venta INTO v_opt_id, v_pv
    FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'redilas' AND oc.clave = '75' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'redilas', '75'; END IF;
    IF v_pv IS DISTINCT FROM 35500 THEN
        RAISE EXCEPTION 'Guardia de coherencia falló en % / %: precio_venta en catálogo es %, pero se esperaba %', 'redilas', '75', v_pv, 35500;
    END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'plataforma', 1, 'fija', 35500, 'Tarifario', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'plataforma'
    );

    -- Opción: redilas / 80 (Tarifario, costo: 36000)
    SELECT oc.id, oc.precio_venta INTO v_opt_id, v_pv
    FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'redilas' AND oc.clave = '80' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'redilas', '80'; END IF;
    IF v_pv IS DISTINCT FROM 36000 THEN
        RAISE EXCEPTION 'Guardia de coherencia falló en % / %: precio_venta en catálogo es %, pero se esperaba %', 'redilas', '80', v_pv, 36000;
    END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'plataforma', 1, 'fija', 36000, 'Tarifario', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'plataforma'
    );

    -- Opción: redilas / 100 (Tarifario, costo: 42000)
    SELECT oc.id, oc.precio_venta INTO v_opt_id, v_pv
    FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'redilas' AND oc.clave = '100' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'redilas', '100'; END IF;
    IF v_pv IS DISTINCT FROM 42000 THEN
        RAISE EXCEPTION 'Guardia de coherencia falló en % / %: precio_venta en catálogo es %, pero se esperaba %', 'redilas', '100', v_pv, 42000;
    END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'plataforma', 1, 'fija', 42000, 'Tarifario', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'plataforma'
    );

    -- Opción: retractil / chico (Tarifario, costo: 15000)
    SELECT oc.id, oc.precio_venta INTO v_opt_id, v_pv
    FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'retractil' AND oc.clave = 'chico' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'retractil', 'chico'; END IF;
    IF v_pv IS DISTINCT FROM 15000 THEN
        RAISE EXCEPTION 'Guardia de coherencia falló en % / %: precio_venta en catálogo es %, pero se esperaba %', 'retractil', 'chico', v_pv, 15000;
    END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'plataforma', 1, 'fija', 15000, 'Tarifario', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'plataforma'
    );

    -- Opción: retractil / grande (Tarifario, costo: 15000)
    SELECT oc.id, oc.precio_venta INTO v_opt_id, v_pv
    FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'retractil' AND oc.clave = 'grande' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'retractil', 'grande'; END IF;
    IF v_pv IS DISTINCT FROM 15000 THEN
        RAISE EXCEPTION 'Guardia de coherencia falló en % / %: precio_venta en catálogo es %, pero se esperaba %', 'retractil', 'grande', v_pv, 15000;
    END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'plataforma', 1, 'fija', 15000, 'Tarifario', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'plataforma'
    );

    -- Opción: plafones / ambar_laterales (Tarifario, costo: 168.2)
    SELECT oc.id, oc.precio_venta INTO v_opt_id, v_pv
    FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'plafones' AND oc.clave = 'ambar_laterales' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'plafones', 'ambar_laterales'; END IF;
    IF v_pv IS DISTINCT FROM 168.2 THEN
        RAISE EXCEPTION 'Guardia de coherencia falló en % / %: precio_venta en catálogo es %, pero se esperaba %', 'plafones', 'ambar_laterales', v_pv, 168.2;
    END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'plataforma', 1, 'fija', 168.2, 'Tarifario', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'plataforma'
    );

    -- Opción: plafones / ambar_estribo (Tarifario, costo: 168.2)
    SELECT oc.id, oc.precio_venta INTO v_opt_id, v_pv
    FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'plafones' AND oc.clave = 'ambar_estribo' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'plafones', 'ambar_estribo'; END IF;
    IF v_pv IS DISTINCT FROM 168.2 THEN
        RAISE EXCEPTION 'Guardia de coherencia falló en % / %: precio_venta en catálogo es %, pero se esperaba %', 'plafones', 'ambar_estribo', v_pv, 168.2;
    END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'plataforma', 1, 'fija', 168.2, 'Tarifario', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'plataforma'
    );

    -- Opción: plafones / rojo_laterales (Tarifario, costo: 168.2)
    SELECT oc.id, oc.precio_venta INTO v_opt_id, v_pv
    FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'plafones' AND oc.clave = 'rojo_laterales' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'plafones', 'rojo_laterales'; END IF;
    IF v_pv IS DISTINCT FROM 168.2 THEN
        RAISE EXCEPTION 'Guardia de coherencia falló en % / %: precio_venta en catálogo es %, pero se esperaba %', 'plafones', 'rojo_laterales', v_pv, 168.2;
    END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'plataforma', 1, 'fija', 168.2, 'Tarifario', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'plataforma'
    );

    -- Opción: plafones / rojo_estribo (Tarifario, costo: 168.2)
    SELECT oc.id, oc.precio_venta INTO v_opt_id, v_pv
    FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'plafones' AND oc.clave = 'rojo_estribo' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'plafones', 'rojo_estribo'; END IF;
    IF v_pv IS DISTINCT FROM 168.2 THEN
        RAISE EXCEPTION 'Guardia de coherencia falló en % / %: precio_venta en catálogo es %, pero se esperaba %', 'plafones', 'rojo_estribo', v_pv, 168.2;
    END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'plataforma', 1, 'fija', 168.2, 'Tarifario', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'plataforma'
    );

    -- Opción: llantas / bf_goodrich (Tarifario, costo: 11750)
    SELECT oc.id, oc.precio_venta INTO v_opt_id, v_pv
    FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'llantas' AND oc.clave = 'bf_goodrich' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'llantas', 'bf_goodrich'; END IF;
    IF v_pv IS DISTINCT FROM 11750 THEN
        RAISE EXCEPTION 'Guardia de coherencia falló en % / %: precio_venta en catálogo es %, pero se esperaba %', 'llantas', 'bf_goodrich', v_pv, 11750;
    END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'plataforma', 4, 'por_eje', 11750, 'Tarifario', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'plataforma'
    );
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'dolly', 4, 'por_eje', 11750, 'Tarifario', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'dolly'
    );
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'gondola', 4, 'por_eje', 11750, 'Tarifario', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'gondola'
    );

    -- Opción: llantas / cerex (Tarifario, costo: 3586)
    SELECT oc.id, oc.precio_venta INTO v_opt_id, v_pv
    FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'llantas' AND oc.clave = 'cerex' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'llantas', 'cerex'; END IF;
    IF v_pv IS DISTINCT FROM 3586 THEN
        RAISE EXCEPTION 'Guardia de coherencia falló en % / %: precio_venta en catálogo es %, pero se esperaba %', 'llantas', 'cerex', v_pv, 3586;
    END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'plataforma', 4, 'por_eje', 3586, 'Tarifario', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'plataforma'
    );
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'dolly', 4, 'por_eje', 3586, 'Tarifario', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'dolly'
    );
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'gondola', 4, 'por_eje', 3586, 'Tarifario', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'gondola'
    );

    -- Opción: llantas / eudemon (Tarifario, costo: 5400)
    SELECT oc.id, oc.precio_venta INTO v_opt_id, v_pv
    FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'llantas' AND oc.clave = 'eudemon' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'llantas', 'eudemon'; END IF;
    IF v_pv IS DISTINCT FROM 5400 THEN
        RAISE EXCEPTION 'Guardia de coherencia falló en % / %: precio_venta en catálogo es %, pero se esperaba %', 'llantas', 'eudemon', v_pv, 5400;
    END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'plataforma', 4, 'por_eje', 5400, 'Tarifario', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'plataforma'
    );
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'dolly', 4, 'por_eje', 5400, 'Tarifario', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'dolly'
    );
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'gondola', 4, 'por_eje', 5400, 'Tarifario', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'gondola'
    );

    -- Opción: llantas / royal_black (Tarifario, costo: 5600)
    SELECT oc.id, oc.precio_venta INTO v_opt_id, v_pv
    FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'llantas' AND oc.clave = 'royal_black' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'llantas', 'royal_black'; END IF;
    IF v_pv IS DISTINCT FROM 5600 THEN
        RAISE EXCEPTION 'Guardia de coherencia falló en % / %: precio_venta en catálogo es %, pero se esperaba %', 'llantas', 'royal_black', v_pv, 5600;
    END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'plataforma', 4, 'por_eje', 5600, 'Tarifario', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'plataforma'
    );
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'dolly', 4, 'por_eje', 5600, 'Tarifario', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'dolly'
    );
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'gondola', 4, 'por_eje', 5600, 'Tarifario', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'gondola'
    );

    -- Opción: llantas / valiant (Tarifario, costo: 3581)
    SELECT oc.id, oc.precio_venta INTO v_opt_id, v_pv
    FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'llantas' AND oc.clave = 'valiant' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'llantas', 'valiant'; END IF;
    IF v_pv IS DISTINCT FROM 3581 THEN
        RAISE EXCEPTION 'Guardia de coherencia falló en % / %: precio_venta en catálogo es %, pero se esperaba %', 'llantas', 'valiant', v_pv, 3581;
    END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'plataforma', 4, 'por_eje', 3581, 'Tarifario', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'plataforma'
    );
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'dolly', 4, 'por_eje', 3581, 'Tarifario', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'dolly'
    );
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'gondola', 4, 'por_eje', 3581, 'Tarifario', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'gondola'
    );

    -- Opción: adicionales / barrenado_chasis (Tarifario, costo: 1250)
    SELECT oc.id, oc.precio_venta INTO v_opt_id, v_pv
    FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'adicionales' AND oc.clave = 'barrenado_chasis' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'adicionales', 'barrenado_chasis'; END IF;
    IF v_pv IS DISTINCT FROM 1250 THEN
        RAISE EXCEPTION 'Guardia de coherencia falló en % / %: precio_venta en catálogo es %, pero se esperaba %', 'adicionales', 'barrenado_chasis', v_pv, 1250;
    END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'plataforma', 1, 'fija', 1250, 'Tarifario', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'plataforma'
    );
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'dolly', 1, 'fija', 1250, 'Tarifario', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'dolly'
    );
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'gondola', 1, 'fija', 1250, 'Tarifario', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'gondola'
    );

    -- Opción: adicionales / caja_auxiliar (Tarifario, costo: 1500)
    SELECT oc.id, oc.precio_venta INTO v_opt_id, v_pv
    FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'adicionales' AND oc.clave = 'caja_auxiliar' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'adicionales', 'caja_auxiliar'; END IF;
    IF v_pv IS DISTINCT FROM 1500 THEN
        RAISE EXCEPTION 'Guardia de coherencia falló en % / %: precio_venta en catálogo es %, pero se esperaba %', 'adicionales', 'caja_auxiliar', v_pv, 1500;
    END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'plataforma', 1, 'fija', 1500, 'Tarifario', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'plataforma'
    );
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'dolly', 1, 'fija', 1500, 'Tarifario', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'dolly'
    );
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'gondola', 1, 'fija', 1500, 'Tarifario', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'gondola'
    );

    -- Opción: adicionales / caja_herr_chica (Tarifario, costo: 9500)
    SELECT oc.id, oc.precio_venta INTO v_opt_id, v_pv
    FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'adicionales' AND oc.clave = 'caja_herr_chica' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'adicionales', 'caja_herr_chica'; END IF;
    IF v_pv IS DISTINCT FROM 9500 THEN
        RAISE EXCEPTION 'Guardia de coherencia falló en % / %: precio_venta en catálogo es %, pero se esperaba %', 'adicionales', 'caja_herr_chica', v_pv, 9500;
    END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'plataforma', 1, 'fija', 9500, 'Tarifario', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'plataforma'
    );
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'dolly', 1, 'fija', 9500, 'Tarifario', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'dolly'
    );
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'gondola', 1, 'fija', 9500, 'Tarifario', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'gondola'
    );

    -- Opción: adicionales / candados (Tarifario, costo: 1450)
    SELECT oc.id, oc.precio_venta INTO v_opt_id, v_pv
    FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'adicionales' AND oc.clave = 'candados' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'adicionales', 'candados'; END IF;
    IF v_pv IS DISTINCT FROM 1450 THEN
        RAISE EXCEPTION 'Guardia de coherencia falló en % / %: precio_venta en catálogo es %, pero se esperaba %', 'adicionales', 'candados', v_pv, 1450;
    END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'plataforma', 1, 'fija', 1450, 'Tarifario', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'plataforma'
    );
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'dolly', 1, 'fija', 1450, 'Tarifario', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'dolly'
    );
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'gondola', 1, 'fija', 1450, 'Tarifario', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'gondola'
    );

    -- Opción: adicionales / jalon (Tarifario, costo: 3768)
    SELECT oc.id, oc.precio_venta INTO v_opt_id, v_pv
    FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'adicionales' AND oc.clave = 'jalon' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'adicionales', 'jalon'; END IF;
    IF v_pv IS DISTINCT FROM 3768 THEN
        RAISE EXCEPTION 'Guardia de coherencia falló en % / %: precio_venta en catálogo es %, pero se esperaba %', 'adicionales', 'jalon', v_pv, 3768;
    END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'plataforma', 1, 'fija', 3768, 'Tarifario', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'plataforma'
    );
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'dolly', 1, 'fija', 3768, 'Tarifario', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'dolly'
    );
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'gondola', 1, 'fija', 3768, 'Tarifario', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'gondola'
    );

    -- Opción: adicionales / lodera_centro (Tarifario, costo: 874)
    SELECT oc.id, oc.precio_venta INTO v_opt_id, v_pv
    FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'adicionales' AND oc.clave = 'lodera_centro' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'adicionales', 'lodera_centro'; END IF;
    IF v_pv IS DISTINCT FROM 874 THEN
        RAISE EXCEPTION 'Guardia de coherencia falló en % / %: precio_venta en catálogo es %, pero se esperaba %', 'adicionales', 'lodera_centro', v_pv, 874;
    END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'plataforma', 1, 'fija', 874, 'Tarifario', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'plataforma'
    );
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'dolly', 1, 'fija', 874, 'Tarifario', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'dolly'
    );
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'gondola', 1, 'fija', 874, 'Tarifario', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'gondola'
    );

    -- Opción: adicionales / multimodal (Tarifario, costo: 50000)
    SELECT oc.id, oc.precio_venta INTO v_opt_id, v_pv
    FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'adicionales' AND oc.clave = 'multimodal' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'adicionales', 'multimodal'; END IF;
    IF v_pv IS DISTINCT FROM 50000 THEN
        RAISE EXCEPTION 'Guardia de coherencia falló en % / %: precio_venta en catálogo es %, pero se esperaba %', 'adicionales', 'multimodal', v_pv, 50000;
    END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'plataforma', 1, 'fija', 50000, 'Tarifario', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'plataforma'
    );
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'dolly', 1, 'fija', 50000, 'Tarifario', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'dolly'
    );
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'gondola', 1, 'fija', 50000, 'Tarifario', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'gondola'
    );

    -- Opción: adicionales / pata_elefante (Tarifario, costo: 3250)
    SELECT oc.id, oc.precio_venta INTO v_opt_id, v_pv
    FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'adicionales' AND oc.clave = 'pata_elefante' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'adicionales', 'pata_elefante'; END IF;
    IF v_pv IS DISTINCT FROM 3250 THEN
        RAISE EXCEPTION 'Guardia de coherencia falló en % / %: precio_venta en catálogo es %, pero se esperaba %', 'adicionales', 'pata_elefante', v_pv, 3250;
    END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'plataforma', 1, 'fija', 3250, 'Tarifario', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'plataforma'
    );
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'dolly', 1, 'fija', 3250, 'Tarifario', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'dolly'
    );
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'gondola', 1, 'fija', 3250, 'Tarifario', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'gondola'
    );

    -- Opción: adicionales / polinera_atravesada (Tarifario, costo: 6000)
    SELECT oc.id, oc.precio_venta INTO v_opt_id, v_pv
    FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'adicionales' AND oc.clave = 'polinera_atravesada' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'adicionales', 'polinera_atravesada'; END IF;
    IF v_pv IS DISTINCT FROM 6000 THEN
        RAISE EXCEPTION 'Guardia de coherencia falló en % / %: precio_venta en catálogo es %, pero se esperaba %', 'adicionales', 'polinera_atravesada', v_pv, 6000;
    END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'plataforma', 1, 'fija', 6000, 'Tarifario', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'plataforma'
    );
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'dolly', 1, 'fija', 6000, 'Tarifario', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'dolly'
    );
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'gondola', 1, 'fija', 6000, 'Tarifario', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'gondola'
    );

    -- Opción: adicionales / polinera_bicicletera (Tarifario, costo: 8000)
    SELECT oc.id, oc.precio_venta INTO v_opt_id, v_pv
    FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'adicionales' AND oc.clave = 'polinera_bicicletera' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'adicionales', 'polinera_bicicletera'; END IF;
    IF v_pv IS DISTINCT FROM 8000 THEN
        RAISE EXCEPTION 'Guardia de coherencia falló en % / %: precio_venta en catálogo es %, pero se esperaba %', 'adicionales', 'polinera_bicicletera', v_pv, 8000;
    END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'plataforma', 1, 'fija', 8000, 'Tarifario', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'plataforma'
    );
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'dolly', 1, 'fija', 8000, 'Tarifario', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'dolly'
    );
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'gondola', 1, 'fija', 8000, 'Tarifario', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'gondola'
    );

    -- Opción: adicionales / polinera_puerta (Tarifario, costo: 10000)
    SELECT oc.id, oc.precio_venta INTO v_opt_id, v_pv
    FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'adicionales' AND oc.clave = 'polinera_puerta' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'adicionales', 'polinera_puerta'; END IF;
    IF v_pv IS DISTINCT FROM 10000 THEN
        RAISE EXCEPTION 'Guardia de coherencia falló en % / %: precio_venta en catálogo es %, pero se esperaba %', 'adicionales', 'polinera_puerta', v_pv, 10000;
    END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'plataforma', 1, 'fija', 10000, 'Tarifario', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'plataforma'
    );
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'dolly', 1, 'fija', 10000, 'Tarifario', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'dolly'
    );
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'gondola', 1, 'fija', 10000, 'Tarifario', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'gondola'
    );

    -- Opción: adicionales / portallantas_extra (Tarifario, costo: 3500)
    SELECT oc.id, oc.precio_venta INTO v_opt_id, v_pv
    FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'adicionales' AND oc.clave = 'portallantas_extra' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'adicionales', 'portallantas_extra'; END IF;
    IF v_pv IS DISTINCT FROM 3500 THEN
        RAISE EXCEPTION 'Guardia de coherencia falló en % / %: precio_venta en catálogo es %, pero se esperaba %', 'adicionales', 'portallantas_extra', v_pv, 3500;
    END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'plataforma', 1, 'fija', 3500, 'Tarifario', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'plataforma'
    );
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'dolly', 1, 'fija', 3500, 'Tarifario', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'dolly'
    );
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'gondola', 1, 'fija', 3500, 'Tarifario', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'gondola'
    );

    -- Opción: adicionales / refuerzos (Tarifario, costo: 14786)
    SELECT oc.id, oc.precio_venta INTO v_opt_id, v_pv
    FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'adicionales' AND oc.clave = 'refuerzos' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'adicionales', 'refuerzos'; END IF;
    IF v_pv IS DISTINCT FROM 14786 THEN
        RAISE EXCEPTION 'Guardia de coherencia falló en % / %: precio_venta en catálogo es %, pero se esperaba %', 'adicionales', 'refuerzos', v_pv, 14786;
    END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'plataforma', 1, 'fija', 14786, 'Tarifario', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'plataforma'
    );
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'dolly', 1, 'fija', 14786, 'Tarifario', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'dolly'
    );
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'gondola', 1, 'fija', 14786, 'Tarifario', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'gondola'
    );

    -- Opción: adicionales / sistema_psi (Tarifario, costo: 20000)
    SELECT oc.id, oc.precio_venta INTO v_opt_id, v_pv
    FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'adicionales' AND oc.clave = 'sistema_psi' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'adicionales', 'sistema_psi'; END IF;
    IF v_pv IS DISTINCT FROM 20000 THEN
        RAISE EXCEPTION 'Guardia de coherencia falló en % / %: precio_venta en catálogo es %, pero se esperaba %', 'adicionales', 'sistema_psi', v_pv, 20000;
    END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'plataforma', 1, 'fija', 20000, 'Tarifario', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'plataforma'
    );
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'dolly', 1, 'fija', 20000, 'Tarifario', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'dolly'
    );
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'gondola', 1, 'fija', 20000, 'Tarifario', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'gondola'
    );

    -- Opción: color / rojo_claro (Supuesto: sin costo adicional, costo: 0)
    SELECT oc.id, oc.precio_venta INTO v_opt_id, v_pv
    FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'color' AND oc.clave = 'rojo_claro' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'color', 'rojo_claro'; END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'plataforma', 1, 'fija', 0, 'Supuesto: sin costo adicional', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'plataforma'
    );
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'dolly', 1, 'fija', 0, 'Supuesto: sin costo adicional', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'dolly'
    );
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'gondola', 1, 'fija', 0, 'Supuesto: sin costo adicional', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'gondola'
    );

    -- Opción: color / rojo (Supuesto: sin costo adicional, costo: 0)
    SELECT oc.id, oc.precio_venta INTO v_opt_id, v_pv
    FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'color' AND oc.clave = 'rojo' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'color', 'rojo'; END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'plataforma', 1, 'fija', 0, 'Supuesto: sin costo adicional', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'plataforma'
    );
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'dolly', 1, 'fija', 0, 'Supuesto: sin costo adicional', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'dolly'
    );
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'gondola', 1, 'fija', 0, 'Supuesto: sin costo adicional', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'gondola'
    );

    -- Opción: color / rojo_coca_cola (Supuesto: sin costo adicional, costo: 0)
    SELECT oc.id, oc.precio_venta INTO v_opt_id, v_pv
    FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'color' AND oc.clave = 'rojo_coca_cola' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'color', 'rojo_coca_cola'; END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'plataforma', 1, 'fija', 0, 'Supuesto: sin costo adicional', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'plataforma'
    );
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'dolly', 1, 'fija', 0, 'Supuesto: sin costo adicional', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'dolly'
    );
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'gondola', 1, 'fija', 0, 'Supuesto: sin costo adicional', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'gondola'
    );

    -- Opción: color / rojo_bermellon (Supuesto: sin costo adicional, costo: 0)
    SELECT oc.id, oc.precio_venta INTO v_opt_id, v_pv
    FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'color' AND oc.clave = 'rojo_bermellon' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'color', 'rojo_bermellon'; END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'plataforma', 1, 'fija', 0, 'Supuesto: sin costo adicional', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'plataforma'
    );
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'dolly', 1, 'fija', 0, 'Supuesto: sin costo adicional', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'dolly'
    );
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'gondola', 1, 'fija', 0, 'Supuesto: sin costo adicional', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'gondola'
    );

    -- Opción: color / vino (Supuesto: sin costo adicional, costo: 0)
    SELECT oc.id, oc.precio_venta INTO v_opt_id, v_pv
    FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'color' AND oc.clave = 'vino' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'color', 'vino'; END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'plataforma', 1, 'fija', 0, 'Supuesto: sin costo adicional', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'plataforma'
    );
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'dolly', 1, 'fija', 0, 'Supuesto: sin costo adicional', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'dolly'
    );
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'gondola', 1, 'fija', 0, 'Supuesto: sin costo adicional', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'gondola'
    );

    -- Opción: color / negro (Supuesto: sin costo adicional, costo: 0)
    SELECT oc.id, oc.precio_venta INTO v_opt_id, v_pv
    FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'color' AND oc.clave = 'negro' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'color', 'negro'; END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'plataforma', 1, 'fija', 0, 'Supuesto: sin costo adicional', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'plataforma'
    );
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'dolly', 1, 'fija', 0, 'Supuesto: sin costo adicional', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'dolly'
    );
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'gondola', 1, 'fija', 0, 'Supuesto: sin costo adicional', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'gondola'
    );

    -- Opción: color / anaranjado_con_borda_blanca (Supuesto: sin costo adicional, costo: 0)
    SELECT oc.id, oc.precio_venta INTO v_opt_id, v_pv
    FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'color' AND oc.clave = 'anaranjado_con_borda_blanca' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'color', 'anaranjado_con_borda_blanca'; END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'plataforma', 1, 'fija', 0, 'Supuesto: sin costo adicional', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'plataforma'
    );
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'dolly', 1, 'fija', 0, 'Supuesto: sin costo adicional', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'dolly'
    );
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'gondola', 1, 'fija', 0, 'Supuesto: sin costo adicional', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'gondola'
    );

    -- Opción: color / azul_rey (Supuesto: sin costo adicional, costo: 0)
    SELECT oc.id, oc.precio_venta INTO v_opt_id, v_pv
    FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'color' AND oc.clave = 'azul_rey' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'color', 'azul_rey'; END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'plataforma', 1, 'fija', 0, 'Supuesto: sin costo adicional', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'plataforma'
    );
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'dolly', 1, 'fija', 0, 'Supuesto: sin costo adicional', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'dolly'
    );
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'gondola', 1, 'fija', 0, 'Supuesto: sin costo adicional', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'gondola'
    );

    -- Opción: color / blanco (Supuesto: sin costo adicional, costo: 0)
    SELECT oc.id, oc.precio_venta INTO v_opt_id, v_pv
    FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'color' AND oc.clave = 'blanco' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'color', 'blanco'; END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'plataforma', 1, 'fija', 0, 'Supuesto: sin costo adicional', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'plataforma'
    );
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'dolly', 1, 'fija', 0, 'Supuesto: sin costo adicional', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'dolly'
    );
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'gondola', 1, 'fija', 0, 'Supuesto: sin costo adicional', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'gondola'
    );

    -- Opción: color / gris (Supuesto: sin costo adicional, costo: 0)
    SELECT oc.id, oc.precio_venta INTO v_opt_id, v_pv
    FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'color' AND oc.clave = 'gris' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'color', 'gris'; END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'plataforma', 1, 'fija', 0, 'Supuesto: sin costo adicional', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'plataforma'
    );
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'dolly', 1, 'fija', 0, 'Supuesto: sin costo adicional', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'dolly'
    );
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'gondola', 1, 'fija', 0, 'Supuesto: sin costo adicional', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'gondola'
    );

    -- Opción: color / naranja (Supuesto: sin costo adicional, costo: 0)
    SELECT oc.id, oc.precio_venta INTO v_opt_id, v_pv
    FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'color' AND oc.clave = 'naranja' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'color', 'naranja'; END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'plataforma', 1, 'fija', 0, 'Supuesto: sin costo adicional', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'plataforma'
    );
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'dolly', 1, 'fija', 0, 'Supuesto: sin costo adicional', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'dolly'
    );
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'gondola', 1, 'fija', 0, 'Supuesto: sin costo adicional', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'gondola'
    );

    -- Opción: color / amarillo (Supuesto: sin costo adicional, costo: 0)
    SELECT oc.id, oc.precio_venta INTO v_opt_id, v_pv
    FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'color' AND oc.clave = 'amarillo' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'color', 'amarillo'; END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'plataforma', 1, 'fija', 0, 'Supuesto: sin costo adicional', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'plataforma'
    );
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'dolly', 1, 'fija', 0, 'Supuesto: sin costo adicional', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'dolly'
    );
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'gondola', 1, 'fija', 0, 'Supuesto: sin costo adicional', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'gondola'
    );

    -- Opción: color / rosa (Supuesto: sin costo adicional, costo: 0)
    SELECT oc.id, oc.precio_venta INTO v_opt_id, v_pv
    FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'color' AND oc.clave = 'rosa' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'color', 'rosa'; END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'plataforma', 1, 'fija', 0, 'Supuesto: sin costo adicional', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'plataforma'
    );
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'dolly', 1, 'fija', 0, 'Supuesto: sin costo adicional', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'dolly'
    );
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'gondola', 1, 'fija', 0, 'Supuesto: sin costo adicional', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'gondola'
    );

    -- Opción: color / verde (Supuesto: sin costo adicional, costo: 0)
    SELECT oc.id, oc.precio_venta INTO v_opt_id, v_pv
    FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'color' AND oc.clave = 'verde' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'color', 'verde'; END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'plataforma', 1, 'fija', 0, 'Supuesto: sin costo adicional', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'plataforma'
    );
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'dolly', 1, 'fija', 0, 'Supuesto: sin costo adicional', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'dolly'
    );
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'gondola', 1, 'fija', 0, 'Supuesto: sin costo adicional', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'gondola'
    );

    -- Opción: color / morado (Supuesto: sin costo adicional, costo: 0)
    SELECT oc.id, oc.precio_venta INTO v_opt_id, v_pv
    FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'color' AND oc.clave = 'morado' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'color', 'morado'; END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'plataforma', 1, 'fija', 0, 'Supuesto: sin costo adicional', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'plataforma'
    );
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'dolly', 1, 'fija', 0, 'Supuesto: sin costo adicional', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'dolly'
    );
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'gondola', 1, 'fija', 0, 'Supuesto: sin costo adicional', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'gondola'
    );

    -- Opción: color / cafe (Supuesto: sin costo adicional, costo: 0)
    SELECT oc.id, oc.precio_venta INTO v_opt_id, v_pv
    FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'color' AND oc.clave = 'cafe' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'color', 'cafe'; END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'plataforma', 1, 'fija', 0, 'Supuesto: sin costo adicional', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'plataforma'
    );
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'dolly', 1, 'fija', 0, 'Supuesto: sin costo adicional', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'dolly'
    );
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'gondola', 1, 'fija', 0, 'Supuesto: sin costo adicional', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'gondola'
    );

    -- Opción: pintura / axalta (Supuesto: sin costo adicional, costo: 0)
    SELECT oc.id, oc.precio_venta INTO v_opt_id, v_pv
    FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'pintura' AND oc.clave = 'axalta' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'pintura', 'axalta'; END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'plataforma', 1, 'fija', 0, 'Supuesto: sin costo adicional', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'plataforma'
    );
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'dolly', 1, 'fija', 0, 'Supuesto: sin costo adicional', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'dolly'
    );
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'gondola', 1, 'fija', 0, 'Supuesto: sin costo adicional', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'gondola'
    );

    -- Opción: pintura / ppg (Supuesto: sin costo adicional, costo: 0)
    SELECT oc.id, oc.precio_venta INTO v_opt_id, v_pv
    FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'pintura' AND oc.clave = 'ppg' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'pintura', 'ppg'; END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'plataforma', 1, 'fija', 0, 'Supuesto: sin costo adicional', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'plataforma'
    );
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'dolly', 1, 'fija', 0, 'Supuesto: sin costo adicional', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'dolly'
    );
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'gondola', 1, 'fija', 0, 'Supuesto: sin costo adicional', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'gondola'
    );

    -- Opción: pintura / sherwin_williams (Supuesto: sin costo adicional, costo: 0)
    SELECT oc.id, oc.precio_venta INTO v_opt_id, v_pv
    FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'pintura' AND oc.clave = 'sherwin_williams' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'pintura', 'sherwin_williams'; END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'plataforma', 1, 'fija', 0, 'Supuesto: sin costo adicional', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'plataforma'
    );
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'dolly', 1, 'fija', 0, 'Supuesto: sin costo adicional', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'dolly'
    );
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    SELECT v_org_id, v_opt_id, 'gondola', 1, 'fija', 0, 'Supuesto: sin costo adicional', 'import-2r1g'
    WHERE NOT EXISTS (
        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = 'gondola'
    );

END $$;

COMMIT;
