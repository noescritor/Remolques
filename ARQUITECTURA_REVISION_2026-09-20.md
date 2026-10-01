# Remolques — Revisión de arquitectura (modo Arquitecto) — 2026-09-20

> Método: The Architect (`the-architect/CLAUDE.md`, arquetipo *Internal Tool* + patrones de auth, base de datos, despliegue, pruebas, estado y API), aplicado a un sistema **ya construido**. No se escribió código.
> Base: `AUDITORIA_2026-09-18.md`, revisión del Bloque 1 (ver `CHANGELOG_ANTIGRAVITY.md`) y lectura de esquema, backend, Dockerfiles y `.env*`.
> Marcas: **[V]** verificado en archivos · **[I]** inferido, por confirmar · **[?]** pregunta abierta.
> Estado al escribir: Anty **aún no aplica** `PROMPT_ANTY_BLOQUE1_FIX.md` (HEAD sigue en `d5b5a05`, árbol sucio, `main` 5 commits adelante de `origin`).

---

## 1. Veredicto

**La dirección de producto es correcta; los cimientos de ingeniería no.**

Lo que decidieron bien es lo difícil: *la cotización firmada es la orden de compra del cliente*, todo cuelga de ella, el flujo aprobar → requisición → compra → recepción → producción es el flujo real de un fabricante, y ya hay multi-tenant, portal con firma, Kanban y trazabilidad.

Lo que falla es **cómo se está construyendo**: sin red de seguridad (tests, CI, type-check), sin una sola fuente de verdad para configuración y despliegue, y con decisiones de modelo de datos sin tomar que el Bloque 2 en adelante hereda. El Bloque 1 lo demostró: pasó `npm run build`, dejó 3 funciones sin definir, borró 6 rutas y registró 3 rutas sin autenticación, y nada lo detectó.

**Mi recomendación:** después del Fix del Bloque 1, **insertar un "Bloque 0: Cimientos"** (unos pocos días) *antes* de seguir con funciones. Cada bloque nuevo sin guardarraíles multiplica el costo de encontrar el siguiente error, y este sistema mueve dinero e inventario.

---

## 1.1 Decisiones cerradas (respuestas del dueño, 2026-09-20)

| # | Pregunta | Respuesta | Efecto en el plan |
|---|---|---|---|
| 1 | ¿Un cliente o varios? | **Un solo cliente** | Se **congela** la inversión multi-tenant: se conserva `organizacion_id` y RLS (ya existen y protegen), pero **no** se construye administración de organizaciones/módulos/invitaciones extra ni se diseña pensando en un segundo tenant. Simplifica pruebas y migraciones. Reabrir solo si aparece un segundo cliente. |
| 2 | ¿Cómo se define el material? | **Por modelo fijo** | El BOM por producto del Bloque 1 **es el modelo correcto**; la preocupación de "configuración por unidad" (§3.D) queda descartada. Se conserva solo lo que sigue siendo válido: congelar el BOM al crear la OT, reservas y recepción parcial. |
| 3 | ¿Base de producción y respaldos? | **Confirmado por el dueño:** producción = Supabase Cloud `djwl…` (compute Nano); **no hay ningún respaldo**; el servidor `ws2.cloud.betics.com.mx` fue una prueba fallida y se **da de baja** | **Tarea 0.1 del Bloque 0, urgente:** respaldo manual hoy → plan con respaldos → restauración de prueba. Rotar la `service_role` (fue expuesta en el chat). |

---

## 2. Qué se está haciendo bien

