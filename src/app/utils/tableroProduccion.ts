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

const MESES_CORTOS_ES = [
  'ene', 'feb', 'mar', 'abr', 'may', 'jun',
  'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
];

const MESES_LARGOS_ES = [
  'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
  'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
];

/**
 * Parsea una fecha YYYY-MM-DD o ISO a partes { anio, mes, dia }
 * Evita la trampa del desfase UTC de `new Date('YYYY-MM-DD')`.
 */
export function parsearFechaPartes(fechaStr?: string | null): { anio: number; mes: number; dia: number } | null {
  if (!fechaStr || typeof fechaStr !== 'string') return null;
  const s = fechaStr.trim();
  if (!s) return null;

  // Formato simple YYYY-MM-DD (el estándar del backend)
  const matchSimple = /^(\d{4})-(\d{2})-(\d{2})/.exec(s);
  if (matchSimple) {
    const anio = parseInt(matchSimple[1], 10);
    const mes = parseInt(matchSimple[2], 10);
    const dia = parseInt(matchSimple[3], 10);
    if (!isNaN(anio) && !isNaN(mes) && !isNaN(dia)) {
      return { anio, mes, dia };
    }
  }

  // Fallback con Intl en zona horaria America/Mexico_City para timestamps completos
  try {
    const d = new Date(s);
    if (isNaN(d.getTime())) return null;
    const formateador = new Intl.DateTimeFormat('en-CA', {
      timeZone: 'America/Mexico_City',
      year: 'numeric',
      month: '2-digit',
      day: '2-digit'
    });
    const partes = formateador.format(d).split('-');
    return {
      anio: parseInt(partes[0], 10),
      mes: parseInt(partes[1], 10),
      dia: parseInt(partes[2], 10),
    };
  } catch {
    return null;
  }
}

/**
 * Formatea una fecha como "06 nov" o "14 nov" en español MX.
 */
export function formatearFechaCorta(fechaStr?: string | null): string {
  const partes = parsearFechaPartes(fechaStr);
  if (!partes) return '';
  const diaStr = String(partes.dia).padStart(2, '0');
  const mesStr = MESES_CORTOS_ES[partes.mes - 1] || '';
  return `${diaStr} ${mesStr}`;
}

/**
 * Formatea una fecha como "6 de noviembre" para aria-label y títulos accesibles.
 */
export function formatearFechaLarga(fechaStr?: string | null): string {
  const partes = parsearFechaPartes(fechaStr);
  if (!partes) return '';
  const mesStr = MESES_LARGOS_ES[partes.mes - 1] || '';
  return `${partes.dia} de ${mesStr}`;
}

const DIAS_SEMANA_ES = ['domingo', 'lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado'];

/**
 * Formatea la fecha de hoy para la cabecera superior, e.g. "jueves, 12 de noviembre de 2026".
 */
export function formatearFechaHoyCompleta(fechaStr?: string | null): string {
  const partes = parsearFechaPartes(fechaStr || obtenerHoyMexico());
  if (!partes) return '';
  const d = new Date(partes.anio, partes.mes - 1, partes.dia, 12, 0, 0);
  const diaSemana = DIAS_SEMANA_ES[d.getDay()] || '';
  const mesStr = MESES_LARGOS_ES[partes.mes - 1] || '';
  return `${diaSemana}, ${partes.dia} de ${mesStr} de ${partes.anio}`;
}

/**
 * Suma o resta días a una fecha YYYY-MM-DD sin desfase horario.
 */
export function sumarDiasAFecha(fechaStr?: string | null, dias: number = 0): string {
  const partes = parsearFechaPartes(fechaStr);
  if (!partes) return obtenerHoyMexico();
  const d = new Date(partes.anio, partes.mes - 1, partes.dia + dias);
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const dia = String(d.getDate()).padStart(2, '0');
  return `${y}-${m}-${dia}`;
}

