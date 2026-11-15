# Reporte de Ejecución — Plataformas: Completar el Despiece (Solo Datos, Sin Mover Precios)

**Fecha:** 2026-11-14  
**Responsable:** Antigravity (para revisión de Claude y Luis)  
**Rama:** `despiece-plataformas-2026-11-14` (worktree `..\Remolques_despiece_plat`)  
**Base:** `main` (commit `344632f`)  
**Reglas duras cumplidas:** Cero push a remoto, cero merge a `main`, sin tocar EasyPanel ni Supabase producción; cero cambios en costos o precios; migración idempotente de dos pasadas con `ON_ERROR_STOP=1`; sin UUID de organización fijo en código.

---

## 1. Resumen Ejecutivo de Cambios

Se completó el despiece físico de plataformas y sus opciones conforme a los requerimientos de la auditoría y los archivos `PLATAFORMAS_AJUSTES_DESPIECE_2026-11-14.xlsx` y `DESPIECE_COMPLETO_2026-11-14.xlsx`.

| Rubro | Antes | Después | Delta | Comentarios |
|---|---:|---:|---:|---|
| **Catálogo de Materiales (`productos`)** | 512 | 517 | **+5** | Solo los marcados `CREAR` con costo $0.00. |
| **Líneas de Receta Base (`receta_base`)** | 2,090 | 2,100 | **+10** | +1 por cada uno de los 10 modelos de plataforma (`Placa de logo`, `seccion = NULL`). |
| **Componentes de Opciones (`opcion_componentes`)** | 181 | 207 | **+26** | Caja auxiliar (+4), Bicicletera (+2), Con riel (+1), Pisos (+18), Fleet Master (+1). |
| **Suite de Pruebas Deno** | 334 | 334 | 0 | 334 pasan, 0 fallan (umbral requerido $\ge 289$). |
| **Script de Verificación (`verificar.mjs --limpio`)** | 11/11 | 11/11 | 0 | 11 comprobaciones limpias en HEAD y entorno real. |
| **Script de Verificación SQL (`verificacion_despiece_plat.sql`)** | N/A | 1 fila | `todo_ok = true` | 9 comprobaciones atómicas en verde. |
| **Precio Sugerido 2R-1d (40/3, 42/3, 45/3, 48/3)** | Idéntico | Idéntico | **$0.00** | Cero variación al centavo en todas las plataformas y cotizaciones de regresión. |

---

## 2. Detalle de Acciones Ejecutadas

### 2.1 Alta de Materiales (Hoja `ALTA_MATERIALES`)
Se dieron de alta exactamente **5 materiales nuevos** en `productos` con costo unitario `$0.00` y precio unitario `$0.00`:
1. `TORNILLO GALVANIZADO 1/2 X 1 1/2 GRADO 5` (unidad `PZA`) — Para Bicicletero y Riel de matracas.
2. `BISAGRA 5/8` (unidad `PZA`) — Para Caja auxiliar (se corrigió la errata "bisabra" del listado original).
3. `CADENA 3/16` (unidad `M`) — Para Caja auxiliar (venta y consumo por metro: 0.30 m por caja).
4. `PIJA 5/16 X 2` (unidad `PZA`) — Para fijación de piso (450 pzas según unión de listados).
5. `PIJA 5/16 X 2 1/2` (unidad `PZA`) — Para fijación de piso (150 pzas según unión de listados).

> [!NOTE]
> **Materiales NO creados (respetados conforme a la instrucción):**
> - `ARNÉS`: No se creó. Pendiente de que Leolca defina qué incluye frente a los cables por metro ya catalogados.
> - `TORNILLO 1/2 X 1 O 1/2 X 1 3/4 GRADO 8`: No se creó. Pendiente de confirmar si corresponde al `TORNILLO 1/2 X 1 3/4` ya existente y su grado específico.

---

### 2.2 Despiece Complementario (Hoja `AGREGAR_DESPIECE`)

#### A. Receta Base de Plataformas (+10 renglones, 1 por modelo)
- **Material reutilizado:** `TORNILLO CABEZA DE COCHE 1/4 X 1 1/2` (`id = '03324988-aa14-44e2-ad6e-1e33bcc7e8cf'`).
  - Nota: En `TORNILLERIA.xlsx` figura como `TORNILLO CABEZA DE COCHE 1/4 X 3`, pero la columna P de `DESPIECE_COMPLETO` indica reutilizar el material existente en catálogo `TORNILLO CABEZA DE COCHE 1/4 X 1 1/2`.
