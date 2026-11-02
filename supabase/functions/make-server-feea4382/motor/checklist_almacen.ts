/**
 * Motor de Checklist de Entregas Almacén -> Producción
 * Sub-bloque T3 (Turno Noche 2026-11-02)
 */

export interface ParametrosEntrega {
  orgId: string;
  lineaId: string;
  cantidad: number;
  tipo?: "entrega" | "reposicion";
  operarioId?: string | null;
  operarioNombre?: string | null;
  motivo?: string | null;
  usuarioId?: string | null;
}

export interface ParametrosEntregaFase {
  orgId: string;
  otId: string;
  faseClave: string;
  equipoIndice?: number;
  operarioId?: string | null;
  operarioNombre?: string | null;
  usuarioId?: string | null;
}

export interface ParametrosAnularEntrega {
  orgId: string;
  entregaId: string;
  motivo: string;
  usuarioId?: string | null;
}

export interface ParametrosLineaManual {
  orgId: string;
  otId: string;
  equipoIndice?: number;
  faseClave: string;
  materialId?: string | null;
  descripcion: string;
  unidad?: string;
  cantidadRequerida: number;
  notas?: string | null;
}

export interface ParametrosAjustarCantidad {
  orgId: string;
  lineaId: string;
  nuevaCantidad: number;
  motivo: string;
}

/**
 * Consulta el estado y avance de despiece para una Orden de Trabajo
 */
export async function listarDespieceOT(
  client: any,
  parametros: { otId: string; orgId: string; equipoIndice?: number }
) {
  const { otId, orgId, equipoIndice } = parametros;

  let query = client
    .from("v_orden_despiece_avance")
    .select("*")
    .eq("orden_trabajo_id", otId)
    .eq("organizacion_id", orgId)
    .order("fase_orden", { ascending: true })
    .order("descripcion", { ascending: true });

  if (equipoIndice) {
    query = query.eq("equipo_indice", equipoIndice);
  }

  const { data: lineas, error: errLineas } = await query;
  if (errLineas) throw errLineas;

  // Consultar historial de entregas de la OT
  const { data: entregas, error: errEntregas } = await client
    .from("orden_despiece_entregas")
    .select("*, operarios(nombre)")
    .eq("organizacion_id", orgId)
    .in(
      "linea_id",
      (lineas || []).map((l: any) => l.linea_id)
    )
    .order("created_at", { ascending: false });

  if (errEntregas) throw errEntregas;

  // Consultar fases oficiales de la organización
  const { data: fases, error: errFases } = await client
    .from("fases_despiece")
    .select("*")
    .eq("organizacion_id", orgId)
    .eq("activo", true)
    .order("orden", { ascending: true });

  if (errFases) throw errFases;

  // Calcular métricas globales
  let totalRequerido = 0;
  let totalEntregado = 0;
  let totalPendiente = 0;
  let totalReposicion = 0;
  let lineasCompletas = 0;

  for (const l of lineas || []) {
    const req = Number(l.cantidad_requerida) || 0;
    const ent = Number(l.cantidad_entregada) || 0;
    const pen = Number(l.cantidad_pendiente) || 0;
    const rep = Number(l.cantidad_reposicion) || 0;

    totalRequerido += req;
    totalEntregado += ent;
    totalPendiente += pen;
    totalReposicion += rep;

    if (l.estado_entrega === "completo") {
      lineasCompletas++;
    }
  }

  const porcentajeAvance =
    totalRequerido > 0 ? Math.round((totalEntregado / totalRequerido) * 100) : 0;

  return {
    lineas: lineas || [],
    entregas: entregas || [],
    fases: fases || [],
    metricas: {
      total_lineas: (lineas || []).length,
      lineas_completas: lineasCompletas,
      total_piezas_requeridas: Math.round(totalRequerido * 100) / 100,
      total_piezas_entregadas: Math.round(totalEntregado * 100) / 100,
      total_piezas_pendientes: Math.round(totalPendiente * 100) / 100,
      total_piezas_reposicion: Math.round(totalReposicion * 100) / 100,
      porcentaje_avance: porcentajeAvance,
      estado_general:
        totalPendiente === 0 && (lineas || []).length > 0
          ? "completo"
          : totalEntregado > 0
          ? "en_progreso"
          : "pendiente",
    },
  };
}

