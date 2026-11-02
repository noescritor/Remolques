# Prompt para Anty — Turno de noche 2026-11-02 (7 tareas en cola, con revisión de Claude Code en paralelo)

Hoy trabajas solo durante varias horas. Yo (Claude Code) reviso lo que vayas entregando contra mi Postgres 17 local y te dejo veredictos por escrito. **No podemos hablar en directo: nos comunicamos con archivos en `COORDINACION/`.** Lee primero esa carpeta (`LEEME.md`, `COLA.md`, `ESTADO.md`).

Luis (el dueño) quiere esto lo más rápido posible, pero **prefiero 4 tareas bien hechas y probadas que 7 a medias**. Si no alcanzas, lo que quede se marca `PENDIENTE` y se sigue otra noche.

---

## 0. Reglas duras de la noche (no negociables)

1. **Nada toca producción.** No ejecutes SQL contra Supabase Cloud, no abras la app apuntando a producción para escribir (`client.ts`/`BASE_URL` están fijos a EasyPanel: para probar UI usa datos de prueba/fixtures o solo lectura), no toques EasyPanel. Todo SQL queda en archivos para que Luis lo corra mañana.
2. **Nada se mergea a `main`.** Aunque yo escriba `APROBADO`, el merge lo hacemos con Luis en la mañana. Cada tarea vive en su rama.
3. **Ramas:** una por tarea, `noche-t1-catalogo`, `noche-t2-despiece`, etc. Parte de `main` actualizado (`ccff3d5`). T3 y T6 dependen de T2: crea su rama **desde la rama de T2**.
4. **Git:** commits nuevos, nunca `--amend`, `reset`, `checkout`/`restore`, `stash`, `clean`, `commit -am`, `git add -A`. Agrega archivos por nombre.
5. **Edita solo con tu herramienta de edición/creación de archivos.** Nada de `sed`, `node -e`, `deno eval`, PowerShell `Set-Content`, ni scripts de parche sueltos en la raíz (los generadores van en `scripts/`, sin llaves incrustadas).
6. **Bitácora:** cada tarea deja su entrada en `CHANGELOG_ANTIGRAVITY.md` (arriba, con la plantilla del archivo).
7. **No commitees datos de clientes ni XML reales:** agrega `Normas/` y `XML_FACTURAS/` a `.gitignore` en T0. La carpeta `Normas/` contiene RFC y domicilios de clientes.
8. **Tokens semánticos de Tailwind** (`bg-card`, `text-foreground`, `border-border`…), nunca colores oscuros fijos. Íconos Lucide. Mobile sin scroll horizontal de página.
9. **Sin dependencias nuevas** salvo que sea imprescindible (T4b puede necesitar un parser XML: justifica cuál y por qué, versión exacta, que corra en Deno).

### Lecciones de 2R-16 (te las pedí y las rompiste una vez; aplican a TODO lo nuevo)
- Las funciones SQL `SECURITY DEFINER` con `GRANT … TO service_role` **se llaman con `getServiceClient()`**, nunca con `c.get("supabase")` (cliente del usuario). Escribe una prueba Deno con un cliente de usuario falso que falla con `permission denied` y un `serviceClient` que responde.
- Fechas de "hoy": **hora de México**, nunca `new Date().toISOString().slice(0,10)`. Usa `hoyMexicoISO()` (backend) y `fechaLocalISO()` (pantalla), que ya existen.
- Dinero y cantidades: valida `Number.isFinite`, redondea (2 decimales dinero, 4 cantidades) **antes** del RPC; errores de validación `400`; errores inesperados con `formatearErrorRespuesta` (500 genérico, sin texto interno).
- PostgREST corta en **1000 filas** sin avisar. Todo listado que pueda crecer pagina con `.range()` o devuelve `truncado: true`.
- Toda tabla nueva: `organizacion_id`, RLS por `get_current_org_id()`, índices, y una prueba con **dos organizaciones** (una no ve ni toca lo de la otra).
- Migraciones **idempotentes** (correrlas dos veces da los mismos conteos) con su `verificacion_<id>.sql` (todo `true`) y `prueba_<id>.sql` (con `ROLLBACK` al final), mismo estilo que `verificacion_2R16.sql` / `prueba_2R16.sql`.
- Cantidades que se descuentan o se acumulan: **bloqueo de fila (`FOR UPDATE`)** dentro de la función SQL; incluye una prueba de dos sesiones simultáneas.

