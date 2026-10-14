# Informe de Importación — Sub-bloque 2R-1e: El Dolly 2 Ejes

Fecha: 2026-10-14  
Fuente: `docs/factura-leolca/extraccion_factura_leolca.json` (hoja `Dolly` de `Factura Leolca (1).xlsx`)  
Modelo importado: **DOLLY 2 EJES** (`tipo = 'dolly'`, `largo_ft = NULL`, `num_ejes = 2`)

---

## 1. Resumen de Entregables y Registros

| Tabla | Registros leídos | Registros generados / insertados | Notas |
|---|---:|---:|---|
| `productos` (producto terminado) | 1 | 1 | Producto terminado `DOLLY 2 EJES` (`tipo_item = 'producto_terminado'`, `unidad = 'PZA'`, `tipo = 'bien'`) |
| `productos` (materia prima acero) | 33 | 33 | 1 paquete consolidado + 32 piezas cortadas (`tipo_item = 'materia_prima'`) |
| `modelos` | 1 | 1 | `tipo = 'dolly'`, `largo_ft = NULL`, `num_ejes = 2`, `activo = true` |
| `receta_base` (sección acero) | 33 | 33 | Sección `acero`, escala fija, `notas = 'import-2r1e'` |
| `costos_modelo` | 18 | 18 | Kits y consumibles fijos no ligados a catálogo (`notas = 'import-2r1e'`) |
| `procesos_manufactura` | 43 | 43 | Procesos de mano de obra (filas 4 a 46), sin nombres personales |
| `opcion_costos` | 9 | 9 | Opciones con costo mapeado para `tipo_modelo = 'dolly'` |
| `parametros_costeo` | 1 | 0 | `ganancia_factura.dolly = 65000` ya existía previamente; no se modificó |

Archivos generados y modificados:
1. `scripts/generar_costos_dolly_sql.cjs`: Generador idempotente en Node.js que procesa el JSON de extracción y produce la migración.
2. `supabase/migrations/20261014_01_dolly.sql`: Migración SQL autocontenida en una transacción con funciones temporales de resolución determinista.
3. `scripts/generar_fixture_dolly.cjs`: Generador versionado del fixture para pruebas unitarias del motor.
4. `supabase/functions/make-server-feea4382/motor/fixtures/datos_costeo_dolly.json`: Fixture con datos reales del Dolly.
5. `supabase/functions/make-server-feea4382/motor/texto_especificacion.ts`: Generación de encabezado según tipo (`DOLLY ${num_ejes} EJES`, `GONDOLA ${num_ejes} EJES`, etc.).
6. `supabase/functions/make-server-feea4382/motor/texto_especificacion.test.ts`: Pruebas de especificación para Dolly y Góndola.
7. `supabase/functions/make-server-feea4382/motor/cargar_costos.ts` y `cargar_costos.test.ts`: Manejo de `largo_ft` nulo como `0` (no `NaN`).
8. `supabase/functions/make-server-feea4382/motor/costeo.test.ts`: Prueba dorada del Dolly con resultado exacto al centavo.
9. `src/app/components/Cotizaciones/ConfiguradorEquipo.tsx`: Corrección en `DialogDescription` para no renderizar "nullFT" cuando `largo_ft` es nulo.
10. `docs/importacion/verificacion_2R1e.sql`: Consulta de verificación con un solo `SELECT` y validaciones cruzadas.

---

## 2. Consolidación del Paquete de Chasis y Renglones Reemplazados

En la hoja `Dolly` del Excel, los primeros 6 renglones del despiece de acero capturan el cuerpo del chasis con un único importe global de **$14,800.00** en el primer renglón y celdas vacías en los siguientes 5. Siguiendo la regla de integración (§3 hallazgo 3 de `INTEGRACION_FACTURA_LEOLCA_2026-10-11.md`), se consolidaron en un único material:

* **Material consolidado:** `PAQUETE CUERPO CHASIS DOLLY (PUENTES J, C, Z, ALMA, SOLERAS SUPERIOR E INFERIOR)`
  * Cantidad: `1`
  * Costo: `$14,800.00`
  * Descripción: `PAQUETE`

