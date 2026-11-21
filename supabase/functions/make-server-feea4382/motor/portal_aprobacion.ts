export interface RespuestaPortal {
  status: number;
  body: Record<string, unknown>;
}

export interface ParamsAprobarPortal {
  token: string;
  firma_imagen?: string | null;
  firma_nombre?: string | null;
  firma_ip?: string | null;
}

export interface ParamsComentarioPortal {
  token: string;
  comentario?: string | null;
  firma_ip?: string | null;
}

export interface DepsPortalAprobacion {
  aplicarEfectos?: (
    supabase: any,
    cotizacionId: string,
    orgId: string,
    usuarioId: string | null,
  ) => Promise<void>;
  ahora?: () => Date;
}

async function registrarEventoSeguro(
  supabase: any,
  evento: {
    cotizacion_id: string;
    organizacion_id: string;
    evento: string;
    usuario_id: string | null;
  },
) {
  try {
    const { error } = await supabase.from("cotizacion_eventos").insert([evento]);
    if (error) {
      console.error("[portal] Error registrando evento:", error);
    }
  } catch (err) {
    console.error("[portal] Excepción registrando evento:", err);
  }
}

function mensajeEstadoNoDisponible(estado: string, accion: "aprobar" | "rechazar" | "solicitar cambios"): {
  error: string;
  codigo: string;
} {
  if (estado === "Aprobada") {
    return {
      error: "Esta cotización ya fue aprobada.",
      codigo: "YA_APROBADA",
    };
  }
  return {
    error: `Esta cotización ya no está disponible para ${accion}, contacta a tu asesor.`,
    codigo: "ESTADO_NO_DISPONIBLE",
  };
}

/**
 * Procesa la aprobación de una cotización desde el portal público del cliente
 * usando actualización atómica (WHERE id = ? AND estado = 'Enviada') para evitar
 * dobles aprobaciones concurrentes y aislando los fallos de efectos posteriores.
 */
