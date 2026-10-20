import type { Configuracion, DatosModelo } from "./tipos.ts";

/**
 * Fusiona filas duplicadas (misma opción y misma marca/medida) sumando sus cantidades.
 */
export function fusionarFilasConfig(vals: any[]): any[] {
  const map = new Map<string, any>();
  for (const v of vals) {
    if (!v) continue;
    const opcion = typeof v === "string" ? v : v.opcion;
    if (!opcion) continue;
    const marca = typeof v === "object" && v.marca ? v.marca.trim().toUpperCase() : "";
    const medida = typeof v === "object" && v.medida ? String(v.medida).trim() : "";
    const key = `${opcion}__${marca}__${medida}`;

    if (map.has(key)) {
      const prev = map.get(key);
      const prevCant = typeof prev === "object" && typeof prev.cantidad === "number" ? prev.cantidad : (typeof v === "object" && typeof v.cantidad === "number" ? 0 : 1);
      const curCant = typeof v === "object" && typeof v.cantidad === "number" ? v.cantidad : 1;
      map.set(key, {
        ...(typeof prev === "object" ? prev : { opcion: prev }),
        cantidad: prevCant + curCant
      });
    } else {
      map.set(key, typeof v === "object" ? { ...v } : v);
    }
  }
  return Array.from(map.values());
}

export const RETRACTILES_POR_ABS: Record<string, number> = {
  "2e_sin_retractil": 0,
  "2e_1_retractil": 1,
  "3e_sin_retractil": 0,
  "3e_1_retractil": 1,
  "3e_2_retractil": 2,
};

/**
 * Obtiene el número de retráctiles contemplados por una opción de kit de aire (abs).
 * Retorna un número (0, 1, 2, ...) o null si la clave no encaja en el patrón.
 */
export function obtenerRetractilesDeClaveAbs(claveAbs: string): number | null {
  if (typeof claveAbs !== "string") return null;
  if (claveAbs in RETRACTILES_POR_ABS) {
    return RETRACTILES_POR_ABS[claveAbs];
  }
  if (claveAbs.includes("sin_retractil")) {
    return 0;
  }
  const match = claveAbs.match(/(\d+)_retractil(?:es)?/);
  if (match) {
    return parseInt(match[1], 10);
  }
  return null;
}

