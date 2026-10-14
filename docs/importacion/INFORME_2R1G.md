# Informe de Importación — Sub-bloque 2R-1g: Costos de Respaldo del Tarifario

Fecha: 2026-10-15  
Rama: `bloque-2r-1g`  
Fuentes:
- Tarifario del fabricante (`data/tarifario_leolca.json` y Excel de opciones comerciales).
- Supuestos operativos sin costo adicional (colores estándar, marcas de pintura estándar, etc.).
- Factura Leolca previa (`import-2r1c`, `import-2r1e`, `import-2r1f`) como fuente primaria inmutable.  
Migración generada: `supabase/migrations/20261015_01_costos_respaldo.sql`.  
Script generador: `scripts/generar_costos_respaldo_sql.cjs`.

---

## 1. Resumen Ejecutivo y Conteos

El sub-bloque 2R-1g completa la cobertura de costos para las opciones del catálogo comercial que la Factura Leolca no cubrió. Esto permite al motor de costeo cotizar cualquier configuración seleccionable sin dejar renglones en `$0` no intencionales ni omitir componentes críticos como llantas, rines o accesorios.

Todas las filas insertadas en esta fase llevan rigurosamente `notas = 'import-2r1g'`. El script de migración es 100% idempotente (borra selectivamente `WHERE notas = 'import-2r1g'` y utiliza `WHERE NOT EXISTS`). Las 56 filas importadas previamente de la Factura Leolca se preservaron intactas.

### Conteos en `opcion_costos`

| Tipo de Modelo | Factura Leolca | Tarifario | Supuesto: sin costo adicional | Total 2R-1g | Suma Tarifario (cu * cant) |
|---|---:|---:|---:|---:|---:|
| **Plataforma** | 8 | 33 | 19 | **60** | **$543,675.52** |
| **Dolly** | 3 | 20 | 19 | **42** | **$278,096.00** |
| **Góndola** | 3 | 20 | 19 | **42** | **$278,096.00** |
| **Total General** | **14** | **73** | **57** | **144** | — |

> **Nota de verificación:** Las opciones previas de Factura Leolca (`import-2r1c`: 22 en plataforma; `import-2r1e`: 9 en dolly; `import-2r1f`: 25 en góndola) se mantienen intactas (56 filas previas + 144 filas nuevas = 200 filas en `opcion_costos`).

---

## 2. Opciones No Mapeadas (Sección A.3) y Justificación

Durante el análisis del Tarifario se identificaron conceptos que no fueron importados a `opcion_costos`. A continuación se detalla cada uno con su debida justificación para el cliente:

| Grupo / Concepto Tarifario | Razón de No Inclusión en `opcion_costos` | Justificación Operativa |
|---|---|---|
| `llantas / linglong_tt` | No existe en `opciones_configuracion`. | El catálogo relacional tiene la opción `linglong` genérica ya mapeada a $3,200.00. No existe una variante TT en las opciones configurables. |
| `perno / holland` | No es opción intercambiable de catálogo. | El perno rey Holland forma parte de los costos base fijos del chasis en la tabla `costos_modelo` ($1,200.00). No es configurable por el cliente. |
| `manitas_rojas_azules` | Parte fija de ensamble. | Componente integrado en el kit neumático base dentro de `costos_modelo`. No es una opción comercial intercambiable. |
| `mangueras_7_vias` | Parte fija de ensamble. | Componente integrado en la instalación eléctrica fija dentro de `costos_modelo`. |
| `chasis_material` (`domex_100`, `strenx_700`) | Requiere despiece de acero independiente. | Aceros estructurales de alta resistencia no están tipificados como opciones unitarias en el catálogo; su cotización requeriría una variante completa en `receta_base`. |
| `puerta_trasera` | Diseño estructural fijo de la góndola. | En la góndola, la puerta trasera está integrada en el despiece de la tina/chasis; no se ofrece como accesorio intercambiable de costo unitario simple. |
| `poste` | No existe grupo de opciones en catálogo. | Postes de refuerzo o estacas adicionales no están modelados en la estructura actual del configurador. |
| `cuello / cuello_fijo_desmontable` | No aplica a remolques estándar. | Aplica únicamente a semirremolques tipo lowboy / cama baja, fuera del alcance de plataformas, dollys y góndolas. |

