# Informe de Importación — Sub-bloque 2R-1f: La Góndola

Fecha: 2026-10-14  
Rama: `bloque-2r-1f`  
Fuente: `docs/factura-leolca/extraccion_factura_leolca.json` (`modelos.gondola_a36` y `modelos.gondola_hardox450`).  
Migración generada: `supabase/migrations/20261014_02_gondola.sql`.

---

## 1. Resumen Ejecutivo y Conteos

Se cargaron los costos completos de los dos modelos de Góndola extraídos de la Factura Leolca: **Góndola 2 Ejes 45 m³** y **Góndola 3 Ejes 45 m³**. Siguiendo la arquitectura del sistema, el material de la tina (A-36 vs Hardox 450) se modeló como una opción de configuración del catálogo (`tina_material`: `a36` y `hardox_450`), permitiendo configurar cualquier número de ejes con cualquiera de los materiales de tina.

### Conteos en Base de Datos

| Concepto | Cantidad | Detalle |
|---|---|---|
| **Productos terminados** | 2 | `GONDOLA 2 EJES 45 M3`, `GONDOLA 3 EJES 45 M3` |
| **Modelos en `modelos`** | 2 | `tipo = 'gondola'`, `largo_ft = NULL`, `num_ejes` = 2 y 3 |
| **Renglones `receta_base` acero (chasis)** | 49 por modelo (98 total) | Ambos modelos comparten el chasis de $103,936.96 |
| **Componentes `opcion_componentes` (Tina A-36)** | 43 | Despiece completo de la tina A-36 (BOM) |
| **Componentes `opcion_componentes` (Tina Hardox)** | 39 | 2 paquetes cotizados de proveedor + 37 componentes individuales |
| **Costos de tina en `opcion_costos`** | 2 | `a36` = $167,505.76; `hardox_450` = $286,748.42 |
| **Renglones `costos_modelo` (2 ejes)** | 15 | 14 comunes ($88,996.98) + 1 kit tornillería gancho ($49.00) = $89,045.98 |
| **Renglones `costos_modelo` (3 ejes)** | 14 | 14 comunes ($88,996.98) |
| **Opciones catalogadas en `opcion_costos`** | 25 | 23 opciones de catálogo general + 2 opciones de `tina_material` |
| **Procesos de manufactura** | 0 | No hay desglose de horas/procesos; mano de obra fija en ganancia |

---

## 2. Despiece de Acero del Chasis y Colisiones de Materiales

El chasis de la góndola consta de 49 renglones en ambas hojas, sumando exactamente **$103,936.96**.

### Regla de Resolución de Materiales:
- **20 materiales reutilizados** de la plataforma al coincidir exactamente nombre y costo.
- **24 materiales nuevos** exclusivos de la góndola.
- **5 colisiones de precio con la plataforma**: materiales con el mismo nombre pero diferente costo unitario entre plataforma y góndola. Se crearon materiales independientes con el sufijo ` (GONDOLA)` para preservar íntegros los costos de la plataforma.

### Detalle de Colisiones de Materiales

| Material | Costo Plataforma | Costo Góndola | Acción Tomada |
|---|---:|---:|---|
| `BORDA DELANTERA (PLACA DE GRADO A-36 CAL. 3/16")` | $2,068.00 | $480.00 | Creado material separado con sufijo `(GONDOLA)` |
| `BASE PARA FOCO DE ABS (PLACA DE GRADO A-36 CAL. 1/4")` | $25.00 | $22.60 | Creado material separado con sufijo `(GONDOLA)` |
| `BASE PARA ABS (PLACA DE GRADO A-36 CAL. 1/4")` | $30.00 | $28.00 | Creado material separado con sufijo `(GONDOLA)` |
| `PORTA PLACAS (PLACA DE GRADO A-36 CAL. 10)` | $42.99 | $45.00 | Creado material separado con sufijo `(GONDOLA)` |
| `PORTA LLANTAS (PLACA DE GRADO A-36 CAL. 1/4")` | $87.99 | $275.99 | Creado material separado con sufijo `(GONDOLA)` |

> **Nota para el dueño:** Estas 5 piezas difieren de precio entre el archivo de plataforma y el de góndola. Se mantuvieron separadas con sufijo para no alterar los costos de la plataforma.

---

## 3. Tina por Material y Paquetes de Hardox 450

El costo de la tina se definió en `opcion_costos` (`tipo_modelo = 'gondola'`):
- `tina_material / a36`: **$167,505.76**
- `tina_material / hardox_450`: **$286,748.42**

### Paquetes de Proveedor en Hardox 450
En la cotización de Hardox, el proveedor entrega paquetes que cubren varios renglones:
1. `PAQUETE TINA HARDOX 450 (VUELTAS TRASERAS, CUELLOS, VUELTAS FRONTALES)`:
   - Importe: **$80,137.66** (cantidad 1).
   - Reemplaza las filas 59 (Vueltas traseras, 4 pzas), 60 (Cuellos, 2 pzas) y 61 (Vueltas frontales, 2 pzas).
