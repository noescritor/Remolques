/**
 * Módulo de negocio para el Catálogo de Costos Administrable (Sub-bloque 2R-7)
 * Permite consultar y editar costos (opcion_costos, costos_modelo, procesos_manufactura, parametros_costeo)
 * con trazabilidad en costos_historial y verificación de permisos.
 */

export interface ResumenOpcionItem {
  opcion_id: string;
  grupo_id: string;
  grupo_clave: string;
  grupo_nombre: string;
  opcion_clave: string;
  opcion_nombre: string;
  opcion_costo_id: string | null;
  cantidad_base: number;
  escala: string;
  costo_unitario: number;
  tiene_costo: boolean;
  fuente: string | null;
  producto_id: string | null;
  producto_nombre: string | null;
  producto_costo: number | null;
  costo_desde_producto: boolean;
  receta_piezas_count: number;
}

export interface CoberturaResumen {
  tipo_modelo: string;
  total_opciones: number;
  con_costo: number;
  sin_costo: number;
  opciones_sin_costo: { opcion_id: string; grupo_clave: string; opcion_clave: string; opcion_nombre: string }[];
  con_receta: number;
  sin_receta: number;
  opciones_sin_receta: { opcion_id: string; grupo_clave: string; opcion_clave: string; opcion_nombre: string }[];
}

export async function verificarPermisoEdicion(
  serviceClient: any,
  orgId: string,
  usuarioId: string
): Promise<boolean> {
  if (!serviceClient || !usuarioId) return false;
  const { data, error } = await serviceClient
    .from("perfiles_organizacion")
    .select("rol")
    .eq("organizacion_id", orgId)
    .eq("usuario_id", usuarioId)
    .maybeSingle();

  if (error || !data) return false;
  return data.rol === "propietario" || data.rol === "admin";
}

export async function registrarHistorial(
  client: any,
  item: {
    organizacion_id: string;
    tabla: "opcion_costos" | "costos_modelo" | "procesos_manufactura" | "parametros_costeo";
    registro_id: string;
    concepto?: string | null;
    campo: string;
    valor_anterior: string | null;
    valor_nuevo: string | null;
    usuario_id: string | null;
  }
) {
  try {
    const { error } = await client.from("costos_historial").insert([item]);
    if (error) console.error("Error registrando costos_historial:", error);
  } catch (err) {
    console.error("Excepción registrando costos_historial:", err);
  }
}

