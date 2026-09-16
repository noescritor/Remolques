const fs = require('fs');
const filePath = 'src/app/App.tsx';
let code = fs.readFileSync(filePath, 'utf-8');

const presupuestosRoute = `
        <Route path="/presupuestos" element={
          <PresupuestosList
            presupuestos={presupuestos}
            clientes={clientes}
            loading={loading}
            onSave={crearPresupuesto}
            onUpdate={actualizarPresupuesto}
            onDelete={eliminarPresupuesto}
          />
        } />
`;

const routeStr = "        <Route path=\"/produccion\" element={";
code = code.replace(routeStr, presupuestosRoute + "\n" + routeStr);

fs.writeFileSync(filePath, code, 'utf-8');
