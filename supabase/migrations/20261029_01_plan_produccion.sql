-- Migración 20261029_01_plan_produccion.sql
-- Sub-bloque 2R-15: Plan semanal de producción (operarios, tareas, materiales y trazabilidad)

BEGIN;

-- 1. Tabla operarios
CREATE TABLE IF NOT EXISTS operarios (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organizacion_id UUID NOT NULL REFERENCES organizaciones(id) ON DELETE CASCADE,
    nombre TEXT NOT NULL,
    puesto TEXT,
    telefono TEXT,
    activo BOOLEAN NOT NULL DEFAULT true,
    notas TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE operarios ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "org_operarios_policy" ON operarios;
CREATE POLICY "org_operarios_policy" ON operarios FOR ALL USING (organizacion_id = get_current_org_id());

CREATE UNIQUE INDEX IF NOT EXISTS uq_operarios_org_nombre_ci ON operarios(organizacion_id, lower(trim(nombre)));
CREATE INDEX IF NOT EXISTS idx_operarios_org_activo ON operarios(organizacion_id, activo);

-- 2. Tabla produccion_areas
CREATE TABLE IF NOT EXISTS produccion_areas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organizacion_id UUID NOT NULL REFERENCES organizaciones(id) ON DELETE CASCADE,
    clave TEXT NOT NULL,
    nombre TEXT NOT NULL,
    orden INT NOT NULL DEFAULT 0,
    activo BOOLEAN NOT NULL DEFAULT true,
    notas TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE produccion_areas ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "org_produccion_areas_policy" ON produccion_areas;
CREATE POLICY "org_produccion_areas_policy" ON produccion_areas FOR ALL USING (organizacion_id = get_current_org_id());

CREATE UNIQUE INDEX IF NOT EXISTS uq_produccion_areas_org_clave ON produccion_areas(organizacion_id, clave);
CREATE INDEX IF NOT EXISTS idx_produccion_areas_org_orden ON produccion_areas(organizacion_id, orden);

-- 3. Tabla produccion_frentes
CREATE TABLE IF NOT EXISTS produccion_frentes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organizacion_id UUID NOT NULL REFERENCES organizaciones(id) ON DELETE CASCADE,
    area_id UUID NOT NULL REFERENCES produccion_areas(id) ON DELETE CASCADE,
    nombre TEXT NOT NULL,
    orden INT NOT NULL DEFAULT 0,
    activo BOOLEAN NOT NULL DEFAULT true,
    notas TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE produccion_frentes ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "org_produccion_frentes_policy" ON produccion_frentes;
CREATE POLICY "org_produccion_frentes_policy" ON produccion_frentes FOR ALL USING (organizacion_id = get_current_org_id());

CREATE UNIQUE INDEX IF NOT EXISTS uq_produccion_frentes_area_nombre ON produccion_frentes(area_id, nombre);
CREATE INDEX IF NOT EXISTS idx_produccion_frentes_org_area ON produccion_frentes(organizacion_id, area_id, orden);

-- 4. Tabla plan_tareas
CREATE TABLE IF NOT EXISTS plan_tareas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organizacion_id UUID NOT NULL REFERENCES organizaciones(id) ON DELETE CASCADE,
    fecha DATE NOT NULL,
    frente_id UUID NOT NULL REFERENCES produccion_frentes(id) ON DELETE CASCADE,
    orden_trabajo_id UUID REFERENCES ordenes_trabajo(id) ON DELETE SET NULL,
    descripcion TEXT,
    movilidad TEXT,
    observaciones TEXT,
    estado TEXT NOT NULL DEFAULT 'planeada' CHECK (estado IN ('planeada', 'en_proceso', 'pausada', 'terminada', 'cancelada')),
    inicio_real TIMESTAMPTZ,
    fin_real TIMESTAMPTZ,
    material_faltante BOOLEAN NOT NULL DEFAULT false,
    creado_por UUID,
    notas TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE plan_tareas ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "org_plan_tareas_policy" ON plan_tareas;
CREATE POLICY "org_plan_tareas_policy" ON plan_tareas FOR ALL USING (organizacion_id = get_current_org_id());

CREATE INDEX IF NOT EXISTS idx_plan_tareas_org_fecha ON plan_tareas(organizacion_id, fecha);
CREATE INDEX IF NOT EXISTS idx_plan_tareas_frente_fecha ON plan_tareas(frente_id, fecha);
CREATE INDEX IF NOT EXISTS idx_plan_tareas_orden ON plan_tareas(orden_trabajo_id);

-- 5. Tabla plan_tarea_operarios
CREATE TABLE IF NOT EXISTS plan_tarea_operarios (
    tarea_id UUID NOT NULL REFERENCES plan_tareas(id) ON DELETE CASCADE,
    operario_id UUID NOT NULL REFERENCES operarios(id) ON DELETE CASCADE,
    organizacion_id UUID NOT NULL REFERENCES organizaciones(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (tarea_id, operario_id)
);

ALTER TABLE plan_tarea_operarios ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "org_plan_tarea_operarios_policy" ON plan_tarea_operarios;
CREATE POLICY "org_plan_tarea_operarios_policy" ON plan_tarea_operarios FOR ALL USING (organizacion_id = get_current_org_id());

CREATE INDEX IF NOT EXISTS idx_plan_tarea_operarios_org ON plan_tarea_operarios(organizacion_id);
CREATE INDEX IF NOT EXISTS idx_plan_tarea_operarios_operario ON plan_tarea_operarios(operario_id);

-- 6. Tabla plan_tarea_materiales
CREATE TABLE IF NOT EXISTS plan_tarea_materiales (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tarea_id UUID NOT NULL REFERENCES plan_tareas(id) ON DELETE CASCADE,
    organizacion_id UUID NOT NULL REFERENCES organizaciones(id) ON DELETE CASCADE,
    producto_id TEXT REFERENCES productos(id) ON DELETE SET NULL,
    descripcion TEXT NOT NULL,
    cantidad NUMERIC(14,4) NOT NULL CHECK (cantidad > 0),
    unidad TEXT NOT NULL,
    notas TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE plan_tarea_materiales ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "org_plan_tarea_materiales_policy" ON plan_tarea_materiales;
CREATE POLICY "org_plan_tarea_materiales_policy" ON plan_tarea_materiales FOR ALL USING (organizacion_id = get_current_org_id());

CREATE INDEX IF NOT EXISTS idx_plan_tarea_mat_tarea ON plan_tarea_materiales(tarea_id);
CREATE INDEX IF NOT EXISTS idx_plan_tarea_mat_org ON plan_tarea_materiales(organizacion_id);
CREATE INDEX IF NOT EXISTS idx_plan_tarea_mat_producto ON plan_tarea_materiales(producto_id);

-- 7. Tabla plan_tareas_historial (trazabilidad y bitácora)
CREATE TABLE IF NOT EXISTS plan_tareas_historial (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organizacion_id UUID NOT NULL REFERENCES organizaciones(id) ON DELETE CASCADE,
    tarea_id UUID REFERENCES plan_tareas(id) ON DELETE SET NULL,
    descripcion_tarea TEXT,
    fecha_tarea DATE,
    evento TEXT NOT NULL CHECK (evento IN ('creada', 'editada', 'estado', 'operario_agregado', 'operario_quitado', 'material_agregado', 'material_quitado', 'eliminada')),
    detalle JSONB NOT NULL DEFAULT '{}'::jsonb,
    usuario_id UUID,
    creado_el TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE plan_tareas_historial ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "org_plan_tareas_historial_policy" ON plan_tareas_historial;
CREATE POLICY "org_plan_tareas_historial_policy" ON plan_tareas_historial FOR ALL USING (organizacion_id = get_current_org_id());

CREATE INDEX IF NOT EXISTS idx_plan_historial_org_tarea ON plan_tareas_historial(organizacion_id, tarea_id);
CREATE INDEX IF NOT EXISTS idx_plan_historial_creado ON plan_tareas_historial(creado_el DESC);

-- 8. Seed de Áreas y Frentes por Organización
-- Con notas = 'import-2r15', ON CONFLICT DO NOTHING
DO $$
DECLARE
    r_org RECORD;
    v_area_nave UUID;
    v_area_term UUID;
    v_area_gond UUID;
    v_area_plat UUID;
    v_area_repa UUID;
BEGIN
    FOR r_org IN SELECT id FROM organizaciones LOOP
        -- 1. NAVE DE PRODUCCIÓN
        INSERT INTO produccion_areas (organizacion_id, clave, nombre, orden, activo, notas)
        VALUES (r_org.id, 'nave', 'NAVE DE PRODUCCIÓN', 1, true, 'import-2r15')
        ON CONFLICT (organizacion_id, clave) DO NOTHING;

        SELECT id INTO v_area_nave FROM produccion_areas WHERE organizacion_id = r_org.id AND clave = 'nave';

        IF v_area_nave IS NOT NULL THEN
            INSERT INTO produccion_frentes (organizacion_id, area_id, nombre, orden, activo, notas)
            VALUES
                (r_org.id, v_area_nave, 'DOLLYS', 1, true, 'import-2r15'),
                (r_org.id, v_area_nave, 'CAJAS/POLINERAS', 2, true, 'import-2r15'),
                (r_org.id, v_area_nave, 'ENSAMBLE DE EJES', 3, true, 'import-2r15'),
                (r_org.id, v_area_nave, 'CORTADORA/SIERRA', 4, true, 'import-2r15')
            ON CONFLICT (area_id, nombre) DO NOTHING;
        END IF;

        -- 2. TERMINADOS
        INSERT INTO produccion_areas (organizacion_id, clave, nombre, orden, activo, notas)
        VALUES (r_org.id, 'terminados', 'TERMINADOS', 2, true, 'import-2r15')
        ON CONFLICT (organizacion_id, clave) DO NOTHING;

        SELECT id INTO v_area_term FROM produccion_areas WHERE organizacion_id = r_org.id AND clave = 'terminados';

        IF v_area_term IS NOT NULL THEN
            INSERT INTO produccion_frentes (organizacion_id, area_id, nombre, orden, activo, notas)
            VALUES
                (r_org.id, v_area_term, 'ESCORIADO', 1, true, 'import-2r15'),
                (r_org.id, v_area_term, 'LAVADO', 2, true, 'import-2r15'),
                (r_org.id, v_area_term, 'PRIMER/PINTURA', 3, true, 'import-2r15'),
                (r_org.id, v_area_term, 'INSTALACIÓN LUZ', 4, true, 'import-2r15'),
                (r_org.id, v_area_term, 'INSTALACIÓN AIRE', 5, true, 'import-2r15'),
                (r_org.id, v_area_term, 'PISO', 6, true, 'import-2r15')
            ON CONFLICT (area_id, nombre) DO NOTHING;
        END IF;

        -- 3. GÓNDOLAS
        INSERT INTO produccion_areas (organizacion_id, clave, nombre, orden, activo, notas)
        VALUES (r_org.id, 'gondolas', 'GÓNDOLAS', 3, true, 'import-2r15')
        ON CONFLICT (organizacion_id, clave) DO NOTHING;

        SELECT id INTO v_area_gond FROM produccion_areas WHERE organizacion_id = r_org.id AND clave = 'gondolas';

        IF v_area_gond IS NOT NULL THEN
            INSERT INTO produccion_frentes (organizacion_id, area_id, nombre, orden, activo, notas)
            VALUES
                (r_org.id, v_area_gond, 'CAJÓN 1', 1, true, 'import-2r15'),
                (r_org.id, v_area_gond, 'CAJÓN 2', 2, true, 'import-2r15'),
                (r_org.id, v_area_gond, 'CAJÓN 3', 3, true, 'import-2r15'),
                (r_org.id, v_area_gond, 'CHASIS 1', 4, true, 'import-2r15'),
                (r_org.id, v_area_gond, 'CHASIS 2', 5, true, 'import-2r15'),
                (r_org.id, v_area_gond, 'CHASIS 6', 6, true, 'import-2r15')
            ON CONFLICT (area_id, nombre) DO NOTHING;
        END IF;

        -- 4. PLATAFORMAS
        INSERT INTO produccion_areas (organizacion_id, clave, nombre, orden, activo, notas)
        VALUES (r_org.id, 'plataformas', 'PLATAFORMAS', 4, true, 'import-2r15')
        ON CONFLICT (organizacion_id, clave) DO NOTHING;

        SELECT id INTO v_area_plat FROM produccion_areas WHERE organizacion_id = r_org.id AND clave = 'plataformas';

        IF v_area_plat IS NOT NULL THEN
            INSERT INTO produccion_frentes (organizacion_id, area_id, nombre, orden, activo, notas)
            VALUES
                (r_org.id, v_area_plat, 'FASE 1 – CORTE', 1, true, 'import-2r15'),
                (r_org.id, v_area_plat, 'FASE 2 – DISPOSITIVO', 2, true, 'import-2r15'),
                (r_org.id, v_area_plat, 'FASE 3 – ARMADO DE BARAS', 3, true, 'import-2r15'),
                (r_org.id, v_area_plat, 'FASE 4 – IPR (CARGADORES)', 4, true, 'import-2r15'),
                (r_org.id, v_area_plat, 'FASE 5 – PERCHAS', 5, true, 'import-2r15'),
                (r_org.id, v_area_plat, 'FASE 6 – ACABADO Y EXTRAS', 6, true, 'import-2r15')
            ON CONFLICT (area_id, nombre) DO NOTHING;
        END IF;

        -- 5. REPARACIONES
        INSERT INTO produccion_areas (organizacion_id, clave, nombre, orden, activo, notas)
        VALUES (r_org.id, 'reparaciones', 'REPARACIONES', 5, true, 'import-2r15')
        ON CONFLICT (organizacion_id, clave) DO NOTHING;

        SELECT id INTO v_area_repa FROM produccion_areas WHERE organizacion_id = r_org.id AND clave = 'reparaciones';

        IF v_area_repa IS NOT NULL THEN
            INSERT INTO produccion_frentes (organizacion_id, area_id, nombre, orden, activo, notas)
            VALUES
                (r_org.id, v_area_repa, 'REPARACIONES', 1, true, 'import-2r15')
            ON CONFLICT (area_id, nombre) DO NOTHING;
        END IF;
    END LOOP;
END $$;

-- 9. Función atómica guardar_plan_tarea (SECURITY DEFINER con revocaciones estrictas)
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
) RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
    v_tarea_id UUID;
    v_frente_org UUID;
    v_orden_org UUID;
    v_op_id UUID;
    v_mat_item JSONB;
    v_desc_mat TEXT;
    v_cant_mat NUMERIC;
    v_unid_mat TEXT;
    v_prod_id TEXT;
    v_evento TEXT;
    v_es_nuevo BOOLEAN := false;
    v_tarea_ant RECORD;
BEGIN
    -- Validar organización del frente
    SELECT organizacion_id INTO v_frente_org
    FROM produccion_frentes
    WHERE id = p_frente_id AND activo = true;

    IF v_frente_org IS NULL OR v_frente_org <> p_org THEN
        RETURN jsonb_build_object('exito', false, 'error', 'frente_invalido', 'mensaje', 'El frente de producción no existe, está inactivo o pertenece a otra organización');
    END IF;

    -- Validar orden de trabajo si fue provista
    IF p_orden_trabajo_id IS NOT NULL THEN
        SELECT organizacion_id INTO v_orden_org
        FROM ordenes_trabajo
        WHERE id = p_orden_trabajo_id;

        IF v_orden_org IS NULL OR v_orden_org <> p_org THEN
            RETURN jsonb_build_object('exito', false, 'error', 'orden_invalida', 'mensaje', 'La orden de trabajo no existe o pertenece a otra organización');
        END IF;
    END IF;

    -- Validar operarios activos y pertenecientes a la organización
    IF p_operarios IS NOT NULL AND array_length(p_operarios, 1) > 0 THEN
        FOREACH v_op_id IN ARRAY p_operarios LOOP
            IF NOT EXISTS (SELECT 1 FROM operarios WHERE id = v_op_id AND organizacion_id = p_org AND activo = true) THEN
                RETURN jsonb_build_object('exito', false, 'error', 'operario_invalido', 'mensaje', 'Uno o más operarios no existen, están inactivos o no pertenecen a la organización');
            END IF;
        END LOOP;
    END IF;

    -- Determinar si es creación o actualización
    IF p_tarea_id IS NOT NULL THEN
        SELECT * INTO v_tarea_ant FROM plan_tareas WHERE id = p_tarea_id AND organizacion_id = p_org;
        IF v_tarea_ant.id IS NULL THEN
            RETURN jsonb_build_object('exito', false, 'error', 'no_encontrada', 'mensaje', 'Tarea no encontrada');
        END IF;
        v_es_nuevo := false;
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

    -- Sincronizar operarios
    DELETE FROM plan_tarea_operarios WHERE tarea_id = v_tarea_id AND organizacion_id = p_org;
    IF p_operarios IS NOT NULL AND array_length(p_operarios, 1) > 0 THEN
        FOREACH v_op_id IN ARRAY p_operarios LOOP
            INSERT INTO plan_tarea_operarios (tarea_id, operario_id, organizacion_id)
            VALUES (v_tarea_id, v_op_id, p_org)
            ON CONFLICT (tarea_id, operario_id) DO NOTHING;
        END LOOP;
    END IF;

    -- Sincronizar materiales
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

            -- Si tiene producto_id, validar que pertenece a la organización
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

    -- Registrar evento en bitácora de trazabilidad
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
            'estado', CASE WHEN v_es_nuevo THEN 'planeada' ELSE v_tarea_ant.estado END,
            'total_operarios', coalesce(array_length(p_operarios, 1), 0),
            'total_materiales', coalesce(jsonb_array_length(p_materiales), 0)
        ),
        p_usuario
    );

    RETURN jsonb_build_object('exito', true, 'tarea_id', v_tarea_id);
END;
$$;

-- 10. Función para cambio de estado de tarea con registro en trazabilidad
CREATE OR REPLACE FUNCTION cambiar_estado_plan_tarea(
    p_org UUID,
    p_usuario UUID,
    p_tarea_id UUID,
    p_nuevo_estado TEXT,
    p_inicio_real TIMESTAMPTZ,
    p_fin_real TIMESTAMPTZ
) RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
    r_tarea RECORD;
BEGIN
    SELECT * INTO r_tarea FROM plan_tareas WHERE id = p_tarea_id AND organizacion_id = p_org;

    IF r_tarea.id IS NULL THEN
        RETURN jsonb_build_object('exito', false, 'error', 'no_encontrada', 'mensaje', 'Tarea no encontrada');
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

-- 11. Función para eliminación de tarea preservando trazabilidad
CREATE OR REPLACE FUNCTION eliminar_plan_tarea(
    p_org UUID,
    p_usuario UUID,
    p_tarea_id UUID
) RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
    r_tarea RECORD;
BEGIN
    SELECT * INTO r_tarea FROM plan_tareas WHERE id = p_tarea_id AND organizacion_id = p_org;

    IF r_tarea.id IS NULL THEN
        RETURN jsonb_build_object('exito', false, 'error', 'no_encontrada', 'mensaje', 'Tarea no encontrada');
    END IF;

    -- Registrar evento 'eliminada' antes del borrado (guardando snapshot de descripción y fecha)
    INSERT INTO plan_tareas_historial (
        organizacion_id, tarea_id, descripcion_tarea, fecha_tarea,
        evento, detalle, usuario_id
    ) VALUES (
        p_org, NULL, r_tarea.descripcion, r_tarea.fecha,
        'eliminada',
        jsonb_build_object(
            'tarea_id_eliminada', p_tarea_id,
            'fecha', r_tarea.fecha,
            'frente_id', r_tarea.frente_id,
            'orden_trabajo_id', r_tarea.orden_trabajo_id,
            'descripcion', r_tarea.descripcion,
            'movilidad', r_tarea.movilidad,
            'observaciones', r_tarea.observaciones,
            'estado', r_tarea.estado
        ),
        p_usuario
    );

    DELETE FROM plan_tareas WHERE id = p_tarea_id AND organizacion_id = p_org;

    RETURN jsonb_build_object('exito', true, 'tarea_id', p_tarea_id);
END;
$$;

-- 12. Restricción estricta de permisos EXECUTE (SECURITY DEFINER exclusivo para service_role)
REVOKE ALL ON FUNCTION guardar_plan_tarea(uuid, uuid, uuid, date, uuid, uuid, text, text, text, boolean, text, uuid[], jsonb) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION cambiar_estado_plan_tarea(uuid, uuid, uuid, text, timestamptz, timestamptz) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION eliminar_plan_tarea(uuid, uuid, uuid) FROM PUBLIC, anon, authenticated;

GRANT EXECUTE ON FUNCTION guardar_plan_tarea(uuid, uuid, uuid, date, uuid, uuid, text, text, text, boolean, text, uuid[], jsonb) TO service_role;
GRANT EXECUTE ON FUNCTION cambiar_estado_plan_tarea(uuid, uuid, uuid, text, timestamptz, timestamptz) TO service_role;
GRANT EXECUTE ON FUNCTION eliminar_plan_tarea(uuid, uuid, uuid) TO service_role;

ALTER FUNCTION guardar_plan_tarea(uuid, uuid, uuid, date, uuid, uuid, text, text, text, boolean, text, uuid[], jsonb) SET search_path = public;
ALTER FUNCTION cambiar_estado_plan_tarea(uuid, uuid, uuid, text, timestamptz, timestamptz) SET search_path = public;
ALTER FUNCTION eliminar_plan_tarea(uuid, uuid, uuid) SET search_path = public;

COMMIT;
