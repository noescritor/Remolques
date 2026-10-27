// Utilidades puras para el Plan Semanal de Producción (Sub-bloque 2R-15)
// Sin dependencias de React ni de red. Ejecutable en navegador y Deno.

export type EstadoPlanTarea = 'planeada' | 'en_proceso' | 'pausada' | 'terminada' | 'cancelada';

export interface OperarioRef {
  id: string;
  nombre?: string;
  puesto?: string | null;
  telefono?: string | null;
  activo?: boolean;
}

export interface MaterialItem {
  id?: string;
  producto_id?: string | null;
  descripcion: string;
  cantidad: number;
  unidad: string;
  notas?: string | null;
}

export interface PlanTarea {
  id: string;
  organizacion_id?: string;
  fecha: string; // YYYY-MM-DD
  frente_id: string;
  orden_trabajo_id?: string | null;
  descripcion?: string | null;
  movilidad?: string | null;
  observaciones?: string | null;
  estado: EstadoPlanTarea;
  inicio_real?: string | null;
  fin_real?: string | null;
  material_faltante?: boolean;
  operarios?: (OperarioRef | string)[];
  materiales?: MaterialItem[];
  frente?: { id: string; nombre: string; area_id: string };
  orden_trabajo?: { id: string; nomenclatura_id?: string; modelo?: string; cliente?: { nombre?: string } };
}

export interface ConflictoOperario {
  operarioId: string;
  fecha: string;
  tareaIds: string[];
}

export interface TotalesPersonalResult {
  // Conteo de operarios distintos que laboraron ese día en el área (columna TOT del Excel)
  porDia: Record<string, number>;
  // Conteo de asignaciones de operario por frente durante la semana (fila TOTAL DE PERSONAL del Excel)
  porFrente: Record<string, number>;
  // Suma total de asignaciones operario-frente en la semana
  totalAsignaciones: number;
  // Conteo de operarios únicos que trabajaron en el área en toda la semana
  operariosUnicosSemana: number;
}

export interface NuevaTareaPayload {
  fecha: string;
  frente_id: string;
  orden_trabajo_id?: string | null;
  descripcion?: string | null;
  movilidad?: string | null;
  observaciones?: string | null;
  estado: 'planeada';
  inicio_real: null;
  fin_real: null;
  material_faltante: false;
  operarios: string[];
  materiales: {
    producto_id?: string | null;
    descripcion: string;
    cantidad: number;
    unidad: string;
    notas?: string | null;
  }[];
}

const MESES = [
  'ENERO', 'FEBRERO', 'MARZO', 'ABRIL', 'MAYO', 'JUNIO',
  'JULIO', 'AGOSTO', 'SEPTIEMBRE', 'OCTUBRE', 'NOVIEMBRE', 'DICIEMBRE'
];

const DIAS_SEMANA = [
  'DOMINGO', 'LUNES', 'MARTES', 'MIÉRCOLES', 'JUEVES', 'VIERNES', 'SÁBADO'
];

/**
 * Parsea una fecha en string YYYY-MM-DD o Date a componentes locales [año, mes (0-11), día].
 * Evita conversiones UTC que desfasen el día según la zona horaria del cliente.
 */
export function parsearFechaLocal(fecha: string | Date): { y: number; m: number; d: number } {
  if (fecha instanceof Date) {
    return {
      y: fecha.getFullYear(),
      m: fecha.getMonth(),
      d: fecha.getDate(),
    };
  }
  const partes = String(fecha).trim().split('T')[0].split('-');
  if (partes.length !== 3) {
    throw new Error(`Formato de fecha inválido: ${fecha}. Se espera YYYY-MM-DD`);
  }
  const y = parseInt(partes[0], 10);
  const m = parseInt(partes[1], 10) - 1;
  const d = parseInt(partes[2], 10);
  if (isNaN(y) || isNaN(m) || isNaN(d)) {
    throw new Error(`Fecha no numérica: ${fecha}`);
  }
  return { y, m, d };
}

