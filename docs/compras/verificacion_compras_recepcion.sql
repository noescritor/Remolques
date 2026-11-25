-- Suite de verificación SQL en Postgres 17 real para 20261125_02_compras_recepcion.sql
-- Prueba con columnas INT (estado actual de main) Y tras ALTER TYPE NUMERIC(14,4) (compatibilidad con Bloque G).
\pset pager off
BEGIN;

CREATE TEMP TABLE rc (caso text, ok boolean, detalle text);

\set A '00000000-0000-0000-0000-000000000001'
\set B '00000000-0000-0000-0000-000000000002'

INSERT INTO organizaciones (id, nombre) VALUES (:'A', 'Org A'), (:'B', 'Org B') ON CONFLICT (id) DO NOTHING;

INSERT INTO proveedores (id, organizacion_id, nombre, rfc, razon_social, moneda_default)
VALUES ('11111111-1111-4111-8111-111111111201', :'A', 'Prov Comp A', 'PCA010101AAA', 'Prov Comp A SA', 'MXN')
ON CONFLICT (id) DO NOTHING;

INSERT INTO productos (id, organizacion_id, nombre, descripcion, unidad, tipo, precio_unitario, costo, stock_actual, stock_reservado, stock_minimo)
VALUES
  ('prod-cr-1', :'A', 'Tornillo CR 1', 'd', 'pz', 'bien', 15, 10, 10, 0, 2),
  ('prod-cr-2', :'A', 'Placa CR 2',    'd', 'pz', 'bien', 80, 50, 5,  0, 1),
  ('prod-cr-b', :'B', 'Prod Org B',    'd', 'pz', 'bien', 20, 10, 7,  0, 1)
ON CONFLICT (id) DO UPDATE SET stock_actual = EXCLUDED.stock_actual, costo = EXCLUDED.costo, precio_unitario = EXCLUDED.precio_unitario;

CREATE FUNCTION pg_temp.run_rec(p_org uuid, p_cid uuid) RETURNS text LANGUAGE plpgsql AS $$
DECLARE r jsonb;
BEGIN
  r := public.recibir_compra_proveedor(p_org, NULL, p_cid);
  RETURN 'OK:' || r::text;
EXCEPTION WHEN OTHERS THEN
  RETURN SQLERRM;
END;
$$;

-- C0: ajustar_stock(uuid, numeric) ya fue eliminada
INSERT INTO rc SELECT 'C0 ajustar_stock(uuid, numeric) eliminada',
  NOT EXISTS (
    SELECT 1 FROM pg_proc
    WHERE pronamespace = 'public'::regnamespace
      AND proname = 'ajustar_stock'
      AND pg_get_function_identity_arguments(oid) = 'p_producto_id uuid, p_delta numeric'
  ), '';

-- C1: Recibir compra de 1 partida + 2 partidas del mismo producto (suma exacta, costo/precio intactos)
INSERT INTO compras_proveedor (id, organizacion_id, folio, proveedor_id, estado)
VALUES ('c1000000-0000-4000-8000-000000000001', :'A', 'OC-CR-001', '11111111-1111-4111-8111-111111111201', 'Pendiente');
INSERT INTO compra_items (id, compra_id, material_id, cantidad, costo_unitario) VALUES
  ('c2000000-0000-4000-8000-000000000001', 'c1000000-0000-4000-8000-000000000001', 'prod-cr-1', 4, 10),
  ('c2000000-0000-4000-8000-000000000002', 'c1000000-0000-4000-8000-000000000001', 'prod-cr-1', 6, 10),
  ('c2000000-0000-4000-8000-000000000003', 'c1000000-0000-4000-8000-000000000001', 'prod-cr-2', 3, 50);

