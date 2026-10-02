const fs = require('fs');
let c = fs.readFileSync('src/app/components/Cotizaciones/CotizacionesTableModern.tsx', 'utf8');

c = c.replace('import { MoreVertical, Edit2, Copy, Trash2, FileText } from \'lucide-react\';', 
  'import { MoreVertical, Edit2, Copy, Trash2, FileText, ClipboardList } from \'lucide-react\';');

c = c.replace('onDuplicarCotizacion: (id: string) => void;', 
  'onDuplicarCotizacion: (id: string) => void;\n  onGenerarPresupuesto?: (cotizacion: Cotizacion) => void;');

const dropdownItem = `
                    {onGenerarPresupuesto && (
                      <DropdownMenuItem onClick={() => onGenerarPresupuesto(cotizacion)}>
                        <ClipboardList className="mr-2 h-4 w-4" />
                        Generar Presupuesto
                      </DropdownMenuItem>
                    )}
`;

// There are two DropdownMenus (mobile and desktop)
c = c.replace(/<DropdownMenuItem onClick=\{\(\) => onVerCotizacion\(cotizacion\.id\)\}>/g, 
  dropdownItem + '<DropdownMenuItem onClick={() => onVerCotizacion(cotizacion.id)}>');

fs.writeFileSync('src/app/components/Cotizaciones/CotizacionesTableModern.tsx', c);
console.log('Patched TableModern');