export async function obtenerResumenCatalogo(
  supabase: any,
  orgId: string,
  tipoModelo: string
): Promise<{ opciones: ResumenOpcionItem[]; cobertura: CoberturaResumen }> {
  if (!["plataforma", "dolly", "gondola"].includes(tipoModelo)) {
    throw new Error("tipo_modelo inválido (debe ser plataforma, dolly o gondola)");
  }

  // 1. Grupos aplicables al tipo
  const { data: gruposRaw, error: errG } = await supabase
    .from("grupos_configuracion")
    .select("id, clave, nombre, aplica_a, orden")
    .eq("organizacion_id", orgId)
    .order("orden", { ascending: true });
  if (errG) throw errG;

  const gruposAplicables = (gruposRaw || []).filter((g: any) => {
    if (!g.aplica_a || !Array.isArray(g.aplica_a) || g.aplica_a.length === 0) return true;
    return g.aplica_a.includes(tipoModelo);
  });

  const gruposIds = new Set(gruposAplicables.map((g: any) => g.id));

  // 2. Opciones de los grupos aplicables
  const { data: opcionesRaw, error: errO } = await supabase
    .from("opciones_configuracion")
    .select("id, grupo_id, clave, nombre, activo")
    .eq("organizacion_id", orgId);
  if (errO) throw errO;

  const opcionesActivas = (opcionesRaw || []).filter(
    (o: any) => gruposIds.has(o.grupo_id) && o.activo !== false
  );

  // 3. Costos vigentes para el tipo_modelo
  const { data: opcionCostosRaw, error: errOC } = await supabase
    .from("opcion_costos")
    .select(`
      id,
      opcion_id,
      tipo_modelo,
      cantidad_base,
      escala,
      costo_unitario,
      fuente,
      producto_id,
      costo_desde_producto,
      productos (id, nombre, costo)
    `)
    .eq("organizacion_id", orgId)
    .eq("tipo_modelo", tipoModelo);
  if (errOC) throw errOC;

  const costosPorOpcion = new Map<string, any>();
  for (const oc of opcionCostosRaw || []) {
    costosPorOpcion.set(oc.opcion_id, oc);
  }

  // 4. Conteo de piezas en receta (opcion_componentes)
  const { data: componentesRaw, error: errComp } = await supabase
    .from("opcion_componentes")
    .select("opcion_id");
  if (errComp) throw errComp;

  const piezasPorOpcion = new Map<string, number>();
  for (const c of componentesRaw || []) {
    piezasPorOpcion.set(c.opcion_id, (piezasPorOpcion.get(c.opcion_id) || 0) + 1);
  }

  // 5. Armar lista completa
  const opciones: ResumenOpcionItem[] = [];
  const opcionesSinCosto: { opcion_id: string; grupo_clave: string; opcion_clave: string; opcion_nombre: string }[] = [];
  const opcionesSinReceta: { opcion_id: string; grupo_clave: string; opcion_clave: string; opcion_nombre: string }[] = [];

  for (const grupo of gruposAplicables) {
    const optsGrupo = opcionesActivas.filter((o: any) => o.grupo_id === grupo.id);
    for (const opt of optsGrupo) {
      const oc = costosPorOpcion.get(opt.id);
      const tieneCosto = Boolean(oc);
      const piezas = piezasPorOpcion.get(opt.id) || 0;

      const prod = oc?.productos;
      const prodCosto = prod?.costo !== null && prod?.costo !== undefined ? Number(prod.costo) : null;

      const item: ResumenOpcionItem = {
        opcion_id: opt.id,
        grupo_id: grupo.id,
        grupo_clave: grupo.clave,
        grupo_nombre: grupo.nombre,
        opcion_clave: opt.clave,
        opcion_nombre: opt.nombre,
        opcion_costo_id: oc?.id || null,
        cantidad_base: oc ? Number(oc.cantidad_base) : 1,
        escala: oc?.escala || "fija",
        costo_unitario: oc ? Number(oc.costo_unitario) : 0,
        tiene_costo: tieneCosto,
        fuente: oc?.fuente || null,
        producto_id: oc?.producto_id || null,
        producto_nombre: prod?.nombre || null,
        producto_costo: prodCosto,
        costo_desde_producto: Boolean(oc?.costo_desde_producto),
        receta_piezas_count: piezas
      };

      opciones.push(item);

      if (!tieneCosto) {
        opcionesSinCosto.push({
          opcion_id: opt.id,
          grupo_clave: grupo.clave,
          opcion_clave: opt.clave,
          opcion_nombre: opt.nombre
        });
      }

      if (piezas === 0) {
        opcionesSinReceta.push({
          opcion_id: opt.id,
          grupo_clave: grupo.clave,
          opcion_clave: opt.clave,
          opcion_nombre: opt.nombre
        });
      }
    }
  }

  const cobertura: CoberturaResumen = {
    tipo_modelo: tipoModelo,
    total_opciones: opciones.length,
    con_costo: opciones.filter(o => o.tiene_costo).length,
    sin_costo: opcionesSinCosto.length,
    opciones_sin_costo: opcionesSinCosto,
    con_receta: opciones.filter(o => o.receta_piezas_count > 0).length,
    sin_receta: opcionesSinReceta.length,
    opciones_sin_receta: opcionesSinReceta
  };

  return { opciones, cobertura };
}

