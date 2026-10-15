export interface BomLineaResumen {
  material_id: string;
  nombre: string;
  unidad: string;
  cantidad: number;
  seccion?: string;
  origen?: string[];
  paso?: string[];
  uso?: string[];
}

export interface BomEquipoResumen {
  descripcion: string;
  modelo_id?: string | null;
  cantidad: number;
  lineas: BomLineaResumen[];
  omitidas?: Array<{ descripcion: string; texto: string }>;
  alternativas?: Array<{ reemplaza: string | null; posibles_reemplazos: string[]; sustituto: string; grupo: string }>;
}

export interface PiezaConsolidada {
  material_id: string;
  nombre: string;
  unidad: string;
  cantidad_total: number;
}

export function formatearCantidad(n: number): string {
  if (n == null || isNaN(n)) return "0";
  const r = Math.round(n * 1000) / 1000;
  return r.toString();
}

export function formatearOrigen(origen?: string[]): string {
  if (!origen || origen.length === 0) return "Base";
  const partes = origen.map((item) => {
    if (item === "base") return "Base";
    if (item.startsWith("opcion:")) {
      const resto = item.replace(/^opcion:/, "");
      const grupo = resto.split("/")[0] || resto;
      return `Opción: ${grupo}`;
    }
    return item;
  });
  return partes.join(", ");
}

export function contarPiezasDistintas(bom: BomEquipoResumen[]): number {
  const ids = new Set<string>();
  for (const eq of bom || []) {
    for (const l of eq.lineas || []) {
      if (l.material_id) {
        ids.add(`${l.material_id}_${l.unidad || ""}`);
      } else if (l.nombre) {
        ids.add(`${l.nombre}_${l.unidad || ""}`);
      }
    }
  }
  return ids.size;
}

export function consolidarDespiece(bom: BomEquipoResumen[]): PiezaConsolidada[] {
  const mapa = new Map<string, PiezaConsolidada>();

  for (const eq of bom || []) {
    const cantEq = Number(eq.cantidad) > 0 ? Number(eq.cantidad) : 1;
    for (const l of eq.lineas || []) {
      const clave = `${l.material_id || l.nombre}_${l.unidad || ""}`;
      const cantTotal = (Number(l.cantidad) || 0) * cantEq;

      const existente = mapa.get(clave);
      if (existente) {
        existente.cantidad_total += cantTotal;
      } else {
        mapa.set(clave, {
          material_id: l.material_id || "",
          nombre: l.nombre || "Sin nombre",
          unidad: l.unidad || "PZA",
          cantidad_total: cantTotal
        });
      }
    }
  }

  const resultado = Array.from(mapa.values()).map((p) => ({
    ...p,
    cantidad_total: Math.round(p.cantidad_total * 1000) / 1000
  }));

  resultado.sort((a, b) => a.nombre.localeCompare(b.nombre, "es", { sensitivity: "base" }));
  return resultado;
}

export function agruparLineasEquipo(
  lineas: BomLineaResumen[],
  tipoAgrupacion: "seccion" | "paso"
): Record<string, BomLineaResumen[]> {
  const grupos: Record<string, BomLineaResumen[]> = {};

  for (const l of lineas || []) {
    if (tipoAgrupacion === "seccion") {
      const k = l.seccion ? l.seccion.trim() : "Sin sección";
      if (!grupos[k]) grupos[k] = [];
      grupos[k].push(l);
    } else {
      const pasos = l.paso && l.paso.length > 0 ? l.paso : ["Sin paso"];
      for (const p of pasos) {
        const k = p ? p.trim() : "Sin paso";
        if (!grupos[k]) grupos[k] = [];
        grupos[k].push(l);
      }
    }
  }

  return grupos;
}

export function filtrarLineas(lineas: BomLineaResumen[], busqueda: string): BomLineaResumen[] {
  if (!busqueda || !busqueda.trim()) return lineas;
  const q = busqueda.trim().toLowerCase();
  return (lineas || []).filter(
    (l) =>
      (l.nombre && l.nombre.toLowerCase().includes(q)) ||
      (l.material_id && l.material_id.toLowerCase().includes(q)) ||
      (l.seccion && l.seccion.toLowerCase().includes(q)) ||
      (l.paso && l.paso.some((p) => p.toLowerCase().includes(q)))
  );
}

function escaparCsv(val: any): string {
  if (val == null) return "";
  const s = String(val);
  if (s.includes('"') || s.includes(",") || s.includes("\n") || s.includes("\r")) {
    return `"${s.replace(/"/g, '""')}"`;
  }
  return s;
}

export function generarCsvDespiece(
  bom: BomEquipoResumen[],
  opciones?: { cotizacionFolio?: string | null }
): string {
  const lineas: string[] = [];

  // UTF-8 BOM
  const BOM = "\uFEFF";

  if (opciones?.cotizacionFolio) {
    lineas.push(`Despiece - Cotización ${opciones.cotizacionFolio}`);
    lineas.push("");
  }

  // 1. Resumen consolidado
  lineas.push("CONSOLIDADO DE MATERIALES");
  lineas.push("Pieza,Unidad,Cantidad total");

  const consolidado = consolidarDespiece(bom);
  for (const p of consolidado) {
    lineas.push(`${escaparCsv(p.nombre)},${escaparCsv(p.unidad)},${formatearCantidad(p.cantidad_total)}`);
  }

  lineas.push("");
  lineas.push("DETALLE POR EQUIPO");
  lineas.push("Equipo,Pieza,Unidad,Por equipo,Cantidad equipos,Total,Paso,Sección,Origen");

  for (const eq of bom || []) {
    const cantEq = Number(eq.cantidad) > 0 ? Number(eq.cantidad) : 1;
    for (const l of eq.lineas || []) {
      const tot = (Number(l.cantidad) || 0) * cantEq;
      const pasoTxt = l.paso && l.paso.length > 0 ? l.paso.join("; ") : "Sin paso";
      const origenTxt = formatearOrigen(l.origen);

      lineas.push(
        `${escaparCsv(eq.descripcion)},${escaparCsv(l.nombre)},${escaparCsv(l.unidad)},${formatearCantidad(
          l.cantidad
        )},${cantEq},${formatearCantidad(tot)},${escaparCsv(pasoTxt)},${escaparCsv(l.seccion || "")},${escaparCsv(
          origenTxt
        )}`
      );
    }
  }

  return BOM + lineas.join("\r\n");
}
