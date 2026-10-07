-- ============================================================================
-- verificacion_2R1a.sql                  SOLO LECTURA (un solo SELECT)
-- Muestra el resumen de importación del catálogo de opciones (2R-1a).
-- ============================================================================

SELECT jsonb_build_object(
    'tablas_creadas', (
        SELECT count(*) FROM information_schema.tables 
        WHERE table_name IN ('modelos', 'grupos_configuracion', 'opciones_configuracion', 'opcion_componentes', 'receta_base', 'material_proveedores', 'parametros_costeo')
    ),
    'tablas_con_rls', (
        SELECT count(*) FROM pg_tables 
        WHERE tablename IN ('modelos', 'grupos_configuracion', 'opciones_configuracion', 'opcion_componentes', 'receta_base', 'material_proveedores', 'parametros_costeo')
        AND rowsecurity = true
    ),
    'grupos', (SELECT count(*) FROM grupos_configuracion),
    'opciones', (SELECT count(*) FROM opciones_configuracion),
    'opciones_sin_precio', (
        SELECT count(*) 
        FROM opciones_configuracion oc
        JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
        WHERE oc.precio_venta IS NULL 
        AND gc.nombre != 'Frente'
    ),
    'modelos', (SELECT count(*) FROM modelos WHERE tipo = 'plataforma'),
    'filas_receta_base', (SELECT count(*) FROM receta_base)
) AS verificacion_2R1a;
