# 2R-1b — correcciones (commit a0f78b5) — NO se autoriza push ni merge

Corrí tu migración `20261008_01_recetas_plataforma.sql` en un Postgres 17 local con los productos reales de producción **y con las restricciones reales de la tabla `productos`**. **No se puede aplicar.** Errores reales, en el orden en que aparecen:

## 1. BLOQUEANTE — error de sintaxis PL/pgSQL
```
ERROR: «largo» no es una variable conocida
LÍNEA 11: FOR largo, ejes IN VALUES
```
`FOR a, b IN VALUES …` no existe en PL/pgSQL, y `largo`/`ejes` no están declaradas en el `DECLARE`. Declara `v_largo int; v_ejes int;` y recorre con `FOR rec IN SELECT * FROM (VALUES …) AS t(largo, ejes) LOOP`, o sustituye el bucle por una sola consulta `SELECT count(*)` y un `RAISE EXCEPTION`.

## 2. BLOQUEANTE — la lista de modelos es incorrecta
Escribiste `(35,2),(40,2),(40,3),(42,2),(42,3),(43,2),(43,3),(45,2),(48,2),(48,3)`. **Los 10 modelos reales son:**
`35x2, 40x2, 40x3, 42x2, 42x3, 43x3, 45x2, 45x3, 48x2, 48x3`. **No existe 43x2** y **sí existe 45x3**. Con tu lista, el bloque de 43x2 deja `v_model_id = NULL` y revienta con `null en la columna modelo_id`. Toma los modelos **de la tabla `modelos`** (`SELECT largo_ft, num_ejes FROM modelos WHERE tipo='plataforma'`), no de una lista escrita a mano. Verifica que el número de bloques de modelo en el `.sql` es 10 y que cada uno apunta a un modelo distinto.

## 3. BLOQUEANTE — los materiales nuevos violan la restricción de `productos`
```
ERROR: viola la restricción «check» «tipo_chk»
La fila que falla contiene (CONSUMIBLE 65, materia_prima, CONSUMIBLE 65, SIN PRECIO, …, producto_terminado)
```
`productos.tipo` solo admite `'bien'` o `'servicio'` (migración `20260427_01_relational_schema.sql`). Lo de "materia prima" va en **`tipo_item`** (`'producto_terminado'` | `'materia_prima'`, migración `20260907_01_materiales_bom.sql`), cuyo **default es `producto_terminado`**. Tu INSERT no pone `tipo_item`, así que aunque pasara el CHECK, los 179 materiales nuevos quedarían como **productos terminados** y aparecerían como equipos vendibles. Los 144 materiales actuales son `tipo='bien'`, `tipo_item='materia_prima'`: **imita exactamente eso**.

Además:
- No pongas `id = nombre`. Omite `id` y deja el default `gen_random_uuid()::text` (así son todos los ids existentes).
- El `NOT EXISTS` debe acotar por `organizacion_id` y `tipo_item = 'materia_prima'`.

## 4. Materiales duplicados y un material basura (me lo pediste evitar en el prompt)
Computé los 197 nombres distintos de tu clasificación:
- **Duplicados por espaciado:** `ROLLO DE MICRO ALAMBRE` ≡ `ROLLO DE MICROALAMBRE`; `TORNILLO 3/4X3 1/2 GRADO 8` ≡ `TORNILLO 3/4 X 3 1/2 GRADO 8`. Se crearían **dos materiales** por cada pareja. Aplica la tabla de alias del prompt 2R (§3) y **normaliza espacios** antes de comparar. Pega la lista de alias aplicados y verifica de nuevo sin duplicados por `upper(replace(nombre,' ',''))`.
- **Material llamado `8`:** las filas 265 y 266 del manual (`producto = "8"`, cantidad 8) son **informativas** (los 8 rines/llantas de la referencia 2 ejes, ya cubiertos por la línea `4 por_eje`). Pasaron como `receta_base`, y el SQL intenta crear/buscar un material llamado `8`. Clasifícalas como `ignorar` con su razón.

## 5. Clasificación: la cuenta no cuadra con lo que reportas
Reportas "260 procesadas, 0 sin asignar" pero 86 + 27 + 129 = **242**. Las otras **18** quedaron como `ignorar` y **no se listan** en el informe. Son encabezados de grupo/opción (válido), pero el prompt pedía **listarlas con razón**. Añade una sección "Filas ignoradas (18)" con fila, texto y motivo. Verifica que cada una es de verdad un encabezado (`grupo_opcion`, `opcion_suspension`, `opcion_pintura`, `encabezado`) o informativa, y que **ninguna** es una línea de material perdida.

## 6. Ubicación y changelog
- El informe debe estar en **`docs/importacion/INFORME_2R1B.md`**, no en la raíz. Muévelo con `git mv`.
- Entrada del changelog: dices que se generaron "tablas temporales" (no es cierto: no hay ninguna) y que las matemáticas son "correctas" cuando el SQL no corre. Redáctala con lo que realmente hiciste, lista los 6 defectos de esta ronda, y **ordénala debajo de las existentes** de arriba, sin tocar las ajenas.
- **Volviste a reescribir el changelog con `node -e`**: es un script de parche (regla 2), aunque sea en línea. Usa tu herramienta de edición.

## 7. Verificación (pega salidas reales)
1. `git diff --numstat main` (solo archivos nuevos y el changelog, 0 borradas).
2. Conteo de bloques de modelo en el `.sql` = 10, con los 10 pares correctos (pega los 10).
3. `grep -c "'materia_prima'" ` sobre INSERT: la columna correcta es `tipo_item`; pega un INSERT de ejemplo.
4. Lista de materiales nuevos sin duplicados por `upper(replace(nombre,' ',''))` (pega el conteo y la lista de alias).
5. `iconv -f UTF-8 -t UTF-8` en `.sql`, `.json`, `.md` y changelog.
6. Si puedes levantar un Postgres local, corre la migración **dos veces** (idempotencia) y pega `verificacion_2R1b.sql`. Yo la corro de todos modos.
7. `npm run build`.

**No push, no merge.** Si algo no cuadra con el estado real, detente y avisa.
