import {
  resolverVolumenGondola,
  formatearVolumenM3
} from "../../../supabase/functions/make-server-feea4382/motor/escalas.ts";

export interface InfoProductoTitulo {
  nombre?: string | null;
}

export interface InfoModeloTitulo {
  tipo?: string | null;
  largo_ft?: number | string | null;
  num_ejes?: number | string | null;
}

/**
 * Genera el título para la cabecera del configurador de equipo.
 * Garantiza interpolación segura sin caracteres literales de plantilla y
 * resuelve el volumen dinámico para góndolas.
 */
export function tituloEquipo(
  producto?: InfoProductoTitulo | null,
  modelo?: InfoModeloTitulo | null,
  configuracion?: any
): string {
  const tipo = (modelo?.tipo || "").toLowerCase();

  if (tipo === "gondola") {
    const numEjes = modelo?.num_ejes ? Number(modelo.num_ejes) : 2;
    const vol = resolverVolumenGondola(configuracion);
    const volStr = formatearVolumenM3(vol);
    return `GONDOLA ${numEjes} EJES ${volStr} M3`;
  }

  const nombreProd = producto?.nombre || "";
  const partesModelo: string[] = [];

  if (tipo) {
    partesModelo.push(tipo);
  }

  if (modelo?.largo_ft && Number(modelo.largo_ft) > 0) {
    partesModelo.push(`${modelo.largo_ft}FT`);
  }

  if (modelo?.num_ejes && Number(modelo.num_ejes) > 0) {
    partesModelo.push(`${modelo.num_ejes} EJES`);
  }

  const detalleModelo = partesModelo.join(" ");

  if (nombreProd && detalleModelo) {
    return `${nombreProd} - ${detalleModelo}`;
  }

  return nombreProd || detalleModelo || "Equipo";
}
