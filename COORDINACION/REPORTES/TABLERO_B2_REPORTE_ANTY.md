# Reporte Técnico — Tablero de Producción (Bloque 2 de 2: La Pantalla / Matriz por Línea)

**Fecha:** 2026-11-13  
**Herramienta:** Antigravity (Google DeepMind)  
**Rama:** `tablero-produccion-b2-2026-11-12`  
**Worktree:** `..\Remolques_tablero_b2`  
**Base de partida:** `main` (`8a6a171`)  
**Revisión:** Claude (sin merge ni push a `main`, sin tocar EasyPanel ni Supabase producción)

---

## 1. Resumen Ejecutivo

Se implementó de manera completa la interfaz de usuario del **Tablero de Producción (Bloque 2 de 2: Matriz por Línea)**, digitalizando el flujo operativo de planta de Armadora Leolca que anteriormente se gestionaba mediante el libro de cálculo Excel `PLATAFORMAS 09-11-2026.xlsx`. 

La solución ofrece una matriz de seguimiento interactiva por líneas de ensamble (`plataforma`, `gondola`, `dolly`, `traila`), visualización de cuellos de botella mediante `wip_por_fase`, edición inline ágil de material faltante, franja de subproceso para el ensamble de tina en góndolas, menú contextual popover accesible para avance de fases con un solo toque (evitando arrastres involuntarios en tablets con dedos grasosos), panel lateral de detalle con historial cronológico vertical y vista alternativa "Por fase" tipo Kanban.

Toda la implementación se validó con el checklist de verificación del proyecto `node scripts/verificar.mjs --limpio`, alcanzando **11/11 comprobaciones en verde**, 333 pruebas unitarias de Deno pasando sin fallas, compilación limpia de Vite, y una reducción neta en errores de TypeScript (de 55 a 41) al retirar código muerto del kanban legado.

---

## 2. Catálogo de Líneas y Fases

| Línea | Clave | Fases Principales | Subprocesos | Total Fases | Particularidad Visual |
| :--- | :--- | :---: | :---: | :---: | :--- |
| **Plataforma** | `plataforma` | 12 | — | 12 | Matriz estándar con fases 1..12 |
| **Góndola** | `gondola` | 12 | Ensamble de Tina (10) | 22 | Badge interactivo `▸ Tina n/10` / `✓ Tina lista` y franja acordeón expandible |
| **Dolly** | `dolly` | 10 | — | 10 | Columna libre rotulada **"Observaciones"** (en lugar de "Material faltante") |
| **Traila** | `traila` | 11 | — | 11 | Matriz estándar con 11 fases de ensamble |

---

## 3. Descripción Visual de las 4 Vistas Principales

### 3.1 Vista Matriz: Plataforma (12 fases)
- **Cabecera:** Título *"Tablero de producción"*, fecha larga en español (`"jueves, 12 de noviembre de 2026"`), buscador sensible a acentos (normalización NFD), botón primario `+ Nuevo equipo en planta` y botón de refresco suave `RefreshCw`.
- **Barra de control:** Pestañas de línea (`Plataforma`, `Góndola`, `Dolly`, `Traila`), selector de vista (`Matriz` / `Por fase`) sincronizados en la URL (`?linea=plataforma&vista=matriz`) y chips de filtro con conteo dinámico (`Todos`, `Atrasados`, `Con material`, `Con pausa`).
- **Fila de resumen "En proceso ahora":** Indica el conteo `wip_por_fase` de equipos en cada fase. La fase con mayor carga activa se resalta automáticamente con fondo ámbar suave y destello visual de **cuello de botella**.
- **Columna izquierda fija (Sticky):** Permanece visible al deslizar horizontalmente la tabla. Muestra semáforo en punto de color, etiqueta visible del equipo (ej. `Transportes Azteca #1`), modelo en subtítulo y acceso al drawer de detalle.
- **Columnas de avance y compromiso:** Refleja la proporción de fases principales completadas (ej. `6/12`) y la fecha compromiso (destacada en rojo si está vencida).
- **Material faltante editable inline:** Clic en la celda activa un input inmediato que guarda con `Enter` o `blur` (llamando a `PUT /produccion/ordenes/:id/planeacion`), o cancela con `Escape`. Si una fase está incompleta y no hay texto, emite un aviso sutil en rojo (`"Falta capturar qué material"`).

### 3.2 Vista Góndola: Subproceso Ensamble de Tina Expandible
- En la columna fija del equipo aparece un badge interactivo:
  - En proceso: `▸ Tina 8/10` (o `▾ Tina 8/10` al estar desplegado).
  - Al completar las 10 fases de tina: transmuta a badge verde `✓ Tina lista`.