---

## 1. Cómo trabajamos juntos (protocolo)

```
COORDINACION/
  LEEME.md            reglas (ya existe)
  COLA.md             las 7 tareas y su estado — tú lo actualizas
  ESTADO.md           qué estás haciendo AHORA — tú lo actualizas tras cada paso
  PREGUNTAS_LUIS.md   dudas que NO te bloquean (supón lo conservador y anótalo)
  REPORTES/           T#_REPORTE_ANTY.md  — los escribes tú
  REVISIONES/         T#_REVISION_CLAUDE.md — los escribo yo
  EVIDENCIA/          capturas/salidas que respalden tus pruebas
```

**Ciclo por tarea:**
1. Marca la tarea `EN_CURSO` en `COLA.md` y escribe `ESTADO.md` (hora, tarea, rama, último commit).
2. Implementa, prueba (ver §2), commitea.
3. Escribe `REPORTES/T#_REPORTE_ANTY.md` (formato en §2) y marca `LISTO_PARA_REVISION`.
4. **Antes de empezar la tarea siguiente, revisa `REVISIONES/`.** La primera línea de cada revisión es `VEREDICTO: APROBADO`, `VEREDICTO: CORREGIR` o `VEREDICTO: BLOQUEADO`.
   - `CORREGIR` de una tarea anterior → **arréglala primero** con commits nuevos encima, actualiza su reporte (sección "Ronda 2") y vuelve a marcarla `LISTO_PARA_REVISION`.
   - No hay revisión todavía → sigue con la siguiente tarea; no me esperes.
5. **No te quedes en espera activa.** Si terminaste todo y hay revisiones pendientes, haz como máximo 3 revisiones de `REVISIONES/` espaciadas ~15 min; si siguen sin llegar, escribe el resumen final en `ESTADO.md` y termina.
6. **Si te atoras** dos veces en lo mismo: escribe `ESTADO.md` con `DETENIDO: <motivo, qué intentaste, qué necesitas>`, marca la tarea `BLOQUEADA` y pasa a la siguiente. No inventes para salir del paso.

Todo lo que dependa de una decisión de Luis: tómala de forma **conservadora y reversible**, anótala en el reporte (sección "Suposiciones") y en `PREGUNTAS_LUIS.md`.

---

## 2. Qué es "listo" (aplica a cada tarea)

Pega **salidas reales**, no resúmenes:
1. `npm run verificar -- --limpio` **después** del último commit → `RESULTADO: TODO OK` (las pruebas Deno no bajan de 196; `tsc` no sube de lo que da `main`: dime el número de `main` en tu máquina).
2. Pruebas nuevas por nombre y su salida.
3. Si hay migración: corrida dos veces, conteos de `verificacion_<id>.sql` y salida de `prueba_<id>.sql`. **No la corras contra Supabase Cloud.** Yo la corro contra mi Postgres local.
4. `git diff --numstat main` y el hash del commit.
5. UI: capturas en `EVIDENCIA/` de lo que sí abriste con datos de prueba; di claramente lo que **no** pudiste ver renderizado.
6. Secciones del reporte: **Qué hice · Archivos · Pruebas (salidas) · Suposiciones · Lo que NO probé · Acciones manuales para Luis (SQL en orden, Rebuild api/web) · Preguntas**.

---

## T0 — Orden de la casa (15 min)

