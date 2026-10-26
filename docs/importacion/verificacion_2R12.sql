-- Script de verificación para Sub-bloque 2R-12: ajustes al cotizador
-- Un solo SELECT con columnas _ok que evalúan:
-- 1. retractil/paleta desactivada
-- 2. piso/plastico_negro desactivado
-- 3. regla de retractil con por_num_ejes
-- 4. pintura desactivada con aplica_a vacío
-- 5. color/personalizado existe y activo
-- 6. costo de retractil/grande en gondola y dolly
-- 7. conteos globales para confirmar que no se borraron filas

WITH
  check_retractil AS (
    SELECT
      (regla = '{"max_total":{"por_num_ejes":{"2":1,"3":2}},"cantidad_defecto":1}'::jsonb) AS regla_retractil_ok,
      (notas = 'import-2r12') AS notas_retractil_ok
    FROM grupos_configuracion
    WHERE clave = 'retractil'
    LIMIT 1
  ),
  check_pintura AS (
    SELECT
      (aplica_a = '{}'::text[]) AS pintura_desactivada_ok,
      (notas = 'import-2r12') AS notas_pintura_ok
    FROM grupos_configuracion
    WHERE clave = 'pintura'
    LIMIT 1
  ),
  check_paleta AS (
    SELECT
      (activo = false) AS paleta_desactivada_ok,
      (notas = 'import-2r12') AS notas_paleta_ok
    FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'retractil' AND oc.clave = 'paleta'
    LIMIT 1
  ),
  check_plastico_negro AS (
    SELECT
      (activo = false) AS plastico_negro_desactivado_ok,
      (notas = 'import-2r12') AS notas_piso_ok
    FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'piso' AND oc.clave = 'plastico_negro'
    LIMIT 1
  ),
  check_personalizado AS (
    SELECT
      (count(*) > 0 AND bool_and(oc.activo = true) AND bool_and(oc.precio_venta = 0)) AS color_personalizado_existe_ok
    FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'color' AND oc.clave = 'personalizado'
  ),
  check_costos_grande AS (
    SELECT
      bool_and(CASE WHEN ocst.tipo_modelo = 'gondola' THEN ocst.costo_unitario = 15000 ELSE true END) AS costo_grande_gondola_ok,
      bool_and(CASE WHEN ocst.tipo_modelo = 'dolly' THEN ocst.costo_unitario = 8200 ELSE true END) AS costo_grande_dolly_ok
    FROM opcion_costos ocst
    JOIN opciones_configuracion oc ON ocst.opcion_id = oc.id
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'retractil' AND oc.clave = 'grande'
  ),
  conteos AS (
    SELECT
      (SELECT count(*) FROM grupos_configuracion) AS total_grupos,
      (SELECT count(*) FROM opciones_configuracion) AS total_opciones
  )
SELECT
  cr.regla_retractil_ok,
  cr.notas_retractil_ok,
  cp.pintura_desactivada_ok,
  cp.notas_pintura_ok,
  cpa.paleta_desactivada_ok,
  cpa.notas_paleta_ok,
  cpn.plastico_negro_desactivado_ok,
  cpn.notas_piso_ok,
  cpers.color_personalizado_existe_ok,
  cg.costo_grande_gondola_ok,
  cg.costo_grande_dolly_ok,
  cnt.total_grupos,
  cnt.total_opciones,
  (
    cr.regla_retractil_ok AND
    cp.pintura_desactivada_ok AND
    cpa.paleta_desactivada_ok AND
    cpn.plastico_negro_desactivado_ok AND
    cpers.color_personalizado_existe_ok AND
    cg.costo_grande_gondola_ok AND
    cg.costo_grande_dolly_ok
  ) AS todo_ok
FROM
  check_retractil cr,
  check_pintura cp,
  check_paleta cpa,
  check_plastico_negro cpn,
  check_personalizado cpers,
  check_costos_grande cg,
  conteos cnt;
