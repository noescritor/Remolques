const fs = require('fs');
const filePath = 'src/app/components/TableroProduccion/TableroProduccionPage.tsx';
let code = fs.readFileSync(filePath, 'utf-8');

code = code.replace(/alert\\\(\\\`Orden: \\\$\\{orden\.cotizacion\?\\\.folio \|\| \'Sin folio\'\\} - \\\$\\{orden\.cliente\?\\\.nombre\\}\\\`\\\);/g, "alert(`Orden: ${orden.cotizacion?.folio || 'Sin folio'} - ${orden.cliente?.nombre}`);");

// Less restrictive replace just in case
code = code.replace("alert(\\`Orden: \\${orden.cotizacion?.folio || 'Sin folio'} - \\${orden.cliente?.nombre}\\`);", "alert(`Orden: ${orden.cotizacion?.folio || 'Sin folio'} - ${orden.cliente?.nombre}`);");

fs.writeFileSync(filePath, code, 'utf-8');