1. Rama `noche-t0-housekeeping` desde `main`. Commitea (por nombre) estos archivos que están sin versionar: `docs/importacion/carga_cadeco_2026-10-29.sql` (ya corrió en producción), `supabase/migrations/20261031_01_concha_110_redilas_85.sql`, `PROMPT_ANTY_2R16_FIX.md`, `PROMPT_ANTY_2R16_CXP_FACTURAS.md` y este prompt. No toques su contenido.
2. Agrega `Normas/` y `XML_FACTURAS/` a `.gitignore`.
3. Crea la carpeta `XML_FACTURAS/` (vacía, con un `LEEME.txt` que diga "Pon aquí los XML de facturas de proveedores. No se versionan.").
4. Reporte corto en `REPORTES/T0_REPORTE_ANTY.md`.

---

## T1 — "Productos y servicios" no muestra todo el catálogo

**Qué ve Luis:** en Productos y servicios, "Remolques terminados" solo tiene 3, "Refacciones" 2, "Materias primas" 5, "Acero" 1; pero ya compilamos mucho más en los Excel y en el cotizador.

**Lo que yo ya vi (verifícalo, no lo asumas):**
- `GET /productos` hace `supabase.from('productos').select('*')` **sin rango**: PostgREST corta en 1000 filas. Si `productos` ya pasa de 1000 (la migración del BOM es enorme), la lista sale incompleta.
- `ProductosList.tsx` filtra por `categoria_id` (pestañas por categoría). Los productos cargados por migración probablemente tienen `categoria_id` nulo: solo aparecen en "Todas".
- Lo del cotizador (opciones, medidas, precios) vive en `opciones_configuracion`, `acero_materiales`, `opcion_costos`, `acero_precios`, **no** en `productos`. Por eso no aparece en Productos y servicios aunque exista y tenga precio.

**Qué hacer:**
1. Diagnóstico por escrito en `docs/diagnostico/CATALOGO_PRODUCTOS.md`: confirma o descarta cada punto leyendo el código y las migraciones. Escribe un SQL **solo de lectura** `docs/diagnostico/catalogo_conteos.sql` (conteos por `tipo_item`, por `categoria_id`, con `costo` nulo o 0, y cuántas filas hay en `acero_materiales`, `opciones_configuracion`, `opcion_costos`, `acero_precios`) para que Luis lo corra mañana y veamos la realidad.
2. Backend: `GET /productos` pagina (`.range()` en bucle hasta agotar, o paginación con `?page&limit&q&categoria&sin_costo=1`; elige lo más simple que no rompa a los demás consumidores de `/productos` — busca quién lo llama). Devuelve el total.
3. Pantalla: pestañas generadas desde las categorías **que realmente tienen datos**, con conteo por pestaña, una pestaña **"Sin categoría"**, buscador, y un filtro **"Sin costo cargado"**. Las piezas sin costo muestran la etiqueta **"Sin costo cargado"** (no `$0`).
4. Pestaña o sección **"Catálogo del cotizador"** (solo lectura) que liste lo de `acero_materiales` y `opciones_configuracion` con su precio y origen, para que Luis vea todo en un solo lugar. Sin duplicar datos.
5. Pruebas Deno de la paginación (más de 1000 filas simuladas, `truncado`, filtros) y de la lógica pura de agrupar/contar en `src/app/utils/`.

**No hagas:** cambiar el motor de costeo, borrar ni mover productos.

---

## T2 — Despiece completo por fases desde `UNION DE LISTADOS ACTULIZADO (1).xlsx`  ← la tarea más importante

**Archivo:** raíz del repo, hoja única `Hoja1` (321 filas). **No lo modifiques.** Léelo con una librería (UTF-8), no con la consola de Windows (los acentos salen rotos ahí).