/**
 * Genera o actualiza idempotentemente las líneas de despiece para una Orden de Trabajo
 */
export async function generarDespieceOT(
  serviceClient: any,
  parametros: { otId: string; orgId: string; forzar?: boolean }
) {
  const { otId, orgId, forzar } = parametros;

  // 1. Obtener orden de trabajo
  const { data: ot, error: errOT } = await serviceClient
    .from("ordenes_trabajo")
    .select("id, cotizacion_id, modelo, organizacion_id")
    .eq("id", otId)
    .eq("organizacion_id", orgId)
    .single();

  if (errOT || !ot) {
    throw new Error("Orden de trabajo no encontrada o no pertenece a la organización");
  }

  // 2. Si ya existen líneas y no se fuerza, retornar conteo actual
  const { count: lineasExistentes, error: errCount } = await serviceClient
    .from("orden_despiece_lineas")
    .select("id", { count: "exact", head: true })
    .eq("orden_trabajo_id", otId)
    .eq("organizacion_id", orgId);

  if (errCount) throw errCount;

  if (lineasExistentes && lineasExistentes > 0 && !forzar) {
    return {
      creadas: 0,
      existentes: lineasExistentes,
      mensaje: "El despiece ya se encuentra generado para esta orden",
    };
  }

  // 3. Buscar presupuesto asociado a la cotización
  let bomItems: any[] = [];

  if (ot.cotizacion_id) {
    const { data: presupuesto } = await serviceClient
      .from("presupuestos")
      .select("datos")
      .eq("cotizacion_id", ot.cotizacion_id)
      .eq("organizacion_id", orgId)
      .limit(1)
      .maybeSingle();

    if (presupuesto?.datos?.meta?.bom && Array.isArray(presupuesto.datos.meta.bom)) {
      // Si meta.bom tiene formato agrupado por equipo o líneas directas
      const bomData = presupuesto.datos.meta.bom;
      if (bomData.length > 0 && bomData[0].lineas) {
        // Formato array de equipos
        bomItems = bomData[0].lineas;
      } else {
        bomItems = bomData;
      }
    }
  }

  // 4. Si no hay BOM en presupuesto, buscar en receta_base del modelo
  if (bomItems.length === 0 && ot.modelo) {
    const { data: receta } = await serviceClient
      .from("receta_base")
      .select("material_id, cantidad, paso, fase_id, productos(nombre, unidad, costo)")
      .eq("modelo_id", ot.modelo);

    if (receta && receta.length > 0) {
      bomItems = receta.map((r: any) => ({
        material_id: r.material_id,
        nombre: r.productos?.nombre || "Material sin nombre",
        unidad: r.productos?.unidad || "pz",
        cantidad: Number(r.cantidad) || 1,
        paso: r.paso || "Paso 1",
        fase_id: r.fase_id || null,
        sin_precio: !r.productos?.costo || r.productos?.costo === 0,
      }));
    }
  }

  // 5. Consultar catálogo de fases y equivalencias
  const { data: fases } = await serviceClient
    .from("fases_despiece")
    .select("id, clave, nombre")
    .eq("organizacion_id", orgId);

  const { data: equiv } = await serviceClient
    .from("fases_despiece_equivalencias")
    .select("paso_legacy, fase_id, fases_despiece(clave)")
    .eq("organizacion_id", orgId);

  const mapaEquiv = new Map<string, { fase_id: string; clave: string }>();
  for (const eq of equiv || []) {
    const leg = (eq.paso_legacy || "").trim().toUpperCase();
    mapaEquiv.set(leg, {
      fase_id: eq.fase_id,
      clave: (eq as any).fases_despiece?.clave || "paso_1",
    });
  }

  // 6. Preparar líneas para inserción idempotente
  const nuevasLineas: any[] = [];
  const equipoIndice = 1;

  for (let i = 0; i < bomItems.length; i++) {
    const item = bomItems[i];
    const nom = item.nombre || item.descripcion || `Pieza ${i + 1}`;
    const pasoRaw = Array.isArray(item.paso) ? item.paso[0] : item.paso || "Paso 1";
    const pasoNorm = (pasoRaw || "").trim().toUpperCase();

    let faseId = item.fase_id || null;
    let faseClave = item.fase_clave || "paso_1";

    if (mapaEquiv.has(pasoNorm)) {
      const match = mapaEquiv.get(pasoNorm)!;
      faseId = match.fase_id;
      faseClave = match.clave;
    } else {
      // Fallback a Paso 1
      const p1 = (fases || []).find((f: any) => f.clave === "paso_1");
      if (p1) {
        faseId = p1.id;
        faseClave = p1.clave;
      }
    }

    const matId = item.material_id || null;
    const claveOrigen = `${faseClave}::${matId || nom}::${item.kit || ""}::${equipoIndice}::${i}`;

    nuevasLineas.push({
      organizacion_id: orgId,
      orden_trabajo_id: otId,
      equipo_indice: equipoIndice,
      fase_id: faseId,
      fase_clave: faseClave,
      kit: item.kit || null,
      material_id: matId,
      descripcion: nom,
      unidad: item.unidad || "pz",
      cantidad_requerida: Math.max(0, Number(item.cantidad) || 1),
      origen: "receta",
      sin_costo: !!item.sin_precio,
      clave_origen: claveOrigen,
    });
  }

  if (nuevasLineas.length === 0) {
    return { creadas: 0, mensaje: "No se encontraron piezas en el presupuesto ni receta del modelo" };
  }

  // 7. Insertar líneas en lotes con ON CONFLICT DO NOTHING
  const { error: errInsert } = await serviceClient
    .from("orden_despiece_lineas")
    .upsert(nuevasLineas, { onConflict: "orden_trabajo_id,equipo_indice,clave_origen" });

  if (errInsert) throw errInsert;

  return {
    creadas: nuevasLineas.length,
    mensaje: `Se generaron ${nuevasLineas.length} líneas de despiece por fases`,
  };
}

