const fs = require('fs');
const filePath = 'src/app/hooks/useSupabaseData.ts';
let code = fs.readFileSync(filePath, 'utf-8');

const regexEnd = /\s*\/\/\s*Utilities\s*loadData\s*\};\s*\}/;

const replacement = `\n    // Producción
    ordenesTrabajo,
    actualizarOrdenTrabajo,
    generarOrdenesDesdeCotizacion,
    presupuestos,
    crearPresupuesto,
    actualizarPresupuesto,
    eliminarPresupuesto,

    // Utilities
    loadData
  };
}`;

code = code.replace(regexEnd, replacement);

fs.writeFileSync(filePath, code, 'utf-8');
