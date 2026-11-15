# Reporte de Ejecución — Dolly: Cargar el Despiece (Solo Datos, Sin Mover Precios)

**Fecha:** 2026-11-14  
**Responsable:** Antigravity (para revisión de Claude y Luis)  
**Rama:** `despiece-dolly-2026-11-14` (worktree `..\Remolques_despiece_dolly`)  
**Base:** `main` (commit `a695e01` con plataformas desplegado)  
**Reglas duras cumplidas:** Cero push a remoto, cero merge a `main`, sin tocar EasyPanel ni Supabase producción; cero cambios en costos o precios; migración idempotente de dos pasadas con `ON_ERROR_STOP=1`; sin UUID de organización fijo en código; commits nuevos sobre la rama sin reescribir historia.

---

## 1. Resumen Ejecutivo

Conforme al pedido de Luis y al análisis de insumos en `COORDINACION/REVISIONES/DOLLY_AJUSTES_DESPIECE_2026-11-14.xlsx` y `DESPIECE_COMPLETO_2026-11-14.xlsx`, se cargó el despiece completo para el modelo **DOLLY 2 EJES**, el cual anteriormente solo contaba con los 33 renglones estructurales de acero (perfiles, soleras, canales) y carecía de despiece de aire, luz, consumibles, herrajes y piezas de ensamble.

### Principales Acciones Realizadas:
1. **Alta de Materiales Faltantes:** Se dieron de alta **14 materiales** en `productos` con `costo = 0.00` y `precio_unitario = 0.00`, exclusivamente aquellos marcados como `CREAR` en la hoja `ALTA_MATERIALES`. No se crearon los marcados como `NO CREAR` ni los que ya existían en el catálogo.
2. **Carga en Receta Base (`receta_base`):** Se insertaron **53 renglones** a la receta de `DOLLY 2 EJES` (`seccion = NULL`, `escala = 'fija'`). Las 4 líneas de `EXTRAS` (amortiguador de alta) incluyen la condición JSONB `{"todas":[{"op":"in","campo":"suspension","valor":["alta_hendrickson","alta_fleet_master","hj_alta"]}]}` idéntica a plataformas.
3. **Carga en Opciones (`opcion_componentes`):**
   - Grupo `dona` (`holland`, `premier`, `bestia`): 3 opciones $\times$ 4 componentes = **12 renglones** con `paso = 'PASO 1'`, `seccion = NULL`, `escala = 'fija'`, `rol = 'componente'`.
   - Grupo `quinta` (`holland`, `fontaine`): 2 opciones $\times$ 4 componentes = **8 renglones** con `paso = 'TERMINADO'`, `seccion = NULL`, `escala = 'fija'`, `rol = 'componente'`.
4. **Asignación Explícita de Fases y Pasos:** Todas las 73 filas nuevas (53 receta + 20 opciones) tienen asignado su `paso` textual y su `fase_id` correspondiente (`paso_1`, `paso_7`, `paso_9`, `paso_10`, `paso_12`, `extras`), resuelto dinámicamente con `to_regclass('public.fases_despiece')` para que la migración no falle si la tabla no existiera.
5. **Respeto a Exclusiones:** No se tocaron los 55 renglones de la hoja `CONFIRMAR`, ni `YA_CUBIERTO_O_DIFERIDO`, ni `COBRO_PROPUESTAS`.
6. **Cero Impacto Económico:** Todas las líneas nuevas tienen `seccion = NULL` y los materiales costo $0.00. El motor de costeo solo suma líneas con `seccion = 'acero'`, garantizando matemáticamente $0.00 de variación en precios y costos.

### Tabla de Métricas de Base de Datos:

| Rubro | Baseline (`remolques_rev_t3` + plat) | Pasada 1 | Pasada 2 (Idempotente) | Delta Total | Estado |
|---|---:|---:|---:|---:|---|
| **Catálogo de Materiales (`productos`)** | 518 | 532 | 532 | **+14** | Costo $0.00, precio $0.00 |
| **Líneas Receta Base Dolly (`receta_base`)** | 33 | 86 | 86 | **+53** | 33 acero + 53 nuevos (`seccion = NULL`) |
| **Receta Base Total Sistema (`receta_base`)** | 2,100 | 2,153 | 2,153 | **+53** | Cero duplicados en segunda pasada |
| **Componentes de Opciones (`opcion_componentes`)** | 207 | 227 | 227 | **+20** | 12 donas + 8 quintas con fase |
| **Suite de Pruebas Deno** | 334 | 334 | 334 | 0 | 334 pasan, 0 fallan |
| **Verificación General (`verificar.mjs`)** | 7/7 (rápido) / 11/11 | 7/7 | 7/7 | 0 | Limpio, 0 errores tsc, build OK |
| **Verificación SQL (`verificacion_despiece_dolly.sql`)** | N/A | 1 fila | 1 fila | `todo_ok = true` | 7 comprobaciones en verde |
| **Variación de Precios / Costos** | $0.00 | $0.00 | $0.00 | **$0.00** | Hashes MD5 100% idénticos |

