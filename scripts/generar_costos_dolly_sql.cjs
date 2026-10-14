/**
 * Generador de migración SQL para los costos del Dolly 2 ejes (Sub-bloque 2R-1e).
 * Lee docs/factura-leolca/extraccion_factura_leolca.json y genera supabase/migrations/20261014_01_dolly.sql
 *
 * Idempotente, ejecutable en una sola transacción.
 */

const fs = require('fs');
const path = require('path');

const jsonPath = path.resolve(__dirname, '../docs/factura-leolca/extraccion_factura_leolca.json');
const outSqlPath = path.resolve(__dirname, '../supabase/migrations/20261014_01_dolly.sql');

if (!fs.existsSync(jsonPath)) {
  console.error(`Error: No se encontró el archivo JSON en ${jsonPath}`);
  process.exit(1);
}

const raw = fs.readFileSync(jsonPath, 'utf8');
const data = JSON.parse(raw);

const dolly = data.modelos && data.modelos.dolly;
if (!dolly) {
  console.error('Error: No se encontró el modelo dolly en el JSON');
  process.exit(1);
}

const escapeSql = (str) => {
  if (str === null || str === undefined) return 'NULL';
  return `'${String(str).replace(/'/g, "''")}'`;
};

const lines = [];

lines.push('-- Migración 20261014_01_dolly.sql');
lines.push('-- Generada automáticamente por scripts/generar_costos_dolly_sql.cjs');
lines.push('-- Sub-bloque 2R-1e: Modelo, acero, kits, mano de obra y costos de opciones del Dolly');
lines.push('-- Idempotente, ejecutable en una sola transacción.');
lines.push('');
lines.push('BEGIN;');
lines.push('');
lines.push('-- Función temporal de sesión para resolver o crear materiales deterministas');
lines.push('CREATE OR REPLACE FUNCTION pg_temp.resolver_o_crear_material_dolly(');
lines.push('    p_org_id uuid,');
lines.push('    p_nombre text,');
lines.push('    p_costo numeric,');
lines.push('    p_desc text');
lines.push(') RETURNS text AS $$');
lines.push('DECLARE');
lines.push('    v_exist_id text;');
lines.push('    v_exist_costo numeric;');
lines.push('    v_final_nombre text := p_nombre;');
lines.push('    v_res_id text;');
lines.push('BEGIN');
lines.push('    SELECT id, costo INTO v_exist_id, v_exist_costo');
lines.push('    FROM productos');
lines.push("    WHERE nombre = p_nombre AND organizacion_id = p_org_id AND tipo_item = 'materia_prima'");
lines.push('    LIMIT 1;');
lines.push('');
lines.push('    IF v_exist_id IS NOT NULL THEN');
lines.push('        IF v_exist_costo = p_costo THEN');
lines.push('            RETURN v_exist_id;');
lines.push('        ELSE');
lines.push("            v_final_nombre := p_nombre || ' (DOLLY)';");
lines.push('            SELECT id INTO v_res_id');
lines.push('            FROM productos');
lines.push("            WHERE nombre = v_final_nombre AND organizacion_id = p_org_id AND tipo_item = 'materia_prima'");
lines.push('            LIMIT 1;');
lines.push('            IF v_res_id IS NOT NULL THEN');
lines.push('                RETURN v_res_id;');
lines.push('            END IF;');
lines.push('        END IF;');
lines.push('    END IF;');
lines.push('');
lines.push('    INSERT INTO productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)');
lines.push("    VALUES (v_final_nombre, 'bien', 'materia_prima', 'PZA', p_costo, 0, p_desc, p_org_id)");
lines.push('    RETURNING id INTO v_res_id;');
lines.push('');
lines.push('    RETURN v_res_id;');
lines.push('END;');
lines.push('$$ LANGUAGE plpgsql;');
lines.push('');
lines.push('DO $$');
lines.push('DECLARE');
lines.push("    v_org_id uuid := '00000000-0000-0000-0000-000000000001';");
lines.push('    v_prod_id text;');
lines.push('    v_model_id uuid;');
lines.push('    v_mat_id text;');
lines.push('    v_opt_id uuid;');
lines.push('    v_count int;');
lines.push('    v_sum_acero numeric;');
lines.push('    v_sum_kits numeric;');
lines.push('    v_sum_mo numeric;');
lines.push('BEGIN');
lines.push('');
lines.push('    -- 1. Producto terminado y modelo Dolly 2 ejes');
lines.push('    INSERT INTO productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)');
lines.push("    SELECT 'DOLLY 2 EJES', 'bien', 'producto_terminado', 'PZA', 0, 0, 'Dolly 2 ejes', v_org_id");
lines.push('    WHERE NOT EXISTS (');
lines.push('        SELECT 1 FROM productos');
lines.push("        WHERE nombre = 'DOLLY 2 EJES' AND organizacion_id = v_org_id AND tipo_item = 'producto_terminado'");
lines.push('    );');
lines.push('');
lines.push("    SELECT id INTO v_prod_id FROM productos WHERE nombre = 'DOLLY 2 EJES' AND organizacion_id = v_org_id AND tipo_item = 'producto_terminado' LIMIT 1;");
lines.push("    IF v_prod_id IS NULL THEN RAISE EXCEPTION 'Producto terminado DOLLY 2 EJES no encontrado'; END IF;");
lines.push('');
lines.push('    INSERT INTO modelos (organizacion_id, producto_id, tipo, largo_ft, num_ejes)');
lines.push("    VALUES (v_org_id, v_prod_id, 'dolly', NULL, 2)");
lines.push('    ON CONFLICT (organizacion_id, producto_id) DO UPDATE SET');
lines.push('        tipo = EXCLUDED.tipo,');
lines.push('        largo_ft = EXCLUDED.largo_ft,');
lines.push('        num_ejes = EXCLUDED.num_ejes;');
lines.push('');
lines.push("    SELECT count(*) INTO v_count FROM modelos WHERE tipo = 'dolly' AND organizacion_id = v_org_id;");
lines.push('    IF v_count <> 1 THEN');
lines.push("        RAISE EXCEPTION 'Se esperaba exactamente 1 modelo dolly, pero se encontraron %', v_count;");
lines.push('    END IF;');
lines.push("    SELECT id INTO v_model_id FROM modelos WHERE tipo = 'dolly' AND organizacion_id = v_org_id;");
lines.push('');
lines.push('    -- 2. Limpieza previa idempotente para import-2r1e');
lines.push("    DELETE FROM receta_base WHERE modelo_id = v_model_id AND notas = 'import-2r1e';");
lines.push("    DELETE FROM costos_modelo WHERE modelo_id = v_model_id AND notas = 'import-2r1e';");
lines.push("    DELETE FROM opcion_costos WHERE tipo_modelo = 'dolly' AND notas = 'import-2r1e';");
lines.push("    DELETE FROM procesos_manufactura WHERE modelo_id = v_model_id AND notas = 'import-2r1e';");
lines.push('');
lines.push('    -- 3. Inserción de materiales de acero y receta_base sección acero');

