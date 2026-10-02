const fs = require('fs');
let c = fs.readFileSync('src/app/components/Cotizaciones/CotizacionesList.tsx', 'utf8');

const target = "for (const item of mainItems) {";
const targetEnd = "if (requiredMaterials.length === 0) {";

const idx1 = c.indexOf(target);
const idx2 = c.indexOf(targetEnd);

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
        
        // Use proxy to bypass CORS
        const resProd = await fetch(\`\${BASE_URL}/productos/\${item.producto_id}\`, { headers }).catch(() => null);
        let esTerminado = false;
        
        if (resProd && resProd.ok) {
           const pData = await resProd.json();
           esTerminado = (pData?.tipo_item === 'producto_terminado' || pData?.[0]?.tipo_item === 'producto_terminado');
        } else {
           // Si falla la API proxy, asumimos que s lo es para intentar sacar la receta
           esTerminado = true;
        }

        if (esTerminado) {
          // Fetch BOM via proxy
          const recetaRes = await fetch(\`\${BASE_URL}/productos/\${item.producto_id}/materiales\`, { headers });
          if (recetaRes.ok) {
            const receta = await recetaRes.json();
            if (receta && receta.length > 0) {
              for (const rm of receta) {
                const cant = Number(rm.cantidad) * item.cantidad;
                const mat = rm.material || {};
                const costo = Number(mat.costo || mat.precio_unitario || 0);
                const importe = cant * costo;
                
                requiredMaterials.push({
                  pzas: cant.toString(),
                  material: mat.nombre || 'Material',
                  cu: costo,
                  importe: importe
                });
                totalCosto += importe;
              }
            }
          }
        }
      }

      `;

c = c.substring(0, idx1) + newLogic + c.substring(idx2);

c = c.replace(
  /const \{ error \} = await supabase\.from\('presupuestos'\)\.insert\(payload\);\n\s*if \(error\) throw error;/,
  'if (crearPresupuesto) { await crearPresupuesto(payload); } else { const { error } = await supabase.from("presupuestos").insert(payload); if (error) throw error; }'
);

fs.writeFileSync('src/app/components/Cotizaciones/CotizacionesList.tsx', c);
console.log('Fixed exactly!');
