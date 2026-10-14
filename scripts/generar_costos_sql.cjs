/**
 * Generador de migración SQL para los costos de la plataforma 40 ft / 2 ejes (Sub-bloque 2R-1c).
 * Lee docs/factura-leolca/extraccion_factura_leolca.json y genera supabase/migrations/20261011_02_costos_plataforma_40x2.sql
 */

const fs = require('fs');
const path = require('path');

const jsonPath = path.resolve(__dirname, '../docs/factura-leolca/extraccion_factura_leolca.json');
const outSqlPath = path.resolve(__dirname, '../supabase/migrations/20261011_02_costos_plataforma_40x2.sql');

if (!fs.existsSync(jsonPath)) {
  console.error(`Error: No se encontró el archivo JSON en ${jsonPath}`);
  process.exit(1);
}

const raw = fs.readFileSync(jsonPath, 'utf8');
const data = JSON.parse(raw);

const plataforma = data.modelos && data.modelos.plataforma_40ft_2ejes;
if (!plataforma) {
  console.error('Error: No se encontró el modelo plataforma_40ft_2ejes en el JSON');
  process.exit(1);
}

const escapeSql = (str) => {
  if (str === null || str === undefined) return 'NULL';
  return `'${String(str).replace(/'/g, "''")}'`;
};

const lines = [];

lines.push('-- Migración 20261011_02_costos_plataforma_40x2.sql');
lines.push('-- Generada automáticamente por scripts/generar_costos_sql.cjs');
lines.push('-- Sub-bloque 2R-1c: Costos de la plataforma 40 ft / 2 ejes');
lines.push('');
lines.push('BEGIN;');
lines.push('');
lines.push('DO $$');
lines.push('DECLARE');
lines.push("    v_org_id uuid := '00000000-0000-0000-0000-000000000001';");
lines.push('    v_model_id uuid;');
lines.push('    v_mat_id text;');
lines.push('    v_opt_id uuid;');
lines.push('    v_count int;');
lines.push('BEGIN');
lines.push('');
lines.push('    -- 1. Resolver y validar modelo plataforma 40 ft / 2 ejes');
lines.push("    SELECT count(*) INTO v_count FROM modelos WHERE tipo = 'plataforma' AND largo_ft = 40 AND num_ejes = 2;");
lines.push('    IF v_count <> 1 THEN');
lines.push("        RAISE EXCEPTION 'Se esperaba exactamente 1 modelo plataforma 40 ft / 2 ejes, pero se encontraron %', v_count;");
lines.push('    END IF;');
lines.push("    SELECT id INTO v_model_id FROM modelos WHERE tipo = 'plataforma' AND largo_ft = 40 AND num_ejes = 2;");
lines.push('');
lines.push('    -- 2. Limpieza idempotente previa para import-2r1c');
lines.push("    DELETE FROM receta_base WHERE notas = 'import-2r1c';");
lines.push("    DELETE FROM costos_modelo WHERE notas LIKE '%import-2r1c%' OR fuente = 'Factura Leolca';");
lines.push("    DELETE FROM opcion_costos WHERE notas = 'import-2r1c' OR fuente = 'Factura Leolca';");
lines.push("    DELETE FROM procesos_manufactura WHERE notas = 'import-2r1c';");
lines.push('');
lines.push('    -- 3. Inserción de materiales de acero (61 piezas)');

const despiece = plataforma.despiece_acero || [];
if (despiece.length !== 61) {
  console.error(`Error: Se esperaban 61 renglones en despiece_acero, pero hay ${despiece.length}`);
  process.exit(1);
}

const nombresAcero = new Set();
const itemsAcero = [];

