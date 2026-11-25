# Reporte de Implementación — Bloque G: Recibir factura en almacén (XML → entradas de inventario)

- **Fecha:** 2026-11-25
- **Rama:** `almacen-g-2026-11-24` (worktree independiente desde `main` `87be541`)
- **Revisa:** Claude (sin merge ni push a `main`)
- **Plan de referencia:** `COORDINACION/PLAN_CAMBIOS_VISITA_2026-11-20.md` (bloque G) y `PROMPT_ANTY_ALMACEN_G_2026-11-24.md`

---

## 0. Hallazgos de pre-vuelo (§0 — Auditoría en Postgres 17 real)

1. **Dependencias de columnas a alterar (`productos.stock_*`, `movimientos_inventario.cantidad`, `catalogo_alias_factura.destino_id`):**
   - Cero vistas y cero columnas generadas dependen de esas columnas.
   - Solo 4 funciones en `public` las referencian: `ajustar_stock`, `procesar_inventario_por_cotizacion`, `aplicar_precios_acero_cfdi` y `renombrar_proveedor_acero`.
   - `catalogo_alias_factura.destino_id` se migró de `UUID` a `TEXT` verificando previamente todas las referencias SQL/TS; los índices (`idx_catalogo_alias_factura_org_tipo`, `uq_catalogo_alias_factura_clave`) se conservaron intactos y las filas de alias existentes permanecen idénticas. El diff en `aplicar_precios_acero_cfdi` es únicamente el cast `::TEXT` (misma firma, `SECURITY DEFINER`, `search_path` y permisos).

2. **Reproducción en vivo del bug de `ajustar_stock` (`PUT /compras-proveedor/:id` -> `Recibida`):**
   - En BD temporal `test_almacen_g_s0` (PG 17 real + bridge + Deno), se envió `PUT /compras-proveedor/22222222-2222-4222-8222-222222222299` con `{ "estado": "Recibida" }`.
   - **Respuesta HTTP de la API:** `200 OK` (315 ms).
   - **Error real en Postgres:** `POST /rest/v1/rpc/ajustar_stock` falló con `operator does not exist: text = uuid` (porque `productos.id` es `TEXT` y `ajustar_stock` recibía `p_producto_id UUID`).
   - **Estado resultante de las 3 filas:**
     - `compras_proveedor`: `OC-S0-TEST` quedó en estado **`Recibida`**.
     - `movimientos_inventario`: se insertó la fila `60f979ae-cde1-46f7-a6b3-c6817e65cb46` (`Entrada | 5 | Compra OC-S0-TEST`).
     - `productos.stock_actual`: **permaneció en `10`** (nunca subió a `15`).
   - Por indicación explícita tras aprobar §0, **no** se modificaron `ajustar_stock`, `PUT /compras-proveedor/:id` ni `POST /inventario/movimientos` en este bloque (se atienden en la rama dedicada `compras-recepcion-2026-11-24`).

3. **Escritores de `stock_actual`, pantallas que muestran stock y `facturas_proveedor.compra_id`:**
   - Todos los escritores de `stock_actual` auditados; `procesar_inventario_por_cotizacion` probado con `NUMERIC(14,4)` (`Aprobada → Cancelada`).
   - `facturas_proveedor.compra_id` nunca es rellenado por el importador CFDI (casi siempre viene `NULL`), por lo que el guardián de doble conteo no podía depender únicamente de `compra_id`.

---

## 1. Qué se construyó

