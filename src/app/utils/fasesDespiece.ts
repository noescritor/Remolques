/**
 * Utilidades puras para el manejo de fases de despiece y agrupación del BOM
 * Sub-bloque T2 / T3 (Turno de Noche 2026-11-02)
 */

export interface FaseDespieceItem {
  id: string;
  clave: string;
  nombre: string;
  subtitulo?: string | null;
  orden: number;
  descripcion?: string | null;
  activo?: boolean;
}

export interface EquivalenciaPasoFase {
  paso_legacy: string;
  fase_clave: string;
  fase_id?: string;
}

export interface LineaBOMGenerica {
  id?: string;
  nombre: string;
  unidad?: string | null;
  cantidad: number;
  paso?: string | string[] | null;
  fase_id?: string | null;
  fase_clave?: string | null;
  seccion?: string | null;
  uso?: string | string[] | null;
  costo_unitario?: number | null;
  precio_unitario?: number | null;
  sin_precio?: boolean;
}

export interface GrupoFaseDespiece {
  fase: FaseDespieceItem;
  lineas: LineaBOMGenerica[];
  totalPiezas: number;
  conCosto: number;
  sinCosto: number;
}

export interface ResumenDespiecePorFases {
  grupos: GrupoFaseDespiece[];
  sinFase: LineaBOMGenerica[];
  totalGeneralPiezas: number;
  totalLineas: number;
}

/**
 * Normaliza un string para comparación de claves o pasos
 */
export function normalizarClavePaso(paso?: string | string[] | null): string {
  if (!paso) return "";
  const val = Array.isArray(paso) ? paso[0] || "" : paso;
  return val.trim().toUpperCase().replace(/\s+/g, " ");
}

/**
 * Resuelve la clave de fase para una línea de BOM dada
 */
export function resolverFaseDeLinea(
  linea: LineaBOMGenerica,
  equivalencias: EquivalenciaPasoFase[] = []
): string {
  if (linea.fase_clave) {
    return linea.fase_clave.toLowerCase().trim();
  }

  const pasoNorm = normalizarClavePaso(linea.paso);
  if (!pasoNorm) {
    return "sin_fase";
  }

  // Buscar coincidencia en equivalencias
  for (const eq of equivalencias) {
    if (normalizarClavePaso(eq.paso_legacy) === pasoNorm) {
      return eq.fase_clave.toLowerCase().trim();
    }
  }

  // Fallback por prefijo estándar "PASO X"
  const matchPaso = pasoNorm.match(/^PASO\s*(\d+)$/);
  if (matchPaso) {
    return `paso_${matchPaso[1]}`;
  }

  if (pasoNorm.includes("PINTURA")) return "paso_8";
  if (pasoNorm.includes("AIRE") || pasoNorm.includes("ABS")) return "paso_9";
  if (pasoNorm.includes("LUZ")) return "paso_10";
  if (pasoNorm.includes("PISO")) return "paso_11";
  if (pasoNorm.includes("TERMINADO") || pasoNorm.includes("ACABADO")) return "paso_12";
  if (pasoNorm.includes("EXTRA")) return "extras";
  if (pasoNorm.includes("LLANTA") || pasoNorm.includes("RIN")) return "llantas_rines";

  return "sin_fase";
}

/**
 * Agrupa una lista de líneas BOM en sus fases correspondientes según el catálogo
 */
export function agruparBOMPorFases(
  lineas: LineaBOMGenerica[],
  fases: FaseDespieceItem[],
  equivalencias: EquivalenciaPasoFase[] = []
): ResumenDespiecePorFases {
  const lineasValidas = Array.isArray(lineas) ? lineas.filter(Boolean) : [];
  const fasesOrdenadas = [...fases].sort((a, b) => (a.orden || 0) - (b.orden || 0));

  const mapaGrupos = new Map<string, GrupoFaseDespiece>();
  for (const f of fasesOrdenadas) {
    mapaGrupos.set(f.clave.toLowerCase().trim(), {
      fase: f,
      lineas: [],
      totalPiezas: 0,
      conCosto: 0,
      sinCosto: 0,
    });
  }

  const sinFase: LineaBOMGenerica[] = [];
  let totalGeneralPiezas = 0;

  for (const item of lineasValidas) {
    const cant = Number(item.cantidad) || 0;
    totalGeneralPiezas += cant;

    const faseClave = resolverFaseDeLinea(item, equivalencias);
    const grupo = mapaGrupos.get(faseClave);

    if (grupo) {
      grupo.lineas.push(item);
      grupo.totalPiezas += cant;
      if (item.sin_precio || !item.costo_unitario || item.costo_unitario <= 0) {
        grupo.sinCosto++;
      } else {
        grupo.conCosto++;
      }
    } else {
      sinFase.push(item);
    }
  }

  return {
    grupos: fasesOrdenadas.map((f) => mapaGrupos.get(f.clave.toLowerCase().trim())!),
    sinFase,
    totalGeneralPiezas,
    totalLineas: lineasValidas.length,
  };
}
