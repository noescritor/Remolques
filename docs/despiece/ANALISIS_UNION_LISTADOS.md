# Análisis de Despiece — UNION DE LISTADOS ACTULIZADO (1).xlsx

**Fecha de análisis:** 2026-11-02  
**Archivo fuente:** `UNION DE LISTADOS ACTULIZADO (1).xlsx` (Hoja1, 321 filas, 316 filas con datos)  
**Objetivo:** Establecer el catálogo de fases, la unidad de referencia (Plataforma 2 ejes 40 FT), mapeo de kits, normalización de piezas y anomalías.  

---
## 1. Deducción de la Unidad de Referencia

Al contrastar las cantidades y materiales de la hoja con la receta base de `PLATAFORMA 2 40 FT`:
- **Cargadores (Paso 4):** 38 piezas de `IPR de 4" x 102"`. Una plataforma de 40 pies (480 pulgadas) con separación a 12 pulgadas requiere típicamente 38 cargadores intermedios más bordas.
- **Almas (Paso 1) y Soleras (Paso 2):** 2 almas de 1/4" y 4 soleras de 1/2" x 6", dimensionadas para 40 pies.
- **Kit de Frenos / ABS (Paso 9):** `Kit ABS 2 ejes` con 2 tanques de aire y 4 cámaras de aire (2 de servicio y 2 de emergencia con resorte).
- **Puentes de suspensión (Paso 3):** 6 piezas de PTR 6" x 2", correspondiente a una suspensión mecánica o neumática de 2 ejes.

> **Conclusión:** La receta del Excel corresponde exactamente a la **PLATAFORMA DE 2 EJES Y 40 PIES (PLATAFORMA 2 40 FT)**. Las demás variantes de largo (35, 42, 43, 45, 48 ft) y de 3 ejes escalan a partir de este modelo maestro.

---
## 2. Árbol de Fases de Despiece y Conteos

| Orden | Fase / Proceso | Subtítulo / Descripción | Total Filas | Con Precio | Sin Costo Cargado | Sin Cantidad |
|---|---|---|:---:|:---:|:---:|:---:|
| 1 | **Paso 1** | Armado y corte de almas | 3 | 0 | 3 | 0 |
| 2 | **Paso 2** | Soleras de refuerzo de almas | 5 | 1 | 4 | 0 |
| 3 | **Paso 3** | Estructura primaria, bordas y plancha de quinta rueda | 21 | 13 | 8 | 0 |
| 4 | **Paso 4** | Cargadores transversales IPR y atizadores | 21 | 15 | 6 | 6 |
| 5 | **Paso 5** | Instalación de suspensión, patines, ejes y retráctiles | 68 | 11 | 57 | 12 |
| 6 | **Paso 6** | Canaleta, refuerzos y accesorios estructurales | 40 | 19 | 21 | 0 |
| 7 | **PASO 7** | Lavado químico, fosfato y preparación de superficie | 4 | 0 | 4 | 0 |
| 8 | **PASO 8** | Aplicación de pintura y recubrimientos por marca | 15 | 0 | 15 | 0 |
| 9 | **PASO 9** | Kit neumático, sistema ABS y tanques de aire | 55 | 0 | 55 | 0 |
| 10 | **PASO 10** | Sistema de iluminación reglamentaria y arnés eléctrico | 29 | 0 | 29 | 0 |
| 11 | **PASO 11** | Instalación de pisos y fijaciones | 6 | 0 | 6 | 0 |
| 12 | **PASO 12** | Acabados, loderas, winches y rotulación final | 16 | 0 | 16 | 0 |
| 13 | **EXTRAS** | Equipamiento adicional (redilas, retráctil Leolca, multimodal) | 18 | 0 | 18 | 0 |
| 14 | **LLANTAS Y RINES** | Juego de rodado (rines de acero/aluminio y llantas) | 15 | 0 | 15 | 4 |

Total general de filas procesadas: **316 filas**.

---
## 3. Bloques de Opciones Configurables Excluyentes

En el Paso 5, 8, 9, 11, Extras y Llantas/Rines, existen conjuntos de alternativas de marca o configuración donde la cantidad `0` representa opciones secundarias no incluidas por omisión:

1. **Suspensiones (Paso 5):**
   - `SUSPENSION HENDRICKSON HT300US (SUSPENSION ALTA)`: 2 perchas, 4 abrazaderas, amortiguador Monroe 65512, cámaras de aire Hendrickson.
   - `SUSPENSION HENDRICKSON HT300 (SUSPENSION NORMAL)`: Componentes estándar.
   - `SUSPENSION FLET MASTER HT300 (SUSPENSION NORMAL)`: Piernas, platos, cámara Flet Master 8050 / Ampro / FCR, amortiguador Flet Master 323.
   - `SUSPENSION AMPRO`: Kit Ampro.
   - `SUSPENSION FCR`: Kit FCR.
