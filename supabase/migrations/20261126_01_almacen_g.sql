-- Bloque G: Recibir factura en almacén (XML -> entradas de inventario)
-- Migración aditiva e idempotente. No modifica productos.costo ni productos.precio_unitario,
-- ni tablas de cotización, ni ajustar_stock / recepción de compras.

BEGIN;

-- 1. Generalizar catalogo_alias_factura.destino_id a TEXT para soportar productos.id (TEXT)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'catalogo_alias_factura'
      AND column_name = 'destino_id'
      AND data_type <> 'text'
  ) THEN
    ALTER TABLE catalogo_alias_factura
      ALTER COLUMN destino_id TYPE TEXT USING destino_id::TEXT;
  END IF;
END $$;

-- Actualizar aplicar_precios_acero_cfdi SOLO con el cast ::TEXT para destino_id
-- (misma firma, misma lógica, SECURITY DEFINER, search_path = public y permisos intactos)
CREATE OR REPLACE FUNCTION aplicar_precios_acero_cfdi(
  p_org UUID,
  p_usuario UUID,
  p_factura_id UUID,
  p_lineas JSONB
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  c_umbral_variacion CONSTANT NUMERIC := 0.30;
  v_factura RECORD;
  v_uuid_fiscal TEXT;
  v_fuente TEXT;
  v_tc NUMERIC;
  v_linea JSONB;
  v_partida_id UUID;
  v_material_id UUID;
  v_proveedor_norm TEXT;
  v_proveedor_existente TEXT;
  v_proveedor TEXT;
  v_factor NUMERIC(14, 6);
  v_tiene_factor BOOLEAN;
  v_factor_confirmado BOOLEAN;
  v_guardar_alias BOOLEAN;
  v_forzar_fecha BOOLEAN;
  v_forzar_var BOOLEAN;
  v_desc_norm TEXT;
  v_partida RECORD;
  v_material RECORD;
  v_precio_calc NUMERIC(14, 4);
  v_precio_actual NUMERIC(14, 4);
  v_incluye_iva_actual BOOLEAN;
  v_precio_actual_sin_iva NUMERIC;
  v_max_fecha_cfdi DATE;
  v_var NUMERIC;
  v_llave_lote TEXT;
  v_llaves_vistas TEXT[] := '{}'::TEXT[];
  v_resultados JSONB := '[]'::JSONB;
  v_alias_id UUID;
BEGIN
  IF p_org IS NULL THEN
    RAISE EXCEPTION 'org_requerida: Organización requerida';
  END IF;

  IF p_lineas IS NULL OR jsonb_typeof(p_lineas) <> 'array' OR jsonb_array_length(p_lineas) = 0 THEN
    RAISE EXCEPTION 'lineas_requeridas: Debes seleccionar al menos una partida para aplicar';
  END IF;

  SELECT id, organizacion_id, proveedor_id, folio, fecha_emision, moneda, tipo_cambio_emision, uuid_fiscal, estado
  INTO v_factura
  FROM facturas_proveedor
  WHERE id = p_factura_id AND organizacion_id = p_org
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'factura_no_encontrada: La factura no existe o pertenece a otra organización';
  END IF;

  IF LOWER(COALESCE(v_factura.estado, '')) = 'cancelada' THEN
    RAISE EXCEPTION 'factura_cancelada: No se pueden aplicar precios desde una factura cancelada';
  END IF;

  -- O6: Bloquear materiales del lote en orden determinista para evitar deadlocks cruzados
  PERFORM id
  FROM acero_materiales
  WHERE organizacion_id = p_org
    AND id IN (
      SELECT DISTINCT (elem->>'material_id')::UUID
      FROM jsonb_array_elements(p_lineas) AS elem
      WHERE NULLIF(TRIM(COALESCE(elem->>'material_id', '')), '') ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
    )
  ORDER BY id
  FOR UPDATE;

  v_uuid_fiscal := v_factura.uuid_fiscal;
  IF v_uuid_fiscal IS NULL THEN
    SELECT uuid_fiscal INTO v_uuid_fiscal
    FROM facturas_proveedor_cfdi
    WHERE factura_id = p_factura_id AND organizacion_id = p_org
    LIMIT 1;
  END IF;

  v_fuente := 'CFDI ' || COALESCE(NULLIF(TRIM(v_uuid_fiscal), ''), NULLIF(TRIM(v_factura.folio), ''), p_factura_id::TEXT);

  IF UPPER(COALESCE(v_factura.moneda, 'MXN')) = 'USD' THEN
    IF COALESCE(v_factura.tipo_cambio_emision, 0) <= 0 THEN
      RAISE EXCEPTION 'tipo_cambio_requerido: La factura en USD no tiene tipo de cambio de emisión válido';
    END IF;
    v_tc := v_factura.tipo_cambio_emision;
  ELSE
    v_tc := 1;
  END IF;

  FOR v_linea IN SELECT * FROM jsonb_array_elements(p_lineas)
  LOOP
    BEGIN
      v_partida_id := NULLIF(TRIM(COALESCE(v_linea->>'partida_id', '')), '')::UUID;
      v_material_id := NULLIF(TRIM(COALESCE(v_linea->>'material_id', '')), '')::UUID;
    EXCEPTION WHEN invalid_text_representation THEN
      RAISE EXCEPTION 'uuid_invalido: Identificador de partida o material inválido';
    END;

    IF v_partida_id IS NULL OR v_material_id IS NULL THEN
      RAISE EXCEPTION 'uuid_invalido: partida_id y material_id son obligatorios';
    END IF;

    -- O2 + N1: Normalizar proveedor; si ya existe con mayúsculas mezcladas en la org, conservar su grafía existente
    v_proveedor_norm := UPPER(TRIM(COALESCE(v_linea->>'proveedor_acero', '')));
    IF v_proveedor_norm = '' THEN
      RAISE EXCEPTION 'proveedor_requerido: El nombre del proveedor de acero es obligatorio';
    END IF;

    v_proveedor_existente := NULL;
    SELECT proveedor
    INTO v_proveedor_existente
    FROM acero_precios
    WHERE organizacion_id = p_org
      AND UPPER(proveedor) = v_proveedor_norm
    ORDER BY (material_id = v_material_id) DESC, proveedor ASC
    LIMIT 1;
    v_proveedor := COALESCE(v_proveedor_existente, v_proveedor_norm);

    -- D3: Distinguir factor omitido de factor explícito (ej. 1)
    v_tiene_factor := (v_linea ? 'factor_conversion')
      AND NULLIF(TRIM(COALESCE(v_linea->>'factor_conversion', '')), '') IS NOT NULL;
    v_factor_confirmado := COALESCE((v_linea->>'factor_confirmado')::BOOLEAN, v_tiene_factor);

    IF v_tiene_factor THEN
      BEGIN
        v_factor := (v_linea->>'factor_conversion')::NUMERIC;
      EXCEPTION WHEN OTHERS THEN
        RAISE EXCEPTION 'factor_invalido: El factor de conversión debe ser un número mayor a cero';
      END;
    ELSE
      v_factor := 1;
    END IF;
    IF v_factor <= 0 THEN
      RAISE EXCEPTION 'factor_invalido: El factor de conversión debe ser mayor a cero';
    END IF;

    v_guardar_alias := COALESCE((v_linea->>'guardar_alias')::BOOLEAN, true);
    v_forzar_fecha := COALESCE((v_linea->>'forzar_fecha_anterior')::BOOLEAN, false);
    v_forzar_var := COALESCE((v_linea->>'forzar_variacion')::BOOLEAN, false);
    v_desc_norm := NULLIF(TRIM(COALESCE(v_linea->>'descripcion_normalizada', '')), '');

    v_llave_lote := v_material_id::TEXT || '|' || UPPER(v_proveedor);
    IF v_llave_lote = ANY(v_llaves_vistas) THEN
      RAISE EXCEPTION 'material_duplicado_en_lote: Dos partidas apuntan al mismo material y proveedor en esta factura; deja solo una';
    END IF;
    v_llaves_vistas := array_append(v_llaves_vistas, v_llave_lote);

    SELECT id, factura_id, organizacion_id, tipo, descripcion, cantidad, precio_unitario, importe, clave_sat, clave_unidad
    INTO v_partida
    FROM factura_proveedor_partidas
    WHERE id = v_partida_id AND factura_id = p_factura_id AND organizacion_id = p_org
    FOR UPDATE;

    IF NOT FOUND OR v_partida.tipo <> 'concepto' THEN
      RAISE EXCEPTION 'partida_no_encontrada: La partida % no pertenece como concepto a esta factura', v_partida_id;
    END IF;

    -- D3: Si la unidad SAT es de peso (KGM/GRM/TNE/LBR), exigir factor explícito y confirmado
    IF UPPER(TRIM(COALESCE(v_partida.clave_unidad, ''))) IN ('KGM', 'GRM', 'TNE', 'LBR')
       AND (NOT v_tiene_factor OR NOT v_factor_confirmado) THEN
      RAISE EXCEPTION 'factor_requerido: La partida "%" está en unidad de peso (%) y requiere capturar un factor de conversión explícito',
        v_partida.descripcion, UPPER(TRIM(v_partida.clave_unidad));
    END IF;

    IF EXISTS (SELECT 1 FROM acero_precios_cfdi_aplicados WHERE partida_id = v_partida_id) THEN
      RAISE EXCEPTION 'partida_ya_aplicada: La partida "%" ya fue aplicada anteriormente', v_partida.descripcion;
    END IF;

    SELECT id, nombre
    INTO v_material
    FROM acero_materiales
    WHERE id = v_material_id AND organizacion_id = p_org
    FOR UPDATE;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'material_no_encontrado: El material seleccionado no pertenece a tu organización';
    END IF;

    IF COALESCE(v_partida.cantidad, 0) <= 0 OR COALESCE(v_partida.importe, 0) <= 0 THEN
      RAISE EXCEPTION 'precio_invalido: La partida "%" no tiene importe o cantidad positiva', v_partida.descripcion;
    END IF;

    v_precio_calc := ROUND((v_partida.importe / v_partida.cantidad) * v_tc * v_factor, 4);
    IF v_precio_calc <= 0 THEN
      RAISE EXCEPTION 'precio_invalido: El precio calculado para "%" debe ser mayor a cero', v_material.nombre;
    END IF;

    -- Validar fecha anterior contra el último precio CFDI aplicado al mismo material+proveedor
    SELECT MAX(fecha_emision_factura)
    INTO v_max_fecha_cfdi
    FROM acero_precios_cfdi_aplicados
    WHERE organizacion_id = p_org
      AND material_id = v_material_id
      AND UPPER(proveedor) = v_proveedor_norm;

    IF v_max_fecha_cfdi IS NOT NULL AND v_factura.fecha_emision IS NOT NULL AND v_factura.fecha_emision < v_max_fecha_cfdi AND NOT v_forzar_fecha THEN
      RAISE EXCEPTION 'fecha_anterior_a_ultimo_cfdi: La fecha de la factura (%) es anterior al último CFDI aplicado (%) para %',
        v_factura.fecha_emision, v_max_fecha_cfdi, v_material.nombre;
    END IF;

    -- D1: Validar variación > ±30% contra precio actual normalizado a base SIN IVA
    v_precio_actual := NULL;
    v_incluye_iva_actual := NULL;
    SELECT precio, incluye_iva
    INTO v_precio_actual, v_incluye_iva_actual
    FROM acero_precios
    WHERE organizacion_id = p_org
      AND material_id = v_material_id
      AND proveedor = v_proveedor;

    v_precio_actual_sin_iva := acero_precio_base_sin_iva(v_precio_actual, v_incluye_iva_actual);

    IF v_precio_actual_sin_iva IS NOT NULL AND v_precio_actual_sin_iva > 0 THEN
      v_var := ABS(v_precio_calc - v_precio_actual_sin_iva) / v_precio_actual_sin_iva;
      IF v_var > c_umbral_variacion AND NOT v_forzar_var THEN
        RAISE EXCEPTION 'variacion_precio_alta: El precio de "%" cambia más de ±30%% respecto a la base sin IVA (actual sin IVA: %, nuevo sin IVA: %)',
          v_material.nombre, ROUND(v_precio_actual_sin_iva, 2), v_precio_calc;
      END IF;
    END IF;

    -- Upsert en acero_precios (precio base sin IVA)
    INSERT INTO acero_precios (
      organizacion_id, material_id, proveedor, precio, incluye_iva, fuente, actualizado_el, updated_at
    ) VALUES (
      p_org, v_material_id, v_proveedor, v_precio_calc, false, v_fuente, NOW(), NOW()
    )
    ON CONFLICT (material_id, proveedor) DO UPDATE SET
      precio = EXCLUDED.precio,
      incluye_iva = false,
      fuente = EXCLUDED.fuente,
      actualizado_el = NOW(),
      updated_at = NOW();

    -- Registrar historial
    INSERT INTO acero_precios_historial (
      organizacion_id, material_id, proveedor, precio_anterior, precio_nuevo, usuario_id, fuente, factura_id, incluye_iva
    ) VALUES (
      p_org, v_material_id, v_proveedor, v_precio_actual, v_precio_calc, p_usuario, v_fuente, p_factura_id, false
    );

    -- Registrar partida aplicada
    INSERT INTO acero_precios_cfdi_aplicados (
      organizacion_id, partida_id, material_id, proveedor, precio_aplicado, factura_id, fecha_emision_factura, usuario_id
    ) VALUES (
      p_org, v_partida_id, v_material_id, v_proveedor, v_precio_calc, p_factura_id, v_factura.fecha_emision, p_usuario
    );

    -- Guardar alias si aplica (cast ::TEXT tras migración de destino_id a TEXT)
    IF v_guardar_alias AND v_factura.proveedor_id IS NOT NULL THEN
      IF v_desc_norm IS NULL THEN
        v_desc_norm := LOWER(TRIM(regexp_replace(v_partida.descripcion, '\s+', ' ', 'g')));
      END IF;

      SELECT id INTO v_alias_id
      FROM catalogo_alias_factura
      WHERE organizacion_id = p_org
        AND proveedor_id = v_factura.proveedor_id
        AND COALESCE(clave_sat, '') = COALESCE(v_partida.clave_sat, '')
        AND descripcion_normalizada = v_desc_norm;

      IF v_alias_id IS NOT NULL THEN
        UPDATE catalogo_alias_factura
        SET destino_tipo = 'acero_material',
            destino_id = v_material_id::TEXT,
            proveedor_acero = v_proveedor,
            factor_conversion = v_factor,
            veces_confirmado = veces_confirmado + 1,
            ultima_confirmacion = NOW(),
            confirmado_por = p_usuario
        WHERE id = v_alias_id;
      ELSE
        INSERT INTO catalogo_alias_factura (
          organizacion_id, proveedor_id, clave_sat, descripcion_normalizada,
          destino_tipo, destino_id, proveedor_acero, factor_conversion,
          veces_confirmado, ultima_confirmacion, confirmado_por
        ) VALUES (
          p_org, v_factura.proveedor_id, v_partida.clave_sat, v_desc_norm,
          'acero_material', v_material_id::TEXT, v_proveedor, v_factor,
          1, NOW(), p_usuario
        );
      END IF;
    END IF;

    v_resultados := v_resultados || jsonb_build_array(
      jsonb_build_object(
        'partida_id', v_partida_id,
        'material_id', v_material_id,
        'material_nombre', v_material.nombre,
        'proveedor_acero', v_proveedor,
        'precio_anterior', v_precio_actual,
        'precio_aplicado', v_precio_calc,
        'incluye_iva', false,
        'fuente', v_fuente
      )
    );
  END LOOP;

  RETURN jsonb_build_object(
    'ok', true,
    'total', jsonb_array_length(v_resultados),
    'aplicadas', v_resultados
  );
END;
$$;

REVOKE ALL ON FUNCTION aplicar_precios_acero_cfdi(UUID, UUID, UUID, JSONB) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION aplicar_precios_acero_cfdi(UUID, UUID, UUID, JSONB) TO service_role;

-- 2. Existencias fraccionarias: productos.stock_* y movimientos_inventario.cantidad -> NUMERIC(14,4)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'productos' AND column_name = 'stock_actual' AND data_type <> 'numeric'
  ) THEN
    ALTER TABLE productos ALTER COLUMN stock_actual TYPE NUMERIC(14,4) USING COALESCE(stock_actual, 0)::NUMERIC(14,4);
    ALTER TABLE productos ALTER COLUMN stock_actual SET DEFAULT 0;
  END IF;

  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'productos' AND column_name = 'stock_reservado' AND data_type <> 'numeric'
  ) THEN
    ALTER TABLE productos ALTER COLUMN stock_reservado TYPE NUMERIC(14,4) USING COALESCE(stock_reservado, 0)::NUMERIC(14,4);
    ALTER TABLE productos ALTER COLUMN stock_reservado SET DEFAULT 0;
  END IF;

  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'productos' AND column_name = 'stock_minimo' AND data_type <> 'numeric'
  ) THEN
    ALTER TABLE productos ALTER COLUMN stock_minimo TYPE NUMERIC(14,4) USING COALESCE(stock_minimo, 0)::NUMERIC(14,4);
    ALTER TABLE productos ALTER COLUMN stock_minimo SET DEFAULT 0;
  END IF;

  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'movimientos_inventario' AND column_name = 'cantidad' AND data_type <> 'numeric'
  ) THEN
    ALTER TABLE movimientos_inventario ALTER COLUMN cantidad TYPE NUMERIC(14,4) USING cantidad::NUMERIC(14,4);
  END IF;
