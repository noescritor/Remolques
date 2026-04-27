-- Fase 1: Migración de datos del KV Store a tablas relacionales
-- Asumimos que la tabla kv_store_feea4382 tiene las columnas "key" (TEXT) y "value" (JSONB)

-- 1. Migrar Clientes
INSERT INTO clientes (id, nombre_razon_social, nombre_contacto, telefono, correo, direccion, ciudad, estado, codigo_postal, pais, tipo_pago_preferido)
SELECT 
  value->>'id',
  value->>'nombre_razon_social',
  value->>'nombre_contacto',
  value->>'telefono',
  value->>'correo',
  value->>'direccion',
  value->>'ciudad',
  value->>'estado',
  value->>'codigo_postal',
  COALESCE(value->>'pais', 'México'),
  value->>'tipo_pago_preferido'
FROM kv_store_feea4382
WHERE key LIKE 'cliente:%'
ON CONFLICT DO NOTHING;

-- 2. Migrar Productos
INSERT INTO productos (id, tipo, nombre, descripcion, unidad, precio_unitario, costo, tasa_iva, servicio)
SELECT 
  value->>'id',
  COALESCE(value->>'tipo', 'bien'),
  value->>'nombre',
  value->>'descripcion',
  COALESCE(value->>'unidad', 'pz'),
  (value->>'precio_unitario')::NUMERIC,
  (value->>'costo')::NUMERIC,
  COALESCE((value->>'tasa_iva')::NUMERIC, 0.16),
  value->'servicio'
FROM kv_store_feea4382
WHERE key LIKE 'producto:%'
ON CONFLICT DO NOTHING;

-- 3. Migrar Cotizaciones
-- Nota: En el modelo anterior, los items vivían dentro de "items" como array JSON. 
-- Los extraeremos después.
INSERT INTO cotizaciones (id, folio, cliente_id, fecha, validez_dias, estado, con_factura, descripcion, subtotal, iva, total, nota)
SELECT 
  value->>'id',
  value->>'folio',
  value->>'cliente_id',
  (value->>'fecha')::DATE,
  COALESCE((value->>'validez_dias')::INT, 30),
  COALESCE(value->>'estado', 'Borrador'),
  COALESCE((value->>'con_factura')::BOOLEAN, true),
  value->>'descripcion',
  (value->>'subtotal')::NUMERIC,
  (value->>'iva')::NUMERIC,
  (value->>'total')::NUMERIC,
  value->>'nota'
FROM kv_store_feea4382
WHERE key LIKE 'cotizacion:%'
-- Solo migrar si el cliente existe (evitar FK error)
AND EXISTS (SELECT 1 FROM clientes WHERE id = value->>'cliente_id')
ON CONFLICT DO NOTHING;

-- 4. Migrar Items de Cotización
-- Necesitamos expandir el array JSON de items en filas individuales
INSERT INTO items_cotizacion (id, cotizacion_id, producto_id, posicion, cantidad, unidad, descripcion, precio_unitario, costo_unitario, iva_item, total_item)
SELECT 
  gen_random_uuid()::text, -- En el KV a veces los items tenían id, a veces no. Generamos uno nuevo.
  kv_store_feea4382.value->>'id',
  item->>'producto_id',
  (item->>'posicion')::INT,
  (item->>'cantidad')::NUMERIC,
  COALESCE(item->>'unidad', 'pz'),
  item->>'descripcion',
  (item->>'precio_unitario')::NUMERIC,
  (item->>'costo_unitario')::NUMERIC,
  (item->>'iva_item')::NUMERIC,
  (item->>'total_item')::NUMERIC
FROM kv_store_feea4382, jsonb_array_elements(kv_store_feea4382.value->'items') AS item
WHERE key LIKE 'cotizacion:%'
-- Asegurarnos de que la cotización padre realmente se insertó (evitar huérfanos)
AND EXISTS (SELECT 1 FROM cotizaciones WHERE id = kv_store_feea4382.value->>'id')
-- Asegurarnos de que el producto existe o es opcional
AND (item->>'producto_id' IS NULL OR EXISTS (SELECT 1 FROM productos WHERE id = item->>'producto_id'))
ON CONFLICT DO NOTHING;

-- 5. Migrar Pagos
INSERT INTO pagos (id, cotizacion_id, tipo_pago, referencia, monto, fecha)
SELECT 
  value->>'id',
  value->>'cotizacion_id',
  value->>'tipo_pago',
  value->>'referencia',
  (value->>'monto')::NUMERIC,
  (value->>'fecha')::DATE
FROM kv_store_feea4382
WHERE key LIKE 'pago:%'
-- Asegurarnos de que la cotización asociada existe
AND EXISTS (SELECT 1 FROM cotizaciones WHERE id = value->>'cotizacion_id')
ON CONFLICT DO NOTHING;

-- 6. Migrar Ajustes
INSERT INTO ajustes (id, data)
SELECT 
  '00000000-0000-0000-0000-000000000001',
  value
FROM kv_store_feea4382
WHERE key = 'ajustes'
ON CONFLICT (id) DO UPDATE SET data = EXCLUDED.data;
