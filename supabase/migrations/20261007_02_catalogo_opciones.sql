BEGIN;

DO $$ 
DECLARE 
    org_id uuid := '00000000-0000-0000-0000-000000000001';
    v_grupo_id uuid;
BEGIN

-- 1. PARAMETROS COSTEO
INSERT INTO parametros_costeo (organizacion_id, clave, valor)
VALUES 
    (org_id, 'iva_pct', '16'::jsonb),
    (org_id, 'margen_sugerido', '{"plataforma": 110000, "dolly": 40000}'::jsonb)
ON CONFLICT (organizacion_id, clave) DO UPDATE SET 
    valor = EXCLUDED.valor;

-- 2. MODELOS PLATAFORMA (10 Variantes)

INSERT INTO modelos (organizacion_id, producto_id, tipo, prefijo)
SELECT org_id, id, 'plataforma', 'PLA'
FROM productos 
WHERE nombre ILIKE '%35%FT%' AND nombre ILIKE '%2%EJES%' AND tipo_item = 'producto_terminado' AND organizacion_id = org_id
LIMIT 1
ON CONFLICT (organizacion_id, producto_id) DO NOTHING;

INSERT INTO modelos (organizacion_id, producto_id, tipo, prefijo)
SELECT org_id, id, 'plataforma', 'PLA'
FROM productos 
WHERE nombre ILIKE '%40%FT%' AND nombre ILIKE '%2%EJES%' AND tipo_item = 'producto_terminado' AND organizacion_id = org_id
LIMIT 1
ON CONFLICT (organizacion_id, producto_id) DO NOTHING;

INSERT INTO modelos (organizacion_id, producto_id, tipo, prefijo)
SELECT org_id, id, 'plataforma', 'PLA'
FROM productos 
WHERE nombre ILIKE '%40%FT%' AND nombre ILIKE '%3%EJES%' AND tipo_item = 'producto_terminado' AND organizacion_id = org_id
LIMIT 1
ON CONFLICT (organizacion_id, producto_id) DO NOTHING;

INSERT INTO modelos (organizacion_id, producto_id, tipo, prefijo)
SELECT org_id, id, 'plataforma', 'PLA'
FROM productos 
WHERE nombre ILIKE '%42%FT%' AND nombre ILIKE '%2%EJES%' AND tipo_item = 'producto_terminado' AND organizacion_id = org_id
LIMIT 1
ON CONFLICT (organizacion_id, producto_id) DO NOTHING;

INSERT INTO modelos (organizacion_id, producto_id, tipo, prefijo)
SELECT org_id, id, 'plataforma', 'PLA'
FROM productos 
WHERE nombre ILIKE '%42%FT%' AND nombre ILIKE '%3%EJES%' AND tipo_item = 'producto_terminado' AND organizacion_id = org_id
LIMIT 1
ON CONFLICT (organizacion_id, producto_id) DO NOTHING;

INSERT INTO modelos (organizacion_id, producto_id, tipo, prefijo)
SELECT org_id, id, 'plataforma', 'PLA'
FROM productos 
WHERE nombre ILIKE '%43%FT%' AND nombre ILIKE '%3%EJES%' AND tipo_item = 'producto_terminado' AND organizacion_id = org_id
LIMIT 1
ON CONFLICT (organizacion_id, producto_id) DO NOTHING;

INSERT INTO modelos (organizacion_id, producto_id, tipo, prefijo)
SELECT org_id, id, 'plataforma', 'PLA'
FROM productos 
WHERE nombre ILIKE '%45%FT%' AND nombre ILIKE '%2%EJES%' AND tipo_item = 'producto_terminado' AND organizacion_id = org_id
LIMIT 1
ON CONFLICT (organizacion_id, producto_id) DO NOTHING;

INSERT INTO modelos (organizacion_id, producto_id, tipo, prefijo)
SELECT org_id, id, 'plataforma', 'PLA'
FROM productos 
WHERE nombre ILIKE '%45%FT%' AND nombre ILIKE '%3%EJES%' AND tipo_item = 'producto_terminado' AND organizacion_id = org_id
LIMIT 1
ON CONFLICT (organizacion_id, producto_id) DO NOTHING;

