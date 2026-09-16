const fs = require('fs');
const filePath = 'src/app/components/Ajustes/AjustesForm.tsx';
let code = fs.readFileSync(filePath, 'utf-8');

code = code.replace(
  "formData.offset_folio.toString().padStart(5, '0')",
  "(formData.offset_folio || 0).toString().padStart(5, '0')"
);

fs.writeFileSync(filePath, code, 'utf-8');
