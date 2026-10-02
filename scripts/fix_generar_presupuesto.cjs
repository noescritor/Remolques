const fs = require('fs');
let c = fs.readFileSync('src/app/components/Cotizaciones/CotizacionesList.tsx', 'utf8');

c = c.replace(
  'export function CotizacionesList({\n  cotizaciones,\n  loading,\n  onNuevaCotizacion,\n  onVerCotizacion,\n  onDuplicarCotizacion,\n  onEliminarCotizacion\n}: CotizacionesListProps) {',
  'export function CotizacionesList({\n  cotizaciones,\n  loading,\n  onNuevaCotizacion,\n  onVerCotizacion,\n  onDuplicarCotizacion,\n  onEliminarCotizacion,\n  crearPresupuesto\n}: any) {'
);

const newLogic = `
        const prodRes = await fetch(\`https://remolques-remolques-api.gehkp3.easypanel.host/productos/\${item.producto_id}\`);
        const prodData = await prodRes.json();
        // Fallback en caso de que no devuelva tipo_item
        const tipoItem = prodData?.tipo_item || (prodData?.[0]?.tipo_item);
        
        if (tipoItem === 'producto_terminado') {
          // Fetch BOM
          const recetaRes = await fetch(\`https://remolques-remolques-api.gehkp3.easypanel.host/productos/\${item.producto_id}/materiales\`);
          const receta = await recetaRes.json();
          
          if (receta && receta.length > 0) {
            for (const rm of receta) {
              const cant = Number(rm.cantidad) * item.cantidad;
              const mat = rm.material || {};
              const costo = Number(mat.costo || mat.precio_unitario || 0);
              const importe = cant * costo;
              
              requiredMaterials.push({
                pzas: cant.toString(),
                material: mat.nombre || 'Material desconocido',
                cu: costo,
                importe: importe
              });
              totalCosto += importe;
            }
          }
        }
`;

c = c.replace(/const \{ data: prod \} = await supabase[\s\S]*?totalCosto \+= importe;\n\s*\}\n\s*\}\n\s*\}/, newLogic);

c = c.replace(/const \{ error \} = await supabase\.from\('presupuestos'\)\.insert\(payload\);\n\s*if \(error\) throw error;/, 'await crearPresupuesto(payload);');

fs.writeFileSync('src/app/components/Cotizaciones/CotizacionesList.tsx', c);
console.log('Fixed CotizacionesList');
