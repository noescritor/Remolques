# Diagnóstico: Por qué "Productos y servicios" no muestra todo el catálogo

**Fecha:** 2026-11-02  
**Autor:** Antigravity (Auditoría Técnica T1)  
**Objetivo:** Explicar con evidencia en el código y las migraciones por qué en la vista de "Productos y servicios" categorías como "Remolques terminados" solo muestran 3 productos, "Refacciones" 2, "Materias primas" 5 y "Acero" 1, a pesar de que el sistema cuenta con cientos de piezas y opciones de cotización.

---

## 1. Hallazgos y Verificación de Hipótesis

### Hipótesis 1: Corte de 1000 filas en PostgREST (`GET /productos`)
- **Veredicto: MITIGACIÓN PREVENTIVA (Medición en base real: 512 productos).**
- **Medición real:** En la base de datos de producción/local existen actualmente **512 productos**. Por tanto, la tabla aún no supera el límite de 1000 de PostgREST. La razón directa por la cual la vista de productos solo mostraba 11 ítems es la **Hipótesis 2** (501 de 512 productos tienen `categoria_id = NULL`).
- **Riesgo mitigado:** Se implementó paginación por lotes de 1000 con `.range()` para garantizar que cuando la importación completa de materias primas y refacciones supere las 1000 filas, la API no sufra truncado silencioso.

### Hipótesis 2: Productos cargados por migración tienen `categoria_id = NULL`
- **Veredicto: CONFIRMADA (Causa dominante: 501 de 512 productos).**
- **Evidencia en migraciones:**
  En las migraciones históricas donde se compilaron las piezas del BOM (`20261001_03_migracion_bom.sql`, `20261008_01_recetas_plataforma.sql`, `20261011_02_costos_plataforma_40x2.sql`, `20261014_01_dolly.sql`, `20261014_02_gondola.sql`), todas las sentencias de inserción siguen la firma:
  ```sql
  INSERT INTO productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)
  VALUES (...)
  ```
  En ninguna de ellas se suministra `categoria_id`, por lo que su valor por omisión en base de datos es `NULL`.
- **Evidencia en frontend (`src/app/components/Productos/ProductosList.tsx`):**
  La interfaz toma las categorías de la tabla `categorias_producto` (que contiene "Remolques terminados", "Refacciones", "Materias primas", "Acero") y genera una pestaña por categoría.
  Al hacer clic en cualquier pestaña, el filtro aplica:
  ```typescript
  const matchCat = categoriaActiva === 'todas' || producto.categoria_id === categoriaActiva;
  ```
  Como 501 de los 512 productos importados tienen `categoria_id = null`, ninguno coincidía con el ID de las categorías. Por tanto:
  1. En las pestañas de categorías solo aparecían los poquísimos productos ingresados manualmente o en seeds iniciales (3 terminados, 2 refacciones, 5 materias primas y 1 acero = 11 en total).
  2. No existía pestaña "Sin categoría", por lo que para ver el resto de productos el usuario estaba forzado a permanecer en "Todas".

### Hipótesis 3: La información del cotizador vive en tablas separadas, no en `productos`
- **Veredicto: CONFIRMADA.**
- **Evidencia en arquitectura:**
  El cotizador y catálogo de costos operan con un modelo relacional desacoplado:
  1. **Acero:** La lista de vigas, canales, ángulos, soleras y placas reside en la tabla `acero_materiales` (creada en `20261027_01_acero_precios.sql`) con sus cotizaciones de proveedores en `acero_precios`.
  2. **Opciones de configuración:** Suspensiones, ejes, patines, retráctiles, rines, llantas, pintura, pisos y aditamentos residen en `opciones_configuracion`, con costos por modelo en `opcion_costos` y despiece en `opcion_componentes`.
  Salvo que una opción tenga explícitamente asignado un `producto_id`, estas opciones no existen como registros en `productos`. Por ello, aunque tengan precios y costos plenamente funcionales en el cotizador, jamás aparecían en la pantalla de "Productos y servicios".

---

## 2. Reglas de Resolución de Precios y Opciones (Ronda 3)

