import { obtenerConfiguracion } from "./configuracionEquipo.ts";
import { resolverVolumenGondola } from "../../../supabase/functions/make-server-feea4382/motor/escalas.ts";

/**
 * Resuelve el nombre a mostrar para un ítem de cotización en PDFs y vistas previas.
 * Si el producto es góndola, asegura que el volumen (30 M3 o 45 M3) aparezca en el título,
 * leyendo la configuración guardada o asumiendo 45 M3 por defecto para cotizaciones históricas.
 */
export function nombreItemCotizacion(
  producto?: { nombre?: string | null; tipo?: string | null } | null,
  item?: any
): string {
  const nombreBase = producto?.nombre || item?.descripcion || "Producto no encontrado";

  const cfg = obtenerConfiguracion(item);
  const esGondolaPorNombre = /gondola/i.test(nombreBase);
  const esGondolaPorTipo = (producto?.tipo || item?.modelo?.tipo || "").toLowerCase() === "gondola";
  const esGondolaPorCfg = Boolean(cfg?.grupos?.volumen || cfg?.grupos?.tina_material);

  if (esGondolaPorNombre || esGondolaPorTipo || esGondolaPorCfg) {
    // Si el nombre ya trae el sufijo de volumen (ej. histórico no renombrado), no duplicar
    if (/\b\d+\s*m3\b/i.test(nombreBase)) {
      return nombreBase;
    }

    const vol = resolverVolumenGondola(cfg);
    return `${nombreBase} ${vol} M3`;
  }

  return nombreBase;
}
