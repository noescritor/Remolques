-- Verificación del Sub-bloque 2R-1d (un solo SELECT)
-- Devuelve una fila por cada modelo destino (8) y una fila final de totales y control del origen.

WITH origen AS (
    SELECT id, largo_ft, num_ejes
    FROM modelos
    WHERE tipo = 'plataforma' AND largo_ft = 40 AND num_ejes = 2
    LIMIT 1
),
control_origen AS (
    SELECT
        round(coalesce(sum(rb.cantidad * p.costo), 0), 2) AS origen_costo_acero,
        (SELECT round(coalesce(sum(cantidad * costo_unitario), 0), 2) FROM costos_modelo WHERE modelo_id = (SELECT id FROM origen)) AS origen_costos_modelo,
        (SELECT round(coalesce(sum(minutos * tarifa_hora / 60.0), 0), 2) FROM procesos_manufactura WHERE modelo_id = (SELECT id FROM origen)) AS origen_mano_obra
    FROM receta_base rb
    JOIN productos p ON rb.material_id = p.id
    WHERE rb.modelo_id = (SELECT id FROM origen)
      AND rb.seccion = 'acero'
),
cargador_prod AS (
    SELECT id
    FROM productos
    WHERE nombre = 'CARGADOR (IPR DE 4")' AND tipo_item = 'materia_prima'
    LIMIT 1
),
destinos AS (
    SELECT
        m.id,
        coalesce(p.nombre, 'PLATAFORMA ' || m.num_ejes || ' ' || m.largo_ft || ' FT') AS modelo_nombre,
        m.largo_ft,
        m.num_ejes,
        m.costos_derivados_de
    FROM modelos m
    LEFT JOIN productos p ON m.producto_id = p.id
    WHERE m.tipo = 'plataforma'
      AND NOT (m.largo_ft = 40 AND m.num_ejes = 2) -- excluir origen 40/2
      AND NOT (m.largo_ft = 43 AND m.num_ejes = 3) -- excluir 43/3 omitido
    ORDER BY m.largo_ft, m.num_ejes
),
filas_destinos AS (
    SELECT
        1 AS orden_sort,
        'DESTINO'::text AS tipo_registro,
        d.modelo_nombre,
        d.largo_ft,
        d.num_ejes,
        (SELECT count(*)::int FROM receta_base rb WHERE rb.modelo_id = d.id AND rb.seccion = 'acero' AND rb.notas = 'import-2r1d') AS renglones_acero,
        (SELECT coalesce(sum(rb.cantidad), 0)::int FROM receta_base rb WHERE rb.modelo_id = d.id AND rb.material_id = (SELECT id FROM cargador_prod) AND rb.notas = 'import-2r1d') AS cargadores,
        (SELECT count(*)::int FROM costos_modelo cm WHERE cm.modelo_id = d.id AND cm.notas = 'import-2r1d') AS kits,
        (SELECT count(*)::int FROM procesos_manufactura pm WHERE pm.modelo_id = d.id AND pm.notas = 'import-2r1d') AS procesos,
        (d.costos_derivados_de = (SELECT id FROM origen)) AS costos_derivados_de_ok,
        (
            (SELECT count(*)::int FROM receta_base rb WHERE rb.modelo_id = d.id AND rb.notas = 'import-2r1d') +
            (SELECT count(*)::int FROM costos_modelo cm WHERE cm.modelo_id = d.id AND cm.notas = 'import-2r1d') +
            (SELECT count(*)::int FROM procesos_manufactura pm WHERE pm.modelo_id = d.id AND pm.notas = 'import-2r1d')
        ) AS renglones_nuevos_modelo,
        NULL::numeric AS origen_40_2_costo_acero,
        NULL::numeric AS origen_40_2_costos_modelo,
        NULL::numeric AS origen_40_2_mano_obra
    FROM destinos d
),
fila_totales AS (
    SELECT
        2 AS orden_sort,
        'TOTALES'::text AS tipo_registro,
        'TOTAL / RESUMEN CONTROL (8 MODELOS)'::text AS modelo_nombre,
        NULL::int AS largo_ft,
        NULL::int AS num_ejes,
        sum(fd.renglones_acero)::int AS renglones_acero,
        sum(fd.cargadores)::int AS cargadores,
        sum(fd.kits)::int AS kits,
        sum(fd.procesos)::int AS procesos,
        bool_and(fd.costos_derivados_de_ok) AS costos_derivados_de_ok,
        sum(fd.renglones_nuevos_modelo)::int AS renglones_nuevos_modelo,
        (SELECT origen_costo_acero FROM control_origen) AS origen_40_2_costo_acero,
        (SELECT origen_costos_modelo FROM control_origen) AS origen_40_2_costos_modelo,
        (SELECT origen_mano_obra FROM control_origen) AS origen_40_2_mano_obra
    FROM filas_destinos fd
)
SELECT
    tipo_registro,
    modelo_nombre,
    largo_ft,
    num_ejes,
    renglones_acero,
    cargadores,
    kits,
    procesos,
    costos_derivados_de_ok,
    renglones_nuevos_modelo,
    origen_40_2_costo_acero,
    origen_40_2_costos_modelo,
    origen_40_2_mano_obra
FROM (
    SELECT * FROM filas_destinos
    UNION ALL
    SELECT * FROM fila_totales
) q
ORDER BY orden_sort, largo_ft, num_ejes;
