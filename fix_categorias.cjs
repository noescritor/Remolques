const fs = require('fs');
const filePath = 'src/app/hooks/useSupabaseData.ts';
let code = fs.readFileSync(filePath, 'utf-8');

code = code.replace(
  /const categoriasReq = await supabase\.from\('categorias_producto'\)\.select\('\*'\)\.order\('orden'\);\s*if \(categoriasReq\.data\) setCategoriasProducto\(categoriasReq\.data\);/,
  "const catProdRes = await fetch(`${import.meta.env.VITE_SUPABASE_URL}/rest/v1/categorias_producto?select=*&order=orden.asc`, { headers: { apikey: import.meta.env.VITE_SUPABASE_ANON_KEY, Authorization: `Bearer ${token}` }});\n      if (catProdRes.ok) setCategoriasProducto(await catProdRes.json());"
);

code = code.replace(
  /const categoriasReqC = await supabase\.from\('categorias_cliente'\)\.select\('\*'\)\.order\('orden'\);\s*if \(categoriasReqC\.data\) setCategoriasCliente\(categoriasReqC\.data\);/,
  "const catCliRes = await fetch(`${import.meta.env.VITE_SUPABASE_URL}/rest/v1/categorias_cliente?select=*&order=orden.asc`, { headers: { apikey: import.meta.env.VITE_SUPABASE_ANON_KEY, Authorization: `Bearer ${token}` }});\n      if (catCliRes.ok) setCategoriasCliente(await catCliRes.json());"
);

fs.writeFileSync(filePath, code, 'utf-8');
