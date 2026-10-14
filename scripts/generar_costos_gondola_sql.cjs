/**
 * Generador de migración SQL para los costos de la Góndola (Sub-bloque 2R-1f).
 * Lee docs/factura-leolca/extraccion_factura_leolca.json y genera:
 * supabase/migrations/20261014_02_gondola.sql
 *
 * Idempotente, ejecutable en una sola transacción.
 */

const fs = require('fs');
const path = require('path');

const jsonPath = path.resolve(__dirname, '../docs/factura-leolca/extraccion_factura_leolca.json');
const outSqlPath = path.resolve(__dirname, '../supabase/migrations/20261014_02_gondola.sql');

if (!fs.existsSync(jsonPath)) {
  console.error(`Error: No se encontró el archivo JSON en ${jsonPath}`);
  process.exit(1);
}

const raw = fs.readFileSync(jsonPath, 'utf8');
const data = JSON.parse(raw);

const a36 = data.modelos && data.modelos.gondola_a36;
const hardox = data.modelos && data.modelos.gondola_hardox450;

if (!a36 || !hardox) {
  console.error('Error: No se encontraron los modelos de góndola en el JSON');
  process.exit(1);
}

const escapeSql = (str) => {
  if (str === null || str === undefined) return 'NULL';
  return `'${String(str).replace(/'/g, "''")}'`;
};

const lines = [];

