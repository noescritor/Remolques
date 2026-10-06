# Análisis del MANUAL de recetas y del cotizador Excel de Leolca — 2026-10-06

**Fuentes (solo lectura):** `MANUAL.xlsx` (9 hojas) y `PRESUPUESTOS Y COTIZACIONES LEOLCA.xlsm` (32 hojas, ~1,550 fórmulas con peso, 1.5 MB de macros VBA, que se extrajeron y leyeron completas).
**No se modificó código de la aplicación.** Datos personales y bancarios del libro (RFC, cuentas, CLABE, teléfonos) **no se copiaron** a ningún documento.
Marcas: **[V]** verificado en el archivo · **[I]** inferido, por confirmar · **[?]** pregunta abierta.

---

## 1. Resumen

Hay **tres capas de información que hoy viven separadas** y que el sistema debe unir:

| Capa | Dónde vive hoy | Qué contiene | Precios |
|---|---|---|---|
| **A. Cotizador comercial** | `.xlsm`: `eQUIPAMIENTO`, `DATOS DE EQUIPAMIENTO`, `TARIFARIO`, `COTIZACION2` | Qué opciones elige el cliente y cuánto cuestan (por kit/pieza) | **Sí** (tarifario) |
| **B. Presupuesto de fabricación** | `.xlsm`: `PRES PLANAS`, `PRES DOLLY`, `BASE DAT PLANAS` | Costo por secciones (acero, pirámide, truckzone, otros, piso, extras, rines, mano de obra) y precio de venta | **Sí** |
| **C. Manual de recetas** | `MANUAL.xlsx`: `PLANA`, `DOLLY`, `GONDOLA` + apoyo | Cada pieza, tornillo, cable y litro de pintura **por paso de producción y por opción elegida** | **No** (las 12 columnas de precio están vacías) |

Tu idea es la correcta y encaja exactamente con estas capas:

> **Cotizar** con todas las variantes (capa A) → enviar al cliente un **resumen** de especificaciones → al **aprobarse**, generar el **presupuesto completo** (capas B + C: acero, tornillería, luz, aire, pintura…) → de ahí salen requisición, órdenes de trabajo y costo real.

Dos consecuencias importantes:
1. **Corrijo una conclusión mía anterior.** Con "es por modelo fijo" (sesión del 20-sep) concluí que un BOM plano por producto bastaba. El manual demuestra que cada modelo es fijo **pero con ~10 grupos de opciones elegibles y reglas condicionales**. El BOM plano del Bloque 1 solo cubre las líneas fijas; el Bloque 2 debe replantearse (sección 7).
2. La receta (capa C) **reemplaza montos globales** que hoy el presupuesto estima "a ojo" (ver §5, hallazgo E3).

---

## 2. Cómo funciona hoy el cotizador Excel [V]

**Flujo de pantallas** (lo que hacen las macros y botones):

```
LOBBY / menú inicial (UserForm, se abre al abrir el libro)
  ├─ PLANAS ──> eQUIPAMIENTO (elige opciones) ─┬─> COTIZACION2   (documento para el cliente, PDF)
  │                                            ├─> PRES PLANAS   (presupuesto interno, PDF)
  │                                            ├─> CONTRATO      (compraventa con calendario de pagos)
  │                                            └─> CARTA FACTURA (documento SCT: NIV, medidas, normas)
  ├─ DOLLY  ──> eQUPAMIENTO DOLLY ─> COTIZACION DOLLY2 / PRES DOLLY
  ├─ CLIENTES (52, con RFC) · TARIFARIO (precios) · FOLIOS NIV (unidades) · PAGOS
```

