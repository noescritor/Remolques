-- Migración 20261028_01_lotes_precios.sql
-- Sub-bloque 2R-14: Actualización masiva de precios (Excel, porcentaje, lotes con reversión)

BEGIN;

-- 1. Tabla precios_lotes
CREATE TABLE IF NOT EXISTS precios_lotes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organizacion_id UUID NOT NULL REFERENCES organizaciones(id) ON DELETE CASCADE,
    usuario_id UUID,
    origen TEXT NOT NULL CHECK (origen IN ('excel', 'porcentaje', 'manual')),
    descripcion VARCHAR(200) NOT NULL,
    creado_el TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    total_cambios INT NOT NULL DEFAULT 0,
    revertido_el TIMESTAMPTZ,
    revertido_por UUID,
    lote_origen_id UUID REFERENCES precios_lotes(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    notas TEXT
);

ALTER TABLE precios_lotes ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "org_precios_lotes_policy" ON precios_lotes;
CREATE POLICY "org_precios_lotes_policy" ON precios_lotes FOR ALL USING (organizacion_id = get_current_org_id());

CREATE INDEX IF NOT EXISTS idx_precios_lotes_org ON precios_lotes(organizacion_id, creado_el DESC);
CREATE INDEX IF NOT EXISTS idx_precios_lotes_origen_id ON precios_lotes(lote_origen_id);

-- 2. Tabla precios_lotes_items
CREATE TABLE IF NOT EXISTS precios_lotes_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lote_id UUID NOT NULL REFERENCES precios_lotes(id) ON DELETE CASCADE,
    organizacion_id UUID NOT NULL REFERENCES organizaciones(id) ON DELETE CASCADE,
    fuente TEXT NOT NULL CHECK (fuente IN ('productos', 'opcion_costos', 'costos_modelo', 'acero_precios')),
    registro_id UUID NOT NULL,
    descripcion TEXT NOT NULL,
    precio_anterior NUMERIC(14,4) NOT NULL,
    precio_nuevo NUMERIC(14,4) NOT NULL,
    incluye_iva BOOLEAN,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    notas TEXT
);

ALTER TABLE precios_lotes_items ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "org_precios_lotes_items_policy" ON precios_lotes_items;
CREATE POLICY "org_precios_lotes_items_policy" ON precios_lotes_items FOR ALL USING (organizacion_id = get_current_org_id());

CREATE INDEX IF NOT EXISTS idx_precios_lotes_items_lote ON precios_lotes_items(lote_id);
CREATE INDEX IF NOT EXISTS idx_precios_lotes_items_org ON precios_lotes_items(organizacion_id);
CREATE INDEX IF NOT EXISTS idx_precios_lotes_items_reg ON precios_lotes_items(registro_id);

-- 3. Función SQL aplicar_lote_precios
CREATE OR REPLACE FUNCTION aplicar_lote_precios(
    p_org UUID,
    p_usuario UUID,
    p_origen TEXT,
    p_descripcion TEXT,
    p_cambios JSONB
) RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
    r_item JSONB;
    v_fuente TEXT;
    v_id TEXT;
    v_id_uuid UUID;
    v_precio_nuevo NUMERIC(14,4);
    v_precio_visto NUMERIC(14,4);
    v_costo_actual NUMERIC(14,4);
    v_desc TEXT;
    v_mat_id UUID;
    v_proveedor TEXT;
    v_incluye_iva BOOLEAN;
    v_conflictos JSONB := '[]'::jsonb;
    v_aplicados INT := 0;
    v_omitidos INT := 0;
    v_lote_id UUID;
    v_items_validos JSONB := '[]'::jsonb;
