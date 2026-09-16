const fs = require('fs');
const filePath = 'src/app/hooks/useSupabaseData.ts';
let code = fs.readFileSync(filePath, 'utf-8');

// Find the bad return and replace it
code = code.replace(
  /return \{\s*ordenesTrabajo,\s*actualizarOrdenTrabajo,\s*generarOrdenesDesdeCotizacion,\s*presupuestos,\s*crearPresupuesto,\s*actualizarPresupuesto,\s*eliminarPresupuesto,\s*token: tokenPortal, expira: expira.toISOString\(\) \};/,
  "return { token: tokenPortal, expira: expira.toISOString() };"
);

// Append the missing exports at the very end (before the last `  };\n}`)
const endPattern = "    // Utilities\n    loadData\n  };\n}";
const replacement = `    // Producción
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

code = code.replace(endPattern, replacement);

fs.writeFileSync(filePath, code, 'utf-8');
