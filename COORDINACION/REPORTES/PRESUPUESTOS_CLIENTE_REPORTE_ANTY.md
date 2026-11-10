# Reporte Técnico: Presupuestos — Mostrar y Buscar por Nombre del Cliente

**Fecha:** 2026-11-10  
**Autor:** Antigravity  
**Revisor:** Claude  
**Rama:** `presupuestos-cliente-2026-11-10`  
**Base:** `5fa4685` (main)  
**Estado:** Completado, verificado con suite Deno (305/305 passed, baseline 295, 10 pruebas unitarias) y build de producción Vite OK.

---

## 1. Resumen Ejecutivo

1. **Pedido de Luis:** "en los presupuestos poner el nombre del cliente para que sea más fácil identificarlo".
2. **Diagnóstico Técnico:**
   - La tabla `presupuestos` ya cuenta con la columna `cliente_id` desde la migración inicial `20260915_presupuestos.sql`.
   - El generador de presupuestos desde cotización (`motor/generar_presupuesto_cotizacion.ts`) ya copia fielmente `cliente_id`.
   - El endpoint `GET /presupuestos` (`index.ts`) ya devuelve la relación embebida `cliente:clientes(*)`.
   - El editor (`PresupuestoEditor.tsx`) ya incluye el selector de cliente y el PDF imprime `CLIENTE:`.
   - **Faltante:** El listado `PresupuestosList.tsx` solo contenía columnas para Folio, Fecha, Concepto / Nomenclatura, Precio Venta y Acciones (sin columna Cliente), y su buscador únicamente filtraba por `folio` y `concepto`. Además, la cabecera del editor mostraba solamente `Editar Presupuesto {folio}` sin identificar al cliente.
3. **Solución Implementada:**
   - **Funciones Puras (`src/app/utils/presupuestoCliente.ts`):**
     - `nombreClientePresupuesto(presupuesto, clientes)`: Resuelve el nombre del cliente priorizando el objeto embebido `presupuesto.cliente` (provisto por el API) o buscando por `presupuesto.cliente_id` en el catálogo en memoria `clientes`. Extrae `nombre_comercial || razon_social` y retorna `"Sin cliente"` en caso de ausencia.
     - `coincideBusquedaPresupuesto(presupuesto, clientes, texto)`: Filtro multi-criterio que evalúa coincidencias en `folio`, `concepto`, `nomenclatura_id` y en el nombre resuelto del cliente. Es completamente insensible a mayúsculas/minúsculas y a acentos/diacríticos mediante normalización NFD (`normalizarTexto`).
     - `tituloEditorPresupuesto(presupuesto, clienteId, clientes)`: Genera el título reactivo del editor (`"Nuevo Presupuesto"`, `"Editar Presupuesto {folio} · {nombreCliente}"` o `"Editar Presupuesto {folio}"`).
   - **Listado de Presupuestos (`PresupuestosList.tsx`):**
     - Se añadió la columna **Cliente** entre Fecha y Concepto/Nomenclatura (distribución de 7 columnas).
     - Si el presupuesto no tiene cliente asociado, se despliega `"Sin cliente"` en color atenuado (`text-muted-foreground`).
     - Folio completo sin truncar (`truncate` removido), permitiendo salto natural en guion.
     - Columna de cliente con `truncate` y tooltip nativo `title={nombreCli}`.
     - Campo de búsqueda ampliado (`w-64 sm:w-80`) con placeholder descriptivo `"Buscar por folio, cliente o concepto..."`.
   - **Editor de Presupuestos (`PresupuestoEditor.tsx`):**
     - Título dinámico en el encabezado: si existe presupuesto con cliente, muestra `Editar Presupuesto {folio} · {nombreCliente}`. Al cambiar de cliente en el selector se actualiza dinámicamente; si se selecciona "ninguno", se retira el cliente y queda `Editar Presupuesto {folio}`. Si es nuevo, mantiene `Nuevo Presupuesto`.
   - **Pruebas Automatizadas:** 10 pruebas unitarias en `src/app/utils/presupuestoCliente.test.ts`. Total de pruebas: **305 passed | 0 failed** (baseline: 295).
   - **Aislamiento e Integridad:** No se modificó la base de datos (0 migraciones SQL), ni el backend Deno/Hono, ni el motor de costeo ni `ConfiguradorEquipo.tsx`.

---

