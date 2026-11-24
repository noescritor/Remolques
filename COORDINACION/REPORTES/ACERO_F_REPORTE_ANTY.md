# Reporte Bloque F — Acero (XML de factura → precios, editor de material, alias compartidos)

- **Rama:** `acero-f-2026-11-23` (creada desde `main` `350ae22`, sin merge ni push)
- **Worktree:** `C:\Users\luisa\Downloads\proyectos_antygravity\Remolques_acero_f`
- **Fecha:** 2026-11-24
- **Autor:** Antigravity (para revisión de Claude)

---

## §0. Hallazgos previos a codificar (esquema e importador actual)

1. **Descuentos en CFDI (`cfdi_parser.ts` / `factura_proveedor_partidas`)**:
   - `cfdi_parser.ts` guarda cada concepto con `tipo = 'concepto'` y su `importe` bruto, y los descuentos en filas separadas `tipo = 'descuento'` sin FK hacia el concepto concreto.
   - Por ello, `obtenerPropuestaAceroCfdi` calcula `precio_neto_mxn = (importe / cantidad) * tipo_cambio * factor_conversion`, detecta si la factura tiene partidas `tipo = 'descuento'` (o `facturas_proveedor.descuento > 0`), y enciende `descuento_en_factura: true` con el aviso visible `"Esta factura trae descuentos; revisa el precio unitario antes de aplicar."`.
2. **Claves de unidad SAT (`clave_unidad`)**:
   - En pruebas y facturas actuales aparece `H87` (pieza). Tabla soportada en `clasificarUnidadCfdi`:
     - **Pieza** (`H87`, `EA`, `C62`, `PZA`, `PIEZA`, `XUN`, `ACT`): `factor = 1` por defecto.
     - **Peso** (`KGM`, `GRM`, `TNE`, `LBR`): `requiere_factor: true` — bloqueada hasta que el comprador captura el factor explícito (`kg/pieza`) o exista un alias previo con factor confirmado.
     - **Otras** (`MTR`, `E48`, etc.): `revisar_unidad: true` con factor editable y aviso visible.
3. **Nombre del emisor y `NoIdentificacion`**:
   - `facturas_proveedor` no guarda el nombre del emisor del XML directamente (solo `proveedor_id` → `proveedores.nombre` y `uuid_fiscal`); el RFC y razón social del emisor viven en `facturas_proveedor_cfdi` (`rfc_emisor`, `nombre_emisor`).
   - `NoIdentificacion` se parsea en `cfdi_parser.ts` pero **no** se persiste en `factura_proveedor_partidas`. No se tocó `cfdi_parser.ts` ni `importarCFDIsMotor` (regla del bloque).

---

## 1. Archivos creados y modificados

### Base de datos y documentación
- `supabase/migrations/20261125_01_acero_f.sql`:
  - `catalogo_alias_factura` (tabla compartida con futuro Bloque G: `destino_tipo IN ('acero_material', 'producto')`, índice único por `(organizacion_id, proveedor_id, COALESCE(clave_sat, ''), descripcion_normalizada)`, RLS por `get_current_org_id()`).
  - `acero_precios_cfdi_aplicados` (evita doble aplicación de una partida con `UNIQUE(partida_id)`).
  - Columnas aditivas en `acero_precios_historial`: `fuente`, `factura_id`, `incluye_iva`.
  - RPC `aplicar_precios_acero_cfdi(p_org, p_usuario, p_factura_id, p_lineas)` (`SECURITY DEFINER`, atómico todo-o-nada, valida factura no cancelada, partida de la factura/org, no duplicada en el lote, no aplicada previamente, factor > 0, USD con TC > 0, fecha anterior y variación > 30% requieren bandera explícita, actualiza `acero_precios` con `incluye_iva = false`, inserta historial y upserta `catalogo_alias_factura`).
  - RPC `renombrar_proveedor_acero(p_org, p_de, p_a)` (`SECURITY DEFINER`, bloquea con `proveedor_conflicto` si existe cualquier material con precio bajo ambos nombres, actualiza `acero_precios`, `acero_precios_historial`, `acero_precios_cfdi_aplicados` y `catalogo_alias_factura`).