---

## 2. Detalle de Materiales y Recetas Modificadas

### 2.1 Alta de 14 Materiales (`productos`)
Todos dados de alta con `tipo = 'bien'`, `tipo_item = 'materia_prima'`, `costo = 0.00` y `precio_unitario = 0.00`:
1. `OREJA` (PZA) — Cuadro del dolly.
2. `BISAGRA DE DOLLY` (PZA) — Cuadro del dolly (independiente de `BISAGRA 5/8` de caja auxiliar).
3. `PERNO DE DOLLY` (PZA) — Cuadro del dolly (mismo que perno de dona).
4. `BUJE CONICO GRANDE` (PZA) — Cuadro del dolly.
5. `DONA HOLLAND` (PZA) — Opción Gancho Holland.
6. `DONA PREMIER` (PZA) — Opción Gancho Premier.
7. `DONA PREMIER BESTIA` (PZA) — Opción Gancho Premier Bestia.
8. `TUERCA GRIPCO 5/8` (PZA) — Tornillería de dona y de quinta.
9. `QUINTA HOLLAND` (PZA) — Opción Quinta Holland.
10. `QUINTA FONTAINE` (PZA) — Opción Quinta Fontaine.
11. `TORNILLO 5/8 X 2 1/2 GRADO 8` (PZA) — Tornillería de quinta.
12. `JUEGO DE MANGUERA ESPIRAL AZUL Y ROJA` (PZA) — Aire.
13. `MACHO SOLO 7 POLOS` (PZA) — Luz.
14. `CABLE 7 POLOS` (M) — Luz (2.5 m en receta base).

*(Nota: materiales marcados como `NO CREAR` como `TORNILLO 5/8*5 GRADO 8`, `RONDANA AUTOMOTRIZ 5/8`, `CADENA 3/8`, `ABRAZADERA 1/2` ya existían previamente en `productos`.)*

### 2.2 Receta Base de DOLLY 2 EJES (53 renglones por Fase y Paso)
- **Paso 1 (`paso_1` — 13 renglones):**
  - Consumibles y corte: Disco laminado 7 (1), Disco de corte 7 (1), Disco de desbaste 9 (1), Consumible 65 (0.25), Rollo de microalambre (1), CO2 (1), Oxígeno (0.25).
  - Patines: Tornillo 5/8 x 1 1/2 Grado 5 (44), Tuerca estándar 5/8 Grado 5 (44).
  - Cuadro: Oreja (2), Bisagra de dolly (2), Perno de dolly (2), Buje cónico grande (4).
- **Limpieza (`paso_7` — 4 renglones):**
  - Lija #80 (2), Carda 5/8 de 3" (1), Disco laminado 4 1/2 (1), Fosfato (1).
- **Aire (`paso_9` — 12 renglones):**
  - Conexiones y válvulas: Reducción 3/4 * 1/2 (1), Te unio 3/8 (1), Adaptador 3/8 (8), Macho 3/8 (8), Hembra 3/8 (8), Kit de ABS 2 ejes Bendix (1), Válvula protectora (1), Manita roja s/llave (2).
  - Mangueras: Manguera roja 3/8 (20 m), Manguera chamber 3/8 (8), Juego de manguera espiral azul y roja (2).
  - Tornillería ABS: Tuerca de seguridad 5/16 (2).
- **Luz (`paso_10` — 13 renglones):**
  - Conectores y arnés: Hembra 7 polos (1), Macho solo 7 polos (1), Cable 7 polos (2.5 m), Cinta de aislar (1), Plafón rojo 4 (6).
  - Cables individuales: Cable rojo cal 12 (6.6 m), Cable amarillo cal 12 (5 m), Cable verde cal 12 (4.2 m), Cable café cal 12 (6.6 m), Corrugado 3/8 (7.5 m), Terminal 3/16 (6).
  - Tornillería: Tornillo 1/4 x 1 galvanizado (4), Tuerca estándar 1/4 (4).
- **Terminado (`paso_12` — 7 renglones):**
  - Accesorios: Lodera blanca o negra (2), Fleje (2), Kit de rotulación (1), Cinta reflejante (1), Placa de NIP (1).
  - Porta lodera: Tornillo 1/2 x 1 3/4 (8), Tuerca de seguridad 1/2 (8).
