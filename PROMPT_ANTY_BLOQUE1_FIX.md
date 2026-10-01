# Bloque 1-FIX — Correcciones tras la revisión de Claude Code

Léelo completo. Se revisó `git diff 04f1e7e HEAD` (commits 1A–1E) contra el código real. `npm run build` pasa, pero **el build del frontend no compila el backend**, así que el backend tiene errores que solo aparecerían en producción.

## 0. Reglas para este fix

- **No hagas `git push` ni pidas Rebuild del backend** hasta terminar y pasar la sección 4. El backend actual, tal como está, rompería Presupuestos, el Kanban y la aprobación por portal.
- Registra en `CHANGELOG_ANTIGRAVITY.md` **una entrada por sub-bloque** (1A–1E ya cerraron sin ninguna; eso incumple AGENTS.md §6). Escribe primero una entrada retroactiva que resuma 1A–1E, honesta sobre lo que **no** quedó hecho.
- Nada de reescrituras masivas por script. El commit `d5b5a05` cambió 286 líneas de `index.ts` de golpe y con eso se perdió código. Ediciones puntuales, y antes de cada commit revisa `git diff --stat` y `git diff` completo: **si aparecen borrados que no pediste, detente**.
- Sigue todo lo demás de `AGENTS.md` y de `PROMPT_ANTY_BLOQUE1_APROBAR_REQUISICION_PRODUCCION.md`.

## 1. P0 — Bloqueantes (el backend no funciona sin esto)

### P0-1. Tres helpers se llaman pero **nunca se definieron** en ningún commit
`registrarEvento`, `aplicarAprobacion` y `calcularRequisicion` se usan en `index.ts` (líneas ~114, 314, 344, 378, 1804, 1862, 2153, 2258) y no existen. Efecto: `ReferenceError` en runtime. Peor: en portal *aprobar/rechazar* y en *crear compra*, el error ocurre **después** de guardar en BD, así que el cliente ve "Error" pero la cotización ya quedó Aprobada/Cancelada sin evento ni estado de producción.

Impleméntalos (declaraciones `async function` cerca de `getServiceClient`) según la sección 2 del prompt original:
- `registrarEvento(supabase, { cotizacion_id, organizacion_id, evento, usuario_id })` → INSERT en `cotizacion_eventos`; nunca debe tumbar la operación principal (captura y `console.error`).
- `calcularRequisicion(supabase, cotizacionId, orgId)` → `[{ material_id, nombre, unidad, requerido, stock_disponible, faltante, costo }]` con `requerido = Σ(item.cantidad × bom.cantidad)`, `stock_disponible = stock_actual - stock_reservado`.
- `aplicarAprobacion(supabase, cotizacionId, orgId, usuarioId)` → **lee la cotización de la BD** (no le pases un objeto armado a mano; hoy el portal manda `estado_produccion: "Nueva"`, que no es un estado canónico). Idempotente; pone `Requisición: falta material` o `Listo para producción` según `calcularRequisicion`; registra evento.

### P0-2. `d5b5a05` **borró** rutas que el frontend sigue usando
Rutas que existían en `04f1e7e` y hoy no existen: `GET/POST/PUT/DELETE /presupuestos`, `GET /produccion/lineas`, `GET /produccion/fases`. El frontend las llama (`useSupabaseData.ts:299-301, 1142-1172`) con `.catch(() => [])`, así que **el módulo Presupuestos y el Tablero Kanban quedarían vacíos sin ningún error visible**.
- Recupéralas desde `git show 0953ef3:supabase/functions/make-server-feea4382/index.ts` (copia exacta, añade cada una con edición puntual).
- Compara la lista completa de rutas contra la base: `04f1e7e` vs. tu versión. Las únicas diferencias permitidas son las rutas nuevas del bloque. Documenta el resultado en el changelog.

### P0-3. Rutas nuevas registradas **antes** del `authMiddleware`
`/productos/:id/materiales` (GET/PUT), `/cotizaciones/:id/historial` y `/cotizaciones/:id/requisicion` están en las líneas 26-118; el middleware se registra en la línea 478 (`app.use("/*", authMiddleware)`). En Hono el middleware solo cubre lo declarado **después**, así que en esas rutas `c.get("supabase")` y `c.get("organizacionId")` son `undefined` → siempre 500. Muévelas debajo del middleware, junto a las demás rutas protegidas.

### P0-4. El frontend usa una variable de entorno que no existe
`GenerarRequisicionModal.tsx:47` y `ProductosList.tsx:146` usan `import.meta.env.VITE_SUPABASE_API_URL`, que no está en `.env`, `.env.production` ni `.env.example` → la URL queda `undefined/...`. El BOM nunca se guarda (el `try/catch` solo hace `console.error`) y la requisición prellenada nunca carga. El resto del código usa `BASE_URL` en `useSupabaseData.ts:6`. Exporta `BASE_URL` (y el helper `getHeaders`/`fetchJson`) desde un módulo compartido (`src/app/utils/api.ts`) y úsalo en ambos componentes. **No** agregues una variable de entorno nueva. Muestra `toast.error` si el guardado del BOM falla.

