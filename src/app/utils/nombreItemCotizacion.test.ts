// @ts-nocheck
import { assertEquals } from "https://deno.land/std@0.192.0/testing/asserts.ts";
import { nombreItemCotizacion } from "./nombreItemCotizacion.ts";

Deno.test("nombreItemCotizacion (a): producto=null, item.descripcion='GONDOLA 2 EJES', item.configuracion con m3_30 -> GONDOLA 2 EJES 30 M3", () => {
  const item = {
    descripcion: "GONDOLA 2 EJES",
    configuracion: {
      grupos: {
        volumen: "m3_30",
      },
    },
  };
  const res = nombreItemCotizacion(null, item);
  assertEquals(res, "GONDOLA 2 EJES 30 M3");
});

Deno.test("nombreItemCotizacion (b): item.descripcion='GONDOLA 2 EJES 45 M3', sin config -> GONDOLA 2 EJES 45 M3 (no duplica)", () => {
  const item = {
    descripcion: "GONDOLA 2 EJES 45 M3",
  };
  const res = nombreItemCotizacion(null, item);
  assertEquals(res, "GONDOLA 2 EJES 45 M3");
});

Deno.test("nombreItemCotizacion (c): item.descripcion='GONDOLA 2 EJES', sin config (histórico) -> GONDOLA 2 EJES 45 M3", () => {
  const item = {
    descripcion: "GONDOLA 2 EJES",
  };
  const res = nombreItemCotizacion(null, item);
  assertEquals(res, "GONDOLA 2 EJES 45 M3");
});

Deno.test("nombreItemCotizacion (d): plataforma -> 'PLATAFORMA 40 FT 2 EJES' sin cambios", () => {
  const prod = { nombre: "PLATAFORMA 40 FT 2 EJES" };
  const item = { descripcion: "Plataforma 40 pies" };
  const res = nombreItemCotizacion(prod, item);
  assertEquals(res, "PLATAFORMA 40 FT 2 EJES");

  const resSinProd = nombreItemCotizacion(null, { descripcion: "PLATAFORMA 40 FT 2 EJES" });
  assertEquals(resSinProd, "PLATAFORMA 40 FT 2 EJES");
});

Deno.test("nombreItemCotizacion: Góndola con producto poblado y sin volumen en catálogo agrega 45 M3 por defecto", () => {
  const prod = { nombre: "GONDOLA 2 EJES" };
  const item = { descripcion: "Góndola 2 ejes estándar" };
  const res = nombreItemCotizacion(prod, item);
  assertEquals(res, "GONDOLA 2 EJES 45 M3");
});

Deno.test("nombreItemCotizacion: Góndola que ya tiene 45 M3 en producto no lo duplica", () => {
  const prod = { nombre: "GONDOLA 3 EJES 45 M3" };
  const item = {};
  const res = nombreItemCotizacion(prod, item);
  assertEquals(res, "GONDOLA 3 EJES 45 M3");
});
