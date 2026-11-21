import { BASE_URL } from '../../utils/api';
import { supabase } from '../../utils/supabase/client';
import {
  FormatoCalidad,
  PlantillaCalidad,
  traducirErrorCalidad,
} from './calidadUtils';

export class CalidadApiError extends Error {
  status: number;
  codigo?: string;
  inspeccionId?: string;

  constructor(message: string, status: number, codigo?: string, inspeccionId?: string) {
    super(message);
    this.status = status;
    this.codigo = codigo;
    this.inspeccionId = inspeccionId;
  }
}

async function getAuthHeaders(): Promise<Record<string, string>> {
  const { data } = await supabase.auth.getSession();
  const token = data.session?.access_token;
  if (!token) {
    throw new CalidadApiError('Sesión no válida. Inicia sesión nuevamente.', 401, 'NO_AUTORIZADO');
  }
  return {
    'Content-Type': 'application/json',
    Authorization: `Bearer ${token}`,
  };
}

async function requestCalidad<T = any>(path: string, init?: RequestInit): Promise<T> {
  const headers = await getAuthHeaders();
  const res = await fetch(`${BASE_URL}${path}`, {
    ...init,
    headers: {
      ...headers,
      ...(init?.headers || {}),
    },
  });

  let body: any = null;
  try {
    body = await res.json();
  } catch {
    body = null;
  }

  if (!res.ok) {
    const codigo = body?.codigo as string | undefined;
    const msg = traducirErrorCalidad(codigo, body?.error || `Error HTTP ${res.status}`);
    throw new CalidadApiError(msg, res.status, codigo, body?.inspeccion_id);
  }

  return body as T;
}

export const calidadApi = {
  listarPlantillas(filtros?: { formato?: string; linea?: string; estado?: string }) {
    const params = new URLSearchParams();
    if (filtros?.formato) params.set('formato', filtros.formato);
    if (filtros?.linea) params.set('linea', filtros.linea);
    if (filtros?.estado) params.set('estado', filtros.estado);
    const qs = params.toString();
    return requestCalidad<PlantillaCalidad[]>(`/calidad/plantillas${qs ? `?${qs}` : ''}`);
  },

  obtenerPlantilla(id: string) {
    return requestCalidad<PlantillaCalidad>(`/calidad/plantillas/${id}`);
  },

  crearPlantilla(body: { formato: FormatoCalidad; linea_clave: string; nombre?: string; duplicar_de?: string }) {
    return requestCalidad<PlantillaCalidad>('/calidad/plantillas', {
      method: 'POST',
      body: JSON.stringify(body),
    });
  },

  guardarPlantilla(id: string, payload: Record<string, unknown>) {
    return requestCalidad<PlantillaCalidad>(`/calidad/plantillas/${id}`, {
      method: 'PUT',
      body: JSON.stringify(payload),
    });
  },

  nuevaVersionPlantilla(id: string) {
    return requestCalidad<PlantillaCalidad>(`/calidad/plantillas/${id}/nueva-version`, {
      method: 'POST',
    });
  },

  publicarPlantilla(id: string) {
    return requestCalidad<PlantillaCalidad>(`/calidad/plantillas/${id}/publicar`, {
      method: 'POST',
    });
  },

  eliminarPlantilla(id: string) {
    return requestCalidad<{ success: boolean }>(`/calidad/plantillas/${id}`, {
      method: 'DELETE',
    });
  },

  crearInspeccion(body: { orden_trabajo_id: string; formato: FormatoCalidad; plantilla_id?: string | null }) {
    return requestCalidad<any>('/calidad/inspecciones', {
      method: 'POST',
      body: JSON.stringify(body),
    });
  },

  listarInspecciones(filtros?: {
    orden_trabajo_id?: string;
    formato?: string;
    estado?: string;
    con_no_conformes?: boolean;
  }) {
    const params = new URLSearchParams();
    if (filtros?.orden_trabajo_id) params.set('orden_trabajo_id', filtros.orden_trabajo_id);
    if (filtros?.formato) params.set('formato', filtros.formato);
    if (filtros?.estado) params.set('estado', filtros.estado);
    if (filtros?.con_no_conformes) params.set('con_no_conformes', 'true');
    const qs = params.toString();
    return requestCalidad<any[]>(`/calidad/inspecciones${qs ? `?${qs}` : ''}`);
  },

  obtenerInspeccion(id: string) {
    return requestCalidad<any>(`/calidad/inspecciones/${id}`);
  },

  actualizarEncabezadoInspeccion(id: string, body: Record<string, unknown>) {
    return requestCalidad<any>(`/calidad/inspecciones/${id}`, {
      method: 'PUT',
      body: JSON.stringify(body),
    });
  },

  guardarResultados(id: string, resultados: Array<Record<string, unknown>>) {
    return requestCalidad<any>(`/calidad/inspecciones/${id}/resultados`, {
      method: 'PUT',
      body: JSON.stringify({ resultados }),
    });
  },

  cerrarInspeccion(id: string, body?: { liberado_por?: string | null; fecha_liberacion?: string | null }) {
    return requestCalidad<any>(`/calidad/inspecciones/${id}/cerrar`, {
      method: 'POST',
      body: JSON.stringify(body || {}),
    });
  },

  reabrirInspeccion(id: string) {
    return requestCalidad<any>(`/calidad/inspecciones/${id}/reabrir`, {
      method: 'POST',
    });
  },

  resumenOrdenes() {
    return requestCalidad<any[]>('/calidad/resumen-ordenes');
  },

  listarOperarios() {
    return requestCalidad<any[]>('/produccion/operarios');
  },
};
