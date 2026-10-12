import type {
  ResultadoCosteo,
  Resultado,
  LineaCosteo
} from "./tipos.ts";

export interface PresupuestoItem {
  pzas: number | string;
  material: string;
  cu: number;
  importe: number;
  sin_precio?: boolean;
}

export interface PresupuestoSeccion {
  items: PresupuestoItem[];
  total: number;
}

export interface MetaConceptoIncluido {
  descripcion: string;
  modelo_id?: string | null;
  cantidad: number;
  confianza: "completa" | "estimada" | "incompleta";
  costo: number;
  precio_sugerido: number | null;
}

export interface MetaConceptoOmitido {
  descripcion: string;
  motivo: string;
}

export interface BomLineaResumen {
  material_id: string;
  nombre: string;
  unidad: string;
  cantidad: number;
  seccion: string;
  origen: string[];
}

export interface BomEquipoResumen {
  descripcion: string;
  modelo_id?: string | null;
  cantidad: number;
  lineas: BomLineaResumen[];
  omitidas: { descripcion: string; texto: string }[];
  alternativas: { reemplaza: string | null; posibles_reemplazos: string[]; sustituto: string; grupo: string }[];
}

export interface MetaPresupuesto {
  origen: "costeo";
  cotizacion_id?: string | null;
  generado_en: string;
  conceptos_incluidos: MetaConceptoIncluido[];
  conceptos_omitidos: MetaConceptoOmitido[];
  pendientes: string[];
  confianza: "completa" | "estimada" | "incompleta";
  sin_precio: number;
  sin_clasificar: string[];
  bom: BomEquipoResumen[];
}

export interface PresupuestoDatos {
  acero: PresupuestoSeccion;
  piramide: PresupuestoSeccion;
  truckzone: PresupuestoSeccion;
  otros: PresupuestoSeccion;
  piso: PresupuestoSeccion;
  extras: PresupuestoSeccion;
  rines: PresupuestoSeccion;
  indirectos: PresupuestoSeccion;
  manoobra: PresupuestoSeccion;
  adicionales: PresupuestoSeccion;
  // Secciones nuevas (2R-4a)
  tornilleria?: PresupuestoSeccion;
  luz?: PresupuestoSeccion;
  aire?: PresupuestoSeccion;
  pintura?: PresupuestoSeccion;
  meta?: MetaPresupuesto;
}

export interface ItemPresupuestoInput {
  descripcion: string;
  cantidad: number;
  modelo_id?: string | null;
}

export interface EquipoPresupuestoInput {
  item: ItemPresupuestoInput;
  costeo: ResultadoCosteo;
  bom?: Resultado | null;
}

export interface OpcionesPresupuesto {
  cotizacion_id?: string | null;
  conceptos_omitidos?: MetaConceptoOmitido[];
  generado_en?: string;
}

export interface ResultadoGeneracionPresupuesto {
  datos: PresupuestoDatos;
  total_costo: number;
  meta: MetaPresupuesto;
}

function round2(num: number): number {
  return Math.round((num + Number.EPSILON) * 100) / 100;
}

/**
 * Tabla de mapeo: grupo de opción -> sección de presupuesto
 */
export const MAPEO_GRUPOS_OPCIONES: Record<string, keyof PresupuestoDatos> = {
  // truckzone
  suspension: "truckzone",
  eje: "truckzone",
  patin: "truckzone",
  gancho: "truckzone",
  retractil: "truckzone",
  riel: "truckzone",
  matracas: "truckzone",
  quinta: "truckzone",
  dona: "truckzone",
  // aire
  abs: "aire",
  // rines
  rines: "rines",
  llantas: "rines",
  // piso
  piso: "piso",
  // pintura
  pintura: "pintura",
  color: "pintura",
  // extras
  frente: "extras",
  redilas: "extras",
  // adicionales
  adicionales: "adicionales",
  plafones: "adicionales"
};