### 2.1. Regla para múltiples proveedores en Aceros (`acero_precios`)
En los datos reales de `acero_precios`, **23 de 38 materiales cuentan con 2 a 3 cotizaciones de proveedores distintos que comparten exactamente la misma fecha de actualización** (`actualizado_el = '2026-10-26 16:43:19.405011+00'`).

Para evitar que el precio vigente varíe aleatoriamente según el orden en que la base de datos devuelva las filas embebidas, se estableció la siguiente regla determinista:
1. **Menor precio disponible (`precio > 0`):** Se selecciona como precio vigente de referencia el precio unitario más económico entre todos los proveedores (enfoque de compras y optimización de costos).
2. **Desempate alfabético estricto:** Si dos o más proveedores ofrecen exactamente el mismo precio y fecha, se desempata por nombre de proveedor en orden alfabético ascendente (`A-Z`).
3. **Desempate por fecha:** En caso de discrepancia de fechas, se prioriza la cotización más reciente.
4. **Exposición completa (`precios_todos`):** La API expone el arreglo íntegro de cotizaciones (`proveedor`, `precio`, `incluye_iva`, `fuente`, `actualizado_el`) y el contador `total_proveedores`. En la pantalla de Aceros se muestra el proveedor vigente, IVA, y una etiqueta interactiva con el número de proveedores y el desglose de precios disponibles.
5. **Unidades realistas:** Los perfiles, vigas, canales y ángulos se comercializan por tramo comercial (ej. 6.10 m o 12.20 m) o pieza, no por kilo. Se asigna `unidad = 'placa'` si cuenta con ancho y largo en pies, y `unidad = 'tramo'` si es un perfil longitudinal (evitando forzar erróneamente `kg`).

### 2.2. Regla para costos de Opciones Configurables (`opcion_costos`)
Una misma opción configurable (por ejemplo, "Suspensión Flet Master 2 ejes") puede tener múltiples costos registrados en `opcion_costos` según el tipo de remolque (`plataforma`, `dolly`, `gondola`):
1. **Prioridad Plataforma:** Se toma como costo de referencia el asociado a `tipo_modelo = 'plataforma'`, al ser el vehículo insignia y de mayor volumen en la planta.
2. **Respaldo general:** Si la opción no se utiliza en plataforma o no tiene costo asignado para plataforma, se toma el primer costo disponible de la lista en `opcion_costos`.

---

## 3. Solución Implementada en T1

1. **Backend (`/productos` y `/catalogo-cotizador`):**
   - Soporte de paginación completa en `GET /productos` mediante `.range()` por lotes para superar el tope de 1000 filas de PostgREST y garantizar que no se pierdan productos en solicitudes completas.
   - Parámetros de consulta opcionales `?page&limit&q&categoria&sin_costo=1` para búsquedas eficientes.
   - Retorno retrocompatible (mantiene formato de array o `{ productos, total, truncado }` según solicitud del cliente).
   - Nuevo endpoint de solo lectura `GET /catalogo-cotizador` que expone los aceros de `acero_materiales` y las opciones de `opciones_configuracion` con sus costos y precios aplicando las reglas deterministas de desempate, sin duplicar datos en `productos`.
2. **Frontend (`ProductosList.tsx`):**
   - Pestaña **"Sin categoría"** con su conteo exacto de productos (501 productos identificados).
   - Pestañas con insignias de conteo real de productos por categoría.
   - Filtro toggle **"Sin costo cargado"** para localizar de inmediato insumos con `costo IS NULL OR costo <= 0` (190 productos).
   - Etiqueta visible **"Sin costo cargado"** (en badge ámbar, nunca `$0`) para piezas sin costo.
   - Pestaña **"Catálogo del cotizador"** (solo lectura) con subpestañas para Aceros y Opciones:
     - Tabla de Aceros con columnas: Material, Tipo, Dimensiones, Unidad (`tramo` / `placa`), Precio Vigente (mínimo), Proveedor Vigente, IVA incl., Otros Precios / Proveedores y Fuente.
     - Tabla de Opciones con Grupo, Opción, Precio Venta, Costo Referencia (plataforma), Fuente Costo y Escala.
3. **Script de Verificación SQL (`docs/diagnostico/catalogo_conteos.sql`):**
   - Consultas de solo lectura listas para que el usuario o administrador obtenga la radiografía de cantidades y filas en producción.
