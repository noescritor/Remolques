-- Verificación integral del Bloque G contra PostgreSQL real
\set ON_ERROR_STOP off
\pset pager off
BEGIN;
SET search_path = public;
CREATE TEMP TABLE rg(caso text, ok boolean, detalle text);

\set A '00000000-0000-0000-0000-000000000001'
\set B '11111111-1111-1111-1111-111111111111'

INSERT INTO organizaciones (id, nombre) VALUES (:'B', 'Org B Almacen G') ON CONFLICT DO NOTHING;
INSERT INTO proveedores (id, organizacion_id, nombre) VALUES
  ('a2000000-0000-0000-0000-000000000001', :'A', 'PROVEEDOR ALMACEN A'),
  ('b2000000-0000-0000-0000-000000000001', :'B', 'PROVEEDOR ALMACEN B')
ON CONFLICT DO NOTHING;

-- Productos: 2 bienes (uno con ID no-UUID para probar TEXT), 1 servicio, 1 de org B
INSERT INTO productos (id, organizacion_id, nombre, unidad, tipo, tipo_item, costo, precio_unitario, stock_actual, stock_reservado, stock_minimo) VALUES
  ('prod-g-text-1', :'A', 'Tornillo Galvanizado 1/2', 'PZA', 'bien', 'materia_prima', 10.00, 15.00, 5, 0, 2),
  ('prod-g-text-2', :'A', 'Pintura Epoxica Gris', 'LT', 'bien', 'materia_prima', 200.00, 280.00, 0, 0, 1),
  ('prod-g-serv-1', :'A', 'Servicio de Flete', 'SERV', 'servicio', 'materia_prima', 500.00, 500.00, 0, 0, 0),
  ('prod-g-orgb-1', :'B', 'Producto Org B', 'PZA', 'bien', 'materia_prima', 50.00, 75.00, 0, 0, 0)
ON CONFLICT (id) DO UPDATE SET stock_actual = EXCLUDED.stock_actual, stock_reservado = 0, ultimo_costo_compra = NULL, ultimo_costo_compra_fecha = NULL;

-- Facturas: F1 (MXN nueva), F2 (USD con TC), F3 (vieja), F4 (cancelada), FB (org B)
INSERT INTO facturas_proveedor (id, organizacion_id, proveedor_id, folio, fecha_emision, fecha_vencimiento, moneda, tipo_cambio_emision, importe, estado) VALUES
  ('f1000000-0000-0000-0000-000000000001', :'A', 'a2000000-0000-0000-0000-000000000001', 'FG-101', '2026-11-20', '2026-12-20', 'MXN', NULL, 5000, 'abierta'),
  ('f1000000-0000-0000-0000-000000000002', :'A', 'a2000000-0000-0000-0000-000000000001', 'FG-USD', '2026-11-22', '2026-12-22', 'USD', 20, 100, 'abierta'),
  ('f1000000-0000-0000-0000-000000000003', :'A', 'a2000000-0000-0000-0000-000000000001', 'FG-OLD', '2026-10-01', '2026-11-01', 'MXN', NULL, 1000, 'abierta'),
  ('f1000000-0000-0000-0000-000000000004', :'A', 'a2000000-0000-0000-0000-000000000001', 'FG-CAN', '2026-11-20', '2026-12-20', 'MXN', NULL, 1000, 'cancelada'),
  ('f1000000-0000-0000-0000-000000000009', :'B', 'b2000000-0000-0000-0000-000000000001', 'FG-B', '2026-11-20', '2026-12-20', 'MXN', NULL, 1000, 'abierta');