2. `PAQUETE TINA HARDOX 450 (PISO, PLACA FRONTAL, PLACA PARA TAPA)`:
   - Importe: **$76,600.00** (cantidad 1).
   - Reemplaza las filas 71 (Piso, 1 pza), 72 (Placa frontal, 1 pza) y 73 (Placa para tapa, 1 pza).

Los 37 renglones restantes se cargaron individualmente, totalizando **39 componentes en BOM** para la tina Hardox.

### Hallazgos de la Tina
- **Hallazgo (a):** En la tina A-36, los renglones 5, 6 y 7 ("Vueltas traseras", "Cuellos", "Vueltas frontales") tienen como descripción `Placa hardox Cal. 3/16"` a pesar de ser una tina de acero A-36. Se respetó la descripción original sin alterar datos.
- **Hallazgo (b):** La tina Hardox incluye 3 renglones de **salpicaderas** (filas 99-101: $7,000.00 + $440.00 + $150.00 = $7,590.00), los cuales en la tina A-36 están capturados con cantidad 0 ($0). Esto indica que las salpicaderas probablemente son un accesorio opcional independiente y no parte intrínseca del material de la tina.

---

## 4. Costos Fijos (`costos_modelo`) y Diferencias entre Hojas

Se compararon renglón por renglón los equipamientos fijos de ambas hojas:
- **14 conceptos comunes** con cantidad y costo unitario idénticos en ambas hojas, sumando **$88,996.98**:
  - `luz`: Kit de luz ($8,500.00).
  - `pintura`: Praimer ($10,000.00).
  - `tornilleria`: Tornillería para patines ($660.00), Tornillería para loderas ($40.00).
  - `consumibles`: Rollo micro tubular ($2,985.00), Rollo sólido ($1,990.00), Tanque CO2 ($2,775.00), Consumibles ($1,100.00), Kit de limpieza ($750.00).
  - `otros`: Perno rey Holland ($1,200.00), Tanque para aire ($2,100.00), Pistón ($55,825.00), Lodera blanca ($607.98), Flejes ($464.00).
- **Renglón que difiere:**
  - `tornilleria`: "Kit de tornillería para gancho" ($49.00). Aparece con cantidad 1 en la hoja A-36 (porque esa configuración incluye Gancho Holland) y con cantidad 0 en la hoja Hardox (que no lleva gancho).
  - Para reflejar la realidad del costeo del Excel, el modelo 2 ejes incluye este renglón (suma: **$89,045.98**), mientras que el modelo 3 ejes no lo incluye (suma: **$88,996.98**).

---

## 5. Costos de Opciones Catalogadas vs Sin Mapear

Se mapearon 23 opciones de componentes a `opcion_costos` (`tipo_modelo = 'gondola'`):
- **Suspensión** (`por_eje`, base 1): Fleet Master $23,118.00; Ampro $23,118.00; Hendrickson $35,844.00; Alta Hendrickson $46,783.62; PHM $30,000.00.
- **Ejes** (`por_eje`, base 1): Ampro $21,692.00; Fleet Master $19,905.60.
- **Patines** (`fija`, base 2): Ampro $5,916.00; HJ $5,646.88; Holland $17,980.00.
- **Gancho** (`fija`, base 1): Holland 10 barrenos $6,844.00; Premier $11,890.00; Premier Bestia $28,040.98.
- **ABS** (`fija`, base 1): 2e sin retráctil $22,000.00; 2e 1 retráctil $26,700.00; 3e 1 retráctil $27,200.00; 3e 2 retráctil $30,500.00.
- **Retráctil** (`fija`, base 1): Paleta $15,000.00.
- **Rines** (`por_eje`, base 4): Acero $1,550.00; Aluminio $5,500.00.
- **Llantas** (`por_eje`, base 4): Chinas $3,000.00; Firestone $8,700.00; Amulet $4,225.00.

### Opciones Sin Mapear y Justificación
1. **Suspensión HJ ($25,000 por eje, $50,000 en A-36):** No existe clave `hj` en el grupo `suspension` del catálogo unificado (solo existe `hj_alta`). Se capturó como ajuste manual en la prueba dorada.
2. **Retráctil UBL ($15,000):** No existe la clave `ubl` en el catálogo unificado (`retractil` solo contempla `grande`, `chico`, `paleta`, `sin_retractil`).
3. **Pintura por tipo de acabado:** En el Excel de góndola se cotiza por tipo de pintura: color estándar ($12,000), color metálico ($15,000) o color claro ($19,000). El catálogo unificado modela marcas (`sherwin_williams`, `ppg`, `axalta`) y 16 colores RAL específicos, no tipos de acabado. Se incluyó como ajuste manual en las pruebas doradas ($15,000).
4. **Chanclas ($1,625):** No existe como concepto en el catálogo unificado.

---

