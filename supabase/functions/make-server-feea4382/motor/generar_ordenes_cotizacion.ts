import { cargarDatosModelo } from "./cargar_datos.ts";
import { construirFichaOrdenTrabajo } from "./ficha_orden_trabajo.ts";
import { desenvolverMetadata } from "./item_metadata.ts";

export interface ParametrosGenerarOrdenes {
  cotizacionId: string;
  orgId: string;
  usuarioId?: string | null;
  force?: boolean;
}

export interface ResultadoGenerarOrdenes {
  ordenes: any[];
  creadas: number;
  ya_existian: boolean;
  advertenciaKeywords?: boolean;
}

async function registrarEventoHelper(
  supabase: any,
  evento: {
    cotizacion_id: string;
    organizacion_id: string;
    evento: string;
    usuario_id: string | null;
  }
) {
  const { error } = await supabase.from("cotizacion_eventos").insert([evento]);
  if (error) console.error("Error registrando evento cotización:", error);
}

export function esItemEquipo(item: any, productosTerminados: Set<string>): boolean {
  if (item.configuracion?.modelo_id) return true;
  if (item.producto_id && productosTerminados.has(item.producto_id)) return true;
  const desc = (item.descripcion || "").toLowerCase();
  const keywords = [
    "dolly",
    "gondola",
    "gándola",
    "góndola",
    "jaula",
    "cama baja",
    "multimodal",
    "porta",
    "seca",
    "traila",
    "plataforma",
    "plana",
    "remolque",
  ];
  return keywords.some((k) => desc.includes(k));
}

export function clasificarTipoEquipo(desc: string): string {
  const d = (desc || "").toLowerCase();
  if (d.includes("dolly")) return "02";
  if (d.includes("gondola") || d.includes("gándola") || d.includes("góndola")) return "03";
  if (d.includes("jaula")) return "04";
  if (d.includes("cama baja")) return "05";
  if (d.includes("multimodal")) return "06";
  if (d.includes("porta")) return "07";
  if (d.includes("seca")) return "08";
  if (d.includes("traila")) return "09";
  return "01";
}

