/**
 * Motor de Cuentas y Permisos:
 * - Validación de rol real (admin / propietario) en perfiles_organizacion
 * - Invitaciones: solo admin/propietario; nunca rol 'propietario' desde esta vía
 * - Rutas de organizaciones (Super-Admin): exige organización principal + rol admin/propietario
 * - Listado de equipo de la organización desde service_role (sin abrir po_select) con
 *   paginación completa de auth.admin.listUsers (de 50 en 50) para no perder correos.
 */

export class CuentasPermisosError extends Error {
  status: number;
  codigo: string;

  constructor(status: number, codigo: string, message: string) {
    super(message);
    this.name = "CuentasPermisosError";
    this.status = status;
    this.codigo = codigo;
  }
}

export const ROLES_ADMINISTRADORES = new Set(["admin", "propietario"]);
export const ROLES_INVITACION_PERMITIDOS = new Set(["admin", "usuario"]);

/**
 * Consulta perfiles_organizacion y exige rol admin o propietario para la organización dada.
 */
export async function exigirAdminOPropietario(
  serviceClient: any,
  orgId: string,
  usuarioId?: string | null,
  mensajePersonalizado?: string
): Promise<string> {
  if (!orgId || !usuarioId) {
    throw new CuentasPermisosError(
      403,
      "sin_permiso",
      mensajePersonalizado ||
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
    throw new CuentasPermisosError(
      403,
      "sin_permiso",
      mensajePersonalizado ||
        "No tienes permisos suficientes en esta organización."
    );
  }

  const rol = String(data.rol || "").trim().toLowerCase();
  if (!ROLES_ADMINISTRADORES.has(rol)) {
    throw new CuentasPermisosError(
      403,
      "sin_permiso",
      mensajePersonalizado ||
        "Solo administradores o propietarios pueden realizar esta acción."
    );
  }

  return rol;
}

/**
 * Exige pertenecer a la organización principal Y tener rol admin o propietario en ella.
 */
export async function exigirSuperAdminOrgPrincipal(
  serviceClient: any,
  params: {
    orgId: string;
    usuarioId?: string | null;
    orgPrincipalId: string;
  }
): Promise<string> {
  if (!params.orgId || params.orgId !== params.orgPrincipalId) {
    throw new CuentasPermisosError(
      403,
      "solo_org_principal",
      "No autorizado. Solo la Organización Principal puede administrar organizaciones."
    );
  }

  return await exigirAdminOPropietario(
    serviceClient,
    params.orgId,
    params.usuarioId,
    "No autorizado. Solo administradores o propietarios de la Organización Principal pueden realizar esta acción."
  );
}

/**
 * Crea una invitación de equipo validando rol admin/propietario y prohibiendo rol 'propietario'.
 */
export async function crearInvitacionSegura(
  serviceClient: any,
  params: {
    orgId: string;
    usuarioId?: string | null;
    email?: string | null;
    rol?: string | null;
  }
) {
  await exigirAdminOPropietario(
    serviceClient,
    params.orgId,
    params.usuarioId,
    "Solo administradores o propietarios pueden invitar miembros al equipo."
  );

  const emailNorm = String(params.email || "").trim().toLowerCase();
  const rolNorm = String(params.rol || "").trim().toLowerCase();

  if (!emailNorm || !rolNorm) {
    throw new CuentasPermisosError(
      400,
      "datos_requeridos",
      "Email y rol son requeridos."
    );
  }

  if (rolNorm === "propietario") {
    throw new CuentasPermisosError(
      403,
      "rol_propietario_prohibido",
      "No se puede invitar con rol propietario desde esta vía."
    );
  }

  if (!ROLES_INVITACION_PERMITIDOS.has(rolNorm)) {
    throw new CuentasPermisosError(
      400,
      "rol_invalido",
      "Rol inválido. Solo se permite invitar como 'admin' o 'usuario'."
    );
  }

  const { data, error } = await serviceClient
    .from("invitaciones_equipo")
    .insert({
      organizacion_id: params.orgId,
      email: emailNorm,
      rol: rolNorm,
      invitado_por: params.usuarioId || null,
    })
    .select()
    .single();

  if (error) {
    if (error.code === "23505") {
      throw new CuentasPermisosError(
        409,
        "invitacion_duplicada",
        "Ya existe una invitación pendiente para ese correo."
      );
    }
    throw error;
  }

  return data;
}

/**
 * Elimina una invitación de equipo validando rol admin/propietario y aislamiento por organización.
 */
export async function eliminarInvitacionSegura(
  serviceClient: any,
  params: {
    orgId: string;
    usuarioId?: string | null;
    invitacionId: string;
  }
) {
  await exigirAdminOPropietario(
    serviceClient,
    params.orgId,
    params.usuarioId,
    "Solo administradores o propietarios pueden eliminar invitaciones."
  );

  if (!params.invitacionId) {
    throw new CuentasPermisosError(400, "id_requerido", "ID de invitación requerido.");
  }

  const { error } = await serviceClient
    .from("invitaciones_equipo")
    .delete()
    .eq("id", params.invitacionId)
    .eq("organizacion_id", params.orgId);

  if (error) throw error;
  return { success: true };
}

/**
 * Recorre todas las páginas de auth.admin.listUsers() (de 50 en 50) para mapear id -> email
 * sin perder correos cuando existen más de 50 usuarios en el proyecto.
 */
export async function mapearCorreosUsuariosAuth(
  serviceClient: any,
  perPage = 50
): Promise<Map<string, string>> {
  const mapa = new Map<string, string>();
  if (!serviceClient?.auth?.admin?.listUsers) return mapa;

  let page = 1;
  const maxPages = 200; // Cota de seguridad ante posibles loops infinitos

  while (page <= maxPages) {
    const { data, error } = await serviceClient.auth.admin.listUsers({
      page,
      perPage,
    });
    if (error) throw error;

    const users: any[] = data?.users || [];
    for (const u of users) {
      if (u?.id && u?.email) {
        mapa.set(u.id, u.email);
      }
    }

    if (users.length < perPage) {
      break;
    }
    page += 1;
  }

  return mapa;
}

/**
 * Lista todos los miembros de la organización del token usando service_role
 * (sin abrir la política po_select en perfiles_organizacion) y mapeando correos paginados.
 */
export async function listarEquipoOrganizacion(
  serviceClient: any,
  orgId: string
) {
  if (!orgId) {
    throw new CuentasPermisosError(403, "sin_organizacion", "Organización no identificada.");
  }

  const { data: perfiles, error } = await serviceClient
    .from("perfiles_organizacion")
    .select("*")
    .eq("organizacion_id", orgId);

  if (error) throw error;

  const lista = perfiles || [];
  if (lista.length === 0) return [];

  const correos = await mapearCorreosUsuariosAuth(serviceClient, 50);

  return lista.map((p: any) => ({
    ...p,
    email: correos.get(p.usuario_id) || "Usuario Desconocido",
  }));
}

/**
 * Elimina un cliente solo si no tiene equipos (ordenes_trabajo, incluyendo cancelados).
 * Si tiene equipos asociados o Postgres devuelve 23503, lanza CuentasPermisosError(409).
 */
export async function eliminarClienteSeguro(
  supabaseClient: any,
  params: {
    orgId: string;
    clienteId: string;
  }
) {
  if (!params.orgId || !params.clienteId) {
    throw new CuentasPermisosError(400, "datos_requeridos", "ID de cliente requerido.");
  }

  const { count, error: countError } = await supabaseClient
    .from("ordenes_trabajo")
    .select("id", { count: "exact", head: true })
    .eq("organizacion_id", params.orgId)
    .eq("cliente_id", params.clienteId);

  if (countError) throw countError;

  const totalEquipos = Number(count || 0);
  if (totalEquipos > 0) {
    throw new CuentasPermisosError(
      409,
      "cliente_con_equipos",
      `No se puede eliminar este cliente porque tiene ${totalEquipos} ${
        totalEquipos === 1 ? "equipo asociado" : "equipos asociados"
      } (incluyendo cancelados).`
    );
  }

  const { error } = await supabaseClient
    .from("clientes")
    .delete()
    .eq("id", params.clienteId)
    .eq("organizacion_id", params.orgId);

  if (error) {
    if (error.code === "23503") {
      throw new CuentasPermisosError(
        409,
        "cliente_con_registros_asociados",
        "No se puede eliminar este cliente porque tiene equipos o registros asociados."
      );
    }
    throw error;
  }

  return { success: true };
}