---

## 3. Discrepancia en la Canastilla (Hoja vs Despiece de Piezas)

En la hoja "OPCIONES DE PLATAFORMA" de la Factura Leolca:
- El encabezado y costo asignado a la **Canastilla porta llantas** marca un total de **$5,784.50**.
- Al sumar minuciosamente los insumos desglosados en dicha hoja (ángulos, soleras, malla desplegada, tornillos, soldadura, pintura y mano de obra de ensamble), la suma aritmética da **$5,040.00**.
- **Diferencia detectada:** **$744.50**.

### Criterio de Resolución
Se mantuvo el costo unitario de **$5,784.50** en `opcion_costos` por las siguientes razones:
1. Es el costo de hoja formalmente registrado en la documentación del fabricante.
2. Es totalmente coherente con el precio de venta al público fijado en `$8,000.00` (`opciones_configuracion.precio_venta`), respetando la guarda de coherencia `costo_unitario <= precio_venta`.

---

## 4. Conflictos entre Factura Leolca y Tarifario

Se detectaron 4 conceptos presentes tanto en la Factura como en el Tarifario con discrepancias de costo:

| Concepto | Costo Factura Leolca | Costo / Precio Tarifario | Decisión del Motor | Razón y Justificación |
|---|---:|---:|:---:|---|
| **Plafón LED** (`luces/plafon_adicional`) | $168.20 / pza | $4,342 (2E) / $3,029 (add) | **Factura ($168.20)** | La Factura documenta el costo real unitario de adquisición de cada lámpara LED. El Tarifario cotizaba kits completos con arneses y mano de obra. |
| **Caja de herramientas** (`accesorios/caja_herramientas`) | $9,500.00 | $9,639.00 | **Factura ($9,500.00)** | La Factura documenta el precio de compra real pagado al proveedor. La diferencia es de $139.00. |
| **Bicicletera** (`accesorios/bicicletera`) | $2,004.00 | $5,000.00 | **Factura ($2,004.00)** | $2,004.00 corresponde al costo directo de materiales y mano de obra de fabricación. Los $5,000.00 del Tarifario corresponden al precio comercial de venta con margen. |
| **Canastilla** (`porta_llantas/canastilla`) | $5,784.50 | $8,000.00 | **Factura ($5,784.50)** | $5,784.50 es el costo real de fabricación; los $8,000.00 del Tarifario son el precio de venta al público en `opciones_configuracion.precio_venta`. |

### Por qué el motor prioriza la Factura
La **Factura Leolca** es un documento contable vinculante que registra transacciones reales de compra a proveedores. El **Tarifario** es un catálogo comercial de precios de referencia y listas de venta sugeridas. Por norma de control de costos, la Factura es la verdad contable y el Tarifario actúa como fuente de respaldo únicamente cuando la Factura no provee un costo.

---

## 5. Simulación: Plataforma 40 ft / 3 Ejes con Opciones No Factura

Para ilustrar el impacto en producción, se simuló una **Plataforma 40 ft / 3 Ejes** configurada con opciones que antes no contaban con costo en la Factura:
- **Llantas:** Cerex (12 llantas requeridas: 3 ejes x 4 llantas por eje).
- **Color:** Rojo Claro.
- **Pintura:** Sherwin Williams.
- **Equipo estándar:** Chasis acero A-36 ($128,211.69), Kits modelo ($45,685.98), Mano de obra ($22,930.00), Suspensión neumática Fleet Master 3E ($69,354.00), Ejes Fleet Master 3E ($59,716.80), Patines HJ ($11,293.76), Frenos ABS 3E ($24,000.00), Margen base ($110,000.00).

### Comparativa Antes y Después de 2R-1g

| Concepto | Antes de 2R-1g | Con 2R-1g (Respaldo) | Impacto / Diferencia |
|---|---:|---:|---:|
| **Costo Base + Kits + MO** | $196,827.67 | $196,827.67 | Sin cambio |
| **Suspensión, Ejes, Patín, ABS** | $164,364.56 | $164,364.56 | Sin cambio |
| **Llantas Cerex (12 pzas)** | **$0.00** *(sin costo)* | **$43,032.00** *(12 x $3,586)* | **+$43,032.00** |
| **Color Rojo Claro** | **$0.00** *(sin costo)* | **$0.00** *(Supuesto)* | Registrado formalmente |
| **Pintura Sherwin Williams** | **$0.00** *(sin costo)* | **$0.00** *(Supuesto)* | Registrado formalmente |
| **COSTO TOTAL** | **$361,192.23** | **$404,224.23** | **+$43,032.00 (+11.9%)** |
| **PRECIO SUGERIDO** | **$471,192.23** | **$514,224.23** | Refleja el costo real de las 12 llantas |

