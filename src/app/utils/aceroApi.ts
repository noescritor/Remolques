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
  cantidad: number;
  precio_unitario_xml: number;
  importe_xml: number;
  clave_unidad: string | null;
  unidad_label: string;
  factor_sugerido: number | null;
  origen_coincidencia: 'recordado' | 'sugerido' | 'sin_sugerencia';
  material_id_sugerido: string | null;
  material_nombre_sugerido: string | null;
  puntaje_sugerencia: number;
  alias_id: string | null;
  precio_actual: number | null;
  precio_actual_incluye_iva: boolean | null;
  precio_nuevo_sin_iva: number | null;
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
  aplicacion_previa: {
    material_id: string;
    proveedor_acero: string;
    precio_aplicado: number;
    aplicado_el: string;
  } | null;
}

export interface PropuestaAceroCfdi {
  factura: {
    id: string;
    folio: string;
    fecha_emision: string;
    moneda: string;
    tipo_cambio_emision: number | null;
    estado: string;
    uuid_fiscal: string | null;
    proveedor_cxp_id: string | null;
    proveedor_cxp_nombre: string | null;
    emisor_rfc: string | null;
    emisor_nombre: string | null;
    tiene_descuentos: boolean;
    descuento_total: number;
  };
  proveedor_acero_sugerido: string;
  proveedores_acero_disponibles: string[];
  materiales_catalogo: Array<{ id: string; nombre: string; tipo: string }>;
  precios_actuales: Array<{
    material_id: string;
    proveedor: string;
    precio: number;
    incluye_iva: boolean;
    fuente: string | null;
  }>;
  partidas: PropuestaPartidaAcero[];
}

export interface LineaAplicarAceroCfdi {
  partida_id: string;
  material_id: string;
  proveedor_acero: string;
  factor_conversion?: number;
  recordar_alias?: boolean;
  confirmar_fecha_anterior?: boolean;
  confirmar_variacion_alta?: boolean;
}

export interface CatalogoAliasItem {
  id: string;
  destino_tipo: string;
  destino_id: string;
  destino_nombre: string | null;
  proveedor_rfc: string | null;
  descripcion_original: string;
  descripcion_normalizada: string;
  clave_unidad: string | null;
  factor_conversion: number | null;
  usos: number;
  creado_el: string;
  actualizado_el: string;
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
): Promise<{ ok: boolean; aplicadas: number; alias_guardados: number; fuente: string; factura_id: string }> {
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
  nombreActual: string,
  nombreNuevo: string
): Promise<{
  ok: boolean;
  nombre_actual: string;
  nombre_nuevo: string;
  precios_actualizados: number;
  historial_actualizado: number;
  aplicaciones_actualizadas: number;
}> {
  const headers = await getAuthHeaders(supabase);
  const res = await fetch(`${BASE_URL}/acero/proveedores/renombrar`, {
    method: 'POST',
    headers,
    body: JSON.stringify({ nombre_actual: nombreActual, nombre_nuevo: nombreNuevo }),
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
  return Array.isArray(data?.alias) ? data.alias : [];
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
