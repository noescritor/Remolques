// Motor de edición de recetas y clonación de modelos
// Valida parámetros de negocio y ejecuta operaciones privilegiadas mediante serviceClient

export interface ClonarRecetaParams {
  modeloOrigenId: string;
  productoId: string;
  nombre: string;
  largoFt: number;
  numEjes: number;
  usuarioId?: string | null;
}

export interface GuardarLineaParams {
  modeloId: string;
  materialId: string;
  cantidad: number;
  escala: 'fija' | 'por_eje' | 'por_largo';
  faseId: string;
  paso?: string | null;
  uso?: string | null;
  seccion?: string;
  lineaId?: string | null;
  usuarioId?: string | null;
  motivo?: string | null;
}

export interface EliminarLineaParams {
  lineaId: string;
  usuarioId?: string | null;
  motivo?: string | null;
}

export class HttpError extends Error {
  status: number;
  constructor(status: number, message: string) {
    super(message);
    this.name = "HttpError";
    this.status = status;
  }
}

export async function clonarRecetaMotor(serviceClient: any, params: ClonarRecetaParams) {
  if (!params.modeloOrigenId || typeof params.modeloOrigenId !== 'string') {
    throw new HttpError(400, 'modeloOrigenId es requerido');
  }
  const prodId = (params.productoId || '').trim();
  if (!prodId) {
    throw new HttpError(400, 'productoId (clave) es requerido');
  }
  const nom = (params.nombre || '').trim();
  if (!nom) {
    throw new HttpError(400, 'nombre del nuevo modelo es requerido');
  }
  const largo = Number(params.largoFt);
  if (!Number.isFinite(largo) || largo <= 0) {
    throw new HttpError(400, 'largoFt debe ser un número positivo finito');
  }
  const ejes = Number(params.numEjes);
  if (!Number.isInteger(ejes) || ejes < 1) {
    throw new HttpError(400, 'numEjes debe ser un entero >= 1');
  }

  const { data, error } = await serviceClient.rpc('clonar_receta_modelo', {
    p_modelo_origen_id: params.modeloOrigenId,
    p_producto_id: prodId,
    p_nombre: nom,
    p_largo_ft: largo,
    p_num_ejes: ejes,
    p_usuario_id: params.usuarioId || null,
  });

  if (error) {
    const msg = error.message || '';
    if (msg.includes('producto_id_duplicado')) {
      throw new HttpError(409, `La clave de producto ${prodId} ya existe en el catálogo`);
    }
    if (msg.includes('modelo_origen_no_encontrado')) {
      throw new HttpError(404, 'Modelo origen no encontrado');
    }
    throw new HttpError(500, msg);
  }

  return { modelo_id: data };
}

export async function obtenerRecetaMotor(supabase: any, modeloId: string) {
  if (!modeloId) {
    throw new HttpError(400, 'modeloId es requerido');
  }

  const { data: modelo, error: modErr } = await supabase
    .from('modelos')
    .select('id, tipo, largo_ft, num_ejes, producto_id, costos_derivados_de, activo, productos(nombre)')
    .eq('id', modeloId)
    .single();

  if (modErr || !modelo) {
    throw new HttpError(404, 'Modelo no encontrado');
  }

  const { data: lineas, error: linErr } = await supabase
    .from('receta_base')
    .select(`
      id,
      modelo_id,
      material_id,
      cantidad,
      escala,
      paso,
      uso,
      seccion,
      notas,
      fase_id,
      productos (id, nombre, unidad, costo, descripcion),
      fases_despiece (id, clave, nombre, orden)
    `)
    .eq('modelo_id', modeloId);

  if (linErr) {
    throw new HttpError(500, linErr.message);
  }

  return {
    modelo: {
      ...modelo,
      nombre: modelo.productos?.nombre || '',
    },
    lineas: (lineas || []).map((l: any) => ({
      id: l.id,
      material_id: l.material_id,
      nombre: l.productos?.nombre || '',
      unidad: l.productos?.unidad || 'PZA',
      costo: l.productos?.costo,
      descripcion: l.productos?.descripcion,
      cantidad: Number(l.cantidad),
      escala: l.escala || 'fija',
      paso: l.paso,
      uso: l.uso,
      seccion: l.seccion || 'ensamble',
      notas: l.notas,
      fase_id: l.fase_id,
      fase: l.fases_despiece ? {
        id: l.fases_despiece.id,
        clave: l.fases_despiece.clave,
        nombre: l.fases_despiece.nombre,
        orden: l.fases_despiece.orden,
      } : null,
    })),
  };
}

export async function guardarLineaRecetaMotor(serviceClient: any, params: GuardarLineaParams) {
  if (!params.modeloId) throw new HttpError(400, 'modeloId es requerido');
  if (!params.materialId) throw new HttpError(400, 'materialId es requerido');
  const cant = Number(params.cantidad);
  if (!Number.isFinite(cant) || cant <= 0) {
    throw new HttpError(400, 'cantidad debe ser un número positivo');
  }
  if (!['fija', 'por_eje', 'por_largo'].includes(params.escala)) {
    throw new HttpError(400, 'escala inválida: debe ser fija, por_eje o por_largo');
  }
  if (!params.faseId) throw new HttpError(400, 'faseId es requerido');

  const { data, error } = await serviceClient.rpc('guardar_linea_receta', {
    p_modelo_id: params.modeloId,
    p_material_id: params.materialId,
    p_cantidad: cant,
    p_escala: params.escala,
    p_fase_id: params.faseId,
    p_paso: params.paso || null,
    p_uso: params.uso || null,
    p_seccion: params.seccion || 'ensamble',
    p_linea_id: params.lineaId || null,
    p_usuario_id: params.usuarioId || null,
    p_motivo: params.motivo || null,
  });

  if (error) {
    const msg = error.message || '';
    if (msg.includes('material_no_encontrado')) throw new HttpError(404, 'Material no encontrado');
    if (msg.includes('modelo_no_encontrado')) throw new HttpError(404, 'Modelo no encontrado');
    throw new HttpError(500, msg);
  }

  return { linea_id: data };
}

export async function eliminarLineaRecetaMotor(serviceClient: any, params: EliminarLineaParams) {
  if (!params.lineaId) throw new HttpError(400, 'lineaId es requerido');

  const { data, error } = await serviceClient.rpc('eliminar_linea_receta', {
    p_linea_id: params.lineaId,
    p_usuario_id: params.usuarioId || null,
    p_motivo: params.motivo || null,
  });

  if (error) {
    throw new HttpError(500, error.message);
  }

  return { eliminado: Boolean(data) };
}

export async function obtenerHistorialRecetaMotor(supabase: any, modeloId: string) {
  if (!modeloId) throw new HttpError(400, 'modeloId es requerido');

  const { data, error } = await supabase
    .from('receta_base_historial')
    .select(`
      id,
      modelo_id,
      linea_id,
      accion,
      material_id,
      fase_id,
      datos_anteriores,
      datos_nuevos,
      usuario_id,
      motivo,
      created_at,
      productos (nombre)
    `)
    .eq('modelo_id', modeloId)
    .order('created_at', { ascending: false });

  if (error) {
    throw new HttpError(500, error.message);
  }

  return {
    historial: (data || []).map((h: any) => ({
      ...h,
      material_nombre: h.productos?.nombre || null,
    })),
  };
}
