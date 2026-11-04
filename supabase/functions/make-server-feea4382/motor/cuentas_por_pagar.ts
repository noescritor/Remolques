// Motor backend para Cuentas por Pagar (Sub-bloque 2R-16)
// Facturas de proveedor, pagos parciales, tipos de cambio, conciliación y crédito con cliente inyectado y lista blanca

import {
  saldoFactura,
  convertirAPesos,
  diasAtraso,
  cubeta,
  resumenCuenta,
  saldoAFecha,
  conciliar,
  usoDeCredito,
  redondearCentavos,
  Moneda,
  FacturaRef,
  PagoRef,
} from "../../../../src/app/utils/cuentasPorPagar.ts";
import {
  parsearCFDI,
  validarSeguridadXML,
  cfdiAPartidasFactura,
  CFDIParseado,
} from "./cfdi_parser.ts";

export interface PartidaFacturaPayload {
  tipo: 'concepto' | 'impuesto_trasladado' | 'retencion' | 'descuento' | 'otro_cargo';
  descripcion: string;
  cantidad: number;
  precio_unitario: number;
  importe: number;
  tasa_o_cuota?: number;
  clave_sat?: string;
  clave_unidad?: string;
}

export interface NuevaFacturaPayload {
  proveedor_id: string;
  compra_id?: string | null;
  sucursal?: string | null;
  folio: string;
  nota?: string | null;
  fecha_emision: string;
  dias_credito?: number;
  fecha_vencimiento?: string;
  moneda: Moneda;
  importe: number;
  tipo_cambio_emision?: number | null;
  concepto?: string | null;
  uuid_fiscal?: string | null;
  subtotal?: number | null;
  descuento?: number | null;
  impuestos_trasladados?: number | null;
  impuestos_retenidos?: number | null;
  partidas?: PartidaFacturaPayload[];
  cfdi?: any;
}

export interface EditarFacturaPayload {
  proveedor_id?: string;
  compra_id?: string | null;
  sucursal?: string | null;
  folio?: string;
  nota?: string | null;
  fecha_emision?: string;
  dias_credito?: number;
  fecha_vencimiento?: string;
  moneda?: Moneda;
  importe?: number;
  tipo_cambio_emision?: number | null;
  concepto?: string | null;
  uuid_fiscal?: string | null;
  subtotal?: number | null;
  descuento?: number | null;
  impuestos_trasladados?: number | null;
  impuestos_retenidos?: number | null;
  partidas?: PartidaFacturaPayload[];
  cfdi?: any;
}

export interface RegistrarPagoPayload {
  fecha_pago: string;
  monto: number;
  tipo_cambio?: number | null;
  metodo_pago?: string;
  referencia?: string | null;
  complemento_pago?: string | null;
  notas?: string | null;
}

export interface GuardarTipoCambioPayload {
  fecha: string;
  valor: number;
  fuente?: string | null;
  notas?: string | null;
}

export interface GuardarCreditoProveedorPayload {
  razon_social?: string | null;
  rfc?: string | null;
  moneda_default?: Moneda;
  dias_credito?: number | null;
  limite_credito?: number | null;
  limite_credito_moneda?: Moneda | null;
  notas_credito?: string | null;
}

export interface GuardarEstadoCuentaPayload {
  fecha: string;
  moneda: Moneda;
  saldo: number;
  notas?: string | null;
}

// ── AUXILIARES DE VALIDACIÓN Y ERROR ──

export function hoyMexicoISO(): string {
  return new Intl.DateTimeFormat('en-CA', { timeZone: 'America/Mexico_City' }).format(new Date());
}

export function formatearErrorRespuesta(err: any): { status: number; body: { error: string } } {
  if (err && typeof err.status === "number" && err.status >= 400 && err.status < 500) {
    return {
      status: err.status,
      body: { error: err.message || "Error en la solicitud" },
    };
  }

  console.error("Error interno CXP:", err);
  return {
    status: 500,
    body: { error: "No se pudo completar la operación" },
  };
}

function esFechaValida(str: string): boolean {
  if (!str || typeof str !== "string") return false;
  if (!/^\d{4}-\d{2}-\d{2}$/.test(str)) return false;
  const [y, m, d] = str.split("-").map(Number);
  if (m < 1 || m > 12 || d < 1 || d > 31) return false;
  const fecha = new Date(y, m - 1, d);
  return (
    fecha.getFullYear() === y &&
    fecha.getMonth() === m - 1 &&
    fecha.getDate() === d
  );
}

function calcularVencimiento(fechaEmision: string, diasCredito: number): string {
  const [y, m, d] = fechaEmision.split("-").map(Number);
  const fecha = new Date(y, m - 1, d);
  fecha.setDate(fecha.getDate() + diasCredito);
  const vy = fecha.getFullYear();
  const vm = String(fecha.getMonth() + 1).padStart(2, "0");
  const vd = String(fecha.getDate()).padStart(2, "0");
  return `${vy}-${vm}-${vd}`;
}

// ── 1. RESUMEN GLOBAL Y POR PROVEEDOR ──

export async function obtenerResumenCxp(
  supabase: any,
  orgId: string,
  corte?: string | null,
  tcManual?: number | null
) {
  const fechaCorte = corte && esFechaValida(corte)
    ? corte
    : hoyMexicoISO();

  if (corte && !esFechaValida(corte)) {
    const err: any = new Error("Fecha de corte inválida (formato YYYY-MM-DD)");
    err.status = 400;
    throw err;
  }

  // Resolver tipo de cambio: tcManual > último en tipos_cambio > null
  let tcUSD: number | null = null;
  if (tcManual !== undefined && tcManual !== null) {
    const tcNum = Number(tcManual);
    if (!Number.isFinite(tcNum) || isNaN(tcNum) || tcNum <= 0) {
      const err: any = new Error("El tipo de cambio debe ser un número mayor a 0");
      err.status = 400;
      throw err;
    }
    tcUSD = Math.round(tcNum * 10000) / 10000;
  } else {
    const { data: ultimosTC } = await supabase
      .from("tipos_cambio")
      .select("valor, fecha")
      .eq("organizacion_id", orgId)
      .eq("moneda", "USD")
      .order("fecha", { ascending: false })
      .limit(1);

    if (ultimosTC && ultimosTC.length > 0) {
      tcUSD = Number(ultimosTC[0].valor);
    }
  }

  // Cargar facturas abiertas con saldo > 0 vía v_facturas_proveedor_saldo
  // Paginación en lotes de 1000 para superar el límite por omisión de PostgREST
  let facturasFiltradas: any[] = [];
  let offset = 0;
  const BATCH = 1000;

  while (true) {
    let q = supabase
      .from("v_facturas_proveedor_saldo")
      .select(`
        id, proveedor_id, folio, sucursal, fecha_emision, fecha_vencimiento,
        moneda, importe, pagado, saldo, estado,
        proveedor:proveedores(id, nombre, razon_social, rfc, moneda_default, dias_credito, limite_credito, limite_credito_moneda)
      `)
      .eq("organizacion_id", orgId)
      .neq("estado", "cancelada")
      .gt("saldo", 0);

    if (typeof q.range === "function") {
      q = q.range(offset, offset + BATCH - 1);
    }

    const { data: batch, error: errF } = await q;
    if (errF) {
      throw new Error(`Error al consultar facturas: ${errF.message}`);
    }

    const rows = batch || [];
    facturasFiltradas.push(...rows);

    if (rows.length < BATCH) {
      break;
    }
    offset += BATCH;
  }

  const facturasRef: FacturaRef[] = facturasFiltradas.map((f: any) => ({
    id: f.id,
    folio: f.folio,
    sucursal: f.sucursal,
    fecha_emision: f.fecha_emision,
    fecha_vencimiento: f.fecha_vencimiento,
    moneda: f.moneda,
    importe: Number(f.importe),
    estado: f.estado,
    pagos: f.pagos
      ? f.pagos.map((p: any) => ({ monto: Number(p.monto), fecha_pago: p.fecha_pago, anulado: p.anulado }))
      : (f.pagado ? [{ monto: Number(f.pagado), anulado: false }] : []),
  }));

  // Resumen general
  const resumenGeneral = resumenCuenta(facturasRef, {
    fechaCorte,
    tcUSD,
  });

  // Agrupar por proveedor
  const provMap: Record<string, { proveedor: any; facturas: FacturaRef[] }> = {};
  for (const f of facturasFiltradas) {
    const pId = f.proveedor_id;
    if (!provMap[pId]) {
      provMap[pId] = {
        proveedor: f.proveedor,
        facturas: [],
      };
    }
    provMap[pId].facturas.push({
      id: f.id,
      folio: f.folio,
      sucursal: f.sucursal,
      fecha_emision: f.fecha_emision,
      fecha_vencimiento: f.fecha_vencimiento,
      moneda: f.moneda,
      importe: Number(f.importe),
      estado: f.estado,
      pagos: f.pagos
        ? f.pagos.map((p: any) => ({ monto: Number(p.monto), fecha_pago: p.fecha_pago, anulado: p.anulado }))
        : (f.pagado ? [{ monto: Number(f.pagado), anulado: false }] : []),
    });
  }

  const porProveedor: any[] = [];
  for (const [provId, data] of Object.entries(provMap)) {
    const resProv = resumenCuenta(data.facturas, { fechaCorte, tcUSD });
    if (resProv.totalFacturasAbiertas > 0) {
      const p = data.proveedor || {};
      const lim = p.limite_credito ? Number(p.limite_credito) : null;
      const limMoneda = p.limite_credito_moneda || p.moneda_default || "MXN";
      // Calcular uso de crédito comparando saldo en la moneda del límite
      const saldoParaLimite = limMoneda === "USD" ? resProv.saldoUSD : (resProv.totalEnPesos || resProv.saldoMXN);
      const usoCreditoPct = lim ? usoDeCredito(saldoParaLimite, lim) : 0;

      porProveedor.push({
        proveedor_id: provId,
        nombre: p.nombre || "Sin nombre",
        razon_social: p.razon_social || null,
        rfc: p.rfc || null,
        moneda_default: p.moneda_default || "MXN",
        dias_credito: p.dias_credito || null,
        limite_credito: lim,
        limite_credito_moneda: limMoneda,
        saldoUSD: resProv.saldoUSD,
        saldoMXN: resProv.saldoMXN,
        equivalenteUSDEnPesos: resProv.equivalenteUSDEnPesos,
        totalEnPesos: resProv.totalEnPesos,
        facturaMasVencidaDias: resProv.facturaMasVencida ? resProv.facturaMasVencida.diasAtraso : 0,
        totalFacturasAbiertas: resProv.totalFacturasAbiertas,
        usoCreditoPct,
      });
    }
  }

  // Ordenar por total en pesos descendente
  porProveedor.sort((a, b) => ((b.totalEnPesos || 0) - (a.totalEnPesos || 0)));

  return {
    corte: fechaCorte,
    tc: tcUSD,
    resumenGeneral,
    porProveedor,
  };
}