INSERT INTO factura_proveedor_partidas (id, organizacion_id, factura_id, tipo, descripcion, cantidad, precio_unitario, importe, clave_sat, clave_unidad, orden) VALUES
  ('d1000000-0000-0000-0000-000000000001', :'A', 'f1000000-0000-0000-0000-000000000001', 'concepto', 'TORNILLO GALV 1/2', 12.5, 12, 150, '31161500', 'H87', 1),
  ('d1000000-0000-0000-0000-000000000002', :'A', 'f1000000-0000-0000-0000-000000000001', 'concepto', 'TORNILLO GALV 1/2 EXTRA', 2.5, 12, 30, '31161500', 'H87', 2),
  ('d1000000-0000-0000-0000-000000000003', :'A', 'f1000000-0000-0000-0000-000000000001', 'concepto', 'PINTURA EPOXICA KGM', 100, 20, 2000, '31211500', 'KGM', 3),
  ('d1000000-0000-0000-0000-000000000004', :'A', 'f1000000-0000-0000-0000-000000000002', 'concepto', 'TORNILLO USD', 2, 50, 100, '31161500', 'H87', 1),
  ('d1000000-0000-0000-0000-000000000005', :'A', 'f1000000-0000-0000-0000-000000000003', 'concepto', 'TORNILLO VIEJO', 10, 8, 80, '31161500', 'H87', 1),
  ('d1000000-0000-0000-0000-000000000006', :'A', 'f1000000-0000-0000-0000-000000000004', 'concepto', 'CANCELADA', 1, 100, 100, '31161500', 'H87', 1),
  ('d1000000-0000-0000-0000-000000000009', :'B', 'f1000000-0000-0000-0000-000000000009', 'concepto', 'PARTIDA B', 1, 100, 100, '31161500', 'H87', 1);

CREATE OR REPLACE FUNCTION pg_temp.rec(p_org uuid, p_fac uuid, lin jsonb, p_doble boolean DEFAULT false) RETURNS text LANGUAGE plpgsql AS $$
DECLARE v_r jsonb;
BEGIN
  v_r := recibir_factura_almacen(p_org, NULL, p_fac, lin, p_doble, 'test');
  RETURN 'OK:' || (v_r->>'recepcion_id');
EXCEPTION WHEN OTHERS THEN RETURN SQLERRM;
END $$;

CREATE OR REPLACE FUNCTION pg_temp.anu(p_org uuid, p_rec uuid, p_mot text) RETURNS text LANGUAGE plpgsql AS $$
BEGIN
  PERFORM anular_recepcion_almacen(p_org, NULL, p_rec, p_mot);
  RETURN 'OK';
EXCEPTION WHEN OTHERS THEN RETURN SQLERRM;
END $$;

-- G1: Factura cancelada y aislamiento org
INSERT INTO rg SELECT 'G1a factura cancelada rechazada', (res LIKE 'factura_cancelada%'), res FROM (SELECT pg_temp.rec(:'A','f1000000-0000-0000-0000-000000000004'::uuid,'[{"partida_id":"d1000000-0000-0000-0000-000000000006","producto_id":"prod-g-text-1"}]'::jsonb) res) t;
INSERT INTO rg SELECT 'G1b factura ajena rechazada', (res LIKE 'factura_no_encontrada%'), res FROM (SELECT pg_temp.rec(:'A','f1000000-0000-0000-0000-000000000009'::uuid,'[{"partida_id":"d1000000-0000-0000-0000-000000000009","producto_id":"prod-g-text-1"}]'::jsonb) res) t;
INSERT INTO rg SELECT 'G1c producto ajeno rechazado', (res LIKE 'producto_no_encontrado%'), res FROM (SELECT pg_temp.rec(:'A','f1000000-0000-0000-0000-000000000001'::uuid,'[{"partida_id":"d1000000-0000-0000-0000-000000000001","producto_id":"prod-g-orgb-1"}]'::jsonb) res) t;
INSERT INTO rg SELECT 'G1d producto servicio rechazado', (res LIKE 'producto_no_es_bien%'), res FROM (SELECT pg_temp.rec(:'A','f1000000-0000-0000-0000-000000000001'::uuid,'[{"partida_id":"d1000000-0000-0000-0000-000000000001","producto_id":"prod-g-serv-1"}]'::jsonb) res) t;

-- G2: KGM sin factor rechazado + todo-o-nada (la linea 1 valida se revierte si la 2 es KGM sin factor)
INSERT INTO rg SELECT 'G2 KGM sin factor rechaza y hace rollback todo-o-nada',
  (res LIKE 'factor_requerido%' AND (SELECT stock_actual FROM productos WHERE id='prod-g-text-1') = 5), res
