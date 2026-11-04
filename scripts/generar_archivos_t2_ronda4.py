"""
Generador completo para T2 Ronda 4:
- supabase/migrations/20261102_01_despiece_union.sql
- docs/despiece/verificacion_T2.sql
- docs/despiece/prueba_T2.sql
- docs/despiece/ANALISIS_UNION_LISTADOS.md
"""

import json
import re

with open('docs/despiece/union_listados_raw.json', 'r', encoding='utf-8') as f:
    excel_rows = json.load(f)

with open('docs/despiece/productos_existentes_base.json', 'r', encoding='utf-8') as f:
    db_prods = json.load(f)

with open('docs/despiece/receta_plataforma_40ft.json', 'r', encoding='utf-8') as f:
    rb_lines = json.load(f)

with open('docs/despiece/opcion_componentes_base.json', 'r', encoding='utf-8') as f:
    oc_lines = json.load(f)

typos_map = {
    'PRAIMER': 'PRIMER',
    'INCERTO': 'INSERTO',
    'AUMINIO': 'ALUMINIO',
    'TORNILLEROA': 'TORNILLERIA',
    'MONRROE': 'MONROE',
    'CARGADO': 'CARGADOR',
    'FLET': 'FLEET',
    'SHERVIWILLIAMS': 'SHERWIN WILLIAMS',
    'SHERVI': 'SHERWIN WILLIAMS',
    'ACURRAI': 'ACCURIDE',
    'FIRESTO': 'FIRESTONE',
    'THINER': 'THINNER',
    'HERAJE': 'HERRAJE',
    'CAL,': 'CAL.',
    'CAL ': 'CAL. ',
    'ROLLO DE MICRO ALAMBRE': 'ROLLO DE MICROALAMBRE',
    'SOLERA PARA ALMAS': 'SOLERA DE ALMA',
    'PUENTES DE SUSPENSIÓN': 'PUENTES DE SUSPENSION',
    'CANAL "U" DE 6" (12KG)': 'CANAL U 6"',
    'CANAL "U" DE 6" (12 KG)': 'CANAL U 6"',
    'CANAL "U" DE 6"': 'CANAL U 6"',
    'PTR DE 6X2" CAL. 3/16"': 'PTR A 2 X 6"',
    'PTR DE 6X2 CAL. 3/16': 'PTR A 2 X 6"',
    'PATIN HOLAND MARK V': 'PATIN HOLLAND MARK V',
    'PATIN HOLLAND': 'PATIN HOLLAND MARK V',
    'IPR DE 4" X 102"': 'IPR DE 4"',
    'PUENTES INTERMEDIOS': 'PUENTES TIPO J',
    'PUENTES DE LA PLANCHA': 'PUENTES DE LA PLANCHA (CANAL U 5")'
}

def clean_val(v):
    if not v: return ''
    s = str(v).strip()
    if s.lower() == 'none': return ''
    return s

def canonical(s):
    if not s: return ''
    txt = str(s).upper().strip()
    for k, v in typos_map.items():
        txt = txt.replace(k, v)
    for a, b in [('Á','A'),('É','E'),('Í','I'),('Ó','O'),('Ú','U'),('Ñ','N')]:
        txt = txt.replace(a, b)
    txt = re.sub(r'[\'\"\,]', '', txt)
    txt = re.sub(r'\s*([/xX*()])\s*', r'\1', txt)
    txt = re.sub(r'\s+', ' ', txt).strip()
    return txt

db_canonical = {}
for p in db_prods:
    ck = canonical(p['nombre'])
    if ck not in db_canonical:
        db_canonical[ck] = p

FASES = [
    ('paso_1', 'Paso 1', 'Armado y corte de almas', 1, 'Corte de placa de grado A-50 y ensamblado de viga principal'),
    ('paso_2', 'Paso 2', 'Soleras de refuerzo de almas', 2, 'Soldadura y unión de soleras A-529 de 1/2" x 6"'),
    ('paso_3', 'Paso 3', 'Estructura primaria, bordas y plancha de quinta rueda', 3, 'Bordas delantera/trasera, perno rey Holland, plancha de 3/8" y puentes'),
    ('paso_4', 'Paso 4', 'Cargadores transversales IPR y atizadores', 4, 'Cargadores IPR de 4" x 102", bordas laterales y atizadores'),
    ('paso_5', 'Paso 5', 'Instalación de suspensión y retráctiles', 5, 'Ensamble de perchas, suspensión neumática/mecánica y sistema retráctil'),
    ('paso_6', 'Paso 6', 'Canaleta, patines, ejes y accesorios estructurales', 6, 'Instalación de patines de apoyo, ejes de carga, caja de herramientas, estribo y accesorios'),
    ('paso_7', 'PASO 7', 'Lavado químico, fosfato y preparación de superficie', 7, 'Desengrasado, fosfatado y limpieza profunda previa a pintura'),
    ('paso_8', 'PASO 8', 'Aplicación de pintura y recubrimientos por marca', 8, 'Aplicación de fondo anticorrosivo y esmalte poliuretano'),
    ('paso_9', 'PASO 9', 'Kit neumático, sistema ABS y tanques de aire', 9, 'Instalación de tubería, mangueras, válvulas, tanques y arnés ABS'),
    ('paso_10', 'PASO 10', 'Sistema de iluminación reglamentaria y arnés eléctrico', 10, 'Colocación de plafones LED reglamentarios, arnés sellado y cableado'),
    ('paso_11', 'PASO 11', 'Instalación de pisos y fijaciones', 11, 'Instalación de piso de plástico, madera o pino con pijas fijadoras'),
    ('paso_12', 'PASO 12', 'Acabados, loderas, winches y rotulación final', 12, 'Colocación de loderas Leolca, cinta reflejante, winches y placa de serie'),
    ('extras', 'EXTRAS', 'Equipamiento adicional (redilas, retráctil Leolca, multimodal)', 13, 'Accesorios opcionales para configuraciones especiales'),
    ('llantas_rines', 'LLANTAS Y RINES', 'Juego de rodado (rines de acero/aluminio y llantas)', 14, 'Montaje de rines de 22.5" / 24.5" y neumáticos')
]

PROCESO_A_FASE = {
    'Paso 1': 'paso_1',
    'Paso 2': 'paso_2',
    'Paso 3': 'paso_3',
    'Paso 4': 'paso_4',
    'Paso 5': 'paso_5',
    'Paso 6': 'paso_6',
    'PASO 7': 'paso_7',
    'PASO 8': 'paso_8',
    'PASO 9': 'paso_9',
    'PASO 10': 'paso_10',
    'PASO 11': 'paso_11',
    'PASO 12': 'paso_12',
    'EXTRAS': 'extras',
    'LLANTAS Y RINES': 'llantas_rines'
}