// ── 2. GESTIÓN DE FACTURAS ──

export async function listarFacturas(
  supabase: any,
  orgId: string,
  filtros: {
    proveedor_id?: string;
    estado?: string;
    moneda?: string;
    vencidas?: string | boolean;
    desde?: string;
    hasta?: string;
    corte?: string;
  } = {},
  limite = 500
) {
  let query = supabase
    .from("facturas_proveedor")
    .select(`
      id, organizacion_id, proveedor_id, compra_id, sucursal, folio, nota,
      fecha_emision, dias_credito, fecha_vencimiento, moneda, importe,
      tipo_cambio_emision, concepto, estado, created_at, updated_at,
      proveedor:proveedores(id, nombre, razon_social, rfc),
      pagos:pagos_factura(id, fecha_pago, monto, tipo_cambio, metodo_pago, referencia, complemento_pago, notas, anulado, anulado_motivo, anulado_at)
    `)
    .eq("organizacion_id", orgId)
    .order("fecha_vencimiento", { ascending: true })
    .limit(limite + 1);

  if (filtros.proveedor_id) {
    query = query.eq("proveedor_id", filtros.proveedor_id);
  }

  if (filtros.moneda && (filtros.moneda === "MXN" || filtros.moneda === "USD")) {
    query = query.eq("moneda", filtros.moneda);
  }

  if (filtros.desde && esFechaValida(filtros.desde)) {
    query = query.gte("fecha_emision", filtros.desde);
  }

  if (filtros.hasta && esFechaValida(filtros.hasta)) {
    query = query.lte("fecha_emision", filtros.hasta);
  }

  const { data, error } = await query;
  if (error) {
    throw new Error(`Error al listar facturas: ${error.message}`);
  }

  const truncado = (data || []).length > limite;
  const items = truncado ? (data || []).slice(0, limite) : (data || []);

  const hoyStr = filtros.corte && esFechaValida(filtros.corte)
    ? filtros.corte
    : hoyMexicoISO();

  const filtradas = items.map((f: any) => {
    const pagosValidos = (f.pagos || []).filter((p: any) => !p.anulado);
    const pagado = pagosValidos.reduce((sum: number, p: any) => sum + Number(p.monto), 0);
    const importe = Number(f.importe);
    const saldo = saldoFactura(importe, f.pagos || []);
    const dias = diasAtraso(f.fecha_vencimiento, hoyStr);

    let estadoCalculado = f.estado;
    if (f.estado !== "cancelada") {
      if (saldo <= 0) {
        estadoCalculado = "pagada";
      } else if (dias > 0) {
        estadoCalculado = "vencida";
      } else {
        estadoCalculado = "abierta";
      }
    }

    return {
      ...f,
      importe,
      pagado: Math.round(pagado * 100) / 100,
      saldo,
      dias_atraso: dias,
      estado_calculado: estadoCalculado,
      pagos: (f.pagos || []).sort((a: any, b: any) => (b.fecha_pago || "").localeCompare(a.fecha_pago || "")),
    };
  });

  // Filtro por estado solicitado
  let resultado = filtradas;
  if (filtros.estado) {
    if (filtros.estado === "abierta") {
      resultado = resultado.filter((f: any) => f.estado_calculado === "abierta" || f.estado_calculado === "vencida");
    } else if (filtros.estado === "pagada") {
      resultado = resultado.filter((f: any) => f.estado_calculado === "pagada");
    } else if (filtros.estado === "vencida") {
      resultado = resultado.filter((f: any) => f.estado_calculado === "vencida");
    } else if (filtros.estado === "cancelada") {
      resultado = resultado.filter((f: any) => f.estado === "cancelada");
    }
  }

  if (filtros.vencidas === "1" || filtros.vencidas === true || filtros.vencidas === "true") {
    resultado = resultado.filter((f: any) => f.dias_atraso > 0 && f.saldo > 0 && f.estado !== "cancelada");
  }

  return {
    facturas: resultado,
    truncado,
  };
}

export async function crearFactura(
  supabase: any,
  orgId: string,
  payload: NuevaFacturaPayload
) {
  // 1. Validaciones
  if (!payload.proveedor_id) {
    const err: any = new Error("El proveedor_id es obligatorio");
    err.status = 400;
    throw err;
  }

  const { data: prov, error: errProv } = await supabase
    .from("proveedores")
    .select("id, organizacion_id")
    .eq("id", payload.proveedor_id)
    .single();

  if (errProv || !prov || prov.organizacion_id !== orgId) {
    const err: any = new Error("El proveedor no existe o pertenece a otra organización");
    err.status = 404;
    throw err;
  }

  if (payload.compra_id) {
    const { data: comp } = await supabase
      .from("compras_proveedor")
      .select("id, organizacion_id")
      .eq("id", payload.compra_id)
      .single();
    if (!comp || comp.organizacion_id !== orgId) {
      const err: any = new Error("La compra asociada no pertenece a la organización");
      err.status = 400;
      throw err;
    }
  }

  const folioTrim = (payload.folio || "").trim();
  if (!folioTrim) {
    const err: any = new Error("El folio de la factura es obligatorio");
    err.status = 400;
    throw err;
  }

  if (!esFechaValida(payload.fecha_emision)) {
    const err: any = new Error("Fecha de emisión inválida (formato YYYY-MM-DD)");
    err.status = 400;
    throw err;
  }

  const diasRaw = payload.dias_credito !== undefined ? Number(payload.dias_credito) : 30;
  if (!Number.isInteger(diasRaw) || diasRaw < 0) {
    const err: any = new Error("Los días de crédito deben ser un entero mayor o igual a 0");
    err.status = 400;
    throw err;
  }
  const diasCredito = diasRaw;

  let fechaVencimiento = payload.fecha_vencimiento;
  if (!fechaVencimiento || !esFechaValida(fechaVencimiento)) {
    fechaVencimiento = calcularVencimiento(payload.fecha_emision, diasCredito);
  }

  const moneda = payload.moneda;
  if (moneda !== "MXN" && moneda !== "USD") {
    const err: any = new Error("La moneda debe ser MXN o USD");
    err.status = 400;
    throw err;
  }

  if (payload.importe === undefined || payload.importe === null || typeof payload.importe === "boolean") {
    const err: any = new Error("El importe de la factura es obligatorio");
    err.status = 400;
    throw err;
  }
  const impNum = Number(payload.importe);
  if (!Number.isFinite(impNum) || isNaN(impNum) || impNum < 0.01) {
    const err: any = new Error("El importe de la factura debe ser un número finito mayor o igual a 0.01");
    err.status = 400;
    throw err;
  }
  const importe = redondearCentavos(impNum);

  let tcEmision: number | null = null;
  if (payload.tipo_cambio_emision !== undefined && payload.tipo_cambio_emision !== null && (payload.tipo_cambio_emision as any) !== "") {
    const tcNum = Number(payload.tipo_cambio_emision);
    if (!Number.isFinite(tcNum) || isNaN(tcNum) || tcNum <= 0) {
      const err: any = new Error("El tipo de cambio de emisión debe ser un número finito mayor a 0");
      err.status = 400;
      throw err;
    }
    tcEmision = Math.round(tcNum * 10000) / 10000;
  }

  const sucursalTrim = payload.sucursal ? payload.sucursal.trim() : null;

  // 2. Verificar duplicado
  let dupQuery = supabase
    .from("facturas_proveedor")
    .select("id")
    .eq("organizacion_id", orgId)
    .eq("proveedor_id", payload.proveedor_id)
    .eq("folio", folioTrim);

  if (sucursalTrim) {
    dupQuery = dupQuery.eq("sucursal", sucursalTrim);
  } else {
    dupQuery = dupQuery.is("sucursal", null);
  }

  const { data: dup } = await dupQuery;
  if (dup && dup.length > 0) {
    const err: any = new Error(`Ya existe una factura con folio '${folioTrim}' ${sucursalTrim ? `(sucursal ${sucursalTrim})` : ''} para este proveedor`);
    err.status = 409;
    throw err;
  }

  // 3. Insertar
  const insertPayload = {
    organizacion_id: orgId,
    proveedor_id: payload.proveedor_id,
    compra_id: payload.compra_id || null,
    sucursal: sucursalTrim,
    folio: folioTrim,
    nota: payload.nota ? payload.nota.trim() : null,
    fecha_emision: payload.fecha_emision,
    dias_credito: diasCredito,
    fecha_vencimiento: fechaVencimiento,
    moneda,
    importe,
    tipo_cambio_emision: payload.tipo_cambio_emision ? Number(payload.tipo_cambio_emision) : null,
    concepto: payload.concepto ? payload.concepto.trim() : null,
    estado: "abierta",
  };

  const { data: creada, error: errIns } = await supabase
    .from("facturas_proveedor")
    .insert(insertPayload)
    .select()
    .single();

  if (errIns) {
    if (errIns.code === "23505") {
      const err: any = new Error("Factura duplicada para el mismo proveedor y folio");
      err.status = 409;
      throw err;
    }
    throw new Error(`Error al crear factura: ${errIns.message}`);
  }

  return creada;
}

