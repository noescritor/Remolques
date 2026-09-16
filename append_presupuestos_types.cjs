const fs = require('fs');
const filePath = 'src/app/types/index.ts';
let code = fs.readFileSync(filePath, 'utf-8');
code += `
export interface PresupuestoItem {
  pzas: number | string;
  material: string;
  cu: number;
  importe: number;
}

export interface PresupuestoSeccion {
  items: PresupuestoItem[];
  total: number;
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
}

export interface Presupuesto {
  id: string;
  organizacion_id: string;
  cliente_id: string | null;
  folio: string;
  nomenclatura_id: string | null;
  fecha: string;
  concepto: string | null;
  datos: PresupuestoDatos;
  total_costo: number;
  precio_venta: number;
  created_at: string;
  cliente?: Cliente;
}
`;
fs.writeFileSync(filePath, code, 'utf-8');
