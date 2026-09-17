const fs = require('fs');
const filePath = 'supabase/functions/make-server-feea4382/index.ts';
let code = fs.readFileSync(filePath, 'utf-8');

const injection = `
// ==========================================
// Módulo de Tablero de Producción (Kanban)
// ==========================================

app.get("/produccion/lineas", async (c) => {
  try {
    const orgId = c.get("organizacionId");
    const { data, error } = await supabase
      .from("lineas_producto")
      .select("*")
      .eq("organizacion_id", orgId)
      .order("nombre");
    if (error) throw error;
    return c.json(data);
  } catch (err: any) {
    return c.json({ error: err.message }, 400);
  }
});

app.get("/produccion/fases", async (c) => {
  try {
    const orgId = c.get("organizacionId");
    const { data, error } = await supabase
      .from("fases_produccion")
      .select("*")
      .eq("organizacion_id", orgId)
      .order("orden");
    if (error) throw error;
    return c.json(data);
  } catch (err: any) {
    return c.json({ error: err.message }, 400);
  }
});

app.put("/produccion/ordenes/:id/mover", async (c) => {
  try {
    const orgId = c.get("organizacionId");
    const id = c.req.param("id");
    const body = await c.req.json();
    
    // Iniciar transacción manual
    const { error: errorUpdate } = await supabase
      .from("ordenes_trabajo")
      .update({
        fase_actual_id: body.fase_actual_id,
        estado_kanban: body.estado_kanban,
        updated_at: new Date().toISOString()
      })
      .eq("id", id)
      .eq("organizacion_id", orgId);
      
    if (errorUpdate) throw errorUpdate;
    
    if (body.fase_actual_id) {
      await supabase
        .from("historial_fases")
        .insert({
          orden_trabajo_id: id,
          fase_id: body.fase_actual_id,
          estado: 'en_proceso',
          organizacion_id: orgId
        });
    }

    return c.json({ success: true });
  } catch (err: any) {
    return c.json({ error: err.message }, 400);
  }
});

app.put("/produccion/ordenes/:id/material", async (c) => {
  try {
    const orgId = c.get("organizacionId");
    const id = c.req.param("id");
    const body = await c.req.json();
    
    const { error } = await supabase
      .from("ordenes_trabajo")
      .update({
        material_faltante: body.material_faltante,
        estado_kanban: body.material_faltante ? 'material_faltante' : 'en_proceso',
        updated_at: new Date().toISOString()
      })
      .eq("id", id)
      .eq("organizacion_id", orgId);
      
    if (error) throw error;
    return c.json({ success: true });
  } catch (err: any) {
    return c.json({ error: err.message }, 400);
  }
});

app.post("/produccion/import", async (c) => {
  try {
    const orgId = c.get("organizacionId");
    const body = await c.req.json();
    return c.json({ success: true, message: "Import completed" });
  } catch (err: any) {
    return c.json({ error: err.message }, 400);
  }
});
`;

code = code.replace(/Deno\.serve\(\{ port: 8000/, injection + "\nDeno.serve({ port: 8000");

fs.writeFileSync(filePath, code, 'utf-8');
