# Reporte de Implementación y Corrección (Ronda 3): Góndola Volumen Configurable

**Fecha:** 2026-11-05  
**Autor:** Antigravity  
**Revisión:** Claude Code (`COORDINACION/REVISIONES/GONDOLA_VOLUMEN_REVISION_CLAUDE.md`, sección RONDA 2)  
**Aprobación final y despliegue:** Luis  
**Rama:** `gondola-volumen-2026-11-05`  
**Directorio de trabajo:** `..\Remolques_gondola`  

---

## 1. Resumen Ejecutivo de Ronda 3

En la Ronda 3 se resolvieron los tres puntos señalados por Claude Code en su revisión de la Ronda 2 (sin requerir migraciones de base de datos adicionales, únicamente código TypeScript/React y pruebas unitarias):

1. **[MEDIA] Volumen tratado como grupo conductor dimensional (sin pendiente falso)**:
   - Se definió el conjunto compartido `GRUPOS_CONDUCTOR = new Set(['volumen'])` y la función `esGrupoConductor()` en `motor/escalas.ts`.
   - En `motor/costeo.ts`, el grupo `volumen` se salta (`continue`) en el bucle de opciones sin generar línea de costo de $0 ni el pendiente espurio `opcion_sin_costo: "Opción sin costo configurado: volumen/m3_45"`.
   - Se revisaron exhaustivamente todos los demás recorridos de grupos en el motor (`resolver_receta.ts`, `catalogo_costos.ts`, `reglas_compatibilidad.ts`, `index.ts`, `ConfiguradorEquipo.tsx`). En `resolver_receta.ts` y `catalogo_costos.ts` se excluyeron los grupos conductores para evitar advertencias de componentes no configurados.
   - En pruebas unitarias Deno, se comprobó que `JSON.stringify(secciones)`, `pendientes`, `costo`, `precio_sugerido` y `confianza` de la configuración con `volumen: "m3_45"` son **100% idénticos** a la configuración sin volumen. Con `m3_30` la única diferencia en pendientes es la advertencia legítima `variante_supuesta`.

2. **[MEDIA] Nombre con volumen dinámico en todas las plantillas PDF y prevención de duplicación**:
   - Se integró `nombreItemCotizacion` en los 5 sitios restantes identificados:
     - `src/app/components/Cotizaciones/PDFTemplateMoodboard.tsx:447, 523, 628`
     - `src/app/components/Cotizaciones/PDFTemplateLeolca.tsx:97`
     - `src/app/components/Cotizaciones/PDFTemplate.tsx:183, 184`
   - Se robusteció `nombreItemCotizacion` para prevenir duplicación ante cotizaciones históricas congeladas mediante la expresión regular `/\b\d+\s*m(?:3|³)\b/i`.
   - Se ampliaron las pruebas unitarias en `src/app/utils/nombreItemCotizacion.test.ts` con los 4 casos exigidos (a, b, c, d) pasando con 6/6 aprobados.
   - Se realizó la auditoría completa de todos los sitios en `src/` que leen o imprimen nombres de producto (ver detalle en §6).

3. **[BAJA] Cifras del reporte corregidas con la salida directa del motor**:
   - Acero a 45 m³: **$103,936.96**
   - Acero a 30 m³: **$85,478.29**
   - Ahorro en acero: **$18,458.67**
   - Reducción en tina A-36: **$55,835.25** ($167,505.76 → $111,670.51)
   - Costo total Góndola 2E con tina A-36 a 45 m³: **$360,488.70**
   - Costo total Góndola 2E con tina A-36 a 30 m³: **$286,194.78**
   - Ahorro total directo de fabricación 45 → 30 m³: **$74,293.92** ($360,488.70 − $286,194.78).
   - Se eliminó la explicación de discrepancia de 14 centavos por redondeo intermedio, adoptando las cifras directas del motor redondeadas a 2 decimales por renglón.

---

## 2. Historial de Commits en la Rama `gondola-volumen-2026-11-05`

### Commits Ronda 3:
- `[commit actual]` — `docs(gondola): actualizar reporte y changelog ronda 3 con cifras exactas del motor`
- `6298d0e` — `fix(pdf): usar nombreItemCotizacion en todas las plantillas y prevenir duplicacion`
- `b63cad2` — `fix(costeo): tratar volumen como grupo conductor y evitar pendiente falso`

