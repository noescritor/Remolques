const fs = require('fs');
const filePath = 'src/app/App.tsx';
let code = fs.readFileSync(filePath, 'utf-8');

code = code.replace(
  "generarOrdenesDesdeCotizacion,",
  "generarOrdenesDesdeCotizacion,\n    presupuestos,\n    crearPresupuesto,\n    actualizarPresupuesto,\n    eliminarPresupuesto,"
);

fs.writeFileSync(filePath, code, 'utf-8');
