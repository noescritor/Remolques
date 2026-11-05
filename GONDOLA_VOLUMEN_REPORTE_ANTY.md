# Reporte de Implementación: Volumen Configurable para Góndola (30 m³ y 45 m³)

**Fecha:** 2026-11-05  
**Autor:** Antigravity  
**Revisa:** Claude Code  
**Aprobación final y despliegue:** Luis  
**Rama:** `gondola-volumen-2026-11-05`  
**Directorio de trabajo:** `..\Remolques_gondola`  

---

## 1. Resumen Ejecutivo

Siguiendo la solicitud de Luis, se ha transformado el volumen de la góndola de ser un valor fijo incrustado en el nombre comercial (`GONDOLA 2 EJES 45 M3`, `GONDOLA 3 EJES 45 M3`) a una **opción configurable** en el sistema:
1. **Nuevo grupo de configuración `volumen`**: Opciones `m3_45` (por defecto, conservando exactamente los costos y piezas actuales) y `m3_30` (aproximación proporcional provisional para la góndola de 30 m³).
2. **Nueva escala `por_volumen`**: Integrada en la base de datos (restricciones `CHECK`, RPCs) y en el motor TypeScript (`escalas.ts`).
3. **Unificación del cálculo de cantidad**: Se eliminó la duplicación de funciones de cálculo en `costeo.ts`, `resolver_receta.ts`, `catalogo_costos.ts` y `recetas_editor.ts`, centralizándolo en `calcularCantidadEscalada`.
4. **Advertencia de costo provisional**: Cuando se selecciona 30 m³, el costeo y el despiece generan automáticamente una advertencia de tipo `variante_supuesta`: *"Costo de 30 m³ estimado por proporción sobre 45 m³; pendiente despiece real"*.
5. **Nombres dinámicos**: El configurador, el generador de especificaciones y la ficha de orden de trabajo ensamblan el modelo como `GONDOLA ${num_ejes} EJES ${volumen} M3`.
6. **Seguridad de Snapshots**: Las cotizaciones y órdenes de trabajo existentes permanecen completamente inmutables; el nombre dinámico solo aplica al configurar o guardar nuevas cotizaciones.
7. **Verificación exhaustiva**: 11/11 verificaciones aprobadas en `scripts/verificar.mjs --limpio`, con **258 pruebas Deno exitosas (0 fallos)** y arranque real del API comprobado.

---

## 2. Historial de Commits en la Rama

La implementación se dividió en 5 commits atómicos y limpios:

1. **`b9fd8b4`** — `feat(db): agregar grupo volumen para gondola y escala por_volumen`
   - Migración `supabase/migrations/20261105_01_gondola_volumen.sql`.
   - Recreación de restricciones `CHECK (escala IN ('fija', 'por_eje', 'por_largo', 'por_volumen'))` en `receta_base`, `opcion_componentes`, `costos_modelo` y `opcion_costos`.
   - Actualización de RPC `guardar_linea_receta` para admitir `'por_volumen'`.
   - Creación multi-tenant del grupo `volumen` (`clave = 'volumen'`, `seleccion = 'unica'`, `aplica_a = ARRAY['gondola']`, `orden = 165`) y opciones `m3_45` y `m3_30`.
   - Renombrado seguro de productos terminados en la base de datos a `GONDOLA 2 EJES` y `GONDOLA 3 EJES`.

2. **`892773b`** — `feat(motor): unificar calculo de escalas con soporte para por_volumen`
   - Módulo compartido `supabase/functions/make-server-feea4382/motor/escalas.ts` con constante `VOLUMEN_BASE_GONDOLA_M3 = 45`, `resolverVolumenGondola()` y `calcularCantidadEscalada()`.
   - Unificación de `costeo.ts`, `resolver_receta.ts`, `catalogo_costos.ts` y `recetas_editor.ts`.
   - Generación de advertencia `variante_supuesta` cuando `volumen === 30`.

