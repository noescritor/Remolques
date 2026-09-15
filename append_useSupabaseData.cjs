const fs = require('fs');
const filePath = 'src/app/hooks/useSupabaseData.ts';
let code = fs.readFileSync(filePath, 'utf-8');

// Import OrdenTrabajo
code = code.replace(/CompraProveedor, CotizacionEvento/, "CompraProveedor, CotizacionEvento, OrdenTrabajo");

// Add state
const stateHook = `
  const [pagosProveedor, setPagosProveedor] = useState<any[]>([]);
  const [ordenesTrabajo, setOrdenesTrabajo] = useState<OrdenTrabajo[]>([]);
`;
code = code.replace(/const \[pagosProveedor, setPagosProveedor\] = useState<any\[\]>\(\[\]\);/, stateHook);

// Fetching
const fetchLogic = `
      const ordenesReq = await fetchJson('ordenes', \`\${BASE_URL}/ordenes-trabajo\`, token).catch(() => []);
      setOrdenesTrabajo(Array.isArray(ordenesReq) ? ordenesReq : []);
`;
code = code.replace(/setPagosProveedor\(Array.isArray\(pagosReq\) \? pagosReq : \[\]\);/, "setPagosProveedor(Array.isArray(pagosReq) ? pagosReq : []);\n" + fetchLogic);

// CRUD
const crudLogic = `
  const actualizarOrdenTrabajo = async (id: string, updates: Partial<OrdenTrabajo>) => {
    try {
      const result = await sendJson('actualizar orden', \`\${BASE_URL}/ordenes-trabajo/\${id}\`, token, {
        method: 'PUT',
        body: JSON.stringify(updates)
      });
      setOrdenesTrabajo(prev => prev.map(o => o.id === id ? { ...o, ...result } : o));
      return result;
    } catch (error) {
      console.error('Error updating orden_trabajo:', error);
      throw error;
    }
  };

  const generarOrdenesDesdeCotizacion = async (cotizacionId: string) => {
    try {
      const results = await sendJson('generar ordenes', \`\${BASE_URL}/cotizaciones/\${cotizacionId}/generar-ordenes\`, token, {
        method: 'POST'
      });
      // Volver a cargar para traer las relaciones (cliente, cotizacion)
      const ordenesReq = await fetchJson('ordenes', \`\${BASE_URL}/ordenes-trabajo\`, token).catch(() => []);
      setOrdenesTrabajo(Array.isArray(ordenesReq) ? ordenesReq : []);
      return results;
    } catch (error) {
      console.error('Error generating ordenes:', error);
      throw error;
    }
  };
`;
const returnVars = `
    ordenesTrabajo,
    actualizarOrdenTrabajo,
    generarOrdenesDesdeCotizacion,
`;

const insertIndex = code.lastIndexOf("return {");
if (insertIndex !== -1) {
  code = code.slice(0, insertIndex) + crudLogic + code.slice(insertIndex);
  code = code.replace(/return \{/, "return {\n" + returnVars);
  fs.writeFileSync(filePath, code, 'utf-8');
  console.log("useSupabaseData updated");
} else {
  console.log("Could not find 'return {'");
}
