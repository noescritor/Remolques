# Contrato de Esquema Real — Bloque G (Almacén desde XML)

Verificado contra PostgreSQL 17 local (clon de `remolques` + `20261102_03_facturas_partidas_cfdi.sql` + `20261125_01_acero_f.sql` + `20261126_01_almacen_g.sql` aplicada ×2 con `ON_ERROR_STOP=1`).

## Columnas modificadas (aditivas / ampliación de tipo)
- `catalogo_alias_factura.destino_id`: `UUID` → `TEXT` (mismos índices `uq_catalogo_alias_factura_clave` e `idx_catalogo_alias_factura_org_tipo`; `aplicar_precios_acero_cfdi` solo agrega `::TEXT`).
- `productos.stock_actual`, `stock_reservado`, `stock_minimo`: `INTEGER` → `NUMERIC(14,4)` (`DEFAULT 0`).
- `movimientos_inventario.cantidad`: `INTEGER` → `NUMERIC(14,4)`.
- `productos` (columnas nuevas; `costo` y `precio_unitario` **no se tocan**):
  - `ultimo_costo_compra NUMERIC(14,4) NULL`
  - `ultimo_costo_compra_fecha DATE NULL`
  - `ultimo_costo_compra_factura_id UUID NULL REFERENCES facturas_proveedor(id) ON DELETE SET NULL`

## Tablas nuevas (RLS SELECT por `get_current_org_id()`; escritura solo vía RPC `service_role`)
- `almacen_recepciones`: `id`, `organizacion_id`, `factura_id`, `proveedor_id`, `compra_id`, `estado ('recibida'|'anulada')`, `notas`, `recibido_por`, `created_at`, `anulada_el`, `anulada_por`, `motivo_anulacion`.
- `almacen_recepcion_lineas`: `id`, `organizacion_id`, `recepcion_id`, `partida_id`, `producto_id TEXT`, `cantidad_xml`, `unidad_xml`, `factor_conversion`, `cantidad_recibida`, `costo_unitario_mxn`, `movimiento_id`, `movimiento_anulacion_id`, `costo_actualizado`, `activa`, `notas`, `created_at`.
  - Índice único parcial: `uq_almacen_recepcion_lineas_partida_activa ON almacen_recepcion_lineas (partida_id) WHERE activa = true`.

## RPCs (`SECURITY DEFINER`, `SET search_path = public`, `GRANT EXECUTE TO service_role`)
- `recibir_factura_almacen(p_org UUID, p_usuario UUID, p_factura_id UUID, p_lineas JSONB, p_confirmo_doble BOOLEAN DEFAULT false, p_notas TEXT DEFAULT NULL) RETURNS JSONB`
- `anular_recepcion_almacen(p_org UUID, p_usuario UUID, p_recepcion_id UUID, p_motivo TEXT) RETURNS JSONB`