export async function guardarOpcionCosto(
  supabase: any,
  orgId: string,
  usuarioId: string,
  opcionId: string,
  body: {
    tipo_modelo: string;
    cantidad_base: number;
    escala: string;
    costo_unitario: number;
    producto_id?: string | null;
    costo_desde_producto?: boolean;
    confirmar?: boolean;
  }
): Promise<{ opcion_costo: any; cambios: string[] }> {
  // 1. Validaciones
  if (!body || typeof body !== "object") {
    throw new Error("Cuerpo de petición inválido");
  }
  if (!["plataforma", "dolly", "gondola"].includes(body.tipo_modelo)) {
    throw new Error("tipo_modelo inválido (plataforma, dolly, gondola)");
  }
  if (!["fija", "por_eje", "por_largo"].includes(body.escala)) {
    throw new Error("escala inválida (fija, por_eje, por_largo)");
  }
  if (typeof body.cantidad_base !== "number" || !Number.isFinite(body.cantidad_base) || body.cantidad_base <= 0) {
    throw new Error("cantidad_base debe ser un número finito mayor a 0");
  }
  if (typeof body.costo_unitario !== "number" || !Number.isFinite(body.costo_unitario) || body.costo_unitario < 0) {
    throw new Error("costo_unitario debe ser un número finito mayor o igual a 0");
  }

  // Si hay producto_id, verificar existencia en la organización
  if (body.producto_id && String(body.producto_id).trim() !== "") {
    const { data: prod, error: errP } = await supabase
      .from("productos")
      .select("id, nombre, costo")
      .eq("id", body.producto_id)
      .eq("organizacion_id", orgId)
      .maybeSingle();

    if (errP || !prod) {
      throw new Error("El producto ligado no existe en la organización");
    }
  }

  // 2. Verificar que la opción pertenezca a la organización y obtener concepto para el historial
  const { data: optInfo, error: errOpt } = await supabase
    .from("opciones_configuracion")
    .select("id, clave, nombre, grupo:grupos_configuracion(clave, nombre)")
    .eq("id", opcionId)
    .eq("organizacion_id", orgId)
    .maybeSingle();

  if (errOpt || !optInfo) {
    throw new Error("La opción no existe en la organización");
  }

  const conceptoOpcion = optInfo.grupo?.nombre || optInfo.grupo?.clave
    ? `${optInfo.grupo?.nombre || optInfo.grupo?.clave}: ${optInfo.nombre || optInfo.clave} (${body.tipo_modelo})`
    : `Opción: ${optInfo.nombre || optInfo.clave} (${body.tipo_modelo})`;

  // 3. Buscar fila existente en opcion_costos
  const { data: existing, error: errExist } = await supabase
    .from("opcion_costos")
    .select("*")
    .eq("organizacion_id", orgId)
    .eq("opcion_id", opcionId)
    .eq("tipo_modelo", body.tipo_modelo)
    .maybeSingle();

  if (errExist) throw errExist;

  // 4. Determinar fuente
  let nuevaFuente: string;
  if (body.costo_desde_producto) {
    nuevaFuente = "Producto";
  } else if (body.confirmar) {
    nuevaFuente = "Manual (usuario)";
  } else if (existing) {
    const cambioValores =
      existing.costo_unitario !== body.costo_unitario ||
      existing.cantidad_base !== body.cantidad_base ||
      existing.escala !== body.escala;
    nuevaFuente = cambioValores ? "Manual (usuario)" : existing.fuente || "Manual (usuario)";
  } else {
    nuevaFuente = "Manual (usuario)";
  }

  const cambiosRegistrados: string[] = [];

  if (existing) {
    // Comparar y registrar historial por campo modificado
    const camposAComparar: { campo: string; anterior: any; nuevo: any }[] = [
      { campo: "costo_unitario", anterior: Number(existing.costo_unitario), nuevo: body.costo_unitario },
      { campo: "cantidad_base", anterior: Number(existing.cantidad_base), nuevo: body.cantidad_base },
      { campo: "escala", anterior: existing.escala, nuevo: body.escala },
      { campo: "fuente", anterior: existing.fuente || null, nuevo: nuevaFuente },
      { campo: "producto_id", anterior: existing.producto_id || null, nuevo: body.producto_id || null },
      { campo: "costo_desde_producto", anterior: Boolean(existing.costo_desde_producto), nuevo: Boolean(body.costo_desde_producto) }
    ];

    for (const c of camposAComparar) {
      if (c.anterior !== c.nuevo) {
        cambiosRegistrados.push(c.campo);
        await registrarHistorial(supabase, {
          organizacion_id: orgId,
          tabla: "opcion_costos",
          registro_id: existing.id,
          concepto: conceptoOpcion,
          campo: c.campo,
          valor_anterior: c.anterior !== null && c.anterior !== undefined ? String(c.anterior) : null,
          valor_nuevo: c.nuevo !== null && c.nuevo !== undefined ? String(c.nuevo) : null,
          usuario_id: usuarioId
        });
      }
    }

    const { data: updated, error: errUp } = await supabase
      .from("opcion_costos")
      .update({
        costo_unitario: body.costo_unitario,
        cantidad_base: body.cantidad_base,
        escala: body.escala,
        fuente: nuevaFuente,
        producto_id: body.producto_id || null,
        costo_desde_producto: Boolean(body.costo_desde_producto),
        updated_at: new Date().toISOString()
      })
      .eq("id", existing.id)
      .select()
      .single();

    if (errUp) throw errUp;
    return { opcion_costo: updated, cambios: cambiosRegistrados };
  } else {
    // Insertar nueva fila
    const nuevaFila = {
      organizacion_id: orgId,
      opcion_id: opcionId,
      tipo_modelo: body.tipo_modelo,
      cantidad_base: body.cantidad_base,
      escala: body.escala,
      costo_unitario: body.costo_unitario,
      fuente: nuevaFuente,
      producto_id: body.producto_id || null,
      costo_desde_producto: Boolean(body.costo_desde_producto),
      notas: "import-2r7"
    };

    const { data: created, error: errIns } = await supabase
      .from("opcion_costos")
      .insert([nuevaFila])
      .select()
      .single();

    if (errIns) throw errIns;

    cambiosRegistrados.push("creacion");
    await registrarHistorial(supabase, {
      organizacion_id: orgId,
      tabla: "opcion_costos",
      registro_id: created.id,
      concepto: conceptoOpcion,
      campo: "creacion",
      valor_anterior: null,
      valor_nuevo: `Costo: ${body.costo_unitario}, Cantidad: ${body.cantidad_base}, Escala: ${body.escala}, Fuente: ${nuevaFuente}`,
      usuario_id: usuarioId
    });

    return { opcion_costo: created, cambios: cambiosRegistrados };
  }
}

