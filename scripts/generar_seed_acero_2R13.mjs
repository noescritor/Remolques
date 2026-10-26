/**
 * Generador de la migración y seed para Sub-bloque 2R-13: Calculadoras de acero
 * Lee docs/importacion/acero_precios_2026-10.json y genera:
 * supabase/migrations/20261027_01_acero_precios.sql
 */

import { readFileSync, writeFileSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const raiz = resolve(__dirname, '..');

const jsonPath = resolve(raiz, 'docs/importacion/acero_precios_2026-10.json');
const sqlPath = resolve(raiz, 'supabase/migrations/20261027_01_acero_precios.sql');

const data = JSON.parse(readFileSync(jsonPath, 'utf8'));

function normalizarNombre(nombre) {
  return nombre.replace(/A-572[°\uFFFD\u00B0]?50/g, 'A-572-50');
}

function determinarTipo(nombre) {
  const n = (nombre || '')
    .trim()
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '');

  if (n.startsWith('placa')) return 'placa';
  if (n.startsWith('lamina')) return 'lamina';
  if (n.startsWith('solera')) return 'solera';
  if (n.startsWith('canal')) return 'canal';
  if (n.startsWith('ptr')) return 'ptr';
  if (n.startsWith('tubo')) return 'tubo';
  if (n.startsWith('angulo')) return 'angulo';
  if (n.startsWith('redondo')) return 'redondo';

  if (n.includes('placa')) return 'placa';
  if (n.includes('lamina')) return 'lamina';
  if (n.includes('solera')) return 'solera';
  if (n.includes('canal')) return 'canal';
  if (n.includes('ptr')) return 'ptr';
  if (n.includes('tubo')) return 'tubo';
  if (n.includes('angulo')) return 'angulo';
  if (n.includes('redondo')) return 'redondo';

  throw new Error(`Tipo desconocido para: ${nombre}`);
}

function parsearMedida(nombre) {
  const regex = /(?:en\s+)?(\d+(?:\.\d+)?)\s*[xX]\s*(\d+(?:\.\d+)?)\s*'/;
  const match = nombre.match(regex);
  if (match) {
    return { anchoFt: parseFloat(match[1]), largoFt: parseFloat(match[2]) };
  }
  return null;
}

// 1. Procesar los 36 materiales del catálogo
const materialesMap = new Map();

for (const m of data.materiales) {
  const nombreNorm = normalizarNombre(m.nombre);
  const tipo = determinarTipo(nombreNorm);
  const medida = parsearMedida(nombreNorm);

  materialesMap.set(nombreNorm, {
    nombre: nombreNorm,
    tipo,
    anchoFt: medida ? medida.anchoFt : null,
    largoFt: medida ? medida.largoFt : null,
    precios: { ...m.precios },
  });
}

// 2. Incorporar los precios de TPI del comparador_ejemplo
if (data.comparador_ejemplo) {
  for (const ej of data.comparador_ejemplo) {
    const nombreNorm = normalizarNombre(ej.material);
    let item = materialesMap.get(nombreNorm);
    if (!item) {
      throw new Error(`Material del comparador no encontrado: ${nombreNorm}`);
    }
    if (ej.precio_tpi !== undefined && ej.precio_tpi !== null) {
      item.precios['TPI'] = ej.precio_tpi;
    }
  }
}

// 3. Incorporar los 2 materiales de referencia de COSTEO DE PLACA.xlsx
const materialesRef = [
  {
    nombre: 'Lamina Negra Cal. 12 4X10\'',
    tipo: 'lamina',
    anchoFt: 4,
    largoFt: 10,
    proveedor: 'REFERENCIA (Excel costeo)',
    precio: 1786.0,
    fuente: 'COSTEO DE PLACA.xlsx; proveedor no indicado, medida 4X10 supuesta',
  },
  {
    nombre: 'Lamina Negra Cal. 14 4X10\'',
    tipo: 'lamina',
    anchoFt: 4,
    largoFt: 10,
    proveedor: 'REFERENCIA (Excel costeo)',
    precio: 1435.0,
    fuente: 'COSTEO DE PLACA.xlsx; proveedor no indicado, medida 4X10 supuesta',
  },
];

for (const ref of materialesRef) {
  materialesMap.set(ref.nombre, {
    nombre: ref.nombre,
    tipo: ref.tipo,
    anchoFt: ref.anchoFt,
    largoFt: ref.largoFt,
    precios: {
      [ref.proveedor]: {
        precio: ref.precio,
        fuente: ref.fuente,
      },
    },
  });
}

console.log(`Total materiales a sembrar: ${materialesMap.size} (esperado 38)`);

let totalPrecios = 0;
for (const [_, m] of materialesMap) {
  totalPrecios += Object.keys(m.precios).length;
}
console.log(`Total precios a sembrar: ${totalPrecios} (esperado 76)`);

