# Reporte de Implementación — Arreglo: Recepción de compras atómica (`ajustar_stock` rota)

- **Fecha:** 2026-11-25
- **Rama:** `compras-recepcion-2026-11-24` (worktree independiente desde `main` `87be541`)
- **Revisa:** Claude (sin merge ni push a `main`)
- **Prompt de referencia:** `PROMPT_ANTY_COMPRAS_RECEPCION_2026-11-24.md`

---

## 0. Auditoría previa (§0) y evidencia "antes vs después"

1. **Otros llamadores de `ajustar_stock` en BD local (`remolques`):**
   - `pg_proc`: solo existe `public.ajustar_stock(p_producto_id uuid, p_delta numeric)`; **0** funciones la llaman.
   - `pg_views`: **0** vistas la referencian.
   - `pg_trigger`: **0** triggers la referencian.
   - En código TypeScript: el único llamador era `PUT /compras-proveedor/:id` (`index.ts` L3443).
2. **Prueba "antes" (sobre `main`, documentada también en §0 de G):**
   - `PUT /compras-proveedor/:id` con `{ "estado": "Recibida" }` devolvía **`200 OK`**, `compras_proveedor` pasaba a `Recibida`, `movimientos_inventario` insertaba `Entrada | 5 | Compra OC-...`, pero `rpc('ajustar_stock', ...)` fallaba con `operator does not exist: text = uuid` sin revisarse y `productos.stock_actual` quedaba en `10` sin posibilidad de reintento.
3. **Prueba "después" (`scripts/dev/repro_recepcion_compra.cjs` contra API local + PG 17 real):**
   - `PUT /compras-proveedor/22222222-2222-4222-8222-222222222301` (`OC-CR-REPRO`, +5 de `prod-cr-e2e-1`): devuelve `200`, compra queda `Recibida`, 1 movimiento `Entrada | 5 | Compra OC-CR-REPRO`, y `stock_actual` sube de **`10` a `15`**.
   - Segunda llamada `PUT` idéntica: devuelve `200`, `ya_recibida: true`, `stock_actual` sigue en **`15`** (0 duplicación).

---

## 1. Qué se construyó

### 1.1 Migración (`supabase/migrations/20261125_02_compras_recepcion.sql`)
- `DROP FUNCTION IF EXISTS public.ajustar_stock(uuid, numeric);` (y encabezado `OBSOLETO` agregado en `20260918_01_flujo_aprobacion_produccion.sql` sin borrar el archivo).
- Nueva RPC atómica `public.recibir_compra_proveedor(p_org UUID, p_usuario UUID, p_compra_id UUID) RETURNS JSONB`, `SECURITY DEFINER`, `SET search_path = public, pg_temp`, `REVOKE ALL` de `PUBLIC, anon, authenticated` y `GRANT EXECUTE` solo a `service_role`:
  - Bloquea `compras_proveedor` (`WHERE id = p_compra_id AND organizacion_id = p_org FOR UPDATE`) → si no existe: `compra_no_encontrada`.
  - Si ya está `Recibida`: devuelve `{ ya_recibida: true, partidas: 0, movimientos: [] }` sin tocar stock ni movimientos (idempotente ante doble clic y concurrencia).
  - Si está `Cancelada`: `compra_cancelada`. Si tiene 0 filas en `compra_items`: `compra_sin_partidas`.
  - **Compatibilidad antes y después de Bloque G (sin cambiar tipos de columnas):** inspecciona `information_schema.columns` en tiempo de ejecución para `productos.stock_actual` y `movimientos_inventario.cantidad`. Mientras sean enteras (`smallint/integer/bigint`), rechaza cantidades no enteras con `cantidad_no_entera`; cuando G las migre a `NUMERIC(14,4)`, el mismo RPC acepta cantidades fraccionarias (ej. `2.5`) sin cambios.
  - Bloquea productos involucrados `ORDER BY p.id FOR UPDATE` filtrando `organizacion_id = p_org`; si alguna partida apunta a un producto inexistente o de otra organización, lanza `producto_no_encontrado` (rollback total).
  - Por partida (`ORDER BY id`): inserta movimiento `Entrada` (`referencia = 'Compra ' || folio`, `usuario_id = p_usuario`) y suma `stock_actual = COALESCE(stock_actual, 0) + v_item.cantidad` en una sola sentencia `UPDATE` (dos partidas del mismo producto se suman). Marca `estado = 'Recibida'` en la misma transacción.

