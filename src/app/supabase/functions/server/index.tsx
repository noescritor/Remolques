import { Hono } from "npm:hono";
import { createClient, SupabaseClient } from "npm:@supabase/supabase-js";
import { cors } from "npm:hono/cors";
import { logger } from "npm:hono/logger";

import type { 
  Cliente, 
  Producto, 
  ProductoTipo, 
  Cotizacion, 
  ItemCotizacion, 
  Pago, 
  Ajustes 
} from "../../../../types/index.ts";

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

const authMiddleware = async (c: any, next: any) => {
  if (c.req.path.endsWith("/health")) {
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
  } catch (error) {
    console.log('Error fetching clientes:', error);
    return c.json({ error: 'Error fetching clientes' }, 500);
  }
});

app.post("/clientes", async (c) => {
  try {
    const supabase = c.get("supabase") as SupabaseClient;
    const cliente: Omit<Cliente, 'id'> = await c.req.json();
    
    const { data, error } = await supabase.from('clientes').insert(cliente).select().single();
    if (error) throw error;
    return c.json(data);
  } catch (error) {
    console.log('Error creating cliente:', error);
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
    console.log('Error updating cliente:', error);
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
    console.log('Error deleting cliente:', error);
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
    console.log('Error fetching productos:', error);
    return c.json({ error: 'Error fetching productos' }, 500);
  }
});

app.post("/productos", async (c) => {
  try {
    const supabase = c.get("supabase") as SupabaseClient;
    const producto: Omit<Producto, 'id'> = await c.req.json();
    
    const { data, error } = await supabase.from('productos').insert(producto).select().single();
    if (error) throw error;
    return c.json(data);
  } catch (error) {
    console.log('Error creating producto:', error);
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
    console.log('Error updating producto:', error);
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
    console.log('Error deleting producto:', error);
    return c.json({ error: 'Error deleting producto' }, 500);
  }
});

app.get("/cotizaciones", async (c) => {
  try {
    const supabase = c.get("supabase") as SupabaseClient;
    const { data, error } = await supabase.from('cotizaciones').select('*, items:items_cotizacion(*)');
    if (error) throw error;
    return c.json(data);
  } catch (error) {
    console.log('Error fetching cotizaciones:', error);
    return c.json({ error: 'Error fetching cotizaciones' }, 500);
  }
});