export interface EstadoVisualCelda {
  estado: EstadoFase;
  texto: string;
  esVencida: boolean;
  claseColor: string;
  ariaLabel: string;
  simbolo: string;
}

/**
 * Deriva el texto, clases de color y accesibilidad de una celda de fase según la maqueta.
 */
export function calcularEstadoVisualCelda(
  celda?: {
    estado?: string | null;
    fecha_propuesta?: string | null;
    fecha_inicio?: string | null;
    fecha_fin?: string | null;
    nota?: string | null;
  } | null,
  nombreFase: string = 'Fase',
  hoyParam?: string
): EstadoVisualCelda {
  const estado = ((celda?.estado || 'pendiente').toLowerCase()) as EstadoFase;
  const hoy = hoyParam || obtenerHoyMexico();

  switch (estado) {
    case 'terminada': {
      const fecha = celda?.fecha_fin || celda?.fecha_propuesta;
      const fechaCorta = formatearFechaCorta(fecha);
      const fechaLarga = formatearFechaLarga(fecha);
      const texto = fechaCorta ? `✓ ${fechaCorta}` : '✓';
      const aria = fechaLarga
        ? `${nombreFase}: terminada el ${fechaLarga}`
        : `${nombreFase}: terminada`;
      return {
        estado: 'terminada',
        texto,
        esVencida: false,
        claseColor: 'text-[#22c55e] dark:text-[#91FFB0] bg-[#22c55e]/10 dark:bg-[#91FFB0]/10 border border-[#22c55e]/30 dark:border-[#91FFB0]/30 hover:bg-[#22c55e]/20',
        ariaLabel: aria,
        simbolo: '✓',
      };
    }

    case 'en_proceso': {
      const fechaPropuesta = celda?.fecha_propuesta;
      const esVencida = Boolean(fechaPropuesta && fechaPropuesta < hoy);
      const fechaCorta = formatearFechaCorta(fechaPropuesta);
      const fechaLarga = formatearFechaLarga(fechaPropuesta);

      let texto = fechaCorta ? `→ ${fechaCorta}` : '→ En proc';
      if (esVencida) {
        texto = fechaCorta ? `→ ${fechaCorta} !` : '→ Vencida !';
      }

      let aria = `${nombreFase}: en proceso`;
      if (fechaLarga) {
        aria += `, propuesta para el ${fechaLarga}`;
      }
      if (esVencida) {
        aria += ' (atrasada)';
      }

      const claseColor = esVencida
        ? 'text-destructive dark:text-[#FF919F] bg-destructive/10 dark:bg-[#FF919F]/10 border border-destructive/60 dark:border-[#FF919F]/60 hover:bg-destructive/20'
        : 'text-primary dark:text-[#A191FF] bg-primary/10 dark:bg-[#A191FF]/10 border border-primary/50 dark:border-[#A191FF]/50 hover:bg-primary/20';

      return {
        estado: 'en_proceso',
        texto,
        esVencida,
        claseColor,
        ariaLabel: aria,
        simbolo: '→',
      };
    }

    case 'incompleta': {
      return {
        estado: 'incompleta',
        texto: 'Material',
        esVencida: false,
        claseColor: 'text-destructive dark:text-[#FF919F] bg-destructive/10 dark:bg-[#FF919F]/10 border border-transparent hover:border-destructive/40',
        ariaLabel: `${nombreFase}: incompleta por material faltante`,
        simbolo: 'Material',
      };
    }

    case 'pausada': {
      return {
        estado: 'pausada',
        texto: 'Pausa',
        esVencida: false,
        claseColor: 'text-amber-500 dark:text-[#FFD391] bg-amber-500/10 dark:bg-[#FFD391]/10 border border-amber-500/30 dark:border-[#FFD391]/30 hover:bg-amber-500/20',
        ariaLabel: `${nombreFase}: en pausa`,
        simbolo: 'Pausa',
      };
    }

    case 'pendiente':
    default: {
      return {
        estado: 'pendiente',
        texto: '·',
        esVencida: false,
        claseColor: 'text-muted-foreground/40 bg-muted/20 border border-transparent hover:border-border/60 hover:text-foreground',
        ariaLabel: `${nombreFase}: pendiente`,
        simbolo: '·',
      };
    }
  }
}

