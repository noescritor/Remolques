// Motor backend para el Plan Semanal de Producción (Sub-bloque 2R-15)
// Operarios, áreas, frentes, tareas, duplicación y trazabilidad con lista blanca estricta

import {
  puedeCambiarEstado,
  duplicarSemana,
  PlanTarea,
  EstadoPlanTarea
} from "../../../../src/app/utils/planProduccion.ts";

export interface OperarioPayload {
  nombre: string;
  puesto?: string | null;
  telefono?: string | null;
  activo?: boolean;
  notas?: string | null;
}

export interface AreaPayload {
  clave?: string;
  nombre: string;
  orden?: number;
  activo?: boolean;
}

export interface FrentePayload {
  area_id: string;
  nombre: string;
  orden?: number;
  activo?: boolean;
}

export interface TareaPayload {
  fecha: string;
  frente_id: string;
  orden_trabajo_id?: string | null;
  descripcion?: string | null;
  movilidad?: string | null;
  observaciones?: string | null;
  material_faltante?: boolean;
  estado?: EstadoPlanTarea;
  operarios?: string[];
  materiales?: {
    producto_id?: string | null;
    descripcion: string;
    cantidad: number;
    unidad: string;
    notas?: string | null;
  }[];
}

// ── OPERARIOS ──

export async function listarOperarios(
  supabase: any,
  orgId: string,
  activosSolamente = false
) {
  let query = supabase
    .from("operarios")
    .select("id, organizacion_id, nombre, puesto, telefono, activo, notas, created_at, updated_at")
    .eq("organizacion_id", orgId)
    .order("nombre", { ascending: true });

  if (activosSolamente) {
    query = query.eq("activo", true);
  }

  const { data, error } = await query;
  if (error) throw error;
  return data || [];
}

export async function crearOperario(
  supabase: any,
  orgId: string,
  payload: OperarioPayload
) {
  const nombreLimpio = (payload.nombre || "").trim();
  if (!nombreLimpio) {
    const err: any = new Error("El nombre del operario es obligatorio");
    err.status = 400;
    throw err;
  }

  // Verificar duplicado insensible a mayúsculas
  const { data: existente } = await supabase
    .from("operarios")
    .select("id, nombre")
    .eq("organizacion_id", orgId)
    .ilike("nombre", nombreLimpio)
    .maybeSingle();

  if (existente) {
    const err: any = new Error(`El operario "${nombreLimpio}" ya está registrado`);
    err.status = 409;
    throw err;
  }

  const insertData = {
    organizacion_id: orgId,
    nombre: nombreLimpio,
    puesto: payload.puesto ? payload.puesto.trim() : null,
    telefono: payload.telefono ? payload.telefono.trim() : null,
    activo: payload.activo !== undefined ? Boolean(payload.activo) : true,
    notas: payload.notas || null,
  };

  const { data, error } = await supabase
    .from("operarios")
    .insert(insertData)
    .select()
    .single();

  if (error) throw error;
  return data;
}

export async function actualizarOperario(
  supabase: any,
  orgId: string,
  id: string,
  payload: OperarioPayload
) {
  const { data: actual } = await supabase
    .from("operarios")
    .select("id, nombre")
    .eq("id", id)
    .eq("organizacion_id", orgId)
    .maybeSingle();

  if (!actual) {
    const err: any = new Error("Operario no encontrado");
    err.status = 404;
    throw err;
  }

  const updateData: any = { updated_at: new Date().toISOString() };

  if (payload.nombre !== undefined) {
    const nombreLimpio = payload.nombre.trim();
    if (!nombreLimpio) {
      const err: any = new Error("El nombre del operario no puede estar vacío");
      err.status = 400;
      throw err;
    }

    if (nombreLimpio.toLowerCase() !== actual.nombre.toLowerCase()) {
      const { data: duplicado } = await supabase
        .from("operarios")
        .select("id")
        .eq("organizacion_id", orgId)
        .ilike("nombre", nombreLimpio)
        .neq("id", id)
        .maybeSingle();

      if (duplicado) {
        const err: any = new Error(`Ya existe otro operario con el nombre "${nombreLimpio}"`);
        err.status = 409;
        throw err;
      }
    }
    updateData.nombre = nombreLimpio;
  }

  if (payload.puesto !== undefined) updateData.puesto = payload.puesto ? payload.puesto.trim() : null;
  if (payload.telefono !== undefined) updateData.telefono = payload.telefono ? payload.telefono.trim() : null;
  if (payload.activo !== undefined) updateData.activo = Boolean(payload.activo);
  if (payload.notas !== undefined) updateData.notas = payload.notas;

  const { data, error } = await supabase
    .from("operarios")
    .update(updateData)
    .eq("id", id)
    .eq("organizacion_id", orgId)
    .select()
    .single();

  if (error) throw error;
  return data;
}