- **Las macros son casi todas navegación y "guardar":** copian la columna de opciones elegidas a una tabla (`FORM PLANAS`, `FORM DOLLY`) y exportan PDFs a carpetas. No contienen lógica de negocio. Una sola función de verdad: `NumLetras` (monto en letra).
- **Toda la lógica está en fórmulas** (`INDEX/MATCH` sobre tablas con nombre). Los folios se arman por texto: cotización `C P ddmmaa-n`, plana `FOL-ddmmaa-n`, dolly `PD-ddmmaa-n`.
- El **texto de la especificación** ("SEMIREMOLQUE TIPO: PLATAFORMA 40 FT 2 EJES, CON SUSPENSIÓN ALTA HENDRICKSON, EJES FLEET MASTER, 2 PAR DE PATÍN HJ…") se **genera concatenando las opciones**. Esto es útil: el sistema debe generar ese texto solo.

---

## 3. Catálogo de configuraciones (lo que pediste)

### 3.1 Variantes de modelo (cambian cantidades de acero y consumibles) [V]

`BASE DAT PLANAS` tiene una columna de cantidades **por cada variante de plataforma**:

| Largo | 2 ejes | 3 ejes |
|---|---|---|
| 35 ft | ✔ | — |
| 40 ft | ✔ | ✔ |
| 42 ft | ✔ | ✔ |
| 43 ft | — | ✔ |
| 45 ft | ✔ | ✔ |
| 48 ft | ✔ | ✔ |

**10 variantes de plataforma.** Más: **Dolly 2 ejes**, **Traila** (15 ft, 20 ft/6 m, por medidas), y en el manual **Góndola 2/3 ejes**, **Jaula** (solo aparece en pintura), "Multimodal/Porta contenedor", "Sin retráctil", "3 ejes con 1 o 2 retráctil, con o sin gancho" (hoja `AIRE` del manual, 9 variantes de kit de aire).

Datos técnicos por variante (para Carta Factura/SCT): peso vehicular, PBVD, modelo ABS, CDE ejes traseros, número de llantas, capacidad de eje/espiga, longitud, ancho. **Solo 3 de 10 variantes los tienen capturados** [V]; el resto sale en cero en la carta factura.

### 3.2 Grupos de opciones del cotizador (el cliente elige) [V]

| Grupo | Opciones en el cotizador | Cantidad | Precio por |
|---|---|---|---|
| **Marca de ejes** | Fleet Master, Ampro (manual añade FCR, Prat Max, HJ) | = nº de ejes | pieza |
| **Suspensión** | Fleet Master, Ampro, Hendrickson, Alta Fleet Master, Alta Hendrickson, HJ Alta, sin suspensión | = nº de ejes | kit |
| **Patines** | HJ, Ampro, Holland (manual añade Flet Master) | 1 o 2 juegos | kit |
| **Piso** | Pino, Encino, Plástico café, Plástico negro, Laminado, Laminado c/madera, Laminado c/plástico, Antiderrapante, Encino central+plástico lados, Sin piso | 1 | total |
| **Riel y matracas** | Con/sin riel · matraca corrediza / soldable / sin | 10 winches típico | pieza |
| **Gancho** | Holland 8/10 barrenos, Premier 8, Premier Bestia 6, Sin gancho | 1–2 | pieza |
| **Frente** | Concha laminada (1.10–2.35 m), Concha lisa reforzada, Burro laminado (1.20/1.50/1.80), Burro madera 1.20, Sin frente (~16 medidas) | 1 | pieza |
| **Redilas** | 70, 75, 80 cm, 1 m, sin redilas | juego | juego |
| **Retráctil** | Sistema retráctil / sin | 0–2 | pieza |
| **Rines** | Acero, Aluminio, Proporciona cliente, Sin rines | 0–12 | pieza |
| **Llantas** | Cerex, Firestone, Royal Black, BF Goodrich, Eudemon, Chinas, Valiant, Amulet, Sin llantas | 0–12 | pieza |
| **Plafones** | De carrito ámbar (laterales) y rojos (estribo) | 16–20 | pieza |
| **ABS** | Kit 2 ejes / Kit 3 ejes (**se deriva** del nº de ejes) | 1 | kit |
| **Color** | 9 colores (Rojo, Rojo Coca-Cola, Vino, Negro, Azul rey, Blanco…) + segundo color | — | — |
| **Adicionales** | Polinera (4 tipos), caja herramientas (chica/grande), bicicletera, portallantas extra, canastilla, pata de elefante, caja auxiliar, lodera de centro, sistema PSI, jalón, doble solera trasera, candados, **multimodal ($50,000)**, refuerzos, barrenado sobre chasis, amarres, base de bolsa en piernas | variable | pieza |
| **Cantidad de unidades** | 1…n | — | multiplicador |

