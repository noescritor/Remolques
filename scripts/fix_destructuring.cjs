const fs = require('fs');
let c = fs.readFileSync('src/app/components/Cotizaciones/CotizacionesTableModern.tsx', 'utf8');

c = c.replace(
  'onDuplicarCotizacion,\r\n  onEliminarCotizacion\r\n}:',
  'onDuplicarCotizacion,\r\n  onGenerarPresupuesto,\r\n  onEliminarCotizacion\r\n}:'
);
c = c.replace(
  'onDuplicarCotizacion,\n  onEliminarCotizacion\n}:',
  'onDuplicarCotizacion,\n  onGenerarPresupuesto,\n  onEliminarCotizacion\n}:'
);

fs.writeFileSync('src/app/components/Cotizaciones/CotizacionesTableModern.tsx', c);
console.log('Fixed for sure');
