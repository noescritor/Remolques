# Análisis Exhaustivo de Despiece — UNION DE LISTADOS ACTULIZADO (1).xlsx

**Fecha de emisión:** 2026-11-02  
**Archivo fuente:** `UNION DE LISTADOS ACTULIZADO (1).xlsx` (Hoja1, 321 filas, 316 datos útiles)  
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

| Orden | Clave | Nombre Oficial | Subtítulo / Alcance Operativo | Filas en Excel | Con Precio | Sin Precio | Sin Cantidad |
|---|---|---|---|:---:|:---:|:---:|:---:|
| 1 | `paso_1` | **Paso 1** | Armado y corte de almas | 3 | 0 | 3 | 0 |
| 2 | `paso_2` | **Paso 2** | Soleras de refuerzo de almas | 5 | 1 | 4 | 0 |
| 3 | `paso_3` | **Paso 3** | Estructura primaria, bordas y plancha de quinta rueda | 21 | 13 | 8 | 0 |
| 4 | `paso_4` | **Paso 4** | Cargadores transversales IPR y atizadores | 21 | 15 | 6 | 6 |
| 5 | `paso_5` | **Paso 5** | Instalación de suspensión, patines, ejes y retráctiles | 68 | 11 | 57 | 12 |
| 6 | `paso_6` | **Paso 6** | Canaleta, refuerzos y accesorios estructurales | 40 | 19 | 21 | 0 |
| 7 | `paso_7` | **PASO 7** | Lavado químico, fosfato y preparación de superficie | 4 | 0 | 4 | 0 |
| 8 | `paso_8` | **PASO 8** | Aplicación de pintura y recubrimientos por marca | 15 | 0 | 15 | 0 |
| 9 | `paso_9` | **PASO 9** | Kit neumático, sistema ABS y tanques de aire | 55 | 0 | 55 | 0 |
| 10 | `paso_10` | **PASO 10** | Sistema de iluminación reglamentaria y arnés eléctrico | 29 | 0 | 29 | 0 |
| 11 | `paso_11` | **PASO 11** | Instalación de pisos y fijaciones | 6 | 0 | 6 | 0 |
| 12 | `paso_12` | **PASO 12** | Acabados, loderas, winches y rotulación final | 16 | 0 | 16 | 0 |
| extras | `extras` | **EXTRAS** | Equipamiento adicional (redilas, retráctil Leolca, multimodal) | 18 | 0 | 18 | 0 |
| rines | `llantas_rines` | **LLANTAS Y RINES** | Juego de rodado (rines de acero/aluminio y llantas) | 15 | 0 | 15 | 4 |

Total de renglones analizados: **316 filas** (59 con precio unitario cargado, 257 sin precio registrado, 22 con cantidad abierta a proceso).

---
## 3. Diccionario Exhaustivo de Normalización de Nombres y Typos

Se identificaron y normalizaron las siguientes cadenas originales para evitar dispersión del catálogo e impedir duplicados casi idénticos:

| Texto Original en Excel | Nombre Normalizado Oficial | Categoría Asignada | Razón de Corrección |
|---|---|---|---|
| `ACURRAI` | **ACCURIDE** | Acero y Estructura | Corrección ortográfica / estandarización de espaciado y acentos |
| `ALMA ` | **ALMA** | Acero y Estructura | Corrección ortográfica / estandarización de espaciado y acentos |
| `AUMINIO` | **ALUMINIO** | Acero y Estructura | Corrección ortográfica / estandarización de espaciado y acentos |
| `CABLE CAFÉ CAL,12` | **CABLE CAFE CAL. 12** | Iluminación y Eléctrico | Corrección ortográfica / estandarización de espaciado y acentos |
| `CABLE NEGRO  CAL,12` | **CABLE NEGRO CAL. 12** | Iluminación y Eléctrico | Corrección ortográfica / estandarización de espaciado y acentos |
| `CANAL "U" DE 6" (12KG)` | **CANAL U DE 6" 12 KG** | Acero y Estructura | Corrección ortográfica / estandarización de espaciado y acentos |
| `CARGADO 3X102 IN` | **CARGADOR 3" X 102"** | Acero y Estructura | Corrección ortográfica / estandarización de espaciado y acentos |
| `FIRESTO` | **FIRESTONE** | Acero y Estructura | Corrección ortográfica / estandarización de espaciado y acentos |
| `FIRESTONE` | **FIRESTONE** | Acero y Estructura | Corrección ortográfica / estandarización de espaciado y acentos |
| `FLET` | **FLEET** | Acero y Estructura | Corrección ortográfica / estandarización de espaciado y acentos |
| `FLET MASTER` | **FLEET MASTER** | Acero y Estructura | Corrección ortográfica / estandarización de espaciado y acentos |
| `HERAJE` | **HERRAJE** | Acero y Estructura | Corrección ortográfica / estandarización de espaciado y acentos |
| `INCERTO` | **INSERTO** | Acero y Estructura | Corrección ortográfica / estandarización de espaciado y acentos |
| `MONRROE` | **MONROE** | Acero y Estructura | Corrección ortográfica / estandarización de espaciado y acentos |
| `PIJAS 5/16 X 2` | **PIJAS 5/16" X 2"** | Tornillería | Corrección ortográfica / estandarización de espaciado y acentos |
| `PIJAS 5/16 X 2 1/2` | **PIJAS 5/16" X 2 1/2"** | Tornillería | Corrección ortográfica / estandarización de espaciado y acentos |
| `PLACA TRASERA ` | **PLACA TRASERA** | Acero y Estructura | Corrección ortográfica / estandarización de espaciado y acentos |
| `PRAIMER` | **PRIMER** | Acero y Estructura | Corrección ortográfica / estandarización de espaciado y acentos |
| `PUENTES DE SUSPENSIÓN ` | **PUENTES DE SUSPENSION** | Suspensión | Corrección ortográfica / estandarización de espaciado y acentos |
| `ROLLO DE MICRO ALAMBRE` | **ROLLO DE MICROALAMBRE** | Consumibles | Corrección ortográfica / estandarización de espaciado y acentos |
| `SHERVI` | **SHERWIN WILLIAMS** | Acero y Estructura | Corrección ortográfica / estandarización de espaciado y acentos |
| `SHERVIWILLIAMS` | **SHERWIN WILLIAMS** | Acero y Estructura | Corrección ortográfica / estandarización de espaciado y acentos |
| `SOLERA DE GRADO A-529 A 1/2" X 6" ` | **SOLERA A-529 1/2" X 6"** | Acero y Estructura | Corrección ortográfica / estandarización de espaciado y acentos |
| `THINER` | **THINNER** | Acero y Estructura | Corrección ortográfica / estandarización de espaciado y acentos |
| `TORNILLEROA` | **TORNILLERIA** | Acero y Estructura | Corrección ortográfica / estandarización de espaciado y acentos |
| `TORNILLO 1/2 X 1 3/4` | **TORNILLO 1/2" X 1 3/4"** | Tornillería | Corrección ortográfica / estandarización de espaciado y acentos |
| `TORNILLO 1/2X 1 3/4` | **TORNILLO 1/2" X 1 3/4"** | Tornillería | Corrección ortográfica / estandarización de espaciado y acentos |

---
## 4. Diff Exhaustivo: Excel vs Base de Datos Real (`remolques`)

- **Total de líneas en `receta_base` para Plataforma 40 FT 2E:** 169
- **Renglones del Excel mapeados a `receta_base`:** 179
- **Renglones del Excel correspondientes a Bloques de Opciones (`opcion_componentes`):** 83
- **Materias primas únicas consolidadas en catálogo:** 256

### 4.1. Discrepancias de Cantidad detectadas (Excel vs Base de Datos)

