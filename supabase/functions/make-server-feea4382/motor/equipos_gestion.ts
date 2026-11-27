/**
 * Motor de Gestión de Equipos (órdenes de trabajo):
 * - Cancelar y reactivar equipos sin borrar (auditoría en orden_cambios)
 * - Cambiar cliente solo en equipos origen = 'manual' (folio intacto)
 * - Validación de fecha_pedido y permisos admin / propietario en servidor
 */

export class EquiposGestionError extends Error {
  status: number;
  codigo: string;
  detalle?: Record<string, any>;

  constructor(
    status: number,
    codigo: string,
    message: string,
    detalle?: Record<string, any>
  ) {
    super(message);
    this.name = "EquiposGestionError";
    this.status = status;
    this.codigo = codigo;
    this.detalle = detalle;
  }
}

export const ROLES_GESTION_EQUIPOS = new Set(["admin", "propietario"]);

/**
 * Valida en el servidor que el usuario pertenece a la organización con rol admin o propietario.
 */
export async function validarRolAdminOPropietario(
  serviceClient: any,
  orgId: string,
  usuarioId?: string | null
): Promise<string> {
  if (!orgId || !usuarioId) {
    throw new EquiposGestionError(
      403,
      "sin_permiso",
      "Solo administradores o propietarios pueden realizar esta acción."
    );
  }

  const { data, error } = await serviceClient
    .from("perfiles_organizacion")
    .select("rol")
    .eq("organizacion_id", orgId)
    .eq("usuario_id", usuarioId)
    .maybeSingle();

  if (error || !data) {
    throw new EquiposGestionError(
      403,
      "sin_permiso",
      "No se pudo verificar tu rol en la organización. Solo administradores o propietarios pueden realizar esta acción."
    );
  }

  const rol = String(data.rol || "").trim().toLowerCase();
  if (!ROLES_GESTION_EQUIPOS.has(rol)) {
    throw new EquiposGestionError(
      403,
      "sin_permiso",
      "Solo administradores o propietarios pueden cancelar, reactivar o cambiar el cliente de un equipo."
    );
  }

  return rol;
}

/**
 * Valida una fecha calendario YYYY-MM-DD (o null/vacía).
 */
export function normalizarFechaIsoOpcional(
  valor: unknown,
  nombreCampo = "fecha_pedido"
): string | null {
  if (valor === null || valor === undefined || valor === "") {
    return null;
  }
  const str = String(valor).trim();
  if (!str) return null;
  const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(str);
  if (!match) {
    throw new EquiposGestionError(
      400,
      "fecha_invalida",
      `El campo ${nombreCampo} debe tener formato YYYY-MM-DD.`
    );
  }
  const anio = Number(match[1]);
  const mes = Number(match[2]);
  const dia = Number(match[3]);
  const dt = new Date(Date.UTC(anio, mes - 1, dia));
  if (
    dt.getUTCFullYear() !== anio ||
    dt.getUTCMonth() !== mes - 1 ||
    dt.getUTCDate() !== dia
  ) {
    throw new EquiposGestionError(
      400,
      "fecha_invalida",
      `La fecha '${str}' en ${nombreCampo} no es válida.`
    );
  }
  return str;
}

function parsearDetalleJson(raw: unknown): Record<string, any> | undefined {
  if (!raw) return undefined;
  if (typeof raw === "object") return raw as Record<string, any>;
  if (typeof raw === "string") {
    try {
      const parsed = JSON.parse(raw);
      if (parsed && typeof parsed === "object") return parsed;
    } catch {
      return undefined;
    }
  }
  return undefined;
}

/**
 * Traduce errores de las RPCs de gestión de equipos a EquiposGestionError con HTTP correcto.
 */