export async function actualizarFactura(
  supabase: any,
  orgId: string,
  facturaId: string,
  payload: EditarFacturaPayload
) {
  // 1. Obtener factura existente
  const { data: fExistente, error: errF } = await supabase
    .from("facturas_proveedor")
    .select(`
      id, organizacion_id, proveedor_id, sucursal, folio, importe, moneda, estado,
      pagos:pagos_factura(id, monto, anulado)
    `)
    .eq("id", facturaId)
    .eq("organizacion_id", orgId)
    .single();

  if (errF || !fExistente) {
    const err: any = new Error("Factura no encontrada o pertenece a otra organización");
    err.status = 404;
    throw err;
  }

  const pagosValidos = (fExistente.pagos || []).filter((p: any) => !p.anulado);
  const totalPagado = pagosValidos.reduce((sum: number, p: any) => sum + Number(p.monto), 0);
  const tienePagosActivos = pagosValidos.length > 0;

  // 2. Si tiene pagos activos: no se puede cambiar moneda ni proveedor; el importe no puede quedar por debajo de lo pagado
  if (tienePagosActivos) {
    if (payload.moneda && payload.moneda !== fExistente.moneda) {
      const err: any = new Error("No se puede cambiar la moneda de una factura que ya tiene pagos registrados");
      err.status = 409;
      throw err;
    }
    if (payload.proveedor_id && payload.proveedor_id !== fExistente.proveedor_id) {
      const err: any = new Error("No se puede cambiar el proveedor de una factura que ya tiene pagos registrados");
      err.status = 409;
      throw err;
    }
    if (payload.importe !== undefined && Number(payload.importe) !== Number(fExistente.importe)) {
      const err: any = new Error("No se puede cambiar el importe de una factura que ya tiene pagos registrados");
      err.status = 409;
      throw err;
    }
  }

  const updateData: any = { updated_at: new Date().toISOString() };

  if (payload.folio !== undefined) {
    const fTrim = payload.folio.trim();
    if (!fTrim) {
      const err: any = new Error("El folio no puede ser vacío");
      err.status = 400;
      throw err;
    }
    updateData.folio = fTrim;
  }

  if (payload.sucursal !== undefined) {
    updateData.sucursal = payload.sucursal ? payload.sucursal.trim() : null;
  }

  if (payload.nota !== undefined) {
    updateData.nota = payload.nota ? payload.nota.trim() : null;
  }

  if (payload.concepto !== undefined) {
    updateData.concepto = payload.concepto ? payload.concepto.trim() : null;
  }

  if (payload.fecha_emision !== undefined) {
    if (!esFechaValida(payload.fecha_emision)) {
      const err: any = new Error("Fecha de emisión inválida");
      err.status = 400;
      throw err;
    }
    updateData.fecha_emision = payload.fecha_emision;
  }

  if (payload.dias_credito !== undefined) {
    const dias = Number(payload.dias_credito);
    if (!Number.isInteger(dias) || dias < 0) {
      const err: any = new Error("Los días de crédito deben ser un entero mayor o igual a 0");
      err.status = 400;
      throw err;
    }
    updateData.dias_credito = dias;
  }

  if (payload.fecha_vencimiento !== undefined) {
    if (!esFechaValida(payload.fecha_vencimiento)) {
      const err: any = new Error("Fecha de vencimiento inválida");
      err.status = 400;
      throw err;
    }
    updateData.fecha_vencimiento = payload.fecha_vencimiento;
  }

  if (!tienePagosActivos) {
    if (payload.moneda !== undefined) {
      if (payload.moneda !== "MXN" && payload.moneda !== "USD") {
        const err: any = new Error("La moneda debe ser MXN o USD");
        err.status = 400;
        throw err;
      }
      updateData.moneda = payload.moneda;
    }
    if (payload.importe !== undefined) {
      const imp = Number(payload.importe);
      if (!Number.isFinite(imp) || isNaN(imp) || imp < 0.01) {
        const err: any = new Error("El importe debe ser un número finito mayor o igual a 0.01");
        err.status = 400;
        throw err;
      }
      updateData.importe = redondearCentavos(imp);
    }
    if (payload.proveedor_id !== undefined) {
      const { data: prov } = await supabase
        .from("proveedores")
        .select("id, organizacion_id")
        .eq("id", payload.proveedor_id)
        .single();
      if (!prov || prov.organizacion_id !== orgId) {
        const err: any = new Error("Proveedor inválido");
        err.status = 404;
        throw err;
      }
      updateData.proveedor_id = payload.proveedor_id;
    }
  }

  if (payload.tipo_cambio_emision !== undefined) {
    if (payload.tipo_cambio_emision !== null && (payload.tipo_cambio_emision as any) !== "") {
      const tc = Number(payload.tipo_cambio_emision);
      if (!Number.isFinite(tc) || isNaN(tc) || tc <= 0) {
        const err: any = new Error("El tipo de cambio de emisión debe ser un número finito mayor a 0");
        err.status = 400;
        throw err;
      }
      updateData.tipo_cambio_emision = Math.round(tc * 10000) / 10000;
    } else {
      updateData.tipo_cambio_emision = null;
    }
  }

  // 3. Ejecutar UPDATE
  const { data: actualizada, error: errUp } = await supabase
    .from("facturas_proveedor")
    .update(updateData)
    .eq("id", facturaId)
    .eq("organizacion_id", orgId)
    .select()
    .single();

  if (errUp) {
    if (errUp.code === "23505") {
      const err: any = new Error("El folio y sucursal especificados ya existen para este proveedor");
      err.status = 409;
      throw err;
    }
    throw new Error(`Error al actualizar factura: ${errUp.message}`);
  }

  return actualizada;
}

export async function cancelarFactura(
  supabase: any,
  orgId: string,
  facturaId: string
) {
  const { data: factura, error: errF } = await supabase
    .from("facturas_proveedor")
    .select("id, organizacion_id, estado, pagos:pagos_factura(id, monto, anulado)")
    .eq("id", facturaId)
    .eq("organizacion_id", orgId)
    .single();

  if (errF || !factura) {
    const err: any = new Error("Factura no encontrada o pertenece a otra organización");
    err.status = 404;
    throw err;
  }

  const tienePagos = (factura.pagos || []).some((p: any) => !p.anulado);
  if (tienePagos) {
    const err: any = new Error("No se puede cancelar una factura que tiene pagos registrados. Debe anular los pagos primero.");
    err.status = 409;
    throw err;
  }

  const { data: cancelada, error: errCan } = await supabase
    .from("facturas_proveedor")
    .update({ estado: "cancelada", updated_at: new Date().toISOString() })
    .eq("id", facturaId)
    .eq("organizacion_id", orgId)
    .select()
    .single();

  if (errCan) {
    throw new Error(`Error al cancelar factura: ${errCan.message}`);
  }

  return cancelada;
}

// ── 3. PAGOS DE FACTURA ──

