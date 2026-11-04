// @ts-nocheck
/**
 * Motor para gestión y consulta del catálogo de productos y cotizador
 * Sub-bloque T1 (Turno de noche 2026-11-02) / Integración T1 + T6
 */

export interface FiltrosProductos {
  q?: string;
  busqueda?: string;
  tipo?: string;
  tipo_item?: string;
  categoria?: string;
  sinCosto?: boolean | string;
  page?: number;
  limit?: number;
  paginado?: boolean | string;
}

/**
 * Sanitiza una cadena de búsqueda para PostgREST eliminando caracteres que
 * romperían la sintaxis del parser lógico de PostgREST (paréntesis y comas).
 */
export function sanitizarBusquedaPostgrest(texto: string): string {
  if (!texto) return "";
  return texto.replace(/[(),]/g, " ").replace(/\s+/g, " ").trim();
}

/**
 * Helper interno para aplicar filtros comunes (orgId, tipo, categoría, costo, búsqueda)
 * a cualquier builder de consulta de PostgREST sobre `productos`.
 */
function aplicarFiltrosComunes(query: any, orgId?: string, filtros: FiltrosProductos = {}) {
  if (orgId) {
    query = query.eq("organizacion_id", orgId);
  }

  const tipoFinal = filtros.tipo || filtros.tipo_item;
  if (tipoFinal) {
    query = query.eq("tipo_item", tipoFinal);
  }

  if (filtros.categoria && filtros.categoria !== "todas") {
    if (filtros.categoria === "sin_categoria" || filtros.categoria === "ninguna") {
      query = query.is("categoria_id", null);
    } else {
      query = query.eq("categoria_id", filtros.categoria);
    }
  }

  if (filtros.sinCosto === true || filtros.sinCosto === "1" || filtros.sinCosto === "true") {
    query = query.or("costo.is.null,costo.lte.0");
  }

  const textoBusqueda = filtros.q || filtros.busqueda;
  if (textoBusqueda && textoBusqueda.trim()) {
    const qSanitized = sanitizarBusquedaPostgrest(textoBusqueda);
    if (qSanitized) {
      query = query.or(`nombre.ilike.%${qSanitized}%,id.ilike.%${qSanitized}%`);
    }
  }

  return query;
}

/**
 * Consulta la tabla de productos con soporte de:
 * 1. Paginación explícita con count exacto (UI de catálogo de productos).
 * 2. Consulta rápida con límite (autocomplete de materiales en editor de recetas).
 * 3. Consulta completa sin truncado de 1000 filas por lotes (retrocompatibilidad).
 */
