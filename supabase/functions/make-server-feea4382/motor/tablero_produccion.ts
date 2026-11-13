import {
  MAPA_TIPO_EQUIPO_LINEA,
  obtenerLineaPorTipoEquipo,
  calcularSemaforo,
  calcularEtiquetaVisible,
  obtenerHoyMexico,
  CeldaSemaforoInput,
  EstadoFase,
  SemaforoProduccion,
} from "../../../../src/app/utils/tableroProduccion.ts";

export {
  MAPA_TIPO_EQUIPO_LINEA,
  obtenerLineaPorTipoEquipo,
  calcularSemaforo,
  calcularEtiquetaVisible,
  obtenerHoyMexico,
};
export type { CeldaSemaforoInput, EstadoFase, SemaforoProduccion };

const CAMPOS_PLANEACION_PERMITIDOS = new Set([
  "fecha_compromiso",
  "etiqueta",
  "material_faltante",
]);

/**
 * Obtiene la matriz completa del Tablero de Producción para una línea de producto.
 */
export async function obtenerMatrizProduccion(
  supabase: any,
  orgId: string,
  lineaClaveParam?: string,
  serviceClient?: any
) {
  const lineaClave = (lineaClaveParam || "plataforma").trim().toLowerCase();

  // 1. Obtener la línea de la organización
  let { data: linea, error: errLin } = await supabase
    .from("lineas_producto")
    .select("id, clave, nombre")
    .eq("organizacion_id", orgId)
    .eq("clave", lineaClave)
    .maybeSingle();

  if (!linea) {
    // Si la organización no tiene líneas sembradas, sembramos y reintentamos
    const { count } = await supabase
      .from("lineas_producto")
      .select("id", { count: "exact", head: true })
      .eq("organizacion_id", orgId);

    if (!count || count === 0) {
      const clientForRpc = serviceClient || supabase;
      const { error: errSembrar } = await clientForRpc.rpc("sembrar_tablero_produccion", { p_org: orgId });
      if (errSembrar) throw errSembrar;
      const { data: lineaReintento } = await supabase
        .from("lineas_producto")
        .select("id, clave, nombre")
        .eq("organizacion_id", orgId)
        .eq("clave", lineaClave)
        .maybeSingle();
      linea = lineaReintento;
    }
  }

  if (!linea) {
    const err = new Error(`Línea de producción '${lineaClave}' no encontrada`);
    (err as any).status = 404;
    throw err;
  }

  // 2. Fases activas de la línea
  const { data: fasesRaw, error: errFases } = await supabase
    .from("fases_produccion")
    .select("id, orden, nombre, grupo, requiere_grupo, duracion_dias")
    .eq("linea_producto_id", linea.id)
    .eq("activo", true);

  if (errFases) throw errFases;

  // Ordenar fases: 'principal' primero, luego 'tina', y por orden numérico ASC
  const fases = (fasesRaw || []).sort((a: any, b: any) => {
    if (a.grupo !== b.grupo) {
      if (a.grupo === "principal") return -1;
      if (b.grupo === "principal") return 1;
      return (a.grupo || "").localeCompare(b.grupo || "");
    }
    return (a.orden || 0) - (b.orden || 0);
  });

  const fasesPrincipales = fases.filter((f: any) => f.grupo === "principal");
  const fasesTina = fases.filter((f: any) => f.grupo === "tina");
  const totalPrincipal = fasesPrincipales.length;
  const totalTina = fasesTina.length;
  const tieneTina = totalTina > 0;

  // 3. Órdenes de trabajo para esta línea (excluyendo Liberado)
  const { data: ordenes, error: errOrd } = await supabase
    .from("ordenes_trabajo")
    .select(`
      id, nomenclatura_id, etiqueta, cliente_id, cotizacion_id, modelo, tipo_equipo,
      origen, fecha_compromiso, fecha_inicio, material_faltante, estado, estado_kanban,
      created_at,
      cliente:clientes(id, nombre_razon_social, nombre_contacto),
      cotizacion:cotizaciones(id, folio)
    `)
    .eq("organizacion_id", orgId)
    .eq("linea_producto_id", linea.id)
    .neq("estado", "Liberado")
    .order("created_at", { ascending: true });

  if (errOrd) throw errOrd;

  // 3b. Obtener todas las órdenes de la línea (incluidas 'Liberado') para la numeración consecutiva por cliente (#1, #2, ...)
  const { data: todasOrdenesLinea, error: errTodas } = await supabase
    .from("ordenes_trabajo")
    .select("id, cliente_id, created_at")
    .eq("organizacion_id", orgId)
    .eq("linea_producto_id", linea.id)
    .order("created_at", { ascending: true });

  if (errTodas) throw errTodas;

  const ordenList = ordenes || [];
  const ordenIds = ordenList.map((o: any) => o.id);

  // 4. Cargar orden_fases para estas órdenes
  let ordenFases: any[] = [];
  if (ordenIds.length > 0) {
    const { data: ofData, error: errOF } = await supabase
      .from("orden_fases")
      .select("orden_trabajo_id, fase_id, estado, fecha_propuesta, fecha_fin, nota")
      .in("orden_trabajo_id", ordenIds);

    if (errOF) throw errOF;
    ordenFases = ofData || [];
  }

  // Agrupar orden_fases por orden_trabajo_id
  const ofPorOrden = new Map<string, Map<string, any>>();
  for (const of of ordenFases) {
    if (!ofPorOrden.has(of.orden_trabajo_id)) {
      ofPorOrden.set(of.orden_trabajo_id, new Map());
    }
    ofPorOrden.get(of.orden_trabajo_id)!.set(of.fase_id, of);
  }

  const hoy = obtenerHoyMexico();

  // 5. Construir filas
  const filasNoOrdenadas: any[] = [];

  for (const ord of ordenList) {
    const celdasMap = ofPorOrden.get(ord.id) || new Map();
    const celdasObj: Record<string, any> = {};

    let terminadasPrincipal = 0;
    let terminadasTina = 0;
    const celdasParaSemaforo: CeldaSemaforoInput[] = [];

    for (const f of fases) {
      const c = celdasMap.get(f.id);
      const celdaData = {
        estado: c?.estado || "pendiente",
        fecha_propuesta: c?.fecha_propuesta || null,
        fecha_fin: c?.fecha_fin || null,
        nota: c?.nota || null,
      };
      celdasObj[f.id] = celdaData;
      celdasParaSemaforo.push(celdaData);

      if (celdaData.estado === "terminada") {
        if (f.grupo === "principal") terminadasPrincipal++;
        else if (f.grupo === "tina") terminadasTina++;
      }
    }

    // Nombre del cliente para visualización
    const cli = ord.cliente;
    const clienteNombre = cli
      ? cli.nombre_razon_social || cli.nombre_contacto || "Cliente"
      : ord.etiqueta
      ? ord.etiqueta
      : "Inventario";

    // Órdenes del mismo cliente y línea (incluidas las liberadas) para numeración estable "#1, #2..."
    let ordenesMismoCliente: any[] = [];
    if (ord.cliente_id) {
      ordenesMismoCliente = (todasOrdenesLinea || []).filter(
        (o: any) => o.cliente_id === ord.cliente_id
      );
    }

    const etiquetaVisible = calcularEtiquetaVisible(
      {
        id: ord.id,
        etiqueta: ord.etiqueta,
        cliente_nombre: clienteNombre,
        created_at: ord.created_at,
      },
      ordenesMismoCliente
    );

    const semaforo = calcularSemaforo(celdasParaSemaforo, hoy);

    const avance = {
      terminadas: terminadasPrincipal,
      total: totalPrincipal,
    };

    const tina = tieneTina
      ? {
          terminadas: terminadasTina,
          total: totalTina,
        }
      : null;

    const cotizacionFolio =
      ord.cotizacion?.folio || (ord.origen === "manual" ? "Manual" : "Sin cotización");

    // Ratio de avance global para ordenamiento (menos avanzado primero)
    const totalFasesGlobal = totalPrincipal + totalTina;
    const terminadasGlobal = terminadasPrincipal + terminadasTina;
    const ratioAvance = totalFasesGlobal > 0 ? terminadasGlobal / totalFasesGlobal : 0;

    filasNoOrdenadas.push({
      orden_id: ord.id,
      etiqueta: etiquetaVisible,
      cliente_nombre: clienteNombre,
      cotizacion_folio: cotizacionFolio,
      modelo: ord.modelo || null,
      tipo_equipo: ord.tipo_equipo,
      origen: ord.origen || "cotizacion",
      fecha_compromiso: ord.fecha_compromiso || null,
      fecha_inicio: ord.fecha_inicio || null,
      material_faltante: ord.material_faltante || null,
      estado: ord.estado,
      estado_kanban: ord.estado_kanban,
      semaforo,
      avance,
      tina,
      celdas: celdasObj,
      _created_at: ord.created_at,
      _ratioAvance: ratioAvance,
    });
  }

  // Ordenar filas: menos avanzado primero (menor ratioAvance), desempate created_at ASC
  const filas = filasNoOrdenadas
    .sort((a, b) => {
      if (a._ratioAvance !== b._ratioAvance) {
        return a._ratioAvance - b._ratioAvance;
      }
      const tA = a._created_at ? new Date(a._created_at).getTime() : 0;
      const tB = b._created_at ? new Date(b._created_at).getTime() : 0;
      return tA - tB;
    })
    .map(({ _created_at, _ratioAvance, ...resto }) => resto);

  // 6. Calcular resumen
  let atrasadosCount = 0;
  let conMaterialCount = 0;
  let conPausaCount = 0;
  const wipPorFase: Record<string, number> = {};

  for (const f of fases) {
    wipPorFase[f.id] = 0;
  }

  for (const fila of filas) {
    if (fila.semaforo === "atrasado") atrasadosCount++;
    if (fila.material_faltante && fila.material_faltante.trim() !== "") conMaterialCount++;
    if (
      fila.estado_kanban === "pausada" ||
      Object.values(fila.celdas).some((c: any) => c.estado === "pausada")
    ) {
      conPausaCount++;
    }

    for (const [faseId, celda] of Object.entries(fila.celdas) as any[]) {
      if (celda.estado === "en_proceso") {
        wipPorFase[faseId] = (wipPorFase[faseId] || 0) + 1;
      }
    }
  }

  const resumen = {
    en_planta: filas.length,
    atrasados: atrasadosCount,
    con_material: conMaterialCount,
    con_pausa: conPausaCount,
    wip_por_fase: wipPorFase,
  };

  return {
    linea,
    fases,
    filas,
    resumen,
  };
}

