/**
 * Generador de fixture para pruebas de costeo del Dolly 2 ejes (Sub-bloque 2R-1e).
 * Lee docs/factura-leolca/extraccion_factura_leolca.json y genera:
 * supabase/functions/make-server-feea4382/motor/fixtures/datos_costeo_dolly.json
 */

const fs = require('fs');
const path = require('path');

const jsonPath = path.resolve(__dirname, '../docs/factura-leolca/extraccion_factura_leolca.json');
const outFixturePath = path.resolve(__dirname, '../supabase/functions/make-server-feea4382/motor/fixtures/datos_costeo_dolly.json');

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

// 1. Modelo
const modelo = {
  id: '00000000-0000-0000-0000-000000000020',
  nombre: 'DOLLY 2 EJES',
  tipo: 'dolly',
  largo_ft: 0,
  num_ejes: 2
};

// 2. Acero (33 renglones: 1 paquete + 32 piezas)
const despieceRaw = (dolly.despiece_acero || []).filter(r => r.fila !== 4);
const receta_acero = [];

// Paquete chasis
receta_acero.push({
  material_id: 'mat-dolly-acero-paquete',
  nombre: 'PAQUETE CUERPO CHASIS DOLLY (PUENTES J, C, Z, ALMA, SOLERAS SUPERIOR E INFERIOR)',
  cantidad: 1,
  escala: 'fija',
  costo: 14800,
  descripcion: 'PAQUETE'
});

const restoDespiece = despieceRaw.slice(6);
for (const row of restoDespiece) {
  let base = row.pieza ? row.pieza.trim() : '';
  if (row.variante && row.variante.trim()) base += ' ' + row.variante.trim();
  if (row.descripcion && row.descripcion.trim()) base += ' (' + row.descripcion.trim() + ')';
  const nombre = base.toUpperCase();

  const sinPrecio = (row.precio_unitario === null || row.precio_unitario === undefined);
  const costo = sinPrecio ? 0 : Number(row.precio_unitario);
  const descripcion = sinPrecio ? 'SIN PRECIO' : (row.descripcion || row.pieza);

  receta_acero.push({
    material_id: `mat-dolly-acero-${row.fila}`,
    nombre,
    cantidad: Number(row.cantidad),
    escala: 'fija',
    costo,
    descripcion
  });
}

// 3. Costos fijos (18 conceptos)
const costos_modelo = [
  { seccion: 'otros', concepto: 'Gata de izaje', cantidad: 1, costo_unitario: 433, escala: 'fija' },
  { seccion: 'otros', concepto: 'Bisagra', cantidad: 2, costo_unitario: 1041, escala: 'fija' },
  { seccion: 'otros', concepto: 'Oreja', cantidad: 2, costo_unitario: 843, escala: 'fija' },
  { seccion: 'otros', concepto: 'Perno de Dona', cantidad: 2, costo_unitario: 421.08, escala: 'fija' },
  { seccion: 'otros', concepto: 'Buje cónico', cantidad: 4, costo_unitario: 160, escala: 'fija' },
  { seccion: 'otros', concepto: 'Lodera blanca', cantidad: 2, costo_unitario: 303.99, escala: 'fija' },
  { seccion: 'otros', concepto: 'Flejes', cantidad: 2, costo_unitario: 232, escala: 'fija' },
  { seccion: 'tornilleria', concepto: 'Tornillería para loderas', cantidad: 8, costo_unitario: 5, escala: 'fija' },
  { seccion: 'luz', concepto: 'Kit de luz', cantidad: 1, costo_unitario: 4500, escala: 'fija' },
  { seccion: 'consumibles', concepto: 'Rollo de micro tubular', cantidad: 2, costo_unitario: 995, escala: 'fija' },
  { seccion: 'consumibles', concepto: 'Tanque de CO2', cantidad: 1, costo_unitario: 925, escala: 'fija' },
  { seccion: 'consumibles', concepto: 'Consumibles', cantidad: 0.5, costo_unitario: 550, escala: 'fija' },
  { seccion: 'consumibles', concepto: 'Kit de limpieza', cantidad: 1, costo_unitario: 400, escala: 'fija' },
  { seccion: 'pintura', concepto: 'Praimer', cantidad: 4, costo_unitario: 285, escala: 'fija' },
  { seccion: 'pintura', concepto: 'Pintura color estándar', cantidad: 4, costo_unitario: 640, escala: 'fija' },
  { seccion: 'otros', concepto: 'Tanque para aire', cantidad: 1, costo_unitario: 904, escala: 'fija' },
  { seccion: 'otros', concepto: 'Kit de rotulación', cantidad: 1, costo_unitario: 400, escala: 'fija' },
  { seccion: 'otros', concepto: 'Cinta reflejante', cantidad: 1, costo_unitario: 200, escala: 'fija' }
];

