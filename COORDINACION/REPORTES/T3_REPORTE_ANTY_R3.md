# Reporte Anty — T3 (Checklist de Almacén) — Ronda 3

**Fecha:** 2026-11-03 (Turno nocturno)  
**Rama:** `noche-t3-checklist`  
**Commit:** `e86926c`  
**Estado:** LISTO_PARA_REVISION  

---

## 1. Tabla de Hallazgos vs Solución en este Commit

| # | Hallazgo Claude R2 (`T3_REVISION_CLAUDE.md`) | Solución en Commit `e86926c` |
|---|---|---|
| 1 | **[ALTA] Emparejamiento BOM equivocado:** `BomEquipoResumen` no traía `item_id`, caía en `modelo_id` y ganaba el primer concepto. Sin coincidencia, el respaldo por índice de unidad tomaba el BOM de otro concepto. | `presupuesto_desde_costeo.ts` y `generar_presupuesto_cotizacion.ts` ahora propagan `item_id` e `id` en cada concepto de `meta.bom`. `generarDespieceOT` empareja prioritariamente por `item_id`. Si falta `item_id`, solo empareja por `modelo_id` si hay exactamente 1 coincidencia; si hay 2 o más conceptos con el mismo modelo y sin `item_id`, se detiene y responde **HTTP 409 `bom_ambiguo`** con la lista de conceptos conflictivos. Nunca adivina por índice. Se corrigieron los fixtures de prueba a la estructura real. |
| 2 | **[ALTA] "Anular" desde pantalla fallaba y no había historial por pieza:** `ultima_entrega` no traía `id`, enviando `entrega_id: undefined`. No se usaba `datos.entregas`. | Se agregó `'id', e_ult.id` al JSON de `ultima_entrega` en la vista `v_orden_despiece_avance`. En la interfaz, se agregó el botón **"Historial"** por partida abriendo un modal con todos los movimientos de entrega/reposición de la pieza y un botón "Anular" individual por cada movimiento activo con motivo obligatorio. |
| 3 | **[MEDIA] Respaldo por `meta.cotizacion_id` solo revisaba 50 presupuestos:** | Se reemplazó el `.select().limit(50)` por consulta directa indexada `.eq("datos->meta->>cotizacion_id", ot.cotizacion_id).maybeSingle()`. |
| 4 | **[MEDIA] Respaldo por `receta_base` armaba despiece crudo sin avisar:** | Las líneas generadas bajo respaldo de receta base cruda se etiquetan con `origen = 'receta_cruda'` (soportado en CHECK de BD) y la función emite `advertencia: 'receta_cruda'` mostrada como banner en la pantalla. |
| 5 | **[MEDIA] Regenerar no detectaba cambios y duplicaba piezas al cambiar de fase:** | La clave determinista se definió como `${matClave}::${kitNorm}` sin incorporar la fase. Al regenerar, las piezas con cambios de fase o cantidad respecto al presupuesto no se duplican en la base; se reportan en `cambios_no_aplicados` para ajuste manual en almacén. |
| 6 | **[MEDIA] "Entregar toda la fase" no registraba operario y no era atómica:** | Se creó la función SQL atómica `entregar_fase_despiece` con bloqueo de filas `FOR UPDATE` que entrega todas las piezas pendientes de la fase en una sola transacción. En frontend se integró un modal selector de operario para la entrega de fase. |
| 7 | **[MEDIA] Vale imprimible insertaba HTML sin escapar y no filtraba por fase:** | Se implementó la función de saneamiento `esc()` (`& < > " '`) para todos los campos interpolados en `printWindow`, evitando riesgos de DOM XSS. Se añadió selector para imprimir únicamente el vale de la fase activa o de todas las fases. |
| 8 | **[MEDIA] Cobertura de pruebas:** | Se ampliaron las pruebas Deno a 10 casos en `checklist_almacen.test.ts` (cubriendo 409 `bom_ambiguo`, regeneración con cambio de fase, `entregarFaseCompleta` y validaciones multi-org). `prueba_T3.sql` se enriqueció con pruebas atómicas de entrega por fase, validación de `NaN` y verificación de `orden_trabajo_id`. |
| 9 | **[MEDIA] Riesgo de tamaño de query string y truncado en entregas:** | Se agregó la columna `orden_trabajo_id` a la tabla `orden_despiece_entregas` con índice, permitiendo consultar directamente por OT sin agotar cabeceras HTTP; se agregó `.range(0, 1000)` y detección de `truncado: true`. |
| 10 | **[BAJA] Pieza sin equivalencia caía en Paso 1 sin aviso:** | Se añadió conteo `sin_fase` en la respuesta y aviso explícito en frontend cuando existen piezas asignadas a fase por omisión. |
| 11 | **[BAJA] "Ya entregada..." mostraba reposiciones:** | Se filtró `ultima_entrega` en `v_orden_despiece_avance` con `AND e_ult.tipo = 'entrega'`. |
| 12 | **[BAJA] `ajustar_cantidad_despiece` y `registrar_entrega` aceptaban `NaN`:** | Se añadieron validaciones explícitas `p_cantidad = 'NaN'::numeric` y `p_nueva_cantidad = 'NaN'::numeric` arrojando `cantidad_invalida`. |
| 13 | **[BAJA] Validaciones de pertenencia de OT y material:** | Las rutas operativas validan la pertenencia de la línea a la OT del parámetro URL (`:id`), y `agregarLineaManual` valida que `material_id` pertenezca a la organización. |
| 14 | **[BAJA] Inserción concurrente:** | Se utiliza `.upsert(lineasAInsertar, { onConflict: "orden_trabajo_id,equipo_indice,clave_origen", ignoreDuplicates: true })`. |
| 15 | **[BAJA] Bloqueo en anulación:** | `anular_entrega_despiece` bloquea tanto la entrega como la línea asociada (`SELECT ... FROM orden_despiece_lineas WHERE id = v_entrega.linea_id FOR UPDATE`), evitando falsos positivos de sobreentrega concurrente. |

