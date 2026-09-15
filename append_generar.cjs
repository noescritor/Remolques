const fs = require('fs');
const filePath = 'src/app/App.tsx';
let code = fs.readFileSync(filePath, 'utf-8');

code = code.replace(
  "onRegistrarMovimientoInventario={registrarMovimientoInventario}",
  "onRegistrarMovimientoInventario={registrarMovimientoInventario}\n            onGenerarOrdenesTrabajo={generarOrdenesDesdeCotizacion}"
);

fs.writeFileSync(filePath, code, 'utf-8');
