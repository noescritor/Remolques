-- Migración 20261127_01_equipos_gestion.sql
-- Bloque: Gestión de equipos (cancelar/reactivar sin borrar, cambiar cliente en equipos manuales, fecha de pedido, bitácora orden_cambios)
-- Idempotente; RLS por organización; RPCs atómicas SECURITY DEFINER con FOR UPDATE y search_path = public, pg_temp.

BEGIN;

-- ═══════════════════════════════════════════════════════════════════════════
-- 1. Columnas nuevas en ordenes_trabajo (NO se altera el CHECK de estado)
-- ═══════════════════════════════════════════════════════════════════════════
ALTER TABLE ordenes_trabajo
    ADD COLUMN IF NOT EXISTS cancelada_el TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS cancelada_por UUID,
    ADD COLUMN IF NOT EXISTS motivo_cancelacion TEXT,
    ADD COLUMN IF NOT EXISTS fecha_pedido DATE;

CREATE INDEX IF NOT EXISTS idx_ordenes_trabajo_org_cancelada
    ON ordenes_trabajo (organizacion_id, cancelada_el);

-- ═══════════════════════════════════════════════════════════════════════════
-- 2. Tabla de bitácora orden_cambios (lectura por organización, escritura solo servidor)
-- ═══════════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS orden_cambios (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organizacion_id UUID NOT NULL REFERENCES organizaciones(id) ON DELETE CASCADE,
    orden_trabajo_id UUID NOT NULL REFERENCES ordenes_trabajo(id) ON DELETE CASCADE,
    accion TEXT NOT NULL CHECK (accion IN ('cancelar', 'reactivar', 'cambiar_cliente', 'actualizar_fecha_pedido')),
    antes JSONB NOT NULL DEFAULT '{}'::jsonb,
    despues JSONB NOT NULL DEFAULT '{}'::jsonb,
    motivo TEXT,
    usuario_id UUID,
    creado_el TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

CREATE INDEX IF NOT EXISTS idx_orden_cambios_org_orden
    ON orden_cambios (organizacion_id, orden_trabajo_id, creado_el DESC);

ALTER TABLE orden_cambios ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "orden_cambios_org_select" ON orden_cambios;
CREATE POLICY "orden_cambios_org_select" ON orden_cambios
    FOR SELECT TO authenticated
    USING (organizacion_id = get_current_org_id());

REVOKE ALL ON orden_cambios FROM PUBLIC, anon, authenticated;
GRANT SELECT ON orden_cambios TO authenticated;
GRANT ALL ON orden_cambios TO service_role;

-- ═══════════════════════════════════════════════════════════════════════════
-- 3. RPC cancelar_orden_trabajo (atómica, idempotente, FOR UPDATE)
-- ═══════════════════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION cancelar_orden_trabajo(
    p_org UUID,
    p_usuario UUID,
    p_orden_id UUID,
    p_motivo TEXT,
    p_confirmo_material_entregado BOOLEAN DEFAULT false
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_motivo TEXT;
    v_orden ordenes_trabajo%ROWTYPE;
    v_orden_upd ordenes_trabajo%ROWTYPE;
    v_cobros_count INTEGER := 0;
    v_cobros_total NUMERIC(12, 2) := 0;
    v_entregas_count INTEGER := 0;
    v_entregas_cantidad NUMERIC(14, 4) := 0;
    v_entregas_texto TEXT;
    v_ahora TIMESTAMPTZ := timezone('utc', now());
BEGIN
    IF p_org IS NULL THEN
        RAISE EXCEPTION 'org_requerida: Organización requerida';
    END IF;

    IF p_orden_id IS NULL THEN
        RAISE EXCEPTION 'orden_no_encontrada: Orden de trabajo requerida';
    END IF;

    v_motivo := TRIM(COALESCE(p_motivo, ''));
    IF v_motivo = '' THEN
        RAISE EXCEPTION 'motivo_requerido: El motivo de cancelación es obligatorio';
    END IF;

    -- Lock de fila sobre la orden con filtro estricto de organización
    SELECT * INTO v_orden
    FROM ordenes_trabajo
    WHERE id = p_orden_id AND organizacion_id = p_org
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'orden_no_encontrada: La orden de trabajo no existe o pertenece a otra organización';
    END IF;

    -- Idempotencia: cancelar dos veces no es error ni duplica bitácora
    IF v_orden.cancelada_el IS NOT NULL THEN
        RETURN jsonb_build_object(
            'ok', true,
            'ya_cancelada', true,
            'orden', to_jsonb(v_orden)
        );
    END IF;

    -- Regla 1: cobros aplicados vigentes -> rechazar (409)
    SELECT COUNT(*)::INTEGER, ROUND(COALESCE(SUM(pa.monto), 0), 2)
    INTO v_cobros_count, v_cobros_total
    FROM pago_aplicaciones pa
    JOIN pagos p ON p.id = pa.pago_id
    WHERE pa.orden_trabajo_id = p_orden_id
      AND pa.organizacion_id = p_org
      AND p.organizacion_id = p_org
      AND p.estado = 'vigente';

    IF v_cobros_count > 0 THEN
        RAISE EXCEPTION 'orden_con_cobros_vigentes: El equipo tiene % cobro(s) aplicado(s) vigente(s) por $%. Primero anula o reasigna esos cobros antes de cancelar el equipo.',
            v_cobros_count, v_cobros_total
            USING DETAIL = jsonb_build_object('cobros_count', v_cobros_count, 'cobros_total', v_cobros_total)::TEXT;
    END IF;

    -- Regla 2: material entregado sin anular -> exigir confirmación explícita y reportar cuánto (no devolver stock)
    SELECT COUNT(*)::INTEGER, COALESCE(SUM(cantidad), 0)
    INTO v_entregas_count, v_entregas_cantidad
    FROM orden_despiece_entregas
    WHERE orden_trabajo_id = p_orden_id
      AND organizacion_id = p_org
      AND anulada = false;

    IF v_entregas_count > 0 AND NOT COALESCE(p_confirmo_material_entregado, false) THEN
        v_entregas_texto := TRIM(TRAILING '.' FROM TRIM(TRAILING '0' FROM ROUND(v_entregas_cantidad, 4)::TEXT));
        RAISE EXCEPTION 'orden_con_material_entregado: El equipo tiene % entrega(s) de material sin anular (% unidades en total). El stock no se devolverá automáticamente; si el material regresa al almacén, anula la entrega ANTES de cancelar (en un equipo cancelado ya no se puede anular). Confirma explícitamente si deseas cancelar de todos modos.',
            v_entregas_count, v_entregas_texto
            USING DETAIL = jsonb_build_object(
                'entregas_count', v_entregas_count,
                'cantidad_total', ROUND(v_entregas_cantidad, 4)
            )::TEXT;
    END IF;

    -- Marcar cancelación sin tocar estado, fases, entregas ni cobros
    UPDATE ordenes_trabajo
    SET cancelada_el = v_ahora,
        cancelada_por = p_usuario,
        motivo_cancelacion = v_motivo
    WHERE id = p_orden_id AND organizacion_id = p_org
    RETURNING * INTO v_orden_upd;

    INSERT INTO orden_cambios (
        organizacion_id,
        orden_trabajo_id,
        accion,
        antes,
        despues,
        motivo,
        usuario_id,
        creado_el
    ) VALUES (
        p_org,
        p_orden_id,
        'cancelar',
        jsonb_build_object(
            'cancelada_el', v_orden.cancelada_el,
            'cancelada_por', v_orden.cancelada_por,
            'motivo_cancelacion', v_orden.motivo_cancelacion,
            'estado', v_orden.estado
        ),
        jsonb_build_object(
            'cancelada_el', v_orden_upd.cancelada_el,
            'cancelada_por', v_orden_upd.cancelada_por,
            'motivo_cancelacion', v_orden_upd.motivo_cancelacion,
            'estado', v_orden_upd.estado,
            'entregas_vigentes', v_entregas_count,
            'cantidad_entregada_vigente', ROUND(v_entregas_cantidad, 4)
        ),
        v_motivo,
        p_usuario,
        v_ahora
    );

    RETURN jsonb_build_object(
        'ok', true,
        'ya_cancelada', false,
        'orden', to_jsonb(v_orden_upd),
        'entregas_vigentes', v_entregas_count,
        'cantidad_entregada_vigente', ROUND(v_entregas_cantidad, 4)
    );
END;
$$;

REVOKE ALL ON FUNCTION cancelar_orden_trabajo(UUID, UUID, UUID, TEXT, BOOLEAN) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION cancelar_orden_trabajo(UUID, UUID, UUID, TEXT, BOOLEAN) TO service_role;

-- ═══════════════════════════════════════════════════════════════════════════
-- 4. RPC reactivar_orden_trabajo (atómica, idempotente, FOR UPDATE)
-- ═══════════════════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION reactivar_orden_trabajo(
    p_org UUID,
    p_usuario UUID,
    p_orden_id UUID,
    p_motivo TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_orden ordenes_trabajo%ROWTYPE;
    v_orden_upd ordenes_trabajo%ROWTYPE;
    v_motivo TEXT := NULLIF(TRIM(COALESCE(p_motivo, '')), '');
    v_ahora TIMESTAMPTZ := timezone('utc', now());
BEGIN
    IF p_org IS NULL THEN
        RAISE EXCEPTION 'org_requerida: Organización requerida';
    END IF;

    IF p_orden_id IS NULL THEN
        RAISE EXCEPTION 'orden_no_encontrada: Orden de trabajo requerida';
    END IF;

    SELECT * INTO v_orden
    FROM ordenes_trabajo
    WHERE id = p_orden_id AND organizacion_id = p_org
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'orden_no_encontrada: La orden de trabajo no existe o pertenece a otra organización';
    END IF;

    -- Idempotencia: si ya está activa, no error ni duplica bitácora
    IF v_orden.cancelada_el IS NULL THEN
        RETURN jsonb_build_object(
            'ok', true,
            'ya_activa', true,
            'orden', to_jsonb(v_orden)
        );
    END IF;

    -- Deja estado y fases exactamente como estaban
    UPDATE ordenes_trabajo
    SET cancelada_el = NULL,
        cancelada_por = NULL,
        motivo_cancelacion = NULL
    WHERE id = p_orden_id AND organizacion_id = p_org
    RETURNING * INTO v_orden_upd;

    INSERT INTO orden_cambios (
        organizacion_id,
        orden_trabajo_id,
        accion,
        antes,
        despues,
        motivo,
        usuario_id,
        creado_el
    ) VALUES (
        p_org,
        p_orden_id,
        'reactivar',
        jsonb_build_object(
            'cancelada_el', v_orden.cancelada_el,
            'cancelada_por', v_orden.cancelada_por,
            'motivo_cancelacion', v_orden.motivo_cancelacion,
            'estado', v_orden.estado
        ),
        jsonb_build_object(
            'cancelada_el', NULL,
            'cancelada_por', NULL,
            'motivo_cancelacion', NULL,
            'estado', v_orden_upd.estado
        ),
        v_motivo,
        p_usuario,
        v_ahora
    );

    RETURN jsonb_build_object(
        'ok', true,
        'ya_activa', false,
        'orden', to_jsonb(v_orden_upd)
    );
END;
$$;

REVOKE ALL ON FUNCTION reactivar_orden_trabajo(UUID, UUID, UUID, TEXT) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION reactivar_orden_trabajo(UUID, UUID, UUID, TEXT) TO service_role;

-- ═══════════════════════════════════════════════════════════════════════════
-- 5. RPC cambiar_cliente_orden_trabajo (solo origen = 'manual', folio intacto)
-- ═══════════════════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION cambiar_cliente_orden_trabajo(
    p_org UUID,
    p_usuario UUID,
    p_orden_id UUID,
    p_cliente_id TEXT DEFAULT NULL,
    p_etiqueta TEXT DEFAULT NULL,
    p_motivo TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_orden ordenes_trabajo%ROWTYPE;
    v_orden_upd ordenes_trabajo%ROWTYPE;
    v_cliente_id TEXT := NULLIF(TRIM(COALESCE(p_cliente_id, '')), '');
    v_etiqueta TEXT := NULLIF(TRIM(COALESCE(p_etiqueta, '')), '');
    v_motivo TEXT := NULLIF(TRIM(COALESCE(p_motivo, '')), '');
    v_cli_nombre TEXT := NULL;
    v_ahora TIMESTAMPTZ := timezone('utc', now());
BEGIN
    IF p_org IS NULL THEN
        RAISE EXCEPTION 'org_requerida: Organización requerida';
    END IF;

    IF p_orden_id IS NULL THEN
        RAISE EXCEPTION 'orden_no_encontrada: Orden de trabajo requerida';
    END IF;

    SELECT * INTO v_orden
    FROM ordenes_trabajo
    WHERE id = p_orden_id AND organizacion_id = p_org
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'orden_no_encontrada: La orden de trabajo no existe o pertenece a otra organización';
    END IF;

    IF v_orden.cancelada_el IS NOT NULL THEN
        RAISE EXCEPTION 'orden_cancelada: No se puede cambiar el cliente de un equipo cancelado. Reactívalo primero.';
    END IF;

    IF v_orden.origen <> 'manual' THEN
        RAISE EXCEPTION 'orden_origen_cotizacion: El cliente de este equipo proviene de su cotización y no puede cambiarse directamente.';
    END IF;

    IF v_cliente_id IS NULL AND v_etiqueta IS NULL THEN
        RAISE EXCEPTION 'cliente_o_etiqueta_requerido: Debes seleccionar un cliente del catálogo o capturar una etiqueta para el equipo.';
    END IF;

    IF v_cliente_id IS NOT NULL THEN
        SELECT nombre_razon_social INTO v_cli_nombre
        FROM clientes
        WHERE id = v_cliente_id AND organizacion_id = p_org;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'cliente_no_encontrado: El cliente seleccionado no existe o pertenece a otra organización';
        END IF;
    END IF;

    -- Si no hubo cambios, devolver sin duplicar bitácora
    IF v_cliente_id IS NOT DISTINCT FROM v_orden.cliente_id
       AND v_etiqueta IS NOT DISTINCT FROM v_orden.etiqueta THEN
        RETURN jsonb_build_object(
            'ok', true,
            'sin_cambios', true,
            'orden', to_jsonb(v_orden)
        );
    END IF;

    -- El folio (nomenclatura_id) NO cambia
    UPDATE ordenes_trabajo
    SET cliente_id = v_cliente_id,
        etiqueta = v_etiqueta
    WHERE id = p_orden_id AND organizacion_id = p_org
    RETURNING * INTO v_orden_upd;

    INSERT INTO orden_cambios (
        organizacion_id,
        orden_trabajo_id,
        accion,
        antes,
        despues,
        motivo,
        usuario_id,
        creado_el
    ) VALUES (
        p_org,
        p_orden_id,
        'cambiar_cliente',
        jsonb_build_object(
            'cliente_id', v_orden.cliente_id,
            'etiqueta', v_orden.etiqueta
        ),
        jsonb_build_object(
            'cliente_id', v_orden_upd.cliente_id,
            'etiqueta', v_orden_upd.etiqueta,
            'cliente_nombre', v_cli_nombre
        ),
        v_motivo,
        p_usuario,
        v_ahora
    );

    RETURN jsonb_build_object(
        'ok', true,
        'sin_cambios', false,
        'orden', to_jsonb(v_orden_upd)
    );
END;
$$;

REVOKE ALL ON FUNCTION cambiar_cliente_orden_trabajo(UUID, UUID, UUID, TEXT, TEXT, TEXT) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION cambiar_cliente_orden_trabajo(UUID, UUID, UUID, TEXT, TEXT, TEXT) TO service_role;

-- ═══════════════════════════════════════════════════════════════════════════
-- 6. Vistas actualizadas: excluir equipos cancelados (cancelada_el IS NULL)
-- ═══════════════════════════════════════════════════════════════════════════

-- 6a. v_orden_despiece_avance (excluye órdenes canceladas)
CREATE OR REPLACE VIEW v_orden_despiece_avance
WITH (security_invoker = true) AS
SELECT
    l.id AS linea_id,
    l.organizacion_id,
    l.orden_trabajo_id,
    l.equipo_indice,
    l.fase_id,
    l.fase_clave,
    COALESCE(fd.nombre, l.fase_clave) AS fase_nombre,
    COALESCE(fd.orden, 99) AS fase_orden,
    l.kit,
    l.material_id,
    l.descripcion,
    l.unidad,
    l.cantidad_requerida,
    l.origen,
    l.sin_costo,
    COALESCE(SUM(CASE WHEN e.anulada = false AND e.tipo = 'entrega' THEN e.cantidad ELSE 0 END), 0) AS cantidad_entregada,
    COALESCE(SUM(CASE WHEN e.anulada = false AND e.tipo = 'reposicion' THEN e.cantidad ELSE 0 END), 0) AS cantidad_reposicion,
    GREATEST(0, l.cantidad_requerida - COALESCE(SUM(CASE WHEN e.anulada = false AND e.tipo = 'entrega' THEN e.cantidad ELSE 0 END), 0)) AS cantidad_pendiente,
    CASE
        WHEN COALESCE(SUM(CASE WHEN e.anulada = false AND e.tipo = 'entrega' THEN e.cantidad ELSE 0 END), 0) = 0 THEN 'pendiente'
        WHEN COALESCE(SUM(CASE WHEN e.anulada = false AND e.tipo = 'entrega' THEN e.cantidad ELSE 0 END), 0) >= l.cantidad_requerida THEN 'completo'
        ELSE 'parcial'
    END AS estado_entrega,
    (
        SELECT jsonb_build_object(
            'id', e_ult.id,
            'fecha', e_ult.fecha,
            'hora', e_ult.hora,
            'operario_nombre', COALESCE(op.nombre, e_ult.operario_nombre, 'Operario'),
            'tipo', e_ult.tipo
        )
        FROM orden_despiece_entregas e_ult
        LEFT JOIN operarios op ON e_ult.operario_id = op.id
        WHERE e_ult.linea_id = l.id AND e_ult.anulada = false AND e_ult.tipo = 'entrega'
        ORDER BY e_ult.created_at DESC
        LIMIT 1
    ) AS ultima_entrega
FROM orden_despiece_lineas l
JOIN ordenes_trabajo ot ON ot.id = l.orden_trabajo_id AND ot.cancelada_el IS NULL
LEFT JOIN fases_despiece fd ON l.fase_id = fd.id
LEFT JOIN orden_despiece_entregas e ON l.id = e.linea_id
GROUP BY l.id, fd.nombre, fd.orden;

GRANT SELECT ON v_orden_despiece_avance TO authenticated;

-- 6b. v_cobranza_equipo (excluye órdenes canceladas)
CREATE OR REPLACE VIEW v_cobranza_equipo
WITH (security_invoker = true) AS
WITH ordenes_por_cot AS (
  SELECT cotizacion_id, organizacion_id, COUNT(*)::INT AS total_equipos
  FROM ordenes_trabajo
  WHERE cotizacion_id IS NOT NULL
    AND cancelada_el IS NULL
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
  ON sac.cotizacion_id = ot.cotizacion_id AND sac.organizacion_id = ot.organizacion_id
WHERE ot.cancelada_el IS NULL;

GRANT SELECT ON v_cobranza_equipo TO authenticated;

-- 6b-bis. v_plan_parcialidades_estado (excluye planes por equipo cuyo equipo esté cancelado; planes por cotización sin cambio)
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
  LEFT JOIN ordenes_trabajo ot
    ON ot.id = pl.orden_trabajo_id AND ot.organizacion_id = pl.organizacion_id
  WHERE pl.orden_trabajo_id IS NULL OR ot.cancelada_el IS NULL
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

GRANT SELECT ON v_plan_parcialidades_estado TO authenticated;

-- 6c. resumen_calidad_ordenes (excluye órdenes canceladas)
CREATE OR REPLACE FUNCTION resumen_calidad_ordenes(p_org uuid)
RETURNS TABLE (
    orden_trabajo_id uuid,
    inspeccion_id uuid,
    formato text,
    folio text,
    intento integer,
    estado text,
    total_esperados integer,
    capturados integer,
    conformes integer,
    no_conformes integer,
    no_aplica integer,
    pendientes integer
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
    WITH ultimas AS (
        SELECT DISTINCT ON (i.orden_trabajo_id, i.formato)
            i.id,
            i.orden_trabajo_id,
            i.plantilla_id,
            i.formato,
            i.folio,
            i.intento,
            i.estado,
            GREATEST(1, COALESCE(jsonb_array_length(p.config->'unidades'), 1)) AS num_unidades
        FROM orden_calidad_inspecciones i
        JOIN ordenes_trabajo ot
          ON ot.id = i.orden_trabajo_id
         AND ot.organizacion_id = p_org
         AND ot.cancelada_el IS NULL
        JOIN calidad_plantillas p ON p.id = i.plantilla_id
        WHERE i.organizacion_id = p_org
        ORDER BY i.orden_trabajo_id, i.formato, i.intento DESC
    ),
    conteo_items AS (
        SELECT plantilla_id, COUNT(*)::integer AS num_items
        FROM calidad_plantilla_items
        WHERE organizacion_id = p_org
        GROUP BY plantilla_id
    ),
    conteo_res AS (
        SELECT
            r.inspeccion_id,
            COUNT(*)::integer AS capturados,
            COUNT(*) FILTER (WHERE r.resultado = 'conforme')::integer AS conformes,
            COUNT(*) FILTER (WHERE r.resultado = 'no_conforme')::integer AS no_conformes,
            COUNT(*) FILTER (WHERE r.resultado = 'no_aplica')::integer AS no_aplica
        FROM orden_calidad_resultados r
        JOIN ultimas u ON u.id = r.inspeccion_id
        WHERE r.organizacion_id = p_org
          AND r.unidad BETWEEN 1 AND u.num_unidades
        GROUP BY r.inspeccion_id
    )
    SELECT
        u.orden_trabajo_id,
        u.id AS inspeccion_id,
        u.formato,
        u.folio,
        u.intento,
        u.estado,
        (COALESCE(ci.num_items, 0) * u.num_unidades)::integer AS total_esperados,
        COALESCE(cr.capturados, 0)::integer AS capturados,
        COALESCE(cr.conformes, 0)::integer AS conformes,
        COALESCE(cr.no_conformes, 0)::integer AS no_conformes,
        COALESCE(cr.no_aplica, 0)::integer AS no_aplica,
        GREATEST(0, (COALESCE(ci.num_items, 0) * u.num_unidades) - COALESCE(cr.capturados, 0))::integer AS pendientes
    FROM ultimas u
    LEFT JOIN conteo_items ci ON ci.plantilla_id = u.plantilla_id
    LEFT JOIN conteo_res cr ON cr.inspeccion_id = u.id;
$$;

REVOKE ALL ON FUNCTION resumen_calidad_ordenes(uuid) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION resumen_calidad_ordenes(uuid) TO service_role;

-- ═══════════════════════════════════════════════════════════════════════════
-- 7. Blindaje de escrituras SQL sobre equipos cancelados + bloqueo FOR UPDATE
-- ═══════════════════════════════════════════════════════════════════════════

-- 7a. actualizar_fase_orden: rechaza si la orden está cancelada
CREATE OR REPLACE FUNCTION actualizar_fase_orden(
    p_org UUID,
    p_orden UUID,
    p_fase UUID,
    p_estado TEXT,
    p_fecha_propuesta DATE DEFAULT NULL,
    p_nota TEXT DEFAULT NULL,
    p_usuario UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    r_orden RECORD;
    r_fase RECORD;
    r_ord_fase RECORD;
    v_calc_fecha_propuesta DATE;
    v_fecha_inicio TIMESTAMPTZ;
    v_fecha_fin TIMESTAMPTZ;
    v_nota TEXT;
    v_avisos TEXT[] := ARRAY[]::TEXT[];
    v_req_terminadas INTEGER;
    v_req_total INTEGER;
    v_resultado_fase RECORD;
    v_resultado_orden RECORD;
BEGIN
    IF p_estado NOT IN ('pendiente', 'en_proceso', 'incompleta', 'pausada', 'terminada') THEN
        RAISE EXCEPTION 'estado_invalido: El estado % no es válido', p_estado
            USING ERRCODE = '22023';
    END IF;

    SELECT * INTO r_orden
    FROM ordenes_trabajo
    WHERE id = p_orden AND organizacion_id = p_org
    FOR UPDATE;

    IF r_orden.id IS NULL THEN
        RAISE EXCEPTION 'orden_no_encontrada: La orden no existe o no pertenece a la organización'
            USING ERRCODE = 'P0002';
    END IF;

    IF r_orden.cancelada_el IS NOT NULL THEN
        RAISE EXCEPTION 'orden_cancelada: No se pueden modificar fases de un equipo cancelado';
    END IF;

    SELECT * INTO r_fase
    FROM fases_produccion
    WHERE id = p_fase
      AND linea_producto_id = r_orden.linea_producto_id
      AND organizacion_id = p_org;

    IF r_fase.id IS NULL THEN
        RAISE EXCEPTION 'fase_no_pertenece_a_linea: La fase no pertenece a la línea de producción de esta orden'
            USING ERRCODE = '23503';
    END IF;

    SELECT * INTO r_ord_fase
    FROM orden_fases
    WHERE orden_trabajo_id = p_orden AND fase_id = p_fase;

    v_fecha_inicio := r_ord_fase.fecha_inicio;
    v_fecha_fin := r_ord_fase.fecha_fin;
    v_calc_fecha_propuesta := COALESCE(p_fecha_propuesta, r_ord_fase.fecha_propuesta);
    v_nota := COALESCE(p_nota, r_ord_fase.nota);

    IF p_estado = 'en_proceso' THEN
        v_fecha_inicio := COALESCE(r_ord_fase.fecha_inicio, timezone('utc', now()));
        v_fecha_fin := NULL;
        IF p_fecha_propuesta IS NULL AND (r_ord_fase.estado = 'terminada' OR v_calc_fecha_propuesta IS NULL) THEN
            v_calc_fecha_propuesta := (timezone('America/Mexico_City', now())::date + r_fase.duracion_dias);
        END IF;
    ELSIF p_estado = 'terminada' THEN
        v_fecha_fin := timezone('utc', now());
        IF v_fecha_inicio IS NULL THEN
            v_fecha_inicio := timezone('utc', now());
        END IF;
    ELSIF p_estado IN ('incompleta', 'pausada') THEN
        v_fecha_fin := NULL;
    ELSIF p_estado = 'pendiente' THEN
        v_fecha_inicio := NULL;
        v_fecha_fin := NULL;
        v_calc_fecha_propuesta := NULL;
    END IF;

    INSERT INTO orden_fases (
        organizacion_id,
        orden_trabajo_id,
        fase_id,
        estado,
        fecha_propuesta,
        fecha_inicio,
        fecha_fin,
        nota,
        actualizado_por,
        updated_at
    ) VALUES (
        p_org,
        p_orden,
        p_fase,
        p_estado,
        v_calc_fecha_propuesta,
        v_fecha_inicio,
        v_fecha_fin,
        v_nota,
        p_usuario,
        timezone('utc', now())
    )
    ON CONFLICT (orden_trabajo_id, fase_id)
    DO UPDATE SET
        estado = EXCLUDED.estado,
        fecha_propuesta = EXCLUDED.fecha_propuesta,
        fecha_inicio = EXCLUDED.fecha_inicio,
        fecha_fin = EXCLUDED.fecha_fin,
        nota = EXCLUDED.nota,
        actualizado_por = EXCLUDED.actualizado_por,
        updated_at = timezone('utc', now());

    IF r_ord_fase.id IS NULL
       OR r_ord_fase.estado IS DISTINCT FROM p_estado
       OR r_ord_fase.fecha_propuesta IS DISTINCT FROM v_calc_fecha_propuesta THEN
        INSERT INTO historial_fases (
            organizacion_id,
            orden_trabajo_id,
            fase_id,
            estado,
            estado_anterior,
            fecha_propuesta,
            nota,
            usuario_id,
            fecha_cambio
        ) VALUES (
            p_org,
            p_orden,
            p_fase,
            p_estado,
            r_ord_fase.estado,
            v_calc_fecha_propuesta,
            p_nota,
            p_usuario,
            timezone('utc', now())
        );
    END IF;

    IF r_fase.requiere_grupo IS NOT NULL AND p_estado = 'terminada' THEN
        SELECT
            COUNT(*) FILTER (WHERE ofs.estado = 'terminada'),
            COUNT(*)
        INTO v_req_terminadas, v_req_total
        FROM orden_fases ofs
        JOIN fases_produccion fp ON fp.id = ofs.fase_id
        WHERE ofs.orden_trabajo_id = p_orden
          AND fp.grupo = r_fase.requiere_grupo
          AND fp.activo = true;

        IF v_req_terminadas < v_req_total THEN
            v_avisos := array_append(
                v_avisos,
                format('La %s va %s/%s', r_fase.requiere_grupo, v_req_terminadas, v_req_total)
            );
        END IF;
    END IF;

    SELECT * INTO v_resultado_fase
    FROM orden_fases
    WHERE orden_trabajo_id = p_orden AND fase_id = p_fase;

    SELECT id, estado, estado_kanban, fase_actual_id, fecha_inicio, fecha_fin
    INTO v_resultado_orden
    FROM ordenes_trabajo
    WHERE id = p_orden;

    RETURN jsonb_build_object(
        'ok', true,
        'fase', row_to_json(v_resultado_fase),
        'orden', jsonb_build_object(
            'id', v_resultado_orden.id,
            'estado', v_resultado_orden.estado,
            'estado_kanban', v_resultado_orden.estado_kanban,
            'fase_actual_id', v_resultado_orden.fase_actual_id,
            'fecha_inicio', v_resultado_orden.fecha_inicio,
            'fecha_fin', v_resultado_orden.fecha_fin
        ),
        'avisos', v_avisos
    );
END;
$$;

REVOKE ALL ON FUNCTION actualizar_fase_orden(UUID, UUID, UUID, TEXT, DATE, TEXT, UUID) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION actualizar_fase_orden(UUID, UUID, UUID, TEXT, DATE, TEXT, UUID) TO service_role;

-- 7b. registrar_entrega_despiece: bloquea ordenes_trabajo FOR UPDATE primero (serializa con cancelar_orden_trabajo)
CREATE OR REPLACE FUNCTION registrar_entrega_despiece(
    p_org_id UUID,
    p_linea_id UUID,
    p_cantidad NUMERIC,
    p_tipo TEXT DEFAULT 'entrega',
    p_operario_id UUID DEFAULT NULL,
    p_operario_nombre TEXT DEFAULT NULL,
    p_motivo TEXT DEFAULT NULL,
    p_entregado_por UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_orden_id UUID;
    v_orden_cancelada TIMESTAMPTZ;
    v_linea RECORD;
    v_entregado NUMERIC(14, 4);
    v_pendiente NUMERIC(14, 4);
    v_entrega_id UUID;
    v_nueva_cantidad NUMERIC(14, 4);
    v_cant NUMERIC(14, 4);
    v_fecha_mx DATE;
    v_hora_mx TIME;
BEGIN
    IF p_cantidad IS NULL OR p_cantidad = 'NaN'::numeric THEN
        RAISE EXCEPTION 'cantidad_invalida: La cantidad no es válida';
    END IF;

    v_cant := round(p_cantidad, 4);

    IF v_cant <= 0 THEN
        RAISE EXCEPTION 'cantidad_invalida: La cantidad debe ser mayor a 0';
    END IF;

    IF p_tipo NOT IN ('entrega', 'reposicion') THEN
        RAISE EXCEPTION 'tipo_invalido: Solo se permite entrega o reposicion';
    END IF;

    IF p_tipo = 'reposicion' AND (p_motivo IS NULL OR trim(p_motivo) = '') THEN
        RAISE EXCEPTION 'motivo_requerido: La reposición requiere especificar el motivo (ej. pieza dañada, defecto)';
    END IF;

    IF p_operario_id IS NOT NULL THEN
        PERFORM 1 FROM operarios WHERE id = p_operario_id AND organizacion_id = p_org_id;
        IF NOT FOUND THEN
            RAISE EXCEPTION 'operario_no_encontrado: El operario especificado no existe o pertenece a otra organización';
        END IF;
    END IF;

    -- Obtener orden_trabajo_id sin lock para respetar orden de bloqueo: ordenes_trabajo -> orden_despiece_lineas
    SELECT orden_trabajo_id INTO v_orden_id
    FROM orden_despiece_lineas
    WHERE id = p_linea_id AND organizacion_id = p_org_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'linea_no_encontrada: La línea de despiece no existe o pertenece a otra organización';
    END IF;

    -- Lock de fila en ordenes_trabajo para serializar con cancelar_orden_trabajo
    SELECT cancelada_el INTO v_orden_cancelada
    FROM ordenes_trabajo
    WHERE id = v_orden_id AND organizacion_id = p_org_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'ot_no_encontrada: La orden de trabajo no existe o pertenece a otra organización';
    END IF;

    IF v_orden_cancelada IS NOT NULL THEN
        RAISE EXCEPTION 'orden_cancelada: No se puede entregar material a un equipo cancelado';
    END IF;

    -- Lock de fila sobre la línea de despiece
    SELECT * INTO v_linea
    FROM orden_despiece_lineas
    WHERE id = p_linea_id AND organizacion_id = p_org_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'linea_no_encontrada: La línea de despiece no existe o pertenece a otra organización';
    END IF;

    SELECT COALESCE(SUM(cantidad), 0) INTO v_entregado
    FROM orden_despiece_entregas
    WHERE linea_id = p_linea_id AND anulada = false AND tipo = 'entrega';

    v_pendiente := GREATEST(0, v_linea.cantidad_requerida - v_entregado);

    IF p_tipo = 'entrega' THEN
        IF (v_entregado + v_cant) > v_linea.cantidad_requerida THEN
            RAISE EXCEPTION 'excede_requerido: La cantidad % excede el saldo pendiente %',
                round(v_cant, 4), round(v_pendiente, 4)
                USING DETAIL = round(v_pendiente, 4)::text, HINT = 'saldo_pendiente';
        END IF;
    END IF;

    v_fecha_mx := (now() AT TIME ZONE 'America/Mexico_City')::date;
    v_hora_mx := (now() AT TIME ZONE 'America/Mexico_City')::time;

    INSERT INTO orden_despiece_entregas (
        organizacion_id,
        orden_trabajo_id,
        linea_id,
        tipo,
        cantidad,
        operario_id,
        operario_nombre,
        entregado_por,
        fecha,
        hora,
        motivo
    ) VALUES (
        p_org_id,
        v_linea.orden_trabajo_id,
        p_linea_id,
        p_tipo,
        v_cant,
        p_operario_id,
        trim(p_operario_nombre),
        p_entregado_por,
        v_fecha_mx,
        v_hora_mx,
        trim(p_motivo)
    )
    RETURNING id INTO v_entrega_id;

    IF p_tipo = 'entrega' THEN
        v_nueva_cantidad := v_entregado + v_cant;
        v_pendiente := GREATEST(0, v_linea.cantidad_requerida - v_nueva_cantidad);
    ELSE
        v_nueva_cantidad := v_entregado;
    END IF;

    RETURN jsonb_build_object(
        'success', true,
        'entrega_id', v_entrega_id,
        'linea_id', p_linea_id,
        'tipo', p_tipo,
        'cantidad', v_cant,
        'total_entregado', v_nueva_cantidad,
        'requerida', v_linea.cantidad_requerida,
        'pendiente', v_pendiente,
        'completo', (v_nueva_cantidad >= v_linea.cantidad_requerida),
        'fecha', v_fecha_mx,
        'hora', v_hora_mx
    );
END;
$$;

REVOKE ALL ON FUNCTION registrar_entrega_despiece(UUID, UUID, NUMERIC, TEXT, UUID, TEXT, TEXT, UUID) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION registrar_entrega_despiece(UUID, UUID, NUMERIC, TEXT, UUID, TEXT, TEXT, UUID) TO service_role;

-- 7c. entregar_fase_despiece: bloquea ordenes_trabajo FOR UPDATE y rechaza si está cancelada
CREATE OR REPLACE FUNCTION entregar_fase_despiece(
    p_org_id UUID,
    p_orden_trabajo_id UUID,
    p_equipo_indice INTEGER,
    p_fase_id UUID,
    p_operario_id UUID DEFAULT NULL,
    p_operario_nombre TEXT DEFAULT NULL,
    p_entregado_por UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_orden_cancelada TIMESTAMPTZ;
    v_linea RECORD;
    v_entregado NUMERIC(14, 4);
    v_pendiente NUMERIC(14, 4);
    v_entregadas_count INTEGER := 0;
    v_detalles JSONB := '[]'::jsonb;
    v_entrega_id UUID;
    v_fecha_mx DATE;
    v_hora_mx TIME;
    v_op_nombre TEXT;
BEGIN
    SELECT cancelada_el INTO v_orden_cancelada
    FROM ordenes_trabajo
    WHERE id = p_orden_trabajo_id AND organizacion_id = p_org_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'ot_no_encontrada: La orden de trabajo no existe o pertenece a otra organización';
    END IF;

    IF v_orden_cancelada IS NOT NULL THEN
        RAISE EXCEPTION 'orden_cancelada: No se puede entregar material a un equipo cancelado';
    END IF;

    IF p_operario_id IS NOT NULL THEN
        SELECT nombre INTO v_op_nombre FROM operarios WHERE id = p_operario_id AND organizacion_id = p_org_id;
        IF NOT FOUND THEN
            RAISE EXCEPTION 'operario_no_encontrado: El operario especificado no existe o pertenece a otra organización';
        END IF;
    ELSE
        v_op_nombre := trim(p_operario_nombre);
    END IF;

    IF v_op_nombre IS NULL OR v_op_nombre = '' THEN
        RAISE EXCEPTION 'operario_requerido: Debe especificar el operario que recibe los materiales de la fase';
    END IF;

    v_fecha_mx := (now() AT TIME ZONE 'America/Mexico_City')::date;
    v_hora_mx := (now() AT TIME ZONE 'America/Mexico_City')::time;

    FOR v_linea IN
        SELECT *
        FROM orden_despiece_lineas
        WHERE organizacion_id = p_org_id
          AND orden_trabajo_id = p_orden_trabajo_id
          AND equipo_indice = p_equipo_indice
          AND fase_id = p_fase_id
        ORDER BY created_at ASC
        FOR UPDATE
    LOOP
        SELECT COALESCE(SUM(cantidad), 0) INTO v_entregado
        FROM orden_despiece_entregas
        WHERE linea_id = v_linea.id AND anulada = false AND tipo = 'entrega';

        v_pendiente := GREATEST(0, v_linea.cantidad_requerida - v_entregado);

        IF v_pendiente > 0 THEN
            INSERT INTO orden_despiece_entregas (
                organizacion_id,
                orden_trabajo_id,
                linea_id,
                tipo,
                cantidad,
                operario_id,
                operario_nombre,
                entregado_por,
                fecha,
                hora,
                motivo
            ) VALUES (
                p_org_id,
                p_orden_trabajo_id,
                v_linea.id,
                'entrega',
                v_pendiente,
                p_operario_id,
                v_op_nombre,
                p_entregado_por,
                v_fecha_mx,
                v_hora_mx,
                'Entrega de fase completa'
            )
            RETURNING id INTO v_entrega_id;

            v_entregadas_count := v_entregadas_count + 1;
            v_detalles := v_detalles || jsonb_build_object(
                'linea_id', v_linea.id,
                'descripcion', v_linea.descripcion,
                'cantidad_entregada', v_pendiente,
                'entrega_id', v_entrega_id
            );
        END IF;
    END LOOP;

    RETURN jsonb_build_object(
        'success', true,
        'orden_trabajo_id', p_orden_trabajo_id,
        'equipo_indice', p_equipo_indice,
        'fase_id', p_fase_id,
        'lineas_entregadas', v_entregadas_count,
        'detalles', v_detalles
    );
END;
$$;

REVOKE ALL ON FUNCTION entregar_fase_despiece(UUID, UUID, INTEGER, UUID, UUID, TEXT, UUID) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION entregar_fase_despiece(UUID, UUID, INTEGER, UUID, UUID, TEXT, UUID) TO service_role;

-- 7d. anular_entrega_despiece: rechaza si la orden está cancelada
CREATE OR REPLACE FUNCTION anular_entrega_despiece(
    p_org_id UUID,
    p_entrega_id UUID,
    p_motivo TEXT,
    p_usuario_id UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_orden_id UUID;
    v_orden_cancelada TIMESTAMPTZ;
    v_entrega RECORD;
    v_linea RECORD;
    v_entregado NUMERIC(14, 4);
BEGIN
    IF p_motivo IS NULL OR trim(p_motivo) = '' THEN
        RAISE EXCEPTION 'motivo_requerido: Se requiere especificar el motivo de anulación';
    END IF;

    SELECT orden_trabajo_id INTO v_orden_id
    FROM orden_despiece_entregas
    WHERE id = p_entrega_id AND organizacion_id = p_org_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'entrega_no_encontrada: La entrega no existe o pertenece a otra organización';
    END IF;

    SELECT cancelada_el INTO v_orden_cancelada
    FROM ordenes_trabajo
    WHERE id = v_orden_id AND organizacion_id = p_org_id
    FOR UPDATE;

    IF v_orden_cancelada IS NOT NULL THEN
        RAISE EXCEPTION 'orden_cancelada: No se pueden anular entregas de un equipo cancelado';
    END IF;

    SELECT * INTO v_entrega
    FROM orden_despiece_entregas
    WHERE id = p_entrega_id AND organizacion_id = p_org_id
    FOR UPDATE;

    SELECT * INTO v_linea
    FROM orden_despiece_lineas
    WHERE id = v_entrega.linea_id AND organizacion_id = p_org_id
    FOR UPDATE;

    IF v_entrega.anulada THEN
        RAISE EXCEPTION 'ya_anulada: Esta entrega ya se encuentra anulada';
    END IF;

    UPDATE orden_despiece_entregas
    SET anulada = true,
        motivo_anulacion = trim(p_motivo),
        anulada_por = p_usuario_id,
        anulada_en = now()
    WHERE id = p_entrega_id;

    SELECT COALESCE(SUM(cantidad), 0) INTO v_entregado
    FROM orden_despiece_entregas
    WHERE linea_id = v_entrega.linea_id AND anulada = false AND tipo = 'entrega';

    SELECT * INTO v_linea FROM orden_despiece_lineas WHERE id = v_entrega.linea_id;

    RETURN jsonb_build_object(
        'success', true,
        'entrega_id', p_entrega_id,
        'linea_id', v_entrega.linea_id,
        'total_entregado', v_entregado,
        'pendiente', GREATEST(0, v_linea.cantidad_requerida - v_entregado)
    );
END;
$$;

REVOKE ALL ON FUNCTION anular_entrega_despiece(UUID, UUID, TEXT, UUID) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION anular_entrega_despiece(UUID, UUID, TEXT, UUID) TO service_role;

-- 7e. ajustar_cantidad_despiece: rechaza si la orden está cancelada
CREATE OR REPLACE FUNCTION ajustar_cantidad_despiece(
    p_org_id UUID,
    p_linea_id UUID,
    p_nueva_cantidad NUMERIC,
    p_motivo TEXT,
    p_usuario_id UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_orden_id UUID;
    v_orden_cancelada TIMESTAMPTZ;
    v_linea RECORD;
    v_entregado NUMERIC(14, 4);
    v_anterior NUMERIC(14, 4);
    v_nueva NUMERIC(14, 4);
    v_nota_ajuste TEXT;
BEGIN
    IF p_motivo IS NULL OR trim(p_motivo) = '' THEN
        RAISE EXCEPTION 'motivo_requerido: Se requiere especificar el motivo del ajuste';
    END IF;

    IF p_nueva_cantidad IS NULL OR p_nueva_cantidad = 'NaN'::numeric OR p_nueva_cantidad < 0 THEN
        RAISE EXCEPTION 'cantidad_invalida: La cantidad requerida no es válida';
    END IF;

    v_nueva := round(p_nueva_cantidad, 4);

    SELECT orden_trabajo_id INTO v_orden_id
    FROM orden_despiece_lineas
    WHERE id = p_linea_id AND organizacion_id = p_org_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'linea_no_encontrada: La línea de despiece no existe o pertenece a otra organización';
    END IF;

    SELECT cancelada_el INTO v_orden_cancelada
    FROM ordenes_trabajo
    WHERE id = v_orden_id AND organizacion_id = p_org_id
    FOR UPDATE;

    IF v_orden_cancelada IS NOT NULL THEN
        RAISE EXCEPTION 'orden_cancelada: No se puede ajustar el despiece de un equipo cancelado';
    END IF;

    SELECT * INTO v_linea
    FROM orden_despiece_lineas
    WHERE id = p_linea_id AND organizacion_id = p_org_id
    FOR UPDATE;

    v_anterior := v_linea.cantidad_requerida;

    SELECT COALESCE(SUM(cantidad), 0) INTO v_entregado
    FROM orden_despiece_entregas
    WHERE linea_id = p_linea_id AND anulada = false AND tipo = 'entrega';

    IF v_nueva < v_entregado THEN
        RAISE EXCEPTION 'excede_entregado: La nueva cantidad requerida (%) no puede ser menor a lo ya entregado (%)',
            v_nueva, v_entregado;
    END IF;

    v_nota_ajuste := to_char(now() AT TIME ZONE 'America/Mexico_City', 'YYYY-MM-DD HH24:MI:SS') ||
        ': Ajuste de ' || v_anterior || ' a ' || v_nueva || ' (' || trim(p_motivo) || ')';

    UPDATE orden_despiece_lineas
    SET cantidad_requerida = v_nueva,
        notas = CASE
            WHEN notas IS NULL OR trim(notas) = '' THEN v_nota_ajuste
            ELSE notas || E'\n' || v_nota_ajuste
        END,
        updated_at = now()
    WHERE id = p_linea_id;

    RETURN jsonb_build_object(
        'success', true,
        'linea_id', p_linea_id,
        'cantidad_anterior', v_anterior,
        'nueva_cantidad_requerida', v_nueva,
        'total_entregado', v_entregado,
        'pendiente', GREATEST(0, v_nueva - v_entregado),
        'completo', (v_entregado >= v_nueva)
    );
END;
$$;

REVOKE ALL ON FUNCTION ajustar_cantidad_despiece(UUID, UUID, NUMERIC, TEXT, UUID) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION ajustar_cantidad_despiece(UUID, UUID, NUMERIC, TEXT, UUID) TO service_role;

-- 7f. eliminar_linea_despiece: rechaza si la orden está cancelada
CREATE OR REPLACE FUNCTION eliminar_linea_despiece(
    p_org_id UUID,
    p_linea_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_orden_id UUID;
    v_orden_cancelada TIMESTAMPTZ;
    v_linea RECORD;
    v_tiene_entregas BOOLEAN;
BEGIN
    SELECT orden_trabajo_id INTO v_orden_id
    FROM orden_despiece_lineas
    WHERE id = p_linea_id AND organizacion_id = p_org_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'linea_no_encontrada: La línea no existe o pertenece a otra organización';
    END IF;

    SELECT cancelada_el INTO v_orden_cancelada
    FROM ordenes_trabajo
    WHERE id = v_orden_id AND organizacion_id = p_org_id
    FOR UPDATE;

    IF v_orden_cancelada IS NOT NULL THEN
        RAISE EXCEPTION 'orden_cancelada: No se puede modificar el despiece de un equipo cancelado';
    END IF;

    SELECT * INTO v_linea
    FROM orden_despiece_lineas
    WHERE id = p_linea_id AND organizacion_id = p_org_id
    FOR UPDATE;

    IF v_linea.origen <> 'manual' THEN
        RAISE EXCEPTION 'linea_no_eliminable: Solo se pueden eliminar líneas agregadas manualmente';
    END IF;

    SELECT EXISTS (
        SELECT 1 FROM orden_despiece_entregas WHERE linea_id = p_linea_id
    ) INTO v_tiene_entregas;

    IF v_tiene_entregas THEN
        RAISE EXCEPTION 'linea_con_historial: No se puede eliminar una partida que cuenta con historial de entregas';
    END IF;

    DELETE FROM orden_despiece_lineas WHERE id = p_linea_id;

    RETURN jsonb_build_object(
        'success', true,
        'linea_id', p_linea_id,
        'eliminada', true
    );
END;
$$;

REVOKE ALL ON FUNCTION eliminar_linea_despiece(UUID, UUID) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION eliminar_linea_despiece(UUID, UUID) TO service_role;

-- 7g. guardar_plan_tarea y cambiar_estado_plan_tarea: rechazan equipos cancelados
CREATE OR REPLACE FUNCTION guardar_plan_tarea(
    p_org UUID,
    p_usuario UUID,
    p_tarea_id UUID,
    p_fecha DATE,
    p_frente_id UUID,
    p_orden_trabajo_id UUID,
    p_descripcion TEXT,
    p_movilidad TEXT,
    p_observaciones TEXT,
    p_material_faltante BOOLEAN,
    p_estado TEXT,
    p_operarios UUID[],
    p_materiales JSONB
) RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
DECLARE
    v_tarea_id UUID;
    v_frente_org UUID;
    v_orden_org UUID;
    v_orden_cancelada TIMESTAMPTZ;
    v_op_id UUID;
    v_mat_item JSONB;
    v_desc_mat TEXT;
    v_cant_mat NUMERIC;
    v_unid_mat TEXT;
    v_prod_id TEXT;
    v_evento TEXT;
    v_es_nuevo BOOLEAN := false;
    v_tarea_ant RECORD;
    v_estado_hist TEXT := 'planeada';
BEGIN
    SELECT organizacion_id INTO v_frente_org
    FROM produccion_frentes
    WHERE id = p_frente_id AND activo = true;

    IF v_frente_org IS NULL OR v_frente_org <> p_org THEN
        RETURN jsonb_build_object('exito', false, 'error', 'frente_invalido', 'mensaje', 'El frente de producción no existe, está inactivo o pertenece a otra organización');
    END IF;

    IF p_orden_trabajo_id IS NOT NULL THEN
        SELECT organizacion_id, cancelada_el INTO v_orden_org, v_orden_cancelada
        FROM ordenes_trabajo
        WHERE id = p_orden_trabajo_id
        FOR UPDATE;

        IF v_orden_org IS NULL OR v_orden_org <> p_org THEN
            RETURN jsonb_build_object('exito', false, 'error', 'orden_invalida', 'mensaje', 'La orden de trabajo no existe o pertenece a otra organización');
        END IF;

        IF v_orden_cancelada IS NOT NULL THEN
            RETURN jsonb_build_object('exito', false, 'error', 'orden_cancelada', 'mensaje', 'No se pueden asignar tareas a un equipo cancelado');
        END IF;
    END IF;

    IF p_operarios IS NOT NULL AND array_length(p_operarios, 1) > 0 THEN
        FOREACH v_op_id IN ARRAY p_operarios LOOP
            IF NOT EXISTS (SELECT 1 FROM operarios WHERE id = v_op_id AND organizacion_id = p_org AND activo = true) THEN
                RETURN jsonb_build_object('exito', false, 'error', 'operario_invalido', 'mensaje', 'Uno o más operarios no existen, están inactivos o no pertenecen a la organización');
            END IF;
        END LOOP;
    END IF;

    IF p_tarea_id IS NOT NULL THEN
        SELECT * INTO v_tarea_ant FROM plan_tareas WHERE id = p_tarea_id AND organizacion_id = p_org;
        IF v_tarea_ant.id IS NULL THEN
            RETURN jsonb_build_object('exito', false, 'error', 'no_encontrada', 'mensaje', 'Tarea no encontrada');
        END IF;
        IF v_tarea_ant.orden_trabajo_id IS NOT NULL AND v_tarea_ant.orden_trabajo_id IS DISTINCT FROM p_orden_trabajo_id THEN
            SELECT cancelada_el INTO v_orden_cancelada
            FROM ordenes_trabajo
            WHERE id = v_tarea_ant.orden_trabajo_id AND organizacion_id = p_org;
            IF v_orden_cancelada IS NOT NULL THEN
                RETURN jsonb_build_object('exito', false, 'error', 'orden_cancelada', 'mensaje', 'No se puede modificar una tarea ligada a un equipo cancelado');
            END IF;
        END IF;
        v_es_nuevo := false;
        v_estado_hist := v_tarea_ant.estado;
        v_tarea_id := p_tarea_id;
    ELSE
        v_es_nuevo := true;
        v_tarea_id := gen_random_uuid();
    END IF;

    IF v_es_nuevo THEN
        INSERT INTO plan_tareas (
            id, organizacion_id, fecha, frente_id, orden_trabajo_id,
            descripcion, movilidad, observaciones, material_faltante,
            estado, creado_por, notas
        ) VALUES (
            v_tarea_id, p_org, p_fecha, p_frente_id, p_orden_trabajo_id,
            p_descripcion, p_movilidad, p_observaciones, coalesce(p_material_faltante, false),
            'planeada', p_usuario, 'import-2r15'
        );
        v_evento := 'creada';
    ELSE
        UPDATE plan_tareas
        SET fecha = p_fecha,
            frente_id = p_frente_id,
            orden_trabajo_id = p_orden_trabajo_id,
            descripcion = p_descripcion,
            movilidad = p_movilidad,
            observaciones = p_observaciones,
            material_faltante = coalesce(p_material_faltante, false),
            updated_at = now()
        WHERE id = v_tarea_id AND organizacion_id = p_org;
        v_evento := 'editada';
    END IF;

    DELETE FROM plan_tarea_operarios WHERE tarea_id = v_tarea_id AND organizacion_id = p_org;
    IF p_operarios IS NOT NULL AND array_length(p_operarios, 1) > 0 THEN
        FOREACH v_op_id IN ARRAY p_operarios LOOP
            INSERT INTO plan_tarea_operarios (tarea_id, operario_id, organizacion_id)
            VALUES (v_tarea_id, v_op_id, p_org)
            ON CONFLICT (tarea_id, operario_id) DO NOTHING;
        END LOOP;
    END IF;

    DELETE FROM plan_tarea_materiales WHERE tarea_id = v_tarea_id AND organizacion_id = p_org;
    IF p_materiales IS NOT NULL AND jsonb_array_length(p_materiales) > 0 THEN
        FOR v_mat_item IN SELECT * FROM jsonb_array_elements(p_materiales) LOOP
            v_desc_mat := trim(coalesce(v_mat_item->>'descripcion', ''));
            v_cant_mat := (v_mat_item->>'cantidad')::numeric;
            v_unid_mat := trim(coalesce(v_mat_item->>'unidad', 'PZA'));
            v_prod_id := NULLIF(trim(coalesce(v_mat_item->>'producto_id', '')), '');

            IF v_desc_mat = '' THEN
                RETURN jsonb_build_object('exito', false, 'error', 'material_invalido', 'mensaje', 'La descripción del material es obligatoria');
            END IF;

            IF v_cant_mat IS NULL OR v_cant_mat <= 0 THEN
                RETURN jsonb_build_object('exito', false, 'error', 'cantidad_invalida', 'mensaje', 'La cantidad de cada material debe ser mayor a 0');
            END IF;

            IF v_prod_id IS NOT NULL THEN
                IF NOT EXISTS (SELECT 1 FROM productos WHERE id = v_prod_id AND organizacion_id = p_org) THEN
                    RETURN jsonb_build_object('exito', false, 'error', 'producto_invalido', 'mensaje', 'El producto asociado al material no pertenece a la organización');
                END IF;
            END IF;

            INSERT INTO plan_tarea_materiales (
                tarea_id, organizacion_id, producto_id, descripcion,
                cantidad, unidad, notas
            ) VALUES (
                v_tarea_id, p_org, v_prod_id, v_desc_mat,
                v_cant_mat, v_unid_mat, 'import-2r15'
            );
        END LOOP;
    END IF;

    INSERT INTO plan_tareas_historial (
        organizacion_id, tarea_id, descripcion_tarea, fecha_tarea,
        evento, detalle, usuario_id
    ) VALUES (
        p_org, v_tarea_id, p_descripcion, p_fecha,
        v_evento,
        jsonb_build_object(
            'fecha', p_fecha,
            'frente_id', p_frente_id,
            'orden_trabajo_id', p_orden_trabajo_id,
            'descripcion', p_descripcion,
            'movilidad', p_movilidad,
            'material_faltante', p_material_faltante,
            'estado', v_estado_hist,
            'total_operarios', coalesce(array_length(p_operarios, 1), 0),
            'total_materiales', coalesce(jsonb_array_length(p_materiales), 0)
        ),
        p_usuario
    );

    RETURN jsonb_build_object('exito', true, 'tarea_id', v_tarea_id);
END;
$$;

REVOKE ALL ON FUNCTION guardar_plan_tarea(uuid, uuid, uuid, date, uuid, uuid, text, text, text, boolean, text, uuid[], jsonb) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION guardar_plan_tarea(uuid, uuid, uuid, date, uuid, uuid, text, text, text, boolean, text, uuid[], jsonb) TO service_role;

CREATE OR REPLACE FUNCTION cambiar_estado_plan_tarea(
    p_org UUID,
    p_usuario UUID,
    p_tarea_id UUID,
    p_nuevo_estado TEXT,
    p_inicio_real TIMESTAMPTZ,
    p_fin_real TIMESTAMPTZ
) RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
DECLARE
    r_tarea RECORD;
    v_orden_cancelada TIMESTAMPTZ;
BEGIN
    SELECT * INTO r_tarea FROM plan_tareas WHERE id = p_tarea_id AND organizacion_id = p_org;

    IF r_tarea.id IS NULL THEN
        RETURN jsonb_build_object('exito', false, 'error', 'no_encontrada', 'mensaje', 'Tarea no encontrada');
    END IF;

    IF r_tarea.orden_trabajo_id IS NOT NULL THEN
        SELECT cancelada_el INTO v_orden_cancelada
        FROM ordenes_trabajo
        WHERE id = r_tarea.orden_trabajo_id AND organizacion_id = p_org;

        IF v_orden_cancelada IS NOT NULL THEN
            RETURN jsonb_build_object('exito', false, 'error', 'orden_cancelada', 'mensaje', 'No se puede cambiar el estado de una tarea de un equipo cancelado');
        END IF;
    END IF;

    UPDATE plan_tareas
    SET estado = p_nuevo_estado,
        inicio_real = coalesce(p_inicio_real, inicio_real),
        fin_real = coalesce(p_fin_real, fin_real),
        updated_at = now()
    WHERE id = p_tarea_id AND organizacion_id = p_org;

    INSERT INTO plan_tareas_historial (
        organizacion_id, tarea_id, descripcion_tarea, fecha_tarea,
        evento, detalle, usuario_id
    ) VALUES (
        p_org, p_tarea_id, r_tarea.descripcion, r_tarea.fecha,
        'estado',
        jsonb_build_object(
            'estado_anterior', r_tarea.estado,
            'estado_nuevo', p_nuevo_estado,
            'inicio_real', coalesce(p_inicio_real, r_tarea.inicio_real),
            'fin_real', coalesce(p_fin_real, r_tarea.fin_real)
        ),
        p_usuario
    );

    RETURN jsonb_build_object('exito', true, 'tarea_id', p_tarea_id, 'nuevo_estado', p_nuevo_estado);
END;
$$;

REVOKE ALL ON FUNCTION cambiar_estado_plan_tarea(uuid, uuid, uuid, text, timestamptz, timestamptz) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION cambiar_estado_plan_tarea(uuid, uuid, uuid, text, timestamptz, timestamptz) TO service_role;

-- 7h. Calidad: crear_inspeccion_calidad, guardar_resultados_calidad, cerrar_inspeccion_calidad, reabrir_inspeccion_calidad, actualizar_encabezado_inspeccion
CREATE OR REPLACE FUNCTION crear_inspeccion_calidad(
    p_org uuid,
    p_orden uuid,
    p_formato text,
    p_plantilla uuid DEFAULT NULL,
    p_usuario uuid DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_orden RECORD;
    v_existente_id uuid;
    v_plantilla_id uuid;
    v_intento integer;
    v_seq integer;
    v_folio text;
    v_new_id uuid;
BEGIN
    IF p_formato NOT IN ('control_total', 'entrega') THEN
        RAISE EXCEPTION 'FORMATO_INVALIDO: %', p_formato;
    END IF;

    SELECT id, linea_producto_id, tipo_equipo, modelo, etiqueta, cancelada_el INTO v_orden
    FROM ordenes_trabajo
    WHERE id = p_orden AND organizacion_id = p_org
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'ORDEN_NO_ENCONTRADA';
    END IF;

    IF v_orden.cancelada_el IS NOT NULL THEN
        RAISE EXCEPTION 'ORDEN_CANCELADA: No se pueden crear inspecciones de calidad en un equipo cancelado';
    END IF;

    SELECT id INTO v_existente_id
    FROM orden_calidad_inspecciones
    WHERE orden_trabajo_id = p_orden
      AND formato = p_formato
      AND estado = 'en_proceso';

    IF v_existente_id IS NOT NULL THEN
        RAISE EXCEPTION 'YA_EXISTE:%', v_existente_id;
    END IF;

    IF p_plantilla IS NOT NULL THEN
        SELECT id INTO v_plantilla_id
        FROM calidad_plantillas
        WHERE id = p_plantilla
          AND organizacion_id = p_org
          AND formato = p_formato
          AND estado = 'activa';
        IF v_plantilla_id IS NULL THEN
            RAISE EXCEPTION 'PLANTILLA_NO_ENCONTRADA';
        END IF;
    ELSE
        IF trim(COALESCE(v_orden.tipo_equipo, '')) = '05'
           OR lower(COALESCE(v_orden.modelo, '') || ' ' || COALESCE(v_orden.etiqueta, '')) ~ 'cama\s*baja' THEN
            SELECT cp.id INTO v_plantilla_id
            FROM calidad_plantillas cp
            JOIN lineas_producto lp ON lp.id = cp.linea_producto_id
            WHERE cp.organizacion_id = p_org
              AND lp.organizacion_id = p_org
              AND lp.clave = 'cama_baja'
              AND cp.formato = p_formato
              AND cp.estado = 'activa'
            LIMIT 1;
        END IF;

        IF v_plantilla_id IS NULL THEN
            SELECT id INTO v_plantilla_id
            FROM calidad_plantillas
            WHERE organizacion_id = p_org
              AND linea_producto_id = v_orden.linea_producto_id
              AND formato = p_formato
              AND estado = 'activa';
        END IF;

        IF v_plantilla_id IS NULL THEN
            RAISE EXCEPTION 'SIN_PLANTILLA: No hay plantilla activa para esta línea y formato. Créala en Calidad → Plantillas';
        END IF;
    END IF;

    SELECT COALESCE(MAX(intento), 0) + 1 INTO v_intento
    FROM orden_calidad_inspecciones
    WHERE orden_trabajo_id = p_orden AND formato = p_formato;

    INSERT INTO calidad_folios (organizacion_id, formato, ultimo)
    VALUES (p_org, p_formato, 1)
    ON CONFLICT (organizacion_id, formato)
    DO UPDATE SET ultimo = calidad_folios.ultimo + 1
    RETURNING ultimo INTO v_seq;

    v_folio := (CASE WHEN p_formato = 'control_total' THEN 'CCT-' ELSE 'CE-' END) || lpad(v_seq::text, 6, '0');

    INSERT INTO orden_calidad_inspecciones (
        organizacion_id, orden_trabajo_id, plantilla_id, formato, folio,
        intento, estado, evaluado_por, fecha_inicio, actualizado_por
    ) VALUES (
        p_org, p_orden, v_plantilla_id, p_formato, v_folio,
        v_intento, 'en_proceso', NULL, CURRENT_DATE, p_usuario
    ) RETURNING id INTO v_new_id;

    RETURN v_new_id;
END;
$$;

REVOKE ALL ON FUNCTION crear_inspeccion_calidad(uuid, uuid, text, uuid, uuid) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION crear_inspeccion_calidad(uuid, uuid, text, uuid, uuid) TO service_role;

CREATE OR REPLACE FUNCTION guardar_resultados_calidad(
    p_org uuid,
    p_inspeccion uuid,
    p_resultados jsonb,
    p_usuario uuid DEFAULT NULL
)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_insp orden_calidad_inspecciones%ROWTYPE;
    v_orden_cancelada timestamptz;
    v_elem jsonb;
    v_item_id uuid;
    v_unidad integer;
    v_resultado text;
    v_operario_id uuid;
    v_colaborador text;
    v_fecha date;
    v_obs text;
    v_max_unidades integer;
    v_procesados integer := 0;
BEGIN
    SELECT * INTO v_insp
    FROM orden_calidad_inspecciones
    WHERE id = p_inspeccion AND organizacion_id = p_org
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'INSPECCION_NO_ENCONTRADA';
    END IF;

    SELECT cancelada_el INTO v_orden_cancelada
    FROM ordenes_trabajo
    WHERE id = v_insp.orden_trabajo_id AND organizacion_id = p_org;

    IF v_orden_cancelada IS NOT NULL THEN
        RAISE EXCEPTION 'ORDEN_CANCELADA: No se pueden modificar inspecciones de un equipo cancelado';
    END IF;

    IF v_insp.estado <> 'en_proceso' THEN
        RAISE EXCEPTION 'INSPECCION_CERRADA: La inspección ya está cerrada y no admite cambios';
    END IF;

    SELECT GREATEST(1, COALESCE(jsonb_array_length(config->'unidades'), 1)) INTO v_max_unidades
    FROM calidad_plantillas
    WHERE id = v_insp.plantilla_id;

    FOR v_elem IN SELECT * FROM jsonb_array_elements(COALESCE(p_resultados, '[]'::jsonb)) LOOP
        v_item_id := (v_elem->>'item_id')::uuid;
        v_unidad := COALESCE(NULLIF(v_elem->>'unidad', '')::integer, 1);
        v_resultado := NULLIF(trim(COALESCE(v_elem->>'resultado', '')), '');

        IF v_unidad < 1 OR v_unidad > v_max_unidades THEN
            RAISE EXCEPTION 'UNIDAD_INVALIDA: La unidad % está fuera de rango (1..%)', v_unidad, v_max_unidades;
        END IF;

        IF NOT EXISTS (
            SELECT 1 FROM calidad_plantilla_items
            WHERE id = v_item_id AND plantilla_id = v_insp.plantilla_id AND organizacion_id = p_org
        ) THEN
            RAISE EXCEPTION 'ITEM_INVALIDO: %', v_item_id;
        END IF;

        IF v_resultado IS NULL THEN
            DELETE FROM orden_calidad_resultados
            WHERE inspeccion_id = p_inspeccion AND item_id = v_item_id AND unidad = v_unidad;
        ELSE
            IF v_resultado NOT IN ('conforme', 'no_conforme', 'no_aplica') THEN
                RAISE EXCEPTION 'RESULTADO_INVALIDO: %', v_resultado;
            END IF;

            v_operario_id := NULLIF(trim(COALESCE(v_elem->>'operario_id', '')), '')::uuid;
            v_colaborador := NULLIF(trim(COALESCE(v_elem->>'colaborador', '')), '');
            v_fecha := NULLIF(trim(COALESCE(v_elem->>'fecha_inspeccion', '')), '')::date;
            v_obs := NULLIF(trim(COALESCE(v_elem->>'observaciones', '')), '');

            IF v_operario_id IS NOT NULL THEN
                SELECT nombre INTO v_colaborador
                FROM operarios
                WHERE id = v_operario_id AND organizacion_id = p_org;
                IF NOT FOUND THEN
                    RAISE EXCEPTION 'OPERARIO_NO_ENCONTRADO';
                END IF;
                v_colaborador := COALESCE(NULLIF(trim(COALESCE(v_elem->>'colaborador', '')), ''), v_colaborador);
            END IF;

            INSERT INTO orden_calidad_resultados (
                organizacion_id, inspeccion_id, item_id, unidad, resultado,
                operario_id, colaborador, fecha_inspeccion, observaciones, updated_at
            ) VALUES (
                p_org, p_inspeccion, v_item_id, v_unidad, v_resultado,
                v_operario_id, v_colaborador, COALESCE(v_fecha, CURRENT_DATE), v_obs, now()
            )
            ON CONFLICT (inspeccion_id, item_id, unidad)
            DO UPDATE SET
                resultado = EXCLUDED.resultado,
                operario_id = EXCLUDED.operario_id,
                colaborador = EXCLUDED.colaborador,
                fecha_inspeccion = EXCLUDED.fecha_inspeccion,
                observaciones = EXCLUDED.observaciones,
                updated_at = now();
        END IF;

        v_procesados := v_procesados + 1;
    END LOOP;

    UPDATE orden_calidad_inspecciones
    SET updated_at = now(), actualizado_por = p_usuario
    WHERE id = p_inspeccion AND organizacion_id = p_org;

    RETURN v_procesados;
END;
$$;

REVOKE ALL ON FUNCTION guardar_resultados_calidad(uuid, uuid, jsonb, uuid) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION guardar_resultados_calidad(uuid, uuid, jsonb, uuid) TO service_role;

CREATE OR REPLACE FUNCTION cerrar_inspeccion_calidad(
    p_org uuid,
    p_inspeccion uuid,
    p_liberado_por text DEFAULT NULL,
    p_fecha_liberacion date DEFAULT NULL,
    p_usuario uuid DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_insp orden_calidad_inspecciones%ROWTYPE;
    v_orden_cancelada timestamptz;
    v_config jsonb;
    v_unidades integer;
    v_total_items integer;
    v_total_esperados integer;
    v_capturados integer;
    v_no_conformes integer;
    v_pendientes integer;
    v_bloquea boolean;
BEGIN
    SELECT * INTO v_insp
    FROM orden_calidad_inspecciones
    WHERE id = p_inspeccion AND organizacion_id = p_org
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'INSPECCION_NO_ENCONTRADA';
    END IF;

    SELECT cancelada_el INTO v_orden_cancelada
    FROM ordenes_trabajo
    WHERE id = v_insp.orden_trabajo_id AND organizacion_id = p_org;

    IF v_orden_cancelada IS NOT NULL THEN
        RAISE EXCEPTION 'ORDEN_CANCELADA: No se pueden cerrar inspecciones de un equipo cancelado';
    END IF;

    IF v_insp.estado = 'cerrada' THEN
        RAISE EXCEPTION 'YA_CERRADA';
    END IF;

    SELECT config INTO v_config
    FROM calidad_plantillas
    WHERE id = v_insp.plantilla_id;

    v_unidades := GREATEST(1, COALESCE(jsonb_array_length(v_config->'unidades'), 1));
    v_bloquea := COALESCE((v_config->>'bloquea_liberacion')::boolean, false);

    SELECT COUNT(*) INTO v_total_items
    FROM calidad_plantilla_items
    WHERE plantilla_id = v_insp.plantilla_id;

    v_total_esperados := v_total_items * v_unidades;

    SELECT
        COUNT(*),
        COUNT(*) FILTER (WHERE resultado = 'no_conforme')
    INTO v_capturados, v_no_conformes
    FROM orden_calidad_resultados
    WHERE inspeccion_id = p_inspeccion
      AND unidad BETWEEN 1 AND v_unidades;

    v_pendientes := GREATEST(0, v_total_esperados - v_capturados);

    IF v_bloquea AND v_no_conformes > 0 THEN
        RAISE EXCEPTION 'BLOQUEADA_POR_NO_CONFORMES: Hay % puntos no conformes y la plantilla bloquea la liberación', v_no_conformes;
    END IF;

    UPDATE orden_calidad_inspecciones
    SET
        estado = 'cerrada',
        liberado_por = COALESCE(NULLIF(trim(p_liberado_por), ''), liberado_por),
        fecha_liberacion = COALESCE(p_fecha_liberacion, CURRENT_DATE),
        updated_at = now(),
        actualizado_por = p_usuario
    WHERE id = p_inspeccion AND organizacion_id = p_org;

    RETURN jsonb_build_object(
        'id', p_inspeccion,
        'estado', 'cerrada',
        'advertencias', jsonb_build_object(
            'pendientes', v_pendientes,
            'no_conformes', v_no_conformes
        )
    );
END;
$$;

REVOKE ALL ON FUNCTION cerrar_inspeccion_calidad(uuid, uuid, text, date, uuid) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION cerrar_inspeccion_calidad(uuid, uuid, text, date, uuid) TO service_role;

CREATE OR REPLACE FUNCTION reabrir_inspeccion_calidad(
    p_org uuid,
    p_inspeccion uuid,
    p_usuario uuid DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_insp orden_calidad_inspecciones%ROWTYPE;
    v_orden_cancelada timestamptz;
BEGIN
    SELECT * INTO v_insp
    FROM orden_calidad_inspecciones
    WHERE id = p_inspeccion AND organizacion_id = p_org
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'INSPECCION_NO_ENCONTRADA';
    END IF;

    SELECT cancelada_el INTO v_orden_cancelada
    FROM ordenes_trabajo
    WHERE id = v_insp.orden_trabajo_id AND organizacion_id = p_org;

    IF v_orden_cancelada IS NOT NULL THEN
        RAISE EXCEPTION 'ORDEN_CANCELADA: No se pueden reabrir inspecciones de un equipo cancelado';
    END IF;

    IF v_insp.estado <> 'cerrada' THEN
        RETURN p_inspeccion;
    END IF;

    IF EXISTS (
        SELECT 1 FROM orden_calidad_inspecciones
        WHERE orden_trabajo_id = v_insp.orden_trabajo_id
          AND formato = v_insp.formato
          AND estado = 'en_proceso'
          AND id <> p_inspeccion
    ) THEN
        RAISE EXCEPTION 'YA_EXISTE: Ya hay una inspección en proceso para esta orden y formato';
    END IF;

    UPDATE orden_calidad_inspecciones
    SET
        estado = 'en_proceso',
        fecha_liberacion = NULL,
        updated_at = now(),
        actualizado_por = p_usuario
    WHERE id = p_inspeccion AND organizacion_id = p_org;

    RETURN p_inspeccion;
END;
$$;

REVOKE ALL ON FUNCTION reabrir_inspeccion_calidad(uuid, uuid, uuid) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION reabrir_inspeccion_calidad(uuid, uuid, uuid) TO service_role;

CREATE OR REPLACE FUNCTION actualizar_encabezado_inspeccion(
    p_org uuid,
    p_inspeccion uuid,
    p_payload jsonb,
    p_usuario uuid DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_estado text;
    v_orden_id uuid;
    v_orden_cancelada timestamptz;
BEGIN
    SELECT estado, orden_trabajo_id INTO v_estado, v_orden_id
    FROM orden_calidad_inspecciones
    WHERE id = p_inspeccion AND organizacion_id = p_org
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'INSPECCION_NO_ENCONTRADA';
    END IF;

    SELECT cancelada_el INTO v_orden_cancelada
    FROM ordenes_trabajo
    WHERE id = v_orden_id AND organizacion_id = p_org;

    IF v_orden_cancelada IS NOT NULL THEN
        RAISE EXCEPTION 'ORDEN_CANCELADA: No se pueden modificar inspecciones de un equipo cancelado';
    END IF;

    IF v_estado <> 'en_proceso' THEN
        RAISE EXCEPTION 'INSPECCION_CERRADA: La inspección ya está cerrada y no admite cambios';
    END IF;

    UPDATE orden_calidad_inspecciones
    SET
        evaluado_por = CASE WHEN p_payload ? 'evaluado_por' THEN NULLIF(trim(COALESCE(p_payload->>'evaluado_por', '')), '') ELSE evaluado_por END,
        fecha_inicio = CASE WHEN p_payload ? 'fecha_inicio' THEN NULLIF(trim(COALESCE(p_payload->>'fecha_inicio', '')), '')::date ELSE fecha_inicio END,
        liberado_por = CASE WHEN p_payload ? 'liberado_por' THEN NULLIF(trim(COALESCE(p_payload->>'liberado_por', '')), '') ELSE liberado_por END,
        nota = CASE WHEN p_payload ? 'nota' THEN NULLIF(trim(COALESCE(p_payload->>'nota', '')), '') ELSE nota END,
        updated_at = now(),
        actualizado_por = p_usuario
    WHERE id = p_inspeccion AND organizacion_id = p_org;

    RETURN p_inspeccion;
END;
$$;

REVOKE ALL ON FUNCTION actualizar_encabezado_inspeccion(uuid, uuid, jsonb, uuid) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION actualizar_encabezado_inspeccion(uuid, uuid, jsonb, uuid) TO service_role;

-- 7i. Cobranza: trg_validar_pago_aplicacion_fn, registrar_cobro (con FOR UPDATE en ordenes_trabajo) y guardar_plan_pago
CREATE OR REPLACE FUNCTION trg_validar_pago_aplicacion_fn()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
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

  SELECT id, organizacion_id, cotizacion_id, cancelada_el
  INTO v_orden
  FROM ordenes_trabajo
  WHERE id = NEW.orden_trabajo_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'aplicacion_orden_invalida: La orden % no existe', NEW.orden_trabajo_id;
  END IF;

  IF v_orden.cancelada_el IS NOT NULL THEN
    RAISE EXCEPTION 'orden_cancelada: No se pueden aplicar cobros a un equipo cancelado';
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
SET search_path = public, pg_temp
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
  v_ordenes_vistas UUID[] := '{}'::UUID[];
  v_ord_check RECORD;
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

  IF p_tipo_pago IS NULL OR p_tipo_pago NOT IN ('Transferencia', 'Tarjeta', 'Efectivo', 'Cheque', 'PayPal', 'Crédito 30 días', 'Especie') THEN
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
    -- Recorrer en orden determinista de orden_trabajo_id para evitar deadlocks con FOR UPDATE
    FOR v_app IN
      SELECT elem
      FROM jsonb_array_elements(p_aplicaciones) AS elem
      ORDER BY COALESCE(elem->>'orden_trabajo_id', '') ASC
    LOOP
      BEGIN
        v_orden_id := NULLIF(TRIM(COALESCE(v_app->>'orden_trabajo_id', '')), '')::UUID;
      EXCEPTION WHEN invalid_text_representation THEN
        RAISE EXCEPTION 'aplicacion_orden_invalida: Identificador de equipo inválido';
      END;
      IF v_orden_id IS NULL THEN
        RAISE EXCEPTION 'aplicacion_orden_invalida: Cada aplicación debe indicar un equipo válido';
      END IF;
      IF v_orden_id = ANY(v_ordenes_vistas) THEN
        RAISE EXCEPTION 'aplicacion_duplicada: No puedes repetir el mismo equipo en un cobro';
      END IF;
      v_ordenes_vistas := array_append(v_ordenes_vistas, v_orden_id);

      -- Lock FOR UPDATE sobre ordenes_trabajo para serializar con cancelar_orden_trabajo
      SELECT id, organizacion_id, cotizacion_id, cancelada_el
      INTO v_ord_check
      FROM ordenes_trabajo
      WHERE id = v_orden_id
      FOR UPDATE;

      IF NOT FOUND OR v_ord_check.organizacion_id <> p_org_id OR v_ord_check.cotizacion_id IS DISTINCT FROM p_cotizacion_id THEN
        RAISE EXCEPTION 'aplicacion_orden_invalida: El equipo no pertenece a la cotización u organización';
      END IF;

      IF v_ord_check.cancelada_el IS NOT NULL THEN
        RAISE EXCEPTION 'orden_cancelada: No se pueden aplicar cobros a un equipo cancelado';
      END IF;

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

CREATE OR REPLACE FUNCTION guardar_plan_pago(
  p_org_id UUID,
  p_cotizacion_id TEXT,
  p_plan_id UUID DEFAULT NULL,
  p_orden_trabajo_id UUID DEFAULT NULL,
  p_nombre TEXT DEFAULT 'Plan de pagos',
  p_notas TEXT DEFAULT NULL,
  p_parcialidades JSONB DEFAULT '[]'::jsonb
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_cot RECORD;
  v_limite NUMERIC(12, 2);
  v_valor_eq NUMERIC(12, 2);
  v_ord_check RECORD;
  v_plan RECORD;
  v_item JSONB;
  v_num INTEGER;
  v_nums INTEGER[] := '{}'::INTEGER[];
  v_fecha DATE;
  v_monto NUMERIC(12, 2);
  v_suma NUMERIC(12, 2) := 0;
  v_parcs JSONB;
BEGIN
  IF p_org_id IS NULL THEN
    RAISE EXCEPTION 'org_requerida: Organización requerida';
  END IF;

  SELECT id, organizacion_id, ROUND(COALESCE(total, 0), 2) AS total
  INTO v_cot
  FROM cotizaciones
  WHERE id = p_cotizacion_id AND organizacion_id = p_org_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'cotizacion_no_encontrada: La cotización no existe o pertenece a otra organización';
  END IF;

  v_limite := v_cot.total;

  IF p_orden_trabajo_id IS NOT NULL THEN
    SELECT id, organizacion_id, cotizacion_id, cancelada_el
    INTO v_ord_check
    FROM ordenes_trabajo
    WHERE id = p_orden_trabajo_id
    FOR UPDATE;
    IF NOT FOUND OR v_ord_check.organizacion_id <> p_org_id OR v_ord_check.cotizacion_id IS DISTINCT FROM p_cotizacion_id THEN
      RAISE EXCEPTION 'aplicacion_orden_invalida: El equipo no pertenece a la cotización';
    END IF;
    IF v_ord_check.cancelada_el IS NOT NULL THEN
      RAISE EXCEPTION 'orden_cancelada: No se puede guardar un plan de pagos para un equipo cancelado';
    END IF;
    SELECT valor_pactado INTO v_valor_eq
    FROM equipo_valor_cobranza
    WHERE orden_trabajo_id = p_orden_trabajo_id AND organizacion_id = p_org_id;
    IF v_valor_eq IS NOT NULL THEN
      v_limite := v_valor_eq;
    END IF;
  END IF;

  IF p_parcialidades IS NULL OR jsonb_typeof(p_parcialidades) <> 'array' OR jsonb_array_length(p_parcialidades) = 0 THEN
    RAISE EXCEPTION 'plan_sin_parcialidades: El plan debe incluir al menos una parcialidad';
  END IF;

  FOR v_item IN SELECT * FROM jsonb_array_elements(p_parcialidades)
  LOOP
    BEGIN
      v_num := (v_item->>'numero')::INTEGER;
    EXCEPTION WHEN OTHERS THEN
      RAISE EXCEPTION 'numero_parcialidad_invalido: El número de parcialidad debe ser un entero >= 1';
    END;
    IF v_num IS NULL OR v_num < 1 THEN
      RAISE EXCEPTION 'numero_parcialidad_invalido: El número de parcialidad debe ser >= 1';
    END IF;
    IF v_num = ANY(v_nums) THEN
      RAISE EXCEPTION 'numero_parcialidad_duplicado: No puede haber números de parcialidad repetidos';
    END IF;
    v_nums := array_append(v_nums, v_num);

    BEGIN
      IF COALESCE(v_item->>'fecha_vencimiento', '') !~ '^\d{4}-\d{2}-\d{2}$' THEN
        RAISE EXCEPTION 'fecha_invalida: Fecha de vencimiento inválida';
      END IF;
      v_fecha := (v_item->>'fecha_vencimiento')::DATE;
    EXCEPTION WHEN datetime_field_overflow OR invalid_datetime_format THEN
      RAISE EXCEPTION 'fecha_invalida: Fecha de vencimiento inválida (%)', COALESCE(v_item->>'fecha_vencimiento', '');
    END;

    v_monto := ROUND(COALESCE((v_item->>'monto')::NUMERIC, 0), 2);
    IF v_monto <= 0 THEN
      RAISE EXCEPTION 'monto_invalido: El monto de cada parcialidad debe ser mayor a cero';
    END IF;
    v_suma := ROUND(v_suma + v_monto, 2);
  END LOOP;

  IF v_suma > v_limite + 0.005 THEN
    RAISE EXCEPTION 'plan_excede_total: La suma de parcialidades (%) excede el total (%)', v_suma, v_limite;
  END IF;

  IF p_plan_id IS NOT NULL THEN
    SELECT * INTO v_plan
    FROM planes_pago
    WHERE id = p_plan_id AND organizacion_id = p_org_id
    FOR UPDATE;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'plan_no_encontrado: Plan de pagos no encontrado';
    END IF;

    UPDATE planes_pago
    SET nombre = COALESCE(NULLIF(TRIM(p_nombre), ''), 'Plan de pagos'),
        notas = p_notas,
        updated_at = NOW()
    WHERE id = p_plan_id AND organizacion_id = p_org_id
    RETURNING * INTO v_plan;

    DELETE FROM plan_pagos_parcialidades
    WHERE plan_id = p_plan_id AND organizacion_id = p_org_id;
  ELSE
    UPDATE planes_pago
    SET activo = false, updated_at = NOW()
    WHERE organizacion_id = p_org_id
      AND cotizacion_id = p_cotizacion_id
      AND activo = true
      AND orden_trabajo_id IS NOT DISTINCT FROM p_orden_trabajo_id;

    INSERT INTO planes_pago (organizacion_id, cotizacion_id, orden_trabajo_id, nombre, notas, activo)
    VALUES (
      p_org_id,
      p_cotizacion_id,
      p_orden_trabajo_id,
      COALESCE(NULLIF(TRIM(p_nombre), ''), 'Plan de pagos'),
      p_notas,
      true
    )
    RETURNING * INTO v_plan;
  END IF;

  INSERT INTO plan_pagos_parcialidades (organizacion_id, plan_id, numero, fecha_vencimiento, monto, nota)
  SELECT
    p_org_id,
    v_plan.id,
    (elem->>'numero')::INTEGER,
    (elem->>'fecha_vencimiento')::DATE,
    ROUND((elem->>'monto')::NUMERIC, 2),
    NULLIF(TRIM(COALESCE(elem->>'nota', '')), '')
  FROM jsonb_array_elements(p_parcialidades) AS elem;

  SELECT COALESCE(jsonb_agg(to_jsonb(pp) ORDER BY pp.fecha_vencimiento ASC, pp.numero ASC), '[]'::jsonb)
  INTO v_parcs
  FROM plan_pagos_parcialidades pp
  WHERE pp.plan_id = v_plan.id;

  RETURN to_jsonb(v_plan) || jsonb_build_object('parcialidades', v_parcs);
END;
$$;

REVOKE ALL ON FUNCTION guardar_plan_pago(UUID, TEXT, UUID, UUID, TEXT, TEXT, JSONB) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION guardar_plan_pago(UUID, TEXT, UUID, UUID, TEXT, TEXT, JSONB) TO service_role;

COMMIT;
