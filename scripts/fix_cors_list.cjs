const fs = require('fs');
let c = fs.readFileSync('src/app/components/Cotizaciones/CotizacionesList.tsx', 'utf8');

const regex = /const handleGenerarPresupuesto = async \(cotizacion: Cotizacion\) => \{[\s\S]*?setGenerandoPresupuesto\(false\);\n  \};/;

const newLogic = `const handleGenerarPresupuesto = async (cotizacion: Cotizacion) => {
    try {
      setGenerandoPresupuesto(true);
      toast.info('Extrayendo recetas BOM para generar presupuesto...');

      const token = (await supabase.auth.getSession()).data.session?.access_token;
      const orgId = (await supabase.auth.getUser()).data.user?.user_metadata?.organizacion_id || localStorage.getItem('org_id');
      const API_URL = import.meta.env.VITE_SUPABASE_API_URL;

      if (!token) throw new Error('No hay sesión activa.');

      const mainItems = cotizacion.items;
      if (!mainItems || mainItems.length === 0) {
        toast.error('La cotización no tiene items.');
        return;
      }

      // Fetch all products to know which are producto_terminado
      const prodRes = await fetch(\`\${API_URL}/productos\`, {
        headers: { 'Authorization': \`Bearer \${token}\`, 'x-org-id': orgId }
      });
      const allProductos = await prodRes.json();

      const requiredMaterials: { pzas: string, material: string, cu: number, importe: number }[] = [];
      let totalCosto = 0;

      for (const item of mainItems) {
        if (!item.producto_id) continue;
        
        const prod = allProductos.find((p: any) => p.id === item.producto_id);
        if (prod && prod.tipo_item === 'producto_terminado') {
          // Fetch BOM using the Deno proxy to avoid CORS
          const req = await fetch(\`\${API_URL}/productos/\${item.producto_id}/materiales\`, {
            headers: { 'Authorization': \`Bearer \${token}\`, 'x-org-id': orgId }
          });
          if (!req.ok) continue;
          const receta = await req.json();
            
          if (receta && receta.length > 0) {
            for (const rm of receta) {
              const cant = Number(rm.cantidad) * item.cantidad;
              // La API devuelve material en material_id (que est expandido por Supabase)
              const materialData = rm.material || {};
              const costo = Number(materialData.costo || materialData.precio_unitario || 0);
              const importe = cant * costo;
              
              requiredMaterials.push({
                pzas: cant.toString(),
                material: materialData.nombre || 'Desconocido',
                cu: costo,
                importe: importe
              });
              totalCosto += importe;
            }
          }
        }
      }

      if (requiredMaterials.length === 0) {
        toast.error('Ninguno de los items de la cotización tiene una receta (BOM) configurada en la BD.');
        return;
      }

      // Crear payload del presupuesto
      const datos = JSON.parse(JSON.stringify(defaultPresupuestoDatos));
      for (const key of Object.keys(datos)) {
        datos[key].items = [];
        datos[key].total = 0;
      }
      datos.acero.items = requiredMaterials;
      datos.acero.total = totalCosto;

      const payload = {
        organizacion_id: cotizacion.organizacion_id,
        cliente_id: cotizacion.cliente_id,
        folio: 'PRE-' + cotizacion.folio,
        fecha: new Date().toISOString().split('T')[0],
        concepto: 'Presupuesto basado en Cotización ' + cotizacion.folio,
        datos: datos,
        total_costo: totalCosto,
        precio_venta: cotizacion.total_cotizacion || 0
      };

      // Enviar a la API proxy
      const postReq = await fetch(\`\${API_URL}/presupuestos\`, {
        method: 'POST',
        headers: {
          'Authorization': \`Bearer \${token}\`,
          'x-org-id': orgId,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(payload)
      });
      
      if (!postReq.ok) {
        throw new Error('Error al guardar presupuesto en el servidor');
      }

      toast.success('Presupuesto de producción generado con éxito. Revisa el módulo de Presupuestos.');

    } catch (err: any) {
      console.error(err);
      toast.error('Error generando presupuesto: ' + err.message);
    } finally {
      setGenerandoPresupuesto(false);
    }
  };`;

c = c.replace(regex, newLogic);

fs.writeFileSync('src/app/components/Cotizaciones/CotizacionesList.tsx', c);
console.log('Replaced logic in CotizacionesList');
