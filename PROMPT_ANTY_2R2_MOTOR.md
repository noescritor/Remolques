# Prompt para Anty — Sub-bloque 2R-2: motor de recetas (`resolverReceta`) + pruebas + 3 rutas

Contexto: `main` está en `8102647`. En **producción** ya están cargados: esquema del configurador, catálogo (20 grupos / 126 opciones), 10 modelos de plataforma y la receta de plataforma sin precios (141 líneas `receta_base` por modelo, 99 `opcion_componentes`, 173 materiales nuevos con costo 0). Lee `PROMPT_ANTY_BLOQUE2R_CONFIGURADOR_Y_RECETA.md` §4, `ANALISIS_FACTURA_LEOLCA_2026-10-07.md` y `docs/importacion/INFORME_2R1B.md`.

## Alcance
**Entra:** función pura `resolverReceta`, sus pruebas automáticas, un cargador de datos y 3 rutas de solo lectura.
**NO entra:** frontend, `calcularRequisicion` (se integra en un bloque aparte), `aplicarAprobacion`, ni ninguna ruta o función existente. Nada de SQL en producción ni migraciones nuevas (si crees que hace falta una, **detente y avisa**).

## Reglas
Rama `bloque-2r-2` desde `main`. **Prohibido:** `git reset --hard`, `clean`, `checkout`/`restore`/`stash`, `commit -am`, `--amend`, y **cualquier script de parche o `node -e` para reescribir archivos**. `git add` explícito. Changelog con tu herramienta de edición (entrada nueva **arriba**, sin tocar las ajenas). No push ni merge: yo reviso primero. No quites ni cambies lo que el prompt pide sin avisarlo en el reporte.

## 1. Datos reales con los que trabajas (verificados en la base)
- **Escala:** las cantidades de `receta_base` y `opcion_componentes` están guardadas para la referencia **40 ft / 2 ejes**.
  - `fija` → cantidad tal cual.
  - `por_largo` → `cantidad × largo_ft / 40` (35 → 0.875, 42 → 1.05, 43 → 1.075, 45 → 1.125, 48 → 1.2).
  - `por_eje` → la cantidad guardada es **por eje**: `cantidad × num_ejes` (piernas de suspensión 1 → 2 con 2 ejes y 3 con 3; rines/llantas 4 → 8 y 12).
- **Roles** (en `opcion_componentes.rol`): `componente` e `independiente` **se incluyen**; `sustituto` **no se incluye** por defecto: se reporta en `alternativas` (por ejemplo `AMORTIGUADOR MONRROE 65512` frente al `HENDRICKSON 23743`). Esto es la lectura del manual más probable; déjalo documentado como "pendiente de confirmar con producción".
- **Condiciones** (`receta_base.condicion`, jsonb): `{"todas":[{"campo","op","valor"}]}` con `op` en `=`, `!=`, `in`. `campo` puede ser cualquier clave de grupo de la configuración, `ejes` o `largo_ft`.
  - Una condición `{"sin_mapear": "<texto>"}` significa **línea excluida hasta que el dueño decida**. Va a `omitidas` con su texto, **nunca** a la receta.
- **Grupos** (`grupos_configuracion.seleccion`): `unica`, `unica_con_medida` (frente), `unica_con_cantidad` (rines, llantas), `cantidad` (plafones), `derivada` (abs), `multiple_con_cantidad` (adicionales), `multiple`.
- **Rines con marca:** `rines/acero` y `rines/aluminio` guardan **todas las marcas como componentes alternativos** (acero: Fleet Master, Acurrai, Ampro; aluminio: Fleet Master, Fleet Master trapezoidal, Ampro, Ampro trapezoidal). Si el motor las suma todas saldrían **24 rines en vez de 8**. La configuración debe traer `marca` (`{"rines":{"opcion":"acero","marca":"ampro"}}`): el motor elige **solo** el componente cuyo nombre contiene esa marca (normalizada, con alias) y devuelve error legible si falta la marca o no coincide con una sola.
- **Cantidad en grupos `unica_con_cantidad`:** si la configuración trae `cantidad`, ese es el **total** (no se escala por eje); si no, se usa la escala por defecto (4 por eje).
- **Opciones sin receta:** muchas opciones del catálogo **no tienen componentes** hoy (piso, frente, matracas, riel, llantas excepto 4 marcas, color, abs, adicionales, dona, quinta, `phm`/`hj_alta`/`alta_fleet_master`…). El motor **no puede fallar en silencio** ni presentar una receta incompleta como completa.
- **Despiece de acero:** hoy no existe para ninguna variante (2R-1c). El motor debe declarar siempre `secciones_pendientes: ["acero"]` y `completo: false` mientras no haya despiece.
- **Costo:** `productos.costo` del material. Los 173 materiales nuevos tienen costo 0 y descripción `SIN PRECIO`: cuentan como **sin precio** (costo 0 con `descripcion = 'SIN PRECIO'`, o NULL).

