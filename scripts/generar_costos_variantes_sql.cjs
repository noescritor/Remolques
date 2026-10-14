/**
 * Generador de migración SQL para los costos de las variantes de plataforma (Sub-bloque 2R-1d).
 * Deriva los costos de 8 variantes a partir del modelo base 40 ft / 2 ejes (2R-1c).
 * Genera supabase/migrations/20261013_02_costos_variantes_plataforma.sql
 */

const fs = require('fs');
const path = require('path');

const outSqlPath = path.resolve(__dirname, '../supabase/migrations/20261013_02_costos_variantes_plataforma.sql');

/**
 * Tabla de cargadores de 4" (IPR DE 4") por largo según hoja BASE DAT PLANAS:
 * - 35 ft -> 34 cargadores
 * - 40 ft -> 38 cargadores (origen 40/2)
 * - 42 ft -> 40 cargadores
 * - 45 ft -> 43 cargadores
 * - 48 ft -> 46 cargadores
 *
 * El modelo 43 ft / 3 ejes se omite intencionalmente porque no existe en BASE DAT PLANAS
 * (solo hay datos para 35, 40, 42, 45 y 48 ft).
 */
const CARGADORES_POR_LARGO = {
  35: 34,
  40: 38,
  42: 40,
  45: 43,
  48: 46
};

/**
 * 8 Modelos destino a los que se derivan costos desde la 40/2:
 */
const MODELOS_DESTINO = [
  { largo_ft: 35, num_ejes: 2, cargadores: 34 },
  { largo_ft: 40, num_ejes: 3, cargadores: 38 },
  { largo_ft: 42, num_ejes: 2, cargadores: 40 },
  { largo_ft: 42, num_ejes: 3, cargadores: 40 },
  { largo_ft: 45, num_ejes: 2, cargadores: 43 },
  { largo_ft: 45, num_ejes: 3, cargadores: 43 },
  { largo_ft: 48, num_ejes: 2, cargadores: 46 },
  { largo_ft: 48, num_ejes: 3, cargadores: 46 }
];

const lines = [];

