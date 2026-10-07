# Correcciones al 2R-1a (commit 9c44fa6) — NO se autoriza push ni merge todavía

Revisé el diff contra `main` (ec95fff). La parte limpia: solo 5 archivos añadidos, 0 líneas borradas, UTF-8 correcto, 20 grupos / 126 opciones. Pero hay **defectos de contenido** y **violaciones de las reglas**. Corrige en la misma rama `bloque-2r-1a` con commits nuevos (sin reescribir historia).

## 0. Violaciones de reglas (no se repiten)
- Ejecutaste `git reset --hard ec95fff; git clean -fd`. `git clean -fd` **borra archivos sin versionar**. Se perdió `PROMPT_ANTY_2R1A.md` (mi prompt, sin versionar). Prohibido `reset --hard` y `clean` en este repo. Si necesitas rehacer commits, usa un `git commit` nuevo encima.
- Usaste `patch_changelog_2.py` (script de parche, prohibido por regla 1) y `git commit -am` (mete lo que no revisaste). Edita el changelog con tu herramienta de edición y usa `git add <archivos>` explícitos.
- Los commits reportados antes del reset (`70f2a81`, `9d26fba`, `59c18bb`, `9fa3ce0`) quedaron huérfanos. Está bien, pero no vuelvas a hacerlo.

## 1. `20261007_01_configurador_esquema.sql`

### 1.1 BLOQUEANTE — no redefinas `get_current_org_id()`
Líneas 3–5 hacen `CREATE OR REPLACE FUNCTION get_current_org_id()` leyendo el claim `org_id` del JWT. **La función real de producción** (migración `20260509_01_saas_invitations_trigger.sql`) lee `perfiles_organizacion` por `auth.uid()`. Tu versión **la sobrescribe en producción** y rompe la RLS de TODAS las tablas existentes. **Borra ese bloque entero.** La función ya existe; solo úsala.

### 1.2 El esquema no es el que pedí (§3 del prompt 2R)
Simplificaste tablas y perdiste columnas que el motor necesita. Reescribe con **al menos** estos campos:

| Tabla | Falta / está mal |
|---|---|
| `modelos` | faltan `largo_ft`, `num_ejes`, `datos_tecnicos jsonb`, `activo`. Hoy tiene un `prefijo` que no pedí (quítalo o justifícalo). `tipo` con CHECK (plataforma/dolly/gondola/jaula/caja_seca/traila) |
| `grupos_configuracion` | faltan `seleccion` (unica/unica_con_medida/unica_con_cantidad/cantidad/derivada/multiple_con_cantidad), `aplica_a text[]`, `depende_de`, `regla jsonb`, `notas`, `unidad_precio`, `cantidad` (regla de cantidad, p. ej. "= nº de ejes"). Los booleanos `requerido`/`multiple` **no bastan** |
| `opciones_configuracion` | `descripcion` → debe ser `nombre`; faltan `medidas jsonb` (columna propia), `clase`, `activo`, `notas`, `precio_fuente`, `otros_precios jsonb`, `marcas`, `proveedor`. Quita `costo_adicional`, `material_id`, `cantidad` (esos pertenecen a `opcion_componentes`) |
| `opcion_componentes` | faltan `escala` (fija/por_eje/por_largo), `rol` (componente/sustituto/independiente), `paso`, `uso`, `seccion`, `condicion jsonb`. **Quita `UNIQUE(opcion_id, material_id)`**: un mismo material repetido se **suma**, no se bloquea |
| `receta_base` | `multiplicador TEXT` → `escala` con CHECK; `condicion` debe ser **jsonb**, no TEXT; faltan `uso`, `seccion` |
| `material_proveedores` | falta `unidad`, `vigente_desde`, `preferido`; **falta `organizacion_id`** (hoy la RLS depende de `proveedores`, frágil) |
| `parametros_costeo` | OK |

Todas las tablas hijas llevan `organizacion_id` + RLS con `get_current_org_id()` (patrón de `20260907_02_proveedores.sql`). Índices en las FK. Mantén los `UNIQUE` pedidos.

## 2. `scripts/generar_catalogo_sql.cjs` y `20261007_02_catalogo_opciones.sql`

