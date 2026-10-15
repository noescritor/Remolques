/**
 * scripts/generar_costos_respaldo_sql.cjs
 * Sub-bloque 2R-1g: Costos de respaldo para las opciones que la Factura no cubre
 *
 * Genera supabase/migrations/20261015_01_costos_respaldo.sql
 * Idempotente, ejecutable en una sola transacción.
 */

const fs = require('fs');
const path = require('path');

const outSqlPath = path.join(__dirname, '..', 'supabase', 'migrations', '20261015_01_costos_respaldo.sql');

function escapeSql(str) {
  if (str === null || str === undefined) return 'NULL';
  return `'${String(str).replace(/'/g, "''")}'`;
}

// Definición de opciones a insertar según prompt A.1
const opcionesRespaldo = [
  // ==========================================
  // 1. FUENTE: 'Factura Leolca'
  // ==========================================
  {
    grupo: 'piso',
    opcion: 'pino',
    cantidad_base: 1,
    escala: 'por_largo',
    costo: 22000,
    fuente: 'Factura Leolca',
    tipos: ['plataforma'],
    guardiaCoherencia: true
  },
  {
    grupo: 'piso',
    opcion: 'encino',
    cantidad_base: 1,
    escala: 'por_largo',
    costo: 22000,
    fuente: 'Factura Leolca',
    tipos: ['plataforma'],
    guardiaCoherencia: true
  },
  {
    grupo: 'piso',
    opcion: 'plastico_cafe',
    cantidad_base: 1,
    escala: 'por_largo',
    costo: 35000,
    fuente: 'Factura Leolca',
    tipos: ['plataforma'],
    guardiaCoherencia: true
  },
  {
    grupo: 'riel',
    opcion: 'con_riel',
    cantidad_base: 1,
    escala: 'fija',
    costo: 5808,
    fuente: 'Factura Leolca',
    tipos: ['plataforma'],
    guardiaCoherencia: false // Excepción A.2: Factura 5808 vs tarifario 5805
  },
  {
    grupo: 'matracas',
    opcion: 'corrediza',
    cantidad_base: 12,
    escala: 'fija',
    costo: 307.40,
    fuente: 'Factura Leolca',
    tipos: ['plataforma'],
    guardiaCoherencia: false // Excepción A.2
  },
  {
    grupo: 'adicionales',
    opcion: 'polinera_grande',
    cantidad_base: 1,
    escala: 'fija',
    costo: 6000,
    fuente: 'Factura Leolca',
    tipos: ['plataforma', 'dolly', 'gondola'],
    guardiaCoherencia: true
  },
  {
    grupo: 'adicionales',
    opcion: 'bicicletera',
    cantidad_base: 1,
    escala: 'fija',
    costo: 2004,
    fuente: 'Factura Leolca',
    tipos: ['plataforma', 'dolly', 'gondola'],
    guardiaCoherencia: false // Excepción A.2: Factura 2004 vs tarifario 5000
  },
  {
    grupo: 'adicionales',
    opcion: 'canastilla',
    cantidad_base: 1,
    escala: 'fija',
    costo: 5784.50,
    fuente: 'Factura Leolca',
    tipos: ['plataforma', 'dolly', 'gondola'],
    guardiaCoherencia: false // Excepción A.2: Factura 5784.50 vs tarifario 8000
  },

  // ==========================================
  // 2. FUENTE: 'Tarifario'
  // ==========================================
  {
    grupo: 'suspension',
    opcion: 'hj_alta',
    cantidad_base: 1,
    escala: 'por_eje',
    costo: 24550,
    fuente: 'Tarifario',
    tipos: ['plataforma', 'dolly', 'gondola'],
    guardiaCoherencia: false // Excepción A.2: 24550 vs 28478 (neto sin iva 1.16)
  },
  {
    grupo: 'piso',
    opcion: 'plastico_negro',
    cantidad_base: 1,
    escala: 'por_largo',
    costo: 36182.72,
    fuente: 'Tarifario',
    tipos: ['plataforma'],
    guardiaCoherencia: true
  },
  {
    grupo: 'piso',
    opcion: 'laminado',
    cantidad_base: 1,
    escala: 'por_largo',
    costo: 28224,
    fuente: 'Tarifario',
    tipos: ['plataforma'],
    guardiaCoherencia: true
  },
  {
    grupo: 'piso',
    opcion: 'antiderrapante',
    cantidad_base: 1,
    escala: 'por_largo',
    costo: 22000,
    fuente: 'Tarifario',
    tipos: ['plataforma'],
    guardiaCoherencia: true
  },
  {
    grupo: 'redilas',
    opcion: '70',
    cantidad_base: 1,
    escala: 'fija',
    costo: 35000,
    fuente: 'Tarifario',
    tipos: ['plataforma'],
    guardiaCoherencia: true
  },
  {
    grupo: 'redilas',
    opcion: '75',
    cantidad_base: 1,
    escala: 'fija',
    costo: 35500,
    fuente: 'Tarifario',
    tipos: ['plataforma'],
    guardiaCoherencia: true
  },
  {
    grupo: 'redilas',
    opcion: '80',
    cantidad_base: 1,
    escala: 'fija',
    costo: 36000,
    fuente: 'Tarifario',
    tipos: ['plataforma'],
    guardiaCoherencia: true
  },
  {
    grupo: 'redilas',
    opcion: '100',
    cantidad_base: 1,
    escala: 'fija',
    costo: 42000,
    fuente: 'Tarifario',
    tipos: ['plataforma'],
    guardiaCoherencia: true
  },
  {
    grupo: 'retractil',
    opcion: 'chico',
    cantidad_base: 1,
    escala: 'fija',
    costo: 15000,
    fuente: 'Tarifario',
    tipos: ['plataforma'],
    guardiaCoherencia: true
  },
  {
    grupo: 'retractil',
    opcion: 'grande',
    cantidad_base: 1,
    escala: 'fija',
    costo: 15000,
    fuente: 'Tarifario',
    tipos: ['plataforma'],
    guardiaCoherencia: true
  },
  {
    grupo: 'plafones',
    opcion: 'ambar_laterales',
    cantidad_base: 1,
    escala: 'fija',
    costo: 168.20,
    fuente: 'Tarifario',
    tipos: ['plataforma'],
    guardiaCoherencia: true
  },
  {
    grupo: 'plafones',
    opcion: 'ambar_estribo',
    cantidad_base: 1,
    escala: 'fija',
    costo: 168.20,
    fuente: 'Tarifario',
    tipos: ['plataforma'],
    guardiaCoherencia: true
  },
  {
    grupo: 'plafones',
    opcion: 'rojo_laterales',
    cantidad_base: 1,
    escala: 'fija',
    costo: 168.20,
    fuente: 'Tarifario',
    tipos: ['plataforma'],
    guardiaCoherencia: true
  },
  {
    grupo: 'plafones',
    opcion: 'rojo_estribo',
    cantidad_base: 1,
    escala: 'fija',
    costo: 168.20,
    fuente: 'Tarifario',
    tipos: ['plataforma'],
    guardiaCoherencia: true
  },
  {
    grupo: 'llantas',
    opcion: 'bf_goodrich',
    cantidad_base: 4,
    escala: 'por_eje',
    costo: 11750,
    fuente: 'Tarifario',
    tipos: ['plataforma', 'dolly', 'gondola'],
    guardiaCoherencia: true
  },
  {
    grupo: 'llantas',
    opcion: 'cerex',
    cantidad_base: 4,
    escala: 'por_eje',
    costo: 3586,
    fuente: 'Tarifario',
    tipos: ['plataforma', 'dolly', 'gondola'],
    guardiaCoherencia: true
  },
  {
    grupo: 'llantas',
    opcion: 'eudemon',
    cantidad_base: 4,
    escala: 'por_eje',
    costo: 5400,
    fuente: 'Tarifario',
    tipos: ['plataforma', 'dolly', 'gondola'],
    guardiaCoherencia: true
  },
  {
    grupo: 'llantas',
    opcion: 'royal_black',
    cantidad_base: 4,
    escala: 'por_eje',
    costo: 5600,
    fuente: 'Tarifario',
    tipos: ['plataforma', 'dolly', 'gondola'],
    guardiaCoherencia: true
  },
  {
    grupo: 'llantas',
    opcion: 'valiant',
    cantidad_base: 4,
    escala: 'por_eje',
    costo: 3581,
    fuente: 'Tarifario',
    tipos: ['plataforma', 'dolly', 'gondola'],
    guardiaCoherencia: true
  },
  {
    grupo: 'adicionales',
    opcion: 'barrenado_chasis',
    cantidad_base: 1,
    escala: 'fija',
    costo: 1250,
    fuente: 'Tarifario',
    tipos: ['plataforma', 'dolly', 'gondola'],
    guardiaCoherencia: true
  },
  {
    grupo: 'adicionales',
    opcion: 'caja_auxiliar',
    cantidad_base: 1,
    escala: 'fija',
    costo: 1500,
    fuente: 'Tarifario',
    tipos: ['plataforma', 'dolly', 'gondola'],
    guardiaCoherencia: true
  },
  {
    grupo: 'adicionales',
    opcion: 'caja_herr_chica',
    cantidad_base: 1,
    escala: 'fija',
    costo: 9500,
    fuente: 'Tarifario',
    tipos: ['plataforma', 'dolly', 'gondola'],
    guardiaCoherencia: true
  },
  {
    grupo: 'adicionales',
    opcion: 'candados',
    cantidad_base: 1,
    escala: 'fija',
    costo: 1450,
    fuente: 'Tarifario',
    tipos: ['plataforma', 'dolly', 'gondola'],
    guardiaCoherencia: true
  },
  {
    grupo: 'adicionales',
    opcion: 'jalon',
    cantidad_base: 1,
    escala: 'fija',
    costo: 3768,
    fuente: 'Tarifario',
    tipos: ['plataforma', 'dolly', 'gondola'],
    guardiaCoherencia: true
  },
  {
    grupo: 'adicionales',
    opcion: 'lodera_centro',
    cantidad_base: 1,
    escala: 'fija',
    costo: 874,
    fuente: 'Tarifario',
    tipos: ['plataforma', 'dolly', 'gondola'],
    guardiaCoherencia: true
  },
  {
    grupo: 'adicionales',
    opcion: 'multimodal',
    cantidad_base: 1,
    escala: 'fija',
    costo: 50000,
    fuente: 'Tarifario',
    tipos: ['plataforma', 'dolly', 'gondola'],
    guardiaCoherencia: true
  },
  {
    grupo: 'adicionales',
    opcion: 'pata_elefante',
    cantidad_base: 1,
    escala: 'fija',
    costo: 3250,
    fuente: 'Tarifario',
    tipos: ['plataforma', 'dolly', 'gondola'],
    guardiaCoherencia: true
  },
  {
    grupo: 'adicionales',
    opcion: 'polinera_atravesada',
    cantidad_base: 1,
    escala: 'fija',
    costo: 6000,
    fuente: 'Tarifario',
    tipos: ['plataforma', 'dolly', 'gondola'],
    guardiaCoherencia: true
  },
  {
    grupo: 'adicionales',
    opcion: 'polinera_bicicletera',
    cantidad_base: 1,
    escala: 'fija',
    costo: 8000,
    fuente: 'Tarifario',
    tipos: ['plataforma', 'dolly', 'gondola'],
    guardiaCoherencia: true
  },
  {
    grupo: 'adicionales',
    opcion: 'polinera_puerta',
    cantidad_base: 1,
    escala: 'fija',
    costo: 10000,
    fuente: 'Tarifario',
    tipos: ['plataforma', 'dolly', 'gondola'],
    guardiaCoherencia: true
  },
  {
    grupo: 'adicionales',
    opcion: 'portallantas_extra',
    cantidad_base: 1,
    escala: 'fija',
    costo: 3500,
    fuente: 'Tarifario',
    tipos: ['plataforma', 'dolly', 'gondola'],
    guardiaCoherencia: true
  },
  {
    grupo: 'adicionales',
    opcion: 'refuerzos',
    cantidad_base: 1,
    escala: 'fija',
    costo: 14786,
    fuente: 'Tarifario',
    tipos: ['plataforma', 'dolly', 'gondola'],
    guardiaCoherencia: true
  },
  {
    grupo: 'adicionales',
    opcion: 'sistema_psi',
    cantidad_base: 1,
    escala: 'fija',
    costo: 20000,
    fuente: 'Tarifario',
    tipos: ['plataforma', 'dolly', 'gondola'],
    guardiaCoherencia: true
  },

  // ==========================================
  // 3. FUENTE: 'Supuesto: sin costo adicional'
  // ==========================================
  // Colores (16 opciones, costo 0)
  ...[
    'rojo_claro', 'rojo', 'rojo_coca_cola', 'rojo_bermellon', 'vino', 'negro',
    'anaranjado_con_borda_blanca', 'azul_rey', 'blanco', 'gris', 'naranja',
    'amarillo', 'rosa', 'verde', 'morado', 'cafe'
  ].map(colClave => ({
    grupo: 'color',
    opcion: colClave,
    cantidad_base: 1,
    escala: 'fija',
    costo: 0,
    fuente: 'Supuesto: sin costo adicional',
    tipos: ['plataforma', 'dolly', 'gondola'],
    guardiaCoherencia: false
  })),

  // Pinturas (3 marcas, costo 0)
  ...['axalta', 'ppg', 'sherwin_williams'].map(pntClave => ({
    grupo: 'pintura',
    opcion: pntClave,
    cantidad_base: 1,
    escala: 'fija',
    costo: 0,
    fuente: 'Supuesto: sin costo adicional',
    tipos: ['plataforma', 'dolly', 'gondola'],
    guardiaCoherencia: false
  }))
];

