export const VOLUMEN_BASE_GONDOLA_M3 = 45;

export type EscalaTipo = "fija" | "por_eje" | "por_largo" | "por_volumen";

export interface ContextoEscala {
  num_ejes?: number | null;
  largo_ft?: number | null;
  volumen_m3?: number | null;
}

/**
 * Resuelve el volumen numérico en m³ a partir de la configuración del equipo.
 * Si no está configurado (cotizaciones antiguas o API sin opción), asume 45 m³.
 */
export function resolverVolumenGondola(
  configuracion?: any,
  opcionesCat?: { clave: string; datos?: any }[]
): number {
  const val = configuracion?.grupos?.volumen;
  if (!val) return VOLUMEN_BASE_GONDOLA_M3;

  if (typeof val === "number" && Number.isFinite(val) && val > 0) {
    return val;
  }

  const clave =
    typeof val === "object" && val !== null
      ? val.opcion || val.clave || val.valor
      : String(val);

  if (typeof clave === "string") {
    if (clave === "m3_30" || clave === "30" || clave === "30m3" || clave === "30_m3") return 30;
    if (clave === "m3_45" || clave === "45" || clave === "45m3" || clave === "45_m3") return 45;
    const match = clave.match(/(\d+)/);
    if (match) {
      const num = parseInt(match[1], 10);
      if (num === 30 || num === 45) return num;
    }
  }

  if (typeof val === "object" && val !== null) {
    if (typeof val.m3 === "number") return val.m3;
    if (val.datos && typeof val.datos.m3 === "number") return val.datos.m3;
  }

  if (opcionesCat && Array.isArray(opcionesCat)) {
    const opt = opcionesCat.find((o) => o.clave === clave);
    if (opt?.datos && typeof opt.datos.m3 === "number") return opt.datos.m3;
  }

  return VOLUMEN_BASE_GONDOLA_M3;
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
