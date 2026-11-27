import { assertEquals, assertStringIncludes } from "https://deno.land/std@0.208.0/assert/mod.ts";
import { app } from "./index.ts";

const ORG_PRINCIPAL = "00000000-0000-0000-0000-000000000001";
const ORG_SECUNDARIA = "00000000-0000-0000-0000-000000000002";

const TOKENS: Record<string, { id: string; email: string; orgId: string; rol: string }> = {
  "tok-usuario-principal": {
    id: "u-usuario-1",
    email: "usuario1@example.com",
    orgId: ORG_PRINCIPAL,
    rol: "usuario",
  },
  "tok-admin-principal": {
    id: "u-admin-1",
    email: "admin1@example.com",
    orgId: ORG_PRINCIPAL,
    rol: "admin",
  },
  "tok-admin-secundaria": {
    id: "u-admin-2",
    email: "admin2@example.com",
    orgId: ORG_SECUNDARIA,
    rol: "admin",
  },
};

interface MockWrite {
  method: string;
  table: string;
  query: string;
  body: any;
}

function iniciarMockSupabase(opciones?: { equiposPorCliente?: Record<string, number> }) {
  const writes: MockWrite[] = [];
  const equiposPorCliente = opciones?.equiposPorCliente ?? {};

  const server = Deno.serve({ port: 0, hostname: "127.0.0.1", onListen: () => {} }, async (req) => {
    const url = new URL(req.url);
    const pathname = url.pathname;
    const auth = req.headers.get("authorization") || "";
    const token = auth.replace(/^Bearer\s+/i, "").trim();

    // 1) GoTrue: GET /auth/v1/user
    if (pathname === "/auth/v1/user") {
      const user = TOKENS[token];
      if (!user) {
        return new Response(JSON.stringify({ error: "invalid_token" }), {
          status: 401,
          headers: { "content-type": "application/json" },
        });
      }
      return new Response(JSON.stringify({ id: user.id, email: user.email }), {
        status: 200,
        headers: { "content-type": "application/json" },
      });
    }

    // 2) PostgREST: /rest/v1/<table>
    if (pathname.startsWith("/rest/v1/")) {
      const table = pathname.slice("/rest/v1/".length);
      const accept = req.headers.get("accept") || "";
      const isSingle = accept.includes("application/vnd.pgrst.object+json");
      let body: any = null;
      if (!["GET", "HEAD", "DELETE"].includes(req.method)) {
        const text = await req.text();
        try {
          body = text ? JSON.parse(text) : null;
        } catch {
          body = text;
        }
      }

      if (["POST", "PATCH", "PUT", "DELETE"].includes(req.method)) {
        writes.push({ method: req.method, table, query: url.search, body });
      }

      // perfiles_organizacion
      if (table === "perfiles_organizacion" && req.method === "GET") {
        const uidParam = url.searchParams.get("usuario_id") || "";
        const uid = uidParam.replace(/^eq\./, "");
        const orgParam = url.searchParams.get("organizacion_id") || "";
        const orgFilter = orgParam.replace(/^eq\./, "");

        const matches = Object.values(TOKENS)
          .filter((u) => (!uid || u.id === uid) && (!orgFilter || u.orgId === orgFilter))
          .map((u) => ({ organizacion_id: u.orgId, usuario_id: u.id, rol: u.rol }));

        if (isSingle) {
          if (matches.length === 0) {
            return new Response(JSON.stringify({ code: "PGRST116", message: "0 rows" }), {
              status: 406,
              headers: { "content-type": "application/json" },
            });
          }
          return new Response(JSON.stringify(matches[0]), {
            status: 200,
            headers: { "content-type": "application/json" },
          });
        }
        return new Response(JSON.stringify(matches), {
          status: 200,
          headers: { "content-type": "application/json" },
        });
      }

      // ordenes_trabajo HEAD/GET count for DELETE /clientes/:id
      if (table === "ordenes_trabajo" && (req.method === "HEAD" || req.method === "GET")) {
        const clienteParam = (url.searchParams.get("cliente_id") || "").replace(/^eq\./, "");
        const total = equiposPorCliente[clienteParam] ?? 0;
        const headers = new Headers({
          "content-type": "application/json",
          "content-range": total > 0 ? `0-${total - 1}/${total}` : `*/0`,
        });
        if (req.method === "HEAD") {
          return new Response(null, { status: 200, headers });
        }
        return new Response(JSON.stringify([]), { status: 200, headers });
      }

      // invitaciones_equipo
      if (table === "invitaciones_equipo") {
        if (req.method === "POST") {
          const row = { id: "inv-nueva-1", ...(body || {}) };
          return new Response(JSON.stringify(isSingle ? row : [row]), {
            status: 201,
            headers: { "content-type": "application/json" },
          });
        }
        if (req.method === "DELETE") {
          return new Response(JSON.stringify([]), {
            status: 200,
            headers: { "content-type": "application/json" },
          });
        }
      }

      // organizaciones
      if (table === "organizaciones") {
        if (req.method === "GET") {
          return new Response(
            JSON.stringify([
              { id: ORG_PRINCIPAL, nombre: "Org Principal", modulos: {} },
              { id: ORG_SECUNDARIA, nombre: "Org Secundaria", modulos: {} },
            ]),
            { status: 200, headers: { "content-type": "application/json" } },
          );
        }
        if (req.method === "POST") {
          const row = { id: "org-creada-1", nombre: body?.nombre || "Nueva Org" };
          return new Response(JSON.stringify(isSingle ? row : [row]), {
            status: 201,
            headers: { "content-type": "application/json" },
          });
        }
        if (req.method === "PATCH") {
          const id = (url.searchParams.get("id") || "").replace(/^eq\./, "");
          const row = { id, ...(body || {}) };
          return new Response(JSON.stringify(isSingle ? row : [row]), {
            status: 200,
            headers: { "content-type": "application/json" },
          });
        }
      }

      // clientes
      if (table === "clientes" && req.method === "DELETE") {
        return new Response(JSON.stringify([]), {
          status: 200,
          headers: { "content-type": "application/json" },
        });
      }

      // Default response for any other table
      return new Response(JSON.stringify(isSingle ? {} : []), {
        status: 200,
        headers: { "content-type": "application/json" },
      });
    }

    return new Response("Not Found", { status: 404 });
  });

  const addr = server.addr as Deno.NetAddr;
  const baseUrl = `http://127.0.0.1:${addr.port}`;
  return { server, baseUrl, writes };
}

