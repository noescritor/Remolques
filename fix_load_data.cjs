const fs = require('fs');
const filePath = 'src/app/hooks/useSupabaseData.ts';
let code = fs.readFileSync(filePath, 'utf-8');

code = code.replace(
  "const pagosData = await fetchJson('pagos', `${BASE_URL}/pagos`, token);",
  "const pagosData = await fetchJson('pagos', `${BASE_URL}/pagos`, token);\n        const ordenesData = await fetchJson('ordenes', `${BASE_URL}/ordenes-trabajo`, token).catch(() => []);\n        const presupuestosData = await fetchJson('presupuestos', `${BASE_URL}/presupuestos`, token).catch(() => []);"
);

code = code.replace(
  "setPagos(Array.isArray(pagosData) ? pagosData : []);",
  "setPagos(Array.isArray(pagosData) ? pagosData : []);\n        setOrdenesTrabajo(Array.isArray(ordenesData) ? ordenesData : []);\n        setPresupuestos(Array.isArray(presupuestosData) ? presupuestosData : []);"
);

fs.writeFileSync(filePath, code, 'utf-8');