### Lo que quiere Luis (sus palabras, resumidas)
Un "arbolito" del despiece de una plataforma: **Fase → kit/producto → pieza (con variante) → cantidad**. Si el cliente elige una suspensión (Hendrickson, Flet Master, Ampro, FCR…) el despiece del presupuesto trae **las piezas de esa suspensión**; igual el kit de ABS, kit de luz, pisos, pintura, retráctiles, ganchos, rines, llantas. Debe quedar en la base de datos y servir de base al checklist de almacén (T3). Las piezas **sin precio** se quedan sin precio: marcadas **"Sin costo cargado"**. Esto aplica a **todas las plataformas** (no a dolly ni góndola, que ya tienen su receta).

### Estructura del Excel (lo que yo vi; compruébalo)
- Columnas: `PROCESO | PRODUCTO | (subpieza/variante) | NOMENCLTURA (material) | CANTIDAD | PRECIO UNITARIO | COSTO`.
- `PROCESO` solo trae valor en la primera fila de cada paso (**celda vacía = continúa el paso anterior**); `PRODUCTO` igual (celda vacía = continúa el producto/kit anterior). La 3.ª columna es variante o subpieza (`27 x 50 cm`, `Placa trasera`, `Aletas`, `TORNILLO`…).
- **Pasos 1–6**: acero (con precios y costos). **7** Lavado y escoreo · **8** Pintura (por marca: Sherwin Williams / PPG / Axalta, en litros) · **9** Kit ABS (+ gancho, bolsa/tornillería de retráctil, tanque de aire) · **10** Kit de luz · **11** Pisos (plástico café, pino, encino, madera + pijas) · **12** Acabado (loderas, fleje, winches, rotulación, placa…) · **EXTRAS** (redilas, retráctil fabricado en Leolca grande, equipos multimodal) · **LLANTAS Y RINES** (medida de rin, tipo de rin, llantas).
- **Bloques de opciones excluyentes** dentro del Paso 5/6: Sistema retráctil grande/chico; suspensiones **Hendrickson HT300US (alta)**, **HT300 (normal)**, **Flet Master**, **Ampro**, **FCR**; patines (Ampro, Holland Mark V, HJ, Flet Master); ejes (Flet Master, Ampro, FCR, Prat Max, HJ); tipo de gancho; rines; llantas; pinturas. Cantidad `0` = alternativa de otra marca que **no** se usa por omisión.

### Anomalías que ya detecté (repórtalas, no las "arregles" en silencio)
- Consumibles sin cantidad en Pasos 4 y 5 (disco laminado 7, disco de corte 7, disco de desbaste 9, oxígeno, rollo de microalambre, CO2) → "cantidad por definir".
- Una fila **sin nombre** con cantidad 25.8 en Paso 10 (después de `CABLE NEGRO`).
- Líneas repetidas con cantidades distintas (`CORRUGADO 3/8`, `CORRUGADO 1/4`, `TERMINAL 3/16`): son usos distintos, consérvalas con su `uso`.
- `FOSFATO` con cantidad de texto (`1 L`) → separa número y unidad.
- `RIN 24.5` / `RIN 22.5` y `LLANTA …` duplicadas sin cantidad: son **medida/elección**, no piezas.
- Typos: `PRAIMER`, `INCERTO`, `AUMINIO`, `TORNILLEROA`, `MONRROE`, `CARGADO 3X102 IN`, `FLET MASTER`. Normaliza el nombre del producto pero guarda el texto original como alias.
- `PTR de 6X2" Cal. 3/16"` (puentes de suspensión) sin precio unitario (ya sabemos que está pendiente con el cliente).
- El Excel es la receta de **una plataforma de referencia de 2 ejes** (cargador 38 pzas de IPR 4"x102", "Kit ABS 2 ejes", 2 tanques). Deduce cuál es comparándola con `receta_base` de `PLATAFORMA 2 40 FT` y dilo.

