# Bloque 1 — Conectar Aprobar → Requisición → Producción

Contexto para el agente (Antigravity). Léelo completo antes de tocar código.

## 0. Antes de nada

1. Lee `AGENTS.md` (todas las reglas, incluida la §6 de bitácora), `AUDITORIA_2026-09-18.md` y `CHANGELOG_ANTIGRAVITY.md`.
2. **Verifica la auditoría, no le creas a ciegas.** Fue una revisión estática hecha por otro agente. Para cada ID de la tabla de abajo, abre el archivo indicado y responde **CONFIRMADO / REFUTADO / PARCIAL** con `archivo:línea`. Registra el resultado en la primera entrada del changelog. Si algo estaba mal, añade una sección `## Correcciones` al final de la auditoría en vez de reescribirla.

| ID | Qué verificar | Dónde |
|----|---------------|-------|
| F1 | Aprobar (manual o por portal) no crea evento, ni cambia `estado_produccion`, ni dispara nada | `index.ts` `PUT /cotizaciones/:id`, `POST /portal/:token/aprobar`; `App.tsx` `manejarCambiarEstado` |
| F2 | Nadie escribe `estado_produccion`; el Dashboard filtra `'Entregado'` y el tipo dice `'Pendiente'\|'En Producción'\|'Entregado'`, pero la migración 05 documenta otros 6 estados | `DashboardMain.tsx:~154`, `types/index.ts:210`, migración `20260907_05` |
| F3 | `producto_materiales` sin API ni UI; `GenerarRequisicionModal` muestra todos los productos (`\|\| true`) y no compara con stock | `GenerarRequisicionModal.tsx:~32`, `index.ts` (buscar `producto_materiales`) |
| F14 | `PUT /compras-proveedor/:id` con `estado:'Recibida'` suma stock en cada llamada; el stock se actualiza leyendo y luego escribiendo | `index.ts:~1655-1695` |
| F15 | `generar-ordenes` ignora items con `precio_unitario < 10000`, deduce tipo por palabras, y usa número **aleatorio** si falla la RPC; no es idempotente | `index.ts:~1941-2040` |
| F16 | Folio de compra `OC-${Date.now().slice(-6)}` generado en el cliente | `CotizacionDetalle.tsx:~78` |
| S4 | Portal: `rechazar` y `solicitar-cambios` no validan expiración; ningún endpoint valida el estado actual; `firma_ip` viene del cliente | `index.ts:192-253` |
| **NUEVO** | `PUT /produccion/ordenes/:id/material` escribe `estado_kanban='material_faltante'`, pero la migración `20260916` tiene `CHECK (estado_kanban IN ('pendiente','en_proceso','pausada','incompleta','en_espera','completada'))` → ese UPDATE debería fallar. Confírmalo y revisa qué etiquetas usa `OrderCard.tsx` | `index.ts:~2198-2218` |

## 1. Objetivo

Que aprobar una cotización ponga en marcha el flujo sin depender de acordarse de botones, **con una persona confirmando lo que cuesta dinero** (compras y órdenes de trabajo):

```
Aprobada ──(automático)──> estado_produccion + evento + cálculo de faltantes vs BOM
   ├─ faltan materiales ─> "Requisición: falta material"
   │      └─ (botón, prellenado) Generar compra ─> "Compra en curso"
   │             └─ Recibida (idempotente) ─> entrada de inventario ─> recalcula
   └─ nada falta ─────────> "Listo para producción"
          └─ (botón) Generar órdenes de trabajo ─> "En producción" ─> Kanban
                 └─ todas las OT completadas ─> "Surtido"
```

Decisiones ya tomadas (no las re-discutas; si ves un problema real, anótalo en el changelog y propón alternativa):

- **Automático:** cambiar `estado_produccion`, registrar evento, calcular faltantes.
- **Con confirmación humana:** crear compras y crear órdenes de trabajo (botones con datos prellenados).
- **Estados canónicos de `estado_produccion`** (una sola constante compartida en `types/index.ts` y usada en backend, Dashboard, lista y detalle):
  `Pendiente de aprobar` → `Aprobada` → `Requisición: falta material` → `Compra en curso` → `Listo para producción` → `En producción` → `Surtido`.
  Mapea los valores legacy (`Pendiente`, `En Producción`, `Entregado`) a los nuevos con un UPDATE en la migración (sección 4).
