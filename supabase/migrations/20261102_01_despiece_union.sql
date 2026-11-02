-- Migración 20261102_01_despiece_union.sql
-- T2 (Turno Noche 2026-11-02): Despiece por fases desde UNION DE LISTADOS ACTULIZADO (1).xlsx
-- 1. Catálogo oficial de fases_despiece (14 fases: Paso 1..12, Extras, Llantas/Rines)
-- 2. Tabla de equivalencias fases_despiece_equivalencias
-- 3. Adición de columna fase_id a receta_base y opcion_componentes
-- 4. Mapeo e inserción de nuevos materiales sin costo / con costo sin pisar existentes
-- 5. Notas: 'import-union-2026-11'

BEGIN;


-- 1. Tablas del catálogo de fases y equivalencias
CREATE TABLE IF NOT EXISTS fases_despiece (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organizacion_id UUID NOT NULL REFERENCES organizaciones(id) ON DELETE CASCADE,
    clave TEXT NOT NULL,
    nombre TEXT NOT NULL,
    subtitulo TEXT,
    orden INTEGER NOT NULL,
    descripcion TEXT,
    activo BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_fases_despiece_org_clave UNIQUE (organizacion_id, clave)
);

ALTER TABLE fases_despiece ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "fases_despiece_org_select" ON fases_despiece;
CREATE POLICY "fases_despiece_org_select" ON fases_despiece
    FOR SELECT TO authenticated
    USING (organizacion_id = (SELECT organizacion_id FROM usuarios WHERE id = auth.uid()));

DROP POLICY IF EXISTS "fases_despiece_org_all" ON fases_despiece;
CREATE POLICY "fases_despiece_org_all" ON fases_despiece
    FOR ALL TO authenticated
    USING (organizacion_id = (SELECT organizacion_id FROM usuarios WHERE id = auth.uid()))
    WITH CHECK (organizacion_id = (SELECT organizacion_id FROM usuarios WHERE id = auth.uid()));

CREATE TABLE IF NOT EXISTS fases_despiece_equivalencias (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organizacion_id UUID NOT NULL REFERENCES organizaciones(id) ON DELETE CASCADE,
    paso_legacy TEXT NOT NULL,
    fase_id UUID NOT NULL REFERENCES fases_despiece(id) ON DELETE CASCADE,
    notas TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_fases_equivalencias_org_legacy UNIQUE (organizacion_id, paso_legacy)
);

ALTER TABLE fases_despiece_equivalencias ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "fases_equivalencias_org_select" ON fases_despiece_equivalencias;
CREATE POLICY "fases_equivalencias_org_select" ON fases_despiece_equivalencias
    FOR SELECT TO authenticated
    USING (organizacion_id = (SELECT organizacion_id FROM usuarios WHERE id = auth.uid()));

DROP POLICY IF EXISTS "fases_equivalencias_org_all" ON fases_despiece_equivalencias;
CREATE POLICY "fases_equivalencias_org_all" ON fases_despiece_equivalencias
    FOR ALL TO authenticated
    USING (organizacion_id = (SELECT organizacion_id FROM usuarios WHERE id = auth.uid()))
    WITH CHECK (organizacion_id = (SELECT organizacion_id FROM usuarios WHERE id = auth.uid()));

-- 2. Vincular columna fase_id en receta_base y opcion_componentes
ALTER TABLE receta_base ADD COLUMN IF NOT EXISTS fase_id UUID REFERENCES fases_despiece(id);
ALTER TABLE opcion_componentes ADD COLUMN IF NOT EXISTS fase_id UUID REFERENCES fases_despiece(id);


DO $$
DECLARE
    r_org RECORD;
    v_fase_id UUID;
    v_mat_id TEXT;
