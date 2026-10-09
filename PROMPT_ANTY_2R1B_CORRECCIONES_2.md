# 2R-1b — ronda 3 (commit ac18f4e) — todavía NO se autoriza push ni merge

**Lo que ya está bien (lo probé):** corrí `20261008_01_recetas_plataforma.sql` **dos veces** en un Postgres 17 local con los productos reales y las restricciones reales de `productos`: **sin errores y idempotente**. 173 materiales nuevos como `bien`/`materia_prima`, sin duplicados ni material "8"; 10 modelos con 111 líneas cada uno; `CONSUMIBLE 65` = 1.00; `lineas_base_sin_material` = 0. Gracias por corregir los 6 puntos anteriores.

**Lo que está mal:** ahora que corre, revisé **qué quedó en cada destino** contra las filas del manual. Hay **clasificaciones incorrectas** que no rompen el SQL pero **dejan una receta equivocada**. Son 6, con número de fila:

## 1. GRAVE — 43 líneas del kit de AIRE quedaron dentro de la opción de pintura Axalta
Filas **129–171** (`KIT ABS`, reducciones, tapones, tes, codos, mangueras, válvulas, manitas, `TANQUE DE AIRE DE PLANA`…) están en `opcion_componentes` de **`pintura/axalta`** (47 componentes, contra 5 de PPG y 6 de Sherwin). Efecto: elegir otra pintura **quita el sistema de aire de la receta**, y elegir Axalta lo agrega.
- La opción `PINTURA AXALTA` solo tiene las filas **125–128** (pintura, reductor, catalizador, praimer).
- Un bloque de opción **termina** cuando cambia `proceso` (aquí `PINTURA` → `AIRE`) o aparece un nuevo `grupo_opcion`/`opcion_*`. Las filas 129–171 son **líneas fijas** (`receta_base`, `paso = 'AIRE'`, con su `uso`).

## 2. GRAVE — consumibles de PASO 6 y LIMPIEZA con la cantidad partida a la mitad
Filas **101–109** (`DISCO LAMINADO 7`, `DISCO DE CORTE 7`, `DISCO DE DESBASTE 9`, `CO2`, `ROLLO DE MICRO ALAMBRE`, `LIJA #80`, `CARDA 5/8 DE 3"`, `DISCO LAMINADO 4 1/2`, `FOSFATO`) vienen **después de una fila en blanco (100)** que cierra el grupo `TIPO DE EJE`. Son líneas fijas, pero las marcaste `por_eje` y dividiste su cantidad entre 2 (CO2 1 → 0.5, LIJA 2 → 1…). Deben quedar `fija` con la **cantidad original del manual** (1, 1, 0.5, 1, 0.5, 2, 1, 1, 1 L). Regla: la división entre 2 y `por_eje` solo aplica a **componentes dentro de un bloque abierto** de `suspension`, `eje`, `rines`, `llantas` o `abs`. Una fila en blanco o un cambio de `proceso` cierra el bloque.

## 3. Rines de aluminio como líneas fijas
Filas **256–259** (`RIN DE AUMINIO FLET MASTER`, `…TRAPEZOIDAL`, `…AMPRO`, `…AMPRO MASTER TRAPEZOIDAL`) quedaron en `receta_base`. Con eso **toda plataforma lleva 4 tipos de rin de aluminio**, además del acero. Son componentes de `rines/aluminio` (el catálogo ya trae esa opción). Typo del manual: `AUMINIO` → `ALUMINIO`, `FLET` → `FLEET` (alias). Tu normalizador aplicó `FLET`→`FLEET` en otros lados pero no se reflejó en el nombre del material; verifica que no queden materiales con `FLET`/`AUMINIO` en el nombre.

## 4. Suspensión: "alta" y "normal" mezcladas
Filas **35** (`HENDRICKSON HT300US (SUSPENSION ALTA)`) y **45** (`HENDRICKSON HT300 (SUSPENSION NORMAL)`) están ambas en `suspension/hendrickson` (17 componentes, con piernas, platos y abrazaderas duplicados). El catálogo distingue `hendrickson` (normal) de **`alta_hendrickson`** (alta); también hay `alta_fleet_master` y `hj_alta`. Mapea cada fila `opcion_suspension` por **marca + (ALTA|NORMAL)** a su opción del catálogo. Si el manual trae una versión "alta" de Fleet Master/HJ que no mapea limpio, **lista** el caso, no lo fuerces. Pega la tabla `fila de encabezado → opción del catálogo` de las 6 a 8 opciones.

## 5. Retráctil: el chico quedó en el grande
- Fila **32** `SISTEMA RETRACTIL CHICO` está en `retractil/grande`; debe ir a **`retractil/chico`**.
- Filas **183–186** (`BOLSA RETRACTIL CHICA UBL`, tornillo, rondanas, tuerca, `PARA SISTEMA RETRACTIL CHICO`) quedaron como líneas fijas "condicionadas": **toda plataforma lleva la bolsa chica además de la grande**. Son componentes de `retractil/chico`. Y fila **182** (`TUERCAS DE SEGURIDAD 1/2`, "PARA SISTEMA RETRACTIL **G**…") es componente de `retractil/grande`.
- Este tipo de línea "PARA <opción>" **no necesita `condicion`**: al ser componente de la opción, ya solo entra si se elige esa opción.

## 6. Cifras que no coinciden con el SQL
Reportaste "177 materiales únicos". El SQL real crea **173** (317 − 144). Reporta lo que de verdad hace el archivo, con una consulta que lo demuestre.

## Pedido para poder revisarlo
Añade a `docs/importacion/INFORME_2R1B.md` una sección **"Receta por destino"**: para cada opción del catálogo con componentes, la lista de filas del manual (número de fila + material + cantidad + escala + rol), y para `receta_base` las filas fijas agrupadas por `paso`. Así reviso en minutos si cada línea quedó donde debe. Luego un **autocontrol**: ninguna opción debe contener líneas con más de un `proceso` distinto salvo `suspension` (todo PASO 5) y `retractil` (PASO 5 y AIRE). Si el autocontrol falla, el script debe **avisar**, no continuar en silencio.

## Reglas (siguen en vigor)
`git add` explícito, commits nuevos, **sin** `reset/clean/checkout/restore/stash/--amend`, **sin** scripts de parche ni `node -e` para reescribir archivos, changelog con tu herramienta de edición, **sin SQL a producción**, **sin push ni merge**.

## Verificación (pega salidas reales)
1. `git diff --numstat main`.
2. Para cada opción de pintura: número de componentes (Sherwin 6, PPG 5, Axalta 4) y total de líneas `receta_base` con `paso = 'AIRE'` (≥ 43).
3. Filas 101–109: pega las 9 líneas con su `escala` y `cantidad`.
4. `rines/aluminio` con 4 componentes; sin materiales `AUMINIO`/`FLET` en nombres.
5. `suspension/hendrickson` y `suspension/alta_hendrickson` por separado, con conteos.
6. `retractil/chico` con sus componentes y la fila 32.
7. `SELECT count(*)` de materiales nuevos (el real, no el estimado).
8. `iconv`, `npm run build`.
