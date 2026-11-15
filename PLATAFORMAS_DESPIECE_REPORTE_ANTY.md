# Reporte de Ejecución — Plataformas: Completar el Despiece (Corrección Ronda 2)

**Fecha:** 2026-11-14  
**Responsable:** Antigravity (para revisión de Claude y Luis)  
**Rama:** `despiece-plataformas-2026-11-14` (worktree `..\Remolques_despiece_plat`)  
**Base:** `main` (commit `344632f`)  
**Reglas duras cumplidas:** Cero push a remoto, cero merge a `main`, sin tocar EasyPanel ni Supabase producción; cero cambios en costos o precios; migración idempotente de dos pasadas con `ON_ERROR_STOP=1`; sin UUID de organización fijo en código; commits nuevos sobre la rama sin reescribir historia.

---

## 1. Resumen Ejecutivo de la Corrección (Ronda 2)

En respuesta a la revisión `COORDINACION/REVISIONES/PLATAFORMAS_DESPIECE_REVISION_CLAUDE.md`, se aplicaron dos correcciones críticas sobre la migración y la consulta de verificación:

1. **Corrección 1 — Fases y Pasos Explícitos en Componentes de Opciones y Receta Base:**
   - Se asignaron valores explícitos de `paso` y `fase_id` en `opcion_componentes`:
     - **Pisos (18 componentes en 9 opciones):** `paso = 'PASO 11'`, `fase_id` apuntando a `paso_11`.
     - **Caja auxiliar (4 componentes) y Bicicletera (2 componentes):** `paso = 'EXTRAS'`, `fase_id` apuntando a `extras`.
     - **Con riel (1 componente):** `paso = 'TERMINADO'`, `fase_id` apuntando a `paso_12`.
     - **Fleet Master (1 componente tapón):** `paso = 'AIRE'`, `fase_id` apuntando a `paso_9`.
   - Se asignaron en `receta_base` para la Placa de logo (10 modelos): `paso = 'TERMINADO'`, `fase_id` apuntando a `paso_12`.
   - La asignación de `fase_id` está completamente protegida con `IF to_regclass('public.fases_despiece') IS NOT NULL THEN` y consultas dinámicas `EXECUTE`, garantizando compatibilidad si la tabla de fases aún no existiera en alguna base.

2. **Corrección 2 — Material Fiel para Placa de Logo:**
   - Se dio de alta el material `TORNILLO CABEZA DE COCHE 1/4 X 3` (`PZA`, costo $0.00, precio $0.00) conforme al requerimiento original del Excel.
   - El catálogo de productos sube de 512 a **518** (+6 materiales nuevos en total).
   - En la receta base de las 10 plataformas se limpió el material provisional `1/4 X 1 1/2` y se insertó `TORNILLO CABEZA DE COCHE 1/4 X 3` (x4, uso `Placa de logo`, paso `TERMINADO`, seccion `NULL`).

| Rubro | Baseline (`remolques_rev_t3`) | Pasada 1 | Pasada 2 (Idempotente) | Delta Total | Estado |
|---|---:|---:|---:|---:|---|
| **Catálogo de Materiales (`productos`)** | 512 | 518 | 518 | **+6** | 6 creados con costo $0.00 |
| **Líneas de Receta Base (`receta_base`)** | 2,090 | 2,100 | 2,100 | **+10** | 10 plataformas con 1/4x3 (Placa de logo) |
| **Componentes de Opciones (`opcion_componentes`)** | 181 | 207 | 207 | **+26** | Con `paso` y `fase_id` completos |
| **Suite de Pruebas Deno** | 334 | 334 | 334 | 0 | 334 pasan, 0 fallan ($\ge 289$) |
| **Verificación General (`verificar.mjs --limpio`)** | 11/11 | 11/11 | 11/11 | 0 | 11/11 OK en HEAD limpio |
| **Consulta SQL (`verificacion_despiece_plat.sql`)** | N/A | 1 fila | 1 fila | `todo_ok = true` | 10 comprobaciones atómicas en verde |
| **Precios 2R-1d (40/3, 42/3, 45/3, 48/3)** | Idénticos | Idénticos | Idénticos | **$0.00** | Cero variación en precio y costo |

