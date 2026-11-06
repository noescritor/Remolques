# Reporte de Implementación: Góndola con Volumen Libre y Configurable (20-60 m³)

**Fecha:** 2026-11-06  
**Autor:** Antigravity (Anty)  
**Revisa:** Claude  
**Rama:** `gondola-volumen-libre-2026-11-05`  
**Worktree:** `..\Remolques_volumen_libre`  
**Base commit:** `a8330f2` (main)  

---

## 1. Resumen Ejecutivo

A solicitud de Luis tras revisar el configurador de góndolas en producción, se transformó el grupo **Volumen** de un selector con tarjetas fijas preseleccionadas (`45 m³` y `30 m³`) a un **campo libre numérico configurable**, donde el usuario puede capturar cualquier capacidad en metros cúbicos (por ejemplo `38` o `37.5 m³`), dentro de un rango permitido de **20 a 60 m³**.

El configurador ahora inicia **sin ningún valor preseleccionado**, mostrando un indicador de grupo pendiente (punto rojo) y deshabilitando la confirmación ("Agregar a la cotización") hasta que el usuario ingrese un volumen válido. Se añadieron dos botones de acceso rápido (**30 m³** y **45 m³**) que facilitan el llenado en un clic sin imponer ninguna opción por defecto.

El costo continúa calculándose de forma proporcional y transparente respecto a la receta base de 45 m³ tanto para los 4 renglones de acero como para los componentes y costos de la tina (A-36 y Hardox 450), registrando una advertencia provisional (`variante_supuesta`) para todo volumen diferente a 45 m³.

---

## 2. Historial de Commits

La implementación se dividió en 4 commits atómicos y descriptivos:

1. `e0cc2f7` — `feat(motor): soportar volumen libre de gondola (20-60 m3) con proporcionalidad y advertencias`
   - Actualización de `escalas.ts` con constantes `VOLUMEN_MIN_GONDOLA_M3 = 20`, `VOLUMEN_MAX_GONDOLA_M3 = 60` y helper unificado `formatearVolumenM3`.
   - `resolverVolumenGondolaDetallado`: soporte para números directos, strings ("38", "37,5"), objetos `{ opcion: 'personalizado', m3: 38 }` y compatibilidad con `m3_30`/`m3_45`.
   - `costeo.ts` y `resolver_receta.ts`: advertencia `variante_supuesta` para cualquier volumen $\neq 45$ m³.

2. `4d70967` — `feat(db): migrar grupo volumen a opcion personalizado con rango 20-60 y desactivar tarjetas fijas`
   - Migración idempotente `20261106_01_gondola_volumen_libre.sql`.
   - Inserción de opción `personalizado` con `datos = '{"min":20,"max":60}'::jsonb`.
   - Desactivación de opciones fijas `m3_45` y `m3_30` (`activo = false`) preservando integridad referencial con cotizaciones previas.
   - Actualización de `docs/gondola/verificacion_volumen.sql` con checks 10 y 11.

3. `859e814` — `feat(ui): control de volumen libre con limites 20-60, atajos y validacion en configurador`
   - Creación de `src/app/utils/volumenGondola.ts` con validación pura (`evaluarEstadoVolumen`, `esVolumenCompleto`).
   - `ConfiguradorEquipo.tsx`: eliminación de valor por defecto `m3_45`, renderizado de input numérico con sufijo `m³`, atajos rápidos 30 y 45 m³, punto rojo en menú lateral mientras esté incompleto, y ocultamiento de la etiqueta "Sin receta" para grupos conductores.
   - Actualización de nombres y textos en `tituloEquipo.ts`, `nombreItemCotizacion.ts`, `texto_especificacion.ts`, `ficha_orden_trabajo.ts` y `ChecklistDespieceModal.tsx`.

4. Commit actual — `test(gondola): pruebas unitarias volumen libre, reporte y bitacora`
   - `volumenGondola.test.ts`: 4 suites de pruebas para funciones de validación.
   - `nombreItemCotizacion.test.ts` y `tituloEquipo.test.ts`: casos con volúmenes libres 38 y 37.5 m³.
   - `gondola_volumen.test.ts`: Test 1 (multi-representación 45), Test 2 (multi-representación 30), Test 2c (38 m³ libre), Test 2d (decimales 37.5), Test 7 (fuera de rango y no numéricos).
   - `CHANGELOG_ANTIGRAVITY.md` y reporte final.

---

## 3. Pruebas en Base de Datos Local (PostgreSQL 17, puerto 54331)

Se creó la base temporal `anty_volumen_libre_test` basada en el template `remolques`. Se ejecutaron en secuencia y con `ON_ERROR_STOP=1`:
1. `20261105_01_gondola_volumen.sql`
2. `20261105_02_gondola_volumen_receta_acero.sql`
3. `20261105_03_gondola_volumen_costos_tina.sql`
4. `20261106_01_gondola_volumen_libre.sql` (2 pasadas consecutivas para comprobar idempotencia estricta).

