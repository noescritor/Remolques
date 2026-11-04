-- Verificación de entrega T2 Ronda 4: Despiece por fases
-- Cero UUIDs literales, validación multitenant y respeto de receta_base.paso

\set ON_ERROR_STOP on

WITH org_base AS (
    SELECT id AS org_id FROM organizaciones WHERE id = '00000000-0000-0000-0000-000000000001'
),
counts_fases AS (
    SELECT count(*) AS total_fases FROM fases_despiece WHERE organizacion_id = (SELECT org_id FROM org_base)
),
counts_equiv AS (
    SELECT count(*) AS total_equiv FROM fases_despiece_equivalencias WHERE organizacion_id = (SELECT org_id FROM org_base)
),
counts_policies AS (
    SELECT count(*) AS politicas_no_select
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename IN ('fases_despiece', 'fases_despiece_equivalencias')
      AND cmd <> 'SELECT'
),
plat_rb_checks AS (
    SELECT
        count(CASE WHEN f.clave = 'paso_1' THEN 1 END) AS p1_count,
        count(CASE WHEN f.clave = 'paso_2' THEN 1 END) AS p2_count,
        count(CASE WHEN f.clave = 'paso_3' THEN 1 END) AS p3_count,
        count(CASE WHEN f.clave = 'paso_4' THEN 1 END) AS p4_count,
        count(CASE WHEN f.clave = 'paso_5' THEN 1 END) AS p5_count,
        count(CASE WHEN f.clave = 'paso_6' THEN 1 END) AS p6_count,
        count(CASE WHEN f.clave = 'paso_7' THEN 1 END) AS p7_count,
        count(CASE WHEN f.clave = 'paso_8' THEN 1 END) AS p8_count,
        count(CASE WHEN f.clave = 'paso_9' THEN 1 END) AS p9_count,
        count(CASE WHEN f.clave = 'paso_10' THEN 1 END) AS p10_count,
        count(CASE WHEN f.clave = 'paso_11' THEN 1 END) AS p11_count,
        count(CASE WHEN f.clave = 'paso_12' THEN 1 END) AS p12_count,
        count(CASE WHEN f.clave = 'extras' THEN 1 END) AS extras_count,
        count(CASE WHEN rb.fase_id IS NULL THEN 1 END) AS sin_fase_count,
        count(*) AS total_lineas
    FROM receta_base rb
    JOIN modelos m ON m.id = rb.modelo_id
    LEFT JOIN fases_despiece f ON f.id = rb.fase_id
    WHERE m.tipo = 'plataforma' AND m.largo_ft = 40 AND m.num_ejes = 2
      AND m.organizacion_id = (SELECT org_id FROM org_base)
),
non_plat_checks AS (
    SELECT
        (SELECT count(CASE WHEN rb.fase_id IS NOT NULL THEN 1 END)
         FROM receta_base rb
         JOIN modelos m ON m.id = rb.modelo_id
         WHERE m.tipo IN ('dolly', 'gondola')) AS dolly_gondola_alterados
),
suspension_checks AS (
    SELECT
        (SELECT count(*) FROM opcion_componentes oc
         JOIN opciones_configuracion o ON o.id = oc.opcion_id
         JOIN productos p ON p.id = oc.material_id
         WHERE o.clave = 'alta_hendrickson'
           AND (p.nombre ILIKE '%MONROE%65512%' OR p.nombre ILIKE '%MONRROE%65512%')
           AND oc.cantidad = 0 AND oc.rol = 'sustituto') AS monroe_sustituto_ok,
        (SELECT count(*) FROM opcion_componentes oc
         JOIN opciones_configuracion o ON o.id = oc.opcion_id
         JOIN productos p ON p.id = oc.material_id
         JOIN grupos_configuracion g ON g.id = o.grupo_id
         WHERE o.clave = 'fleet_master' AND g.clave = 'suspension'
           AND (p.nombre ILIKE '%AMORTIGUADOR%FCR%' OR p.nombre ILIKE '%AMORTIGUADOR%GABRIEL%')
           AND oc.cantidad = 0 AND oc.rol = 'sustituto') AS fleet_amort_sustitutos_ok,
        (SELECT count(*) FROM opcion_componentes oc
         JOIN opciones_configuracion o ON o.id = oc.opcion_id
         JOIN productos p ON p.id = oc.material_id
         JOIN grupos_configuracion g ON g.id = o.grupo_id
         WHERE o.clave = 'fleet_master' AND g.clave = 'suspension'
           AND (p.nombre ILIKE '%CAMARA%AMPRO%1R14-039%' OR p.nombre ILIKE '%CAMARA%FCR%1R14-039%')
           AND oc.cantidad = 0 AND oc.rol = 'sustituto') AS fleet_camara_sustitutos_ok
),
tenant_isolation AS (
    SELECT
        (SELECT count(*)
         FROM receta_base rb
         JOIN modelos m ON m.id = rb.modelo_id
         JOIN fases_despiece f ON f.id = rb.fase_id
         WHERE f.organizacion_id <> m.organizacion_id) AS receta_fase_cruzada,
        (SELECT count(*)
         FROM opcion_componentes oc
         JOIN opciones_configuracion o ON o.id = oc.opcion_id
         JOIN fases_despiece f ON f.id = oc.fase_id
         WHERE f.organizacion_id <> o.organizacion_id) AS opcion_fase_cruzada
),
duplicate_checks AS (
    SELECT count(*) AS casi_duplicados
    FROM productos p1
    JOIN productos p2 ON p1.organizacion_id = p2.organizacion_id AND p1.id < p2.id
    WHERE p1.tipo_item = 'materia_prima' AND p2.tipo_item = 'materia_prima'
      AND (
          (p1.nombre ILIKE '%27X60%' AND p2.nombre ILIKE '%27 X 60%') OR
          (p1.nombre ILIKE '%MONRROE%65512%' AND p2.nombre ILIKE '%MONROE%65512%') OR
          (p1.nombre ILIKE '%TORNILLO%1/4X1%' AND p2.nombre ILIKE '%TORNILLO%1/4 X 1%') OR
          (p1.nombre ILIKE '%CABLE%NEGRO%CAL,12%' AND p2.nombre ILIKE '%CABLE%NEGRO%CAL.%12%')
      )
)
SELECT
    cf.total_fases,
    ce.total_equiv,
    cp.politicas_no_select,
    prb.total_lineas AS rb_40ft_total,
    prb.sin_fase_count AS rb_40ft_sin_fase,
    prb.p1_count,
    prb.p2_count,
    prb.p3_count,
    prb.p4_count,
    prb.p5_count,
    prb.p6_count,
    prb.p7_count,
    prb.p9_count,
    prb.p10_count,
    prb.p12_count,
    prb.extras_count,
    npc.dolly_gondola_alterados,
    sc.monroe_sustituto_ok,
    sc.fleet_amort_sustitutos_ok,
    sc.fleet_camara_sustitutos_ok,
    ti.receta_fase_cruzada,
    ti.opcion_fase_cruzada,
    dc.casi_duplicados,
    (
        cf.total_fases = 14 AND
        ce.total_equiv = 22 AND
        cp.politicas_no_select = 0 AND
        prb.total_lineas = 202 AND
        prb.sin_fase_count = 0 AND
        prb.p1_count = 3 AND
        prb.p2_count = 5 AND
        prb.p3_count = 22 AND
        prb.p4_count = 22 AND
        prb.p5_count = 16 AND
        prb.p6_count = 28 AND
        prb.p7_count = 4 AND
        prb.p9_count = 47 AND
        prb.p10_count = 29 AND
        prb.p12_count = 16 AND
        prb.extras_count = 10 AND
        npc.dolly_gondola_alterados = 0 AND
        sc.monroe_sustituto_ok = 1 AND
        sc.fleet_amort_sustitutos_ok = 2 AND
        sc.fleet_camara_sustitutos_ok = 2 AND
        ti.receta_fase_cruzada = 0 AND
        ti.opcion_fase_cruzada = 0 AND
        dc.casi_duplicados = 0
    ) AS todo_ok
FROM counts_fases cf
CROSS JOIN counts_equiv ce
CROSS JOIN counts_policies cp
CROSS JOIN plat_rb_checks prb
CROSS JOIN non_plat_checks npc
CROSS JOIN suspension_checks sc
CROSS JOIN tenant_isolation ti
CROSS JOIN duplicate_checks dc;
