import {
  VOLUMEN_MIN_GONDOLA_M3,
  VOLUMEN_MAX_GONDOLA_M3,
  formatearVolumenM3,
  resolverVolumenGondola,
  esGrupoConductor,
  extraerCandidatoVolumen,
} from "../../../supabase/functions/make-server-feea4382/motor/escalas.ts";

export { esGrupoConductor, resolverVolumenGondola, formatearVolumenM3, extraerCandidatoVolumen };

export interface ResultadoEstadoVolumen {
  estado: "incompleto" | "completo";
  completo: boolean;
  volumen: number | null;
  error?: string;
  mensaje?: string;
  texto?: string;
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
  const { numero: numBruto, textoOriginal } = extraerCandidatoVolumen(val);

  if (numBruto === null && !textoOriginal) {
    return {
      estado: "incompleto",
      completo: false,
      volumen: null,
      mensaje: `Ingresa el volumen en m³ (${min} - ${max} m³)`,
    };
  }

  if (numBruto === null || !Number.isFinite(numBruto) || numBruto <= 0) {
    return {
      estado: "incompleto",
      completo: false,
      volumen: null,
      error: `El volumen '${textoOriginal}' no es válido (debe ser mayor a 0)`,
      mensaje: `El volumen '${textoOriginal}' no es válido (debe ser mayor a 0)`,
    };
  }

  const numero = Math.round(numBruto * 10) / 10;

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