### Qué hacer
1. **Análisis primero** → `docs/despiece/ANALISIS_UNION_LISTADOS.md`: el árbol (conteos por fase/kit/pieza), diccionario de normalización de nombres, anomalías, y un **diff Excel ↔ base de datos**: qué piezas ya están en `receta_base`/`opcion_componentes` (con `paso`/`uso` actuales y su valor de cantidad), cuáles son nuevas, cuáles cambiaron de cantidad, cuáles faltan en el Excel. Reutiliza `scripts/parse_bom.py`, `generar_recetas_sql.cjs` y `generate_sql_bom.py` si sirven (léelos antes). La base **no se ve en producción desde aquí**: trabaja con las migraciones `20261001_03_migracion_bom.sql`, `20261008_01_recetas_plataforma.sql` y siguientes.
2. **Catálogo de fases** (no confundir con `fases_produccion` del Kanban): tabla `fases_despiece` (`clave`, `nombre`, `orden`, `descripcion`) con Paso 1…12, Extras y Llantas y rines **con el nombre que usa el Excel**; para 1–6 usa "Paso N" y un subtítulo editable. Mapea los valores actuales de `paso` (hay `PASO 1…6`, `AIRE`, `LUZ`, `TERMINADO`, `EXTRAS`) a estas fases en una tabla de equivalencias; **no pierdas** el `paso` original.
3. **Modelo de datos del árbol:** reutiliza `receta_base` y `opcion_componentes` (ya tienen `paso`, `uso`, `seccion`, `escala`, `condicion`). Solo agrega columnas (`kit`, `variante`, `nota_origen`…) si `uso`/`notas` no alcanzan, y justifícalo. **Prohibido crear un segundo BOM paralelo.**
4. **Productos:** cada pieza del despiece debe existir en `productos` (`tipo_item = 'materia_prima'`, `unidad`, categoría por kit/fase: Acero, Tornillería, Aire/ABS, Luz, Pintura, Pisos, Acabados, Suspensión, Patines y ejes, Llantas y rines, Consumibles). Si ya existe, **reutilízala** (compara por nombre normalizado/alias; no dupliques). Costo: solo si el Excel trae precio **y** el producto no tiene costo; si ya tiene costo distinto (>2 %), **no lo pises**: lista el conflicto en el análisis. `precio_fuente`/nota: `UNION_LISTADOS_2026-11`. Sin precio → costo nulo → "Sin costo cargado".
5. **Opciones configurables:** mapea cada bloque de opciones del Excel al grupo/opción existente (suspensión, retráctil, patines, ejes, gancho, pintura, pisos, rines, llantas). Para cada una: sus componentes con cantidad y `escala` (`fija`/`por_eje`/`por_largo`). **Las cantidades del Excel son de la referencia de 2 ejes**: dónde escalar por eje o por largo es decisión técnica; sigue la lógica que ya usa el motor para esas opciones y marca como `DUDA` en el reporte cada línea donde no haya evidencia. No inventes fórmulas.
6. **Migración de datos** idempotente `20261102_01_despiece_union.sql` (fases, equivalencias, productos nuevos, componentes nuevos/ajustados) generada por un script en `scripts/` que lea el Excel, con marca `import-union-2026-11` en `notas`. Guardias: cada grupo/opción base existe exactamente una vez por organización; si una pieza no se puede mapear con certeza, **no la cargues**: va a una sección "Pendientes de definir" del análisis.
7. **Verificación:** `verificacion_T2.sql` (conteos esperados vs Excel) y `prueba_T2.sql`. Que el motor siga resolviendo la receta de `PLATAFORMA 2 40 FT` igual que antes **salvo** las diferencias documentadas: corre las pruebas Deno de `resolver_receta` y las fixtures de `motor/fixtures` y muestra que no se rompieron.
8. El **despiece del presupuesto** (`presupuestos.datos.meta.bom`) debe conservar `paso` y debe poder agrupar por fase con el catálogo nuevo. Si hay que tocar `presupuesto_desde_costeo.ts`, que el cambio sea aditivo.

**No hagas:** cambiar precios de venta, tocar el costeo, cargar Dolly/Góndola, ni borrar recetas existentes.

---

## T3 — Checklist de entrega de almacén a producción (por orden, por equipo, por fase)  ← depende de T2

