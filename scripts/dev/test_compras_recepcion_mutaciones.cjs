/**
 * Batería de mutaciones para motor/compras_recepcion.ts (modelo: arnes_revision_f/mutar_f3.cjs).
 * Uso: node scripts/dev/test_compras_recepcion_mutaciones.cjs
 */

const fs = require('node:fs');
const { resolve } = require('node:path');
const { spawnSync } = require('node:child_process');

const dir = resolve(__dirname, '../../supabase/functions/make-server-feea4382/motor');
const file = resolve(dir, 'compras_recepcion.ts');
const orig = fs.readFileSync(file, 'utf8');
const nl = orig.includes('\r\n');

const M = [
  ['M1 lista blanca: permite editar organizacion_id/folio', 'if (CAMPOS_EDITABLES_COMPRA.has(k) && v !== undefined)', 'if (v !== undefined)'],
  ['M2 transicion Recibida -> Pendiente permitida', 'if (estadoPrevio === "Recibida") {', 'if (false) {'],
  ['M3 transicion Cancelada -> Recibida permitida', 'if (estadoPrevio === "Cancelada") {', 'if (false) {'],
  ['M4 estado invalido aceptado', 'if (!ESTADOS_VALIDOS.has(nuevo)) {', 'if (false) {'],
  ['M5 lectura previa sin filtro organizacion_id', '.eq("id", compraId)\n    .eq("organizacion_id", orgId)\n    .maybeSingle();', '.eq("id", compraId)\n    .maybeSingle();'],
  ['M6 ignora error del RPC recibir_compra_proveedor', 'if (rpcErr) {\n    throw mapearErrorRpcCompra(rpcErr);\n  }', 'if (false) {\n    throw mapearErrorRpcCompra(rpcErr);\n  }'],
  ['M7 mapeo compra_no_encontrada deja de ser 404', 'return new ComprasRecepcionError(404, "compra_no_encontrada"', 'return new ComprasRecepcionError(500, "compra_no_encontrada"'],
  ['M8 mapeo cantidad_no_entera deja de ser 400', 'return new ComprasRecepcionError(\n      400,\n      "cantidad_no_entera",', 'return new ComprasRecepcionError(\n      500,\n      "cantidad_no_entera",'],
  ['M9 mapeo deadlock 40P01 deja de ser 409', 'code === "40P01" ||\n    code === "40001" ||', 'false ||'],
  ['M10 POST no valida org de productos', '.eq("organizacion_id", orgId)\n      .in("id", prodIds);', '.in("id", prodIds);'],
  ['M11 POST acepta cantidad <= 0', 'if (!Number.isFinite(cantidad) || cantidad <= 0) {', 'if (false) {'],
  ['M12 POST acepta costo negativo', 'if (!Number.isFinite(costo) || costo < 0) {', 'if (false) {'],
  ['M13 POST no borra compra fantasma si falla compra_items', 'if (itemsError) {\n      await supabase\n        .from("compras_proveedor")\n        .delete()', 'if (false) {\n      await supabase\n        .from("compras_proveedor")\n        .delete()'],
  ['M14 fallo de calcularRequisicion no genera aviso', 'respuesta.aviso = `La compra se recibió', '// respuesta.aviso = `La compra se recibió'],
  ['M15 UUID invalido aceptado en PUT', 'if (!UUID_RE.test(String(compraId || ""))) {', 'if (false) {'],
];

let muertos = 0;
const vivos = [];
const noAplica = [];

try {
  for (let [nombre, a, b] of M) {
    if (nl) {
      a = a.split('\n').join('\r\n');
      b = b.split('\n').join('\r\n');
    }
    if (!orig.includes(a)) {
      noAplica.push(nombre);
      continue;
    }
    fs.writeFileSync(file, orig.replace(a, b));
    const r = spawnSync('deno', ['test', '--allow-all', '--no-check', resolve(dir, 'compras_recepcion.test.ts')], {
      encoding: 'utf8',
    });
    const murio = r.status !== 0;
    console.log((murio ? 'MUERTO ' : 'VIVO   ') + nombre);
    if (murio) muertos++;
    else vivos.push(nombre);
  }
} finally {
  fs.writeFileSync(file, orig);
}

console.log(`\nRESUMEN: muertos=${muertos} vivos=${vivos.length} no_aplica=${noAplica.length}`);
if (vivos.length) {
  console.log('VIVOS:\n - ' + vivos.join('\n - '));
  process.exit(1);
}
if (noAplica.length) {
  console.log('NO_APLICA:\n - ' + noAplica.join('\n - '));
  process.exit(1);
}