INSERT INTO modelos (organizacion_id, producto_id, tipo, prefijo)
SELECT org_id, id, 'plataforma', 'PLA'
FROM productos 
WHERE nombre ILIKE '%48%FT%' AND nombre ILIKE '%2%EJES%' AND tipo_item = 'producto_terminado' AND organizacion_id = org_id
LIMIT 1
ON CONFLICT (organizacion_id, producto_id) DO NOTHING;

INSERT INTO modelos (organizacion_id, producto_id, tipo, prefijo)
SELECT org_id, id, 'plataforma', 'PLA'
FROM productos 
WHERE nombre ILIKE '%48%FT%' AND nombre ILIKE '%3%EJES%' AND tipo_item = 'producto_terminado' AND organizacion_id = org_id
LIMIT 1
ON CONFLICT (organizacion_id, producto_id) DO NOTHING;

-- 3. GRUPOS Y OPCIONES

-- Grupo: Marca de ejes
INSERT INTO grupos_configuracion (organizacion_id, clave, nombre, requerido, multiple, orden)
VALUES (org_id, 'eje', 'Marca de ejes', true, false, 10)
ON CONFLICT (organizacion_id, clave) DO UPDATE SET nombre = EXCLUDED.nombre, requerido = EXCLUDED.requerido, multiple = EXCLUDED.multiple, orden = EXCLUDED.orden
RETURNING id INTO v_grupo_id;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'fleet_master', 'Fleet Master', 20099.99, 0, 1, ARRAY['FLET MASTER', 'FLEET MASTER']::text[], '{"otros_precios":{"CSV_GONDOLA":19905.6,"DATOS_EQUIPAMIENTO":24421},"precio_fuente":"TARIFARIO"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'ampro', 'Ampro', 22231.4, 0, 1, NULL, '{"otros_precios":{"CSV_GONDOLA":21692,"DATOS_EQUIPAMIENTO":24421},"precio_fuente":"TARIFARIO"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'fcr', 'FCR', NULL, 0, 1, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'prat_max', 'Prat Max', NULL, 0, 1, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'hj', 'HJ', NULL, 0, 1, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

-- Grupo: Suspensión
INSERT INTO grupos_configuracion (organizacion_id, clave, nombre, requerido, multiple, orden)
VALUES (org_id, 'suspension', 'Suspensión', true, false, 20)
ON CONFLICT (organizacion_id, clave) DO UPDATE SET nombre = EXCLUDED.nombre, requerido = EXCLUDED.requerido, multiple = EXCLUDED.multiple, orden = EXCLUDED.orden
RETURNING id INTO v_grupo_id;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'fleet_master', 'Fleet Master (normal)', 23118, 0, 1, ARRAY['SUSPENSIÓN FLEET MASTER']::text[], '{"otros_precios":{"CSV_GONDOLA":23118,"DATOS_EQUIPAMIENTO":23118},"precio_fuente":"TARIFARIO"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'ampro', 'Ampro (normal)', 23118, 0, 1, NULL, '{"otros_precios":{"CSV_GONDOLA":23118,"DATOS_EQUIPAMIENTO":23118},"precio_fuente":"TARIFARIO"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'hendrickson', 'Hendrickson HT300 (normal)', 35844, 0, 1, ARRAY['HENDRICKS']::text[], '{"otros_precios":{"CSV_GONDOLA":35844,"DATOS_EQUIPAMIENTO":23118},"precio_fuente":"TARIFARIO"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'fcr', 'FCR (normal)', NULL, 0, 1, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'alta_hendrickson', 'Hendrickson alta HT300US', 43700, 0, 1, ARRAY['ALTA HENDRICKS', 'SUSPENSIÓN ALTA HENDRICKSON']::text[], '{"otros_precios":{"CSV_GONDOLA":46783.62,"DATOS_EQUIPAMIENTO":23118},"precio_fuente":"TARIFARIO"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'hj_alta', 'HJ tipo Low alta HT300US', 28478, 0, 1, ARRAY['SUSPENSION HJ ALTA']::text[], '{"otros_precios":{"CSV_GONDOLA":25000},"precio_fuente":"TARIFARIO"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'alta_fleet_master', 'Fleet Master alta', NULL, 0, 1, ARRAY['ALTA FM']::text[], '{"otros_precios":{"DATOS_EQUIPAMIENTO":23118}}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'phm', 'PHM', NULL, 0, 1, NULL, '{"otros_precios":{"CSV_GONDOLA":30000}}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'sin_suspension', 'Sin suspensión', NULL, 0, 1, NULL, '{"precio_fuente":"definido"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

-- Grupo: Patines
INSERT INTO grupos_configuracion (organizacion_id, clave, nombre, requerido, multiple, orden)
VALUES (org_id, 'patin', 'Patines', true, false, 30)
ON CONFLICT (organizacion_id, clave) DO UPDATE SET nombre = EXCLUDED.nombre, requerido = EXCLUDED.requerido, multiple = EXCLUDED.multiple, orden = EXCLUDED.orden
RETURNING id INTO v_grupo_id;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'hj', 'HJ', 5798.81, 0, 1, NULL, '{"otros_precios":{"CSV_GONDOLA":5646.88},"precio_fuente":"TARIFARIO"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'ampro', 'Ampro', 5336, 0, 1, NULL, '{"otros_precios":{"CSV_GONDOLA":5916},"precio_fuente":"TARIFARIO"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'holland', 'Holland (Mark V)', 13461.4, 0, 1, ARRAY['HOLAND MARK V']::text[], '{"otros_precios":{"CSV_GONDOLA":17980},"precio_fuente":"TARIFARIO"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'flet_master', 'Fleet Master', NULL, 0, 1, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

-- Grupo: Piso
INSERT INTO grupos_configuracion (organizacion_id, clave, nombre, requerido, multiple, orden)
VALUES (org_id, 'piso', 'Piso', true, false, 40)
ON CONFLICT (organizacion_id, clave) DO UPDATE SET nombre = EXCLUDED.nombre, requerido = EXCLUDED.requerido, multiple = EXCLUDED.multiple, orden = EXCLUDED.orden
RETURNING id INTO v_grupo_id;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'pino', 'Madera de pino', 22000, 0, 1, NULL, '{"precio_fuente":"TARIFARIO"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'encino', 'Madera de encino', 22000, 0, 1, NULL, '{"precio_fuente":"TARIFARIO"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'plastico_cafe', 'Plástico café', 35000, 0, 1, NULL, '{"precio_fuente":"TARIFARIO"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'plastico_negro', 'Plástico negro', 36182.72, 0, 1, NULL, '{"precio_fuente":"TARIFARIO"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'laminado', 'Laminado', 28224, 0, 1, NULL, '{"precio_fuente":"TARIFARIO"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'laminado_madera', 'Laminado con base de madera', 50000, 0, 1, ARRAY['PISO LAMIN C/MADERA']::text[], '{"precio_fuente":"TARIFARIO"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'laminado_plastico', 'Laminado con base de plástico', 63500, 0, 1, ARRAY['PISO LAMIN C/PLASTICO']::text[], '{"precio_fuente":"TARIFARIO"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'antiderrapante', 'Antiderrapante', 22000, 0, 1, NULL, '{"precio_fuente":"TARIFARIO"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'encino_centro_plastico_lados', 'Encino al centro y plástico a los lados', NULL, 0, 1, NULL, '{"otros_precios":{"DATOS_EQUIPAMIENTO":35000}}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'sin_piso', 'Sin piso', NULL, 0, 1, NULL, '{"precio_fuente":"definido"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

-- Grupo: Riel
INSERT INTO grupos_configuracion (organizacion_id, clave, nombre, requerido, multiple, orden)
VALUES (org_id, 'riel', 'Riel', true, false, 50)
ON CONFLICT (organizacion_id, clave) DO UPDATE SET nombre = EXCLUDED.nombre, requerido = EXCLUDED.requerido, multiple = EXCLUDED.multiple, orden = EXCLUDED.orden
RETURNING id INTO v_grupo_id;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'con_riel', 'Con riel', 5805, 0, 1, NULL, '{"otros_precios":{"DATOS_EQUIPAMIENTO":6240},"precio_fuente":"TARIFARIO"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'sin_riel', 'Sin riel', NULL, 0, 1, NULL, '{"precio_fuente":"definido"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

-- Grupo: Matracas / winches
INSERT INTO grupos_configuracion (organizacion_id, clave, nombre, requerido, multiple, orden)
VALUES (org_id, 'matracas', 'Matracas / winches', true, false, 60)
ON CONFLICT (organizacion_id, clave) DO UPDATE SET nombre = EXCLUDED.nombre, requerido = EXCLUDED.requerido, multiple = EXCLUDED.multiple, orden = EXCLUDED.orden
RETURNING id INTO v_grupo_id;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'corrediza', 'Matraca corrediza', 307.4, 0, 1, NULL, '{"precio_fuente":"TARIFARIO"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'soldable', 'Matraca soldable', NULL, 0, 1, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'sin_matracas', 'Sin matracas', NULL, 0, 1, NULL, '{"precio_fuente":"definido"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

-- Grupo: Gancho de arrastre
INSERT INTO grupos_configuracion (organizacion_id, clave, nombre, requerido, multiple, orden)
VALUES (org_id, 'gancho', 'Gancho de arrastre', true, false, 70)
ON CONFLICT (organizacion_id, clave) DO UPDATE SET nombre = EXCLUDED.nombre, requerido = EXCLUDED.requerido, multiple = EXCLUDED.multiple, orden = EXCLUDED.orden
RETURNING id INTO v_grupo_id;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'holland_8_10', 'Holland 8/10 barrenos', 6948.4, 0, 1, ARRAY['GANCHO HOLLAND 10 BARRENOS', 'HOLLAN']::text[], '{"otros_precios":{"CSV_GONDOLA":6844,"DATOS_EQUIPAMIENTO":7100},"precio_fuente":"TARIFARIO"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'premier_8', 'Premier 8 barrenos', 12979.24, 0, 1, ARRAY['GANCHO PREMIER 10 BARRENOS']::text[], '{"otros_precios":{"CSV_GONDOLA":11890,"DATOS_EQUIPAMIENTO":8000},"precio_fuente":"TARIFARIO"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'premier_bestia_6', 'Premier Bestia 6 barrenos', 21892.68, 0, 1, NULL, '{"otros_precios":{"CSV_GONDOLA":28040.98,"DATOS_EQUIPAMIENTO":8000},"precio_fuente":"TARIFARIO"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'sin_gancho', 'Sin gancho', NULL, 0, 1, NULL, '{"precio_fuente":"definido"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

-- Grupo: Frente
INSERT INTO grupos_configuracion (organizacion_id, clave, nombre, requerido, multiple, orden)
VALUES (org_id, 'frente', 'Frente', false, false, 80)
ON CONFLICT (organizacion_id, clave) DO UPDATE SET nombre = EXCLUDED.nombre, requerido = EXCLUDED.requerido, multiple = EXCLUDED.multiple, orden = EXCLUDED.orden
RETURNING id INTO v_grupo_id;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'concha_laminada', 'Concha laminada', NULL, 0, 1, NULL, '{"medidas":{"1.20":6160,"1.50":7500,"1.70":6891},"precio_fuente":"TARIFARIO"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'concha_lisa_reforzada', 'Concha lisa reforzada', NULL, 0, 1, NULL, '{"medidas":{"1.20":7536},"precio_fuente":"TARIFARIO"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'concha', 'Concha (tipo sin especificar)', NULL, 0, 1, NULL, '{"medidas":{"1.00":6240,"1.10":5891,"1.40":8800,"1.50":7680,"2.00":10000,"2.35":11750},"precio_fuente":"TARIFARIO"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'concha_madera', 'Concha de madera', NULL, 0, 1, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'burro_laminado', 'Burro laminado', NULL, 0, 1, NULL, '{"medidas":{"1.20":5800,"1.50":7250,"1.80":8700},"precio_fuente":"TARIFARIO"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'burro_madera', 'Burro de madera', NULL, 0, 1, NULL, '{"medidas":{"1.20":4515},"precio_fuente":"TARIFARIO"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'sin_frente', 'Sin frente', NULL, 0, 1, NULL, '{"precio_fuente":"definido"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

-- Grupo: Redilas
INSERT INTO grupos_configuracion (organizacion_id, clave, nombre, requerido, multiple, orden)
VALUES (org_id, 'redilas', 'Redilas', true, false, 90)
ON CONFLICT (organizacion_id, clave) DO UPDATE SET nombre = EXCLUDED.nombre, requerido = EXCLUDED.requerido, multiple = EXCLUDED.multiple, orden = EXCLUDED.orden
RETURNING id INTO v_grupo_id;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, '70', 'Redilas de 70 cm', 35000, 0, 1, NULL, '{"precio_fuente":"TARIFARIO"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, '75', 'Redilas de 75 cm', 35500, 0, 1, NULL, '{"precio_fuente":"TARIFARIO"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, '80', 'Redilas de 80 cm', 36000, 0, 1, NULL, '{"precio_fuente":"TARIFARIO"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, '90', 'Redilas de 90 cm', NULL, 0, 1, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, '100', 'Redilas de 1 m', 42000, 0, 1, NULL, '{"precio_fuente":"TARIFARIO"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'sin_redilas', 'Sin redilas', NULL, 0, 1, NULL, '{"precio_fuente":"definido"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

-- Grupo: Sistema retráctil
INSERT INTO grupos_configuracion (organizacion_id, clave, nombre, requerido, multiple, orden)
VALUES (org_id, 'retractil', 'Sistema retráctil', true, false, 100)
ON CONFLICT (organizacion_id, clave) DO UPDATE SET nombre = EXCLUDED.nombre, requerido = EXCLUDED.requerido, multiple = EXCLUDED.multiple, orden = EXCLUDED.orden
RETURNING id INTO v_grupo_id;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'grande', 'Retráctil grande', 15000, 0, 1, ARRAY['SISTEMA RETRÁCTIL']::text[], '{"otros_precios":{"CSV_GONDOLA":15000},"precio_fuente":"TARIFARIO"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'chico', 'Retráctil chico (UBL)', 15000, 0, 1, NULL, '{"otros_precios":{"CSV_GONDOLA":15000},"precio_fuente":"TARIFARIO"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'paleta', 'Retráctil paleta', NULL, 0, 1, NULL, '{"otros_precios":{"CSV_GONDOLA":15000}}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'sin_retractil', 'Sin sistema retráctil', NULL, 0, 1, NULL, '{"precio_fuente":"definido"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

-- Grupo: Rines
INSERT INTO grupos_configuracion (organizacion_id, clave, nombre, requerido, multiple, orden)
VALUES (org_id, 'rines', 'Rines', false, false, 110)
ON CONFLICT (organizacion_id, clave) DO UPDATE SET nombre = EXCLUDED.nombre, requerido = EXCLUDED.requerido, multiple = EXCLUDED.multiple, orden = EXCLUDED.orden
RETURNING id INTO v_grupo_id;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'acero', 'Rines de acero', 1391.97, 0, 1, NULL, '{"precio_fuente":"TARIFARIO"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'aluminio', 'Rines de aluminio', 4268.8, 0, 1, NULL, '{"precio_fuente":"TARIFARIO"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'cliente', 'Proporciona el cliente', NULL, 0, 1, NULL, '{"precio_fuente":"definido"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'sin_rines', 'Sin rines', NULL, 0, 1, NULL, '{"precio_fuente":"definido"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

-- Grupo: Llantas
INSERT INTO grupos_configuracion (organizacion_id, clave, nombre, requerido, multiple, orden)
VALUES (org_id, 'llantas', 'Llantas', false, false, 120)
ON CONFLICT (organizacion_id, clave) DO UPDATE SET nombre = EXCLUDED.nombre, requerido = EXCLUDED.requerido, multiple = EXCLUDED.multiple, orden = EXCLUDED.orden
RETURNING id INTO v_grupo_id;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'cerex', 'Cerex', 3586, 0, 1, NULL, '{"precio_fuente":"TARIFARIO"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'firestone', 'Firestone', 8790, 0, 1, ARRAY['FIRESTON LINEAL']::text[], '{"precio_fuente":"TARIFARIO"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'royal_black', 'Royal Black', 5600, 0, 1, NULL, '{"precio_fuente":"TARIFARIO"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'bf_goodrich', 'BF Goodrich', 11750, 0, 1, NULL, '{"precio_fuente":"TARIFARIO"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'eudemon', 'Eudemon', 5400, 0, 1, NULL, '{"precio_fuente":"TARIFARIO"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'chinas', 'Chinas', 4000, 0, 1, NULL, '{"precio_fuente":"TARIFARIO"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'valiant', 'Valiant', 3581, 0, 1, NULL, '{"precio_fuente":"TARIFARIO"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'amulet', 'Amulet', 5400.01, 0, 1, NULL, '{"precio_fuente":"TARIFARIO"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'kpatos_lineal', 'K Patos lineal', NULL, 0, 1, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'kpatos_traccion', 'K Patos tracción', NULL, 0, 1, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'godshield_lineal', 'Godshield lineal', NULL, 0, 1, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'roadmaster', 'Road Master', NULL, 0, 1, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'sin_llantas', 'Sin llantas', NULL, 0, 1, NULL, '{"precio_fuente":"definido"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

-- Grupo: Plafones de carrito
INSERT INTO grupos_configuracion (organizacion_id, clave, nombre, requerido, multiple, orden)
VALUES (org_id, 'plafones', 'Plafones de carrito', false, false, 130)
ON CONFLICT (organizacion_id, clave) DO UPDATE SET nombre = EXCLUDED.nombre, requerido = EXCLUDED.requerido, multiple = EXCLUDED.multiple, orden = EXCLUDED.orden
RETURNING id INTO v_grupo_id;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'ambar_laterales', 'Ámbar laterales', 168.2, 0, 1, NULL, '{"precio_fuente":"TARIFARIO"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'rojo_laterales', 'Rojos laterales', 168.2, 0, 1, NULL, '{"precio_fuente":"TARIFARIO"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'ambar_estribo', 'Ámbar en estribo', 168.2, 0, 1, NULL, '{"precio_fuente":"TARIFARIO"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'rojo_estribo', 'Rojos en estribo', 168.2, 0, 1, NULL, '{"precio_fuente":"TARIFARIO"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

-- Grupo: Kit de aire / ABS
INSERT INTO grupos_configuracion (organizacion_id, clave, nombre, requerido, multiple, orden)
VALUES (org_id, 'abs', 'Kit de aire / ABS', false, false, 140)
ON CONFLICT (organizacion_id, clave) DO UPDATE SET nombre = EXCLUDED.nombre, requerido = EXCLUDED.requerido, multiple = EXCLUDED.multiple, orden = EXCLUDED.orden
RETURNING id INTO v_grupo_id;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, '2e_sin_retractil', '2 ejes sin retráctil', 22000, 0, 1, NULL, '{"otros_precios":{"TARIFARIO":23000},"precio_fuente":"CSV_GONDOLA"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, '2e_1_retractil', '2 ejes 1 retráctil', 26700, 0, 1, NULL, '{"otros_precios":{"TARIFARIO":23000},"precio_fuente":"CSV_GONDOLA"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, '3e_1_retractil', '3 ejes 1 retráctil', 27200, 0, 1, NULL, '{"otros_precios":{"TARIFARIO":27000},"precio_fuente":"CSV_GONDOLA"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, '3e_2_retractil', '3 ejes 2 retráctiles', 30500, 0, 1, NULL, '{"otros_precios":{"TARIFARIO":27000},"precio_fuente":"CSV_GONDOLA"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

-- Grupo: Quinta
INSERT INTO grupos_configuracion (organizacion_id, clave, nombre, requerido, multiple, orden)
VALUES (org_id, 'quinta', 'Quinta', true, false, 150)
ON CONFLICT (organizacion_id, clave) DO UPDATE SET nombre = EXCLUDED.nombre, requerido = EXCLUDED.requerido, multiple = EXCLUDED.multiple, orden = EXCLUDED.orden
RETURNING id INTO v_grupo_id;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'holland', 'Holland', 28998.81, 0, 1, NULL, '{"otros_precios":{"PRES_DOLLY":29998.81},"precio_fuente":"TARIFARIO"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'fontaine', 'Fontaine', NULL, 0, 1, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

-- Grupo: Dona (dolly)
INSERT INTO grupos_configuracion (organizacion_id, clave, nombre, requerido, multiple, orden)
VALUES (org_id, 'dona', 'Dona (dolly)', true, false, 160)
ON CONFLICT (organizacion_id, clave) DO UPDATE SET nombre = EXCLUDED.nombre, requerido = EXCLUDED.requerido, multiple = EXCLUDED.multiple, orden = EXCLUDED.orden
RETURNING id INTO v_grupo_id;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'holland', 'Dona Holland', 4400, 0, 1, NULL, '{"precio_fuente":"TARIFARIO"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'premier', 'Dona Premier', 4400, 0, 1, NULL, '{"precio_fuente":"TARIFARIO"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'bestia', 'Dona Premier Bestia', NULL, 0, 1, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

-- Grupo: Material de la tina
INSERT INTO grupos_configuracion (organizacion_id, clave, nombre, requerido, multiple, orden)
VALUES (org_id, 'tina_material', 'Material de la tina', true, false, 170)
ON CONFLICT (organizacion_id, clave) DO UPDATE SET nombre = EXCLUDED.nombre, requerido = EXCLUDED.requerido, multiple = EXCLUDED.multiple, orden = EXCLUDED.orden
RETURNING id INTO v_grupo_id;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'a36', 'Acero A-36', NULL, 0, 1, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'hardox_450', 'Acero Hardox 450', NULL, 0, 1, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

-- Grupo: Marca de pintura
INSERT INTO grupos_configuracion (organizacion_id, clave, nombre, requerido, multiple, orden)
VALUES (org_id, 'pintura', 'Marca de pintura', true, false, 180)
ON CONFLICT (organizacion_id, clave) DO UPDATE SET nombre = EXCLUDED.nombre, requerido = EXCLUDED.requerido, multiple = EXCLUDED.multiple, orden = EXCLUDED.orden
RETURNING id INTO v_grupo_id;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'sherwin_williams', 'Sherwin-Williams', NULL, 0, 1, ARRAY['SHERVI']::text[], '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'ppg', 'PPG', NULL, 0, 1, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'axalta', 'Axalta', NULL, 0, 1, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

-- Grupo: Color
INSERT INTO grupos_configuracion (organizacion_id, clave, nombre, requerido, multiple, orden)
VALUES (org_id, 'color', 'Color', true, false, 190)
ON CONFLICT (organizacion_id, clave) DO UPDATE SET nombre = EXCLUDED.nombre, requerido = EXCLUDED.requerido, multiple = EXCLUDED.multiple, orden = EXCLUDED.orden
RETURNING id INTO v_grupo_id;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'rojo_claro', 'Rojo claro', NULL, 0, 1, NULL, '{"precio_fuente":"definido"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'rojo', 'Rojo', NULL, 0, 1, NULL, '{"precio_fuente":"definido"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'rojo_coca_cola', 'Rojo Coca-Cola', NULL, 0, 1, NULL, '{"precio_fuente":"definido"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'rojo_bermellon', 'Rojo bermellón', NULL, 0, 1, NULL, '{"precio_fuente":"definido"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'vino', 'Vino', NULL, 0, 1, NULL, '{"precio_fuente":"definido"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'negro', 'Negro', NULL, 0, 1, NULL, '{"precio_fuente":"definido"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'anaranjado_con_borda_blanca', 'Anaranjado con borda blanca', NULL, 0, 1, NULL, '{"precio_fuente":"definido"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'azul_rey', 'Azul rey', NULL, 0, 1, NULL, '{"precio_fuente":"definido"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'blanco', 'Blanco', NULL, 0, 1, NULL, '{"precio_fuente":"definido"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'gris', 'Gris', NULL, 0, 1, NULL, '{"precio_fuente":"definido"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'naranja', 'Naranja', NULL, 0, 1, NULL, '{"precio_fuente":"definido"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'amarillo', 'Amarillo', NULL, 0, 1, NULL, '{"precio_fuente":"definido"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'rosa', 'Rosa', NULL, 0, 1, NULL, '{"precio_fuente":"definido"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'verde', 'Verde', NULL, 0, 1, NULL, '{"precio_fuente":"definido"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'morado', 'Morado', NULL, 0, 1, NULL, '{"precio_fuente":"definido"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'cafe', 'Café', NULL, 0, 1, NULL, '{"precio_fuente":"definido"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

-- Grupo: Adicionales
INSERT INTO grupos_configuracion (organizacion_id, clave, nombre, requerido, multiple, orden)
VALUES (org_id, 'adicionales', 'Adicionales', false, false, 200)
ON CONFLICT (organizacion_id, clave) DO UPDATE SET nombre = EXCLUDED.nombre, requerido = EXCLUDED.requerido, multiple = EXCLUDED.multiple, orden = EXCLUDED.orden
RETURNING id INTO v_grupo_id;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'polinera_grande', 'Polinera grande', 6000, 0, 1, NULL, '{"precio_fuente":"TARIFARIO"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'polinera_puerta', 'Polinera con puerta', 10000, 0, 1, NULL, '{"precio_fuente":"TARIFARIO"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'polinera_atravesada', 'Polinera atravesada', 6000, 0, 1, NULL, '{"precio_fuente":"TARIFARIO"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'polinera_bicicletera', 'Polinera con bicicletera', 8000, 0, 1, NULL, '{"precio_fuente":"TARIFARIO"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'caja_herr_chica', 'Caja de herramientas chica', 9500, 0, 1, NULL, '{"precio_fuente":"TARIFARIO"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'caja_herr_grande', 'Caja de herramientas grande 1.10 m', NULL, 0, 1, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'caja_auxiliar', 'Caja auxiliar', 1500, 0, 1, NULL, '{"precio_fuente":"TARIFARIO"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'bicicletera', 'Bicicletera', 5000, 0, 1, NULL, '{"precio_fuente":"TARIFARIO"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'portallantas_extra', 'Portallantas extra', 3500, 0, 1, NULL, '{"precio_fuente":"TARIFARIO"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'canastilla', 'Canastilla', 8000, 0, 1, NULL, '{"precio_fuente":"TARIFARIO"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'pata_elefante', 'Pata de elefante', 3250, 0, 1, NULL, '{"precio_fuente":"TARIFARIO"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'lodera_centro', 'Lodera de centro', 874, 0, 1, NULL, '{"precio_fuente":"TARIFARIO"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'sistema_psi', 'Sistema PSI', 20000, 0, 1, NULL, '{"precio_fuente":"TARIFARIO"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'jalon', 'Jalón', 3768, 0, 1, NULL, '{"precio_fuente":"TARIFARIO"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'candados', 'Candados', 1450, 0, 1, NULL, '{"otros_precios":{"TARIFARIO_extras":461},"precio_fuente":"TARIFARIO"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'multimodal', 'Multimodal', 50000, 0, 1, NULL, '{"precio_fuente":"TARIFARIO"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'refuerzos', 'Refuerzos', 14786, 0, 1, NULL, '{"otros_precios":{"TARIFARIO_extras":10000},"precio_fuente":"TARIFARIO"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'barrenado_chasis', 'Barrenado sobre chasis', 1250, 0, 1, NULL, '{"precio_fuente":"TARIFARIO"}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'doble_solera_trasera', 'Doble solera parte trasera (colita)', NULL, 0, 1, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'base_bolsa_piernas', 'Base completa de bolsa en piernas', NULL, 0, 1, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, 'amarres', 'Amarres', NULL, 0, 1, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

END $$;
COMMIT;
