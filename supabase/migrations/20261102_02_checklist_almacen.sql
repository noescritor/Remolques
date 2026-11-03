-- Migración 20261102_02_checklist_almacen.sql
-- Sub-bloque T3 (Turno Noche / Ronda 2): Checklist de entregas almacén -> producción por OT, equipo y fase
-- 1. Tablas orden_despiece_lineas y orden_despiece_entregas con RLS restrictivo (solo SELECT para authenticated)
-- 2. Integridad referencial ON DELETE RESTRICT en orden_despiece_entregas
-- 3. Trigger trg_lineas_requerida_vs_entregada para impedir cantidad_requerida < entregado
-- 4. Funciones atómicas SECURITY DEFINER con FOR UPDATE:
--    - registrar_entrega_despiece (bloqueo, validación de sobreentrega, fecha/hora México)
--    - anular_entrega_despiece
--    - ajustar_cantidad_despiece
--    - eliminar_linea_despiece
-- 5. Vista v_orden_despiece_avance con WITH (security_invoker = true)
-- 6. Permisos: REVOKE a PUBLIC, anon, authenticated; GRANT a service_role

BEGIN;

-- 1. Tabla de líneas de despiece por OT y equipo
CREATE TABLE IF NOT EXISTS orden_despiece_lineas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organizacion_id UUID NOT NULL REFERENCES organizaciones(id) ON DELETE CASCADE,
    orden_trabajo_id UUID NOT NULL REFERENCES ordenes_trabajo(id) ON DELETE CASCADE,
    equipo_indice INTEGER NOT NULL DEFAULT 1 CHECK (equipo_indice >= 1),
    fase_id UUID REFERENCES fases_despiece(id) ON DELETE SET NULL,
    fase_clave TEXT NOT NULL,
    kit TEXT,
    material_id TEXT REFERENCES productos(id) ON DELETE SET NULL,
    descripcion TEXT NOT NULL,
    unidad TEXT NOT NULL DEFAULT 'pz',
    cantidad_requerida NUMERIC(14, 4) NOT NULL CHECK (cantidad_requerida >= 0),
    origen TEXT NOT NULL DEFAULT 'receta' CHECK (origen IN ('receta', 'opcion', 'manual', 'ajuste')),
    sin_costo BOOLEAN NOT NULL DEFAULT false,
    clave_origen TEXT NOT NULL,
    notas TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_orden_despiece_lineas_clave UNIQUE (orden_trabajo_id, equipo_indice, clave_origen)
);

ALTER TABLE orden_despiece_lineas ENABLE ROW LEVEL SECURITY;

-- Políticas estrictas: authenticated solo puede hacer SELECT.
-- Modificaciones únicamente a través de serviceClient o RPCs SECURITY DEFINER.
DROP POLICY IF EXISTS "orden_despiece_lineas_org_all" ON orden_despiece_lineas;
DROP POLICY IF EXISTS "orden_despiece_lineas_org_select" ON orden_despiece_lineas;
CREATE POLICY "orden_despiece_lineas_org_select" ON orden_despiece_lineas
    FOR SELECT TO authenticated
    USING (organizacion_id = get_current_org_id());

CREATE INDEX IF NOT EXISTS idx_orden_despiece_lineas_ot ON orden_despiece_lineas(orden_trabajo_id, equipo_indice);
CREATE INDEX IF NOT EXISTS idx_orden_despiece_lineas_fase ON orden_despiece_lineas(fase_id);

-- 2. Tabla de entregas (nunca se borran filas físicas; auditoría inmutable)
CREATE TABLE IF NOT EXISTS orden_despiece_entregas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organizacion_id UUID NOT NULL REFERENCES organizaciones(id) ON DELETE CASCADE,
    linea_id UUID NOT NULL REFERENCES orden_despiece_lineas(id) ON DELETE RESTRICT,
    tipo TEXT NOT NULL DEFAULT 'entrega' CHECK (tipo IN ('entrega', 'reposicion')),
    cantidad NUMERIC(14, 4) NOT NULL CHECK (cantidad > 0),
    operario_id UUID REFERENCES operarios(id) ON DELETE SET NULL,
    operario_nombre TEXT,
    entregado_por UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    fecha DATE NOT NULL DEFAULT (now() AT TIME ZONE 'America/Mexico_City')::date,
    hora TIME NOT NULL DEFAULT (now() AT TIME ZONE 'America/Mexico_City')::time,
    motivo TEXT,
    anulada BOOLEAN NOT NULL DEFAULT false,
    anulada_por UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    anulada_en TIMESTAMPTZ,
    motivo_anulacion TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Asegurar que si la tabla ya existía con ON DELETE CASCADE, se actualice a ON DELETE RESTRICT
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_name = 'orden_despiece_entregas_linea_id_fkey'
        AND table_name = 'orden_despiece_entregas'
    ) THEN
        ALTER TABLE orden_despiece_entregas DROP CONSTRAINT orden_despiece_entregas_linea_id_fkey;
        ALTER TABLE orden_despiece_entregas
            ADD CONSTRAINT orden_despiece_entregas_linea_id_fkey
            FOREIGN KEY (linea_id) REFERENCES orden_despiece_lineas(id) ON DELETE RESTRICT;
    END IF;
