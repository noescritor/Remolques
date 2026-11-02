-- Verificación de Esquema T6: Editor de Recetas y Clonación
-- Ejecutar en SQL Editor de Supabase para confirmar todo en verde

DO $$
DECLARE
    v_historial_ok BOOLEAN := false;
    v_rls_ok BOOLEAN := false;
    v_fn_clonar_ok BOOLEAN := false;
    v_fn_guardar_ok BOOLEAN := false;
    v_fn_eliminar_ok BOOLEAN := false;
    v_todo_ok BOOLEAN := false;
BEGIN
    -- 1. Tabla receta_base_historial
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_name = 'receta_base_historial'
    ) INTO v_historial_ok;

    -- 2. RLS habilitado
    SELECT EXISTS (
        SELECT 1 FROM pg_tables 
        WHERE schemaname = 'public' AND tablename = 'receta_base_historial' AND rowsecurity = true
    ) INTO v_rls_ok;

    -- 3. Funciones RPC
    SELECT EXISTS (
        SELECT 1 FROM pg_proc p 
        JOIN pg_namespace n ON n.oid = p.pronamespace 
        WHERE n.nspname = 'public' AND p.proname = 'clonar_receta_modelo' AND p.prosecdef = true
    ) INTO v_fn_clonar_ok;

    SELECT EXISTS (
        SELECT 1 FROM pg_proc p 
        JOIN pg_namespace n ON n.oid = p.pronamespace 
        WHERE n.nspname = 'public' AND p.proname = 'guardar_linea_receta' AND p.prosecdef = true
    ) INTO v_fn_guardar_ok;

    SELECT EXISTS (
        SELECT 1 FROM pg_proc p 
        JOIN pg_namespace n ON n.oid = p.pronamespace 
        WHERE n.nspname = 'public' AND p.proname = 'eliminar_linea_receta' AND p.prosecdef = true
    ) INTO v_fn_eliminar_ok;

    v_todo_ok := v_historial_ok AND v_rls_ok AND v_fn_clonar_ok AND v_fn_guardar_ok AND v_fn_eliminar_ok;

    RAISE NOTICE '=== VERIFICACION T6: EDITOR DE RECETAS ===';
    RAISE NOTICE 'Tabla receta_base_historial: %', v_historial_ok;
    RAISE NOTICE 'RLS en receta_base_historial: %', v_rls_ok;
    RAISE NOTICE 'RPC clonar_receta_modelo: %', v_fn_clonar_ok;
    RAISE NOTICE 'RPC guardar_linea_receta: %', v_fn_guardar_ok;
    RAISE NOTICE 'RPC eliminar_linea_receta: %', v_fn_eliminar_ok;
    RAISE NOTICE 'TODO OK: %', v_todo_ok;

    IF NOT v_todo_ok THEN
        RAISE EXCEPTION 'Verificación T6 falló. Uno o más componentes no están presentes.';
    END IF;
END $$;