### 3.3 Grupos de opciones del manual (capa de receta) [V]

Mismos grupos, **más** los que el cotizador no maneja y que cambian la receta: **tipo de pintura** (Sherwin-Williams / PPG / Axalta, con litros distintos por marca y por largo 40/42/45 ft, jaula, góndola, juego de redilas, dolly), **tipo de bolsa retráctil** (grande ↔ chica), **tipo de gancho** y **quinta** (Holland o Fontaine, solo góndola/dolly), **dona del dolly** (Holland/Premier/Bestia).

### 3.4 Reglas y dependencias entre opciones [V salvo indicación]

| # | Regla | Evidencia |
|---|---|---|
| R1 | Sistema retráctil **grande ⇒ suspensión alta ⇒ bolsa retráctil grande** y los extras "retráctil grande hechizo" + "amortiguador de alta". **Chico ⇒ suspensión normal ⇒ 2 bolsas chicas + su tornillería.** | Hojas del manual, columna ESTATUS |
| R2 | Los **consumibles escalan con el largo** (CO2, micro­tubular, discos, lijas, luces, tornillos): 35 ft = 0.875, 42 = 1.05, 45 = 1.125, 48 = 1.2 (× la base de 40 ft). | `BASE DAT PLANAS` filas 69–84 |
| R3 | Acero también cambia por largo (cargadores: 34/38/40/43/46; buchacas: 40/52; pirámide: planchas 0.875→1…). | `BASE DAT PLANAS` |
| R4 | **Sin gancho** ⇒ el jalón de arrastre pasa a 0 (y con gancho en góndola: +1 codo, manitas con llave). | Fórmulas `IF(...="SIN GANCHO",0,…)` |
| R5 | **Con redilas** ⇒ suma redondo de 5/8, **444 tornillos, tuercas y rondanas**, 48 chavetas y pintura propia (6 L). | Manual `EXTRAS` y `PINTURA` |
| R6 | **Con laterales y estribo** ⇒ más cable negro, corrugado, 36 terminales, plafones de carrito, 72 tornillos. | Manual `LUZ` |
| R7 | **Multimodal / porta contenedor** ⇒ 12 candados + 8 cargadores 3×102. | Manual `PLANA` fila 250 |
| R8 | **3 ejes** ⇒ kit ABS de 3 ejes, "te pipa" extra, suspensión/ejes ×3, hasta 12 llantas. | `PRES PLANAS` + `AIRE` |
| R9 | **Dona del dolly ↔ tipo de gancho de la plana** (Holland / Premier / Bestia). | Hoja `DOLLY` |
| R10 | Cada pieza de suspensión está marcada **COMPONENTE** (va en el kit), **SUSTITUTO** (marca alterna de otra pieza) o **INDEPENDIENTE** (se compra aparte, p. ej. cámara Flet Master 8050). Hay que respetarlo al calcular costo y compras. | Columna ESTATUS (45 filas) |
| R11 | Tornillería ligada a cada componente (kit de gancho, kit de tanque de aire, kit de ABS, tornillería de lodera, tope, riel, porta placa…). | Columna ESTATUS del manual + hoja `TORNILLERIA` |

### 3.5 Las recetas siguen la **secuencia real de fabricación** [V]

El manual no solo lista materiales: los agrupa por **paso**, con el trabajo que se hace en cada uno.