for (const row of despiece) {
  let base = row.pieza ? row.pieza.trim() : '';
  if (row.variante && row.variante.trim()) {
    base += ' ' + row.variante.trim();
  }
  if (row.descripcion && row.descripcion.trim()) {
    base += ' (' + row.descripcion.trim() + ')';
  }
  let nombre = base.toUpperCase();

  // Regla explícita de desambiguación para fila 62 (segundo porta llantas)
  if (row.fila === 62) {
    nombre += ' #2';
  }

  if (nombresAcero.has(nombre)) {
    console.error(`Error de colisión de nombre no resuelta: "${nombre}" en fila ${row.fila}`);
    process.exit(1);
  }
  nombresAcero.add(nombre);

  const sinPrecio = (row.precio_unitario === null || row.precio_unitario === undefined);
  const costo = sinPrecio ? 0 : Number(row.precio_unitario);
  const descripcionMat = sinPrecio ? 'SIN PRECIO' : (row.descripcion || row.pieza);

  itemsAcero.push({
    fila: row.fila,
    pieza: row.pieza,
    nombre,
    cantidad: Number(row.cantidad),
    costo,
    sinPrecio,
    descripcion: descripcionMat
  });
}

// Inserción de materiales de acero en productos
for (const item of itemsAcero) {
  lines.push(`    INSERT INTO productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)`);
  lines.push(`    SELECT ${escapeSql(item.nombre)}, 'bien', 'materia_prima', 'PZA', ${item.costo}, 0, ${escapeSql(item.descripcion)}, v_org_id`);
  lines.push(`    WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = ${escapeSql(item.nombre)} AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');`);
}

lines.push('');
lines.push('    -- 4. Inserción de receta_base sección acero para plataforma 40/2');
for (const item of itemsAcero) {
  lines.push(`    SELECT id INTO v_mat_id FROM productos WHERE nombre = ${escapeSql(item.nombre)} AND organizacion_id = v_org_id AND tipo_item = 'materia_prima' LIMIT 1;`);
  lines.push(`    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: %', ${escapeSql(item.nombre)}; END IF;`);
  lines.push(`    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)`);
  lines.push(`    VALUES (v_model_id, v_mat_id, ${item.cantidad}, 'fija', NULL, ${escapeSql(item.pieza)}, 'acero', NULL, 'import-2r1c');`);
}

lines.push('');
lines.push('    -- 5. Inserción de costos_modelo (kits y consumibles fijos)');
const complementarios = plataforma.configuracion_complementarios || [];
// Secciones permitidas: consumibles, luz, pintura, tornilleria, otros
const itemsCostosModelo = [
  { grupo: 'Topes', opcion: 'Tope de goma', seccion: 'otros', concepto: 'Tope de goma', cantidad: 2, cu: 82, notas: 'import-2r1c' },
  { grupo: 'Loderas', opcion: 'Lodera blanca', seccion: 'otros', concepto: 'Lodera blanca', cantidad: 2, cu: 303.99, notas: 'import-2r1c' },
  { grupo: 'Loderas', opcion: 'Flejes', seccion: 'otros', concepto: 'Flejes', cantidad: 2, cu: 232, notas: 'import-2r1c' },
  { grupo: 'Loderas', opcion: 'Tornilleria', seccion: 'tornilleria', concepto: 'Tornillería para loderas', cantidad: 8, cu: 5, notas: 'import-2r1c' },
  { grupo: 'Banderolas', opcion: null, seccion: 'otros', concepto: 'Banderolas', cantidad: 2, cu: 400, notas: 'import-2r1c' },
  { grupo: 'Kit de luz', opcion: null, seccion: 'luz', concepto: 'Kit de luz', cantidad: 1, cu: 15000, notas: 'import-2r1c' },
  { grupo: 'Royo de micro tubular', opcion: null, seccion: 'consumibles', concepto: 'Rollo de micro tubular', cantidad: 3, cu: 995, notas: 'import-2r1c' },
  { grupo: 'Tanque de CO2', opcion: null, seccion: 'consumibles', concepto: 'Tanque de CO2', cantidad: 3, cu: 925, notas: 'import-2r1c' },
  { grupo: 'Consumibles', opcion: null, seccion: 'consumibles', concepto: 'Consumibles', cantidad: 1, cu: 550, notas: 'import-2r1c' },
  { grupo: 'Kit de limpieza', opcion: null, seccion: 'consumibles', concepto: 'Kit de limpieza', cantidad: 1, cu: 300, notas: 'import-2r1c' },
  { grupo: 'Praimer', opcion: null, seccion: 'pintura', concepto: 'Praimer', cantidad: 1, cu: 10000, notas: 'import-2r1c' },
  { grupo: 'Pintura', opcion: 'Color estandar', seccion: 'pintura', concepto: 'Pintura color estándar', cantidad: 1, cu: 12000, fuente: 'Factura Leolca (cantidad original: 1 1/2 cubeta)', notas: 'import-2r1c' }
];