### 1.1 Base de datos (`supabase/migrations/20261126_01_almacen_g.sql`)
- `productos.stock_actual`, `stock_reservado`, `stock_minimo` y `movimientos_inventario.cantidad` migrados a `NUMERIC(14,4)`.
- Columnas nuevas de solo referencia en `productos`: `ultimo_costo_compra NUMERIC(14,4)`, `ultimo_costo_compra_fecha DATE`, `ultimo_costo_compra_factura_id UUID REFERENCES facturas_proveedor(id) ON DELETE SET NULL`. **Nunca** se tocan `productos.costo` ni `productos.precio_unitario`.
- `catalogo_alias_factura.destino_id` migrado a `TEXT` con soporte para `destino_tipo = 'producto'` (sin alterar ni pisar alias `'acero_material'` de Bloque F).
- Tablas nuevas con RLS (`organizacion_id = get_current_org_id()`):
  - `almacen_recepciones` (`estado IN ('recibida', 'anulada')`, `motivo_anulacion`, `anulada_el`, `anulada_por`).
  - `almacen_recepcion_lineas` con índice único parcial `uq_almacen_recepcion_linea_partida_activa ON (partida_id) WHERE activa = true` para impedir doble recepción de la misma partida y permitir re-recepción tras anulación.
- RPC `recibir_factura_almacen(...)` (`SECURITY DEFINER`, `SET search_path = public, pg_temp`):
  - Valida factura abierta (rechaza `cancelada`), productos `tipo = 'bien'`, cantidades `> 0`, factor obligatorio en unidades de peso (`KGM/GRM/TNE/LBR`), tipo de cambio válido en `USD`, bloqueo ordenado `ORDER BY id FOR UPDATE` sobre `productos` (previene deadlocks `40P01`).
  - **Guardián de doble conteo (a + b)** (rechaza con `compra_ya_recibida` salvo `p_confirmo_doble = true`):
    - **(a)** `facturas_proveedor.compra_id` ligada a una compra `Recibida`.
    - **(b)** Cualquier compra `Recibida` de la misma organización y mismo `proveedor_id` en ventana de ±60 días que comparta al menos un producto (`compra_items.material_id`) con las líneas a recibir.
  - Suma cantidades fraccionales (incluso múltiples líneas del mismo producto en la misma factura), inserta `movimientos_inventario` (`Entrada`), actualiza `ultimo_costo_compra` **solo si** la factura es de fecha `>= ultimo_costo_compra_fecha` (o si es `NULL`), y guarda alias `destino_tipo = 'producto'` sin sobreescribir alias `'acero_material'`.
- RPC `anular_recepcion_almacen(p_recepcion_id, p_motivo, ...)` (`SECURITY DEFINER`):
  - Bloquea la recepción y los productos ordenados por `id`, verifica que no haya sido anulada (`recepcion_ya_anulada`) y que el stock actual alcance para revertir sin quedar negativo (`stock_insuficiente_para_anular`), resta stock, inserta `movimientos_inventario` (`Salida`), marca `activa = false` en `almacen_recepcion_lineas` (liberando las partidas) y `estado = 'anulada'` en `almacen_recepciones`, sin revertir `ultimo_costo_compra`.

### 1.2 Backend Deno (`supabase/functions/make-server-feea4382/`)
- `motor/almacen_recepcion.ts`: reutiliza `normalizarDescripcion`, `clasificarUnidadCfdi` y `sugerirMaterial` de `motor/acero_cfdi.ts`. Implementa propuesta con 3 orígenes (`alias`, `similitud`, `ninguna`), detección de servicio probable (fletes/maniobras/E48), banderas de peso (`KGM/GRM/TNE/LBR`), `USD`, descuento en factura, `compra_ya_recibida`, `posible_compra_duplicada` + `folios_compras_duplicadas` + `folios_por_producto`, validación de lote y mapeo de errores RPC.
- `motor/acero_cfdi.ts`: `listarCatalogoAlias` resuelve también `destino_nombre` desde `productos` cuando `destino_tipo === 'producto'`.
- `index.ts`: 4 endpoints protegidos por `authMiddleware`:
  - `GET /almacen/facturas/:facturaId/propuesta`
  - `POST /almacen/facturas/:facturaId/recibir`
  - `GET /almacen/recepciones`
  - `POST /almacen/recepciones/:id/anular`
- `scripts/dev/local_supabase_bridge.cjs`: soporte RPC para `recibir_factura_almacen` y `anular_recepcion_almacen`.