---

## 2. Detalle de Materiales y Recetas Modificadas

### 2.1 Alta de Materiales (6 productos nuevos en `productos`)
Todos con `costo = 0.00` y `precio_unitario = 0.00`:
1. `TORNILLO GALVANIZADO 1/2 X 1 1/2 GRADO 5` (PZA) — Bicicletero y Riel.
2. `BISAGRA 5/8` (PZA) — Caja auxiliar.
3. `CADENA 3/16` (M) — Caja auxiliar (0.30 m).
4. `PIJA 5/16 X 2` (PZA) — Pisos (450 pzas).
5. `PIJA 5/16 X 2 1/2` (PZA) — Pisos (150 pzas).
6. `TORNILLO CABEZA DE COCHE 1/4 X 3` (PZA) — Placa de logo (4 pzas).

### 2.2 Receta Base (10 modelos de plataforma)
- Material: `TORNILLO CABEZA DE COCHE 1/4 X 3`
- Cantidad: 4 pzas
- Uso: `Placa de logo`
- Paso: `TERMINADO`
- Fase: `paso_12` (condicional si existe `fases_despiece`)
- Sección: `NULL` (sin impacto en costos ni precios)

### 2.3 Componentes de Opciones (26 componentes con paso y fase definidos)
1. **Adicionales / Caja auxiliar (`caja_auxiliar`):**
   - `BISAGRA 5/8`: cant 2, paso `EXTRAS`, fase `extras`.
   - `CADENA 3/16`: cant 0.3, paso `EXTRAS`, fase `extras`.
   - `TORNILLO ALLEN 1/2 X 1 1/2`: cant 2, paso `EXTRAS`, fase `extras`.
   - `TUERCA ESTANDAR 1/2 GRADO 5`: cant 2, paso `EXTRAS`, fase `extras`.
2. **Adicionales / Bicicletera (`bicicletera`):**
   - `TORNILLO GALVANIZADO 1/2 X 1 1/2 GRADO 5`: cant 2, paso `EXTRAS`, fase `extras`.
   - `TUERCA ESTANDAR 1/2 GRADO 5`: cant 2, paso `EXTRAS`, fase `extras`.
3. **Riel / Con riel (`con_riel`):**
   - `TORNILLO GALVANIZADO 1/2 X 1 1/2 GRADO 5`: cant 2, paso `TERMINADO`, fase `paso_12`.
   - *Nota de conflicto asentada:* "Conflicto: manual dice tornillo 1/2 X 1 3/4; lista dice 1/2 X 1 1/2 Grado 5".
4. **Pisos (9 opciones, excluyendo `sin_piso` — 18 componentes):**
   - Opciones: `antiderrapante`, `encino`, `encino_centro_plastico_lados`, `laminado`, `laminado_madera`, `laminado_plastico`, `pino`, `plastico_cafe`, `plastico_negro`.
   - `PIJA 5/16 X 2`: cant 450, paso `PASO 11`, fase `paso_11`.
   - `PIJA 5/16 X 2 1/2`: cant 150, paso `PASO 11`, fase `paso_11`.
5. **Suspensión / Fleet Master (`fleet_master`):**
   - `TAPON 1/4 SUSPENSION FM + 4`: cant 3, paso `AIRE`, fase `paso_9`.

---

## 3. Prueba de Clasificación en Checklist de Almacén (`checklist_almacen.ts`)

Se ejecutó la simulación de la lógica real de `checklist_almacen.ts` (líneas 363–387) sobre una plataforma configurada con:
- Piso: `plastico_negro`
- Adicionales: `caja_auxiliar`
- Receta Base: `Placa de logo`

