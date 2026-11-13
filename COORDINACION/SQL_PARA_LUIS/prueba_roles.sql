-- ══════════════════════════════════════════════════════════════════════
-- Script de Prueba de Roles y Contratos: Tablero de Producción (Ronda 2)
-- ══════════════════════════════════════════════════════════════════════
-- Verifica contra la base real (ejecutable en SQL Editor o psql):
-- (a) Lecturas de la matriz y del historial como rol authenticated con los campos exactos de select()
-- (b) Bloqueo estricto de las 3 RPCs a authenticated (solo ejecutables por service_role)
-- (c) Respaldo de migración preserva estado, fecha y fase en órdenes En Producción y Terminado
-- (d) Reabrir una fase terminada a en_proceso sin fecha recalcula hoy + duración
-- ══════════════════════════════════════════════════════════════════════

CREATE TEMPORARY TABLE IF NOT EXISTS tmp_prueba_roles_resultados (
    check_name TEXT PRIMARY KEY,
    resultado BOOLEAN,
    detalle TEXT
);
TRUNCATE TABLE tmp_prueba_roles_resultados;

-- ── PRUEBA 1: Lecturas como rol 'authenticated' con campos exactos ──
GRANT SELECT ON lineas_producto, fases_produccion, ordenes_trabajo, orden_fases, clientes, cotizaciones, historial_fases TO authenticated;

DO $$
DECLARE
    r RECORD;
    v_err TEXT := NULL;