/**
 * Registra una entrega o reposición mediante la función atómica SECURITY DEFINER
 */
export async function registrarEntrega(serviceClient: any, p: ParametrosEntrega) {
  if (!Number.isFinite(p.cantidad) || p.cantidad <= 0) {
    throw new Error("La cantidad a entregar debe ser un número mayor a 0");
  }

  const { data, error } = await serviceClient.rpc("registrar_entrega_despiece", {
    p_org_id: p.orgId,
    p_linea_id: p.lineaId,
    p_cantidad: p.cantidad,
    p_tipo: p.tipo || "entrega",
    p_operario_id: p.operarioId || null,
    p_operario_nombre: p.operarioNombre || null,
    p_motivo: p.motivo || null,
    p_entregado_por: p.usuarioId || null,
  });

  if (error) {
    throw new Error(error.message || "Error al registrar entrega en almacén");
  }

  return data;
}

/**
 * Entrega todas las piezas pendientes de una fase completa para una OT
 */
export async function entregarFaseCompleta(serviceClient: any, p: ParametrosEntregaFase) {
  // Consultar todas las líneas pendientes de la fase
  let q = serviceClient
    .from("v_orden_despiece_avance")
    .select("linea_id, descripcion, cantidad_pendiente")
    .eq("orden_trabajo_id", p.otId)
    .eq("organizacion_id", p.orgId)
    .eq("fase_clave", p.faseClave)
    .gt("cantidad_pendiente", 0);

  if (p.equipoIndice) {
    q = q.eq("equipo_indice", p.equipoIndice);
  }

  const { data: lineasPendientes, error: errQ } = await q;
  if (errQ) throw errQ;

  if (!lineasPendientes || lineasPendientes.length === 0) {
    return {
      entregadas: 0,
      mensaje: "No hay piezas pendientes de entrega en esta fase",
    };
  }

  const resultados = [];
  for (const l of lineasPendientes) {
    const res = await registrarEntrega(serviceClient, {
      orgId: p.orgId,
      lineaId: l.linea_id,
      cantidad: Number(l.cantidad_pendiente),
      tipo: "entrega",
      operarioId: p.operarioId,
      operarioNombre: p.operarioNombre,
      motivo: `Entrega completa de fase ${p.faseClave}`,
      usuarioId: p.usuarioId,
    });
    resultados.push(res);
  }

  return {
    entregadas: resultados.length,
    resultados,
    mensaje: `Se entregaron ${resultados.length} partidas de la fase`,
  };
}

/**
 * Anula una entrega registrada previamente
 */
