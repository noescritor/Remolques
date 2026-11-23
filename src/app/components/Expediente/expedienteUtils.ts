/**
 * Funciones puras del Expediente por Equipo (Bloque H).
 * Sin dependencias de React ni de DOM para poder probarlas directamente en Deno.
 */

export type TabExpediente =
  | 'resumen'
  | 'cotizacion'
  | 'orden'
  | 'plan'
  | 'almacen'
  | 'calidad'
  | 'cobranza';

export const TABS_EXPEDIENTE: TabExpediente[] = [
  'resumen',
  'cotizacion',
  'orden',
  'plan',
  'almacen',
  'calidad',
  'cobranza',
];

export function normalizarTabExpediente(raw: string | null | undefined): TabExpediente {
  const val = String(raw || '').trim().toLowerCase() as TabExpediente;
  return TABS_EXPEDIENTE.includes(val) ? val : 'resumen';
}

export interface FaseOrdenTablero {
  fase_id?: string | null;
  id?: string | null;
  nombre?: string | null;
  clave?: string | null;
  orden?: number | null;
  estado?: string | null;
}

export type EstadoVisualFase = 'en_curso' | 'pasada' | 'futura';

export function faseEnCurso<T extends FaseOrdenTablero>(fases: T[] | null | undefined): T | null {
  if (!Array.isArray(fases) || fases.length === 0) return null;
  const ordenadas = [...fases].sort((a, b) => Number(a.orden ?? 999) - Number(b.orden ?? 999));

  const enProceso = ordenadas.find((f) => f.estado === 'en_proceso');
  if (enProceso) return enProceso;

  const primeraNoTerminada = ordenadas.find((f) => f.estado !== 'terminada');
  return primeraNoTerminada || null;
}

export function estadoVisualFase(
  fase: FaseOrdenTablero,
  enCurso: FaseOrdenTablero | null | undefined
): EstadoVisualFase {
  if (fase.estado === 'terminada') return 'pasada';
  if (!enCurso) return 'pasada';

  const idFase = fase.fase_id || fase.id || null;
  const idCurso = enCurso.fase_id || enCurso.id || null;
  if (idFase && idCurso && idFase === idCurso) return 'en_curso';
  if (
    !idFase &&
    !idCurso &&
    fase.orden !== undefined &&
    fase.orden !== null &&
    Number(fase.orden) === Number(enCurso.orden)
  ) {
    return 'en_curso';
  }

  if (Number(fase.orden ?? 999) < Number(enCurso.orden ?? 999)) {
    return 'pasada';
  }
  return 'futura';
}

export interface LineaDespieceResumen {
  fase_clave?: string | null;
  cantidad_requerida?: number | string | null;
  cantidad_entregada?: number | string | null;
  estado_entrega?: string | null;
  anulada?: boolean | null;
}

export function esPartidaCompletaLinea(linea: LineaDespieceResumen): boolean {
  if (linea.estado_entrega !== undefined && linea.estado_entrega !== null) {
    return linea.estado_entrega === 'completo';
  }
  const req = Number(linea.cantidad_requerida ?? 0);
  const ent = Number(linea.cantidad_entregada ?? 0);
  return ent > 0 && ent >= req;
}

export function extraerTareasPlan(res: any): any[] {
  if (Array.isArray(res)) return res;
  if (res && Array.isArray(res.tareas)) return res.tareas;
  return [];
}

export interface ResumenFaseDespiece {
  total_partidas: number;
  partidas_completas: number;
  porcentaje: number | null;
}

export interface ResumenEntregasExpediente {
  total_partidas: number;
  partidas_completas: number;
  por_fase: Record<string, ResumenFaseDespiece>;
}

export function porcentajeEntregas(
  resumen: { total_partidas: number; partidas_completas: number } | null | undefined
): number | null {
  if (!resumen || resumen.total_partidas <= 0) return null;
  return Math.round((resumen.partidas_completas / resumen.total_partidas) * 100);
}

