const { createClient } = require('@supabase/supabase-js');
const supabase = createClient('http://ws2.cloud.betics.com.mx:8000', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyAgCiAgICAicm9sZSI6ICJhbm9uIiwKICAgICJpc3MiOiAic3VwYWJhc2UtZGVtbyIsCiAgICAiaWF0IjogMTY0MTc2OTIwMCwKICAgICJleHAiOiAxNzk5NTM1NjAwCn0.dc_X5iR_VP_qT0zsiyj_I_OZ2T9FtRU2BBNWN8Bu4GE');

async function check() {
  const { data, error } = await supabase.from('productos').select('*');
  if (error) console.error('Error fetching', error);
  else {
    console.log('Total productos:', data.length);
    const terminados = data.filter(p => p.tipo_item === 'producto_terminado');
    console.log('Terminados:', terminados.length);
    if(terminados.length > 0) console.log('Ejemplos:', terminados.slice(0,2).map(p=>p.nombre));
  }
}
check();
