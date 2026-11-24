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
    tipo?: string;
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

export interface PropuestaPartidaAcero {
  partida_id: string;
  orden: number;
  descripcion: string;
  descripcion_normalizada: string;
  clave_sat: string | null;
  clave_unidad: string | null;
  cantidad: number;
  precio_unitario_xml: number;
  importe: number;
  precio_neto_mxn: number | null;
  sugerencia_origen: 'recordado' | 'sugerido' | 'sin_sugerencia';
  sugerencia_puntaje: number;
  material_id_sugerido: string | null;
  proveedor_acero_sugerido: string | null;
  factor_conversion_sugerido: number;
  precio_actual: number | null;
  precio_actual_incluye_iva: boolean | null;
  banderas: {
    ya_aplicada: boolean;
    fecha_anterior: boolean;
    variacion_pct: number | null;
    variacion_alta: boolean;
    descuento_en_factura: boolean;
    requiere_factor: boolean;
    bloqueada_unidad: boolean;
    revisar_unidad: boolean;
    bloqueada_tipo_cambio: boolean;
  };
}

export interface PropuestaAceroCfdi {
  factura: {
    id: string;
    folio: string;
    uuid_fiscal: string | null;
    fecha_emision: string;
    moneda: string;
    tipo_cambio_emision: number | null;
    estado: string;
    proveedor_id: string | null;
    proveedor_nombre: string | null;
    descuento_en_factura: boolean;
  };
  proveedores_acero: string[];
  materiales: Array<{ id: string; nombre: string; tipo: string }>;
  precios_actuales: Array<{
    material_id: string;
    proveedor: string;
    precio: number;
    incluye_iva: boolean;
  }>;
  lineas: PropuestaPartidaAcero[];
}

export interface LineaAplicarAceroCfdi {
  partida_id: string;
  material_id: string;
  proveedor_acero: string;
  factor_conversion?: number;
  guardar_alias?: boolean;
  forzar_fecha_anterior?: boolean;
  forzar_variacion?: boolean;
  descripcion_normalizada?: string;
}

export interface CatalogoAliasItem {
  id: string;
  destino_tipo: string;
  destino_id: string;
  destino_nombre?: string | null;
  proveedor_id: string;
  proveedor_acero: string | null;
  clave_sat: string | null;
  descripcion_normalizada: string;
  factor_conversion: number;
  veces_confirmado: number;
  ultima_confirmacion: string;
  created_at: string;
}

export async function fetchPropuestaAceroCfdi(
  supabase: any,
  facturaId: string,
  proveedor?: string
): Promise<PropuestaAceroCfdi> {
  const headers = await getAuthHeaders(supabase);
  const qs = proveedor ? `?proveedor=${encodeURIComponent(proveedor)}` : '';
  const res = await fetch(`${BASE_URL}/acero/cfdi/${encodeURIComponent(facturaId)}/propuesta${qs}`, {
    headers,
  });
  if (!res.ok) {
    const err = await res.json().catch(() => ({}));
    throw new Error(err.error || 'Error al obtener propuesta de precios desde factura');
  }
  return res.json();
}

export async function aplicarPreciosAceroCfdiApi(
  supabase: any,
  facturaId: string,
  lineas: LineaAplicarAceroCfdi[]
): Promise<{ ok: boolean; total: number; aplicadas: any[] }> {
  const headers = await getAuthHeaders(supabase);
  const res = await fetch(`${BASE_URL}/acero/cfdi/${encodeURIComponent(facturaId)}/aplicar`, {
    method: 'POST',
    headers,
    body: JSON.stringify({ lineas }),
  });
  if (!res.ok) {
    const err = await res.json().catch(() => ({}));
    const error: any = new Error(err.error || 'Error al aplicar precios de acero');
    error.status = res.status;
    error.codigo = err.codigo;
    throw error;
  }
  return res.json();
}

export async function renombrarProveedorAceroApi(
  supabase: any,
  de: string,
  a: string
): Promise<{
  ok: boolean;
  de: string;
  a: string;
  precios_actualizados: number;
  alias_actualizados: number;
}> {
  const headers = await getAuthHeaders(supabase);
  const res = await fetch(`${BASE_URL}/acero/proveedores/renombrar`, {
    method: 'POST',
    headers,
    body: JSON.stringify({ de, a }),
  });
  if (!res.ok) {
    const err = await res.json().catch(() => ({}));
    const error: any = new Error(err.error || 'Error al renombrar proveedor');
    error.status = res.status;
    error.codigo = err.codigo;
    throw error;
  }
  return res.json();
}

export async function fetchCatalogoAliasApi(
  supabase: any,
  destinoTipo: string = 'acero_material'
): Promise<CatalogoAliasItem[]> {
  const headers = await getAuthHeaders(supabase);
  const qs = destinoTipo ? `?destino_tipo=${encodeURIComponent(destinoTipo)}` : '';
  const res = await fetch(`${BASE_URL}/catalogo-alias${qs}`, { headers });
  if (!res.ok) {
    const err = await res.json().catch(() => ({}));
    throw new Error(err.error || 'Error al cargar alias guardados');
  }
  const data = await res.json();
  return Array.isArray(data) ? data : Array.isArray(data?.alias) ? data.alias : [];
}

export async function eliminarCatalogoAliasApi(
  supabase: any,
  aliasId: string
): Promise<{ ok: boolean; eliminado: boolean }> {
  const headers = await getAuthHeaders(supabase);
  const res = await fetch(`${BASE_URL}/catalogo-alias/${encodeURIComponent(aliasId)}`, {
    method: 'DELETE',
    headers,
  });
  if (!res.ok) {
    const err = await res.json().catch(() => ({}));
    throw new Error(err.error || 'Error al eliminar alias');
  }
  return res.json();
}