lines.push('-- Migración 20261014_02_gondola.sql');
lines.push('-- Generada automáticamente por scripts/generar_costos_gondola_sql.cjs');
lines.push('-- Sub-bloque 2R-1f: Modelos, chasis, tina por material, kits fijos y costos de opciones de la Góndola');
lines.push('-- Idempotente, ejecutable en una sola transacción.');
lines.push('');
lines.push('BEGIN;');
lines.push('');
lines.push('-- Función temporal de sesión para resolver o crear materiales deterministas para la góndola');
lines.push('CREATE OR REPLACE FUNCTION pg_temp.resolver_o_crear_material_gondola(');
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
lines.push('    v_res_costo numeric;');
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
lines.push("            v_final_nombre := p_nombre || ' (GONDOLA)';");
lines.push('            SELECT id, costo INTO v_res_id, v_res_costo');
lines.push('            FROM productos');
lines.push("            WHERE nombre = v_final_nombre AND organizacion_id = p_org_id AND tipo_item = 'materia_prima'");
lines.push('            LIMIT 1;');
lines.push('            IF v_res_id IS NOT NULL THEN');
lines.push('                IF v_res_costo = p_costo THEN');
lines.push('                    RETURN v_res_id;');
lines.push('                ELSE');
lines.push("                    v_final_nombre := v_final_nombre || ' #2';");
lines.push('                    SELECT id INTO v_res_id');
lines.push('                    FROM productos');
lines.push("                    WHERE nombre = v_final_nombre AND organizacion_id = p_org_id AND tipo_item = 'materia_prima'");
lines.push('                    LIMIT 1;');
lines.push('                    IF v_res_id IS NOT NULL THEN');
lines.push('                        RETURN v_res_id;');
lines.push('                    END IF;');
lines.push('                END IF;');
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
lines.push('    v_prod_2e_id text;');
lines.push('    v_prod_3e_id text;');
lines.push('    v_model_2e_id uuid;');
lines.push('    v_model_3e_id uuid;');
lines.push('    v_mat_id text;');
lines.push('    v_opt_id uuid;');
lines.push('    v_opt_a36_id uuid;');
lines.push('    v_opt_hardox_id uuid;');
lines.push('    v_count int;');
lines.push('    v_sum_acero_2e numeric;');
lines.push('    v_sum_acero_3e numeric;');
lines.push('    v_sum_kits_2e numeric;');
lines.push('    v_sum_kits_3e numeric;');
lines.push('BEGIN');
lines.push('');
lines.push('    -- 1. Productos terminados y modelos Góndola 2 y 3 ejes');
lines.push('    INSERT INTO productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)');
lines.push("    SELECT 'GONDOLA 2 EJES 45 M3', 'bien', 'producto_terminado', 'PZA', 0, 0, 'Góndola 2 ejes 45 m3', v_org_id");
lines.push('    WHERE NOT EXISTS (');
lines.push('        SELECT 1 FROM productos');
lines.push("        WHERE nombre = 'GONDOLA 2 EJES 45 M3' AND organizacion_id = v_org_id AND tipo_item = 'producto_terminado'");
lines.push('    );');
lines.push('');
lines.push('    INSERT INTO productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)');
lines.push("    SELECT 'GONDOLA 3 EJES 45 M3', 'bien', 'producto_terminado', 'PZA', 0, 0, 'Góndola 3 ejes 45 m3', v_org_id");
lines.push('    WHERE NOT EXISTS (');
lines.push('        SELECT 1 FROM productos');
lines.push("        WHERE nombre = 'GONDOLA 3 EJES 45 M3' AND organizacion_id = v_org_id AND tipo_item = 'producto_terminado'");
lines.push('    );');
lines.push('');
lines.push("    SELECT id INTO v_prod_2e_id FROM productos WHERE nombre = 'GONDOLA 2 EJES 45 M3' AND organizacion_id = v_org_id AND tipo_item = 'producto_terminado' LIMIT 1;");
lines.push("    IF v_prod_2e_id IS NULL THEN RAISE EXCEPTION 'Producto terminado GONDOLA 2 EJES 45 M3 no encontrado'; END IF;");
lines.push('');
lines.push("    SELECT id INTO v_prod_3e_id FROM productos WHERE nombre = 'GONDOLA 3 EJES 45 M3' AND organizacion_id = v_org_id AND tipo_item = 'producto_terminado' LIMIT 1;");
lines.push("    IF v_prod_3e_id IS NULL THEN RAISE EXCEPTION 'Producto terminado GONDOLA 3 EJES 45 M3 no encontrado'; END IF;");
lines.push('');
lines.push('    INSERT INTO modelos (organizacion_id, producto_id, tipo, largo_ft, num_ejes)');
lines.push("    VALUES (v_org_id, v_prod_2e_id, 'gondola', NULL, 2)");
lines.push('    ON CONFLICT (organizacion_id, producto_id) DO UPDATE SET');
lines.push('        tipo = EXCLUDED.tipo,');
lines.push('        largo_ft = EXCLUDED.largo_ft,');
lines.push('        num_ejes = EXCLUDED.num_ejes;');
lines.push('');
lines.push('    INSERT INTO modelos (organizacion_id, producto_id, tipo, largo_ft, num_ejes)');
lines.push("    VALUES (v_org_id, v_prod_3e_id, 'gondola', NULL, 3)");
lines.push('    ON CONFLICT (organizacion_id, producto_id) DO UPDATE SET');
lines.push('        tipo = EXCLUDED.tipo,');
lines.push('        largo_ft = EXCLUDED.largo_ft,');
lines.push('        num_ejes = EXCLUDED.num_ejes;');
lines.push('');
lines.push("    SELECT id INTO v_model_2e_id FROM modelos WHERE producto_id = v_prod_2e_id AND organizacion_id = v_org_id LIMIT 1;");
lines.push("    SELECT id INTO v_model_3e_id FROM modelos WHERE producto_id = v_prod_3e_id AND organizacion_id = v_org_id LIMIT 1;");
lines.push("    IF v_model_2e_id IS NULL OR v_model_3e_id IS NULL THEN RAISE EXCEPTION 'Modelos de góndola no encontrados'; END IF;");
lines.push('');
lines.push('    -- 2. Limpieza previa idempotente para import-2r1f');
lines.push("    DELETE FROM receta_base WHERE modelo_id IN (v_model_2e_id, v_model_3e_id) AND notas = 'import-2r1f';");
lines.push("    DELETE FROM costos_modelo WHERE modelo_id IN (v_model_2e_id, v_model_3e_id) AND notas = 'import-2r1f';");
lines.push("    DELETE FROM opcion_costos WHERE tipo_modelo = 'gondola' AND (notas = 'import-2r1f' OR fuente = 'Factura Leolca');");
lines.push('');
lines.push('    -- Obtener IDs de las opciones tina_material para opcion_componentes');
lines.push("    SELECT oc.id INTO v_opt_a36_id FROM opciones_configuracion oc");
lines.push("    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id");
lines.push("    WHERE gc.clave = 'tina_material' AND oc.clave = 'a36' AND oc.organizacion_id = v_org_id LIMIT 1;");
lines.push("    IF v_opt_a36_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: tina_material -> a36'; END IF;");
lines.push('');
lines.push("    SELECT oc.id INTO v_opt_hardox_id FROM opciones_configuracion oc");
lines.push("    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id");
lines.push("    WHERE gc.clave = 'tina_material' AND oc.clave = 'hardox_450' AND oc.organizacion_id = v_org_id LIMIT 1;");
lines.push("    IF v_opt_hardox_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: tina_material -> hardox_450'; END IF;");
lines.push('');
lines.push("    DELETE FROM opcion_componentes WHERE opcion_id IN (v_opt_a36_id, v_opt_hardox_id) AND notas = 'import-2r1f';");
lines.push('');
lines.push('    -- 3. Inserción de materiales de acero y receta_base sección acero (49 renglones para ambos modelos)');
lines.push('');