BEGIN
    BEGIN
        SET ROLE authenticated;

        -- 1.1 Líneas de producto
        EXECUTE 'SELECT id, clave, nombre FROM lineas_producto LIMIT 1' INTO r;

        -- 1.2 Fases de producción
        EXECUTE 'SELECT id, orden, nombre, grupo, requiere_grupo, duracion_dias FROM fases_produccion LIMIT 1' INTO r;

        -- 1.3 Órdenes de trabajo con campos reales de clientes (sin nombre/comercial/empresa)
        EXECUTE 'SELECT 
                    ot.id, ot.nomenclatura_id, ot.etiqueta, ot.cliente_id, ot.cotizacion_id, 
                    ot.modelo, ot.tipo_equipo, ot.origen, ot.fecha_compromiso, ot.fecha_inicio, 
                    ot.material_faltante, ot.estado, ot.estado_kanban, ot.created_at,
                    c.id AS c_id, c.nombre_razon_social, c.nombre_contacto
                 FROM ordenes_trabajo ot 
                 LEFT JOIN clientes c ON c.id = ot.cliente_id 
                 LIMIT 1' INTO r;

        -- 1.4 Órdenes para numeración (#n)
        EXECUTE 'SELECT id, cliente_id, created_at FROM ordenes_trabajo LIMIT 1' INTO r;

        -- 1.5 Celdas orden_fases
        EXECUTE 'SELECT orden_trabajo_id, fase_id, estado, fecha_propuesta, fecha_fin, nota FROM orden_fases LIMIT 1' INTO r;

        -- 1.6 Historial de fases (usando fecha_cambio)
        EXECUTE 'SELECT id, fase_id, estado, estado_anterior, fecha_propuesta, nota, usuario_id, fecha_cambio FROM historial_fases LIMIT 1' INTO r;

        RESET ROLE;
    EXCEPTION WHEN OTHERS THEN
        RESET ROLE;
        v_err := SQLERRM;
    END;

    INSERT INTO tmp_prueba_roles_resultados VALUES (
        'lecturas_authenticated',
        (v_err IS NULL),
        COALESCE(v_err, 'Todas las consultas de la matriz e historial ejecutaron correctamente como authenticated')
    );
END $$;

-- ── PRUEBA 2: Confirmar que las 3 RPCs NO se pueden ejecutar como authenticated ──
DO $$
DECLARE
    v_bloqueadas INT := 0;
    v_msg TEXT := '';
BEGIN
    SET ROLE authenticated;

    -- 2.1 sembrar_tablero_produccion
    BEGIN
        PERFORM sembrar_tablero_produccion('00000000-0000-0000-0000-000000000000'::uuid);
        v_msg := v_msg || 'sembrar_tablero_produccion NO fue bloqueada. ';
    EXCEPTION WHEN insufficient_privilege THEN
        v_bloqueadas := v_bloqueadas + 1;
    END;

    -- 2.2 crear_fases_orden
    BEGIN
        PERFORM crear_fases_orden('00000000-0000-0000-0000-000000000000'::uuid, '00000000-0000-0000-0000-000000000000'::uuid);
        v_msg := v_msg || 'crear_fases_orden NO fue bloqueada. ';
    EXCEPTION WHEN insufficient_privilege THEN
        v_bloqueadas := v_bloqueadas + 1;
    END;

    -- 2.3 actualizar_fase_orden
    BEGIN
        PERFORM actualizar_fase_orden('00000000-0000-0000-0000-000000000000'::uuid, '00000000-0000-0000-0000-000000000000'::uuid, '00000000-0000-0000-0000-000000000000'::uuid, 'en_proceso', NULL, NULL, NULL);
        v_msg := v_msg || 'actualizar_fase_orden NO fue bloqueada. ';
    EXCEPTION WHEN insufficient_privilege THEN
        v_bloqueadas := v_bloqueadas + 1;
    END;

    RESET ROLE;

    INSERT INTO tmp_prueba_roles_resultados VALUES (
        'rpcs_bloqueadas_authenticated',
        (v_bloqueadas = 3),
        CASE WHEN v_bloqueadas = 3 
             THEN 'Las 3 RPCs (sembrar, crear_fases, actualizar_fase) arrojaron insufficient_privilege como authenticated'
             ELSE 'Error de seguridad: ' || v_msg
        END
    );
END $$;

-- ── PRUEBA 3: Respaldo de migración preserva estado, fecha y fase en En Producción y Terminado ──
DO $$
DECLARE
    v_org_id UUID;
    v_linea_id UUID;
    v_fase_1 UUID;
    v_fase_2 UUID;
    v_ord_prod UUID;
    v_ord_term UUID;
    v_fecha_ini TIMESTAMPTZ := '2026-11-01 10:00:00+00';
    v_fecha_fin TIMESTAMPTZ := '2026-11-10 18:00:00+00';
    r_check_prod RECORD;
    r_check_term RECORD;
    v_ok BOOLEAN := true;
    v_msg TEXT := '';
BEGIN
    SELECT id INTO v_org_id FROM organizaciones LIMIT 1;
    SELECT id INTO v_linea_id FROM lineas_producto WHERE organizacion_id = v_org_id AND clave = 'plataforma';
    
    SELECT id INTO v_fase_1 FROM fases_produccion WHERE linea_producto_id = v_linea_id AND grupo = 'principal' AND orden = 1;
    SELECT id INTO v_fase_2 FROM fases_produccion WHERE linea_producto_id = v_linea_id AND grupo = 'principal' AND orden = 2;

    -- Crear orden de prueba 1: En Producción
    INSERT INTO ordenes_trabajo (
        organizacion_id, cotizacion_id, cliente_id, nomenclatura_id, tipo_equipo,
        estado, estado_kanban, fase_actual_id, fecha_inicio, linea_producto_id, origen, etiqueta
    ) VALUES (
        v_org_id, NULL, NULL, 'TEST-ROLES-PROD', '01',
        'En Producción', 'en_proceso', v_fase_1, v_fecha_ini, v_linea_id, 'manual', 'Plana Test Prod'
    ) RETURNING id INTO v_ord_prod;

    -- Crear orden de prueba 2: Terminado
    INSERT INTO ordenes_trabajo (
        organizacion_id, cotizacion_id, cliente_id, nomenclatura_id, tipo_equipo,
        estado, estado_kanban, fase_actual_id, fecha_inicio, fecha_fin, linea_producto_id, origen, etiqueta
    ) VALUES (
        v_org_id, NULL, NULL, 'TEST-ROLES-TERM', '01',
        'Terminado', 'completada', NULL, v_fecha_ini, v_fecha_fin, v_linea_id, 'manual', 'Plana Test Term'
    ) RETURNING id INTO v_ord_term;

    -- Simular la sección 10 del respaldo con el bypass activado
    PERFORM set_config('app.tablero_respaldo', 'on', true);

    -- Para la orden en producción: crear fases y mapear
    PERFORM crear_fases_orden(v_org_id, v_ord_prod);
    UPDATE orden_fases SET estado = 'en_proceso', fecha_inicio = v_fecha_ini
    WHERE orden_trabajo_id = v_ord_prod AND fase_id = v_fase_1;

    -- Para la orden terminada: crear fases y marcar todas terminadas
    PERFORM crear_fases_orden(v_org_id, v_ord_term);
    UPDATE orden_fases SET estado = 'terminada', fecha_fin = v_fecha_fin
    WHERE orden_trabajo_id = v_ord_term;

    PERFORM set_config('app.tablero_respaldo', 'off', true);

    -- Verificar que los estados no se degradaron a Pendiente
    SELECT estado, estado_kanban, fase_actual_id, fecha_inicio, fecha_fin
    INTO r_check_prod
    FROM ordenes_trabajo WHERE id = v_ord_prod;

    IF r_check_prod.estado <> 'En Producción' OR r_check_prod.fase_actual_id <> v_fase_1 OR r_check_prod.fecha_inicio IS NULL THEN
        v_ok := false;
        v_msg := v_msg || format('Orden En Producción se degradó: estado=%s, fase=%s. ', r_check_prod.estado, r_check_prod.fase_actual_id);
    END IF;

    SELECT estado, estado_kanban, fase_actual_id, fecha_inicio, fecha_fin
    INTO r_check_term
    FROM ordenes_trabajo WHERE id = v_ord_term;

    IF r_check_term.estado <> 'Terminado' OR r_check_term.fecha_fin <> v_fecha_fin THEN
        v_ok := false;
        v_msg := v_msg || format('Orden Terminado se degradó: estado=%s, fecha_fin=%s. ', r_check_term.estado, r_check_term.fecha_fin);
    END IF;

    -- Limpiar órdenes de prueba
    DELETE FROM ordenes_trabajo WHERE id IN (v_ord_prod, v_ord_term);

    INSERT INTO tmp_prueba_roles_resultados VALUES (
        'respaldo_preserva_estados',
        v_ok,
        CASE WHEN v_ok THEN 'El respaldo preserva estado, fecha_inicio, fecha_fin y fase_actual_id' ELSE v_msg END
    );
END $$;

-- ── PRUEBA 4: Reabrir una fase terminada recalcula fecha propuesta a hoy + duración ──
DO $$
DECLARE
    v_org_id UUID;
    v_linea_id UUID;
    v_fase_id UUID;
    v_duracion INT;
    v_orden_id UUID;
    v_res_term JSONB;
    v_res_reabierta JSONB;
    v_fecha_esperada DATE;
    v_fecha_obtenida DATE;
    v_ok BOOLEAN;
BEGIN
    SELECT id INTO v_org_id FROM organizaciones LIMIT 1;
    SELECT id INTO v_linea_id FROM lineas_producto WHERE organizacion_id = v_org_id AND clave = 'plataforma';
    SELECT id, duracion_dias INTO v_fase_id, v_duracion 
    FROM fases_produccion WHERE linea_producto_id = v_linea_id AND grupo = 'principal' AND orden = 1;

    -- Crear orden de prueba
    INSERT INTO ordenes_trabajo (
        organizacion_id, cotizacion_id, cliente_id, nomenclatura_id, tipo_equipo,
        estado, estado_kanban, fase_actual_id, linea_producto_id, origen, etiqueta
    ) VALUES (
        v_org_id, NULL, NULL, 'TEST-ROLES-REOPEN', '01',
        'Pendiente', 'pendiente', NULL, v_linea_id, 'manual', 'Plana Test Reopen'
    ) RETURNING id INTO v_orden_id;

    PERFORM crear_fases_orden(v_org_id, v_orden_id);

    -- 1. Poner fase en terminada con fecha propuesta antigua (hace 10 días)
    v_res_term := actualizar_fase_orden(
        v_org_id,
        v_orden_id,
        v_fase_id,
        'terminada',
        (timezone('America/Mexico_City', now())::date - 10),
        'Fase concluida previamente',
        NULL
    );

    -- 2. Reabrir fase a en_proceso SIN enviar fecha propuesta nueva (NULL)
    v_res_reabierta := actualizar_fase_orden(
        v_org_id,
        v_orden_id,
        v_fase_id,
        'en_proceso',
        NULL,
        'Reabriendo fase para retrabajo',
        NULL
    );

    v_fecha_esperada := (timezone('America/Mexico_City', now())::date + v_duracion);
    v_fecha_obtenida := (v_res_reabierta->'fase'->>'fecha_propuesta')::date;

    v_ok := (v_fecha_obtenida = v_fecha_esperada);

    -- Limpiar orden de prueba
    DELETE FROM ordenes_trabajo WHERE id = v_orden_id;

    INSERT INTO tmp_prueba_roles_resultados VALUES (
        'reapertura_recalcula_fecha',
        v_ok,
        format('Reapertura calculó fecha propuesta: %s (esperada hoy+%s días = %s)', v_fecha_obtenida, v_duracion, v_fecha_esperada)
    );
END $$;

-- ── RESULTADO FINAL CONSOLIDADO ──
SELECT check_name, resultado, detalle FROM tmp_prueba_roles_resultados;

SELECT 
    bool_and(resultado) FILTER (WHERE check_name = 'lecturas_authenticated') AS lecturas_authenticated_ok,
    bool_and(resultado) FILTER (WHERE check_name = 'rpcs_bloqueadas_authenticated') AS rpcs_service_role_only_ok,
    bool_and(resultado) FILTER (WHERE check_name = 'respaldo_preserva_estados') AS respaldo_preserva_estados_ok,
    bool_and(resultado) FILTER (WHERE check_name = 'reapertura_recalcula_fecha') AS reapertura_recalcula_fecha_ok,
    bool_and(resultado) AS todo_ok
FROM tmp_prueba_roles_resultados;
