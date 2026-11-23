export type TipoPagoCobro =
  | 'Efectivo'
  | 'Transferencia'
  | 'Cheque'
  | 'Tarjeta'
  | 'Crédito 30 días'
  | 'Especie';

export type EstatusParcialidad = 'pagada' | 'vencida' | 'parcial' | 'pendiente';

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
  tipo_pago: TipoPagoCobro | string;
  referencia?: string | null;
  monto: number;
  fecha: string;
  estado: 'vigente' | 'anulado';
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

export function hoyMexicoIso(now: Date = new Date()): string {
  const fmt = new Intl.DateTimeFormat('en-CA', {
    timeZone: 'America/Mexico_City',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  });
  return fmt.format(now);
}

export function redondear2(n: number): number {
  if (!Number.isFinite(n)) return 0;
  const r = Math.round((n + Math.sign(n) * Number.EPSILON) * 100) / 100;
  return r === 0 ? 0 : r;
}

export function saldoCotizacion(
  total: number,
  cobros: ReadonlyArray<{ monto: number; estado?: string | null }>,
): { total: number; cobrado: number; saldo: number; saldo_a_favor: number } {
  const totalR = redondear2(Math.max(0, total));
  let suma = 0;
  for (const c of cobros) {
    if (c.estado === 'anulado') continue;
    const m = Number(c.monto);
    if (Number.isFinite(m) && m > 0) {
      suma += m;
    }
  }
  const cobrado = redondear2(suma);
  const saldo = redondear2(Math.max(0, totalR - cobrado));
  const saldo_a_favor = redondear2(Math.max(0, cobrado - totalR));
  return { total: totalR, cobrado, saldo, saldo_a_favor };
}

export function estatusParcialidad(
  monto: number,
  montoCubierto: number,
  fechaVencimiento: string,
  hoy: string,
): EstatusParcialidad {
  if (montoCubierto >= monto - 0.005) return 'pagada';
  if (fechaVencimiento < hoy) return 'vencida';
  if (montoCubierto > 0.005) return 'parcial';
  return 'pendiente';
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
    const pendiente = redondear2(Math.max(0, monto - cubierto));
    return {
      ...p,
      monto,
      monto_cubierto: cubierto,
      monto_pendiente: pendiente,
      estatus: estatusParcialidad(monto, cubierto, p.fecha_vencimiento, hoy),
    };
  });
}

export function repartirEnPartesIguales(
  montoTotal: number,
  ordenIds: ReadonlyArray<string>,
): { orden_trabajo_id: string; monto: number }[] {
  if (ordenIds.length === 0 || !Number.isFinite(montoTotal) || montoTotal <= 0) {
    return [];
  }
  const centavosTotales = Math.round(redondear2(montoTotal) * 100);
  const n = ordenIds.length;
  const base = Math.floor(centavosTotales / n);
  const residuo = centavosTotales % n;
  return ordenIds.map((id, idx) => ({
    orden_trabajo_id: id,
    monto: (base + (idx < residuo ? 1 : 0)) / 100,
  }));
}

export function validarAplicaciones(
  montoCobro: number,
  aplicaciones: ReadonlyArray<{ orden_trabajo_id: string; monto: number }>,
  ordenesValidas?: ReadonlySet<string>,
): { valido: boolean; error?: string; suma: number } {
  const vistas = new Set<string>();
  let suma = 0;
  for (const app of aplicaciones) {
    if (!app.orden_trabajo_id) {
      return { valido: false, error: 'Cada aplicación debe indicar un equipo válido.', suma: 0 };
    }
    if (vistas.has(app.orden_trabajo_id)) {
      return { valido: false, error: 'No puedes repetir el mismo equipo en un cobro.', suma: 0 };
    }
    vistas.add(app.orden_trabajo_id);
    if (ordenesValidas && !ordenesValidas.has(app.orden_trabajo_id)) {
      return { valido: false, error: 'Un equipo seleccionado no pertenece a la cotización.', suma: 0 };
    }
    const m = redondear2(Number(app.monto));
    if (!Number.isFinite(m) || m <= 0) {
      return { valido: false, error: 'Cada monto aplicado a equipo debe ser mayor a cero.', suma: 0 };
    }
    suma = redondear2(suma + m);
  }
  if (suma > redondear2(montoCobro) + 0.005) {
    return {
      valido: false,
      error: 'La suma aplicada a equipos excede el monto total del cobro.',
      suma,
    };
  }
  return { valido: true, suma };
}

