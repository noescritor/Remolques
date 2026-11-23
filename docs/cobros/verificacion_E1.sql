-- Verificación integral de Bloque E1 (Cobros, plan de pagos y cobranza por equipo)
-- Se ejecuta dentro de una transacción que hace ROLLBACK al final para no dejar datos de prueba.
\set ON_ERROR_STOP on
BEGIN;

-- 1. Verificar tablas, vistas, funciones y columnas nuevas
DO $$
BEGIN
  IF to_regclass('public.pago_aplicaciones') IS NULL THEN RAISE EXCEPTION 'Falta tabla pago_aplicaciones'; END IF;
  IF to_regclass('public.equipo_valor_cobranza') IS NULL THEN RAISE EXCEPTION 'Falta tabla equipo_valor_cobranza'; END IF;
  IF to_regclass('public.planes_pago') IS NULL THEN RAISE EXCEPTION 'Falta tabla planes_pago'; END IF;
  IF to_regclass('public.plan_pagos_parcialidades') IS NULL THEN RAISE EXCEPTION 'Falta tabla plan_pagos_parcialidades'; END IF;
  IF to_regclass('public.v_cobranza_cotizacion') IS NULL THEN RAISE EXCEPTION 'Falta vista v_cobranza_cotizacion'; END IF;
  IF to_regclass('public.v_cobranza_equipo') IS NULL THEN RAISE EXCEPTION 'Falta vista v_cobranza_equipo'; END IF;
  IF to_regclass('public.v_plan_parcialidades_estado') IS NULL THEN RAISE EXCEPTION 'Falta vista v_plan_parcialidades_estado'; END IF;
END $$;

-- 2. Datos de prueba en dos organizaciones
DO $$
DECLARE
  v_org_a uuid := '00000000-0000-0000-0000-000000000001';
  v_org_b uuid := gen_random_uuid();
  v_user_a uuid := gen_random_uuid();
  v_cliente_a text := gen_random_uuid()::text;
  v_cliente_b text := gen_random_uuid()::text;
  v_cot_a text := gen_random_uuid()::text;
  v_cot_borrador text := gen_random_uuid()::text;
  v_cot_b text := gen_random_uuid()::text;
  v_orden_1 uuid := gen_random_uuid();
  v_orden_2 uuid := gen_random_uuid();
  v_plan_id uuid;
  v_pago1_id text;
  v_pago2_id text;
  v_res jsonb;
  v_estado text;
  v_saldo numeric;
  v_cnt integer;