END $$;

-- 3. Columnas nuevas de último costo de compra en productos (MXN, sin IVA; NO toca productos.costo)
ALTER TABLE productos
  ADD COLUMN IF NOT EXISTS ultimo_costo_compra NUMERIC(14,4) NULL,
  ADD COLUMN IF NOT EXISTS ultimo_costo_compra_fecha DATE NULL,
  ADD COLUMN IF NOT EXISTS ultimo_costo_compra_factura_id UUID NULL REFERENCES facturas_proveedor(id) ON DELETE SET NULL;

-- 4. Tablas de recepciones de almacén desde factura CFDI
CREATE TABLE IF NOT EXISTS almacen_recepciones (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organizacion_id UUID NOT NULL REFERENCES organizaciones(id) ON DELETE CASCADE,
  factura_id UUID NOT NULL REFERENCES facturas_proveedor(id) ON DELETE RESTRICT,
  proveedor_id UUID NULL REFERENCES proveedores(id) ON DELETE SET NULL,
  compra_id UUID NULL REFERENCES compras_proveedor(id) ON DELETE SET NULL,
  estado TEXT NOT NULL DEFAULT 'recibida' CHECK (estado IN ('recibida', 'anulada')),
  notas TEXT NULL,
  recibido_por UUID NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  anulada_el TIMESTAMPTZ NULL,
  anulada_por UUID NULL,
  motivo_anulacion TEXT NULL
);

