-- ============================================================================
-- 01b_diagnostico_un_solo_resultado.sql        SOLO LECTURA (un solo SELECT)
-- El SQL Editor de Supabase muestra únicamente el resultado de la ÚLTIMA
-- consulta, por eso este script junta todo en UNA tabla de 7 filas.
-- Pegar el resultado completo (las 7 filas).
-- ============================================================================
SELECT n, chequeo, resultado FROM (

  SELECT 1 AS n, 'Productos por tipo' AS chequeo,
    coalesce((SELECT string_agg(coalesce(tipo_item, '(sin tipo)') || ': ' || c, ' | ' ORDER BY tipo_item)
              FROM (SELECT tipo_item, count(*)::text AS c FROM productos GROUP BY tipo_item) t), '(ninguno)') AS resultado

  UNION ALL
  SELECT 2, 'Organización de materiales y modelos',
    coalesce((SELECT string_agg(organizacion_id::text || ' -> ' || tipo_item || ': ' || c, ' | ')
              FROM (SELECT organizacion_id, tipo_item, count(*)::text AS c FROM productos
                    WHERE tipo_item IN ('materia_prima', 'producto_terminado') GROUP BY 1, 2) t), '(ninguno)')

  UNION ALL
  SELECT 3, 'Organización de las cotizaciones reales',
    coalesce((SELECT string_agg(organizacion_id::text || ': ' || c, ' | ')
              FROM (SELECT organizacion_id, count(*)::text AS c FROM cotizaciones GROUP BY 1) t), '(ninguno)')

  UNION ALL
  SELECT 4, 'Líneas de receta por producto terminado',
    coalesce((SELECT string_agg(nombre || ': ' || c, ' | ')
              FROM (SELECT p.nombre, count(pm.id)::text AS c
                    FROM productos p JOIN producto_materiales pm ON pm.producto_id = p.id
                    WHERE p.tipo_item = 'producto_terminado' GROUP BY p.nombre) t), '(ninguna)')

  UNION ALL
  SELECT 5, 'Plana 40 ft: ejes, rines y llantas en la receta',
    coalesce((SELECT string_agg(m.nombre || ' = ' || pm.cantidad::text, ' | ')
              FROM producto_materiales pm
              JOIN productos p ON p.id = pm.producto_id
              JOIN productos m ON m.id = pm.material_id
              WHERE p.nombre = 'PLANA 40 FT 2 EJES CON RETRACTIL'
                AND (m.nombre ILIKE 'EJE %' OR m.nombre ILIKE 'RIN %' OR m.nombre ILIKE 'LLANTA %')), '(ninguno)')

  UNION ALL
  SELECT 6, 'Índices únicos en productos',
    coalesce((SELECT string_agg(indexdef, ' || ') FROM pg_indexes
              WHERE schemaname = 'public' AND tablename = 'productos' AND indexdef ILIKE '%UNIQUE%'), '(ninguno)')

  UNION ALL
  SELECT 7, 'Cotizaciones y compras desde 2026-10-01',
    (SELECT count(*)::text FROM cotizaciones WHERE created_at >= '2026-10-01') || ' cotizaciones | '
    || (SELECT count(*)::text FROM compras_proveedor WHERE created_at >= '2026-10-01') || ' compras'

) x
ORDER BY n;