FROM (SELECT pg_temp.rec(:'A','f1000000-0000-0000-0000-000000000001'::uuid,
  '[{"partida_id":"d1000000-0000-0000-0000-000000000001","producto_id":"prod-g-text-1"},{"partida_id":"d1000000-0000-0000-0000-000000000003","producto_id":"prod-g-text-2"}]'::jsonb) res) t;

-- G3: Recepcion exitosa con 2 partidas del MISMO producto (12.5 + 2.5 = +15 -> stock 20) + KGM con factor 0.1 (=10 LT, costo 200)
SELECT pg_temp.rec(:'A','f1000000-0000-0000-0000-000000000001'::uuid,
  '[{"partida_id":"d1000000-0000-0000-0000-000000000001","producto_id":"prod-g-text-1"},{"partida_id":"d1000000-0000-0000-0000-000000000002","producto_id":"prod-g-text-1"},{"partida_id":"d1000000-0000-0000-0000-000000000003","producto_id":"prod-g-text-2","factor_conversion":0.1,"factor_confirmado":true}]'::jsonb) AS rec1 \gset
INSERT INTO rg SELECT 'G3a suma fraccionaria de 2 partidas del mismo producto y no toca productos.costo',
  (:'rec1' LIKE 'OK:%' AND stock_actual = 20 AND costo = 10 AND ultimo_costo_compra = 12),
  :'rec1' || ' stock=' || stock_actual || ' costo=' || costo || ' ult=' || ultimo_costo_compra
FROM productos WHERE id='prod-g-text-1';
INSERT INTO rg SELECT 'G3b KGM con factor 0.1 recibe 10 LT a costo 200',
  (stock_actual = 10 AND ultimo_costo_compra = 200),
  'stock=' || stock_actual || ' ult=' || ultimo_costo_compra
FROM productos WHERE id='prod-g-text-2';

-- G4: Re-recepcion bloqueada
INSERT INTO rg SELECT 'G4 partida ya recibida bloqueada', (res LIKE 'partida_ya_recibida%'), res
FROM (SELECT pg_temp.rec(:'A','f1000000-0000-0000-0000-000000000001'::uuid,'[{"partida_id":"d1000000-0000-0000-0000-000000000001","producto_id":"prod-g-text-1"}]'::jsonb) res) t;

-- G5: USD (100 USD / 2 * TC 20 = 1000 MXN) + recepcion parcial (1.5 en vez de 2)
SELECT pg_temp.rec(:'A','f1000000-0000-0000-0000-000000000002'::uuid,'[{"partida_id":"d1000000-0000-0000-0000-000000000004","producto_id":"prod-g-text-1","cantidad_recibida":1.5}]'::jsonb) AS rec_usd \gset
INSERT INTO rg SELECT 'G5 USD convierte a 1000 y recepcion parcial suma 1.5 (20 -> 21.5)',
  (:'rec_usd' LIKE 'OK:%' AND stock_actual = 21.5 AND ultimo_costo_compra = 1000),
  :'rec_usd' || ' stock=' || stock_actual || ' ult=' || ultimo_costo_compra
FROM productos WHERE id='prod-g-text-1';

-- G6: Factura mas vieja NO pisa ultimo_costo_compra (sigue en 1000 de 2026-11-22)
SELECT pg_temp.rec(:'A','f1000000-0000-0000-0000-000000000003'::uuid,'[{"partida_id":"d1000000-0000-0000-0000-000000000005","producto_id":"prod-g-text-1"}]'::jsonb) AS rec_old \gset
INSERT INTO rg SELECT 'G6 factura vieja suma stock pero NO pisa ultimo_costo_compra',
  (:'rec_old' LIKE 'OK:%' AND stock_actual = 31.5 AND ultimo_costo_compra = 1000),
  :'rec_old' || ' stock=' || stock_actual || ' ult=' || ultimo_costo_compra
FROM productos WHERE id='prod-g-text-1';