export async function generarOrdenesDeCotizacion(
  supabase: any,
  params: ParametrosGenerarOrdenes
): Promise<ResultadoGenerarOrdenes> {
  const { cotizacionId, orgId, usuarioId } = params;

  // 1. Cargar cotización con cliente e items
  const { data: cotizacion, error: cotError } = await supabase
    .from("cotizaciones")
    .select("*, cliente:clientes(*), items:items_cotizacion(*)")
    .eq("id", cotizacionId)
    .eq("organizacion_id", orgId)
    .single();

  if (cotError || !cotizacion) {
    throw new Error("Cotización no encontrada");
  }

  // 2. Exigir estado 'Aprobada'
  if (cotizacion.estado !== "Aprobada") {
    throw new Error("Aprueba la cotización para generar la orden de trabajo");
  }

  // 3. Idempotencia: si ya existen órdenes, devolverlas
  const { data: existing } = await supabase
    .from("ordenes_trabajo")
    .select("*, cliente:clientes(*), cotizacion:cotizaciones(*), linea:lineas_producto(*), fase:fases_produccion(*)")
    .eq("cotizacion_id", cotizacionId)
    .eq("organizacion_id", orgId);

  if (existing && existing.length > 0) {
    return {
      ordenes: existing,
      creadas: 0,
      ya_existian: true,
    };
  }

  // 4. Mapeo de productos terminados
  const rawItems = cotizacion.items || [];
  const productIds = rawItems.map((i: any) => i.producto_id).filter(Boolean);
  const productosTerminados = new Set<string>();

  if (productIds.length > 0) {
    const { data: prods } = await supabase
      .from("productos")
      .select("id, tipo_item")
      .in("id", productIds);
    if (prods) {
      prods
        .filter((p: any) => p.tipo_item === "producto_terminado")
        .forEach((p: any) => productosTerminados.add(p.id));
    }
  }

  // 5. Configurar línea y fase inicial de kanban
  const { data: lineas } = await supabase
    .from("lineas_producto")
    .select("id, nombre, prefijo")
    .eq("organizacion_id", orgId);
  const defaultLinea = lineas && lineas.length > 0 ? lineas[0] : null;
  let defaultFaseId = null;
  if (defaultLinea) {
    const { data: fases } = await supabase
      .from("fases_produccion")
      .select("id")
      .eq("linea_id", defaultLinea.id)
      .order("orden")
      .limit(1);
    if (fases && fases.length > 0) defaultFaseId = fases[0].id;
  }

  // 6. Iniciales del cliente para nomenclatura
  let iniciales = "CLI";
  const cli = cotizacion.cliente;
  if (cli) {
    if (cli.tipo === "Empresa" || cli.empresa) {
      const nomEmp = cli.empresa || cli.nombre_razon_social || cli.nombre || "";
      iniciales = nomEmp.substring(0, 3).toUpperCase() || "CLI";
    } else {
      const nom = cli.nombre_razon_social || cli.nombre || "";
      iniciales =
        nom
          .split(" ")
          .filter(Boolean)
          .slice(0, 3)
          .map((p: string) => p[0])
          .join("")
          .toUpperCase() || "CLI";
    }
  }

  const mesStr = (new Date().getMonth() + 1).toString().padStart(2, "0");
  const anio = new Date().getFullYear().toString().slice(-2);

  let advertenciaKeywords = false;
  const ordenesToInsert: any[] = [];
  let trailerCounter = 1;

  for (const rawItem of rawItems) {
    const item = rawItem.configuracion ? rawItem : desenvolverMetadata(rawItem);
    let isEquipo = false;
    let tipoEquipo = "01";
    const lineaId = defaultLinea?.id || null;
    const faseId = defaultFaseId;

    if (item.producto_id && productosTerminados.has(item.producto_id)) {
      isEquipo = true;
    } else if (!item.producto_id) {
      // Fallback keyword check
      const desc = (item.descripcion || "").toLowerCase();
      if (desc.includes("dolly")) tipoEquipo = "02";
      else if (desc.includes("gondola") || desc.includes("gándola") || desc.includes("góndola")) tipoEquipo = "03";
      else if (desc.includes("jaula")) tipoEquipo = "04";
      else if (desc.includes("cama baja")) tipoEquipo = "05";
      else if (desc.includes("multimodal")) tipoEquipo = "06";
      else if (desc.includes("porta")) tipoEquipo = "07";
      else if (desc.includes("seca")) tipoEquipo = "08";
      else if (desc.includes("traila")) tipoEquipo = "09";
      else continue;

      isEquipo = true;
      advertenciaKeywords = true;
    }

    if (!isEquipo) continue;

    // Cargar DatosModelo si existe modelo_id o producto_id
    const cfg = item.configuracion || {};
    const modeloId = cfg.modelo_id || item.producto_id;
    let datosModelo: any = null;
    if (modeloId) {
      try {
        datosModelo = await cargarDatosModelo(supabase, modeloId);
      } catch (_e) {
        // Fallback si no se puede cargar DatosModelo
      }
    }

    if (datosModelo?.modelo?.tipo) {
      const t = datosModelo.modelo.tipo.toLowerCase();
      if (t === "dolly") tipoEquipo = "02";
      else if (t === "gondola" || t === "góndola") tipoEquipo = "03";
      else if (t === "jaula") tipoEquipo = "04";
      else if (t === "cama_baja" || t === "cama baja") tipoEquipo = "05";
      else if (t === "multimodal") tipoEquipo = "06";
      else if (t === "portacontenedor" || t === "porta") tipoEquipo = "07";
      else if (t === "caja_seca" || t === "seca") tipoEquipo = "08";
    }

    const ficha = construirFichaOrdenTrabajo({
      item,
      cotizacion,
      cliente: cotizacion.cliente,
      datosModelo,
    });

    const cantidad = Math.max(1, Math.round(Number(item.cantidad) || 1));

    for (let i = 0; i < cantidad; i++) {
      const { data: numResult, error: seqError } = await supabase.rpc(
        "obtener_siguiente_produccion"
      );
      if (seqError) {
        throw new Error(
          "Fallo al obtener secuencia de producción: " + seqError.message
        );
      }

      const nomenclatura = `${numResult}-${iniciales}${tipoEquipo}${mesStr}${anio}-${trailerCounter}`;

      ordenesToInsert.push({
        organizacion_id: orgId,
        cotizacion_id: cotizacionId,
        cliente_id: cotizacion.cliente_id,
        nomenclatura_id: nomenclatura,
        tipo_equipo: tipoEquipo,
        caracteristicas: {
          ...(item.configuracion || {}),
          item_id: item.id || rawItem.id,
          unidad: i + 1,
          descripcion_corta: item.descripcion,
          ficha,
        },
        estado: "Pendiente",
        linea_producto_id: lineaId,
        fase_actual_id: faseId,
        estado_kanban: "pendiente",
      });

      trailerCounter++;
    }
  }

  if (ordenesToInsert.length === 0) {
    throw new Error(
      "No se encontraron equipos (productos terminados) en la cotización."
    );
  }

  const { data: ordenes, error: insError } = await supabase
    .from("ordenes_trabajo")
    .insert(ordenesToInsert)
    .select();

  if (insError) throw insError;

  await supabase
    .from("cotizaciones")
    .update({ estado_produccion: "En producción" })
    .eq("id", cotizacionId);

  await registrarEventoHelper(supabase, {
    cotizacion_id: cotizacionId,
    organizacion_id: orgId,
    evento: `Órdenes de producción generadas (${ordenesToInsert.length} unidades). Estado: En producción`,
    usuario_id: usuarioId || null,
  });

  return {
    ordenes: ordenes || [],
    creadas: (ordenes || []).length,
    ya_existian: false,
    advertenciaKeywords,
  };
}

