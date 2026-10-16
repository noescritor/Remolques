/**
 * Utilidades puras para el Catálogo de Costos Administrable (Sub-bloque 2R-7).
 * No contiene React ni dependencias de navegador, permitiendo pruebas unitarias con Deno.
 */

export interface InsigniaFuenteInfo {
  texto: string;
  colorClase: string;
  descripcion: string;
  esPendiente: boolean;
}

/**
 * Formatea un monto numérico a formato de moneda MXN.
 */
export function formatearMoneda(monto: number | null | undefined): string {
  if (monto === null || monto === undefined || isNaN(monto)) return "$0.00";
  return new Intl.NumberFormat("es-MX", {
    style: "currency",
    currency: "MXN",
    minimumFractionDigits: 2,
    maximumFractionDigits: 2
  }).format(monto);
}

/**
 * Determina la insignia de origen (Factura, Tarifario, Supuesto, Producto, Manual, Sin costo)
 * junto con su clase de color y descripción explicativa para tooltip.
 */
export function obtenerInsigniaFuente(
  fuente?: string | null,
  costoDesdeProducto?: boolean
): InsigniaFuenteInfo {
  if (costoDesdeProducto || fuente === "Producto") {
    return {
      texto: "Producto",
      colorClase: "bg-blue-100 text-blue-800 dark:bg-blue-900/40 dark:text-blue-300 border border-blue-300 dark:border-blue-700",
      descripcion: "Ligado a catálogo de Productos (toma el costo del inventario)",
      esPendiente: false
    };
  }

  if (!fuente) {
    return {
      texto: "Sin costo",
      colorClase: "bg-red-100 text-red-800 dark:bg-red-900/40 dark:text-red-300 border border-red-300 dark:border-red-700",
      descripcion: "Opción sin registro de costo asignado en este modelo",
      esPendiente: true
    };
  }

  if (fuente.startsWith("Factura")) {
    return {
      texto: "Factura",
      colorClase: "bg-emerald-100 text-emerald-800 dark:bg-emerald-900/40 dark:text-emerald-300 border border-emerald-300 dark:border-emerald-700",
      descripcion: "Costo verificado de la Factura Leolca",
      esPendiente: false
    };
  }

  if (fuente.startsWith("Manual")) {
    return {
      texto: "Manual",
      colorClase: "bg-violet-100 text-violet-800 dark:bg-violet-900/40 dark:text-violet-300 border border-violet-300 dark:border-violet-700",
      descripcion: "Costo confirmado o capturado manualmente por el usuario",
      esPendiente: false
    };
  }

  if (fuente.startsWith("Tarifario")) {
    return {
      texto: "Tarifario",
      colorClase: "bg-amber-100 text-amber-800 dark:bg-amber-900/40 dark:text-amber-300 border border-amber-300 dark:border-amber-700",
      descripcion: "Costo tomado del tarifario de respaldo; pendiente de confirmación",
      esPendiente: true
    };
  }

  if (fuente.startsWith("Supuesto")) {
    return {
      texto: "Supuesto",
      colorClase: "bg-amber-100 text-amber-800 dark:bg-amber-900/40 dark:text-amber-300 border border-amber-300 dark:border-amber-700",
      descripcion: "Supuesto operativo sin costo adicional; pendiente de confirmación",
      esPendiente: true
    };
  }

  return {
    texto: fuente,
    colorClase: "bg-muted text-muted-foreground border border-border",
    descripcion: fuente,
    esPendiente: false
  };
}

/**
 * Valida los campos de edición de una opción de costo.
 */
export function validarOpcionEdicion(datos: {
  tipo_modelo?: any;
  cantidad_base?: any;
  escala?: any;
  costo_unitario?: any;
}): { valido: boolean; error?: string } {
  if (!datos || typeof datos !== "object") {
    return { valido: false, error: "Datos de opción inválidos" };
  }
  if (!["plataforma", "dolly", "gondola"].includes(String(datos.tipo_modelo))) {
    return { valido: false, error: "Tipo de modelo inválido" };
  }
  if (!["fija", "por_eje", "por_largo"].includes(String(datos.escala))) {
    return { valido: false, error: "Escala inválida (debe ser fija, por_eje o por_largo)" };
  }
  const qty = Number(datos.cantidad_base);
  if (isNaN(qty) || !Number.isFinite(qty) || qty <= 0) {
    return { valido: false, error: "Cantidad base debe ser un número mayor a 0" };
  }
  const cu = Number(datos.costo_unitario);
  if (isNaN(cu) || !Number.isFinite(cu) || cu < 0) {
    return { valido: false, error: "Costo unitario debe ser un número mayor o igual a 0" };
  }
  return { valido: true };
}

