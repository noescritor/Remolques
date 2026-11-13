# Reporte Técnico — Tablero de Producción (Bloque 1 de 2: Datos y Backend)

**Fecha:** 2026-11-12  
**Herramienta:** Antigravity (Google DeepMind)  
**Rama:** `tablero-produccion-b1-2026-11-12`  
**Worktree:** `..\Remolques_tablero_b1`  
**Base de partida:** `main` (`efa48f8`)  
**Revisión:** Claude (sin merge ni push a `main`, sin tocar EasyPanel ni Supabase producción)

---

## 1. Resumen Ejecutivo

Se implementó de manera completa e integral el **Bloque 1 de 2: Datos y Backend** del Tablero de Producción (estado por fase), respondiendo a la necesidad de Armadora Leolca de digitalizar la matriz de control de planta (originalmente en Excel `PLATAFORMAS 09-11-2026.xlsx`) con soporte para 4 líneas de producto, 55 fases canónicas, subprocesos como ensamble de tina en góndolas, cálculo automático de semáforos de cumplimiento, creación manual de órdenes de inventario sin cotización, y recálculo reactivo mediante triggers y RPC en PostgreSQL.

Todo el desarrollo se validó contra un Postgres 17 local desechable (`anty_test_tablero_b1`) en el puerto 54331, superando 2 pasadas consecutivas de la migración con `ON_ERROR_STOP=1`, los 10/10 checks de `verificacion_tablero.sql` (`todo_ok = true`), una suite de 10 pruebas transaccionales de concurrencia y aislamiento, 326 pruebas unitarias de Deno (cero fallas), y el checklist integral `node scripts/verificar.mjs --limpio` reportando **11/11 comprobaciones en verde**.

---

## 2. Base de Datos y Migración (`20261112_01_tablero_orden_fases.sql`)

La migración es **estrictamente idempotente** y contempla:

1. **Líneas de Producto (`lineas_producto`)**:
   - Ajuste de unicidad: la restricción única pasó de ser global a `(organizacion_id, clave)`.
   - Soporte para las 4 líneas canónicas: `plataforma`, `gondola`, `dolly`, `traila`.

2. **Fases de Producción (`fases_produccion`)**:
   - Nuevas columnas: `grupo` (`'principal'` | `'tina'`), `duracion_dias` (1..60, default 2), `requiere_grupo` (apunta al subproceso requerido, ej. `'tina'` en Montado de tina), `activo` (default true).
   - Clave única `(linea_producto_id, grupo, orden)`.

3. **Matriz de Fases por Orden (`orden_fases`)**:
   - Nueva tabla de vínculo `(orden_trabajo_id, fase_id)` con estados: `'pendiente'`, `'en_proceso'`, `'incompleta'`, `'pausada'`, `'terminada'`.
   - Control temporal: `fecha_inicio`, `fecha_fin`, `fecha_propuesta`, `nota`.
   - Políticas RLS activas (`SELECT` para usuarios autenticados de su misma organización).

4. **Órdenes de Trabajo (`ordenes_trabajo`)**:
   - Columnas nuevas: `fecha_compromiso`, `etiqueta`, `origen` (`'cotizacion'` | `'manual'`).
   - Null-safety en BD: `cotizacion_id` y `cliente_id` ahora son anulables con restricción CHECK que exige `cliente_id IS NOT NULL OR (etiqueta IS NOT NULL AND trim(etiqueta) <> '')`.

5. **Historial de Fases (`historial_fases`)**:
   - Ampliado con `estado_anterior`, `fecha_propuesta`, `nota`, `usuario_id`.