- `docs/acero/verificacion_F.sql` y `docs/acero/contrato_esquema_real.md`.

### Backend (`supabase/functions/make-server-feea4382/`)
- `motor/acero_cfdi.ts` (autocontenido para `Dockerfile.backend`) y `motor/acero_cfdi.test.ts`.
- `motor/acero.ts` y `motor/acero.test.ts`:
  - `actualizarMaterialAcero` acepta `tipo` explícito (validado contra los 8 tipos), **no** pisa `tipo` al renombrar, y recalcula `ancho_ft`/`largo_ft` solo cuando el tipo resultante es `placa` o `lamina`.
  - `guardarPrecioAcero` guarda `fuente` e `incluye_iva` también en `acero_precios_historial`.
- `index.ts`: nuevas rutas:
  - `GET /acero/cfdi/:facturaId/propuesta`
  - `POST /acero/cfdi/:facturaId/aplicar`
  - `POST /acero/proveedores/renombrar`
  - `GET /catalogo-alias` (`?destino_tipo=`)
  - `DELETE /catalogo-alias/:id`

### Frontend (`src/app/`)
- `utils/aceroCalc.ts`: **bug real detectado y corregido en `compararProveedores`** — anteriormente ignoraba `p.incluye_iva` por fila y aplicaba el flag global `incluyeIva` a todos los precios, lo que distorsionaba comparaciones mixtas (XML sin IVA vs manual con IVA). Ahora normaliza cada fila a la misma base antes de sumar y elegir `mejorProveedorCompleto` / `mejorPorRenglon` (100% retrocompatible con las pruebas doradas del Excel).
- `utils/aceroApi.ts`: clientes tipados para propuesta, aplicar, renombrar proveedor y gestión de alias.
- `components/Calculadora/AplicarPreciosAceroCfdiModal.tsx`: propuesta desde factura XML con 3 orígenes (`Recordado` / `Sugerido` / `Sin sugerencia`), selector de proveedor (+ nuevo), factor editable (obligatorio en `KGM`), comparación Actual → Nuevo sin IVA y `%`, confirmación explícita de fecha anterior y variación >30%, bloqueo anti-doble clic (`guardandoRef`), preservación de estado en errores y acceso directo a la matriz.
- `components/Calculadora/GestionAliasAceroModal.tsx`: listado buscable y eliminación de alias guardados.
- `components/Finanzas/CxpFacturasTab.tsx`: botón `Acero` en facturas no canceladas.
- `components/Calculadora/PreciosAcero.tsx`: editor de material (Nombre, Tipo, Notas, Activo), selector de Tipo en Nuevo Material, toggle `Incluye IVA` / `Sin IVA` en edición de celda, visualización de `s/IVA` y `fuente` en matriz e historial, renombrar proveedor desde encabezado de columna con manejo de conflicto 409, y botón `Gestionar alias`.
- `components/Calculadora/CosteoPlaca.tsx`: confirmada edición de factor ×1.5 y reemplazada la nota antigua por `"El factor cubre mano de obra y proceso de la placa trabajada. El precio de la matriz es siempre el de la placa sin factor."`.

### Utilidades locales de desarrollo y E2E (O8)
- `scripts/dev/local_supabase_bridge.cjs`: puente PostgREST + Auth + RPC sobre PostgreSQL local (lee `PGHOST`, `PGPORT`, `PGUSER`, `PGPASSWORD`, `PGDATABASE`, `BRIDGE_PORT` desde `process.env`, cero llaves incrustadas).
- `scripts/dev/seed_acero_f.sql`: semilla reproducible de facturas de prueba (`FAC-ACERO-101`, `FAC-ACERO-VIEJA`, `FAC-CANCELADA-99`) con alias `Placa` → `Placa`.
- `scripts/dev/test_acero_f_browser.cjs`: prueba E2E de navegador en Chrome headless + CDP sin rutas hardcodeadas.

---

## 2. Cómo levantar el puente local y correr el E2E de navegador

