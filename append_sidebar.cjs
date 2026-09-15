const fs = require('fs');
const filePath = 'src/app/components/Layout/Sidebar.tsx';
let code = fs.readFileSync(filePath, 'utf-8');
code = code.replace(
  "{ icon: Settings, label: 'Configuración', id: 'configuracion', path: '/configuracion' }",
  "{ icon: Settings, label: 'Configuración', id: 'configuracion', path: '/configuracion' },\n    { icon: Factory, label: 'Producción', id: 'produccion', path: '/produccion' }"
);
code = code.replace(
  "import { LayoutDashboard",
  "import { Factory, LayoutDashboard"
);
fs.writeFileSync(filePath, code, 'utf-8');
