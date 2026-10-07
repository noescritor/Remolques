BEGIN;

DO $$ 
DECLARE 
    -- org_id se fija manual debido a que este bloque es exclusivo para el cliente actual.
    -- Cuando sea multitenant esto deberá ser parametrizado.
    org_id uuid := '00000000-0000-0000-0000-000000000001';
    v_grupo_id uuid;
    v_count int;
    v_total_modelos int := 0;
BEGIN

-- 1. PARAMETROS COSTEO
INSERT INTO parametros_costeo (organizacion_id, clave, valor)
VALUES 
    (org_id, 'iva_pct', '16'::jsonb),
    (org_id, 'margen_sugerido', '{"plataforma": 110000, "dolly": 40000}'::jsonb)
ON CONFLICT (organizacion_id, clave) DO UPDATE SET 
    valor = EXCLUDED.valor;

-- 2. MODELOS PLATAFORMA (10 Variantes)

SELECT count(*) INTO v_count FROM productos 
WHERE nombre ~* '^PLATAFORMA +2 +35 *FT *$' AND tipo_item = 'producto_terminado' AND organizacion_id = org_id;

IF v_count <> 1 THEN
    RAISE EXCEPTION 'La variante "35 ft x2" (regex: %) devolvió % productos en lugar de 1', '^PLATAFORMA +2 +35 *FT *$', v_count;
END IF;

INSERT INTO modelos (organizacion_id, producto_id, tipo, largo_ft, num_ejes)
SELECT org_id, id, 'plataforma', 35, 2
FROM productos 
WHERE nombre ~* '^PLATAFORMA +2 +35 *FT *$' AND tipo_item = 'producto_terminado' AND organizacion_id = org_id
ON CONFLICT (organizacion_id, producto_id) DO UPDATE SET 
    tipo = EXCLUDED.tipo, largo_ft = EXCLUDED.largo_ft, num_ejes = EXCLUDED.num_ejes;

v_total_modelos := v_total_modelos + 1;

SELECT count(*) INTO v_count FROM productos 
WHERE nombre ~* '^PLATAFORMA +2 +40 *FT *$' AND tipo_item = 'producto_terminado' AND organizacion_id = org_id;

IF v_count <> 1 THEN
    RAISE EXCEPTION 'La variante "40 ft x2" (regex: %) devolvió % productos en lugar de 1', '^PLATAFORMA +2 +40 *FT *$', v_count;
END IF;

INSERT INTO modelos (organizacion_id, producto_id, tipo, largo_ft, num_ejes)
SELECT org_id, id, 'plataforma', 40, 2
FROM productos 
WHERE nombre ~* '^PLATAFORMA +2 +40 *FT *$' AND tipo_item = 'producto_terminado' AND organizacion_id = org_id
ON CONFLICT (organizacion_id, producto_id) DO UPDATE SET 
    tipo = EXCLUDED.tipo, largo_ft = EXCLUDED.largo_ft, num_ejes = EXCLUDED.num_ejes;

v_total_modelos := v_total_modelos + 1;

SELECT count(*) INTO v_count FROM productos 
WHERE nombre ~* '^PLATAFORMA +3 +40 *FT *$' AND tipo_item = 'producto_terminado' AND organizacion_id = org_id;

IF v_count <> 1 THEN
    RAISE EXCEPTION 'La variante "40 ft x3" (regex: %) devolvió % productos en lugar de 1', '^PLATAFORMA +3 +40 *FT *$', v_count;
END IF;

INSERT INTO modelos (organizacion_id, producto_id, tipo, largo_ft, num_ejes)
SELECT org_id, id, 'plataforma', 40, 3
FROM productos 
WHERE nombre ~* '^PLATAFORMA +3 +40 *FT *$' AND tipo_item = 'producto_terminado' AND organizacion_id = org_id
ON CONFLICT (organizacion_id, producto_id) DO UPDATE SET 
    tipo = EXCLUDED.tipo, largo_ft = EXCLUDED.largo_ft, num_ejes = EXCLUDED.num_ejes;

v_total_modelos := v_total_modelos + 1;

SELECT count(*) INTO v_count FROM productos 
WHERE nombre ~* '^PLATAFORMA +2 +42 *FT *$' AND tipo_item = 'producto_terminado' AND organizacion_id = org_id;

IF v_count <> 1 THEN
    RAISE EXCEPTION 'La variante "42 ft x2" (regex: %) devolvió % productos en lugar de 1', '^PLATAFORMA +2 +42 *FT *$', v_count;
END IF;

INSERT INTO modelos (organizacion_id, producto_id, tipo, largo_ft, num_ejes)
SELECT org_id, id, 'plataforma', 42, 2
FROM productos 
WHERE nombre ~* '^PLATAFORMA +2 +42 *FT *$' AND tipo_item = 'producto_terminado' AND organizacion_id = org_id
ON CONFLICT (organizacion_id, producto_id) DO UPDATE SET 
    tipo = EXCLUDED.tipo, largo_ft = EXCLUDED.largo_ft, num_ejes = EXCLUDED.num_ejes;

v_total_modelos := v_total_modelos + 1;

SELECT count(*) INTO v_count FROM productos 
WHERE nombre ~* '^PLATAFORMA +3 +42 *FT *$' AND tipo_item = 'producto_terminado' AND organizacion_id = org_id;

IF v_count <> 1 THEN
    RAISE EXCEPTION 'La variante "42 ft x3" (regex: %) devolvió % productos en lugar de 1', '^PLATAFORMA +3 +42 *FT *$', v_count;
END IF;

INSERT INTO modelos (organizacion_id, producto_id, tipo, largo_ft, num_ejes)
SELECT org_id, id, 'plataforma', 42, 3
FROM productos 
WHERE nombre ~* '^PLATAFORMA +3 +42 *FT *$' AND tipo_item = 'producto_terminado' AND organizacion_id = org_id
ON CONFLICT (organizacion_id, producto_id) DO UPDATE SET 
    tipo = EXCLUDED.tipo, largo_ft = EXCLUDED.largo_ft, num_ejes = EXCLUDED.num_ejes;

