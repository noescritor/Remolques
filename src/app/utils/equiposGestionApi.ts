import { BASE_URL } from './api';
import { supabase } from './supabase/client';
import type { OrdenTrabajo } from '../types';

export interface ErrorGestionEquipo extends Error {
  status?: number;
  codigo?: string;
  detalle?: Record<string, any>;
}

async function getHeaders(token?: string): Promise<Record<string, string>> {
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
  };
  if (token) {
    headers['Authorization'] = `Bearer ${token}`;
    return headers;
  }
  const { data: { session } } = await supabase.auth.getSession();
  if (session?.access_token) {
    headers['Authorization'] = `Bearer ${session.access_token}`;
  }
  return headers;
}

async function parseErrorResponse(res: Response, fallback: string): Promise<ErrorGestionEquipo> {
  const body = await res.json().catch(() => ({}));
  const err: ErrorGestionEquipo = new Error(body?.error || fallback);
  err.status = res.status;
  err.codigo = body?.codigo;
  err.detalle = body?.detalle;
  return err;
}

export async function listarOrdenesCanceladas(token?: string): Promise<OrdenTrabajo[]> {
  const headers = await getHeaders(token);
  const res = await fetch(`${BASE_URL}/ordenes-trabajo?canceladas=true`, { headers });
  if (!res.ok) {
    throw await parseErrorResponse(res, 'No se pudieron cargar los equipos cancelados');
  }
  const data = await res.json();
  return Array.isArray(data) ? data : [];
}

export async function cancelarOrdenTrabajoApi(
  id: string,
  payload: { motivo: string; confirmo_material_entregado?: boolean },
  token?: string
): Promise<{
  ok: boolean;
  ya_cancelada: boolean;
  entregas_vigentes: number;
  cantidad_entregada_vigente: number;
  orden: OrdenTrabajo;
}> {
  const headers = await getHeaders(token);
  const res = await fetch(`${BASE_URL}/ordenes-trabajo/${id}/cancelar`, {
    method: 'POST',
    headers,
    body: JSON.stringify(payload),
  });
  if (!res.ok) {
    throw await parseErrorResponse(res, 'No se pudo cancelar el equipo');
  }
  return res.json();
}

export async function reactivarOrdenTrabajoApi(
  id: string,
  payload: { motivo?: string | null } = {},
  token?: string
): Promise<{ ok: boolean; ya_activa: boolean; orden: OrdenTrabajo }> {
  const headers = await getHeaders(token);
  const res = await fetch(`${BASE_URL}/ordenes-trabajo/${id}/reactivar`, {
    method: 'POST',
    headers,
    body: JSON.stringify(payload),
  });
  if (!res.ok) {
    throw await parseErrorResponse(res, 'No se pudo reactivar el equipo');
  }
  return res.json();
}

export async function cambiarClienteOrdenTrabajoApi(
  id: string,
  payload: { cliente_id: string | null; etiqueta: string | null; motivo?: string | null },
  token?: string
): Promise<{ ok: boolean; sin_cambios: boolean; orden: OrdenTrabajo }> {
  const headers = await getHeaders(token);
  const res = await fetch(`${BASE_URL}/ordenes-trabajo/${id}/cliente`, {
    method: 'PUT',
    headers,
    body: JSON.stringify(payload),
  });
  if (!res.ok) {
    throw await parseErrorResponse(res, 'No se pudo cambiar el cliente del equipo');
  }
  return res.json();
}

/**
 * Formatea una fecha calendario YYYY-MM-DD en formato legible (hora de México, sin desfase UTC).
 */
export function formatearFechaPedidoMx(fechaIso?: string | null): string {
  if (!fechaIso) return '—';
  const match = /^(\d{4})-(\d{2})-(\d{2})/.exec(String(fechaIso).trim());
  if (!match) return String(fechaIso);
  const [, anio, mes, dia] = match;
  const dt = new Date(Date.UTC(Number(anio), Number(mes) - 1, Number(dia), 12, 0, 0));
  return new Intl.DateTimeFormat('es-MX', {
    timeZone: 'America/Mexico_City',
    day: '2-digit',
    month: 'short',
    year: 'numeric',
  }).format(dt);
}

/**
 * Formatea un timestamp TIMESTAMPTZ en fecha y hora de México.
 */
export function formatearFechaHoraMx(iso?: string | null): string {
  if (!iso) return '—';
  const dt = new Date(iso);
  if (Number.isNaN(dt.getTime())) return String(iso);
  return new Intl.DateTimeFormat('es-MX', {
    timeZone: 'America/Mexico_City',
    day: '2-digit',
    month: 'short',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  }).format(dt);
}
