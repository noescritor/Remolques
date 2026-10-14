-- Verificación del Sub-bloque 2R-1f: La Góndola (un solo SELECT)
-- Devuelve una fila de resumen de control para los modelos de Góndola (2 y 3 ejes),
-- y verifica la integridad intacta de la Plataforma 40/2 y del Dolly 2 ejes.

WITH modelo_gondola_2e AS (
    SELECT id
    FROM modelos
    WHERE tipo = 'gondola' AND num_ejes = 2
    LIMIT 1
),
modelo_gondola_3e AS (
    SELECT id
    FROM modelos
    WHERE tipo = 'gondola' AND num_ejes = 3
    LIMIT 1
),
opcion_tina_a36 AS (
    SELECT oc.id
    FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'tina_material' AND oc.clave = 'a36'
    LIMIT 1
),
opcion_tina_hardox AS (
    SELECT oc.id
    FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'tina_material' AND oc.clave = 'hardox_450'
    LIMIT 1
),
control_gondola AS (
    SELECT
        (SELECT count(*)::int FROM modelos WHERE tipo = 'gondola') AS modelos_gondola_total,
        (SELECT count(*)::int FROM productos WHERE nombre IN ('GONDOLA 2 EJES 45 M3', 'GONDOLA 3 EJES 45 M3') AND tipo_item = 'producto_terminado') AS productos_gondola_total,
        
        -- Acero chasis por modelo
        (SELECT count(*)::int FROM receta_base rb WHERE rb.modelo_id = (SELECT id FROM modelo_gondola_2e) AND rb.seccion = 'acero' AND rb.notas = 'import-2r1f') AS receta_acero_2e,
        (SELECT round(coalesce(sum(rb.cantidad * p.costo), 0), 2) FROM receta_base rb JOIN productos p ON rb.material_id = p.id WHERE rb.modelo_id = (SELECT id FROM modelo_gondola_2e) AND rb.seccion = 'acero' AND rb.notas = 'import-2r1f') AS costo_acero_2e,
        (SELECT count(*)::int FROM receta_base rb WHERE rb.modelo_id = (SELECT id FROM modelo_gondola_3e) AND rb.seccion = 'acero' AND rb.notas = 'import-2r1f') AS receta_acero_3e,
        (SELECT round(coalesce(sum(rb.cantidad * p.costo), 0), 2) FROM receta_base rb JOIN productos p ON rb.material_id = p.id WHERE rb.modelo_id = (SELECT id FROM modelo_gondola_3e) AND rb.seccion = 'acero' AND rb.notas = 'import-2r1f') AS costo_acero_3e,
        
        -- Componentes y costos de tina
        (SELECT count(*)::int FROM opcion_componentes oc WHERE oc.opcion_id = (SELECT id FROM opcion_tina_a36) AND oc.notas = 'import-2r1f') AS componentes_tina_a36,
        (SELECT round(costo_unitario, 2) FROM opcion_costos WHERE opcion_id = (SELECT id FROM opcion_tina_a36) AND tipo_modelo = 'gondola' LIMIT 1) AS costo_tina_a36,
        (SELECT count(*)::int FROM opcion_componentes oc WHERE oc.opcion_id = (SELECT id FROM opcion_tina_hardox) AND oc.notas = 'import-2r1f') AS componentes_tina_hardox,
        (SELECT round(costo_unitario, 2) FROM opcion_costos WHERE opcion_id = (SELECT id FROM opcion_tina_hardox) AND tipo_modelo = 'gondola' LIMIT 1) AS costo_tina_hardox,
        
        -- Costos fijos (kits) por modelo
        (SELECT count(*)::int FROM costos_modelo cm WHERE cm.modelo_id = (SELECT id FROM modelo_gondola_2e) AND cm.notas = 'import-2r1f') AS renglones_costos_modelo_2e,
        (SELECT round(coalesce(sum(cm.cantidad * cm.costo_unitario), 0), 2) FROM costos_modelo cm WHERE cm.modelo_id = (SELECT id FROM modelo_gondola_2e) AND cm.notas = 'import-2r1f') AS suma_costos_modelo_2e,
        (SELECT count(*)::int FROM costos_modelo cm WHERE cm.modelo_id = (SELECT id FROM modelo_gondola_3e) AND cm.notas = 'import-2r1f') AS renglones_costos_modelo_3e,
        (SELECT round(coalesce(sum(cm.cantidad * cm.costo_unitario), 0), 2) FROM costos_modelo cm WHERE cm.modelo_id = (SELECT id FROM modelo_gondola_3e) AND cm.notas = 'import-2r1f') AS suma_costos_modelo_3e,
        
        -- Opciones de catálogo
        (SELECT count(*)::int FROM opcion_costos oc WHERE oc.tipo_modelo = 'gondola' AND (oc.notas LIKE '%import-2r1f%' OR oc.fuente = 'Factura Leolca')) AS renglones_opcion_costos_gondola
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
),
modelo_dolly AS (
    SELECT id
    FROM modelos
    WHERE tipo = 'dolly' AND num_ejes = 2
    LIMIT 1
),
control_dolly AS (
    SELECT
        (SELECT round(coalesce(sum(rb.cantidad * p.costo), 0), 2) FROM receta_base rb JOIN productos p ON rb.material_id = p.id WHERE rb.modelo_id = (SELECT id FROM modelo_dolly) AND rb.seccion = 'acero') AS dolly_costo_acero,
        (SELECT round(coalesce(sum(cm.cantidad * cm.costo_unitario), 0), 2) FROM costos_modelo cm WHERE cm.modelo_id = (SELECT id FROM modelo_dolly)) AS dolly_costos_modelo,
        (SELECT round(coalesce(sum(pm.minutos * pm.tarifa_hora / 60.0), 0), 2) FROM procesos_manufactura pm WHERE pm.modelo_id = (SELECT id FROM modelo_dolly)) AS dolly_mano_obra
)
SELECT
    -- Góndola
    cg.modelos_gondola_total,
    cg.productos_gondola_total,
    cg.receta_acero_2e,
    cg.costo_acero_2e,
    (cg.costo_acero_2e = 103936.96) AS costo_acero_2e_ok,
    cg.receta_acero_3e,
    cg.costo_acero_3e,
    (cg.costo_acero_3e = 103936.96) AS costo_acero_3e_ok,
    cg.componentes_tina_a36,
    cg.costo_tina_a36,
    (cg.costo_tina_a36 = 167505.76) AS tina_a36_ok,
    cg.componentes_tina_hardox,
    cg.costo_tina_hardox,
    (cg.costo_tina_hardox = 286748.42) AS tina_hardox_ok,
    cg.renglones_costos_modelo_2e,
    cg.suma_costos_modelo_2e,
    (cg.suma_costos_modelo_2e = 89045.98) AS kits_2e_ok,
    cg.renglones_costos_modelo_3e,
    cg.suma_costos_modelo_3e,
    (cg.suma_costos_modelo_3e = 88996.98) AS kits_3e_ok,
    cg.renglones_opcion_costos_gondola,
    (cg.renglones_opcion_costos_gondola = 25) AS opcion_costos_ok,
    
    -- Plataforma 40/2 intacta
    cp.plat_40_2_costo_acero,
    (cp.plat_40_2_costo_acero = 128211.69) AS plat_acero_intacto,
    cp.plat_40_2_costos_modelo,
    (cp.plat_40_2_costos_modelo = 45685.98) AS plat_kits_intacto,
    cp.plat_40_2_mano_obra,
    (cp.plat_40_2_mano_obra = 22930.00) AS plat_mo_intacto,
    
    -- Dolly intacto
    cd.dolly_costo_acero,
    (cd.dolly_costo_acero = 27018.80) AS dolly_acero_intacto,
    cd.dolly_costos_modelo,
    (cd.dolly_costos_modelo = 20089.14) AS dolly_kits_intacto,
    cd.dolly_mano_obra,
    (cd.dolly_mano_obra = 11249.90) AS dolly_mo_intacto
FROM control_gondola cg
CROSS JOIN control_plat_40_2 cp
CROSS JOIN control_dolly cd;