export const CAMPOS_PERMITIDOS_ORDEN_TRABAJO = [
  "niv",
  "modelo",
  "estado",
  "fecha_inicio",
  "fecha_fin",
  "caracteristicas",
  "estado_kanban",
  "fase_actual_id",
  "material_faltante",
] as const;

export function sanitizarPayloadOrdenTrabajo(
  rawPayload: Record<string, any>
): Record<string, any> {
  const limpio: Record<string, any> = {};
  for (const campo of CAMPOS_PERMITIDOS_ORDEN_TRABAJO) {
    if (campo in rawPayload && rawPayload[campo] !== undefined) {
      limpio[campo] = rawPayload[campo];
    }
  }
  return limpio;
}

export async function actualizarOrdenTrabajoSegura(
  supabase: any,
  params: {
    id: string;
    orgId: string;
    rawPayload: Record<string, any>;
  }
) {
  const { id, orgId, rawPayload } = params;
  const payload = sanitizarPayloadOrdenTrabajo(rawPayload);

  // Si el payload incluye caracteristicas, fusionar en vez de sobreescribir
  if (payload.caracteristicas) {
    const { data: actual } = await supabase
      .from("ordenes_trabajo")
      .select("caracteristicas")
      .eq("id", id)
      .eq("organizacion_id", orgId)
      .single();

    if (actual && actual.caracteristicas) {
      const carActuales = actual.caracteristicas || {};
      const carNuevas = payload.caracteristicas || {};
      const fichaActual = carActuales.ficha || {};
      const fichaNueva = carNuevas.ficha || {};

      payload.caracteristicas = {
        ...carActuales,
        ...carNuevas,
        ...(fichaNueva || fichaActual
          ? {
              ficha: {
                ...fichaActual,
                ...fichaNueva,
                cabecera: {
                  ...(fichaActual.cabecera || {}),
                  ...(fichaNueva.cabecera || {})
                },
                caracteristicas:
                  fichaNueva.caracteristicas || fichaActual.caracteristicas,
                accesorios_extra:
                  fichaNueva.accesorios_extra || fichaActual.accesorios_extra,
                nota:
                  fichaNueva.nota !== undefined
                    ? fichaNueva.nota
                    : fichaActual.nota
              }
            }
          : {})
      };
    }
  }

  const { data, error } = await supabase
    .from("ordenes_trabajo")
    .update(payload)
    .eq("id", id)
    .eq("organizacion_id", orgId)
    .select()
    .single();

  if (error) throw error;
  if (!data) {
    const err = new Error("Orden de trabajo no encontrada");
    (err as any).status = 404;
    throw err;
  }
  return data;
}

