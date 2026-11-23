-- Migración Bloque E1: Cobros, aplicaciones por equipo, planes de pago y pago en especie
-- Aditiva e idempotente; RLS por organización; funciones atómicas SECURITY DEFINER.

BEGIN;

-- 1. Extender tabla pagos existente (sin borrar ni alterar datos previos)
ALTER TABLE pagos ADD COLUMN IF NOT EXISTS estado TEXT NOT NULL DEFAULT 'vigente';
ALTER TABLE pagos ADD COLUMN IF NOT EXISTS anulado_at TIMESTAMPTZ;
ALTER TABLE pagos ADD COLUMN IF NOT EXISTS anulado_por UUID;
ALTER TABLE pagos ADD COLUMN IF NOT EXISTS motivo_anulacion TEXT;
ALTER TABLE pagos ADD COLUMN IF NOT EXISTS notas TEXT;
ALTER TABLE pagos ADD COLUMN IF NOT EXISTS descripcion_especie TEXT;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'pagos_estado_check' AND conrelid = 'pagos'::regclass
  ) THEN
    ALTER TABLE pagos
      ADD CONSTRAINT pagos_estado_check CHECK (estado IN ('vigente', 'anulado'));
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'pagos_monto_positivo_check' AND conrelid = 'pagos'::regclass
  ) THEN
    ALTER TABLE pagos
      ADD CONSTRAINT pagos_monto_positivo_check CHECK (monto > 0) NOT VALID;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_pagos_org_cotizacion_estado
  ON pagos(organizacion_id, cotizacion_id, estado);

