import type { SupabaseClient } from "npm:@supabase/supabase-js";

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const ESTADOS_VALIDOS = new Set(["Pendiente", "Recibida", "Cancelada"]);
const CAMPOS_EDITABLES_COMPRA = new Set([
  "estado",
  "proveedor_id",
  "cotizacion_id",
  "fecha",
  "fecha_vencimiento_pago",
]);

export class ComprasRecepcionError extends Error {
  status: number;
  codigo: string;

  constructor(status: number, codigo: string, message: string) {
    super(message);
    this.status = status;
    this.codigo = codigo;
  }
}

export function mapearErrorRpcCompra(err: unknown): ComprasRecepcionError {
  if (err instanceof ComprasRecepcionError) return err;
  const code = String((err as { code?: string })?.code || "");
  const msg = String((err as { message?: string })?.message || err || "");

  if (msg.includes("compra_no_encontrada")) {
    return new ComprasRecepcionError(404, "compra_no_encontrada", "La compra no existe o pertenece a otra organización.");
  }
  if (msg.includes("compra_cancelada")) {
    return new ComprasRecepcionError(409, "compra_cancelada", "No se puede recibir una compra que ya está cancelada.");
  }
  if (msg.includes("compra_sin_partidas")) {
    return new ComprasRecepcionError(409, "compra_sin_partidas", "La compra no tiene partidas para recibir.");
  }
  if (msg.includes("producto_no_encontrado")) {
    return new ComprasRecepcionError(
      409,
      "producto_no_encontrado",
      "Uno de los productos de la compra no existe o pertenece a otra organización.",
    );
  }
  if (msg.includes("cantidad_no_entera")) {
    return new ComprasRecepcionError(
      400,
      "cantidad_no_entera",
      "La compra contiene cantidades fraccionarias y el inventario actual solo acepta números enteros.",
    );
  }
  if (msg.includes("cantidad_invalida")) {
    return new ComprasRecepcionError(400, "cantidad_invalida", "Todas las partidas deben tener una cantidad mayor a cero.");
  }
  if (msg.includes("org_requerida") || code === "22P02") {
    return new ComprasRecepcionError(400, "parametro_invalido", "Los datos enviados para la compra no son válidos.");
  }
  if (
    code === "40P01" ||
    code === "40001" ||
    msg.includes("deadlock_detected") ||
    msg.includes("serialization_failure")
  ) {
    return new ComprasRecepcionError(
      409,
      "conflicto_concurrencia",
      "Hubo un conflicto simultáneo al actualizar el inventario; inténtalo de nuevo.",
    );
  }
  if (code === "42883" || code === "PGRST202" || msg.includes("Could not find the function")) {
    return new ComprasRecepcionError(
      503,
      "rpc_no_disponible",
      "La función de recepción de compras aún no está instalada en la base de datos.",
    );
  }
  return new ComprasRecepcionError(500, "error_interno", "No se pudo completar la recepción de la compra.");
}

export function sanitizarCamposCompraUpdate(payload: Record<string, unknown>): Record<string, unknown> {
  const out: Record<string, unknown> = {};
  if (!payload || typeof payload !== "object") return out;
  for (const [k, v] of Object.entries(payload)) {
    if (CAMPOS_EDITABLES_COMPRA.has(k) && v !== undefined) {
      out[k] = v;
    }
  }
  return out;
}

export function validarTransicionEstadoCompra(estadoPrevio: string, estadoNuevo?: unknown): void {
  if (estadoNuevo === undefined || estadoNuevo === null) return;
  const nuevo = String(estadoNuevo);
  if (!ESTADOS_VALIDOS.has(nuevo)) {
    throw new ComprasRecepcionError(400, "estado_invalido", `Estado de compra no válido: ${nuevo}.`);
  }
  if (nuevo === estadoPrevio) return;

  if (estadoPrevio === "Recibida") {
    throw new ComprasRecepcionError(
      409,
      "transicion_invalida",
      "Una compra ya recibida no puede cambiar a Pendiente ni Cancelada porque dejaría el inventario inconsistente.",
    );
  }
  if (estadoPrevio === "Cancelada") {
    throw new ComprasRecepcionError(
      409,
      "transicion_invalida",
      "No se puede cambiar el estado de una compra cancelada.",
    );
  }
}

export interface PartidaCompraInput {
  material_id: string;
  cantidad: number;
  costo_unitario: number;
}

export function validarPartidasCompraNueva(items: unknown): PartidaCompraInput[] {
  if (items === undefined || items === null) return [];
  if (!Array.isArray(items)) {
    throw new ComprasRecepcionError(400, "partidas_invalidas", "Las partidas de la compra deben ser una lista.");
  }
  return items.map((raw: unknown, idx: number) => {
    const it = raw as Record<string, unknown>;
    const materialId = String(it?.material_id || "").trim();
    const cantidad = Number(it?.cantidad);
    const costo = Number(it?.costo_unitario);
    if (!materialId) {
      throw new ComprasRecepcionError(400, "producto_requerido", `La partida #${idx + 1} no tiene producto asignado.`);
    }
    if (!Number.isFinite(cantidad) || cantidad <= 0) {
      throw new ComprasRecepcionError(400, "cantidad_invalida", `La cantidad de la partida #${idx + 1} debe ser mayor a cero.`);
    }
    if (!Number.isFinite(costo) || costo < 0) {
      throw new ComprasRecepcionError(400, "costo_invalido", `El costo unitario de la partida #${idx + 1} no puede ser negativo.`);
    }
    return { material_id: materialId, cantidad, costo_unitario: costo };
  });
}