### 1.2 Backend Deno (`motor/compras_recepcion.ts` + `index.ts`)
- `motor/compras_recepcion.ts`:
  - `mapearErrorRpcCompra`: mapea todos los códigos SQL (`compra_no_encontrada` 404, `compra_cancelada`/`compra_sin_partidas`/`producto_no_encontrado` 409, `cantidad_no_entera`/`cantidad_invalida`/`22P02` 400, `40P01`/`40001` 409, `42883`/`PGRST202` 503, desconocido 500 sin filtrar `P0001`/`23xxx`).
  - `sanitizarCamposCompraUpdate`: lista blanca estricta (`estado`, `proveedor_id`, `cotizacion_id`, `fecha`, `fecha_vencimiento_pago`); bloquea `id`, `organizacion_id`, `folio`, `created_at`.
  - `validarTransicionEstadoCompra`: permite `Pendiente → Recibida`, `Pendiente → Cancelada` y `Recibida → Recibida` (idempotente); rechaza `Recibida → Pendiente/Cancelada` y `Cancelada → Recibida` con `409`.
  - `actualizarCompraProveedorMotor` (`PUT /compras-proveedor/:id`): filtra siempre `organizacion_id = orgId`, elimina el bucle manual y `ajustar_stock`, llama `serviceClient.rpc('recibir_compra_proveedor', ...)` revisando `error`. Si falla el recálculo posterior de requisición (`calcularRequisicion`), registra el motivo y devuelve `200` con `aviso` en lugar de `500` sobre una recepción ya exitosa.
  - `crearCompraProveedorMotor` (`POST /compras-proveedor`): valida partidas (`cantidad > 0`, `costo_unitario >= 0`) y pertenencia de productos a `orgId` antes de insertar; revisa error del insert de `compra_items` y, si falla, elimina la compra recién creada (cero compras fantasma). Se optó por validación + compensación limpia en lugar de un nuevo RPC para mantener el alcance mínimo del bloque.
- No se tocaron `GET /compras-proveedor`, rutas CxP, `POST /inventario/movimientos`, `procesar_inventario_por_cotizacion`, Bloque F ni costos/precios.

### 1.3 Frontend (`ComprasProveedorList.tsx` + `useSupabaseData.ts`)
- `ComprasProveedorList.tsx`: diálogo de confirmación previo con texto exacto `"Se sumará al inventario: N partidas. Esta acción no se puede deshacer desde aquí."`, bloqueo del botón con spinner `Loader2` durante la petición, captura explícita de errores con banner de alerta (`AlertTriangle` + mensaje real + botón `Reintentar`) y actualización de estado solo tras confirmación del servidor. Responsive a 768px y 375px.
- `useSupabaseData.ts`: `actualizarCompraProveedor` preserva `items` y, tras confirmar `estado === 'Recibida'`, refresca `productos` para que `/inventario` refleje el nuevo stock sin recargar la página.

### 1.4 Diagnóstico de solo lectura
- `scripts/sql/diagnostico_stock_vs_movimientos.sql`: solo `SELECT` (compara `stock_actual` vs suma neta de movimientos, audita compras `Recibida` vs movimientos `'Compra <folio>'`, y lista compras `Pendiente` sin partidas).

---

## 2. Verificación y pruebas ejecutadas

