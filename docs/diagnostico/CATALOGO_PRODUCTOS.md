# Diagnóstico: Por qué "Productos y servicios" no muestra todo el catálogo

**Fecha:** 2026-11-02  
**Autor:** Antigravity (Auditoría Técnica T1)  
**Objetivo:** Explicar con evidencia en el código y las migraciones por qué en la vista de "Productos y servicios" categorías como "Remolques terminados" solo muestran 3 productos, "Refacciones" 2, "Materias primas" 5 y "Acero" 1, a pesar de que el sistema cuenta con cientos de piezas y opciones de cotización.

---

## 1. Hallazgos y Verificación de Hipótesis

### Hipótesis 1: Corte de 1000 filas en PostgREST (`GET /productos`)
- **Veredicto: CONFIRMADA.**
- **Evidencia en código (`supabase/functions/make-server-feea4382/index.ts` l. 1543-1548):**
  ```typescript
  app.get("/productos", async (c) => {
    try {
      const supabase = c.get("supabase") as SupabaseClient;
      const { data, error } = await supabase.from('productos').select('*');
      if (error) throw error;
      return c.json(data);
  ```
  La consulta no especifica `.range()`. El límite predeterminado de PostgREST en Supabase es de 1000 registros por solicitud. Si la tabla `productos` supera las 1000 filas (especialmente tras importar el BOM base y las recetas de plataformas, dollys y góndolas), cualquier registro a partir del índice 1001 se trunca silenciosamente sin advertencia ni paginación hacia el cliente.

### Hipótesis 2: Productos cargados por migración tienen `categoria_id = NULL`
- **Veredicto: CONFIRMADA.**
- **Evidencia en migraciones:**
  En las migraciones históricas donde se compilaron las piezas del BOM (`20261001_03_migracion_bom.sql`, `20261008_01_recetas_plataforma.sql`, `20261011_02_costos_plataforma_40x2.sql`, `20261014_01_dolly.sql`, `20261014_02_gondola.sql`), todas las sentencias de inserción siguen la firma:
  ```sql
  INSERT INTO productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)
  VALUES (...)
  ```
  En ninguna de ellas se suministra `categoria_id`, por lo que su valor por omisión en base de datos es `NULL`.
- **Evidencia en frontend (`src/app/components/Productos/ProductosList.tsx` l. 75-80 y 200-208):**
  La interfaz toma las categorías de la tabla `categorias_producto` (que contiene "Remolques terminados", "Refacciones", "Materias primas", "Acero") y genera una pestaña por categoría.
  Al hacer clic en cualquier pestaña, el filtro aplica:
  ```typescript
  const matchCat = categoriaActiva === 'todas' || producto.categoria_id === categoriaActiva;
  ```
  Como los cientos de productos importados tienen `categoria_id = null`, ninguno coincide con el ID de las categorías. Por tanto:
  1. En las pestañas de categorías solo aparecen los poquísimos productos ingresados manualmente o en seeds iniciales (los 3, 2, 5 y 1 que ve Luis).
  2. No existía pestaña "Sin categoría", por lo que para ver el resto de productos el usuario estaba forzado a permanecer en "Todas".

### Hipótesis 3: La información del cotizador vive en tablas separadas, no en `productos`
- **Veredicto: CONFIRMADA.**
- **Evidencia en arquitectura:**
  El cotizador y catálogo de costos operan con un modelo relacional desacoplado:
  1. **Acero:** La lista de vigas, canales, ángulos, soleras y placas reside en la tabla `acero_materiales` (creada en `20261027_01_acero_precios.sql`) con sus precios por kilo/pieza en `acero_precios`.
  2. **Opciones de configuración:** Suspensiones, ejes, patines, retráctiles, rines, llantas, pintura, pisos y aditamentos residen en `opciones_configuracion`, con costos por modelo en `opcion_costos` y despiece en `opcion_componentes`.
  Salvo que una opción tenga explícitamente asignado un `producto_id`, estas opciones no existen como registros en `productos`. Por ello, aunque tengan precios y costos plenamente funcionales en el cotizador, jamás aparecían en la pantalla de "Productos y servicios".

---

## 2. Solución Implementada en T1

1. **Backend (`/productos`):**
   - Soporte de paginación completa en `GET /productos` mediante `.range()` recursivo/por lotes para superar el tope de 1000 filas de PostgREST y garantizar que no se pierdan productos en solicitudes completas.
   - Parámetros de consulta opcionales `?page&limit&q&categoria&sin_costo=1` para búsquedas eficientes.
   - Retorno retrocompatible (mantiene formato de array o `{ productos, total, truncado }` según solicitud del cliente).
   - Nuevo endpoint de solo lectura `GET /catalogo-cotizador` que expone los aceros de `acero_materiales` y las opciones de `opciones_configuracion` con sus costos y precios sin duplicar datos en `productos`.
2. **Frontend (`ProductosList.tsx`):**
   - Pestaña **"Sin categoría"** con su conteo exacto de productos.
   - Pestañas con insignias de conteo real de productos por categoría.
   - Filtro toggle **"Sin costo cargado"** para localizar de inmediato insumos con `costo IS NULL OR costo = 0`.
   - Etiqueta visible **"Sin costo cargado"** (en badge ámbar, nunca `$0`) para piezas sin costo.
   - Pestaña **"Catálogo del cotizador"** (solo lectura) que despliega aceros y opciones configurables con su precio, tipo y procedencia.
3. **Script de Verificación SQL (`docs/diagnostico/catalogo_conteos.sql`):**
   - Consultas de solo lectura listas para que el usuario o administrador obtenga la radiografía de cantidades y filas en producción.
