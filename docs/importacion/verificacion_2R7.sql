-- Verificación del Sub-bloque 2R-7: Catálogo de costos administrable (un solo SELECT)
-- Valida:
-- 1. Columnas nuevas en opcion_costos (producto_id, costo_desde_producto)
-- 2. Tabla costos_historial con RLS activado y política org_costos_historial_policy
-- 3. Ligas de llantas por tipo_modelo (8 plataforma, 8 dolly, 8 góndola)
-- 4. Que ningún costo_unitario cambió respecto de 2R-1g (plataforma: 82 filas / $986,902.50;
--    dolly: 51 filas / $305,383.50; góndola: 67 filas / $1,077,541.76; total 200 filas).

WITH columnas_opcion_costos AS (
    SELECT
        count(*) FILTER (WHERE column_name = 'producto_id' AND data_type = 'text')::int AS tiene_producto_id,
        count(*) FILTER (WHERE column_name = 'costo_desde_producto' AND data_type = 'boolean')::int AS tiene_costo_desde_producto
    FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'opcion_costos'
),
seguridad_historial AS (
    SELECT
        (SELECT count(*)::int FROM pg_tables WHERE schemaname = 'public' AND tablename = 'costos_historial') AS tabla_existe,
        (SELECT count(*)::int FROM pg_tables WHERE schemaname = 'public' AND tablename = 'costos_historial' AND rowsecurity = true) AS rls_activado,
        (SELECT count(*)::int FROM pg_policies WHERE schemaname = 'public' AND tablename = 'costos_historial' AND policyname = 'org_costos_historial_policy') AS politica_existe
),
llantas_ligadas AS (
    SELECT
        count(*) FILTER (WHERE ocst.tipo_modelo = 'plataforma' AND ocst.producto_id IS NOT NULL)::int AS plat_llantas_ligadas,
        count(*) FILTER (WHERE ocst.tipo_modelo = 'dolly' AND ocst.producto_id IS NOT NULL)::int AS dolly_llantas_ligadas,
        count(*) FILTER (WHERE ocst.tipo_modelo = 'gondola' AND ocst.producto_id IS NOT NULL)::int AS gondola_llantas_ligadas,
        count(*) FILTER (WHERE ocst.producto_id IS NOT NULL AND gc.clave <> 'llantas')::int AS otras_ligas_inesperadas,
        count(*) FILTER (WHERE ocst.costo_desde_producto = true)::int AS activadas_dinamicas_inesperadas,
        coalesce(string_agg(oc.clave, ', ') FILTER (WHERE ocst.tipo_modelo = 'plataforma' AND ocst.producto_id IS NULL AND gc.clave = 'llantas'), 'ninguna') AS plat_llantas_no_ligadas,
        coalesce(string_agg(oc.clave, ', ') FILTER (WHERE ocst.tipo_modelo = 'dolly' AND ocst.producto_id IS NULL AND gc.clave = 'llantas'), 'ninguna') AS dolly_llantas_no_ligadas,
        coalesce(string_agg(oc.clave, ', ') FILTER (WHERE ocst.tipo_modelo = 'gondola' AND ocst.producto_id IS NULL AND gc.clave = 'llantas'), 'ninguna') AS gondola_llantas_no_ligadas
    FROM opcion_costos ocst
    JOIN opciones_configuracion oc ON ocst.opcion_id = oc.id
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
),
resumen_costos AS (
    SELECT
        count(*)::int AS total_filas_opcion_costos,
        count(*) FILTER (WHERE tipo_modelo = 'plataforma')::int AS filas_plat,
        count(*) FILTER (WHERE tipo_modelo = 'dolly')::int AS filas_dolly,
        count(*) FILTER (WHERE tipo_modelo = 'gondola')::int AS filas_gondola,
        round(coalesce(sum(costo_unitario) FILTER (WHERE tipo_modelo = 'plataforma'), 0), 2) AS suma_cu_plat,
        round(coalesce(sum(costo_unitario) FILTER (WHERE tipo_modelo = 'dolly'), 0), 2) AS suma_cu_dolly,
        round(coalesce(sum(costo_unitario) FILTER (WHERE tipo_modelo = 'gondola'), 0), 2) AS suma_cu_gondola
    FROM opcion_costos
)
SELECT
    -- 1. Columnas nuevas
    (c.tiene_producto_id = 1 AND c.tiene_costo_desde_producto = 1) AS columnas_opcion_costos_ok,
    
    -- 2. Tabla historial y RLS
    (s.tabla_existe = 1 AND s.rls_activado = 1 AND s.politica_existe = 1) AS seguridad_costos_historial_ok,
    
    -- 3. Opciones de llantas ligadas por tipo
    l.plat_llantas_ligadas,
    (l.plat_llantas_ligadas = 8 AND l.plat_llantas_no_ligadas = 'ninguna') AS plat_llantas_ok,
    l.dolly_llantas_ligadas,
    (l.dolly_llantas_ligadas = 8 AND l.dolly_llantas_no_ligadas = 'ninguna') AS dolly_llantas_ok,
    l.gondola_llantas_ligadas,
    (l.gondola_llantas_ligadas = 8 AND l.gondola_llantas_no_ligadas = 'ninguna') AS gondola_llantas_ok,
    (l.otras_ligas_inesperadas = 0 AND l.activadas_dinamicas_inesperadas = 0) AS guardas_ligas_ok,
    l.plat_llantas_no_ligadas,
    l.dolly_llantas_no_ligadas,
    l.gondola_llantas_no_ligadas,

    -- 4. Costos unitarios inalterados (2R-1g)
    r.total_filas_opcion_costos,
    (r.total_filas_opcion_costos = 200) AS total_filas_ok,
    r.filas_plat,
    (r.filas_plat = 82 AND r.suma_cu_plat = 986902.50) AS costos_plat_inalterados_ok,
    r.filas_dolly,
    (r.filas_dolly = 51 AND r.suma_cu_dolly = 305383.50) AS costos_dolly_inalterados_ok,
    r.filas_gondola,
    (r.filas_gondola = 67 AND r.suma_cu_gondola = 1077541.76) AS costos_gondola_inalterados_ok
FROM columnas_opcion_costos c
CROSS JOIN seguridad_historial s
CROSS JOIN llantas_ligadas l
CROSS JOIN resumen_costos r;
