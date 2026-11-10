# Reporte Técnico: Plataforma 3 Ejes 43 ft (Derivada de 40/2) y Avisos de Costeo Incompleto

**Fecha:** 2026-11-09  
**Autor:** Antigravity  
**Revisor:** Claude  
**Rama:** `plataforma-43ft-2026-11-09`  
**Base:** `407468d` (main)  
**Estado:** Completado, verificado en base local desechable Postgres 17 y suite Deno (295/295 passed, 11/11 checks de sanidad OK).

---

## 1. Resumen Ejecutivo

1. **Problema Reportado por Luis:** Al cotizar una `PLATAFORMA 3 43 FT`, el precio salía en `$0.00` sin advertencia alguna.
2. **Causa Raíz:** Era el único modelo de plataforma sin despiece de acero (`receta_base`), costos fijos (`costos_modelo`) ni mano de obra (`procesos_manufactura`). El motor de costeo marcaba la cotización con confianza `incompleta` y `precio_sugerido = null`. El cliente web convertía ese `null` en `$0.00` de forma silenciosa.
3. **Solución Implementada:**
   - **Costos Derivados:** Se derivaron los costos de `PLATAFORMA 3 43 FT` a partir de la base dorada `PLATAFORMA 2 40 FT` (mismo método del Sub-bloque 2R-1d). Se calcularon **41 cargadores de 4"** por interpolación lineal estricta de la serie Leolca (`largo_ft - 2`).
   - **Migración SQL Multi-Tenant Idempotente:** `supabase/migrations/20261109_01_costos_plataforma_43ft.sql` (61 renglones de acero, 12 de kits fijos por $45,685.98, 80 de manufactura por $22,930.00 y registro de procedencia `costos_derivados_de`).
   - **Mensaje Explicativo en Configurador (`ConfiguradorEquipo.tsx`):** Cuando un modelo tiene costeo incompleto, se sustituye el texto genérico `"Sin costeo para este modelo"` por un desglose detallado de lo que falta (`"Sin precio sugerido: faltan acero, kits y mano de obra de este modelo"` o las secciones que apliquen).
   - **Aviso Visible en Cotizador (`CotizacionEditor.tsx`):** Cuando un concepto configurado tiene precio unitario `$0.00` debido a costeo incompleto, se despliega un aviso visible (`"Sin precio: costeo incompleto. Captura el precio a mano."`) tanto en la tarjeta de concepto como junto al campo de captura de precio, sin bloquear el guardado de la cotización.
   - **Pruebas Automatizadas:** 6 nuevas pruebas Deno (1 de sanidad matemática y monotonía en el motor + 5 de la función pura de mensajes UI). Total de pruebas del proyecto: **295 passed | 0 failed** (baseline: 289).

---

## 2. Comparativa de Sanidad y Monotonía de Precios

Configuración estándar de prueba (3 ejes, suspensión y ejes Fleet Master, patín HJ, piso laminado plástico con escala `por_largo`, ABS 3 ejes con 2 retráctiles, y ajustes dorados del Excel):

| Concepto | 42 ft / 3 ejes (40 cargadores) | 43 ft / 3 ejes (41 cargadores) | 45 ft / 3 ejes (43 cargadores) | Monotonía / Relación |
| :--- | :---: | :---: | :---: | :---: |
| **Cargadores IPR 4"** | 40 pz | **41 pz** | 43 pz | +1 pz vs 42 ft / -2 pz vs 45 ft |
| **Acero (`receta_base`)** | $129,365.33 | **$129,942.15** | $131,095.79 | Crecimiento exacto: +$576.82 por cargador |
| **Kits Fijos (`costos_modelo`)** | $45,685.98 | **$45,685.98** | $45,685.98 | Idénticos (fijos por modelo) |
| **Mano de Obra (`procesos`)** | $22,930.00 | **$22,930.00** | $22,930.00 | Idénticos (80 procesos estándar) |
| **Piso Plástico (`por_largo`)** | $54,663.00 (42/40) | **$55,964.50** (43/40) | $58,567.50 (45/40) | Lineal exacto sobre $52,060.00 |
| **Opciones Totales** | $199,444.56 | **$200,746.06** | $203,349.06 | Monótonamente creciente |
| **Ajustes Manuales** | $31,485.00 | **$31,485.00** | $31,485.00 | Constante de calibración Excel |
| **Costo Total** | $452,993.87 | **$454,872.19** | $458,628.83 | $452.9k < **$454.8k** < $458.6k |
| **Ganancia** | $110,000.00 | **$110,000.00** | $110,000.00 | Ganancia estándar de plataforma |
| **Precio Sugerido** | **$562,993.87** | **$564,872.19** | **$568,628.83** | **$562,993.87 < $564,872.19 < $568,628.83** (OK) |
| **Nivel de Confianza** | `estimada` | `estimada` | `estimada` | Incluye pendiente `variante_supuesta` |

