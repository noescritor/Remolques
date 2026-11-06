export const VOLUMEN_BASE_GONDOLA_M3 = 45;

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

export function esGrupoConductor(grupoClave: string): boolean {
  return GRUPOS_CONDUCTOR.has(grupoClave);
}

export interface DetalleVolumenGondola {
  volumen: number;
  esReconocido: boolean;
  advertencia?: string;
}

/**
 * Resuelve el volumen numérico en m³ a partir de la configuración del equipo de forma detallada.
 * Si no está configurado (cotizaciones antiguas o API sin opción), asume 45 m³ como reconocido.
 * Si se especifica un volumen no reconocido, reporta advertencia y asume 45 m³.
 */
export function resolverVolumenGondolaDetallado(
  configuracion?: any,
  opcionesCat?: { clave: string; datos?: any }[]
): DetalleVolumenGondola {
  const val = configuracion?.grupos?.volumen;
  if (!val) {
    return {
      volumen: VOLUMEN_BASE_GONDOLA_M3,
      esReconocido: true
    };
  }

  if (typeof val === "number" && Number.isFinite(val) && val > 0) {
    if (val === 30 || val === 45) {
      return { volumen: val, esReconocido: true };
    }
    return {
      volumen: VOLUMEN_BASE_GONDOLA_M3,
      esReconocido: false,
      advertencia: `Volumen '${val}' no reconocido para góndola; se asume 45 m³ (provisional)`
    };
  }

  const clave =
    typeof val === "object" && val !== null
      ? val.opcion || val.clave || val.valor
      : String(val);

  if (typeof clave === "string") {
    if (clave === "m3_30" || clave === "30" || clave === "30m3" || clave === "30_m3") {
      return { volumen: 30, esReconocido: true };
    }
    if (clave === "m3_45" || clave === "45" || clave === "45m3" || clave === "45_m3") {
      return { volumen: 45, esReconocido: true };
    }
    const match = clave.match(/(\d+)/);
    if (match) {
      const num = parseInt(match[1], 10);
      if (num === 30 || num === 45) return { volumen: num, esReconocido: true };
    }
  }

  if (typeof val === "object" && val !== null) {
    const m3Val = typeof val.m3 === "number" ? val.m3 : (val.datos && typeof val.datos.m3 === "number" ? val.datos.m3 : null);
    if (m3Val !== null) {
      if (m3Val === 30 || m3Val === 45) return { volumen: m3Val, esReconocido: true };
      return {
        volumen: VOLUMEN_BASE_GONDOLA_M3,
        esReconocido: false,
        advertencia: `Volumen '${m3Val}' no reconocido para góndola; se asume 45 m³ (provisional)`
      };
    }
  }

  if (opcionesCat && Array.isArray(opcionesCat) && typeof clave === "string") {
    const opt = opcionesCat.find((o) => o.clave === clave);
    if (opt?.datos && typeof opt.datos.m3 === "number") {
      const m3Opt = opt.datos.m3;
      if (m3Opt === 30 || m3Opt === 45) return { volumen: m3Opt, esReconocido: true };
      return {
        volumen: VOLUMEN_BASE_GONDOLA_M3,
        esReconocido: false,
        advertencia: `Volumen '${m3Opt}' no reconocido para góndola; se asume 45 m³ (provisional)`
      };
    }
  }

  const representacion = typeof val === "object" ? JSON.stringify(val) : String(val);
  return {
    volumen: VOLUMEN_BASE_GONDOLA_M3,
    esReconocido: false,
    advertencia: `Volumen '${representacion}' no reconocido para góndola; se asume 45 m³ (provisional)`
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