// Procesar los 49 renglones de chasis
const chasisRows = a36.despiece_chasis || [];
if (chasisRows.length !== 49) {
  console.error(`Error: Se esperaban 49 renglones en despiece_chasis, hay ${chasisRows.length}`);
  process.exit(1);
}

const itemsChasis = [];
for (const row of chasisRows) {
  let base = row.pieza ? row.pieza.trim() : '';
  if (row.variante && row.variante.trim()) base += ' ' + row.variante.trim();
  if (row.descripcion && row.descripcion.trim()) base += ' (' + row.descripcion.trim() + ')';
  const nombre = base.toUpperCase();

  const sinPrecio = (row.precio_unitario === null || row.precio_unitario === undefined);
  const costo = sinPrecio ? 0 : Number(row.precio_unitario);
  const descripcion = sinPrecio ? 'SIN PRECIO' : (row.descripcion || row.pieza);

  itemsChasis.push({
    nombre,
    pieza: row.pieza,
    cantidad: Number(row.cantidad),
    costo,
    descripcion
  });
}

for (const item of itemsChasis) {
  lines.push(`    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, ${escapeSql(item.nombre)}, ${item.costo}, ${escapeSql(item.descripcion)});`);
  // Para modelo 2 ejes
  lines.push(`    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)`);
  lines.push(`    VALUES (v_model_2e_id, v_mat_id, ${item.cantidad}, 'fija', NULL, ${escapeSql(item.pieza)}, 'acero', NULL, 'import-2r1f');`);
  // Para modelo 3 ejes
  lines.push(`    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)`);
  lines.push(`    VALUES (v_model_3e_id, v_mat_id, ${item.cantidad}, 'fija', NULL, ${escapeSql(item.pieza)}, 'acero', NULL, 'import-2r1f');`);
}

lines.push('');
lines.push('    -- Validación de suma de acero (debe ser exactamente 103,936.96 en ambos modelos)');
lines.push('    SELECT round(coalesce(sum(rb.cantidad * p.costo), 0), 2) INTO v_sum_acero_2e');
lines.push('    FROM receta_base rb');
lines.push('    JOIN productos p ON rb.material_id = p.id');
lines.push("    WHERE rb.modelo_id = v_model_2e_id AND rb.seccion = 'acero' AND rb.notas = 'import-2r1f';");
lines.push('    IF v_sum_acero_2e <> 103936.96 THEN');
lines.push("        RAISE EXCEPTION 'El acero de la góndola 2 ejes no suma 103,936.96 (suma actual: %)', v_sum_acero_2e;");
lines.push('    END IF;');
lines.push('');
lines.push('    SELECT round(coalesce(sum(rb.cantidad * p.costo), 0), 2) INTO v_sum_acero_3e');
lines.push('    FROM receta_base rb');
lines.push('    JOIN productos p ON rb.material_id = p.id');
lines.push("    WHERE rb.modelo_id = v_model_3e_id AND rb.seccion = 'acero' AND rb.notas = 'import-2r1f';");
lines.push('    IF v_sum_acero_3e <> 103936.96 THEN');
lines.push("        RAISE EXCEPTION 'El acero de la góndola 3 ejes no suma 103,936.96 (suma actual: %)', v_sum_acero_3e;");
lines.push('    END IF;');
lines.push('');

// 4. Tina por material -> opcion_componentes
lines.push('    -- 4. Tina por material -> opcion_componentes (BOM)');
lines.push('    -- Tina A-36: 43 renglones');

