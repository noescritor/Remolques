-- Migración 20261102_04_editor_recetas.sql
-- Sub-bloque T6: Editor de recetas creadas por el usuario y clonación de modelos
-- Idempotente, transaccional y compatible con RLS multi-tenant

BEGIN;

-- 1. Tabla de Historial y Auditoría de Modificaciones de Receta
CREATE TABLE IF NOT EXISTS public.receta_base_historial (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organizacion_id UUID NOT NULL REFERENCES public.organizaciones(id) ON DELETE CASCADE,
    modelo_id UUID NOT NULL REFERENCES public.modelos(id) ON DELETE CASCADE,
    linea_id UUID,
    accion TEXT NOT NULL CHECK (accion IN ('clonar_modelo', 'crear_linea', 'modificar_linea', 'eliminar_linea')),
    material_id TEXT REFERENCES public.productos(id) ON DELETE SET NULL,
    fase_id UUID REFERENCES public.fases_despiece(id) ON DELETE SET NULL,
    datos_anteriores JSONB,
    datos_nuevos JSONB,
    usuario_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    motivo TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.receta_base_historial ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "receta_historial_org_select" ON public.receta_base_historial;
CREATE POLICY "receta_historial_org_select" ON public.receta_base_historial
    FOR SELECT TO authenticated
    USING (organizacion_id = (SELECT organizacion_id FROM public.usuarios WHERE id = auth.uid()));

DROP POLICY IF EXISTS "receta_historial_org_all" ON public.receta_base_historial;
CREATE POLICY "receta_historial_org_all" ON public.receta_base_historial
    FOR ALL TO authenticated
    USING (organizacion_id = (SELECT organizacion_id FROM public.usuarios WHERE id = auth.uid()))
    WITH CHECK (organizacion_id = (SELECT organizacion_id FROM public.usuarios WHERE id = auth.uid()));

CREATE INDEX IF NOT EXISTS idx_receta_hist_modelo ON public.receta_base_historial(modelo_id);
CREATE INDEX IF NOT EXISTS idx_receta_hist_org ON public.receta_base_historial(organizacion_id);

-- 2. Función Atómica: Clonar Receta a un Nuevo Modelo
CREATE OR REPLACE FUNCTION public.clonar_receta_modelo(
    p_modelo_origen_id UUID,
    p_producto_id TEXT,
    p_nombre TEXT,
    p_largo_ft NUMERIC,
    p_num_ejes INT,
    p_usuario_id UUID DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_org_id UUID;
    v_tipo TEXT;
    v_nuevo_modelo_id UUID;
    v_count_lineas INT := 0;
BEGIN
    -- Validar modelo origen y obtener organización y tipo
    SELECT organizacion_id, tipo INTO v_org_id, v_tipo
    FROM public.modelos
    WHERE id = p_modelo_origen_id;

    IF v_org_id IS NULL THEN
        RAISE EXCEPTION 'modelo_origen_no_encontrado: El modelo especificado no existe';
    END IF;

    -- Validar que no exista ya el producto_id en la organización
    IF EXISTS (SELECT 1 FROM public.productos WHERE id = p_producto_id AND organizacion_id = v_org_id) THEN
        RAISE EXCEPTION 'producto_id_duplicado: La clave % ya existe en el catálogo', p_producto_id;
    END IF;

    -- 1. Insertar en productos (tipo producto_terminado)
    INSERT INTO public.productos (
        id,
        organizacion_id,
        nombre,
        tipo_item,
        activo,
        unidad,
        costo
    ) VALUES (
        p_producto_id,
        v_org_id,
        p_nombre,
        'producto_terminado',
        true,
        'PZA',
        0
    );

    -- 2. Insertar en modelos derivado del origen
    INSERT INTO public.modelos (
        organizacion_id,
        producto_id,
        tipo,
        largo_ft,
        num_ejes,
        costos_derivados_de,
        activo
    ) VALUES (
        v_org_id,
        p_producto_id,
        v_tipo,
        p_largo_ft,
        p_num_ejes,
        p_modelo_origen_id,
        true
    ) RETURNING id INTO v_nuevo_modelo_id;

    -- 3. Clonar filas de receta_base
    INSERT INTO public.receta_base (
        modelo_id,
        material_id,
        cantidad,
        escala,
        paso,
        uso,
        seccion,
        condicion,
        notas,
        fase_id
    )
    SELECT
        v_nuevo_modelo_id,
        material_id,
        cantidad,
        escala,
        paso,
        uso,
        seccion,
        condicion,
        notas,
        fase_id
    FROM public.receta_base
    WHERE modelo_id = p_modelo_origen_id;

    GET DIAGNOSTICS v_count_lineas = ROW_COUNT;

    -- 4. Clonar costos_modelo y procesos_manufactura
    INSERT INTO public.costos_modelo (
        modelo_id,
        seccion,
        concepto,
        cantidad,
        costo_unitario,
        escala
    )
    SELECT
        v_nuevo_modelo_id,
        seccion,
        concepto,
        cantidad,
        costo_unitario,
        escala
    FROM public.costos_modelo
    WHERE modelo_id = p_modelo_origen_id;

    INSERT INTO public.procesos_manufactura (
        modelo_id,
        orden,
        proceso,
        subproceso,
        minutos,
        tarifa_hora
    )
    SELECT
        v_nuevo_modelo_id,
        orden,
        proceso,
        subproceso,
        minutos,
        tarifa_hora
    FROM public.procesos_manufactura
    WHERE modelo_id = p_modelo_origen_id;

    -- 5. Registrar en auditoría
    INSERT INTO public.receta_base_historial (
        organizacion_id,
        modelo_id,
        accion,
        datos_nuevos,
        usuario_id,
        motivo
    ) VALUES (
        v_org_id,
        v_nuevo_modelo_id,
        'clonar_modelo',
        jsonb_build_object(
            'modelo_origen_id', p_modelo_origen_id,
            'producto_id', p_producto_id,
            'nombre', p_nombre,
            'largo_ft', p_largo_ft,
            'num_ejes', p_num_ejes,
            'lineas_clonadas', v_count_lineas
        ),
        p_usuario_id,
        'Clonación de receta base a nuevo modelo'
    );

    RETURN v_nuevo_modelo_id;
END;
$$;

-- Permisos de la función de clonación
REVOKE ALL ON FUNCTION public.clonar_receta_modelo(UUID, TEXT, TEXT, NUMERIC, INT, UUID) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.clonar_receta_modelo(UUID, TEXT, TEXT, NUMERIC, INT, UUID) TO service_role;

-- 3. Función Atómica: Guardar o Modificar Línea de Receta
CREATE OR REPLACE FUNCTION public.guardar_linea_receta(
    p_modelo_id UUID,
    p_material_id TEXT,
    p_cantidad NUMERIC,
    p_escala TEXT,
    p_fase_id UUID,
    p_paso TEXT DEFAULT NULL,
    p_uso TEXT DEFAULT NULL,
    p_seccion TEXT DEFAULT 'ensamble',
    p_linea_id UUID DEFAULT NULL,
    p_usuario_id UUID DEFAULT NULL,
    p_motivo TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_org_id UUID;
    v_res_linea_id UUID;
    v_ant_data JSONB := NULL;
    v_accion TEXT;
BEGIN
    -- Validar modelo y organización
    SELECT organizacion_id INTO v_org_id FROM public.modelos WHERE id = p_modelo_id;
    IF v_org_id IS NULL THEN
        RAISE EXCEPTION 'modelo_no_encontrado: El modelo especificado no existe';
    END IF;

    -- Validar que el material exista en la misma organización
    IF NOT EXISTS (SELECT 1 FROM public.productos WHERE id = p_material_id AND organizacion_id = v_org_id) THEN
        RAISE EXCEPTION 'material_no_encontrado: La materia prima % no existe en la organización', p_material_id;
    END IF;

    -- Validar escala
    IF p_escala NOT IN ('fija', 'por_eje', 'por_largo') THEN
        RAISE EXCEPTION 'escala_invalida: La escala debe ser fija, por_eje o por_largo';
    END IF;

    IF p_cantidad <= 0 THEN
        RAISE EXCEPTION 'cantidad_invalida: La cantidad debe ser mayor a cero';
    END IF;

    IF p_linea_id IS NULL THEN
        -- Inserción
        v_accion := 'crear_linea';
        INSERT INTO public.receta_base (
            modelo_id,
            material_id,
            cantidad,
            escala,
            paso,
            uso,
            seccion,
            fase_id
        ) VALUES (
            p_modelo_id,
            p_material_id,
            p_cantidad,
            p_escala,
            p_paso,
            p_uso,
            p_seccion,
            p_fase_id
        ) RETURNING id INTO v_res_linea_id;
    ELSE
        -- Actualización
        v_accion := 'modificar_linea';
        v_res_linea_id := p_linea_id;

        SELECT jsonb_build_object(
            'material_id', material_id,
            'cantidad', cantidad,
            'escala', escala,
            'paso', paso,
            'uso', uso,
            'seccion', seccion,
            'fase_id', fase_id
        ) INTO v_ant_data
        FROM public.receta_base
        WHERE id = p_linea_id AND modelo_id = p_modelo_id;

        IF v_ant_data IS NULL THEN
            RAISE EXCEPTION 'linea_no_encontrada: La línea de receta % no existe', p_linea_id;
        END IF;

        UPDATE public.receta_base
        SET
            material_id = p_material_id,
            cantidad = p_cantidad,
            escala = p_escala,
            paso = p_paso,
            uso = p_uso,
            seccion = p_seccion,
            fase_id = p_fase_id,
            updated_at = now()
        WHERE id = p_linea_id;
    END IF;

    -- Registrar auditoría
    INSERT INTO public.receta_base_historial (
        organizacion_id,
        modelo_id,
        linea_id,
        accion,
        material_id,
        fase_id,
        datos_anteriores,
        datos_nuevos,
        usuario_id,
        motivo
    ) VALUES (
        v_org_id,
        p_modelo_id,
        v_res_linea_id,
        v_accion,
        p_material_id,
        p_fase_id,
        v_ant_data,
        jsonb_build_object(
            'material_id', p_material_id,
            'cantidad', p_cantidad,
            'escala', p_escala,
            'paso', p_paso,
            'uso', p_uso,
            'seccion', p_seccion,
            'fase_id', p_fase_id
        ),
        p_usuario_id,
        p_motivo
    );

    RETURN v_res_linea_id;
END;
$$;

REVOKE ALL ON FUNCTION public.guardar_linea_receta(UUID, TEXT, NUMERIC, TEXT, UUID, TEXT, TEXT, TEXT, UUID, UUID, TEXT) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.guardar_linea_receta(UUID, TEXT, NUMERIC, TEXT, UUID, TEXT, TEXT, TEXT, UUID, UUID, TEXT) TO service_role;

-- 4. Función Atómica: Eliminar Línea de Receta
CREATE OR REPLACE FUNCTION public.eliminar_linea_receta(
    p_linea_id UUID,
    p_usuario_id UUID DEFAULT NULL,
    p_motivo TEXT DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_org_id UUID;
    v_modelo_id UUID;
    v_material_id TEXT;
    v_fase_id UUID;
    v_ant_data JSONB;
BEGIN
    SELECT
        m.organizacion_id,
        rb.modelo_id,
        rb.material_id,
        rb.fase_id,
        jsonb_build_object(
            'material_id', rb.material_id,
            'cantidad', rb.cantidad,
            'escala', rb.escala,
            'paso', rb.paso,
            'uso', rb.uso,
            'seccion', rb.seccion,
            'fase_id', rb.fase_id
        )
    INTO v_org_id, v_modelo_id, v_material_id, v_fase_id, v_ant_data
    FROM public.receta_base rb
    JOIN public.modelos m ON m.id = rb.modelo_id
    WHERE rb.id = p_linea_id;

    IF v_ant_data IS NULL THEN
        RAISE EXCEPTION 'linea_no_encontrada: La línea % no existe', p_linea_id;
    END IF;

    DELETE FROM public.receta_base WHERE id = p_linea_id;

    -- Registrar auditoría
    INSERT INTO public.receta_base_historial (
        organizacion_id,
        modelo_id,
        linea_id,
        accion,
        material_id,
        fase_id,
        datos_anteriores,
        usuario_id,
        motivo
    ) VALUES (
        v_org_id,
        v_modelo_id,
        p_linea_id,
        'eliminar_linea',
        v_material_id,
        v_fase_id,
        v_ant_data,
        p_usuario_id,
        p_motivo
    );

    RETURN TRUE;
END;
$$;

REVOKE ALL ON FUNCTION public.eliminar_linea_receta(UUID, UUID, TEXT) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.eliminar_linea_receta(UUID, UUID, TEXT) TO service_role;

COMMIT;