## 2. Entregables

### A. Módulo puro `supabase/functions/make-server-feea4382/motor/resolver_receta.ts`
Sin imports de Hono, ni Supabase, ni red: recibe datos y devuelve datos. Firma orientativa:

```ts
resolverReceta(datos: DatosModelo, configuracion: Configuracion): Resultado
```
- `DatosModelo`: modelo (`id, tipo, largo_ft, num_ejes`), `receta_base[]` (con material: `id, nombre, unidad, costo, descripcion`), `grupos[]`, `opciones[]`, `opcion_componentes[]`.
- `Configuracion`: `{ grupos: { suspension: "alta_hendrickson", rines: { opcion, marca, cantidad? }, adicionales: [...] } }`.
- `Resultado`:
  - `lineas[]`: `{ material_id, nombre, cantidad, unidad, paso[], uso[], seccion, origen[] }`. **Líneas repetidas del mismo material y unidad se suman** (conserva la lista de pasos y orígenes). `origen` = `base` o `opcion:<grupo>/<opcion>`.
  - `omitidas[]` (condición `sin_mapear`, con texto), `alternativas[]` (sustitutos), `advertencias[]` (opciones sin receta, `unica_con_cantidad` sin dato, etc.), `errores[]` (compatibilidad, falta de grupo obligatorio, marca faltante).
  - `sin_precio[]`, `costo_parcial`, `completo` (**false** si hay `errores`, `advertencias` de opción sin receta, `sin_precio` o `secciones_pendientes`), `secciones_pendientes`.
- Validaciones: **exactamente una** opción por grupo `unica`; grupos obligatorios presentes; compatibilidad. El campo `grupos.regla` es **texto**, no sirve para ejecutar: implementa las reglas como una **tabla en código documentada** (`reglas_compatibilidad.ts`): suspensión de clase `alta` exige retráctil `grande` y de clase `normal` exige `chico` (cuando el retráctil elegido no es `sin_retractil`/`paleta`); `dona` debe corresponder al gancho. Las claves salen del catálogo (`clase` de cada opción), no se escriben a mano.

### B. Cargador `motor/cargar_datos.ts`
Una función `cargarDatosModelo(supabase, modeloId)` que consulta `modelos`, `receta_base` (+ `productos`), `grupos_configuracion`, `opciones_configuracion`, `opcion_componentes` y devuelve `DatosModelo`. Es la **única** parte con acceso a datos. Sin escribir nada.

### C. 3 rutas nuevas en `index.ts`, **después** de `authMiddleware` (usa `c.get("supabase")`)
- `GET /modelos`: lista de modelos con `largo_ft`, `num_ejes`, nombre del producto.
- `GET /modelos/:id/configuracion`: grupos y opciones que aplican a ese tipo (`aplica_a`), con `seleccion`, `precio_venta`, `clase` y si la opción **tiene receta** o no.
- `POST /configuracion/resolver`: `{ modelo_id, configuracion }` → `Resultado`.
Respuestas con errores legibles y códigos HTTP correctos (400 para configuración inválida, 404 si no existe el modelo). **No** toques las rutas existentes: el diff de rutas contra `main` debe mostrar solo las 3 nuevas. Pega ese diff.

