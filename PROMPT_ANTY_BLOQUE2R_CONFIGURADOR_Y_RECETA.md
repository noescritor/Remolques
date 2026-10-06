# Bloque 2R — Configurador de opciones y receta resuelta

Léelo completo antes de tocar código. Sustituye el enfoque del Bloque 2 (receta plana por producto) por uno que respeta cómo se vende y se fabrica de verdad.

## 0. Antes de empezar

1. Lee `AGENTS.md`, el último `CHANGELOG_ANTIGRAVITY.md`, `ANALISIS_MANUAL_Y_COTIZADOR_2026-10-06.md` (**todo**, sobre todo §3, §4.1 y §6), `docs/catalogo-opciones/catalogo_opciones_unificado.json` y `artifacts/propuesta_ux_sistemas.md` (sus ideas de UX se adoptan, ver §6).
2. **Reglas de proceso (no negociables):**
   - Una rama por sub-bloque (`bloque-2r-0`, `bloque-2r-1`…). **Nada directo a `main`. No hagas `git push` ni pidas Rebuild** hasta que Claude Code revise el diff y el dueño lo autorice.
   - Antes de **cada** commit: `git diff --stat` y revisar el diff completo. Si aparecen borrados que no pediste, detente.
   - Una entrada de changelog **por sub-bloque**, con "qué no se probó". Los 13 commits del Bloque 2 anterior solo dejaron una entrada; no se repite.
   - Verificaciones por sub-bloque: `npm run build`, `tsc --noEmit` (instala `typescript`), `deno check` del backend, y **diff de rutas del backend** contra la rama base (solo deben aparecer las nuevas).
   - Los SQL **no se corren solos**: se entregan en `supabase/migrations/` y en el changelog dices el orden exacto y quién los corre (el dueño).
   - Ediciones puntuales. Nada de reescrituras masivas por script. Rutas Hono nuevas: `const supabase = c.get("supabase") as any;` dentro del `try`, **después** de `authMiddleware`.
   - Tokens semánticos de Tailwind (nada de `orange-500`, `slate`, hex nuevos). Sin llaves en archivos.
3. **Un solo camino de datos:** el navegador **no** consulta Supabase directo (hoy `ModeloConfiguratorModal` lo hace y usa `localStorage`). Todo pasa por la API.

## 1. Decisiones ya tomadas por el dueño (no las reabras)

| # | Decisión |
|---|---|
| D1 | **Se cotizan todas las variantes.** La cotización que se envía muestra solo un **resumen** de especificaciones; el **presupuesto completo** (tornillería, luz, aire, pintura…) se genera **al aprobar**. |
| D2 | **Precio sugerido:** costo + margen configurable **por tipo de modelo** (valores iniciales del Excel: plataforma $110,000, dolly $40,000, en pesos). El vendedor puede ajustarlo y queda registrado el **margen real** (precio final − costo). No es un porcentaje fijo. |
| D3 | **Cantidades por unidad:** la cantidad escrita en la receta es el **total para esa unidad** de referencia (2 ejes, 40 ft). Se escala solo cuando la línea lo indica (`por_eje`, `por_largo`). El encabezado del manual ("2 PARES", "2 PZA") es informativo. *Esto se valida con el dueño al final del §3 (tabla de verificación).* |
| D4 | **Modelos a soportar:** plataforma (10 variantes), dolly, **góndola**, **jaula**, **caja seca** y traila. Jaula y caja seca **no tienen receta capturada** en ningún archivo: el sistema debe permitir crearlas (editor/importación), no inventarlas. |
| D5 | **Catálogo de opciones único** = `docs/catalogo-opciones/catalogo_opciones_unificado.json` (unión sin repeticiones de las dos listas). Precio principal = TARIFARIO; los demás precios quedan como "otros precios" para revisión. |
| D6 | Los **precios de ~230 materiales** aún no existen. Nunca se muestra un costo 0 como si fuera real: lo que no tenga precio se marca **"sin precio"** y bloquea el cálculo de costo total con un aviso visible. |

## 2. Sub-bloque 2R-0 — Contención (hoy mismo, antes que cualquier otra cosa)

