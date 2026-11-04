# Reporte Antigravity — T2 Despiece por Fases (Ronda 4)

- **Fecha:** 2026-11-04 (Ronda 4)
- **Rama:** `noche-t2-despiece`
- **Commit de código:** `ec25c46`
- **Base `main`:** `ccff3d5`

---

## 1. Tabla de Hallazgos y Soluciones (Ronda 4)

| # | Severidad | Hallazgo Claude | Solución Implementada | Commit |
|---|---|---|---|---|
| 1 | **ALTA** | Bloque D dependía de 61 UUIDs locales; en producción y Org B 61 líneas quedaban sin fase | Reescrito Bloque D para resolver productos por `nombre` exacto + `organizacion_id` + `tipo_item = 'materia_prima'`. Si hay 0 o >1 matches, se aborta con `RAISE EXCEPTION`. CERO UUIDs de productos en la migración. Probado con Org B con UUIDs aleatorios: 202/202 con fase. | `ec25c46` |
| 2 | **MEDIA** | Se escribía `receta_base.paso` (549 líneas a "Paso N") | Se dejó `receta_base.paso` intacto (NULL o valor legado) en Bloque D, fijando únicamente `fase_id = v_target_fase_id`. Se verificó que la agrupación opera sobre `fase_id`. | `ec25c46` |
| 3 | **MEDIA** | Tabla §7 con Cant "-" en 316/316, 72 fases contradiciendo Proceso, asociaciones dudosas fijas | Cantidad real tomada de `cantidad_raw` del Excel (294 filas con cantidad, 22 con "-" porque no traen en Excel). Fase 100% alineada con columna Proceso (0 discrepancias). Pintura, pijas y piso movidos a Pendientes. El SQL se genera desde las definiciones maestras. | `ec25c46` |
| 4 | **MEDIA** | Diff §4.1/§4.3 con explicaciones inventadas, Atizadores 8 vs 8, Rondana 5/16 4 vs 4, LIJA omitida | Diff calculado por nombre normalizado + `uso`. LIJA #80 documentada (Excel 10 vs BD 2). Atizadores 27 cm (Excel 8 vs BD 8, 0 diff). RONDANA 5/16 (chasis 4 vs 4). Corregido §4.2 ($50 vs $50). Corregido §4.3 (20+ piezas sí existen en Excel). | `ec25c46` |
| 5 | **MEDIA** | Generador no se podía correr desde repo por falta de JSONs | Agregados y versionados en `docs/despiece/`: `productos_existentes_base.json`, `receta_plataforma_40ft.json`, `opcion_componentes_base.json`. Generación 100% determinista con `scripts/generar_archivos_t2_ronda4.py`. | `ec25c46` |
| 6 | BAJA | Fila sin nombre 25.8 de Paso 10 | Identificada como segunda línea de `CABLE NEGRO CAL,12` para uso con laterales/estribo, documentada en §5. | `ec25c46` |
| 7 | BAJA | Fases de opciones gancho/retráctil | Documentada la decisión de mantener fase a nivel grupo en análisis §5. | `ec25c46` |
| 8 | BAJA | Verificación casi_duplicados simétrica | Asegurada comparación canónica sin riesgo de falsos negativos. | `ec25c46` |

---

## 2. Evidencia de Ejecución en Base Desechable (`anty_t2_test` en Postgres 17, puerto 54331)

### 2.1. Migración corrida DOS VECES (Idempotencia estricta)

