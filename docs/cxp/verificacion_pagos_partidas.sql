-- Script de Verificación: CxP Pagos por Partida
-- Ejecutable directamente en el SQL Editor de Supabase (un solo SELECT con todo_ok)
-- Sin metacomandos de psql (\c, \echo, etc.)

WITH checks AS (
    SELECT 
        -- 1. Existencia de la tabla pagos_factura_partidas
        (to_regclass('public.pagos_factura_partidas') IS NOT NULL) AS tabla_pagos_partidas_existe,

        -- 2. Existencia de la vista v_factura_partidas_saldo
        (to_regclass('public.v_factura_partidas_saldo') IS NOT NULL) AS vista_partidas_saldo_existe,

        -- 3. Existencia de la RPC registrar_pago_factura con soporte para asignaciones
        EXISTS (
            SELECT 1 FROM pg_proc p
            JOIN pg_namespace n ON n.oid = p.pronamespace
            WHERE n.nspname = 'public' 
              AND p.proname = 'registrar_pago_factura'
              AND p.pronargs >= 9
        ) AS rpc_registrar_pago_existe,

        -- 4. Validez de asignaciones: ninguna asignación con monto <= 0 ni nulo
        NOT EXISTS (
            SELECT 1 FROM pagos_factura_partidas
            WHERE monto IS NULL OR monto <= 0
        ) AS asignaciones_monto_valido,

        -- 5. Asignaciones no exceden el importe a pagar de su partida
        NOT EXISTS (
            SELECT pfp.partida_id
            FROM pagos_factura_partidas pfp
            JOIN pagos_factura pf ON pf.id = pfp.pago_id
            JOIN v_factura_partidas_saldo v ON v.partida_id = pfp.partida_id
            WHERE pf.anulado = false
            GROUP BY pfp.partida_id, v.importe_a_pagar
            HAVING SUM(pfp.monto) > v.importe_a_pagar + 0.01
        ) AS asignaciones_no_exceden_importe,

        -- 6. Para toda factura con partidas y pagos, suma de asignaciones activas = suma de pagos activos
        NOT EXISTS (
            SELECT f.id
            FROM facturas_proveedor f
            WHERE EXISTS (SELECT 1 FROM factura_proveedor_partidas WHERE factura_id = f.id)
              AND EXISTS (SELECT 1 FROM pagos_factura WHERE factura_id = f.id AND anulado = false)
            GROUP BY f.id
            HAVING abs(
                COALESCE((
                    SELECT SUM(pf.monto) 
                    FROM pagos_factura pf 
                    WHERE pf.factura_id = f.id AND pf.anulado = false
                ), 0) -
                COALESCE((
                    SELECT SUM(pfp.monto) 
                    FROM pagos_factura_partidas pfp 
                    JOIN pagos_factura pf ON pf.id = pfp.pago_id 
                    WHERE pf.factura_id = f.id AND pf.anulado = false
                ), 0)
            ) > 0.01
        ) AS suma_asignaciones_igual_pagos_activos,

        -- 7. Ninguna asignación huérfana o inconsistente
        NOT EXISTS (
            SELECT 1 
            FROM pagos_factura_partidas pfp
            LEFT JOIN pagos_factura pf ON pf.id = pfp.pago_id
            LEFT JOIN factura_proveedor_partidas fpp ON fpp.id = pfp.partida_id
            WHERE pf.id IS NULL OR fpp.id IS NULL
        ) AS sin_asignaciones_huerfanas,

        -- 8. Seguridad RPC: registrar_pago_factura solo ejecutable por service_role (no authenticated ni anon)
        (
            NOT has_function_privilege('authenticated', 'public.registrar_pago_factura(UUID, UUID, DATE, NUMERIC, NUMERIC, TEXT, TEXT, TEXT, TEXT, JSONB)', 'EXECUTE')
            AND NOT has_function_privilege('anon', 'public.registrar_pago_factura(UUID, UUID, DATE, NUMERIC, NUMERIC, TEXT, TEXT, TEXT, TEXT, JSONB)', 'EXECUTE')
            AND has_function_privilege('service_role', 'public.registrar_pago_factura(UUID, UUID, DATE, NUMERIC, NUMERIC, TEXT, TEXT, TEXT, TEXT, JSONB)', 'EXECUTE')
        ) AS rpc_registrar_pago_solo_service_role
)
SELECT 
    tabla_pagos_partidas_existe,
    vista_partidas_saldo_existe,
    rpc_registrar_pago_existe,
    asignaciones_monto_valido,
    asignaciones_no_exceden_importe,
    suma_asignaciones_igual_pagos_activos,
    sin_asignaciones_huerfanas,
    rpc_registrar_pago_solo_service_role,
    (
        tabla_pagos_partidas_existe AND
        vista_partidas_saldo_existe AND
        rpc_registrar_pago_existe AND
        asignaciones_monto_valido AND
        asignaciones_no_exceden_importe AND
        suma_asignaciones_igual_pagos_activos AND
        sin_asignaciones_huerfanas AND
        rpc_registrar_pago_solo_service_role
    ) AS todo_ok
FROM checks;
