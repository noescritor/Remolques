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

// ── AUXILIARES DE VALIDACIÓN ──

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
    : new Date().toISOString().slice(0, 10);

  if (corte && !esFechaValida(corte)) {
    const err: any = new Error("Fecha de corte inválida (formato YYYY-MM-DD)");
    err.status = 400;
    throw err;
  }

  // Resolver tipo de cambio: tcManual > último en tipos_cambio > null
  let tcUSD: number | null = null;
  if (tcManual !== undefined && tcManual !== null) {
    if (isNaN(tcManual) || tcManual <= 0) {
      const err: any = new Error("El tipo de cambio debe ser un número mayor a 0");
      err.status = 400;
      throw err;
    }
    tcUSD = Number(tcManual);
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

  // Cargar facturas abiertas con sus pagos no anulados
  const { data: facturas, error: errF } = await supabase
    .from("facturas_proveedor")
    .select(`
      id, proveedor_id, folio, sucursal, fecha_emision, fecha_vencimiento,
      moneda, importe, estado,
      proveedor:proveedores(id, nombre, razon_social, rfc, moneda_default, dias_credito, limite_credito, limite_credito_moneda),
      pagos:pagos_factura(monto, fecha_pago, anulado)
    `)
    .eq("organizacion_id", orgId)
    .neq("estado", "cancelada");

  if (errF) {
    throw new Error(`Error al consultar facturas: ${errF.message}`);
  }

  const facturasRef: FacturaRef[] = (facturas || []).map((f: any) => ({
    id: f.id,
    folio: f.folio,
    sucursal: f.sucursal,
    fecha_emision: f.fecha_emision,
    fecha_vencimiento: f.fecha_vencimiento,
    moneda: f.moneda,
    importe: Number(f.importe),
    estado: f.estado,
    pagos: (f.pagos || []).map((p: any) => ({
      monto: Number(p.monto),
      fecha_pago: p.fecha_pago,
      anulado: p.anulado,
    })),
  }));

  // Resumen general
  const resumenGeneral = resumenCuenta(facturasRef, {
    fechaCorte,
    tcUSD,
  });

  // Agrupar por proveedor
  const provMap: Record<string, { proveedor: any; facturas: FacturaRef[] }> = {};
  for (const f of facturas || []) {
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
      pagos: (f.pagos || []).map((p: any) => ({
        monto: Number(p.monto),
        fecha_pago: p.fecha_pago,
        anulado: p.anulado,
      })),
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
  }
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
    .limit(500);

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

  const hoyStr = new Date().toISOString().slice(0, 10);
  const filtradas = (data || []).map((f: any) => {
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

  return resultado;
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

  const diasCredito = payload.dias_credito !== undefined ? Number(payload.dias_credito) : 30;
  if (isNaN(diasCredito) || diasCredito < 0) {
    const err: any = new Error("Los días de crédito deben ser un entero mayor o igual a 0");
    err.status = 400;
    throw err;
  }

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

  const importe = Number(payload.importe);
  if (isNaN(importe) || importe <= 0) {
    const err: any = new Error("El importe de la factura debe ser mayor a 0");
    err.status = 400;
    throw err;
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

  const tienePagosActivos = (fExistente.pagos || []).some((p: any) => !p.anulado);

  // 2. Si tiene pagos activos, no se puede modificar moneda, importe ni proveedor_id
  if (tienePagosActivos) {
    if (payload.moneda && payload.moneda !== fExistente.moneda) {
      const err: any = new Error("No se puede cambiar la moneda de una factura que ya tiene pagos registrados");
      err.status = 409;
      throw err;
    }
    if (payload.importe !== undefined && Number(payload.importe) !== Number(fExistente.importe)) {
      const err: any = new Error("No se puede cambiar el importe de una factura que ya tiene pagos registrados");
      err.status = 409;
      throw err;
    }
    if (payload.proveedor_id && payload.proveedor_id !== fExistente.proveedor_id) {
      const err: any = new Error("No se puede cambiar el proveedor de una factura que ya tiene pagos registrados");
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
    if (isNaN(dias) || dias < 0) {
      const err: any = new Error("Días de crédito inválidos");
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
      if (isNaN(imp) || imp <= 0) {
        const err: any = new Error("El importe debe ser mayor a 0");
        err.status = 400;
        throw err;
      }
      updateData.importe = imp;
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
    updateData.tipo_cambio_emision = payload.tipo_cambio_emision ? Number(payload.tipo_cambio_emision) : null;
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
  supabase: any,
  orgId: string,
  facturaId: string,
  payload: RegistrarPagoPayload
) {
  if (!payload.monto || isNaN(Number(payload.monto)) || Number(payload.monto) <= 0) {
    const err: any = new Error("El monto del pago debe ser mayor a 0");
    err.status = 400;
    throw err;
  }

  if (!esFechaValida(payload.fecha_pago)) {
    const err: any = new Error("Fecha de pago inválida (formato YYYY-MM-DD)");
    err.status = 400;
    throw err;
  }

  // Llamada a la función PostgreSQL registrar_pago_factura
  const { data: res, error: errRpc } = await supabase.rpc("registrar_pago_factura", {
    p_org: orgId,
    p_factura_id: facturaId,
    p_fecha: payload.fecha_pago,
    p_monto: Number(payload.monto),
    p_tipo_cambio: payload.tipo_cambio ? Number(payload.tipo_cambio) : null,
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
  supabase: any,
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

  const { data: res, error: errRpc } = await supabase.rpc("anular_pago_factura", {
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
    .limit(limite);

  if (error) {
    throw new Error(`Error al listar pagos: ${error.message}`);
  }

  return (data || []).map((p: any) => {
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
  if (isNaN(valor) || valor <= 0) {
    const err: any = new Error("El valor del tipo de cambio debe ser mayor a 0");
    err.status = 400;
    throw err;
  }

  const record = {
    organizacion_id: orgId,
    fecha: payload.fecha,
    moneda: "USD",
    valor,
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
      if (isNaN(d) || d < 0) {
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
      if (isNaN(l) || l < 0) {
        const err: any = new Error("limite_credito debe ser un número >= 0");
        err.status = 400;
        throw err;
      }
      updateData.limite_credito = l;
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

  if (payload.saldo === undefined || payload.saldo === null || isNaN(Number(payload.saldo))) {
    const err: any = new Error("El saldo debe ser un número válido");
    err.status = 400;
    throw err;
  }

  const record = {
    organizacion_id: orgId,
    proveedor_id: proveedorId,
    fecha: payload.fecha,
    moneda: payload.moneda,
    saldo: Number(payload.saldo),
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
    : new Date().toISOString().slice(0, 10);

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