/**
 * Valida los campos de edición de un kit de costos_modelo.
 */
export function validarKitEdicion(datos: {
  cantidad?: any;
  costo_unitario?: any;
}): { valido: boolean; error?: string } {
  if (!datos || typeof datos !== "object") {
    return { valido: false, error: "Datos de kit inválidos" };
  }
  const qty = Number(datos.cantidad);
  if (isNaN(qty) || !Number.isFinite(qty) || qty <= 0) {
    return { valido: false, error: "Cantidad debe ser un número mayor a 0" };
  }
  const cu = Number(datos.costo_unitario);
  if (isNaN(cu) || !Number.isFinite(cu) || cu < 0) {
    return { valido: false, error: "Costo unitario debe ser un número mayor o igual a 0" };
  }
  return { valido: true };
}

/**
 * Valida los campos de edición de un proceso de manufactura.
 */
export function validarProcesoEdicion(datos: {
  minutos?: any;
  tarifa_hora?: any;
}): { valido: boolean; error?: string } {
  if (!datos || typeof datos !== "object") {
    return { valido: false, error: "Datos de proceso inválidos" };
  }
  const m = Number(datos.minutos);
  if (isNaN(m) || !Number.isFinite(m) || m < 0) {
    return { valido: false, error: "Minutos debe ser un número mayor o igual a 0" };
  }
  const t = Number(datos.tarifa_hora);
  if (isNaN(t) || !Number.isFinite(t) || t < 0) {
    return { valido: false, error: "Tarifa por hora debe ser un número mayor o igual a 0" };
  }
  return { valido: true };
}

/**
 * Valida la ganancia fija de cotización.
 */
export function validarGananciaMonto(ganancia: any): { valido: boolean; error?: string } {
  const g = Number(ganancia);
  if (isNaN(g) || !Number.isFinite(g) || g < 0) {
    return { valido: false, error: "El monto de ganancia debe ser un número mayor o igual a 0" };
  }
  return { valido: true };
}

/**
 * Filtra opciones del catálogo según búsqueda y flags de pendientes/sin costo.
 */
export function filtrarOpciones(
  opciones: any[],
  filtros: {
    busqueda?: string;
    soloPendientes?: boolean;
    soloSinCosto?: boolean;
  }
): any[] {
  let resultado = opciones || [];

  if (filtros.soloSinCosto) {
    resultado = resultado.filter(o => !o.tiene_costo);
  } else if (filtros.soloPendientes) {
    resultado = resultado.filter(o => {
      const ins = obtenerInsigniaFuente(o.fuente, o.costo_desde_producto);
      return ins.esPendiente;
    });
  }

  if (filtros.busqueda && filtros.busqueda.trim() !== "") {
    const q = filtros.busqueda.trim().toLowerCase();
    resultado = resultado.filter(o =>
      (o.opcion_nombre && o.opcion_nombre.toLowerCase().includes(q)) ||
      (o.opcion_clave && o.opcion_clave.toLowerCase().includes(q)) ||
      (o.grupo_nombre && o.grupo_nombre.toLowerCase().includes(q)) ||
      (o.grupo_clave && o.grupo_clave.toLowerCase().includes(q)) ||
      (o.producto_nombre && o.producto_nombre.toLowerCase().includes(q))
    );
  }

  return resultado;
}

/**
 * Calcula porcentajes y resumen estadístico de cobertura.
 */
export function calcularResumenCobertura(opciones: any[]) {
  const total = opciones.length;
  const conCosto = opciones.filter(o => o.tiene_costo).length;
  const sinCosto = total - conCosto;
  const conReceta = opciones.filter(o => o.receta_piezas_count > 0).length;
  const sinReceta = total - conReceta;

  const pctCosto = total > 0 ? Math.round((conCosto / total) * 100) : 0;
  const pctReceta = total > 0 ? Math.round((conReceta / total) * 100) : 0;

  return {
    total,
    conCosto,
    sinCosto,
    conReceta,
    sinReceta,
    pctCosto,
    pctReceta
  };
}
