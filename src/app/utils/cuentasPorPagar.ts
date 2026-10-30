// Utilidades puras para Cuentas por Pagar (Sub-bloque 2R-16)
// Sin dependencias de React ni de red. Ejecutable en navegador, Node y Deno.
// Todo el dinero se procesa internamente en centavos enteros para evitar errores de coma flotante.

export type Moneda = 'MXN' | 'USD';
export type CubetaAntiguedad = 'por_vencer' | '1_30' | '31_60' | 'mas_60';
export type EstadoConciliacion = 'cuadra' | 'leolca_mayor' | 'proveedor_mayor';

export interface FacturaRef {
  id: string;
  folio: string;
  sucursal?: string | null;
  fecha_emision: string; // YYYY-MM-DD
  fecha_vencimiento: string; // YYYY-MM-DD
  moneda: Moneda;
  importe: number;
  estado?: string; // 'abierta' | 'cancelada'
  pagos?: Array<{ monto: number; fecha_pago?: string; anulado?: boolean }>;
  saldo?: number;
}

export interface PagoRef {
  id?: string;
  factura_id: string;
  fecha_pago: string; // YYYY-MM-DD
  monto: number;
  tipo_cambio?: number | null;
  anulado?: boolean;
}

// ── AUXILIARES DE FECHA LOCAL (Sin desfasamiento UTC) ──

export function parseFechaLocal(strFecha: string): Date {
  const partes = strFecha.split('-');
  if (partes.length !== 3) {
    throw new Error(`Formato de fecha inválido: ${strFecha}. Se esperaba YYYY-MM-DD.`);
  }
  const anio = parseInt(partes[0], 10);
  const mes = parseInt(partes[1], 10) - 1;
  const dia = parseInt(partes[2], 10);
  return new Date(anio, mes, dia, 12, 0, 0);
}

export function redondearCentavos(num: number): number {
  return Math.round((num + Number.EPSILON) * 100) / 100;
}

function aCentavos(monto: number): number {
  return Math.round((monto + Number.EPSILON) * 100);
}

function deCentavos(centavos: number): number {
  return Math.round(centavos) / 100;
}

// ── 1. SALDO FACTURA ──

export function saldoFactura(
  importe: number,
  pagos?: Array<{ monto: number; anulado?: boolean }>
): number {
  let centavosImporte = aCentavos(importe);
  if (!pagos || pagos.length === 0) return deCentavos(centavosImporte);

  let centavosPagados = 0;
  for (const p of pagos) {
    if (p.anulado !== true) {
      centavosPagados += aCentavos(p.monto);
    }
  }

  const saldo = Math.max(0, centavosImporte - centavosPagados);
  return deCentavos(saldo);
}

// ── 2. CONVERTIR A PESOS ──

export function convertirAPesos(monto: number, moneda: Moneda, tc?: number | null): number {
  if (moneda === 'MXN') {
    return redondearCentavos(monto);
  }

  if (moneda === 'USD') {
    if (tc === undefined || tc === null || tc <= 0 || isNaN(tc)) {
      throw new Error('Tipo de cambio debe ser mayor a 0 para convertir USD a pesos');
    }
    const totalPesos = monto * tc;
    return redondearCentavos(totalPesos);
  }

  return redondearCentavos(monto);
}

// ── 3. DÍAS DE ATRASO ──

export function diasAtraso(vencimiento: string, fechaCorte: string): number {
  const dVence = parseFechaLocal(vencimiento);
  const dCorte = parseFechaLocal(fechaCorte);
  const diffMs = dCorte.getTime() - dVence.getTime();
  return Math.round(diffMs / (1000 * 60 * 60 * 24));
}

// ── 4. CUBETA DE ANTIGÜEDAD ──

export function cubeta(dias: number): CubetaAntiguedad {
  if (dias <= 0) return 'por_vencer';
  if (dias <= 30) return '1_30';
  if (dias <= 60) return '31_60';
  return 'mas_60';
}

