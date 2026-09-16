const fs = require('fs');
const filePath = 'src/app/hooks/useSupabaseData.ts';
let code = fs.readFileSync(filePath, 'utf-8');

code = code.replace(
  "const ordenesReq = await fetchJson('ordenes', `${BASE_URL}/ordenes-trabajo`, token).catch(() => []);\n      setOrdenesTrabajo(Array.isArray(ordenesReq) ? ordenesReq : []);",
  "const ordenesReq = await fetchJson('ordenes', `${BASE_URL}/ordenes-trabajo`, token).catch(() => []);\n      setOrdenesTrabajo(Array.isArray(ordenesReq) ? ordenesReq : []);\n\n      const presuReq = await fetchJson('presupuestos', `${BASE_URL}/presupuestos`, token).catch(() => []);\n      setPresupuestos(Array.isArray(presuReq) ? presuReq : []);"
);

fs.writeFileSync(filePath, code, 'utf-8');
