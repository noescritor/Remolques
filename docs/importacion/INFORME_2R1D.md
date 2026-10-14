# Informe de Importación — Sub-bloque 2R-1d: Costos de Variantes de Plataforma

Fecha: 2026-10-14  
Fuente: `Factura Leolca (1).xlsx` (hoja `BASE DAT PLANAS` y costos base de la 40/2 de 2R-1c)  
Modelos procesados: **8 variantes derivadas** a partir de la **PLATAFORMA 40 FT / 2 EJES**

---

## 1. Resumen Ejecutivo y Alcance

En la `Factura Leolca (1).xlsx`, únicamente el modelo **PLATAFORMA 2 40 FT** cuenta con un desglose completo de costos, compras y mano de obra al centavo (incorporado en el sub-bloque 2R-1c). Las demás plataformas solo presentan precios de lista globales en la carátula comercial (40/3 = $507,713.63 [copia idéntica de la fórmula de 2 ejes], 42/3 = $505,000.00, 45/3 = $508,000.00), sin despiece ni análisis de costos propio.

El sub-bloque **2R-1d** deriva los costos de las demás variantes de plataforma a partir de la 40/2, permitiendo que el cotizador y el generador de presupuestos funcionen para todas las variantes de plataforma estándar sin bloquearse por "el modelo no tiene costos cargados".

Cada modelo derivado queda explícitamente marcado en la base de datos con `costos_derivados_de = <id_40_2>`, y el motor de costeo emite un pendiente de tipo `variante_supuesta` con nivel de confianza **`estimada`** (nunca `completa`), garantizando que tanto el configurador como el vendedor vean siempre el aviso de que se trata de un costo de referencia supuesto por validar.

---

## 2. Modelos Derivados y Modelo Omitido

### 2.1 Modelos destino derivados (8 variantes)
Se crearon registros de costos para los 8 modelos de plataforma existentes en el catálogo:
1. `PLATAFORMA 2 35 FT` (35 ft / 2 ejes)
2. `PLATAFORMA 3 40 FT` (40 ft / 3 ejes)
3. `PLATAFORMA 2 42 FT` (42 ft / 2 ejes)
4. `PLATAFORMA 3 42 FT` (42 ft / 3 ejes)
5. `PLATAFORMA 2 45 FT` (45 ft / 2 ejes)
6. `PLATAFORMA 3 45 FT` (45 ft / 3 ejes)
7. `PLATAFORMA 2 48 FT` (48 ft / 2 ejes)
8. `PLATAFORMA 3 48 FT` (48 ft / 3 ejes)

### 2.2 Modelo omitido: `PLATAFORMA 3 43 FT`
El modelo **43 ft / 3 ejes se omite intencionalmente** de esta migración.
- **Motivo:** En la hoja `BASE DAT PLANAS` del cotizador de Leolca solo existen columnas para longitudes de **35, 40, 42, 45 y 48 ft**. No existe información técnica ni de cargadores para 43 ft.
- **Comportamiento en el sistema:** Al cotizar una plataforma de 43 ft y presionar "Generar presupuesto", el sistema omite el concepto y avisa de manera concisa: `PLATAFORMA 3 43 FT: sin costos cargados todavía`. Queda catalogado como pendiente de definición con el dueño.

---

## 3. Qué se Copió y Qué Cambió

Desde el modelo base 40 ft / 2 ejes (`v_origen_id`):

