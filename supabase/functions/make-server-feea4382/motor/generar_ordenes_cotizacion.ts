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
