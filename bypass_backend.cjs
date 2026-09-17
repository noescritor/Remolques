const fs = require('fs');
const filePath = 'src/app/hooks/useSupabaseData.ts';
let code = fs.readFileSync(filePath, 'utf-8');

// Replace the lineasData and fasesData fetch calls
const targetFetch = `
        const ordenesData = await fetchJson('ordenes', \`\${BASE_URL}/ordenes-trabajo\`, token).catch(() => []);
        const lineasData = await fetchJson('lineas', \`\${BASE_URL}/produccion/lineas\`, token).catch(() => []);
        const fasesData = await fetchJson('fases', \`\${BASE_URL}/produccion/fases\`, token).catch(() => []);
`;

const replaceFetch = `
        const ordenesData = await fetchJson('ordenes', \`\${BASE_URL}/ordenes-trabajo\`, token).catch(() => []);
        
        // Fetch directamente de Supabase para evitar problema con el backend desactualizado
        const { data: lineasData } = await supabase.from('lineas_producto').select('*').eq('organizacion_id', organizacionData.id).order('nombre');
        const { data: fasesData } = await supabase.from('fases_produccion').select('*').eq('organizacion_id', organizacionData.id).order('orden');
`;

code = code.replace(/        const ordenesData = await fetchJson\('ordenes', `\$\{BASE_URL\}\/ordenes-trabajo`, token\)\.catch\(\(\) => \[\]\);\s*const lineasData = await fetchJson\('lineas', `\$\{BASE_URL\}\/produccion\/lineas`, token\)\.catch\(\(\) => \[\]\);\s*const fasesData = await fetchJson\('fases', `\$\{BASE_URL\}\/produccion\/fases`, token\)\.catch\(\(\) => \[\]\);/, replaceFetch);

// Now patch the functions: moverOrdenKanban, actualizarMaterialFaltante
const funcMover = `
  const moverOrdenKanban = async (id: string, fase_actual_id: string | null, estado_kanban: string) => {
    try {
      // By-pass the backend
      const { error } = await supabase
        .from('ordenes_trabajo')
        .update({ fase_actual_id, estado_kanban, updated_at: new Date().toISOString() })
        .eq('id', id);
        
      if (error) throw error;
      
      if (fase_actual_id) {
        await supabase.from('historial_fases').insert({
          orden_trabajo_id: id,
          fase_id: fase_actual_id,
          estado: 'en_proceso',
          organizacion_id: organizacion.id
        });
      }

      const ordenesActualizadas = await fetchJson('ordenes', \`\${BASE_URL}/ordenes-trabajo\`, token);
      setOrdenesTrabajo(ordenesActualizadas);
    } catch (error) {
      console.error('Error moving orden kanban:', error);
      throw error;
    }
  };
`;

code = code.replace(/  const moverOrdenKanban = async \(id: string, fase_actual_id: string \| null, estado_kanban: string\) => \{[\s\S]*?console\.error\('Error moving orden kanban:', error\);\s*throw error;\s*\}\s*\};/, funcMover);


const funcMaterial = `
  const actualizarMaterialFaltante = async (id: string, material_faltante: string | null) => {
    try {
      const { error } = await supabase
        .from('ordenes_trabajo')
        .update({ 
          material_faltante, 
          estado_kanban: material_faltante ? 'material_faltante' : 'en_proceso',
          updated_at: new Date().toISOString()
        })
        .eq('id', id);
        
      if (error) throw error;

      const ordenesActualizadas = await fetchJson('ordenes', \`\${BASE_URL}/ordenes-trabajo\`, token);
      setOrdenesTrabajo(ordenesActualizadas);
    } catch (error) {
      console.error('Error updating material kanban:', error);
      throw error;
    }
  };
`;

code = code.replace(/  const actualizarMaterialFaltante = async \(id: string, material_faltante: string \| null\) => \{[\s\S]*?console\.error\('Error updating material kanban:', error\);\s*throw error;\s*\}\s*\};/, funcMaterial);


fs.writeFileSync(filePath, code, 'utf-8');