-- Garantizar ON DELETE RESTRICT en instalaciones previas (idempotente)
DO $$
BEGIN
  ALTER TABLE almacen_recepciones DROP CONSTRAINT IF EXISTS almacen_recepciones_factura_id_fkey;
  ALTER TABLE almacen_recepciones
    ADD CONSTRAINT almacen_recepciones_factura_id_fkey
    FOREIGN KEY (factura_id) REFERENCES facturas_proveedor(id) ON DELETE RESTRICT;
END $$;

CREATE INDEX IF NOT EXISTS idx_almacen_recepciones_org_fecha
  ON almacen_recepciones (organizacion_id, created_at DESC, id);

CREATE INDEX IF NOT EXISTS idx_almacen_recepciones_org_factura
  ON almacen_recepciones (organizacion_id, factura_id);

ALTER TABLE almacen_recepciones ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "rls_almacen_recepciones_select" ON almacen_recepciones;
CREATE POLICY "rls_almacen_recepciones_select" ON almacen_recepciones
  FOR SELECT TO authenticated
  USING (organizacion_id = get_current_org_id());
GRANT SELECT ON almacen_recepciones TO authenticated;

CREATE TABLE IF NOT EXISTS almacen_recepcion_lineas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organizacion_id UUID NOT NULL REFERENCES organizaciones(id) ON DELETE CASCADE,
  recepcion_id UUID NOT NULL REFERENCES almacen_recepciones(id) ON DELETE CASCADE,
  partida_id UUID NULL REFERENCES factura_proveedor_partidas(id) ON DELETE RESTRICT,
  partida_id_original UUID NULL,
  producto_id TEXT NOT NULL REFERENCES productos(id) ON DELETE RESTRICT,
  cantidad_xml NUMERIC(14,4) NOT NULL CHECK (cantidad_xml > 0),
  unidad_xml TEXT NULL,
  factor_conversion NUMERIC(14,6) NOT NULL DEFAULT 1 CHECK (factor_conversion > 0),
  cantidad_recibida NUMERIC(14,4) NOT NULL CHECK (cantidad_recibida > 0),
  costo_unitario_mxn NUMERIC(14,4) NOT NULL CHECK (costo_unitario_mxn > 0),
  movimiento_id UUID NULL REFERENCES movimientos_inventario(id) ON DELETE SET NULL,
  movimiento_anulacion_id UUID NULL REFERENCES movimientos_inventario(id) ON DELETE SET NULL,
  costo_actualizado BOOLEAN NOT NULL DEFAULT false,
  activa BOOLEAN NOT NULL DEFAULT true,
  notas TEXT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT almacen_recepcion_lineas_partida_activa_check CHECK (activa = false OR partida_id IS NOT NULL)
);