> **CORRECCIÓN (6-oct, tras el diagnóstico del dueño en producción).** La premisa de este apartado era que `20261005_01_recetas_nuevas.sql` se había aplicado. **No fue así**: `productos` solo tiene el índice `productos_pkey` (no hay índice único sobre `nombre, organizacion_id`), así que su `ON CONFLICT (nombre, organizacion_id)` falla y la transacción se deshace entera; en producción hay 144 materiales (no los 227) y no existe la receta "PLANA 40 FT 2 EJES CON RETRACTIL". **No volver a correr ese archivo.**
> Lo que **sí** está en producción es la migración del **1-oct** (`20261001_03_migracion_bom.sql`, commit `c668f22`): 23 productos terminados (10 `PLATAFORMA n FT` + otros) con recetas de ~65 líneas. Defectos verificados en el archivo: (a) los **8 pisos sumados** (pino ×3, encino, plástico, 2 laminados, antiderrapante, "sin piso"); (b) **precio cargado como cantidad**: el archivo carga `MANO DE OBRA PISO` = 3000 y `MONTADA DE LLANTAS` = 50, pero **esas líneas no llegaron a producción** (el diagnóstico `01c` da 0 líneas de mano de obra); sí llegó **una** línea con cantidad 5450 en `PLATAFORMA 2 35 FT` (un precio de "sistema retráctil" tomado como cantidad); (c) valores por defecto de 2 ejes en variantes de 3 ejes; (d) 16-22 líneas por producto **omitidas en silencio** (65-68 de 81-87 líneas porque cada `INSERT` se salta si el material no existe). **Diagnóstico `01c` en producción:** las 10 plataformas tienen 65-68 líneas y **6 líneas de piso sumadas** (no 8). Además hay **13 "productos terminados" sin receta** que no son modelos de Leolca: piezas mal clasificadas (`Eje de 3500 lbs`, `Gato manual 5000 lbs`, `Llanta 22.5` y su copia `…20260917195452`, `Llanta Rin 15 6 Birlos`, `Placa de Acero 1/8"`, `Tirón Bola 2"`, `VARILLA NIVELADORA A14187`, `Viga IPR 10"` y su copia) y 3 remolques que parecen de demostración (`Cama Baja 18ft`, `Cuello de Ganso 24ft`, `Ganadero 14ft`). **No los toques** hasta que el dueño confirme; en 2R-1 se reclasifican o archivan con su aprobación, sin borrar nada.
> **Limpieza aprobada para 2R-0:** el archivo `docs/remediacion/02b_correccion_recetas_1oct.sql` (con respaldo interno y guarda de 659 líneas). Úsalo en lugar del esqueleto de `02_correccion_recetas_PENDIENTE.sql`; el dueño lo corre, tú no. Todo en la organización `00000000-0000-0000-0000-000000000001`, que es la **única** y la misma de las cotizaciones: no hay desajuste de organización.
> Donde abajo dice "la migración del 5-oct" o "la Plana 40 ft con 10 piernas y 56 rines", tómalo como **análisis del manual** (qué pasaría al aplanarlo), no como estado de producción. La limpieza de 2R-0 apunta a **las recetas del 1-oct**. El dueño correrá `docs/remediacion/01c_productos_terminados.sql` y te pasará las filas antes de que escribas el `DELETE`.

Hechos verificados (sobre el archivo del 5-oct y sobre el backend):

- La receta plana de la Plana 40 ft **suma todas las opciones**: 10 piernas y 10 platos de suspensión, 10 ejes, 56 rines, 32 llantas, 3 marcas de pintura, 3 ganchos, 2 sistemas retráctiles.
- Los materiales repetidos (34 en la Plana) quedaron con **solo la primera cantidad** (`ON CONFLICT DO NOTHING` sobre `UNIQUE(producto_id, material_id)`).
- **`calcularRequisicion` nunca calcula nada:** hace `select('*')` de `cotizaciones` y lee `cot.items`, pero los conceptos están en `items_cotizacion`; devuelve `[]` siempre. Resultado: "no faltan materiales" para toda cotización.
- `sub_items` **no se guarda** (no está en `toItemCotizacionRow` ni en `metadata`): existe solo en el editor y en la impresión.
- La migración usó `(SELECT id FROM organizaciones LIMIT 1)`: puede haber asignado los productos a la organización equivocada.