export function validarPlanParcialidades(
  parcialidades: ReadonlyArray<{ numero: number; fecha_vencimiento: string; monto: number }>,
  limiteTotal?: number | null,
): { valido: boolean; error?: string; suma: number } {
  if (parcialidades.length === 0) {
    return { valido: false, error: 'El plan debe incluir al menos una parcialidad.', suma: 0 };
  }
  const numeros = new Set<number>();
  let suma = 0;
  for (const p of parcialidades) {
    if (!Number.isInteger(p.numero) || p.numero < 1) {
      return { valido: false, error: 'Cada parcialidad debe tener un número entero >= 1.', suma: 0 };
    }
    if (numeros.has(p.numero)) {
      return { valido: false, error: 'No puede haber números de parcialidad repetidos.', suma: 0 };
    }
    numeros.add(p.numero);
    if (!/^\d{4}-\d{2}-\d{2}$/.test(p.fecha_vencimiento)) {
      return { valido: false, error: 'Cada parcialidad debe tener una fecha válida (YYYY-MM-DD).', suma: 0 };
    }
    const m = redondear2(Number(p.monto));
    if (!Number.isFinite(m) || m <= 0) {
      return { valido: false, error: 'El monto de cada parcialidad debe ser mayor a cero.', suma: 0 };
    }
    suma = redondear2(suma + m);
  }
  if (limiteTotal != null && Number.isFinite(limiteTotal) && suma > redondear2(limiteTotal) + 0.005) {
    return {
      valido: false,
      error: `La suma de parcialidades ($${suma.toLocaleString('es-MX', { minimumFractionDigits: 2 })}) excede el total ($${redondear2(limiteTotal).toLocaleString('es-MX', { minimumFractionDigits: 2 })}).`,
      suma,
    };
  }
  return { valido: true, suma };
}

export function validarDatosCobro(input: {
  monto: number;
  tipo_pago: string;
  descripcion_especie?: string | null;
  saldoPendiente: number;
  permitirSaldoAFavor?: boolean;
}): {
  valido: boolean;
  requiereConfirmacionSaldoAFavor?: boolean;
  excedente?: number;
  error?: string;
} {
  const monto = redondear2(Number(input.monto));
  if (!Number.isFinite(monto) || monto <= 0) {
    return { valido: false, error: 'El monto del cobro debe ser mayor a cero.' };
  }
  if (input.tipo_pago === 'Especie' && !String(input.descripcion_especie ?? '').trim()) {
    return { valido: false, error: 'Describe el bien o servicio recibido en especie.' };
  }
  const excedente = redondear2(monto - redondear2(Math.max(0, input.saldoPendiente)));
  if (excedente > 0.005 && !input.permitirSaldoAFavor) {
    return {
      valido: false,
      requiereConfirmacionSaldoAFavor: true,
      excedente,
      error: `El cobro excede el saldo pendiente por $${excedente.toLocaleString('es-MX', { minimumFractionDigits: 2 })}.`,
    };
  }
  return { valido: true, excedente: Math.max(0, excedente) };
}

export function traducirErrorCobros(err: unknown): string {
  const raw = err instanceof Error ? err.message : String(err ?? '');
  if (raw.includes('cotizacion_no_cobrable')) {
    return 'Solo se pueden registrar cobros en cotizaciones aprobadas o pagadas.';
  }
  if (raw.includes('especie_sin_descripcion')) {
    return 'Para cobros en especie debes describir el bien o servicio recibido.';
  }
  if (raw.includes('saldo_excedido')) {
    return 'El monto excede el saldo pendiente. Confirma si deseas registrarlo como saldo a favor.';
  }
  if (raw.includes('aplicaciones_exceden_monto')) {
    return 'La suma aplicada a equipos supera el monto total del cobro.';
  }
  if (raw.includes('aplicacion_monto_invalido')) {
    return 'Cada monto aplicado a equipo debe ser mayor a cero.';
  }
  if (raw.includes('metodo_pago_invalido') || raw.includes('tipo_pago_invalido')) {
    return 'El método de pago seleccionado no es válido.';
  }
  if (raw.includes('aplicacion_duplicada')) {
    return 'No puedes repetir el mismo equipo en un cobro.';
  }
  if (raw.includes('orden_no_pertenece_cotizacion') || raw.includes('aplicacion_orden_invalida')) {
    return 'Uno de los equipos seleccionados no pertenece a esta cotización.';
  }
  if (raw.includes('fecha_invalida')) {
    return 'Una de las fechas indicadas no es válida.';
  }
  if (raw.includes('plan_sin_parcialidades')) {
    return 'El plan de pagos debe incluir al menos una parcialidad.';
  }
  if (raw.includes('numero_parcialidad_duplicado') || raw.includes('numero_parcialidad_invalido')) {
    return 'Los números de parcialidad deben ser consecutivos y no repetirse.';
  }
  if (raw.includes('motivo_requerido')) {
    return 'Debes indicar el motivo de anulación.';
  }
  if (raw.includes('cobro_no_encontrado')) {
    return 'No se encontró el cobro en tu organización.';
  }
  if (raw.includes('plan_excede_total')) {
    return 'La suma de parcialidades excede el total permitido.';
  }
  return raw || 'Ocurrió un error al procesar el cobro.';
}