export function mapearErrorRpcEquipos(error: any): EquiposGestionError {
  const msg = String(error?.message || "Error procesando operación de equipo");
  const detailObj = parsearDetalleJson(error?.details ?? error?.detail);
  const idx = msg.indexOf(":");
  const prefijo = idx > 0 ? msg.slice(0, idx).trim() : "";
  const limpio = idx > 0 ? msg.slice(idx + 1).trim() || msg : msg;

  switch (prefijo) {
    case "motivo_requerido":
    case "cliente_o_etiqueta_requerido":
    case "org_requerida":
      return new EquiposGestionError(400, prefijo, limpio, detailObj);

    case "orden_no_encontrada":
    case "cliente_no_encontrado":
      return new EquiposGestionError(404, prefijo, limpio, detailObj);

    case "orden_con_cobros_vigentes":
      return new EquiposGestionError(409, prefijo, limpio, detailObj);

    case "orden_con_material_entregado":
      return new EquiposGestionError(409, prefijo, limpio, {
        ...(detailObj || {}),
        requiere_confirmacion_material: true,
      });

    case "orden_origen_cotizacion":
    case "orden_cancelada":
      return new EquiposGestionError(409, prefijo, limpio, detailObj);

    default:
      if (error instanceof EquiposGestionError) return error;
      if (error?.code === "23514") {
        return new EquiposGestionError(
          400,
          "restriccion_campos",
          "Los datos del equipo no cumplen las reglas de cliente/etiqueta."
        );
      }
      return new EquiposGestionError(500, "error_interno", msg);
  }
}

async function cargarOrdenEnriquecida(
  serviceClient: any,
  orgId: string,
  ordenId: string
) {
  const { data } = await serviceClient
    .from("ordenes_trabajo")
    .select(
      "*, cliente:clientes(*), cotizacion:cotizaciones(*), linea:lineas_producto(*), fase:fases_produccion(*)"
    )
    .eq("id", ordenId)
    .eq("organizacion_id", orgId)
    .maybeSingle();
  return data || null;
}

/**
 * Cancela un equipo (nunca borra). Solo admin o propietario.
 */
export async function cancelarOrdenTrabajoMotor(
  serviceClient: any,
  params: {
    orgId: string;
    usuarioId: string | null;
    ordenId: string;
    motivo: string;
    confirmoMaterialEntregado?: boolean;
  }
) {
  await validarRolAdminOPropietario(
    serviceClient,
    params.orgId,
    params.usuarioId
  );

  const motivo = String(params.motivo ?? "").trim();
  if (!motivo) {
    throw new EquiposGestionError(
      400,
      "motivo_requerido",
      "El motivo de cancelación es obligatorio."
    );
  }

  const { data, error } = await serviceClient.rpc("cancelar_orden_trabajo", {
    p_org: params.orgId,
    p_usuario: params.usuarioId,
    p_orden_id: params.ordenId,
    p_motivo: motivo,
    p_confirmo_material_entregado: Boolean(params.confirmoMaterialEntregado),
  });

  if (error) {
    throw mapearErrorRpcEquipos(error);
  }

  const ordenEnriquecida =
    (await cargarOrdenEnriquecida(serviceClient, params.orgId, params.ordenId)) ||
    data?.orden ||
    null;

  return {
    ok: true,
    ya_cancelada: Boolean(data?.ya_cancelada),
    entregas_vigentes: Number(data?.entregas_vigentes ?? 0),
    cantidad_entregada_vigente: Number(data?.cantidad_entregada_vigente ?? 0),
    orden: ordenEnriquecida,
  };
}

/**
 * Reactiva un equipo cancelado dejándolo exactamente como estaba. Solo admin o propietario.
 */
export async function reactivarOrdenTrabajoMotor(
  serviceClient: any,
  params: {
    orgId: string;
    usuarioId: string | null;
    ordenId: string;
    motivo?: string | null;
  }
) {
  await validarRolAdminOPropietario(
    serviceClient,
    params.orgId,
    params.usuarioId
  );

  const motivo = params.motivo ? String(params.motivo).trim() : null;

  const { data, error } = await serviceClient.rpc("reactivar_orden_trabajo", {
    p_org: params.orgId,
    p_usuario: params.usuarioId,
    p_orden_id: params.ordenId,
    p_motivo: motivo,
  });

  if (error) {
    throw mapearErrorRpcEquipos(error);
  }

  const ordenEnriquecida =
    (await cargarOrdenEnriquecida(serviceClient, params.orgId, params.ordenId)) ||
    data?.orden ||
    null;

  return {
    ok: true,
    ya_activa: Boolean(data?.ya_activa),
    orden: ordenEnriquecida,
  };
}

/**
 * Cambia el cliente o etiqueta de un equipo origen = 'manual'. Folio intacto. Solo admin o propietario.
 */