| Prueba | Resultado | Detalle |
|---|---|---|
| Migración `20261125_02_compras_recepcion.sql` ×2 en PG 17 real (`ON_ERROR_STOP=1`) | **PASA (0 errores)** | Idempotente sobre BD clonada de plantilla `remolques`. |
| `docs/compras/verificacion_compras_recepcion.sql` (PG 17 real) | **11/11 `PASA`** | `ajustar_stock` eliminada, multi-partida + 2 partidas mismo producto, idempotencia `ya_recibida`, `Cancelada`, sin partidas, org ajena, producto ajeno (todo-o-nada), `cantidad_no_entera` con `INT`, fraccionaria `2.5` exacta tras `ALTER TYPE NUMERIC(14,4)`, permisos `authenticated`/`anon`. |
| Diagnóstico `scripts/sql/diagnostico_stock_vs_movimientos.sql` | **PASA (solo SELECT)** | Ejecutado limpio sobre PG 17 real. |
| Concurrencia real en 2 sesiones PG 17 (`OC-CR-CONC`, +7) | **PASA** | `antes: 4, despues: 11, movs: 1, ya: [false, true]` (stock sube una sola vez). |
| Reproducción HTTP real (`scripts/dev/repro_recepcion_compra.cjs`) | **PASA** | `PUT` → 200, stock `10 → 15`, 1 movimiento `Entrada`, segunda llamada idempotente. |
| Pruebas Deno (`motor/compras_recepcion.test.ts` + suite completa) | **PASA** | 4 nuevas suites en `compras_recepcion.test.ts`; suite completa en `verificar --limpio` en verde. |
| Mutaciones (`scripts/dev/test_compras_recepcion_mutaciones.cjs`) | **15/15 muertos, 0 vivos** | Lista blanca, transiciones, filtro `organizacion_id`, error RPC ignorado, mapeos 404/400/409, validación POST, borrado compra fantasma, aviso requisición, UUID. |
| E2E navegador real (`scripts/dev/test_compras_recepcion_browser.cjs`) | **TODO PASA, 0 errores consola** | Confirmación con texto exacto, corte API → aviso + `Reintentar` + sigue `Pendiente`, reintento con doble clic, stock en `/inventario` actualizado sin recargar (`18` y `13`), movimiento en Historial, 768px y 375px sin overflow horizontal. |
| `node scripts/verificar.mjs --limpio` | **11/11 OK** | Verificado con árbol limpio. |

### Evidencia visual inspeccionada (`COORDINACION/EVIDENCIA/`)
- `compras_recepcion_01_confirmacion.png`: Diálogo de confirmación de `OC-CR-E2E` con el aviso de 2 partidas.
- `compras_recepcion_02_error_reintentar.png`: Error de API capturado en pantalla con ícono `AlertTriangle` y botón `Reintentar` (compra sigue `PENDIENTE`).
- `compras_recepcion_03_inventario_actualizado.png`: Pantalla `/inventario` actualizada sin recargar tras confirmar la recepción.
- `compras_recepcion_04_mobile_compras.png`: `/compras` a 375×812 px sin desbordamiento horizontal.

### Cómo reproducir localmente
```bash
psql -h 127.0.0.1 -p 54331 -U tester -d test_compras_rec -v ON_ERROR_STOP=1 -f supabase/migrations/20261125_02_compras_recepcion.sql
psql -h 127.0.0.1 -p 54331 -U tester -d test_compras_rec -v ON_ERROR_STOP=1 -f scripts/dev/seed_compras_recepcion.sql
PGDATABASE=test_compras_rec PGPORT=54331 PGUSER=tester BRIDGE_PORT=54321 node scripts/dev/local_supabase_bridge.cjs
SUPABASE_URL=http://127.0.0.1:54321 SUPABASE_SERVICE_ROLE_KEY=local-service-key SUPABASE_ANON_KEY=local-anon-key PORT=8000 deno run --allow-net --allow-env --allow-read supabase/functions/make-server-feea4382/index.ts
VITE_API_URL=http://127.0.0.1:8000 npx vite --port 5173 --strictPort
PGDATABASE=test_compras_rec node scripts/dev/repro_recepcion_compra.cjs
node scripts/dev/test_compras_recepcion_browser.cjs
node scripts/dev/test_compras_recepcion_mutaciones.cjs
```

---

## 3. Despliegue y comportamiento ante despliegue parcial

