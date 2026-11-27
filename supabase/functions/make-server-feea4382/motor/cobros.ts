import type { SupabaseClient } from "npm:@supabase/supabase-js";

export type EstatusParcialidad = "pagada" | "vencida" | "parcial" | "pendiente";

export interface PagoAplicacionDto {
  id?: string;
  pago_id?: string;
  orden_trabajo_id: string;
  monto: number;
}

export interface CobroDto {
  id: string;
  organizacion_id?: string;
  cotizacion_id: string;
  tipo_pago: string;
  referencia?: string | null;
  monto: number;
  fecha: string;
  estado: "vigente" | "anulado";
  anulado_at?: string | null;
  anulado_por?: string | null;
  motivo_anulacion?: string | null;
  notas?: string | null;
  descripcion_especie?: string | null;
  created_at?: string;
  aplicaciones?: PagoAplicacionDto[];
}

export interface ParcialidadInput {
  id?: string;
  numero: number;
  fecha_vencimiento: string;
  monto: number;
  nota?: string | null;
}

export interface ParcialidadEstadoDto extends ParcialidadInput {
  monto_cubierto: number;
  monto_pendiente: number;
  estatus: EstatusParcialidad;
}

export interface PlanPagoDto {
  id: string;
  cotizacion_id: string;
  orden_trabajo_id?: string | null;
  nombre: string;
  notas?: string | null;
  activo: boolean;
  parcialidades: ParcialidadEstadoDto[];
}

export interface EquipoResumenCobranzaDto {
  orden_trabajo_id: string;
  nomenclatura_id?: string | null;
  modelo?: string | null;
  tipo_equipo?: string | null;
  valor_pactado?: number | null;
  notas_valor?: string | null;
  cobrado_asignado: number;
  saldo_equipo?: number | null;
}

export interface CobranzaCotizacionDto {
  cotizacion: {
    id: string;
    folio: string;
    estado: string;
    total: number;
    cliente_id?: string | null;
    cliente_nombre?: string | null;
  };
  resumen: {
    total: number;
    cobrado_vigente: number;
    saldo_pendiente: number;
    saldo_a_favor: number;
    sin_asignar_equipo: number;
  };
  equipos: EquipoResumenCobranzaDto[];
  cobros: CobroDto[];
  plan_activo: PlanPagoDto | null;
}

export interface CobranzaEquipoDto {
  orden: {
    id: string;
    nomenclatura_id?: string | null;
    modelo?: string | null;
    tipo_equipo?: string | null;
    cotizacion_id?: string | null;
    es_manual: boolean;
  };
  valor_pactado: number | null;
  notas_valor: string | null;
  cobrado_asignado: number;
  saldo_equipo: number | null;
  cobranza_cotizacion: CobranzaCotizacionDto | null;
}

function redondear2(n: number): number {
  if (!Number.isFinite(n)) return 0;
  const r = Math.round((n + Math.sign(n) * Number.EPSILON) * 100) / 100;
  return r === 0 ? 0 : r;
}

function saldoCotizacion(
  total: number,
  cobros: ReadonlyArray<{ monto: number; estado?: string | null }>,
): { total: number; cobrado: number; saldo: number; saldo_a_favor: number } {
  const totalR = redondear2(Math.max(0, total));
  let suma = 0;
  for (const c of cobros) {
    if (c.estado === "anulado") continue;
    const m = Number(c.monto);
    if (Number.isFinite(m) && m > 0) suma += m;
  }
  const cobrado = redondear2(suma);
  return {
    total: totalR,
    cobrado,
    saldo: redondear2(Math.max(0, totalR - cobrado)),
    saldo_a_favor: redondear2(Math.max(0, cobrado - totalR)),
  };
}

export function estatusParcialidad(
  monto: number,
  montoCubierto: number,
  fechaVencimiento: string,
  hoy: string,
): EstatusParcialidad {
  if (montoCubierto >= monto - 0.005) return "pagada";
  if (fechaVencimiento < hoy) return "vencida";
  if (montoCubierto > 0.005) return "parcial";
  return "pendiente";
}