---

## 2. Evidencia de Ejecución en Base de Datos Desechable (`anty_t3_test`)

Base de datos temporal creada como réplica de `remolques` sobre PostgreSQL 17 (puerto 54331), ejecutada y posteriormente eliminada:

### 2.1. Migración corrida dos veces (Idempotencia)

**Pase 1:**
```text
BEGIN
CREATE TABLE
DO
ALTER TABLE
psql:supabase/migrations/20261102_02_checklist_almacen.sql:61: NOTICE:  policy "orden_despiece_lineas_org_all" for relation "orden_despiece_lineas" does not exist, skipping
DROP POLICY
psql:supabase/migrations/20261102_02_checklist_almacen.sql:62: NOTICE:  policy "orden_despiece_lineas_org_select" for relation "orden_despiece_lineas" does not exist, skipping
DROP POLICY
CREATE POLICY
CREATE INDEX
CREATE INDEX
CREATE TABLE
DO
ALTER TABLE
psql:supabase/migrations/20261102_02_checklist_almacen.sql:122: NOTICE:  policy "orden_despiece_entregas_org_all" for relation "orden_despiece_entregas" does not exist, skipping
DROP POLICY
psql:supabase/migrations/20261102_02_checklist_almacen.sql:123: NOTICE:  policy "orden_despiece_entregas_org_select" for relation "orden_despiece_entregas" does not exist, skipping
DROP POLICY
CREATE POLICY
CREATE INDEX
CREATE INDEX
CREATE INDEX
CREATE FUNCTION
psql:supabase/migrations/20261102_02_checklist_almacen.sql:152: NOTICE:  trigger "trg_lineas_requerida_vs_entregada" for relation "orden_despiece_lineas" does not exist, skipping
DROP TRIGGER
CREATE TRIGGER
CREATE VIEW
CREATE FUNCTION
CREATE FUNCTION
CREATE FUNCTION
CREATE FUNCTION
CREATE FUNCTION
REVOKE
GRANT
REVOKE
GRANT
REVOKE
GRANT
REVOKE
GRANT
REVOKE
GRANT
COMMIT
```

**Pase 2 (Idempotente):**
```text
BEGIN
psql:supabase/migrations/20261102_02_checklist_almacen.sql:36: NOTICE:  relation "orden_despiece_lineas" already exists, skipping
CREATE TABLE
DO
ALTER TABLE
psql:supabase/migrations/20261102_02_checklist_almacen.sql:61: NOTICE:  policy "orden_despiece_lineas_org_all" for relation "orden_despiece_lineas" does not exist, skipping
DROP POLICY
DROP POLICY
CREATE POLICY
psql:supabase/migrations/20261102_02_checklist_almacen.sql:67: NOTICE:  relation "idx_orden_despiece_lineas_ot" already exists, skipping
CREATE INDEX
psql:supabase/migrations/20261102_02_checklist_almacen.sql:68: NOTICE:  relation "idx_orden_despiece_lineas_fase" already exists, skipping
CREATE INDEX
psql:supabase/migrations/20261102_02_checklist_almacen.sql:89: NOTICE:  relation "orden_despiece_entregas" already exists, skipping
CREATE TABLE
DO
ALTER TABLE
psql:supabase/migrations/20261102_02_checklist_almacen.sql:122: NOTICE:  policy "orden_despiece_entregas_org_all" for relation "orden_despiece_entregas" does not exist, skipping
DROP POLICY
DROP POLICY
CREATE POLICY
psql:supabase/migrations/20261102_02_checklist_almacen.sql:128: NOTICE:  relation "idx_orden_despiece_entregas_linea" already exists, skipping
CREATE INDEX
psql:supabase/migrations/20261102_02_checklist_almacen.sql:129: NOTICE:  relation "idx_orden_despiece_entregas_ot" already exists, skipping
CREATE INDEX
psql:supabase/migrations/20261102_02_checklist_almacen.sql:130: NOTICE:  relation "idx_orden_despiece_entregas_operario" already exists, skipping
CREATE INDEX
CREATE FUNCTION
DROP TRIGGER
CREATE TRIGGER
CREATE VIEW
CREATE FUNCTION
CREATE FUNCTION
CREATE FUNCTION
CREATE FUNCTION
CREATE FUNCTION
REVOKE
GRANT
REVOKE
GRANT
REVOKE
GRANT
REVOKE
GRANT
REVOKE
GRANT
COMMIT
```