| Acierto | Por qué importa |
|---|---|
| Cotización = OC del cliente (no tabla nueva) | Una sola cadena de documentos, trazable de punta a punta |
| Portal con token, expiración y firma | Aprobación con evidencia, sin fricción |
| `organizacion_id` + RLS desde el inicio | Aislamiento por cliente ya pensado |
| Bitácora de eventos (`cotizacion_eventos`) | Base de auditoría; falta completarla |
| Migraciones versionadas en `supabase/migrations/` | Esquema reproducible (falta el registro de cuáles corrieron) |
| Tokens semánticos claro/oscuro (`AGENTS.md`) | UI coherente sin retrabajo |
| `AGENTS.md` + changelog + prompts por bloque | Buen proceso con agente; falta el "definition of done" (sección 6) |
| Decisiones con humano en el circuito (compras y OT con confirmación) | Correcto para un flujo que cuesta dinero |

---

## 3. Decisiones de arquitectura pendientes (lo que hay que tomar en cuenta)

Prioridad: 🔴 antes de seguir · 🟠 antes del Bloque 2 · 🟡 planificado.

### A. 🔴 No existe una fuente única de configuración: hay tres Supabase distintos [V]

| Dónde | Apunta a |
|---|---|
| `.env` (local, no versionado) | `http://ws2.cloud.betics.com.mx:8000` — **HTTP plano**, self-hosted |
| `.env.production` (versionado; lo usa `vite build` en Docker) | `https://djwlchgkeeeqfkreebgq.supabase.co` — un proyecto **Supabase Cloud** |
| `src/app/utils/supabase/client.ts` (hardcodeado) | `https://remolques-remolques-supa.gehkp3.easypanel.host` |
| `useSupabaseData.ts:6` (hardcodeado) | `https://remolques-remolques-api.gehkp3.easypanel.host` |

> **Corrección (2026-09-20, tras probar los servidores):** mi hipótesis inicial de que las categorías iban a una base distinta era **incorrecta**. `nginx-supa.conf:19` hace `proxy_pass https://djwlchgkeeeqfkreebgq.supabase.co`: el servicio `remolques-remolques-supa` de EasyPanel es solo un **proxy hacia el proyecto Cloud `djwl…`**, y el bundle desplegado (`index-DoCF-YfD.js`) contiene 13 referencias a `djwl…`, 1 al proxy y 1 a la API. Es decir, el frontend en producción habla con **una sola base: Supabase Cloud `djwl…`**. Lo que sigue siendo cierto es que la configuración está repartida en tres lugares y hay servidores sobrantes.

Estado de los servidores (probados con `GET` sin credenciales, todos responden):

| Servidor | Estado | Rol probable |
|---|---|---|
| `djwlchgkeeeqfkreebgq.supabase.co` | vivo | **Base de producción (Cloud)** — confirmado por el bundle desplegado |
| `remolques-remolques-supa.gehkp3.easypanel.host` | vivo | Nginx que reenvía a `djwl…` (existe para resolver CORS/mixed-content) |
| `remolques-remolques-api.gehkp3.easypanel.host` | vivo (`/health` OK) | API Hono (Deno) — **[?] a qué base apunta lo decide su variable `SUPABASE_URL` en EasyPanel** |
| `remolques-remolques-web.gehkp3.easypanel.host` | vivo | Frontend; el bundle desplegado es el de **antes** del Bloque 1 (mismo hash que el build local previo) |
| `ws2.cloud.betics.com.mx:8000` | vivo, **HTTP plano** | Supabase self-hosted; solo aparece en el `.env` local → hoy actúa como base de **desarrollo**. **[?]** ¿de quién es y qué tan alineada está con producción? |
| `kntbzloxbfrklzgjnvzi.supabase.co` | vivo | Proyecto Cloud **original del cotizador** (`cotizacion-app-admin`), sigue respondiendo |

Consecuencias: (1) el `.env` de dev apunta a otra base que producción, así que **lo probado en dev no prueba producción** salvo que esquema y datos coincidan; (2) hay servidores sobrantes (kntbz, posiblemente ws2) que agregan superficie y confusión; (3) el `.env` local usa HTTP plano, aceptable solo dentro de una red privada.
**Recomendación:** un módulo `config` que lea *solo* variables `VITE_*` (`API_URL`, `SUPABASE_URL`, `SUPABASE_ANON_KEY`), pasadas como `ARG` en el Dockerfile; cero URLs en código; HTTPS obligatorio en todo lo que salga a internet; y documentar en un solo lugar qué servidor es producción, cuál es desarrollo/staging y cuáles se dan de baja. Verificar que el `SUPABASE_URL` de la API apunte a `djwl…`.