-- Garantizar ON DELETE RESTRICT + partida_id_original en instalaciones previas (idempotente)
DO $$
BEGIN
  ALTER TABLE almacen_recepcion_lineas ADD COLUMN IF NOT EXISTS partida_id_original UUID NULL;
  UPDATE almacen_recepcion_lineas
  SET partida_id_original = partida_id
  WHERE partida_id_original IS NULL AND partida_id IS NOT NULL;
  ALTER TABLE almacen_recepcion_lineas ALTER COLUMN partida_id DROP NOT NULL;
  ALTER TABLE almacen_recepcion_lineas DROP CONSTRAINT IF EXISTS almacen_recepcion_lineas_partida_activa_check;
  ALTER TABLE almacen_recepcion_lineas
    ADD CONSTRAINT almacen_recepcion_lineas_partida_activa_check
    CHECK (activa = false OR partida_id IS NOT NULL);
  ALTER TABLE almacen_recepcion_lineas DROP CONSTRAINT IF EXISTS almacen_recepcion_lineas_partida_id_fkey;
  ALTER TABLE almacen_recepcion_lineas
    ADD CONSTRAINT almacen_recepcion_lineas_partida_id_fkey
    FOREIGN KEY (partida_id) REFERENCES factura_proveedor_partidas(id) ON DELETE RESTRICT;
END $$;

-- Una partida solo puede estar en una línea activa; al anular (activa = false) queda libre
CREATE UNIQUE INDEX IF NOT EXISTS uq_almacen_recepcion_lineas_partida_activa
  ON almacen_recepcion_lineas (partida_id)
  WHERE activa = true;

CREATE INDEX IF NOT EXISTS idx_almacen_recepcion_lineas_recepcion
  ON almacen_recepcion_lineas (organizacion_id, recepcion_id);

CREATE INDEX IF NOT EXISTS idx_almacen_recepcion_lineas_producto
  ON almacen_recepcion_lineas (organizacion_id, producto_id);

ALTER TABLE almacen_recepcion_lineas ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "rls_almacen_recepcion_lineas_select" ON almacen_recepcion_lineas;
CREATE POLICY "rls_almacen_recepcion_lineas_select" ON almacen_recepcion_lineas
  FOR SELECT TO authenticated
  USING (organizacion_id = get_current_org_id());
GRANT SELECT ON almacen_recepcion_lineas TO authenticated;