- **Cantidad:** 4 pzas.
- **Paso/Fase:** `TERMINADO`.
- **Uso:** `Placa de logo`.
- **Sección:** `NULL` (garantiza cero impacto en costo de acero y precio).
- **Condición:** `NULL` (fijo en todas las plataformas).
- **Modelos impactados (10):**
  1. `PLATAFORMA 2 35 FT`
  2. `PLATAFORMA 2 40 FT`
  3. `PLATAFORMA 3 40 FT`
  4. `PLATAFORMA 2 42 FT`
  5. `PLATAFORMA 3 42 FT`
  6. `PLATAFORMA 3 43 FT`
  7. `PLATAFORMA 2 45 FT`
  8. `PLATAFORMA 3 45 FT`
  9. `PLATAFORMA 2 48 FT`
  10. `PLATAFORMA 3 48 FT`

#### B. Componentes de Opciones (+26 renglones en `opcion_componentes`)
Todos con `escala = 'fija'`, `rol = 'componente'`, `seccion = NULL`:

1. **Adicionales / Caja auxiliar (`caja_auxiliar`) — 4 componentes:**
   - `BISAGRA 5/8`: 2 pzas (Uso: `Caja auxiliar`).
   - `CADENA 3/16`: 0.30 m (Uso: `Caja auxiliar (m)`).
   - `TORNILLO ALLEN 1/2 X 1 1/2`: 2 pzas (Uso: `Caja auxiliar`).
   - `TUERCA ESTANDAR 1/2 GRADO 5`: 2 pzas (Uso: `Caja auxiliar`).

2. **Adicionales / Bicicletera (`bicicletera`) — 2 componentes:**
   - `TORNILLO GALVANIZADO 1/2 X 1 1/2 GRADO 5`: 2 pzas (Uso: `Bicicletero`).
   - `TUERCA ESTANDAR 1/2 GRADO 5`: 2 pzas (Uso: `Bicicletero`).

3. **Riel / Con riel (`con_riel`) — 1 componente:**
   - `TORNILLO GALVANIZADO 1/2 X 1 1/2 GRADO 5`: 2 pzas (Uso: `Riel de matracas`).
   - *Nota de conflicto asentada en la columna notas:* "Conflicto: manual dice tornillo 1/2 X 1 3/4; lista dice 1/2 X 1 1/2 Grado 5".

4. **Piso (todas las 9 opciones excepto `sin_piso`) — 18 componentes (9 × 2):**
   - Opciones: `antiderrapante`, `encino`, `encino_centro_plastico_lados`, `laminado`, `laminado_madera`, `laminado_plastico`, `pino`, `plastico_cafe`, `plastico_negro`.
   - Componente 1: `PIJA 5/16 X 2` × 450 pzas (Uso: `Pijas del piso`).
   - Componente 2: `PIJA 5/16 X 2 1/2` × 150 pzas (Uso: `Pijas del piso`).
   - *Nota asentada:* "Cantidad preliminar 450/150 pzas según union de listados paso 11; pendiente confirmación Leolca por tipo de piso".
   - `sin_piso` se conserva con 0 componentes.

5. **Suspensión / Fleet Master (`fleet_master`) — 1 componente:**
   - `TAPON 1/4 SUSPENSION FM + 4`: 3 pzas (Paso: `AIRE`, Uso: `Kit de aire con suspensión Fleet Master`).
   - La opción pasa de 12 a 13 componentes totales.

---

### 2.3 Condiciones Sin Mapear (Hoja `MAPEAR_CONDICIONES`)

#### A. Cómo evalúa el motor `sin_mapear` hoy
En `supabase/functions/make-server-feea4382/motor/resolver_receta.ts` (líneas 84–87), cuando `evaluarCondicion` detecta `condicion.sin_mapear`:
1. Devuelve estrictamente **`false`**.
2. Agrega la línea al arreglo `omitidas` con la descripción del texto original.
3. **Resultado:** Las 10 líneas **NUNCA se incluyen en `res.lineas`**.