### Salida real del clasificador:
```text
=== SIMULACION DE CHECKLIST DE ALMACEN (checklist_almacen.ts) ===
Conectado a base local con esquema completo de fases

Evaluando 7 items de la orden (Piso Plástico Negro, Caja Auxiliar, Placa de Logo)...

=== DISTRIBUCION POR FASE DE ENTREGA EN ALMACEN ===

Fase: [EXTRAS]
  - BISAGRA 5/8: 2 (paso: "EXTRAS", fase_id: 4bb475de-e06d-4f83-8c93-471f0f026560)
  - CADENA 3/16: 0.3 (paso: "EXTRAS", fase_id: 4bb475de-e06d-4f83-8c93-471f0f026560)
  - TORNILLO ALLEN 1/2 X 1 1/2: 2 (paso: "EXTRAS", fase_id: 4bb475de-e06d-4f83-8c93-471f0f026560)
  - TUERCA ESTANDAR 1/2 GRADO 5: 2 (paso: "EXTRAS", fase_id: 4bb475de-e06d-4f83-8c93-471f0f026560)
  Total piezas en fase: 6.3

Fase: [PASO_11]
  - PIJA 5/16 X 2 1/2: 150 (paso: "PASO 11", fase_id: 3d77fd1d-d74e-40d9-b603-a276abb75748)
  - PIJA 5/16 X 2: 450 (paso: "PASO 11", fase_id: 3d77fd1d-d74e-40d9-b603-a276abb75748)
  Total piezas en fase: 600

Fase: [PASO_12]
  - TORNILLO CABEZA DE COCHE 1/4 X 3: 4 (paso: "TERMINADO", fase_id: fa82741a-a1e2-4150-84fa-fd284b54d29c)
  Total piezas en fase: 4

================ METRICAS DEL CHECKLIST ================
Pijas en Paso 11 (esperado 600): 600 -> OK
Partidas de Caja Auxiliar en Extras (esperado 4): 4 -> OK
conteoSinFase (esperado 0): 0 -> OK

RESULTADO GENERAL: APROBADO (todo_ok = true)
```

**Resultado:**
- Las 600 pijas caen exactamente en la fase `paso_11` (Paso 11).
- Las 4 partidas de la caja auxiliar caen exactamente en la fase `extras` (Extras).
- `conteoSinFase` es estrictamente **0** (ninguna partida cae en fallback a Paso 1).

---

## 4. Script de Verificación SQL (`verificacion_despiece_plat.sql`)

El verificador `docs/importacion/verificacion_despiece_plat.sql` incluye ahora la comprobación `fases_ok` condicional a la existencia de la tabla `fases_despiece`:

```sql
 materiales_6_ok | receta_base_placa_logo_10_ok | caja_auxiliar_4_ok | bicicletera_2_ok | con_riel_1_ok | pisos_18_ok | sin_piso_0_ok | fleet_master_tapon_ok | acero_plataformas_intacto | fases_ok | todo_ok 
-----------------+------------------------------+--------------------+------------------+---------------+-------------+---------------+-----------------------+---------------------------+----------+---------
 t               | t                            | t                  | t                | t             | t           | t             | t                     | t                         | t        | t
(1 fila)
```

### Comprobaciones del Verificador:
1. `materiales_6_ok`: 6 materiales nuevos con costo 0.00 y unidades correctas.
2. `receta_base_placa_logo_10_ok`: Exactamente 10 plataformas tienen `TORNILLO CABEZA DE COCHE 1/4 X 3` (x4, uso `Placa de logo`, paso `TERMINADO`, `seccion IS NULL`).
3. `caja_auxiliar_4_ok`: 4 componentes con paso `EXTRAS` y `seccion IS NULL`.
4. `bicicletera_2_ok`: 2 componentes con paso `EXTRAS` y `seccion IS NULL`.
5. `con_riel_1_ok`: 1 componente con paso `TERMINADO` y `seccion IS NULL`.
6. `pisos_18_ok`: 18 componentes (9 opciones x 2 pijas) con paso `PASO 11` y `seccion IS NULL`.
7. `sin_piso_0_ok`: 0 componentes en opción `sin_piso`.
8. `fleet_master_tapon_ok`: Tapón 1/4 en paso `AIRE` (total 13 componentes en opción).
9. `acero_plataformas_intacto`: Las 61 líneas de acero en los 9 modelos con costos se mantienen idénticas.
10. `fases_ok`:
    - Si `fases_despiece` no existe en la base, devuelve `true` sin fallar.
    - Si `fases_despiece` existe: verifica que ninguna fila nueva tiene `fase_id IS NULL`, pisos apuntan a `paso_11`, adicionales a `extras`, y placa de logo/riel a `paso_12`.
