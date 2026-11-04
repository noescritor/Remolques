-- Verificación de Esquema T6: Editor de Recetas y Clonación
-- Ejecutar en SQL Editor de Supabase para confirmar todo en verde

WITH checks AS (
    SELECT
        EXISTS (
            SELECT 1 FROM information_schema.tables 
            WHERE table_schema = 'public' AND table_name = 'receta_base_historial'
        ) AS historial_existe,

        EXISTS (
            SELECT 1 FROM pg_tables 
            WHERE schemaname = 'public' AND tablename = 'receta_base_historial' AND rowsecurity = true
        ) AS rls_activo,

        EXISTS (
            SELECT 1 FROM pg_proc p 
            JOIN pg_namespace n ON n.oid = p.pronamespace 
            WHERE n.nspname = 'public' AND p.proname = 'clonar_receta_modelo' AND p.prosecdef = true
        ) AS fn_clonar_existe,

        EXISTS (
            SELECT 1 FROM pg_proc p 
            JOIN pg_namespace n ON n.oid = p.pronamespace 
            WHERE n.nspname = 'public' AND p.proname = 'guardar_linea_receta' AND p.prosecdef = true
        ) AS fn_guardar_existe,

        EXISTS (
            SELECT 1 FROM pg_proc p 
            JOIN pg_namespace n ON n.oid = p.pronamespace 
            WHERE n.nspname = 'public' AND p.proname = 'eliminar_linea_receta' AND p.prosecdef = true
        ) AS fn_eliminar_existe,

        (
            SELECT count(*) FROM pg_policies 
            WHERE schemaname = 'public' AND tablename = 'receta_base_historial' AND cmd != 'SELECT'
        ) AS politicas_no_select
)
SELECT
    historial_existe,
    rls_activo,
    fn_clonar_existe,
    fn_guardar_existe,
    fn_eliminar_existe,
    politicas_no_select,
    (historial_existe AND rls_activo AND fn_clonar_existe AND fn_guardar_existe AND fn_eliminar_existe AND politicas_no_select = 0) AS todo_ok
FROM checks;
