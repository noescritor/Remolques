-- docs/proveedores/verificacion_T4.sql
-- Script de verificación de esquema, vista y permisos para Sub-bloque T4
-- Debe retornar todo_ok = true

SELECT
    -- 1. Tablas existen
    EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'factura_proveedor_partidas') AS tabla_partidas_existe,
    EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'facturas_proveedor_cfdi') AS tabla_cfdi_existe,
    
    -- 2. Columnas añadidas a facturas_proveedor
    EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'facturas_proveedor' AND column_name = 'uuid_fiscal') AS col_uuid_fiscal,
    EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'facturas_proveedor' AND column_name = 'subtotal') AS col_subtotal,
    EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'facturas_proveedor' AND column_name = 'impuestos_trasladados') AS col_traslados,
    
    -- 3. Columnas presentes en la vista v_facturas_proveedor_saldo
    EXISTS (SELECT 1 FROM information_schema.views WHERE table_name = 'v_facturas_proveedor_saldo') AS vista_saldo_existe,
    EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'v_facturas_proveedor_saldo' AND column_name = 'uuid_fiscal') AS vista_tiene_uuid,
    EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'v_facturas_proveedor_saldo' AND column_name = 'subtotal') AS vista_tiene_subtotal,
    EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'v_facturas_proveedor_saldo' AND column_name = 'impuestos_trasladados') AS vista_tiene_traslados,

    -- 4. Índice único parcial por organización y UUID en facturas_proveedor
    EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE tablename = 'facturas_proveedor' 
          AND indexname = 'uq_facturas_proveedor_org_uuid'
    ) AS indice_uq_facturas_uuid,

    -- 5. Restricción única en facturas_proveedor_cfdi
    EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'uq_facturas_cfdi_org_uuid') AS restriccion_uq_cfdi,

    -- 6. Función RPC existe y con permisos correctos
    EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'guardar_factura_con_partidas') AS funcion_rpc_existe,

    -- 7. RLS habilitado y políticas exclusivas de SELECT para authenticated
    (SELECT relrowsecurity FROM pg_class WHERE relname = 'factura_proveedor_partidas') AS rls_partidas_activo,
    (SELECT relrowsecurity FROM pg_class WHERE relname = 'facturas_proveedor_cfdi') AS rls_cfdi_activo,
    (
        SELECT COUNT(*) 
        FROM pg_policy pol
        JOIN pg_class c ON c.oid = pol.polrelid
        WHERE c.relname IN ('factura_proveedor_partidas', 'facturas_proveedor_cfdi')
          AND pol.polcmd <> 'r' -- 'r' = SELECT
    ) AS politicas_no_select,

    -- 8. Indicador global de éxito
    (
        EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'factura_proveedor_partidas') AND
        EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'facturas_proveedor_cfdi') AND
        EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'facturas_proveedor' AND column_name = 'uuid_fiscal') AND
        EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'v_facturas_proveedor_saldo' AND column_name = 'uuid_fiscal') AND
        EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'v_facturas_proveedor_saldo' AND column_name = 'subtotal') AND
        EXISTS (
            SELECT 1 FROM pg_indexes 
            WHERE tablename = 'facturas_proveedor' 
              AND indexname = 'uq_facturas_proveedor_org_uuid'
        ) AND
        EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'uq_facturas_cfdi_org_uuid') AND
        EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'guardar_factura_con_partidas') AND
        (
            SELECT COUNT(*) 
            FROM pg_policy pol
            JOIN pg_class c ON c.oid = pol.polrelid
            WHERE c.relname IN ('factura_proveedor_partidas', 'facturas_proveedor_cfdi')
              AND pol.polcmd <> 'r'
        ) = 0
    ) AS todo_ok;