- Al hacer clic en el badge, se despliega una franja acordeón horizontal inmediatamente debajo del equipo con fondo semitransparente primario, conteniendo sus 10 fases secuenciales (1. Bastidor tina, 2. Piso, etc.), cada una con los mismos botones y menú contextual de celda.
- El estado expandido/colapsado se recuerda en memoria de sesión por cada equipo.
- Avisos de subproceso: Si se intenta marcar como terminada la fase principal "Montado de tina" sin que la tina esté al 100%, el API emite un aviso (`"La tina va 8/10"`) que el frontend despliega en un toast tipo warning sin bloquear la acción del operador.

### 3.3 Vista Dolly: Columna "Observaciones"
- Adaptada a la nomenclatura de planta para dollies: el encabezado de la columna libre sustituye el texto "Material faltante" por **"Observaciones"**, permitiendo capturar anotaciones de chasis o perchas de forma inline.

### 3.4 Vista Alternativa: "Por fase" (Kanban Seguro)
- Conmutador `Por fase` en la barra de control (`?vista=fase`).
- Organiza tarjetas exclusivamente para fases activas (`en_proceso`, `incompleta`, `pausada`) más la columna `"Por iniciar"`.
- **Regla de concurrencia de fases:** Si un equipo tiene dos o más fases en proceso simultáneo (ej. Armado y Perchas), aparece reflejado en ambas columnas sin conflictos de clave única.
- **Sin Drag-and-Drop:** Se evitó intencionalmente el arrastre para prevenir movimientos accidentales en pantallas táctiles industriales. Cada tarjeta incluye su botón interactivo de fase para avanzar de estado con un solo toque seguro.

---

## 4. Mapeo de Estados Visuales de Celda

| Estado BD (`orden_fases`) | Condición / Propuesta | Texto Celda | Símbolo | Estilo Semántico Tailwind | Accesibilidad (`aria-label`) |
| :--- | :--- | :---: | :---: | :--- | :--- |
| `terminada` | Cualquiera (`fecha_fin`) | `✓ 06 nov` | `✓` | `text-emerald-500 bg-emerald-500/10 border-emerald-500/30` | `[Fase]: terminada el [Día] de [Mes]` |
| `en_proceso` | En tiempo (`fecha_propuesta >= hoy`) | `→ 14 nov` | `→` | `text-primary bg-primary/10 border-primary/30` | `[Fase]: en proceso, fecha propuesta [Día] de [Mes]` |
| `en_proceso` | Atrasada (`fecha_propuesta < hoy`) | `→ 11 nov !` | `!` | `text-destructive bg-destructive/10 border-destructive/40 font-bold` | `[Fase]: en proceso atrasada desde el [Día] de [Mes]` |
| `incompleta` | Faltante de material | `Material` | `Alert` | `text-destructive bg-destructive/10 border-transparent` | `[Fase]: incompleta por material faltante` |
| `pausada` | Pausa operativa | `Pausa` | `||` | `text-amber-500 bg-amber-500/10 border-amber-500/30` | `[Fase]: en pausa` |
| `pendiente` | Sin iniciar | `·` | `·` | `text-muted-foreground/40 bg-muted/20 border-transparent` | `[Fase]: pendiente` |

---

## 5. Menú Contextual de Celda (`CeldaFaseMenu.tsx`)

Al hacer clic en cualquier celda, se despliega un `Popover` accesible de Radix con las opciones pertinentes al estado actual:
- **Pendiente:** Botón "Iniciar hoy (+N días)" (calcula propuesta sumando `duracion_dias`), botón "Terminar hoy".
- **En proceso:** Botón "Terminar hoy", botón "Falta material (incompleta)", botón "Pausar", ajuste rápido de fecha (`-1 día` / `+1 día` o selector de calendario), campo de nota opcional y botón "Guardar".
- **Incompleta:** Botón "Reanudar (en proceso)", botón "Terminar hoy", edición de observaciones.
- **Pausada:** Botón "Reanudar (en proceso)", botón "Terminar hoy".
- **Terminada:** Botón "Reabrir (en proceso)" con recálculo automático a `hoy + duracion`.
- **Cualquier estado:** Separador inferior con botón "Limpiar (volver a pendiente)".
- **Actualización optimista y reversión:** La función pura `aplicarCambioOptimistaFase` actualiza el estado local y semáforos inmediatamente. Si la petición HTTP falla, revierte a `filaAnterior` y notifica mediante toast de error.

---

## 6. Panel Lateral de Detalle e Historial (`OrdenTrabajoDetalleSheet.tsx`)

