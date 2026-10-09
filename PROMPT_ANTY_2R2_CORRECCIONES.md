# 2R-2 — correcciones (rama `bloque-2r-2`, cambios en el índice, sin commit) — NO se autoriza push ni merge

Corrí `deno test` yo mismo: las 15 pasan, `deno check` de los módulos del motor pasa y `TS2304` en `index.ts` da 0. El diff de `index.ts` solo añade las 3 rutas (bien). **Pero** hay un bloqueante que haría fallar las 3 rutas en producción, y varios defectos del motor que las pruebas no ven porque están escritas para pasar.

## 1. BLOQUEANTE — las 3 rutas y el cargador consultan columnas que NO existen
Comprobé cada `.select()` contra el esquema real (`20261007_01_configurador_esquema.sql`, aplicado en producción). Postgres/PostgREST contesta error 42703 y las rutas devolverían 500 (o "Modelo no encontrado") **siempre**:

| Consulta | Columna pedida | Realidad |
|---|---|---|
| `modelos` (cargador y `GET /modelos`) | `nombre` | **No existe.** `modelos` tiene `id, producto_id, tipo, largo_ft, num_ejes, datos_tecnicos, activo`. El nombre sale de `productos` vía `producto_id` (embed: `productos(nombre)`) |
| `grupos_configuracion` (cargador y configuración) | `tipo` | **No existe.** Es `seleccion`. También hay `aplica_a`, `depende_de`, `regla`, `cantidad`, `unidad_precio`, `medidas` |
| `opciones_configuracion` (cargador y configuración) | `seleccion` | **No existe** aquí; `seleccion` es de **grupos**. Sí existen `marcas`, `medidas`, `activo`, `aliases` |

Corrige todas las consultas. Además:
- El cargador no trae `opciones_configuracion.marcas` (lo necesita el punto 2b) ni `grupos.aplica_a/depende_de/seleccion` (los necesita el punto 2d).
- **Prueba de contrato (nueva, obligatoria):** una prueba de Deno que lea los `.select("...")` de `cargar_datos.ts` y de las 3 rutas, extraiga las columnas y compruebe que **cada una aparece en el `CREATE TABLE` de la migración** correspondiente. Así este error no puede repetirse sin que falle el test. Pega la tabla `consulta → columna → línea de la migración`.
- Mueve los `import` del motor a la **parte superior** de `index.ts`, junto con los demás (hoy están a mitad del archivo).

## 2. Defectos del motor que las pruebas actuales no atrapan (los reproduje)

**a. `unica_con_cantidad` no funciona con datos reales.** `calcularCantidad` compara `escala === 'unica_con_cantidad'`, pero la escala en la base solo vale `fija`/`por_eje`/`por_largo`. La prueba 3 pasa porque **inventa** un componente con `escala: "unica_con_cantidad"`. Con datos reales, `rines: {opcion:"acero", marca:"ampro", cantidad: 6}` devuelve `RIN DE ACERO AMPRO x8`, no 6. Debe leerse de `grupo.seleccion === 'unica_con_cantidad'` y de la `cantidad` de la configuración: ese valor es el **total**.

**b. La marca de rin es ambigua.** `comp.nombre.includes(marca)` hace que `aluminio` + `fleet master` coincida con `FLEET MASTER` **y** `FLEET MASTER TRAPEZOIDAL` (error "se encontraron 2" y ambas líneas × 8), y `ampro` con `AMPRO` y `AMPRO MASTER TRAPEZOIDAL`. Con la configuración más común el motor da error. Usa el campo `marcas` de la opción (Fleet Master / Fleet Master trapezoidal / Ampro / Ampro trapezoidal) y empareja por nombre **completo** normalizado (no por subcadena). Si la configuración falla, `lineas` no debe llevar las marcas no elegidas.

