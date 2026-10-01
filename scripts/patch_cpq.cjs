const fs = require('fs');
let content = fs.readFileSync('src/app/components/Cotizaciones/CotizacionEditor.tsx', 'utf8');

const oldFunc = `  const agregarItemDesdeProducto = (producto: Producto) => {
    let nuevoItem: ItemCotizacion;

    if (producto.tipo === 'servicio' && producto.servicio) {
      // Para servicios, usamos valores por defecto y permitimos configuración posterior
      const servicio = producto.servicio;
      nuevoItem = {
        id: Date.now().toString(),
        producto_id: producto.id,
        posicion: formData.items.length + 1,
        cantidad: 1, // Para servicios puede representar base/asientos
        unidad: producto.unidad || 'servicio',
        descripcion: producto.nombre,
        incluir_setup: servicio.modo === 'unico' || servicio.modo === 'hibrido',
        meses_cobrados: 1,
        asientos_extra: 0,
        iva_item: 0, // Se calculará dinámicamente
        total_item: 0, // Se calculará dinámicamente
        numero_proyecto: producto.id
      };
    } else {
      // Para bienes, mantener la lógica existente
      const { iva_item, total_item } = calcularItemCotizacion(
        1,
        producto.precio_unitario || 0,
        formData.con_factura ? ajustes.iva_por_defecto : 0
      );
      
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
        numero_proyecto: producto.id
      };
    }
    
    setFormData(prev => ({
      ...prev,
      items: [...prev.items, nuevoItem]
    }));
    
    setBusquedaProducto('');
    setShowProductoDropdown(false);
  };`;

const newFunc = `  const agregarItemDesdeProducto = async (producto: Producto) => {
    let nuevoItem: ItemCotizacion;
    let sub_items = undefined;

    // BLOQUE 2: CPQ - Cargar la "Receta Base" si es un Producto Terminado
    if (producto.tipo === 'bien' && producto.tipo_item === 'producto_terminado') {
      try {
        const { data: receta } = await supabase
          .from('producto_materiales')
          .select('cantidad, material:productos(id, nombre, precio_unitario)')
          .eq('producto_id', producto.id);
          
        if (receta && receta.length > 0) {
          sub_items = receta.map((rm: any) => ({
            material_id: rm.material.id,
            nombre: rm.material.nombre,
            cantidad: rm.cantidad,
            precio_unitario: rm.material.precio_unitario
          }));
        }
      } catch (err) {
        console.error("Error cargando receta CPQ:", err);
      }
    }

    if (producto.tipo === 'servicio' && producto.servicio) {
      // Para servicios, usamos valores por defecto y permitimos configuración posterior
      const servicio = producto.servicio;
      nuevoItem = {
        id: Date.now().toString(),
        producto_id: producto.id,
        posicion: formData.items.length + 1,
        cantidad: 1, // Para servicios puede representar base/asientos
        unidad: producto.unidad || 'servicio',
        descripcion: producto.nombre,
        incluir_setup: servicio.modo === 'unico' || servicio.modo === 'hibrido',
        meses_cobrados: 1,
        asientos_extra: 0,
        iva_item: 0, // Se calculará dinámicamente
        total_item: 0, // Se calculará dinámicamente
        numero_proyecto: producto.id
      };
    } else {
      // Para bienes, mantener la lógica existente
      const { iva_item, total_item } = calcularItemCotizacion(
        1,
        producto.precio_unitario || 0,
        formData.con_factura ? ajustes.iva_por_defecto : 0
      );
      
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
    
    setFormData(prev => ({
      ...prev,
      items: [...prev.items, nuevoItem]
    }));
    
    setBusquedaProducto('');
    setShowProductoDropdown(false);
  };`;

// Note: Replace string can be tricky with tabs/spaces, so we use a flexible regex
// Or we just replace exactly if the spacing matches.
if (content.includes(oldFunc)) {
    content = content.replace(oldFunc, newFunc);
} else {
    console.log("Could not find EXACT match. Fallback to replace by logic.");
    // Fallback logic
    const startStr = "const agregarItemDesdeProducto = (producto: Producto) => {";
    const endStr = "setShowProductoDropdown(false);\n  };";
    const startIndex = content.indexOf(startStr);
    const endIndex = content.indexOf(endStr, startIndex);
    if (startIndex !== -1 && endIndex !== -1) {
        content = content.substring(0, startIndex) + newFunc + content.substring(endIndex + endStr.length);
    } else {
        console.error("FAIL: Could not locate function block.");
        process.exit(1);
    }
}

fs.writeFileSync('src/app/components/Cotizaciones/CotizacionEditor.tsx', content);
console.log("Patch applied to CotizacionEditor.tsx!");