### 1.3 Frontend (`src/app/`)
- `src/app/hooks/useSupabaseData.ts`: `normalizarProductoNumerico` convierte `NUMERIC` → `Number()` en un único punto para toda la app (carga desde API, fallback localStorage, crear/actualizar producto y `cantidad` en `obtenerMovimientosInventario`).
- `src/app/utils/almacenApi.ts`: cliente tipado + `formatearCantidadStock(v)` (`12`, `12.5`, nunca `12.0000`).
- `src/app/components/Inventario/RecibirFacturaAlmacenModal.tsx`: modal interactivo con estados `cargando | error | ok` + botón `Reintentar`, aviso de doble conteo con ícono + folios + checkbox `"Confirmo que no es la misma mercancía"`, bloqueo de líneas de peso sin factor confirmado, servicios probables sin marcar por defecto, bloqueo anti-doble clic, preservación de estado ante error de API y botón `"Ver en Inventario"`.
- `src/app/components/Finanzas/CxpFacturasTab.tsx` + `CuentasPorPagarMain.tsx` + `App.tsx`: botón `"Almacén"` junto a `"Acero"` en facturas no canceladas; al confirmar recepción recarga productos y facturas sin F5.
- `src/app/components/Inventario/InventarioList.tsx`: columna `"Último costo compra (s/IVA)"` con fecha `YYYY-MM-DD` y acceso a CxP; formateo con `formatearCantidadStock`; botón y modal `"Recepciones"` (`Todas | Recibidas | Anuladas`, `cargando | error | ok` + `Reintentar`) con flujo de **Anular** (motivo obligatorio + explicación clara de efectos); **nota sobre `parseInt` en L231**: se actualizó a `parseFloat` con `step="any"` y `min="0.0001"` para que los ajustes manuales acepten cantidades fraccionales consistentes con `NUMERIC(14,4)`.
- `src/app/components/Cotizaciones/GenerarOrdenProduccionModal.tsx`: usa `formatearCantidadStock` en el selector de stock.
- `src/app/components/OrdenesTrabajo/ChecklistDespiecePanel.tsx`: consulta secundaria de solo lectura a `/productos` que muestra la insignia `"Existencia registrada: X <unidad> · no descuenta entregas"` cuando la línea referencia un bien; nunca bloquea entregas y no toca `registrarEntrega` ni `entregarFaseCompleta`.

---

## 2. Verificación y pruebas ejecutadas

| Prueba | Resultado | Detalle |
|---|---|---|
| Migración idempotente ×2 (`20261126_01_almacen_g.sql`, PG 17 real, `ON_ERROR_STOP=1`) | **PASA (0 errores)** | Corrida 2 veces seguidas sobre `test_almacen_g`. |
| `docs/almacen/verificacion_G.sql` (PG 17 real) | **19/19 `PASA`** | Incluye trigger `procesar_inventario_por_cotizacion` (`Aprobada → Cancelada`), doble conteo (a) y (b) 60d, fraccionales, 2 líneas mismo producto, KGM sin/con factor, USD TC, factura vieja preserva `ultimo_costo_compra`, anulación con/sin stock, RLS. |
| No-regresión Bloque F (`rev_f.sql` + `rev_f2_r2.sql` sin cambios en `test_almacen_g`) | **18/18 + 7/7 `PASA`** | `catalogo_alias_factura.destino_id` como `TEXT` no rompe nada de Bloque F. |
| Concurrencia real en 2 sesiones PG 17 (`CONC_RECIBIR` y `CONC_ANULAR`) | **PASA** | `CONC_RECIBIR`: 1 ok, 1 `partida_ya_recibida`, stock `+5` una vez (`15.0000`). `CONC_ANULAR`: 1 ok, 1 `recepcion_ya_anulada`, stock `10.0000`. |
| Pruebas unitarias Deno (`motor/almacen_recepcion.test.ts` + `motor/acero_cfdi.test.ts`) | **17/17 `PASA`** | Antes: 10 pruebas (solo Bloque F); después: 17 pruebas (+7 suites de Bloque G). |
| Pruebas de mutación (`mutar_g.cjs`) | **19/19 muertos, 0 vivos** | Incluye mutaciones sobre doble conteo (b), ventana de 60d, filtro `organizacion_id`, `tipo='bien'`, `destino_tipo='producto'`. |
| TypeScript (`tsc --noEmit` en archivos tocados) + `npm run build` | **0 errores nuevos / build verde** | Bundle Vite construido limpio. |
| E2E en navegador real (`scripts/dev/seed_almacen_g.sql` + `scripts/dev/test_almacen_g_browser.cjs`) | **TODO PASA, 0 errores consola** | Probó botón visible/oculto en cancelada, corte API en propuesta + Reintentar, 3 orígenes (`Recordado`/`Sugerido`/`Sin sugerencia`), KGM bloqueado, servicio desmarcado, corte API en recibir preservando estado, doble clic bloqueado, recepción parcial, USD TC 20 (`$1,000.00`), factura vieja no pisa último costo, formato sin `.0000`, servicio ausente en Inventario, modal Recepciones + anulación (`6 -> 5` preservando `$1,000.00`), responsive 768px y 375px sin overflow horizontal. |
| `node scripts/verificar.mjs --limpio` | **11/11 PASA** | Verificado con árbol limpio al final. |

