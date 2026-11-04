# Cola de la noche — 2026-11-02

Anty actualiza la columna **Estado** (y la hora). Prompt de la noche: `PROMPT_ANTY_NOCHE_2026-11-02.md`. **Ronda 2 (correcciones): `PROMPT_ANTY_CORRECCION_RONDA2_2026-11-02.md`.**

| # | Tarea | Rama | Depende de | Estado | Último commit | Reporte | Revisión de Claude |
|---|---|---|---|---|---|---|---|
| T0 | Orden de la casa (commitear SQL/prompts sueltos, `.gitignore`, carpeta `XML_FACTURAS/`) | `noche-t0-housekeeping` | — | APROBADO (03:16) | `102b594` | `REPORTES/T0_REPORTE_ANTY.md` | `REVISIONES/T0_REVISION_CLAUDE.md` (APROBADO) |
| T1 | Productos y servicios: catálogo completo, paginación, "Sin costo cargado", catálogo del cotizador | `noche-t1-catalogo` | — | LISTO_PARA_REVISION (00:10) | `e77a2af` | `REPORTES/T1_REPORTE_ANTY_R3.md` | `REVISIONES/T1_REVISION_CLAUDE.md` (APROBADO R3) |
| T2 | Despiece por fases desde `UNION DE LISTADOS ACTULIZADO (1).xlsx` (todas las plataformas) | `noche-t2-despiece` | — | LISTO_PARA_REVISION (08:35) | `ec25c46` | `REPORTES/T2_REPORTE_ANTY_R4.md` | `REVISIONES/T2_REVISION_CLAUDE.md` (CORREGIR R3) |
| T3 | Checklist de entregas almacén → producción (por OT, equipo y fase; sin re-entregar) | `noche-t3-checklist` | T2 | LISTO_PARA_REVISION (00:04) | `e86926c` | `REPORTES/T3_REPORTE_ANTY_R3.md` | `REVISIONES/T3_REVISION_CLAUDE.md` (CORREGIR R3) |
| T4 | Proveedores: partidas por factura, importar XML (CFDI), reporte de facturación, revisión general | `noche-t4-proveedores` | — | LISTO_PARA_REVISION (22:51) | `48f028d` | `REPORTES/T4_REPORTE_ANTY_R2.md` | `REVISIONES/T4_REVISION_CLAUDE.md` (CORREGIR R2) |
| T5 | Normas: propuesta de dónde y cómo (solo documento) | `noche-t5-normas` | — | LISTO_PARA_REVISION (23:11) | `45e6949` | `REPORTES/T5_REPORTE_ANTY_R2.md` | `REVISIONES/T5_REVISION_CLAUDE.md` (CORREGIR R2) |
| T6 | Editor de recetas/plantillas creadas por el usuario (nota de diseño + MVP si es viable) | `noche-t6-editor-recetas` | T2 | LISTO_PARA_REVISION (23:05) | `31dbd5f` | `REPORTES/T6_REPORTE_ANTY_R2.md` | `REVISIONES/T6_REVISION_CLAUDE.md` (CORREGIR R2) |

Ronda 1 (noche): T0 → T6 entregadas a las 03:45; Claude revisó contra el esquema real: T0 aprobada, T1–T6 a corregir.
Ronda 2: orden sugerido T2 → T1 → T3 → T4 → T6 → T5. Anty pasa cada tarea a `LISTO_PARA_REVISION` (con hora y commit) al terminar.
