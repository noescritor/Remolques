const fs = require('fs');
const filePath = 'src/app/App.tsx';
let code = fs.readFileSync(filePath, 'utf-8');

code = code.replace(
  "import { OrdenesTrabajoList } from './components/OrdenesTrabajo/OrdenesTrabajoList';",
  "import { OrdenesTrabajoList } from './components/OrdenesTrabajo/OrdenesTrabajoList';\nimport { PresupuestosList } from './components/Presupuestos/PresupuestosList';"
);

const routeStr = "        <Route path=\"/produccion\" element={<ModernLayout />}>\n          <Route index element={<OrdenesTrabajoList />} />\n        </Route>";
code = code.replace(
  routeStr,
  routeStr + "\n        <Route path=\"/presupuestos\" element={<ModernLayout />}>\n          <Route index element={<PresupuestosList />} />\n        </Route>"
);

fs.writeFileSync(filePath, code, 'utf-8');
