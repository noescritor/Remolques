# Reporte Técnico — Bloque H: Expediente por Equipo + Liberación de Material por Fase

**Fecha:** 2026-11-22  
**Rama:** `expediente-h-2026-11-22` (worktree `..\Remolques_expediente_h`, desde `main` `8c26141`)  
**Commit de código verificado:** `9facf4a` (árbol limpio, `git status` vacío)  
**Referencia:** `PROMPT_ANTY_EXPEDIENTE_H_2026-11-22.md`, `COORDINACION/PLAN_CAMBIOS_VISITA_2026-11-20.md` (Bloque H)

---

## 1. Qué se construyó (archivos y alcance)

1. **Backend de solo lectura (`supabase/functions/make-server-feea4382/motor/resumen_entregas.ts`, `index.ts`, `motor/resumen_entregas.test.ts`)**:
   - Nueva ruta `GET /ordenes-trabajo/resumen-entregas` que consulta `v_orden_despiece_avance` **en una sola consulta** filtrada por `organizacion_id` con el cliente de usuario (RLS).
   - **Definición de "porcentaje de entregas":** `Math.round((partidas_completas / total_partidas) * 100)`, donde una partida es completa cuando `cantidad_entregada >= cantidad_requerida` (las unidades son heterogéneas — piezas, kg, litros — por lo que no se suman cantidades). Incluye líneas manuales y excluye líneas anuladas (`anulada = true`); sin partidas retorna `null` (no `0%`).
2. **Funciones puras y pruebas Deno (`src/app/components/Expediente/expedienteUtils.ts` y `motor/expediente_utils.test.ts`)**:
   - `faseEnCurso(fases)`: prioriza `en_proceso`, luego primera fase no `terminada`, o `null`.
   - `estadoVisualFase(fase, faseEnCurso)`: `'en_curso' | 'pasada' | 'futura'` (estrictamente visual).
   - `resumenEntregasPorFase(lineas)` y `porcentajeEntregas(resumen)`: resumen global y por fase, excluyendo anuladas y contando sobre-entregas como completas.
   - `puedeLiberarFase()`: siempre retorna `{ permitido: true, motivo: null }` (las fases futuras siguen siendo operables).
   - `estadoVacioPestana(...)`, `normalizarTabExpediente(...)` y `resolverPresupuestoDeOrden(...)`.
3. **Extracción compartida (`src/app/components/OrdenesTrabajo/ChecklistDespiecePanel.tsx` y `ChecklistDespieceModal.tsx`)**:
   - Se extrajo el contenido de `ChecklistDespieceModal` a `ChecklistDespiecePanel` sin alterar la lógica de `checklist_almacen.ts` ni el comportamiento del modal existente.
   - En modo embebido (`modoEmbebido`), cada fase muestra su estado, `"X de Y partidas completas"`, resaltado de `"Fase en curso"`, atenuación visual de `"Fase futura"` (siempre operable), botón `"Liberar fase completa"` con confirmación, quién y cuándo entregó (`ultima_entrega`), y estado vacío diferenciado para líneas sin receta (ej. Tráila).
   - **Hallazgo heredado de `ChecklistDespieceModal.tsx:132`:** el panel llama `GET /operarios` que responde `404` porque la ruta real en `index.ts` es `/produccion/operarios`; el componente cae silenciosamente a captura manual de nombre y no se modificó la ruta para no tocar comportamiento heredado del modal sin aprobación.
