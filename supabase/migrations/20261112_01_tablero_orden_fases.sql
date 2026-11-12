-- Migración 20261112_01_tablero_orden_fases.sql
-- Tablero de producción: estado por fase (Bloque 1 de 2: datos y backend)
-- Idempotente: diseñada para ejecutarse múltiples veces con ON_ERROR_STOP=1 sin alterar datos previos ni duraciones editadas.

BEGIN;

-- 1. Modificar lineas_producto: unicidad por (organizacion_id, clave)
ALTER TABLE lineas_producto DROP CONSTRAINT IF EXISTS lineas_producto_clave_key;
DROP INDEX IF EXISTS lineas_producto_clave_key;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'uq_lineas_producto_org_clave'
    ) THEN
        ALTER TABLE lineas_producto 
        ADD CONSTRAINT uq_lineas_producto_org_clave UNIQUE (organizacion_id, clave);
    END IF;
END $$;

-- 2. Modificar fases_produccion: grupo, duracion_dias, requiere_grupo, activo y unicidad (linea_producto_id, grupo, orden)
ALTER TABLE fases_produccion
    ADD COLUMN IF NOT EXISTS grupo TEXT NOT NULL DEFAULT 'principal',
    ADD COLUMN IF NOT EXISTS duracion_dias INTEGER NOT NULL DEFAULT 2,
    ADD COLUMN IF NOT EXISTS requiere_grupo TEXT NULL,
    ADD COLUMN IF NOT EXISTS activo BOOLEAN NOT NULL DEFAULT true;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_fases_produccion_grupo') THEN
        ALTER TABLE fases_produccion ADD CONSTRAINT chk_fases_produccion_grupo 
            CHECK (grupo IN ('principal', 'tina'));
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_fases_produccion_duracion') THEN
        ALTER TABLE fases_produccion ADD CONSTRAINT chk_fases_produccion_duracion 
            CHECK (duracion_dias BETWEEN 1 AND 60);
    END IF;
END $$;

-- Eliminar unicidad previa (linea_producto_id, orden)
ALTER TABLE fases_produccion DROP CONSTRAINT IF EXISTS fases_produccion_linea_producto_id_orden_key;
DROP INDEX IF EXISTS fases_produccion_linea_producto_id_orden_key;

-- Agregar unicidad nueva (linea_producto_id, grupo, orden)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'uq_fases_produccion_linea_grupo_orden') THEN
        ALTER TABLE fases_produccion ADD CONSTRAINT uq_fases_produccion_linea_grupo_orden 
            UNIQUE (linea_producto_id, grupo, orden);
    END IF;
END $$;

-- 3. Modificar ordenes_trabajo: fecha_compromiso, etiqueta, origen y flexibilizar cotizacion_id/cliente_id
ALTER TABLE ordenes_trabajo
    ADD COLUMN IF NOT EXISTS fecha_compromiso DATE,
    ADD COLUMN IF NOT EXISTS etiqueta TEXT,
    ADD COLUMN IF NOT EXISTS origen TEXT NOT NULL DEFAULT 'cotizacion';

ALTER TABLE ordenes_trabajo ALTER COLUMN cotizacion_id DROP NOT NULL;
ALTER TABLE ordenes_trabajo ALTER COLUMN cliente_id DROP NOT NULL;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_ordenes_trabajo_origen_valido') THEN
        ALTER TABLE ordenes_trabajo ADD CONSTRAINT chk_ordenes_trabajo_origen_valido 
            CHECK (origen IN ('cotizacion', 'manual'));
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_ordenes_trabajo_origen_campos') THEN
        ALTER TABLE ordenes_trabajo ADD CONSTRAINT chk_ordenes_trabajo_origen_campos 
            CHECK (
                (origen = 'cotizacion' AND cotizacion_id IS NOT NULL AND cliente_id IS NOT NULL) OR
                (origen = 'manual' AND (cliente_id IS NOT NULL OR etiqueta IS NOT NULL))
            );
    END IF;
END $$;

-- 4. Modificar historial_fases: estado_anterior, fecha_propuesta, nota
ALTER TABLE historial_fases
    ADD COLUMN IF NOT EXISTS estado_anterior TEXT,
    ADD COLUMN IF NOT EXISTS fecha_propuesta DATE,
    ADD COLUMN IF NOT EXISTS nota TEXT;