app.post("/cotizaciones", async (c) => {
  try {
    const supabase = c.get("supabase") as SupabaseClient;
    const payload = await c.req.json();
    const items = payload.items || [];
    const cotizacionData = { ...payload };
    delete cotizacionData.items;

    // Get latest folio and ajustes
    const { data: latestCots } = await supabase
      .from('cotizaciones')
      .select('folio')
      .order('created_at', { ascending: false })
      .limit(1);
      
    const ultimaFolio = latestCots && latestCots.length > 0 
      ? parseInt(latestCots[0].folio.split('-').pop() || '0') 
      : 0;

    const { data: ajustes } = await supabase.from('ajustes').select('data').single();
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

    const { data: nuevaCotizacion, error: insertError } = await supabase
      .from('cotizaciones')
      .insert(cotizacionData)
      .select()
      .single();
      
    if (insertError) throw insertError;

    if (items.length > 0) {
      const itemsToInsert = items.map((item: any) => {
        const { id, ...itemData } = item; // remove frontend temporary id
        return { ...itemData, cotizacion_id: nuevaCotizacion.id };
      });
      const { error: itemsError } = await supabase.from('items_cotizacion').insert(itemsToInsert);
      if (itemsError) throw itemsError;
    }

    const { data: finalCotizacion } = await supabase
      .from('cotizaciones')
      .select('*, items:items_cotizacion(*)')
      .eq('id', nuevaCotizacion.id)
      .single();

    return c.json(finalCotizacion);
  } catch (error) {
    console.log('Error creating cotizacion:', error);
    return c.json({ error: 'Error creating cotizacion' }, 500);
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
    
    const { error: updateError } = await supabase
      .from('cotizaciones')
      .update(cotizacionData)
      .eq('id', id);
      
    if (updateError) throw updateError;
    
    if (items !== undefined) {
      // Reemplazo completo de items: borrar existentes y crear nuevos
      await supabase.from('items_cotizacion').delete().eq('cotizacion_id', id);
      if (items.length > 0) {
        const itemsToInsert = items.map((item: any) => {
          const { id: itemId, ...itemData } = item;
          return { ...itemData, cotizacion_id: id };
        });
        await supabase.from('items_cotizacion').insert(itemsToInsert);
      }
    }
    
    const { data: finalCotizacion } = await supabase
      .from('cotizaciones')
      .select('*, items:items_cotizacion(*)')
      .eq('id', id)
      .single();
      
    return c.json(finalCotizacion);
  } catch (error) {
    console.log('Error updating cotizacion:', error);
    return c.json({ error: 'Error updating cotizacion' }, 500);
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
    console.log('Error deleting cotizacion:', error);
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
    
    // Get latest folio
    const { data: latestCots } = await supabase
      .from('cotizaciones')
      .select('folio')
      .order('created_at', { ascending: false })
      .limit(1);
      
    const ultimaFolio = latestCots && latestCots.length > 0 
      ? parseInt(latestCots[0].folio.split('-').pop() || '0') 
      : 0;

    // Get ajustes
    const { data: ajustesWrapper } = await supabase.from('ajustes').select('data').single();
    const prefijo = ajustesWrapper?.data?.prefijo_folio || '';
    
    const año = new Date().getFullYear();
    const numeroFormateado = (ultimaFolio + 1).toString().padStart(5, '0');
    
    const cotizacionDuplicadaPayload = {
      ...cotizacionExistente,
      folio: prefijo ? `${prefijo}-${año}-${numeroFormateado}` : `${año}-${numeroFormateado}`,
      estado: 'Borrador',
      fecha: new Date().toISOString().split('T')[0]
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
        return { ...itemData, cotizacion_id: nuevaCotizacion.id };
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
    console.log('Error duplicating cotizacion:', error);
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
    console.log('Error fetching pagos:', error);
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
    console.log('Error fetching pagos for cotizacion:', error);
    return c.json({ error: 'Error fetching pagos for cotizacion' }, 500);
  }
});

app.post("/pagos", async (c) => {
  try {
    const supabase = c.get("supabase") as SupabaseClient;
    const pago: Omit<Pago, 'id'> = await c.req.json();
    
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
    console.log('Error creating pago:', error);
    return c.json({ error: 'Error creating pago' }, 500);
  }
});

app.get("/ajustes", async (c) => {
  try {
    const supabase = c.get("supabase") as SupabaseClient;
    const { data, error } = await supabase.from('ajustes').select('data').eq('id', '00000000-0000-0000-0000-000000000001').single();
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
    console.log('Error fetching ajustes:', error);
    return c.json({ error: 'Error fetching ajustes' }, 500);
  }
});

app.put("/ajustes", async (c) => {
  try {
    const supabase = c.get("supabase") as SupabaseClient;
    const updates: Partial<Ajustes> = await c.req.json();
    
    const { data: currentAjustes } = await supabase.from('ajustes').select('data').eq('id', '00000000-0000-0000-0000-000000000001').single();
    const ajustesActualizados = { ...(currentAjustes?.data || {}), ...updates };
    
    const { error } = await supabase.from('ajustes').upsert({ id: '00000000-0000-0000-0000-000000000001', data: ajustesActualizados });
    if (error) throw error;
    
    return c.json(ajustesActualizados);
  } catch (error) {
    console.log('Error updating ajustes:', error);
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
      console.log('Error enviando email: RESEND_API_KEY no configurada correctamente');
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
    const { data: ajustesData } = await supabase.from('ajustes').select('data').eq('id', '00000000-0000-0000-0000-000000000001').single();
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
      console.log('Error from Resend API:', result);
      
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
    console.log('Error sending email:', error);
    return c.json({ 
      error: 'Error al enviar el email: ' + error.message,
      hint: 'Verifica tu conexión a internet y la configuración de Resend'
    }, 500);
  }
});

Deno.serve(app.fetch);
