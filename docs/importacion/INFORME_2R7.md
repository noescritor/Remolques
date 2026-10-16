# Informe de Implementación — Sub-bloque 2R-7: Catálogo de Costos Administrable

Fecha: 2026-10-15  
Rama: `bloque-2r-7`  
Migración generada: `supabase/migrations/20261016_01_catalogo_costos.sql`  
Script generador: `scripts/generar_catalogo_costos_sql.cjs`  
Verificación SQL: `docs/importacion/verificacion_2R7.sql`

---

## 1. Resumen Ejecutivo

El sub-bloque **2R-7** implementa la infraestructura completa para administrar y visualizar los costos del cotizador desde una interfaz de usuario integrada con control de permisos y auditoría de cambios:
1. **Migración e Integración con Productos:** Agrega las columnas `producto_id` y `costo_desde_producto` a `opcion_costos`, crea la tabla `costos_historial` con políticas RLS basadas en organización, y liga inicialmente las 8 opciones de llantas a sus productos de materia prima correspondientes sin alterar costos vigentes.
2. **Motor de Costeo:** Habilita el cálculo dinámico basado en productos cuando `costo_desde_producto = true` (reportando pendiente `sin_precio` si el producto carece de costo), y actualiza la regla de `costo_no_factura` para marcar exclusivamente fuentes `Tarifario` y `Supuesto…` (permitiendo que fuentes confirmadas como `Manual…`, `Producto` o `Factura…` no generen pendientes). Las 4 pruebas doradas de costeo continúan pasando sin ninguna alteración.
3. **API con Control de Permisos y Trazabilidad:** Módulo `motor/catalogo_costos.ts` con cliente inyectable y endpoints REST protegidos: lectura abierta a cualquier miembro de la organización, escritura restringida estrictamente a roles `propietario` o `admin` (consultados mediante el cliente de servicio en `perfiles_organizacion`), generando un registro de historial por cada campo editado.
4. **Pantalla "Catálogo de Costos":** Módulo UI completo con 5 pestañas (Opciones, Kits y Mano de Obra, Utilidad, Cobertura, Historial), soporte de modo claro/oscuro con variables semánticas Tailwind, modo de solo lectura para usuarios sin privilegios administrativos, confirmación antes de guardar y lógica desacoplada en `src/app/utils/catalogoCostos.ts`.

---

## 2. Componentes Creados y Modificados

### A. Migración de Base de Datos
- **Archivo:** `supabase/migrations/20261016_01_catalogo_costos.sql`
- **Generador:** `scripts/generar_catalogo_costos_sql.cjs`
- **Estructura:**
  - `ALTER TABLE opcion_costos ADD COLUMN IF NOT EXISTS producto_id text REFERENCES productos(id) ON DELETE SET NULL;`
  - `ALTER TABLE opcion_costos ADD COLUMN IF NOT EXISTS costo_desde_producto boolean NOT NULL DEFAULT false;`
  - Índice `idx_opcion_costos_producto_id` en `opcion_costos(producto_id)`.
  - `CREATE TABLE IF NOT EXISTS costos_historial`: almacena `(id, organizacion_id, tabla, registro_id, concepto, campo, valor_anterior, valor_nuevo, usuario_id, creado_en)`.
  - RLS activado en `costos_historial` con política `org_costos_historial_policy` (`organizacion_id = get_current_org_id()`).
  - Índice compuesto `idx_costos_historial_org_creado` en `(organizacion_id, creado_en DESC)`.
  - Bloque transaccional idempotente para enlazar las opciones de llantas.

### B. Ligas Iniciales Opción ↔ Producto
Para las 8 opciones del grupo `llantas`, se realizó la búsqueda exacta (case-insensitive) contra productos de `materia_prima`:
- `cerex` → `LLANTAS CEREX`
- `bf_goodrich` → `LLANTAS BF GOODRICH`
- `eudemon` → `LLANTAS EUDEMON`
- `amulet` → `LLANTAS AMULET`
- `chinas` → `LLANTAS CHINAS`
- `royal_black` → `LLANTAS ROYAL BLACK`
- `valiant` → `LLANTAS VALIANT`
- `firestone` → `LLANTAS FIRESTONE`

**Estado de Ligas por Tipo de Modelo:**
- **Plataforma:** 8 de 8 opciones ligadas con éxito.
- **Dolly:** 8 de 8 opciones ligadas con éxito.
- **Góndola:** 8 de 8 opciones ligadas con éxito.
- **Total ligas creadas:** 24 filas actualizadas con su respectivo `producto_id`.
- **Ligas omitidas o ambiguas:** 0 en el grupo de llantas. Todos los 8 productos existen de manera unívoca en la base de datos de productos.
- **Preservación de Costos:** En todas las filas `costo_desde_producto` permanece en `false`, garantizando que la migración no altera ningún número de costeo existente.