Tareas **en este orden**:
1. **No agregar `sub_items` desde la receta plana.** En `CotizacionEditor.agregarItemDesdeProducto` y en `ModeloConfiguratorModal` deja de cargar `producto_materiales` como sub-ítems. El item se agrega sin receta hasta que exista el motor (2R-2).
2. **`calcularRequisicion` debe fallar a la vista, no devolver `[]`:** léela desde `items_cotizacion` (con `producto_id` y `metadata.configuracion`) y, si un concepto es producto terminado **sin configuración resuelta**, devuelve un estado `sin_receta` por concepto que el frontend muestre como aviso ("Falta configurar este equipo"). **Elimina el respaldo a `producto_materiales`** (leería la receta mala). Hasta 2R-2 esto es solo contención.
3. El dueño corre `docs/remediacion/01_diagnostico_recetas.sql` y te pega el resultado. **No corras tú nada contra producción.** Con el resultado, revisa `02_correccion_recetas_PENDIENTE.sql`; solo se corre con **respaldo previo** (hoy producción no tiene respaldos automáticos: es prerrequisito, confírmalo en el changelog).
4. Entrada de changelog con el resultado del diagnóstico.

## 3. Sub-bloque 2R-1 — Esquema e importación

Migración nueva `supabase/migrations/2026MMDD_01_configurador_recetas.sql` (idempotente, en transacción). Tipos: `productos.id` es **TEXT**; `organizaciones.id` es **uuid**; las tablas nuevas usan `uuid` propio y `organizacion_id uuid` con la misma RLS (`get_current_org_id()`). Verifica cada tipo con `grep` en las migraciones, no asumas.

| Tabla | Para qué | Campos clave |
|---|---|---|
| `modelos` | Variante vendible ligada a un producto terminado | `producto_id` (TEXT → `productos`), `tipo` (plataforma/dolly/gondola/jaula/caja_seca/traila), `largo_ft`, `num_ejes`, `datos_tecnicos jsonb` (peso, PBVD, ABS, CDE, ancho, longitud), `activo` |
| `grupos_configuracion` | Un grupo de opciones por tipo de modelo | `clave`, `nombre`, `seleccion` (unica/multiple/cantidad/derivada), `aplica_a text[]`, `orden`, `depende_de` (clave de otro grupo), `regla jsonb`, `obligatorio` |
| `opciones_configuracion` | Opciones de un grupo | `grupo_id`, `clave`, `nombre`, `aliases text[]`, `precio_venta`, `medidas jsonb`, `clase` (p. ej. alta/normal), `activo`, `notas` |
| `opcion_componentes` | Qué materiales trae una opción | `opcion_id`, `material_id` (TEXT), `cantidad`, `escala` (`fija`/`por_eje`/`por_largo`), `rol` (`componente`/`sustituto`/`independiente`), `paso`, `uso` (kit), `seccion`, `condicion jsonb` |
| `receta_base` | Líneas fijas por variante | `modelo_id`, `material_id`, `cantidad`, `escala`, `paso`, `uso`, `seccion`, `condicion jsonb` |
| `material_proveedores` | Hasta N precios por material | `material_id`, `proveedor_id`, `precio`, `unidad`, `vigente_desde`, `preferido` |
| `parametros_costeo` | Valores que hoy están pegados en el Excel | `clave`, `valor jsonb`: `precio_acero_kg`, `margen_sugerido` por tipo, `gastos_indirectos_pct`, `iva_pct` |