/**
 * Mapeo de kits fijos por su campo seccion
 */
export function clasificarKitFijo(seccion?: string): keyof PresupuestoDatos {
  const s = (seccion || "").toLowerCase().trim();
  if (s === "tornilleria") return "tornilleria";
  if (s === "luz") return "luz";
  if (s === "pintura") return "pintura";
  // 'consumibles', 'otros', o no clasificado
  return "otros";
}

/**
 * Determina la sección del presupuesto para una línea de opción
 */
export function clasificarOpcion(
  origen: string,
  sinClasificarSet: Set<string>
): keyof PresupuestoDatos {
  const match = origen.match(/^opcion:([^/]+)/);
  if (!match) {
    sinClasificarSet.add("desconocido");
    return "otros";
  }
  const grupo = match[1].toLowerCase().trim();
  const seccion = MAPEO_GRUPOS_OPCIONES[grupo];
  if (seccion) {
    return seccion;
  }
  sinClasificarSet.add(grupo);
  return "otros";
}

interface AcumuladorLinea {
  pzas: number;
  material: string;
  cu: number;
  sin_precio: boolean;
  importeExacto: number;
}

interface AcumuladorManoObra {
  proceso: string;
  horas: number;
  importeExacto: number;
}

/**
 * Genera el presupuesto puro a partir de la lista de equipos costeados.
 */