-- 5. RPC atómica recibir_factura_almacen (todo o nada)
CREATE OR REPLACE FUNCTION recibir_factura_almacen(
  p_org UUID,
  p_usuario UUID,
  p_factura_id UUID,
  p_lineas JSONB,
  p_confirmo_doble BOOLEAN DEFAULT false,
  p_notas TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_factura RECORD;
  v_tc NUMERIC;
  v_ref_factura TEXT;
  v_folio_compra TEXT;
  v_folios_dup TEXT;
  v_fecha_ref DATE;
  v_recepcion_id UUID;
  v_linea JSONB;
  v_partida_id UUID;
  v_producto_id TEXT;
  v_partidas_vistas UUID[] := '{}'::UUID[];
  v_productos_lote TEXT[] := '{}'::TEXT[];
  v_partida RECORD;
  v_producto RECORD;
  v_tiene_factor BOOLEAN;
  v_factor_confirmado BOOLEAN;
  v_factor NUMERIC(14,6);
  v_cant_calculada NUMERIC(14,4);
  v_cant_recibida NUMERIC(14,4);
  v_costo_unit NUMERIC(14,4);
  v_guardar_alias BOOLEAN;
  v_desc_norm TEXT;
  v_nota_linea TEXT;
  v_mov_id UUID;
  v_costo_actualizado BOOLEAN;
  v_alias_existente RECORD;
  v_resultados JSONB := '[]'::JSONB;
BEGIN
  IF p_org IS NULL THEN
    RAISE EXCEPTION 'org_requerida: Organización requerida';
  END IF;

  IF p_lineas IS NULL OR jsonb_typeof(p_lineas) <> 'array' OR jsonb_array_length(p_lineas) = 0 THEN
    RAISE EXCEPTION 'lineas_requeridas: Debes seleccionar al menos una partida para recibir';
  END IF;

  -- Bloquear factura de la organización
  SELECT id, organizacion_id, proveedor_id, compra_id, folio, fecha_emision, moneda, tipo_cambio_emision, estado
  INTO v_factura
  FROM facturas_proveedor
  WHERE id = p_factura_id AND organizacion_id = p_org
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'factura_no_encontrada: La factura no existe o pertenece a otra organización';
  END IF;

  IF LOWER(COALESCE(v_factura.estado, '')) = 'cancelada' THEN
    RAISE EXCEPTION 'factura_cancelada: No se puede recibir mercancía de una factura cancelada';
  END IF;

  IF UPPER(COALESCE(v_factura.moneda, 'MXN')) = 'USD' THEN
    IF COALESCE(v_factura.tipo_cambio_emision, 0) <= 0 THEN
      RAISE EXCEPTION 'tipo_cambio_requerido: La factura en USD no tiene tipo de cambio de emisión válido';
    END IF;
    v_tc := v_factura.tipo_cambio_emision;
  ELSE
    v_tc := 1;
  END IF;

  -- Recolectar producto_ids del lote y bloquear en orden determinista para evitar deadlocks
  SELECT COALESCE(array_agg(DISTINCT TRIM(elem->>'producto_id')), '{}'::TEXT[])
  INTO v_productos_lote
  FROM jsonb_array_elements(p_lineas) AS elem
  WHERE NULLIF(TRIM(COALESCE(elem->>'producto_id', '')), '') IS NOT NULL;

  PERFORM id
  FROM productos
  WHERE organizacion_id = p_org
    AND id = ANY(v_productos_lote)
  ORDER BY id
  FOR UPDATE;

  -- Doble conteo (a + b): rechazar salvo p_confirmo_doble = true
  IF NOT COALESCE(p_confirmo_doble, false) THEN
    -- (a) Factura ligada directamente a compra_id ya Recibida
    IF v_factura.compra_id IS NOT NULL THEN
      SELECT folio INTO v_folio_compra
      FROM compras_proveedor
      WHERE id = v_factura.compra_id
        AND organizacion_id = p_org
        AND UPPER(TRIM(COALESCE(estado, ''))) = 'RECIBIDA'
      LIMIT 1;

      IF v_folio_compra IS NOT NULL THEN
        RAISE EXCEPTION 'compra_ya_recibida: La factura está ligada a la compra "%" que ya fue recibida; confirma que no es la misma mercancía',
          v_folio_compra;
      END IF;
    END IF;

    -- (b) Compra Recibida del mismo proveedor en los últimos 60 días con al menos un producto en común
    IF v_factura.proveedor_id IS NOT NULL AND array_length(v_productos_lote, 1) > 0 THEN
      v_fecha_ref := COALESCE(v_factura.fecha_emision, CURRENT_DATE);
      SELECT string_agg(DISTINCT c.folio, ', ' ORDER BY c.folio)
      INTO v_folios_dup
      FROM compras_proveedor c
      JOIN compra_items ci ON ci.compra_id = c.id
      WHERE c.organizacion_id = p_org
        AND c.proveedor_id = v_factura.proveedor_id
        AND UPPER(TRIM(COALESCE(c.estado, ''))) = 'RECIBIDA'
        AND c.fecha IS NOT NULL
        AND c.fecha::DATE >= (v_fecha_ref - 60)
        AND c.fecha::DATE <= (v_fecha_ref + 60)
        AND ci.material_id = ANY(v_productos_lote);

      IF v_folios_dup IS NOT NULL THEN
        RAISE EXCEPTION 'compra_ya_recibida: Existen compras recibidas del mismo proveedor en los últimos 60 días con estos productos (%); confirma que no es la misma mercancía',
          v_folios_dup;
      END IF;
    END IF;
  END IF;

  v_ref_factura := 'Factura ' || COALESCE(NULLIF(TRIM(v_factura.folio), ''), p_factura_id::TEXT);

  INSERT INTO almacen_recepciones (
    organizacion_id, factura_id, proveedor_id, compra_id, estado, notas, recibido_por
  ) VALUES (
    p_org, p_factura_id, v_factura.proveedor_id, v_factura.compra_id, 'recibida',
    NULLIF(TRIM(COALESCE(p_notas, '')), ''), p_usuario
  )
  RETURNING id INTO v_recepcion_id;

  FOR v_linea IN SELECT * FROM jsonb_array_elements(p_lineas)
  LOOP
    BEGIN
      v_partida_id := NULLIF(TRIM(COALESCE(v_linea->>'partida_id', '')), '')::UUID;
    EXCEPTION WHEN invalid_text_representation THEN
      RAISE EXCEPTION 'uuid_invalido: Identificador de partida inválido';
    END;

    v_producto_id := NULLIF(TRIM(COALESCE(v_linea->>'producto_id', '')), '');
    IF v_partida_id IS NULL OR v_producto_id IS NULL THEN
      RAISE EXCEPTION 'parametro_invalido: partida_id y producto_id son obligatorios';
    END IF;

    IF v_partida_id = ANY(v_partidas_vistas) THEN
      RAISE EXCEPTION 'partida_duplicada_en_lote: La partida % está repetida en el mismo lote de recepción', v_partida_id;
    END IF;
    v_partidas_vistas := array_append(v_partidas_vistas, v_partida_id);

    -- Validar partida de la factura y organización
    SELECT id, factura_id, organizacion_id, tipo, descripcion, cantidad, precio_unitario, importe, clave_sat, clave_unidad
    INTO v_partida
    FROM factura_proveedor_partidas
    WHERE id = v_partida_id AND factura_id = p_factura_id AND organizacion_id = p_org
    FOR UPDATE;

    IF NOT FOUND OR v_partida.tipo <> 'concepto' THEN
      RAISE EXCEPTION 'partida_no_encontrada: La partida % no pertenece como concepto a esta factura', v_partida_id;
    END IF;

    IF EXISTS (SELECT 1 FROM almacen_recepcion_lineas WHERE partida_id = v_partida_id AND activa = true) THEN
      RAISE EXCEPTION 'partida_ya_recibida: La partida "%" ya fue recibida en almacén', v_partida.descripcion;
    END IF;

    -- Validar producto de la organización y tipo = 'bien'
    SELECT id, nombre, tipo, stock_actual, ultimo_costo_compra_fecha
    INTO v_producto
    FROM productos
    WHERE id = v_producto_id AND organizacion_id = p_org;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'producto_no_encontrado: El producto seleccionado no pertenece a tu organización';
    END IF;

    IF LOWER(COALESCE(v_producto.tipo, '')) <> 'bien' THEN
      RAISE EXCEPTION 'producto_no_es_bien: El producto "%" es un servicio y no puede recibirse en inventario', v_producto.nombre;
    END IF;

    -- Validar factor de conversión (unidades de peso exigen factor explícito y confirmado)
    v_tiene_factor := (v_linea ? 'factor_conversion')
      AND NULLIF(TRIM(COALESCE(v_linea->>'factor_conversion', '')), '') IS NOT NULL;
    v_factor_confirmado := COALESCE((v_linea->>'factor_confirmado')::BOOLEAN, v_tiene_factor);

    IF UPPER(TRIM(COALESCE(v_partida.clave_unidad, ''))) IN ('KGM', 'GRM', 'TNE', 'LBR')
       AND (NOT v_tiene_factor OR NOT v_factor_confirmado) THEN
      RAISE EXCEPTION 'factor_requerido: La partida "%" está en unidad de peso (%) y requiere capturar un factor de conversión explícito',
        v_partida.descripcion, UPPER(TRIM(v_partida.clave_unidad));
    END IF;

    IF v_tiene_factor THEN
      BEGIN
        v_factor := (v_linea->>'factor_conversion')::NUMERIC;
      EXCEPTION WHEN OTHERS THEN
        RAISE EXCEPTION 'factor_invalido: El factor de conversión debe ser un número mayor a cero';
      END;
    ELSE
      v_factor := 1;
    END IF;
    IF v_factor <= 0 THEN
      RAISE EXCEPTION 'factor_invalido: El factor de conversión debe ser mayor a cero';
    END IF;

    IF COALESCE(v_partida.cantidad, 0) <= 0 OR COALESCE(v_partida.importe, 0) <= 0 THEN
      RAISE EXCEPTION 'precio_invalido: La partida "%" no tiene importe o cantidad positiva', v_partida.descripcion;
    END IF;

    v_cant_calculada := ROUND(v_partida.cantidad * v_factor, 4);
    IF (v_linea ? 'cantidad_recibida') AND NULLIF(TRIM(COALESCE(v_linea->>'cantidad_recibida', '')), '') IS NOT NULL THEN
      BEGIN
        v_cant_recibida := ROUND((v_linea->>'cantidad_recibida')::NUMERIC, 4);
      EXCEPTION WHEN OTHERS THEN
        RAISE EXCEPTION 'cantidad_invalida: La cantidad a recibir debe ser un número mayor a cero';
      END;
    ELSE
      v_cant_recibida := v_cant_calculada;
    END IF;
    IF v_cant_recibida IS NULL OR v_cant_recibida <= 0 THEN
      RAISE EXCEPTION 'cantidad_invalida: La cantidad a recibir debe ser mayor a cero';
    END IF;

    -- Recalcular costo unitario MXN sin IVA: importe / cantidad_xml * tipo_cambio / factor
    v_costo_unit := ROUND((v_partida.importe / v_partida.cantidad) * v_tc / v_factor, 4);
    IF v_costo_unit <= 0 THEN
      RAISE EXCEPTION 'precio_invalido: El costo unitario calculado para "%" debe ser mayor a cero', v_producto.nombre;
    END IF;

    -- Insertar movimiento de inventario Entrada
    INSERT INTO movimientos_inventario (
      organizacion_id, producto_id, tipo_movimiento, cantidad, referencia, usuario_id
    ) VALUES (
      p_org, v_producto_id, 'Entrada', v_cant_recibida, v_ref_factura, p_usuario
    )
    RETURNING id INTO v_mov_id;

    -- Sumar stock_actual atómicamente y actualizar último costo solo si la fecha es igual o posterior
    v_costo_actualizado := (
      v_producto.ultimo_costo_compra_fecha IS NULL
      OR v_factura.fecha_emision IS NULL
      OR v_factura.fecha_emision >= v_producto.ultimo_costo_compra_fecha
    );

    IF v_costo_actualizado THEN
      UPDATE productos
      SET stock_actual = COALESCE(stock_actual, 0) + v_cant_recibida,
          ultimo_costo_compra = v_costo_unit,
          ultimo_costo_compra_fecha = COALESCE(v_factura.fecha_emision, CURRENT_DATE),
          ultimo_costo_compra_factura_id = p_factura_id
      WHERE id = v_producto_id AND organizacion_id = p_org;
    ELSE
      UPDATE productos
      SET stock_actual = COALESCE(stock_actual, 0) + v_cant_recibida
      WHERE id = v_producto_id AND organizacion_id = p_org;
    END IF;

    v_nota_linea := NULLIF(TRIM(COALESCE(v_linea->>'notas', '')), '');
    INSERT INTO almacen_recepcion_lineas (
      organizacion_id, recepcion_id, partida_id, partida_id_original, producto_id,
      cantidad_xml, unidad_xml, factor_conversion, cantidad_recibida,
      costo_unitario_mxn, movimiento_id, costo_actualizado, activa, notas
    ) VALUES (
      p_org, v_recepcion_id, v_partida_id, v_partida_id, v_producto_id,
      v_partida.cantidad, v_partida.clave_unidad, v_factor, v_cant_recibida,
      v_costo_unit, v_mov_id, v_costo_actualizado, true, v_nota_linea
    );

    -- Guardar alias compartido (destino_tipo = 'producto') sin pisar alias de acero_material
    v_guardar_alias := COALESCE((v_linea->>'guardar_alias')::BOOLEAN, true);
    v_desc_norm := NULLIF(TRIM(COALESCE(v_linea->>'descripcion_normalizada', '')), '');
    IF v_guardar_alias AND v_factura.proveedor_id IS NOT NULL THEN
      IF v_desc_norm IS NULL THEN
        v_desc_norm := LOWER(TRIM(regexp_replace(v_partida.descripcion, '\s+', ' ', 'g')));
      END IF;

      SELECT id, destino_tipo INTO v_alias_existente
      FROM catalogo_alias_factura
      WHERE organizacion_id = p_org
        AND proveedor_id = v_factura.proveedor_id
        AND COALESCE(clave_sat, '') = COALESCE(v_partida.clave_sat, '')
        AND descripcion_normalizada = v_desc_norm;

      IF v_alias_existente.id IS NOT NULL THEN
        IF v_alias_existente.destino_tipo = 'producto' THEN
          UPDATE catalogo_alias_factura
          SET destino_id = v_producto_id,
              factor_conversion = v_factor,
              veces_confirmado = veces_confirmado + 1,
              ultima_confirmacion = NOW(),
              confirmado_por = p_usuario
          WHERE id = v_alias_existente.id;
        END IF;
      ELSE
        INSERT INTO catalogo_alias_factura (
          organizacion_id, proveedor_id, clave_sat, descripcion_normalizada,
          destino_tipo, destino_id, factor_conversion,
          veces_confirmado, ultima_confirmacion, confirmado_por
        ) VALUES (
          p_org, v_factura.proveedor_id, v_partida.clave_sat, v_desc_norm,
          'producto', v_producto_id, v_factor,
          1, NOW(), p_usuario
        );
      END IF;
    END IF;

    v_resultados := v_resultados || jsonb_build_array(
      jsonb_build_object(
        'partida_id', v_partida_id,
        'producto_id', v_producto_id,
        'producto_nombre', v_producto.nombre,
        'cantidad_recibida', v_cant_recibida,
        'costo_unitario_mxn', v_costo_unit,
        'costo_actualizado', v_costo_actualizado,
        'movimiento_id', v_mov_id
      )
    );
  END LOOP;

  RETURN jsonb_build_object(
    'ok', true,
    'recepcion_id', v_recepcion_id,
    'total_lineas', jsonb_array_length(v_resultados),
    'lineas', v_resultados
  );
END;
$$;

REVOKE ALL ON FUNCTION recibir_factura_almacen(UUID, UUID, UUID, JSONB, BOOLEAN, TEXT) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION recibir_factura_almacen(UUID, UUID, UUID, JSONB, BOOLEAN, TEXT) TO service_role;

-- 6. RPC atómica anular_recepcion_almacen (todo o nada, bloquea stock negativo)
CREATE OR REPLACE FUNCTION anular_recepcion_almacen(
  p_org UUID,
  p_usuario UUID,
  p_recepcion_id UUID,
  p_motivo TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_motivo TEXT := TRIM(COALESCE(p_motivo, ''));
  v_rec RECORD;
  v_folio TEXT;
  v_chk RECORD;
  v_lin RECORD;
  v_mov_id UUID;
  v_lineas_anuladas INTEGER := 0;
BEGIN
  IF p_org IS NULL THEN
    RAISE EXCEPTION 'org_requerida: Organización requerida';
  END IF;

  IF v_motivo = '' THEN
    RAISE EXCEPTION 'motivo_requerido: Debes capturar el motivo de la anulación';
  END IF;

  SELECT id, organizacion_id, factura_id, estado
  INTO v_rec
  FROM almacen_recepciones
  WHERE id = p_recepcion_id AND organizacion_id = p_org
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'recepcion_no_encontrada: La recepción no existe o pertenece a otra organización';
  END IF;

  IF v_rec.estado = 'anulada' THEN
    RAISE EXCEPTION 'recepcion_ya_anulada: Esta recepción ya fue anulada anteriormente';
  END IF;

  SELECT folio INTO v_folio FROM facturas_proveedor WHERE id = v_rec.factura_id;

  -- Bloquear productos involucrados en orden determinista
  PERFORM p.id
  FROM productos p
  WHERE p.organizacion_id = p_org
    AND p.id IN (
      SELECT DISTINCT l.producto_id
      FROM almacen_recepcion_lineas l
      WHERE l.recepcion_id = p_recepcion_id AND l.activa = true
    )
  ORDER BY p.id
  FOR UPDATE;

  -- Verificar que ningún producto quede con stock negativo (sumando líneas del mismo producto)
  FOR v_chk IN
    SELECT p.id, p.nombre, COALESCE(p.stock_actual, 0) AS stock_actual, SUM(l.cantidad_recibida) AS total_revertir
    FROM almacen_recepcion_lineas l
    JOIN productos p ON p.id = l.producto_id AND p.organizacion_id = p_org
    WHERE l.recepcion_id = p_recepcion_id AND l.activa = true
    GROUP BY p.id, p.nombre, p.stock_actual
    ORDER BY p.id
  LOOP
    IF v_chk.stock_actual < v_chk.total_revertir THEN
      RAISE EXCEPTION 'stock_insuficiente: No hay existencia suficiente de "%" para anular (actual: %, a revertir: %)',
        v_chk.nombre, v_chk.stock_actual, v_chk.total_revertir;
    END IF;
  END LOOP;

  -- Insertar movimientos contrarios, restar stock y desactivar líneas (liberando partidas)
  FOR v_lin IN
    SELECT id, producto_id, cantidad_recibida
    FROM almacen_recepcion_lineas
    WHERE recepcion_id = p_recepcion_id AND activa = true
    ORDER BY id
  LOOP
    INSERT INTO movimientos_inventario (
      organizacion_id, producto_id, tipo_movimiento, cantidad, referencia, usuario_id
    ) VALUES (
      p_org, v_lin.producto_id, 'Salida', v_lin.cantidad_recibida,
      'Anulación recepción Factura ' || COALESCE(NULLIF(TRIM(v_folio), ''), v_rec.factura_id::TEXT) || ' (' || LEFT(v_motivo, 120) || ')',
      p_usuario
    )
    RETURNING id INTO v_mov_id;

    UPDATE productos
    SET stock_actual = COALESCE(stock_actual, 0) - v_lin.cantidad_recibida
    WHERE id = v_lin.producto_id AND organizacion_id = p_org;

    UPDATE almacen_recepcion_lineas
    SET activa = false,
        partida_id_original = COALESCE(partida_id_original, partida_id),
        partida_id = NULL,
        movimiento_anulacion_id = v_mov_id
    WHERE id = v_lin.id;

    v_lineas_anuladas := v_lineas_anuladas + 1;
  END LOOP;

  UPDATE almacen_recepciones
  SET estado = 'anulada',
      anulada_el = NOW(),
      anulada_por = p_usuario,
      motivo_anulacion = v_motivo
  WHERE id = p_recepcion_id AND organizacion_id = p_org;

  RETURN jsonb_build_object(
    'ok', true,
    'recepcion_id', p_recepcion_id,
    'lineas_anuladas', v_lineas_anuladas
  );
END;
$$;

REVOKE ALL ON FUNCTION anular_recepcion_almacen(UUID, UUID, UUID, TEXT) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION anular_recepcion_almacen(UUID, UUID, UUID, TEXT) TO service_role;

-- 7. Redefinir recibir_compra_proveedor con guardián inverso de doble conteo (factura -> compra)
--    Elimina la firma de 3 argumentos para evitar sobrecarga ambigua en PostgREST;
--    el 4to parámetro tiene DEFAULT false para mantener compatibilidad con llamadas de 3 argumentos.
DROP FUNCTION IF EXISTS public.recibir_compra_proveedor(UUID, UUID, UUID);

CREATE OR REPLACE FUNCTION public.recibir_compra_proveedor(
  p_org UUID,
  p_usuario UUID,
  p_compra_id UUID,
  p_confirmo_doble BOOLEAN DEFAULT false
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_compra RECORD;
  v_item RECORD;
  v_missing_prod TEXT;
  v_columnas_enteras BOOLEAN := false;
  v_count_items INTEGER := 0;
  v_mov_id UUID;
  v_movimientos JSONB := '[]'::jsonb;
  v_ref TEXT;
  v_fecha_compra DATE;
  v_folios_dup TEXT;
BEGIN
  IF p_org IS NULL THEN
    RAISE EXCEPTION 'org_requerida: Organización requerida';
  END IF;

  IF p_compra_id IS NULL THEN
    RAISE EXCEPTION 'compra_no_encontrada: La compra no existe o pertenece a otra organización';
  END IF;

  -- Bloquear la compra dentro de la organización (serializa recepciones simultáneas)
  SELECT id, organizacion_id, folio, estado, cotizacion_id, proveedor_id, fecha
  INTO v_compra
  FROM compras_proveedor
  WHERE id = p_compra_id
    AND organizacion_id = p_org
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'compra_no_encontrada: La compra no existe o pertenece a otra organización';
  END IF;

  -- Idempotencia antes del chequeo de doble conteo
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

  SELECT COUNT(*) INTO v_count_items
  FROM compra_items
  WHERE compra_id = p_compra_id;

  IF v_count_items = 0 THEN
    RAISE EXCEPTION 'compra_sin_partidas: La compra no tiene partidas para recibir';
  END IF;

  -- Detectar dinámicamente si stock_actual o cantidad siguen siendo enteras
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

  -- Bloquear productos en orden determinista (mismo orden que recibir_factura_almacen)
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

  -- Guardián inverso de doble conteo DESPUÉS del bloqueo FOR UPDATE de productos:
  -- rechaza salvo p_confirmo_doble = true si ya existe recepción activa en almacén
  -- (a) ligada a esta compra, o (b) mismo proveedor + fecha +-60 días + producto en común.
  IF NOT COALESCE(p_confirmo_doble, false) THEN
    v_fecha_compra := COALESCE(v_compra.fecha::DATE, CURRENT_DATE);

    SELECT string_agg(DISTINCT folio_ref, ', ' ORDER BY folio_ref)
    INTO v_folios_dup
    FROM (
      SELECT COALESCE(NULLIF(TRIM(fp.folio), ''), fp.id::TEXT) AS folio_ref
      FROM almacen_recepciones ar
      JOIN facturas_proveedor fp
        ON fp.id = ar.factura_id
       AND fp.organizacion_id = p_org
      JOIN almacen_recepcion_lineas arl
        ON arl.recepcion_id = ar.id
       AND arl.organizacion_id = p_org
       AND arl.activa = true
      WHERE ar.organizacion_id = p_org
        AND ar.estado = 'recibida'
        AND (
          -- (a) Ligada directamente a esta compra
          ar.compra_id = p_compra_id
          OR fp.compra_id = p_compra_id
          -- (b) Mismo proveedor, fecha de factura a +-60 días y producto en común
          OR (
            v_compra.proveedor_id IS NOT NULL
            AND COALESCE(fp.proveedor_id, ar.proveedor_id) = v_compra.proveedor_id
            AND fp.fecha_emision IS NOT NULL
            AND fp.fecha_emision >= (v_fecha_compra - 60)
            AND fp.fecha_emision <= (v_fecha_compra + 60)
            AND arl.producto_id IN (
              SELECT DISTINCT ci2.material_id
              FROM compra_items ci2
              WHERE ci2.compra_id = p_compra_id
            )
          )
        )
    ) dup;

    IF v_folios_dup IS NOT NULL THEN
      RAISE EXCEPTION 'factura_ya_recibida: Esta mercancía ya fue recibida por factura en almacén (%). Confirma que no es la misma mercancía',
        v_folios_dup;
    END IF;
  END IF;

  v_ref := 'Compra ' || COALESCE(NULLIF(TRIM(v_compra.folio), ''), v_compra.id::TEXT);

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

REVOKE ALL ON FUNCTION public.recibir_compra_proveedor(UUID, UUID, UUID, BOOLEAN) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.recibir_compra_proveedor(UUID, UUID, UUID, BOOLEAN) TO service_role;

COMMIT;
