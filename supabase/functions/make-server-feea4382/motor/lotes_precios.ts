/**
 * Motor de actualización masiva de precios (Sub-bloque 2R-14)
 * - Exportación de catálogo de precios por fuente con filtros
 * - Previsualización y análisis de cambios con lectura fresca de base de datos
 * - Aplicación atómica de lotes con validación de concurrencia
 * - Reversión segura de lotes
 */

import {
  analizarLote,
  FuentePrecios,
  FilaLoteEntrada,
  AnalisisLoteResultado,
} from '../../../../src/app/utils/preciosLote.ts';

export interface FiltrosExportacion {
  fuente: string;
  q?: string;
  proveedor?: string;
  tipo?: string;
  grupo?: string;
  tipo_modelo?: string;
  solo_sin_precio?: boolean;
}

export interface FilaExportada {
  fuente: FuentePrecios;
  id: string;
  descripcion: string;
  contexto: string;
  unidad: string;
  precio_actual: number | null;
  incluye_iva: boolean | null;
}

export interface CambioPrecioEntrada {
  fuente: FuentePrecios;
  id: string;
  precio_nuevo: number;
  precio_anterior_visto?: number;
}

export interface LoteAplicarPayload {
  origen: 'excel' | 'porcentaje' | 'manual';
  descripcion: string;
  cambios: CambioPrecioEntrada[];
}

/**
 * Exporta precios de la base de datos según la fuente solicitada y los filtros aplicados.
 */