export async function crearCompraProveedorMotor(
  supabase: SupabaseClient,
  orgId: string,
  userId: string | null,
  payload: Record<string, unknown>,
  registrarEventoFn?: (
    sb: SupabaseClient,
    ev: { cotizacion_id: string; organizacion_id: string; evento: string; usuario_id: string | null },
  ) => Promise<void>,
) {
  const partidas = validarPartidasCompraNueva(payload?.items);

  // Verificar que todos los productos de las partidas existan y pertenezcan a la organización
  if (partidas.length > 0) {
    const prodIds = Array.from(new Set(partidas.map((p) => p.material_id)));
    const { data: prods, error: errProds } = await supabase
      .from("productos")
      .select("id")
      .eq("organizacion_id", orgId)
      .in("id", prodIds);
    if (errProds) {
      throw new ComprasRecepcionError(500, "error_consulta_productos", "No se pudieron validar los productos de la compra.");
    }
    const encontrados = new Set((prods || []).map((p: Record<string, unknown>) => String(p.id)));
    const faltante = prodIds.find((id) => !encontrados.has(id));
    if (faltante) {
      throw new ComprasRecepcionError(
        400,
        "producto_no_encontrado",
        `El producto "${faltante}" no existe o pertenece a otra organización.`,
      );
    }
  }

  // Lista blanca para creación (siempre arranca en Pendiente)
  const campos = sanitizarCamposCompraUpdate(payload);
  const compraData: Record<string, unknown> = {
    proveedor_id: campos.proveedor_id ?? null,
    cotizacion_id: campos.cotizacion_id ?? null,
    fecha: campos.fecha ?? undefined,
    fecha_vencimiento_pago: campos.fecha_vencimiento_pago ?? null,
    estado: "Pendiente",
    organizacion_id: orgId,
  };
  if (compraData.fecha === undefined) delete compraData.fecha;

  // Generar folio MAX+1
  const { data: maxFolio } = await supabase
    .from("compras_proveedor")
    .select("folio")
    .eq("organizacion_id", orgId)
    .order("created_at", { ascending: false })
    .limit(1);

  let nextNum = 1;
  if (maxFolio && maxFolio.length > 0 && maxFolio[0].folio) {
    const match = String(maxFolio[0].folio).match(/\d+$/);
    if (match) nextNum = parseInt(match[0], 10) + 1;
  }
  compraData.folio = `OC-${String(nextNum).padStart(5, "0")}`;

  // 1. Insertar compra principal
  const { data: compra, error: compraError } = await supabase
    .from("compras_proveedor")
    .insert(compraData)
    .select()
    .single();

  if (compraError || !compra) {
    throw new ComprasRecepcionError(500, "error_crear_compra", "No se pudo crear la orden de compra.");
  }

  // 2. Insertar partidas revisando error; si falla, eliminar la compra recién creada (sin compras fantasma)
  if (partidas.length > 0) {
    const itemsToInsert = partidas.map((item) => ({
      material_id: item.material_id,
      cantidad: item.cantidad,
      costo_unitario: item.costo_unitario,
      compra_id: compra.id,
    }));
    const { error: itemsError } = await supabase.from("compra_items").insert(itemsToInsert);
    if (itemsError) {
      await supabase
        .from("compras_proveedor")
        .delete()
        .eq("id", compra.id)
        .eq("organizacion_id", orgId);
      throw new ComprasRecepcionError(
        400,
        "error_crear_partidas",
        "No se pudieron guardar las partidas de la compra; la compra no fue creada.",
      );
    }
  }

  // 3. Actualizar estado de producción si está ligada a cotización
  if (compraData.cotizacion_id) {
    await supabase
      .from("cotizaciones")
      .update({ estado_produccion: "Compra en curso" })
      .eq("id", compraData.cotizacion_id)
      .eq("organizacion_id", orgId);
    if (registrarEventoFn) {
      await registrarEventoFn(supabase, {
        cotizacion_id: String(compraData.cotizacion_id),
        organizacion_id: orgId,
        evento: `Compra generada (${compraData.folio}). Estado de producción: Compra en curso`,
        usuario_id: userId,
      });
    }
  }

  return compra;
}

export interface HooksPostRecepcion {
  calcularRequisicion?: (
    sb: SupabaseClient,
    cotizacionId: string,
    orgId: string,
  ) => Promise<Array<{ estado?: string; faltante?: number }>>;
  registrarEvento?: (
    sb: SupabaseClient,
    ev: { cotizacion_id: string; organizacion_id: string; evento: string; usuario_id: string | null },
  ) => Promise<void>;
}

