// @ts-nocheck
import { assertEquals, assert } from "https://deno.land/std@0.192.0/testing/asserts.ts";
import { tituloEquipo } from "./tituloEquipo.ts";

Deno.test("tituloEquipo: Plataforma 40 ft 2 ejes genera formato correcto sin caracteres de plantilla", () => {
  const prod = { nombre: "PLATAFORMA 40 FT" };
  const mod = { tipo: "plataforma", largo_ft: 40, num_ejes: 2 };
  const res = tituloEquipo(prod, mod);

  assertEquals(res, "PLATAFORMA 40 FT - plataforma 40FT 2 EJES");
  assert(!res.includes("{"), "No debe contener {");
  assert(!res.includes("$"), "No debe contener $");
});

Deno.test("tituloEquipo: Dolly 2 ejes genera formato correcto sin largo_ft", () => {
  const prod = { nombre: "DOLLY H-200" };
  const mod = { tipo: "dolly", largo_ft: null, num_ejes: 2 };
  const res = tituloEquipo(prod, mod);

  assertEquals(res, "DOLLY H-200 - dolly 2 EJES");
  assert(!res.includes("{"));
  assert(!res.includes("$"));
});

Deno.test("tituloEquipo: Góndola 2 ejes sin configuración de volumen asume 45 M3 por defecto", () => {
  const prod = { nombre: "GONDOLA 2 EJES" };
  const mod = { tipo: "gondola", largo_ft: null, num_ejes: 2 };
  const res = tituloEquipo(prod, mod, { grupos: {} });

  assertEquals(res, "GONDOLA 2 EJES 45 M3");
  assert(!res.includes("{"));
  assert(!res.includes("$"));
});

Deno.test("tituloEquipo: Góndola 3 ejes con m3_30 genera 30 M3", () => {
  const prod = { nombre: "GONDOLA 3 EJES" };
  const mod = { tipo: "gondola", largo_ft: null, num_ejes: 3 };
  const res = tituloEquipo(prod, mod, { grupos: { volumen: "m3_30" } });

  assertEquals(res, "GONDOLA 3 EJES 30 M3");
  assert(!res.includes("{"));
  assert(!res.includes("$"));
});
