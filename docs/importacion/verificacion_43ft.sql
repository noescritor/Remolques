-- Verificación de Costos para PLATAFORMA 3 43 FT
-- Ejecutar en el SQL Editor de Supabase. Debe devolver una sola fila con todo_ok = true.

WITH origen AS (
    SELECT id
    FROM public.modelos
    WHERE tipo = 'plataforma' AND largo_ft = 40 AND num_ejes = 2
    LIMIT 1
),
modelo_43 AS (
    SELECT id, costos_derivados_de
    FROM public.modelos
    WHERE tipo = 'plataforma' AND largo_ft = 43 AND num_ejes = 3
    LIMIT 1
),
cargador_prod AS (
    SELECT id
    FROM public.productos
    WHERE nombre = 'CARGADOR (IPR DE 4")' AND tipo_item = 'materia_prima'
    LIMIT 1
),
checks AS (
    SELECT
        -- 1. Modelo 43/3 tiene exactamente 61 renglones de acero
        (
            SELECT count(*) = 61
            FROM public.receta_base
            WHERE modelo_id = (SELECT id FROM modelo_43)
              AND seccion = 'acero'
        ) AS acero_43_ok,

        -- 2. Modelo 43/3 tiene exactamente 41 cargadores de 4"
        (
            SELECT coalesce(sum(cantidad), 0) = 41
            FROM public.receta_base
            WHERE modelo_id = (SELECT id FROM modelo_43)
              AND material_id = (SELECT id FROM cargador_prod)
              AND seccion = 'acero'
        ) AS cargadores_43_ok,

        -- 3. Modelo 43/3 tiene exactamente 12 costos_modelo
        (
            SELECT count(*) = 12
            FROM public.costos_modelo
            WHERE modelo_id = (SELECT id FROM modelo_43)
        ) AS kits_43_ok,

        -- 4. Modelo 43/3 tiene exactamente 80 procesos_manufactura
        (
            SELECT count(*) = 80
            FROM public.procesos_manufactura
            WHERE modelo_id = (SELECT id FROM modelo_43)
        ) AS procesos_43_ok,

        -- 5. costos_derivados_de del 43/3 apunta al modelo 40/2
        (
            (SELECT costos_derivados_de FROM modelo_43) = (SELECT id FROM origen)
        ) AS costos_derivados_de_ok,

        -- 6. Origen 40/2 conserva exactamente sus 61 acero, 12 kits, 80 procesos
        (
            (SELECT count(*) FROM public.receta_base WHERE modelo_id = (SELECT id FROM origen) AND seccion = 'acero') = 61 AND
            (SELECT count(*) FROM public.costos_modelo WHERE modelo_id = (SELECT id FROM origen)) = 12 AND
            (SELECT count(*) FROM public.procesos_manufactura WHERE modelo_id = (SELECT id FROM origen)) = 80
        ) AS origen_40_2_intacto,

        -- 7. Los otros 8 modelos de plataforma conservan sus 61 acero, 12 kits, 80 procesos
        (
            SELECT count(*) = 8
            FROM (
                SELECT m.id
                FROM public.modelos m
                WHERE m.tipo = 'plataforma'
                  AND NOT (m.largo_ft = 40 AND m.num_ejes = 2)
                  AND NOT (m.largo_ft = 43 AND m.num_ejes = 3)
                  AND (SELECT count(*) FROM public.receta_base rb WHERE rb.modelo_id = m.id AND rb.seccion = 'acero') = 61
                  AND (SELECT count(*) FROM public.costos_modelo cm WHERE cm.modelo_id = m.id) = 12
                  AND (SELECT count(*) FROM public.procesos_manufactura pm WHERE pm.modelo_id = m.id) = 80
            ) sub
        ) AS otros_8_modelos_plataforma_intactos,

        -- 8. Los 2 modelos de góndola conservan sus conteos de acero (49 renglones cada uno)
        (
            SELECT count(*) = 2
            FROM (
                SELECT m.id
                FROM public.modelos m
                WHERE m.tipo = 'gondola'
                  AND (SELECT count(*) FROM public.receta_base rb WHERE rb.modelo_id = m.id AND rb.seccion = 'acero') = 49
            ) sub_g
        ) AS gondolas_intactas
)
SELECT
    acero_43_ok,
    cargadores_43_ok,
    kits_43_ok,
    procesos_43_ok,
    costos_derivados_de_ok,
    origen_40_2_intacto,
    otros_8_modelos_plataforma_intactos,
    gondolas_intactas,
    (
        acero_43_ok AND
        cargadores_43_ok AND
        kits_43_ok AND
        procesos_43_ok AND
        costos_derivados_de_ok AND
        origen_40_2_intacto AND
        otros_8_modelos_plataforma_intactos AND
        gondolas_intactas
    ) AS todo_ok
FROM checks;
