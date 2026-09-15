const fs = require('fs');
const filePath = 'src/app/components/ModernLayout.tsx';
let code = fs.readFileSync(filePath, 'utf-8');

code = code.replace(
  "{ id: 'ajustes',      label: 'Configuración', icon: Settings,        isActive: currentPage === 'ajustes' },",
  "{ id: 'ajustes',      label: 'Configuración', icon: Settings,        isActive: currentPage === 'ajustes' },\n    { id: 'produccion',   label: 'Producción', icon: Settings,        isActive: currentPage === 'produccion' },"
);
// Replace Settings icon with Factory icon for produccion
code = code.replace(
  "{ id: 'produccion',   label: 'Producción', icon: Settings",
  "{ id: 'produccion',   label: 'Producción', icon: Factory"
);
// Import Factory from lucide-react
code = code.replace(
  "LayoutDashboard,",
  "LayoutDashboard,\n  Factory,"
);

fs.writeFileSync(filePath, code, 'utf-8');
