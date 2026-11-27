# Reporte — Bloque "Gestión de equipos" (`equipos-gestion-2026-11-27`)

- **Rama:** `equipos-gestion-2026-11-27` (worktree independiente desde `main` `daebb23`, que ya incluye Bloque G).
- **Commit principal de código:** `383e5c6` (`node scripts/verificar.mjs --limpio` → **11/11 TODO OK**, 442/442 pruebas Deno en verde).
- **Migración:** `supabase/migrations/20261127_01_equipos_gestion.sql` (idempotente; **no** ejecutada en producción).
- **Precios de cotización:** 0 archivos de precios/costeo/recetas tocados. Sin carga de equipos de Leolca. Sin merge ni push a `main`.

---

## 1. Resumen de lo implementado

### 1.1 Cancelar y reactivar equipo (nunca borrar)
- **Esquema (`20261127_01_equipos_gestion.sql`):**
  - Nuevas columnas en `ordenes_trabajo`: `cancelada_el TIMESTAMPTZ`, `cancelada_por UUID`, `motivo_cancelacion TEXT`, `fecha_pedido DATE`.
  - **No** se agregó `'Cancelado'` al `CHECK` de `ordenes_trabajo.estado` (sigue siendo `Pendiente`, `En Producción`, `Terminado`, `Liberado`).
  - Nueva tabla de bitácora `orden_cambios` (`organizacion_id`, `orden_trabajo_id`, `accion`, `antes`, `despues`, `motivo`, `usuario_id`, `creado_el`) con RLS: `SELECT` para `authenticated` filtrado por `organizacion_id = get_current_org_id()`, escritura exclusiva de `service_role` (`REVOKE ALL ... FROM PUBLIC, anon, authenticated; GRANT SELECT TO authenticated;`).
- **RPCs atómicas** (`SECURITY DEFINER`, `SET search_path = public, pg_temp`, `EXECUTE` exclusivo para `service_role`, `FOR UPDATE` sobre `ordenes_trabajo` y filtro explícito de `organizacion_id`):
  - `cancelar_orden_trabajo(p_org, p_usuario, p_orden_id, p_motivo, p_confirmo_material_entregado DEFAULT false)`:
    - Motivo obligatorio (`motivo_requerido` → 400).
    - Cobros aplicados vigentes (`pago_aplicaciones` + `pagos.estado = 'vigente'`) → rechaza con `409 orden_con_cobros_vigentes` indicando monto/cantidad y pidiendo anular o reasignar antes de cancelar.
    - Material entregado sin anular (`orden_despiece_entregas.anulada = false`) → exige `p_confirmo_material_entregado = true`, reporta cuántas entregas y cuántas unidades tiene (`409 orden_con_material_entregado`), y **no devuelve stock automáticamente**.
    - Idempotente: cancelar dos veces devuelve `ya_cancelada: true` sin error ni duplicación en `orden_cambios`.
    - Conserva intactos `estado`, `orden_fases`, `orden_despiece_entregas`, `pagos` y `productos.stock_actual`.
  - `reactivar_orden_trabajo(p_org, p_usuario, p_orden_id, p_motivo DEFAULT NULL)`:
    - Limpia `cancelada_el/por/motivo_cancelacion` dejando `estado` y `orden_fases` exactamente como estaban, registra en `orden_cambios`. Idempotente (`ya_activa: true`).
  - Validación de rol en servidor (`motor/equipos_gestion.ts` → `validarRolAdminOPropietario`): solo `admin` o `propietario` en `perfiles_organizacion` (403 para cualquier otro rol).
- **Rutas nuevas en `index.ts`:**
  - `POST /ordenes-trabajo/:id/cancelar`
  - `POST /ordenes-trabajo/:id/reactivar`
  - `PUT /ordenes-trabajo/:id/cliente`
  - `GET /ordenes-trabajo/:id/cambios`
  - `GET /ordenes-trabajo?canceladas=true` (por defecto solo activas `cancelada_el IS NULL`).