export function imputarCobrosAParcialidades(
  parcialidades: ReadonlyArray<ParcialidadInput>,
  totalCobradoVigente: number,
  hoy: string,
): ParcialidadEstadoDto[] {
  const ordenadas = [...parcialidades].sort((a, b) => {
    if (a.fecha_vencimiento !== b.fecha_vencimiento) {
      return a.fecha_vencimiento < b.fecha_vencimiento ? -1 : 1;
    }
    return a.numero - b.numero;
  });
  let disponible = redondear2(Math.max(0, totalCobradoVigente));
  return ordenadas.map((p) => {
    const monto = redondear2(Math.max(0, p.monto));
    const cubierto = redondear2(Math.min(monto, disponible));
    disponible = redondear2(Math.max(0, disponible - cubierto));
    return {
      ...p,
      monto,
      monto_cubierto: cubierto,
      monto_pendiente: redondear2(Math.max(0, monto - cubierto)),
      estatus: estatusParcialidad(monto, cubierto, p.fecha_vencimiento, hoy),
    };
  });
}

export function validarPlanParcialidades(
  parcialidades: ReadonlyArray<{ numero: number; fecha_vencimiento: string; monto: number }>,
  limiteTotal?: number | null,
): { valido: boolean; error?: string } {
  if (parcialidades.length === 0) {
    return { valido: false, error: "El plan debe incluir al menos una parcialidad." };
  }
  const numeros = new Set<number>();
  let suma = 0;
  for (const p of parcialidades) {
    if (!Number.isInteger(p.numero) || p.numero < 1) {
      return { valido: false, error: "Cada parcialidad debe tener un número entero >= 1." };
    }
    if (numeros.has(p.numero)) {
      return { valido: false, error: "No puede haber números de parcialidad repetidos." };
    }
    numeros.add(p.numero);
    if (!/^\d{4}-\d{2}-\d{2}$/.test(p.fecha_vencimiento)) {
      return { valido: false, error: "Cada parcialidad debe tener una fecha válida (YYYY-MM-DD)." };
    }
    const m = redondear2(Number(p.monto));
    if (!Number.isFinite(m) || m <= 0) {
      return { valido: false, error: "El monto de cada parcialidad debe ser mayor a cero." };
    }
    suma = redondear2(suma + m);
  }
  if (limiteTotal != null && Number.isFinite(limiteTotal) && suma > redondear2(limiteTotal) + 0.005) {
    return { valido: false, error: `La suma de parcialidades (${suma}) excede el total (${redondear2(limiteTotal)}).` };
  }
  return { valido: true };
}

export class CobrosError extends Error {
  status: number;
  codigo: string;
  extra?: Record<string, unknown>;

  constructor(status: number, codigo: string, message: string, extra?: Record<string, unknown>) {
    super(message);
    this.status = status;
    this.codigo = codigo;
    this.extra = extra;
  }
}

export function hoyMexicoIso(): string {
  const fmt = new Intl.DateTimeFormat("en-CA", {
    timeZone: "America/Mexico_City",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  });
  return fmt.format(new Date());
}

export function mapearErrorRpcCobros(err: unknown): CobrosError {
  const msg = String((err as { message?: string })?.message || err || "Error inesperado en cobranza");
  if (msg.includes("cotizacion_no_encontrada")) {
    return new CobrosError(404, "cotizacion_no_encontrada", msg);
  }
  if (msg.includes("plan_no_encontrado")) {
    return new CobrosError(404, "plan_no_encontrado", msg);
  }
  if (msg.includes("orden_cancelada")) {
    return new CobrosError(409, "orden_cancelada", msg);
  }
  if (msg.includes("cotizacion_no_cobrable")) {
    return new CobrosError(409, "cotizacion_no_cobrable", msg);
  }
  if (msg.includes("saldo_excedido")) {
    return new CobrosError(409, "saldo_excedido", msg, { requiere_confirmacion_saldo_a_favor: true });
  }
  if (msg.includes("cobro_no_encontrado")) {
    return new CobrosError(404, "cobro_no_encontrado", msg);
  }
  if (
    msg.includes("monto_invalido") ||
    msg.includes("metodo_pago_invalido") ||
    msg.includes("tipo_pago_invalido") ||
    msg.includes("especie_sin_descripcion") ||
    msg.includes("fecha_futura_invalida") ||
    msg.includes("fecha_invalida") ||
    msg.includes("aplicacion_monto_invalido") ||
    msg.includes("aplicaciones_exceden_monto") ||
    msg.includes("aplicacion_orden_invalida") ||
    msg.includes("aplicacion_duplicada") ||
    msg.includes("orden_no_pertenece_cotizacion") ||
    msg.includes("plan_excede_total") ||
    msg.includes("plan_sin_parcialidades") ||
    msg.includes("numero_parcialidad_duplicado") ||
    msg.includes("numero_parcialidad_invalido") ||
    msg.includes("motivo_requerido") ||
    msg.includes("org_requerida")
  ) {
    const codigo = msg.split(":")[0]?.trim() || "validacion_cobro";
    return new CobrosError(400, codigo, msg);
  }
  return new CobrosError(500, "error_interno", msg);
}

