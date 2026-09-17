const fs = require('fs');
const filePath = 'src/app/components/Presupuestos/PresupuestoEditor.tsx';
let code = fs.readFileSync(filePath, 'utf-8');

// Replace {datos[key].items.map((item, idx) => (
// With {Array.isArray(datos[key]?.items) && datos[key].items.map((item, idx) => (
code = code.replace(/\{datos\[key\]\.items\.map\(\(item, idx\) => \(/g, "{Array.isArray(datos[key]?.items) && datos[key].items.map((item, idx) => (");

// Also check PresupuestoPDF.tsx
const pdfPath = 'src/app/components/Presupuestos/PresupuestoPDF.tsx';
if (fs.existsSync(pdfPath)) {
  let pdfCode = fs.readFileSync(pdfPath, 'utf-8');
  pdfCode = pdfCode.replace(/sec\.items\.filter/g, "(sec.items || []).filter");
  fs.writeFileSync(pdfPath, pdfCode, 'utf-8');
}

fs.writeFileSync(filePath, code, 'utf-8');