export async function listarProductosPaginados(
  supabase: any,
  orgId?: string,
  filtros: FiltrosProductos = {}
) {
  const esPaginado =
    filtros.paginado === true ||
    filtros.paginado === "1" ||
    filtros.paginado === "true" ||
    (filtros.page !== undefined && filtros.paginado !== false && filtros.paginado !== "false");

  // 1. Modo paginación explícita para la UI (devuelve objeto con metadata)
  if (esPaginado) {
    const page = Math.max(1, Number(filtros.page) || 1);
    const limit = Math.max(1, Math.min(1000, Number(filtros.limit) || 50));
    const offset = (page - 1) * limit;

    let query = supabase.from("productos").select("*", { count: "exact" });
    query = aplicarFiltrosComunes(query, orgId, filtros);

    query = query.order("nombre", { ascending: true }).order("id", { ascending: true });
    if (typeof query.range === "function") {
      query = query.range(offset, offset + limit - 1);
    }

    const { data, count, error } = await query;
    if (error) {
      throw new Error(`Error al listar productos paginados: ${error.message}`);
    }

    const rows = data || [];
    const total = count ?? rows.length;
    const truncado = total > offset + limit;

    return {
      productos: rows,
      total,
      page,
      limit,
      truncado,
    };
  }

  // 2. Modo sin paginado con limit (usado por autocomplete / T6, recorta el resultado devolviendo arreglo)
  if (filtros.limit !== undefined && filtros.limit !== null && !isNaN(Number(filtros.limit))) {
    const lim = Math.max(1, Number(filtros.limit));
    let query = supabase.from("productos").select("*");
    query = aplicarFiltrosComunes(query, orgId, filtros);
    query = query.order("nombre", { ascending: true }).order("id", { ascending: true });
    if (typeof query.limit === "function") {
      query = query.limit(lim);
    }

    const { data, error } = await query;
    if (error) {
      throw new Error(`Error al listar productos con limit: ${error.message}`);
    }

    return data || [];
  }

  // 3. Modo retrocompatible: trae TODOS los productos mediante bucle .range() en lotes de 1000
  const BATCH = 1000;
  let allProducts: any[] = [];
  let offset = 0;

  while (true) {
    let query = supabase.from("productos").select("*");
    query = aplicarFiltrosComunes(query, orgId, filtros);

    query = query.order("nombre", { ascending: true }).order("id", { ascending: true });
    if (typeof query.range === "function") {
      query = query.range(offset, offset + BATCH - 1);
    }

    const { data, error } = await query;
    if (error) {
      throw new Error(`Error al listar todos los productos: ${error.message}`);
    }

    const rows = data || [];
    allProducts.push(...rows);

    if (rows.length < BATCH) {
      break;
    }
    offset += BATCH;
  }

  return allProducts;
}

/**
 * Consulta unificada del Catálogo del Cotizador (aceros y opciones de configuración)
 * para visualización en pestaña de solo lectura sin duplicar datos en productos.
 * Utiliza el esquema real de acero_materiales y acero_precios (precio, actualizado_el, proveedor, incluye_iva).
 */