export type TipoChipFiltro = 'todos' | 'atrasados' | 'con_material' | 'con_pausa';
export type FiltroChip = TipoChipFiltro;

function normalizarTextoBusqueda(str?: string | null): string {
  if (!str) return '';
  return str
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '');
}

/**
 * Filtra las filas de la matriz en el cliente según el chip de filtro activo y término de búsqueda.
 */
export function filtrarFilasMatriz(
  filas: any[],
  chipFiltro: TipoChipFiltro = 'todos',
  busqueda: string = ''
): any[] {
  if (!filas) return [];
  let resultado = [...filas];

  if (chipFiltro === 'atrasados') {
    resultado = resultado.filter(f => f.semaforo === 'atrasado');
  } else if (chipFiltro === 'con_material') {
    resultado = resultado.filter(f => f.material_faltante && String(f.material_faltante).trim() !== '');
  } else if (chipFiltro === 'con_pausa') {
    resultado = resultado.filter(f => {
      if (f.estado_kanban === 'pausada') return true;
      if (f.celdas && typeof f.celdas === 'object') {
        return Object.values(f.celdas).some((c: any) => c?.estado === 'pausada');
      }
      return false;
    });
  }

  if (busqueda && busqueda.trim() !== '') {
    const q = normalizarTextoBusqueda(busqueda.trim());
    resultado = resultado.filter(f => {
      const etiqueta = normalizarTextoBusqueda(f.etiqueta);
      const cliente = normalizarTextoBusqueda(f.cliente_nombre);
      const folio = normalizarTextoBusqueda(f.cotizacion_folio);
      const modelo = normalizarTextoBusqueda(f.modelo);
      const tipo = normalizarTextoBusqueda(f.tipo_equipo);
      const material = normalizarTextoBusqueda(f.material_faltante);
      return (
        etiqueta.includes(q) ||
        cliente.includes(q) ||
        folio.includes(q) ||
        modelo.includes(q) ||
        tipo.includes(q) ||
        material.includes(q)
      );
    });
  }

  return resultado;
}

export interface TarjetaPorFase {
  orden_id: string;
  fila: any;
  fase_id: string;
  fase_nombre: string;
  estado_fase: EstadoFase;
  fecha_propuesta?: string | null;
  fecha_fin?: string | null;
  nota?: string | null;
  material_faltante?: string | null;
  etiqueta: string;
  modelo?: string | null;
}

export interface ColumnaPorFase {
  id: string;
  titulo: string;
  orden: number;
  esPorIniciar: boolean;
  fase?: any;
  tarjetas: TarjetaPorFase[];
}

/**
 * Agrupa las filas de la matriz en columnas para la vista "Por fase".
 * Regla: Un equipo con dos fases activas aparece en ambas columnas.
 */