// ── 5. RESUMEN DE CUENTA ──

export interface ResumenCuentaOpciones {
  fechaCorte: string; // YYYY-MM-DD
  tcUSD?: number | null;
}

export interface AntiguedadDetalle {
  por_vencer: number;
  '1_30': number;
  '31_60': number;
  mas_60: number;
}

export interface ResumenCuentaResultado {
  saldoUSD: number;
  saldoMXN: number;
  equivalenteUSDEnPesos: number | null;
  totalEnPesos: number | null;
  antiguedad: {
    usd: AntiguedadDetalle;
    mxn: AntiguedadDetalle;
    pesos: AntiguedadDetalle | null;
  };
  facturaMasVencida: {
    folio: string;
    diasAtraso: number;
    moneda: Moneda;
    saldo: number;
  } | null;
  totalFacturasAbiertas: number;
}

export function resumenCuenta(
  facturas: FacturaRef[],
  opciones: ResumenCuentaOpciones
): ResumenCuentaResultado {
  const { fechaCorte, tcUSD } = opciones;

  let centavosUSD = 0;
  let centavosMXN = 0;

  const antUSD: AntiguedadDetalle = { por_vencer: 0, '1_30': 0, '31_60': 0, mas_60: 0 };
  const antMXN: AntiguedadDetalle = { por_vencer: 0, '1_30': 0, '31_60': 0, mas_60: 0 };

  let maxAtraso = -Infinity;
  let facturaMasVencida: ResumenCuentaResultado['facturaMasVencida'] = null;
  let totalAbiertas = 0;

  for (const f of facturas) {
    if (f.estado === 'cancelada') continue;

    const saldo = f.saldo !== undefined ? f.saldo : saldoFactura(f.importe, f.pagos);
    if (saldo <= 0) continue;

    totalAbiertas++;
    const dias = diasAtraso(f.fecha_vencimiento, fechaCorte);
    const cub = cubeta(dias);
    const saldoCentavos = aCentavos(saldo);

    if (dias > maxAtraso) {
      maxAtraso = dias;
      facturaMasVencida = {
        folio: f.folio,
        diasAtraso: dias,
        moneda: f.moneda,
        saldo: saldo,
      };
    }

    if (f.moneda === 'USD') {
      centavosUSD += saldoCentavos;
      antUSD[cub] = redondearCentavos(antUSD[cub] + saldo);
    } else {
      centavosMXN += saldoCentavos;
      antMXN[cub] = redondearCentavos(antMXN[cub] + saldo);
    }
  }

  const saldoUSD = deCentavos(centavosUSD);
  const saldoMXN = deCentavos(centavosMXN);

  const tieneUSD = saldoUSD > 0;
  const tcValido = tcUSD !== undefined && tcUSD !== null && tcUSD > 0;

  let equivalenteUSDEnPesos: number | null = null;
  let totalEnPesos: number | null = null;
  let antPesos: AntiguedadDetalle | null = null;

  if (tieneUSD) {
    if (tcValido) {
      equivalenteUSDEnPesos = redondearCentavos(saldoUSD * tcUSD!);
      totalEnPesos = redondearCentavos(saldoMXN + equivalenteUSDEnPesos);
      antPesos = {
        por_vencer: redondearCentavos(antMXN.por_vencer + antUSD.por_vencer * tcUSD!),
        '1_30': redondearCentavos(antMXN['1_30'] + antUSD['1_30'] * tcUSD!),
        '31_60': redondearCentavos(antMXN['31_60'] + antUSD['31_60'] * tcUSD!),
        mas_60: redondearCentavos(antMXN.mas_60 + antUSD.mas_60 * tcUSD!),
      };
    } else {
      equivalenteUSDEnPesos = null;
      totalEnPesos = null;
      antPesos = null;
    }
  } else {
    equivalenteUSDEnPesos = 0;
    totalEnPesos = saldoMXN;
    antPesos = { ...antMXN };
  }

  return {
    saldoUSD,
    saldoMXN,
    equivalenteUSDEnPesos,
    totalEnPesos,
    antiguedad: {
      usd: antUSD,
      mxn: antMXN,
      pesos: antPesos,
    },
    facturaMasVencida,
    totalFacturasAbiertas: totalAbiertas,
  };
}

