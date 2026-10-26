/**
 * Cliente API para el módulo de Acero y Calculadoras (Sub-bloque 2R-13)
 */

import { BASE_URL } from './api';
import { AceroMaterialItem } from '../../../supabase/functions/make-server-feea4382/motor/acero';

async function getAuthHeaders(supabase: any): Promise<Record<string, string>> {
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
  };
  try {
    const { data: { session } } = await supabase.auth.getSession();
    if (session?.access_token) {
      headers['Authorization'] = `Bearer ${session.access_token}`;
    }
  } catch (err) {
    console.warn('[aceroApi] No se pudo obtener sesión:', err);
  }
  return headers;
}

export async function fetchCatalogoAcero(
  supabase: any
): Promise<{ materiales: AceroMaterialItem[]; proveedores: string[] }> {
  const headers = await getAuthHeaders(supabase);
  const res = await fetch(`${BASE_URL}/acero/catalogo`, { headers });
  if (!res.ok) {
    const err = await res.json().catch(() => ({}));
    throw new Error(err.error || 'Error al obtener catálogo de acero');
  }
  return res.json();
}

export async function guardarPrecioAceroApi(
  supabase: any,
  payload: {
    material_id: string;
    proveedor: string;
    precio: number;
    incluye_iva?: boolean;
    fuente?: string;
  }
): Promise<any> {
  const headers = await getAuthHeaders(supabase);
  const res = await fetch(`${BASE_URL}/acero/precios`, {
    method: 'PUT',
    headers,
    body: JSON.stringify(payload),
  });
  if (!res.ok) {
    const err = await res.json().catch(() => ({}));
    throw new Error(err.error || 'Error al guardar precio de acero');
  }
  return res.json();
}

export async function crearMaterialAceroApi(
  supabase: any,
  payload: {
    nombre: string;
    tipo?: string;
    notas?: string;
  }
): Promise<any> {
  const headers = await getAuthHeaders(supabase);
  const res = await fetch(`${BASE_URL}/acero/materiales`, {
    method: 'POST',
    headers,
    body: JSON.stringify(payload),
  });
  if (!res.ok) {
    const err = await res.json().catch(() => ({}));
    throw new Error(err.error || 'Error al crear material de acero');
  }
  return res.json();
}

export async function actualizarMaterialAceroApi(
  supabase: any,
  id: string,
  payload: {
    nombre?: string;
    activo?: boolean;
    notas?: string;
  }
): Promise<any> {
  const headers = await getAuthHeaders(supabase);
  const res = await fetch(`${BASE_URL}/acero/materiales/${id}`, {
    method: 'PUT',
    headers,
    body: JSON.stringify(payload),
  });
  if (!res.ok) {
    const err = await res.json().catch(() => ({}));
    throw new Error(err.error || 'Error al actualizar material de acero');
  }
  return res.json();
}

export async function eliminarPrecioAceroApi(
  supabase: any,
  materialId: string,
  proveedor: string
): Promise<any> {
  const headers = await getAuthHeaders(supabase);
  const res = await fetch(`${BASE_URL}/acero/precios/${materialId}/${encodeURIComponent(proveedor)}`, {
    method: 'DELETE',
    headers,
  });
  if (!res.ok) {
    const err = await res.json().catch(() => ({}));
    throw new Error(err.error || 'Error al eliminar precio de acero');
  }
  return res.json();
}

export async function fetchHistorialAceroApi(
  supabase: any,
  materialId?: string,
  limite: number = 50
): Promise<any[]> {
  const headers = await getAuthHeaders(supabase);
  const url = materialId
    ? `${BASE_URL}/acero/historial?material_id=${materialId}&limite=${limite}`
    : `${BASE_URL}/acero/historial?limite=${limite}`;
  const res = await fetch(url, { headers });
  if (!res.ok) {
    const err = await res.json().catch(() => ({}));
    throw new Error(err.error || 'Error al obtener historial de precios');
  }
  return res.json();
}
