// @ts-nocheck
import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { extraerListaOperarios } from "./operarios.ts";

Deno.test("extraerListaOperarios: respuesta real del servidor { operarios: [...] }", () => {
  const ops = [{ id: "op-1", nombre: "Juan Perez" }, { id: "op-2", nombre: "Ana Ruiz" }];
  assertEquals(extraerListaOperarios({ operarios: ops }), ops);
});

Deno.test("extraerListaOperarios: acepta un arreglo directo", () => {
  const ops = [{ id: "op-1", nombre: "Juan Perez" }];
  assertEquals(extraerListaOperarios(ops), ops);
});

Deno.test("extraerListaOperarios: lista vacía del servidor", () => {
  assertEquals(extraerListaOperarios({ operarios: [] }), []);
});

Deno.test("extraerListaOperarios: formas inválidas devuelven []", () => {
  assertEquals(extraerListaOperarios(null), []);
  assertEquals(extraerListaOperarios(undefined), []);
  assertEquals(extraerListaOperarios({}), []);
  assertEquals(extraerListaOperarios({ operarios: "x" }), []);
  assertEquals(extraerListaOperarios({ error: "falló" }), []);
  assertEquals(extraerListaOperarios("texto"), []);
});
