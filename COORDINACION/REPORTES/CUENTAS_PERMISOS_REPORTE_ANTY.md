# Reporte — Bloque "Cuentas y permisos" (`cuentas-permisos-2026-11-27`)

- **Rama:** `cuentas-permisos-2026-11-27` (worktree independiente desde `main` `daebb23`).
- **Migración:** `supabase/migrations/20261127_02_cuentas_permisos.sql` (idempotente; **no** ejecutada en producción).
- **Alcance respetado:** sin merge ni push a `main`, sin SQL en producción, sin crear cuentas ni tocar contraseñas, sin agregar roles nuevos ni permisos por módulo, sin tocar E2.

---

## 1. Cambios implementados (puntos 1 a 9)

1. **RLS estricto en `invitaciones_equipo` (`20261127_02_cuentas_permisos.sql`):**
   - Helper `public.es_admin_o_propietario_org(p_org UUID)` (`SECURITY DEFINER`, `SET search_path = public, pg_temp`, `REVOKE ALL FROM PUBLIC, anon; GRANT EXECUTE TO authenticated, service_role`).
   - `inv_insert`: solo `admin` o `propietario` de la organización y **nunca** `rol = 'propietario'` (`LOWER(TRIM(COALESCE(rol, ''))) IN ('admin', 'usuario')`). El alta de organización nueva (`service_role`) sigue creando invitaciones con rol `'propietario'`.
   - `inv_delete`: solo `admin` o `propietario` de la organización.
   - `REVOKE ALL FROM PUBLIC, anon;` y `REVOKE UPDATE, TRUNCATE FROM authenticated;`.
2. **Controles de rol en el servidor (`motor/cuentas_permisos.ts` + `index.ts`):**
   - `POST /invitaciones` (`crearInvitacionSegura`): exige rol `admin` o `propietario` en `perfiles_organizacion` (403 si no), rechaza `rol = 'propietario'` con 403 (`rol_propietario_prohibido`), solo admite `'admin'` o `'usuario'`.
   - `DELETE /invitaciones/:id` (`eliminarInvitacionSegura`): exige `admin` o `propietario` (403) y filtra por `organizacion_id`.
   - `POST /organizaciones/crear-con-invitacion`, `GET /organizaciones` y `PUT /organizaciones/:id/modulos` (`exigirSuperAdminOrgPrincipal`): exigen **Organización Principal Y rol `admin`/`propietario`** en `perfiles_organizacion` (403 si falta cualquiera).
3. **Rol único del frontend desde `perfiles_organizacion` (`src/app/hooks/useRolOrganizacion.ts`):**
   - Fuente única usada en `App.tsx` y pasada a `ComprasProveedorList`, `CatalogoCostosMain` y `EquipoManager`.
   - **Cero** lecturas de `user_metadata` para roles en todo `src/`.
   - Si falla la lectura de `perfiles_organizacion`, trata como `'usuario'` y muestra aviso con botón **Reintentar**. Compras sigue permitiendo recibir únicamente a `admin` y `propietario`.
4. **Pantalla "Equipo" (`src/app/components/Equipo/EquipoManager.tsx`):**
   - El formulario de invitar, el botón de eliminar invitación y los paneles de Super-Admin solo se muestran a `admin` o `propietario`.
   - Mensaje exacto tras invitar: `"Invitación registrada. No se envía correo: falta crear la cuenta."`
5. **Auditoría de escalación de permisos desde el navegador (ver §2).**
6. **Equipos protegidos contra escritura directa (`trg_proteger_ordenes_trabajo_directo` en `20261127_02_cuentas_permisos.sql`):**
   - Trigger `BEFORE UPDATE OR DELETE ON public.ordenes_trabajo` (`SECURITY INVOKER`): solo actúa cuando `current_user IN ('authenticated', 'anon')`.
   - Rechaza `DELETE` directo (`42501 operacion_no_permitida`) y `UPDATE` de `cancelada_el`, `cancelada_por`, `motivo_cancelacion`, `cliente_id`, `organizacion_id`, `cotizacion_id`, `origen` y `nomenclatura_id` (`42501 campo_protegido`).
   - Las RPC `SECURITY DEFINER`, la edición normal de campos editables (NIV, etiqueta, material faltante, etc.) y el `ON DELETE CASCADE` desde `cotizaciones` siguen funcionando (probado con `rls_ordenes_trabajo` y `rls_cotizaciones` reales en PG 17).