4. **Pantalla `/expediente/:ordenId` (`ExpedienteEquipoPage.tsx` y `expedienteApi.ts`) y puntos de entrada**:
   - Encabezado fijo con botón **Volver**, datos del equipo y alerta de `material_faltante`; pestañas sincronizadas en URL (`?tab=resumen|cotizacion|orden|plan|almacen|calidad|cobranza`) con scroll horizontal propio en tableta/móvil.
   - **Cómo se ligan cotización y presupuesto hoy:** `presupuestos.cotizacion_id = cotizaciones.id` y folio `PRE-<folio de la cotización>` (`generar_presupuesto_cotizacion.ts:158`). La pestaña **Cotización y presupuesto** resuelve ambos en solo lectura sin recalcular nada.
   - **Calidad:** monta `OrdenCalidadTab` directamente (reutilizado del Sheet con `linea_clave` y `ajustes`).
   - **Cobranza (solo lectura):** consulta `GET /pagos/cotizacion/:id` etiquetado **"Pagos de la cotización"**, aclara si la cotización cubre varios equipos y muestra el aviso de alcance.
   - **Equipos manuales sin cotización:** estado vacío claro en Cotización/presupuesto y Cobranza, sin errores.
   - **4 puntos de entrada:** `OrdenTrabajoDetalleSheet` ("Abrir expediente"), `OrdenesTrabajoList` (ícono de expediente), `CalidadPage` (enlace en columna equipo → `?tab=calidad`) y `CuadriculaSemanal` en Plan Semanal (badge de OT → `?tab=plan`).
   - **Tablero (`MatrizProduccionView.tsx`):** insignia `"Almacén X/Y"` junto a `"Calidad X/Y"` en una sola llamada a `/ordenes-trabajo/resumen-entregas`.

---

## 2. Pruebas y Verificación

- **Pruebas Deno desde raíz del repo:**
  - Antes (C2 Ronda 3): `260 passed | 0 failed`
  - Después: **`269 passed | 0 failed`** (+3 en `motor/resumen_entregas.test.ts` incluida guardia de aislamiento org, +6 en `motor/expediente_utils.test.ts`).
- **Prueba real en navegador (Chrome Headless CDP contra Vite + API local + Postgres desechable `test_expediente_h`):**
  - `Console errors: []`
  - **Tablero → Sheet → Expediente:** insignia inicial `Almacén 1/4` → clic en `Abrir expediente` (`/expediente/27c73db7-...`) → cambio a `?tab=almacen` y recarga conservando pestaña, `"Fase en curso"` y `"Fase futura"` visibles.
  - **Corte de API a propósito (`/despiece/entregar` → 500):** diálogo de error visible (`"Corte simulado de API en Almacen"`), sin pérdida de estado.
  - **Liberar fase completa (Paso 2):** confirmación con operario `"Carlos Lopez"` → `"Se entregaron atómicamente 2 partidas de la fase Paso 2"`, progreso actualizado en el panel (`12/22`, `55%`) e insignia en el tablero actualizada a **`Almacén 3/4`**.
  - **Lista de órdenes:** modal original `ChecklistDespieceModal` sigue funcionando (`expediente_h_05_modal_original.png`); equipo manual sin cotización (`99-GON021126-1`) abre en `/expediente/48690997-...` sin errores.
  - **Calidad y Plan Semanal:** enlace desde Calidad abre `/expediente/...?tab=calidad`; enlace desde tarea en Plan Semanal (`2026-11-18`) abre `/expediente/...?tab=plan`.
  - **Responsive sin scroll horizontal:** Tableta `768px` (`winW: 768, docScrollW: 768`) y Móvil `375px` (`winW: 375, docScrollW: 375`).
  - Capturas en `COORDINACION/EVIDENCIA/expediente_h_01..08_*.png`.
- **Integridad de precios/despiece (`git diff --stat main..HEAD`):** 0 cambios en `receta_base`, `costos_modelo`, `procesos_manufactura`, `opcion_costos`, `productos`, `motor/checklist_almacen.ts` ni migraciones.
- **`npm run build`**, **`tsc --noEmit`** y **`node scripts/verificar.mjs --limpio`** (árbol limpio).

---

## 3. Qué falta confirmar con Luis (preguntas abiertas)

1. **Cobranza por equipo:** hoy el pago se liga a la cotización. Si una cotización cubre varios equipos, ¿cómo se reparte? (lo resuelve el bloque de cobranza, no este).
2. **Porcentaje de entregas:** ¿el porcentaje de entregas por partidas completas es el que quieren ver, o prefieren por fase en curso?
3. **Entrega y recepción en almacén:** ¿quién del almacén libera el material y quién lo recibe en planta? (para decidir si falta un "recibido por" en la entrega).
4. **Catálogo de operarios en checklist (`/operarios` vs `/produccion/operarios`):** ¿se apunta `ChecklistDespiecePanel` a `/produccion/operarios` para evitar el `404` heredado del modal?

