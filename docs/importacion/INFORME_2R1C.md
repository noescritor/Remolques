# Informe de Importación — Sub-bloque 2R-1c: Costos de Plataforma 40 ft / 2 ejes

Fecha: 2026-10-11  
Fuente: `docs/factura-leolca/extraccion_factura_leolca.json` (extraído de `Factura Leolca (1).xlsx`)  
Variante importada: **PLATAFORMA 40 FT / 2 EJES** (`largo_ft = 40`, `num_ejes = 2`)

---

## 1. Resumen de Entregables y Líneas Insertadas

| Tabla | Registros leídos | Registros generados/insertados | Notas |
|---|---:|---:|---|
| `productos` (materia prima acero) | 61 | 61 | Nuevos materiales con `unidad = 'PZA'`, `tipo_item = 'materia_prima'` |
| `receta_base` (sección acero) | 61 | 61 | `seccion = 'acero'`, `modelo_id` plataforma 40/2, `notas = 'import-2r1c'` |
| `costos_modelo` | 12 | 12 | Kits y consumibles fijos (sin kit de aire) |
| `opcion_costos` | 22 | 22 | Costos de opciones para `tipo_modelo = 'plataforma'` |
| `procesos_manufactura` | 80 | 80 | Mano de obra (filas 5 a 84 del Excel), sin datos de personas |
| `parametros_costeo` | 1 | 1 | Registro `ganancia_factura` |

Archivos generados:
1. `supabase/migrations/20261011_01_costos_esquema.sql`: Crea las tablas `opcion_costos`, `procesos_manufactura` y `costos_modelo` con RLS habilitada e índices en llaves foráneas.
2. `scripts/generar_costos_sql.cjs`: Generador idempotente en Node.js que procesa el JSON y emite la migración de datos.
3. `supabase/migrations/20261011_02_costos_plataforma_40x2.sql`: Transacción única e idempotente para cargar los datos de la variante 40/2.
4. `docs/importacion/verificacion_2R1c.sql`: Consulta de validación (`SELECT` único) con sumas de control.

---

## 2. Renglones Sin Precio

En el despiece de acero de la plataforma 40/2 se identificó **1 renglón sin precio**:

* **Fila 9:** `Puentes de suspensión` — 6 piezas de `PTR a 2 x 6"`.
  * Precio unitario en el Excel: `null` (en blanco).
  * Costo total en el Excel: `$0.00`.
  * Nombre asignado: `PUENTES DE SUSPENSIÓN (PTR A 2 X 6")`.
  * Registro en `productos`: `costo = 0`, `descripcion = 'SIN PRECIO'`.
  * *Observación:* En la góndola se valuaron 9 puentes a $700 c/u ($6,300 total). No se inventó el precio para mantener fidelidad estricta al Excel.

---

## 3. Opciones Sin Mapear (Motivo y Detalle)

De los bloques analizados en `extraccion_factura_leolca.json`, los siguientes elementos no se insertaron en `opcion_costos`:

1. **Pisos de madera y plástico sin laminado (40 ft):**
   * `Piso de Madera 40 Ft` ($22,000): En el catálogo existen opciones `pino` y `encino` (ambas a $22,000 en el tarifario). No se mapeó para no adivinar la especie de madera.
   * `Piso de Plastico 40 Ft` ($35,000): En el catálogo existen `plastico_cafe` ($35,000) y `plastico_negro` ($36,182.72). No se mapeó para no adivinar el color.
2. **Pisos de otras longitudes (42 ft y 45 ft):**
   * Todos los pisos de 42 ft y 45 ft (con o sin laminado) vienen con precio `null` en la hoja `Pisos` y corresponden a variantes fuera del alcance del bloque 2R-1c (reservados para 2R-1d).
3. **Kit de aire 3 ejes 1 retráctil (`3e_1_retractil`):**
   * La hoja de plataforma del Excel solo lista `2 ejes sin retractil` ($20,000), `2 ejes 1 retractil` ($24,700) y `3 ejes 2 retractil` ($28,500). La opción `3e_1_retractil` solo aparece en góndola ($27,200) y no se inventó para plataforma.
4. **Sistemas retráctiles UBL y Paleta:**
   * Figuran en la hoja de góndola a $15,000, pero no en el desglose de equipamiento de plataforma.