export async function obtenerCatalogoCotizador(supabase: any, orgId: string) {
  // 1. Aceros materiales con sus precios históricos/vigentes
  const { data: acerosRaw, error: errAceros } = await supabase
    .from("acero_materiales")
    .select(`
      id, organizacion_id, nombre, tipo, ancho_ft, largo_ft, activo, notas,
      precios:acero_precios(id, proveedor, precio, incluye_iva, fuente, actualizado_el, notas)
    `)
    .eq("organizacion_id", orgId)
    .order("nombre", { ascending: true })
    .order("id", { ascending: true });

  if (errAceros) {
    throw new Error(`Error consultando acero_materiales: ${errAceros.message}`);
  }

  const aceros = (acerosRaw || []).map((a: any) => {
    // REGLA DETERMINISTA DE RESOLUCIÓN DE PRECIOS:
    // 1. Menor precio válido (> 0) primero (costo más competitivo de referencia)
    // 2. Desempate alfabético estricto por proveedor (A-Z) para evitar azar cuando coinciden precios y actualizado_el
    // 3. Desempate secundario por fecha de actualización más reciente
    const precios = (a.precios || []).slice().sort((p1: any, p2: any) => {
      const pr1 = p1.precio !== null && p1.precio !== undefined ? Number(p1.precio) : Infinity;
      const pr2 = p2.precio !== null && p2.precio !== undefined ? Number(p2.precio) : Infinity;
      if (pr1 !== pr2) {
        return pr1 - pr2;
      }
      const prov1 = String(p1.proveedor || "").trim().toLowerCase();
      const prov2 = String(p2.proveedor || "").trim().toLowerCase();
      if (prov1 !== prov2) {
        return prov1.localeCompare(prov2);
      }
      return String(p2.actualizado_el || "").localeCompare(String(p1.actualizado_el || ""));
    });

    const precioVigente =
      precios.length > 0 && precios[0].precio !== null && precios[0].precio !== undefined && Number(precios[0].precio) !== Infinity
        ? Number(precios[0].precio)
        : null;
    const proveedorVigente = precios.length > 0 ? precios[0].proveedor : null;
    const incluyeIva = precios.length > 0 ? Boolean(precios[0].incluye_iva) : null;
    const fuente = precios.length > 0 ? (precios[0].fuente || "manual") : "sin_precio";

    // Unidad realista: no forzar 'kg' a perfiles vendidos por pieza o tramo comercial
    let unidad = "pz / tramo";
    if (a.ancho_ft && a.largo_ft) {
      unidad = "placa";
    } else if (/6\.10m|12\.20m|tramo|tubo|ptr|canal|angulo|solera|redondo|cuadrado/i.test(a.nombre || "")) {
      unidad = "tramo";
    }

    const dimensionesTexto =
      `${a.ancho_ft ? `${a.ancho_ft} ft` : ''} ${a.largo_ft ? `x ${a.largo_ft} ft` : ''}`.trim() || null;

    return {
      id: a.id,
      tipo_origen: "acero",
      clave: a.id,
      nombre: a.nombre,
      tipo: a.tipo || "acero",
      tipo_material: a.tipo || "acero",
      dimensiones: dimensionesTexto,
      dimensiones_texto: dimensionesTexto,
      ancho_ft: a.ancho_ft,
      largo_ft: a.largo_ft,
      unidad,
      precio: precioVigente,
      proveedor: proveedorVigente,
      incluye_iva: incluyeIva,
      total_proveedores: precios.length,
      precios_todos: precios.map((p: any) => ({
        id: p.id,
        proveedor: p.proveedor,
        precio: p.precio !== null && p.precio !== undefined ? Number(p.precio) : null,
        incluye_iva: p.incluye_iva,
        fuente: p.fuente,
        actualizado_el: p.actualizado_el,
        notas: p.notas || null,
      })),
      fuente,
      activo: a.activo !== false,
      notas: a.notas || null,
    };
  });

  // 2. Opciones de configuración con su grupo y costos vigentes
  const { data: opcionesRaw, error: errOpciones } = await supabase
    .from("opciones_configuracion")
    .select(`
      id, organizacion_id, grupo_id, clave, nombre, precio_venta, activo, aliases,
      grupo:grupos_configuracion(id, clave, nombre),
      costos:opcion_costos(id, tipo_modelo, costo_unitario, escala, fuente)
    `)
    .eq("organizacion_id", orgId)
    .order("nombre", { ascending: true })
    .order("id", { ascending: true });

  if (errOpciones) {
    throw new Error(`Error consultando opciones_configuracion: ${errOpciones.message}`);
  }

  const opciones = (opcionesRaw || []).map((o: any) => {
    const costos = o.costos || [];
    // Tomar costo de plataforma o el primero disponible
    const costoPlat = costos.find((c: any) => c.tipo_modelo === "plataforma") || costos[0];
    const costoUnit = costoPlat && costoPlat.costo_unitario !== null && costoPlat.costo_unitario !== undefined
      ? Number(costoPlat.costo_unitario)
      : null;
    const fuente = costoPlat ? costoPlat.fuente : "sin_costo";
    const escala = costoPlat ? costoPlat.escala : "fija";

    return {
      id: o.id,
      tipo_origen: "opcion_cotizador",
      grupo: o.grupo?.nombre || o.grupo?.clave || "General",
      grupo_nombre: o.grupo?.nombre || o.grupo?.clave || "General",
      grupo_clave: o.grupo?.clave || "General",
      clave: o.clave,
      nombre: o.nombre,
      precio_venta: o.precio_venta !== null && o.precio_venta !== undefined ? Number(o.precio_venta) : null,
      costo: costoUnit,
      costo_referencia: costoUnit,
      fuente,
      escala,
      activo: o.activo !== false,
      aliases: o.aliases || [],
    };
  });

  return {
    aceros,
    opciones,
    totalAceros: aceros.length,
    total_aceros: aceros.length,
    totalOpciones: opciones.length,
    total_opciones: opciones.length,
  };
}