export async function registrarPago(
  serviceClient: any,
  orgId: string,
  facturaId: string,
  payload: RegistrarPagoPayload
) {
  if (payload.monto === undefined || payload.monto === null || typeof payload.monto === "boolean") {
    const err: any = new Error("El monto del pago es obligatorio");
    err.status = 400;
    throw err;
  }

  const montoNum = Number(payload.monto);
  if (!Number.isFinite(montoNum) || isNaN(montoNum) || montoNum < 0.01) {
    const err: any = new Error("El monto del pago debe ser un número finito mayor o igual a 0.01");
    err.status = 400;
    throw err;
  }

  const montoRedondeado = redondearCentavos(montoNum);

  if (!esFechaValida(payload.fecha_pago)) {
    const err: any = new Error("Fecha de pago inválida (formato YYYY-MM-DD)");
    err.status = 400;
    throw err;
  }

  let tcPago: number | null = null;
  if (payload.tipo_cambio !== undefined && payload.tipo_cambio !== null && (payload.tipo_cambio as any) !== "") {
    const tcNum = Number(payload.tipo_cambio);
    if (!Number.isFinite(tcNum) || isNaN(tcNum) || tcNum <= 0) {
      const err: any = new Error("El tipo de cambio debe ser un número finito mayor a 0");
      err.status = 400;
      throw err;
    }
    tcPago = Math.round(tcNum * 10000) / 10000;
  }

  // Llamada a la función PostgreSQL registrar_pago_factura USANDO serviceClient
  const { data: res, error: errRpc } = await serviceClient.rpc("registrar_pago_factura", {
    p_org: orgId,
    p_factura_id: facturaId,
    p_fecha: payload.fecha_pago,
    p_monto: montoRedondeado,
    p_tipo_cambio: tcPago,
    p_metodo: payload.metodo_pago ? payload.metodo_pago.trim() : "Transferencia",
    p_referencia: payload.referencia ? payload.referencia.trim() : null,
    p_complemento: payload.complemento_pago ? payload.complemento_pago.trim() : null,
    p_notas: payload.notas ? payload.notas.trim() : null,
  });

  if (errRpc) {
    throw new Error(`Error RPC registrar_pago_factura: ${errRpc.message}`);
  }

  if (!res || !res.exito) {
    const errCodigo = res?.error || "error_desconocido";
    const mensaje = res?.mensaje || "Error al registrar pago";
    const err: any = new Error(mensaje);

    if (errCodigo === "no_encontrada") {
      err.status = 404;
    } else if (errCodigo === "excede_saldo" || errCodigo === "cancelada") {
      err.status = 409;
    } else {
      err.status = 400;
    }
    throw err;
  }

  return res;
}

export async function anularPago(
  serviceClient: any,
  orgId: string,
  pagoId: string,
  motivo: string
) {
  const motivoTrim = (motivo || "").trim();
  if (!motivoTrim) {
    const err: any = new Error("Debe especificar el motivo de anulación");
    err.status = 400;
    throw err;
  }

  // Llamada a anular_pago_factura USANDO serviceClient
  const { data: res, error: errRpc } = await serviceClient.rpc("anular_pago_factura", {
    p_org: orgId,
    p_pago_id: pagoId,
    p_motivo: motivoTrim,
  });

  if (errRpc) {
    throw new Error(`Error RPC anular_pago_factura: ${errRpc.message}`);
  }

  if (!res || !res.exito) {
    const errCodigo = res?.error || "error_desconocido";
    const mensaje = res?.mensaje || "Error al anular pago";
    const err: any = new Error(mensaje);

    if (errCodigo === "no_encontrado") {
      err.status = 404;
    } else if (errCodigo === "ya_anulado") {
      err.status = 409;
    } else {
      err.status = 400;
    }
    throw err;
  }

  return res;
}

export async function listarPagos(
  supabase: any,
  orgId: string,
  limite = 200
) {
  const { data, error } = await supabase
    .from("pagos_factura")
    .select(`
      id, factura_id, fecha_pago, monto, tipo_cambio, metodo_pago, referencia,
      complemento_pago, notas, anulado, anulado_motivo, anulado_at, created_at,
      factura:facturas_proveedor(id, folio, sucursal, moneda, importe, proveedor:proveedores(id, nombre, razon_social))
    `)
    .eq("organizacion_id", orgId)
    .order("fecha_pago", { ascending: false })
    .limit(limite + 1);

  if (error) {
    throw new Error(`Error al listar pagos: ${error.message}`);
  }

  const truncado = (data || []).length > limite;
  const items = truncado ? (data || []).slice(0, limite) : (data || []);

  const pagosMapped = items.map((p: any) => {
    const tc = p.tipo_cambio ? Number(p.tipo_cambio) : null;
    const monto = Number(p.monto);
    const moneda = p.factura?.moneda || "MXN";
    const montoPesos = moneda === "USD" && tc ? redondearCentavos(monto * tc) : monto;

    return {
      ...p,
      monto,
      tipo_cambio: tc,
      monto_en_pesos: montoPesos,
    };
  });

  return {
    pagos: pagosMapped,
    truncado,
  };
}

// ── 4. TIPOS DE CAMBIO ──

export async function listarTiposCambio(
  supabase: any,
  orgId: string,
  limite = 60
) {
  const { data, error } = await supabase
    .from("tipos_cambio")
    .select("id, fecha, moneda, valor, fuente, notas, created_at")
    .eq("organizacion_id", orgId)
    .order("fecha", { ascending: false })
    .limit(limite);

  if (error) {
    throw new Error(`Error al consultar tipos de cambio: ${error.message}`);
  }
  return data || [];
}

export async function guardarTipoCambio(
  supabase: any,
  orgId: string,
  payload: GuardarTipoCambioPayload
) {
  if (!esFechaValida(payload.fecha)) {
    const err: any = new Error("Fecha inválida (formato YYYY-MM-DD)");
    err.status = 400;
    throw err;
  }

  const valor = Number(payload.valor);
  if (!Number.isFinite(valor) || isNaN(valor) || valor <= 0) {
    const err: any = new Error("El valor del tipo de cambio debe ser un número finito mayor a 0");
    err.status = 400;
    throw err;
  }

  const record = {
    organizacion_id: orgId,
    fecha: payload.fecha,
    moneda: "USD",
    valor: Math.round(valor * 10000) / 10000,
    fuente: payload.fuente ? payload.fuente.trim() : "manual",
    notas: payload.notas ? payload.notas.trim() : null,
  };

  const { data, error } = await supabase
    .from("tipos_cambio")
    .upsert(record, { onConflict: "organizacion_id,fecha,moneda" })
    .select()
    .single();

  if (error) {
    throw new Error(`Error al guardar tipo de cambio: ${error.message}`);
  }

  return data;
}

// ── 5. CRÉDITO DE PROVEEDOR ──

export async function obtenerCreditoProveedor(
  supabase: any,
  orgId: string,
  proveedorId: string
) {
  const { data, error } = await supabase
    .from("proveedores")
    .select("id, nombre, razon_social, rfc, moneda_default, dias_credito, limite_credito, limite_credito_moneda, notas_credito")
    .eq("id", proveedorId)
    .eq("organizacion_id", orgId)
    .single();

  if (error || !data) {
    const err: any = new Error("Proveedor no encontrado o pertenece a otra organización");
    err.status = 404;
    throw err;
  }

  return data;
}

export async function actualizarCreditoProveedor(
  supabase: any,
  orgId: string,
  proveedorId: string,
  payload: GuardarCreditoProveedorPayload
) {
  const { data: prov, error: errP } = await supabase
    .from("proveedores")
    .select("id")
    .eq("id", proveedorId)
    .eq("organizacion_id", orgId)
    .single();

  if (errP || !prov) {
    const err: any = new Error("Proveedor no encontrado o pertenece a otra organización");
    err.status = 404;
    throw err;
  }

  const updateData: any = {};

  if (payload.razon_social !== undefined) {
    updateData.razon_social = payload.razon_social ? payload.razon_social.trim() : null;
  }

  if (payload.rfc !== undefined) {
    updateData.rfc = payload.rfc ? payload.rfc.trim().toUpperCase() : null;
  }

  if (payload.moneda_default !== undefined) {
    if (payload.moneda_default !== "MXN" && payload.moneda_default !== "USD") {
      const err: any = new Error("moneda_default debe ser MXN o USD");
      err.status = 400;
      throw err;
    }
    updateData.moneda_default = payload.moneda_default;
  }

  if (payload.dias_credito !== undefined) {
    if (payload.dias_credito !== null) {
      const d = Number(payload.dias_credito);
      if (!Number.isInteger(d) || isNaN(d) || d < 0) {
        const err: any = new Error("dias_credito debe ser un entero >= 0");
        err.status = 400;
        throw err;
      }
      updateData.dias_credito = d;
    } else {
      updateData.dias_credito = null;
    }
  }

  if (payload.limite_credito !== undefined) {
    if (payload.limite_credito !== null) {
      const l = Number(payload.limite_credito);
      if (!Number.isFinite(l) || isNaN(l) || l < 0) {
        const err: any = new Error("limite_credito debe ser un número finito >= 0");
        err.status = 400;
        throw err;
      }
      updateData.limite_credito = redondearCentavos(l);
    } else {
      updateData.limite_credito = null;
    }
  }

  if (payload.limite_credito_moneda !== undefined) {
    if (payload.limite_credito_moneda !== null && payload.limite_credito_moneda !== "MXN" && payload.limite_credito_moneda !== "USD") {
      const err: any = new Error("limite_credito_moneda debe ser MXN o USD");
      err.status = 400;
      throw err;
    }
    updateData.limite_credito_moneda = payload.limite_credito_moneda;
  }

  if (payload.notas_credito !== undefined) {
    updateData.notas_credito = payload.notas_credito ? payload.notas_credito.trim() : null;
  }

  const { data: updated, error: errUp } = await supabase
    .from("proveedores")
    .update(updateData)
    .eq("id", proveedorId)
    .eq("organizacion_id", orgId)
    .select("id, nombre, razon_social, rfc, moneda_default, dias_credito, limite_credito, limite_credito_moneda, notas_credito")
    .single();

  if (errUp) {
    throw new Error(`Error al actualizar crédito de proveedor: ${errUp.message}`);
  }

  return updated;
}

