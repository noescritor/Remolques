# Auditoría del sistema Remolques — 2026-09-18

**Alcance:** revisión estática de `src/`, `supabase/functions/make-server-feea4382/index.ts`, `supabase/migrations/`, archivos de raíz, planes y docs.
**No se modificó código.** Solo se ejecutó `npm run build` (pasa en ~26 s; `dist/` está en `.gitignore`).
**Limitaciones:** no se probó la app en vivo, no se conectó a Supabase y no se decodificaron llaves. Lo marcado **[verificar]** es sospecha sin confirmar.

Leyenda: 🔴 crítico · 🟠 alto · 🟡 medio · ⚪ bajo

---

## 1. Seguridad

| # | Sev | Hallazgo | Evidencia | Acción sugerida |
|---|-----|----------|-----------|-----------------|
| S1 | 🔴 | **Llaves de Supabase en archivos versionados.** `test_perfiles.cjs` declara una variable llamada `SUPABASE_SERVICE_ROLE_KEY` con un JWT literal; `test_movimiento.cjs` (`supabaseKey`), `check_supa.cjs` y `check_supa_real.cjs` también traen JWTs literales. El repo está en GitHub (`noescritor/Remolques`, privado) y los archivos están en el historial (commits `a8adf55`, `d4cbb52`). | `git grep "eyJ"` | Confirmar el rol de cada llave (payload del JWT). Si alguna es `service_role`: **rotarla en Supabase**, borrar los scripts y limpiar historial (`git filter-repo`). Los scripts deben leer de `process.env`. |
| S2 | 🟠 | `src/app/utils/supabase/client.ts` tiene URL y anon key **hardcodeadas** en vez de `import.meta.env`. La anon key es pública por diseño, pero así el `.env` se ignora y cambiar de servidor exige editar código. | `client.ts:6` | Leer de `import.meta.env.VITE_*`. |
| S3 | 🟠 | **Portal público filtra datos internos.** `GET /portal/:token` devuelve `productos` completos de la organización (`select("*")`, incluye `costo`, stock) y `cliente:clientes(*)` completo (incluye `limite_credito`). Cualquiera con el link ve el costo de todo el catálogo. | `index.ts:162-190` | Devolver solo los campos que usa `PDFTemplateMoodboard` (nombre, descripción, imagen, unidad). |
| S4 | 🟠 | **Portal: transiciones sin validar.** `rechazar` y `solicitar-cambios` no revisan expiración del token (`aprobar` sí). Ningún endpoint valida el estado actual: un link viejo puede pasar una cotización *Pagada/Aprobada* a *Cancelada*, o aprobar una *Cancelada*. `firma_ip` la manda el cliente (falsificable). Sin rate-limit. Aprobar/rechazar no deja evento de trazabilidad. | `index.ts:192-253` | Validar expiración y estado permitido en los 3 endpoints; sacar la IP de `x-forwarded-for`; registrar evento. |
| S5 | 🟠 | **`/supa-proxy/*` es un proxy abierto** a Supabase, sin auth propia y con `CORS *`, declarado *antes* del `authMiddleware`. El frontend **no lo usa** (0 referencias en `src/`). | `index.ts:37-66` | Si ya no se usa (existe `Dockerfile.supa-proxy` / `nginx-supa.conf`), eliminarlo del backend. |
| S6 | 🟡 | `getServiceClient()` cae silenciosamente a la **anon key** si falta la service key; el backend usa service client (salta RLS) en portal, compras, órdenes. El aislamiento por organización depende de recordar `.eq("organizacion_id", …)` en cada consulta. No se auditó cada ruta. | `index.ts:~70` | Fallar fuerte si falta la variable; revisar ruta por ruta que filtre por org. |
| S7 | 🟡 | `App.tsx:604` pasa `rolActual={session.user.user_metadata.rol}` a Compras. `user_metadata` **lo puede editar el propio usuario** en Supabase Auth; si se usa para permisos, es evadible. | `App.tsx:604` | Leer el rol de `perfiles_organizacion` (server-side), no de `user_metadata`. **[verificar]** si el backend también lo usa. |
| S8 | ⚪ | Token del portal: `crypto.randomUUID()` (suficiente) con expiración. Sin revocación explícita. | `index.ts:~273` | Opcional: endpoint para revocar. |

---

## 2. Módulos y flujos que NO están conectados

