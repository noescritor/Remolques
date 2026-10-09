# Prompt para Anty — Sub-bloque 2R-1b: recetas del manual (solo PLATAFORMA, sin precios)

Contexto: `main` está en `38c8c8b`. El esquema del 2R-1a **ya está aplicado en producción** (tablas `modelos`, `grupos_configuracion`, `opciones_configuracion`, `opcion_componentes`, `receta_base`, `material_proveedores`, `parametros_costeo`; 20 grupos, 126 opciones, 10 modelos de plataforma). Lee primero: `PROMPT_ANTY_BLOQUE2R_CONFIGURADOR_Y_RECETA.md` §3 (reglas de lectura del manual), `ANALISIS_MANUAL_Y_COTIZADOR_2026-10-06.md` y `ANALISIS_FACTURA_LEOLCA_2026-10-07.md`.

## Alcance (y lo que NO entra)
**Entra:** importar a `receta_base` y `opcion_componentes` las recetas de la hoja **PLANA** del manual (260 líneas de `docs/manual-recetas/lineas_parseadas.json`, `hoja = "PLANA"`) para los **10 modelos de plataforma**.

**No entra** (se deja explícito en el changelog):
- **Precios y costos.** No toques `costo`/`precio_unitario` de materiales existentes, ni `material_proveedores`, ni `parametros_costeo`. Dependen de preguntas pendientes al dueño.
- **DOLLY y GÓNDOLA** (220 y 193 líneas). En producción **no existen** productos terminados ni `modelos` para ellos. Se hacen en un 2R-1c cuando el dueño confirme los productos.
- **Despiece de acero por variante** (sección `acero`): sale de `BASE DAT PLANAS`, que no está en el repo todavía. No lo inventes.
- Motor de resolución, backend, frontend: nada de `index.ts` ni `src/`. Es solo base de datos y documentos.

## Reglas (las mismas de siempre, y se han violado varias veces)
1. Rama nueva desde `main`: `bloque-2r-1b`.
2. **Prohibido:** `git reset --hard`, `git clean`, `git checkout`/`restore`/`stash` sobre archivos compartidos, `git commit -am`, `git commit --amend`, y **cualquier script de parche** (`patch_*`, `rewrite_*`, `fix_*`) para editar el changelog u otros archivos. Edita con tu herramienta de edición. `git add` solo con archivos explícitos.
3. **No ejecutes SQL contra producción.** Tú escribes la migración; el dueño la corre a mano.
4. Sin secretos en archivos.
5. Entrada en `CHANGELOG_ANTIGRAVITY.md` **debajo** de las entradas existentes de arriba (formato: nuevas arriba, sin reescribir las ajenas).
6. Pega **salidas reales** de cada verificación.

## Hechos del estado real de producción (verificados contra el respaldo)
- `productos` tiene **144 `materia_prima`** (son **piezas de acero** del despiece antiguo: `BORDA DELANTERA`, `PORTA PLACA`, `PLACA P/QUINTA`…) y 23 `producto_terminado` (los 10 `PLATAFORMA <ejes> <largo> FT`, más demo). **No existen** los consumibles, tornillería, kits ni componentes del manual (`CONSUMIBLE 65`, `DISCO DE DESBASTE 9`, `CO2`…). El plan anterior suponía 227 materiales ya cargados: **eso era falso**. La mayoría de los materiales del manual **hay que crearlos**.
- `productos.id` es **TEXT**. Solo hay `productos_pkey` como índice único: **no uses `ON CONFLICT (nombre, …)`** (fue lo que hizo fallar el SQL del 5-oct). Para crear materiales usa `INSERT … SELECT … WHERE NOT EXISTS` comparando nombre normalizado.
- Los `modelos` ya existen y se identifican por `largo_ft` y `num_ejes`.

## Entregables

### A. Clasificación previa (antes de escribir SQL): `docs/importacion/clasificacion_2R1b.json` + `INFORME_2R1B.md`
Para **cada una de las 260 líneas** de PLANA, decide el destino y guárdalo:
- `receta_base` (línea fija; con su `paso` = columna PROCESO arrastrada y `uso` = ESTATUS),
- `opcion_componentes` (componente de una opción: ligada a `opciones_configuracion` por **grupo + clave**),
- `sin_asignar` (lista con la razón).