// ── 6. ESTADOS DE CUENTA Y CONCILIACIÓN ──

export async function listarEstadosCuentaProveedor(
  supabase: any,
  orgId: string,
  proveedorId: string
) {
  // Validar proveedor
  const { data: prov, error: errP } = await supabase
    .from("proveedores")
    .select("id")
    .eq("id", proveedorId)
    .eq("organizacion_id", orgId)
    .single();

  if (errP || !prov) {
    const err: any = new Error("Proveedor no encontrado");
    err.status = 404;
    throw err;
  }

  const { data, error } = await supabase
    .from("estados_cuenta_proveedor")
    .select("id, fecha, moneda, saldo, notas, created_at")
    .eq("organizacion_id", orgId)
    .eq("proveedor_id", proveedorId)
    .order("fecha", { ascending: false });

  if (error) {
    throw new Error(`Error al consultar estados de cuenta: ${error.message}`);
  }

  return (data || []).map((e: any) => ({
    ...e,
    saldo: Number(e.saldo),
  }));
}

export async function guardarEstadoCuentaProveedor(
  supabase: any,
  orgId: string,
  proveedorId: string,
  payload: GuardarEstadoCuentaPayload
) {
  // Validar proveedor
  const { data: prov, error: errP } = await supabase
    .from("proveedores")
    .select("id")
    .eq("id", proveedorId)
    .eq("organizacion_id", orgId)
    .single();

  if (errP || !prov) {
    const err: any = new Error("Proveedor no encontrado");
    err.status = 404;
    throw err;
  }

  if (!esFechaValida(payload.fecha)) {
    const err: any = new Error("Fecha inválida");
    err.status = 400;
    throw err;
  }

  if (payload.moneda !== "MXN" && payload.moneda !== "USD") {
    const err: any = new Error("La moneda debe ser MXN o USD");
    err.status = 400;
    throw err;
  }

  if (payload.saldo === undefined || payload.saldo === null || typeof payload.saldo === "boolean") {
    const err: any = new Error("El saldo debe ser un número válido");
    err.status = 400;
    throw err;
  }

  const saldoNum = Number(payload.saldo);
  if (!Number.isFinite(saldoNum) || isNaN(saldoNum)) {
    const err: any = new Error("El saldo debe ser un número finito");
    err.status = 400;
    throw err;
  }

  const record = {
    organizacion_id: orgId,
    proveedor_id: proveedorId,
    fecha: payload.fecha,
    moneda: payload.moneda,
    saldo: redondearCentavos(saldoNum),
    notas: payload.notas ? payload.notas.trim() : null,
  };

  const { data, error } = await supabase
    .from("estados_cuenta_proveedor")
    .upsert(record, { onConflict: "organizacion_id,proveedor_id,fecha,moneda" })
    .select()
    .single();

  if (error) {
    throw new Error(`Error al guardar estado de cuenta: ${error.message}`);
  }

  return {
    ...data,
    saldo: Number(data.saldo),
  };
}

export async function obtenerConciliacionProveedor(
  supabase: any,
  orgId: string,
  proveedorId: string,
  corte?: string | null
) {
  const fechaCorte = corte && esFechaValida(corte)
    ? corte
    : hoyMexicoISO();

  if (corte && !esFechaValida(corte)) {
    const err: any = new Error("Fecha de corte inválida");
    err.status = 400;
    throw err;
  }

  // 1. Obtener datos del proveedor
  const { data: proveedor, error: errP } = await supabase
    .from("proveedores")
    .select("id, nombre, razon_social, rfc, moneda_default, dias_credito, limite_credito, limite_credito_moneda")
    .eq("id", proveedorId)
    .eq("organizacion_id", orgId)
    .single();

  if (errP || !proveedor) {
    const err: any = new Error("Proveedor no encontrado");
    err.status = 404;
    throw err;
  }

  // 2. Facturas del proveedor emitidas <= fechaCorte
  const { data: facturas, error: errF } = await supabase
    .from("facturas_proveedor")
    .select("id, folio, sucursal, fecha_emision, fecha_vencimiento, moneda, importe, estado, concepto")
    .eq("organizacion_id", orgId)
    .eq("proveedor_id", proveedorId)
    .lte("fecha_emision", fechaCorte)
    .neq("estado", "cancelada");

  if (errF) {
    throw new Error(`Error al consultar facturas para conciliación: ${errF.message}`);
  }

  const facturasIds = (facturas || []).map((f: any) => f.id);

  // 3. Pagos de esas facturas con fecha <= fechaCorte
  let pagosValidos: PagoRef[] = [];
  if (facturasIds.length > 0) {
    const { data: pagos, error: errPag } = await supabase
      .from("pagos_factura")
      .select("id, factura_id, fecha_pago, monto, tipo_cambio, anulado")
      .eq("organizacion_id", orgId)
      .in("factura_id", facturasIds)
      .lte("fecha_pago", fechaCorte)
      .eq("anulado", false);

    if (errPag) {
      throw new Error(`Error al consultar pagos para conciliación: ${errPag.message}`);
    }

    pagosValidos = (pagos || []).map((p: any) => ({
      id: p.id,
      factura_id: p.factura_id,
      fecha_pago: p.fecha_pago,
      monto: Number(p.monto),
      tipo_cambio: p.tipo_cambio ? Number(p.tipo_cambio) : null,
      anulado: false,
    }));
  }

  // Calcular saldo Leolca a esa fecha
  const facturasRef: FacturaRef[] = (facturas || []).map((f: any) => ({
    id: f.id,
    folio: f.folio,
    sucursal: f.sucursal,
    fecha_emision: f.fecha_emision,
    fecha_vencimiento: f.fecha_vencimiento,
    moneda: f.moneda,
    importe: Number(f.importe),
    estado: f.estado,
  }));

  const saldoLeolca = saldoAFecha(facturasRef, pagosValidos, fechaCorte);

  // 4. Último estado de cuenta registrado del proveedor <= fechaCorte (por moneda)
  const { data: ecUSD } = await supabase
    .from("estados_cuenta_proveedor")
    .select("saldo, fecha")
    .eq("organizacion_id", orgId)
    .eq("proveedor_id", proveedorId)
    .eq("moneda", "USD")
    .lte("fecha", fechaCorte)
    .order("fecha", { ascending: false })
    .limit(1);

  const { data: ecMXN } = await supabase
    .from("estados_cuenta_proveedor")
    .select("saldo, fecha")
    .eq("organizacion_id", orgId)
    .eq("proveedor_id", proveedorId)
    .eq("moneda", "MXN")
    .lte("fecha", fechaCorte)
    .order("fecha", { ascending: false })
    .limit(1);

  const saldoProvUSD = ecUSD && ecUSD.length > 0 ? Number(ecUSD[0].saldo) : null;
  const fechaProvUSD = ecUSD && ecUSD.length > 0 ? ecUSD[0].fecha : null;

  const saldoProvMXN = ecMXN && ecMXN.length > 0 ? Number(ecMXN[0].saldo) : null;
  const fechaProvMXN = ecMXN && ecMXN.length > 0 ? ecMXN[0].fecha : null;

  const concUSD = saldoProvUSD !== null
    ? conciliar(saldoLeolca.saldoUSD, saldoProvUSD)
    : null;

  const concMXN = saldoProvMXN !== null
    ? conciliar(saldoLeolca.saldoMXN, saldoProvMXN)
    : null;

  // Facturas abiertas a la fecha para ayudar al usuario a conciliar
  const pagosMap: Record<string, number> = {};
  for (const p of pagosValidos) {
    pagosMap[p.factura_id] = (pagosMap[p.factura_id] || 0) + p.monto;
  }

  const facturasAbiertas = (facturas || [])
    .map((f: any) => {
      const imp = Number(f.importe);
      const pag = pagosMap[f.id] || 0;
      const sal = Math.max(0, Math.round((imp - pag) * 100) / 100);
      const dias = diasAtraso(f.fecha_vencimiento, fechaCorte);
      return {
        id: f.id,
        folio: f.folio,
        sucursal: f.sucursal,
        fecha_emision: f.fecha_emision,
        fecha_vencimiento: f.fecha_vencimiento,
        moneda: f.moneda,
        importe: imp,
        pagado: pag,
        saldo: sal,
        dias_atraso: dias,
        concepto: f.concepto,
      };
    })
    .filter((f: any) => f.saldo > 0)
    .sort((a: any, b: any) => a.fecha_vencimiento.localeCompare(b.fecha_vencimiento));

  return {
    corte: fechaCorte,
    proveedor: {
      id: proveedor.id,
      nombre: proveedor.nombre,
      razon_social: proveedor.razon_social,
      rfc: proveedor.rfc,
      moneda_default: proveedor.moneda_default || "MXN",
      dias_credito: proveedor.dias_credito,
      limite_credito: proveedor.limite_credito ? Number(proveedor.limite_credito) : null,
      limite_credito_moneda: proveedor.limite_credito_moneda || "MXN",
    },
    usd: {
      saldoLeolca: saldoLeolca.saldoUSD,
      saldoProveedor: saldoProvUSD,
      fechaEstadoCuenta: fechaProvUSD,
      diferencia: concUSD ? concUSD.diferencia : null,
      estado: concUSD ? concUSD.estado : "sin_estado_cuenta",
    },
    mxn: {
      saldoLeolca: saldoLeolca.saldoMXN,
      saldoProveedor: saldoProvMXN,
      fechaEstadoCuenta: fechaProvMXN,
      diferencia: concMXN ? concMXN.diferencia : null,
      estado: concMXN ? concMXN.estado : "sin_estado_cuenta",
    },
    facturasAbiertas,
  };
}