### Commits Ronda 2:
- `b56d316` — `docs(gondola): actualizar reporte de implementacion y ronda 2`
- `17e6a83` — `docs(gondola): registrar bitacora de ronda 2 en CHANGELOG_ANTIGRAVITY`
- `700f79a` — `test(gondola): pruebas unitarias completas, concurrencia y verificacion ronda 2`
- `ea7ee8c` — `fix(pdf): helper nombreItemCotizacion con volumen dinamico para PDFs`
- `87f3d38` — `fix(ui): helper tituloEquipo y corregir interpolacion en configurador`
- `f5c236f` — `feat(db): migrar opcion_costos de tina a escala por_volumen`
- `6c9c971` — `fix(db): restaurar guardar_linea_receta de T6 con soporte por_volumen y concurrencia`

### Commits Ronda 1:
- `7fdd445` — `docs(gondola): registrar bitacora y reporte de volumen configurable`
- `b2453a5` — `test(gondola): pruebas unitarias y de base de datos para volumen configurable`
- `bc9092a` — `feat(recetas): marcar lineas de tina de gondola con escala por_volumen`
- `97cf5d4` — `feat(ui): nombre dinamico con volumen para gondola y visualizacion en configurador`
- `892773b` — `feat(motor): unificar calculo de escalas con soporte para por_volumen`
- `b9fd8b4` — `feat(db): agregar grupo volumen para gondola y escala por_volumen`

---

## 3. Detalle de Cambios de Ronda 3

### 3.1 Tratamiento de Volumen como Grupo Conductor (`motor/escalas.ts` y `motor/costeo.ts`)
El volumen no es un insumo con precio propio ni una opción con costo unitario; es un conductor dimensional que modula la escala `por_volumen` de otros insumos en `receta_base` y `opcion_costos`.

En `motor/escalas.ts`:
```typescript
export const GRUPOS_CONDUCTOR = new Set<string>(["volumen"]);

export function esGrupoConductor(grupoClave?: string | null): boolean {
  if (!grupoClave) return false;
  return GRUPOS_CONDUCTOR.has(grupoClave.trim().toLowerCase());
}
```

En `motor/costeo.ts`:
```typescript
// En bucle de opciones elegidas:
if (esGrupoConductor(grupoClave)) {
  continue; // Conductor dimensional; no genera costo propio ni advertencia de sin_costo
}
```

Lugares auditados que iteran sobre `configuracion.grupos`:
- `motor/costeo.ts`: **Modificado**. Omite grupos conductores evitando línea $0 y advertencia falsa `opcion_sin_costo`.
- `motor/resolver_receta.ts`: **Modificado**. Se excluyeron grupos conductores de la validación de grupos desconocidos y del bucle de opciones sin receta.
- `motor/catalogo_costos.ts`: **Modificado**. Se excluyeron grupos conductores de la detección de `opcionesSinCosto` y `opcionesSinReceta`.
- `motor/reglas_compatibilidad.ts`: **Revisado**. Las reglas de compatibilidad validan pares grupo-opción definidos en BD; al no existir reglas restrictivas para volumen, opera normalmente sin tocar código.
- `supabase/functions/make-server-feea4382/index.ts`: **Revisado**. No valida grupos directamente, delega a `costeo.ts` y `resolver_receta.ts`.
- `src/app/components/Cotizaciones/ConfiguradorEquipo.tsx`: **Revisado**. Muestra la tarjeta del grupo para selección del usuario (30 m³ / 45 m³) sin mostrar costos falsos.

### 3.2 Pruebas Unitarias de Regresión y Diferencial
En `supabase/functions/make-server-feea4382/motor/gondola_volumen.test.ts` (Test 1):
1. **Regresión 45 m³ exacta:**
   - `costoConVolumen45 === costoSinVolumen` (ambos **$360,488.70** con tina A-36).
   - `precioConVolumen45 === precioSinVolumen` (ambos **$450,610.88**).
   - `pendientesConVolumen45` tiene longitud 0 (idéntico a sin volumen).
   - `JSON.stringify(secciones)` es idéntico carácter por carácter.
2. **Diferencial con 30 m³:**
   - La única diferencia en `pendientes` frente a 45 m³ es la advertencia legítima:  
     `variante_supuesta: "Costo de 30 m³ estimado por proporción sobre 45 m³; pendiente despiece real"`.
   - Cero pendientes de tipo `opcion_sin_costo`.

