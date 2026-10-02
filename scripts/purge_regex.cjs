const fs = require('fs');
let c = fs.readFileSync('src/app/components/Cotizaciones/CotizacionEditor.tsx', 'utf8');

c = c.replace(/if \([\s\S]*?producto_terminado'[\s\S]*?\{[\s\S]*?catch[\s\S]*?\}[\s\S]*?\}/, '');
fs.writeFileSync('src/app/components/Cotizaciones/CotizacionEditor.tsx', c);
console.log('Fixed');
