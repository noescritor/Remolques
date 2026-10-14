import type { Ajustes } from '../types';

/** IVA que usa el sistema cuando los ajustes guardados no traen `iva_por_defecto`. */
export const IVA_POR_DEFECTO = 0.16;

/**
 * Completa los ajustes con los valores por defecto que las pantallas y los PDF dan por hechos.
 * Si el JSON guardado en la base (o en la cotización del portal) no trae `iva_por_defecto`,
 * los PDF calculaban `base * (1 + undefined)` y mostraban "$NaN".
 */
export function normalizarAjustes<T extends Partial<Ajustes>>(ajustes: T | null | undefined): T & { iva_por_defecto: number } {
  const base = (ajustes && typeof ajustes === 'object' ? ajustes : {}) as T;
  const crudo: unknown = (base as any).iva_por_defecto;
  const iva = crudo === null || crudo === undefined || crudo === '' ? NaN : Number(crudo);
  return { ...base, iva_por_defecto: Number.isFinite(iva) ? iva : IVA_POR_DEFECTO };
}