### B. 🔴 Despliegue en dos mitades con contrato implícito [V]

Frontend (imagen Nginx) y backend (contenedor Deno) se despliegan **por separado y a mano** ("Rebuild"/"Implementar"). Esta misma semana el frontend llamaba endpoints que el backend desplegado no tenía, y se creó `bypass_backend.cjs` para rodearlo. Además `supabase/functions/make-server-feea4382/` **no es una Edge Function** (corre en Docker con `Deno.serve`); el nombre y la carpeta confunden, y hay **dos copias** del Dockerfile del frontend (`Dockerfile` y `deploy/easypanel/Dockerfile`, distintas).
**Recomendación:**
1. CI en GitHub Actions por PR: `npm run build` + `tsc --noEmit` + `deno check` + tests. Sin esto, el error del Bloque 1 se repite.
2. `GET /version` en el backend (commit SHA) y el frontend avisa si el backend es más viejo de lo que espera.
3. Auto-deploy por webhook de EasyPanel al hacer merge a `main`, para ambos servicios, en ese orden (backend primero, compatible hacia atrás).
4. Mover el backend a `api/` y partirlo en routers por dominio (`cotizaciones`, `compras`, `produccion`…): hoy es un archivo de 2,351 líneas donde un reemplazo grande borra módulos sin que nadie lo note.
5. Ramas por bloque y **PR revisado antes de `main`** (ver sección 6).

### C. 🔴 Autorización repartida en cuatro caminos [V]

1. API Hono con cliente **de servicio** (salta RLS) en portal, compras, órdenes.
2. API Hono con cliente **del usuario** (RLS aplica) en otras rutas.
3. **El navegador llama directo a PostgREST** (`/rest/v1/categorias_*`) con el token.
4. `/supa-proxy/*` abierto (sin uso).

Además **ninguna ruta valida rol**: cualquier miembro de la organización puede borrar cotizaciones, editar inventario o aprobar. `area_operativa` existe en BD y no se usa, y `App.tsx:604` lee el rol de `user_metadata` (editable por el propio usuario) [V].
**Recomendación (opinionada):** *un solo camino.* Todo lo de negocio pasa por la API; el navegador no toca PostgREST salvo Auth. La API usa el cliente del usuario por defecto (RLS como segunda barrera) y el de servicio **solo** donde no hay usuario (portal, jobs). Middleware `requireArea('compras' | 'almacen' | 'ventas' | 'gerencia')` leyendo `perfiles_organizacion` en servidor. Matriz de permisos por área definida *antes* de construirla. Eliminar `/supa-proxy`.

### D. 🟠 Material por modelo: BOM correcto, falta cerrar el circuito [V] — *ajustado tras la respuesta 2*

> **Actualización:** como el material es **por modelo fijo**, el BOM por producto del Bloque 1 es la estructura correcta. Lo que sigue en pie de este punto es más pequeño:
> 1. **Dos fuentes para lo mismo:** Presupuestos guarda el material de cada modelo en texto libre (`acero`, `piramide`, `piso`, `rines`… con piezas como `4.44`, sin unidad ni vínculo al catálogo) y el BOM guarda lo mismo estructurado. Recomendación: Presupuesto sigue siendo la **herramienta de costeo**, pero se **siembra el BOM una sola vez por modelo** desde él (mapeando cada línea a un material del catálogo) y de ahí en adelante el costo del modelo se calcula del BOM × costo vigente del material.
> 2. **Congelar el BOM al crear la OT** (copia automática, sin edición manual) para que un cambio posterior del BOM no altere órdenes ya en producción, y para poder comparar consumo real vs. BOM (costo real).
> 3. La requisición se calcula por cotización (`cantidad × BOM`), lo cual **es correcto** con modelos fijos; los accesorios sueltos tendrían su propio BOM o ninguno.
>
> El texto original de abajo se conserva como contexto de la decisión.