3. **`97cf5d4`** — `feat(ui): nombre dinamico con volumen para gondola y visualizacion en configurador`
   - `ConfiguradorEquipo.tsx`: Preselección automática de `m3_45` y encabezado dinámico con volumen.
   - `texto_especificacion.ts`: Encabezado `GONDOLA ${num_ejes} EJES ${volumen} M3` y omisión de grupo `volumen` en líneas de cuerpo para evitar repeticiones.
   - `ficha_orden_trabajo.ts`: Soporte para sufijo de volumen en `formatearCantidadTexto`.
   - `ChecklistDespieceModal.tsx`: Visualización de volumen en el checklist de almacén y vale de materiales.

4. **`bc9092a`** — `feat(recetas): marcar lineas de tina de gondola con escala por_volumen`
   - Migración independiente `supabase/migrations/20261105_02_gondola_volumen_escalas.sql`.
   - Renglones de la tina marcados con `por_volumen` en `receta_base` y en `opcion_componentes` (`tina_material`).
   - Renglones de chasis, suspensión y patines preservados con `fija`.

5. **`b2453a5`** — `test(gondola): pruebas unitarias y de base de datos para volumen configurable`
   - Script SQL `docs/gondola/verificacion_volumen.sql` (devuelve `todo_ok = true`).
   - Script SQL transaccional `docs/gondola/prueba_volumen.sql` (con `ROLLBACK`).
   - Suite de 6 pruebas unitarias en `gondola_volumen.test.ts`.

---

## 3. Tabla de Propuesta: Los 49 Renglones de Acero Base de Góndola

En la migración `20261014_02_gondola.sql`, la sección `'acero'` de la receta base cuenta con **49 renglones**. Todos fueron analizados detalladamente para clasificar si pertenecen a la **Tina** (escalan con el volumen) o al **Chasis / Suspensión / Patines** (permanecen fijos independientemente del volumen):

