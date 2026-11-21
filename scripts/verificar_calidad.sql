-- Verificador SQL de solo lectura para Calidad (Parte 1)
-- Valida plantillas semilla, conteos de grupos/ítems, unicidad de activa, RLS en 6 tablas y hashes de precios.

WITH plantillas AS (
    SELECT
        p.id,
        p.organizacion_id,
        p.formato,
        p.estado,
        lp.clave AS linea_clave,
        (SELECT COUNT(*) FROM calidad_plantilla_grupos g WHERE g.plantilla_id = p.id) AS num_grupos,
        (SELECT COUNT(*) FROM calidad_plantilla_items i WHERE i.plantilla_id = p.id) AS num_items
    FROM calidad_plantillas p
    JOIN lineas_producto lp ON lp.id = p.linea_producto_id
),
activas_por_clave AS (
    SELECT organizacion_id, linea_clave, formato, COUNT(*) AS cnt
    FROM plantillas
    WHERE estado = 'activa'
    GROUP BY organizacion_id, linea_clave, formato
),
rls_tablas AS (
    SELECT c.relname, c.relrowsecurity
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public'
      AND c.relname IN (
          'calidad_plantillas',
          'calidad_plantilla_grupos',
          'calidad_plantilla_items',
          'orden_calidad_inspecciones',
          'orden_calidad_resultados',
          'calidad_folios'
      )
),
checks AS (
    SELECT
        (SELECT COUNT(*) = 5 FROM plantillas WHERE estado = 'activa') AS plantillas_activas_5_ok,
        (SELECT COUNT(*) = 1 AND MIN(num_grupos) = 13 AND MIN(num_items) = 116
         FROM plantillas WHERE formato = 'control_total' AND linea_clave = 'plataforma' AND estado = 'activa') AS ct_plataforma_ok,
        (
            COALESCE((SELECT num_items = 57 FROM plantillas WHERE formato = 'entrega' AND linea_clave = 'plataforma' AND estado = 'activa' LIMIT 1), false)
            AND COALESCE((SELECT num_items = 52 FROM plantillas WHERE formato = 'entrega' AND linea_clave = 'gondola' AND estado = 'activa' LIMIT 1), false)
            AND COALESCE((SELECT num_items = 28 FROM plantillas WHERE formato = 'entrega' AND linea_clave = 'dolly' AND estado = 'activa' LIMIT 1), false)
            AND COALESCE((SELECT num_items = 39 FROM plantillas WHERE formato = 'entrega' AND linea_clave = 'cama_baja' AND estado = 'activa' LIMIT 1), false)
        ) AS entrega_items_ok,
        (SELECT NOT EXISTS (SELECT 1 FROM activas_por_clave WHERE cnt > 1)) AS una_activa_por_linea_fmt_ok,
        (SELECT COUNT(*) = 6 AND bool_and(relrowsecurity) FROM rls_tablas) AS rls_6_tablas_ok,
        (SELECT md5(COALESCE(string_agg(t::text, '|' ORDER BY id), '')) FROM receta_base t) AS md5_receta_base,
        (SELECT md5(COALESCE(string_agg(t::text, '|' ORDER BY id), '')) FROM costos_modelo t) AS md5_costos_modelo,
        (SELECT md5(COALESCE(string_agg(t::text, '|' ORDER BY id), '')) FROM procesos_manufactura t) AS md5_procesos_manufactura,
        (SELECT md5(COALESCE(string_agg(t::text, '|' ORDER BY id), '')) FROM opcion_costos t) AS md5_opcion_costos,
        (SELECT md5(COALESCE(string_agg(t::text, '|' ORDER BY id), '')) FROM productos t) AS md5_productos
)
SELECT
    *,
    (
        plantillas_activas_5_ok
        AND ct_plataforma_ok
        AND entrega_items_ok
        AND una_activa_por_linea_fmt_ok
        AND rls_6_tablas_ok
    ) AS todo_ok
FROM checks;