| Paso | Qué se hace (columna ESTATUS) |
|---|---|
| 1 | Corte de placa; esmerilar placas |
| 2 | Unión de soleras |
| 3 | Plancha; puentes y bordas |
| 4 | Cargadores, bordas laterales, buchacas, gancho, tubo, aletas |
| 5 | Resolde, retráctil y suspensión |
| 6 | Caja de herramienta y porta llanta; 2 pares de patines; ejes |
| — | Limpieza → Pintura → Aire → Luz → Terminado → Extras |

Estos pasos **son las fases del Tablero Kanban** que hoy se siembran con datos de demostración (Corte y Doblez / Armado / Pintura). Con esto el tablero y el consumo de material pueden ser reales **[I: confirmar con producción]**.

---

## 4. Comparación con el sistema actual (Remolques)

| Necesidad (Excel) | Estado en Remolques | Brecha |
|---|---|---|
| Elegir variante (largo × ejes) y opciones | `Cotizacion.items[]` con producto libre; `configuracion` JSON **solo se lee al generar OT** | **No existe configurador** |
| Generar el texto de especificación | Se escribe a mano en descripción | Falta |
| Cotización resumida para el cliente | PDF Moodboard con conceptos | Falta formato "especificaciones" |
| Presupuesto por secciones | **Módulo Presupuestos con las mismas 10 secciones** (acero, pirámide, truckzone, otros, piso, extras, rines, indirectos, mano de obra, adicionales) ✔ | Está **aislado**: no nace de la cotización aprobada |
| Receta por paso y opción | BOM plano `producto_materiales` (Bloque 1) | No hay opciones, reglas, pasos ni cantidad por largo |
| Precio de acero por kg que recalcula piezas | No | Falta parámetro y piezas con kg |
| Precio por proveedor (hasta 4 por material) | 1 `costo` por producto | Falta `material_proveedores` |
| Unidad física (**chasis/NIV**) con pagos y entrega | OT con `niv`; pagos **por cotización** | Falta pago/entrega por unidad |
| Contrato de compraventa con calendario de pagos | No | Falta |
| Carta Factura SCT + datos técnicos | No | Falta |
| Folios `C P…`, `FOL-…`, `PD-…` | Folio genérico | Definir formato |
| Fotos por modelo y color | No | Opcional |

### 4.1 Lo que Antigravity ya construyó (1–5 oct) y su choque con el manual [V]

Mientras yo analizaba, Antigravity avanzó con un "Bloque 2" que ya existe en el repositorio (13 commits, `main` sin diferencia con `origin`, es decir **ya subido**): cotización con sub-ítems de receta (CPQ), `ModeloConfiguratorModal` en Presupuestos, flujo Cotización → Presupuesto, formato PDF Leolca y un SQL de recetas generado desde un CSV del mismo manual.

**Lo bueno:** el flujo que pides ya tiene esqueleto (cotización → presupuesto), y el documento `artifacts/propuesta_ux_sistemas.md` (expediente unificado, secciones colapsables por área, cálculos bloqueados en cotización) es buena idea y compatible con este diseño.

**El problema crítico, verificado en `artifacts/parsed_bom.json` y `20261005_01_recetas_nuevas.sql`:**

> El manual lista **todas las opciones a la vez** (así se consulta: "tipo de suspensión", "tipo de patín"…). Al convertirlo en **una receta plana por producto**, la **Plana 40 ft** quedó con las opciones **sumadas**, no elegidas.

| Concepto | Lo que cargaría la receta plana | Lo correcto (una opción) |
|---|---|---|
| Piernas / platos de suspensión | **10 / 10** (5 marcas) | 2 / 2 |
| Ejes | **10** (FM, Ampro, FCR, Prat Max, HJ × 2) | 2 |
| Rines | **56** (7 tipos × 8) | 8 |
| Llantas | **32** (4 tipos × 8) | 8 |
| Pintura | 3 marcas sumadas (19 + 16 + 20 L) | una marca |
| Ganchos / retráctil | los 3 ganchos y los 2 sistemas | 1 y 1 |