## 1.1 Correcciones de Ronda 2 (Revisión de Claude)

En apego a la revisión `COORDINACION/REVISIONES/PRESUPUESTOS_CLIENTE_REVISION_CLAUDE.md`:
1. **[MEDIA] Folio sin cortes en el listado (`PresupuestosList.tsx`):**
   - Se removió `truncate` de la celda de folio (`<div className="col-span-1 font-medium text-blue-600">{p.folio}</div>`).
   - Los folios largos generados de cotizaciones (ej. `PRE-2026-20260917195482`) ahora se parten en el guion sin mostrar puntos suspensivos ("…"), permitiendo la lectura íntegra del folio.
2. **[BAJA] Reactividad del título del editor al seleccionar "ninguno" (`PresupuestoEditor.tsx` y `presupuestoCliente.ts`):**
   - Se modificó `const idCli = clienteId !== 'ninguno' ? clienteId : null;`, evitando que al elegir "ninguno" (A QUIEN CORRESPONDA) se retornara al cliente original del presupuesto.
   - Se exportó la función pura `tituloEditorPresupuesto` y se agregó la prueba unitaria 10 que certifica que elegir otro cliente actualiza el título y elegir "ninguno" lo quita inmediatamente.

---

## 2. Visualización y Flujo de Usuario (Mockups Conceptuales)

### A. Listado de Presupuestos (`PresupuestosList.tsx`)
```text
Listado de Presupuestos              [🔍 Buscar por folio, cliente o concepto...   ] [+ Nuevo Presupuesto]
──────────────────────────────────────────────────────────────────────────────────────────────────────────
Folio       Fecha       Cliente                 Concepto / Nomenclatura        Precio Venta    Acciones
──────────────────────────────────────────────────────────────────────────────────────────────────────────
PRE-2026-   10/11/2026  FERRETERA DEL CENTRO    9-GA5010226-6                  $1,250,000      [📄][🖨️][🗑️]
2026091719                                      Góndola 30 m³ 3 Ejes HARDOX
PRE-000102  09/11/2026  Sin cliente             PL-402-001                       $620,000      [📄][🖨️][🗑️]
                                                Plataforma 40 ft 2 Ejes
PRE-000103  08/11/2026  TRANSPORTES Y LOGÍSTICA DOLLY-H-01                       $310,000      [📄][🖨️][🗑️]
                                                Dolly H-2 Ejes
```
- El folio largo no se trunca con "…", sino que se parte en el guion de forma legible.
- Búsqueda por `"ferretera"`, `"Ferretera"`, `"FERRETERA"` o `"centro"` localiza instantáneamente a `PRE-2026-...`.
- Búsqueda por `"logistica"` o `"logística"` (con o sin acento) localiza a `PRE-000103`.
- Búsqueda por folio o concepto conserva su comportamiento previo intacto.

### B. Encabezado del Editor (`PresupuestoEditor.tsx`)
```text
[← Volver]   Editar Presupuesto PRE-000101 · FERRETERA DEL CENTRO        [💾 Guardar Presupuesto]
```
Si el usuario selecciona "A QUIEN CORRESPONDA" ("ninguno") en el selector:
```text
[← Volver]   Editar Presupuesto PRE-000101                               [💾 Guardar Presupuesto]
```
Si se presiona "+ Nuevo Presupuesto":
```text
[← Volver]   Nuevo Presupuesto                                           [💾 Guardar Presupuesto]
```

---

## 3. Pruebas Automatizadas y Casos Cubiertos

Archivo de pruebas: `src/app/utils/presupuestoCliente.test.ts` (10 pruebas Deno).

