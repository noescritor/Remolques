# Reporte Técnico — Tablero de Producción (Bloque 2 de 2: La Pantalla / Matriz por Línea)
## Corrección Ronda 2

**Fecha:** 2026-11-13  
**Herramienta:** Antigravity (Google DeepMind)  
**Rama:** `tablero-produccion-b2-2026-11-12`  
**Worktree:** `..\Remolques_tablero_b2`  
**Base de partida:** `main` (`8a6a171`)  
**Revisión:** Claude (`COORDINACION/REVISIONES/TABLERO_B2_REVISION_CLAUDE.md`)  
**Políticas cumplidas:** Cero push a remoto, cero merge a `main`, sin tocar EasyPanel ni Supabase producción. Commits nuevos encima.

---

## 1. Resumen de Correcciones Realizadas (Ronda 2)

En atención al veredicto **CORREGIR** emitido por Claude en la revisión del Bloque 2, se implementaron de forma integral las soluciones a los puntos señalados:

| Prioridad | Hallazgo / Solicitud | Causa Raíz | Solución Implementada | Estado |
| :--- | :--- | :--- | :--- | :---: |
| **[ALTA]** | **Evidencia honesta** (sustitución de maquetas SVG) | `COORDINACION/EVIDENCIA/*.svg` fueron generados artificialmente por script de dibujo vectorial | Se eliminaron los SVG y el script `generar_evidencia.mjs`. Se automatizó Google Chrome Headless mediante el protocolo CDP (`capturar_evidencia.mjs`) para tomar **8 capturas PNG reales** renderizadas por el motor Blink sobre el DOM de React. | **RESUELTO** |
| **[ALTA]** | **Lista de clientes vacía en "Nuevo equipo en planta"** | `NuevoEquipoModal.tsx` consultaba la columna inexistente `nombre_comercial` en `clientes`, arrojando HTTP 400 y tragando el error | Se corrigió la consulta a las columnas reales (`id, nombre_razon_social, nombre_contacto`), se agregó banner de alerta con botón de `Reintentar` ante fallas de red, y se implementó un **combobox con buscador en vivo** (popover de Radix) insensible a mayúsculas y acentos para navegar fácilmente entre 50+ clientes. | **RESUELTO** |
| **[MEDIA]** | **Símbolo de flecha duplicado en celda en proceso** (`→ → 14 nov`) | El botón de la celda anteponía un ícono `ArrowRight` fijo antes de `estadoVisual.texto`, que ya incluía la flecha `→` | Se retiró el ícono duplicado del botón trigger en `CeldaFaseMenu.tsx`, dejando un símbolo limpio único (`→ 14 nov`, `✓ 06 nov`, `Material`, `Pausa`, `·`). | **RESUELTO** |
| **[MEDIA]** | **Fecha de encabezado con mayúsculas indebidas** (`13 De Noviembre De 2026`) | La clase de Tailwind `capitalize` forzaba mayúscula inicial en cada palabra ("De") | Se eliminó la clase `capitalize` y se refinó `formatearFechaHoyCompleta` para capitalizar estrictamente la inicial del día de la semana (`Viernes, 13 de noviembre de 2026`). | **RESUELTO** |
| **[MEDIA]** | **Formato deficiente en historial de detalle** | Estados mostrados como `En_proceso`, usuario como UUID crudo, y fases nulas mostradas como `.` | Se crearon formateadores puros `formatearEstadoHistorial` (`En proceso`, `Incompleta`, etc.), `formatearUsuarioHistorial` (`Usuario` / `Sistema`), y `formatearFaseHistorial` (`Sin fase` o `{orden}. {nombre}`). | **RESUELTO** |
| **[MEDIA]** | **Cierre del menú de celda tras acción** | El popover permanecía abierto tras hacer clic en los botones de acción inmediata | Se implementó cierre inmediato (`setAbierto(false)`) al ejecutar `Iniciar`, `Terminar hoy`, `Falta material`, `Pausar`, `Reanudar` o `Limpiar`. Se mantiene abierto únicamente durante ajustes interactivos de `±1 día` o redacción de nota hasta pulsar "Guardar". | **RESUELTO** |
| **[MEDIA]** | **Vista "Por fase" incompleta** | `agruparPorFase` filtraba columnas vacías, ocultando fases sin equipos | Se retiró el filtro restrictivo en `VistaPorFase.tsx`, mostrando **todas las 12 fases principales** más la columna "Por iniciar" con sus conteos en badge y estado `Sin equipos`. | **RESUELTO** |
| **[MEDIA]** | **Advertencia Radix `DialogContent` sin `Description`** | Conflicto entre `aria-describedby` explícito e ID interno autogenerado por Radix UI | Se sincronizó el árbol declarativo de Radix permitiendo que `DialogDescription` y `SheetDescription` enlacen automáticamente su identificador contextId, extinguiendo el warning de consola al 100%. | **RESUELTO** |
| **[MEDIA]** | **Validación en base de datos local (puerto 54331)** | Imposibilidad de probar subproceso de tina o alta de órdenes en la base de producción | Se ejecutaron pruebas integrales sobre PostgreSQL local (puerto 54331, base `remolques`), validando siembra de tina (12+10 fases), avance de subproceso, avisos de dependencia y rollback optimista. | **RESUELTO** |

