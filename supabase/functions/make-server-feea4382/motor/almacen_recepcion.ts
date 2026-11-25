import type { SupabaseClient } from "npm:@supabase/supabase-js";
import {
  clasificarUnidadCfdi,
  normalizarDescripcion,
  sugerirMaterial,
} from "./acero_cfdi.ts";

export const VENTANA_DOBLE_CONTEO_DIAS = 60;

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const PALABRAS_SERVICIO_RE =
  /\b(flete|maniobra|maniobras|descarga|envio|transporte|servicio|servicios|corte|maquila|comision|paqueteria|seguro|acarreo)\b/;
const PREFIJOS_CLAVE_SAT_SERVICIO = ["78", "80", "81", "84"];

export class AlmacenRecepcionError extends Error {
  status: number;
  codigo: string;

  constructor(status: number, codigo: string, message: string) {
    super(message);
    this.status = status;
    this.codigo = codigo;
  }
}

export function mapearErrorRpcAlmacen(err: unknown): AlmacenRecepcionError {
  const code = (err as { code?: string })?.code;
  const msg = String((err as { message?: string })?.message || err || "Error inesperado en recepción de almacén");

  if (
    msg.includes("factura_no_encontrada") ||
    msg.includes("partida_no_encontrada") ||
    msg.includes("producto_no_encontrado") ||
    msg.includes("recepcion_no_encontrada")
  ) {
    const codigo = msg.split(":")[0]?.trim() || "no_encontrado";
    return new AlmacenRecepcionError(404, codigo, msg);
  }
  if (
    msg.includes("factura_cancelada") ||
    msg.includes("partida_ya_recibida") ||
    msg.includes("partida_duplicada_en_lote") ||
    msg.includes("compra_ya_recibida") ||
    msg.includes("stock_insuficiente") ||
    msg.includes("recepcion_ya_anulada") ||
    msg.includes("deadlock_detected") ||
    code === "40P01" ||
    code === "23505"
  ) {
    const codigo =
      code === "40P01"
        ? "deadlock_detected"
        : code === "23505"
        ? "partida_ya_recibida"
        : msg.split(":")[0]?.trim() || "conflicto";
    const mensaje =
      code === "40P01"
        ? "Conflicto de concurrencia al actualizar existencias simultáneamente; vuelve a intentar."
        : code === "23505"
        ? "Una de las partidas ya fue recibida en almacén."
        : msg;
    return new AlmacenRecepcionError(409, codigo, mensaje);
  }
  if (
    msg.includes("org_requerida") ||
    msg.includes("lineas_requeridas") ||
    msg.includes("tipo_cambio_requerido") ||
    msg.includes("uuid_invalido") ||
    msg.includes("parametro_invalido") ||
    msg.includes("producto_no_es_bien") ||
    msg.includes("factor_requerido") ||
    msg.includes("factor_invalido") ||
    msg.includes("cantidad_invalida") ||
    msg.includes("precio_invalido") ||
    msg.includes("motivo_requerido") ||
    code === "22P02"
  ) {
    const codigo = code === "22P02" ? "parametro_invalido" : msg.split(":")[0]?.trim() || "validacion";
    const mensaje = code === "22P02" ? "Alguno de los identificadores o valores enviados no es válido." : msg;
    return new AlmacenRecepcionError(400, codigo, mensaje);
  }
  return new AlmacenRecepcionError(500, "error_interno", msg);
}

export function cantidadARecibir(
  cantidadXml: number,
  factorConversion: number,
): { ok: boolean; cantidad?: number; codigo?: string; error?: string } {
  const cant = Number(cantidadXml);
  const factor = Number(factorConversion);
  if (!Number.isFinite(cant) || cant <= 0) {
    return { ok: false, codigo: "cantidad_invalida", error: "La cantidad del XML debe ser mayor a cero." };
  }
  if (!Number.isFinite(factor) || factor <= 0) {
    return { ok: false, codigo: "factor_invalido", error: "El factor de conversión debe ser mayor a cero." };
  }
  const cantidad = Math.round(cant * factor * 10000) / 10000;
  if (!Number.isFinite(cantidad) || cantidad <= 0) {
    return { ok: false, codigo: "cantidad_invalida", error: "La cantidad calculada debe ser mayor a cero." };
  }
  return { ok: true, cantidad };
}