7. **Pantalla Equipo con varias cuentas (`GET /equipo` → `listarEquipoOrganizacion`):**
   - Consulta `perfiles_organizacion` con `service_role` filtrando `.eq('organizacion_id', orgId)` del token, sin abrir la política `po_select`.
   - Pagina `adminSupabase.auth.admin.listUsers({ page, perPage: 50 })` hasta agotar todas las páginas para no perder correos con >50 usuarios.
8. **Alta de cuentas (`on_auth_user_created_trigger` + `Login.tsx`):**
   - Incluidas en `20261127_02_cuentas_permisos.sql` la función `public.on_auth_user_created()` (versión `20260616`, insensible a mayúsculas/minúsculas, `SET search_path = public, pg_temp`) y el trigger idempotente `on_auth_user_created_trigger` en `auth.users`. Los usuarios existentes no cambian.
   - `Login.tsx`: quitado `"Regístrate"` (`view={vista}` con `'sign_in'` por defecto y `showLinks={false}`) **conservando la recuperación de contraseña** mediante un enlace propio `"¿Olvidaste tu contraseña?"` que alterna a `view="forgotten_password"` y vuelve a `"Volver a iniciar sesión"`.
9. **Vista abierta sin sesión (`vista_saldo_cliente`) y auditoría de seguridad:**
   - Replicado idempotentemente `SQL_PARA_LUIS/2026-11-27-ACCESOS/1_cerrar_vista.sql` en `20261127_02_cuentas_permisos.sql` (`security_invoker = true`, `REVOKE ALL FROM anon, public`, `REVOKE INSERT/UPDATE/DELETE/... FROM authenticated`, `REVOKE EXECUTE ON obtener_siguiente_produccion() FROM public, anon; GRANT TO authenticated, service_role`).
   - Prueba automática en `docs/cuentas/verificacion_cuentas_permisos.sql` que falla si cualquier vista de `public` carece de `security_invoker` o si cualquier función `SECURITY DEFINER` (no trigger, no extensión, salvo `get_current_org_id`) es ejecutable por `anon`.

---

## 2. Hallazgos de auditoría RLS (Puntos 5 y 6 — solo reporte, sin cambios)

### 2.1 Tablas donde un `usuario` podría escalarse permisos desde el navegador (Punto 5)
Verificado directamente contra `pg_policies` en PG 17 real:
- **`perfiles_organizacion`**: solo tiene `po_select` (`FOR SELECT TO authenticated USING (usuario_id = auth.uid())`). No existen políticas `INSERT`, `UPDATE` ni `DELETE` para `authenticated` → un `usuario` **no** puede cambiarse de rol ni de organización desde el navegador.
- **`organizaciones`**: solo tiene `org_select` (`FOR SELECT TO authenticated USING (id = get_current_org_id())`). No existen políticas `INSERT`, `UPDATE` ni `DELETE` para `authenticated` → un `usuario` **no** puede crear organizaciones ni activar/desactivar `modulos` desde el navegador.
- **`invitaciones_equipo`**: era el único hueco directo de escalación (un `usuario` podía invitar un correo suyo como `admin` o `propietario`); **quedó cerrado en esta migración**.

### 2.2 Otras tablas con política `FOR ALL` que permiten saltarse controles de rol del servidor (Punto 6, sin modificarlas todavía)
Consultadas directamente en `pg_policies` (`cmd = 'ALL'`):
- **Catálogo de costos (el servidor exige `propietario`/`admin`):** `costos_modelo`, `opcion_costos`, `procesos_manufactura`, `parametros_costeo`, `costos_historial`, `precios_lotes`, `precios_lotes_items`.
- **Recetas / Configurador (el editor de recetas exige `propietario`/`admin`):** `receta_base`, `modelos`, `grupos_configuracion`, `opciones_configuracion`, `opcion_componentes`, `producto_materiales`.
- **Acero:** `acero_materiales`, `acero_precios`, `acero_precios_historial`.
- **Cobros (E1):** `pagos`, `pago_aplicaciones`, `equipo_valor_cobranza`, `planes_pago`, `plan_pagos_parcialidades`.
- **CxP / Compras / Producción:** `facturas_proveedor`, `pagos_factura`, `estados_cuenta_proveedor`, `tipos_cambio`, `operarios`, `produccion_areas`, `produccion_frentes`, `plan_tareas`, `plan_tarea_operarios`, `plan_tarea_materiales`, `plan_tareas_historial`.

