const fs = require('fs');
const filePath = 'supabase/functions/make-server-feea4382/index.ts';
let code = fs.readFileSync(filePath, 'utf-8');

const endpoints = `

// --- TRAZABILIDAD (EVENTOS COTIZACION) ---
app.get("/cotizacion-eventos", async (c) => {
  try {
    const adminClient = getServiceClient();
    const orgId = c.get("organizacionId");
    const { data, error } = await adminClient
      .from("cotizacion_eventos")
      .select("*")
      .eq("organizacion_id", orgId)
      .order("created_at", { ascending: false });
    if (error) throw error;
    return c.json(data || []);
  } catch (error: any) {
    console.error("[make-server] Error fetching cotizacion_eventos:", error);
    return c.json({ error: error.message || "Error al obtener eventos" }, 500);
  }
});

app.post("/cotizacion-eventos", async (c) => {
  try {
    const adminClient = getServiceClient();
    const payload = await c.req.json();
    payload.organizacion_id = c.get("organizacionId");
    
    // El usuario auth id
    const authHeader = c.req.header("Authorization");
    if (authHeader) {
      const token = authHeader.replace("Bearer ", "");
      const { data: { user } } = await adminClient.auth.getUser(token);
      if (user) {
        payload.usuario_id = user.id;
      }
    }

    const { data, error } = await adminClient
      .from("cotizacion_eventos")
      .insert(payload)
      .select()
      .single();
      
    if (error) throw error;
    return c.json(data);
  } catch (error: any) {
    console.error("[make-server] Error creating cotizacion_evento:", error);
    return c.json({ error: error.message || "Error al registrar evento" }, 500);
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
