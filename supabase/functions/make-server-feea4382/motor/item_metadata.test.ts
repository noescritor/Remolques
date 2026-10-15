import { assertEquals } from "https://deno.land/std@0.208.0/assert/mod.ts";
import { construirMetadata, desenvolverMetadata } from "./item_metadata.ts";

Deno.test("item_metadata: envuelve y desenvuelve configuracion intacta", () => {
  const input = {
    producto_id: "p1",
    posicion: 1,
    cantidad: 1,
    unidad: "PZA",
    descripcion: "Test",
    precio_unitario: 100,
    costo_unitario: 50,
    iva_item: 16,
    total_item: 116,
    numero_proyecto: "PRJ-1",
    incluir_setup: true,
    configuracion: {
      modelo_id: "m1",
      grupos: { rines: "acero" },
      texto_especificacion: "TEXTO"
    }
  };

  const dbRow = construirMetadata(input, "c1", "org1");
  
  assertEquals(dbRow.cotizacion_id, "c1");
  assertEquals(dbRow.organizacion_id, "org1");
  assertEquals(dbRow.metadata.numero_proyecto, "PRJ-1");
  assertEquals(dbRow.metadata.incluir_setup, true);
  assertEquals(dbRow.metadata.configuracion.modelo_id, "m1");
  
  const unwrapped = desenvolverMetadata(dbRow);
  
  assertEquals(unwrapped.numero_proyecto, "PRJ-1");
  assertEquals(unwrapped.incluir_setup, true);
  assertEquals(unwrapped.configuracion.modelo_id, "m1");
  assertEquals(unwrapped.configuracion.texto_especificacion, "TEXTO");
});

Deno.test("item_metadata: maneja items sin configuracion", () => {
  const input = {
    producto_id: "p1",
    posicion: 1,
    cantidad: 1,
    unidad: "PZA",
    descripcion: "Test"
  };

  const dbRow = construirMetadata(input, "c1");
  assertEquals(dbRow.metadata.configuracion, undefined);
  
  const unwrapped = desenvolverMetadata(dbRow);
  assertEquals(unwrapped.configuracion, undefined);
});

Deno.test("item_metadata: re-guardar un item crudo (configuracion solo en metadata) NO pierde la configuracion", () => {
  // Así llegan los items en la respuesta de POST/PUT sin desenvolver: todo vive dentro de `metadata`
  const itemCrudo = {
    id: "i1",
    producto_id: "p1",
    posicion: 1,
    cantidad: 1,
    unidad: "PZA",
    descripcion: "Equipo",
    precio_unitario: 100,
    metadata: {
      numero_proyecto: "PRJ-9",
      incluir_setup: false,
      configuracion: { modelo_id: "m1", grupos: { rines: "acero" } }
    }
  };

  const dbRow = construirMetadata(itemCrudo, "c1", "org1");
  assertEquals(dbRow.metadata.configuracion?.modelo_id, "m1");
  assertEquals(dbRow.metadata.numero_proyecto, "PRJ-9");
  assertEquals(dbRow.metadata.incluir_setup, false);

  // Y una segunda vuelta (guardar otra vez lo ya guardado) tampoco la pierde
  const otraVez = construirMetadata(desenvolverMetadata(dbRow), "c1", "org1");
  assertEquals(otraVez.metadata.configuracion?.grupos, { rines: "acero" });
});

Deno.test("item_metadata: la configuracion de la raiz manda sobre la de metadata", () => {
  const dbRow = construirMetadata({
    configuracion: { modelo_id: "nuevo" },
    metadata: { configuracion: { modelo_id: "viejo" } }
  }, "c1");
  assertEquals(dbRow.metadata.configuracion?.modelo_id, "nuevo");
});
