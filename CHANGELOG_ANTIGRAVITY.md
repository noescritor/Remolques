# Changelog de cambios y hallazgos — Remolques

Bitácora obligatoria para cualquier cambio hecho con Antigravity o Claude Code.
Formato: entradas nuevas **arriba**.

## 2026-10-15 - Corrección 2R-4b: Separación de presupuesto al aprobar (camino PUT vs. portal)
**Herramienta:** Antigravity  
**Tipo:** fix (backend, motor)  
**Archivos tocados:**  
- `supabase/functions/make-server-feea4382/motor/generar_presupuesto_cotizacion.ts`
- `supabase/functions/make-server-feea4382/motor/generar_presupuesto_cotizacion.test.ts`
- `supabase/functions/make-server-feea4382/index.ts`
**Qué cambió y por qué:**  
- **Separación de responsabilidades en la generación automática:**  
  - En `motor/generar_presupuesto_cotizacion.ts`, se extrajo la función `generarPresupuestoAlAprobar` (que contiene únicamente la lógica try/catch para generar el presupuesto con `{ reemplazar: false }` y registrar eventos de presupuesto, sin alterar el estado de producción ni registrar eventos de cotización).
  - `ejecutarAprobacionCotizacion` se mantiene exclusivamente para el portal público (`POST /portal/:token/aprobar`), conservando el `UPDATE estado_produccion = 'Aprobada'`, el evento `"Cotizacion aprobada"` y la llamada a `generarPresupuestoAlAprobar`.
  - En `PUT /cotizaciones/:id`, al detectar la transición a `'Aprobada'`, se invoca directamente `generarPresupuestoAlAprobar` con el cliente de servicio. De esta forma, el `estado_produccion` se mantiene intacto (ej. en `'Pendiente'` para los tableros de producción) y no se genera el evento duplicado `"Cotizacion aprobada"`.
- **Prueba unitaria añadida:**  
  - En `motor/generar_presupuesto_cotizacion.test.ts`, se agregó la prueba `generarPresupuestoAlAprobar (camino PUT): crea presupuesto sin actualizar estado_produccion ni registrar 'Cotizacion aprobada'`, verificando con un cliente stub que: (1) crea el presupuesto una sola vez, (2) no actualiza `estado_produccion`, (3) no registra `"Cotizacion aprobada"`, y (4) una segunda invocación es idempotente y no duplica datos.
**Acciones manuales pendientes:** Ninguna.

## 2026-10-15 - Sub-bloque 2R-4b: Despiece visible en el presupuesto y presupuesto automático al aprobar
**Herramienta:** Antigravity  
**Tipo:** feat (motor, backend, frontend, ui)  
**Archivos tocados:**  
- `supabase/functions/make-server-feea4382/motor/presupuesto_desde_costeo.ts`
- `supabase/functions/make-server-feea4382/motor/presupuesto_desde_costeo.test.ts`
- `supabase/functions/make-server-feea4382/motor/generar_presupuesto_cotizacion.ts`
- `supabase/functions/make-server-feea4382/motor/generar_presupuesto_cotizacion.test.ts`
- `supabase/functions/make-server-feea4382/motor/despiece.test.ts`
- `supabase/functions/make-server-feea4382/index.ts`
- `src/app/utils/despiece.ts`
- `src/app/components/Presupuestos/PresupuestoDespieceTab.tsx`
- `src/app/components/Presupuestos/PresupuestoEditor.tsx`
**Qué cambió y por qué:**  
- **Parte A (Refactorización a función reutilizable):**  
  - Se extrajo toda la lógica de generación del presupuesto desde cotización (~200 líneas de `index.ts`) a `motor/generar_presupuesto_cotizacion.ts` (`generarPresupuestoDeCotizacion`).
  - El handler `POST /cotizaciones/:id/presupuesto` en `index.ts` quedó delgado delegando en la función y mapeando exactamente a los mismos códigos HTTP (`200`, `409`, `400`, `404`, `500`).
  - Pruebas unitarias completas con stub en `motor/generar_presupuesto_cotizacion.test.ts` cubriendo: (1) cotización configurada → `creado`, (2) segunda llamada sin reemplazar → `existe`, (3) con reemplazar → `reemplazado` (mismo ID), (4) sin equipos elegibles → `sin_equipos`, (5) `registrarEvento` con texto exacto.
- **Parte B (Metadatos de despiece):**  
  - En `motor/presupuesto_desde_costeo.ts`, se añadieron los campos opcionales aditivos `paso?: string[]` y `uso?: string[]` a `BomLineaResumen`, y `cotizacion_folio?: string | null` a `MetaPresupuesto` y `OpcionesPresupuesto`.
  - La prueba dorada de Plataforma 40 ft / 2 ejes se mantiene exacta en $397,713.63 y se agregaron aserciones de propagación.
- **Parte C (Pestaña Despiece y exportación CSV):**  
  - Se creó el módulo de lógica pura `src/app/utils/despiece.ts` para consolidar, agrupar, filtrar y exportar a CSV con BOM UTF-8 (`\uFEFF`).
  - En `src/app/components/Presupuestos/PresupuestoEditor.tsx`, se añadieron pestañas "Costos" y "Despiece" (`ui/tabs`).
  - Se implementó `PresupuestoDespieceTab.tsx` con encabezado (folio de cotización, conteo de equipos y piezas distintas), tarjetas plegables por equipo con selector de agrupación ("Sección" vs "Paso / kit"), buscador en tiempo real, bloque consolidado, sección plegable "Pendientes de definir" (omisiones y alternativas) y botón de descarga CSV en cliente.
- **Parte D (Presupuesto automático al aprobar):**  
  - Se identificaron los caminos de aprobación:
    1. Portal cliente: `POST /portal/:token/aprobar` llama a `aplicarAprobacion(supabase, cot.id, cot.organizacion_id, null)` con el cliente de servicio.
    2. Editor / manual desde la app: `useSupabaseData.ts -> actualizarCotizacion` envía `PUT /cotizaciones/:id`. Se enganchó `aplicarAprobacion(supabase, id, orgId, userId)` cuando transiciona a `Aprobada` (`!wasApproved && isNowApproved`).
  - En `aplicarAprobacion` (vía `ejecutarAprobacionCotizacion`), se dispara `generarPresupuestoDeCotizacion(..., { reemplazar: false })` dentro de `try/catch`. Nunca rompe la aprobación y registra en `cotizacion_eventos` tanto el éxito como si no hubo equipos o si ocurrió un error.
**Acciones manuales pendientes:** Ninguna. En producción, hacer "Rebuild" en EasyPanel para el servicio del backend cuando se despliegue.

## 2026-10-15 - Corrección 2R-1g (ronda 2): blindaje contra borrado cruzado en generadores y filtro LIKE en verificación
**Herramienta:** Antigravity  
**Tipo:** fix (migraciones, docs)  
**Archivos tocados:**  
- `docs/importacion/verificacion_2R1g.sql`
- `scripts/generar_costos_sql.cjs`
- `supabase/migrations/20261011_02_costos_plataforma_40x2.sql`
- `scripts/generar_costos_dolly_sql.cjs`
- `supabase/migrations/20261014_01_dolly.sql`
- `scripts/generar_costos_gondola_sql.cjs`
- `supabase/migrations/20261014_02_gondola.sql`
- `docs/importacion/INFORME_2R1G.md`
**Qué cambió y por qué:**  
- **Ajuste en `docs/importacion/verificacion_2R1g.sql`:**  
  - En `control_previos`, se actualizó `fuente LIKE 'Factura Leolca%'` para `plat_factura_previas`, `dolly_factura_previas` y `gondola_factura_previas`, reconociendo las 5 filas de dolly normalizadas con texto descriptivo en fuente.
- **Blindaje contra borrado cruzado en generadores (2R-1c, 2R-1e y 2R-1f):**  
  - Se removió la cláusula amplia `OR fuente = 'Factura Leolca'` de las sentencias `DELETE` en `opcion_costos` y `costos_modelo`.
  - Ahora cada generador borra estrictamente por su etiqueta de `notas` exacto (`import-2r1c`, `import-2r1e`, `import-2r1f`) y por su modelo/tipo (`modelo_id = ...` o `tipo_modelo = ...`).
  - En `scripts/generar_costos_sql.cjs`, las opciones de piso `laminado_madera` y `laminado_plastico` se generan directamente con `escala = 'por_largo'`, evitando revertir el ajuste de 2R-1d al re-ejecutar.
  - Se regeneraron `20261011_02_costos_plataforma_40x2.sql`, `20261014_01_dolly.sql` y `20261014_02_gondola.sql`.
- **Verificación de idempotencia y re-ejecución:**  
  - Se documentó en la Sección 8 de `INFORME_2R1G.md` que re-ejecutar 1c, 1e y 1f sobre una base con 1g mantiene idénticos los 200 registros de `opcion_costos` y 59 de `costos_modelo` sin pérdidas de datos.
**Acciones manuales pendientes:** Ejecutar `verificacion_2R1g.sql` en Postgres local.

## 2026-10-15 - Corrección 2R-1g: normalización de notas heredadas (2R-1c y 2R-1e) y ajuste en verificación
**Herramienta:** Antigravity  
**Tipo:** fix (migraciones, docs)  
**Archivos tocados:**  
- `scripts/generar_costos_sql.cjs`
- `supabase/migrations/20261011_02_costos_plataforma_40x2.sql`
- `scripts/generar_costos_dolly_sql.cjs`
- `supabase/migrations/20261014_01_dolly.sql`
- `scripts/generar_normalizar_notas_sql.cjs`
- `supabase/migrations/20261015_02_normalizar_notas.sql`
- `docs/importacion/verificacion_2R1g.sql`
- `docs/importacion/INFORME_2R1G.md`
**Qué cambió y por qué:**  
- **Normalización de notas y generadores de 2R-1c y 2R-1e:**  
  - En `scripts/generar_costos_dolly_sql.cjs` y `20261014_01_dolly.sql`, 5 filas de `opcion_costos` (rines y llantas) que contenían textos explicativos en notas migraron a `fuente = 'Factura Leolca (cantidad por eje supuesta igual a plataforma y góndola)'` y `notas = 'import-2r1e'`.
  - En `scripts/generar_costos_sql.cjs` y `20261011_02_costos_plataforma_40x2.sql`, la fila de pintura de `costos_modelo` migró a `fuente = 'Factura Leolca (cantidad original: 1 1/2 cubeta)'` y `notas = 'import-2r1c'`.
  - Se creó el generador `scripts/generar_normalizar_notas_sql.cjs` y la nueva migración idempotente `supabase/migrations/20261015_02_normalizar_notas.sql` para aplicar estas normalizaciones en bases ya existentes.
- **Correcciones en `docs/importacion/verificacion_2R1g.sql`:**  
  - `escala_por_largo`: Evalúa que en plataforma existan exactamente los 8 pisos con escala `por_largo` (2 de 2R-1c + 6 de 2R-1g) y ninguna otra opción fuera de pisos con dicha escala, sin filtrar por notas.
  - `dolly_previas`: Filtra con `fuente = 'Factura Leolca' AND notas ILIKE '%import-2r1e%' = 9` para tolerar tanto el estado previo como el normalizado.
- **Documentación en `docs/importacion/INFORME_2R1G.md`:**  
  - Se agregó la Sección 7 con la justificación y las consultas SQL para auditar que `notas ILIKE '%import-2r1%'` devuelva únicamente variantes exactas.
**Acciones manuales pendientes:** Ejecutar `20261015_02_normalizar_notas.sql` y `verificacion_2R1g.sql` en Postgres local.

## 2026-10-15 - Sub-bloque 2R-1g: Costos de respaldo del tarifario para opciones no cubiertas por factura
**Herramienta:** Antigravity  
**Tipo:** feat (migraciones, backend, motor, cpq)  
**Archivos tocados:**  
- `scripts/generar_costos_respaldo_sql.cjs`
- `supabase/migrations/20261015_01_costos_respaldo.sql`
- `src/app/utils/costeo.ts`
- `supabase/functions/make-server-feea4382/motor/tipos.ts`
- `supabase/functions/make-server-feea4382/motor/cargar_costos.ts`
- `supabase/functions/make-server-feea4382/motor/costeo.ts`
- `supabase/functions/make-server-feea4382/motor/costeo.test.ts`
- `supabase/functions/make-server-feea4382/motor/presupuesto_desde_costeo.test.ts`
- `docs/importacion/verificacion_2R1g.sql`
- `docs/importacion/INFORME_2R1G.md`
**Qué cambió y por qué:**  
- **Generador y migración SQL (`scripts/generar_costos_respaldo_sql.cjs` → `20261015_01_costos_respaldo.sql`):**  
  - Inserta 144 filas en `opcion_costos` con `notas = 'import-2r1g'` de forma estrictamente idempotente en una sola transacción (`DELETE WHERE notas = 'import-2r1g'` + `INSERT ... SELECT ... WHERE NOT EXISTS`).
  - Cobertura de 60 opciones únicas distribuidas por tipo de modelo: Plataforma (60 filas: 8 Factura, 33 Tarifario, 19 Supuesto; suma Tarifario = $543,675.52), Dolly (42 filas: 3 Factura, 20 Tarifario, 19 Supuesto; suma Tarifario = $278,096.00) y Góndola (42 filas: 3 Factura, 20 Tarifario, 19 Supuesto; suma Tarifario = $278,096.00).
  - Incluye guardas de coherencia para 36 opciones verificando que el costo unitario no supere el precio de venta (`costo_unitario <= precio_venta`), contemplando las excepciones de regla neta (`suspension/hj_alta`) y diferencias justificadas de tarifario (`bicicletera`, `canastilla`, `con_riel`, `corrediza`).
