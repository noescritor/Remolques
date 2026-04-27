import { ItemCotizacion, Cotizacion, Producto, ServicioPlan } from '../types';

export function calcularItemCotizacion(
  cantidad: number,
  precio_unitario: number,
  tasa_iva: number = 0.16
): { iva_item: number; total_item: number } {
  const total_item = cantidad * precio_unitario;
  const iva_item = total_item * tasa_iva;
  
  return {
    iva_item: Math.round(iva_item * 100) / 100,
    total_item: Math.round(total_item * 100) / 100
  };
}

export function calcularTotalesCotizacion(
  itemsOrCotizacion: ItemCotizacion[] | Cotizacion | any, 
  tasa_iva: number = 0.16
): {
  subtotal: number;
  iva: number;
  total: number;
} {
  // Si se pasa una cotización, extraer los items y verificar si es con factura
  let items: any[] = [];
  let conFactura = true; // Por defecto con factura
  
  if (Array.isArray(itemsOrCotizacion)) {
    items = itemsOrCotizacion;
  } else if (itemsOrCotizacion?.items && Array.isArray(itemsOrCotizacion.items)) {
    items = itemsOrCotizacion.items;
    conFactura = itemsOrCotizacion.con_factura !== false; // Si no está definido, por defecto true
  } else {
    // Si no hay items válidos, retornar totales en cero
    return {
      subtotal: 0,
      iva: 0,
      total: 0
    };
  }

  // Calcular totales usando diferentes estructuras de datos
  const subtotal = items.reduce((sum, item) => {
    // Manejar diferentes estructuras de items
    let total = 0;
    
    if (item.total_item !== undefined) {
      total = item.total_item;
    } else if (item.total !== undefined) {
      total = item.total;
    } else if (item.cantidad !== undefined && item.precio_unitario !== undefined) {
      total = item.cantidad * item.precio_unitario;
    }
    
    return sum + (total || 0);
  }, 0);
  
  // Si es sin factura, el IVA es 0 y el total es igual al subtotal
  const iva = conFactura ? subtotal * tasa_iva : 0;
  const total = subtotal + iva;

  return {
    subtotal: Math.round(subtotal * 100) / 100,
    iva: Math.round(iva * 100) / 100,
    total: Math.round(total * 100) / 100
  };
}

export function formatearMoneda(amount: number): string {
  return new Intl.NumberFormat('es-MX', {
    style: 'currency',
    currency: 'MXN',
    minimumFractionDigits: 2,
    maximumFractionDigits: 2
  }).format(amount);
}

export function formatearFecha(fecha: string): string {
  return new Date(fecha).toLocaleDateString('es-MX', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric'
  });
}

export function generarFolio(prefijo: string, numero: number): string {
  const year = new Date().getFullYear();
  const numeroFormateado = numero.toString().padStart(5, '0');
  return `${prefijo}${year}-${numeroFormateado}`;
}

// NUEVAS FUNCIONES PARA ANÁLISIS DE COSTOS Y UTILIDADES

export function calcularCostosDirectosItem(
  cantidad: number,
  costo_unitario: number
): number {
  const costoTotal = cantidad * costo_unitario;
  return Math.round(costoTotal * 100) / 100;
}

export function calcularUtilidadItem(
  cantidad: number,
  precio_unitario: number,
  costo_unitario: number
): {
  ingreso: number;
  costo: number;
  utilidad: number;
  margen: number;
} {
  const ingreso = cantidad * precio_unitario;
  const costo = cantidad * costo_unitario;
  const utilidad = ingreso - costo;
  const margen = ingreso > 0 ? (utilidad / ingreso) * 100 : 0;

  return {
    ingreso: Math.round(ingreso * 100) / 100,
    costo: Math.round(costo * 100) / 100,
    utilidad: Math.round(utilidad * 100) / 100,
    margen: Math.round(margen * 100) / 100
  };
}

export function calcularTotalCostosIndirectos(costos: any = {}): number {
  const {
    mano_obra = 0,
    insumos_dtf = 0,
    empaque = 0,
    mermas = 0,
    envio = 0,
    otros = 0
  } = costos;
  
  return Math.round((mano_obra + insumos_dtf + empaque + mermas + envio + otros) * 100) / 100;
}