- **Sin `UNIQUE(modelo, material)`** en `receta_base`: un mismo material puede aparecer en varios pasos. Se **suma** al resolver.
- **`condicion`** (jsonb) es un mini-lenguaje cerrado: `{"todas":[{"campo":"ejes","op":"=","valor":3},{"campo":"gancho","op":"!=","valor":"sin_gancho"}]}`. Campos posibles: `ejes`, `largo_ft`, `retractiles`, y la opción elegida de cualquier grupo (`gancho`, `suspension`, `redilas`, `piso`…). Nada de código arbitrario.
- `seccion` = una de las secciones del presupuesto: `acero`, `piramide`, `truckzone`, `otros`, `piso`, `extras`, `rines_llantas`, `manoobra`, `indirectos`, `adicionales` (ya existen) **más** `tornilleria`, `luz`, `aire`, `pintura` (nuevas; amplía `PresupuestoDatos` de forma retrocompatible).
- `paso` = `PASO 1…6`, `LIMPIEZA`, `PINTURA`, `AIRE`, `LUZ`, `TERMINADO`, `EXTRAS` (son las fases reales del Kanban).

**Importación (dos fuentes, sin tocar producción desde tu máquina):**
1. **Opciones:** `docs/catalogo-opciones/catalogo_opciones_unificado.json` → `grupos_configuracion` + `opciones_configuracion`. Respeta `aliases`, `medidas` (frente) y `otros_precios` (guárdalos en `notas`/`datos`, no se descartan). Las opciones sin precio se importan con `precio_venta = NULL` y se muestran como "sin precio".
2. **Recetas del manual:** `docs/manual-recetas/lineas_parseadas.json` (673 filas ya separadas en `proceso`, `cantidad`, `unidad`, `producto`, `estatus_o_uso`, `proveedores`) y `MANUAL.xlsx`. Reglas de lectura, **verificadas contra las hojas**:
   - Una fila con `tipo = grupo_opcion` (`TIPO DE SUSPENSION`, `TIPO DE PATIN`, `TIPO DE EJE`, `TIPO DE GANCHO`, `TIPO DE BOLSA RETRACTIL`, `TIPO DE RINES…`, `TIPO DE LLANTAS…`, `TIPO DE SISTEMA RETRACTIL`, `TIPO DE PINTURA`) abre un grupo; las filas siguientes son **opciones o componentes de opciones**, no líneas fijas.
   - Dentro de `TIPO DE SUSPENSION`, `tipo = opcion_suspension` (`1 SUSPENSION HENDRICKSON HT300US…`) abre una opción y las filas siguientes son **sus componentes** hasta la siguiente. La columna **ESTATUS** da el `rol`: `COMPONENTE`, `SUSTITUTO`, `INDEPENDIENTE`.
   - En `TIPO DE PINTURA`, `opcion_pintura` (`PINTURA SHERVI/PPG/AXALTA`) abre la opción; los litros dependen del modelo.
   - Todo lo demás es **línea fija** (`receta_base`) con su `paso` (la columna PROCESO, arrastrando el último valor) y su `uso` (la columna ESTATUS, p. ej. `KIT DE GANCHO`).
   - `Bolsa retráctil` depende de `retractil` (grande ↔ chico). `Dona` (dolly) depende de `gancho`.
   - **Duplicados:** un mismo material repetido en la **misma** receta/opción se **suma**; nunca `DO NOTHING`.
   - **Unidades:** `1 L`, `150ML`, `2,5 M`, `3 M` se separan en cantidad + unidad. Cantidades como `1 PZA` o `2 PARES` en encabezados son informativas.
   - **Nombres:** unifica con una tabla de alias las variantes de escritura (p. ej. `MICRO ALAMBRE`/`MICROALAMBRE`, `TUERCA DE SEGURIRAD`/`SEGURIDAD`, `TE UNIO`/`TE UNION`, `RONDANA PLANA`/`RONDANAS PLANAS`, `GADO`/`GRADO`, `HOLAND`/`HOLLAND`, `FLET`/`FLEET`). **Las medidas distintas son materiales distintos** (`TUERCA 3/8` ≠ `TUERCA 5/8`).
   - **Reutiliza** los 227 materiales ya cargados (`productos`, `tipo_item='materia_prima'`) y fusiona duplicados: no crees materiales nuevos si existe uno equivalente.
