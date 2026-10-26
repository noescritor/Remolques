/**
 * Funciones puras para las calculadoras de acero (Sub-bloque 2R-13)
 * - Medidas y conversión de pies a mm
 * - Extracción de medidas de placas/láminas
 * - Costeo proporcional de placa por área
 * - Comparador de precios por proveedor
 */

export type TipoMaterialAcero =
  | 'placa'
  | 'lamina'
  | 'solera'
  | 'canal'
  | 'ptr'
  | 'tubo'
  | 'angulo'
  | 'redondo';

/**
 * Tabla explícita de equivalencia de pies a milímetros según las especificaciones
 * del Excel del cliente: 4→1219, 5→1523, 10→3050.
 * Nota: 5→1523 y 10→3050 provienen tal cual del Excel del cliente (en lugar del valor estándar 5*304.8=1524).
 */
export const TABLA_FT_A_MM: Record<number, number> = {
  4: 1219,
  5: 1523,
  10: 3050,
};

/**
 * Convierte una medida en pies a milímetros.
 * Para 4, 5 y 10 pies usa los valores exactos del Excel del cliente.
 * Para el resto calcula round(ft * 304.8).
 */
export function medidaFtAMm(ft: number): number {
  if (ft in TABLA_FT_A_MM) {
    return TABLA_FT_A_MM[ft];
  }
  return Math.round(ft * 304.8);
}

/**
 * Determina el tipo de material a partir de su nombre comercial.
 */
export function determinarTipoMaterial(nombre: string): TipoMaterialAcero {
  const n = (nombre || '')
    .trim()
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '');

  if (n.startsWith('placa')) return 'placa';
  if (n.startsWith('lamina')) return 'lamina';
  if (n.startsWith('solera')) return 'solera';
  if (n.startsWith('canal')) return 'canal';
  if (n.startsWith('ptr')) return 'ptr';
  if (n.startsWith('tubo')) return 'tubo';
  if (n.startsWith('angulo')) return 'angulo';
  if (n.startsWith('redondo')) return 'redondo';

  // Si no inicia con el prefijo pero lo contiene
  if (n.includes('placa')) return 'placa';
  if (n.includes('lamina')) return 'lamina';
  if (n.includes('solera')) return 'solera';
  if (n.includes('canal')) return 'canal';
  if (n.includes('ptr')) return 'ptr';
  if (n.includes('tubo')) return 'tubo';
  if (n.includes('angulo')) return 'angulo';
  if (n.includes('redondo')) return 'redondo';

  throw new Error(`No se pudo determinar el tipo de material para: "${nombre}"`);
}

/**
 * Normaliza nombres con caracteres potencialmente dañados (ej: A-572°50 -> A-572-50)
 */
export function normalizarNombreMaterial(nombre: string): string {
  if (!nombre) return '';
  return nombre.replace(/A-572[°\uFFFD\u00B0]?50/g, 'A-572-50');
}

/**
 * Extrae las dimensiones en pies (ancho y largo) del nombre de una placa o lámina.
 * Ejemplo: "Placa de grado A-36 de 3/16\" en 5X10'" -> { anchoFt: 5, largoFt: 10 }
 * Devuelve null si el nombre no contiene dimensiones en formato de lámina.
 */
export function parsearMedidaLamina(
  nombre: string
): { anchoFt: number; largoFt: number } | null {
  if (!nombre) return null;
  // Busca expresiones con comilla simple de pies: "5X10'", "4X40'", "3X10'"
  const regex = /(?:en\s+)?(\d+(?:\.\d+)?)\s*[xX]\s*(\d+(?:\.\d+)?)\s*'/;
  const match = nombre.match(regex);
  if (match) {
    const anchoFt = parseFloat(match[1]);
    const largoFt = parseFloat(match[2]);
    if (!isNaN(anchoFt) && !isNaN(largoFt) && anchoFt > 0 && largoFt > 0) {
      return { anchoFt, largoFt };
    }
  }
  return null;
}

