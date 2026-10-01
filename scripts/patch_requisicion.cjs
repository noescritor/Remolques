const fs = require('fs');
let c = fs.readFileSync('supabase/functions/make-server-feea4382/index.ts', 'utf8');
const func = `
async function calcularRequisicion(supabase, cotizacionId, orgId) {
  const { data: cot } = await supabase.from('cotizaciones').select('*').eq('id', cotizacionId).single();
  if (!cot || !cot.items) return [];
  const { data: inventario } = await supabase.from('productos').select('id, stock_actual, stock_reservado').eq('organizacion_id', orgId);
  const invMap = new Map();
  if (inventario) {
    inventario.forEach((p) => {
      invMap.set(p.id, (p.stock_actual || 0) - (p.stock_reservado || 0));
    });
  }
  const required = new Map();
  for (const item of cot.items) {
    // If CPQ sub_items exist, use them directly
    if (item.sub_items && item.sub_items.length > 0) {
      for (const sub of item.sub_items) {
        const qty = Number(sub.cantidad) * Number(item.cantidad);
        required.set(sub.material_id, (required.get(sub.material_id) || 0) + qty);
      }
    } else if (item.producto_id) {
      // Fallback to static BOM
      const { data: receta } = await supabase.from('producto_materiales').select('material_id, cantidad').eq('producto_id', item.producto_id);
      if (receta) {
        for (const rm of receta) {
          const qty = Number(rm.cantidad) * Number(item.cantidad);
          required.set(rm.material_id, (required.get(rm.material_id) || 0) + qty);
        }
      }
    }
  }
  const result = [];
  for (const [matId, cantReq] of required.entries()) {
    const disp = invMap.get(matId) || 0;
    const faltante = Math.max(0, cantReq - disp);
    const { data: prod } = await supabase.from('productos').select('nombre, unidad, costo').eq('id', matId).single();
    if (prod) {
      result.push({
        material_id: matId,
        material_nombre: prod.nombre,
        material_unidad: prod.unidad,
        requerido: cantReq,
        disponible: disp,
        faltante: faltante,
        costo_unitario: prod.costo || 0,
        costo_total_faltante: faltante * (prod.costo || 0)
      });
    }
  }
  return result;
}
`;
c = c.replace('const app = new Hono();', func + '\nconst app = new Hono();');
fs.writeFileSync('supabase/functions/make-server-feea4382/index.ts', c);
console.log('Fixed backend function!');