/**
 * Actualiza el estado de una fase de una orden mediante la RPC `actualizar_fase_orden`.
 */
export async function actualizarFaseMotor(
  supabase: any,
  orgId: string,
  ordenId: string,
  faseId: string,
  payload: {
    estado: string;
    fecha_propuesta?: string | null;
    nota?: string | null;
  },
  usuarioId?: string | null,
  serviceClient?: any
) {
  if (!payload || !payload.estado) {
    const err = new Error("El estado de la fase es requerido");
    (err as any).status = 400;
    throw err;
  }

  const clientForRpc = serviceClient || supabase;
  const { data, error } = await clientForRpc.rpc("actualizar_fase_orden", {
    p_org: orgId,
    p_orden: ordenId,
    p_fase: faseId,
    p_estado: payload.estado,
    p_fecha_propuesta: payload.fecha_propuesta || null,
    p_nota: payload.nota || null,
    p_usuario: usuarioId || null,
  });

  if (error) {
    const msg = error.message || "";
    const err = new Error(msg);
    if (
      msg.includes("no encontrada") ||
      msg.includes("no pertenece a la organización")
    ) {
      (err as any).status = 404;
    } else if (msg.includes("no pertenece a la línea")) {
      (err as any).status = 409;
    } else {
      (err as any).status = 400;
    }
    throw err;
  }

  return data;
}