export function calcularTotalComisiones(
  subtotal: number,
  comisiones: any = {}
): number {
  const { porcentaje = 0, fijo = 0 } = comisiones;
  const comisionPorcentaje = subtotal * (porcentaje / 100);
  return Math.round((comisionPorcentaje + fijo) * 100) / 100;
}

export function calcularAnalisisCompleto(
  cotizacion: any,
  productos: any[] = []
): {
  ingresoSinIva: number;
  costosDirectos: number;
  costosIndirectos: number;
  comisiones: number;
  utilidadBruta: number;
  margenBruto: number;
  detalleItems: any[];
} {
  const items = cotizacion.items || [];
  const { subtotal } = calcularTotalesCotizacion(cotizacion);
  
  // Calcular costos directos y detalles por ítem
  let costosDirectosTotales = 0;
  const detalleItems = items.map((item: any) => {
    // Buscar el producto para obtener el costo por defecto
    const producto = productos.find(p => p.nombre === item.descripcion);
    const costoUnitario = item.costo_unitario ?? producto?.costo ?? 0;
    
    const analisisItem = calcularUtilidadItem(
      item.cantidad,
      item.precio_unitario,
      costoUnitario
    );
    
    costosDirectosTotales += analisisItem.costo;
    
    return {
      ...item,
      costo_unitario: costoUnitario,
      ...analisisItem
    };
  });
  
  // Calcular costos indirectos y comisiones
  const costosIndirectos = calcularTotalCostosIndirectos(cotizacion.costos_indirectos);
  const comisiones = calcularTotalComisiones(subtotal, cotizacion.comisiones_pago);
  
  // Calcular utilidad bruta
  const utilidadBruta = subtotal - costosDirectosTotales - costosIndirectos - comisiones;
  const margenBruto = subtotal > 0 ? (utilidadBruta / subtotal) * 100 : 0;
  
  return {
    ingresoSinIva: subtotal,
    costosDirectos: Math.round(costosDirectosTotales * 100) / 100,
    costosIndirectos,
    comisiones,
    utilidadBruta: Math.round(utilidadBruta * 100) / 100,
    margenBruto: Math.round(margenBruto * 100) / 100,
    detalleItems
  };
}

export function calcularPrecioObjetivo(
  costo_unitario: number,
  margen_deseado: number
): number {
  // Margen deseado es un porcentaje (ej: 30 para 30%)
  // Precio = Costo / (1 - Margen/100)
  const precio = costo_unitario / (1 - (margen_deseado / 100));
  return Math.round(precio * 100) / 100;
}

// NUEVAS FUNCIONES PARA SERVICIOS

const round2 = (n: number) => Math.round(n * 100) / 100;

export function totalItemServicio(
  item: ItemCotizacion,
  producto: Producto,
  tasaIva: number
): {
  subtotal: number;
  iva: number;
  total: number;
  costoTotal: number;
} {
  const plan = producto.servicio!;
  const meses = Math.max(1, item.meses_cobrados ?? 1);
  const porAsiento = plan.por_asiento ?? false;
  const extra = Math.max(0, item.asientos_extra ?? 0);

  const setup = (plan.modo === 'unico' || plan.modo === 'hibrido') && (item.incluir_setup ?? true)
    ? (plan.setup_precio ?? 0) : 0;

  const baseRec = (plan.modo === 'suscripcion' || plan.modo === 'hibrido')
    ? (plan.recur_precio ?? 0) : 0;

  const recargoAsientos = porAsiento ? extra * (plan.precio_por_asiento ?? 0) : 0;
  const recurrente = (baseRec + recargoAsientos) * meses;

  const subtotal = setup + recurrente;
  const iva = subtotal * tasaIva;
  const total = subtotal + iva;

  const setupCosto = setup > 0 ? (plan.setup_costo ?? 0) : 0;
  const recCosto = (plan.recur_costo ?? 0) * meses;
  const costoTotal = setupCosto + recCosto;

  return { 
    subtotal: round2(subtotal), 
    iva: round2(iva), 
    total: round2(total), 
    costoTotal: round2(costoTotal) 
  };
}