async function conMockSupabase(
  opciones: { equiposPorCliente?: Record<string, number> } | undefined,
  fn: (ctx: { writes: MockWrite[] }) => Promise<void>,
) {
  const prevUrl = Deno.env.get("SUPABASE_URL");
  const prevAnon = Deno.env.get("SUPABASE_ANON_KEY");
  const prevService = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

  const { server, baseUrl, writes } = iniciarMockSupabase(opciones);
  Deno.env.set("SUPABASE_URL", baseUrl);
  Deno.env.set("SUPABASE_ANON_KEY", "test-anon-key");
  Deno.env.set("SUPABASE_SERVICE_ROLE_KEY", "test-service-key");

  try {
    await fn({ writes });
  } finally {
    await server.shutdown();
    if (prevUrl === undefined) Deno.env.delete("SUPABASE_URL");
    else Deno.env.set("SUPABASE_URL", prevUrl);
    if (prevAnon === undefined) Deno.env.delete("SUPABASE_ANON_KEY");
    else Deno.env.set("SUPABASE_ANON_KEY", prevAnon);
    if (prevService === undefined) Deno.env.delete("SUPABASE_SERVICE_ROLE_KEY");
    else Deno.env.set("SUPABASE_SERVICE_ROLE_KEY", prevService);
  }
}

Deno.test("Ruta POST /invitaciones: usuario recibe 403 y no escribe nada", async () => {
  await conMockSupabase(undefined, async ({ writes }) => {
    const res = await app.request("/invitaciones", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: "Bearer tok-usuario-principal",
      },
      body: JSON.stringify({ email: "intruso@example.com", rol: "usuario" }),
    });
    assertEquals(res.status, 403);
    assertEquals(writes.length, 0);
  });
});

Deno.test("Ruta POST /invitaciones: admin puede invitar usuario pero NO propietario", async () => {
  await conMockSupabase(undefined, async ({ writes }) => {
    const resProp = await app.request("/invitaciones", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: "Bearer tok-admin-principal",
      },
      body: JSON.stringify({ email: "prop@example.com", rol: "propietario" }),
    });
    assertEquals(resProp.status, 403);
    assertEquals(writes.length, 0);

    const resOk = await app.request("/invitaciones", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: "Bearer tok-admin-principal",
      },
      body: JSON.stringify({ email: "nuevo@example.com", rol: "usuario" }),
    });
    assertEquals(resOk.status, 200);
    assertEquals(writes.length, 1);
    assertEquals(writes[0].table, "invitaciones_equipo");
  });
});