export function formatearFechaISO(y: number, m: number, d: number): string {
  const mm = String(m + 1).padStart(2, '0');
  const dd = String(d).padStart(2, '0');
  return `${y}-${mm}-${dd}`;
}

/**
 * 1. inicioDeSemana(fecha) -> devuelve el lunes de la semana correspondiente en formato YYYY-MM-DD.
 * Para domingos (día 0), retrocede al lunes de esa misma semana (6 días antes).
 */
export function inicioDeSemana(fecha: string | Date): string {
  const { y, m, d } = parsearFechaLocal(fecha);
  const fechaObj = new Date(y, m, d, 12, 0, 0);
  const diaSem = fechaObj.getDay(); // 0 = Domingo, 1 = Lunes, ..., 6 = Sábado
  const diasARestar = diaSem === 0 ? 6 : diaSem - 1;

  fechaObj.setDate(fechaObj.getDate() - diasARestar);
  return formatearFechaISO(fechaObj.getFullYear(), fechaObj.getMonth(), fechaObj.getDate());
}

/**
 * 2. diasDeSemana(lunes, { sabado }) -> devuelve 5 o 6 fechas de lunes a viernes/sábado.
 */
export function diasDeSemana(lunes: string, opciones?: { sabado?: boolean }): string[] {
  const { y, m, d } = parsearFechaLocal(lunes);
  const totalDias = opciones?.sabado ? 6 : 5;
  const resultado: string[] = [];

  for (let i = 0; i < totalDias; i++) {
    const fechaObj = new Date(y, m, d + i, 12, 0, 0);
    resultado.push(formatearFechaISO(fechaObj.getFullYear(), fechaObj.getMonth(), fechaObj.getDate()));
  }

  return resultado;
}

/**
 * etiquetaDia(fecha) -> 'LUNES 19/10/26' (como el Excel de producción).
 */
export function etiquetaDia(fecha: string): string {
  const { y, m, d } = parsearFechaLocal(fecha);
  const fechaObj = new Date(y, m, d, 12, 0, 0);
  const nombreDia = DIAS_SEMANA[fechaObj.getDay()];
  const dd = String(d).padStart(2, '0');
  const mm = String(m + 1).padStart(2, '0');
  const yy = String(y).slice(-2);
  return `${nombreDia} ${dd}/${mm}/${yy}`;
}

/**
 * 3. rangoSemanaTexto(lunes, opciones?) -> 'DEL 19 AL 23 DE OCTUBRE 2026'
 * Si cruza mes: 'DEL 28 DE SEPTIEMBRE AL 2 DE OCTUBRE 2026'
 * Si cruza año: 'DEL 28 DE DICIEMBRE 2026 AL 1 DE ENERO 2027'
 */
export function rangoSemanaTexto(lunes: string, opciones?: { sabado?: boolean }): string {
  const dias = diasDeSemana(lunes, opciones);
  const inicio = parsearFechaLocal(dias[0]);
  const fin = parsearFechaLocal(dias[dias.length - 1]);

  const mesInicio = MESES[inicio.m];
  const mesFin = MESES[fin.m];

  if (inicio.y !== fin.y) {
    return `DEL ${inicio.d} DE ${mesInicio} ${inicio.y} AL ${fin.d} DE ${mesFin} ${fin.y}`;
  }

  if (inicio.m !== fin.m) {
    return `DEL ${inicio.d} DE ${mesInicio} AL ${fin.d} DE ${mesFin} ${inicio.y}`;
  }

  return `DEL ${inicio.d} AL ${fin.d} DE ${mesInicio} ${inicio.y}`;
}

/**
 * 4. agruparPlan(tareas) -> mapa plano por dia (YYYY-MM-DD) -> frenteId -> tareas[]
 */
export function agruparPlan(tareas: PlanTarea[]): Record<string, Record<string, PlanTarea[]>> {
  const mapa: Record<string, Record<string, PlanTarea[]>> = {};

  for (const t of tareas) {
    const dia = t.fecha ? t.fecha.split('T')[0] : '';
    if (!dia) continue;
    if (!mapa[dia]) mapa[dia] = {};
    if (!mapa[dia][t.frente_id]) mapa[dia][t.frente_id] = [];
    mapa[dia][t.frente_id].push(t);
  }

  return mapa;
}

