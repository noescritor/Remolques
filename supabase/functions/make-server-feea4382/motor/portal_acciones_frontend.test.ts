import { assertEquals } from "https://deno.land/std@0.192.0/testing/asserts.ts";
import { enviarAccionPortal } from "../../../../src/app/components/Portal/portalAcciones.ts";

Deno.test("portalAcciones (regresión hipótesis 1): HTTP 409 ya aprobada devuelve ok=false y mensaje específico", async () => {
  const mockFetch = (async () =>
    new Response(JSON.stringify({ error: "Esta cotización ya fue aprobada.", codigo: "YA_APROBADA" }), {
      status: 409,
      headers: { "Content-Type": "application/json" },
    })) as typeof fetch;

  const res = await enviarAccionPortal("http://localhost:8000", "tok-1", "aprobar", {
    firma_nombre: "Juan",
    firma_imagen: "data:image/png;base64,AAA",
  }, mockFetch);

  assertEquals(res.ok, false);
  assertEquals(res.status, 409);
  assertEquals(res.codigo, "YA_APROBADA");
  assertEquals(res.error, "Esta cotización ya fue aprobada.");
  assertEquals(res.reintentable, false);
});

Deno.test("portalAcciones: HTTP 409 otro estado devuelve mensaje de asesor", async () => {
  const mockFetch = (async () =>
    new Response(JSON.stringify({ error: "No disponible", codigo: "ESTADO_NO_DISPONIBLE", estado_actual: "Borrador" }), {
      status: 409,
      headers: { "Content-Type": "application/json" },
    })) as typeof fetch;

  const res = await enviarAccionPortal("http://localhost:8000", "tok-1", "aprobar", {}, mockFetch);

  assertEquals(res.ok, false);
  assertEquals(res.error, "Esta cotización ya no está disponible para aprobar, contacta a tu asesor.");
  assertEquals(res.reintentable, false);
});

Deno.test("portalAcciones: HTTP 410 token expirado devuelve 'El enlace expiró.'", async () => {
  const mockFetch = (async () =>
    new Response(JSON.stringify({ error: "Link expirado", codigo: "TOKEN_EXPIRADO" }), {
      status: 410,
      headers: { "Content-Type": "application/json" },
    })) as typeof fetch;

  const res = await enviarAccionPortal("http://localhost:8000", "tok-1", "aprobar", {}, mockFetch);

  assertEquals(res.ok, false);
  assertEquals(res.status, 410);
  assertEquals(res.error, "El enlace expiró.");
});

Deno.test("portalAcciones: HTTP 500 devuelve error genérico reintentable", async () => {
  const mockFetch = (async () =>
    new Response(JSON.stringify({ error: "Error interno" }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    })) as typeof fetch;

  const res = await enviarAccionPortal("http://localhost:8000", "tok-1", "aprobar", {}, mockFetch);

  assertEquals(res.ok, false);
  assertEquals(res.status, 500);
  assertEquals(res.reintentable, true);
});

Deno.test("portalAcciones: HTTP 200 devuelve ok=true", async () => {
  const mockFetch = (async () =>
    new Response(JSON.stringify({ success: true, estado: "Aprobada" }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    })) as typeof fetch;

  const res = await enviarAccionPortal("http://localhost:8000", "tok-1", "aprobar", {}, mockFetch);

  assertEquals(res.ok, true);
  assertEquals(res.status, 200);
  assertEquals(res.data?.estado, "Aprobada");
});