> **Conclusión Matemática:** El precio sugerido de la 43 ft ($564,872.19) se sitúa con precisión monotónica entre la 42 ft ($562,993.87) y la 45 ft ($568,628.83). La diferencia contra la 42 ft es de exactamente +$1,878.32 (+$576.82 por 1 cargador + $1,301.50 por escala de piso).

---

## 3. Verificación de Base de Datos (8 Checks en `true`)

Se ejecutó la migración en una base PostgreSQL 17 desechable clonada del esquema real (`anty_test_43ft`). Se probó dos veces consecutivas (`ON_ERROR_STOP=1`) para certificar idempotencia, seguido de la ejecución de `docs/importacion/verificacion_43ft.sql`.

### Consulta Ejecutada:
```sql
SELECT 
  (
    acero_count = 61 AND
    cargadores_count = 41 AND
    kits_count = 12 AND
    procesos_count = 80 AND
    costos_derivados_de_ok AND
    base_40x2_intacta AND
    variantes_2r1d_intactas = 8 AND
    gondolas_intactas = 2
  ) AS todo_ok,
  acero_count,
  cargadores_count,
  kits_count,
  procesos_count,
  costos_derivados_de_ok,
  base_40x2_intacta,
  variantes_2r1d_intactas,
  gondolas_intactas
FROM checks;
```

### Salida Real de `psql`:
```
 todo_ok | acero_count | cargadores_count | kits_count | procesos_count | costos_derivados_de_ok | base_40x2_intacta | variantes_2r1d_intactas | gondolas_intactas 
---------+-------------+------------------+------------+----------------+------------------------+-------------------+-------------------------+-------------------
 t       |          61 |               41 |         12 |             80 | t                      | t                 |                       8 |                 2
(1 fila)
```

**Comprobaciones Validadas:**
1. `acero_count = 61`: Los 61 renglones de acero clonados para 43/3.
2. `cargadores_count = 41`: Exactamente 41 piezas en el IPR de 4".
3. `kits_count = 12`: Los 12 kits fijos clonados ($45,685.98).
4. `procesos_count = 80`: Los 80 procesos de mano de obra clonados ($22,930.00).
5. `costos_derivados_de_ok = t`: `modelos.costos_derivados_de` apunta a `PLATAFORMA 2 40 FT`.
6. `base_40x2_intacta = t`: Modelo origen 40/2 permanece inalterado (61 acero, 38 cargadores, 12 kits, 80 procesos).
7. `variantes_2r1d_intactas = 8`: Las 8 variantes existentes de la migración 2R-1d permanecen idénticas.
8. `gondolas_intactas = 2`: Las 2 góndolas conservan sus 49 renglones de acero y kits fijos intactos.

---

## 4. Auditoría de Variantes en Blanco en el Catálogo

Se realizó una auditoría de conteos sobre la totalidad de los modelos registrados en el catálogo de Supabase:

```sql
SELECT 
  m.id, 
  p.nombre, 
  m.tipo, 
  m.largo_ft, 
  m.num_ejes, 
  (SELECT count(*) FROM receta_base r WHERE r.modelo_id = m.id AND r.seccion = 'acero') as acero_rows, 
  (SELECT count(*) FROM costos_modelo cm WHERE cm.modelo_id = m.id) as kits_rows, 
  (SELECT count(*) FROM procesos_manufactura pm WHERE pm.modelo_id = m.id) as procesos_rows 
FROM modelos m 
LEFT JOIN productos p ON p.id = m.producto_id 
ORDER BY m.tipo, m.largo_ft, m.num_ejes;
```

**Resultado:**
- `DOLLY 2 EJES`: 33 acero, 18 kits, 43 procesos.
- `GONDOLA 2 EJES 45 M3`: 49 acero, 15 kits, 0 procesos (mano de obra fija en costeo).
- `GONDOLA 3 EJES 45 M3`: 49 acero, 14 kits, 0 procesos.
- `PLATAFORMA 2 35 FT`: 61 acero, 12 kits, 80 procesos.
- `PLATAFORMA 2 40 FT`: 61 acero, 12 kits, 80 procesos.
- `PLATAFORMA 3 40 FT`: 61 acero, 12 kits, 80 procesos.
- `PLATAFORMA 2 42 FT`: 61 acero, 12 kits, 80 procesos.
- `PLATAFORMA 3 42 FT`: 61 acero, 12 kits, 80 procesos.
- `PLATAFORMA 3 43 FT`: **0 acero, 0 kits, 0 procesos** (era la **única** variante en blanco).
- `PLATAFORMA 2 45 FT`: 61 acero, 12 kits, 80 procesos.
- `PLATAFORMA 3 45 FT`: 61 acero, 12 kits, 80 procesos.
- `PLATAFORMA 2 48 FT`: 61 acero, 12 kits, 80 procesos.
- `PLATAFORMA 3 48 FT`: 61 acero, 12 kits, 80 procesos.

