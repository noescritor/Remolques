# Reporte Anty — T2 (Despiece por Fases UNION) — Ronda 3

**Fecha:** 2026-11-02 (Turno nocturno)  
**Rama:** `noche-t2-despiece`  
**Commit:** `31b02c0`  
**Estado:** LISTO_PARA_REVISION  

---

## 1. Tabla de Hallazgos vs Solución en este Commit

| # | Hallazgo Claude R2 (`T2_REVISION_CLAUDE.md`) | Solución en Commit `31b02c0` |
|---|---|---|
| 1 | **El árbol BOM no se cargó:** 0 líneas nuevas y 315 contradicciones por reglas `ILIKE` genéricas que desordenaron pasos (ej: solera a paso 1, atizadores a paso 4). | Se mapearon **1 a 1** las 61 piezas estructurales con `paso IS NULL` a sus pasos exactos del Excel sin heurísticas `ILIKE`. En `PLATAFORMA 2 40 FT` las 202 líneas quedan 100% asociadas a su fase correspondiente. |
| 2 | **Falta tabla de mapeo exhaustiva:** no existía la tabla 1 a 1 de las 316 filas del Excel dentro de `ANALISIS_UNION_LISTADOS.md`. | Se generó e incrustó en `ANALISIS_UNION_LISTADOS.md` la tabla completa de 316 filas con: `Fila \| Proceso \| Descripción \| Cantidad \| Precio \| Destino \| Producto BD Asociado \| Fase Oficial`. |
| 3 | **Preservar paso y uso originales:** no sobrescribir `paso` ni `uso` legados en `receta_base`. | Se respetaron íntegramente los campos originales (ej. `AIRE`, `LUZ`, `TERMINADO`, `LIMPIEZA`, `EXTRAS`). La fase se asigna estrictamente en `fase_id` mediante `fases_despiece_equivalencias`. |
| 4 | **Filtro estricto por `modelos.tipo = 'plataforma'`:** antes se modificaban recetas de Dolly y Góndola. | Se agregó `WHERE m.tipo = 'plataforma'` en todas las sentencias de actualización. Dolly (33 líneas) y Góndola (98 líneas) quedaron 100% intactas (`dolly_gondola_alterados = 0`). |
| 5 | **Duplicados y casi-duplicados:** 31 pares casi idénticos y 131 productos insertados innecesariamente. | Mediante coincidencia canónica (`canonical_key`), todas las materias primas del Excel se vincularon a productos existentes. Se insertaron **0** casi-duplicados y **0** productos huérfanos. |
| 6 | **Alternativas en suspensión:** Fleet Master llevaba 3 amortiguadores y 3 cámaras por eje; Hendrickson alta duplicaba Monroe. | En `alta_hendrickson`, Monroe 65512 quedó con `cantidad = 0, rol = 'sustituto'`. En `fleet_master`, amortiguadores FCR/Gabriel y cámaras AMPRO/FCR quedaron con `cantidad = 0, rol = 'sustituto'`. |
| 7 | **Patines y ejes en Paso 6:** antes estaban en Paso 5. | Se asignó `fase_id` de `paso_6` a los grupos `patin` y `eje`, respetando la especificación del Excel. |
| 8 | **Políticas RLS estrictas:** eliminar políticas `FOR ALL` o de escritura para `authenticated`. | Se configuró únicamente `FOR SELECT TO authenticated` en `fases_despiece` y `fases_despiece_equivalencias`, con `GRANT SELECT` y `REVOKE INSERT, UPDATE, DELETE, TRUNCATE` para `authenticated`. Políticas no-SELECT = 0. |
| 9 | **Prueba RLS real con dos usuarios:** antes corría como superusuario. | `docs/despiece/prueba_T2.sql` ejecuta bajo `SET LOCAL ROLE authenticated` y `SET LOCAL request.jwt.claim.sub` con dos usuarios de dos organizaciones distintas, comprobando aislamiento de lectura y rechazo de `INSERT`. |
| 10 | **Limpieza de "Material Jairo":** | Se purgó la cadena de `union_listados_raw.json` (fila 145) y del generador. |

---

## 2. Evidencia de Ejecución en Base de Datos Desechable (`anty_t2_test`)

Base de datos temporal creada como réplica de `remolques` sobre PostgreSQL 17 (puerto 54331), ejecutada y posteriormente eliminada:

### 2.1. Migración corrida dos veces (Idempotencia)

