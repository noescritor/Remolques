// Utilidades y funciones puras para el Tablero de Producción (Matriz de fases y Kanban)

export type EstadoFase = 'pendiente' | 'en_proceso' | 'incompleta' | 'pausada' | 'terminada';
export type SemaforoProduccion = 'terminado' | 'por_iniciar' | 'atrasado' | 'detenido' | 'en_tiempo';

export interface CeldaSemaforoInput {
  estado: string;
  fecha_propuesta?: string | null;
  fecha_inicio?: string | null;
  fecha_fin?: string | null;
}

/**
 * Mapa oficial de tipos de equipo a clave de línea de producción
 * 01: Plataforma (omisión)
 * 02: Dolly
 * 03: Góndola
 * 04: Jaula -> Plataforma
 * 05: Cama Baja -> Plataforma
 * 06: Multimodal -> Plataforma
 * 07: Portacontenedor -> Plataforma
 * 08: Caja Seca -> Plataforma
 * 09: Traila -> Traila
 */
export const MAPA_TIPO_EQUIPO_LINEA: Record<string, string> = {
  "01": "plataforma",
  "02": "dolly",
  "03": "gondola",
  "04": "plataforma",
  "05": "plataforma",
  "06": "plataforma",
  "07": "plataforma",
  "08": "plataforma",
  "09": "traila",
};

export function obtenerLineaPorTipoEquipo(tipo?: string | null): string {
  if (!tipo) return "plataforma";
  const t = tipo.trim();
  if (MAPA_TIPO_EQUIPO_LINEA[t]) return MAPA_TIPO_EQUIPO_LINEA[t];
  const lower = t.toLowerCase();
  if (lower.includes("dolly")) return "dolly";
  if (lower.includes("gondola") || lower.includes("góndola")) return "gondola";
  if (lower.includes("traila")) return "traila";
  return "plataforma";
}

/**
 * Obtiene la fecha actual en zona horaria America/Mexico_City en formato YYYY-MM-DD
 */
export function obtenerHoyMexico(): string {
  const formateador = new Intl.DateTimeFormat('en-CA', {
    timeZone: 'America/Mexico_City',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit'
  });
  return formateador.format(new Date());
}

/**
 * Calcula el semáforo de un equipo a partir de sus celdas de fases.
 * Precedencia estricta:
 * 1. 'terminado': Todas las fases terminadas (mínimo 1 fase).
 * 2. 'por_iniciar': Ninguna fase iniciada (todas pendientes).
 * 3. 'atrasado': Alguna fase 'en_proceso' con fecha_propuesta < hoy (la tina cuenta).
 * 4. 'detenido': Alguna fase 'incompleta' o 'pausada'.
 * 5. 'en_tiempo': En cualquier otro caso en producción.
 */
export function calcularSemaforo(
  celdas: Array<CeldaSemaforoInput> | Record<string, CeldaSemaforoInput>,
  hoyParam?: string
): SemaforoProduccion {
  const lista: CeldaSemaforoInput[] = Array.isArray(celdas) 
    ? celdas 
    : Object.values(celdas || {});

  if (!lista || lista.length === 0) {
    return 'por_iniciar';
  }

  const hoy = hoyParam || obtenerHoyMexico();

  const total = lista.length;
  let terminadas = 0;
  let pendientes = 0;
  let enProceso = 0;
  let atrasadas = 0;
  let detenidas = 0;

  for (const c of lista) {
    const est = (c.estado || 'pendiente').toLowerCase();
    if (est === 'terminada') {
      terminadas++;
    } else if (est === 'pendiente') {
      pendientes++;
    } else if (est === 'incompleta' || est === 'pausada') {
      detenidas++;
    } else if (est === 'en_proceso') {
      enProceso++;
      if (c.fecha_propuesta && c.fecha_propuesta < hoy) {
        atrasadas++;
      }
    }
  }

  // 1. Todas terminadas
  if (terminadas === total) {
    return 'terminado';
  }

  // 2. Ninguna iniciada
  if (pendientes === total) {
    return 'por_iniciar';
  }

  // 3. Atrasado (alguna en proceso con fecha propuesta vencida)
  if (atrasadas > 0) {
    return 'atrasado';
  }

  // 4. Detenido (alguna incompleta o pausada)
  if (detenidas > 0) {
    return 'detenido';
  }

  // 5. En tiempo
  return 'en_tiempo';
}

/**
 * Calcula la etiqueta visible de la orden:
 * 1. Si existe etiqueta manual -> usar etiqueta manual.
 * 2. Si no -> "{cliente} #{n}" con n = posición por created_at entre órdenes del mismo cliente y línea,
 *    solo si hay más de una. Si solo hay una -> "{cliente}".
 */
export function calcularEtiquetaVisible(
  orden: {
    id?: string;
    etiqueta?: string | null;
    cliente_nombre?: string | null;
    created_at?: string | null;
  },
  ordenesMismoClienteyLinea?: Array<{ id: string; created_at?: string | null }>
): string {
  if (orden.etiqueta && orden.etiqueta.trim() !== '') {
    return orden.etiqueta.trim();
  }

  const nombreCliente = (orden.cliente_nombre || '').trim() || 'Inventario';

  if (!ordenesMismoClienteyLinea || ordenesMismoClienteyLinea.length <= 1) {
    return nombreCliente;
  }

  // Ordenar determinísticamente por created_at ASC y luego id ASC
  const ordenadas = [...ordenesMismoClienteyLinea].sort((a, b) => {
    const tA = a.created_at ? new Date(a.created_at).getTime() : 0;
    const tB = b.created_at ? new Date(b.created_at).getTime() : 0;
    if (tA !== tB) return tA - tB;
    return (a.id || '').localeCompare(b.id || '');
  });

  const indice = ordenadas.findIndex(o => o.id === orden.id);
  const numero = indice >= 0 ? indice + 1 : 1;
  return `${nombreCliente} #${numero}`;
}
