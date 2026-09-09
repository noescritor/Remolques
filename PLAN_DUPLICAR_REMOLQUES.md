# Plan — Duplicar "Cotización App Admin" → Sistema de Producción y Almacén (Remolques)

**Base:** repo `cotizacion-app-admin` (React + Vite + Supabase, Moodboard Kit 3.0 dark theme)
**Cliente objetivo:** fabricante de remolques, plataformas, dollies, tolvas, caja seca
**Este documento se le da directo a Claude Code como contexto inicial.**

---

## 0. Estrategia: duplicar, no reescribir

1. Fork del repo actual a uno nuevo (ej. `remolques-produccion-app`).
2. Proyecto de Supabase **nuevo** (no el mismo `kntbzloxbfrklzgjnvzi`) — este cliente necesita
   tablas propias (materiales, proveedores, compras) que no le sirven a otros tenants del SaaS
   genérico, y así no se toca el esquema que ya está en producción para otros.
3. Se parte del `schema.sql` actual exportado + las migraciones en `supabase/migrations/`, y de
   ahí se agregan las migraciones nuevas de la sección 4.

*(Nota al margen: la arquitectura actual ya es multi-tenant con `organizacion_modulos` — en teoría
esto también podría vivir como módulos nuevos del mismo SaaS en vez de un fork. Lo dejo apuntado
por si en algún momento conviene más esa ruta, pero el plan de abajo sigue lo que pediste: duplicar.)*

---

## 1. Lo que YA resuelve el proyecto actual (no reinventar)

| Necesidad que discutimos | Ya existe como | Dónde |
|---|---|---|
| Plantillas de cotización (machote) | `Plantilla` | `types/index.ts`, `PlantillasList.tsx` |
| Costos con vigencia / actualización semanal | `HistorialPrecio` | `types/index.ts` |
| Pagos / próximos cobros | `Pago` (cotizacion_id, monto, fecha) | `types/index.ts` |
| Fecha comprometida + estatus de producción | `Cotizacion.fecha_entrega`, `estado_produccion` | `types/index.ts` |
| Aceptación del cliente = "OC firmada" | Portal cliente + firma digital (`token_publico`, `firma_*`) | `PortalCliente.tsx`, `PortalPDF.tsx` |
| Almacén entradas/salidas | `MovimientoInventario` (tipo_movimiento, cantidad, referencia) | `types/index.ts` |
| Equipo y roles de cuenta | `PerfilOrganizacion.rol` (propietario/admin/usuario), `InvitacionEquipo` | `types/index.ts`, `EquipoManager.tsx` |
| Crédito como forma de pago | `Cliente.tipo_pago_preferido` incluye `'Crédito 30 días'` | `types/index.ts` |

**Consecuencia práctica:** no hay que construir "Orden de Compra" como tabla nueva. La OC del
cliente **es la Cotización ya firmada** (`estado='Aprobada'` + firma en el portal). Todo lo nuevo
se cuelga de esa Cotización, igual que en el demo.

---

## 2. Lo que SÍ falta construir

### 2.1 Materiales y lista de materiales (BOM)
- Agregar a `Producto`: `tipo_item: 'producto_terminado' | 'materia_prima'` (reutilizar la tabla
  existente en vez de crear un catálogo aparte — ya tiene `stock_actual`, `costo`, `unidad`).
- Tabla nueva `producto_materiales` (BOM): `producto_id`, `material_id`, `cantidad_por_unidad`.

### 2.2 Requisición automática (lógica, no tabla)
- Al pasar `Cotizacion.estado` a `'Aprobada'`: calcular `requerido = BOM × cantidad` vs
  `stock_actual` de cada material → si falta algo, dispara 2.4.

### 2.3 Proveedores (tabla nueva)
- `proveedores`: nombre, contacto, teléfono, tiempo_entrega_dias, condiciones_pago.
- `proveedor_materiales`: proveedor_id, material_id (a quién comprarle cada cosa).

### 2.4 Compra a proveedor (tabla nueva)
- `compras_proveedor`: folio, cotizacion_id, proveedor_id, estado (Pendiente/Recibida), fecha.
- `compra_items`: compra_id, material_id, cantidad, costo_unitario.

### 2.5 Crédito de cliente
- Agregar a `Cliente`: `limite_credito numeric`.
- El **saldo usado** no se duplica: se calcula (vista o función SQL) como
  `SUM(Cotizacion.total WHERE estado IN ('Aprobada','Pagada')) - SUM(Pago.monto)`.