El CPQ de Antigravity carga esa receta en los `sub_items` de la cotización: **en el editor y en la impresión se ven cinco juegos de suspensión, cinco ejes y 56 rines**.

> **Corrección (misma fecha, tras revisar el backend):** en una primera lectura dije que `calcularRequisicion` "pediría" todo eso. Es inexacto. `sub_items` **no se guarda** en la base (no está en `toItemCotizacionRow` ni en `metadata`), y `calcularRequisicion` hace `select('*')` de `cotizaciones` y lee `cot.items`, que **no existe** en esa tabla (los conceptos están en `items_cotizacion`). La función devuelve `[]` siempre: **la requisición hoy nunca detecta faltantes**, ni buenos ni malos. El daño real en la base se limita a las filas de `producto_materiales` de los productos terminados (y a las cotizaciones impresas desde el editor). Cuando se arregle la función, el "respaldo" a `producto_materiales` leería la receta mala: por eso hay que **borrar esas filas antes** (ver `docs/remediacion/`).

**Segundo defecto, silencioso:** el SQL inserta con `ON CONFLICT DO NOTHING` sobre una restricción `UNIQUE(producto_id, material_id)`. La Plana tiene **34 materiales repetidos** (p. ej. `CONSUMIBLE 65` = 0.5 + 0.25 + 0.25; `DISCO DE DESBASTE 9` = 1 + 0.5 + 0.5 + 0.5 + 0.5). Solo sobrevive la **primera** cantidad: el consumo de soldadura y discos queda **subestimado**, sin ningún error visible.

**Tercero:** todos los materiales entran con **costo 0** (el manual no trae precios), así que el "costo de producción" del presupuesto saldría casi vacío. Además solo se cargaron **4 recetas** (Plana 40 ft ×2 hojas, Dolly, "Góndola A-36" con 8 líneas); faltan las 8 variantes restantes de plataforma.

**Estado del SQL:** está **sin versionar en la raíz** (`??`). **No debe correrse tal cual.**

> **Actualización (6-oct, diagnóstico del dueño en producción):** ese SQL del 5-oct **no se aplicó**. `productos` solo tiene el índice `productos_pkey`, así que su `ON CONFLICT (nombre, organizacion_id)` falla y la transacción se deshace (hay 144 materiales, no 227; no existe la receta "PLANA 40 FT 2 EJES CON RETRACTIL"). Los defectos de aplanado y de cantidades perdidas descritos arriba son **análisis de lo que habría pasado**, no estado de producción.
> Lo que **sí** está en producción es la migración del **1-oct** (`20261001_03_migracion_bom.sql`): 23 productos terminados con ~65 líneas de receta cada uno, generadas desde la hoja `PRODUCTOS` del cotizador. Defectos verificados en el archivo: los **8 pisos sumados**, **precio cargado como cantidad** (`MANO DE OBRA PISO` = 3000, `MONTADA DE LLANTAS` = 50), valores por defecto de 2 ejes en las variantes de 3 ejes, y 16–22 líneas por producto omitidas en silencio. Todo está en la única organización (`…0001`), la misma de las 11 cotizaciones reales (6 desde el 1-oct, 0 compras): no hay desajuste de organización.

---

## 5. Hallazgos de calidad y riesgo del Excel