-- G7: Doble conteo (b): compra Recibida mismo proveedor en ultimos 60 dias con producto compartido
INSERT INTO compras_proveedor (id, organizacion_id, proveedor_id, folio, estado, fecha)
VALUES ('cc000000-0000-0000-0000-000000000001', :'A', 'a2000000-0000-0000-0000-000000000001', 'OC-DUP-60D', 'Recibida', '2026-11-15'::timestamptz);
INSERT INTO compra_items (compra_id, material_id, cantidad, costo_unitario)
VALUES ('cc000000-0000-0000-0000-000000000001', 'prod-g-text-1', 5, 10);

INSERT INTO facturas_proveedor (id, organizacion_id, proveedor_id, folio, fecha_emision, fecha_vencimiento, moneda, importe, estado)
VALUES ('f1000000-0000-0000-0000-000000000005', :'A', 'a2000000-0000-0000-0000-000000000001', 'FG-DUP', '2026-11-21', '2026-12-21', 'MXN', 100, 'abierta');
INSERT INTO factura_proveedor_partidas (id, organizacion_id, factura_id, tipo, descripcion, cantidad, precio_unitario, importe, clave_unidad, orden)
VALUES ('d1000000-0000-0000-0000-000000000007', :'A', 'f1000000-0000-0000-0000-000000000005', 'concepto', 'TORNILLO DUP', 1, 10, 10, 'H87', 1);

INSERT INTO rg SELECT 'G7a doble conteo (b) por compra Recibida 60d bloquea sin confirmo_doble',
  (res LIKE 'compra_ya_recibida%OC-DUP-60D%'), res
FROM (SELECT pg_temp.rec(:'A','f1000000-0000-0000-0000-000000000005'::uuid,'[{"partida_id":"d1000000-0000-0000-0000-000000000007","producto_id":"prod-g-text-1"}]'::jsonb, false) res) t;
INSERT INTO rg SELECT 'G7b doble conteo pasa con p_confirmo_doble=true',
  (res LIKE 'OK:%'), res
FROM (SELECT pg_temp.rec(:'A','f1000000-0000-0000-0000-000000000005'::uuid,'[{"partida_id":"d1000000-0000-0000-0000-000000000007","producto_id":"prod-g-text-1"}]'::jsonb, true) res) t;

-- G8: Anulacion (sin motivo, stock insuficiente, exitosa libera partida, doble anulacion, aislamiento org)
SELECT substring(:'rec1' FROM 4)::uuid AS rec1_id \gset
INSERT INTO rg SELECT 'G8a anular sin motivo rechazado', (res LIKE 'motivo_requerido%'), res FROM (SELECT pg_temp.anu(:'A', :'rec1_id'::uuid, '   ') res) t;
INSERT INTO rg SELECT 'G8b anular recepcion ajena rechazado', (res LIKE 'recepcion_no_encontrada%'), res FROM (SELECT pg_temp.anu(:'B', :'rec1_id'::uuid, 'motivo') res) t;

-- Bajar stock de prod-g-text-2 a 2 para probar stock_insuficiente al intentar anular 10
UPDATE productos SET stock_actual = 2 WHERE id = 'prod-g-text-2';
INSERT INTO rg SELECT 'G8c anular con stock insuficiente bloqueado', (res LIKE 'stock_insuficiente%'), res FROM (SELECT pg_temp.anu(:'A', :'rec1_id'::uuid, 'error captura') res) t;
UPDATE productos SET stock_actual = 10 WHERE id = 'prod-g-text-2';

SELECT pg_temp.anu(:'A', :'rec1_id'::uuid, 'error captura') AS anu_ok \gset
INSERT INTO rg SELECT 'G8d anular con stock suficiente revierte stock y libera partida',
  (:'anu_ok' = 'OK' AND (SELECT stock_actual FROM productos WHERE id='prod-g-text-2') = 0
   AND NOT EXISTS (SELECT 1 FROM almacen_recepcion_lineas WHERE partida_id='d1000000-0000-0000-0000-000000000001' AND activa = true)),
  :'anu_ok' || ' stock2=' || (SELECT stock_actual FROM productos WHERE id='prod-g-text-2');