### Renglones que reemplaza:
1. **Fila 6:** `Puente tipo J` — 4 pzas, Placa de grado A-36 Cal. 5/16" (7,93mm) [costo capturado: $14,800]
2. **Fila 7:** `Puente tipo C` — 4 pzas, Placa de grado A-36 Cal. 5/16" (7,93mm) [costo: null]
3. **Fila 8:** `Puente tipo Z` — 1 pza, Placa de grado A-36 Cal. 5/16" (7,93mm) [costo: null]
4. **Fila 9:** `Alma` — 2 pzas, Placa de grado A-36 Cal. 1/4" (6,35mm) [costo: null]
5. **Fila 10:** `Solera superior` — 2 pzas, Solera de grado A-36 de 1/2" X 6" a 2,85m [costo: null]
6. **Fila 11:** `Solera inferior` — 2 pzas, Solera de grado A-36 de 1/2" X 6" a 2,55m [costo: null]

---

## 3. Materiales Nuevos y Manejo de Colisiones

* **Total de materiales en receta_base del Dolly:** 33 materiales (1 paquete + 32 individuales).
* **Colisiones con materiales existentes en migraciones:** 0 colisiones detectadas contra los 61 materiales de la plataforma 40/2 ni los catálogos previos.
* **Mecanismo de resolución en Postgres:** La migración incluye la función temporal de sesión `pg_temp.resolver_o_crear_material_dolly`. En caso de que en la base de datos de producción ya existiese un material con el mismo nombre determinista:
  - Si el costo unitario coincide exactamente, se reutiliza el `id` existente (evitando duplicar el producto).
  - Si el costo unitario difiere, se crea un nuevo material con el sufijo ` (DOLLY)`, garantizando que ningún costo de la plataforma ni de otros modelos sea alterado.

---

## 4. Renglones Sin Precio

En el despiece de acero del Dolly:
* **Renglones con costo $0.00 o sin precio:** `0`.
* A diferencia de la plataforma 40 ft (donde los 6 puentes de suspensión carecían de precio unitario en el Excel), todos los 32 renglones individuales del Dolly cuentan con precio unitario e importe positivo en la extracción de la Factura Leolca.

---

## 5. Opciones Sin Mapear (Motivo y Detalle)

De los elementos listados en el bloque de equipamiento del Dolly en la Factura Leolca, se excluyeron de `opcion_costos` los siguientes por las razones indicadas:

1. **Dona 6 Barrenos ($5,176.00):**
   * *Motivo:* En el catálogo unificado, el grupo `dona` contiene únicamente las opciones `holland`, `premier` y `bestia`. Ninguna opción corresponde a "6 barrenos". Para no realizar una asignación arbitraria, no se mapeó y se procesa como ajuste manual en la prueba dorada.
2. **Sistema retráctil UBL ($8,000.00):**
   * *Motivo:* No existe en el catálogo la opción de retráctil `ubl` para Dolly. Solo se catalogó `paleta` ($8,200.00).
3. **Suspensión, Ejes y Patines:**
   * *Motivo:* La hoja del Dolly en `Factura Leolca (1).xlsx` no contiene precios unitarios ni fórmulas para suspensión ni ejes (y un dolly estructuralmente no lleva patines de apoyo). Si el usuario selecciona suspensión o ejes en el configurador para un Dolly, el motor reportará `opcion_sin_costo` como pendiente visible de forma transparente.

---

## 6. Clasificación de Secciones en `costos_modelo`

Los 18 conceptos de equipamiento con cantidad > 0 que no corresponden a opciones del catálogo se registraron en `costos_modelo`:

| Sección | Concepto | Cantidad | Costo Unitario | Importe Total | Criterio de Asignación |
|---|---|---:|---:|---:|---|
| `otros` | Gata de izaje | 1 | $433.00 | $433.00 | Mecanismo de elevación de lanza |
| `otros` | Bisagra | 2 | $1,041.00 | $2,082.00 | Articulación de lanza |
| `otros` | Oreja | 2 | $843.00 | $1,686.00 | Puntos de sujeción y remolque |
| `otros` | Perno de Dona | 2 | $421.08 | $842.16 | Fijación de la argolla/dona |
| `otros` | Buje cónico | 4 | $160.00 | $640.00 | Bujes mecánicos de articulación |
| `otros` | Lodera blanca | 2 | $303.99 | $607.98 | Loderas de chasis |
| `otros` | Flejes | 2 | $232.00 | $464.00 | Sujeción de loderas |
| `tornilleria` | Tornillería para loderas | 8 | $5.00 | $40.00 | Tornillería y tuercas de sujeción |
| `luz` | Kit de luz | 1 | $4,500.00 | $4,500.00 | Sistema eléctrico y cableado Dolly |
| `consumibles` | Rollo de micro tubular | 2 | $995.00 | $1,990.00 | Alambre para soldadura tubular |
| `consumibles` | Tanque de CO2 | 1 | $925.00 | $925.00 | Gas de protección para soldadura |
| `consumibles` | Consumibles | 0.5 | $550.00 | $275.00 | Discos de desbaste y consumibles |
| `consumibles` | Kit de limpieza | 1 | $400.00 | $400.00 | Químicos desengrasantes y solventes |
| `pintura` | Praimer | 4 | $285.00 | $1,140.00 | Fondo anticorrosivo (4 galones) |
| `pintura` | Pintura color estándar | 4 | $640.00 | $2,560.00 | Esmalte de acabado (4 galones) |
| `otros` | Tanque para aire | 1 | $904.00 | $904.00 | Depósito neumático del Dolly |
| `otros` | Kit de rotulación | 1 | $400.00 | $400.00 | Calcomanías y rótulos reglamentarios |
| `otros` | Cinta reflejante | 1 | $200.00 | $200.00 | Cinta reflectiva perimetral DOT |
| **Total** | | | | **$20,089.14** | |