> **Hallazgo:** Con la aplicación de `20261109_01_costos_plataforma_43ft.sql`, el 100% de los modelos de plataformas (10/10) cuentan con sus costos base completos. No existen otras variantes huérfanas en el catálogo actual.

---

## 5. Textos y Capturas de Avisos en UI

### A. Configurador de Equipo (`ConfiguradorEquipo.tsx`)
Cuando se abre un modelo que carece de despiece (o en caso de que alguna sección falte en el futuro):
- **Si faltan las 3 secciones (caso 43 ft previo a migración):**  
  `"Sin precio sugerido: faltan acero, kits y mano de obra de este modelo"`
- **Si faltan 2 secciones:**  
  `"Sin precio sugerido: faltan acero y kits de este modelo"` (o la combinación respectiva)
- **Si falta 1 sección:**  
  `"Sin precio sugerido: falta acero de este modelo"` / `"Sin precio sugerido: faltan kits de este modelo"` / `"Sin precio sugerido: falta mano de obra de este modelo"`
- **Ubicación:** Sección de totales del configurador, en el bloque donde normalmente se muestra el precio sugerido en negritas.

### B. Editor de Cotizaciones (`CotizacionEditor.tsx`)
Cuando se agrega o visualiza un concepto configurado cuyo precio sugerido resultó nulo o incompleto (precio unitario `$0.00`):
- **Aviso Banner en la tarjeta del remolque:**
  ```
  [Icono AlertCircle] Sin precio: costeo incompleto. Captura el precio a mano.
  ```
  (Estilizado con `bg-amber-50 dark:bg-amber-950/40 text-amber-800 dark:text-amber-300 border-amber-200 dark:border-amber-800`)
- **Aviso junto al campo de Precio Unitario:**
  Input resaltado con borde ámbar y texto de advertencia debajo:
  `Captura a mano` / `Sin precio: costeo incompleto. Captura el precio a mano.`
- **Guardado NO Bloqueante:** El formulario permite guardar la cotización con el precio editado manualmente o en $0 si el vendedor está en proceso de cotización preliminar.

---

## 6. Pruebas Automatizadas y Verificación de Sanidad

- **Pruebas Deno Totales:** **295 pasadas | 0 falladas** (baseline inicial: 289; 6 pruebas nuevas agregadas).
  - 1 prueba de motor en `supabase/functions/make-server-feea4382/motor/costeo.test.ts`:
    - Costeo exacto de 43 ft 3 ejes ($129,942.15 acero, $454,872.19 costo, $564,872.19 precio).
    - Escala de piso plástico por largo (43/40 = $55,964.50).
    - Monotonía contra 42/3 y 45/3.
    - Preservación de nivel de confianza `estimada` y pendientes (`variante_supuesta` y `sin_precio`).
  - 5 pruebas unitarias en `src/app/utils/costeo.test.ts`:
    - Retorno `null` ante costeos completos, estimados con precio y nulos.
    - Formateo de 1 sección faltante (`acero`, `kits`, `mano_obra`).
    - Formateo de 2 secciones faltantes (`acero y kits`, `acero y mano de obra`, `kits y mano de obra`).
    - Formateo de 3 secciones faltantes (`acero, kits y mano de obra`).
    - Deducción automática desde pendientes cuando no se provee el arreglo explícito.
- **Resultado de `node scripts/verificar.mjs --limpio`:**
  ```
  == 1. Archivos de parche o temporales nuevos: OK
  == 2. Codificación de los archivos modificados: OK (UTF-8 sin BOM)
  == 3. Sintaxis de .ts/.tsx modificados: OK
  == 4. TypeScript (tsc --noEmit): OK (44 errores, baseline 55)
  == 5. Build de Vite: OK
  == 6. Pruebas Deno: OK (295 pasan, 0 fallan)
  == 7. Arranque real del API: OK (Listening on http://localhost:8000/)
  == 8. Contexto del Dockerfile.backend: OK (deno cache index.ts exitoso)
  == 9. Checkout limpio de HEAD (git archive): OK (295 pasan, API arranca)
  ============================================================
  RESULTADO: TODO OK  (11/11 comprobaciones)
  ```

---

## 7. Instrucciones para Luis (Acciones Manuales)

1. **Paso 1 (Supabase SQL Editor):**
   - Abrir el SQL Editor en Supabase producción.
   - Ejecutar el script `COORDINACION/SQL_PARA_LUIS/20261109_01_costos_plataforma_43ft.sql`.
   - Ejecutar la verificación `COORDINACION/SQL_PARA_LUIS/verificacion_43ft.sql` y confirmar que `todo_ok = true`.
2. **Paso 2 (EasyPanel):**
   - Tras el merge a `main`, hacer **Rebuild** en `remolques-api` y `remolques-web`.