// ── SUB-BLOQUE T4: FACTURAS CON PARTIDAS, CFDI XML Y REPORTES ──

export async function guardarFacturaConPartidasMotor(
  serviceClient: any,
  orgId: string,
  facturaId: string | null,
  payload: NuevaFacturaPayload | EditarFacturaPayload
) {
  if (!payload.proveedor_id) {
    const err: any = new Error("El proveedor_id es obligatorio");
    err.status = 400;
    throw err;
  }
  const folioTrim = (payload.folio || "").trim();
  if (!folioTrim) {
    const err: any = new Error("El folio de la factura es obligatorio");
    err.status = 400;
    throw err;
  }
  if (!payload.fecha_emision || !esFechaValida(payload.fecha_emision)) {
    const err: any = new Error("Fecha de emisión inválida (formato YYYY-MM-DD)");
    err.status = 400;
    throw err;
  }
  const moneda = payload.moneda || "MXN";
  if (moneda !== "MXN" && moneda !== "USD") {
    const err: any = new Error("La moneda debe ser MXN o USD");
    err.status = 400;
    throw err;
  }

  const impNum = Number(payload.importe);
  if (!Number.isFinite(impNum) || isNaN(impNum) || impNum < 0.01) {
    const err: any = new Error("El importe de la factura debe ser un número finito mayor o igual a 0.01");
    err.status = 400;
    throw err;
  }
  const importe = redondearCentavos(impNum);

  const diasCredito = payload.dias_credito !== undefined ? Number(payload.dias_credito) : 30;
  const fechaVencimiento = payload.fecha_vencimiento && esFechaValida(payload.fecha_vencimiento)
    ? payload.fecha_vencimiento
    : calcularVencimiento(payload.fecha_emision, diasCredito);

  // Validar partidas si se incluyeron
  const partidas = payload.partidas || [];
  if (partidas.length > 0) {
    let sumaPartidas = 0;
    for (const p of partidas) {
      if (!p.descripcion || !p.descripcion.trim()) {
        const err: any = new Error("Cada partida debe contener una descripción válida");
        err.status = 400;
        throw err;
      }
      if (Number(p.cantidad) <= 0) {
        const err: any = new Error("La cantidad de cada partida debe ser mayor a 0");
        err.status = 400;
        throw err;
      }
      if (Number(p.importe) < 0) {
        const err: any = new Error("El importe de cada partida no puede ser negativo");
        err.status = 400;
        throw err;
      }
      const imp = Number(p.importe) || 0;
      if (p.tipo === "concepto" || p.tipo === "impuesto_trasladado" || p.tipo === "otro_cargo") {
        sumaPartidas += imp;
      } else if (p.tipo === "descuento" || p.tipo === "retencion") {
        sumaPartidas -= imp;
      }
    }
    sumaPartidas = redondearCentavos(sumaPartidas);
    if (Math.abs(importe - sumaPartidas) > 0.01) {
      const err: any = new Error(`El importe de la factura (${importe}) no coincide con la suma calculada de las partidas (${sumaPartidas})`);
      err.status = 400;
      throw err;
    }
  }

  // Invocar RPC atómica en Postgres
  const { data, error } = await serviceClient.rpc("guardar_factura_con_partidas", {
    p_organizacion_id: orgId,
    p_factura_id: facturaId,
    p_proveedor_id: payload.proveedor_id,
    p_folio: folioTrim,
    p_sucursal: payload.sucursal ? payload.sucursal.trim() : null,
    p_fecha_emision: payload.fecha_emision,
    p_dias_credito: diasCredito,
    p_fecha_vencimiento: fechaVencimiento,
    p_moneda: moneda,
    p_importe: importe,
    p_tipo_cambio_emision: payload.tipo_cambio_emision ? Number(payload.tipo_cambio_emision) : null,
    p_concepto: payload.concepto ? payload.concepto.trim() : null,
    p_uuid_fiscal: payload.uuid_fiscal ? payload.uuid_fiscal.trim() : null,
    p_subtotal: payload.subtotal ? Number(payload.subtotal) : null,
    p_descuento: payload.descuento ? Number(payload.descuento) : 0,
    p_impuestos_trasladados: payload.impuestos_trasladados ? Number(payload.impuestos_trasladados) : 0,
    p_impuestos_retenidos: payload.impuestos_retenidos ? Number(payload.impuestos_retenidos) : 0,
    p_partidas: partidas,
    p_cfdi: payload.cfdi || null,
  });

  if (error) {
    const msg = error.message || "";
    if (msg.includes("factura_no_encontrada")) {
      const err: any = new Error("La factura no existe o pertenece a otra organización");
      err.status = 404;
      throw err;
    }
    if (msg.includes("proveedor_no_encontrado")) {
      const err: any = new Error("El proveedor no existe o pertenece a otra organización");
      err.status = 400;
      throw err;
    }
    if (msg.includes("importe_no_cuadra")) {
      const err: any = new Error("El importe de la factura no coincide con la suma de las partidas");
      err.status = 400;
      throw err;
    }
    if (msg.includes("factura_cancelada")) {
      const err: any = new Error("No se puede modificar una factura que ya ha sido cancelada");
      err.status = 409;
      throw err;
    }
    if (msg.includes("no_se_puede_cambiar_moneda_con_pagos")) {
      const err: any = new Error("No se puede cambiar la moneda de una factura que ya tiene pagos registrados");
      err.status = 409;
      throw err;
    }
    if (msg.includes("no_se_puede_cambiar_proveedor_con_pagos")) {
      const err: any = new Error("No se puede cambiar el proveedor de una factura que ya tiene pagos registrados");
      err.status = 409;
      throw err;
    }
    if (msg.includes("nuevo_total_menor_que_pagado")) {
      const err: any = new Error("El nuevo importe de la factura no puede ser menor a lo ya pagado");
      err.status = 409;
      throw err;
    }
    if (msg.includes("uuid_fiscal_duplicado") || msg.includes("uq_facturas_proveedor_org_uuid")) {
      const err: any = new Error("Ya existe una factura registrada con este UUID fiscal en la organización");
      err.status = 409;
      throw err;
    }
    if (msg.includes("uq_facturas_proveedor_folio") || (msg.includes("duplicate key") && msg.includes("folio"))) {
      const err: any = new Error("Ya existe una factura con ese folio para este proveedor");
      err.status = 409;
      throw err;
    }
    console.error("Error no controlado al guardar factura con partidas:", error);
    const err: any = new Error("Error interno al guardar la factura con partidas");
    err.status = 500;
    throw err;
  }

  return data;
}

export async function obtenerPartidasFactura(
  supabase: any,
  orgId: string,
  facturaId: string
) {
  const { data, error } = await supabase
    .from("factura_proveedor_partidas")
    .select("*")
    .eq("factura_id", facturaId)
    .eq("organizacion_id", orgId)
    .order("orden", { ascending: true });

  if (error) {
    console.error("Error al obtener partidas de factura:", error);
    const err: any = new Error("Error interno al obtener las partidas de la factura");
    err.status = 500;
    throw err;
  }
  return data || [];
}

