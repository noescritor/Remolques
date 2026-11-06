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

function extraerNumeroVolumen(val: any): { numero: number | null; representacion: string } {
  if (val === undefined || val === null) {
    return { numero: null, representacion: "" };
  }

  if (typeof val === "number") {
    return {
      numero: Number.isFinite(val) ? val : null,
      representacion: String(val)
    };
  }

  if (typeof val === "string") {
    const s = val.trim();
    if (!s) return { numero: null, representacion: "" };

    // Claves específicas históricas
    if (s === "m3_30" || s === "30m3" || s === "30_m3") return { numero: 30, representacion: s };
    if (s === "m3_45" || s === "45m3" || s === "45_m3") return { numero: 45, representacion: s };

    // Intentar número directo (ej: "38", "37.5", "37,5", "38 m3", "38 m³")
    const normalizado = s.replace(",", ".");
    const match = normalizado.match(/^[-+]?\d+(?:\.\d+)?/);
    if (match) {
      const num = parseFloat(match[0]);
      return { numero: Number.isFinite(num) ? num : null, representacion: s };
    }

    // Si viene con prefijo como "volumen_38"
    const matchSub = normalizado.match(/[-+]?\d+(?:\.\d+)?/);
    if (matchSub) {
      const num = parseFloat(matchSub[0]);
      return { numero: Number.isFinite(num) ? num : null, representacion: s };
    }

    return { numero: null, representacion: s };
  }

  if (typeof val === "object") {
    const repr = JSON.stringify(val);

    // Caso { clave: 'm3_30' } o { opcion: 'm3_30' }
    const clave = val.opcion || val.clave;
    if (clave === "m3_30" || clave === "30") return { numero: 30, representacion: repr };
    if (clave === "m3_45" || clave === "45") return { numero: 45, representacion: repr };

    // Caso { m3: 38 }
    if (val.m3 !== undefined && val.m3 !== null) {
      const sub = extraerNumeroVolumen(val.m3);
      return { numero: sub.numero, representacion: repr };
    }

    // Caso { valor: 38 }
    if (val.valor !== undefined && val.valor !== null) {
      const sub = extraerNumeroVolumen(val.valor);
      return { numero: sub.numero, representacion: repr };
    }

    // Caso { texto: "38" }
    if (val.texto !== undefined && val.texto !== null) {
      const sub = extraerNumeroVolumen(val.texto);
      return { numero: sub.numero, representacion: repr };
    }

    // Caso { cantidad: 38 }
    if (val.cantidad !== undefined && val.cantidad !== null) {
      const sub = extraerNumeroVolumen(val.cantidad);
      return { numero: sub.numero, representacion: repr };
    }

    // Caso { datos: { m3: 38 } }
    if (val.datos && typeof val.datos === "object" && val.datos.m3 !== undefined) {
      const sub = extraerNumeroVolumen(val.datos.m3);
      return { numero: sub.numero, representacion: repr };
    }

    if (typeof clave === "string") {
      const sub = extraerNumeroVolumen(clave);
      if (sub.numero !== null) return { numero: sub.numero, representacion: repr };
    }

    return { numero: null, representacion: repr };
  }

  return { numero: null, representacion: String(val) };
}

/**
 * Resuelve el volumen numérico en m³ a partir de la configuración del equipo de forma detallada.
 * Si no está configurado (cotizaciones antiguas o API sin opción), asume 45 m³ como reconocido sin advertencia.
 * Si se especifica un volumen fuera del rango [20, 60] m³ o no numérico/<=0, reporta advertencia y asume 45 m³.
 * Para cualquier volumen numérico válido dentro de rango, lo retorna como reconocido.
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

  const { numero, representacion } = extraerNumeroVolumen(val);

  if (numero === null || !Number.isFinite(numero) || numero <= 0) {
    return {
      volumen: VOLUMEN_BASE_GONDOLA_M3,
      esReconocido: false,
      advertencia: `Volumen '${representacion}' no válido para góndola; se asume ${VOLUMEN_BASE_GONDOLA_M3} m³ (provisional)`
    };
  }

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