| # | Hallazgo | Por qué importa |
|---|---|---|
| E1 | **El precio de venta de la cotización se teclea a mano** (`656,000`, "IVA incluido"); el presupuesto calcula `655,856.70 = costo + 110,000` **fijo** (plana) y `+ 40,000` fijo (dolly). | Margen fijo en pesos, no porcentaje: pierde sentido si cambia el costo. Hay que decidir la regla (pregunta 1). |
| E2 | **Gastos indirectos = 2.5 % de un número pegado** (`463,794.94`), no de la suma real. | Nunca cambia aunque cambie la configuración. |
| E3 | Muchas líneas del presupuesto son **montos globales**: `TORNILLOS 2,000`, `CABLEADO 827`, `LUCES 9,500`, `MATERIAL COMPLEMENTARIO 2,500`. | Es justo lo que el manual detalla; la receta permite costo real por unidad. |
| E4 | **Dos listas de precios que no coinciden**: `DATOS DE EQUIPAMIENTO` (todas las suspensiones 23,118; ejes 24,421) vs `TARIFARIO` (suspensión 23,118 / 35,844 / 43,700; ejes 20,100 / 22,231). | Ya hoy se cotiza con precios inconsistentes según de dónde se lea. |
| E5 | **IVA mezclado**: algunos costos con `×1.16`, otros sin; la cotización dice "IVA incluido". | Riesgo de margen mal calculado. |
| E6 | **Macros rotas**: `CAPVENTA`, `CAPVENT1` y `REGPAGORECIB` escriben a hojas que **no existen** (`REG DE VENTAS`, `Ventas`, `PAGOS RECIBIDOS`). Hay un nombre definido con `#REF!` (`CLIENTE`) y `END PRESUPUESTO` usa clientes con `#REF!`. | El libro arrastra funciones muertas. |
| E7 | **Dependencia de una máquina**: rutas fijas a `C:\Users\THINKPAD\OneDrive…`, `G:\Mi unidad\Leolca…` y `\\MAQUINA1LETY\respaldos…`. Libro de **14 MB**. | Un solo equipo; sin control de versiones ni acceso simultáneo. |
| E8 | **Seis plantillas de cotización distintas** (`COTIZACION`, `COTIZACION2`, `COTIZACION DOLLY`, `DOLLY2`, `TRAILA COTIZACION`, `Hoja1`) con cuentas bancarias distintas (BBVA/HSBC). | Deriva: no hay una versión oficial. |
| E9 | **Pagos por chasis, sin comprobante**: 64 pagos registrados, **0 con folio de comprobante**, 48 con fecha. Solo 2 de 199 unidades con factura capturada. | Evidencia de cobro débil. La columna "liquidada" se calcula como `adeudo = 0`; con precio vacío da "SI" falso, **no confiar en ese conteo**. |
| E10 | **199 unidades (chasis) de 63 clientes, 194 de modelo 2024; 83 sin dato de producto**; 59 con fecha de entrega. | El histórico que habría que migrar está incompleto. |
| E11 | Datos técnicos de SCT solo en 3 de 10 variantes. | Carta factura sale en cero. |
| E12 | Manual: **hoja GONDOLA con título de PLANA**; ~10 variantes de escritura de un mismo material (`MICRO ALAMBRE` / `MICROALAMBRE`, `SEGURIRAD`, `UNIO`/`UNION`…); 11 líneas sin proveedor; cantidades con unidad en texto (`1 L`, `150ML`, `2,5 M`); **12 columnas de precio vacías**; hardware que aparece en `TORNILLERIA` pero **no en ninguna receta**: bicicletero, caja auxiliar, manivela, placa de logo, tapa de chamber, bisagra del pistón, kits de cámara de suspensión. | La receta está incompleta y no es consultable tal cual. |
| E13 | **Tabla de recetas ≠ lista de opciones del cotizador** (p. ej. ejes FM/Ampro vs FM/Ampro/FCR/Prat Max/HJ; patines; rines; llantas). | Hay que decidir un catálogo único y vigente. |

---

## 6. Propuesta: del configurador a la receta resuelta

### 6.1 Flujo

```
CONFIGURAR  → modelo (largo × ejes) + opciones + cantidad + color
   ↓  precio sugerido (tarifario + margen)  ← el vendedor puede ajustarlo
COTIZACIÓN (se envía): RESUMEN de especificaciones + precio + forma de pago   [PDF]
   ↓  cliente aprueba (portal con firma)
PRESUPUESTO COMPLETO (se genera solo): acero, pirámide, truckzone, otros, piso, extras, rines
                       + tornillería, luz, aire, pintura del manual + mano de obra + indirectos
   ↓  se congela como BOM de cada unidad
ORDEN DE TRABAJO por unidad (chasis/NIV) → requisición → compra → recepción → Kanban por PASO
   ↓
CONTRATO · CARTA FACTURA · pagos por unidad · entrega
```

