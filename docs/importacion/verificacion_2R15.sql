-- Verificación de migración Sub-bloque 2R-15: Plan semanal de producción
-- Comprueba:
-- 1. Existencia de las 7 tablas del esquema
-- 2. Existencia de índices clave e índices únicos case-insensitive
-- 3. Políticas RLS habilitadas en las 7 tablas
-- 4. Existencia de las 3 funciones SQL seguras
-- 5. Restricción estricta de permisos EXECUTE (anon/authenticated sin acceso, service_role con acceso)
-- 6. Conteos de áreas (5) y frentes (23) por organización
-- 7. todo_ok: evaluación global en true

WITH
  check_tablas AS (
    SELECT
      (
        EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'operarios') AND
        EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'produccion_areas') AND
        EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'produccion_frentes') AND
        EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'plan_tareas') AND
        EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'plan_tarea_operarios') AND
        EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'plan_tarea_materiales') AND
        EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'plan_tareas_historial')
      ) AS tablas_ok
  ),
  check_indices AS (
    SELECT
      (
        EXISTS (SELECT 1 FROM pg_indexes idx WHERE idx.schemaname = 'public' AND idx.tablename = 'operarios' AND idx.indexname = 'uq_operarios_org_nombre_ci') AND
        EXISTS (SELECT 1 FROM pg_indexes idx WHERE idx.schemaname = 'public' AND idx.tablename = 'produccion_areas' AND idx.indexname = 'uq_produccion_areas_org_clave') AND
        EXISTS (SELECT 1 FROM pg_indexes idx WHERE idx.schemaname = 'public' AND idx.tablename = 'produccion_frentes' AND idx.indexname = 'uq_produccion_frentes_area_nombre') AND
        EXISTS (SELECT 1 FROM pg_indexes idx WHERE idx.schemaname = 'public' AND idx.tablename = 'plan_tareas' AND idx.indexname = 'idx_plan_tareas_org_fecha') AND
        EXISTS (SELECT 1 FROM pg_indexes idx WHERE idx.schemaname = 'public' AND idx.tablename = 'plan_tarea_operarios' AND idx.indexname = 'idx_plan_tarea_operarios_operario') AND
        EXISTS (SELECT 1 FROM pg_indexes idx WHERE idx.schemaname = 'public' AND idx.tablename = 'plan_tarea_materiales' AND idx.indexname = 'idx_plan_tarea_mat_tarea') AND
        EXISTS (SELECT 1 FROM pg_indexes idx WHERE idx.schemaname = 'public' AND idx.tablename = 'plan_tareas_historial' AND idx.indexname = 'idx_plan_historial_creado')
      ) AS indices_ok
  ),
  check_politicas AS (
    SELECT
      (
        EXISTS (SELECT 1 FROM pg_policies pol WHERE pol.schemaname = 'public' AND pol.tablename = 'operarios' AND pol.policyname = 'org_operarios_policy') AND
        EXISTS (SELECT 1 FROM pg_policies pol WHERE pol.schemaname = 'public' AND pol.tablename = 'produccion_areas' AND pol.policyname = 'org_produccion_areas_policy') AND
        EXISTS (SELECT 1 FROM pg_policies pol WHERE pol.schemaname = 'public' AND pol.tablename = 'produccion_frentes' AND pol.policyname = 'org_produccion_frentes_policy') AND
        EXISTS (SELECT 1 FROM pg_policies pol WHERE pol.schemaname = 'public' AND pol.tablename = 'plan_tareas' AND pol.policyname = 'org_plan_tareas_policy') AND
        EXISTS (SELECT 1 FROM pg_policies pol WHERE pol.schemaname = 'public' AND pol.tablename = 'plan_tarea_operarios' AND pol.policyname = 'org_plan_tarea_operarios_policy') AND
        EXISTS (SELECT 1 FROM pg_policies pol WHERE pol.schemaname = 'public' AND pol.tablename = 'plan_tarea_materiales' AND pol.policyname = 'org_plan_tarea_materiales_policy') AND
        EXISTS (SELECT 1 FROM pg_policies pol WHERE pol.schemaname = 'public' AND pol.tablename = 'plan_tareas_historial' AND pol.policyname = 'org_plan_tareas_historial_policy')
      ) AS politicas_ok
  ),
  check_funciones AS (
    SELECT
      (
        EXISTS (SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname = 'public' AND p.proname = 'guardar_plan_tarea') AND
        EXISTS (SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname = 'public' AND p.proname = 'cambiar_estado_plan_tarea') AND
        EXISTS (SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname = 'public' AND p.proname = 'eliminar_plan_tarea')
      ) AS funciones_ok
  ),
  check_permisos AS (
    SELECT
      (
        -- guardar_plan_tarea
        NOT has_function_privilege('anon', 'public.guardar_plan_tarea(uuid,uuid,uuid,date,uuid,uuid,text,text,text,boolean,text,uuid[],jsonb)', 'EXECUTE') AND
        NOT has_function_privilege('authenticated', 'public.guardar_plan_tarea(uuid,uuid,uuid,date,uuid,uuid,text,text,text,boolean,text,uuid[],jsonb)', 'EXECUTE') AND
        has_function_privilege('service_role', 'public.guardar_plan_tarea(uuid,uuid,uuid,date,uuid,uuid,text,text,text,boolean,text,uuid[],jsonb)', 'EXECUTE') AND
        -- cambiar_estado_plan_tarea
        NOT has_function_privilege('anon', 'public.cambiar_estado_plan_tarea(uuid,uuid,uuid,text,timestamptz,timestamptz)', 'EXECUTE') AND
        NOT has_function_privilege('authenticated', 'public.cambiar_estado_plan_tarea(uuid,uuid,uuid,text,timestamptz,timestamptz)', 'EXECUTE') AND
        has_function_privilege('service_role', 'public.cambiar_estado_plan_tarea(uuid,uuid,uuid,text,timestamptz,timestamptz)', 'EXECUTE') AND
        -- eliminar_plan_tarea
        NOT has_function_privilege('anon', 'public.eliminar_plan_tarea(uuid,uuid,uuid)', 'EXECUTE') AND
        NOT has_function_privilege('authenticated', 'public.eliminar_plan_tarea(uuid,uuid,uuid)', 'EXECUTE') AND
        has_function_privilege('service_role', 'public.eliminar_plan_tarea(uuid,uuid,uuid)', 'EXECUTE')
      ) AS permisos_funciones_ok
  ),
  check_seed AS (
    SELECT
      (
        -- Cada organización debe tener al menos 5 áreas y 23 frentes
        COALESCE(bool_and(areas_cnt >= 5), false) AND
        COALESCE(bool_and(frentes_cnt >= 23), false)
      ) AS seed_areas_frentes_ok
    FROM (
      SELECT
        o.id,
        count(DISTINCT a.id) AS areas_cnt,
        count(DISTINCT f.id) AS frentes_cnt
      FROM organizaciones o
      LEFT JOIN produccion_areas a ON a.organizacion_id = o.id
      LEFT JOIN produccion_frentes f ON f.organizacion_id = o.id
      GROUP BY o.id
    ) conteos_org
  )
SELECT
  ct.tablas_ok,
  ci.indices_ok,
  cp.politicas_ok,
  cf.funciones_ok,
  cperm.permisos_funciones_ok,
  cs.seed_areas_frentes_ok,
  (
    ct.tablas_ok AND
    ci.indices_ok AND
    cp.politicas_ok AND
    cf.funciones_ok AND
    cperm.permisos_funciones_ok AND
    cs.seed_areas_frentes_ok
  ) AS todo_ok
FROM
  check_tablas ct,
  check_indices ci,
  check_politicas cp,
  check_funciones cf,
  check_permisos cperm,
  check_seed cs;
