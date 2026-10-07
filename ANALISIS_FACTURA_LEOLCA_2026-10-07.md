# Análisis de `Factura Leolca.xlsx` (2026-10-07)

Libro de solo lectura analizado hoja por hoja, con fórmulas. **No se copiaron** RFC, datos de clientes, nombres de colaboradores ni cuentas bancarias. La hoja `Clientes` no se abrió.

## 1. Mapa del libro

| Hoja | Contenido | Estado |
|---|---|---|
| `Factura simple` | Formato de factura (folio A-001): equipo + complementos | Con datos |
| `REPARACIONES` | Formato de factura A-003 para reparación de una pipa (lista de piezas, sin importes) | Con datos, sin precios |
| `Productos` | **Precio de lista** por producto + "combinación de ensamble" (opciones elegidas) + catálogo de rines/llantas | Con datos |
| `Complementos` | Sub-recetas de cada complemento (concha, burro, bicicletero, riel, plafones, caja de herramientas, redilas) + tabla de pisos y loderas | Con datos, incompleta |
| `Plataforma` | Costeo de **una** variante: Plataforma 40 ft 2 ejes | Completa |
| `Dolly` | Costeo del dolly | Completa |
| `Gondola` | Costeo de góndola con cuello 45 m³ (acero A-36) | Completa |
| `Traila`, `Multimodal`, `Cama Baja`, `Porta Contenedor`, `Caja Seca`, `Caja de Volteo`, `Detalle de facturas` | **Vacías** (0 celdas) | Sin datos |

Confirma lo que ya sabíamos: **jaula, caja seca, cama baja, caja de volteo, traila, multimodal y porta contenedor no tienen receta ni costeo en ningún archivo.**

## 2. Cómo se arma el precio (Plataforma 40 ft, 2 ejes)

`Productos!B2 = Plataforma!K29 + Productos!L21`

| Concepto | Importe | % del precio | Origen (fórmula) |
|---|---:|---:|---|
| Chasis: despiece de acero (61 líneas) | 128,211.69 | 25.3 % | `SUM(F5:F65)`, cada línea = cantidad × precio por pieza |
| Complementarios: kits y consumibles | 65,685.98 | 12.9 % | `SUM(M5:M22)` |
| Sueldos: mano de obra por proceso | 22,930.00 | 4.5 % | `SUM(U5:U84)`, 80 líneas de proceso |
| Ganancia | 110,000.00 | 21.7 % | **Constante escrita a mano** |
| Subtotal "Plataforma" (`K29`) | 326,827.67 | | |
| Combinación de ensamble (`L21`) | 180,885.96 | 35.6 % | `SUM(L4:L20)`: suspensión, ejes, patines, piso, sin nombre |
| **Precio de lista** | **507,713.63** | 100 % | |

- **No hay IVA** en la factura de plataforma. La factura A-001 (equipo + concha + bicicletero + personalizado) suma 520,031.88 exactos. Es el mismo criterio que ya vimos en el cotizador: el precio se maneja IVA incluido.
- **La ganancia es fija** (110,000 en plataforma), no un porcentaje. Confirma el `margen_sugerido` que cargamos para plataforma.

### 2.1 La hoja `Productos` ya es un configurador a mano
La columna `CANTIDAD` de la "combinación de ensamble" funciona como selector: cantidad 0 = no elegida, 1 o 2 = elegida. Ejemplo de la plataforma 40/2:

| Opción elegida | Cant. | Precio unit. | Total |
|---|---:|---:|---:|
| Suspensión Fleet Master HT-300 | 2 | 23,118.00 | 46,236.00 |
| Ejes Fleet Master | 2 | 19,905.60 | 39,811.20 |
| Patines HJ | 2 | 5,646.88 | 11,293.76 |
| Piso de plástico 40 ft con laminado | 1 | 52,060.00 | 52,060.00 |
| Línea sin nombre | 2 | 15,000.00 | 30,000.00 |
| Línea sin nombre | 1 | 1,485.00 | 1,485.00 |

**Esto responde la pregunta de las piernas:** el Excel cobra la suspensión **×2 en una plataforma de 2 ejes** (una por eje), no ×4. Conviene confirmarlo con producción, pero la evidencia del libro es 2 = número de ejes (`por_eje`, factor 1).

El gancho Holland, el kit de aire y las redilas **no están elegidos** en esa combinación (cantidad 0): el precio de lista 507,713.63 es una configuración concreta, no "la plataforma base".

## 3. Hallazgos que cambian decisiones

### H1. El precio del dolly parece arrastrar opciones de la plataforma (probable error)
`Productos!B6 = Dolly!K40 + L21`. Es decir, **precio del dolly = costeo del dolly (175,908.84) + la misma "combinación de ensamble" de la plataforma (180,885.96)**. Esa combinación incluye un **piso de plástico con laminado (52,060)**, que un dolly no lleva, y suspensión/ejes/patines que quizá se cuentan dos veces. Resultado: 356,794.80. Hay que preguntar al dueño si el dolly se vende realmente a ~356 mil o si es un arrastre de fórmula.

