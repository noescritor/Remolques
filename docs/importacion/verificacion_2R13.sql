-- Script de verificación para Sub-bloque 2R-13: calculadoras de acero
-- Un solo SELECT con columnas _ok que evalúan:
-- 1. 38 materiales sembrados con notas 'import-2r13' y activo = true
-- 2. 76 precios sembrados con notas 'import-2r13' e incluye_iva = true
-- 3. Los 6 proveedores presentes (TANOS, FORTACERO, SERVIACERO, PIRAMIDE, TPI, REFERENCIA)
-- 4. Historial vacío tras la migración inicial (0 filas)
-- 5. Índices / restricciones únicas existentes para evitar duplicados
-- 6. todo_ok: evaluación global en true

WITH
  check_materiales AS (
    SELECT
      (count(*) = 38) AS total_materiales_ok,
      bool_and(am.notas = 'import-2r13') AS notas_materiales_ok,
      bool_and(am.activo = true) AS activo_materiales_ok,
      (count(DISTINCT am.tipo) = 8) AS tipos_completos_ok
    FROM acero_materiales am
    WHERE am.notas = 'import-2r13'
  ),
  check_precios AS (
    SELECT
      (count(*) = 76) AS total_precios_ok,
      bool_and(ap.notas = 'import-2r13') AS notas_precios_ok,
      bool_and(ap.incluye_iva = true) AS incluye_iva_ok,
      (count(DISTINCT ap.proveedor) = 6) AS total_proveedores_ok,
      bool_and(ap.precio > 0) AS precios_positivos_ok
    FROM acero_precios ap
    WHERE ap.notas = 'import-2r13'
  ),
  check_historial AS (
    SELECT
      (count(*) = 0) AS historial_vacio_ok
    FROM acero_precios_historial aph
  ),
  check_proveedores_especificos AS (
    SELECT
      (
        count(DISTINCT ap.proveedor) FILTER (WHERE ap.proveedor = 'TANOS') = 1 AND
        count(DISTINCT ap.proveedor) FILTER (WHERE ap.proveedor = 'FORTACERO') = 1 AND
        count(DISTINCT ap.proveedor) FILTER (WHERE ap.proveedor = 'SERVIACERO') = 1 AND
        count(DISTINCT ap.proveedor) FILTER (WHERE ap.proveedor = 'PIRAMIDE') = 1 AND
        count(DISTINCT ap.proveedor) FILTER (WHERE ap.proveedor = 'TPI') = 1 AND
        count(DISTINCT ap.proveedor) FILTER (WHERE ap.proveedor = 'REFERENCIA (Excel costeo)') = 1
      ) AS proveedores_esperados_ok
    FROM acero_precios ap
    WHERE ap.notas = 'import-2r13'
  ),
  check_indices AS (
    SELECT
      (
        EXISTS (
          SELECT 1 FROM pg_constraint c
          JOIN pg_class t ON c.conrelid = t.oid
          WHERE t.relname = 'acero_materiales' AND c.contype = 'u'
        ) AND
        EXISTS (
          SELECT 1 FROM pg_constraint c
          JOIN pg_class t ON c.conrelid = t.oid
          WHERE t.relname = 'acero_precios' AND c.contype = 'u'
        )
      ) AS restricciones_unicas_ok
  )
SELECT
  cm.total_materiales_ok,
  cm.notas_materiales_ok,
  cm.activo_materiales_ok,
  cm.tipos_completos_ok,
  cp.total_precios_ok,
  cp.notas_precios_ok,
  cp.incluye_iva_ok,
  cp.total_proveedores_ok,
  cp.precios_positivos_ok,
  cpe.proveedores_esperados_ok,
  ch.historial_vacio_ok,
  ci.restricciones_unicas_ok,
  (
    cm.total_materiales_ok AND
    cm.notas_materiales_ok AND
    cm.activo_materiales_ok AND
    cm.tipos_completos_ok AND
    cp.total_precios_ok AND
    cp.notas_precios_ok AND
    cp.incluye_iva_ok AND
    cp.total_proveedores_ok AND
    cp.precios_positivos_ok AND
    cpe.proveedores_esperados_ok AND
    ch.historial_vacio_ok AND
    ci.restricciones_unicas_ok
  ) AS todo_ok
FROM
  check_materiales cm,
  check_precios cp,
  check_proveedores_especificos cpe,
  check_historial ch,
  check_indices ci;
