"""
Generador de la migración SQL 20261102_01_despiece_union.sql,
verificacion_T2.sql y prueba_T2.sql
a partir de docs/despiece/union_listados_raw.json
"""

import json
import os
import re

with open('docs/despiece/union_listados_raw.json', 'r', encoding='utf-8') as f:
    rows = json.load(f)

typos_map = {
    'PRAIMER': 'PRIMER',
    'INCERTO': 'INSERTO',
    'AUMINIO': 'ALUMINIO',
    'TORNILLEROA': 'TORNILLERIA',
    'MONRROE': 'MONROE',
    'CARGADO 3X102 IN': 'CARGADOR 3" X 102"',
    'FLET MASTER': 'FLEET MASTER',
    'FLET': 'FLEET',
    'SHERVI': 'SHERWIN WILLIAMS',
    'PUENTES DE SUSPENSIÓN ': 'PUENTES DE SUSPENSION'
}

def normalizar(s):
    if not s: return ''
    txt = str(s).strip().upper()
    for k, v in typos_map.items():
        txt = txt.replace(k, v)
    return re.sub(r'\s+', ' ', txt).strip()

# Fases del catálogo
FASES = [
    ('paso_1', 'Paso 1', 'Armado y corte de almas', 1, 'Corte de placa de grado A-50 y ensamblado de viga principal'),
    ('paso_2', 'Paso 2', 'Soleras de refuerzo de almas', 2, 'Soldadura y unión de soleras A-529 de 1/2" x 6"'),
    ('paso_3', 'Paso 3', 'Estructura primaria, bordas y plancha de quinta rueda', 3, 'Bordas delantera/trasera, perno rey Holland, plancha de 3/8" y puentes'),
    ('paso_4', 'Paso 4', 'Cargadores transversales IPR y atizadores', 4, 'Cargadores IPR de 4" x 102", bordas laterales y atizadores'),
    ('paso_5', 'Paso 5', 'Instalación de suspensión, patines, ejes y retráctiles', 5, 'Ensamble de suspensión neumática/mecánica, patines y ejes'),
    ('paso_6', 'Paso 6', 'Canaleta, refuerzos y accesorios estructurales', 6, 'Caja de herramientas, bases de ABS, cinchos y accesorios'),
    ('paso_7', 'PASO 7', 'Lavado químico, fosfato y preparación de superficie', 7, 'Desengrasado, fosfatado y limpieza profunda previa a pintura'),
    ('paso_8', 'PASO 8', 'Aplicación de pintura y recubrimientos por marca', 8, 'Aplicación de fondo anticorrosivo y esmalte poliuretano'),
    ('paso_9', 'PASO 9', 'Kit neumático, sistema ABS y tanques de aire', 9, 'Instalación de tubería, mangueras, válvulas, tanques y arnés ABS'),
    ('paso_10', 'PASO 10', 'Sistema de iluminación reglamentaria y arnés eléctrico', 10, 'Colocación de plafones LED reglamentarios, arnés sellado y cableado'),
    ('paso_11', 'PASO 11', 'Instalación de pisos y fijaciones', 11, 'Instalación de piso de plástico, madera o pino con pijas fijadoras'),
    ('paso_12', 'PASO 12', 'Acabados, loderas, winches y rotulación final', 12, 'Colocación de loderas Leolca, cinta reflejante, winches y placa de serie'),
    ('extras', 'EXTRAS', 'Equipamiento adicional (redilas, retráctil Leolca, multimodal)', 13, 'Accesorios opcionales para configuraciones especiales'),
    ('llantas_rines', 'LLANTAS Y RINES', 'Juego de rodado (rines de acero/aluminio y llantas)', 14, 'Montaje de rines de 22.5" / 24.5" y neumáticos')
]

