-- Seed reproducible para pruebas E2E de Bloque G (Almacén desde factura CFDI)
-- Uso: psql -U tester -p 54331 -d test_almacen_g -v ON_ERROR_STOP=1 -f scripts/dev/seed_almacen_g.sql

BEGIN;

-- 1. Organización y perfil base
INSERT INTO public.organizaciones (id, nombre)
VALUES ('00000000-0000-0000-0000-000000000001', 'Leolca E2E')
ON CONFLICT (id) DO NOTHING;

-- 2. Proveedor E2E
INSERT INTO public.proveedores (id, organizacion_id, nombre, rfc, razon_social, moneda_default)
VALUES (
  '11111111-1111-4111-8111-111111111101',
  '00000000-0000-0000-0000-000000000001',
  'PROVEEDOR ALMACEN E2E',
  'PAE010101AAA',
  'PROVEEDOR ALMACEN E2E SA DE CV',
  'MXN'
)
ON CONFLICT (id) DO UPDATE SET nombre = EXCLUDED.nombre, rfc = EXCLUDED.rfc;

-- 3. Productos (bienes con stock entero y fraccional + 1 servicio)
INSERT INTO public.productos (id, organizacion_id, nombre, descripcion, unidad, tipo, precio_unitario, costo, stock_actual, stock_reservado, stock_minimo)
VALUES
  ('prod-e2e-tornillo', '00000000-0000-0000-0000-000000000001', 'Tornillo Hexagonal 1/2', 'Tornillo grado 8', 'pz', 'bien', 10, 5, 12.0000, 0, 5),
  ('prod-e2e-cable',    '00000000-0000-0000-0000-000000000001', 'Cable Calibre 12',       'Cable automotriz', 'm',  'bien', 35, 20, 12.5000, 0, 5),
  ('prod-e2e-lamina',   '00000000-0000-0000-0000-000000000001', 'Lamina Calibre 14',      'Lamina hoja 4x8',  'pza','bien', 650, 400, 4.0000, 0, 2),
  ('prod-e2e-valvula',  '00000000-0000-0000-0000-000000000001', 'Valvula Hidraulica 3/4', 'Valvula alta presion','pz','bien', 1200, 800, 2.0000, 0, 1),
  ('prod-e2e-flete',    '00000000-0000-0000-0000-000000000001', 'Flete de entrega',       'Servicio de flete','srv','servicio', 500, 300, 0, 0, 0)
ON CONFLICT (id) DO UPDATE SET
  nombre = EXCLUDED.nombre,
  stock_actual = EXCLUDED.stock_actual,
  stock_reservado = EXCLUDED.stock_reservado,
  ultimo_costo_compra = NULL,
  ultimo_costo_compra_fecha = NULL,
  ultimo_costo_compra_factura_id = NULL;

-- Limpiar recepciones/movimientos previos del seed si se re-ejecuta
DELETE FROM public.almacen_recepcion_lineas
 WHERE recepcion_id IN (
   SELECT id FROM public.almacen_recepciones
    WHERE factura_id IN (
      '33333333-3333-4333-8333-333333333301',
      '33333333-3333-4333-8333-333333333302',
      '33333333-3333-4333-8333-333333333303',
      '33333333-3333-4333-8333-333333333304'
    )
 );
DELETE FROM public.almacen_recepciones
 WHERE factura_id IN (
   '33333333-3333-4333-8333-333333333301',
   '33333333-3333-4333-8333-333333333302',
   '33333333-3333-4333-8333-333333333303',
   '33333333-3333-4333-8333-333333333304'
 );
DELETE FROM public.movimientos_inventario
 WHERE producto_id IN ('prod-e2e-tornillo','prod-e2e-cable','prod-e2e-lamina','prod-e2e-valvula');

-- 4. Compra Recibida reciente (5 dias atras) que comparte prod-e2e-lamina -> dispara posible_compra_duplicada
INSERT INTO public.compras_proveedor (id, organizacion_id, folio, proveedor_id, fecha, estado)
VALUES (
  '22222222-2222-4222-8222-222222222201',
  '00000000-0000-0000-0000-000000000001',
  'OC-E2E-DUP-01',
  '11111111-1111-4111-8111-111111111101',
  NOW() - INTERVAL '5 days',
  'Recibida'
)
ON CONFLICT (id) DO UPDATE SET estado = 'Recibida', fecha = NOW() - INTERVAL '5 days';

DELETE FROM public.compra_items WHERE compra_id = '22222222-2222-4222-8222-222222222201';
INSERT INTO public.compra_items (id, compra_id, material_id, cantidad, costo_unitario)
VALUES (
  '22222222-2222-4222-8222-222222222211',
  '22222222-2222-4222-8222-222222222201',
  'prod-e2e-lamina',
  5,
  400
);

-- 5. Alias de producto en catalogo_alias_factura (para origen = 'alias')
DELETE FROM public.catalogo_alias_factura
 WHERE organizacion_id = '00000000-0000-0000-0000-000000000001'
   AND proveedor_id = '11111111-1111-4111-8111-111111111101'
   AND descripcion_normalizada IN ('tornillo hex 1 2', 'tornillo hex 1/2');

