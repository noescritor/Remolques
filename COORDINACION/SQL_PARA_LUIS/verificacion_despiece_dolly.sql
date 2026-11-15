-- Verificación de Despiece de DOLLY 2 EJES
-- Ejecutar en el SQL Editor de Supabase. Debe devolver una sola fila con todo_ok = true.

WITH org AS (
    SELECT id FROM public.organizaciones LIMIT 1
),
mod_dolly AS (
    SELECT m.id
    FROM public.modelos m
    WHERE m.tipo = 'dolly' AND m.organizacion_id = (SELECT id FROM org)
    LIMIT 1
),
checks AS (
    SELECT
        -- 1. Alta de los 14 materiales nuevos con costo 0.00 y unidades correctas
        (
            SELECT count(*) = 14
            FROM public.productos p
            WHERE p.organizacion_id = (SELECT id FROM org)
              AND p.costo = 0.00
              AND p.precio_unitario = 0.00
              AND (
                  (p.nombre = 'OREJA' AND p.unidad = 'PZA') OR
                  (p.nombre = 'BISAGRA DE DOLLY' AND p.unidad = 'PZA') OR
                  (p.nombre = 'PERNO DE DOLLY' AND p.unidad = 'PZA') OR
                  (p.nombre = 'BUJE CONICO GRANDE' AND p.unidad = 'PZA') OR
                  (p.nombre = 'DONA HOLLAND' AND p.unidad = 'PZA') OR
                  (p.nombre = 'DONA PREMIER' AND p.unidad = 'PZA') OR
                  (p.nombre = 'DONA PREMIER BESTIA' AND p.unidad = 'PZA') OR
                  (p.nombre = 'TUERCA GRIPCO 5/8' AND p.unidad = 'PZA') OR
                  (p.nombre = 'QUINTA HOLLAND' AND p.unidad = 'PZA') OR
                  (p.nombre = 'QUINTA FONTAINE' AND p.unidad = 'PZA') OR
                  (p.nombre = 'TORNILLO 5/8 X 2 1/2 GRADO 8' AND p.unidad = 'PZA') OR
                  (p.nombre = 'JUEGO DE MANGUERA ESPIRAL AZUL Y ROJA' AND p.unidad = 'PZA') OR
                  (p.nombre = 'MACHO SOLO 7 POLOS' AND p.unidad = 'PZA') OR
                  (p.nombre = 'CABLE 7 POLOS' AND p.unidad = 'M')
              )
        ) AS materiales_14_ok,

        -- 2. Receta base: DOLLY 2 EJES tiene exactamente 86 renglones (33 acero + 53 nuevos con seccion NULL y escala 'fija')
        (
            SELECT (count(*) = 86)
               AND (count(*) FILTER (WHERE rb.seccion = 'acero') = 33)
               AND (count(*) FILTER (WHERE rb.seccion IS NULL AND rb.escala = 'fija') = 53)
               AND (count(*) FILTER (WHERE rb.paso = 'EXTRAS' AND rb.uso = 'AMORTIGUADOR DE ALTA' AND rb.condicion = '{"todas":[{"op":"in","campo":"suspension","valor":["alta_hendrickson","alta_fleet_master","hj_alta"]}]}'::jsonb) = 4)
            FROM public.receta_base rb
            WHERE rb.modelo_id = (SELECT id FROM mod_dolly)
        ) AS receta_base_dolly_86_ok,

        -- 3. Opciones de Dona: exactamente 3 opciones (holland, premier, bestia) x 4 componentes = 12 componentes con paso 'PASO 1'
        (
            SELECT count(*) = 12
            FROM public.opcion_componentes oc
            JOIN public.opciones_configuracion o ON o.id = oc.opcion_id
            JOIN public.grupos_configuracion g ON g.id = o.grupo_id
            JOIN public.productos p ON p.id = oc.material_id
            WHERE g.clave = 'dona' AND o.clave IN ('holland', 'premier', 'bestia')
              AND oc.paso = 'PASO 1'
              AND oc.seccion IS NULL
              AND oc.escala = 'fija'
              AND (
                  (p.nombre IN ('DONA HOLLAND', 'DONA PREMIER', 'DONA PREMIER BESTIA') AND oc.cantidad = 1) OR
                  (p.nombre = 'TORNILLO 5/8*5 GRADO 8' AND oc.cantidad = 6) OR
                  (p.nombre = 'TUERCA GRIPCO 5/8' AND oc.cantidad = 6) OR
                  (p.nombre = 'RONDANA AUTOMOTRIZ 5/8' AND oc.cantidad = 12)
              )
        ) AS dona_opciones_12_ok,

        -- 4. Opciones de Quinta: exactamente 2 opciones (holland, fontaine) x 4 componentes = 8 componentes con paso 'TERMINADO'
        (
            SELECT count(*) = 8
            FROM public.opcion_componentes oc
            JOIN public.opciones_configuracion o ON o.id = oc.opcion_id
            JOIN public.grupos_configuracion g ON g.id = o.grupo_id
            JOIN public.productos p ON p.id = oc.material_id
            WHERE g.clave = 'quinta' AND o.clave IN ('holland', 'fontaine')
              AND oc.paso = 'TERMINADO'
              AND oc.seccion IS NULL
              AND oc.escala = 'fija'
              AND (
                  (p.nombre IN ('QUINTA HOLLAND', 'QUINTA FONTAINE') AND oc.cantidad = 1) OR
                  (p.nombre = 'TORNILLO 5/8 X 2 1/2 GRADO 8' AND oc.cantidad = 10) OR
                  (p.nombre = 'TUERCA GRIPCO 5/8' AND oc.cantidad = 10) OR
                  (p.nombre = 'RONDANA AUTOMOTRIZ 5/8' AND oc.cantidad = 20)
              )
        ) AS quinta_opciones_8_ok,

        -- 5. Acero del dolly intacto (exactamente 33 líneas con sección 'acero')
        (
            SELECT count(*) = 33
            FROM public.receta_base rb
            WHERE rb.modelo_id = (SELECT id FROM mod_dolly)
              AND rb.seccion = 'acero'
        ) AS acero_dolly_intacto,

        -- 6. Asignación de fases condicional (si fases_despiece existe):
        --    - Ninguna fila nueva en receta_base o en opciones de dona/quinta tiene fase_id IS NULL
        --    - Receta base: PASO 1 (13), LIMPIEZA (4), AIRE (12), LUZ (13), TERMINADO (7), EXTRAS (4)
        --    - Opciones: dona (12 en paso_1), quinta (8 en paso_12)
        --    - Si fases_despiece no existe, devuelve true sin fallar
        (
            SELECT CASE
                WHEN to_regclass('public.fases_despiece') IS NULL THEN true
                ELSE (query_to_xml('
                    SELECT (
                        -- 0 nulos en receta_base nueva del dolly
                        (SELECT count(*) FROM public.receta_base rb
                         WHERE rb.modelo_id = ''' || (SELECT id FROM mod_dolly) || '''
                           AND rb.seccion IS NULL
                           AND rb.fase_id IS NULL) = 0
                        AND
                        -- 0 nulos en opciones de dona y quinta
                        (SELECT count(*) FROM public.opcion_componentes oc
                         JOIN public.opciones_configuracion o ON o.id = oc.opcion_id
                         JOIN public.grupos_configuracion g ON g.id = o.grupo_id
                         WHERE g.clave IN (''dona'', ''quinta'')
                           AND oc.fase_id IS NULL) = 0
                        AND
                        -- Receta base fases correspondientes
                        (SELECT count(*) FROM public.receta_base rb
                         WHERE rb.modelo_id = ''' || (SELECT id FROM mod_dolly) || '''
                           AND rb.paso = ''PASO 1''
                           AND rb.fase_id = (SELECT id FROM public.fases_despiece WHERE clave = ''paso_1'' LIMIT 1)
                        ) = 13
                        AND
                        (SELECT count(*) FROM public.receta_base rb
                         WHERE rb.modelo_id = ''' || (SELECT id FROM mod_dolly) || '''
                           AND rb.paso = ''LIMPIEZA''
                           AND rb.fase_id = (SELECT id FROM public.fases_despiece WHERE clave = ''paso_7'' LIMIT 1)
                        ) = 4
                        AND
                        (SELECT count(*) FROM public.receta_base rb
                         WHERE rb.modelo_id = ''' || (SELECT id FROM mod_dolly) || '''
                           AND rb.paso = ''AIRE''
                           AND rb.fase_id = (SELECT id FROM public.fases_despiece WHERE clave = ''paso_9'' LIMIT 1)
                        ) = 12
                        AND
                        (SELECT count(*) FROM public.receta_base rb
                         WHERE rb.modelo_id = ''' || (SELECT id FROM mod_dolly) || '''
                           AND rb.paso = ''LUZ''
                           AND rb.fase_id = (SELECT id FROM public.fases_despiece WHERE clave = ''paso_10'' LIMIT 1)
                        ) = 13
                        AND
                        (SELECT count(*) FROM public.receta_base rb
                         WHERE rb.modelo_id = ''' || (SELECT id FROM mod_dolly) || '''
                           AND rb.paso = ''TERMINADO''
                           AND rb.fase_id = (SELECT id FROM public.fases_despiece WHERE clave = ''paso_12'' LIMIT 1)
                        ) = 7
                        AND
                        (SELECT count(*) FROM public.receta_base rb
                         WHERE rb.modelo_id = ''' || (SELECT id FROM mod_dolly) || '''
                           AND rb.paso = ''EXTRAS''
                           AND rb.fase_id = (SELECT id FROM public.fases_despiece WHERE clave = ''extras'' LIMIT 1)
                        ) = 4
                        AND
                        -- Opciones dona (12 a paso_1)
                        (SELECT count(*) FROM public.opcion_componentes oc
                         JOIN public.opciones_configuracion o ON o.id = oc.opcion_id
                         JOIN public.grupos_configuracion g ON g.id = o.grupo_id
                         WHERE g.clave = ''dona''
                           AND oc.fase_id = (SELECT id FROM public.fases_despiece WHERE clave = ''paso_1'' LIMIT 1)
                        ) = 12
                        AND
                        -- Opciones quinta (8 a paso_12)
                        (SELECT count(*) FROM public.opcion_componentes oc
                         JOIN public.opciones_configuracion o ON o.id = oc.opcion_id
                         JOIN public.grupos_configuracion g ON g.id = o.grupo_id
                         WHERE g.clave = ''quinta''
                           AND oc.fase_id = (SELECT id FROM public.fases_despiece WHERE clave = ''paso_12'' LIMIT 1)
                        ) = 8
                    ) AS val
                ', true, false, '')::text LIKE '%<val>true</val>%')
            END
        ) AS fases_ok
)
SELECT
    materiales_14_ok,
    receta_base_dolly_86_ok,
    dona_opciones_12_ok,
    quinta_opciones_8_ok,
    acero_dolly_intacto,
    fases_ok,
    (
        materiales_14_ok AND
        receta_base_dolly_86_ok AND
        dona_opciones_12_ok AND
        quinta_opciones_8_ok AND
        acero_dolly_intacto AND
        fases_ok
    ) AS todo_ok
FROM checks;