// ── ESTRUCTURA (ÁREAS Y FRENTES) ──

export async function obtenerEstructuraProduccion(supabase: any, orgId: string) {
  const { data: areas, error: errAreas } = await supabase
    .from("produccion_areas")
    .select("id, clave, nombre, orden, activo, notas")
    .eq("organizacion_id", orgId)
    .order("orden", { ascending: true });

  if (errAreas) throw errAreas;

  const { data: frentes, error: errFrentes } = await supabase
    .from("produccion_frentes")
    .select("id, area_id, nombre, orden, activo, notas")
    .eq("organizacion_id", orgId)
    .order("orden", { ascending: true });

  if (errFrentes) throw errFrentes;

  const frentesPorArea: Record<string, any[]> = {};
  for (const f of frentes || []) {
    if (!frentesPorArea[f.area_id]) frentesPorArea[f.area_id] = [];
    frentesPorArea[f.area_id].push(f);
  }

  const areasConFrentes = (areas || []).map((a: any) => ({
    ...a,
    frentes: frentesPorArea[a.id] || [],
  }));

  return areasConFrentes;
}

export async function guardarArea(
  supabase: any,
  orgId: string,
  id: string | null,
  payload: AreaPayload
) {
  const nombreLimpio = (payload.nombre || "").trim();
  if (!nombreLimpio) {
    const err: any = new Error("El nombre del área es obligatorio");
    err.status = 400;
    throw err;
  }

  if (id) {
    const updateData: any = {
      nombre: nombreLimpio,
      updated_at: new Date().toISOString(),
    };
    if (payload.orden !== undefined) updateData.orden = Number(payload.orden);
    if (payload.activo !== undefined) updateData.activo = Boolean(payload.activo);

    const { data, error } = await supabase
      .from("produccion_areas")
      .update(updateData)
      .eq("id", id)
      .eq("organizacion_id", orgId)
      .select()
      .single();

    if (error) throw error;
    return data;
  } else {
    const clave = (payload.clave || nombreLimpio.toLowerCase().replace(/[^a-z0-9]/g, "_")).slice(0, 50);
    const insertData = {
      organizacion_id: orgId,
      clave,
      nombre: nombreLimpio,
      orden: payload.orden !== undefined ? Number(payload.orden) : 0,
      activo: payload.activo !== undefined ? Boolean(payload.activo) : true,
    };

    const { data, error } = await supabase
      .from("produccion_areas")
      .insert(insertData)
      .select()
      .single();

    if (error) throw error;
    return data;
  }
}

export async function guardarFrente(
  supabase: any,
  orgId: string,
  id: string | null,
  payload: FrentePayload
) {
  const nombreLimpio = (payload.nombre || "").trim();
  if (!nombreLimpio) {
    const err: any = new Error("El nombre del frente es obligatorio");
    err.status = 400;
    throw err;
  }

  if (id) {
    const updateData: any = {
      nombre: nombreLimpio,
      updated_at: new Date().toISOString(),
    };
    if (payload.orden !== undefined) updateData.orden = Number(payload.orden);
    if (payload.activo !== undefined) updateData.activo = Boolean(payload.activo);

    const { data, error } = await supabase
      .from("produccion_frentes")
      .update(updateData)
      .eq("id", id)
      .eq("organizacion_id", orgId)
      .select()
      .single();

    if (error) throw error;
    return data;
  } else {
    if (!payload.area_id) {
      const err: any = new Error("area_id es obligatorio para crear un frente");
      err.status = 400;
      throw err;
    }

    const insertData = {
      organizacion_id: orgId,
      area_id: payload.area_id,
      nombre: nombreLimpio,
      orden: payload.orden !== undefined ? Number(payload.orden) : 0,
      activo: payload.activo !== undefined ? Boolean(payload.activo) : true,
    };

    const { data, error } = await supabase
      .from("produccion_frentes")
      .insert(insertData)
      .select()
      .single();

    if (error) throw error;
    return data;
  }
}