INSERT INTO rg SELECT 'G8e segunda anulacion bloqueada', (res LIKE 'recepcion_ya_anulada%'), res FROM (SELECT pg_temp.anu(:'A', :'rec1_id'::uuid, 'otra vez') res) t;

-- G8f: No regresion trigger procesar_inventario_por_cotizacion (Aprobada -> Cancelada y Aprobada -> Pagada con NUMERIC(14,4))
DO $$
DECLARE
  v_org uuid := '00000000-0000-0000-0000-000000000001';
  v_cli text;
  v_cot text := 'cot-g-trig-test';
  v_sr_aprob numeric;
  v_sr_canc numeric;
BEGIN
  SELECT id INTO v_cli FROM clientes WHERE organizacion_id = v_org LIMIT 1;
  IF v_cli IS NOT NULL THEN
    INSERT INTO cotizaciones (id, organizacion_id, cliente_id, folio, fecha, estado, subtotal, iva, total)
    VALUES (v_cot, v_org, v_cli, 'COT-G-TRIG', CURRENT_DATE, 'Borrador', 100, 16, 116)
    ON CONFLICT (id) DO UPDATE SET estado = 'Borrador';
    DELETE FROM items_cotizacion WHERE cotizacion_id = v_cot;
    INSERT INTO items_cotizacion (id, organizacion_id, cotizacion_id, producto_id, posicion, cantidad, unidad, descripcion, precio_unitario, total_item)
    VALUES ('item-g-trig-1', v_org, v_cot, 'prod-g-text-1', 1, 3, 'PZA', 'Tornillo prueba', 15, 45);
    UPDATE cotizaciones SET estado = 'Aprobada' WHERE id = v_cot;
    SELECT stock_reservado INTO v_sr_aprob FROM productos WHERE id = 'prod-g-text-1';
    UPDATE cotizaciones SET estado = 'Cancelada' WHERE id = v_cot;
    SELECT stock_reservado INTO v_sr_canc FROM productos WHERE id = 'prod-g-text-1';
    INSERT INTO rg VALUES ('G8f trigger procesar_inventario_por_cotizacion (Aprobada->Cancelada)',
      (v_sr_aprob = 3 AND v_sr_canc = 0),
      'aprob=' || v_sr_aprob || ' canc=' || v_sr_canc);
  END IF;
END $$;

-- G9: Permisos RPC
INSERT INTO rg SELECT 'G9a authenticated no puede ejecutar recibir_factura_almacen',
  NOT has_function_privilege('authenticated','recibir_factura_almacen(uuid,uuid,uuid,jsonb,boolean,text)','EXECUTE'), '';
INSERT INTO rg SELECT 'G9b anon no puede ejecutar anular_recepcion_almacen',
  NOT has_function_privilege('anon','anular_recepcion_almacen(uuid,uuid,uuid,text)','EXECUTE'), '';

-- G10 (D1): FK ON DELETE RESTRICT con guardar_factura_con_partidas real + editar tras anular
DO $$
DECLARE
  v_org uuid := '00000000-0000-0000-0000-000000000001';
  v_prov uuid := '11111111-1111-4111-8111-111111111111';
  v_usr uuid := NULL;
  v_fid uuid;
  v_pid uuid;
  v_rec jsonb;
  v_rid uuid;
  v_err_23503 boolean := false;
  v_lineas_intactas int;
  v_stock_post numeric;
  v_edit_ok boolean := false;
