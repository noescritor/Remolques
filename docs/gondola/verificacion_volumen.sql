-- Verificación de Esquema: Volumen Configurable para Góndola (30 m³ y 45 m³)
-- Ejecutar en el SQL Editor de Supabase. Debe devolver una sola fila con todo_ok = true.

WITH checks AS (
    SELECT
        -- 1. Grupo volumen existe y aplica a góndola
        EXISTS (
            SELECT 1 FROM grupos_configuracion
            WHERE clave = 'volumen'
              AND seleccion = 'unica'
              AND 'gondola' = ANY(aplica_a)
        ) AS grupo_volumen_existe,

        -- 2. Opciones m3_45 y m3_30 existen para el grupo volumen
        (
            SELECT count(*) = 2
            FROM opciones_configuracion oc
            JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
            WHERE gc.clave = 'volumen'
              AND oc.clave IN ('m3_45', 'm3_30')
        ) AS opciones_volumen_existen,

        -- 3. Productos terminados de góndola renombrados sin '45 M3' fijo
        (
            SELECT count(*) = 2
            FROM productos
            WHERE nombre IN ('GONDOLA 2 EJES', 'GONDOLA 3 EJES')
              AND tipo_item = 'producto_terminado'
        ) AS productos_renombrados_existen,

        -- 4. No quedan productos con el nombre antiguo
        NOT EXISTS (
            SELECT 1 FROM productos
            WHERE nombre IN ('GONDOLA 2 EJES 45 M3', 'GONDOLA 3 EJES 45 M3')
              AND tipo_item = 'producto_terminado'
        ) AS productos_antiguos_eliminados,

        -- 5. Renglones de tina en receta_base tienen escala por_volumen
        (
            SELECT count(*) >= 8 -- 4 renglones x 2 modelos (2 y 3 ejes)
            FROM receta_base rb
            JOIN modelos m ON rb.modelo_id = m.id
            WHERE m.tipo = 'gondola'
              AND rb.seccion = 'acero'
              AND rb.uso IN ('Alma', 'Soleras', 'Borda delantera', 'Cajon para casquillo trasero')
              AND rb.escala = 'por_volumen'
        ) AS receta_tina_escala_por_volumen,

        -- 6. Renglones de chasis en receta_base mantienen escala fija
        (
            SELECT count(*) >= 80 -- 44 o 45 renglones fijos x 2 modelos
            FROM receta_base rb
            JOIN modelos m ON rb.modelo_id = m.id
            WHERE m.tipo = 'gondola'
              AND rb.seccion = 'acero'
              AND rb.uso NOT IN ('Alma', 'Soleras', 'Borda delantera', 'Cajon para casquillo trasero')
              AND rb.escala = 'fija'
        ) AS receta_chasis_escala_fija,

        -- 7. Componentes de tina en opcion_componentes tienen escala por_volumen
        (
            SELECT count(*) > 0
            FROM opcion_componentes oc
            JOIN opciones_configuracion o ON oc.opcion_id = o.id
            JOIN grupos_configuracion g ON o.grupo_id = g.id
            WHERE g.clave = 'tina_material'
              AND o.clave IN ('a36', 'hardox_450')
              AND oc.escala = 'por_volumen'
        ) AS opcion_tina_escala_por_volumen
)
SELECT
    grupo_volumen_existe,
    opciones_volumen_existen,
    productos_renombrados_existen,
    productos_antiguos_eliminados,
    receta_tina_escala_por_volumen,
    receta_chasis_escala_fija,
    opcion_tina_escala_por_volumen,
    (
        grupo_volumen_existe AND
        opciones_volumen_existen AND
        productos_renombrados_existen AND
        productos_antiguos_eliminados AND
        receta_tina_escala_por_volumen AND
        receta_chasis_escala_fija AND
        opcion_tina_escala_por_volumen
    ) AS todo_ok
FROM checks;
