const fs = require('fs');
const filePath = 'src/app/components/Presupuestos/PresupuestoPDF.tsx';
let code = fs.readFileSync(filePath, 'utf-8');

code = code.replace(/\\`/g, "`");
code = code.replace(/\\\$/g, "$");

fs.writeFileSync(filePath, code, 'utf-8');
