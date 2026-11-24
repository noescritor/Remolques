-- Verificación integral de Bloque F (Acero: XML -> precios, alias, renombrar proveedor)
-- Todo dentro de BEGIN ... ROLLBACK.
\set ON_ERROR_STOP on
BEGIN;

-- 1. Contrato de columnas usadas por motor/acero_cfdi.ts y motor/acero.ts
SELECT id, organizacion_id, proveedor_id, clave_sat, descripcion_normalizada, destino_tipo, destino_id, proveedor_acero, factor_conversion, veces_confirmado, ultima_confirmacion, confirmado_por FROM catalogo_alias_factura LIMIT 0;
SELECT id, organizacion_id, partida_id, material_id, proveedor, precio_aplicado, factura_id, fecha_emision_factura, aplicado_el, usuario_id FROM acero_precios_cfdi_aplicados LIMIT 0;
SELECT id, organizacion_id, material_id, proveedor, precio_anterior, precio_nuevo, usuario_id, creado_el, fuente, factura_id, incluye_iva FROM acero_precios_historial LIMIT 0;

DO $$
DECLARE
  v_org_a uuid := '00000000-0000-0000-0000-000000000001';
  v_org_b uuid := gen_random_uuid();
  v_user_a uuid := gen_random_uuid();
  v_prov_a uuid := gen_random_uuid();
  v_prov_b uuid := gen_random_uuid();
  v_mat_a uuid;
  v_mat_b uuid := gen_random_uuid();
  v_fac_1 uuid := gen_random_uuid();
  v_fac_old uuid := gen_random_uuid();
  v_part_1 uuid := gen_random_uuid();
  v_part_2 uuid := gen_random_uuid();
  v_part_old uuid := gen_random_uuid();
  v_res jsonb;
  v_cnt integer;
  v_precio numeric;
  v_iva boolean;
