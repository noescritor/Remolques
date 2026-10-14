-- Verificación del Sub-bloque 2R-1e: El Dolly (un solo SELECT)
-- Devuelve una fila de resumen de control para el modelo Dolly 2 ejes y verifica la integridad de la Plataforma 40/2.

WITH modelo_dolly AS (
    SELECT id, tipo, largo_ft, num_ejes
    FROM modelos
    WHERE tipo = 'dolly'
    LIMIT 1
),
control_dolly AS (
    SELECT
        (SELECT count(*)::int FROM modelos WHERE tipo = 'dolly') AS modelos_dolly_total,
        (SELECT count(*)::int FROM productos WHERE nombre = 'DOLLY 2 EJES' AND tipo_item = 'producto_terminado') AS producto_terminado_dolly,
        (SELECT count(DISTINCT rb.material_id)::int FROM receta_base rb WHERE rb.modelo_id = (SELECT id FROM modelo_dolly) AND rb.seccion = 'acero' AND rb.notas = 'import-2r1e') AS materiales_acero_propios,
        (SELECT count(*)::int FROM receta_base rb WHERE rb.modelo_id = (SELECT id FROM modelo_dolly) AND rb.seccion = 'acero' AND rb.notas = 'import-2r1e') AS renglones_receta_acero_dolly,
        (SELECT round(coalesce(sum(rb.cantidad * p.costo), 0), 2) FROM receta_base rb JOIN productos p ON rb.material_id = p.id WHERE rb.modelo_id = (SELECT id FROM modelo_dolly) AND rb.seccion = 'acero' AND rb.notas = 'import-2r1e') AS costo_acero_dolly,
        (SELECT count(*)::int FROM costos_modelo cm WHERE cm.modelo_id = (SELECT id FROM modelo_dolly) AND cm.notas = 'import-2r1e') AS renglones_costos_modelo_dolly,
        (SELECT round(coalesce(sum(cm.cantidad * cm.costo_unitario), 0), 2) FROM costos_modelo cm WHERE cm.modelo_id = (SELECT id FROM modelo_dolly) AND cm.notas = 'import-2r1e') AS suma_costos_modelo_dolly,
        (SELECT count(*)::int FROM procesos_manufactura pm WHERE pm.modelo_id = (SELECT id FROM modelo_dolly) AND pm.notas = 'import-2r1e') AS renglones_procesos_dolly,
        (SELECT round(coalesce(sum(pm.minutos * pm.tarifa_hora / 60.0), 0), 2) FROM procesos_manufactura pm WHERE pm.modelo_id = (SELECT id FROM modelo_dolly) AND pm.notas = 'import-2r1e') AS suma_mano_obra_dolly,
        (SELECT count(*)::int FROM opcion_costos oc WHERE oc.tipo_modelo = 'dolly' AND oc.notas LIKE '%import-2r1e%') AS renglones_opcion_costos_dolly
),
modelo_plat_40_2 AS (
    SELECT id
    FROM modelos
    WHERE tipo = 'plataforma' AND largo_ft = 40 AND num_ejes = 2
    LIMIT 1
),
control_plat_40_2 AS (
    SELECT
        (SELECT round(coalesce(sum(rb.cantidad * p.costo), 0), 2) FROM receta_base rb JOIN productos p ON rb.material_id = p.id WHERE rb.modelo_id = (SELECT id FROM modelo_plat_40_2) AND rb.seccion = 'acero') AS plat_40_2_costo_acero,
        (SELECT round(coalesce(sum(cm.cantidad * cm.costo_unitario), 0), 2) FROM costos_modelo cm WHERE cm.modelo_id = (SELECT id FROM modelo_plat_40_2)) AS plat_40_2_costos_modelo,
        (SELECT round(coalesce(sum(pm.minutos * pm.tarifa_hora / 60.0), 0), 2) FROM procesos_manufactura pm WHERE pm.modelo_id = (SELECT id FROM modelo_plat_40_2)) AS plat_40_2_mano_obra
)
SELECT
    cd.modelos_dolly_total,
    cd.producto_terminado_dolly,
    cd.materiales_acero_propios,
    cd.renglones_receta_acero_dolly,
    cd.costo_acero_dolly,
    (cd.costo_acero_dolly = 27018.80) AS costo_acero_ok,
    cd.renglones_costos_modelo_dolly,
    cd.suma_costos_modelo_dolly,
    (cd.suma_costos_modelo_dolly = 20089.14) AS costos_modelo_ok,
    cd.renglones_procesos_dolly,
    cd.suma_mano_obra_dolly,
    (cd.suma_mano_obra_dolly = 11249.90) AS mano_obra_ok,
    cd.renglones_opcion_costos_dolly,
    cp.plat_40_2_costo_acero,
    (cp.plat_40_2_costo_acero = 128211.69) AS plat_acero_intacto,
    cp.plat_40_2_costos_modelo,
    (cp.plat_40_2_costos_modelo = 45685.98) AS plat_kits_intacto,
    cp.plat_40_2_mano_obra,
    (cp.plat_40_2_mano_obra = 22930.00) AS plat_mo_intacto
FROM control_dolly cd
CROSS JOIN control_plat_40_2 cp;