// ── PLAN DE TAREAS SEMANAL ──

export async function obtenerPlanSemanal(
  supabase: any,
  orgId: string,
  desde: string,
  hasta: string,
  areaIdOClave?: string
) {
  let query = supabase
    .from("plan_tareas")
    .select(`
      id,
      organizacion_id,
      fecha,
      frente_id,
      orden_trabajo_id,
      descripcion,
      movilidad,
      observaciones,
      estado,
      inicio_real,
      fin_real,
      material_faltante,
      created_at,
      frente:produccion_frentes!inner(
        id,
        nombre,
        orden,
        area_id,
        area:produccion_areas!inner(id, clave, nombre)
      ),
      orden_trabajo:ordenes_trabajo(
        id,
        nomenclatura_id,
        modelo,
        cliente:clientes(nombre_razon_social)
      ),
      operarios_asig:plan_tarea_operarios(
        operario:operarios(id, nombre, puesto, telefono, activo)
      ),
      materiales:plan_tarea_materiales(
        id,
        producto_id,
        descripcion,
        cantidad,
        unidad,
        notas
      )
    `)
    .eq("organizacion_id", orgId)
    .gte("fecha", desde)
    .lte("fecha", hasta)
    .order("fecha", { ascending: true });

  if (areaIdOClave) {
    // Si parece UUID, filtrar por area_id, sino por clave
    const esUuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(areaIdOClave);
    if (esUuid) {
      query = query.eq("frente.area_id", areaIdOClave);
    } else {
      query = query.eq("frente.area.clave", areaIdOClave);
    }
  }

  const { data, error } = await query;
  if (error) throw error;

  // Aplanar la estructura de operarios para la UI
  const tareasFormateadas = (data || []).map((t: any) => ({
    ...t,
    operarios: (t.operarios_asig || [])
      .map((oa: any) => oa.operario)
      .filter(Boolean),
  }));

  return tareasFormateadas;
}

export async function guardarTarea(
  serviceClient: any,
  orgId: string,
  usuarioId: string | null,
  tareaId: string | null,
  payload: TareaPayload
) {
  if (!payload.fecha) {
    const err: any = new Error("La fecha de la tarea es obligatoria");
    err.status = 400;
    throw err;
  }
  if (!payload.frente_id) {
    const err: any = new Error("El frente de producción es obligatorio");
    err.status = 400;
    throw err;
  }

  const { data: res, error } = await serviceClient.rpc("guardar_plan_tarea", {
    p_org: orgId,
    p_usuario: usuarioId,
    p_tarea_id: tareaId,
    p_fecha: payload.fecha,
    p_frente_id: payload.frente_id,
    p_orden_trabajo_id: payload.orden_trabajo_id || null,
    p_descripcion: payload.descripcion || null,
    p_movilidad: payload.movilidad || null,
    p_observaciones: payload.observaciones || null,
    p_material_faltante: Boolean(payload.material_faltante),
    p_estado: payload.estado || "planeada",
    p_operarios: payload.operarios || [],
    p_materiales: payload.materiales || [],
  });

  if (error) throw error;
  if (res && res.exito === false) {
    const err: any = new Error(res.mensaje || "Error al guardar la tarea");
    err.status = 400;
    err.code = res.error;
    throw err;
  }

  return res;
}

