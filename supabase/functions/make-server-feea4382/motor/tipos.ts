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
  paso: string;
  uso: string | null;
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
  grupos: Record<string, string | { opcion: string; marca?: string; cantidad?: number }>;
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