5. **Kit de luz de $8,500:**
   * Corresponde a la hoja góndola. La plataforma lleva el kit de luz completo de $15,000.

---

## 4. Reglas de Clasificación de Secciones en `costos_modelo`

Los 12 conceptos de `configuracion_complementarios` con cantidad mayor a 0 (excluyendo el kit de aire que va a `opcion_costos`) se asignaron a las secciones correspondientes:

| Concepto | Cantidad | Costo Unitario | Importe | Sección Asignada | Criterio de Asignación |
|---|---:|---:|---:|---|---|
| Tope de goma | 2 | $82.00 | $164.00 | `otros` | Accesorio de protección en defensa trasera |
| Lodera blanca | 2 | $303.99 | $607.98 | `otros` | Loderas individuales de chasis |
| Flejes | 2 | $232.00 | $464.00 | `otros` | Sujeción de loderas |
| Tornillería para loderas | 8 | $5.00 | $40.00 | `tornilleria` | Tornillos y tuercas de fijación |
| Banderolas | 2 | $400.00 | $800.00 | `otros` | Señalización de seguridad obligatoria |
| Kit de luz | 1 | $15,000.00 | $15,000.00 | `luz` | Sistema eléctrico y cableado general |
| Rollo de micro tubular | 3 | $995.00 | $2,985.00 | `consumibles` | Aporte para soldadura tubular de chasis |
| Tanque de CO2 | 3 | $925.00 | $2,775.00 | `consumibles` | Gas de protección para soldadura |
| Consumibles | 1 | $550.00 | $550.00 | `consumibles` | Discos y consumibles generales de taller |
| Kit de limpieza | 1 | $300.00 | $300.00 | `consumibles` | Químicos y abrasivos de limpieza pre-pintura |
| Praimer | 1 | $10,000.00 | $10,000.00 | `pintura` | Fondo anticorrosivo primario |
| Pintura color estándar | 1 | $12,000.00 | $12,000.00 | `pintura` | Acabado final (nota: 1 1/2 cubeta) |
| **Total** | | | **$45,685.98** | | |

---

## 5. Tabla Comparativa: Excel vs. Sistema

| Componente de Costo | Valor Excel (`Plataforma`) | Valor Sistema (`verificacion_2R1c.sql`) | Diferencia | Estado |
|---|---:|---:|---:|---|
| Despiece de acero (61 piezas) | $128,211.69 | $128,211.69 | $0.00 | Cuadrado al centavo |
| Kits y consumibles fijos (`costos_modelo`) | $45,685.98 | $45,685.98 | $0.00 | Cuadrado al centavo |
| Kit de aire base (opción `2e_sin_retractil`) | $20,000.00 | $20,000.00 | $0.00 | Cuadrado al centavo |
| Total complementarios hoja | $65,685.98 | $65,685.98 | $0.00 | Cuadrado al centavo |
| Mano de obra (80 renglones, 291.1 hrs) | $22,930.00 | $22,930.00 | $0.00 | Cuadrado al centavo |
| **Suma Costo Base Chasis (pre-opciones)** | **$216,827.67** | **$216,827.67** | **$0.00** | **Exacto** |
| Ganancia sugerida (`ganancia_factura`) | $110,000.00 | $110,000.00 | $0.00 | Registrada en parámetros |

*Nota:* Valores medidos en Postgres local por Claude Code, no por Antigravity.

---

## 6. Lista de los 61 Materiales Nuevos de Acero

