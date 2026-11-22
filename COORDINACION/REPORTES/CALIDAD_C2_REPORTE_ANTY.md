# Reporte Técnico — Calidad, Parte 2 de 2: Pantallas, Editor de Plantillas e Impresión

**Fecha:** 2026-11-21  
**Rama:** `calidad-c2-pantallas-2026-11-21` (worktree `..\Remolques_calidad_c2`, desde `main` `c440aba`)  
**Referencia:** `PROMPT_ANTY_CALIDAD_C2_PANTALLAS_2026-11-21.md`, `COORDINACION/PLAN_CAMBIOS_VISITA_2026-11-20.md` (Bloque C)

---

## 1. Qué se construyó (archivos y alcance)

1. **`src/app/components/Calidad/calidadUtils.ts`** y **`supabase/functions/make-server-feea4382/motor/calidad_ui_utils.test.ts`**:
   - Lógica pura: `normalizarConfigPlantilla`, `agruparResultadosPorClave`, `contarResumenPorPlantilla`, `contarResumenGrupo`, `obtenerSiguienteNoConforme`, `etiquetaResultado`, `armarLoteResultados`, `parsearLineasActividades`, `resolverPlantillaSugerida` (incluyendo Cama baja tipo `'05'`) y `traducirErrorCalidad`.
2. **`src/app/components/Calidad/calidadApi.ts`**:
   - Cliente tipado contra los endpoints `/calidad/*` y `/produccion/operarios`, propagando `CalidadApiError` con `codigo` e `inspeccionId` en español.
3. **`src/app/components/Calidad/CalidadPage.tsx`** (`/calidad` y `/calidad/plantillas`):
   - **Pestaña Inspecciones**: filtros por formato, estado, línea y "Solo con no conformes"; tabla con folio, formato, equipo/NIV, progreso, no conformes, estado y fechas; diálogo "Nueva inspección" que sugiere automáticamente la plantilla activa (incluida Cama baja para tipo `05`), deja elegir otra plantilla activa y ofrece "Abrir la que ya existe" ante `YA_EXISTE`.
   - **Pestaña Plantillas**: acciones **Nueva**, **Duplicar** (a otra línea/formato), **Nueva versión**, **Editar** (solo borrador), **Publicar** (con confirmación y aviso de archivo de versión anterior), **Restaurar esta versión** (para archivadas) y **Eliminar** (borradores sin inspecciones).
4. **`src/app/components/Calidad/CalidadInspeccionModal.tsx`**:
   - Modal de alto fijo con encabezado y pie fijos y scroll interno, sin scroll horizontal en tableta (`768px`) ni móvil (`375px`).
   - Autoguardado por lotes con anti-rebote (`550ms`), indicador `Guardando... / Guardado / Error` con botón **Reintentar**, y confirmación si se sale con cambios pendientes.
   - Botones segmentados por unidad (`√`/`X` o `Sí`/`No`, más `N/A`), colaborador (lista de operarios o texto libre), fecha por omisión al marcar, recordatorio discreto si un no conforme no tiene observación, atajos por grupo ("Todo conforme" con confirmación y "Aplicar al grupo"), barra de progreso + botón **"Siguiente no conforme"**.
   - **Cerrar / Reabrir / Nueva re-inspección**: muestra advertencias de pendientes y no conformes sin bloquear.
5. **`src/app/components/Calidad/CalidadImpresion.tsx`**:
   - Portal en `document.body` (`z-[100]`) con `@media print` en tamaño **carta**, `thead` repetido en cada página, `break-inside: avoid` en filas, `break-after: avoid` en encabezados de grupo, encabezado corporativo reutilizando `decidirLogoEncabezado` y `ajustes`.
   - Modos **Imprimir** (con datos y marca `X` explícita en no conformes para copias B/N) e **Imprimir en blanco**, fiel a los dos Excel (`CONTROL DE CALIDAD TOTAL` y `INSPECCIÓN CONTROL DE CALIDAD DE UNIDAD EN PRODUCTO TERMINADO`).
6. **`src/app/components/Calidad/CalidadPlantillaEditorModal.tsx`**:
   - Editor de borradores: nombre, revisión y fecha de revisión del formato, 1 o 2 unidades con nombres, etiquetas de resultado, interruptor `bloquea_liberacion` apagado por defecto con explicación, grupos y actividades con reordenamiento por botones (sin librerías de drag-and-drop), **"Pegar varias líneas"**, **Vista previa de impresión** y **Publicar**.
7. **`src/app/components/Calidad/OrdenCalidadTab.tsx`** + **`OrdenTrabajoDetalleSheet.tsx`**:
   - Pestaña **"Calidad"** reutilizable dentro del detalle de orden con tarjetas de Control total y Entrega, enlace a `Calidad → Plantillas` si falta plantilla.
8. **`MatrizProduccionView.tsx`**, **`OrdenesTrabajoList.tsx`**, **`ModernLayout.tsx`**, **`App.tsx`**:
   - Una sola petición `GET /calidad/resumen-ordenes` para todo el tablero mostrando `Calidad X/Y` y badge `N NC` en la columna Avance.
   - Aviso no bloqueante con confirmación ("Continuar de todos modos") al cambiar una orden a **Liberado** sin inspección de entrega cerrada o con no conformes.

---

## 2. Pruebas y Verificación

- **Pruebas Deno desde raíz del repo**:
  - Antes (C1 Ronda 2): `247 passed | 0 failed`
  - Después: **`254 passed | 0 failed`** (+7 pruebas nuevas en `motor/calidad_ui_utils.test.ts`).