- **`POST /cotizaciones/:id/generar-ordenes` (`motor/generar_ordenes_cotizacion.ts`):**
  - Una orden cancelada cuenta como existente (no crea duplicados) y devuelve `canceladas_existentes` + un `mensaje` claro explicando que puede reactivarse desde **Órdenes de trabajo → Ver cancelados** (mostrado en el toast de `CotizacionesList.tsx`).

### 1.2 Cambiar cliente (solo `origen = 'manual'`)
- `cambiar_cliente_orden_trabajo(p_org, p_usuario, p_orden_id, p_cliente_id, p_etiqueta, p_motivo DEFAULT NULL)`:
  - `origen = 'cotizacion'` → rechaza con `409 orden_origen_cotizacion` explicando que el cliente proviene de la cotización.
  - `origen = 'manual'` → permite elegir un cliente del catálogo de la organización o dejarlo sin cliente con etiqueta (preservando la restricción que exige al menos uno de los dos).
  - El folio (`nomenclatura_id`) **no cambia**. Queda registrado en `orden_cambios`.

### 1.3 Fecha de pedido
- Columna `fecha_pedido DATE` nullable en `ordenes_trabajo`.
- Capturable en **"Nuevo equipo"** (`NuevoEquipoModal.tsx` → `POST /produccion/ordenes`).
- Editable en **Órdenes de trabajo** (`PUT /ordenes-trabajo/:id`) y en el **Detalle del Tablero** (`OrdenTrabajoDetalleSheet.tsx` → `PUT /produccion/ordenes/:id/planeacion`).
- Mostrada en **Órdenes de trabajo** y en el **Detalle del Tablero**, formateada en hora de México (`America/Mexico_City`, sin `toISOString().slice(0,10)`).

---

## 2. Inventario exhaustivo de TODAS las consultas que leen o escriben `ordenes_trabajo`

### 2.1 Vistas y funciones SQL (`supabase/migrations/`)