---

## 4. Despliegue (cuando se apruebe el merge)

1. **Migración SQL:** No requerida.
2. **Backend (`remolques-api` en EasyPanel):** Hacer **Rebuild** (por `GET /ordenes-trabajo/resumen-entregas`).
3. **Frontend (`remolques-web` en EasyPanel):** Hacer **Rebuild**.

---

## 5. Ronda 2 (correcciones tras revisión de Claude `EXPEDIENTE_H_REVISION_CLAUDE.md`)

- **Commit de código verificado:** `3e8932e` (construido sobre `0437e0d`, árbol limpio `git status` vacío).
- **D1 — Plan semanal con respuesta real `{ orden, tareas, bitacora }`**:
  - `expedienteApi.trazabilidadOrden` tipado como `TrazabilidadOrdenResponse`.
  - `extraerTareasPlan` en `expedienteUtils.ts` lee `res.tareas` y `ExpedienteEquipoPage.tsx` muestra `fecha`, `descripcion`, `estado`, `frente.nombre` / `frente.area.nombre` y `operarios[].nombre`.
- **D2 — Estados independientes `cargando | error | ok` y `Promise.allSettled`**:
  - Eliminados los `.catch(() => [])` que ocultaban fallos como "sin datos". Cada sección (Resumen, Presupuestos, Plan semanal, Calidad, Cobranza, Fases del tablero) tiene su propio estado, aviso de error y botón **Reintentar**.
  - `refrescarResumenSilencioso` usa `Promise.allSettled` y conserva los datos previos si falla.
- **D3 — Sin emparejamiento numérico entre catálogos de fases**:
  - `ChecklistDespiecePanel.tsx` ya no resalta/atenúa fases ni muestra `"Terminada en planta"` por coincidencia numérica; `"Liberar fase completa"` sigue disponible en todas las fases.
  - `ExpedienteEquipoPage.tsx` muestra en el encabezado fijo **`Tablero: en <fase>`** según `faseEnCurso(fasesEquipo)`.
- **D4 — Paginación en `resumenEntregasOrdenesMotor`**:
  - Pagina `v_orden_despiece_avance` con `.order("linea_id", { ascending: true }).range(desde, hasta)` en bloques de `1000` hasta recibir un bloque corto. Probado en Deno con simulador de `1250` filas (`[0, 999]` y `[1000, 1999]`) y propagación de error DB.
- **Observaciones 1, 2, 3 y 5**:
  - Criterio único de "partida completa" (`esPartidaCompleta` en servidor y `esPartidaCompletaLinea` en `expedienteUtils.ts` + `ChecklistDespiecePanel.tsx`): usa `estado_entrega === 'completo'` cuando viene de la vista SQL o `ent > 0 && ent >= req` (evita `0 >= 0`). La insignia `"Completa"` de cada fase usa `partidasCompletas === partidasDeFase.length`.
  - `ExpedienteEquipoRoute` en `App.tsx` pasa `key={ordenId}` a `ExpedienteEquipoPage`.
- **D5 — Pruebas y mutaciones (`COORDINACION/REVISIONES/arnes_revision_h/mutar_h.cjs`)**:
  - Ejecución sobre export limpio (`git archive 0437e0d`, idéntico en lógica a `3e8932e`): **Detectadas 38/38 (inválidas: 2), Vivas: ninguna** (cubiertas `G3`, `G4`, `G9`, `G10`, `G11`, `G12`, `E3`, `E7`–`E13`, `E18`, `E21`, `E22`).
- **Evidencia navegador Ronda 2** (`COORDINACION/EVIDENCIA/expediente_h_r2_*.png`):
  - `expediente_h_r2_01_plan_semanal.png` (tarea visible con forma real `{ orden, tareas, bitacora }`), `expediente_h_r2_02_almacen_sin_emparejar.png` (`Tablero: en Corte` en encabezado, Almacén sin emparejamiento), `expediente_h_r2_03_corte_carga_cobranza.png` (corte de API en la carga mostrando error + `Reintentar`, recuperado al reintentar).