export async function cambiarEstadoTarea(
  serviceClient: any,
  supabase: any,
  orgId: string,
  usuarioId: string | null,
  tareaId: string,
  nuevoEstado: EstadoPlanTarea,
  confirmarReapertura = false
) {
  const { data: tareaActual, error: errFetch } = await supabase
    .from("plan_tareas")
    .select("id, estado, inicio_real, fin_real")
    .eq("id", tareaId)
    .eq("organizacion_id", orgId)
    .maybeSingle();

  if (errFetch || !tareaActual) {
    const err: any = new Error("Tarea no encontrada");
    err.status = 404;
    throw err;
  }

  const evaluacion = puedeCambiarEstado(
    tareaActual.estado as EstadoPlanTarea,
    nuevoEstado,
    { confirmarReapertura }
  );

  if (!evaluacion.valido) {
    const err: any = new Error(evaluacion.motivo || `Transición inválida de ${tareaActual.estado} a ${nuevoEstado}`);
    err.status = 409;
    throw err;
  }

  let inicioReal = tareaActual.inicio_real;
  let finReal = tareaActual.fin_real;

  if (evaluacion.fijaTiempos.fijarInicio && !inicioReal) {
    inicioReal = new Date().toISOString();
  }
  if (evaluacion.fijaTiempos.fijarFin) {
    finReal = new Date().toISOString();
  }

  const { data: res, error } = await serviceClient.rpc("cambiar_estado_plan_tarea", {
    p_org: orgId,
    p_usuario: usuarioId,
    p_tarea_id: tareaId,
    p_nuevo_estado: nuevoEstado,
    p_inicio_real: inicioReal,
    p_fin_real: finReal,
  });

  if (error) throw error;
  return res;
}

export async function eliminarTarea(
  serviceClient: any,
  supabase: any,
  orgId: string,
  usuarioId: string | null,
  tareaId: string,
  confirmado = false
) {
  const { data: tareaActual, error: errFetch } = await supabase
    .from("plan_tareas")
    .select("id, estado")
    .eq("id", tareaId)
    .eq("organizacion_id", orgId)
    .maybeSingle();

  if (errFetch || !tareaActual) {
    const err: any = new Error("Tarea no encontrada");
    err.status = 404;
    throw err;
  }

  if (tareaActual.estado !== "planeada" && tareaActual.estado !== "cancelada" && !confirmado) {
    const err: any = new Error("La tarea se encuentra en curso o terminada. Confirma explícitamente para eliminarla.");
    err.status = 400;
    throw err;
  }

  const { data: res, error } = await serviceClient.rpc("eliminar_plan_tarea", {
    p_org: orgId,
    p_usuario: usuarioId,
    p_tarea_id: tareaId,
  });

  if (error) throw error;
  return res;
}

export async function duplicarSemanaProduccion(
  serviceClient: any,
  supabase: any,
  orgId: string,
  usuarioId: string | null,
  payload: { desde: string; hasta: string; areaIdOClave?: string }
) {
  const { desde, hasta, areaIdOClave } = payload;
  if (!desde || !hasta) {
    const err: any = new Error("Las fechas 'desde' y 'hasta' son obligatorias");
    err.status = 400;
    throw err;
  }

  // Obtener tareas origen (hasta 500)
  const tareasOrigen = await obtenerPlanSemanal(
    supabase,
    orgId,
    desde,
    // La semana origen abarca 7 días
    new Date(new Date(desde + "T12:00:00Z").getTime() + 6 * 24 * 60 * 60 * 1000)
      .toISOString()
      .split("T")[0],
    areaIdOClave
  );

  if (tareasOrigen.length === 0) {
    return { creadas: 0, omitidas: 0, mensaje: "No hay tareas activas en la semana de origen para duplicar" };
  }

  if (tareasOrigen.length > 500) {
    const err: any = new Error("Límite de 500 tareas excedido para duplicar");
    err.status = 413;
    throw err;
  }

  const payloadsNuevas = duplicarSemana(tareasOrigen as PlanTarea[], {
    desde,
    hasta,
  });

  // Consultar tareas ya existentes en la semana destino para garantizar idempotencia
  const fechaFinDestino = new Date(new Date(hasta + "T12:00:00Z").getTime() + 6 * 24 * 60 * 60 * 1000)
    .toISOString()
    .split("T")[0];

  const { data: existentesDestino } = await supabase
    .from("plan_tareas")
    .select("id, fecha, frente_id, orden_trabajo_id, descripcion")
    .eq("organizacion_id", orgId)
    .gte("fecha", hasta)
    .lte("fecha", fechaFinDestino);

  const setExistentes = new Set<string>();
  for (const ex of existentesDestino || []) {
    const clave = `${ex.fecha}__${ex.frente_id}__${ex.orden_trabajo_id || ""}__${(ex.descripcion || "").trim()}`;
    setExistentes.add(clave);
  }

  let creadas = 0;
  let omitidas = 0;

  for (const item of payloadsNuevas) {
    const clave = `${item.fecha}__${item.frente_id}__${item.orden_trabajo_id || ""}__${(item.descripcion || "").trim()}`;
    if (setExistentes.has(clave)) {
      omitidas += 1;
      continue;
    }

    await guardarTarea(serviceClient, orgId, usuarioId, null, item);
    setExistentes.add(clave);
    creadas += 1;
  }

  return { creadas, omitidas };
}