- **La cotización muestra poco; el presupuesto muestra todo**, tal como dijiste. El resumen replica el formato actual `COTIZACION2` (Estructura, Ejes, Suspensión, Patines, Frenos, Instalación eléctrica, Frente, Redilas, Piso, Pintura, Rines, Llantas… + precio IVA incluido + nota + forma de pago).
- **Se cotizan todas las variantes**; lo que cambia es solo **qué opciones están habilitadas por tipo de modelo** (el dolly no tiene patín ni piso).

### 6.2 Modelo de datos (conceptual, no código)

**Catálogo**
- `modelos`: tipo (plataforma/dolly/góndola/jaula/traila…), largo, ejes, datos técnicos SCT, foto, **factor_largo** (largo/40).
- `receta_base`: modelo/variante → material, cantidad (o fórmula `base × factor_largo`), **paso**, condición opcional. *(las líneas fijas)*
- `grupos_configuracion` (por tipo de modelo): clave, etiqueta, selección única/múltiple/cantidad, obligatorio, regla de cantidad (`= ejes`, `= pares`, fija), **depende_de** (p. ej. bolsa retráctil depende de retráctil).
- `opciones`: grupo → nombre, **precio comercial** (el del tarifario), vigencia.
- `opcion_componentes`: opción → material, cantidad, **rol** (componente / sustituto / independiente), **kit/uso**, paso.
- `reglas`: condición (`ejes=3`, `con_gancho`, `con_redilas`, `multimodal`, `laterales_estribo`) → agrega o quita componentes.
- `materiales` (materia prima, ya existe como `productos.tipo_item`) + **`material_proveedores`** (hasta N, precio, fecha, preferido) + **unidad** real (L, m, pza).
- `parametros_costeo`: **precio del acero por kg**, margen por tipo de modelo, % indirectos, IVA.

**Transaccional**
- Concepto de cotización: modelo + **`configuracion`** (selecciones) + cantidad + precio (sugerido y final).
- Presupuesto generado: secciones resueltas y **congeladas** (con versión de precios).
- Unidad (chasis/NIV) por OT: **pagos y entrega por unidad**.

### 6.3 Cómo cambia el plan

| Antes | Ahora |
|---|---|
| Bloque 2 = "BOM por OT, reservas, recepción parcial" | **Bloque 2 = catálogo de configuración + receta resuelta + presupuesto generado**; reservas/recepción parcial pasan al 2b |
| BOM plano `producto_materiales` | Se **conserva solo como receta base**; opciones y reglas van aparte |
| Pagos por cotización | **Pagos por unidad (chasis)**, con la cotización como agrupador |
| Fases Kanban de demostración | **Fases = pasos reales** (1–6, limpieza, pintura, aire, luz, terminado) |

El **Bloque 0 (respaldos, configuración única, CI, borrado seguro)** sigue siendo el primero: este diseño es más grande y no debe construirse sobre una base sin red de seguridad.

**Orden sugerido:** 1-FIX → Bloque 0 → **2a Catálogo y configurador** (solo cotización) → **2b Presupuesto generado + precios de componentes** → 2c Receta → OT/requisición/reservas → 3 Unidad/pagos/NIV + contrato + carta factura → resto.

---

## 6.4 Decisiones cerradas por el dueño (2026-10-06, segunda ronda)

