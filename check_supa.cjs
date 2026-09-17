const URL = 'http://ws2.cloud.betics.com.mx:8000';
const KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyAgCiAgICAicm9sZSI6ICJhbm9uIiwKICAgICJpc3MiOiAic3VwYWJhc2UtZGVtbyIsCiAgICAiaWF0IjogMTY0MTc2OTIwMCwKICAgICJleHAiOiAxNzk5NTM1NjAwCn0.dc_X5iR_VP_qT0zsiyj_I_OZ2T9FtRU2BBNWN8Bu4GE';

async function query() {
  const headers = { 'apikey': KEY, 'Authorization': 'Bearer ' + KEY };
  
  const res = await fetch(URL + '/rest/v1/lineas_producto?select=*', { headers });
  const lineas = await res.json();
  console.log('Líneas:', lineas);

  const resFases = await fetch(URL + '/rest/v1/fases_produccion?select=*', { headers });
  const fases = await resFases.json();
  console.log('Fases:', fases);
}

query();