// Preparar los materiales de acero
const despieceRaw = (dolly.despiece_acero || []).filter(r => r.fila !== 4);
if (despieceRaw.length < 7) {
  console.error(`Error: Se esperaban al menos 7 renglones de acero, pero hay ${despieceRaw.length}`);
  process.exit(1);
}

const itemsAcero = [];

// 1. Paquete Chasis Dolly (reemplaza los 6 primeros renglones: fila 6 a 11)
itemsAcero.push({
  nombre: 'PAQUETE CUERPO CHASIS DOLLY (PUENTES J, C, Z, ALMA, SOLERAS SUPERIOR E INFERIOR)',
  pieza: 'Paquete cuerpo chasis dolly',
  cantidad: 1,
  costo: 14800,
  descripcion: 'PAQUETE'
});

// 2. Renglones restantes (fila 12 en adelante)
const restoDespiece = despieceRaw.slice(6);
for (const row of restoDespiece) {
  let base = row.pieza ? row.pieza.trim() : '';
  if (row.variante && row.variante.trim()) base += ' ' + row.variante.trim();
  if (row.descripcion && row.descripcion.trim()) base += ' (' + row.descripcion.trim() + ')';
  const nombre = base.toUpperCase();

  const sinPrecio = (row.precio_unitario === null || row.precio_unitario === undefined);
  const costo = sinPrecio ? 0 : Number(row.precio_unitario);
  const descripcion = sinPrecio ? 'SIN PRECIO' : (row.descripcion || row.pieza);

  itemsAcero.push({
    nombre,
    pieza: row.pieza,
    cantidad: Number(row.cantidad),
    costo,
    descripcion
  });
}

// Generar SQL para cada material y línea de receta_base
for (const item of itemsAcero) {
  lines.push(`    v_mat_id := pg_temp.resolver_o_crear_material_dolly(v_org_id, ${escapeSql(item.nombre)}, ${item.costo}, ${escapeSql(item.descripcion)});`);
  lines.push(`    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)`);
  lines.push(`    VALUES (v_model_id, v_mat_id, ${item.cantidad}, 'fija', NULL, ${escapeSql(item.pieza)}, 'acero', NULL, 'import-2r1e');`);
}

