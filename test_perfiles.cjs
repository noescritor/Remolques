const { createClient } = require('@supabase/supabase-js');

const SUPABASE_URL = 'https://djwlchgkeeeqfkreebgq.supabase.co';
const SUPABASE_SERVICE_ROLE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRqd2xjaGdrZWVlcWZrcmVlYmdxIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc4ODgzNDk1OSwiZXhwIjoyMTA0NDEwOTU5fQ.F2Y8-LKD6AQJtrKuQbi5gtTxmvkKl8M4kF2UqYq4w6E';

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

async function main() {
  const { data, error } = await supabase.from('perfiles_organizacion').select('*');
  console.log('Perfiles:', data, error);
}

main();
