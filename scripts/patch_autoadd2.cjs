const fs = require('fs');
let c = fs.readFileSync('src/app/components/Cotizaciones/CotizacionEditor.tsx', 'utf8');

const hookLogic = `
  useEffect(() => {
    const isFromCpq = searchParams.get('from_cpq');
    if (esNueva && isFromCpq && formData.items.length === 0) {
      try {
        const stored = localStorage.getItem('pending_cpq');
        if (stored) {
          const cpqData = JSON.parse(stored);
          
          const nuevoItem = {
            id: Date.now().toString(),
            producto_id: cpqData.producto_id,
            posicion: 1,
            cantidad: 1,
            unidad: 'pz',
            descripcion: cpqData.nombre,
            precio_unitario: cpqData.precio_unitario,
            costo_unitario: cpqData.costo_unitario,
            iva_item: 0,
            total_item: cpqData.precio_unitario,
            numero_proyecto: cpqData.producto_id,
            sub_items: cpqData.sub_items
          };
          
          setFormData(prev => ({ ...prev, items: [nuevoItem] }));
          
          const url = new URL(window.location.href);
          url.searchParams.delete('from_cpq');
          window.history.replaceState({}, '', url.toString());
          localStorage.removeItem('pending_cpq');
        }
      } catch(e) {}
    }
  }, [esNueva, searchParams]);
`;

// Inject below the existing useEffect
const target = `window.history.replaceState({}, '', url.toString());
      }
    }
  }, [productos, esNueva, searchParams]);`;

if (c.includes(target) && !c.includes("searchParams.get('from_cpq')")) {
  c = c.replace(target, target + '\n' + hookLogic);
  fs.writeFileSync('src/app/components/Cotizaciones/CotizacionEditor.tsx', c);
  console.log('CotizacionEditor CPQ load patched');
}