### 2.1 BLOQUEANTE — el match de `modelos` es ambiguo
`nombre ILIKE '%40%FT%' AND nombre ILIKE '%2%EJES%'` hace que **"42 FT 3 EJES"** cumpla `%2%EJES%` (el 2 de "42") y que **"43 FT 2 EJES"** cumpla `%3%EJES%`. Con `LIMIT 1` y `ON CONFLICT DO NOTHING` el error **queda silenciado**: modelos mal ligados sin aviso. Además tu changelog dice "búsqueda exacta": es falso, es `ILIKE` difuso.
- **Antes de escribir el patrón, mira los nombres reales:** el dueño tiene el resultado de `docs/remediacion/01c_productos_terminados.sql`. Pídele esa lista (o usa la que ya pegó) y matchea por **nombre exacto** o regex con límites (`~* '\m40\s*FT\M.*\m2\s*EJES\M'`), nunca por subcadena suelta.
- Que el script **falle** (`RAISE EXCEPTION`) si no encuentra **exactamente 1** producto por variante, en vez de omitir en silencio. Al final del DO, verifica `count(*) = 10` o aborta. (Si falla en producción, el `BEGIN…COMMIT` lo deshace entero: es lo que queremos.)
- `org_id` hardcodeado: acéptalo para el único cliente actual, pero déjalo como constante nombrada al inicio y comenta por qué.

### 2.2 Pérdida de información del catálogo
El generador descarta campos del JSON:
- `seleccion`: lo reduces a dos booleanos. `unica_con_medida` (frente), `unica_con_cantidad` (rines, llantas), `cantidad` (plafones), `derivada` (abs) y `multiple_con_cantidad` (adicionales) **se vuelven "no requerido / no múltiple"**. Guarda el valor original en `seleccion`.
- Grupo: se pierden `aplica`, `cantidad`, `unidad_precio`, `regla`, `notas`, `medidas`.
- Opción: se pierden `notas` (21 opciones), `clase`, `marcas`, `proveedor`. `precio_fuente` y `otros_precios` van dentro de `datos`; pásalos a sus columnas.
- `medidas` del grupo `frente` debe quedar consultable.
- Verifica con una query de reconstrucción que **ningún dato del JSON** se pierde (cuenta de claves por grupo/opción antes y después).

### 2.3 Idempotencia
`ON CONFLICT … DO UPDATE` debe actualizar **todas** las columnas nuevas, no solo cuatro.

## 3. `docs/importacion/verificacion_2R1a.sql`
- `gc.nombre != 'Frente'` es un **filtro a medida para que cuadre el número**. Quítalo. El número real de opciones sin precio hoy: **32** en el JSON (6 de ellas en `frente`, que tiene precio por medida en `medidas`). Reporta ambos conteos: sin precio total y sin precio ni medidas.
- `tablas_creadas` y `tablas_con_rls` filtran solo por nombre sin esquema: añade `table_schema='public'` / `schemaname='public'`.
- Añade: `grupos` esperado 20, `opciones` esperado 126, `modelos` esperado 10, `filas_receta_base` esperado 0, y `funcion_org_intacta` (comprobar que `get_current_org_id` sigue leyendo de `perfiles_organizacion`: `pg_get_functiondef` contiene `perfiles_organizacion`).

## 4. Changelog
Corrige la entrada 2R-1a: no digas "búsqueda exacta"; no digas "UUID dinámico" (`productos.id` es TEXT); lista las desviaciones que arreglaste; anota el incidente del `reset --hard`/`clean -fd`. Mantén el formato.

## 5. Verificación al reportar (pega salidas reales)
1. `git diff --numstat main` — solo 5 archivos, 0 borradas (el changelog no debe borrar nada).
2. `grep -n "get_current_org_id" supabase/migrations/20261007_01_configurador_esquema.sql` — solo **usos** en políticas, ninguna línea `CREATE ... FUNCTION`.
3. `iconv -f UTF-8 -t UTF-8` en los `.sql`, el JSON y el changelog.
4. Conteos: INSERT de grupos 20 / opciones 126; reconstrucción sin pérdida de campos.
5. Regex de modelos: pega las 10 consultas y, para cada una, contra qué nombre real de la lista del dueño coincide (y que no coincide con ningún otro).
6. `npm run build`.
7. Si puedes levantar un Postgres local (docker o `pg_tmp`), corre ambas migraciones **dos veces** (idempotencia) con una función `get_current_org_id` de prueba y una tabla `productos` de prueba. Si no puedes, dilo.

No push, no merge. Reporta commit y salidas.