// 4. Generar el script SQL
function escapeSql(str) {
  return str.replace(/'/g, "''");
}

let sql = `-- Migración 20261027_01_acero_precios.sql
-- Sub-bloque 2R-13: calculadoras de acero (costeo de placa + comparador de precios de acero)
-- Esquema y seed idempotente para acero_materiales, acero_precios y acero_precios_historial

BEGIN;

-- 1. Tabla acero_materiales
CREATE TABLE IF NOT EXISTS acero_materiales (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organizacion_id UUID NOT NULL REFERENCES organizaciones(id) ON DELETE CASCADE,
    nombre TEXT NOT NULL,
    tipo TEXT NOT NULL CHECK (tipo IN ('placa', 'lamina', 'solera', 'canal', 'ptr', 'tubo', 'angulo', 'redondo')),
    ancho_ft NUMERIC,
    largo_ft NUMERIC,
    activo BOOLEAN NOT NULL DEFAULT true,
    notas TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(organizacion_id, nombre)
);

ALTER TABLE acero_materiales ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "org_acero_materiales_policy" ON acero_materiales;
CREATE POLICY "org_acero_materiales_policy" ON acero_materiales FOR ALL USING (organizacion_id = get_current_org_id());

CREATE INDEX IF NOT EXISTS idx_acero_materiales_org ON acero_materiales(organizacion_id);
CREATE INDEX IF NOT EXISTS idx_acero_materiales_tipo ON acero_materiales(organizacion_id, tipo);

-- 2. Tabla acero_precios
CREATE TABLE IF NOT EXISTS acero_precios (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organizacion_id UUID NOT NULL REFERENCES organizaciones(id) ON DELETE CASCADE,
    material_id UUID NOT NULL REFERENCES acero_materiales(id) ON DELETE CASCADE,
    proveedor TEXT NOT NULL,
    precio NUMERIC(14,4) NOT NULL,
    incluye_iva BOOLEAN NOT NULL DEFAULT true,
    fuente TEXT,
    actualizado_el TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    notas TEXT,
    UNIQUE(material_id, proveedor)
);

ALTER TABLE acero_precios ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "org_acero_precios_policy" ON acero_precios;
CREATE POLICY "org_acero_precios_policy" ON acero_precios FOR ALL USING (organizacion_id = get_current_org_id());

CREATE INDEX IF NOT EXISTS idx_acero_precios_material_id ON acero_precios(material_id);
CREATE INDEX IF NOT EXISTS idx_acero_precios_org ON acero_precios(organizacion_id);

-- 3. Tabla acero_precios_historial
CREATE TABLE IF NOT EXISTS acero_precios_historial (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organizacion_id UUID NOT NULL REFERENCES organizaciones(id) ON DELETE CASCADE,
    material_id UUID NOT NULL REFERENCES acero_materiales(id) ON DELETE CASCADE,
    proveedor TEXT NOT NULL,
    precio_anterior NUMERIC(14,4),
    precio_nuevo NUMERIC(14,4) NOT NULL,
    usuario_id UUID,
    creado_el TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE acero_precios_historial ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "org_acero_precios_historial_policy" ON acero_precios_historial;
CREATE POLICY "org_acero_precios_historial_policy" ON acero_precios_historial FOR ALL USING (organizacion_id = get_current_org_id());

CREATE INDEX IF NOT EXISTS idx_acero_precios_historial_org ON acero_precios_historial(organizacion_id, creado_el DESC);
CREATE INDEX IF NOT EXISTS idx_acero_precios_historial_mat ON acero_precios_historial(material_id);

-- 4. Seed de materiales y precios por organización
DO $$
DECLARE
    r_org RECORD;
    v_mat_id UUID;
BEGIN
    FOR r_org IN SELECT id FROM organizaciones LOOP
`;

for (const [nombre, m] of materialesMap) {
  const anchoVal = m.anchoFt !== null ? m.anchoFt : 'NULL';
  const largoVal = m.largoFt !== null ? m.largoFt : 'NULL';

  sql += `
        -- Material: ${nombre}
        INSERT INTO acero_materiales (organizacion_id, nombre, tipo, ancho_ft, largo_ft, activo, notas)
        VALUES (r_org.id, '${escapeSql(nombre)}', '${m.tipo}', ${anchoVal}, ${largoVal}, true, 'import-2r13')
        ON CONFLICT (organizacion_id, nombre)
        DO UPDATE SET tipo = EXCLUDED.tipo, ancho_ft = EXCLUDED.ancho_ft, largo_ft = EXCLUDED.largo_ft, activo = EXCLUDED.activo, notas = EXCLUDED.notas
        RETURNING id INTO v_mat_id;
`;

  for (const [proveedor, precioObj] of Object.entries(m.precios)) {
    let precioVal;
    let fuenteVal;
    if (typeof precioObj === 'number') {
      precioVal = precioObj;
      fuenteVal = 'PRECIOS DE ACERO.xlsx (Hoja1)';
    } else {
      precioVal = precioObj.precio;
      fuenteVal = precioObj.fuente || 'PRECIOS DE ACERO.xlsx (Hoja1)';
    }

    sql += `        INSERT INTO acero_precios (organizacion_id, material_id, proveedor, precio, incluye_iva, fuente, notas)
        VALUES (r_org.id, v_mat_id, '${escapeSql(proveedor)}', ${precioVal}, true, '${escapeSql(fuenteVal)}', 'import-2r13')
        ON CONFLICT (material_id, proveedor)
        DO UPDATE SET precio = EXCLUDED.precio, incluye_iva = EXCLUDED.incluye_iva, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;
`;
  }
}

sql += `    END LOOP;
END $$;

COMMIT;
`;

writeFileSync(sqlPath, sql, 'utf8');
console.log(`Archivo generado con éxito: ${sqlPath}`);
