import { Hono } from "npm:hono";
import { createClient, SupabaseClient } from "npm:@supabase/supabase-js";
import { cors } from "npm:hono/cors";
import { logger } from "npm:hono/logger";

import { Cliente, Cotizacion, ItemCotizacion, Producto, EstadoCotizacion, Ajustes, Pago, Plantilla } from "../../../src/app/types/index.ts";

const app = new Hono();

app.use('*', logger(console.log));

app.use(
  "/*",
  cors({
    origin: "*",
    allowHeaders: ["Content-Type", "Authorization"],
    allowMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    exposeHeaders: ["Content-Length"],
    maxAge: 600,
  }),
);

// ─── Portal público (SIN autenticación) ───────────────────────────────────────

app.get("/health", (c) => c.json({ ok: true }));
app.get("/make-server-feea4382/health", (c) => c.json({ ok: true }));

// ─── Proxy transparente hacia Supabase (resuelve mixed-content HTTP→HTTPS) ────
const SUPA_URL = Deno.env.get("SUPABASE_URL") ?? "";

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, PATCH, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization, apikey, x-client-info, x-supabase-api-version",
  "Access-Control-Max-Age": "86400",
};

// Interceptar preflight OPTIONS antes de reenviar a Supabase
app.options("/supa-proxy/*", (c) => {
  return new Response(null, { status: 204, headers: CORS_HEADERS });
});

app.all("/supa-proxy/*", async (c) => {
  const path = c.req.path.replace("/supa-proxy", "");
  const urlObj = new URL(c.req.url);
  const targetUrl = `${SUPA_URL}${path}${urlObj.search}`;

  const headers = new Headers();
  for (const [key, val] of Object.entries(c.req.header())) {
    const lower = key.toLowerCase();
    if (lower !== "host" && lower !== "origin" && lower !== "referer") {
      headers.set(key, val as string);
    }
  }

  const body = ["GET", "HEAD", "OPTIONS"].includes(c.req.method) ? undefined : await c.req.raw.blob();

  const res = await fetch(targetUrl, { method: c.req.method, headers, body });

  const resHeaders = new Headers(res.headers);
  Object.entries(CORS_HEADERS).forEach(([k, v]) => resHeaders.set(k, v));

  return new Response(res.body, { status: res.status, headers: resHeaders });
});

const getServiceClient = () => {
  const url = Deno.env.get("SUPABASE_URL") ?? "";
  const key = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? Deno.env.get("SUPABASE_ANON_KEY") ?? "";
  return createClient(url, key);
};

const toItemCotizacionRow = (item: any, cotizacionId: string, orgId?: string) => ({
  cotizacion_id: cotizacionId,
  ...(orgId ? { organizacion_id: orgId } : {}),
  producto_id: item.producto_id || null,
  posicion: item.posicion,
  cantidad: item.cantidad,
  unidad: item.unidad,
  descripcion: item.descripcion,
  precio_unitario: item.precio_unitario ?? null,
  costo_unitario: item.costo_unitario ?? null,
  iva_item: item.iva_item ?? 0,
  total_item: item.total_item ?? 0,
  metadata: {
    numero_proyecto: item.numero_proyecto || null,
    incluir_setup: item.incluir_setup ?? null,
    meses_cobrados: item.meses_cobrados ?? null,
    asientos_extra: item.asientos_extra ?? null,
  },
});

const toLegacyItemCotizacionRow = (item: any, cotizacionId: string, orgId?: string) => {
  const { metadata, ...row } = toItemCotizacionRow(item, cotizacionId, orgId);
  return row;
};

const insertItemsCotizacion = async (supabase: SupabaseClient, items: any[], cotizacionId: string, orgId?: string) => {
  if (items.length === 0) return;

  const itemsToInsert = items.map((item: any) => toItemCotizacionRow(item, cotizacionId, orgId));
  let { error } = await supabase.from('items_cotizacion').insert(itemsToInsert);

  if (error && String(error.message || "").includes("metadata")) {
    const legacyItems = items.map((item: any) => toLegacyItemCotizacionRow(item, cotizacionId));
    const retry = await supabase.from('items_cotizacion').insert(legacyItems);
    error = retry.error;
  }

  if (error) throw error;
};

// Frontend analysis fields that must never reach the DB (not columns in cotizaciones)
const CLIENT_ONLY_FIELDS = new Set(["costo", "utilidad", "margen", "cliente", "items"]);

const optionalCotizacionColumns = [
  "costos_indirectos",
  "comisiones_pago",
  "token_publico",
  "token_expira_en",
  "firma_imagen",
  "firma_nombre",
  "firma_fecha",
  "firma_ip",
  "comentario_cliente",
  "cotizacion_padre_id",
  "version",
];

const retryWithoutMissingCotizacionColumns = async (
  supabase: SupabaseClient,
  cotizacionData: Record<string, unknown>,
) => {
  let payload = { ...cotizacionData };

  for (let attempt = 0; attempt <= optionalCotizacionColumns.length; attempt++) {
    const result = await supabase
      .from('cotizaciones')
      .insert(payload)
      .select()
      .single();

    if (!result.error) return result;

    const message = String(result.error.message || "");
    const missingColumn = optionalCotizacionColumns.find(column => message.includes(`'${column}'`) || message.includes(`"${column}"`) || message.includes(column));

    if (!missingColumn || !(missingColumn in payload)) {
      return result;
    }

    const { [missingColumn]: _removed, ...nextPayload } = payload;
    payload = nextPayload;
  }

  return supabase
    .from('cotizaciones')
    .insert(payload)
    .select()
    .single();
};

app.get("/portal/:token", async (c) => {
  try {
    const token = c.req.param("token");
    const supabase = getServiceClient();
    const { data, error } = await supabase
      .from("cotizaciones")
      .select("*, items:items_cotizacion(*), cliente:clientes(*)")
      .eq("token_publico", token)
      .single();
    if (error || !data) return c.json({ error: "Cotización no encontrada o token inválido." }, 404);
    if (data.token_expira_en && new Date(data.token_expira_en) < new Date()) {
      return c.json({ error: "Este link ha expirado." }, 410);
    }
    // Incluir ajustes de empresa para el PDF público
    const { data: ajustesRow } = await supabase
      .from("ajustes")
      .select("data")
      .eq("id", data.organizacion_id)
      .single();
    // Incluir productos de la organización para el template Moodboard
    const { data: productosData } = await supabase
      .from("productos")
      .select("*")
      .eq("organizacion_id", data.organizacion_id);
    return c.json({ ...data, ajustes: ajustesRow?.data || {}, productos: productosData || [] });
  } catch (e) {
    return c.json({ error: "Error interno" }, 500);
  }
});

app.post("/portal/:token/aprobar", async (c) => {
  try {
    const token = c.req.param("token");
    const { firma_imagen, firma_nombre, firma_ip } = await c.req.json();
    const supabase = getServiceClient();
    const { data: cot } = await supabase
      .from("cotizaciones").select("id, token_expira_en").eq("token_publico", token).single();
    if (!cot) return c.json({ error: "Token inválido" }, 404);
    if (cot.token_expira_en && new Date(cot.token_expira_en) < new Date()) {
      return c.json({ error: "Link expirado" }, 410);
    }
    const { error } = await supabase.from("cotizaciones").update({
      estado: "Aprobada",
      firma_imagen: firma_imagen || null,
      firma_nombre: firma_nombre || null,
      firma_fecha: new Date().toISOString(),
      firma_ip: firma_ip || null,
    }).eq("id", cot.id);
    if (error) throw error;
    return c.json({ success: true });
  } catch (e) {
    return c.json({ error: "Error al aprobar" }, 500);
  }
});

