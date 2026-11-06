import {
  VOLUMEN_MIN_GONDOLA_M3,
  VOLUMEN_MAX_GONDOLA_M3,
  formatearVolumenM3,
  resolverVolumenGondola,
  esGrupoConductor,
} from "../../../supabase/functions/make-server-feea4382/motor/escalas.ts";

export { esGrupoConductor, resolverVolumenGondola, formatearVolumenM3 };

export interface ResultadoEstadoVolumen {
  estado: "incompleto" | "completo";
  completo: boolean;
  volumen: number | null;
  error?: string;
  mensaje?: string;
  texto?: string;
}

/**
 * Extrae el valor numérico candidato de cualquier representación de volumen
 * enviada por el configurador o guardada en cotizaciones históricas.
 */
export function extraerCandidatoVolumen(val: any): { numero: number | null; textoOriginal: string } {
  if (val === undefined || val === null) {
    return { numero: null, textoOriginal: "" };
  }

  if (typeof val === "number") {
    return {
      numero: Number.isFinite(val) ? val : null,
      textoOriginal: String(val),
    };
  }

  if (typeof val === "string") {
    const s = val.trim();
    if (!s) return { numero: null, textoOriginal: "" };

    // Claves históricas
    if (s === "m3_30" || s === "30m3" || s === "30_m3") return { numero: 30, textoOriginal: s };
    if (s === "m3_45" || s === "45m3" || s === "45_m3") return { numero: 45, textoOriginal: s };

    const normalizado = s.replace(",", ".");
    const match = normalizado.match(/^[-+]?\d+(?:\.\d+)?/);
    if (match) {
      const num = parseFloat(match[0]);
      return { numero: Number.isFinite(num) ? num : null, textoOriginal: s };
    }

    return { numero: null, textoOriginal: s };
  }

  if (typeof val === "object") {
    // Si viene como { opcion: 'personalizado', m3: 38 } o { m3: 38 }
    if (val.m3 !== undefined && val.m3 !== null && val.m3 !== "") {
      return extraerCandidatoVolumen(val.m3);
    }
    if (val.valor !== undefined && val.valor !== null && val.valor !== "") {
      return extraerCandidatoVolumen(val.valor);
    }
    if (val.texto !== undefined && val.texto !== null && val.texto !== "") {
      return extraerCandidatoVolumen(val.texto);
    }
    if (val.cantidad !== undefined && val.cantidad !== null && val.cantidad !== "") {
      return extraerCandidatoVolumen(val.cantidad);
    }
    if (val.datos?.m3 !== undefined) {
      return extraerCandidatoVolumen(val.datos.m3);
    }

    const clave = val.opcion || val.clave;
    if (clave === "m3_30") return { numero: 30, textoOriginal: "m3_30" };
    if (clave === "m3_45") return { numero: 45, textoOriginal: "m3_45" };
    if (typeof clave === "string" && clave !== "personalizado") {
      return extraerCandidatoVolumen(clave);
    }

    return { numero: null, textoOriginal: "" };
  }

  return { numero: null, textoOriginal: String(val) };
}

/**
 * Función pura que evalúa el estado de captura del volumen de una góndola.
 * - sin valor -> incompleto
 * - valor numérico válido en rango [min, max] -> completo
 * - fuera de rango (< min o > max) o <= 0 o no numérico -> incompleto con mensaje de error
 */
export function evaluarEstadoVolumen(
  val: any,
  min: number = VOLUMEN_MIN_GONDOLA_M3,
  max: number = VOLUMEN_MAX_GONDOLA_M3
): ResultadoEstadoVolumen {
  const { numero, textoOriginal } = extraerCandidatoVolumen(val);

  if (numero === null && !textoOriginal) {
    return {
      estado: "incompleto",
      completo: false,
      volumen: null,
      mensaje: `Ingresa el volumen en m³ (${min} - ${max} m³)`,
    };
  }

  if (numero === null || !Number.isFinite(numero) || numero <= 0) {
    return {
      estado: "incompleto",
      completo: false,
      volumen: null,
      error: `El volumen '${textoOriginal}' no es válido (debe ser mayor a 0)`,
      mensaje: `El volumen '${textoOriginal}' no es válido (debe ser mayor a 0)`,
    };
  }

  if (numero < min || numero > max) {
    return {
      estado: "incompleto",
      completo: false,
      volumen: null,
      error: `El volumen (${numero} m³) debe estar entre ${min} y ${max} m³`,
      mensaje: `El volumen (${numero} m³) debe estar entre ${min} y ${max} m³`,
    };
  }

  return {
    estado: "completo",
    completo: true,
    volumen: numero,
    texto: formatearVolumenM3(numero),
  };
}

export function esVolumenCompleto(
  val: any,
  min: number = VOLUMEN_MIN_GONDOLA_M3,
  max: number = VOLUMEN_MAX_GONDOLA_M3
): boolean {
  return evaluarEstadoVolumen(val, min, max).completo;
}
