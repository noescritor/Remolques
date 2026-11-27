import type { SupabaseClient } from "npm:@supabase/supabase-js";

export const TASA_IVA_ACERO = 0.16;
export const UMBRAL_VARIACION_PRECIO = 0.30;
export const PUNTAJE_MINIMO_SUGERENCIA = 0.45;
export const MARGEN_DESEMPATE_SUGERENCIA = 0.05;

/**
 * Normaliza un precio a base SIN IVA usando TASA_IVA_ACERO (D1).
 * Misma definición que acero_precio_base_sin_iva() en SQL.
 */
export function precioBaseSinIva(
  precio: number | null | undefined,
  incluyeIva?: boolean | null,
): number | null {
  if (precio === null || precio === undefined || !Number.isFinite(Number(precio))) return null;
  const p = Number(precio);
  if (incluyeIva === false) return p;
  return p / (1 + TASA_IVA_ACERO);
}

export const UNIDADES_PIEZA = new Set(["H87", "EA", "C62", "PZA", "PIEZA", "XUN", "ACT"]);
export const UNIDADES_PESO = new Set(["KGM", "GRM", "TNE", "LBR"]);

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const TIPOS_ACERO = new Set(["placa", "lamina", "solera", "canal", "ptr", "tubo", "angulo", "redondo"]);

export class AceroCfdiError extends Error {
  status: number;
  codigo: string;

  constructor(status: number, codigo: string, message: string) {
    super(message);
    this.status = status;
    this.codigo = codigo;
  }
}

export function mapearErrorRpcAceroCfdi(err: unknown): AceroCfdiError {
  const code = (err as { code?: string })?.code;
  const msg = String((err as { message?: string })?.message || err || "Error inesperado en acero CFDI");

  if (
    msg.includes("factura_no_encontrada") ||
    msg.includes("material_no_encontrado") ||
    msg.includes("partida_no_encontrada") ||
    msg.includes("alias_no_encontrado") ||
    msg.includes("proveedor_no_encontrado")
  ) {
    const codigo = msg.split(":")[0]?.trim() || "no_encontrado";
    return new AceroCfdiError(404, codigo, msg);
  }
  if (
    msg.includes("factura_cancelada") ||
    msg.includes("partida_ya_aplicada") ||
    msg.includes("fecha_anterior_a_ultimo_cfdi") ||
    msg.includes("variacion_precio_alta") ||
    msg.includes("material_duplicado_en_lote") ||
    msg.includes("proveedor_conflicto") ||
    msg.includes("deadlock_detected") ||
    code === "40P01"
  ) {
    const codigo = code === "40P01" ? "deadlock_detected" : (msg.split(":")[0]?.trim() || "conflicto");
    const mensaje = code === "40P01"
      ? "Conflicto de concurrencia al actualizar precios simultáneamente; vuelve a intentar."
      : msg;
    return new AceroCfdiError(409, codigo, mensaje);
  }
  if (
    msg.includes("org_requerida") ||
    msg.includes("lineas_requeridas") ||
    msg.includes("tipo_cambio_requerido") ||
    msg.includes("uuid_invalido") ||
    msg.includes("proveedor_requerido") ||
    msg.includes("proveedor_invalido") ||
    msg.includes("factor_requerido") ||
    msg.includes("factor_invalido") ||
    msg.includes("precio_invalido") ||
    code === "22P02"
  ) {
    const codigo = code === "22P02" ? "parametro_invalido" : (msg.split(":")[0]?.trim() || "validacion");
    return new AceroCfdiError(400, codigo, msg);
  }
  return new AceroCfdiError(500, "error_interno", msg);
}