export async function aprobarPorPortal(
  supabase: any,
  params: ParamsAprobarPortal,
  deps: DepsPortalAprobacion = {},
): Promise<RespuestaPortal> {
  const ahora = deps.ahora ?? (() => new Date());
  const firmaNombreLimpio = typeof params.firma_nombre === "string" ? params.firma_nombre.trim() : "";
  const firmaImagenLimpia = typeof params.firma_imagen === "string" ? params.firma_imagen.trim() : "";
  const ipLimpia = typeof params.firma_ip === "string" && params.firma_ip.trim()
    ? params.firma_ip.trim()
    : "unknown";

  if (!firmaNombreLimpio || !firmaImagenLimpia) {
    return {
      status: 400,
      body: {
        error: "Se requiere tu nombre y firma para aprobar la cotización.",
        codigo: "FIRMA_REQUERIDA",
      },
    };
  }

  const { data: cot, error: errSelect } = await supabase
    .from("cotizaciones")
    .select("id, token_expira_en, estado, organizacion_id")
    .eq("token_publico", params.token)
    .maybeSingle();

  if (errSelect) throw errSelect;
  if (!cot) {
    return {
      status: 404,
      body: { error: "Token inválido o cotización no encontrada.", codigo: "TOKEN_INVALIDO" },
    };
  }

  if (cot.token_expira_en && new Date(cot.token_expira_en) < ahora()) {
    return {
      status: 410,
      body: { error: "El enlace expiró.", codigo: "TOKEN_EXPIRADO" },
    };
  }

  if (cot.estado !== "Enviada") {
    const msg = mensajeEstadoNoDisponible(cot.estado, "aprobar");
    return {
      status: 409,
      body: { ...msg, estado_actual: cot.estado },
    };
  }

  const fechaIso = ahora().toISOString();

  // Comparación atómica: solo actualiza si sigue en estado 'Enviada'
  const { data: actualizada, error: errUpdate } = await supabase
    .from("cotizaciones")
    .update({
      estado: "Aprobada",
      firma_imagen: firmaImagenLimpia,
      firma_nombre: firmaNombreLimpio,
      firma_fecha: fechaIso,
      firma_ip: ipLimpia,
    })
    .eq("id", cot.id)
    .eq("estado", "Enviada")
    .select("id, estado, organizacion_id")
    .maybeSingle();

  if (errUpdate) throw errUpdate;

  if (!actualizada) {
    const { data: recarga } = await supabase
      .from("cotizaciones")
      .select("estado")
      .eq("id", cot.id)
      .maybeSingle();
    const estadoActual = recarga?.estado || "Aprobada";
    const msg = mensajeEstadoNoDisponible(estadoActual, "aprobar");
    return {
      status: 409,
      body: { ...msg, estado_actual: estadoActual },
    };
  }

  // Registrar siempre el evento legal de aprobación desde el portal
  await registrarEventoSeguro(supabase, {
    cotizacion_id: cot.id,
    organizacion_id: cot.organizacion_id,
    evento: `Aprobada por el cliente desde el portal — Firma: ${firmaNombreLimpio}, IP: ${ipLimpia}, Fecha: ${fechaIso}`,
    usuario_id: null,
  });

  // Ejecutar efectos posteriores sin revertir ni devolver 500 si fallan
  let efectosPendientes = false;
  if (deps.aplicarEfectos) {
    try {
      await deps.aplicarEfectos(supabase, cot.id, cot.organizacion_id, null);
    } catch (err: any) {
      efectosPendientes = true;
      const mensajeError = err instanceof Error
        ? err.message
        : (typeof err?.message === "string" ? err.message : JSON.stringify(err || "error desconocido"));
      console.error(`[portal/aprobar] Error en efectos posteriores para cotización ${cot.id}:`, err);
      await registrarEventoSeguro(supabase, {
        cotizacion_id: cot.id,
        organizacion_id: cot.organizacion_id,
        evento: `Aprobada desde el portal — efectos pendientes: ${mensajeError}`,
        usuario_id: null,
      });
    }
  }

  return {
    status: 200,
    body: {
      success: true,
      estado: "Aprobada",
      firma_nombre: firmaNombreLimpio,
      firma_fecha: fechaIso,
      ...(efectosPendientes ? { efectos_pendientes: true } : {}),
    },
  };
}

/**
 * Procesa el rechazo de una cotización desde el portal público con actualización atómica.
 */
export async function rechazarPorPortal(
  supabase: any,
  params: ParamsComentarioPortal,
  deps: Pick<DepsPortalAprobacion, "ahora"> = {},
): Promise<RespuestaPortal> {
  const ahora = deps.ahora ?? (() => new Date());
  const comentarioLimpio = typeof params.comentario === "string" ? params.comentario.trim() : "";
  const ipLimpia = typeof params.firma_ip === "string" && params.firma_ip.trim()
    ? params.firma_ip.trim()
    : "unknown";

  if (!comentarioLimpio) {
    return {
      status: 400,
      body: { error: "Por favor indica el motivo de rechazo.", codigo: "COMENTARIO_REQUERIDO" },
    };
  }

  const { data: cot, error: errSelect } = await supabase
    .from("cotizaciones")
    .select("id, token_expira_en, estado, organizacion_id")
    .eq("token_publico", params.token)
    .maybeSingle();

  if (errSelect) throw errSelect;
  if (!cot) {
    return {
      status: 404,
      body: { error: "Token inválido o cotización no encontrada.", codigo: "TOKEN_INVALIDO" },
    };
  }

  if (cot.token_expira_en && new Date(cot.token_expira_en) < ahora()) {
    return {
      status: 410,
      body: { error: "El enlace expiró.", codigo: "TOKEN_EXPIRADO" },
    };
  }

  if (cot.estado !== "Enviada") {
    const msg = mensajeEstadoNoDisponible(cot.estado, "rechazar");
    return {
      status: 409,
      body: { ...msg, estado_actual: cot.estado },
    };
  }

  const { data: actualizada, error: errUpdate } = await supabase
    .from("cotizaciones")
    .update({
      estado: "Cancelada",
      comentario_cliente: comentarioLimpio,
    })
    .eq("id", cot.id)
    .eq("estado", "Enviada")
    .select("id")
    .maybeSingle();

  if (errUpdate) throw errUpdate;
  if (!actualizada) {
    return {
      status: 409,
      body: {
        error: "Esta cotización ya no está disponible para rechazar, contacta a tu asesor.",
        codigo: "ESTADO_NO_DISPONIBLE",
      },
    };
  }

  const fechaIso = ahora().toISOString();
  await registrarEventoSeguro(supabase, {
    cotizacion_id: cot.id,
    organizacion_id: cot.organizacion_id,
    evento: `Rechazada por el cliente desde el portal — IP: ${ipLimpia}, Fecha: ${fechaIso}. Comentario: ${comentarioLimpio}`,
    usuario_id: null,
  });

  return { status: 200, body: { success: true, estado: "Cancelada" } };
}

