import os

file_path = r"c:\Users\luisa\Downloads\proyectos_antygravity\Remolques\supabase\functions\make-server-feea4382\index.ts"

with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

# Check if endpoints already exist
if "/proveedores" not in content:
    new_endpoints = """
// ─── Nuevos endpoints (Remolques) ─────────────────────────────────────────────

app.get("/proveedores", async (c) => {
  try {
    const supabase = c.get("supabase") as SupabaseClient;
    const { data, error } = await supabase.from('proveedores').select('*, materiales:proveedor_materiales(material_id)');
    if (error) throw error;
    return c.json(data);
  } catch (error: any) {
    return c.json({ error: 'Error fetching proveedores' }, 500);
  }
});

app.post("/proveedores", async (c) => {
  try {
    const supabase = c.get("supabase") as SupabaseClient;
    const { materiales, ...proveedorData } = await c.req.json();
    proveedorData.organizacion_id = c.get("organizacionId");

    const { data, error } = await supabase.from('proveedores').insert(proveedorData).select().single();
    if (error) throw error;

    if (materiales && materiales.length > 0) {
      const itemsToInsert = materiales.map((m_id: string) => ({ proveedor_id: data.id, material_id: m_id }));
      await supabase.from('proveedor_materiales').insert(itemsToInsert);
    }
    return c.json(data);
  } catch (error) {
    return c.json({ error: 'Error creating proveedor' }, 500);
  }
});

app.put("/proveedores/:id", async (c) => {
  try {
    const supabase = c.get("supabase") as SupabaseClient;
    const id = c.req.param('id');
    const { materiales, ...updates } = await c.req.json();

    const { data, error } = await supabase.from('proveedores').update(updates).eq('id', id).select().single();
    if (error) throw error;

    if (materiales !== undefined) {
      await supabase.from('proveedor_materiales').delete().eq('proveedor_id', id);
      if (materiales.length > 0) {
        const itemsToInsert = materiales.map((m_id: string) => ({ proveedor_id: id, material_id: m_id }));
        await supabase.from('proveedor_materiales').insert(itemsToInsert);
      }
    }
    return c.json(data);
  } catch (error) {
    return c.json({ error: 'Error updating proveedor' }, 500);
  }
});

app.delete("/proveedores/:id", async (c) => {
  try {
    const supabase = c.get("supabase") as SupabaseClient;
    const { error } = await supabase.from('proveedores').delete().eq('id', c.req.param('id'));
    if (error) throw error;
    return c.json({ success: true });
  } catch (error) {
    return c.json({ error: 'Error deleting proveedor' }, 500);
  }
});

app.get("/compras-proveedor", async (c) => {
  try {
    const supabase = c.get("supabase") as SupabaseClient;
    const { data, error } = await supabase.from('compras_proveedor').select('*, items:compra_items(*)');
    if (error) throw error;
    return c.json(data);
  } catch (error) {
    return c.json({ error: 'Error fetching compras_proveedor' }, 500);
  }
});

app.post("/compras-proveedor", async (c) => {
  try {
    const supabase = c.get("supabase") as SupabaseClient;
    const payload = await c.req.json();
    const { items, ...compraData } = payload;
    compraData.organizacion_id = c.get("organizacionId");

    const { data, error } = await supabase.from('compras_proveedor').insert(compraData).select().single();
    if (error) throw error;

    if (items && items.length > 0) {
      const itemsToInsert = items.map((item: any) => ({ ...item, compra_id: data.id }));
      await supabase.from('compra_items').insert(itemsToInsert);
    }
    return c.json(data);
  } catch (error) {
    return c.json({ error: 'Error creating compra_proveedor' }, 500);
  }
});

app.put("/compras-proveedor/:id", async (c) => {
  try {
    const supabase = c.get("supabase") as SupabaseClient;
    const id = c.req.param('id');
    const { items, ...updates } = await c.req.json();

    const { data, error } = await supabase.from('compras_proveedor').update(updates).eq('id', id).select().single();
    if (error) throw error;

    if (items !== undefined) {
      await supabase.from('compra_items').delete().eq('compra_id', id);
      if (items.length > 0) {
        const itemsToInsert = items.map((item: any) => ({ ...item, compra_id: id }));
        await supabase.from('compra_items').insert(itemsToInsert);
      }
    }
    return c.json(data);
  } catch (error) {
    return c.json({ error: 'Error updating compra_proveedor' }, 500);
  }
});

app.get("/cotizacion-eventos", async (c) => {
  try {
    const supabase = c.get("supabase") as SupabaseClient;
    // We select usuario by joining auth.users using raw sql, but postgrest doesn't allow auth schema join easily unless we use a view or function.
    // However, if we just select it, we can resolve it on the client or let Supabase edge functions handle it via admin client if we need email.
    // For now, let's just select *
    const { data, error } = await supabase.from('cotizacion_eventos').select('*');
    if (error) throw error;
    return c.json(data);
  } catch (error) {
    return c.json({ error: 'Error fetching eventos' }, 500);
  }
});

app.post("/cotizacion-eventos", async (c) => {
  try {
    const supabase = c.get("supabase") as SupabaseClient;
    const payload = await c.req.json();
    payload.organizacion_id = c.get("organizacionId");
    
    // Automatically set user_id from auth token
    const user = c.get("user");
    payload.usuario_id = user?.id;

    const { data, error } = await supabase.from('cotizacion_eventos').insert(payload).select().single();
    if (error) throw error;
    return c.json(data);
  } catch (error) {
    return c.json({ error: 'Error creating evento' }, 500);
  }
});
"""

    content = content.replace('Deno.serve(app.fetch);', new_endpoints + '\n\nDeno.serve(app.fetch);')

    with open(file_path, "w", encoding="utf-8") as f:
        f.write(content)
    print("Endpoints added.")
else:
    print("Endpoints already exist.")