**Lo que pide Luis:** del presupuesto sale un **checklist editable del despiece, por fases**, para saber qué piezas ya se le entregaron a producción **para ese remolque en específico** y **no volver a entregar una pieza ya entregada** (ejemplo: Paso 12, las 2 loderas ya se entregaron; si otro operario las vuelve a pedir, el sistema lo impide; se puede entregar todo lo que **no** se haya entregado). El inventario real (existencias) **no** entra todavía: lo conectamos cuando el almacén esté al 100 %. Hoy es control de entregas.

### Diseño base (puedes mejorarlo si lo justificas)
- `orden_despiece_lineas`: snapshot por **orden de trabajo y por equipo** (si la OT tiene 2 remolques hay 2 juegos de líneas): `fase_clave`, `kit`, `material_id`/`descripcion`, `unidad`, `cantidad_requerida`, `origen` (receta / opción / manual), `sin_costo`, `clave_origen` determinística. La generación es **idempotente**: volver a generar agrega lo faltante y **jamás borra ni reinicia lo ya entregado**.
- `orden_despiece_entregas`: movimientos (`entrega` / `reposicion`), `cantidad`, `operario_id` (quien recibe, de la tabla `operarios`), `entregado_por`, `fecha`, `motivo`, y anulación (`anulada`, quién, por qué). **Nunca se borran filas.**
- Función SQL `registrar_entrega_despiece` (`SECURITY DEFINER`, solo `service_role`, `FOR UPDATE` sobre la línea): rechaza si `entregado + cantidad > requerida` con error `excede_requerido` que devuelve lo pendiente; la **reposición** (pieza dañada/perdida) sí puede exceder, pero exige `motivo` y queda visible aparte. `anular_entrega_despiece` para corregir errores. Cantidades fraccionarias válidas (0.25 de disco).
- Vista `v_orden_despiece_avance`: entregado, pendiente, estado (`pendiente`/`parcial`/`completo`) por línea y por fase.
- Rutas bajo `/ordenes-trabajo/:id/despiece/*` (generar, listar, entregar, anular, agregar línea manual, ajustar cantidad). Debes **investigar** cómo se relacionan hoy OT ↔ presupuesto ↔ cotización (`generar_ordenes_cotizacion.ts`, `presupuesto_desde_costeo.ts`) y decir de dónde sale el BOM de cada OT.
- **Editable:** ajustar `cantidad_requerida` (con motivo; nunca por debajo de lo entregado), agregar línea manual, quitar una línea solo si lleva 0 entregado.
- Pantalla en el detalle de la OT (pestaña "Almacén / Despiece"): fases plegables con barra de avance, cada pieza con requerida/entregada/pendiente, botón **Entregar** (cantidad por omisión = pendiente, selector de quién recibe), **Entregar toda la fase** (con confirmación), pieza completa → botón deshabilitado con el texto "Ya entregada completa el {fecha} a {operario}", etiqueta **"Sin costo cargado"**, historial por pieza, modal de reposición. Imprimir/CSV de una fase como vale de salida.
- Pruebas: dos sesiones simultáneas entregando lo mismo (queda una sola entrega; la otra recibe `excede_requerido`), idempotencia de la generación, dos organizaciones, redondeo, anulación, reposición sin motivo → rechazo.

**No hagas:** descontar existencias, tocar `stock_actual`, ni integrar con `plan_tarea_materiales` (queda para después).

---

## T4 — Proveedores, facturas con varias partidas, XML y reporte  ← construye sobre 2R-16 (ya en `main`)

**Interpretación (confírmala en el reporte):** "agregar más cobros en una sola factura" = que una factura pueda llevar **varias partidas/cargos** (conceptos, flete, descuentos, impuestos). Los **pagos parciales ya existen** (`pagos_factura`): no los toques.