```powershell
# 1. Postgres 17 local en 54331 con BD clonada y migrada (ej. test_acero_f)
#    Sembrar datos de prueba:
psql -h 127.0.0.1 -p 54331 -U tester -d test_acero_f -v ON_ERROR_STOP=1 -f scripts/dev/seed_acero_f.sql

# 2. Puente REST/Auth/RPC local en 54321
$env:PGDATABASE="test_acero_f"; $env:PGPORT="54331"; $env:PGUSER="tester"; $env:PGPASSWORD="tester"; $env:BRIDGE_PORT="54321"
node scripts/dev/local_supabase_bridge.cjs

# 3. Backend Deno en 8000
Set-Location supabase/functions/make-server-feea4382
$env:SUPABASE_URL="http://127.0.0.1:54321"; $env:SUPABASE_ANON_KEY="local-anon"; $env:SUPABASE_SERVICE_ROLE_KEY="local-service"; $env:PORT="8000"
deno run --allow-net --allow-env --allow-read index.ts

# 4. Frontend Vite en 5173
Set-Location ..\..\..
$env:VITE_API_URL="http://127.0.0.1:8000"; $env:VITE_SUPABASE_URL="http://127.0.0.1:54321"; $env:VITE_SUPABASE_ANON_KEY="local-anon"
npx vite --port 5173 --strictPort

# 5. Ejecutar prueba E2E de navegador (genera COORDINACION/EVIDENCIA/acero_f_01..05_*.png)
node scripts/dev/test_acero_f_browser.cjs
```

---

## 3. Verificación realizada

1. **PostgreSQL 17 real (`test_acero_f`, clon de `remolques` + `20261102_03` + `20261125_01`)**:
   - Migración aplicada **2 veces seguidas** con `ON_ERROR_STOP=1`: idempotente sin errores.
   - **No regresión de precios/materiales existentes**: MD5 antes = después (`acero_materiales`: `5ec9ac836f92d2a7cfd6b145528b6979`, `acero_precios`: `c47860e9de29ddd6bd33f631608dc1b5`).
   - `docs/acero/verificacion_F.sql`: `VERIFICACION_F_OK` (rollback todo-o-nada, duplicados en lote, reaplicación bloqueada, fecha vieja bloqueada, ±30% bloqueado, renombre de proveedor con y sin conflicto, RLS org B).
   - **Concurrencia real en 2 sesiones** sobre `aplicar_precios_acero_cfdi`: sesión 1 `ok: true`, sesión 2 `ERROR: partida_ya_aplicada`.
   - Base desechable `test_acero_f` eliminada al terminar.
2. **Pruebas Deno y mutaciones**:
   - Base en `main` (`350ae22`): `288 passed | 0 failed` en `motor/`.
   - Pruebas nuevas: `motor/acero_cfdi.test.ts` (7/7), `motor/acero.test.ts` (5/5, +1 nueva de editor de `tipo`), `src/app/utils/aceroCalc.test.ts` (9/9 doradas del Excel).
   - **Mutaciones (`mutar_f.cjs`)**: **8/8 mutantes matados** (`umbral_variacion_ge`, `umbral_variacion_40`, `fecha_anterior_le`, `descuento_ignorado`, `usd_sin_tc`, `factor_ignorado`, `kgm_no_bloquea`, `empate_elige_uno`).