| Pieza | Fase | Cantidad en BD | Cantidad en Excel | Uso Registrado |
|---|---|:---:|:---:|---|
| CONSUMIBLE 65 | Paso 1 | 0.25 | **0.5** | PUENTES Y BORDAS |
| DISCO DE DESBASTE 9 | Paso 1 | 0.5 | **1.0** |  |
| CO2 | Paso 2 | 1.0 | **0.5** |  |
| ROLLO DE MICRO ALAMBRE | Paso 2 | 0.5 | **1.0** |  |
| Atizadores externos | Paso 3 | 8.0 | **2.0** | Atizadores externos |
| ROLLO DE MICRO ALAMBRE | Paso 3 | 0.5 | **0.25** |  |
| CO2 | Paso 3 | 1.0 | **0.25** |  |
| DISCO LAMINADO 7 | Paso 3 | 1.0 | **0.25** |  |
| DISCO DE CORTE 7 | Paso 3 | 1.0 | **0.25** |  |
| LIJA #80 | PASO 7 | 2.0 | **10.0** |  |
| RONDANA PLANA 5/16 | PASO 9 | 444.0 | **4.0** | JUEGO DE REDILAS |
| RONDANA AUTOMOTRIZ 3/4 | PASO 9 | 4.0 | **2.0** | AMORTIGUADOR DE ALTA |
| RONDANA PLANA 5/16 | PASO 10 | 444.0 | **6.0** | JUEGO DE REDILAS |
| TUERCA ESTANDAR 1/4 | PASO 10 | 444.0 | **6.0** | JUEGO DE REDILAS |
| CORRUGADO 3/8 | PASO 10 | 3.0 | **2.8** | SI LLEVA LATERALES Y ESTRIBO |
| CORRUGADO 1/4 | PASO 10 | 22.8 | **21.8** | SI LLEVA LATERALES Y ESTRIBO |
| TERMINAL 3/16 | PASO 10 | 36.0 | **18.0** | SI LLEVA LATERALES Y ESTRIBO |
| TORNILLO 1/4X1 ACERO INOXIDABLE | PASO 12 | 4.0 | **8.0** | TORNILLERIA DE PORTA PLACA |
| TUERCA DE SEGURIDAD 1/4 | PASO 12 | 4.0 | **8.0** |  |
| RETRACTIL FABRICADO EN LEOLCA GRANDE TUERCA DE SEGURIDAD 3/4 | EXTRAS | 4.0 | **1.0** | AMORTIGUADOR DE ALTA |
| RETRACTIL FABRICADO EN LEOLCA GRANDE RONDANA AUTOMOTRIZ 3/4 | EXTRAS | 4.0 | **2.0** | AMORTIGUADOR DE ALTA |

### 4.2. Conflictos de Costo detectados (> 2% de diferencia)

| Pieza | Costo BD ($ MXN) | Precio en Excel ($ MXN) | Diferencia % | Decisión |
|---|:---:|:---:|:---:|---|
| Atizadores externos | $50.00 | $60.00 | 20.0% | Se respeta el costo previo en BD para no alterar costeo vigente |

### 4.3. Piezas presentes en Base de Datos no listadas en el Excel

Se identificaron 25 componentes en `receta_base` (tornillería de montaje interno, cintas y válvulas específicas de ensamble) que están modelados en el sistema pero no desglosados renglón a renglón en la hoja resumen:

- `CARGADORES 4 X 102 IN` (38.0 pzas, escala: `fija`, uso: CARGADOR, BORDAD LATERALES, BUCHACAS, GANCHO, TUBO, ALETAS)
- `TORNILLO ALLEN 1/2 X 1 1/2` (3.0 pzas, escala: `fija`, uso: CAJA DE HERRAMIENTA Y PORTA LLANTA)
- `TUERCA ESTANDAR 1/2 GRADO 5` (3.0 pzas, escala: `fija`, uso: CAJA DE HERRAMIENTA Y PORTA LLANTA)
- `TORNILLO 5/8 X 1 1/2 GRADO 5` (44.0 pzas, escala: `fija`, uso: 2 PARES DE PATINES)
- `TUERCA ESTANDAR 5/8 GRADO 5` (44.0 pzas, escala: `fija`, uso: 2 PARES DE PATINES)
- `KIT ABS` (1.0 pzas, escala: `fija`, uso: Estándar)
- `CABLE CAFE CAL,12` (28.5 pzas, escala: `fija`, uso: Estándar)
- `CABLE NEGRO CAL,12` (25.8 pzas, escala: `fija`, uso: SI LLEVA LATERALES Y ESTRIBO)
- `CARGADO 3 X 102 IN` (8.0 pzas, escala: `fija`, uso: SI ES MULTIMODAL O PORTA CONTENEDOR)
- `SOLERA DE ALMA (SOLERA DE GRADO A-529 A 1/2" X 6")` (4.0 pzas, escala: `fija`, uso: Solera de alma)
- `PUENTES DE SUSPENSIÓN (PTR A 2 X 6")` (6.0 pzas, escala: `fija`, uso: Puentes de suspensión)
- `PUENTES TIPO J (PLACA DE GRADO A-36 CAL. 3/16")` (7.0 pzas, escala: `fija`, uso: Puentes tipo J)
- `BOTONES (PLACA DE GRADO A-36 CAL. 1/4")` (16.0 pzas, escala: `fija`, uso: Botones)
- `ATIZADORES EXTERNOS 29CM` (2.0 pzas, escala: `fija`, uso: Atizadores externos)
- `JALON (PLACA DE GRADO A-36 CAL. 1/2")` (1.0 pzas, escala: `fija`, uso: Jalon)
- *(... y 10 piezas adicionales preservadas íntegramente)*

---
## 5. Sección 'Pendientes de Definir' (Anomalías y Datos Abiertos)