- **Toda la lógica de negocio va en el backend** (una sola fuente de verdad). El frontend solo muestra y dispara.

## 2. Alcance por sub-bloque

Trabaja **un sub-bloque a la vez**. Al terminar cada uno: `npm run build` en verde, una entrada en `CHANGELOG_ANTIGRAVITY.md` y un commit local (sin `git push` hasta que yo lo diga).

### 1A — Base: estados, eventos del servidor y aprobación
- Constante canónica de estados + tipo `EstadoProduccion` en `types/index.ts`. Corrige el filtro del Dashboard (`'Entregado'` → estado terminal `'Surtido'`).
- Helper de backend `registrarEvento(supabase, { cotizacion_id, organizacion_id, evento, usuario_id | null })`. Revisa en la migración `20260907_06` si `usuario_id` admite NULL (el portal no tiene usuario); si no, incluye el ALTER en la migración.
- Helper de backend `aplicarAprobacion(cotizacion)`: idempotente (si ya está `Aprobada` con `estado_produccion` avanzado, no retrocede nada), pone `estado_produccion`, registra evento y calcula faltantes (ver 1B).
- Llamarlo desde `PUT /cotizaciones/:id` **solo cuando `estado` pasa a `Aprobada`** (lee el estado previo antes de actualizar) y desde `POST /portal/:token/aprobar`.
- Evitar eventos duplicados: si el backend ya registra el cambio de estado, quita esa llamada en `App.tsx:manejarCambiarEstado` (deja las demás).
- **S4 en los 3 endpoints del portal:** validar expiración; permitir aprobar/rechazar/solicitar cambios solo si `estado === 'Enviada'`; tomar la IP de `x-forwarded-for` (ignora `firma_ip` del body); registrar evento con `usuario_id = null`.

### 1B — BOM y requisición inteligente
- Backend: `GET /productos/:id/materiales` y `PUT /productos/:id/materiales` (reemplaza la lista completa). Verifica que el producto y cada material pertenezcan a la organización. Solo `materia_prima` puede ser material.
- Backend: `GET /cotizaciones/:id/requisicion` → `[{ material_id, nombre, unidad, requerido, stock_disponible, faltante, costo }]`. `requerido = Σ(cantidad del item × cantidad_por_unidad)`; `stock_disponible = stock_actual - stock_reservado` (nulos = 0). Items sin BOM se ignoran (lista vacía = "nada falta"). Es la misma función que usa `aplicarAprobacion`.
- Frontend: en el formulario de producto, selector `tipo_item` y sección "Materiales (BOM)" para editar la lista. Usa el mismo estilo que el resto de `ProductosList`.
- Frontend: `GenerarRequisicionModal` se abre **prellenado con los faltantes**, muestra solo `materia_prima` (elimina el `|| true`), permite ajustar cantidades y elegir proveedor.
- Fuera de alcance: `proveedor_materiales` (no lo toques; déjalo anotado como pendiente).

### 1C — Compras e inventario correctos
- Folio de compra generado en el servidor (secuencia o `MAX+1` por organización dentro de la misma petición; documenta la elección). Quita el folio del cliente.
- Crear compra → `estado_produccion = 'Compra en curso'` + evento.
- Recepción **idempotente**: `UPDATE compras_proveedor SET estado='Recibida' … WHERE id=$1 AND estado <> 'Recibida'` y solo si afectó 1 fila se generan movimientos y stock. Sin esto, doble clic = stock duplicado.
- Stock atómico: función SQL `ajustar_stock(p_producto_id, p_delta)` (en la migración) y llámala con `supabase.rpc` en lugar de leer-luego-escribir.
- Tras recibir: recalcular la requisición de la cotización asociada; si ya no falta nada y estaba en `Requisición: falta material` / `Compra en curso` → `Listo para producción` + evento.

