import type { DatosCosteo, Modelo } from "./tipos.ts";

export async function cargarDatosCosteo(supabase: any, modeloId: string): Promise<DatosCosteo> {
  const { data: modelo, error: errMod } = await supabase
    .from("modelos")
    .select("id, tipo, largo_ft, num_ejes, productos(nombre)")
    .eq("id", modeloId)
    .single();

  if (errMod || !modelo) throw new Error("Modelo no encontrado");

  const modeloMapeado: Modelo = {
    id: modelo.id,
    tipo: modelo.tipo,
    largo_ft: Number(modelo.largo_ft),
    num_ejes: Number(modelo.num_ejes),
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
      seccion,
      productos (nombre, unidad, costo, descripcion)
    `)
    .eq("modelo_id", modeloId)
    .eq("seccion", "acero");

  const { data: costos_modelo } = await supabase
    .from("costos_modelo")
    .select("seccion, concepto, cantidad, costo_unitario, escala")
    .eq("modelo_id", modeloId);

  const { data: procesos } = await supabase
    .from("procesos_manufactura")
    .select("orden, proceso, subproceso, minutos, tarifa_hora")
    .eq("modelo_id", modeloId)
    .order("orden", { ascending: true });

  const { data: grupos } = await supabase
    .from("grupos_configuracion")
    .select("id, clave, nombre, seleccion, regla, aplica_a, depende_de, cantidad, unidad_precio, medidas");

  const { data: opcion_costos_raw } = await supabase
    .from("opcion_costos")
    .select(`
      cantidad_base,
      escala,
      costo_unitario,
      tipo_modelo,
      opciones_configuracion (clave, grupo_id)
    `)
    .eq("tipo_modelo", modeloMapeado.tipo);

  const { data: paramGanancia } = await supabase
    .from("parametros_costeo")
    .select("valor")
    .eq("clave", "ganancia_factura")
    .maybeSingle();

  let ganancia: number | null = null;
  if (paramGanancia?.valor && typeof paramGanancia.valor === "object") {
    if (modeloMapeado.tipo === "plataforma" || modeloMapeado.tipo === "dolly") {
      const val = paramGanancia.valor[modeloMapeado.tipo];
      ganancia = typeof val === "number" ? val : null;
    } else {
      ganancia = null;
    }
  }

  const gruposList = grupos || [];

  return {
    modelo: modeloMapeado,
    receta_acero: (receta_base || []).map((r: any) => ({
      material_id: r.material_id,
      nombre: r.productos?.nombre || "",
      cantidad: Number(r.cantidad),
      escala: r.escala || "fija",
      costo: r.productos?.costo !== null && r.productos?.costo !== undefined ? Number(r.productos.costo) : null,
      descripcion: r.productos?.descripcion || null
    })),
    costos_modelo: (costos_modelo || []).map((cm: any) => ({
      seccion: cm.seccion,
      concepto: cm.concepto,
      cantidad: Number(cm.cantidad),
      costo_unitario: Number(cm.costo_unitario),
      escala: cm.escala || "fija"
    })),
    procesos: (procesos || []).map((p: any) => ({
      orden: p.orden,
      proceso: p.proceso,
      subproceso: p.subproceso || null,
      minutos: Number(p.minutos),
      tarifa_hora: Number(p.tarifa_hora)
    })),
    opcion_costos: (opcion_costos_raw || []).map((oc: any) => {
      const grupo = gruposList.find((g: any) => g.id === oc.opciones_configuracion?.grupo_id);
      return {
        grupo_clave: grupo ? grupo.clave : "",
        opcion_clave: oc.opciones_configuracion?.clave || "",
        cantidad_base: Number(oc.cantidad_base),
        escala: oc.escala || "fija",
        costo_unitario: Number(oc.costo_unitario)
      };
    }),
    grupos: gruposList,
    ganancia
  };
}