/**
 * Factor sobre costo (merma/proceso) por defecto según el Excel del cliente.
 * Nota: Valor del Excel del cliente; pendiente confirmar qué incluye.
 */
export const FACTOR_PLACA_DEFECTO = 1.5;

export interface CostoPiezaInput {
  precioLamina: number;
  anchoLaminaMm: number;
  largoLaminaMm: number;
  anchoPiezaMm: number;
  largoPiezaMm: number;
  factor?: number;
}

export interface CostoPiezaResultado {
  areaLaminaMm2: number;
  areaPiezaMm2: number;
  costoProporcional: number;
  costoPieza: number;
  piezasPorArea: number;
  costoPorM2: number;
}

/**
 * Calcula el costo de una pieza cortada a partir de una lámina/placa completa.
 */
export function costoPieza(params: CostoPiezaInput): CostoPiezaResultado {
  const {
    precioLamina,
    anchoLaminaMm,
    largoLaminaMm,
    anchoPiezaMm,
    largoPiezaMm,
    factor = FACTOR_PLACA_DEFECTO,
  } = params;

  if (!Number.isFinite(precioLamina) || precioLamina <= 0) {
    throw new Error('El precio de la lámina debe ser mayor a cero');
  }
  if (!Number.isFinite(anchoLaminaMm) || anchoLaminaMm <= 0) {
    throw new Error('El ancho de la lámina debe ser mayor a cero');
  }
  if (!Number.isFinite(largoLaminaMm) || largoLaminaMm <= 0) {
    throw new Error('El largo de la lámina debe ser mayor a cero');
  }
  if (!Number.isFinite(anchoPiezaMm) || anchoPiezaMm <= 0) {
    throw new Error('El ancho de la pieza debe ser mayor a cero');
  }
  if (!Number.isFinite(largoPiezaMm) || largoPiezaMm <= 0) {
    throw new Error('El largo de la pieza debe ser mayor a cero');
  }
  if (!Number.isFinite(factor) || factor < 1) {
    throw new Error('El factor debe ser mayor o igual a 1');
  }

  const areaLaminaMm2 = anchoLaminaMm * largoLaminaMm;
  const areaPiezaMm2 = anchoPiezaMm * largoPiezaMm;

  if (areaPiezaMm2 > areaLaminaMm2) {
    throw new Error('La pieza no puede ser mayor que la lámina por área');
  }

  const costoProporcional = (precioLamina * areaPiezaMm2) / areaLaminaMm2;
  const costoPiezaCalculado = costoProporcional * factor;
  const piezasPorArea = Math.floor(areaLaminaMm2 / areaPiezaMm2);
  const areaLaminaM2 = areaLaminaMm2 / 1_000_000;
  const costoPorM2 = areaLaminaM2 > 0 ? precioLamina / areaLaminaM2 : 0;

  return {
    areaLaminaMm2,
    areaPiezaMm2,
    costoProporcional,
    costoPieza: costoPiezaCalculado,
    piezasPorArea,
    costoPorM2,
  };
}

export interface RenglonComparadorInput {
  materialId: string;
  cantidad: number;
}

export interface PrecioItemInput {
  material_id: string;
  proveedor: string;
  precio: number;
  incluye_iva?: boolean;
}

export interface RenglonProveedorResultado {
  materialId: string;
  cantidad: number;
  precioUnitario: number | null;
  importe: number | null;
}

export interface ProveedorComparacion {
  proveedor: string;
  renglones: RenglonProveedorResultado[];
  completo: boolean;
  materialesFaltantes: string[];
  subtotal: number;
  iva: number;
  total: number;
  diferenciaContraMejor: number | null;
}

export interface MejorPorRenglonItem {
  materialId: string;
  cantidad: number;
  proveedor: string | null;
  precioUnitario: number | null;
  importe: number | null;
}