lines.push('');
lines.push('    -- Validación de suma de acero (debe ser exactamente 27,018.80)');
lines.push('    SELECT round(coalesce(sum(rb.cantidad * p.costo), 0), 2) INTO v_sum_acero');
lines.push('    FROM receta_base rb');
lines.push('    JOIN productos p ON rb.material_id = p.id');
lines.push("    WHERE rb.modelo_id = v_model_id AND rb.seccion = 'acero' AND rb.notas = 'import-2r1e';");
lines.push('    IF v_sum_acero <> 27018.80 THEN');
lines.push("        RAISE EXCEPTION 'El acero del dolly no suma 27,018.80 (suma actual: %)', v_sum_acero;");
lines.push('    END IF;');
lines.push('');
lines.push('    -- 4. Inserción de costos_modelo (kits y consumibles fijos: 18 conceptos)');

const itemsCostosModelo = [
  { seccion: 'otros', concepto: 'Gata de izaje', cantidad: 1, cu: 433 },
  { seccion: 'otros', concepto: 'Bisagra', cantidad: 2, cu: 1041 },
  { seccion: 'otros', concepto: 'Oreja', cantidad: 2, cu: 843 },
  { seccion: 'otros', concepto: 'Perno de Dona', cantidad: 2, cu: 421.08 },
  { seccion: 'otros', concepto: 'Buje cónico', cantidad: 4, cu: 160 },
  { seccion: 'otros', concepto: 'Lodera blanca', cantidad: 2, cu: 303.99 },
  { seccion: 'otros', concepto: 'Flejes', cantidad: 2, cu: 232 },
  { seccion: 'tornilleria', concepto: 'Tornillería para loderas', cantidad: 8, cu: 5 },
  { seccion: 'luz', concepto: 'Kit de luz', cantidad: 1, cu: 4500 },
  { seccion: 'consumibles', concepto: 'Rollo de micro tubular', cantidad: 2, cu: 995 },
  { seccion: 'consumibles', concepto: 'Tanque de CO2', cantidad: 1, cu: 925 },
  { seccion: 'consumibles', concepto: 'Consumibles', cantidad: 0.5, cu: 550 },
  { seccion: 'consumibles', concepto: 'Kit de limpieza', cantidad: 1, cu: 400 },
  { seccion: 'pintura', concepto: 'Praimer', cantidad: 4, cu: 285 },
  { seccion: 'pintura', concepto: 'Pintura color estándar', cantidad: 4, cu: 640 },
  { seccion: 'otros', concepto: 'Tanque para aire', cantidad: 1, cu: 904 },
  { seccion: 'otros', concepto: 'Kit de rotulación', cantidad: 1, cu: 400 },
  { seccion: 'otros', concepto: 'Cinta reflejante', cantidad: 1, cu: 200 }
];

for (const cm of itemsCostosModelo) {
  lines.push(`    INSERT INTO costos_modelo (organizacion_id, modelo_id, seccion, concepto, cantidad, costo_unitario, escala, fuente, notas)`);
  lines.push(`    VALUES (v_org_id, v_model_id, ${escapeSql(cm.seccion)}, ${escapeSql(cm.concepto)}, ${cm.cantidad}, ${cm.cu}, 'fija', 'Factura Leolca', 'import-2r1e');`);
}

lines.push('');
lines.push('    -- Validación de suma de costos_modelo (debe ser exactamente 20,089.14)');
lines.push('    SELECT round(coalesce(sum(cantidad * costo_unitario), 0), 2) INTO v_sum_kits');
lines.push('    FROM costos_modelo');
lines.push("    WHERE modelo_id = v_model_id AND notas = 'import-2r1e';");
lines.push('    IF v_sum_kits <> 20089.14 THEN');
lines.push("        RAISE EXCEPTION 'Los costos_modelo del dolly no suman 20,089.14 (suma actual: %)', v_sum_kits;");
lines.push('    END IF;');
lines.push('');
lines.push('    -- 5. Inserción de procesos_manufactura (43 renglones de mano de obra)');

const manoObra = dolly.mano_obra || [];
if (manoObra.length !== 43) {
  console.error(`Error: Se esperaban 43 renglones en mano_obra, pero hay ${manoObra.length}`);
  process.exit(1);
}

for (const mo of manoObra) {
  // Los minutos totales del modelo corresponden al costo del renglón dividido entre la tarifa por minuto
  const minutosTotales = Math.round(((mo.costo * 60) / mo.tarifa_hora) * 100) / 100;
  lines.push(`    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)`);
  lines.push(`    VALUES (v_org_id, v_model_id, ${mo.fila}, ${escapeSql(mo.proceso)}, NULL, ${minutosTotales}, ${mo.tarifa_hora}, 'import-2r1e');`);
}