SELECT pg_temp.run_rec(:'A', 'c1000000-0000-4000-8000-000000000001') AS r1 \gset
INSERT INTO rc SELECT 'C1 multi-partida y 2 partidas mismo producto suman exacto sin tocar costo/precio',
  (:'r1' LIKE 'OK:%'
   AND (SELECT estado FROM compras_proveedor WHERE id='c1000000-0000-4000-8000-000000000001') = 'Recibida'
   AND (SELECT stock_actual FROM productos WHERE id='prod-cr-1') = 20
   AND (SELECT stock_actual FROM productos WHERE id='prod-cr-2') = 8
   AND (SELECT costo FROM productos WHERE id='prod-cr-1') = 10
   AND (SELECT precio_unitario FROM productos WHERE id='prod-cr-1') = 15
   AND (SELECT count(*) FROM movimientos_inventario WHERE referencia = 'Compra OC-CR-001' AND tipo_movimiento = 'Entrada') = 3),
  :'r1';

-- C2: Idempotencia: segunda llamada devuelve ya_recibida=true y NO duplica stock ni movimientos
SELECT pg_temp.run_rec(:'A', 'c1000000-0000-4000-8000-000000000001') AS r2 \gset
INSERT INTO rc SELECT 'C2 segunda llamada idempotente ya_recibida=true sin duplicar stock',
  (:'r2' LIKE 'OK:%"ya_recibida": true%'
   AND (SELECT stock_actual FROM productos WHERE id='prod-cr-1') = 20
   AND (SELECT count(*) FROM movimientos_inventario WHERE referencia = 'Compra OC-CR-001') = 3),
  :'r2';

-- C3: Compra Cancelada rechazada
INSERT INTO compras_proveedor (id, organizacion_id, folio, proveedor_id, estado)
VALUES ('c1000000-0000-4000-8000-000000000002', :'A', 'OC-CR-CANC', '11111111-1111-4111-8111-111111111201', 'Cancelada');
INSERT INTO compra_items (id, compra_id, material_id, cantidad, costo_unitario)
VALUES ('c2000000-0000-4000-8000-000000000004', 'c1000000-0000-4000-8000-000000000002', 'prod-cr-1', 2, 10);
INSERT INTO rc SELECT 'C3 compra cancelada rechazada', res LIKE 'compra_cancelada%', res
FROM (SELECT pg_temp.run_rec(:'A', 'c1000000-0000-4000-8000-000000000002') res) t;

-- C4: Compra sin partidas rechazada y sigue Pendiente
INSERT INTO compras_proveedor (id, organizacion_id, folio, proveedor_id, estado)
VALUES ('c1000000-0000-4000-8000-000000000003', :'A', 'OC-CR-VACIA', '11111111-1111-4111-8111-111111111201', 'Pendiente');
INSERT INTO rc SELECT 'C4 compra sin partidas rechazada y sigue Pendiente',
  (res LIKE 'compra_sin_partidas%' AND (SELECT estado FROM compras_proveedor WHERE id='c1000000-0000-4000-8000-000000000003') = 'Pendiente'),
  res
FROM (SELECT pg_temp.run_rec(:'A', 'c1000000-0000-4000-8000-000000000003') res) t;

-- C5: Compra de otra organización -> compra_no_encontrada
INSERT INTO rc SELECT 'C5 compra desde otra organizacion rechazada',
  res LIKE 'compra_no_encontrada%', res
FROM (SELECT pg_temp.run_rec(:'B', 'c1000000-0000-4000-8000-000000000001') res) t;

-- C6: Todo-o-nada: segunda partida con producto de otra organización revierte la primera y deja Pendiente
INSERT INTO compras_proveedor (id, organizacion_id, folio, proveedor_id, estado)
VALUES ('c1000000-0000-4000-8000-000000000004', :'A', 'OC-CR-AJENO', '11111111-1111-4111-8111-111111111201', 'Pendiente');
INSERT INTO compra_items (id, compra_id, material_id, cantidad, costo_unitario) VALUES
  ('c2000000-0000-4000-8000-000000000005', 'c1000000-0000-4000-8000-000000000004', 'prod-cr-1', 5, 10),
  ('c2000000-0000-4000-8000-000000000006', 'c1000000-0000-4000-8000-000000000004', 'prod-cr-b', 2, 10);