END $$;

ALTER TABLE orden_despiece_entregas ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "orden_despiece_entregas_org_all" ON orden_despiece_entregas;
DROP POLICY IF EXISTS "orden_despiece_entregas_org_select" ON orden_despiece_entregas;
CREATE POLICY "orden_despiece_entregas_org_select" ON orden_despiece_entregas
    FOR SELECT TO authenticated
    USING (organizacion_id = get_current_org_id());

CREATE INDEX IF NOT EXISTS idx_orden_despiece_entregas_linea ON orden_despiece_entregas(linea_id);
CREATE INDEX IF NOT EXISTS idx_orden_despiece_entregas_operario ON orden_despiece_entregas(operario_id);

-- 3. Trigger para garantizar que cantidad_requerida nunca sea menor a lo ya entregado
CREATE OR REPLACE FUNCTION trg_validar_requerida_vs_entregada()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_entregado NUMERIC(14, 4);
BEGIN
    SELECT COALESCE(SUM(cantidad), 0) INTO v_entregado
    FROM orden_despiece_entregas
    WHERE linea_id = NEW.id AND anulada = false AND tipo = 'entrega';

    IF NEW.cantidad_requerida < v_entregado THEN
        RAISE EXCEPTION 'cantidad_requerida_invalida: La cantidad requerida (%) no puede ser menor a lo ya entregado (%)',
            NEW.cantidad_requerida, v_entregado;
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_lineas_requerida_vs_entregada ON orden_despiece_lineas;
CREATE TRIGGER trg_lineas_requerida_vs_entregada
    BEFORE UPDATE OF cantidad_requerida ON orden_despiece_lineas
    FOR EACH ROW
    EXECUTE FUNCTION trg_validar_requerida_vs_entregada();

-- 4. Vista de avance de despiece con security_invoker = true
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
            'fecha', e_ult.fecha,
            'hora', e_ult.hora,
            'operario_nombre', COALESCE(op.nombre, e_ult.operario_nombre, 'Operario'),
            'tipo', e_ult.tipo
        )
        FROM orden_despiece_entregas e_ult
        LEFT JOIN operarios op ON e_ult.operario_id = op.id
        WHERE e_ult.linea_id = l.id AND e_ult.anulada = false
        ORDER BY e_ult.created_at DESC
        LIMIT 1
    ) AS ultima_entrega
FROM orden_despiece_lineas l
LEFT JOIN fases_despiece fd ON l.fase_id = fd.id
LEFT JOIN orden_despiece_entregas e ON l.id = e.linea_id
GROUP BY l.id, fd.nombre, fd.orden;

-- 5. Función atómica para registrar entrega con bloqueo FOR UPDATE y zona horaria de México
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
SET search_path = public
AS $$
DECLARE
    v_linea RECORD;
    v_entregado NUMERIC(14, 4);
    v_pendiente NUMERIC(14, 4);
    v_entrega_id UUID;
    v_nueva_cantidad NUMERIC(14, 4);
    v_cant NUMERIC(14, 4);
    v_fecha_mx DATE;
    v_hora_mx TIME;
