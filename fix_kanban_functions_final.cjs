const fs = require('fs');
const filePath = 'src/app/hooks/useSupabaseData.ts';
let code = fs.readFileSync(filePath, 'utf-8');

const injection = `
  const moverOrdenKanban = async (id: string, fase_actual_id: string | null, estado_kanban: string) => {
    try {
      await sendJson('mover orden kanban', \`\${BASE_URL}/produccion/ordenes/\${id}/mover\`, token, {
        method: 'PUT',
        body: JSON.stringify({ fase_actual_id, estado_kanban })
      });
      const ordenesActualizadas = await fetchJson('ordenes', \`\${BASE_URL}/ordenes-trabajo\`, token);
      setOrdenesTrabajo(ordenesActualizadas);
    } catch (error) {
      console.error('Error moving orden kanban:', error);
      throw error;
    }
  };

  const actualizarMaterialFaltante = async (id: string, material_faltante: string | null) => {
    try {
      await sendJson('actualizar material kanban', \`\${BASE_URL}/produccion/ordenes/\${id}/material\`, token, {
        method: 'PUT',
        body: JSON.stringify({ material_faltante })
      });
      const ordenesActualizadas = await fetchJson('ordenes', \`\${BASE_URL}/ordenes-trabajo\`, token);
      setOrdenesTrabajo(ordenesActualizadas);
    } catch (error) {
      console.error('Error updating material kanban:', error);
      throw error;
    }
  };

  const importarExcelKanban = async (payload: any) => {
    try {
      await sendJson('importar excel kanban', \`\${BASE_URL}/produccion/import\`, token, {
        method: 'POST',
        body: JSON.stringify(payload)
      });
      await loadData();
    } catch (error) {
      console.error('Error importing excel kanban:', error);
      throw error;
    }
  };
`;

code = code.replace(/  return \{/g, injection + "\n  return {");

fs.writeFileSync(filePath, code, 'utf-8');