**(Texto original)** El material real de un remolque no vive donde el plan lo puso [V][I]

El Bloque 1 guarda la lista de materiales **por producto** (`producto_materiales`), con materiales del catálogo. Pero el costeo real de la empresa está en **Presupuestos**: secciones `acero / piramide / truckzone / piso / rines / …` con líneas de **texto libre** (`"PTR 4*4 PARA ESTRIBO"`, piezas `4.44`, sin unidad ni vínculo al catálogo). Un remolque además es *configurable* (`caracteristicas`/`configuracion` JSON): ejes, rines, medidas, piso.
Riesgos: (1) una lista fija por producto no refleja variantes; (2) la requisición se calcula a nivel **cotización**, pero el material se consume por **unidad fabricada** (OT); una cotización de 5 remolques distintos + accesorios mezcla ambos; (3) hay dos "verdades" de material (BOM vs. Presupuesto) que no se hablan.
**Recomendación:** BOM como **plantilla por modelo** + **snapshot por orden de trabajo** (`orden_materiales`: requerido / reservado / consumido, editable por ingeniería para la configuración de esa unidad). La requisición se calcula **sumando los snapshots de las OT**, no leyendo la cotización. Presupuesto pasa a ser la fuente que *propone* el snapshot (mapeando líneas al catálogo), no un documento aislado. El BOM simple del Bloque 1 sirve como v1 y no hay que tirarlo.
**[?]** Ver pregunta 2.

### E. 🟠 Inventario: stock mutable + bitácora, y sin reservas [V]

`productos.stock_actual` se modifica directo **y** existe `movimientos_inventario`: dos fuentes de verdad. `stock_reservado` existe pero **nadie lo escribe** (solo se muestra). Consecuencia: dos cotizaciones aprobadas "ven" el mismo stock disponible y ambas creen tener material.
**Recomendación:** bitácora (`movimientos`) como verdad y `stock_actual` como caché mantenida **solo** por la función atómica (`ajustar_stock`, ya en camino) o trigger; tabla de **reservas por OT** al aprobar/liberar; disponible = stock − reservas. Consumo de material ligado a `orden_trabajo_id` y fase (hoy la salida por producción solo guarda texto en `referencia`). Recepción **parcial** de compras (hoy `Recibida` es todo-o-nada: `compra_items` no tiene cantidad recibida) [V].

### F. 🟠 Tres máquinas de estado en paralelo [V]

`cotizaciones.estado` (Borrador…Pagada), `cotizaciones.estado_produccion` (texto libre, **sin CHECK**, con valores distintos entre tipo TS, migración 05 y Dashboard) y `ordenes_trabajo.estado` + `estado_kanban`.
**Recomendación:** definir cada máquina **una vez** (tabla de transiciones en un módulo compartido), agregar `CHECK` en BD, y que `estado_produccion` de la cotización sea **derivado**: una función `recalcularEstadoProduccion(cotizacion)` que mira compras y OT y se invoca tras cada evento. Así se evita esparcir `UPDATE estado_produccion` por cada ruta (que es justo el patrón que el Bloque 1 estaba construyendo).

### G. 🟠 Integridad y auditoría [V]

- `DELETE /cotizaciones/:id` borra **físicamente**; `ordenes_trabajo.cotizacion_id … ON DELETE CASCADE` y `cotizacion_eventos … ON DELETE CASCADE`: **borrar una cotización elimina sus órdenes de producción y su historial de auditoría**. Además cualquier miembro puede hacerlo (punto C).
  → Prohibir borrar si tiene OT, pagos o compras; usar `Cancelada`/`deleted_at`; la bitácora debe ser **append-only** (sin UPDATE/DELETE por RLS).
