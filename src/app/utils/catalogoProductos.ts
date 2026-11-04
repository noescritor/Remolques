/**
 * Utilidades puras para el catálogo de productos y servicios
 * Sub-bloque T1 (Turno de noche 2026-11-02)
 */

export interface ProductoSimple {
  id: string;
  nombre: string;
  descripcion?: string | null;
  unidad?: string | null;
  costo?: number | null;
  precio_unitario?: number | null;
  categoria_id?: string | null;
  tipo?: string;
  tipo_item?: string;
}

export interface CategoriaSimple {
  id: string;
  nombre: string;
  color?: string | null;
  orden?: number;
}

export interface CategoriaConConteo {
  id: string;
  nombre: string;
  color: string;
  count: number;
}

export interface ResumenCategorias {
  todasCount: number;
  sinCategoriaCount: number;
  sinCostoCount: number;
  categoriasConDatos: CategoriaConConteo[];
}

/**
 * Determina si una pieza o producto no tiene costo cargado (es nulo, indefinido, NaN o 0).
 */
export function esProductoSinCosto(producto: ProductoSimple | null | undefined): boolean {
  if (!producto) return true;
  if (producto.costo === null || producto.costo === undefined) return true;
  const num = Number(producto.costo);
  if (isNaN(num) || num <= 0) return true;
  return false;
}

/**
 * Calcula conteos de productos para las pestañas de categorías, la pestaña "Sin categoría"
 * y el contador de ítems sin costo cargado.
 * Solo incluye en `categoriasConDatos` aquellas categorías que realmente tienen productos asociados.
 */
export function calcularCategoriasConConteo(
  productos: ProductoSimple[],
  categorias: CategoriaSimple[] = []
): ResumenCategorias {
  const prods = Array.isArray(productos) ? productos.filter(Boolean) : [];
  const todasCount = prods.length;

  let sinCategoriaCount = 0;
  let sinCostoCount = 0;
  const conteosPorCat = new Map<string, number>();

  for (const p of prods) {
    if (esProductoSinCosto(p)) {
      sinCostoCount++;
    }

    const cId = p.categoria_id;
    if (!cId || cId === "ninguna") {
      sinCategoriaCount++;
    } else {
      conteosPorCat.set(cId, (conteosPorCat.get(cId) || 0) + 1);
    }
  }

  // Filtrar categorías que realmente tienen productos asignados
  const categoriasConDatos: CategoriaConConteo[] = [];
  for (const c of categorias || []) {
    const count = conteosPorCat.get(c.id) || 0;
    if (count > 0) {
      categoriasConDatos.push({
        id: c.id,
        nombre: c.nombre,
        color: c.color || "#3b82f6",
        count,
      });
    }
  }

  return {
    todasCount,
    sinCategoriaCount,
    sinCostoCount,
    categoriasConDatos,
  };
}

/**
 * Filtra la lista de productos por texto de búsqueda, categoría activa (incluyendo 'sin_categoria')
 * y el selector booleano de "solo sin costo cargado".
 */
export function filtrarProductosCatalogo<T extends ProductoSimple>(
  productos: T[],
  opciones: {
    busqueda?: string;
    categoriaActiva?: string;
    soloSinCosto?: boolean;
  } = {}
): T[] {
  const prods = Array.isArray(productos) ? productos.filter(Boolean) : [];
  const term = (opciones.busqueda || "").trim().toLowerCase();
  const catActiva = opciones.categoriaActiva || "todas";
  const soloSinCosto = !!opciones.soloSinCosto;

  return prods.filter((p) => {
    // 1. Filtro por costo nulo o cero
    if (soloSinCosto && !esProductoSinCosto(p)) {
      return false;
    }

    // 2. Filtro por categoría
    if (catActiva !== "todas") {
      if (catActiva === "sin_categoria" || catActiva === "ninguna") {
        if (p.categoria_id && p.categoria_id !== "ninguna") {
          return false;
        }
      } else {
        if (p.categoria_id !== catActiva) {
          return false;
        }
      }
    }

    // 3. Filtro por búsqueda de texto
    if (term) {
      const nomMatch = (p.nombre || "").toLowerCase().includes(term);
      const descMatch = (p.descripcion || "").toLowerCase().includes(term);
      const unidadMatch = (p.unidad || "").toLowerCase().includes(term);
      if (!nomMatch && !descMatch && !unidadMatch) {
        return false;
      }
    }

    return true;
  });
}