export async function exportarPrecios(
  supabase: any,
  orgId: string,
  filtros: FiltrosExportacion
): Promise<FilaExportada[]> {
  const fuente = filtros.fuente;
  const q = (filtros.q || '').trim().toLowerCase();
  const soloSinPrecio = Boolean(filtros.solo_sin_precio);

  if (fuente === 'productos') {
    let query = supabase
      .from('productos')
      .select('id, nombre, descripcion, unidad, costo, tipo_item')
      .eq('organizacion_id', orgId)
      .eq('tipo_item', 'materia_prima')
      .order('nombre', { ascending: true });

    if (filtros.tipo) {
      query = query.eq('tipo_item', filtros.tipo);
    }
    if (soloSinPrecio) {
      query = query.or('costo.is.null,costo.eq.0');
    }

    const { data, error } = await query;
    if (error) throw new Error(`Error al exportar productos: ${error.message}`);

    let filas: FilaExportada[] = (data || []).map((p: any) => ({
      fuente: 'productos',
      id: p.id,
      descripcion: p.nombre,
      contexto: p.tipo_item || 'materia_prima',
      unidad: p.unidad || 'PZA',
      precio_actual: p.costo !== null ? Number(p.costo) : null,
      incluye_iva: null,
    }));

    if (q) {
      filas = filas.filter(
        (f) =>
          f.descripcion.toLowerCase().includes(q) ||
          f.contexto.toLowerCase().includes(q)
      );
    }
    return filas;
  }

  if (fuente === 'opcion_costos') {
    let query = supabase
      .from('opcion_costos')
      .select(`
        id,
        tipo_modelo,
        costo_unitario,
        opcion:opciones_configuracion!inner(
          id,
          nombre,
          grupo:grupos_configuracion!inner(id, nombre)
        )
      `)
      .eq('organizacion_id', orgId);

    if (filtros.tipo_modelo) {
      query = query.eq('tipo_modelo', filtros.tipo_modelo);
    }
    if (soloSinPrecio) {
      query = query.or('costo_unitario.is.null,costo_unitario.eq.0');
    }

    const { data, error } = await query;
    if (error) throw new Error(`Error al exportar opcion_costos: ${error.message}`);

    let filas: FilaExportada[] = (data || []).map((row: any) => {
      const grupoNombre = row.opcion?.grupo?.nombre || 'General';
      const opcionNombre = row.opcion?.nombre || 'Opción';
      return {
        fuente: 'opcion_costos',
        id: row.id,
        descripcion: opcionNombre,
        contexto: `${grupoNombre} (${row.tipo_modelo})`,
        unidad: 'PZA',
        precio_actual: row.costo_unitario !== null ? Number(row.costo_unitario) : null,
        incluye_iva: null,
      };
    });

    if (filtros.grupo) {
      const gNorm = filtros.grupo.toLowerCase();
      filas = filas.filter((f) => f.contexto.toLowerCase().includes(gNorm));
    }
    if (q) {
      filas = filas.filter(
        (f) =>
          f.descripcion.toLowerCase().includes(q) ||
          f.contexto.toLowerCase().includes(q)
      );
    }
    filas.sort((a, b) => a.contexto.localeCompare(b.contexto) || a.descripcion.localeCompare(b.descripcion));
    return filas;
  }

  if (fuente === 'costos_modelo') {
    let query = supabase
      .from('costos_modelo')
      .select(`
        id,
        seccion,
        concepto,
        costo_unitario,
        modelo:modelos!inner(id, nombre, tipo)
      `)
      .eq('organizacion_id', orgId);

    if (filtros.tipo_modelo) {
      query = query.eq('modelo.tipo', filtros.tipo_modelo);
    }
    if (soloSinPrecio) {
      query = query.or('costo_unitario.is.null,costo_unitario.eq.0');
    }

    const { data, error } = await query;
    if (error) throw new Error(`Error al exportar costos_modelo: ${error.message}`);

    let filas: FilaExportada[] = (data || []).map((row: any) => ({
      fuente: 'costos_modelo',
      id: row.id,
      descripcion: row.concepto,
      contexto: `${row.modelo?.nombre || 'Modelo'} / ${row.seccion}`,
      unidad: 'PZA',
      precio_actual: row.costo_unitario !== null ? Number(row.costo_unitario) : null,
      incluye_iva: null,
    }));

    if (q) {
      filas = filas.filter(
        (f) =>
          f.descripcion.toLowerCase().includes(q) ||
          f.contexto.toLowerCase().includes(q)
      );
    }
    filas.sort((a, b) => a.contexto.localeCompare(b.contexto) || a.descripcion.localeCompare(b.descripcion));
    return filas;
  }

  if (fuente === 'acero_precios') {
    let query = supabase
      .from('acero_precios')
      .select(`
        id,
        proveedor,
        precio,
        incluye_iva,
        material:acero_materiales!inner(id, nombre, tipo)
      `)
      .eq('organizacion_id', orgId);

    if (filtros.proveedor) {
      query = query.eq('proveedor', filtros.proveedor);
    }
    if (filtros.tipo) {
      query = query.eq('material.tipo', filtros.tipo);
    }
    if (soloSinPrecio) {
      query = query.or('precio.is.null,precio.eq.0');
    }

    const { data, error } = await query;
    if (error) throw new Error(`Error al exportar acero_precios: ${error.message}`);

    let filas: FilaExportada[] = (data || []).map((row: any) => ({
      fuente: 'acero_precios',
      id: row.id,
      descripcion: row.material?.nombre || 'Material',
      contexto: `${row.material?.tipo || 'acero'} / ${row.proveedor}`,
      unidad: 'TRAMO/LÁMINA',
      precio_actual: row.precio !== null ? Number(row.precio) : null,
      incluye_iva: row.incluye_iva ?? true,
    }));

    if (q) {
      filas = filas.filter(
        (f) =>
          f.descripcion.toLowerCase().includes(q) ||
          f.contexto.toLowerCase().includes(q)
      );
    }
    filas.sort((a, b) => a.descripcion.localeCompare(b.descripcion) || a.contexto.localeCompare(b.contexto));
    return filas;
  }

  throw new Error(`Fuente no válida para exportación: ${fuente}`);
}

/**
 * Previsualiza los cambios de un lote leyendo los precios actuales de la base de datos
 * y aplicando la función pura analizarLote. No escribe ningún dato.
 */