3. **Navegador real (Chrome headless + CDP contra Postgres real + Deno + Vite)**:
   - Factura abierta muestra `Acero`, cancelada no (`FAC-CANCELADA-99`).
   - Corte de API en carga de propuesta → error visible + `Reintentar`.
   - Propuesta `FAC-ACERO-101`: 3 orígenes (`Recordado`, `Sugerido`, `Sin sugerencia`), aviso de descuento, `KGM` bloqueada hasta capturar factor `45`.
   - Corte de API al aplicar → alerta visible sin perder selección ni factor `45`.
   - Aplicación real con doble clic rápido → `2 precio(s) actualizado(s)`, ambas pasan a `Ya aplicada` (reaplicar bloqueado).
   - `FAC-ACERO-VIEJA` (USD TC 20, fecha `2026-10-10`, variación `+93.94%`) → muestra ambas casillas de confirmación.
   - Matriz `Precios de acero` refleja `$1,102.50 · s/IVA · CFDI ...` sin recargar; editor de material guarda `tipo`; `Gestionar alias` lista alias guardado.
   - `Costeo de placa`: factor `1.5` editable y nota exacta visible.
   - Responsive: `768px` (`scrollWidth = 768`) y `375px` (`scrollWidth = 375`), `0` errores de consola, `0` `alert()`/`confirm()` bloqueantes.
   - Capturas inspeccionadas visualmente en `COORDINACION/EVIDENCIA/acero_f_01..05_*.png`.
4. **No se tocó ninguna tabla/archivo prohibido**:
   - Cero cambios en `receta_base`, `costos_modelo`, `procesos_manufactura`, `opcion_costos`, `productos`, `cotizaciones`, `cfdi_parser.ts` ni `importarCFDIsMotor`.

---

## 4. Orden de despliegue y comportamiento con piezas faltantes

1. **Primero SQL**: ejecutar `supabase/migrations/20261125_01_acero_f.sql` en el SQL Editor de Supabase.
2. **Segundo Backend**: Rebuild de `remolques-api` en EasyPanel.
3. **Tercero Frontend**: Rebuild/deploy de `remolques-web` en EasyPanel.
- *Si solo se despliega SQL*: sin impacto; es 100% aditivo.
- *Si se despliega Frontend antes de Backend*: el botón `Acero` en CxP y `Gestionar alias` mostrarán error de carga con botón `Reintentar` (no pantalla en blanco ni falsos vacíos); la matriz actual sigue operando normal.
- *Si se despliega Backend antes de SQL*: las rutas existentes `/acero/catalogo`, `/acero/precios`, `/acero/materiales` siguen funcionando; `/acero/cfdi/*` y `/catalogo-alias` devolverán error hasta correr la migración.

---

## 5. Correcciones de Ronda 2 (revisión de Claude sobre `ee5875b`)