export async function obtenerCostosModeloYProcesos(
  supabase: any,
  orgId: string,
  modeloId: string
) {
  const { data: modelo, error: errMod } = await supabase
    .from("modelos")
    .select("id, tipo, largo_ft, num_ejes, producto_id, productos(nombre)")
    .eq("id", modeloId)
    .single();

  if (errMod || !modelo) throw new Error("Modelo no encontrado");

  const { data: kits, error: errKits } = await supabase
    .from("costos_modelo")
    .select("id, seccion, concepto, cantidad, costo_unitario, escala, fuente, notas")
    .eq("modelo_id", modeloId)
    .eq("organizacion_id", orgId);
  if (errKits) throw errKits;

  const { data: procesos, error: errProc } = await supabase
    .from("procesos_manufactura")
    .select("id, orden, proceso, subproceso, minutos, tarifa_hora, notas")
    .eq("modelo_id", modeloId)
    .eq("organizacion_id", orgId)
    .order("orden", { ascending: true });
  if (errProc) throw errProc;

  const numEjes = Number(modelo.num_ejes) || 1;
  const largoFt = Number(modelo.largo_ft) || 40;

  let totalKits = 0;
  for (const kit of kits || []) {
    const factor = kit.escala === "por_eje" ? numEjes : kit.escala === "por_largo" ? largoFt / 40 : 1;
    totalKits += Number(kit.cantidad) * Number(kit.costo_unitario) * factor;
  }

  let totalManoObra = 0;
  for (const p of procesos || []) {
    totalManoObra += (Number(p.minutos) * Number(p.tarifa_hora)) / 60;
  }

  return {
    modelo: {
      id: modelo.id,
      tipo: modelo.tipo,
      largo_ft: largoFt,
      num_ejes: numEjes,
      nombre: modelo.productos?.nombre || ""
    },
    costos_modelo: (kits || []).map((k: any) => ({
      ...k,
      cantidad: Number(k.cantidad),
      costo_unitario: Number(k.costo_unitario)
    })),
    procesos_manufactura: (procesos || []).map((p: any) => ({
      ...p,
      minutos: Number(p.minutos),
      tarifa_hora: Number(p.tarifa_hora)
    })),
    totales: {
      total_kits: Math.round(totalKits * 100) / 100,
      total_mano_obra: Math.round(totalManoObra * 100) / 100
    }
  };
}

