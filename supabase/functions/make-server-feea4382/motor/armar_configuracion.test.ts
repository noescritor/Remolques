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

Deno.test("armarConfiguracionModelo - calcula max_piezas y cantidad_defecto según regla (por_eje o fija)", () => {
  const modelo2Ejes = { tipo: "plataforma", num_ejes: 2 };
  const modelo3Ejes = { tipo: "plataforma", num_ejes: 3 };

  const gruposConReglas = [
    { id: "g1", clave: "rines", nombre: "Rines", regla: { max_total: { por_eje: 4 }, cantidad_defecto: "max" }, orden: 1 },
    { id: "g2", clave: "matracas", nombre: "Matracas", regla: JSON.stringify({ max_total: { fija: 20 }, cantidad_defecto: 12 }), orden: 2 },
    { id: "g3", clave: "retractil", nombre: "Sistema retráctil", regla: { max_total: { por_eje: 1 }, cantidad_defecto: 1 }, orden: 3 },
    { id: "g4", clave: "eje", nombre: "Ejes", regla: null, orden: 4 }
  ];

  const res2 = armarConfiguracionModelo(modelo2Ejes, gruposConReglas, [], []);
  assertEquals(res2.grupos.find(g => g.clave === "rines")?.max_piezas, 8);
  assertEquals(res2.grupos.find(g => g.clave === "rines")?.cantidad_defecto, "max");
  assertEquals(res2.grupos.find(g => g.clave === "matracas")?.max_piezas, 20);
  assertEquals(res2.grupos.find(g => g.clave === "matracas")?.cantidad_defecto, 12);
  assertEquals(res2.grupos.find(g => g.clave === "retractil")?.max_piezas, 2);
  assertEquals(res2.grupos.find(g => g.clave === "retractil")?.cantidad_defecto, 1);
  assertEquals(res2.grupos.find(g => g.clave === "eje")?.max_piezas, undefined);
  assertEquals(res2.grupos.find(g => g.clave === "eje")?.cantidad_defecto, undefined);

  const res3 = armarConfiguracionModelo(modelo3Ejes, gruposConReglas, [], []);
  assertEquals(res3.grupos.find(g => g.clave === "rines")?.max_piezas, 12);
  assertEquals(res3.grupos.find(g => g.clave === "matracas")?.max_piezas, 20);
  assertEquals(res3.grupos.find(g => g.clave === "retractil")?.max_piezas, 3);
  assertEquals(res3.grupos.find(g => g.clave === "retractil")?.cantidad_defecto, 1);
});