Deno.test("Ruta DELETE /invitaciones/:id: usuario recibe 403 y no borra nada", async () => {
  await conMockSupabase(undefined, async ({ writes }) => {
    const res = await app.request("/invitaciones/inv-99", {
      method: "DELETE",
      headers: { Authorization: "Bearer tok-usuario-principal" },
    });
    assertEquals(res.status, 403);
    assertEquals(writes.length, 0);
  });
});

Deno.test("Ruta POST /organizaciones/crear-con-invitacion: usuario en org principal recibe 403 y no crea nada", async () => {
  await conMockSupabase(undefined, async ({ writes }) => {
    const res = await app.request("/organizaciones/crear-con-invitacion", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: "Bearer tok-usuario-principal",
      },
      body: JSON.stringify({ nombre: "Empresa X", email: "dueno@x.com" }),
    });
    assertEquals(res.status, 403);
    assertEquals(writes.length, 0);
  });
});

Deno.test("Ruta POST /organizaciones/crear-con-invitacion: admin de org secundaria recibe 403 y no crea nada", async () => {
  await conMockSupabase(undefined, async ({ writes }) => {
    const res = await app.request("/organizaciones/crear-con-invitacion", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: "Bearer tok-admin-secundaria",
      },
      body: JSON.stringify({ nombre: "Empresa X", email: "dueno@x.com" }),
    });
    assertEquals(res.status, 403);
    assertEquals(writes.length, 0);
  });
});

Deno.test("Ruta GET /organizaciones: usuario en org principal recibe 403", async () => {
  await conMockSupabase(undefined, async ({ writes }) => {
    const res = await app.request("/organizaciones", {
      method: "GET",
      headers: { Authorization: "Bearer tok-usuario-principal" },
    });
    assertEquals(res.status, 403);
    assertEquals(writes.length, 0);

    const resAdmin = await app.request("/organizaciones", {
      method: "GET",
      headers: { Authorization: "Bearer tok-admin-principal" },
    });
    assertEquals(resAdmin.status, 200);
  });
});

Deno.test("Ruta PUT /organizaciones/:id/modulos: usuario en org principal recibe 403 y no modifica nada", async () => {
  await conMockSupabase(undefined, async ({ writes }) => {
    const res = await app.request(`/organizaciones/${ORG_SECUNDARIA}/modulos`, {
      method: "PUT",
      headers: {
        "Content-Type": "application/json",
        Authorization: "Bearer tok-usuario-principal",
      },
      body: JSON.stringify({ modulos: { almacen: true } }),
    });
    assertEquals(res.status, 403);
    assertEquals(writes.length, 0);

    const resAdmin = await app.request(`/organizaciones/${ORG_SECUNDARIA}/modulos`, {
      method: "PUT",
      headers: {
        "Content-Type": "application/json",
        Authorization: "Bearer tok-admin-principal",
      },
      body: JSON.stringify({ modulos: { almacen: true } }),
    });
    assertEquals(resAdmin.status, 200);
    assertEquals(writes.length, 1);
    assertEquals(writes[0].table, "organizaciones");
  });
});

Deno.test("Ruta DELETE /clientes/:id: rechaza con 409 si el cliente tiene equipos y no borra", async () => {
  await conMockSupabase({ equiposPorCliente: { "cli-con-equipos": 3, "cli-sin-equipos": 0 } }, async ({ writes }) => {
    const res409 = await app.request("/clientes/cli-con-equipos", {
      method: "DELETE",
      headers: { Authorization: "Bearer tok-admin-principal" },
    });
    assertEquals(res409.status, 409);
    const body409 = await res409.json();
    assertStringIncludes(body409.error, "3 equipos");
    assertEquals(writes.length, 0);

    const resOk = await app.request("/clientes/cli-sin-equipos", {
      method: "DELETE",
      headers: { Authorization: "Bearer tok-admin-principal" },
    });
    assertEquals(resOk.status, 200);
    assertEquals(writes.length, 1);
    assertEquals(writes[0].table, "clientes");
    assertEquals(writes[0].method, "DELETE");
  });
});
