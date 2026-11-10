export interface LineaCosteo {
  concepto: string;
  cantidad: number;
  costo_unitario: number;
  importe: number;
  origen: string;
  seccion?: string;
}

export interface SeccionCosteo {
  total: number;
  lineas: LineaCosteo[];
}

export interface PendienteCosteo {
  tipo: 'sin_precio' | 'opcion_sin_costo' | 'modelo_sin_costos' | 'ganancia_no_definida' | 'variante_supuesta' | string;
  detalle: string;
}

export type SeccionFaltante = 'acero' | 'kits' | 'mano_obra';

export interface ResultadoCosteo {
  moneda: 'MXN';
  secciones: {
    acero: SeccionCosteo;
    kits_fijos: SeccionCosteo;
    opciones: SeccionCosteo;
    mano_obra: SeccionCosteo;
    ajustes: SeccionCosteo;
  };
  costo: number;
  ganancia: number | null;
  precio_sugerido: number | null;
  margen_sobre_precio: number | null;
  margen_sobre_costo: number | null;
  confianza: 'completa' | 'estimada' | 'incompleta';
  pendientes: PendienteCosteo[];
  secciones_faltantes?: SeccionFaltante[];
}

export interface AjusteManual {
  concepto: string;
  cantidad: number;
  costo_unitario: number;
}

export interface CosteoResumenGuardado {
  costo: number;
  ganancia: number | null;
  precio_sugerido: number | null;
  confianza: 'completa' | 'estimada' | 'incompleta';
  pendientes: string[];
  calculado_en: string;
}

/**
 * Valida un único ajuste individual en el cliente.
 */
export function validarAjusteIndividual(ajuste: any): boolean {
  if (!ajuste || typeof ajuste !== 'object') return false;
  if (typeof ajuste.concepto !== 'string' || ajuste.concepto.trim().length === 0) return false;
  if (typeof ajuste.cantidad !== 'number' || !Number.isFinite(ajuste.cantidad) || ajuste.cantidad <= 0) return false;
  if (typeof ajuste.costo_unitario !== 'number' || !Number.isFinite(ajuste.costo_unitario)) return false;
  return true;
}

/**
 * Valida una lista completa de ajustes manuales capturados en el cliente.
 */
export function validarAjustesCliente(ajustes: any): { valido: boolean; error?: string } {
  if (ajustes === undefined || ajustes === null) {
    return { valido: true };
  }
  if (!Array.isArray(ajustes)) {
    return { valido: false, error: 'Ajustes debe ser un arreglo' };
  }
  for (let i = 0; i < ajustes.length; i++) {
    const a = ajustes[i];
    if (!validarAjusteIndividual(a)) {
      return {
        valido: false,
        error: `Ajuste #${i + 1} inválido: concepto no vacío, cantidad > 0 y costo unitario numérico finito`
      };
    }
  }
  return { valido: true };
}

/**
 * Decide el precio unitario del item según las reglas de negocio del sub-bloque 2R-4d:
 * - Si no hay nuevo precio sugerido (costeo null o precio_sugerido null), conserva precioActual
 *   (o 0 si precioActual es undefined). Nunca devuelve 0 sobre un precio existente por falta de costeo.
 * - Item nuevo (precioActual undefined): si costeo.precio_sugerido no es null, se prellena con él; si no, 0.
 * - Item en edición (precioActual definido): si precioActual es 0 o coincide con el precio_sugerido previo
 *   (el vendedor nunca lo editó), se actualiza al nuevo precio sugerido si está disponible.
 *   Si el vendedor personalizó el precio o no hay nuevo precio sugerido, conserva precioActual.
 *
 * Casos que deben pasar:
 * - (costeo null, precioActual 500, previo 500) → 500
 * - (precio_sugerido null, precioActual 500, previo 500) → 500
 * - (nuevo 520, actual 500, previo 500) → 520
 * - (nuevo 520, actual 480, previo 500) → 480
 * - (nuevo 500, actual undefined) → 500
 */