app.post("/portal/:token/rechazar", async (c) => {
  try {
    const token = c.req.param("token");
    const { comentario } = await c.req.json();
    const supabase = getServiceClient();
    const { data: cot } = await supabase
      .from("cotizaciones").select("id").eq("token_publico", token).single();
    if (!cot) return c.json({ error: "Token inválido" }, 404);
    const { error } = await supabase.from("cotizaciones").update({
      estado: "Cancelada",
      comentario_cliente: comentario || null,
    }).eq("id", cot.id);
    if (error) throw error;
    return c.json({ success: true });
  } catch (e) {
    return c.json({ error: "Error al rechazar" }, 500);
  }
});

app.post("/portal/:token/solicitar-cambios", async (c) => {
  try {
    const token = c.req.param("token");
    const { comentario } = await c.req.json();
    const supabase = getServiceClient();
    const { data: cot } = await supabase
      .from("cotizaciones").select("id").eq("token_publico", token).single();
    if (!cot) return c.json({ error: "Token inválido" }, 404);
    const { error } = await supabase.from("cotizaciones").update({
      comentario_cliente: comentario || null,
    }).eq("id", cot.id);
    if (error) throw error;
    return c.json({ success: true });
  } catch (e) {
    return c.json({ error: "Error al guardar comentario" }, 500);
  }
});

// Generar/renovar token y preparar link del portal (requiere auth)
app.post("/cotizaciones/:id/generar-token-portal", async (c) => {
  try {
    const authHeader = c.req.header("Authorization");
    if (!authHeader) {
      return c.json({ error: "No autorizado. Token faltante." }, 401);
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
    const supabase = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
    });

    const { data: { user }, error: authError } = await supabase.auth.getUser();
    if (authError || !user) {
      return c.json({ error: "No autorizado. Token inválido." }, 401);
    }

    const id = c.req.param("id");
    const { data: cot } = await supabase.from("cotizaciones").select("validez_dias").eq("id", id).single();
    if (!cot) return c.json({ error: "Cotización no encontrada" }, 404);
    const token = crypto.randomUUID();
    const expira = new Date();
    expira.setDate(expira.getDate() + (cot.validez_dias || 30));
    const { error } = await supabase.from("cotizaciones").update({
      token_publico: token,
      token_expira_en: expira.toISOString(),
      estado: "Enviada",
    }).eq("id", id);
    if (error) throw error;
    return c.json({ token, expira: expira.toISOString() });
  } catch (e) {
    return c.json({ error: "Error al generar token" }, 500);
  }
});