BEGIN
  INSERT INTO organizaciones (id, nombre) VALUES (v_org_b, 'Org Prueba B E1') ON CONFLICT DO NOTHING;

  INSERT INTO clientes (id, organizacion_id, nombre_razon_social) VALUES
    (v_cliente_a, v_org_a, 'Cliente Prueba E1 A'),
    (v_cliente_b, v_org_b, 'Cliente Prueba E1 B');

  INSERT INTO cotizaciones (id, organizacion_id, folio, cliente_id, total, estado) VALUES
    (v_cot_a, v_org_a, 'COT-E1-TEST-01', v_cliente_a, 100000.00, 'Aprobada'),
    (v_cot_borrador, v_org_a, 'COT-E1-TEST-02', v_cliente_a, 50000.00, 'Borrador'),
    (v_cot_b, v_org_b, 'COT-E1-TEST-B1', v_cliente_b, 80000.00, 'Aprobada');

  INSERT INTO ordenes_trabajo (id, organizacion_id, cotizacion_id, cliente_id, nomenclatura_id, modelo, estado) VALUES
    (v_orden_1, v_org_a, v_cot_a, v_cliente_a, 'NOM-E1-1', 'Modelo A', 'Pendiente'),
    (v_orden_2, v_org_a, v_cot_a, v_cliente_a, 'NOM-E1-2', 'Modelo B', 'Pendiente');

  -- 2a. Cotización no cobrable debe fallar
  BEGIN
    PERFORM registrar_cobro(v_org_a, v_cot_borrador, 1000, CURRENT_DATE, 'Transferencia');
    RAISE EXCEPTION 'Debio fallar cotizacion_no_cobrable';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM NOT LIKE '%cotizacion_no_cobrable%' THEN RAISE; END IF;
  END;

  -- 2b. Especie sin descripción debe fallar
  BEGIN
    PERFORM registrar_cobro(v_org_a, v_cot_a, 1000, CURRENT_DATE, 'Especie', NULL, NULL, NULL, '[]'::jsonb, false, v_user_a);
    RAISE EXCEPTION 'Debio fallar especie_sin_descripcion';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM NOT LIKE '%especie_sin_descripcion%' THEN RAISE; END IF;
  END;

  -- 2c. Cobro 1: 40,000 repartido 25,000 a orden 1 y 15,000 a orden 2
  v_res := registrar_cobro(
    v_org_a, v_cot_a, 40000.00, CURRENT_DATE, 'Transferencia',
    'REF-01', 'Anticipo', NULL,
    jsonb_build_array(
      jsonb_build_object('orden_trabajo_id', v_orden_1, 'monto', 25000.00),
      jsonb_build_object('orden_trabajo_id', v_orden_2, 'monto', 15000.00)
    ),
    false, v_user_a
  );
  v_pago1_id := (v_res->'pago'->>'id');
  IF (v_res->>'saldo_pendiente')::numeric <> 60000.00 THEN
    RAISE EXCEPTION 'Saldo esperado 60000.00, obtenido %', v_res->>'saldo_pendiente';
  END IF;

  -- 2d. Excedente sin permitir_excedente debe fallar
  BEGIN
    PERFORM registrar_cobro(v_org_a, v_cot_a, 70000.00, CURRENT_DATE, 'Transferencia', NULL, NULL, NULL, '[]'::jsonb, false, v_user_a);
    RAISE EXCEPTION 'Debio fallar saldo_excedido';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM NOT LIKE '%saldo_excedido%' THEN RAISE; END IF;
  END;

  -- 2e. Cobro 2 en Especie por 60,000 -> cotización pasa a Pagada
  v_res := registrar_cobro(
    v_org_a, v_cot_a, 60000.00, CURRENT_DATE, 'Especie',
    NULL, 'Unidad a cuenta', 'Remolque usado serie X',
    '[]'::jsonb, false, v_user_a
  );
  v_pago2_id := (v_res->'pago'->>'id');
  SELECT estado INTO v_estado FROM cotizaciones WHERE id = v_cot_a;
  IF v_estado <> 'Pagada' THEN
    RAISE EXCEPTION 'Cotizacion debio pasar a Pagada, estado actual: %', v_estado;
  END IF;

  -- 2f. Plan de pagos y verificación FIFO en v_plan_parcialidades_estado
  INSERT INTO planes_pago (organizacion_id, cotizacion_id, nombre) VALUES (v_org_a, v_cot_a, 'Plan 3 parcialidades') RETURNING id INTO v_plan_id;
  INSERT INTO plan_pagos_parcialidades (organizacion_id, plan_id, numero, fecha_vencimiento, monto, nota) VALUES
    (v_org_a, v_plan_id, 1, CURRENT_DATE - 10, 30000.00, 'Anticipo'),
    (v_org_a, v_plan_id, 2, CURRENT_DATE - 2, 30000.00, 'Avance'),
    (v_org_a, v_plan_id, 3, CURRENT_DATE + 10, 40000.00, 'Entrega');

  -- Anular cobro 2 (60,000) -> quedan 40,000 vigentes; cotización vuelve a Aprobada
  v_res := anular_cobro(v_org_a, v_pago2_id, 'Cheque devuelto', v_user_a);
  SELECT estado INTO v_estado FROM cotizaciones WHERE id = v_cot_a;
  IF v_estado <> 'Aprobada' THEN
    RAISE EXCEPTION 'Cotizacion debio volver a Aprobada tras anulacion, estado actual: %', v_estado;
  END IF;

  -- Con 40,000 pagados: P1 (30,000) = pagada, P2 (30,000, vencida hace 2 días, cubiertos 10,000) = vencida, P3 (futuro) = pendiente
  SELECT COUNT(*) INTO v_cnt FROM v_plan_parcialidades_estado WHERE plan_id = v_plan_id AND numero = 1 AND estatus = 'pagada';
  IF v_cnt <> 1 THEN RAISE EXCEPTION 'Parcialidad 1 debio ser pagada'; END IF;
  SELECT COUNT(*) INTO v_cnt FROM v_plan_parcialidades_estado WHERE plan_id = v_plan_id AND numero = 2 AND estatus = 'vencida' AND monto_cubierto = 10000.00;
  IF v_cnt <> 1 THEN RAISE EXCEPTION 'Parcialidad 2 debio ser vencida con 10000 cubierto'; END IF;
  SELECT COUNT(*) INTO v_cnt FROM v_plan_parcialidades_estado WHERE plan_id = v_plan_id AND numero = 3 AND estatus = 'pendiente' AND monto_cubierto = 0;
  IF v_cnt <> 1 THEN RAISE EXCEPTION 'Parcialidad 3 debio ser pendiente'; END IF;

  -- 2g. Verificar vista_saldo_cliente excluye anulados (100,000 - 40,000 = 60,000)
  SELECT saldo_usado INTO v_saldo FROM vista_saldo_cliente WHERE cliente_id = v_cliente_a;
  IF v_saldo <> 60000.00 THEN
    RAISE EXCEPTION 'vista_saldo_cliente debio reportar 60000.00 tras anular 60000, reporto %', v_saldo;
  END IF;

  -- 2h. Verificar aislamiento RLS con org B
  PERFORM set_config('request.jwt.claims', json_build_object('sub', v_user_a, 'organizacion_id', v_org_b, 'role', 'authenticated')::text, true);
  EXECUTE 'SET LOCAL ROLE authenticated';
  SELECT COUNT(*) INTO v_cnt FROM planes_pago WHERE id = v_plan_id;
  IF v_cnt <> 0 THEN
    RAISE EXCEPTION 'Fallo aislamiento RLS: Org B vio plan de Org A';
  END IF;
  EXECUTE 'RESET ROLE';

  RAISE NOTICE 'VERIFICACION_E1_OK';
END $$;

ROLLBACK;