export function agruparPorFase(
  filas: any[],
  fasesPrincipales: any[]
): ColumnaPorFase[] {
  const columnas: ColumnaPorFase[] = [];

  // 1. Columna "Por iniciar"
  const tarjetasPorIniciar: TarjetaPorFase[] = [];
  for (const fila of (filas || [])) {
    const todasPendientes = !fila.celdas || Object.values(fila.celdas).every((c: any) => c?.estado === 'pendiente');
    if (fila.estado === 'Pendiente' || todasPendientes) {
      tarjetasPorIniciar.push({
        orden_id: fila.orden_id,
        fila,
        fase_id: 'por_iniciar',
        fase_nombre: 'Por iniciar',
        estado_fase: 'pendiente',
        fecha_propuesta: null,
        fecha_fin: null,
        nota: null,
        material_faltante: fila.material_faltante,
        etiqueta: fila.etiqueta,
        modelo: fila.modelo,
      });
    }
  }

  columnas.push({
    id: 'por_iniciar',
    titulo: 'Por iniciar',
    orden: 0,
    esPorIniciar: true,
    tarjetas: tarjetasPorIniciar,
  });

  // 2. Columnas por fase principal
  const fasesOrdenadas = [...(fasesPrincipales || [])].sort((a, b) => (a.orden || 0) - (b.orden || 0));

  for (const fp of fasesOrdenadas) {
    const tarjetasFase: TarjetaPorFase[] = [];

    for (const fila of (filas || [])) {
      const c = fila.celdas?.[fp.id];
      const estado = c?.estado;
      if (estado === 'en_proceso' || estado === 'incompleta' || estado === 'pausada') {
        tarjetasFase.push({
          orden_id: fila.orden_id,
          fila,
          fase_id: fp.id,
          fase_nombre: fp.nombre,
          estado_fase: estado as EstadoFase,
          fecha_propuesta: c.fecha_propuesta,
          fecha_fin: c.fecha_fin,
          nota: c.nota,
          material_faltante: fila.material_faltante,
          etiqueta: fila.etiqueta,
          modelo: fila.modelo,
        });
      }
    }

    columnas.push({
      id: fp.id,
      titulo: fp.nombre,
      orden: fp.orden,
      esPorIniciar: false,
      fase: fp,
      tarjetas: tarjetasFase,
    });
  }

  return columnas;
}

/**
 * Aplica un cambio de estado en una celda de manera optimista en la matriz local
 * y devuelve una copia de la fila anterior para permitir rollback.
 */
export function aplicarCambioOptimistaFase(
  filas: any[],
  ordenId: string,
  faseId: string,
  cambio: {
    estado: string;
    fecha_propuesta?: string | null;
    fecha_fin?: string | null;
    nota?: string | null;
  },
  fases: any[],
  hoyParam?: string
): { filasActualizadas: any[]; filaAnterior: any | null } {
  const hoy = hoyParam || obtenerHoyMexico();
  let filaAnterior: any = null;

  const filasActualizadas = (filas || []).map(f => {
    if (f.orden_id !== ordenId) return f;

    filaAnterior = JSON.parse(JSON.stringify(f));

    const celdasNuevas = { ...(f.celdas || {}) };
    const celdaActual = celdasNuevas[faseId] || {};

    let fechaFin = cambio.fecha_fin;
    if (cambio.estado === 'terminada') {
      fechaFin = fechaFin !== undefined ? fechaFin : hoy;
    } else if (cambio.estado !== 'terminada') {
      fechaFin = null;
    }

    celdasNuevas[faseId] = {
      ...celdaActual,
      estado: cambio.estado,
      fecha_propuesta: cambio.fecha_propuesta !== undefined ? cambio.fecha_propuesta : celdaActual.fecha_propuesta,
      fecha_fin: fechaFin,
      nota: cambio.nota !== undefined ? cambio.nota : celdaActual.nota,
    };

    let terminadasPrincipal = 0;
    let terminadasTina = 0;
    let totalPrincipal = 0;
    let totalTina = 0;

    for (const fase of (fases || [])) {
      const c = celdasNuevas[fase.id];
      if (fase.grupo === 'principal') {
        totalPrincipal++;
        if (c?.estado === 'terminada') terminadasPrincipal++;
      } else if (fase.grupo === 'tina') {
        totalTina++;
        if (c?.estado === 'terminada') terminadasTina++;
      }
    }

    const nuevoSemaforo = calcularSemaforo(celdasNuevas, hoy);

    return {
      ...f,
      celdas: celdasNuevas,
      semaforo: nuevoSemaforo,
      avance: {
        terminadas: terminadasPrincipal,
        total: totalPrincipal || f.avance?.total || 12,
      },
      tina: totalTina > 0 ? {
        terminadas: terminadasTina,
        total: totalTina,
      } : null,
    };
  });

  return { filasActualizadas, filaAnterior };
}
