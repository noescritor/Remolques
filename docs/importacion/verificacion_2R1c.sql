-- Verificación del Sub-bloque 2R-1c (un solo SELECT)
-- Devuelve una fila con el resumen de control de las tablas, costos y mano de obra importados.

WITH tablas AS (
    SELECT count(*)::int AS tablas_nuevas_creadas
    FROM information_schema.tables 
    WHERE table_schema = 'public' 
      AND table_name IN ('opcion_costos', 'procesos_manufactura', 'costos_modelo')
),
modelo_ref AS (
    SELECT id 
    FROM modelos 
    WHERE tipo = 'plataforma' AND largo_ft = 40 AND num_ejes = 2
    LIMIT 1
),
acero_receta AS (
    SELECT 
        count(*)::int AS renglones_receta_acero,
        round(coalesce(sum(rb.cantidad * p.costo), 0), 2) AS costo_acero,
        count(CASE WHEN p.costo = 0 OR p.costo IS NULL OR p.descripcion = 'SIN PRECIO' THEN 1 END)::int AS materiales_acero_sin_precio
    FROM receta_base rb
    JOIN productos p ON rb.material_id = p.id
    WHERE rb.modelo_id = (SELECT id FROM modelo_ref)
      AND rb.seccion = 'acero'
      AND rb.notas = 'import-2r1c'
),
materiales_acero AS (
    SELECT count(DISTINCT rb.material_id)::int AS materiales_acero_nuevos
    FROM receta_base rb
    WHERE rb.modelo_id = (SELECT id FROM modelo_ref)
      AND rb.seccion = 'acero'
      AND rb.notas = 'import-2r1c'
),
costos_mod AS (
    SELECT round(coalesce(sum(cantidad * costo_unitario), 0), 2) AS suma_costos_modelo
    FROM costos_modelo
    WHERE modelo_id = (SELECT id FROM modelo_ref)
      AND (notas LIKE '%import-2r1c%' OR fuente = 'Factura Leolca')
),
procesos AS (
    SELECT 
        count(*)::int AS renglones_procesos_manufactura,
        round(coalesce(sum(minutos * tarifa_hora / 60.0), 0), 2) AS suma_mano_obra
    FROM procesos_manufactura
    WHERE modelo_id = (SELECT id FROM modelo_ref)
      AND notas = 'import-2r1c'
),
opciones AS (
    SELECT count(*)::int AS renglones_opcion_costos
    FROM opcion_costos
    WHERE tipo_modelo = 'plataforma'
      AND notas = 'import-2r1c'
),
ganancia AS (
    SELECT (valor IS NOT NULL) AS ganancia_factura_presente
    FROM parametros_costeo
    WHERE clave = 'ganancia_factura'
    LIMIT 1
)
SELECT 
    t.tablas_nuevas_creadas,
    ma.materiales_acero_nuevos,
    ar.renglones_receta_acero,
    ar.costo_acero,
    ar.materiales_acero_sin_precio,
    cm.suma_costos_modelo,
    pr.renglones_procesos_manufactura,
    pr.suma_mano_obra,
    op.renglones_opcion_costos,
    coalesce(g.ganancia_factura_presente, false) AS ganancia_factura_presente,
    round(ar.costo_acero + cm.suma_costos_modelo + 20000.00 + pr.suma_mano_obra, 2) AS suma_control_base
FROM tablas t
CROSS JOIN materiales_acero ma
CROSS JOIN acero_receta ar
CROSS JOIN costos_mod cm
CROSS JOIN procesos pr
CROSS JOIN opciones op
LEFT JOIN ganancia g ON true;
