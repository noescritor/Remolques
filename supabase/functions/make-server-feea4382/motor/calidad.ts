export class CalidadError extends Error {
  status: number;
  codigo: string;
  extra?: Record<string, unknown>;

  constructor(status: number, codigo: string, message: string, extra?: Record<string, unknown>) {
    super(message);
    this.status = status;
    this.codigo = codigo;
    this.extra = extra;
  }
}

export function mapearErrorRpcCalidad(err: any): CalidadError {
  const msg = String(err?.message || err || "Error inesperado en módulo de calidad");

  if (msg.includes("SIN_PLANTILLA")) {
    return new CalidadError(
      409,
      "SIN_PLANTILLA",
      "No hay plantilla activa para esta línea y formato. Créala en Calidad → Plantillas.",
    );
  }
  if (msg.includes("YA_EXISTE:")) {
    const idExistente = msg.split("YA_EXISTE:")[1]?.trim().split(/\s+/)[0] || null;
    return new CalidadError(
      409,
      "YA_EXISTE",
      "Ya existe una inspección en proceso para esta orden y formato.",
      idExistente ? { inspeccion_id: idExistente } : undefined,
    );
  }
  if (msg.includes("YA_EXISTE")) {
    return new CalidadError(409, "YA_EXISTE", "Ya existe una inspección en proceso para esta orden y formato.");
  }
  if (msg.includes("BLOQUEADA_POR_NO_CONFORMES")) {
    return new CalidadError(
      409,
      "BLOQUEADA_POR_NO_CONFORMES",
      "Existen puntos no conformes y la plantilla tiene activado el bloqueo de liberación.",
    );
  }
  if (msg.includes("NO_EDITABLE")) {
    return new CalidadError(409, "NO_EDITABLE", "Solo se pueden modificar o eliminar plantillas en estado borrador.");
  }
  if (msg.includes("TIENE_INSPECCIONES")) {
    return new CalidadError(409, "TIENE_INSPECCIONES", "No se puede eliminar una plantilla que ya tiene inspecciones.");
  }
  if (msg.includes("INSPECCION_CERRADA")) {
    return new CalidadError(409, "INSPECCION_CERRADA", "La inspección ya está cerrada y no admite cambios.");
  }
  if (msg.includes("YA_CERRADA")) {
    return new CalidadError(409, "YA_CERRADA", "La inspección ya se encuentra cerrada.");
  }
  if (msg.includes("PLANTILLA_VACIA")) {
    return new CalidadError(400, "PLANTILLA_VACIA", "La plantilla debe tener al menos un grupo y un punto para publicarse.");
  }
  if (msg.includes("PLANTILLA_NO_ENCONTRADA")) {
    return new CalidadError(404, "PLANTILLA_NO_ENCONTRADA", "Plantilla de calidad no encontrada.");
  }
  if (msg.includes("INSPECCION_NO_ENCONTRADA")) {
    return new CalidadError(404, "INSPECCION_NO_ENCONTRADA", "Inspección de calidad no encontrada.");
  }
  if (msg.includes("ORDEN_NO_ENCONTRADA")) {
    return new CalidadError(404, "ORDEN_NO_ENCONTRADA", "Orden de trabajo no encontrada.");
  }
  if (msg.includes("LINEA_NO_ENCONTRADA")) {
    return new CalidadError(404, "LINEA_NO_ENCONTRADA", "Línea de producto no encontrada.");
  }
  if (msg.includes("OPERARIO_NO_ENCONTRADO")) {
    return new CalidadError(404, "OPERARIO_NO_ENCONTRADO", "Operario no encontrado en esta organización.");
  }
  if (msg.includes("UNIDAD_INVALIDA")) {
    return new CalidadError(400, "UNIDAD_INVALIDA", msg);
  }
  if (
    msg.includes("FORMATO_INVALIDO") ||
    msg.includes("NOMBRE_REQUERIDO") ||
    msg.includes("ITEM_INVALIDO") ||
    msg.includes("RESULTADO_INVALIDO")
  ) {
    return new CalidadError(400, "DATOS_INVALIDOS", msg);
  }

  return new CalidadError(500, "ERROR_CALIDAD", msg);
}

function exigirServiceClient(serviceClient: any) {
  if (!serviceClient) {
    throw new CalidadError(500, "CONFIG_SERVIDOR", "Se requiere cliente de servicio para esta operación.");
  }
  return serviceClient;
}

/**
 * Si la organización aún no tiene plantillas sembradas, invoca sembrar_calidad_plantillas.
 */