export async function guardarKitCosto(
  supabase: any,
  orgId: string,
  usuarioId: string,
  modeloId: string,
  kitId: string,
  body: {
    cantidad: number;
    costo_unitario: number;
    concepto?: string;
  }
) {
  if (!body || typeof body !== "object") throw new Error("Cuerpo inválido");
  if (typeof body.cantidad !== "number" || !Number.isFinite(body.cantidad) || body.cantidad <= 0) {
    throw new Error("cantidad debe ser un número finito mayor a 0");
  }
  if (typeof body.costo_unitario !== "number" || !Number.isFinite(body.costo_unitario) || body.costo_unitario < 0) {
    throw new Error("costo_unitario debe ser un número finito mayor o igual a 0");
  }

  const { data: existing, error: errEx } = await supabase
    .from("costos_modelo")
    .select("*")
    .eq("id", kitId)
    .eq("modelo_id", modeloId)
    .eq("organizacion_id", orgId)
    .single();

  if (errEx || !existing) throw new Error("Kit de costos_modelo no encontrado");

  const cambiosRegistrados: string[] = [];
  const nuevoConcepto = body.concepto && body.concepto.trim() !== "" ? body.concepto.trim() : existing.concepto;

  const campos: { campo: string; anterior: any; nuevo: any }[] = [
    { campo: "cantidad", anterior: Number(existing.cantidad), nuevo: body.cantidad },
    { campo: "costo_unitario", anterior: Number(existing.costo_unitario), nuevo: body.costo_unitario },
    { campo: "concepto", anterior: existing.concepto, nuevo: nuevoConcepto }
  ];

  for (const c of campos) {
    if (c.anterior !== c.nuevo) {
      cambiosRegistrados.push(c.campo);
      await registrarHistorial(supabase, {
        organizacion_id: orgId,
        tabla: "costos_modelo",
        registro_id: kitId,
        concepto: existing.concepto,
        campo: c.campo,
        valor_anterior: String(c.anterior),
        valor_nuevo: String(c.nuevo),
        usuario_id: usuarioId
      });
    }
  }

  const { data: updated, error: errUp } = await supabase
    .from("costos_modelo")
    .update({
      cantidad: body.cantidad,
      costo_unitario: body.costo_unitario,
      concepto: nuevoConcepto,
      fuente: "Manual (usuario)",
      updated_at: new Date().toISOString()
    })
    .eq("id", kitId)
    .select()
    .single();

  if (errUp) throw errUp;
  return { kit: updated, cambios: cambiosRegistrados };
}

export async function guardarProcesoManufactura(
  supabase: any,
  orgId: string,
  usuarioId: string,
  procesoId: string,
  body: {
    minutos: number;
    tarifa_hora: number;
  }
) {
  if (!body || typeof body !== "object") throw new Error("Cuerpo inválido");
  if (typeof body.minutos !== "number" || !Number.isFinite(body.minutos) || body.minutos < 0) {
    throw new Error("minutos debe ser un número finito mayor o igual a 0");
  }
  if (typeof body.tarifa_hora !== "number" || !Number.isFinite(body.tarifa_hora) || body.tarifa_hora < 0) {
    throw new Error("tarifa_hora debe ser un número finito mayor o igual a 0");
  }

  const { data: existing, error: errEx } = await supabase
    .from("procesos_manufactura")
    .select("*")
    .eq("id", procesoId)
    .eq("organizacion_id", orgId)
    .single();

  if (errEx || !existing) throw new Error("Proceso de manufactura no encontrado");

  const cambiosRegistrados: string[] = [];
  const campos: { campo: string; anterior: any; nuevo: any }[] = [
    { campo: "minutos", anterior: Number(existing.minutos), nuevo: body.minutos },
    { campo: "tarifa_hora", anterior: Number(existing.tarifa_hora), nuevo: body.tarifa_hora }
  ];

  for (const c of campos) {
    if (c.anterior !== c.nuevo) {
      cambiosRegistrados.push(c.campo);
      await registrarHistorial(supabase, {
        organizacion_id: orgId,
        tabla: "procesos_manufactura",
        registro_id: procesoId,
        concepto: existing.subproceso ? `${existing.proceso} - ${existing.subproceso}` : existing.proceso,
        campo: c.campo,
        valor_anterior: String(c.anterior),
        valor_nuevo: String(c.nuevo),
        usuario_id: usuarioId
      });
    }
  }

  const { data: updated, error: errUp } = await supabase
    .from("procesos_manufactura")
    .update({
      minutos: body.minutos,
      tarifa_hora: body.tarifa_hora,
      updated_at: new Date().toISOString()
    })
    .eq("id", procesoId)
    .select()
    .single();

  if (errUp) throw errUp;
  return { proceso: updated, cambios: cambiosRegistrados };
}