// ── TRAZABILIDAD ──

export async function obtenerTrazabilidadOrden(
  supabase: any,
  orgId: string,
  ordenId: string
) {
  // Validar orden
  const { data: orden, error: errOrden } = await supabase
    .from("ordenes_trabajo")
    .select("id, nomenclatura_id, modelo, cliente:clientes(nombre_razon_social)")
    .eq("id", ordenId)
    .eq("organizacion_id", orgId)
    .maybeSingle();

  if (errOrden || !orden) {
    const err: any = new Error("Orden de trabajo no encontrada");
    err.status = 404;
    throw err;
  }

  // Tareas vinculadas a la orden
  const { data: tareas, error: errTareas } = await supabase
    .from("plan_tareas")
    .select(`
      id,
      fecha,
      frente_id,
      descripcion,
      movilidad,
      observaciones,
      estado,
      inicio_real,
      fin_real,
      material_faltante,
      frente:produccion_frentes(id, nombre, area:produccion_areas(nombre)),
      operarios_asig:plan_tarea_operarios(operario:operarios(id, nombre, puesto)),
      materiales:plan_tarea_materiales(id, descripcion, cantidad, unidad)
    `)
    .eq("orden_trabajo_id", ordenId)
    .eq("organizacion_id", orgId)
    .order("fecha", { ascending: true });

  if (errTareas) throw errTareas;

  const tareaIds = (tareas || []).map((t: any) => t.id);

  // Bitácora de eventos de esas tareas
  let bitacora: any[] = [];
  if (tareaIds.length > 0) {
    const { data: eventos, error: errHist } = await supabase
      .from("plan_tareas_historial")
      .select("id, tarea_id, descripcion_tarea, fecha_tarea, evento, detalle, usuario_id, creado_el")
      .eq("organizacion_id", orgId)
      .in("tarea_id", tareaIds)
      .order("creado_el", { ascending: true });

    if (errHist) throw errHist;
    bitacora = eventos || [];
  }

  const tareasFormateadas = (tareas || []).map((t: any) => ({
    ...t,
    operarios: (t.operarios_asig || []).map((oa: any) => oa.operario).filter(Boolean),
  }));

  return {
    orden,
    tareas: tareasFormateadas,
    bitacora,
  };
}

export async function obtenerTrazabilidadOperario(
  supabase: any,
  orgId: string,
  operarioId: string,
  desde?: string,
  hasta?: string
) {
  const { data: operario, error: errOp } = await supabase
    .from("operarios")
    .select("id, nombre, puesto, telefono, activo")
    .eq("id", operarioId)
    .eq("organizacion_id", orgId)
    .maybeSingle();

  if (errOp || !operario) {
    const err: any = new Error("Operario no encontrado");
    err.status = 404;
    throw err;
  }

  let query = supabase
    .from("plan_tarea_operarios")
    .select(`
      tarea:plan_tareas!inner(
        id,
        fecha,
        descripcion,
        movilidad,
        observaciones,
        estado,
        inicio_real,
        fin_real,
        frente:produccion_frentes(id, nombre, area:produccion_areas(nombre)),
        orden_trabajo:ordenes_trabajo(id, nomenclatura_id, modelo),
        materiales:plan_tarea_materiales(id, descripcion, cantidad, unidad)
      )
    `)
    .eq("organizacion_id", orgId)
    .eq("operario_id", operarioId);

  if (desde) query = query.gte("tarea.fecha", desde);
  if (hasta) query = query.lte("tarea.fecha", hasta);

  const { data, error } = await query;
  if (error) throw error;

  const tareas = (data || []).map((row: any) => row.tarea).filter(Boolean);

  return {
    operario,
    tareas,
  };
}