export async function listarPagosPaginados(
  supabase: SupabaseClient,
  orgId: string,
  opts: { cotizacionId?: string; incluirAnulados?: boolean } = {},
): Promise<CobroDto[]> {
  const pageSize = 1000;
  let offset = 0;
  const todos: CobroDto[] = [];

  while (true) {
    let q = supabase
      .from("pagos")
      .select("*")
      .eq("organizacion_id", orgId)
      .order("fecha", { ascending: false })
      .order("created_at", { ascending: false })
      .order("id", { ascending: false })
      .range(offset, offset + pageSize - 1);

    if (opts.cotizacionId) {
      q = q.eq("cotizacion_id", opts.cotizacionId);
    }
    if (!opts.incluirAnulados) {
      q = q.neq("estado", "anulado");
    }

    const { data, error } = await q;
    if (error) throw error;
    const chunk = (data || []) as CobroDto[];
    todos.push(...chunk);
    if (chunk.length < pageSize) break;
    offset += pageSize;
  }

  return todos;
}

export async function registrarCobro(
  serviceClient: SupabaseClient,
  orgId: string,
  userId: string | null,
  payload: {
    cotizacion_id: string;
    monto: number;
    fecha?: string;
    tipo_pago: string;
    referencia?: string | null;
    notas?: string | null;
    descripcion_especie?: string | null;
    aplicaciones?: Array<{ orden_trabajo_id: string; monto: number }>;
    permitir_saldo_a_favor?: boolean;
  },
) {
  const fecha = payload.fecha || hoyMexicoIso();
  const { data, error } = await serviceClient.rpc("registrar_cobro", {
    p_org_id: orgId,
    p_cotizacion_id: payload.cotizacion_id,
    p_monto: Number(payload.monto),
    p_fecha: fecha,
    p_tipo_pago: payload.tipo_pago,
    p_referencia: payload.referencia ?? null,
    p_notas: payload.notas ?? null,
    p_descripcion_especie: payload.descripcion_especie ?? null,
    p_aplicaciones: payload.aplicaciones ?? [],
    p_permitir_saldo_a_favor: Boolean(payload.permitir_saldo_a_favor),
    p_usuario_id: userId ?? null,
  });

  if (error) throw mapearErrorRpcCobros(error);
  return data;
}

export async function anularCobro(
  serviceClient: SupabaseClient,
  orgId: string,
  userId: string | null,
  pagoId: string,
  motivo: string,
) {
  const { data, error } = await serviceClient.rpc("anular_cobro", {
    p_org_id: orgId,
    p_pago_id: pagoId,
    p_motivo: motivo,
    p_usuario_id: userId ?? null,
  });

  if (error) throw mapearErrorRpcCobros(error);
  return data;
}