const tinaA36Rows = a36.despiece_tina || [];
for (const row of tinaA36Rows) {
  let base = row.grupo ? row.grupo.trim() : '';
  if (row.opcion && row.opcion.trim() && row.opcion.trim() !== 'null') {
    base += ' (' + row.opcion.trim() + ')';
  }
  const nombre = base.toUpperCase();
  const cu = Number(row.precio_unitario) || 0;
  const descripcion = (row.opcion && row.opcion.trim() !== 'null') ? row.opcion : (row.grupo || 'TINA A-36');

  lines.push(`    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, ${escapeSql(nombre)}, ${cu}, ${escapeSql(descripcion)});`);
  lines.push(`    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, notas)`);
  lines.push(`    VALUES (v_opt_a36_id, v_mat_id, ${Number(row.cantidad) || 0}, 'fija', 'componente', NULL, ${escapeSql(row.grupo)}, 'acero', 'import-2r1f');`);
}

lines.push('');
lines.push('    -- Tina Hardox 450: 39 componentes (2 paquetes reemplazan 6 renglones, más 37 renglones individuales)');

const tinaHardoxRows = hardox.despiece_tina || [];

// Paquete 1: reemplaza filas 59, 60, 61 (índices 0, 1, 2)
const pkg1 = {
  nombre: 'PAQUETE TINA HARDOX 450 (VUELTAS TRASERAS, CUELLOS, VUELTAS FRONTALES)',
  cantidad: 1,
  costo: 80137.66,
  descripcion: 'PAQUETE TINA HARDOX (Vueltas traseras 4 pzas, Cuellos 2 pzas, Vueltas frontales 2 pzas)'
};

// Paquete 2: reemplaza filas 71, 72, 73 (índices 12, 13, 14)
const pkg2 = {
  nombre: 'PAQUETE TINA HARDOX 450 (PISO, PLACA FRONTAL, PLACA PARA TAPA)',
  cantidad: 1,
  costo: 76600.00,
  descripcion: 'PAQUETE TINA HARDOX (Piso 1 pza, Placa frontal 1 pza, Placa para tapa 1 pza)'
};

// Insertar Paquete 1
lines.push(`    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, ${escapeSql(pkg1.nombre)}, ${pkg1.costo}, ${escapeSql(pkg1.descripcion)});`);
lines.push(`    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, notas)`);
lines.push(`    VALUES (v_opt_hardox_id, v_mat_id, ${pkg1.cantidad}, 'fija', 'componente', NULL, 'Paquete vueltas/cuellos', 'acero', 'import-2r1f');`);

// Filas 62 a 70 (índices 3 a 11)
for (let i = 3; i <= 11; i++) {
  const row = tinaHardoxRows[i];
  let base = row.grupo ? row.grupo.trim() : '';
  if (row.opcion && row.opcion.trim() && row.opcion.trim() !== 'null') {
    base += ' (' + row.opcion.trim() + ')';
  }
  const nombre = base.toUpperCase();
  const cu = Number(row.precio_unitario) || 0;
  const descripcion = (row.opcion && row.opcion.trim() !== 'null') ? row.opcion : (row.grupo || 'TINA HARDOX');

  lines.push(`    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, ${escapeSql(nombre)}, ${cu}, ${escapeSql(descripcion)});`);
  lines.push(`    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, notas)`);
  lines.push(`    VALUES (v_opt_hardox_id, v_mat_id, ${Number(row.cantidad) || 0}, 'fija', 'componente', NULL, ${escapeSql(row.grupo)}, 'acero', 'import-2r1f');`);
}

// Insertar Paquete 2
lines.push(`    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, ${escapeSql(pkg2.nombre)}, ${pkg2.costo}, ${escapeSql(pkg2.descripcion)});`);
lines.push(`    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, notas)`);
lines.push(`    VALUES (v_opt_hardox_id, v_mat_id, ${pkg2.cantidad}, 'fija', 'componente', NULL, 'Paquete piso/tapa', 'acero', 'import-2r1f');`);

