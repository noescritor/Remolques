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

/**
 * Devuelve la representación textual limpia para el campo de entrada de volumen en UI.
 * - Mapea claves históricas ("m3_45" -> "45", "m3_30" -> "30", "45m3" -> "45", etc.).
 * - Si viene un objeto con `raw`, devuelve `raw` (para respetar lo que teclea el usuario).
 * - Si viene un objeto con `m3` numérico, devuelve `String(m3)`.
 * - Si es número, devuelve `String(valor)`.
 * - Si es undefined o null o vacío, devuelve `""`.
 */
export function textoCampoVolumen(valor: any): string {
  if (valor === undefined || valor === null || valor === "") {
    return "";
  }
  if (typeof valor === "number") {
    return Number.isFinite(valor) ? String(valor) : "";
  }
  if (typeof valor === "string") {
    const s = valor.trim();
    if (!s) return "";
    if (s === "m3_45" || s === "45m3" || s === "45_m3") return "45";
    if (s === "m3_30" || s === "30m3" || s === "30_m3") return "30";
    return s;
  }
  if (typeof valor === "object") {
    const opcion = valor.opcion || valor.clave;
    // Si viene de cotización histórica con clave de opción
    if (opcion === "m3_45" || opcion === "45m3" || opcion === "45_m3") return "45";
    if (opcion === "m3_30" || opcion === "30m3" || opcion === "30_m3") return "30";

    // Si tiene raw explícito (ej. lo que escribió el usuario mientras tecleaba)
    if (typeof valor.raw === "string") {
      return valor.raw;
    }

    // Si tiene m3 numérico
    if (valor.m3 !== undefined && valor.m3 !== null && valor.m3 !== "") {
      return String(valor.m3);
    }
    if (valor.volumen !== undefined && valor.volumen !== null && valor.volumen !== "") {
      return String(valor.volumen);
    }
    if (valor.cantidad !== undefined && valor.cantidad !== null && valor.cantidad !== "") {
      return String(valor.cantidad);
    }

    if (typeof opcion === "string" && opcion !== "personalizado" && opcion !== "") {
      return opcion;
    }
  }
  return "";
}

/**
 * Convierte el texto tecleado en el configurador al valor que se almacena en `configuracion.grupos.volumen`.
 * - "" o whitespace -> undefined (elimina la clave de grupos para marcar incompleto).
 * - Si el usuario está tecleando un decimal con punto o coma al final (ej. "37.", "37,"):
 *   guarda { opcion: 'personalizado', m3: 37, raw: '37.' } para mantener el número provisional
 *   sin borrar el separador decimal en el texto local.
 * - Si es un número válido (ej. "37.5", "37,5", "38.0", "38 m³"):
 *   extrae el número y conserva raw: { opcion: 'personalizado', m3: 37.5, raw: '37,5' }.
 * - Si es texto no numérico o inválido (ej. "abc", "38abc"):
 *   guarda { opcion: 'personalizado', raw: s } sin propiedad m3.
 */
export function valorDesdeTextoVolumen(texto: string): any {
  if (texto === undefined || texto === null) return undefined;
  const s = String(texto);
  if (s.trim() === "") return undefined;

  // Caso: mientras el usuario teclea y termina en punto o coma decimal (ej. "37.", "37,")
  const matchIncompleto = s.match(/^\s*([-+]?\d+)[.,]\s*$/);
  if (matchIncompleto) {
    const num = parseFloat(matchIncompleto[1]);
    const m3 = Number.isFinite(num) ? num : undefined;
    return m3 !== undefined
      ? { opcion: "personalizado", m3, raw: s }
      : { opcion: "personalizado", raw: s };
  }

  // Validación estricta de número completo (con punto o coma, opcionalmente seguido de m3 o m³)
  const matchCompleto = s.match(/^\s*([-+]?\d+(?:[.,]\d+)?)\s*(?:m3|m³)?\s*$/i);
  if (matchCompleto) {
    const num = parseFloat(matchCompleto[1].replace(",", "."));
    const m3 = Number.isFinite(num) ? num : undefined;
    return m3 !== undefined
      ? { opcion: "personalizado", m3, raw: s }
      : { opcion: "personalizado", raw: s };
  }

  // Texto inválido o no numérico
  return { opcion: "personalizado", raw: s };
}

