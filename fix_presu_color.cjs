const fs = require('fs');
const filePath = 'src/app/components/Presupuestos/PresupuestoEditor.tsx';
let code = fs.readFileSync(filePath, 'utf-8');
code = code.replace(/'bg-slate-700'/g, "'bg-muted text-foreground'");
fs.writeFileSync(filePath, code, 'utf-8');