// Filas 74 a 101 (índices 15 a 42)
for (let i = 15; i <= 42; i++) {
  const row = tinaHardoxRows[i];
  let base = row.grupo ? row.grupo.trim() : '';
  if (row.opcion && row.opcion.trim() && row.opcion.trim() !== 'null') {
    base += ' (' + row.opcion.trim() + ')';
  }
  const nombre = base.toUpperCase();
  const cu = Number(row.precio_unitario) || 0;
  const descripcion = (row.opcion && row.opcion.trim() !== 'null') ? row.opcion : (row.grupo || 'TINA HARDOX');

  lines.push(`    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, ${escapeSql(nombre)}, ${cu}, ${escapeSql(descripcion)});`);
  lines.push(`    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, notas)`);
  lines.push(`    VALUES (v_opt_hardox_id, v_mat_id, ${Number(row.cantidad) || 0}, 'fija', 'componente', NULL, ${escapeSql(row.grupo)}, 'acero', 'import-2r1f');`);
}

lines.push('');
lines.push('    -- 5. Costos de opciones tina_material en opcion_costos');
lines.push('    -- A-36: 167,505.76');
lines.push(`    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)`);
lines.push(`    VALUES (v_org_id, v_opt_a36_id, 'gondola', 1, 'fija', 167505.76, 'Factura Leolca', 'import-2r1f')`);
lines.push(`    ON CONFLICT (opcion_id, tipo_modelo) DO UPDATE SET`);
lines.push(`        cantidad_base = EXCLUDED.cantidad_base, escala = EXCLUDED.escala, costo_unitario = EXCLUDED.costo_unitario, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;`);
lines.push('');
lines.push('    -- Hardox 450: 286,748.42');
lines.push(`    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)`);
lines.push(`    VALUES (v_org_id, v_opt_hardox_id, 'gondola', 1, 'fija', 286748.42, 'Factura Leolca', 'import-2r1f')`);
lines.push(`    ON CONFLICT (opcion_id, tipo_modelo) DO UPDATE SET`);
lines.push(`        cantidad_base = EXCLUDED.cantidad_base, escala = EXCLUDED.escala, costo_unitario = EXCLUDED.costo_unitario, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;`);
lines.push('');

// 6. Costos fijos en costos_modelo
lines.push('    -- 6. Costos fijos en costos_modelo');
lines.push('    -- Kits comunes a ambas hojas (14 conceptos, suma = 88,996.98)');

const kitsComunes = [
  { seccion: 'luz', concepto: 'Kit de luz', cantidad: 1, cu: 8500 },
  { seccion: 'pintura', concepto: 'Praimer', cantidad: 1, cu: 10000 },
  { seccion: 'tornilleria', concepto: 'Kit de tornillería para patines', cantidad: 44, cu: 15 },
  { seccion: 'tornilleria', concepto: 'Tornillería para loderas', cantidad: 8, cu: 5 },
  { seccion: 'consumibles', concepto: 'Rollo de micro tubular', cantidad: 3, cu: 995 },
  { seccion: 'consumibles', concepto: 'Rollo de sólido', cantidad: 2, cu: 995 },
  { seccion: 'consumibles', concepto: 'Tanque de CO2', cantidad: 3, cu: 925 },
  { seccion: 'consumibles', concepto: 'Consumibles', cantidad: 2, cu: 550 },
  { seccion: 'consumibles', concepto: 'Kit de limpieza', cantidad: 1, cu: 750 },
  { seccion: 'otros', concepto: 'Perno rey Holland', cantidad: 1, cu: 1200 },
  { seccion: 'otros', concepto: 'Tanque para aire', cantidad: 2, cu: 1050 },
  { seccion: 'otros', concepto: 'Pistón', cantidad: 1, cu: 55825 },
  { seccion: 'otros', concepto: 'Lodera blanca', cantidad: 2, cu: 303.99 },
  { seccion: 'otros', concepto: 'Flejes', cantidad: 2, cu: 232 }
];

// Insertar comunes para 2 ejes
for (const cm of kitsComunes) {
  lines.push(`    INSERT INTO costos_modelo (organizacion_id, modelo_id, seccion, concepto, cantidad, costo_unitario, escala, fuente, notas)`);
  lines.push(`    VALUES (v_org_id, v_model_2e_id, ${escapeSql(cm.seccion)}, ${escapeSql(cm.concepto)}, ${cm.cantidad}, ${cm.cu}, 'fija', 'Factura Leolca', 'import-2r1f');`);
}
// Insertar tornilleria de gancho para 2 ejes (en hoja A-36 cant=1, cu=49)
lines.push(`    INSERT INTO costos_modelo (organizacion_id, modelo_id, seccion, concepto, cantidad, costo_unitario, escala, fuente, notas)`);
lines.push(`    VALUES (v_org_id, v_model_2e_id, 'tornilleria', 'Kit de tornillería para gancho', 1, 49, 'fija', 'Factura Leolca (hoja A-36 con gancho Holland)', 'import-2r1f');`);