- **Extras (`extras` — 4 renglones, condicionales a suspensión alta):**
  - Condición: `{"todas":[{"op":"in","campo":"suspension","valor":["alta_hendrickson","alta_fleet_master","hj_alta"]}]}`
  - Amortiguador de alta: Tornillo 3/4 x 6 Grado 8 (2), Tuerca de seguridad 3/4 (4), Tornillo 3/4 x 3 1/2 Grado 8 (2), Rondana automotriz 3/4 (4).

### 2.3 Componentes de Opciones (20 renglones)
1. **Grupo `dona` (`paso = 'PASO 1'`, `fase_id = paso_1`):**
   - **Opción `holland`:** Dona Holland (1), Tornillo 5/8*5 Grado 8 (6), Tuerca Gripco 5/8 (6), Rondana automotriz 5/8 (12).
   - **Opción `premier`:** Dona Premier (1), Tornillo 5/8*5 Grado 8 (6), Tuerca Gripco 5/8 (6), Rondana automotriz 5/8 (12).
   - **Opción `bestia`:** Dona Premier Bestia (1), Tornillo 5/8*5 Grado 8 (6), Tuerca Gripco 5/8 (6), Rondana automotriz 5/8 (12).
2. **Grupo `quinta` (`paso = 'TERMINADO'`, `fase_id = paso_12`):**
   - **Opción `holland`:** Quinta Holland (1), Tornillo 5/8 x 2 1/2 Grado 8 (10), Tuerca Gripco 5/8 (10), Rondana automotriz 5/8 (20).
   - **Opción `fontaine`:** Quinta Fontaine (1), Tornillo 5/8 x 2 1/2 Grado 8 (10), Tuerca Gripco 5/8 (10), Rondana automotriz 5/8 (20).

---

## 3. Pruebas de Costeo e Integridad de Precios

### 3.1 Cotizaciones Reales con Dolly
Se consultó la base de datos para identificar cotizaciones históricas que incluyan dolly:
```sql
SELECT count(*) FROM items_cotizacion ic JOIN modelos m ON m.producto_id = ic.producto_id WHERE m.tipo = 'dolly';
-- Resultado: 0

SELECT count(*) FROM items_cotizacion ic WHERE ic.descripcion ILIKE '%dolly%';
-- Resultado: 0
```
**Conclusión:** Actualmente no existen cotizaciones históricas de dolly en la tabla `items_cotizacion`.

### 3.2 Verificación de Hashes MD5 (Precios y Costos Intactos)
Se compararon los hashes criptográficos MD5 de todas las tablas tarifarias antes y después de la migración:

| Tabla Evaluada | Hash MD5 Antes | Hash MD5 Después | ¿Idéntico? |
|---|---|---|:---:|
| `productos` (costos previos) | `d6b6771acb57b5b286a71e2e928ded77` | `d6b6771acb57b5b286a71e2e928ded77` | **SÍ** |
| `costos_modelo` | `b8e2e1fec640dccbba86654abf522245` | `b8e2e1fec640dccbba86654abf522245` | **SÍ** |
| `opcion_costos` | `f05ab3c93da398d62ef6cd8013fc7103` | `f05ab3c93da398d62ef6cd8013fc7103` | **SÍ** |
| `receta_base` (`seccion IS NOT NULL`) | `dc784dd8892625c39817b37e641d4867` | `dc784dd8892625c39817b37e641d4867` | **SÍ** |
| `procesos_manufactura` | `6e15a60017eb33b3087430df69067708` | `6e15a60017eb33b3087430df69067708` | **SÍ** |

Los 33 renglones de acero del dolly se mantienen con `seccion = 'acero'`. Como los 53 renglones nuevos tienen `seccion = NULL`, el motor de costeo los ignora completamente para el cálculo de costos (`cargar_costos.ts` línea 48: `.eq("seccion", "acero")`).

---

## 4. Simulación de Checklist de Almacén (`checklist_almacen.ts`)

Se ejecutó la simulación de generación de checklist para un DOLLY 2 EJES con configuración típica:
- Quinta: `holland`
- Dona: `holland`
- Suspensión: `alta_hendrickson` (activa 4 extras de amortiguador de alta)
- Retráctil: `grande`

### Distribución por Fase en Almacén:

```text
┌─────────┬────────────┬─────────────┬────────────┬─────────────────┬──────────────┐
│ (index) │ fase       │ fase_nombre │ fase_orden │ total_renglones │ total_piezas │
├─────────┼────────────┼─────────────┼────────────┼─────────────────┼──────────────┤
│ 0       │ 'paso_1'   │ 'Paso 1'    │ 1          │ 17              │ 128.50       │
│ 1       │ 'paso_5'   │ 'Paso 5'    │ 5          │ 11              │ 40.00        │
│ 2       │ 'paso_7'   │ 'PASO 7'    │ 7          │ 4               │ 5.00         │
│ 3       │ 'paso_9'   │ 'PASO 9'    │ 9          │ 12              │ 62.00        │
│ 4       │ 'paso_10'  │ 'PASO 10'   │ 10         │ 13              │ 55.40        │
│ 5       │ 'paso_12'  │ 'PASO 12'   │ 12         │ 11              │ 64.00        │
│ 6       │ 'extras'   │ 'EXTRAS'    │ 13         │ 4               │ 12.00        │
│ 7       │ 'sin_fase' │ 'Sin Fase'  │ 999        │ 33 (acero)      │ 58.00        │
└─────────┴────────────┴─────────────┴────────────┴─────────────────┴──────────────┘
```

- **Paso 1 (`paso_1`):** 17 renglones (13 de receta base + 4 de componentes de Dona Holland).
- **Paso 5 (`paso_5`):** 11 renglones correspondientes a los componentes del retráctil grande.
- **PASO 7 (`paso_7` — Limpieza):** 4 renglones de consumibles de limpieza.
- **PASO 9 (`paso_9` — Aire):** 12 renglones de kit de aire y conexiones.
- **PASO 10 (`paso_10` — Luz):** 13 renglones de arnés eléctrico y plafones.
- **PASO 12 (`paso_12` — Terminado):** 11 renglones (7 de receta base + 4 de componentes de Quinta Holland).
- **EXTRAS (`extras`):** 4 renglones del amortiguador de alta.
- **Sin Fase:** Únicamente los 33 renglones históricos de perfiles estructurales de acero (los cuales no son ítems de almacén sino de ensamble estructural primario). Ningún renglón nuevo de almacén carece de fase (`conteoSinFase = 0`).

### Coexistencia con Componentes de Retráctil:
Al comparar los materiales de `receta_base` del dolly contra `opcion_componentes` del grupo `retractil`, los únicos materiales compartidos son:
- `RONDANA AUTOMOTRIZ 3/4`
- `TUERCA DE SEGURIDAD 3/4`

Ambos son elementos de tornillería estándar automotriz 3/4 requeridos tanto en los amortiguadores de alta como en el montaje del kit retráctil. No existe duplicación de bolsas de aire, cámaras ni herrajes especializados.

---

## 5. Verificador SQL (`verificacion_despiece_dolly.sql`)

El archivo `docs/importacion/verificacion_despiece_dolly.sql` (copiado también a `COORDINACION/SQL_PARA_LUIS/verificacion_despiece_dolly.sql`) consiste en una sola consulta `SELECT` pura sin metacomandos `\echo` ni transacciones manuales, lista para correr en el SQL Editor de Supabase:

```sql
 materiales_14_ok | receta_base_dolly_86_ok | dona_opciones_12_ok | quinta_opciones_8_ok | acero_dolly_intacto | fases_ok | todo_ok 
------------------+-------------------------+---------------------+----------------------+---------------------+----------+---------
 t                | t                       | t                   | t                    | t                   | t        | t
(1 fila)
```

### Detalle de Comprobaciones:
1. `materiales_14_ok`: Alta exacta de los 14 materiales nuevos con costo 0.00, precio 0.00 y unidades correspondientes (M para Cable 7 polos, PZA para los demás).
2. `receta_base_dolly_86_ok`: DOLLY 2 EJES tiene exactamente 86 renglones (33 acero + 53 nuevos con `seccion IS NULL`, `escala = 'fija'` y 4 extras con condición de suspensión alta).
3. `dona_opciones_12_ok`: Exactamente 12 componentes (3 donas $\times$ 4) con `paso = 'PASO 1'`.
4. `quinta_opciones_8_ok`: Exactamente 8 componentes (2 quintas $\times$ 4) con `paso = 'TERMINADO'`.
5. `acero_dolly_intacto`: Exactamente 33 líneas con `seccion = 'acero'`.
6. `fases_ok`: Todas las líneas nuevas de receta base y opciones tienen `fase_id` no nulo asignado a su fase correspondiente (o retorna `true` si `fases_despiece` no existe).
7. `todo_ok`: Conjunción booleana de todas las anteriores (`true`).

---

## 6. Instrucciones de Despliegue para Luis

Cuando Claude autorice la migración:
1. Abrir el **SQL Editor** del proyecto Supabase en producción.
2. Ejecutar el contenido del archivo:
   `COORDINACION/SQL_PARA_LUIS/20261114_02_dolly_despiece.sql`
3. Ejecutar el script de verificación para validar que todo esté en verde:
   `COORDINACION/SQL_PARA_LUIS/verificacion_despiece_dolly.sql`
   (Debe arrojar `todo_ok = true`).
4. **Nota:** No se requiere Rebuild en EasyPanel ya que no se modificó código del backend Hono.
