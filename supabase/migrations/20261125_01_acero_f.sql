-- Bloque F: Acero (XML de factura -> precios, alias compartidos con G, renombrar proveedor)
-- Migración aditiva e idempotente. No modifica precios existentes ni tablas de cotización.

BEGIN;

-- 1. Tabla compartida catalogo_alias_factura (F: acero_material, G: producto)
CREATE TABLE IF NOT EXISTS catalogo_alias_factura (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organizacion_id UUID NOT NULL REFERENCES organizaciones(id) ON DELETE CASCADE,
  proveedor_id UUID NOT NULL REFERENCES proveedores(id) ON DELETE CASCADE,
  clave_sat TEXT NULL,
  descripcion_normalizada TEXT NOT NULL,
  destino_tipo TEXT NOT NULL CHECK (destino_tipo IN ('acero_material', 'producto')),
  destino_id UUID NOT NULL,
  proveedor_acero TEXT NULL,
  factor_conversion NUMERIC(14, 6) NOT NULL DEFAULT 1 CHECK (factor_conversion > 0),
  veces_confirmado INTEGER NOT NULL DEFAULT 1 CHECK (veces_confirmado >= 1),
  ultima_confirmacion TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  confirmado_por UUID NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_catalogo_alias_factura_clave
  ON catalogo_alias_factura (organizacion_id, proveedor_id, COALESCE(clave_sat, ''), descripcion_normalizada);

CREATE INDEX IF NOT EXISTS idx_catalogo_alias_factura_org_tipo
  ON catalogo_alias_factura (organizacion_id, destino_tipo, proveedor_id);

ALTER TABLE catalogo_alias_factura ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "rls_catalogo_alias_factura_select" ON catalogo_alias_factura;
CREATE POLICY "rls_catalogo_alias_factura_select" ON catalogo_alias_factura
  FOR SELECT TO authenticated
  USING (organizacion_id = get_current_org_id());

GRANT SELECT ON catalogo_alias_factura TO authenticated;

-- 2. Tabla de partidas CFDI ya aplicadas a precios de acero (evita doble aplicación)
CREATE TABLE IF NOT EXISTS acero_precios_cfdi_aplicados (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organizacion_id UUID NOT NULL REFERENCES organizaciones(id) ON DELETE CASCADE,
  partida_id UUID NOT NULL REFERENCES factura_proveedor_partidas(id) ON DELETE CASCADE UNIQUE,
  material_id UUID NOT NULL REFERENCES acero_materiales(id) ON DELETE CASCADE,
  proveedor TEXT NOT NULL,
  precio_aplicado NUMERIC(14, 4) NOT NULL CHECK (precio_aplicado > 0),
  factura_id UUID NOT NULL REFERENCES facturas_proveedor(id) ON DELETE CASCADE,
  fecha_emision_factura DATE NULL,
  aplicado_el TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  usuario_id UUID NULL
);

CREATE INDEX IF NOT EXISTS idx_acero_cfdi_aplicados_org_mat_prov
  ON acero_precios_cfdi_aplicados (organizacion_id, material_id, proveedor, fecha_emision_factura DESC);

CREATE INDEX IF NOT EXISTS idx_acero_cfdi_aplicados_factura
  ON acero_precios_cfdi_aplicados (organizacion_id, factura_id);

ALTER TABLE acero_precios_cfdi_aplicados ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "rls_acero_precios_cfdi_aplicados_select" ON acero_precios_cfdi_aplicados;
CREATE POLICY "rls_acero_precios_cfdi_aplicados_select" ON acero_precios_cfdi_aplicados
  FOR SELECT TO authenticated
  USING (organizacion_id = get_current_org_id());

GRANT SELECT ON acero_precios_cfdi_aplicados TO authenticated;

-- 3. Extensión aditiva de acero_precios_historial
ALTER TABLE acero_precios_historial
  ADD COLUMN IF NOT EXISTS fuente TEXT,
  ADD COLUMN IF NOT EXISTS factura_id UUID NULL REFERENCES facturas_proveedor(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS incluye_iva BOOLEAN NULL;

-- 3b. Función pura de base común sin IVA (D1: una sola definición compartida por RPC)
CREATE OR REPLACE FUNCTION acero_precio_base_sin_iva(
  p_precio NUMERIC,
  p_incluye_iva BOOLEAN
)
RETURNS NUMERIC
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
  c_tasa_iva CONSTANT NUMERIC := 0.16;
BEGIN
  IF p_precio IS NULL THEN
    RETURN NULL;
  END IF;
  IF COALESCE(p_incluye_iva, true) THEN
    RETURN p_precio / (1 + c_tasa_iva);
  END IF;
  RETURN p_precio;
END;
$$;

-- 4. RPC atómica aplicar_precios_acero_cfdi (todo o nada)
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

    -- O2: Normalizar proveedor (recorte y mayúsculas) para evitar columnas duplicadas
    v_proveedor := UPPER(TRIM(COALESCE(v_linea->>'proveedor_acero', '')));
    IF v_proveedor = '' THEN
      RAISE EXCEPTION 'proveedor_requerido: El nombre del proveedor de acero es obligatorio';
    END IF;

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
      AND proveedor = v_proveedor;

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

    -- Guardar alias si aplica
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
            destino_id = v_material_id,
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
          'acero_material', v_material_id, v_proveedor, v_factor,
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

-- 5. RPC renombrar_proveedor_acero (sin fusión silenciosa)
CREATE OR REPLACE FUNCTION renombrar_proveedor_acero(
  p_org UUID,
  p_de TEXT,
  p_a TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_de TEXT := TRIM(COALESCE(p_de, ''));
  v_a TEXT := UPPER(TRIM(COALESCE(p_a, '')));
  v_conflictos TEXT;
  v_precios_upd INTEGER := 0;
  v_alias_upd INTEGER := 0;
  v_historial_upd INTEGER := 0;
  v_aplicados_upd INTEGER := 0;
BEGIN
  IF p_org IS NULL THEN
    RAISE EXCEPTION 'org_requerida: Organización requerida';
  END IF;

  IF v_de = '' OR v_a = '' THEN
    RAISE EXCEPTION 'proveedor_invalido: Debes indicar el proveedor origen y el nuevo nombre';
  END IF;

  IF v_de = v_a THEN
    RAISE EXCEPTION 'proveedor_invalido: El nuevo nombre debe ser diferente al actual';
  END IF;

  SELECT string_agg(m.nombre, ', ' ORDER BY m.nombre)
  INTO v_conflictos
  FROM acero_precios p1
  JOIN acero_precios p2
    ON p2.organizacion_id = p1.organizacion_id
    AND p2.material_id = p1.material_id
    AND p2.proveedor = v_a
  JOIN acero_materiales m
    ON m.id = p1.material_id
  WHERE p1.organizacion_id = p_org
    AND p1.proveedor = v_de;

  IF v_conflictos IS NOT NULL THEN
    RAISE EXCEPTION 'proveedor_conflicto: Ya existen precios para "%" en: %', v_a, v_conflictos;
  END IF;

  UPDATE acero_precios
  SET proveedor = v_a, updated_at = NOW()
  WHERE organizacion_id = p_org AND proveedor = v_de;
  GET DIAGNOSTICS v_precios_upd = ROW_COUNT;

  -- D2: Actualizar también historial y registro de partidas CFDI aplicadas
  UPDATE acero_precios_historial
  SET proveedor = v_a
  WHERE organizacion_id = p_org AND proveedor = v_de;
  GET DIAGNOSTICS v_historial_upd = ROW_COUNT;

  UPDATE acero_precios_cfdi_aplicados
  SET proveedor = v_a
  WHERE organizacion_id = p_org AND proveedor = v_de;
  GET DIAGNOSTICS v_aplicados_upd = ROW_COUNT;

  UPDATE catalogo_alias_factura
  SET proveedor_acero = v_a
  WHERE organizacion_id = p_org AND proveedor_acero = v_de;
  GET DIAGNOSTICS v_alias_upd = ROW_COUNT;

  RETURN jsonb_build_object(
    'ok', true,
    'de', v_de,
    'a', v_a,
    'precios_actualizados', v_precios_upd,
    'historial_actualizado', v_historial_upd,
    'aplicaciones_actualizadas', v_aplicados_upd,
    'alias_actualizados', v_alias_upd
  );
END;
$$;

REVOKE ALL ON FUNCTION renombrar_proveedor_acero(UUID, TEXT, TEXT) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION renombrar_proveedor_acero(UUID, TEXT, TEXT) TO service_role;

COMMIT;