export async function obtenerParametrosCosteo(
  supabase: any,
  orgId: string
) {
  const { data: paramGanancia } = await supabase
    .from("parametros_costeo")
    .select("valor")
    .eq("organizacion_id", orgId)
    .eq("clave", "ganancia_factura")
    .maybeSingle();

  const { data: paramMargen } = await supabase
    .from("parametros_costeo")
    .select("valor")
    .eq("organizacion_id", orgId)
    .eq("clave", "margen_sugerido")
    .maybeSingle();

  return {
    ganancia_factura: paramGanancia?.valor || {
      plataforma: 110000,
      dolly: 65000,
      gondola_servicios_sueldos: 150000
    },
    margen_sugerido: paramMargen?.valor ?? null
  };
}

export async function guardarParametrosCosteo(
  supabase: any,
  orgId: string,
  usuarioId: string,
  body: {
    ganancia_factura?: {
      plataforma?: number;
      dolly?: number;
      gondola_servicios_sueldos?: number;
    };
  }
) {
  if (!body || !body.ganancia_factura || typeof body.ganancia_factura !== "object") {
    throw new Error("ganancia_factura requerida");
  }

  const gf = body.ganancia_factura;
  if (gf.plataforma !== undefined && (typeof gf.plataforma !== "number" || !Number.isFinite(gf.plataforma) || gf.plataforma < 0)) {
    throw new Error("ganancia_factura.plataforma debe ser número >= 0");
  }
  if (gf.dolly !== undefined && (typeof gf.dolly !== "number" || !Number.isFinite(gf.dolly) || gf.dolly < 0)) {
    throw new Error("ganancia_factura.dolly debe ser número >= 0");
  }
  if (gf.gondola_servicios_sueldos !== undefined && (typeof gf.gondola_servicios_sueldos !== "number" || !Number.isFinite(gf.gondola_servicios_sueldos) || gf.gondola_servicios_sueldos < 0)) {
    throw new Error("ganancia_factura.gondola_servicios_sueldos debe ser número >= 0");
  }

  const { data: existing } = await supabase
    .from("parametros_costeo")
    .select("*")
    .eq("organizacion_id", orgId)
    .eq("clave", "ganancia_factura")
    .maybeSingle();

  const valorAnterior = existing?.valor || {};
  const valorNuevo = {
    ...valorAnterior,
    ...(gf.plataforma !== undefined ? { plataforma: gf.plataforma } : {}),
    ...(gf.dolly !== undefined ? { dolly: gf.dolly } : {}),
    ...(gf.gondola_servicios_sueldos !== undefined ? { gondola_servicios_sueldos: gf.gondola_servicios_sueldos } : {})
  };

  await registrarHistorial(supabase, {
    organizacion_id: orgId,
    tabla: "parametros_costeo",
    registro_id: existing?.id || "parametros_ganancia_factura",
    concepto: "Parámetros de ganancia fija",
    campo: "ganancia_factura",
    valor_anterior: JSON.stringify(valorAnterior),
    valor_nuevo: JSON.stringify(valorNuevo),
    usuario_id: usuarioId
  });

  if (existing) {
    const { data: updated, error } = await supabase
      .from("parametros_costeo")
      .update({ valor: valorNuevo, updated_at: new Date().toISOString() })
      .eq("id", existing.id)
      .select()
      .single();
    if (error) throw error;
    return updated;
  } else {
    const { data: created, error } = await supabase
      .from("parametros_costeo")
      .insert([{
        organizacion_id: orgId,
        clave: "ganancia_factura",
        valor: valorNuevo
      }])
      .select()
      .single();
    if (error) throw error;
    return created;
  }
}

export async function obtenerHistorialCostos(
  supabase: any,
  orgId: string,
  limite: number = 100
) {
  const limiteNum = Math.min(Math.max(Number(limite) || 100, 1), 500);

  const { data, error } = await supabase
    .from("costos_historial")
    .select("id, tabla, registro_id, concepto, campo, valor_anterior, valor_nuevo, usuario_id, creado_en")
    .eq("organizacion_id", orgId)
    .order("creado_en", { ascending: false })
    .limit(limiteNum);

  if (error) throw error;
  return data || [];
}
