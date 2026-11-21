# Reporte Técnico — Calidad, Parte 1 de 2: Datos, Plantillas Semilla y API

**Fecha:** 2026-11-21  
**Rama:** `calidad-c1-datos-2026-11-21` (worktree `..\Remolques_calidad_c1`, desde `main` `4153313`)  
**Referencia:** `PROMPT_ANTY_CALIDAD_C1_DATOS_2026-11-21.md`, `COORDINACION/PLAN_CAMBIOS_VISITA_2026-11-20.md` (Bloque C)

---

## 1. Qué se construyó (archivos y alcance)

1. **`docs/calidad/calidad_plantillas_seed.json`** (copiado y versionado desde el origen de verdad):
   - 5 plantillas semilla: `control_total` Plataforma (13 grupos, 116 ítems, 1 unidad), `entrega` Plataforma (4 grupos, 57 ítems, 2 unidades: `Plana 1`/`Plana 2`), `entrega` Góndola (4 grupos, 52 ítems, 2 unidades: `Unidad 1`/`Unidad 2`), `entrega` Dolly (4 grupos, 28 ítems, etiquetas `Sí`/`No`), `entrega` Cama baja (4 grupos, 39 ítems).
2. **`supabase/migrations/20261121_01_calidad.sql`** (migración idempotente):
   - **6 tablas**: `calidad_plantillas`, `calidad_plantilla_grupos`, `calidad_plantilla_items`, `orden_calidad_inspecciones`, `orden_calidad_resultados`, `calidad_folios`.
   - **Índices y unicidad**: `uq_calidad_plantilla_activa` (índice único parcial `WHERE estado = 'activa'`), `uq_orden_calidad_en_proceso` (índice único parcial `WHERE estado = 'en_proceso'`), índices por `(organizacion_id, ...)`, `ON DELETE CASCADE` en grupos/ítems/resultados y `ON DELETE RESTRICT` en `orden_calidad_inspecciones.plantilla_id`.
   - **RLS**: habilitada en las 6 tablas, solo `SELECT` para `authenticated` con `organizacion_id = get_current_org_id()`. Ninguna política de escritura directa.
   - **Funciones `SECURITY DEFINER` (`SET search_path = public`, `GRANT` exclusivo a `service_role`)**:
     - `sembrar_calidad_plantillas(p_org)`
     - `crear_plantilla_borrador(p_org, p_linea_clave, p_formato, p_nombre)`
     - `guardar_plantilla_calidad(p_org, p_id, p_payload)`
     - `duplicar_plantilla(p_org, p_id, p_linea_clave, p_formato, p_nombre)`
     - `nueva_version_plantilla(p_org, p_id)`
     - `publicar_plantilla(p_org, p_id)` (con `pg_advisory_xact_lock` para serializar publicaciones concurrentes)
     - `eliminar_plantilla_borrador(p_org, p_id)`
     - `crear_inspeccion_calidad(p_org, p_orden, p_formato, p_plantilla, p_usuario)` (con `FOR UPDATE` en `ordenes_trabajo` y folios atómicos `CCT-000001` / `CE-000001`)
     - `actualizar_encabezado_inspeccion(p_org, p_inspeccion, p_payload, p_usuario)`
     - `guardar_resultados_calidad(p_org, p_inspeccion, p_resultados, p_usuario)`
     - `cerrar_inspeccion_calidad(p_org, p_inspeccion, p_liberado_por, p_fecha_liberacion, p_usuario)`
     - `reabrir_inspeccion_calidad(p_org, p_inspeccion, p_usuario)`
     - `resumen_calidad_ordenes(p_org)`
3. **`supabase/functions/make-server-feea4382/motor/calidad.ts`** y **`index.ts`** (líneas 49-65, 1238-1485):
   - 14 rutas bajo autenticación (`/calidad/plantillas*`, `/calidad/inspecciones*`, `/calidad/resumen-ordenes`), tomando `organizacionId` del contexto autenticado y delegando escrituras a `getServiceClient().rpc(...)`.
4. **`scripts/verificar_calidad.sql`**: verificador de solo lectura.
5. **`supabase/functions/make-server-feea4382/motor/calidad.test.ts`**: 7 pruebas unitarias Deno.

---

## 2. Choque encontrado con `main` y cómo se resolvió

- `sembrar_tablero_produccion(p_org)` (`20261112_01_tablero_orden_fases.sql`) solo crea 4 líneas en `lineas_producto`: `plataforma`, `gondola`, `dolly`, `traila`.
- El archivo semilla `calidad_plantillas_seed.json` trae una 5.ª plantilla para **`cama_baja`** (`Calidad de entrega — Cama baja`).
- **Solución aplicada**: `sembrar_calidad_plantillas(p_org)` llama primero a `sembrar_tablero_produccion(p_org)` y enseguida inserta `('cama_baja', 'Cama baja')` en `lineas_producto` con `ON CONFLICT (organizacion_id, clave) DO NOTHING`. Esto permite cumplir la FK sin modificar `20261112_01_tablero_orden_fases.sql` ni el motor del tablero.