v_total_modelos := v_total_modelos + 1;

SELECT count(*) INTO v_count FROM productos 
WHERE nombre ~* '^PLATAFORMA +3 +43 *FT *$' AND tipo_item = 'producto_terminado' AND organizacion_id = org_id;

IF v_count <> 1 THEN
    RAISE EXCEPTION 'La variante "43 ft x3" (regex: %) devolvió % productos en lugar de 1', '^PLATAFORMA +3 +43 *FT *$', v_count;
END IF;

INSERT INTO modelos (organizacion_id, producto_id, tipo, largo_ft, num_ejes)
SELECT org_id, id, 'plataforma', 43, 3
FROM productos 
WHERE nombre ~* '^PLATAFORMA +3 +43 *FT *$' AND tipo_item = 'producto_terminado' AND organizacion_id = org_id
ON CONFLICT (organizacion_id, producto_id) DO UPDATE SET 
    tipo = EXCLUDED.tipo, largo_ft = EXCLUDED.largo_ft, num_ejes = EXCLUDED.num_ejes;

v_total_modelos := v_total_modelos + 1;

SELECT count(*) INTO v_count FROM productos 
WHERE nombre ~* '^PLATAFORMA +2 +45 *FT *$' AND tipo_item = 'producto_terminado' AND organizacion_id = org_id;

IF v_count <> 1 THEN
    RAISE EXCEPTION 'La variante "45 ft x2" (regex: %) devolvió % productos en lugar de 1', '^PLATAFORMA +2 +45 *FT *$', v_count;
END IF;

INSERT INTO modelos (organizacion_id, producto_id, tipo, largo_ft, num_ejes)
SELECT org_id, id, 'plataforma', 45, 2
FROM productos 
WHERE nombre ~* '^PLATAFORMA +2 +45 *FT *$' AND tipo_item = 'producto_terminado' AND organizacion_id = org_id
ON CONFLICT (organizacion_id, producto_id) DO UPDATE SET 
    tipo = EXCLUDED.tipo, largo_ft = EXCLUDED.largo_ft, num_ejes = EXCLUDED.num_ejes;

v_total_modelos := v_total_modelos + 1;

SELECT count(*) INTO v_count FROM productos 
WHERE nombre ~* '^PLATAFORMA +3 +45 *FT *$' AND tipo_item = 'producto_terminado' AND organizacion_id = org_id;

IF v_count <> 1 THEN
    RAISE EXCEPTION 'La variante "45 ft x3" (regex: %) devolvió % productos en lugar de 1', '^PLATAFORMA +3 +45 *FT *$', v_count;
END IF;

INSERT INTO modelos (organizacion_id, producto_id, tipo, largo_ft, num_ejes)
SELECT org_id, id, 'plataforma', 45, 3
FROM productos 
WHERE nombre ~* '^PLATAFORMA +3 +45 *FT *$' AND tipo_item = 'producto_terminado' AND organizacion_id = org_id
ON CONFLICT (organizacion_id, producto_id) DO UPDATE SET 
    tipo = EXCLUDED.tipo, largo_ft = EXCLUDED.largo_ft, num_ejes = EXCLUDED.num_ejes;

v_total_modelos := v_total_modelos + 1;

SELECT count(*) INTO v_count FROM productos 
WHERE nombre ~* '^PLATAFORMA +2 +48 *FT *$' AND tipo_item = 'producto_terminado' AND organizacion_id = org_id;

IF v_count <> 1 THEN
    RAISE EXCEPTION 'La variante "48 ft x2" (regex: %) devolvió % productos en lugar de 1', '^PLATAFORMA +2 +48 *FT *$', v_count;
END IF;

INSERT INTO modelos (organizacion_id, producto_id, tipo, largo_ft, num_ejes)
SELECT org_id, id, 'plataforma', 48, 2
FROM productos 
WHERE nombre ~* '^PLATAFORMA +2 +48 *FT *$' AND tipo_item = 'producto_terminado' AND organizacion_id = org_id
ON CONFLICT (organizacion_id, producto_id) DO UPDATE SET 
    tipo = EXCLUDED.tipo, largo_ft = EXCLUDED.largo_ft, num_ejes = EXCLUDED.num_ejes;

v_total_modelos := v_total_modelos + 1;

SELECT count(*) INTO v_count FROM productos 
WHERE nombre ~* '^PLATAFORMA +3 +48 *FT *$' AND tipo_item = 'producto_terminado' AND organizacion_id = org_id;

IF v_count <> 1 THEN
    RAISE EXCEPTION 'La variante "48 ft x3" (regex: %) devolvió % productos en lugar de 1', '^PLATAFORMA +3 +48 *FT *$', v_count;
END IF;

INSERT INTO modelos (organizacion_id, producto_id, tipo, largo_ft, num_ejes)
SELECT org_id, id, 'plataforma', 48, 3
FROM productos 
WHERE nombre ~* '^PLATAFORMA +3 +48 *FT *$' AND tipo_item = 'producto_terminado' AND organizacion_id = org_id
ON CONFLICT (organizacion_id, producto_id) DO UPDATE SET 
    tipo = EXCLUDED.tipo, largo_ft = EXCLUDED.largo_ft, num_ejes = EXCLUDED.num_ejes;

v_total_modelos := v_total_modelos + 1;

IF v_total_modelos <> 10 THEN
    RAISE EXCEPTION 'Se insertaron % modelos en lugar de los 10 esperados', v_total_modelos;
END IF;

-- 3. GRUPOS Y OPCIONES

