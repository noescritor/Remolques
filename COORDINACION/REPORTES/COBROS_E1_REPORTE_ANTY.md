# Reporte de Implementación — Bloque E1 (Cobros, plan de pagos y cobranza por equipo)

**Rama:** `cobros-e1-2026-11-22`  
**Worktree:** `C:\Users\luisa\Downloads\proyectos_antygravity\Remolques_cobros_e1`  
**Base (`main`):** `187992a`  

---

## §0. Hallazgos previos a la migración (cómo nacen las órdenes desde una cotización)

1. **`generarOrdenesDeCotizacion` (`motor/generar_ordenes_cotizacion.ts`)**:
   - Recorre `cotizacion.items` filtrando los conceptos que corresponden a equipos/remolques e inserta `cantidad = Math.max(1, Math.round(Number(item.cantidad) || 1))` filas individuales en `ordenes_trabajo`.
   - En `ordenes_trabajo.caracteristicas` guarda `{ item_id, unidad: i + 1, descripcion_corta, ficha }`, **sin** guardar precio unitario ni subtotal.
   - Debido a que una cotización puede mezclar accesorios/servicios no productivos, IVA global o por partida (`con_factura`), descuentos y costos indirectos prorrateados en `cotizaciones.total`, **no existe un valor económico automático confiable por equipo**. Por ello se implementó la tabla opcional `equipo_valor_cobranza` (valor pactado manual por equipo).
2. **Estado real de datos en BD local (`remolques`)**:
   - `pagos`: 2 registros vigentes (`Transferencia`), 0 con `monto <= 0`, 0 con `'Crédito 30 días'`.
   - `cotizaciones` con más de 1 orden: 0 (las cotizaciones `8b2edadd-...` y `fbdd977b-...` tienen 1 orden).
   - `vista_saldo_cliente`: 113 filas (3 con saldo distinto de cero: `66000.00`, `98600.00`, `66000.00`).

---

## 1. Diseño implementado

### Base de datos (`supabase/migrations/20261123_01_cobros_e1.sql`)
- Extensión aditiva e idempotente de `pagos`: `estado` (`'vigente' | 'anulado'`), `anulado_at`, `anulado_por`, `motivo_anulacion`, `notas`, `descripcion_especie`, `pagos_estado_check` y `pagos_monto_positivo_check NOT VALID`.
- Tablas nuevas con RLS por organización (`get_current_org_id()`) y `GRANT` explícitos a `authenticated`:
  - `pago_aplicaciones` (con trigger `trg_validar_pago_aplicacion` que valida pertenencia de pago y orden a la misma organización/cotización y que la suma aplicada no exceda el monto del cobro).
  - `equipo_valor_cobranza` (valor pactado manual opcional por orden).
  - `planes_pago` y `plan_pagos_parcialidades`.
- Vistas (`security_invoker = true`): `v_cobranza_cotizacion`, `v_cobranza_equipo`, `v_plan_parcialidades_estado` (cálculo FIFO por `fecha_vencimiento ASC, numero ASC`) y actualización de `vista_saldo_cliente` conservando exactamente sus 4 columnas (`cliente_id, organizacion_id, limite_credito, saldo_usado`) y filtrando `AND p.estado = 'vigente'`.
- Funciones atómicas `SECURITY DEFINER` con `FOR UPDATE` y `GRANT EXECUTE ... TO service_role`:
  - `registrar_cobro`: valida estado cobrable (`Aprobada` / `Pagada`), descripción obligatoria para `Especie`, exceso sobre saldo (exige `p_permitir_saldo_a_favor = true`), inserta aplicaciones por equipo y transiciona `Aprobada` → `Pagada` cuando `cobrado >= total - 0.005`.
  - `anular_cobro`: exige `motivo`, marca `estado = 'anulado'`, `anulado_at`, `anulado_por`, `motivo_anulacion` (idempotente si ya estaba anulado) y revierte `Pagada` → `Aprobada` si el saldo vuelve a ser positivo.

### Backend (`motor/cobros.ts` y `index.ts`)
- Rutas nuevas: `GET /cobros`, `POST /cobros`, `POST /cobros/:id/anular`, `GET /cobranza/cotizacion/:id`, `GET /cobranza/equipo/:ordenId`, `PUT /cobranza/equipo/:ordenId/valor`, `GET/POST/PUT/DELETE /planes-pago`.
- Actualización de `GET /pagos` y `GET /pagos/cotizacion/:cotizacionId` (paginación `.range()` en bloques de 1000 y exclusión de `estado = 'anulado'` por defecto, `?incluir_anulados=1` opcional) y `POST /pagos` delegando a `registrar_cobro`.
- `motor/cobros.ts` es autocontenido dentro de `supabase/functions/make-server-feea4382/` para compatibilidad con el contexto de `Dockerfile.backend`.