export function resumenEntregasPorFase(
  lineas: LineaDespieceResumen[] | null | undefined
): ResumenEntregasExpediente {
  const porFase: Record<string, { total_partidas: number; partidas_completas: number }> = {};
  let totalPartidas = 0;
  let partidasCompletas = 0;

  for (const linea of lineas || []) {
    if (!linea || linea.anulada) continue;
    const completa = esPartidaCompletaLinea(linea);

    totalPartidas += 1;
    if (completa) partidasCompletas += 1;

    const faseClave = String(linea.fase_clave || 'sin_fase').trim() || 'sin_fase';
    if (!porFase[faseClave]) {
      porFase[faseClave] = { total_partidas: 0, partidas_completas: 0 };
    }
    porFase[faseClave].total_partidas += 1;
    if (completa) porFase[faseClave].partidas_completas += 1;
  }

  const porFaseConPct: Record<string, ResumenFaseDespiece> = {};
  for (const [clave, datos] of Object.entries(porFase)) {
    porFaseConPct[clave] = {
      total_partidas: datos.total_partidas,
      partidas_completas: datos.partidas_completas,
      porcentaje: porcentajeEntregas(datos),
    };
  }

  return {
    total_partidas: totalPartidas,
    partidas_completas: partidasCompletas,
    por_fase: porFaseConPct,
  };
}

/**
 * La atenuación de "fase futura" es estrictamente visual.
 * Las entregas de almacén se permiten en cualquier orden de fases.
 */
export function puedeLiberarFase(
  _faseClave?: string | null,
  _estadoVisual?: EstadoVisualFase
): { permitido: true; motivo: null } {
  return { permitido: true, motivo: null };
}

export function estadoVacioPestana(
  pestana: 'cotizacion' | 'almacen' | 'plan' | 'cobranza',
  ctx: {
    cotizacionId?: string | null;
    totalLineasDespiece?: number;
    admiteDespiece?: boolean;
    totalTareasPlan?: number;
    totalPagos?: number;
  }
): { vacio: boolean; titulo: string; mensaje: string } {
  if (pestana === 'cotizacion') {
    if (!ctx.cotizacionId) {
      return {
        vacio: true,
        titulo: 'Equipo sin cotización vinculada',
        mensaje:
          'Este equipo se registró de forma manual en planta y no tiene una cotización o presupuesto de origen.',
      };
    }
    return { vacio: false, titulo: '', mensaje: '' };
  }

  if (pestana === 'cobranza') {
    if (!ctx.cotizacionId) {
      return {
        vacio: true,
        titulo: 'Sin cotización para consultar pagos',
        mensaje:
          'Este equipo no proviene de una cotización. Los pagos se vinculan a nivel de cotización.',
      };
    }
    if ((ctx.totalPagos ?? 0) === 0) {
      return {
        vacio: true,
        titulo: 'Sin pagos registrados en la cotización',
        mensaje: 'Aún no hay abonos registrados para la cotización vinculada a este equipo.',
      };
    }
    return { vacio: false, titulo: '', mensaje: '' };
  }

  if (pestana === 'almacen') {
    if (ctx.admiteDespiece === false) {
      return {
        vacio: true,
        titulo: 'Línea sin despiece parametrizado',
        mensaje:
          'Este equipo corresponde a una línea o modelo sin receta de despiece configurada.',
      };
    }
    if ((ctx.totalLineasDespiece ?? 0) === 0) {
      return {
        vacio: true,
        titulo: 'Despiece aún no generado',
        mensaje:
          'Genera el despiece para listar los materiales por fase y registrar entregas de almacén.',
      };
    }
    return { vacio: false, titulo: '', mensaje: '' };
  }

  if ((ctx.totalTareasPlan ?? 0) === 0) {
    return {
      vacio: true,
      titulo: 'Sin tareas en plan semanal',
      mensaje: 'Este equipo aún no tiene tareas asignadas en la planeación semanal.',
    };
  }
  return { vacio: false, titulo: '', mensaje: '' };
}

export function resolverPresupuestoDeOrden(
  orden: { cotizacion_id?: string | null; cotizacion?: { folio?: string | null } | null } | null | undefined,
  presupuestos: Array<{ id: string; folio?: string | null; cotizacion_id?: string | null }>
) {
  if (!orden?.cotizacion_id || !Array.isArray(presupuestos)) return null;
  const porCotizacion = presupuestos.find((p) => p.cotizacion_id === orden.cotizacion_id);
  if (porCotizacion) return porCotizacion;

  const folioCot = orden.cotizacion?.folio;
  if (folioCot) {
    const folioEsperado = `PRE-${folioCot}`;
    return presupuestos.find((p) => p.folio === folioEsperado) || null;
  }
  return null;
}
