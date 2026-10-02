const fs = require('fs');
let c = fs.readFileSync('src/app/components/Cotizaciones/CotizacionesList.tsx', 'utf8');

c = c.replace(/onEliminarCotizacion,\\n  crearPresupuesto,\\n  productos = \[\]\\n\}: CotizacionesListProps\) \{/, 'onEliminarCotizacion,\n  crearPresupuesto,\n  productos = []\n}: CotizacionesListProps) {');

fs.writeFileSync('src/app/components/Cotizaciones/CotizacionesList.tsx', c);
console.log('Fixed literal');