-- Grupo: Marca de ejes
INSERT INTO grupos_configuracion (organizacion_id, clave, nombre, seleccion, aplica_a, regla, notas, unidad_precio, cantidad, medidas, orden)
VALUES (org_id, 'eje', 'Marca de ejes', 'unica', ARRAY['plataforma','dolly','gondola','jaula','caja_seca']::text[], NULL, NULL, 'pieza', '= nº de ejes', NULL, 10)
ON CONFLICT (organizacion_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, seleccion = EXCLUDED.seleccion, aplica_a = EXCLUDED.aplica_a, regla = EXCLUDED.regla, notas = EXCLUDED.notas, unidad_precio = EXCLUDED.unidad_precio, cantidad = EXCLUDED.cantidad, medidas = EXCLUDED.medidas, orden = EXCLUDED.orden
RETURNING id INTO v_grupo_id;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'fleet_master', 'Fleet Master', 20099.99, NULL, NULL, NULL, 'TARIFARIO', '{"CSV_GONDOLA":19905.6,"DATOS_EQUIPAMIENTO":24421}'::jsonb, NULL, NULL, ARRAY['FLET MASTER', 'FLEET MASTER']::text[], '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'ampro', 'Ampro', 22231.4, NULL, NULL, NULL, 'TARIFARIO', '{"CSV_GONDOLA":21692,"DATOS_EQUIPAMIENTO":24421}'::jsonb, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'fcr', 'FCR', NULL, NULL, NULL, 'Solo en el manual (proveedor Cadeco). Falta precio.', NULL, NULL, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'prat_max', 'Prat Max', NULL, NULL, NULL, 'Solo en el manual. Falta precio.', NULL, NULL, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'hj', 'HJ', NULL, NULL, NULL, 'Solo en el manual. Falta precio.', NULL, NULL, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

-- Grupo: Suspensión
INSERT INTO grupos_configuracion (organizacion_id, clave, nombre, seleccion, aplica_a, regla, notas, unidad_precio, cantidad, medidas, orden)
VALUES (org_id, 'suspension', 'Suspensión', 'unica', ARRAY['plataforma','dolly','gondola','jaula','caja_seca']::text[], '{"texto": "clase alta implica retráctil grande; clase normal implica retráctil chico"}'::jsonb, NULL, 'kit por eje', '= nº de ejes', NULL, 20)
ON CONFLICT (organizacion_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, seleccion = EXCLUDED.seleccion, aplica_a = EXCLUDED.aplica_a, regla = EXCLUDED.regla, notas = EXCLUDED.notas, unidad_precio = EXCLUDED.unidad_precio, cantidad = EXCLUDED.cantidad, medidas = EXCLUDED.medidas, orden = EXCLUDED.orden
RETURNING id INTO v_grupo_id;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'fleet_master', 'Fleet Master (normal)', 23118, NULL, 'normal', NULL, 'TARIFARIO', '{"CSV_GONDOLA":23118,"DATOS_EQUIPAMIENTO":23118}'::jsonb, NULL, NULL, ARRAY['SUSPENSIÓN FLEET MASTER']::text[], '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'ampro', 'Ampro (normal)', 23118, NULL, 'normal', NULL, 'TARIFARIO', '{"CSV_GONDOLA":23118,"DATOS_EQUIPAMIENTO":23118}'::jsonb, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'hendrickson', 'Hendrickson HT300 (normal)', 35844, NULL, 'normal', NULL, 'TARIFARIO', '{"CSV_GONDOLA":35844,"DATOS_EQUIPAMIENTO":23118}'::jsonb, NULL, NULL, ARRAY['HENDRICKS']::text[], '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'fcr', 'FCR (normal)', NULL, NULL, 'normal', 'Solo en el manual. Falta precio.', NULL, NULL, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'alta_hendrickson', 'Hendrickson alta HT300US', 43700, NULL, 'alta', NULL, 'TARIFARIO', '{"CSV_GONDOLA":46783.62,"DATOS_EQUIPAMIENTO":23118}'::jsonb, NULL, NULL, ARRAY['ALTA HENDRICKS', 'SUSPENSIÓN ALTA HENDRICKSON']::text[], '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'hj_alta', 'HJ tipo Low alta HT300US', 28478, NULL, 'alta', 'Solo se usa en góndola según el manual.', 'TARIFARIO', '{"CSV_GONDOLA":25000}'::jsonb, NULL, NULL, ARRAY['SUSPENSION HJ ALTA']::text[], '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'alta_fleet_master', 'Fleet Master alta', NULL, NULL, 'alta', 'Solo en el cotizador; su 23,118 parece provisional. Confirmar si existe.', NULL, '{"DATOS_EQUIPAMIENTO":23118}'::jsonb, NULL, NULL, ARRAY['ALTA FM']::text[], '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'phm', 'PHM', NULL, NULL, NULL, 'Solo en el costeo de góndola.', NULL, '{"CSV_GONDOLA":30000}'::jsonb, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'sin_suspension', 'Sin suspensión', 0, NULL, NULL, NULL, 'definido', NULL, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

-- Grupo: Patines
INSERT INTO grupos_configuracion (organizacion_id, clave, nombre, seleccion, aplica_a, regla, notas, unidad_precio, cantidad, medidas, orden)
VALUES (org_id, 'patin', 'Patines', 'unica', ARRAY['plataforma','gondola','jaula','caja_seca']::text[], NULL, NULL, 'por confirmar (pieza o par)', '1 o 2 juegos', NULL, 30)
ON CONFLICT (organizacion_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, seleccion = EXCLUDED.seleccion, aplica_a = EXCLUDED.aplica_a, regla = EXCLUDED.regla, notas = EXCLUDED.notas, unidad_precio = EXCLUDED.unidad_precio, cantidad = EXCLUDED.cantidad, medidas = EXCLUDED.medidas, orden = EXCLUDED.orden
RETURNING id INTO v_grupo_id;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'hj', 'HJ', 5798.81, NULL, NULL, NULL, 'TARIFARIO', '{"CSV_GONDOLA":5646.88}'::jsonb, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'ampro', 'Ampro', 5336, NULL, NULL, NULL, 'TARIFARIO', '{"CSV_GONDOLA":5916}'::jsonb, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'holland', 'Holland (Mark V)', 13461.4, NULL, NULL, NULL, 'TARIFARIO', '{"CSV_GONDOLA":17980}'::jsonb, NULL, NULL, ARRAY['HOLAND MARK V']::text[], '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'flet_master', 'Fleet Master', NULL, NULL, NULL, 'Solo en el manual. Falta precio.', NULL, NULL, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

-- Grupo: Piso
INSERT INTO grupos_configuracion (organizacion_id, clave, nombre, seleccion, aplica_a, regla, notas, unidad_precio, cantidad, medidas, orden)
VALUES (org_id, 'piso', 'Piso', 'unica', ARRAY['plataforma']::text[], NULL, 'En DATOS DE EQUIPAMIENTO casi todos los pisos valen 35,000 (provisional); se usa TARIFARIO.', NULL, NULL, NULL, 40)
ON CONFLICT (organizacion_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, seleccion = EXCLUDED.seleccion, aplica_a = EXCLUDED.aplica_a, regla = EXCLUDED.regla, notas = EXCLUDED.notas, unidad_precio = EXCLUDED.unidad_precio, cantidad = EXCLUDED.cantidad, medidas = EXCLUDED.medidas, orden = EXCLUDED.orden
RETURNING id INTO v_grupo_id;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'pino', 'Madera de pino', 22000, NULL, NULL, NULL, 'TARIFARIO', NULL, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'encino', 'Madera de encino', 22000, NULL, NULL, NULL, 'TARIFARIO', NULL, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'plastico_cafe', 'Plástico café', 35000, NULL, NULL, NULL, 'TARIFARIO', NULL, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'plastico_negro', 'Plástico negro', 36182.72, NULL, NULL, NULL, 'TARIFARIO', NULL, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'laminado', 'Laminado', 28224, NULL, NULL, NULL, 'TARIFARIO', NULL, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'laminado_madera', 'Laminado con base de madera', 50000, NULL, NULL, NULL, 'TARIFARIO', NULL, NULL, NULL, ARRAY['PISO LAMIN C/MADERA']::text[], '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'laminado_plastico', 'Laminado con base de plástico', 63500, NULL, NULL, NULL, 'TARIFARIO', NULL, NULL, NULL, ARRAY['PISO LAMIN C/PLASTICO']::text[], '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'antiderrapante', 'Antiderrapante', 22000, NULL, NULL, NULL, 'TARIFARIO', NULL, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'encino_centro_plastico_lados', 'Encino al centro y plástico a los lados', NULL, NULL, NULL, 'Solo en el cotizador; 35,000 es el valor repetido de la lista, parece provisional.', NULL, '{"DATOS_EQUIPAMIENTO":35000}'::jsonb, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'sin_piso', 'Sin piso', 0, NULL, NULL, NULL, 'definido', NULL, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

-- Grupo: Riel
INSERT INTO grupos_configuracion (organizacion_id, clave, nombre, seleccion, aplica_a, regla, notas, unidad_precio, cantidad, medidas, orden)
VALUES (org_id, 'riel', 'Riel', 'unica', ARRAY['plataforma']::text[], NULL, NULL, NULL, NULL, NULL, 50)
ON CONFLICT (organizacion_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, seleccion = EXCLUDED.seleccion, aplica_a = EXCLUDED.aplica_a, regla = EXCLUDED.regla, notas = EXCLUDED.notas, unidad_precio = EXCLUDED.unidad_precio, cantidad = EXCLUDED.cantidad, medidas = EXCLUDED.medidas, orden = EXCLUDED.orden
RETURNING id INTO v_grupo_id;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'con_riel', 'Con riel', 5805, NULL, NULL, NULL, 'TARIFARIO', '{"DATOS_EQUIPAMIENTO":6240}'::jsonb, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'sin_riel', 'Sin riel', 0, NULL, NULL, NULL, 'definido', NULL, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

-- Grupo: Matracas / winches
INSERT INTO grupos_configuracion (organizacion_id, clave, nombre, seleccion, aplica_a, regla, notas, unidad_precio, cantidad, medidas, orden)
VALUES (org_id, 'matracas', 'Matracas / winches', 'unica', ARRAY['plataforma']::text[], NULL, NULL, NULL, 'típico 10', NULL, 60)
ON CONFLICT (organizacion_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, seleccion = EXCLUDED.seleccion, aplica_a = EXCLUDED.aplica_a, regla = EXCLUDED.regla, notas = EXCLUDED.notas, unidad_precio = EXCLUDED.unidad_precio, cantidad = EXCLUDED.cantidad, medidas = EXCLUDED.medidas, orden = EXCLUDED.orden
RETURNING id INTO v_grupo_id;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'corrediza', 'Matraca corrediza', 307.4, NULL, NULL, NULL, 'TARIFARIO', NULL, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'soldable', 'Matraca soldable', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'sin_matracas', 'Sin matracas', 0, NULL, NULL, NULL, 'definido', NULL, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

-- Grupo: Gancho de arrastre
INSERT INTO grupos_configuracion (organizacion_id, clave, nombre, seleccion, aplica_a, regla, notas, unidad_precio, cantidad, medidas, orden)
VALUES (org_id, 'gancho', 'Gancho de arrastre', 'unica', ARRAY['plataforma','gondola']::text[], '{"texto": "sin gancho: el jalón de arrastre pasa a 0"}'::jsonb, NULL, NULL, NULL, NULL, 70)
ON CONFLICT (organizacion_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, seleccion = EXCLUDED.seleccion, aplica_a = EXCLUDED.aplica_a, regla = EXCLUDED.regla, notas = EXCLUDED.notas, unidad_precio = EXCLUDED.unidad_precio, cantidad = EXCLUDED.cantidad, medidas = EXCLUDED.medidas, orden = EXCLUDED.orden
RETURNING id INTO v_grupo_id;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'holland_8_10', 'Holland 8/10 barrenos', 6948.4, NULL, NULL, NULL, 'TARIFARIO', '{"CSV_GONDOLA":6844,"DATOS_EQUIPAMIENTO":7100}'::jsonb, NULL, NULL, ARRAY['GANCHO HOLLAND 10 BARRENOS', 'HOLLAN']::text[], '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'premier_8', 'Premier 8 barrenos', 12979.24, NULL, NULL, NULL, 'TARIFARIO', '{"CSV_GONDOLA":11890,"DATOS_EQUIPAMIENTO":8000}'::jsonb, NULL, NULL, ARRAY['GANCHO PREMIER 10 BARRENOS']::text[], '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'premier_bestia_6', 'Premier Bestia 6 barrenos', 21892.68, NULL, NULL, NULL, 'TARIFARIO', '{"CSV_GONDOLA":28040.98,"DATOS_EQUIPAMIENTO":8000}'::jsonb, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'sin_gancho', 'Sin gancho', 0, NULL, NULL, NULL, 'definido', NULL, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

-- Grupo: Frente
INSERT INTO grupos_configuracion (organizacion_id, clave, nombre, seleccion, aplica_a, regla, notas, unidad_precio, cantidad, medidas, orden)
VALUES (org_id, 'frente', 'Frente', 'unica_con_medida', ARRAY['plataforma']::text[], NULL, 'El cotizador separa tipo y medida; el tarifario las junta. Aquí quedan como tipo por medida. ''CONCHA A 2.35 M'' estaba duplicada.', NULL, NULL, NULL, 80)
ON CONFLICT (organizacion_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, seleccion = EXCLUDED.seleccion, aplica_a = EXCLUDED.aplica_a, regla = EXCLUDED.regla, notas = EXCLUDED.notas, unidad_precio = EXCLUDED.unidad_precio, cantidad = EXCLUDED.cantidad, medidas = EXCLUDED.medidas, orden = EXCLUDED.orden
RETURNING id INTO v_grupo_id;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'concha_laminada', 'Concha laminada', NULL, '{"1.20":6160,"1.50":7500,"1.70":6891}'::jsonb, NULL, NULL, 'TARIFARIO', NULL, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'concha_lisa_reforzada', 'Concha lisa reforzada', NULL, '{"1.20":7536}'::jsonb, NULL, NULL, 'TARIFARIO', NULL, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'concha', 'Concha (tipo sin especificar)', NULL, '{"1.00":6240,"1.10":5891,"1.40":8800,"1.50":7680,"2.00":10000,"2.35":11750}'::jsonb, NULL, 'Confirmar si ''concha'' es laminada o lisa. A 1.50 m hay dos precios (7,500 laminada y 7,680 concha).', 'TARIFARIO', NULL, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'concha_madera', 'Concha de madera', NULL, NULL, NULL, 'Solo en el cotizador, sin precio.', NULL, NULL, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'burro_laminado', 'Burro laminado', NULL, '{"1.20":5800,"1.50":7250,"1.80":8700}'::jsonb, NULL, NULL, 'TARIFARIO', NULL, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'burro_madera', 'Burro de madera', NULL, '{"1.20":4515}'::jsonb, NULL, NULL, 'TARIFARIO', NULL, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'sin_frente', 'Sin frente', 0, NULL, NULL, NULL, 'definido', NULL, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

-- Grupo: Redilas
INSERT INTO grupos_configuracion (organizacion_id, clave, nombre, seleccion, aplica_a, regla, notas, unidad_precio, cantidad, medidas, orden)
VALUES (org_id, 'redilas', 'Redilas', 'unica', ARRAY['plataforma']::text[], '{"texto": "con redilas: suma 444 tornillos con tuerca y rondana, 48 chavetas y 6 L de pintura"}'::jsonb, NULL, NULL, NULL, NULL, 90)
ON CONFLICT (organizacion_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, seleccion = EXCLUDED.seleccion, aplica_a = EXCLUDED.aplica_a, regla = EXCLUDED.regla, notas = EXCLUDED.notas, unidad_precio = EXCLUDED.unidad_precio, cantidad = EXCLUDED.cantidad, medidas = EXCLUDED.medidas, orden = EXCLUDED.orden
RETURNING id INTO v_grupo_id;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, '70', 'Redilas de 70 cm', 35000, NULL, NULL, NULL, 'TARIFARIO', NULL, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, '75', 'Redilas de 75 cm', 35500, NULL, NULL, NULL, 'TARIFARIO', NULL, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, '80', 'Redilas de 80 cm', 36000, NULL, NULL, NULL, 'TARIFARIO', NULL, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, '90', 'Redilas de 90 cm', NULL, NULL, NULL, 'Solo en el cotizador (su 2,500 es provisional).', NULL, NULL, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, '100', 'Redilas de 1 m', 42000, NULL, NULL, NULL, 'TARIFARIO', NULL, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'sin_redilas', 'Sin redilas', 0, NULL, NULL, NULL, 'definido', NULL, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

-- Grupo: Sistema retráctil
INSERT INTO grupos_configuracion (organizacion_id, clave, nombre, seleccion, aplica_a, regla, notas, unidad_precio, cantidad, medidas, orden)
VALUES (org_id, 'retractil', 'Sistema retráctil', 'unica', ARRAY['plataforma','dolly','gondola','jaula','caja_seca']::text[], NULL, NULL, NULL, '0 a 2', NULL, 100)
ON CONFLICT (organizacion_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, seleccion = EXCLUDED.seleccion, aplica_a = EXCLUDED.aplica_a, regla = EXCLUDED.regla, notas = EXCLUDED.notas, unidad_precio = EXCLUDED.unidad_precio, cantidad = EXCLUDED.cantidad, medidas = EXCLUDED.medidas, orden = EXCLUDED.orden
RETURNING id INTO v_grupo_id;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'grande', 'Retráctil grande', 15000, NULL, NULL, 'Va con suspensión alta.', 'TARIFARIO', '{"CSV_GONDOLA":15000}'::jsonb, NULL, NULL, ARRAY['SISTEMA RETRÁCTIL']::text[], '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'chico', 'Retráctil chico (UBL)', 15000, NULL, NULL, 'Va con suspensión normal.', 'TARIFARIO', '{"CSV_GONDOLA":15000}'::jsonb, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'paleta', 'Retráctil paleta', NULL, NULL, NULL, 'Solo en el costeo de góndola.', NULL, '{"CSV_GONDOLA":15000}'::jsonb, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'sin_retractil', 'Sin sistema retráctil', 0, NULL, NULL, NULL, 'definido', NULL, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

-- Grupo: Rines
INSERT INTO grupos_configuracion (organizacion_id, clave, nombre, seleccion, aplica_a, regla, notas, unidad_precio, cantidad, medidas, orden)
VALUES (org_id, 'rines', 'Rines', 'unica_con_cantidad', ARRAY['plataforma','dolly','gondola','jaula','caja_seca']::text[], NULL, NULL, 'pieza', '0 a 12', '["24.5","22.5"]'::jsonb, 110)
ON CONFLICT (organizacion_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, seleccion = EXCLUDED.seleccion, aplica_a = EXCLUDED.aplica_a, regla = EXCLUDED.regla, notas = EXCLUDED.notas, unidad_precio = EXCLUDED.unidad_precio, cantidad = EXCLUDED.cantidad, medidas = EXCLUDED.medidas, orden = EXCLUDED.orden
RETURNING id INTO v_grupo_id;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'acero', 'Rines de acero', 1391.97, NULL, NULL, NULL, 'TARIFARIO', NULL, ARRAY['Fleet Master', 'Acurrai', 'Ampro']::text[], NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'aluminio', 'Rines de aluminio', 4268.8, NULL, NULL, NULL, 'TARIFARIO', NULL, ARRAY['Fleet Master', 'Fleet Master trapezoidal', 'Ampro', 'Ampro trapezoidal']::text[], NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'cliente', 'Proporciona el cliente', 0, NULL, NULL, NULL, 'definido', NULL, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'sin_rines', 'Sin rines', 0, NULL, NULL, NULL, 'definido', NULL, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

-- Grupo: Llantas
INSERT INTO grupos_configuracion (organizacion_id, clave, nombre, seleccion, aplica_a, regla, notas, unidad_precio, cantidad, medidas, orden)
VALUES (org_id, 'llantas', 'Llantas', 'unica_con_cantidad', ARRAY['plataforma','dolly','gondola','jaula','caja_seca']::text[], NULL, NULL, 'pieza', '0 a 12', '["24.5","22.5"]'::jsonb, 120)
ON CONFLICT (organizacion_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, seleccion = EXCLUDED.seleccion, aplica_a = EXCLUDED.aplica_a, regla = EXCLUDED.regla, notas = EXCLUDED.notas, unidad_precio = EXCLUDED.unidad_precio, cantidad = EXCLUDED.cantidad, medidas = EXCLUDED.medidas, orden = EXCLUDED.orden
RETURNING id INTO v_grupo_id;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'cerex', 'Cerex', 3586, NULL, NULL, NULL, 'TARIFARIO', NULL, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'firestone', 'Firestone', 8790, NULL, NULL, NULL, 'TARIFARIO', NULL, NULL, NULL, ARRAY['FIRESTON LINEAL']::text[], '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'royal_black', 'Royal Black', 5600, NULL, NULL, NULL, 'TARIFARIO', NULL, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'bf_goodrich', 'BF Goodrich', 11750, NULL, NULL, NULL, 'TARIFARIO', NULL, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'eudemon', 'Eudemon', 5400, NULL, NULL, NULL, 'TARIFARIO', NULL, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'chinas', 'Chinas', 4000, NULL, NULL, NULL, 'TARIFARIO', NULL, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'valiant', 'Valiant', 3581, NULL, NULL, NULL, 'TARIFARIO', NULL, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'amulet', 'Amulet', 5400.01, NULL, NULL, NULL, 'TARIFARIO', NULL, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'kpatos_lineal', 'K Patos lineal', NULL, NULL, NULL, 'Solo en el manual.', NULL, NULL, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'kpatos_traccion', 'K Patos tracción', NULL, NULL, NULL, 'Solo en el manual.', NULL, NULL, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'godshield_lineal', 'Godshield lineal', NULL, NULL, NULL, 'Solo en el manual.', NULL, NULL, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'roadmaster', 'Road Master', NULL, NULL, NULL, 'Solo en el inventario de llantas.', NULL, NULL, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'sin_llantas', 'Sin llantas', 0, NULL, NULL, NULL, 'definido', NULL, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

-- Grupo: Plafones de carrito
INSERT INTO grupos_configuracion (organizacion_id, clave, nombre, seleccion, aplica_a, regla, notas, unidad_precio, cantidad, medidas, orden)
VALUES (org_id, 'plafones', 'Plafones de carrito', 'cantidad', ARRAY['plataforma']::text[], NULL, 'El cotizador trae además plafón ámbar y rojo a 400 (formato anterior).', NULL, NULL, NULL, 130)
ON CONFLICT (organizacion_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, seleccion = EXCLUDED.seleccion, aplica_a = EXCLUDED.aplica_a, regla = EXCLUDED.regla, notas = EXCLUDED.notas, unidad_precio = EXCLUDED.unidad_precio, cantidad = EXCLUDED.cantidad, medidas = EXCLUDED.medidas, orden = EXCLUDED.orden
RETURNING id INTO v_grupo_id;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'ambar_laterales', 'Ámbar laterales', 168.2, NULL, NULL, NULL, 'TARIFARIO', NULL, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'rojo_laterales', 'Rojos laterales', 168.2, NULL, NULL, NULL, 'TARIFARIO', NULL, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'ambar_estribo', 'Ámbar en estribo', 168.2, NULL, NULL, NULL, 'TARIFARIO', NULL, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'rojo_estribo', 'Rojos en estribo', 168.2, NULL, NULL, NULL, 'TARIFARIO', NULL, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

-- Grupo: Kit de aire / ABS
INSERT INTO grupos_configuracion (organizacion_id, clave, nombre, seleccion, aplica_a, regla, notas, unidad_precio, cantidad, medidas, orden)
VALUES (org_id, 'abs', 'Kit de aire / ABS', 'derivada', ARRAY['plataforma','dolly','gondola','jaula','caja_seca']::text[], '{"texto": "se deriva del nº de ejes y retráctiles; el tarifario solo distingue 2 y 3 ejes (23,000 / 27,000)"}'::jsonb, NULL, NULL, NULL, NULL, 140)
ON CONFLICT (organizacion_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, seleccion = EXCLUDED.seleccion, aplica_a = EXCLUDED.aplica_a, regla = EXCLUDED.regla, notas = EXCLUDED.notas, unidad_precio = EXCLUDED.unidad_precio, cantidad = EXCLUDED.cantidad, medidas = EXCLUDED.medidas, orden = EXCLUDED.orden
RETURNING id INTO v_grupo_id;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, '2e_sin_retractil', '2 ejes sin retráctil', 22000, NULL, NULL, NULL, 'CSV_GONDOLA', '{"TARIFARIO":23000}'::jsonb, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, '2e_1_retractil', '2 ejes 1 retráctil', 26700, NULL, NULL, NULL, 'CSV_GONDOLA', '{"TARIFARIO":23000}'::jsonb, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, '3e_1_retractil', '3 ejes 1 retráctil', 27200, NULL, NULL, NULL, 'CSV_GONDOLA', '{"TARIFARIO":27000}'::jsonb, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, '3e_2_retractil', '3 ejes 2 retráctiles', 30500, NULL, NULL, NULL, 'CSV_GONDOLA', '{"TARIFARIO":27000}'::jsonb, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

-- Grupo: Quinta
INSERT INTO grupos_configuracion (organizacion_id, clave, nombre, seleccion, aplica_a, regla, notas, unidad_precio, cantidad, medidas, orden)
VALUES (org_id, 'quinta', 'Quinta', 'unica', ARRAY['dolly']::text[], NULL, NULL, NULL, NULL, NULL, 150)
ON CONFLICT (organizacion_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, seleccion = EXCLUDED.seleccion, aplica_a = EXCLUDED.aplica_a, regla = EXCLUDED.regla, notas = EXCLUDED.notas, unidad_precio = EXCLUDED.unidad_precio, cantidad = EXCLUDED.cantidad, medidas = EXCLUDED.medidas, orden = EXCLUDED.orden
RETURNING id INTO v_grupo_id;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'holland', 'Holland', 28998.81, NULL, NULL, NULL, 'TARIFARIO', '{"PRES_DOLLY":29998.81}'::jsonb, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'fontaine', 'Fontaine', NULL, NULL, NULL, 'Solo en el manual.', NULL, NULL, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

-- Grupo: Dona (dolly)
INSERT INTO grupos_configuracion (organizacion_id, clave, nombre, seleccion, aplica_a, regla, notas, unidad_precio, cantidad, medidas, orden)
VALUES (org_id, 'dona', 'Dona (dolly)', 'unica', ARRAY['dolly']::text[], '{"texto": "debe corresponder al tipo de gancho de la plana"}'::jsonb, NULL, NULL, NULL, NULL, 160)
ON CONFLICT (organizacion_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, seleccion = EXCLUDED.seleccion, aplica_a = EXCLUDED.aplica_a, regla = EXCLUDED.regla, notas = EXCLUDED.notas, unidad_precio = EXCLUDED.unidad_precio, cantidad = EXCLUDED.cantidad, medidas = EXCLUDED.medidas, orden = EXCLUDED.orden
RETURNING id INTO v_grupo_id;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'holland', 'Dona Holland', 4400, NULL, NULL, NULL, 'TARIFARIO', NULL, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'premier', 'Dona Premier', 4400, NULL, NULL, NULL, 'TARIFARIO', NULL, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'bestia', 'Dona Premier Bestia', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

-- Grupo: Material de la tina
INSERT INTO grupos_configuracion (organizacion_id, clave, nombre, seleccion, aplica_a, regla, notas, unidad_precio, cantidad, medidas, orden)
VALUES (org_id, 'tina_material', 'Material de la tina', 'unica', ARRAY['gondola']::text[], NULL, 'En el costeo de góndola las vueltas y cuellos son placa Hardox; el resto A-36.', NULL, NULL, NULL, 170)
ON CONFLICT (organizacion_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, seleccion = EXCLUDED.seleccion, aplica_a = EXCLUDED.aplica_a, regla = EXCLUDED.regla, notas = EXCLUDED.notas, unidad_precio = EXCLUDED.unidad_precio, cantidad = EXCLUDED.cantidad, medidas = EXCLUDED.medidas, orden = EXCLUDED.orden
RETURNING id INTO v_grupo_id;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'a36', 'Acero A-36', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'hardox_450', 'Acero Hardox 450', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

-- Grupo: Marca de pintura
INSERT INTO grupos_configuracion (organizacion_id, clave, nombre, seleccion, aplica_a, regla, notas, unidad_precio, cantidad, medidas, orden)
VALUES (org_id, 'pintura', 'Marca de pintura', 'unica', ARRAY['plataforma','dolly','gondola','jaula','caja_seca']::text[], NULL, 'Los litros dependen del modelo y del largo (hoja PINTURA).', NULL, NULL, NULL, 180)
ON CONFLICT (organizacion_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, seleccion = EXCLUDED.seleccion, aplica_a = EXCLUDED.aplica_a, regla = EXCLUDED.regla, notas = EXCLUDED.notas, unidad_precio = EXCLUDED.unidad_precio, cantidad = EXCLUDED.cantidad, medidas = EXCLUDED.medidas, orden = EXCLUDED.orden
RETURNING id INTO v_grupo_id;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'sherwin_williams', 'Sherwin-Williams', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'La Nueva Estrella', ARRAY['SHERVI']::text[], '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'ppg', 'PPG', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Pinturas Dayman', NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'axalta', 'Axalta', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Axalta', NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

-- Grupo: Color
INSERT INTO grupos_configuracion (organizacion_id, clave, nombre, seleccion, aplica_a, regla, notas, unidad_precio, cantidad, medidas, orden)
VALUES (org_id, 'color', 'Color', 'unica', ARRAY['plataforma','dolly','gondola','jaula','caja_seca']::text[], NULL, NULL, NULL, 'hasta 2 colores', NULL, 190)
ON CONFLICT (organizacion_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, seleccion = EXCLUDED.seleccion, aplica_a = EXCLUDED.aplica_a, regla = EXCLUDED.regla, notas = EXCLUDED.notas, unidad_precio = EXCLUDED.unidad_precio, cantidad = EXCLUDED.cantidad, medidas = EXCLUDED.medidas, orden = EXCLUDED.orden
RETURNING id INTO v_grupo_id;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'rojo_claro', 'Rojo claro', 0, NULL, NULL, NULL, 'definido', NULL, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'rojo', 'Rojo', 0, NULL, NULL, NULL, 'definido', NULL, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'rojo_coca_cola', 'Rojo Coca-Cola', 0, NULL, NULL, NULL, 'definido', NULL, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'rojo_bermellon', 'Rojo bermellón', 0, NULL, NULL, NULL, 'definido', NULL, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'vino', 'Vino', 0, NULL, NULL, NULL, 'definido', NULL, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'negro', 'Negro', 0, NULL, NULL, NULL, 'definido', NULL, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'anaranjado_con_borda_blanca', 'Anaranjado con borda blanca', 0, NULL, NULL, NULL, 'definido', NULL, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'azul_rey', 'Azul rey', 0, NULL, NULL, NULL, 'definido', NULL, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'blanco', 'Blanco', 0, NULL, NULL, NULL, 'definido', NULL, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'gris', 'Gris', 0, NULL, NULL, NULL, 'definido', NULL, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'naranja', 'Naranja', 0, NULL, NULL, NULL, 'definido', NULL, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'amarillo', 'Amarillo', 0, NULL, NULL, NULL, 'definido', NULL, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'rosa', 'Rosa', 0, NULL, NULL, NULL, 'definido', NULL, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'verde', 'Verde', 0, NULL, NULL, NULL, 'definido', NULL, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'morado', 'Morado', 0, NULL, NULL, NULL, 'definido', NULL, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'cafe', 'Café', 0, NULL, NULL, NULL, 'definido', NULL, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

-- Grupo: Adicionales
INSERT INTO grupos_configuracion (organizacion_id, clave, nombre, seleccion, aplica_a, regla, notas, unidad_precio, cantidad, medidas, orden)
VALUES (org_id, 'adicionales', 'Adicionales', 'multiple_con_cantidad', ARRAY['plataforma','dolly','gondola','jaula','caja_seca']::text[], NULL, NULL, NULL, NULL, NULL, 200)
ON CONFLICT (organizacion_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, seleccion = EXCLUDED.seleccion, aplica_a = EXCLUDED.aplica_a, regla = EXCLUDED.regla, notas = EXCLUDED.notas, unidad_precio = EXCLUDED.unidad_precio, cantidad = EXCLUDED.cantidad, medidas = EXCLUDED.medidas, orden = EXCLUDED.orden
RETURNING id INTO v_grupo_id;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'polinera_grande', 'Polinera grande', 6000, NULL, NULL, NULL, 'TARIFARIO', NULL, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'polinera_puerta', 'Polinera con puerta', 10000, NULL, NULL, NULL, 'TARIFARIO', NULL, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'polinera_atravesada', 'Polinera atravesada', 6000, NULL, NULL, NULL, 'TARIFARIO', NULL, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'polinera_bicicletera', 'Polinera con bicicletera', 8000, NULL, NULL, NULL, 'TARIFARIO', NULL, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'caja_herr_chica', 'Caja de herramientas chica', 9500, NULL, NULL, NULL, 'TARIFARIO', NULL, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'caja_herr_grande', 'Caja de herramientas grande 1.10 m', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'caja_auxiliar', 'Caja auxiliar', 1500, NULL, NULL, NULL, 'TARIFARIO', NULL, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'bicicletera', 'Bicicletera', 5000, NULL, NULL, NULL, 'TARIFARIO', NULL, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'portallantas_extra', 'Portallantas extra', 3500, NULL, NULL, NULL, 'TARIFARIO', NULL, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'canastilla', 'Canastilla', 8000, NULL, NULL, NULL, 'TARIFARIO', NULL, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'pata_elefante', 'Pata de elefante', 3250, NULL, NULL, NULL, 'TARIFARIO', NULL, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'lodera_centro', 'Lodera de centro', 874, NULL, NULL, NULL, 'TARIFARIO', NULL, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'sistema_psi', 'Sistema PSI', 20000, NULL, NULL, NULL, 'TARIFARIO', NULL, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'jalon', 'Jalón', 3768, NULL, NULL, NULL, 'TARIFARIO', NULL, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'candados', 'Candados', 1450, NULL, NULL, NULL, 'TARIFARIO', '{"TARIFARIO_extras":461}'::jsonb, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'multimodal', 'Multimodal', 50000, NULL, NULL, 'Implica 12 candados y 8 cargadores 3x102.', 'TARIFARIO', NULL, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'refuerzos', 'Refuerzos', 14786, NULL, NULL, NULL, 'TARIFARIO', '{"TARIFARIO_extras":10000}'::jsonb, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'barrenado_chasis', 'Barrenado sobre chasis', 1250, NULL, NULL, NULL, 'TARIFARIO', NULL, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'doble_solera_trasera', 'Doble solera parte trasera (colita)', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'base_bolsa_piernas', 'Base completa de bolsa en piernas', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, 'amarres', 'Amarres', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '{}'::jsonb)
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;

END $$;
COMMIT;
