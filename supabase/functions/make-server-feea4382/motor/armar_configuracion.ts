export function armarConfiguracionModelo(modelo: any, gruposRaw: any[], opcionesRaw: any[], componentesRaw: any[]) {
  const opcionesConReceta = new Set(componentesRaw.map((c: any) => c.opcion_id));

  const grupos = gruposRaw
    .filter((g: any) => !g.aplica_a || g.aplica_a.includes(modelo.tipo))
    .sort((a: any, b: any) => (a.orden || 0) - (b.orden || 0));

  const gruposIds = new Set(grupos.map((g: any) => g.id));

  const opciones = opcionesRaw
    .filter((o: any) => gruposIds.has(o.grupo_id))
    .map((o: any) => ({
      id: o.id,
      grupo_id: o.grupo_id,
      clave: o.clave,
      nombre: o.nombre,
      marcas: o.marcas,
      medidas: o.medidas,
      activo: o.activo,
      aliases: o.aliases,
      precio_venta: o.precio_venta,
      clase: o.clase,
      tiene_receta: opcionesConReceta.has(o.id)
    }));

  return { modelo, grupos, opciones };
}