### H2. Utilidad del dolly: 65,000 aquí vs 40,000 en el cotizador
`Dolly!K38` (UTILIDAD) = **65,000**. El cotizador (`PRESUPUESTOS Y COTIZACIONES LEOLCA.xlsm`) usaba **40,000**. En `parametros_costeo` ya cargamos `margen_sugerido = {plataforma: 110000, dolly: 40000}`. **Hay que confirmar cuál vale** y corregir el parámetro (es un UPDATE de una fila).

### H3. IVA de la góndola: solo se aplica a una parte
`Gondola!Y8 = SUM(Y4:Z5*0.16)`: IVA 16 % **solo sobre chasis + tina** (103,936.96 + 167,505.76 = 271,442.72 → 43,430.84), no sobre equipamiento ni servicios. Total 704,968.50. Si el IVA debía ir sobre todo (661,537.66), faltan ~62,400. Puede ser deliberado (equipamiento ya con IVA) o un error de rango. **Pregunta para el dueño.**

### H4. Los kits son importes fijos y distintos entre hojas
Los "kits" valen un monto global en cada hoja, no se calculan de materiales:

| Kit | Plataforma | Dolly | Góndola |
|---|---:|---:|---:|
| Kit de aire, 2 ejes sin retráctil | 20,000 | 20,000 | 22,000 |
| Kit de aire, 2 ejes 1 retráctil | 24,700 | 24,700 | 26,700 |
| Kit de aire, 3 ejes 1 retráctil | — | — | 27,200 |
| Kit de aire, 3 ejes 2 retráctil | 28,500 | — | 30,500 |
| Kit de luz | 15,000 | 4,500 | 8,500 |
| Sistema retráctil UBL / paleta | — | 8,000 / 8,200 | 15,000 / 15,000 |
| Praimer | 10,000 | 4 × 285 = 1,140 | 10,000 |
| Pintura estándar | 12,000 (1½ cubeta) | 4 × 640 = 2,560 | 12,000 (1½ cubeta) |

El mismo kit tiene precios distintos según la hoja. **La receta del manual (que lista cada pieza) es la que debe reemplazar estos importes**, con precio por material. Mientras no haya precios de materiales (~230 sin precio), estos importes sirven como **costo transitorio por kit**.

Pintura: en Plataforma, "color metálico" y "color claro" están en **0** (sin precio). En Góndola valen 15,000 y 19,000.

### H5. Hay precios de lista escritos a mano que no salen de ningún costeo
`Productos`: Plataforma 42 ft 3 ejes = **505,000**, 45 ft 3 ejes = **508,000** (constantes). Plataforma 40 ft 3 ejes = igual que la de 2 ejes (misma fórmula copiada, 507,713.63). Góndola, Multimodal, Cama Baja 53 ft, Porta Contenedor y Caja Seca **no tienen precio**. Solo la 40/2 tiene costeo real.

### H6. La mano de obra es por proceso, con tarifa por persona
`Plataforma!O:U` y `Dolly!O:U`: cada proceso tiene `tiempo (min)`, `colaborador`, `costo por hora`. `Total = minutos × tarifa / 60`. La tarifa por hora varía de 42.50 a 250 según la persona (Gerencia: 720 min × 250 = 3,000). Por modelo hay ~80 líneas de proceso.
- Plataforma: 22,930. Dolly: 11,249.90. Procesos: Proceso 1–6, Escoreado y lavado, Praimer, Pintura, Aire, Luz, Piso, Enllantado, Rotulado, Marcado, más ~50 sub-procesos por pieza (botones, atizadores, jalón, aletas, estribo, ganchos, porta llantas, etc.), Gerencia y Revisión final.
- **Decisión de privacidad:** el modelo de datos debe guardar la **tarifa por rol/proceso**, no el nombre del colaborador. Los nombres no se importan.

### H7. Los precios de componentes son *costo de compra*, no precio de venta
Suspensión Fleet Master HT-300 23,118; Hendrickson 35,844; Hendrickson Alta 46,783.62; ejes Fleet Master 19,905.60 / Ampro 21,692; patines HJ 5,646.88 / Ampro 5,916 / Holland 17,980; ganchos Holland 6,844 / Premier 11,890 / Bestia 28,040.98; rines acero 1,550 / aluminio 5,500; llantas China 3,000 / Firestone 8,700 / Amulet 4,225. Coinciden con la columna `CSV_GONDOLA` del catálogo (p. ej. eje Fleet Master 19,905.60), no con el `TARIFARIO` (20,099.99). Hay **tres series de precios** (TARIFARIO, CSV/Factura, DATOS_EQUIPAMIENTO). Falta decidir cuál es costo y cuál es venta.