---

## 3. Evidencia de pruebas y verificación

### A. Migración doble + Hashes MD5 de precios (`test_calidad_c1`, Postgres 17, `-v ON_ERROR_STOP=1`)
- Corrida 1 y Corrida 2 ejecutadas con código de salida `0`.
- Hashes MD5 **idénticos** antes y después de las dos corridas:
  - `receta_base`: `5475cb65323c4272efe9da3dac66242b`
  - `costos_modelo`: `07aae2ce021880a417e75ff45f5cbd94`
  - `procesos_manufactura`: `8bc33825a653fe0ad3aea4c7538e296f`
  - `opcion_costos`: `ace8acaf9a17492f07ed8f298401f6dd`
  - `productos`: `abf20196f9ce8f4ebdbc4083a5dd2bb6`

### B. Salida de `scripts/verificar_calidad.sql`
```
plantillas_activas_5_ok     | t
ct_plataforma_ok            | t
entrega_items_ok            | t
una_activa_por_linea_fmt_ok | t
rls_6_tablas_ok             | t
todo_ok                     | t
```

### C. Pruebas reales contra Postgres (`test_calidad_pg.cjs`, 8/8 OK)
1. Re-semilla (`sembrar_calidad_plantillas`) no pisa plantilla editada por el usuario ni duplica filas.
2. `NO_EDITABLE` al intentar editar plantilla `activa`; `duplicar_plantilla` copia 116 ítems a `dolly`; `eliminar_plantilla_borrador` borra borradores sin inspecciones.
3. `SIN_PLANTILLA` en Góndola `control_total`; folios consecutivos `CE-000001`, `CE-000002`; `YA_EXISTE` ante duplicado `en_proceso`; re-inspección (`intento = 2`) tras cerrar.
4. `guardar_resultados_calidad` (lote + baja a pendiente con `resultado = null`) y `resumen_calidad_ordenes` con 2 unidades en plataforma entrega (`total_esperados = 114`).
5. `cerrar_inspeccion_calidad`: con `bloquea_liberacion = false` cierra y devuelve `advertencias`; con `bloquea_liberacion = true` y no conformes lanza `BLOQUEADA_POR_NO_CONFORMES`; inspecciones previas conservan su `plantilla_id` original tras publicar nueva versión.
6. Aislamiento entre organizaciones (`orgB` recibe `PLANTILLA_NO_ENCONTRADA` / `ORDEN_NO_ENCONTRADA` sobre recursos de `orgA`) y `REVOKE` verificado con `SET ROLE authenticated` (`permission denied`).
7. **Concurrencia real contra Postgres** (dos conexiones simultáneas con `Promise.allSettled`):
   - Dos `crear_inspeccion_calidad` simultáneos sobre la misma `(orden, formato)` → 1 éxito, 1 rechazo `YA_EXISTE`.
   - Dos `publicar_plantilla` simultáneos sobre dos borradores de la misma `(org, linea, formato)` → ambos serializan con `pg_advisory_xact_lock`, quedando exactamente **1** `activa`.
8. **Mutación propia**: dentro de una transacción con `ROLLBACK`, se eliminó `uq_calidad_plantilla_activa` y se activó una segunda plantilla; `scripts/verificar_calidad.sql` reportó `una_activa_por_linea_fmt_ok = f` y `todo_ok = f`.

### D. Suite del repositorio
- **Pruebas Deno desde raíz del repo**: antes `237 passed` → después **`244 passed | 0 failed`** (+7 en `motor/calidad.test.ts`).
- **`node scripts/verificar.mjs --limpio`**: **11/11 comprobaciones OK** (`npm run build` exitoso, `tsc` 0 nombres sin definir, arranque de API OK).

---

## 4. Qué falta por confirmar con Luis (para Bloque 2 / operación)

1. **Equivalencia de 2 procesos de Control Total con fases del tablero de Plataforma** (marcados `fase_confirmada = false` en el JSON semilla):
   - Proceso `2` (**Ensamble de chasis**) → propuesto a fase 2 (`Dispositivo`).
   - Proceso `9` (**Resoldado**) → propuesto a fase 5 (`Perchas`).
   - Confirmar si corresponden a esas fases o si deben reasignarse desde el editor.
2. **Encabezados de documento (`revision_formato` y `fecha_revision_formato`)**: quedaron nulos en la semilla por no venir en el JSON; confirmar si se capturan manualmente por plantilla.
3. **Plantillas faltantes**: `control_total` Dolly, `control_total` Góndola y `entrega` Traila quedan sin plantilla por diseño hasta crearlas/duplicarlas desde el editor (Bloque 2).

