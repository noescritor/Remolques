export interface Modelo {
  id: string;
  tipo: string;
  largo_ft: number;
  num_ejes: number;
  nombre: string;
}

export interface LineaReceta {
  material_id: string;
  nombre: string;
  unidad: string;
  costo: number | null;
  descripcion: string | null;
  cantidad: number;
  escala: string;
  paso: string | null;
  uso: string | null;
  seccion?: string | null;
  condicion?: any;
}

export interface LineaOpcion {
  opcion_id: string;
  grupo_clave: string;
  opcion_clave: string;
  material_id: string;
  nombre: string;
  unidad: string;
  costo: number | null;
  descripcion: string | null;
  cantidad: number;
  escala: string;
  paso: string;
  rol: string;
  uso: string | null;
}

export interface GrupoOpcion {
  id: string;
  clave: string;
  nombre: string;
  seleccion: string;
  regla: string | null;
  aplica_a?: string[] | null;
  depende_de?: any | null;
  cantidad?: number | null;
  unidad_precio?: string | null;
  medidas?: any | null;
}

export interface Opcion {
  id: string;
  grupo_id: string;
  clave: string;
  nombre: string;
  precio_venta: number;
  clase: string;
  marcas?: string[] | null;
  medidas?: any | null;
  activo?: boolean;
  aliases?: string[] | null;
}

export interface DatosModelo {
  modelo: Modelo;
  receta_base: LineaReceta[];
  grupos: GrupoOpcion[];
  opciones: Opcion[];
  opcion_componentes: LineaOpcion[];
}

export interface Configuracion {
  grupos: Record<string, string | { opcion: string; marca?: string; cantidad?: number } | (string | { opcion: string; marca?: string; cantidad?: number })[]>;
  adicionales?: string[];
}

export interface LineaResultado {
  material_id: string;
  nombre: string;
  cantidad: number;
  unidad: string;
  paso: string[];
  uso: string[];
  seccion: string;
  origen: string[];
}

export interface Resultado {
  lineas: LineaResultado[];
  omitidas: { descripcion: string; texto: string }[];
  alternativas: { reemplaza: string | null; posibles_reemplazos: string[]; sustituto: string; grupo: string }[];
  advertencias: string[];
  errores: string[];
  sin_precio: string[];
  costo_parcial: number;
  completo: boolean;
  secciones_pendientes: string[];
}

export interface AjusteManual {
  concepto: string;
  cantidad: number;
  costo_unitario: number;
}

export interface LineaCosteo {
  concepto: string;
  cantidad: number;
  costo_unitario: number;
  importe: number;
  origen: string;
  seccion?: string;
}

export interface SeccionCosteo {
  total: number;
  lineas: LineaCosteo[];
}

export interface PendienteCosteo {
  tipo: 'sin_precio' | 'opcion_sin_costo' | 'modelo_sin_costos' | 'ganancia_no_definida' | 'variante_supuesta' | 'iva_gondola' | 'costo_no_factura';
  detalle: string;
}

export interface ResultadoCosteo {
  moneda: 'MXN';
  secciones: {
    acero: SeccionCosteo;
    kits_fijos: SeccionCosteo;
    opciones: SeccionCosteo;
    mano_obra: SeccionCosteo;
    ajustes: SeccionCosteo;
  };
  costo: number;
  ganancia: number | null;
  precio_sugerido: number | null;
  margen_sobre_precio: number | null;
  margen_sobre_costo: number | null;
  confianza: 'completa' | 'estimada' | 'incompleta';
  pendientes: PendienteCosteo[];
}

export interface DatosCosteo {
  modelo: Modelo;
  costos_derivados_de?: { id: string; nombre: string } | null;
  receta_acero: {
    material_id: string;
    nombre: string;
    cantidad: number;
    escala: string;
    costo: number | null;
    descripcion: string | null;
  }[];
  costos_modelo: {
    seccion: string;
    concepto: string;
    cantidad: number;
    costo_unitario: number;
    escala: string;
  }[];
  procesos: {
    orden: number;
    proceso: string;
    subproceso: string | null;
    minutos: number;
    tarifa_hora: number;
  }[];
  opcion_costos: {
    grupo_clave: string;
    opcion_clave: string;
    cantidad_base: number;
    escala: string;
    costo_unitario: number;
    fuente?: string;
    producto_id?: string | null;
    costo_desde_producto?: boolean;
    producto_costo?: number | null;
  }[];
  grupos: GrupoOpcion[];
  ganancia: number | null;
}

