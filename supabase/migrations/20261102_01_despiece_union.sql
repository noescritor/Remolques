-- Migración 20261102_01_despiece_union.sql
-- T2 Ronda 3: Despiece oficial por fases desde UNION DE LISTADOS
-- Corrección integral: RLS estricto SELECT, sin duplicados, asignación de pasos reales y aislamiento de modelos

BEGIN;

-- 0. Columna notas en productos para trazabilidad
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
DROP POLICY IF EXISTS "fases_despiece_org_all" ON fases_despiece;
DROP POLICY IF EXISTS "fases_despiece_org_insert" ON fases_despiece;
DROP POLICY IF EXISTS "fases_despiece_org_update" ON fases_despiece;
DROP POLICY IF EXISTS "fases_despiece_org_delete" ON fases_despiece;

CREATE POLICY "fases_despiece_org_select" ON fases_despiece
    FOR SELECT TO authenticated
    USING (organizacion_id = get_current_org_id());

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
DROP POLICY IF EXISTS "fases_equivalencias_org_all" ON fases_despiece_equivalencias;
DROP POLICY IF EXISTS "fases_equivalencias_org_insert" ON fases_despiece_equivalencias;
DROP POLICY IF EXISTS "fases_equivalencias_org_update" ON fases_despiece_equivalencias;
DROP POLICY IF EXISTS "fases_equivalencias_org_delete" ON fases_despiece_equivalencias;

CREATE POLICY "fases_equivalencias_org_select" ON fases_despiece_equivalencias
    FOR SELECT TO authenticated
    USING (organizacion_id = get_current_org_id());

-- Permisos estrictos: solo lectura para usuarios autenticados
GRANT SELECT ON fases_despiece TO authenticated;
GRANT SELECT ON fases_despiece_equivalencias TO authenticated;
REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON fases_despiece FROM authenticated;
REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON fases_despiece_equivalencias FROM authenticated;

-- 2. Adición de columna fase_id en receta_base y opcion_componentes
ALTER TABLE receta_base ADD COLUMN IF NOT EXISTS fase_id UUID REFERENCES fases_despiece(id);
ALTER TABLE opcion_componentes ADD COLUMN IF NOT EXISTS fase_id UUID REFERENCES fases_despiece(id);