### H8. Despiece de acero: granularidad por pieza cortada, solo para una variante
Cada línea es una pieza con precio fijo (`Alma 2 × 12,500`, `Atizadores internos 12 × 35`, `Cargador 38 × 576.82`). No hay kg ni cálculo por largo. El despiece solo existe para 40 ft/2 ejes. Para las otras 9 variantes, las cantidades de acero salen de `BASE DAT PLANAS` del cotizador (xlsm). El libro mezcla precios de pieza: aletas, estribos, etc.

### H9. Complementos: la tabla está incompleta
`Complementos` define sub-recetas que sí cuadran: Concha 8,714.25 = material de proveedor 6,215 + ensamble 2,259.25 + escalera 3 × 80. Bicicletero 2,004 (suma de sus piezas y 334 de mano de obra). Riel con matracas 9,496.80 (riel 5,808 + 12 winches). Plafones laterales 4,342 y en estribo 3,029. Caja de herramientas 9,639.

Faltan o están en blanco: redilas 80 cm, 90 cm y 1 m (solo hay material de proveedor 11,000 para la de 70 cm), caja auxiliar y burro con partes sin precio, piso de madera y de plástico a 42 y 45 ft (solo hay precios de 40 ft: madera 22,000, plástico 35,000, madera laminada 39,060, plástico laminado 52,060), tornillería y lámina antiderrapante de 40/42/45 ft (500 / 14,400 / 15,300 / 16,200).

Las filas "Ensamble" y "Mano de obra" dentro de cada complemento son **importes fijos**, no tiempo × tarifa.

### H10. `REPARACIONES` no es del cotizador
Es otro documento de la empresa: factura de reparación de una pipa (lista de piezas a cambiar, sin importes). No entra al configurador ni a las recetas. Se trata como fuera de alcance.

## 4. Qué cambia en el 2R-1b

1. **Costos por material.** Hoy `material_proveedores` está vacía. De este libro salen costos para suspensiones, ejes, patines, ganchos, rines, llantas, quinta rueda, dona, kits, concha, redilas 70 cm, pisos 40 ft, etc. Se pueden cargar como **costo transitorio por opción** en `opciones_configuracion.datos` (o `otros_precios`), sin inventar costos de los ~230 materiales sin precio.
2. **Falta una tabla de procesos de manufactura.** `receta_base` no modela tiempo × tarifa. Propuesta para 2R-1b: `procesos_manufactura(modelo_id, proceso, minutos, rol, tarifa_hora)` más una tabla de tarifas por rol, para que "sueldos" sea una sección calculada y no una constante.
3. **Despiece de acero por pieza.** Propuesta: `despiece_acero(modelo_id, pieza, descripcion, cantidad, costo_unitario)` con un `factor_largo`/`escala`, solo para la variante 40/2; las otras salen de `BASE DAT PLANAS` y del escalado largo/40.
4. **Sección "ganancia".** Es un monto fijo por tipo de equipo (`margen_sugerido`), no un porcentaje. Ya está modelado; solo falta resolver H2.
5. **Los kits** (aire, luz, praimer, pintura) entran primero como importe transitorio y se reemplazan por la receta del manual cuando haya precios de materiales.

## 5. Preguntas para el dueño (en orden de impacto)

1. **¿La utilidad del dolly es 65,000 o 40,000?** (H2)
2. **¿El precio del dolly (356,794.80) es real o arrastra la combinación de la plataforma?** (H1)
3. **¿El IVA de la góndola va solo sobre chasis y tina, o sobre todo?** (H3)
4. **¿Qué son las dos líneas sin nombre de la combinación de ensamble** (2 × 15,000 y 1 × 1,485)? (§2.1)
5. **Suspensión de la plataforma 2 ejes: ¿2 unidades (una por eje), como cobra el Excel?** (§2.1)
6. **¿Qué serie de precios es costo y cuál es venta?** TARIFARIO vs Factura Leolca. (H7)
7. **Tarifa por hora: ¿por persona o por rol/categoría?** Y si se pueden agrupar en pocos roles. (H6)
8. **Precios de lista de las 9 variantes restantes de plataforma:** hoy solo la 40/2 está costeada; la 42/3 (505,000) y 45/3 (508,000) son constantes. (H5)
9. **Piso a 42 y 45 ft, redilas 80/90/100 cm, color metálico y claro:** precios en blanco. (H4, H9)

## 6. Estado de las fuentes

| Fuente | Aporta | Falta |
|---|---|---|
| `MANUAL.xlsx` | Recetas de materiales por opción (673 líneas) | Precios |
| `PRESUPUESTOS Y COTIZACIONES LEOLCA.xlsm` | Cantidades por variante (`BASE DAT PLANAS`), secciones | Fórmulas con constantes |
| `Factura Leolca.xlsx` | Costeo real de 40/2, dolly y góndola; costos de compra de opciones; procesos de mano de obra | 9 variantes de plataforma, 6 hojas vacías |
