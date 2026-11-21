export type FormatoCalidad = 'control_total' | 'entrega';
export type EstadoPlantillaCalidad = 'borrador' | 'activa' | 'archivada';
export type ResultadoValor = 'conforme' | 'no_conforme' | 'no_aplica';

export interface ConfigPlantillaCalidad {
  unidades: string[];
  etiquetas_resultado: {
    conforme: string;
    no_conforme: string;
  };
  bloquea_liberacion: boolean;
}

export interface PlantillaItemCalidad {
  id?: string;
  orden: number;
  numero: number;
  texto: string;
  aplica_si?: string | null;
}

export interface PlantillaGrupoCalidad {
  id?: string;
  orden: number;
  nombre: string;
  numero_original?: string | null;
  fase_orden?: number | null;
  fase_confirmada?: boolean;
  items: PlantillaItemCalidad[];
}

export interface PlantillaCalidad {
  id: string;
  organizacion_id: string;
  linea_producto_id: string;
  linea?: { id: string; clave: string; nombre: string } | null;
  formato: FormatoCalidad;
  nombre: string;
  version: number;
  estado: EstadoPlantillaCalidad;
  revision_formato?: string | null;
  fecha_revision_formato?: string | null;
  config: ConfigPlantillaCalidad;
  origen: 'semilla' | 'editor';
  grupos?: PlantillaGrupoCalidad[];
  created_at?: string;
  updated_at?: string;
}

export interface ResultadoInspeccionCalidad {
  id?: string;
  inspeccion_id?: string;
  item_id: string;
  unidad: number;
  resultado: ResultadoValor | null;
  operario_id?: string | null;
  colaborador?: string | null;
  fecha_inspeccion?: string | null;
  observaciones?: string | null;
}

export interface ResumenInspeccionCalidad {
  total: number;
  capturados: number;
  conformes: number;
  no_conformes: number;
  no_aplica: number;
  pendientes: number;
}

export function normalizarConfigPlantilla(raw: any): ConfigPlantillaCalidad {
  const unidades = Array.isArray(raw?.unidades) && raw.unidades.length > 0
    ? raw.unidades.map((u: any) => String(u || '').trim()).filter(Boolean)
    : ['Única'];
  return {
    unidades: unidades.length > 0 ? unidades : ['Única'],
    etiquetas_resultado: {
      conforme: String(raw?.etiquetas_resultado?.conforme || '√'),
      no_conforme: String(raw?.etiquetas_resultado?.no_conforme || 'X'),
    },
    bloquea_liberacion: Boolean(raw?.bloquea_liberacion),
  };
}

export function claveResultado(itemId: string, unidad: number): string {
  return `${itemId}:${unidad}`;
}

export function agruparResultadosPorClave(
  resultados: ResultadoInspeccionCalidad[]
): Map<string, ResultadoInspeccionCalidad> {
  const mapa = new Map<string, ResultadoInspeccionCalidad>();
  for (const r of resultados || []) {
    if (!r?.item_id) continue;
    const u = Number(r.unidad) || 1;
    mapa.set(claveResultado(r.item_id, u), { ...r, unidad: u });
  }
  return mapa;
}

export function contarResumenPorPlantilla(
  grupos: PlantillaGrupoCalidad[],
  configRaw: any,
  resultados: ResultadoInspeccionCalidad[] | Map<string, ResultadoInspeccionCalidad>
): ResumenInspeccionCalidad {
  const config = normalizarConfigPlantilla(configRaw);
  const numUnidades = config.unidades.length;
  const mapa = resultados instanceof Map ? resultados : agruparResultadosPorClave(resultados);

  let numItems = 0;
  let conformes = 0;
  let no_conformes = 0;
  let no_aplica = 0;

  for (const g of grupos || []) {
    for (const it of g.items || []) {
      numItems++;
      if (!it.id) continue;
      for (let u = 1; u <= numUnidades; u++) {
        const res = mapa.get(claveResultado(it.id, u));
        if (!res || !res.resultado) continue;
        if (res.resultado === 'conforme') conformes++;
        else if (res.resultado === 'no_conforme') no_conformes++;
        else if (res.resultado === 'no_aplica') no_aplica++;
      }
    }
  }

  const total = numItems * numUnidades;
  const capturados = conformes + no_conformes + no_aplica;
  const pendientes = Math.max(0, total - capturados);

  return { total, capturados, conformes, no_conformes, no_aplica, pendientes };
}

export function contarResumenGrupo(
  grupo: PlantillaGrupoCalidad,
  numUnidades: number,
  mapa: Map<string, ResultadoInspeccionCalidad>
): ResumenInspeccionCalidad {
  return contarResumenPorPlantilla(
    [grupo],
    { unidades: Array.from({ length: Math.max(1, numUnidades) }, (_, i) => `U${i + 1}`) },
    mapa
  );
}

