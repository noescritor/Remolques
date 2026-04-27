# Contexto y Estado del Proyecto — Cotización App Admin

**Fecha de última actualización:** Abril 2026  
**Fase actual:** Fase 3 en progreso (Portal de Cliente + Firma Digital)  
**Estado Global:** FASE 0 ✅ | FASE 1 ✅ | FASE 2 ✅ | FASE 3 en curso

---

## ✅ FASE 0 — Estabilización y Seguridad (COMPLETADA)

1. `.env` configurado, cero credenciales en código, `.gitignore` listo.
2. RLS habilitado (`20260427_00_enable_rls.sql`).
3. JWT Middleware en todos los endpoints Hono.
4. Supabase Auth UI en el frontend (login obligatorio).
5. React Router con rutas declarativas.
6. MUI eliminado del bundle.

---

## ✅ FASE 1 — Fundamentos Técnicos (COMPLETADA)

1. **1.1** Migración a tablas relacionales. Scripts: `20260427_01_relational_schema.sql` + `20260427_02_migrate_kv_data.sql`.
2. **1.2** Tipos unificados en `src/app/types/index.ts`.
3. Edge Function `make-server-feea4382` desplegada en Supabase.

**Bugs críticos corregidos:**
- `DialogFooter` no importado → crash en render → corregido.
- Rutas Hono con prefijo incorrecto → 404 → corregido.
- `CotizacionEditorWrapper` no pasaba `id` → updates sin efecto → corregido.
- Timeout disponibilidad servidor: 2s → 8s.
- `tsconfig.json` y `src/vite-env.d.ts` creados.

---

## ✅ FASE 2 — Productividad (COMPLETADA)

| Tarea | Estado | Notas |
|-------|--------|-------|
| 2.1 Plantillas de cotización | ✅ | Sección "Plantillas" en sidebar, CRUD completo, "Usar Plantilla" y "Guardar como Plantilla" en editor |
| 2.2 Versiones de cotización | ✅ | Diálogo en editor detecta Enviada/Aprobada → ofrece v2; timeline de versiones en pestaña "Versiones" del detalle |
| 2.3 Historial de precios | ✅ | Auto-registra cambios de precio en `historial_precios`; endpoint GET/POST en servidor |
| 2.4 Seguimiento automático | ⏸️ | Requiere Resend API Key + Supabase cron (Scheduled Functions). Pospuesto. |
| 2.5 IA con Claude & OpenAI | ✅ | Botón ✨ por item y "Generar nota con IA". Soporta Claude (Anthropic) y GPT (OpenAI). **Requiere ANTHROPIC_API_KEY o OPENAI_API_KEY en secretos de Supabase.** |
| 2.6 Importar desde Excel | ✅ | Modal con SheetJS, detección automática de columnas, preview, importa todos los conceptos |

**Migración ejecutada en Supabase:** `20260427_03_plantillas_historial.sql` ✅

---

## 🔄 FASE 3 — Portal de Cliente y Firma Digital (EN CURSO)

### ✅ 3.1 Portal de Cliente (implementado en esta sesión)

**Qué hace:**
- Página pública (sin login) accesible via link único: `/cotizacion/:token`
- Token UUID pre-generado en la tabla `cotizaciones.token_publico`
- El vendedor genera/copia el link desde el detalle de la cotización con el botón "Generar Portal" / "Copiar Portal"
- El cliente ve: logo IDEALLY, datos, items, totales, nota, vigencia
- El cliente puede: ✅ Aprobar | 💬 Solicitar cambios | ❌ Rechazar

**Archivos creados/modificados:**
- `supabase/migrations/20260427_04_portal_firma.sql` → ejecutar en Supabase SQL Editor
- `supabase/functions/make-server-feea4382/index.ts` → rutas públicas `/portal/:token`, `/portal/:token/aprobar`, `/portal/:token/rechazar`, `/portal/:token/solicitar-cambios`; ruta autenticada `/cotizaciones/:id/generar-token-portal`
- `src/app/components/Portal/PortalCliente.tsx` → componente nuevo (página pública)
- `src/app/App.tsx` → ruta pública `/cotizacion/:token` disponible antes del check de auth y también con sesión activa
- `src/app/hooks/useSupabaseData.ts` → helper `generarTokenPortal`
- `src/app/components/Cotizaciones/CotizacionDetalle.tsx` → botón "Generar Portal" / "Copiar Portal"
- `src/app/types/index.ts` → campos de portal y firma agregados al tipo `Cotizacion`

### ✅ 3.2 Firma Digital (implementado en esta sesión)

- Librería `signature_pad` integrada en el portal
- Al aprobar: canvas de firma → guardar como base64
- Campos en DB: `firma_imagen`, `firma_nombre`, `firma_fecha`, `firma_ip`
- Registro de auditoría completo

### ⬜ 3.3 Notificaciones WhatsApp (pendiente)
- Requiere Twilio o WhatsApp Business API
- Posponer hasta Fase 5 (integraciones externas)

---

## ⚠️ Advertencias para el desarrollador

1. **Deploy Edge Function** después de cualquier cambio en el servidor:
   ```
   npx supabase functions deploy make-server-feea4382 --no-verify-jwt
   ```
2. **Migraciones pendientes de ejecutar en Supabase SQL Editor:**
   - `20260427_04_portal_firma.sql` (columnas adicionales para portal y firma)
3. **Rutas públicas del servidor:** `/portal/*` y el health check bypasean el JWT middleware. Todo lo demás requiere auth.
4. **Variables de entorno faltantes:**
   - `ANTHROPIC_API_KEY` → secreto en Supabase (para IA)
   - `RESEND_API_KEY` → secreto en Supabase (para emails)
5. **Fuente única de tipos:** `src/app/types/index.ts`

---

## Próximos pasos recomendados

1. Ejecutar `20260427_04_portal_firma.sql` en Supabase
2. Probar el flujo completo: Cotización → "Generar Portal" → link copiado → cliente aprueba → estado cambia
3. Configurar `RESEND_API_KEY` para activar el envío automático del link por email
4. Continuar con Fase 4 (Pipeline Kanban, Módulo de Proyectos) o Fase 5 (CFDI, Webhooks)