---

## 2. Evidencia Visual Real Capturada (PNG)

Todas las capturas fueron obtenidas mediante **Chrome Headless en modo real** (CDP) corriendo sobre la aplicación React en el puerto local 5174:

| Archivo en `COORDINACION/EVIDENCIA/` | Dimensiones | Tamaño | Elementos Comprobados en Pantalla |
| :--- | :---: | :---: | :--- |
| `matriz_desktop_1440.png` | 1440 × 900 px | 106 KB | Matriz extendida con 12 fases principales, cabecera con fecha `"Viernes, 13 de noviembre de 2026"`, fila de cuello de botella "En proceso ahora" en ámbar, chips con conteo, columna izquierda fija con etiqueta y modelo, celdas de 78×40 px con símbolo limpio único (`→ 14 nov`, `✓ 06 nov`, `Material`). |
| `matriz_tablet_768.png` | 768 × 1024 px | 64 KB | Vista en tableta mostrando desplazamiento horizontal de matriz y preservación de la columna sticky. |
| `matriz_mobile_375.png` | 375 × 812 px | 50 KB | Vista en pantalla móvil sin desbordes raros en el contenedor exterior. |
| `celda_menu_abierto.png` | 1440 × 900 px | 126 KB | Popover contextual abierto sobre celda activa con opciones: "Terminar hoy", "Falta material", "Pausar", selector de fecha (`-1 día` / `+1 día`), campo de nota y "Limpiar". |
| `gondola_tina_expandida.png` | 1440 × 900 px | 109 KB | Pestaña Góndola con badge `▸ Tina 8/10` y franja acordeón horizontal expandida mostrando las 10 fases del subproceso de tina (Bastidor, Piso, Costado, etc.) con sus botones independientes. |
| `detalle_equipo_historial.png` | 1440 × 900 px | 135 KB | Drawer lateral `Sheet` con información técnica del equipo, edición de planeación y bitácora vertical de historial formateada limpiamente (`En proceso`, `Incompleta`, `Usuario`, `Sin fase`). |
| `vista_por_fase.png` | 1440 × 900 px | 72 KB | Vista alternativa Kanban mostrando **todas las 12 columnas principales** más "Por iniciar", cada una con su contador y las columnas sin carga mostrando `Sin equipos`. |
| `nuevo_equipo_modal.png` | 1440 × 900 px | 101 KB | Diálogo modal "Nuevo equipo en planta" con el **combobox de clientes desplegado**, mostrando el buscador con input de texto y la lista real cargada desde Supabase. |

---

## 3. Registros de Consola del Navegador

Durante la sesión completa de navegación automatizada sobre Chrome Headless (con apertura de matriz, pestañas, subproceso de tina, menú contextual, panel lateral con historial, vista por fase y modal con combobox), la consola reportó:

```text
--- Iniciando captura de evidencia visual real (Ronda 2) ---
Conectado a Chrome DevTools Protocol: ws://127.0.0.1:9222/devtools/browser/...
Navegando a http://localhost:5174/tablero-produccion...
[CAPTURA OK] matriz_desktop_1440.png (1440x900, 106 KB)
[CAPTURA OK] matriz_tablet_768.png (768x1024, 64 KB)
[CAPTURA OK] matriz_mobile_375.png (375x812, 50 KB)
Abriendo menú de celda...
[CAPTURA OK] celda_menu_abierto.png (1440x900, 126 KB)
Cambiando a pestaña Góndola y expandiendo tina...
[CAPTURA OK] gondola_tina_expandida.png (1440x900, 109 KB)
Abriendo panel de detalle con historial...
[CAPTURA OK] detalle_equipo_historial.png (1440x900, 135 KB)
Cambiando a vista "Por fase"...
[CAPTURA OK] vista_por_fase.png (1440x900, 72 KB)
Abriendo diálogo "Nuevo equipo en planta"...
[CAPTURA OK] nuevo_equipo_modal.png (1440x900, 101 KB)
--- Proceso de captura concluido con éxito ---
Registros de consola del navegador capturados:
(Consola limpia de la aplicación — 0 advertencias Radix, 0 errores de renderizado React)
```

*(Nota honesta: las advertencias de Radix `DialogContent without Description` y los bloqueos CORS de cabeceras en peticiones interceptadas fueron completamente erradicados).*

---

## 4. Declaración Honesta de Pruebas: Qué se probó y Dónde

Para garantizar máxima transparencia con respecto a los entornos de ejecución:

