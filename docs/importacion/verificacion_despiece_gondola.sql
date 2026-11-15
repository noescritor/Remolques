-- Verificación de Despiece de GONDOLA 2 EJES 45 M3 y GONDOLA 3 EJES 45 M3
-- Ejecutar en el SQL Editor de Supabase. Debe devolver una sola fila con todo_ok = true.

WITH org AS (
    SELECT id FROM public.organizaciones LIMIT 1
),
mod_gondola_2ejes AS (
    SELECT m.id
    FROM public.modelos m
    WHERE m.tipo = 'gondola' AND m.num_ejes = 2 AND m.organizacion_id = (SELECT id FROM org)
    LIMIT 1
),
mod_gondola_3ejes AS (
    SELECT m.id
    FROM public.modelos m
    WHERE m.tipo = 'gondola' AND m.num_ejes = 3 AND m.organizacion_id = (SELECT id FROM org)
    LIMIT 1
),
opc_hj_alta AS (
    SELECT o.id
    FROM public.opciones_configuracion o
    JOIN public.grupos_configuracion g ON g.id = o.grupo_id
    WHERE g.clave = 'suspension' AND o.clave = 'hj_alta' AND o.organizacion_id = (SELECT id FROM org)
    LIMIT 1
),
checks AS (
    SELECT
        -- 1. Alta de los 11 materiales nuevos con costo 0.00, precio 0.00 y unidad PZA
        (
            SELECT count(*) = 11
            FROM public.productos p
            WHERE p.organizacion_id = (SELECT id FROM org)
              AND p.costo = 0.00
              AND p.precio_unitario = 0.00
              AND p.unidad = 'PZA'
              AND p.nombre IN (
                  'ROLLO DE SOLIDO',
                  'DISCO DE CORTE 14',
                  'ESPARRAGO DE 1"',
                  'TUERCA ESTANDAR 1"',
                  'TORNILLO 1 X 2 1/2 GRADO 8',
                  'TUERCA DE SEGURIDAD 1"',
                  'CODO 3/8 +1',
                  'TORNILLO 3/8 X 1 1/4 GRADO 8',
                  'AMORTIGUADOR GRC85938',
                  'CAMARA DE SUSPENSION GOOD YEAR R14-232',
                  'ABRAZADERAS HJ'
              )
        ) AS materiales_11_ok,

        -- 2. Receta base GONDOLA 2 EJES 45 M3: 147 renglones (49 acero + 98 no-acero escala 'fija')
        (
            SELECT (count(*) = 147)
               AND (count(*) FILTER (WHERE rb.seccion = 'acero') = 49)
               AND (count(*) FILTER (WHERE rb.seccion IS NULL AND rb.escala = 'fija') = 98)
               AND (count(*) FILTER (WHERE rb.paso = 'EXTRAS' AND rb.uso = 'AMORTIGUADOR DE ALTA' AND rb.condicion = '{"todas":[{"op":"in","campo":"suspension","valor":["alta_hendrickson","alta_fleet_master","hj_alta"]}]}'::jsonb) = 4)
               AND (count(*) FILTER (WHERE rb.uso = 'KIT DE GANCHO' AND rb.condicion = '{"todas":[{"op":"!=","campo":"gancho","valor":"sin_gancho"}]}'::jsonb) = 4)
            FROM public.receta_base rb
            WHERE rb.modelo_id = (SELECT id FROM mod_gondola_2ejes)
        ) AS receta_2ejes_147_ok,

        -- 3. Receta base GONDOLA 3 EJES 45 M3: 107 renglones (49 acero + 58 no-acero escala 'fija')
        (
            SELECT (count(*) = 107)
               AND (count(*) FILTER (WHERE rb.seccion = 'acero') = 49)
               AND (count(*) FILTER (WHERE rb.seccion IS NULL AND rb.escala = 'fija') = 58)
               AND (count(*) FILTER (WHERE rb.paso = 'EXTRAS' AND rb.uso = 'AMORTIGUADOR DE ALTA' AND rb.condicion = '{"todas":[{"op":"in","campo":"suspension","valor":["alta_hendrickson","alta_fleet_master","hj_alta"]}]}'::jsonb) = 4)
               AND (count(*) FILTER (WHERE rb.uso = 'KIT DE GANCHO' AND rb.condicion = '{"todas":[{"op":"!=","campo":"gancho","valor":"sin_gancho"}]}'::jsonb) = 4)
            FROM public.receta_base rb
            WHERE rb.modelo_id = (SELECT id FROM mod_gondola_3ejes)
        ) AS receta_3ejes_107_ok,

        -- 4. Acero de góndolas intacto (exactamente 49 líneas en 2 ejes y 49 líneas en 3 ejes)
        (
            SELECT (count(*) FILTER (WHERE rb.modelo_id = (SELECT id FROM mod_gondola_2ejes) AND rb.seccion = 'acero') = 49)
               AND (count(*) FILTER (WHERE rb.modelo_id = (SELECT id FROM mod_gondola_3ejes) AND rb.seccion = 'acero') = 49)
            FROM public.receta_base rb
            WHERE rb.modelo_id IN ((SELECT id FROM mod_gondola_2ejes), (SELECT id FROM mod_gondola_3ejes))
        ) AS acero_gondolas_intacto,

        -- 5. Componentes de suspensión hj_alta (exactamente 9 componentes con paso 'PASO 5' y escala 'por_eje')
        (
            SELECT (count(*) = 9)
               AND (count(*) FILTER (WHERE oc.paso = 'PASO 5' AND oc.escala = 'por_eje') = 9)
               AND (count(*) FILTER (WHERE oc.rol = 'sustituto' AND oc.cantidad = 0) = 1)
               AND (count(*) FILTER (WHERE oc.rol = 'componente' AND oc.cantidad > 0) = 8)
            FROM public.opcion_componentes oc
            WHERE oc.opcion_id = (SELECT id FROM opc_hj_alta)
        ) AS hj_alta_9_ok,

        -- 6. Asignación de fases condicional (si fases_despiece existe):
        --    - Cero filas nuevas en receta_base de góndolas con fase_id IS NULL
        --    - Cero filas en componentes de hj_alta con fase_id IS NULL
        --    - Desglose 2 ejes: PASO 1 (13), PASO 3 (1), PASO 6 (2), LIMPIEZA (4), AIRE (44), LUZ (20), TERMINADO (10), EXTRAS (4)
        --    - Desglose 3 ejes: PASO 1 (13), PASO 3 (1), PASO 6 (2), LIMPIEZA (4), AIRE (4 - gancho), LUZ (20), TERMINADO (10), EXTRAS (4)
        --    - hj_alta: 9 en paso_5
        --    - Si fases_despiece no existe, devuelve true sin fallar
        (
            SELECT CASE
                WHEN to_regclass('public.fases_despiece') IS NULL THEN true
                ELSE (query_to_xml('
                    SELECT (
                        -- 0 nulos en receta_base nueva de góndola 2 ejes
                        (SELECT count(*) FROM public.receta_base rb
                         WHERE rb.modelo_id = ''' || (SELECT id FROM mod_gondola_2ejes) || '''
                           AND rb.seccion IS NULL
                           AND rb.fase_id IS NULL) = 0
                        AND
                        -- 0 nulos en receta_base nueva de góndola 3 ejes
                        (SELECT count(*) FROM public.receta_base rb
                         WHERE rb.modelo_id = ''' || (SELECT id FROM mod_gondola_3ejes) || '''
                           AND rb.seccion IS NULL
                           AND rb.fase_id IS NULL) = 0
                        AND
                        -- 0 nulos en componentes de hj_alta
                        (SELECT count(*) FROM public.opcion_componentes oc
                         WHERE oc.opcion_id = ''' || (SELECT id FROM opc_hj_alta) || '''
                           AND oc.fase_id IS NULL) = 0
                        AND
                        -- Fases en góndola 2 ejes
                        (SELECT count(*) FROM public.receta_base rb
                         WHERE rb.modelo_id = ''' || (SELECT id FROM mod_gondola_2ejes) || '''
                           AND rb.seccion IS NULL
                           AND rb.fase_id = (SELECT id FROM public.fases_despiece WHERE clave = ''paso_1'' LIMIT 1)
                        ) = 13
                        AND
                        (SELECT count(*) FROM public.receta_base rb
                         WHERE rb.modelo_id = ''' || (SELECT id FROM mod_gondola_2ejes) || '''
                           AND rb.seccion IS NULL
                           AND rb.fase_id = (SELECT id FROM public.fases_despiece WHERE clave = ''paso_3'' LIMIT 1)
                        ) = 1
                        AND
                        (SELECT count(*) FROM public.receta_base rb
                         WHERE rb.modelo_id = ''' || (SELECT id FROM mod_gondola_2ejes) || '''
                           AND rb.seccion IS NULL
                           AND rb.fase_id = (SELECT id FROM public.fases_despiece WHERE clave = ''paso_6'' LIMIT 1)
                        ) = 2
                        AND
                        (SELECT count(*) FROM public.receta_base rb
                         WHERE rb.modelo_id = ''' || (SELECT id FROM mod_gondola_2ejes) || '''
                           AND rb.seccion IS NULL
                           AND rb.fase_id = (SELECT id FROM public.fases_despiece WHERE clave = ''paso_7'' LIMIT 1)
                        ) = 4
                        AND
                        (SELECT count(*) FROM public.receta_base rb
                         WHERE rb.modelo_id = ''' || (SELECT id FROM mod_gondola_2ejes) || '''
                           AND rb.seccion IS NULL
                           AND rb.fase_id = (SELECT id FROM public.fases_despiece WHERE clave = ''paso_9'' LIMIT 1)
                        ) = 44
                        AND
                        (SELECT count(*) FROM public.receta_base rb
                         WHERE rb.modelo_id = ''' || (SELECT id FROM mod_gondola_2ejes) || '''
                           AND rb.seccion IS NULL
                           AND rb.fase_id = (SELECT id FROM public.fases_despiece WHERE clave = ''paso_10'' LIMIT 1)
                        ) = 20
                        AND
                        (SELECT count(*) FROM public.receta_base rb
                         WHERE rb.modelo_id = ''' || (SELECT id FROM mod_gondola_2ejes) || '''
                           AND rb.seccion IS NULL
                           AND rb.fase_id = (SELECT id FROM public.fases_despiece WHERE clave = ''paso_12'' LIMIT 1)
                        ) = 10
                        AND
                        (SELECT count(*) FROM public.receta_base rb
                         WHERE rb.modelo_id = ''' || (SELECT id FROM mod_gondola_2ejes) || '''
                           AND rb.seccion IS NULL
                           AND rb.fase_id = (SELECT id FROM public.fases_despiece WHERE clave = ''extras'' LIMIT 1)
                        ) = 4
                        AND
                        -- Fases en góndola 3 ejes
                        (SELECT count(*) FROM public.receta_base rb
                         WHERE rb.modelo_id = ''' || (SELECT id FROM mod_gondola_3ejes) || '''
                           AND rb.seccion IS NULL
                           AND rb.fase_id = (SELECT id FROM public.fases_despiece WHERE clave = ''paso_9'' LIMIT 1)
                        ) = 4
                        AND
                        -- Fases en componentes de hj_alta (9 en paso_5)
                        (SELECT count(*) FROM public.opcion_componentes oc
                         WHERE oc.opcion_id = ''' || (SELECT id FROM opc_hj_alta) || '''
                           AND oc.fase_id = (SELECT id FROM public.fases_despiece WHERE clave = ''paso_5'' LIMIT 1)
                        ) = 9
                    ) AS val
                ', true, false, '')::text LIKE '%<val>true</val>%')
            END
        ) AS fases_ok
)
SELECT
    materiales_11_ok,
    receta_2ejes_147_ok,
    receta_3ejes_107_ok,
    acero_gondolas_intacto,
    hj_alta_9_ok,
    fases_ok,
    (
        materiales_11_ok AND
        receta_2ejes_147_ok AND
        receta_3ejes_107_ok AND
        acero_gondolas_intacto AND
        hj_alta_9_ok AND
        fases_ok
    ) AS todo_ok
FROM checks;
