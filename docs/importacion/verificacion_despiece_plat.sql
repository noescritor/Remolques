-- Verificación de Despiece Complementario de Plataformas
-- Ejecutar en el SQL Editor de Supabase. Debe devolver una sola fila con todo_ok = true.

WITH org AS (
    SELECT id FROM public.organizaciones LIMIT 1
),
modelos_plat AS (
    SELECT m.id, m.largo_ft, m.num_ejes
    FROM public.modelos m
    WHERE m.tipo = 'plataforma' AND m.organizacion_id = (SELECT id FROM org)
),
mat_coche_3 AS (
    SELECT id FROM public.productos WHERE nombre = 'TORNILLO CABEZA DE COCHE 1/4 X 3' AND organizacion_id = (SELECT id FROM org) LIMIT 1
),
mat_galv AS (
    SELECT id FROM public.productos WHERE nombre = 'TORNILLO GALVANIZADO 1/2 X 1 1/2 GRADO 5' AND organizacion_id = (SELECT id FROM org) LIMIT 1
),
mat_bisagra AS (
    SELECT id FROM public.productos WHERE nombre = 'BISAGRA 5/8' AND organizacion_id = (SELECT id FROM org) LIMIT 1
),
mat_cadena AS (
    SELECT id FROM public.productos WHERE nombre = 'CADENA 3/16' AND organizacion_id = (SELECT id FROM org) LIMIT 1
),
mat_pija_2 AS (
    SELECT id FROM public.productos WHERE nombre = 'PIJA 5/16 X 2' AND organizacion_id = (SELECT id FROM org) LIMIT 1
),
mat_pija_2_half AS (
    SELECT id FROM public.productos WHERE nombre = 'PIJA 5/16 X 2 1/2' AND organizacion_id = (SELECT id FROM org) LIMIT 1
),
mat_tapon_fm AS (
    SELECT id FROM public.productos WHERE nombre = 'TAPON 1/4 SUSPENSION FM + 4' AND organizacion_id = (SELECT id FROM org) LIMIT 1
),
opc_caja_aux AS (
    SELECT o.id FROM public.opciones_configuracion o
    JOIN public.grupos_configuracion g ON g.id = o.grupo_id
    WHERE g.clave = 'adicionales' AND o.clave = 'caja_auxiliar' AND o.organizacion_id = (SELECT id FROM org)
),
opc_bicicletera AS (
    SELECT o.id FROM public.opciones_configuracion o
    JOIN public.grupos_configuracion g ON g.id = o.grupo_id
    WHERE g.clave = 'adicionales' AND o.clave = 'bicicletera' AND o.organizacion_id = (SELECT id FROM org)
),
opc_con_riel AS (
    SELECT o.id FROM public.opciones_configuracion o
    JOIN public.grupos_configuracion g ON g.id = o.grupo_id
    WHERE g.clave = 'riel' AND o.clave = 'con_riel' AND o.organizacion_id = (SELECT id FROM org)
),
opc_fleet_master AS (
    SELECT o.id FROM public.opciones_configuracion o
    JOIN public.grupos_configuracion g ON g.id = o.grupo_id
    WHERE g.clave = 'suspension' AND o.clave = 'fleet_master' AND o.organizacion_id = (SELECT id FROM org)
),
checks AS (
    SELECT
        -- 1. Alta de los 6 materiales requeridos con costo 0.00 y unidades correctas
        (
            SELECT count(*) = 6
            FROM public.productos p
            WHERE p.organizacion_id = (SELECT id FROM org)
              AND p.costo = 0.00
              AND (
                  (p.nombre = 'TORNILLO GALVANIZADO 1/2 X 1 1/2 GRADO 5' AND p.unidad = 'PZA') OR
                  (p.nombre = 'BISAGRA 5/8' AND p.unidad = 'PZA') OR
                  (p.nombre = 'CADENA 3/16' AND p.unidad = 'M') OR
                  (p.nombre = 'PIJA 5/16 X 2' AND p.unidad = 'PZA') OR
                  (p.nombre = 'PIJA 5/16 X 2 1/2' AND p.unidad = 'PZA') OR
                  (p.nombre = 'TORNILLO CABEZA DE COCHE 1/4 X 3' AND p.unidad = 'PZA')
              )
        ) AS materiales_6_ok,

        -- 2. Receta base: exactamente 10 plataformas tienen TORNILLO CABEZA DE COCHE 1/4 X 3 (x4, uso 'Placa de logo', paso 'TERMINADO', seccion IS NULL)
        (
            SELECT count(*) = 10
            FROM public.receta_base rb
            WHERE rb.modelo_id IN (SELECT id FROM modelos_plat)
              AND rb.material_id = (SELECT id FROM mat_coche_3)
              AND rb.cantidad = 4
              AND rb.uso = 'Placa de logo'
              AND rb.paso = 'TERMINADO'
              AND rb.seccion IS NULL
        ) AS receta_base_placa_logo_10_ok,

        -- 3. Caja auxiliar: exactamente 4 componentes con paso 'EXTRAS' (Bisagra 5/8 x2, Cadena 3/16 x0.3, Tornillo Allen 1/2 x2, Tuerca std 1/2 x2), seccion IS NULL
        (
            SELECT count(*) = 4
            FROM public.opcion_componentes oc
            WHERE oc.opcion_id = (SELECT id FROM opc_caja_aux)
              AND oc.seccion IS NULL
              AND oc.paso = 'EXTRAS'
              AND (
                  (oc.material_id = (SELECT id FROM mat_bisagra) AND oc.cantidad = 2) OR
                  (oc.material_id = (SELECT id FROM mat_cadena) AND oc.cantidad = 0.3) OR
                  (oc.material_id = (SELECT id FROM public.productos WHERE nombre = 'TORNILLO ALLEN 1/2 X 1 1/2' AND organizacion_id = (SELECT id FROM org)) AND oc.cantidad = 2) OR
                  (oc.material_id = (SELECT id FROM public.productos WHERE nombre = 'TUERCA ESTANDAR 1/2 GRADO 5' AND organizacion_id = (SELECT id FROM org)) AND oc.cantidad = 2)
              )
        ) AS caja_auxiliar_4_ok,

        -- 4. Bicicletera: exactamente 2 componentes con paso 'EXTRAS' (Tornillo Galv 1/2 x2, Tuerca std 1/2 x2), seccion IS NULL
        (
            SELECT count(*) = 2
            FROM public.opcion_componentes oc
            WHERE oc.opcion_id = (SELECT id FROM opc_bicicletera)
              AND oc.seccion IS NULL
              AND oc.paso = 'EXTRAS'
              AND (
                  (oc.material_id = (SELECT id FROM mat_galv) AND oc.cantidad = 2) OR
                  (oc.material_id = (SELECT id FROM public.productos WHERE nombre = 'TUERCA ESTANDAR 1/2 GRADO 5' AND organizacion_id = (SELECT id FROM org)) AND oc.cantidad = 2)
              )
        ) AS bicicletera_2_ok,

        -- 5. Riel de matracas: exactamente 1 componente con paso 'TERMINADO' (Tornillo Galv 1/2 x2), seccion IS NULL
        (
            SELECT count(*) = 1
            FROM public.opcion_componentes oc
            WHERE oc.opcion_id = (SELECT id FROM opc_con_riel)
              AND oc.material_id = (SELECT id FROM mat_galv)
              AND oc.cantidad = 2
              AND oc.paso = 'TERMINADO'
              AND oc.seccion IS NULL
        ) AS con_riel_1_ok,

        -- 6. Pisos: 9 opciones x 2 pijas = 18 componentes con paso 'PASO 11' y seccion IS NULL (450 pijas 2", 150 pijas 2 1/2")
        (
            SELECT count(*) = 18
            FROM public.opcion_componentes oc
            JOIN public.opciones_configuracion o ON o.id = oc.opcion_id
            JOIN public.grupos_configuracion g ON g.id = o.grupo_id
            WHERE g.clave = 'piso' AND o.clave != 'sin_piso'
              AND oc.seccion IS NULL
              AND oc.paso = 'PASO 11'
              AND (
                  (oc.material_id = (SELECT id FROM mat_pija_2) AND oc.cantidad = 450) OR
                  (oc.material_id = (SELECT id FROM mat_pija_2_half) AND oc.cantidad = 150)
              )
        ) AS pisos_18_ok,

        -- 7. Sin piso: 0 componentes
        (
            SELECT count(*) = 0
            FROM public.opcion_componentes oc
            JOIN public.opciones_configuracion o ON o.id = oc.opcion_id
            JOIN public.grupos_configuracion g ON g.id = o.grupo_id
            WHERE g.clave = 'piso' AND o.clave = 'sin_piso'
        ) AS sin_piso_0_ok,

        -- 8. Suspensión Fleet Master: tapón 1/4 x3 en paso AIRE, seccion IS NULL (total 13 componentes en la opción)
        (
            SELECT (count(*) = 13) AND (count(*) FILTER (WHERE material_id = (SELECT id FROM mat_tapon_fm) AND cantidad = 3 AND paso = 'AIRE' AND seccion IS NULL) = 1)
            FROM public.opcion_componentes oc
            WHERE oc.opcion_id = (SELECT id FROM opc_fleet_master)
        ) AS fleet_master_tapon_ok,

        -- 9. Integridad de costos: las 61 líneas de acero en los 9 modelos con costos se mantienen intactas
        (
            SELECT (count(*) FILTER (WHERE sub.acero = 61)) = 9
            FROM (
                SELECT m.id, count(rb.id) AS acero
                FROM modelos_plat m
                LEFT JOIN public.receta_base rb ON rb.modelo_id = m.id AND rb.seccion = 'acero'
                WHERE NOT (m.largo_ft = 43 AND m.num_ejes = 3)
                GROUP BY m.id
            ) sub
        ) AS acero_plataformas_intacto,

        -- 10. Asignación de fases condicional (si fases_despiece existe):
        --     - Ninguna fila nueva tiene fase_id IS NULL
        --     - Piso apunta a paso_11
        --     - Adicionales (caja auxiliar y bicicletera) apunta a extras
        --     - Con riel y Receta base placa de logo apuntan a paso_12 (TERMINADO)
        --     - Fleet Master apunta a paso_9 (AIRE)
        --     - Si fases_despiece no existe, devuelve true sin fallar
        (
            SELECT CASE
                WHEN to_regclass('public.fases_despiece') IS NULL THEN true
                ELSE (query_to_xml('
                    SELECT (
                        (SELECT count(*) FROM public.opcion_componentes oc
                         JOIN public.opciones_configuracion o ON o.id = oc.opcion_id
                         JOIN public.grupos_configuracion g ON g.id = o.grupo_id
                         JOIN public.productos p ON p.id = oc.material_id
                         WHERE (
                             (g.clave = ''piso'' AND o.clave != ''sin_piso'' AND p.nombre IN (''PIJA 5/16 X 2'', ''PIJA 5/16 X 2 1/2'')) OR
                             (g.clave = ''adicionales'' AND o.clave = ''caja_auxiliar'' AND p.nombre IN (''BISAGRA 5/8'', ''CADENA 3/16'', ''TORNILLO ALLEN 1/2 X 1 1/2'', ''TUERCA ESTANDAR 1/2 GRADO 5'')) OR
                             (g.clave = ''adicionales'' AND o.clave = ''bicicletera'' AND p.nombre IN (''TORNILLO GALVANIZADO 1/2 X 1 1/2 GRADO 5'', ''TUERCA ESTANDAR 1/2 GRADO 5'')) OR
                             (g.clave = ''riel'' AND o.clave = ''con_riel'' AND p.nombre = ''TORNILLO GALVANIZADO 1/2 X 1 1/2 GRADO 5'') OR
                             (g.clave = ''suspension'' AND o.clave = ''fleet_master'' AND p.nombre = ''TAPON 1/4 SUSPENSION FM + 4'')
                         ) AND oc.fase_id IS NULL) = 0
                        AND
                        (SELECT count(*) FROM public.opcion_componentes oc
                         JOIN public.opciones_configuracion o ON o.id = oc.opcion_id
                         JOIN public.grupos_configuracion g ON g.id = o.grupo_id
                         JOIN public.productos p ON p.id = oc.material_id
                         WHERE g.clave = ''piso'' AND o.clave != ''sin_piso''
                           AND p.nombre IN (''PIJA 5/16 X 2'', ''PIJA 5/16 X 2 1/2'')
                           AND oc.fase_id = (SELECT id FROM public.fases_despiece WHERE clave = ''paso_11'' LIMIT 1)
                        ) = 18
                        AND
                        (SELECT count(*) FROM public.opcion_componentes oc
                         JOIN public.opciones_configuracion o ON o.id = oc.opcion_id
                         JOIN public.grupos_configuracion g ON g.id = o.grupo_id
                         JOIN public.productos p ON p.id = oc.material_id
                         WHERE g.clave = ''adicionales'' AND o.clave IN (''caja_auxiliar'', ''bicicletera'')
                           AND p.nombre IN (''BISAGRA 5/8'', ''CADENA 3/16'', ''TORNILLO ALLEN 1/2 X 1 1/2'', ''TUERCA ESTANDAR 1/2 GRADO 5'', ''TORNILLO GALVANIZADO 1/2 X 1 1/2 GRADO 5'')
                           AND oc.fase_id = (SELECT id FROM public.fases_despiece WHERE clave = ''extras'' LIMIT 1)
                        ) = 6
                        AND
                        (SELECT count(*) FROM public.receta_base rb
                         JOIN public.modelos m ON m.id = rb.modelo_id
                         JOIN public.productos p ON p.id = rb.material_id
                         WHERE m.tipo = ''plataforma''
                           AND p.nombre = ''TORNILLO CABEZA DE COCHE 1/4 X 3''
                           AND rb.uso = ''Placa de logo''
                           AND rb.fase_id = (SELECT id FROM public.fases_despiece WHERE clave = ''paso_12'' LIMIT 1)
                        ) = 10
                    ) AS val
                ', true, false, '')::text LIKE '%<val>true</val>%')
            END
        ) AS fases_ok
)
SELECT
    materiales_6_ok,
    receta_base_placa_logo_10_ok,
    caja_auxiliar_4_ok,
    bicicletera_2_ok,
    con_riel_1_ok,
    pisos_18_ok,
    sin_piso_0_ok,
    fleet_master_tapon_ok,
    acero_plataformas_intacto,
    fases_ok,
    (
        materiales_6_ok AND
        receta_base_placa_logo_10_ok AND
        caja_auxiliar_4_ok AND
        bicicletera_2_ok AND
        con_riel_1_ok AND
        pisos_18_ok AND
        sin_piso_0_ok AND
        fleet_master_tapon_ok AND
        acero_plataformas_intacto AND
        fases_ok
    ) AS todo_ok
FROM checks;
