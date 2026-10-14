/**
 * Generador de fixture para pruebas de costeo de la Góndola (Sub-bloque 2R-1f).
 * Lee docs/factura-leolca/extraccion_factura_leolca.json y genera:
 * supabase/functions/make-server-feea4382/motor/fixtures/datos_costeo_gondola.json
 */

const fs = require('fs');
const path = require('path');

const jsonPath = path.resolve(__dirname, '../docs/factura-leolca/extraccion_factura_leolca.json');
const outFixturePath = path.resolve(__dirname, '../supabase/functions/make-server-feea4382/motor/fixtures/datos_costeo_gondola.json');

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

// 1. Modelos
const modelo2e = {
  id: '00000000-0000-0000-0000-000000000030',
  nombre: 'GONDOLA 2 EJES 45 M3',
  tipo: 'gondola',
  largo_ft: 0,
  num_ejes: 2
};

const modelo3e = {
  id: '00000000-0000-0000-0000-000000000031',
  nombre: 'GONDOLA 3 EJES 45 M3',
  tipo: 'gondola',
  largo_ft: 0,
  num_ejes: 3
};

// 2. Acero chasis (49 renglones compartidos por ambos modelos)
const chasisRows = a36.despiece_chasis || [];
const receta_acero = [];
for (let idx = 0; idx < chasisRows.length; idx++) {
  const row = chasisRows[idx];
  let base = row.pieza ? row.pieza.trim() : '';
  if (row.variante && row.variante.trim()) base += ' ' + row.variante.trim();
  if (row.descripcion && row.descripcion.trim()) base += ' (' + row.descripcion.trim() + ')';
  const nombre = base.toUpperCase();

  const sinPrecio = (row.precio_unitario === null || row.precio_unitario === undefined);
  const costo = sinPrecio ? 0 : Number(row.precio_unitario);
  const descripcion = sinPrecio ? 'SIN PRECIO' : (row.descripcion || row.pieza);

  receta_acero.push({
    material_id: `mat-gondola-chasis-${idx + 1}`,
    nombre,
    cantidad: Number(row.cantidad),
    escala: 'fija',
    costo,
    descripcion
  });
}

// 3. Costos fijos (kits)
const kitsComunes = [
  { seccion: 'luz', concepto: 'Kit de luz', cantidad: 1, costo_unitario: 8500, escala: 'fija' },
  { seccion: 'pintura', concepto: 'Praimer', cantidad: 1, costo_unitario: 10000, escala: 'fija' },
  { seccion: 'tornilleria', concepto: 'Kit de tornillería para patines', cantidad: 44, costo_unitario: 15, escala: 'fija' },
  { seccion: 'tornilleria', concepto: 'Tornillería para loderas', cantidad: 8, costo_unitario: 5, escala: 'fija' },
  { seccion: 'consumibles', concepto: 'Rollo de micro tubular', cantidad: 3, costo_unitario: 995, escala: 'fija' },
  { seccion: 'consumibles', concepto: 'Rollo de sólido', cantidad: 2, costo_unitario: 995, escala: 'fija' },
  { seccion: 'consumibles', concepto: 'Tanque de CO2', cantidad: 3, costo_unitario: 925, escala: 'fija' },
  { seccion: 'consumibles', concepto: 'Consumibles', cantidad: 2, costo_unitario: 550, escala: 'fija' },
  { seccion: 'consumibles', concepto: 'Kit de limpieza', cantidad: 1, costo_unitario: 750, escala: 'fija' },
  { seccion: 'otros', concepto: 'Perno rey Holland', cantidad: 1, costo_unitario: 1200, escala: 'fija' },
  { seccion: 'otros', concepto: 'Tanque para aire', cantidad: 2, costo_unitario: 1050, escala: 'fija' },
  { seccion: 'otros', concepto: 'Pistón', cantidad: 1, costo_unitario: 55825, escala: 'fija' },
  { seccion: 'otros', concepto: 'Lodera blanca', cantidad: 2, costo_unitario: 303.99, escala: 'fija' },
  { seccion: 'otros', concepto: 'Flejes', cantidad: 2, costo_unitario: 232, escala: 'fija' }
];

const costos_modelo_2e = [
  ...kitsComunes,
  { seccion: 'tornilleria', concepto: 'Kit de tornillería para gancho', cantidad: 1, costo_unitario: 49, escala: 'fija' }
];

const costos_modelo_3e = [
  ...kitsComunes
];

// 4. Mano de obra (vacío para góndola: se maneja como ganancia fija de 100,000)
const procesos = [];