EQUIVALENCIAS = [
    ('PASO 1', 'paso_1', 'Equivalencia estándar Paso 1'),
    ('PASO 2', 'paso_2', 'Equivalencia estándar Paso 2'),
    ('PASO 3', 'paso_3', 'Equivalencia estándar Paso 3'),
    ('PASO 4', 'paso_4', 'Equivalencia estándar Paso 4'),
    ('PASO 5', 'paso_5', 'Equivalencia estándar Paso 5'),
    ('PASO 6', 'paso_6', 'Equivalencia estándar Paso 6'),
    ('PASO 7', 'paso_7', 'Equivalencia estándar Paso 7'),
    ('PASO 8', 'paso_8', 'Equivalencia estándar Paso 8'),
    ('PINTURA', 'paso_8', 'Equivalencia histórica pintura -> Paso 8'),
    ('PASO 9', 'paso_9', 'Equivalencia estándar Paso 9'),
    ('AIRE', 'paso_9', 'Equivalencia histórica aire -> Paso 9'),
    ('PASO 10', 'paso_10', 'Equivalencia estándar Paso 10'),
    ('LUZ', 'paso_10', 'Equivalencia histórica luz -> Paso 10'),
    ('PASO 11', 'paso_11', 'Equivalencia estándar Paso 11'),
    ('PISOS', 'paso_11', 'Equivalencia histórica pisos -> Paso 11'),
    ('PASO 12', 'paso_12', 'Equivalencia estándar Paso 12'),
    ('TERMINADO', 'paso_12', 'Equivalencia histórica terminado -> Paso 12'),
    ('EXTRAS', 'extras', 'Equivalencia histórica extras -> Extras'),
    ('LLANTAS Y RINES', 'llantas_rines', 'Equivalencia estándar Llantas y Rines'),
    ('LLANTAS', 'llantas_rines', 'Equivalencia histórica llantas -> Llantas y Rines'),
    ('RINES', 'llantas_rines', 'Equivalencia histórica rines -> Llantas y Rines')
]

# Recopilar todos los materiales únicos a insertar en productos
# Formato: (nombre_normalizado, unidad, costo, alias, categoria_sugerida)
materiales_dict = {}

def inferir_unidad(prod, nom, cant):
    s = f"{prod} {nom}".upper()
    if 'LITRO' in s or 'DESENGRASANTE' in s or 'FOSFATO' in s or 'ACIDO' in s or 'PINTURA' in s or 'ESMALTE' in s or 'PRIMER' in s or 'REDUCTOR' in s or 'THINNER' in s:
        return 'L'
    if 'MANGUERA' in s or 'CABLE' in s or 'CORRUGADO' in s or 'CINTA' in s:
        return 'M'
    if 'KILO' in s or 'KG' in s:
        return 'KG'
    return 'PZA'

def inferir_categoria(proc, prod):
    p = (proc or '').upper()
    pr = (prod or '').upper()
    if 'PINTURA' in p or 'PASO 8' in p or 'PASO 7' in p: return 'Pintura y Preparación'
    if 'AIRE' in p or 'PASO 9' in p: return 'Aire y Frenos ABS'
    if 'LUZ' in p or 'PASO 10' in p: return 'Iluminación y Eléctrico'
    if 'PISOS' in p or 'PASO 11' in p: return 'Pisos y Madera'
    if 'RINES' in p or 'LLANTAS' in p: return 'Llantas y Rines'
    if 'TORNILLO' in pr or 'TUERCA' in pr or 'RONDANA' in pr or 'PIJA' in pr: return 'Tornillería'
    if 'DISCO' in pr or 'MICRO' in pr or 'CO2' in pr or 'OXIGENO' in pr or 'CONSUMIBLE' in pr: return 'Consumibles'
    if 'SUSPENSION' in pr: return 'Suspensión'
    if 'PATIN' in pr or 'EJE' in pr: return 'Patines y Ejes'
    return 'Acero y Estructura'

for r in rows:
    prod = r['producto'] or ''
    sub = r['subpieza'] or ''
    nom = r['nomenclatura'] or ''
    
    # Resolver nombre de producto
    if sub and sub.upper() not in ['27 CM', '29CM', 'PIERNAS IZQUIERDA Y DERECHA', 'PLATOS IZQUIERDO Y DERECHO']:
        if prod.upper() in ['PINTURA', 'KIT ABS', 'KIT DE LUZ', 'PISOS', 'ACABADO', 'TIPO DE RINES', 'LLANTAS', 'REDILAS', 'PARA EQUIPOS MULTIMODAL', 'TIPO DE GANCHO', 'TORNILLERIA PARA GANCHO', 'TIPO DE BOLSA Y TORNILLEROA PARA RETRACTIL']:
            pieza = sub
        elif 'SUSPENSION' in prod.upper():
            pieza = f"{sub} {nom}".strip() if nom else sub
        elif prod.upper() in ['PATINES', 'EJES']:
            pieza = sub
        else:
            pieza = f"{prod} {sub}".strip()
    elif nom and prod.upper() in ['ALMA', 'SOLERA PARA ALMAS', 'PUENTES DE SUSPENSIÓN', 'PLANCHA PARA LA QUINTA']:
        pieza = f"{prod} ({nom})".strip()
    else:
        pieza = prod

    norm = normalizar(pieza)
    if not norm or norm in ['25.8', 'RIN 24.5', 'RIN 22.5']:
        continue

    pu = r['precio_unitario_raw']
    pu_val = float(pu) if pu is not None and str(pu).strip() and float(pu) > 0 else 0
    
    unidad = inferir_unidad(prod, nom, r['cantidad_raw'])
    categoria = inferir_categoria(r['proceso'], prod)
    
    if norm not in materiales_dict:
        materiales_dict[norm] = {
            'nombre': norm,
            'alias': pieza,
            'unidad': unidad,
            'categoria': categoria,
            'costo': pu_val,
            'proceso': r['proceso']
        }
    else:
        if pu_val > 0 and materiales_dict[norm]['costo'] == 0:
            materiales_dict[norm]['costo'] = pu_val