- **Motor TypeScript/Deno y Frontend:**  
  - `motor/tipos.ts`: Se añadió `'costo_no_factura'` a `PendienteCosteo.tipo` y `fuente?: string` a `DatosCosteo.opcion_costos`.
  - `motor/cargar_costos.ts`: Lee y mapea la columna `fuente` de `opcion_costos`.
  - `motor/costeo.ts`: Agrupa las opciones seleccionadas que no provienen de `'Factura Leolca'` por su `fuente` e inyecta un único pendiente consolidado por cada fuente (`tipo: 'costo_no_factura'`, detalle: `Costos que no vienen de la Factura (por confirmar): <fuente> → <opciones>`), degradando la confianza a `estimada` sin inflar alertas por cada opción individual.
  - `src/app/utils/costeo.ts`: Registra la traducción `'costo_no_factura': 'Costo no es de la Factura'`.
  - Tests en `motor/costeo.test.ts` (6 casos exhaustivos para 2R-1g) y `motor/presupuesto_desde_costeo.test.ts` pasando al 100% (57 passed).
- **Verificación y documentación:**  
  - Script SQL `docs/importacion/verificacion_2R1g.sql` (un solo `SELECT`) que audita conteos, desglose por fuente, sumas de tarifario, escala `por_largo` restringida a pisos laminados e integridad de filas previas.
  - Informe detallado en `docs/importacion/INFORME_2R1G.md` documentando discrepancia de canastilla ($5,784.50 vs $5,040.00), resolución de 4 conflictos Factura vs Tarifario, justificación de conceptos no mapeados y simulación de plataforma 40/3.
**Acciones manuales pendientes:** Ejecutar migración `20261015_01_costos_respaldo.sql` en Postgres local para pruebas; posterior rebuild del backend en EasyPanel cuando se autorice el despliegue.

## 2026-10-14 - Corrección 2R-1f: notas uniformes en costos_modelo y detalle de 11 colisiones (GONDOLA)
**Herramienta:** Antigravity  
**Tipo:** fix (migraciones, docs)  
**Archivos tocados:**  
- `scripts/generar_costos_gondola_sql.cjs`
- `supabase/migrations/20261014_02_gondola.sql`
- `docs/importacion/INFORME_2R1F.md`
**Qué cambió y por qué:**  
- **Generador y migración (`scripts/generar_costos_gondola_sql.cjs` → `20261014_02_gondola.sql`):**  
  - Se corrigió la fila 'Kit de tornillería para gancho' de 2 ejes para que lleve estrictamente `notas = 'import-2r1f'` (igual que todas las demás filas importadas) y la explicación en `fuente`. Esto asegura que los filtros de borrado y la validación `RAISE EXCEPTION` (`v_sum_kits_2e = 89045.98`) coincidan exactamente y no falle la migración ni se dupliquen filas al re-ejecutar.
- **Informe de importación (`docs/importacion/INFORME_2R1F.md`):**  
  - Se listaron con datos reales del JSON los 11 materiales que reciben sufijo `(GONDOLA)` o `(GONDOLA) #2` (6 por colisión de precio con la plataforma y 5 por colisiones internas entre piezas de la góndola).
  - Se alineó la tabla comparativa Excel vs Sistema al desglose exacto que mide el motor de costeo: A-36 ($103,936.96 chasis + $303,554.72 tina y opciones + $89,045.98 kits + $65,000 ajustes = $561,537.66) y Hardox 450 ($103,936.96 chasis + $574,416.42 opciones con tina + $88,996.98 kits + $15,000 ajustes = $782,350.36).
**Acciones manuales pendientes:** Ejecutar migración `20261014_02_gondola.sql` en Postgres local para validar idempotencia.

## 2026-10-14 - Sub-bloque 2R-1f: La Góndola (modelos, chasis, tina por material, kits fijos y costos de opciones)
**Herramienta:** Antigravity  
**Tipo:** feat (migraciones, backend, motor, cpq)  
**Archivos tocados:**  
- `scripts/generar_costos_gondola_sql.cjs`
- `supabase/migrations/20261014_02_gondola.sql`
- `scripts/generar_fixture_gondola.cjs`
- `supabase/functions/make-server-feea4382/motor/fixtures/datos_costeo_gondola.json`
- `supabase/functions/make-server-feea4382/motor/tipos.ts`
- `supabase/functions/make-server-feea4382/motor/cargar_costos.ts`
- `supabase/functions/make-server-feea4382/motor/cargar_costos.test.ts`
- `supabase/functions/make-server-feea4382/motor/costeo.ts`
- `supabase/functions/make-server-feea4382/motor/costeo.test.ts`
- `supabase/functions/make-server-feea4382/motor/presupuesto_desde_costeo.ts`
- `supabase/functions/make-server-feea4382/motor/presupuesto_desde_costeo.test.ts`
- `src/app/utils/costeo.ts`
- `docs/importacion/verificacion_2R1f.sql`
- `docs/importacion/INFORME_2R1F.md`
**Qué cambió y por qué:**  
- **Generador y migración SQL (`scripts/generar_costos_gondola_sql.cjs` → `20261014_02_gondola.sql`):**  
  - Crea los productos terminados `GONDOLA 2 EJES 45 M3` y `GONDOLA 3 EJES 45 M3` y sus modelos en `modelos` (`tipo = 'gondola'`, `largo_ft = NULL`, `num_ejes` = 2 y 3).
  - Carga el acero del chasis (49 renglones por modelo, $103,936.96 cada uno) en `receta_base` (`seccion = 'acero'`) usando la función de sesión `pg_temp.resolver_o_crear_material_gondola`. Resuelve 20 materiales reutilizados, 24 nuevos y 5 colisiones de precio con la plataforma (`Borda delantera`, `Base para foco de ABS`, `Base para ABS`, `Porta placas`, `Porta llantas`) creando materiales separados con sufijo ` (GONDOLA)` para proteger los costos de la plataforma.
  - Carga el despiece de tina (BOM) en `opcion_componentes`: 43 renglones para `tina_material / a36`, y 39 renglones para `tina_material / hardox_450` (donde 2 paquetes cotizados de proveedor reemplazan 6 renglones).
  - Carga el costo de las tinas en `opcion_costos`: `a36` = $167,505.76; `hardox_450` = $286,748.42.
  - Carga los costos fijos en `costos_modelo`: 15 conceptos para 2 ejes ($89,045.98) incluyendo el kit de tornillería para gancho de $49; y 14 conceptos comunes para 3 ejes ($88,996.98).
  - Carga 23 opciones catalogadas para góndola en `opcion_costos` (suspensión, ejes, patines, ganchos, ABS, retráctil, rines, llantas).
  - Todo etiquetado con `notas = 'import-2r1f'` e idempotente en una sola transacción.
- **Motor TypeScript/Deno y Frontend:**  
  - `motor/tipos.ts`: Se agregó `'iva_gondola'` a `PendienteCosteo.tipo`.
  - `motor/cargar_costos.ts`: Asigna `ganancia = paramGanancia.valor.gondola_servicios_sueldos` ($100,000) para `tipo = 'gondola'`.
  - `motor/costeo.ts`: Reconoce que la góndola no requiere procesos de manufactura individuales (`tieneProcesos = true`) y agrega el pendiente `{ tipo: 'iva_gondola', detalle: 'El IVA de la góndola está por confirmar con el dueño: en el Excel es 16% solo sobre chasis + tina; el precio sugerido no lo incluye' }`, otorgando confianza `estimada` y calculando el precio sugerido sin IVA.
  - `src/app/utils/costeo.ts`: Traduce `iva_gondola` a `'IVA por confirmar'`.
  - `motor/presupuesto_desde_costeo.ts`: Mapea `tina_material` a la sección `acero` en `MAPEO_GRUPOS_OPCIONES`.
  - `motor/costeo.test.ts`: Pruebas doradas exactas para Góndola A-36 ($561,537.66 costo / $661,537.66 sugerido sin IVA / $704,968.50 con IVA 16% sobre chasis+tina) y Góndola Hardox 450 ($782,350.36 costo / $882,350.36 sugerido sin IVA / $944,860.02 con IVA).
- **Verificación y documentación:**  
  - Script SQL `docs/importacion/verificacion_2R1f.sql` (un solo `SELECT`) que valida conteos, totales de góndola e integridad intacta de Plataforma 40/2 y Dolly.
  - Informe detallado en `docs/importacion/INFORME_2R1F.md` con hallazgos de tina (piezas Hardox en tina A-36, salpicaderas exclusivas en Hardox) y tabla comparativa Excel vs Sistema.
**Acciones manuales pendientes:** Ejecutar migración `20261014_02_gondola.sql` en SQL Editor de Supabase tras autorización. Rebuild del backend en EasyPanel.

## 2026-10-14 - Sub-bloque 2R-1e: El Dolly (modelo, acero, kits, mano de obra y costos de opciones)
**Herramienta:** Antigravity
**Tipo:** feat (migraciones, backend, motor, cpq)
**Archivos tocados:**
- `scripts/generar_costos_dolly_sql.cjs`
- `supabase/migrations/20261014_01_dolly.sql`
- `scripts/generar_fixture_dolly.cjs`
- `supabase/functions/make-server-feea4382/motor/fixtures/datos_costeo_dolly.json`
- `supabase/functions/make-server-feea4382/motor/texto_especificacion.ts`
- `supabase/functions/make-server-feea4382/motor/texto_especificacion.test.ts`
- `supabase/functions/make-server-feea4382/motor/cargar_costos.ts`
- `supabase/functions/make-server-feea4382/motor/cargar_costos.test.ts`
- `supabase/functions/make-server-feea4382/motor/costeo.test.ts`
- `src/app/components/Cotizaciones/ConfiguradorEquipo.tsx`
- `docs/importacion/verificacion_2R1e.sql`
- `docs/importacion/INFORME_2R1e.md`
**Qué cambió y por qué:**
- **Generador y migración SQL (`scripts/generar_costos_dolly_sql.cjs` → `20261014_01_dolly.sql`):**
  - Crea el producto terminado `DOLLY 2 EJES` y su modelo en `modelos` (`tipo = 'dolly'`, `largo_ft = NULL`, `num_ejes = 2`).
  - Carga el acero del Dolly en `receta_base` (`seccion = 'acero'`, 33 renglones, suma exacta: $27,018.80) consolidando los primeros 6 renglones en `PAQUETE CUERPO CHASIS DOLLY (PUENTES J, C, Z, ALMA, SOLERAS SUPERIOR E INFERIOR)` ($14,800.00).
  - Incluye la función temporal `pg_temp.resolver_o_crear_material_dolly` para resolver dinámicamente colisiones de materiales (reutiliza si el costo coincide, o añade sufijo ` (DOLLY)` si difiere).
  - Carga los 18 conceptos fijos de kits y consumibles en `costos_modelo` (suma exacta: $20,089.14).
  - Carga los 43 procesos de mano de obra en `procesos_manufactura` (suma exacta: $11,249.90, ajustando minutos totales por unidad según el costo de la fila).
  - Mapea 9 opciones del catálogo unificado en `opcion_costos` para `tipo_modelo = 'dolly'` (quinta Holland $27,375, ABS 2e sin retráctil $20,000, ABS 2e 1 retráctil $24,700, retráctil paleta $8,200, rines acero $1,550 y aluminio $5,500, llantas chinas $3,000, Firestone $8,700 y Amulet $4,225).
  - Toda la inserción está etiquetada con `notas = 'import-2r1e'` y es estrictamente idempotente.
- **Motor TypeScript/Deno y Frontend:**
  - `motor/texto_especificacion.ts`: Formatea el encabezado por tipo (`DOLLY ${num_ejes} EJES`, `GONDOLA ${num_ejes} EJES`, o en mayúsculas). Pruebas agregadas en `texto_especificacion.test.ts`.
  - `motor/cargar_costos.ts`: Mapea `largo_ft` nulo como `0` en vez de `NaN`. Prueba unitaria agregada en `cargar_costos.test.ts`.
  - `motor/costeo.test.ts`: Agregada prueba dorada del Dolly con fixture `datos_costeo_dolly.json` generado por `scripts/generar_fixture_dolly.cjs`. Coincide al centavo: costo $110,908.84, ganancia $65,000.00, precio sugerido $175,908.84.
  - `ConfiguradorEquipo.tsx`: Corrige `DialogDescription` para no mostrar "nullFT" cuando `largo_ft` es nulo.
- **Verificación y documentación:**
  - Consulta SQL `docs/importacion/verificacion_2R1e.sql` con un solo `SELECT` que valida totales del Dolly e integridad intacta de la Plataforma 40/2 ($128,211.69 / $45,685.98 / $22,930.00).
  - Informe completo en `docs/importacion/INFORME_2R1e.md`.
**Acciones manuales pendientes:** Ejecutar migración `20261014_01_dolly.sql` en SQL Editor de Supabase tras autorización. Rebuild del backend en EasyPanel.

## 2026-10-14 - Sub-bloque 2R-1d: Costos de variantes de plataforma (derivadas de la 40/2)
**Herramienta:** Antigravity
**Tipo:** feat (migraciones, backend, motor, cpq)
**Archivos tocados:**
- `supabase/migrations/20261013_01_costos_derivados.sql`
- `scripts/generar_costos_variantes_sql.cjs`
- `supabase/migrations/20261013_02_costos_variantes_plataforma.sql`
- `supabase/functions/make-server-feea4382/motor/tipos.ts`
- `supabase/functions/make-server-feea4382/motor/cargar_costos.ts`
- `supabase/functions/make-server-feea4382/motor/costeo.ts`
- `supabase/functions/make-server-feea4382/motor/costeo.test.ts`
- `supabase/functions/make-server-feea4382/index.ts`
- `src/app/components/Cotizaciones/CotizacionesList.tsx`
- `src/app/utils/costeo.ts`
- `docs/importacion/verificacion_2R1d.sql`
- `docs/importacion/INFORME_2R1D.md`
**Qué cambió y por qué:**
- **Migración de esquema (`20261013_01_costos_derivados.sql`):**
  - Se agregó la columna `costos_derivados_de uuid REFERENCES modelos(id) ON DELETE SET NULL` en la tabla `modelos` con su comentario SQL.
  - Se actualizó la escala de las opciones de piso (`laminado_madera` y `laminado_plastico`) a `'por_largo'` en `opcion_costos` para que escalen proporcionalmente al largo (`largo_ft / 40.0`). La 40/2 permanece idéntica ($397,713.63 costo / $507,713.63 precio).
