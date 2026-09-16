const fs = require('fs');
const filePath = 'supabase/functions/make-server-feea4382/index.ts';
let code = fs.readFileSync(filePath, 'utf-8');

const endpoints = `

// --- PRESUPUESTOS ---
app.get("/presupuestos", async (c) => {
  try {
    const supabase = getServiceClient();
    const orgId = c.get("organizacionId");
    const { data, error } = await supabase
      .from("presupuestos")
      .select("*, cliente:clientes(*)")
      .eq("organizacion_id", orgId)
      .order("created_at", { ascending: false });
    if (error) throw error;
    return c.json(data || []);
  } catch (error: any) {
    console.error("[make-server] Error fetching presupuestos:", error);
    return c.json({ error: error.message }, 500);
  }
});

app.post("/presupuestos", async (c) => {
  try {
    const supabase = getServiceClient();
    const orgId = c.get("organizacionId");
    const payload = await c.req.json();
    payload.organizacion_id = orgId;
    const { data, error } = await supabase
      .from("presupuestos")
      .insert(payload)
      .select("*, cliente:clientes(*)")
      .single();
    if (error) throw error;
    return c.json(data);
  } catch (error: any) {
    console.error("[make-server] Error creating presupuesto:", error);
    return c.json({ error: error.message }, 500);
  }
});

app.put("/presupuestos/:id", async (c) => {
  try {
    const supabase = getServiceClient();
    const orgId = c.get("organizacionId");
    const id = c.req.param("id");
    const payload = await c.req.json();
    
    const { data, error } = await supabase
      .from("presupuestos")
      .update(payload)
      .eq("id", id)
      .eq("organizacion_id", orgId)
      .select("*, cliente:clientes(*)")
      .single();
      
    if (error) throw error;
    return c.json(data);
  } catch (error: any) {
    console.error("[make-server] Error updating presupuesto:", error);
    return c.json({ error: error.message }, 500);
  }
});

app.delete("/presupuestos/:id", async (c) => {
  try {
    const supabase = getServiceClient();
    const orgId = c.get("organizacionId");
    const id = c.req.param("id");
    
    const { error } = await supabase
      .from("presupuestos")
      .delete()
      .eq("id", id)
      .eq("organizacion_id", orgId);
      
    if (error) throw error;
    return c.json({ success: true });
  } catch (error: any) {
    console.error("[make-server] Error deleting presupuesto:", error);
    return c.json({ error: error.message }, 500);
  }
});

`;

const exportIndex = code.lastIndexOf("Deno.serve(");
if (exportIndex !== -1) {
  code = code.slice(0, exportIndex) + endpoints + code.slice(exportIndex);
  fs.writeFileSync(filePath, code, 'utf-8');
  console.log("Endpoints appended to index.ts");
} else {
  console.error("Could not find 'Deno.serve' in index.ts");
}