export async function obtenerCobranzaCotizacion(
  supabase: SupabaseClient,
  orgId: string,
  cotizacionId: string,
  hoyOverride?: string,
): Promise<CobranzaCotizacionDto> {
  const { data: cot, error: cotErr } = await supabase
    .from("cotizaciones")
    .select("id, folio, estado, total, cliente_id")
    .eq("id", cotizacionId)
    .eq("organizacion_id", orgId)
    .single();

  if (cotErr || !cot) {
    throw new CobrosError(404, "cotizacion_no_encontrada", "Cotización no encontrada en tu organización.");
  }

  let clienteNombre: string | null = null;
  if (cot.cliente_id) {
    const { data: cli } = await supabase
      .from("clientes")
      .select("nombre_razon_social")
      .eq("id", cot.cliente_id)
      .eq("organizacion_id", orgId)
      .maybeSingle();
    clienteNombre = cli?.nombre_razon_social ?? null;
  }

  const [{ data: ordenes, error: ordErr }, cobros, { data: planes, error: planErr }] = await Promise.all([
    supabase
      .from("ordenes_trabajo")
      .select("id, nomenclatura_id, modelo, tipo_equipo")
      .eq("cotizacion_id", cotizacionId)
      .eq("organizacion_id", orgId)
      .is("cancelada_el", null)
      .order("created_at", { ascending: true }),
    listarPagosPaginados(supabase, orgId, { cotizacionId, incluirAnulados: true }),
    supabase
      .from("planes_pago")
      .select("*")
      .eq("cotizacion_id", cotizacionId)
      .eq("organizacion_id", orgId)
      .eq("activo", true)
      .is("orden_trabajo_id", null)
      .order("created_at", { ascending: false })
      .limit(1),
  ]);

  if (ordErr) throw ordErr;
  if (planErr) throw planErr;

  const ordenIds = (ordenes || []).map((o: { id: string }) => o.id);
  const pagoIds = cobros.map((c) => c.id);

  let valoresPorOrden = new Map<string, { valor_pactado: number | null; notas: string | null }>();
  if (ordenIds.length > 0) {
    const { data: valores, error: valErr } = await supabase
      .from("equipo_valor_cobranza")
      .select("orden_trabajo_id, valor_pactado, notas")
      .eq("organizacion_id", orgId)
      .in("orden_trabajo_id", ordenIds);
    if (valErr) throw valErr;
    for (const v of valores || []) {
      valoresPorOrden.set(v.orden_trabajo_id, {
        valor_pactado: v.valor_pactado != null ? Number(v.valor_pactado) : null,
        notas: v.notas ?? null,
      });
    }
  }

  let appsPorPago = new Map<string, PagoAplicacionDto[]>();
  const cobradoPorOrden = new Map<string, number>();
  let totalAsignadoVigente = 0;

  if (pagoIds.length > 0) {
    const { data: apps, error: appsErr } = await supabase
      .from("pago_aplicaciones")
      .select("id, pago_id, orden_trabajo_id, monto")
      .eq("organizacion_id", orgId)
      .in("pago_id", pagoIds);
    if (appsErr) throw appsErr;

    const pagosVigentes = new Set(cobros.filter((c) => c.estado !== "anulado").map((c) => c.id));
    for (const a of apps || []) {
      const monto = redondear2(Number(a.monto));
      const arr = appsPorPago.get(a.pago_id) || [];
      arr.push({ id: a.id, pago_id: a.pago_id, orden_trabajo_id: a.orden_trabajo_id, monto });
      appsPorPago.set(a.pago_id, arr);

      if (pagosVigentes.has(a.pago_id)) {
        cobradoPorOrden.set(
          a.orden_trabajo_id,
          redondear2((cobradoPorOrden.get(a.orden_trabajo_id) || 0) + monto),
        );
        totalAsignadoVigente = redondear2(totalAsignadoVigente + monto);
      }
    }
  }

  const cobrosConApps: CobroDto[] = cobros.map((c) => ({
    ...c,
    monto: redondear2(Number(c.monto)),
    estado: (c.estado === "anulado" ? "anulado" : "vigente"),
    aplicaciones: appsPorPago.get(c.id) || [],
  }));

  const resumenSaldo = saldoCotizacion(Number(cot.total || 0), cobrosConApps);
  const sinAsignar = redondear2(Math.max(0, resumenSaldo.cobrado - totalAsignadoVigente));

  const equipos = (ordenes || []).map((o: { id: string; nomenclatura_id?: string; modelo?: string; tipo_equipo?: string }) => {
    const val = valoresPorOrden.get(o.id);
    const cobradoEq = redondear2(cobradoPorOrden.get(o.id) || 0);
    const valorPactado = val?.valor_pactado ?? null;
    const saldoEquipo = valorPactado != null ? redondear2(Math.max(0, valorPactado - cobradoEq)) : null;
    return {
      orden_trabajo_id: o.id,
      nomenclatura_id: o.nomenclatura_id ?? null,
      modelo: o.modelo ?? null,
      tipo_equipo: o.tipo_equipo ?? null,
      valor_pactado: valorPactado,
      notas_valor: val?.notas ?? null,
      cobrado_asignado: cobradoEq,
      saldo_equipo: saldoEquipo,
    };
  });

  let planActivo: PlanPagoDto | null = null;
  const planRow = planes?.[0];
  if (planRow) {
    const { data: parcs, error: parcErr } = await supabase
      .from("plan_pagos_parcialidades")
      .select("id, numero, fecha_vencimiento, monto, nota")
      .eq("plan_id", planRow.id)
      .eq("organizacion_id", orgId)
      .order("fecha_vencimiento", { ascending: true })
      .order("numero", { ascending: true });
    if (parcErr) throw parcErr;

    const hoy = hoyOverride || hoyMexicoIso();
    planActivo = {
      id: planRow.id,
      cotizacion_id: planRow.cotizacion_id,
      orden_trabajo_id: planRow.orden_trabajo_id ?? null,
      nombre: planRow.nombre,
      notas: planRow.notas ?? null,
      activo: Boolean(planRow.activo),
      parcialidades: imputarCobrosAParcialidades(
        (parcs || []).map((p: { id: string; numero: number; fecha_vencimiento: string; monto: number; nota?: string | null }) => ({
          id: p.id,
          numero: p.numero,
          fecha_vencimiento: p.fecha_vencimiento,
          monto: Number(p.monto),
          nota: p.nota ?? null,
        })),
        resumenSaldo.cobrado,
        hoy,
      ),
    };
  }

  return {
    cotizacion: {
      id: cot.id,
      folio: cot.folio,
      estado: cot.estado,
      total: resumenSaldo.total,
      cliente_id: cot.cliente_id ?? null,
      cliente_nombre: clienteNombre,
    },
    resumen: {
      total: resumenSaldo.total,
      cobrado_vigente: resumenSaldo.cobrado,
      saldo_pendiente: resumenSaldo.saldo,
      saldo_a_favor: resumenSaldo.saldo_a_favor,
      sin_asignar_equipo: sinAsignar,
    },
    equipos,
    cobros: cobrosConApps,
    plan_activo: planActivo,
  };
}