lines.push('-- Migración 20261013_02_costos_variantes_plataforma.sql');
lines.push('-- Generada automáticamente por scripts/generar_costos_variantes_sql.cjs');
lines.push('-- Sub-bloque 2R-1d: Costos de variantes de plataforma (derivadas de la 40/2)');
lines.push('-- Idempotente, ejecutable en una sola transacción.');
lines.push('');
lines.push('BEGIN;');
lines.push('');
lines.push('DO $$');
lines.push('DECLARE');
lines.push("    v_org_id uuid := '00000000-0000-0000-0000-000000000001';");
lines.push('    v_origen_id uuid;');
lines.push('    v_origen_count int;');
lines.push('    v_acero_count int;');
lines.push('    v_kits_count int;');
lines.push('    v_proc_count int;');
lines.push('    v_cargador_mat_id text;');
lines.push('    v_cargador_count int;');
lines.push('    v_dest_count int;');
lines.push('    v_destino_id uuid;');
lines.push('    v_destinos_ids uuid[] := ARRAY[]::uuid[];');
lines.push('BEGIN');
lines.push('');
lines.push('    -- 1. Validar modelo origen (plataforma 40 ft / 2 ejes)');
lines.push("    SELECT count(*) INTO v_origen_count FROM modelos WHERE tipo = 'plataforma' AND largo_ft = 40 AND num_ejes = 2 AND organizacion_id = v_org_id;");
lines.push('    IF v_origen_count <> 1 THEN');
lines.push("        RAISE EXCEPTION 'Se esperaba exactamente 1 modelo origen plataforma 40 ft / 2 ejes, pero se encontraron %', v_origen_count;");
lines.push('    END IF;');
lines.push("    SELECT id INTO v_origen_id FROM modelos WHERE tipo = 'plataforma' AND largo_ft = 40 AND num_ejes = 2 AND organizacion_id = v_org_id;");
lines.push('');
lines.push('    -- 2. Validar que el origen tenga exactamente 61 renglones de receta_base con seccion=acero');
lines.push("    SELECT count(*) INTO v_acero_count FROM receta_base WHERE modelo_id = v_origen_id AND seccion = 'acero';");
lines.push('    IF v_acero_count <> 61 THEN');
lines.push("        RAISE EXCEPTION 'El modelo origen 40/2 no tiene exactamente 61 renglones de acero en receta_base (encontrados: %)', v_acero_count;");
lines.push('    END IF;');
lines.push('');
lines.push('    -- 3. Validar material determinista del cargador de 4"');
lines.push("    SELECT id INTO v_cargador_mat_id FROM productos WHERE nombre = 'CARGADOR (IPR DE 4\")' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima' LIMIT 1;");
lines.push('    IF v_cargador_mat_id IS NULL THEN');
lines.push("        RAISE EXCEPTION 'Material determinista de cargador no encontrado: CARGADOR (IPR DE 4\")';");
lines.push('    END IF;');
lines.push('');
lines.push('    SELECT count(*) INTO v_cargador_count FROM receta_base WHERE modelo_id = v_origen_id AND material_id = v_cargador_mat_id AND seccion = \'acero\';');
lines.push('    IF v_cargador_count <> 1 THEN');
lines.push("        RAISE EXCEPTION 'Se esperaba exactamente 1 renglón del cargador en receta_base del origen 40/2, pero se encontraron %', v_cargador_count;");
lines.push('    END IF;');
lines.push('');
lines.push('    -- 4. Validar que el origen tenga 12 costos_modelo y 80 procesos_manufactura');
lines.push('    SELECT count(*) INTO v_kits_count FROM costos_modelo WHERE modelo_id = v_origen_id;');
lines.push('    IF v_kits_count <> 12 THEN');
lines.push("        RAISE EXCEPTION 'El modelo origen 40/2 debe tener 12 costos_modelo, encontrados %', v_kits_count;");
lines.push('    END IF;');
lines.push('');
lines.push('    SELECT count(*) INTO v_proc_count FROM procesos_manufactura WHERE modelo_id = v_origen_id;');
lines.push('    IF v_proc_count <> 80 THEN');
lines.push("        RAISE EXCEPTION 'El modelo origen 40/2 debe tener 80 procesos_manufactura, encontrados %', v_proc_count;");
lines.push('    END IF;');
lines.push('');
lines.push('    -- 5. Validar y recolectar IDs de los 8 modelos destino');

for (const dest of MODELOS_DESTINO) {
  lines.push(`    SELECT count(*) INTO v_dest_count FROM modelos WHERE tipo = 'plataforma' AND largo_ft = ${dest.largo_ft} AND num_ejes = ${dest.num_ejes} AND organizacion_id = v_org_id;`);
  lines.push(`    IF v_dest_count <> 1 THEN`);
  lines.push(`        RAISE EXCEPTION 'Se esperaba exactamente 1 modelo plataforma ${dest.largo_ft} ft / ${dest.num_ejes} ejes, pero se encontraron %', v_dest_count;`);
  lines.push(`    END IF;`);
  lines.push(`    SELECT id INTO v_destino_id FROM modelos WHERE tipo = 'plataforma' AND largo_ft = ${dest.largo_ft} AND num_ejes = ${dest.num_ejes} AND organizacion_id = v_org_id;`);
  lines.push(`    v_destinos_ids := array_append(v_destinos_ids, v_destino_id);`);
}

lines.push('');
lines.push("    -- 6. Limpieza idempotente previa: SOLO notas = 'import-2r1d' para los modelos destino");
lines.push("    DELETE FROM receta_base WHERE notas = 'import-2r1d' AND modelo_id = ANY(v_destinos_ids);");
lines.push("    DELETE FROM costos_modelo WHERE notas = 'import-2r1d' AND modelo_id = ANY(v_destinos_ids);");
lines.push("    DELETE FROM procesos_manufactura WHERE notas = 'import-2r1d' AND modelo_id = ANY(v_destinos_ids);");
lines.push('');
lines.push('    -- 7. Copia e inserción para cada modelo destino');