BEGIN
    FOR r_org IN SELECT id FROM organizaciones LOOP
        -- A. Poblar fases_despiece

        INSERT INTO fases_despiece (organizacion_id, clave, nombre, subtitulo, orden, descripcion, activo)
        VALUES (r_org.id, 'paso_1', 'Paso 1', 'Armado y corte de almas', 1, 'Corte de placa de grado A-50 y ensamblado de viga principal', true)
        ON CONFLICT (organizacion_id, clave) DO UPDATE SET
            nombre = EXCLUDED.nombre,
            subtitulo = EXCLUDED.subtitulo,
            orden = EXCLUDED.orden,
            descripcion = EXCLUDED.descripcion,
            updated_at = now();

        INSERT INTO fases_despiece (organizacion_id, clave, nombre, subtitulo, orden, descripcion, activo)
        VALUES (r_org.id, 'paso_2', 'Paso 2', 'Soleras de refuerzo de almas', 2, 'Soldadura y unión de soleras A-529 de 1/2" x 6"', true)
        ON CONFLICT (organizacion_id, clave) DO UPDATE SET
            nombre = EXCLUDED.nombre,
            subtitulo = EXCLUDED.subtitulo,
            orden = EXCLUDED.orden,
            descripcion = EXCLUDED.descripcion,
            updated_at = now();

        INSERT INTO fases_despiece (organizacion_id, clave, nombre, subtitulo, orden, descripcion, activo)
        VALUES (r_org.id, 'paso_3', 'Paso 3', 'Estructura primaria, bordas y plancha de quinta rueda', 3, 'Bordas delantera/trasera, perno rey Holland, plancha de 3/8" y puentes', true)
        ON CONFLICT (organizacion_id, clave) DO UPDATE SET
            nombre = EXCLUDED.nombre,
            subtitulo = EXCLUDED.subtitulo,
            orden = EXCLUDED.orden,
            descripcion = EXCLUDED.descripcion,
            updated_at = now();

        INSERT INTO fases_despiece (organizacion_id, clave, nombre, subtitulo, orden, descripcion, activo)
        VALUES (r_org.id, 'paso_4', 'Paso 4', 'Cargadores transversales IPR y atizadores', 4, 'Cargadores IPR de 4" x 102", bordas laterales y atizadores', true)
        ON CONFLICT (organizacion_id, clave) DO UPDATE SET
            nombre = EXCLUDED.nombre,
            subtitulo = EXCLUDED.subtitulo,
            orden = EXCLUDED.orden,
            descripcion = EXCLUDED.descripcion,
            updated_at = now();

        INSERT INTO fases_despiece (organizacion_id, clave, nombre, subtitulo, orden, descripcion, activo)
        VALUES (r_org.id, 'paso_5', 'Paso 5', 'Instalación de suspensión, patines, ejes y retráctiles', 5, 'Ensamble de suspensión neumática/mecánica, patines y ejes', true)
        ON CONFLICT (organizacion_id, clave) DO UPDATE SET
            nombre = EXCLUDED.nombre,
            subtitulo = EXCLUDED.subtitulo,
            orden = EXCLUDED.orden,
            descripcion = EXCLUDED.descripcion,
            updated_at = now();

        INSERT INTO fases_despiece (organizacion_id, clave, nombre, subtitulo, orden, descripcion, activo)
        VALUES (r_org.id, 'paso_6', 'Paso 6', 'Canaleta, refuerzos y accesorios estructurales', 6, 'Caja de herramientas, bases de ABS, cinchos y accesorios', true)
        ON CONFLICT (organizacion_id, clave) DO UPDATE SET
            nombre = EXCLUDED.nombre,
            subtitulo = EXCLUDED.subtitulo,
            orden = EXCLUDED.orden,
            descripcion = EXCLUDED.descripcion,
            updated_at = now();

        INSERT INTO fases_despiece (organizacion_id, clave, nombre, subtitulo, orden, descripcion, activo)
        VALUES (r_org.id, 'paso_7', 'PASO 7', 'Lavado químico, fosfato y preparación de superficie', 7, 'Desengrasado, fosfatado y limpieza profunda previa a pintura', true)
        ON CONFLICT (organizacion_id, clave) DO UPDATE SET
            nombre = EXCLUDED.nombre,
            subtitulo = EXCLUDED.subtitulo,
            orden = EXCLUDED.orden,
            descripcion = EXCLUDED.descripcion,
            updated_at = now();

        INSERT INTO fases_despiece (organizacion_id, clave, nombre, subtitulo, orden, descripcion, activo)
        VALUES (r_org.id, 'paso_8', 'PASO 8', 'Aplicación de pintura y recubrimientos por marca', 8, 'Aplicación de fondo anticorrosivo y esmalte poliuretano', true)
        ON CONFLICT (organizacion_id, clave) DO UPDATE SET
            nombre = EXCLUDED.nombre,
            subtitulo = EXCLUDED.subtitulo,
            orden = EXCLUDED.orden,
            descripcion = EXCLUDED.descripcion,
            updated_at = now();

        INSERT INTO fases_despiece (organizacion_id, clave, nombre, subtitulo, orden, descripcion, activo)
        VALUES (r_org.id, 'paso_9', 'PASO 9', 'Kit neumático, sistema ABS y tanques de aire', 9, 'Instalación de tubería, mangueras, válvulas, tanques y arnés ABS', true)
        ON CONFLICT (organizacion_id, clave) DO UPDATE SET
            nombre = EXCLUDED.nombre,
            subtitulo = EXCLUDED.subtitulo,
            orden = EXCLUDED.orden,
            descripcion = EXCLUDED.descripcion,
            updated_at = now();

        INSERT INTO fases_despiece (organizacion_id, clave, nombre, subtitulo, orden, descripcion, activo)
        VALUES (r_org.id, 'paso_10', 'PASO 10', 'Sistema de iluminación reglamentaria y arnés eléctrico', 10, 'Colocación de plafones LED reglamentarios, arnés sellado y cableado', true)
        ON CONFLICT (organizacion_id, clave) DO UPDATE SET
            nombre = EXCLUDED.nombre,
            subtitulo = EXCLUDED.subtitulo,
            orden = EXCLUDED.orden,
            descripcion = EXCLUDED.descripcion,
            updated_at = now();

        INSERT INTO fases_despiece (organizacion_id, clave, nombre, subtitulo, orden, descripcion, activo)
        VALUES (r_org.id, 'paso_11', 'PASO 11', 'Instalación de pisos y fijaciones', 11, 'Instalación de piso de plástico, madera o pino con pijas fijadoras', true)
        ON CONFLICT (organizacion_id, clave) DO UPDATE SET
            nombre = EXCLUDED.nombre,
            subtitulo = EXCLUDED.subtitulo,
            orden = EXCLUDED.orden,
            descripcion = EXCLUDED.descripcion,
            updated_at = now();

        INSERT INTO fases_despiece (organizacion_id, clave, nombre, subtitulo, orden, descripcion, activo)
        VALUES (r_org.id, 'paso_12', 'PASO 12', 'Acabados, loderas, winches y rotulación final', 12, 'Colocación de loderas Leolca, cinta reflejante, winches y placa de serie', true)
        ON CONFLICT (organizacion_id, clave) DO UPDATE SET
            nombre = EXCLUDED.nombre,
            subtitulo = EXCLUDED.subtitulo,
            orden = EXCLUDED.orden,
            descripcion = EXCLUDED.descripcion,
            updated_at = now();

        INSERT INTO fases_despiece (organizacion_id, clave, nombre, subtitulo, orden, descripcion, activo)
        VALUES (r_org.id, 'extras', 'EXTRAS', 'Equipamiento adicional (redilas, retráctil Leolca, multimodal)', 13, 'Accesorios opcionales para configuraciones especiales', true)
        ON CONFLICT (organizacion_id, clave) DO UPDATE SET
            nombre = EXCLUDED.nombre,
            subtitulo = EXCLUDED.subtitulo,
            orden = EXCLUDED.orden,
            descripcion = EXCLUDED.descripcion,
            updated_at = now();

        INSERT INTO fases_despiece (organizacion_id, clave, nombre, subtitulo, orden, descripcion, activo)
        VALUES (r_org.id, 'llantas_rines', 'LLANTAS Y RINES', 'Juego de rodado (rines de acero/aluminio y llantas)', 14, 'Montaje de rines de 22.5" / 24.5" y neumáticos', true)
        ON CONFLICT (organizacion_id, clave) DO UPDATE SET
            nombre = EXCLUDED.nombre,
            subtitulo = EXCLUDED.subtitulo,
            orden = EXCLUDED.orden,
            descripcion = EXCLUDED.descripcion,
            updated_at = now();


        -- B. Poblar fases_despiece_equivalencias

        SELECT id INTO v_fase_id FROM fases_despiece WHERE organizacion_id = r_org.id AND clave = 'paso_1';
        IF v_fase_id IS NOT NULL THEN
            INSERT INTO fases_despiece_equivalencias (organizacion_id, paso_legacy, fase_id, notas)
            VALUES (r_org.id, 'PASO 1', v_fase_id, 'Equivalencia estándar Paso 1')
            ON CONFLICT (organizacion_id, paso_legacy) DO UPDATE SET
                fase_id = EXCLUDED.fase_id,
                notas = EXCLUDED.notas;
        END IF;

        SELECT id INTO v_fase_id FROM fases_despiece WHERE organizacion_id = r_org.id AND clave = 'paso_2';
        IF v_fase_id IS NOT NULL THEN
            INSERT INTO fases_despiece_equivalencias (organizacion_id, paso_legacy, fase_id, notas)
            VALUES (r_org.id, 'PASO 2', v_fase_id, 'Equivalencia estándar Paso 2')
            ON CONFLICT (organizacion_id, paso_legacy) DO UPDATE SET
                fase_id = EXCLUDED.fase_id,
                notas = EXCLUDED.notas;
        END IF;

        SELECT id INTO v_fase_id FROM fases_despiece WHERE organizacion_id = r_org.id AND clave = 'paso_3';
        IF v_fase_id IS NOT NULL THEN
            INSERT INTO fases_despiece_equivalencias (organizacion_id, paso_legacy, fase_id, notas)
            VALUES (r_org.id, 'PASO 3', v_fase_id, 'Equivalencia estándar Paso 3')
            ON CONFLICT (organizacion_id, paso_legacy) DO UPDATE SET
                fase_id = EXCLUDED.fase_id,
                notas = EXCLUDED.notas;
        END IF;

        SELECT id INTO v_fase_id FROM fases_despiece WHERE organizacion_id = r_org.id AND clave = 'paso_4';
        IF v_fase_id IS NOT NULL THEN
            INSERT INTO fases_despiece_equivalencias (organizacion_id, paso_legacy, fase_id, notas)
            VALUES (r_org.id, 'PASO 4', v_fase_id, 'Equivalencia estándar Paso 4')
            ON CONFLICT (organizacion_id, paso_legacy) DO UPDATE SET
                fase_id = EXCLUDED.fase_id,
                notas = EXCLUDED.notas;
        END IF;

        SELECT id INTO v_fase_id FROM fases_despiece WHERE organizacion_id = r_org.id AND clave = 'paso_5';
        IF v_fase_id IS NOT NULL THEN
            INSERT INTO fases_despiece_equivalencias (organizacion_id, paso_legacy, fase_id, notas)
            VALUES (r_org.id, 'PASO 5', v_fase_id, 'Equivalencia estándar Paso 5')
            ON CONFLICT (organizacion_id, paso_legacy) DO UPDATE SET
                fase_id = EXCLUDED.fase_id,
                notas = EXCLUDED.notas;
        END IF;

        SELECT id INTO v_fase_id FROM fases_despiece WHERE organizacion_id = r_org.id AND clave = 'paso_6';
        IF v_fase_id IS NOT NULL THEN
            INSERT INTO fases_despiece_equivalencias (organizacion_id, paso_legacy, fase_id, notas)
            VALUES (r_org.id, 'PASO 6', v_fase_id, 'Equivalencia estándar Paso 6')
            ON CONFLICT (organizacion_id, paso_legacy) DO UPDATE SET
                fase_id = EXCLUDED.fase_id,
                notas = EXCLUDED.notas;
        END IF;

        SELECT id INTO v_fase_id FROM fases_despiece WHERE organizacion_id = r_org.id AND clave = 'paso_7';
        IF v_fase_id IS NOT NULL THEN
            INSERT INTO fases_despiece_equivalencias (organizacion_id, paso_legacy, fase_id, notas)
            VALUES (r_org.id, 'PASO 7', v_fase_id, 'Equivalencia estándar Paso 7')
            ON CONFLICT (organizacion_id, paso_legacy) DO UPDATE SET
                fase_id = EXCLUDED.fase_id,
                notas = EXCLUDED.notas;
        END IF;

        SELECT id INTO v_fase_id FROM fases_despiece WHERE organizacion_id = r_org.id AND clave = 'paso_8';
        IF v_fase_id IS NOT NULL THEN
            INSERT INTO fases_despiece_equivalencias (organizacion_id, paso_legacy, fase_id, notas)
            VALUES (r_org.id, 'PASO 8', v_fase_id, 'Equivalencia estándar Paso 8')
            ON CONFLICT (organizacion_id, paso_legacy) DO UPDATE SET
                fase_id = EXCLUDED.fase_id,
                notas = EXCLUDED.notas;
        END IF;

        SELECT id INTO v_fase_id FROM fases_despiece WHERE organizacion_id = r_org.id AND clave = 'paso_8';
        IF v_fase_id IS NOT NULL THEN
            INSERT INTO fases_despiece_equivalencias (organizacion_id, paso_legacy, fase_id, notas)
            VALUES (r_org.id, 'PINTURA', v_fase_id, 'Equivalencia histórica pintura -> Paso 8')
            ON CONFLICT (organizacion_id, paso_legacy) DO UPDATE SET
                fase_id = EXCLUDED.fase_id,
                notas = EXCLUDED.notas;
        END IF;

        SELECT id INTO v_fase_id FROM fases_despiece WHERE organizacion_id = r_org.id AND clave = 'paso_9';
        IF v_fase_id IS NOT NULL THEN
            INSERT INTO fases_despiece_equivalencias (organizacion_id, paso_legacy, fase_id, notas)
            VALUES (r_org.id, 'PASO 9', v_fase_id, 'Equivalencia estándar Paso 9')
            ON CONFLICT (organizacion_id, paso_legacy) DO UPDATE SET
                fase_id = EXCLUDED.fase_id,
                notas = EXCLUDED.notas;
        END IF;

        SELECT id INTO v_fase_id FROM fases_despiece WHERE organizacion_id = r_org.id AND clave = 'paso_9';
        IF v_fase_id IS NOT NULL THEN
            INSERT INTO fases_despiece_equivalencias (organizacion_id, paso_legacy, fase_id, notas)
            VALUES (r_org.id, 'AIRE', v_fase_id, 'Equivalencia histórica aire -> Paso 9')
            ON CONFLICT (organizacion_id, paso_legacy) DO UPDATE SET
                fase_id = EXCLUDED.fase_id,
                notas = EXCLUDED.notas;
        END IF;

        SELECT id INTO v_fase_id FROM fases_despiece WHERE organizacion_id = r_org.id AND clave = 'paso_10';
        IF v_fase_id IS NOT NULL THEN
            INSERT INTO fases_despiece_equivalencias (organizacion_id, paso_legacy, fase_id, notas)
            VALUES (r_org.id, 'PASO 10', v_fase_id, 'Equivalencia estándar Paso 10')
            ON CONFLICT (organizacion_id, paso_legacy) DO UPDATE SET
                fase_id = EXCLUDED.fase_id,
                notas = EXCLUDED.notas;
        END IF;

        SELECT id INTO v_fase_id FROM fases_despiece WHERE organizacion_id = r_org.id AND clave = 'paso_10';
        IF v_fase_id IS NOT NULL THEN
            INSERT INTO fases_despiece_equivalencias (organizacion_id, paso_legacy, fase_id, notas)
            VALUES (r_org.id, 'LUZ', v_fase_id, 'Equivalencia histórica luz -> Paso 10')
            ON CONFLICT (organizacion_id, paso_legacy) DO UPDATE SET
                fase_id = EXCLUDED.fase_id,
                notas = EXCLUDED.notas;
        END IF;

        SELECT id INTO v_fase_id FROM fases_despiece WHERE organizacion_id = r_org.id AND clave = 'paso_11';
        IF v_fase_id IS NOT NULL THEN
            INSERT INTO fases_despiece_equivalencias (organizacion_id, paso_legacy, fase_id, notas)
            VALUES (r_org.id, 'PASO 11', v_fase_id, 'Equivalencia estándar Paso 11')
            ON CONFLICT (organizacion_id, paso_legacy) DO UPDATE SET
                fase_id = EXCLUDED.fase_id,
                notas = EXCLUDED.notas;
        END IF;

        SELECT id INTO v_fase_id FROM fases_despiece WHERE organizacion_id = r_org.id AND clave = 'paso_11';
        IF v_fase_id IS NOT NULL THEN
            INSERT INTO fases_despiece_equivalencias (organizacion_id, paso_legacy, fase_id, notas)
            VALUES (r_org.id, 'PISOS', v_fase_id, 'Equivalencia histórica pisos -> Paso 11')
            ON CONFLICT (organizacion_id, paso_legacy) DO UPDATE SET
                fase_id = EXCLUDED.fase_id,
                notas = EXCLUDED.notas;
        END IF;

        SELECT id INTO v_fase_id FROM fases_despiece WHERE organizacion_id = r_org.id AND clave = 'paso_12';
        IF v_fase_id IS NOT NULL THEN
            INSERT INTO fases_despiece_equivalencias (organizacion_id, paso_legacy, fase_id, notas)
            VALUES (r_org.id, 'PASO 12', v_fase_id, 'Equivalencia estándar Paso 12')
            ON CONFLICT (organizacion_id, paso_legacy) DO UPDATE SET
                fase_id = EXCLUDED.fase_id,
                notas = EXCLUDED.notas;
        END IF;

        SELECT id INTO v_fase_id FROM fases_despiece WHERE organizacion_id = r_org.id AND clave = 'paso_12';
        IF v_fase_id IS NOT NULL THEN
            INSERT INTO fases_despiece_equivalencias (organizacion_id, paso_legacy, fase_id, notas)
            VALUES (r_org.id, 'TERMINADO', v_fase_id, 'Equivalencia histórica terminado -> Paso 12')
            ON CONFLICT (organizacion_id, paso_legacy) DO UPDATE SET
                fase_id = EXCLUDED.fase_id,
                notas = EXCLUDED.notas;
        END IF;

        SELECT id INTO v_fase_id FROM fases_despiece WHERE organizacion_id = r_org.id AND clave = 'extras';
        IF v_fase_id IS NOT NULL THEN
            INSERT INTO fases_despiece_equivalencias (organizacion_id, paso_legacy, fase_id, notas)
            VALUES (r_org.id, 'EXTRAS', v_fase_id, 'Equivalencia histórica extras -> Extras')
            ON CONFLICT (organizacion_id, paso_legacy) DO UPDATE SET
                fase_id = EXCLUDED.fase_id,
                notas = EXCLUDED.notas;
        END IF;

        SELECT id INTO v_fase_id FROM fases_despiece WHERE organizacion_id = r_org.id AND clave = 'llantas_rines';
        IF v_fase_id IS NOT NULL THEN
            INSERT INTO fases_despiece_equivalencias (organizacion_id, paso_legacy, fase_id, notas)
            VALUES (r_org.id, 'LLANTAS Y RINES', v_fase_id, 'Equivalencia estándar Llantas y Rines')
            ON CONFLICT (organizacion_id, paso_legacy) DO UPDATE SET
                fase_id = EXCLUDED.fase_id,
                notas = EXCLUDED.notas;
        END IF;

        SELECT id INTO v_fase_id FROM fases_despiece WHERE organizacion_id = r_org.id AND clave = 'llantas_rines';
        IF v_fase_id IS NOT NULL THEN
            INSERT INTO fases_despiece_equivalencias (organizacion_id, paso_legacy, fase_id, notas)
            VALUES (r_org.id, 'LLANTAS', v_fase_id, 'Equivalencia histórica llantas -> Llantas y Rines')
            ON CONFLICT (organizacion_id, paso_legacy) DO UPDATE SET
                fase_id = EXCLUDED.fase_id,
                notas = EXCLUDED.notas;
        END IF;

        SELECT id INTO v_fase_id FROM fases_despiece WHERE organizacion_id = r_org.id AND clave = 'llantas_rines';
        IF v_fase_id IS NOT NULL THEN
            INSERT INTO fases_despiece_equivalencias (organizacion_id, paso_legacy, fase_id, notas)
            VALUES (r_org.id, 'RINES', v_fase_id, 'Equivalencia histórica rines -> Llantas y Rines')
            ON CONFLICT (organizacion_id, paso_legacy) DO UPDATE SET
                fase_id = EXCLUDED.fase_id,
                notas = EXCLUDED.notas;
        END IF;


        -- C. Poblar productos (materias primas) desde UNION DE LISTADOS

        -- Material: ABRAZADERAS AMPRO GABRIEL
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'ABRAZADERAS AMPRO GABRIEL' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'ABRAZADERAS AMPRO GABRIEL', 'bien', 'materia_prima', 'PZA', 0, 0, 'ABRAZADERAS AMPRO GABRIEL', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'ABRAZADERAS AMPRO GABRIEL' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: ABRAZADERAS FLEET MASTER GABRIEL
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'ABRAZADERAS FLEET MASTER GABRIEL' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'ABRAZADERAS FLEET MASTER GABRIEL', 'bien', 'materia_prima', 'PZA', 0, 0, 'ABRAZADERAS FLET MASTER GABRIEL', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'ABRAZADERAS FLEET MASTER GABRIEL' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: ABRAZADERAS HENDRICKSON HENDRICKSON C-25319 O R14-152
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'ABRAZADERAS HENDRICKSON HENDRICKSON C-25319 O R14-152' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'ABRAZADERAS HENDRICKSON HENDRICKSON C-25319 O R14-152', 'bien', 'materia_prima', 'PZA', 0, 0, 'ABRAZADERAS HENDRICKSON HENDRICKSON C-25319 O R14-152', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'ABRAZADERAS HENDRICKSON HENDRICKSON C-25319 O R14-152' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: ABRAZADERAS HENDRICKSON HENDRICKSON R14-083-38
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'ABRAZADERAS HENDRICKSON HENDRICKSON R14-083-38' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'ABRAZADERAS HENDRICKSON HENDRICKSON R14-083-38', 'bien', 'materia_prima', 'PZA', 0, 0, 'ABRAZADERAS HENDRICKSON HENDRICKSON R14-083-38', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'ABRAZADERAS HENDRICKSON HENDRICKSON R14-083-38' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: ADAPTADOR 3/8
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'ADAPTADOR 3/8' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'ADAPTADOR 3/8', 'bien', 'materia_prima', 'PZA', 0, 0, 'ADAPTADOR 3/8', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'ADAPTADOR 3/8' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: ALMA (PLACA DE GRADO A-50 CAL. 1/4")
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'ALMA (PLACA DE GRADO A-50 CAL. 1/4")' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'ALMA (PLACA DE GRADO A-50 CAL. 1/4")', 'bien', 'materia_prima', 'PZA', 0, 0, 'Alma (Placa de grado A-50 Cal. 1/4")', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'ALMA (PLACA DE GRADO A-50 CAL. 1/4")' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: AMORTIGUADOR FCR
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'AMORTIGUADOR FCR' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'AMORTIGUADOR FCR', 'bien', 'materia_prima', 'PZA', 0, 0, 'AMORTIGUADOR FCR', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'AMORTIGUADOR FCR' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: AMORTIGUADOR FLEET MASTER 323
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'AMORTIGUADOR FLEET MASTER 323' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'AMORTIGUADOR FLEET MASTER 323', 'bien', 'materia_prima', 'PZA', 0, 0, 'AMORTIGUADOR FLET MASTER 323', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'AMORTIGUADOR FLEET MASTER 323' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: AMORTIGUADOR GABRIEL
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'AMORTIGUADOR GABRIEL' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'AMORTIGUADOR GABRIEL', 'bien', 'materia_prima', 'PZA', 0, 0, 'AMORTIGUADOR GABRIEL', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'AMORTIGUADOR GABRIEL' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: AMORTIGUADOR HENDRICKSON 20126
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'AMORTIGUADOR HENDRICKSON 20126' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'AMORTIGUADOR HENDRICKSON 20126', 'bien', 'materia_prima', 'PZA', 0, 0, 'AMORTIGUADOR HENDRICKSON 20126', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'AMORTIGUADOR HENDRICKSON 20126' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: AMORTIGUADOR HENDRICKSON 23743
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'AMORTIGUADOR HENDRICKSON 23743' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'AMORTIGUADOR HENDRICKSON 23743', 'bien', 'materia_prima', 'PZA', 0, 0, 'AMORTIGUADOR HENDRICKSON 23743', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'AMORTIGUADOR HENDRICKSON 23743' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: AMORTIGUADOR MONROE 65512
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'AMORTIGUADOR MONROE 65512' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'AMORTIGUADOR MONROE 65512', 'bien', 'materia_prima', 'PZA', 0, 0, 'AMORTIGUADOR MONRROE 65512', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'AMORTIGUADOR MONROE 65512' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: ATIZADORES EXTERNOS
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'ATIZADORES EXTERNOS' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'ATIZADORES EXTERNOS', 'bien', 'materia_prima', 'PZA', 50.0, 0, 'Atizadores externos', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 50.0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'ATIZADORES EXTERNOS' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 50.0 > 0;
        END IF;

        -- Material: ATIZADORES INTERNOS
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'ATIZADORES INTERNOS' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'ATIZADORES INTERNOS', 'bien', 'materia_prima', 'PZA', 35.0, 0, 'Atizadores internos', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 35.0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'ATIZADORES INTERNOS' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 35.0 > 0;
        END IF;

        -- Material: BASE PARA ABS
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'BASE PARA ABS' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'BASE PARA ABS', 'bien', 'materia_prima', 'PZA', 30.0, 0, 'Base para ABS', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 30.0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'BASE PARA ABS' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 30.0 > 0;
        END IF;

        -- Material: BASE PARA ESTRIBO PLACA FRONTAL
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'BASE PARA ESTRIBO PLACA FRONTAL' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'BASE PARA ESTRIBO PLACA FRONTAL', 'bien', 'materia_prima', 'PZA', 170.0, 0, 'Base para estribo Placa frontal', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 170.0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'BASE PARA ESTRIBO PLACA FRONTAL' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 170.0 > 0;
        END IF;

        -- Material: BASE PARA ESTRIBO PLACA INTERMEDIA
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'BASE PARA ESTRIBO PLACA INTERMEDIA' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'BASE PARA ESTRIBO PLACA INTERMEDIA', 'bien', 'materia_prima', 'PZA', 130.0, 0, 'Base para estribo Placa intermedia', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 130.0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'BASE PARA ESTRIBO PLACA INTERMEDIA' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 130.0 > 0;
        END IF;

        -- Material: BASE PARA ESTRIBO PLACA TRASERA
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'BASE PARA ESTRIBO PLACA TRASERA' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'BASE PARA ESTRIBO PLACA TRASERA', 'bien', 'materia_prima', 'PZA', 65.0, 0, 'Base para estribo Placa trasera', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 65.0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'BASE PARA ESTRIBO PLACA TRASERA' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 65.0 > 0;
        END IF;

        -- Material: BASE PARA FOCO DE ABS
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'BASE PARA FOCO DE ABS' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'BASE PARA FOCO DE ABS', 'bien', 'materia_prima', 'PZA', 25.0, 0, 'Base para foco de ABS', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 25.0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'BASE PARA FOCO DE ABS' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 25.0 > 0;
        END IF;

        -- Material: BASE PARA MANITAS
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'BASE PARA MANITAS' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'BASE PARA MANITAS', 'bien', 'materia_prima', 'PZA', 101.0, 0, 'Base para manitas', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 101.0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'BASE PARA MANITAS' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 101.0 > 0;
        END IF;

        -- Material: BASE PARA PATINES PLACAS
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'BASE PARA PATINES PLACAS' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'BASE PARA PATINES PLACAS', 'bien', 'materia_prima', 'PZA', 52.6, 0, 'Base para patines Placas', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 52.6, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'BASE PARA PATINES PLACAS' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 52.6 > 0;
        END IF;

        -- Material: BASE PARA PATINES SOLERA
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'BASE PARA PATINES SOLERA' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'BASE PARA PATINES SOLERA', 'bien', 'materia_prima', 'PZA', 23.4, 0, 'Base para patines Solera', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 23.4, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'BASE PARA PATINES SOLERA' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 23.4 > 0;
        END IF;

        -- Material: BASE PARA PERCHAS
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'BASE PARA PERCHAS' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'BASE PARA PERCHAS', 'bien', 'materia_prima', 'PZA', 234.0, 0, 'Base para perchas', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 234.0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'BASE PARA PERCHAS' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 234.0 > 0;
        END IF;

        -- Material: BASE PARA PLATOS
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'BASE PARA PLATOS' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'BASE PARA PLATOS', 'bien', 'materia_prima', 'PZA', 67.0, 0, 'Base para platos', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 67.0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'BASE PARA PLATOS' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 67.0 > 0;
        END IF;

        -- Material: BASE PARA TANQUES
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'BASE PARA TANQUES' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'BASE PARA TANQUES', 'bien', 'materia_prima', 'PZA', 77.0, 0, 'Base para tanques', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 77.0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'BASE PARA TANQUES' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 77.0 > 0;
        END IF;

        -- Material: BOLSA RETRACTIL CHICA UBL
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'BOLSA RETRACTIL CHICA UBL' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'BOLSA RETRACTIL CHICA UBL', 'bien', 'materia_prima', 'PZA', 0, 0, 'BOLSA RETRACTIL CHICA UBL', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'BOLSA RETRACTIL CHICA UBL' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: BOLSA RETRACTIL GRANDE
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'BOLSA RETRACTIL GRANDE' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'BOLSA RETRACTIL GRANDE', 'bien', 'materia_prima', 'PZA', 0, 0, 'BOLSA RETRACTIL GRANDE', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'BOLSA RETRACTIL GRANDE' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: BORDA DELANTERA
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'BORDA DELANTERA' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'BORDA DELANTERA', 'bien', 'materia_prima', 'PZA', 2068.0, 0, 'Borda delantera', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 2068.0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'BORDA DELANTERA' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 2068.0 > 0;
        END IF;

        -- Material: BORDA TRASERA
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'BORDA TRASERA' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'BORDA TRASERA', 'bien', 'materia_prima', 'PZA', 2500.0, 0, 'Borda trasera', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 2500.0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'BORDA TRASERA' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 2500.0 > 0;
        END IF;

        -- Material: BORDAS LATERALES
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'BORDAS LATERALES' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'BORDAS LATERALES', 'bien', 'materia_prima', 'PZA', 5870.35, 0, 'Bordas laterales', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 5870.35, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'BORDAS LATERALES' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 5870.35 > 0;
        END IF;

        -- Material: BOTONES
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'BOTONES' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'BOTONES', 'bien', 'materia_prima', 'PZA', 40.0, 0, 'Botones', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 40.0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'BOTONES' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 40.0 > 0;
        END IF;

        -- Material: BUCHACAS
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'BUCHACAS' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'BUCHACAS', 'bien', 'materia_prima', 'PZA', 45.5, 0, 'Buchacas', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 45.5, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'BUCHACAS' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 45.5 > 0;
        END IF;

        -- Material: BUJE TRIFUNCIONAL CON TORNILLO 7/8 HENDRICKSON R14-083-38
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'BUJE TRIFUNCIONAL CON TORNILLO 7/8 HENDRICKSON R14-083-38' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'BUJE TRIFUNCIONAL CON TORNILLO 7/8 HENDRICKSON R14-083-38', 'bien', 'materia_prima', 'PZA', 0, 0, 'BUJE TRIFUNCIONAL CON TORNILLO 7/8 HENDRICKSON R14-083-38', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'BUJE TRIFUNCIONAL CON TORNILLO 7/8 HENDRICKSON R14-083-38' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: BUJE TRIFUNCIONAL CON TORNILLO HENDRICKSON C-25319 O R14-152
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'BUJE TRIFUNCIONAL CON TORNILLO HENDRICKSON C-25319 O R14-152' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'BUJE TRIFUNCIONAL CON TORNILLO HENDRICKSON C-25319 O R14-152', 'bien', 'materia_prima', 'PZA', 0, 0, 'BUJE TRIFUNCIONAL CON TORNILLO HENDRICKSON C-25319 O R14-152', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'BUJE TRIFUNCIONAL CON TORNILLO HENDRICKSON C-25319 O R14-152' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: BUJE TRIFUNCIONAL GABRIEL
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'BUJE TRIFUNCIONAL GABRIEL' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'BUJE TRIFUNCIONAL GABRIEL', 'bien', 'materia_prima', 'PZA', 0, 0, 'BUJE TRIFUNCIONAL GABRIEL', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'BUJE TRIFUNCIONAL GABRIEL' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: BUJE TRIFUNCIONAL HENDRICKSON 7/8 GABRIEL
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'BUJE TRIFUNCIONAL HENDRICKSON 7/8 GABRIEL' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'BUJE TRIFUNCIONAL HENDRICKSON 7/8 GABRIEL', 'bien', 'materia_prima', 'PZA', 0, 0, 'BUJE TRIFUNCIONAL HENDRICKSON 7/8 GABRIEL', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'BUJE TRIFUNCIONAL HENDRICKSON 7/8 GABRIEL' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: CABLE AMARILLO CAL,12
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'CABLE AMARILLO CAL,12' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'CABLE AMARILLO CAL,12', 'bien', 'materia_prima', 'PZA', 0, 0, 'CABLE AMARILLO CAL,12', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'CABLE AMARILLO CAL,12' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: CABLE AZUL CAL,12
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'CABLE AZUL CAL,12' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'CABLE AZUL CAL,12', 'bien', 'materia_prima', 'PZA', 0, 0, 'CABLE AZUL CAL,12', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'CABLE AZUL CAL,12' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: CABLE CAFÉ CAL,12
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'CABLE CAFÉ CAL,12' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'CABLE CAFÉ CAL,12', 'bien', 'materia_prima', 'PZA', 0, 0, 'CABLE CAFÉ CAL,12', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'CABLE CAFÉ CAL,12' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: CABLE NEGRO CAL,12
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'CABLE NEGRO CAL,12' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'CABLE NEGRO CAL,12', 'bien', 'materia_prima', 'PZA', 0, 0, 'CABLE NEGRO  CAL,12', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'CABLE NEGRO CAL,12' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: CABLE ROJO CAL,12
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'CABLE ROJO CAL,12' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'CABLE ROJO CAL,12', 'bien', 'materia_prima', 'PZA', 0, 0, 'CABLE ROJO CAL,12', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'CABLE ROJO CAL,12' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: CABLE VERDE CAL,12
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'CABLE VERDE CAL,12' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'CABLE VERDE CAL,12', 'bien', 'materia_prima', 'PZA', 0, 0, 'CABLE VERDE CAL,12', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'CABLE VERDE CAL,12' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: CAJA DE HERRAMIENTAS MATERIAL JAIRO
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'CAJA DE HERRAMIENTAS MATERIAL JAIRO' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'CAJA DE HERRAMIENTAS MATERIAL JAIRO', 'bien', 'materia_prima', 'PZA', 0, 0, 'Caja de herramientas Material Jairo', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'CAJA DE HERRAMIENTAS MATERIAL JAIRO' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: CAJA DE HERRAMIENTAS TORNILLO
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'CAJA DE HERRAMIENTAS TORNILLO' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'CAJA DE HERRAMIENTAS TORNILLO', 'bien', 'materia_prima', 'PZA', 0, 0, 'Caja de herramientas TORNILLO', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'CAJA DE HERRAMIENTAS TORNILLO' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: CAJA DE HERRAMIENTAS TUERCA
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'CAJA DE HERRAMIENTAS TUERCA' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'CAJA DE HERRAMIENTAS TUERCA', 'bien', 'materia_prima', 'PZA', 0, 0, 'Caja de herramientas TUERCA', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'CAJA DE HERRAMIENTAS TUERCA' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: CAMARA DE SUSPENSION AMPRO 1R14-039
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'CAMARA DE SUSPENSION AMPRO 1R14-039' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'CAMARA DE SUSPENSION AMPRO 1R14-039', 'bien', 'materia_prima', 'PZA', 0, 0, 'CAMARA DE SUSPENSION AMPRO 1R14-039', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'CAMARA DE SUSPENSION AMPRO 1R14-039' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: CAMARA DE SUSPENSION AMPRO 8050
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'CAMARA DE SUSPENSION AMPRO 8050' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'CAMARA DE SUSPENSION AMPRO 8050', 'bien', 'materia_prima', 'PZA', 0, 0, 'CAMARA DE SUSPENSION AMPRO 8050', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'CAMARA DE SUSPENSION AMPRO 8050' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: CAMARA DE SUSPENSION FCR 1R14-039
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'CAMARA DE SUSPENSION FCR 1R14-039' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'CAMARA DE SUSPENSION FCR 1R14-039', 'bien', 'materia_prima', 'PZA', 0, 0, 'CAMARA DE SUSPENSION FCR 1R14-039', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'CAMARA DE SUSPENSION FCR 1R14-039' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: CAMARA DE SUSPENSION FLEET MASTER 8050
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'CAMARA DE SUSPENSION FLEET MASTER 8050' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'CAMARA DE SUSPENSION FLEET MASTER 8050', 'bien', 'materia_prima', 'PZA', 0, 0, 'CAMARA DE SUSPENSION FLET MASTER 8050', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'CAMARA DE SUSPENSION FLEET MASTER 8050' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: CAMARA DE SUSPENSION HENDRICKSON C-25319 O R14-152
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'CAMARA DE SUSPENSION HENDRICKSON C-25319 O R14-152' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'CAMARA DE SUSPENSION HENDRICKSON C-25319 O R14-152', 'bien', 'materia_prima', 'PZA', 0, 0, 'CAMARA DE SUSPENSION HENDRICKSON C-25319 O R14-152', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'CAMARA DE SUSPENSION HENDRICKSON C-25319 O R14-152' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: CAMARA DE SUSPENSION HENDRICKSON R14-083-38
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'CAMARA DE SUSPENSION HENDRICKSON R14-083-38' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'CAMARA DE SUSPENSION HENDRICKSON R14-083-38', 'bien', 'materia_prima', 'PZA', 0, 0, 'CAMARA DE SUSPENSION HENDRICKSON R14-083-38', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'CAMARA DE SUSPENSION HENDRICKSON R14-083-38' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: CANDADO PARA PLANA
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'CANDADO PARA PLANA' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'CANDADO PARA PLANA', 'bien', 'materia_prima', 'PZA', 0, 0, 'CANDADO PARA PLANA', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'CANDADO PARA PLANA' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: CARGADOR
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'CARGADOR' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'CARGADOR', 'bien', 'materia_prima', 'PZA', 576.82, 0, 'Cargador', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 576.82, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'CARGADOR' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 576.82 > 0;
        END IF;

        -- Material: CARGADOR 3" X 102"
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'CARGADOR 3" X 102"' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'CARGADOR 3" X 102"', 'bien', 'materia_prima', 'PZA', 0, 0, 'CARGADO 3X102 IN', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'CARGADOR 3" X 102"' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: CARTABONES PARA JALON
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'CARTABONES PARA JALON' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'CARTABONES PARA JALON', 'bien', 'materia_prima', 'PZA', 300.0, 0, 'Cartabones para jalon', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 300.0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'CARTABONES PARA JALON' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 300.0 > 0;
        END IF;

        -- Material: CHAVETAS 3/16*2
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'CHAVETAS 3/16*2' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'CHAVETAS 3/16*2', 'bien', 'materia_prima', 'PZA', 0, 0, 'CHAVETAS 3/16*2', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'CHAVETAS 3/16*2' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: CINCHO
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'CINCHO' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'CINCHO', 'bien', 'materia_prima', 'PZA', 1110.0, 0, 'Cincho', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 1110.0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'CINCHO' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 1110.0 > 0;
        END IF;

        -- Material: CINTA DE AISLAR
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'CINTA DE AISLAR' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'CINTA DE AISLAR', 'bien', 'materia_prima', 'PZA', 0, 0, 'CINTA DE AISLAR', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'CINTA DE AISLAR' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: CINTA REFLEJANTE
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'CINTA REFLEJANTE' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'CINTA REFLEJANTE', 'bien', 'materia_prima', 'PZA', 0, 0, 'CINTA REFLEJANTE', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'CINTA REFLEJANTE' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: CO2
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'CO2' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'CO2', 'bien', 'materia_prima', 'PZA', 0, 0, 'CO2', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'CO2' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: CODO 1/2
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'CODO 1/2' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'CODO 1/2', 'bien', 'materia_prima', 'PZA', 0, 0, 'CODO 1/2', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'CODO 1/2' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: CODO 3/8
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'CODO 3/8' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'CODO 3/8', 'bien', 'materia_prima', 'PZA', 0, 0, 'CODO 3/8', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'CODO 3/8' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: CODO 3/8*1/4
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'CODO 3/8*1/4' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'CODO 3/8*1/4', 'bien', 'materia_prima', 'PZA', 0, 0, 'CODO 3/8*1/4', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'CODO 3/8*1/4' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: CODO 3/8*1/8
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'CODO 3/8*1/8' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'CODO 3/8*1/8', 'bien', 'materia_prima', 'PZA', 0, 0, 'CODO 3/8*1/8', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'CODO 3/8*1/8' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: CONSUMIBLE 65
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'CONSUMIBLE 65' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'CONSUMIBLE 65', 'bien', 'materia_prima', 'PZA', 0, 0, 'CONSUMIBLE 65', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'CONSUMIBLE 65' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: CORRUGADO 1/2
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'CORRUGADO 1/2' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'CORRUGADO 1/2', 'bien', 'materia_prima', 'PZA', 0, 0, 'CORRUGADO 1/2', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'CORRUGADO 1/2' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: CORRUGADO 1/4
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'CORRUGADO 1/4' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'CORRUGADO 1/4', 'bien', 'materia_prima', 'PZA', 0, 0, 'CORRUGADO 1/4', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'CORRUGADO 1/4' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: CORRUGADO 3/8
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'CORRUGADO 3/8' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'CORRUGADO 3/8', 'bien', 'materia_prima', 'PZA', 0, 0, 'CORRUGADO 3/8', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'CORRUGADO 3/8' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: DISCO DE CORTE 7
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'DISCO DE CORTE 7' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'DISCO DE CORTE 7', 'bien', 'materia_prima', 'PZA', 0, 0, 'DISCO DE CORTE 7', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'DISCO DE CORTE 7' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: DISCO DE DESBASTE 9
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'DISCO DE DESBASTE 9' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'DISCO DE DESBASTE 9', 'bien', 'materia_prima', 'PZA', 0, 0, 'DISCO DE DESBASTE 9', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'DISCO DE DESBASTE 9' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: DISCO LAMINADO 7
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'DISCO LAMINADO 7' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'DISCO LAMINADO 7', 'bien', 'materia_prima', 'PZA', 0, 0, 'DISCO LAMINADO 7', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'DISCO LAMINADO 7' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: EJE AMPRO
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'EJE AMPRO' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'EJE AMPRO', 'bien', 'materia_prima', 'PZA', 0, 0, 'EJE AMPRO', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'EJE AMPRO' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: EJE FCR
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'EJE FCR' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'EJE FCR', 'bien', 'materia_prima', 'PZA', 0, 0, 'EJE FCR', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'EJE FCR' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: EJE FLEET MASTER
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'EJE FLEET MASTER' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'EJE FLEET MASTER', 'bien', 'materia_prima', 'PZA', 0, 0, 'EJE FLET MASTER', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'EJE FLEET MASTER' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: EJE HJ
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'EJE HJ' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'EJE HJ', 'bien', 'materia_prima', 'PZA', 0, 0, 'EJE HJ', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'EJE HJ' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: EJE PRAT MAX
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'EJE PRAT MAX' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'EJE PRAT MAX', 'bien', 'materia_prima', 'PZA', 0, 0, 'EJE PRAT MAX', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'EJE PRAT MAX' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: ESPARRAGO
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'ESPARRAGO' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'ESPARRAGO', 'bien', 'materia_prima', 'PZA', 0, 0, 'ESPARRAGO', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'ESPARRAGO' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: ESQUINERO DELANTERO
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'ESQUINERO DELANTERO' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'ESQUINERO DELANTERO', 'bien', 'materia_prima', 'PZA', 70.0, 0, 'Esquinero delantero', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 70.0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'ESQUINERO DELANTERO' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 70.0 > 0;
        END IF;

        -- Material: ESQUINERO TRASERO
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'ESQUINERO TRASERO' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'ESQUINERO TRASERO', 'bien', 'materia_prima', 'PZA', 110.0, 0, 'Esquinero trasero', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 110.0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'ESQUINERO TRASERO' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 110.0 > 0;
        END IF;

        -- Material: ESTRIBO
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'ESTRIBO' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'ESTRIBO', 'bien', 'materia_prima', 'PZA', 1050.0, 0, 'Estribo', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 1050.0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'ESTRIBO' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 1050.0 > 0;
        END IF;

        -- Material: FLEJE
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'FLEJE' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'FLEJE', 'bien', 'materia_prima', 'PZA', 0, 0, 'FLEJE', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'FLEJE' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: GANCHO HOLLAND 10 BARRENOS
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'GANCHO HOLLAND 10 BARRENOS' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'GANCHO HOLLAND 10 BARRENOS', 'bien', 'materia_prima', 'PZA', 0, 0, 'GANCHO HOLLAND 10 BARRENOS', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'GANCHO HOLLAND 10 BARRENOS' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: GANCHO PREMIER 10 BARRENOS
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'GANCHO PREMIER 10 BARRENOS' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'GANCHO PREMIER 10 BARRENOS', 'bien', 'materia_prima', 'PZA', 0, 0, 'GANCHO PREMIER 10 BARRENOS', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'GANCHO PREMIER 10 BARRENOS' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: GANCHO PREMIER BESTIA 6 BARRENOS
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'GANCHO PREMIER BESTIA 6 BARRENOS' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'GANCHO PREMIER BESTIA 6 BARRENOS', 'bien', 'materia_prima', 'PZA', 0, 0, 'GANCHO PREMIER BESTIA 6 BARRENOS', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'GANCHO PREMIER BESTIA 6 BARRENOS' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: GANCHOS
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'GANCHOS' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'GANCHOS', 'bien', 'materia_prima', 'PZA', 6.3, 0, 'Ganchos', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 6.3, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'GANCHOS' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 6.3 > 0;
        END IF;

        -- Material: HEMBRA 3/8
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'HEMBRA 3/8' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'HEMBRA 3/8', 'bien', 'materia_prima', 'PZA', 0, 0, 'HEMBRA 3/8', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'HEMBRA 3/8' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: HEMBRA 7 POLOS
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'HEMBRA 7 POLOS' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'HEMBRA 7 POLOS', 'bien', 'materia_prima', 'PZA', 0, 0, 'HEMBRA 7 POLOS', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'HEMBRA 7 POLOS' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: HERAJE PARA PATINES 110CM
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'HERAJE PARA PATINES 110CM' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'HERAJE PARA PATINES 110CM', 'bien', 'materia_prima', 'PZA', 196.99, 0, 'Heraje para patines 110cm', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 196.99, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'HERAJE PARA PATINES 110CM' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 196.99 > 0;
        END IF;

        -- Material: HERAJE PARA PATINES 125CM
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'HERAJE PARA PATINES 125CM' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'HERAJE PARA PATINES 125CM', 'bien', 'materia_prima', 'PZA', 223.99, 0, 'Heraje para patines 125cm', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 223.99, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'HERAJE PARA PATINES 125CM' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 223.99 > 0;
        END IF;

        -- Material: HERAJE PARA PATINES 23CM
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'HERAJE PARA PATINES 23CM' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'HERAJE PARA PATINES 23CM', 'bien', 'materia_prima', 'PZA', 41.99, 0, 'Heraje para patines 23cm', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 41.99, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'HERAJE PARA PATINES 23CM' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 41.99 > 0;
        END IF;

        -- Material: HERAJE PARA PATINES 27CM
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'HERAJE PARA PATINES 27CM' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'HERAJE PARA PATINES 27CM', 'bien', 'materia_prima', 'PZA', 90.99, 0, 'Heraje para patines 27cm', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 90.99, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'HERAJE PARA PATINES 27CM' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 90.99 > 0;
        END IF;

        -- Material: HERAJE PARA PATINES 30CM
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'HERAJE PARA PATINES 30CM' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'HERAJE PARA PATINES 30CM', 'bien', 'materia_prima', 'PZA', 100.99, 0, 'Heraje para patines 30cm', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 100.99, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'HERAJE PARA PATINES 30CM' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 100.99 > 0;
        END IF;

        -- Material: HERAJE PARA PATINES 67CM
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'HERAJE PARA PATINES 67CM' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'HERAJE PARA PATINES 67CM', 'bien', 'materia_prima', 'PZA', 119.99, 0, 'Heraje para patines 67cm', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 119.99, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'HERAJE PARA PATINES 67CM' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 119.99 > 0;
        END IF;

        -- Material: HERAJE PARA PATINES 70CM
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'HERAJE PARA PATINES 70CM' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'HERAJE PARA PATINES 70CM', 'bien', 'materia_prima', 'PZA', 124.99, 0, 'Heraje para patines 70cm', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 124.99, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'HERAJE PARA PATINES 70CM' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 124.99 > 0;
        END IF;

        -- Material: HERAJE PARA PATINES 7CM
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'HERAJE PARA PATINES 7CM' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'HERAJE PARA PATINES 7CM', 'bien', 'materia_prima', 'PZA', 23.99, 0, 'Heraje para patines 7cm', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 23.99, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'HERAJE PARA PATINES 7CM' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 23.99 > 0;
        END IF;

        -- Material: HERAJE PARA PATINES BUCHACA
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'HERAJE PARA PATINES BUCHACA' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'HERAJE PARA PATINES BUCHACA', 'bien', 'materia_prima', 'PZA', 40.99, 0, 'Heraje para patines Buchaca', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 40.99, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'HERAJE PARA PATINES BUCHACA' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 40.99 > 0;
        END IF;

        -- Material: HERAJE PARA PATINES TORNILLO
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'HERAJE PARA PATINES TORNILLO' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'HERAJE PARA PATINES TORNILLO', 'bien', 'materia_prima', 'PZA', 0, 0, 'Heraje para patines TORNILLO', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'HERAJE PARA PATINES TORNILLO' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: HERAJE PARA PATINES TUERCA
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'HERAJE PARA PATINES TUERCA' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'HERAJE PARA PATINES TUERCA', 'bien', 'materia_prima', 'PZA', 0, 0, 'Heraje para patines TUERCA', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'HERAJE PARA PATINES TUERCA' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: INSERTO 1/2
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'INSERTO 1/2' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'INSERTO 1/2', 'bien', 'materia_prima', 'PZA', 0, 0, 'INCERTO 1/2', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'INSERTO 1/2' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: INSERTO 3/8
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'INSERTO 3/8' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'INSERTO 3/8', 'bien', 'materia_prima', 'PZA', 0, 0, 'INCERTO 3/8', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'INSERTO 3/8' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: JALON
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'JALON' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'JALON', 'bien', 'materia_prima', 'PZA', 2500.0, 0, 'Jalon', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 2500.0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'JALON' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 2500.0 > 0;
        END IF;

        -- Material: KIT DE ABS 2 EJES BENDIX
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'KIT DE ABS 2 EJES BENDIX' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'KIT DE ABS 2 EJES BENDIX', 'bien', 'materia_prima', 'PZA', 0, 0, 'KIT DE ABS 2 EJES BENDIX', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'KIT DE ABS 2 EJES BENDIX' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: KIT DE ALETAS 27 X 50 CM
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'KIT DE ALETAS 27 X 50 CM' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'KIT DE ALETAS 27 X 50 CM', 'bien', 'materia_prima', 'PZA', 108.99, 0, 'Kit de aletas 27 x 50 cm', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 108.99, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'KIT DE ALETAS 27 X 50 CM' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 108.99 > 0;
        END IF;

        -- Material: KIT DE ALETAS 27 X 60 CM
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'KIT DE ALETAS 27 X 60 CM' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'KIT DE ALETAS 27 X 60 CM', 'bien', 'materia_prima', 'PZA', 130.99, 0, 'Kit de aletas 27 x 60 cm', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 130.99, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'KIT DE ALETAS 27 X 60 CM' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 130.99 > 0;
        END IF;

        -- Material: KIT DE ALETAS 40 X 50 CM
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'KIT DE ALETAS 40 X 50 CM' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'KIT DE ALETAS 40 X 50 CM', 'bien', 'materia_prima', 'PZA', 161.99, 0, 'Kit de aletas 40 x 50 cm', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 161.99, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'KIT DE ALETAS 40 X 50 CM' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 161.99 > 0;
        END IF;

        -- Material: KIT DE ALETAS 40 X 60 CM
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'KIT DE ALETAS 40 X 60 CM' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'KIT DE ALETAS 40 X 60 CM', 'bien', 'materia_prima', 'PZA', 193.99, 0, 'Kit de aletas 40 x 60 cm', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 193.99, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'KIT DE ALETAS 40 X 60 CM' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 193.99 > 0;
        END IF;

        -- Material: KIT DE ALETAS 45 X 50 CM
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'KIT DE ALETAS 45 X 50 CM' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'KIT DE ALETAS 45 X 50 CM', 'bien', 'materia_prima', 'PZA', 181.99, 0, 'Kit de aletas 45 x 50 cm', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 181.99, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'KIT DE ALETAS 45 X 50 CM' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 181.99 > 0;
        END IF;

        -- Material: KIT DE ALETAS 45 X 60 CM
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'KIT DE ALETAS 45 X 60 CM' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'KIT DE ALETAS 45 X 60 CM', 'bien', 'materia_prima', 'PZA', 217.99, 0, 'Kit de aletas 45 x 60 cm', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 217.99, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'KIT DE ALETAS 45 X 60 CM' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 217.99 > 0;
        END IF;

        -- Material: KIT DE LUZ
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'KIT DE LUZ' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'KIT DE LUZ', 'bien', 'materia_prima', 'PZA', 0, 0, 'KIT DE LUZ', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'KIT DE LUZ' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: KIT DE ROTULACION
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'KIT DE ROTULACION' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'KIT DE ROTULACION', 'bien', 'materia_prima', 'PZA', 0, 0, 'KIT DE ROTULACION', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'KIT DE ROTULACION' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: LAVADO Y ESCOREO CARDA 5/8 DE 3"
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'LAVADO Y ESCOREO CARDA 5/8 DE 3"' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'LAVADO Y ESCOREO CARDA 5/8 DE 3"', 'bien', 'materia_prima', 'PZA', 0, 0, 'LAVADO Y ESCOREO CARDA 5/8 DE 3"', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'LAVADO Y ESCOREO CARDA 5/8 DE 3"' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: LAVADO Y ESCOREO DISCO LAMINADO 4 1/2
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'LAVADO Y ESCOREO DISCO LAMINADO 4 1/2' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'LAVADO Y ESCOREO DISCO LAMINADO 4 1/2', 'bien', 'materia_prima', 'PZA', 0, 0, 'LAVADO Y ESCOREO DISCO LAMINADO 4 1/2', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'LAVADO Y ESCOREO DISCO LAMINADO 4 1/2' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: LAVADO Y ESCOREO FOSFATO
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'LAVADO Y ESCOREO FOSFATO' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'LAVADO Y ESCOREO FOSFATO', 'bien', 'materia_prima', 'PZA', 0, 0, 'LAVADO Y ESCOREO FOSFATO', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'LAVADO Y ESCOREO FOSFATO' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: LAVADO Y ESCOREO LIJA #80
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'LAVADO Y ESCOREO LIJA #80' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'LAVADO Y ESCOREO LIJA #80', 'bien', 'materia_prima', 'PZA', 0, 0, 'LAVADO Y ESCOREO LIJA #80', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'LAVADO Y ESCOREO LIJA #80' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: LLANTA FIRESTON LINEAL
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'LLANTA FIRESTON LINEAL' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'LLANTA FIRESTON LINEAL', 'bien', 'materia_prima', 'PZA', 0, 0, 'LLANTA FIRESTON LINEAL', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'LLANTA FIRESTON LINEAL' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: LLANTA GODSHIELD LINEAL
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'LLANTA GODSHIELD LINEAL' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'LLANTA GODSHIELD LINEAL', 'bien', 'materia_prima', 'PZA', 0, 0, 'LLANTA GODSHIELD LINEAL', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'LLANTA GODSHIELD LINEAL' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: LLANTA K PATOS LINEAL
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'LLANTA K PATOS LINEAL' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'LLANTA K PATOS LINEAL', 'bien', 'materia_prima', 'PZA', 0, 0, 'LLANTA K PATOS LINEAL', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'LLANTA K PATOS LINEAL' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: LLANTA K PATOS TRACCION
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'LLANTA K PATOS TRACCION' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'LLANTA K PATOS TRACCION', 'bien', 'materia_prima', 'PZA', 0, 0, 'LLANTA K PATOS TRACCION', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'LLANTA K PATOS TRACCION' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: LODERA BLANCA O NEGRA
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'LODERA BLANCA O NEGRA' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'LODERA BLANCA O NEGRA', 'bien', 'materia_prima', 'PZA', 0, 0, 'LODERA BLANCA O NEGRA', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'LODERA BLANCA O NEGRA' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: MACHO 3/8
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'MACHO 3/8' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'MACHO 3/8', 'bien', 'materia_prima', 'PZA', 0, 0, 'MACHO 3/8', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'MACHO 3/8' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: MANGUERA AZUL 3/8
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'MANGUERA AZUL 3/8' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'MANGUERA AZUL 3/8', 'bien', 'materia_prima', 'PZA', 0, 0, 'MANGUERA AZUL 3/8', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'MANGUERA AZUL 3/8' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: MANGUERA CHAMBER 3/8
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'MANGUERA CHAMBER 3/8' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'MANGUERA CHAMBER 3/8', 'bien', 'materia_prima', 'PZA', 0, 0, 'MANGUERA CHAMBER 3/8', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'MANGUERA CHAMBER 3/8' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: MANGUERA ROJA 3/8
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'MANGUERA ROJA 3/8' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'MANGUERA ROJA 3/8', 'bien', 'materia_prima', 'PZA', 0, 0, 'MANGUERA ROJA 3/8', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'MANGUERA ROJA 3/8' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: MANITA AZUL C/LLAVE
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'MANITA AZUL C/LLAVE' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'MANITA AZUL C/LLAVE', 'bien', 'materia_prima', 'PZA', 0, 0, 'MANITA AZUL C/LLAVE', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'MANITA AZUL C/LLAVE' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: MANITA AZUL S/LLAVE
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'MANITA AZUL S/LLAVE' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'MANITA AZUL S/LLAVE', 'bien', 'materia_prima', 'PZA', 0, 0, 'MANITA AZUL S/LLAVE', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'MANITA AZUL S/LLAVE' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: MANITA ROJA C/LLAVE
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'MANITA ROJA C/LLAVE' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'MANITA ROJA C/LLAVE', 'bien', 'materia_prima', 'PZA', 0, 0, 'MANITA ROJA C/LLAVE', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'MANITA ROJA C/LLAVE' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: MANITA ROJA S/LLAVE
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'MANITA ROJA S/LLAVE' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'MANITA ROJA S/LLAVE', 'bien', 'materia_prima', 'PZA', 0, 0, 'MANITA ROJA S/LLAVE', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'MANITA ROJA S/LLAVE' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: MEDIDA DE RIN RIN 22.5
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'MEDIDA DE RIN RIN 22.5' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'MEDIDA DE RIN RIN 22.5', 'bien', 'materia_prima', 'PZA', 0, 0, 'MEDIDA DE RIN RIN 22.5', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'MEDIDA DE RIN RIN 22.5' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: MEDIDA DE RIN RIN 24.5
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'MEDIDA DE RIN RIN 24.5' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'MEDIDA DE RIN RIN 24.5', 'bien', 'materia_prima', 'PZA', 0, 0, 'MEDIDA DE RIN RIN 24.5', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'MEDIDA DE RIN RIN 24.5' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: NIPLE 1/4
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'NIPLE 1/4' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'NIPLE 1/4', 'bien', 'materia_prima', 'PZA', 0, 0, 'NIPLE 1/4', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'NIPLE 1/4' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: OXIGENO
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'OXIGENO' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'OXIGENO', 'bien', 'materia_prima', 'PZA', 0, 0, 'OXIGENO', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'OXIGENO' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: PATIN AMPRO
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'PATIN AMPRO' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'PATIN AMPRO', 'bien', 'materia_prima', 'PZA', 0, 0, 'PATIN AMPRO', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'PATIN AMPRO' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: PATIN FLEET MASTER
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'PATIN FLEET MASTER' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'PATIN FLEET MASTER', 'bien', 'materia_prima', 'PZA', 0, 0, 'PATIN FLET MASTER', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'PATIN FLEET MASTER' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: PATIN HJ
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'PATIN HJ' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'PATIN HJ', 'bien', 'materia_prima', 'PZA', 0, 0, 'PATIN HJ', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'PATIN HJ' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: PATIN HOLAND MARK V
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'PATIN HOLAND MARK V' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'PATIN HOLAND MARK V', 'bien', 'materia_prima', 'PZA', 0, 0, 'PATIN HOLAND MARK V', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'PATIN HOLAND MARK V' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: PERNO REY
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'PERNO REY' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'PERNO REY', 'bien', 'materia_prima', 'PZA', 1200.0, 0, 'Perno rey', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 1200.0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'PERNO REY' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 1200.0 > 0;
        END IF;

        -- Material: PESTAÑAS
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'PESTAÑAS' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'PESTAÑAS', 'bien', 'materia_prima', 'PZA', 64.0, 0, 'Pestañas', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 64.0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'PESTAÑAS' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 64.0 > 0;
        END IF;

        -- Material: PIJAS 5/16 X 2
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'PIJAS 5/16 X 2' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'PIJAS 5/16 X 2', 'bien', 'materia_prima', 'PZA', 0, 0, 'PIJAS 5/16 X 2', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'PIJAS 5/16 X 2' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: PIJAS 5/16 X 2 1/2
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'PIJAS 5/16 X 2 1/2' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'PIJAS 5/16 X 2 1/2', 'bien', 'materia_prima', 'PZA', 0, 0, 'PIJAS 5/16 X 2 1/2', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'PIJAS 5/16 X 2 1/2' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: PINTURA
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'PINTURA' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'PINTURA', 'bien', 'materia_prima', 'L', 0, 0, 'PINTURA', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'PINTURA' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: PINTURA AXALTA
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'PINTURA AXALTA' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'PINTURA AXALTA', 'bien', 'materia_prima', 'L', 0, 0, 'PINTURA AXALTA', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'PINTURA AXALTA' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: PINTURA PPG
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'PINTURA PPG' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'PINTURA PPG', 'bien', 'materia_prima', 'L', 0, 0, 'PINTURA PPG', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'PINTURA PPG' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: PINTURA SHERWIN WILLIAMSWILLIAMS
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'PINTURA SHERWIN WILLIAMSWILLIAMS' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'PINTURA SHERWIN WILLIAMSWILLIAMS', 'bien', 'materia_prima', 'L', 0, 0, 'PINTURA SHERVIWILLIAMS', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'PINTURA SHERWIN WILLIAMSWILLIAMS' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: PISO DE ENCINO
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'PISO DE ENCINO' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'PISO DE ENCINO', 'bien', 'materia_prima', 'PZA', 0, 0, 'PISO DE ENCINO', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'PISO DE ENCINO' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: PISO DE PINO
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'PISO DE PINO' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'PISO DE PINO', 'bien', 'materia_prima', 'PZA', 0, 0, 'PISO DE PINO', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'PISO DE PINO' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: PISO MADERA
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'PISO MADERA' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'PISO MADERA', 'bien', 'materia_prima', 'PZA', 0, 0, 'PISO MADERA', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'PISO MADERA' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: PISO PLASTICO CAFE
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'PISO PLASTICO CAFE' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'PISO PLASTICO CAFE', 'bien', 'materia_prima', 'PZA', 0, 0, 'PISO PLASTICO CAFE', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'PISO PLASTICO CAFE' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: PLACA DE NIP
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'PLACA DE NIP' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'PLACA DE NIP', 'bien', 'materia_prima', 'PZA', 0, 0, 'PLACA DE NIP', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'PLACA DE NIP' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: PLAFON AMBAR 2
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'PLAFON AMBAR 2' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'PLAFON AMBAR 2', 'bien', 'materia_prima', 'PZA', 0, 0, 'PLAFON AMBAR 2', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'PLAFON AMBAR 2' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: PLAFON AVALADO AMBAR
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'PLAFON AVALADO AMBAR' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'PLAFON AVALADO AMBAR', 'bien', 'materia_prima', 'PZA', 0, 0, 'PLAFON AVALADO AMBAR', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'PLAFON AVALADO AMBAR' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: PLAFON DE CARRITO AMBAR
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'PLAFON DE CARRITO AMBAR' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'PLAFON DE CARRITO AMBAR', 'bien', 'materia_prima', 'PZA', 0, 0, 'PLAFON DE CARRITO AMBAR', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'PLAFON DE CARRITO AMBAR' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: PLAFON DE CARRITO ROJO
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'PLAFON DE CARRITO ROJO' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'PLAFON DE CARRITO ROJO', 'bien', 'materia_prima', 'PZA', 0, 0, 'PLAFON DE CARRITO ROJO', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'PLAFON DE CARRITO ROJO' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: PLAFON ROJO 2
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'PLAFON ROJO 2' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'PLAFON ROJO 2', 'bien', 'materia_prima', 'PZA', 0, 0, 'PLAFON ROJO 2', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'PLAFON ROJO 2' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: PLAFON ROJO 4
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'PLAFON ROJO 4' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'PLAFON ROJO 4', 'bien', 'materia_prima', 'PZA', 0, 0, 'PLAFON ROJO 4', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'PLAFON ROJO 4' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: PLAFONES OVALADOS
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'PLAFONES OVALADOS' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'PLAFONES OVALADOS', 'bien', 'materia_prima', 'PZA', 45.0, 0, 'Plafones ovalados', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 45.0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'PLAFONES OVALADOS' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 45.0 > 0;
        END IF;

        -- Material: PLANCHA PARA LA QUINTA (PLACA DE GRADO A-36 CAL. 3/8")
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'PLANCHA PARA LA QUINTA (PLACA DE GRADO A-36 CAL. 3/8")' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'PLANCHA PARA LA QUINTA (PLACA DE GRADO A-36 CAL. 3/8")', 'bien', 'materia_prima', 'PZA', 5700.0, 0, 'Plancha para la quinta (Placa de grado A-36 Cal. 3/8")', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 5700.0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'PLANCHA PARA LA QUINTA (PLACA DE GRADO A-36 CAL. 3/8")' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 5700.0 > 0;
        END IF;

        -- Material: PORTA LLANTAS "U"
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'PORTA LLANTAS "U"' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'PORTA LLANTAS "U"', 'bien', 'materia_prima', 'PZA', 738.99, 0, 'Porta Llantas "U"', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 738.99, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'PORTA LLANTAS "U"' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 738.99 > 0;
        END IF;

        -- Material: PORTA LLANTAS "Z"
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'PORTA LLANTAS "Z"' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'PORTA LLANTAS "Z"', 'bien', 'materia_prima', 'PZA', 275.99, 0, 'Porta Llantas "Z"', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 275.99, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'PORTA LLANTAS "Z"' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 275.99 > 0;
        END IF;

        -- Material: PORTA LLANTAS ALETAS
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'PORTA LLANTAS ALETAS' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'PORTA LLANTAS ALETAS', 'bien', 'materia_prima', 'PZA', 87.99, 0, 'Porta Llantas Aletas', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 87.99, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'PORTA LLANTAS ALETAS' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 87.99 > 0;
        END IF;

        -- Material: PORTA LLANTAS TORNILLO
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'PORTA LLANTAS TORNILLO' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'PORTA LLANTAS TORNILLO', 'bien', 'materia_prima', 'PZA', 0, 0, 'Porta Llantas TORNILLO', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'PORTA LLANTAS TORNILLO' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: PORTA LLANTAS TUERCA
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'PORTA LLANTAS TUERCA' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'PORTA LLANTAS TUERCA', 'bien', 'materia_prima', 'PZA', 0, 0, 'Porta Llantas TUERCA', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'PORTA LLANTAS TUERCA' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: PORTA LODERAS
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'PORTA LODERAS' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'PORTA LODERAS', 'bien', 'materia_prima', 'PZA', 440.0, 0, 'Porta loderas', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 440.0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'PORTA LODERAS' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 440.0 > 0;
        END IF;

        -- Material: PORTA PLACAS
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'PORTA PLACAS' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'PORTA PLACAS', 'bien', 'materia_prima', 'PZA', 42.99, 0, 'Porta placas', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 42.99, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'PORTA PLACAS' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 42.99 > 0;
        END IF;

        -- Material: PUENTES DE LA PLANCHA
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'PUENTES DE LA PLANCHA' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'PUENTES DE LA PLANCHA', 'bien', 'materia_prima', 'KG', 450.0, 0, 'Puentes de la plancha', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 450.0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'PUENTES DE LA PLANCHA' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 450.0 > 0;
        END IF;

        -- Material: PUENTES DE SUSPENSION(PTR DE 6X2" CAL. 3/16")
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'PUENTES DE SUSPENSION(PTR DE 6X2" CAL. 3/16")' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'PUENTES DE SUSPENSION(PTR DE 6X2" CAL. 3/16")', 'bien', 'materia_prima', 'PZA', 0, 0, 'Puentes de suspensión (PTR de 6X2" Cal. 3/16")', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'PUENTES DE SUSPENSION(PTR DE 6X2" CAL. 3/16")' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: PUENTES INTERMEDIOS
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'PUENTES INTERMEDIOS' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'PUENTES INTERMEDIOS', 'bien', 'materia_prima', 'PZA', 440.0, 0, 'Puentes intermedios', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 440.0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'PUENTES INTERMEDIOS' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 440.0 > 0;
        END IF;

        -- Material: RECTA 3/8*1/4
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'RECTA 3/8*1/4' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'RECTA 3/8*1/4', 'bien', 'materia_prima', 'PZA', 0, 0, 'RECTA 3/8*1/4', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'RECTA 3/8*1/4' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: REDUCCION 3/4 * 1/2
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'REDUCCION 3/4 * 1/2' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'REDUCCION 3/4 * 1/2', 'bien', 'materia_prima', 'PZA', 0, 0, 'REDUCCION  3/4 * 1/2', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'REDUCCION 3/4 * 1/2' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: REDUCCION 3/8 * 1/4
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'REDUCCION 3/8 * 1/4' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'REDUCCION 3/8 * 1/4', 'bien', 'materia_prima', 'PZA', 0, 0, 'REDUCCION  3/8 * 1/4', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'REDUCCION 3/8 * 1/4' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: REFUERZO DE JALON
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'REFUERZO DE JALON' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'REFUERZO DE JALON', 'bien', 'materia_prima', 'PZA', 600.0, 0, 'Refuerzo de jalon', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 600.0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'REFUERZO DE JALON' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 600.0 > 0;
        END IF;

        -- Material: REMACHE 3/16 X 5/8
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'REMACHE 3/16 X 5/8' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'REMACHE 3/16 X 5/8', 'bien', 'materia_prima', 'PZA', 0, 0, 'REMACHE 3/16 X 5/8', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'REMACHE 3/16 X 5/8' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: RETRACTIL FABRICADO EN LEOLCA GRANDE ESLABONES DE CADENA 1/2
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'RETRACTIL FABRICADO EN LEOLCA GRANDE ESLABONES DE CADENA 1/2' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'RETRACTIL FABRICADO EN LEOLCA GRANDE ESLABONES DE CADENA 1/2', 'bien', 'materia_prima', 'PZA', 0, 0, 'RETRACTIL FABRICADO EN LEOLCA GRANDE ESLABONES DE CADENA 1/2', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'RETRACTIL FABRICADO EN LEOLCA GRANDE ESLABONES DE CADENA 1/2' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: RETRACTIL FABRICADO EN LEOLCA GRANDE RONDANA AUTOMOTRIZ 3/4
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'RETRACTIL FABRICADO EN LEOLCA GRANDE RONDANA AUTOMOTRIZ 3/4' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'RETRACTIL FABRICADO EN LEOLCA GRANDE RONDANA AUTOMOTRIZ 3/4', 'bien', 'materia_prima', 'PZA', 0, 0, 'RETRACTIL FABRICADO EN LEOLCA GRANDE RONDANA AUTOMOTRIZ 3/4', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'RETRACTIL FABRICADO EN LEOLCA GRANDE RONDANA AUTOMOTRIZ 3/4' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: RETRACTIL FABRICADO EN LEOLCA GRANDE RONDANA AUTOMOTRIZ 5/8
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'RETRACTIL FABRICADO EN LEOLCA GRANDE RONDANA AUTOMOTRIZ 5/8' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'RETRACTIL FABRICADO EN LEOLCA GRANDE RONDANA AUTOMOTRIZ 5/8', 'bien', 'materia_prima', 'PZA', 0, 0, 'RETRACTIL FABRICADO EN LEOLCA GRANDE RONDANA AUTOMOTRIZ 5/8', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'RETRACTIL FABRICADO EN LEOLCA GRANDE RONDANA AUTOMOTRIZ 5/8' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: RETRACTIL FABRICADO EN LEOLCA GRANDE TORNILLO 3/4 X 3 1/2 GRADO 8
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'RETRACTIL FABRICADO EN LEOLCA GRANDE TORNILLO 3/4 X 3 1/2 GRADO 8' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'RETRACTIL FABRICADO EN LEOLCA GRANDE TORNILLO 3/4 X 3 1/2 GRADO 8', 'bien', 'materia_prima', 'PZA', 0, 0, 'RETRACTIL FABRICADO EN LEOLCA GRANDE TORNILLO 3/4 X 3  1/2 GRADO 8', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'RETRACTIL FABRICADO EN LEOLCA GRANDE TORNILLO 3/4 X 3 1/2 GRADO 8' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: RETRACTIL FABRICADO EN LEOLCA GRANDE TORNILLO 3/4 X 6 GRADO 8
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'RETRACTIL FABRICADO EN LEOLCA GRANDE TORNILLO 3/4 X 6 GRADO 8' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'RETRACTIL FABRICADO EN LEOLCA GRANDE TORNILLO 3/4 X 6 GRADO 8', 'bien', 'materia_prima', 'PZA', 0, 0, 'RETRACTIL FABRICADO EN LEOLCA GRANDE TORNILLO 3/4 X 6 GRADO 8', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'RETRACTIL FABRICADO EN LEOLCA GRANDE TORNILLO 3/4 X 6 GRADO 8' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: RETRACTIL FABRICADO EN LEOLCA GRANDE TORNILLO 3/4*6 GRADO 8
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'RETRACTIL FABRICADO EN LEOLCA GRANDE TORNILLO 3/4*6 GRADO 8' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'RETRACTIL FABRICADO EN LEOLCA GRANDE TORNILLO 3/4*6 GRADO 8', 'bien', 'materia_prima', 'PZA', 0, 0, 'RETRACTIL FABRICADO EN LEOLCA GRANDE TORNILLO 3/4*6 GRADO 8', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'RETRACTIL FABRICADO EN LEOLCA GRANDE TORNILLO 3/4*6 GRADO 8' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: RETRACTIL FABRICADO EN LEOLCA GRANDE TORNILLO 5/8*3 GRADO 8
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'RETRACTIL FABRICADO EN LEOLCA GRANDE TORNILLO 5/8*3 GRADO 8' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'RETRACTIL FABRICADO EN LEOLCA GRANDE TORNILLO 5/8*3 GRADO 8', 'bien', 'materia_prima', 'PZA', 0, 0, 'RETRACTIL FABRICADO EN LEOLCA GRANDE TORNILLO 5/8*3 GRADO 8', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'RETRACTIL FABRICADO EN LEOLCA GRANDE TORNILLO 5/8*3 GRADO 8' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: RETRACTIL FABRICADO EN LEOLCA GRANDE TORNILLO 5/8*5 GRADO 8
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'RETRACTIL FABRICADO EN LEOLCA GRANDE TORNILLO 5/8*5 GRADO 8' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'RETRACTIL FABRICADO EN LEOLCA GRANDE TORNILLO 5/8*5 GRADO 8', 'bien', 'materia_prima', 'PZA', 0, 0, 'RETRACTIL FABRICADO EN LEOLCA GRANDE TORNILLO 5/8*5 GRADO 8', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'RETRACTIL FABRICADO EN LEOLCA GRANDE TORNILLO 5/8*5 GRADO 8' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: RETRACTIL FABRICADO EN LEOLCA GRANDE TUERCA DE SEGURIDAD 3/4
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'RETRACTIL FABRICADO EN LEOLCA GRANDE TUERCA DE SEGURIDAD 3/4' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'RETRACTIL FABRICADO EN LEOLCA GRANDE TUERCA DE SEGURIDAD 3/4', 'bien', 'materia_prima', 'PZA', 0, 0, 'RETRACTIL FABRICADO EN LEOLCA GRANDE TUERCA DE SEGURIDAD 3/4', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'RETRACTIL FABRICADO EN LEOLCA GRANDE TUERCA DE SEGURIDAD 3/4' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: RETRACTIL FABRICADO EN LEOLCA GRANDE TUERCA DE SEGURIDAD 5/8
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'RETRACTIL FABRICADO EN LEOLCA GRANDE TUERCA DE SEGURIDAD 5/8' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'RETRACTIL FABRICADO EN LEOLCA GRANDE TUERCA DE SEGURIDAD 5/8', 'bien', 'materia_prima', 'PZA', 0, 0, 'RETRACTIL FABRICADO EN LEOLCA GRANDE TUERCA DE SEGURIDAD 5/8', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'RETRACTIL FABRICADO EN LEOLCA GRANDE TUERCA DE SEGURIDAD 5/8' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: RIN DE ACERO ACURRAI
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'RIN DE ACERO ACURRAI' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'RIN DE ACERO ACURRAI', 'bien', 'materia_prima', 'PZA', 0, 0, 'RIN DE ACERO ACURRAI', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'RIN DE ACERO ACURRAI' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: RIN DE ACERO AMPRO
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'RIN DE ACERO AMPRO' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'RIN DE ACERO AMPRO', 'bien', 'materia_prima', 'PZA', 0, 0, 'RIN DE ACERO AMPRO', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'RIN DE ACERO AMPRO' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: RIN DE ACERO FLEET MASTER
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'RIN DE ACERO FLEET MASTER' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'RIN DE ACERO FLEET MASTER', 'bien', 'materia_prima', 'PZA', 0, 0, 'RIN DE ACERO FLET MASTER', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'RIN DE ACERO FLEET MASTER' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: RIN DE ALUMINIO AMPRO
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'RIN DE ALUMINIO AMPRO' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'RIN DE ALUMINIO AMPRO', 'bien', 'materia_prima', 'PZA', 0, 0, 'RIN DE AUMINIO AMPRO', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'RIN DE ALUMINIO AMPRO' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: RIN DE ALUMINIO AMPRO MASTER TRAPEZOIDAL
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'RIN DE ALUMINIO AMPRO MASTER TRAPEZOIDAL' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'RIN DE ALUMINIO AMPRO MASTER TRAPEZOIDAL', 'bien', 'materia_prima', 'PZA', 0, 0, 'RIN DE AUMINIO AMPRO MASTER TRAPEZOIDAL', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'RIN DE ALUMINIO AMPRO MASTER TRAPEZOIDAL' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: RIN DE ALUMINIO FLEET MASTER
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'RIN DE ALUMINIO FLEET MASTER' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'RIN DE ALUMINIO FLEET MASTER', 'bien', 'materia_prima', 'PZA', 0, 0, 'RIN DE AUMINIO FLET MASTER', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'RIN DE ALUMINIO FLEET MASTER' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: RIN DE ALUMINIO FLEET MASTER TRAPEZOIDAL
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'RIN DE ALUMINIO FLEET MASTER TRAPEZOIDAL' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'RIN DE ALUMINIO FLEET MASTER TRAPEZOIDAL', 'bien', 'materia_prima', 'PZA', 0, 0, 'RIN DE AUMINIO FLET MASTER TRAPEZOIDAL', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'RIN DE ALUMINIO FLEET MASTER TRAPEZOIDAL' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: ROLLO DE MICRO ALAMBRE
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'ROLLO DE MICRO ALAMBRE' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'ROLLO DE MICRO ALAMBRE', 'bien', 'materia_prima', 'PZA', 0, 0, 'ROLLO DE MICRO ALAMBRE', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'ROLLO DE MICRO ALAMBRE' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: ROLLO DE MICROALAMBRE
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'ROLLO DE MICROALAMBRE' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'ROLLO DE MICROALAMBRE', 'bien', 'materia_prima', 'PZA', 0, 0, 'ROLLO DE MICROALAMBRE', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'ROLLO DE MICROALAMBRE' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: RONDANA AUTOMOTRIZ 3/4
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'RONDANA AUTOMOTRIZ 3/4' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'RONDANA AUTOMOTRIZ 3/4', 'bien', 'materia_prima', 'PZA', 0, 0, 'RONDANA AUTOMOTRIZ 3/4', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'RONDANA AUTOMOTRIZ 3/4' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: RONDANA PLANA 1/2
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'RONDANA PLANA 1/2' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'RONDANA PLANA 1/2', 'bien', 'materia_prima', 'PZA', 0, 0, 'RONDANA PLANA 1/2', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'RONDANA PLANA 1/2' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: RONDANA PLANA 3/8
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'RONDANA PLANA 3/8' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'RONDANA PLANA 3/8', 'bien', 'materia_prima', 'PZA', 0, 0, 'RONDANA PLANA 3/8', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'RONDANA PLANA 3/8' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: RONDANA PLANA 5/16
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'RONDANA PLANA 5/16' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'RONDANA PLANA 5/16', 'bien', 'materia_prima', 'PZA', 0, 0, 'RONDANA PLANA 5/16', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'RONDANA PLANA 5/16' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: RONDANAS CENTRICAS GABRIEL
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'RONDANAS CENTRICAS GABRIEL' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'RONDANAS CENTRICAS GABRIEL', 'bien', 'materia_prima', 'PZA', 0, 0, 'RONDANAS CENTRICAS GABRIEL', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'RONDANAS CENTRICAS GABRIEL' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: RONDANAS CENTRICAS HENDRICKSON GABRIEL
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'RONDANAS CENTRICAS HENDRICKSON GABRIEL' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'RONDANAS CENTRICAS HENDRICKSON GABRIEL', 'bien', 'materia_prima', 'PZA', 0, 0, 'RONDANAS CENTRICAS HENDRICKSON GABRIEL', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'RONDANAS CENTRICAS HENDRICKSON GABRIEL' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: RONDANAS CENTRICAS HENDRICKSON HENDRICKSON C-25319 O R14-152
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'RONDANAS CENTRICAS HENDRICKSON HENDRICKSON C-25319 O R14-152' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'RONDANAS CENTRICAS HENDRICKSON HENDRICKSON C-25319 O R14-152', 'bien', 'materia_prima', 'PZA', 0, 0, 'RONDANAS CENTRICAS HENDRICKSON HENDRICKSON C-25319 O R14-152', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'RONDANAS CENTRICAS HENDRICKSON HENDRICKSON C-25319 O R14-152' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: RONDANAS CENTRICAS HENDRICKSON HENDRICKSON R14-083-38
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'RONDANAS CENTRICAS HENDRICKSON HENDRICKSON R14-083-38' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'RONDANAS CENTRICAS HENDRICKSON HENDRICKSON R14-083-38', 'bien', 'materia_prima', 'PZA', 0, 0, 'RONDANAS CENTRICAS HENDRICKSON HENDRICKSON R14-083-38', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'RONDANAS CENTRICAS HENDRICKSON HENDRICKSON R14-083-38' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: RONDANAS EXCENTRICAS GABRIEL
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'RONDANAS EXCENTRICAS GABRIEL' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'RONDANAS EXCENTRICAS GABRIEL', 'bien', 'materia_prima', 'PZA', 0, 0, 'RONDANAS EXCENTRICAS GABRIEL', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'RONDANAS EXCENTRICAS GABRIEL' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: RONDANAS EXCENTRICAS HENDRICKSON GABRIEL
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'RONDANAS EXCENTRICAS HENDRICKSON GABRIEL' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'RONDANAS EXCENTRICAS HENDRICKSON GABRIEL', 'bien', 'materia_prima', 'PZA', 0, 0, 'RONDANAS EXCENTRICAS HENDRICKSON GABRIEL', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'RONDANAS EXCENTRICAS HENDRICKSON GABRIEL' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: RONDANAS EXCENTRICAS HENDRICKSON HENDRICKSON C-25319 O R14-152
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'RONDANAS EXCENTRICAS HENDRICKSON HENDRICKSON C-25319 O R14-152' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'RONDANAS EXCENTRICAS HENDRICKSON HENDRICKSON C-25319 O R14-152', 'bien', 'materia_prima', 'PZA', 0, 0, 'RONDANAS EXCENTRICAS HENDRICKSON HENDRICKSON C-25319 O R14-152', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'RONDANAS EXCENTRICAS HENDRICKSON HENDRICKSON C-25319 O R14-152' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: RONDANAS EXCENTRICAS HENDRICKSON HENDRICKSON R14-083-38
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'RONDANAS EXCENTRICAS HENDRICKSON HENDRICKSON R14-083-38' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'RONDANAS EXCENTRICAS HENDRICKSON HENDRICKSON R14-083-38', 'bien', 'materia_prima', 'PZA', 0, 0, 'RONDANAS EXCENTRICAS HENDRICKSON HENDRICKSON R14-083-38', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'RONDANAS EXCENTRICAS HENDRICKSON HENDRICKSON R14-083-38' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: RONDANAS PLANAS 3/8
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'RONDANAS PLANAS 3/8' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'RONDANAS PLANAS 3/8', 'bien', 'materia_prima', 'PZA', 0, 0, 'RONDANAS PLANAS 3/8', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'RONDANAS PLANAS 3/8' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: SISTEMA RETRACTIL CHICO RETRACTIL UBL ORIGINAL
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'SISTEMA RETRACTIL CHICO RETRACTIL UBL ORIGINAL' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'SISTEMA RETRACTIL CHICO RETRACTIL UBL ORIGINAL', 'bien', 'materia_prima', 'PZA', 0, 0, 'SISTEMA RETRACTIL CHICO Retractil UBL original', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'SISTEMA RETRACTIL CHICO RETRACTIL UBL ORIGINAL' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: SISTEMA RETRACTIL CHICO RETRACTIL UBL PROPIO
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'SISTEMA RETRACTIL CHICO RETRACTIL UBL PROPIO' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'SISTEMA RETRACTIL CHICO RETRACTIL UBL PROPIO', 'bien', 'materia_prima', 'PZA', 0, 0, 'SISTEMA RETRACTIL CHICO Retractil UBL propio', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'SISTEMA RETRACTIL CHICO RETRACTIL UBL PROPIO' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: SISTEMA RETRACTIL GRANDE
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'SISTEMA RETRACTIL GRANDE' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'SISTEMA RETRACTIL GRANDE', 'bien', 'materia_prima', 'PZA', 0, 0, 'SISTEMA RETRACTIL GRANDE', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'SISTEMA RETRACTIL GRANDE' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: SISTEMA RETRACTIL GRANDE RETRACTIL GRANDE ORIGINAL
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'SISTEMA RETRACTIL GRANDE RETRACTIL GRANDE ORIGINAL' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'SISTEMA RETRACTIL GRANDE RETRACTIL GRANDE ORIGINAL', 'bien', 'materia_prima', 'PZA', 0, 0, 'SISTEMA RETRACTIL GRANDE Retractil grande original', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'SISTEMA RETRACTIL GRANDE RETRACTIL GRANDE ORIGINAL' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: SISTEMA RETRACTIL GRANDE RETRACTIL GRANDE PROPIO
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'SISTEMA RETRACTIL GRANDE RETRACTIL GRANDE PROPIO' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'SISTEMA RETRACTIL GRANDE RETRACTIL GRANDE PROPIO', 'bien', 'materia_prima', 'PZA', 0, 0, 'SISTEMA RETRACTIL GRANDE Retractil grande propio', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'SISTEMA RETRACTIL GRANDE RETRACTIL GRANDE PROPIO' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: SOLERA PARA ALMAS (SOLERA DE GRADO A-529 A 1/2" X 6")
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'SOLERA PARA ALMAS (SOLERA DE GRADO A-529 A 1/2" X 6")' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'SOLERA PARA ALMAS (SOLERA DE GRADO A-529 A 1/2" X 6")', 'bien', 'materia_prima', 'PZA', 4884.75, 0, 'Solera para almas (Solera de grado A-529 a 1/2" X 6")', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 4884.75, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'SOLERA PARA ALMAS (SOLERA DE GRADO A-529 A 1/2" X 6")' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 4884.75 > 0;
        END IF;

        -- Material: SOLERA PARA ESQUINEROS
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'SOLERA PARA ESQUINEROS' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'SOLERA PARA ESQUINEROS', 'bien', 'materia_prima', 'PZA', 60.6, 0, 'Solera para esquineros', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 60.6, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'SOLERA PARA ESQUINEROS' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 60.6 > 0;
        END IF;

        -- Material: SUSPENSION AMPRO HT300 ( SUSPENSION NORMAL)
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'SUSPENSION AMPRO HT300 ( SUSPENSION NORMAL)' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'SUSPENSION AMPRO HT300 ( SUSPENSION NORMAL)', 'bien', 'materia_prima', 'PZA', 0, 0, 'SUSPENSION AMPRO HT300 ( SUSPENSION NORMAL)', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'SUSPENSION AMPRO HT300 ( SUSPENSION NORMAL)' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: SUSPENSION FCR HT300 ( SUSPENSION NORMAL)
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'SUSPENSION FCR HT300 ( SUSPENSION NORMAL)' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'SUSPENSION FCR HT300 ( SUSPENSION NORMAL)', 'bien', 'materia_prima', 'PZA', 0, 0, 'SUSPENSION FCR HT300 ( SUSPENSION NORMAL)', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'SUSPENSION FCR HT300 ( SUSPENSION NORMAL)' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: SUSPENSION FLEET MASTER HT300 ( SUSPENSION NORMAL)
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'SUSPENSION FLEET MASTER HT300 ( SUSPENSION NORMAL)' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'SUSPENSION FLEET MASTER HT300 ( SUSPENSION NORMAL)', 'bien', 'materia_prima', 'PZA', 0, 0, 'SUSPENSION FLET MASTER HT300 ( SUSPENSION NORMAL)', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'SUSPENSION FLEET MASTER HT300 ( SUSPENSION NORMAL)' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: SUSPENSION HENDRICKSON HT300 ( SUSPENSION NORMAL)
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'SUSPENSION HENDRICKSON HT300 ( SUSPENSION NORMAL)' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'SUSPENSION HENDRICKSON HT300 ( SUSPENSION NORMAL)', 'bien', 'materia_prima', 'PZA', 0, 0, 'SUSPENSION HENDRICKSON HT300 ( SUSPENSION NORMAL)', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'SUSPENSION HENDRICKSON HT300 ( SUSPENSION NORMAL)' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: SUSPENSION HENDRICKSON HT300US ( SUSPENSION ALTA)
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'SUSPENSION HENDRICKSON HT300US ( SUSPENSION ALTA)' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'SUSPENSION HENDRICKSON HT300US ( SUSPENSION ALTA)', 'bien', 'materia_prima', 'PZA', 0, 0, 'SUSPENSION HENDRICKSON HT300US ( SUSPENSION ALTA)', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'SUSPENSION HENDRICKSON HT300US ( SUSPENSION ALTA)' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: TANQUE DE AIRE DE PLANA
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'TANQUE DE AIRE DE PLANA' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'TANQUE DE AIRE DE PLANA', 'bien', 'materia_prima', 'PZA', 0, 0, 'TANQUE DE AIRE DE PLANA', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'TANQUE DE AIRE DE PLANA' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: TAPA PARA PERNO REY
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'TAPA PARA PERNO REY' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'TAPA PARA PERNO REY', 'bien', 'materia_prima', 'KG', 100.0, 0, 'Tapa para perno rey', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 100.0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'TAPA PARA PERNO REY' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 100.0 > 0;
        END IF;

        -- Material: TAPON 1/2
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'TAPON 1/2' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'TAPON 1/2', 'bien', 'materia_prima', 'PZA', 0, 0, 'TAPON 1/2', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'TAPON 1/2' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: TAPON 1/4 SUSPENSION FM + 4
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'TAPON 1/4 SUSPENSION FM + 4' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'TAPON 1/4 SUSPENSION FM + 4', 'bien', 'materia_prima', 'PZA', 0, 0, 'TAPON 1/4 SUSPENSION FM + 4', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'TAPON 1/4 SUSPENSION FM + 4' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: TAPON 1/8
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'TAPON 1/8' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'TAPON 1/8', 'bien', 'materia_prima', 'PZA', 0, 0, 'TAPON 1/8', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'TAPON 1/8' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: TAPON 3/4
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'TAPON 3/4' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'TAPON 3/4', 'bien', 'materia_prima', 'PZA', 0, 0, 'TAPON 3/4', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'TAPON 3/4' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: TE CENTRO 3/8*1/4
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'TE CENTRO 3/8*1/4' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'TE CENTRO 3/8*1/4', 'bien', 'materia_prima', 'PZA', 0, 0, 'TE CENTRO 3/8*1/4', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'TE CENTRO 3/8*1/4' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: TE LATERAL 3/8*1/4
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'TE LATERAL 3/8*1/4' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'TE LATERAL 3/8*1/4', 'bien', 'materia_prima', 'PZA', 0, 0, 'TE LATERAL 3/8*1/4', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'TE LATERAL 3/8*1/4' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: TE UNIO 3/8
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'TE UNIO 3/8' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'TE UNIO 3/8', 'bien', 'materia_prima', 'PZA', 0, 0, 'TE UNIO 3/8', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'TE UNIO 3/8' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: TEFLON DE 13 METROS
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'TEFLON DE 13 METROS' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'TEFLON DE 13 METROS', 'bien', 'materia_prima', 'PZA', 0, 0, 'TEFLON DE 13 METROS', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'TEFLON DE 13 METROS' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: TERMINAL 1/4
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'TERMINAL 1/4' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'TERMINAL 1/4', 'bien', 'materia_prima', 'PZA', 0, 0, 'TERMINAL 1/4', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'TERMINAL 1/4' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: TERMINAL 3/16
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'TERMINAL 3/16' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'TERMINAL 3/16', 'bien', 'materia_prima', 'PZA', 0, 0, 'TERMINAL 3/16', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'TERMINAL 3/16' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: TOPE DE HULE 3 BARRENOS
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'TOPE DE HULE 3 BARRENOS' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'TOPE DE HULE 3 BARRENOS', 'bien', 'materia_prima', 'PZA', 0, 0, 'TOPE DE HULE  3 BARRENOS', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'TOPE DE HULE 3 BARRENOS' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: TORNILLO 1/2 X 2 1/2 GALVANIZADO
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'TORNILLO 1/2 X 2 1/2 GALVANIZADO' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'TORNILLO 1/2 X 2 1/2 GALVANIZADO', 'bien', 'materia_prima', 'PZA', 0, 0, 'TORNILLO 1/2 X 2 1/2 GALVANIZADO', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'TORNILLO 1/2 X 2 1/2 GALVANIZADO' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: TORNILLO 1/2X 1 3/4
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'TORNILLO 1/2X 1 3/4' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'TORNILLO 1/2X 1 3/4', 'bien', 'materia_prima', 'PZA', 0, 0, 'TORNILLO 1/2X 1 3/4', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'TORNILLO 1/2X 1 3/4' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: TORNILLO 1/4X1 ACERO INOXIDABLE
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'TORNILLO 1/4X1 ACERO INOXIDABLE' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'TORNILLO 1/4X1 ACERO INOXIDABLE', 'bien', 'materia_prima', 'PZA', 0, 0, 'TORNILLO 1/4X1 ACERO INOXIDABLE', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'TORNILLO 1/4X1 ACERO INOXIDABLE' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: TORNILLO 1/4X1 GALVANIZADO
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'TORNILLO 1/4X1 GALVANIZADO' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'TORNILLO 1/4X1 GALVANIZADO', 'bien', 'materia_prima', 'PZA', 0, 0, 'TORNILLO 1/4X1 GALVANIZADO', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'TORNILLO 1/4X1 GALVANIZADO' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: TORNILLO 1/8X 1 1/4
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'TORNILLO 1/8X 1 1/4' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'TORNILLO 1/8X 1 1/4', 'bien', 'materia_prima', 'PZA', 0, 0, 'TORNILLO 1/8X 1 1/4', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'TORNILLO 1/8X 1 1/4' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: TORNILLO 3/4X 2 1/2 GRADO 8
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'TORNILLO 3/4X 2 1/2 GRADO 8' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'TORNILLO 3/4X 2 1/2 GRADO 8', 'bien', 'materia_prima', 'PZA', 0, 0, 'TORNILLO 3/4X 2 1/2 GRADO 8', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'TORNILLO 3/4X 2 1/2 GRADO 8' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: TORNILLO 3/4X3 1/2 GRADO 8
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'TORNILLO 3/4X3 1/2 GRADO 8' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'TORNILLO 3/4X3 1/2 GRADO 8', 'bien', 'materia_prima', 'PZA', 0, 0, 'TORNILLO 3/4X3 1/2 GRADO 8', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'TORNILLO 3/4X3 1/2 GRADO 8' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: TORNILLO 3/8 X 1 GRADO 8
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'TORNILLO 3/8 X 1 GRADO 8' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'TORNILLO 3/8 X 1 GRADO 8', 'bien', 'materia_prima', 'PZA', 0, 0, 'TORNILLO 3/8 X 1 GRADO 8', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'TORNILLO 3/8 X 1 GRADO 8' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: TORNILLO 3/8 X 3/4 GRADO 8
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'TORNILLO 3/8 X 3/4 GRADO 8' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'TORNILLO 3/8 X 3/4 GRADO 8', 'bien', 'materia_prima', 'PZA', 0, 0, 'TORNILLO 3/8 X 3/4 GRADO 8', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'TORNILLO 3/8 X 3/4 GRADO 8' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: TORNILLO 5/16 X 5 GRADO 8
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'TORNILLO 5/16 X 5 GRADO 8' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'TORNILLO 5/16 X 5 GRADO 8', 'bien', 'materia_prima', 'PZA', 0, 0, 'TORNILLO 5/16 X 5 GRADO 8', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'TORNILLO 5/16 X 5 GRADO 8' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: TORNILLO CABEZA DE COCHE 1/4 X 1 1/2
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'TORNILLO CABEZA DE COCHE 1/4 X 1 1/2' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'TORNILLO CABEZA DE COCHE 1/4 X 1 1/2', 'bien', 'materia_prima', 'PZA', 0, 0, 'TORNILLO CABEZA DE COCHE 1/4 X 1 1/2', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'TORNILLO CABEZA DE COCHE 1/4 X 1 1/2' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: TUBOS LATERALES
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'TUBOS LATERALES' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'TUBOS LATERALES', 'bien', 'materia_prima', 'PZA', 12.0, 0, 'Tubos laterales', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 12.0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'TUBOS LATERALES' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 12.0 > 0;
        END IF;

        -- Material: TUERCA DE SEGURIDAD 1/2
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'TUERCA DE SEGURIDAD 1/2' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'TUERCA DE SEGURIDAD 1/2', 'bien', 'materia_prima', 'PZA', 0, 0, 'TUERCA DE SEGURIDAD 1/2', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'TUERCA DE SEGURIDAD 1/2' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: TUERCA DE SEGURIDAD 1/4
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'TUERCA DE SEGURIDAD 1/4' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'TUERCA DE SEGURIDAD 1/4', 'bien', 'materia_prima', 'PZA', 0, 0, 'TUERCA DE SEGURIDAD 1/4', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'TUERCA DE SEGURIDAD 1/4' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: TUERCA DE SEGURIDAD 3/8
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'TUERCA DE SEGURIDAD 3/8' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'TUERCA DE SEGURIDAD 3/8', 'bien', 'materia_prima', 'PZA', 0, 0, 'TUERCA DE SEGURIDAD 3/8', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'TUERCA DE SEGURIDAD 3/8' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: TUERCA DE SEGURIDAD 5/16
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'TUERCA DE SEGURIDAD 5/16' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'TUERCA DE SEGURIDAD 5/16', 'bien', 'materia_prima', 'PZA', 0, 0, 'TUERCA DE SEGURIDAD 5/16', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'TUERCA DE SEGURIDAD 5/16' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: TUERCA ESTANDAR 1/2 GALVANIZADA
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'TUERCA ESTANDAR 1/2 GALVANIZADA' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'TUERCA ESTANDAR 1/2 GALVANIZADA', 'bien', 'materia_prima', 'PZA', 0, 0, 'TUERCA ESTANDAR  1/2 GALVANIZADA', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'TUERCA ESTANDAR 1/2 GALVANIZADA' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: TUERCA ESTANDAR 1/4
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'TUERCA ESTANDAR 1/4' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'TUERCA ESTANDAR 1/4', 'bien', 'materia_prima', 'PZA', 0, 0, 'TUERCA ESTANDAR 1/4', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'TUERCA ESTANDAR 1/4' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: TUERCA ESTANDAR 1/8
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'TUERCA ESTANDAR 1/8' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'TUERCA ESTANDAR 1/8', 'bien', 'materia_prima', 'PZA', 0, 0, 'TUERCA ESTANDAR 1/8', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'TUERCA ESTANDAR 1/8' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: TUERCA GRIPCO 3/4
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'TUERCA GRIPCO 3/4' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'TUERCA GRIPCO 3/4', 'bien', 'materia_prima', 'PZA', 0, 0, 'TUERCA GRIPCO 3/4', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'TUERCA GRIPCO 3/4' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: TUERCA ROSCA MILIMETRICA 3/4
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'TUERCA ROSCA MILIMETRICA 3/4' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'TUERCA ROSCA MILIMETRICA 3/4', 'bien', 'materia_prima', 'PZA', 0, 0, 'TUERCA ROSCA MILIMETRICA 3/4', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'TUERCA ROSCA MILIMETRICA 3/4' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: TUERCAS DE SEGURIDAD 1/2
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'TUERCAS DE SEGURIDAD 1/2' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'TUERCAS DE SEGURIDAD 1/2', 'bien', 'materia_prima', 'PZA', 0, 0, 'TUERCAS DE SEGURIDAD 1/2', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'TUERCAS DE SEGURIDAD 1/2' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: U PARA JALON
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'U PARA JALON' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'U PARA JALON', 'bien', 'materia_prima', 'PZA', 102.0, 0, 'U para jalon', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 102.0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'U PARA JALON' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 102.0 > 0;
        END IF;

        -- Material: VALVULA NIVELADORA
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'VALVULA NIVELADORA' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'VALVULA NIVELADORA', 'bien', 'materia_prima', 'PZA', 0, 0, 'VALVULA NIVELADORA', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'VALVULA NIVELADORA' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: VALVULA PALANQUETA
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'VALVULA PALANQUETA' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'VALVULA PALANQUETA', 'bien', 'materia_prima', 'PZA', 0, 0, 'VALVULA PALANQUETA', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'VALVULA PALANQUETA' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: VALVULA PROTECTORA
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'VALVULA PROTECTORA' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'VALVULA PROTECTORA', 'bien', 'materia_prima', 'PZA', 0, 0, 'VALVULA PROTECTORA', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'VALVULA PROTECTORA' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: VALVULA RETRACTIL SEALCO
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'VALVULA RETRACTIL SEALCO' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'VALVULA RETRACTIL SEALCO', 'bien', 'materia_prima', 'PZA', 0, 0, 'VALVULA RETRACTIL SEALCO', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'VALVULA RETRACTIL SEALCO' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: VARILLA NIVELADORA
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'VARILLA NIVELADORA' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'VARILLA NIVELADORA', 'bien', 'materia_prima', 'PZA', 0, 0, 'VARILLA NIVELADORA', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'VARILLA NIVELADORA' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;

        -- Material: WINCHES
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = 'WINCHES' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, 'WINCHES', 'bien', 'materia_prima', 'PZA', 0, 0, 'WINCHES', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = 0, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = 'WINCHES' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND 0 > 0;
        END IF;


        -- D. Actualizar fase_id en receta_base y opcion_componentes existentes según equivalencias
        UPDATE receta_base rb
        SET fase_id = fe.fase_id
        FROM fases_despiece_equivalencias fe
        WHERE fe.organizacion_id = r_org.id
          AND upper(trim(rb.paso)) = upper(trim(fe.paso_legacy))
          AND (rb.fase_id IS NULL OR rb.fase_id != fe.fase_id);

        UPDATE opcion_componentes oc
        SET fase_id = fe.fase_id
        FROM fases_despiece_equivalencias fe
        WHERE fe.organizacion_id = r_org.id
          AND upper(trim(oc.paso)) = upper(trim(fe.paso_legacy))
          AND (oc.fase_id IS NULL OR oc.fase_id != fe.fase_id);

    END LOOP;
END $$;

COMMIT;
