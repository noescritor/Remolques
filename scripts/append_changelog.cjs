const fs = require('fs');
let c = fs.readFileSync('CHANGELOG_ANTIGRAVITY.md', 'utf8');
const log = `
## 2026-10-01 - Bloque 2: CPQ y Generación de PDF (Leolca)
**Herramienta:** Antigravity
**Tipo:** cambio
**Archivos tocados:** 
- src/app/components/Cotizaciones/CotizacionEditor.tsx
- src/app/components/Cotizaciones/PDFTemplateLeolca.tsx
- src/app/components/Cotizaciones/PDFFullPageLeolca.tsx
- src/app/App.tsx
- supabase/functions/make-server-feea4382/index.ts
**Qué cambió / qué se encontró:** 
1. Se modificó el CotizacionEditor para cargar automáticamente la Receta Base (BOM) en el objeto sub_items de cada ItemCotizacion al seleccionar un producto terminado.
2. Se añadió UI inline para permitir la edición y modificación de cantidades de los materiales base en la cotización.
3. Se inyectó la función 'calcularRequisicion' perdida en el backend de Deno, asegurando que extraiga los materiales directos desde 'sub_items' de la cotización si existen (CPQ dinámico), cayendo a la consulta estática de 'producto_materiales' como fallback.
4. Se implementó la vista de impresión 1:1 del Formato Leolca para cotizaciones (usando window.print()).
**Por qué:** Para cumplir con el requerimiento del Bloque 2 donde las cotizaciones necesitan ser dinámicas, con recetas que varían por venta individual, y para reemplazar el formato de PDF genérico por el estándar de Leolca.
**Acciones manuales pendientes:** Rebuild backend en EasyPanel del servicio 'make-server-feea4382'.
**Verificado:** build exitoso, TypeScript ok.

`;
c = c.replace('---', '---\n' + log);
fs.writeFileSync('CHANGELOG_ANTIGRAVITY.md', c);
