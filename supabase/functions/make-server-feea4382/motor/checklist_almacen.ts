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
 * Localiza el BOM desde cotizaciones/presupuestos (PRE-<folio> o meta.cotizacion_id),
 * asocia el equipo por item_id/modelo_id, genera claves estables sin índices volátiles,
 * suma duplicados y nunca sobreescribe líneas ya existentes o entregadas.
 */
export async function generarDespieceOT(
  serviceClient: any,
  parametros: { otId: string; orgId: string; forzar?: boolean }
) {
  const { otId, orgId, forzar } = parametros;

  // 1. Obtener orden de trabajo con sus características
  const { data: ot, error: errOT } = await serviceClient
    .from("ordenes_trabajo")
    .select("id, cotizacion_id, modelo, caracteristicas, organizacion_id")
    .eq("id", otId)
    .eq("organizacion_id", orgId)
    .single();

  if (errOT || !ot) {
    throw new Error("ot_no_encontrada: Orden de trabajo no encontrada o no pertenece a la organización");
  }

  // 2. Extraer identificadores del equipo
  const caracteristicas = ot.caracteristicas || {};
  const itemId = caracteristicas.item_id;
  const modeloId = caracteristicas.modelo_id || caracteristicas.ficha?.modelo_id || ot.modelo;
  const equipoIndice = Number(caracteristicas.unidad) || 1;

  // 3. Buscar BOM en presupuesto asociado a la cotización
  let bomItems: any[] = [];

  if (ot.cotizacion_id) {
    // Consultar cotización para obtener folio oficial
    const { data: cotizacion, error: errCotiz } = await serviceClient
      .from("cotizaciones")
      .select("id, folio")
      .eq("id", ot.cotizacion_id)
      .eq("organizacion_id", orgId)
      .maybeSingle();

    if (errCotiz) {
      console.error("[checklist] Error consultando cotización:", errCotiz);
    }

    let presupuesto: any = null;

    if (cotizacion?.folio) {
      const { data: pFolio, error: errPFolio } = await serviceClient
        .from("presupuestos")
        .select("id, datos")
        .eq("organizacion_id", orgId)
        .eq("folio", `PRE-${cotizacion.folio}`)
        .maybeSingle();

      if (errPFolio) {
        console.error("[checklist] Error consultando presupuesto por folio:", errPFolio);
      }
      if (pFolio?.datos) {
        presupuesto = pFolio;
      }
    }

    if (!presupuesto) {
      // Fallback: búsqueda por cotizacion_id dentro del jsonb meta
      const { data: pList, error: errPList } = await serviceClient
        .from("presupuestos")
        .select("id, datos")
        .eq("organizacion_id", orgId)
        .limit(50);

      if (errPList) {
        console.error("[checklist] Error consultando presupuestos por lista:", errPList);
      }

      if (pList) {
        presupuesto = pList.find(
          (p: any) => p.datos?.meta?.cotizacion_id === ot.cotizacion_id
        );
      }
    }

    if (presupuesto?.datos?.meta?.bom && Array.isArray(presupuesto.datos.meta.bom)) {
      const bomData = presupuesto.datos.meta.bom;
      if (bomData.length > 0 && bomData[0].lineas) {
        // Formato array de equipos: buscar correspondencia por item_id o modelo_id
        let equipoBom = bomData.find(
          (b: any) => (itemId && b.item_id === itemId) || (modeloId && b.modelo_id === modeloId)
        );
        if (!equipoBom && bomData.length > 0) {
          const idx = Math.min(equipoIndice - 1, bomData.length - 1);
          equipoBom = bomData[Math.max(0, idx)];
        }
        bomItems = equipoBom?.lineas || [];
      } else {
        bomItems = bomData;
      }
    }
  }

  // 4. Si no hay BOM en presupuesto, buscar en receta_base del modelo
  if (bomItems.length === 0 && modeloId) {
    const { data: receta, error: errReceta } = await serviceClient
      .from("receta_base")
      .select("material_id, cantidad, paso, fase_id, productos(nombre, unidad, costo)")
      .eq("modelo_id", modeloId);

    if (errReceta) {
      console.error("[checklist] Error consultando receta_base:", errReceta);
    }

    if (receta && receta.length > 0) {
      bomItems = receta.map((r: any) => ({
        material_id: r.material_id,
        nombre: r.productos?.nombre || "Material sin nombre",
        unidad: r.productos?.unidad || "pz",
        cantidad: Number(r.cantidad) || 0,
        paso: r.paso || "Paso 1",
        fase_id: r.fase_id || null,
        sin_precio: !r.productos?.costo || r.productos?.costo === 0,
      }));
    }
  }

  // 5. Consultar catálogo de fases y equivalencias de la organización
  const { data: fases, error: errFases } = await serviceClient
    .from("fases_despiece")
    .select("id, clave, nombre")
    .eq("organizacion_id", orgId);

  if (errFases) throw errFases;

  const { data: equiv, error: errEquiv } = await serviceClient
    .from("fases_despiece_equivalencias")
    .select("paso_legacy, fase_id, fases_despiece(clave)")
    .eq("organizacion_id", orgId);

  if (errEquiv) throw errEquiv;

  const mapaEquiv = new Map<string, { fase_id: string; clave: string }>();
  for (const eq of equiv || []) {
    const leg = (eq.paso_legacy || "").trim().toUpperCase();
    mapaEquiv.set(leg, {
      fase_id: eq.fase_id,
      clave: (eq as any).fases_despiece?.clave || "paso_1",
    });
  }

  // 6. Preparar y fusionar líneas por clave estable determinística
  const mapaLineas = new Map<string, any>();
  const normalizar = (s: string) =>
    (s || "").trim().toLowerCase().replace(/[^a-z0-9_-]/g, "_");

  for (const item of bomItems) {
    const cant = Number(item.cantidad) || 0;
    if (cant <= 0) continue; // No inventar piezas si cantidad es nula o 0

    const nom = (item.nombre || item.descripcion || "").trim() || "Pieza sin nombre";
    const pasoRaw = Array.isArray(item.paso) ? item.paso[0] : item.paso || "Paso 1";
    const pasoNorm = (pasoRaw || "").trim().toUpperCase();

    let faseId = item.fase_id || null;
    let faseClave = item.fase_clave || "paso_1";

    if (mapaEquiv.has(pasoNorm)) {
      const match = mapaEquiv.get(pasoNorm)!;
      faseId = match.fase_id;
      faseClave = match.clave;
    } else {
      const p1 = (fases || []).find((f: any) => f.clave === "paso_1");
      if (p1) {
        faseId = p1.id;
        faseClave = p1.clave;
      }
    }

    const matId = item.material_id || null;
    const matClave = normalizar(matId || nom);
    const faseClaveNorm = normalizar(faseClave);
    const kitNorm = normalizar(item.kit || "base");
    const claveOrigen = `${faseClaveNorm}::${matClave}::${kitNorm}`;

    if (mapaLineas.has(claveOrigen)) {
      const existente = mapaLineas.get(claveOrigen);
      existente.cantidad_requerida = Math.round((existente.cantidad_requerida + cant) * 10000) / 10000;
    } else {
      mapaLineas.set(claveOrigen, {
        organizacion_id: orgId,
        orden_trabajo_id: otId,
        equipo_indice: equipoIndice,
        fase_id: faseId,
        fase_clave: faseClave,
        kit: item.kit || null,
        material_id: matId,
        descripcion: nom,
        unidad: item.unidad || "pz",
        cantidad_requerida: Math.round(cant * 10000) / 10000,
        origen: "receta",
        sin_costo: !!item.sin_precio,
        clave_origen: claveOrigen,
      });
    }
  }

  // 7. Consultar líneas existentes en la base de datos para no pisar lo ya entregado
  const { data: lineasBD, error: errLineasBD } = await serviceClient
    .from("orden_despiece_lineas")
    .select("clave_origen")
    .eq("orden_trabajo_id", otId)
    .eq("equipo_indice", equipoIndice)
    .eq("organizacion_id", orgId);

  if (errLineasBD) throw errLineasBD;

  const clavesExistentes = new Set((lineasBD || []).map((l: any) => l.clave_origen));
  const lineasAInsertar = Array.from(mapaLineas.values()).filter(
    (l) => !clavesExistentes.has(l.clave_origen)
  );

  if (lineasAInsertar.length === 0) {
    return {
      creadas: 0,
      existentes: clavesExistentes.size,
      mensaje: clavesExistentes.size > 0
        ? "El despiece ya contiene todas las piezas requeridas (no se alteraron las existentes ni lo entregado)"
        : "No se encontraron piezas en el presupuesto ni receta del modelo",
    };
  }

  const { error: errInsert } = await serviceClient
    .from("orden_despiece_lineas")
    .insert(lineasAInsertar);

  if (errInsert) throw errInsert;

  return {
    creadas: lineasAInsertar.length,
    existentes: clavesExistentes.size,
    mensaje: `Se agregaron ${lineasAInsertar.length} líneas nuevas de despiece sin afectar las existentes`,
  };
}

