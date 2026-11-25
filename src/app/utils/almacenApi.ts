/**
 * Cliente API y utilidades de formato para Recepción de Facturas en Almacén (Bloque G)
 */

import { BASE_URL } from './api';

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
    console.warn('[almacenApi] No se pudo obtener sesión:', err);
  }
  return headers;
}

/**
 * Formatea cantidades de stock (NUMERIC(14,4)) para la interfaz:
 * - Enteros sin decimales: 12 -> "12" (nunca "12.0000")
 * - Fracciones solo con los decimales necesarios: 12.5000 -> "12.5", 0.3333 -> "0.3333"
 */
export function formatearCantidadStock(v: number | string | null | undefined): string {
  const n = Number(v ?? 0);
  if (!Number.isFinite(n)) return '0';
  if (Math.abs(n - Math.round(n)) < 1e-6) {
    return String(Math.round(n));
  }
  return String(Number(n.toFixed(4)));
}

export interface PropuestaLineaAlmacen {
  partida_id: string;
  orden: number;
  descripcion: string;
  descripcion_normalizada: string;
  clave_sat: string | null;
  clave_unidad: string | null;
  cantidad_xml: number;
  precio_unitario_xml: number;
  importe: number;
  sugerencia_origen: 'alias' | 'similitud' | 'ninguna';
  sugerencia_puntaje: number;
  producto_id_sugerido: string | null;
  factor_conversion_sugerido: number;
  cantidad_recibir_sugerida: number | null;
  costo_unitario_mxn: number | null;
  costo_catalogo: number | null;
  diferencia_costo_pct: number | null;
  stock_actual: number | null;
  ultimo_costo_compra: number | null;
  ultimo_costo_compra_fecha: string | null;
  folios_compras_duplicadas: string[];
  banderas: {
    ya_recibida: boolean;
    compra_ya_recibida: boolean;
    posible_compra_duplicada: boolean;
    costo_fecha_anterior: boolean;
    requiere_factor: boolean;
    bloqueada_unidad: boolean;
    revisar_unidad: boolean;
    bloqueada_tipo_cambio: boolean;
    descuento_en_factura: boolean;
    es_servicio_probable: boolean;
  };
}

export interface PropuestaRecepcionAlmacen {
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
    compra_id: string | null;
    descuento_en_factura: boolean;
  };
  compra_ya_recibida: boolean;
  posible_compra_duplicada: boolean;
  folios_compras_duplicadas: string[];
  folios_por_producto: Record<string, string[]>;
  productos: Array<{
    id: string;
    nombre: string;
    unidad: string;
    tipo_item: string;
    costo: number | null;
    stock_actual: number;
    ultimo_costo_compra: number | null;
    ultimo_costo_compra_fecha: string | null;
  }>;
  lineas: PropuestaLineaAlmacen[];
}

export interface LineaRecibirAlmacen {
  partida_id: string;
  producto_id: string;
  factor_conversion?: number;
  factor_confirmado?: boolean;
  cantidad_recibida?: number;
  guardar_alias?: boolean;
  descripcion_normalizada?: string;
  notas?: string;
}

export interface RecepcionAlmacenItem {
  id: string;
  factura_id: string;
  factura_folio: string;
  factura_fecha_emision: string | null;
  factura_moneda: string;
  proveedor_id: string | null;
  proveedor_nombre: string | null;
  estado: 'recibida' | 'anulada';
  notas: string | null;
  created_at: string;
  anulada_el: string | null;
  motivo_anulacion: string | null;
  lineas: Array<{
    id: string;
    partida_id: string;
    producto_id: string;
    producto_nombre: string;
    producto_unidad: string;
    cantidad_xml: number;
    unidad_xml: string | null;
    factor_conversion: number;
    cantidad_recibida: number;
    costo_unitario_mxn: number;
    costo_actualizado: boolean;
    activa: boolean;
    notas: string | null;
  }>;
}

export async function fetchPropuestaAlmacenApi(
  supabase: any,
  facturaId: string
): Promise<PropuestaRecepcionAlmacen> {
  const headers = await getAuthHeaders(supabase);
  const res = await fetch(`${BASE_URL}/almacen/facturas/${encodeURIComponent(facturaId)}/propuesta`, {
    headers,
  });
  if (!res.ok) {
    const err = await res.json().catch(() => ({}));
    throw new Error(err.error || 'No se pudo obtener la propuesta de recepción en almacén');
  }
  return res.json();
}

export async function recibirFacturaAlmacenApi(
  supabase: any,
  facturaId: string,
  payload: {
    lineas: LineaRecibirAlmacen[];
    confirmo_doble?: boolean;
    notas?: string;
  }
): Promise<{
  ok: boolean;
  recepcion_id: string;
  total_lineas: number;
  lineas: Array<{
    partida_id: string;
    producto_id: string;
    producto_nombre: string;
    cantidad_recibida: number;
    costo_unitario_mxn: number;
    costo_actualizado: boolean;
  }>;
}> {
  const headers = await getAuthHeaders(supabase);
  const res = await fetch(`${BASE_URL}/almacen/facturas/${encodeURIComponent(facturaId)}/recibir`, {
    method: 'POST',
    headers,
    body: JSON.stringify(payload),
  });
  if (!res.ok) {
    const err = await res.json().catch(() => ({}));
    const error: any = new Error(err.error || 'Error al recibir factura en almacén');
    error.status = res.status;
    error.codigo = err.codigo;
    throw error;
  }
  return res.json();
}

export async function fetchRecepcionesAlmacenApi(
  supabase: any,
  filtros?: { facturaId?: string; productoId?: string; estado?: string; limite?: number }
): Promise<RecepcionAlmacenItem[]> {
  const headers = await getAuthHeaders(supabase);
  const params = new URLSearchParams();
  if (filtros?.facturaId) params.set('factura_id', filtros.facturaId);
  if (filtros?.productoId) params.set('producto_id', filtros.productoId);
  if (filtros?.estado && filtros.estado !== 'todas') params.set('estado', filtros.estado);
  if (filtros?.limite) params.set('limite', String(filtros.limite));
  const qs = params.toString() ? `?${params.toString()}` : '';
  const res = await fetch(`${BASE_URL}/almacen/recepciones${qs}`, { headers });
  if (!res.ok) {
    const err = await res.json().catch(() => ({}));
    throw new Error(err.error || 'Error al cargar recepciones de almacén');
  }
  const data = await res.json();
  return Array.isArray(data) ? data : [];
}

export async function anularRecepcionAlmacenApi(
  supabase: any,
  recepcionId: string,
  motivo: string
): Promise<{ ok: boolean; recepcion_id: string; lineas_anuladas: number }> {
  const headers = await getAuthHeaders(supabase);
  const res = await fetch(`${BASE_URL}/almacen/recepciones/${encodeURIComponent(recepcionId)}/anular`, {
    method: 'POST',
    headers,
    body: JSON.stringify({ motivo }),
  });
  if (!res.ok) {
    const err = await res.json().catch(() => ({}));
    const error: any = new Error(err.error || 'Error al anular recepción de almacén');
    error.status = res.status;
    error.codigo = err.codigo;
    throw error;
  }
  return res.json();
}