/**
 * Actualiza los campos de planeación de una orden (lista blanca estricta).
 */
export async function actualizarPlaneacionMotor(
  supabase: any,
  orgId: string,
  ordenId: string,
  rawPayload: Record<string, any>
) {
  if (!rawPayload || typeof rawPayload !== "object") {
    const err = new Error("Payload inválido");
    (err as any).status = 400;
    throw err;
  }

  // Validar lista blanca estricta
  for (const k of Object.keys(rawPayload)) {
    if (!CAMPOS_PLANEACION_PERMITIDOS.has(k)) {
      const err = new Error(
        `Campo '${k}' no permitido en planeación. Campos permitidos: fecha_compromiso, etiqueta, material_faltante.`
      );
      (err as any).status = 400;
      throw err;
    }
  }

  const updateData: Record<string, any> = {};
  if ("fecha_compromiso" in rawPayload) {
    updateData.fecha_compromiso = rawPayload.fecha_compromiso || null;
  }
  if ("etiqueta" in rawPayload) {
    updateData.etiqueta = rawPayload.etiqueta
      ? String(rawPayload.etiqueta).trim()
      : null;
  }
  if ("material_faltante" in rawPayload) {
    updateData.material_faltante =
      rawPayload.material_faltante !== undefined
        ? rawPayload.material_faltante
        : null;
  }

  const { data: orden, error } = await supabase
    .from("ordenes_trabajo")
    .update(updateData)
    .eq("id", ordenId)
    .eq("organizacion_id", orgId)
    .select("*, cliente:clientes(*), linea:lineas_producto(*)")
    .maybeSingle();

  if (error || !orden) {
    const err = new Error("Orden de trabajo no encontrada");
    (err as any).status = 404;
    throw err;
  }

  return { ok: true, orden };
}

