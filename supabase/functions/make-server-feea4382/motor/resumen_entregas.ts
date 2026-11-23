/**
 * Resumen de entregas de almacén por orden de trabajo y por fase.
 * Solo lectura sobre la vista v_orden_despiece_avance (con RLS por organización).
 */

export interface LineaAvanceDespiece {
  linea_id?: string;
  orden_trabajo_id: string;
  fase_clave?: string | null;
  fase_nombre?: string | null;
  cantidad_requerida?: number | string | null;
  cantidad_entregada?: number | string | null;
  estado_entrega?: string | null;
  anulada?: boolean | null;
}

export interface ResumenFaseEntrega {
  total_partidas: number;
  partidas_completas: number;
  porcentaje: number | null;
}

export interface ResumenEntregasOrden {
  orden_trabajo_id: string;
  total_partidas: number;
  partidas_completas: number;
  porcentaje: number | null;
  por_fase: Record<string, ResumenFaseEntrega>;
}

const TAMANO_PAGINA_ENTREGAS = 1000;

/**
 * Criterio único de "partida completa":
 * - Si viene estado_entrega de la vista SQL, usa estado_entrega === 'completo'.
 * - Si no viene estado_entrega, requiere cantidad_entregada > 0 y >= cantidad_requerida
 *   (evita que 0 >= 0 cuente como completa cuando la vista lo marca 'pendiente').
 */
export function esPartidaCompleta(row: LineaAvanceDespiece): boolean {
  if (row.estado_entrega !== undefined && row.estado_entrega !== null) {
    return row.estado_entrega === "completo";
  }
  const req = Number(row.cantidad_requerida ?? 0);
  const ent = Number(row.cantidad_entregada ?? 0);
  return ent > 0 && ent >= req;
}

export function agruparResumenEntregas(
  lineas: LineaAvanceDespiece[]
): ResumenEntregasOrden[] {
  const porOrden = new Map<
    string,
    {
      total_partidas: number;
      partidas_completas: number;
      fases: Map<string, { total_partidas: number; partidas_completas: number }>;
    }
  >();

  for (const row of lineas || []) {
    if (!row?.orden_trabajo_id || row.anulada) continue;

    let entry = porOrden.get(row.orden_trabajo_id);
    if (!entry) {
      entry = {
        total_partidas: 0,
        partidas_completas: 0,
        fases: new Map(),
      };
      porOrden.set(row.orden_trabajo_id, entry);
    }

    const completa = esPartidaCompleta(row);
    entry.total_partidas += 1;
    if (completa) entry.partidas_completas += 1;

    const faseClave = String(row.fase_clave || "sin_fase").trim() || "sin_fase";
    let faseEntry = entry.fases.get(faseClave);
    if (!faseEntry) {
      faseEntry = { total_partidas: 0, partidas_completas: 0 };
      entry.fases.set(faseClave, faseEntry);
    }
    faseEntry.total_partidas += 1;
    if (completa) faseEntry.partidas_completas += 1;
  }

  const resultado: ResumenEntregasOrden[] = [];
  for (const [ordenId, entry] of porOrden.entries()) {
    const porFase: Record<string, ResumenFaseEntrega> = {};
    for (const [faseClave, f] of entry.fases.entries()) {
      porFase[faseClave] = {
        total_partidas: f.total_partidas,
        partidas_completas: f.partidas_completas,
        porcentaje:
          f.total_partidas > 0
            ? Math.round((f.partidas_completas / f.total_partidas) * 100)
            : null,
      };
    }

    resultado.push({
      orden_trabajo_id: ordenId,
      total_partidas: entry.total_partidas,
      partidas_completas: entry.partidas_completas,
      porcentaje:
        entry.total_partidas > 0
          ? Math.round((entry.partidas_completas / entry.total_partidas) * 100)
          : null,
      por_fase: porFase,
    });
  }

  return resultado;
}

export async function resumenEntregasOrdenesMotor(
  supabase: any,
  orgId: string
): Promise<ResumenEntregasOrden[]> {
  if (!orgId) {
    throw new Error("Organización requerida para consultar resumen de entregas");
  }

  const todas: LineaAvanceDespiece[] = [];
  let desde = 0;

  while (true) {
    const hasta = desde + TAMANO_PAGINA_ENTREGAS - 1;
    const { data, error } = await supabase
      .from("v_orden_despiece_avance")
      .select(
        "linea_id, orden_trabajo_id, fase_clave, fase_nombre, cantidad_requerida, cantidad_entregada, estado_entrega"
      )
      .eq("organizacion_id", orgId)
      .order("linea_id", { ascending: true })
      .range(desde, hasta);

    if (error) throw error;
    const bloque = Array.isArray(data) ? data : [];
    todas.push(...bloque);
    if (bloque.length < TAMANO_PAGINA_ENTREGAS) break;
    desde += TAMANO_PAGINA_ENTREGAS;
  }

  return agruparResumenEntregas(todas);
}