**c. Condiciones.** El código evalúa `==`, pero el lenguaje acordado usa `=`: una condición con `=` se evalúa **siempre verdadera**. Faltan los campos `ejes` y `largo_ft`. Un operador desconocido hoy pasa como verdadero: debe ser **error**. Y `!=` con un grupo no elegido devuelve verdadero (con `gancho` sin elegir, el kit de gancho entra). Define el comportamiento y pruébalo.

**d. Faltan las validaciones pedidas.** (i) Un grupo `unica` que aplica al tipo del modelo (`aplica_a`) y no viene en la configuración se salta en silencio: debe ser **error** ("falta elegir <grupo>") salvo los grupos opcionales que documentes. (ii) Un grupo desconocido en la configuración se ignora: debe ser error. (iii) Una opción de otro grupo o inactiva (`activo = false`): error. (iv) `depende_de` si está presente. Con `{grupos:{}}` hoy el resultado trae **0 errores y 0 advertencias**.

**e. Resultados poco útiles.** `alternativas[].original` es el texto fijo `"Original"`: indica **qué componente reemplaza** el sustituto. `omitidas[]` no dice qué material ni cantidad se omitió: incluye `material`, `cantidad` y `uso`.

## 3. Pruebas: varias están escritas para pasar, no para probar
Rehazlas con la intención original del prompt (usa datos reales; si necesitas modificar una copia de la fixture, que el cambio sea un dato **válido**, nunca un valor inventado):
- **1:** que exista **una sola** familia de componentes de suspensión (cuenta las líneas de piernas, platos y cámaras: no 5 juegos).
- **2:** 2 ejes → piernas 2, ejes 2, rines 8; **3 ejes** → piernas 3, ejes 3, rines 12. Hoy solo se prueba el rin con 2 ejes.
- **3:** con datos reales (punto 2a).
- **6:** `CONSUMIBLE 65` para **35, 40, 42, 43, 45 y 48 ft** = 0.875, 1.0, 1.05, 1.075, 1.125, 1.2. Hoy solo 40 y 35.
- **8:** comprueba la **cantidad sumada**: `CONSUMIBLE 65` = 0.5 + 0.25 + 0.25 = 1.0 en una sola línea con tres pasos, y otro material repetido real con su suma.
- **12:** añade aluminio con `fleet master` (solo `RIN DE ALUMINIO FLEET MASTER`) y `fleet master trapezoidal`, `ampro` y `ampro master trapezoidal`.
- Añade: grupo `unica` faltante, grupo desconocido, operador `=`, operador desconocido, campo `ejes`, y la prueba de contrato del punto 1.
- Al terminar imprime el listado de nombres de las 15+ pruebas con su estado.

## 4. Limpieza y reglas
- `deno.lock` quedó sin versionar: añádelo a `.gitignore` o no lo toques. Que no entre en el commit.
- Editaste `package.json` con `node -e`. Es el mismo patrón prohibido; no lo repitas (usa tu herramienta de edición).
- Dijiste que `iconv` no está en Windows. **Sí está:** `& "C:\Program Files\Git\usr\bin\iconv.exe" -f UTF-8 -t UTF-8 <archivo>` (lo usaste en bloques anteriores). Córrelo sobre cada archivo nuevo y pega el resultado.
- Los cambios están solo en el índice. Haz **commits** (git add explícito, sin `-A`) cuando termines.
- Sin push ni merge. No quites ni cambies lo que el prompt pide sin avisarlo en el reporte.

## 5. Verificación (pega salidas reales)
1. `git diff --numstat main` y diff de rutas (solo las 3 nuevas).
2. `deno test` completo (todas las pruebas con nombre y estado).
3. `deno check` de los módulos del motor y de `index.ts` filtrado por `TS2304`: 0.
4. Tabla `consulta → columna → línea de la migración` (prueba de contrato).
5. Ejemplo ejecutado: aluminio + `fleet master` sin errores y una sola línea de rin con cantidad 8; con `cantidad: 6` → 6; con 3 ejes → piernas 3.
6. `{grupos:{}}` → lista de errores de grupos obligatorios.
7. `iconv`, `tsc --noEmit` filtrado por "Cannot find name", `npm run build`.
