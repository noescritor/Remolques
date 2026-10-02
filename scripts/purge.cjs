const fs = require('fs');
let c = fs.readFileSync('src/app/components/Cotizaciones/CotizacionEditor.tsx', 'utf8');

const strStart = "        if (producto.tipo === 'bien' && producto.tipo_item === 'producto_terminado') {";
const strEnd = "        if (producto.tipo === 'servicio' && producto.servicio) {";

const idx1 = c.indexOf(strStart);
const idx2 = c.indexOf(strEnd);

if (idx1 !== -1 && idx2 !== -1) {
  const replacement = `
        if (producto.tipo === 'bien' && producto.tipo_item === 'producto_terminado') {
          // Ya no requerimos buscar la receta de producto_materiales aqui
          // porque se genera en Presupuestos
        }
        
`;
  c = c.substring(0, idx1) + replacement + c.substring(idx2);
  fs.writeFileSync('src/app/components/Cotizaciones/CotizacionEditor.tsx', c);
  console.log('Successfully purged block');
} else {
  console.log('Not found', idx1, idx2);
}
