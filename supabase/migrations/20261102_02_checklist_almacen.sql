-- Migración 20261102_02_checklist_almacen.sql
-- Sub-bloque T3 (Turno Noche 2026-11-02): Checklist de entregas almacén -> producción por OT, equipo y fase
-- 1. Tablas orden_despiece_lineas y orden_despiece_entregas con RLS
-- 2. Funciones atómicas SECURITY DEFINER con FOR UPDATE: registrar_entrega_despiece y anular_entrega_despiece
-- 3. Vista v_orden_despiece_avance con WITH (security_invoker = true)
-- 4. Permisos: REVOKE a PUBLIC, anon, authenticated; GRANT a service_role
-- 5. Notas: 'import-t3-checklist'

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

DROP POLICY IF EXISTS "orden_despiece_lineas_org_all" ON orden_despiece_lineas;
CREATE POLICY "orden_despiece_lineas_org_all" ON orden_despiece_lineas
    FOR ALL TO authenticated
    USING (organizacion_id IN (SELECT organizacion_id FROM perfiles_organizacion WHERE usuario_id = auth.uid()))
    WITH CHECK (organizacion_id IN (SELECT organizacion_id FROM perfiles_organizacion WHERE usuario_id = auth.uid()));

CREATE INDEX IF NOT EXISTS idx_orden_despiece_lineas_ot ON orden_despiece_lineas(orden_trabajo_id, equipo_indice);
CREATE INDEX IF NOT EXISTS idx_orden_despiece_lineas_fase ON orden_despiece_lineas(fase_id);

-- 2. Tabla de entregas (nunca se borran filas)
CREATE TABLE IF NOT EXISTS orden_despiece_entregas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organizacion_id UUID NOT NULL REFERENCES organizaciones(id) ON DELETE CASCADE,
    linea_id UUID NOT NULL REFERENCES orden_despiece_lineas(id) ON DELETE CASCADE,
    tipo TEXT NOT NULL DEFAULT 'entrega' CHECK (tipo IN ('entrega', 'reposicion')),
    cantidad NUMERIC(14, 4) NOT NULL CHECK (cantidad > 0),
    operario_id UUID REFERENCES operarios(id) ON DELETE SET NULL,
    operario_nombre TEXT,
    entregado_por UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    fecha DATE NOT NULL DEFAULT CURRENT_DATE,
    hora TIME NOT NULL DEFAULT CURRENT_TIME,
    motivo TEXT,
    anulada BOOLEAN NOT NULL DEFAULT false,
    anulada_por UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    anulada_en TIMESTAMPTZ,
    motivo_anulacion TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE orden_despiece_entregas ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "orden_despiece_entregas_org_all" ON orden_despiece_entregas;
CREATE POLICY "orden_despiece_entregas_org_all" ON orden_despiece_entregas
    FOR ALL TO authenticated
    USING (organizacion_id IN (SELECT organizacion_id FROM perfiles_organizacion WHERE usuario_id = auth.uid()))
    WITH CHECK (organizacion_id IN (SELECT organizacion_id FROM perfiles_organizacion WHERE usuario_id = auth.uid()));

CREATE INDEX IF NOT EXISTS idx_orden_despiece_entregas_linea ON orden_despiece_entregas(linea_id);
CREATE INDEX IF NOT EXISTS idx_orden_despiece_entregas_operario ON orden_despiece_entregas(operario_id);

-- 3. Vista de avance de despiece con security_invoker = true
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

-- 4. Función atómica para registrar entrega con bloqueo FOR UPDATE
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
BEGIN
    -- Validaciones básicas
    IF p_cantidad IS NULL OR p_cantidad <= 0 THEN
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
        IF (v_entregado + p_cantidad) > v_linea.cantidad_requerida THEN
            RAISE EXCEPTION 'excede_requerido: La cantidad %.2f excede el saldo pendiente %.2f', p_cantidad, v_pendiente;
        END IF;
    END IF;

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
        p_cantidad,
        p_operario_id,
        trim(p_operario_nombre),
        p_entregado_por,
        CURRENT_DATE,
        CURRENT_TIME,
        trim(p_motivo)
    )
    RETURNING id INTO v_entrega_id;

    -- Recalcular pendiente tras inserción
    IF p_tipo = 'entrega' THEN
        v_nueva_cantidad := v_entregado + p_cantidad;
        v_pendiente := GREATEST(0, v_linea.cantidad_requerida - v_nueva_cantidad);
    ELSE
        v_nueva_cantidad := v_entregado;
    END IF;

    RETURN jsonb_build_object(
        'success', true,
        'entrega_id', v_entrega_id,
        'linea_id', p_linea_id,
        'tipo', p_tipo,
        'cantidad', p_cantidad,
        'total_entregado', v_nueva_cantidad,
        'requerida', v_linea.cantidad_requerida,
        'pendiente', v_pendiente,
        'completo', (v_nueva_cantidad >= v_linea.cantidad_requerida)
    );
END;
$$;

-- 5. Función atómica para anular entrega
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

-- 6. Seguridad estricta: REVOKE a PUBLIC, anon, authenticated y GRANT a service_role
REVOKE ALL ON FUNCTION registrar_entrega_despiece(UUID, UUID, NUMERIC, TEXT, UUID, TEXT, TEXT, UUID) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION registrar_entrega_despiece(UUID, UUID, NUMERIC, TEXT, UUID, TEXT, TEXT, UUID) TO service_role;

REVOKE ALL ON FUNCTION anular_entrega_despiece(UUID, UUID, TEXT, UUID) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION anular_entrega_despiece(UUID, UUID, TEXT, UUID) TO service_role;

COMMIT;