export async function previsualizarCambios(
  supabase: any,
  orgId: string,
  cambios: { fuente: FuentePrecios; id: string; precio_nuevo: number }[]
): Promise<AnalisisLoteResultado> {
  const idsPorFuente: Record<FuentePrecios, string[]> = {
    productos: [],
    opcion_costos: [],
    costos_modelo: [],
    acero_precios: [],
  };

  for (const c of cambios) {
    if (idsPorFuente[c.fuente]) {
      idsPorFuente[c.fuente].push(c.id);
    }
  }

  // Cargar precios actuales frescos de la base de datos
  const preciosActuales = new Map<string, { precioActual: number | null; descripcion: string; contexto?: string }>();

  // 1. Productos
  if (idsPorFuente.productos.length > 0) {
    const { data } = await supabase
      .from('productos')
      .select('id, nombre, costo, tipo_item')
      .eq('organizacion_id', orgId)
      .in('id', idsPorFuente.productos);
    for (const p of data || []) {
      preciosActuales.set(`productos:${p.id}`, {
        precioActual: p.costo !== null ? Number(p.costo) : null,
        descripcion: p.nombre,
        contexto: p.tipo_item,
      });
    }
  }

  // 2. Opcion costos
  if (idsPorFuente.opcion_costos.length > 0) {
    const { data } = await supabase
      .from('opcion_costos')
      .select('id, costo_unitario, tipo_modelo, opcion:opciones_configuracion(nombre, grupo:grupos_configuracion(nombre))')
      .eq('organizacion_id', orgId)
      .in('id', idsPorFuente.opcion_costos);
    for (const oc of data || []) {
      const g = (oc.opcion as any)?.grupo?.nombre || '';
      const o = (oc.opcion as any)?.nombre || '';
      preciosActuales.set(`opcion_costos:${oc.id}`, {
        precioActual: oc.costo_unitario !== null ? Number(oc.costo_unitario) : null,
        descripcion: o,
        contexto: `${g} (${oc.tipo_modelo})`,
      });
    }
  }

  // 3. Costos modelo
  if (idsPorFuente.costos_modelo.length > 0) {
    const { data } = await supabase
      .from('costos_modelo')
      .select('id, concepto, seccion, costo_unitario, modelo:modelos(nombre)')
      .eq('organizacion_id', orgId)
      .in('id', idsPorFuente.costos_modelo);
    for (const cm of data || []) {
      const m = (cm.modelo as any)?.nombre || '';
      preciosActuales.set(`costos_modelo:${cm.id}`, {
        precioActual: cm.costo_unitario !== null ? Number(cm.costo_unitario) : null,
        descripcion: cm.concepto,
        contexto: `${m} / ${cm.seccion}`,
      });
    }
  }

  // 4. Acero precios
  if (idsPorFuente.acero_precios.length > 0) {
    const { data } = await supabase
      .from('acero_precios')
      .select('id, precio, proveedor, material:acero_materiales(nombre, tipo)')
      .eq('organizacion_id', orgId)
      .in('id', idsPorFuente.acero_precios);
    for (const ap of data || []) {
      const m = (ap.material as any)?.nombre || '';
      const t = (ap.material as any)?.tipo || '';
      preciosActuales.set(`acero_precios:${ap.id}`, {
        precioActual: ap.precio !== null ? Number(ap.precio) : null,
        descripcion: m,
        contexto: `${t} / ${ap.proveedor}`,
      });
    }
  }

  // Armar filas de entrada para analizarLote
  const filasParaAnalizar: FilaLoteEntrada[] = cambios.map((c) => {
    const info = preciosActuales.get(`${c.fuente}:${c.id}`);
    return {
      id: c.id,
      fuente: c.fuente,
      descripcion: info?.descripcion || `ID: ${c.id}`,
      contexto: info?.contexto,
      precioActual: info?.precioActual ?? null,
      precioNuevo: c.precio_nuevo,
    };
  });

  return analizarLote({ filas: filasParaAnalizar });
}

/**
 * Aplica atómicamente un lote de precios mediante la función SQL aplicar_lote_precios.
 */
