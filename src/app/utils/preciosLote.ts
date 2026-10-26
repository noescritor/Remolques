/**
 * Funciones puras para actualización masiva de precios (Sub-bloque 2R-14)
 * - Cálculo de nuevos precios por porcentaje, monto o fijo con redondeos
 * - Parseo robusto y seguro de importes en texto
 * - Análisis y validación de lotes de precios (alertas, errores, impacto)
 * - Conversión de hojas Excel/CSV a filas estructuradas
 */

export type ModoCalculo = 'porcentaje' | 'monto' | 'fijo';
export type TipoRedondeo = 'centavos' | 'peso' | 'multiplo5';
export type FuentePrecios = 'productos' | 'opcion_costos' | 'costos_modelo' | 'acero_precios';

export interface ParametrosCalculoPrecio {
  precioActual: number | null | undefined;
  modo: ModoCalculo;
  valor: number;
  redondeo?: TipoRedondeo;
}

export interface ResultadoCalculoPrecio {
  precioNuevo: number | null;
  sinPrecioBase: boolean;
}

export interface FilaLoteEntrada {
  id: string;
  fuente: FuentePrecios;
  descripcion: string;
  precioActual: number | null | undefined;
  precioNuevo: number | null | undefined;
  filaArchivo?: number;
  contexto?: string;
  unidad?: string;
  incluyeIva?: boolean | null;
}

export type EstadoFilaLote = 'sinCambio' | 'cambia' | 'alerta' | 'error';

export interface FilaLoteAnalizada extends FilaLoteEntrada {
  estado: EstadoFilaLote;
  delta: number | null;
  deltaPorcentaje: number | null;
  alertas: string[];
  error: string | null;
}

export interface ResumenLote {
  total: number;
  cambian: number;
  sinCambio: number;
  alertas: number;
  errores: number;
  impactoTotalPesos: number;
}

export interface AnalisisLoteResultado {
  filas: FilaLoteAnalizada[];
  resumen: ResumenLote;
}

/**
 * Calcula un nuevo precio aplicando porcentaje, monto o valor fijo, con el redondeo especificado.
 */
export function calcularNuevoPrecio({
  precioActual,
  modo,
  valor,
  redondeo = 'centavos',
}: ParametrosCalculoPrecio): ResultadoCalculoPrecio {
  if (typeof valor !== 'number' || isNaN(valor) || !isFinite(valor)) {
    throw new Error(`El valor del cálculo debe ser un número válido: ${valor}`);
  }

  if (modo === 'fijo' && valor < 0) {
    throw new Error(`El precio fijo no puede ser negativo: ${valor}`);
  }

  // Si no hay precio base actual
  if (precioActual === null || precioActual === undefined) {
    if (modo === 'fijo') {
      const redondeado = aplicarRedondeo(valor, redondeo);
      return { precioNuevo: redondeado, sinPrecioBase: false };
    }
    return { precioNuevo: null, sinPrecioBase: true };
  }

  // Precio 0 con porcentaje se mantiene en 0 y se marca sinPrecioBase
  if (precioActual === 0 && modo === 'porcentaje') {
    return { precioNuevo: 0, sinPrecioBase: true };
  }

  let raw: number;
  if (modo === 'porcentaje') {
    raw = precioActual * (1 + valor / 100);
  } else if (modo === 'monto') {
    raw = precioActual + valor;
  } else if (modo === 'fijo') {
    raw = valor;
  } else {
    throw new Error(`Modo de cálculo desconocido: ${modo}`);
  }

  if (raw < 0) {
    throw new Error(`El precio resultante no puede ser negativo: ${raw}`);
  }

  if (!isFinite(raw) || isNaN(raw)) {
    throw new Error('El precio resultante no es un número finito válido');
  }

  const precioNuevo = aplicarRedondeo(raw, redondeo);
  return { precioNuevo, sinPrecioBase: false };
}

/**
 * Aplica el redondeo seleccionado.
 */
function aplicarRedondeo(valor: number, redondeo: TipoRedondeo): number {
  switch (redondeo) {
    case 'centavos':
      return Math.round(valor * 100) / 100;
    case 'peso':
      return Math.round(valor);
    case 'multiplo5':
      return Math.round(valor / 5) * 5;
    default:
      return Math.round(valor * 100) / 100;
  }
}

/**
 * Parsea un texto numérico proveniente de hojas Excel o CSV.
 * Acepta formatos mexicanos e internacionales:
 * - 1,234.56
 * - 1234.56
 * - $1,234.56
 * - 1 234,56 (espacio de miles con coma decimal)
 * - 1234,56
 * - Vacío o null/undefined -> null (sin cambio)
 *
 * Rechaza casos ambiguos como '1,234' (una coma seguida de exactamente 3 dígitos sin punto),
 * para evitar adivinar si el usuario quiso decir $1,234 o $1.234.
 */
