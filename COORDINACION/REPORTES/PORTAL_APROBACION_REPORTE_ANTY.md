# Reporte Técnico — Portal del cliente: aprobación no reflejada en el sistema (Bloque A)

**Fecha:** 2026-11-21  
**Rama:** `fix-portal-aprobacion-2026-11-21` (worktree `..\Remolques_portal_aprobacion`, desde `main` `a3481d0`)  
**Referencia:** `COORDINACION/PLAN_CAMBIOS_VISITA_2026-11-20.md` (Bloque A)

---

## 1. Tabla de hipótesis (Paso 0 — Reproducción previa contra Postgres local `test_portal_aprobacion`)

| # | Hipótesis | Veredicto | Evidencia medida antes de tocar código |
|---|---|---|---|
| 1 | El portal miente al cliente (`res.ok` ignorado) | **CONFIRMADA** | `PortalCliente.tsx:90-100` (`handleAprobar`), `109-115` (`handleRechazar`) y `124-130` (`handleCambios`) ejecutan `await fetch(...)` sin verificar `res.ok`. Ante HTTP `409` / `410` / `500`, el portal igualmente asigna `setResultado('aprobado')` y muestra `"¡Cotización Aprobada!"`. |
| 2 | Solo se aprueba desde `Enviada` | **CONFIRMADA** | `index.ts:344` devuelve `409 {"error":"La cotización ya fue procesada"}` si la cotización está en `Borrador` o `Cancelada` (reproducido en casos `b1` y `b2`: BD permanece en `Borrador`/`Cancelada`, `estado_produccion = 'Pendiente'`). Combinado con H1, el cliente ve éxito falso. |
| 3 | Aprobación a medias (`aplicarAprobacion`) | **CONFIRMADA (con matiz)** | `index.ts:348-357` actualiza `estado = 'Aprobada'` primero y luego llama `aplicarAprobacion`. En `ejecutarAprobacionCotizacion` (`motor/generar_presupuesto_cotizacion.ts:301`), el `update({ estado_produccion: 'Aprobada' })` no revisaba `{ error }`: al forzar un fallo en BD (caso `d`), `estado` quedó `'Aprobada'` y `estado_produccion` quedó `'Pendiente'` sin lanzar error. Si `aplicarAprobacion` lanza excepción, `index.ts:360` responde `500` sin `console.error`, dejando la cotización en `Aprobada` sin efectos. |
| 4 | Pisado por el sistema interno (`PUT /cotizaciones/:id`) | **CONFIRMADA** | `CotizacionEditor.tsx:491-503` envía `...formData` (incluyendo `estado` con el que abrió el formulario). Reproducido: con copia interna en `Enviada`, se aprobó por el portal (`estado = 'Aprobada'`, `firma_nombre = 'Maria Lopez'`), y al ejecutar `PUT /cotizaciones/:id` con el payload viejo regresó `estado` a `'Enviada'` en BD. *(No modificado en este bloque por regla; ver propuesta en §4).* |
| 5 | Lista interna con datos viejos | **CONFIRMADA** | `useSupabaseData.ts:408-410` solo ejecuta `loadData()` una vez al montar (`[token]`) y guarda en `useState` + `localStorage`. No usa TanStack Query ni escucha `focus`/`visibilitychange`. Además, ni `CotizacionesTableModern.tsx` ni `CotizacionDetalle.tsx` mostraban `firma_nombre`/`firma_fecha` ni `cotizacion_eventos`. |

---

## 2. Cambios implementados

### Backend (`supabase/functions/make-server-feea4382/`)
1. **`motor/portal_aprobacion.ts`** (nuevo):
   - `aprobarPorPortal`: valida `firma_nombre` y `firma_imagen` (`400`), token (`404`), expiración (`410`), estado previo (`409` diferenciando `YA_APROBADA` vs `ESTADO_NO_DISPONIBLE`). Ejecuta actualización atómica `UPDATE ... WHERE id = ? AND estado = 'Enviada'`. Registra evento `"Aprobada por el cliente desde el portal — Firma: <nombre>, IP: <ip>, Fecha: <iso>"`. Ejecuta `aplicarEfectos` dentro de `try/catch`; si falla, registra `console.error` + evento `"Aprobada desde el portal — efectos pendientes: <mensaje>"` y responde `200 { success: true, efectos_pendientes: true }`.
   - `rechazarPorPortal` y `solicitarCambiosPorPortal`: actualización atómica con `WHERE estado = 'Enviada'`, validación de comentario (`400`) y registro de evento con IP y fecha.
