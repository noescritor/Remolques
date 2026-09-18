const fs = require('fs');
let c = fs.readFileSync('CHANGELOG_ANTIGRAVITY.md', 'utf8');

const entry = `## 2026-09-18 - Sub-bloque 1D (Producción)
**Herramienta:** Antigravity
**Tipo:** cambio
**Archivos tocados:** supabase/functions/make-server-feea4382/index.ts
**Qué cambió / qué se encontró:**
- Backend: Se corrigió el bug de \`PUT /produccion/ordenes/:id/material\`: ahora usa \`incompleta\` y \`en_proceso\` (valores válidos del CHECK constraint de Kanban).
- Backend: \`POST /cotizaciones/:id/generar-ordenes\` ahora exige estado \`Aprobada\`.
- Backend: \`generar-ordenes\` ahora es idempotente, retornando órdenes existentes en lugar de duplicarlas.
- Backend: En lugar de la regla frágil de \`< 10000\`, ahora se detectan equipos cuando \`tipo_item === 'producto_terminado'\`, usando \`keywords\` solo como fallback con advertencia.
- Backend: Si \`obtener_siguiente_produccion\` falla, lanza un error 500 en lugar de usar \`Math.random()\`.
- Backend: Ahora se inicializan los campos \`linea_producto_id\`, \`fase_actual_id\` (a la primera fase) y \`estado_kanban = 'pendiente'\` al crear la orden.
- Backend: El endpoint rechaza la creación (HTTP 409) si hay faltantes en la requisición, a menos que se envíe \`force: true\`.
- Backend: Al crear las órdenes, el estado de producción cambia a \`En producción\` y se registra en trazabilidad.
**Por qué:** Requisito 1D del prompt.
**Acciones manuales pendientes:** Rebuild del backend en EasyPanel.
**Verificado:** Revisión de código en el backend.
**Ref. auditoría:** F2, F15.

`;

c = c.replace('## 2026-09-18 - Sub-bloque 1C', entry + '## 2026-09-18 - Sub-bloque 1C');
fs.writeFileSync('CHANGELOG_ANTIGRAVITY.md', c);
