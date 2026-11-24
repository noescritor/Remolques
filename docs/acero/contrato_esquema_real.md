# Contrato de Esquema Real — Bloque F (Acero CFDI)

Ejecutado contra PostgreSQL 17 local (`test_acero_f` clonada de `remolques` con `20261102_03_facturas_partidas_cfdi.sql` y `20261125_01_acero_f.sql` aplicada 2 veces con `ON_ERROR_STOP=1`).

## 1. Tablas y columnas verificadas
- `catalogo_alias_factura`: `id, organizacion_id, proveedor_id, clave_sat, descripcion_normalizada, destino_tipo, destino_id, proveedor_acero, factor_conversion, veces_confirmado, ultima_confirmacion, confirmado_por, created_at` + índice único `uq_catalogo_alias_factura_clave` con `COALESCE(clave_sat, '')`.
- `acero_precios_cfdi_aplicados`: `id, organizacion_id, partida_id (UNIQUE), material_id, proveedor, precio_aplicado, factura_id, fecha_emision_factura, aplicado_el, usuario_id`.
- `acero_precios_historial`: columnas aditivas `fuente TEXT`, `factura_id UUID`, `incluye_iva BOOLEAN`.

## 2. No regresión de datos existentes (MD5 antes vs después de migración ×2)
- `acero_materiales`: `5ec9ac836f92d2a7cfd6b145528b6979` (idéntico).
- `acero_precios`: `c47860e9de29ddd6bd33f631608dc1b5` (idéntico).

## 3. Verificador integral y concurrencia
- `docs/acero/verificacion_F.sql`: `VERIFICACION_F_OK` (todo-o-nada, duplicado en lote, reaplicación, fecha anterior, variación ±30%, renombrar proveedor con/sin conflicto y aislamiento RLS `authenticated`).
- Concurrencia en 2 sesiones paralelas sobre `aplicar_precios_acero_cfdi`: sesión 1 `ok: true`, sesión 2 `ERROR: partida_ya_aplicada`.