function generarSql() {
  const lines = [];

  lines.push('-- Sub-bloque 2R-1g: Costos de respaldo para opciones no cubiertas por Factura');
  lines.push('-- Generado automáticamente por scripts/generar_costos_respaldo_sql.cjs');
  lines.push('-- Idempotente, ejecutable en una sola transacción.');
  lines.push('');
  lines.push('BEGIN;');
  lines.push('');
  lines.push('DO $$');
  lines.push('DECLARE');
  lines.push("    v_org_id uuid := '00000000-0000-0000-0000-000000000001';");
  lines.push('    v_opt_id uuid;');
  lines.push('    v_pv numeric;');
  lines.push('BEGIN');
  lines.push('');
  lines.push('    -- 1. Borrado idempotente previo de import-2r1g únicamente');
  lines.push("    DELETE FROM opcion_costos WHERE notas = 'import-2r1g';");
  lines.push('');
  lines.push('    -- 2. Inserción con resolución y guardia de coherencia');

  for (const item of opcionesRespaldo) {
    lines.push('');
    lines.push(`    -- Opción: ${item.grupo} / ${item.opcion} (${item.fuente}, costo: ${item.costo})`);
    lines.push(`    SELECT oc.id, oc.precio_venta INTO v_opt_id, v_pv`);
    lines.push(`    FROM opciones_configuracion oc`);
    lines.push(`    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id`);
    lines.push(`    WHERE gc.clave = ${escapeSql(item.grupo)} AND oc.clave = ${escapeSql(item.opcion)} AND oc.organizacion_id = v_org_id LIMIT 1;`);
    lines.push(`    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', ${escapeSql(item.grupo)}, ${escapeSql(item.opcion)}; END IF;`);

    if (item.guardiaCoherencia) {
      lines.push(`    IF v_pv IS DISTINCT FROM ${item.costo} THEN`);
      lines.push(`        RAISE EXCEPTION 'Guardia de coherencia falló en % / %: precio_venta en catálogo es %, pero se esperaba %', ${escapeSql(item.grupo)}, ${escapeSql(item.opcion)}, v_pv, ${item.costo};`);
      lines.push(`    END IF;`);
    }

    for (const tipo of item.tipos) {
      lines.push(`    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)`);
      lines.push(`    SELECT v_org_id, v_opt_id, ${escapeSql(tipo)}, ${item.cantidad_base}, ${escapeSql(item.escala)}, ${item.costo}, ${escapeSql(item.fuente)}, 'import-2r1g'`);
      lines.push(`    WHERE NOT EXISTS (`);
      lines.push(`        SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_id AND tipo_modelo = ${escapeSql(tipo)}`);
      lines.push(`    );`);
    }
  }

  lines.push('');
  lines.push('END $$;');
  lines.push('');
  lines.push('COMMIT;');

  return lines.join('\n') + '\n';
}

const sql = generarSql();
fs.writeFileSync(outSqlPath, sql, 'utf8');

console.log(`Migración generada exitosamente en ${outSqlPath}`);
console.log(`- Total opciones únicas: ${opcionesRespaldo.length}`);
let totalRows = 0;
opcionesRespaldo.forEach(o => totalRows += o.tipos.length);
console.log(`- Total filas a insertar (si no existen): ${totalRows}`);
