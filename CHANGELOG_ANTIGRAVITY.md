# Changelog de cambios y hallazgos — Remolques

Bitácora obligatoria para cualquier cambio hecho con Antigravity o Claude Code.
Formato: entradas nuevas **arriba**. Una entrada por sesión/cambio.

## Plantilla

```
## AAAA-MM-DD — <título corto>
**Herramienta:** Antigravity | Claude Code
**Tipo:** cambio | hallazgo | fix | migración
**Archivos tocados:** ruta1, ruta2
**Qué cambió / qué se encontró:** …
**Por qué:** …
**Acciones manuales pendientes:** (Rebuild backend en EasyPanel / correr SQL X en Supabase / ninguna)
**Verificado:** (build, prueba manual, sin verificar)
**Ref. auditoría:** (ej. S3, F1)
```

---

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



## 2026-09-20 — Confirmación de producción: sin respaldos, betics se da de baja
**Herramienta:** Claude Code
**Tipo:** hallazgo / decisión
**Archivos tocados:** solo este changelog. Sin cambios de código. **Ninguna llave se guardó en archivos.**
**Qué cambió / qué se encontró (por pantallazo del panel de Supabase y variables de entorno que compartió el dueño):**
- 🔴 **Proyecto `djwl…` ("Remolques"): "Last backup: No backups"**, compute NANO, "No migrations" (las migraciones se corren a mano; no hay historial en Supabase), sin repositorio conectado. RAM 57 % en Nano; 8/60 conexiones. **Producción no tiene ningún respaldo.**
- ✔ Variables de la API confirmadas: `SUPABASE_URL` = `djwl…` (correcto), `SUPABASE_ANON_KEY` y `SUPABASE_SERVICE_ROLE_KEY` presentes en el servidor (lugar correcto).
- 🔴 La `SUPABASE_SERVICE_ROLE_KEY` de producción fue pegada en el chat → **rotar** (después del primer respaldo).
- ✘ Bloque `VITE_SUPABASE_URL=http://ws2.cloud.betics.com.mx:8000` + `VITE_SUPABASE_ANON_KEY` (llave de demostración de Supabase self-hosted) **obsoleto**: el frontend en producción usa `.env.production` (→ `djwl…`). Peligro latente: si se agrega `ARG VITE_*` al Dockerfile, estos valores **ganarían** sobre `.env.production` y romperían producción. Eliminarlos de donde estén definidos.
- `VITE_API_URL` está definido pero el código usa un `BASE_URL` hardcodeado: la variable es ignorada.
- **Decisión del dueño:** el servidor `ws2.cloud.betics.com.mx` fue una prueba fallida → se da de baja.
**Acciones manuales pendientes (dueño):** (1) respaldo manual hoy, (2) decidir plan con respaldos automáticos, (3) rotar service_role, (4) borrar variables VITE_ de betics y luego el servidor.
**Verificado:** Solo lectura de lo que compartió el dueño.
**Ref. auditoría:** S1, C11; Bloque 0 tarea 0.1

## 2026-09-20 — Respuestas del dueño y verificación de servidores
**Herramienta:** Claude Code
**Tipo:** hallazgo / decisión
**Archivos tocados:** `ARQUITECTURA_REVISION_2026-09-20.md` (secciones 1.1, 3.A, 3.D, 3.M, 5, 7). Sin cambios de código.
**Qué cambió / qué se encontró:**
- **Decisiones cerradas:** un solo cliente (se congela lo multi-tenant, se conserva `organizacion_id`/RLS); material **por modelo fijo** (el BOM por producto del Bloque 1 es correcto).
- **Base de producción = Supabase Cloud `djwl…`** (deducido): `nginx-supa.conf` reenvía a `djwl…` y el bundle desplegado tiene 13 referencias a ese host. **Corrige** la hipótesis previa de que las categorías iban a otra base.
- Servidores vivos (probados sin credenciales): `djwl…`, proxy `remolques-remolques-supa`, API `remolques-remolques-api` (`/health` OK), web, `ws2.cloud.betics.com.mx:8000` (self-hosted, HTTP plano, hoy solo en `.env` local) y el proyecto original `kntbz…`.
- El frontend desplegado es el de **antes del Bloque 1** (mismo hash de bundle que el build local previo): nada del Bloque 1 está en producción.
**Por qué:** El dueño no sabía cuál era la base de producción; se dedujo de los artefactos.
**Acciones manuales pendientes (dueño):** verificar plan y respaldos de `djwl…`, y el `SUPABASE_URL` del servicio API en EasyPanel (guía en §7 del documento). Si no hay respaldos: exportación manual inmediata.
**Verificado:** `GET` sin credenciales a 6 hosts; lectura de `nginx-supa.conf`; búsqueda de hosts en el bundle público. No se leyeron llaves ni datos.
**Ref. auditoría:** C11 (deploy duplicado), S5