lines.push('');
lines.push('    -- Validación de suma de procesos_manufactura (debe ser exactamente 11,249.90)');
lines.push('    SELECT round(coalesce(sum(minutos * tarifa_hora / 60.0), 0), 2) INTO v_sum_mo');
lines.push('    FROM procesos_manufactura');
lines.push("    WHERE modelo_id = v_model_id AND notas = 'import-2r1e';");
lines.push('    IF v_sum_mo <> 11249.90 THEN');
lines.push("        RAISE EXCEPTION 'La mano de obra del dolly no suma 11,249.90 (suma actual: %)', v_sum_mo;");
lines.push('    END IF;');
lines.push('');
lines.push('    -- 6. Inserción de opcion_costos para Dolly (9 opciones catalogadas)');

const opcionesCostos = [
  // quinta (1)
  { grupo_clave: 'quinta', opcion_clave: 'holland', costo: 27375, escala: 'fija', cantidad_base: 1, notas: 'import-2r1e' },
  // abs (2)
  { grupo_clave: 'abs', opcion_clave: '2e_sin_retractil', costo: 20000, escala: 'fija', cantidad_base: 1, notas: 'import-2r1e' },
  { grupo_clave: 'abs', opcion_clave: '2e_1_retractil', costo: 24700, escala: 'fija', cantidad_base: 1, notas: 'import-2r1e' },
  // retractil (1)
  { grupo_clave: 'retractil', opcion_clave: 'paleta', costo: 8200, escala: 'fija', cantidad_base: 1, notas: 'import-2r1e' },
  // rines (2)
  { grupo_clave: 'rines', opcion_clave: 'acero', costo: 1550, escala: 'por_eje', cantidad_base: 4, fuente: 'Factura Leolca (cantidad por eje supuesta igual a plataforma y góndola)', notas: 'import-2r1e' },
  { grupo_clave: 'rines', opcion_clave: 'aluminio', costo: 5500, escala: 'por_eje', cantidad_base: 4, fuente: 'Factura Leolca (cantidad por eje supuesta igual a plataforma y góndola)', notas: 'import-2r1e' },
  // llantas (3)
  { grupo_clave: 'llantas', opcion_clave: 'chinas', costo: 3000, escala: 'por_eje', cantidad_base: 4, fuente: 'Factura Leolca (cantidad por eje supuesta igual a plataforma y góndola)', notas: 'import-2r1e' },
  { grupo_clave: 'llantas', opcion_clave: 'firestone', costo: 8700, escala: 'por_eje', cantidad_base: 4, fuente: 'Factura Leolca (cantidad por eje supuesta igual a plataforma y góndola)', notas: 'import-2r1e' },
  { grupo_clave: 'llantas', opcion_clave: 'amulet', costo: 4225, escala: 'por_eje', cantidad_base: 4, fuente: 'Factura Leolca (cantidad por eje supuesta igual a plataforma y góndola)', notas: 'import-2r1e' }
];

for (const oc of opcionesCostos) {
  lines.push(`    SELECT oc.id INTO v_opt_id FROM opciones_configuracion oc`);
  lines.push(`    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id`);
  lines.push(`    WHERE gc.clave = ${escapeSql(oc.grupo_clave)} AND oc.clave = ${escapeSql(oc.opcion_clave)} AND oc.organizacion_id = v_org_id LIMIT 1;`);
  lines.push(`    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', ${escapeSql(oc.grupo_clave)}, ${escapeSql(oc.opcion_clave)}; END IF;`);
  lines.push(`    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)`);
  lines.push(`    VALUES (v_org_id, v_opt_id, 'dolly', ${oc.cantidad_base}, ${escapeSql(oc.escala)}, ${oc.costo}, ${escapeSql(oc.fuente || 'Factura Leolca')}, ${escapeSql(oc.notas)})`);
  lines.push(`    ON CONFLICT (opcion_id, tipo_modelo) DO UPDATE SET`);
  lines.push(`        cantidad_base = EXCLUDED.cantidad_base, escala = EXCLUDED.escala, costo_unitario = EXCLUDED.costo_unitario, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;`);
}

lines.push('');
lines.push('END $$;');
lines.push('');
lines.push('DROP FUNCTION IF EXISTS pg_temp.resolver_o_crear_material_dolly(uuid, text, numeric, text);');
lines.push('');
lines.push('COMMIT;');

fs.writeFileSync(outSqlPath, lines.join('\n') + '\n', 'utf8');
console.log(`Migración generada exitosamente en ${outSqlPath}`);
console.log(`- Materiales y receta_base acero: ${itemsAcero.length}`);
console.log(`- Costos modelo (kits/consumibles): ${itemsCostosModelo.length}`);
console.log(`- Procesos manufactura (mano de obra): ${manoObra.length}`);
console.log(`- Opciones costos: ${opcionesCostos.length}`);