export async function previsualizarCFDIsMotor(
  supabase: any,
  orgId: string,
  archivos: Array<{ nombre: string; contenido: string }>,
  rfcOrg?: string
) {
  if (!archivos || !Array.isArray(archivos)) {
    const err: any = new Error("El payload debe contener un arreglo de archivos");
    err.status = 400;
    throw err;
  }
  if (archivos.length > 100) {
    const err: any = new Error("Se permite un máximo de 100 archivos XML por lote");
    err.status = 400;
    throw err;
  }

  const resultados: any[] = [];
  const parsedItems: Array<{ nombre: string; arch: any; parsed: any }> = [];

  for (const arch of archivos) {
    const nombre = arch.nombre || "archivo.xml";
    if (!arch.contenido || typeof arch.contenido !== "string") {
      resultados.push({
        nombre,
        estado: "error",
        motivo: "Contenido de archivo vacío o inválido",
      });
      continue;
    }

    if (arch.contenido.length > 2 * 1024 * 1024) {
      resultados.push({
        nombre,
        estado: "error",
        motivo: "El archivo excede el límite máximo de 2 MB",
      });
      continue;
    }

    try {
      validarSeguridadXML(arch.contenido);
      const parsed = parsearCFDI(arch.contenido, rfcOrg);
      if (!parsed.ok) {
        resultados.push({
          nombre,
          estado: parsed.tipo_comprobante === "E" ? "nota_credito" : "rechazado",
          motivo: parsed.error || "Comprobante no válido para importación",
          tipo_comprobante: parsed.tipo_comprobante,
        });
        continue;
      }
      parsedItems.push({ nombre, arch, parsed });
    } catch (err: any) {
      resultados.push({
        nombre,
        estado: "error",
        motivo: err.message || "Error al procesar XML",
      });
    }
  }

  // Pre-cargar proveedores y UUIDs sólo de los archivos recibidos (evita límite de 1000 filas)
  const candidateUUIDs = Array.from(new Set(parsedItems.map((p) => p.parsed.uuid_fiscal.toUpperCase())));
  const candidateRFCs = Array.from(new Set(parsedItems.map((p) => (p.parsed.emisor.rfc || "").toUpperCase())));

  const uuidSet = new Set<string>();
  if (candidateUUIDs.length > 0) {
    const { data: cfdisExistentes } = await supabase
      .from("facturas_proveedor_cfdi")
      .select("uuid_fiscal")
      .eq("organizacion_id", orgId)
      .in("uuid_fiscal", candidateUUIDs);
    for (const c of cfdisExistentes || []) {
      if (c.uuid_fiscal) uuidSet.add(c.uuid_fiscal.toUpperCase());
    }

    const { data: facturasExistentes } = await supabase
      .from("facturas_proveedor")
      .select("uuid_fiscal")
      .eq("organizacion_id", orgId)
      .in("uuid_fiscal", candidateUUIDs);
    for (const f of facturasExistentes || []) {
      if (f.uuid_fiscal) uuidSet.add(f.uuid_fiscal.toUpperCase());
    }
  }

  const provMapByRfc: Record<string, any> = {};
  if (candidateRFCs.length > 0) {
    const { data: provs } = await supabase
      .from("proveedores")
      .select("id, nombre, rfc, dias_credito, moneda_default")
      .eq("organizacion_id", orgId)
      .in("rfc", candidateRFCs);
    for (const p of provs || []) {
      if (p.rfc) provMapByRfc[p.rfc.trim().toUpperCase()] = p;
    }
  }

  for (const { nombre, arch, parsed } of parsedItems) {
    const uuidUpper = parsed.uuid_fiscal.toUpperCase();
    if (uuidSet.has(uuidUpper)) {
      resultados.push({
        nombre,
        estado: "duplicado",
        motivo: "Factura ya importada previamente en la organización",
        uuid_fiscal: parsed.uuid_fiscal,
        emisor: parsed.emisor,
        total: parsed.total,
        moneda: parsed.moneda,
      });
      continue;
    }

    const rfcEmisor = (parsed.emisor.rfc || "").toUpperCase();
    const provExistente = provMapByRfc[rfcEmisor];
    const partidas = cfdiAPartidasFactura(parsed);

    const tieneInconsistencia = parsed.advertencias && parsed.advertencias.some((adv: string) =>
      adv.toLowerCase().includes("inconsistencia en total")
    );

    const estadoFinal = tieneInconsistencia
      ? "inconsistente"
      : provExistente
      ? "valido"
      : "proveedor_nuevo";

    const motivoFinal = tieneInconsistencia
      ? "El total declarado del CFDI no coincide con el cálculo de SubTotal e Impuestos"
      : provExistente
      ? "Listo para importar"
      : "Proveedor no encontrado en catálogo; se creará al confirmar";

    resultados.push({
      nombre,
      estado: estadoFinal,
      motivo: motivoFinal,
      cfdi: parsed,
      proveedor_id: provExistente ? provExistente.id : null,
      proveedor_nombre: provExistente ? provExistente.nombre : parsed.emisor.nombre,
      dias_credito: provExistente ? provExistente.dias_credito : 30,
      partidas,
      xml_contenido: arch.contenido,
      advertencias: parsed.advertencias,
    });
  }

  const validosCount = resultados.filter((r) => r.estado === "valido" || r.estado === "proveedor_nuevo").length;
  const duplicadosCount = resultados.filter((r) => r.estado === "duplicado").length;
  const nuevosProvCount = resultados.filter((r) => r.estado === "proveedor_nuevo").length;

  return {
    total_archivos: archivos.length,
    validos_count: validosCount,
    duplicados_count: duplicadosCount,
    nuevos_proveedores_count: nuevosProvCount,
    resultados,
  };
}

export async function importarCFDIsMotor(
  serviceClient: any,
  orgId: string,
  lotes: Array<{
    xml_contenido: string;
    cfdi?: any;
    nombre_archivo?: string;
    crear_proveedor?: boolean;
    proveedor_id?: string;
  }>
) {
  if (!lotes || !Array.isArray(lotes) || lotes.length === 0) {
    const err: any = new Error("No se proporcionaron comprobantes para importar");
    err.status = 400;
    throw err;
  }
  if (lotes.length > 100) {
    const err: any = new Error("El lote supera el límite máximo de 100 comprobantes por importación");
    err.status = 400;
    throw err;
  }

  let importadas = 0;
  let proveedoresCreados = 0;
  const detalles: any[] = [];

  for (const item of lotes) {
    if (!item.xml_contenido || typeof item.xml_contenido !== "string") {
      detalles.push({ ok: false, error: "Contenido XML inválido o vacío" });
      continue;
    }

    try {
      validarSeguridadXML(item.xml_contenido);
      const cfdi = parsearCFDI(item.xml_contenido);
      if (!cfdi.ok) {
        detalles.push({
          uuid_fiscal: cfdi.uuid_fiscal || null,
          folio: cfdi.folio || null,
          ok: false,
          error: cfdi.error || "Error al parsear CFDI",
        });
        continue;
      }

      const uuidUpper = cfdi.uuid_fiscal.toUpperCase();

      // Verificar existencia previa
      const { data: fExistente } = await serviceClient
        .from("facturas_proveedor")
        .select("id")
        .eq("organizacion_id", orgId)
        .eq("uuid_fiscal", uuidUpper)
        .limit(1);

      if (fExistente && fExistente.length > 0) {
        detalles.push({
          uuid_fiscal: uuidUpper,
          folio: cfdi.folio,
          ok: false,
          error: `Factura con UUID ${uuidUpper} ya importada previamente`,
          ya_importado: true,
        });
        continue;
      }

      let provId = item.proveedor_id;
      let diasCredito = 30;

      if (!provId) {
        const { data: prov } = await serviceClient
          .from("proveedores")
          .select("id, dias_credito")
          .eq("organizacion_id", orgId)
          .eq("rfc", cfdi.emisor.rfc.toUpperCase())
          .limit(1);

        if (prov && prov.length > 0) {
          provId = prov[0].id;
          diasCredito = prov[0].dias_credito || 30;
        } else if (item.crear_proveedor) {
          const { data: nuevoProv, error: errProv } = await serviceClient
            .from("proveedores")
            .insert({
              organizacion_id: orgId,
              nombre: cfdi.emisor.nombre,
              razon_social: cfdi.emisor.nombre,
              rfc: cfdi.emisor.rfc.toUpperCase(),
              moneda_default: cfdi.moneda,
              dias_credito: 30,
              condiciones_pago: "Crédito 30 días",
            })
            .select("id, dias_credito")
            .single();

          if (errProv) throw new Error("Error al crear proveedor en catálogo");
          provId = nuevoProv.id;
          proveedoresCreados++;
        } else {
          throw new Error(`Proveedor con RFC ${cfdi.emisor.rfc} no existe y no se autorizó crearlo`);
        }
      } else {
        const { data: prov } = await serviceClient
          .from("proveedores")
          .select("dias_credito")
          .eq("organizacion_id", orgId)
          .eq("id", provId)
          .limit(1);
        if (prov && prov.length > 0 && prov[0].dias_credito !== undefined && prov[0].dias_credito !== null) {
          diasCredito = Number(prov[0].dias_credito);
        }
      }

      const fechaEmisionISO = (cfdi.fecha_emision || "").slice(0, 10);
      const fechaVencimiento = calcularVencimiento(fechaEmisionISO, diasCredito);
      const partidas = cfdiAPartidasFactura(cfdi);

      const fechaEmisionMexico = cfdi.fecha_emision && !cfdi.fecha_emision.includes('Z') && !/[+-]\d{2}:\d{2}$/.test(cfdi.fecha_emision)
        ? `${cfdi.fecha_emision}-06:00`
        : cfdi.fecha_emision;

      const cfdiPayload = {
        version: cfdi.version,
        rfc_emisor: cfdi.emisor.rfc.toUpperCase(),
        nombre_emisor: cfdi.emisor.nombre,
        rfc_receptor: cfdi.receptor.rfc.toUpperCase(),
        serie: cfdi.serie || null,
        folio: cfdi.folio || null,
        fecha_emision: fechaEmisionMexico,
        moneda: cfdi.moneda,
        tipo_cambio: cfdi.tipo_cambio,
        subtotal: cfdi.subtotal,
        descuento: cfdi.descuento || 0,
        impuestos_trasladados: cfdi.impuestos_trasladados || 0,
        impuestos_retenidos: cfdi.impuestos_retenidos || 0,
        total: cfdi.total,
        metodo_pago: cfdi.metodo_pago || null,
        forma_pago: cfdi.forma_pago || null,
        xml_contenido: item.xml_contenido,
      };

      // Guardar factura, partidas y comprobante fiscal en una sola transacción atómica vía RPC
      const resFactura = await guardarFacturaConPartidasMotor(serviceClient, orgId, null, {
        proveedor_id: provId,
        folio: cfdi.folio || uuidUpper.slice(0, 8),
        sucursal: cfdi.serie || null,
        fecha_emision: fechaEmisionISO,
        dias_credito: diasCredito,
        fecha_vencimiento: fechaVencimiento,
        moneda: cfdi.moneda,
        importe: cfdi.total,
        tipo_cambio_emision: cfdi.tipo_cambio,
        concepto: cfdi.conceptos[0]?.descripcion ? `CFDI: ${cfdi.conceptos[0].descripcion}` : "Importado desde CFDI XML",
        uuid_fiscal: uuidUpper,
        subtotal: cfdi.subtotal,
        descuento: cfdi.descuento || 0,
        impuestos_trasladados: cfdi.impuestos_trasladados || 0,
        impuestos_retenidos: cfdi.impuestos_retenidos || 0,
        partidas,
        cfdi: cfdiPayload,
      });

      const facturaId = (resFactura as any)?.factura_id;
      importadas++;
      detalles.push({
        uuid_fiscal: uuidUpper,
        folio: cfdi.folio,
        factura_id: facturaId,
        ok: true,
      });
    } catch (err: any) {
      detalles.push({
        uuid_fiscal: item.cfdi?.uuid_fiscal || null,
        folio: item.cfdi?.folio || null,
        ok: false,
        error: err.message || "Error al procesar comprobante",
      });
    }
  }

  return {
    total_solicitadas: lotes.length,
    importadas,
    proveedores_creados: proveedoresCreados,
    detalles,
  };
}

