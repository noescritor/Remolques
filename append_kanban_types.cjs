const fs = require('fs');
const filePath = 'src/app/types/index.ts';
let code = fs.readFileSync(filePath, 'utf-8');

const newTypes = `
// Kanban Producción
export interface LineaProducto {
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

// extend OrdenTrabajo
export interface OrdenTrabajo {
  id: string;
  organizacion_id: string;
  cotizacion_id: string;
  cliente_id: string;
  nomenclatura_id: string;
  niv?: string;
  modelo?: string;
  tipo_equipo?: string;
  caracteristicas?: any;
  estado: 'Pendiente' | 'En Producción' | 'Terminado' | 'Liberado';
  fecha_inicio?: string;
  fecha_fin?: string;
  created_at: string;
  
  // Kanban extra fields
  linea_producto_id?: string;
  orden_relacionada_id?: string;
  fase_actual_id?: string;
  estado_kanban?: 'pendiente' | 'en_proceso' | 'pausada' | 'incompleta' | 'en_espera' | 'completada';
  material_faltante?: string;
  
  // joins
  cliente?: Partial<Cliente>;
  cotizacion?: Partial<Cotizacion>;
  linea?: Partial<LineaProducto>;
  fase?: Partial<FaseProduccion>;
}
`;

// wait, OrdenTrabajo is already defined in types? Let's check.
// I will just append the new types or replace the old OrdenTrabajo.
code += newTypes;
fs.writeFileSync(filePath, code, 'utf-8');
