const fs = require('fs');
const filePath = 'src/app/types/index.ts';
let code = fs.readFileSync(filePath, 'utf-8');

const regex = /export interface OrdenTrabajo \{[\s\S]*?\n\}/;

const extended = `export interface LineaProducto {
  id: string;
  clave: string;
  nombre: string;
  grupo?: string;
  organizacion_id?: string;
}

export interface FaseProduccion {
  id: string;
  linea_producto_id: string;
  orden: number;
  nombre: string;
  organizacion_id?: string;
}

export interface OrdenTrabajo {
  id: string;
  organizacion_id: string;
  cotizacion_id: string;
  cliente_id: string;
  nomenclatura_id: string;
  niv: string | null;
  modelo: string | null;
  tipo_equipo: string;
  caracteristicas: any;
  estado: string;
  fecha_inicio: string | null;
  fecha_fin: string | null;
  created_at: string;
  
  // Kanban extra fields
  linea_producto_id?: string;
  orden_relacionada_id?: string;
  fase_actual_id?: string;
  estado_kanban?: 'pendiente' | 'en_proceso' | 'pausada' | 'incompleta' | 'en_espera' | 'completada';
  material_faltante?: string;

  cliente?: Cliente;
  cotizacion?: Cotizacion;
  linea?: LineaProducto;
  fase?: FaseProduccion;
}`;

code = code.replace(regex, extended);

fs.writeFileSync(filePath, code, 'utf-8');
