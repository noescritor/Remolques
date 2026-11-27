-- Seed reproducible para pruebas de recepción atómica de compras (compras-recepcion-2026-11-24)
-- Uso: psql -h 127.0.0.1 -p 54331 -U tester -d test_compras_rec -v ON_ERROR_STOP=1 -f scripts/dev/seed_compras_recepcion.sql

BEGIN;

INSERT INTO public.organizaciones (id, nombre)
VALUES ('00000000-0000-0000-0000-000000000001', 'Leolca E2E')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.proveedores (id, organizacion_id, nombre, rfc, razon_social, moneda_default)
VALUES (
  '11111111-1111-4111-8111-111111111301',
  '00000000-0000-0000-0000-000000000001',
  'PROVEEDOR COMPRAS E2E',
  'PCE010101AAA',
  'PROVEEDOR COMPRAS E2E SA DE CV',
  'MXN'
)
ON CONFLICT (id) DO UPDATE SET nombre = EXCLUDED.nombre;

INSERT INTO public.productos (id, organizacion_id, nombre, descripcion, unidad, tipo, precio_unitario, costo, stock_actual, stock_reservado, stock_minimo)
VALUES
  ('prod-cr-e2e-1', '00000000-0000-0000-0000-000000000001', 'Eje Reforzado 3500lb', 'Eje para remolque', 'pz', 'bien', 2500, 1800, 10, 0, 2),
  ('prod-cr-e2e-2', '00000000-0000-0000-0000-000000000001', 'Muelle 4 Hojas', 'Muelle', 'pz', 'bien', 900, 600, 4, 0, 1)
ON CONFLICT (id) DO UPDATE SET
  organizacion_id = EXCLUDED.organizacion_id,
  stock_actual = EXCLUDED.stock_actual,
  stock_reservado = 0;

-- Limpiar movimientos y compras previas del seed
DELETE FROM public.movimientos_inventario WHERE producto_id IN ('prod-cr-e2e-1', 'prod-cr-e2e-2');
DELETE FROM public.compra_items WHERE compra_id IN (
  '22222222-2222-4222-8222-222222222301',
  '22222222-2222-4222-8222-222222222302',
  '22222222-2222-4222-8222-222222222303'
);
DELETE FROM public.compras_proveedor WHERE id IN (
  '22222222-2222-4222-8222-222222222301',
  '22222222-2222-4222-8222-222222222302',
  '22222222-2222-4222-8222-222222222303'
);

-- OC-CR-REPRO: para repro_recepcion_compra.cjs (antes/después: stock 10 -> 15)
INSERT INTO public.compras_proveedor (id, organizacion_id, folio, proveedor_id, fecha, estado)
VALUES (
  '22222222-2222-4222-8222-222222222301',
  '00000000-0000-0000-0000-000000000001',
  'OC-CR-REPRO',
  '11111111-1111-4111-8111-111111111301',
  NOW(),
  'Pendiente'
);
INSERT INTO public.compra_items (id, compra_id, material_id, cantidad, costo_unitario) VALUES
  ('22222222-2222-4222-8222-222222222311', '22222222-2222-4222-8222-222222222301', 'prod-cr-e2e-1', 5, 1800);

-- OC-CR-E2E: para navegador (2 partidas: prod-cr-e2e-1 x3 y prod-cr-e2e-2 x2)
INSERT INTO public.compras_proveedor (id, organizacion_id, folio, proveedor_id, fecha, estado)
VALUES (
  '22222222-2222-4222-8222-222222222302',
  '00000000-0000-0000-0000-000000000001',
  'OC-CR-E2E',
  '11111111-1111-4111-8111-111111111301',
  NOW(),
  'Pendiente'
);
INSERT INTO public.compra_items (id, compra_id, material_id, cantidad, costo_unitario) VALUES
  ('22222222-2222-4222-8222-222222222312', '22222222-2222-4222-8222-222222222302', 'prod-cr-e2e-1', 3, 1800),
  ('22222222-2222-4222-8222-222222222313', '22222222-2222-4222-8222-222222222302', 'prod-cr-e2e-2', 2, 600);

-- OC-CR-CONC: para concurrencia (2 sesiones simultáneas -> +7 una sola vez)
INSERT INTO public.compras_proveedor (id, organizacion_id, folio, proveedor_id, fecha, estado)
VALUES (
  '22222222-2222-4222-8222-222222222303',
  '00000000-0000-0000-0000-000000000001',
  'OC-CR-CONC',
  '11111111-1111-4111-8111-111111111301',
  NOW(),
  'Pendiente'
);
INSERT INTO public.compra_items (id, compra_id, material_id, cantidad, costo_unitario) VALUES
  ('22222222-2222-4222-8222-222222222314', '22222222-2222-4222-8222-222222222303', 'prod-cr-e2e-2', 7, 600);

COMMIT;
