# Nota de Diseño Arquitectónico: Editor de Recetas Creadas por el Usuario

- **Documento:** Análisis de viabilidad, arquitectura de datos y diseño para la creación y edición de recetas de modelos desde el sistema.
- **Autor:** Antigravity (Pair Programming / Arquitectura)
- **Fecha:** 2 de noviembre de 2026
- **Contexto:** Tarea T6 de la noche (construye sobre el catálogo de fases y despiece de T2).

---

## 1. Cómo se Define Hoy un Modelo en el Sistema

Actualmente, un modelo configurable en Remolques Leolca se compone de 5 piezas interrelacionadas:

```
                  ┌───────────────────────────────┐
                  │    productos (Terminado)      │
                  │  id: 'REM-PLAT-40-2E'         │
                  └──────────────┬────────────────┘
                                 │ 1:1
                                 ▼
                  ┌───────────────────────────────┐
                  │           modelos             │
                  │  tipo: 'plataforma'           │
                  │  largo_ft: 40, num_ejes: 2    │
                  │  costos_derivados_de: uuid    │
                  └──────┬─────────────────┬──────┘
                         │ 1:N             │ 1:N
        ┌────────────────┘                 └────────────────┐
        ▼                                                   ▼
┌───────────────────────────┐                     ┌───────────────────────────┐
│       receta_base         │                     │  costos_modelo / procesos │
│ material_id -> productos  │                     │  Kits fijos de pintura,   │
│ cantidad, escala, paso    │                     │  tornillería, minutos y   │
│ fase_id -> fases_despiece │                     │  tarifas de mano de obra  │
└───────────────────────────┘                     └───────────────────────────┘
```

1. **`productos` (Producto Terminado):**
   - Todo modelo comercial debe existir primero en la tabla `productos` con `tipo_item = 'producto_terminado'`. Su `id` es la clave comercial (ej. `REM-PLAT-40-2E`, `REM-GOND-30M3-3E`).
2. **`modelos`:**
   - Define los parámetros geométricos y cinemáticos: `tipo` (`'plataforma'`, `'dolly'`, `'gondola'`, `'jaula'`, `'caja_seca'`, `'traila'`), `largo_ft`, `num_ejes`, `producto_id`, `costos_derivados_de` (FK a otro modelo si es variante), y `datos_tecnicos` (JSONB).
3. **`receta_base`:**
   - La lista de materias primas estructurales fijas: `material_id` (FK a `productos`), `cantidad`, `escala` (`'fija'`, `'por_eje'`, `'por_largo'`), `paso`, `seccion` (`'acero'`, `'ensamble'`), `fase_id` (FK a `fases_despiece` introducida en T2) y `condicion` (JSONB con reglas condicionales evaluadas dinámicamente).
4. **`grupos_configuracion` y `opciones_configuracion`:**
   - Cada grupo de opciones (suspensión, rines, llantas, color, frenos) posee un campo `aplica_a TEXT[]` (ej. `['plataforma']` o `['plataforma', 'gondola']`). Cuando el cotizador o el motor evalúa un modelo, filtra automáticamente los grupos donde `grupo.aplica_a.includes(modelo.tipo)`.
5. **`opcion_componentes`:**
   - Componentes que sustituyen o agregan material cuando el cliente selecciona una opción particular en el cotizador (ej. un retráctil grande o rines de aluminio).

---

## 2. Evaluación de Viabilidad: ¿El Motor Permite Resolver un Modelo Nuevo sin Tocar Código?

### 2.1. Análisis del Motor de Resolución (`resolver_receta.ts`)
Al inspeccionar `supabase/functions/make-server-feea4382/motor/resolver_receta.ts`, confirmamos que:
- **No existen nombres de modelo ni IDs hardcodeados.**
- La función recibe `datos: DatosModelo` (cargados dinámicamente de la base de datos por `cargarDatosModelo(supabase, modeloId)`) y `configuracion: Configuracion`.
- La función de escalado `calcularCantidad` es completamente paramétrica:
  ```typescript
  const calcularCantidad = (cantidadBase: number, escala: string): number => {
    if (escala === 'por_eje') {
      return cantidadBase * datos.modelo.num_ejes;
    } else if (escala === 'por_largo') {
      return cantidadBase * (datos.modelo.largo_ft / 40.0);
    }
    return cantidadBase; // fija
  };
  ```
  Si el usuario crea un modelo de 47 pies (`largo_ft = 47`), el factor `(47 / 40.0) = 1.175` se aplica automáticamente a todas las materias primas con `escala = 'por_largo'` (vigas, piso, defensas laterales, etc.).
- Las opciones y reglas de compatibilidad se filtran por `datos.modelo.tipo`. Si el nuevo modelo es de `tipo = 'plataforma'`, heredará instantáneamente todos los grupos configurables de plataforma (suspensión, perno rey, matracas, llantas, rines).

### 2.2. Análisis del Motor de Costeo (`costeo.ts`)
- `costeo.ts` requiere:
  1. `receta_acero` (obtenida de `receta_base` con `seccion = 'acero'`).
  2. `costos_modelo` (kits fijos).
  3. `procesos_manufactura` (tiempos de ensamble).
  4. `ganancia` (obtenida de `parametros_costeo` para el `tipo` del modelo).
- Gracias a la arquitectura de **costos derivados** (`costos_derivados_de`), si un modelo nuevo clona la receta base y apunta a un modelo base existente (o clona sus kits y procesos), `costeo.ts` calcula el costo total sin errores y sin marcar `modelo_sin_costos`.