1. **`receta_base` (acero, 61 renglones por variante):**
   - Se copian los 61 renglones de acero con los mismos materiales y costos unitarios.
   - **Único cambio:** La cantidad del cargador de 4" (`CARGADOR (IPR DE 4")`, fila 34 del despiece, costo unitario $576.82), la cual se ajusta según la tabla técnica de `BASE DAT PLANAS`:
     - **35 ft:** 34 cargadores (delta vs 40 ft: -4 pzas, -$2,307.28)
     - **40 ft:** 38 cargadores (base 40/2: $21,919.16)
     - **42 ft:** 40 cargadores (delta vs 40 ft: +2 pzas, +$1,153.64)
     - **45 ft:** 43 cargadores (delta vs 40 ft: +5 pzas, +$2,884.10)
     - **48 ft:** 46 cargadores (delta vs 40 ft: +8 pzas, +$4,614.56)
2. **`costos_modelo` (kits y consumibles, 12 renglones por variante):**
   - Se copian idénticos los 12 conceptos (luz $15,000, pintura $22,000, micro tubular, CO2, topes, loderas, flejes, tornillería, consumibles, etc.) con total $45,685.98.
3. **`procesos_manufactura` (mano de obra, 80 renglones por variante):**
   - Se copian idénticos los 80 procesos (291.1 horas-hombre, tarifa por proceso) sumando $22,930.00.
4. **`opcion_costos` (Piso por largo):**
   - Se migró la escala de las opciones de piso (`laminado_madera` y `laminado_plastico`) a `escala = 'por_largo'`.
   - Para 40 ft el factor es `40 / 40 = 1` (la prueba dorada de la 40/2 se mantiene idéntica en $397,713.63 costo / $507,713.63 precio).
   - Para otros largos, el costo escala como `largo_ft / 40.0`. Por ejemplo, en piso plástico laminado ($52,060 base):
     - 35 ft: $45,552.50 (-$6,507.50)
     - 42 ft: $54,663.00 (+$2,603.00)
     - 45 ft: $58,567.50 (+$6,507.50)
     - 48 ft: $62,472.00 (+$10,412.00)
5. **Marcado en base de datos:**
   - Para los 8 modelos destino se ejecuta `UPDATE modelos SET costos_derivados_de = <id_40_2>`.

---

## 4. Tabla de Sanidad: Precios Sugeridos vs Precios de Lista de Factura Leolca

Medición ejecutada directamente con la función pura de costeo (`costeo.ts`) usando los datos generados y la configuración de la prueba dorada:
- Suspensión: Fleet Master
- Ejes: Fleet Master
- Patín: HJ
- Piso: Plástico laminado
- Kit de aire / ABS:
  - 2 ejes: `2e_sin_retractil` (costo $20,000.00)
  - 3 ejes: `3e_2_retractil` (costo $28,500.00)
- Ajustes de la prueba dorada: $31,485.00 ($30,000 líneas sin concepto + $1,485)
- Ganancia: $110,000.00

| Variante | Cargadores | Costo Acero | Opciones | Costo Total | Ganancia | Precio Sugerido | Precio Lista Factura | Diferencia (Sugerido - Lista) | Confianza Costeo |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
| **40/2 (Base)** | 38 | $128,211.69 | $169,400.96 | $397,713.63 | $110,000.00 | **$507,713.63** | $507,713.63 | **$0.00 (Exacto)** | Estimada (`sin_precio`) |
| **35/2** | 34 | $125,904.41 | $162,893.46 | $388,898.85 | $110,000.00 | **$498,898.85** | *Sin precio lista* | N/A | Estimada (`variante_supuesta`, `sin_precio`) |
| **40/3** | 38 | $128,211.69 | $220,924.56 | $449,237.23 | $110,000.00 | **$559,237.23** | $507,713.63 | **+$51,523.60 (+10.1%)** | Estimada (`variante_supuesta`, `sin_precio`) |
| **42/2** | 40 | $129,365.33 | $172,003.96 | $401,470.27 | $110,000.00 | **$511,470.27** | *Sin precio lista* | N/A | Estimada (`variante_supuesta`, `sin_precio`) |
| **42/3** | 40 | $129,365.33 | $223,527.56 | $452,993.87 | $110,000.00 | **$562,993.87** | $505,000.00 | **+$57,993.87 (+11.5%)** | Estimada (`variante_supuesta`, `sin_precio`) |
| **45/2** | 43 | $131,095.79 | $175,908.46 | $407,105.23 | $110,000.00 | **$517,105.23** | *Sin precio lista* | N/A | Estimada (`variante_supuesta`, `sin_precio`) |
| **45/3** | 43 | $131,095.79 | $227,432.06 | $458,628.83 | $110,000.00 | **$568,628.83** | $508,000.00 | **+$60,628.83 (+11.9%)** | Estimada (`variante_supuesta`, `sin_precio`) |
| **48/2** | 46 | $132,826.25 | $179,812.96 | $412,740.19 | $110,000.00 | **$522,740.19** | *Sin precio lista* | N/A | Estimada (`variante_supuesta`, `sin_precio`) |
| **48/3** | 46 | $132,826.25 | $231,336.56 | $464,263.79 | $110,000.00 | **$574,263.79** | *Sin precio lista* | N/A | Estimada (`variante_supuesta`, `sin_precio`) |

### Hallazgos clave de la tabla de sanidad:
1. **La 40/3 en la Factura Leolca está subvaluada o tiene una fórmula copiada sin actualizar:**
   - En el Excel original, la celda de precio de 40/3 muestra $507,713.63 (exactamente el mismo número de la 40/2). Un 3er eje con su suspensión Fleet Master agrega por sí solo $43,023.60 de costo directo ($23,118 suspensión + $19,905.60 eje), más la diferencia del kit de aire ($8,500). El sistema calcula un costo real de $449,237.23 y un precio de $559,237.23.
2. **Las variantes 42/3 ($505,000) y 45/3 ($508,000) de lista no cubren un tercer eje:**
   - Si la 40/2 cuesta $507,713.63, un precio de lista de $505,000 para 42/3 o de $508,000 para 45/3 es físicamente imposible si se incluye el tercer eje comercial completo a los costos unitarios del Excel. El sistema reporta diferencias de ~$58,000 a ~$60,000 respecto a los precios de lista fijos capturados en la portada del Excel.
3. **Si para 3 ejes se selecciona el kit `3e_1_retractil` (que aún no tiene costo registrado):**
   - El costo de ABS es $0 (genera aviso `opcion_sin_costo`), con lo cual los precios sugeridos quedan en:
     - 40/3: $530,737.23 (diferencia vs lista: +$23,023.60)
     - 42/3: $534,493.87 (diferencia vs lista: +$29,493.87)
     - 45/3: $540,128.83 (diferencia vs lista: +$32,128.83)

---

## 5. Supuestos Técnicos que el Dueño Debe Validar

Para consolidar estas variantes como definitivas (y retirar la marca `variante_supuesta`), el dueño del proyecto (Luis) debe revisar:
1. **Acero constante:** Se asume que toda la estructura de acero (vigas, bordas, perchas, placa de quinta, etc.) es idéntica en todas las longitudes, y que la única variación de acero son los cargadores de 4" (según `BASE DAT PLANAS`).
2. **Tercer eje y suspensión:** Se asume que la tercera suspensión y el tercer eje se costean proporcionalmente con la regla `por_eje` (1 unidad adicional con el mismo costo de amortiguador/viga/bolsa).
3. **Escala de piso:** Se asume que el costo del piso escala estrictamente en proporción al largo (`largo_ft / 40.0`).
4. **Mismos kits y mano de obra:** Se asume que las 8 variantes consumen los mismos $45,685.98 de kits/consumibles y las mismas 291.1 horas-hombre ($22,930.00) de mano de obra.
5. **Puentes de suspensión:** Se asumen 6 puentes para todas las plataformas (tanto de 2 como de 3 ejes), manteniéndose con costo $0 (`SIN PRECIO`).
6. **Kit de aire 3 ejes 1 retráctil (`3e_1_retractil`):** Definir el costo unitario para plataformas de 3 ejes (en góndola aparece en $27,200).

---

## 6. Entregables del Sub-bloque 2R-1d

1. `supabase/migrations/20261013_01_costos_derivados.sql`: Migración de esquema (`ALTER TABLE modelos ADD COLUMN costos_derivados_de...` y `UPDATE opcion_costos SET escala = 'por_largo' WHERE grupo = 'piso'`).
2. `scripts/generar_costos_variantes_sql.cjs`: Generador determinista de migración de datos.
3. `supabase/migrations/20261013_02_costos_variantes_plataforma.sql`: Transacción única e idempotente que carga 1,224 renglones (61 receta base, 12 costos modelo, 80 procesos de manufactura por cada uno de los 8 destinos) y actualiza `costos_derivados_de`.
4. `docs/importacion/verificacion_2R1d.sql`: Consulta SQL de un solo `SELECT` que valida los 8 modelos destino y una fila resumen de control.
5. `docs/importacion/INFORME_2R1D.md`: Este informe con la tabla de sanidad y supuestos.