-- 2. Tabla pago_aplicaciones: reparto de un cobro entre órdenes de trabajo (equipos)
CREATE TABLE IF NOT EXISTS pago_aplicaciones (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organizacion_id UUID NOT NULL REFERENCES organizaciones(id) ON DELETE CASCADE,
  pago_id TEXT NOT NULL REFERENCES pagos(id) ON DELETE CASCADE,
  orden_trabajo_id UUID NOT NULL REFERENCES ordenes_trabajo(id) ON DELETE CASCADE,
  monto NUMERIC(12, 2) NOT NULL CHECK (monto > 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (pago_id, orden_trabajo_id)
);

CREATE INDEX IF NOT EXISTS idx_pago_aplicaciones_org_orden
  ON pago_aplicaciones(organizacion_id, orden_trabajo_id);
CREATE INDEX IF NOT EXISTS idx_pago_aplicaciones_pago
  ON pago_aplicaciones(pago_id);

CREATE OR REPLACE FUNCTION trg_validar_pago_aplicacion_fn()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_pago RECORD;
  v_orden RECORD;
  v_suma_otras NUMERIC(12, 2);
BEGIN
  SELECT id, organizacion_id, cotizacion_id, monto, estado
  INTO v_pago
  FROM pagos
  WHERE id = NEW.pago_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'pago_no_encontrado: El pago % no existe', NEW.pago_id;
  END IF;

  IF v_pago.organizacion_id <> NEW.organizacion_id THEN
    RAISE EXCEPTION 'aplicacion_org_invalida: La aplicación no pertenece a la organización del pago';
  END IF;

  SELECT id, organizacion_id, cotizacion_id
  INTO v_orden
  FROM ordenes_trabajo
  WHERE id = NEW.orden_trabajo_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'aplicacion_orden_invalida: La orden % no existe', NEW.orden_trabajo_id;
  END IF;

  IF v_orden.organizacion_id <> NEW.organizacion_id OR v_orden.cotizacion_id IS DISTINCT FROM v_pago.cotizacion_id THEN
    RAISE EXCEPTION 'aplicacion_orden_invalida: La orden debe pertenecer a la misma cotización y organización del pago';
  END IF;

  SELECT COALESCE(SUM(monto), 0)
  INTO v_suma_otras
  FROM pago_aplicaciones
  WHERE pago_id = NEW.pago_id
    AND id IS DISTINCT FROM NEW.id;

  IF ROUND(v_suma_otras + NEW.monto, 2) > ROUND(v_pago.monto, 2) + 0.005 THEN
    RAISE EXCEPTION 'aplicaciones_exceden_monto: La suma de aplicaciones (%) excede el monto del pago (%)',
      ROUND(v_suma_otras + NEW.monto, 2), ROUND(v_pago.monto, 2);
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_validar_pago_aplicacion ON pago_aplicaciones;
CREATE TRIGGER trg_validar_pago_aplicacion
  BEFORE INSERT OR UPDATE ON pago_aplicaciones
  FOR EACH ROW EXECUTE FUNCTION trg_validar_pago_aplicacion_fn();

-- 3. Valor pactado manual por equipo (cuando una cotización tiene varios equipos)
CREATE TABLE IF NOT EXISTS equipo_valor_cobranza (
  orden_trabajo_id UUID PRIMARY KEY REFERENCES ordenes_trabajo(id) ON DELETE CASCADE,
  organizacion_id UUID NOT NULL REFERENCES organizaciones(id) ON DELETE CASCADE,
  valor_pactado NUMERIC(12, 2) NOT NULL CHECK (valor_pactado >= 0),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_equipo_valor_cobranza_org
  ON equipo_valor_cobranza(organizacion_id);

-- 4. Planes de pago y parcialidades
CREATE TABLE IF NOT EXISTS planes_pago (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organizacion_id UUID NOT NULL REFERENCES organizaciones(id) ON DELETE CASCADE,
  cotizacion_id TEXT NOT NULL REFERENCES cotizaciones(id) ON DELETE CASCADE,
  orden_trabajo_id UUID NULL REFERENCES ordenes_trabajo(id) ON DELETE CASCADE,
  nombre TEXT NOT NULL DEFAULT 'Plan de pagos',
  notas TEXT,
  activo BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_planes_pago_org_cot
  ON planes_pago(organizacion_id, cotizacion_id, activo);

CREATE TABLE IF NOT EXISTS plan_pagos_parcialidades (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organizacion_id UUID NOT NULL REFERENCES organizaciones(id) ON DELETE CASCADE,
  plan_id UUID NOT NULL REFERENCES planes_pago(id) ON DELETE CASCADE,
  numero INTEGER NOT NULL CHECK (numero >= 1),
  fecha_vencimiento DATE NOT NULL,
  monto NUMERIC(12, 2) NOT NULL CHECK (monto > 0),
  nota TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (plan_id, numero)
);

CREATE INDEX IF NOT EXISTS idx_plan_parcialidades_plan
  ON plan_pagos_parcialidades(plan_id, fecha_vencimiento, numero);

-- 5. RLS por organización en tablas nuevas
ALTER TABLE pago_aplicaciones ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "rls_pago_aplicaciones" ON pago_aplicaciones;
CREATE POLICY "rls_pago_aplicaciones" ON pago_aplicaciones
  FOR ALL USING (organizacion_id = get_current_org_id())
  WITH CHECK (organizacion_id = get_current_org_id());

ALTER TABLE equipo_valor_cobranza ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "rls_equipo_valor_cobranza" ON equipo_valor_cobranza;
CREATE POLICY "rls_equipo_valor_cobranza" ON equipo_valor_cobranza
  FOR ALL USING (organizacion_id = get_current_org_id())
  WITH CHECK (organizacion_id = get_current_org_id());

ALTER TABLE planes_pago ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "rls_planes_pago" ON planes_pago;
CREATE POLICY "rls_planes_pago" ON planes_pago
  FOR ALL USING (organizacion_id = get_current_org_id())
  WITH CHECK (organizacion_id = get_current_org_id());

ALTER TABLE plan_pagos_parcialidades ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "rls_plan_pagos_parcialidades" ON plan_pagos_parcialidades;
CREATE POLICY "rls_plan_pagos_parcialidades" ON plan_pagos_parcialidades
  FOR ALL USING (organizacion_id = get_current_org_id())
  WITH CHECK (organizacion_id = get_current_org_id());

-- 6. Vistas (security_invoker = true) y actualización de vista_saldo_cliente
CREATE OR REPLACE VIEW v_cobranza_cotizacion
WITH (security_invoker = true) AS
WITH pagos_vig AS (
  SELECT
    cotizacion_id,
    organizacion_id,
    ROUND(COALESCE(SUM(monto), 0), 2) AS cobrado,
    COUNT(*)::INT AS num_cobros,
    MAX(fecha) AS ultimo_cobro_fecha
  FROM pagos
  WHERE estado = 'vigente'
  GROUP BY cotizacion_id, organizacion_id
)
SELECT
  c.id AS cotizacion_id,
  c.organizacion_id,
  c.cliente_id,
  c.folio,
  c.estado,
  ROUND(COALESCE(c.total, 0), 2) AS total,
  COALESCE(pv.cobrado, 0.00)::NUMERIC(12, 2) AS cobrado,
  ROUND(GREATEST(0, COALESCE(c.total, 0) - COALESCE(pv.cobrado, 0)), 2)::NUMERIC(12, 2) AS saldo,
  ROUND(GREATEST(0, COALESCE(pv.cobrado, 0) - COALESCE(c.total, 0)), 2)::NUMERIC(12, 2) AS saldo_a_favor,
  COALESCE(pv.num_cobros, 0) AS num_cobros,
  pv.ultimo_cobro_fecha
FROM cotizaciones c
LEFT JOIN pagos_vig pv
  ON pv.cotizacion_id = c.id AND pv.organizacion_id = c.organizacion_id
WHERE c.estado IN ('Aprobada', 'Pagada');

CREATE OR REPLACE VIEW v_cobranza_equipo
WITH (security_invoker = true) AS
WITH ordenes_por_cot AS (
  SELECT cotizacion_id, organizacion_id, COUNT(*)::INT AS total_equipos
  FROM ordenes_trabajo
  WHERE cotizacion_id IS NOT NULL
  GROUP BY cotizacion_id, organizacion_id
),
aplicado_por_orden AS (
  SELECT
    pa.orden_trabajo_id,
    pa.organizacion_id,
    ROUND(COALESCE(SUM(pa.monto), 0), 2) AS cobrado_aplicado
  FROM pago_aplicaciones pa
  JOIN pagos p ON p.id = pa.pago_id
  WHERE p.estado = 'vigente'
  GROUP BY pa.orden_trabajo_id, pa.organizacion_id
),
sin_asignar_por_cot AS (
  SELECT
    p.cotizacion_id,
    p.organizacion_id,
    ROUND(COALESCE(SUM(
      p.monto - COALESCE((SELECT SUM(pa2.monto) FROM pago_aplicaciones pa2 WHERE pa2.pago_id = p.id), 0)
    ), 0), 2) AS monto_sin_asignar
  FROM pagos p
  WHERE p.estado = 'vigente'
  GROUP BY p.cotizacion_id, p.organizacion_id
)
SELECT
  ot.id AS orden_trabajo_id,
  ot.organizacion_id,
  ot.cotizacion_id,
  ev.valor_pactado,
  COALESCE(apo.cobrado_aplicado, 0.00)::NUMERIC(12, 2) AS cobrado_aplicado,
  (
    COALESCE(apo.cobrado_aplicado, 0.00) +
    CASE
      WHEN COALESCE(opc.total_equipos, 0) = 1 THEN COALESCE(sac.monto_sin_asignar, 0.00)
      ELSE 0.00
    END
  )::NUMERIC(12, 2) AS cobrado_equipo,
  COALESCE(opc.total_equipos, 0) AS total_equipos_cotizacion
FROM ordenes_trabajo ot
LEFT JOIN equipo_valor_cobranza ev
  ON ev.orden_trabajo_id = ot.id AND ev.organizacion_id = ot.organizacion_id
LEFT JOIN ordenes_por_cot opc
  ON opc.cotizacion_id = ot.cotizacion_id AND opc.organizacion_id = ot.organizacion_id
LEFT JOIN aplicado_por_orden apo
  ON apo.orden_trabajo_id = ot.id AND apo.organizacion_id = ot.organizacion_id
LEFT JOIN sin_asignar_por_cot sac
  ON sac.cotizacion_id = ot.cotizacion_id AND sac.organizacion_id = ot.organizacion_id;

CREATE OR REPLACE VIEW v_plan_parcialidades_estado
WITH (security_invoker = true) AS
WITH base_cobrado AS (
  SELECT
    pl.id AS plan_id,
    CASE
      WHEN pl.orden_trabajo_id IS NULL THEN COALESCE((
        SELECT ROUND(SUM(p.monto), 2)
        FROM pagos p
        WHERE p.cotizacion_id = pl.cotizacion_id
          AND p.organizacion_id = pl.organizacion_id
          AND p.estado = 'vigente'
      ), 0.00)
      ELSE COALESCE((
        SELECT ce.cobrado_equipo
        FROM v_cobranza_equipo ce
        WHERE ce.orden_trabajo_id = pl.orden_trabajo_id
          AND ce.organizacion_id = pl.organizacion_id
      ), 0.00)
    END AS total_cobrado
  FROM planes_pago pl
),
acumulado AS (
  SELECT
    pp.id AS parcialidad_id,
    pp.plan_id,
    pp.organizacion_id,
    pl.cotizacion_id,
    pl.orden_trabajo_id,
    pp.numero,
    pp.fecha_vencimiento,
    pp.monto,
    pp.nota,
    bc.total_cobrado,
    COALESCE(SUM(pp.monto) OVER (
      PARTITION BY pp.plan_id
      ORDER BY pp.fecha_vencimiento ASC, pp.numero ASC
      ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
    ), 0.00) AS acumulado_previo
  FROM plan_pagos_parcialidades pp
  JOIN planes_pago pl ON pl.id = pp.plan_id
  JOIN base_cobrado bc ON bc.plan_id = pp.plan_id
),
calculo AS (
  SELECT
    parcialidad_id,
    plan_id,
    organizacion_id,
    cotizacion_id,
    orden_trabajo_id,
    numero,
    fecha_vencimiento,
    monto,
    nota,
    ROUND(LEAST(monto, GREATEST(0, total_cobrado - acumulado_previo)), 2)::NUMERIC(12, 2) AS monto_cubierto
  FROM acumulado
)
SELECT
  parcialidad_id,
  plan_id,
  organizacion_id,
  cotizacion_id,
  orden_trabajo_id,
  numero,
  fecha_vencimiento,
  monto,
  nota,
  monto_cubierto,
  ROUND(GREATEST(0, monto - monto_cubierto), 2)::NUMERIC(12, 2) AS monto_pendiente,
  CASE
    WHEN monto_cubierto >= monto - 0.005 THEN 'pagada'
    WHEN fecha_vencimiento < (NOW() AT TIME ZONE 'America/Mexico_City')::date THEN 'vencida'
    WHEN monto_cubierto > 0.005 THEN 'parcial'
    ELSE 'pendiente'
  END AS estatus
FROM calculo;

CREATE OR REPLACE VIEW vista_saldo_cliente AS
SELECT
  c.id AS cliente_id,
  c.organizacion_id,
  c.limite_credito,
  COALESCE(
    (SELECT SUM(total) FROM cotizaciones WHERE cliente_id = c.id AND estado IN ('Aprobada', 'Pagada')),
    0
  ) - COALESCE(
    (SELECT SUM(p.monto)
     FROM pagos p
     JOIN cotizaciones ct ON p.cotizacion_id = ct.id
     WHERE ct.cliente_id = c.id
       AND ct.estado IN ('Aprobada', 'Pagada')
       AND p.estado = 'vigente'),
    0
  ) AS saldo_usado
FROM clientes c;

GRANT SELECT ON pago_aplicaciones TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON equipo_valor_cobranza, planes_pago, plan_pagos_parcialidades TO authenticated;

GRANT SELECT ON v_cobranza_cotizacion TO authenticated;
GRANT SELECT ON v_cobranza_equipo TO authenticated;
GRANT SELECT ON v_plan_parcialidades_estado TO authenticated;

-- 7. Funciones atómicas SECURITY DEFINER
CREATE OR REPLACE FUNCTION registrar_cobro(
  p_org_id UUID,
  p_cotizacion_id TEXT,
  p_monto NUMERIC,
  p_fecha DATE,
  p_tipo_pago TEXT,
  p_referencia TEXT DEFAULT NULL,
  p_notas TEXT DEFAULT NULL,
  p_descripcion_especie TEXT DEFAULT NULL,
  p_aplicaciones JSONB DEFAULT '[]'::jsonb,
  p_permitir_saldo_a_favor BOOLEAN DEFAULT false,
  p_usuario_id UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_cot RECORD;
  v_hoy DATE := (NOW() AT TIME ZONE 'America/Mexico_City')::date;
  v_monto NUMERIC(12, 2);
  v_cobrado_actual NUMERIC(12, 2);
  v_nuevo_cobrado NUMERIC(12, 2);
  v_saldo_nuevo NUMERIC(12, 2);
  v_saldo_a_favor NUMERIC(12, 2);
  v_pago_id TEXT;
  v_pago RECORD;
  v_app JSONB;
  v_orden_id UUID;
  v_app_monto NUMERIC(12, 2);
  v_suma_apps NUMERIC(12, 2) := 0;
  v_nuevo_estado TEXT;
BEGIN
  IF p_org_id IS NULL THEN
    RAISE EXCEPTION 'org_requerida: Organización requerida';
  END IF;

  SELECT id, organizacion_id, cliente_id, folio, estado, ROUND(COALESCE(total, 0), 2) AS total
  INTO v_cot
  FROM cotizaciones
  WHERE id = p_cotizacion_id AND organizacion_id = p_org_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'cotizacion_no_encontrada: La cotización no existe o pertenece a otra organización';
  END IF;

  IF v_cot.estado NOT IN ('Aprobada', 'Pagada') THEN
    RAISE EXCEPTION 'cotizacion_no_cobrable: Solo se pueden cobrar cotizaciones Aprobadas o Pagadas (estado actual: %)', v_cot.estado;
  END IF;

  v_monto := ROUND(COALESCE(p_monto, 0), 2);
  IF v_monto <= 0 THEN
    RAISE EXCEPTION 'monto_invalido: El monto del cobro debe ser mayor a cero';
  END IF;

  IF p_fecha IS NULL OR p_fecha > v_hoy + 1 THEN
    RAISE EXCEPTION 'fecha_futura_invalida: La fecha del cobro no puede ser mayor a un día en el futuro';
  END IF;

  IF p_tipo_pago IS NULL OR p_tipo_pago NOT IN ('Transferencia', 'Tarjeta', 'Efectivo', 'PayPal', 'Crédito 30 días', 'Especie') THEN
    RAISE EXCEPTION 'metodo_pago_invalido: Método de pago no válido (%)', COALESCE(p_tipo_pago, '');
  END IF;

  IF p_tipo_pago = 'Especie' AND TRIM(COALESCE(p_descripcion_especie, '')) = '' THEN
    RAISE EXCEPTION 'especie_sin_descripcion: Describe el bien recibido en especie y su valor acordado';
  END IF;

  SELECT ROUND(COALESCE(SUM(monto), 0), 2)
  INTO v_cobrado_actual
  FROM pagos
  WHERE cotizacion_id = p_cotizacion_id
    AND organizacion_id = p_org_id
    AND estado = 'vigente';

  v_nuevo_cobrado := ROUND(v_cobrado_actual + v_monto, 2);

  IF (v_nuevo_cobrado - v_cot.total) > 0.005 AND NOT COALESCE(p_permitir_saldo_a_favor, false) THEN
    RAISE EXCEPTION 'saldo_excedido: El cobro deja $% a favor del cliente (excede el saldo pendiente de $%). Confirma explícitamente si deseas registrar saldo a favor.',
      ROUND(v_nuevo_cobrado - v_cot.total, 2),
      ROUND(GREATEST(0, v_cot.total - v_cobrado_actual), 2);
  END IF;

  IF p_aplicaciones IS NOT NULL AND jsonb_typeof(p_aplicaciones) = 'array' THEN
    FOR v_app IN SELECT * FROM jsonb_array_elements(p_aplicaciones)
    LOOP
      v_orden_id := (v_app->>'orden_trabajo_id')::UUID;
      v_app_monto := ROUND(COALESCE((v_app->>'monto')::NUMERIC, 0), 2);
      IF v_app_monto <= 0 THEN
        RAISE EXCEPTION 'aplicacion_monto_invalido: Cada aplicación por equipo debe ser mayor a cero';
      END IF;
      v_suma_apps := ROUND(v_suma_apps + v_app_monto, 2);
    END LOOP;

    IF v_suma_apps > v_monto + 0.005 THEN
      RAISE EXCEPTION 'aplicaciones_exceden_monto: La suma aplicada a equipos (%) excede el monto del cobro (%)', v_suma_apps, v_monto;
    END IF;
  END IF;

  v_pago_id := gen_random_uuid()::TEXT;

  INSERT INTO pagos (
    id, organizacion_id, cotizacion_id, tipo_pago, referencia, monto, fecha,
    estado, notas, descripcion_especie
  ) VALUES (
    v_pago_id,
    p_org_id,
    p_cotizacion_id,
    p_tipo_pago,
    NULLIF(TRIM(COALESCE(p_referencia, '')), ''),
    v_monto,
    p_fecha,
    'vigente',
    NULLIF(TRIM(COALESCE(p_notas, '')), ''),
    CASE WHEN p_tipo_pago = 'Especie' THEN TRIM(p_descripcion_especie) ELSE NULL END
  )
  RETURNING * INTO v_pago;

  IF p_aplicaciones IS NOT NULL AND jsonb_typeof(p_aplicaciones) = 'array' THEN
    FOR v_app IN SELECT * FROM jsonb_array_elements(p_aplicaciones)
    LOOP
      INSERT INTO pago_aplicaciones (organizacion_id, pago_id, orden_trabajo_id, monto)
      VALUES (
        p_org_id,
        v_pago_id,
        (v_app->>'orden_trabajo_id')::UUID,
        ROUND((v_app->>'monto')::NUMERIC, 2)
      );
    END LOOP;
  END IF;

  v_nuevo_estado := v_cot.estado;
  IF v_nuevo_cobrado >= v_cot.total - 0.005 AND v_cot.estado = 'Aprobada' THEN
    UPDATE cotizaciones SET estado = 'Pagada' WHERE id = p_cotizacion_id AND organizacion_id = p_org_id;
    v_nuevo_estado := 'Pagada';
  END IF;

  v_saldo_nuevo := ROUND(GREATEST(0, v_cot.total - v_nuevo_cobrado), 2);
  v_saldo_a_favor := ROUND(GREATEST(0, v_nuevo_cobrado - v_cot.total), 2);

  RETURN jsonb_build_object(
    'pago', to_jsonb(v_pago),
    'cobrado', v_nuevo_cobrado,
    'saldo', v_saldo_nuevo,
    'saldo_a_favor', v_saldo_a_favor,
    'estado_cotizacion', v_nuevo_estado
  );
END;
$$;

REVOKE ALL ON FUNCTION registrar_cobro(UUID, TEXT, NUMERIC, DATE, TEXT, TEXT, TEXT, TEXT, JSONB, BOOLEAN, UUID) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION registrar_cobro(UUID, TEXT, NUMERIC, DATE, TEXT, TEXT, TEXT, TEXT, JSONB, BOOLEAN, UUID) TO service_role;

CREATE OR REPLACE FUNCTION anular_cobro(
  p_org_id UUID,
  p_pago_id TEXT,
  p_motivo TEXT,
  p_usuario_id UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_pago RECORD;
  v_cot RECORD;
  v_nuevo_cobrado NUMERIC(12, 2);
  v_nuevo_estado TEXT;
BEGIN
  IF p_org_id IS NULL THEN
    RAISE EXCEPTION 'org_requerida: Organización requerida';
  END IF;

  IF TRIM(COALESCE(p_motivo, '')) = '' THEN
    RAISE EXCEPTION 'motivo_requerido: El motivo de anulación es obligatorio';
  END IF;

  SELECT *
  INTO v_pago
  FROM pagos
  WHERE id = p_pago_id AND organizacion_id = p_org_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'cobro_no_encontrado: El cobro no existe o pertenece a otra organización';
  END IF;

  SELECT id, estado, ROUND(COALESCE(total, 0), 2) AS total
  INTO v_cot
  FROM cotizaciones
  WHERE id = v_pago.cotizacion_id AND organizacion_id = p_org_id
  FOR UPDATE;

  IF v_pago.estado = 'anulado' THEN
    SELECT ROUND(COALESCE(SUM(monto), 0), 2)
    INTO v_nuevo_cobrado
    FROM pagos
    WHERE cotizacion_id = v_pago.cotizacion_id AND organizacion_id = p_org_id AND estado = 'vigente';

    RETURN jsonb_build_object(
      'ya_anulado', true,
      'pago', to_jsonb(v_pago),
      'cobrado', v_nuevo_cobrado,
      'saldo', ROUND(GREATEST(0, v_cot.total - v_nuevo_cobrado), 2),
      'saldo_a_favor', ROUND(GREATEST(0, v_nuevo_cobrado - v_cot.total), 2),
      'estado_cotizacion', v_cot.estado
    );
  END IF;

  UPDATE pagos
  SET
    estado = 'anulado',
    anulado_at = NOW(),
    anulado_por = p_usuario_id,
    motivo_anulacion = TRIM(p_motivo)
  WHERE id = p_pago_id AND organizacion_id = p_org_id
  RETURNING * INTO v_pago;

  SELECT ROUND(COALESCE(SUM(monto), 0), 2)
  INTO v_nuevo_cobrado
  FROM pagos
  WHERE cotizacion_id = v_pago.cotizacion_id AND organizacion_id = p_org_id AND estado = 'vigente';

  v_nuevo_estado := v_cot.estado;
  IF v_cot.estado = 'Pagada' AND v_nuevo_cobrado < v_cot.total - 0.005 THEN
    UPDATE cotizaciones SET estado = 'Aprobada' WHERE id = v_cot.id AND organizacion_id = p_org_id;
    v_nuevo_estado := 'Aprobada';
  END IF;

  RETURN jsonb_build_object(
    'ya_anulado', false,
    'pago', to_jsonb(v_pago),
    'cobrado', v_nuevo_cobrado,
    'saldo', ROUND(GREATEST(0, v_cot.total - v_nuevo_cobrado), 2),
    'saldo_a_favor', ROUND(GREATEST(0, v_nuevo_cobrado - v_cot.total), 2),
    'estado_cotizacion', v_nuevo_estado
  );
END;
$$;

REVOKE ALL ON FUNCTION anular_cobro(UUID, TEXT, TEXT, UUID) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION anular_cobro(UUID, TEXT, TEXT, UUID) TO service_role;

COMMIT;