Mapa actual de lo que sí funciona: Cotización → Portal/firma → **(manual)** Requisición → Compra proveedor → **Recibida → entrada de inventario** ✔ → CxP (pagos proveedor) ✔. Cotización → **(manual)** Órdenes de trabajo → Kanban ✔. Cotización → Pagos → CxC ✔.

| # | Sev | Desconexión | Detalle |
|---|-----|-------------|---------|
| F1 | 🟠 | **Aprobar no dispara nada.** Ni por el portal ni manual se crea requisición, orden de trabajo, evento ni cambia `estado_produccion`. Todo depende de botones manuales en `CotizacionDetalle`. | El plan (§2.2) pedía requisición automática al aprobar. |
| F2 | 🟠 | **`estado_produccion` está huérfano.** La migración 05 define 6 estados (`Pendiente de aprobar … Surtido`), pero **ningún flujo los escribe**; solo `DashboardMain` los lee. Además el Dashboard filtra `!== 'Entregado'`, valor que **no existe** en la lista → toda cotización con `fecha_entrega` cuenta como "entrega pendiente" para siempre. No hay badge en la lista de cotizaciones (plan §3). | `DashboardMain.tsx:154`, migración 05 |
| F3 | 🟠 | **BOM / requisición inteligente no existe.** `producto_materiales`, `proveedor_materiales` y `tipo_item` están en migraciones/tipos pero **sin API ni UI**. `calcularRequisicion()` nunca se escribió. `GenerarRequisicionModal` muestra **todos** los productos como si fueran materia prima (filtro con `\|\| true` en línea 32) y no compara contra stock. | plan §2.1-2.2 sin implementar |
| F4 | 🟠 | **Crédito de cliente no se aplica.** `limite_credito` solo se captura en `ClienteModal`. No hay barra de saldo usado, ni validación al aprobar/crear cotización, ni alerta en Dashboard. | grep: 3 archivos, ninguno lo evalúa |
| F5 | 🟠 | **`POST /produccion/import` es un stub**: devuelve `{success:true, message:"Import completed"}` sin hacer nada. El hook `importarExcelKanban` existe pero **ningún componente lo llama**. El "ETL" del commit `f43f171` no está en el backend. | `index.ts:2222` |
| F6 | 🟡 | **Trazabilidad incompleta.** Solo se registran eventos desde el frontend en 4 puntos (crear/actualizar cotización, cambiar estado, pago). **Sin evento:** aprobación/rechazo del portal, requisición/compra, recepción, movimientos de inventario, generar OT, mover Kanban, pagos a proveedor. Además el evento es una 2ª petición del cliente: si falla tras la mutación, la UI muestra error aunque el cambio sí se guardó. | `App.tsx:207-369` |
| F7 | 🟡 | **Dos módulos de producción sobre los mismos datos:** `/produccion` (`OrdenesTrabajoList`) y `/tablero-produccion` (Kanban), ambos leen `ordenes_trabajo`. Los campos Kanban (`linea_producto_id`, `fase_actual_id`, `estado_kanban`) **[verificar]** si `generar-ordenes` los inicializa. | sidebar + `App.tsx:636-657` |
| F8 | 🟡 | **Salida de inventario "por producción"** (`GenerarOrdenProduccionModal`) solo inserta movimientos con referencia en texto: no se liga a la `orden_trabajo`, no valida stock (puede quedar negativo **[verificar]**). | `CotizacionDetalle.tsx:98` |
| F9 | 🟡 | **Presupuestos, Calculadora, CalculadoraMaterial y Notas son islas.** Presupuestos solo se enlaza a `cliente_id` (no a cotización/OT/productos). `NotaSimple` guarda `cliente_nombre` como texto (sin `cliente_id` ni `cotizacion_id`). | `types/index.ts:336, 420` |
| F10 | 🟡 | **Devoluciones:** solo son 3 opciones en el `<select>` del formulario de movimiento; no hay pestaña dedicada (plan §3) ni vínculo a compra/cotización de origen. | `InventarioList.tsx:220` |
| F11 | 🟡 | **`area_operativa` (Ventas/Compras/Almacén/Gerencia)** existe en migración 08 y tipos, pero **sin UI ni permisos**. Cualquier miembro ve y hace todo. | plan §2.9 |
| F12 | 🟡 | **Módulos por organización no se respetan:** `organizacion_modulos` solo oculta 6 ítems del menú (cotizaciones, clientes, productos, calculadora, inventario, notas). Proveedores, Compras, CxC, CxP, Presupuestos, Trazabilidad, Tablero, Producción y Equipo no son configurables. Y **ninguna ruta está protegida**: `App.tsx` no consulta `modulos`, se entra escribiendo la URL. | `ModernLayout.tsx:72-89`, `App.tsx` |
| F13 | 🟡 | **Dashboard vs plan §3:** solo se encontraron "próximas entregas". No vi crédito abierto, próximos cobros ni alertas de stock mínimo. | `DashboardMain.tsx` |
| F14 | 🟡 | **Recepción de compra no es idempotente:** `PUT /compras-proveedor/:id` con `estado:'Recibida'` suma stock **cada vez que se llama**, sin verificar el estado previo (doble clic / reintento = stock duplicado). Además el stock se actualiza con lectura-luego-escritura (condición de carrera). | `index.ts:1655-1695` |
| F15 | 🟡 | **`generar-ordenes` usa heurísticas frágiles:** omite cualquier item con `precio_unitario < 10000`, deduce el tipo de equipo por palabras en la descripción, y si falla la RPC `obtener_siguiente_produccion` usa un **número aleatorio** como consecutivo (posibles folios duplicados). | `index.ts:1975-2000` |
| F16 | ⚪ | Folio de compras `OC-${Date.now().slice(-6)}` en el cliente: puede colisionar; debería salir de una secuencia en BD. | `CotizacionDetalle.tsx:78` |