/**
 * Consulta el historial de cambios de fase para una orden.
 */
export async function obtenerHistorialOrdenMotor(
  supabase: any,
  orgId: string,
  ordenId: string
) {
  // 1. Validar que la orden existe y es de la org
  const { data: orden, error: errOrd } = await supabase
    .from("ordenes_trabajo")
    .select("id")
    .eq("id", ordenId)
    .eq("organizacion_id", orgId)
    .maybeSingle();

  if (errOrd || !orden) {
    const err = new Error("Orden de trabajo no encontrada");
    (err as any).status = 404;
    throw err;
  }

  // 2. Obtener historial
  const { data: historialRaw, error: errHist } = await supabase
    .from("historial_fases")
    .select(`
      id,
      fase_id,
      estado,
      estado_anterior,
      fecha_propuesta,
      nota,
      usuario_id,
      fecha_cambio,
      fase:fases_produccion(nombre, grupo, orden)
    `)
    .eq("orden_trabajo_id", ordenId)
    .order("fecha_cambio", { ascending: false });

  if (errHist) throw errHist;

  const historial = historialRaw || [];

  const items = historial.map((h: any) => ({
    id: h.id,
    fase_id: h.fase_id,
    fase_nombre: h.fase?.nombre || null,
    fase_grupo: h.fase?.grupo || null,
    fase_orden: h.fase?.orden || null,
    estado_anterior: h.estado_anterior || null,
    estado_nuevo: h.estado,
    fecha_propuesta: h.fecha_propuesta || null,
    nota: h.nota || null,
    usuario: h.usuario_id || "Sistema",
    usuario_id: h.usuario_id || null,
    fecha_cambio: h.fecha_cambio,
    created_at: h.fecha_cambio,
  }));

  return { ok: true, historial: items };
}

/**
 * Mueve una orden a una fase (compatibilidad con Kanban actual).
 */
export async function moverOrdenMotor(
  supabase: any,
  orgId: string,
  ordenId: string,
  faseActualId: string,
  usuarioId?: string | null,
  serviceClient?: any
) {
  if (
    !faseActualId ||
    faseActualId === "pendientes" ||
    faseActualId === "pendiente"
  ) {
    const err = new Error(
      "No se puede mover la orden a pendientes directamente. Inicie una fase para comenzar la producción."
    );
    (err as any).status = 400;
    throw err;
  }

  // Llama a actualizar_fase_orden poniendo la fase en_proceso
  const res = await actualizarFaseMotor(
    supabase,
    orgId,
    ordenId,
    faseActualId,
    { estado: "en_proceso" },
    usuarioId,
    serviceClient
  );

  return res;
}

/**
 * Crea una orden manual ("Nuevo equipo en planta").
 */
