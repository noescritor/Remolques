const { createClient } = require('@supabase/supabase-js');

const supabase = createClient(
  'https://remolques-remolques-supa.gehkp3.easypanel.host',
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRqd2xjaGdrZWVlcWZrcmVlYmdxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODg4MzQ5NTksImV4cCI6MjEwNDQxMDk1OX0.EvPTfH1gi6zI_W3CLWNlpV5X_9jQISC-C8hscVlBsJ4'
);

async function checkBOM() {
  const { data, error } = await supabase
    .from('producto_materiales')
    .select('producto_id, productos(nombre, sku)');
    
  if (error) {
    console.error('Error:', error);
    return;
  }
  
  if (!data || data.length === 0) {
    console.log('No hay recetas BOM registradas en la base de datos.');
    return;
  }
  
  const productosConReceta = new Map();
  for (const item of data) {
    if (!productosConReceta.has(item.producto_id)) {
      productosConReceta.set(item.producto_id, {
        nombre: item.productos?.nombre || 'Desconocido',
        sku: item.productos?.sku || 'N/A',
        materialesCount: 0
      });
    }
    productosConReceta.get(item.producto_id).materialesCount++;
  }
  
  console.log('--- PRODUCTOS CON RECETA BOM ---');
  for (const [id, prod] of productosConReceta.entries()) {
    console.log(`- ${prod.nombre} (SKU: ${prod.sku}) -> ${prod.materialesCount} materiales`);
  }
}

checkBOM();
