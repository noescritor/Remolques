/**
 * Utilidades puras para grupos de configuración con selección mixta y cantidad (Sub-bloque 2R-8).
 * Diseñado sin dependencias de React ni DOM para ejecutarse tanto en Deno (backend/tests)
 * como en el navegador (Vite frontend).
 */

export interface FilaSeleccionMixta {
  opcion: string;
  marca?: string;
  medida?: string;
  cantidad: number;
}

/**
 * Normaliza cualquier valor previo de configuración (string, objeto único o array)
 * a un arreglo estándar de FilaSeleccionMixta.
 */
export function normalizarFilas(valorConfig: any, defaultCantidad: number = 1): FilaSeleccionMixta[] {
  if (valorConfig === undefined || valorConfig === null) {
    return [];
  }

  if (Array.isArray(valorConfig)) {
    return valorConfig
      .filter(item => item !== null && item !== undefined)
      .map(item => {
        if (typeof item === 'string') {
          return { opcion: item, cantidad: defaultCantidad };
        }
        return {
          opcion: item.opcion || '',
          marca: item.marca,
          medida: item.medida,
          cantidad: typeof item.cantidad === 'number' && !isNaN(item.cantidad) && item.cantidad >= 1 ? Math.floor(item.cantidad) : defaultCantidad
        };
      })
      .filter(f => f.opcion.trim() !== '');
  }

  if (typeof valorConfig === 'object') {
    if (!valorConfig.opcion) return [];
    return [{
      opcion: valorConfig.opcion,
      marca: valorConfig.marca,
      medida: valorConfig.medida,
      cantidad: typeof valorConfig.cantidad === 'number' && !isNaN(valorConfig.cantidad) && valorConfig.cantidad >= 1 ? Math.floor(valorConfig.cantidad) : defaultCantidad
    }];
  }

  if (typeof valorConfig === 'string' && valorConfig.trim() !== '') {
    return [{ opcion: valorConfig.trim(), cantidad: defaultCantidad }];
  }

  return [];
}

/**
 * Suma la cantidad total de piezas de una lista de filas.
 * Las opciones "sin_*" (ej. sin_rines, sin_llantas, sin_matracas) equivalen a "ninguna" y suman 0.
 * La opción "cliente" (proporciona el cliente) sí cuenta para el tope.
 */
export function calcularSumaPiezas(filas: FilaSeleccionMixta[]): number {
  return filas
    .filter(f => f && typeof f.opcion === 'string' && !f.opcion.startsWith('sin_'))
    .reduce((acc, f) => acc + (typeof f.cantidad === 'number' && !isNaN(f.cantidad) ? Math.floor(f.cantidad) : 0), 0);
}

/**
 * Calcula cuántas piezas faltan para alcanzar el tope máximo.
 */
export function calcularFaltantes(maxPiezas: number, filas: FilaSeleccionMixta[]): number {
  const suma = calcularSumaPiezas(filas);
  return Math.max(0, maxPiezas - suma);
}

/**
 * Fusiona filas duplicadas (misma opción y misma marca/medida), sumando sus cantidades.
 * Preserva el orden de aparición de la primera coincidencia.
 */
export function fusionarDuplicados(filas: FilaSeleccionMixta[]): FilaSeleccionMixta[] {
  const map = new Map<string, FilaSeleccionMixta>();

  for (const fila of filas) {
    if (!fila || !fila.opcion) continue;
    const opcionNorm = fila.opcion.trim();
    const marcaNorm = (fila.marca || '').trim().toUpperCase();
    const medidaNorm = (fila.medida || '').trim();
    const key = `${opcionNorm}__${marcaNorm}__${medidaNorm}`;

    if (map.has(key)) {
      const existente = map.get(key)!;
      existente.cantidad = (existente.cantidad || 0) + (fila.cantidad || 1);
    } else {
      map.set(key, {
        opcion: opcionNorm,
        ...(fila.marca ? { marca: fila.marca } : {}),
        ...(fila.medida ? { medida: fila.medida } : {}),
        cantidad: typeof fila.cantidad === 'number' && !isNaN(fila.cantidad) ? fila.cantidad : 1
      });
    }
  }

  return Array.from(map.values());
}