**T4a — Partidas por factura**
- Tabla `factura_proveedor_partidas` (`tipo`: `concepto` | `impuesto_trasladado` | `retencion` | `descuento` | `otro_cargo`; `descripcion`, `cantidad`, `precio_unitario`, `importe`). El `importe` de la factura = subtotal + traslados + otros cargos − retenciones − descuentos y se **valida en el servidor/RPC**; no puede quedar por debajo de lo ya pagado. Las 16 facturas de CADECO ya cargadas no tienen partidas y **siguen siendo válidas**.
- Formulario de factura con tabla de partidas (agregar/quitar, total en vivo, moneda de la factura). Detalle de factura muestra partidas y pagos.

**T4b — Subir XML (CFDI 3.3 / 4.0)**
- Endpoint de **previsualización** (no escribe nada) y de **importación** con confirmación; acepta varios `.xml` (máx. 100 por lote, 2 MB c/u), se procesa en el servidor.
- Extrae: UUID fiscal (`TimbreFiscalDigital`), serie+folio, fecha, moneda, tipo de cambio, subtotal, descuento, impuestos (traslados/retenciones), total, método y forma de pago, emisor (RFC, nombre) y receptor (RFC), conceptos. Mapea a factura + partidas; `dias_credito` del proveedor.
- Reglas: **idempotente por UUID fiscal** (mismo XML dos veces → "ya importada", sin duplicar); proveedor por RFC del emisor (si no existe, la previsualización lo propone como "proveedor nuevo" y se crea solo al confirmar); solo `TipoDeComprobante = I`; `E` (nota de crédito) se muestra aparte como "nota de crédito, no importada"; `P` (pago) se ignora con aviso; receptor distinto al RFC de la organización → advertencia. Guarda el XML original (tabla `facturas_proveedor_cfdi` con `uuid_fiscal` único por organización).
- **Seguridad:** parser sin resolución de entidades externas ni DTD (rechaza `<!DOCTYPE`/`<!ENTITY`), límite de tamaño, solo `.xml`. **No valida contra el SAT** ni la firma: dilo en pantalla ("Importado desde XML; no validado con el SAT").
- Pantalla: zona para soltar archivos → tabla de previsualización (válido / duplicado / proveedor nuevo / error y por qué) → botón Importar.
- Pruebas con **XML sintéticos que escribas tú** según el estándar (3.3 y 4.0; USD con tipo de cambio; con descuento; con retenciones; duplicado; nota de crédito; DTD malicioso; truncado). Si Luis deja XML reales en `XML_FACTURAS/`, corre también contra ellos y reporta (sin copiar datos fiscales al reporte).

**T4c — Reporte de facturación (proveedores)**
- Filtros: rango de fecha de emisión o de vencimiento, proveedor, moneda, estado (abierta/pagada parcial/pagada/vencida). Columnas: proveedor, folio, UUID, emisión, vencimiento, moneda, subtotal, IVA, retenciones, total, pagado, saldo, días de atraso. **Totales por moneda** (no sumes USD con MXN; muestra el equivalente en pesos con el tipo de cambio de `tipos_cambio`, indicando cuál usó). Exportar CSV (UTF-8 con BOM) e imprimir. Pagina o marca `truncado`.

**T4d — Revisión general de Proveedores**
- Audita `ProveedoresList.tsx` contra los campos que ya existen (razón social, RFC, días de crédito, moneda, límite de crédito del 2R-16), detecta duplicados por RFC (advertencia, **no** índice único), muestra saldo vigente y enlace a Cuentas por pagar. Lista en el reporte lo que falte; implementa solo lo de bajo riesgo. **No inventes proveedores**: la "actualización de la lista" sale de los XML y de lo que Luis cargue.

---

## T5 — Normas: dónde y cómo meterlas (solo propuesta, **sin código**)

`Normas/` tiene 10 `.docx` de 3 unidades (volteo 9.20 m, plataforma 40 ft, dolly): **Carta factura**, **NOM-012 (constancia de pesos y dimensiones)**, **NOM-035 (constancia, con ~90 imágenes de pruebas)** y **NOM-068 (manifiesto)**. Los 4 documentos de una unidad comparten el **folio** (`044/27`, `064/27`, `066/27`) y el **NIV**.

