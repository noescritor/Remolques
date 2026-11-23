import { BASE_URL } from '../../utils/api';
import { supabase } from '../../utils/supabase/client';

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

async function fetchJson<T>(path: string): Promise<T> {
  const headers = await authHeaders();
  const res = await fetch(`${BASE_URL}${path}`, { headers });
  const body = await res.json().catch(() => null);
  if (!res.ok) {
    throw new Error(body?.error || body?.message || `Error ${res.status}`);
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
};