export function decidirPrecioItem({
  costeo,
  precioActual,
  costeoPrevio
}: {
  costeo: ResultadoCosteo | null;
  precioActual?: number;
  costeoPrevio?: { precio_sugerido?: number | null } | null;
}): number {
  const nuevoSugerido = (costeo?.precio_sugerido !== null && costeo?.precio_sugerido !== undefined)
    ? costeo.precio_sugerido
    : null;

  // Si no hay nuevo precio sugerido, conservar precioActual existente (o 0 si es item nuevo)
  if (nuevoSugerido === null) {
    return precioActual !== undefined ? precioActual : 0;
  }

  // Item nuevo con nuevo precio sugerido disponible
  if (precioActual === undefined) {
    return nuevoSugerido;
  }

  // Item en edición: verificar si el vendedor nunca tocó el precio (o era 0)
  const nuncaLoToco =
    precioActual === 0 ||
    (costeoPrevio?.precio_sugerido !== undefined &&
      costeoPrevio?.precio_sugerido !== null &&
      precioActual === costeoPrevio.precio_sugerido);

  if (nuncaLoToco) {
    return nuevoSugerido;
  }

  // El vendedor personalizó el precio: conservarlo intacto
  return precioActual;
}

/**
 * Devuelve el texto legible según el nivel de confianza del costeo.
 */
export function textoConfianza(confianza?: 'completa' | 'estimada' | 'incompleta' | string | null): string {
  switch (confianza) {
    case 'completa':
      return 'Costeo completo';
    case 'estimada':
      return 'Estimado: hay datos pendientes';
    case 'incompleta':
    default:
      return 'Sin costeo para este modelo';
  }
}

/**
 * Traduce el código de tipo de pendiente a un texto corto en español.
 */
export function traducirTipoPendiente(tipo: string): string {
  switch (tipo) {
    case 'sin_precio':
      return 'Sin precio';
    case 'opcion_sin_costo':
      return 'Opción sin costo';
    case 'modelo_sin_costos':
      return 'Modelo sin costos';
    case 'ganancia_no_definida':
      return 'Ganancia no definida';
    case 'variante_supuesta':
      return 'Costo supuesto';
    case 'iva_gondola':
      return 'IVA por confirmar';
    case 'costo_no_factura':
      return 'Costo no es de la Factura';
    default:
      return tipo;
  }
}

/**
 * Obtiene la lista de secciones faltantes ('acero', 'kits', 'mano_obra')
 * a partir del costeo, ya sea de `secciones_faltantes`, de `pendientes` o de `secciones`.
 */
export function obtenerSeccionesFaltantes(
  costeo: {
    confianza?: string;
    secciones_faltantes?: (SeccionFaltante | string)[];
    pendientes?: { tipo?: string; detalle?: string }[];
    secciones?: {
      acero?: { lineas?: any[] };
      kits_fijos?: { lineas?: any[] };
      mano_obra?: { lineas?: any[] };
    };
  } | null | undefined
): SeccionFaltante[] {
  if (!costeo) return [];

  if (Array.isArray(costeo.secciones_faltantes) && costeo.secciones_faltantes.length > 0) {
    const ordenValido: SeccionFaltante[] = ['acero', 'kits', 'mano_obra'];
    return ordenValido.filter(s => costeo.secciones_faltantes!.includes(s));
  }

  const faltantes: SeccionFaltante[] = [];
  const pendientes = costeo.pendientes || [];

  const tienePendienteAcero = pendientes.some(
    p => p.tipo === 'modelo_sin_costos' && (p.detalle || '').toLowerCase().includes('acero')
  );
  const tienePendienteKits = pendientes.some(
    p => p.tipo === 'modelo_sin_costos' && ((p.detalle || '').toLowerCase().includes('fijos') || (p.detalle || '').toLowerCase().includes('kits'))
  );
  const tienePendienteProcesos = pendientes.some(
    p => p.tipo === 'modelo_sin_costos' && ((p.detalle || '').toLowerCase().includes('procesos') || (p.detalle || '').toLowerCase().includes('mano de obra'))
  );

  const sinAcero = tienePendienteAcero || (costeo.secciones?.acero && (!costeo.secciones.acero.lineas || costeo.secciones.acero.lineas.length === 0));
  const sinKits = tienePendienteKits || (costeo.secciones?.kits_fijos && (!costeo.secciones.kits_fijos.lineas || costeo.secciones.kits_fijos.lineas.length === 0));
  const sinManoObra = tienePendienteProcesos || (costeo.secciones?.mano_obra && (!costeo.secciones.mano_obra.lineas || costeo.secciones.mano_obra.lineas.length === 0));

  if (sinAcero) faltantes.push('acero');
  if (sinKits) faltantes.push('kits');
  if (sinManoObra) faltantes.push('mano_obra');

  return faltantes;
}

