-- Semilla local para pruebas E2E de navegador del Bloque F (acero XML -> precios).
-- Uso: psql -h 127.0.0.1 -p 54331 -U tester -d test_acero_f -v ON_ERROR_STOP=1 -f scripts/dev/seed_acero_f.sql

DO $$
DECLARE
  v_org uuid;
  v_prov uuid;
  v_mat1 uuid;
  v_mat2 uuid;
  v_f1 uuid := 'f1111111-1111-4111-8111-111111111111';
  v_f2 uuid := 'f2222222-2222-4222-8222-222222222222';
  v_f3 uuid := 'f3333333-3333-4333-8333-333333333333';
BEGIN
  SELECT id INTO v_org FROM organizaciones LIMIT 1;
  SELECT id INTO v_prov FROM proveedores WHERE organizacion_id = v_org LIMIT 1;
  IF v_prov IS NULL THEN
    INSERT INTO proveedores (organizacion_id, nombre, rfc, dias_credito)
    VALUES (v_org, 'SERVIACERO COMMERCIAL', 'SCO900101AAA', 30)
    RETURNING id INTO v_prov;
  END IF;

  -- O8: Asegurar que el alias "Recordado" de placa apunte a una PLACA real (no a un PTR)
  SELECT id INTO v_mat1
  FROM acero_materiales
  WHERE organizacion_id = v_org AND tipo = 'placa' AND nombre ILIKE '%3/16%'
  ORDER BY nombre ASC
  LIMIT 1;

  IF v_mat1 IS NULL THEN
    SELECT id INTO v_mat1
    FROM acero_materiales
    WHERE organizacion_id = v_org AND tipo = 'placa'
    ORDER BY nombre ASC
    LIMIT 1;
  END IF;

  SELECT id INTO v_mat2
  FROM acero_materiales
  WHERE organizacion_id = v_org AND id <> v_mat1 AND tipo = 'canal'
  ORDER BY nombre ASC
  LIMIT 1;

  DELETE FROM catalogo_alias_factura
  WHERE organizacion_id = v_org
    AND proveedor_id = v_prov
    AND descripcion_normalizada = 'placa a36 3/16 5x10 especial';

  INSERT INTO catalogo_alias_factura (
    organizacion_id, proveedor_id, clave_sat, descripcion_normalizada,
    destino_tipo, destino_id, proveedor_acero, factor_conversion, veces_confirmado
  ) VALUES (
    v_org, v_prov, NULL, 'placa a36 3/16 5x10 especial',
    'acero_material', v_mat1, 'SERVIACERO', 1, 3
  );

  DELETE FROM acero_precios_cfdi_aplicados WHERE factura_id IN (v_f1, v_f2, v_f3);
  DELETE FROM factura_proveedor_partidas WHERE factura_id IN (v_f1, v_f2, v_f3);
  DELETE FROM facturas_proveedor_cfdi WHERE factura_id IN (v_f1, v_f2, v_f3);
  DELETE FROM facturas_proveedor WHERE id IN (v_f1, v_f2, v_f3);

  -- Factura 1 (abierta, MXN, con descuento, 3 conceptos: recordado H87, sugerido KGM, flete E48)
  INSERT INTO facturas_proveedor (id, organizacion_id, proveedor_id, folio, fecha_emision, fecha_vencimiento, moneda, importe, subtotal, descuento, estado, uuid_fiscal)
  VALUES (v_f1, v_org, v_prov, 'FAC-ACERO-101', '2026-11-22', '2026-12-22', 'MXN', 15000, 13000, 200, 'abierta', '11111111-1111-4111-8111-000000000101');

  INSERT INTO factura_proveedor_partidas (organizacion_id, factura_id, orden, tipo, descripcion, cantidad, precio_unitario, importe, clave_unidad) VALUES
    (v_org, v_f1, 1, 'concepto', 'PLACA A36 3/16 5X10 ESPECIAL', 2, 1650, 3300, 'H87'),
    (v_org, v_f1, 2, 'concepto', (SELECT nombre FROM acero_materiales WHERE id = v_mat2), 100, 24.5, 2450, 'KGM'),
    (v_org, v_f1, 3, 'concepto', 'FLETE TERRESTRE SERVICIO EXPRESS', 1, 850, 850, 'E48'),
    (v_org, v_f1, 4, 'descuento', 'Descuento comercial', 1, 200, 200, NULL);

  -- Factura 2 (más vieja + USD TC 20 + variación > 30%)
  INSERT INTO facturas_proveedor (id, organizacion_id, proveedor_id, folio, fecha_emision, fecha_vencimiento, moneda, tipo_cambio_emision, importe, subtotal, estado, uuid_fiscal)
  VALUES (v_f2, v_org, v_prov, 'FAC-ACERO-VIEJA', '2026-10-10', '2026-11-10', 'USD', 20, 400, 350, 'abierta', '22222222-2222-4222-8222-000000000202');

  INSERT INTO factura_proveedor_partidas (organizacion_id, factura_id, orden, tipo, descripcion, cantidad, precio_unitario, importe, clave_unidad) VALUES
    (v_org, v_f2, 1, 'concepto', 'PLACA A36 3/16 5X10 ESPECIAL', 1, 160, 160, 'H87');

  -- Factura 3 (cancelada: no debe mostrar botón Acero)
  INSERT INTO facturas_proveedor (id, organizacion_id, proveedor_id, folio, fecha_emision, fecha_vencimiento, moneda, importe, subtotal, estado)
  VALUES (v_f3, v_org, v_prov, 'FAC-CANCELADA-99', '2026-11-20', '2026-12-20', 'MXN', 1000, 862.07, 'cancelada');

  RAISE NOTICE 'SEED_OK org=% mat1=% mat2=%', v_org, v_mat1, v_mat2;
END $$;