export async function actualizarCompraProveedorMotor(
  supabase: SupabaseClient,
  serviceClient: SupabaseClient,
  orgId: string,
  userId: string | null,
  compraId: string,
  payload: Record<string, unknown>,
  hooks: HooksPostRecepcion = {},
) {
  if (!UUID_RE.test(String(compraId || ""))) {
    throw new ComprasRecepcionError(400, "uuid_invalido", "El identificador de la compra no es válido.");
  }

  // Lectura previa filtrando explícitamente por organizacion_id
  const { data: prevCompra, error: errPrev } = await supabase
    .from("compras_proveedor")
    .select("*")
    .eq("id", compraId)
    .eq("organizacion_id", orgId)
    .maybeSingle();

  if (errPrev) {
    throw new ComprasRecepcionError(500, "error_lectura_compra", "No se pudo consultar la compra.");
  }
  if (!prevCompra) {
    throw new ComprasRecepcionError(404, "compra_no_encontrada", "La compra no existe o pertenece a otra organización.");
  }

  const campos = sanitizarCamposCompraUpdate(payload);
  validarTransicionEstadoCompra(String(prevCompra.estado), campos.estado);

  const esRecepcion = campos.estado === "Recibida";
  const { estado: _est, ...otrosCampos } = campos;

  // Actualizar campos no-estado si vienen en la lista blanca
  let compraActual = prevCompra;
  if (Object.keys(otrosCampos).length > 0 || (!esRecepcion && campos.estado !== undefined)) {
    const updateData = esRecepcion ? otrosCampos : campos;
    if (Object.keys(updateData).length > 0) {
      const { data: updated, error: errUpd } = await supabase
        .from("compras_proveedor")
        .update(updateData)
        .eq("id", compraId)
        .eq("organizacion_id", orgId)
        .select()
        .single();
      if (errUpd || !updated) {
        throw new ComprasRecepcionError(500, "error_actualizar_compra", "No se pudo actualizar la compra.");
      }
      compraActual = updated;
    }
  }

  if (!esRecepcion) {
    return compraActual;
  }

  // Recepción atómica vía RPC con service_role (revisando error obligatoriamente)
  const { data: rpcRes, error: rpcErr } = await serviceClient.rpc("recibir_compra_proveedor", {
    p_org: orgId,
    p_usuario: userId,
    p_compra_id: compraId,
  });

  if (rpcErr) {
    throw mapearErrorRpcCompra(rpcErr);
  }

  // Leer la compra ya actualizada desde BD
  const { data: compraRecibida } = await supabase
    .from("compras_proveedor")
    .select("*")
    .eq("id", compraId)
    .eq("organizacion_id", orgId)
    .maybeSingle();

  const respuesta: Record<string, unknown> = {
    ...(compraRecibida || { ...compraActual, estado: "Recibida" }),
    recepcion: rpcRes || null,
  };

  // Recalcular requisición si aplica; si falla, NO lanzar 500 sobre una recepción ya exitosa
  const yaRecibida = Boolean((rpcRes as Record<string, unknown> | null)?.ya_recibida);
  const cotizacionId = compraActual.cotizacion_id ? String(compraActual.cotizacion_id) : null;
  if (!yaRecibida && cotizacionId && hooks.calcularRequisicion) {
    try {
      const faltantes = await hooks.calcularRequisicion(supabase, cotizacionId, orgId);
      const unconfigured = faltantes.some((f) => f.estado === "sin_receta");
      if (!unconfigured) {
        const totalFaltante = faltantes.reduce((sum, f) => sum + (f.faltante || 0), 0);
        if (totalFaltante === 0) {
          const { data: cot } = await supabase
            .from("cotizaciones")
            .select("estado_produccion")
            .eq("id", cotizacionId)
            .eq("organizacion_id", orgId)
            .maybeSingle();
          if (
            cot &&
            (cot.estado_produccion === "Requisición: falta material" || cot.estado_produccion === "Compra en curso")
          ) {
            await supabase
              .from("cotizaciones")
              .update({ estado_produccion: "Listo para producción" })
              .eq("id", cotizacionId)
              .eq("organizacion_id", orgId);
            if (hooks.registrarEvento) {
              await hooks.registrarEvento(supabase, {
                cotizacion_id: cotizacionId,
                organizacion_id: orgId,
                evento: `Compra ${respuesta.folio || compraId} recibida. No hay faltantes. Estado: Listo para producción`,
                usuario_id: userId,
              });
            }
          }
        }
      }
    } catch (reqErr: unknown) {
      const motivo = reqErr instanceof Error ? reqErr.message : String(reqErr);
      console.error("[compras-recepcion] Error recalculando requisición tras recibir compra:", motivo);
      respuesta.aviso = `La compra se recibió en inventario, pero no se pudo recalcular la requisición de producción (${motivo}).`;
    }
  }

  return respuesta;
}
