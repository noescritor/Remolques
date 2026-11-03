-- Migración 20261102_01_despiece_union.sql
-- T2 Ronda 2: Despiece oficial por fases desde UNION DE LISTADOS
-- Corrección integral de RLS, esquema real, carga de árbol y aislamiento entre organizaciones

BEGIN;

-- 0. Columna notas en productos para trazabilidad de importación (ej. 'import-union-2026-11')
ALTER TABLE public.productos ADD COLUMN IF NOT EXISTS notas TEXT;

-- 1. Catálogo oficial de fases_despiece y equivalencias
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
    USING (organizacion_id = get_current_org_id());

DROP POLICY IF EXISTS "fases_despiece_org_all" ON fases_despiece;
CREATE POLICY "fases_despiece_org_all" ON fases_despiece
    FOR ALL TO authenticated
    USING (organizacion_id = get_current_org_id())
    WITH CHECK (organizacion_id = get_current_org_id());

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
    USING (organizacion_id = get_current_org_id());

DROP POLICY IF EXISTS "fases_equivalencias_org_all" ON fases_despiece_equivalencias;
CREATE POLICY "fases_equivalencias_org_all" ON fases_despiece_equivalencias
    FOR ALL TO authenticated
    USING (organizacion_id = get_current_org_id())
    WITH CHECK (organizacion_id = get_current_org_id());

-- 2. Adición de columna fase_id en receta_base y opcion_componentes
ALTER TABLE receta_base ADD COLUMN IF NOT EXISTS fase_id UUID REFERENCES fases_despiece(id);
ALTER TABLE opcion_componentes ADD COLUMN IF NOT EXISTS fase_id UUID REFERENCES fases_despiece(id);


DO $$
DECLARE
    r_org RECORD;
    v_fase_id UUID;
    v_cat_id UUID;
    v_mat_id TEXT;
    v_modelo_id UUID;
    v_opcion_id UUID;
    v_grupo_id UUID;