INSERT INTO public.catalogo_alias_factura (
  organizacion_id, proveedor_id, clave_sat, descripcion_normalizada,
  destino_tipo, destino_id, factor_conversion, veces_confirmado
)
VALUES (
  '00000000-0000-0000-0000-000000000001',
  '11111111-1111-4111-8111-111111111101',
  '',
  'tornillo hex 1/2',
  'producto',
  'prod-e2e-tornillo',
  1,
  3
);

-- 6. Facturas de prueba (F-E2E-001 MXN, F-E2E-002 USD, F-E2E-003 vieja, F-E2E-004 cancelada)
INSERT INTO public.facturas_proveedor (
  id, organizacion_id, proveedor_id, folio, uuid_fiscal, fecha_emision, fecha_vencimiento,
  moneda, tipo_cambio_emision, importe, estado, concepto
)
VALUES
  ('33333333-3333-4333-8333-333333333301', '00000000-0000-0000-0000-000000000001', '11111111-1111-4111-8111-111111111101',
   'F-E2E-001', 'UUID-E2E-0001-ALMACEN', '2026-11-20', '2026-12-20', 'MXN', 1, 3115.00, 'abierta', 'Materiales taller E2E'),
  ('33333333-3333-4333-8333-333333333302', '00000000-0000-0000-0000-000000000001', '11111111-1111-4111-8111-111111111101',
   'F-E2E-002', 'UUID-E2E-0002-USD',     '2026-11-22', '2026-12-22', 'USD', 20.00, 150.00, 'abierta', 'Valvulas importadas USD'),
  ('33333333-3333-4333-8333-333333333303', '00000000-0000-0000-0000-000000000001', '11111111-1111-4111-8111-111111111101',
   'F-E2E-003-VIEJA', 'UUID-E2E-0003-VIEJA', '2026-10-01', '2026-11-01', 'MXN', 1, 700.00, 'abierta', 'Factura anterior de valvula'),
  ('33333333-3333-4333-8333-333333333304', '00000000-0000-0000-0000-000000000001', '11111111-1111-4111-8111-111111111101',
   'F-E2E-004-CANC',  'UUID-E2E-0004-CANC',  '2026-11-21', '2026-12-21', 'MXN', 1, 100.00, 'cancelada', 'Factura cancelada E2E')
ON CONFLICT (id) DO UPDATE SET
  estado = EXCLUDED.estado,
  fecha_emision = EXCLUDED.fecha_emision,
  moneda = EXCLUDED.moneda,
  tipo_cambio_emision = EXCLUDED.tipo_cambio_emision,
  importe = EXCLUDED.importe;

DELETE FROM public.factura_proveedor_partidas
 WHERE factura_id IN (
   '33333333-3333-4333-8333-333333333301',
   '33333333-3333-4333-8333-333333333302',
   '33333333-3333-4333-8333-333333333303',
   '33333333-3333-4333-8333-333333333304'
 );

INSERT INTO public.factura_proveedor_partidas (id, organizacion_id, factura_id, orden, tipo, descripcion, cantidad, clave_unidad, precio_unitario, importe)
VALUES
  -- F-E2E-001 (alias, nombre, peso KGM + doble conteo b, servicio probable)
  ('44444444-4444-4444-8444-444444444401', '00000000-0000-0000-0000-000000000001', '33333333-3333-4333-8333-333333333301', 1, 'concepto', 'TORNILLO HEX 1/2',           10,  'H87', 6.00,   60.00),
  ('44444444-4444-4444-8444-444444444402', '00000000-0000-0000-0000-000000000001', '33333333-3333-4333-8333-333333333301', 2, 'concepto', 'Cable Calibre 12 rollo',     2.5, 'MTR', 22.00,  55.00),
  ('44444444-4444-4444-8444-444444444403', '00000000-0000-0000-0000-000000000001', '33333333-3333-4333-8333-333333333301', 3, 'concepto', 'Lamina Calibre 14 acero',    100, 'KGM', 25.00,  2500.00),
  ('44444444-4444-4444-8444-444444444404', '00000000-0000-0000-0000-000000000001', '33333333-3333-4333-8333-333333333301', 4, 'concepto', 'Flete y maniobra de entrega', 1,  'E48', 500.00, 500.00),
  -- F-E2E-002 (USD TC 20)
  ('44444444-4444-4444-8444-444444444405', '00000000-0000-0000-0000-000000000001', '33333333-3333-4333-8333-333333333302', 1, 'concepto', 'Valvula Hidraulica 3/4',     3,   'H87', 50.00,  150.00),
  -- F-E2E-003-VIEJA (MXN fecha anterior)
  ('44444444-4444-4444-8444-444444444406', '00000000-0000-0000-0000-000000000001', '33333333-3333-4333-8333-333333333303', 1, 'concepto', 'Valvula Hidraulica 3/4',     1,   'H87', 700.00, 700.00),
  -- F-E2E-004-CANC (cancelada)
  ('44444444-4444-4444-8444-444444444407', '00000000-0000-0000-0000-000000000001', '33333333-3333-4333-8333-333333333304', 1, 'concepto', 'TORNILLO HEX 1/2',           2,   'H87', 50.00,  100.00);

COMMIT;