/**
 * Calcula el número máximo de piezas de un grupo para un modelo dado,
 * basándose en su regla JSON (por_eje o fija).
 */
export function calcularMaxPiezasGrupo(grupo: any, modelo: any): number | undefined {
  if (!grupo) return undefined;
  let regla = grupo.regla;
  if (typeof regla === 'string') {
    try {
      regla = JSON.parse(regla);
    } catch {
      return undefined;
    }
  }

  if (regla && typeof regla === 'object') {
    if (regla.max_total?.por_eje && typeof modelo?.num_ejes === 'number') {
      return regla.max_total.por_eje * modelo.num_ejes;
    }
    if (typeof regla.max_total?.fija === 'number') {
      return regla.max_total.fija;
    }
  }

  return undefined;
}

export interface ResultadoValidacionSeleccionMixta {
  valido: boolean;
  errores: string[];
  advertencias: string[];
  suma: number;
  filasFusionadas: FilaSeleccionMixta[];
}

/**
 * Valida la selección de filas contra el tope máximo del grupo.
 */
export function validarFilasSeleccionMixta(
  filas: FilaSeleccionMixta[],
  maxPiezas: number,
  nombreGrupo: string
): ResultadoValidacionSeleccionMixta {
  const errores: string[] = [];
  const advertencias: string[] = [];

  const filasFusionadas = fusionarDuplicados(filas);

  for (const f of filasFusionadas) {
    if (!Number.isInteger(f.cantidad) || f.cantidad < 1) {
      errores.push(`La cantidad de cada fila en ${nombreGrupo} debe ser un número entero mayor o igual a 1.`);
      break;
    }
  }

  const suma = calcularSumaPiezas(filasFusionadas);
  const esPluralFemenino = nombreGrupo.toLowerCase().startsWith('llanta') || nombreGrupo.toLowerCase().startsWith('matraca');
  const articulo = esPluralFemenino ? 'Las' : 'Los';

  if (suma > maxPiezas) {
    errores.push(`${articulo} ${nombreGrupo.toLowerCase()} suman ${suma} piezas y el máximo para este modelo es ${maxPiezas}`);
  } else if (suma < maxPiezas && suma > 0) {
    const faltan = maxPiezas - suma;
    advertencias.push(`Faltan ${faltan} ${nombreGrupo.toLowerCase()} por definir`);
  }

  return {
    valido: errores.length === 0,
    errores,
    advertencias,
    suma,
    filasFusionadas
  };
}

/**
 * Comportamiento guiado para nueva fila:
 * - Primera opción: llena con el máximo.
 * - Siguientes opciones: llena con lo que falta (mínimo 1).
 * - Si ya no falta nada: avisa que se llegó al tope.
 */
export function siguienteCantidad(
  maxPiezas: number,
  filasActuales: FilaSeleccionMixta[]
): { cantidadSugerida: number; yaLlegoAlMaximo: boolean; mensajeBloqueo?: string } {
  if (filasActuales.length === 0) {
    return { cantidadSugerida: Math.max(1, maxPiezas), yaLlegoAlMaximo: false };
  }

  const faltan = calcularFaltantes(maxPiezas, filasActuales);
  if (faltan <= 0) {
    return {
      cantidadSugerida: 1,
      yaLlegoAlMaximo: true,
      mensajeBloqueo: `Ya llegaste al máximo de ${maxPiezas} piezas; reduce otra fila para agregar.`
    };
  }

  return {
    cantidadSugerida: faltan,
    yaLlegoAlMaximo: false
  };
}

/**
 * Asigna a una fila específica lo que falta para llegar al máximo total del grupo.
 */
export function completarConEstaOpcion(
  filas: FilaSeleccionMixta[],
  indexACompletar: number,
  maxPiezas: number
): FilaSeleccionMixta[] {
  const otrasSuma = filas.reduce((acc, f, i) => {
    if (i === indexACompletar || !f || f.opcion.startsWith('sin_')) return acc;
    return acc + (Number(f.cantidad) || 0);
  }, 0);

  const nuevaCantidad = Math.max(1, maxPiezas - otrasSuma);
  return filas.map((f, i) => (i === indexACompletar ? { ...f, cantidad: nuevaCantidad } : f));
}