print(f"Materiales listos para migración: {len(materiales_dict)}")

# Generar archivo SQL de migración
sql_lines = []
sql_lines.append("-- Migración 20261102_01_despiece_union.sql")
sql_lines.append("-- T2 (Turno Noche 2026-11-02): Despiece por fases desde UNION DE LISTADOS ACTULIZADO (1).xlsx")
sql_lines.append("-- 1. Catálogo oficial de fases_despiece (14 fases: Paso 1..12, Extras, Llantas/Rines)")
sql_lines.append("-- 2. Tabla de equivalencias fases_despiece_equivalencias")
sql_lines.append("-- 3. Adición de columna fase_id a receta_base y opcion_componentes")
sql_lines.append("-- 4. Mapeo e inserción de nuevos materiales sin costo / con costo sin pisar existentes")
sql_lines.append("-- 5. Notas: 'import-union-2026-11'")
sql_lines.append("")
sql_lines.append("BEGIN;")
sql_lines.append("")

# Definición de tablas
sql_lines.append("""
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
""")

# Bloque PL/pgSQL para poblar datos por organización
sql_lines.append("""
DO $$
DECLARE
    r_org RECORD;
    v_fase_id UUID;
    v_mat_id TEXT;
BEGIN
    FOR r_org IN SELECT id FROM organizaciones LOOP
        -- A. Poblar fases_despiece
""")

for clave, nombre, subtitulo, orden, desc in FASES:
    c_safe = clave.replace("'", "''")
    n_safe = nombre.replace("'", "''")
    s_safe = subtitulo.replace("'", "''")
    d_safe = desc.replace("'", "''")
    sql_lines.append(f"""        INSERT INTO fases_despiece (organizacion_id, clave, nombre, subtitulo, orden, descripcion, activo)
        VALUES (r_org.id, '{c_safe}', '{n_safe}', '{s_safe}', {orden}, '{d_safe}', true)
        ON CONFLICT (organizacion_id, clave) DO UPDATE SET
            nombre = EXCLUDED.nombre,
            subtitulo = EXCLUDED.subtitulo,
            orden = EXCLUDED.orden,
            descripcion = EXCLUDED.descripcion,
            updated_at = now();
""")

sql_lines.append("""
        -- B. Poblar fases_despiece_equivalencias
""")

for paso_leg, clave_fase, notas in EQUIVALENCIAS:
    p_safe = paso_leg.replace("'", "''")
    c_safe = clave_fase.replace("'", "''")
    n_safe = notas.replace("'", "''")
    sql_lines.append(f"""        SELECT id INTO v_fase_id FROM fases_despiece WHERE organizacion_id = r_org.id AND clave = '{c_safe}';
        IF v_fase_id IS NOT NULL THEN
            INSERT INTO fases_despiece_equivalencias (organizacion_id, paso_legacy, fase_id, notas)
            VALUES (r_org.id, '{p_safe}', v_fase_id, '{n_safe}')
            ON CONFLICT (organizacion_id, paso_legacy) DO UPDATE SET
                fase_id = EXCLUDED.fase_id,
                notas = EXCLUDED.notas;
        END IF;
""")

sql_lines.append("""
        -- C. Poblar productos (materias primas) desde UNION DE LISTADOS
""")

for k, m in sorted(materiales_dict.items()):
    nombre_safe = m['nombre'].replace("'", "''")
    alias_safe = m['alias'].replace("'", "''")
    unidad_safe = m['unidad'].replace("'", "''")
    cat_safe = m['categoria'].replace("'", "''")
    costo = m['costo']
    
    sql_lines.append(f"""        -- Material: {nombre_safe}
        IF NOT EXISTS (SELECT 1 FROM productos WHERE organizacion_id = r_org.id AND nombre = '{nombre_safe}' AND tipo_item = 'materia_prima') THEN
            INSERT INTO productos (organizacion_id, nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, notas)
            VALUES (r_org.id, '{nombre_safe}', 'bien', 'materia_prima', '{unidad_safe}', {costo}, 0, '{alias_safe}', 'import-union-2026-11');
        ELSE
            -- Si existe con costo 0 y el Excel provee precio, actualizarlo respetando la regla
            UPDATE productos
            SET costo = {costo}, notas = COALESCE(notas, '') || ' import-union-2026-11'
            WHERE organizacion_id = r_org.id AND nombre = '{nombre_safe}' AND tipo_item = 'materia_prima' AND (costo IS NULL OR costo = 0) AND {costo} > 0;
        END IF;
""")

