-- Script de verificación para Sub-bloque 2R-14: Actualización masiva de precios
-- Un solo SELECT con columnas _ok calificadas con alias evaluando:
-- 1. Existencia de tablas precios_lotes y precios_lotes_items
-- 2. Existencia de funciones aplicar_lote_precios y revertir_lote_precios
-- 3. Políticas RLS activas en ambas tablas
-- 4. Índices creados
-- 5. Tablas vacías tras la migración inicial (0 lotes, 0 items)
-- 6. todo_ok: evaluación global en true

WITH
  check_tablas AS (
    SELECT
      (count(*) = 2) AS tablas_ok
    FROM information_schema.tables t
    WHERE t.table_schema = 'public'
      AND t.table_name IN ('precios_lotes', 'precios_lotes_items')
  ),
  check_funciones AS (
    SELECT
      (count(*) = 2) AS funciones_ok
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND p.proname IN ('aplicar_lote_precios', 'revertir_lote_precios')
  ),
  check_politicas AS (
    SELECT
      (
        count(*) FILTER (WHERE pol.policyname = 'org_precios_lotes_policy') = 1 AND
        count(*) FILTER (WHERE pol.policyname = 'org_precios_lotes_items_policy') = 1
      ) AS politicas_ok
    FROM pg_policies pol
    WHERE pol.schemaname = 'public'
      AND pol.tablename IN ('precios_lotes', 'precios_lotes_items')
  ),
  check_indices AS (
    SELECT
      (
        EXISTS (SELECT 1 FROM pg_indexes idx WHERE idx.schemaname = 'public' AND idx.tablename = 'precios_lotes' AND idx.indexname = 'idx_precios_lotes_org') AND
        EXISTS (SELECT 1 FROM pg_indexes idx WHERE idx.schemaname = 'public' AND idx.tablename = 'precios_lotes_items' AND idx.indexname = 'idx_precios_lotes_items_lote') AND
        EXISTS (SELECT 1 FROM pg_indexes idx WHERE idx.schemaname = 'public' AND idx.tablename = 'precios_lotes_items' AND idx.indexname = 'idx_precios_lotes_items_org')
      ) AS indices_ok
  ),
  check_conteo_inicial AS (
    SELECT
      (
        (SELECT count(*) FROM precios_lotes pl) = 0 AND
        (SELECT count(*) FROM precios_lotes_items pli) = 0
      ) AS lotes_inicial_vacio_ok
  )
SELECT
  ct.tablas_ok,
  cf.funciones_ok,
  cp.politicas_ok,
  ci.indices_ok,
  cci.lotes_inicial_vacio_ok,
  (
    ct.tablas_ok AND
    cf.funciones_ok AND
    cp.politicas_ok AND
    ci.indices_ok AND
    cci.lotes_inicial_vacio_ok
  ) AS todo_ok
FROM
  check_tablas ct,
  check_funciones cf,
  check_politicas cp,
  check_indices ci,
  check_conteo_inicial cci;