### 2.6 Estados de producción ampliados
- Ampliar los valores válidos de `estado_produccion`: `Pendiente de aprobar` → `Aprobada` →
  `Requisición: falta material` → `Compra en curso` → `Listo para producción` → `Surtido`.

### 2.7 Trazabilidad / bitácora
- Tabla nueva `cotizacion_eventos`: cotizacion_id, evento (texto), usuario_id, created_at.
  Alimenta la pantalla de Trazabilidad del demo — cada acción (aprobar, generar compra, recibir,
  surtir) inserta un registro aquí.

### 2.8 Devoluciones
- Ampliar el enum `tipo_movimiento` de `MovimientoInventario`: agregar `Devolucion_Interna`,
  `Devolucion_Cliente`, `Devolucion_Proveedor` (la tabla ya soporta esto, solo falta el valor).

### 2.9 Roles operativos (Ventas / Compras / Almacén / Gerencia)
- **No tocar** `PerfilOrganizacion.rol` (rige permisos de cuenta SaaS: propietario/admin/usuario).
- Agregar columna nueva `area_operativa` a `PerfilOrganizacion` para el área de piso
  (Ventas/Compras/Almacén/Gerencia), y usarla para los mismos permisos que probamos en el demo.

---

## 3. Módulos de interfaz (nav)

- **Dashboard** — extender `DashboardMain.tsx` existente: card de crédito abierto, próximos
  cobros (de `Pago`), entregas por vencer (de `fecha_entrega`), material en alerta de stock.
- **Clientes** — extender `ClienteModal.tsx`: barra de crédito, sus cotizaciones y en qué
  `estado_produccion` va cada una.
- **Cotizaciones** — ya existe, solo agregar badge de `estado_produccion` en la lista.
- **Proveedores** — nuevo.
- **Compra a proveedor** — nuevo.
- **Almacén** — extender `InventarioList.tsx` existente: agregar tab de devoluciones.
- **Trazabilidad** — nuevo, lee `cotizacion_eventos`.

---

## 4. Migraciones sugeridas (mismo formato que ya usan: `YYYYMMDD_NN_descripcion.sql`)

1. `_01_materiales_bom.sql` — columna `tipo_item` en productos + tabla `producto_materiales`
2. `_02_proveedores.sql` — tablas `proveedores` y `proveedor_materiales`
3. `_03_compras_proveedor.sql` — tablas `compras_proveedor` y `compra_items`
4. `_04_credito_cliente.sql` — columna `limite_credito` en clientes + vista de saldo usado
5. `_05_estado_produccion_ampliado.sql` — actualizar constraint de `estado_produccion`
6. `_06_cotizacion_eventos.sql` — tabla de bitácora
7. `_07_movimiento_devoluciones.sql` — ampliar `tipo_movimiento`

---

## 5. Checklist para Claude Code

- [ ] Fork del repo, proyecto Supabase nuevo, actualizar `.env` / `.env.production`
- [ ] Correr migraciones 1–7 (sección 4)
- [ ] Backend (`supabase/functions/server/index.tsx`, Hono): endpoints CRUD para
      `/proveedores`, `/compras-proveedor`, `/cotizacion-eventos`, `/materiales`
- [ ] `useSupabaseData.ts`: cargar materiales/BOM, proveedores, compras, eventos
- [ ] Utilidad nueva `calcularRequisicion(cotizacion)` en `utils/calculations.ts`
- [ ] UI nuevas: `Proveedores.tsx`, `ComprasProveedor.tsx`, `Trazabilidad.tsx`
- [ ] UI a extender: `DashboardMain.tsx`, `ClienteModal.tsx`, `InventarioList.tsx`,
      `CotizacionesList.tsx` (badges de estado/entrega)
- [ ] Reusar el estilo ya definido (tokens de `globals.css`, Moodboard Kit 3.0) — no rediseñar
- [ ] Probar el flujo completo: cotización → firma del cliente (portal) → aprobación →
      requisición → compra a proveedor (si aplica) → entrada de almacén → salida → surtido

---

## 6. Contexto a adjuntar en la primera sesión de Claude Code

- Este documento
- `PLAN_REDISENO_UI.md` (ya en el repo — para no chocar criterios de diseño)
- `types/index.ts` (esquema actual)
- El demo interactivo (`.jsx`) ya construido y con el estilo del Moodboard Kit aplicado, como
  referencia de pantallas y flujo