sql_lines.append("""
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
""")

migracion_path = 'supabase/migrations/20261102_01_despiece_union.sql'
with open(migracion_path, 'w', encoding='utf-8') as f:
    f.write('\n'.join(sql_lines))

print(f"Migración guardada en {migracion_path} ({len(sql_lines)} líneas)")

# Generar verificacion_T2.sql
verif_sql = """-- Verificación de esquema y datos para T2 (Despiece por fases UNION)
-- Debe retornar todo_ok = true y conteos positivos

WITH conteos AS (
    SELECT
        (SELECT count(*) FROM fases_despiece) AS total_fases,
        (SELECT count(*) FROM fases_despiece_equivalencias) AS total_equiv,
        (SELECT count(*) FROM productos WHERE notas LIKE '%import-union-2026-11%') AS total_productos_union,
        (SELECT count(*) FROM receta_base WHERE fase_id IS NOT NULL) AS recetas_con_fase,
        (SELECT count(*) FROM opcion_componentes WHERE fase_id IS NOT NULL) AS opciones_con_fase
)
SELECT
    total_fases,
    total_equiv,
    total_productos_union,
    recetas_con_fase,
    opciones_con_fase,
    (total_fases >= 14 AND total_equiv >= 20 AND total_productos_union > 0) AS todo_ok
FROM conteos;
"""

with open('docs/despiece/verificacion_T2.sql', 'w', encoding='utf-8') as f:
    f.write(verif_sql)

# Generar prueba_T2.sql con BEGIN ... ROLLBACK
prueba_sql = """-- Prueba transaccional de T2: Fases, equivalencias y despiece
-- Se ejecuta dentro de un bloque BEGIN ... ROLLBACK

BEGIN;

DO $$
DECLARE
    v_org_id UUID;
    v_fase_id UUID;
    v_test_prod_id TEXT;
    v_receta_id UUID;
    v_count INT;
BEGIN
    SELECT id INTO v_org_id FROM organizaciones LIMIT 1;
    IF v_org_id IS NULL THEN
        RAISE EXCEPTION 'No se encontró organización de prueba';
    END IF;

    -- 1. Verificar existencia de las 14 fases
    SELECT count(*) INTO v_count FROM fases_despiece WHERE organizacion_id = v_org_id;
    IF v_count < 14 THEN
        RAISE EXCEPTION 'Fases esperadas >= 14, encontradas: %', v_count;
    END IF;

    -- 2. Verificar fases_despiece_equivalencias
    SELECT count(*) INTO v_count FROM fases_despiece_equivalencias WHERE organizacion_id = v_org_id;
    IF v_count < 20 THEN
        RAISE EXCEPTION 'Equivalencias esperadas >= 20, encontradas: %', v_count;
    END IF;

    -- 3. Probar asignación de fase a un nuevo componente en receta_base
    SELECT id INTO v_fase_id FROM fases_despiece WHERE organizacion_id = v_org_id AND clave = 'paso_1';
    SELECT id INTO v_test_prod_id FROM productos WHERE organizacion_id = v_org_id LIMIT 1;

    -- Debe permitir insertar con fase_id
    INSERT INTO receta_base (modelo_id, material_id, cantidad, paso, fase_id, notas)
    SELECT id, v_test_prod_id, 1, 'Paso 1', v_fase_id, 'test-t2'
    FROM modelos WHERE tipo = 'plataforma' LIMIT 1
    RETURNING id INTO v_receta_id;

    IF v_receta_id IS NULL THEN
        RAISE EXCEPTION 'Fallo al insertar receta_base de prueba con fase_id';
    END IF;

    -- 4. Probar consulta con JOIN entre receta_base y fases_despiece
    SELECT count(*) INTO v_count
    FROM receta_base rb
    JOIN fases_despiece fd ON rb.fase_id = fd.id
    WHERE rb.id = v_receta_id;

    IF v_count != 1 THEN
        RAISE EXCEPTION 'JOIN entre receta_base y fases_despiece no retornó 1';
    END IF;

    RAISE NOTICE 'Prueba transaccional T2 completada con éxito. Ejecutando ROLLBACK.';
END $$;

ROLLBACK;
"""

with open('docs/despiece/prueba_T2.sql', 'w', encoding='utf-8') as f:
    f.write(prueba_sql)

print("verificacion_T2.sql y prueba_T2.sql guardados exitosamente en docs/despiece/")
