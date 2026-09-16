const fs = require('fs');
const filePath = 'supabase/functions/make-server-feea4382/index.ts';
let code = fs.readFileSync(filePath, 'utf-8');

code = code.replace(
  `.select("*, cliente:clientes(*), cotizacion:cotizaciones(*)")`,
  `.select("*, cliente:clientes(*), cotizacion:cotizaciones(*), linea:lineas_producto(*), fase:fases_produccion(*)")`
);

fs.writeFileSync(filePath, code, 'utf-8');