| Objeto SQL | Tipo | Acción tomada en `20261127_01_equipos_gestion.sql` |
|---|---|---|
| `v_orden_despiece_avance` | Vista (`security_invoker = true`) | Se agregó `JOIN ordenes_trabajo ot ON ot.id = l.orden_trabajo_id AND ot.cancelada_el IS NULL` para excluir equipos cancelados del despiece y del resumen de entregas. |
| `v_cobranza_equipo` | Vista (`security_invoker = true`) | Se agregó `AND cancelada_el IS NULL` en `ordenes_por_cot` y `WHERE ot.cancelada_el IS NULL` en el `SELECT` principal para excluir equipos cancelados de cobranza por equipo. Se conserva `GRANT SELECT TO authenticated`. |
| `v_plan_parcialidades_estado` | Vista (`security_invoker = true`) | **R2:** Se agregó `LEFT JOIN ordenes_trabajo ot ON ot.id = pl.orden_trabajo_id AND ot.organizacion_id = pl.organizacion_id` con `WHERE pl.orden_trabajo_id IS NULL OR ot.cancelada_el IS NULL` en `base_cobrado`, excluyendo planes propios de equipos cancelados y dejando intactos los planes por cotización. Conserva `security_invoker = true` y `GRANT SELECT TO authenticated`. |
| `resumen_calidad_ordenes(p_org)` | Función SQL (`SECURITY DEFINER`) | Se agregó `JOIN ordenes_trabajo ot ON ot.id = i.orden_trabajo_id AND ot.organizacion_id = p_org AND ot.cancelada_el IS NULL` para excluir equipos cancelados de calidad. |
| `actualizar_fase_orden(...)` | RPC escritura (`FOR UPDATE`) | Rechaza con `orden_cancelada` si `r_orden.cancelada_el IS NOT NULL`. |
| `registrar_entrega_despiece(...)` | RPC escritura | Bloquea `ordenes_trabajo FOR UPDATE` antes de `orden_despiece_lineas` (serializa con `cancelar_orden_trabajo` sin deadlocks) y rechaza con `orden_cancelada`. |
| `entregar_fase_despiece(...)` | RPC escritura | Bloquea `ordenes_trabajo FOR UPDATE` y rechaza con `orden_cancelada`. |
| `anular_entrega_despiece(...)` | RPC escritura | Bloquea `ordenes_trabajo FOR UPDATE` y rechaza con `orden_cancelada`. |
| `ajustar_cantidad_despiece(...)` | RPC escritura | Bloquea `ordenes_trabajo FOR UPDATE` y rechaza con `orden_cancelada`. |
| `eliminar_linea_despiece(...)` | RPC escritura | Bloquea `ordenes_trabajo FOR UPDATE` y rechaza con `orden_cancelada`. |
| `guardar_plan_tarea(...)` | RPC escritura | Bloquea `ordenes_trabajo FOR UPDATE` si `p_orden_trabajo_id IS NOT NULL` y devuelve `orden_cancelada` (409) si está cancelada (o si la tarea editada pertenecía a una orden cancelada). |
| `cambiar_estado_plan_tarea(...)` | RPC escritura | Rechaza con `orden_cancelada` (409) si la tarea está ligada a una orden cancelada. |
| `crear_inspeccion_calidad(...)` | RPC escritura (`FOR UPDATE`) | Rechaza con `ORDEN_CANCELADA` (409) si `v_orden.cancelada_el IS NOT NULL`. |
| `guardar_resultados_calidad(...)`, `cerrar_inspeccion_calidad(...)`, `reabrir_inspeccion_calidad(...)`, `actualizar_encabezado_inspeccion(...)` | RPCs escritura calidad | Verifican `ordenes_trabajo.cancelada_el` y rechazan con `ORDEN_CANCELADA` (409). |
| `trg_validar_pago_aplicacion_fn()` | Trigger `pago_aplicaciones` | Rechaza con `orden_cancelada` si `v_orden.cancelada_el IS NOT NULL`. |
| `registrar_cobro(...)` | RPC escritura | Bloquea cada `ordenes_trabajo` de `p_aplicaciones` en orden determinista con `FOR UPDATE` (serializa con `cancelar_orden_trabajo` sin deadlocks) y rechaza con `orden_cancelada`. |
| `guardar_plan_pago(...)` | RPC escritura | Bloquea `ordenes_trabajo FOR UPDATE` si `p_orden_trabajo_id IS NOT NULL` y rechaza con `orden_cancelada`. |
| `crear_fases_orden` / `fn_recalcular_orden_trabajo` | RPC/Trigger interno fases | Solo corren al crear orden o actualizar `orden_fases` (que ya está bloqueado por `actualizar_fase_orden`). No se modificaron porque reactivar conserva fases intactas. |

### 2.2 Consultas en el servidor (`supabase/functions/make-server-feea4382/`)