// 5. Opciones de costo para Góndola (25 opciones catalogadas)
const opcion_costos = [
  // tina_material (2)
  { grupo_clave: 'tina_material', opcion_clave: 'a36', cantidad_base: 1, escala: 'fija', costo_unitario: 167505.76 },
  { grupo_clave: 'tina_material', opcion_clave: 'hardox_450', cantidad_base: 1, escala: 'fija', costo_unitario: 286748.42 },

  // suspension (5)
  { grupo_clave: 'suspension', opcion_clave: 'fleet_master', cantidad_base: 1, escala: 'por_eje', costo_unitario: 23118 },
  { grupo_clave: 'suspension', opcion_clave: 'ampro', cantidad_base: 1, escala: 'por_eje', costo_unitario: 23118 },
  { grupo_clave: 'suspension', opcion_clave: 'hendrickson', cantidad_base: 1, escala: 'por_eje', costo_unitario: 35844 },
  { grupo_clave: 'suspension', opcion_clave: 'alta_hendrickson', cantidad_base: 1, escala: 'por_eje', costo_unitario: 46783.62 },
  { grupo_clave: 'suspension', opcion_clave: 'phm', cantidad_base: 1, escala: 'por_eje', costo_unitario: 30000 },

  // eje (2)
  { grupo_clave: 'eje', opcion_clave: 'ampro', cantidad_base: 1, escala: 'por_eje', costo_unitario: 21692 },
  { grupo_clave: 'eje', opcion_clave: 'fleet_master', cantidad_base: 1, escala: 'por_eje', costo_unitario: 19905.60 },

  // patin (3)
  { grupo_clave: 'patin', opcion_clave: 'ampro', cantidad_base: 2, escala: 'fija', costo_unitario: 5916 },
  { grupo_clave: 'patin', opcion_clave: 'hj', cantidad_base: 2, escala: 'fija', costo_unitario: 5646.88 },
  { grupo_clave: 'patin', opcion_clave: 'holland', cantidad_base: 2, escala: 'fija', costo_unitario: 17980 },

  // gancho (3)
  { grupo_clave: 'gancho', opcion_clave: 'holland_8_10', cantidad_base: 1, escala: 'fija', costo_unitario: 6844 },
  { grupo_clave: 'gancho', opcion_clave: 'premier_8', cantidad_base: 1, escala: 'fija', costo_unitario: 11890 },
  { grupo_clave: 'gancho', opcion_clave: 'premier_bestia_6', cantidad_base: 1, escala: 'fija', costo_unitario: 28040.98 },

  // abs (4)
  { grupo_clave: 'abs', opcion_clave: '2e_sin_retractil', cantidad_base: 1, escala: 'fija', costo_unitario: 22000 },
  { grupo_clave: 'abs', opcion_clave: '2e_1_retractil', cantidad_base: 1, escala: 'fija', costo_unitario: 26700 },
  { grupo_clave: 'abs', opcion_clave: '3e_1_retractil', cantidad_base: 1, escala: 'fija', costo_unitario: 27200 },
  { grupo_clave: 'abs', opcion_clave: '3e_2_retractil', cantidad_base: 1, escala: 'fija', costo_unitario: 30500 },

  // retractil (1)
  { grupo_clave: 'retractil', opcion_clave: 'paleta', cantidad_base: 1, escala: 'fija', costo_unitario: 15000 },

  // rines (2)
  { grupo_clave: 'rines', opcion_clave: 'acero', cantidad_base: 4, escala: 'por_eje', costo_unitario: 1550 },
  { grupo_clave: 'rines', opcion_clave: 'aluminio', cantidad_base: 4, escala: 'por_eje', costo_unitario: 5500 },

  // llantas (3)
  { grupo_clave: 'llantas', opcion_clave: 'chinas', cantidad_base: 4, escala: 'por_eje', costo_unitario: 3000 },
  { grupo_clave: 'llantas', opcion_clave: 'firestone', cantidad_base: 4, escala: 'por_eje', costo_unitario: 8700 },
  { grupo_clave: 'llantas', opcion_clave: 'amulet', cantidad_base: 4, escala: 'por_eje', costo_unitario: 4225 }
];

// 6. Grupos
const grupos = [
  { id: 'grp-tina_material', clave: 'tina_material', nombre: 'Material de tina', seleccion: 'unica', regla: null },
  { id: 'grp-suspension', clave: 'suspension', nombre: 'Suspensión', seleccion: 'unica', regla: null },
  { id: 'grp-eje', clave: 'eje', nombre: 'Ejes', seleccion: 'unica', regla: null },
  { id: 'grp-patin', clave: 'patin', nombre: 'Patines', seleccion: 'unica', regla: null },
  { id: 'grp-gancho', clave: 'gancho', nombre: 'Gancho de arrastre', seleccion: 'unica', regla: null },
  { id: 'grp-abs', clave: 'abs', nombre: 'Sistema de frenos ABS', seleccion: 'unica', regla: null },
  { id: 'grp-retractil', clave: 'retractil', nombre: 'Sistema retráctil', seleccion: 'multiple', regla: null },
  { id: 'grp-rines', clave: 'rines', nombre: 'Rines', seleccion: 'unica_con_cantidad', regla: null },
  { id: 'grp-llantas', clave: 'llantas', nombre: 'Llantas', seleccion: 'unica_con_cantidad', regla: null }
];

// 7. Ganancia
const ganancia = 100000;

const fixture = {
  gondola_a36: {
    modelo: modelo2e,
    receta_acero,
    costos_modelo: costos_modelo_2e,
    procesos,
    opcion_costos,
    grupos,
    ganancia
  },
  gondola_hardox450: {
    modelo: modelo3e,
    receta_acero,
    costos_modelo: costos_modelo_3e,
    procesos,
    opcion_costos,
    grupos,
    ganancia
  }
};

fs.writeFileSync(outFixturePath, JSON.stringify(fixture, null, 2) + '\n', 'utf8');
console.log(`Fixture generado exitosamente en ${outFixturePath}`);
console.log(`- Acero chasis: ${receta_acero.reduce((sum, item) => sum + item.cantidad * (item.costo || 0), 0).toFixed(2)}`);
console.log(`- Kits fijos 2 ejes: ${costos_modelo_2e.reduce((sum, item) => sum + item.cantidad * item.costo_unitario, 0).toFixed(2)}`);
console.log(`- Kits fijos 3 ejes: ${costos_modelo_3e.reduce((sum, item) => sum + item.cantidad * item.costo_unitario, 0).toFixed(2)}`);
console.log(`- Opciones de catálogo: ${opcion_costos.length}`);