### D. Pruebas automáticas `motor/resolver_receta.test.ts` (Deno test)
Sin base de datos. Las fixtures se generan con **un script reproducible** `scripts/generar_fixture_motor.cjs` a partir de `docs/importacion/clasificacion_2R1b.json` y `docs/catalogo-opciones/catalogo_opciones_unificado.json` (guárdalas en `motor/fixtures/`). Pruebas mínimas, con los valores reales:
1. **Un grupo exclusivo, una opción:** con `suspension: alta_hendrickson` no aparece ningún componente de `hendrickson`, `fleet_master`, `ampro` ni `fcr` (no 5 suspensiones).
2. **`por_eje`:** 2 ejes → piernas de suspensión = 2, ejes = 2, rines = 8; 3 ejes → 3, 3, 12.
3. **`unica_con_cantidad`:** con `cantidad: 6` el total es 6 (no se escala).
4. **`sin_gancho`:** no hay gancho ni líneas con `uso = KIT DE GANCHO`; con `holland_8_10` sí.
5. **Redilas:** con `80` suma 444 tornillos cabeza de coche, 444 tuercas, 444 rondanas y 48 chavetas; con `sin_redilas`, ninguno. (La pintura de redilas, "6 L" en el catálogo, **no está** en la receta importada: repórtala como pendiente, no la inventes.)
6. **Escala por largo:** `CONSUMIBLE 65` = 1.0 con 40 ft; 0.875 con 35; 1.05 con 42; 1.075 con 43; 1.125 con 45; 1.2 con 48.
7. **Incompatibilidad:** suspensión alta + retráctil chico → error; normal + grande → error; alta + grande → ok.
8. **Suma de repetidos:** un material repetido en receta base y en una opción aparece **una vez** con la cantidad sumada (usa un caso real de la receta; pega cuál).
9. **`sin_mapear`:** las líneas `SI LLEVA LATERALES Y ESTRIBO` y `SI ES MULTIMODAL…` **no** están en `lineas` y sí en `omitidas`.
10. **Operador `in`:** las líneas `AMORTIGUADOR DE ALTA` aparecen con `alta_hendrickson` y **no** con `hendrickson`.
11. **Sustitutos:** `AMORTIGUADOR MONRROE 65512` no está en `lineas`; sí en `alternativas`.
12. **Marca de rines:** `rines/acero` sin marca → error; con `marca: "ampro"` → solo `RIN DE ACERO AMPRO`, cantidad 8 (2 ejes).
13. **Opción sin receta:** `piso: laminado` → `advertencia`, `completo: false`.
14. **Precios:** materiales nuevos con costo 0 aparecen en `sin_precio` y `costo_parcial` **no** se marca como completo; `secciones_pendientes` contiene `"acero"`.
15. **Control cruzado:** para 40 ft / 2 ejes con la configuración del Excel (Fleet Master HT-300 normal ×2, ejes Fleet Master, patín HJ, retráctil chico) imprime la tabla de cantidades resueltas (piernas, platos, amortiguadores, cámaras, abrazaderas, ejes, patines, rines, llantas, `CONSUMIBLE 65`). Yo la comparo con `Factura Leolca.xlsx` (suspensión ×2, ejes ×2, patines HJ ×2).
Agrega `"test:motor": "deno test supabase/functions/make-server-feea4382/motor/"` al `package.json` (o documenta el comando exacto si Deno no está en el PATH).

## 3. Verificación (pega salidas reales)
1. `git diff --numstat main`: archivos nuevos + `index.ts` (solo líneas añadidas) + changelog.
2. **Diff de rutas contra `main`:** solo `GET /modelos`, `GET /modelos/:id/configuracion`, `POST /configuracion/resolver`. Ninguna otra ruta cambia.
3. `deno test` completo con la lista de las 15 pruebas en verde.
4. `deno check` filtrado por `TS2304` ("Cannot find name"): 0. (Los otros ~132 errores de tipado de Hono son ruido ya conocido.)
5. `tsc --noEmit` filtrado por "Cannot find name": 0. `npm run build`.
6. `iconv -f UTF-8 -t UTF-8` en todos los archivos nuevos.
7. La tabla del control cruzado (prueba 15).

## 4. Qué haré yo
Reviso el diff y corro tus pruebas. Además corro **las consultas del cargador** contra mi Postgres local con el esquema real, para comprobar que devuelven lo que el motor espera. Si todo pasa, autorizo el push.
