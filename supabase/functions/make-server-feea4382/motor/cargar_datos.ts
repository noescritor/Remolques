import type { DatosModelo } from "./tipos.ts";

export async function cargarDatosModelo(supabase: any, modeloId: string): Promise<DatosModelo> {
  const { data: modelo, error: errMod } = await supabase
    .from("modelos")
    .select("id, tipo, largo_ft, num_ejes, productos(nombre)")
    .eq("id", modeloId)
    .single();

  if (errMod || !modelo) throw new Error("Modelo no encontrado");

  // Remap to match DatosModelo interface
  const modeloMapeado = {
    ...modelo,
    nombre: modelo.productos?.nombre || ""
  };

  const { data: receta_base } = await supabase
    .from("receta_base")
    .select(`
      material_id,
      cantidad,
      escala,
      paso,
      uso,
      condicion,
      productos (nombre, unidad, costo, descripcion)
    `)
    .eq("modelo_id", modeloId);

  const { data: grupos } = await supabase
    .from("grupos_configuracion")
    .select("id, clave, nombre, seleccion, regla, aplica_a, depende_de, cantidad, unidad_precio, medidas");

  const { data: opciones } = await supabase
    .from("opciones_configuracion")
    .select("id, grupo_id, clave, nombre, marcas, medidas, activo, aliases, precio_venta, clase");

  const { data: componentes } = await supabase
    .from("opcion_componentes")
    .select(`
      opcion_id,
      material_id,
      cantidad,
      escala,
      paso,
      rol,
      uso,
      opciones_configuracion (grupo_id, clave),
      productos (nombre, unidad, costo, descripcion)
    `);

  return {
    modelo: modeloMapeado,
    receta_base: (receta_base || []).map((r: any) => ({
      material_id: r.material_id,
      nombre: r.productos?.nombre || "",
      unidad: r.productos?.unidad || "",
      costo: r.productos?.costo,
      descripcion: r.productos?.descripcion,
      cantidad: r.cantidad,
      escala: r.escala,
      paso: r.paso,
      uso: r.uso,
      condicion: r.condicion
    })),
    grupos: grupos || [],
    opciones: opciones || [],
    opcion_componentes: (componentes || []).map((c: any) => {
      const grupo = (grupos || []).find((g: any) => g.id === c.opciones_configuracion?.grupo_id);
      return {
        opcion_id: c.opcion_id,
        grupo_clave: grupo ? grupo.clave : "",
        opcion_clave: c.opciones_configuracion?.clave || "",
        material_id: c.material_id,
        nombre: c.productos?.nombre || "",
        unidad: c.productos?.unidad || "",
        costo: c.productos?.costo,
        descripcion: c.productos?.descripcion,
        cantidad: c.cantidad,
        escala: c.escala,
        paso: c.paso,
        rol: c.rol,
        uso: c.uso
      };
    })
  };
}
