const fs = require('fs');
const filePath = 'supabase/functions/make-server-feea4382/index.ts';
let code = fs.readFileSync(filePath, 'utf-8');

const endpoints = `

// --- ORDENES DE TRABAJO ---
app.get("/ordenes-trabajo", async (c) => {
  try {
    const supabase = getServiceClient();
    const orgId = c.get("organizacionId");
    const { data, error } = await supabase
      .from("ordenes_trabajo")
      .select("*, cliente:clientes(*), cotizacion:cotizaciones(*)")
      .eq("organizacion_id", orgId)
      .order("created_at", { ascending: false });
    if (error) throw error;
    return c.json(data || []);
  } catch (error: any) {
    console.error("[make-server] Error fetching ordenes_trabajo:", error);
    return c.json({ error: error.message }, 500);
  }
});

app.put("/ordenes-trabajo/:id", async (c) => {
  try {
    const supabase = getServiceClient();
    const orgId = c.get("organizacionId");
    const id = c.req.param("id");
    const payload = await c.req.json();
    
    const { data, error } = await supabase
      .from("ordenes_trabajo")
      .update(payload)
      .eq("id", id)
      .eq("organizacion_id", orgId)
      .select()
      .single();
      
    if (error) throw error;
    return c.json(data);
  } catch (error: any) {
    console.error("[make-server] Error updating orden_trabajo:", error);
    return c.json({ error: error.message }, 500);
  }
});

app.post("/cotizaciones/:id/generar-ordenes", async (c) => {
  try {
    const supabase = getServiceClient();
    const orgId = c.get("organizacionId");
    const cotizacionId = c.req.param("id");
    
    // 1. Traer cotizacion con cliente y items
    const { data: cotizacion, error: cotError } = await supabase
      .from("cotizaciones")
      .select("*, cliente:clientes(*), items:items_cotizacion(*)")
      .eq("id", cotizacionId)
      .eq("organizacion_id", orgId)
      .single();
    if (cotError) throw cotError;
    
    // Generar iniciales del cliente
    let iniciales = "CLI";
    if (cotizacion.cliente) {
      if (cotizacion.cliente.tipo === 'Empresa' || cotizacion.cliente.empresa) {
        const nombreEmpresa = cotizacion.cliente.empresa || cotizacion.cliente.nombre;
        iniciales = nombreEmpresa.substring(0, 3).toUpperCase();
      } else {
        const partes = cotizacion.cliente.nombre.split(' ').filter(Boolean);
        iniciales = partes.slice(0, 3).map((p: string) => p[0]).join('').toUpperCase();
      }
    }
    
    const mes = new Date().getMonth() + 1;
    const anio = new Date().getFullYear().toString().slice(-2);
    const mesStr = mes.toString().padStart(2, '0');
    
    const ordenesToInsert = [];
    let trailerCounter = 1;
    
    // Por cada item, si es remolque (asumiremos todo > $10,000 es remolque por ahora, o buscamos keywords)
    for (const item of cotizacion.items) {
      // Intentar deducir tipo equipo
      let tipoEquipo = "01"; // Default plataforma
      const desc = item.descripcion.toLowerCase();
      if (desc.includes("dolly")) tipoEquipo = "02";
      else if (desc.includes("gondola") || desc.includes("góndola")) tipoEquipo = "03";
      else if (desc.includes("jaula")) tipoEquipo = "04";
      else if (desc.includes("cama baja")) tipoEquipo = "05";
      else if (desc.includes("multimodal")) tipoEquipo = "06";
      else if (desc.includes("porta")) tipoEquipo = "07";
      else if (desc.includes("seca")) tipoEquipo = "08";
      else if (desc.includes("traila")) tipoEquipo = "09";
      
      // Si el precio_unitario < 10000, probablemente no es un equipo sino un repuesto/extra
      if (item.precio_unitario < 10000) continue;
      
      // Para cada cantidad del item
      for (let i = 0; i < item.cantidad; i++) {
        // Conseguir num secuencial
        const { data: numResult, error: seqError } = await supabase.rpc('obtener_siguiente_produccion');
        let numSecuencial = 1;
        if (seqError) {
            // Fallback si no tenemos la RPC
            numSecuencial = Math.floor(Math.random() * 900) + 100; // Fake seq
        } else {
            numSecuencial = numResult;
        }
        
        const nomenclatura = \`\${numSecuencial}-\${iniciales}\${tipoEquipo}\${mesStr}\${anio}-\${trailerCounter}\`;
        
        // Características base del JSON
        const caracteristicas = item.configuracion || {};
        caracteristicas.descripcion_corta = item.descripcion;
        
        ordenesToInsert.push({
          organizacion_id: orgId,
          cotizacion_id: cotizacionId,
          cliente_id: cotizacion.cliente_id,
          nomenclatura_id: nomenclatura,
          tipo_equipo: tipoEquipo,
          caracteristicas: caracteristicas,
          estado: 'Pendiente'
        });
        
        trailerCounter++;
      }
    }
    
    if (ordenesToInsert.length === 0) {
      return c.json({ error: "No se encontraron equipos principales en la cotización." }, 400);
    }
    
    const { data: ordenes, error: insError } = await supabase
      .from("ordenes_trabajo")
      .insert(ordenesToInsert)
      .select();
      
    if (insError) throw insError;
    
    return c.json(ordenes);
  } catch (error: any) {
    console.error("[make-server] Error generating ordenes:", error);
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