/**
 * Calcula el costo unitario en MXN sin IVA por unidad recibida en almacén:
 * (importe / cantidadXml) * tipoCambio / factorConversion.
 * Nota: en factura_proveedor_partidas los descuentos vienen en filas separadas sin FK al concepto,
 * por lo que se usa el importe bruto y se marca descuento_en_factura en las banderas.
 */
export function costoUnitarioMxn(input: {
  importe: number;
  cantidadXml: number;
  moneda: string;
  tipoCambio?: number | null;
  factorConversion: number;
}): { ok: boolean; costo?: number; codigo?: string; error?: string } {
  const importe = Number(input.importe);
  const cantidad = Number(input.cantidadXml);
  const factor = Number(input.factorConversion);

  if (!Number.isFinite(cantidad) || cantidad <= 0) {
    return { ok: false, codigo: "precio_invalido", error: "La cantidad del concepto debe ser mayor a cero." };
  }
  if (!Number.isFinite(importe) || importe <= 0) {
    return { ok: false, codigo: "precio_invalido", error: "El importe del concepto debe ser mayor a cero." };
  }
  if (!Number.isFinite(factor) || factor <= 0) {
    return { ok: false, codigo: "factor_invalido", error: "El factor de conversión debe ser mayor a cero." };
  }

  const moneda = String(input.moneda || "MXN").toUpperCase();
  let tc = 1;
  if (moneda === "USD") {
    const tcNum = Number(input.tipoCambio);
    if (!Number.isFinite(tcNum) || tcNum <= 0) {
      return { ok: false, codigo: "tipo_cambio_requerido", error: "La factura en USD no tiene tipo de cambio válido." };
    }
    tc = tcNum;
  }

  const costo = Math.round(((importe / cantidad) * tc / factor) * 10000) / 10000;
  if (!Number.isFinite(costo) || costo <= 0) {
    return { ok: false, codigo: "precio_invalido", error: "El costo unitario calculado debe ser mayor a cero." };
  }
  return { ok: true, costo };
}

export function clasificarServicioProbable(input: {
  descripcion: string;
  claveSat?: string | null;
  claveUnidad?: string | null;
}): boolean {
  const descNorm = normalizarDescripcion(input.descripcion);
  if (PALABRAS_SERVICIO_RE.test(descNorm)) return true;
  const cu = String(input.claveUnidad || "").trim().toUpperCase();
  if (cu === "E48") return true;
  const csat = String(input.claveSat || "").trim();
  if (csat && PREFIJOS_CLAVE_SAT_SERVICIO.some((p) => csat.startsWith(p))) return true;
  return false;
}

export function evaluarBanderasRecepcion(input: {
  yaRecibida: boolean;
  compraYaRecibida: boolean;
  posibleCompraDuplicada: boolean;
  fechaFactura: string | null;
  ultimoCostoFecha: string | null;
  claveUnidad?: string | null;
  factorCapturado: boolean;
  moneda: string;
  tipoCambio?: number | null;
  descuentoEnFactura: boolean;
  esServicioProbable: boolean;
}) {
  const unidadInfo = clasificarUnidadCfdi(input.claveUnidad);
  const bloqueadaTipoCambio =
    String(input.moneda || "MXN").toUpperCase() === "USD" && !(Number(input.tipoCambio) > 0);
  const bloqueadaUnidad = unidadInfo.requiere_factor && !input.factorCapturado;
  const costoFechaAnterior = Boolean(
    input.fechaFactura &&
      input.ultimoCostoFecha &&
      input.fechaFactura.slice(0, 10) < input.ultimoCostoFecha.slice(0, 10),
  );

  return {
    ya_recibida: input.yaRecibida,
    compra_ya_recibida: input.compraYaRecibida,
    posible_compra_duplicada: input.posibleCompraDuplicada,
    costo_fecha_anterior: costoFechaAnterior,
    requiere_factor: unidadInfo.requiere_factor,
    bloqueada_unidad: bloqueadaUnidad,
    revisar_unidad: unidadInfo.revisar_unidad,
    bloqueada_tipo_cambio: bloqueadaTipoCambio,
    descuento_en_factura: input.descuentoEnFactura,
    es_servicio_probable: input.esServicioProbable,
  };
}

