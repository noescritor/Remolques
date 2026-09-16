const fs = require('fs');
const filePath = 'src/app/components/Presupuestos/PresupuestoEditor.tsx';
let code = fs.readFileSync(filePath, 'utf-8');

code = code.replace(
  "{presupuesto ? \\`Editar Presupuesto \\${presupuesto.folio}\\` : 'Nuevo Presupuesto'}",
  "{presupuesto ? `Editar Presupuesto ${presupuesto.folio}` : 'Nuevo Presupuesto'}"
);

fs.writeFileSync(filePath, code, 'utf-8');
