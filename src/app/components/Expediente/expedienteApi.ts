import { BASE_URL } from '../../utils/api';
import { supabase } from '../../utils/supabase/client';
import type { CobranzaCotizacionDto, CobranzaEquipoDto } from '../../utils/cobros';

async function authHeaders(): Promise<Record<string, string>> {
  const {
    data: { session },
  } = await supabase.auth.getSession();
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
  };
  if (session?.access_token) {
    headers['Authorization'] = `Bearer ${session.access_token}`;
  }
  return headers;
}

async function fetchJson<T>(path: string, init?: RequestInit): Promise<T> {
  const headers = await authHeaders();
  const res = await fetch(`${BASE_URL}${path}`, {
    ...init,
    headers: { ...headers, ...(init?.headers || {}) },
  });
  const body = await res.json().catch(() => null);
  if (!res.ok) {
    const err = new Error(body?.error || body?.message || `Error ${res.status}`) as Error & {
      codigo?: string;
      status?: number;
      requiere_confirmacion_saldo_a_favor?: boolean;
    };
    err.codigo = body?.codigo;
    err.status = res.status;
    err.requiere_confirmacion_saldo_a_favor = body?.requiere_confirmacion_saldo_a_favor;
    throw err;
  }
  return body as T;
}

export interface ResumenEntregaOrdenDto {
  orden_trabajo_id: string;
  total_partidas: number;
  partidas_completas: number;
  porcentaje: number | null;
  por_fase: Record<
    string,
    { total_partidas: number; partidas_completas: number; porcentaje: number | null }
  >;
}

export interface TrazabilidadOrdenResponse {
  orden?: any;
  tareas?: any[];
  bitacora?: any[];
}

export const expedienteApi = {
  resumenEntregasOrdenes: () =>
    fetchJson<ResumenEntregaOrdenDto[]>('/ordenes-trabajo/resumen-entregas'),
  listarOrdenesTrabajo: () => fetchJson<any[]>('/ordenes-trabajo'),
  listarPresupuestos: () => fetchJson<any[]>('/presupuestos'),
  pagosPorCotizacion: (cotizacionId: string) =>
    fetchJson<any[]>(`/pagos/cotizacion/${encodeURIComponent(cotizacionId)}`),
  trazabilidadOrden: (ordenId: string) =>
    fetchJson<TrazabilidadOrdenResponse>(`/produccion/trazabilidad/orden/${encodeURIComponent(ordenId)}`),
  matrizLinea: (lineaClave: string) =>
    fetchJson<any>(`/produccion/matriz?linea=${encodeURIComponent(lineaClave)}`),
  cobranzaEquipo: (ordenId: string) =>
    fetchJson<CobranzaEquipoDto>(`/cobranza/equipo/${encodeURIComponent(ordenId)}`),
  cobranzaCotizacion: (cotizacionId: string) =>
    fetchJson<CobranzaCotizacionDto>(`/cobranza/cotizacion/${encodeURIComponent(cotizacionId)}`),
  registrarCobro: (payload: {
    cotizacion_id: string;
    monto: number;
    fecha?: string;
    tipo_pago: string;
    referencia?: string | null;
    notas?: string | null;
    descripcion_especie?: string | null;
    aplicaciones?: Array<{ orden_trabajo_id: string; monto: number }>;
    permitir_saldo_a_favor?: boolean;
  }) =>
    fetchJson<any>('/cobros', {
      method: 'POST',
      body: JSON.stringify(payload),
    }),
  anularCobro: (pagoId: string, motivo: string) =>
    fetchJson<any>(`/cobros/${encodeURIComponent(pagoId)}/anular`, {
      method: 'POST',
      body: JSON.stringify({ motivo }),
    }),
  guardarValorEquipo: (ordenId: string, valorPactado: number | null, notas?: string | null) =>
    fetchJson<any>(`/cobranza/equipo/${encodeURIComponent(ordenId)}/valor`, {
      method: 'PUT',
      body: JSON.stringify({ valor_pactado: valorPactado, notas: notas ?? null }),
    }),
  crearPlanPago: (payload: {
    cotizacion_id: string;
    orden_trabajo_id?: string | null;
    nombre: string;
    notas?: string | null;
    parcialidades: Array<{ numero: number; fecha_vencimiento: string; monto: number; nota?: string | null }>;
  }) =>
    fetchJson<any>('/planes-pago', {
      method: 'POST',
      body: JSON.stringify(payload),
    }),
  actualizarPlanPago: (
    planId: string,
    payload: {
      nombre?: string;
      notas?: string | null;
      parcialidades?: Array<{ numero: number; fecha_vencimiento: string; monto: number; nota?: string | null }>;
    },
  ) =>
    fetchJson<any>(`/planes-pago/${encodeURIComponent(planId)}`, {
      method: 'PUT',
      body: JSON.stringify(payload),
    }),
  eliminarPlanPago: (planId: string) =>
    fetchJson<any>(`/planes-pago/${encodeURIComponent(planId)}`, {
      method: 'DELETE',
    }),
};