- **Totales calculados en el cliente**; no encontré recálculo en el servidor. Para un documento que el cliente firma, el servidor debe recalcular y rechazar diferencias.
- Pagos: sin validación de `monto ≤ saldo` en servidor; crédito (`limite_credito`) sin aplicar.
- Folios de compra por `MAX+1` (Anty): con dos usuarios simultáneos puede duplicar. Mejor secuencia por organización o `UNIQUE(organizacion_id, folio)` con reintento.

### H. 🟠 Esquema: mezcla de `TEXT` y `UUID` en los ids [V, conteo aproximado]

~10 tablas con `id TEXT` (las heredadas del cotizador) y ~18 con `uuid` (las nuevas). Es la causa directa del error `ajustar_stock(UUID)` de Anty y volverá a pasar con cada FK nueva.
**Recomendación:** documentar la convención en `AGENTS.md` con una tabla "tabla → tipo de id"; generar tipos desde la BD (`supabase gen types typescript`) en vez de mantener `types/index.ts` a mano (hoy puede divergir sin aviso); no migrar los ids legados (riesgo alto, beneficio bajo).

### I. 🔴 Operación de datos: migraciones a mano y sin evidencia de respaldos [V/?]

Las migraciones se corren manualmente sin registro; no vi respaldos (ni `pg_dump`, ni cron, ni documentación) ni ambiente de pruebas. Hay datos reales de producción, según el flujo descrito.
**Recomendación:** tabla `schema_migrations` (o `supabase db push`) para saber qué corrió en cada servidor; respaldo diario automático del Postgres con **prueba de restauración** documentada; un ambiente *staging* (segunda base pequeña) donde se prueba cada migración antes de producción. **[?]** ¿Existen respaldos hoy? Ver pregunta 3.

### J. 🟡 Cliente que carga todo y en cascada [V]

Al iniciar, ~18 peticiones secuenciales que traen **todas** las cotizaciones, productos, eventos, movimientos… sin paginación, con `.catch(() => [])` que oculta fallos. El Arquitecto lo marca como pitfall #2 de herramientas internas (*"Don't skip pagination"*) y el `CLAUDE.md` global fija **TanStack Query** como estándar. Bundle único de 3.15 MB.
**Recomendación:** migrar la capa de datos a TanStack Query por módulo (cache, reintentos, errores visibles, invalidación tras mutaciones), paginación en servidor para `cotizacion_eventos`, `movimientos_inventario` y cotizaciones, y `React.lazy` por ruta. Puede hacerse módulo por módulo, sin reescritura total.

### K. 🟠 Pruebas: cero en un sistema que mueve dinero e inventario [V]

El Arquitecto recomienda para herramientas internas *E2E de los flujos centrales* y para producción *unit + E2E de las rutas críticas*.
**Mínimo viable (proporcional):**
1. **Vitest** sobre funciones puras: totales/IVA, cálculo de requisición, transiciones de estado, folio. Requiere que esa lógica viva en funciones sin BD (hoy está dentro de las rutas).
2. **Un solo E2E (Playwright) del flujo dorado:** cotización → enviar → aprobar por portal → compra → recibir → OT → Kanban → Surtido, contra una base de pruebas. Este único test habría detectado todo el desastre del Bloque 1.
3. Tests SQL simples para `ajustar_stock` y para idempotencia de recepción.

### L. 🟡 Observabilidad [V]

Solo `console.log`. Recomendación: id de petición en logs, captura de errores (Sentry gratuito o una tabla `errores_app`), `/health` con verificación de BD, y una política explícita: **nunca** un `.catch` que devuelva `[]` sin avisar al usuario.

### M. 🟡 Multi-tenant vs. un solo cliente — **RESUELTO: un solo cliente** (ver §1.1)

Conservar lo que ya existe y protege (`organizacion_id`, RLS); **no** invertir en nada orientado a un segundo tenant. Texto original:

El plan original dijo "duplicar para este cliente"; el código mantiene `organizacion_id`, módulos por organización e invitaciones (SaaS). Ambas cosas a la vez cuestan: cada consulta debe filtrar por organización (riesgo constante con el cliente de servicio) y cada migración debe funcionar para tenants distintos. **[?]** Ver pregunta 1.

---

## 4. Huecos funcionales que el plan no menciona

| Tema | Por qué se debe decidir |
|---|---|
| **Anticipos / liberación a producción por pago** | En fabricación por pedido casi siempre se libera con anticipo. Hoy CxC registra pagos pero nada condiciona producción. Regla: "no generar OT sin X% cobrado o autorización de gerencia". Se conecta con el crédito (F4). |
| **Recepción parcial y devolución a proveedor** | Los materiales llegan en varias entregas; hoy es todo-o-nada. |
| **Costo real vs. presupuestado por OT** | Cierra el ciclo: material consumido + mano de obra vs. `Presupuesto`. Sin esto no saben si ganan en cada remolque. |
| **Facturación (CFDI) y entrega** | Existe `con_factura`, pero no hay timbrado ni evidencia de entrega (`LiberacionPDF`, NIV/placas). Definir si se integra un PAC o queda fuera. |
| **Tiempos y mano de obra por fase** | `historial_fases` existe; falta usarlo para retrasos y carga por línea. |
| **Piso de planta en tablet/móvil** | Kanban y recepción los usa gente de taller, no de oficina; requiere diseño táctil (ver skill `mobile-native`). |
| **Notificaciones y vencimientos** | Correo ya existe (Resend), pero no hay tarea programada: entregas por vencer, compras atrasadas, stock mínimo. |
| **Moneda** | Acero y componentes suelen cotizarse en USD; hoy solo MXN. Decidir si se necesita tipo de cambio. |

---

## 5. Ruta recomendada

| Orden | Bloque | Contenido | Por qué en este orden |
|---|---|---|---|
| 0 | **1-FIX** (en curso) | `PROMPT_ANTY_BLOQUE1_FIX.md` | No desplegar el Bloque 1 roto |
| 1 | **Bloque 0: Cimientos** | **0.1 Verificar y activar respaldos de `djwl…` (antes que todo lo demás)** · A (config única; dar de baja servidores sobrantes; API → `djwl…`) · B (CI + `deno check` + `tsc` + `/version`) · I (migraciones con registro + respaldos + staging) · G-mínimo (bloquear borrado de cotizaciones con OT/pagos/compras) · seguridad S1/S3/S5 · limpieza de 80 scripts y código muerto · Vitest base + el E2E dorado | Sin esto cada bloque siguiente es apostar |
| 2 | **Bloque 2: Material por OT** | D (sembrar BOM desde Presupuestos + congelar BOM al crear OT; sin edición manual por unidad) · E (reservas, consumo ligado a OT, recepción parcial) · F (`recalcularEstadoProduccion`) | Es el corazón operativo; depende de las decisiones 3.D–F. Más simple tras "por modelo fijo" |
| 3 | **Bloque 3: Permisos y dinero** | C (un solo camino + roles por área) · crédito y anticipos · totales recalculados en servidor | Requiere la matriz de permisos definida |
| 4 | **Bloque 4: Costo y planta** | Costo real por OT · tiempos por fase · vista móvil de planta | Aprovecha los datos que ya generan los bloques 2-3 |
| 5 | **Bloque 5: Escala y reportes** | TanStack Query · paginación · Dashboard extendido · notificaciones · decisión CFDI | Optimización una vez estable el dominio |

---

## 6. Proceso con Anty (cambios propuestos a `AGENTS.md`)

Lo ocurrido en el Bloque 1 fue de **proceso**, más que de capacidad. Propongo agregar una *Definition of Done* obligatoria:

1. Rama por bloque (`bloque-2-material`) — **nada directo a `main`**.
2. Antes de cada commit: `git diff --stat` revisado; **si hay borrados no solicitados, se detiene**.
3. Verificaciones: `npm run build`, `tsc --noEmit`, `deno check`, y **diff de rutas del backend** contra la base.
4. Toda función usada tiene definición (lo verifica `deno check`).
5. Entrada de changelog **por sub-bloque**, incluyendo "qué no se probó".
6. Revisión externa (Claude Code) del diff **antes de merge y de Rebuild**.
7. Prohibido reescribir archivos completos con scripts; edición puntual.
8. Los prompts de cada bloque se guardan en `docs/prompts/` y el estado del plan se actualiza **solo con hechos verificados** (el §7 de `PLAN_DUPLICAR_REMOLQUES.md` afirmaba cosas que no eran ciertas).

---

## 7. Estado de las decisiones y cómo verificar los respaldos

**Respondidas:** 1 (un solo cliente) y 2 (material por modelo fijo). **Pendiente:** 3, pero ya se acotó: producción es `djwl…`; falta confirmar respaldos y a qué base apunta la API.

### Verificación en 10 minutos (solo lectura, no cambia nada)

1. **Supabase Cloud → proyecto `djwlchgkeeeqfkreebgq` → Project Settings → Infrastructure/Billing:** ¿qué plan tiene (Free o Pro)? Un proyecto Free no incluye respaldos descargables y se **pausa por inactividad**; verifica la política vigente en tu panel.
2. **Database → Backups:** ¿aparece una lista de respaldos diarios? ¿Cuántos días de retención? ¿Hay PITR (restauración a un punto en el tiempo)? Anota la respuesta tal cual.
3. **Table Editor:** confirma que `cotizaciones`, `clientes` y `ordenes_trabajo` tienen los datos reales de la operación (así se confirma que `djwl…` **es** producción).
4. **EasyPanel → servicio `remolques-api` → Environment:** ¿cuánto vale `SUPABASE_URL`? (solo el host, no copies llaves). Debe ser `https://djwlchgkeeeqfkreebgq.supabase.co`. Si es otro, avísame: entonces la API y el login hablan con bases distintas.
5. **`ws2.cloud.betics.com.mx:8000`:** ¿de quién es ese servidor y para qué se usa? ¿Tiene datos que importen?

### Si no hay respaldos: acción inmediata (antes de cualquier función nueva)
- Hacer **una exportación manual hoy** (Supabase CLI `supabase db dump` o `pg_dump` con la cadena de conexión del panel, guardada en una variable de entorno local, nunca en un archivo del repo) y guardarla **fuera** del servidor.
- Después: respaldo diario automatizado (plan Pro con backups, o un job diario a almacenamiento externo) y **una restauración de prueba** documentada. Un respaldo que nunca se restauró no cuenta.

---

## 7.1 Preguntas originales (referencia)

1. **¿Remolques es un solo cliente (servidor propio) o piensas vender esto a más fabricantes?** Define si se mantiene multi-tenant (y su costo) o se simplifica. Recomiendo, si es un solo cliente por ahora: conservar `organizacion_id` (ya está) pero **no** invertir en administración de organizaciones/módulos hasta que exista el segundo cliente.
2. **¿Cómo se define hoy el material de un remolque?** ¿Por modelo fijo, o cada unidad lleva configuración distinta que Ventas/Ingeniería captura en el Presupuesto? ¿Quién lo captura y en qué momento (antes o después de aprobar)?
3. **¿Cuál es la base de producción real (la self-hosted en EasyPanel o el proyecto Cloud `djwl…`) y existen respaldos hoy?** Si no los hay, es lo primero que se resuelve, antes que cualquier función nueva.

Con las respuestas puedo generar el **blueprint de Remolques v2** (`the-architect/output/remolques-v2-blueprint.md`): decisiones cerradas, modelo de datos objetivo, orden de construcción numerado y `CLAUDE.md`/`AGENTS.md` actualizados para que Anty ejecute los bloques 0–5 con la Definition of Done de la sección 6.