- **D1 (Base común de IVA en variación ±30%):** se añadió la función pura SQL `acero_precio_base_sin_iva(precio, incluye_iva)` (con `c_tasa_iva CONSTANT NUMERIC := 0.16`) usada en `aplicar_precios_acero_cfdi`, y su equivalente `precioBaseSinIva` (`TASA_IVA_ACERO = 0.16`) en `motor/acero_cfdi.ts` (`evaluarBanderas` y `obtenerPropuestaAceroCfdi`, que ahora expone `precio_actual_sin_iva` y `precios_actuales[].precio_sin_iva`). El modal consume directamente `banderas.variacion_pct` / `variacion_alta` del servidor (y si el usuario cambia material/proveedor/factor en vivo, recalcula sobre `precio_sin_iva` del servidor con la misma constante). Verificado en Postgres real (C1 y C2 pasan).
- **D2 (`renombrar_proveedor_acero`):** ahora actualiza también `acero_precios_historial.proveedor` y `acero_precios_cfdi_aplicados.proveedor` dentro del mismo RPC (corregida la omisión anterior y el reporte). Verificado en Postgres real (C6b, C6c y C6d pasan: el guardián de fecha anterior sigue bloqueando tras renombrar).
- **D3 (Factor obligatorio en unidades de peso en servidor y modal):** `aplicar_precios_acero_cfdi` distingue `factor_conversion` omitido de `1` (con `factor_confirmado`) y rechaza con `factor_requerido` (mapeado a 400 en español) cualquier partida `KGM`/`GRM`/`TNE`/`LBR` sin factor explícito y confirmado (C3 pasa). `aplicarPreciosAceroCfdi` no inventa `1` cuando viene omitido, y `AplicarPreciosAceroCfdiModal.tsx` eliminó el fallback silencioso `: 1`.
- **D4 (Cobertura de pruebas y mutaciones):** se agregaron pruebas con cliente simulado en `motor/acero_cfdi.test.ts` para aislamiento de organización en propuesta y borrado de alias, materiales inactivos, aviso de descuento por cabecera, fallback de alias sin `clave_sat`, factor/proveedor del alias, filtro `destino_tipo = 'acero_material'`, paginación >1000 filas, líneas vacías, límites `importe=0`/`cantidad=0`, redondeo a 4 decimales y margen exacto `0.05`. En `arnes_revision_f/mutar_f2.cjs`: **25/25 mutantes aplicables matados, 0 vivos** (los 5 `no_aplica` corresponden a líneas mejoradas en R2 para O6/D3/O7, todas cubiertas por pruebas directas).
- **O1 (Comparador de acero):** interruptor renombrado a `"Mostrar resultados con IVA"` / `"Mostrar resultados sin IVA"` en `ComparadorAcero.tsx` (sin cambiar nada más del comparador) + prueba dorada en `acero_cfdi.test.ts` con `incluyeIva: false` y filas mixtas `incluye_iva: true/false`.
- **O2 (Normalización de proveedor en RPC):** `aplicar_precios_acero_cfdi` y `renombrar_proveedor_acero` normalizan con `UPPER(TRIM(...))` (C7 pasa: `tpi-nuevo` actualiza `TPI-NUEVO` sin duplicar columna).
- **O3 (Contradicciones en sugerencia de material):** `sugerirMaterial` ahora anula candidatos con contradicción de acabado (`galvanizada` vs `negra`), calibre explícito (`Cal 18` vs `Cal 10`) o medida `NxM` (`PTR 3X3` vs `PTR 4"`). Resultado en `arnes_revision_f/sug.ts` sobre el catálogo real: **16 aciertos, 5 sin sugerencia aceptables, 0 errores**.
- **O4 (`precioDesdeConcepto`):** documentado con JSDoc el parámetro opcional `descuento` y por qué `obtenerPropuestaAceroCfdi` usa el importe bruto + bandera `descuento_en_factura`.
- **O6 (Deadlock en actualizaciones concurrentes):** `aplicar_precios_acero_cfdi` bloquea los `acero_materiales` del lote en orden determinista (`ORDER BY id FOR UPDATE`), y `mapearErrorRpcAceroCfdi` mapea `40P01` (`deadlock_detected`) a `409`.
- **O7 (4.º parámetro `proveedor` en `/propuesta`):** implementado `proveedorOverride?: string` en `obtenerPropuestaAceroCfdi` y cubierto en prueba unitaria.
- **O8 (Reproducibilidad E2E):** commiteados `scripts/dev/seed_acero_f.sql` (corrigiendo el alias `Recordado` para que apunte a una `Placa` real y no a un `PTR`) y `scripts/dev/test_acero_f_browser.cjs`; E2E re-ejecutado en verde (`E2E_ACERO_F_OK`, 0 errores de consola, capturas actualizadas).

### Verificación de Ronda 2
- `arnes_revision_f/rev_f.sql` (Postgres 17 real, migración aplicada ×2 con `ON_ERROR_STOP=1`): **18/18 `PASA`** (C1, C2, C3, C4a–d, C5, C6a–d, C7, C8, C9, C9b–d).
- `arnes_revision_f/mutar_f2.cjs`: **25 muertos, 0 vivos**.
- `arnes_revision_f/sug.ts`: **bien=16, sin_sugerencia_aceptable=5, errores=0**.
- `scripts/dev/test_acero_f_browser.cjs`: **`E2E_ACERO_F_OK`** (`placaAPlaca: true`, `CHECK_COMPARADOR_O1: true`, `768px`/`375px` sin desbordamiento, `0` errores de consola).

---

## 6. Preguntas abiertas

- Ninguna bloqueante. Nota informativa para Bloque G: `catalogo_alias_factura` ya quedó lista con `destino_tipo IN ('acero_material', 'producto')`, índice único por `(organizacion_id, proveedor_id, COALESCE(clave_sat, ''), descripcion_normalizada)` y endpoints `GET /catalogo-alias?destino_tipo=...` / `DELETE /catalogo-alias/:id`.
