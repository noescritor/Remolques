# Reporte de Corrección: Enlaces a la API (Portal, Correo, IA)

**Fecha:** 2026-11-05  
**Autor:** Antigravity  
**Revisión:** Claude Code  
**Aprobación final y despliegue:** Luis  
**Rama:** `urls-api-2026-11-05`  
**Directorio de trabajo:** `..\Remolques_urls`  
**Base:** `main` en `483e3db`  

---

## 1. Contexto del Problema

El frontend tenía dos formas de comunicarse con el backend:
1. **Vigente y correcta:** `BASE_URL` definida en `src/app/utils/api.ts` (`https://remolques-remolques-api.gehkp3.easypanel.host`), que apunta directamente al servicio Deno en EasyPanel (`remolques-api`).
2. **Obsoleta y fallida:** `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/make-server-feea4382`, que devolvía `404 "Requested function was not found"` porque la Edge Function de Supabase ya no está desplegada tras la migración a EasyPanel.

Debido a esta discrepancia, cinco llamadas en producción fallaban:
- **Portal del cliente:** Carga de cotización (`/portal/:token`), aprobación (`/aprobar`), rechazo (`/rechazar`), solicitud de cambios (`/solicitar-cambios`) y vista PDF pública (`PortalPDF.tsx`).
- **Envío de cotización por correo:** Diálogo `EnviarEmailDialog.tsx` (`/enviar-email`).
- **Asistente de IA en el editor de cotizaciones:** Botón para mejorar descripción (`/ia/mejorar-descripcion`) y botón para redactar notas (`/ia/generar-nota`) en `CotizacionEditor.tsx`.

---

## 2. Modificaciones Realizadas

### 2.1 Cambios en Código Fuente

Se sustituyeron todas las rutas obsoletas por `BASE_URL` importado de `utils/api.ts` (sin prefijo `/functions/v1/make-server-feea4382`), preservando intactos los encabezados y cuerpos de solicitud:

1. **`src/app/components/Cotizaciones/CotizacionEditor.tsx` (~L537 y ~L556):**
   - Se removió la declaración local `const BASE_URL = `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/make-server-feea4382`;` en `mejorarDescripcionConIA` y `generarNotaConIA`.
   - Ambas funciones ahora usan el `import { BASE_URL } from '../../utils/api';` ya existente a nivel de módulo.
   - Conserva headers de autenticación (`Authorization: Bearer ${token}`).

2. **`src/app/components/Cotizaciones/EnviarEmailDialog.tsx` (L63):**
   - Se añadió `import { BASE_URL } from '../../utils/api';`.
   - Se actualizó el endpoint a `${BASE_URL}/enviar-email`.
   - Conserva headers de autenticación (`Authorization: Bearer ${token}`).

3. **`src/app/components/Portal/PortalCliente.tsx` (L15):**
   - Se reemplazó la constante local por `import { BASE_URL } from '../../utils/api';`.
   - Todas las llamadas (`/portal/${token}`, `/aprobar`, `/rechazar`, `/solicitar-cambios`, `/pdf`) ahora se dirigen al backend de EasyPanel.
   - Conserva headers existentes (`Content-Type: application/json`).

4. **`src/app/components/Portal/PortalPDF.tsx` (L8):**
   - Se reemplazó la constante local por `import { BASE_URL } from '../../utils/api';`.
   - La llamada `fetch(`${BASE_URL}/portal/${token}`)` ahora consulta el backend vigente.

---

## 3. Auditoría de Referencias en `src/`

### 3.1 Búsqueda de `functions/v1` en `src/`
Ejecución de `git grep -n "functions/v1" src/`:
- **Resultado:** **0 coincidencias** en archivos de aplicación.

### 3.2 Búsqueda de `VITE_SUPABASE_URL` en `src/`
Ejecución de `git grep -n "VITE_SUPABASE_URL" src/`:
- **Resultado:** 8 coincidencias, todas en `src/app/hooks/useSupabaseData.ts`:
  - Líneas 106, 121, 134: CRUD de `categorias_producto` vía PostgREST directo (`${VITE_SUPABASE_URL}/rest/v1/categorias_producto`).
  - Líneas 148, 162, 175: CRUD de `categorias_cliente` vía PostgREST directo (`${VITE_SUPABASE_URL}/rest/v1/categorias_cliente`).
  - Líneas 308, 312: Carga inicial de categorías de producto y cliente vía PostgREST directo.
