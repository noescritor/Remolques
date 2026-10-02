const fs = require('fs');
let c = fs.readFileSync('src/app/components/Cotizaciones/CotizacionEditor.tsx', 'utf8');

const regex = /if \(producto\.tipo === 'bien' && producto\.tipo_item === 'producto_terminado'\) \{[\s\S]*?\}\n\s*\}/;

c = c.replace('const agregarItemDesdeProducto = async (producto: Producto) => {', 'const agregarItemDesdeProducto = (producto: Producto) => {');
c = c.replace(regex, '');

// Also remove `sub_items` property from `nuevoItem` assignment
c = c.replace(/sub_items: sub_items/g, '');

fs.writeFileSync('src/app/components/Cotizaciones/CotizacionEditor.tsx', c);
console.log('Removed supabase fetch from CotizacionEditor');
