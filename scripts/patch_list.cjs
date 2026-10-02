const fs = require('fs');
let c = fs.readFileSync('src/app/components/Cotizaciones/CotizacionesList.tsx', 'utf8');

const importSupabase = `import { supabase } from '../../utils/supabase/client';
import { toast } from 'sonner';
import { defaultPresupuestoDatos } from '../Presupuestos/presupuestoTemplate';`;

c = c.replace("import { CotizacionesTableModern } from './CotizacionesTableModern';", 
  "import { CotizacionesTableModern } from './CotizacionesTableModern';\n" + importSupabase);

const handlerCode = `
  const [generandoPresupuesto, setGenerandoPresupuesto] = useState(false);

  const handleGenerarPresupuesto = async (cotizacion: Cotizacion) => {
    try {
      setGenerandoPresupuesto(true);
      toast.info('Extrayendo recetas BOM para generar presupuesto...');

      // Find the first producto_terminado in the quote items
      const mainItems = cotizacion.items;
      if (!mainItems || mainItems.length === 0) {
        toast.error('La cotización no tiene items.');
        return;
      }

      // We will create a budget for the first finished product (or merge them)
      // For simplicity, let's just grab all materials required for this quote
      const requiredMaterials: { pzas: string, material: string, cu: number, importe: number }[] = [];
      let totalCosto = 0;

      for (const item of mainItems) {
        if (!item.producto_id) continue;
        
        const { data: prod } = await supabase.from('productos').select('tipo_item').eq('id', item.producto_id).single();
        if (prod && prod.tipo_item === 'producto_terminado') {
          // Fetch BOM
          const { data: receta } = await supabase.from('producto_materiales')
            .select('cantidad, material:productos(id, nombre, costo, precio_unitario)')
            .eq('producto_id', item.producto_id);
            
          if (receta && receta.length > 0) {
            for (const rm of receta) {
              const cant = Number(rm.cantidad) * item.cantidad;
              const costo = Number((rm.material as any).costo || (rm.material as any).precio_unitario || 0);
              const importe = cant * costo;
              
              requiredMaterials.push({
                pzas: cant.toString(),
                material: (rm.material as any).nombre,
                cu: costo,
                importe: importe
              });
              totalCosto += importe;
            }
          }
        }
      }

      if (requiredMaterials.length === 0) {
        toast.error('Ninguno de los items de la cotización tiene una receta (BOM) configurada en la BD.');
        return;
      }

      // Create new presupuesto payload
      const datos = JSON.parse(JSON.stringify(defaultPresupuestoDatos));
      // Empty out the default template and dump our custom BOM into 'acero' to show it cleanly
      for (const key of Object.keys(datos)) {
        datos[key].items = [];
        datos[key].total = 0;
      }
      datos.acero.items = requiredMaterials;
      datos.acero.total = totalCosto;

      const payload = {
        organizacion_id: cotizacion.organizacion_id,
        cliente_id: cotizacion.cliente_id,
        folio: 'PRE-' + cotizacion.folio,
        fecha: new Date().toISOString().split('T')[0],
        concepto: 'Presupuesto basado en Cotización ' + cotizacion.folio,
        datos: datos,
        total_costo: totalCosto,
        precio_venta: cotizacion.total_cotizacion || 0
      };

      const { error } = await supabase.from('presupuestos').insert(payload);
      if (error) throw error;

      toast.success('Presupuesto de producción generado con éxito. Revisa el módulo de Presupuestos.');

    } catch (err: any) {
      console.error(err);
      toast.error('Error generando presupuesto: ' + err.message);
    } finally {
      setGenerandoPresupuesto(false);
    }
  };
`;

c = c.replace('const cotizacionesSeguras =', handlerCode + '\n  const cotizacionesSeguras =');

c = c.replace('<CotizacionesTableModern', '<CotizacionesTableModern\n            onGenerarPresupuesto={handleGenerarPresupuesto}');

fs.writeFileSync('src/app/components/Cotizaciones/CotizacionesList.tsx', c);
console.log('CotizacionesList patched!');
