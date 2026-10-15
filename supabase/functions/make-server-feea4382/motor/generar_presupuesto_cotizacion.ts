import { desenvolverMetadata } from "./item_metadata.ts";
import { cargarDatosCosteo } from "./cargar_costos.ts";
import { costear } from "./costeo.ts";
import { cargarDatosModelo } from "./cargar_datos.ts";
import { resolverReceta } from "./resolver_receta.ts";
import { generarPresupuestoDesdeCosteo } from "./presupuesto_desde_costeo.ts";

export interface ParametrosGenerarPresupuesto {
  cotizacionId: string;
  orgId: string;
  usuarioId?: string | null;
  reemplazar?: boolean;
  textoEvento?: string | null;
}

export interface ResultadoGenerarPresupuesto {
  estado: "creado" | "reemplazado" | "existe" | "sin_equipos";
  presupuesto?: any;
  presupuesto_id?: string;
  total_costo?: number;
  confianza?: string;
  equipos_incluidos?: number;
  conceptos_omitidos?: { descripcion: string; motivo: string }[];
  mensaje?: string;
  folio?: string;
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
  if (error) console.error("Error registrando evento:", error);
}

export async function generarPresupuestoDeCotizacion(
  supabase: any,
  params: ParametrosGenerarPresupuesto
): Promise<ResultadoGenerarPresupuesto> {
  const { cotizacionId, orgId, usuarioId, reemplazar, textoEvento } = params;

  // Cargar cotización
  const { data: cotizacion, error: errCot } = await supabase
    .from("cotizaciones")
    .select("id, folio, cliente_id, organizacion_id, descripcion, total")
    .eq("id", cotizacionId)
    .eq("organizacion_id", orgId)
    .single();

  if (errCot || !cotizacion) {
    throw new Error("Cotización no encontrada");
  }

  // Cargar conceptos con metadata
  const { data: itemsRaw, error: errItems } = await supabase
    .from("items_cotizacion")
    .select("id, producto_id, cantidad, descripcion, metadata, producto:productos(tipo_item, nombre)")
    .eq("cotizacion_id", cotizacionId);

  if (errItems) {
    throw new Error("Error al cargar conceptos de la cotización: " + errItems.message);
  }

  const items = itemsRaw || [];
  const omitidos: { descripcion: string; motivo: string }[] = [];
  const equiposValidos: any[] = [];

  for (const rawItem of items) {
    const item = rawItem.configuracion ? rawItem : desenvolverMetadata(rawItem);
    const desc = item.descripcion || "Item sin descripción";

    const esProductoTerminado = item.producto?.tipo_item === "producto_terminado";
    if (!esProductoTerminado && !item.configuracion) {
      omitidos.push({
        descripcion: desc,
        motivo: "no es equipo configurable"
      });
      continue;
    }

    const cfg = item.configuracion;
    const modeloId = cfg?.modelo_id || item.producto_id;

    if (!cfg || !cfg.grupos || typeof cfg.grupos !== "object" || !modeloId) {
      omitidos.push({
        descripcion: desc,
        motivo: "sin configurar"
      });
      continue;
    }

    // Recalcular con datos de hoy
    try {
      const datosCosteo = await cargarDatosCosteo(supabase, modeloId);
      const resultadoCosteo = costear(datosCosteo, { grupos: cfg.grupos }, cfg.ajustes || []);

      if (resultadoCosteo.confianza === "incompleta") {
        const modNom = datosCosteo.modelo?.nombre || item.producto?.nombre || "";
        omitidos.push({
          descripcion: desc,
          motivo: modNom ? `${modNom}: sin costos cargados todavía` : "sin costos cargados todavía"
        });
        continue;
      }

      let resultadoBom = null;
      try {
        const datosModelo = await cargarDatosModelo(supabase, modeloId);
        resultadoBom = resolverReceta(datosModelo, { grupos: cfg.grupos });
        const erroresReales = (resultadoBom.errores || []).filter(
          (e: string) => !e.startsWith("Falta elegir una opción para el grupo obligatorio")
        );
        if (erroresReales.length > 0) {
          omitidos.push({
            descripcion: desc,
            motivo: `la configuración tiene errores: ${erroresReales.join(", ")}`
          });
          continue;
        }
      } catch (_eBom: any) {
        // Si el modelo no tiene receta, el costeo es la fuente de verdad
      }

      equiposValidos.push({
        item: {
          descripcion: desc,
          cantidad: Number(item.cantidad) > 0 ? Number(item.cantidad) : 1,
          modelo_id: modeloId
        },
        costeo: resultadoCosteo,
        bom: resultadoBom
      });
    } catch (errCosteo: any) {
      const modNom = item.producto?.nombre || "";
      omitidos.push({
        descripcion: desc,
        motivo: errCosteo.message === "Modelo no encontrado"
          ? (modNom ? `${modNom}: sin costos cargados todavía` : "sin costos cargados todavía")
          : `error al costear: ${errCosteo.message}`
      });
    }
  }

  if (equiposValidos.length === 0) {
    return {
      estado: "sin_equipos",
      conceptos_omitidos: omitidos
    };
  }

  const folioPresupuesto = `PRE-${cotizacion.folio}`;

  // Verificar si ya existe
  const { data: existente } = await supabase
    .from("presupuestos")
    .select("id")
    .eq("folio", folioPresupuesto)
    .eq("organizacion_id", orgId)
    .maybeSingle();

  if (existente && !reemplazar) {
    return {
      estado: "existe",
      presupuesto_id: existente.id,
      folio: folioPresupuesto,
      mensaje: `Ya existe un presupuesto con folio ${folioPresupuesto}`
    };
  }

  const resultadoPresupuesto = generarPresupuestoDesdeCosteo(equiposValidos, {
    cotizacion_id: cotizacion.id,
    cotizacion_folio: cotizacion.folio,
    conceptos_omitidos: omitidos,
    generado_en: new Date().toISOString()
  });

  const payloadPresupuesto = {
    organizacion_id: orgId,
    cliente_id: cotizacion.cliente_id || null,
    folio: folioPresupuesto,
    fecha: new Date().toISOString().split("T")[0],
    concepto: cotizacion.descripcion || `Presupuesto basado en Cotización ${cotizacion.folio}`,
    datos: resultadoPresupuesto.datos,
    total_costo: resultadoPresupuesto.total_costo,
    precio_venta: Number(cotizacion.total) || 0
  };

  let presFinal = null;
  let fueReemplazado = false;

  if (existente && reemplazar) {
    const { data: updated, error: errUpdate } = await supabase
      .from("presupuestos")
      .update(payloadPresupuesto)
      .eq("id", existente.id)
      .eq("organizacion_id", orgId)
      .select()
      .single();
    if (errUpdate) throw errUpdate;
    presFinal = updated;
    fueReemplazado = true;
  } else {
    const { data: inserted, error: errInsert } = await supabase
      .from("presupuestos")
      .insert(payloadPresupuesto)
      .select()
      .single();
    if (errInsert) throw errInsert;
    presFinal = inserted;
  }

  if (textoEvento !== null) {
    const texto = textoEvento || (fueReemplazado
      ? `Presupuesto ${folioPresupuesto} reemplazado desde costeo`
      : `Presupuesto ${folioPresupuesto} generado desde costeo`);

    await registrarEventoHelper(supabase, {
      cotizacion_id: cotizacion.id,
      organizacion_id: orgId,
      evento: texto,
      usuario_id: usuarioId || null
    });
  }

  return {
    estado: fueReemplazado ? "reemplazado" : "creado",
    presupuesto: presFinal,
    presupuesto_id: presFinal.id,
    total_costo: resultadoPresupuesto.total_costo,
    confianza: resultadoPresupuesto.meta.confianza,
    equipos_incluidos: resultadoPresupuesto.meta.conceptos_incluidos.length,
    conceptos_omitidos: resultadoPresupuesto.meta.conceptos_omitidos,
    folio: folioPresupuesto
  };
}