export interface ComparacionResultado {
  proveedores: ProveedorComparacion[];
  mejorProveedorCompleto: ProveedorComparacion | null;
  mejorPorRenglon: {
    renglones: MejorPorRenglonItem[];
    subtotal: number;
    iva: number;
    total: number;
    ahorroContraMejorCompleto: number | null;
  };
}

/**
 * Compara precios de acero entre múltiples proveedores.
 */
export function compararProveedores(params: {
  renglones: RenglonComparadorInput[];
  precios: PrecioItemInput[];
  incluyeIva?: boolean;
  proveedores?: string[];
  catalogoMateriales?: Record<string, { nombre: string }>;
}): ComparacionResultado {
  const {
    renglones,
    precios,
    incluyeIva = true,
    proveedores: provsParam,
    catalogoMateriales = {},
  } = params;

  // Filtrar renglones con cantidad válida > 0
  const renglonesValidos = (renglones || []).filter(
    (r) => Number.isFinite(r.cantidad) && r.cantidad > 0
  );

  // Lista de proveedores a evaluar
  const listaProveedores: string[] =
    provsParam && provsParam.length > 0
      ? provsParam
      : Array.from(new Set(precios.map((p) => p.proveedor))).filter(Boolean);

  // Mapa rápido de precios: key = `${material_id}::${proveedor}`
  const mapaPrecios = new Map<string, number>();
  for (const p of precios) {
    if (Number.isFinite(p.precio) && p.precio > 0) {
      mapaPrecios.set(`${p.material_id}::${p.proveedor}`, p.precio);
    }
  }

  if (renglonesValidos.length === 0 || listaProveedores.length === 0) {
    return {
      proveedores: listaProveedores.map((proveedor) => ({
        proveedor,
        renglones: [],
        completo: false,
        materialesFaltantes: [],
        subtotal: 0,
        iva: 0,
        total: 0,
        diferenciaContraMejor: null,
      })),
      mejorProveedorCompleto: null,
      mejorPorRenglon: {
        renglones: [],
        subtotal: 0,
        iva: 0,
        total: 0,
        ahorroContraMejorCompleto: null,
      },
    };
  }

  // Evaluar cada proveedor
  const resultadosProveedores: Array<
    ProveedorComparacion & { unroundedTotal: number }
  > = [];

  for (const prov of listaProveedores) {
    const renglonesProv: RenglonProveedorResultado[] = [];
    const faltantes: string[] = [];
    let sumaImporte = 0;
    let completo = true;

    for (const r of renglonesValidos) {
      const precioUnitario = mapaPrecios.get(`${r.materialId}::${prov}`) ?? null;
      if (precioUnitario === null) {
        completo = false;
        const nombreMat = catalogoMateriales[r.materialId]?.nombre || r.materialId;
        faltantes.push(nombreMat);
        renglonesProv.push({
          materialId: r.materialId,
          cantidad: r.cantidad,
          precioUnitario: null,
          importe: null,
        });
      } else {
        const importe = precioUnitario * r.cantidad;
        sumaImporte += importe;
        renglonesProv.push({
          materialId: r.materialId,
          cantidad: r.cantidad,
          precioUnitario,
          importe: Math.round(importe * 100) / 100,
        });
      }
    }

    let subtotal = 0;
    let iva = 0;
    let total = 0;
    let unroundedTotal = 0;

    if (completo) {
      if (incluyeIva) {
        unroundedTotal = sumaImporte;
        total = Math.round(sumaImporte * 100) / 100;
        const rawSub = unroundedTotal / 1.16;
        subtotal = Math.round(rawSub * 100) / 100;
        iva = Math.round((total - subtotal) * 100) / 100;
      } else {
        const rawSub = sumaImporte;
        subtotal = Math.round(rawSub * 100) / 100;
        const rawIva = rawSub * 0.16;
        iva = Math.round(rawIva * 100) / 100;
        unroundedTotal = rawSub * 1.16;
        total = Math.round(unroundedTotal * 100) / 100;
      }
    }

    resultadosProveedores.push({
      proveedor: prov,
      renglones: renglonesProv,
      completo,
      materialesFaltantes: faltantes,
      subtotal,
      iva,
      total,
      unroundedTotal,
      diferenciaContraMejor: null,
    });
  }

  // Encontrar el mejor proveedor completo
  const completos = resultadosProveedores.filter((p) => p.completo);
  let mejorProveedorCompleto: ProveedorComparacion | null = null;
  let unroundedMejorTotal = 0;

  if (completos.length > 0) {
    completos.sort((a, b) => a.total - b.total);
    mejorProveedorCompleto = completos[0];
    unroundedMejorTotal = (mejorProveedorCompleto as any).unroundedTotal;
  }

  // Calcular diferencias contra el mejor completo
  for (const prov of resultadosProveedores) {
    if (prov.completo && mejorProveedorCompleto) {
      if (prov.proveedor === mejorProveedorCompleto.proveedor) {
        prov.diferenciaContraMejor = 0;
      } else {
        // Usar la diferencia no redondeada para coincidir con la precisión del Excel (54,665.12)
        const dif = Math.round((prov.unroundedTotal - unroundedMejorTotal) * 100) / 100;
        prov.diferenciaContraMejor = Math.max(0, dif);
      }
    } else {
      prov.diferenciaContraMejor = null;
    }
  }

  // Compra mixta: mejor precio por renglón
  const renglonesMixtos: MejorPorRenglonItem[] = [];
  let sumaMixta = 0;
  let mixtoCompleto = true;

  for (const r of renglonesValidos) {
    let mejorPrecio: number | null = null;
    let mejorProv: string | null = null;

    for (const prov of listaProveedores) {
      const p = mapaPrecios.get(`${r.materialId}::${prov}`);
      if (p !== undefined && p !== null) {
        if (mejorPrecio === null || p < mejorPrecio) {
          mejorPrecio = p;
          mejorProv = prov;
        }
      }
    }

    if (mejorPrecio === null) {
      mixtoCompleto = false;
      renglonesMixtos.push({
        materialId: r.materialId,
        cantidad: r.cantidad,
        proveedor: null,
        precioUnitario: null,
        importe: null,
      });
    } else {
      const importe = mejorPrecio * r.cantidad;
      sumaMixta += importe;
      renglonesMixtos.push({
        materialId: r.materialId,
        cantidad: r.cantidad,
        proveedor: mejorProv,
        precioUnitario: mejorPrecio,
        importe: Math.round(importe * 100) / 100,
      });
    }
  }

  let mixtoSubtotal = 0;
  let mixtoIva = 0;
  let mixtoTotal = 0;

  if (mixtoCompleto) {
    if (incluyeIva) {
      mixtoTotal = Math.round(sumaMixta * 100) / 100;
      const rawSub = mixtoTotal / 1.16;
      mixtoSubtotal = Math.round(rawSub * 100) / 100;
      mixtoIva = Math.round((mixtoTotal - mixtoSubtotal) * 100) / 100;
    } else {
      mixtoSubtotal = Math.round(sumaMixta * 100) / 100;
      const rawIva = mixtoSubtotal * 0.16;
      mixtoIva = Math.round(rawIva * 100) / 100;
      mixtoTotal = Math.round((mixtoSubtotal * 1.16) * 100) / 100;
    }
  }

  const ahorroContraMejorCompleto =
    mixtoCompleto && mejorProveedorCompleto
      ? Math.round((mejorProveedorCompleto.total - mixtoTotal) * 100) / 100
      : null;

  return {
    proveedores: resultadosProveedores.map(({ unroundedTotal: _, ...p }) => p),
    mejorProveedorCompleto: mejorProveedorCompleto
      ? (() => {
          const { unroundedTotal: _, ...clean } = mejorProveedorCompleto as any;
          return clean;
        })()
      : null,
    mejorPorRenglon: {
      renglones: renglonesMixtos,
      subtotal: mixtoSubtotal,
      iva: mixtoIva,
      total: mixtoTotal,
      ahorroContraMejorCompleto,
    },
  };
}