export async function aplicarLote(
  adminClient: any,
  orgId: string,
  userId: string | null,
  payload: LoteAplicarPayload
): Promise<{ status: number; data: any }> {
  const { origen, descripcion, cambios } = payload;

  if (!cambios || !Array.isArray(cambios)) {
    return { status: 400, data: { error: 'El campo cambios debe ser un arreglo' } };
  }

  if (cambios.length > 2000) {
    return {
      status: 413,
      data: { error: `El lote excede el máximo permitido de 2,000 cambios (${cambios.length})` },
    };
  }

  if (!descripcion || String(descripcion).trim() === '') {
    return { status: 400, data: { error: 'La descripción del lote es obligatoria' } };
  }

  // Lista blanca estricta de campos por cada cambio
  const cambiosLimpios = cambios.map((c: any) => ({
    fuente: c.fuente,
    id: String(c.id || '').trim(),
    precio_nuevo: Number(c.precio_nuevo),
    precio_anterior_visto:
      c.precio_anterior_visto !== undefined && c.precio_anterior_visto !== null
        ? Number(c.precio_anterior_visto)
        : null,
  }));

  // Validar precios numéricos válidos
  for (const c of cambiosLimpios) {
    if (isNaN(c.precio_nuevo) || !isFinite(c.precio_nuevo) || c.precio_nuevo < 0) {
      return { status: 400, data: { error: `Precio nuevo inválido para registro ${c.id}: ${c.precio_nuevo}` } };
    }
  }

  const { data: rpcRes, error } = await adminClient.rpc('aplicar_lote_precios', {
    p_org: orgId,
    p_usuario: userId,
    p_origen: origen,
    p_descripcion: descripcion.slice(0, 200),
    p_cambios: cambiosLimpios,
  });

  if (error) {
    return { status: 500, data: { error: `Error en función aplicar_lote_precios: ${error.message}` } };
  }

  if (!rpcRes.exito && rpcRes.error === 'conflicto') {
    return { status: 409, data: rpcRes };
  }

  if (!rpcRes.exito) {
    return { status: 400, data: rpcRes };
  }

  return { status: 200, data: rpcRes };
}

/**
 * Obtiene los últimos lotes de precios registrados en la organización.
 */
export async function obtenerLotes(
  supabase: any,
  orgId: string,
  limite: number = 50
) {
  const { data, error } = await supabase
    .from('precios_lotes')
    .select('id, origen, descripcion, creado_el, total_cambios, revertido_el, revertido_por, lote_origen_id, usuario_id')
    .eq('organizacion_id', orgId)
    .order('creado_el', { ascending: false })
    .limit(limite);

  if (error) throw new Error(`Error al obtener lotes: ${error.message}`);
  return data || [];
}

/**
 * Obtiene el detalle de un lote y sus items.
 */
export async function obtenerLoteDetalle(
  supabase: any,
  orgId: string,
  loteId: string
) {
  const { data: lote, error: errLote } = await supabase
    .from('precios_lotes')
    .select('*')
    .eq('id', loteId)
    .eq('organizacion_id', orgId)
    .single();

  if (errLote || !lote) {
    return null;
  }

  const { data: items, error: errItems } = await supabase
    .from('precios_lotes_items')
    .select('*')
    .eq('lote_id', loteId)
    .eq('organizacion_id', orgId)
    .order('created_at', { ascending: true });

  if (errItems) throw new Error(`Error al obtener items del lote: ${errItems.message}`);

  return {
    ...lote,
    items: items || [],
  };
}

/**
 * Revierte un lote de precios mediante la función SQL revertir_lote_precios.
 */
export async function revertirLote(
  adminClient: any,
  orgId: string,
  userId: string | null,
  loteId: string
): Promise<{ status: number; data: any }> {
  const { data: rpcRes, error } = await adminClient.rpc('revertir_lote_precios', {
    p_org: orgId,
    p_usuario: userId,
    p_lote_id: loteId,
  });

  if (error) {
    return { status: 500, data: { error: `Error en función revertir_lote_precios: ${error.message}` } };
  }

  if (!rpcRes.exito) {
    if (rpcRes.error === 'not_found') return { status: 404, data: rpcRes };
    if (rpcRes.error === 'ya_revertido') return { status: 409, data: rpcRes };
    return { status: 400, data: rpcRes };
  }

  return { status: 200, data: rpcRes };
}