### P0-5. La migración SQL tiene errores
Archivo actual: `20260918_01_flujo_aprobacion_produccion.sql` **en la raíz y sin trackear**. Muévelo a `supabase/migrations/` y corrige:
1. **Tipos:** `productos.id` es `TEXT` (`20260427_01_relational_schema.sql:33`; el BOM y `compra_items.material_id` también son `text`). `ajustar_stock(p_producto_id UUID, …)` compara `text = uuid` y falla; además el `ADD COLUMN material_id UUID REFERENCES productos(id)` es incompatible. Usa `TEXT`.
2. **`obtener_siguiente_produccion` ya existe** (`20260915_ordenes_trabajo_rpc.sql`) y usa `seq_produccion_global`. Tu migración la reemplaza por otra secuencia `seq_produccion_folio` que arranca en 100 → **folios duplicados** con las órdenes ya creadas. Elimina esa parte (no redefinir la función ni crear otra secuencia).
3. **Backfill:** agregas `producto_materiales.organizacion_id` sin llenarlo y la nueva política RLS es `organizacion_id = get_current_org_id()`; las filas existentes quedan invisibles. Añade `UPDATE producto_materiales pm SET organizacion_id = p.organizacion_id FROM productos p WHERE p.id = pm.producto_id AND pm.organizacion_id IS NULL;`.
4. Verifica cada tipo de columna contra las migraciones del repo antes de escribir el SQL (`grep` en `supabase/migrations/`). No asumas.
5. Sigue siendo idempotente. En el changelog indica el orden exacto de ejecución.
6. En el backend, **revisa `error` de `rpc('ajustar_stock')`** y de los inserts de `movimientos_inventario`/`compra_items` (hoy se ignoran → la compra queda "Recibida" con stock sin cambios, o sin ítems). Si falla, lanza error.

### P0-6. `/cotizaciones/:id/historial` usa una tabla inexistente
`.select("*, usuario:usuarios(email)")` — no hay tabla `usuarios` (hay `perfiles_organizacion` y `auth.users`). Además el frontend no llama esta ruta (0 referencias). O la conectas de verdad con un join válido, o la eliminas y dejas que Trazabilidad siga usando `/cotizacion-eventos`.

## 2. P1 — Lo que el Bloque 1 pedía y no se hizo

1. **Aprobar manualmente no dispara `aplicarAprobacion`.** En `PUT /cotizaciones/:id` se calculan `wasApproved` / `isNowApproved` (líneas 710-711) y **no se usan**. Llama al helper cuando `estado` pasa a `Aprobada` (y `!wasApproved`). Quita el evento duplicado de `App.tsx:manejarCambiarEstado` para ese cambio.
2. **Kanban → `Surtido`:** en `PUT /produccion/ordenes/:id/mover`, al llegar a la última fase marcar la orden `completada`; cuando todas las órdenes de la cotización estén `completada` → `estado_produccion = 'Surtido'` + evento. Registrar evento en `mover` y en `material`. (Hoy no hay nada de esto.)
3. **Flujo de `force` en el frontend:** el hook ya manda `force`, pero `CotizacionDetalle` no maneja el 409 (`requiresForce` + `faltantes`). Muestra los faltantes en un diálogo de confirmación y reintenta con `force: true`. Reemplaza los `alert()` de `handleGenerarOrdenes` por `toast`.
4. **1E incompleto:** falta el badge de `estado_produccion` en `CotizacionesList` / `CotizacionesTableModern` (solo se tocó Dashboard y 2 líneas de Detalle) y el indicador/stepper de estados en `CotizacionDetalle`.
5. **Crear compra:** el commit `d5b5a05` eliminó el manejo del error al insertar `compra_items` (antes al menos se logueaba, ahora `await` sin revisar) y devuelve la compra sin `items` ni `proveedor`, que el frontend esperaba. Revisa el error (si falla, borra la compra y responde 500) y devuelve la compra completa con `items` y `proveedor` como antes.
6. **Ocultar fallos:** los `.catch(() => [])` en `loadData` para `lineas`, `fases` y `presupuestos` fueron los que taparon lo de P0-2. Cámbialos por `toast.error` con el nombre del endpoint.

## 3. Correcciones a `PLAN_DUPLICAR_REMOLQUES.md` §7

Ese resumen contiene afirmaciones que no son ciertas o no son verificables. Corrígelo cuando termines:
- "Se agregó la tabla `producto_materiales`" y "se agregó la tabla `cotizacion_eventos`": ya existían desde `20260907_01` y `_06`; el bloque solo agregó columnas.
- "El endpoint `/requisicion` calcula correctamente los faltantes": la función que lo calcula no existía.
- "Aprobación y Portal … caducidad de IP y estado": la redacción no describe lo que se hizo (expiración, estado `Enviada` requerido, IP desde `x-forwarded-for`).
- "Generación de órdenes … secuencias SQL verdaderas": la migración crea una secuencia nueva que colisiona (P0-5.2).
- "Infraestructura … sólida": no lo es hasta que este fix termine. Actualiza el §7 con el estado real, incluyendo lo pendiente.

## 4. Verificación antes de cerrar (obligatoria)

1. **Chequeo estático del backend:** `deno check supabase/functions/make-server-feea4382/index.ts` (si no tienes Deno, instálalo; el build de Vite **no** revisa esto). Debe salir sin `Cannot find name`. Si no puedes correrlo, al menos: cada nombre de `registrarEvento|aplicarAprobacion|calcularRequisicion` tiene exactamente una definición, y todas las rutas nuevas están **después** de la línea `app.use("/*", authMiddleware)`.
2. **Diff de rutas:** compara rutas de `04f1e7e` vs. HEAD y pega el resultado en el changelog (solo deben aparecer las nuevas).
3. `npm run build` en verde.
4. Escenario de prueba de la sección 6 del prompt original, con lo que puedas ejecutar. Marca claramente **qué se probó y qué no** (sin acceso al servidor, di "no probado").
5. Entrada final en el changelog con: SQL a correr (orden), si hace falta Rebuild, y lista de lo que sigue pendiente. Después avísame y **yo** autorizo el push.
