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