## 6. Mano de Obra, Ganancia Fija e IVA

- **Mano de obra:** No hay procesos de manufactura por tiempo/tarifa. La hoja de góndola agrupa todo en un monto cerrado de **$100,000.00** bajo el concepto "Servicios y sueldos".
- **Ganancia:** Se asigna desde el parámetro existente `ganancia_factura.gondola_servicios_sueldos` ($100,000.00).
- **Tratamiento del IVA:** En el Excel de Leolca, el IVA del 16% se calcula **únicamente sobre la suma de Chasis + Tina**, excluyendo equipamiento y sueldos. Por regla arquitectónica, el motor de costeo no calcula IVA directamente, sino que agrega el pendiente `iva_gondola` ("El IVA de la góndola está por confirmar con el dueño: en el Excel es 16% solo sobre chasis + tina; el precio sugerido no lo incluye") y asigna confianza `estimada`.

---

## 7. Tabla Comparativa: Excel vs Sistema (Valores Medidos)

### Góndola A-36, 2 Ejes (Configuración del Excel)
- Opciones: `eje: fleet_master` (2), `patin: hj`, `gancho: holland_8_10`, `abs: 2e_1_retractil`, `retractil: paleta`, `rines: acero` (8), `llantas: chinas` (8), `tina_material: a36`.
- Ajustes: Suspensión HJ ($50,000.00) + Pintura metálico ($15,000.00).

| Sección | Valor Excel | Valor Medido en Sistema | Estado |
|---|---:|---:|:---:|
| Chasis (Acero) | $103,936.96 | $103,936.96 | Exacto |
| Tina A-36 | $167,505.76 | $167,505.76 | Exacto |
| Equipamiento (Kits + Opciones + Ajustes) | $290,094.94 | $290,094.94 | Exacto |
| — Kits fijos modelo 2 ejes | — | $89,045.98 | — |
| — Opciones elegidas | — | $136,048.96 | — |
| — Ajustes manuales | — | $65,000.00 | — |
| Mano de obra | $0.00 | $0.00 | Exacto |
| **Costo Total** | **$561,537.66** | **$561,537.66** | **Exacto** |
| Servicios y sueldos (Ganancia) | $100,000.00 | $100,000.00 | Exacto |
| **Precio Sugerido sin IVA** | — | **$661,537.66** | Exacto |
| IVA 16% sobre chasis + tina ($271,442.72 × 0.16) | $43,430.84 | $43,430.84 | En nota |
| **Precio Total con IVA (Excel)** | **$704,968.50** | **$704,968.50** | **Exacto** |

---

### Góndola Hardox 450, 3 Ejes (Configuración del Excel)
- Opciones: `suspension: hendrickson` (3), `eje: ampro` (3), `patin: holland`, `abs: 3e_2_retractil`, `retractil: {opcion: paleta, cantidad: 2}`, `rines: acero` (12), `tina_material: hardox_450`.
- Ajustes: Pintura metálico ($15,000.00).

| Sección | Valor Excel | Valor Medido en Sistema | Estado |
|---|---:|---:|:---:|
| Chasis (Acero) | $103,936.96 | $103,936.96 | Exacto |
| Tina Hardox 450 | $286,748.42 | $286,748.42 | Exacto |
| Equipamiento (Kits + Opciones + Ajustes) | $391,664.98 | $391,664.98 | Exacto |
| — Kits fijos modelo 3 ejes | — | $88,996.98 | — |
| — Opciones elegidas | — | $287,668.00 | — |
| — Ajustes manuales | — | $15,000.00 | — |
| Mano de obra | $0.00 | $0.00 | Exacto |
| **Costo Total** | **$782,350.36** | **$782,350.36** | **Exacto** |
| Servicios y sueldos (Ganancia) | $100,000.00 | $100,000.00 | Exacto |
| **Precio Sugerido sin IVA** | — | **$882,350.36** | Exacto |
| IVA 16% sobre chasis + tina ($390,685.38 × 0.16) | $62,509.66 | $62,509.66 | En nota |
| **Precio Total con IVA (Excel)** | **$944,860.02** | **$944,860.02** | **Exacto** |

---

## 8. Verificación de Integridad de Plataforma y Dolly

Las pruebas automáticas y consultas de integridad verifican que los modelos preexistentes no sufrieron ninguna alteración:
- **Plataforma 40/2:**
  - Costo de acero: **$128,211.69** (intacto).
  - Costos de modelo: **$45,685.98** (intacto).
  - Mano de obra: **$22,930.00** (intacto).
  - Costo total: **$397,713.63**; Precio sugerido: **$507,713.63** (intacto).
- **Dolly 2 ejes:**
  - Costo de acero: **$27,018.80** (intacto).
  - Costos de modelo: **$20,089.14** (intacto).
  - Mano de obra: **$11,249.90** (intacto).
  - Costo total: **$110,908.84**; Precio sugerido: **$175,908.84** (intacto).