---

## 7. Detalle Técnico de Mano de Obra (43 Procesos)

Al analizar la hoja `Dolly` en el archivo Excel original, se identificó un patrón de captura en 14 renglones de mano de obra donde la columna de minutos representaba los **minutos unitarios por pieza** y el costo de la fila se calculó multiplicando por la cantidad total de piezas del despiece de acero (por ejemplo, `Atizador`: 10 minutos unitarios × 10 piezas = 100 minutos totales; `PTR para bisagra`: 18 minutos unitarios × 2 piezas = 36 minutos totales).

Dado que el motor de costeo y la tabla `procesos_manufactura` operan con los **minutos totales por unidad terminada** (`minutos × tarifa_hora / 60`), los minutos insertados en la base de datos se calcularon como `(costo_fila × 60) / tarifa_hora`. Con esto, la suma total de mano de obra da con exactitud matemática:
$$\sum \frac{\text{minutos} \times \text{tarifa\_hora}}{60} = \$11,249.90$$

---

## 8. Tabla Comparativa: Excel vs. Sistema

Valores medidos en el disco mediante el generador y la suite de pruebas de Deno:

| Componente | Valor Excel (`Dolly`) | Valor Medido en Sistema | Diferencia | Estado |
|---|---:|---:|---:|---|
| Despiece de acero (33 renglones) | $27,018.80 | $27,018.80 | $0.00 | Exacto al centavo |
| Kits y consumibles fijos (`costos_modelo`) | $20,089.14 | $20,089.14 | $0.00 | Exacto al centavo |
| Opciones catalogadas (quinta Holland + ABS 2e) | $47,375.00 | $47,375.00 | $0.00 | Exacto al centavo |
| Ajuste manual (Dona 6 barrenos sin mapear) | $5,176.00 | $5,176.00 | $0.00 | Exacto al centavo |
| Mano de obra (43 renglones) | $11,249.90 | $11,249.90 | $0.00 | Exacto al centavo |
| **Costo Total del Equipo** | **$110,908.84** | **$110,908.84** | **$0.00** | **Cuadrado al centavo** |
| Ganancia (`ganancia_factura.dolly`) | $65,000.00 | $65,000.00 | $0.00 | Exacto |
| **Precio Sugerido** | **$175,908.84** | **$175,908.84** | **$0.00** | **Exacto al total de la hoja** |

*Nota sobre ejecución en Postgres:* Como mandata la regla de desarrollo, **no ejecuté las consultas SQL contra ninguna base de datos Postgres (ni producción ni local)**. Las pruebas fueron ejecutadas con el motor TypeScript/Deno contra el fixture determinista generado desde el archivo JSON de extracción.

---

## 9. Lista de Pendientes por Cargar para el Dolly

Los siguientes elementos **no existen en ningún archivo fuente actual** y deberán definirse en fases posteriores:
1. **Tornillería completa del Dolly:** Solo se dispone de la tornillería para loderas ($40.00) y el kit de tornillería de lanza ($226.00 dentro del acero). Falta la tornillería general de ensamble.
2. **Gastos indirectos, energía eléctrica y combustible:** No están desglosados en la hoja de Dolly.
3. **Catálogo de opciones de suspensión y ejes específicos:** La hoja de Dolly no tiene costos de suspensión ni ejes; si se seleccionan en el cotizador, se mostrarán como pendientes visibles (`opcion_sin_costo`).