### Comportamiento del Motor y Metadatos de Pendientes

1. **Antes de 2R-1g:**
   - El motor arrojaba alertas de `sin_precio = 3` por falta de costo en llantas, color y pintura.
   - El costo calculado sub-estimaba gravemente la realidad financiera de la plataforma (las 12 llantas no sumaban ni un centavo al costo total).

2. **Después de 2R-1g:**
   - El costo total se calcula con exactitud matemática ($404,224.23).
   - El motor reconoce que las opciones no provienen de la Factura Leolca e inyecta pendientes agrupados por fuente:
     * `tipo: 'costo_no_factura'`, detalle:  
       `"Costos que no vienen de la Factura (por confirmar): Tarifario → llantas/cerex"`
     * `tipo: 'costo_no_factura'`, detalle:  
       `"Costos que no vienen de la Factura (por confirmar): Supuesto: sin costo adicional → color/rojo_claro, pintura/sherwin_williams"`
   - De esta forma, el cotizador visualiza el costo completo inmediatamente, pero tiene un indicador claro y consolidado de qué insumos requieren confirmación de precio de compra real.

---

## 6. Verificación Automatizada

La verificación formal se ejecuta con:
```bash
npm.cmd run test:motor
```
Dando como resultado:
```
ok | 57 passed | 0 failed (1s)
```
Incluyendo las 6 pruebas unitarias del Sub-bloque 2R-1g en `costeo.test.ts` y la prueba de integración de presupuesto en `presupuesto_desde_costeo.test.ts`.

---

## 7. Normalización de Notas Heredadas (2R-1c y 2R-1e)

Para garantizar consistencia y facilitar filtros de auditoría limpios, se normalizaron las notas heredadas en `opcion_costos` y `costos_modelo`:
1. **Dolly (`opcion_costos`):** 5 filas de rines y llantas con notas descriptivas terminadas en `'; import-2r1e'` migraron el texto explicativo a `fuente = 'Factura Leolca (cantidad por eje supuesta igual a plataforma y góndola)'` y fijaron `notas = 'import-2r1e'`.
2. **Plataforma (`costos_modelo`):** 1 fila de pintura con `notas = ' 1 1/2 Cubeta; import-2r1c'` migró la aclaración a `fuente = 'Factura Leolca (cantidad original: 1 1/2 cubeta)'` y fijó `notas = 'import-2r1c'`.
3. **Generadores y Migraciones:** Se actualizaron `scripts/generar_costos_sql.cjs` y `scripts/generar_costos_dolly_sql.cjs`, regenerando de forma 100% determinista e idempotente `20261011_02_costos_plataforma_40x2.sql` y `20261014_01_dolly.sql`. Se creó además la migración correctiva idempotente `supabase/migrations/20261015_02_normalizar_notas.sql` producida por `scripts/generar_normalizar_notas_sql.cjs`.

### Consulta de Auditoría de Notas Exactas

Al ejecutar en Postgres:
```sql
SELECT notas, count(*) 
FROM opcion_costos 
WHERE notas ILIKE '%import-2r1%' 
GROUP BY notas
ORDER BY notas;
```
El resultado debe arrojar exclusivamente variantes exactas:
- `'import-2r1c'`: 22
- `'import-2r1e'`: 9
- `'import-2r1f'`: 25
- `'import-2r1g'`: 144

Y en `costos_modelo`:
```sql
SELECT notas, count(*) 
FROM costos_modelo 
WHERE notas ILIKE '%import-2r1%' 
GROUP BY notas
ORDER BY notas;
```
El resultado debe arrojar exclusivamente:
- `'import-2r1c'`: 12
- `'import-2r1e'`: 18
- `'import-2r1f'`: 29 (15 en 2E y 14 en 3E)