3. **Escalado por variante:** `BASE DAT PLANAS` del cotizador tiene las cantidades de acero por variante (35–48 ft × 2/3 ejes) y los consumibles escalan **largo/40** (35→0.875, 42→1.05, 45→1.125, 48→1.2). Marca esas líneas con `escala = 'por_largo'`. Suspensión, ejes, ABS, rines y llantas: `por_eje` (3 ejes: ×1.5; llantas de 8 a 12).
4. **Informe de importación** (archivo `docs/importacion/INFORME_2R1.md`): líneas leídas, líneas asignadas (fija / opción / regla), líneas **sin asignar** (lista), alias aplicados, materiales fusionados, y los **conflictos de precio** del catálogo. Las líneas sin asignar se **listan**, no se descartan ni se adivinan.
5. **Hardware que está en `TORNILLERIA` y no en ninguna receta** (bicicletero, caja auxiliar, manivela, placa de logo, tapa de chamber, bisagra del pistón, kits de cámara de suspensión): inclúyelos en el informe como **"faltan en la receta"**, para que el dueño decida.

**Tabla de verificación (entrega obligatoria al cerrar 2R-1):** para **Plana 40 ft, 2 ejes, suspensión alta Hendrickson, retráctil grande, gancho Holland**, imprime las cantidades resueltas de piernas, platos, amortiguadores, cámaras, abrazaderas, ejes, patines, rines, llantas, `CONSUMIBLE 65` y `jalón`. El dueño las compara con la realidad. Un valor que ya conocemos: `CONSUMIBLE 65` suma 0.5 + 0.25 + 0.25 = **1.0**, que coincide con `BASE DAT PLANAS`.

## 4. Sub-bloque 2R-2 — Motor y pruebas

- Función pura **`resolverReceta(modelo, configuracion)`** → `[{material_id, cantidad, unidad, seccion, paso, uso, origen}]` (origen = `base` | `opcion:<grupo>/<opcion>`). Vive en un módulo propio del backend (no dentro de una ruta) para poder probarla sin base de datos.
- Reglas: exactamente **una** opción por grupo `unica`; valida `depende_de` (p. ej. retráctil grande exige suspensión alta) y devuelve errores legibles; aplica `escala`, `condicion`, `rol` (los `sustituto` no se suman a su componente) y **suma** líneas repetidas.
- Rutas nuevas (protegidas): `GET /modelos`, `GET /modelos/:id/configuracion` (grupos y opciones habilitadas), `POST /configuracion/resolver` (devuelve receta + costo + faltantes de precio).
- **Pruebas automáticas** (Vitest o Deno test, nuevas, que corran en el build): (1) cada grupo exclusivo aporta una sola opción (no 5 suspensiones); (2) rines = 8 con 2 ejes y 12 con 3; (3) `sin_gancho` ⇒ jalón 0; (4) con redilas suma los 444 tornillos y 6 L de pintura; (5) 42 ft ⇒ consumibles ×1.05; (6) opción incompatible (suspensión alta + retráctil chico) ⇒ error; (7) material repetido se suma, no se pierde; (8) un material sin precio ⇒ aparece en `sin_precio` y el costo total no se presenta como completo.
- `calcularRequisicion` usa `resolverReceta` sobre cada concepto de `items_cotizacion` con `metadata.configuracion`.

## 5. Sub-bloque 2R-3 — Configurador en la cotización

- El concepto de cotización guarda `metadata.configuracion` = `{variante: {largo_ft, ejes}, grupos: {suspension: "alta_hendrickson", rines: {opcion: "acero", cantidad: 8, medida: "24.5"}, adicionales: [...]}}`. No cambia la tabla; usa el `metadata jsonb` existente (agrégalo a `toItemCotizacionRow`).
- Pantalla: eliges **modelo y variante**, y aparecen **solo los grupos que aplican a ese tipo** (el dolly no ve patín ni piso). Sin opciones inválidas (las incompatibles aparecen deshabilitadas con el motivo).
- **Texto de especificación automático** ("SEMIREMOLQUE TIPO: PLATAFORMA 40 FT 2 EJES, CON SUSPENSIÓN ALTA HENDRICKSON, EJES FLEET MASTER, 2 PAR DE PATÍN HJ…") generado de las opciones, igual que hoy lo arma el Excel. Sin escribirlo a mano.
- **Precio sugerido** = costo (suma de `precio_venta` de las opciones, tarifario) + margen del tipo de modelo; campo editable; muestra siempre **costo, precio y margen real**.
- **Cotización resumen (PDF Leolca, ya existe):** Estructura, Ejes, Suspensión, Patines, Frenos, Instalación eléctrica, Frente, Redilas, Piso, Pintura, Rines, Llantas, precio IVA incluido, nota y forma de pago. **No** lista la tornillería.
- Reemplaza `localStorage('pending_cpq')` y el acceso directo a Supabase por llamadas a la API.