1. **Cliente embebido en el presupuesto:** Usa `presupuesto.cliente` devuelto por el join del API (`nombre_comercial` o `razon_social`).
2. **Resolución por `cliente_id`:** Si `presupuesto.cliente` no viene embebido, lo resuelve exitosamente a través de la lista en memoria `clientes`.
3. **Fallback sin cliente:** Retorna `"Sin cliente"` si no existe cliente embebido ni coincide el `cliente_id` (o viene nulo/vacío).
4. **Prioridad de nombre:** Prioriza `nombre_comercial` sobre `razon_social`; si no hay nombre comercial, usa `razon_social` o `nombre_razon_social`.
5. **Búsqueda por subcadena:** Coincidencia parcial insensible a mayúsculas (ej. `"ferretera"` encuentra `"FERRETERA DEL CENTRO"`).
6. **Búsqueda insensible a acentos:** Coincidencia normalizada NFD (ej. `"logistica"` encuentra `"TRANSPORTES Y LOGÍSTICA"` y viceversa).
7. **Búsqueda por folio y concepto:** Conserva compatibilidad total con búsquedas por folio (`"PRE-001"`), concepto (`"gondola"`) y nomenclatura (`"9-GA"`).
8. **Texto vacío o espacios:** Retorna `true` permitiendo mostrar todos los presupuestos sin filtrar.
9. **Manejo de nulos / indefinidos:** Tolera presupuestos con datos parciales o campos ausentes sin generar excepciones.
10. **Reactividad de título en editor:** Verifica que `tituloEditorPresupuesto` cambia al seleccionar otro cliente, quita el nombre del cliente al seleccionar "ninguno", y maneja presupuestos nuevos y presupuestos sin cliente previo.

### Salida Real de `deno test -A`
```text
running 10 tests from ./src/app/utils/presupuestoCliente.test.ts
presupuestoCliente: normalizarTexto elimina acentos y pasa a minúsculas ... ok (1ms)
presupuestoCliente: nombreClientePresupuesto con cliente embebido ... ok (0ms)
presupuestoCliente: nombreClientePresupuesto solo con cliente_id (busca en clientes) ... ok (0ms)
presupuestoCliente: nombreClientePresupuesto cliente con solo razón social ... ok (0ms)
presupuestoCliente: nombreClientePresupuesto sin cliente (null o no encontrado) devuelve 'Sin cliente' ... ok (0ms)
presupuestoCliente: coincideBusquedaPresupuesto con texto vacío retorna true ... ok (0ms)
presupuestoCliente: buscar por parte del nombre del cliente ('ferretera' encuentra 'FERRETERA DEL CENTRO') ... ok (0ms)
presupuestoCliente: buscar cliente insensible a acentos ... ok (0ms)
presupuestoCliente: búsqueda por folio y por concepto sigue funcionando igual que hoy ... ok (0ms)
presupuestoCliente: tituloEditorPresupuesto cambia con selección y se quita con 'ninguno' ... ok (0ms)

... (resto de la suite de motor, esquemas y UI)

ok | 305 passed | 0 failed (6s)
```

---

## 4. Archivos Modificados vs `main`

| Archivo | Estado | Descripción |
| :--- | :---: | :--- |
| `src/app/utils/presupuestoCliente.ts` | **Nuevo** | Funciones puras `nombreClientePresupuesto`, `coincideBusquedaPresupuesto`, `normalizarTexto` y `tituloEditorPresupuesto`. |
| `src/app/utils/presupuestoCliente.test.ts` | **Nuevo** | 10 pruebas unitarias cubriendo todos los casos de resolución de nombre, búsqueda y reactividad del título. |
| `src/app/components/Presupuestos/PresupuestosList.tsx` | Modificado | Columna Cliente, folio completo sin cortar, ancho ampliado de búsqueda y filtro multi-campo con `coincideBusquedaPresupuesto`. |
| `src/app/components/Presupuestos/PresupuestoEditor.tsx` | Modificado | Título dinámico `Editar Presupuesto {folio} · {nombreCliente}` en el encabezado con soporte para quitar al elegir "ninguno". |
| `CHANGELOG_ANTIGRAVITY.md` | Modificado | Bitácora de cambios registrada (Rondas 1 y 2). |
| `PRESUPUESTOS_CLIENTE_REPORTE_ANTY.md` | **Nuevo** | Este reporte técnico. |
| `COORDINACION/REPORTES/PRESUPUESTOS_CLIENTE_REPORTE_ANTY.md` | **Nuevo** | Copia del reporte técnico en coordinación. |

---

## 5. Acciones Manuales para Luis

- **Base de Datos:** **Ninguna acción necesaria.** No se crearon tablas ni columnas nuevas; la columna `cliente_id` ya existía.
- **Backend Deno (`remolques-api`):** **Ninguna acción necesaria.** El backend ya retornaba la relación con clientes.
- **Frontend Web (`remolques-web`):**
  - Una vez que la rama sea integrada (`merge`) a `main`, hacer clic en **"Rebuild"** en el servicio `remolques-web` de EasyPanel.
