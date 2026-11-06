import { obtenerConfiguracion } from "./configuracionEquipo.ts";
import {
  resolverVolumenGondola,
  formatearVolumenM3
} from "../../../supabase/functions/make-server-feea4382/motor/escalas.ts";

/**
 * Resuelve el nombre a mostrar para un ítem de cotización en PDFs y vistas previas.
 * Si el producto es góndola, asegura que el volumen aparezca en el título,
 * leyendo la configuración guardada o asumiendo 45 M3 por defecto para cotizaciones históricas.
 */
export function nombreItemCotizacion(
  producto?: { nombre?: string | null; tipo?: string | null } | null,
  item?: any
): string {
  const nombreBase = (producto?.nombre || item?.descripcion || "Producto no encontrado").trim();

  const cfg = obtenerConfiguracion(item);
  const esGondolaPorNombre = /gondola/i.test(nombreBase) || /gondola/i.test(item?.descripcion || "");
  const esGondolaPorTipo = (producto?.tipo || item?.modelo?.tipo || "").toLowerCase() === "gondola";
  const esGondolaPorCfg = Boolean(cfg?.grupos?.volumen || cfg?.grupos?.tina_material);

  if (esGondolaPorNombre || esGondolaPorTipo || esGondolaPorCfg) {
    const tieneVolumenEnTexto = /\b\d+(?:[.,]\d+)?\s*m(?:3|³)\b/i.test(nombreBase);
    const tieneVolumenEnDescripcion = /\b\d+(?:[.,]\d+)?\s*m(?:3|³)\b/i.test(item?.descripcion || "");
    const volConfigurado = cfg?.grupos?.volumen;

    // Si ya trae el volumen en el texto y no hay una reconfiguración explícita
    if (tieneVolumenEnTexto && !volConfigurado) {
      return nombreBase;
    }
    if (tieneVolumenEnDescripcion && !volConfigurado && producto?.nombre) {
      return item.descripcion.trim();
    }

    const vol = resolverVolumenGondola(cfg);
    const volStr = formatearVolumenM3(vol);

    // Si el texto ya tiene un volumen pero la config pide otro (o el mismo)
    if (tieneVolumenEnTexto) {
      return nombreBase.replace(/\b\d+(?:[.,]\d+)?\s*m(?:3|³)\b/i, `${volStr} M3`);
    }

    return `${nombreBase} ${volStr} M3`;
  }

  return nombreBase;
}

