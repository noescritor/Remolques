const fs = require('fs');
const filePath = 'src/app/hooks/useSupabaseData.ts';
let code = fs.readFileSync(filePath, 'utf-8');

// 1. Imports
code = code.replace(/OrdenTrabajo/, "OrdenTrabajo, Presupuesto");

// 2. State
code = code.replace(
  "const [ordenesTrabajo, setOrdenesTrabajo] = useState<OrdenTrabajo[]>([]);",
  "const [ordenesTrabajo, setOrdenesTrabajo] = useState<OrdenTrabajo[]>([]);\n  const [presupuestos, setPresupuestos] = useState<Presupuesto[]>([]);"
);

// 3. Fetch
const fetchStr = "setOrdenesTrabajo(Array.isArray(ordenesReq) ? ordenesReq : []);";
code = code.replace(
  fetchStr,
  fetchStr + "\n\n      const presuReq = await fetchJson('presupuestos', `${BASE_URL}/presupuestos`, token).catch(() => []);\n      setPresupuestos(Array.isArray(presuReq) ? presuReq : []);"
);

// 4. CRUD
const crud = `
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
`;
code = code.replace(
  "const generarOrdenesDesdeCotizacion",
  crud + "\n  const generarOrdenesDesdeCotizacion"
);

// 5. Returns
code = code.replace(
  "generarOrdenesDesdeCotizacion,",
  "generarOrdenesDesdeCotizacion,\n    presupuestos,\n    crearPresupuesto,\n    actualizarPresupuesto,\n    eliminarPresupuesto,"
);

fs.writeFileSync(filePath, code, 'utf-8');