BEGIN
  INSERT INTO organizaciones (id, nombre) VALUES (v_org_b, 'Org F B') ON CONFLICT DO NOTHING;
  INSERT INTO proveedores (id, organizacion_id, nombre, rfc) VALUES
    (v_prov_a, v_org_a, 'SERVIACERO TEST', 'SER010101AAA'),
    (v_prov_b, v_org_b, 'OTRO PROV B', 'OTR010101BBB');

  SELECT id INTO v_mat_a FROM acero_materiales WHERE organizacion_id = v_org_a LIMIT 1;
  INSERT INTO acero_materiales (id, organizacion_id, nombre, tipo) VALUES
    (v_mat_b, v_org_b, 'Material Org B', 'placa');

  -- Factura 1 (MXN, fecha hoy) y Factura vieja (fecha hoy - 30)
  INSERT INTO facturas_proveedor (id, organizacion_id, proveedor_id, folio, fecha_emision, fecha_vencimiento, moneda, importe, tipo_cambio_emision, estado, uuid_fiscal) VALUES
    (v_fac_1, v_org_a, v_prov_a, 'F-ACERO-1', CURRENT_DATE, CURRENT_DATE + 30, 'MXN', 10000, 1, 'abierta', 'UUID-ACERO-F1'),
    (v_fac_old, v_org_a, v_prov_a, 'F-ACERO-OLD', CURRENT_DATE - 30, CURRENT_DATE, 'MXN', 10000, 1, 'abierta', 'UUID-ACERO-OLD');

  INSERT INTO factura_proveedor_partidas (id, organizacion_id, factura_id, tipo, descripcion, cantidad, precio_unitario, importe, clave_sat, clave_unidad, orden) VALUES
    (v_part_1, v_org_a, v_fac_1, 'concepto', 'CANAL U 6 DE 12.20M', 2, 4800, 9600, '30101804', 'H87', 1),
    (v_part_2, v_org_a, v_fac_1, 'concepto', 'FLETE', 1, 400, 400, '78101800', 'E48', 2),
    (v_part_old, v_org_a, v_fac_old, 'concepto', 'CANAL U 6 DE 12.20M', 2, 4700, 9400, '30101804', 'H87', 1);

  -- 1. Todo-o-nada: si la segunda línea tiene material ajeno (Org B), no aplica la primera
  BEGIN
    PERFORM aplicar_precios_acero_cfdi(
      v_org_a, v_user_a, v_fac_1,
      jsonb_build_array(
        jsonb_build_object('partida_id', v_part_1, 'material_id', v_mat_a, 'proveedor_acero', 'PROV_F_TEST', 'factor_conversion', 1, 'guardar_alias', true),
        jsonb_build_object('partida_id', v_part_2, 'material_id', v_mat_b, 'proveedor_acero', 'PROV_F_TEST', 'factor_conversion', 1, 'guardar_alias', true)
      )
    );
    RAISE EXCEPTION 'Debio fallar material_no_encontrado';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM NOT LIKE '%material_no_encontrado%' THEN RAISE; END IF;
  END;

  SELECT COUNT(*) INTO v_cnt FROM acero_precios_cfdi_aplicados WHERE partida_id = v_part_1;
  IF v_cnt <> 0 THEN RAISE EXCEPTION 'Rollback todo-o-nada fallo'; END IF;

  -- 2. Material duplicado en el mismo lote falla
  BEGIN
    PERFORM aplicar_precios_acero_cfdi(
      v_org_a, v_user_a, v_fac_1,
      jsonb_build_array(
        jsonb_build_object('partida_id', v_part_1, 'material_id', v_mat_a, 'proveedor_acero', 'PROV_F_TEST', 'factor_conversion', 1),
        jsonb_build_object('partida_id', v_part_2, 'material_id', v_mat_a, 'proveedor_acero', 'PROV_F_TEST', 'factor_conversion', 1)
      )
    );
    RAISE EXCEPTION 'Debio fallar material_duplicado_en_lote';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM NOT LIKE '%material_duplicado_en_lote%' THEN RAISE; END IF;
  END;

  -- 3. Aplicar partida 1 correctamente -> guarda precio sin IVA, historial con fuente/factura_id y alias
  v_res := aplicar_precios_acero_cfdi(
    v_org_a, v_user_a, v_fac_1,
    jsonb_build_array(
      jsonb_build_object('partida_id', v_part_1, 'material_id', v_mat_a, 'proveedor_acero', 'PROV_F_TEST', 'factor_conversion', 1, 'guardar_alias', true, 'descripcion_normalizada', 'canal u 6 de 12 20m')
    )
  );
  IF (v_res->>'total')::int <> 1 THEN RAISE EXCEPTION 'Esperaba total=1'; END IF;

  SELECT precio, incluye_iva INTO v_precio, v_iva
  FROM acero_precios WHERE organizacion_id = v_org_a AND material_id = v_mat_a AND proveedor = 'PROV_F_TEST';
  IF v_precio <> 4800.0000 OR v_iva <> false THEN
    RAISE EXCEPTION 'Precio o incluye_iva incorrectos: % / %', v_precio, v_iva;
  END IF;

  -- 4. Reaplicar misma partida falla con partida_ya_aplicada
  BEGIN
    PERFORM aplicar_precios_acero_cfdi(
      v_org_a, v_user_a, v_fac_1,
      jsonb_build_array(jsonb_build_object('partida_id', v_part_1, 'material_id', v_mat_a, 'proveedor_acero', 'PROV_F_TEST', 'factor_conversion', 1))
    );
    RAISE EXCEPTION 'Debio fallar partida_ya_aplicada';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM NOT LIKE '%partida_ya_aplicada%' THEN RAISE; END IF;
  END;

  -- 5. Factura más vieja bloqueada sin forzar_fecha_anterior
  BEGIN
    PERFORM aplicar_precios_acero_cfdi(
      v_org_a, v_user_a, v_fac_old,
      jsonb_build_array(jsonb_build_object('partida_id', v_part_old, 'material_id', v_mat_a, 'proveedor_acero', 'PROV_F_TEST', 'factor_conversion', 1))
    );
    RAISE EXCEPTION 'Debio fallar fecha_anterior_a_ultimo_cfdi';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM NOT LIKE '%fecha_anterior_a_ultimo_cfdi%' THEN RAISE; END IF;
  END;

  -- 6. Variación > 30% bloqueada sin forzar_variacion (factor 2 => 9400 vs 4800 = +95%)
  BEGIN
    PERFORM aplicar_precios_acero_cfdi(
      v_org_a, v_user_a, v_fac_old,
      jsonb_build_array(jsonb_build_object('partida_id', v_part_old, 'material_id', v_mat_a, 'proveedor_acero', 'PROV_F_TEST', 'factor_conversion', 2, 'forzar_fecha_anterior', true))
    );
    RAISE EXCEPTION 'Debio fallar variacion_precio_alta';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM NOT LIKE '%variacion_precio_alta%' THEN RAISE; END IF;
  END;

  -- 7. Renombrar proveedor con conflicto (SERVIACERO ya existe en v_mat_a) -> falla sin cambiar nada
  BEGIN
    PERFORM renombrar_proveedor_acero(v_org_a, 'PROV_F_TEST', 'SERVIACERO');
    RAISE EXCEPTION 'Debio fallar proveedor_conflicto';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM NOT LIKE '%proveedor_conflicto%' THEN RAISE; END IF;
  END;

  -- 8. Renombrar proveedor sin conflicto -> actualiza acero_precios y catalogo_alias_factura
  v_res := renombrar_proveedor_acero(v_org_a, 'PROV_F_TEST', 'PROV_F_RENOMBRADO');
  IF (v_res->>'precios_actualizados')::int <> 1 OR (v_res->>'alias_actualizados')::int <> 1 THEN
    RAISE EXCEPTION 'Renombrar no actualizo precios y alias: %', v_res;
  END IF;

  -- 9. Aislamiento RLS con rol authenticated de Org B
  PERFORM set_config('request.jwt.claims', json_build_object('sub', v_user_a, 'organizacion_id', v_org_b, 'role', 'authenticated')::text, true);
  EXECUTE 'SET LOCAL ROLE authenticated';
  SELECT COUNT(*) INTO v_cnt FROM catalogo_alias_factura WHERE proveedor_acero = 'PROV_F_RENOMBRADO';
  IF v_cnt <> 0 THEN RAISE EXCEPTION 'Fallo RLS catalogo_alias_factura'; END IF;
  SELECT COUNT(*) INTO v_cnt FROM acero_precios_cfdi_aplicados WHERE factura_id = v_fac_1;
  IF v_cnt <> 0 THEN RAISE EXCEPTION 'Fallo RLS acero_precios_cfdi_aplicados'; END IF;
  EXECUTE 'RESET ROLE';

  RAISE NOTICE 'VERIFICACION_F_OK';
END $$;

ROLLBACK;