// 4. Mano de obra (43 renglones)
const procesos = (dolly.mano_obra || []).map(mo => ({
  orden: mo.fila,
  proceso: mo.proceso,
  subproceso: null,
  minutos: Math.round(((mo.costo * 60) / mo.tarifa_hora) * 100) / 100,
  tarifa_hora: mo.tarifa_hora
}));

// 5. Opciones de costo (9 opciones catalogadas)
const opcion_costos = [
  { grupo_clave: 'quinta', opcion_clave: 'holland', cantidad_base: 1, escala: 'fija', costo_unitario: 27375 },
  { grupo_clave: 'abs', opcion_clave: '2e_sin_retractil', cantidad_base: 1, escala: 'fija', costo_unitario: 20000 },
  { grupo_clave: 'abs', opcion_clave: '2e_1_retractil', cantidad_base: 1, escala: 'fija', costo_unitario: 24700 },
  { grupo_clave: 'retractil', opcion_clave: 'paleta', cantidad_base: 1, escala: 'fija', costo_unitario: 8200 },
  { grupo_clave: 'rines', opcion_clave: 'acero', cantidad_base: 4, escala: 'por_eje', costo_unitario: 1550 },
  { grupo_clave: 'rines', opcion_clave: 'aluminio', cantidad_base: 4, escala: 'por_eje', costo_unitario: 5500 },
  { grupo_clave: 'llantas', opcion_clave: 'chinas', cantidad_base: 4, escala: 'por_eje', costo_unitario: 3000 },
  { grupo_clave: 'llantas', opcion_clave: 'firestone', cantidad_base: 4, escala: 'por_eje', costo_unitario: 8700 },
  { grupo_clave: 'llantas', opcion_clave: 'amulet', cantidad_base: 4, escala: 'por_eje', costo_unitario: 4225 }
];

// 6. Grupos relevantes
const grupos = [
  { id: 'grp-quinta', clave: 'quinta', nombre: 'Quinta', seleccion: 'unica' },
  { id: 'grp-abs', clave: 'abs', nombre: 'Sistema de frenos ABS', seleccion: 'unica' },
  { id: 'grp-retractil', clave: 'retractil', nombre: 'Sistema retráctil', seleccion: 'unica' },
  { id: 'grp-rines', clave: 'rines', nombre: 'Rines', seleccion: 'unica_con_cantidad' },
  { id: 'grp-llantas', clave: 'llantas', nombre: 'Llantas', seleccion: 'unica_con_cantidad' }
];

// 7. Ganancia
const ganancia = 65000;

const fixture = {
  modelo,
  receta_acero,
  costos_modelo,
  procesos,
  opcion_costos,
  grupos,
  ganancia
};

fs.writeFileSync(outFixturePath, JSON.stringify(fixture, null, 2) + '\n', 'utf8');
console.log(`Fixture generado exitosamente en ${outFixturePath}`);
console.log(`- Acero total: ${receta_acero.reduce((sum, item) => sum + item.cantidad * (item.costo || 0), 0).toFixed(2)}`);
console.log(`- Kits total: ${costos_modelo.reduce((sum, item) => sum + item.cantidad * item.costo_unitario, 0).toFixed(2)}`);
console.log(`- Mano de obra total: ${procesos.reduce((sum, item) => sum + (item.minutos * item.tarifa_hora / 60), 0).toFixed(2)}`);
