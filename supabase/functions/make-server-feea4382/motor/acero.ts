/**
 * Módulo de negocio para Calculadoras y Precios de Acero (Sub-bloque 2R-13)
 * Maneja catálogo de materiales, precios por proveedor e historial de cambios
 * con estricto filtrado por organizacion_id y lista blanca de campos.
 */

import {
  determinarTipoMaterial,
  normalizarNombreMaterial,
  parsearMedidaLamina,
  TipoMaterialAcero,
} from "../../../../src/app/utils/aceroCalc.ts";

export interface AceroMaterialItem {
  id: string;
  organizacion_id: string;
  nombre: string;
  tipo: TipoMaterialAcero;
  ancho_ft: number | null;
  largo_ft: number | null;
  activo: boolean;
  notas: string | null;
  created_at?: string;
  updated_at?: string;
  precios?: Record<string, {
    id: string;
    precio: number;
    incluye_iva: boolean;
    fuente: string | null;
    actualizado_el: string;
  }>;
}

export interface AceroPrecioItem {
  id: string;
  organizacion_id: string;
  material_id: string;
  proveedor: string;
  precio: number;
  incluye_iva: boolean;
  fuente: string | null;
  actualizado_el: string;
}

/**
 * Consulta el catálogo de materiales y sus precios vigentes por proveedor.
 */
export async function obtenerCatalogoAcero(
  client: any,
  orgId: string
): Promise<{ materiales: AceroMaterialItem[]; proveedores: string[] }> {
  // 1. Obtener materiales de la organización
  const { data: materialesRaw, error: matErr } = await client
    .from("acero_materiales")
    .select("*")
    .eq("organizacion_id", orgId)
    .order("tipo", { ascending: true })
    .order("nombre", { ascending: true });

  if (matErr) throw matErr;

  // 2. Obtener precios de la organización
  const { data: preciosRaw, error: precErr } = await client
    .from("acero_precios")
    .select("*")
    .eq("organizacion_id", orgId);

  if (precErr) throw precErr;

  const proveedoresSet = new Set<string>();
  const preciosPorMaterial = new Map<string, Record<string, any>>();

  for (const p of preciosRaw || []) {
    if (p.proveedor) {
      proveedoresSet.add(p.proveedor);
    }
    if (!preciosPorMaterial.has(p.material_id)) {
      preciosPorMaterial.set(p.material_id, {});
    }
    preciosPorMaterial.get(p.material_id)![p.proveedor] = {
      id: p.id,
      precio: Number(p.precio),
      incluye_iva: Boolean(p.incluye_iva),
      fuente: p.fuente,
      actualizado_el: p.actualizado_el || p.updated_at,
    };
  }

  const materiales: AceroMaterialItem[] = (materialesRaw || []).map((m: any) => ({
    id: m.id,
    organizacion_id: m.organizacion_id,
    nombre: m.nombre,
    tipo: m.tipo,
    ancho_ft: m.ancho_ft !== null ? Number(m.ancho_ft) : null,
    largo_ft: m.largo_ft !== null ? Number(m.largo_ft) : null,
    activo: Boolean(m.activo),
    notas: m.notas,
    created_at: m.created_at,
    updated_at: m.updated_at,
    precios: preciosPorMaterial.get(m.id) || {},
  }));

  // Ordenar proveedores alfabéticamente
  const proveedores = Array.from(proveedoresSet).sort();

  return { materiales, proveedores };
}

/**
 * Guarda o actualiza un precio de acero por proveedor con historial.
 * Lista blanca de campos: { material_id, proveedor, precio, incluye_iva?, fuente? }
 */
