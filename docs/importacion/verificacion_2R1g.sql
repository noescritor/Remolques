-- Verificación del Sub-bloque 2R-1g: Costos de Respaldo del Tarifario (un solo SELECT)
-- Valida las 144 filas insertadas con notas = 'import-2r1g',
-- el desglose y sumas de Tarifario por tipo_modelo, la integridad de filas previas
-- y la regla de escala 'por_largo' exclusiva de pisos laminados.

WITH base_2r1g AS (
    SELECT
        ocst.tipo_modelo,
        ocst.fuente,
        ocst.costo_unitario,
        ocst.cantidad_base,
        ocst.escala,
        gc.clave AS grupo_clave,
        oc.clave AS opcion_clave
    FROM opcion_costos ocst
    JOIN opciones_configuracion oc ON ocst.opcion_id = oc.id
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE ocst.notas = 'import-2r1g'
),
resumen_2r1g AS (
    SELECT
        -- Totales por tipo_modelo
        count(*)::int AS total_filas_2r1g,
        count(*) FILTER (WHERE tipo_modelo = 'plataforma')::int AS filas_plat_2r1g,
        count(*) FILTER (WHERE tipo_modelo = 'dolly')::int AS filas_dolly_2r1g,
        count(*) FILTER (WHERE tipo_modelo = 'gondola')::int AS filas_gondola_2r1g,

        -- Desglose plataforma (8 Factura, 33 Tarifario, 19 Supuesto)
        count(*) FILTER (WHERE tipo_modelo = 'plataforma' AND fuente = 'Factura Leolca')::int AS plat_factura,
        count(*) FILTER (WHERE tipo_modelo = 'plataforma' AND fuente = 'Tarifario')::int AS plat_tarifario,
        count(*) FILTER (WHERE tipo_modelo = 'plataforma' AND fuente = 'Supuesto: sin costo adicional')::int AS plat_supuesto,

        -- Desglose dolly (3 Factura, 20 Tarifario, 19 Supuesto)
        count(*) FILTER (WHERE tipo_modelo = 'dolly' AND fuente = 'Factura Leolca')::int AS dolly_factura,
        count(*) FILTER (WHERE tipo_modelo = 'dolly' AND fuente = 'Tarifario')::int AS dolly_tarifario,
        count(*) FILTER (WHERE tipo_modelo = 'dolly' AND fuente = 'Supuesto: sin costo adicional')::int AS dolly_supuesto,

        -- Desglose góndola (3 Factura, 20 Tarifario, 19 Supuesto)
        count(*) FILTER (WHERE tipo_modelo = 'gondola' AND fuente = 'Factura Leolca')::int AS gondola_factura,
        count(*) FILTER (WHERE tipo_modelo = 'gondola' AND fuente = 'Tarifario')::int AS gondola_tarifario,
        count(*) FILTER (WHERE tipo_modelo = 'gondola' AND fuente = 'Supuesto: sin costo adicional')::int AS gondola_supuesto,

        -- Sumas de Tarifario (costo_unitario * cantidad_base)
        round(coalesce(sum(costo_unitario * cantidad_base) FILTER (WHERE tipo_modelo = 'plataforma' AND fuente = 'Tarifario'), 0), 2) AS suma_tarifario_plat,
        round(coalesce(sum(costo_unitario * cantidad_base) FILTER (WHERE tipo_modelo = 'dolly' AND fuente = 'Tarifario'), 0), 2) AS suma_tarifario_dolly,
        round(coalesce(sum(costo_unitario * cantidad_base) FILTER (WHERE tipo_modelo = 'gondola' AND fuente = 'Tarifario'), 0), 2) AS suma_tarifario_gondola,

        -- Validación escala por_largo
        count(*) FILTER (WHERE escala = 'por_largo' AND NOT (grupo_clave = 'piso' AND opcion_clave IN ('laminado_madera', 'laminado_plastico')))::int AS escala_por_largo_invalidas,
        count(*) FILTER (WHERE escala = 'por_largo' AND grupo_clave = 'piso' AND opcion_clave IN ('laminado_madera', 'laminado_plastico'))::int AS pisos_por_largo_validos
    FROM base_2r1g
),
control_previos AS (
    SELECT
        count(*) FILTER (WHERE tipo_modelo = 'plataforma' AND notas = 'import-2r1c')::int AS plat_factura_previas,
        count(*) FILTER (WHERE tipo_modelo = 'dolly' AND notas = 'import-2r1e')::int AS dolly_factura_previas,
        count(*) FILTER (WHERE tipo_modelo = 'gondola' AND notas = 'import-2r1f')::int AS gondola_factura_previas
    FROM opcion_costos
)
SELECT
    -- Totales y desgloses
    r.total_filas_2r1g,
    (r.total_filas_2r1g = 144) AS total_filas_ok,
    r.filas_plat_2r1g,
    (r.filas_plat_2r1g = 60 AND r.plat_factura = 8 AND r.plat_tarifario = 33 AND r.plat_supuesto = 19) AS plat_desglose_ok,
    r.filas_dolly_2r1g,
    (r.filas_dolly_2r1g = 42 AND r.dolly_factura = 3 AND r.dolly_tarifario = 20 AND r.dolly_supuesto = 19) AS dolly_desglose_ok,
    r.filas_gondola_2r1g,
    (r.filas_gondola_2r1g = 42 AND r.gondola_factura = 3 AND r.gondola_tarifario = 20 AND r.gondola_supuesto = 19) AS gondola_desglose_ok,

    -- Sumas del Tarifario
    r.suma_tarifario_plat,
    (r.suma_tarifario_plat = 543675.52) AS suma_tarifario_plat_ok,
    r.suma_tarifario_dolly,
    (r.suma_tarifario_dolly = 278096.00) AS suma_tarifario_dolly_ok,
    r.suma_tarifario_gondola,
    (r.suma_tarifario_gondola = 278096.00) AS suma_tarifario_gondola_ok,

    -- Validación escala por_largo
    r.pisos_por_largo_validos,
    (r.pisos_por_largo_validos = 2 AND r.escala_por_largo_invalidas = 0) AS escala_por_largo_ok,

    -- Filas previas intactas
    p.plat_factura_previas,
    (p.plat_factura_previas = 22) AS plat_previas_ok,
    p.dolly_factura_previas,
    (p.dolly_factura_previas = 9) AS dolly_previas_ok,
    p.gondola_factura_previas,
    (p.gondola_factura_previas = 25) AS gondola_previas_ok
FROM resumen_2r1g r
CROSS JOIN control_previos p;