/**
 * Registra una solicitud de cambios desde el portal público cuando la cotización está Enviada.
 */
export async function solicitarCambiosPorPortal(
  supabase: any,
  params: ParamsComentarioPortal,
  deps: Pick<DepsPortalAprobacion, "ahora"> = {},
): Promise<RespuestaPortal> {
  const ahora = deps.ahora ?? (() => new Date());
  const comentarioLimpio = typeof params.comentario === "string" ? params.comentario.trim() : "";
  const ipLimpia = typeof params.firma_ip === "string" && params.firma_ip.trim()
    ? params.firma_ip.trim()
    : "unknown";

  if (!comentarioLimpio) {
    return {
      status: 400,
      body: { error: "Por favor describe los cambios que necesitas.", codigo: "COMENTARIO_REQUERIDO" },
    };
  }

  const { data: cot, error: errSelect } = await supabase
    .from("cotizaciones")
    .select("id, token_expira_en, estado, organizacion_id")
    .eq("token_publico", params.token)
    .maybeSingle();

  if (errSelect) throw errSelect;
  if (!cot) {
    return {
      status: 404,
      body: { error: "Token inválido o cotización no encontrada.", codigo: "TOKEN_INVALIDO" },
    };
  }

  if (cot.token_expira_en && new Date(cot.token_expira_en) < ahora()) {
    return {
      status: 410,
      body: { error: "El enlace expiró.", codigo: "TOKEN_EXPIRADO" },
    };
  }

  if (cot.estado !== "Enviada") {
    const msg = mensajeEstadoNoDisponible(cot.estado, "solicitar cambios");
    return {
      status: 409,
      body: { ...msg, estado_actual: cot.estado },
    };
  }

  const { data: actualizada, error: errUpdate } = await supabase
    .from("cotizaciones")
    .update({
      comentario_cliente: comentarioLimpio,
    })
    .eq("id", cot.id)
    .eq("estado", "Enviada")
    .select("id")
    .maybeSingle();

  if (errUpdate) throw errUpdate;
  if (!actualizada) {
    return {
      status: 409,
      body: {
        error: "Esta cotización ya no está disponible para solicitar cambios, contacta a tu asesor.",
        codigo: "ESTADO_NO_DISPONIBLE",
      },
    };
  }

  const fechaIso = ahora().toISOString();
  await registrarEventoSeguro(supabase, {
    cotizacion_id: cot.id,
    organizacion_id: cot.organizacion_id,
    evento: `Cambios solicitados por el cliente desde el portal — IP: ${ipLimpia}, Fecha: ${fechaIso}. Comentario: ${comentarioLimpio}`,
    usuario_id: null,
  });

  return { status: 200, body: { success: true } };
}
