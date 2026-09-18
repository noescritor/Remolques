# Changelog de cambios y hallazgos — Remolques

Bitácora obligatoria para cualquier cambio hecho con Antigravity o Claude Code.
Formato: entradas nuevas **arriba**. Una entrada por sesión/cambio.

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