---

## 4. Cifras Consolidadas de Costeo y Fabricación

Medidas directamente en el motor con el fixture real de Góndola 2 Ejes:

| Rubro | Con 45 m³ (Estándar) | Con 30 m³ (Proporcional) | Diferencia / Ahorro |
|---|---|---|---|
| **Acero Base (`receta_base`, 49 renglones)** | $103,936.96 | $85,478.29 | **−$18,458.67** |
| — *4 renglones tina (Alma, Soleras, Borda, Cajón)* | $55,375.86 | $36,917.19 | −$18,458.67 (−33.3%) |
| — *45 renglones chasis/suspensión (escala fija)* | $48,561.10 | $48,561.10 | $0.00 |
| **Tina en Opciones (`opcion_costos`, A-36)** | $167,505.76 | $111,670.51 | **−$55,835.25** (−33.3%) |
| *(Alternativa Hardox 450 en `opcion_costos`)* | *$286,748.42* | *$191,165.61* | *−$95,582.81* (−33.3%) |
| **Chasis en `costos_modelo` (15 renglones fijos)** | $89,045.98 | $89,045.98 | $0.00 |
| **Costo Total de Fabricación (con Tina A-36)** | **$360,488.70** | **$286,194.78** | **−$74,293.92** (−20.6%) |
| **Precio de Venta Sugerido (Margen 20%)** | **$450,610.88** | **$357,743.48** | **−$92,867.40** |

---

## 5. Evaluación de `costos_modelo` de Góndola (29 Renglones)

Listado completo de los 29 renglones de `costos_modelo` (15 en 2 ejes por $89,045.98 y 14 en 3 ejes por $88,996.98). No se alteraron sus escalas (`fija`), quedando sujeto a decisión técnica de Luis y Leolca:

| # | Modelo | Concepto | Cantidad | Costo Unitario | Importe Total | Escala | Opinión Técnica Antigravity |
|---|---|---|---|---|---|---|---|
| 1 | Góndola 2E | Pistón | 1 | $55,825.00 | $55,825.00 | `fija` | **Posiblemente dependiente**: Representa el 62.7% del costo fijo. Si el volteo de 30 m³ requiere un pistón con menor carrera o menor número de etapas/tonelaje, su costo comercial sería menor. Requiere confirmar con Leolca. |
| 2 | Góndola 2E | Praimer | 1 | $10,000.00 | $10,000.00 | `fija` | **Ligeramente dependiente**: El área superficial de pintura de la tina de 30 m³ es menor (~20%). Si se compra por tambor fijo o lote, puede dejarse fija. |
| 3 | Góndola 2E | Kit de luz | 1 | $8,500.00 | $8,500.00 | `fija` | **Fija**: El arnés y luces reglamentarias SCT son idénticas en ambas configuraciones. |
| 4 | Góndola 2E | Rollo de micro tubular | 3 | $995.00 | $2,985.00 | `fija` | **Posiblemente dependiente**: Menor longitud de soldadura en tina. |
| 5 | Góndola 2E | Tanque de CO2 | 3 | $925.00 | $2,775.00 | `fija` | **Posiblemente dependiente**: Menor tiempo de arco de soldadura. |
| 6 | Góndola 2E | Tanque para aire | 2 | $1,050.00 | $2,100.00 | `fija` | **Fija**: Reservorios reglamentarios para frenos según norma SCT. |
| 7 | Góndola 2E | Rollo de sólido | 2 | $995.00 | $1,990.00 | `fija` | **Posiblemente dependiente**: Soldadura de tina. |
| 8 | Góndola 2E | Perno rey Holland | 1 | $1,200.00 | $1,200.00 | `fija` | **Fija**: Acople al tractocamión independiente del volumen. |
| 9 | Góndola 2E | Consumibles | 2 | $550.00 | $1,100.00 | `fija` | **Fija**: Discos de corte, desbaste, EPP. |
| 10 | Góndola 2E | Kit de limpieza | 1 | $750.00 | $750.00 | `fija` | **Fija**: Limpieza previa a pintura. |
| 11 | Góndola 2E | Kit tornillería patines | 44 | $15.00 | $660.00 | `fija` | **Fija**: Patines de chasis idénticos. |
| 12 | Góndola 2E | Lodera blanca | 2 | $303.99 | $607.98 | `fija` | **Fija**: Accesorios de chasis trasero. |
| 13 | Góndola 2E | Flejes | 2 | $232.00 | $464.00 | `fija` | **Fija**: Sujeción de tanques de aire. |
| 14 | Góndola 2E | Kit tornillería gancho | 1 | $49.00 | $49.00 | `fija` | **Fija**: Sujeción de gancho (solo en 2 ejes). |
| 15 | Góndola 2E | Tornillería loderas | 8 | $5.00 | $40.00 | `fija` | **Fija**: Tornillos de loderas. |
| 16–29 | Góndola 3E | *(Mismos 14 conceptos anteriores salvo gancho)* | - | - | $88,996.98 | `fija` | **Mismo criterio** que en 2 ejes. |

