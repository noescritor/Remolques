-- docs/proveedores/verificacion_T4.sql
-- Script de verificación de esquema y permisos para Sub-bloque T4

SELECT
    -- 1. Tablas existen
    EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'factura_proveedor_partidas') AS tabla_partidas_existe,
    EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'facturas_proveedor_cfdi') AS tabla_cfdi_existe,
    -- 2. Columnas añadidas a facturas_proveedor
    EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'facturas_proveedor' AND column_name = 'uuid_fiscal') AS col_uuid_fiscal,
    EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'facturas_proveedor' AND column_name = 'subtotal') AS col_subtotal,
    EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'facturas_proveedor' AND column_name = 'impuestos_trasladados') AS col_traslados,
    -- 3. Restricción única en facturas_proveedor_cfdi por UUID fiscal y organización
    EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'uq_facturas_cfdi_org_uuid') AS restriccion_uq_cfdi,
    -- 4. Función RPC existe
    EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'guardar_factura_con_partidas') AS funcion_rpc_existe,
    -- 5. RLS habilitado
    (SELECT relrowsecurity FROM pg_class WHERE relname = 'factura_proveedor_partidas') AS rls_partidas_activo,
    (SELECT relrowsecurity FROM pg_class WHERE relname = 'facturas_proveedor_cfdi') AS rls_cfdi_activo,
    -- 6. Indicador global de éxito
    (
        EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'factura_proveedor_partidas') AND
        EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'facturas_proveedor_cfdi') AND
        EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'facturas_proveedor' AND column_name = 'uuid_fiscal') AND
        EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'uq_facturas_cfdi_org_uuid') AND
        EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'guardar_factura_con_partidas')
    ) AS todo_ok;