export function obtenerSiguienteNoConforme(
  grupos: PlantillaGrupoCalidad[],
  numUnidades: number,
  mapa: Map<string, ResultadoInspeccionCalidad>,
  actual?: { item_id: string; unidad: number } | null
): { item_id: string; unidad: number; numero: number } | null {
  const lista: Array<{ item_id: string; unidad: number; numero: number }> = [];
  const uMax = Math.max(1, numUnidades);

  for (const g of grupos || []) {
    for (const it of g.items || []) {
      if (!it.id) continue;
      for (let u = 1; u <= uMax; u++) {
        const res = mapa.get(claveResultado(it.id, u));
        if (res?.resultado === 'no_conforme') {
          lista.push({ item_id: it.id, unidad: u, numero: it.numero });
        }
      }
    }
  }

  if (lista.length === 0) return null;
  if (!actual) return lista[0];

  const idxActual = lista.findIndex(
    (x) => x.item_id === actual.item_id && x.unidad === actual.unidad
  );
  if (idxActual === -1) return lista[0];
  return lista[(idxActual + 1) % lista.length];
}

export function etiquetaResultado(
  resultado: ResultadoValor | null | undefined,
  configRaw: any
): string {
  if (!resultado) return '';
  const config = normalizarConfigPlantilla(configRaw);
  if (resultado === 'conforme') return config.etiquetas_resultado.conforme;
  if (resultado === 'no_conforme') return config.etiquetas_resultado.no_conforme;
  if (resultado === 'no_aplica') return 'N/A';
  return '';
}

export function armarLoteResultados(
  cambios: ResultadoInspeccionCalidad[]
): Array<Record<string, unknown>> {
  const dedup = new Map<string, ResultadoInspeccionCalidad>();
  for (const c of cambios) {
    if (!c.item_id) continue;
    const u = Number(c.unidad) || 1;
    dedup.set(claveResultado(c.item_id, u), { ...c, unidad: u });
  }

  return Array.from(dedup.values()).map((r) => ({
    item_id: r.item_id,
    unidad: r.unidad,
    resultado: r.resultado ?? null,
    operario_id: r.operario_id || null,
    colaborador: r.colaborador ? r.colaborador.trim() : null,
    fecha_inspeccion: r.fecha_inspeccion || null,
    observaciones: r.observaciones ? r.observaciones.trim() : null,
  }));
}

export function parsearLineasActividades(
  texto: string,
  numeroInicial = 1
): PlantillaItemCalidad[] {
  const lineas = String(texto || '')
    .split(/\r?\n/)
    .map((l) => l.trim())
    .filter(Boolean);

  return lineas.map((linea, idx) => ({
    orden: idx + 1,
    numero: numeroInicial + idx,
    texto: linea,
    aplica_si: null,
  }));
}

export function resolverPlantillaSugerida(
  orden: { tipo_equipo?: string | null; modelo?: string | null; etiqueta?: string | null; linea_producto_id?: string | null } | null | undefined,
  plantillasActivas: PlantillaCalidad[],
  formato: FormatoCalidad
): PlantillaCalidad | null {
  const candidatas = (plantillasActivas || []).filter(
    (p) => p.estado === 'activa' && p.formato === formato
  );
  if (candidatas.length === 0 || !orden) return null;

  const esCamaBaja =
    String(orden.tipo_equipo || '').trim() === '05' ||
    /cama\s*baja/i.test(`${orden.modelo || ''} ${orden.etiqueta || ''}`);

  if (esCamaBaja) {
    const cb = candidatas.find((p) => p.linea?.clave === 'cama_baja');
    if (cb) return cb;
  }

  if (orden.linea_producto_id) {
    const porLinea = candidatas.find((p) => p.linea_producto_id === orden.linea_producto_id);
    if (porLinea) return porLinea;
  }

  return null;
}

export function traducirErrorCalidad(codigo?: string | null, mensajeFallback?: string | null): string {
  switch (codigo) {
    case 'UNIDAD_INVALIDA':
      return mensajeFallback || 'La unidad seleccionada está fuera del rango de la plantilla.';
    case 'NO_EDITABLE':
      return 'Solo se pueden editar o eliminar plantillas en estado borrador.';
    case 'TIENE_INSPECCIONES':
      return 'No se puede eliminar esta plantilla porque ya tiene inspecciones registradas.';
    case 'SIN_PLANTILLA':
      return 'No hay plantilla activa para esta línea y formato. Créala en Calidad → Plantillas.';
    case 'YA_EXISTE':
      return 'Ya existe una inspección en proceso para este equipo y formato.';
    case 'INSPECCION_CERRADA':
      return 'La inspección ya está cerrada. Reábrela si necesitas hacer cambios.';
    case 'PLANTILLA_VACIA':
      return 'La plantilla debe tener al menos un grupo y una actividad antes de publicarse.';
    case 'BLOQUEADA_POR_NO_CONFORMES':
      return 'No se puede liberar porque la plantilla tiene activado el bloqueo por no conformes.';
    default:
      return mensajeFallback || 'Ocurrió un error al procesar la solicitud de calidad.';
  }
}