BEGIN
    IF p_cantidad IS NULL THEN
        RAISE EXCEPTION 'cantidad_invalida: La cantidad es requerida';
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

    -- Bloqueo de fila FOR UPDATE
    SELECT * INTO v_linea
    FROM orden_despiece_lineas
    WHERE id = p_linea_id AND organizacion_id = p_org_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'linea_no_encontrada: La línea de despiece no existe o pertenece a otra organización';
    END IF;

    -- Calcular acumulado entregado actual
    SELECT COALESCE(SUM(cantidad), 0) INTO v_entregado
    FROM orden_despiece_entregas
    WHERE linea_id = p_linea_id AND anulada = false AND tipo = 'entrega';

    v_pendiente := GREATEST(0, v_linea.cantidad_requerida - v_entregado);

    -- Si es entrega regular, verificar que no exceda lo requerido
    IF p_tipo = 'entrega' THEN
        IF (v_entregado + v_cant) > v_linea.cantidad_requerida THEN
            RAISE EXCEPTION 'excede_requerido: La cantidad % excede el saldo pendiente %',
                round(v_cant, 4), round(v_pendiente, 4)
                USING DETAIL = round(v_pendiente, 4)::text, HINT = 'saldo_pendiente';
        END IF;
    END IF;

    v_fecha_mx := (now() AT TIME ZONE 'America/Mexico_City')::date;
    v_hora_mx := (now() AT TIME ZONE 'America/Mexico_City')::time;

    -- Insertar movimiento
    INSERT INTO orden_despiece_entregas (
        organizacion_id,
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

    -- Recalcular pendiente tras inserción
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

-- 6. Función atómica para anular entrega
CREATE OR REPLACE FUNCTION anular_entrega_despiece(
    p_org_id UUID,
    p_entrega_id UUID,
    p_motivo TEXT,
    p_usuario_id UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_entrega RECORD;
    v_linea RECORD;
    v_entregado NUMERIC(14, 4);
BEGIN
    IF p_motivo IS NULL OR trim(p_motivo) = '' THEN
        RAISE EXCEPTION 'motivo_requerido: Se requiere especificar el motivo de anulación';
    END IF;

    -- Bloqueo de fila FOR UPDATE
    SELECT * INTO v_entrega
    FROM orden_despiece_entregas
    WHERE id = p_entrega_id AND organizacion_id = p_org_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'entrega_no_encontrada: La entrega no existe o pertenece a otra organización';
    END IF;

    IF v_entrega.anulada THEN
        RAISE EXCEPTION 'ya_anulada: Esta entrega ya se encuentra anulada';
    END IF;

    UPDATE orden_despiece_entregas
    SET anulada = true,
        motivo_anulacion = trim(p_motivo),
        anulada_por = p_usuario_id,
        anulada_en = now()
    WHERE id = p_entrega_id;

    -- Obtener nuevo estado de la línea
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

-- 7. Función atómica para ajustar cantidad requerida de una partida con bloqueo FOR UPDATE
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
SET search_path = public
AS $$
DECLARE
    v_linea RECORD;
    v_entregado NUMERIC(14, 4);
    v_anterior NUMERIC(14, 4);
    v_nueva NUMERIC(14, 4);
    v_nota_ajuste TEXT;
BEGIN
    IF p_motivo IS NULL OR trim(p_motivo) = '' THEN
        RAISE EXCEPTION 'motivo_requerido: Se requiere especificar el motivo del ajuste';
    END IF;

    IF p_nueva_cantidad IS NULL OR p_nueva_cantidad < 0 THEN
        RAISE EXCEPTION 'cantidad_invalida: La cantidad requerida no puede ser negativa';
    END IF;

    v_nueva := round(p_nueva_cantidad, 4);

    SELECT * INTO v_linea
    FROM orden_despiece_lineas
    WHERE id = p_linea_id AND organizacion_id = p_org_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'linea_no_encontrada: La línea de despiece no existe o pertenece a otra organización';
    END IF;

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

-- 8. Función atómica para eliminar línea agregada manualmente (sin historial)
CREATE OR REPLACE FUNCTION eliminar_linea_despiece(
    p_org_id UUID,
    p_linea_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_linea RECORD;
    v_tiene_entregas BOOLEAN;
BEGIN
    SELECT * INTO v_linea
    FROM orden_despiece_lineas
    WHERE id = p_linea_id AND organizacion_id = p_org_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'linea_no_encontrada: La línea no existe o pertenece a otra organización';
    END IF;

    IF v_linea.origen <> 'manual' THEN
        RAISE EXCEPTION 'linea_no_eliminable: Solo se pueden eliminar líneas agregadas manualmente';
    END IF;

    -- Verificar que NO tenga ninguna entrega registrada (ni activa ni anulada) para preservar historial
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

-- 9. Seguridad estricta: REVOKE a PUBLIC, anon, authenticated; GRANT a service_role
REVOKE ALL ON FUNCTION registrar_entrega_despiece(UUID, UUID, NUMERIC, TEXT, UUID, TEXT, TEXT, UUID) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION registrar_entrega_despiece(UUID, UUID, NUMERIC, TEXT, UUID, TEXT, TEXT, UUID) TO service_role;

REVOKE ALL ON FUNCTION anular_entrega_despiece(UUID, UUID, TEXT, UUID) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION anular_entrega_despiece(UUID, UUID, TEXT, UUID) TO service_role;

REVOKE ALL ON FUNCTION ajustar_cantidad_despiece(UUID, UUID, NUMERIC, TEXT, UUID) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION ajustar_cantidad_despiece(UUID, UUID, NUMERIC, TEXT, UUID) TO service_role;

REVOKE ALL ON FUNCTION eliminar_linea_despiece(UUID, UUID) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION eliminar_linea_despiece(UUID, UUID) TO service_role;

COMMIT;