export async function asegurarSemillaCalidad(
  supabase: any,
  orgId: string,
  serviceClient?: any,
) {
  const { count, error } = await supabase
    .from("calidad_plantillas")
    .select("id", { count: "exact", head: true })
    .eq("organizacion_id", orgId);

  if (error) throw error;

  if (!count || count === 0) {
    const rpcClient = exigirServiceClient(serviceClient);
    const { error: errSembrar } = await rpcClient.rpc("sembrar_calidad_plantillas", { p_org: orgId });
    if (errSembrar) throw mapearErrorRpcCalidad(errSembrar);
  }
}

export async function listarPlantillasCalidad(
  supabase: any,
  orgId: string,
  filtros: { formato?: string; linea?: string; estado?: string } = {},
  serviceClient?: any,
) {
  await asegurarSemillaCalidad(supabase, orgId, serviceClient);

  let query = supabase
    .from("calidad_plantillas")
    .select("*, linea:lineas_producto(id, clave, nombre)")
    .eq("organizacion_id", orgId);

  if (filtros.formato) query = query.eq("formato", filtros.formato);
  if (filtros.estado) query = query.eq("estado", filtros.estado);

  const { data, error } = await query
    .order("formato", { ascending: true })
    .order("version", { ascending: false });

  if (error) throw error;

  let lista = data || [];
  if (filtros.linea) {
    const claveFiltro = filtros.linea.trim().toLowerCase();
    lista = lista.filter((p: any) => p.linea?.clave === claveFiltro);
  }

  return lista;
}

export async function obtenerPlantillaCalidad(
  supabase: any,
  orgId: string,
  id: string,
) {
  const { data: plantilla, error } = await supabase
    .from("calidad_plantillas")
    .select("*, linea:lineas_producto(id, clave, nombre)")
    .eq("id", id)
    .eq("organizacion_id", orgId)
    .maybeSingle();

  if (error) throw error;
  if (!plantilla) {
    throw new CalidadError(404, "PLANTILLA_NO_ENCONTRADA", "Plantilla de calidad no encontrada.");
  }

  const [{ data: grupos, error: errGr }, { data: items, error: errIt }] = await Promise.all([
    supabase
      .from("calidad_plantilla_grupos")
      .select("*")
      .eq("plantilla_id", id)
      .eq("organizacion_id", orgId)
      .order("orden", { ascending: true }),
    supabase
      .from("calidad_plantilla_items")
      .select("*")
      .eq("plantilla_id", id)
      .eq("organizacion_id", orgId)
      .order("orden", { ascending: true }),
  ]);

  if (errGr) throw errGr;
  if (errIt) throw errIt;

  const itemsPorGrupo = new Map<string, any[]>();
  for (const it of items || []) {
    if (!itemsPorGrupo.has(it.grupo_id)) itemsPorGrupo.set(it.grupo_id, []);
    itemsPorGrupo.get(it.grupo_id)!.push(it);
  }

  const gruposConItems = (grupos || []).map((g: any) => ({
    ...g,
    items: itemsPorGrupo.get(g.id) || [],
  }));

  return {
    ...plantilla,
    grupos: gruposConItems,
  };
}

export async function crearPlantillaCalidad(
  supabase: any,
  orgId: string,
  body: { formato: string; linea_clave: string; nombre?: string; duplicar_de?: string },
  serviceClient?: any,
) {
  await asegurarSemillaCalidad(supabase, orgId, serviceClient);
  const rpcClient = exigirServiceClient(serviceClient);

  if (body.duplicar_de) {
    const { data: newId, error } = await rpcClient.rpc("duplicar_plantilla", {
      p_org: orgId,
      p_id: body.duplicar_de,
      p_linea_clave: body.linea_clave,
      p_formato: body.formato,
      p_nombre: body.nombre ?? null,
    });
    if (error) throw mapearErrorRpcCalidad(error);
    return await obtenerPlantillaCalidad(supabase, orgId, newId);
  }

  const { data: newId, error } = await rpcClient.rpc("crear_plantilla_borrador", {
    p_org: orgId,
    p_linea_clave: body.linea_clave,
    p_formato: body.formato,
    p_nombre: body.nombre || "",
  });
  if (error) throw mapearErrorRpcCalidad(error);
  return await obtenerPlantillaCalidad(supabase, orgId, newId);
}

export async function guardarPlantillaCalidad(
  supabase: any,
  orgId: string,
  id: string,
  payload: Record<string, unknown>,
  serviceClient?: any,
) {
  const rpcClient = exigirServiceClient(serviceClient);
  const { error } = await rpcClient.rpc("guardar_plantilla_calidad", {
    p_org: orgId,
    p_id: id,
    p_payload: payload,
  });
  if (error) throw mapearErrorRpcCalidad(error);
  return await obtenerPlantillaCalidad(supabase, orgId, id);
}

