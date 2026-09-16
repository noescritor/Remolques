const fs = require('fs');
const filePath = 'src/app/hooks/useSupabaseData.ts';
let code = fs.readFileSync(filePath, 'utf-8');

const badBlock = `      return {

    
    ordenesTrabajo,
    actualizarOrdenTrabajo,
    generarOrdenesDesdeCotizacion,
    presupuestos,
    crearPresupuesto,
    actualizarPresupuesto,
    eliminarPresupuesto,

 token: tokenPortal, expira: expira.toISOString() };`;

code = code.replace(badBlock, `      return { token: tokenPortal, expira: expira.toISOString() };`);

const goodBlock = `    // Utilities
    loadData
  };
}`;

const replacement = `    // Produccion
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

code = code.replace(goodBlock, replacement);

fs.writeFileSync(filePath, code, 'utf-8');