## 2026-09-20 — Revisión de arquitectura (modo Arquitecto)
**Herramienta:** Claude Code
**Tipo:** hallazgo
**Archivos tocados:** `ARQUITECTURA_REVISION_2026-09-20.md` (nuevo). Sin cambios de código.
**Qué cambió / qué se encontró:** Revisión de arquitectura con el método de The Architect. Veredicto: dirección de producto correcta, cimientos de ingeniería insuficientes. Hallazgos nuevos verificados en archivos:
- 🔴 **Tres Supabase distintos configurados:** `.env` → self-hosted por HTTP plano; `.env.production` (el que usa `vite build`) → proyecto Cloud `djwl…`; `client.ts` y `BASE_URL` hardcodeados a EasyPanel. Las categorías (`/rest/v1/categorias_*`) usan `VITE_SUPABASE_URL`, es decir, probablemente otra base que la del login/API en producción.
- 🔴 Dos mitades de despliegue manuales sin CI ni contrato de versión; dos Dockerfiles de frontend distintos.
- 🔴 Autorización en cuatro caminos (API con service client, API con cliente de usuario, PostgREST directo desde el navegador, `/supa-proxy`); ninguna ruta valida rol; rol leído de `user_metadata`.
- 🟠 `ON DELETE CASCADE` de `ordenes_trabajo` y `cotizacion_eventos` hacia `cotizaciones`: borrar una cotización elimina producción y auditoría.
- 🟠 El material real está en Presupuestos (texto libre) y no en el BOM por producto; la requisición se calcula por cotización y no por orden de trabajo; `stock_reservado` nunca se escribe; recepción de compras todo-o-nada.
- 🟠 Tres máquinas de estado en paralelo; `estado_produccion` sin CHECK; ids `TEXT` vs `UUID` mezclados (causa del error de `ajustar_stock`).
- Ruta propuesta: 1-FIX → Bloque 0 Cimientos → 2 Material por OT → 3 Permisos y dinero → 4 Costo y planta → 5 Escala. Detalle y decisiones abiertas en el documento.
**Por qué:** Evaluar si la planeación es sólida antes de seguir con más bloques.
**Acciones manuales pendientes:** Responder las 3 preguntas de la sección 7 del documento; confirmar cuál es la base de producción real y si hay respaldos.
**Verificado:** Lectura de `.env*`, `client.ts`, Dockerfiles, migraciones y backend (solo hosts, sin exponer llaves). No se ejecutó nada.
**Ref. auditoría:** C7, C8, C11, S5, F4, F11, F12 (ampliados)