### Evidencia visual inspeccionada (`COORDINACION/EVIDENCIA/`)
- `almacen_g_01_cxp_boton.png`: CxP → Facturas con botón `Almacén` en abiertas y oculto en `F-E2E-004-CANC`.
- `almacen_g_02_modal_propuesta.png`: Modal `Recibir factura en almacén F-E2E-001` con badges `Recordado`, `Sugerido`, `Sin sugerencia`, `Captura factor (KGM)`, `En compra OC-E2E-DUP-01` y `Servicio probable`.
- `almacen_g_03_inventario_actualizado.png`: Inventario en modo oscuro semántico con botones `Recepciones`, `Historial`, `Ajuste Manual`, y cantidades formateadas sin `.0000`.
- `almacen_g_04_recepciones_anular.png`: Modal `Recepciones de facturas en almacén` con filtros `Todas | Recibidas | Anuladas` y botón `Anular`.
- `almacen_g_05_mobile_inventario.png`: Inventario a 375×812 px sin desbordamiento horizontal y toast de anulación exitosa.

### Cómo reproducir el E2E localmente
```bash
# 1. Crear BD local con esquema base + migraciones (incluyendo 20261125_01 y 20261126_01)
psql -h 127.0.0.1 -p 54331 -U tester -d test_almacen_g -v ON_ERROR_STOP=1 -f scripts/dev/seed_almacen_g.sql
# 2. Levantar bridge, Deno y Vite
PGDATABASE=test_almacen_g PGPORT=54331 PGUSER=tester BRIDGE_PORT=54321 node scripts/dev/local_supabase_bridge.cjs
SUPABASE_URL=http://127.0.0.1:54321 SUPABASE_SERVICE_ROLE_KEY=local-service-key SUPABASE_ANON_KEY=local-anon-key PORT=8000 deno run --allow-net --allow-env --allow-read supabase/functions/make-server-feea4382/index.ts
VITE_API_URL=http://127.0.0.1:8000 npx vite --port 5173 --strictPort
# 3. Correr pruebas de navegador
node scripts/dev/test_almacen_g_browser.cjs
```

---

## 3. Despliegue, bloqueos y comportamiento ante despliegue parcial

### Orden obligatorio de despliegue (cuando se apruebe el merge a `main`)
1. **Rebasar** esta rama sobre `compras-recepcion-2026-11-24` una vez que entre a `main`.
2. **Base de datos (Supabase SQL Editor):** ejecutar `supabase/migrations/20261126_01_almacen_g.sql`.
   - **Bloqueos / duración estimada:** `ALTER COLUMN ... TYPE NUMERIC(14,4)` en `productos` y `movimientos_inventario`, y `ALTER COLUMN destino_id TYPE TEXT` en `catalogo_alias_factura` toman `ACCESS EXCLUSIVE` breve por tabla; con el volumen actual de Leolca (<10k filas), la ejecución completa toma **< 1 segundo**. Se recomienda correr en horario de baja actividad (fuera de captura simultánea de inventario).