INSERT INTO rc SELECT 'C6 producto de otra org revierte todo-o-nada y deja Pendiente',
  (res LIKE 'producto_no_encontrado%'
   AND (SELECT estado FROM compras_proveedor WHERE id='c1000000-0000-4000-8000-000000000004') = 'Pendiente'
   AND (SELECT stock_actual FROM productos WHERE id='prod-cr-1') = 20
   AND (SELECT count(*) FROM movimientos_inventario WHERE referencia = 'Compra OC-CR-AJENO') = 0),
  res
FROM (SELECT pg_temp.run_rec(:'A', 'c1000000-0000-4000-8000-000000000004') res) t;

-- C7: Cantidad fraccionaria con columnas INT rechaza con cantidad_no_entera y deja Pendiente
INSERT INTO compras_proveedor (id, organizacion_id, folio, proveedor_id, estado)
VALUES ('c1000000-0000-4000-8000-000000000005', :'A', 'OC-CR-FRAC', '11111111-1111-4111-8111-111111111201', 'Pendiente');
INSERT INTO compra_items (id, compra_id, material_id, cantidad, costo_unitario)
VALUES ('c2000000-0000-4000-8000-000000000007', 'c1000000-0000-4000-8000-000000000005', 'prod-cr-1', 2.5, 10);
INSERT INTO rc SELECT 'C7 cantidad fraccionaria con columnas INT rechaza cantidad_no_entera',
  (res LIKE 'cantidad_no_entera%'
   AND (SELECT estado FROM compras_proveedor WHERE id='c1000000-0000-4000-8000-000000000005') = 'Pendiente'
   AND (SELECT stock_actual FROM productos WHERE id='prod-cr-1') = 20),
  res
FROM (SELECT pg_temp.run_rec(:'A', 'c1000000-0000-4000-8000-000000000005') res) t;

-- C8: Tras simular Bloque G (ALTER TYPE NUMERIC(14,4)), el MISMO RPC acepta 2.5 y suma exacto (20 -> 22.5)
ALTER TABLE productos ALTER COLUMN stock_actual TYPE NUMERIC(14,4);
ALTER TABLE movimientos_inventario ALTER COLUMN cantidad TYPE NUMERIC(14,4);
SELECT pg_temp.run_rec(:'A', 'c1000000-0000-4000-8000-000000000005') AS r8 \gset
INSERT INTO rc SELECT 'C8 con columnas NUMERIC(14,4) el mismo RPC acepta 2.5 y suma exacto',
  (:'r8' LIKE 'OK:%"ya_recibida": false%'
   AND (SELECT estado FROM compras_proveedor WHERE id='c1000000-0000-4000-8000-000000000005') = 'Recibida'
   AND (SELECT stock_actual FROM productos WHERE id='prod-cr-1') = 22.5000
   AND (SELECT cantidad FROM movimientos_inventario WHERE referencia = 'Compra OC-CR-FRAC') = 2.5000),
  :'r8';

-- C9: Permisos: authenticated y anon no pueden ejecutar recibir_compra_proveedor
INSERT INTO rc SELECT 'C9a authenticated no ejecuta recibir_compra_proveedor',
  NOT has_function_privilege('authenticated', 'public.recibir_compra_proveedor(uuid,uuid,uuid)', 'EXECUTE'), '';
INSERT INTO rc SELECT 'C9b anon no ejecuta recibir_compra_proveedor',
  NOT has_function_privilege('anon', 'public.recibir_compra_proveedor(uuid,uuid,uuid)', 'EXECUTE'), '';

SELECT caso, CASE WHEN ok THEN 'PASA' ELSE 'FALLA' END AS estado, detalle FROM rc ORDER BY caso;
ROLLBACK;