export interface LineaRecepcionInput {
  partida_id: string;
  producto_id: string;
  factor_conversion?: number;
  factor_confirmado?: boolean;
  cantidad_recibida?: number;
  guardar_alias?: boolean;
  descripcion_normalizada?: string;
  notas?: string;
}

export function validarLoteRecepcion(
  facturaId: string,
  lineas: LineaRecepcionInput[],
): Array<Record<string, unknown>> {
  if (!UUID_RE.test(String(facturaId || ""))) {
    throw new AlmacenRecepcionError(400, "uuid_invalido", "El identificador de factura no es válido.");
  }
  if (!Array.isArray(lineas) || lineas.length === 0) {
    throw new AlmacenRecepcionError(400, "lineas_requeridas", "Debes seleccionar al menos una partida para recibir.");
  }

  const partidasVistas = new Set<string>();
  return lineas.map((l) => {
    const partidaId = String(l?.partida_id || "").trim();
    const productoId = String(l?.producto_id || "").trim();
    if (!UUID_RE.test(partidaId)) {
      throw new AlmacenRecepcionError(400, "uuid_invalido", "El identificador de partida no es válido.");
    }
    if (!productoId) {
      throw new AlmacenRecepcionError(400, "parametro_invalido", "Debes seleccionar un producto para cada partida.");
    }
    if (partidasVistas.has(partidaId)) {
      throw new AlmacenRecepcionError(
        400,
        "partida_duplicada_en_lote",
        "La misma partida está repetida en el lote de recepción.",
      );
    }
    partidasVistas.add(partidaId);

    const tieneFactor = l.factor_conversion !== undefined && l.factor_conversion !== null;
    let factor: number | undefined = undefined;
    if (tieneFactor) {
      factor = Number(l.factor_conversion);
      if (!Number.isFinite(factor) || factor <= 0) {
        throw new AlmacenRecepcionError(400, "factor_invalido", "El factor de conversión debe ser mayor a cero.");
      }
    }

    const tieneCantidad = l.cantidad_recibida !== undefined && l.cantidad_recibida !== null;
    let cantidad: number | undefined = undefined;
    if (tieneCantidad) {
      cantidad = Number(l.cantidad_recibida);
      if (!Number.isFinite(cantidad) || cantidad <= 0) {
        throw new AlmacenRecepcionError(400, "cantidad_invalida", "La cantidad a recibir debe ser mayor a cero.");
      }
    }

    const out: Record<string, unknown> = {
      partida_id: partidaId,
      producto_id: productoId,
      guardar_alias: l.guardar_alias !== false,
      descripcion_normalizada: l.descripcion_normalizada ? normalizarDescripcion(l.descripcion_normalizada) : undefined,
      notas: l.notas ? String(l.notas).trim().slice(0, 300) : undefined,
    };
    if (tieneFactor) {
      out.factor_conversion = factor;
      out.factor_confirmado = l.factor_confirmado !== undefined ? Boolean(l.factor_confirmado) : true;
    } else if (l.factor_confirmado !== undefined) {
      out.factor_confirmado = Boolean(l.factor_confirmado);
    }
    if (tieneCantidad) {
      out.cantidad_recibida = cantidad;
    }
    return out;
  });
}

async function paginar<T>(
  queryFn: (from: number, to: number) => Promise<{ data: unknown[] | null; error: unknown }>,
): Promise<T[]> {
  const pageSize = 1000;
  let offset = 0;
  const out: T[] = [];
  while (true) {
    const { data, error } = await queryFn(offset, offset + pageSize - 1);
    if (error) throw error;
    const chunk = (data || []) as T[];
    out.push(...chunk);
    if (chunk.length < pageSize) break;
    offset += pageSize;
  }
  return out;
}