3. **Backend (`remolques-api` en EasyPanel):** clic en **Rebuild**.
4. **Frontend (`remolques-web` en EasyPanel):** clic en **Rebuild**.

### Comportamiento si falta una pieza
- **Si corre la migración pero aún no se despliega API/Web:** totalmente compatible hacia atrás; Bloque F (`aplicar_precios_acero_cfdi`) y las pantallas existentes siguen operando sin cambios.
- **Si se despliega Web sin API o sin migración:** el botón `"Almacén"` y el modal `"Recepciones"` muestran aviso de error claro con botón `"Reintentar"` (nunca simulan éxito ni ocultan el fallo).

---

## 4. Preguntas abiertas y seguimiento (fuera de alcance de Bloque G)

1. **Carrera en `POST /inventario/movimientos`:** el endpoint actual lee `stock_actual`, calcula el nuevo valor en JS y hace `UPDATE` sin `FOR UPDATE`, por lo que dos ajustes manuales concurrentes pueden perder una actualización. Queda documentado para migrarse a un RPC atómico en un bloque separado (no se tocó por regla del bloque).
2. **Fix de `ajustar_stock` / recepción de compras (`PUT /compras-proveedor/:id`):** documentado en §0(2) (`operator does not exist: text = uuid`). Se atiende en la rama dedicada `compras-recepcion-2026-11-24`; al mergearse a `main`, esta rama se rebasará encima.
3. **Carga de inventario inicial (conteo físico):** actualmente muchos productos arrancan con `stock_actual = 0`. Para que las existencias reflejen el almacén real antes de recibir nuevas facturas, conviene definir un flujo guiado (importación CSV o plantilla de conteo inicial) que registre movimientos `Ajuste` con referencia `"Inventario inicial YYYY-MM-DD"`.

---

## 5. Ronda 2 — Correcciones a revisión de Claude (`ALMACEN_G_REVISION_CLAUDE.md`)

### D1 — Bloqueo de edición/borrado en cascada de partidas de facturas ya recibidas
- **Migración (`supabase/migrations/20261126_01_almacen_g.sql`):**
  - Se cambiaron las llaves foráneas `almacen_recepciones.factura_id` y `almacen_recepcion_lineas.partida_id` de `ON DELETE CASCADE` a **`ON DELETE RESTRICT`** (con bloques `DO $$ ...` idempotentes para instalaciones previas).
  - Para permitir editar partidas **después de anular** una recepción sin perder trazabilidad: `almacen_recepcion_lineas` añade `partida_id_original UUID` y `CHECK (activa = false OR partida_id IS NOT NULL)`. Al recibir se guarda `partida_id` y `partida_id_original`; al anular (`anular_recepcion_almacen`), `activa = false` y `partida_id = NULL` (conservando `partida_id_original`), liberando las partidas para `guardar_factura_con_partidas` mientras que cualquier recepción activa sigue protegida en BD por `ON DELETE RESTRICT`.
- **Rutas y motores CxP / Almacén (`index.ts`, `motor/cuentas_por_pagar.ts`, `motor/almacen_recepcion.ts`):**
  - `PUT /cxp/facturas/:id/partidas`: comprueba recepciones activas (`almacen_recepciones.estado = 'recibida'`) junto con pagos asignados; si solo cambia descripción/`clave_sat`/`clave_unidad`, actualiza en sitio sin borrar partidas ni tocar la recepción; si cambian montos/cantidades/conteo, responde **`409`**: `"La factura ya fue recibida en almacén; anula la recepción antes de modificar sus partidas"`.
  - `guardarFacturaConPartidasMotor` (cubre `PUT /cxp/facturas/:id`, `POST /cxp/facturas/:id/partidas` y `PUT /cxp/facturas/:id/partidas`): valida recepciones activas (`409`) y mapea `23503` / FK de almacén a `409`.
  - `mapearErrorRpcAlmacen` y `formatearErrorRespuesta`: mapean SQLSTATE `23503` y las FKs `almacen_recepcion_lineas_partida_id_fkey` / `almacen_recepciones_factura_id_fkey` a **`409`** (nunca `500`), cubriendo también reimportación de XML.
