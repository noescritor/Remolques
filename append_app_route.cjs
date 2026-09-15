const fs = require('fs');
const filePath = 'src/app/App.tsx';
let code = fs.readFileSync(filePath, 'utf-8');

// Imports
code = code.replace(
  "import { TrazabilidadList } from './components/Trazabilidad/TrazabilidadList';",
  "import { TrazabilidadList } from './components/Trazabilidad/TrazabilidadList';\nimport { OrdenesTrabajoList } from './components/OrdenesTrabajo/OrdenesTrabajoList';"
);

// Destructure from useSupabaseData
code = code.replace(
  "    cotizacionEventos,",
  "    cotizacionEventos,\n    ordenesTrabajo,\n    actualizarOrdenTrabajo,\n    generarOrdenesDesdeCotizacion,"
);

// Add Route
const routeStr = `
        <Route path="/produccion" element={
          <OrdenesTrabajoList
            ordenes={ordenesTrabajo}
            clientes={clientes}
            loading={loading}
            onActualizarOrden={actualizarOrdenTrabajo}
          />
        } />
`;
code = code.replace(/<Route path="\/trazabilidad"/, routeStr + '        <Route path="/trazabilidad"');

fs.writeFileSync(filePath, code, 'utf-8');