#### B. Qué cambia en Almacén / OT
- Actualmente, el sistema **no genera vales de entrega ni rebaja de inventario** para estas 10 líneas en la Orden de Trabajo (OT).
- En caso de fabricar una unidad multimodal o con plafones de carrito, el taller debe suministrar estos materiales manualmente.
- En precio, el impacto es **$0.00**, ya que todas tienen `seccion = NULL`.

#### C. Factibilidad de Mapeo y Aplicación de la Regla Negativa
El prompt instruye explícitamente:
> *"Si el campo de la opción no existe en la configuración, no lo inventes: déjalo como está y repórtalo."*

Al revisar la estructura de `configuracion.grupos`:
- `adicionales` se almacena como un arreglo de objetos `[{ opcion: 'multimodal', cantidad: 1 }]` (por ser `multiple_con_cantidad`). El evaluador de `resolver_receta.ts` (línea 97) solo evalúa cadenas u objetos escalares con `.opcion`; un arreglo evalúa siempre a `''`, haciendo imposible evaluar `campo: 'adicionales'` con igualdad sin modificar el motor.
- `plafones` tiene `seleccion = 'cantidad'` con 4 variantes (`ambar_estribo`, `ambar_laterales`, etc.) y no posee clave `ninguna`, ni opciones booleanas generales de "laterales" o "estribo".
- **Decisión:** En estricto apego a la regla, **se dejaron las 10 líneas en `receta_base` con su condición `{"sin_mapear": "..."}` intacta** y se documentó el análisis completo en `docs/importacion/analisis_condiciones_plataformas.md`.
- **Recomendación para siguiente fase:** Mover `CANDADO PARA PLANA` (x12) y `CARGADO 3 X 102 IN` (x8) a `opcion_componentes` de la opción `Multimodal`, donde el motor sí soporta opciones múltiples nativamente y las incluirá en almacén/OT sin requerir condiciones sintéticas en `receta_base`.

---

### 2.4 Lo que NO se Toca (Hojas `CANTIDADES_A_CONFIRMAR` y `COBRO_PROPUESTAS`)
- No se modificó ninguna cantidad sujeta a confirmación técnica de Leolca.
- No se modificó ningún costo ni cobro de opciones ni precios de venta.

---

## 3. Pruebas y Verificación Rigurosa

### 3.1 Idempotencia en Base de Datos Desechable (`ON_ERROR_STOP=1`)
Se ejecutó la migración dos veces en base de datos PostgreSQL local:

```text
CONTEOS INICIALES:
  productos:            512
  receta_base:         2090
  opcion_componentes:   181

PASADA 1 (Migración aplicada):
  productos:            517  (+5  exactos)
  receta_base:         2100  (+10 exactos, 1 por plataforma)
  opcion_componentes:   207  (+26 exactos)

PASADA 2 (Ejecución idempotente):
  productos:            517  (0 duplicados)
  receta_base:         2100  (0 duplicados)
  opcion_componentes:   207  (0 duplicados)
```

### 3.2 Script de Verificación SQL (`docs/importacion/verificacion_despiece_plat.sql`)
Ejecutado sobre la base de datos local:

```text
 materiales_5_ok | receta_base_placa_logo_10_ok | caja_auxiliar_4_ok | bicicletera_2_ok | con_riel_1_ok | pisos_18_ok | sin_piso_0_ok | fleet_master_tapon_ok | acero_plataformas_intacto | todo_ok 
-----------------+------------------------------+--------------------+------------------+---------------+-------------+---------------+-----------------------+---------------------------+---------
 t               | t                            | t                  | t                | t             | t           | t             | t                     | t                         | t
(1 fila)
```
Resultado: **`todo_ok = true`** (las 9 subconsultas de comprobación en `true`).

### 3.3 Compatibilidad de Precios — Tabla de Sanidad 2R-1d
Comprobado mediante el motor de costeo puro (`costeo.ts`) con la configuración tipo dorada:
- Suspensión: Fleet Master
- Ejes: Fleet Master
- Patín: HJ
- Piso: Plástico laminado (`laminado_plastico`)
- Kit de aire / ABS: 3 ejes 2 retráctiles (`3e_2_retractil`)
- Ajustes prueba dorada: $31,485.00 ($30,000 líneas sin concepto + $1,485)
- Ganancia: $110,000.00

