import { assertEquals } from "https://deno.land/std@0.208.0/assert/mod.ts";
import { armarConfiguracionModelo } from "./armar_configuracion.ts";

Deno.test("armarConfiguracionModelo", () => {
  const modelo = { tipo: "PLATAFORMA" };
  const grupos = [
    { id: "g1", clave: "ejes", aplica_a: ["PLATAFORMA"] },
    { id: "g2", clave: "inexistente", aplica_a: ["CAJA"] }
  ];
  const opciones = [
    { id: "o1", grupo_id: "g1", clave: "fleet_master", activo: true, marcas: ["fleet"] },
    { id: "o2", grupo_id: "g2", clave: "no_aplica", activo: true }
  ];
  const componentes = [{ opcion_id: "o1" }];

  const res = armarConfiguracionModelo(modelo, grupos, opciones, componentes);
  
  assertEquals(res.modelo.tipo, "PLATAFORMA");
  assertEquals(res.grupos.length, 1);
  assertEquals(res.grupos[0].id, "g1");
  assertEquals(res.opciones.length, 1);
  assertEquals(res.opciones[0].id, "o1");
  assertEquals(res.opciones[0].tiene_receta, true);
  assertEquals(res.opciones[0].marcas, ["fleet"]);
  assertEquals(res.opciones[0].activo, true);
});