**Pasada 1:**
```
BEGIN
ALTER TABLE
CREATE TABLE
ALTER TABLE
NOTICE:  policy "fases_despiece_org_select" for relation "fases_despiece" does not exist, skipping
DROP POLICY
NOTICE:  policy "fases_despiece_org_all" for relation "fases_despiece" does not exist, skipping
DROP POLICY
NOTICE:  policy "fases_despiece_org_insert" for relation "fases_despiece" does not exist, skipping
DROP POLICY
NOTICE:  policy "fases_despiece_org_update" for relation "fases_despiece" does not exist, skipping
DROP POLICY
NOTICE:  policy "fases_despiece_org_delete" for relation "fases_despiece" does not exist, skipping
DROP POLICY
CREATE POLICY
CREATE TABLE
ALTER TABLE
NOTICE:  policy "fases_equivalencias_org_select" for relation "fases_despiece_equivalencias" does not exist, skipping
DROP POLICY
NOTICE:  policy "fases_equivalencias_org_all" for relation "fases_despiece_equivalencias" does not exist, skipping
DROP POLICY
NOTICE:  policy "fases_equivalencias_org_insert" for relation "fases_despiece_equivalencias" does not exist, skipping
DROP POLICY
NOTICE:  policy "fases_equivalencias_org_update" for relation "fases_despiece_equivalencias" does not exist, skipping
DROP POLICY
NOTICE:  policy "fases_equivalencias_org_delete" for relation "fases_despiece_equivalencias" does not exist, skipping
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
Exit code: 0

**Pasada 2:**
```
BEGIN
NOTICE:  column "notas" of relation "productos" already exists, skipping
ALTER TABLE
NOTICE:  relation "fases_despiece" already exists, skipping
CREATE TABLE
ALTER TABLE
DROP POLICY
NOTICE:  policy "fases_despiece_org_all" for relation "fases_despiece" does not exist, skipping
DROP POLICY
NOTICE:  policy "fases_despiece_org_insert" for relation "fases_despiece" does not exist, skipping
DROP POLICY
NOTICE:  policy "fases_despiece_org_update" for relation "fases_despiece" does not exist, skipping
DROP POLICY
NOTICE:  policy "fases_despiece_org_delete" for relation "fases_despiece" does not exist, skipping
DROP POLICY
CREATE POLICY
NOTICE:  relation "fases_despiece_equivalencias" already exists, skipping
CREATE TABLE
ALTER TABLE
DROP POLICY
NOTICE:  policy "fases_equivalencias_org_all" for relation "fases_despiece_equivalencias" does not exist, skipping
DROP POLICY
NOTICE:  policy "fases_equivalencias_org_insert" for relation "fases_despiece_equivalencias" does not exist, skipping
DROP POLICY
NOTICE:  policy "fases_equivalencias_org_update" for relation "fases_despiece_equivalencias" does not exist, skipping
DROP POLICY
NOTICE:  policy "fases_equivalencias_org_delete" for relation "fases_despiece_equivalencias" does not exist, skipping
DROP POLICY
CREATE POLICY
GRANT
GRANT
REVOKE
REVOKE
NOTICE:  column "fase_id" of relation "receta_base" already exists, skipping
ALTER TABLE
NOTICE:  column "fase_id" of relation "opcion_componentes" already exists, skipping
ALTER TABLE
DO
COMMIT
```
Exit code: 0 (Idempotente al 100%)

---

### 2.2. Verificación SQL (`docs/despiece/verificacion_T2.sql`)

```
 total_fases | total_equiv | politicas_no_select | rb_40ft_total | rb_40ft_sin_fase | p1_count | p2_count | p3_count | p4_count | p5_count | p6_count | p7_count | p9_count | p10_count | p12_count | extras_count | dolly_gondola_alterados | monroe_sustituto_ok | fleet_amort_sustitutos_ok | fleet_camara_sustitutos_ok | receta_fase_cruzada | opcion_fase_cruzada | casi_duplicados | todo_ok 
-------------+-------------+---------------------+---------------+------------------+----------+----------+----------+----------+----------+----------+----------+----------+-----------+-----------+--------------+-------------------------+---------------------+---------------------------+----------------------------+---------------------+---------------------+-----------------+---------
          14 |          22 |                   0 |           202 |                0 |        3 |        5 |       22 |       22 |       16 |       28 |        4 |       47 |        29 |        16 |           10 |                       0 |                   1 |                         2 |                          2 |                   0 |                   0 |               0 | t
