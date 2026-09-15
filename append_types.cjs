const fs = require('fs');
const filePath = 'src/app/types/index.ts';
let code = fs.readFileSync(filePath, 'utf-8');
code += `
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
  cliente?: Cliente;
  cotizacion?: Cotizacion;
}
`;
fs.writeFileSync(filePath, code, 'utf-8');