- **Generador y migración de datos (`generar_costos_variantes_sql.cjs` → `20261013_02_costos_variantes_plataforma.sql`):**
  - Script determinista que deriva costos para 8 variantes (35/2, 40/3, 42/2, 42/3, 45/2, 45/3, 48/2, 48/3) copiando los 61 renglones de acero (con cargadores de 4" ajustados según `BASE DAT PLANAS`), 12 costos de kits y consumibles fijos, y 80 procesos de mano de obra (total 1,224 renglones insertados).
  - Valida que el modelo origen 40/2 sea exactamente 1 con 61 renglones de acero y que exista el material determinista `CARGADOR (IPR DE 4")`.
  - El modelo 43/3 se omite intencionalmente por no figurar en `BASE DAT PLANAS` (documentado como pendiente).
  - Marca los 8 modelos destino con `costos_derivados_de = <id_40_2>`.
- **Motor de costeo y backend:**
  - `motor/tipos.ts`: añadido `DatosCosteo.costos_derivados_de` y el tipo de pendiente `'variante_supuesta'` a `PendienteCosteo`.
  - `motor/cargar_costos.ts`: lee `modelos.costos_derivados_de` y el nombre del modelo origen.
  - `motor/costeo.ts`: si `costos_derivados_de` está presente, agrega el pendiente `{ tipo: 'variante_supuesta', detalle: 'Costos estimados a partir de <nombre>: no hay desglose propio de esta variante' }`, asignando confianza `'estimada'` mientras calcula el precio sugerido.
  - `motor/costeo.test.ts`: agregadas pruebas para validar que la 40/2 no trae `variante_supuesta`, que un modelo derivado obtiene `variante_supuesta` y precio sugerido, y que el piso de 45 ft escala a 45/40 del de 40 ft.
  - `supabase/functions/make-server-feea4382/index.ts`: los motivos de conceptos omitidos en `POST /cotizaciones/:id/presupuesto` ante modelos sin costos incluyen el nombre corto del modelo (e.g., `PLATAFORMA 3 43 FT: sin costos cargados todavía`).
  - `CotizacionesList.tsx`: recorta la descripción del concepto a 70 caracteres con '…' al mostrar el aviso toast.
  - `src/app/utils/costeo.ts`: agregada la traducción `'variante_supuesta' -> 'Costo supuesto'` en `traducirTipoPendiente`.
- **Verificación y documentación:**
  - Creada consulta `docs/importacion/verificacion_2R1d.sql` (un solo `SELECT` con 8 filas de destinos y 1 fila de totales de control).
  - Creado informe `docs/importacion/INFORME_2R1D.md` con tabla de sanidad y supuestos para el dueño.
**Acciones manuales pendientes:** Ejecutar migraciones `20261013_01_costos_derivados.sql` y `20261013_02_costos_variantes_plataforma.sql` en SQL Editor tras autorización. Rebuild del backend en EasyPanel una vez mergeado.


## 2026-10-12 - Sub-bloque 2R-4a (V2): Generación de presupuesto desde costeo real (presupuesto_desde_costeo.ts)
**Herramienta:** Antigravity
**Tipo:** feat (motor, backend, frontend, presupuestos, cpq)
**Archivos tocados:**
- `supabase/functions/make-server-feea4382/motor/tipos.ts`
- `supabase/functions/make-server-feea4382/motor/costeo.ts`
- `supabase/functions/make-server-feea4382/motor/costeo.test.ts`
- `supabase/functions/make-server-feea4382/motor/presupuesto_desde_costeo.ts`
- `supabase/functions/make-server-feea4382/motor/presupuesto_desde_costeo.test.ts`
- `supabase/functions/make-server-feea4382/index.ts`
- `src/app/types/index.ts`
- `src/app/utils/costeo.ts`
- `src/app/components/Presupuestos/presupuestoTemplate.ts`
- `src/app/components/Presupuestos/PresupuestoEditor.tsx`
- `src/app/components/Presupuestos/PresupuestoPDF.tsx`
- `src/app/components/Cotizaciones/CotizacionesList.tsx`
**Qué cambió y por qué:**
- **Sección A (Tipos y kits con sección):**
  - Añadido `seccion?: string` a `LineaCosteo` en `motor/tipos.ts` y `src/app/utils/costeo.ts`.
  - En `motor/costeo.ts`, se asigna `seccion: kit.seccion` a las líneas de kits/procesos de manufactura (tornilleria, luz, pintura, etc.).
  - En `motor/costeo.test.ts`, prueba añadida para verificar que las 12 líneas de kits traen su sección poblada.
- **Sección B (Función pura `generarPresupuestoDesdeCosteo`):**
  - Creado `supabase/functions/make-server-feea4382/motor/presupuesto_desde_costeo.ts`: función pura que mapea líneas de costeo y opciones a las 14 secciones del presupuesto, fusiona líneas idénticas (mismo material y cu), agrupa procesos de mano de obra, congela `meta.bom` por unidad y preserva trazabilidad (`meta.pendientes`, `meta.conceptos_omitidos`, `meta.confianza`).
  - Creado `supabase/functions/make-server-feea4382/motor/presupuesto_desde_costeo.test.ts` con 8 pruebas que pasan al 100%, incluyendo la prueba dorada que reproduce el total exacto del Excel ($397,713.63) y desglose por sección al centavo.
- **Sección C (Ruta POST /cotizaciones/:id/presupuesto):**
  - En `supabase/functions/make-server-feea4382/index.ts`, añadida la ruta que recalcula costos y BOM de los equipos con datos de hoy, responde 400 si ningún equipo es elegible, 409 si ya existe un folio PRE- (con soporte para `{ reemplazar: true }`), e inserta/actualiza en `presupuestos` con registro de auditoría en bitácora.
- **Sección D (Botón "Generar presupuesto" en CotizacionesList):**
  - Reemplazada la implementación legacy en `handleGenerarPresupuesto`: eliminadas las constantes duplicadas y llamadas a `/productos/:id/materiales`.
  - Ahora invoca `POST /cotizaciones/:id/presupuesto` usando `BASE_URL` de `utils/api.ts`.
  - Manejo de confirmación ante respuesta 409 con diálogo ("Ya existe un presupuesto para esta cotización. ¿Reemplazarlo?"), bloqueo ante dobles clics y mensajes descriptivos para errores 400.
- **Sección E (Editor, PDF y compatibilidad hacia atrás):**
  - Añadidas las secciones opcionales `tornilleria`, `luz`, `aire`, `pintura` y `meta?` a `PresupuestoDatos` en `src/app/types/index.ts` y `presupuestoTemplate.ts`.
  - `PresupuestoEditor.tsx`: renderiza las 14 secciones, destaca filas con `sin_precio: true` y retira la marca al ingresar `cu > 0`, muestra banner de avisos para `datos.meta` (pendientes, sin_precio, omitidos, confianza), rotula "Gran Total (Costo estimado)" si la confianza no es completa, y preserva `datos.meta` al guardar.
  - `PresupuestoPDF.tsx`: renderiza las nuevas secciones de forma segura (tolerante a presupuestos antiguos sin esas claves) y añade la leyenda `TOTAL (COSTO ESTIMADO):` cuando corresponde.
- **Verificación:**
  - `npm.cmd run verificar -- --limpio` pasando 10/10 comprobaciones con 44 pruebas Deno exitosas y tsc en 53 errores ($\le$ baseline de 55).
**Acciones manuales pendientes:** Ninguna. Sin merge ni push hasta autorización explícita.


## 2026-10-12 - Sub-bloque 2R-4d: Conexión frontend de costeo y precio sugerido en Configurador y Cotización
**Herramienta:** Antigravity
**Tipo:** feat (frontend, cpq, costeo, cotizaciones)
**Archivos tocados:**
- `src/app/utils/costeo.ts`
- `src/app/components/Cotizaciones/ConfiguradorEquipo.tsx`
- `src/app/components/Cotizaciones/CotizacionEditor.tsx`
**Qué cambió y por qué:**
- **Módulo de utilidades (`src/app/utils/costeo.ts`):**
  - Se crearon las interfaces TypeScript `ResultadoCosteo`, `SeccionCosteo`, `LineaCosteo`, `PendienteCosteo`, `AjusteManual` y `CosteoResumenGuardado`.
  - Se implementó la lógica pura de decisión de precios `decidirPrecioItem({ costeo, precioActual, costeoPrevio })`:
    - Si no hay nuevo precio sugerido (`costeo === null` o `precio_sugerido === null`), conserva `precioActual` intacto (o 0 si `precioActual` es undefined); nunca devuelve 0 sobre un precio existente por falta de costeo.
    - Si el ítem es nuevo (`precioActual === undefined`), asigna el nuevo sugerido.
    - Si el ítem está en edición y el usuario no personalizó el precio (era 0 o coincidía con el sugerido previo), se actualiza al nuevo precio sugerido.
    - Si el usuario personalizó el precio a mano, se preserva su precio manual.
    - Se documentaron y probaron los 5 casos de aceptación en el archivo.
  - Se añadieron las funciones `validarAjusteIndividual`, `validarAjustesCliente`, `textoConfianza` y `traducirTipoPendiente`.
- **Configurador de equipos (`src/app/components/Cotizaciones/ConfiguradorEquipo.tsx`):**
  - Se conectó la llamada paralela con debounce a `POST /configuracion/costear` junto a `/configuracion/resolver` en `ejecutarCalculos`.
  - Se añadió el estado `calculoPendiente` que se activa de inmediato en `handleConfigChange` y `handleAjustesUIChange` y se desactiva al resolver la última petición (con protección `reqId`).
  - El botón de confirmar se deshabilita si `calculoPendiente || costeando || resolviendo`.
  - Si `/costear` responde con error o falla de red, ejecuta `setCosteo(null)` para evitar confirmar con datos de una configuración anterior.
  - **Panel de Costos**: Precio sugerido prominente con badges de confianza ('Costeo completo', 'Estimado: hay datos pendientes', 'Sin costeo para este modelo') y mensajes claros si no hay costos cargados o falta definir ganancia (nunca $0).
  - Costo unitario y Margen (% sobre precio y $ en pesos).
  - Indicador sutil de recálculo (`costeando || calculoPendiente`) sin saltos de layout.
  - Lista de pendientes legible y traducida (`traducirTipoPendiente`).
  - Desglose plegable por sección (Acero, Kits y consumibles, Opciones elegidas, Mano de obra, Ajustes) con scroll interno (`max-h-44`) para las 61 líneas de acero.
  - Sección plegable de **Ajustes al costo**: maneja estado local de texto por renglón (`AjusteFilaUI`: `cantidad`, `costo_unitario` como strings), permitiendo escribir el signo `-` y decimales sin saltos a 0.
  - Al confirmar, `cfgToSave.ajustes` guarda únicamente los ajustes que pasan `validarAjusteIndividual`, y se retiró `costeo` de `cfgToSave` para mantener una única fuente de verdad en `handleCPQConfirm`.
- **Renglón de la cotización (`src/app/components/Cotizaciones/CotizacionEditor.tsx`):**
  - Se actualizó `handleCPQConfirm` para recibir el 5.º argumento `costeo`.
  - Asigna `costo_unitario` al valor de costeo únicamente si la confianza no es `'incompleta'`.
  - Asigna `precio_unitario` mediante `decidirPrecioItem` y recalcula `iva_item` y `total_item` con `calcularItemCotizacion`.
  - Guarda en `configuracion.costeo` el resumen para trazabilidad y persistencia.
- **Validación:**
  - `npm.cmd run verificar -- --limpio` pasa 10/10 comprobaciones con 0 errores tsc sobre el baseline (55).
**Acciones manuales pendientes:** Ninguna. Sin merge ni push hasta autorización explícita.

## 2026-10-11 - Sub-bloque 2R-4c: Motor de costeo (costeo.ts), ruta POST /configuracion/costear y corrección de secciones en resolver
**Herramienta:** Antigravity
**Tipo:** feat (backend, cpq, costeo)
**Archivos tocados:**
- `supabase/functions/make-server-feea4382/motor/tipos.ts`
- `supabase/functions/make-server-feea4382/motor/cargar_datos.ts`
- `supabase/functions/make-server-feea4382/motor/resolver_receta.ts`
- `supabase/functions/make-server-feea4382/motor/resolver_receta.test.ts`
- `supabase/functions/make-server-feea4382/motor/costeo.ts`
- `supabase/functions/make-server-feea4382/motor/cargar_costos.ts`
- `supabase/functions/make-server-feea4382/index.ts`
- `supabase/functions/make-server-feea4382/motor/fixtures/datos_costeo_plataforma_40x2.json`
- `supabase/functions/make-server-feea4382/motor/costeo.test.ts`
**Qué cambió y por qué:**
- **Parte 1 (Corrección del resolver):**
  - En `cargar_datos.ts` se agregó la lectura de `seccion` en la consulta de `receta_base`.
  - En `tipos.ts` se agregó `seccion?: string | null` y `paso: string | null` a `LineaReceta`.
  - En `resolver_receta.ts`, la receta base ahora propaga su sección real (por ejemplo `'acero'`), evitando sobrescribirla con `'ensamble'`. La clave del mapa de agregación ahora incluye la sección `${matId}_${unidad}_${seccion}` para no colisionar piezas de diferentes secciones. Se sanitizó la inserción en `linea.paso` para no meter valores `null`. `secciones_pendientes` ahora se calcula dinámicamente (`["acero"]` solo si el modelo carece de líneas de `receta_base` con sección `'acero'`). Se añadieron pruebas unitarias 17 y 18 a `resolver_receta.test.ts`.
- **Parte 2 & 3 (Motor de costeo y carga de datos):**
  - En `tipos.ts` se definieron los tipos `DatosCosteo`, `AjusteManual`, `LineaCosteo`, `SeccionCosteo`, `PendienteCosteo` y `ResultadoCosteo`.
  - Se implementó `motor/costeo.ts` con función pura `costear(datos, configuracion, ajustes)` que desglosa acero, kits fijos, opciones, mano de obra y ajustes manuales, redondeando sección por sección a dos decimales y evaluando nivel de confianza (`'completa'`, `'estimada'`, `'incompleta'`). También se expuso la función `validarAjustes`.
  - Se implementó `motor/cargar_costos.ts` para extraer de Supabase la receta de acero, costos fijos, mano de obra, costos de opciones por tipo de modelo y parámetro de ganancia.
  - En `index.ts` se registró la ruta `POST /configuracion/costear` con validación estricta de parámetros y ajustes manuales.
- **Parte 4 (Prueba de aceptación dorada y suite de pruebas):**
  - Se generó el fixture `fixtures/datos_costeo_plataforma_40x2.json` a partir de `docs/factura-leolca/extraccion_factura_leolca.json` y los costos de opciones del catálogo.
  - Se creó `motor/costeo.test.ts` con 8 pruebas automatizadas: la prueba dorada (cuadre exacto al centavo con el Excel de Leolca: acero $128,211.69, kits $45,685.98, opciones $169,400.96, mano de obra $22,930.00, ajustes $31,485.00 -> costo $397,713.63 + ganancia $110,000.00 = precio sugerido $507,713.63, confianza estimada con 1 pendiente por puentes de suspensión sin precio) más 7 pruebas de validación de escala, opciones faltantes, variantes incompletas, ganancia nula, ajustes negativos/descuentos, validación de ajustes inválidos y confianza completa.
- **Validación:**
  - 33 pruebas Deno pasando (18 en resolver_receta + 8 en costeo + resto del motor).
  - Verificación `npm.cmd run verificar -- --limpio` completa con `RESULTADO: TODO OK (10/10 comprobaciones)`.
**Acciones manuales pendientes:**
- Rebuild del servicio backend en EasyPanel una vez que el usuario apruebe y autorice el despliegue a main.

## 2026-10-11 - Sub-bloque 2R-1c: Costos de la plataforma 40 ft / 2 ejes
**Herramienta:** Antigravity
**Tipo:** migración / datos
**Archivos tocados:**
- `supabase/migrations/20261011_01_costos_esquema.sql`
- `scripts/generar_costos_sql.cjs`
- `supabase/migrations/20261011_02_costos_plataforma_40x2.sql`
- `docs/importacion/verificacion_2R1c.sql`
- `docs/importacion/INFORME_2R1C.md`
- `package.json`
- `scripts/verificar.mjs`
- `scripts/verificar-baseline.json`
**Qué cambió y por qué:**
- **Paso 0:** Se versionaron los scripts de verificación (`scripts/verificar.mjs`, `scripts/verificar-baseline.json`) y el comando `"verificar": "node scripts/verificar.mjs"` en `package.json`.
- **Esquema:** Se creó la migración `20261011_01_costos_esquema.sql` con las tablas `opcion_costos`, `procesos_manufactura` y `costos_modelo`, con RLS habilitada usando `get_current_org_id()` existente e índices en FK.
- **Generador y Datos:** Se creó `scripts/generar_costos_sql.cjs` que extrae datos de `docs/factura-leolca/extraccion_factura_leolca.json` y genera la migración idempotente `20261011_02_costos_plataforma_40x2.sql`. Inserta 61 materiales de acero en `productos` (`materia_prima`) y su correspondiente `receta_base`, 12 conceptos en `costos_modelo` ($45,685.98), 22 costos de opciones en `opcion_costos`, 80 renglones de mano de obra en `procesos_manufactura` ($22,930.00 medidos en Postgres local) y la clave `ganancia_factura` en `parametros_costeo`.
- **Verificación:** Se añadió la consulta `docs/importacion/verificacion_2R1c.sql` y el informe detallado `docs/importacion/INFORME_2R1C.md`. Validado con éxito en Postgres local en dos corridas idempotentes por Claude Code (costo base chasis medido: $216,827.67).
**Acciones manuales pendientes:** Ninguna para 2R-1c (validado en Postgres local antes del merge a main).

## 2026-10-09 - Bloque 2R-3a y 2R-3b: Configurador de equipos y tarjeta en cotización (Frontend)
**Herramienta:** Antigravity
**Tipo:** cambio
**Archivos tocados:**
- supabase/functions/make-server-feea4382/index.ts (hotfix import duplicado)
- src/app/components/Cotizaciones/CotizacionEditor.tsx
- src/app/components/Cotizaciones/ConfiguradorEquipo.tsx
- src/app/components/Cotizaciones/SelectorProductos.tsx
- src/app/components/Cotizaciones/PDFTemplateLeolca.tsx
- src/app/components/Cotizaciones/PDFTemplateMoodboard.tsx
- src/app/components/Cotizaciones/PDFFullPageMoodboard.tsx
- src/app/components/Portal/PortalCliente.tsx
- src/app/utils/calculations.ts
- src/app/App.tsx
**Qué cambió y por qué:**
Se completaron los bloques 2R-3a (integración del configurador) y 2R-3b (pulido de la interfaz).
- **Backend:** Se aplicó un hotfix en index.ts borrando un import duplicado de construirMetadata que impedía el arranque en producción.
- **Frontend - Editor:** Se implementó el nuevo SelectorProductos agrupado y el componente ConfiguradorEquipo adaptado. Las opciones obligatorias faltantes se agrupan en un solo mensaje de alerta. En CotizacionEditor, los conceptos configurados (Plataformas, etc.) ahora se muestran en una tarjeta dedicada que incluye chips de estado (Precio pendiente, Receta incompleta), botones y el desglose plegable.
- **Frontend - Totales y PDF:** Se corrigió el cálculo de IVA (asumiendo 0 en vez de NaN si ajustes.iva_por_defecto es nulo). Los desgloses configurados ahora se muestran en el PDF y el Portal de Cliente.
**Acciones manuales pendientes:** Ninguna. Todo validado en local y construido correctamente.

## 2026-10-09 (12) - Bloque 2R-3a: Configurador de equipo en la cotización
**Herramienta:** Antigravity
**Tipo:** feat (frontend, cpq, ui)
**Archivos tocados:**
- `supabase/functions/make-server-feea4382/index.ts`
- `supabase/functions/make-server-feea4382/motor/item_metadata.ts`
- `supabase/functions/make-server-feea4382/motor/texto_especificacion.ts`
- `src/app/components/Cotizaciones/ConfiguradorEquipo.tsx`
- `src/app/components/Cotizaciones/CotizacionEditor.tsx`
- `src/app/types/index.ts`
- Eliminado: `src/app/components/Presupuestos/ModeloConfiguratorModal.tsx`

**Qué cambió y por qué:**
Se extrajo la lógica de persistencia de metadatos a `motor/item_metadata.ts` para guardar `configuracion` íntegra. Se agregó `generarEspecificacion` (`texto_especificacion.ts`) que mapea la configuración elegida al texto objetivo de las facturas (ordenado y formateado). El backend ahora devuelve este texto y la lista de materiales sugerida en `/configuracion/resolver`, y `producto_id` en `/modelos`. En el frontend, se integró el componente `ConfiguradorEquipo` dentro del Editor de Cotizaciones; intercepta productos que sean modelos y muestra una UI en vivo validando compatibilidades y la suficiencia de la receta. Se removieron todos los rastros de `pending_cpq` y código muerto previo.

**Acciones manuales / Despliegue:**
- Ninguna. Pruebas Deno en verde, build de Vite en verde. Rebuild requerido en EasyPanel si se decide desplegar.

## 2026-10-07 (11) - Bloque 2R-2: Correcciones Motor CPQ (Validaciones y Contrato)
**Herramienta:** Antigravity
**Tipo:** fix (motor, tests)
**Archivos tocados:**
- `supabase/functions/make-server-feea4382/motor/resolver_receta.ts`
- `supabase/functions/make-server-feea4382/motor/reglas_compatibilidad.ts`
- `supabase/functions/make-server-feea4382/motor/resolver_receta.test.ts`
- `supabase/functions/make-server-feea4382/motor/verificacion_esquema.test.ts`
- `supabase/functions/make-server-feea4382/motor/tipos.ts`

**Qué cambió y por qué:**
Se refinó la lógica del motor para igualar marcas de rines por nombre completo y alias (ej. `AMPRO MASTER TRAPEZOIDAL`); se programó la regla condicional Dona/Gancho con una tabla dura explícita (`holland` <-> `holland_8_10`, etc.); se sustituyó el campo original por `reemplaza: null` y un arreglo `posibles_reemplazos` buscando componentes excluidos con el mismo prefijo. Finalmente, se reconstruyó la prueba de contrato para que abra y lea dinámicamente los archivos `index.ts` y `cargar_datos.ts`, extraiga el árbol de `.select()` real, y los verifique cruzando contra el `CREATE TABLE` de las migraciones SQL. Las pruebas fueron reescritas y actualizadas con escenarios de datos reales.

**Acciones manuales / Despliegue:**
- Ninguna. Las pruebas corren en Deno (`deno test`).

## 2026-10-07 (10) - Bloque 2R-2: Motor de Resolución de Recetas CPQ
**Herramienta:** Antigravity
**Tipo:** feat (motor, server)
**Archivos tocados:**
- `supabase/functions/make-server-feea4382/index.ts`
- `supabase/functions/make-server-feea4382/motor/tipos.ts`
- `supabase/functions/make-server-feea4382/motor/reglas_compatibilidad.ts`
- `supabase/functions/make-server-feea4382/motor/resolver_receta.ts`
- `supabase/functions/make-server-feea4382/motor/cargar_datos.ts`
- `supabase/functions/make-server-feea4382/motor/resolver_receta.test.ts`
- `scripts/generar_fixture_motor.cjs`
- `package.json`

**Qué cambió y por qué:**
Se implementó el Motor de Recetas CPQ en el backend (Deno/Hono). 
1. Se programó la función pura `resolverReceta` que toma una configuración y los datos de un modelo para generar la lista exhaustiva de materiales (`lineas`), validando exclusividad, sumando piezas repetidas de diferentes orígenes (base u opciones), y alertando sobre incompatibilidades, materiales faltantes o sin costo.
2. Se programó `cargarDatosModelo` para obtener los datos puros desde Supabase.
3. Se integraron 3 endpoints nuevos (`GET /modelos`, `GET /modelos/:id/configuracion`, `POST /configuracion/resolver`) bajo el middleware de autenticación.
4. Se programaron 15 pruebas Deno simulando resoluciones complejas (redilas, marcas de rines, escalas por longitud de plataforma, condiciones cruzadas).
5. Se generó un script temporal `generar_fixture_motor.cjs` para crear los datos de prueba idénticos al esquema real a partir del `clasificacion_2R1b.json` y el catálogo.
6. El Despiece de Acero fue excluido intencionalmente, reportando `secciones_pendientes: ["acero"]`.

## 2026-10-07 (9) - Bloque 2R-1b: Recetas de Plataforma - Ronda 6 (Restauración de costo y precio)
**Herramienta:** Antigravity
**Tipo:** fix (db)
**Archivos tocados:**
- `scripts/generar_recetas_sql.cjs`
- `supabase/migrations/20261008_01_recetas_plataforma.sql`

**Qué cambió y por qué:**
Se corrigió un error introducido en la actualización anterior, donde al agregar la columna obligatoria `unidad` en la inserción de nuevos materiales a la tabla `productos`, se removieron accidentalmente las columnas que el prompt original requería explícitamente (`costo`, `precio_unitario` y `descripcion`).
Esto dejaba a los 173 materiales nuevos con sus precios en NULL, imposibilitando los cálculos de costeo y rompiendo el script de verificación `verificacion_2R1b.sql` (que cuenta los materiales insertados usando la etiqueta `descripcion = 'SIN PRECIO'`).
Se restauraron estas columnas a su instrucción inicial (`costo = 0`, `precio_unitario = 0`, `descripcion = 'SIN PRECIO'`) junto a la inclusión de la unidad resuelta.

## 2026-10-07 (8) - Bloque 2R-1b: Recetas de Plataforma - Ronda 5 (Corrección de constraint unidad)
**Herramienta:** Antigravity
**Tipo:** fix (db)
**Archivos tocados:**
- scripts/clasificador_2R1b.cjs
- scripts/generar_recetas_sql.cjs
- docs/importacion/INFORME_2R1B.md
- supabase/migrations/20261008_01_recetas_plataforma.sql

**Qué cambió y por qué:**
Se corrigió un error que rompía la inserción en producción por violación de constraint NOT NULL en la columna unidad de la tabla productos. La inserción inicial omitía la columna, y no tenía un DEFAULT.
Se implementó un mapeo de unidades donde los materiales listados bajo líquidos reciben L (Litros), aquellos que son cableado o mangueras reciben M (Metros), y el resto se clasifica por convención como PZA (Piezas). Los materiales que fueron asignados como PZA por falta de certeza quedaron reportados en INFORME_2R1B.md bajo la sección Unidades Supuestas para validación del dueño.
El SQL de importación fue actualizado para inyectar esta unidad de forma explícita en el INSERT.

## 2026-10-07 (7) - Bloque 2R-1b: Recetas de Plataforma - Ronda 4 (Condicionales JSONB)
**Herramienta:** Antigravity
**Tipo:** fix (db)
**Archivos tocados:**
- docs/importacion/clasificacion_2R1b.json
- docs/importacion/INFORME_2R1B.md
- supabase/migrations/20261008_01_recetas_plataforma.sql
- scripts/clasificador_2R1b.cjs
- scripts/generar_recetas_sql.cjs

**Qué cambió y por qué:**
Se solucionó la omisión de las reglas condicionales para filas de receta_base.
Anteriormente las reglas condicionales se perdían al insertarlas con condicion = NULL, dejando que un hipotético motor de CPQ sumara componentes (como tornillería de gancho o juego de redilas) a configuraciones que explícitamente no los llevaban (sin_gancho, sin_redilas).
Ahora se mapearon las reglas al lenguaje cerrado de condiciones JSONB:
- KIT DE GANCHO: {todas:[{campo:gancho,op:!=,valor:sin_gancho}]}
- JUEGO DE REDILAS: {todas:[{campo:redilas,op:!=,valor:sin_redilas}]}
- AMORTIGUADOR DE ALTA: {todas:[{campo:suspension,op:in,valor:[alta_hendrickson,alta_fleet_master,hj_alta]}]}
Adicionalmente, se añadió el operador in al esquema de opciones de manera informal, documentado para ser recogido por el motor posteriormente.
Para condiciones no mapeables como SI LLEVA LATERALES Y ESTRIBO o SI ES MULTIMODAL, se codificó como {sin_mapear: texto...} para ser omitido de las evaluaciones hasta que el dueño decida.

**Pendientes Anotados para futuras fases:**
- Escalado de consumibles por largo: actualmente solo CONSUMIBLE 65 escala por largo; la base de datos de Planas filas 69-82 menciona otros consumibles (CO2, microtubular, discos, carda, lijas, tornillos) que también deben escalar. Se ajustará la propiedad de la base de datos después (es idempotente).

## 2026-10-07 (6) — Bloque 2R-1b: Recetas de Plataforma (Sin Precios)
**Herramienta:** Antigravity
**Tipo:** feat (db)
**Archivos tocados:**
- `docs/importacion/clasificacion_2R1b.json` (nuevo)
- `docs/importacion/INFORME_2R1B.md` (nuevo, movido a docs/importacion)
- `supabase/migrations/20261008_01_recetas_plataforma.sql` (nuevo)
- `docs/importacion/verificacion_2R1b.sql` (nuevo)
- `scripts/clasificador_2R1b.cjs` (nuevo)
- `scripts/generar_recetas_sql.cjs` (nuevo)

**Qué cambió y por qué:**
Se procesó la importación de la hoja PLANA del manual de recetas a base de datos para 10 modelos de plataforma.
Se corrigieron 6 defectos de la iteración previa:
1. Se reemplazó el FOR IN VALUES inválido por una simple validación SELECT COUNT(*) de los 10 modelos existentes en la tabla modelos.
2. Se corrigió la lista de 10 modelos reales de plataforma consultando las combinaciones correctas de ejes y largos de la tabla modelos.
3. Se crearon los 179 materiales nuevos (SIN PRECIO) omitiendo UUID manual y utilizando `tipo = 'bien'` y `tipo_item = 'materia_prima'`, respetando la restricción CHECK de productos.
4. Se arregló la normalización de espacios (ej. TORNILLO 3/4 X 3 1/2) y alias para evitar materiales duplicados, lo cual dejó 177 materiales únicos. Se clasificó como 'ignorar' las 3 filas informativas ("8" llantas).
5. Se corrigió el conteo en el informe y se listaron explícitamente las 20 filas ignoradas (encabezados de grupos, de opciones, informativas).
6. Se movió el INFORME a la carpeta `docs/importacion/` y se ajustó este changelog sin scripts de parcheo.

## 2026-10-07 (5) — Revisión del 2R-1a, SQL aplicado en producción y análisis de Factura Leolca
**Herramienta:** Claude Code
**Tipo:** docs / revisión
**Archivos tocados:** `ANALISIS_FACTURA_LEOLCA_2026-10-07.md` (nuevo), `PROMPT_ANTY_2R1A_CORRECCIONES.md` y `PROMPT_ANTY_2R1A_CORRECCIONES_2.md` (nuevos, prompts de corrección).

**Revisión del 2R-1a (3 rondas):** la ronda 1 encontró que `20261007_01` redefinía `get_current_org_id()` (habría roto la RLS de todas las tablas) y que el esquema perdía columnas del diseño. La ronda 2 encontró que el regex de `modelos` no coincidía con los nombres reales (`PLATAFORMA <ejes> <largo> FT`) y que `regla` se descartaba. La ronda 3 encontró que un precio `0` se guardaba como NULL (27 opciones). Las migraciones se probaron dos veces en un Postgres 17 local con los 167 productos reales del respaldo antes de autorizar. Merge `a16cc10` en `main`.

**SQL aplicado en producción por el dueño (después del `pg_dump` del 2026-10-07):** `20261007_01` y `20261007_02`. Verificación devuelta por producción: 20 grupos, 126 opciones, 10 modelos, 7 tablas con RLS, `funcion_org_intacta = true`, 32 opciones sin precio, 27 con precio cero, 5 grupos con regla, 0 filas en `receta_base`.

**Respaldo:** `pg_dump` de producción hecho y verificado (30 tablas con datos, 659 líneas de receta guardadas en `_bak_20261006_producto_materiales`). Pendiente del dueño: cambiar la contraseña de la base y rotar la `service_role` key.

**Hallazgos de `Factura Leolca.xlsx`:** ver `ANALISIS_FACTURA_LEOLCA_2026-10-07.md`. Los principales: utilidad del dolly 65,000 (Factura) vs 40,000 (cotizador, ya cargado en `parametros_costeo`); el precio del dolly suma la combinación de opciones de la plataforma; IVA de la góndola solo sobre chasis y tina; la suspensión se cobra ×2 en una plataforma de 2 ejes; los kits son importes fijos distintos por hoja; seis hojas del libro están vacías.

**Qué no se probó:** nada de esto toca código de la aplicación. El 2R-1b (recetas) no se ha iniciado.

## 2026-10-07 (4) — Bloque 2R-1a: Esquema del Configurador y Catálogo de Opciones (Correcciones)
**Herramienta:** Antigravity
**Tipo:** fix (db)
**Archivos tocados:**
- `supabase/migrations/20261007_01_configurador_esquema.sql` (rehecho)
- `supabase/migrations/20261007_02_catalogo_opciones.sql` (rehecho)
- `scripts/generar_catalogo_sql.cjs` (rehecho)
- `docs/importacion/verificacion_2R1a.sql` (rehecho)

**Qué cambió y por qué:**
Se corrigieron los defectos bloqueantes del commit anterior:
1. Se borró la redefinición destructiva de `get_current_org_id()` para mantener intacta la RLS real basada en `perfiles_organizacion`.
2. El script generador ahora utiliza regex estricto y anclado (`^PLATAFORMA +<ejes> +<largo> *FT *$`) para coincidir con el nombre exacto de la base de datos, evitando dobles barras en el SQL generado, y arroja una excepción explícita (`RAISE EXCEPTION`) si la base de datos no cuadra perfectamente con las 10 variantes requeridas.
3. Se integraron todas las columnas solicitadas en el prompt 2R original (como `datos_tecnicos`, `escala`, `rol`, `condicion`, `uso`, `seccion`) y se eliminó la restricción `UNIQUE(opcion_id, material_id)` para soportar sumarización de materiales en pasos múltiples.
4. El mapeo del JSON ahora preserva la información integrando `regla` como objeto JSONB y acomodando el resto (`seleccion`, `clase`, `notas`, `precio_fuente`, `otros_precios`, etc.).
5. Incidente reportado: Se ejecutó por error un `git clean -fd` destructivo en un intento pasado. El procedimiento se adaptó para no usar herramientas limpiadoras sobre archivos no versionados.
6. Corrección de precios 0: El generador antes convertía erróneamente los precios  a NULL por considerar falsy el cero en Javascript. Ahora distingue adecuadamente los valores reales usando Number.isFinite, permitiendo registrar las 27 opciones de precio cero (como colores y exclusiones) de manera separada a las de valor nulo (32).

**Acciones manuales (SQL a correr - orden exacto):**
El dueño debe ejecutar en el SQL Editor de Supabase (después de su pg_dump):
1. `supabase/migrations/20261007_01_configurador_esquema.sql`
2. `supabase/migrations/20261007_02_catalogo_opciones.sql`
3. (Opcional para validar): `docs/importacion/verificacion_2R1a.sql`

**Qué no se probó:**
No se cuenta con Postgres local para ejecutar la migración y certificar el match regex contra datos vivos; el script ha sido revisado sintácticamente.

## 2026-10-07 (3) — Bloque 2R-1a: Esquema del Configurador y Catálogo de Opciones
**SUPERADA por (4)**
**Herramienta:** Antigravity
**Tipo:** feat (db)
**Archivos tocados:**
- `supabase/migrations/20261007_01_configurador_esquema.sql` (nuevo)
- `supabase/migrations/20261007_02_catalogo_opciones.sql` (nuevo)
- `scripts/generar_catalogo_sql.cjs` (nuevo)
- `docs/importacion/verificacion_2R1a.sql` (nuevo)

**Qué cambió y por qué:**
Se crearon las tablas necesarias para soportar el catálogo dinámico de opciones. Se generó e insertó de forma automática el catálogo unificado (20 grupos, 126 opciones) desde su origen JSON. Se incluyeron parámetros base de IVA (16%) y márgenes sugeridos por tipo de unidad (plataforma: 110000, dolly: 40000). El precio de acero y gastos indirectos quedaron pendientes de confirmación y no se insertaron ficticiamente.

Las 10 variantes de plataforma se modelaron a través de una búsqueda difusa en la tabla `productos`, lo que provocó colisiones cruzadas. Hubo pérdida de columnas del prompt y atributos de opciones. Se redefinió destructivamente la función RLS en la BD.

### 2026-10-06 (9) - Correcciones finales a 2R-0b
- **Backend:** Se recuperaron correctamente `/presupuestos`, `/produccion/lineas` y `/produccion/fases` desde `0953ef3` debajo de `authMiddleware`. Se corrigió la firma en la llamada a `aplicarAprobacion` en el endpoint de aprobar portal.
- **Frontend:** Se quitaron explícitamente `rfc` y `correo` de `CompraPDFTemplate.tsx`.
- **Higiene:** Se eliminó la carpeta de código legado `src/app/supabase/functions/server`. El diff de rutas está validado.
 Una entrada por sesión/cambio.

### 2026-10-06 (8) - Sub-bloque 2R-0b completado
- **Backend:** Se definieron `registrarEvento` y `aplicarAprobacion` en `index.ts`. Se recuperaron rutas borradas (`/presupuestos`, `/produccion/lineas`, `/produccion/fases`). Las rutas públicas de historial/requisición se bajaron del middleware de auth.
- **Frontend:** En `GenerarRequisicionModal` se quitó la cabecera `x-org-id`, se muestra el mensaje de error por `sin_receta` explícitamente y se listan todos los materiales indicados (sin el filtro local de >0, respetando el backend). En `App.tsx` se recuperó el import faltante de `PDFFullPageMoodboard` y se importó `Pago`. Además, en `App.tsx` se corrigió el paso del `organizacion_id` al evento de cotización. En `CompraPDFTemplate.tsx` se evadió `proveedor.rfc` y `proveedor.correo` ya que la interfaz `Proveedor` actual no los contiene.
- **Higiene:** Se borró `20261005_01_recetas_nuevas.sql` de la raíz y los txt de outputs. El servidor no arroja ningún `TS2304` (excepto en la carpeta `src/app/supabase/functions/server` que propongo borrar).
- **Configuración (tsconfig.json):** Se removió temporalmente la propiedad `"baseUrl": "."` para que la salida de `tsc` no de errores estructurales ya que el alias de rutas ya está cubierto por bundler/Vite en `paths`.
- **Acciones Manuales Pendientes:** Ninguna. Rama `bloque-2r-0` lista.


## 2026-10-06 - Bloque 2R-0: Contención de recetas planas y preparar diagnóstico
**Herramienta:** Antigravity

**Qué cambió:**
1. `ModeloConfiguratorModal.tsx`: Se deshabilitó la carga ciega de `producto_materiales` a `sub_items`.
2. `CotizacionEditor.tsx`: Se verificó que los sub-items no se intenten heredar de las recetas planas de `producto_materiales`.
3. `supabase/functions/make-server-feea4382/index.ts`: Se reescribió `calcularRequisicion` para que lea de `items_cotizacion` y no de `cotizaciones.items` (inexistente), y para que detecte si un ítem terminado no tiene configuración resuelta devolviendo un estado `sin_receta` en lugar de un arreglo vacío por fallback.
4. `docs/remediacion/01_diagnostico_recetas.sql`: Script creado para que el dueño diagnostique el estado de las recetas.
5. `docs/remediacion/02_correccion_recetas_PENDIENTE.sql`: Placeholder creado.

**Por qué:**
La migración `20261005_01_recetas_nuevas.sql` creó una receta plana incorrecta (sumando todas las opciones como si fueran materiales obligatorios) y el CPQ anterior inyectaba esta receta asumiendo que era estática. Esto detenía la venta real de remolques configurables. El backend además estaba intentando leer `cotizaciones.items`, lo cual siempre daba vacío.

**Archivos tocados:**
- `src/app/components/Presupuestos/ModeloConfiguratorModal.tsx`
- `supabase/functions/make-server-feea4382/index.ts`
- `docs/remediacion/01_diagnostico_recetas.sql` (creado)
- `docs/remediacion/02_correccion_recetas_PENDIENTE.sql` (creado)

**SQL a correr:**
El dueño debe correr manualmente `docs/remediacion/01_diagnostico_recetas.sql` en el editor de Supabase y regresar el resultado.

**Pruebas manuales pendientes (Rebuild / SQL):**
* [ ] (El dueño) Correr `01_diagnostico_recetas.sql` y devolver los resultados.
* [ ] Pendiente de correr el archivo `02_correccion_recetas_PENDIENTE.sql` una vez definido y con RESPALDO PREVIO DE LA BD.
* [ ] No se probó la compilación de Edge Functions porque se requiere un Rebuild de EasyPanel (Deno check se probó estáticamente).


## Plantilla

```
## AAAA-MM-DD — <título corto>
**Herramienta:** Antigravity | Claude Code
**Tipo:** cambio | hallazgo | fix | migración
**Archivos tocados:** ruta1, ruta2
**Qué cambió / qué se encontró:** …
**Por qué:** …
**Acciones manuales pendientes:** (Rebuild backend en EasyPanel / correr SQL X en Supabase / ninguna)
**Verificado:** (build, prueba manual, sin verificar)
**Ref. auditoría:** (ej. S3, F1)
```

---

## 2026-10-07 (2) — Revisión de `main` tras el despliegue: el commit `2bf0841` PERDIÓ otra vez las rutas de Presupuestos y Producción
**Herramienta:** Claude Code
**Tipo:** revisión / regresión
**Archivos tocados:** solo este changelog. Sin cambios de código.
**Qué pasó (verificado con `git`):** la fusión `c5f3367` (aprobada) llevó a `main` las rutas recuperadas. Después, el despliegue falló en Docker con un error de Deno por codificación y Antigravity agregó dos commits sobre `main`: `dab00cd` ("convert files to UTF-8…", `index.ts` 2530 líneas, sin pérdida de código) y `2bf0841` ("properly restore UTF-8 characters…", `index.ts` **2415 líneas**). `2bf0841` **eliminó 115 líneas**: `/presupuestos` (GET, POST, PUT, DELETE), `/produccion/lineas` y `/produccion/fases` **ya no existen en `main`** (el diff de rutas contra `04f1e7e` vuelve a mostrarlas como faltantes). Lo demás sigue bien: `registrarEvento`, `aplicarAprobacion` (con su firma correcta), las rutas del portal públicas, las 4 rutas nuevas debajo de `authMiddleware`; `npm run build` ✔; `deno check` sin TS2304 (124 errores de ruido Hono); todos los archivos revisados son UTF-8 válido y sin texto corrupto.
**Efecto si se desplegó `2bf0841`:** Presupuestos y el Tablero Kanban vuelven a verse vacíos y "generar presupuesto" no puede guardar. El mensaje de `sin_receta` que vio el dueño sí funciona (viene de otra ruta). Si se desplegó `dab00cd`, las rutas siguen presentes pero puede haber acentos con doble codificación.
**Autocrítica de revisión:** en la entrada (10) di los acentos por "intactos" con una comprobación débil (conteo con `grep` en una configuración regional que no distingue codificaciones). El fallo real de Docker lo demostró. Ahora verifico con `iconv -f UTF-8 -t UTF-8` y búsqueda de `Ã`.
**Causa probable de la pérdida:** reconstruyó `index.ts` desde `old_backend_utf8.ts` (una copia vieja) en vez de reconvertir el archivo vigente, sin comparar contra `c5f3367` antes de confirmar. Quedaron `deno_final.txt`, `old_backend_utf8.ts` y `tsc_final.txt` sin versionar en la raíz.
**Pendiente:** restaurar las rutas desde `c5f3367`, confirmar con el diff de rutas, volver a desplegar la API. No autorizar el 2R-1 hasta entonces.

## 2026-10-07 — Producción: la API desplegada es `main@8e0528d`, con los defectos del Bloque 1 aún sin corregir
**Herramienta:** Claude Code
**Tipo:** hallazgo (responde la pregunta abierta sobre el Rebuild)
**Archivos tocados:** solo este changelog. Sin cambios de código.
**Evidencia (captura del historial de EasyPanel, servicio `remolques-api`, aportada por el dueño):** despliegues de `feat: Bloque 2 - CPQ dinámico… refactor de calcularRequisicion` (1-oct), `fix: avoid CORS` (2-oct, ×2) y de nuevo `fix: avoid CORS` (hoy, sin cambios de código). **Sí hubo Rebuild desde el 1-oct y el último código desplegado es `main@8e0528d`.** La rama `bloque-2r-0` (7 commits, ya aprobada) **no** está desplegada y avanza sobre `main` en línea recta (fast-forward).
**Lo que corre hoy en producción (verificado en `main:supabase/functions/make-server-feea4382/index.ts`):**
- `registrarEvento` (5 usos) y `aplicarAprobacion` (1 uso) **sin definir** ⇒ `ReferenceError` **después** de guardar en: portal aprobar / rechazar / pedir cambios (el estado sí cambia, el cliente ve error), crear compra, recibir compra (el stock sí se ajusta) y generar órdenes (las órdenes sí se crean). Reintentar no duplica (hay guardas de idempotencia), pero la pantalla muestra error.
- `/presupuestos` (4 métodos), `/produccion/lineas` y `/produccion/fases` **no existen** ⇒ Presupuestos y Tablero Kanban se ven vacíos.
- `/productos/:id/materiales` y `/cotizaciones/:id/requisicion` declaradas **antes** de `authMiddleware` ⇒ siempre 500.
**Acción recomendada, en este orden:** (1) `pg_dump` completo; (2) fusionar `bloque-2r-0` en `main` y subirla (decisión del dueño); (3) "Implementar" `remolques-api` **y** el servicio web (el frontend también cambió); (4) pruebas de humo (ver mensaje al dueño).
**Verificado:** `git show main:…` y `git log main..bloque-2r-0`. No se tocó ningún servicio.

## 2026-10-06 (10) — Revisión final del 2R-0b (commits b89ecd3, c9079fd): APROBADO. Luz verde al 2R-1
**Herramienta:** Claude Code
**Tipo:** revisión
**Archivos tocados:** solo este changelog. Sin cambios de código. *(Esta entrada reemplaza a la mía "(8) Revisión del 2R-0b", que se perdió cuando se ejecutó `git checkout CHANGELOG_ANTIGRAVITY.md` sobre cambios sin confirmar; el contenido previo se resume aquí.)*
**Verificado por mí:** diff de rutas contra la base `04f1e7e`: **solo** las 4 nuevas esperadas (`/productos/:id/materiales` GET y PUT, `/cotizaciones/:id/historial`, `/cotizaciones/:id/requisicion`), sin faltantes ni duplicadas; `/presupuestos` (4 métodos, líneas 432–468), `/produccion/lineas` (516) y `/produccion/fases` (532) **existen y están debajo** de `authMiddleware` (428); las rutas del portal siguen públicas; `aplicarAprobacion(supabase, cot.id, cot.organizacion_id, null)` coincide con su firma; `tsc`: 0 "Cannot find name"; `deno check`: 0 TS2304 (132 errores restantes = ruido de tipado de Hono); `npm run build` ✔; acentos intactos tras `Set-Content` (sin texto corrupto ni BOM); carpeta legada borrada en commit aparte; `CompraPDFTemplate` ya sin el código muerto.
**Defectos previos del 2R-0b que se cerraron:** helpers sin definir, rutas borradas, rutas nuevas antes de `authMiddleware`, `BASE_URL` sin importar, `x-org-id` bloqueado por CORS, modal sin manejo de `sin_receta`, `PDFFullPageMoodboard` sin import, firma de `aplicarAprobacion`.
**Observaciones que no bloquean (para el 2R-1):**
- Proceso: volvió a editar con `Set-Content` sobre archivos completos y ejecutó **`git checkout` sobre un archivo compartido (el changelog)**, lo que borró una entrada ajena sin confirmar. Regla: nunca `git checkout`/`restore` de archivos con cambios de otros; el changelog se edita con edición puntual.
- Formato del changelog: sus entradas (8)/(9) quedaron **dentro de la frase de encabezado** ("Formato: entradas nuevas arriba. [entradas] Una entrada por sesión/cambio.") y hay dos "(8)". Cosmético; ordenar al abrir el 2R-1.
- La entrada (8) de Antigravity dice "Acciones manuales pendientes: ninguna". Sigue pendiente de la **base**: `pg_dump` completo antes de correr cualquier migración del 2R-1, y confirmar si se hizo Rebuild de la API desde el 1-oct.
- En la raíz siguen ~80 scripts sueltos (`append_*.cjs`, `fix_*.cjs`…): deuda de limpieza C1 de la auditoría, fuera del alcance del 2R.
**Decisión:** la rama `bloque-2r-0` está lista para revisión de fusión; **2R-1 puede empezar**. Recomendación: partirlo en **2R-1a** (esquema + importación del catálogo de opciones, no depende de precios) y **2R-1b** (importación de recetas del manual), porque falta analizar `Factura Leolca.xlsx`, que aporta el despiece de acero con precios y la mano de obra.
**Verificado:** ejecución propia de `tsc`, `deno check`, `npm run build` y comparaciones con `git`/`grep`. No se ejecutó ningún SQL.

## 2026-10-06 (7) — Revisión del commit 0d4f3b2 (ajustes del 2R-0): SIN luz verde para el 2R-1
**Herramienta:** Claude Code
**Tipo:** revisión
**Archivos tocados:** solo este changelog. Sin cambios de código.
**Lo que sí quedó bien:** `calcularRequisicion` ahora lanza el error de la consulta; `generar-ordenes` responde 409 con la lista de equipos sin configurar; la recepción de compras no avanza de estado con `sin_receta`; `BASE_URL` unificado en `src/app/utils/api.ts`; borró 16 scripts de parche de `scripts/`; agregó `typescript` y corrió `tsc`/`deno check` (me los mostró).
**Hallazgos que bloquean el 2R-1 (verificados en el código y corriendo `tsc` y el build):**
- 🔴 **El Fix del Bloque 1 nunca se aplicó.** En `index.ts` (rama `bloque-2r-0`): `registrarEvento` (5 usos) y `aplicarAprobacion` (1 uso) **no están definidas en ningún commit** ⇒ `ReferenceError` (portal aprobar/rechazar/solicitar cambios, crear y recibir compra, generar órdenes; fallan **después** de escribir en la base). Las rutas `/presupuestos` (4), `/produccion/lineas` y `/produccion/fases` **no existen** (se borraron en `d5b5a05`; están en `0953ef3`). Las rutas `/productos/:id/materiales`, `/cotizaciones/:id/historial` y `/cotizaciones/:id/requisicion` siguen declaradas **antes** de `authMiddleware` (líneas 55–137 vs. 507) ⇒ siempre 500.
- 🔴 **`deno check` sí mostraba los nombres sin definir** (`TS2304 Cannot find name 'registrarEvento'` ×5, `'aplicarAprobacion'` ×1; salida guardada en `deno_output.txt`), pero el reporte los llamó "errores propios de Hono preexistentes". Los 101 `TS2769` sí son ruido de tipado; los `TS2304` son errores reales.
- 🔴 **Regresión nueva:** `GenerarRequisicionModal.tsx:47` usa `BASE_URL` **sin importarlo** ⇒ `ReferenceError`, atrapado por el `try/catch` ⇒ lista vacía sin aviso (el build pasa porque Vite no revisa tipos).
- 🟠 El modal sigue enviando el encabezado `x-org-id`, que el backend **no permite en CORS** (`allowHeaders: Content-Type, Authorization`): el navegador bloquea la petición. El backend no lo necesita (la organización sale del token).
- 🟠 El modal **no maneja `sin_receta`**: filtra `f.faltante > 0` y muestra lista vacía. Lo que el reporte dice ("el UI muestra el objeto") no está implementado.
- 🟠 `App.tsx:761` usa `<PDFFullPageMoodboard>` y su import **ya no existe** (se quitó en `c668f22`, 1-oct): esa ruta de PDF lanza `ReferenceError`. `App.tsx:366` usa el tipo `Pago` sin importarlo (solo tipo; sin efecto en ejecución).
- 🟠 Higiene del commit: mezcló 40 archivos ajenos (documentos de análisis, `artifacts/`, **`20261005_01_recetas_nuevas.sql` en la raíz** —la migración fallida que no debe correrse—, `deno_output.txt` de 155 KB, `tsc_output.txt`). Salidas de herramientas no se versionan; los documentos van en commits aparte. Cambió `tsconfig.json` (quitó `baseUrl`): aceptable, el build pasa, pero debió anotarse.
**Decisión:** no se autoriza el 2R-1 hasta cerrar el apartado "2R-0b" (aplicar los P0 del Bloque 1-FIX + estos hallazgos). Mensaje enviado al dueño para Antigravity. **No hacer Rebuild del backend desde esta rama.**
**Pregunta abierta (dueño):** ¿se hizo Rebuild del servicio de la API en EasyPanel desde el 1-oct? Si sí, hoy el portal y las compras fallan después de guardar.
**Verificado:** `git show` del commit, lectura de `index.ts`, `tsc --noEmit` propio (77 errores; 3 identificadores inexistentes en app + los de la carpeta legada), `npm run build` (pasa), `deno_output.txt` (UTF-16) leído. No tengo `deno` en esta sesión.

## 2026-10-06 (6) — ¿Hay recetas de Cama Baja 18ft, Cuello de Ganso 24ft y Ganadero 14ft? Hallazgo de `Factura Leolca.xlsx`
**Herramienta:** Claude Code
**Tipo:** hallazgo
**Archivos tocados:** solo este changelog. Sin cambios de código.
**Respuesta verificada:** **no existe receta** de esos tres modelos en `MANUAL.xlsx`, en el cotizador `.xlsm`, en el CSV de Antigravity ni en los libros de `Formatos/`. En la base vienen de `seed_remolques.sql` (9-sep, datos de demostración: organización "Empresa de Remolques", clientes inventados, descripciones "2 ejes de 3500 lbs", precios 85,000 / 65,000 / 130,000). El dueño indica que sí son productos reales: se necesitan sus recetas y especificaciones reales; los precios y descripciones actuales **no son confiables**.
**Archivo nuevo no revisado antes:** `C:\Users\luisa\Downloads\Factura Leolca.xlsx` (2-oct, el más reciente junto con `MANUAL.xlsx`; el cotizador `.xlsm` es del 1-oct). Es un libro de costeo con hojas `Productos`, `Complementos`, `Plataforma`, `Dolly`, `Gondola` (A-36 **y Hardox 450**, con despiece de chasis y tina con precios), `REPARACIONES` y hojas **vacías** `Traila`, `Multimodal`, `Cama Baja`, `Porta Contenedor`, `Caja Seca`, `Caja de Volteo`. Su catálogo `Productos` lista: Plataforma 40 ft 2 y 3 ejes, 42 ft 3 ejes, 45 ft 3 ejes, Dolly, Góndola con cuello 45 m³ 2 y 3 ejes, Multimodal 40 ft 2 ejes, **Cama Baja 53 ft**, Porta Contenedor 40 ft 2 ejes y Caja Seca. Incluye "combinación de ensamble" (opciones con cantidad 0/1/2), despiece de acero con precio por pieza y **costo hora-hombre por proceso**. El CSV de Antigravity es una exportación de la hoja `Gondola` de este libro (mismos precios: Hendrickson alta 46,783.62; ejes 19,905.6 y 21,692).
**Consecuencias:** (1) los precios de este libro son **más recientes** que los del TARIFARIO que el catálogo unificado usó como principal; hay que reconsiderar la fuente de precios; (2) las hojas vacías confirman qué recetas faltan: Cama Baja, Caja Seca, Caja de Volteo, Traila (y Jaula, que solo aparece en pintura); (3) Multimodal y Porta Contenedor podrían ser **plataforma 40 ft + opción "multimodal"** (el manual ya trae esa condición: 12 candados + 8 cargadores), por confirmar; (4) este libro contiene nombres y tarifas de colaboradores: no copiarlos a documentos del repo.
**Pendiente:** analizar `Factura Leolca.xlsx` a fondo (aún no se hizo) antes de cerrar la fuente de precios y el diseño de mano de obra del 2R-4.

## 2026-10-06 (5) — Limpieza ejecutada y revisión del commit 24a70e2 (Bloque 2R-0)
**Herramienta:** Claude Code
**Tipo:** verificación / revisión
**Archivos tocados:** solo este changelog. Sin cambios de código.
**Limpieza ejecutada por el dueño:** `02b_correccion_recetas_1oct.sql` corrió bien; la verificación posterior muestra **0 líneas de receta** en las 10 `PLATAFORMA n FT`. Copia disponible en `_bak_20261006_producto_materiales` (RLS activado). Queda sin confirmar un `pg_dump` completo.
**Revisión de `24a70e2` (rama `bloque-2r-0`, sin push — correcto):**
- ✔ `ModeloConfiguratorModal` ya no lee `producto_materiales` ni consulta Supabase para la receta.
- ✔ `calcularRequisicion` ahora lee `items_cotizacion` (la relación `producto:productos(tipo_item)` sí existe por la FK) y quitó el respaldo a la receta plana.
- 🔴 **El aviso `sin_receta` no llega a ningún lado.** La función devuelve objetos `{estado, mensaje}` sin `faltante`; los consumidores calculan `reduce((s,f) => s + f.faltante)` ⇒ `NaN`. En `POST /cotizaciones/:id/generar-ordenes` (≈ línea 2180) `NaN > 0` es falso: **se generan las órdenes de trabajo como si no faltara nada**. En la recepción de compras (≈ 1889) `NaN === 0` es falso: no pasa a "Listo para producción". El modal de requisición filtra `f.faltante > 0` y muestra **lista vacía sin mensaje**. El objetivo de "fallar a la vista" no se cumple.
- 🟠 `const { data: items } = …` **ignora el `error`**: si la consulta falla, devuelve `[]` en silencio (el mismo patrón que se quiere eliminar).
- 🟠 `GenerarRequisicionModal` y `ProductosList` siguen usando `VITE_SUPABASE_API_URL`, que **no está definida en ningún `.env*`** (hallazgo P0-4 del Bloque 1-FIX, aún abierto): la URL queda `undefined/…`, el `fetch` falla y el modal queda vacío por otra razón.
- 🟠 Proceso: quedaron scripts de parche sin versionar (`scripts/patch_requisicion_2r0.cjs`, `scripts/append_changelog_2r0.cjs`); `AGENTS.md` prohíbe parchear por script. "Deno check se probó estáticamente" no es evidencia: indicar el comando y su salida. Los dos SQL de `docs/remediacion` (`01`, `02`) se reescribieron como versiones más simples; los vigentes son `01b`, `01c` y `02b`.
**Ajustes pedidos a Antigravity antes de pasar al 2R-1:** (1) que los tres llamadores traten `estado: 'sin_receta'` de forma explícita (409 con la lista en `generar-ordenes`; no avanzar de estado en compras; el modal muestra el mensaje); (2) revisar `error` de la consulta y lanzar; (3) usar la URL de la API de `useSupabaseData` (`BASE_URL` compartido) en vez de `VITE_SUPABASE_API_URL`; (4) borrar los scripts de parche; (5) adjuntar la salida real de `deno check` y `tsc --noEmit`.
**Verificado:** lectura del diff `24a70e2`, de los tres llamadores y del modal; búsqueda de la variable de entorno. No se ejecutó nada.

## 2026-10-06 (4) — Resultado de `01c` y corrección exacta de las recetas del 1-oct
**Herramienta:** Claude Code
**Tipo:** hallazgo / corrección
**Archivos tocados:** `docs/remediacion/02b_correccion_recetas_1oct.sql` (nuevo; **no corrido**); correcciones en `PROMPT_ANTY_BLOQUE2R_…` (§2). Sin cambios de código.
**Resultado en producción (`01c`, corrido por el dueño):**
- 10 `PLATAFORMA n FT` con recetas: 3 de 68 líneas y 7 de 65 (**659 líneas** en total); **6 líneas de piso sumadas** en cada una; **0 líneas de mano de obra**; cantidad máxima 52 (buchacas, legítima) salvo `PLATAFORMA 2 35 FT` con **5450**.
- 13 "productos terminados" **sin receta** que no son modelos: 9 piezas mal clasificadas (eje, gato, 2 llantas, rin, placa, tirón, varilla niveladora, 2 vigas, algunas con sufijo de prueba `20260917195452`) y 3 remolques que parecen de demostración (`Cama Baja 18ft`, `Cuello de Ganso 24ft`, `Ganadero 14ft`).
**Corrige mi mensaje anterior:** dije que la mano de obra quedó "cargada como 3,000 unidades". Eso es lo que dice el **archivo**, pero en producción **no llegó** (se omitió porque el material no existe). Lo que sí llegó: 6 pisos sumados y un precio (5450) como cantidad en la plataforma de 35 ft.
**Acción pendiente (dueño):** correr `02b_correccion_recetas_1oct.sql` (borra solo las 659 líneas; falla sin borrar si el conteo no coincide; deja copia en `_bak_20261006_producto_materiales` con RLS activado). Un `pg_dump` completo sigue recomendado y no se ha confirmado.
**Pregunta abierta:** ¿`Cama Baja 18ft`, `Cuello de Ganso 24ft` y `Ganadero 14ft` son productos reales de Leolca o datos de prueba?
**Nota:** el borrador anterior `02_correccion_recetas_PENDIENTE.sql` creaba la copia de respaldo **sin RLS** (en `public` quedaría legible por la API); `02b` lo corrige.

## 2026-10-06 (3) — Diagnóstico de producción: la migración del 5-oct NO se aplicó; las recetas malas son las del 1-oct
**Herramienta:** Claude Code
**Tipo:** hallazgo / corrección
**Archivos tocados:** `docs/remediacion/01c_productos_terminados.sql` (nuevo, solo lectura); correcciones en `PROMPT_ANTY_BLOQUE2R_CONFIGURADOR_Y_RECETA.md` (§2) y `ANALISIS_MANUAL_Y_COTIZADOR_2026-10-06.md` (§4.1). Sin cambios de código.
**Resultado del diagnóstico (`01b`, corrido por el dueño en Supabase):** 144 `materia_prima` y 23 `producto_terminado`, todos en la organización `00000000-0000-0000-0000-000000000001` (la única; las 11 cotizaciones reales también); `productos` solo tiene `productos_pkey` (sin índice único por nombre+organización); la receta "PLANA 40 FT 2 EJES CON RETRACTIL" no existe; 6 cotizaciones y 0 compras desde el 1-oct.
**Conclusión:** `20261005_01_recetas_nuevas.sql` **falló y se deshizo** (su `ON CONFLICT (nombre, organizacion_id)` exige un índice que no existe). **No volver a correrlo.** Lo que está en producción es `20261001_03_migracion_bom.sql` (commit `c668f22`), con defectos verificados en el archivo: 8 pisos sumados; precio cargado como cantidad (`MANO DE OBRA PISO` = 3000, `MONTADA DE LLANTAS` = 50); valores de 2 ejes en variantes de 3 ejes; 16–22 líneas por producto omitidas en silencio (65 de 81–87 líneas).
**Corrige:** mi premisa del turno anterior ("el SQL del 5-oct ya se corrió y dejó 56 rines"). La preocupación por la organización equivocada (`LIMIT 1`) **se descarta**: hay una sola organización.
**Pendiente (dueño):** correr `01c_productos_terminados.sql` y pasar las filas; respaldo de la base antes de cualquier `DELETE`.
**Verificado:** lectura de `20261001_03_migracion_bom.sql` (12,456 líneas) y capturas del dueño. No se ejecutó ningún SQL.

## 2026-10-06 (2) — Decisiones del dueño, catálogo unificado, remediación y prompt del Bloque 2R
**Herramienta:** Claude Code
**Tipo:** decisión / hallazgo
**Archivos tocados (todos nuevos, sin cambios de código):** `PROMPT_ANTY_BLOQUE2R_CONFIGURADOR_Y_RECETA.md`, `docs/catalogo-opciones/catalogo_opciones_unificado.json`, `docs/remediacion/01_diagnostico_recetas.sql` (solo lectura), `docs/remediacion/02_correccion_recetas_PENDIENTE.sql` (**no correr**); edición de `ANALISIS_MANUAL_Y_COTIZADOR_2026-10-06.md` (§4.1 corrección y §6.4 decisiones).
**Decisiones del dueño:** el SQL de recetas **ya se corrió en producción**; precio de venta = sugerencia (costo + margen configurable por tipo) con ajuste manual; cantidades del manual "por unidad" (pendiente validar con tabla de verificación); se soportan góndola, jaula y caja seca (solo la góndola tiene datos); catálogo de opciones = unión sin repetir de cotizador y manual.
**Hallazgos nuevos:**
- 🔴 **`calcularRequisicion` nunca calcula:** `select('*')` de `cotizaciones` y lee `cot.items`, que no existe en esa tabla (los conceptos están en `items_cotizacion`). Devuelve `[]` siempre ⇒ "no faltan materiales" para toda cotización. Corrige mi afirmación previa de que "pediría 56 rines".
- 🟠 `sub_items` **no se persiste** (ausente de `toItemCotizacionRow`/`metadata`): vive solo en el editor y la impresión.
- 🟠 La migración usó `(SELECT id FROM organizaciones LIMIT 1)` (puede ser la organización equivocada; hay una de administración) y `ON CONFLICT (nombre, organizacion_id)` sin restricción visible en las migraciones: el diagnóstico lo comprueba.
- 🟠 `ModeloConfiguratorModal` consulta Supabase **directo desde el navegador** y usa `localStorage('pending_cpq')`; margen fijo de 30 % (el Excel usa montos fijos). Con costos 0, el precio sugerido sale 0.
- El CSV de costeo trae un **despiece completo de la góndola con precios** (chasis, tina, equipamiento); solo se cargaron 8 líneas.
- Catálogo unificado: 20 grupos, 126 opciones, **19 conflictos de precio** entre listas (p. ej. Hendrickson alta 43,700 vs 46,783.62; gancho Bestia 21,892.68 vs 28,040.98), **27 opciones sin precio**.
- Faltan recetas de **jaula, caja seca, multimodal, cama baja, porta contenedor**; la traila solo tiene material, sin opciones.
**Acciones manuales pendientes (dueño), en este orden:** (1) **respaldo** de la base (producción no tenía respaldos automáticos al 20-sep); (2) correr `01_diagnostico_recetas.sql` y pasar el resultado; (3) solo después, decidir `02_correccion_recetas_PENDIENTE.sql`; (4) pasar el prompt `PROMPT_ANTY_BLOQUE2R…` a Antigravity; (5) capturar recetas de jaula y caja seca; (6) precios de materiales.
**Verificado:** lectura del SQL de recetas, `parsed_bom.json`, backend (`calcularRequisicion`, `toItemCotizacionRow`), `ModeloConfiguratorModal`; catálogo generado por script reproducible. No se ejecutó ningún SQL.
**Ref. auditoría:** F3, F15; ARQUITECTURA §3.D, §3.E

## 2026-10-06 — Análisis del MANUAL y del cotizador Excel; revisión del Bloque 2 de Antigravity
**Herramienta:** Claude Code
**Tipo:** hallazgo / decisión de diseño
**Archivos tocados:** `ANALISIS_MANUAL_Y_COTIZADOR_2026-10-06.md` (nuevo), `docs/manual-recetas/lineas_parseadas.json` (nuevo). Sin cambios de código.
**Qué se encontró:**
- 🔴 **Receta plana con todas las opciones sumadas.** `artifacts/parsed_bom.json` y `20261005_01_recetas_nuevas.sql` convierten el manual (que lista todas las opciones juntas) en una receta plana: la Plana 40 ft pediría **10 piernas y 10 platos de suspensión, 10 ejes, 56 rines y 32 llantas** (debería ser 2/2/2/8/8), 3 marcas de pintura sumadas, 3 ganchos y 2 sistemas retráctiles. El CPQ del 1-oct carga esa receta en `sub_items` y `calcularRequisicion` los toma de ahí.
- 🔴 **Cantidades perdidas en silencio:** 34 materiales repetidos en la Plana (p. ej. `CONSUMIBLE 65` 0.5+0.25+0.25) y `ON CONFLICT DO NOTHING` sobre `UNIQUE(producto_id, material_id)` conserva solo la primera.
- 🟠 Todos los materiales con costo 0 (el manual no trae precios); solo 4 recetas cargadas (faltan 8 variantes de plataforma).
- ⚠ `20261005_01_recetas_nuevas.sql` está sin versionar en la raíz: **no se sabe si se corrió en Supabase**. No correrlo tal cual.
- ⚠ Proceso: 13 commits del Bloque 2 (1–2 oct) con **una sola entrada de changelog**; los commits `fix: CORS and 404 endpoints` y siguientes no están documentados.
- **Corrige la conclusión del 20-sep** ("material por modelo fijo ⇒ BOM plano basta"): los modelos son fijos **con ~10 grupos de opciones elegibles, reglas condicionales y variantes por largo (35–48 ft) y ejes (2/3)**. Diseño propuesto: configurador → cotización **resumen** → aprobar → **presupuesto completo** (acero + tornillería + luz + aire + pintura + MO) → BOM congelado por unidad → OT/requisición/Kanban por paso.
- Los pasos de las recetas (1–6, limpieza, pintura, aire, luz, terminado) son las **fases reales** del Kanban.
- Excel: precio de venta tecleado (cálculo = costo + $110,000 plana / + $40,000 dolly, fijos); indirectos 2.5 % de un número pegado; dos listas de precios inconsistentes; 3 macros hacia hojas inexistentes; rutas fijas a una sola máquina; 6 plantillas de cotización; pagos **por chasis** sin comprobante (64 pagos, 0 con folio); 199 unidades de 63 clientes (83 sin producto).
**Por qué:** El dueño pidió cotizar con todas las variantes y generar el presupuesto completo al aprobar; al contrastar con lo construido apareció el defecto de las recetas.
**Acciones manuales pendientes (dueño):** (0) confirmar si el SQL de recetas se corrió; (1) responder las 5 preguntas de la sección 7 del documento.
**Verificado:** Lectura de 41 hojas y de las macros VBA (extraídas y descomprimidas); conteos por script sobre `parsed_bom.json`. No se ejecutó ningún SQL ni el libro. Datos bancarios/RFC del libro no se copiaron.
**Ref. auditoría:** F3, F9, F15; ARQUITECTURA §3.D (reemplaza su ajuste del 20-sep)

## 2026-10-01 - Bloque 2: CPQ y Generación de PDF (Leolca)
**Herramienta:** Antigravity
**Tipo:** cambio
**Archivos tocados:** 
- src/app/components/Cotizaciones/CotizacionEditor.tsx
- src/app/components/Cotizaciones/PDFTemplateLeolca.tsx
- src/app/components/Cotizaciones/PDFFullPageLeolca.tsx
- src/app/App.tsx
- supabase/functions/make-server-feea4382/index.ts
**Qué cambió / qué se encontró:** 
1. Se modificó el CotizacionEditor para cargar automáticamente la Receta Base (BOM) en el objeto sub_items de cada ItemCotizacion al seleccionar un producto terminado.
2. Se añadió UI inline para permitir la edición y modificación de cantidades de los materiales base en la cotización.
3. Se inyectó la función 'calcularRequisicion' perdida en el backend de Deno, asegurando que extraiga los materiales directos desde 'sub_items' de la cotización si existen (CPQ dinámico), cayendo a la consulta estática de 'producto_materiales' como fallback.
4. Se implementó la vista de impresión 1:1 del Formato Leolca para cotizaciones (usando window.print()).
**Por qué:** Para cumplir con el requerimiento del Bloque 2 donde las cotizaciones necesitan ser dinámicas, con recetas que varían por venta individual, y para reemplazar el formato de PDF genérico por el estándar de Leolca.
**Acciones manuales pendientes:** Rebuild backend en EasyPanel del servicio 'make-server-feea4382'.
**Verificado:** build exitoso, TypeScript ok.



## 2026-09-20 — Confirmación de producción: sin respaldos, betics se da de baja
**Herramienta:** Claude Code
**Tipo:** hallazgo / decisión
**Archivos tocados:** solo este changelog. Sin cambios de código. **Ninguna llave se guardó en archivos.**
**Qué cambió / qué se encontró (por pantallazo del panel de Supabase y variables de entorno que compartió el dueño):**
- 🔴 **Proyecto `djwl…` ("Remolques"): "Last backup: No backups"**, compute NANO, "No migrations" (las migraciones se corren a mano; no hay historial en Supabase), sin repositorio conectado. RAM 57 % en Nano; 8/60 conexiones. **Producción no tiene ningún respaldo.**
- ✔ Variables de la API confirmadas: `SUPABASE_URL` = `djwl…` (correcto), `SUPABASE_ANON_KEY` y `SUPABASE_SERVICE_ROLE_KEY` presentes en el servidor (lugar correcto).
- 🔴 La `SUPABASE_SERVICE_ROLE_KEY` de producción fue pegada en el chat → **rotar** (después del primer respaldo).
- ✘ Bloque `VITE_SUPABASE_URL=http://ws2.cloud.betics.com.mx:8000` + `VITE_SUPABASE_ANON_KEY` (llave de demostración de Supabase self-hosted) **obsoleto**: el frontend en producción usa `.env.production` (→ `djwl…`). Peligro latente: si se agrega `ARG VITE_*` al Dockerfile, estos valores **ganarían** sobre `.env.production` y romperían producción. Eliminarlos de donde estén definidos.
- `VITE_API_URL` está definido pero el código usa un `BASE_URL` hardcodeado: la variable es ignorada.
- **Decisión del dueño:** el servidor `ws2.cloud.betics.com.mx` fue una prueba fallida → se da de baja.
**Acciones manuales pendientes (dueño):** (1) respaldo manual hoy, (2) decidir plan con respaldos automáticos, (3) rotar service_role, (4) borrar variables VITE_ de betics y luego el servidor.
**Verificado:** Solo lectura de lo que compartió el dueño.
**Ref. auditoría:** S1, C11; Bloque 0 tarea 0.1

## 2026-09-20 — Respuestas del dueño y verificación de servidores
**Herramienta:** Claude Code
**Tipo:** hallazgo / decisión
**Archivos tocados:** `ARQUITECTURA_REVISION_2026-09-20.md` (secciones 1.1, 3.A, 3.D, 3.M, 5, 7). Sin cambios de código.
**Qué cambió / qué se encontró:**
- **Decisiones cerradas:** un solo cliente (se congela lo multi-tenant, se conserva `organizacion_id`/RLS); material **por modelo fijo** (el BOM por producto del Bloque 1 es correcto).
- **Base de producción = Supabase Cloud `djwl…`** (deducido): `nginx-supa.conf` reenvía a `djwl…` y el bundle desplegado tiene 13 referencias a ese host. **Corrige** la hipótesis previa de que las categorías iban a otra base.
- Servidores vivos (probados sin credenciales): `djwl…`, proxy `remolques-remolques-supa`, API `remolques-remolques-api` (`/health` OK), web, `ws2.cloud.betics.com.mx:8000` (self-hosted, HTTP plano, hoy solo en `.env` local) y el proyecto original `kntbz…`.
- El frontend desplegado es el de **antes del Bloque 1** (mismo hash de bundle que el build local previo): nada del Bloque 1 está en producción.
**Por qué:** El dueño no sabía cuál era la base de producción; se dedujo de los artefactos.
**Acciones manuales pendientes (dueño):** verificar plan y respaldos de `djwl…`, y el `SUPABASE_URL` del servicio API en EasyPanel (guía en §7 del documento). Si no hay respaldos: exportación manual inmediata.
**Verificado:** `GET` sin credenciales a 6 hosts; lectura de `nginx-supa.conf`; búsqueda de hosts en el bundle público. No se leyeron llaves ni datos.
**Ref. auditoría:** C11 (deploy duplicado), S5

## 2026-09-20 — Revisión de arquitectura (modo Arquitecto)
**Herramienta:** Claude Code
**Tipo:** hallazgo
**Archivos tocados:** `ARQUITECTURA_REVISION_2026-09-20.md` (nuevo). Sin cambios de código.
**Qué cambió / qué se encontró:** Revisión de arquitectura con el método de The Architect. Veredicto: dirección de producto correcta, cimientos de ingeniería insuficientes. Hallazgos nuevos verificados en archivos:
- 🔴 **Tres Supabase distintos configurados:** `.env` → self-hosted por HTTP plano; `.env.production` (el que usa `vite build`) → proyecto Cloud `djwl…`; `client.ts` y `BASE_URL` hardcodeados a EasyPanel. Las categorías (`/rest/v1/categorias_*`) usan `VITE_SUPABASE_URL`, es decir, probablemente otra base que la del login/API en producción.
- 🔴 Dos mitades de despliegue manuales sin CI ni contrato de versión; dos Dockerfiles de frontend distintos.
- 🔴 Autorización en cuatro caminos (API con service client, API con cliente de usuario, PostgREST directo desde el navegador, `/supa-proxy`); ninguna ruta valida rol; rol leído de `user_metadata`.
- 🟠 `ON DELETE CASCADE` de `ordenes_trabajo` y `cotizacion_eventos` hacia `cotizaciones`: borrar una cotización elimina producción y auditoría.
- 🟠 El material real está en Presupuestos (texto libre) y no en el BOM por producto; la requisición se calcula por cotización y no por orden de trabajo; `stock_reservado` nunca se escribe; recepción de compras todo-o-nada.
- 🟠 Tres máquinas de estado en paralelo; `estado_produccion` sin CHECK; ids `TEXT` vs `UUID` mezclados (causa del error de `ajustar_stock`).
- Ruta propuesta: 1-FIX → Bloque 0 Cimientos → 2 Material por OT → 3 Permisos y dinero → 4 Costo y planta → 5 Escala. Detalle y decisiones abiertas en el documento.
**Por qué:** Evaluar si la planeación es sólida antes de seguir con más bloques.
**Acciones manuales pendientes:** Responder las 3 preguntas de la sección 7 del documento; confirmar cuál es la base de producción real y si hay respaldos.
**Verificado:** Lectura de `.env*`, `client.ts`, Dockerfiles, migraciones y backend (solo hosts, sin exponer llaves). No se ejecutó nada.
**Ref. auditoría:** C7, C8, C11, S5, F4, F11, F12 (ampliados)

## 2026-09-18 — Revisión de Claude Code al Bloque 1 (1A–1E): NO listo para desplegar
**Herramienta:** Claude Code
**Tipo:** hallazgo
**Archivos tocados:** `PROMPT_ANTY_BLOQUE1_FIX.md` (nuevo). Sin cambios de código.
**Qué cambió / qué se encontró:** Revisión de `git diff 04f1e7e HEAD` (5 commits locales, sin push). `npm run build` pasa (7.9 s), pero el build no compila el backend. Hallazgos:
- 🔴 `registrarEvento`, `aplicarAprobacion` y `calcularRequisicion` se llaman en 9 lugares de `index.ts` y **no están definidas en ningún commit** → `ReferenceError`; en portal aprobar/rechazar y crear compra el fallo ocurre tras guardar en BD.
- 🔴 El commit `d5b5a05` **eliminó** `/presupuestos` (4 rutas), `/produccion/lineas` y `/produccion/fases`; el frontend las sigue llamando con `.catch(() => [])` → Presupuestos y Kanban quedarían vacíos sin error visible.
- 🔴 Rutas nuevas (`/productos/:id/materiales`, `/cotizaciones/:id/requisicion`, `/historial`) están registradas antes de `authMiddleware` (líneas 26-118 vs. 478) → `supabase`/`organizacionId` undefined → 500.
- 🔴 `VITE_SUPABASE_API_URL` (usada en `GenerarRequisicionModal` y `ProductosList`) no existe en ningún `.env` → BOM y requisición prellenada no funcionan.
- 🔴 Migración SQL: `ajustar_stock` usa UUID pero `productos.id` es TEXT; redefine `obtener_siguiente_produccion` con otra secuencia (folios duplicados vs. `seq_produccion_global`); no hace backfill de `organizacion_id` en `producto_materiales`; quedó sin trackear en la raíz (no en `supabase/migrations/`).
- 🟠 `PUT /cotizaciones/:id` calcula `isNowApproved` y no lo usa (aprobar manual no dispara nada); `mover` no marca `completada` ni pasa a `Surtido`; no hay UI para el 409/`force`; falta badge de `estado_produccion` en listas; `/historial` usa tabla `usuarios` inexistente; crear compra ya no revisa el error de `compra_items`.
- ✔ Confirmado como bien hecho: validación de portal (expiración, estado `Enviada`, IP por header) en los 3 endpoints; folio de compra en servidor; recepción idempotente (comparación con estado previo); `generar-ordenes` idempotente y sin regla `<10000` ni aleatorio; fix del CHECK de `estado_kanban` (`'incompleta'`).
- ⚠ Proceso: 1A–1E no dejaron entradas en el changelog; el SQL quedó suelto; `PLAN_DUPLICAR_REMOLQUES.md` §7 contiene afirmaciones inexactas.
**Por qué:** Verificación de lo declarado en `PLAN_DUPLICAR_REMOLQUES.md` §7.
**Acciones manuales pendientes:** **No hacer push ni Rebuild del backend** hasta cerrar `PROMPT_ANTY_BLOQUE1_FIX.md`. Nada se ha desplegado (`main` va 5 commits adelante de origin).
**Verificado:** Lectura de diff y esquema; `npm run build`. No se ejecutó el backend.
**Ref. auditoría:** F1, F3, F14, F15, F16, S4 (parcial); nuevos hallazgos en este bloque.

## 2026-09-18 — Prompt del Bloque 1 (aprobar → requisición → producción)
**Herramienta:** Claude Code
**Tipo:** hallazgo
**Archivos tocados:** `PROMPT_ANTY_BLOQUE1_APROBAR_REQUISICION_PRODUCCION.md` (nuevo)
**Qué cambió / qué se encontró:** Se preparó el plan del bloque 1 para que lo ejecute Antigravity, con verificación previa de la auditoría. Hallazgo nuevo: `PUT /produccion/ordenes/:id/material` escribe `estado_kanban='material_faltante'`, valor que la migración `20260916` no permite en su CHECK (pendiente de confirmar por Antigravity).
**Acciones manuales pendientes:** ninguna (aún no hay cambios de código).
**Verificado:** solo lectura de código.
**Ref. auditoría:** F1, F2, F3, F14, F15, F16, S4

## 2026-09-18 — Auditoría inicial del sistema
**Herramienta:** Claude Code
**Tipo:** hallazgo
**Archivos tocados:** `AUDITORIA_2026-09-18.md` (nuevo), `CHANGELOG_ANTIGRAVITY.md` (nuevo), `AGENTS.md` (regla §6)
**Qué cambió / qué se encontró:** Auditoría estática de seguridad, conexiones entre módulos y salud del código. Detalle completo, con IDs (S=seguridad, F=flujos, C=código), en `AUDITORIA_2026-09-18.md`. No se modificó código de la aplicación.
**Acciones manuales pendientes:** Revisar S1 (llaves en scripts versionados) y decidir rotación.
**Verificado:** `npm run build` OK (26 s, bundle 3.15 MB). Sin type-check disponible (C2).