(1 fila)
```
Exit code: 0 (`todo_ok = t`)

---

### 2.3. Prueba Transaccional Multi-Tenant (`docs/despiece/prueba_T2.sql`)

Prueba con segunda organización (Org B) con productos clonados con `gen_random_uuid()::text`, comprobando que la resolución dinámica por nombre no depende de ningún UUID local:
```
BEGIN
INSERT 0 1
INSERT 0 1
INSERT 0 1
INSERT 0 512
DO
DO
NOTICE:  PRUEBA MULTI-ORG RESOLUCION POR NOMBRE: EXITOSA (Org A: 202/202 con fase, Org B: 202/202 con fase)
DO
SET
SET
NOTICE:  PRUEBA RLS USUARIO A (SELECT AISLADO 14 FASES + BLOQUEO INSERT): EXITOSA
DO
SET
NOTICE:  PRUEBA RLS USUARIO B (AISLAMIENTO TOTAL RESPECTO A ORG A): EXITOSA
DO
RESET
ROLLBACK
```
Exit code: 0 (Org A y Org B con 202/202 líneas con fase, 0 sin fase; RLS verificado con `SET LOCAL ROLE authenticated` y `SET LOCAL request.jwt.claim.sub`; ROLLBACK limpio).

---

### 2.4. Resumen de Generación Tabla 316 (`ANALISIS_UNION_LISTADOS.md`)
```
Resumen de Tabla 316:
  Filas con Cant '-': 22 (exactamente las 22 que no traen cantidad en Excel)
  Filas con fase != Proceso: 0 (100% coincidencia)
```

---

## 3. Comprobación `npm run verificar -- --limpio`

```
> @figma/my-make-file@0.0.1 verificar
> node scripts/verificar.mjs --limpio

== 1. Archivos de parche o temporales nuevos
  OK     Sin parches ni temporales

== 2. Codificación de los archivos modificados
  OK     UTF-8 sin BOM ni mojibake — 95 archivos revisados

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

## 4. Lo que NO probé y No hice (y por qué)

1. **No toqué Supabase Cloud**: Todas las pruebas se realizaron exclusivamente en PostgreSQL 17 local (puerto 54331, base desechable `anty_t2_test` eliminada al terminar).
2. **No toqué Dolly ni Góndola**: Por regla de alcance estricto, la asignación de fases se limita exclusivamente a modelos `tipo = 'plataforma'`. Dolly (33 líneas) y Góndola (98 líneas) permanecen intactas.
3. **No se alteró `receta_base.paso`**: Siguiendo el requerimiento del prompt y de la revisión, `paso` se mantuvo intacto para no alterar textos legados ni forzar conversiones artificiales.
4. **No se vio la UI renderizada**: T2 es un cambio de base de datos/migraciones y análisis de despiece; no incluye cambios en componentes visuales del frontend.

---

## 5. Acciones Manuales para Luis

1. **Ejecutar migración en SQL Editor de Supabase**:
   - Archivo: `supabase/migrations/20261102_01_despiece_union.sql`
2. **Ejecutar verificación post-migración**:
   - Archivo: `docs/despiece/verificacion_T2.sql`
   - Confirmar que retorna `todo_ok = true` con 202 líneas en plataforma 40 ft y 0 líneas sin fase.
3. **Sin Rebuild de backend por T2**: T2 no modifica endpoints ni archivos de Deno.

---

## 6. Git Diff Numstat contra `main`

```
90	0	CHANGELOG_ANTIGRAVITY.md
16	0	COORDINACION/COLA.md
44	0	COORDINACION/ESTADO.md
226	0	COORDINACION/REPORTES/T2_REPORTE_ANTY_R3.md
466	0	docs/despiece/ANALISIS_UNION_LISTADOS.md
181	0	docs/despiece/opcion_componentes_base.json
512	0	docs/despiece/productos_existentes_base.json
308	0	docs/despiece/prueba_T2.sql
202	0	docs/despiece/receta_plataforma_40ft.json
4110	0	docs/despiece/union_listados_raw.json
156	0	docs/despiece/verificacion_T2.sql
269	0	scripts/analizar_union.py
1114	0	scripts/generar_archivos_t2_ronda3.py
1202	0	scripts/generar_archivos_t2_ronda4.py
891	0	scripts/generar_migracion_despiece.py
99	0	src/app/utils/fasesDespiece.test.ts
153	0	src/app/utils/fasesDespiece.ts
698	0	supabase/migrations/20261102_01_despiece_union.sql
```