// Insertar comunes para 3 ejes
for (const cm of kitsComunes) {
  lines.push(`    INSERT INTO costos_modelo (organizacion_id, modelo_id, seccion, concepto, cantidad, costo_unitario, escala, fuente, notas)`);
  lines.push(`    VALUES (v_org_id, v_model_3e_id, ${escapeSql(cm.seccion)}, ${escapeSql(cm.concepto)}, ${cm.cantidad}, ${cm.cu}, 'fija', 'Factura Leolca', 'import-2r1f');`);
}

lines.push('');
lines.push('    -- Validación de costos_modelo (2 ejes: 89,045.98; 3 ejes: 88,996.98)');
lines.push('    SELECT round(coalesce(sum(cantidad * costo_unitario), 0), 2) INTO v_sum_kits_2e');
lines.push('    FROM costos_modelo');
lines.push("    WHERE modelo_id = v_model_2e_id AND notas = 'import-2r1f';");
lines.push('    IF v_sum_kits_2e <> 89045.98 THEN');
lines.push("        RAISE EXCEPTION 'Los costos_modelo de góndola 2 ejes no suman 89,045.98 (suma actual: %)', v_sum_kits_2e;");
lines.push('    END IF;');
lines.push('');
lines.push('    SELECT round(coalesce(sum(cantidad * costo_unitario), 0), 2) INTO v_sum_kits_3e');
lines.push('    FROM costos_modelo');
lines.push("    WHERE modelo_id = v_model_3e_id AND notas = 'import-2r1f';");
lines.push('    IF v_sum_kits_3e <> 88996.98 THEN');
lines.push("        RAISE EXCEPTION 'Los costos_modelo de góndola 3 ejes no suman 88,996.98 (suma actual: %)', v_sum_kits_3e;");
lines.push('    END IF;');
lines.push('');

// 7. Inserción de opcion_costos para Góndola (23 opciones adicionales de catálogo + 2 de tina = 25)
lines.push('    -- 7. Inserción de opcion_costos para Góndola');