export async function nuevaVersionPlantillaCalidad(
  supabase: any,
  orgId: string,
  id: string,
  serviceClient?: any,
) {
  const rpcClient = exigirServiceClient(serviceClient);
  const { data: newId, error } = await rpcClient.rpc("nueva_version_plantilla", {
    p_org: orgId,
    p_id: id,
  });
  if (error) throw mapearErrorRpcCalidad(error);
  return await obtenerPlantillaCalidad(supabase, orgId, newId);
}

export async function publicarPlantillaCalidad(
  supabase: any,
  orgId: string,
  id: string,
  serviceClient?: any,
) {
  const rpcClient = exigirServiceClient(serviceClient);
  const { error } = await rpcClient.rpc("publicar_plantilla", {
    p_org: orgId,
    p_id: id,
  });
  if (error) throw mapearErrorRpcCalidad(error);
  return await obtenerPlantillaCalidad(supabase, orgId, id);
}

export async function eliminarPlantillaCalidad(
  _supabase: any,
  orgId: string,
  id: string,
  serviceClient?: any,
) {
  const rpcClient = exigirServiceClient(serviceClient);
  const { error } = await rpcClient.rpc("eliminar_plantilla_borrador", {
    p_org: orgId,
    p_id: id,
  });
  if (error) throw mapearErrorRpcCalidad(error);
  return { success: true };
}

export async function obtenerResumenCalidadOrdenes(
  _supabase: any,
  orgId: string,
  serviceClient?: any,
) {
  const rpcClient = exigirServiceClient(serviceClient);
  const { data, error } = await rpcClient.rpc("resumen_calidad_ordenes", { p_org: orgId });
  if (error) throw mapearErrorRpcCalidad(error);
  return data || [];
}

export function calcularResumenInspeccion(
  numItems: number,
  unidadesConfig: unknown,
  resultados: Array<{ resultado: string; unidad?: number }>,
) {
  const unidades = Array.isArray(unidadesConfig) && unidadesConfig.length > 0 ? unidadesConfig.length : 1;
  const total = numItems * unidades;
  let conformes = 0;
  let no_conformes = 0;
  let no_aplica = 0;
  for (const r of resultados) {
    if (typeof r.unidad === "number" && (r.unidad < 1 || r.unidad > unidades)) continue;
    if (r.resultado === "conforme") conformes++;
    else if (r.resultado === "no_conforme") no_conformes++;
    else if (r.resultado === "no_aplica") no_aplica++;
  }
  const capturados = conformes + no_conformes + no_aplica;
  const pendientes = Math.max(0, total - capturados);
  return { total, capturados, conformes, no_conformes, no_aplica, pendientes };
}

export async function crearInspeccionCalidad(
  supabase: any,
  orgId: string,
  body: { orden_trabajo_id: string; formato: string; plantilla_id?: string | null },
  usuarioId: string | null,
  serviceClient?: any,
) {
  await asegurarSemillaCalidad(supabase, orgId, serviceClient);
  const rpcClient = exigirServiceClient(serviceClient);

  const { data: newId, error } = await rpcClient.rpc("crear_inspeccion_calidad", {
    p_org: orgId,
    p_orden: body.orden_trabajo_id,
    p_formato: body.formato,
    p_plantilla: body.plantilla_id ?? null,
    p_usuario: usuarioId,
  });
  if (error) throw mapearErrorRpcCalidad(error);
  return await obtenerInspeccionCalidad(supabase, orgId, newId);
}

export async function listarInspeccionesCalidad(
  supabase: any,
  orgId: string,
  filtros: {
    orden_trabajo_id?: string;
    formato?: string;
    estado?: string;
    con_no_conformes?: string | boolean;
  } = {},
  serviceClient?: any,
) {
  let query = supabase
    .from("orden_calidad_inspecciones")
    .select("*, orden:ordenes_trabajo(id, etiqueta, modelo, niv, cliente_id, linea_producto_id), plantilla:calidad_plantillas(id, nombre, version, formato, config)")
    .eq("organizacion_id", orgId);

  if (filtros.orden_trabajo_id) query = query.eq("orden_trabajo_id", filtros.orden_trabajo_id);
  if (filtros.formato) query = query.eq("formato", filtros.formato);
  if (filtros.estado) query = query.eq("estado", filtros.estado);

  const { data: inspecciones, error } = await query.order("created_at", { ascending: false });
  if (error) throw error;

  const resumenes = await obtenerResumenCalidadOrdenes(supabase, orgId, serviceClient);
  const resumenPorInsp = new Map<string, any>();
  for (const r of resumenes) {
    resumenPorInsp.set(r.inspeccion_id, r);
  }

  let lista = (inspecciones || []).map((insp: any) => {
    const res = resumenPorInsp.get(insp.id);
    return {
      ...insp,
      resumen: res
        ? {
            total: res.total_esperados,
            capturados: res.capturados,
            conformes: res.conformes,
            no_conformes: res.no_conformes,
            no_aplica: res.no_aplica,
            pendientes: res.pendientes,
          }
        : null,
    };
  });

  if (filtros.con_no_conformes === true || filtros.con_no_conformes === "true") {
    lista = lista.filter((i: any) => (i.resumen?.no_conformes || 0) > 0);
  }

  return lista;
}

