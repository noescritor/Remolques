-- Verificación de la migración 2R-16 (Cuentas por pagar con facturas, dólares y conciliación)
-- Ejecutar en el SQL Editor de Supabase tras correr 20261030_01_cxp_facturas.sql

WITH 
-- 1. Tablas nuevas existentes
chk_tablas AS (
    SELECT count(*) = 4 AS tablas_ok
    FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_name IN ('tipos_cambio', 'facturas_proveedor', 'pagos_factura', 'estados_cuenta_proveedor')
),

-- 2. Columnas añadidas a proveedores
chk_cols_proveedores AS (
    SELECT count(*) = 7 AS cols_prov_ok
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'proveedores'
      AND column_name IN (
          'razon_social', 'rfc', 'moneda_default', 
          'dias_credito', 'limite_credito', 'limite_credito_moneda', 'notas_credito'
      )
),

-- 3. Índices únicos requeridos
chk_indices AS (
    SELECT 
        EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND tablename = 'tipos_cambio' AND indexname = 'uq_tipos_cambio_org_fecha_moneda')
        AND EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND tablename = 'facturas_proveedor' AND indexname = 'uq_facturas_proveedor_folio')
        AND EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND tablename = 'estados_cuenta_proveedor' AND indexname = 'uq_estados_cuenta_org_prov_fecha_moneda')
        AS indices_ok
),

-- 4. RLS habilitado en todas las tablas
chk_rls AS (
    SELECT bool_and(rowsecurity) AS rls_ok
    FROM pg_tables
    WHERE schemaname = 'public'
      AND tablename IN ('tipos_cambio', 'facturas_proveedor', 'pagos_factura', 'estados_cuenta_proveedor')
),

-- 5. Vista v_facturas_proveedor_saldo con security_invoker = true
chk_vista AS (
    SELECT 
        EXISTS (
            SELECT 1 
            FROM pg_views 
            WHERE schemaname = 'public' AND viewname = 'v_facturas_proveedor_saldo'
        ) 
        AND EXISTS (
            SELECT 1
            FROM pg_class c
            JOIN pg_namespace n ON n.oid = c.relnamespace
            WHERE n.nspname = 'public' 
              AND c.relname = 'v_facturas_proveedor_saldo'
              AND c.reloptions @> ARRAY['security_invoker=true']
        ) AS vista_ok
),

-- 6. Funciones y privilegios estrictos (SECURITY DEFINER, no anon, no authenticated, sí service_role)
chk_funciones AS (
    SELECT 
        -- registrar_pago_factura
        NOT has_function_privilege('anon', 'registrar_pago_factura(uuid,uuid,date,numeric,numeric,text,text,text,text)', 'execute')
        AND NOT has_function_privilege('authenticated', 'registrar_pago_factura(uuid,uuid,date,numeric,numeric,text,text,text,text)', 'execute')
        AND has_function_privilege('service_role', 'registrar_pago_factura(uuid,uuid,date,numeric,numeric,text,text,text,text)', 'execute')
        -- anular_pago_factura
        AND NOT has_function_privilege('anon', 'anular_pago_factura(uuid,uuid,text)', 'execute')
        AND NOT has_function_privilege('authenticated', 'anular_pago_factura(uuid,uuid,text)', 'execute')
        AND has_function_privilege('service_role', 'anular_pago_factura(uuid,uuid,text)', 'execute')
        AS funciones_seguras_ok
)

SELECT 
    t.tablas_ok,
    cp.cols_prov_ok,
    i.indices_ok,
    r.rls_ok,
    v.vista_ok,
    f.funciones_seguras_ok,
    (t.tablas_ok AND cp.cols_prov_ok AND i.indices_ok AND r.rls_ok AND v.vista_ok AND f.funciones_seguras_ok) AS todo_ok
FROM chk_tablas t
CROSS JOIN chk_cols_proveedores cp
CROSS JOIN chk_indices i
CROSS JOIN chk_rls r
CROSS JOIN chk_vista v
CROSS JOIN chk_funciones f;
