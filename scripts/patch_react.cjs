const fs = require('fs');
let c = fs.readFileSync('src/app/components/Cotizaciones/CotizacionEditor.tsx', 'utf8');
if (!c.includes("import React")) {
    c = c.replace("import { useState", "import React, { useState");
    fs.writeFileSync('src/app/components/Cotizaciones/CotizacionEditor.tsx', c);
}
console.log("Added React import");
