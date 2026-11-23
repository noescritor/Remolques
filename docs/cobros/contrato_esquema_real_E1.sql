-- Prueba de contrato contra el esquema real (sin simulador) para Bloque E1
-- Ejecuta todas las consultas de columnas, órdenes y RPCs que usa motor/cobros.ts
-- contra la base migrada, dentro de una transacción con ROLLBACK al final.
\set ON_ERROR_STOP on
BEGIN;

-- 1. Contrato de columnas usadas por motor/cobros.ts
SELECT id, folio, estado, total, cliente_id FROM cotizaciones LIMIT 0;
SELECT id, nombre_razon_social FROM clientes LIMIT 0;
SELECT id, nomenclatura_id, modelo, tipo_equipo, cotizacion_id FROM ordenes_trabajo LIMIT 0;
SELECT orden_trabajo_id, organizacion_id, valor_pactado, notas, updated_at FROM equipo_valor_cobranza LIMIT 0;
SELECT id, pago_id, orden_trabajo_id, monto FROM pago_aplicaciones LIMIT 0;
SELECT id, organizacion_id, cotizacion_id, orden_trabajo_id, nombre, notas, activo, created_at, updated_at FROM planes_pago LIMIT 0;
SELECT id, organizacion_id, plan_id, numero, fecha_vencimiento, monto, nota FROM plan_pagos_parcialidades LIMIT 0;
SELECT * FROM pagos ORDER BY fecha DESC, created_at DESC, id DESC LIMIT 0;

-- 2. Flujo completo real en Postgres: equipo con cotización, orden manual, Cheque, guardar_plan_pago atómico
DO $$
DECLARE
  v_org uuid := '00000000-0000-0000-0000-000000000001';
  v_user uuid := gen_random_uuid();
  v_cli text := gen_random_uuid()::text;
  v_cot text := gen_random_uuid()::text;
  v_ord_cot uuid := gen_random_uuid();
  v_ord_man uuid := gen_random_uuid();
  v_plan_res jsonb;
  v_plan_id uuid;
  v_cobro_res jsonb;
  v_cnt integer;
BEGIN
  INSERT INTO clientes (id, organizacion_id, nombre_razon_social)
  VALUES (v_cli, v_org, 'Cliente Contrato E1');

  INSERT INTO cotizaciones (id, organizacion_id, folio, cliente_id, total, estado)
  VALUES (v_cot, v_org, 'COT-CONTRATO-1', v_cli, 100000.00, 'Aprobada');

  INSERT INTO ordenes_trabajo (id, organizacion_id, cotizacion_id, cliente_id, nomenclatura_id, modelo, tipo_equipo, estado, origen, etiqueta)
  VALUES
    (v_ord_cot, v_org, v_cot, v_cli, 'CTR-01', 'Plana', 'Plana', 'Pendiente', 'cotizacion', NULL),
    (v_ord_man, v_org, NULL, NULL, 'CTR-MAN', 'Dolly', 'Dolly', 'Pendiente', 'manual', 'Manual CTR');

  -- 2a. PUT valor con notas (D1)
  INSERT INTO equipo_valor_cobranza (organizacion_id, orden_trabajo_id, valor_pactado, notas)
  VALUES (v_org, v_ord_cot, 100000.00, 'Valor pactado con notas')
  ON CONFLICT (orden_trabajo_id) DO UPDATE SET valor_pactado = EXCLUDED.valor_pactado, notas = EXCLUDED.notas;

  -- 2b. Cobro con Cheque (D2)
  v_cobro_res := registrar_cobro(
    v_org, v_cot, 25000.00, CURRENT_DATE, 'Cheque', 'CHQ-101', 'Primer cheque', NULL,
    jsonb_build_array(jsonb_build_object('orden_trabajo_id', v_ord_cot, 'monto', 25000.00)),
    false, v_user
  );

  -- 2c. Errores de aplicaciones previas (D2): UUID inválido y orden duplicada
  BEGIN
    PERFORM registrar_cobro(v_org, v_cot, 1000, CURRENT_DATE, 'Cheque', NULL, NULL, NULL, '[{"orden_trabajo_id":"no-es-uuid","monto":500}]'::jsonb, false, v_user);
    RAISE EXCEPTION 'Debio fallar aplicacion_orden_invalida';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM NOT LIKE '%aplicacion_orden_invalida%' THEN RAISE; END IF;
  END;

  BEGIN
    PERFORM registrar_cobro(
      v_org, v_cot, 1000, CURRENT_DATE, 'Cheque', NULL, NULL, NULL,
      jsonb_build_array(
        jsonb_build_object('orden_trabajo_id', v_ord_cot, 'monto', 400),
        jsonb_build_object('orden_trabajo_id', v_ord_cot, 'monto', 400)
      ),
      false, v_user
    );
    RAISE EXCEPTION 'Debio fallar aplicacion_duplicada';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM NOT LIKE '%aplicacion_duplicada%' THEN RAISE; END IF;
  END;

  -- 2d. guardar_plan_pago atómico (D4) y fallo por fecha inválida 2026-02-31
  v_plan_res := guardar_plan_pago(
    v_org, v_cot, NULL, NULL, 'Plan V1', 'Notas V1',
    jsonb_build_array(
      jsonb_build_object('numero', 1, 'fecha_vencimiento', (CURRENT_DATE - 1)::text, 'monto', 25000),
      jsonb_build_object('numero', 2, 'fecha_vencimiento', (CURRENT_DATE + 10)::text, 'monto', 75000)
    )
  );
  v_plan_id := (v_plan_res->>'id')::uuid;

  BEGIN
    PERFORM guardar_plan_pago(
      v_org, v_cot, NULL, NULL, 'Plan Roto', NULL,
      '[{"numero":1,"fecha_vencimiento":"2026-02-31","monto":50000}]'::jsonb
    );
    RAISE EXCEPTION 'Debio fallar fecha_invalida';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM NOT LIKE '%fecha_invalida%' THEN RAISE; END IF;
  END;

  -- Verificar que Plan V1 sigue activo e intacto tras el fallo
  SELECT COUNT(*) INTO v_cnt FROM planes_pago WHERE id = v_plan_id AND activo = true;
  IF v_cnt <> 1 THEN RAISE EXCEPTION 'Plan V1 debio seguir activo tras fallo atomico'; END IF;
  SELECT COUNT(*) INTO v_cnt FROM plan_pagos_parcialidades WHERE plan_id = v_plan_id;
  IF v_cnt <> 2 THEN RAISE EXCEPTION 'Plan V1 debio conservar sus 2 parcialidades'; END IF;

  -- 2e. Diferencial con v_plan_parcialidades_estado
  SELECT COUNT(*) INTO v_cnt FROM v_plan_parcialidades_estado WHERE plan_id = v_plan_id AND numero = 1 AND estatus = 'pagada';
  IF v_cnt <> 1 THEN RAISE EXCEPTION 'Parcialidad 1 debio ser pagada en v_plan_parcialidades_estado'; END IF;
  SELECT COUNT(*) INTO v_cnt FROM v_plan_parcialidades_estado WHERE plan_id = v_plan_id AND numero = 2 AND estatus = 'pendiente';
  IF v_cnt <> 1 THEN RAISE EXCEPTION 'Parcialidad 2 debio ser pendiente en v_plan_parcialidades_estado'; END IF;

  RAISE NOTICE 'CONTRATO_ESQUEMA_REAL_E1_OK';
END $$;

ROLLBACK;