export async function guardarPrecioAcero(
  client: any,
  orgId: string,
  usuarioId: string | null,
  rawPayload: any
): Promise<any> {
  if (!rawPayload || typeof rawPayload !== "object") {
    const err: any = new Error("Payload inválido");
    err.status = 400;
    throw err;
  }

  const materialId = rawPayload.material_id;
  if (!materialId || typeof materialId !== "string") {
    const err: any = new Error("material_id es requerido");
    err.status = 400;
    throw err;
  }

  // Verificar que el material pertenece a la organización
  const { data: material, error: matErr } = await client
    .from("acero_materiales")
    .select("id, nombre")
    .eq("id", materialId)
    .eq("organizacion_id", orgId)
    .maybeSingle();

  if (matErr) throw matErr;
  if (!material) {
    const err: any = new Error("Material no encontrado");
    err.status = 404;
    throw err;
  }

  const proveedor = (rawPayload.proveedor || "").trim();
  if (!proveedor) {
    const err: any = new Error("proveedor es requerido");
    err.status = 400;
    throw err;
  }

  const precio = Number(rawPayload.precio);
  if (!Number.isFinite(precio) || precio <= 0) {
    const err: any = new Error("precio debe ser un número mayor a cero");
    err.status = 400;
    throw err;
  }

  const incluyeIva = rawPayload.incluye_iva !== undefined ? Boolean(rawPayload.incluye_iva) : true;
  const fuente = rawPayload.fuente ? String(rawPayload.fuente).slice(0, 200) : "Manual";

  // Consultar precio anterior
  const { data: precioAnterior, error: prevErr } = await client
    .from("acero_precios")
    .select("id, precio")
    .eq("material_id", materialId)
    .eq("proveedor", proveedor)
    .eq("organizacion_id", orgId)
    .maybeSingle();

  if (prevErr) throw prevErr;

  const precioPrevioNum = precioAnterior ? Number(precioAnterior.precio) : null;
  const precioCambio = precioPrevioNum === null || Math.abs(precioPrevioNum - precio) > 0.0001;

  // Si cambió el precio, registrar en historial
  if (precioCambio) {
    try {
      await client.from("acero_precios_historial").insert({
        organizacion_id: orgId,
        material_id: materialId,
        proveedor,
        precio_anterior: precioPrevioNum,
        precio_nuevo: precio,
        usuario_id: usuarioId,
      });
    } catch (histErr) {
      console.error("[acero] Error registrando historial de precio:", histErr);
    }
  }

  // Upsert en acero_precios
  const ahora = new Date().toISOString();
  const upsertData: any = {
    organizacion_id: orgId,
    material_id: materialId,
    proveedor,
    precio,
    incluye_iva: incluyeIva,
    fuente,
    actualizado_el: ahora,
    updated_at: ahora,
  };

  const { data: guardado, error: saveErr } = await client
    .from("acero_precios")
    .upsert(upsertData, { onConflict: "material_id,proveedor" })
    .select()
    .single();

  if (saveErr) throw saveErr;
  return guardado;
}

/**
 * Crea un nuevo material de acero.
 * Lista blanca de campos: { nombre, tipo?, notas? }
 * (ancho_ft y largo_ft se derivan automáticamente del nombre)
 */
export async function crearMaterialAcero(
  client: any,
  orgId: string,
  rawPayload: any
): Promise<any> {
  if (!rawPayload || typeof rawPayload !== "object") {
    const err: any = new Error("Payload inválido");
    err.status = 400;
    throw err;
  }

  const rawNombre = (rawPayload.nombre || "").trim();
  if (!rawNombre) {
    const err: any = new Error("El nombre del material es requerido");
    err.status = 400;
    throw err;
  }

  const nombre = normalizarNombreMaterial(rawNombre);

  // Validar unicidad en la organización
  const { data: existente, error: checkErr } = await client
    .from("acero_materiales")
    .select("id")
    .eq("organizacion_id", orgId)
    .ilike("nombre", nombre)
    .maybeSingle();

  if (checkErr) throw checkErr;
  if (existente) {
    const err: any = new Error("Ya existe un material con este nombre");
    err.status = 409;
    throw err;
  }

  // Derivar tipo
  let tipo: TipoMaterialAcero;
  const tiposValidos = ["placa", "lamina", "solera", "canal", "ptr", "tubo", "angulo", "redondo"];
  if (rawPayload.tipo && tiposValidos.includes(String(rawPayload.tipo).toLowerCase())) {
    tipo = String(rawPayload.tipo).toLowerCase() as TipoMaterialAcero;
  } else {
    try {
      tipo = determinarTipoMaterial(nombre);
    } catch (_e) {
      tipo = "placa";
    }
  }

  // Derivar medidas si aplica
  const medida = parsearMedidaLamina(nombre);
  const anchoFt = medida ? medida.anchoFt : null;
  const largoFt = medida ? medida.largoFt : null;
  const notas = rawPayload.notas ? String(rawPayload.notas).slice(0, 500) : null;

  const insertData = {
    organizacion_id: orgId,
    nombre,
    tipo,
    ancho_ft: anchoFt,
    largo_ft: largoFt,
    activo: true,
    notas,
  };

  const { data: creado, error: insErr } = await client
    .from("acero_materiales")
    .insert(insertData)
    .select()
    .single();

  if (insErr) throw insErr;
  return creado;
}

/**
 * Actualiza un material de acero existente.
 * Lista blanca de campos: { nombre?, notas?, activo? }
 */
