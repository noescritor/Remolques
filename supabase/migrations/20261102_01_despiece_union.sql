-- Migración 20261102_01_despiece_union.sql
-- T2 Ronda 4: Despiece oficial por fases desde UNION DE LISTADOS
-- Corrección integral: CERO UUIDs de productos, resolución por nombre exacto dentro de la organización,
-- respeto absoluto de receta_base.paso (solo asigna fase_id) y soporte multitenant estricto.

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
    v_fase_5 UUID;
    v_fase_6 UUID;
    v_fase_8 UUID;
    v_fase_11 UUID;
    v_fase_llantas_rines UUID;
    v_fase_extras UUID;
    r_acero RECORD;
    v_mat_id TEXT;
    v_mat_count INT;
    v_target_fase_id UUID;
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


        -- D. Asignar fase_id a las 61 líneas de acero estructural en modelos de tipo 'plataforma'
        -- SOLO modelos.tipo = 'plataforma'. Dolly y Góndola NO se tocan.
        -- Resuelve los productos por nombre exacto + organización + tipo_item = 'materia_prima'.
        -- CERO UUIDs literales de productos en el código.
        -- No se escribe receta_base.paso: se conserva intacto (NULL o previo), solo se fija fase_id.
        FOR r_acero IN
            SELECT * FROM (VALUES

                ('paso_1', 'ALMA (PLACA DE GRADO A-50 CAL. 1/4")'),
                ('paso_2', 'SOLERA DE ALMA (SOLERA DE GRADO A-529 A 1/2" X 6")'),
                ('paso_3', 'BORDA DELANTERA (PLACA DE GRADO A-36 CAL. 3/16")'),
                ('paso_3', 'BORDA TRASERA (PLACA DE GRADO A-36 CAL. 3/16")'),
                ('paso_3', 'PUENTES DE SUSPENSIÓN (PTR A 2 X 6")'),
                ('paso_3', 'PLANCHA PARA LA QUINTA (PLACA DE GRADO A-36 CAL. 3/8")'),
                ('paso_3', 'PUENTES TIPO J (PLACA DE GRADO A-36 CAL. 3/16")'),
                ('paso_3', 'PUENTES DE LA PLANCHA (CANAL U 5")'),
                ('paso_3', 'BOTONES (PLACA DE GRADO A-36 CAL. 1/4")'),
                ('paso_3', 'ATIZADORES INTERNOS (PLACA DE GRADO A-36 CAL. 1/4")'),
                ('paso_3', 'ATIZADORES EXTERNOS 27 CM (SOLERA DE GRADO A-36 A 3/8" X 2")'),
                ('paso_3', 'ATIZADORES EXTERNOS 29CM'),
                ('paso_3', 'JALON (PLACA DE GRADO A-36 CAL. 1/2")'),
                ('paso_3', 'REFUERZO DE JALON (PLACA DE GRADO A-36 CAL. 3/8")'),
                ('paso_3', 'PERNO REY (PERNO REY HOLLAND 3/8")'),
                ('paso_3', 'TAPA PARA PERNO REY (CANAL U 6")'),
                ('paso_4', 'KIT DE ALETAS 27 X 50 CM (PLACA DE GRADO A-36 CAL. 10)'),
                ('paso_4', 'KIT DE ALETAS 27 X 60 CM'),
                ('paso_4', 'KIT DE ALETAS 40 X 50 CM'),
                ('paso_4', 'KIT DE ALETAS 40 X 60 CM'),
                ('paso_4', 'KIT DE ALETAS 45 X 50 CM'),
                ('paso_4', 'KIT DE ALETAS 45 X 60 CM'),
                ('paso_4', 'ESQUINERO DELANTERO (PLACA DE GRADO A-36 CAL. 1/4")'),
                ('paso_4', 'ESQUINERO TRASERO (PLACA DE GRADO A-36 CAL. 1/4")'),
                ('paso_4', 'BUCHACAS (PLACA DE GRADO A-36 CAL. 1/4")'),
                ('paso_4', 'TUBOS LATERALES (TUBO DE 1 1/4" CED. 40)'),
                ('paso_4', 'BASE PARA ESTRIBO PLACA TRASERA (PLACA DE GRADO A-36 CAL. 1/4")'),
                ('paso_4', 'BASE PARA ESTRIBO PLACA FRONTAL (PLACA DE GRADO A-36 CAL. 1/4")'),
                ('paso_4', 'BASE PARA ESTRIBO PLACA INTERMEDIA (PLACA DE GRADO A-36 CAL. 1/4")'),
                ('paso_4', 'CARGADOR (IPR DE 4")'),
                ('paso_4', 'BORDAS LATERALES (CANAL U 6")'),
                ('paso_5', 'BASE PARA TANQUES (PLACA DE GRADO A-36 CAL. 1/4")'),
                ('paso_5', 'BASE PARA PATINES PLACAS (PLACA DE GRADO A-36 CAL. 1/4")'),
                ('paso_5', 'BASE PARA PATINES SOLERA (SOLERA DE GRADO A-36 A 3/8" X 2")'),
                ('paso_5', 'BASE PARA MANITAS (PLACA DE GRADO A-36 CAL. 1/4")'),
                ('paso_5', 'BASE PARA PERCHAS (SOLERA DE GRADO A-36 A 1/2" X 6")'),
                ('paso_5', 'BASE PARA PLATOS (SOLERA DE GRADO A-36 A 1/2" X 3")'),
                ('paso_5', 'PESTAÑAS (PLACA DE GRADO A-36 CAL. 1/4")'),
                ('paso_5', 'GANCHOS (REDONDO DE 1/2")'),
                ('paso_5', 'PLAFONES OVALADOS (PLACA DE GRADO A-36 CAL. 1/4")'),
                ('paso_5', 'CARTABONES PARA JALON (PLACA DE GRADO A-36 CAL. 3/8")'),
                ('paso_5', 'SOLERA PARA ESQUINEROS (PLACA DE GRADO A-36 CAL. 3/16")'),
                ('paso_6', 'U PARA JALON (REDONDO DE 1")'),
                ('paso_6', 'BASE PARA FOCO DE ABS (PLACA DE GRADO A-36 CAL. 1/4")'),
                ('paso_6', 'BASE PARA ABS (PLACA DE GRADO A-36 CAL. 1/4")'),
                ('paso_6', 'PORTA PLACAS (PLACA DE GRADO A-36 CAL. 10)'),
                ('paso_6', 'CINCHO (SOLERA DE GRADO A-36 A 3/8" X 2")'),
                ('paso_6', 'HERAJE PARA PATINES 110CM (PLACA DE GRADO A-36 CAL. 3/16")'),
                ('paso_6', 'HERAJE PARA PATINES 125CM'),
                ('paso_6', 'HERAJE PARA PATINES 70CM'),
                ('paso_6', 'HERAJE PARA PATINES 67CM'),
                ('paso_6', 'HERAJE PARA PATINES 23CM'),
                ('paso_6', 'HERAJE PARA PATINES 7CM (SOLERA DE GRADO A-36 A 1/2" X 3")'),
                ('paso_6', 'HERAJE PARA PATINES 27CM'),
                ('paso_6', 'HERAJE PARA PATINES 30CM'),
                ('paso_6', 'HERAJE PARA PATINES BUCHACA (PLACA DE GRADO A-36 CAL. 1/4")'),
                ('paso_6', 'PORTA LLANTAS (PLACA DE GRADO A-36 CAL. 1/4")'),
                ('paso_6', 'PORTA LLANTAS (PLACA DE GRADO A-36 CAL. 1/4") #2'),
                ('paso_6', 'PORTA LLANTAS (SOLERA DE GRADO A-36 A 1/2" X 3")'),
                ('paso_6', 'ESTRIBO (PTR DE 4X4" A 6.10M)'),
                ('paso_6', 'PORTA LODERAS (PLACA DE GRADO A-36 CAL. 12)')

            ) AS t(fase_clave, producto_nombre)
        LOOP
            -- 1. Resolver fase_id dentro de la organización
            SELECT id INTO v_target_fase_id
            FROM fases_despiece
            WHERE organizacion_id = r_org.id AND clave = r_acero.fase_clave;

            IF v_target_fase_id IS NULL THEN
                RAISE EXCEPTION 'Fase % no encontrada para la organizacion %', r_acero.fase_clave, r_org.id;
            END IF;

            -- 2. Resolver material_id por nombre exacto dentro de la organizacion
            SELECT count(*), min(id) INTO v_mat_count, v_mat_id
            FROM productos
            WHERE organizacion_id = r_org.id
              AND nombre = r_acero.producto_nombre
              AND tipo_item = 'materia_prima';

            IF v_mat_count = 0 THEN
                RAISE EXCEPTION 'Producto no encontrado: % (org: %, tipo_item: materia_prima)', r_acero.producto_nombre, r_org.id;
            ELSIF v_mat_count > 1 THEN
                RAISE EXCEPTION 'Producto ambiguo (% encontrados): % (org: %, tipo_item: materia_prima)', v_mat_count, r_acero.producto_nombre, r_org.id;
            END IF;

            -- 3. Asignar fase_id en receta_base a los modelos de plataforma
            -- SIN alterar receta_base.paso
            UPDATE receta_base rb
            SET fase_id = v_target_fase_id
            FROM modelos m
            WHERE rb.modelo_id = m.id
              AND m.organizacion_id = r_org.id
              AND m.tipo = 'plataforma'
              AND rb.material_id = v_mat_id
              AND (rb.fase_id IS NULL OR rb.fase_id != v_target_fase_id);
        END LOOP;

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
        SELECT id INTO v_fase_5 FROM fases_despiece WHERE organizacion_id = r_org.id AND clave = 'paso_5';
        SELECT id INTO v_fase_6 FROM fases_despiece WHERE organizacion_id = r_org.id AND clave = 'paso_6';
        SELECT id INTO v_fase_8 FROM fases_despiece WHERE organizacion_id = r_org.id AND clave = 'paso_8';
        SELECT id INTO v_fase_11 FROM fases_despiece WHERE organizacion_id = r_org.id AND clave = 'paso_11';
        SELECT id INTO v_fase_llantas_rines FROM fases_despiece WHERE organizacion_id = r_org.id AND clave = 'llantas_rines';
        SELECT id INTO v_fase_extras FROM fases_despiece WHERE organizacion_id = r_org.id AND clave = 'extras';

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

        -- 5. Rines y Llantas -> Llantas y Rines
        UPDATE opcion_componentes oc
        SET fase_id = v_fase_llantas_rines
        FROM opciones_configuracion o, grupos_configuracion g
        WHERE oc.opcion_id = o.id AND o.grupo_id = g.id
          AND o.organizacion_id = r_org.id
          AND g.clave IN ('rines', 'llantas')
          AND (oc.fase_id IS NULL OR oc.fase_id != v_fase_llantas_rines);

        -- 6. Adicionales -> Extras
        UPDATE opcion_componentes oc
        SET fase_id = v_fase_extras
        FROM opciones_configuracion o, grupos_configuracion g
        WHERE oc.opcion_id = o.id AND o.grupo_id = g.id
          AND o.organizacion_id = r_org.id
          AND g.clave IN ('adicionales', 'redilas')
          AND (oc.fase_id IS NULL OR oc.fase_id != v_fase_extras);

        -- G. Resolver alternativas en suspensión (ajuste de sustitutos a cantidad = 0 y rol = 'sustituto')
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