---

## 6. Auditoría Exhaustiva de Sitios que Leen o Imprimen Nombres en `src/`

Tras ejecutar `git grep -nE "\b(producto|produto|prod|p)\??\.nombre|item\??\.descripcion" src/`, se clasificaron todos los sitios del código fuente:

| Archivo y Línea | Código | Estado | Razón |
|---|---|---|---|
| `PDFFullPage.tsx:31` | `nombreItemCotizacion(producto, item)` | **Ya usaba helper** | Exportación PDF página completa. |
| `PDFPreview.tsx:34` | `nombreItemCotizacion(producto, item)` | **Ya usaba helper** | Vista previa del PDF en diálogo. |
| `PDFTemplateCompact.tsx:176` | `{nombreItemCotizacion(producto, item)}` | **Ya usaba helper** | Título principal de ítem en plantilla compacta. |
| `PDFTemplateCompact.tsx:266` | `{nombreItemCotizacion(producto, item)}` | **Ya usaba helper** | Bloque de notas/especificaciones en plantilla compacta. |
| `PDFTemplateModern.tsx:196` | `{nombreItemCotizacion(producto, item)}` | **Ya usaba helper** | Encabezado de ítem en plantilla moderna. |
| `PDFTemplateMoodboard.tsx:447` | `{nombreItemCotizacion(produto, item)}` | **Corregido (R3)** | Bloque de descripción de producto en moodboard. |
| `PDFTemplateMoodboard.tsx:523` | `{nombreItemCotizacion(produto, item)}` | **Corregido (R3)** | Tarjeta de servicio/equipo en moodboard. |
| `PDFTemplateMoodboard.tsx:628` | `{nombreItemCotizacion(produto, item)}` | **Corregido (R3)** | Renglón de total por equipo en moodboard. |
| `PDFTemplateLeolca.tsx:97` | `{nombreItemCotizacion(productos?.find(...), item)}` | **Corregido (R3)** | Encabezado de BOM en plantilla corporativa Leolca. |
| `PDFTemplate.tsx:183, 184` | `{nombreItemCotizacion(null, item)}` | **Corregido (R3)** | Columna descripción y title en plantilla clásica. |
| `CotizacionEditor.tsx:467, 537, 544, 649, 1084, 1193, 1205, 1459` | `item.descripcion`, `p.nombre` | **No aplica** | Campo input interactivo y autocomplete de catálogo al escribir una cotización. |
| `ExcelImportModal.tsx:103` | `item.descripcion !== ''` | **No aplica** | Validador de importación masiva de Excel. |
| `GenerarOrdenProduccionModal.tsx:104` | `{p.nombre}` | **No aplica** | Selector de producto base para orden de manufactura. |
| `GenerarRequisicionModal.tsx:142, 173` | `{p.nombre}` | **No aplica** | Selector de catálogo de materiales y compras. |
| `SelectorProductos.tsx:114, 119, 237` | `p.nombre` | **No aplica** | Catálogo general para agregar productos a la cotización. |
| `InventarioList.tsx:43, 169, 204, 275` | `producto.nombre` | **No aplica** | Gestión de existencias en almacén general. |
| `NotasManager.tsx:1200, 1207, 1213, 1217` | `p.nombre` | **No aplica** | Catálogo de conceptos en notas de crédito. |
| `FormularioTareaModal.tsx:301, 520, 889, 895` | `p.nombre`, `prod.nombre` | **No aplica** | Plan de producción de planta. |
| `PlantillasList.tsx:54, 129, 158, 218` | `p.nombre`, `item.descripcion` | **No aplica** | Plantillas preconfiguradas de cotización. |
| `PortalCliente.tsx:251` | `item.descripcion` | **No aplica** | Portal del cliente externo. |
| `PresupuestoDespieceTab.tsx:75, 320` | `p.nombre` | **No aplica** | Catálogo de materiales en ingeniería. |
| `ProductosList.tsx:163, 506, 939` | `producto.nombre`, `p.nombre` | **No aplica** | ABM del catálogo general de productos. |
| `ProveedoresList.tsx:70, 92, 217, 218` | `p.nombre` | **No aplica** | Catálogo de proveedores. |
| `calculations.ts:167` | `p.nombre === item.descripcion` | **No aplica** | Matching interno de catálogo si la descripción coincide. |
| `catalogoProductos.ts:139` | `p.nombre` | **No aplica** | Búsqueda de productos en catálogo. |
| `despiece.ts:159` | `p.nombre` | **No aplica** | Exportación de despiece CSV. |