export async function generarPresupuestoAlAprobar(
  _supabase: any,
  cotizacionId: string,
  orgId: string,
  usuarioId: string | null,
  clientParaPresupuesto?: any
) {
  const clienteServicio = clientParaPresupuesto || _supabase;

  try {
    const res = await generarPresupuestoDeCotizacion(clienteServicio, {
      cotizacionId,
      orgId,
      usuarioId: usuarioId || null,
      reemplazar: false,
      textoEvento: null
    });

    if (res.estado === "creado") {
      const folio = res.presupuesto?.folio || `PRE-${cotizacionId}`;
      await registrarEventoHelper(clienteServicio, {
        cotizacion_id: cotizacionId,
        organizacion_id: orgId,
        evento: `Presupuesto ${folio} generado automáticamente al aprobar`,
        usuario_id: usuarioId || null
      });
    } else if (res.estado === "sin_equipos") {
      await registrarEventoHelper(clienteServicio, {
        cotizacion_id: cotizacionId,
        organizacion_id: orgId,
        evento: "No se generó el presupuesto automático: la cotización no tiene equipos configurados con costos cargados",
        usuario_id: usuarioId || null
      });
    }
    return res;
  } catch (err: any) {
    console.error("[generarPresupuestoAlAprobar] Error generando presupuesto automático:", err);
    try {
      await registrarEventoHelper(clienteServicio, {
        cotizacion_id: cotizacionId,
        organizacion_id: orgId,
        evento: `No se generó el presupuesto automático: ${err?.message || "error desconocido"}`,
        usuario_id: usuarioId || null
      });
    } catch (_e) {
      // no romper aprobación bajo ninguna circunstancia
    }
  }
}

export async function ejecutarAprobacionCotizacion(
  supabase: any,
  cotizacionId: string,
  orgId: string,
  usuarioId: string | null,
  clientParaPresupuesto?: any
) {
  await supabase.from("cotizaciones").update({ estado_produccion: "Aprobada" }).eq("id", cotizacionId);
  await registrarEventoHelper(supabase, {
    cotizacion_id: cotizacionId,
    organizacion_id: orgId,
    evento: "Cotizacion aprobada",
    usuario_id: usuarioId
  });

  await generarPresupuestoAlAprobar(supabase, cotizacionId, orgId, usuarioId, clientParaPresupuesto);
}