export function normalizarDescripcion(texto: string): string {
  return String(texto || "")
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase()
    .replace(/["'“”‘’]/g, " ")
    .replace(/[^a-z0-9./x\s-]/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

export function clasificarUnidadCfdi(claveUnidad?: string | null): {
  tipo: "pieza" | "peso" | "otra";
  requiere_factor: boolean;
  revisar_unidad: boolean;
} {
  const code = String(claveUnidad || "").trim().toUpperCase();
  if (UNIDADES_PIEZA.has(code)) {
    return { tipo: "pieza", requiere_factor: false, revisar_unidad: false };
  }
  if (UNIDADES_PESO.has(code)) {
    return { tipo: "peso", requiere_factor: true, revisar_unidad: false };
  }
  return { tipo: "otra", requiere_factor: false, revisar_unidad: true };
}

function tokenizarConPeso(textoNorm: string): Map<string, number> {
  const tokens = textoNorm.split(/[\s-]+/).filter((t) => t.length > 0);
  const map = new Map<string, number>();
  for (const raw of tokens) {
    const t = raw.replace(/^\.+|\.+$/g, "");
    if (!t) continue;
    if (/\d/.test(t)) {
      map.set(t, Math.max(map.get(t) || 0, 3.0));
      // También descomponer 4x10 -> 4, 10
      if (t.includes("x")) {
        for (const sub of t.split("x")) {
          if (sub) map.set(sub, Math.max(map.get(sub) || 0, 2.0));
        }
      }
    } else if (TIPOS_ACERO.has(t) || t === "cal" || t === "calibre") {
      map.set(t, Math.max(map.get(t) || 0, 2.0));
    } else if (t.length >= 2 && t !== "de" && t !== "en" && t !== "la" && t !== "el") {
      map.set(t, Math.max(map.get(t) || 0, 1.0));
    }
  }
  return map;
}

function extraerCalibre(textoNorm: string): string | null {
  const m = textoNorm.match(/\bcal(?:ibre)?\.?\s*(\d+(?:\/\d+)?)\b/);
  return m ? m[1] : null;
}

function extraerMedidasNxM(textoNorm: string): string[] {
  const out: string[] = [];
  // Evita capturar el denominador de una fracción (ej. "1/4 x 4" -> no es "4x4")
  const re = /(?<![/\d.])(\d+(?:\.\d+)?)\s*x\s*(\d+(?:\.\d+)?)(?![/\d.])/g;
  let m: RegExpExecArray | null;
  while ((m = re.exec(textoNorm)) !== null) {
    out.push(`${m[1]}x${m[2]}`);
  }
  return out;
}

function hayContradiccionMaterial(descNorm: string, matNorm: string): boolean {
  // 1. Acabado contradictorio: galvanizada vs negra
  const descGalv = /\bgalvanizad\w*\b/.test(descNorm);
  const descNegra = /\bnegr[ao]s?\b/.test(descNorm);
  const matGalv = /\bgalvanizad\w*\b/.test(matNorm);
  const matNegra = /\bnegr[ao]s?\b/.test(matNorm);
  if ((descGalv && matNegra) || (descNegra && matGalv)) return true;

  // 2. Calibre explícito contradictorio (ej. Cal 18 vs Cal 10)
  const calDesc = extraerCalibre(descNorm);
  const calMat = extraerCalibre(matNorm);
  if (calDesc && calMat && calDesc !== calMat) return true;

  // 3. Medida NxM explícita en la descripción que contradice al material (ej. PTR 3x3 vs PTR 4", Placa 6x20 vs 4x10)
  const medidasDesc = extraerMedidasNxM(descNorm);
  const medidasMat = extraerMedidasNxM(matNorm);
  if (medidasDesc.length > 0) {
    for (const md of medidasDesc) {
      // Ignorar medidas métricas decimales (ej. 1.22x3.05) porque el catálogo usa pies (4x10)
      if (md.includes(".")) continue;
      if (medidasMat.length > 0) {
        if (!medidasMat.includes(md)) return true;
      } else {
        // El material no tiene NxM (ej. PTR de 4"): si ninguna parte de NxM aparece como token en el material, contradice
        const [a, b] = md.split("x");
        const tokensMat = new Set(matNorm.split(/[\s-]+/));
        if (!tokensMat.has(md) && !(tokensMat.has(a) && tokensMat.has(b))) {
          return true;
        }
      }
    }
  }

  return false;
}

export function sugerirMaterial(
  descripcion: string,
  _claveSat: string | null | undefined,
  materiales: ReadonlyArray<{ id: string; nombre: string; tipo: string }>,
): { material_id: string | null; puntaje: number; empatado: boolean } {
  const descNorm = normalizarDescripcion(descripcion);
  if (!descNorm || materiales.length === 0) {
    return { material_id: null, puntaje: 0, empatado: false };
  }

  const tokensDesc = tokenizarConPeso(descNorm);
  if (tokensDesc.size === 0) {
    return { material_id: null, puntaje: 0, empatado: false };
  }

  const scores: Array<{ id: string; score: number }> = [];
  for (const mat of materiales) {
    const matNorm = normalizarDescripcion(`${mat.tipo} ${mat.nombre}`);
    if (hayContradiccionMaterial(descNorm, matNorm)) {
      continue;
    }
    const tokensMat = tokenizarConPeso(matNorm);
    let interseccion = 0;
    let totalPesoMat = 0;
    let totalPesoDesc = 0;

    for (const [tk, w] of tokensMat.entries()) {
      totalPesoMat += w;
      if (tokensDesc.has(tk)) {
        interseccion += Math.min(w, tokensDesc.get(tk)!);
      }
    }
    for (const w of tokensDesc.values()) totalPesoDesc += w;

    const denom = totalPesoMat + totalPesoDesc - interseccion;
    const score = denom > 0 ? Math.round((interseccion / denom) * 1000) / 1000 : 0;
    scores.push({ id: mat.id, score });
  }

  scores.sort((a, b) => b.score - a.score);
  const mejor = scores[0];
  const segundo = scores[1];

  if (!mejor || mejor.score < PUNTAJE_MINIMO_SUGERENCIA) {
    return { material_id: null, puntaje: mejor?.score ?? 0, empatado: false };
  }
  if (segundo && mejor.score - segundo.score < MARGEN_DESEMPATE_SUGERENCIA) {
    return { material_id: null, puntaje: mejor.score, empatado: true };
  }
  return { material_id: mejor.id, puntaje: mejor.score, empatado: false };
}

/**
 * Calcula el precio unitario neto en MXN (sin IVA) a partir de una partida CFDI.
 * Nota (O4): el parámetro opcional `descuento` se resta solo cuando el caller tiene
 * un descuento atribuible a la partida específica. En `factura_proveedor_partidas`,
 * el importador CFDI guarda descuentos como filas separadas sin FK al concepto, por lo
 * que `obtenerPropuestaAceroCfdi` usa el importe bruto y activa `descuento_en_factura: true`.
 */
export function precioDesdeConcepto(input: {
  importe: number;
  cantidad: number;
  descuento?: number | null;
  moneda: string;
  tipoCambio?: number | null;
  factorConversion: number;
}): { ok: boolean; precio?: number; error?: string; codigo?: string } {
  const importe = Number(input.importe);
  const cantidad = Number(input.cantidad);
  const descuento = Number(input.descuento || 0);
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

  const importeNeto = Math.max(0, importe - (Number.isFinite(descuento) && descuento > 0 ? descuento : 0));
  const precio = Math.round(((importeNeto / cantidad) * tc * factor) * 10000) / 10000;
  if (!Number.isFinite(precio) || precio <= 0) {
    return { ok: false, codigo: "precio_invalido", error: "El precio calculado debe ser mayor a cero." };
  }
  return { ok: true, precio };
}

export function evaluarBanderas(input: {
  precioNuevo: number | null;
  precioActual: number | null;
  precioActualIncluyeIva?: boolean | null;
  fechaFactura: string | null;
  fechaUltimoPrecioCfdi: string | null;
  yaAplicada: boolean;
  descuentoEnFactura: boolean;
  claveUnidad?: string | null;
  factorCapturado: boolean;
  moneda: string;
  tipoCambio?: number | null;
}) {
  const unidadInfo = clasificarUnidadCfdi(input.claveUnidad);
  const monedaUsdSinTc =
    String(input.moneda || "MXN").toUpperCase() === "USD" && !(Number(input.tipoCambio) > 0);
  const bloqueadaUnidad = unidadInfo.requiere_factor && !input.factorCapturado;

  // D1: Comparar siempre en base común SIN IVA (misma función que el RPC SQL)
  const actualSinIva = precioBaseSinIva(input.precioActual, input.precioActualIncluyeIva);
  let variacionPct: number | null = null;
  let variacionAlta = false;
  if (
    input.precioNuevo !== null &&
    actualSinIva !== null &&
    Number.isFinite(actualSinIva) &&
    actualSinIva > 0
  ) {
    const ratio = (input.precioNuevo - actualSinIva) / actualSinIva;
    variacionPct = Math.round(ratio * 10000) / 100;
    variacionAlta = Math.abs(ratio) > UMBRAL_VARIACION_PRECIO;
  }

  const fechaAnterior = Boolean(
    input.fechaFactura &&
      input.fechaUltimoPrecioCfdi &&
      input.fechaFactura.slice(0, 10) < input.fechaUltimoPrecioCfdi.slice(0, 10),
  );

  return {
    ya_aplicada: input.yaAplicada,
    fecha_anterior: fechaAnterior,
    variacion_pct: variacionPct,
    variacion_alta: variacionAlta,
    descuento_en_factura: input.descuentoEnFactura,
    requiere_factor: unidadInfo.requiere_factor,
    bloqueada_unidad: bloqueadaUnidad,
    revisar_unidad: unidadInfo.revisar_unidad,
    bloqueada_tipo_cambio: monedaUsdSinTc,
  };
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

export async function obtenerPropuestaAceroCfdi(
  supabase: SupabaseClient,
  orgId: string,
  facturaId: string,
  proveedorOverride?: string,
) {
  if (!UUID_RE.test(facturaId)) {
    throw new AceroCfdiError(400, "uuid_invalido", "El identificador de factura no es válido.");
  }

  const { data: factura, error: facErr } = await supabase
    .from("facturas_proveedor")
    .select("id, organizacion_id, proveedor_id, folio, fecha_emision, moneda, tipo_cambio_emision, uuid_fiscal, descuento, estado")
    .eq("id", facturaId)
    .eq("organizacion_id", orgId)
    .maybeSingle();

  if (facErr) throw facErr;
  if (!factura) {
    throw new AceroCfdiError(404, "factura_no_encontrada", "Factura no encontrada en tu organización.");
  }

  const [partidas, materiales, precios, aliasList, aplicados, provRes] = await Promise.all([
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
    paginar<{ id: string; nombre: string; tipo: string; activo: boolean }>(async (from, to) =>
      await supabase
        .from("acero_materiales")
        .select("id, nombre, tipo, activo")
        .eq("organizacion_id", orgId)
        .order("nombre", { ascending: true })
        .order("id", { ascending: true })
        .range(from, to)
    ),
    paginar<{ material_id: string; proveedor: string; precio: number; incluye_iva: boolean }>(async (from, to) =>
      await supabase
        .from("acero_precios")
        .select("material_id, proveedor, precio, incluye_iva")
        .eq("organizacion_id", orgId)
        .order("material_id", { ascending: true })
        .order("proveedor", { ascending: true })
        .range(from, to)
    ),
    paginar<Record<string, unknown>>(async (from, to) =>
      await supabase
        .from("catalogo_alias_factura")
        .select("*")
        .eq("organizacion_id", orgId)
        .eq("destino_tipo", "acero_material")
        .order("id", { ascending: true })
        .range(from, to)
    ),
    paginar<{ partida_id: string; material_id: string; proveedor: string; fecha_emision_factura: string | null }>(async (from, to) =>
      await supabase
        .from("acero_precios_cfdi_aplicados")
        .select("partida_id, material_id, proveedor, fecha_emision_factura")
        .eq("organizacion_id", orgId)
        .order("id", { ascending: true })
        .range(from, to)
    ),
    factura.proveedor_id
      ? supabase.from("proveedores").select("id, nombre, rfc").eq("id", factura.proveedor_id).eq("organizacion_id", orgId).maybeSingle()
      : Promise.resolve({ data: null, error: null }),
  ]);

  const descuentoEnFactura =
    Number(factura.descuento || 0) > 0.005 || partidas.some((p) => p.tipo === "descuento");

  const conceptos = partidas.filter((p) => p.tipo === "concepto");
  const aplicadasSet = new Set(aplicados.map((a) => a.partida_id));
  const proveedoresExistentes = Array.from(new Set(precios.map((p) => p.proveedor))).sort();

  const precioActualMap = new Map<string, { precio: number; incluye_iva: boolean }>();
  for (const pr of precios) {
    precioActualMap.set(`${pr.material_id}|${pr.proveedor.toUpperCase()}`, {
      precio: Number(pr.precio),
      incluye_iva: Boolean(pr.incluye_iva),
    });
  }

  const maxFechaCfdiMap = new Map<string, string>();
  for (const ap of aplicados) {
    if (!ap.fecha_emision_factura) continue;
    const k = `${ap.material_id}|${ap.proveedor.toUpperCase()}`;
    const prev = maxFechaCfdiMap.get(k);
    if (!prev || ap.fecha_emision_factura > prev) {
      maxFechaCfdiMap.set(k, ap.fecha_emision_factura);
    }
  }

  const aliasMap = new Map<string, Record<string, unknown>>();
  for (const al of aliasList) {
    const k = `${al.proveedor_id}|${al.clave_sat || ""}|${al.descripcion_normalizada}`;
    aliasMap.set(k, al);
  }

  const provOverrideNorm = String(proveedorOverride || "").trim().toUpperCase();
  const provNombreRaw = String((provRes as { data?: { nombre?: string } })?.data?.nombre || "").trim();
  const proveedorSugeridoDefault =
    provOverrideNorm ||
    proveedoresExistentes.find((p) => provNombreRaw.toUpperCase().includes(p.toUpperCase())) ||
    (provNombreRaw ? provNombreRaw.toUpperCase().split(/\s+/)[0] : "");

  const materialesActivos = materiales.filter((m) => m.activo !== false);

  const lineas = conceptos.map((c) => {
    const desc = String(c.descripcion || "");
    const descNorm = normalizarDescripcion(desc);
    const claveSat = c.clave_sat ? String(c.clave_sat) : "";
    const claveUnidad = c.clave_unidad ? String(c.clave_unidad) : null;

    const aliasExacto = factura.proveedor_id
      ? aliasMap.get(`${factura.proveedor_id}|${claveSat}|${descNorm}`) ||
        aliasMap.get(`${factura.proveedor_id}||${descNorm}`)
      : undefined;

    let sugerenciaOrigen: "alias" | "similitud" | "ninguna" = "ninguna";
    let materialIdSug: string | null = null;
    let puntaje = 0;
    let proveedorAceroSug = proveedorSugeridoDefault;
    let factorSug = 1;
    let factorConfirmado = false;

    if (aliasExacto) {
      sugerenciaOrigen = "alias";
      materialIdSug = String(aliasExacto.destino_id);
      puntaje = 1;
      if (!provOverrideNorm && aliasExacto.proveedor_acero) proveedorAceroSug = String(aliasExacto.proveedor_acero);
      factorSug = Number(aliasExacto.factor_conversion || 1);
      factorConfirmado = true;
    } else {
      const sim = sugerirMaterial(desc, claveSat, materialesActivos);
      if (sim.material_id) {
        sugerenciaOrigen = "similitud";
        materialIdSug = sim.material_id;
        puntaje = sim.puntaje;
      }
    }

    const unidadInfo = clasificarUnidadCfdi(claveUnidad);
    const calc = precioDesdeConcepto({
      importe: Number(c.importe),
      cantidad: Number(c.cantidad),
      moneda: String(factura.moneda || "MXN"),
      tipoCambio: factura.tipo_cambio_emision != null ? Number(factura.tipo_cambio_emision) : null,
      factorConversion: factorSug,
    });

    const llaveActual = materialIdSug && proveedorAceroSug
      ? `${materialIdSug}|${proveedorAceroSug.toUpperCase()}`
      : null;
    const actualInfo = llaveActual ? precioActualMap.get(llaveActual) : undefined;
    const maxFecha = llaveActual ? (maxFechaCfdiMap.get(llaveActual) || null) : null;

    const banderas = evaluarBanderas({
      precioNuevo: calc.ok ? (calc.precio ?? null) : null,
      precioActual: actualInfo ? actualInfo.precio : null,
      precioActualIncluyeIva: actualInfo ? actualInfo.incluye_iva : null,
      fechaFactura: factura.fecha_emision ? String(factura.fecha_emision).slice(0, 10) : null,
      fechaUltimoPrecioCfdi: maxFecha,
      yaAplicada: aplicadasSet.has(String(c.id)),
      descuentoEnFactura,
      claveUnidad,
      factorCapturado: factorConfirmado || !unidadInfo.requiere_factor,
      moneda: String(factura.moneda || "MXN"),
      tipoCambio: factura.tipo_cambio_emision != null ? Number(factura.tipo_cambio_emision) : null,
    });

    const precioActualSinIva = actualInfo
      ? precioBaseSinIva(actualInfo.precio, actualInfo.incluye_iva)
      : null;

    return {
      partida_id: String(c.id),
      orden: Number(c.orden || 0),
      descripcion: desc,
      descripcion_normalizada: descNorm,
      clave_sat: claveSat || null,
      clave_unidad: claveUnidad,
      cantidad: Number(c.cantidad),
      precio_unitario_xml: Number(c.precio_unitario),
      importe: Number(c.importe),
      precio_neto_mxn: calc.ok ? calc.precio : null,
      sugerencia_origen: sugerenciaOrigen,
      sugerencia_puntaje: puntaje,
      material_id_sugerido: materialIdSug,
      proveedor_acero_sugerido: proveedorAceroSug,
      factor_conversion_sugerido: factorSug,
      precio_actual: actualInfo ? actualInfo.precio : null,
      precio_actual_incluye_iva: actualInfo ? actualInfo.incluye_iva : null,
      precio_actual_sin_iva: precioActualSinIva !== null ? Math.round(precioActualSinIva * 10000) / 10000 : null,
      banderas,
    };
  });

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
      proveedor_nombre: provNombreRaw || null,
      descuento_en_factura: descuentoEnFactura,
    },
    proveedores_acero: proveedoresExistentes,
    materiales: materialesActivos,
    precios_actuales: Array.from(precioActualMap.entries()).map(([k, v]) => {
      const [material_id, proveedor] = k.split("|");
      const sinIva = precioBaseSinIva(v.precio, v.incluye_iva);
      return {
        material_id,
        proveedor,
        precio: v.precio,
        incluye_iva: v.incluye_iva,
        precio_sin_iva: sinIva !== null ? Math.round(sinIva * 10000) / 10000 : null,
      };
    }),
    lineas,
  };
}

export async function aplicarPreciosAceroCfdi(
  serviceClient: SupabaseClient,
  orgId: string,
  userId: string | null,
  facturaId: string,
  lineas: Array<{
    partida_id: string;
    material_id: string;
    proveedor_acero: string;
    factor_conversion?: number;
    factor_confirmado?: boolean;
    guardar_alias?: boolean;
    forzar_fecha_anterior?: boolean;
    forzar_variacion?: boolean;
    descripcion_normalizada?: string;
  }>,
) {
  if (!UUID_RE.test(facturaId)) {
    throw new AceroCfdiError(400, "uuid_invalido", "El identificador de factura no es válido.");
  }
  if (!Array.isArray(lineas) || lineas.length === 0) {
    throw new AceroCfdiError(400, "lineas_requeridas", "Debes seleccionar al menos una partida para aplicar.");
  }

  const sanitizadas = lineas.map((l) => {
    if (!UUID_RE.test(String(l?.partida_id || "")) || !UUID_RE.test(String(l?.material_id || ""))) {
      throw new AceroCfdiError(400, "uuid_invalido", "partida_id y material_id deben ser UUID válidos.");
    }
    const tieneFactor = l.factor_conversion !== undefined && l.factor_conversion !== null;
    let factor: number | undefined = undefined;
    if (tieneFactor) {
      factor = Number(l.factor_conversion);
      if (!Number.isFinite(factor) || factor <= 0) {
        throw new AceroCfdiError(400, "factor_invalido", "El factor de conversión debe ser un número mayor a cero.");
      }
    }
    const prov = String(l.proveedor_acero || "").trim().toUpperCase();
    if (!prov) {
      throw new AceroCfdiError(400, "proveedor_requerido", "Debes indicar el proveedor de acero.");
    }
    const out: Record<string, unknown> = {
      partida_id: l.partida_id,
      material_id: l.material_id,
      proveedor_acero: prov,
      guardar_alias: l.guardar_alias !== false,
      forzar_fecha_anterior: Boolean(l.forzar_fecha_anterior),
      forzar_variacion: Boolean(l.forzar_variacion),
      descripcion_normalizada: l.descripcion_normalizada ? normalizarDescripcion(l.descripcion_normalizada) : undefined,
    };
    if (tieneFactor) {
      out.factor_conversion = factor;
      out.factor_confirmado = l.factor_confirmado !== undefined ? Boolean(l.factor_confirmado) : true;
    } else if (l.factor_confirmado !== undefined) {
      out.factor_confirmado = Boolean(l.factor_confirmado);
    }
    return out;
  });

  const { data, error } = await serviceClient.rpc("aplicar_precios_acero_cfdi", {
    p_org: orgId,
    p_usuario: userId ?? null,
    p_factura_id: facturaId,
    p_lineas: sanitizadas,
  });

  if (error) throw mapearErrorRpcAceroCfdi(error);
  return data;
}

export async function renombrarProveedorAcero(
  serviceClient: SupabaseClient,
  orgId: string,
  de: string,
  a: string,
) {
  const { data, error } = await serviceClient.rpc("renombrar_proveedor_acero", {
    p_org: orgId,
    p_de: de,
    p_a: a,
  });
  if (error) throw mapearErrorRpcAceroCfdi(error);
  return data;
}

export async function listarCatalogoAlias(
  supabase: SupabaseClient,
  orgId: string,
  destinoTipo?: string,
) {
  const rows = await paginar<Record<string, unknown>>(async (from, to) => {
    let q = supabase
      .from("catalogo_alias_factura")
      .select("*")
      .eq("organizacion_id", orgId)
      .order("ultima_confirmacion", { ascending: false })
      .order("id", { ascending: true })
      .range(from, to);
    if (destinoTipo) q = q.eq("destino_tipo", destinoTipo);
    return await q;
  });

  if (rows.length > 0 && (!destinoTipo || destinoTipo === "acero_material")) {
    const mats = await paginar<{ id: string; nombre: string }>(async (from, to) =>
      await supabase
        .from("acero_materiales")
        .select("id, nombre")
        .eq("organizacion_id", orgId)
        .order("id", { ascending: true })
        .range(from, to)
    );
    const matMap = new Map(mats.map((m) => [m.id, m.nombre]));
    for (const r of rows) {
      if (r.destino_tipo === "acero_material") {
        r.destino_nombre = matMap.get(String(r.destino_id)) || null;
      }
    }
  }
  if (rows.length > 0 && (!destinoTipo || destinoTipo === "producto")) {
    const prods = await paginar<{ id: string; nombre: string }>(async (from, to) =>
      await supabase
        .from("productos")
        .select("id, nombre")
        .eq("organizacion_id", orgId)
        .order("id", { ascending: true })
        .range(from, to)
    );
    const prodMap = new Map(prods.map((p) => [String(p.id), p.nombre]));
    for (const r of rows) {
      if (r.destino_tipo === "producto") {
        r.destino_nombre = prodMap.get(String(r.destino_id)) || null;
      }
    }
  }
  return rows;
}

export async function eliminarCatalogoAlias(
  serviceClient: SupabaseClient,
  orgId: string,
  aliasId: string,
) {
  if (!UUID_RE.test(aliasId)) {
    throw new AceroCfdiError(400, "uuid_invalido", "El identificador de alias no es válido.");
  }
  const { data, error } = await serviceClient
    .from("catalogo_alias_factura")
    .delete()
    .eq("id", aliasId)
    .eq("organizacion_id", orgId)
    .select("id")
    .maybeSingle();
  if (error) throw error;
  if (!data) {
    throw new AceroCfdiError(404, "alias_no_encontrado", "Alias no encontrado en tu organización.");
  }
  return { ok: true, id: data.id };
}
