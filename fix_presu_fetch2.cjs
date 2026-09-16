const fs = require('fs');
const filePath = 'src/app/hooks/useSupabaseData.ts';
let code = fs.readFileSync(filePath, 'utf-8');

const regex = /const ordenesReq = await fetchJson\('ordenes', `\$\{BASE_URL\}\/ordenes-trabajo`, token\)\.catch\(\(\) => \[\]\);\s*setOrdenesTrabajo\(Array\.isArray\(ordenesReq\) \? ordenesReq : \[\]\);/g;

code = code.replace(regex, "const ordenesReq = await fetchJson('ordenes', `${BASE_URL}/ordenes-trabajo`, token).catch(() => []);\n      setOrdenesTrabajo(Array.isArray(ordenesReq) ? ordenesReq : []);\n\n      const presuReq = await fetchJson('presupuestos', `${BASE_URL}/presupuestos`, token).catch(() => []);\n      setPresupuestos(Array.isArray(presuReq) ? presuReq : []);");

fs.writeFileSync(filePath, code, 'utf-8');
