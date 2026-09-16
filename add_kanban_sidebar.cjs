const fs = require('fs');
const filePath = 'src/app/components/ModernLayout.tsx';
let code = fs.readFileSync(filePath, 'utf-8');

const injection = `    { id: 'tablero-produccion', label: 'Tablero Producción', icon: LayoutDashboard, isActive: currentPage === 'tablero-produccion' },
    { id: 'trazabilidad', label: 'Trazabilidad',  icon: ClipboardList,   isActive: currentPage === 'trazabilidad' },`;
code = code.replace("{ id: 'trazabilidad', label: 'Trazabilidad',  icon: ClipboardList,   isActive: currentPage === 'trazabilidad' },", injection);

fs.writeFileSync(filePath, code, 'utf-8');