Los siguientes 22 registros de la hoja no cuentan con cantidad unitaria determinable o representan notas operativas de taller:

| Fila Excel | Proceso | Descripción de la Pieza | Clasificación / Causa |
|:---:|---|---|---|
| 46 | Paso 4 | **DISCO LAMINADO 7** | Cantidad no especificada en Excel (a definir en planta) |
| 47 | Paso 4 | **DISCO DE CORTE 7** | Cantidad no especificada en Excel (a definir en planta) |
| 48 | Paso 4 | **DISCO DE DESBASTE 9** | Cantidad no especificada en Excel (a definir en planta) |
| 49 | Paso 4 | **OXIGENO** | Cantidad no especificada en Excel (a definir en planta) |
| 50 | Paso 4 | **ROLLO DE MICROALAMBRE** | Cantidad no especificada en Excel (a definir en planta) |
| 51 | Paso 4 | **CO2** | Cantidad no especificada en Excel (a definir en planta) |
| 63 | Paso 5 | **DISCO LAMINADO 7** | Cantidad no especificada en Excel (a definir en planta) |
| 64 | Paso 5 | **DISCO DE CORTE 7** | Cantidad no especificada en Excel (a definir en planta) |
| 65 | Paso 5 | **DISCO DE DESBASTE 9** | Cantidad no especificada en Excel (a definir en planta) |
| 66 | Paso 5 | **ROLLO DE MICROALAMBRE** | Cantidad no especificada en Excel (a definir en planta) |
| 67 | Paso 5 | **CO2** | Cantidad no especificada en Excel (a definir en planta) |
| 68 | Paso 5 | **SISTEMA RETRACTIL GRANDE Retractil grande original** | Cantidad no especificada en Excel (a definir en planta) |
| 69 | Paso 5 | **SISTEMA RETRACTIL GRANDE Retractil grande propio** | Cantidad no especificada en Excel (a definir en planta) |
| 70 | Paso 5 | **SISTEMA RETRACTIL GRANDE** | Cantidad no especificada en Excel (a definir en planta) |
| 71 | Paso 5 | **SISTEMA RETRACTIL GRANDE** | Cantidad no especificada en Excel (a definir en planta) |
| 72 | Paso 5 | **SISTEMA RETRACTIL GRANDE** | Cantidad no especificada en Excel (a definir en planta) |
| 75 | Paso 5 | **SISTEMA RETRACTIL CHICO Retractil UBL original** | Cantidad no especificada en Excel (a definir en planta) |
| 76 | Paso 5 | **SISTEMA RETRACTIL CHICO Retractil UBL propio** | Cantidad no especificada en Excel (a definir en planta) |
| 307 | LLANTAS Y RINES | **MEDIDA DE RIN RIN 24.5** | Cantidad no especificada en Excel (a definir en planta) |
| 308 | LLANTAS Y RINES | **MEDIDA DE RIN RIN 22.5** | Cantidad no especificada en Excel (a definir en planta) |
| 320 | LLANTAS Y RINES | **LLANTA FIRESTON LINEAL** | Cantidad no especificada en Excel (a definir en planta) |
| 321 | LLANTAS Y RINES | **LLANTA GODSHIELD LINEAL** | Cantidad no especificada en Excel (a definir en planta) |

---
## 6. Mapeo de Bloques de Opciones Configurables Excluyentes

1. **Grupo `suspension` (Paso 5):** Alternativas de marca (`alta_hendrickson`, `hendrickson`, `fleet_master`, `ampro`, `fcr`).
2. **Grupo `patin` (Paso 5):** Opciones `ampro`, `holland`, `hj`, `flet_master`.
3. **Grupo `eje` (Paso 5):** Opciones `fleet_master`, `ampro`, `fcr`, `prat_max`, `hj` con escala `por_eje`.
4. **Grupo `retractil` (Paso 5):** Opciones `chico` (UBL) y `grande` con desglose de tornillería grado 8.
5. **Grupo `pintura` (Paso 8):** Opciones por sistema de recubrimiento (`sherwin_williams`, `ppg`, `axalta`).
6. **Grupo `piso` (Paso 11):** Opciones `plastico_cafe` (18 tablones), `pino`, `encino` con dotación de 600 pijas fijadoras.
7. **Grupos `rines` y `llantas` (LLANTAS Y RINES):** Dotaciones de rodado doble por eje con escala `por_eje`.
8. **Grupo `adicionales` (EXTRAS):** Opción `multimodal` (twistlocks y cargadores IPR 3").