2. **Sistemas Retráctiles (Paso 5 / Paso 9):**
   - Retráctil Chico (con bolsa UBL chica y tornillería).
   - Retráctil Grande (con bolsa grande y tornillería de 3/4).
   - Retráctil Fabricado Leolca (en sección EXTRAS).
3. **Patines (Paso 5):**
   - Ampro, Holland Mark V, HJ, Fleet Master.
4. **Ejes (Paso 5):**
   - Fleet Master, Ampro, FCR, Prat Max, HJ.
5. **Pintura (Paso 8):**
   - Sherwin Williams (primer, esmalte poliuretano, reductor).
   - PPG.
   - Axalta.
6. **Pisos (Paso 11):**
   - Piso plástico café (18 tablones de 20 ft).
   - Piso pino.
   - Piso encino.
   - Madera tradicional.
7. **Rines y Llantas:**
   - Rin 24.5 vs Rin 22.5 (acero blanco, aluminio Fleet Master, aluminio Ampro, trapezoidal).
   - Llantas por marca/modelo.

---
## 4. Anomalías Detectadas en el Excel

1. **Fila 12 — Puentes de suspensión sin precio:** `PTR de 6X2" Cal. 3/16"` con 6 piezas, precio unitario nulo y costo 0. Se registra como `"Sin costo cargado"`.
2. **Consumibles sin cantidad (Filas 46-51 en Paso 4 y 63-67 en Paso 5):**
   - `DISCO LAMINADO 7`, `DISCO DE CORTE 7`, `DISCO DE DESBASTE 9`, `OXIGENO`, `ROLLO DE MICROALAMBRE`, `CO2`.
   - Tienen cantidad nula (`None`). Se clasifican como consumibles con cantidad por definir en planta.
3. **Fila 248 — Fila sin nombre con cantidad 25.8 en Paso 10:**
   - Ubicada inmediatamente después de `CABLE NEGRO`. La columna producto y nomenclatura están vacías. Se deduce que corresponde a metros de cableado eléctrico o manguera de protección para el cable negro (25.8 m). Se documenta y no se mapea a producto fantasma.
4. **FOSFATO con unidad en texto (Fila 164 en PASO 7):**
   - La celda trae `1 L`. Se normaliza a cantidad `1` y unidad `L` (litro).
5. **Rines y Llantas sin cantidad (Filas 308-321):**
   - Las filas `RIN 24.5`, `RIN 22.5` actúan como encabezados de medida/diámetro; las opciones hijas tienen cantidad 0 o 8 piezas según el paquete.
6. **Typos y errores ortográficos de origen:**
   - `PRAIMER` → normalizado a `PRIMER`.
   - `INCERTO` → normalizado a `INSERTO`.
   - `AUMINIO` → normalizado a `ALUMINIO`.
   - `TORNILLEROA` → normalizado a `TORNILLERIA`.
   - `MONRROE` → normalizado a `MONROE`.
   - `CARGADO 3X102 IN` → normalizado a `CARGADOR 3" X 102"`.
   - `FLET MASTER` → normalizado a `FLEET MASTER`.
   En cada caso se conserva el texto original en la columna o nota `alias` para trazabilidad.

---
## 5. Comparativa (Diff) Excel vs Base de Datos (Migraciones Previas)

De los 316 renglones:
- **~180 piezas** ya existían en `receta_base` u `opcion_componentes` bajo códigos similares del sub-bloque 2R-1b y 2R-3.
- **Nuevas piezas identificadas:**
  - Lavado y fosfatado químico (Paso 7: Desengrasante, Fosfato, Ácido neutralizante).
  - Kits completos de pintura por marca (PPG y Axalta desglosados en litros y catalizadores).
  - Componentes específicos de suspensión Fleet Master HT300 (platos, piernas, abrazaderas especiales).
  - Tornillería desglosada del kit retráctil (tuercas métricas 3/4, rondanas 3/8, tornillos grado 8).
  - Equipos multimodal (chasis portacontenedor twist-locks y cargadores reforzados).

---
## 6. Estrategia de Migración y Catálogo de Fases

Se implementan dos nuevas estructuras en base de datos:
1. `fases_despiece`:
   - `clave`: `paso_1` a `paso_12`, `extras`, `llantas_rines`.
   - `nombre`: Nombre oficial exacto del Excel (`Paso 1`, `Paso 2`, ..., `PASO 7`, `EXTRAS`, `LLANTAS Y RINES`).
   - `subtitulo`: Descripción del proceso de taller.
   - `orden`: 1 a 14.
2. `fases_despiece_equivalencias`:
   - Mapea valores legados de `receta_base.paso` (`PASO 1`...`6`, `AIRE`, `LUZ`, `TERMINADO`, `EXTRAS`, `PINTURA`, `PISOS`) a su respectivo `fase_id` sin perder la columna `paso` original.