*(Nota: las tablas más recientes de despiece/almacén, calidad, alias/recepciones G y `orden_cambios` ya siguen el patrón `FOR SELECT TO authenticated` con escritura solo desde servidor/RPC).*

---

## 3. Evidencia de pruebas

1. **Postgres 17 real (`20261127_02_cuentas_permisos.sql` ×2 + `2_diagnostico.sql`):**
   - Migración aplicada **×2** sin errores.
   - Resultado de `2_diagnostico.sql` tras aplicar la migración:
     - `1 trigger de alta en auth.users`: `on_auth_user_created_trigger -> on_auth_user_created (O)`
     - `4 tablas sin RLS`: `ninguna`
     - `5 politicas abiertas`: `ninguna`
     - `6 vistas que saltan RLS`: `ninguna`
     - `7 funciones con permiso de dueno que anon puede llamar`: `get_current_org_id`
     - `8 vista de saldos cerrada`: `true`
2. **Suite SQL integral (`docs/cuentas/verificacion_cuentas_permisos.sql`) en PG 17 real con `rls_ordenes_trabajo` y `rls_cotizaciones` reales:**
   - `anon` bloqueado en `invitaciones_equipo` y `vista_saldo_cliente`; `usuario` bloqueado para invitar y borrar invitaciones; `admin` puede invitar `usuario`/`admin` en su org, bloqueado para `propietario` y aislado de Org B.
   - Trigger de `ordenes_trabajo`: bloquea `DELETE` directo y `UPDATE` de campos protegidos; permite edición normal, `ON DELETE CASCADE` desde `cotizaciones` y RPC `cancelar_orden_trabajo`.
   - Trigger `on_auth_user_created_trigger`: alta con invitación (case-insensitive) crea perfil con el rol exacto y borra la invitación; sin invitación rechaza con `Registro denegado`; usuarios existentes intactos.
   - Auditoría automática de seguridad de todas las vistas `public` y funciones `SECURITY DEFINER`: **OK**.
3. **Servidor Deno + mutaciones:**
   - `motor/cuentas_permisos.test.ts`: **5/5 pasan** (incluye paginación >50 en `listUsers` y aislamiento de 2 organizaciones).
   - `scripts/dev/test_cuentas_permisos_mutaciones.cjs`: **8/8 mutaciones muertas, 0 vivas**.
4. **Verificación final:** `node scripts/verificar.mjs --limpio` → **TODO OK (11/11)**.

---

## 4. Acciones manuales pendientes para despliegue
1. Revisar y aprobar merge de `cuentas-permisos-2026-11-27` a `main`.
2. Ejecutar `supabase/migrations/20261127_02_cuentas_permisos.sql` en el SQL Editor de Supabase (idempotente; ya incluye `equipos-gestion` y funciona sin ser dueño de `auth.users`).
3. Hacer **Rebuild** de `remolques-api` y después de `remolques-web` en EasyPanel.

---

## 5. Ronda 2 — Ajustes D1 a D5 (`PROMPT_ANTY_CUENTAS_R2_2026-11-27.md`)

1. **D1 (Merge con `main` `87bc64e`):**
   - `main` (con `equipos-gestion-2026-11-27`) integrado en `cuentas-permisos-2026-11-27` (commit de merge `ce63492`).
   - Conflictos resueltos preservando ambos bloques en `supabase/functions/make-server-feea4382/index.ts` (imports) y `CHANGELOG_ANTIGRAVITY.md`.
2. **D2 (Trigger en `auth.users` sin `DROP TRIGGER`):**
   - Eliminado `DROP TRIGGER IF EXISTS on_auth_user_created_trigger ON auth.users;` de `20261127_02_cuentas_permisos.sql`.
   - Reemplazado por bloque idempotente `DO $trg$` que crea el trigger solo si no existe en `pg_trigger` (idéntico a `SQL_PARA_LUIS/2026-11-27-ACCESOS/3_plantillas_y_alta.sql`).
   - **Probado en PG 17 real:** `20261127_02_cuentas_permisos.sql` ejecutada **×2** y además ejecutada bajo un rol `NOSUPERUSER` (`rol_sql_editor_sim`) que **NO es dueño de `auth.users`** cuando `on_auth_user_created_trigger` ya existe → pasó sin error (`must be owner of relation users` eliminado).