export function generarPresupuestoDesdeCosteo(
  equipos: EquipoPresupuestoInput[],
  opciones?: OpcionesPresupuesto
): ResultadoGeneracionPresupuesto {
  const omitidos: MetaConceptoOmitido[] = [
    ...(opciones?.conceptos_omitidos || [])
  ];
  const incluidos: MetaConceptoIncluido[] = [];
  const pendientesSet = new Set<string>();
  const sinClasificarSet = new Set<string>();
  const bomResumen: BomEquipoResumen[] = [];

  // Acumuladores por sección: clave = concepto:::cu
  const mapaSecciones: Record<string, Map<string, AcumuladorLinea>> = {
    acero: new Map(),
    tornilleria: new Map(),
    luz: new Map(),
    pintura: new Map(),
    aire: new Map(),
    truckzone: new Map(),
    piso: new Map(),
    otros: new Map(),
    rines: new Map(),
    extras: new Map(),
    adicionales: new Map(),
    piramide: new Map(),
    indirectos: new Map()
  };

  const acumuladorManoObra = new Map<string, AcumuladorManoObra>();

  let confianzaGlobal: "completa" | "estimada" | "incompleta" = "completa";
  let hayEquiposValidos = false;

  for (const eq of equipos) {
    const { item, costeo, bom } = eq;

    // Validación de elegibilidad
    if (!item.modelo_id) {
      omitidos.push({
        descripcion: item.descripcion || "Equipo sin descripción",
        motivo: "sin configurar"
      });
      continue;
    }

    if (costeo.confianza === "incompleta") {
      omitidos.push({
        descripcion: item.descripcion || "Equipo",
        motivo: "el modelo no tiene costos cargados"
      });
      continue;
    }

    const erroresReales = (bom?.errores || []).filter(
      (e) => !e.startsWith("Falta elegir una opción para el grupo obligatorio")
    );

    if (erroresReales.length > 0) {
      omitidos.push({
        descripcion: item.descripcion || "Equipo",
        motivo: `la configuración tiene errores: ${erroresReales.join(", ")}`
      });
      continue;
    }

    // Equipo elegible
    hayEquiposValidos = true;
    const cantEquipo = item.cantidad > 0 ? item.cantidad : 1;

    incluidos.push({
      descripcion: item.descripcion,
      modelo_id: item.modelo_id,
      cantidad: cantEquipo,
      confianza: costeo.confianza,
      costo: costeo.costo,
      precio_sugerido: costeo.precio_sugerido
    });

    // Peor confianza entre los incluidos: si alguno es estimada, la global es estimada
    if (costeo.confianza === "estimada") {
      confianzaGlobal = "estimada";
    }

    // Pendientes únicos
    for (const p of costeo.pendientes || []) {
      if (p.detalle) {
        pendientesSet.add(p.detalle);
      }
    }

    // Guardar BOM por unidad (sin multiplicar por cantEquipo)
    if (bom) {
      bomResumen.push({
        descripcion: item.descripcion,
        modelo_id: item.modelo_id,
        cantidad: cantEquipo,
        lineas: (bom.lineas || []).map((l) => ({
          material_id: l.material_id,
          nombre: l.nombre,
          unidad: l.unidad,
          cantidad: l.cantidad,
          seccion: l.seccion,
          origen: l.origen || []
        })),
        omitidas: bom.omitidas || [],
        alternativas: bom.alternativas || []
      });
    }

    // Helper para acumular líneas en una sección
    const agregarLinea = (
      seccion: string,
      concepto: string,
      cantPorUnidad: number,
      cu: number,
      esSinPrecio: boolean
    ) => {
      const mapa = mapaSecciones[seccion];
      if (!mapa) return;

      const pzasTotal = cantPorUnidad * cantEquipo;
      const impExacto = cantPorUnidad * cu * cantEquipo;
      const clave = `${concepto}:::${cu}`;

      const existente = mapa.get(clave);
      if (existente) {
        existente.pzas += pzasTotal;
        existente.importeExacto += impExacto;
        if (esSinPrecio) existente.sin_precio = true;
      } else {
        mapa.set(clave, {
          pzas: pzasTotal,
          material: concepto,
          cu,
          sin_precio: esSinPrecio,
          importeExacto: impExacto
        });
      }
    };

    // 1. Acero
    for (const linea of costeo.secciones.acero.lineas || []) {
      const sinPrecio = linea.costo_unitario === 0;
      agregarLinea("acero", linea.concepto, linea.cantidad, linea.costo_unitario, sinPrecio);
    }

    // 2. Kits fijos
    for (const linea of costeo.secciones.kits_fijos.lineas || []) {
      const sec = clasificarKitFijo(linea.seccion);
      const sinPrecio = linea.costo_unitario === 0;
      agregarLinea(sec, linea.concepto, linea.cantidad, linea.costo_unitario, sinPrecio);
    }

    // 3. Opciones
    for (const linea of costeo.secciones.opciones.lineas || []) {
      const sec = clasificarOpcion(linea.origen, sinClasificarSet);
      // Las opciones con importe 0 y cu 0 son sin_precio a menos que sean explícitamente exentas
      let esExenta = false;
      const match = linea.origen.match(/^opcion:[^/]+\/(.+)$/);
      if (match) {
        const oClave = match[1];
        if (oClave.startsWith("sin_") || oClave === "paleta" || oClave === "cliente") {
          esExenta = true;
        }
      }
      const sinPrecio = linea.costo_unitario === 0 && !esExenta;
      agregarLinea(sec, linea.concepto, linea.cantidad, linea.costo_unitario, sinPrecio);
    }

    // 4. Mano de obra (una línea por proceso)
    for (const linea of costeo.secciones.mano_obra.lineas || []) {
      const procesoNombre = linea.concepto.split(" - ")[0].trim();
      const horasTotal = linea.cantidad * cantEquipo;
      const impTotal = linea.cantidad * linea.costo_unitario * cantEquipo;

      const exist = acumuladorManoObra.get(procesoNombre);
      if (exist) {
        exist.horas += horasTotal;
        exist.importeExacto += impTotal;
      } else {
        acumuladorManoObra.set(procesoNombre, {
          proceso: procesoNombre,
          horas: horasTotal,
          importeExacto: impTotal
        });
      }
    }

    // 5. Ajustes manuales -> adicionales
    for (const linea of costeo.secciones.ajustes.lineas || []) {
      agregarLinea("adicionales", linea.concepto, linea.cantidad, linea.costo_unitario, false);
    }
  }

  if (!hayEquiposValidos) {
    confianzaGlobal = "incompleta";
  }

  // Construir secciones del presupuesto
  let conteoSinPrecio = 0;

  const construirSeccion = (secKey: string): PresupuestoSeccion => {
    const mapa = mapaSecciones[secKey];
    if (!mapa || mapa.size === 0) {
      return { items: [], total: 0 };
    }

    let sumaExacta = 0;
    const items: PresupuestoItem[] = [];

    for (const itemAcum of mapa.values()) {
      sumaExacta += itemAcum.importeExacto;
      if (itemAcum.sin_precio) {
        conteoSinPrecio++;
      }
      const itemFinal: PresupuestoItem = {
        pzas: round2(itemAcum.pzas),
        material: itemAcum.material,
        cu: itemAcum.cu,
        importe: round2(itemAcum.pzas * itemAcum.cu)
      };
      if (itemAcum.sin_precio) {
        itemFinal.sin_precio = true;
      }
      items.push(itemFinal);
    }

    return {
      items,
      total: round2(sumaExacta)
    };
  };

  // Construir sección mano de obra agrupada por proceso
  let sumaManoObraExacta = 0;
  const itemsManoObra: PresupuestoItem[] = [];

  for (const mo of acumuladorManoObra.values()) {
    sumaManoObraExacta += mo.importeExacto;
    const cuCalculado = mo.horas > 0 ? round2(mo.importeExacto / mo.horas) : 0;
    itemsManoObra.push({
      pzas: round2(mo.horas),
      material: mo.proceso,
      cu: cuCalculado,
      importe: round2(mo.importeExacto)
    });
  }

  const seccionManoObra: PresupuestoSeccion = {
    items: itemsManoObra,
    total: round2(sumaManoObraExacta)
  };

  const datos: PresupuestoDatos = {
    acero: construirSeccion("acero"),
    piramide: { items: [], total: 0 },
    truckzone: construirSeccion("truckzone"),
    otros: construirSeccion("otros"),
    piso: construirSeccion("piso"),
    extras: construirSeccion("extras"),
    rines: construirSeccion("rines"),
    indirectos: { items: [], total: 0 },
    manoobra: seccionManoObra,
    adicionales: construirSeccion("adicionales"),
    tornilleria: construirSeccion("tornilleria"),
    luz: construirSeccion("luz"),
    aire: construirSeccion("aire"),
    pintura: construirSeccion("pintura")
  };

  // Gran total = suma de los totales de cada sección
  const total_costo = round2(
    (datos.acero.total || 0) +
    (datos.piramide.total || 0) +
    (datos.truckzone.total || 0) +
    (datos.otros.total || 0) +
    (datos.piso.total || 0) +
    (datos.extras.total || 0) +
    (datos.rines.total || 0) +
    (datos.indirectos.total || 0) +
    (datos.manoobra.total || 0) +
    (datos.adicionales.total || 0) +
    (datos.tornilleria?.total || 0) +
    (datos.luz?.total || 0) +
    (datos.aire?.total || 0) +
    (datos.pintura?.total || 0)
  );

  const meta: MetaPresupuesto = {
    origen: "costeo",
    cotizacion_id: opciones?.cotizacion_id || null,
    generado_en: opciones?.generado_en || new Date().toISOString(),
    conceptos_incluidos: incluidos,
    conceptos_omitidos: omitidos,
    pendientes: Array.from(pendientesSet),
    confianza: confianzaGlobal,
    sin_precio: conteoSinPrecio,
    sin_clasificar: Array.from(sinClasificarSet),
    bom: bomResumen
  };

  datos.meta = meta;

  return {
    datos,
    total_costo,
    meta
  };
}