BEGIN
    FOR r_org IN SELECT id FROM organizaciones LOOP

        -- A. Garantizar categorías estándar para kit/fase

        IF NOT EXISTS (SELECT 1 FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Acero y Estructura'))) THEN
            INSERT INTO categorias_producto (organizacion_id, nombre, orden)
            VALUES (r_org.id, 'Acero y Estructura', 10);
        END IF;

        IF NOT EXISTS (SELECT 1 FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Tornillería'))) THEN
            INSERT INTO categorias_producto (organizacion_id, nombre, orden)
            VALUES (r_org.id, 'Tornillería', 10);
        END IF;

        IF NOT EXISTS (SELECT 1 FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Aire y Frenos ABS'))) THEN
            INSERT INTO categorias_producto (organizacion_id, nombre, orden)
            VALUES (r_org.id, 'Aire y Frenos ABS', 10);
        END IF;

        IF NOT EXISTS (SELECT 1 FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Iluminación y Eléctrico'))) THEN
            INSERT INTO categorias_producto (organizacion_id, nombre, orden)
            VALUES (r_org.id, 'Iluminación y Eléctrico', 10);
        END IF;

        IF NOT EXISTS (SELECT 1 FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Pintura y Preparación'))) THEN
            INSERT INTO categorias_producto (organizacion_id, nombre, orden)
            VALUES (r_org.id, 'Pintura y Preparación', 10);
        END IF;

        IF NOT EXISTS (SELECT 1 FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Pisos y Madera'))) THEN
            INSERT INTO categorias_producto (organizacion_id, nombre, orden)
            VALUES (r_org.id, 'Pisos y Madera', 10);
        END IF;

        IF NOT EXISTS (SELECT 1 FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Acabados y Rotulación'))) THEN
            INSERT INTO categorias_producto (organizacion_id, nombre, orden)
            VALUES (r_org.id, 'Acabados y Rotulación', 10);
        END IF;

        IF NOT EXISTS (SELECT 1 FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Suspensión'))) THEN
            INSERT INTO categorias_producto (organizacion_id, nombre, orden)
            VALUES (r_org.id, 'Suspensión', 10);
        END IF;

        IF NOT EXISTS (SELECT 1 FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Patines y Ejes'))) THEN
            INSERT INTO categorias_producto (organizacion_id, nombre, orden)
            VALUES (r_org.id, 'Patines y Ejes', 10);
        END IF;

        IF NOT EXISTS (SELECT 1 FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Llantas y Rines'))) THEN
            INSERT INTO categorias_producto (organizacion_id, nombre, orden)
            VALUES (r_org.id, 'Llantas y Rines', 10);
        END IF;

        IF NOT EXISTS (SELECT 1 FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Consumibles'))) THEN
            INSERT INTO categorias_producto (organizacion_id, nombre, orden)
            VALUES (r_org.id, 'Consumibles', 10);
        END IF;


        -- B. Poblar fases_despiece (14 fases oficiales)

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


        -- C. Poblar fases_despiece_equivalencias (22 equivalencias históricas)

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

        SELECT id INTO v_fase_id FROM fases_despiece WHERE organizacion_id = r_org.id AND clave = 'paso_7';
        IF v_fase_id IS NOT NULL THEN
            INSERT INTO fases_despiece_equivalencias (organizacion_id, paso_legacy, fase_id, notas)
            VALUES (r_org.id, 'LIMPIEZA', v_fase_id, 'Equivalencia histórica limpieza -> Paso 7 (Lavado químico y preparación)')
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


        -- D. Insertar materias primas normalizadas de UNION DE LISTADOS (sin costo = NULL, precio_unitario = NULL)

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Suspensión')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'ABRAZADERAS AMPRO GABRIEL' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'ABRAZADERAS AMPRO GABRIEL', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'ABRAZADERAS AMPRO GABRIEL', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Suspensión')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'ABRAZADERAS FLEET MASTER GABRIEL' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'ABRAZADERAS FLEET MASTER GABRIEL', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'ABRAZADERAS FLET MASTER GABRIEL', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Suspensión')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'ABRAZADERAS HENDRICKSON C-25319 O R14-152' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'ABRAZADERAS HENDRICKSON C-25319 O R14-152', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'ABRAZADERAS HENDRICKSON C-25319 O R14-152', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Suspensión')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'ABRAZADERAS HENDRICKSON R14-083-38' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'ABRAZADERAS HENDRICKSON R14-083-38', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'ABRAZADERAS HENDRICKSON R14-083-38', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Aire y Frenos ABS')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'ADAPTADOR 3/8' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'ADAPTADOR 3/8', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'ADAPTADOR 3/8', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Acero y Estructura')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'ALMA(PLACA DE GRADO A-50 CAL. 1/4")' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'ALMA(PLACA DE GRADO A-50 CAL. 1/4")', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'Alma (Placa de grado A-50 Cal. 1/4")', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Suspensión')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'AMORTIGUADOR FCR' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'AMORTIGUADOR FCR', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'AMORTIGUADOR FCR', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Suspensión')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'AMORTIGUADOR FLEET MASTER 323' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'AMORTIGUADOR FLEET MASTER 323', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'AMORTIGUADOR FLET MASTER 323', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Suspensión')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'AMORTIGUADOR GABRIEL' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'AMORTIGUADOR GABRIEL', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'AMORTIGUADOR GABRIEL', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Suspensión')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'AMORTIGUADOR HENDRICKSON 20126' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'AMORTIGUADOR HENDRICKSON 20126', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'AMORTIGUADOR HENDRICKSON 20126', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Suspensión')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'AMORTIGUADOR HENDRICKSON 23743' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'AMORTIGUADOR HENDRICKSON 23743', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'AMORTIGUADOR HENDRICKSON 23743', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Suspensión')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'AMORTIGUADOR MONROE 65512' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'AMORTIGUADOR MONROE 65512', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'AMORTIGUADOR MONRROE 65512', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Acero y Estructura')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'ATIZADORES EXTERNOS' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'ATIZADORES EXTERNOS', 'bien', 'materia_prima', 'PZA', 50.0, NULL, 'Atizadores externos', 'import-union-2026-11');
        ELSE
            IF 50.0 IS NOT NULL THEN
                UPDATE productos
                SET costo = 50.0,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Acero y Estructura')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'ATIZADORES INTERNOS' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'ATIZADORES INTERNOS', 'bien', 'materia_prima', 'PZA', 35.0, NULL, 'Atizadores internos', 'import-union-2026-11');
        ELSE
            IF 35.0 IS NOT NULL THEN
                UPDATE productos
                SET costo = 35.0,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Aire y Frenos ABS')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'BASE PARA ABS' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'BASE PARA ABS', 'bien', 'materia_prima', 'PZA', 30.0, NULL, 'Base para ABS', 'import-union-2026-11');
        ELSE
            IF 30.0 IS NOT NULL THEN
                UPDATE productos
                SET costo = 30.0,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Acero y Estructura')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'BASE PARA ESTRIBO PLACA FRONTAL' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'BASE PARA ESTRIBO PLACA FRONTAL', 'bien', 'materia_prima', 'PZA', 170.0, NULL, 'Base para estribo Placa frontal', 'import-union-2026-11');
        ELSE
            IF 170.0 IS NOT NULL THEN
                UPDATE productos
                SET costo = 170.0,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Acero y Estructura')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'BASE PARA ESTRIBO PLACA INTERMEDIA' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'BASE PARA ESTRIBO PLACA INTERMEDIA', 'bien', 'materia_prima', 'PZA', 130.0, NULL, 'Base para estribo Placa intermedia', 'import-union-2026-11');
        ELSE
            IF 130.0 IS NOT NULL THEN
                UPDATE productos
                SET costo = 130.0,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Acero y Estructura')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'BASE PARA ESTRIBO PLACA TRASERA' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'BASE PARA ESTRIBO PLACA TRASERA', 'bien', 'materia_prima', 'PZA', 65.0, NULL, 'Base para estribo Placa trasera', 'import-union-2026-11');
        ELSE
            IF 65.0 IS NOT NULL THEN
                UPDATE productos
                SET costo = 65.0,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Aire y Frenos ABS')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'BASE PARA FOCO DE ABS' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'BASE PARA FOCO DE ABS', 'bien', 'materia_prima', 'PZA', 25.0, NULL, 'Base para foco de ABS', 'import-union-2026-11');
        ELSE
            IF 25.0 IS NOT NULL THEN
                UPDATE productos
                SET costo = 25.0,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Acero y Estructura')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'BASE PARA MANITAS' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'BASE PARA MANITAS', 'bien', 'materia_prima', 'PZA', 101.0, NULL, 'Base para manitas', 'import-union-2026-11');
        ELSE
            IF 101.0 IS NOT NULL THEN
                UPDATE productos
                SET costo = 101.0,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Patines y Ejes')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'BASE PARA PATINES PLACAS' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'BASE PARA PATINES PLACAS', 'bien', 'materia_prima', 'PZA', 52.6, NULL, 'Base para patines Placas', 'import-union-2026-11');
        ELSE
            IF 52.6 IS NOT NULL THEN
                UPDATE productos
                SET costo = 52.6,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Patines y Ejes')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'BASE PARA PATINES SOLERA' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'BASE PARA PATINES SOLERA', 'bien', 'materia_prima', 'PZA', 23.4, NULL, 'Base para patines Solera', 'import-union-2026-11');
        ELSE
            IF 23.4 IS NOT NULL THEN
                UPDATE productos
                SET costo = 23.4,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Suspensión')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'BASE PARA PERCHAS' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'BASE PARA PERCHAS', 'bien', 'materia_prima', 'PZA', 234.0, NULL, 'Base para perchas', 'import-union-2026-11');
        ELSE
            IF 234.0 IS NOT NULL THEN
                UPDATE productos
                SET costo = 234.0,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Acero y Estructura')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'BASE PARA PLATOS' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'BASE PARA PLATOS', 'bien', 'materia_prima', 'PZA', 67.0, NULL, 'Base para platos', 'import-union-2026-11');
        ELSE
            IF 67.0 IS NOT NULL THEN
                UPDATE productos
                SET costo = 67.0,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Aire y Frenos ABS')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'BASE PARA TANQUES' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'BASE PARA TANQUES', 'bien', 'materia_prima', 'PZA', 77.0, NULL, 'Base para tanques', 'import-union-2026-11');
        ELSE
            IF 77.0 IS NOT NULL THEN
                UPDATE productos
                SET costo = 77.0,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Aire y Frenos ABS')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'BOLSA RETRACTIL CHICA UBL' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'BOLSA RETRACTIL CHICA UBL', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'BOLSA RETRACTIL CHICA UBL', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Aire y Frenos ABS')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'BOLSA RETRACTIL GRANDE' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'BOLSA RETRACTIL GRANDE', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'BOLSA RETRACTIL GRANDE', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Acero y Estructura')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'BORDA DELANTERA' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'BORDA DELANTERA', 'bien', 'materia_prima', 'PZA', 2068.0, NULL, 'Borda delantera', 'import-union-2026-11');
        ELSE
            IF 2068.0 IS NOT NULL THEN
                UPDATE productos
                SET costo = 2068.0,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Acero y Estructura')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'BORDA TRASERA' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'BORDA TRASERA', 'bien', 'materia_prima', 'PZA', 2500.0, NULL, 'Borda trasera', 'import-union-2026-11');
        ELSE
            IF 2500.0 IS NOT NULL THEN
                UPDATE productos
                SET costo = 2500.0,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Acero y Estructura')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'BORDAS LATERALES' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'BORDAS LATERALES', 'bien', 'materia_prima', 'PZA', 5870.35, NULL, 'Bordas laterales', 'import-union-2026-11');
        ELSE
            IF 5870.35 IS NOT NULL THEN
                UPDATE productos
                SET costo = 5870.35,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Acero y Estructura')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'BOTONES' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'BOTONES', 'bien', 'materia_prima', 'PZA', 40.0, NULL, 'Botones', 'import-union-2026-11');
        ELSE
            IF 40.0 IS NOT NULL THEN
                UPDATE productos
                SET costo = 40.0,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Acero y Estructura')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'BUCHACAS' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'BUCHACAS', 'bien', 'materia_prima', 'PZA', 45.5, NULL, 'Buchacas', 'import-union-2026-11');
        ELSE
            IF 45.5 IS NOT NULL THEN
                UPDATE productos
                SET costo = 45.5,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Suspensión')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'BUJE TRIFUNCIONAL CON TORNILLO 7/8 HENDRICKSON R14-083-38' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'BUJE TRIFUNCIONAL CON TORNILLO 7/8 HENDRICKSON R14-083-38', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'BUJE TRIFUNCIONAL CON TORNILLO 7/8 HENDRICKSON R14-083-38', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Suspensión')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'BUJE TRIFUNCIONAL CON TORNILLO HENDRICKSON C-25319 O R14-152' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'BUJE TRIFUNCIONAL CON TORNILLO HENDRICKSON C-25319 O R14-152', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'BUJE TRIFUNCIONAL CON TORNILLO HENDRICKSON C-25319 O R14-152', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Suspensión')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'BUJE TRIFUNCIONAL GABRIEL' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'BUJE TRIFUNCIONAL GABRIEL', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'BUJE TRIFUNCIONAL GABRIEL', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Suspensión')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'BUJE TRIFUNCIONAL HENDRICKSON 7/8 GABRIEL' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'BUJE TRIFUNCIONAL HENDRICKSON 7/8 GABRIEL', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'BUJE TRIFUNCIONAL HENDRICKSON 7/8 GABRIEL', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Iluminación y Eléctrico')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'CABLE AMARILLO CAL,12' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'CABLE AMARILLO CAL,12', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'CABLE AMARILLO CAL,12', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Iluminación y Eléctrico')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'CABLE AZUL CAL,12' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'CABLE AZUL CAL,12', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'CABLE AZUL CAL,12', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Iluminación y Eléctrico')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'CABLE CAFE CAL. 12' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'CABLE CAFE CAL. 12', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'CABLE CAFÉ CAL,12', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Iluminación y Eléctrico')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'CABLE NEGRO CAL. 12' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'CABLE NEGRO CAL. 12', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'CABLE NEGRO  CAL,12', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Iluminación y Eléctrico')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'CABLE ROJO CAL,12' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'CABLE ROJO CAL,12', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'CABLE ROJO CAL,12', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Iluminación y Eléctrico')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'CABLE VERDE CAL,12' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'CABLE VERDE CAL,12', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'CABLE VERDE CAL,12', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Acero y Estructura')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'CAJA DE HERRAMIENTAS' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'CAJA DE HERRAMIENTAS', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'Caja de herramientas', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Acero y Estructura')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'CAJA DE HERRAMIENTAS TORNILLO' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'CAJA DE HERRAMIENTAS TORNILLO', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'Caja de herramientas TORNILLO', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Acero y Estructura')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'CAJA DE HERRAMIENTAS TUERCA' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'CAJA DE HERRAMIENTAS TUERCA', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'Caja de herramientas TUERCA', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Suspensión')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'CAMARA DE SUSPENSION AMPRO 1R14-039' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'CAMARA DE SUSPENSION AMPRO 1R14-039', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'CAMARA DE SUSPENSION AMPRO 1R14-039', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Suspensión')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'CAMARA DE SUSPENSION AMPRO 8050' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'CAMARA DE SUSPENSION AMPRO 8050', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'CAMARA DE SUSPENSION AMPRO 8050', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Suspensión')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'CAMARA DE SUSPENSION FCR 1R14-039' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'CAMARA DE SUSPENSION FCR 1R14-039', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'CAMARA DE SUSPENSION FCR 1R14-039', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Suspensión')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'CAMARA DE SUSPENSION FLEET MASTER 8050' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'CAMARA DE SUSPENSION FLEET MASTER 8050', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'CAMARA DE SUSPENSION FLET MASTER 8050', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Suspensión')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'CAMARA DE SUSPENSION HENDRICKSON C-25319 O R14-152' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'CAMARA DE SUSPENSION HENDRICKSON C-25319 O R14-152', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'CAMARA DE SUSPENSION HENDRICKSON C-25319 O R14-152', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Suspensión')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'CAMARA DE SUSPENSION HENDRICKSON R14-083-38' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'CAMARA DE SUSPENSION HENDRICKSON R14-083-38', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'CAMARA DE SUSPENSION HENDRICKSON R14-083-38', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Acero y Estructura')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'CANDADO PARA PLANA' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'CANDADO PARA PLANA', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'CANDADO PARA PLANA', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Pintura y Preparación')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'CARDA 5/8 DE 3"' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'CARDA 5/8 DE 3"', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'CARDA 5/8 DE 3"', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Acero y Estructura')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'CARGADOR' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'CARGADOR', 'bien', 'materia_prima', 'PZA', 576.82, NULL, 'Cargador', 'import-union-2026-11');
        ELSE
            IF 576.82 IS NOT NULL THEN
                UPDATE productos
                SET costo = 576.82,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Acero y Estructura')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'CARGADOR 3"X102"' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'CARGADOR 3"X102"', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'CARGADO 3X102 IN', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Acero y Estructura')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'CARTABONES PARA JALON' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'CARTABONES PARA JALON', 'bien', 'materia_prima', 'PZA', 300.0, NULL, 'Cartabones para jalon', 'import-union-2026-11');
        ELSE
            IF 300.0 IS NOT NULL THEN
                UPDATE productos
                SET costo = 300.0,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Acero y Estructura')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'CHAVETAS 3/16*2' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'CHAVETAS 3/16*2', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'CHAVETAS 3/16*2', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Acero y Estructura')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'CINCHO' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'CINCHO', 'bien', 'materia_prima', 'PZA', 1110.0, NULL, 'Cincho', 'import-union-2026-11');
        ELSE
            IF 1110.0 IS NOT NULL THEN
                UPDATE productos
                SET costo = 1110.0,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Iluminación y Eléctrico')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'CINTA DE AISLAR' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'CINTA DE AISLAR', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'CINTA DE AISLAR', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Acabados y Rotulación')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'CINTA REFLEJANTE' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'CINTA REFLEJANTE', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'CINTA REFLEJANTE', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Consumibles')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'CO2' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'CO2', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'CO2', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Aire y Frenos ABS')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'CODO 1/2' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'CODO 1/2', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'CODO 1/2', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Aire y Frenos ABS')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'CODO 3/8' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'CODO 3/8', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'CODO 3/8', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Aire y Frenos ABS')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'CODO 3/8*1/4' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'CODO 3/8*1/4', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'CODO 3/8*1/4', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Aire y Frenos ABS')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'CODO 3/8*1/8' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'CODO 3/8*1/8', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'CODO 3/8*1/8', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Acero y Estructura')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'CONSUMIBLE 65' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'CONSUMIBLE 65', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'CONSUMIBLE 65', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Iluminación y Eléctrico')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'CORRUGADO 1/2' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'CORRUGADO 1/2', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'CORRUGADO 1/2', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Iluminación y Eléctrico')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'CORRUGADO 1/4' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'CORRUGADO 1/4', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'CORRUGADO 1/4', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Iluminación y Eléctrico')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'CORRUGADO 3/8' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'CORRUGADO 3/8', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'CORRUGADO 3/8', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Consumibles')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'DISCO DE CORTE 7' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'DISCO DE CORTE 7', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'DISCO DE CORTE 7', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Consumibles')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'DISCO DE DESBASTE 9' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'DISCO DE DESBASTE 9', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'DISCO DE DESBASTE 9', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Pintura y Preparación')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'DISCO LAMINADO 4 1/2' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'DISCO LAMINADO 4 1/2', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'DISCO LAMINADO 4 1/2', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Consumibles')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'DISCO LAMINADO 7' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'DISCO LAMINADO 7', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'DISCO LAMINADO 7', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Patines y Ejes')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'EJE AMPRO' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'EJE AMPRO', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'EJE AMPRO', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Patines y Ejes')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'EJE FCR' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'EJE FCR', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'EJE FCR', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Patines y Ejes')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'EJE FLEET MASTER' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'EJE FLEET MASTER', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'EJE FLET MASTER', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Patines y Ejes')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'EJE HJ' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'EJE HJ', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'EJE HJ', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Patines y Ejes')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'EJE PRAT MAX' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'EJE PRAT MAX', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'EJE PRAT MAX', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Aire y Frenos ABS')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'ESPARRAGO' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'ESPARRAGO', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'ESPARRAGO', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Acero y Estructura')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'ESQUINERO DELANTERO' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'ESQUINERO DELANTERO', 'bien', 'materia_prima', 'PZA', 70.0, NULL, 'Esquinero delantero', 'import-union-2026-11');
        ELSE
            IF 70.0 IS NOT NULL THEN
                UPDATE productos
                SET costo = 70.0,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Acero y Estructura')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'ESQUINERO TRASERO' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'ESQUINERO TRASERO', 'bien', 'materia_prima', 'PZA', 110.0, NULL, 'Esquinero trasero', 'import-union-2026-11');
        ELSE
            IF 110.0 IS NOT NULL THEN
                UPDATE productos
                SET costo = 110.0,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Acero y Estructura')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'ESTRIBO' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'ESTRIBO', 'bien', 'materia_prima', 'PZA', 1050.0, NULL, 'Estribo', 'import-union-2026-11');
        ELSE
            IF 1050.0 IS NOT NULL THEN
                UPDATE productos
                SET costo = 1050.0,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Acabados y Rotulación')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'FLEJE' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'FLEJE', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'FLEJE', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Pintura y Preparación')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'FOSFATO' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'FOSFATO', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'FOSFATO', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Aire y Frenos ABS')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'GANCHO HOLLAND 10 BARRENOS' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'GANCHO HOLLAND 10 BARRENOS', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'GANCHO HOLLAND 10 BARRENOS', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Aire y Frenos ABS')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'GANCHO PREMIER 10 BARRENOS' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'GANCHO PREMIER 10 BARRENOS', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'GANCHO PREMIER 10 BARRENOS', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Aire y Frenos ABS')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'GANCHO PREMIER BESTIA 6 BARRENOS' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'GANCHO PREMIER BESTIA 6 BARRENOS', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'GANCHO PREMIER BESTIA 6 BARRENOS', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Acero y Estructura')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'GANCHOS' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'GANCHOS', 'bien', 'materia_prima', 'PZA', 6.3, NULL, 'Ganchos', 'import-union-2026-11');
        ELSE
            IF 6.3 IS NOT NULL THEN
                UPDATE productos
                SET costo = 6.3,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Aire y Frenos ABS')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'HEMBRA 3/8' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'HEMBRA 3/8', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'HEMBRA 3/8', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Iluminación y Eléctrico')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'HEMBRA 7 POLOS' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'HEMBRA 7 POLOS', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'HEMBRA 7 POLOS', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Patines y Ejes')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'HERRAJE PARA PATINES 110CM' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'HERRAJE PARA PATINES 110CM', 'bien', 'materia_prima', 'PZA', 196.99, NULL, 'Heraje para patines 110cm', 'import-union-2026-11');
        ELSE
            IF 196.99 IS NOT NULL THEN
                UPDATE productos
                SET costo = 196.99,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Patines y Ejes')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'HERRAJE PARA PATINES 125CM' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'HERRAJE PARA PATINES 125CM', 'bien', 'materia_prima', 'PZA', 223.99, NULL, 'Heraje para patines 125cm', 'import-union-2026-11');
        ELSE
            IF 223.99 IS NOT NULL THEN
                UPDATE productos
                SET costo = 223.99,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Patines y Ejes')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'HERRAJE PARA PATINES 23CM' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'HERRAJE PARA PATINES 23CM', 'bien', 'materia_prima', 'PZA', 41.99, NULL, 'Heraje para patines 23cm', 'import-union-2026-11');
        ELSE
            IF 41.99 IS NOT NULL THEN
                UPDATE productos
                SET costo = 41.99,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Patines y Ejes')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'HERRAJE PARA PATINES 27CM' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'HERRAJE PARA PATINES 27CM', 'bien', 'materia_prima', 'PZA', 90.99, NULL, 'Heraje para patines 27cm', 'import-union-2026-11');
        ELSE
            IF 90.99 IS NOT NULL THEN
                UPDATE productos
                SET costo = 90.99,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Patines y Ejes')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'HERRAJE PARA PATINES 30CM' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'HERRAJE PARA PATINES 30CM', 'bien', 'materia_prima', 'PZA', 100.99, NULL, 'Heraje para patines 30cm', 'import-union-2026-11');
        ELSE
            IF 100.99 IS NOT NULL THEN
                UPDATE productos
                SET costo = 100.99,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Patines y Ejes')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'HERRAJE PARA PATINES 67CM' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'HERRAJE PARA PATINES 67CM', 'bien', 'materia_prima', 'PZA', 119.99, NULL, 'Heraje para patines 67cm', 'import-union-2026-11');
        ELSE
            IF 119.99 IS NOT NULL THEN
                UPDATE productos
                SET costo = 119.99,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Patines y Ejes')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'HERRAJE PARA PATINES 70CM' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'HERRAJE PARA PATINES 70CM', 'bien', 'materia_prima', 'PZA', 124.99, NULL, 'Heraje para patines 70cm', 'import-union-2026-11');
        ELSE
            IF 124.99 IS NOT NULL THEN
                UPDATE productos
                SET costo = 124.99,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Patines y Ejes')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'HERRAJE PARA PATINES 7CM' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'HERRAJE PARA PATINES 7CM', 'bien', 'materia_prima', 'PZA', 23.99, NULL, 'Heraje para patines 7cm', 'import-union-2026-11');
        ELSE
            IF 23.99 IS NOT NULL THEN
                UPDATE productos
                SET costo = 23.99,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Patines y Ejes')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'HERRAJE PARA PATINES BUCHACA' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'HERRAJE PARA PATINES BUCHACA', 'bien', 'materia_prima', 'PZA', 40.99, NULL, 'Heraje para patines Buchaca', 'import-union-2026-11');
        ELSE
            IF 40.99 IS NOT NULL THEN
                UPDATE productos
                SET costo = 40.99,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Patines y Ejes')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'HERRAJE PARA PATINES TORNILLO' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'HERRAJE PARA PATINES TORNILLO', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'Heraje para patines TORNILLO', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Patines y Ejes')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'HERRAJE PARA PATINES TUERCA' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'HERRAJE PARA PATINES TUERCA', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'Heraje para patines TUERCA', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Aire y Frenos ABS')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'INSERTO 1/2' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'INSERTO 1/2', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'INCERTO 1/2', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Aire y Frenos ABS')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'INSERTO 3/8' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'INSERTO 3/8', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'INCERTO 3/8', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Acero y Estructura')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'JALON' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'JALON', 'bien', 'materia_prima', 'PZA', 2500.0, NULL, 'Jalon', 'import-union-2026-11');
        ELSE
            IF 2500.0 IS NOT NULL THEN
                UPDATE productos
                SET costo = 2500.0,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Aire y Frenos ABS')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'KIT DE ABS 2 EJES BENDIX' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'KIT DE ABS 2 EJES BENDIX', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'KIT DE ABS 2 EJES BENDIX', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Acero y Estructura')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'KIT DE ALETAS 27X50 CM' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'KIT DE ALETAS 27X50 CM', 'bien', 'materia_prima', 'PZA', 108.99, NULL, 'Kit de aletas 27 x 50 cm', 'import-union-2026-11');
        ELSE
            IF 108.99 IS NOT NULL THEN
                UPDATE productos
                SET costo = 108.99,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Acero y Estructura')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'KIT DE ALETAS 27X60 CM' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'KIT DE ALETAS 27X60 CM', 'bien', 'materia_prima', 'PZA', 130.99, NULL, 'Kit de aletas 27 x 60 cm', 'import-union-2026-11');
        ELSE
            IF 130.99 IS NOT NULL THEN
                UPDATE productos
                SET costo = 130.99,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Acero y Estructura')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'KIT DE ALETAS 40X50 CM' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'KIT DE ALETAS 40X50 CM', 'bien', 'materia_prima', 'PZA', 161.99, NULL, 'Kit de aletas 40 x 50 cm', 'import-union-2026-11');
        ELSE
            IF 161.99 IS NOT NULL THEN
                UPDATE productos
                SET costo = 161.99,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Acero y Estructura')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'KIT DE ALETAS 40X60 CM' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'KIT DE ALETAS 40X60 CM', 'bien', 'materia_prima', 'PZA', 193.99, NULL, 'Kit de aletas 40 x 60 cm', 'import-union-2026-11');
        ELSE
            IF 193.99 IS NOT NULL THEN
                UPDATE productos
                SET costo = 193.99,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Acero y Estructura')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'KIT DE ALETAS 45X50 CM' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'KIT DE ALETAS 45X50 CM', 'bien', 'materia_prima', 'PZA', 181.99, NULL, 'Kit de aletas 45 x 50 cm', 'import-union-2026-11');
        ELSE
            IF 181.99 IS NOT NULL THEN
                UPDATE productos
                SET costo = 181.99,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Acero y Estructura')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'KIT DE ALETAS 45X60 CM' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'KIT DE ALETAS 45X60 CM', 'bien', 'materia_prima', 'PZA', 217.99, NULL, 'Kit de aletas 45 x 60 cm', 'import-union-2026-11');
        ELSE
            IF 217.99 IS NOT NULL THEN
                UPDATE productos
                SET costo = 217.99,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Iluminación y Eléctrico')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'KIT DE LUZ' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'KIT DE LUZ', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'KIT DE LUZ', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Acabados y Rotulación')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'KIT DE ROTULACION' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'KIT DE ROTULACION', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'KIT DE ROTULACION', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Pintura y Preparación')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'LIJA #80' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'LIJA #80', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'LIJA #80', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Llantas y Rines')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'LLANTA FIRESTONEN LINEAL' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'LLANTA FIRESTONEN LINEAL', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'LLANTA FIRESTON LINEAL', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Llantas y Rines')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'LLANTA GODSHIELD LINEAL' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'LLANTA GODSHIELD LINEAL', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'LLANTA GODSHIELD LINEAL', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Llantas y Rines')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'LLANTA K PATOS LINEAL' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'LLANTA K PATOS LINEAL', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'LLANTA K PATOS LINEAL', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Llantas y Rines')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'LLANTA K PATOS TRACCION' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'LLANTA K PATOS TRACCION', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'LLANTA K PATOS TRACCION', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Acabados y Rotulación')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'LODERA BLANCA O NEGRA' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'LODERA BLANCA O NEGRA', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'LODERA BLANCA O NEGRA', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Aire y Frenos ABS')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'MACHO 3/8' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'MACHO 3/8', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'MACHO 3/8', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Aire y Frenos ABS')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'MANGUERA AZUL 3/8' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'MANGUERA AZUL 3/8', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'MANGUERA AZUL 3/8', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Aire y Frenos ABS')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'MANGUERA CHAMBER 3/8' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'MANGUERA CHAMBER 3/8', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'MANGUERA CHAMBER 3/8', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Aire y Frenos ABS')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'MANGUERA ROJA 3/8' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'MANGUERA ROJA 3/8', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'MANGUERA ROJA 3/8', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Aire y Frenos ABS')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'MANITA AZUL C/LLAVE' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'MANITA AZUL C/LLAVE', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'MANITA AZUL C/LLAVE', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Aire y Frenos ABS')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'MANITA AZUL S/LLAVE' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'MANITA AZUL S/LLAVE', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'MANITA AZUL S/LLAVE', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Aire y Frenos ABS')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'MANITA ROJA C/LLAVE' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'MANITA ROJA C/LLAVE', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'MANITA ROJA C/LLAVE', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Aire y Frenos ABS')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'MANITA ROJA S/LLAVE' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'MANITA ROJA S/LLAVE', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'MANITA ROJA S/LLAVE', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Llantas y Rines')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'MEDIDA DE RIN RIN 22.5' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'MEDIDA DE RIN RIN 22.5', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'MEDIDA DE RIN RIN 22.5', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Llantas y Rines')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'MEDIDA DE RIN RIN 24.5' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'MEDIDA DE RIN RIN 24.5', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'MEDIDA DE RIN RIN 24.5', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Aire y Frenos ABS')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'NIPLE 1/4' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'NIPLE 1/4', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'NIPLE 1/4', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Consumibles')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'OXIGENO' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'OXIGENO', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'OXIGENO', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Patines y Ejes')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'PATIN AMPRO' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'PATIN AMPRO', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'PATIN AMPRO', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Patines y Ejes')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'PATIN FLEET MASTER' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'PATIN FLEET MASTER', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'PATIN FLET MASTER', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Patines y Ejes')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'PATIN HJ' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'PATIN HJ', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'PATIN HJ', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Patines y Ejes')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'PATIN HOLAND MARK V' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'PATIN HOLAND MARK V', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'PATIN HOLAND MARK V', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Acero y Estructura')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'PERNO REY' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'PERNO REY', 'bien', 'materia_prima', 'PZA', 1200.0, NULL, 'Perno rey', 'import-union-2026-11');
        ELSE
            IF 1200.0 IS NOT NULL THEN
                UPDATE productos
                SET costo = 1200.0,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Acero y Estructura')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'PESTAÑAS' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'PESTAÑAS', 'bien', 'materia_prima', 'PZA', 64.0, NULL, 'Pestañas', 'import-union-2026-11');
        ELSE
            IF 64.0 IS NOT NULL THEN
                UPDATE productos
                SET costo = 64.0,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Pisos y Madera')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'PIJAS 5/16"X2 1/2"' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'PIJAS 5/16"X2 1/2"', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'PIJAS 5/16 X 2 1/2', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Pisos y Madera')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'PIJAS 5/16"X2"' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'PIJAS 5/16"X2"', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'PIJAS 5/16 X 2', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Pintura y Preparación')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'PINTURA' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'PINTURA', 'bien', 'materia_prima', 'L', NULL, NULL, 'PINTURA', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Pintura y Preparación')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'PINTURA AXALTA' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'PINTURA AXALTA', 'bien', 'materia_prima', 'L', NULL, NULL, 'PINTURA AXALTA', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Pintura y Preparación')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'PINTURA PPG' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'PINTURA PPG', 'bien', 'materia_prima', 'L', NULL, NULL, 'PINTURA PPG', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Pintura y Preparación')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'PINTURA SHERWIN WILLIAMSWILLIAMS' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'PINTURA SHERWIN WILLIAMSWILLIAMS', 'bien', 'materia_prima', 'L', NULL, NULL, 'PINTURA SHERVIWILLIAMS', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Pisos y Madera')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'PISO DE ENCINO' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'PISO DE ENCINO', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'PISO DE ENCINO', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Pisos y Madera')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'PISO DE PINO' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'PISO DE PINO', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'PISO DE PINO', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Pisos y Madera')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'PISO MADERA' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'PISO MADERA', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'PISO MADERA', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Pisos y Madera')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'PISO PLASTICO CAFE' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'PISO PLASTICO CAFE', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'PISO PLASTICO CAFE', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Acabados y Rotulación')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'PLACA DE NIP' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'PLACA DE NIP', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'PLACA DE NIP', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Iluminación y Eléctrico')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'PLAFON AMBAR 2' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'PLAFON AMBAR 2', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'PLAFON AMBAR 2', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Iluminación y Eléctrico')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'PLAFON AVALADO AMBAR' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'PLAFON AVALADO AMBAR', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'PLAFON AVALADO AMBAR', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Iluminación y Eléctrico')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'PLAFON DE CARRITO AMBAR' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'PLAFON DE CARRITO AMBAR', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'PLAFON DE CARRITO AMBAR', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Iluminación y Eléctrico')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'PLAFON DE CARRITO ROJO' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'PLAFON DE CARRITO ROJO', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'PLAFON DE CARRITO ROJO', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Iluminación y Eléctrico')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'PLAFON ROJO 2' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'PLAFON ROJO 2', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'PLAFON ROJO 2', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Iluminación y Eléctrico')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'PLAFON ROJO 4' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'PLAFON ROJO 4', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'PLAFON ROJO 4', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Iluminación y Eléctrico')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'PLAFONES OVALADOS' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'PLAFONES OVALADOS', 'bien', 'materia_prima', 'PZA', 45.0, NULL, 'Plafones ovalados', 'import-union-2026-11');
        ELSE
            IF 45.0 IS NOT NULL THEN
                UPDATE productos
                SET costo = 45.0,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Acero y Estructura')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'PLANCHA PARA LA QUINTA (PLACA DE GRADO A-36 CAL. 3/8")' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'PLANCHA PARA LA QUINTA (PLACA DE GRADO A-36 CAL. 3/8")', 'bien', 'materia_prima', 'PZA', 5700.0, NULL, 'Plancha para la quinta (Placa de grado A-36 Cal. 3/8")', 'import-union-2026-11');
        ELSE
            IF 5700.0 IS NOT NULL THEN
                UPDATE productos
                SET costo = 5700.0,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Llantas y Rines')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'PORTA LLANTAS ALETAS' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'PORTA LLANTAS ALETAS', 'bien', 'materia_prima', 'PZA', 87.99, NULL, 'Porta Llantas Aletas', 'import-union-2026-11');
        ELSE
            IF 87.99 IS NOT NULL THEN
                UPDATE productos
                SET costo = 87.99,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Llantas y Rines')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'PORTA LLANTAS TORNILLO' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'PORTA LLANTAS TORNILLO', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'Porta Llantas TORNILLO', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Llantas y Rines')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'PORTA LLANTAS TUERCA' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'PORTA LLANTAS TUERCA', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'Porta Llantas TUERCA', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Llantas y Rines')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'PORTA LLANTAS"U"' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'PORTA LLANTAS"U"', 'bien', 'materia_prima', 'PZA', 738.99, NULL, 'Porta Llantas "U"', 'import-union-2026-11');
        ELSE
            IF 738.99 IS NOT NULL THEN
                UPDATE productos
                SET costo = 738.99,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Llantas y Rines')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'PORTA LLANTAS"Z"' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'PORTA LLANTAS"Z"', 'bien', 'materia_prima', 'PZA', 275.99, NULL, 'Porta Llantas "Z"', 'import-union-2026-11');
        ELSE
            IF 275.99 IS NOT NULL THEN
                UPDATE productos
                SET costo = 275.99,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Acabados y Rotulación')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'PORTA LODERAS' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'PORTA LODERAS', 'bien', 'materia_prima', 'PZA', 440.0, NULL, 'Porta loderas', 'import-union-2026-11');
        ELSE
            IF 440.0 IS NOT NULL THEN
                UPDATE productos
                SET costo = 440.0,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Acero y Estructura')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'PORTA PLACAS' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'PORTA PLACAS', 'bien', 'materia_prima', 'PZA', 42.99, NULL, 'Porta placas', 'import-union-2026-11');
        ELSE
            IF 42.99 IS NOT NULL THEN
                UPDATE productos
                SET costo = 42.99,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Acero y Estructura')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'PUENTES DE LA PLANCHA' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'PUENTES DE LA PLANCHA', 'bien', 'materia_prima', 'KG', 450.0, NULL, 'Puentes de la plancha', 'import-union-2026-11');
        ELSE
            IF 450.0 IS NOT NULL THEN
                UPDATE productos
                SET costo = 450.0,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Acero y Estructura')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'PUENTES DE SUSPENSION(PTR DE 6X2"CAL. 3/16")' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'PUENTES DE SUSPENSION(PTR DE 6X2"CAL. 3/16")', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'Puentes de suspensión (PTR de 6X2" Cal. 3/16")', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Acero y Estructura')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'PUENTES INTERMEDIOS' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'PUENTES INTERMEDIOS', 'bien', 'materia_prima', 'PZA', 440.0, NULL, 'Puentes intermedios', 'import-union-2026-11');
        ELSE
            IF 440.0 IS NOT NULL THEN
                UPDATE productos
                SET costo = 440.0,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Aire y Frenos ABS')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'RECTA 3/8*1/4' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'RECTA 3/8*1/4', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'RECTA 3/8*1/4', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Aire y Frenos ABS')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'REDUCCION 3/4*1/2' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'REDUCCION 3/4*1/2', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'REDUCCION  3/4 * 1/2', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Aire y Frenos ABS')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'REDUCCION 3/8*1/4' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'REDUCCION 3/8*1/4', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'REDUCCION  3/8 * 1/4', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Acero y Estructura')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'REFUERZO DE JALON' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'REFUERZO DE JALON', 'bien', 'materia_prima', 'PZA', 600.0, NULL, 'Refuerzo de jalon', 'import-union-2026-11');
        ELSE
            IF 600.0 IS NOT NULL THEN
                UPDATE productos
                SET costo = 600.0,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Iluminación y Eléctrico')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'REMACHE 3/16X5/8' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'REMACHE 3/16X5/8', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'REMACHE 3/16 X 5/8', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Acero y Estructura')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'RETRACTIL FABRICADO EN LEOLCA GRANDE ESLABONES DE CADENA 1/2' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'RETRACTIL FABRICADO EN LEOLCA GRANDE ESLABONES DE CADENA 1/2', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'RETRACTIL FABRICADO EN LEOLCA GRANDE ESLABONES DE CADENA 1/2', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Acero y Estructura')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'RETRACTIL FABRICADO EN LEOLCA GRANDE RONDANA AUTOMOTRIZ 3/4' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'RETRACTIL FABRICADO EN LEOLCA GRANDE RONDANA AUTOMOTRIZ 3/4', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'RETRACTIL FABRICADO EN LEOLCA GRANDE RONDANA AUTOMOTRIZ 3/4', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Acero y Estructura')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'RETRACTIL FABRICADO EN LEOLCA GRANDE RONDANA AUTOMOTRIZ 5/8' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'RETRACTIL FABRICADO EN LEOLCA GRANDE RONDANA AUTOMOTRIZ 5/8', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'RETRACTIL FABRICADO EN LEOLCA GRANDE RONDANA AUTOMOTRIZ 5/8', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Acero y Estructura')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'RETRACTIL FABRICADO EN LEOLCA GRANDE TORNILLO 3/4*6 GRADO 8' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'RETRACTIL FABRICADO EN LEOLCA GRANDE TORNILLO 3/4*6 GRADO 8', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'RETRACTIL FABRICADO EN LEOLCA GRANDE TORNILLO 3/4*6 GRADO 8', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Acero y Estructura')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'RETRACTIL FABRICADO EN LEOLCA GRANDE TORNILLO 3/4X3 1/2 GRADO 8' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'RETRACTIL FABRICADO EN LEOLCA GRANDE TORNILLO 3/4X3 1/2 GRADO 8', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'RETRACTIL FABRICADO EN LEOLCA GRANDE TORNILLO 3/4 X 3  1/2 GRADO 8', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Acero y Estructura')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'RETRACTIL FABRICADO EN LEOLCA GRANDE TORNILLO 3/4X6 GRADO 8' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'RETRACTIL FABRICADO EN LEOLCA GRANDE TORNILLO 3/4X6 GRADO 8', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'RETRACTIL FABRICADO EN LEOLCA GRANDE TORNILLO 3/4 X 6 GRADO 8', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Acero y Estructura')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'RETRACTIL FABRICADO EN LEOLCA GRANDE TORNILLO 5/8*3 GRADO 8' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'RETRACTIL FABRICADO EN LEOLCA GRANDE TORNILLO 5/8*3 GRADO 8', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'RETRACTIL FABRICADO EN LEOLCA GRANDE TORNILLO 5/8*3 GRADO 8', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Acero y Estructura')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'RETRACTIL FABRICADO EN LEOLCA GRANDE TORNILLO 5/8*5 GRADO 8' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'RETRACTIL FABRICADO EN LEOLCA GRANDE TORNILLO 5/8*5 GRADO 8', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'RETRACTIL FABRICADO EN LEOLCA GRANDE TORNILLO 5/8*5 GRADO 8', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Acero y Estructura')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'RETRACTIL FABRICADO EN LEOLCA GRANDE TUERCA DE SEGURIDAD 3/4' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'RETRACTIL FABRICADO EN LEOLCA GRANDE TUERCA DE SEGURIDAD 3/4', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'RETRACTIL FABRICADO EN LEOLCA GRANDE TUERCA DE SEGURIDAD 3/4', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Acero y Estructura')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'RETRACTIL FABRICADO EN LEOLCA GRANDE TUERCA DE SEGURIDAD 5/8' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'RETRACTIL FABRICADO EN LEOLCA GRANDE TUERCA DE SEGURIDAD 5/8', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'RETRACTIL FABRICADO EN LEOLCA GRANDE TUERCA DE SEGURIDAD 5/8', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Llantas y Rines')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'RIN DE ACERO ACCURIDE' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'RIN DE ACERO ACCURIDE', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'RIN DE ACERO ACURRAI', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Llantas y Rines')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'RIN DE ACERO AMPRO' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'RIN DE ACERO AMPRO', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'RIN DE ACERO AMPRO', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Llantas y Rines')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'RIN DE ACERO FLEET MASTER' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'RIN DE ACERO FLEET MASTER', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'RIN DE ACERO FLET MASTER', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Llantas y Rines')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'RIN DE ALUMINIO AMPRO' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'RIN DE ALUMINIO AMPRO', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'RIN DE AUMINIO AMPRO', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Llantas y Rines')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'RIN DE ALUMINIO AMPRO MASTER TRAPEZOIDAL' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'RIN DE ALUMINIO AMPRO MASTER TRAPEZOIDAL', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'RIN DE AUMINIO AMPRO MASTER TRAPEZOIDAL', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Llantas y Rines')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'RIN DE ALUMINIO FLEET MASTER' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'RIN DE ALUMINIO FLEET MASTER', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'RIN DE AUMINIO FLET MASTER', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Llantas y Rines')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'RIN DE ALUMINIO FLEET MASTER TRAPEZOIDAL' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'RIN DE ALUMINIO FLEET MASTER TRAPEZOIDAL', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'RIN DE AUMINIO FLET MASTER TRAPEZOIDAL', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Acero y Estructura')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'ROLLO DE MICROALAMBRE' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'ROLLO DE MICROALAMBRE', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'ROLLO DE MICRO ALAMBRE', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Aire y Frenos ABS')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'RONDANA AUTOMOTRIZ 3/4' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'RONDANA AUTOMOTRIZ 3/4', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'RONDANA AUTOMOTRIZ 3/4', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Acabados y Rotulación')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'RONDANA PLANA 1/2' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'RONDANA PLANA 1/2', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'RONDANA PLANA 1/2', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Aire y Frenos ABS')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'RONDANA PLANA 3/8' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'RONDANA PLANA 3/8', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'RONDANA PLANA 3/8', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Aire y Frenos ABS')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'RONDANA PLANA 5/16' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'RONDANA PLANA 5/16', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'RONDANA PLANA 5/16', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Suspensión')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'RONDANAS CENTRICAS GABRIEL' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'RONDANAS CENTRICAS GABRIEL', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'RONDANAS CENTRICAS GABRIEL', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Suspensión')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'RONDANAS CENTRICAS HENDRICKSON C-25319 O R14-152' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'RONDANAS CENTRICAS HENDRICKSON C-25319 O R14-152', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'RONDANAS CENTRICAS HENDRICKSON C-25319 O R14-152', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Suspensión')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'RONDANAS CENTRICAS HENDRICKSON GABRIEL' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'RONDANAS CENTRICAS HENDRICKSON GABRIEL', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'RONDANAS CENTRICAS HENDRICKSON GABRIEL', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Suspensión')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'RONDANAS CENTRICAS HENDRICKSON R14-083-38' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'RONDANAS CENTRICAS HENDRICKSON R14-083-38', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'RONDANAS CENTRICAS HENDRICKSON R14-083-38', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Suspensión')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'RONDANAS EXCENTRICAS GABRIEL' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'RONDANAS EXCENTRICAS GABRIEL', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'RONDANAS EXCENTRICAS GABRIEL', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Suspensión')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'RONDANAS EXCENTRICAS HENDRICKSON C-25319 O R14-152' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'RONDANAS EXCENTRICAS HENDRICKSON C-25319 O R14-152', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'RONDANAS EXCENTRICAS HENDRICKSON C-25319 O R14-152', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Suspensión')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'RONDANAS EXCENTRICAS HENDRICKSON GABRIEL' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'RONDANAS EXCENTRICAS HENDRICKSON GABRIEL', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'RONDANAS EXCENTRICAS HENDRICKSON GABRIEL', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Suspensión')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'RONDANAS EXCENTRICAS HENDRICKSON R14-083-38' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'RONDANAS EXCENTRICAS HENDRICKSON R14-083-38', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'RONDANAS EXCENTRICAS HENDRICKSON R14-083-38', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Aire y Frenos ABS')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'RONDANAS PLANAS 3/8' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'RONDANAS PLANAS 3/8', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'RONDANAS PLANAS 3/8', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Acero y Estructura')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'SISTEMA RETRACTIL CHICO RETRACTIL UBL ORIGINAL' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'SISTEMA RETRACTIL CHICO RETRACTIL UBL ORIGINAL', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'SISTEMA RETRACTIL CHICO Retractil UBL original', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Acero y Estructura')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'SISTEMA RETRACTIL CHICO RETRACTIL UBL PROPIO' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'SISTEMA RETRACTIL CHICO RETRACTIL UBL PROPIO', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'SISTEMA RETRACTIL CHICO Retractil UBL propio', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Acero y Estructura')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'SISTEMA RETRACTIL GRANDE' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'SISTEMA RETRACTIL GRANDE', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'SISTEMA RETRACTIL GRANDE', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Acero y Estructura')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'SISTEMA RETRACTIL GRANDE RETRACTIL GRANDE ORIGINAL' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'SISTEMA RETRACTIL GRANDE RETRACTIL GRANDE ORIGINAL', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'SISTEMA RETRACTIL GRANDE Retractil grande original', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Acero y Estructura')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'SISTEMA RETRACTIL GRANDE RETRACTIL GRANDE PROPIO' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'SISTEMA RETRACTIL GRANDE RETRACTIL GRANDE PROPIO', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'SISTEMA RETRACTIL GRANDE Retractil grande propio', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Acero y Estructura')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'SOLERA PARA ALMAS (SOLERA DE GRADO A-529 A 1/2"X6")' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'SOLERA PARA ALMAS (SOLERA DE GRADO A-529 A 1/2"X6")', 'bien', 'materia_prima', 'PZA', 4884.75, NULL, 'Solera para almas (Solera de grado A-529 a 1/2" X 6")', 'import-union-2026-11');
        ELSE
            IF 4884.75 IS NOT NULL THEN
                UPDATE productos
                SET costo = 4884.75,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Acero y Estructura')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'SOLERA PARA ESQUINEROS' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'SOLERA PARA ESQUINEROS', 'bien', 'materia_prima', 'PZA', 60.6, NULL, 'Solera para esquineros', 'import-union-2026-11');
        ELSE
            IF 60.6 IS NOT NULL THEN
                UPDATE productos
                SET costo = 60.6,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Suspensión')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'SUSPENSION AMPRO HT300 ( SUSPENSION NORMAL)' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'SUSPENSION AMPRO HT300 ( SUSPENSION NORMAL)', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'SUSPENSION AMPRO HT300 ( SUSPENSION NORMAL)', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Suspensión')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'SUSPENSION FCR HT300 ( SUSPENSION NORMAL)' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'SUSPENSION FCR HT300 ( SUSPENSION NORMAL)', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'SUSPENSION FCR HT300 ( SUSPENSION NORMAL)', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Suspensión')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'SUSPENSION FLEET MASTER HT300 ( SUSPENSION NORMAL)' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'SUSPENSION FLEET MASTER HT300 ( SUSPENSION NORMAL)', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'SUSPENSION FLET MASTER HT300 ( SUSPENSION NORMAL)', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Suspensión')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'SUSPENSION HENDRICKSON HT300 ( SUSPENSION NORMAL)' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'SUSPENSION HENDRICKSON HT300 ( SUSPENSION NORMAL)', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'SUSPENSION HENDRICKSON HT300 ( SUSPENSION NORMAL)', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Suspensión')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'SUSPENSION HENDRICKSON HT300US ( SUSPENSION ALTA)' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'SUSPENSION HENDRICKSON HT300US ( SUSPENSION ALTA)', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'SUSPENSION HENDRICKSON HT300US ( SUSPENSION ALTA)', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Aire y Frenos ABS')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'TANQUE DE AIRE DE PLANA' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'TANQUE DE AIRE DE PLANA', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'TANQUE DE AIRE DE PLANA', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Acero y Estructura')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'TAPA PARA PERNO REY' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'TAPA PARA PERNO REY', 'bien', 'materia_prima', 'KG', 100.0, NULL, 'Tapa para perno rey', 'import-union-2026-11');
        ELSE
            IF 100.0 IS NOT NULL THEN
                UPDATE productos
                SET costo = 100.0,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Aire y Frenos ABS')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'TAPON 1/2' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'TAPON 1/2', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'TAPON 1/2', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Aire y Frenos ABS')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'TAPON 1/4 SUSPENSION FM + 4' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'TAPON 1/4 SUSPENSION FM + 4', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'TAPON 1/4 SUSPENSION FM + 4', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Aire y Frenos ABS')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'TAPON 1/8' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'TAPON 1/8', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'TAPON 1/8', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Aire y Frenos ABS')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'TAPON 3/4' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'TAPON 3/4', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'TAPON 3/4', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Aire y Frenos ABS')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'TE CENTRO 3/8*1/4' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'TE CENTRO 3/8*1/4', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'TE CENTRO 3/8*1/4', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Aire y Frenos ABS')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'TE LATERAL 3/8*1/4' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'TE LATERAL 3/8*1/4', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'TE LATERAL 3/8*1/4', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Aire y Frenos ABS')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'TE UNIO 3/8' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'TE UNIO 3/8', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'TE UNIO 3/8', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Aire y Frenos ABS')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'TEFLON DE 13 METROS' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'TEFLON DE 13 METROS', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'TEFLON DE 13 METROS', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Iluminación y Eléctrico')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'TERMINAL 1/4' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'TERMINAL 1/4', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'TERMINAL 1/4', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Iluminación y Eléctrico')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'TERMINAL 3/16' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'TERMINAL 3/16', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'TERMINAL 3/16', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Acabados y Rotulación')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'TOPE DE HULE 3 BARRENOS' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'TOPE DE HULE 3 BARRENOS', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'TOPE DE HULE  3 BARRENOS', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Acabados y Rotulación')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'TORNILLO 1/2"X1 3/4"' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'TORNILLO 1/2"X1 3/4"', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'TORNILLO 1/2X 1 3/4', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Acabados y Rotulación')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'TORNILLO 1/2X2 1/2 GALVANIZADO' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'TORNILLO 1/2X2 1/2 GALVANIZADO', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'TORNILLO 1/2 X 2 1/2 GALVANIZADO', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Acabados y Rotulación')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'TORNILLO 1/4X1 ACERO INOXIDABLE' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'TORNILLO 1/4X1 ACERO INOXIDABLE', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'TORNILLO 1/4X1 ACERO INOXIDABLE', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Iluminación y Eléctrico')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'TORNILLO 1/4X1 GALVANIZADO' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'TORNILLO 1/4X1 GALVANIZADO', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'TORNILLO 1/4X1 GALVANIZADO', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Iluminación y Eléctrico')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'TORNILLO 1/8X1 1/4' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'TORNILLO 1/8X1 1/4', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'TORNILLO 1/8X 1 1/4', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Aire y Frenos ABS')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'TORNILLO 3/4X2 1/2 GRADO 8' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'TORNILLO 3/4X2 1/2 GRADO 8', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'TORNILLO 3/4X 2 1/2 GRADO 8', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Aire y Frenos ABS')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'TORNILLO 3/4X3 1/2 GRADO 8' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'TORNILLO 3/4X3 1/2 GRADO 8', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'TORNILLO 3/4X3 1/2 GRADO 8', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Aire y Frenos ABS')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'TORNILLO 3/8X1 GRADO 8' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'TORNILLO 3/8X1 GRADO 8', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'TORNILLO 3/8 X 1 GRADO 8', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Aire y Frenos ABS')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'TORNILLO 3/8X3/4 GRADO 8' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'TORNILLO 3/8X3/4 GRADO 8', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'TORNILLO 3/8 X 3/4 GRADO 8', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Aire y Frenos ABS')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'TORNILLO 5/16X5 GRADO 8' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'TORNILLO 5/16X5 GRADO 8', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'TORNILLO 5/16 X 5 GRADO 8', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Acero y Estructura')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'TORNILLO CABEZA DE COCHE 1/4X1 1/2' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'TORNILLO CABEZA DE COCHE 1/4X1 1/2', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'TORNILLO CABEZA DE COCHE 1/4 X 1 1/2', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Acero y Estructura')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'TUBOS LATERALES' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'TUBOS LATERALES', 'bien', 'materia_prima', 'PZA', 12.0, NULL, 'Tubos laterales', 'import-union-2026-11');
        ELSE
            IF 12.0 IS NOT NULL THEN
                UPDATE productos
                SET costo = 12.0,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Acabados y Rotulación')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'TUERCA DE SEGURIDAD 1/2' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'TUERCA DE SEGURIDAD 1/2', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'TUERCA DE SEGURIDAD 1/2', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Acabados y Rotulación')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'TUERCA DE SEGURIDAD 1/4' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'TUERCA DE SEGURIDAD 1/4', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'TUERCA DE SEGURIDAD 1/4', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Aire y Frenos ABS')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'TUERCA DE SEGURIDAD 3/8' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'TUERCA DE SEGURIDAD 3/8', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'TUERCA DE SEGURIDAD 3/8', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Aire y Frenos ABS')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'TUERCA DE SEGURIDAD 5/16' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'TUERCA DE SEGURIDAD 5/16', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'TUERCA DE SEGURIDAD 5/16', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Acabados y Rotulación')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'TUERCA ESTANDAR 1/2 GALVANIZADA' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'TUERCA ESTANDAR 1/2 GALVANIZADA', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'TUERCA ESTANDAR  1/2 GALVANIZADA', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Iluminación y Eléctrico')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'TUERCA ESTANDAR 1/4' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'TUERCA ESTANDAR 1/4', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'TUERCA ESTANDAR 1/4', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Iluminación y Eléctrico')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'TUERCA ESTANDAR 1/8' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'TUERCA ESTANDAR 1/8', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'TUERCA ESTANDAR 1/8', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Aire y Frenos ABS')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'TUERCA GRIPCO 3/4' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'TUERCA GRIPCO 3/4', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'TUERCA GRIPCO 3/4', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Aire y Frenos ABS')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'TUERCA ROSCA MILIMETRICA 3/4' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'TUERCA ROSCA MILIMETRICA 3/4', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'TUERCA ROSCA MILIMETRICA 3/4', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Aire y Frenos ABS')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'TUERCAS DE SEGURIDAD 1/2' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'TUERCAS DE SEGURIDAD 1/2', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'TUERCAS DE SEGURIDAD 1/2', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Acero y Estructura')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'U PARA JALON' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'U PARA JALON', 'bien', 'materia_prima', 'PZA', 102.0, NULL, 'U para jalon', 'import-union-2026-11');
        ELSE
            IF 102.0 IS NOT NULL THEN
                UPDATE productos
                SET costo = 102.0,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Aire y Frenos ABS')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'VALVULA NIVELADORA' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'VALVULA NIVELADORA', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'VALVULA NIVELADORA', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Aire y Frenos ABS')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'VALVULA PALANQUETA' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'VALVULA PALANQUETA', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'VALVULA PALANQUETA', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Aire y Frenos ABS')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'VALVULA PROTECTORA' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'VALVULA PROTECTORA', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'VALVULA PROTECTORA', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Aire y Frenos ABS')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'VALVULA RETRACTIL SEALCO' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'VALVULA RETRACTIL SEALCO', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'VALVULA RETRACTIL SEALCO', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Aire y Frenos ABS')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'VARILLA NIVELADORA' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'VARILLA NIVELADORA', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'VARILLA NIVELADORA', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;

        SELECT id INTO v_cat_id FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('Acabados y Rotulación')) LIMIT 1;
        SELECT id INTO v_mat_id FROM productos WHERE organizacion_id = r_org.id AND upper(trim(nombre)) = 'WINCHES' AND tipo_item = 'materia_prima' LIMIT 1;
        
        IF v_mat_id IS NULL THEN
            INSERT INTO productos (organizacion_id, categoria_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, v_cat_id, 'WINCHES', 'bien', 'materia_prima', 'PZA', NULL, NULL, 'WINCHES', 'import-union-2026-11');
        ELSE
            IF NULL IS NOT NULL THEN
                UPDATE productos
                SET costo = NULL,
                    notas = COALESCE(notas, '') || ' import-union-2026-11'
                WHERE id = v_mat_id AND costo IS NULL;
            END IF;
        END IF;


        -- E. Actualizar paso y fase_id en líneas de acero estructural que tenían paso nulo o vacío
        -- Paso 1: Almas
        UPDATE receta_base rb
        SET paso = 'Paso 1'
        FROM modelos m, productos p
        WHERE rb.modelo_id = m.id AND rb.material_id = p.id
          AND m.organizacion_id = r_org.id
          AND (rb.paso IS NULL OR rb.paso = '')
          AND p.nombre ILIKE '%ALMA%';

        -- Paso 2: Soleras de refuerzo de almas
        UPDATE receta_base rb
        SET paso = 'Paso 2'
        FROM modelos m, productos p
        WHERE rb.modelo_id = m.id AND rb.material_id = p.id
          AND m.organizacion_id = r_org.id
          AND (rb.paso IS NULL OR rb.paso = '')
          AND p.nombre ILIKE '%SOLERA%ALMA%';

        -- Paso 3: Estructura primaria, bordas y plancha de quinta
        UPDATE receta_base rb
        SET paso = 'Paso 3'
        FROM modelos m, productos p
        WHERE rb.modelo_id = m.id AND rb.material_id = p.id
          AND m.organizacion_id = r_org.id
          AND (rb.paso IS NULL OR rb.paso = '')
          AND (p.nombre ILIKE '%BORDA%' OR p.nombre ILIKE '%QUINTA%' OR p.nombre ILIKE '%PERNO REY%' OR p.nombre ILIKE '%PUENTE%' OR p.nombre ILIKE '%BOTON%' OR p.nombre ILIKE '%JALON%' OR p.nombre ILIKE '%ALETAS%' OR p.nombre ILIKE '%ESQUINERO%');

        -- Paso 4: Cargadores transversales IPR y atizadores
        UPDATE receta_base rb
        SET paso = 'Paso 4'
        FROM modelos m, productos p
        WHERE rb.modelo_id = m.id AND rb.material_id = p.id
          AND m.organizacion_id = r_org.id
          AND (rb.paso IS NULL OR rb.paso = '')
          AND (p.nombre ILIKE '%CARGADOR%' OR p.nombre ILIKE '%ATIZADOR%');

        -- Paso 5: Bases de suspensión y patines estructurales
        UPDATE receta_base rb
        SET paso = 'Paso 5'
        FROM modelos m, productos p
        WHERE rb.modelo_id = m.id AND rb.material_id = p.id
          AND m.organizacion_id = r_org.id
          AND (rb.paso IS NULL OR rb.paso = '')
          AND (p.nombre ILIKE '%BASE%PATIN%' OR p.nombre ILIKE '%BASE%PERCHA%' OR p.nombre ILIKE '%BASE%PLATO%' OR p.nombre ILIKE '%HERAJE%PATIN%');

        -- Paso 6: Accesorios estructurales, estribo, ganchos, canaleta
        UPDATE receta_base rb
        SET paso = 'Paso 6'
        FROM modelos m, productos p
        WHERE rb.modelo_id = m.id AND rb.material_id = p.id
          AND m.organizacion_id = r_org.id
          AND (rb.paso IS NULL OR rb.paso = '');

        -- Paso 7: Actualizar registros legados de 'LIMPIEZA' a 'PASO 7'
        UPDATE receta_base rb
        SET paso = 'PASO 7'
        FROM modelos m
        WHERE rb.modelo_id = m.id AND m.organizacion_id = r_org.id
          AND upper(trim(rb.paso)) = 'LIMPIEZA';

        -- F. Asignación de fase_id en receta_base asegurando estricto aislamiento entre organizaciones
        UPDATE receta_base rb
        SET fase_id = fe.fase_id
        FROM fases_despiece_equivalencias fe, modelos m
        WHERE m.id = rb.modelo_id
          AND fe.organizacion_id = r_org.id
          AND m.organizacion_id = r_org.id
          AND upper(trim(rb.paso)) = upper(trim(fe.paso_legacy))
          AND (rb.fase_id IS NULL OR rb.fase_id != fe.fase_id);

        -- G. Asignación de fase_id en opcion_componentes asegurando estricto aislamiento entre organizaciones
        UPDATE opcion_componentes oc
        SET fase_id = fe.fase_id
        FROM fases_despiece_equivalencias fe, opciones_configuracion oc_opt
        WHERE oc_opt.id = oc.opcion_id
          AND fe.organizacion_id = r_org.id
          AND oc_opt.organizacion_id = r_org.id
          AND upper(trim(oc.paso)) = upper(trim(fe.paso_legacy))
          AND (oc.fase_id IS NULL OR oc.fase_id != fe.fase_id);

        -- H. Carga del árbol de opciones en opcion_componentes para los bloques configurables
        -- 1. Suspensión (Paso 5)
        SELECT id INTO v_fase_id FROM fases_despiece WHERE organizacion_id = r_org.id AND clave = 'paso_5';
        
        -- Hendrickson alta
        SELECT id INTO v_opcion_id FROM opciones_configuracion WHERE organizacion_id = r_org.id AND clave = 'alta_hendrickson';
        IF v_opcion_id IS NOT NULL AND v_fase_id IS NOT NULL THEN
            UPDATE opcion_componentes SET fase_id = v_fase_id, paso = 'PASO 5', uso = 'Kit suspensión alta'
            WHERE opcion_id = v_opcion_id AND (fase_id IS NULL OR fase_id != v_fase_id);
        END IF;

        -- Hendrickson normal
        SELECT id INTO v_opcion_id FROM opciones_configuracion WHERE organizacion_id = r_org.id AND clave = 'hendrickson';
        IF v_opcion_id IS NOT NULL AND v_fase_id IS NOT NULL THEN
            UPDATE opcion_componentes SET fase_id = v_fase_id, paso = 'PASO 5', uso = 'Kit suspensión normal'
            WHERE opcion_id = v_opcion_id AND (fase_id IS NULL OR fase_id != v_fase_id);
        END IF;

        -- Fleet Master normal
        SELECT id INTO v_opcion_id FROM opciones_configuracion WHERE organizacion_id = r_org.id AND clave = 'fleet_master';
        IF v_opcion_id IS NOT NULL AND v_fase_id IS NOT NULL THEN
            UPDATE opcion_componentes SET fase_id = v_fase_id, paso = 'PASO 5', uso = 'Kit suspensión normal'
            WHERE opcion_id = v_opcion_id AND (fase_id IS NULL OR fase_id != v_fase_id);
        END IF;

        -- 2. Patines (Paso 5)
        FOR v_opcion_id IN SELECT id FROM opciones_configuracion WHERE organizacion_id = r_org.id AND grupo_id = (SELECT id FROM grupos_configuracion WHERE clave = 'patin' AND organizacion_id = r_org.id) LOOP
            UPDATE opcion_componentes SET fase_id = v_fase_id, paso = 'PASO 5', uso = 'Patines de apoyo'
            WHERE opcion_id = v_opcion_id AND (fase_id IS NULL OR fase_id != v_fase_id);
        END LOOP;

        -- 3. Ejes (Paso 5)
        FOR v_opcion_id IN SELECT id FROM opciones_configuracion WHERE organizacion_id = r_org.id AND grupo_id = (SELECT id FROM grupos_configuracion WHERE clave = 'eje' AND organizacion_id = r_org.id) LOOP
            UPDATE opcion_componentes SET fase_id = v_fase_id, paso = 'PASO 5', uso = 'Ejes de carga'
            WHERE opcion_id = v_opcion_id AND (fase_id IS NULL OR fase_id != v_fase_id);
        END LOOP;

        -- 4. Pintura (Paso 8)
        SELECT id INTO v_fase_id FROM fases_despiece WHERE organizacion_id = r_org.id AND clave = 'paso_8';
        FOR v_opcion_id IN SELECT id FROM opciones_configuracion WHERE organizacion_id = r_org.id AND grupo_id = (SELECT id FROM grupos_configuracion WHERE clave = 'pintura' AND organizacion_id = r_org.id) LOOP
            UPDATE opcion_componentes SET fase_id = v_fase_id, paso = 'PASO 8', uso = 'Pintura y acabados'
            WHERE opcion_id = v_opcion_id AND (fase_id IS NULL OR fase_id != v_fase_id);
        END LOOP;

        -- 5. Pisos (Paso 11)
        SELECT id INTO v_fase_id FROM fases_despiece WHERE organizacion_id = r_org.id AND clave = 'paso_11';
        FOR v_opcion_id IN SELECT id FROM opciones_configuracion WHERE organizacion_id = r_org.id AND grupo_id = (SELECT id FROM grupos_configuracion WHERE clave = 'piso' AND organizacion_id = r_org.id) LOOP
            UPDATE opcion_componentes SET fase_id = v_fase_id, paso = 'PASO 11', uso = 'Pisos y fijación'
            WHERE opcion_id = v_opcion_id AND (fase_id IS NULL OR fase_id != v_fase_id);
        END LOOP;

        -- 6. Llantas y Rines
        SELECT id INTO v_fase_id FROM fases_despiece WHERE organizacion_id = r_org.id AND clave = 'llantas_rines';
        FOR v_opcion_id IN SELECT id FROM opciones_configuracion WHERE organizacion_id = r_org.id AND grupo_id IN (SELECT id FROM grupos_configuracion WHERE clave IN ('rines', 'llantas') AND organizacion_id = r_org.id) LOOP
            UPDATE opcion_componentes SET fase_id = v_fase_id, paso = 'LLANTAS Y RINES', uso = 'Rodado'
            WHERE opcion_id = v_opcion_id AND (fase_id IS NULL OR fase_id != v_fase_id);
        END LOOP;

    END LOOP;
END $$;

COMMIT;