### Orden obligatorio (migración → API → Web)
1. **Consultas de solo lectura en Supabase SQL Editor:** correr verificación de dependientes de `ajustar_stock` y `scripts/sql/diagnostico_stock_vs_movimientos.sql`.
2. **Migración:** ejecutar `supabase/migrations/20261125_02_compras_recepcion.sql` (sin bloqueos de tabla: solo `DROP FUNCTION` + `CREATE OR REPLACE FUNCTION`, <100 ms).
3. **Backend (`remolques-api` en EasyPanel):** Rebuild.
4. **Frontend (`remolques-web` en EasyPanel):** Rebuild.

### Si falta una pieza
- **API desplegado sin migración:** recibir una compra devuelve `503` claro (`rpc_no_disponible`), sin marcar la compra `Recibida` ni corromper stock.
- **Migración corrida sin API nuevo:** el código viejo llama a la función eliminada y sigue sin subir stock (igual que hoy). Por eso el orden obligatorio es **migración → API → web**.

---

## 4. Preguntas abiertas para Luis (no decididas aquí)

1. **¿Se puede revertir una recepción de compra?** Hoy está bloqueado (`Recibida` no vuelve a `Pendiente`/`Cancelada`). Si se requiere anular una recepción de compra por error de captura, conviene un RPC de anulación con movimiento contrario en un bloque posterior.
2. **¿Recepción parcial de compras?** `compra_items` no tiene `cantidad_recibida`; actualmente `Recibida` es todo-o-nada.
3. **Compras `Pendiente` sin partidas existentes:** el RPC las rechaza (`compra_sin_partidas`). El diagnóstico lista si existe alguna en producción para que Luis decida si se cancelan o se recapturan.
4. **`POST /inventario/movimientos`:** actualmente hace lectura → suma en JS → escritura (condición de carrera) y no valida atómicamente; se propone migrarlo a un RPC atómico en un bloque separado.
5. **Doble conteo con Bloque G:** `facturas_proveedor.compra_id` casi nunca se llena en el importador CFDI; Bloque G ya cubre ambos casos (`compra_id` + compras `Recibida` del mismo proveedor en ±60 días con producto compartido).

---

## 5. Ronda 2 — Cierre de observaciones O1 y O2 (`COMPRAS_RECEPCION_REVISION_CLAUDE.md`)

- **Sin migración nueva.**
- **O1 (carrera recibir vs cancelar en `PUT /compras-proveedor/:id`):**
  - En `supabase/functions/make-server-feea4382/motor/compras_recepcion.ts`, cuando el `UPDATE` no recepcional cambia el `estado` (ej. `Pendiente → Cancelada`), ahora exige `.eq("estado", prevCompra.estado)` (`AND estado = <el leído>`). Si otra petición ya recibió la compra en el intervalo, el `UPDATE` afecta 0 filas y responde **`409`** (`estado_cambiado`): `"La compra cambió de estado; recarga e inténtalo de nuevo"`, sin sobreescribir `Recibida`.
  - Cubierto por la nueva prueba `R-C5 (O1)` en `rev_compras_extra.test.ts` (simula cambio concurrente a `Recibida` entre lectura previa y `UPDATE`, verifica 409 y estado preservado, más caso normal `Pendiente → Cancelada`).
- **O2 (incorporación de pruebas extra y mutaciones):**
  - Se incorporó `supabase/functions/make-server-feea4382/motor/rev_compras_extra.test.ts` (`R-C1` a `R-C5`, 5 pruebas; 9/9 en total junto a `compras_recepcion.test.ts`).
  - `EXTRA=1 node COORDINACION/REVISIONES/arnes_revision_compras/mutar_compras.cjs`: **28 muertas, 0 vivas, 0 no aplica** (28/28).
  - `node scripts/dev/test_compras_recepcion_mutaciones.cjs`: **15 muertas, 0 vivas, 0 no aplica** (15/15).
- **`node scripts/verificar.mjs --limpio`:** **11/11 TODO OK** (423 pruebas Deno pasan, 0 fallan).