BEGIN
    IF p_origen NOT IN ('excel', 'porcentaje', 'manual') THEN
        RETURN jsonb_build_object('exito', false, 'error', 'origen_invalido', 'mensaje', 'Origen inválido: ' || coalesce(p_origen, 'null'));
    END IF;

    IF jsonb_typeof(p_cambios) <> 'array' THEN
        RETURN jsonb_build_object('exito', false, 'error', 'formato_invalido', 'mensaje', 'p_cambios debe ser un arreglo JSON');
    END IF;

    -- FASE 1: Validación completa de todos los registros y detección de conflictos
    FOR r_item IN SELECT * FROM jsonb_array_elements(p_cambios) LOOP
        v_fuente := r_item->>'fuente';
        v_id := r_item->>'id';
        v_precio_nuevo := (r_item->>'precio_nuevo')::numeric;
        v_precio_visto := NULL;
        IF (r_item->>'precio_anterior_visto') IS NOT NULL AND (r_item->>'precio_anterior_visto') <> '' THEN
            v_precio_visto := (r_item->>'precio_anterior_visto')::numeric;
        END IF;

        IF v_id IS NULL OR v_id = '' THEN
            v_conflictos := v_conflictos || jsonb_build_object('id', v_id, 'fuente', v_fuente, 'motivo', 'ID no proporcionado');
            CONTINUE;
        END IF;

        IF v_precio_nuevo IS NULL OR v_precio_nuevo < 0 THEN
            v_conflictos := v_conflictos || jsonb_build_object('id', v_id, 'fuente', v_fuente, 'motivo', 'Precio nuevo inválido o negativo');
            CONTINUE;
        END IF;

        v_costo_actual := NULL;
        v_desc := NULL;
        v_mat_id := NULL;
        v_proveedor := NULL;
        v_incluye_iva := NULL;

        IF v_fuente = 'productos' THEN
            SELECT p.costo, (p.nombre || coalesce(' (' || p.unidad || ')', ''))
            INTO v_costo_actual, v_desc
            FROM productos p
            WHERE p.id = v_id AND p.organizacion_id = p_org;

            IF v_desc IS NULL THEN
                v_conflictos := v_conflictos || jsonb_build_object('id', v_id, 'fuente', v_fuente, 'motivo', 'Producto no encontrado o de otra organización');
                CONTINUE;
            END IF;

        ELSIF v_fuente = 'opcion_costos' THEN
            BEGIN
                v_id_uuid := v_id::uuid;
            EXCEPTION WHEN OTHERS THEN
                v_conflictos := v_conflictos || jsonb_build_object('id', v_id, 'fuente', v_fuente, 'motivo', 'UUID inválido');
                CONTINUE;
            END;

            SELECT oc.costo_unitario, (g.nombre || ' / ' || o.nombre || ' (' || oc.tipo_modelo || ')')
            INTO v_costo_actual, v_desc
            FROM opcion_costos oc
            JOIN opciones_configuracion o ON o.id = oc.opcion_id
            JOIN grupos_configuracion g ON g.id = o.grupo_id
            WHERE oc.id = v_id_uuid AND oc.organizacion_id = p_org;

            IF v_desc IS NULL THEN
                v_conflictos := v_conflictos || jsonb_build_object('id', v_id, 'fuente', v_fuente, 'motivo', 'Opción de costo no encontrada o de otra organización');
                CONTINUE;
            END IF;

        ELSIF v_fuente = 'costos_modelo' THEN
            BEGIN
                v_id_uuid := v_id::uuid;
            EXCEPTION WHEN OTHERS THEN
                v_conflictos := v_conflictos || jsonb_build_object('id', v_id, 'fuente', v_fuente, 'motivo', 'UUID inválido');
                CONTINUE;
            END;

            SELECT cm.costo_unitario, (pm.nombre || ' / ' || cm.seccion || ' / ' || cm.concepto)
            INTO v_costo_actual, v_desc
            FROM costos_modelo cm
            JOIN modelos m ON m.id = cm.modelo_id
            JOIN productos pm ON pm.id = m.producto_id
            WHERE cm.id = v_id_uuid AND cm.organizacion_id = p_org;

            IF v_desc IS NULL THEN
                v_conflictos := v_conflictos || jsonb_build_object('id', v_id, 'fuente', v_fuente, 'motivo', 'Costo de modelo no encontrado o de otra organización');
                CONTINUE;
            END IF;

        ELSIF v_fuente = 'acero_precios' THEN
            BEGIN
                v_id_uuid := v_id::uuid;
            EXCEPTION WHEN OTHERS THEN
                v_conflictos := v_conflictos || jsonb_build_object('id', v_id, 'fuente', v_fuente, 'motivo', 'UUID inválido');
                CONTINUE;
            END;

            SELECT ap.precio, ap.material_id, ap.proveedor, ap.incluye_iva, (am.nombre || ' (' || ap.proveedor || ')')
            INTO v_costo_actual, v_mat_id, v_proveedor, v_incluye_iva, v_desc
            FROM acero_precios ap
            JOIN acero_materiales am ON am.id = ap.material_id
            WHERE ap.id = v_id_uuid AND ap.organizacion_id = p_org;

            IF v_desc IS NULL THEN
                v_conflictos := v_conflictos || jsonb_build_object('id', v_id, 'fuente', v_fuente, 'motivo', 'Precio de acero no encontrado o de otra organización');
                CONTINUE;
            END IF;

        ELSE
            v_conflictos := v_conflictos || jsonb_build_object('id', v_id, 'fuente', v_fuente, 'motivo', 'Fuente no reconocida: ' || coalesce(v_fuente, 'null'));
            CONTINUE;
        END IF;

        -- Comparar precio_anterior_visto si fue provisto
        IF v_precio_visto IS NOT NULL THEN
            IF abs(coalesce(v_costo_actual, 0) - v_precio_visto) > 0.0001 THEN
                v_conflictos := v_conflictos || jsonb_build_object(
                    'id', v_id,
                    'fuente', v_fuente,
                    'descripcion', v_desc,
                    'precio_esperado', v_precio_visto,
                    'precio_actual', v_costo_actual,
                    'motivo', 'El precio actual ha cambiado respecto al visto por el cliente'
                );
                CONTINUE;
            END IF;
        END IF;

        -- Evaluar si hay cambio real
        IF v_costo_actual IS NOT NULL AND abs(v_costo_actual - v_precio_nuevo) < 0.0001 THEN
            v_omitidos := v_omitidos + 1;
        ELSE
            v_aplicados := v_aplicados + 1;
            v_items_validos := v_items_validos || jsonb_build_object(
                'id', v_id,
                'fuente', v_fuente,
                'descripcion', v_desc,
                'costo_actual', coalesce(v_costo_actual, 0),
                'precio_nuevo', v_precio_nuevo,
                'mat_id', v_mat_id,
                'proveedor', v_proveedor,
                'incluye_iva', v_incluye_iva
            );
        END IF;
    END LOOP;

    -- Si hubo algún conflicto, abortar sin modificar nada
    IF jsonb_array_length(v_conflictos) > 0 THEN
        RETURN jsonb_build_object(
            'exito', false,
            'error', 'conflicto',
            'mensaje', 'Se detectaron conflictos de concurrencia o registros inválidos',
            'conflictos', v_conflictos
        );
    END IF;

    -- FASE 2: Aplicación atómica de cambios
    INSERT INTO precios_lotes (
        organizacion_id,
        usuario_id,
        origen,
        descripcion,
        total_cambios,
        notas
    ) VALUES (
        p_org,
        p_usuario,
        p_origen,
        p_descripcion,
        v_aplicados,
        'import-2r14'
    ) RETURNING id INTO v_lote_id;

    FOR r_item IN SELECT * FROM jsonb_array_elements(v_items_validos) LOOP
        v_fuente := r_item->>'fuente';
        v_id := r_item->>'id';
        v_desc := r_item->>'descripcion';
        v_costo_actual := (r_item->>'costo_actual')::numeric;
        v_precio_nuevo := (r_item->>'precio_nuevo')::numeric;

        IF v_fuente = 'productos' THEN
            UPDATE productos
            SET costo = v_precio_nuevo, updated_at = NOW()
            WHERE id = v_id AND organizacion_id = p_org;

            INSERT INTO precios_lotes_items (
                lote_id, organizacion_id, fuente, registro_id, descripcion,
                precio_anterior, precio_nuevo, incluye_iva, notas
            ) VALUES (
                v_lote_id, p_org, 'productos', v_id::uuid, v_desc,
                v_costo_actual, v_precio_nuevo, NULL, 'import-2r14'
            );

        ELSIF v_fuente = 'opcion_costos' THEN
            UPDATE opcion_costos
            SET costo_unitario = v_precio_nuevo, updated_at = NOW()
            WHERE id = v_id::uuid AND organizacion_id = p_org;

            INSERT INTO costos_historial (
                organizacion_id, tabla, registro_id, concepto, campo,
                valor_anterior, valor_nuevo, usuario_id, creado_en
            ) VALUES (
                p_org, 'opcion_costos', v_id, v_desc, 'costo_unitario',
                v_costo_actual::text, v_precio_nuevo::text, p_usuario, NOW()
            );

            INSERT INTO precios_lotes_items (
                lote_id, organizacion_id, fuente, registro_id, descripcion,
                precio_anterior, precio_nuevo, incluye_iva, notas
            ) VALUES (
                v_lote_id, p_org, 'opcion_costos', v_id::uuid, v_desc,
                v_costo_actual, v_precio_nuevo, NULL, 'import-2r14'
            );

        ELSIF v_fuente = 'costos_modelo' THEN
            UPDATE costos_modelo
            SET costo_unitario = v_precio_nuevo, updated_at = NOW()
            WHERE id = v_id::uuid AND organizacion_id = p_org;

            INSERT INTO costos_historial (
                organizacion_id, tabla, registro_id, concepto, campo,
                valor_anterior, valor_nuevo, usuario_id, creado_en
            ) VALUES (
                p_org, 'costos_modelo', v_id, v_desc, 'costo_unitario',
                v_costo_actual::text, v_precio_nuevo::text, p_usuario, NOW()
            );

            INSERT INTO precios_lotes_items (
                lote_id, organizacion_id, fuente, registro_id, descripcion,
                precio_anterior, precio_nuevo, incluye_iva, notas
            ) VALUES (
                v_lote_id, p_org, 'costos_modelo', v_id::uuid, v_desc,
                v_costo_actual, v_precio_nuevo, NULL, 'import-2r14'
            );

        ELSIF v_fuente = 'acero_precios' THEN
            UPDATE acero_precios
            SET precio = v_precio_nuevo, actualizado_el = NOW(), updated_at = NOW()
            WHERE id = v_id::uuid AND organizacion_id = p_org;

            INSERT INTO acero_precios_historial (
                organizacion_id, material_id, proveedor,
                precio_anterior, precio_nuevo, usuario_id, creado_el
            ) VALUES (
                p_org, (r_item->>'mat_id')::uuid, (r_item->>'proveedor'),
                v_costo_actual, v_precio_nuevo, p_usuario, NOW()
            );

            INSERT INTO precios_lotes_items (
                lote_id, organizacion_id, fuente, registro_id, descripcion,
                precio_anterior, precio_nuevo, incluye_iva, notas
            ) VALUES (
                v_lote_id, p_org, 'acero_precios', v_id::uuid, v_desc,
                v_costo_actual, v_precio_nuevo, (r_item->>'incluye_iva')::boolean, 'import-2r14'
            );
        END IF;
    END LOOP;

    RETURN jsonb_build_object(
        'exito', true,
        'lote_id', v_lote_id,
        'aplicados', v_aplicados,
        'omitidos_sin_cambio', v_omitidos
    );