### Resultado de `docs/gondola/verificacion_volumen.sql`:
```
 check_numero |                  descripcion                  | resultado 
--------------+-----------------------------------------------+-----------
            1 | grupo_volumen_existe                          | t
            2 | opciones_volumen_existen                      | t
            3 | columna_escala_existe                         | t
            4 | check_escala_receta_base_incluye_por_volumen  | t
            5 | check_escala_opcion_costos_incluye_volumen    | t
            6 | check_escala_opcion_comp_incluye_volumen      | t
            7 | renglones_acero_gondola_por_volumen           | t
            8 | funcion_guardar_linea_receta_soporta_escala   | t
            9 | opcion_costos_tina_por_volumen                | t
           10 | opcion_personalizado_existe                   | t
           11 | opciones_fijas_desactivadas                   | t
(11 filas)

 todo_ok 
---------
 t
(1 fila)
```
Los 11 checks resultaron verdaderos (`t`). La base temporal fue eliminada al concluir la prueba.

---

## 4. Pruebas Unitarias y Validación del Repositorio

- **Pruebas Deno:** `283 passed | 0 failed` (se superó el piso anterior de 273 pruebas).
- **TypeScript:** `tsc --noEmit` arroja 44 errores históricos de types de componentes no relacionados (baseline permitido $\le 55$), sin errores en los archivos tocados.
- **Vite Build:** `npm run build` compila con éxito en 39s generando los bundles de producción sin fallos.
- **Arranque del API:** `deno cache index.ts` y arranque local en puerto 8000 exitosos.

---

## 5. Acciones Manuales Pendientes (para Luis tras merge a main)

1. **Supabase Cloud:**
   - Ejecutar en el SQL Editor la migración nueva:
     `supabase/migrations/20261106_01_gondola_volumen_libre.sql`
   - Opcionalmente correr `docs/gondola/verificacion_volumen.sql` para confirmar los 11 checks en verde.
2. **EasyPanel:**
   - Hacer clic en **Rebuild** en el servicio de backend (`remolques-api`).
   - Hacer clic en **Rebuild** en el servicio de frontend (`remolques-web`).

---

## 6. Ronda 2: Correcciones tras Revisión de Claude

**Referencia:** `COORDINACION/REVISIONES/GONDOLA_VOLUMEN_LIBRE_REVISION_CLAUDE.md` (Veredicto: CORREGIR)  
**Commits adicionales de la ronda:**
- `235c587` — `refactor(motor): redondeo unico a 1 decimal, parseo estricto de volumen y extractor compartido`
- `1204681` — `fix(ui): estado local de texto para tecleo de decimales y formateo de cotizaciones historicas`

### Punto 1. [ALTA] Tecleo de decimales en el campo de volumen
- **Causa raíz:** En `ConfiguradorEquipo.tsx` el valor del `<input>` se repintaba desde `String(valActual.m3)`. Al escribir `37.`, el número convertido era `37`, provocando la desaparición inmediata del punto decimal e impidiendo ingresar decimales como `37.5`, `37,5` o `38.0`.
- **Solución implementada:**
  1. Se introdujo un estado local desacoplado: `const [textoVolumenLocal, setTextoVolumenLocal] = useState<string>('')`.
  2. El `<input>` lee directamente de `value={textoVolumenLocal}` y su `onChange` actualiza el texto local al tiempo que genera la configuración mediante `valorDesdeTextoVolumen(txt)`.
  3. Se crearon las funciones puras `textoCampoVolumen(valor)` y `valorDesdeTextoVolumen(texto)` en `src/app/utils/volumenGondola.ts`.
  4. La sincronización desde configuración externa solo ocurre al inicializar/abrir el modal y al hacer clic en los atajos rápidos (`30 m³` y `45 m³`).
- **Prueba Deno ejecutada (salida real):**
```
running 1 test from ./src/app/utils/volumenGondola.test.ts
volumenGondola: Simulación de tecleo carácter por carácter (punto, coma, decimales) ... ok (365µs)
```
  - Secuencia `"37.5"` (`""` -> `"3"` -> `"37"` -> `"37."` -> `"37.5"`): el punto no se pierde en ningún paso y `m3` final es `37.5`.
  - Secuencia `"37,5"` (`""` -> `"3"` -> `"37"` -> `"37,"` -> `"37,5"`): la coma no se pierde y `m3` final es `37.5`.
  - Secuencia `"38.0"` (`""` -> `"3"` -> `"38"` -> `"38."` -> `"38.0"`): `m3` final es `38`.

### Punto 2. [MEDIA] Visualización limpia de cotizaciones históricas
- **Causa raíz:** Cotizaciones antiguas con clave de opción (`{ volumen: "m3_45" }` o `{ volumen: { opcion: "m3_30" } }`) mostraban el texto crudo `m3_45` o `m3_30` en el campo al reabrirse.
- **Solución implementada:**
  - `textoCampoVolumen(valor)` mapea explícitamente `"m3_45"` -> `"45"`, `"m3_30"` -> `"30"`, `opcion: "m3_45"` -> `"45"`, `opcion: "m3_30"` -> `"30"`.
  - Al abrir una cotización vieja, el campo muestra `"45"` o `"30"`, el estado se evalúa como `completo: true`, y los botones de atajo rápido se iluminan correctamente.
