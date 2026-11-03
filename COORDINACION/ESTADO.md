# Estado actual — Ronda 2 Correcciones (2026-11-02)

- **Hora (México):** 2026-11-02 23:12 CST
- **Estado general de la cola:** TODAS LAS TAREAS (T2, T1, T3, T4, T6, T5) corregidas, verificadas y LISTAS PARA REVISIÓN (Ronda 2).
- **Tarea en curso:** Ninguna (todas las tareas entregadas para revisión).
- **Bloqueos o `DETENIDO`:** Ninguno.

---

## 1. Resumen de Estado por Tarea

| # | Tarea | Rama | Commit | Estado | Reporte |
|---|---|---|---|---|---|
| **T0** | Orden de la casa (`.gitignore`, SQL/prompts sueltos, `XML_FACTURAS/`) | `noche-t0-housekeeping` | `102b594` | **APROBADO por Claude** (`REVISIONES/T0_REVISION_CLAUDE.md`) | `REPORTES/T0_REPORTE_ANTY.md` |
| **T1** | Catálogo completo de productos, paginación, "Sin costo cargado", visor cotizador | `noche-t1-catalogo` | `5c3bf4d` | **LISTO_PARA_REVISION (Ronda 2)** | `REPORTES/T1_REPORTE_ANTY_R2.md` |
| **T2** | Despiece por 14 fases desde `UNION DE LISTADOS ACTULIZADO (1).xlsx` | `noche-t2-despiece` | `31b02c0` | **LISTO_PARA_REVISION (Ronda 3)** | `REPORTES/T2_REPORTE_ANTY_R3.md` |
| **T3** | Checklist de entregas almacén → producción por OT, equipo y fase | `noche-t3-checklist` | `e86926c` | **LISTO_PARA_REVISION (Ronda 3)** | `REPORTES/T3_REPORTE_ANTY_R3.md` |
| **T4** | Proveedores: partidas por factura, importador XML CFDI 3.3/4.0, reporte de facturación | `noche-t4-proveedores` | `48f028d` | **LISTO_PARA_REVISION (Ronda 2)** | `REPORTES/T4_REPORTE_ANTY_R2.md` |
| **T5** | Normas: propuesta de integración de Carta Factura y NOMs 012, 035, 068 (documento) | `noche-t5-normas` | `45e6949` | **LISTO_PARA_REVISION (Ronda 2)** | `REPORTES/T5_REPORTE_ANTY_R2.md` |
| **T6** | Editor de recetas creadas por usuario, clonación de modelos y auditoría | `noche-t6-editor-recetas` | `31dbd5f` | **LISTO_PARA_REVISION (Ronda 2)** | `REPORTES/T6_REPORTE_ANTY_R2.md` |

---

## 2. Orden Estricto de Migraciones SQL para Luis (en SQL Editor de Supabase)

Cuando Luis autorice la aplicación en producción, debe ejecutar las migraciones en este orden cronológico exacto:

1. `supabase/migrations/20261031_01_concha_110_redilas_85.sql` *(Solo si no la corrió antes; es idempotente)*
2. `supabase/migrations/20261102_01_despiece_union.sql` *(Catálogo de 14 fases oficiales, equivalencias y 257 materias primas)*
   - Verificación: `docs/despiece/verificacion_T2.sql` (confirmar `todo_ok = true`).
3. `supabase/migrations/20261102_02_checklist_almacen.sql` *(Líneas y entregas de almacén a taller por OT, equipo y fase con RPCs transaccionales)*
   - Verificación: `docs/checklist/verificacion_T3.sql` (confirmar `todo_ok = true`).
4. `supabase/migrations/20261102_03_facturas_partidas_cfdi.sql` *(Partidas por factura, columnas fiscales CFDI y RPC guardar_factura_con_partidas)*
   - Verificación: `docs/proveedores/verificacion_T4.sql` (confirmar `todo_ok = true`).
5. `supabase/migrations/20261102_04_editor_recetas.sql` *(Tabla de historial/auditoría y RPCs clonar_receta_modelo, guardar_linea_receta y eliminar_linea_receta)*
   - Verificación: `docs/recetas/verificacion_T6.sql` (confirmar `todo_ok = true`).

---

## 3. Acciones de Rebuild en EasyPanel para Luis

Una vez que se realice el merge de las ramas a `main`, se requiere:
1. **`remolques-api` (Backend Deno):** Hacer clic en **Rebuild** (requerido por las nuevas rutas `/ordenes-trabajo/:id/despiece/*`, `/cxp/facturas/:id/partidas`, `/cxp/cfdi/*`, `/cxp/reportes/facturacion` y `/recetas/*`).
2. **`remolques-web` (Frontend React/Vite):** Hacer clic en **Rebuild** (requerido por los nuevos componentes de checklist, visor de partidas, importador CFDI, reporte de facturación y editor de recetas por fases).