// ── 6. SALDO A FECHA ──

export function saldoAFecha(
  facturas: FacturaRef[],
  pagos: PagoRef[],
  fechaCorte: string
): { saldoUSD: number; saldoMXN: number } {
  let centavosUSD = 0;
  let centavosMXN = 0;

  // Filtrar facturas emitidas <= fechaCorte y no canceladas
  const facturasValidas = facturas.filter(
    (f) => f.estado !== 'cancelada' && f.fecha_emision <= fechaCorte
  );

  // Mapear pagos <= fechaCorte agrupados por factura_id
  const pagosPorFactura: Record<string, number> = {};
  for (const p of pagos) {
    if (p.anulado !== true && p.fecha_pago <= fechaCorte) {
      pagosPorFactura[p.factura_id] = (pagosPorFactura[p.factura_id] || 0) + aCentavos(p.monto);
    }
  }

  for (const f of facturasValidas) {
    const impCentavos = aCentavos(f.importe);
    const pagadoCentavos = pagosPorFactura[f.id] || 0;
    const rem = Math.max(0, impCentavos - pagadoCentavos);

    if (f.moneda === 'USD') {
      centavosUSD += rem;
    } else {
      centavosMXN += rem;
    }
  }

  return {
    saldoUSD: deCentavos(centavosUSD),
    saldoMXN: deCentavos(centavosMXN),
  };
}

// ── 7. CONCILIAR CONTRA ESTADO DE CUENTA ──

export interface ConciliacionResultado {
  diferencia: number;
  estado: EstadoConciliacion;
  saldoLeolca: number;
  saldoProveedor: number;
}

export function conciliar(
  saldoLeolca: number,
  saldoProveedor: number
): ConciliacionResultado {
  const cLeolca = aCentavos(saldoLeolca);
  const cProveedor = aCentavos(saldoProveedor);
  const diffCentavos = cLeolca - cProveedor;
  const absDiff = Math.abs(diffCentavos);

  // Tolerancia 1 centavo
  if (absDiff <= 1) {
    return {
      diferencia: 0,
      estado: 'cuadra',
      saldoLeolca: redondearCentavos(saldoLeolca),
      saldoProveedor: redondearCentavos(saldoProveedor),
    };
  }

  const diferencia = deCentavos(absDiff);
  const estado: EstadoConciliacion = diffCentavos > 0 ? 'leolca_mayor' : 'proveedor_mayor';

  return {
    diferencia,
    estado,
    saldoLeolca: redondearCentavos(saldoLeolca),
    saldoProveedor: redondearCentavos(saldoProveedor),
  };
}

// ── 8. USO DE CRÉDITO ──

export function usoDeCredito(saldo: number, limite?: number | null): number {
  if (!limite || limite <= 0 || isNaN(limite)) return 0;
  const pct = (saldo / limite) * 100;
  return Math.round(pct * 100) / 100;
}

// ── FORMATEO DE MONEDA ──

export function formatearMonedaDe(monto: number, moneda: Moneda): string {
  const formateado = new Intl.NumberFormat('es-MX', {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(monto || 0);

  if (moneda === 'USD') {
    return `US$ ${formateado}`;
  }
  return `$${formateado}`;
}

// ── FECHA LOCAL ISO (YYYY-MM-DD) ──

/**
 * Devuelve la fecha local en formato YYYY-MM-DD sin desfases por conversión a UTC.
 */
export function fechaLocalISO(d: Date = new Date()): string {
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const dia = String(d.getDate()).padStart(2, '0');
  return `${y}-${m}-${dia}`;
}