END;
$$;

-- 4. Función SQL revertir_lote_precios
CREATE OR REPLACE FUNCTION revertir_lote_precios(
    p_org UUID,
    p_usuario UUID,
    p_lote_id UUID
) RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
    r_lote RECORD;
    r_item RECORD;
    v_costo_actual NUMERIC(14,4);
    v_nuevo_lote_id UUID;
    v_revertidos INT := 0;
    v_omitidos INT := 0;
    v_detalles_omitidos JSONB := '[]'::jsonb;
    v_desc_rev TEXT;
    v_mat_id UUID;
    v_proveedor TEXT;
BEGIN
    SELECT * INTO r_lote
    FROM precios_lotes
    WHERE id = p_lote_id AND organizacion_id = p_org;

    IF r_lote.id IS NULL THEN
        RETURN jsonb_build_object('exito', false, 'error', 'not_found', 'mensaje', 'Lote no encontrado');
    END IF;

    IF r_lote.revertido_el IS NOT NULL THEN
        RETURN jsonb_build_object('exito', false, 'error', 'ya_revertido', 'mensaje', 'El lote ya fue revertido el ' || r_lote.revertido_el::text);
    END IF;

    v_desc_rev := 'Reversión de: ' || coalesce(r_lote.descripcion, 'lote ' || p_lote_id::text);
    IF length(v_desc_rev) > 200 THEN
        v_desc_rev := substring(v_desc_rev from 1 for 197) || '...';
    END IF;

    -- Crear nuevo lote de reversión
    INSERT INTO precios_lotes (
        organizacion_id,
        usuario_id,
        origen,
        descripcion,
        total_cambios,
        lote_origen_id,
        notas
    ) VALUES (
        p_org,
        p_usuario,
        'manual',
        v_desc_rev,
        0,
        p_lote_id,
        'import-2r14'
    ) RETURNING id INTO v_nuevo_lote_id;

    -- Iterar items del lote original
    FOR r_item IN
        SELECT *
        FROM precios_lotes_items
        WHERE lote_id = p_lote_id AND organizacion_id = p_org
    LOOP
        v_costo_actual := NULL;

        IF r_item.fuente = 'productos' THEN
            SELECT p.costo INTO v_costo_actual
            FROM productos p
            WHERE p.id = r_item.registro_id::text AND p.organizacion_id = p_org;

            -- Solo restaurar si el costo sigue siendo el precio_nuevo del lote
            IF v_costo_actual IS NOT NULL AND abs(v_costo_actual - r_item.precio_nuevo) < 0.0001 THEN
                UPDATE productos
                SET costo = r_item.precio_anterior, updated_at = NOW()
                WHERE id = r_item.registro_id::text AND organizacion_id = p_org;

                INSERT INTO precios_lotes_items (
                    lote_id, organizacion_id, fuente, registro_id, descripcion,
                    precio_anterior, precio_nuevo, incluye_iva, notas
                ) VALUES (
                    v_nuevo_lote_id, p_org, 'productos', r_item.registro_id, r_item.descripcion,
                    r_item.precio_nuevo, r_item.precio_anterior, NULL, 'import-2r14'
                );

                v_revertidos := v_revertidos + 1;
            ELSE
                v_omitidos := v_omitidos + 1;
                v_detalles_omitidos := v_detalles_omitidos || jsonb_build_object(
                    'id', r_item.registro_id,
                    'descripcion', r_item.descripcion,
                    'precio_esperado', r_item.precio_nuevo,
                    'precio_actual', v_costo_actual,
                    'motivo', 'Modificado posteriormente'
                );
            END IF;

        ELSIF r_item.fuente = 'opcion_costos' THEN
            SELECT oc.costo_unitario INTO v_costo_actual
            FROM opcion_costos oc
            WHERE oc.id = r_item.registro_id AND oc.organizacion_id = p_org;

            IF v_costo_actual IS NOT NULL AND abs(v_costo_actual - r_item.precio_nuevo) < 0.0001 THEN
                UPDATE opcion_costos
                SET costo_unitario = r_item.precio_anterior, updated_at = NOW()
                WHERE id = r_item.registro_id AND organizacion_id = p_org;

                INSERT INTO costos_historial (
                    organizacion_id, tabla, registro_id, concepto, campo,
                    valor_anterior, valor_nuevo, usuario_id, creado_en
                ) VALUES (
                    p_org, 'opcion_costos', r_item.registro_id::text, r_item.descripcion, 'costo_unitario',
                    r_item.precio_nuevo::text, r_item.precio_anterior::text, p_usuario, NOW()
                );

                INSERT INTO precios_lotes_items (
                    lote_id, organizacion_id, fuente, registro_id, descripcion,
                    precio_anterior, precio_nuevo, incluye_iva, notas
                ) VALUES (
                    v_nuevo_lote_id, p_org, 'opcion_costos', r_item.registro_id, r_item.descripcion,
                    r_item.precio_nuevo, r_item.precio_anterior, NULL, 'import-2r14'
                );

                v_revertidos := v_revertidos + 1;
            ELSE
                v_omitidos := v_omitidos + 1;
                v_detalles_omitidos := v_detalles_omitidos || jsonb_build_object(
                    'id', r_item.registro_id,
                    'descripcion', r_item.descripcion,
                    'precio_esperado', r_item.precio_nuevo,
                    'precio_actual', v_costo_actual,
                    'motivo', 'Modificado posteriormente'
                );
            END IF;

        ELSIF r_item.fuente = 'costos_modelo' THEN
            SELECT cm.costo_unitario INTO v_costo_actual
            FROM costos_modelo cm
            WHERE cm.id = r_item.registro_id AND cm.organizacion_id = p_org;

            IF v_costo_actual IS NOT NULL AND abs(v_costo_actual - r_item.precio_nuevo) < 0.0001 THEN
                UPDATE costos_modelo
                SET costo_unitario = r_item.precio_anterior, updated_at = NOW()
                WHERE id = r_item.registro_id AND organizacion_id = p_org;

                INSERT INTO costos_historial (
                    organizacion_id, tabla, registro_id, concepto, campo,
                    valor_anterior, valor_nuevo, usuario_id, creado_en
                ) VALUES (
                    p_org, 'costos_modelo', r_item.registro_id::text, r_item.descripcion, 'costo_unitario',
                    r_item.precio_nuevo::text, r_item.precio_anterior::text, p_usuario, NOW()
                );

                INSERT INTO precios_lotes_items (
                    lote_id, organizacion_id, fuente, registro_id, descripcion,
                    precio_anterior, precio_nuevo, incluye_iva, notas
                ) VALUES (
                    v_nuevo_lote_id, p_org, 'costos_modelo', r_item.registro_id, r_item.descripcion,
                    r_item.precio_nuevo, r_item.precio_anterior, NULL, 'import-2r14'
                );

                v_revertidos := v_revertidos + 1;
            ELSE
                v_omitidos := v_omitidos + 1;
                v_detalles_omitidos := v_detalles_omitidos || jsonb_build_object(
                    'id', r_item.registro_id,
                    'descripcion', r_item.descripcion,
                    'precio_esperado', r_item.precio_nuevo,
                    'precio_actual', v_costo_actual,
                    'motivo', 'Modificado posteriormente'
                );
            END IF;

        ELSIF r_item.fuente = 'acero_precios' THEN
            SELECT ap.precio, ap.material_id, ap.proveedor
            INTO v_costo_actual, v_mat_id, v_proveedor
            FROM acero_precios ap
            WHERE ap.id = r_item.registro_id AND ap.organizacion_id = p_org;

            IF v_costo_actual IS NOT NULL AND abs(v_costo_actual - r_item.precio_nuevo) < 0.0001 THEN
                UPDATE acero_precios
                SET precio = r_item.precio_anterior, actualizado_el = NOW(), updated_at = NOW()
                WHERE id = r_item.registro_id AND organizacion_id = p_org;

                INSERT INTO acero_precios_historial (
                    organizacion_id, material_id, proveedor,
                    precio_anterior, precio_nuevo, usuario_id, creado_el
                ) VALUES (
                    p_org, v_mat_id, v_proveedor,
                    r_item.precio_nuevo, r_item.precio_anterior, p_usuario, NOW()
                );

                INSERT INTO precios_lotes_items (
                    lote_id, organizacion_id, fuente, registro_id, descripcion,
                    precio_anterior, precio_nuevo, incluye_iva, notas
                ) VALUES (
                    v_nuevo_lote_id, p_org, 'acero_precios', r_item.registro_id, r_item.descripcion,
                    r_item.precio_nuevo, r_item.precio_anterior, r_item.incluye_iva, 'import-2r14'
                );

                v_revertidos := v_revertidos + 1;
            ELSE
                v_omitidos := v_omitidos + 1;
                v_detalles_omitidos := v_detalles_omitidos || jsonb_build_object(
                    'id', r_item.registro_id,
                    'descripcion', r_item.descripcion,
                    'precio_esperado', r_item.precio_nuevo,
                    'precio_actual', v_costo_actual,
                    'motivo', 'Modificado posteriormente'
                );
            END IF;
        END IF;
    END LOOP;

    -- Actualizar total_cambios del nuevo lote
    UPDATE precios_lotes
    SET total_cambios = v_revertidos, updated_at = NOW()
    WHERE id = v_nuevo_lote_id;

    -- Marcar lote original como revertido
    UPDATE precios_lotes
    SET revertido_el = NOW(), revertido_por = p_usuario, updated_at = NOW()
    WHERE id = p_lote_id;

    RETURN jsonb_build_object(
        'exito', true,
        'lote_id', v_nuevo_lote_id,
        'revertidos', v_revertidos,
        'omitidos_editados_posteriormente', v_omitidos,
        'detalles_omitidos', v_detalles_omitidos
    );
END;
$$;

-- 5. Restricción estricta de permisos EXECUTE (SECURITY DEFINER exclusivo para service_role)
REVOKE ALL ON FUNCTION aplicar_lote_precios(uuid, uuid, text, text, jsonb) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION revertir_lote_precios(uuid, uuid, uuid) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION aplicar_lote_precios(uuid, uuid, text, text, jsonb) TO service_role;
GRANT EXECUTE ON FUNCTION revertir_lote_precios(uuid, uuid, uuid) TO service_role;
ALTER FUNCTION aplicar_lote_precios(uuid, uuid, text, text, jsonb) SET search_path = public;
ALTER FUNCTION revertir_lote_precios(uuid, uuid, uuid) SET search_path = public;

COMMIT;