export async function obtenerInspeccionCalidad(
  supabase: any,
  orgId: string,
  id: string,
) {
  const { data: inspeccion, error } = await supabase
    .from("orden_calidad_inspecciones")
    .select("*")
    .eq("id", id)
    .eq("organizacion_id", orgId)
    .maybeSingle();

  if (error) throw error;
  if (!inspeccion) {
    throw new CalidadError(404, "INSPECCION_NO_ENCONTRADA", "Inspección de calidad no encontrada.");
  }

  const [{ data: orden }, plantilla, { data: resultados, error: errRes }] = await Promise.all([
    supabase
      .from("ordenes_trabajo")
      .select("id, etiqueta, modelo, niv, cliente_id, linea_producto_id, cliente:clientes(nombre_razon_social), linea:lineas_producto(id, clave, nombre)")
      .eq("id", inspeccion.orden_trabajo_id)
      .eq("organizacion_id", orgId)
      .maybeSingle(),
    obtenerPlantillaCalidad(supabase, orgId, inspeccion.plantilla_id),
    supabase
      .from("orden_calidad_resultados")
      .select("*")
      .eq("inspeccion_id", id)
      .eq("organizacion_id", orgId),
  ]);

  if (errRes) throw errRes;

  const numItems = (plantilla.grupos || []).reduce((acc: number, g: any) => acc + (g.items?.length || 0), 0);
  const resumen = calcularResumenInspeccion(numItems, plantilla.config?.unidades, resultados || []);

  return {
    inspeccion,
    orden: orden
      ? {
          id: orden.id,
          etiqueta: orden.etiqueta || orden.cliente?.nombre_razon_social || null,
          cliente_nombre: orden.cliente?.nombre_razon_social || null,
          modelo: orden.modelo,
          niv: orden.niv,
          linea: orden.linea || null,
        }
      : null,
    plantilla,
    resultados: resultados || [],
    resumen,
  };
}

export async function actualizarEncabezadoInspeccion(
  supabase: any,
  orgId: string,
  id: string,
  payload: Record<string, unknown>,
  usuarioId: string | null,
  serviceClient?: any,
) {
  const rpcClient = exigirServiceClient(serviceClient);
  const { error } = await rpcClient.rpc("actualizar_encabezado_inspeccion", {
    p_org: orgId,
    p_inspeccion: id,
    p_payload: payload,
    p_usuario: usuarioId,
  });
  if (error) throw mapearErrorRpcCalidad(error);
  return await obtenerInspeccionCalidad(supabase, orgId, id);
}

export async function guardarResultadosCalidad(
  supabase: any,
  orgId: string,
  id: string,
  resultados: Array<Record<string, unknown>>,
  usuarioId: string | null,
  serviceClient?: any,
) {
  const rpcClient = exigirServiceClient(serviceClient);
  const { data: procesados, error } = await rpcClient.rpc("guardar_resultados_calidad", {
    p_org: orgId,
    p_inspeccion: id,
    p_resultados: resultados,
    p_usuario: usuarioId,
  });
  if (error) throw mapearErrorRpcCalidad(error);
  const detalle = await obtenerInspeccionCalidad(supabase, orgId, id);
  return { ...detalle, procesados };
}

export async function cerrarInspeccionCalidad(
  _supabase: any,
  orgId: string,
  id: string,
  body: { liberado_por?: string | null; fecha_liberacion?: string | null } = {},
  usuarioId: string | null,
  serviceClient?: any,
) {
  const rpcClient = exigirServiceClient(serviceClient);
  const { data, error } = await rpcClient.rpc("cerrar_inspeccion_calidad", {
    p_org: orgId,
    p_inspeccion: id,
    p_liberado_por: body.liberado_por ?? null,
    p_fecha_liberacion: body.fecha_liberacion ?? null,
    p_usuario: usuarioId,
  });
  if (error) throw mapearErrorRpcCalidad(error);
  return data;
}

export async function reabrirInspeccionCalidad(
  supabase: any,
  orgId: string,
  id: string,
  usuarioId: string | null,
  serviceClient?: any,
) {
  const rpcClient = exigirServiceClient(serviceClient);
  const { error } = await rpcClient.rpc("reabrir_inspeccion_calidad", {
    p_org: orgId,
    p_inspeccion: id,
    p_usuario: usuarioId,
  });
  if (error) throw mapearErrorRpcCalidad(error);
  return await obtenerInspeccionCalidad(supabase, orgId, id);
}
