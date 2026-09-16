const fs = require('fs');
const filePath = 'supabase/functions/make-server-feea4382/index.ts';
let code = fs.readFileSync(filePath, 'utf-8');

const injection = `
  // --- TABLERO DE PRODUCCION (KANBAN) ---

  app.get("/produccion/lineas", async (c) => {
    try {
      const supabase = getServiceClient();
      const orgId = c.get("organizacionId");
      const { data, error } = await supabase
        .from("lineas_producto")
        .select("*")
        .eq("organizacion_id", orgId)
        .order("clave");
      if (error) throw error;
      return c.json(data || []);
    } catch (error: any) {
      console.error("[make-server] Error fetching lineas:", error);
      return c.json({ error: error.message }, 500);
    }
  });

  app.get("/produccion/fases", async (c) => {
    try {
      const supabase = getServiceClient();
      const orgId = c.get("organizacionId");
      const { data, error } = await supabase
        .from("fases_produccion")
        .select("*")
        .eq("organizacion_id", orgId)
        .order("orden");
      if (error) throw error;
      return c.json(data || []);
    } catch (error: any) {
      console.error("[make-server] Error fetching fases:", error);
      return c.json({ error: error.message }, 500);
    }
  });

  app.get("/produccion/tablero", async (c) => {
    try {
      const supabase = getServiceClient();
      const orgId = c.get("organizacionId");
      
      const { data, error } = await supabase
        .from("ordenes_trabajo")
        .select("*, cliente:clientes(nombre), linea:lineas_producto(clave), fase:fases_produccion(nombre)")
        .eq("organizacion_id", orgId)
        .order("created_at", { ascending: false });
        
      if (error) throw error;
      return c.json(data || []);
    } catch (error: any) {
      console.error("[make-server] Error fetching tablero:", error);
      return c.json({ error: error.message }, 500);
    }
  });

  app.put("/produccion/ordenes/:id/mover", async (c) => {
    try {
      const supabase = getServiceClient();
      const orgId = c.get("organizacionId");
      const id = c.req.param("id");
      const { fase_actual_id, estado_kanban } = await c.req.json();
      
      // Update order
      const { data, error } = await supabase
        .from("ordenes_trabajo")
        .update({ fase_actual_id, estado_kanban })
        .eq("id", id)
        .eq("organizacion_id", orgId)
        .select()
        .single();
        
      if (error) throw error;

      // Insert history log
      await supabase.from("historial_fases").insert({
        orden_trabajo_id: id,
        fase_id: fase_actual_id,
        estado: estado_kanban,
        organizacion_id: orgId
      });

      return c.json(data);
    } catch (error: any) {
      console.error("[make-server] Error moving orden:", error);
      return c.json({ error: error.message }, 500);
    }
  });

  app.put("/produccion/ordenes/:id/material", async (c) => {
    try {
      const supabase = getServiceClient();
      const orgId = c.get("organizacionId");
      const id = c.req.param("id");
      const { material_faltante } = await c.req.json();
      
      const { data, error } = await supabase
        .from("ordenes_trabajo")
        .update({ material_faltante })
        .eq("id", id)
        .eq("organizacion_id", orgId)
        .select()
        .single();
        
      if (error) throw error;
      return c.json(data);
    } catch (error: any) {
      console.error("[make-server] Error updating material:", error);
      return c.json({ error: error.message }, 500);
    }
  });

  // Batch import for ETL
  app.post("/produccion/import", async (c) => {
    try {
      const supabase = getServiceClient();
      const orgId = c.get("organizacionId");
      const payload = await c.req.json();
      const { lineas, fases, ordenes } = payload;
      
      // We assume client does the heavy lifting and sends ready-to-insert objects 
      // but without org_id. So we add it.
      
      if (lineas && lineas.length > 0) {
         await supabase.from('lineas_producto').upsert(
           lineas.map((l: any) => ({ ...l, organizacion_id: orgId })),
           { onConflict: 'clave' }
         );
      }
      
      if (fases && fases.length > 0) {
         await supabase.from('fases_produccion').upsert(
           fases.map((f: any) => ({ ...f, organizacion_id: orgId }))
         );
      }
      
      if (ordenes && ordenes.length > 0) {
         // for simplicity in ETL we can just insert or ignore
         await supabase.from('ordenes_trabajo').upsert(
           ordenes.map((o: any) => ({ ...o, organizacion_id: orgId }))
         );
      }

      return c.json({ success: true });
    } catch (error: any) {
      console.error("[make-server] Error importing:", error);
      return c.json({ error: error.message }, 500);
    }
  });

  // --- FIN TABLERO DE PRODUCCION ---
`;

code = code.replace('export default {', injection + '\nexport default {');

fs.writeFileSync(filePath, code, 'utf-8');