| Archivo y función / ruta | Qué lee o escribe | Acción tomada |
|---|---|---|
| `index.ts` → `GET /ordenes-trabajo` (`motor/equipos_gestion.ts` → `listarOrdenesTrabajoMotor`) | Lista órdenes de trabajo (alimenta Órdenes de trabajo, Liberación, selector de tareas en Plan semanal, Calidad, Expediente) | Por defecto filtra `.is("cancelada_el", null)`. Solo con `?canceladas=true` devuelve `.not("cancelada_el", "is", null)` para el filtro **"Ver cancelados"**. |
| `index.ts` → `DELETE /cotizaciones/:id` | Verifica si alguna OT de la cotización tiene entregas en `orden_despiece_entregas` | **Intencionalmente sin filtrar `cancelada_el`**: las entregas de una orden cancelada siguen existiendo (`ON DELETE RESTRICT`) y deben impedir borrar la cotización. |
| `motor/tablero_produccion.ts` → `obtenerMatrizProduccion` (2 consultas: órdenes activas de línea y `todasOrdenesLinea` para numeración `#1, #2`) | Tablero de producción y Vista por fase | Se agregó `.is("cancelada_el", null)` en **ambas** consultas y se expone `fecha_pedido` en cada fila. |
| `motor/tablero_produccion.ts` → `actualizarPlaneacionMotor` | `PUT /produccion/ordenes/:id/planeacion` y `/material` | Agrega `.is("cancelada_el", null)`, rechaza con `409 orden_cancelada` si la orden está cancelada, y permite actualizar `fecha_pedido`. |
| `motor/tablero_produccion.ts` → `actualizarFaseMotor` / `moverOrdenMotor` | `PUT /produccion/ordenes/:id/fases/:faseId` y `/mover` | Propaga `orden_cancelada` de la RPC como HTTP `409`. |
| `motor/tablero_produccion.ts` → `crearOrdenManualMotor` | `POST /produccion/ordenes` ("Nuevo equipo") | Acepta, valida y guarda `fecha_pedido`. |
| `motor/tablero_produccion.ts` → `obtenerHistorialOrdenMotor` | `GET /produccion/ordenes/:id/historial` | Solo lectura de historial por ID. |
| `motor/plan_produccion.ts` → `obtenerPlanProduccion` | `GET /produccion/plan` (Plan semanal) | Selecciona `orden_trabajo.cancelada_el` y excluye tareas ligadas a equipos cancelados. |
| `motor/plan_produccion.ts` → `obtenerTrazabilidadOrden` | `GET /produccion/trazabilidad/orden/:ordenId` | Rechaza con 404 si `orden.cancelada_el` está presente. |
| `motor/plan_produccion.ts` → `obtenerTrazabilidadOperario` | `GET /produccion/trazabilidad/operario/:operarioId` | Excluye tareas ligadas a equipos cancelados. |
| `motor/plan_produccion.ts` → `guardarTarea` / `cambiarEstadoTarea` | `POST/PUT /produccion/tareas` | Mapea `orden_cancelada` de las RPCs a HTTP `409`. |
| `motor/checklist_almacen.ts` → `listarDespieceOT` | `GET /ordenes-trabajo/:id/despiece` | Verifica `ordenes_trabajo.cancelada_el` y rechaza con `409 orden_cancelada` si está cancelada (además de `v_orden_despiece_avance` filtrada). |
| `motor/checklist_almacen.ts` → `generarDespieceOT`, `entregarFaseCompleta`, `agregarLineaManual` | Escrituras de despiece/entregas | Seleccionan `cancelada_el` y rechazan con `409 orden_cancelada` antes de escribir. |
| `motor/resumen_entregas.ts` → `resumenEntregasOrdenesMotor` | `GET /ordenes-trabajo/resumen-entregas` | Lee `v_orden_despiece_avance`, que ya excluye `cancelada_el IS NOT NULL`. |
| `motor/calidad.ts` → `listarInspeccionesCalidad` | `GET /calidad/inspecciones` | Selecciona `orden.cancelada_el` y excluye inspecciones de equipos cancelados. |
| `motor/calidad.ts` → `obtenerResumenCalidadOrdenes` | `GET /calidad/resumen-ordenes` | Llama a `resumen_calidad_ordenes`, que ya excluye equipos cancelados. |
| `motor/calidad.ts` → `mapearErrorRpcCalidad` | Escrituras de calidad | Mapea `ORDEN_CANCELADA` a HTTP `409`. |
| `motor/cobros.ts` → `obtenerCobranzaCotizacion` | `GET /cobranza/cotizacion/:id` | Se agregó `.is("cancelada_el", null)` al consultar `ordenes_trabajo`. |
| `motor/cobros.ts` → `obtenerCobranzaEquipo` | `GET /cobranza/equipo/:ordenId` | Rechaza con 404 si `orden.cancelada_el` está presente. |
| `motor/cobros.ts` → `guardarValorEquipo` | `PUT /cobranza/equipo/:ordenId/valor` | Rechaza con `409 orden_cancelada` si `orden.cancelada_el` está presente. |
| `motor/cobros.ts` → `listarPlanesPago` | `GET /planes-pago` | **R2:** Se decidió **ocultar** los planes por equipo (`orden_trabajo_id IS NOT NULL`) cuyo equipo esté cancelado para mantener consistencia con `v_plan_parcialidades_estado` y no mostrar planes de equipos cancelados al consultar por cotización o por equipo; los planes por cotización (`orden_trabajo_id IS NULL`) permanecen sin cambio. |
| `motor/generar_ordenes_cotizacion.ts` → `generarOrdenesDeCotizacion` | `POST /cotizaciones/:id/generar-ordenes` | **Intencionalmente sin filtrar `cancelada_el`**: una orden cancelada cuenta como existente (no se crea otra) y se explica en `mensaje`. |
| `motor/generar_ordenes_cotizacion.ts` → `actualizarOrdenTrabajoSegura` / `regenerarFichaDeOrden` | `PUT /ordenes-trabajo/:id` y `POST /ordenes-trabajo/:id/regenerar-ficha` | Rechazan con `409 orden_cancelada` si el equipo está cancelado; `actualizarOrdenTrabajoSegura` valida y guarda `fecha_pedido`. |
| `index.ts` → `GET /portal/:token` (Portal cliente) | Portal público de cotización | **Verificado:** no consulta `ordenes_trabajo` (lee solo `cotizaciones`, `items_cotizacion`, `clientes`, `ajustes`, `productos`). No expone equipos cancelados. |

