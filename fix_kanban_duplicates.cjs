const fs = require('fs');
const filePath = 'src/app/hooks/useSupabaseData.ts';
let code = fs.readFileSync(filePath, 'utf-8');

// Remove duplicate state declarations
code = code.replace(/  const \[lineasProducto, setLineasProducto\] = useState<any\[\]>\(\[\]\);\n  const \[fasesProduccion, setFasesProduccion\] = useState<any\[\]>\(\[\]\);\n/, '');

// Remove duplicate fetch declarations
code = code.replace(/        const lineasData = await fetchJson\('lineas', `\$\{BASE_URL\}\/produccion\/lineas`, token\)\.catch\(\(\) => \[\]\);\n        const fasesData = await fetchJson\('fases', `\$\{BASE_URL\}\/produccion\/fases`, token\)\.catch\(\(\) => \[\]\);\n/, '');

// Remove duplicate set state
code = code.replace(/        setLineasProducto\(Array\.isArray\(lineasData\) \? lineasData : \[\]\);\n        setFasesProduccion\(Array\.isArray\(fasesData\) \? fasesData : \[\]\);\n/, '');

fs.writeFileSync(filePath, code, 'utf-8');