| # | Insumo / Material | Uso | Cant. Base (45 m³) | Cant. Propuesta (30 m³) | Escala | Clasificación | Costo Unit. | Subtotal 45 m³ | Subtotal 30 m³ | Racional |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | ALMA (PLACA DE GRADO A-50 CAL. 1/4") | Alma | 2 | 1.3333 | `por_volumen` | **Tina** | $12,500.00 | $25,000.00 | $16,666.67 | Vigas principales del cuerpo de la tina; se acortan/reducen con menor volumen |
| 2 | SOLERAS (SOLERA DE GRADO A-529 A 1/2" X 6") | Soleras | 4 | 2.6667 | `por_volumen` | **Tina** | $7,304.00 | $29,216.00 | $19,477.33 | Soleras longitudinales de la tina; longitud proporcional al volumen |
| 3 | PUENTES DE SUSPENSIÓN (PLACA DE GRADO A-36 CAL. 1/4") | Puentes de suspensión | 9 | 9 | `fija` | **Chasis** | $700.00 | $6,300.00 | $6,300.00 | Bastidor de suspensión; no varía con la capacidad de carga cúbica |
| 4 | PUENTES INTERMEDIOS (PLACA DE GRADO A-36 CAL. 1/4") | Puentes intermedios | 4 | 4 | `fija` | **Chasis** | $600.00 | $2,400.00 | $2,400.00 | Refuerzos estructurales del chasis inferior |
| 5 | PUENTES PARA PATINES (PLACA DE GRADO A-36 CAL. 3/16") | Puentes para patines | 2 | 2 | `fija` | **Chasis** | $440.00 | $880.00 | $880.00 | Estructura de anclaje de patines |
| 6 | CARTABON PARA PUENTE DE PATIN (PLACA DE GRADO A-36 CAL. 1/4") | Cartabon para puente de patin | 2 | 2 | `fija` | **Chasis** | $300.00 | $600.00 | $600.00 | Refuerzo de patín |
| 7 | PUENTES PARA PLANCHA (PLACA DE GRADO A-36 CAL. 1/4") | Puentes para plancha | 3 | 3 | `fija` | **Chasis** | $700.00 | $2,100.00 | $2,100.00 | Estructura frontal de quinta rueda |
| 8 | BORDA DELANTERA (PLACA DE GRADO A-36 CAL. 3/16") | Borda delantera | 1 | 0.6667 | `por_volumen` | **Tina** | $480.00 | $480.00 | $320.00 | Remate perimetral superior de la tina |
| 9 | PLANCHA (PLACA DE GRADO A-36 CAL. 3/8") | Plancha | 1 | 1 | `fija` | **Chasis** | $3,235.00 | $3,235.00 | $3,235.00 | Plancha perno rey de acople al tracto |
| 10 | ATISADOR (SOLERA DE GRADO A-36 A 3/8" X 2") | Atisador | 6 | 6 | `fija` | **Chasis** | $40.00 | $240.00 | $240.00 | Refuerzos internos de vigas |
| 11 | ATISADOR (SOLERA DE GRADO A-36 A 3/8" X 2") | Atisador | 18 | 18 | `fija` | **Chasis** | $75.00 | $1,350.00 | $1,350.00 | Refuerzos internos de vigas |
| 12 | KIT DE PERNOS | Kit de pernos | 1 | 1 | `fija` | **Chasis** | $13,000.00 | $13,000.00 | $13,000.00 | Perno rey y herrajes de acople estándar |
| 13 | BASE PARA TANQUES (PLACA DE GRADO A-36 CAL. 1/4") | Base para tanques | 4 | 4 | `fija` | **Chasis** | $77.00 | $308.00 | $308.00 | Soporte tanques de aire comprimido |
| 14 | JALON PLACA BASE (PLACA DE GRADO A-36 CAL. 1/2") | Jalon | 1 | 1 | `fija` | **Chasis** | $2,500.00 | $2,500.00 | $2,500.00 | Mecanismo de jalón posterior |
| 15 | JALON REFUERZO (PLACA DE GRADO A-36 CAL. 3/8") | Jalon | 1 | 1 | `fija` | **Chasis** | $600.00 | $600.00 | $600.00 | Refuerzo de jalón posterior |
| 16 | JALON CARTABONES | Jalon | 2 | 2 | `fija` | **Chasis** | $400.00 | $800.00 | $800.00 | Cartabones de jalón |
| 17 | BASE PARA ESTRIBO PLACA (PLACA DE GRADO A-36 CAL. 1/4") | Base para estribo | 1 | 1 | `fija` | **Chasis** | $130.00 | $130.00 | $130.00 | Acceso de operador |
| 18 | BASE PARA ESTRIBO SOLERA FRONTAL | Base para estribo | 2 | 2 | `fija` | **Chasis** | $170.00 | $340.00 | $340.00 | Acceso de operador |
| 19 | BASE PARA ESTRIBO SOLERA POSTERIOR | Base para estribo | 2 | 2 | `fija` | **Chasis** | $65.00 | $130.00 | $130.00 | Acceso de operador |
| 20 | ESTRIBO (PTR 4X4") | Estribo | 1 | 1 | `fija` | **Chasis** | $1,050.00 | $1,050.00 | $1,050.00 | Escalón / estribo |
| 21 | C PARA GATO (PLACA DE GRADO A-36 CAL. 3/8") | C para gato | 4 | 4 | `fija` | **Chasis** | $350.00 | $1,400.00 | $1,400.00 | Base para soporte hidráulico de volteo |
| 22 | BASE PARA MANITAS (PLACA DE GRADO A-36 CAL. 1/4") | Base para manitas | 1 | 1 | `fija` | **Chasis** | $101.00 | $101.00 | $101.00 | Conexiones de aire tractocamión |
| 23 | PORTA LODERAS (PLACA DE GRADO A-36 CAL. 10) | Porta loderas | 2 | 2 | `fija` | **Chasis** | $380.00 | $760.00 | $760.00 | Soporte para loderas de goma |
| 24 | U PARA JALON (REDONDO DE 1") | U para jalon | 1 | 1 | `fija` | **Chasis** | $102.00 | $102.00 | $102.00 | Herraje jalón |
| 25 | BASE PARA PERCHAS (SOLERA DE GRADO A-36 A 1/2" X 6") | Base para perchas | 6 | 6 | `fija` | **Chasis** | $234.00 | $1,404.00 | $1,404.00 | Montaje de suspensión mecánica/neumática |
| 26 | BASE PARA PLATOS (SOLERA DE GRADO A-36 A 1/2" X 3") | Base para platos | 6 | 6 | `fija` | **Chasis** | $67.00 | $402.00 | $402.00 | Platos de suspensión |
| 27 | TAPA PARA PERNO REY (CANAL U 6") | Tapa para perno rey | 1 | 1 | `fija` | **Chasis** | $100.00 | $100.00 | $100.00 | Protección perno rey |
| 28 | BASE PARA PATINES PLACAS (PLACA DE GRADO A-36 CAL. 1/4") | Base para patines | 8 | 8 | `fija` | **Chasis** | $52.60 | $420.80 | $420.80 | Placas soporte patines |
| 29 | BASE PARA PATINES SOLERA (SOLERA DE GRADO A-36 A 3/8" X 2") | Base para patines | 8 | 8 | `fija` | **Chasis** | $23.40 | $187.20 | $187.20 | Soleras soporte patines |
| 30 | BASE PARA FOCO DE ABS (PLACA DE GRADO A-36 CAL. 1/4") | Base para foco de ABS | 1 | 1 | `fija` | **Chasis** | $22.60 | $22.60 | $22.60 | Soporte indicador eléctrico |
| 31 | BASE PARA ABS (PLACA DE GRADO A-36 CAL. 1/4") | Base para ABS | 1 | 1 | `fija` | **Chasis** | $28.00 | $28.00 | $28.00 | Soporte válvula ABS |
| 32 | PORTA PLACAS (PLACA DE GRADO A-36 CAL. 10) | Porta placas | 1 | 1 | `fija` | **Chasis** | $45.00 | $45.00 | $45.00 | Porta placa vehicular |
| 33 | HERAJE PARA PATINES 110CM (PLACA DE GRADO A-36 CAL. 3/16") | Heraje para patines | 2 | 2 | `fija` | **Chasis** | $196.99 | $393.98 | $393.98 | Refuerzo diagonal patines |
| 34 | HERAJE PARA PATINES 125CM | Heraje para patines | 2 | 2 | `fija` | **Chasis** | $223.99 | $447.98 | $447.98 | Refuerzo diagonal patines |
| 35 | HERAJE PARA PATINES 70CM | Heraje para patines | 2 | 2 | `fija` | **Chasis** | $124.99 | $249.98 | $249.98 | Refuerzo diagonal patines |
| 36 | HERAJE PARA PATINES 67CM | Heraje para patines | 4 | 4 | `fija` | **Chasis** | $119.99 | $479.96 | $479.96 | Refuerzo diagonal patines |
| 37 | HERAJE PARA PATINES 23CM | Heraje para patines | 2 | 2 | `fija` | **Chasis** | $41.99 | $83.98 | $83.98 | Refuerzo diagonal patines |
| 38 | HERAJE PARA PATINES 7CM (SOLERA DE GRADO A-36 A 1/2" X 3") | Heraje para patines | 2 | 2 | `fija` | **Chasis** | $23.99 | $47.98 | $47.98 | Refuerzo diagonal patines |
| 39 | HERAJE PARA PATINES 27CM | Heraje para patines | 2 | 2 | `fija` | **Chasis** | $90.99 | $181.98 | $181.98 | Refuerzo diagonal patines |
| 40 | HERAJE PARA PATINES 30CM | Heraje para patines | 2 | 2 | `fija` | **Chasis** | $100.99 | $201.98 | $201.98 | Refuerzo diagonal patines |
| 41 | HERAJE PARA PATINES BUCHACA (PLACA DE GRADO A-36 CAL. 1/4") | Heraje para patines | 4 | 4 | `fija` | **Chasis** | $40.99 | $163.96 | $163.96 | Anclaje patines |
| 42 | PORTA LLANTAS (PLACA DE GRADO A-36 CAL. 1/4") | Porta Llantas | 4 | 4 | `fija` | **Chasis** | $87.99 | $351.96 | $351.96 | Porta llanta de refacción |
| 43 | PORTA LLANTAS (PLACA DE GRADO A-36 CAL. 1/4") | Porta Llantas | 2 | 2 | `fija` | **Chasis** | $275.99 | $551.98 | $551.98 | Porta llanta de refacción |
| 44 | PORTA LLANTAS (SOLERA DE GRADO A-36 A 1/2" X 3") | Porta Llantas | 2 | 2 | `fija` | **Chasis** | $738.99 | $1,477.98 | $1,477.98 | Porta llanta de refacción |
| 45 | PORTA LLANTAS (REDONDO DE 1") | Porta Llantas | 2 | 2 | `fija` | **Chasis** | $400.00 | $800.00 | $800.00 | Porta llanta de refacción |
| 46 | TUBOS PARA CABLEADO (TUBO DE 1 1/2" CED. 40) | Tubos para cableado | 20 | 20 | `fija` | **Chasis** | $10.99 | $219.80 | $219.80 | Conducción eléctrica a lo largo del chasis |
| 47 | CHAMBER PARA PUERTAS | Chamber para puertas | 2 | 2 | `fija` | **Tina (Actuador)** | $487.99 | $975.98 | $975.98 | Cilindro neumático de apertura de compuerta; siempre son 2 actuadores |
| 48 | REFUERZO TRUZA (PLACA DE GRADO A-36 CAL. 1/4") | Refuerzo truza | 12 | 12 | `fija` | **Chasis** | $82.99 | $995.88 | $995.88 | Refuerzo de cuello / kingpin |
| 49 | CAJON PARA CASQUILLO TRASERO (PLACA DE GRADO A-36 CAL. 1/4") | Cajon para casquillo trasero | 2 | 1.3333 | `por_volumen` | **Tina** | $340.00 | $680.00 | $453.33 | Estructura trasera de articulación de volteo |

### Resumen del Acero Base de Góndola:
- **Total 45 m³:** **$103,936.96** (exacto al centavo con el control de 2R-1f).
- **Total estimado 30 m³:** **$85,478.43** (ahorro provisional de $18,458.53 en el acero base, correspondiente al 33.3% de reducción en los componentes principales del cuerpo de la tina: Alma, Soleras, Borda y Cajón casquillo).

---

## 4. Componentes de Tina en `opcion_componentes` (`tina_material`)

En la arquitectura del sistema (migración `20261014_02_gondola.sql`), las placas que forman las paredes, piso y frente de la tina no están en `receta_base` sino en la tabla `opcion_componentes` bajo el grupo `tina_material` (opciones `a36` y `hardox_450`).

En la migración `20261105_02_gondola_volumen_escalas.sql` también se marcaron con `escala = 'por_volumen'` las líneas que conforman el cuerpo de la tina:
- **Láminas y paredes:** `Piso`, `Placas laterales para tina`, `Placa frontal`, `Placa para tapa`, `Vueltas traseras`, `Cuellos`, `Vueltas frontales`, `Borda trasera`, `Resvalon`, `Poste trasero`, `Charola`, `Aletas traseras`.
- **Estructura HSS:** `HSS inferior`, `HSS superior`, `HSS frontal`, `Refuerzo interno de tina`, `Brasos frontales`, `Brasos traseros`.
- **Paquetes Hardox:** `PAQUETE TINA HARDOX 450 (VUELTAS TRASERAS, CUELLOS, VUELTAS FRONTALES)` y `PAQUETE TINA HARDOX 450 (PISO, PLACA FRONTAL, PLACA PARA TAPA)`.
- **Herrajes de tina menores:** `Ganchos para lonas`, `Escalera`, `Tornilleria para tapa` y `Salpicaderas` se mantuvieron en `fija`.

Esto garantiza que al seleccionar 30 m³, el costeo proporcional reduzca tanto el acero base como las láminas de la tina en proporción directa `30 / 45`.

---

## 5. Investigación de Snapshots y Retrocompatibilidad

Se revisó el flujo de datos para confirmar que cotizaciones y órdenes ya emitidas no cambien de nombre ni de costo:
1. **Cotizaciones (`cotizaciones`)**: Los renglones en `cotizaciones.items` almacenan el snapshot del texto en `item.descripcion`. Las cotizaciones históricas conservan su texto intacto. Solo cuando se reconfigura o se crea una cotización nueva se calcula el nuevo encabezado con volumen.
2. **Órdenes de Trabajo (`ordenes_trabajo`)**: Guardan snapshots en `caracteristicas` (`ficha` y `descripcion_corta`). Las órdenes pasadas no sufren alteración. En la impresión del vale de entrega de materiales (`ChecklistDespieceModal.tsx`), el helper `resolverModeloChecklist` detecta dinámicamente si la orden trae `volumen: 'm3_30'` o `'m3_45'` para reflejarlo en la cabecera del PDF/impresión.
3. **Presupuestos (`presupuestos`)**: Guardan su estructura en `datos jsonb`. No se recalculan automáticamente; respetan el histórico generado.

---

## 6. Advertencia de Costo Provisional (`variante_supuesta`)

Tal como solicitó Luis, el costo para 30 m³ es una aproximación proporcional y está marcado como provisional.
- En `costeo.ts`, cuando se detecta `volumen === 30`, se inyecta en `resultado.pendientes`:
  ```json
  {
    "tipo": "variante_supuesta",
    "detalle": "Costo de 30 m³ estimado por proporción sobre 45 m³; pendiente despiece real"
  }
  ```
- En `resolver_receta.ts`, al resolver el despiece de 30 m³, se inyecta la misma leyenda en `resultado.advertencias`.
- Esta advertencia es visible en el modal del configurador y viaja en la cotización dentro de `meta.pendientes`.

---

## 7. Verificación de Código y Pruebas Unitarias

### Resultado de `scripts/verificar.mjs --limpio`:
```
== 1. Archivos de parche o temporales nuevos
  OK     Sin parches ni temporales

== 2. Codificación de los archivos modificados
  OK     UTF-8 sin BOM ni mojibake — 15 archivos revisados

== 3. Sintaxis de .ts/.tsx modificados
  OK     Sintaxis válida

== 4. TypeScript (tsc --noEmit)
  OK     tsc: 0 nombres sin definir/duplicados
  OK     tsc: el total de errores no sube — 44 (baseline 55)

== 5. Build de Vite
  OK     npm run build

== 6. Pruebas Deno
  OK     Pruebas Deno — 258 pasan, 0 fallan

== 7. Arranque real del API
  OK     El API arranca — Listening on http://localhost:8000/

== 8. Contexto del Dockerfile.backend
  OK     Contexto del Dockerfile.backend — deno cache index.ts exitoso

== 9. Checkout limpio de HEAD (git archive)
  OK     Pruebas Deno en HEAD limpio — 258 pasan, 0 fallan
  OK     El API arranca en HEAD limpio — Listening on http://localhost:8000/

============================================================
RESULTADO: TODO OK  (11/11 comprobaciones)
```

### Pruebas Unitarias de `gondola_volumen.test.ts`:
- **Test 1:** Volumen 45 m³ costo y despiece idénticos a regresión previa (factor 1.0, 0 advertencias de variante_supuesta).
- **Test 2:** Volumen 30 m³ escala tina proporcionalmente (factor 30/45), fijos intactos y emite advertencia `variante_supuesta`.
- **Test 3:** Ausencia de grupo volumen toma 45 m³ por defecto sin advertencias.
- **Test 4:** Plataforma y Dolly no son alterados ni afectados por volumen.
- **Test 5:** Consistencia de cálculo de escalas y helper unificado entre costeo y despiece BOM.
- **Test 6:** Formato exacto de nombres dinámicos con volumen (`GONDOLA 2 EJES 30 M3`, `GONDOLA 2 EJES 45 M3`, `Una Góndola 2 ejes 30 m³`).

---

## 8. Instrucciones para Despliegue (Luis)

Cuando Claude revise y apruebe esta rama, los pasos para desplegar en producción son:

1. **Merge a `main`** desde la rama `gondola-volumen-2026-11-05`.
2. **Ejecutar migraciones en Supabase SQL Editor** (en este orden exacto):
   - `supabase/migrations/20261105_01_gondola_volumen.sql` (Crea grupo, opciones y restricciones).
   - `supabase/migrations/20261105_02_gondola_volumen_escalas.sql` (Marca renglones de tina con `por_volumen`).
3. **Ejecutar verificación en Supabase SQL Editor**:
   - Correr `docs/gondola/verificacion_volumen.sql` y confirmar que devuelva `todo_ok = true`.
4. **Rebuild en EasyPanel**:
   - Servicio `remolques-api` (Backend Deno).
   - Servicio `remolques-web` (Frontend Vite).