DO $$
DECLARE
    r_org RECORD;
    v_fase_id UUID;
    v_fase_1 UUID;
    v_fase_2 UUID;
    v_fase_3 UUID;
    v_fase_4 UUID;
    v_fase_5 UUID;
    v_fase_6 UUID;
    v_fase_7 UUID;
    v_fase_8 UUID;
    v_fase_9 UUID;
    v_fase_10 UUID;
    v_fase_11 UUID;
    v_fase_12 UUID;
    v_fase_extras UUID;
    v_fase_llantas_rines UUID;
    v_opcion_id UUID;
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
        VALUES (r_org.id, 'paso_5', 'Paso 5', 'Instalación de suspensión y retráctiles', 5, 'Ensamble de perchas, suspensión neumática/mecánica y sistema retráctil', true)
        ON CONFLICT (organizacion_id, clave) DO UPDATE SET
            nombre = EXCLUDED.nombre,
            subtitulo = EXCLUDED.subtitulo,
            orden = EXCLUDED.orden,
            descripcion = EXCLUDED.descripcion,
            updated_at = now();

        INSERT INTO fases_despiece (organizacion_id, clave, nombre, subtitulo, orden, descripcion, activo)
        VALUES (r_org.id, 'paso_6', 'Paso 6', 'Canaleta, patines, ejes y accesorios estructurales', 6, 'Instalación de patines de apoyo, ejes de carga, caja de herramientas, estribo y accesorios', true)
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


        -- Obtener IDs de fases para asignación estructurada
        SELECT id INTO v_fase_1 FROM fases_despiece WHERE organizacion_id = r_org.id AND clave = 'paso_1';
        SELECT id INTO v_fase_2 FROM fases_despiece WHERE organizacion_id = r_org.id AND clave = 'paso_2';
        SELECT id INTO v_fase_3 FROM fases_despiece WHERE organizacion_id = r_org.id AND clave = 'paso_3';
        SELECT id INTO v_fase_4 FROM fases_despiece WHERE organizacion_id = r_org.id AND clave = 'paso_4';
        SELECT id INTO v_fase_5 FROM fases_despiece WHERE organizacion_id = r_org.id AND clave = 'paso_5';
        SELECT id INTO v_fase_6 FROM fases_despiece WHERE organizacion_id = r_org.id AND clave = 'paso_6';
        SELECT id INTO v_fase_7 FROM fases_despiece WHERE organizacion_id = r_org.id AND clave = 'paso_7';
        SELECT id INTO v_fase_8 FROM fases_despiece WHERE organizacion_id = r_org.id AND clave = 'paso_8';
        SELECT id INTO v_fase_9 FROM fases_despiece WHERE organizacion_id = r_org.id AND clave = 'paso_9';
        SELECT id INTO v_fase_10 FROM fases_despiece WHERE organizacion_id = r_org.id AND clave = 'paso_10';
        SELECT id INTO v_fase_11 FROM fases_despiece WHERE organizacion_id = r_org.id AND clave = 'paso_11';
        SELECT id INTO v_fase_12 FROM fases_despiece WHERE organizacion_id = r_org.id AND clave = 'paso_12';
        SELECT id INTO v_fase_extras FROM fases_despiece WHERE organizacion_id = r_org.id AND clave = 'extras';
        SELECT id INTO v_fase_llantas_rines FROM fases_despiece WHERE organizacion_id = r_org.id AND clave = 'llantas_rines';

        -- D. Asignar paso y fase_id a las 61 líneas de acero estructural en modelos de tipo 'plataforma'
        -- SOLO modelos.tipo = 'plataforma'. Dolly y Góndola NO se tocan.

        -- Paso 1: Almas
        UPDATE receta_base rb
        SET paso = 'Paso 1', fase_id = v_fase_1
        FROM modelos m
        WHERE rb.modelo_id = m.id AND m.organizacion_id = r_org.id AND m.tipo = 'plataforma'
          AND (rb.paso IS NULL OR rb.paso = '')
          AND rb.material_id = '8e293a14-b9a3-4f5a-91a5-2f271f64c85f';

        -- Paso 2: Soleras de refuerzo de almas
        UPDATE receta_base rb
        SET paso = 'Paso 2', fase_id = v_fase_2
        FROM modelos m
        WHERE rb.modelo_id = m.id AND m.organizacion_id = r_org.id AND m.tipo = 'plataforma'
          AND (rb.paso IS NULL OR rb.paso = '')
          AND rb.material_id = '758e857b-665c-454a-9dbc-26488891e95a';

        -- Paso 3: Estructura primaria, bordas, perno rey, puentes y atizadores
        UPDATE receta_base rb
        SET paso = 'Paso 3', fase_id = v_fase_3
        FROM modelos m
        WHERE rb.modelo_id = m.id AND m.organizacion_id = r_org.id AND m.tipo = 'plataforma'
          AND (rb.paso IS NULL OR rb.paso = '')
          AND rb.material_id IN (
              '45daffba-3466-4f3e-8a8b-d60d3a8eeff1', -- BORDA DELANTERA
              '20bc4eed-7cc3-4ff8-b2f9-9c0b9ef055ba', -- BORDA TRASERA
              'a1df81f9-5cd9-480e-91ff-81c44f0c224a', -- PUENTES DE SUSPENSION
              '4acae371-705c-4ce5-a44c-af1414282fa2', -- PLANCHA PARA LA QUINTA
              '7a29e650-06d8-47da-ba00-dc6f1a2176be', -- PUENTES TIPO J
              '227f6fd8-30cb-412d-ac73-de9ec9e396a1', -- PUENTES DE LA PLANCHA
              '41f81b98-fde5-4153-8553-0f82c315b960', -- BOTONES
              'b7579499-3821-458a-91d3-b1c5362c8265', -- ATIZADORES INTERNOS
              '0b89cc55-b3c6-4bde-8bac-64be7885217b', -- ATIZADORES EXTERNOS 27 CM
              '5096421e-9dd5-4354-b192-a903d05d4cf8', -- ATIZADORES EXTERNOS 29CM
              '3c25ea9e-1567-4762-a403-3b95aaeb7c37', -- JALON
              'ee8ca04a-e61d-4228-b57f-2884998abb1b', -- REFUERZO DE JALON
              'c8faf622-7ee3-4f79-b92c-8058f23f2bad', -- PERNO REY
              'ca6a49d8-d291-44d7-b85a-011e053cbedd'  -- TAPA PARA PERNO REY
          );

        -- Paso 4: Cargadores transversales IPR, bordas laterales, aletas, esquineros y buchacas
        UPDATE receta_base rb
        SET paso = 'Paso 4', fase_id = v_fase_4
        FROM modelos m
        WHERE rb.modelo_id = m.id AND m.organizacion_id = r_org.id AND m.tipo = 'plataforma'
          AND (rb.paso IS NULL OR rb.paso = '')
          AND rb.material_id IN (
              '3738e243-6167-4360-a289-60e22f3a5574', -- KIT DE ALETAS 27 X 50 CM
              'd7ac4c98-d74d-4784-9229-699f6cb1727f', -- KIT DE ALETAS 27 X 60 CM
              'b0ae5871-8a57-4982-a985-3bdbef6d84b2', -- KIT DE ALETAS 40 X 50 CM
              '42203533-e399-4048-bb88-edeb887b652a', -- KIT DE ALETAS 40 X 60 CM
              '5ce2ea37-3c74-425a-baff-7de53e71860c', -- KIT DE ALETAS 45 X 50 CM
              '77345584-2c98-4537-b228-7288048f98b4', -- KIT DE ALETAS 45 X 60 CM
              '755dc358-f2dd-4dbc-a7da-5f2669fae852', -- ESQUINERO DELANTERO
              'f19fa2d5-cf64-435f-92d6-1ec3240ef564', -- ESQUINERO TRASERO
              '0193683f-1f70-4acc-adfa-d52ce23de90d', -- BUCHACAS
              '137801d9-8eea-4309-8314-35d590b2f481', -- TUBOS LATERALES
              '6d4da212-cd0d-4345-8cdf-44dc0579099d', -- BASE PARA ESTRIBO PLACA TRASERA
              'bbabf8ed-47f4-4330-baf3-4b91bc8e0760', -- BASE PARA ESTRIBO PLACA FRONTAL
              '75a6b9e2-56b3-4cba-a696-bf8ae4f07046', -- BASE PARA ESTRIBO PLACA INTERMEDIA
              'c711eccd-c643-44f1-92cc-fc21503902ce', -- CARGADOR
              '03d632b8-e0eb-4bc2-9928-b610e8ea79ea'  -- BORDAS LATERALES
          );

        -- Paso 5: Bases de suspensión, tanques, manitas y cartabones
        UPDATE receta_base rb
        SET paso = 'Paso 5', fase_id = v_fase_5
        FROM modelos m
        WHERE rb.modelo_id = m.id AND m.organizacion_id = r_org.id AND m.tipo = 'plataforma'
          AND (rb.paso IS NULL OR rb.paso = '')
          AND rb.material_id IN (
              '438ad5b7-4f26-4872-a0d3-82c6759bebdd', -- BASE PARA TANQUES
              '16bfb053-307c-4a89-80ee-5a8c193faf7c', -- BASE PARA PATINES PLACAS
              'b7a97767-d7af-40cc-ba18-4b533b6da63f', -- BASE PARA PATINES SOLERA
              '5af16bd7-31e4-4053-8742-55fe84d1a0ea', -- BASE PARA MANITAS
              '7da6ed98-2b9e-41df-b36c-40d20970a598', -- BASE PARA PERCHAS
              '5bfcef2f-9f89-484c-bf45-27c1233ad653', -- BASE PARA PLATOS
              '705dda7a-2293-44c7-a7d3-8b6e34b97af5', -- PESTAÑAS
              '249309a9-eb57-4f7e-9370-21946c68f3aa', -- GANCHOS
              '21033076-8b49-41ee-bff0-925a2b8c6c1d', -- PLAFONES OVALADOS
              '6a0f8a0a-0913-4f7b-a79e-6ba537aad8ee', -- CARTABONES PARA JALON
              'c3632f71-dfe8-4f61-b410-5329e8320986'  -- SOLERA PARA ESQUINEROS
          );

        -- Paso 6: Accesorios estructurales, herrajes de patines, porta llantas, estribo y porta loderas
        UPDATE receta_base rb
        SET paso = 'Paso 6', fase_id = v_fase_6
        FROM modelos m
        WHERE rb.modelo_id = m.id AND m.organizacion_id = r_org.id AND m.tipo = 'plataforma'
          AND (rb.paso IS NULL OR rb.paso = '')
          AND rb.material_id IN (
              '79ff96c0-7a6e-4616-bc0a-05779054b21d', -- U PARA JALON
              '64664069-1dfe-4003-bcfb-c888eb615653', -- BASE PARA FOCO DE ABS
              '59d52996-44bf-4888-893e-da655ffded3e', -- BASE PARA ABS
              '56cc0bee-2078-4fb9-94ab-974f1ea10449', -- PORTA PLACAS
              'f99ae062-8396-43da-89bb-bc5c4ec157f2', -- CINCHO
              'cd774fce-0f85-47df-a729-5f66df250f9b', -- HERAJE PARA PATINES 110CM
              'a4fa05c4-9f9c-41dc-a499-f5f2126e5678', -- HERAJE PARA PATINES 125CM
              '427b4801-dd67-4643-b7e9-9c064f3fdacb', -- HERAJE PARA PATINES 70CM
              '3ceca9d3-9f50-4afd-abb3-28d06ffd6460', -- HERAJE PARA PATINES 67CM
              '751108eb-fcbb-413b-a410-7eb73062f2a1', -- HERAJE PARA PATINES 23CM
              '49f8c40d-3a98-4df9-870c-884032dff13b', -- HERAJE PARA PATINES 7CM
              '81cd08c1-d585-42ec-b30e-de166cbac4b6', -- HERAJE PARA PATINES 27CM
              '1fa437ef-fe29-4881-b8aa-12decec4f802', -- HERAJE PARA PATINES 30CM
              '6da557b2-4cc6-4f5d-8aa3-9f90882ba611', -- HERAJE PARA PATINES BUCHACA
              'f7bf645b-3f6b-4d0b-b284-f7b8f063ffca', -- PORTA LLANTAS 1
              '34c47066-df57-4cba-95dd-d4d21d9db62a', -- PORTA LLANTAS 2
              '867d7598-c6d9-421e-800c-be7386309009', -- PORTA LLANTAS 3
              '9ee8fbd5-f3bb-4197-8c07-553e26e25df0', -- ESTRIBO
              '83136b99-f8df-4754-8a0a-fa860b871b9c'  -- PORTA LODERAS
          );

        -- E. Asignar fase_id en receta_base a través de equivalencias para todos los modelos plataforma
        -- Respetando paso y uso originales (ej. AIRE, LUZ, TERMINADO, LIMPIEZA, EXTRAS)
        UPDATE receta_base rb
        SET fase_id = fe.fase_id
        FROM fases_despiece_equivalencias fe, modelos m
        WHERE m.id = rb.modelo_id
          AND m.tipo = 'plataforma'
          AND fe.organizacion_id = r_org.id
          AND m.organizacion_id = r_org.id
          AND upper(trim(rb.paso)) = upper(trim(fe.paso_legacy))
          AND (rb.fase_id IS NULL OR rb.fase_id != fe.fase_id);

        -- F. Asignación de fase_id en opcion_componentes según catálogo y Excel oficial
        -- 1. Suspensión y Retráctil -> Paso 5
        UPDATE opcion_componentes oc
        SET fase_id = v_fase_5
        FROM opciones_configuracion o, grupos_configuracion g
        WHERE oc.opcion_id = o.id AND o.grupo_id = g.id
          AND o.organizacion_id = r_org.id
          AND g.clave IN ('suspension', 'retractil')
          AND (oc.fase_id IS NULL OR oc.fase_id != v_fase_5);

        -- 2. Patines y Ejes -> Paso 6 (según clasificación explícita del Excel oficial)
        UPDATE opcion_componentes oc
        SET fase_id = v_fase_6
        FROM opciones_configuracion o, grupos_configuracion g
        WHERE oc.opcion_id = o.id AND o.grupo_id = g.id
          AND o.organizacion_id = r_org.id
          AND g.clave IN ('patin', 'eje')
          AND (oc.fase_id IS NULL OR oc.fase_id != v_fase_6);

        -- 3. Pintura -> Paso 8
        UPDATE opcion_componentes oc
        SET fase_id = v_fase_8
        FROM opciones_configuracion o, grupos_configuracion g
        WHERE oc.opcion_id = o.id AND o.grupo_id = g.id
          AND o.organizacion_id = r_org.id
          AND g.clave = 'pintura'
          AND (oc.fase_id IS NULL OR oc.fase_id != v_fase_8);

        -- 4. Pisos -> Paso 11
        UPDATE opcion_componentes oc
        SET fase_id = v_fase_11
        FROM opciones_configuracion o, grupos_configuracion g
        WHERE oc.opcion_id = o.id AND o.grupo_id = g.id
          AND o.organizacion_id = r_org.id
          AND g.clave = 'piso'
          AND (oc.fase_id IS NULL OR oc.fase_id != v_fase_11);

        -- 5. Llantas y Rines -> llantas_rines
        UPDATE opcion_componentes oc
        SET fase_id = v_fase_llantas_rines
        FROM opciones_configuracion o, grupos_configuracion g
        WHERE oc.opcion_id = o.id AND o.grupo_id = g.id
          AND o.organizacion_id = r_org.id
          AND g.clave IN ('rines', 'llantas')
          AND (oc.fase_id IS NULL OR oc.fase_id != v_fase_llantas_rines);

        -- 6. Adicionales y Gancho -> extras
        UPDATE opcion_componentes oc
        SET fase_id = v_fase_extras
        FROM opciones_configuracion o, grupos_configuracion g
        WHERE oc.opcion_id = o.id AND o.grupo_id = g.id
          AND o.organizacion_id = r_org.id
          AND g.clave IN ('gancho', 'adicionales')
          AND (oc.fase_id IS NULL OR oc.fase_id != v_fase_extras);

        -- G. Resolver alternativas en suspensión (ajuste de sustitutos a cantidad = 0 y rol = 'sustituto')
        -- Hendrickson alta: Monroe 65512 es sustituto opcional (Excel Fila 80 cant = 0)
        SELECT id INTO v_opcion_id FROM opciones_configuracion WHERE organizacion_id = r_org.id AND clave = 'alta_hendrickson';
        IF v_opcion_id IS NOT NULL THEN
            UPDATE opcion_componentes
            SET cantidad = 0, rol = 'sustituto'
            WHERE opcion_id = v_opcion_id
              AND material_id IN (
                  SELECT id FROM productos 
                  WHERE organizacion_id = r_org.id 
                    AND (nombre ILIKE '%MONROE%65512%' OR nombre ILIKE '%MONRROE%65512%')
              );
        END IF;

        -- Fleet Master: Amortiguadores FCR y Gabriel son sustitutos (Excel Filas 97, 98 cant = 0)
        -- Cámaras AMPRO y FCR son sustitutos (Excel Filas 100, 101 cant = 0)
        SELECT o.id INTO v_opcion_id 
        FROM opciones_configuracion o 
        JOIN grupos_configuracion g ON g.id = o.grupo_id 
        WHERE o.organizacion_id = r_org.id AND o.clave = 'fleet_master' AND g.clave = 'suspension';

        IF v_opcion_id IS NOT NULL THEN
            UPDATE opcion_componentes
            SET cantidad = 0, rol = 'sustituto'
            WHERE opcion_id = v_opcion_id
              AND material_id IN (
                  SELECT id FROM productos 
                  WHERE organizacion_id = r_org.id 
                    AND (nombre ILIKE '%AMORTIGUADOR%FCR%' OR nombre ILIKE '%AMORTIGUADOR%GABRIEL%')
              );

            UPDATE opcion_componentes
            SET cantidad = 0, rol = 'sustituto'
            WHERE opcion_id = v_opcion_id
              AND material_id IN (
                  SELECT id FROM productos 
                  WHERE organizacion_id = r_org.id 
                    AND (nombre ILIKE '%CAMARA%AMPRO%1R14-039%' OR nombre ILIKE '%CAMARA%FCR%1R14-039%')
              );
        END IF;

    END LOOP;
END $$;

COMMIT;