---

## 3. Salud del código

| # | Sev | Hallazgo | Detalle |
|---|-----|----------|---------|
| C1 | 🟠 | **80 scripts sueltos en la raíz** (`fix_*.cjs`, `append_*.cjs`, `*.py`, `*.sql`). Son parches one-off de Antigravity; ya causaron incidentes (AGENTS.md §3). Varios tienen llaves (S1). | Mover a `scripts/archive/` o borrar; los `.sql` útiles pasan a `supabase/migrations/`. |
| C2 | 🟠 | **Sin type-check, lint ni tests.** `typescript` no está en `devDependencies` (`npx tsc` falla). `vite build` no valida tipos, así que "compila" no implica "tipado correcto". `test_calculations.js` es un script suelto, no un test runner. El paquete se llama `@figma/my-make-file`. | Agregar `typescript`, `"typecheck": "tsc --noEmit"`, y Vitest para `utils/calculations.ts`. |
| C3 | 🟡 | **Código muerto (~5–6 k líneas):** `components/Layout.tsx` (reemplazado por `ModernLayout`), `hooks/useAppData.ts`, `src/app/imports/*` (export de Figma: `CotizadorSemiautomatico`, `Page`, `Frame4`, `Group*`, svgs), `src/app/supabase/functions/server/` (copia legacy del backend con solo 8 módulos), variantes de PDF sin usar (`PDFTemplate`, `PDFTemplateCompact`, `PDFTemplateModern`, `PDFFullPage`, `PDFFullPageCompact`, `PDFFullPageModern`, `PDFPreview`) — la app solo usa `*Moodboard`. Hay `__pycache__/` **trackeado**. | Verificar y eliminar. |
| C4 | 🟡 | **Monolitos:** `index.ts` (backend, +2 200 líneas, un solo archivo), `useSupabaseData.ts` (1 337), `NotasManager.tsx` (1 368), `CotizacionEditor.tsx` (1 255). | Dividir por módulo (el CLAUDE.md global define `modules/<nombre>/{api,hooks,types,components}`). |
| C5 | 🟡 | **Carga inicial en cascada:** ~18 `await` secuenciales en `loadData`; casi todos con `.catch(() => [])`, que **oculta fallos** (justo el síntoma del backend sin "Rebuild" documentado en AGENTS.md). Además dos llamadas directas a `/rest/v1/categorias_*` fuera del backend. | Paralelizar con `Promise.allSettled` y mostrar qué endpoint falló. TanStack Query resolvería esto y cache. |
| C6 | 🟡 | **Bundle único de 3.15 MB (957 kB gzip).** Sin code-splitting; `xlsx`, `@react-pdf/renderer`, `recharts` se cargan en el login. | `React.lazy` por ruta + `manualChunks`. |
| C7 | 🟡 | **Backend con parches defensivos de esquema:** `optionalCotizacionColumns` reintenta quitando columnas que "no existen" comparando texto del error, y hay rutas "legacy". Esto enmascara drift de esquema. Bug concreto: en `insertItemsCotizacion` el reintento legacy llama `toLegacyItemCotizacionRow(item, cotizacionId)` **sin `orgId`** → items sin `organizacion_id`. | `index.ts:~120-135` |
| C8 | 🟡 | **Migraciones:** dos convenciones de nombre (`YYYYMMDD_NN_` y `YYYYMMDDHHMMSS_`); `full_schema.sql`, `schema_nuevo_servidor.sql` y `seed_*.sql` viven fuera de `migrations/`; se aplican a mano sin registro de cuáles corrieron (AGENTS.md §2). Riesgo de drift entre servidores. | Un `MIGRACIONES_APLICADAS.md` por servidor, o usar `run_migrations.cjs` con tabla de control. |
| C9 | 🟡 | **Design system:** AGENTS.md prohíbe colores fijos, pero hay muchas coincidencias de `text-white`, `bg-*-slate/gray`, `orange-*` y hex (los más altos: `NotasManager` 73, `PortalCliente` 33, `CotizacionEditor` 21, `DashboardMain` 17, `EquipoManager` 14). Algunos son legítimos (texto sobre accent). `CotizacionDetalle` usa `orange-500` (fuera de paleta Moodboard). 15 `alert()` nativos cuando ya hay `sonner`. | Barrido con tokens semánticos. |
| C10 | ⚪ | **Sidebar:** íconos repetidos (`Users` ×3, `Package` ×3, `DollarSign` ×2), "Producción" al final del menú y "Tablero Producción" arriba; sin agrupación por área. | Agrupar: Ventas / Producción / Almacén / Finanzas / Admin. |
| C11 | ⚪ | **Deploy duplicado/confuso:** `Dockerfile` vs `deploy/easypanel/Dockerfile`; `nginx.conf` vs `nginx-supa.conf` vs `deploy/easypanel/nginx.conf`; `Dockerfile.backend`, `Dockerfile.supa-proxy`. | Documentar cuál usa cada servicio de EasyPanel. |