export function validarCompatibilidad(
  config: Configuracion,
  datos: DatosModelo,
  errores: string[],
  advertencias?: string[]
) {
  // Extract selected options with their metadata
  const selectedOptions = new Map<string, any>();
  for (const [gClave, val] of Object.entries(config.grupos || {})) {
    if (Array.isArray(val)) continue; // Las reglas condicionales actuales no operan sobre grupos múltiples
    const oClave = typeof val === "string" ? val : (val as any).opcion;
    const grupo = datos.grupos.find((g) => g.clave === gClave);
    if (!grupo) continue;
    const opcion = datos.opciones.find((o) => o.grupo_id === grupo.id && o.clave === oClave);
    if (opcion) {
      selectedOptions.set(gClave, opcion);
    }
  }

  // Regla 1: Suspensión vs Retráctil (soporta string, objeto o arreglo de retráctiles)
  const susp = selectedOptions.get("suspension");
  const grpRetractil = datos.grupos.find((g) => g.clave === "retractil");
  const retrRaw = config.grupos?.["retractil"];
  const retrList = retrRaw ? (Array.isArray(retrRaw) ? retrRaw : [retrRaw]) : [];

  for (const r of retrList) {
    const oClave = typeof r === "string" ? r : r?.opcion;
    if (!oClave) continue;
    const opcion = datos.opciones.find((o) => o.grupo_id === grpRetractil?.id && o.clave === oClave);
    if (susp && opcion && opcion.clave !== "sin_retractil" && opcion.clave !== "paleta") {
      if (susp.clase === "alta" && opcion.clave !== "grande") {
        errores.push(`Incompatibilidad: La suspensión de clase alta requiere un retráctil grande (seleccionado: ${opcion.nombre}).`);
      } else if (susp.clase === "normal" && opcion.clave !== "chico") {
        errores.push(`Incompatibilidad: La suspensión de clase normal requiere un retráctil chico (seleccionado: ${opcion.nombre}).`);
      }
    }
  }

  // Regla 2: Dona vs Gancho
  const dona = selectedOptions.get("dona");
  const gancho = selectedOptions.get("gancho");

  if (dona && gancho && dona.clave !== "sin_dona" && gancho.clave !== "sin_gancho") {
    const mapaDonaGancho: Record<string, string> = {
      "holland": "holland_8_10",
      "premier": "premier_8",
      "bestia": "premier_bestia_6"
    };
    
    if (mapaDonaGancho[dona.clave] !== gancho.clave) {
        errores.push(`Incompatibilidad: La dona ${dona.nombre} no corresponde al gancho ${gancho.nombre}.`);
    }
  }

  // Regla 3: Grupos con max_total (rines, llantas, matracas, retractil)
  for (const grupo of datos.grupos || []) {
    let regla: any = grupo.regla;
    if (typeof regla === "string") {
      try {
        regla = JSON.parse(regla);
      } catch {
        regla = null;
      }
    }
    if (!regla || typeof regla !== "object" || !regla.max_total) continue;

    let maxPiezas: number | undefined = undefined;
    if (regla.max_total?.por_eje && typeof datos.modelo?.num_ejes === "number") {
      maxPiezas = regla.max_total.por_eje * datos.modelo.num_ejes;
    } else if (typeof regla.max_total?.fija === "number") {
      maxPiezas = regla.max_total.fija;
    }
    if (maxPiezas === undefined) continue;

    const valConfigRaw = config.grupos?.[grupo.clave];
    if (valConfigRaw === undefined || valConfigRaw === null) continue;

    const rawVals = Array.isArray(valConfigRaw) ? valConfigRaw : [valConfigRaw];
    const tieneCant = (f: any) =>
      typeof f === "object" && f !== null && typeof f.cantidad === "number" && !isNaN(f.cantidad);
    const esSin = (f: any) => {
      const op = typeof f === "string" ? f : f?.opcion;
      return typeof op === "string" && op.startsWith("sin_");
    };

    const rawReales = rawVals.filter(f => f && !esSin(f));
    if (rawReales.length === 0) continue;

    // Si hay varias filas y alguna no tiene cantidad explícita -> error
    if (rawReales.length > 1) {
      const haySinCantidad = rawReales.some(f => !tieneCant(f));
      if (haySinCantidad) {
        errores.push(`Indica la cantidad de cada fila en ${grupo.nombre}.`);
        continue;
      }
    }

    let cantDef: number;
    if (regla.cantidad_defecto === "max") {
      cantDef = maxPiezas;
    } else if (typeof regla.cantidad_defecto === "number") {
      cantDef = regla.cantidad_defecto;
    } else {
      cantDef = maxPiezas;
    }

    // Si es una sola fila sin cantidad, asignamos cantDef (retrocompatibilidad)
    const valsConDefecto = rawVals.map(f => {
      if (f && !esSin(f) && !tieneCant(f)) {
        return typeof f === "object" ? { ...f, cantidad: cantDef } : { opcion: f, cantidad: cantDef };
      }
      return f;
    });

    const filasFusionadas = fusionarFilasConfig(valsConDefecto);

    let suma = 0;
    for (const fila of filasFusionadas) {
      if (esSin(fila)) continue;
      const cant = typeof fila === "object" && typeof fila.cantidad === "number" ? fila.cantidad : cantDef;

      if (!Number.isInteger(cant) || cant < 1) {
        errores.push(`La cantidad de cada fila en ${grupo.nombre} debe ser un número entero mayor o igual a 1.`);
      }

      suma += cant;
    }

    const esPluralFemenino = grupo.nombre.toLowerCase().startsWith("llanta") || grupo.nombre.toLowerCase().startsWith("matraca");
    const articulo = esPluralFemenino ? "Las" : "Los";
    const nombreSujeto = grupo.clave === "retractil" ? "retráctiles" : grupo.nombre.toLowerCase();

    if (suma > maxPiezas) {
      errores.push(`${articulo} ${nombreSujeto} suman ${suma} piezas y el máximo para este modelo es ${maxPiezas}`);
    } else if (suma < maxPiezas && suma > 0 && (regla.cantidad_defecto === "max" || regla.cantidad_defecto === undefined)) {
      const faltan = maxPiezas - suma;
      if (advertencias) {
        advertencias.push(`Faltan ${faltan} ${nombreSujeto} por definir`);
      }
    }
  }

  const absVal = config.grupos?.["abs"];
  const absClave = typeof absVal === "string" ? absVal : (!Array.isArray(absVal) && typeof absVal === "object" && absVal ? (absVal as any).opcion : undefined);
  if (absClave) {
    const esperado = obtenerRetractilesDeClaveAbs(absClave);
    if (esperado !== null && advertencias) {
      let totalRetractiles = 0;
      for (const r of retrList) {
        const op = typeof r === "string" ? r : r?.opcion;
        if (!op || op.startsWith("sin_")) continue;
        const cant = typeof r === "object" && typeof r.cantidad === "number" && !isNaN(r.cantidad) ? r.cantidad : 1;
        totalRetractiles += cant;
      }

      if (totalRetractiles !== esperado) {
        const espStr = esperado === 1 ? "1 retráctil" : `${esperado} retráctiles`;
        advertencias.push(`El kit de aire elegido es para ${espStr} y elegiste ${totalRetractiles}; revisa el kit de aire (no hay precio para esa combinación)`);
      }
    }
  }
}
