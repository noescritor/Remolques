const fs = require('fs');
const filePath = 'src/app/hooks/useSupabaseData.ts';
let code = fs.readFileSync(filePath, 'utf-8');

// Import
code = code.replace(/OrdenTrabajo/, "OrdenTrabajo, Presupuesto");

// Add state
const stateHook = `
  const [ordenesTrabajo, setOrdenesTrabajo] = useState<OrdenTrabajo[]>([]);
  const [presupuestos, setPresupuestos] = useState<Presupuesto[]>([]);
`;
code = code.replace(/const \[ordenesTrabajo, setOrdenesTrabajo\] = useState<OrdenTrabajo\[\]>\(\[\]\);/, stateHook);

// Add global fetch (find where ordenes-trabajo is fetched during load)
// It is around line 287 (inside loadData function)
const fetchLogic = `
      const ordenesReq = await fetchJson('ordenes', \`\${BASE_URL}/ordenes-trabajo\`, token).catch(() => []);
      setOrdenesTrabajo(Array.isArray(ordenesReq) ? ordenesReq : []);

      const presuReq = await fetchJson('presupuestos', \`\${BASE_URL}/presupuestos\`, token).catch(() => []);
      setPresupuestos(Array.isArray(presuReq) ? presuReq : []);
`;
code = code.replace(
  /const ordenesReq = await fetchJson\('ordenes', `\$\{BASE_URL\}\/ordenes-trabajo`, token\)\.catch\(\(\) => \[\]\);\n\s*setOrdenesTrabajo\(Array\.isArray\(ordenesReq\) \? ordenesReq : \[\]\);/,
  fetchLogic
);

// CRUD
const crudLogic = `
  const crearPresupuesto = async (presupuesto: Partial<Presupuesto>) => {
    try {
      const result = await sendJson('crear presupuesto', \`\${BASE_URL}/presupuestos\`, token, {
        method: 'POST',
        body: JSON.stringify(presupuesto)
      });
      setPresupuestos([result, ...presupuestos]);
      toast.success('Presupuesto creado');
      return result;
    } catch (error: any) {
      toast.error('Error al crear presupuesto', { description: error.message });
      throw error;
    }
  };

  const actualizarPresupuesto = async (id: string, updates: Partial<Presupuesto>) => {
    try {
      const result = await sendJson('actualizar presupuesto', \`\${BASE_URL}/presupuestos/\${id}\`, token, {
        method: 'PUT',
        body: JSON.stringify(updates)
      });
      setPresupuestos(prev => prev.map(p => p.id === id ? { ...p, ...result } : p));
      toast.success('Presupuesto actualizado');
      return result;
    } catch (error: any) {
      toast.error('Error al actualizar presupuesto', { description: error.message });
      throw error;
    }
  };

  const eliminarPresupuesto = async (id: string) => {
    try {
      await sendJson('eliminar presupuesto', \`\${BASE_URL}/presupuestos/\${id}\`, token, { method: 'DELETE' });
      setPresupuestos(prev => prev.filter(p => p.id !== id));
      toast.success('Presupuesto eliminado');
    } catch (error: any) {
      toast.error('Error al eliminar presupuesto', { description: error.message });
      throw error;
    }
  };

  const generarOrdenesDesdeCotizacion = async (cotizacionId: string) => {
`;
code = code.replace(/const generarOrdenesDesdeCotizacion = async \(cotizacionId: string\) => \{/, crudLogic);

// Add to return block (at the very bottom)
const returnVars = `
    ordenesTrabajo,
    actualizarOrdenTrabajo,
    generarOrdenesDesdeCotizacion,
    presupuestos,
    crearPresupuesto,
    actualizarPresupuesto,
    eliminarPresupuesto,
`;
code = code.replace(/ordenesTrabajo,\s*actualizarOrdenTrabajo,\s*generarOrdenesDesdeCotizacion,/, returnVars);

fs.writeFileSync(filePath, code, 'utf-8');
