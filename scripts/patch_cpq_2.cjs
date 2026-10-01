const fs = require('fs');
let c = fs.readFileSync('src/app/components/Cotizaciones/CotizacionEditor.tsx', 'utf8');
const startStr = 'const agregarItemDesdeProducto = (producto: Producto) => {';
const endStr = 'setShowProductoDropdown(false);\n    };';
const startIdx = c.indexOf(startStr);
const endIdx = c.indexOf(endStr, startIdx);

if (startIdx !== -1 && endIdx !== -1) {
  const newF = `const agregarItemDesdeProducto = async (producto: Producto) => {
      let nuevoItem: ItemCotizacion;
      let sub_items = undefined;
  
      if (producto.tipo === 'bien' && producto.tipo_item === 'producto_terminado') {
        try {
          const { data: receta } = await supabase.from('producto_materiales').select('cantidad, material:productos(id, nombre, precio_unitario, costo)').eq('producto_id', producto.id);
          if (receta && receta.length > 0) {
            sub_items = receta.map((rm: any) => ({
              material_id: rm.material.id,
              nombre: rm.material.nombre,
              cantidad: rm.cantidad,
              precio_unitario: rm.material.precio_unitario || rm.material.costo
            }));
          }
        } catch (err) {}
      }
  
      if (producto.tipo === 'servicio' && producto.servicio) {
        const servicio = producto.servicio;
        nuevoItem = {
          id: Date.now().toString(),
          producto_id: producto.id,
          posicion: formData.items.length + 1,
          cantidad: 1,
          unidad: producto.unidad || 'servicio',
          descripcion: producto.nombre,
          incluir_setup: servicio.modo === 'unico' || servicio.modo === 'hibrido',
          meses_cobrados: 1,
          asientos_extra: 0,
          iva_item: 0,
          total_item: 0,
          numero_proyecto: producto.id
        };
      } else {
        const { iva_item, total_item } = calcularItemCotizacion(1, producto.precio_unitario || 0, formData.con_factura ? ajustes.iva_por_defecto : 0);
        nuevoItem = {
          id: Date.now().toString(),
          producto_id: producto.id,
          posicion: formData.items.length + 1,
          cantidad: 1,
          unidad: producto.unidad || 'pz',
          descripcion: producto.nombre,
          precio_unitario: producto.precio_unitario,
          costo_unitario: producto.costo || 0,
          iva_item,
          total_item,
          numero_proyecto: producto.id,
          sub_items
        };
      }
      
      setFormData(prev => ({ ...prev, items: [...prev.items, nuevoItem] }));
      setBusquedaProducto('');
      setShowProductoDropdown(false);
    };`;
    
  c = c.substring(0, startIdx) + newF + c.substring(endIdx + endStr.length);
  fs.writeFileSync('src/app/components/Cotizaciones/CotizacionEditor.tsx', c);
  console.log('Patched correctly');
} else {
  console.log('Could not find function bounds!', startIdx, endIdx);
}