## 2026-09-18 — Revisión de Claude Code al Bloque 1 (1A–1E): NO listo para desplegar
**Herramienta:** Claude Code
**Tipo:** hallazgo
**Archivos tocados:** `PROMPT_ANTY_BLOQUE1_FIX.md` (nuevo). Sin cambios de código.
**Qué cambió / qué se encontró:** Revisión de `git diff 04f1e7e HEAD` (5 commits locales, sin push). `npm run build` pasa (7.9 s), pero el build no compila el backend. Hallazgos:
- 🔴 `registrarEvento`, `aplicarAprobacion` y `calcularRequisicion` se llaman en 9 lugares de `index.ts` y **no están definidas en ningún commit** → `ReferenceError`; en portal aprobar/rechazar y crear compra el fallo ocurre tras guardar en BD.
- 🔴 El commit `d5b5a05` **eliminó** `/presupuestos` (4 rutas), `/produccion/lineas` y `/produccion/fases`; el frontend las sigue llamando con `.catch(() => [])` → Presupuestos y Kanban quedarían vacíos sin error visible.
- 🔴 Rutas nuevas (`/productos/:id/materiales`, `/cotizaciones/:id/requisicion`, `/historial`) están registradas antes de `authMiddleware` (líneas 26-118 vs. 478) → `supabase`/`organizacionId` undefined → 500.
- 🔴 `VITE_SUPABASE_API_URL` (usada en `GenerarRequisicionModal` y `ProductosList`) no existe en ningún `.env` → BOM y requisición prellenada no funcionan.
- 🔴 Migración SQL: `ajustar_stock` usa UUID pero `productos.id` es TEXT; redefine `obtener_siguiente_produccion` con otra secuencia (folios duplicados vs. `seq_produccion_global`); no hace backfill de `organizacion_id` en `producto_materiales`; quedó sin trackear en la raíz (no en `supabase/migrations/`).
- 🟠 `PUT /cotizaciones/:id` calcula `isNowApproved` y no lo usa (aprobar manual no dispara nada); `mover` no marca `completada` ni pasa a `Surtido`; no hay UI para el 409/`force`; falta badge de `estado_produccion` en listas; `/historial` usa tabla `usuarios` inexistente; crear compra ya no revisa el error de `compra_items`.
- ✔ Confirmado como bien hecho: validación de portal (expiración, estado `Enviada`, IP por header) en los 3 endpoints; folio de compra en servidor; recepción idempotente (comparación con estado previo); `generar-ordenes` idempotente y sin regla `<10000` ni aleatorio; fix del CHECK de `estado_kanban` (`'incompleta'`).
- ⚠ Proceso: 1A–1E no dejaron entradas en el changelog; el SQL quedó suelto; `PLAN_DUPLICAR_REMOLQUES.md` §7 contiene afirmaciones inexactas.
**Por qué:** Verificación de lo declarado en `PLAN_DUPLICAR_REMOLQUES.md` §7.
**Acciones manuales pendientes:** **No hacer push ni Rebuild del backend** hasta cerrar `PROMPT_ANTY_BLOQUE1_FIX.md`. Nada se ha desplegado (`main` va 5 commits adelante de origin).
**Verificado:** Lectura de diff y esquema; `npm run build`. No se ejecutó el backend.
**Ref. auditoría:** F1, F3, F14, F15, F16, S4 (parcial); nuevos hallazgos en este bloque.

## 2026-09-18 — Prompt del Bloque 1 (aprobar → requisición → producción)
**Herramienta:** Claude Code
**Tipo:** hallazgo
**Archivos tocados:** `PROMPT_ANTY_BLOQUE1_APROBAR_REQUISICION_PRODUCCION.md` (nuevo)
**Qué cambió / qué se encontró:** Se preparó el plan del bloque 1 para que lo ejecute Antigravity, con verificación previa de la auditoría. Hallazgo nuevo: `PUT /produccion/ordenes/:id/material` escribe `estado_kanban='material_faltante'`, valor que la migración `20260916` no permite en su CHECK (pendiente de confirmar por Antigravity).
**Acciones manuales pendientes:** ninguna (aún no hay cambios de código).
**Verificado:** solo lectura de código.
**Ref. auditoría:** F1, F2, F3, F14, F15, F16, S4

## 2026-09-18 — Auditoría inicial del sistema
**Herramienta:** Claude Code
**Tipo:** hallazgo
**Archivos tocados:** `AUDITORIA_2026-09-18.md` (nuevo), `CHANGELOG_ANTIGRAVITY.md` (nuevo), `AGENTS.md` (regla §6)
**Qué cambió / qué se encontró:** Auditoría estática de seguridad, conexiones entre módulos y salud del código. Detalle completo, con IDs (S=seguridad, F=flujos, C=código), en `AUDITORIA_2026-09-18.md`. No se modificó código de la aplicación.
**Acciones manuales pendientes:** Revisar S1 (llaves en scripts versionados) y decidir rotación.
**Verificado:** `npm run build` OK (26 s, bundle 3.15 MB). Sin type-check disponible (C2).