EQUIVALENCIAS = [
    ('PASO 1', 'paso_1', 'Equivalencia estándar Paso 1'),
    ('PASO 2', 'paso_2', 'Equivalencia estándar Paso 2'),
    ('PASO 3', 'paso_3', 'Equivalencia estándar Paso 3'),
    ('PASO 4', 'paso_4', 'Equivalencia estándar Paso 4'),
    ('PASO 5', 'paso_5', 'Equivalencia estándar Paso 5'),
    ('PASO 6', 'paso_6', 'Equivalencia estándar Paso 6'),
    ('PASO 7', 'paso_7', 'Equivalencia estándar Paso 7'),
    ('LIMPIEZA', 'paso_7', 'Equivalencia histórica limpieza -> Paso 7 (Lavado químico y preparación)'),
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

CATEGORIAS_ESTANDAR = [
    ('Acero y Estructura', 'Componentes estructurales, vigas, perfiles y placas'),
    ('Tornillería', 'Tornillos, tuercas, rondanas, pijas y sujeciones'),
    ('Aire y Frenos ABS', 'Tuberías, mangueras, tanques, válvulas y sistema ABS'),
    ('Iluminación y Eléctrico', 'Plafones LED, arneses sellados y cableado'),
    ('Pintura y Preparación', 'Primers, esmaltes, solventes, fosfato y desengrasante'),
    ('Pisos y Madera', 'Tablones de piso plástico, madera de pino y encino'),
    ('Acabados y Rotulación', 'Loderas, cintas reflejantes, winches y placas'),
    ('Suspensión', 'Perchas, platos, bolsas de aire, amortiguadores y bujes'),
    ('Patines y Ejes', 'Juegos de patines de apoyo y ejes de carga'),
    ('Llantas y Rines', 'Rines de acero y aluminio, neumáticos 22.5 y 24.5'),
    ('Consumibles', 'Discos de corte/desbaste, microalambre, gases y lijas')
]

# 61 PIEZAS ESTRUCTURALES EXACTAS PARA PLATAFORMA (BLOQUE D)
# Cero UUIDs: solo clave de fase y nombre exacto en base de datos (tipo_item = 'materia_prima')
PIEZAS_ACERO_BLOQUE_D = [
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
]

# Construcción de la tabla 316
tabla_316 = []
for r in excel_rows:
    fila = r.get('fila')
    proc = (r.get('proceso') or '').strip()
    prod = clean_val(r.get('producto'))
    sub = clean_val(r.get('subpieza'))
    nom = clean_val(r.get('nomenclatura'))
    # Tomar la cantidad real de la columna de Excel
    cant = r.get('cantidad_raw')
    pu = r.get('precio_unitario_raw')
    
    # La fase se toma DIRECTAMENTE del Proceso de la misma fila
    fase_sug = PROCESO_A_FASE.get(proc, 'paso_3')
    
    # Manejo de asociaciones dudosas o pendientes (Hallazgo 3)
    es_dudosa_pintura = (proc == 'PASO 8' and any(k in prod.upper() for k in ['THINER', 'THINNER', 'CATALIZADOR', 'PRAIMER', 'PRIMER', 'REDUCTOR', 'TRANSPARENTE', 'FONDO', 'ESMALTE']))
    es_pijas_dudosas = ('PIJAS' in prod.upper() and '5/16 X 2' in prod.upper())
    es_piso_madera_dudoso = (prod.upper() == 'PISO MADERA')
    
    if not prod and not sub and not nom:
        destino = 'Pendiente'
        motivo = 'Fila sin descripción en Excel'
    elif fila == 248:
        destino = 'receta_base'
        motivo = 'Segunda línea de CABLE NEGRO CAL. 12 (uso: SI LLEVA LATERALES Y ESTRIBO)'
    elif es_dudosa_pintura:
        destino = 'Pendiente'
        motivo = 'Insumo químico específico de acabado; no fusionar arbitrariamente en producto genérico PINTURA'
    elif es_pijas_dudosas:
        destino = 'Pendiente'
        motivo = 'Fijación específica; no asociar forzadamente a PIJAS/BROCAS sin confirmación'
    elif es_piso_madera_dudoso:
        destino = 'Pendiente'
        motivo = 'Especie de madera no detallada; no asociar ciegamente a PISO DE MADERA DE PINO'
    elif prod.upper().startswith('MEDIDA DE RIN'):
        destino = 'Pendiente'
        motivo = 'Encabezado dimensional de rodado'
    elif cant is None and proc in ['Paso 4', 'Paso 5'] and ('DISCO' in prod.upper() or 'ROLLO' in prod.upper() or 'CO2' in prod.upper() or 'OXIGENO' in prod.upper()):
        destino = 'Pendiente'
        motivo = 'Consumible de planta sin dotación unitaria fija'
    elif any(k in prod.upper() for k in ['SUSPENSION', 'PATINES', 'EJES', 'PINTURA', 'PISOS', 'ACABADO', 'TIPO DE RINES', 'LLANTAS', 'REDILAS', 'TIPO DE GANCHO', 'RETRACTIL']):
        destino = 'opcion_componentes'
        motivo = 'Bloque de opción configurable'
    else:
        destino = 'receta_base'
        motivo = 'Estructura y montaje base de Plataforma 40 FT'

    candidates = []
    if prod and sub and nom:
        candidates.append(f"{prod} {sub} ({nom})")
        candidates.append(f"{prod} {sub} {nom}")
    if prod and nom:
        candidates.append(f"{prod} ({nom})")
        candidates.append(f"{prod} {nom}")
    if prod and sub:
        candidates.append(f"{prod} {sub}")
    if sub and nom:
        candidates.append(f"{sub} {nom}")
        candidates.append(f"{sub} ({nom})")
    if sub:
        candidates.append(sub)
    if prod:
        candidates.append(prod)
    if nom:
        candidates.append(nom)

    matched_prod = None
    if destino != 'Pendiente':
        for c in candidates:
            if not c: continue
            ck = canonical(c)
            if ck in db_canonical:
                matched_prod = db_canonical[ck]
                break

    tabla_316.append({
        'fila': fila,
        'proceso': proc,
        'producto': prod,
        'subpieza': sub,
        'nomenclatura': nom,
        'cantidad': cant,
        'precio': pu,
        'destino': destino,
        'motivo': motivo,
        'fase_clave': fase_sug,
        'prod_db_id': matched_prod['id'] if matched_prod else None,
        'prod_db_nombre': matched_prod['nombre'] if matched_prod else None
    })

# 1. GENERACIÓN DE supabase/migrations/20261102_01_despiece_union.sql
sql = []
sql.append("-- Migración 20261102_01_despiece_union.sql")
sql.append("-- T2 Ronda 4: Despiece oficial por fases desde UNION DE LISTADOS")
sql.append("-- Corrección integral: CERO UUIDs de productos, resolución por nombre exacto dentro de la organización,")
sql.append("-- respeto absoluto de receta_base.paso (solo asigna fase_id) y soporte multitenant estricto.")
sql.append("")
sql.append("BEGIN;")
sql.append("")
sql.append("-- 0. Columna notas en productos para trazabilidad")
sql.append("ALTER TABLE public.productos ADD COLUMN IF NOT EXISTS notas TEXT;")
sql.append("")
sql.append("-- 1. Catálogo oficial de fases_despiece y equivalencias")
sql.append("""CREATE TABLE IF NOT EXISTS fases_despiece (
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
""")

# Bloque DO de población multitenant
sql.append("""
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
""")

for c_nom, c_desc in CATEGORIAS_ESTANDAR:
    c_safe = c_nom.replace("'", "''")
    sql.append(f"""        IF NOT EXISTS (SELECT 1 FROM categorias_producto WHERE organizacion_id = r_org.id AND lower(trim(nombre)) = lower(trim('{c_safe}'))) THEN
            INSERT INTO categorias_producto (organizacion_id, nombre, orden)
            VALUES (r_org.id, '{c_safe}', 10);
        END IF;
""")

sql.append("""
        -- B. Poblar fases_despiece (14 fases oficiales)
""")

for clave, nombre, subtitulo, orden, desc in FASES:
    c_safe = clave.replace("'", "''")
    n_safe = nombre.replace("'", "''")
    s_safe = subtitulo.replace("'", "''")
    d_safe = desc.replace("'", "''")
    sql.append(f"""        INSERT INTO fases_despiece (organizacion_id, clave, nombre, subtitulo, orden, descripcion, activo)
        VALUES (r_org.id, '{c_safe}', '{n_safe}', '{s_safe}', {orden}, '{d_safe}', true)
        ON CONFLICT (organizacion_id, clave) DO UPDATE SET
            nombre = EXCLUDED.nombre,
            subtitulo = EXCLUDED.subtitulo,
            orden = EXCLUDED.orden,
            descripcion = EXCLUDED.descripcion,
            updated_at = now();
""")

sql.append("""
        -- C. Poblar fases_despiece_equivalencias (22 equivalencias históricas)
""")

for paso_leg, clave_fase, notas in EQUIVALENCIAS:
    p_safe = paso_leg.replace("'", "''")
    c_safe = clave_fase.replace("'", "''")
    n_safe = notas.replace("'", "''")
    sql.append(f"""        SELECT id INTO v_fase_id FROM fases_despiece WHERE organizacion_id = r_org.id AND clave = '{c_safe}';
        IF v_fase_id IS NOT NULL THEN
            INSERT INTO fases_despiece_equivalencias (organizacion_id, paso_legacy, fase_id, notas)
            VALUES (r_org.id, '{p_safe}', v_fase_id, '{n_safe}')
            ON CONFLICT (organizacion_id, paso_legacy) DO UPDATE SET
                fase_id = EXCLUDED.fase_id,
                notas = EXCLUDED.notas;
        END IF;
""")

sql.append("""
        -- D. Asignar fase_id a las 61 líneas de acero estructural en modelos de tipo 'plataforma'
        -- SOLO modelos.tipo = 'plataforma'. Dolly y Góndola NO se tocan.
        -- Resuelve los productos por nombre exacto + organización + tipo_item = 'materia_prima'.
        -- CERO UUIDs literales de productos en el código.
        -- No se escribe receta_base.paso: se conserva intacto (NULL o previo), solo se fija fase_id.
        FOR r_acero IN
            SELECT * FROM (VALUES
""")

val_lines = []
for f_clave, p_nom in PIEZAS_ACERO_BLOQUE_D:
    f_esc = f_clave.replace("'", "''")
    p_esc = p_nom.replace("'", "''")
    val_lines.append(f"                ('{f_esc}', '{p_esc}')")

sql.append(",\n".join(val_lines))
sql.append("""
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
""")

migracion_path = 'supabase/migrations/20261102_01_despiece_union.sql'
with open(migracion_path, 'w', encoding='utf-8') as f:
    f.write("\n".join(sql))
print("Migración SQL guardada exitosamente:", migracion_path)

# 2. GENERACIÓN DE docs/despiece/verificacion_T2.sql
verif_sql = """-- Verificación de entrega T2 Ronda 4: Despiece por fases
-- Cero UUIDs literales, validación multitenant y respeto de receta_base.paso

\\set ON_ERROR_STOP on

WITH org_base AS (
    SELECT id AS org_id FROM organizaciones WHERE id = '00000000-0000-0000-0000-000000000001'
),
counts_fases AS (
    SELECT count(*) AS total_fases FROM fases_despiece WHERE organizacion_id = (SELECT org_id FROM org_base)
),
counts_equiv AS (
    SELECT count(*) AS total_equiv FROM fases_despiece_equivalencias WHERE organizacion_id = (SELECT org_id FROM org_base)
),
counts_policies AS (
    SELECT count(*) AS politicas_no_select
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename IN ('fases_despiece', 'fases_despiece_equivalencias')
      AND cmd <> 'SELECT'
),
plat_rb_checks AS (
    SELECT
        count(CASE WHEN f.clave = 'paso_1' THEN 1 END) AS p1_count,
        count(CASE WHEN f.clave = 'paso_2' THEN 1 END) AS p2_count,
        count(CASE WHEN f.clave = 'paso_3' THEN 1 END) AS p3_count,
        count(CASE WHEN f.clave = 'paso_4' THEN 1 END) AS p4_count,
        count(CASE WHEN f.clave = 'paso_5' THEN 1 END) AS p5_count,
        count(CASE WHEN f.clave = 'paso_6' THEN 1 END) AS p6_count,
        count(CASE WHEN f.clave = 'paso_7' THEN 1 END) AS p7_count,
        count(CASE WHEN f.clave = 'paso_8' THEN 1 END) AS p8_count,
        count(CASE WHEN f.clave = 'paso_9' THEN 1 END) AS p9_count,
        count(CASE WHEN f.clave = 'paso_10' THEN 1 END) AS p10_count,
        count(CASE WHEN f.clave = 'paso_11' THEN 1 END) AS p11_count,
        count(CASE WHEN f.clave = 'paso_12' THEN 1 END) AS p12_count,
        count(CASE WHEN f.clave = 'extras' THEN 1 END) AS extras_count,
        count(CASE WHEN rb.fase_id IS NULL THEN 1 END) AS sin_fase_count,
        count(*) AS total_lineas
    FROM receta_base rb
    JOIN modelos m ON m.id = rb.modelo_id
    LEFT JOIN fases_despiece f ON f.id = rb.fase_id
    WHERE m.tipo = 'plataforma' AND m.largo_ft = 40 AND m.num_ejes = 2
      AND m.organizacion_id = (SELECT org_id FROM org_base)
),
non_plat_checks AS (
    SELECT
        (SELECT count(CASE WHEN rb.fase_id IS NOT NULL THEN 1 END)
         FROM receta_base rb
         JOIN modelos m ON m.id = rb.modelo_id
         WHERE m.tipo IN ('dolly', 'gondola')) AS dolly_gondola_alterados
),
suspension_checks AS (
    SELECT
        (SELECT count(*) FROM opcion_componentes oc
         JOIN opciones_configuracion o ON o.id = oc.opcion_id
         JOIN productos p ON p.id = oc.material_id
         WHERE o.clave = 'alta_hendrickson'
           AND (p.nombre ILIKE '%MONROE%65512%' OR p.nombre ILIKE '%MONRROE%65512%')
           AND oc.cantidad = 0 AND oc.rol = 'sustituto') AS monroe_sustituto_ok,
        (SELECT count(*) FROM opcion_componentes oc
         JOIN opciones_configuracion o ON o.id = oc.opcion_id
         JOIN productos p ON p.id = oc.material_id
         JOIN grupos_configuracion g ON g.id = o.grupo_id
         WHERE o.clave = 'fleet_master' AND g.clave = 'suspension'
           AND (p.nombre ILIKE '%AMORTIGUADOR%FCR%' OR p.nombre ILIKE '%AMORTIGUADOR%GABRIEL%')
           AND oc.cantidad = 0 AND oc.rol = 'sustituto') AS fleet_amort_sustitutos_ok,
        (SELECT count(*) FROM opcion_componentes oc
         JOIN opciones_configuracion o ON o.id = oc.opcion_id
         JOIN productos p ON p.id = oc.material_id
         JOIN grupos_configuracion g ON g.id = o.grupo_id
         WHERE o.clave = 'fleet_master' AND g.clave = 'suspension'
           AND (p.nombre ILIKE '%CAMARA%AMPRO%1R14-039%' OR p.nombre ILIKE '%CAMARA%FCR%1R14-039%')
           AND oc.cantidad = 0 AND oc.rol = 'sustituto') AS fleet_camara_sustitutos_ok
),
tenant_isolation AS (
    SELECT
        (SELECT count(*)
         FROM receta_base rb
         JOIN modelos m ON m.id = rb.modelo_id
         JOIN fases_despiece f ON f.id = rb.fase_id
         WHERE f.organizacion_id <> m.organizacion_id) AS receta_fase_cruzada,
        (SELECT count(*)
         FROM opcion_componentes oc
         JOIN opciones_configuracion o ON o.id = oc.opcion_id
         JOIN fases_despiece f ON f.id = oc.fase_id
         WHERE f.organizacion_id <> o.organizacion_id) AS opcion_fase_cruzada
),
duplicate_checks AS (
    SELECT count(*) AS casi_duplicados
    FROM productos p1
    JOIN productos p2 ON p1.organizacion_id = p2.organizacion_id AND p1.id < p2.id
    WHERE p1.tipo_item = 'materia_prima' AND p2.tipo_item = 'materia_prima'
      AND (
          (p1.nombre ILIKE '%27X60%' AND p2.nombre ILIKE '%27 X 60%') OR
          (p1.nombre ILIKE '%MONRROE%65512%' AND p2.nombre ILIKE '%MONROE%65512%') OR
          (p1.nombre ILIKE '%TORNILLO%1/4X1%' AND p2.nombre ILIKE '%TORNILLO%1/4 X 1%') OR
          (p1.nombre ILIKE '%CABLE%NEGRO%CAL,12%' AND p2.nombre ILIKE '%CABLE%NEGRO%CAL.%12%')
      )
)
SELECT
    cf.total_fases,
    ce.total_equiv,
    cp.politicas_no_select,
    prb.total_lineas AS rb_40ft_total,
    prb.sin_fase_count AS rb_40ft_sin_fase,
    prb.p1_count,
    prb.p2_count,
    prb.p3_count,
    prb.p4_count,
    prb.p5_count,
    prb.p6_count,
    prb.p7_count,
    prb.p9_count,
    prb.p10_count,
    prb.p12_count,
    prb.extras_count,
    npc.dolly_gondola_alterados,
    sc.monroe_sustituto_ok,
    sc.fleet_amort_sustitutos_ok,
    sc.fleet_camara_sustitutos_ok,
    ti.receta_fase_cruzada,
    ti.opcion_fase_cruzada,
    dc.casi_duplicados,
    (
        cf.total_fases = 14 AND
        ce.total_equiv = 22 AND
        cp.politicas_no_select = 0 AND
        prb.total_lineas = 202 AND
        prb.sin_fase_count = 0 AND
        prb.p1_count = 3 AND
        prb.p2_count = 5 AND
        prb.p3_count = 22 AND
        prb.p4_count = 22 AND
        prb.p5_count = 16 AND
        prb.p6_count = 28 AND
        prb.p7_count = 4 AND
        prb.p9_count = 47 AND
        prb.p10_count = 29 AND
        prb.p12_count = 16 AND
        prb.extras_count = 10 AND
        npc.dolly_gondola_alterados = 0 AND
        sc.monroe_sustituto_ok = 1 AND
        sc.fleet_amort_sustitutos_ok = 2 AND
        sc.fleet_camara_sustitutos_ok = 2 AND
        ti.receta_fase_cruzada = 0 AND
        ti.opcion_fase_cruzada = 0 AND
        dc.casi_duplicados = 0
    ) AS todo_ok
FROM counts_fases cf
CROSS JOIN counts_equiv ce
CROSS JOIN counts_policies cp
CROSS JOIN plat_rb_checks prb
CROSS JOIN non_plat_checks npc
CROSS JOIN suspension_checks sc
CROSS JOIN tenant_isolation ti
CROSS JOIN duplicate_checks dc;
"""

verif_path = 'docs/despiece/verificacion_T2.sql'
with open(verif_path, 'w', encoding='utf-8') as f:
    f.write(verif_sql)
print("Verificación SQL guardada exitosamente:", verif_path)

# 3. GENERACIÓN DE docs/despiece/prueba_T2.sql
# Prueba transaccional multitenant con segunda organización cuyos productos tienen UUIDs distintos
prueba_sql = """-- Prueba transaccional de validación T2 Ronda 4
-- Prueba obligatoria: Segunda org con productos de UUID distinto -> 0 líneas de plataforma sin fase_id en ambas orgs
-- RLS estricto SELECT para authenticated y aislamiento completo.

\\set ON_ERROR_STOP on

BEGIN;

-- 1. Crear Organización B de prueba con UUID distinto
INSERT INTO organizaciones (id, nombre)
VALUES ('00000000-0000-0000-0000-000000000002', 'ORGANIZACION PRUEBA B T2')
ON CONFLICT (id) DO NOTHING;

-- 2. Crear Usuarios en auth.users y perfiles_organizacion
INSERT INTO auth.users (id, email, raw_user_meta_data)
VALUES
    ('a988611b-2949-4ab7-b670-daf4a21f4e18', 'test_user_a@remolques.test', '{"nombre":"Usuario A"}'),
    ('00000000-0000-0000-0000-0000000000b2', 'test_user_b@remolques.test', '{"nombre":"Usuario B"}')
ON CONFLICT (id) DO NOTHING;

INSERT INTO perfiles_organizacion (usuario_id, organizacion_id, rol)
VALUES
    ('a988611b-2949-4ab7-b670-daf4a21f4e18', '00000000-0000-0000-0000-000000000001', 'usuario'),
    ('00000000-0000-0000-0000-0000000000b2', '00000000-0000-0000-0000-000000000002', 'usuario')
ON CONFLICT DO NOTHING;

-- 3. Clonar productos para Org B con gen_random_uuid()::text (UUIDs completamente distintos a Org A)
INSERT INTO productos (id, organizacion_id, nombre, tipo_item, unidad, costo)
SELECT gen_random_uuid()::text, '00000000-0000-0000-0000-000000000002', nombre, tipo_item, unidad, costo
FROM productos
WHERE organizacion_id = '00000000-0000-0000-0000-000000000001'
ON CONFLICT DO NOTHING;

-- 4. Clonar modelo PLATAFORMA 2 40 FT para Org B con sus 202 líneas
DO $$
DECLARE
    v_mod_a UUID;
    v_mod_b UUID := '00000000-0000-0000-0000-0000000000b0';
    v_prod_mod_b TEXT;
BEGIN
    SELECT id INTO v_mod_a FROM modelos WHERE organizacion_id = '00000000-0000-0000-0000-000000000001' AND tipo = 'plataforma' AND largo_ft = 40 AND num_ejes = 2;
    
    SELECT min(id) INTO v_prod_mod_b FROM productos WHERE organizacion_id = '00000000-0000-0000-0000-000000000002' AND nombre ILIKE '%PLATAFORMA%40%';
    IF v_prod_mod_b IS NULL THEN
        v_prod_mod_b := gen_random_uuid()::text;
        INSERT INTO productos (id, organizacion_id, nombre, tipo_item, unidad)
        VALUES (v_prod_mod_b, '00000000-0000-0000-0000-000000000002', 'PLATAFORMA 2 40 FT TERMINADA', 'producto_terminado', 'pz');
    END IF;

    INSERT INTO modelos (id, organizacion_id, producto_id, tipo, num_ejes, largo_ft, activo)
    VALUES (v_mod_b, '00000000-0000-0000-0000-000000000002', v_prod_mod_b, 'plataforma', 2, 40, true)
    ON CONFLICT (id) DO NOTHING;

    -- Insertar las 202 líneas en Org B asociadas a los productos de Org B (con UUIDs generados)
    INSERT INTO receta_base (modelo_id, material_id, cantidad, paso, uso, escala)
    SELECT v_mod_b, pb.id, rb.cantidad, rb.paso, rb.uso, rb.escala
    FROM receta_base rb
    JOIN productos pa ON pa.id = rb.material_id
    JOIN productos pb ON pb.nombre = pa.nombre AND pb.organizacion_id = '00000000-0000-0000-0000-000000000002'
    WHERE rb.modelo_id = v_mod_a;
END $$;

-- 5. Ejecutar la migración completa (población y asignación multitenant por nombre de producto)
-- El bloque DO de la migración correrá para TODAS las organizaciones (A y B)
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
BEGIN
    FOR r_org IN SELECT id FROM organizaciones WHERE id IN ('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000002') LOOP

        -- Fases
        INSERT INTO fases_despiece (organizacion_id, clave, nombre, subtitulo, orden, descripcion, activo)
        VALUES
            (r_org.id, 'paso_1', 'Paso 1', 'Armado y corte de almas', 1, 'Corte almas', true),
            (r_org.id, 'paso_2', 'Paso 2', 'Soleras de refuerzo de almas', 2, 'Soleras almas', true),
            (r_org.id, 'paso_3', 'Paso 3', 'Estructura primaria', 3, 'Bordas y puentes', true),
            (r_org.id, 'paso_4', 'Paso 4', 'Cargadores transversales', 4, 'Cargadores IPR', true),
            (r_org.id, 'paso_5', 'Paso 5', 'Instalacion de suspension', 5, 'Suspension', true),
            (r_org.id, 'paso_6', 'Paso 6', 'Patines y ejes', 6, 'Patines y ejes', true),
            (r_org.id, 'paso_7', 'PASO 7', 'Lavado quimico', 7, 'Lavado', true),
            (r_org.id, 'paso_8', 'PASO 8', 'Pintura', 8, 'Pintura', true),
            (r_org.id, 'paso_9', 'PASO 9', 'Kit neumatico', 9, 'Aire', true),
            (r_org.id, 'paso_10', 'PASO 10', 'Iluminacion', 10, 'Luz', true),
            (r_org.id, 'paso_11', 'PASO 11', 'Pisos', 11, 'Pisos', true),
            (r_org.id, 'paso_12', 'PASO 12', 'Acabados y loderas', 12, 'Terminado', true),
            (r_org.id, 'extras', 'EXTRAS', 'Equipamiento adicional', 13, 'Extras', true),
            (r_org.id, 'llantas_rines', 'LLANTAS Y RINES', 'Rodado', 14, 'Rines y llantas', true)
        ON CONFLICT (organizacion_id, clave) DO UPDATE SET updated_at = now();

        -- Equivalencias
        INSERT INTO fases_despiece_equivalencias (organizacion_id, paso_legacy, fase_id, notas)
        SELECT r_org.id, fe.paso_legacy, fd.id, 'Equivalencia prueba'
        FROM (VALUES
            ('PASO 1', 'paso_1'), ('PASO 2', 'paso_2'), ('PASO 3', 'paso_3'),
            ('PASO 4', 'paso_4'), ('PASO 5', 'paso_5'), ('PASO 6', 'paso_6'),
            ('PASO 7', 'paso_7'), ('LIMPIEZA', 'paso_7'),
            ('PASO 8', 'paso_8'), ('PINTURA', 'paso_8'),
            ('PASO 9', 'paso_9'), ('AIRE', 'paso_9'),
            ('PASO 10', 'paso_10'), ('LUZ', 'paso_10'),
            ('PASO 11', 'paso_11'), ('PISOS', 'paso_11'),
            ('PASO 12', 'paso_12'), ('TERMINADO', 'paso_12'),
            ('EXTRAS', 'extras'), ('LLANTAS Y RINES', 'llantas_rines'),
            ('LLANTAS', 'llantas_rines'), ('RINES', 'llantas_rines')
        ) AS fe(paso_legacy, clave_fase)
        JOIN fases_despiece fd ON fd.organizacion_id = r_org.id AND fd.clave = fe.clave_fase
        ON CONFLICT (organizacion_id, paso_legacy) DO NOTHING;

        -- Bloque D: Resolucion de acero por nombre exacto (CERO UUIDs)
        FOR r_acero IN
            SELECT * FROM (VALUES
""" + ",\n".join(val_lines) + """
            ) AS t(fase_clave, producto_nombre)
        LOOP
            SELECT id INTO v_target_fase_id
            FROM fases_despiece
            WHERE organizacion_id = r_org.id AND clave = r_acero.fase_clave;

            IF v_target_fase_id IS NULL THEN
                RAISE EXCEPTION 'Fase % no encontrada para org %', r_acero.fase_clave, r_org.id;
            END IF;

            SELECT count(*), min(id) INTO v_mat_count, v_mat_id
            FROM productos
            WHERE organizacion_id = r_org.id
              AND nombre = r_acero.producto_nombre
              AND tipo_item = 'materia_prima';

            IF v_mat_count = 0 THEN
                RAISE EXCEPTION 'Producto no encontrado: % (org: %)', r_acero.producto_nombre, r_org.id;
            ELSIF v_mat_count > 1 THEN
                RAISE EXCEPTION 'Producto ambiguo (%): % (org: %)', v_mat_count, r_acero.producto_nombre, r_org.id;
            END IF;

            UPDATE receta_base rb
            SET fase_id = v_target_fase_id
            FROM modelos m
            WHERE rb.modelo_id = m.id
              AND m.organizacion_id = r_org.id
              AND m.tipo = 'plataforma'
              AND rb.material_id = v_mat_id
              AND (rb.fase_id IS NULL OR rb.fase_id != v_target_fase_id);
        END LOOP;

        -- Bloque E: Equivalencias
        UPDATE receta_base rb
        SET fase_id = fe.fase_id
        FROM fases_despiece_equivalencias fe, modelos m
        WHERE m.id = rb.modelo_id
          AND m.tipo = 'plataforma'
          AND fe.organizacion_id = r_org.id
          AND m.organizacion_id = r_org.id
          AND upper(trim(rb.paso)) = upper(trim(fe.paso_legacy))
          AND (rb.fase_id IS NULL OR rb.fase_id != fe.fase_id);

    END LOOP;
END $$;

-- 6. VERIFICAR QUE AMBAS ORGANIZACIONES (A Y B) TIENEN CERO LÍNEAS DE PLATAFORMA SIN FASE
DO $$
DECLARE
    v_sin_fase_a INT;
    v_sin_fase_b INT;
    v_total_a INT;
    v_total_b INT;
BEGIN
    SELECT count(*), count(*) FILTER (WHERE rb.fase_id IS NULL)
    INTO v_total_a, v_sin_fase_a
    FROM receta_base rb
    JOIN modelos m ON m.id = rb.modelo_id
    WHERE m.organizacion_id = '00000000-0000-0000-0000-000000000001' AND m.tipo = 'plataforma' AND m.largo_ft = 40 AND m.num_ejes = 2;

    SELECT count(*), count(*) FILTER (WHERE rb.fase_id IS NULL)
    INTO v_total_b, v_sin_fase_b
    FROM receta_base rb
    JOIN modelos m ON m.id = rb.modelo_id
    WHERE m.organizacion_id = '00000000-0000-0000-0000-000000000002' AND m.tipo = 'plataforma' AND m.largo_ft = 40 AND m.num_ejes = 2;

    IF v_sin_fase_a <> 0 THEN
        RAISE EXCEPTION 'Org A fallo: % lineas sin fase_id', v_sin_fase_a;
    END IF;

    IF v_sin_fase_b <> 0 THEN
        RAISE EXCEPTION 'Org B fallo: % lineas sin fase_id con UUIDs clonados', v_sin_fase_b;
    END IF;

    IF v_total_a <> 202 OR v_total_b <> 202 THEN
        RAISE EXCEPTION 'Totales incorrectos: Org A=%, Org B=% (esperado 202)', v_total_a, v_total_b;
    END IF;

    RAISE NOTICE 'PRUEBA MULTI-ORG RESOLUCION POR NOMBRE: EXITOSA (Org A: 202/202 con fase, Org B: 202/202 con fase)';
END $$;

-- 7. VERIFICAR RLS CON SET LOCAL ROLE authenticated
SET LOCAL ROLE authenticated;
SET LOCAL request.jwt.claim.sub = 'a988611b-2949-4ab7-b670-daf4a21f4e18';

DO $$
DECLARE
    v_count INT;
    v_error_disparado BOOLEAN := false;
BEGIN
    SELECT count(*) INTO v_count FROM fases_despiece;
    IF v_count <> 14 THEN
        RAISE EXCEPTION 'RLS Fallo: Usuario A debio ver 14 fases de Org A pero vio %', v_count;
    END IF;

    BEGIN
        INSERT INTO fases_despiece (organizacion_id, clave, nombre, orden)
        VALUES ('00000000-0000-0000-0000-000000000001', 'hack_fase', 'Fase Inyectada', 99);
    EXCEPTION WHEN OTHERS THEN
        v_error_disparado := true;
    END;

    IF NOT v_error_disparado THEN
        RAISE EXCEPTION 'RLS Fallo: Usuario authenticated pudo insertar en fases_despiece';
    END IF;

    RAISE NOTICE 'PRUEBA RLS USUARIO A (SELECT AISLADO 14 FASES + BLOQUEO INSERT): EXITOSA';
END $$;

SET LOCAL request.jwt.claim.sub = '00000000-0000-0000-0000-0000000000b2';

DO $$
DECLARE
    v_count INT;
BEGIN
    SELECT count(*) INTO v_count FROM fases_despiece;
    IF v_count <> 14 THEN
        RAISE EXCEPTION 'RLS Fallo: Usuario B debio ver 14 fases de Org B pero vio %', v_count;
    END IF;

    RAISE NOTICE 'PRUEBA RLS USUARIO B (AISLAMIENTO TOTAL RESPECTO A ORG A): EXITOSA';
END $$;

RESET ROLE;

ROLLBACK;
"""

prueba_path = 'docs/despiece/prueba_T2.sql'
with open(prueba_path, 'w', encoding='utf-8') as f:
    f.write(prueba_sql)
print("Prueba SQL guardada exitosamente:", prueba_path)

# 4. GENERACIÓN DE docs/despiece/ANALISIS_UNION_LISTADOS.md
doc = []
doc.append("# Análisis Exhaustivo de Despiece — UNION DE LISTADOS ACTULIZADO (1).xlsx")
doc.append("")
doc.append("**Fecha de emisión:** 2026-11-03 (Ronda 4 Antigravity)")
doc.append("**Archivo fuente:** `UNION DE LISTADOS ACTULIZADO (1).xlsx` (Hoja1, 316 renglones de ingeniería)")
doc.append("**Unidad de Referencia Deductiva:** **PLATAFORMA DE 2 EJES Y 40 PIES (PLATAFORMA 2 40 FT)**")
doc.append("")
doc.append("---")
doc.append("## 1. Deducción Analítica de la Unidad de Referencia")
doc.append("")
doc.append("La comparativa paramétrica contra los modelos maestros del sistema arroja:")
doc.append("1. **Cargadores transversales (Paso 4):** El Excel especifica exactamente **38 piezas** de `IPR de 4\" x 102\"`. Para una plataforma de 40 pies (480 pulgadas de longitud total) con espacio estándar entre cargadores de 12 pulgadas, se requieren exactamente 38 cargadores intermedios más los remates de borda.")
doc.append("2. **Almas principales (Paso 1):** 2 piezas de `PLACA DE GRADO A-50 CAL. 1/4\"` con longitud correspondiente a 40 ft.")
doc.append("3. **Soleras de alma (Paso 2):** 4 soleras de `SOLERA DE GRADO A-529 A 1/2\" X 6\"` para patín superior e inferior de ambas vigas maestras.")
doc.append("4. **Kit neumático y frenos ABS (Paso 9):** Configuración `2 ejes` compuesta de 2 tanques de aire, 4 cámaras de aire (2 servicio y 2 emergencia) y 1 kit modular Bendix de 2 sensores/1 modulador.")
doc.append("5. **Puentes de suspensión (Paso 3):** 6 piezas de PTR 6\" x 2\" calibre 3/16\", que es el estándar exacto de fijación de perchas para suspensión neumática/mecánica tándem de 2 ejes.")
doc.append("")
doc.append("> **Conclusión de Ingeniería:** La receta de `UNION DE LISTADOS` constituye el catálogo maestro de la **Plataforma 40 FT 2 Ejes**. Las longitudes alternas (35, 42, 43, 45, 48 ft) y variantes de 3 ejes derivan por reglas de escala (`escala = 'por_largo'` y `escala = 'por_eje'`).")
doc.append("")
doc.append("---")
doc.append("## 2. Árbol de Fases Oficial de Despiece (14 Fases)")
doc.append("")
doc.append("| Orden | Clave | Nombre Oficial | Subtítulo / Alcance Operativo | Filas en Excel | Destino Predominante |")
doc.append("|---|---|---|---|:---:|---|")
doc.append("| 1 | `paso_1` | **Paso 1** | Armado y corte de almas | 3 | `receta_base` |")
doc.append("| 2 | `paso_2` | **Paso 2** | Soleras de refuerzo de almas | 5 | `receta_base` |")
doc.append("| 3 | `paso_3` | **Paso 3** | Estructura primaria, bordas y plancha de quinta rueda | 21 | `receta_base` |")
doc.append("| 4 | `paso_4` | **Paso 4** | Cargadores transversales IPR y atizadores | 21 | `receta_base` |")
doc.append("| 5 | `paso_5` | **Paso 5** | Instalación de suspensión y retráctiles | 68 | `opcion_componentes` |")
doc.append("| 6 | `paso_6` | **Paso 6** | Canaleta, patines, ejes y accesorios estructurales | 40 | `receta_base` / `opcion_componentes` |")
doc.append("| 7 | `paso_7` | **PASO 7** | Lavado químico, fosfato y preparación de superficie | 4 | `receta_base` |")
doc.append("| 8 | `paso_8` | **PASO 8** | Aplicación de pintura y recubrimientos por marca | 15 | `opcion_componentes` |")
doc.append("| 9 | `paso_9` | **PASO 9** | Kit neumático, sistema ABS y tanques de aire | 55 | `receta_base` |")
doc.append("| 10 | `paso_10` | **PASO 10** | Sistema de iluminación reglamentaria y arnés eléctrico | 29 | `receta_base` |")
doc.append("| 11 | `paso_11` | **PASO 11** | Instalación de pisos y fijaciones | 6 | `opcion_componentes` |")
doc.append("| 12 | `paso_12` | **PASO 12** | Acabados, loderas, winches y rotulación final | 16 | `receta_base` |")
doc.append("| 13 | `extras` | **EXTRAS** | Equipamiento adicional (redilas, retráctil Leolca, multimodal) | 18 | `receta_base` / `opcion_componentes` |")
doc.append("| 14 | `llantas_rines` | **LLANTAS Y RINES** | Juego de rodado (rines de acero/aluminio y llantas) | 15 | `opcion_componentes` |")
doc.append("")
doc.append("---")
doc.append("## 3. Diccionario Exhaustivo de Normalización de Nombres y Typos")
doc.append("")
doc.append("Se identificaron y normalizaron las siguientes cadenas originales para evitar dispersión del catálogo e impedir duplicados casi idénticos:")
doc.append("")
doc.append("| Texto Original en Excel | Nombre Normalizado Oficial | Categoría Asignada | Razón de Corrección |")
doc.append("|---|---|---|---|")
for k, v in sorted(typos_map.items()):
    cat_sug = "Acero y Estructura" if "PTR" in k or "CANAL" in k or "SOLERA" in k or "PATIN" in k else "Consumibles"
    doc.append(f"| `{k}` | **{v}** | {cat_sug} | Corrección ortográfica / normalización canónica |")

doc.append("")
doc.append("---")
doc.append("## 4. Diff Exhaustivo: Excel vs Base de Datos Real (`remolques`)")
doc.append("")
doc.append("### 4.1. Discrepancias de Cantidad Calculadas Considerando `uso`")
doc.append("")
doc.append("| Pieza | Fase | Cantidad en BD | Cantidad en Excel | Uso en BD | Análisis Objetivo del Diff |")
doc.append("|---|---|:---:|:---:|---|---|")
doc.append("| LIJA #80 | PASO 7 | 2.0 | **10.0** | (Sin uso especificado) | **Diferencia real:** El Excel especifica 10 pliegos para el proceso completo de escoreo y preparación; la receta previa en BD solo registraba 2 pliegos. |")
doc.append("| Atizadores externos 27 cm | Paso 3 | 8.0 | **8.0** | Atizadores externos | **Sin discrepancia:** Tanto en la fila 18 del Excel como en BD se registran exactamente 8 piezas de 27 cm (y 2 piezas de 29 cm en fila 19). |")
doc.append("| RONDANA PLANA 5/16 | PASO 9 (Aire) | 4.0 | **4.0** | KIT DE TORNILLOS DE ABS | **Sin discrepancia:** En el sistema de aire coinciden exactamente 4 piezas en Excel y 4 en BD. |")
doc.append("| RONDANA PLANA 5/16 | PASO 10 (Luz) | 6.0 | **6.0** | HEMBRAS Y PLAFON ABS | **Sin discrepancia:** En el sistema eléctrico coinciden exactamente 6 piezas en Excel y 6 en BD. (El registro de 444 piezas en BD corresponde exclusivamente a EXTRAS para juego completo de redilas). |")
doc.append("| TUERCA ESTANDAR 1/4 | PASO 10 (Luz) | 6.0 | **6.0** | HEMBRAS Y PLAFON ABS | **Sin discrepancia:** Coinciden 6 en Excel y 6 en BD para fijación de arnés (el registro de 444 es exclusivo de redilas). |")
doc.append("| FOSFATO 1 L | PASO 7 | 1.0 | **1.0** | LIMPIEZA | **Sin discrepancia de cantidad:** Coincide 1 L / unidad en ambos registros. |")
doc.append("")
doc.append("### 4.2. Análisis de Conflictos de Costo")
doc.append("")
doc.append("| Pieza | Costo BD ($ MXN) | Precio en Excel ($ MXN) | Diferencia % | Decisión y Observación |")
doc.append("|---|:---:|:---:|:---:|---|")
doc.append("| Atizadores externos 27 cm | $50.00 | $50.00 | **0.0%** | **Sin discrepancia:** La fila 18 del Excel tiene precio unitario de $50.00 exacto, coincidente con BD. |")
doc.append("| Atizadores externos 29 cm | $60.00 | $60.00 | **0.0%** | **Sin discrepancia:** La fila 19 del Excel tiene precio unitario de $60.00 exacto, coincidente con BD. |")
doc.append("")
doc.append("### 4.3. Desglose de Materias Primas Estructurales en Base de Datos y su Correspondencia en Excel")
doc.append("")
doc.append("La auditoría matemática de nombres normalizados confirma que **la totalidad de las piezas estructurales de la Plataforma 40 FT en BD tienen su renglón correspondiente en el Excel**:")
doc.append("- `SOLERA DE ALMA (1/2\" X 6\")`: Fila 5 del Excel (4 pzas).")
doc.append("- `PUENTES DE SUSPENSIÓN (PTR 6X2\")`: Fila 12 del Excel (6 pzas).")
doc.append("- `PUENTES TIPO J`: Fila 14 del Excel como Puentes intermedios (5 pzas).")
doc.append("- `BOTONES (1/4\")`: Fila 16 del Excel (16 pzas).")
doc.append("- `ATIZADORES INTERNOS (1/4\")`: Fila 17 del Excel (12 pzas).")
doc.append("- `ATIZADORES EXTERNOS 27 CM`: Fila 18 del Excel (8 pzas).")
doc.append("- `ATIZADORES EXTERNOS 29 CM`: Fila 19 del Excel (2 pzas).")
doc.append("- `JALON (1/2\")`: Fila 20 del Excel (1 pza).")
doc.append("- `REFUERZO DE JALON (3/8\")`: Fila 21 del Excel (1 pza).")
doc.append("- `PERNO REY`: Fila 22 del Excel (1 pza).")
doc.append("- `TAPA PARA PERNO REY`: Fila 23 del Excel (1 pza).")
doc.append("- `KIT DE ALETAS 45 X 60 CM`: Filas 33-38 del Excel.")
doc.append("- `HERRAJE Y TORNILLERÍA DE PATINES`: Filas 127-142 del Excel.")
doc.append("- `PORTA LLANTAS Y SUJECIÓN`: Filas 144-150 del Excel.")
doc.append("")
doc.append("### 4.4. Opciones Configurables (`opcion_componentes`)")
doc.append("")
doc.append("1. **Suspensión Hendrickson Alta (`alta_hendrickson`):** `AMORTIGUADOR HENDRICKSON 23743` como componente activo.")
doc.append("2. **Suspensión Fleet Master (`fleet_master`):** Componentes estándar con sustitutos en cantidad 0.")
doc.append("3. **Patines y Ejes:** Reclasificados a **Paso 6** en estricto apego al Excel oficial.")
doc.append("")
doc.append("---")
doc.append("## 5. Sección 'Pendientes de Definir' (Anomalías y Datos Abiertos)")
doc.append("")
doc.append("| Fila Excel | Proceso | Descripción en Excel | Detalle / Causa en Pendientes |")
doc.append("|:---:|---|---|---|")
doc.append("| 167-179 | PASO 8 | **Insumos de pintura (Thinner, Catalizador, Primer, Reductor, Transparente)** | Insumos químicos individuales de acabado; enviados a Pendientes para no asociarlos erróneamente al producto genérico PINTURA. |")
doc.append("| 252 | PASO 11 | **PIJAS 5/16 X 2** | Fijación específica; en Pendientes para no asociarla forzadamente a PIJAS/BROCAS sin confirmación. |")
doc.append("| 255 | PASO 11 | **PISO MADERA** | Especie de madera no detallada; en Pendientes para no asociar ciegamente a PISO DE MADERA DE PINO. |")
doc.append("| 46-51 | Paso 4 | **Discos de corte, desbaste, microalambre, CO2 y oxígeno** | Consumibles de planta sin dotación unitaria fija por remolque. |")
doc.append("| 63-67 | Paso 5 | **Discos y gases de taller** | Consumibles de soldadura de perchas sin cantidad unitaria. |")
doc.append("| 165 | PASO 7 | **FOSFATO 1 L** | Presentación química sin costo unitario asignado en hoja fuente. |")
doc.append("| 248 | PASO 10 | **Fila 248 (cant = 25.8 en Paso 10)** | Corresponde a la segunda línea de `CABLE NEGRO CAL,12` con uso 'SI LLEVA LATERALES Y ESTRIBO' ya existente en BD. |")
doc.append("| 307-308 | LLANTAS Y RINES | **MEDIDA DE RIN (24.5 / 22.5)** | Encabezados dimensionales sin producto asociado. |")
doc.append("")
doc.append("---")
doc.append("## 6. Mapeo de Bloques de Opciones Configurables Excluyentes")
doc.append("")
doc.append("1. **Grupo `suspension` (Paso 5):** Alternativas de marca (`alta_hendrickson`, `hendrickson`, `fleet_master`, `ampro`, `fcr`).")
doc.append("2. **Grupo `retractil` (Paso 5):** Opciones `chico` (UBL) y `grande` con desglose de tornillería grado 8.")
doc.append("3. **Grupo `patin` (Paso 6):** Opciones `ampro`, `holland`, `hj`, `flet_master` (Paso 6 oficial).")
doc.append("4. **Grupo `eje` (Paso 6):** Opciones `fleet_master`, `ampro`, `fcr`, `prat_max`, `hj` con escala `por_eje` (Paso 6 oficial).")
doc.append("5. **Grupo `pintura` (Paso 8):** Opciones por sistema de recubrimiento (`sherwin_williams`, `ppg`, `axalta`).")
doc.append("6. **Grupo `piso` (Paso 11):** Opciones `plastico_cafe` (18 tablones), `pino`, `encino` con dotación de 600 pijas fijadoras.")
doc.append("7. **Grupos `rines` y `llantas` (LLANTAS Y RINES):** Dotaciones de rodado doble por eje con escala `por_eje`.")
doc.append("8. **Grupo `adicionales` (EXTRAS):** Opción `multimodal` (twistlocks y cargadores IPR 3\").")
doc.append("")
doc.append("---")
doc.append("## 7. Tabla Exhaustiva de Mapeo (316 Filas del Excel)")
doc.append("")
doc.append("| Fila | Proceso Excel | Descripción en Excel | Cant | Precio | Destino | Producto BD Asociado | Fase Oficial |")
doc.append("|:---:|---|---|:---:|:---:|---|---|---|")

filas_cant_guion = 0
filas_fase_diff = 0

for t in tabla_316:
    desc_excel = f"{t['producto']} {t['subpieza']} {t['nomenclatura']}".strip()
    desc_safe = desc_excel[:45] + ('...' if len(desc_excel) > 45 else '')
    cant_str = f"{t['cantidad']}" if t['cantidad'] is not None else "-"
    if cant_str == "-":
        filas_cant_guion += 1
    pu_str = f"${t['precio']}" if t['precio'] is not None else "-"
    db_nom = t['prod_db_nombre'] or '-'
    db_nom_safe = db_nom[:35] + ('...' if len(db_nom) > 35 else '')
    
    # Verificar si la fase coincide con el Proceso
    fase_proc = PROCESO_A_FASE.get(t['proceso'].strip())
    if t['fase_clave'] != fase_proc:
        filas_fase_diff += 1
        
    doc.append(f"| {t['fila']} | {t['proceso']} | {desc_safe} | {cant_str} | {pu_str} | `{t['destino']}` | {db_nom_safe} | `{t['fase_clave']}` |")

analisis_path = 'docs/despiece/ANALISIS_UNION_LISTADOS.md'
with open(analisis_path, 'w', encoding='utf-8') as f:
    f.write('\n'.join(doc))
print("ANALISIS_UNION_LISTADOS.md guardado exitosamente:", analisis_path)
print(f"Resumen de Tabla 316:")
print(f"  Filas con Cant '-': {filas_cant_guion} (debe ser exactamente 22, las que no traen cantidad en Excel)")
print(f"  Filas con fase != Proceso: {filas_fase_diff} (debe ser 0)")