### 1D — Producción
- **Bug del CHECK:** en `PUT /produccion/ordenes/:id/material` usa un valor válido del CHECK (mira `OrderCard.tsx` y elige el que coincida con su etiqueta; mi sugerencia es `'incompleta'` cuando hay faltante y `'en_proceso'` al limpiar). No cambies el CHECK salvo que haya una razón sólida.
- `POST /cotizaciones/:id/generar-ordenes`:
  - Solo si la cotización está `Aprobada`.
  - **Idempotente:** si ya existen órdenes para esa cotización, devuelve las existentes (no duplica).
  - Detectar equipos por `producto_id` → `productos.tipo_item = 'producto_terminado'` (elimina la regla `< 10000`). Para items sin `producto_id`, conserva las palabras clave solo como respaldo y devuelve una advertencia en la respuesta.
  - Si falla `obtener_siguiente_produccion`, **error 500**, nunca un número aleatorio.
  - Inicializar campos Kanban: `linea_producto_id` (según el tipo de equipo; revisa `lineas_producto` y su seed), `fase_actual_id` = primera fase, `estado_kanban = 'pendiente'`.
  - Si `requisicion` aún tiene faltantes → responder 409 con la lista, salvo que llegue `force: true`. El botón del frontend pide confirmación y reintenta con `force`.
  - Al crear: `estado_produccion = 'En producción'` + evento.
- Al mover una orden a su **última fase** (`mover`), marcarla `completada`; cuando todas las OT de la cotización estén `completada` → `estado_produccion = 'Surtido'` + evento. Cada movimiento de Kanban y cada cambio de material registra evento.
- Frontend: `CotizacionDetalle` reemplaza los `alert()` de estos flujos por `toast` (sonner) y muestra los botones según el estado; añade un stepper/indicador de `estado_produccion`.

### 1E — Visibilidad
- Badge de `estado_produccion` en `CotizacionesList`/`CotizacionesTableModern` y en `CotizacionDetalle`.
- `TrazabilidadList` ya lee `cotizacion_eventos`: verifica que los eventos nuevos se vean bien (orden, usuario nulo → "Sistema/Cliente").

## 3. Fuera de alcance (no lo toques en este bloque)

Llaves versionadas (S1), fuga de costos en `GET /portal/:token` (S3), `/supa-proxy` (S5), límite de crédito (F4), `/produccion/import` (F5), roles operativos (F11), módulos por organización (F12), limpieza de scripts y código muerto (C1/C3), TypeScript/lint/tests (C2). Cada uno tendrá su bloque. Si algo te estorba, anótalo en el changelog en vez de arreglarlo aquí.

## 4. Migración SQL (yo la corro a mano)

Crea `supabase/migrations/20260918_01_flujo_aprobacion_produccion.sql`, idempotente (`IF NOT EXISTS`, `CREATE OR REPLACE`), con:
- Función `ajustar_stock(p_producto_id text, p_delta numeric)` (revisa el tipo real de `productos.id`; el BOM usa `TEXT`).
- `ALTER` de `usuario_id` a NULL en `cotizacion_eventos` si hace falta.
- Normalización de valores legacy de `estado_produccion`.
- Cualquier secuencia/índice que necesites para el folio.

No asumas que corrió: en el changelog dime exactamente qué SQL correr y en qué orden, y qué debo hacer **Rebuild** en EasyPanel.

## 5. Reglas técnicas (de AGENTS.md, no negociables)

- Cada ruta Hono nueva empieza con `const supabase = c.get("supabase") as any;` dentro del `try`.
- Filtra siempre por `organizacion_id` cuando uses el service client.
- Nunca parches con regex codiciosas: `.replace('string exacto', 'nuevo')`, o edita el archivo directamente.
- No escapes backticks en JSX.
- Colores solo con tokens semánticos (`bg-card`, `text-foreground`, `text-muted-foreground`, `border-border`…). Nada de `orange-500`, `slate`, `gray` ni hex nuevos.
- No dejes scripts sueltos en la raíz. No escribas llaves en ningún archivo.
- No dejes `.catch(() => [])` nuevos que oculten errores: muéstralos con `toast.error`.

## 6. Entrega y verificación

Al final de cada sub-bloque, en el changelog: archivos tocados, qué cambió y por qué, acciones manuales (SQL / Rebuild), y **cómo probarlo** con pasos concretos. Al cerrar el bloque, deja el escenario de prueba completo:

1. Producto terminado con BOM de 2 materiales; uno con stock suficiente y otro sin stock.
2. Cotización → enviar → aprobar **desde el portal** → debe quedar `Requisición: falta material` con evento.
3. Generar compra prellenada → `Compra en curso`.
4. Marcar Recibida **dos veces** → el stock sube una sola vez → `Listo para producción`.
5. Generar órdenes de trabajo dos veces → no se duplican → `En producción`, aparecen en el Kanban en la primera fase.
6. Mover al final → `Surtido`. Trazabilidad muestra la historia completa.
7. Reportar en el changelog qué pasos pasaron y cuáles no pudiste probar.