export async function regenerarFichaDeOrden(
  supabase: any,
  params: {
    id: string;
    orgId: string;
  }
) {
  const { id, orgId } = params;

  const { data: orden, error: errOrd } = await supabase
    .from("ordenes_trabajo")
    .select("*, cliente:clientes(*), cotizacion:cotizaciones(*, items:items_cotizacion(*))")
    .eq("id", id)
    .eq("organizacion_id", orgId)
    .single();

  if (errOrd || !orden) {
    const err = new Error("Orden de trabajo no encontrada");
    (err as any).status = 404;
    throw err;
  }

  const items = orden.cotizacion?.items || [];
  if (items.length === 0) {
    const err = new Error("La cotización no contiene conceptos");
    (err as any).status = 400;
    throw err;
  }

  // Buscar concepto correspondiente:
  let itemEncontrado: any = null;

  // 1. Si la orden tiene item_id guardado en caracteristicas
  const itemIdGuardado = orden.caracteristicas?.item_id;
  if (itemIdGuardado) {
    itemEncontrado = items.find((it: any) => it.id === itemIdGuardado);
  }

  // 2. Si no tiene item_id (orden vieja) o no se encontró por item_id:
  if (!itemEncontrado) {
    // Buscar productos terminados para identificar equipos
    const productIds = items.map((i: any) => i.producto_id).filter(Boolean);
    const productosTerminados = new Set<string>();
    if (productIds.length > 0) {
      const { data: prods } = await supabase
        .from("productos")
        .select("id, tipo_item")
        .in("id", productIds);
      if (prods) {
        prods
          .filter((p: any) => p.tipo_item === "producto_terminado")
          .forEach((p: any) => productosTerminados.add(p.id));
      }
    }

    const equipos = items.filter((it: any) => esItemEquipo(it, productosTerminados));

    if (equipos.length === 1) {
      // Si la cotización tiene un solo equipo, úsalo
      itemEncontrado = equipos[0];
    } else {
      // Si tiene varios y no se puede determinar con certeza, responde 409
      const err = new Error(
        "No se puede determinar el concepto de esta orden; regenérala desde la cotización"
      );
      (err as any).status = 409;
      throw err;
    }
  }

  const itemUnwrapped = itemEncontrado.configuracion
    ? itemEncontrado
    : desenvolverMetadata(itemEncontrado);
  const modeloId =
    itemUnwrapped.configuracion?.modelo_id || itemEncontrado.producto_id;
  let datosModelo: any = null;
  if (modeloId) {
    try {
      datosModelo = await cargarDatosModelo(supabase, modeloId);
    } catch (_e) {
      // Fallback si no hay modelo en catálogo
    }
  }

  const ficha = construirFichaOrdenTrabajo({
    item: itemUnwrapped,
    cotizacion: orden.cotizacion,
    cliente: orden.cliente || orden.cotizacion?.cliente,
    datosModelo
  });

  const nuevasCaracteristicas = {
    ...(orden.caracteristicas || {}),
    item_id: itemEncontrado.id,
    unidad: orden.caracteristicas?.unidad || 1,
    ficha
  };

  const { data: ordenActualizada, error: errUpd } = await supabase
    .from("ordenes_trabajo")
    .update({ caracteristicas: nuevasCaracteristicas })
    .eq("id", id)
    .eq("organizacion_id", orgId)
    .select(
      "*, cliente:clientes(*), cotizacion:cotizaciones(*), linea:lineas_producto(*), fase:fases_produccion(*)"
    )
    .single();

  if (errUpd) throw errUpd;

  return { ok: true, orden: ordenActualizada };
}