function dentroDeVentanaDias(fechaCompra: string | null | undefined, fechaRef: string | null | undefined, dias: number): boolean {
  if (!fechaCompra || !fechaRef) return false;
  const d1 = new Date(`${String(fechaCompra).slice(0, 10)}T00:00:00Z`).getTime();
  const d2 = new Date(`${String(fechaRef).slice(0, 10)}T00:00:00Z`).getTime();
  if (!Number.isFinite(d1) || !Number.isFinite(d2)) return false;
  return Math.abs(d1 - d2) <= dias * 86_400_000;
}

export async function obtenerPropuestaRecepcionAlmacen(
  supabase: SupabaseClient,
  orgId: string,
  facturaId: string,
) {
  if (!UUID_RE.test(facturaId)) {
    throw new AlmacenRecepcionError(400, "uuid_invalido", "El identificador de factura no es válido.");
  }

  const { data: factura, error: facErr } = await supabase
    .from("facturas_proveedor")
    .select("id, organizacion_id, proveedor_id, compra_id, folio, fecha_emision, moneda, tipo_cambio_emision, uuid_fiscal, descuento, estado")
    .eq("id", facturaId)
    .eq("organizacion_id", orgId)
    .maybeSingle();

  if (facErr) throw facErr;
  if (!factura) {
    throw new AlmacenRecepcionError(404, "factura_no_encontrada", "Factura no encontrada en tu organización.");
  }

  const [partidas, productosRaw, aliasList, recepLineasActivas, provRes, compraLigadaRes, comprasProv] = await Promise.all([
    paginar<Record<string, unknown>>(async (from, to) =>
      await supabase
        .from("factura_proveedor_partidas")
        .select("*")
        .eq("factura_id", facturaId)
        .eq("organizacion_id", orgId)
        .order("orden", { ascending: true })
        .order("id", { ascending: true })
        .range(from, to)
    ),
    paginar<{
      id: string;
      nombre: string;
      unidad: string | null;
      tipo: string | null;
      tipo_item: string | null;
      costo: number | null;
      stock_actual: number | null;
      ultimo_costo_compra: number | null;
      ultimo_costo_compra_fecha: string | null;
      activo?: boolean;
    }>(async (from, to) =>
      await supabase
        .from("productos")
        .select("id, nombre, unidad, tipo, tipo_item, costo, stock_actual, ultimo_costo_compra, ultimo_costo_compra_fecha")
        .eq("organizacion_id", orgId)
        .order("nombre", { ascending: true })
        .order("id", { ascending: true })
        .range(from, to)
    ),
    paginar<Record<string, unknown>>(async (from, to) =>
      await supabase
        .from("catalogo_alias_factura")
        .select("*")
        .eq("organizacion_id", orgId)
        .eq("destino_tipo", "producto")
        .order("id", { ascending: true })
        .range(from, to)
    ),
    paginar<{ partida_id: string; recepcion_id: string; producto_id: string; cantidad_recibida: number }>(async (from, to) =>
      await supabase
        .from("almacen_recepcion_lineas")
        .select("partida_id, recepcion_id, producto_id, cantidad_recibida")
        .eq("organizacion_id", orgId)
        .eq("activa", true)
        .order("id", { ascending: true })
        .range(from, to)
    ),
    factura.proveedor_id
      ? supabase.from("proveedores").select("id, nombre, rfc").eq("id", factura.proveedor_id).eq("organizacion_id", orgId).maybeSingle()
      : Promise.resolve({ data: null, error: null }),
    factura.compra_id
      ? supabase.from("compras_proveedor").select("id, folio, estado, fecha").eq("id", factura.compra_id).eq("organizacion_id", orgId).maybeSingle()
      : Promise.resolve({ data: null, error: null }),
    factura.proveedor_id
      ? paginar<{ id: string; folio: string; estado: string | null; fecha: string | null }>(async (from, to) =>
          await supabase
            .from("compras_proveedor")
            .select("id, folio, estado, fecha")
            .eq("organizacion_id", orgId)
            .eq("proveedor_id", factura.proveedor_id)
            .order("id", { ascending: true })
            .range(from, to)
        )
      : Promise.resolve([]),
  ]);

  // Solo productos bienes y activos; preferir materia_prima primero
  const productosBienes = productosRaw
    .filter((p) => String(p.tipo || "").toLowerCase() === "bien" && p.activo !== false)
    .sort((a, b) => {
      const aMp = a.tipo_item === "materia_prima" ? 0 : 1;
      const bMp = b.tipo_item === "materia_prima" ? 0 : 1;
      if (aMp !== bMp) return aMp - bMp;
      return String(a.nombre || "").localeCompare(String(b.nombre || ""));
    });

  const productosMap = new Map(productosBienes.map((p) => [p.id, p]));
  const catalogoParaSugerencia = productosBienes.map((p) => ({
    id: p.id,
    nombre: p.nombre,
    tipo: p.tipo_item === "materia_prima" ? "" : String(p.tipo_item || ""),
  }));

  // Doble conteo (a) por compra_id ligada
  const compraLigada = (compraLigadaRes as { data?: { id: string; folio: string; estado?: string } | null })?.data;
  const compraYaRecibida = Boolean(compraLigada && String(compraLigada.estado || "").trim().toUpperCase() === "RECIBIDA");

  // Doble conteo (b) por compras Recibidas del mismo proveedor en los últimos 60 días
  const fechaRef = factura.fecha_emision ? String(factura.fecha_emision).slice(0, 10) : new Date().toISOString().slice(0, 10);
  const comprasRecibidasVentana = comprasProv.filter(
    (c) =>
      String(c.estado || "").trim().toUpperCase() === "RECIBIDA" &&
      dentroDeVentanaDias(c.fecha, fechaRef, VENTANA_DOBLE_CONTEO_DIAS),
  );

  const foliosPorProducto = new Map<string, Set<string>>();
  if (comprasRecibidasVentana.length > 0) {
    const compraIds = comprasRecibidasVentana.map((c) => c.id);
    const folioPorCompraId = new Map(comprasRecibidasVentana.map((c) => [c.id, c.folio]));
    const itemsCompras = await paginar<{ compra_id: string; material_id: string }>(async (from, to) =>
      await supabase
        .from("compra_items")
        .select("compra_id, material_id")
        .in("compra_id", compraIds)
        .order("id", { ascending: true })
        .range(from, to)
    );
    for (const it of itemsCompras) {
      const folio = folioPorCompraId.get(it.compra_id);
      if (!folio || !it.material_id) continue;
      if (!foliosPorProducto.has(it.material_id)) foliosPorProducto.set(it.material_id, new Set());
      foliosPorProducto.get(it.material_id)!.add(folio);
    }
  }

  const descuentoEnFactura =
    Number(factura.descuento || 0) > 0.005 || partidas.some((p) => p.tipo === "descuento");
  const conceptos = partidas.filter((p) => p.tipo === "concepto");
  const recibidasSet = new Set(recepLineasActivas.map((r) => r.partida_id));

  const aliasMap = new Map<string, Record<string, unknown>>();
  for (const al of aliasList) {
    const k = `${al.proveedor_id}|${al.clave_sat || ""}|${al.descripcion_normalizada}`;
    aliasMap.set(k, al);
  }

  const foliosDuplicadosFactura = new Set<string>();
  if (compraYaRecibida && compraLigada?.folio) {
    foliosDuplicadosFactura.add(compraLigada.folio);
  }

  const lineas = conceptos.map((c) => {
    const desc = String(c.descripcion || "");
    const descNorm = normalizarDescripcion(desc);
    const claveSat = c.clave_sat ? String(c.clave_sat) : "";
    const claveUnidad = c.clave_unidad ? String(c.clave_unidad) : null;
    const esServicioProbable = clasificarServicioProbable({ descripcion: desc, claveSat, claveUnidad });

    const aliasExacto = factura.proveedor_id
      ? aliasMap.get(`${factura.proveedor_id}|${claveSat}|${descNorm}`) ||
        aliasMap.get(`${factura.proveedor_id}||${descNorm}`)
      : undefined;

    let sugerenciaOrigen: "alias" | "similitud" | "ninguna" = "ninguna";
    let productoIdSug: string | null = null;
    let puntaje = 0;
    let factorSug = 1;
    let factorConfirmado = false;

    if (aliasExacto && productosMap.has(String(aliasExacto.destino_id))) {
      sugerenciaOrigen = "alias";
      productoIdSug = String(aliasExacto.destino_id);
      puntaje = 1;
      factorSug = Number(aliasExacto.factor_conversion || 1);
      factorConfirmado = true;
    } else if (!esServicioProbable) {
      const sim = sugerirMaterial(desc, claveSat, catalogoParaSugerencia);
      if (sim.material_id && productosMap.has(sim.material_id)) {
        sugerenciaOrigen = "similitud";
        productoIdSug = sim.material_id;
        puntaje = sim.puntaje;
      }
    }

    const prodSug = productoIdSug ? productosMap.get(productoIdSug) || null : null;
    const foliosProd = productoIdSug ? Array.from(foliosPorProducto.get(productoIdSug) || []) : [];
    for (const fl of foliosProd) foliosDuplicadosFactura.add(fl);
    const posibleCompraDuplicada = compraYaRecibida || foliosProd.length > 0;

    const unidadInfo = clasificarUnidadCfdi(claveUnidad);
    const cantRes = cantidadARecibir(Number(c.cantidad), factorSug);
    const costoRes = costoUnitarioMxn({
      importe: Number(c.importe),
      cantidadXml: Number(c.cantidad),
      moneda: String(factura.moneda || "MXN"),
      tipoCambio: factura.tipo_cambio_emision != null ? Number(factura.tipo_cambio_emision) : null,
      factorConversion: factorSug,
    });

    const costoCatalogo = prodSug && prodSug.costo !== null ? Number(prodSug.costo) : null;
    let diferenciaCostoPct: number | null = null;
    if (costoRes.ok && costoRes.costo !== undefined && costoCatalogo !== null && costoCatalogo > 0) {
      diferenciaCostoPct = Math.round(((costoRes.costo - costoCatalogo) / costoCatalogo) * 10000) / 100;
    }

    const banderas = evaluarBanderasRecepcion({
      yaRecibida: recibidasSet.has(String(c.id)),
      compraYaRecibida,
      posibleCompraDuplicada,
      fechaFactura: factura.fecha_emision ? String(factura.fecha_emision).slice(0, 10) : null,
      ultimoCostoFecha: prodSug?.ultimo_costo_compra_fecha ? String(prodSug.ultimo_costo_compra_fecha).slice(0, 10) : null,
      claveUnidad,
      factorCapturado: factorConfirmado || !unidadInfo.requiere_factor,
      moneda: String(factura.moneda || "MXN"),
      tipoCambio: factura.tipo_cambio_emision != null ? Number(factura.tipo_cambio_emision) : null,
      descuentoEnFactura,
      esServicioProbable,
    });

    return {
      partida_id: String(c.id),
      orden: Number(c.orden || 0),
      descripcion: desc,
      descripcion_normalizada: descNorm,
      clave_sat: claveSat || null,
      clave_unidad: claveUnidad,
      cantidad_xml: Number(c.cantidad),
      precio_unitario_xml: Number(c.precio_unitario),
      importe: Number(c.importe),
      sugerencia_origen: sugerenciaOrigen,
      sugerencia_puntaje: puntaje,
      producto_id_sugerido: productoIdSug,
      factor_conversion_sugerido: factorSug,
      cantidad_recibir_sugerida: cantRes.ok ? cantRes.cantidad : null,
      costo_unitario_mxn: costoRes.ok ? costoRes.costo : null,
      costo_catalogo: costoCatalogo,
      diferencia_costo_pct: diferenciaCostoPct,
      stock_actual: prodSug ? Number(prodSug.stock_actual || 0) : null,
      ultimo_costo_compra: prodSug && prodSug.ultimo_costo_compra !== null ? Number(prodSug.ultimo_costo_compra) : null,
      ultimo_costo_compra_fecha: prodSug?.ultimo_costo_compra_fecha || null,
      folios_compras_duplicadas: foliosProd,
      banderas,
    };
  });

  const provNombre = String((provRes as { data?: { nombre?: string } })?.data?.nombre || "").trim();

  return {
    factura: {
      id: factura.id,
      folio: factura.folio,
      uuid_fiscal: factura.uuid_fiscal,
      fecha_emision: factura.fecha_emision,
      moneda: factura.moneda,
      tipo_cambio_emision: factura.tipo_cambio_emision != null ? Number(factura.tipo_cambio_emision) : null,
      estado: factura.estado,
      proveedor_id: factura.proveedor_id,
      proveedor_nombre: provNombre || null,
      compra_id: factura.compra_id || null,
      descuento_en_factura: descuentoEnFactura,
    },
    compra_ya_recibida: compraYaRecibida,
    posible_compra_duplicada: foliosDuplicadosFactura.size > 0,
    folios_compras_duplicadas: Array.from(foliosDuplicadosFactura).sort(),
    folios_por_producto: Object.fromEntries(
      Array.from(foliosPorProducto.entries()).map(([k, v]) => [k, Array.from(v).sort()]),
    ),
    productos: productosBienes.map((p) => ({
      id: p.id,
      nombre: p.nombre,
      unidad: p.unidad || "PZA",
      tipo_item: p.tipo_item || "producto_terminado",
      costo: p.costo !== null ? Number(p.costo) : null,
      stock_actual: Number(p.stock_actual || 0),
      ultimo_costo_compra: p.ultimo_costo_compra !== null ? Number(p.ultimo_costo_compra) : null,
      ultimo_costo_compra_fecha: p.ultimo_costo_compra_fecha || null,
    })),
    lineas,
  };
}