function extraerOperarioId(op: OperarioRef | string): string {
  if (typeof op === 'string') return op;
  return op?.id || '';
}

/**
 * 5. totalesPersonal(tareas) ->
 * - porDia: operarios distintos que laboraron ese día en el área (columna TOT del Excel).
 * - porFrente: asignaciones de operario en la semana (fila TOTAL DE PERSONAL del Excel).
 * - totalAsignaciones: suma de asignaciones de toda la semana.
 * - operariosUnicosSemana: total de personas físicas distintas que laboraron en la semana.
 */
export function totalesPersonal(tareas: PlanTarea[]): TotalesPersonalResult {
  const porDia: Record<string, Set<string>> = {};
  const porFrente: Record<string, number> = {};
  const operariosSemana = new Set<string>();
  let totalAsignaciones = 0;

  for (const t of tareas) {
    if (t.estado === 'cancelada') continue;

    const dia = t.fecha ? t.fecha.split('T')[0] : '';
    if (!dia) continue;

    if (!porDia[dia]) porDia[dia] = new Set<string>();
    if (!porFrente[t.frente_id]) porFrente[t.frente_id] = 0;

    const ops = t.operarios || [];
    for (const op of ops) {
      const opId = extraerOperarioId(op);
      if (!opId) continue;

      porDia[dia].add(opId);
      porFrente[t.frente_id] += 1;
      operariosSemana.add(opId);
      totalAsignaciones += 1;
    }
  }

  const porDiaConteo: Record<string, number> = {};
  for (const [dia, setOps] of Object.entries(porDia)) {
    porDiaConteo[dia] = setOps.size;
  }

  return {
    porDia: porDiaConteo,
    porFrente,
    totalAsignaciones,
    operariosUnicosSemana: operariosSemana.size,
  };
}

/**
 * 6. detectarConflictos(tareas) -> operarios asignados el mismo día a más de una tarea (aviso no bloqueante).
 */
export function detectarConflictos(tareas: PlanTarea[]): ConflictoOperario[] {
  // Mapa (operarioId, fecha) -> tareaIds[]
  const mapa = new Map<string, { operarioId: string; fecha: string; tareaIds: string[] }>();

  for (const t of tareas) {
    if (t.estado === 'cancelada') continue;
    const dia = t.fecha ? t.fecha.split('T')[0] : '';
    if (!dia) continue;

    for (const op of t.operarios || []) {
      const opId = extraerOperarioId(op);
      if (!opId) continue;

      const clave = `${opId}__${dia}`;
      if (!mapa.has(clave)) {
        mapa.set(clave, { operarioId: opId, fecha: dia, tareaIds: [] });
      }
      mapa.get(clave)!.tareaIds.push(t.id);
    }
  }

  const conflictos: ConflictoOperario[] = [];
  for (const val of mapa.values()) {
    if (val.tareaIds.length > 1) {
      conflictos.push(val);
    }
  }

  return conflictos;
}

/**
 * 7. duplicarSemana(tareas, { desde, hasta }) ->
 * Desplaza tareas activas (no canceladas) por el número de días entre desde y hasta (por defecto +7 días).
 * Se restablece el estado a 'planeada' y se limpian inicio_real, fin_real y material_faltante.
 */
