const fs = require('fs');
let c = fs.readFileSync('src/app/components/Cotizaciones/CotizacionesList.tsx', 'utf8');

c = c.replace(
  'interface CotizacionesListProps {',
  'interface CotizacionesListProps {\n  productos?: any[];\n  crearPresupuesto?: any;'
);

c = c.replace(
  'onEliminarCotizacion\n}: CotizacionesListProps) {',
  'onEliminarCotizacion,\n  productos = [],\n  crearPresupuesto\n}: CotizacionesListProps) {'
);

const newLogic = `
        const { data: { session } } = await supabase.auth.getSession();
        const token = session?.access_token;
        const headers = {
          'Content-Type': 'application/json',
          ...(token ? { 'Authorization': \`Bearer \${token}\` } : {})
        };
        const BASE_URL = 'https://remolques-remolques-api.gehkp3.easypanel.host';

        for (const item of mainItems) {
          if (!item.producto_id) continue;
          
          const prod = productos.find(p => p.id === item.producto_id);
          if (prod && prod.tipo_item === 'producto_terminado') {
            // Fetch BOM from proxy to avoid CORS
            const res = await fetch(\`\${BASE_URL}/productos/\${item.producto_id}/materiales\`, { headers });
            if (!res.ok) throw new Error('Error al cargar materiales');
            const receta = await res.json();
              
            if (receta && receta.length > 0) {
              for (const rm of receta) {
                const cant = Number(rm.cantidad) * item.cantidad;
                const mat = rm.material || {};
                const costo = Number(mat.costo || mat.precio_unitario || 0);
                const importe = cant * costo;
                
                requiredMaterials.push({
                  pzas: cant.toString(),
                  material: mat.nombre || 'Desconocido',
                  cu: costo,
                  importe: importe
                });
                totalCosto += importe;
              }
            }
          }
        }
`;

c = c.replace(/for \(const item of mainItems\) \{[\s\S]*?totalCosto \+= importe;\n\s*\}\n\s*\}\n\s*\}\n\s*\}/, newLogic);

c = c.replace(
  /const \{ error \} = await supabase\.from\('presupuestos'\)\.insert\(payload\);\n\s*if \(error\) throw error;/,
  'if (crearPresupuesto) { await crearPresupuesto(payload); } else { const { error } = await supabase.from("presupuestos").insert(payload); if (error) throw error; }'
);

fs.writeFileSync('src/app/components/Cotizaciones/CotizacionesList.tsx', c);
console.log('Fixed CotizacionesList completely');