export async function recibirFacturaAlmacen(
  serviceClient: SupabaseClient,
  orgId: string,
  userId: string | null,
  facturaId: string,
  lineas: LineaRecepcionInput[],
  confirmoDoble: boolean = false,
  notas?: string | null,
) {
  const sanitizadas = validarLoteRecepcion(facturaId, lineas);
  const { data, error } = await serviceClient.rpc("recibir_factura_almacen", {
    p_org: orgId,
    p_usuario: userId ?? null,
    p_factura_id: facturaId,
    p_lineas: sanitizadas,
    p_confirmo_doble: Boolean(confirmoDoble),
    p_notas: notas ? String(notas).trim().slice(0, 500) : null,
  });
  if (error) throw mapearErrorRpcAlmacen(error);
  return data;
}

export async function listarRecepcionesAlmacen(
  supabase: SupabaseClient,
  orgId: string,
  filtros?: {
    facturaId?: string;
    productoId?: string;
    estado?: string;
    limite?: number;
    offset?: number;
  },
) {
  const limite = Math.min(200, Math.max(1, Number(filtros?.limite || 50)));
  const offset = Math.max(0, Number(filtros?.offset || 0));

  let recepcionIdsFiltro: string[] | null = null;
  if (filtros?.productoId) {
    const linMatch = await paginar<{ recepcion_id: string }>(async (from, to) =>
      await supabase
        .from("almacen_recepcion_lineas")
        .select("recepcion_id")
        .eq("organizacion_id", orgId)
        .eq("producto_id", filtros.productoId!)
        .order("id", { ascending: true })
        .range(from, to)
    );
    recepcionIdsFiltro = Array.from(new Set(linMatch.map((l) => l.recepcion_id)));
    if (recepcionIdsFiltro.length === 0) return [];
  }

  let q = supabase
    .from("almacen_recepciones")
    .select("*")
    .eq("organizacion_id", orgId)
    .order("created_at", { ascending: false })
    .order("id", { ascending: true })
    .range(offset, offset + limite - 1);

  if (filtros?.facturaId) q = q.eq("factura_id", filtros.facturaId);
  if (filtros?.estado && ["recibida", "anulada"].includes(filtros.estado)) q = q.eq("estado", filtros.estado);
  if (recepcionIdsFiltro) q = q.in("id", recepcionIdsFiltro);

  const { data: recs, error: recErr } = await q;
  if (recErr) throw recErr;
  const lista = (recs || []) as Array<Record<string, unknown>>;
  if (lista.length === 0) return [];

  const recIds = lista.map((r) => String(r.id));
  const facIds = Array.from(new Set(lista.map((r) => String(r.factura_id))));
  const provIds = Array.from(new Set(lista.map((r) => r.proveedor_id).filter(Boolean).map(String)));

  const [lineas, facturas, proveedores] = await Promise.all([
    paginar<Record<string, unknown>>(async (from, to) =>
      await supabase
        .from("almacen_recepcion_lineas")
        .select("*")
        .eq("organizacion_id", orgId)
        .in("recepcion_id", recIds)
        .order("created_at", { ascending: true })
        .order("id", { ascending: true })
        .range(from, to)
    ),
    supabase.from("facturas_proveedor").select("id, folio, fecha_emision, moneda").eq("organizacion_id", orgId).in("id", facIds),
    provIds.length > 0
      ? supabase.from("proveedores").select("id, nombre").eq("organizacion_id", orgId).in("id", provIds)
      : Promise.resolve({ data: [], error: null }),
  ]);

  const prodIds = Array.from(new Set(lineas.map((l) => String(l.producto_id))));
  const { data: prods } = prodIds.length > 0
    ? await supabase.from("productos").select("id, nombre, unidad").eq("organizacion_id", orgId).in("id", prodIds)
    : { data: [] };

  const facMap = new Map(((facturas.data || []) as Array<Record<string, unknown>>).map((f) => [String(f.id), f]));
  const provMap = new Map(((proveedores.data || []) as Array<Record<string, unknown>>).map((p) => [String(p.id), p]));
  const prodMap = new Map(((prods || []) as Array<Record<string, unknown>>).map((p) => [String(p.id), p]));

  const lineasPorRec = new Map<string, Array<Record<string, unknown>>>();
  for (const l of lineas) {
    const rid = String(l.recepcion_id);
    if (!lineasPorRec.has(rid)) lineasPorRec.set(rid, []);
    const pr = prodMap.get(String(l.producto_id));
    lineasPorRec.get(rid)!.push({
      ...l,
      cantidad_xml: Number(l.cantidad_xml),
      factor_conversion: Number(l.factor_conversion),
      cantidad_recibida: Number(l.cantidad_recibida),
      costo_unitario_mxn: Number(l.costo_unitario_mxn),
      producto_nombre: pr ? String(pr.nombre) : String(l.producto_id),
      producto_unidad: pr ? String(pr.unidad || "PZA") : "PZA",
    });
  }

  return lista.map((r) => {
    const fac = facMap.get(String(r.factura_id));
    const prov = r.proveedor_id ? provMap.get(String(r.proveedor_id)) : null;
    return {
      ...r,
      factura_folio: fac ? String(fac.folio || "") : "",
      factura_fecha_emision: fac ? fac.fecha_emision : null,
      factura_moneda: fac ? fac.moneda : "MXN",
      proveedor_nombre: prov ? String(prov.nombre || "") : null,
      lineas: lineasPorRec.get(String(r.id)) || [],
    };
  });
}

export async function anularRecepcionAlmacen(
  serviceClient: SupabaseClient,
  orgId: string,
  userId: string | null,
  recepcionId: string,
  motivo: string,
) {
  if (!UUID_RE.test(String(recepcionId || ""))) {
    throw new AlmacenRecepcionError(400, "uuid_invalido", "El identificador de recepción no es válido.");
  }
  const motivoClean = String(motivo || "").trim();
  if (!motivoClean) {
    throw new AlmacenRecepcionError(400, "motivo_requerido", "Debes capturar el motivo de la anulación.");
  }
  const { data, error } = await serviceClient.rpc("anular_recepcion_almacen", {
    p_org: orgId,
    p_usuario: userId ?? null,
    p_recepcion_id: recepcionId,
    p_motivo: motivoClean.slice(0, 500),
  });
  if (error) throw mapearErrorRpcAlmacen(error);
  return data;
}