### C. Ajustes al Motor de Costeo
- **Archivos:**
  - `supabase/functions/make-server-feea4382/motor/tipos.ts`: Incorporación de `producto_id`, `costo_desde_producto` y `producto_costo` en `OpcionCostoRow`.
  - `supabase/functions/make-server-feea4382/motor/cargar_costos.ts`: Embed de `productos(costo)` en la consulta de `opcion_costos`.
  - `supabase/functions/make-server-feea4382/motor/costeo.ts`:
    * Resolución de costo unitario: si `costo_desde_producto = true` y existe costo positivo de producto, se adopta dicho costo. Si el costo del producto es 0 o nulo, se genera un pendiente `sin_precio` indicando el concepto y la línea suma 0.
    * Regla de `costo_no_factura`: Se modificó el filtro para evaluar estrictamente `fuente.startsWith('Tarifario') || fuente.startsWith('Supuesto')`. Las opciones con fuentes `Factura...`, `Producto` o `Manual...` ya no generan alerta de costo pendiente.
  - `supabase/functions/make-server-feea4382/motor/costeo.test.ts`: Se agregaron 3 pruebas unitarias específicas para 2R-7 que validan el enlace dinámico a productos, la detección de producto sin precio, y la exclusión de pendientes para `Manual` y `Producto`. Las 4 pruebas doradas continúan pasando sin modificaciones.

### D. API REST y Endpoints Hono
- **Módulo:** `supabase/functions/make-server-feea4382/motor/catalogo_costos.ts`
- **Rutas en `index.ts`:**
  - `GET /catalogo-costos/resumen`: Retorna opciones agrupadas con métricas de recetas y opciones activas sin costo.
  - `PUT /catalogo-costos/opciones/:opcionId`: Actualización de costo unitario, cantidad base, escala y liga a producto; actualiza fuente a `Manual (usuario)` o `Producto` y registra historial por campo.
  - `GET /catalogo-costos/modelos/:modeloId`: Desglose de `costos_modelo` y `procesos_manufactura` con totales.
  - `PUT /catalogo-costos/modelos/:modeloId/kits/:id`: Edición de insumos fijos con auditoría.
  - `PUT /catalogo-costos/procesos/:id`: Edición de minutos y tarifa por hora de procesos.
  - `GET /catalogo-costos/parametros`: Consulta de ganancias por factura y margen sugerido.
  - `PUT /catalogo-costos/parametros`: Actualización de ganancias de factura con auditoría.
  - `GET /catalogo-costos/historial`: Consulta de los 100 movimientos más recientes.
- **Seguridad:** Verificación de rol en `perfiles_organizacion`. Si el usuario no tiene rol `propietario` o `admin`, los métodos PUT devuelven `403 Forbidden { error: 'No tienes permiso para editar costos' }`.
- **Pruebas:** `supabase/functions/make-server-feea4382/motor/catalogo_costos.test.ts` con 7 pruebas que validan el bloqueo 403, validación de inputs, confirmación de costo sin cambio de montos, aislamiento entre tipos de modelo y registro granular en historial.

### E. Frontend y Navegación
- **Componente Principal:** `src/app/components/CatalogoCostos/CatalogoCostosMain.tsx`
- **Utilidades:** `src/app/utils/catalogoCostos.ts` (con pruebas en `src/app/utils/catalogoCostos.test.ts`).
- **Navegación:**
  - Integrado en `src/app/components/ModernLayout.tsx` bajo la sección Catálogo ("Catálogo de Costos", ícono `Coins`).
  - Integrado en `src/app/components/Layout.tsx` en el submenú de Catálogo.
  - Ruta declarada en `src/app/App.tsx` (`/catalogo-costos`).

---

## 3. Verificación de Integridad de Costos (Comparativa 2R-1g vs 2R-7)

La migración 2R-7 no modifica ningún costo unitario existente ni activa `costo_desde_producto`:

| Tipo de Modelo | Filas en `opcion_costos` | Suma de `costo_unitario` | Suma Total Ponderada (`cu * cant`) | Llantas Ligadas |
|---|---:|---:|---:|---:|
| **Plataforma** | 82 | $986,902.50 | $1,178,502.78 | 8 / 8 |
| **Dolly** | 51 | $305,383.50 | $464,059.50 | 8 / 8 |
| **Góndola** | 67 | $1,077,541.76 | $1,265,760.64 | 8 / 8 |
| **Total General** | **200** | **$2,369,827.76** | **$2,908,322.92** | **24 / 24** |

---

## 4. Pruebas Automatizadas

El conjunto completo de pruebas del proyecto fue ejecutado exitosamente:
- **Pruebas Deno:** 84 pruebas ejecutadas (superando ampliamente la base previa de 73).
  - `motor/costeo.test.ts`: 23 pruebas pasadas.
  - `motor/catalogo_costos.test.ts`: 7 pruebas pasadas.
  - `src/app/utils/catalogoCostos.test.ts`: 4 pruebas pasadas.
  - Pruebas previas de motor y presupuesto: 50 pruebas pasadas.
- **TypeScript `tsc --noEmit`:** 53 advertencias preexistentes conservadas; 0 errores nuevos introducidos.
- **Compilación Vite:** Compilación exitosa para producción sin errores de sintaxis JSX ni escapes inválidos.

---

## 5. Lo que NO se Probó en este Entorno

Conforme a las reglas de seguridad y alcance:
1. **Base de Datos de Producción:** No se corrió la migración `20261016_01_catalogo_costos.sql` ni se ejecutó ninguna sentencia SQL contra la base de datos de producción de Supabase.
2. **Servicio Backend en EasyPanel:** No se desplegó ni se probó la comunicación HTTP en vivo contra el contenedor de Deno en EasyPanel (se probó mediante el harness local de Deno y clientes simulados).
3. **Renderizado en Navegador:** No se interactuó con la interfaz mediante un navegador real montado (la pantalla fue validada mediante TypeScript, Vite build y pruebas unitarias de utilidades).
