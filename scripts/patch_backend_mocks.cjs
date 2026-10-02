const fs = require('fs');
const path = 'supabase/functions/make-server-feea4382/index.ts';
let code = fs.readFileSync(path, 'utf8');

const mocks = `
app.get("/produccion/lineas", (c) => c.json([]));
app.get("/produccion/fases", (c) => c.json([]));
`;

if (!code.includes('app.get("/produccion/lineas"')) {
  code = code.replace('app.notFound((c) =>', mocks + '\napp.notFound((c) =>');
  fs.writeFileSync(path, code);
  console.log('Mocks added');
}