- **Clasificación:** **usan el host directo en vez del proxy, sin cambio**. Estas rutas sí existen en Supabase PostgREST, llevan `apikey` y `Authorization`, y funcionan normalmente.

### 3.3 Búsqueda de `make-server-feea4382` en `src/`
Ejecución de `git grep -n "make-server-feea4382" src/`:
- Solo importaciones de tipos y utilidades TypeScript desde `supabase/functions/make-server-feea4382/motor/` (`acero.ts`, `escalas.ts`). Cero cadenas de URL o llamadas de red.

---

## 4. Prueba Automatizada de Regresión

Se creó la prueba unitaria Deno en [`src/app/utils/urls_api.test.ts`](file:///c:/Users/luisa/Downloads/proyectos_antygravity/Remolques_urls/src/app/utils/urls_api.test.ts):
1. **Validador de BASE_URL:** Asegura que `BASE_URL` inicie con `https://`, apunte a `easypanel.host` y no termine con diagonal.
2. **Escáner recursivo de prevención:** Recorre todo `src/` analizando archivos `.ts`, `.tsx`, `.js` y `.jsx`, y falla automáticamente si se detecta cualquier referencia a `"functions/v1"`.

Resultado de ejecución:
```text
running 2 tests from ./src/app/utils/urls_api.test.ts
urls_api: BASE_URL está configurada hacia el backend vigente de EasyPanel ... ok (630µs)
urls_api: Cero referencias a funciones viejas de Supabase en todo el código fuente de src/ ... ok (62ms)

ok | 2 passed | 0 failed (74ms)
```

---

## 5. Verificación de Integridad del Repositorio

Salida real de `node scripts/verificar.mjs --limpio`:

```text
== 1. Archivos de parche o temporales nuevos
  OK     Sin parches ni temporales

== 2. Codificación de los archivos modificados
  OK     UTF-8 sin BOM ni mojibake — 5 archivos revisados

== 3. Sintaxis de .ts/.tsx modificados
  OK     Sintaxis válida

== 4. TypeScript (tsc --noEmit)
  OK     tsc: 0 nombres sin definir/duplicados
  OK     tsc: el total de errores no sube — 44 (baseline 55)

== 5. Build de Vite
  OK     npm run build

== 6. Pruebas Deno
  OK     Pruebas Deno — 273 pasan, 0 fallan

== 7. Arranque real del API
  OK     El API arranca — Listening on http://localhost:8000/

== 8. Contexto del Dockerfile.backend
  OK     Contexto del Dockerfile.backend — deno cache index.ts exitoso

== 9. Checkout limpio de HEAD (git archive)
  OK     Pruebas Deno en HEAD limpio — 273 pasan, 0 fallan
  OK     El API arranca en HEAD limpio — Listening on http://localhost:8000/

============================================================
RESULTADO: TODO OK  (11/11 comprobaciones)
```

El total de pruebas Deno pasó de **271 a 273**, cumpliendo con la restricción de no descender.

---

## 6. Historial de Commits en la Rama

1. `ec0a0d8` — `fix(api): usar BASE_URL de api.ts en Portal, envio de correo e IA`
2. `385b26a` — `test(api): agregar prueba Deno para prevenir reaparicion de functions/v1 en src`
3. `[commit actual]` — `docs(api): registrar bitacora y reporte de URLs de API`

---

## 7. Pasos de Despliegue para Luis

1. **Revisión de Claude Code:** Claude inspecciona la rama `urls-api-2026-11-05` en el worktree `..\Remolques_urls`.
2. **Merge a `main`:** Luis realiza el merge hacia `main`.
3. **Base de Datos:** **No requiere migraciones SQL**.
4. **Rebuild en EasyPanel:** Hacer clic en "Rebuild" en el servicio **`remolques-web`** (Frontend Vite) para publicar las nuevas URLs.
