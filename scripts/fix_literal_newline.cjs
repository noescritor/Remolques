const fs = require('fs');
let c = fs.readFileSync('src/app/App.tsx', 'utf8');

c = c.replace('cotizacionEventos,\\n    crearCotizacionEvento,', 'cotizacionEventos,\n    crearCotizacionEvento,');

fs.writeFileSync('src/app/App.tsx', c);
console.log('Fixed literally');