### Frontend
- `src/app/utils/cobros.ts`: funciones puras (`redondear2`, `saldoCotizacion`, `estatusParcialidad`, `imputarCobrosAParcialidades`, `repartirEnPartesIguales`, `validarAplicaciones`, `validarPlanParcialidades`, `validarDatosCobro`, `traducirErrorCobros`).
- `src/app/components/Cobros/`: `CobranzaTabPanel.tsx`, `RegistrarCobroModal.tsx` (soporte `Especie`, reparto en partes iguales, confirmación explícita de saldo a favor, protección síncrona `guardandoRef` contra doble clic y preservación de datos en error de red), `PlanPagosModal.tsx` y `AnularCobroModal.tsx`.
- Integración en `ExpedienteEquipoPage.tsx` (pestaña `Cobranza`), `CuentasPorCobrar.tsx` (exclusión de anulados, `Especie`, bloqueo doble clic y enlace `/cotizaciones/:id`) y `CotizacionDetalle.tsx` (`Especie` e indicador de anulados).

---

## 2. Orden de despliegue

1. Ejecutar `supabase/migrations/20261123_01_cobros_e1.sql` en el SQL Editor de Supabase (idempotente).
2. Hacer **Rebuild** de `remolques-api` en EasyPanel.
3. Hacer **Rebuild** de `remolques-web` en EasyPanel.

---

## 3. Verificaciones ejecutadas

- **Migración idempotente en PostgreSQL 17 (`test_cobros_e1`)**: aplicada 2 veces con `ON_ERROR_STOP=1` sin errores; `vista_saldo_cliente` mantuvo idénticas las 3 filas con saldo (`66000.00`, `98600.00`, `66000.00`).
- **Verificador SQL (`docs/cobros/verificacion_E1.sql`)**: `VERIFICACION_E1_OK` (incluye transición `Aprobada` → `Pagada` → `Aprobada`, rechazo de borrador/exceso/especie sin descripción, FIFO en `v_plan_parcialidades_estado`, `vista_saldo_cliente` excluyendo anulados y aislamiento RLS entre organizaciones).
- **Concurrencia real en 2 sesiones paralelas (`test_cobros_e1`)**:
  - Dos `registrar_cobro` simultáneos de `$60,000` sobre cotización de `$100,000`: 1 éxito (`cobrado: 60000.00, saldo: 40000.00`) y 1 rechazo (`ERROR: saldo_excedido`).
  - Dos `anular_cobro` simultáneos sobre el mismo pago: 1 anulación efectiva (`ya_anulado: false`) y 1 respuesta idempotente (`ya_anulado: true`).
- **Pruebas Deno**:
  - `cobros_utils.test.ts`: 10/10 pasan.
  - `motor/cobros.test.ts`: 5/5 pasan (incluye paginación >1000 filas, aislamiento por organización y `3 × 33,333.33`).
  - Mutaciones en `src/app/utils/cobros.ts` (`mutar_e1.cjs`): **9/9 mutantes matados, 0 vivos**.
  - Suite Deno completa desde la raíz: **284 passed | 0 failed** (y **399** en `verificar.mjs`).
- **E2E en navegador (Chrome headless + shim Supabase local + API Deno + Vite)**:
  - `E2E_COBROS_E1_OK` (`consoleErrorsCount: 0, dialogsCount: 0`): corte de API en carga + Reintentar, reparto en partes iguales entre 2 equipos + corte en POST preservando datos + doble clic síncrono, pago `Especie` → `Pagada`, anulación → `Aprobada`, excedente bloqueado sin confirmación y aceptado como `Saldo a favor: $10,000.00`, orden manual sin cotización, vista `Cuentas por Cobrar` (`/cxc`) y `CotizacionDetalle` (`/cotizaciones/:id`), y responsive 768px / 375px sin scroll horizontal.
  - Evidencia en `COORDINACION/EVIDENCIA/cobros_e1_01..06_*.png`.

---

## 4. Preguntas abiertas / Alcance futuro (E2)

- La definición de `valor_pactado` por equipo es manual y opcional (`equipo_valor_cobranza`), ya que `ordenes_trabajo` no guarda desglose económico unitario al generarse desde `cotizaciones`.
- No se modificaron tablas ni lógica de precios, costeo ni despiece de almacén.