/**
 * Arma un mensaje explicativo cuando un modelo no tiene precio sugerido por costeo incompleto.
 * Devuelve null si el costeo tiene precio_sugerido o su confianza no es 'incompleta'.
 *
 * Casos:
 * - 1 faltante:
 *   - 'acero'     -> "Sin precio sugerido: falta acero de este modelo"
 *   - 'kits'      -> "Sin precio sugerido: faltan kits de este modelo"
 *   - 'mano_obra' -> "Sin precio sugerido: falta mano de obra de este modelo"
 * - 2 faltantes:
 *   - 'acero' y 'kits'      -> "Sin precio sugerido: faltan acero y kits de este modelo"
 *   - 'acero' y 'mano_obra' -> "Sin precio sugerido: faltan acero y mano de obra de este modelo"
 *   - 'kits' y 'mano_obra'  -> "Sin precio sugerido: faltan kits y mano de obra de este modelo"
 * - 3 faltantes:
 *   - 'acero', 'kits', 'mano_obra' -> "Sin precio sugerido: faltan acero, kits y mano de obra de este modelo"
 * - Incompleto sin secciones identificadas:
 *   - -> "Sin precio sugerido: costeo incompleto para este modelo"
 * - Costeo normal / completo / estimado con precio -> null
 */
export function mensajeCosteoIncompleto(
  costeo: {
    confianza?: string;
    precio_sugerido?: number | null;
    secciones_faltantes?: (SeccionFaltante | string)[];
    pendientes?: { tipo?: string; detalle?: string }[];
    secciones?: {
      acero?: { lineas?: any[] };
      kits_fijos?: { lineas?: any[] };
      mano_obra?: { lineas?: any[] };
    };
  } | null | undefined
): string | null {
  if (!costeo) return null;

  // Si tiene precio sugerido, no es un costeo que falte precio
  if (costeo.precio_sugerido !== null && costeo.precio_sugerido !== undefined) {
    return null;
  }

  // Solo aplica si la confianza es incompleta (o si precio_sugerido es null y confianza no es completa/estimada)
  const esIncompleto = costeo.confianza === 'incompleta' || (!costeo.confianza && costeo.precio_sugerido === null);
  if (!esIncompleto) {
    return null;
  }

  const faltantes = obtenerSeccionesFaltantes(costeo);

  if (faltantes.length === 0) {
    return 'Sin precio sugerido: costeo incompleto para este modelo';
  }

  const nombres: Record<SeccionFaltante, string> = {
    acero: 'acero',
    kits: 'kits',
    mano_obra: 'mano de obra'
  };

  if (faltantes.length === 1) {
    const s = faltantes[0];
    const verbo = s === 'kits' ? 'faltan' : 'falta';
    return `Sin precio sugerido: ${verbo} ${nombres[s]} de este modelo`;
  }

  if (faltantes.length === 2) {
    return `Sin precio sugerido: faltan ${nombres[faltantes[0]]} y ${nombres[faltantes[1]]} de este modelo`;
  }

  return 'Sin precio sugerido: faltan acero, kits y mano de obra de este modelo';
}

