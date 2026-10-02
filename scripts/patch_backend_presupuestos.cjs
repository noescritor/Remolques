const fs = require('fs');
const path = 'supabase/functions/make-server-feea4382/index.ts';
let code = fs.readFileSync(path, 'utf8');

const endpoints = `
// --- Endpoints de Presupuestos Restaurados ---
app.get("/presupuestos", async (c) => {
  try {
    const orgId = c.get("organizacionId");
    const supabase = c.get("supabase") as any;
    const { data, error } = await supabase.from("presupuestos").select("*").eq("organizacion_id", orgId).order('created_at', { ascending: false });
    if (error) throw error;
    return c.json(data || []);
  } catch (err: any) {
    return c.json({ error: err.message }, 400);
  }
});

app.get("/presupuestos/:id", async (c) => {
  try {
    const orgId = c.get("organizacionId");
    const id = c.req.param("id");
    const supabase = c.get("supabase") as any;
    const { data, error } = await supabase.from("presupuestos").select("*").eq("id", id).eq("organizacion_id", orgId).single();
    if (error) throw error;
    return c.json(data);
  } catch (err: any) {
    return c.json({ error: err.message }, 400);
  }
});

app.post("/presupuestos", async (c) => {
  try {
    const orgId = c.get("organizacionId");
    const supabase = c.get("supabase") as any;
    const body = await c.req.json();
    body.organizacion_id = orgId;
    const { data, error } = await supabase.from("presupuestos").insert([body]).select().single();
    if (error) throw error;
    return c.json(data);
  } catch (err: any) {
    return c.json({ error: err.message }, 400);
  }
});

app.put("/presupuestos/:id", async (c) => {
  try {
    const orgId = c.get("organizacionId");
    const id = c.req.param("id");
    const supabase = c.get("supabase") as any;
    const body = await c.req.json();
    const { data, error } = await supabase.from("presupuestos").update(body).eq("id", id).eq("organizacion_id", orgId).select().single();
    if (error) throw error;
    return c.json(data);
  } catch (err: any) {
    return c.json({ error: err.message }, 400);
  }
});

app.delete("/presupuestos/:id", async (c) => {
  try {
    const orgId = c.get("organizacionId");
    const id = c.req.param("id");
    const supabase = c.get("supabase") as any;
    const { error } = await supabase.from("presupuestos").delete().eq("id", id).eq("organizacion_id", orgId);
    if (error) throw error;
    return c.json({ success: true });
  } catch (err: any) {
    return c.json({ error: err.message }, 400);
  }
});
// -----------------------------------------------
`;

if (!code.includes('app.get("/presupuestos"')) {
  // Insert before the last default handlers or just at the bottom before app.notFound
  code = code.replace('app.notFound((c) =>', endpoints + '\napp.notFound((c) =>');
  fs.writeFileSync(path, code);
  console.log('Backend patched with presupuestos endpoints');
} else {
  console.log('Already patched');
}