/**
 * Registra una entrega o reposición mediante la función atómica SECURITY DEFINER
 */
export async function registrarEntrega(serviceClient: any, p: ParametrosEntrega) {
  if (!Number.isFinite(p.cantidad) || p.cantidad <= 0) {
    throw new Error("cantidad_invalida: La cantidad a entregar debe ser un número mayor a 0");
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
    throw new Error("motivo_requerido: El motivo de anulación es obligatorio");
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
 * Agrega una línea manual de despiece a una OT validando tenencia
 */
export async function agregarLineaManual(serviceClient: any, p: ParametrosLineaManual) {
  if (!p.descripcion || !p.descripcion.trim()) {
    throw new Error("descripcion_requerida: La descripción de la pieza es obligatoria");
  }

  if (!Number.isFinite(p.cantidadRequerida) || p.cantidadRequerida <= 0) {
    throw new Error("cantidad_invalida: La cantidad requerida debe ser mayor a 0");
  }

  // 1. Validar que la orden de trabajo pertenece a la organización
  const { data: ot, error: errOT } = await serviceClient
    .from("ordenes_trabajo")
    .select("id")
    .eq("id", p.otId)
    .eq("organizacion_id", p.orgId)
    .single();

  if (errOT || !ot) {
    throw new Error("ot_no_encontrada: La orden de trabajo no existe o pertenece a otra organización");
  }

  // 2. Resolver y validar fase_id desde clave
  const { data: fase, error: errFase } = await serviceClient
    .from("fases_despiece")
    .select("id, clave")
    .eq("organizacion_id", p.orgId)
    .eq("clave", p.faseClave)
    .maybeSingle();

  if (!fase) {
    throw new Error("fase_no_encontrada: La fase especificada no existe en la organización");
  }

  const equipoIndice = p.equipoIndice || 1;
  const claveOrigen = `manual::${Date.now()}::${Math.random().toString(36).substring(2, 7)}`;

  const { data, error } = await serviceClient
    .from("orden_despiece_lineas")
    .insert([
      {
        organizacion_id: p.orgId,
        orden_trabajo_id: p.otId,
        equipo_indice: equipoIndice,
        fase_id: fase.id,
        fase_clave: fase.clave,
        material_id: p.materialId || null,
        descripcion: p.descripcion.trim(),
        unidad: p.unidad || "pz",
        cantidad_requerida: Math.round(p.cantidadRequerida * 10000) / 10000,
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
 * Ajusta la cantidad requerida de una línea utilizando la RPC atómica con FOR UPDATE
 */
export async function ajustarCantidadRequerida(serviceClient: any, p: ParametrosAjustarCantidad & { usuarioId?: string | null }) {
  if (!Number.isFinite(p.nuevaCantidad) || p.nuevaCantidad < 0) {
    throw new Error("cantidad_invalida: La cantidad requerida no puede ser negativa");
  }

  if (!p.motivo || !p.motivo.trim()) {
    throw new Error("motivo_requerido: El motivo del ajuste es obligatorio");
  }

  const { data, error } = await serviceClient.rpc("ajustar_cantidad_despiece", {
    p_org_id: p.orgId,
    p_linea_id: p.lineaId,
    p_nueva_cantidad: p.nuevaCantidad,
    p_motivo: p.motivo.trim(),
    p_usuario_id: p.usuarioId || null,
  });

  if (error) {
    throw new Error(error.message || "Error al ajustar cantidad requerida");
  }

  return data;
}

/**
 * Elimina una línea manual si no tiene entregas realizadas utilizando la RPC atómica
 */
export async function eliminarLineaManual(
  serviceClient: any,
  p: { orgId: string; lineaId: string }
) {
  const { data, error } = await serviceClient.rpc("eliminar_linea_despiece", {
    p_org_id: p.orgId,
    p_linea_id: p.lineaId,
  });

  if (error) {
    throw new Error(error.message || "Error al eliminar partida");
  }

  return data;
}