const authMiddleware = async (c: any, next: any) => {
  if (c.req.path.endsWith("/health") || c.req.path.includes("/portal/")) {
    return next();
  }

  const authHeader = c.req.header("Authorization");
  if (!authHeader) {
    return c.json({ error: "No autorizado. Token faltante." }, 401);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";

  if (!supabaseUrl || !supabaseAnonKey) {
    // If not running in Supabase environment, pass through for local dev if needed
    // or fail. Better to fail securely.
    return c.json({ error: "Error de configuración de servidor." }, 500);
  }

  const supabase = createClient(supabaseUrl, supabaseAnonKey, {
    global: { headers: { Authorization: authHeader } },
  });

  const { data: { user }, error } = await supabase.auth.getUser();

  if (error || !user) {
    return c.json({ error: "No autorizado. Token inválido." }, 401);
  }

  // Extraer organización (Saas Phase 2)
  // Usamos el Service Client para bypasear RLS (evita dependencia circular)
  const adminClient = getServiceClient();
  const { data: orgData } = await adminClient
    .from('perfiles_organizacion')
    .select('organizacion_id')
    .eq('usuario_id', user.id)
    .limit(1)
    .maybeSingle();

  if (orgData?.organizacion_id) {
    c.set("organizacionId", orgData.organizacion_id);
  } else {
    return c.json({ error: "El usuario no pertenece a ninguna organización." }, 403);
  }

  c.set("user", user);
  c.set("supabase", supabase);
  await next();
};

app.use("/*", authMiddleware);

app.get("/clientes", async (c) => {
  try {
    const supabase = c.get("supabase") as SupabaseClient;
    const { data, error } = await supabase.from('clientes').select('*');
    if (error) throw error;
    return c.json(data);
  } catch (error: any) {
    console.error('[make-server] Error fetching clientes:', error);
    return c.json({ error: 'Error fetching clientes', details: error?.message || String(error), code: error?.code }, 500);
  }
});

app.post("/clientes", async (c) => {
  try {
    const supabase = c.get("supabase") as SupabaseClient;
    const cliente: any = await c.req.json();
    cliente.organizacion_id = c.get("organizacionId");

    const { data, error } = await supabase.from('clientes').insert(cliente).select().single();
    if (error) throw error;
    return c.json(data);
  } catch (error) {
    console.error('[make-server] Error creating cliente:', error);
    return c.json({ error: 'Error creating cliente' }, 500);
  }
});

app.put("/clientes/:id", async (c) => {
  try {
    const supabase = c.get("supabase") as SupabaseClient;
    const id = c.req.param('id');
    const updates: Partial<Cliente> = await c.req.json();

    const { data, error } = await supabase.from('clientes').update(updates).eq('id', id).select().single();
    if (error) throw error;
    return c.json(data);
  } catch (error) {
    console.error('[make-server] Error updating cliente:', error);
    return c.json({ error: 'Error updating cliente' }, 500);
  }
});

app.delete("/clientes/:id", async (c) => {
  try {
    const supabase = c.get("supabase") as SupabaseClient;
    const id = c.req.param('id');

    const { error } = await supabase.from('clientes').delete().eq('id', id);
    if (error) throw error;
    return c.json({ success: true });
  } catch (error) {
    console.error('[make-server] Error deleting cliente:', error);
    return c.json({ error: 'Error deleting cliente' }, 500);
  }
});

app.get("/productos", async (c) => {
  try {
    const supabase = c.get("supabase") as SupabaseClient;
    const { data, error } = await supabase.from('productos').select('*');
    if (error) throw error;
    return c.json(data);
  } catch (error) {
    console.error('[make-server] Error fetching productos:', error);
    return c.json({ error: 'Error fetching productos' }, 500);
  }
});

app.post("/productos", async (c) => {
  try {
    const supabase = c.get("supabase") as SupabaseClient;
    const producto: any = await c.req.json();
    producto.organizacion_id = c.get("organizacionId");

    const { data, error } = await supabase.from('productos').insert(producto).select().single();
    if (error) throw error;
    return c.json(data);
  } catch (error) {
    console.error('[make-server] Error creating producto:', error);
    return c.json({ error: 'Error creating producto' }, 500);
  }
});

app.put("/productos/:id", async (c) => {
  try {
    const supabase = c.get("supabase") as SupabaseClient;
    const id = c.req.param('id');
    const updates: Partial<Producto> = await c.req.json();

    const { data, error } = await supabase.from('productos').update(updates).eq('id', id).select().single();
    if (error) throw error;
    return c.json(data);
  } catch (error) {
    console.error('[make-server] Error updating producto:', error);
    return c.json({ error: 'Error updating producto' }, 500);
  }
});

app.delete("/productos/:id", async (c) => {
  try {
    const supabase = c.get("supabase") as SupabaseClient;
    const id = c.req.param('id');

    const { error } = await supabase.from('productos').delete().eq('id', id);
    if (error) throw error;
    return c.json({ success: true });
  } catch (error) {
    console.error('[make-server] Error deleting producto:', error);
    return c.json({ error: 'Error deleting producto' }, 500);
  }
});

// Unwrap metadata fields stored in JSONB back to root-level item properties
const unwrapItemMetadata = (item: any) => {
  const meta = item.metadata || {};
  return {
    ...item,
    numero_proyecto: item.numero_proyecto ?? meta.numero_proyecto ?? null,
    incluir_setup: item.incluir_setup ?? meta.incluir_setup ?? null,
    meses_cobrados: item.meses_cobrados ?? meta.meses_cobrados ?? null,
    asientos_extra: item.asientos_extra ?? meta.asientos_extra ?? null,
  };
};

// Get the highest sequential folio number across all non-version cotizaciones
const getUltimaFolioNumber = async (supabase: SupabaseClient): Promise<number> => {
  const { data } = await supabase
    .from('cotizaciones')
    .select('folio')
    .not('folio', 'ilike', '%-V%');
  if (!data || data.length === 0) return 0;
  return data.reduce((max, c) => {
    if (!c.folio) return max;
    const n = parseInt(c.folio.split('-').pop() || '0');
    return !isNaN(n) && n > max ? n : max;
  }, 0);
};

app.get("/cotizaciones", async (c) => {
  try {
    const supabase = c.get("supabase") as SupabaseClient;
    const { data, error } = await supabase.from('cotizaciones').select('*, items:items_cotizacion(*)');
    if (error) throw error;
    const result = (data || []).map((cot: any) => ({
      ...cot,
      items: (cot.items || []).map(unwrapItemMetadata)
    }));
    return c.json(result);
  } catch (error) {
    console.error('[make-server] Error fetching cotizaciones:', error);
    return c.json({ error: 'Error fetching cotizaciones' }, 500);
  }
});

app.post("/cotizaciones", async (c) => {
  try {
    const supabase = c.get("supabase") as SupabaseClient;
    const payload = await c.req.json();
    const items = payload.items || [];
    const cotizacionData: any = { ...payload };
    cotizacionData.organizacion_id = c.get("organizacionId");
    delete cotizacionData.items;

    // Get highest sequential folio number (skips version folios like -V2)
    const ultimaFolio = await getUltimaFolioNumber(supabase);

    const { data: ajustes } = await supabase.from('ajustes').select('data').eq('id', c.get("organizacionId")).single();
    const prefijo = ajustes?.data?.prefijo_folio || '';

    if (cotizacionData.cotizacion_padre_id) {
      // Es una nueva versión
      const { data: padre } = await supabase.from('cotizaciones').select('folio').eq('id', cotizacionData.cotizacion_padre_id).single();
      if (padre) {
        const baseFolio = padre.folio.split('-V')[0];
        cotizacionData.folio = `${baseFolio}-V${cotizacionData.version || 2}`;
      } else {
        // Fallback si el padre no existe por alguna razón
        const año = new Date().getFullYear();
        const numeroFormateado = (ultimaFolio + 1).toString().padStart(5, '0');
        cotizacionData.folio = prefijo ? `${prefijo}-${año}-${numeroFormateado}` : `${año}-${numeroFormateado}`;
      }
    } else {
      // Generación de folio estándar correlativo
      const año = new Date().getFullYear();
      const numeroFormateado = (ultimaFolio + 1).toString().padStart(5, '0');
      cotizacionData.folio = prefijo ? `${prefijo}-${año}-${numeroFormateado}` : `${año}-${numeroFormateado}`;
    }

    // Remove frontend-only fields that have no column in the cotizaciones table
    for (const key of CLIENT_ONLY_FIELDS) {
      delete (cotizacionData as any)[key];
    }

    const { data: nuevaCotizacion, error: insertError } = await retryWithoutMissingCotizacionColumns(supabase, cotizacionData);

    if (insertError) throw insertError;

    if (items.length > 0) {
      try {
        await insertItemsCotizacion(supabase, items, nuevaCotizacion.id, c.get("organizacionId"));
      } catch (itemsError) {
        await supabase.from('cotizaciones').delete().eq('id', nuevaCotizacion.id);
        throw itemsError;
      }
    }

    const { data: finalCotizacion } = await supabase
      .from('cotizaciones')
      .select('*, items:items_cotizacion(*)')
      .eq('id', nuevaCotizacion.id)
      .single();

    return c.json(finalCotizacion);
  } catch (error) {
    console.error('[make-server] Error creating cotizacion:', error);
    const details = error instanceof Error ? error.message : JSON.stringify(error);
    return c.json({ error: 'Error creating cotizacion', details }, 500);
  }
});

app.put("/cotizaciones/:id", async (c) => {
  try {
    const supabase = c.get("supabase") as SupabaseClient;
    const id = c.req.param('id');
    const payload = await c.req.json();

    const items = payload.items;
    const cotizacionData = { ...payload };
    delete cotizacionData.items;
    for (const key of CLIENT_ONLY_FIELDS) delete (cotizacionData as any)[key];

    let { error: updateError } = await supabase
      .from('cotizaciones')
      .update(cotizacionData)
      .eq('id', id);

    if (updateError) {
      const message = String(updateError.message || "");
      const missingColumn = optionalCotizacionColumns.find(column => message.includes(`'${column}'`) || message.includes(`"${column}"`) || message.includes(column));

      if (missingColumn && missingColumn in cotizacionData) {
        const { [missingColumn]: _removed, ...legacyCotizacionData } = cotizacionData;
        const retry = await supabase
          .from('cotizaciones')
          .update(legacyCotizacionData)
          .eq('id', id);
        updateError = retry.error;
      }
    }

    if (updateError) throw updateError;

    if (items !== undefined) {
      // Reemplazo completo de items: borrar existentes y crear nuevos
      await supabase.from('items_cotizacion').delete().eq('cotizacion_id', id);
      if (items.length > 0) {
        await insertItemsCotizacion(supabase, items, id, c.get("organizacionId"));
      }
    }

    const { data: finalCotizacion } = await supabase
      .from('cotizaciones')
      .select('*, items:items_cotizacion(*)')
      .eq('id', id)
      .single();

    return c.json(finalCotizacion);
  } catch (error) {
    console.error('[make-server] Error updating cotizacion:', error);
    const details = error instanceof Error ? error.message : JSON.stringify(error);
    return c.json({ error: 'Error updating cotizacion', details }, 500);
  }
});

app.delete("/cotizaciones/:id", async (c) => {
  try {
    const supabase = c.get("supabase") as SupabaseClient;
    const id = c.req.param('id');

    // items and pagos should be cascade deleted by FK, but let's be safe for pagos
    await supabase.from('pagos').delete().eq('cotizacion_id', id);
    const { error } = await supabase.from('cotizaciones').delete().eq('id', id);
    if (error) throw error;

    return c.json({ success: true });
  } catch (error) {
    console.error('[make-server] Error deleting cotizacion:', error);
    return c.json({ error: 'Error deleting cotizacion' }, 500);
  }
});

app.post("/cotizaciones/:id/duplicate", async (c) => {
  try {
    const supabase = c.get("supabase") as SupabaseClient;
    const id = c.req.param('id');

    const { data: cotizacionExistente, error: getError } = await supabase
      .from('cotizaciones')
      .select('*, items:items_cotizacion(*)')
      .eq('id', id)
      .single();

    if (getError || !cotizacionExistente) {
      return c.json({ error: 'Cotizacion not found' }, 404);
    }

    // Get highest sequential folio number
    const ultimaFolio = await getUltimaFolioNumber(supabase);

    // Get ajustes
    const { data: ajustesWrapper } = await supabase.from('ajustes').select('data').eq('id', c.get("organizacionId")).single();
    const prefijo = ajustesWrapper?.data?.prefijo_folio || '';

    const año = new Date().getFullYear();
    const numeroFormateado = (ultimaFolio + 1).toString().padStart(5, '0');

    const cotizacionDuplicadaPayload: any = {
      ...cotizacionExistente,
      folio: prefijo ? `${prefijo}-${año}-${numeroFormateado}` : `${año}-${numeroFormateado}`,
      estado: 'Borrador',
      fecha: new Date().toISOString().split('T')[0],
      organizacion_id: c.get("organizacionId")
    };

    delete cotizacionDuplicadaPayload.id;
    delete cotizacionDuplicadaPayload.created_at;
    delete cotizacionDuplicadaPayload.updated_at;
    const items = cotizacionDuplicadaPayload.items;
    delete cotizacionDuplicadaPayload.items;

    const { data: nuevaCotizacion, error: insertError } = await supabase
      .from('cotizaciones')
      .insert(cotizacionDuplicadaPayload)
      .select()
      .single();

    if (insertError) throw insertError;

    if (items && items.length > 0) {
      const itemsToInsert = items.map((item: any) => {
        const { id: itemId, cotizacion_id, ...itemData } = item;
        return { ...itemData, cotizacion_id: nuevaCotizacion.id, organizacion_id: c.get("organizacionId") };
      });
      await supabase.from('items_cotizacion').insert(itemsToInsert);
    }

    const { data: finalCotizacion } = await supabase
      .from('cotizaciones')
      .select('*, items:items_cotizacion(*)')
      .eq('id', nuevaCotizacion.id)
      .single();

    return c.json(finalCotizacion);
  } catch (error) {
    console.error('[make-server] Error duplicating cotizacion:', error);
    return c.json({ error: 'Error duplicating cotizacion' }, 500);
  }
});

app.get("/pagos", async (c) => {
  try {
    const supabase = c.get("supabase") as SupabaseClient;
    const { data, error } = await supabase.from('pagos').select('*');
    if (error) throw error;
    return c.json(data);
  } catch (error) {
    console.error('[make-server] Error fetching pagos:', error);
    return c.json({ error: 'Error fetching pagos' }, 500);
  }
});

app.get("/pagos/cotizacion/:cotizacionId", async (c) => {
  try {
    const supabase = c.get("supabase") as SupabaseClient;
    const cotizacionId = c.req.param('cotizacionId');
    const { data, error } = await supabase.from('pagos').select('*').eq('cotizacion_id', cotizacionId);
    if (error) throw error;
    return c.json(data);
  } catch (error) {
    console.error('[make-server] Error fetching pagos for cotizacion:', error);
    return c.json({ error: 'Error fetching pagos for cotizacion' }, 500);
  }
});

app.post("/pagos", async (c) => {
  try {
    const supabase = c.get("supabase") as SupabaseClient;
    const pago: any = await c.req.json();
    pago.organizacion_id = c.get("organizacionId");

    const { data: nuevoPago, error } = await supabase.from('pagos').insert(pago).select().single();
    if (error) throw error;

    const { data: pagosCotizacion } = await supabase.from('pagos').select('*').eq('cotizacion_id', pago.cotizacion_id);
    const totalPagado = (pagosCotizacion || []).reduce((sum, p) => sum + Number(p.monto), 0);

    const { data: cotizacion } = await supabase.from('cotizaciones').select('total').eq('id', pago.cotizacion_id).single();

    if (cotizacion && Math.abs(totalPagado - Number(cotizacion.total)) < 0.01) {
      await supabase.from('cotizaciones').update({ estado: 'Pagada' }).eq('id', pago.cotizacion_id);
    }

    return c.json(nuevoPago);
  } catch (error) {
    console.error('[make-server] Error creating pago:', error);
    return c.json({ error: 'Error creating pago' }, 500);
  }
});

app.get("/ajustes", async (c) => {
  try {
    const supabase = c.get("supabase") as SupabaseClient;
    const orgId = c.get("organizacionId");
    const { data, error } = await supabase.from('ajustes').select('data').eq('id', orgId).single();
    if (error) {
      // Return defaults if none
      return c.json({
        iva_por_defecto: 0.16,
        validez_por_defecto: 30,
        nota_por_defecto: 'Gracias por su preferencia.',
        prefijo_folio: '',
        offset_folio: 1,
        nombre_empresa: 'IDEALLY'
      });
    }
    return c.json(data.data);
  } catch (error) {
    console.error('[make-server] Error fetching ajustes:', error);
    return c.json({ error: 'Error fetching ajustes' }, 500);
  }
});

app.put("/ajustes", async (c) => {
  try {
    const supabase = c.get("supabase") as SupabaseClient;
    const updates: Partial<Ajustes> = await c.req.json();
    const orgId = c.get("organizacionId");

    const { data: currentAjustes } = await supabase.from('ajustes').select('data').eq('id', orgId).single();
    const ajustesActualizados = { ...(currentAjustes?.data || {}), ...updates };

    const { error } = await supabase.from('ajustes').upsert({ id: orgId, data: ajustesActualizados });
    if (error) throw error;

    return c.json(ajustesActualizados);
  } catch (error) {
    console.error('[make-server] Error updating ajustes:', error);
    return c.json({ error: 'Error updating ajustes' }, 500);
  }
});

app.post("/enviar-email", async (c) => {
  try {
    const supabase = c.get("supabase") as SupabaseClient;
    const { destinatario, asunto, mensaje, cotizacionId } = await c.req.json();

    if (!destinatario || !asunto || !cotizacionId) {
      return c.json({ error: 'Faltan campos requeridos' }, 400);
    }

    const resendApiKey = Deno.env.get('RESEND_API_KEY');
    if (!resendApiKey || resendApiKey === '' || resendApiKey === 'your-resend-api-key-here') {
      console.error('[make-server] Error enviando email: RESEND_API_KEY no configurada correctamente');
      return c.json({
        error: 'API key de Resend no configurada',
        hint: 'Obtén una API key gratis en https://resend.com/api-keys y configúrala en los secretos de Supabase'
      }, 500);
    }

    const { data: cotizacion, error: getCotError } = await supabase.from('cotizaciones').select('*').eq('id', cotizacionId).single();
    if (getCotError || !cotizacion) {
      return c.json({ error: 'Cotización no encontrada' }, 404);
    }

    const { data: cliente } = await supabase.from('clientes').select('*').eq('id', cotizacion.cliente_id).single();
    const orgId = c.get("organizacionId");
    const { data: ajustesData } = await supabase.from('ajustes').select('data').eq('id', orgId).single();
    const ajustes = ajustesData?.data || {};

    const emailHtml = `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
    .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; border-radius: 8px 8px 0 0; }
    .content { background: #f9fafb; padding: 30px; border: 1px solid #e5e7eb; }
    .footer { background: #f3f4f6; padding: 20px; text-align: center; font-size: 12px; color: #6b7280; border-radius: 0 0 8px 8px; }
    .info-row { margin: 10px 0; }
    .label { font-weight: bold; color: #4b5563; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1 style="margin: 0; font-size: 28px;">${ajustes.nombre_empresa || 'IDEALLY'}</h1>
      <p style="margin: 5px 0 0 0; opacity: 0.9;">${ajustes.tagline || 'Arte . Diseño . Ingeniería'}</p>
    </div>
    
    <div class="content">
      ${mensaje ? `<p>${mensaje.replace(/\n/g, '<br>')}</p>` : ''}
      
      <div style="background: white; padding: 20px; border-radius: 6px; margin: 20px 0; border-left: 4px solid #667eea;">
        <h2 style="margin-top: 0; color: #667eea;">Detalles de la Cotización</h2>
        
        <div class="info-row">
          <span class="label">Folio:</span> ${cotizacion.folio}
        </div>
        <div class="info-row">
          <span class="label">Fecha:</span> ${new Date(cotizacion.fecha).toLocaleDateString('es-MX')}
        </div>
        <div class="info-row">
          <span class="label">Cliente:</span> ${cliente?.nombre_razon_social || 'N/A'}
        </div>
        ${cotizacion.descripcion ? `
        <div class="info-row">
          <span class="label">Descripción:</span> ${cotizacion.descripcion}
        </div>
        ` : ''}
        <div class="info-row">
          <span class="label">Total:</span> <strong style="color: #059669; font-size: 18px;">${cotizacion.total.toLocaleString('es-MX', { minimumFractionDigits: 2, maximumFractionDigits: 2 })} ${cotizacion.con_factura ? '+ IVA' : ''}</strong>
        </div>
        <div class="info-row">
          <span class="label">Validez:</span> ${cotizacion.validez_dias} días
        </div>
      </div>
      
      ${cotizacion.nota ? `
      <div style="background: #fef3c7; padding: 15px; border-radius: 6px; margin: 20px 0; border-left: 4px solid #f59e0b;">
        <p style="margin: 0; color: #92400e;"><strong>Nota:</strong> ${cotizacion.nota}</p>
      </div>
      ` : ''}
    </div>
    
    <div class="footer">
      <p><strong>${ajustes.nombre_empresa || 'IDEALLY'}</strong></p>
      ${ajustes.direccion ? `<p>${ajustes.direccion}</p>` : ''}
      ${ajustes.telefono ? `<p>Tel: ${ajustes.telefono}</p>` : ''}
      ${ajustes.email ? `<p>Email: ${ajustes.email}</p>` : ''}
      ${ajustes.sitio_web ? `<p>Web: ${ajustes.sitio_web}</p>` : ''}
    </div>
  </div>
</body>
</html>
    `.trim();

    const response = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${resendApiKey}`
      },
      body: JSON.stringify({
        from: ajustes.email_envio || 'onboarding@resend.dev',
        to: destinatario,
        subject: asunto,
        html: emailHtml
      })
    });

    const result = await response.json();

    if (!response.ok) {
      console.error('[make-server] Error from Resend API:', result);

      let errorMessage = 'Error al enviar el email';
      let hint = '';

      if (response.status === 401) {
        errorMessage = 'API key de Resend inválida';
        hint = 'Verifica que hayas ingresado una API key válida de Resend. Obtén una en https://resend.com/api-keys';
      } else if (response.status === 403) {
        errorMessage = 'Acceso denegado por Resend';
        hint = 'Verifica que tu cuenta de Resend esté activa y el dominio verificado';
      } else if (response.status === 422) {
        errorMessage = 'Datos de email inválidos';
        hint = result.message || 'Verifica el email del destinatario y que el dominio "from" esté verificado en Resend';
      }

      return c.json({
        error: errorMessage,
        hint: hint,
        details: result
      }, response.status);
    }

    return c.json({
      success: true,
      messageId: result.id
    });

  } catch (error) {
    console.error('[make-server] Error sending email:', error);
    return c.json({
      error: 'Error al enviar el email: ' + error.message,
      hint: 'Verifica tu conexión a internet y la configuración de Resend'
    }, 500);
  }
});

// ─── IA — Redacción con Claude ───────────────────────────────────────────────

app.post("/ia/mejorar-descripcion", async (c) => {
  try {
    const anthropicKey = Deno.env.get("ANTHROPIC_API_KEY");
    if (!anthropicKey) {
      return c.json({ error: "ANTHROPIC_API_KEY no configurada en los secretos de Supabase." }, 500);
    }

    const { descripcion, contexto } = await c.req.json();
    if (!descripcion?.trim()) {
      return c.json({ error: "descripcion es requerida" }, 400);
    }

    const prompt = `Eres un redactor profesional de cotizaciones para IDEALLY, una empresa mexicana de Arte, Diseño e Ingeniería. Tu tarea es reformular descripciones técnicas de servicios/productos para que sean claras, profesionales y orientadas al valor que recibe el cliente (no técnicas).

Descripción original: "${descripcion}"${contexto ? `\nContexto adicional: ${contexto}` : ""}

Responde ÚNICAMENTE con la descripción reformulada. Sin explicaciones, sin comillas, sin listas. Máximo 2 oraciones concisas.`;

    const response = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "x-api-key": anthropicKey,
        "anthropic-version": "2023-06-01",
        "content-type": "application/json",
      },
      body: JSON.stringify({
        model: "claude-haiku-4-5-20251001",
        max_tokens: 300,
        messages: [{ role: "user", content: prompt }],
      }),
    });

    if (!response.ok) {
      const err = await response.json();
      console.error("[make-server] Anthropic API error:", err);
      return c.json({ error: "Error al llamar a Claude API" }, 500);
    }

    const result = await response.json();
    const mejora = result.content?.[0]?.text?.trim() || descripcion;
    return c.json({ descripcion_mejorada: mejora });
  } catch (error) {
    console.error("[make-server] Error en /ia/mejorar-descripcion:", error);
    return c.json({ error: "Error interno" }, 500);
  }
});

app.post("/ia/generar-nota", async (c) => {
  try {
    const anthropicKey = Deno.env.get("ANTHROPIC_API_KEY");
    if (!anthropicKey) {
      return c.json({ error: "ANTHROPIC_API_KEY no configurada" }, 500);
    }

    const { cliente, descripcion, items } = await c.req.json();

    const prompt = `Eres un redactor profesional de IDEALLY (Arte, Diseño e Ingeniería, México). Genera una nota de cierre cálida y profesional para una cotización.

Cliente: ${cliente || "cliente"}
Proyecto: ${descripcion || "proyecto"}
Servicios incluidos: ${Array.isArray(items) ? items.map((i: any) => i.descripcion).join(", ") : "servicios"}

Escribe una nota de cierre de 2-3 oraciones que exprese disposición para responder dudas y proyecte confianza. Tono: profesional pero cercano. Solo la nota, sin saludos ni despedidas formales.`;

    const response = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "x-api-key": anthropicKey,
        "anthropic-version": "2023-06-01",
        "content-type": "application/json",
      },
      body: JSON.stringify({
        model: "claude-haiku-4-5-20251001",
        max_tokens: 200,
        messages: [{ role: "user", content: prompt }],
      }),
    });

    const result = await response.json();
    const nota = result.content?.[0]?.text?.trim() || "";
    return c.json({ nota });
  } catch (error) {
    console.error("[make-server] Error en /ia/generar-nota:", error);
    return c.json({ error: "Error interno" }, 500);
  }
});

// ─── Plantillas de cotización ────────────────────────────────────────────────

app.get("/plantillas", async (c) => {
  try {
    const supabase = c.get("supabase") as SupabaseClient;
    const { data, error } = await supabase
      .from("plantillas_cotizacion")
      .select("*")
      .order("created_at", { ascending: false });
    if (error) throw error;
    return c.json(data);
  } catch (error) {
    console.error("[make-server] Error fetching plantillas:", error);
    return c.json({ error: "Error fetching plantillas" }, 500);
  }
});

app.post("/plantillas", async (c) => {
  try {
    const supabase = c.get("supabase") as SupabaseClient;
    const body: Omit<Plantilla, "id" | "created_at"> = await c.req.json();
    const payload: Record<string, unknown> = {
      nombre: body.nombre,
      descripcion: body.descripcion || null,
      items: body.items || [],
      nota: body.nota || null,
      con_factura: body.con_factura ?? true,
      updated_at: new Date().toISOString(),
      organizacion_id: c.get("organizacionId"),
    };

    let { data, error } = await supabase
      .from("plantillas_cotizacion")
      .insert(payload)
      .select()
      .single();

    if (error && String(error.message || "").includes("con_factura")) {
      const { con_factura, updated_at, ...legacyPayload } = payload;
      const retry = await supabase
        .from("plantillas_cotizacion")
        .insert(legacyPayload)
        .select()
        .single();
      data = retry.data;
      error = retry.error;
    }

    if (error) throw error;
    return c.json(data);
  } catch (error) {
    console.error("[make-server] Error creating plantilla:", error);
    const details = error instanceof Error ? error.message : JSON.stringify(error);
    return c.json({
      error: "Error creating plantilla",
      details
    }, 500);
  }
});

app.put("/plantillas/:id", async (c) => {
  try {
    const supabase = c.get("supabase") as SupabaseClient;
    const id = c.req.param("id");
    const body: Partial<Plantilla> = await c.req.json();
    const payload: Record<string, unknown> = {
      updated_at: new Date().toISOString(),
    };
    if (body.nombre !== undefined) payload.nombre = body.nombre;
    if (body.descripcion !== undefined) payload.descripcion = body.descripcion || null;
    if (body.items !== undefined) payload.items = body.items;
    if (body.nota !== undefined) payload.nota = body.nota || null;
    if (body.con_factura !== undefined) payload.con_factura = body.con_factura;

    let { data, error } = await supabase
      .from("plantillas_cotizacion")
      .update(payload)
      .eq("id", id)
      .select()
      .single();

    if (error && String(error.message || "").includes("con_factura")) {
      const { con_factura, updated_at, ...legacyPayload } = payload;
      const retry = await supabase
        .from("plantillas_cotizacion")
        .update(legacyPayload)
        .eq("id", id)
        .select()
        .single();
      data = retry.data;
      error = retry.error;
    }

    if (error) throw error;
    return c.json(data);
  } catch (error) {
    console.error("[make-server] Error updating plantilla:", error);
    const details = error instanceof Error ? error.message : JSON.stringify(error);
    return c.json({
      error: "Error updating plantilla",
      details
    }, 500);
  }
});

app.delete("/plantillas/:id", async (c) => {
  try {
    const supabase = c.get("supabase") as SupabaseClient;
    const id = c.req.param("id");
    const { error } = await supabase
      .from("plantillas_cotizacion")
      .delete()
      .eq("id", id);
    if (error) throw error;
    return c.json({ success: true });
  } catch (error) {
    console.error("[make-server] Error deleting plantilla:", error);
    return c.json({ error: "Error deleting plantilla" }, 500);
  }
});

// ─── Historial de precios ─────────────────────────────────────────────────────

app.post("/productos/:id/historial-precio", async (c) => {
  try {
    const supabase = c.get("supabase") as SupabaseClient;
    const productoId = c.req.param("id");
    const { precio_anterior, precio_nuevo } = await c.req.json();
    const { error } = await supabase.from("historial_precios").insert({
      producto_id: productoId,
      precio_anterior,
      precio_nuevo,
      organizacion_id: c.get("organizacionId")
    });
    if (error) throw error;
    return c.json({ success: true });
  } catch (error) {
    console.error("[make-server] Error saving historial precio:", error);
    return c.json({ error: "Error saving historial" }, 500);
  }
});

app.get("/productos/:id/historial-precios", async (c) => {
  try {
    const supabase = c.get("supabase") as SupabaseClient;
    const productoId = c.req.param("id");
    const { data, error } = await supabase
      .from("historial_precios")
      .select("*")
      .eq("producto_id", productoId)
      .order("fecha", { ascending: false })
      .limit(20);
    if (error) throw error;
    return c.json(data);
  } catch (error) {
    console.error("[make-server] Error fetching historial precios:", error);
    return c.json({ error: "Error fetching historial" }, 500);
  }
});

// ─── Gestión de Equipo e Invitaciones (SaaS) ────────────────────────────────

app.get("/equipo", async (c) => {
  try {
    const supabase = c.get("supabase") as SupabaseClient;
    const orgId = c.get("organizacionId");

    // Obtenemos los perfiles
    const { data: perfiles, error } = await supabase
      .from('perfiles_organizacion')
      .select('*')
      .eq('organizacion_id', orgId);
    
    if (error) throw error;

    // Necesitamos los emails, que están en auth.users (solo accesible con service role)
    const adminSupabase = getServiceClient();
    
    // Obtenemos todos los usuarios para mapear el email
    const { data: authUsers, error: authError } = await adminSupabase.auth.admin.listUsers();
    
    if (authError) throw authError;

    const equipoConEmails = perfiles.map(p => {
      const user = authUsers.users.find(u => u.id === p.usuario_id);
      return {
        ...p,
        email: user?.email || 'Usuario Desconocido'
      };
    });

    return c.json(equipoConEmails);
  } catch (error) {
    console.error("[make-server] Error fetching equipo:", error);
    return c.json({ error: "Error fetching equipo" }, 500);
  }
});

app.get("/invitaciones", async (c) => {
  try {
    const supabase = c.get("supabase") as SupabaseClient;
    const orgId = c.get("organizacionId");

    const { data, error } = await supabase
      .from('invitaciones_equipo')
      .select('*')
      .eq('organizacion_id', orgId);

    if (error) throw error;
    return c.json(data);
  } catch (error) {
    console.error("[make-server] Error fetching invitaciones:", error);
    return c.json({ error: "Error fetching invitaciones" }, 500);
  }
});

app.post("/invitaciones", async (c) => {
  try {
    const supabase = c.get("supabase") as SupabaseClient;
    const orgId = c.get("organizacionId");
    const user = c.get("user");
    const { email, rol } = await c.req.json();

    if (!email || !rol) return c.json({ error: "Email y rol son requeridos" }, 400);

    const { data, error } = await supabase
      .from('invitaciones_equipo')
      .insert({
        organizacion_id: orgId,
        email: email.toLowerCase(),
        rol,
        invitado_por: user.id
      })
      .select()
      .single();

    if (error) throw error;
    return c.json(data);
  } catch (error) {
    console.error("[make-server] Error creating invitacion:", error);
    return c.json({ error: "Error creating invitacion" }, 500);
  }
});

app.delete("/invitaciones/:id", async (c) => {
  try {
    const supabase = c.get("supabase") as SupabaseClient;
    const id = c.req.param("id");

    const { error } = await supabase
      .from('invitaciones_equipo')
      .delete()
      .eq('id', id);

    if (error) throw error;
    return c.json({ success: true });
} catch (error) {
    console.error("[make-server] Error deleting invitacion:", error);
    return c.json({ error: "Error deleting invitacion" }, 500);
  }
});

const ORG_PRINCIPAL_ID = "00000000-0000-0000-0000-000000000001";

app.post("/organizaciones/crear-con-invitacion", async (c) => {
  try {
    const user = c.get("user");
    const currentOrgId = c.get("organizacionId");

    // Restringir a la Organización Principal (Super-Admin)
    if (currentOrgId !== ORG_PRINCIPAL_ID) {
      return c.json({ error: "No autorizado. Solo la Organización Principal puede crear nuevas organizaciones." }, 403);
    }

    const { nombre, email } = await c.req.json();

    if (!nombre || !email) {
      return c.json({ error: "Nombre de organización y correo son requeridos" }, 400);
    }

    const adminClient = getServiceClient();

    // 1. Crear la nueva organización
    const { data: org, error: orgError } = await adminClient
      .from('organizaciones')
      .insert({ nombre })
      .select()
      .single();

    if (orgError) {
      console.error("[make-server] Error al crear la organización:", orgError);
      throw orgError;
    }

    // 2. Crear la invitación para esa organización
    const { data: inv, error: invError } = await adminClient
      .from('invitaciones_equipo')
      .insert({
        organizacion_id: org.id,
        email: email.toLowerCase(),
        rol: 'propietario', // El nuevo usuario es el propietario de esta nueva organización
        invitado_por: user.id
      })
      .select()
      .single();

    if (invError) {
      console.error("[make-server] Error al crear la invitación para la nueva organización:", invError);
      // Intentar limpiar la organización creada para evitar registros huérfanos
      await adminClient.from('organizaciones').delete().eq('id', org.id);
      throw invError;
    }

    // 3. Inicializar unos ajustes básicos para la nueva organización
    const { error: ajustesError } = await adminClient
      .from('ajustes')
      .insert({
        id: org.id,
        data: {
          iva_por_defecto: 0.16,
          validez_por_defecto: 30,
          nota_por_defecto: 'Gracias por su preferencia.',
          prefijo_folio: '',
          offset_folio: 1,
          nombre_empresa: nombre
        }
      });

    if (ajustesError) {
      console.error("[make-server] Advertencia: no se pudieron inicializar los ajustes de la nueva organización:", ajustesError);
    }

    return c.json({ success: true, organizacion: org, invitacion: inv });
  } catch (error: any) {
    console.error("[make-server] Error in /organizaciones/crear-con-invitacion:", error);
    return c.json({ error: error.message || "Error al crear la organización y la invitación" }, 500);
  }
});

// Obtener datos de la organización actual
app.get("/organizacion", async (c) => {
  try {
    const supabase = c.get("supabase") as SupabaseClient;
    const orgId = c.get("organizacionId");

    const { data, error } = await supabase
      .from("organizaciones")
      .select("id, nombre, modulos")
      .eq("id", orgId)
      .single();

    if (error) throw error;
    return c.json(data);
  } catch (error: any) {
    console.error("[make-server] Error fetching /organizacion:", error);
    return c.json({ error: error.message || "Error al obtener la organización" }, 500);
  }
});

// Listar todas las organizaciones (Solo Super-Admin)
app.get("/organizaciones", async (c) => {
  try {
    const currentOrgId = c.get("organizacionId");
    if (currentOrgId !== ORG_PRINCIPAL_ID) {
      return c.json({ error: "No autorizado." }, 403);
    }

    const adminClient = getServiceClient();
    const { data, error } = await adminClient
      .from("organizaciones")
      .select("*")
      .order("created_at", { ascending: false });

    if (error) throw error;
    return c.json(data);
  } catch (error: any) {
    console.error("[make-server] Error fetching /organizaciones:", error);
    return c.json({ error: error.message || "Error al obtener las organizaciones" }, 500);
  }
});

// Actualizar módulos de una organización (Solo Super-Admin)
app.put("/organizaciones/:id/modulos", async (c) => {
  try {
    const currentOrgId = c.get("organizacionId");
    if (currentOrgId !== ORG_PRINCIPAL_ID) {
      return c.json({ error: "No autorizado." }, 403);
    }

    const id = c.req.param("id");
    const { modulos } = await c.req.json();

    if (!modulos) {
      return c.json({ error: "Módulos son requeridos" }, 400);
    }

    const adminClient = getServiceClient();
    const { data, error } = await adminClient
      .from("organizaciones")
      .update({ modulos })
      .eq("id", id)
      .select()
      .single();

    if (error) throw error;
    return c.json(data);
  } catch (error: any) {
    console.error("[make-server] Error updating /organizaciones/:id/modulos:", error);
    return c.json({ error: error.message || "Error al actualizar los módulos" }, 500);
  }
});


// --- NOTAS SIMPLES ---

app.get("/notas", async (c) => {
  try {
    const supabase = c.get("supabase") as SupabaseClient;
    const { data, error } = await supabase
      .from('notas_simples')
      .select('*')
      .order('created_at', { ascending: false });
    if (error) throw error;
    return c.json(data);
  } catch (error: any) {
    console.error('[make-server] Error fetching notas:', error);
    return c.json({ error: error.message || 'Error al obtener las notas' }, 500);
  }
});

app.post("/notas", async (c) => {
  try {
    const supabase = c.get("supabase") as SupabaseClient;
    const nota = await c.req.json();
    
    // Quitar campos de control de fecha/hora para forzar el uso de now() de la base de datos
    delete nota.created_at;
    delete nota.updated_at;
    
    nota.organizacion_id = c.get("organizacionId");

    const { data, error } = await supabase
      .from('notas_simples')
      .insert(nota)
      .select()
      .single();
    if (error) throw error;
    return c.json(data);
  } catch (error: any) {
    console.error('[make-server] Error creating nota:', error);
    return c.json({ error: error.message || 'Error al crear la nota' }, 500);
  }
});

app.put("/notas/:id", async (c) => {
  try {
    const supabase = c.get("supabase") as SupabaseClient;
    const id = c.req.param('id');
    const updates = await c.req.json();

    // No permitir alterar fecha de creación ni organización asociada
    delete updates.created_at;
    delete updates.organizacion_id;
    updates.updated_at = new Date().toISOString();

    const { data, error } = await supabase
      .from('notas_simples')
      .update(updates)
      .eq('id', id)
      .select()
      .single();
    if (error) throw error;
    return c.json(data);
  } catch (error: any) {
    console.error('[make-server] Error updating nota:', error);
    return c.json({ error: error.message || 'Error al actualizar la nota' }, 500);
  }
});

app.delete("/notas/:id", async (c) => {
  try {
    const supabase = c.get("supabase") as SupabaseClient;
    const id = c.req.param('id');

    const { data, error } = await supabase
      .from('notas_simples')
      .delete()
      .eq('id', id)
      .select()
      .single();
    if (error) throw error;
    return c.json(data);
  } catch (error: any) {
    console.error('[make-server] Error deleting nota:', error);
    return c.json({ error: error.message || 'Error al eliminar la nota' }, 500);
  }
});
// --- PROVEEDORES ---

app.get("/proveedores", async (c) => {
  try {
    const supabase = c.get("supabase") as SupabaseClient;
    const orgId = c.get("organizacionId");
    const { data, error } = await supabase
      .from("proveedores")
      .select("*")
      .eq("organizacion_id", orgId)
      .order("created_at", { ascending: false });
    if (error) throw error;
    return c.json(data);
  } catch (error: any) {
    return c.json({ error: error.message }, 500);
  }
});

app.post("/proveedores", async (c) => {
  try {
    const supabase = c.get("supabase") as SupabaseClient;
    const orgId = c.get("organizacionId");
    const payload = await c.req.json();
    const { data, error } = await supabase
      .from("proveedores")
      .insert({ ...payload, organizacion_id: orgId })
      .select()
      .single();
    if (error) throw error;
    return c.json(data);
  } catch (error: any) {
    return c.json({ error: error.message }, 500);
  }
});

app.put("/proveedores/:id", async (c) => {
  try {
    const supabase = c.get("supabase") as SupabaseClient;
    const id = c.req.param("id");
    const payload = await c.req.json();
    const { data, error } = await supabase
      .from("proveedores")
      .update(payload)
      .eq("id", id)
      .select()
      .single();
    if (error) throw error;
    return c.json(data);
  } catch (error: any) {
    return c.json({ error: error.message }, 500);
  }
});

app.delete("/proveedores/:id", async (c) => {
  try {
    const supabase = c.get("supabase") as SupabaseClient;
    const id = c.req.param("id");
    const { error } = await supabase.from("proveedores").delete().eq("id", id);
    if (error) throw error;
    return c.json({ success: true });
  } catch (error: any) {
    return c.json({ error: error.message }, 500);
  }
});

// --- COMPRAS PROVEEDOR ---

app.get("/compras-proveedor", async (c) => {
  try {
    const supabase = c.get("supabase") as SupabaseClient;
    const orgId = c.get("organizacionId");
    const { data, error } = await supabase
      .from("compras_proveedor")
      .select("*, items:compra_items(*), proveedor:proveedores(*)")
      .eq("organizacion_id", orgId)
      .order("created_at", { ascending: false });
    if (error) throw error;
    return c.json(data);
  } catch (error: any) {
    return c.json({ error: error.message }, 500);
  }
});

app.post("/compras-proveedor", async (c) => {
  try {
    const supabase = c.get("supabase") as SupabaseClient;
    const orgId = c.get("organizacionId");
    const payload = await c.req.json();
    
    const { items, ...compraData } = payload;
    compraData.organizacion_id = orgId;
    
    // 1. Insertar compra principal
    const { data: compra, error: compraError } = await supabase
      .from("compras_proveedor")
      .insert(compraData)
      .select()
      .single();
      
    if (compraError) throw compraError;
    
    // 2. Insertar items si existen
    if (items && items.length > 0) {
      const itemsToInsert = items.map((item: any) => ({
        ...item,
        compra_id: compra.id
      }));
      const { error: itemsError } = await supabase.from("compra_items").insert(itemsToInsert);
      if (itemsError) console.error("Error inserting items:", itemsError); // Non-fatal for now
    }
    
    // 3. Obtener la compra completa con items
    const { data: compraCompleta } = await supabase
      .from("compras_proveedor")
      .select("*, items:compra_items(*), proveedor:proveedores(*)")
      .eq("id", compra.id)
      .single();
      
    return c.json(compraCompleta);
  } catch (error: any) {
    return c.json({ error: error.message }, 500);
  }
});

app.put("/compras-proveedor/:id", async (c) => {
  try {
    const supabase = c.get("supabase") as SupabaseClient;
    const id = c.req.param("id");
    const payload = await c.req.json();
    
    const { items, ...compraData } = payload;
    
    // 1. Update main record
    const { data: compra, error: compraError } = await supabase
      .from("compras_proveedor")
      .update(compraData)
      .eq("id", id)
      .select()
      .single();
      
    if (compraError) throw compraError;
    
    // If state changed to Recibida, we should generate inventory movements!
    if (compraData.estado === 'Recibida') {
       // Fetch items
       const { data: existingItems } = await supabase.from("compra_items").select("*").eq("compra_id", id);
       if (existingItems && existingItems.length > 0) {
         const adminClient = getServiceClient();
         for (const item of existingItems) {
           await adminClient.from('movimientos_inventario').insert({
             producto_id: item.material_id,
             organizacion_id: compra.organizacion_id,
             tipo_movimiento: 'Entrada',
             cantidad: item.cantidad,
             referencia: \`Compra \${compra.folio}\`,
             costo_unitario: item.costo_unitario
           });
           
           // Update stock in products
           const { data: prod } = await adminClient.from('productos').select('stock_actual').eq('id', item.material_id).single();
           if (prod) {
             await adminClient.from('productos').update({ stock_actual: (prod.stock_actual || 0) + item.cantidad }).eq('id', item.material_id);
           }
         }
       }
    }
    
    return c.json(compra);
  } catch (error: any) {
    return c.json({ error: error.message }, 500);
  }
});

// --- INVENTARIO ---

app.get("/inventario/movimientos", async (c) => {
  try {
    const adminClient = getServiceClient();
    const orgId = c.get("organizacionId");
    const { data, error } = await adminClient
      .from('movimientos_inventario')
      .select('*, producto:productos(nombre)')
      .eq('organizacion_id', orgId)
      .order('created_at', { ascending: false });
    if (error) throw error;
    return c.json(data);
  } catch (error: any) {
    console.error("[make-server] Error fetching inventario movimientos:", error);
    return c.json({ error: "Error fetching movimientos", details: error?.message }, 500);
  }
});

app.post("/inventario/movimientos", async (c) => {
  try {
    // Usamos service client para bypass RLS y garantizar escritura
    const adminClient = getServiceClient();
    const payload = await c.req.json();
    payload.organizacion_id = c.get("organizacionId");
    
    // Solo permitimos Entradas, Salidas y Ajustes manuales por este endpoint
    if (!['Entrada', 'Salida', 'Ajuste'].includes(payload.tipo_movimiento)) {
      return c.json({ error: "Tipo de movimiento no permitido por API manual" }, 400);
    }

    // Validaciones básicas
    if (!payload.producto_id) {
      return c.json({ error: "producto_id es requerido" }, 400);
    }
    if (!payload.cantidad || payload.cantidad <= 0) {
      return c.json({ error: "cantidad debe ser mayor a 0" }, 400);
    }
    
    // Insertamos movimiento usando admin client (bypass RLS)
    const { data: mov, error: movError } = await adminClient
      .from('movimientos_inventario')
      .insert(payload)
      .select()
      .single();
    if (movError) {
      console.error("[make-server] movError:", JSON.stringify(movError));
      throw movError;
    }
    
    // Actualizamos el stock del producto
    const diff = payload.tipo_movimiento === 'Salida' ? -payload.cantidad : payload.cantidad;

    // Obtenemos stock actual (usando admin para evitar problemas de RLS en productos)
    const { data: prod, error: prodError } = await adminClient
      .from('productos')
      .select('stock_actual')
      .eq('id', payload.producto_id)
      .single();

    if (prodError) {
      console.error("[make-server] prodError:", JSON.stringify(prodError));
      // No tiramos error fatal, el movimiento ya quedó registrado
    } else if (prod) {
      const stockActual = prod.stock_actual ?? 0;
      const nuevoStock = stockActual + diff;
      const { error: updateError } = await adminClient
        .from('productos')
        .update({ stock_actual: nuevoStock })
        .eq('id', payload.producto_id);
      if (updateError) {
        console.error("[make-server] updateError al actualizar stock:", JSON.stringify(updateError));
      }
    }
    
    return c.json(mov);
  } catch (error: any) {
    console.error("[make-server] Error creating inventario movimiento:", error);
    return c.json({ error: "Error creating movimiento", details: error?.message }, 500);
  }
});

Deno.serve({ port: 8000, hostname: "0.0.0.0" }, (req) => {
  const url = new URL(req.url);
  const prefix = "/make-server-feea4382";

  if (url.pathname.startsWith(`${prefix}/`)) {
    url.pathname = url.pathname.slice(prefix.length);
    return app.fetch(new Request(url.toString(), req));
  }

  return app.fetch(req);
});