---

## 4. Documentación desactualizada

- `HANDOFF_ESTADO.md` (abril): habla de `cotizacion-app-admin`, otro dominio de EasyPanel y otro `project ref`. No refleja el servidor Supabase self-hosted ni los módulos nuevos.
- `task.md`: todo `[ ]`, aunque Notas ya está construido. `implementation_plan.md`: requisición ya implementada. `README.md`: de abril.
- `PLAN_DUPLICAR_REMOLQUES.md`: sirve como checklist; ver §5 para el estado real.
- `AGENTS.md` es lo único vigente y útil (se le agregó la regla del changelog).

---

## 5. Estado del plan `PLAN_DUPLICAR_REMOLQUES.md`

| Ítem del plan | Estado |
|---|---|
| Migraciones 01-07 (+08,09,10) | ✅ existen (aplicadas manualmente: **[verificar]** en el servidor nuevo) |
| Proveedores (UI+API) | ✅ |
| Compras a proveedor + recepción → inventario | ✅ (con F14) |
| Pagos a proveedor / CxP | ✅ |
| Trazabilidad (pantalla) | ✅ lectura · ⚠️ escritura parcial (F6) |
| Órdenes de trabajo / Kanban / PDFs | ✅ extra al plan (con F5, F7, F15) |
| CxC | ✅ |
| BOM + requisición automática (§2.1-2.2) | ❌ (F3) |
| Estados de producción ampliados (§2.6) | ⚠️ solo esquema (F2) |
| Crédito de cliente (§2.5) | ⚠️ solo captura (F4) |
| Devoluciones (§2.8) | ⚠️ solo opciones del select (F10) |
| Roles operativos (§2.9) | ❌ solo esquema (F11) |
| Dashboard extendido (§3) | ⚠️ parcial (F13) |
| Badge `estado_produccion` en lista de cotizaciones | ❌ |
| Badge/barra de crédito y cotizaciones en `ClienteModal` | ⚠️ solo el campo |

---

## 6. Prioridad recomendada

**Hoy (riesgo):** S1 (revisar/rotar llaves), S3 (portal filtra costos), S4, S5, F14 (stock duplicado).
**Siguiente (valor de negocio):** F1 → F2 → F3 (aprobar → estado → requisición con BOM), F4 (crédito), F6 (trazabilidad completa).
**Orden interno:** C1/C3 (limpieza), C2 (typecheck), C5/C4 (hook y backend), C9/C10 (UI).

> Nota de proceso: al terminar cada bloque, registrar en `CHANGELOG_ANTIGRAVITY.md` (ver AGENTS.md).