- **Prueba real en navegador (Chrome Headless CDP contra Vite + API local + Postgres `test_calidad_c2`)**:
  - `Console errors: 0 []`
  - Creación de inspección `CCT-000001`, llenado, autoguardado (`Guardado` visible) y **persistencia tras recarga** (`Progreso: 2 / 116` y `No conformes: 1` verificados).
  - Cierre con advertencias (sin bloqueo), impresión con datos y en blanco (`CalidadImpresion`), duplicación de Plataforma → `"Dolly (control total)"`, edición y publicación.
  - **Responsive sin scroll horizontal**:
    - Tableta `768px`: `winW: 768, docScrollW: 768, dlgClientW: 735, dlgScrollW: 735`.
    - Móvil `375px`: `winW: 375, docScrollW: 375, dlgClientW: 358, dlgScrollW: 358`.
  - **Capturas reales** en `COORDINACION/EVIDENCIA/`:
    - `calidad_01_inspecciones.png`
    - `calidad_02_llenado_autoguardado.png`
    - `calidad_03_cerrar_advertencias.png`
    - `calidad_04_impresion_datos.png`
    - `calidad_05_impresion_blanco.png`
    - `calidad_06_plantillas_duplicar_editar.png`
    - `calidad_07_tableta_768.png`
    - `calidad_08_movil_375.png`
- **`npm run build`**, **`tsc --noEmit`** (0 nombres sin definir) y **`node scripts/verificar.mjs --limpio`**: **11/11 comprobaciones OK**.
- **Servidor y BD**: **0 cambios** al backend ni a migraciones.

---

## 3. Qué falta por confirmar con Luis

1. Equivalencia de fase en Control Total para los procesos `2` (**Ensamble de chasis** → Dispositivo) y `9` (**Resoldado** → Perchas), marcados con `"Fase por confirmar"` en el editor y en la pantalla de llenado.
2. Captura de `revision_formato` y `fecha_revision_formato` en cada plantilla desde el editor.
3. Creación/duplicación desde el editor de las plantillas faltantes por diseño (`control_total` Dolly, `control_total` Góndola, `entrega` Tráila).

---

## 4. Despliegue (cuando se apruebe el merge)

1. **Migración SQL**: **No requerida** (la parte 1 ya está en `main`).
2. **Backend (`remolques-api`)**: **No requiere rebuild** (0 cambios de servidor).
3. **Frontend (`remolques-web` en EasyPanel)**: Hacer **Rebuild**.

---

## 5. Ronda 2 (correcciones tras revisión de Claude `CALIDAD_C2_REVISION_CLAUDE.md`)

1. **D1 — Refresco sin desmontar modal y cola de autoguardado de un solo vuelo**:
   - `OrdenCalidadTab.cargar(silencioso = false)` evita activar `loading` en refrescos de fondo tras `onActualizado`, manteniendo montado `CalidadInspeccionModal`.
   - `CalidadInspeccionModal` usa `guardandoEnVueloRef`, `limpiarLoteEnviado` y drenado automático si llegan cambios mientras una petición sigue en vuelo.
2. **D2 — Bloqueo de cierre con cambios sin guardar**:
   - `enviarLotePendiente` retorna `boolean`; `handleConfirmarCierre` evalúa `puedeCerrarInspeccion(pendientesRef.current.size)` y aborta el cierre con `toast.error` si queda algún cambio pendiente o falló el guardado.
3. **D3 — Unidad activa de observación en formatos multi-unidad**:
   - Extraídas `seleccionarUnidadObservacion` y `faltanObservacionesNoConforme` en `calidadUtils.ts`; colaborador, fecha y observaciones se ligan a la primera unidad con resultado (ej. Plana 2 si solo Plana 2 tiene marca) y se deshabilitan con `"Marca primero un resultado"` cuando no hay ninguno.
4. **D4 — Aviso al liberar sobre la inspección vigente por formato**:
   - `OrdenesTrabajoList.tsx` usa `avisosAlLiberar(insps)` de `calidadUtils.ts` (evalúa solo el intento más alto por formato y corrige singular/plural `"1 punto marcado"`). Singular/plural corregido también en el diálogo de cierre de `CalidadInspeccionModal.tsx`.
5. **D5 y Menores 1–6**:
   - `TableroProduccionPage` pasa `lineaClave`, `ajustes` y `onCalidadActualizada` (`calidadRefreshKey`) a `OrdenTrabajoDetalleSheet` → `OrdenCalidadTab` y `MatrizProduccionView` (refresco en vivo de insignias + `title` explicativo).
   - `OrdenCalidadTab` ya no deshabilita `Iniciar` si no hay plantilla preseleccionada y elimina el texto engañoso para Plataforma normal.
   - `CalidadImpresion.tsx` llama `decidirLogoEncabezado(ajustes, 'claro')` (corrige TS2554) y formatea fechas a `DD/MM/AAAA` con `formatearFechaImpresion`.
   - Encabezado plegable en móvil (`375px`) dentro de `CalidadInspeccionModal` y toast de re-inspección con el nombre de la plantilla usada.
6. **Pruebas Deno, mutaciones y navegador (Ronda 2)**:
   - `calidad_ui_utils.test.ts` ampliado a **13 pruebas** (suite completa: **`260 passed | 0 failed`**); mutaciones M4, M9, M10, M14–M19: **10/10 eliminadas, 0 sobrevivientes**.
   - Prueba real en Chrome CDP por la ruta **Tablero → Sheet → Calidad**:
     - `calidad_r2_01_tablero.png`, `calidad_r2_02_sheet_tab.png`, `calidad_r2_03_modal_scroll_d1.png` (latencia 450ms, scroll en `900px` sin perder posición), `calidad_r2_04_plana2_obs.png` (solo Plana 2 + observación persistida en Postgres), `calidad_r2_05_cierre_bloqueado_d2.png` (API cortado → cierre abortado con aviso), `calidad_r2_06_movil_375.png` (encabezado plegable en 375px).