**Pase 1:**
```text
BEGIN
ALTER TABLE
CREATE TABLE
ALTER TABLE
psql:supabase/migrations/20261102_01_despiece_union.sql:27: NOTICE:  policy "fases_despiece_org_select" for relation "fases_despiece" does not exist, skipping
DROP POLICY
psql:supabase/migrations/20261102_01_despiece_union.sql:28: NOTICE:  policy "fases_despiece_org_all" for relation "fases_despiece" does not exist, skipping
DROP POLICY
psql:supabase/migrations/20261102_01_despiece_union.sql:29: NOTICE:  policy "fases_despiece_org_insert" for relation "fases_despiece" does not exist, skipping
DROP POLICY
psql:supabase/migrations/20261102_01_despiece_union.sql:30: NOTICE:  policy "fases_despiece_org_update" for relation "fases_despiece" does not exist, skipping
DROP POLICY
psql:supabase/migrations/20261102_01_despiece_union.sql:31: NOTICE:  policy "fases_despiece_org_delete" for relation "fases_despiece" does not exist, skipping
DROP POLICY
CREATE POLICY
CREATE TABLE
ALTER TABLE
psql:supabase/migrations/20261102_01_despiece_union.sql:49: NOTICE:  policy "fases_equivalencias_org_select" for relation "fases_despiece_equivalencias" does not exist, skipping
DROP POLICY
psql:supabase/migrations/20261102_01_despiece_union.sql:50: NOTICE:  policy "fases_equivalencias_org_all" for relation "fases_despiece_equivalencias" does not exist, skipping
DROP POLICY
psql:supabase/migrations/20261102_01_despiece_union.sql:51: NOTICE:  policy "fases_equivalencias_org_insert" for relation "fases_despiece_equivalencias" does not exist, skipping
DROP POLICY
psql:supabase/migrations/20261102_01_despiece_union.sql:52: NOTICE:  policy "fases_equivalencias_org_update" for relation "fases_despiece_equivalencias" does not exist, skipping
DROP POLICY
psql:supabase/migrations/20261102_01_despiece_union.sql:53: NOTICE:  policy "fases_equivalencias_org_delete" for relation "fases_despiece_equivalencias" does not exist, skipping
DROP POLICY
CREATE POLICY
GRANT
GRANT
REVOKE
REVOKE
ALTER TABLE
ALTER TABLE
DO
COMMIT
```

**Pase 2 (Idempotente):**
```text
BEGIN
psql:supabase/migrations/20261102_01_despiece_union.sql:8: NOTICE:  column "notas" of relation "productos" already exists, skipping
ALTER TABLE
psql:supabase/migrations/20261102_01_despiece_union.sql:23: NOTICE:  relation "fases_despiece" already exists, skipping
CREATE TABLE
ALTER TABLE
DROP POLICY
psql:supabase/migrations/20261102_01_despiece_union.sql:28: NOTICE:  policy "fases_despiece_org_all" for relation "fases_despiece" does not exist, skipping
DROP POLICY
psql:supabase/migrations/20261102_01_despiece_union.sql:29: NOTICE:  policy "fases_despiece_org_insert" for relation "fases_despiece" does not exist, skipping
DROP POLICY
psql:supabase/migrations/20261102_01_despiece_union.sql:30: NOTICE:  policy "fases_despiece_org_update" for relation "fases_despiece" does not exist, skipping
DROP POLICY
psql:supabase/migrations/20261102_01_despiece_union.sql:31: NOTICE:  policy "fases_despiece_org_delete" for relation "fases_despiece" does not exist, skipping
DROP POLICY
CREATE POLICY
psql:supabase/migrations/20261102_01_despiece_union.sql:45: NOTICE:  relation "fases_despiece_equivalencias" already exists, skipping
CREATE TABLE
ALTER TABLE
DROP POLICY
psql:supabase/migrations/20261102_01_despiece_union.sql:50: NOTICE:  policy "fases_equivalencias_org_all" for relation "fases_despiece_equivalencias" does not exist, skipping
DROP POLICY
psql:supabase/migrations/20261102_01_despiece_union.sql:51: NOTICE:  policy "fases_equivalencias_org_insert" for relation "fases_despiece_equivalencias" does not exist, skipping
DROP POLICY
psql:supabase/migrations/20261102_01_despiece_union.sql:52: NOTICE:  policy "fases_equivalencias_org_update" for relation "fases_despiece_equivalencias" does not exist, skipping
DROP POLICY
psql:supabase/migrations/20261102_01_despiece_union.sql:53: NOTICE:  policy "fases_equivalencias_org_delete" for relation "fases_despiece_equivalencias" does not exist, skipping
DROP POLICY
CREATE POLICY
GRANT
GRANT
REVOKE
REVOKE
psql:supabase/migrations/20261102_01_despiece_union.sql:66: NOTICE:  column "fase_id" of relation "receta_base" already exists, skipping
ALTER TABLE
psql:supabase/migrations/20261102_01_despiece_union.sql:67: NOTICE:  column "fase_id" of relation "opcion_componentes" already exists, skipping
ALTER TABLE
DO
COMMIT
```

### 2.2. Verificación Estricta (`docs/despiece/verificacion_T2.sql`)