const opcionesCostosGondola = [
  // suspension (por_eje, base 1): fleet_master 23118; ampro 23118; hendrickson 35844; alta_hendrickson 46783.62; phm 30000
  { grupo_clave: 'suspension', opcion_clave: 'fleet_master', costo: 23118, escala: 'por_eje', cantidad_base: 1 },
  { grupo_clave: 'suspension', opcion_clave: 'ampro', costo: 23118, escala: 'por_eje', cantidad_base: 1 },
  { grupo_clave: 'suspension', opcion_clave: 'hendrickson', costo: 35844, escala: 'por_eje', cantidad_base: 1 },
  { grupo_clave: 'suspension', opcion_clave: 'alta_hendrickson', costo: 46783.62, escala: 'por_eje', cantidad_base: 1 },
  { grupo_clave: 'suspension', opcion_clave: 'phm', costo: 30000, escala: 'por_eje', cantidad_base: 1 },

  // eje (por_eje, base 1): ampro 21692; fleet_master 19905.60
  { grupo_clave: 'eje', opcion_clave: 'ampro', costo: 21692, escala: 'por_eje', cantidad_base: 1 },
  { grupo_clave: 'eje', opcion_clave: 'fleet_master', costo: 19905.60, escala: 'por_eje', cantidad_base: 1 },

  // patin (fija, base 2): ampro 5916; hj 5646.88; holland 17980
  { grupo_clave: 'patin', opcion_clave: 'ampro', costo: 5916, escala: 'fija', cantidad_base: 2 },
  { grupo_clave: 'patin', opcion_clave: 'hj', costo: 5646.88, escala: 'fija', cantidad_base: 2 },
  { grupo_clave: 'patin', opcion_clave: 'holland', costo: 17980, escala: 'fija', cantidad_base: 2 },

  // gancho (fija, base 1): holland_8_10 6844; premier_8 11890; premier_bestia_6 28040.98
  { grupo_clave: 'gancho', opcion_clave: 'holland_8_10', costo: 6844, escala: 'fija', cantidad_base: 1 },
  { grupo_clave: 'gancho', opcion_clave: 'premier_8', costo: 11890, escala: 'fija', cantidad_base: 1 },
  { grupo_clave: 'gancho', opcion_clave: 'premier_bestia_6', costo: 28040.98, escala: 'fija', cantidad_base: 1 },

  // abs (fija, base 1): 2e_sin_retractil 22000; 2e_1_retractil 26700; 3e_1_retractil 27200; 3e_2_retractil 30500
  { grupo_clave: 'abs', opcion_clave: '2e_sin_retractil', costo: 22000, escala: 'fija', cantidad_base: 1 },
  { grupo_clave: 'abs', opcion_clave: '2e_1_retractil', costo: 26700, escala: 'fija', cantidad_base: 1 },
  { grupo_clave: 'abs', opcion_clave: '3e_1_retractil', costo: 27200, escala: 'fija', cantidad_base: 1 },
  { grupo_clave: 'abs', opcion_clave: '3e_2_retractil', costo: 30500, escala: 'fija', cantidad_base: 1 },

  // retractil (fija, base 1): paleta 15000
  { grupo_clave: 'retractil', opcion_clave: 'paleta', costo: 15000, escala: 'fija', cantidad_base: 1 },

  // rines (por_eje, base 4): acero 1550; aluminio 5500
  { grupo_clave: 'rines', opcion_clave: 'acero', costo: 1550, escala: 'por_eje', cantidad_base: 4 },
  { grupo_clave: 'rines', opcion_clave: 'aluminio', costo: 5500, escala: 'por_eje', cantidad_base: 4 },

  // llantas (por_eje, base 4): chinas 3000; firestone 8700; amulet 4225
  { grupo_clave: 'llantas', opcion_clave: 'chinas', costo: 3000, escala: 'por_eje', cantidad_base: 4 },
  { grupo_clave: 'llantas', opcion_clave: 'firestone', costo: 8700, escala: 'por_eje', cantidad_base: 4 },
  { grupo_clave: 'llantas', opcion_clave: 'amulet', costo: 4225, escala: 'por_eje', cantidad_base: 4 }
];

for (const oc of opcionesCostosGondola) {
  lines.push(`    SELECT oc.id INTO v_opt_id FROM opciones_configuracion oc`);
  lines.push(`    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id`);
  lines.push(`    WHERE gc.clave = ${escapeSql(oc.grupo_clave)} AND oc.clave = ${escapeSql(oc.opcion_clave)} AND oc.organizacion_id = v_org_id LIMIT 1;`);
  lines.push(`    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', ${escapeSql(oc.grupo_clave)}, ${escapeSql(oc.opcion_clave)}; END IF;`);
  lines.push(`    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)`);
  lines.push(`    VALUES (v_org_id, v_opt_id, 'gondola', ${oc.cantidad_base}, ${escapeSql(oc.escala)}, ${oc.costo}, 'Factura Leolca', 'import-2r1f')`);
  lines.push(`    ON CONFLICT (opcion_id, tipo_modelo) DO UPDATE SET`);
  lines.push(`        cantidad_base = EXCLUDED.cantidad_base, escala = EXCLUDED.escala, costo_unitario = EXCLUDED.costo_unitario, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;`);
}

lines.push('');
lines.push('END $$;');
lines.push('');
lines.push('DROP FUNCTION IF EXISTS pg_temp.resolver_o_crear_material_gondola(uuid, text, numeric, text);');
lines.push('');
lines.push('COMMIT;');

fs.writeFileSync(outSqlPath, lines.join('\n') + '\n', 'utf8');
console.log(`Migración generada exitosamente en ${outSqlPath}`);
console.log(`- Materiales y receta_base chasis: ${itemsChasis.length} por modelo (2 modelos = ${itemsChasis.length * 2})`);
console.log(`- Componentes tina A-36: ${tinaA36Rows.length}`);
console.log(`- Componentes tina Hardox 450: 39 (2 paquetes + 37 componentes)`);
console.log(`- Costos modelo 2 ejes: 15 conceptos (suma: 89,045.98)`);
console.log(`- Costos modelo 3 ejes: 14 conceptos (suma: 88,996.98)`);
console.log(`- Opciones de catálogo: ${opcionesCostosGondola.length} + 2 de tina = ${opcionesCostosGondola.length + 2}`);