for (const cm of itemsCostosModelo) {
  lines.push(`    INSERT INTO costos_modelo (organizacion_id, modelo_id, seccion, concepto, cantidad, costo_unitario, escala, fuente, notas)`);
  lines.push(`    VALUES (v_org_id, v_model_id, ${escapeSql(cm.seccion)}, ${escapeSql(cm.concepto)}, ${cm.cantidad}, ${cm.cu}, 'fija', ${escapeSql(cm.fuente || 'Factura Leolca')}, ${escapeSql(cm.notas)});`);
}

lines.push('');
lines.push('    -- 6. Inserción de opcion_costos (22 opciones mapeadas)');

const opcionesCostos = [
  // suspension (4)
  { grupo_clave: 'suspension', opcion_clave: 'fleet_master', costo: 23118, escala: 'por_eje', cantidad_base: 1 },
  { grupo_clave: 'suspension', opcion_clave: 'ampro', costo: 23118, escala: 'por_eje', cantidad_base: 1 },
  { grupo_clave: 'suspension', opcion_clave: 'hendrickson', costo: 35844, escala: 'por_eje', cantidad_base: 1 },
  { grupo_clave: 'suspension', opcion_clave: 'alta_hendrickson', costo: 46783.62, escala: 'por_eje', cantidad_base: 1 },
  // eje (2)
  { grupo_clave: 'eje', opcion_clave: 'fleet_master', costo: 19905.60, escala: 'por_eje', cantidad_base: 1 },
  { grupo_clave: 'eje', opcion_clave: 'ampro', costo: 21692, escala: 'por_eje', cantidad_base: 1 },
  // patin (3)
  { grupo_clave: 'patin', opcion_clave: 'hj', costo: 5646.88, escala: 'fija', cantidad_base: 2 },
  { grupo_clave: 'patin', opcion_clave: 'ampro', costo: 5916, escala: 'fija', cantidad_base: 2 },
  { grupo_clave: 'patin', opcion_clave: 'holland', costo: 17980, escala: 'fija', cantidad_base: 2 },
  // gancho (3)
  { grupo_clave: 'gancho', opcion_clave: 'holland_8_10', costo: 6844, escala: 'fija', cantidad_base: 1 },
  { grupo_clave: 'gancho', opcion_clave: 'premier_8', costo: 11890, escala: 'fija', cantidad_base: 1 },
  { grupo_clave: 'gancho', opcion_clave: 'premier_bestia_6', costo: 28040.98, escala: 'fija', cantidad_base: 1 },
  // abs (3)
  { grupo_clave: 'abs', opcion_clave: '2e_sin_retractil', costo: 20000, escala: 'fija', cantidad_base: 1 },
  { grupo_clave: 'abs', opcion_clave: '2e_1_retractil', costo: 24700, escala: 'fija', cantidad_base: 1 },
  { grupo_clave: 'abs', opcion_clave: '3e_2_retractil', costo: 28500, escala: 'fija', cantidad_base: 1 },
  // rines (2)
  { grupo_clave: 'rines', opcion_clave: 'acero', costo: 1550, escala: 'por_eje', cantidad_base: 4 },
  { grupo_clave: 'rines', opcion_clave: 'aluminio', costo: 5500, escala: 'por_eje', cantidad_base: 4 },
  // llantas (3)
  { grupo_clave: 'llantas', opcion_clave: 'chinas', costo: 3000, escala: 'por_eje', cantidad_base: 4 },
  { grupo_clave: 'llantas', opcion_clave: 'firestone', costo: 8700, escala: 'por_eje', cantidad_base: 4 },
  { grupo_clave: 'llantas', opcion_clave: 'amulet', costo: 4225, escala: 'por_eje', cantidad_base: 4 },
  // piso (2)
  { grupo_clave: 'piso', opcion_clave: 'laminado_madera', costo: 39060, escala: 'fija', cantidad_base: 1 },
  { grupo_clave: 'piso', opcion_clave: 'laminado_plastico', costo: 52060, escala: 'fija', cantidad_base: 1 }
];

