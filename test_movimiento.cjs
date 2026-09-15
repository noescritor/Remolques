const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = 'https://djwlchgkeeeqfkreebgq.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRqd2xjaGdrZWVlcWZrcmVlYmdxIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc4ODgzNDk1OSwiZXhwIjoyMTA0NDEwOTU5fQ.F2Y8-LKD6AQJtrKuQbi5gtTxmvkKl8M4kF2UqYq4w6E';

const supabase = createClient(supabaseUrl, supabaseKey);

async function testInsert() {
  const orgId = '00000000-0000-0000-0000-000000000001';
  
  // Fetch a product ID
  const { data: prod } = await supabase.from('productos').select('id').eq('organizacion_id', orgId).limit(1).single();
  if (!prod) {
    console.log("No product found");
    return;
  }
  
  const payload = {
    organizacion_id: orgId,
    producto_id: prod.id,
    tipo_movimiento: 'Salida',
    cantidad: 1,
    referencia: 'Producción de prueba'
  };

  console.log("Inserting:", payload);
  const { data, error } = await supabase
    .from('movimientos_inventario')
    .insert(payload)
    .select()
    .single();

  if (error) {
    console.error("DB Error:", error);
  } else {
    console.log("Success:", data);
  }
}

testInsert();
