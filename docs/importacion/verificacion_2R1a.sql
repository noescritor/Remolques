-- ============================================================================
-- verificacion_2R1a.sql                  SOLO LECTURA (un solo SELECT)
-- Muestra el resumen de importación del catálogo de opciones (2R-1a).
-- ============================================================================

SELECT jsonb_build_object(
    'tablas_creadas', (
        SELECT count(*) FROM information_schema.tables 
        WHERE table_name IN ('modelos', 'grupos_configuracion', 'opciones_configuracion', 'opcion_componentes', 'receta_base', 'material_proveedores', 'parametros_costeo')
        AND table_schema = 'public'
    ),
    'tablas_con_rls', (
        SELECT count(*) FROM pg_tables 
        WHERE tablename IN ('modelos', 'grupos_configuracion', 'opciones_configuracion', 'opcion_componentes', 'receta_base', 'material_proveedores', 'parametros_costeo')
        AND schemaname = 'public' AND rowsecurity = true
    ),
    'grupos', (SELECT count(*) FROM grupos_configuracion),
    'opciones', (SELECT count(*) FROM opciones_configuracion),
    'opciones_sin_precio_total', (
        SELECT count(*) 
        FROM opciones_configuracion
        WHERE precio_venta IS NULL
    ),
    'opciones_sin_precio_ni_medidas', (
        SELECT count(*) 
        FROM opciones_configuracion
        WHERE precio_venta IS NULL AND (medidas IS NULL OR medidas = '{}'::jsonb)
    ),
    'modelos', (SELECT count(*) FROM modelos WHERE tipo = 'plataforma'),
    'filas_receta_base', (SELECT count(*) FROM receta_base),
    'funcion_org_intacta', (
        SELECT position('perfiles_organizacion' in pg_get_functiondef(oid)) > 0 
        FROM pg_proc 
        WHERE proname = 'get_current_org_id'
    )
) AS verificacion_2R1a;