| Pregunta | Respuesta | Efecto |
|---|---|---|
| ¿Se corrió el SQL de recetas? | **Sí, en producción** | Contención + diagnóstico + corrección con respaldo previo (`docs/remediacion/`) |
| Precio de venta | "Aplica la sugerencia" | El sistema **sugiere** costo + margen configurable por tipo de modelo (inicial: plataforma $110,000, dolly $40,000) y el vendedor ajusta; se guarda el margen real |
| Cantidades del manual | "Creo que es por unidad" | Se toma como **total de la unidad de referencia** (2 ejes, 40 ft) y se escala solo donde se indique. Queda **pendiente validar** con una tabla de verificación (ver abajo) |
| Góndola, jaula, caja seca | "Sí, hay que meterlos en las recetas" | Se soportan los 3. **Solo la góndola tiene datos**; jaula y caja seca no existen en ningún archivo y hay que capturarlas |
| Catálogo de opciones | "Combina las 2, sin repetir" | Hecho: `docs/catalogo-opciones/catalogo_opciones_unificado.json` (20 grupos, 126 opciones, 19 conflictos de precio, 27 sin precio) |
| Precios de ~230 materiales | **Sin respuesta** | Se construye con precios **vacíos y visibles** ("sin precio"); pantalla de importación en 2R-4 |

**Una verificación que sigue abierta** (porque la frase "por unidad" admite dos lecturas): en la suspensión, el manual escribe "2 PIERNAS IZQUIERDA Y DERECHA" por suspensión y el encabezado dice "2 PARES"; el Excel cotiza **2** suspensiones (una por eje) a $43,700 cada una. Si la cantidad es total de la unidad, una Plana de 2 ejes lleva **2 piernas**; si es por suspensión, lleva **4**. El motor mostrará la receta resuelta de una Plana 40 ft 2 ejes y el dueño la compara con una compra real.

---

## 7. Qué necesito de ti

**0. Urgente — ¿se corrió `20261005_01_recetas_nuevas.sql` en Supabase?** Si **no**, no lo corran: se rehace con opciones (sección 6). Si **sí**, hay que revisar `producto_materiales` y las cotizaciones creadas desde el 1 de octubre, porque cargaron recetas con todas las opciones sumadas. Es lo primero que hay que contestar.

Después, **máximo 5 preguntas** de diseño:

1. **Precio de venta:** ¿siempre es costo + margen fijo (plana $110,000, dolly $40,000) redondeado a mano, o se negocia libre? Propongo: el sistema **sugiere** el precio (costo + margen configurable por modelo) y el vendedor lo ajusta, quedando registrado el margen real.
2. **Precios de los ~230 materiales:** las columnas de precio del manual están vacías. ¿Quién los captura y cada cuándo cambian (¿semanal?)? ¿La **fuente de verdad** es el tarifario por kit (actual) o los componentes del manual? Propongo usar componentes para el presupuesto y dejar el kit solo como precio sugerido de cotización, mostrando la diferencia.
3. **Cantidades del manual:** en suspensión, patín y eje aparece "2 PARES" / "2 PZA" en el encabezado y "2" en cada opción. ¿La cantidad es **total para la unidad** (2 ejes ⇒ 2 suspensiones) o **por eje**? En tornillería de patín es total (44 = 22 × 2 pares), así que supongo total, pero confírmalo.
4. **Góndola, jaula, caja seca y traila:** el cotizador solo tiene **plataforma, dolly y traila**; el manual agrega **góndola** (y la **jaula** solo en pintura). ¿Cuáles se venden hoy? ¿Tienen cotización propia o se arma aparte?
5. **Catálogo único:** las listas del cotizador y las del manual no coinciden (ejes, patines, rines, llantas). ¿Cuál es la lista **vigente** de cada grupo?

Además, **cuando puedas**: el **PDF de una cotización y un presupuesto reales** ya generados (para clonar el formato) y confirmar si los **datos técnicos SCT** de las 7 variantes faltantes existen en otro lado.

---

## 8. Lo que no revisé

- Tablas dinámicas y segmentaciones de datos de `FOLIOS NIV` (aparecen como nombres `#N/A`); imágenes del libro (14 MB); formato de impresión.
- Si los cálculos de las hojas coinciden con lo que se cotizó en la realidad (solo se leyeron fórmulas y valores guardados).
- Archivos auxiliares generados: `docs/manual-recetas/lineas_parseadas.json` (673 filas del manual ya separadas en cantidad, unidad, proveedor y uso).