11. `todo_ok`: Conjunción de las 10 comprobaciones anteriores.

---

## 5. Tabla de Sanidad de Precios (Regresión 2R-1d)

Configuración tipo dorada:
- Plataforma 3 ejes, patín HJ, ejes y suspensión Fleet Master, kit de aire/ABS 3e_2_retractil, piso plástico laminado, ganancia $110,000.00.

| Plataforma | Costo Total | Ganancia | Precio Sugerido | Precio Esperado Tabla 2R-1d | Variación |
|---|---:|---:|---:|---:|---:|
| **40 FT / 3 EJES** | $449,237.23 | $110,000.00 | **$559,237.23** | $559,237.23 | **$0.00** |
| **42 FT / 3 EJES** | $452,993.87 | $110,000.00 | **$562,993.87** | $562,993.87 | **$0.00** |
| **45 FT / 3 EJES** | $458,628.83 | $110,000.00 | **$568,628.83** | $568,628.83 | **$0.00** |
| **48 FT / 3 EJES** | $464,263.79 | $110,000.00 | **$574,263.79** | $574,263.79 | **$0.00** |

---

## 6. Verificación General del Repositorio (`scripts/verificar.mjs --limpio`)

```text
== 1. Archivos de parche o temporales nuevos
  OK     Sin parches ni temporales

== 2. Codificación de los archivos modificados
  OK     UTF-8 sin BOM ni mojibake — 13 archivos revisados

== 3. Sintaxis de .ts/.tsx modificados
  OK     Sintaxis válida

== 4. TypeScript (tsc --noEmit)
  OK     tsc: 0 nombres sin definir/duplicados
  OK     tsc: el total de errores no sube — 41 (baseline 55)

== 5. Build de Vite
  OK     npm run build

== 6. Pruebas Deno
  OK     Pruebas Deno — 334 pasan, 0 fallan

== 7. Arranque real del API
  OK     El API arranca — Listening on http://localhost:8000/

== 8. Contexto del Dockerfile.backend
  OK     Contexto del Dockerfile.backend — deno cache index.ts exitoso

== 9. Checkout limpio de HEAD (git archive)
  OK     Pruebas Deno en HEAD limpio — 334 pasan, 0 fallan
  OK     El API arranca en HEAD limpio — Listening on http://localhost:8000/

============================================================
RESULTADO: TODO OK  (11/11 comprobaciones)
```

---

## 7. Instrucciones para Despliegue en Producción (Luis)

1. **Abrir SQL Editor de Supabase en producción.**
2. **Copiar y ejecutar:** [20261114_01_plataformas_despiece.sql](file:///c:/Users/luisa/Downloads/proyectos_antygravity/Remolques_despiece_plat/COORDINACION/SQL_PARA_LUIS/20261114_01_plataformas_despiece.sql).
3. **Ejecutar consulta de verificación:** [verificacion_despiece_plat.sql](file:///c:/Users/luisa/Downloads/proyectos_antygravity/Remolques_despiece_plat/COORDINACION/SQL_PARA_LUIS/verificacion_despiece_plat.sql).
   - Confirmar que arroje una sola fila con `todo_ok = true`.
4. **Rebuild en EasyPanel:** **NO REQUERIDO.** El cambio es 100% de base de datos.
