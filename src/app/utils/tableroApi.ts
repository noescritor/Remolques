/**
 * Cliente API para el Tablero de Producción (Matriz de fases y seguimiento)
 * Conforme a docs/tablero/CONTRATO_API_MATRIZ.md
 */

import { BASE_URL } from './api';
import { supabase } from './supabase/client';

export interface FaseMatriz {
  id: string;
  orden: number;
  nombre: string;
  grupo: 'principal' | 'tina';
  requiere_grupo: string | null;
  duracion_dias: number;
}

export interface CeldaMatriz {
  estado: 'pendiente' | 'en_proceso' | 'incompleta' | 'pausada' | 'terminada';
  fecha_propuesta: string | null;
  fecha_fin: string | null;
  nota: string | null;
}

export interface FilaMatriz {
  orden_id: string;
  etiqueta: string;
  cliente_nombre: string;
  cotizacion_folio: string | null;
  modelo: string | null;
  tipo_equipo: string | null;
  origen: 'cotizacion' | 'manual';
  fecha_compromiso: string | null;
  fecha_inicio: string | null;
  material_faltante: string | null;
  estado: string;
  estado_kanban: string;
  semaforo: 'en_tiempo' | 'por_vencer' | 'atrasado';
  avance: {
    terminadas: number;
    total: number;
  };
  tina: {
    terminadas: number;
    total: number;
  } | null;
  celdas: Record<string, CeldaMatriz>;
}

export interface ResumenMatriz {
  en_planta: number;
  atrasados: number;
  con_material: number;
  con_pausa: number;
  wip_por_fase: Record<string, number>;
}

export interface MatrizRespuesta {
  linea: {
    id: string;
    clave: string;
    nombre: string;
  };
  fases: FaseMatriz[];
  filas: FilaMatriz[];
  resumen: ResumenMatriz;
}

export interface HistorialFaseItem {
  id: string;
  fase_id: string;
  fase_nombre: string;
  fase_grupo: string;
  fase_orden: number;
  estado_anterior: string;
  estado_nuevo: string;
  fecha_propuesta: string | null;
  nota: string | null;
  usuario: string | null;
  usuario_id: string | null;
  fecha_cambio: string;
  created_at: string;
}

async function getAuthHeaders(tokenOrClient?: string | any): Promise<Record<string, string>> {
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
  };

  if (typeof tokenOrClient === 'string' && tokenOrClient.length > 0) {
    headers['Authorization'] = `Bearer ${tokenOrClient}`;
    return headers;
  }

  if (tokenOrClient?.access_token) {
    headers['Authorization'] = `Bearer ${tokenOrClient.access_token}`;
    return headers;
  }

  try {
    const client = tokenOrClient?.auth ? tokenOrClient : supabase;
    const { data: { session } } = await client.auth.getSession();
    if (session?.access_token) {
      headers['Authorization'] = `Bearer ${session.access_token}`;
    }
  } catch (err) {
    console.warn('[tableroApi] No se pudo obtener sesión de auth:', err);
  }

  return headers;
}

/**
 * 1. GET /produccion/matriz?linea=<clave>
 */
export async function fetchMatrizProduccion(
  lineaClave: string = 'plataforma',
  tokenOrClient?: string | any
): Promise<MatrizRespuesta> {
  const headers = await getAuthHeaders(tokenOrClient);
  const res = await fetch(`${BASE_URL}/produccion/matriz?linea=${encodeURIComponent(lineaClave)}`, {
    headers,
  });

  if (!res.ok) {
    const err = await res.json().catch(() => ({}));
    throw new Error(err.error || `Error ${res.status} al cargar matriz de ${lineaClave}`);
  }

  return res.json();
}

/**
 * 2. POST /produccion/ordenes
 */
export async function crearOrdenProduccion(
  payload: {
    linea: string;
    tipo_equipo?: string;
    modelo?: string;
    etiqueta?: string;
    cliente_id?: string | null;
    fecha_compromiso?: string | null;
    caracteristicas?: any;
  },
  tokenOrClient?: string | any
): Promise<{ ok: boolean; orden: any }> {
  const headers = await getAuthHeaders(tokenOrClient);
  const res = await fetch(`${BASE_URL}/produccion/ordenes`, {
    method: 'POST',
    headers,
    body: JSON.stringify(payload),
  });

  if (!res.ok) {
    const err = await res.json().catch(() => ({}));
    throw new Error(err.error || 'Error al crear equipo en planta');
  }

  return res.json();
}

/**
 * 3. PUT /produccion/ordenes/:id/fases/:faseId
 */
export async function actualizarFaseOrden(
  ordenId: string,
  faseId: string,
  payload: {
    estado: string;
    fecha_propuesta?: string | null;
    fecha_fin?: string | null;
    nota?: string | null;
  },
  tokenOrClient?: string | any
): Promise<{ ok: boolean; fase: any; orden: any; avisos?: string[] }> {
  const headers = await getAuthHeaders(tokenOrClient);
  const res = await fetch(`${BASE_URL}/produccion/ordenes/${ordenId}/fases/${faseId}`, {
    method: 'PUT',
    headers,
    body: JSON.stringify(payload),
  });

  if (!res.ok) {
    const err = await res.json().catch(() => ({}));
    throw new Error(err.error || 'Error al actualizar fase de la orden');
  }

  return res.json();
}

/**
 * 4. PUT /produccion/ordenes/:id/planeacion
 * Lista blanca estricta: { fecha_compromiso, etiqueta, material_faltante }
 */
export async function actualizarPlaneacionOrden(
  ordenId: string,
  payload: {
    fecha_compromiso?: string | null;
    etiqueta?: string | null;
    material_faltante?: string | null;
  },
  tokenOrClient?: string | any
): Promise<{ ok: boolean; orden: any }> {
  const headers = await getAuthHeaders(tokenOrClient);
  const res = await fetch(`${BASE_URL}/produccion/ordenes/${ordenId}/planeacion`, {
    method: 'PUT',
    headers,
    body: JSON.stringify(payload),
  });

  if (!res.ok) {
    const err = await res.json().catch(() => ({}));
    throw new Error(err.error || 'Error al actualizar planeación de la orden');
  }

  return res.json();
}

/**
 * 6. GET /produccion/ordenes/:id/historial
 */
export async function fetchHistorialOrden(
  ordenId: string,
  tokenOrClient?: string | any
): Promise<{ ok: boolean; historial: HistorialFaseItem[] }> {
  const headers = await getAuthHeaders(tokenOrClient);
  const res = await fetch(`${BASE_URL}/produccion/ordenes/${ordenId}/historial`, {
    headers,
  });

  if (!res.ok) {
    const err = await res.json().catch(() => ({}));
    throw new Error(err.error || 'Error al consultar historial de la orden');
  }

  return res.json();
}

/**
 * 8. POST /produccion/sembrar
 */
export async function sembrarTableroProduccion(
  tokenOrClient?: string | any
): Promise<{ ok: boolean; resultado: { lineas: number; fases: number } }> {
  const headers = await getAuthHeaders(tokenOrClient);
  const res = await fetch(`${BASE_URL}/produccion/sembrar`, {
    method: 'POST',
    headers,
    body: JSON.stringify({}),
  });

  if (!res.ok) {
    const err = await res.json().catch(() => ({}));
    throw new Error(err.error || 'Error al sembrar líneas y fases de producción');
  }

  return res.json();
}
