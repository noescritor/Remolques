export const construirMetadata = (item: any, cotizacionId: string, orgId?: string) => ({
  cotizacion_id: cotizacionId,
  ...(orgId ? { organizacion_id: orgId } : {}),
  producto_id: item.producto_id || null,
  posicion: item.posicion,
  cantidad: item.cantidad,
  unidad: item.unidad,
  descripcion: item.descripcion,
  precio_unitario: item.precio_unitario ?? null,
  costo_unitario: item.costo_unitario ?? null,
  iva_item: item.iva_item ?? 0,
  total_item: item.total_item ?? 0,
  metadata: {
    numero_proyecto: item.numero_proyecto || null,
    incluir_setup: item.incluir_setup ?? null,
    meses_cobrados: item.meses_cobrados ?? null,
    asientos_extra: item.asientos_extra ?? null,
    ...(item.configuracion ? { configuracion: item.configuracion } : {})
  },
});

export const desenvolverMetadata = (item: any) => {
  const meta = item.metadata || {};
  return {
    ...item,
    numero_proyecto: item.numero_proyecto ?? meta.numero_proyecto ?? null,
    incluir_setup: item.incluir_setup ?? meta.incluir_setup ?? null,
    meses_cobrados: item.meses_cobrados ?? meta.meses_cobrados ?? null,
    asientos_extra: item.asientos_extra ?? meta.asientos_extra ?? null,
    ...(meta.configuracion ? { configuracion: meta.configuracion } : {})
  };
};