| # | Fila Origen | Nombre Generado | Cantidad | Costo Unitario | Importe Total |
|---|---:|---|---:|---:|---:|
| 1 | 5 | ALMA (PLACA DE GRADO A-50 CAL. 1/4") | 2 | $12,500.00 | $25,000.00 |
| 2 | 6 | SOLERA DE ALMA (SOLERA DE GRADO A-529 A 1/2" X 6") | 4 | $7,304.00 | $29,216.00 |
| 3 | 7 | BORDA DELANTERA (PLACA DE GRADO A-36 CAL. 3/16") | 1 | $2,068.00 | $2,068.00 |
| 4 | 8 | BORDA TRASERA (PLACA DE GRADO A-36 CAL. 3/16") | 1 | $2,500.00 | $2,500.00 |
| 5 | 9 | PUENTES DE SUSPENSIÓN (PTR A 2 X 6") | 6 | $0.00 | $0.00 |
| 6 | 10 | PLANCHA PARA LA QUINTA (PLACA DE GRADO A-36 CAL. 3/8") | 1 | $5,700.00 | $5,700.00 |
| 7 | 11 | PUENTES TIPO J (PLACA DE GRADO A-36 CAL. 3/16") | 7 | $440.00 | $3,080.00 |
| 8 | 12 | PUENTES DE LA PLANCHA (CANAL U 5") | 4 | $450.00 | $1,800.00 |
| 9 | 13 | BOTONES (PLACA DE GRADO A-36 CAL. 1/4") | 16 | $40.00 | $640.00 |
| 10 | 14 | ATIZADORES INTERNOS (PLACA DE GRADO A-36 CAL. 1/4") | 12 | $35.00 | $420.00 |
| 11 | 15 | ATIZADORES EXTERNOS 27 CM (SOLERA DE GRADO A-36 A 3/8" X 2") | 8 | $50.00 | $400.00 |
| 12 | 16 | ATIZADORES EXTERNOS 29CM | 2 | $60.00 | $120.00 |
| 13 | 17 | JALON (PLACA DE GRADO A-36 CAL. 1/2") | 1 | $2,500.00 | $2,500.00 |
| 14 | 18 | REFUERZO DE JALON (PLACA DE GRADO A-36 CAL. 3/8") | 1 | $600.00 | $600.00 |
| 15 | 19 | REFUERZO DE JALON 2 (PLACA DE GRADO A-36 CAL. 1/4") | 2 | $400.00 | $800.00 |
| 16 | 20 | CANAL DE JALON (CANAL U 6") | 1 | $1,400.00 | $1,400.00 |
| 17 | 21 | CAJON PARA JALON (CANAL U 6") | 1 | $1,200.00 | $1,200.00 |
| 18 | 22 | TAPA DE JALON (PLACA DE GRADO A-36 CAL. 3/16") | 1 | $260.00 | $260.00 |
| 19 | 23 | CARGADORES DE 4" (CANAL U 4") | 38 | $550.00 | $20,900.00 |
| 20 | 24 | CARGADORES DE 3" (CANAL U 3") | 6 | $250.00 | $1,500.00 |
| 21 | 25 | BORDAS LATERALES (CANAL ESTRUCTURAL DE 8") | 4 | $3,500.00 | $14,000.00 |
| 22 | 26 | BUCHACAS (PLACA DE GRADO A-36 CAL. 3/16") | 48 | $45.50 | $2,184.00 |
| 23 | 27 | CANDADOS (PLACA DE GRADO A-36 CAL. 1/4") | 4 | $40.00 | $160.00 |
| 24 | 28 | CAJON PARA BANDEROLAS (PTR DE 2-1/2 X 2-1/2 CAL. 1/4") | 2 | $200.00 | $400.00 |
| 25 | 29 | CAJON PARA BANDEROLAS 2 (PTR DE 2 X 2 CAL. 1/4") | 2 | $150.00 | $300.00 |
| 26 | 30 | OREJAS PARA CADENA DE BANDEROLAS (PLACA DE GRADO A-36 CAL. 3/8") | 4 | $15.00 | $60.00 |
| 27 | 31 | CAJAS PARA LUCES (PLACA DE GRADO A-36 CAL. 12) | 2 | $250.00 | $500.00 |
| 28 | 32 | CONCHA (PLACA DE GRADO A-36 CAL. 12) | 1 | $1,200.00 | $1,200.00 |
| 29 | 33 | REFUERZO DE SUSPENSIÓN (CANAL U 5") | 2 | $350.00 | $700.00 |
| 30 | 34 | ATIZADOR DE SUSPENSIÓN (PLACA DE GRADO A-36 CAL. 1/4") | 8 | $35.00 | $280.00 |
| 31 | 35 | ATIZADOR DE PATINES (PLACA DE GRADO A-36 CAL. 1/4") | 4 | $35.00 | $140.00 |
| 32 | 36 | CASUELAS DE SUSPENSION (PLACA DE GRADO A-36 CAL. 3/8") | 4 | $65.00 | $260.00 |
| 33 | 37 | ATIZADOR DE DEFROCE DE ALMA (PLACA DE GRADO A-36 CAL. 1/4") | 4 | $35.00 | $140.00 |
| 34 | 38 | ATIZADORES PARA GOMAS (PLACA DE GRADO A-36 CAL. 1/4") | 4 | $25.00 | $100.00 |
| 35 | 39 | BASES PARA LODERAS (ANGULO ESTRUCTURAL DE 2 X 2") | 2 | $200.00 | $400.00 |
| 36 | 40 | SOPORTE PARA CABLE DE 7 POLOS (SOLERA DE GRADO A-36 A 3/8" X 2") | 1 | $80.00 | $80.00 |
| 37 | 41 | SOPORTE PARA PORTA MANITAS (SOLERA DE GRADO A-36 A 3/8" X 2") | 1 | $80.00 | $80.00 |
| 38 | 42 | SOPORTE PARA MATRACA (SOLERA DE GRADO A-36 A 3/8" X 2") | 1 | $15.00 | $15.00 |
| 39 | 43 | CASUELAS PARA MATRACA (SOLERA DE GRADO A-36 A 3/8" X 2") | 2 | $15.00 | $30.00 |
| 40 | 44 | SOPORTE PARA TANQUE DE AIRE (SOLERA DE GRADO A-36 A 1/4" X 2") | 4 | $60.00 | $240.00 |
| 41 | 45 | ABRAZADERA PARA TANQUE DE AIRE (SOLERA DE GRADO A-36 A 1/8" X 2") | 4 | $50.00 | $200.00 |
| 42 | 46 | SOPORTE DE VALVULA (SOLERA DE GRADO A-36 A 1/8" X 2") | 1 | $20.00 | $20.00 |
| 43 | 47 | PORTA MANITAS (PLACA DE GRADO A-36 CAL. 12) | 1 | $100.00 | $100.00 |
| 44 | 48 | PORTA PLACA (PLACA DE GRADO A-36 CAL. 12) | 1 | $60.00 | $60.00 |
| 45 | 49 | HERRAJE PARA PATINES 105CM (SOLERA DE GRADO A-36 A 1/2" X 3") | 2 | $358.99 | $717.98 |
| 46 | 50 | HERRAJE PARA PATINES 45CM (SOLERA DE GRADO A-36 A 1/2" X 3") | 2 | $153.99 | $307.98 |
| 47 | 51 | HERRAJE PARA PATINES 22CM (SOLERA DE GRADO A-36 A 1/2" X 3") | 2 | $75.99 | $151.98 |
| 48 | 52 | HERRAJE PARA PATINES 58CM (SOLERA DE GRADO A-36 A 1/2" X 3") | 2 | $196.99 | $393.98 |
| 49 | 53 | HERAJE PARA PATINES 125CM | 2 | $223.99 | $447.98 |
| 50 | 54 | HERAJE PARA PATINES 70CM | 2 | $124.99 | $249.98 |
| 51 | 55 | HERAJE PARA PATINES 67CM | 4 | $119.99 | $479.96 |
| 52 | 56 | HERAJE PARA PATINES 23CM | 2 | $41.99 | $83.98 |
| 53 | 57 | HERAJE PARA PATINES 7CM (SOLERA DE GRADO A-36 A 1/2" X 3") | 2 | $23.99 | $47.98 |
| 54 | 58 | HERAJE PARA PATINES 27CM | 2 | $90.99 | $181.98 |
| 55 | 59 | HERAJE PARA PATINES 30CM | 2 | $100.99 | $201.98 |
| 56 | 60 | HERAJE PARA PATINES BUCHACA (PLACA DE GRADO A-36 CAL. 1/4") | 2 | $40.99 | $81.98 |
| 57 | 61 | PORTA LLANTAS (PLACA DE GRADO A-36 CAL. 1/4") | 2 | $87.99 | $175.98 |
| 58 | 62 | PORTA LLANTAS (PLACA DE GRADO A-36 CAL. 1/4") #2 | 1 | $275.99 | $275.99 |
| 59 | 63 | PORTA LLANTAS (SOLERA DE GRADO A-36 A 1/2" X 3") | 1 | $738.99 | $738.99 |
| 60 | 64 | ESTRIBO (PTR DE 4X4" A 6.10M) | 1 | $1,050.00 | $1,050.00 |
| 61 | 65 | PORTA LODERAS (PLACA DE GRADO A-36 CAL. 12) | 2 | $440.00 | $880.00 |
| **Total** | | | **256** | | **$128,211.69** |