-- 5. Crear tabla orden_fases
CREATE TABLE IF NOT EXISTS orden_fases (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organizacion_id UUID NOT NULL REFERENCES organizaciones(id) ON DELETE CASCADE,
    orden_trabajo_id UUID NOT NULL REFERENCES ordenes_trabajo(id) ON DELETE CASCADE,
    fase_id UUID NOT NULL REFERENCES fases_produccion(id) ON DELETE CASCADE,
    estado TEXT NOT NULL DEFAULT 'pendiente' 
        CHECK (estado IN ('pendiente', 'en_proceso', 'incompleta', 'pausada', 'terminada')),
    fecha_propuesta DATE,
    fecha_inicio TIMESTAMPTZ,
    fecha_fin TIMESTAMPTZ,
    nota TEXT,
    actualizado_por UUID,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    CONSTRAINT uq_orden_fases_orden_fase UNIQUE (orden_trabajo_id, fase_id)
);

CREATE INDEX IF NOT EXISTS idx_orden_fases_org_orden ON orden_fases (organizacion_id, orden_trabajo_id);
CREATE INDEX IF NOT EXISTS idx_orden_fases_fase_estado ON orden_fases (fase_id, estado);

ALTER TABLE orden_fases ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "orden_fases_org_select" ON orden_fases;
DROP POLICY IF EXISTS "org_orden_fases_policy" ON orden_fases;

CREATE POLICY "orden_fases_org_select" ON orden_fases
    FOR SELECT TO authenticated
    USING (organizacion_id = get_current_org_id());