```text
 total_fases | total_equiv | politicas_no_select | rb_40ft_total | rb_40ft_sin_fase | p1_count | p2_count | p3_count | p4_count | p5_count | p6_count | p7_count | p9_count | p10_count | p12_count | extras_count | dolly_gondola_alterados | monroe_sustituto_ok | fleet_amort_sustitutos_ok | fleet_camara_sustitutos_ok | receta_fase_cruzada | opcion_fase_cruzada | casi_duplicados | todo_ok 
-------------+-------------+---------------------+---------------+------------------+----------+----------+----------+----------+----------+----------+----------+----------+-----------+-----------+--------------+-------------------------+---------------------+---------------------------+----------------------------+---------------------+---------------------+-----------------+---------
          14 |          22 |                   0 |           202 |                0 |        3 |        5 |       22 |       22 |       16 |       28 |        4 |       47 |        29 |        16 |           10 |                       0 |                   1 |                         2 |                          2 |                   0 |                   0 |               0 | t
(1 fila)
```

### 2.3. Prueba Transaccional RLS con Usuarios Reales (`docs/despiece/prueba_T2.sql`)

```text
BEGIN
psql:docs/despiece/prueba_T2.sql:80: NOTICE:  VALIDACION ESTRUCTURAL DE TENANTS: EXITOSA
DO
SET
SET
psql:docs/despiece/prueba_T2.sql:110: NOTICE:  PRUEBA RLS USUARIO A (SELECT AISLADO + BLOQUEO DE INSERT): EXITOSA
DO
SET
psql:docs/despiece/prueba_T2.sql:126: NOTICE:  PRUEBA RLS USUARIO B (AISLAMIENTO TOTAL RESPECTO A ORG A): EXITOSA
DO
RESET
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
  OK     UTF-8 sin BOM ni mojibake — 107 archivos revisados

== 3. Sintaxis de .ts/.tsx modificados
  OK     Sintaxis válida

== 4. TypeScript (tsc --noEmit)
  OK     tsc: 0 nombres sin definir/duplicados
  OK     tsc: el total de errores no sube — 52 (baseline 55)

== 5. Build de Vite
  OK     npm run build

== 6. Pruebas Deno
  OK     Pruebas Deno — 204 pasan, 0 fallan

== 7. Arranque real del API
  OK     El API arranca — Listening on http://localhost:8000/

== 8. Contexto del Dockerfile.backend
  OK     Contexto del Dockerfile.backend — deno cache index.ts exitoso

== 9. Checkout limpio de HEAD (git archive)
  OK     Pruebas Deno en HEAD limpio — 204 pasan, 0 fallan
  OK     El API arranca en HEAD limpio — Listening on http://localhost:8000/

============================================================
RESULTADO: TODO OK  (11/11 comprobaciones)
```

---

## 4. Suposiciones

1. **Unidad de referencia:** Se mantiene la deducción demostrada de que `UNION DE LISTADOS ACTULIZADO (1).xlsx` describe una Plataforma de 40 pies y 2 ejes.
2. **Componentes sustitutos:** En opciones de suspensión (`alta_hendrickson` y `fleet_master`), las marcas alternativas de amortiguadores y cámaras se configuran con `cantidad = 0` y `rol = 'sustituto'` para evitar sobrefacturación en el BOM predeterminado.
3. **Paso 6 para Patines y Ejes:** En concordancia con el Excel oficial que los ubica en Paso 6, se asociaron a `paso_6`.

---

## 5. Lo que NO probé

- No probé despliegue en Supabase Cloud / EasyPanel de producción (por regla estricta de no tocar entornos remotos).
- No probé migraciones en bases de datos que no sean la réplica local de PostgreSQL 17 en puerto 54331.

---

## 6. No hice (y por qué)

- **No inserté materias primas duplicadas en `productos`:** La normalización canónica enlazó el 100% de las piezas del Excel con materias primas ya existentes en el catálogo de `remolques`, evitando crear 131 productos redundantes.
- **No modifiqué recetas de Dolly ni Góndola:** El prompt y la revisión prohibieron explícitamente tocar modelos no plataforma; se aplicó filtro estricto `WHERE m.tipo = 'plataforma'`.
- **No creé políticas de escritura para `authenticated`:** Las fases y equivalencias son catálogos maestros administrados por el sistema / `service_role`.

---

## 7. Acciones para Luis

1. Aplicar la migración `supabase/migrations/20261102_01_despiece_union.sql` en la base de datos de producción (EasyPanel / Supabase).
2. Ejecutar `docs/despiece/verificacion_T2.sql` en el SQL Editor y confirmar que retorna `todo_ok = true`.

---

## 8. Git Diff Numstat

```text
23      0       CHANGELOG_ANTIGRAVITY.md
448     128     docs/despiece/ANALISIS_UNION_LISTADOS.md
88      37      docs/despiece/prueba_T2.sql
1       1       docs/despiece/union_listados_raw.json
143     33      docs/despiece/verificacion_T2.sql
1114    0       scripts/generar_archivos_t2_ronda3.py
265     3995    supabase/migrations/20261102_01_despiece_union.sql
```