## 6. Sub-bloque 2R-4 — Presupuesto completo al aprobar y costos

- Al pasar la cotización a **Aprobada** (portal o manual) se **genera el presupuesto** con `resolverReceta`: secciones (las 10 existentes + tornillería, luz, aire, pintura), cantidades resueltas y costo por línea. Se guarda **congelado** (con la fecha de los precios usados). No se recalcula solo si cambia un precio.
- UX del presupuesto (de `artifacts/propuesta_ux_sistemas.md`, que se adopta): **secciones colapsables** con conteo y subtotal por sección; botones con texto explícito (nada de "tres puntitos" para acciones críticas); indicador permanente "Guardado/Sincronizado"; alerta roja visible "Faltan precios en N materiales"; el costo unitario **no se edita desde la cotización**, solo en el catálogo.
- **Costos:** `material_proveedores` con hasta N proveedores por material y uno **preferido**; costo = precio del proveedor preferido. Pantalla y plantilla de **importación de precios** (CSV/Excel) con las columnas del manual: material, proveedor, precio, unidad, fecha. Importar nunca pisa en silencio: muestra un resumen de cambios para confirmar.
- **Parámetros** (`parametros_costeo`): precio del acero por kg (hoy 43 y 34), margen por tipo, indirectos (2.5 % de la **suma real**; en el Excel era un número pegado), IVA. Pantalla simple para editarlos.
- **No** dupliques el módulo Presupuestos: extiéndelo. `PresupuestoEditor` y `presupuestoTemplate.ts` ya tienen las secciones; reutilízalos.

## 7. Sub-bloque 2R-5 — Góndola, jaula, caja seca

- **Góndola:** une dos fuentes: la receta del manual (hoja GONDOLA) y el **costeo con precios** del CSV (`artifacts/raw_bom.csv`, líneas ~542 en adelante: despiece de **chasis** y de **tina**, equipamiento, kit de aire, pistón $55,825, etc.). Opción `tina_material`: A-36 / Hardox 450 (vueltas y cuellos son placa Hardox; el resto A-36). Hoy solo quedaron 8 líneas; hay que cargar el despiece completo.
- **Jaula y caja seca:** crea los modelos y las variantes que el dueño indique; el sistema debe incluir un **editor de receta** (agregar líneas por paso, opciones y condiciones) y/o importación CSV con la misma plantilla. **No inventes material.** Mientras no tengan receta, el modelo aparece como **"Receta pendiente"** y no permite aprobar una cotización con él sin aviso.
- **Plantilla de captura:** entrega un `.csv` de ejemplo (columnas: modelo, paso, grupo, opción, rol, material, cantidad, unidad, escala, condición) para que el dueño llene jaula y caja seca.

## 8. Fuera de alcance de este bloque

Reservas de inventario, recepción parcial de compras, BOM congelado por **unidad (chasis/NIV)**, pagos por chasis, contrato y carta factura SCT (van en el Bloque 3). Tampoco toques seguridad (llaves, portal, `/supa-proxy`): tienen su propio bloque.

## 9. Entrega y verificación (cada sub-bloque)

En el changelog: archivos tocados, qué cambió y por qué, **SQL a correr (orden exacto)**, si hace falta Rebuild, cómo probarlo con pasos concretos y **qué no se probó**. Al cerrar el 2R-2 incluye el resultado de las 8 pruebas. Avisa a Claude Code para revisar el diff **antes** de cualquier push.