for (const dest of MODELOS_DESTINO) {
  lines.push(`    -- Destino: Plataforma ${dest.largo_ft} ft / ${dest.num_ejes} ejes (cargadores: ${dest.cargadores})`);
  lines.push(`    SELECT id INTO v_destino_id FROM modelos WHERE tipo = 'plataforma' AND largo_ft = ${dest.largo_ft} AND num_ejes = ${dest.num_ejes} AND organizacion_id = v_org_id;`);
  lines.push('');
  lines.push(`    -- 7.1 receta_base acero (61 renglones, cargador con cantidad ${dest.cargadores})`);
  lines.push(`    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)`);
  lines.push(`    SELECT`);
  lines.push(`        v_destino_id,`);
  lines.push(`        material_id,`);
  lines.push(`        CASE WHEN material_id = v_cargador_mat_id THEN ${dest.cargadores} ELSE cantidad END,`);
  lines.push(`        escala,`);
  lines.push(`        paso,`);
  lines.push(`        uso,`);
  lines.push(`        seccion,`);
  lines.push(`        condicion,`);
  lines.push(`        'import-2r1d'`);
  lines.push(`    FROM receta_base`);
  lines.push(`    WHERE modelo_id = v_origen_id AND seccion = 'acero';`);
  lines.push('');
  lines.push(`    -- 7.2 costos_modelo (12 renglones)`);
  lines.push(`    INSERT INTO costos_modelo (organizacion_id, modelo_id, seccion, concepto, cantidad, costo_unitario, escala, fuente, notas)`);
  lines.push(`    SELECT`);
  lines.push(`        v_org_id,`);
  lines.push(`        v_destino_id,`);
  lines.push(`        seccion,`);
  lines.push(`        concepto,`);
  lines.push(`        cantidad,`);
  lines.push(`        costo_unitario,`);
  lines.push(`        escala,`);
  lines.push(`        fuente,`);
  lines.push(`        'import-2r1d'`);
  lines.push(`    FROM costos_modelo`);
  lines.push(`    WHERE modelo_id = v_origen_id;`);
  lines.push('');
  lines.push(`    -- 7.3 procesos_manufactura (80 renglones)`);
  lines.push(`    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)`);
  lines.push(`    SELECT`);
  lines.push(`        v_org_id,`);
  lines.push(`        v_destino_id,`);
  lines.push(`        orden,`);
  lines.push(`        proceso,`);
  lines.push(`        subproceso,`);
  lines.push(`        minutos,`);
  lines.push(`        tarifa_hora,`);
  lines.push(`        'import-2r1d'`);
  lines.push(`    FROM procesos_manufactura`);
  lines.push(`    WHERE modelo_id = v_origen_id;`);
  lines.push('');
  lines.push(`    -- 7.4 Actualizar modelo con costos_derivados_de`);
  lines.push(`    UPDATE modelos SET costos_derivados_de = v_origen_id WHERE id = v_destino_id;`);
  lines.push('');
}

lines.push('END $$;');
lines.push('');
lines.push('COMMIT;');
lines.push('');

const outputContent = lines.join('\n');
fs.writeFileSync(outSqlPath, outputContent, 'utf8');

console.log(`Migración generada exitosamente en ${outSqlPath}`);
console.log(`- Modelo origen: Plataforma 40 ft / 2 ejes`);
console.log(`- Modelos destino procesados: ${MODELOS_DESTINO.length}`);
for (const dest of MODELOS_DESTINO) {
  console.log(`  • Plataforma ${dest.largo_ft}/${dest.num_ejes}: 61 receta_base (cargadores=${dest.cargadores}), 12 costos_modelo, 80 procesos`);
}
console.log(`- Total renglones a insertar: ${MODELOS_DESTINO.length} x 153 = ${MODELOS_DESTINO.length * 153}`);
console.log(`- Modelo 43/3: OMITIDO (no presente en BASE DAT PLANAS; pendiente de validar con el dueño)`);
