-- Script de Verificación: Tablero de Producción (Bloque 1: Datos y Backend)
-- Ejecutable directamente en el SQL Editor de Supabase (un solo SELECT con todo_ok)
-- Sin metacomandos de psql (\c, \echo, etc.)

WITH checks AS (
    SELECT 
        -- 1. Existencia de la tabla orden_fases
        (to_regclass('public.orden_fases') IS NOT NULL) AS tabla_orden_fases_existe,

        -- 2. Columnas nuevas y nullables en ordenes_trabajo
        (
            EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'ordenes_trabajo' AND column_name = 'fecha_compromiso') AND
            EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'ordenes_trabajo' AND column_name = 'etiqueta') AND
            EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'ordenes_trabajo' AND column_name = 'origen') AND
            (SELECT is_nullable FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'ordenes_trabajo' AND column_name = 'cotizacion_id') = 'YES' AND
            (SELECT is_nullable FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'ordenes_trabajo' AND column_name = 'cliente_id') = 'YES'
        ) AS columnas_ordenes_trabajo_existen,

        -- 3. Columnas nuevas en fases_produccion
        (
            EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'fases_produccion' AND column_name = 'grupo') AND
            EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'fases_produccion' AND column_name = 'duracion_dias') AND
            EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'fases_produccion' AND column_name = 'requiere_grupo') AND
            EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'fases_produccion' AND column_name = 'activo')
        ) AS columnas_fases_produccion_existen,

        -- 4. Existencia de RPC actualizar_fase_orden
        EXISTS (
            SELECT 1 FROM pg_proc p
            JOIN pg_namespace n ON n.oid = p.pronamespace
            WHERE n.nspname = 'public' AND p.proname = 'actualizar_fase_orden'
        ) AS rpc_actualizar_fase_existe,

        -- 5. Existencia de trigger sobre orden_fases
        EXISTS (
            SELECT 1 FROM pg_trigger
            WHERE tgname = 'trg_recalcular_orden_fases' AND NOT tgisinternal
        ) AS trigger_recalcular_existe,

        -- 6. Semilla completa: cada organización con líneas tiene 4 líneas y 55 fases
        NOT EXISTS (
            SELECT o.id
            FROM organizaciones o
            WHERE EXISTS (SELECT 1 FROM lineas_producto lp WHERE lp.organizacion_id = o.id)
            GROUP BY o.id
            HAVING (
                SELECT COUNT(*) FROM lineas_producto lp 
                WHERE lp.organizacion_id = o.id 
                  AND lp.clave IN ('plataforma', 'gondola', 'dolly', 'traila')
            ) <> 4
            OR (
                SELECT COUNT(*) FROM fases_produccion fp 
                WHERE fp.organizacion_id = o.id 
                  AND fp.activo = true
            ) <> 55
        ) AS lineas_y_fases_completas,

        -- 7. Integridad de fases: toda orden con línea tiene su orden_fases por cada fase activa de su línea
        NOT EXISTS (
            SELECT ot.id
            FROM ordenes_trabajo ot
            WHERE ot.linea_producto_id IS NOT NULL
            GROUP BY ot.id, ot.linea_producto_id
            HAVING (
                SELECT COUNT(*) 
                FROM orden_fases ofs 
                WHERE ofs.orden_trabajo_id = ot.id
            ) <> (
                SELECT COUNT(*) 
                FROM fases_produccion fp 
                WHERE fp.linea_producto_id = ot.linea_producto_id 
                  AND fp.activo = true
            )
        ) AS ordenes_con_fases_completas,

        -- 8. Derivación de estados: fase_actual_id y estado_kanban coinciden con las fases
        NOT EXISTS (
            SELECT ot.id
            FROM ordenes_trabajo ot
            JOIN (
                SELECT 
                    ofs.orden_trabajo_id,
                    COUNT(*) AS total_fases,
                    COUNT(*) FILTER (WHERE ofs.estado = 'terminada') AS terminadas,
                    COUNT(*) FILTER (WHERE ofs.estado = 'incompleta') AS incompletas,
                    COUNT(*) FILTER (WHERE ofs.estado = 'pausada') AS pausadas,
                    COUNT(*) FILTER (WHERE ofs.estado = 'en_proceso') AS en_proceso
                FROM orden_fases ofs
                JOIN fases_produccion fp ON fp.id = ofs.fase_id AND fp.activo = true
                GROUP BY ofs.orden_trabajo_id
            ) calc ON calc.orden_trabajo_id = ot.id
            LEFT JOIN LATERAL (
                SELECT ofs2.fase_id
                FROM orden_fases ofs2
                JOIN fases_produccion fp2 ON fp2.id = ofs2.fase_id
                WHERE ofs2.orden_trabajo_id = ot.id
                  AND fp2.grupo = 'principal'
                  AND fp2.activo = true
                  AND ofs2.estado IN ('en_proceso', 'incompleta', 'pausada')
                ORDER BY fp2.orden ASC
                LIMIT 1
            ) pri ON true
            WHERE (
                CASE 
                    WHEN calc.total_fases > 0 AND calc.terminadas = calc.total_fases THEN 'completada'
                    WHEN calc.incompletas > 0 THEN 'incompleta'
                    WHEN calc.pausadas > 0 THEN 'pausada'
                    WHEN calc.en_proceso > 0 THEN 'en_proceso'
                    ELSE 'pendiente'
                END
            ) <> COALESCE(ot.estado_kanban, 'pendiente')
            OR (pri.fase_id IS DISTINCT FROM ot.fase_actual_id)
        ) AS estados_derivados_coinciden,

        -- 9. Validación de órdenes manuales: ninguna orden manual sin cliente y sin etiqueta
        NOT EXISTS (
            SELECT 1 FROM ordenes_trabajo
            WHERE origen = 'manual' 
              AND cliente_id IS NULL 
              AND (etiqueta IS NULL OR TRIM(etiqueta) = '')
        ) AS ordenes_manuales_validas,

        -- 10. Seguridad RPC: solo ejecutable por service_role
        (
            NOT has_function_privilege('authenticated', 'public.actualizar_fase_orden(UUID, UUID, UUID, TEXT, DATE, TEXT, UUID)', 'EXECUTE') AND
            NOT has_function_privilege('anon', 'public.actualizar_fase_orden(UUID, UUID, UUID, TEXT, DATE, TEXT, UUID)', 'EXECUTE') AND
            has_function_privilege('service_role', 'public.actualizar_fase_orden(UUID, UUID, UUID, TEXT, DATE, TEXT, UUID)', 'EXECUTE')
        ) AS rpc_permisos_seguros
)
SELECT 
    tabla_orden_fases_existe,
    columnas_ordenes_trabajo_existen,
    columnas_fases_produccion_existen,
    rpc_actualizar_fase_existe,
    trigger_recalcular_existe,
    lineas_y_fases_completas,
    ordenes_con_fases_completas,
    estados_derivados_coinciden,
    ordenes_manuales_validas,
    rpc_permisos_seguros,
    (
        tabla_orden_fases_existe AND
        columnas_ordenes_trabajo_existen AND
        columnas_fases_produccion_existen AND
        rpc_actualizar_fase_existe AND
        trigger_recalcular_existe AND
        lineas_y_fases_completas AND
        ordenes_con_fases_completas AND
        estados_derivados_coinciden AND
        ordenes_manuales_validas AND
        rpc_permisos_seguros
    ) AS todo_ok
FROM checks;