export async function obtenerCobranzaEquipo(
  supabase: SupabaseClient,
  orgId: string,
  ordenId: string,
  hoyOverride?: string,
): Promise<CobranzaEquipoDto> {
  const { data: orden, error: ordErr } = await supabase
    .from("ordenes_trabajo")
    .select("id, nomenclatura_id, modelo, tipo_equipo, cotizacion_id, cancelada_el")
    .eq("id", ordenId)
    .eq("organizacion_id", orgId)
    .single();

  if (ordErr || !orden || orden.cancelada_el) {
    throw new CobrosError(404, "orden_no_encontrada", "Orden de trabajo no encontrada en tu organización.");
  }

  let cobranzaCot: CobranzaCotizacionDto | null = null;
  if (orden.cotizacion_id) {
    cobranzaCot = await obtenerCobranzaCotizacion(supabase, orgId, orden.cotizacion_id, hoyOverride);
  }

  const eq = cobranzaCot?.equipos.find((e) => e.orden_trabajo_id === orden.id);
  let valorPactado = eq?.valor_pactado ?? null;
  let notasValor = eq?.notas_valor ?? null;
  let cobradoAsignado = eq?.cobrado_asignado ?? 0;

  if (!cobranzaCot) {
    const { data: val } = await supabase
      .from("equipo_valor_cobranza")
      .select("valor_pactado, notas")
      .eq("orden_trabajo_id", orden.id)
      .eq("organizacion_id", orgId)
      .maybeSingle();
    valorPactado = val?.valor_pactado != null ? Number(val.valor_pactado) : null;
    notasValor = val?.notas ?? null;
  }

  const saldoEquipo = valorPactado != null ? redondear2(Math.max(0, valorPactado - cobradoAsignado)) : null;

  return {
    orden: {
      id: orden.id,
      nomenclatura_id: orden.nomenclatura_id ?? null,
      modelo: orden.modelo ?? null,
      tipo_equipo: orden.tipo_equipo ?? null,
      cotizacion_id: orden.cotizacion_id ?? null,
      es_manual: !orden.cotizacion_id,
    },
    valor_pactado: valorPactado,
    notas_valor: notasValor,
    cobrado_asignado: cobradoAsignado,
    saldo_equipo: saldoEquipo,
    cobranza_cotizacion: cobranzaCot,
  };
}