---

## 5. Instrucciones exactas de despliegue (cuando se apruebe el merge)

1. **Base de datos (Supabase SQL Editor)**:
   - Ejecutar `supabase/migrations/20261121_01_calidad.sql`.
   - Ejecutar `scripts/verificar_calidad.sql` y confirmar `todo_ok = true`.
2. **Backend (`remolques-api` en EasyPanel)**:
   - Hacer **Rebuild** para desplegar `motor/calidad.ts` y las rutas `/calidad/*` en `index.ts`.
3. **Frontend (`remolques-web`)**:
   - **NO hace falta rebuild del frontend en esta parte 1** (las pantallas llegan en Calidad parte 2).

---

## 6. Ronda 2 — Correcciones a observaciones de Claude

### Qué cambió
1. **Unidad fuera de rango (Obs. 1)**:
   - `guardar_resultados_calidad` (`20261121_01_calidad.sql`) valida `unidad BETWEEN 1 AND jsonb_array_length(config->'unidades')` y lanza `UNIDAD_INVALIDA` (mapeado a HTTP `400` en `motor/calidad.ts`).
   - `cerrar_inspeccion_calidad`, `resumen_calidad_ordenes` y `calcularResumenInspeccion` (`motor/calidad.ts`) cuentan únicamente resultados con `unidad` dentro de rango (`1..num_unidades`).
2. **Solo plantillas activas con `p_plantilla` (Obs. 2)**:
   - `crear_inspeccion_calidad` exige `estado = 'activa'` y `formato = p_formato` cuando se pasa `p_plantilla` explícita (permitiendo elegir otra línea a propósito, pero rechazando borradores y archivadas con `PLANTILLA_NO_ENCONTRADA`).
3. **Resolución automática de Cama baja (Obs. 3)**:
   - Sin `p_plantilla`, si `ordenes_trabajo.tipo_equipo = '05'` (o su modelo/etiqueta menciona `cama baja`), `crear_inspeccion_calidad` busca primero la plantilla activa de la línea `cama_baja` para ese formato; si no existe (por ejemplo `control_total`), cae a la plantilla activa de la línea de la orden (`plataforma`). No se modificó `src/app/utils/tableroProduccion.ts` ni el motor del tablero.
4. **Pruebas versionadas y guardias de organización (Obs. 4)**:
   - Se versionó `scripts/test_calidad_pg.cjs` con casos reales de `UNIDAD_INVALIDA` (unidad 0 y 3), rechazo de borrador/archivada, `tipo_equipo = '05'` (cama baja en `entrega` y fallback a `plataforma` en `control_total`) y `evaluado_por = NULL`.
   - **Cómo correr `scripts/test_calidad_pg.cjs`**:
     - `createdb -h localhost -p 54331 -U tester -T remolques test_calidad_c1`
     - `psql -h localhost -p 54331 -U tester -d test_calidad_c1 -v ON_ERROR_STOP=1 -f supabase/migrations/20261121_01_calidad.sql`
     - `node scripts/test_calidad_pg.cjs` (variables opcionales: `PGHOST`, `PGPORT`, `PGUSER`, `PGPASSWORD`, `PGDATABASE`).
   - En `motor/calidad.test.ts`, los simuladores registran llamadas `.eq("organizacion_id", ...)` (distinguiendo el `head` de siembra) y `p_org` de los 7 RPCs.
5. **Menor (Obs. 5a)**:
   - `crear_inspeccion_calidad` inicializa `evaluado_por` en `NULL` en lugar de `''`.

### Conteo de pruebas y mutaciones (Ronda 2)
- **Pruebas Deno desde raíz del repo**: antes `244 passed` → después **`247 passed | 0 failed`** (+3 pruebas en `motor/calidad.test.ts`).
- **Pruebas reales contra Postgres (`scripts/test_calidad_pg.cjs`)**: **9/9 OK**.
- **Doble corrida de migración (`ON_ERROR_STOP=1`)**: ambas exitosas; hashes MD5 de las 5 tablas de precios idénticos; `scripts/verificar_calidad.sql` → `todo_ok = t`.
- **`node scripts/verificar.mjs --limpio`**: **11/11 comprobaciones OK**.
- **Mutaciones de aislamiento detectadas (3/3)**:
  1. Quitar `.eq("organizacion_id", orgId)` en `listarPlantillasCalidad` → **detectada** por `calidad.test.ts`.
  2. Quitar `.eq("organizacion_id", orgId)` en `obtenerPlantillaCalidad` → **detectada** por `calidad.test.ts`.
  3. Enviar otra organización en `p_org` de `crear_inspeccion_calidad` → **detectada** por `calidad.test.ts`.