Entrega `docs/propuestas/NORMAS_PROPUESTA.md` con: (1) qué datos fijos y variables lleva cada documento y de dónde saldría cada uno en el sistema (cliente, domicilio, RFC, NIV, tipo, longitud, ejes, suspensión, ancho/alto, fecha, folio); (2) dos alternativas de ubicación —pestaña "Documentos / Normas" dentro de la Orden de Trabajo, o módulo "Expedientes de unidad"— con tu recomendación y por qué; (3) modelo de datos propuesto (unidad fabricada con NIV y folio consecutivo anual `NNN/YY`, estado de cada documento); (4) generación: plantilla `.docx` con marcadores → borrador → revisión humana y firma; **nunca emitir sin revisión** (son manifiestos "bajo protesta de decir verdad"); (5) las **inconsistencias** que veas entre documentos (por ejemplo, años distintos de la misma norma —NOM-012-SCT-2-2017 vs 2014, NOM-035 2022 vs 2010—, "VOLETO", dimensiones, datos duplicados o sueltos como números previos al NIV) **sin corregirlas**: solo lístalas; (6) preguntas para Luis. No muevas ni edites los originales. Extrae el texto de los `.docx` en UTF-8 (no con la consola).

---

## T6 — Editor de recetas y plantillas creadas por el usuario  ← depende de T2

**Lo que quiere Luis:** que además de cargar recetas por base de datos, un usuario pueda **crear una receta nueva desde el sistema** (ejemplo: una "cama plana de 47 pies"), partiendo de una existente ya dada de alta por fases, **editarla** (agregar/quitar/cambiar piezas por fase) y que quede disponible para el cotizador y las plantillas.

1. **Primero una nota de diseño** (`docs/propuestas/EDITOR_RECETAS.md`): cómo se define hoy un modelo (`modelos`, `receta_base`, `opcion_componentes`, `resolver_receta.ts`), qué hace falta para que un modelo nuevo **aparezca en el cotizador y se resuelva sin tocar código** (¿el motor lo permite? ¿el `CHECK (tipo_modelo …)` lo limita? ¿cómo se obtienen costos y medidas de un modelo nuevo?). Aclara también a qué se refiere "plantillas": ¿`plantillas_cotizacion` (plantillas de cotización) o plantillas de receta? Si el motor **no** puede resolver un modelo nuevo sin cambios de código, **detente en la nota y repórtalo**; no hagas un parche.
2. Si es viable, MVP: **"Nueva receta desde…"** (clonar `receta_base` de un modelo origen a un modelo nuevo con nombre, largo y ejes) y un **editor por fases** (agregar pieza buscando en `productos`, cambiar cantidad/escala, quitar, reordenar) con historial de cambios (quién, qué, cuándo). Las recetas **congeladas** en presupuestos/OT ya generados **no cambian**; el cambio aplica a lo nuevo.
3. Pruebas: clonar (no duplica ni modifica el origen), edición con dos organizaciones, idempotencia, y que `resolver_receta` resuelva el modelo clonado igual que el origen.

---

## Orden y criterio de corte
`T0 → T1 → T2 → T3 → T4 (a,b,c,d) → T5 → T6`. Si algo de T4 se atora por el parser XML, entrega T4a y T4c y deja T4b documentada. Si el tiempo se acaba, **cierra con calidad la tarea en curso** antes de abrir otra.

## Al terminar
Actualiza `COLA.md` y `ESTADO.md` con el resumen final: qué tareas quedaron `LISTO_PARA_REVISION`, cuáles `APROBADA` por mí, cuáles `PENDIENTE`/`BLOQUEADA`, el **orden de SQL para Luis** y si hace falta Rebuild de `remolques-api` y/o `remolques-web`.