export function duplicarSemana(
  tareas: PlanTarea[],
  opciones: { desde: string; hasta: string }
): NuevaTareaPayload[] {
  const fDesde = parsearFechaLocal(opciones.desde);
  const fHasta = parsearFechaLocal(opciones.hasta);

  const dDesde = new Date(fDesde.y, fDesde.m, fDesde.d, 12, 0, 0);
  const dHasta = new Date(fHasta.y, fHasta.m, fHasta.d, 12, 0, 0);
  const diffDias = Math.round((dHasta.getTime() - dDesde.getTime()) / (1000 * 60 * 60 * 24));

  const nuevas: NuevaTareaPayload[] = [];

  for (const t of tareas) {
    if (t.estado === 'cancelada') continue;

    const { y, m, d } = parsearFechaLocal(t.fecha);
    const nuevaFechaObj = new Date(y, m, d + diffDias, 12, 0, 0);
    const nuevaFechaStr = formatearFechaISO(
      nuevaFechaObj.getFullYear(),
      nuevaFechaObj.getMonth(),
      nuevaFechaObj.getDate()
    );

    const operarioIds = (t.operarios || [])
      .map(extraerOperarioId)
      .filter(Boolean);

    const materiales = (t.materiales || []).map((m) => ({
      producto_id: m.producto_id || null,
      descripcion: m.descripcion,
      cantidad: Number(m.cantidad) || 1,
      unidad: m.unidad || 'PZA',
      notas: m.notas || null,
    }));

    nuevas.push({
      fecha: nuevaFechaStr,
      frente_id: t.frente_id,
      orden_trabajo_id: t.orden_trabajo_id || null,
      descripcion: t.descripcion || null,
      movilidad: t.movilidad || null,
      observaciones: t.observaciones || null,
      estado: 'planeada',
      inicio_real: null,
      fin_real: null,
      material_faltante: false,
      operarios: operarioIds,
      materiales,
    });
  }

  return nuevas;
}

/**
 * 8. puedeCambiarEstado(actual, nuevo, opciones?) ->
 * Evalúa transiciones válidas:
 * - planeada -> en_proceso | cancelada
 * - en_proceso -> pausada | terminada | cancelada
 * - pausada -> en_proceso | cancelada
 * - terminada -> en_proceso (requiere confirmación explícita)
 * Determina qué tiempos se deben fijar.
 */
export function puedeCambiarEstado(
  actual: EstadoPlanTarea,
  nuevo: EstadoPlanTarea,
  opciones?: { confirmarReapertura?: boolean }
): {
  valido: boolean;
  motivo?: string;
  fijaTiempos: { fijarInicio: boolean; fijarFin: boolean };
} {
  if (actual === nuevo) {
    return {
      valido: true,
      fijaTiempos: { fijarInicio: false, fijarFin: false },
    };
  }

  // Transición desde terminada a en_proceso requiere confirmación
  if (actual === 'terminada') {
    if (nuevo === 'en_proceso') {
      if (!opciones?.confirmarReapertura) {
        return {
          valido: false,
          motivo: 'Reabrir una tarea terminada requiere confirmación explícita',
          fijaTiempos: { fijarInicio: false, fijarFin: false },
        };
      }
      return {
        valido: true,
        fijaTiempos: { fijarInicio: false, fijarFin: false },
      };
    }
    return {
      valido: false,
      motivo: `No se permite cambiar de 'terminada' a '${nuevo}'`,
      fijaTiempos: { fijarInicio: false, fijarFin: false },
    };
  }

  let valido = false;
  let motivo: string | undefined;

  switch (actual) {
    case 'planeada':
      valido = nuevo === 'en_proceso' || nuevo === 'cancelada';
      if (!valido) motivo = `Una tarea planeada solo puede pasar a 'en_proceso' o 'cancelada'`;
      break;
    case 'en_proceso':
      valido = nuevo === 'pausada' || nuevo === 'terminada' || nuevo === 'cancelada';
      if (!valido) motivo = `Una tarea en proceso solo puede pausarse, terminarse o cancelarse`;
      break;
    case 'pausada':
      valido = nuevo === 'en_proceso' || nuevo === 'cancelada';
      if (!valido) motivo = `Una tarea pausada solo puede reanudarse a 'en_proceso' o cancelarse`;
      break;
    case 'cancelada':
      valido = false;
      motivo = `Una tarea cancelada no puede reactivarse directamente`;
      break;
    default:
      valido = false;
      motivo = `Estado desconocido: ${actual}`;
  }

  const fijarInicio = valido && nuevo === 'en_proceso';
  const fijarFin = valido && nuevo === 'terminada';

  return {
    valido,
    motivo,
    fijaTiempos: { fijarInicio, fijarFin },
  };
}
