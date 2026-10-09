# 2R-1b — ronda 4 (commit f331a6a): un solo punto pendiente

**Verificado en mi Postgres local (dos corridas, datos reales):** la migración corre limpia e idempotente; 99 componentes de opción y 1,410 líneas de receta (141 por modelo, igual en los 10); Axalta 4, PPG 5, Sherwin 6; 47 líneas de AIRE como fijas; filas 101–109 `fija` con cantidad original; rines de aluminio 4; `alta_hendrickson` 9 y `hendrickson` 8 separadas; `retractil/chico` 5 y `retractil/grande` 11; sin materiales `FLET`/`AUMINIO`; `CONSUMIBLE 65` = 1.00.

**Una disculpa de mi parte:** dudé del conteo 177 vs 173 y tenías razón. Comprobé que 4 materiales **ya existían** con el mismo nombre (`CO2`, `PATIN AMPRO`, `GANCHO PREMIER BESTIA 6 BARRENOS`, `CINTA REFLEJANTE`) y el `NOT EXISTS` los reutilizó. Bien hecho. Anótalo en el informe (lista de materiales reutilizados).

## PENDIENTE — 20 líneas condicionales entran en toda receta sin condición

En `receta_base`, las líneas cuyo `uso` es una condición ("si lleva…") quedaron con `condicion = NULL`. Para un modelo 40/2, `SELECT count(*) FROM receta_base WHERE condicion IS NOT NULL` da **0**, pero hay estas líneas condicionales:

| `uso` | Líneas | Ejemplo de efecto si no se condiciona |
|---|---:|---|
| `JUEGO DE REDILAS` | 4 | **444 tornillos, 444 tuercas, 444 rondanas, 48 chavetas en toda plataforma**, aunque no lleve redilas |
| `KIT DE GANCHO` | 4 | tornillería de gancho aunque se elija `sin_gancho` |
| `AMORTIGUADOR DE ALTA` | 4 | tornillería de amortiguador de suspensión alta en suspensiones normales |
| `SI LLEVA LATERALES Y ESTRIBO` | 6 | cableado, corrugado y tornillos de laterales aunque no lleve |
| `SI ES MULTIMODAL O PORTA CONTENEDOR` | 2 | 12 candados y 8 cargadores en toda plataforma |

Un motor de recetas que lea `receta_base` incluiría **todas** esas líneas siempre: es exactamente el "aplanado" que nos trajo hasta aquí. Esto **no rompe el SQL**, pero deja una receta equivocada. No se puede dejar solo en el texto de `uso`.

### Qué hacer
1. **Mapear lo que sí se puede**, con el lenguaje cerrado de `condicion` (`{"todas":[{"campo":…,"op":…,"valor":…}]}`):
   - `KIT DE GANCHO` → `{"todas":[{"campo":"gancho","op":"!=","valor":"sin_gancho"}]}`
   - `JUEGO DE REDILAS` → `{"todas":[{"campo":"redilas","op":"!=","valor":"sin_redilas"}]}`
   - `AMORTIGUADOR DE ALTA` → `{"todas":[{"campo":"suspension","op":"in","valor":["alta_hendrickson","alta_fleet_master","hj_alta"]}]}`
   Verifica las claves reales de cada grupo en el catálogo (`gancho`, `redilas`, `suspension`) y que `sin_gancho` / `sin_redilas` existan. Añade el operador **`in`** a la definición del lenguaje y documéntalo (un comentario en la migración del esquema ya aplicado no se toca: ponlo en `docs/importacion/INFORME_2R1B.md` y en el changelog; yo lo recojo en el prompt del motor).
2. **Lo que no se puede mapear hoy** (`SI LLEVA LATERALES Y ESTRIBO`, `SI ES MULTIMODAL O PORTA CONTENEDOR`): no hay grupo de catálogo para eso. Guarda `condicion = {"sin_mapear": "<texto original>"}`. Es un marcador explícito: **el motor debe excluir las líneas con `sin_mapear`** hasta que se mapeen. Lístalas en el informe en una sección "Condicionales sin mapear (excluidas hasta decisión del dueño)" con su `uso` y cantidad de líneas.
3. `LATERALES` y `ESTRIBO` (filas 213–214, `PLAFON DE CARRITO AMBAR/ROJO`) son parte del mismo caso "laterales y estribo": revísalas, y si son condicionales marca igual con `sin_mapear`.
4. La migración debe seguir siendo idempotente (marcador `notas = 'import-2r1b'`).

### Verificación (pega salidas reales)
1. `git diff --numstat main`.
2. Para el modelo 40/2: conteo de líneas por tipo de `condicion` (mapeada, `sin_mapear`, ninguna) con `SELECT`; ninguna línea con `uso` condicional debe quedar con `condicion IS NULL`.
3. Las claves que usaste (`sin_gancho`, `sin_redilas`, las 3 claves de suspensión alta) confirmadas contra `catalogo_opciones_unificado.json`.
4. `iconv`, `npm run build`.

## Pendientes que NO son de esta ronda (anótalos en el changelog)
- **Escalado de consumibles por largo:** hoy solo `CONSUMIBLE 65` es `por_largo`. En el cotizador (`BASE DAT PLANAS` filas 69–82) también escalan CO2, microtubular, discos, carda, lijas y tornillos. Es un cambio de `escala` y la migración es idempotente: se corrige después con la lista confirmada, sin reimportar a mano.
- Dolly, góndola y despiece de acero (2R-1c).
- Precios de materiales (dueño).

## Reglas (siguen en vigor)
`git add` explícito, commits nuevos, **sin** `reset/clean/checkout/restore/stash/--amend`, **sin** scripts de parche ni `node -e` para reescribir archivos, changelog con tu herramienta de edición, **sin SQL a producción**, **sin push ni merge**.