---

## 3. Evidencia de pruebas obligatorias

1. **Migración dos veces en Postgres 17 real (`test_equipos_gestion`):**
   - Aplicada cadena completa de migraciones + `20261127_01_equipos_gestion.sql` **×2 consecutivas** con `ON_ERROR_STOP=1`: código de salida `0`.
2. **Suite SQL integral (`docs/equipos/verificacion_equipos_gestion.sql`) en PG 17 real:**
   - CHECK de `estado` intacto (rechaza `'Cancelado'`), motivo obligatorio, aislamiento multi-org, bloqueo por cobros vigentes + desbloqueo al anular cobro, confirmación explícita con material entregado sin devolver stock, inmutabilidad de stock/entregas/fases/estado al cancelar y reactivar, idempotencia de cancelar ×2 y reactivar ×2, cambio de cliente solo en `manual` con folio intacto, exclusión en vistas (`v_orden_despiece_avance`, `v_cobranza_equipo`), rechazo de escrituras sobre cancelados (fases, entregas, plan semanal, calidad, cobros).
   - **RLS entre 2 organizaciones y permisos con roles reales (`anon` / `authenticated`):** `anon` y `authenticated` bloqueados de ejecutar las 3 RPCs y de escribir en `orden_cambios`; Org A solo lee `orden_cambios` de Org A (0 de Org B) y Org B solo lee Org B (0 de Org A).
3. **Concurrencia con dos sesiones PG 17 (`scripts/dev/test_equipos_gestion_concurrencia.cjs`):**
   - `cancelar_orden_trabajo` vs `registrar_cobro`: **5/5 carreras simultáneas + 2/2 deterministas en ambos sentidos** sin violación de invariante ni deadlocks.
   - `cancelar_orden_trabajo` (sin confirmación) vs `registrar_entrega_despiece`: **5/5 carreras simultáneas + determinista** sin violación de invariante ni deadlocks.
4. **Servidor Deno + mutaciones:**
   - `deno test --allow-all` sobre los 7 motores tocados (`equipos_gestion`, `generar_ordenes_cotizacion`, `tablero_produccion`, `plan_produccion`, `checklist_almacen`, `calidad`, `cobros`): **66 passed | 0 failed**.
   - Mutaciones (`scripts/dev/test_equipos_gestion_mutaciones.cjs`): **10/10 mutaciones muertas, 0 vivas**.