export async function guardarValorEquipo(
  supabase: SupabaseClient,
  orgId: string,
  ordenId: string,
  valorPactado: number | null,
  notas?: string | null,
) {
  const { data: orden, error: ordErr } = await supabase
    .from("ordenes_trabajo")
    .select("id, cancelada_el")
    .eq("id", ordenId)
    .eq("organizacion_id", orgId)
    .single();
  if (ordErr || !orden) {
    throw new CobrosError(404, "orden_no_encontrada", "Orden de trabajo no encontrada en tu organización.");
  }
  if (orden.cancelada_el) {
    throw new CobrosError(409, "orden_cancelada", "No se puede modificar el valor de cobranza de un equipo cancelado.");
  }

  if (valorPactado === null) {
    const { error } = await supabase
      .from("equipo_valor_cobranza")
      .delete()
      .eq("orden_trabajo_id", ordenId)
      .eq("organizacion_id", orgId);
    if (error) throw error;
    return { orden_trabajo_id: ordenId, valor_pactado: null, notas: null };
  }

  const val = redondear2(Number(valorPactado));
  if (!Number.isFinite(val) || val <= 0) {
    throw new CobrosError(400, "valor_invalido", "El valor pactado del equipo debe ser mayor a cero.");
  }

  const { data: existente } = await supabase
    .from("equipo_valor_cobranza")
    .select("orden_trabajo_id")
    .eq("orden_trabajo_id", ordenId)
    .eq("organizacion_id", orgId)
    .maybeSingle();

  const payloadValor = {
    organizacion_id: orgId,
    orden_trabajo_id: ordenId,
    valor_pactado: val,
    notas: notas ?? null,
    updated_at: new Date().toISOString(),
  };

  const { data, error } = existente
    ? await supabase
        .from("equipo_valor_cobranza")
        .update(payloadValor)
        .eq("orden_trabajo_id", ordenId)
        .eq("organizacion_id", orgId)
        .select()
        .single()
    : await supabase
        .from("equipo_valor_cobranza")
        .insert(payloadValor)
        .select()
        .single();
  if (error) throw error;
  return data;
}

export async function listarPlanesPago(
  supabase: SupabaseClient,
  orgId: string,
  filters: { cotizacionId?: string; ordenId?: string } = {},
) {
  let q = supabase
    .from("planes_pago")
    .select("*, plan_pagos_parcialidades(*), orden_trabajo:ordenes_trabajo(id, cancelada_el)")
    .eq("organizacion_id", orgId)
    .order("created_at", { ascending: false });

  if (filters.cotizacionId) q = q.eq("cotizacion_id", filters.cotizacionId);
  if (filters.ordenId) q = q.eq("orden_trabajo_id", filters.ordenId);

  const { data, error } = await q;
  if (error) throw error;
  return (data || [])
    .filter((p: any) => !p.orden_trabajo_id || !p.orden_trabajo?.cancelada_el)
    .map(({ orden_trabajo: _ot, ...rest }: any) => rest);
}

