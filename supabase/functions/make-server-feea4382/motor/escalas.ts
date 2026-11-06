export const VOLUMEN_BASE_GONDOLA_M3 = 45;
export const VOLUMEN_MIN_GONDOLA_M3 = 20;
export const VOLUMEN_MAX_GONDOLA_M3 = 60;

export type EscalaTipo = "fija" | "por_eje" | "por_largo" | "por_volumen";

export interface ContextoEscala {
  num_ejes?: number | null;
  largo_ft?: number | null;
  volumen_m3?: number | null;
}

/**
 * Conjunto de grupos de configuración que actúan como conductores de escala dimensional
 * y no como opciones con componentes directos o precio de venta unitario propio.
 */
export const GRUPOS_CONDUCTOR = new Set<string>(["volumen"]);

export function esGrupoConductor(grupoClave?: string | null): boolean {
  if (!grupoClave) return false;
  return GRUPOS_CONDUCTOR.has(grupoClave.trim().toLowerCase());
}

export interface DetalleVolumenGondola {
  volumen: number;
  esReconocido: boolean;
  advertencia?: string;
}

/**
 * Formatea un volumen numérico en m³ de forma homogénea:
 * Si es entero se muestra sin decimales (p. ej. 38, 45, 30).
 * Si tiene decimales, se redondea y muestra con un solo decimal (p. ej. 37.5).
 */
export function formatearVolumenM3(vol: number): string {
  if (!Number.isFinite(vol)) return String(VOLUMEN_BASE_GONDOLA_M3);
  if (Number.isInteger(vol)) {
    return String(vol);
  }
  const unDecimal = Number(vol.toFixed(1));
  return Number.isInteger(unDecimal) ? String(unDecimal) : unDecimal.toFixed(1);
}

export interface CandidatoVolumen {
  numero: number | null;
  representacion: string;
  textoOriginal: string;
}

/**
 * Extrae el valor numérico candidato de cualquier representación de volumen
 * enviada por el configurador o guardada en cotizaciones históricas.
 * Validación estricta: todo el texto debe ser un número (con punto o coma)
 * opcionalmente seguido de m3 o m³. Elimina la rama matchSub y rechaza "38abc", "abc38", "1e2".
 */
export function extraerCandidatoVolumen(val: any): CandidatoVolumen {
  if (val === undefined || val === null) {
    return { numero: null, representacion: "", textoOriginal: "" };
  }

  if (typeof val === "number") {
    const n = Number.isFinite(val) ? val : null;
    const str = String(val);
    return { numero: n, representacion: str, textoOriginal: str };
  }

  if (typeof val === "string") {
    const s = val.trim();
    if (!s) return { numero: null, representacion: "", textoOriginal: "" };

    // Claves específicas históricas
    if (s === "m3_30" || s === "30m3" || s === "30_m3") {
      return { numero: 30, representacion: s, textoOriginal: s };
    }
    if (s === "m3_45" || s === "45m3" || s === "45_m3") {
      return { numero: 45, representacion: s, textoOriginal: s };
    }

    // Validación estricta: todo el texto debe ser un número opcionalmente seguido de m3 o m³
    const match = s.match(/^\s*([-+]?\d+(?:[.,]\d+)?)\s*(?:m3|m³)?\s*$/i);
    if (match) {
      const num = parseFloat(match[1].replace(",", "."));
      const n = Number.isFinite(num) ? num : null;
      return { numero: n, representacion: s, textoOriginal: s };
    }

    return { numero: null, representacion: s, textoOriginal: s };
  }

  if (typeof val === "object") {
    const rawStr = typeof val.raw === "string" ? val.raw : undefined;
    const repr = rawStr ?? JSON.stringify(val);

    // Caso clave histórica en objeto: { opcion: 'm3_30' } o { clave: 'm3_45' }
    const clave = val.opcion || val.clave;
    if (clave === "m3_30" || clave === "30m3" || clave === "30_m3") {
      return { numero: 30, representacion: rawStr ?? "m3_30", textoOriginal: rawStr ?? "m3_30" };
    }
    if (clave === "m3_45" || clave === "45m3" || clave === "45_m3") {
      return { numero: 45, representacion: rawStr ?? "m3_45", textoOriginal: rawStr ?? "m3_45" };
    }

    // Caso { m3: 38 }
    if (val.m3 !== undefined && val.m3 !== null && val.m3 !== "") {
      const sub = extraerCandidatoVolumen(val.m3);
      const str = rawStr ?? sub.representacion;
      return { numero: sub.numero, representacion: str, textoOriginal: str };
    }

    // Si viene con raw pero sin m3 (ej: { opcion: 'personalizado', raw: 'abc' })
    if (rawStr !== undefined) {
      const sub = extraerCandidatoVolumen(rawStr);
      return { numero: sub.numero, representacion: rawStr, textoOriginal: rawStr };
    }

    // Caso { valor: 38 }
    if (val.valor !== undefined && val.valor !== null && val.valor !== "") {
      const sub = extraerCandidatoVolumen(val.valor);
      const str = rawStr ?? sub.representacion;
      return { numero: sub.numero, representacion: str, textoOriginal: str };
    }

    // Caso { texto: "38" }
    if (val.texto !== undefined && val.texto !== null && val.texto !== "") {
      const sub = extraerCandidatoVolumen(val.texto);
      const str = rawStr ?? sub.representacion;
      return { numero: sub.numero, representacion: str, textoOriginal: str };
    }

    // Caso { cantidad: 38 }
    if (val.cantidad !== undefined && val.cantidad !== null && val.cantidad !== "") {
      const sub = extraerCandidatoVolumen(val.cantidad);
      const str = rawStr ?? sub.representacion;
      return { numero: sub.numero, representacion: str, textoOriginal: str };
    }

    // Caso { datos: { m3: 38 } }
    if (val.datos && typeof val.datos === "object" && val.datos.m3 !== undefined) {
      const sub = extraerCandidatoVolumen(val.datos.m3);
      const str = rawStr ?? sub.representacion;
      return { numero: sub.numero, representacion: str, textoOriginal: str };
    }

    if (typeof clave === "string" && clave !== "personalizado") {
      const sub = extraerCandidatoVolumen(clave);
      if (sub.numero !== null) {
        return { numero: sub.numero, representacion: repr, textoOriginal: repr };
      }
    }

    return { numero: null, representacion: rawStr ?? "", textoOriginal: rawStr ?? "" };
  }

  const s = String(val);
  return { numero: null, representacion: s, textoOriginal: s };
}