5. **Navegador E2E (Chrome headless + CDP contra Postgres 17 real + Deno + Vite):**
   - `scripts/dev/test_equipos_gestion_browser.cjs`: todas las aserciones OK.
   - Capturas guardadas e inspeccionadas visualmente:
     - `COORDINACION/EVIDENCIA/equipos_gestion_cambiar_cliente.png`
     - `COORDINACION/EVIDENCIA/equipos_gestion_cancelar.png`
     - `COORDINACION/EVIDENCIA/equipos_gestion_ver_cancelados.png`
     - `COORDINACION/EVIDENCIA/equipos_gestion_reactivar.png`
6. **Build & Verificación final:**
   - `npm run build`: verde.
   - `node scripts/verificar.mjs --limpio`: verde (ver commit abajo).

---

## 4. Ronda 2 — Cierre de observaciones (`EQUIPOS_GESTION_REVISION_CLAUDE.md`)

1. **`v_plan_parcialidades_estado` + `GET /planes-pago`:**
   - Redefinida `v_plan_parcialidades_estado` en `20261127_01_equipos_gestion.sql` conservando `security_invoker = true` y `GRANT SELECT TO authenticated`, excluyendo planes por equipo cuyo equipo esté cancelado y manteniendo intactos los planes por cotización.
   - Verificado en PG 17 real (`docs/equipos/verificacion_equipos_gestion.sql` paso `10a-bis` + migración ×2): antes de cancelar aparece `vencida` ($20,000), al cancelar desaparece (mientras el plan por cotización sigue visible), y al reactivar vuelve igual (`vencida`, $20,000).
   - En `motor/cobros.ts` → `listarPlanesPago` (`GET /planes-pago`): se decidió ocultar planes por equipo cancelado manteniendo intactos los planes por cotización (consistente con `v_plan_parcialidades_estado`).
2. **`CotizacionDetalle.tsx`:** usa `data.mensaje` cuando `data?.ya_existian` (evita decir "ya tiene 0 órdenes" si todas están canceladas).
3. **Columna "Equipo" en `OrdenesTrabajoList.tsx`:** `orden.modelo` se prioriza solo cuando `orden.origen === 'manual'`; en equipos de cotización se preserva exactamente el orden de `main` (`ficha?.cantidad_texto || orden.caracteristicas?.descripcion_corta || 'Remolque'`).
4. **Pruebas de los 12 filtros (+ `listarPlanesPago`) y mutaciones:**
   - Agregado `supabase/functions/make-server-feea4382/motor/equipos_filtros_cancelados.test.ts` (13 pruebas cubriendo los 12 filtros exactos señalados en D4 + `listarPlanesPago`, usando formas reales de Supabase).
   - Extendido `scripts/dev/test_equipos_gestion_mutaciones.cjs` para mutar cada una de las 12 líneas (más las 10 reglas de `equipos_gestion.ts` y `listarPlanesPago`): **23/23 mutaciones muertas, 0 vivas**.
5. **Aviso de material entregado:** actualizado tanto en `cancelar_orden_trabajo` (SQL) como en el diálogo de `OrdenesTrabajoList.tsx` para advertir explícitamente que, si el material regresa al almacén, hay que anular la entrega **antes** de cancelar porque en un equipo cancelado ya no se puede anular (habría que reactivar, anular y volver a cancelar).

---

## 5. Acciones manuales pendientes para despliegue
1. Revisar y aprobar merge de `equipos-gestion-2026-11-27` a `main`.
2. Ejecutar `supabase/migrations/20261127_01_equipos_gestion.sql` en el SQL Editor de Supabase (producción).
3. Hacer **Rebuild** de `remolques-api` y después de `remolques-web` en EasyPanel.