export async function actualizarMaterialAcero(
  client: any,
  orgId: string,
  materialId: string,
  rawPayload: any
): Promise<any> {
  if (!rawPayload || typeof rawPayload !== "object") {
    const err: any = new Error("Payload inválido");
    err.status = 400;
    throw err;
  }

  // Verificar existencia en la organización
  const { data: actual, error: getErr } = await client
    .from("acero_materiales")
    .select("*")
    .eq("id", materialId)
    .eq("organizacion_id", orgId)
    .maybeSingle();

  if (getErr) throw getErr;
  if (!actual) {
    const err: any = new Error("Material no encontrado");
    err.status = 404;
    throw err;
  }

  const updates: any = {
    updated_at: new Date().toISOString(),
  };

  if (rawPayload.nombre !== undefined) {
    const rawNombre = String(rawPayload.nombre).trim();
    if (!rawNombre) {
      const err: any = new Error("El nombre no puede estar vacío");
      err.status = 400;
      throw err;
    }
    const nombre = normalizarNombreMaterial(rawNombre);

    // Verificar si colisiona con otro material
    const { data: colision, error: colErr } = await client
      .from("acero_materiales")
      .select("id")
      .eq("organizacion_id", orgId)
      .ilike("nombre", nombre)
      .neq("id", materialId)
      .maybeSingle();

    if (colErr) throw colErr;
    if (colision) {
      const err: any = new Error("Ya existe un material con este nombre");
      err.status = 409;
      throw err;
    }

    updates.nombre = nombre;
    try {
      updates.tipo = determinarTipoMaterial(nombre);
    } catch (_e) {
      // conservar tipo actual
    }
    const medida = parsearMedidaLamina(nombre);
    updates.ancho_ft = medida ? medida.anchoFt : null;
    updates.largo_ft = medida ? medida.largoFt : null;
  }

  if (rawPayload.activo !== undefined) {
    updates.activo = Boolean(rawPayload.activo);
  }

  if (rawPayload.notas !== undefined) {
    updates.notas = rawPayload.notas ? String(rawPayload.notas).slice(0, 500) : null;
  }

  const { data: actualizado, error: updErr } = await client
    .from("acero_materiales")
    .update(updates)
    .eq("id", materialId)
    .eq("organizacion_id", orgId)
    .select()
    .single();

  if (updErr) throw updErr;
  return actualizado;
}

/**
 * Elimina un precio específico por proveedor.
 * (No se eliminan materiales; solo se desactivan vía activo = false)
 */
export async function eliminarPrecioAcero(
  client: any,
  orgId: string,
  usuarioId: string | null,
  materialId: string,
  proveedor: string
): Promise<{ ok: boolean; deleted: boolean }> {
  // Verificar material en la organización
  const { data: material, error: matErr } = await client
    .from("acero_materiales")
    .select("id")
    .eq("id", materialId)
    .eq("organizacion_id", orgId)
    .maybeSingle();

  if (matErr) throw matErr;
  if (!material) {
    const err: any = new Error("Material no encontrado");
    err.status = 404;
    throw err;
  }

  // Buscar precio
  const { data: precioExistente, error: getErr } = await client
    .from("acero_precios")
    .select("id, precio")
    .eq("material_id", materialId)
    .eq("proveedor", proveedor)
    .eq("organizacion_id", orgId)
    .maybeSingle();

  if (getErr) throw getErr;
  if (!precioExistente) {
    return { ok: true, deleted: false };
  }

  // Registrar historial de eliminación
  try {
    await client.from("acero_precios_historial").insert({
      organizacion_id: orgId,
      material_id: materialId,
      proveedor,
      precio_anterior: Number(precioExistente.precio),
      precio_nuevo: 0,
      usuario_id: usuarioId,
    });
  } catch (histErr) {
    console.error("[acero] Error registrando historial en delete:", histErr);
  }

  const { error: delErr } = await client
    .from("acero_precios")
    .delete()
    .eq("id", precioExistente.id)
    .eq("organizacion_id", orgId);

  if (delErr) throw delErr;
  return { ok: true, deleted: true };
}

/**
 * Consulta el historial de cambios de precios de acero.
 */
export async function obtenerHistorialAcero(
  client: any,
  orgId: string,
  materialId?: string,
  limite: number = 50
): Promise<any[]> {
  let query = client
    .from("acero_precios_historial")
    .select("*, material:acero_materiales(nombre, tipo)")
    .eq("organizacion_id", orgId)
    .order("creado_el", { ascending: false })
    .limit(limite);

  if (materialId) {
    query = query.eq("material_id", materialId);
  }

  const { data, error } = await query;
  if (error) throw error;
  return data || [];
}
