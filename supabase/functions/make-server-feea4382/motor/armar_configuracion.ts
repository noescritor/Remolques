export function armarConfiguracionModelo(modelo: any, gruposRaw: any[], opcionesRaw: any[], componentesRaw: any[]) {
  const opcionesConReceta = new Set(componentesRaw.map((c: any) => c.opcion_id));

  const grupos = gruposRaw
    .filter((g: any) => !g.aplica_a || g.aplica_a.includes(modelo.tipo))
    .sort((a: any, b: any) => (a.orden || 0) - (b.orden || 0))
    .map((g: any) => {
      let max_piezas: number | undefined = undefined;
      let cantidad_defecto: number | "max" | undefined = undefined;
      let regla = g.regla;
      if (typeof regla === 'string') {
        try {
          regla = JSON.parse(regla);
        } catch {
          regla = null;
        }
      }
      if (regla && typeof regla === 'object') {
        if (regla.max_total?.por_eje && typeof modelo?.num_ejes === 'number') {
          max_piezas = regla.max_total.por_eje * modelo.num_ejes;
        } else if (typeof regla.max_total?.fija === 'number') {
          max_piezas = regla.max_total.fija;
        }
        if (regla.cantidad_defecto !== undefined) {
          cantidad_defecto = regla.cantidad_defecto;
        }
      }
      return {
        ...g,
        ...(max_piezas !== undefined ? { max_piezas } : {}),
        ...(cantidad_defecto !== undefined ? { cantidad_defecto } : {})
      };
    });

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