export async function anularEntrega(serviceClient: any, p: ParametrosAnularEntrega) {
  if (!p.motivo || !p.motivo.trim()) {
    throw new Error("El motivo de anulación es obligatorio");
  }

  const { data, error } = await serviceClient.rpc("anular_entrega_despiece", {
    p_org_id: p.orgId,
    p_entrega_id: p.entregaId,
    p_motivo: p.motivo.trim(),
    p_usuario_id: p.usuarioId || null,
  });

  if (error) {
    throw new Error(error.message || "Error al anular entrega");
  }

  return data;
}

/**
 * Agrega una línea manual de despiece a una OT
 */
export async function agregarLineaManual(serviceClient: any, p: ParametrosLineaManual) {
  if (!p.descripcion || !p.descripcion.trim()) {
    throw new Error("La descripción de la pieza es obligatoria");
  }

  if (!Number.isFinite(p.cantidadRequerida) || p.cantidadRequerida <= 0) {
    throw new Error("La cantidad requerida debe ser mayor a 0");
  }

  // Resolver fase_id desde clave
  const { data: fase } = await serviceClient
    .from("fases_despiece")
    .select("id")
    .eq("organizacion_id", p.orgId)
    .eq("clave", p.faseClave)
    .single();

  const equipoIndice = p.equipoIndice || 1;
  const claveOrigen = `manual::${Date.now()}::${Math.random().toString(36).substring(2, 7)}`;

  const { data, error } = await serviceClient
    .from("orden_despiece_lineas")
    .insert([
      {
        organizacion_id: p.orgId,
        orden_trabajo_id: p.otId,
        equipo_indice: equipoIndice,
        fase_id: fase?.id || null,
        fase_clave: p.faseClave,
        material_id: p.materialId || null,
        descripcion: p.descripcion.trim(),
        unidad: p.unidad || "pz",
        cantidad_requerida: p.cantidadRequerida,
        origen: "manual",
        sin_costo: false,
        clave_origen: claveOrigen,
        notas: p.notas || null,
      },
    ])
    .select()
    .single();

  if (error) throw error;
  return data;
}

/**
 * Ajusta la cantidad requerida de una línea
 */
export async function ajustarCantidadRequerida(serviceClient: any, p: ParametrosAjustarCantidad) {
  if (!Number.isFinite(p.nuevaCantidad) || p.nuevaCantidad < 0) {
    throw new Error("La cantidad requerida no puede ser negativa");
  }

  if (!p.motivo || !p.motivo.trim()) {
    throw new Error("El motivo del ajuste es obligatorio");
  }

  // Verificar cantidad ya entregada
  const { data: entregadoData } = await serviceClient
    .from("orden_despiece_entregas")
    .select("cantidad")
    .eq("linea_id", p.lineaId)
    .eq("organizacion_id", p.orgId)
    .eq("anulada", false)
    .eq("tipo", "entrega");

  const totalEntregado = (entregadoData || []).reduce(
    (acc: number, cur: any) => acc + (Number(cur.cantidad) || 0),
    0
  );

  if (p.nuevaCantidad < totalEntregado) {
    throw new Error(
      `No se puede reducir la cantidad requerida a ${p.nuevaCantidad} porque ya se han entregado ${totalEntregado} piezas`
    );
  }

  const { data, error } = await serviceClient
    .from("orden_despiece_lineas")
    .update({
      cantidad_requerida: p.nuevaCantidad,
      notas: `Ajuste: ${p.motivo.trim()}`,
      updated_at: new Date().toISOString(),
    })
    .eq("id", p.lineaId)
    .eq("organizacion_id", p.orgId)
    .select()
    .single();

  if (error) throw error;
  return data;
}

/**
 * Elimina una línea manual si no tiene entregas realizadas
 */
export async function eliminarLineaManual(
  serviceClient: any,
  p: { orgId: string; lineaId: string }
) {
  const { count: entregasCount } = await serviceClient
    .from("orden_despiece_entregas")
    .select("id", { count: "exact", head: true })
    .eq("linea_id", p.lineaId)
    .eq("organizacion_id", p.orgId)
    .eq("anulada", false);

  if (entregasCount && entregasCount > 0) {
    throw new Error("No se puede eliminar una partida que ya cuenta con entregas registradas");
  }

  const { error } = await serviceClient
    .from("orden_despiece_lineas")
    .delete()
    .eq("id", p.lineaId)
    .eq("organizacion_id", p.orgId);

  if (error) throw error;
  return { success: true };
}
