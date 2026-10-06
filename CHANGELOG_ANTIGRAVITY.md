# Changelog de cambios y hallazgos — Remolques

Bitácora obligatoria para cualquier cambio hecho con Antigravity o Claude Code.
Formato: entradas nuevas **arriba**. Una entrada por sesión/cambio.

## 2026-10-06 - Bloque 2R-0: Contención de recetas planas y preparar diagnóstico
**Herramienta:** Antigravity

**Qué cambió:**
1. `ModeloConfiguratorModal.tsx`: Se deshabilitó la carga ciega de `producto_materiales` a `sub_items`.
2. `CotizacionEditor.tsx`: Se verificó que los sub-items no se intenten heredar de las recetas planas de `producto_materiales`.
3. `supabase/functions/make-server-feea4382/index.ts`: Se reescribió `calcularRequisicion` para que lea de `items_cotizacion` y no de `cotizaciones.items` (inexistente), y para que detecte si un ítem terminado no tiene configuración resuelta devolviendo un estado `sin_receta` en lugar de un arreglo vacío por fallback.
4. `docs/remediacion/01_diagnostico_recetas.sql`: Script creado para que el dueño diagnostique el estado de las recetas.
5. `docs/remediacion/02_correccion_recetas_PENDIENTE.sql`: Placeholder creado.

**Por qué:**
La migración `20261005_01_recetas_nuevas.sql` creó una receta plana incorrecta (sumando todas las opciones como si fueran materiales obligatorios) y el CPQ anterior inyectaba esta receta asumiendo que era estática. Esto detenía la venta real de remolques configurables. El backend además estaba intentando leer `cotizaciones.items`, lo cual siempre daba vacío.

**Archivos tocados:**
- `src/app/components/Presupuestos/ModeloConfiguratorModal.tsx`
- `supabase/functions/make-server-feea4382/index.ts`
- `docs/remediacion/01_diagnostico_recetas.sql` (creado)
- `docs/remediacion/02_correccion_recetas_PENDIENTE.sql` (creado)

**SQL a correr:**
El dueño debe correr manualmente `docs/remediacion/01_diagnostico_recetas.sql` en el editor de Supabase y regresar el resultado.

**Pruebas manuales pendientes (Rebuild / SQL):**
* [ ] (El dueño) Correr `01_diagnostico_recetas.sql` y devolver los resultados.
* [ ] Pendiente de correr el archivo `02_correccion_recetas_PENDIENTE.sql` una vez definido y con RESPALDO PREVIO DE LA BD.
* [ ] No se probó la compilación de Edge Functions porque se requiere un Rebuild de EasyPanel (Deno check se probó estáticamente).


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

## 2026-10-06 (2) — Decisiones del dueño, catálogo unificado, remediación y prompt del Bloque 2R
**Herramienta:** Claude Code
**Tipo:** decisión / hallazgo
**Archivos tocados (todos nuevos, sin cambios de código):** `PROMPT_ANTY_BLOQUE2R_CONFIGURADOR_Y_RECETA.md`, `docs/catalogo-opciones/catalogo_opciones_unificado.json`, `docs/remediacion/01_diagnostico_recetas.sql` (solo lectura), `docs/remediacion/02_correccion_recetas_PENDIENTE.sql` (**no correr**); edición de `ANALISIS_MANUAL_Y_COTIZADOR_2026-10-06.md` (§4.1 corrección y §6.4 decisiones).
**Decisiones del dueño:** el SQL de recetas **ya se corrió en producción**; precio de venta = sugerencia (costo + margen configurable por tipo) con ajuste manual; cantidades del manual "por unidad" (pendiente validar con tabla de verificación); se soportan góndola, jaula y caja seca (solo la góndola tiene datos); catálogo de opciones = unión sin repetir de cotizador y manual.
**Hallazgos nuevos:**
- 🔴 **`calcularRequisicion` nunca calcula:** `select('*')` de `cotizaciones` y lee `cot.items`, que no existe en esa tabla (los conceptos están en `items_cotizacion`). Devuelve `[]` siempre ⇒ "no faltan materiales" para toda cotización. Corrige mi afirmación previa de que "pediría 56 rines".
- 🟠 `sub_items` **no se persiste** (ausente de `toItemCotizacionRow`/`metadata`): vive solo en el editor y la impresión.
- 🟠 La migración usó `(SELECT id FROM organizaciones LIMIT 1)` (puede ser la organización equivocada; hay una de administración) y `ON CONFLICT (nombre, organizacion_id)` sin restricción visible en las migraciones: el diagnóstico lo comprueba.
- 🟠 `ModeloConfiguratorModal` consulta Supabase **directo desde el navegador** y usa `localStorage('pending_cpq')`; margen fijo de 30 % (el Excel usa montos fijos). Con costos 0, el precio sugerido sale 0.
- El CSV de costeo trae un **despiece completo de la góndola con precios** (chasis, tina, equipamiento); solo se cargaron 8 líneas.
- Catálogo unificado: 20 grupos, 126 opciones, **19 conflictos de precio** entre listas (p. ej. Hendrickson alta 43,700 vs 46,783.62; gancho Bestia 21,892.68 vs 28,040.98), **27 opciones sin precio**.
- Faltan recetas de **jaula, caja seca, multimodal, cama baja, porta contenedor**; la traila solo tiene material, sin opciones.
**Acciones manuales pendientes (dueño), en este orden:** (1) **respaldo** de la base (producción no tenía respaldos automáticos al 20-sep); (2) correr `01_diagnostico_recetas.sql` y pasar el resultado; (3) solo después, decidir `02_correccion_recetas_PENDIENTE.sql`; (4) pasar el prompt `PROMPT_ANTY_BLOQUE2R…` a Antigravity; (5) capturar recetas de jaula y caja seca; (6) precios de materiales.
**Verificado:** lectura del SQL de recetas, `parsed_bom.json`, backend (`calcularRequisicion`, `toItemCotizacionRow`), `ModeloConfiguratorModal`; catálogo generado por script reproducible. No se ejecutó ningún SQL.
**Ref. auditoría:** F3, F15; ARQUITECTURA §3.D, §3.E