- **Verificación en Postgres 17 real (migración ×2 idempotente):**
  - `arnes_revision_g/i_rpc_real.sql`: `guardar_factura_con_partidas` falla con `23503` (`violates foreign key constraint "almacen_recepcion_lineas_partida_id_fkey"`), la recepción conserva su línea activa (`lineas_en_recepcion=1`, `estado_recepcion=recibida`), intentar recibir otra vez falla con `partida_ya_recibida`, y `stock_actual` permanece en **`10.0000`** (ya no sube a 21).
  - `arnes_revision_g/rev_g.sql`: **67/67 `PASA`**, y el `DELETE FROM factura_proveedor_partidas` del bloque I es rechazado por la FK `ON DELETE RESTRICT` (`almacen_recepcion_lineas_partida_id_fkey`).
  - `docs/almacen/verificacion_G.sql`: **23/23 `PASA`**, incluyendo los nuevos casos `G10a` (RPC real bloqueada por `23503`), `G10b` (actualizar solo descripción en sitio conserva la recepción) y `G10c` (tras anular la recepción, `guardar_factura_con_partidas` sí edita partidas conservando `partida_id_original`).

### D2 y O1 — Cobertura de `obtenerPropuestaRecepcionAlmacen` y arnés de 38 mutaciones (`mutar_g.cjs`)
- Se amplió `motor/almacen_recepcion.test.ts` con pruebas de:
  - Ventana exacta `±60` vs `±61` días en **ambos sentidos** (fijando O1 contra SQL), estados `Pendiente`/`Cancelada`, otro proveedor, aislamiento por `organizacion_id` (factura, productos y alias), compra ligada (`Recibida` vs `Pendiente`), líneas inactivas (`activa = false`) vs activas, claves SAT de servicio `78/80/81/84`, descuento detectado por partida `tipo = 'descuento'` con cabecera en `0`, y redondeo exacto a 2 decimales de `diferencia_costo_pct` (`3.33`).
  - Mapeo `23503 → 409`, bloqueo en `guardarFacturaConPartidasMotor` y `cancelarFactura` (O2), y liberación tras anular la recepción.
- **Resultado sobre las 38 mutaciones de `COORDINACION/REVISIONES/arnes_revision_g/mutar_g.cjs`:**
  - **34 muertas, 4 vivas, 0 no aplica** (100% de las 12 mutaciones no equivalentes que quedaban vivas en ronda 1 — M1, M2, M3, M4, M5, M6, M7, M8, M9, M10, M13, M21, M37, M38 — ahora mueren).
  - **4 vivas equivalentes explicadas:**
    - `M19` (`factor 0` en `cantidadARecibir`): el cálculo posterior produce `cantidad = 0`, que igual falla como `cantidad_invalida` (y el RPC lo rechaza con `factor_invalido`).
    - `M26` (`cantidad 0` en `validarLoteRecepcion`): el RPC `recibir_factura_almacen` valida `cantidad_recibida > 0` y rechaza con `cantidad_invalida`.
    - `M32` (tope máximo de `listarRecepcionesAlmacen` 200 → 2000): tope defensivo de paginación no ejercitado en test unitario.
    - `M34` (filtro `organizacion_id` en líneas del listado): las líneas ya están acotadas por `recepcion_id` proveniente de `almacen_recepciones` filtrado por `organizacion_id` (y protegidas por RLS).

### O2 — Cancelación de factura con recepción activa
- `cancelarFactura` en `motor/cuentas_por_pagar.ts` comprueba `almacen_recepciones` con `estado = 'recibida'` y rechaza con **`409`**: `"No se puede cancelar una factura que ya fue recibida en almacén. Anula la recepción primero."` (tras anular la recepción, sí permite cancelar).
- `O3` (alias compartido con F) y `O4` (insignia `Existencia registrada: 0` en despiece) no se tocaron, pendientes de decisión de Luis.