6. **Semilla Idempotente (`sembrar_tablero_produccion(p_org uuid)`)**:
   - Siembra exactamente las 4 líneas y 55 fases oficiales:
     - **Plataforma (12)**: 1 Corte, 2 Dispositivo, 3 Armado de baras, 4 IPR, 5 Perchas, 6 Acabado y extras, 7 Escoreado y lavado, 8 Primer, 9 Pintura, 10 Luz, 11 Aire, 12 Piso.
     - **Góndola Principal (12)**: 1 Corte, 2 Dispositivo, 3 Armado de baras, 4 Jalón y cajones para tina, 5 Suspensión, ejes y patines, 6 Acabados, 7 Montado de tina (`requiere_grupo = 'tina'`), 8 Escoreado y lavado, 9 Primer, 10 Pintura, 11 Aire, 12 Luz.
     - **Góndola Tina (10)**: 1 Piso y vueltas laterales, 2 Cuellos y placas superiores, 3 Ensamble de HSS principal, 4 Ensamble de frente y HSS lateral, 5 Ensamble de porterías, 6 Complementos, 7 Resoldado externo, 8 Resoldado interno, 9 Ensamble de puerta y plafonera, 10 Terminados.
     - **Dolly (10)**: 1 Armado de puentes, 2 Armado de cuadro, 3 Perchas y platos, 4 Portaloderas y lanza, 5 Retráctil y ejes, 6 Escoreado y lavado, 7 Primer, 8 Pintura, 9 Luz, 10 Aire.
     - **Traila (11)**: 1 Armado de cuadro, 2 Ensamble de travesaños, 3 Ensamble de ejes, 4 Ensamble de pasamanos, 5 Ensamble de lanza, 6 Puerta o tapa, 7 Acabados, 8 Primer, 9 Pintura, 10 Luz, 11 Piso.
   - **Preservación**: `ON CONFLICT DO UPDATE` no pisa `duracion_dias` si ya fue modificado por el usuario.

7. **Trigger Reactivo (`trg_recalcular_orden_fases`)**:
   - Recalcula de inmediato en `ordenes_trabajo`:
     - `estado_kanban`: `completada` si todas las fases terminaron; si no, por precedencia estricta `incompleta` > `pausada` > `en_proceso` > `pendiente`.
     - `fase_actual_id`: la primera fase principal (por orden) en proceso, incompleta o pausada (o `NULL` si ninguna o todas terminadas).
     - `estado`: preserva `'Liberado'` inmutable; si no, `'Terminado'` al finalizar todas las fases, `'En Producción'` al iniciar la primera, y `'Pendiente'` si no ha iniciado ninguna.
     - `fecha_inicio`: mínima de inicio de sus fases; `fecha_fin`: timestamp de término (se limpia automáticamente si se reabre una fase).

8. **RPC Transaccional (`actualizar_fase_orden`)**:
   - `SECURITY DEFINER`, search_path fijo.
   - `SELECT FOR UPDATE` sobre la orden para evitar colisiones entre usuarios concurrentes.
   - Reglas de transición: cálculo automático de propuesta a fecha local de México (`America/Mexico_City`), limpieza de fechas al volver a `pendiente`, registro selectivo en historial solo si hubo cambios.
   - Retorno de avisos no bloqueantes: si fase 7 Montado de tina se termina con la tina incompleta, devuelve `"La tina va 8/10"`.

9. **Backfill Idempotente de Órdenes Existentes**:
   - Asigna línea por `tipo_equipo` a órdenes existentes, crea sus `orden_fases` correspondientes y sincroniza `fase_actual_id` a `en_proceso` sin inventar fases terminadas.

---

## 3. Funciones Puras y Utilidades (`src/app/utils/tableroProduccion.ts`)

- `MAPA_TIPO_EQUIPO_LINEA` y `obtenerLineaPorTipoEquipo`:
  - 01, 04 (jaula), 05 (cama baja), 06 (multimodal), 07 (portacontenedor), 08 (caja seca) $\rightarrow$ `plataforma`
  - 02 $\rightarrow$ `dolly`
  - 03 $\rightarrow$ `gondola`
  - 09 $\rightarrow$ `traila`
  - Fallbacks por texto libre (`"Dolly H"`, `"Góndola 30m3"`, `"Traila ganadera"`).
- `calcularSemaforo(celdas, hoy)`:
  - Precedencia estricta: `terminado` > `por_iniciar` > `atrasado` > `detenido` > `en_tiempo`.
  - Zona horaria: `America/Mexico_City`.