for (const oc of opcionesCostos) {
  lines.push(`    SELECT oc.id INTO v_opt_id FROM opciones_configuracion oc`);
  lines.push(`    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id`);
  lines.push(`    WHERE gc.clave = ${escapeSql(oc.grupo_clave)} AND oc.clave = ${escapeSql(oc.opcion_clave)} AND oc.organizacion_id = v_org_id LIMIT 1;`);
  lines.push(`    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', ${escapeSql(oc.grupo_clave)}, ${escapeSql(oc.opcion_clave)}; END IF;`);
  lines.push(`    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)`);
  lines.push(`    VALUES (v_org_id, v_opt_id, 'plataforma', ${oc.cantidad_base}, ${escapeSql(oc.escala)}, ${oc.costo}, 'Factura Leolca', 'import-2r1c')`);
  lines.push(`    ON CONFLICT (opcion_id, tipo_modelo) DO UPDATE SET`);
  lines.push(`        cantidad_base = EXCLUDED.cantidad_base, escala = EXCLUDED.escala, costo_unitario = EXCLUDED.costo_unitario, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;`);
}

lines.push('');
lines.push('    -- 7. Inserción de procesos_manufactura (80 renglones mano de obra)');
const manoObra = plataforma.mano_obra || [];
if (manoObra.length !== 80) {
  console.error(`Error: Se esperaban 80 renglones en mano_obra, pero hay ${manoObra.length}`);
  process.exit(1);
}

for (const mo of manoObra) {
  lines.push(`    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)`);
  lines.push(`    VALUES (v_org_id, v_model_id, ${mo.fila}, ${escapeSql(mo.proceso)}, NULL, ${mo.minutos}, ${mo.tarifa_hora}, 'import-2r1c');`);
}

lines.push('');
lines.push('    -- 8. Parámetros de costeo (ganancia_factura)');
lines.push('    INSERT INTO parametros_costeo (organizacion_id, clave, valor)');
lines.push(`    VALUES (v_org_id, 'ganancia_factura', '{"plataforma":110000,"dolly":65000,"gondola_servicios_sueldos":100000}'::jsonb)`);
lines.push('    ON CONFLICT (organizacion_id, clave) DO UPDATE SET valor = EXCLUDED.valor;');
lines.push('');
lines.push('END $$;');
lines.push('');
lines.push('COMMIT;');

fs.writeFileSync(outSqlPath, lines.join('\n') + '\n', 'utf8');
console.log(`Migración generada exitosamente en ${outSqlPath}`);
console.log(`- Materiales de acero: ${itemsAcero.length}`);
console.log(`- Receta base acero: ${itemsAcero.length}`);
console.log(`- Costos modelo: ${itemsCostosModelo.length}`);
console.log(`- Opciones costos: ${opcionesCostos.length}`);
console.log(`- Procesos manufactura: ${manoObra.length}`);