## 2026-10-06 — Análisis del MANUAL y del cotizador Excel; revisión del Bloque 2 de Antigravity
**Herramienta:** Claude Code
**Tipo:** hallazgo / decisión de diseño
**Archivos tocados:** `ANALISIS_MANUAL_Y_COTIZADOR_2026-10-06.md` (nuevo), `docs/manual-recetas/lineas_parseadas.json` (nuevo). Sin cambios de código.
**Qué se encontró:**
- 🔴 **Receta plana con todas las opciones sumadas.** `artifacts/parsed_bom.json` y `20261005_01_recetas_nuevas.sql` convierten el manual (que lista todas las opciones juntas) en una receta plana: la Plana 40 ft pediría **10 piernas y 10 platos de suspensión, 10 ejes, 56 rines y 32 llantas** (debería ser 2/2/2/8/8), 3 marcas de pintura sumadas, 3 ganchos y 2 sistemas retráctiles. El CPQ del 1-oct carga esa receta en `sub_items` y `calcularRequisicion` los toma de ahí.
- 🔴 **Cantidades perdidas en silencio:** 34 materiales repetidos en la Plana (p. ej. `CONSUMIBLE 65` 0.5+0.25+0.25) y `ON CONFLICT DO NOTHING` sobre `UNIQUE(producto_id, material_id)` conserva solo la primera.
- 🟠 Todos los materiales con costo 0 (el manual no trae precios); solo 4 recetas cargadas (faltan 8 variantes de plataforma).
- ⚠ `20261005_01_recetas_nuevas.sql` está sin versionar en la raíz: **no se sabe si se corrió en Supabase**. No correrlo tal cual.
- ⚠ Proceso: 13 commits del Bloque 2 (1–2 oct) con **una sola entrada de changelog**; los commits `fix: CORS and 404 endpoints` y siguientes no están documentados.
- **Corrige la conclusión del 20-sep** ("material por modelo fijo ⇒ BOM plano basta"): los modelos son fijos **con ~10 grupos de opciones elegibles, reglas condicionales y variantes por largo (35–48 ft) y ejes (2/3)**. Diseño propuesto: configurador → cotización **resumen** → aprobar → **presupuesto completo** (acero + tornillería + luz + aire + pintura + MO) → BOM congelado por unidad → OT/requisición/Kanban por paso.
- Los pasos de las recetas (1–6, limpieza, pintura, aire, luz, terminado) son las **fases reales** del Kanban.
- Excel: precio de venta tecleado (cálculo = costo + $110,000 plana / + $40,000 dolly, fijos); indirectos 2.5 % de un número pegado; dos listas de precios inconsistentes; 3 macros hacia hojas inexistentes; rutas fijas a una sola máquina; 6 plantillas de cotización; pagos **por chasis** sin comprobante (64 pagos, 0 con folio); 199 unidades de 63 clientes (83 sin producto).
**Por qué:** El dueño pidió cotizar con todas las variantes y generar el presupuesto completo al aprobar; al contrastar con lo construido apareció el defecto de las recetas.
**Acciones manuales pendientes (dueño):** (0) confirmar si el SQL de recetas se corrió; (1) responder las 5 preguntas de la sección 7 del documento.
**Verificado:** Lectura de 41 hojas y de las macros VBA (extraídas y descomprimidas); conteos por script sobre `parsed_bom.json`. No se ejecutó ningún SQL ni el libro. Datos bancarios/RFC del libro no se copiaron.
**Ref. auditoría:** F3, F9, F15; ARQUITECTURA §3.D (reemplaza su ajuste del 20-sep)

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