- `calcularEtiquetaVisible(orden, grupoMismoClienteYLinea)`:
  - Etiqueta manual gana siempre si existe.
  - Si un cliente tiene 1 orden en la línea $\rightarrow$ `"{cliente}"`.
  - Si tiene $>1$ órdenes en la misma línea $\rightarrow$ `"{cliente} #{n}"` ordenadas determinísticamente por `created_at ASC` (ej. Saul Salas #1, #2, #3).
- **Pruebas Deno**: `src/app/utils/tableroProduccion.test.ts` (100% pasando).

---

## 4. Motor Backend (`motor/tablero_produccion.ts` y `generar_ordenes_cotizacion.ts`)

- `obtenerMatrizProduccion`:
  - Ensambla en una sola llamada eficiente la línea, fases activas (ordenadas: principal 1..N, tina 1..N), filas de órdenes no liberadas con semáforo, avance principal, avance de tina (si aplica) y celdas indexadas.
  - Orden por defecto: **menos avanzado primero** (menor porcentaje de avance global), desempate por `created_at ASC`.
  - Resumen global en tiempo real: `en_planta`, `atrasados`, `con_material`, `con_pausa`, `wip_por_fase`.
- `crearOrdenManualMotor`:
  - Valida exigencia de `cliente_id` o `etiqueta`.
  - Genera nomenclatura única mediante `obtener_siguiente_produccion` con iniciales `INV` si es para stock/inventario o las iniciales del cliente.
  - Origen `'manual'`, `cotizacion_id = null`.
  - Invoca `crear_fases_orden` de inmediato.
- `actualizarFaseMotor`: invoca la RPC `actualizar_fase_orden` mapeando excepciones a HTTP 400, 404 o 409.
- `actualizarPlaneacionMotor`: lista blanca estricta (`fecha_compromiso`, `etiqueta`, `material_faltante`). Rechaza cualquier campo ajeno con HTTP 400.
- `obtenerHistorialOrdenMotor`: consulta `historial_fases` enriqueciendo nombres de usuario y fases.
- `moverOrdenMotor`: reimplementado sobre `actualizar_fase_orden`. Mover a fase la pasa a `en_proceso`; mover a `pendientes` responde 400.
- `generar_ordenes_cotizacion.ts`:
  - Corregido para mapear la línea canónica por `tipo_equipo` (en vez de `lineas[0]`).
  - Columnas correctas (`linea_producto_id`).
  - Las órdenes nacen con `fase_actual_id = null`, `estado_kanban = 'pendiente'`, `estado = 'Pendiente'`.
  - Invoca `crear_fases_orden` para cada orden generada.
- **Pruebas Deno**: `supabase/functions/make-server-feea4382/motor/tablero_produccion.test.ts` (8 pruebas exhaustivas pasando).

---

## 5. Endpoints y Dockerfile.backend (`index.ts`, `Dockerfile.backend`)

En `supabase/functions/make-server-feea4382/index.ts`:
1. `GET /produccion/matriz`
2. `POST /produccion/ordenes` (201 Created)
3. `PUT /produccion/ordenes/:id/fases/:faseId`
4. `PUT /produccion/ordenes/:id/planeacion`
5. `PUT /produccion/ordenes/:id/material` (alias retrocompatible)
6. `GET /produccion/ordenes/:id/historial`
7. `PUT /produccion/ordenes/:id/mover`
8. `POST /produccion/sembrar` (permiso admin/propietario)
9. **Eliminado**: Esqueleto muerto de `POST /produccion/import`.

En `Dockerfile.backend`:
- Se agregó `COPY src/app/utils/tableroProduccion.ts ./src/app/utils/tableroProduccion.ts` para garantizar que la imagen de Docker en EasyPanel compile y ejecute `deno cache index.ts` sin depender de rutas externas.

---

## 6. Null-Safety de Órdenes Manuales en el Frontend

Para asegurar que órdenes sin cotización o sin cliente no provoquen errores en tiempo de ejecución:
- `src/app/types/index.ts`: `OrdenTrabajo` actualizado con `cotizacion_id?: string | null`, `cliente_id?: string | null`, `etiqueta?: string | null`, `origen?: 'cotizacion' | 'manual'`, `fecha_compromiso?: string | null`. Agregados tipos `OrdenFase`, `MatrizProduccion`, `FilaMatriz`, `CeldaFase`, `ResumenMatriz`, `SemaforoProduccion`.
- `OrdenesTrabajoList.tsx`: Búsqueda y listado seguro con `orden.cotizacion?.descripcion || 'Manual'` y `orden.cliente?.nombre || orden.etiqueta || 'Inventario'`.
- `OrdenTrabajoPDF.tsx`: Detección de órdenes manuales sin cotización, mensaje contextual claro y desactivación de regeneración sin cotización.
- `LiberacionPDF.tsx`: Nombre del cliente seguro con fallback a etiqueta o `'CLIENTE'`.
- `ChecklistDespieceModal.tsx`: Visualización de cliente con fallback a etiqueta o `'Inventario'`.
- `OrderCard.tsx`: Folio seguro (`cotizacion?.folio || nomenclatura_id || 'Manual'`) y cliente (`cliente?.nombre || etiqueta || 'Inventario'`).
- `TableroProduccionPage.tsx`: Búsqueda segura combinando cliente, etiqueta, folio y nomenclatura.

---

## 7. Contrato de API para el Bloque 2 (`docs/tablero/CONTRATO_API_MATRIZ.md`)

Se documentaron todos los endpoints con ejemplos reales de JSON para request y response (casos con y sin cliente, góndolas con subproceso de tina, avisos no bloqueantes, errores 400/404/409 y sembrado de líneas).

---

## 8. Verificación y Resultados

### Comprobaciones `scripts/verificar.mjs --limpio`
```text
== 1. Archivos de parche o temporales nuevos
  OK     Sin parches ni temporales

== 2. Codificación de los archivos modificados
  OK     UTF-8 sin BOM ni mojibake — 19 archivos revisados

== 3. Sintaxis de .ts/.tsx modificados
  OK     Sintaxis válida

== 4. TypeScript (tsc --noEmit)
  OK     tsc: 0 nombres sin definir/duplicados
  OK     tsc: el total de errores no sube — 45 (baseline 55)

== 5. Build de Vite
  OK     npm run build

== 6. Pruebas Deno
  OK     Pruebas Deno — 326 pasan, 0 fallan

== 7. Arranque real del API
  OK     El API arranca — Listening on http://localhost:8000/

== 8. Contexto del Dockerfile.backend
  OK     Contexto del Dockerfile.backend — deno cache index.ts exitoso

== 9. Checkout limpio de HEAD (git archive)
  OK     Pruebas Deno en HEAD limpio — 326 pasan, 0 fallan
  OK     El API arranca en HEAD limpio — Listening on http://localhost:8000/

============================================================
RESULTADO: TODO OK  (11/11 comprobaciones)
```

---

## 13. Acciones Manuales para Luis (Producción)

Cuando esta rama sea revisada y aprobada por Claude:
1. **Ejecutar la migración SQL**:
   Copiar y pegar el contenido de `COORDINACION/SQL_PARA_LUIS/20261112_01_tablero_orden_fases.sql` en el SQL Editor de Supabase (producción).
2. **Ejecutar la verificación SQL**:
   Copiar y pegar el contenido de `COORDINACION/SQL_PARA_LUIS/verificacion_tablero.sql` y `COORDINACION/SQL_PARA_LUIS/prueba_roles.sql` en el SQL Editor de Supabase y verificar que retornen `todo_ok = true`.
3. **Rebuild del Backend**:
   En EasyPanel, entrar al servicio `remolques-api` y presionar **"Rebuild"**.
4. **Rebuild del Frontend**:
   En EasyPanel, entrar al servicio `remolques-web` y presionar **"Rebuild"**.

### Verificación SQL en Postgres 17 (`docs/tablero/verificacion_tablero.sql`)
Todos los 10 checks booleanos arrojaron `t` y `todo_ok = true`:
```text
 check_lineas_canonica               | t
 check_fases_totales                 | t
 check_tabla_orden_fases             | t
 check_columnas_ordenes_trabajo      | t
 check_columnas_historial_fases      | t
 check_rpc_actualizar_fase           | t
 check_rpc_crear_fases               | t
 check_trigger_recalcular            | t
 check_ordenes_manuales_null_safety  | t
 check_fases_activas_coherencia      | t
 todo_ok                             | t
```

---

## 9. `git diff main --stat`

```text
 COORDINACION/SQL_PARA_LUIS/20261112_01_tablero_orden_fases.sql | 720 +++++++++++++++++++++
 COORDINACION/SQL_PARA_LUIS/verificacion_tablero.sql             | 153 +++++
 Dockerfile.backend                                             |   1 +
 docs/tablero/CONTRATO_API_MATRIZ.md                            | 360 +++++++++++
 docs/tablero/verificacion_tablero.sql                          | 153 +++++
 src/app/components/OrdenesTrabajo/ChecklistDespieceModal.tsx  |   4 +-
 src/app/components/OrdenesTrabajo/LiberacionPDF.tsx            |   3 +-
 src/app/components/OrdenesTrabajo/OrdenTrabajoPDF.tsx          |  12 +-
 src/app/components/OrdenesTrabajo/OrdenesTrabajoList.tsx      |  11 +-
 src/app/components/TableroProduccion/OrderCard.tsx             |   4 +-
 src/app/components/TableroProduccion/TableroProduccionPage.tsx|  14 +-
 src/app/types/index.ts                                         |  86 ++-
 src/app/utils/tableroProduccion.test.ts                        | 146 +++++
 src/app/utils/tableroProduccion.ts                             | 167 +++++
 supabase/functions/make-server-feea4382/index.ts               | 195 ++++--
 .../motor/generar_ordenes_cotizacion.ts                        |  54 +-
 .../motor/tablero_produccion.test.ts                           | 494 ++++++++++++++
 .../motor/tablero_produccion.ts                                | 667 +++++++++++++++++++
 supabase/migrations/20261112_01_tablero_orden_fases.sql         | 720 +++++++++++++++++++++
 19 files changed, 3879 insertions(+), 85 deletions(-)
```

---

## 11. Ronda 2: Correcciones y Pruebas Reales contra la Base de Datos

En respuesta a la revisión técnica de Claude (`COORDINACION/REVISIONES/TABLERO_B1_REVISION_CLAUDE.md`), se aplicaron y validaron las siguientes correcciones en la base real Postgres 17 (puerto 54331):

### 1. Cliente `service_role` para RPCs (Hallazgo 1 [ALTA])
- En `index.ts`, las rutas `/produccion/matriz`, `/produccion/ordenes`, `/produccion/ordenes/:id/fases/:faseId`, `/produccion/ordenes/:id/mover` y `/produccion/sembrar` ahora obtienen e inyectan `serviceClient = getServiceClient()`.
- En `motor/tablero_produccion.ts`, las funciones `actualizarFaseMotor`, `crearOrdenManualMotor`, `moverOrdenMotor`, `sembrarTableroMotor` y la siembra perezosa de `obtenerMatrizProduccion` ejecutan sus llamadas `.rpc()` exclusivamente a través de `serviceClient || supabase`, verificando el error de retorno y arrojando una excepción clara si falla.

### 2. Columnas Existentes en `clientes` (Hallazgo 2 [ALTA])
- `obtenerMatrizProduccion` selecciona `cliente:clientes(id, nombre_razon_social, nombre_contacto)`.
- `crearOrdenManualMotor` consulta `nombre_razon_social` y `nombre_contacto` para derivar las iniciales de la nomenclatura cuando la orden manual tiene un cliente asignado.

### 3. Historial de Fases por `fecha_cambio` (Hallazgo 3 [ALTA])
- `obtenerHistorialOrdenMotor` consulta y ordena por `fecha_cambio DESC` en `historial_fases`.
- Devuelve en el contrato JSON `fecha_cambio` y su alias retrocompatible `created_at`.
- El campo `usuario` devuelve el `usuario_id` (o `'Sistema'` si es nulo), con la aclaración respectiva en el contrato de API.

### 4. Respaldo de Migración y Conservación de Órdenes Existentes (Hallazgo 4 [ALTA])
- **Bypass de Trigger**: En `fn_recalcular_orden_trabajo()`, se añadió salida inmediata `IF current_setting('app.tablero_respaldo', true) = 'on' THEN RETURN NULL; END IF;`.
- **Mapeo Previo a la Eliminación**: En la sección 10 de la migración, se leen `fase_actual_id` y su `orden` previo a modificar líneas; se crea `crear_fases_orden` y se mapea la fase a la nueva línea canónica en `en_proceso` con propuesta `hoy + duracion`.
- **Preservación Estricta**: Las órdenes en `En Producción`, `Terminado` y `Liberado` conservan sus estados, fechas (`fecha_inicio`, `fecha_fin`) y fases activas sin ser degradadas a `Pendiente`.
- **Limpieza Segura**: El `DELETE FROM lineas_producto` se acotó únicamente a líneas sin órdenes asociadas (`AND id NOT IN (SELECT DISTINCT linea_producto_id FROM ordenes_trabajo WHERE linea_producto_id IS NOT NULL)`), emitiendo `RAISE NOTICE 'Líneas antiguas sin órdenes eliminadas: %'`.

### 5. Numeración de Cliente Estable `#n` (Hallazgo 5 [MEDIA])
- `obtenerMatrizProduccion` consulta todas las órdenes de la línea (incluidas las que ya están en estado `Liberado`) para calcular la posición ordinal del cliente `#n`. Liberar la unidad #1 ya no renumera la unidad #2.

### 6. Recálculo al Reabrir Fase Terminada (Hallazgo 6 [MEDIA])
- En `actualizar_fase_orden()`, si una fase estaba en estado `terminada` y se pasa a `en_proceso` sin enviar una nueva fecha propuesta explícita (`p_fecha_propuesta IS NULL`), se recalcula automáticamente como `(timezone('America/Mexico_City', now())::date + duracion_dias)`.

### 7. No reactivación de fases en DO UPDATE (Hallazgo 7 [BAJA])
- Se removió `activo = EXCLUDED.activo` en los 5 bloques `ON CONFLICT` de `sembrar_tablero_produccion`.

### 8. Sanitización de PUT en Órdenes de Trabajo (Hallazgo 8 [BAJA])
- Se removieron `estado_kanban` y `fase_actual_id` de `CAMPOS_PERMITIDOS_ORDEN_TRABAJO` en `generar_ordenes_cotizacion.ts`. Se aseguraron verificaciones de error en llamadas RPC.

---

## 12. Resultados de Pruebas de la Ronda 2

### Prueba de Roles y Contratos en Postgres 17 (`docs/tablero/prueba_roles.sql`)
Ejecutada contra la base local desechable (`anty_test_tablero_b1`, puerto 54331):
```text
          check_name           | resultado |                                                detalle                                                 
-------------------------------+-----------+--------------------------------------------------------------------------------------------------------
 lecturas_authenticated        | t         | Todas las consultas de la matriz e historial ejecutaron correctamente como authenticated
 rpcs_bloqueadas_authenticated | t         | Las 3 RPCs (sembrar, crear_fases, actualizar_fase) arrojaron insufficient_privilege como authenticated
 respaldo_preserva_estados     | t         | El respaldo preserva estado, fecha_inicio, fecha_fin y fase_actual_id
 reapertura_recalcula_fecha    | t         | Reapertura calculó fecha propuesta: 2026-11-14 (esperada hoy+2 días = 2026-11-14)

 lecturas_authenticated_ok | rpcs_service_role_only_ok | respaldo_preserva_estados_ok | reapertura_recalcula_fecha_ok | todo_ok 
---------------------------+---------------------------+------------------------------+-------------------------------+---------
 t                         | t                         | t                            | t                             | t
```

### Verificación Integral `node scripts/verificar.mjs --limpio`
```text
== 1. Archivos de parche o temporales nuevos
  OK     Sin parches ni temporales

== 2. Codificación de los archivos modificados
  OK     UTF-8 sin BOM ni mojibake — 22 archivos revisados

== 3. Sintaxis de .ts/.tsx modificados
  OK     Sintaxis válida

== 4. TypeScript (tsc --noEmit)
  OK     tsc: 0 nombres sin definir/duplicados
  OK     tsc: el total de errores no sube — 45 (baseline 55)

== 5. Build de Vite
  OK     npm run build

== 6. Pruebas Deno
  OK     Pruebas Deno — 328 pasan, 0 fallan

== 7. Arranque real del API
  OK     El API arranca — Listening on http://localhost:8000/

== 8. Contexto del Dockerfile.backend
  OK     Contexto del Dockerfile.backend — deno cache index.ts exitoso

== 9. Checkout limpio de HEAD (git archive)
  OK     Pruebas Deno en HEAD limpio — 326 pasan, 0 fallan
  OK     El API arranca en HEAD limpio — Listening on http://localhost:8000/

============================================================
RESULTADO: TODO OK  (11/11 comprobaciones)
```

---

## 13. Acciones Manuales para Luis (Producción)

Cuando esta rama sea revisada y aprobada por Claude:
1. **Ejecutar la migración SQL**:
   Copiar y pegar el contenido de `COORDINACION/SQL_PARA_LUIS/20261112_01_tablero_orden_fases.sql` en el SQL Editor de Supabase (producción).
2. **Ejecutar la verificación SQL**:
   Copiar y pegar el contenido de `COORDINACION/SQL_PARA_LUIS/verificacion_tablero.sql` y `COORDINACION/SQL_PARA_LUIS/prueba_roles.sql` en el SQL Editor de Supabase y verificar que retornen `todo_ok = true`.
3. **Rebuild del Backend**:
   En EasyPanel, entrar al servicio `remolques-api` y presionar **"Rebuild"**.
4. **Rebuild del Frontend**:
   En EasyPanel, entrar al servicio `remolques-web` y presionar **"Rebuild"**.

