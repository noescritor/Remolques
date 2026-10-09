import { assertEquals } from "https://deno.land/std@0.208.0/assert/mod.ts";
import { armarConfiguracionModelo } from "./armar_configuracion.ts";
import * as fixtures from "./fixtures/datos_modelo.json" with { type: "json" };

Deno.test("armarConfiguracionModelo", () => {
  const { modelo, grupos, opciones, opcion_componentes } = fixtures.default as any;

  // Add fake orden to test sorting
  const rinesG = grupos.find((g: any) => g.clave === 'rines');
  const suspG = grupos.find((g: any) => g.clave === 'suspension');
  if (rinesG) rinesG.orden = 20;
  if (suspG) suspG.orden = 10;

  const res = armarConfiguracionModelo(modelo, grupos, opciones, opcion_componentes);
  
  assertEquals(res.modelo.tipo, "plataforma");
  
  // Test ordering
  const rIdx = res.grupos.findIndex((g: any) => g.clave === 'rines');
  const sIdx = res.grupos.findIndex((g: any) => g.clave === 'suspension');
  if (rIdx >= 0 && sIdx >= 0) {
    assertEquals(sIdx < rIdx, true); // 10 comes before 20
  }

  // Find rines/acero and check marcas
  const rinesA = res.opciones.find((o: any) => o.clave === "acero" && o.grupo_id === rinesG?.id);
  assertEquals(!!rinesA, true);
  assertEquals(rinesA!.marcas.length, 3);
  assertEquals(rinesA!.marcas.includes("Fleet Master"), true);
  assertEquals(rinesA!.tiene_receta, true);

  // Find suspension/alta_hendrickson
  const suspH = res.opciones.find((o: any) => o.clave === "alta_hendrickson" && o.grupo_id === suspG?.id);
  assertEquals(!!suspH, true);
  assertEquals(suspH!.tiene_receta, true);

  // Find piso/laminado (which has no recipe in standard fixtures)
  const pisoG = res.grupos.find((g: any) => g.clave === 'piso');
  const pisoL = res.opciones.find((o: any) => o.clave === "laminado" && o.grupo_id === pisoG?.id);
  assertEquals(!!pisoL, true);
  assertEquals(pisoL!.tiene_receta, false);
});