| Plataforma | Costo Total Calculado | Ganancia | Precio Sugerido Calculado | Precio Esperado Tabla 2R-1d | Diferencia |
|---|---:|---:|---:|---:|---:|
| **40 FT / 3 EJES** | $449,237.23 | $110,000.00 | **$559,237.23** | $559,237.23 | **$0.00** |
| **42 FT / 3 EJES** | $452,993.87 | $110,000.00 | **$562,993.87** | $562,993.87 | **$0.00** |
| **45 FT / 3 EJES** | $458,628.83 | $110,000.00 | **$568,628.83** | $568,628.83 | **$0.00** |
| **48 FT / 3 EJES** | $464,263.79 | $110,000.00 | **$574,263.79** | $574,263.79 | **$0.00** |

Cero variación. Las 60 cotizaciones reales de regresión arrojan exactamente el mismo resultado previo.

### 3.4 Verificación General del Sistema (`node scripts/verificar.mjs --limpio`)
Resultado de la corrida oficial:
- **1. Archivos de parche:** Sin parches ni temporales (OK).
- **2. Codificación:** UTF-8 sin BOM ni mojibake en todos los archivos modificados (OK).
- **3. Sintaxis TypeScript:** Válida (OK).
- **4. TypeScript `tsc --noEmit`:** 0 nombres sin definir / total 41 errores (baseline 55, no sube) (OK).
- **5. Build de Vite:** `npm run build` exitoso (OK).
- **6. Pruebas Deno:** 334 pasan, 0 fallan (OK).
- **7. Arranque real del API:** Escuchando en http://localhost:8000/ (OK).
- **8. Contexto Dockerfile.backend:** Cache Deno exitoso (OK).
- **9. Checkout limpio de HEAD (git archive):** 334 pruebas pasan, API arranca (OK).
- **Resultado final:** `TODO OK (11/11 comprobaciones)`.

---

## 4. Registro de Commits en la Rama

La rama `despiece-plataformas-2026-11-14` contiene commits atómicos y descriptivos:
1. `f36c481`: `feat(despiece): alta de materiales y despiece de opciones para plataformas`
   - `supabase/migrations/20261114_01_plataformas_despiece.sql`
   - `docs/importacion/verificacion_despiece_plat.sql`
   - `COORDINACION/SQL_PARA_LUIS/20261114_01_plataformas_despiece.sql`
   - `COORDINACION/SQL_PARA_LUIS/verificacion_despiece_plat.sql`
2. `2d2833d`: `docs(despiece): analisis y evaluacion de condiciones sin_mapear en receta de plataformas`
   - `docs/importacion/analisis_condiciones_plataformas.md`
3. (Este commit): `docs(despiece): reporte de despiece de plataformas y actualizacion de changelog`
   - `PLATAFORMAS_DESPIECE_REPORTE_ANTY.md`
   - `COORDINACION/REPORTES/PLATAFORMAS_DESPIECE_REPORTE_ANTY.md`
   - `CHANGELOG_ANTIGRAVITY.md`

---

## 5. Acciones Manuales para Luis

1. **Aplicar Migración en Supabase Producción:**
   - Abrir el **SQL Editor** de Supabase en producción.
   - Copiar y ejecutar el contenido de [20261114_01_plataformas_despiece.sql](file:///c:/Users/luisa/Downloads/proyectos_antygravity/Remolques_despiece_plat/COORDINACION/SQL_PARA_LUIS/20261114_01_plataformas_despiece.sql).
2. **Validar con Consulta de Verificación:**
   - En una nueva pestaña del SQL Editor, ejecutar [verificacion_despiece_plat.sql](file:///c:/Users/luisa/Downloads/proyectos_antygravity/Remolques_despiece_plat/COORDINACION/SQL_PARA_LUIS/verificacion_despiece_plat.sql).
   - Comprobar que devuelva una sola fila con `todo_ok = true`.
3. **Rebuild en EasyPanel:**
   - **NO ES REQUERIDO.** Esta entrega consiste 100% en migración SQL de catálogo de datos, recetas y componentes de opciones, sin modificaciones de lógica en backend Deno ni frontend React.
