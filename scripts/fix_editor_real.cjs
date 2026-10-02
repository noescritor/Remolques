const fs = require('fs');
let c = fs.readFileSync('src/app/components/Cotizaciones/CotizacionEditor.tsx', 'utf8');

const replacementFn = `  const agregarItemDesdeProducto = (producto: Producto) => {
      let nuevoItem: ItemCotizacion;
      let sub_items = undefined;
  
      if (producto.tipo === 'servicio' && producto.servicio) {`;

c = c.replace(/const agregarItemDesdeProducto = async \(producto: Producto\) => \{[\s\S]*?if \(producto\.tipo === 'servicio' && producto\.servicio\) \{/, replacementFn);

fs.writeFileSync('src/app/components/Cotizaciones/CotizacionEditor.tsx', c);
console.log('Fixed for real');