- Implementado con `Sheet` de Radix / shadcn, se despliega al dar clic sobre el nombre del equipo en la columna fija.
- **Cabecera técnica:** Etiqueta editable en vivo, semáforo, cliente, cotización de origen, modelo, avance general y estado de tina.
- **Edición de planeación:** Fecha de compromiso y material faltante con botón de guardado hacia `PUT /produccion/ordenes/:id/planeacion`.
- **Acceso directo a tareas:** Botón "Ver tareas de producción" que navega directamente a `/plan-semanal?tab=trazabilidad&ordenId={orden_id}`.
- **Línea de tiempo vertical de historial:** Consulta `GET /produccion/ordenes/:id/historial` y renderiza una bitácora cronológica con la transición de estado (`estado_anterior → estado_nuevo`), fecha propuesta, notas capturadas, usuario responsable y tiempo relativo (`"hace unos segundos"`, `"hace 2 horas"`).

---

## 7. Modal "Nuevo Equipo en Planta" (`NuevoEquipoModal.tsx`)

- Implementado con `Dialog` de Radix / shadcn, accesible desde el botón primario de la cabecera.
- Permite ingresar órdenes manuales para piso de venta o stock sin depender de cotización.
- **Campos:**
  - Selector de línea (por omisión la línea activa).
  - Selector de modelo canónico (con opción de modelo personalizado).
  - Selector de cliente (opcional; si no se asigna, la orden queda catalogada como inventario).
  - Etiqueta identificadora visible (obligatoria si no hay cliente; si hay cliente, prellena el nombre).
  - Fecha de compromiso opcional y observaciones técnicas.
- Al confirmar, llama a `POST /produccion/ordenes`, inserta la orden con sus fases sembradas, recarga la matriz y abre de inmediato el panel lateral de detalle para permitir afinaciones.

---

## 8. Accesibilidad y Responsividad

1. **Prevención de trampa horaria UTC:** Toda manipulación de fechas utiliza descomposición aritmética pura `[año, mes, día]` mediante `parsearFechaPartes` y `formatearFechaCorta`, eliminando por completo el bug de corrimiento de un día provocado por `new Date('YYYY-MM-DD')` en huso horario `America/Mexico_City` (UTC-6).
2. **Dimensiones táctiles:** Todas las celdas interactivas cuentan con dimensiones mínimas de **78 px de ancho por 40 px de alto**, cumpliendo holgadamente con los estándares WCAG para áreas de toque con el dedo.
3. **Contraste y tokens semánticos:** Cero colores oscuros fijos (`bg-slate-900`, etc.); se emplearon variables semánticas de Tailwind (`bg-card`, `bg-popover`, `text-foreground`, `text-muted-foreground`, `border-border`), garantizando soporte natural para Modo Claro y Modo Oscuro.
4. **Comportamiento responsive:**
   - **Desktop (1440 px):** Matriz extendida con 12 fases principales a la vista, resumen de cuello de botella y columna sticky.
   - **Tablet (768 px):** Columna sticky de 180 px fija a la izquierda con desplazamiento horizontal suave para las columnas de fase.
   - **Móvil (375 px):** Visualización sin desbordes raros en el contenedor exterior; la vista "Por fase" se adapta en formato de tarjetas apilables.

---

## 9. Evidencia Visual

Las representaciones visuales vectoriales generadas se encuentran archivadas en `COORDINACION/EVIDENCIA/`:
- `COORDINACION/EVIDENCIA/matriz_desktop_1440.svg`: Vista extendida en escritorio con cuello de botella e indicadores.
- `COORDINACION/EVIDENCIA/matriz_tablet_768.svg`: Comportamiento de columna sticky y área de toque en tablet.
- `COORDINACION/EVIDENCIA/matriz_mobile_375.svg`: Adaptación móvil en tarjetas compactas.
- `COORDINACION/EVIDENCIA/gondola_tina_expandida.svg`: Franja de subproceso de tina con sus 10 fases desplegadas.

---

## 10. Resumen de Pruebas y Verificación

- **Pruebas unitarias de utilerías (`tableroProduccion.test.ts`):** 8/8 pruebas pasando (mapeo de líneas, semáforos, etiquetas correlativas, trampa UTC, estados visuales, filtros de búsqueda NFD, agrupamiento por fase y optimismo).
- **Pruebas Deno globales:** **333 pasadas** (0 fallas).
- **TypeScript (`tsc --noEmit`):** 0 nombres duplicados o sin definir; errores globales reducidos a **41** (baseline 55).
- **Script de verificación integral (`node scripts/verificar.mjs --limpio`):** **11/11 comprobaciones en verde (TODO OK)**.