/**
 * Resuelve el volumen numérico en m³ a partir de la configuración del equipo de forma detallada.
 * Si no está configurado (cotizaciones antiguas o API sin opción), asume 45 m³ como reconocido sin advertencia.
 * Si se especifica un volumen fuera del rango [20, 60] m³ o no numérico/<=0, reporta advertencia y asume 45 m³.
 * Para cualquier volumen numérico válido dentro de rango, lo redondea una sola vez a 1 decimal y lo retorna.
 */
export function resolverVolumenGondolaDetallado(
  configuracion?: any,
  opcionesCat?: { clave: string; datos?: any }[]
): DetalleVolumenGondola {
  const val = configuracion?.grupos?.volumen;
  if (val === undefined || val === null || val === "") {
    return {
      volumen: VOLUMEN_BASE_GONDOLA_M3,
      esReconocido: true
    };
  }

  const { numero: numBruto, representacion } = extraerCandidatoVolumen(val);

  if (numBruto === null || !Number.isFinite(numBruto) || numBruto <= 0) {
    return {
      volumen: VOLUMEN_BASE_GONDOLA_M3,
      esReconocido: false,
      advertencia: `Volumen '${representacion}' no válido para góndola; se asume ${VOLUMEN_BASE_GONDOLA_M3} m³ (provisional)`
    };
  }

  // Redondeo único a 1 decimal antes de validar el rango y de devolverlo
  const numero = Math.round(numBruto * 10) / 10;

  if (numero < VOLUMEN_MIN_GONDOLA_M3 || numero > VOLUMEN_MAX_GONDOLA_M3) {
    return {
      volumen: VOLUMEN_BASE_GONDOLA_M3,
      esReconocido: false,
      advertencia: `Volumen '${numero}' fuera de rango (${VOLUMEN_MIN_GONDOLA_M3}-${VOLUMEN_MAX_GONDOLA_M3} m³); se asume ${VOLUMEN_BASE_GONDOLA_M3} m³ (provisional)`
    };
  }

  return {
    volumen: numero,
    esReconocido: true
  };
}

/**
 * Resuelve el volumen numérico en m³ a partir de la configuración del equipo.
 * Si no está configurado (cotizaciones antiguas o API sin opción), asume 45 m³.
 */
export function resolverVolumenGondola(
  configuracion?: any,
  opcionesCat?: { clave: string; datos?: any }[]
): number {
  return resolverVolumenGondolaDetallado(configuracion, opcionesCat).volumen;
}

/**
 * Función única y compartida de cálculo de cantidad efectiva según escala.
 * Utilizada por costeo.ts, resolver_receta.ts y catalogo_costos.ts.
 */
export function calcularCantidadEscalada(
  cantidadBase: number,
  escala: string,
  contexto?: ContextoEscala | null
): number {
  if (escala === "por_eje") {
    const ejes = Number(contexto?.num_ejes) || 1;
    return cantidadBase * ejes;
  }
  if (escala === "por_largo") {
    const largo = Number(contexto?.largo_ft) || 40;
    return cantidadBase * (largo / 40.0);
  }
  if (escala === "por_volumen") {
    const vol =
      contexto?.volumen_m3 != null
        ? Number(contexto.volumen_m3)
        : VOLUMEN_BASE_GONDOLA_M3;
    return cantidadBase * (vol / Number(VOLUMEN_BASE_GONDOLA_M3));
  }
  return cantidadBase; // fija
}