- **Prueba Deno ejecutada (salida real):**
```
running 1 test from ./src/app/utils/volumenGondola.test.ts
volumenGondola: Reapertura de cotizaciones viejas con clave histórica se visualiza limpia y completa ... ok (225µs)
```

### Punto 3. [ALTA] Redondeo único en el motor antes de validar rango
- **Causa raíz:** Múltiples redondeos o formateos tardíos en `formatearVolumenM3` o en el cálculo de escala podían generar discrepancias entre el volumen validado, el factor de costo y los títulos.
- **Solución implementada:**
  - En `supabase/functions/make-server-feea4382/motor/escalas.ts` (`resolverVolumenGondolaDetallado`): se aplica un único redondeo canónico `Math.round(numBruto * 10) / 10` sobre `numBruto` **antes** de validar rango `[20, 60]`, registrar advertencias `variante_supuesta` o calcular el factor `volumen / 45`.
  - En `src/app/utils/volumenGondola.ts` (`evaluarEstadoVolumen`): se aplica el mismo redondeo canónico idéntico.
- **Prueba Deno ejecutada (salida real):**
```
running 1 test from ./supabase/functions/make-server-feea4382/motor/gondola_volumen.test.ts
8. Redondeo único a 1 decimal en el motor antes de validar rango ... ok (2ms)
```
  - Casos verificados:
    - `37.25` -> `37.3` (dentro de rango, escala `37.3 / 45 = 0.828888...`)
    - `37.99` -> `38` (dentro de rango, escala `38 / 45 = 0.844444...`)
    - `19.96` -> `20` (redondea hacia arriba y entra en rango permitido)
    - `19.94` -> `19.9` (fuera de rango, cae a `volumen = 45` base con aviso `volumen_fuera_rango`)
    - `45`, `30` y `38`: valores enteros idénticos a hoy byte a byte.

### Punto 4. [MEDIA] Parseo estricto de texto y extractor compartido
- **Causa raíz:** La búsqueda parcial `matchSub` en `escalas.ts` permitía que cadenas inválidas como `"38abc"`, `"abc38"`, `"1e2"` o `"volumen_38"` fueran interpretadas como `38` o `1`. Además existían parseos paralelos entre backend y frontend.
- **Solución implementada:**
  - Se eliminó la rama `matchSub`.
  - Se implementó la regex estricta: `/^\s*([-+]?\d+(?:[.,]\d+)?)\s*(?:m3|m³)?\s*$/i`.
  - Se exportó la función unificada `extraerCandidatoVolumen(val): CandidatoVolumen` desde `escalas.ts`.
  - `volumenGondola.ts` en el frontend re-exporta y reutiliza la misma función compartida de `escalas.ts`.
- **Prueba Deno ejecutada (salida real):**
```
running 1 test from ./supabase/functions/make-server-feea4382/motor/gondola_volumen.test.ts
9. Parseo estricto de texto en escalas.ts (rechaza coincidencias parciales) ... ok (1ms)
```
  - Cadenas rechazadas (`numero = null`, cae a 45 m³ con aviso `volumen_invalido` o marca error en UI):
    - `"38abc"`, `"abc38"`, `"1e2"`, `"volumen_38"`, `"NaN"`, `"abc"`.
  - Cadenas aceptadas estrictamente:
    - `"38 m3"`, `"38 m³"`, `"38m3"`, `" 45 "`, `"37,5 m³"`.

---

### Resumen de Verificación Final (Ronda 2)

```
== 1. Archivos de parche o temporales nuevos
  OK     Sin parches ni temporales

== 2. Codificación de los archivos modificados
  OK     UTF-8 sin BOM ni mojibake — 20 archivos revisados

== 3. Sintaxis de .ts/.tsx modificados
  OK     Sintaxis válida

== 4. TypeScript (tsc --noEmit)
  OK     tsc: 0 nombres sin definir/duplicados
  OK     tsc: el total de errores no sube — 44 (baseline 55)

== 5. Build de Vite
  OK     npm run build

== 6. Pruebas Deno
  OK     Pruebas Deno — 289 pasan, 0 fallan

== 7. Arranque real del API
  OK     El API arranca — Listening on http://localhost:8000/

== 8. Contexto del Dockerfile.backend
  OK     Contexto del Dockerfile.backend — deno cache index.ts exitoso

== 9. Checkout limpio de HEAD (git archive)
  OK     Pruebas Deno en HEAD limpio — 289 pasan, 0 fallan
  OK     El API arranca en HEAD limpio — Listening on http://localhost:8000/

============================================================
RESULTADO: TODO OK  (11/11 comprobaciones)
```