export async function crearPlanPago(
  serviceClient: SupabaseClient,
  orgId: string,
  payload: {
    cotizacion_id: string;
    orden_trabajo_id?: string | null;
    nombre?: string;
    notas?: string | null;
    parcialidades: Array<{ numero: number; fecha_vencimiento: string; monto: number; nota?: string | null }>;
  },
) {
  const { data: cot, error: cotErr } = await serviceClient
    .from("cotizaciones")
    .select("id, total")
    .eq("id", payload.cotizacion_id)
    .eq("organizacion_id", orgId)
    .single();
  if (cotErr || !cot) {
    throw new CobrosError(404, "cotizacion_no_encontrada", "Cotización no encontrada en tu organización.");
  }

  let limite = Number(cot.total || 0);
  if (payload.orden_trabajo_id) {
    const { data: val } = await serviceClient
      .from("equipo_valor_cobranza")
      .select("valor_pactado")
      .eq("orden_trabajo_id", payload.orden_trabajo_id)
      .eq("organizacion_id", orgId)
      .maybeSingle();
    if (val?.valor_pactado != null) {
      limite = Number(val.valor_pactado);
    }
  }

  const check = validarPlanParcialidades(payload.parcialidades || [], limite);
  if (!check.valido) {
    throw new CobrosError(400, "plan_excede_total", check.error || "Plan de pagos inválido.");
  }

  const { data, error } = await serviceClient.rpc("guardar_plan_pago", {
    p_org_id: orgId,
    p_cotizacion_id: payload.cotizacion_id,
    p_plan_id: null,
    p_orden_trabajo_id: payload.orden_trabajo_id ?? null,
    p_nombre: (payload.nombre || "Plan de pagos").trim(),
    p_notas: payload.notas ?? null,
    p_parcialidades: payload.parcialidades ?? [],
  });
  if (error) throw mapearErrorRpcCobros(error);
  return data;
}

export async function actualizarPlanPago(
  serviceClient: SupabaseClient,
  orgId: string,
  planId: string,
  payload: {
    nombre?: string;
    notas?: string | null;
    activo?: boolean;
    parcialidades?: Array<{ numero: number; fecha_vencimiento: string; monto: number; nota?: string | null }>;
  },
) {
  const { data: plan, error: planErr } = await serviceClient
    .from("planes_pago")
    .select("id, cotizacion_id, orden_trabajo_id, nombre, notas")
    .eq("id", planId)
    .eq("organizacion_id", orgId)
    .single();
  if (planErr || !plan) {
    throw new CobrosError(404, "plan_no_encontrado", "Plan de pagos no encontrado.");
  }

  if (payload.parcialidades) {
    const { data: cot } = await serviceClient
      .from("cotizaciones")
      .select("total")
      .eq("id", plan.cotizacion_id)
      .eq("organizacion_id", orgId)
      .single();
    let limite = Number(cot?.total || 0);
    if (plan.orden_trabajo_id) {
      const { data: val } = await serviceClient
        .from("equipo_valor_cobranza")
        .select("valor_pactado")
        .eq("orden_trabajo_id", plan.orden_trabajo_id)
        .eq("organizacion_id", orgId)
        .maybeSingle();
      if (val?.valor_pactado != null) limite = Number(val.valor_pactado);
    }
    const check = validarPlanParcialidades(payload.parcialidades, limite);
    if (!check.valido) {
      throw new CobrosError(400, "plan_excede_total", check.error || "Plan de pagos inválido.");
    }

    const { data, error } = await serviceClient.rpc("guardar_plan_pago", {
      p_org_id: orgId,
      p_cotizacion_id: plan.cotizacion_id,
      p_plan_id: planId,
      p_orden_trabajo_id: plan.orden_trabajo_id ?? null,
      p_nombre: (payload.nombre !== undefined ? payload.nombre : plan.nombre || "Plan de pagos").trim(),
      p_notas: payload.notas !== undefined ? payload.notas : (plan.notas ?? null),
      p_parcialidades: payload.parcialidades,
    });
    if (error) throw mapearErrorRpcCobros(error);
    return data;
  }

  const updateFields: Record<string, unknown> = { updated_at: new Date().toISOString() };
  if (payload.nombre !== undefined) updateFields.nombre = payload.nombre.trim();
  if (payload.notas !== undefined) updateFields.notas = payload.notas;
  if (payload.activo !== undefined) updateFields.activo = payload.activo;

  const { data: updated, error: updErr } = await serviceClient
    .from("planes_pago")
    .update(updateFields)
    .eq("id", planId)
    .eq("organizacion_id", orgId)
    .select()
    .single();
  if (updErr) throw updErr;
  return updated;
}

export async function eliminarPlanPago(
  supabase: SupabaseClient,
  orgId: string,
  planId: string,
) {
  const { data, error } = await supabase
    .from("planes_pago")
    .delete()
    .eq("id", planId)
    .eq("organizacion_id", orgId)
    .select("id")
    .maybeSingle();
  if (error) throw error;
  if (!data) {
    throw new CobrosError(404, "plan_no_encontrado", "Plan de pagos no encontrado.");
  }
  return { ok: true, id: data.id };
}