### 2.3. Limitaciones y Restricciones Detectadas (CHECK Constraints)
- **Restricción de tipo en Postgres:**
  En la tabla `modelos`:
  ```sql
  tipo TEXT NOT NULL CHECK (tipo IN ('plataforma', 'dolly', 'gondola', 'jaula', 'caja_seca', 'traila'))
  ```
  - **Consecuencia:** Un modelo creado por el usuario (ej. "Cama Plana de 47 pies") **debe clasificarse en uno de los 6 tipos canónicos**. En este ejemplo, una cama plana es de tipo `'plataforma'`. No se pueden inventar tipos nuevos (ej. `'tolva'`) sin una migración DDL que modifique el CHECK.
- **Relación obligatoria con `productos`:**
  `modelos.producto_id` tiene una FK estricta `REFERENCES productos(id)`. Por ende, el endpoint de creación de receta debe insertar atómicamente el registro en `productos` (`tipo_item = 'producto_terminado'`) antes de insertar en `modelos`.

### 2.4. ¿A qué se Refiere "Plantillas"?
En el sistema existen dos conceptos:
1. **`plantillas_cotizacion` (Plantillas Comerciales):** Cotizaciones prearmadas que un vendedor guarda para reutilizar (ej. "Plataforma 40ft Estándar con Rines de Aluminio").
2. **Plantillas de Receta (Receta Base de Fabricación):** Las líneas de materiales en `receta_base` que definen la ingeniería de producto.
- Cuando Luis dice: *"que quede disponible para el cotizador y las plantillas"*, se refiere a que:
  - Al crearse el nuevo modelo en `modelos` + `productos`, la pantalla del Cotizador (`CotizacionEditor.tsx`) lo lista en su selector de productos configurables (`SelectorProductos.tsx`).
  - Al cotizar este nuevo modelo, el usuario puede guardarlo como plantilla en `plantillas_cotizacion` para ofrecerlo repetidamente a otros clientes.

---

## 3. Conclusión de Viabilidad: ES COMPLETAMENTE VIABLE

> [!TIP]
> **Dictamen Arquitectónico:** El motor ya está preparado para resolver y costear modelos dinámicos sin tocar una sola línea de código TypeScript en el motor.
> Lo que hacía falta era la **capa operativa**:
> 1. Un endpoint transaccional para **clonar** una receta existente (`receta_base`, kits y procesos) hacia un nuevo modelo con nombre, largo y ejes personalizados.
> 2. Un **editor granular por fases** (`receta_base` ligada a `fases_despiece`) para agregar, quitar o editar cantidades y escalas de materiales.
> 3. Trazabilidad inmutable (`receta_base_historial`) para auditar quién modificó qué insumo y cuándo.
> 4. Garantía de inmutabilidad: Las recetas congeladas en presupuestos (`presupuestos.datos.meta.bom`) y órdenes de trabajo ya emitidas **permanecen intactas**; los cambios en `receta_base` solo aplican a cotizaciones futuras.

---

## 4. Diseño del MVP: "Nueva Receta Desde..." y Editor por Fases

### 4.1. Esquema de Base de Datos (Migración `20261102_04_editor_recetas.sql`)
1. **Auditoría e Historial de Cambios (`receta_base_historial`):**
   - Registra cada alta, modificación o baja de materias primas en la receta.
   - Columnas: `id`, `organizacion_id`, `modelo_id`, `accion` (`'crear_modelo'`, `'agregar_linea'`, `'modificar_linea'`, `'eliminar_linea'`), `material_id`, `fase_id`, `datos_anteriores` (JSONB), `datos_nuevos` (JSONB), `usuario_id`, `motivo`, `created_at`.
2. **Función RPC Atómica (`clonar_receta_modelo`):**
   - Recibe: `p_modelo_origen_id`, `p_producto_id`, `p_nombre`, `p_largo_ft`, `p_num_ejes`.
   - Crea el registro en `productos`.
   - Crea el registro en `modelos` con `costos_derivados_de = p_modelo_origen_id`.
   - Clona todas las filas de `receta_base` asociándolas al nuevo `modelo_id` y preservando su `fase_id`, `escala`, `paso`, `seccion` y `condicion`.
   - Clona `costos_modelo` y `procesos_manufactura`.
   - Registra el evento en `receta_base_historial`.
   - Retorna el nuevo `modelo_id`.

### 4.2. Endpoints REST en Backend Deno (`index.ts` / `motor/recetas_editor.ts`)
- `POST /recetas/clonar`: Ejecuta `clonar_receta_modelo` vía RPC.
- `GET /recetas/:modeloId`: Obtiene información del modelo y sus líneas de receta agrupadas por `fase_id` con detalle del producto.
- `POST /recetas/:modeloId/lineas`: Agrega una materia prima a una fase de la receta.
- `PUT /recetas/:modeloId/lineas/:id`: Actualiza cantidad, escala (`fija`, `por_eje`, `por_largo`), uso o notas.
- `DELETE /recetas/:modeloId/lineas/:id`: Elimina un insumo de la receta.
- `GET /recetas/:modeloId/historial`: Retorna la bitácora cronológica de modificaciones.

### 4.3. Experiencia de Usuario (UI React)
- Integrado en el catálogo de productos/costos (`src/app/components/CatalogoCostos/RecetasEditorMain.tsx`):
  - Botón principal: **"Nueva receta desde..."** (modal para seleccionar modelo base, ingresar nombre, largo en pies y número de ejes).
  - Selector de modelo a editar.
  - Pestañas/Acordeones por las 14 fases oficiales de despiece (Paso 1: Vigas, Paso 2: Chasis, ..., Pintura, Llantas/Rines).
  - Tabla de insumos con edición rápida de cantidad y escala.
  - Búsqueda en vivo de insumos en el catálogo de productos con costo unitario.
  - Pestaña de historial de cambios auditados.