2. **`motor/generar_presupuesto_cotizacion.ts`** (líneas 294-346):
   - `ejecutarAprobacionCotizacion` ahora valida `resProd?.error`, evita degradar `estado_produccion` si ya avanzó de `'Pendiente'`, y evita duplicar el evento `"Cotizacion aprobada"` en reintentos.
3. **`index.ts`** (líneas 15, 332-399):
   - Delegación de `POST /portal/:token/{aprobar,rechazar,solicitar-cambios}` a `motor/portal_aprobacion.ts` con `console.error` en `catch`.

### Frontend (`src/app/`)
4. **`components/Portal/portalAcciones.ts`** (nuevo) y **`components/Portal/PortalCliente.tsx`**:
   - Verifica `res.ok` antes de marcar éxito.
   - Muestra mensajes específicos: `"Esta cotización ya fue aprobada."`, `"Esta cotización ya no está disponible para aprobar, contacta a tu asesor."`, `"El enlace expiró."`, o error genérico con botón **Reintentar**.
   - Tokens semánticos (`bg-primary`, `bg-destructive/10`) e íconos Lucide sin emojis en botones ni gradientes.
5. **`hooks/useSupabaseData.ts`** (líneas 1, 412-462):
   - `refrescarCotizaciones` silencioso al recuperar `focus` / `visibilityState === 'visible'` (con throttle de 3s) y cada 30s mientras la pestaña está visible.
6. **`components/Cotizaciones/CotizacionesTableModern.tsx`** (líneas 5, 69-79, 330-335, 482-487):
   - Marca `"Aprobada por el cliente — <nombre>, <fecha>"` debajo del badge de estado en vista móvil y escritorio.
7. **`components/Cotizaciones/CotizacionDetalle.tsx`** y **`App.tsx`**:
   - Banner de aprobación por cliente con nombre, fecha e IP.
   - Tarjeta **Historial de Eventos** mostrando `cotizacion_eventos` de la cotización.

---

## 3. Pruebas y Verificación

- **Pruebas Deno**:
  - Antes: `223 passed | 0 failed`
  - Después: **`237 passed | 0 failed`** (+14 pruebas nuevas: 9 en `motor/portal_aprobacion.test.ts` incluyendo carrera concurrente, firma ausente, fallos de efectos e idempotencia; 5 en `motor/portal_acciones_frontend.test.ts` incluyendo regresión de HTTP 409).
- **`node scripts/verificar.mjs --limpio`**: **11/11 comprobaciones OK** (`npm run build` exitoso, `tsc` 0 nombres sin definir, arranque de API OK).

---

## 4. Propuesta para Hipótesis 4 (pendiente decisión de Claude y Luis)

Como `PUT /cotizaciones/:id` sobrescribe `estado` cuando un usuario interno guarda con una copia previa:
- **Propuesta**: En `PUT /cotizaciones/:id` (`index.ts:1804-1818`), si `previous.estado === 'Aprobada'`, impedir que un `PUT` estándar regrese `estado` a `'Enviada'` o `'Borrador'` (y eliminar `firma_imagen`, `firma_nombre`, `firma_fecha`, `firma_ip` del payload editable de `PUT`, o devolver `409 Conflict` si el cliente intenta editar una cotización que cambió de estado desde que la abrió).

---

## 5. Despliegue requerido

1. **Migración SQL**: No requerida.
2. **Backend**: Redeploy de la Edge Function / servicio `remolques-api` en EasyPanel (**Rebuild**).
3. **Frontend**: Rebuild de `remolques-web` en EasyPanel.
