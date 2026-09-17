const URL = 'https://djwlchgkeeeqfkreebgq.supabase.co';
const KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRqd2xjaGdrZWVlcWZrcmVlYmdxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODg4MzQ5NTksImV4cCI6MjEwNDQxMDk1OX0.EvPTfH1gi6zI_W3CLWNlpV5X_9jQISC-C8hscVlBsJ4';

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
