// @ts-nocheck
import { assertEquals } from "https://deno.land/std@0.192.0/testing/asserts.ts";
import { nombreItemCotizacion } from "./nombreItemCotizacion.ts";

Deno.test("nombreItemCotizacion: Góndola vieja sin configuración muestra 45 M3 por defecto", () => {
  const prod = { nombre: "GONDOLA 2 EJES" };
  const item = { descripcion: "Góndola 2 ejes estándar" };
  const res = nombreItemCotizacion(prod, item);

  assertEquals(res, "GONDOLA 2 EJES 45 M3");
});

Deno.test("nombreItemCotizacion: Góndola con m3_30 muestra 30 M3", () => {
  const prod = { nombre: "GONDOLA 2 EJES" };
  const item = {
    descripcion: "Góndola 2 ejes",
    configuracion: {
      grupos: {
        volumen: "m3_30"
      }
    }
  };
  const res = nombreItemCotizacion(prod, item);

  assertEquals(res, "GONDOLA 2 EJES 30 M3");
});

Deno.test("nombreItemCotizacion: Plataforma mantiene su nombre original sin sufijo de volumen", () => {
  const prod = { nombre: "PLATAFORMA 40 FT 2 EJES" };
  const item = { descripcion: "Plataforma 40 pies" };
  const res = nombreItemCotizacion(prod, item);

  assertEquals(res, "PLATAFORMA 40 FT 2 EJES");
});

Deno.test("nombreItemCotizacion: Góndola que ya tiene 45 M3 en su nombre no lo duplica", () => {
  const prod = { nombre: "GONDOLA 3 EJES 45 M3" };
  const item = {};
  const res = nombreItemCotizacion(prod, item);

  assertEquals(res, "GONDOLA 3 EJES 45 M3");
});
