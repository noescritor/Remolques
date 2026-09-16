const fs = require('fs');
const filePath = 'src/app/hooks/useSupabaseData.ts';
let code = fs.readFileSync(filePath, 'utf-8');

// ADD STATES
const stateInjection = `  const [ordenesTrabajo, setOrdenesTrabajo] = useState<OrdenTrabajo[]>([]);
  const [lineasProducto, setLineasProducto] = useState<any[]>([]);
  const [fasesProduccion, setFasesProduccion] = useState<any[]>([]);`;

code = code.replace(/  const \[ordenesTrabajo, setOrdenesTrabajo\] = useState<OrdenTrabajo\[\]>\(\[\]\);/, stateInjection);

// ADD TO LOADDATA
const loadInjection = `        const ordenesData = await fetchJson('ordenes', \`\${BASE_URL}/ordenes-trabajo\`, token).catch(() => []);
        const lineasData = await fetchJson('lineas', \`\${BASE_URL}/produccion/lineas\`, token).catch(() => []);
        const fasesData = await fetchJson('fases', \`\${BASE_URL}/produccion/fases\`, token).catch(() => []);`;

code = code.replace(/        const ordenesData = await fetchJson\('ordenes', `\$\{BASE_URL\}\/ordenes-trabajo`, token\)\.catch\(\(\) => \[\]\);/, loadInjection);

const setInjection = `        setOrdenesTrabajo(Array.isArray(ordenesData) ? ordenesData : []);
        setLineasProducto(Array.isArray(lineasData) ? lineasData : []);
        setFasesProduccion(Array.isArray(fasesData) ? fasesData : []);`;

code = code.replace(/        setOrdenesTrabajo\(Array\.isArray\(ordenesData\) \? ordenesData : \[\]\);/, setInjection);

// ADD FUNCTIONS
const funcInjection = `  const actualizarOrdenTrabajo = async (id: string, orden: Partial<OrdenTrabajo>) => {
      try {
        const resultado = await sendJson('actualizar orden_trabajo', \`\${BASE_URL}/ordenes-trabajo/\${id}\`, token, {
          method: 'PUT',
          body: JSON.stringify(orden)
        });
        
        // Reload all orders to get updated relationships
        const ordenesActualizadas = await fetchJson('ordenes', \`\${BASE_URL}/ordenes-trabajo\`, token);
        setOrdenesTrabajo(ordenesActualizadas);
        return resultado;
      } catch (error) {
        console.error('Error updating orden_trabajo:', error);
        throw error;
      }
    };

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
        // reload everything
        await loadData();
      } catch (error) {
        console.error('Error importing excel kanban:', error);
        throw error;
      }
    };
`;

code = code.replace(/  const actualizarOrdenTrabajo = async[\s\S]*?throw error;\n      \}\n    \};/, funcInjection);

// ADD TO EXPORTS
const exportInjection = `    // Producción
    ordenesTrabajo,
    lineasProducto,
    fasesProduccion,
    actualizarOrdenTrabajo,
    moverOrdenKanban,
    actualizarMaterialFaltante,
    importarExcelKanban,`;

code = code.replace(/    \/\/ Producción\n    ordenesTrabajo,\n    actualizarOrdenTrabajo,/, exportInjection);

fs.writeFileSync(filePath, code, 'utf-8');