-- 6. Función sembrar_tablero_produccion(p_org UUID)
CREATE OR REPLACE FUNCTION sembrar_tablero_produccion(p_org UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_linea_plat UUID;
    v_linea_gond UUID;
    v_linea_dolly UUID;
    v_linea_traila UUID;
BEGIN
    -- 1. Líneas de producto (4 líneas canónicas)
    INSERT INTO lineas_producto (organizacion_id, clave, nombre)
    VALUES (p_org, 'plataforma', 'Plataforma')
    ON CONFLICT (organizacion_id, clave) DO UPDATE SET nombre = EXCLUDED.nombre
    RETURNING id INTO v_linea_plat;

    INSERT INTO lineas_producto (organizacion_id, clave, nombre)
    VALUES (p_org, 'gondola', 'Góndola')
    ON CONFLICT (organizacion_id, clave) DO UPDATE SET nombre = EXCLUDED.nombre
    RETURNING id INTO v_linea_gond;

    INSERT INTO lineas_producto (organizacion_id, clave, nombre)
    VALUES (p_org, 'dolly', 'Dolly')
    ON CONFLICT (organizacion_id, clave) DO UPDATE SET nombre = EXCLUDED.nombre
    RETURNING id INTO v_linea_dolly;

    INSERT INTO lineas_producto (organizacion_id, clave, nombre)
    VALUES (p_org, 'traila', 'Traila')
    ON CONFLICT (organizacion_id, clave) DO UPDATE SET nombre = EXCLUDED.nombre
    RETURNING id INTO v_linea_traila;

    IF v_linea_plat IS NULL THEN SELECT id INTO v_linea_plat FROM lineas_producto WHERE organizacion_id = p_org AND clave = 'plataforma'; END IF;
    IF v_linea_gond IS NULL THEN SELECT id INTO v_linea_gond FROM lineas_producto WHERE organizacion_id = p_org AND clave = 'gondola'; END IF;
    IF v_linea_dolly IS NULL THEN SELECT id INTO v_linea_dolly FROM lineas_producto WHERE organizacion_id = p_org AND clave = 'dolly'; END IF;
    IF v_linea_traila IS NULL THEN SELECT id INTO v_linea_traila FROM lineas_producto WHERE organizacion_id = p_org AND clave = 'traila'; END IF;

    -- 2. Fases de Plataforma (grupo principal, 12 fases)
    INSERT INTO fases_produccion (organizacion_id, linea_producto_id, grupo, orden, nombre, duracion_dias, requiere_grupo, activo)
    VALUES
        (p_org, v_linea_plat, 'principal', 1, 'Corte', 2, NULL, true),
        (p_org, v_linea_plat, 'principal', 2, 'Dispositivo', 2, NULL, true),
        (p_org, v_linea_plat, 'principal', 3, 'Armado de baras', 2, NULL, true),
        (p_org, v_linea_plat, 'principal', 4, 'IPR', 2, NULL, true),
        (p_org, v_linea_plat, 'principal', 5, 'Perchas', 2, NULL, true),
        (p_org, v_linea_plat, 'principal', 6, 'Acabado y extras', 2, NULL, true),
        (p_org, v_linea_plat, 'principal', 7, 'Escoreado y lavado', 2, NULL, true),
        (p_org, v_linea_plat, 'principal', 8, 'Primer', 2, NULL, true),
        (p_org, v_linea_plat, 'principal', 9, 'Pintura', 2, NULL, true),
        (p_org, v_linea_plat, 'principal', 10, 'Luz', 2, NULL, true),
        (p_org, v_linea_plat, 'principal', 11, 'Aire', 2, NULL, true),
        (p_org, v_linea_plat, 'principal', 12, 'Piso', 2, NULL, true)
    ON CONFLICT (linea_producto_id, grupo, orden) 
    DO UPDATE SET 
        nombre = EXCLUDED.nombre,
        activo = EXCLUDED.activo,
        requiere_grupo = EXCLUDED.requiere_grupo;

    -- 3. Fases de Góndola - principal (12 fases)
    INSERT INTO fases_produccion (organizacion_id, linea_producto_id, grupo, orden, nombre, duracion_dias, requiere_grupo, activo)
    VALUES
        (p_org, v_linea_gond, 'principal', 1, 'Corte', 2, NULL, true),
        (p_org, v_linea_gond, 'principal', 2, 'Dispositivo', 2, NULL, true),
        (p_org, v_linea_gond, 'principal', 3, 'Armado de baras', 2, NULL, true),
        (p_org, v_linea_gond, 'principal', 4, 'Jalón y cajones para tina', 2, NULL, true),
        (p_org, v_linea_gond, 'principal', 5, 'Suspensión, ejes y patines', 2, NULL, true),
        (p_org, v_linea_gond, 'principal', 6, 'Acabados', 2, NULL, true),
        (p_org, v_linea_gond, 'principal', 7, 'Montado de tina', 2, 'tina', true),
        (p_org, v_linea_gond, 'principal', 8, 'Escoreado y lavado', 2, NULL, true),
        (p_org, v_linea_gond, 'principal', 9, 'Primer', 2, NULL, true),
        (p_org, v_linea_gond, 'principal', 10, 'Pintura', 2, NULL, true),
        (p_org, v_linea_gond, 'principal', 11, 'Aire', 2, NULL, true),
        (p_org, v_linea_gond, 'principal', 12, 'Luz', 2, NULL, true)
    ON CONFLICT (linea_producto_id, grupo, orden) 
    DO UPDATE SET 
        nombre = EXCLUDED.nombre,
        activo = EXCLUDED.activo,
        requiere_grupo = EXCLUDED.requiere_grupo;

    -- 4. Fases de Góndola - tina (10 fases)
    INSERT INTO fases_produccion (organizacion_id, linea_producto_id, grupo, orden, nombre, duracion_dias, requiere_grupo, activo)
    VALUES
        (p_org, v_linea_gond, 'tina', 1, 'Piso y vueltas laterales', 2, NULL, true),
        (p_org, v_linea_gond, 'tina', 2, 'Cuellos y placas superiores', 2, NULL, true),
        (p_org, v_linea_gond, 'tina', 3, 'Ensamble de HSS principal', 2, NULL, true),
        (p_org, v_linea_gond, 'tina', 4, 'Ensamble de frente y HSS lateral', 2, NULL, true),
        (p_org, v_linea_gond, 'tina', 5, 'Ensamble de porterías', 2, NULL, true),
        (p_org, v_linea_gond, 'tina', 6, 'Complementos', 2, NULL, true),
        (p_org, v_linea_gond, 'tina', 7, 'Resoldado externo', 2, NULL, true),
        (p_org, v_linea_gond, 'tina', 8, 'Resoldado interno', 2, NULL, true),
        (p_org, v_linea_gond, 'tina', 9, 'Ensamble de puerta y plafonera', 2, NULL, true),
        (p_org, v_linea_gond, 'tina', 10, 'Terminados', 2, NULL, true)
    ON CONFLICT (linea_producto_id, grupo, orden) 
    DO UPDATE SET 
        nombre = EXCLUDED.nombre,
        activo = EXCLUDED.activo,
        requiere_grupo = EXCLUDED.requiere_grupo;

    -- 5. Fases de Dolly (grupo principal, 10 fases)
    INSERT INTO fases_produccion (organizacion_id, linea_producto_id, grupo, orden, nombre, duracion_dias, requiere_grupo, activo)
    VALUES
        (p_org, v_linea_dolly, 'principal', 1, 'Armado de puentes', 2, NULL, true),
        (p_org, v_linea_dolly, 'principal', 2, 'Armado de cuadro', 2, NULL, true),
        (p_org, v_linea_dolly, 'principal', 3, 'Perchas y platos', 2, NULL, true),
        (p_org, v_linea_dolly, 'principal', 4, 'Portaloderas y lanza', 2, NULL, true),
        (p_org, v_linea_dolly, 'principal', 5, 'Retráctil y ejes', 2, NULL, true),
        (p_org, v_linea_dolly, 'principal', 6, 'Escoreado y lavado', 2, NULL, true),
        (p_org, v_linea_dolly, 'principal', 7, 'Primer', 2, NULL, true),
        (p_org, v_linea_dolly, 'principal', 8, 'Pintura', 2, NULL, true),
        (p_org, v_linea_dolly, 'principal', 9, 'Luz', 2, NULL, true),
        (p_org, v_linea_dolly, 'principal', 10, 'Aire', 2, NULL, true)
    ON CONFLICT (linea_producto_id, grupo, orden) 
    DO UPDATE SET 
        nombre = EXCLUDED.nombre,
        activo = EXCLUDED.activo,
        requiere_grupo = EXCLUDED.requiere_grupo;

    -- 6. Fases de Traila (grupo principal, 11 fases)
    INSERT INTO fases_produccion (organizacion_id, linea_producto_id, grupo, orden, nombre, duracion_dias, requiere_grupo, activo)
    VALUES
        (p_org, v_linea_traila, 'principal', 1, 'Armado de cuadro', 2, NULL, true),
        (p_org, v_linea_traila, 'principal', 2, 'Ensamble de travesaños', 2, NULL, true),
        (p_org, v_linea_traila, 'principal', 3, 'Ensamble de ejes', 2, NULL, true),
        (p_org, v_linea_traila, 'principal', 4, 'Ensamble de pasamanos', 2, NULL, true),
        (p_org, v_linea_traila, 'principal', 5, 'Ensamble de lanza', 2, NULL, true),
        (p_org, v_linea_traila, 'principal', 6, 'Puerta o tapa', 2, NULL, true),
        (p_org, v_linea_traila, 'principal', 7, 'Acabados', 2, NULL, true),
        (p_org, v_linea_traila, 'principal', 8, 'Primer', 2, NULL, true),
        (p_org, v_linea_traila, 'principal', 9, 'Pintura', 2, NULL, true),
        (p_org, v_linea_traila, 'principal', 10, 'Luz', 2, NULL, true),
        (p_org, v_linea_traila, 'principal', 11, 'Piso', 2, NULL, true)
    ON CONFLICT (linea_producto_id, grupo, orden) 
    DO UPDATE SET 
        nombre = EXCLUDED.nombre,
        activo = EXCLUDED.activo,
        requiere_grupo = EXCLUDED.requiere_grupo;
END;
$$;

REVOKE ALL ON FUNCTION sembrar_tablero_produccion(UUID) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION sembrar_tablero_produccion(UUID) TO service_role;

-- 7. Helper RPC crear_fases_orden(p_org UUID, p_orden UUID)
CREATE OR REPLACE FUNCTION crear_fases_orden(p_org UUID, p_orden UUID)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_linea_id UUID;
    v_creadas INTEGER := 0;
BEGIN
    SELECT linea_producto_id INTO v_linea_id
    FROM ordenes_trabajo
    WHERE id = p_orden AND organizacion_id = p_org;

    IF v_linea_id IS NULL THEN
        RETURN 0;
    END IF;

    INSERT INTO orden_fases (
        organizacion_id,
        orden_trabajo_id,
        fase_id,
        estado,
        fecha_propuesta,
        fecha_inicio,
        fecha_fin,
        nota
    )
    SELECT 
        p_org,
        p_orden,
        fp.id,
        'pendiente',
        NULL,
        NULL,
        NULL,
        NULL
    FROM fases_produccion fp
    WHERE fp.linea_producto_id = v_linea_id
      AND fp.activo = true
    ON CONFLICT (orden_trabajo_id, fase_id) DO NOTHING;

    GET DIAGNOSTICS v_creadas = ROW_COUNT;
    RETURN v_creadas;
END;
$$;

REVOKE ALL ON FUNCTION crear_fases_orden(UUID, UUID) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION crear_fases_orden(UUID, UUID) TO service_role;

-- 8. Trigger para derivar estado, estado_kanban, fase_actual_id, fecha_inicio y fecha_fin en ordenes_trabajo
CREATE OR REPLACE FUNCTION fn_recalcular_orden_trabajo()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_orden_id UUID;
    v_org_id UUID;
    v_estado_actual TEXT;
    
    v_total_fases INTEGER := 0;
    v_terminadas INTEGER := 0;
    v_incompletas INTEGER := 0;
    v_pausadas INTEGER := 0;
    v_en_proceso INTEGER := 0;
    v_iniciadas INTEGER := 0;
    
    v_nuevo_estado_kanban TEXT;
    v_nueva_fase_actual_id UUID := NULL;
    v_nuevo_estado TEXT;
    v_min_fecha_inicio TIMESTAMPTZ := NULL;
    v_max_fecha_fin TIMESTAMPTZ := NULL;
BEGIN
    IF TG_OP = 'DELETE' THEN
        v_orden_id := OLD.orden_trabajo_id;
        v_org_id := OLD.organizacion_id;
    ELSE
        v_orden_id := NEW.orden_trabajo_id;
        v_org_id := NEW.organizacion_id;
    END IF;

    -- Consultar estado actual de la orden
    SELECT estado INTO v_estado_actual
    FROM ordenes_trabajo
    WHERE id = v_orden_id AND organizacion_id = v_org_id;

    IF NOT FOUND THEN
        RETURN NULL;
    END IF;

    -- Conteo de estados de fases asociadas activas
    SELECT 
        COUNT(*),
        COUNT(*) FILTER (WHERE ofs.estado = 'terminada'),
        COUNT(*) FILTER (WHERE ofs.estado = 'incompleta'),
        COUNT(*) FILTER (WHERE ofs.estado = 'pausada'),
        COUNT(*) FILTER (WHERE ofs.estado = 'en_proceso'),
        COUNT(*) FILTER (WHERE ofs.fecha_inicio IS NOT NULL OR ofs.estado IN ('en_proceso', 'incompleta', 'pausada', 'terminada')),
        MIN(ofs.fecha_inicio),
        MAX(ofs.fecha_fin)
    INTO 
        v_total_fases,
        v_terminadas,
        v_incompletas,
        v_pausadas,
        v_en_proceso,
        v_iniciadas,
        v_min_fecha_inicio,
        v_max_fecha_fin
    FROM orden_fases ofs
    JOIN fases_produccion fp ON fp.id = ofs.fase_id
    WHERE ofs.orden_trabajo_id = v_orden_id
      AND fp.activo = true;

    -- 1. Derivar estado_kanban:
    -- completada si todas las fases están terminadas (y hay al menos 1 fase)
    -- si no, por prioridad: incompleta > pausada > en_proceso > pendiente
    IF v_total_fases > 0 AND v_terminadas = v_total_fases THEN
        v_nuevo_estado_kanban := 'completada';
    ELSIF v_incompletas > 0 THEN
        v_nuevo_estado_kanban := 'incompleta';
    ELSIF v_pausadas > 0 THEN
        v_nuevo_estado_kanban := 'pausada';
    ELSIF v_en_proceso > 0 THEN
        v_nuevo_estado_kanban := 'en_proceso';
    ELSE
        v_nuevo_estado_kanban := 'pendiente';
    END IF;

    -- 2. Derivar fase_actual_id:
    -- La primera fase principal (por orden ASC) con estado en_proceso, incompleta o pausada; si no hay ninguna, NULL
    SELECT ofs.fase_id INTO v_nueva_fase_actual_id
    FROM orden_fases ofs
    JOIN fases_produccion fp ON fp.id = ofs.fase_id
    WHERE ofs.orden_trabajo_id = v_orden_id
      AND fp.grupo = 'principal'
      AND fp.activo = true
      AND ofs.estado IN ('en_proceso', 'incompleta', 'pausada')
    ORDER BY fp.orden ASC
    LIMIT 1;

    -- 3. Derivar estado:
    -- Si está Liberado, NUNCA se toca
    -- Terminado cuando todas estén terminadas
    -- En Producción mientras haya al menos una iniciada
    -- Pendiente mientras ninguna haya iniciado
    IF v_estado_actual = 'Liberado' THEN
        v_nuevo_estado := 'Liberado';
    ELSIF v_total_fases > 0 AND v_terminadas = v_total_fases THEN
        v_nuevo_estado := 'Terminado';
    ELSIF v_iniciadas > 0 THEN
        v_nuevo_estado := 'En Producción';
    ELSE
        v_nuevo_estado := 'Pendiente';
    END IF;

    -- 4. Derivar fecha_fin:
    -- Se establece cuando todo queda terminado; si se reabre alguna fase o no está todo terminado, NULL
    IF v_total_fases > 0 AND v_terminadas = v_total_fases THEN
        IF v_max_fecha_fin IS NULL THEN
            v_max_fecha_fin := timezone('utc', now());
        END IF;
    ELSE
        v_max_fecha_fin := NULL;
    END IF;

    -- Actualizar ordenes_trabajo
    UPDATE ordenes_trabajo
    SET estado_kanban = v_nuevo_estado_kanban,
        fase_actual_id = v_nueva_fase_actual_id,
        estado = v_nuevo_estado,
        fecha_inicio = v_min_fecha_inicio,
        fecha_fin = v_max_fecha_fin
    WHERE id = v_orden_id AND organizacion_id = v_org_id;

    RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS trg_recalcular_orden_fases ON orden_fases;
CREATE TRIGGER trg_recalcular_orden_fases
AFTER INSERT OR UPDATE OR DELETE ON orden_fases
FOR EACH ROW
EXECUTE FUNCTION fn_recalcular_orden_trabajo();

-- 9. RPC actualizar_fase_orden
CREATE OR REPLACE FUNCTION actualizar_fase_orden(
    p_org UUID,
    p_orden UUID,
    p_fase UUID,
    p_estado TEXT,
    p_fecha_propuesta DATE,
    p_nota TEXT,
    p_usuario UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
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
    -- 1. Validar estado válido
    IF p_estado NOT IN ('pendiente', 'en_proceso', 'incompleta', 'pausada', 'terminada') THEN
        RAISE EXCEPTION 'estado_invalido: El estado % no es válido', p_estado
            USING ERRCODE = '22023';
    END IF;

    -- 2. Bloquear y verificar orden (FOR UPDATE sobre la orden)
    SELECT * INTO r_orden
    FROM ordenes_trabajo
    WHERE id = p_orden AND organizacion_id = p_org
    FOR UPDATE;

    IF r_orden.id IS NULL THEN
        RAISE EXCEPTION 'orden_no_encontrada: La orden no existe o no pertenece a la organización'
            USING ERRCODE = 'P0002';
    END IF;

    -- 3. Verificar que la fase pertenezca a la línea de la orden
    SELECT * INTO r_fase
    FROM fases_produccion
    WHERE id = p_fase 
      AND linea_producto_id = r_orden.linea_producto_id
      AND organizacion_id = p_org;

    IF r_fase.id IS NULL THEN
        RAISE EXCEPTION 'fase_no_pertenece_a_linea: La fase no pertenece a la línea de producción de esta orden'
            USING ERRCODE = '23503';
    END IF;

    -- 4. Obtener registro actual de orden_fases si existe
    SELECT * INTO r_ord_fase
    FROM orden_fases
    WHERE orden_trabajo_id = p_orden AND fase_id = p_fase;

    -- 5. Calcular fechas y notas según estado
    v_fecha_inicio := r_ord_fase.fecha_inicio;
    v_fecha_fin := r_ord_fase.fecha_fin;
    v_calc_fecha_propuesta := COALESCE(p_fecha_propuesta, r_ord_fase.fecha_propuesta);
    v_nota := COALESCE(p_nota, r_ord_fase.nota);

    IF p_estado = 'en_proceso' THEN
        v_fecha_inicio := COALESCE(r_ord_fase.fecha_inicio, timezone('utc', now()));
        v_fecha_fin := NULL;
        IF v_calc_fecha_propuesta IS NULL THEN
            -- current_date en America/Mexico_City + duracion_dias
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

    -- 6. Upsert en orden_fases
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

    -- 7. Historial de fases (solo si cambió estado o fecha_propuesta)
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

    -- 8. Validar avisos por requiere_grupo (sin bloquear)
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

    -- 9. Consultar datos finales actualizados
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

-- 10. Respaldo / Backfill idempotente
DO $$
DECLARE
    r_org RECORD;
    r_ord RECORD;
    v_linea_id UUID;
    v_linea_clave TEXT;
    v_tipo TEXT;
    v_fase_propuesta DATE;
    v_duracion INT;
BEGIN
    -- 1. Sembrar líneas y fases en todas las organizaciones existentes
    FOR r_org IN SELECT id FROM organizaciones LOOP
        PERFORM sembrar_tablero_produccion(r_org.id);
    END LOOP;

    -- 2. Limpiar líneas legacy que no sean ('plataforma', 'gondola', 'dolly', 'traila')
    -- Reasignar órdenes que apunten a líneas legacy o que tengan linea_producto_id nulo
    FOR r_ord IN 
        SELECT ot.id, ot.organizacion_id, ot.tipo_equipo, ot.linea_producto_id
        FROM ordenes_trabajo ot
        LEFT JOIN lineas_producto lp ON lp.id = ot.linea_producto_id
        WHERE ot.linea_producto_id IS NULL OR lp.clave NOT IN ('plataforma', 'gondola', 'dolly', 'traila')
    LOOP
        v_tipo := LOWER(COALESCE(r_ord.tipo_equipo, ''));
        IF v_tipo LIKE '%dolly%' OR v_tipo = '02' THEN
            v_linea_clave := 'dolly';
        ELSIF v_tipo LIKE '%gondola%' OR v_tipo LIKE '%góndola%' OR v_tipo = '03' THEN
            v_linea_clave := 'gondola';
        ELSIF v_tipo LIKE '%traila%' OR v_tipo = '09' THEN
            v_linea_clave := 'traila';
        ELSE
            v_linea_clave := 'plataforma';
        END IF;

        SELECT id INTO v_linea_id
        FROM lineas_producto
        WHERE organizacion_id = r_ord.organizacion_id AND clave = v_linea_clave;

        UPDATE ordenes_trabajo
        SET linea_producto_id = v_linea_id
        WHERE id = r_ord.id;
    END LOOP;

    -- Eliminar líneas legacy que no tengan órdenes asociadas
    DELETE FROM lineas_producto
    WHERE clave NOT IN ('plataforma', 'gondola', 'dolly', 'traila');

    -- 3. Crear orden_fases para todas las órdenes de trabajo existentes
    FOR r_ord IN 
        SELECT id, organizacion_id, fase_actual_id 
        FROM ordenes_trabajo 
        WHERE linea_producto_id IS NOT NULL 
    LOOP
        PERFORM crear_fases_orden(r_ord.organizacion_id, r_ord.id);

        -- Si la orden tenía fase_actual_id y la fase está en pendiente, ponerla en proceso
        IF r_ord.fase_actual_id IS NOT NULL THEN
            SELECT duracion_dias INTO v_duracion 
            FROM fases_produccion 
            WHERE id = r_ord.fase_actual_id;

            v_fase_propuesta := (timezone('America/Mexico_City', now())::date + COALESCE(v_duracion, 2));

            UPDATE orden_fases
            SET estado = 'en_proceso',
                fecha_inicio = COALESCE(fecha_inicio, timezone('utc', now())),
                fecha_propuesta = COALESCE(fecha_propuesta, v_fase_propuesta)
            WHERE orden_trabajo_id = r_ord.id 
              AND fase_id = r_ord.fase_actual_id
              AND estado = 'pendiente';
        END IF;
    END LOOP;
END $$;

COMMIT;
