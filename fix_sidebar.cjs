const fs = require('fs');
const filePath = 'src/app/components/ModernLayout.tsx';
let code = fs.readFileSync(filePath, 'utf-8');

const regex = /{ id: 'trazabilidad', label: 'Trazabilidad',  icon: ClipboardList,   isActive: currentPage === 'trazabilidad' },/;
code = code.replace(regex, "{ id: 'trazabilidad', label: 'Trazabilidad',  icon: ClipboardList,   isActive: currentPage === 'trazabilidad' },\n    { id: 'presupuestos', label: 'Presupuestos',  icon: Calculator,      isActive: currentPage === 'presupuestos' },");

fs.writeFileSync(filePath, code, 'utf-8');