export function parsearPrecioTexto(texto: string | number | null | undefined): number | null {
  if (texto === null || texto === undefined) return null;
  if (typeof texto === 'number') {
    if (isNaN(texto) || !isFinite(texto) || texto < 0) {
      throw new Error(`Precio numérico inválido: ${texto}`);
    }
    return Math.round(texto * 10000) / 10000;
  }

  const s = String(texto).trim();
  if (s === '') return null;

  // Remover símbolo de moneda y espacios sobrantes
  const limpio = s.replace(/^\$/, '').trim();
  if (limpio === '') return null;

  // Regla de ambigüedad: una sola coma seguida de exactamente 3 dígitos sin más separadores
  if (/^\d{1,3},\d{3}$/.test(limpio)) {
    throw new Error(
      `Precio ambiguo '${texto}': especifique decimales (ej. ${limpio}.00 o ${limpio.replace(',', '')})`
    );
  }

  // Normalizar separadores
  let normalizado = limpio.replace(/\s+/g, '');

  if (normalizado.includes(',') && normalizado.includes('.')) {
    // Si contiene ambos separadores:
    const idxComa = normalizado.indexOf(',');
    const idxPunto = normalizado.indexOf('.');
    if (idxComa < idxPunto) {
      // Formato standard: 1,234.56 -> eliminar comas
      normalizado = normalizado.replace(/,/g, '');
    } else {
      // Formato europeo: 1.234,56 -> eliminar puntos y cambiar coma por punto
      normalizado = normalizado.replace(/\./g, '').replace(',', '.');
    }
  } else if (normalizado.includes(',')) {
    // Solo contiene coma(s)
    const partes = normalizado.split(',');
    if (partes.length === 2) {
      // Una sola coma: tratar como coma decimal (ej. 1234,56 -> 1234.56)
      normalizado = partes[0] + '.' + partes[1];
    } else {
      // Múltiples comas: separadores de miles
      normalizado = normalizado.replace(/,/g, '');
    }
  }

  const num = parseFloat(normalizado);
  if (isNaN(num) || !isFinite(num) || num < 0) {
    throw new Error(`No se pudo interpretar el precio: '${texto}'`);
  }

  return Math.round(num * 10000) / 10000;
}

const FUENTES_VALIDAS: Set<FuentePrecios> = new Set([
  'productos',
  'opcion_costos',
  'costos_modelo',
  'acero_precios',
]);

/**
 * Analiza un conjunto de filas de un lote de precios, detectando filas sin cambio,
 * filas que cambian, alertas y errores por registro.
 */
export function analizarLote({ filas }: { filas: FilaLoteEntrada[] }): AnalisisLoteResultado {
  const analizadas: FilaLoteAnalizada[] = [];

  let countCambian = 0;
  let countSinCambio = 0;
  let countAlertas = 0;
  let countErrores = 0;
  let impactoTotal = 0;

  for (const fila of filas) {
    const alertas: string[] = [];
    let error: string | null = null;
    let estado: EstadoFilaLote = 'sinCambio';
    let delta: number | null = null;
    let deltaPorcentaje: number | null = null;

    // Validación de campos básicos
    if (!fila.id || String(fila.id).trim() === '') {
      error = 'Identificador (id) vacío o no especificado';
    } else if (!fila.fuente || !FUENTES_VALIDAS.has(fila.fuente)) {
      error = `Fuente inválida: '${fila.fuente}'`;
    } else if (
      fila.precioNuevo !== null &&
      fila.precioNuevo !== undefined &&
      (isNaN(fila.precioNuevo) || !isFinite(fila.precioNuevo) || fila.precioNuevo < 0)
    ) {
      error = `Precio nuevo no numérico o negativo: ${fila.precioNuevo}`;
    }

    if (error) {
      estado = 'error';
      countErrores++;
    } else {
      const actual = fila.precioActual ?? null;
      const nuevo = fila.precioNuevo ?? null;

      if (nuevo === null || (actual !== null && Math.abs(nuevo - actual) < 0.0001)) {
        estado = 'sinCambio';
        countSinCambio++;
      } else {
        // Hay un cambio de precio
        if (actual !== null) {
          delta = Math.round((nuevo - actual) * 100) / 100;
          if (actual > 0) {
            deltaPorcentaje = Math.round(((nuevo - actual) / actual) * 1000) / 10;
          }
        }

        // Revisar alertas
        if (actual !== null && actual > 0) {
          const varPct = Math.abs((nuevo - actual) / actual);
          if (varPct > 0.3) {
            alertas.push(`Variación mayor al 30% (${(varPct * 100).toFixed(1)}%)`);
          }
          if (nuevo > 5 * actual) {
            alertas.push(`Precio nuevo supera 5 veces el actual (${(nuevo / actual).toFixed(1)}x)`);
          }
        }

        if (nuevo === 0 && actual !== null && actual > 0) {
          alertas.push('Precio nuevo es $0.00 (el precio anterior era mayor a cero)');
        }

        if (alertas.length > 0) {
          estado = 'alerta';
          countAlertas++;
        } else {
          estado = 'cambia';
          countCambian++;
        }

        if (actual !== null) {
          impactoTotal += Math.abs(nuevo - actual);
        } else {
          impactoTotal += nuevo;
        }
      }
    }

    analizadas.push({
      ...fila,
      estado,
      delta,
      deltaPorcentaje,
      alertas,
      error,
    });
  }

  return {
    filas: analizadas,
    resumen: {
      total: filas.length,
      cambian: countCambian,
      sinCambio: countSinCambio,
      alertas: countAlertas,
      errores: countErrores,
      impactoTotalPesos: Math.round(impactoTotal * 100) / 100,
    },
  };
}