export function calcularTotalesCotizacionServiciosAware(
  items: ItemCotizacion[],
  productosIdx: Record<string, Producto>,
  tasaIva: number,
  conFactura: boolean = true
): {
  subtotal: number;
  iva: number;
  total: number;
  costo: number;
  utilidad: number;
  margen: number;
} {
  let subtotal = 0;
  let costo = 0;

  for (const item of items) {
    const producto = item.producto_id ? productosIdx[item.producto_id] : undefined;
    
    if (producto?.tipo === 'servicio' && producto.servicio) {
      const resultado = totalItemServicio(item, producto, conFactura ? tasaIva : 0);
      subtotal += resultado.subtotal;
      costo += resultado.costoTotal;
    } else {
      // Producto tradicional (bien)
      const base = (item.cantidad ?? 0) * (item.precio_unitario ?? 0);
      subtotal += base;
      const costoUnitario = item.costo_unitario ?? (producto?.costo ?? 0);
      costo += (item.cantidad ?? 0) * (costoUnitario ?? 0);
    }
  }

  const iva = conFactura ? subtotal * tasaIva : 0;
  const total = subtotal + iva;
  const utilidad = subtotal - costo;
  const margen = subtotal > 0 ? utilidad / subtotal : 0;

  return {
    subtotal: round2(subtotal),
    iva: round2(iva),
    total: round2(total),
    costo: round2(costo),
    utilidad: round2(utilidad),
    margen: Math.round(margen * 1000) / 1000
  };
}

export function calcularResumenServicio(
  items: ItemCotizacion[],
  productosIdx: Record<string, Producto>,
  conFactura: boolean = true,
  tasaIva: number = 0.16
): {
  primerPago: { sinIva: number; conIva: number };
  pagosSiguientes: { sinIva: number; conIva: number };
  totalCotizado: { sinIva: number; conIva: number };
  plazoMinimo?: number;
} {
  let setupTotal = 0;
  let recurrenteTotal = 0;
  let mesesMaximos = 1;
  let plazoMinimo: number | undefined;

  for (const item of items) {
    const producto = item.producto_id ? productosIdx[item.producto_id] : undefined;
    
    if (producto?.tipo === 'servicio' && producto.servicio) {
      const plan = producto.servicio;
      const meses = Math.max(1, item.meses_cobrados ?? 1);
      const extra = Math.max(0, item.asientos_extra ?? 0);
      
      // Setup
      if ((plan.modo === 'unico' || plan.modo === 'hibrido') && (item.incluir_setup ?? true)) {
        setupTotal += plan.setup_precio ?? 0;
      }
      
      // Recurrente
      if (plan.modo === 'suscripcion' || plan.modo === 'hibrido') {
        const baseRec = plan.recur_precio ?? 0;
        const recargoAsientos = plan.por_asiento ? extra * (plan.precio_por_asiento ?? 0) : 0;
        recurrenteTotal += baseRec + recargoAsientos;
      }
      
      mesesMaximos = Math.max(mesesMaximos, meses);
      if (plan.min_meses && (!plazoMinimo || plan.min_meses > plazoMinimo)) {
        plazoMinimo = plan.min_meses;
      }
    }
  }

  const primerPagoSinIva = setupTotal + recurrenteTotal;
  const primerPagoConIva = conFactura ? primerPagoSinIva * (1 + tasaIva) : primerPagoSinIva;
  
  const pagosSiguientesSinIva = recurrenteTotal;
  const pagosSiguientesConIva = conFactura ? pagosSiguientesSinIva * (1 + tasaIva) : pagosSiguientesSinIva;
  
  const totalCotizadoSinIva = setupTotal + (recurrenteTotal * mesesMaximos);
  const totalCotizadoConIva = conFactura ? totalCotizadoSinIva * (1 + tasaIva) : totalCotizadoSinIva;

  return {
    primerPago: { 
      sinIva: round2(primerPagoSinIva), 
      conIva: round2(primerPagoConIva) 
    },
    pagosSiguientes: { 
      sinIva: round2(pagosSiguientesSinIva), 
      conIva: round2(pagosSiguientesConIva) 
    },
    totalCotizado: { 
      sinIva: round2(totalCotizadoSinIva), 
      conIva: round2(totalCotizadoConIva) 
    },
    plazoMinimo
  };
}