export async function crearOrdenManualMotor(
  supabase: any,
  orgId: string,
  payload: {
    linea?: string;
    tipo_equipo?: string;
    modelo?: string;
    cliente_id?: string | null;
    etiqueta?: string | null;
    fecha_compromiso?: string | null;
    caracteristicas?: Record<string, any>;
  },
  serviceClient?: any
) {
  if (!payload || typeof payload !== "object") {
    const err = new Error("Payload inválido");
    (err as any).status = 400;
    throw err;
  }

  const clientForRpc = serviceClient || supabase;
  const etiquetaTrimmed = payload.etiqueta
    ? String(payload.etiqueta).trim()
    : null;
  const clienteId = payload.cliente_id || null;

  // Regla: Exige cliente_id o etiqueta
  if (!clienteId && (!etiquetaTrimmed || etiquetaTrimmed === "")) {
    const err = new Error(
      "Se requiere cliente_id o etiqueta para crear una orden manual"
    );
    (err as any).status = 400;
    throw err;
  }

  // Resolver clave de línea y tipo de equipo
  let lineaClave = payload.linea ? payload.linea.trim().toLowerCase() : "";
  if (!lineaClave) {
    lineaClave = obtenerLineaPorTipoEquipo(payload.tipo_equipo);
  }

  let tipoEquipo = payload.tipo_equipo
    ? String(payload.tipo_equipo).trim()
    : "";
  if (!tipoEquipo) {
    if (lineaClave === "dolly") tipoEquipo = "02";
    else if (lineaClave === "gondola") tipoEquipo = "03";
    else if (lineaClave === "traila") tipoEquipo = "09";
    else tipoEquipo = "01";
  }

  // Buscar línea de la organización
  let { data: linea } = await supabase
    .from("lineas_producto")
    .select("id, clave, nombre")
    .eq("organizacion_id", orgId)
    .eq("clave", lineaClave)
    .maybeSingle();

  if (!linea) {
    // Si no existe, sembramos con serviceClient y reintentamos
    const { error: errSembrar } = await clientForRpc.rpc("sembrar_tablero_produccion", { p_org: orgId });
    if (errSembrar) throw errSembrar;

    const { data: lineaReintento } = await supabase
      .from("lineas_producto")
      .select("id, clave, nombre")
      .eq("organizacion_id", orgId)
      .eq("clave", lineaClave)
      .maybeSingle();
    linea = lineaReintento;
  }

  if (!linea) {
    const err = new Error(`Línea de producción '${lineaClave}' no encontrada`);
    (err as any).status = 400;
    throw err;
  }

  // Iniciales del cliente para la nomenclatura
  let iniciales = "INV";
  if (clienteId) {
    const { data: cli } = await supabase
      .from("clientes")
      .select("id, nombre_razon_social, nombre_contacto")
      .eq("id", clienteId)
      .eq("organizacion_id", orgId)
      .maybeSingle();

    if (cli) {
      const nom = cli.nombre_razon_social || cli.nombre_contacto || "";
      const palabras = nom.split(" ").filter(Boolean);
      if (palabras.length >= 2) {
        iniciales = palabras
          .slice(0, 3)
          .map((p: string) => p[0])
          .join("")
          .toUpperCase() || "CLI";
      } else {
        iniciales = nom.substring(0, 3).toUpperCase() || "CLI";
      }
    }
  }

  // Obtener número consecutivo
  const { data: seqNum, error: seqErr } = await clientForRpc.rpc(
    "obtener_siguiente_produccion"
  );
  if (seqErr) {
    throw new Error(
      "Fallo al obtener secuencia de producción: " + seqErr.message
    );
  }

  const mesStr = (new Date().getMonth() + 1).toString().padStart(2, "0");
  const anio = new Date().getFullYear().toString().slice(-2);
  const nomenclatura = `${seqNum}-${iniciales}${tipoEquipo}${mesStr}${anio}-1`;

  // Insertar orden de trabajo
  const clientForInsert = (serviceClient && typeof serviceClient.from === "function") ? serviceClient : supabase;
  const { data: orden, error: insErr } = await clientForInsert
    .from("ordenes_trabajo")
    .insert([
      {
        organizacion_id: orgId,
        cotizacion_id: null,
        cliente_id: clienteId,
        etiqueta: etiquetaTrimmed,
        origen: "manual",
        linea_producto_id: linea.id,
        tipo_equipo: tipoEquipo,
        modelo: payload.modelo || null,
        nomenclatura_id: nomenclatura,
        fecha_compromiso: payload.fecha_compromiso || null,
        caracteristicas: payload.caracteristicas || {},
        estado: "Pendiente",
        estado_kanban: "pendiente",
        fase_actual_id: null,
      },
    ])
    .select("*, cliente:clientes(*), linea:lineas_producto(*)")
    .single();

  if (insErr) throw insErr;

  // Crear sus fases vinculadas con serviceClient
  const { error: errFases } = await clientForRpc.rpc("crear_fases_orden", {
    p_org: orgId,
    p_orden: orden.id,
  });
  if (errFases) throw errFases;

  return { ok: true, orden };
}

/**
 * Siembra las 4 líneas y 55 fases de producción para una organización.
 */
export async function sembrarTableroMotor(
  supabase: any,
  orgId: string,
  serviceClient?: any
) {
  const clientForRpc = serviceClient || supabase;
  const { data, error } = await clientForRpc.rpc("sembrar_tablero_produccion", {
    p_org: orgId,
  });
  if (error) throw error;
  return { ok: true, resultado: data };
}