3. **D3 (Punto 10 — cierre de `plantillas_cotizacion` y prueba automática de políticas en `public`):**
   - Replicado idempotentemente en `20261127_02_cuentas_permisos.sql` el bloque `DO $cierre$` de `3_plantillas_y_alta.sql`: borra cualquier política abierta (`qual = 'true' OR with_check = 'true'`) en `public.plantillas_cotizacion` y garantiza `rls_plantillas` (`organizacion_id = public.get_current_org_id()`).
   - Agregada prueba automática en `docs/cuentas/verificacion_cuentas_permisos.sql` que falla si **cualquier** política de `pg_policies` en `public` carece de filtro de organización o usuario (`get_current_org_id|organizacion_id|usuario_id`). Validada en PG 17 real tras correr toda la cadena de 21 migraciones + política abierta sembrada + `20261127_02` ×2 → **0 políticas abiertas**.
4. **D4 (Pruebas de rutas reales en `index.ts` y mutaciones sobre `index.ts`):**
   - Exportado `app` en `index.ts` con guardia `if (import.meta.main)` para `Deno.serve(...)`.
   - Nueva suite `supabase/functions/make-server-feea4382/cuentas_permisos_rutas.test.ts` (**8/8 pruebas pasan**) contra el `app` real de `index.ts` (con `authMiddleware` y mock HTTP de GoTrue/PostgREST que registra toda escritura):
     - `POST /invitaciones`, `DELETE /invitaciones/:id`, `POST /organizaciones/crear-con-invitacion`, `GET /organizaciones` y `PUT /organizaciones/:id/modulos`: `usuario` recibe **403** y **0 escrituras**; `admin` de org secundaria recibe **403** en `/organizaciones/*`; `admin` de org principal puede operar pero no invitar `propietario`.
     - `DELETE /clientes/:id`: cliente con equipos recibe **409** con el conteo y **0 escrituras**; sin equipos recibe **200**.
   - Mutaciones ampliadas en `scripts/dev/test_cuentas_permisos_mutaciones.cjs`: **16/16 muertas, 0 vivas** (**10/10** en `motor/cuentas_permisos.ts` + **6/6** directamente sobre las rutas de `index.ts`).
5. **D5 (Proteger equipos al borrar un cliente):**
   - `20261127_02_cuentas_permisos.sql`: bloque idempotente `DO $fk_ot_cliente$` cambia la FK `ordenes_trabajo_cliente_id_fkey` de `ON DELETE CASCADE` (`c`) a `ON DELETE NO ACTION` (`a`). No modifica `ordenes_trabajo_cotizacion_id_fkey` (borrar cotización sigue igual).
   - `motor/cuentas_permisos.ts` (`eliminarClienteSeguro`) + `DELETE /clientes/:id` en `index.ts`: cuenta `ordenes_trabajo` del cliente en la organización (**incluyendo cancelados**); si `> 0`, devuelve **409** indicando cuántos equipos tiene (y mapea `23503` a **409** como respaldo).
   - Frontend (`src/app/App.tsx`): `manejarEliminarCliente` muestra claramente `error?.detalle` del servidor en el toast de error.
   - **Probado en PG 17 real (`verificacion_cuentas_permisos.sql` §6):**
     - FK confirmada `ON DELETE NO ACTION` (`confdeltype = 'a'`).
     - Borrar cliente con equipo manual **activo** (sin cotizaciones) → rechazado exactamente por `ordenes_trabajo_cliente_id_fkey` (`23503`).
     - Borrar cliente con equipo manual **cancelado** → también rechazado por `ordenes_trabajo_cliente_id_fkey` (`23503`).
     - Borrar cliente **sin equipos** → éxito (`ROW_COUNT = 1`).
     - Borrar **cotización** → sigue borrando en cascada como antes (§3d).
     - Borrar **organización** con `ordenes_trabajo` → sigue funcionando por cascada (`clientes_organizacion_id_fkey` ya era `NO ACTION`, `ordenes_trabajo_organizacion_id_fkey` sigue `CASCADE`).
