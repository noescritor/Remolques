const fs = require('fs');
const filePath = 'src/app/hooks/useSupabaseData.ts';
let code = fs.readFileSync(filePath, 'utf-8');

// POST
code = code.replace(
  /const { data, error } = await supabase\.from\('categorias_producto'\)\.insert\(categoria\)\.select\(\)\.single\(\);\s*if \(error\) throw error;/,
  "const res = await fetch(`${import.meta.env.VITE_SUPABASE_URL}/rest/v1/categorias_producto?select=*`, { method: 'POST', headers: { apikey: import.meta.env.VITE_SUPABASE_ANON_KEY, Authorization: `Bearer ${token}`, 'Content-Type': 'application/json', 'Prefer': 'return=representation' }, body: JSON.stringify(categoria) });\n      if (!res.ok) throw new Error('Error creating categoria');\n      const data = (await res.json())[0];"
);
code = code.replace(
  /const { data, error } = await supabase\.from\('categorias_cliente'\)\.insert\(categoria\)\.select\(\)\.single\(\);\s*if \(error\) throw error;/,
  "const res = await fetch(`${import.meta.env.VITE_SUPABASE_URL}/rest/v1/categorias_cliente?select=*`, { method: 'POST', headers: { apikey: import.meta.env.VITE_SUPABASE_ANON_KEY, Authorization: `Bearer ${token}`, 'Content-Type': 'application/json', 'Prefer': 'return=representation' }, body: JSON.stringify(categoria) });\n      if (!res.ok) throw new Error('Error creating categoria');\n      const data = (await res.json())[0];"
);

// PUT
code = code.replace(
  /const { data, error } = await supabase\.from\('categorias_producto'\)\.update\(categoria\)\.eq\('id', id\)\.select\(\)\.single\(\);\s*if \(error\) throw error;/,
  "const res = await fetch(`${import.meta.env.VITE_SUPABASE_URL}/rest/v1/categorias_producto?id=eq.${id}&select=*`, { method: 'PATCH', headers: { apikey: import.meta.env.VITE_SUPABASE_ANON_KEY, Authorization: `Bearer ${token}`, 'Content-Type': 'application/json', 'Prefer': 'return=representation' }, body: JSON.stringify(categoria) });\n      if (!res.ok) throw new Error('Error updating categoria');\n      const data = (await res.json())[0];"
);
code = code.replace(
  /const { data, error } = await supabase\.from\('categorias_cliente'\)\.update\(categoria\)\.eq\('id', id\)\.select\(\)\.single\(\);\s*if \(error\) throw error;/,
  "const res = await fetch(`${import.meta.env.VITE_SUPABASE_URL}/rest/v1/categorias_cliente?id=eq.${id}&select=*`, { method: 'PATCH', headers: { apikey: import.meta.env.VITE_SUPABASE_ANON_KEY, Authorization: `Bearer ${token}`, 'Content-Type': 'application/json', 'Prefer': 'return=representation' }, body: JSON.stringify(categoria) });\n      if (!res.ok) throw new Error('Error updating categoria');\n      const data = (await res.json())[0];"
);

// DELETE
code = code.replace(
  /const { error } = await supabase\.from\('categorias_producto'\)\.delete\(\)\.eq\('id', id\);\s*if \(error\) throw error;/,
  "const res = await fetch(`${import.meta.env.VITE_SUPABASE_URL}/rest/v1/categorias_producto?id=eq.${id}`, { method: 'DELETE', headers: { apikey: import.meta.env.VITE_SUPABASE_ANON_KEY, Authorization: `Bearer ${token}` }});\n      if (!res.ok) throw new Error('Error deleting categoria');"
);
code = code.replace(
  /const { error } = await supabase\.from\('categorias_cliente'\)\.delete\(\)\.eq\('id', id\);\s*if \(error\) throw error;/,
  "const res = await fetch(`${import.meta.env.VITE_SUPABASE_URL}/rest/v1/categorias_cliente?id=eq.${id}`, { method: 'DELETE', headers: { apikey: import.meta.env.VITE_SUPABASE_ANON_KEY, Authorization: `Bearer ${token}` }});\n      if (!res.ok) throw new Error('Error deleting categoria');"
);

fs.writeFileSync(filePath, code, 'utf-8');
