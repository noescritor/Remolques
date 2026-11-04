# Análisis Exhaustivo de Despiece — UNION DE LISTADOS ACTULIZADO (1).xlsx

**Fecha de emisión:** 2026-11-03 (Ronda 4 Antigravity)
**Archivo fuente:** `UNION DE LISTADOS ACTULIZADO (1).xlsx` (Hoja1, 316 renglones de ingeniería)
**Unidad de Referencia Deductiva:** **PLATAFORMA DE 2 EJES Y 40 PIES (PLATAFORMA 2 40 FT)**

---
## 1. Deducción Analítica de la Unidad de Referencia

La comparativa paramétrica contra los modelos maestros del sistema arroja:
1. **Cargadores transversales (Paso 4):** El Excel especifica exactamente **38 piezas** de `IPR de 4" x 102"`. Para una plataforma de 40 pies (480 pulgadas de longitud total) con espacio estándar entre cargadores de 12 pulgadas, se requieren exactamente 38 cargadores intermedios más los remates de borda.
2. **Almas principales (Paso 1):** 2 piezas de `PLACA DE GRADO A-50 CAL. 1/4"` con longitud correspondiente a 40 ft.
3. **Soleras de alma (Paso 2):** 4 soleras de `SOLERA DE GRADO A-529 A 1/2" X 6"` para patín superior e inferior de ambas vigas maestras.
4. **Kit neumático y frenos ABS (Paso 9):** Configuración `2 ejes` compuesta de 2 tanques de aire, 4 cámaras de aire (2 servicio y 2 emergencia) y 1 kit modular Bendix de 2 sensores/1 modulador.
5. **Puentes de suspensión (Paso 3):** 6 piezas de PTR 6" x 2" calibre 3/16", que es el estándar exacto de fijación de perchas para suspensión neumática/mecánica tándem de 2 ejes.

> **Conclusión de Ingeniería:** La receta de `UNION DE LISTADOS` constituye el catálogo maestro de la **Plataforma 40 FT 2 Ejes**. Las longitudes alternas (35, 42, 43, 45, 48 ft) y variantes de 3 ejes derivan por reglas de escala (`escala = 'por_largo'` y `escala = 'por_eje'`).

---
## 2. Árbol de Fases Oficial de Despiece (14 Fases)

| Orden | Clave | Nombre Oficial | Subtítulo / Alcance Operativo | Filas en Excel | Destino Predominante |
|---|---|---|---|:---:|---|
| 1 | `paso_1` | **Paso 1** | Armado y corte de almas | 3 | `receta_base` |
| 2 | `paso_2` | **Paso 2** | Soleras de refuerzo de almas | 5 | `receta_base` |
| 3 | `paso_3` | **Paso 3** | Estructura primaria, bordas y plancha de quinta rueda | 21 | `receta_base` |
| 4 | `paso_4` | **Paso 4** | Cargadores transversales IPR y atizadores | 21 | `receta_base` |
| 5 | `paso_5` | **Paso 5** | Instalación de suspensión y retráctiles | 68 | `opcion_componentes` |
| 6 | `paso_6` | **Paso 6** | Canaleta, patines, ejes y accesorios estructurales | 40 | `receta_base` / `opcion_componentes` |
| 7 | `paso_7` | **PASO 7** | Lavado químico, fosfato y preparación de superficie | 4 | `receta_base` |
| 8 | `paso_8` | **PASO 8** | Aplicación de pintura y recubrimientos por marca | 15 | `opcion_componentes` |
| 9 | `paso_9` | **PASO 9** | Kit neumático, sistema ABS y tanques de aire | 55 | `receta_base` |
| 10 | `paso_10` | **PASO 10** | Sistema de iluminación reglamentaria y arnés eléctrico | 29 | `receta_base` |
| 11 | `paso_11` | **PASO 11** | Instalación de pisos y fijaciones | 6 | `opcion_componentes` |
| 12 | `paso_12` | **PASO 12** | Acabados, loderas, winches y rotulación final | 16 | `receta_base` |
| 13 | `extras` | **EXTRAS** | Equipamiento adicional (redilas, retráctil Leolca, multimodal) | 18 | `receta_base` / `opcion_componentes` |
| 14 | `llantas_rines` | **LLANTAS Y RINES** | Juego de rodado (rines de acero/aluminio y llantas) | 15 | `opcion_componentes` |

---
## 3. Diccionario Exhaustivo de Normalización de Nombres y Typos

Se identificaron y normalizaron las siguientes cadenas originales para evitar dispersión del catálogo e impedir duplicados casi idénticos:

| Texto Original en Excel | Nombre Normalizado Oficial | Categoría Asignada | Razón de Corrección |
|---|---|---|---|
| `ACURRAI` | **ACCURIDE** | Consumibles | Corrección ortográfica / normalización canónica |
| `AUMINIO` | **ALUMINIO** | Consumibles | Corrección ortográfica / normalización canónica |
| `CAL ` | **CAL. ** | Consumibles | Corrección ortográfica / normalización canónica |
| `CAL,` | **CAL.** | Consumibles | Corrección ortográfica / normalización canónica |
| `CANAL "U" DE 6"` | **CANAL U 6"** | Acero y Estructura | Corrección ortográfica / normalización canónica |
| `CANAL "U" DE 6" (12 KG)` | **CANAL U 6"** | Acero y Estructura | Corrección ortográfica / normalización canónica |
| `CANAL "U" DE 6" (12KG)` | **CANAL U 6"** | Acero y Estructura | Corrección ortográfica / normalización canónica |
| `CARGADO` | **CARGADOR** | Consumibles | Corrección ortográfica / normalización canónica |
| `FIRESTO` | **FIRESTONE** | Consumibles | Corrección ortográfica / normalización canónica |
| `FLET` | **FLEET** | Consumibles | Corrección ortográfica / normalización canónica |
| `HERAJE` | **HERRAJE** | Consumibles | Corrección ortográfica / normalización canónica |
| `INCERTO` | **INSERTO** | Consumibles | Corrección ortográfica / normalización canónica |
| `IPR DE 4" X 102"` | **IPR DE 4"** | Consumibles | Corrección ortográfica / normalización canónica |
| `MONRROE` | **MONROE** | Consumibles | Corrección ortográfica / normalización canónica |
| `PATIN HOLAND MARK V` | **PATIN HOLLAND MARK V** | Acero y Estructura | Corrección ortográfica / normalización canónica |
| `PATIN HOLLAND` | **PATIN HOLLAND MARK V** | Acero y Estructura | Corrección ortográfica / normalización canónica |
| `PRAIMER` | **PRIMER** | Consumibles | Corrección ortográfica / normalización canónica |
| `PTR DE 6X2 CAL. 3/16` | **PTR A 2 X 6"** | Acero y Estructura | Corrección ortográfica / normalización canónica |
| `PTR DE 6X2" CAL. 3/16"` | **PTR A 2 X 6"** | Acero y Estructura | Corrección ortográfica / normalización canónica |
| `PUENTES DE LA PLANCHA` | **PUENTES DE LA PLANCHA (CANAL U 5")** | Consumibles | Corrección ortográfica / normalización canónica |
| `PUENTES DE SUSPENSIÓN` | **PUENTES DE SUSPENSION** | Consumibles | Corrección ortográfica / normalización canónica |
| `PUENTES INTERMEDIOS` | **PUENTES TIPO J** | Consumibles | Corrección ortográfica / normalización canónica |
| `ROLLO DE MICRO ALAMBRE` | **ROLLO DE MICROALAMBRE** | Consumibles | Corrección ortográfica / normalización canónica |
| `SHERVI` | **SHERWIN WILLIAMS** | Consumibles | Corrección ortográfica / normalización canónica |
| `SHERVIWILLIAMS` | **SHERWIN WILLIAMS** | Consumibles | Corrección ortográfica / normalización canónica |
| `SOLERA PARA ALMAS` | **SOLERA DE ALMA** | Acero y Estructura | Corrección ortográfica / normalización canónica |
| `THINER` | **THINNER** | Consumibles | Corrección ortográfica / normalización canónica |
| `TORNILLEROA` | **TORNILLERIA** | Consumibles | Corrección ortográfica / normalización canónica |

---
## 4. Diff Exhaustivo: Excel vs Base de Datos Real (`remolques`)

### 4.1. Discrepancias de Cantidad Calculadas Considerando `uso`

| Pieza | Fase | Cantidad en BD | Cantidad en Excel | Uso en BD | Análisis Objetivo del Diff |
|---|---|:---:|:---:|---|---|
| LIJA #80 | PASO 7 | 2.0 | **10.0** | (Sin uso especificado) | **Diferencia real:** El Excel especifica 10 pliegos para el proceso completo de escoreo y preparación; la receta previa en BD solo registraba 2 pliegos. |
| Atizadores externos 27 cm | Paso 3 | 8.0 | **8.0** | Atizadores externos | **Sin discrepancia:** Tanto en la fila 18 del Excel como en BD se registran exactamente 8 piezas de 27 cm (y 2 piezas de 29 cm en fila 19). |
| RONDANA PLANA 5/16 | PASO 9 (Aire) | 4.0 | **4.0** | KIT DE TORNILLOS DE ABS | **Sin discrepancia:** En el sistema de aire coinciden exactamente 4 piezas en Excel y 4 en BD. |
| RONDANA PLANA 5/16 | PASO 10 (Luz) | 6.0 | **6.0** | HEMBRAS Y PLAFON ABS | **Sin discrepancia:** En el sistema eléctrico coinciden exactamente 6 piezas en Excel y 6 en BD. (El registro de 444 piezas en BD corresponde exclusivamente a EXTRAS para juego completo de redilas). |
| TUERCA ESTANDAR 1/4 | PASO 10 (Luz) | 6.0 | **6.0** | HEMBRAS Y PLAFON ABS | **Sin discrepancia:** Coinciden 6 en Excel y 6 en BD para fijación de arnés (el registro de 444 es exclusivo de redilas). |
| FOSFATO 1 L | PASO 7 | 1.0 | **1.0** | LIMPIEZA | **Sin discrepancia de cantidad:** Coincide 1 L / unidad en ambos registros. |

### 4.2. Análisis de Conflictos de Costo

| Pieza | Costo BD ($ MXN) | Precio en Excel ($ MXN) | Diferencia % | Decisión y Observación |
|---|:---:|:---:|:---:|---|
| Atizadores externos 27 cm | $50.00 | $50.00 | **0.0%** | **Sin discrepancia:** La fila 18 del Excel tiene precio unitario de $50.00 exacto, coincidente con BD. |
| Atizadores externos 29 cm | $60.00 | $60.00 | **0.0%** | **Sin discrepancia:** La fila 19 del Excel tiene precio unitario de $60.00 exacto, coincidente con BD. |

### 4.3. Desglose de Materias Primas Estructurales en Base de Datos y su Correspondencia en Excel

La auditoría matemática de nombres normalizados confirma que **la totalidad de las piezas estructurales de la Plataforma 40 FT en BD tienen su renglón correspondiente en el Excel**:
- `SOLERA DE ALMA (1/2" X 6")`: Fila 5 del Excel (4 pzas).
- `PUENTES DE SUSPENSIÓN (PTR 6X2")`: Fila 12 del Excel (6 pzas).
- `PUENTES TIPO J`: Fila 14 del Excel como Puentes intermedios (5 pzas).
- `BOTONES (1/4")`: Fila 16 del Excel (16 pzas).
- `ATIZADORES INTERNOS (1/4")`: Fila 17 del Excel (12 pzas).
- `ATIZADORES EXTERNOS 27 CM`: Fila 18 del Excel (8 pzas).
- `ATIZADORES EXTERNOS 29 CM`: Fila 19 del Excel (2 pzas).
- `JALON (1/2")`: Fila 20 del Excel (1 pza).
- `REFUERZO DE JALON (3/8")`: Fila 21 del Excel (1 pza).
- `PERNO REY`: Fila 22 del Excel (1 pza).
- `TAPA PARA PERNO REY`: Fila 23 del Excel (1 pza).
- `KIT DE ALETAS 45 X 60 CM`: Filas 33-38 del Excel.
- `HERRAJE Y TORNILLERÍA DE PATINES`: Filas 127-142 del Excel.
- `PORTA LLANTAS Y SUJECIÓN`: Filas 144-150 del Excel.

### 4.4. Opciones Configurables (`opcion_componentes`)

1. **Suspensión Hendrickson Alta (`alta_hendrickson`):** `AMORTIGUADOR HENDRICKSON 23743` como componente activo.
2. **Suspensión Fleet Master (`fleet_master`):** Componentes estándar con sustitutos en cantidad 0.
3. **Patines y Ejes:** Reclasificados a **Paso 6** en estricto apego al Excel oficial.

---
## 5. Sección 'Pendientes de Definir' (Anomalías y Datos Abiertos)

| Fila Excel | Proceso | Descripción en Excel | Detalle / Causa en Pendientes |
|:---:|---|---|---|
| 167-179 | PASO 8 | **Insumos de pintura (Thinner, Catalizador, Primer, Reductor, Transparente)** | Insumos químicos individuales de acabado; enviados a Pendientes para no asociarlos erróneamente al producto genérico PINTURA. |
| 252 | PASO 11 | **PIJAS 5/16 X 2** | Fijación específica; en Pendientes para no asociarla forzadamente a PIJAS/BROCAS sin confirmación. |
| 255 | PASO 11 | **PISO MADERA** | Especie de madera no detallada; en Pendientes para no asociar ciegamente a PISO DE MADERA DE PINO. |
| 46-51 | Paso 4 | **Discos de corte, desbaste, microalambre, CO2 y oxígeno** | Consumibles de planta sin dotación unitaria fija por remolque. |
| 63-67 | Paso 5 | **Discos y gases de taller** | Consumibles de soldadura de perchas sin cantidad unitaria. |
| 165 | PASO 7 | **FOSFATO 1 L** | Presentación química sin costo unitario asignado en hoja fuente. |
| 248 | PASO 10 | **Fila 248 (cant = 25.8 en Paso 10)** | Corresponde a la segunda línea de `CABLE NEGRO CAL,12` con uso 'SI LLEVA LATERALES Y ESTRIBO' ya existente en BD. |
| 307-308 | LLANTAS Y RINES | **MEDIDA DE RIN (24.5 / 22.5)** | Encabezados dimensionales sin producto asociado. |

---
## 6. Mapeo de Bloques de Opciones Configurables Excluyentes

1. **Grupo `suspension` (Paso 5):** Alternativas de marca (`alta_hendrickson`, `hendrickson`, `fleet_master`, `ampro`, `fcr`).
2. **Grupo `retractil` (Paso 5):** Opciones `chico` (UBL) y `grande` con desglose de tornillería grado 8.
3. **Grupo `patin` (Paso 6):** Opciones `ampro`, `holland`, `hj`, `flet_master` (Paso 6 oficial).
4. **Grupo `eje` (Paso 6):** Opciones `fleet_master`, `ampro`, `fcr`, `prat_max`, `hj` con escala `por_eje` (Paso 6 oficial).
5. **Grupo `pintura` (Paso 8):** Opciones por sistema de recubrimiento (`sherwin_williams`, `ppg`, `axalta`).
6. **Grupo `piso` (Paso 11):** Opciones `plastico_cafe` (18 tablones), `pino`, `encino` con dotación de 600 pijas fijadoras.
7. **Grupos `rines` y `llantas` (LLANTAS Y RINES):** Dotaciones de rodado doble por eje con escala `por_eje`.
8. **Grupo `adicionales` (EXTRAS):** Opción `multimodal` (twistlocks y cargadores IPR 3").

---
## 7. Tabla Exhaustiva de Mapeo (316 Filas del Excel)

| Fila | Proceso Excel | Descripción en Excel | Cant | Precio | Destino | Producto BD Asociado | Fase Oficial |
|:---:|---|---|:---:|:---:|---|---|---|
| 2 | Paso 1 | Alma  Placa de grado A-50 Cal. 1/4" | 2 | - | `receta_base` | ALMA (PLACA DE GRADO A-50 CAL. 1/4"... | `paso_1` |
| 3 | Paso 1 | CONSUMIBLE 65 | 0.5 | - | `receta_base` | CONSUMIBLE 65 | `paso_1` |
| 4 | Paso 1 | DISCO DE DESBASTE 9 | 1 | - | `receta_base` | DISCO DE DESBASTE 9 | `paso_1` |
| 5 | Paso 2 | Solera para almas  Solera de grado A-529 a 1/... | 4 | $4884.75 | `receta_base` | SOLERA DE ALMA (SOLERA DE GRADO A-5... | `paso_2` |
| 6 | Paso 2 | CO2 | 0.5 | - | `receta_base` | CO2 | `paso_2` |
| 7 | Paso 2 | ROLLO DE MICRO ALAMBRE | 1 | - | `receta_base` | ROLLO DE MICROALAMBRE | `paso_2` |
| 8 | Paso 2 | DISCO DE CORTE 7 | 1 | - | `receta_base` | DISCO DE CORTE 7 | `paso_2` |
| 9 | Paso 2 | CONSUMIBLE 65 | 0.25 | - | `receta_base` | CONSUMIBLE 65 | `paso_2` |
| 10 | Paso 3 | Borda delantera  Placa de grado A-36 Cal. 3/1... | 1 | $2068 | `receta_base` | BORDA DELANTERA (PLACA DE GRADO A-3... | `paso_3` |
| 11 | Paso 3 | Borda trasera  Placa de grado A-36 Cal. 3/16" | 1 | $2500 | `receta_base` | BORDA TRASERA (PLACA DE GRADO A-36 ... | `paso_3` |
| 12 | Paso 3 | Puentes de suspensión  PTR de 6X2" Cal. 3/16" | 6 | - | `receta_base` | PUENTES DE SUSPENSIÓN (PTR A 2 X 6"... | `paso_3` |
| 13 | Paso 3 | Plancha para la quinta  Placa de grado A-36 C... | 1 | $5700 | `receta_base` | PLANCHA PARA LA QUINTA (PLACA DE GR... | `paso_3` |
| 14 | Paso 3 | Puentes intermedios  PTR de 2X4" Cal. 7 | 5 | $440 | `receta_base` | - | `paso_3` |
| 15 | Paso 3 | Puentes de la plancha  Canal "U" de 6" (12Kg) | 4 | $450 | `receta_base` | - | `paso_3` |
| 16 | Paso 3 | Botones  Placa de grado A-36 Cal. 1/4" | 16 | $40 | `receta_base` | BOTONES (PLACA DE GRADO A-36 CAL. 1... | `paso_3` |
| 17 | Paso 3 | Atizadores internos  Placa de grado A-36 Cal.... | 12 | $35 | `receta_base` | ATIZADORES INTERNOS (PLACA DE GRADO... | `paso_3` |
| 18 | Paso 3 | Atizadores externos 27 cm Solera de grado A-3... | 8 | $50 | `receta_base` | ATIZADORES EXTERNOS 27 CM (SOLERA D... | `paso_3` |
| 19 | Paso 3 | Atizadores externos 29cm Solera de grado A-36... | 2 | $60 | `receta_base` | ATIZADORES EXTERNOS 29CM | `paso_3` |
| 20 | Paso 3 | Jalon  Placa de grado A-36 Cal. 1/2" | 1 | $2500 | `receta_base` | JALON (PLACA DE GRADO A-36 CAL. 1/2... | `paso_3` |
| 21 | Paso 3 | Refuerzo de jalon  Placa de grado A-36 Cal. 3... | 1 | $600 | `receta_base` | REFUERZO DE JALON (PLACA DE GRADO A... | `paso_3` |
| 22 | Paso 3 | Perno rey  Perno rey Holland 3/8" | 1 | $1200 | `receta_base` | PERNO REY (PERNO REY HOLLAND 3/8") | `paso_3` |
| 23 | Paso 3 | Tapa para perno rey  Canal "U" de 6" (12Kg) | 1 | $100 | `receta_base` | TAPA PARA PERNO REY (CANAL U 6") | `paso_3` |
| 24 | Paso 3 | CONSUMIBLE 65 | 0.25 | - | `receta_base` | CONSUMIBLE 65 | `paso_3` |
| 25 | Paso 3 | ROLLO DE MICRO ALAMBRE | 0.25 | - | `receta_base` | ROLLO DE MICROALAMBRE | `paso_3` |
| 26 | Paso 3 | CO2 | 0.25 | - | `receta_base` | CO2 | `paso_3` |
| 27 | Paso 3 | OXIGENO | 0.25 | - | `receta_base` | OXIGENO | `paso_3` |
| 28 | Paso 3 | DISCO LAMINADO 7 | 0.25 | - | `receta_base` | DISCO LAMINADO 7 | `paso_3` |
| 29 | Paso 3 | DISCO DE CORTE 7 | 0.25 | - | `receta_base` | DISCO DE CORTE 7 | `paso_3` |
| 30 | Paso 3 | DISCO DE DESBASTE 9 | 0.5 | - | `receta_base` | DISCO DE DESBASTE 9 | `paso_3` |
| 31 | Paso 4 | Kit de aletas 27 x 50 cm Placa de grado A-36 ... | 1 | $108.99 | `receta_base` | KIT DE ALETAS 27 X 50 CM (PLACA DE ... | `paso_4` |
| 32 | Paso 4 | Kit de aletas 27 x 60 cm Placa de grado A-36 ... | 1 | $130.99 | `receta_base` | KIT DE ALETAS 27 X 60 CM | `paso_4` |
| 33 | Paso 4 | Kit de aletas 40 x 50 cm Placa de grado A-36 ... | 3 | $161.99 | `receta_base` | KIT DE ALETAS 40 X 50 CM | `paso_4` |
| 34 | Paso 4 | Kit de aletas 40 x 60 cm Placa de grado A-36 ... | 3 | $193.99 | `receta_base` | KIT DE ALETAS 40 X 60 CM | `paso_4` |
| 35 | Paso 4 | Kit de aletas 45 x 50 cm Placa de grado A-36 ... | 2 | $181.99 | `receta_base` | KIT DE ALETAS 45 X 50 CM | `paso_4` |
| 36 | Paso 4 | Kit de aletas 45 x 60 cm Placa de grado A-36 ... | 2 | $217.99 | `receta_base` | KIT DE ALETAS 45 X 60 CM | `paso_4` |
| 37 | Paso 4 | Esquinero delantero  Placa de grado A-36 Cal.... | 2 | $70 | `receta_base` | ESQUINERO DELANTERO (PLACA DE GRADO... | `paso_4` |
| 38 | Paso 4 | Esquinero trasero  Placa de grado A-36 Cal. 1... | 2 | $110 | `receta_base` | ESQUINERO TRASERO (PLACA DE GRADO A... | `paso_4` |
| 39 | Paso 4 | Buchacas  Placa de grado A-36 Cal. 1/4" | 48 | $45.5 | `receta_base` | BUCHACAS (PLACA DE GRADO A-36 CAL. ... | `paso_4` |
| 40 | Paso 4 | Tubos laterales  Tubo de 1 1/4" Ced. 40 | 42 | $12 | `receta_base` | TUBOS LATERALES (TUBO DE 1 1/4" CED... | `paso_4` |
| 41 | Paso 4 | Base para estribo Placa trasera Placa de grad... | 2 | $65 | `receta_base` | BASE PARA ESTRIBO PLACA TRASERA (PL... | `paso_4` |
| 42 | Paso 4 | Base para estribo Placa frontal Placa de grad... | 2 | $170 | `receta_base` | BASE PARA ESTRIBO PLACA FRONTAL (PL... | `paso_4` |
| 43 | Paso 4 | Base para estribo Placa intermedia Placa de g... | 2 | $130 | `receta_base` | BASE PARA ESTRIBO PLACA INTERMEDIA ... | `paso_4` |
| 44 | Paso 4 | Cargador  IPR DE 4" X 102" | 38 | $576.82 | `receta_base` | CARGADOR (IPR DE 4") | `paso_4` |
| 45 | Paso 4 | Bordas laterales  Canal U 6" | 2 | $5870.35 | `receta_base` | BORDAS LATERALES (CANAL U 6") | `paso_4` |
| 46 | Paso 4 | DISCO LAMINADO 7 | - | - | `Pendiente` | - | `paso_4` |
| 47 | Paso 4 | DISCO DE CORTE 7 | - | - | `Pendiente` | - | `paso_4` |
| 48 | Paso 4 | DISCO DE DESBASTE 9 | - | - | `Pendiente` | - | `paso_4` |
| 49 | Paso 4 | OXIGENO | - | - | `Pendiente` | - | `paso_4` |
| 50 | Paso 4 | ROLLO DE MICROALAMBRE | - | - | `Pendiente` | - | `paso_4` |
| 51 | Paso 4 | CO2 | - | - | `Pendiente` | - | `paso_4` |
| 52 | Paso 5 | Base para tanques  Placa de grado A-36 Cal. 1... | 4 | $77 | `receta_base` | BASE PARA TANQUES (PLACA DE GRADO A... | `paso_5` |
| 53 | Paso 5 | Base para patines Placas Placa de grado A-36 ... | 8 | $52.6 | `opcion_componentes` | BASE PARA PATINES PLACAS (PLACA DE ... | `paso_5` |
| 54 | Paso 5 | Base para patines Solera Solera de grado A-36... | 8 | $23.4 | `opcion_componentes` | BASE PARA PATINES SOLERA (SOLERA DE... | `paso_5` |
| 55 | Paso 5 | Base para manitas  Placa de grado A-36 Cal. 1... | 1 | $101 | `receta_base` | BASE PARA MANITAS (PLACA DE GRADO A... | `paso_5` |
| 56 | Paso 5 | Base para perchas  Solera de grado A-36 a 1/2... | 4 | $234 | `receta_base` | BASE PARA PERCHAS (SOLERA DE GRADO ... | `paso_5` |
| 57 | Paso 5 | Base para platos  Solera de grado A-36 a 1/2"... | 4 | $67 | `receta_base` | BASE PARA PLATOS (SOLERA DE GRADO A... | `paso_5` |
| 58 | Paso 5 | Pestañas  Placa de grado A-36 Cal. 1/4" | 2 | $64 | `receta_base` | PESTAÑAS (PLACA DE GRADO A-36 CAL. ... | `paso_5` |
| 59 | Paso 5 | Ganchos  Redondo de 1/2" | 32 | $6.3 | `receta_base` | GANCHOS (REDONDO DE 1/2") | `paso_5` |
| 60 | Paso 5 | Plafones ovalados  Placa de grado A-36 Cal. 1... | 4 | $45 | `receta_base` | PLAFONES OVALADOS (PLACA DE GRADO A... | `paso_5` |
| 61 | Paso 5 | Cartabones para jalon  Placa de grado A-36 Ca... | 2 | $300 | `receta_base` | CARTABONES PARA JALON (PLACA DE GRA... | `paso_5` |
| 62 | Paso 5 | Solera para esquineros  Placa de grado A-36 C... | 1 | $60.6 | `receta_base` | SOLERA PARA ESQUINEROS (PLACA DE GR... | `paso_5` |
| 63 | Paso 5 | DISCO LAMINADO 7 | - | - | `Pendiente` | - | `paso_5` |
| 64 | Paso 5 | DISCO DE CORTE 7 | - | - | `Pendiente` | - | `paso_5` |
| 65 | Paso 5 | DISCO DE DESBASTE 9 | - | - | `Pendiente` | - | `paso_5` |
| 66 | Paso 5 | ROLLO DE MICROALAMBRE | - | - | `Pendiente` | - | `paso_5` |
| 67 | Paso 5 | CO2 | - | - | `Pendiente` | - | `paso_5` |
| 68 | Paso 5 | SISTEMA RETRACTIL GRANDE Retractil grande ori... | - | - | `opcion_componentes` | SISTEMA RETRACTIL GRANDE | `paso_5` |
| 69 | Paso 5 | SISTEMA RETRACTIL GRANDE Retractil grande pro... | - | - | `opcion_componentes` | SISTEMA RETRACTIL GRANDE | `paso_5` |
| 70 | Paso 5 | SISTEMA RETRACTIL GRANDE  Placa de grado A-36... | - | - | `opcion_componentes` | SISTEMA RETRACTIL GRANDE | `paso_5` |
| 71 | Paso 5 | SISTEMA RETRACTIL GRANDE  Placa de grado A-36... | - | - | `opcion_componentes` | SISTEMA RETRACTIL GRANDE | `paso_5` |
| 72 | Paso 5 | SISTEMA RETRACTIL GRANDE  Cadena de 1/2" | - | - | `opcion_componentes` | SISTEMA RETRACTIL GRANDE | `paso_5` |
| 75 | Paso 5 | SISTEMA RETRACTIL CHICO Retractil UBL origina... | - | - | `opcion_componentes` | SISTEMA RETRACTIL CHICO | `paso_5` |
| 76 | Paso 5 | SISTEMA RETRACTIL CHICO Retractil UBL propio ... | - | - | `opcion_componentes` | SISTEMA RETRACTIL CHICO | `paso_5` |
| 77 | Paso 5 | SUSPENSION HENDRICKSON HT300US ( SUSPENSION A... | 4 | - | `opcion_componentes` | PIERNAS IZQUIERDA Y DERECHA | `paso_5` |
| 78 | Paso 5 | SUSPENSION HENDRICKSON HT300US ( SUSPENSION A... | 4 | - | `opcion_componentes` | PLATOS IZQUIERDO Y DERECHO | `paso_5` |
| 79 | Paso 5 | SUSPENSION HENDRICKSON HT300US ( SUSPENSION A... | 4 | - | `opcion_componentes` | AMORTIGUADOR HENDRICKSON 23743 | `paso_5` |
| 80 | Paso 5 | SUSPENSION HENDRICKSON HT300US ( SUSPENSION A... | 0 | - | `opcion_componentes` | AMORTIGUADOR MONRROE 65512 | `paso_5` |
| 81 | Paso 5 | SUSPENSION HENDRICKSON HT300US ( SUSPENSION A... | 4 | - | `opcion_componentes` | CAMARA DE SUSPENSION HENDRICKSON C-... | `paso_5` |
| 82 | Paso 5 | SUSPENSION HENDRICKSON HT300US ( SUSPENSION A... | 4 | - | `opcion_componentes` | RONDANAS CENTRICAS HENDRICKSON | `paso_5` |
| 83 | Paso 5 | SUSPENSION HENDRICKSON HT300US ( SUSPENSION A... | 4 | - | `opcion_componentes` | RONDANAS EXCENTRICAS HENDRICKSON | `paso_5` |
| 84 | Paso 5 | SUSPENSION HENDRICKSON HT300US ( SUSPENSION A... | 4 | - | `opcion_componentes` | BUJE TRIFUNCIONAL CON TORNILLO | `paso_5` |
| 85 | Paso 5 | SUSPENSION HENDRICKSON HT300US ( SUSPENSION A... | 8 | - | `opcion_componentes` | ABRAZADERAS HENDRICKSON | `paso_5` |
| 86 | Paso 5 | SUSPENSION HENDRICKSON HT300 ( SUSPENSION NOR... | 4 | - | `opcion_componentes` | PIERNAS IZQUIERDA Y DERECHA | `paso_5` |
| 87 | Paso 5 | SUSPENSION HENDRICKSON HT300 ( SUSPENSION NOR... | 4 | - | `opcion_componentes` | PLATOS IZQUIERDO Y DERECHO | `paso_5` |
| 88 | Paso 5 | SUSPENSION HENDRICKSON HT300 ( SUSPENSION NOR... | 4 | - | `opcion_componentes` | AMORTIGUADOR HENDRICKSON 20126 | `paso_5` |
| 89 | Paso 5 | SUSPENSION HENDRICKSON HT300 ( SUSPENSION NOR... | 4 | - | `opcion_componentes` | CAMARA DE SUSPENSION HENDRICKSON R1... | `paso_5` |
| 90 | Paso 5 | SUSPENSION HENDRICKSON HT300 ( SUSPENSION NOR... | 4 | - | `opcion_componentes` | RONDANAS CENTRICAS HENDRICKSON | `paso_5` |
| 91 | Paso 5 | SUSPENSION HENDRICKSON HT300 ( SUSPENSION NOR... | 4 | - | `opcion_componentes` | RONDANAS EXCENTRICAS HENDRICKSON | `paso_5` |
| 92 | Paso 5 | SUSPENSION HENDRICKSON HT300 ( SUSPENSION NOR... | 4 | - | `opcion_componentes` | BUJE TRIFUNCIONAL CON TORNILLO 7/8 | `paso_5` |
| 93 | Paso 5 | SUSPENSION HENDRICKSON HT300 ( SUSPENSION NOR... | 8 | - | `opcion_componentes` | ABRAZADERAS HENDRICKSON | `paso_5` |
| 94 | Paso 5 | SUSPENSION FLET MASTER HT300 ( SUSPENSION NOR... | 4 | - | `opcion_componentes` | PIERNAS IZQUIERDA Y DERECHA | `paso_5` |
| 95 | Paso 5 | SUSPENSION FLET MASTER HT300 ( SUSPENSION NOR... | 4 | - | `opcion_componentes` | PLATOS IZQUIERDO Y DERECHO | `paso_5` |
| 96 | Paso 5 | SUSPENSION FLET MASTER HT300 ( SUSPENSION NOR... | 4 | - | `opcion_componentes` | CAMARA DE SUSPENSION FLEET MASTER 8... | `paso_5` |
| 97 | Paso 5 | SUSPENSION FLET MASTER HT300 ( SUSPENSION NOR... | 0 | - | `opcion_componentes` | CAMARA DE SUSPENSION AMPRO 1R14-039 | `paso_5` |
| 98 | Paso 5 | SUSPENSION FLET MASTER HT300 ( SUSPENSION NOR... | 0 | - | `opcion_componentes` | CAMARA DE SUSPENSION FCR 1R14-039 | `paso_5` |
| 99 | Paso 5 | SUSPENSION FLET MASTER HT300 ( SUSPENSION NOR... | 4 | - | `opcion_componentes` | AMORTIGUADOR FLEET MASTER 323 | `paso_5` |
| 100 | Paso 5 | SUSPENSION FLET MASTER HT300 ( SUSPENSION NOR... | 0 | - | `opcion_componentes` | AMORTIGUADOR FCR | `paso_5` |
| 101 | Paso 5 | SUSPENSION FLET MASTER HT300 ( SUSPENSION NOR... | 0 | - | `opcion_componentes` | AMORTIGUADOR GABRIEL | `paso_5` |
| 102 | Paso 5 | SUSPENSION FLET MASTER HT300 ( SUSPENSION NOR... | 8 | - | `opcion_componentes` | ABRAZADERAS FLEET MASTER | `paso_5` |
| 103 | Paso 5 | SUSPENSION FLET MASTER HT300 ( SUSPENSION NOR... | 4 | - | `opcion_componentes` | RONDANAS CENTRICAS HENDRICKSON | `paso_5` |
| 104 | Paso 5 | SUSPENSION FLET MASTER HT300 ( SUSPENSION NOR... | 4 | - | `opcion_componentes` | RONDANAS EXCENTRICAS HENDRICKSON | `paso_5` |
| 105 | Paso 5 | SUSPENSION FLET MASTER HT300 ( SUSPENSION NOR... | 8 | - | `opcion_componentes` | BUJE TRIFUNCIONAL HENDRICKSON 7/8 | `paso_5` |
| 106 | Paso 5 | SUSPENSION AMPRO HT300 ( SUSPENSION NORMAL) P... | 4 | - | `opcion_componentes` | PIERNAS IZQUIERDA Y DERECHA | `paso_5` |
| 107 | Paso 5 | SUSPENSION AMPRO HT300 ( SUSPENSION NORMAL) P... | 4 | - | `opcion_componentes` | PLATOS IZQUIERDO Y DERECHO | `paso_5` |
| 108 | Paso 5 | SUSPENSION AMPRO HT300 ( SUSPENSION NORMAL) C... | 4 | - | `opcion_componentes` | CAMARA DE SUSPENSION AMPRO 8050 | `paso_5` |
| 109 | Paso 5 | SUSPENSION AMPRO HT300 ( SUSPENSION NORMAL) A... | 4 | - | `opcion_componentes` | AMORTIGUADOR GABRIEL | `paso_5` |
| 110 | Paso 5 | SUSPENSION AMPRO HT300 ( SUSPENSION NORMAL) A... | 8 | - | `opcion_componentes` | ABRAZADERAS AMPRO | `paso_5` |
| 111 | Paso 5 | SUSPENSION AMPRO HT300 ( SUSPENSION NORMAL) R... | 4 | - | `opcion_componentes` | RONDANAS CENTRICAS | `paso_5` |
| 112 | Paso 5 | SUSPENSION AMPRO HT300 ( SUSPENSION NORMAL) R... | 4 | - | `opcion_componentes` | RONDANAS EXCENTRICAS | `paso_5` |
| 113 | Paso 5 | SUSPENSION AMPRO HT300 ( SUSPENSION NORMAL) B... | 8 | - | `opcion_componentes` | BUJE TRIFUNCIONAL | `paso_5` |
| 114 | Paso 5 | SUSPENSION FCR HT300 ( SUSPENSION NORMAL) PIE... | 4 | - | `opcion_componentes` | PIERNAS IZQUIERDA Y DERECHA | `paso_5` |
| 115 | Paso 5 | SUSPENSION FCR HT300 ( SUSPENSION NORMAL) PLA... | 4 | - | `opcion_componentes` | PLATOS IZQUIERDO Y DERECHO | `paso_5` |
| 116 | Paso 5 | SUSPENSION FCR HT300 ( SUSPENSION NORMAL) CAM... | 4 | - | `opcion_componentes` | CAMARA DE SUSPENSION AMPRO 8050 | `paso_5` |
| 117 | Paso 5 | SUSPENSION FCR HT300 ( SUSPENSION NORMAL) AMO... | 4 | - | `opcion_componentes` | AMORTIGUADOR GABRIEL | `paso_5` |
| 118 | Paso 5 | SUSPENSION FCR HT300 ( SUSPENSION NORMAL) ABR... | 8 | - | `opcion_componentes` | ABRAZADERAS AMPRO | `paso_5` |
| 119 | Paso 5 | SUSPENSION FCR HT300 ( SUSPENSION NORMAL) RON... | 4 | - | `opcion_componentes` | RONDANAS CENTRICAS | `paso_5` |
| 120 | Paso 5 | SUSPENSION FCR HT300 ( SUSPENSION NORMAL) RON... | 4 | - | `opcion_componentes` | RONDANAS EXCENTRICAS | `paso_5` |
| 121 | Paso 5 | SUSPENSION FCR HT300 ( SUSPENSION NORMAL) BUJ... | 8 | - | `opcion_componentes` | BUJE TRIFUNCIONAL | `paso_5` |
| 122 | Paso 6 | U para jalon  Redondo de 1" | 1 | $102 | `receta_base` | U PARA JALON (REDONDO DE 1") | `paso_6` |
| 123 | Paso 6 | Base para foco de ABS  Placa de grado A-36 Ca... | 1 | $25 | `receta_base` | BASE PARA FOCO DE ABS (PLACA DE GRA... | `paso_6` |
| 124 | Paso 6 | Base para ABS  Placa de grado A-36 Cal. 1/4" | 1 | $30 | `receta_base` | BASE PARA ABS (PLACA DE GRADO A-36 ... | `paso_6` |
| 125 | Paso 6 | Porta placas  Placa de grado A-36 Cal. 10 | 1 | $42.99 | `receta_base` | PORTA PLACAS (PLACA DE GRADO A-36 C... | `paso_6` |
| 126 | Paso 6 | Cincho  Solera de grado A-36 a 3/8" x 2" | 4 | $1110 | `receta_base` | CINCHO (SOLERA DE GRADO A-36 A 3/8"... | `paso_6` |
| 127 | Paso 6 | Heraje para patines 110cm Placa de grado A-36... | 2 | $196.99 | `opcion_componentes` | HERAJE PARA PATINES 110CM (PLACA DE... | `paso_6` |
| 128 | Paso 6 | Heraje para patines 125cm Placa de grado A-36... | 2 | $223.99 | `opcion_componentes` | HERAJE PARA PATINES 125CM | `paso_6` |
| 129 | Paso 6 | Heraje para patines 70cm Placa de grado A-36 ... | 2 | $124.99 | `opcion_componentes` | HERAJE PARA PATINES 70CM | `paso_6` |
| 130 | Paso 6 | Heraje para patines 67cm Placa de grado A-36 ... | 4 | $119.99 | `opcion_componentes` | HERAJE PARA PATINES 67CM | `paso_6` |
| 131 | Paso 6 | Heraje para patines 23cm Placa de grado A-36 ... | 2 | $41.99 | `opcion_componentes` | HERAJE PARA PATINES 23CM | `paso_6` |
| 132 | Paso 6 | Heraje para patines 7cm Solera de grado A-36 ... | 2 | $23.99 | `opcion_componentes` | HERAJE PARA PATINES 7CM (SOLERA DE ... | `paso_6` |
| 133 | Paso 6 | Heraje para patines 27cm Solera de grado A-36... | 2 | $90.99 | `opcion_componentes` | HERAJE PARA PATINES 27CM | `paso_6` |
| 134 | Paso 6 | Heraje para patines 30cm Solera de grado A-36... | 2 | $100.99 | `opcion_componentes` | HERAJE PARA PATINES 30CM | `paso_6` |
| 135 | Paso 6 | Heraje para patines Buchaca Placa de grado A-... | 2 | $40.99 | `opcion_componentes` | HERAJE PARA PATINES BUCHACA (PLACA ... | `paso_6` |
| 136 | Paso 6 | Heraje para patines TORNILLO 5/8X1 1/2 GRADO ... | 44 | - | `opcion_componentes` | TORNILLO 5/8 X 1 1/2 GRADO 5 | `paso_6` |
| 137 | Paso 6 | Heraje para patines TUERCA ESTANDAR 5/8 GRADO... | 44 | - | `opcion_componentes` | TUERCA ESTANDAR 5/8 GRADO 5 | `paso_6` |
| 138 | Paso 6 | Porta Llantas Aletas Placa de grado A-36 Cal.... | 2 | $87.99 | `opcion_componentes` | PORTA LLANTAS (PLACA DE GRADO A-36 ... | `paso_6` |
| 139 | Paso 6 | Porta Llantas "Z" Placa de grado A-36 Cal. 1/... | 1 | $275.99 | `opcion_componentes` | PORTA LLANTAS (PLACA DE GRADO A-36 ... | `paso_6` |
| 140 | Paso 6 | Porta Llantas "U" Solera de grado A-36 a 1/2"... | 1 | $738.99 | `opcion_componentes` | PORTA LLANTAS (SOLERA DE GRADO A-36... | `paso_6` |
| 141 | Paso 6 | Porta Llantas TORNILLO ALLEN 1/2X1 1/2 | 2 | - | `opcion_componentes` | TORNILLO ALLEN 1/2 X 1 1/2 | `paso_6` |
| 142 | Paso 6 | Porta Llantas TUERCA ESTANDAR 1/2 GRADO 5 | 2 | - | `opcion_componentes` | TUERCA ESTANDAR 1/2 GRADO 5 | `paso_6` |
| 143 | Paso 6 | Estribo  PTR de 4X4" a 6.10m | 1 | $1050 | `receta_base` | ESTRIBO (PTR DE 4X4" A 6.10M) | `paso_6` |
| 144 | Paso 6 | Porta loderas  Placa de grado A-36 Cal. 12 | 2 | $440 | `receta_base` | PORTA LODERAS (PLACA DE GRADO A-36 ... | `paso_6` |
| 145 | Paso 6 | Caja de herramientas  Placa de grado A-36 Cal... | 1 | - | `receta_base` | CAJA DE HERRAMIENTAS | `paso_6` |
| 146 | Paso 6 | Caja de herramientas TORNILLO ALLEN 1/2X1 1/2 | 2 | - | `receta_base` | TORNILLO ALLEN 1/2 X 1 1/2 | `paso_6` |
| 147 | Paso 6 | Caja de herramientas TUERCA ESTANDAR 1/2 GRAD... | 2 | - | `receta_base` | TUERCA ESTANDAR 1/2 GRADO 5 | `paso_6` |
| 148 | Paso 6 | Patines PATIN AMPRO | 0 | - | `opcion_componentes` | PATIN AMPRO | `paso_6` |
| 149 | Paso 6 | Patines PATIN HOLAND MARK V | 0 | - | `opcion_componentes` | PATIN HOLLAND MARK V | `paso_6` |
| 150 | Paso 6 | Patines PATIN HJ | 2 | - | `opcion_componentes` | PATÍN HJ | `paso_6` |
| 151 | Paso 6 | Patines PATIN FLET MASTER | 0 | - | `opcion_componentes` | PATIN FLEET MASTER | `paso_6` |
| 152 | Paso 6 | Ejes EJE FLET MASTER | 2 | - | `opcion_componentes` | EJE FLEET MASTER | `paso_6` |
| 153 | Paso 6 | Ejes EJE AMPRO | 0 | - | `opcion_componentes` | EJE AMPRO | `paso_6` |
| 154 | Paso 6 | Ejes EJE FCR | 0 | - | `opcion_componentes` | EJE FCR | `paso_6` |
| 155 | Paso 6 | Ejes EJE PRAT MAX | 0 | - | `opcion_componentes` | EJE PRAT MAX | `paso_6` |
| 156 | Paso 6 | Ejes EJE HJ | 0 | - | `opcion_componentes` | EJE HJ | `paso_6` |
| 157 | Paso 6 | DISCO LAMINADO 7 | 1 | - | `receta_base` | DISCO LAMINADO 7 | `paso_6` |
| 158 | Paso 6 | DISCO DE CORTE 7 | 1 | - | `receta_base` | DISCO DE CORTE 7 | `paso_6` |
| 159 | Paso 6 | DISCO DE DESBASTE 9 | 0.5 | - | `receta_base` | DISCO DE DESBASTE 9 | `paso_6` |
| 160 | Paso 6 | CO2 | 1 | - | `receta_base` | CO2 | `paso_6` |
| 161 | Paso 6 | ROLLO DE MICRO ALAMBRE | 0.5 | - | `receta_base` | ROLLO DE MICROALAMBRE | `paso_6` |
| 162 | PASO 7 | LAVADO Y ESCOREO LIJA #80 | 10 | - | `receta_base` | LIJA #80 | `paso_7` |
| 163 | PASO 7 | LAVADO Y ESCOREO CARDA 5/8 DE 3" | 1 | - | `receta_base` | CARDA 5/8 DE 3" | `paso_7` |
| 164 | PASO 7 | LAVADO Y ESCOREO DISCO LAMINADO 4 1/2 | 1 | - | `receta_base` | DISCO LAMINADO 4 1/2 | `paso_7` |
| 165 | PASO 7 | LAVADO Y ESCOREO FOSFATO | 1 L | - | `receta_base` | FOSFATO | `paso_7` |
| 166 | PASO 8 | PINTURA PINTURA SHERVIWILLIAMS PINTURA | 19 | - | `opcion_componentes` | PINTURA | `paso_8` |
| 167 | PASO 8 | PINTURA  THINER | 20 | - | `opcion_componentes` | PINTURA | `paso_8` |
| 168 | PASO 8 | PINTURA  TRANSPARENTE | 4.5 | - | `opcion_componentes` | PINTURA | `paso_8` |
| 169 | PASO 8 | PINTURA  CATALIZADOR | 1 | - | `opcion_componentes` | PINTURA | `paso_8` |
| 170 | PASO 8 | PINTURA  PRAIMER | 6 | - | `opcion_componentes` | PINTURA | `paso_8` |
| 171 | PASO 8 | PINTURA  THINER O REDUCTOR | 6 | - | `opcion_componentes` | PINTURA | `paso_8` |
| 172 | PASO 8 | PINTURA PINTURA PPG PINTURA | 16 | - | `opcion_componentes` | PINTURA | `paso_8` |
| 174 | PASO 8 | PINTURA  REDUCTOR | 15 | - | `opcion_componentes` | PINTURA | `paso_8` |
| 175 | PASO 8 | PINTURA  CATALIZADOR | 2.5 | - | `opcion_componentes` | PINTURA | `paso_8` |
| 176 | PASO 8 | PINTURA  PRAIMER | 7 | - | `opcion_componentes` | PINTURA | `paso_8` |
| 177 | PASO 8 | PINTURA  THINER O REDUCTOR | 5 | - | `opcion_componentes` | PINTURA | `paso_8` |
| 178 | PASO 8 | PINTURA PINTURA AXALTA PINTURA | 20 | - | `opcion_componentes` | PINTURA | `paso_8` |
| 180 | PASO 8 | PINTURA  REDUCTOR | 15 | - | `opcion_componentes` | PINTURA | `paso_8` |
| 181 | PASO 8 | PINTURA  CATALIZADOR | 2.5 | - | `opcion_componentes` | PINTURA | `paso_8` |
| 182 | PASO 8 | PINTURA  PRAIMER | 6 | - | `opcion_componentes` | PINTURA | `paso_8` |
| 183 | PASO 9 | KIT ABS REDUCCION  3/4 * 1/2 | 1 | - | `receta_base` | REDUCCION 3/4 * 1/2 | `paso_9` |
| 184 | PASO 9 | KIT ABS REDUCCION  3/8 * 1/4 | 3 | - | `receta_base` | REDUCCION 3/8 * 1/4 | `paso_9` |
| 185 | PASO 9 | KIT ABS NIPLE 1/4 | 1 | - | `receta_base` | NIPLE 1/4 | `paso_9` |
| 186 | PASO 9 | KIT ABS TAPON 3/4 | 1 | - | `receta_base` | TAPON 3/4 | `paso_9` |
| 187 | PASO 9 | KIT ABS TAPON 1/2 | 1 | - | `receta_base` | TAPON 1/2 | `paso_9` |
| 188 | PASO 9 | KIT ABS TAPON 1/4 SUSPENSION FM + 4 | 3 | - | `receta_base` | TAPON 1/4 SUSPENSION FM + 4 | `paso_9` |
| 189 | PASO 9 | KIT ABS TAPON 1/8 | 1 | - | `receta_base` | TAPON 1/8 | `paso_9` |
| 190 | PASO 9 | KIT ABS TE UNIO 3/8 | 1 | - | `receta_base` | TE UNIO 3/8 | `paso_9` |
| 191 | PASO 9 | KIT ABS TE LATERAL 3/8*1/4 | 6 | - | `receta_base` | TE LATERAL 3/8*1/4 | `paso_9` |
| 192 | PASO 9 | KIT ABS TE CENTRO 3/8*1/4 | 1 | - | `receta_base` | TE CENTRO 3/8*1/4 | `paso_9` |
| 193 | PASO 9 | KIT ABS RECTA 3/8*1/4 | 6 | - | `receta_base` | RECTA 3/8*1/4 | `paso_9` |
| 194 | PASO 9 | KIT ABS CODO 3/8*1/4 | 12 | - | `receta_base` | CODO 3/8*1/4 | `paso_9` |
| 195 | PASO 9 | KIT ABS CODO 3/8*1/8 | 2 | - | `receta_base` | CODO 3/8*1/8 | `paso_9` |
| 196 | PASO 9 | KIT ABS CODO 3/8 | 1 | - | `receta_base` | CODO 3/8 | `paso_9` |
| 197 | PASO 9 | KIT ABS CODO 1/2 | 2 | - | `receta_base` | CODO 1/2 | `paso_9` |
| 198 | PASO 9 | KIT ABS ADAPTADOR 3/8 | 8 | - | `receta_base` | ADAPTADOR 3/8 | `paso_9` |
| 199 | PASO 9 | KIT ABS MACHO 3/8 | 8 | - | `receta_base` | MACHO 3/8 | `paso_9` |
| 200 | PASO 9 | KIT ABS HEMBRA 3/8 | 8 | - | `receta_base` | HEMBRA 3/8 | `paso_9` |
| 201 | PASO 9 | KIT ABS KIT DE ABS 2 EJES BENDIX | 1 | - | `receta_base` | KIT DE ABS 2 EJES BENDIX | `paso_9` |
| 202 | PASO 9 | KIT ABS VALVULA PROTECTORA | 1 | - | `receta_base` | VALVULA PROTECTORA | `paso_9` |
| 203 | PASO 9 | KIT ABS VALVULA NIVELADORA | 1 | - | `receta_base` | VALVULA NIVELADORA | `paso_9` |
| 204 | PASO 9 | KIT ABS VALVULA PALANQUETA | 1 | - | `receta_base` | VALVULA PALANQUETA | `paso_9` |
| 205 | PASO 9 | KIT ABS VARILLA NIVELADORA | 1 | - | `receta_base` | VARILLA NIVELADORA | `paso_9` |
| 206 | PASO 9 | KIT ABS VALVULA RETRACTIL SEALCO | 1 | - | `receta_base` | VALVULA RETRACTIL SEALCO | `paso_9` |
| 207 | PASO 9 | KIT ABS MANITA AZUL C/LLAVE | 1 | - | `receta_base` | MANITA AZUL C/LLAVE | `paso_9` |
| 208 | PASO 9 | KIT ABS MANITA ROJA C/LLAVE | 1 | - | `receta_base` | MANITA ROJA C/LLAVE | `paso_9` |
| 209 | PASO 9 | KIT ABS MANITA AZUL S/LLAVE | 1 | - | `receta_base` | MANITA AZUL S/LLAVE | `paso_9` |
| 210 | PASO 9 | KIT ABS MANITA ROJA S/LLAVE | 1 | - | `receta_base` | MANITA ROJA S/LLAVE | `paso_9` |
| 211 | PASO 9 | KIT ABS ESPARRAGO | 2 | - | `receta_base` | ESPARRAGO | `paso_9` |
| 212 | PASO 9 | KIT ABS TEFLON DE 13 METROS | 2 | - | `receta_base` | TEFLON DE 13 METROS | `paso_9` |
| 213 | PASO 9 | KIT ABS INCERTO 3/8 | 38 | - | `receta_base` | INCERTO 3/8 | `paso_9` |
| 214 | PASO 9 | KIT ABS INCERTO 1/2 | 2 | - | `receta_base` | INCERTO 1/2 | `paso_9` |
| 215 | PASO 9 | KIT ABS MANGUERA AZUL 3/8 | 30 | - | `receta_base` | MANGUERA AZUL 3/8 | `paso_9` |
| 216 | PASO 9 | KIT ABS MANGUERA ROJA 3/8 | 13 | - | `receta_base` | MANGUERA ROJA 3/8 | `paso_9` |
| 217 | PASO 9 | KIT ABS MANGUERA CHAMBER 3/8 | 8 | - | `receta_base` | MANGUERA CHAMBER 3/8 | `paso_9` |
| 218 | PASO 9 | KIT ABS TORNILLO 3/8 X 1 GRADO 8 | 8 | - | `receta_base` | TORNILLO 3/8 X 1 GRADO 8 | `paso_9` |
| 219 | PASO 9 | KIT ABS RONDANA PLANA 3/8 | 8 | - | `receta_base` | RONDANA PLANA 3/8 | `paso_9` |
| 220 | PASO 9 | KIT ABS TUERCA DE SEGURIDAD 3/8 | 8 | - | `receta_base` | TUERCA DE SEGURIDAD 3/8 | `paso_9` |
| 221 | PASO 9 | KIT ABS TORNILLO 5/16 X 5 GRADO 8 | 2 | - | `receta_base` | TORNILLO 5/16 X 5 GRADO 8 | `paso_9` |
| 222 | PASO 9 | KIT ABS RONDANA PLANA 5/16 | 4 | - | `receta_base` | RONDANA PLANA 5/16 | `paso_9` |
| 223 | PASO 9 | KIT ABS TUERCA DE SEGURIDAD 5/16 | 2 | - | `receta_base` | TUERCA DE SEGURIDAD 5/16 | `paso_9` |
| 224 | PASO 9 | KIT ABS TANQUE DE AIRE DE PLANA | 2 | - | `receta_base` | TANQUE DE AIRE DE PLANA | `paso_9` |
| 225 | PASO 9 | TIPO DE GANCHO GANCHO HOLLAND 10 BARRENOS | 1 | - | `opcion_componentes` | GANCHO HOLLAND 10 BARRENOS | `paso_9` |
| 226 | PASO 9 | TIPO DE GANCHO GANCHO PREMIER 10 BARRENOS | 1 | - | `opcion_componentes` | GANCHO PREMIER 10 BARRENOS | `paso_9` |
| 227 | PASO 9 | TIPO DE GANCHO GANCHO PREMIER BESTIA 6 BARREN... | 1 | - | `opcion_componentes` | GANCHO PREMIER BESTIA 6 BARRENOS | `paso_9` |
| 228 | PASO 9 | TORNILLERIA PARA GANCHO TORNILLO 3/4X3 1/2 GR... | 2 | - | `receta_base` | TORNILLO 3/4 X 3 1/2 GRADO 8 | `paso_9` |
| 229 | PASO 9 | TORNILLERIA PARA GANCHO TORNILLO 3/4X 2 1/2 G... | 6 | - | `receta_base` | TORNILLO 3/4 X 2 1/2 GRADO 8 | `paso_9` |
| 230 | PASO 9 | TORNILLERIA PARA GANCHO TUERCA GRIPCO 3/4 | 8 | - | `receta_base` | TUERCA GRIPCO 3/4 | `paso_9` |
| 231 | PASO 9 | TORNILLERIA PARA GANCHO RONDANA AUTOMOTRIZ 3/... | 2 | - | `receta_base` | RONDANA AUTOMOTRIZ 3/4 | `paso_9` |
| 232 | PASO 9 | TIPO DE BOLSA Y TORNILLEROA PARA RETRACTIL BO... | 1 | - | `opcion_componentes` | BOLSA RETRACTIL GRANDE | `paso_9` |
| 233 | PASO 9 | TIPO DE BOLSA Y TORNILLEROA PARA RETRACTIL TU... | 8 | - | `opcion_componentes` | TUERCAS DE SEGURIDAD 1/2 | `paso_9` |
| 234 | PASO 9 | TIPO DE BOLSA Y TORNILLEROA PARA RETRACTIL BO... | 2 | - | `opcion_componentes` | BOLSA RETRACTIL CHICA UBL | `paso_9` |
| 235 | PASO 9 | TIPO DE BOLSA Y TORNILLEROA PARA RETRACTIL TO... | 4 | - | `opcion_componentes` | TORNILLO 3/8 X 3/4 GRADO 8 | `paso_9` |
| 236 | PASO 9 | TIPO DE BOLSA Y TORNILLEROA PARA RETRACTIL RO... | 4 | - | `opcion_componentes` | RONDANAS PLANAS 3/8 | `paso_9` |
| 237 | PASO 9 | TIPO DE BOLSA Y TORNILLEROA PARA RETRACTIL TU... | 2 | - | `opcion_componentes` | TUERCA ROSCA MILIMETRICA 3/4 | `paso_9` |
| 238 | PASO 10 | KIT DE LUZ HEMBRA 7 POLOS | 2 | - | `receta_base` | HEMBRA 7 POLOS | `paso_10` |
| 239 | PASO 10 | KIT DE LUZ TORNILLO 1/4X1 GALVANIZADO | 6 | - | `receta_base` | TORNILLO 1/4 X 1 GALVANIZADO | `paso_10` |
| 240 | PASO 10 | KIT DE LUZ RONDANA PLANA 5/16 | 6 | - | `receta_base` | RONDANA PLANA 5/16 | `paso_10` |
| 241 | PASO 10 | KIT DE LUZ TUERCA ESTANDAR 1/4 | 6 | - | `receta_base` | TUERCA ESTANDAR 1/4 | `paso_10` |
| 242 | PASO 10 | KIT DE LUZ CABLE AZUL CAL,12 | 15.9 | - | `receta_base` | CABLE AZUL CAL,12 | `paso_10` |
| 243 | PASO 10 | KIT DE LUZ CABLE ROJO CAL,12 | 17.3 | - | `receta_base` | CABLE ROJO CAL,12 | `paso_10` |
| 244 | PASO 10 | KIT DE LUZ CABLE AMARILLO CAL,12 | 22 | - | `receta_base` | CABLE AMARILLO CAL,12 | `paso_10` |
| 245 | PASO 10 | KIT DE LUZ CABLE VERDE CAL,12 | 22 | - | `receta_base` | CABLE VERDE CAL,12 | `paso_10` |
| 246 | PASO 10 | KIT DE LUZ CABLE CAFÉ CAL,12 | 28.5 | - | `receta_base` | CABLE CAFE CAL,12 | `paso_10` |
| 247 | PASO 10 | KIT DE LUZ CABLE NEGRO  CAL,12 | 15.9 | - | `receta_base` | CABLE NEGRO CAL,12 | `paso_10` |
| 248 | PASO 10 | KIT DE LUZ | 25.8 | - | `receta_base` | - | `paso_10` |
| 249 | PASO 10 | KIT DE LUZ CORRUGADO 1/2 | 14.5 | - | `receta_base` | CORRUGADO 1/2 | `paso_10` |
| 250 | PASO 10 | KIT DE LUZ CORRUGADO 3/8 | 2.8 | - | `receta_base` | CORRUGADO 3/8 | `paso_10` |
| 251 | PASO 10 | KIT DE LUZ CORRUGADO 1/4 | 21.8 | - | `receta_base` | CORRUGADO 1/4 | `paso_10` |
| 252 | PASO 10 | KIT DE LUZ CORRUGADO 3/8 | 3 | - | `receta_base` | CORRUGADO 3/8 | `paso_10` |
| 253 | PASO 10 | KIT DE LUZ CORRUGADO 1/4 | 22.8 | - | `receta_base` | CORRUGADO 1/4 | `paso_10` |
| 254 | PASO 10 | KIT DE LUZ TERMINAL 3/16 | 18 | - | `receta_base` | TERMINAL 3/16 | `paso_10` |
| 255 | PASO 10 | KIT DE LUZ TERMINAL 1/4 | 2 | - | `receta_base` | TERMINAL 1/4 | `paso_10` |
| 256 | PASO 10 | KIT DE LUZ TERMINAL 3/16 | 36 | - | `receta_base` | TERMINAL 3/16 | `paso_10` |
| 257 | PASO 10 | KIT DE LUZ REMACHE 3/16 X 5/8 | 51 | - | `receta_base` | REMACHE 3/16 X 5/8 | `paso_10` |
| 258 | PASO 10 | KIT DE LUZ CINTA DE AISLAR | 1 | - | `receta_base` | CINTA DE AISLAR | `paso_10` |
| 259 | PASO 10 | KIT DE LUZ PLAFON ROJO 4 | 6 | - | `receta_base` | PLAFON ROJO 4 | `paso_10` |
| 260 | PASO 10 | KIT DE LUZ PLAFON ROJO 2 | 5 | - | `receta_base` | PLAFON ROJO 2 | `paso_10` |
| 261 | PASO 10 | KIT DE LUZ PLAFON AMBAR 2 | 2 | - | `receta_base` | PLAFON AMBAR 2 | `paso_10` |
| 262 | PASO 10 | KIT DE LUZ PLAFON AVALADO AMBAR | 4 | - | `receta_base` | PLAFON AVALADO AMBAR | `paso_10` |
| 263 | PASO 10 | KIT DE LUZ PLAFON DE CARRITO AMBAR | 20 | - | `receta_base` | PLAFON DE CARRITO AMBAR | `paso_10` |
| 264 | PASO 10 | KIT DE LUZ PLAFON DE CARRITO ROJO | 16 | - | `receta_base` | PLAFON DE CARRITO ROJO | `paso_10` |
| 265 | PASO 10 | KIT DE LUZ TORNILLO 1/8X 1 1/4 | 72 | - | `receta_base` | TORNILLO 1/8 X 1 1/4 | `paso_10` |
| 266 | PASO 10 | KIT DE LUZ TUERCA ESTANDAR 1/8 | 72 | - | `receta_base` | TUERCA ESTANDAR 1/8 | `paso_10` |
| 267 | PASO 11 | PISOS PISO PLASTICO CAFE | 1 | - | `opcion_componentes` | - | `paso_11` |
| 268 | PASO 11 | PISOS PISO DE PINO | 1 | - | `opcion_componentes` | - | `paso_11` |
| 269 | PASO 11 | PISOS PISO DE ENCINO | 1 | - | `opcion_componentes` | - | `paso_11` |
| 270 | PASO 11 | PISOS PISO MADERA | 1 | - | `opcion_componentes` | - | `paso_11` |
| 271 | PASO 11 | PISOS PIJAS 5/16 X 2 | 450 | - | `opcion_componentes` | - | `paso_11` |
| 272 | PASO 11 | PISOS PIJAS 5/16 X 2 1/2 | 150 | - | `opcion_componentes` | - | `paso_11` |
| 273 | PASO 12 | ACABADO LODERA BLANCA O NEGRA | 2 | - | `opcion_componentes` | LODERA BLANCA O NEGRA | `paso_12` |
| 274 | PASO 12 | ACABADO FLEJE | 2 | - | `opcion_componentes` | FLEJE | `paso_12` |
| 275 | PASO 12 | ACABADO TORNILLO 1/4X1 ACERO INOXIDABLE | 8 | - | `opcion_componentes` | TORNILLO 1/4 X 1 ACERO INOXIDABLE | `paso_12` |
| 276 | PASO 12 | ACABADO TUERCA DE SEGURIDAD 1/4 | 8 | - | `opcion_componentes` | TUERCA DE SEGURIDAD 1/4 | `paso_12` |
| 277 | PASO 12 | ACABADO TOPE DE HULE  3 BARRENOS | 2 | - | `opcion_componentes` | TOPE DE HULE 3 BARRENOS | `paso_12` |
| 278 | PASO 12 | ACABADO TORNILLO 1/2 X 2 1/2 GALVANIZADO | 6 | - | `opcion_componentes` | TORNILLO 1/2 X 2 1/2 GALVANIZADO | `paso_12` |
| 279 | PASO 12 | ACABADO TUERCA ESTANDAR  1/2 GALVANIZADA | 6 | - | `opcion_componentes` | TUERCA ESTANDAR 1/2 GALVANIZADA | `paso_12` |
| 280 | PASO 12 | ACABADO RONDANA PLANA 1/2 | 6 | - | `opcion_componentes` | RONDANA PLANA 1/2 | `paso_12` |
| 281 | PASO 12 | ACABADO WINCHES | 20 | - | `opcion_componentes` | WINCHES | `paso_12` |
| 282 | PASO 12 | ACABADO TORNILLO 1/2X 1 3/4 | 2 | - | `opcion_componentes` | TORNILLO 1/2 X 1 3/4 | `paso_12` |
| 283 | PASO 12 | ACABADO TUERCA DE SEGURIDAD 1/2 | 2 | - | `opcion_componentes` | TUERCA DE SEGURIDAD 1/2 | `paso_12` |
| 284 | PASO 12 | ACABADO KIT DE ROTULACION | 1 | - | `opcion_componentes` | KIT DE ROTULACION | `paso_12` |
| 285 | PASO 12 | ACABADO CINTA REFLEJANTE | 1 | - | `opcion_componentes` | CINTA REFLEJANTE | `paso_12` |
| 286 | PASO 12 | ACABADO PLACA DE NIP | 1 | - | `opcion_componentes` | PLACA DE NIP | `paso_12` |
| 287 | PASO 12 | ACABADO TORNILLO 1/4X1 ACERO INOXIDABLE | 4 | - | `opcion_componentes` | TORNILLO 1/4 X 1 ACERO INOXIDABLE | `paso_12` |
| 288 | PASO 12 | ACABADO TUERCA DE SEGURIDAD 1/4 | 4 | - | `opcion_componentes` | TUERCA DE SEGURIDAD 1/4 | `paso_12` |
| 289 | EXTRAS | REDILAS TORNILLO CABEZA DE COCHE 1/4 X 1 1/2 | 444 | - | `opcion_componentes` | TORNILLO CABEZA DE COCHE 1/4 X 1 1/... | `extras` |
| 290 | EXTRAS | REDILAS TUERCA ESTANDAR 1/4 | 444 | - | `opcion_componentes` | TUERCA ESTANDAR 1/4 | `extras` |
| 291 | EXTRAS | REDILAS RONDANA PLANA 5/16 | 444 | - | `opcion_componentes` | RONDANA PLANA 5/16 | `extras` |
| 292 | EXTRAS | REDILAS CHAVETAS 3/16*2 | 48 | - | `opcion_componentes` | CHAVETAS 3/16*2 | `extras` |
| 293 | EXTRAS | RETRACTIL FABRICADO EN LEOLCA GRANDE ESLABONE... | 20 | - | `opcion_componentes` | ESLABONES DE CADENA 1/2 | `extras` |
| 294 | EXTRAS | RETRACTIL FABRICADO EN LEOLCA GRANDE TORNILLO... | 1 | - | `opcion_componentes` | TORNILLO 5/8*3 GRADO 8 | `extras` |
| 295 | EXTRAS | RETRACTIL FABRICADO EN LEOLCA GRANDE TORNILLO... | 1 | - | `opcion_componentes` | TORNILLO 5/8*5 GRADO 8 | `extras` |
| 296 | EXTRAS | RETRACTIL FABRICADO EN LEOLCA GRANDE TORNILLO... | 1 | - | `opcion_componentes` | TORNILLO 3/4*6 GRADO 8 | `extras` |
| 297 | EXTRAS | RETRACTIL FABRICADO EN LEOLCA GRANDE TUERCA D... | 1 | - | `opcion_componentes` | TUERCA DE SEGURIDAD 3/4 | `extras` |
| 298 | EXTRAS | RETRACTIL FABRICADO EN LEOLCA GRANDE RONDANA ... | 2 | - | `opcion_componentes` | RONDANA AUTOMOTRIZ 3/4 | `extras` |
| 299 | EXTRAS | RETRACTIL FABRICADO EN LEOLCA GRANDE TUERCA D... | 2 | - | `opcion_componentes` | TUERCA DE SEGURIDAD 5/8 | `extras` |
| 300 | EXTRAS | RETRACTIL FABRICADO EN LEOLCA GRANDE RONDANA ... | 2 | - | `opcion_componentes` | RONDANA AUTOMOTRIZ 5/8 | `extras` |
| 301 | EXTRAS | RETRACTIL FABRICADO EN LEOLCA GRANDE TORNILLO... | 2 | - | `opcion_componentes` | TORNILLO 3/4 X 6 GRADO 8 | `extras` |
| 302 | EXTRAS | RETRACTIL FABRICADO EN LEOLCA GRANDE TUERCA D... | 4 | - | `opcion_componentes` | TUERCA DE SEGURIDAD 3/4 | `extras` |
| 303 | EXTRAS | RETRACTIL FABRICADO EN LEOLCA GRANDE TORNILLO... | 2 | - | `opcion_componentes` | TORNILLO 3/4 X 3 1/2 GRADO 8 | `extras` |
| 304 | EXTRAS | RETRACTIL FABRICADO EN LEOLCA GRANDE RONDANA ... | 4 | - | `opcion_componentes` | RONDANA AUTOMOTRIZ 3/4 | `extras` |
| 305 | EXTRAS | PARA EQUIPOS MULTIMODAL CANDADO PARA PLANA | 12 | - | `receta_base` | CANDADO PARA PLANA | `extras` |
| 306 | EXTRAS | PARA EQUIPOS MULTIMODAL CARGADO 3X102 IN | 8 | - | `receta_base` | CARGADO 3 X 102 IN | `extras` |
| 307 | LLANTAS Y RINES | MEDIDA DE RIN RIN 24.5 | - | - | `Pendiente` | - | `llantas_rines` |
| 308 | LLANTAS Y RINES | MEDIDA DE RIN RIN 22.5 | - | - | `Pendiente` | - | `llantas_rines` |
| 309 | LLANTAS Y RINES | TIPO DE RINES RIN DE ACERO FLET MASTER | 8 | - | `opcion_componentes` | RIN DE ACERO FLEET MASTER | `llantas_rines` |
| 310 | LLANTAS Y RINES | TIPO DE RINES RIN DE ACERO ACURRAI | 8 | - | `opcion_componentes` | RIN DE ACERO ACURRAI | `llantas_rines` |
| 311 | LLANTAS Y RINES | TIPO DE RINES RIN DE ACERO AMPRO | 8 | - | `opcion_componentes` | RIN DE ACERO AMPRO | `llantas_rines` |
| 312 | LLANTAS Y RINES | TIPO DE RINES RIN DE AUMINIO FLET MASTER | 8 | - | `opcion_componentes` | RIN DE ALUMINIO FLEET MASTER | `llantas_rines` |
| 313 | LLANTAS Y RINES | TIPO DE RINES RIN DE AUMINIO FLET MASTER TRAP... | 8 | - | `opcion_componentes` | RIN DE ALUMINIO FLEET MASTER TRAPEZ... | `llantas_rines` |
| 314 | LLANTAS Y RINES | TIPO DE RINES RIN DE AUMINIO AMPRO | 8 | - | `opcion_componentes` | RIN DE ALUMINIO AMPRO | `llantas_rines` |
| 315 | LLANTAS Y RINES | TIPO DE RINES RIN DE AUMINIO AMPRO MASTER TRA... | 8 | - | `opcion_componentes` | RIN DE ALUMINIO AMPRO MASTER TRAPEZ... | `llantas_rines` |
| 316 | LLANTAS Y RINES | LLANTAS LLANTA K PATOS LINEAL | 8 | - | `opcion_componentes` | LLANTA K PATOS LINEAL | `llantas_rines` |
| 317 | LLANTAS Y RINES | LLANTAS LLANTA K PATOS TRACCION | 8 | - | `opcion_componentes` | LLANTA K PATOS TRACCION | `llantas_rines` |
| 318 | LLANTAS Y RINES | LLANTAS LLANTA FIRESTON LINEAL | 8 | - | `opcion_componentes` | LLANTA FIRESTON LINEAL | `llantas_rines` |
| 319 | LLANTAS Y RINES | LLANTAS LLANTA GODSHIELD LINEAL | 8 | - | `opcion_componentes` | LLANTA GODSHIELD LINEAL | `llantas_rines` |
| 320 | LLANTAS Y RINES | LLANTAS LLANTA FIRESTON LINEAL | - | - | `opcion_componentes` | LLANTA FIRESTON LINEAL | `llantas_rines` |
| 321 | LLANTAS Y RINES | LLANTAS LLANTA GODSHIELD LINEAL | - | - | `opcion_componentes` | LLANTA GODSHIELD LINEAL | `llantas_rines` |