-- Migración: Recepción atómica de compras a proveedor y eliminación de ajustar_stock rota
-- Fecha: 2026-11-25
-- Idempotente: sí (puede ejecutarse más de una vez sin error).
-- No modifica tipos de columnas (productos.stock_* / movimientos_inventario.cantidad) ni costos/precios.

BEGIN;

-- 1. Eliminar función rota ajustar_stock(uuid, numeric)
--    productos.id es TEXT, por lo que WHERE id = p_producto_id siempre fallaba con
--    "operator does not exist: text = uuid". No hay otros llamadores en BD.
DROP FUNCTION IF EXISTS public.ajustar_stock(uuid, numeric);

-- 2. RPC atómica de recepción de compra a proveedor (todo o nada, idempotente)
CREATE OR REPLACE FUNCTION public.recibir_compra_proveedor(
  p_org UUID,
  p_usuario UUID,
  p_compra_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_compra RECORD;
  v_item RECORD;
  v_producto RECORD;
  v_missing_prod TEXT;
  v_columnas_enteras BOOLEAN := false;
  v_count_items INTEGER := 0;
  v_mov_id UUID;
  v_movimientos JSONB := '[]'::jsonb;
  v_ref TEXT;
BEGIN
  IF p_org IS NULL THEN
    RAISE EXCEPTION 'org_requerida: Organización requerida';
  END IF;

  IF p_compra_id IS NULL THEN
    RAISE EXCEPTION 'compra_no_encontrada: La compra no existe o pertenece a otra organización';
  END IF;

  -- Bloquear la compra dentro de la organización (serializa recepciones simultáneas)
  SELECT id, organizacion_id, folio, estado, cotizacion_id
  INTO v_compra
  FROM compras_proveedor
  WHERE id = p_compra_id
    AND organizacion_id = p_org
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'compra_no_encontrada: La compra no existe o pertenece a otra organización';
  END IF;

  -- Idempotencia: si ya estaba Recibida, no duplicar movimientos ni stock
  IF v_compra.estado = 'Recibida' THEN
    RETURN jsonb_build_object(
      'ya_recibida', true,
      'compra_id', v_compra.id,
      'folio', v_compra.folio,
      'partidas', 0,
      'movimientos', '[]'::jsonb
    );
  END IF;

  IF v_compra.estado = 'Cancelada' THEN
    RAISE EXCEPTION 'compra_cancelada: No se puede recibir una compra cancelada';
  END IF;

  -- Verificar que la compra tenga partidas
  SELECT COUNT(*) INTO v_count_items
  FROM compra_items
  WHERE compra_id = p_compra_id;

  IF v_count_items = 0 THEN
    RAISE EXCEPTION 'compra_sin_partidas: La compra no tiene partidas para recibir';
  END IF;

  -- Detectar dinámicamente si stock_actual o cantidad siguen siendo enteras (antes de Bloque G)
  SELECT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND (
        (table_name = 'productos' AND column_name = 'stock_actual')
        OR (table_name = 'movimientos_inventario' AND column_name = 'cantidad')
      )
      AND data_type IN ('smallint', 'integer', 'bigint')
  ) INTO v_columnas_enteras;

  -- Validar cantidades de todas las partidas antes de tocar existencias
  FOR v_item IN
    SELECT id, material_id, cantidad
    FROM compra_items
    WHERE compra_id = p_compra_id
    ORDER BY id
  LOOP
    IF v_item.cantidad IS NULL OR v_item.cantidad <= 0 THEN
      RAISE EXCEPTION 'cantidad_invalida: La cantidad de la partida (%) debe ser mayor a cero', v_item.id;
    END IF;

    IF v_columnas_enteras AND v_item.cantidad <> TRUNC(v_item.cantidad) THEN
      RAISE EXCEPTION 'cantidad_no_entera: La cantidad (%) del producto "%" debe ser entera mientras el inventario use cantidades enteras',
        v_item.cantidad, v_item.material_id;
    END IF;
  END LOOP;

  -- Bloquear todos los productos involucrados en orden determinista (evita deadlocks)
  PERFORM p.id
  FROM productos p
  WHERE p.organizacion_id = p_org
    AND p.id IN (
      SELECT DISTINCT ci.material_id
      FROM compra_items ci
      WHERE ci.compra_id = p_compra_id
    )
  ORDER BY p.id
  FOR UPDATE;

  -- Verificar que todos los productos pertenezcan a la organización
  SELECT ci.material_id
  INTO v_missing_prod
  FROM compra_items ci
  LEFT JOIN productos p
    ON p.id = ci.material_id
   AND p.organizacion_id = p_org
  WHERE ci.compra_id = p_compra_id
    AND p.id IS NULL
  ORDER BY ci.id
  LIMIT 1;

  IF v_missing_prod IS NOT NULL THEN
    RAISE EXCEPTION 'producto_no_encontrado: El producto "%" no existe o pertenece a otra organización', v_missing_prod;
  END IF;

  v_ref := 'Compra ' || COALESCE(NULLIF(TRIM(v_compra.folio), ''), v_compra.id::TEXT);

  -- Insertar movimientos y sumar existencias atómicamente (dos partidas del mismo producto se suman)
  FOR v_item IN
    SELECT id, material_id, cantidad
    FROM compra_items
    WHERE compra_id = p_compra_id
    ORDER BY id
  LOOP
    INSERT INTO movimientos_inventario (
      organizacion_id,
      producto_id,
      tipo_movimiento,
      cantidad,
      referencia,
      usuario_id
    ) VALUES (
      p_org,
      v_item.material_id,
      'Entrada',
      v_item.cantidad,
      v_ref,
      p_usuario
    )
    RETURNING id INTO v_mov_id;

    UPDATE productos
    SET stock_actual = COALESCE(stock_actual, 0) + v_item.cantidad
    WHERE id = v_item.material_id
      AND organizacion_id = p_org;

    v_movimientos := v_movimientos || jsonb_build_array(
      jsonb_build_object(
        'movimiento_id', v_mov_id,
        'producto_id', v_item.material_id,
        'cantidad', v_item.cantidad
      )
    );
  END LOOP;

  -- Marcar compra como Recibida dentro de la misma transacción
  UPDATE compras_proveedor
  SET estado = 'Recibida'
  WHERE id = p_compra_id
    AND organizacion_id = p_org;

  RETURN jsonb_build_object(
    'ya_recibida', false,
    'compra_id', v_compra.id,
    'folio', v_compra.folio,
    'partidas', v_count_items,
    'movimientos', v_movimientos
  );
END;
$$;

REVOKE ALL ON FUNCTION public.recibir_compra_proveedor(UUID, UUID, UUID) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.recibir_compra_proveedor(UUID, UUID, UUID) TO service_role;

COMMIT;