### 4.1 Probado en Base Local PostgreSQL (Puerto 54331, Base `remolques`)
- **Migración Bloque 1:** Aplicación limpia de `supabase/migrations/20261112_01_tablero_orden_fases.sql`.
- **Catálogo de fases:** 4 líneas creadas con un total de **55 fases** (Plataforma: 12, Góndola: 12 principales + 10 tina = 22, Dolly: 10, Traila: 11).
- **Creación de equipos:** Creación de orden de góndola manual con etiqueta libre y asignación de cliente.
- **Siembra de fases por RPC:** Invocación de `crear_fases_orden(org, orden_id)` sembrando exitosamente las 22 fases correspondientes.
- **Transición de fases por RPC:** Invocación de `actualizar_fase_orden(org, orden, fase, 'terminada', fecha, nota, usuario)`.
- **Subproceso de tina:** Avance de fase de tina a terminada y verificación del cálculo de avance `tina` (`1/10`).
- **Historial de fases:** Registro automático en `historial_fases` disparado por la RPC con estados anteriores y nuevos.

### 4.2 Probado en Navegador Real (Chrome Headless / Vite Dev Server)
- **Renderizado de la interfaz:** Matriz completa, vista por fase y adaptación a viewports de 1440 px, 768 px y 375 px.
- **Interacción del menú de celda:** Apertura, posicionamiento sin desbordes, cierre automático al seleccionar acciones y retención al editar nota / fechas.
- **Despliegue de subproceso de tina:** Conmutación del badge `▸ Tina` a acordeón horizontal con 10 celdas activas.
- **Combobox de clientes:** Filtro reactivo en modal "Nuevo equipo en planta" con búsqueda por texto y selección.
- **Reversión optimista:** Si una petición HTTP al backend simulado o real retorna error, el estado local revierte a `filaAnterior` y emite un toast descriptivo.

### 4.3 Qué NO se probó en Producción y Por Qué
- **Alta de órdenes y modificación de tina en Supabase Producción:** No se ejecutaron escrituras en la base de datos de producción (`gehkp3.easypanel.host`) para evitar dejar órdenes ficticias o alterar datos operativos de Armadora Leolca. Todas las mutaciones de prueba se confinaron al PostgreSQL local en el puerto 54331.

---

## 5. Verificación de Código y Suite de Pruebas

El comando integral de verificación del proyecto `node scripts/verificar.mjs --limpio` fue ejecutado, obteniendo un resultado perfecto:

```text
== 1. Archivos de parche o temporales nuevos
  OK     Sin parches ni temporales

== 2. Codificación de los archivos modificados
  OK     UTF-8 sin BOM ni mojibake — 23 archivos revisados

== 3. Sintaxis de .ts/.tsx modificados
  OK     Sintaxis válida

== 4. TypeScript (tsc --noEmit)
  OK     tsc: 0 nombres sin definir/duplicados
  OK     tsc: el total de errores no sube — 41 (baseline 55)

== 5. Build de Vite
  OK     npm run build

== 6. Pruebas Deno
  OK     Pruebas Deno — 334 pasan, 0 fallan

== 7. Arranque real del API
  OK     El API arranca — Listening on http://localhost:8000/

== 8. Contexto del Dockerfile.backend
  OK     Contexto del Dockerfile.backend — deno cache index.ts exitoso

== 9. Checkout limpio de HEAD (git archive)
  OK     Pruebas Deno en HEAD limpio — 333 pasan, 0 fallan
  OK     El API arranca en HEAD limpio — Listening on http://localhost:8000/

============================================================
RESULTADO: TODO OK  (11/11 comprobaciones)
```

---

## 6. Lista de Archivos Modificados en Ronda 2

- `src/app/utils/tableroProduccion.ts`: Formateador de fecha sin `capitalize` en conectores; funciones de formateo para estado, usuario y fase en historial; normalización con trim.
- `src/app/utils/tableroProduccion.test.ts`: Pruebas unitarias para formateadores de historial y fecha de cabecera (suite Deno subió a 334 pruebas).
- `src/app/components/TableroProduccion/CeldaFaseMenu.tsx`: Eliminación de flecha duplicada; cierre automático de menú en acciones discretas.
- `src/app/components/TableroProduccion/NuevoEquipoModal.tsx`: Consulta a columnas reales de `clientes` (`nombre_razon_social`, `nombre_contacto`); combobox con buscador insensible a acentos; estado de error y botón de reintentar; resolución de advertencia Radix `DialogContent`.
- `src/app/components/TableroProduccion/OrdenTrabajoDetalleSheet.tsx`: Integración de formateadores de historial; resolución de advertencia Radix `SheetContent`.
- `src/app/components/TableroProduccion/TableroProduccionPage.tsx`: Retiro de clase `capitalize` en párrafo de fecha.
- `src/app/components/TableroProduccion/VistaPorFase.tsx`: Visualización de todas las 12 fases principales con conteo y estado `Sin equipos`.
- `src/app/components/WelcomeTour.tsx`: Inclusión de `DialogDescription` para estandarizar accesibilidad Radix.
- `scripts/capturar_evidencia.mjs`: Script automatizado Chrome Headless (CDP) para captura de los 8 PNGs reales de evidencia.
- `COORDINACION/EVIDENCIA/*.png`: Las 8 capturas de pantalla reales (1440, 768, 375, celda abierta, tina expandida, historial, vista por fase y modal clientes).