Reglas (ya definidas en el prompt 2R §3, resumidas):
- Una fila `tipo = grupo_opcion` abre un grupo del manual (`TIPO DE SUSPENSION`, `TIPO DE PATIN`, `TIPO DE EJE`, `TIPO DE GANCHO`, `TIPO DE BOLSA RETRACTIL`, `TIPO DE RINES`, `TIPO DE LLANTAS`, `TIPO DE SISTEMA RETRACTIL`, `TIPO DE PINTURA`). Las filas siguientes son **componentes de opciones**, no líneas fijas.
- `opcion_suspension` / `opcion_pintura` abren una opción; sus filas siguientes son componentes. `ESTATUS`: `COMPONENTE` / `SUSTITUTO` / `INDEPENDIENTE` → columna `rol`.
- Todo lo demás es línea fija (`receta_base`).
- **Cada opción del manual debe ligarse a una opción del catálogo** (`opciones_configuracion`) por nombre/alias. Si no hay coincidencia segura: `sin_asignar`, **no adivines**.
- Duplicados del mismo material en la misma receta/opción **se suman**, nunca `DO NOTHING`.
- Unidades: `1 L`, `150ML`, `2,5 M` → cantidad + unidad. Alias de nombres de las variantes de escritura (`MICRO ALAMBRE`/`MICROALAMBRE`, `TUERCA DE SEGURIRAD`/`SEGURIDAD`, `HOLAND`/`HOLLAND`, `FLET`/`FLEET`…). **Medidas distintas = materiales distintos.**
- `escala`: `por_largo` para consumibles que escalan largo/40 (35→0.875, 42→1.05, 43→1.075, 45→1.125, 48→1.2); `por_eje` para suspensión, ejes, ABS, rines, llantas; `fija` el resto. **Las cantidades se guardan para la referencia 40 ft / 2 ejes** y el motor las escala (2R-2); no multipliques tú.
- `condicion` (jsonb, lenguaje cerrado): solo cuando el `uso` se mapea sin ambigüedad a un grupo del catálogo (`gancho`, `redilas`, `retractil`, `suspension`…). Casos como `SI LLEVA LATERALES Y ESTRIBO` o `RETRACTIL GRANDE HECHIZO`: conserva el texto en `uso` y **lístalos** en el informe como "condición no mapeada". No inventes condiciones.
- **Lo que vale 2 y no 4:** la suspensión de una plataforma de 2 ejes es **×2 (una por eje)** según `Factura Leolca.xlsx`; se modela `por_eje` con factor 1 y queda pendiente confirmación de producción. No lo cambies a 4.

El informe incluye: líneas leídas, asignadas (fija / opción / condicionada), **sin asignar (lista completa)**, alias aplicados, materiales **nuevos a crear** (lista) vs **existentes reutilizados** (lista, con el producto al que se ligaron), y las líneas "faltan en la receta" (hardware de TORNILLERIA sin receta: bicicletero, caja auxiliar, manivela, placa de logo, tapa de chamber, bisagra del pistón, kits de cámara de suspensión).

### B. Migración `supabase/migrations/20261008_01_recetas_plataforma.sql`
Una transacción, idempotente (se puede correr dos veces sin duplicar).
1. Crea los **materiales nuevos** como `materia_prima` con `INSERT … WHERE NOT EXISTS` (nombre normalizado, `organizacion_id` fijo `00000000-0000-0000-0000-000000000001`, constante nombrada). `costo` y `precio_unitario` en 0 y la descripción debe decir `SIN PRECIO`. **No toques materiales existentes.**
2. Inserta en `receta_base` (un juego de líneas por cada uno de los 10 modelos, con `material_id` resuelto por nombre) y en `opcion_componentes` (por `opcion_id` resuelto por grupo+clave).
3. **Idempotencia** sin `UNIQUE` en esas tablas: antes de insertar, borra solo lo que esta migración insertó antes (márcalo con `notas = 'import-2r1b'`) y vuelve a insertar. **Prohibido** `DELETE`/`TRUNCATE` sin ese filtro.
4. **Aborta con `RAISE EXCEPTION`** si: algún modelo no existe (esperado 10), algún grupo/opción del catálogo no se encuentra, o algún material queda sin resolver.
5. No toques `producto_materiales` (hoy vacía a propósito; respaldo en `_bak_20261006_producto_materiales`).
6. Genérala con un script en `scripts/` (uno, reproducible) y commitea **el `.sql` generado**. Un valor que no encaje: lístalo, no lo fuerces.

### C. `docs/importacion/verificacion_2R1b.sql`
**Un solo SELECT** (el SQL Editor solo muestra el último resultado) que devuelva: materiales nuevos creados, líneas de `receta_base` por modelo (esperado igual en los 10), componentes por opción, líneas sin material, y para `PLATAFORMA 2 40 FT` la suma de `CONSUMIBLE 65` (esperado **1.0** = 0.5 + 0.25 + 0.25, coincide con `BASE DAT PLANAS`).

## Verificación antes de reportar (pega la salida)
1. `git diff --numstat main`: solo archivos nuevos (+ changelog), 0 borradas.
2. `iconv -f UTF-8 -t UTF-8` sobre `.sql`, `.json`, `.md` y changelog.
3. Conteos: líneas leídas = 260; asignadas + sin_asignar = 260.
4. `grep -c` de backslashes en el `.sql` (debe ser 0 en literales de patrón).
5. `npm run build` (no deberías haber tocado código).
6. Dilo explícitamente si no pudiste probar en un Postgres: **yo lo pruebo en un Postgres 17 local con los productos reales**, dos veces seguidas.

## Al terminar
Reporta rama, hash y salidas. **No hagas push ni merge**: reviso primero. Si algo del alcance no cuadra con el estado real, **detente y avisa**, no improvises.