BEGIN
  INSERT INTO proveedores (id, organizacion_id, nombre, rfc, razon_social, moneda_default)
  VALUES (v_prov, v_org, 'Prov D1 Test', 'PDT010101AAA', 'Prov D1 Test SA', 'MXN')
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO productos (id, organizacion_id, nombre, descripcion, unidad, tipo, precio_unitario, costo, stock_actual, stock_reservado, stock_minimo)
  VALUES ('prod-g-d1', v_org, 'Prod D1', 'd', 'pz', 'bien', 10, 5, 0, 0, 0)
  ON CONFLICT (id) DO UPDATE SET stock_actual = 0;

  PERFORM public.guardar_factura_con_partidas(
    v_org, NULL, v_prov, 'FG-D1-REAL', NULL, '2026-11-20', 30, '2026-12-20', 'MXN', 100, 1, 'd1', NULL, 100, 0, 0, 0,
    '[{"tipo":"concepto","descripcion":"Tornillo D1","cantidad":10,"clave_unidad":"H87","precio_unitario":10,"importe":100}]'::jsonb, NULL
  );
  SELECT id INTO v_fid FROM facturas_proveedor WHERE organizacion_id = v_org AND folio = 'FG-D1-REAL';
  SELECT id INTO v_pid FROM factura_proveedor_partidas WHERE factura_id = v_fid;

  v_rec := public.recibir_factura_almacen(
    v_org, v_usr, v_fid,
    jsonb_build_array(jsonb_build_object('partida_id', v_pid, 'producto_id', 'prod-g-d1', 'guardar_alias', false)),
    false, NULL
  );
  v_rid := (v_rec->>'recepcion_id')::uuid;

  -- Intentar reemplazar partidas con guardar_factura_con_partidas mientras la recepcion esta activa -> debe fallar 23503
  BEGIN
    PERFORM public.guardar_factura_con_partidas(
      v_org, v_fid, v_prov, 'FG-D1-REAL', NULL, '2026-11-20', 30, '2026-12-20', 'MXN', 110, 1, 'd1', NULL, 110, 0, 0, 0,
      '[{"tipo":"concepto","descripcion":"Tornillo D1","cantidad":11,"clave_unidad":"H87","precio_unitario":10,"importe":110}]'::jsonb, NULL
    );
  EXCEPTION WHEN foreign_key_violation THEN
    v_err_23503 := true;
  END;

  SELECT count(*) INTO v_lineas_intactas FROM almacen_recepcion_lineas WHERE recepcion_id = v_rid AND activa = true;
  SELECT stock_actual INTO v_stock_post FROM productos WHERE id = 'prod-g-d1';
  INSERT INTO rg VALUES ('G10a guardar_factura_con_partidas bloqueado por FK RESTRICT con recepcion activa',
    (v_err_23503 AND v_lineas_intactas = 1 AND v_stock_post = 10),
    'fk_err=' || v_err_23503 || ' lineas=' || v_lineas_intactas || ' stock=' || v_stock_post);

  -- Actualizar solo descripcion en sitio no rompe la recepcion
  UPDATE factura_proveedor_partidas SET descripcion = 'Tornillo D1 corregido' WHERE id = v_pid;
  SELECT count(*) INTO v_lineas_intactas FROM almacen_recepcion_lineas WHERE recepcion_id = v_rid AND activa = true;
  INSERT INTO rg VALUES ('G10b actualizar descripcion en sitio conserva recepcion activa',
    (v_lineas_intactas = 1), 'lineas=' || v_lineas_intactas);

  -- Tras anular la recepcion, guardar_factura_con_partidas SI permite editar partidas y partida_id_original conserva trazabilidad
  PERFORM public.anular_recepcion_almacen(v_org, v_usr, v_rid, 'corregir cantidad factura');
  PERFORM public.guardar_factura_con_partidas(
    v_org, v_fid, v_prov, 'FG-D1-REAL', NULL, '2026-11-20', 30, '2026-12-20', 'MXN', 110, 1, 'd1', NULL, 110, 0, 0, 0,
    '[{"tipo":"concepto","descripcion":"Tornillo D1","cantidad":11,"clave_unidad":"H87","precio_unitario":10,"importe":110}]'::jsonb, NULL
  );
  v_edit_ok := (SELECT cantidad FROM factura_proveedor_partidas WHERE factura_id = v_fid) = 11
    AND (SELECT partida_id_original FROM almacen_recepcion_lineas WHERE recepcion_id = v_rid) = v_pid;
  INSERT INTO rg VALUES ('G10c tras anular recepcion se pueden editar partidas conservando partida_id_original',
    v_edit_ok, 'edit_ok=' || v_edit_ok);
END $$;

SELECT caso, CASE WHEN ok THEN 'PASA' ELSE 'FALLA' END estado, detalle FROM rg ORDER BY caso;
ROLLBACK;