---

## 7. Pruebas Automatizadas y Verificación

### 7.1 Pruebas Unitarias de `nombreItemCotizacion.test.ts` (Deno)
Se verificaron los 4 casos solicitados más los casos de catálogo:
- **Caso (a)**: `producto=null, item.descripcion="GONDOLA 2 EJES", item.configuracion con m3_30` → `"GONDOLA 2 EJES 30 M3"` (**OK**).
- **Caso (b)**: `item.descripcion="GONDOLA 2 EJES 45 M3", sin config` → `"GONDOLA 2 EJES 45 M3"` (**OK**, no duplica).
- **Caso (c)**: `item.descripcion="GONDOLA 2 EJES", sin config (histórico)` → `"GONDOLA 2 EJES 45 M3"` (**OK**).
- **Caso (d)**: `plataforma` → `"PLATAFORMA 40 FT 2 EJES"` (**OK**, sin cambios).
- **Caso catálogo**: Góndola con producto poblado y sin volumen → `"GONDOLA 2 EJES 45 M3"` (**OK**).
- **Caso idempotente**: Góndola que ya tiene 45 M3 en producto no lo duplica → `"GONDOLA 3 EJES 45 M3"` (**OK**).
**Resultado: 6 passed | 0 failed**.

### 7.2 Pruebas de Motor `gondola_volumen.test.ts` (Deno)
Se ejecutaron las 9 pruebas del motor de costeo y despiece para góndola:
- Test 1: Configuración con 45 m³ es idéntica a sin volumen en costos, precios, pendientes y secciones.
- Test 1b: Con 30 m³, la única diferencia en pendientes es la advertencia legítima `variante_supuesta` (sin pendientes falsos de `opcion_sin_costo`).
- Test 2: Tina A-36 y Hardox escalan exactamente a 30/45 en `opcion_costos`.
- Test 3: Comparación de costo total 45 vs 30 m³ da exactamente $74,293.92 de ahorro directo.
- Test 4: Consistencia 100% entre factor de despiece BOM y factor de costo en opciones de tina.
- Tests 5-9: Plataformas intactas, dollys intactos, advertencia de volumen no reconocido y retrocompatibilidad.
**Resultado: 9 passed | 0 failed**.

---

## 8. Pasos de Despliegue para Luis

1. **Revisión de Claude Code**: Claude valida la rama `gondola-volumen-2026-11-05` en el worktree `..\Remolques_gondola`.
2. **Merge a `main`**: Una vez aprobado, Luis hace merge de `gondola-volumen-2026-11-05` hacia `main`.
3. **Ejecutar migraciones en Supabase SQL Editor** (en este orden exacto):
   - `supabase/migrations/20261105_01_gondola_volumen.sql`
   - `supabase/migrations/20261105_02_gondola_volumen_escalas.sql`
   - `supabase/migrations/20261105_03_gondola_volumen_costos_tina.sql`
4. **Verificación en Supabase SQL Editor**:
   - Ejecutar `docs/gondola/verificacion_volumen.sql` y confirmar que `todo_ok` devuelva `true` (los 9 checks en verde).
5. **Rebuild en EasyPanel**:
   - `remolques-api` (Backend Deno).
   - `remolques-web` (Frontend Vite).
