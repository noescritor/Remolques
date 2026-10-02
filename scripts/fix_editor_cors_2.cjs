const fs = require('fs');
let c = fs.readFileSync('src/app/components/Cotizaciones/CotizacionEditor.tsx', 'utf8');

const regex = /const agregarItemDesdeProducto = \(producto: Producto\) => \{[\s\S]*?setFormData\(prev => \(\{[\s\S]*?items: \[\.\.\.prev\.items, nuevoItem\]\n\s*\}\)\);\n\s*\};/;

const newFn = `const agregarItemDesdeProducto = (producto: Producto) => {
    let nuevoItem: ItemCotizacion;

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
        unidad: producto.unidad,
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
  };`;

c = c.replace(regex, newFn);
fs.writeFileSync('src/app/components/Cotizaciones/CotizacionEditor.tsx', c);
console.log('Fixed adding items');