export async function obtenerReporteFacturacion(
  supabase: any,
  orgId: string,
  filtros: {
    desde?: string;
    hasta?: string;
    filtro_fecha_tipo?: "emision" | "vencimiento";
    proveedor_id?: string;
    moneda?: string;
    estado?: string;
    corte?: string;
    limite?: number;
  }
) {
  const limite = Math.min(Math.max(1, Number(filtros.limite) || 500), 1000);
  const fechaCorte = filtros.corte && esFechaValida(filtros.corte) ? filtros.corte : hoyMexicoISO();

  // 1. Obtener tipo de cambio vigente a la fecha de corte
  let tcUSD = 20.0;
  let tcFecha: string | null = null;
  let sinTipoCambio = true;

  const { data: ultimosTC } = await supabase
    .from("tipos_cambio")
    .select("valor, fecha")
    .eq("organizacion_id", orgId)
    .eq("moneda", "USD")
    .lte("fecha", fechaCorte)
    .order("fecha", { ascending: false })
    .limit(1);

  if (ultimosTC && ultimosTC.length > 0) {
    tcUSD = Number(ultimosTC[0].valor);
    tcFecha = ultimosTC[0].fecha;
    sinTipoCambio = false;
  }

  // 2. Construir consulta sobre v_facturas_proveedor_saldo con columnas fiscales
  let q = supabase
    .from("v_facturas_proveedor_saldo")
    .select(`
      id, proveedor_id, folio, sucursal, fecha_emision, fecha_vencimiento,
      moneda, importe, pagado, saldo, estado, estado_vencimiento, dias_vencimiento,
      uuid_fiscal, subtotal, impuestos_trasladados, impuestos_retenidos,
      proveedor:proveedores(id, nombre, razon_social, rfc)
    `)
    .eq("organizacion_id", orgId)
    .order("fecha_emision", { ascending: false });

  if (filtros.proveedor_id && filtros.proveedor_id !== "todos") {
    q = q.eq("proveedor_id", filtros.proveedor_id);
  }

  if (filtros.moneda && filtros.moneda !== "todas") {
    q = q.eq("moneda", filtros.moneda);
  }

  // Filtrar estado a nivel base de datos antes de aplicar limit
  if (filtros.estado && filtros.estado !== "todas") {
    if (filtros.estado === "abierta") {
      q = q.gt("saldo", 0).neq("estado", "cancelada");
    } else if (filtros.estado === "pagada") {
      q = q.lte("saldo", 0).neq("estado", "cancelada");
    } else if (filtros.estado === "vencida") {
      q = q.eq("estado_vencimiento", "vencida").gt("saldo", 0).neq("estado", "cancelada");
    } else if (filtros.estado === "cancelada") {
      q = q.eq("estado", "cancelada");
    }
  }

  const campoFecha = filtros.filtro_fecha_tipo === "vencimiento" ? "fecha_vencimiento" : "fecha_emision";
  if (filtros.desde && esFechaValida(filtros.desde)) {
    q = q.gte(campoFecha, filtros.desde);
  }
  if (filtros.hasta && esFechaValida(filtros.hasta)) {
    q = q.lte(campoFecha, filtros.hasta);
  }

  q = q.limit(limite + 1);

  const { data, error } = await q;
  if (error) {
    throw new Error(`Error al generar reporte de facturación: ${error.message}`);
  }

  const truncado = (data || []).length > limite;
  const itemsRaw = truncado ? (data || []).slice(0, limite) : (data || []);

  const items = itemsRaw.map((f: any) => {
    const importe = Number(f.importe);
    const pagado = Number(f.pagado || 0);
    const saldo = Number(f.saldo || 0);
    const subtotal = Number(f.subtotal || importe);
    const impuestos_trasladados = Number(f.impuestos_trasladados || 0);
    const impuestos_retenidos = Number(f.impuestos_retenidos || 0);
    const dias = diasAtraso(f.fecha_vencimiento, fechaCorte);

    let estadoCalculado = f.estado;
    if (f.estado !== "cancelada") {
      if (saldo <= 0) {
        estadoCalculado = "pagada";
      } else if (dias > 0) {
        estadoCalculado = "vencida";
      } else if (pagado > 0) {
        estadoCalculado = "pagada_parcial";
      } else {
        estadoCalculado = "abierta";
      }
    }

    return {
      id: f.id,
      proveedor_id: f.proveedor_id,
      proveedor_nombre: f.proveedor?.nombre || "Sin proveedor",
      proveedor_rfc: f.proveedor?.rfc || "",
      folio: f.folio,
      sucursal: f.sucursal,
      uuid_fiscal: f.uuid_fiscal,
      subtotal,
      impuestos_trasladados,
      impuestos_retenidos,
      fecha_emision: f.fecha_emision,
      fecha_vencimiento: f.fecha_vencimiento,
      moneda: f.moneda,
      importe,
      pagado,
      saldo,
      dias_atraso: dias,
      estado: estadoCalculado,
    };
  });

  // Totales por moneda: excluir canceladas a menos que el filtro sea explícitamente cancelada
  const itemsParaTotales = filtros.estado === "cancelada"
    ? items
    : items.filter((it: any) => it.estado !== "cancelada");

  const mxnItems = itemsParaTotales.filter((it: any) => it.moneda === "MXN");
  const usdItems = itemsParaTotales.filter((it: any) => it.moneda === "USD");

  const totalesMXN = {
    total: redondearCentavos(mxnItems.reduce((acc: number, it: any) => acc + it.importe, 0)),
    pagado: redondearCentavos(mxnItems.reduce((acc: number, it: any) => acc + it.pagado, 0)),
    saldo: redondearCentavos(mxnItems.reduce((acc: number, it: any) => acc + it.saldo, 0)),
    cantidad: mxnItems.length,
  };

  const totalesUSD = {
    total: redondearCentavos(usdItems.reduce((acc: number, it: any) => acc + it.importe, 0)),
    pagado: redondearCentavos(usdItems.reduce((acc: number, it: any) => acc + it.pagado, 0)),
    saldo: redondearCentavos(usdItems.reduce((acc: number, it: any) => acc + it.saldo, 0)),
    cantidad: usdItems.length,
  };

  const equivalentePesos = sinTipoCambio
    ? (totalesUSD.total > 0 ? null : totalesMXN.total)
    : redondearCentavos(totalesMXN.total + (totalesUSD.total * tcUSD));

  const saldoEquivalentePesos = sinTipoCambio
    ? (totalesUSD.saldo > 0 ? null : totalesMXN.saldo)
    : redondearCentavos(totalesMXN.saldo + (totalesUSD.saldo * tcUSD));

  return {
    corte: fechaCorte,
    tc_vigente: { valor: sinTipoCambio ? null : tcUSD, fecha: tcFecha, sin_tipo_cambio: sinTipoCambio },
    totales_mxn: totalesMXN,
    totales_usd: totalesUSD,
    equivalente_pesos: equivalentePesos,
    saldo_equivalente_pesos: saldoEquivalentePesos,
    truncado,
    items,
  };
}