### 2.2. Verificación Estricta (`docs/checklist/verificacion_T3.sql`)

```text
 tiene_lineas | tiene_entregas | tiene_vista | tiene_fn_entrega | tiene_fn_anular | tiene_fn_ajustar | tiene_fn_eliminar | tiene_fn_entregar_fase | tiene_col_ot_en_entregas | tiene_trigger | politicas_no_select | todo_ok 
--------------+----------------+-------------+------------------+-----------------+------------------+-------------------+------------------------+--------------------------+---------------+---------------------+---------
            1 |              1 |           1 |                1 |               1 |                1 |                 1 |                      1 |                        1 |             1 |                   0 | t
(1 fila)
```

### 2.3. Prueba Transaccional Completa (`docs/checklist/prueba_T3.sql`)

```text
BEGIN
psql:docs/checklist/prueba_T3.sql:377: NOTICE:  Prueba transaccional T3 completada exitosamente (0 errores). Ejecutando ROLLBACK.
DO
ROLLBACK
```

---

## 3. Comprobación del Sistema (`npm run verificar -- --limpio`)

```text
> @figma/my-make-file@0.0.1 verificar
> node scripts/verificar.mjs --limpio


== 1. Archivos de parche o temporales nuevos
  OK     Sin parches ni temporales

== 2. Codificación de los archivos modificados
  OK     UTF-8 sin BOM ni mojibake — 103 archivos revisados

== 3. Sintaxis de .ts/.tsx modificados
  OK     Sintaxis válida

== 4. TypeScript (tsc --noEmit)
  OK     tsc: 0 nombres sin definir/duplicados
  OK     tsc: el total de errores no sube — 53 (baseline 55)

== 5. Build de Vite
  OK     npm run build

== 6. Pruebas Deno
  OK     Pruebas Deno — 214 pasan, 0 fallan

== 7. Arranque real del API
  OK     El API arranca — Listening on http://localhost:8000/

== 8. Contexto del Dockerfile.backend
  OK     Contexto del Dockerfile.backend — deno cache index.ts exitoso

== 9. Checkout limpio de HEAD (git archive)
  OK     Pruebas Deno en HEAD limpio — 214 pasan, 0 fallan
  OK     El API arranca en HEAD limpio — Listening on http://localhost:8000/

============================================================
RESULTADO: TODO OK  (11/11 comprobaciones)
```

---

## 4. Suposiciones

1. **Prioridad de vinculación de BOM:** El identificador `item_id` (o `id` del renglón cotizado) es la clave primaria de asociación entre la orden de trabajo y el concepto del BOM presupuestado.
2. **Entrega de fase:** La entrega de fase completa cubre exclusivamente los saldos pendientes de piezas de dicha fase que tengan `cantidad_pendiente > 0`.
3. **Clave de despiece sin fase:** La identidad de una pieza requerida en una orden de trabajo está determinada por el material y el kit (`${material_id}::${kit}`); los cambios de fase no deben duplicar las partidas.

---

## 5. Lo que NO probé

- No probé despliegue en Supabase Cloud / EasyPanel de producción (por regla estricta de no tocar entornos remotos).
- No probé la vista renderizada en un navegador real automatizado con Cypress/Playwright; la funcionalidad fue validada mediante inspección de código, tipos y pruebas unitarias Deno.

---

## 6. No hice (y por qué)

- **No modifiqué las migraciones de T4, T5 ni T6:** Fuera del alcance estricto de la Ronda 3.
- **No permití selección arbitraria de conceptos por índice:** Se implementó el error 409 `bom_ambiguo` para garantizar que nunca se entreguen piezas de otro modelo.

---

## 7. Acciones para Luis

1. Aplicar la migración `supabase/migrations/20261102_02_checklist_almacen.sql` en la base de datos de producción (EasyPanel / Supabase).
2. Ejecutar `docs/checklist/verificacion_T3.sql` en el SQL Editor y confirmar que retorna `todo_ok = true`.
3. Rebuild del backend `remolques-api` y `remolques-web` en EasyPanel.

---

## 8. Git Diff Numstat vs `noche-t2-despiece`

```text
53	0	CHANGELOG_ANTIGRAVITY.md
379	0	docs/checklist/prueba_T3.sql
43	0	docs/checklist/verificacion_T3.sql
1525	0	src/app/components/OrdenesTrabajo/ChecklistDespieceModal.tsx
18	1	src/app/components/OrdenesTrabajo/OrdenesTrabajoList.tsx
241	0	supabase/functions/make-server-feea4382/index.ts
623	0	supabase/functions/make-server-feea4382/motor/checklist_almacen.test.ts
747	0	supabase/functions/make-server-feea4382/motor/checklist_almacen.ts
2	0	supabase/functions/make-server-feea4382/motor/generar_presupuesto_cotizacion.ts
4	0	supabase/functions/make-server-feea4382/motor/presupuesto_desde_costeo.ts
636	0	supabase/migrations/20261102_02_checklist_almacen.sql
```