/**
 * Normaliza nombres de encabezados para mapear columnas de archivos Excel / CSV.
 */
function normalizarHeader(h: string): string {
  return (h || '')
    .trim()
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^a-z0-9]/g, '');
}

/**
 * Convierte registros crudos de una hoja Excel o CSV en filas con validaciones y
 * número de fila de archivo (1-indexed, considerando cabecera en fila 1).
 */
export function filasDesdeHoja(
  filasRaw: Record<string, any>[],
  fuenteDefault?: FuentePrecios
): FilaLoteEntrada[] {
  const resultado: FilaLoteEntrada[] = [];

  for (let i = 0; i < filasRaw.length; i++) {
    const raw = filasRaw[i];
    const filaArchivo = i + 2; // Fila 1 es cabecera

    // Mapear columnas dinámicamente
    let idVal = '';
    let descVal = '';
    let contextoVal = '';
    let unidadVal = '';
    let fuenteVal: FuentePrecios | undefined = fuenteDefault;
    let precioActualVal: number | null = null;
    let precioNuevoRaw: any = null;

    for (const [key, val] of Object.entries(raw)) {
      const norm = normalizarHeader(key);
      if (norm === 'id' || norm === 'registro' || norm === 'registroid') {
        idVal = val !== null && val !== undefined ? String(val).trim() : '';
      } else if (norm === 'descripcion' || norm === 'concepto' || norm === 'nombre') {
        descVal = val !== null && val !== undefined ? String(val).trim() : '';
      } else if (norm === 'contexto' || norm === 'grupo' || norm === 'modelo' || norm === 'seccion') {
        contextoVal = val !== null && val !== undefined ? String(val).trim() : '';
      } else if (norm === 'unidad') {
        unidadVal = val !== null && val !== undefined ? String(val).trim() : '';
      } else if (norm === 'fuente' || norm === 'tabla') {
        if (typeof val === 'string' && FUENTES_VALIDAS.has(val.trim() as FuentePrecios)) {
          fuenteVal = val.trim() as FuentePrecios;
        }
      } else if (norm === 'precioactual' || norm === 'costoactual' || norm === 'costovigente') {
        try {
          precioActualVal = parsearPrecioTexto(val);
        } catch {
          precioActualVal = null;
        }
      } else if (
        norm === 'precionuevo' ||
        norm === 'costonuevo' ||
        norm === 'nuevo' ||
        norm === 'nuevoprecio' ||
        norm === 'nuevocosto'
      ) {
        precioNuevoRaw = val;
      }
    }

    let precioNuevo: number | null = null;
    if (precioNuevoRaw !== null && precioNuevoRaw !== undefined && String(precioNuevoRaw).trim() !== '') {
      try {
        precioNuevo = parsearPrecioTexto(precioNuevoRaw);
      } catch (err: any) {
        // Dejar como NaN para que analizarLote lo marque como error reportando la fila
        precioNuevo = NaN;
      }
    }

    resultado.push({
      id: idVal,
      fuente: (fuenteVal || 'productos') as FuentePrecios,
      descripcion: descVal,
      contexto: contextoVal,
      unidad: unidadVal,
      precioActual: precioActualVal,
      precioNuevo,
      filaArchivo,
    });
  }

  return resultado;
}