export async function cambiarClienteOrdenTrabajoMotor(
  serviceClient: any,
  params: {
    orgId: string;
    usuarioId: string | null;
    ordenId: string;
    clienteId?: string | null;
    etiqueta?: string | null;
    motivo?: string | null;
  }
) {
  await validarRolAdminOPropietario(
    serviceClient,
    params.orgId,
    params.usuarioId
  );

  const clienteId =
    params.clienteId && String(params.clienteId).trim()
      ? String(params.clienteId).trim()
      : null;
  const etiqueta =
    params.etiqueta && String(params.etiqueta).trim()
      ? String(params.etiqueta).trim()
      : null;
  const motivo =
    params.motivo && String(params.motivo).trim()
      ? String(params.motivo).trim()
      : null;

  if (!clienteId && !etiqueta) {
    throw new EquiposGestionError(
      400,
      "cliente_o_etiqueta_requerido",
      "Debes seleccionar un cliente del catálogo o capturar una etiqueta para el equipo."
    );
  }

  const { data, error } = await serviceClient.rpc(
    "cambiar_cliente_orden_trabajo",
    {
      p_org: params.orgId,
      p_usuario: params.usuarioId,
      p_orden_id: params.ordenId,
      p_cliente_id: clienteId,
      p_etiqueta: etiqueta,
      p_motivo: motivo,
    }
  );

  if (error) {
    throw mapearErrorRpcEquipos(error);
  }

  const ordenEnriquecida =
    (await cargarOrdenEnriquecida(serviceClient, params.orgId, params.ordenId)) ||
    data?.orden ||
    null;

  return {
    ok: true,
    sin_cambios: Boolean(data?.sin_cambios),
    orden: ordenEnriquecida,
  };
}

/**
 * Lista las órdenes de trabajo activas (por defecto) o canceladas (cuando soloCanceladas = true).
 */
export async function listarOrdenesTrabajoMotor(
  serviceClient: any,
  orgId: string,
  opciones: { soloCanceladas?: boolean } = {}
) {
  let query = serviceClient
    .from("ordenes_trabajo")
    .select(
      "*, cliente:clientes(*), cotizacion:cotizaciones(*), linea:lineas_producto(*), fase:fases_produccion(*)"
    )
    .eq("organizacion_id", orgId);

  if (opciones.soloCanceladas) {
    query = query
      .not("cancelada_el", "is", null)
      .order("cancelada_el", { ascending: false });
  } else {
    query = query
      .is("cancelada_el", null)
      .order("created_at", { ascending: false });
  }

  const { data, error } = await query;
  if (error) throw error;

  const lista = data || [];
  if (!opciones.soloCanceladas || lista.length === 0) {
    return lista;
  }

  // Enriquecer con nombre/correo legible de quien canceló (si auth.admin está disponible)
  const userIds = Array.from(
    new Set(lista.map((o: any) => o.cancelada_por).filter(Boolean))
  ) as string[];
  const mapaUsuarios = new Map<string, string>();

  if (userIds.length > 0 && serviceClient?.auth?.admin?.getUserById) {
    await Promise.all(
      userIds.map(async (uid) => {
        try {
          const { data: uData } = await serviceClient.auth.admin.getUserById(uid);
          const u = uData?.user;
          const etiqueta =
            u?.user_metadata?.nombre ||
            u?.user_metadata?.full_name ||
            u?.email ||
            uid;
          mapaUsuarios.set(uid, etiqueta);
        } catch {
          mapaUsuarios.set(uid, uid);
        }
      })
    );
  }

  return lista.map((o: any) => ({
    ...o,
    cancelada_por_nombre: o.cancelada_por
      ? mapaUsuarios.get(o.cancelada_por) || o.cancelada_por
      : null,
  }));
}

/**
 * Lista la bitácora orden_cambios para una orden de trabajo.
 */
export async function listarCambiosOrdenMotor(
  supabase: any,
  orgId: string,
  ordenId: string
) {
  const { data, error } = await supabase
    .from("orden_cambios")
    .select("*")
    .eq("organizacion_id", orgId)
    .eq("orden_trabajo_id", ordenId)
    .order("creado_el", { ascending: false });

  if (error) throw error;
  return data || [];
}
