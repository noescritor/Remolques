import { assertEquals, assertRejects } from "https://deno.land/std@0.192.0/testing/asserts.ts";
import {
  agruparResumenEntregas,
  esPartidaCompleta,
  resumenEntregasOrdenesMotor,
} from "./resumen_entregas.ts";

Deno.test("resumen_entregas: agrupa por orden y por fase, excluye anuladas, maneja sin_fase y nulos", () => {
  const res = agruparResumenEntregas([
    {
      orden_trabajo_id: "ot-1",
      fase_clave: "corte",
      cantidad_requerida: 4,
      cantidad_entregada: 4,
    },
    {
      orden_trabajo_id: "ot-1",
      fase_clave: "corte",
      cantidad_requerida: 2,
      cantidad_entregada: 1,
    },
    {
      orden_trabajo_id: "ot-1",
      fase_clave: "armado",
      cantidad_requerida: 5,
      cantidad_entregada: 6, // sobre-entrega >= requerido -> completa
    },
    {
      orden_trabajo_id: "ot-1",
      fase_clave: "armado",
      cantidad_requerida: 3,
      cantidad_entregada: 3,
      anulada: true, // excluida
    },
    {
      // Partida manual sin fase (G3 / G11)
      orden_trabajo_id: "ot-1",
      fase_clave: null,
      cantidad_requerida: 2,
      cantidad_entregada: 2,
    },
    {
      // Cantidades nulas (G9 / G10): 0 requerido y 0 entregado -> NO completa
      orden_trabajo_id: "ot-2",
      fase_clave: "   ",
      cantidad_requerida: null,
      cantidad_entregada: null,
    },
    {
      // estado_entrega explícito de la vista SQL
      orden_trabajo_id: "ot-2",
      fase_clave: "corte",
      cantidad_requerida: 0,
      cantidad_entregada: 0,
      estado_entrega: "pendiente",
    },
  ]);

  assertEquals(res.length, 2);

  const ot1 = res.find((r) => r.orden_trabajo_id === "ot-1")!;
  assertEquals(ot1.total_partidas, 4);
  assertEquals(ot1.partidas_completas, 3);
  assertEquals(ot1.porcentaje, 75);
  assertEquals(ot1.por_fase.corte, {
    total_partidas: 2,
    partidas_completas: 1,
    porcentaje: 50,
  });
  assertEquals(ot1.por_fase.armado, {
    total_partidas: 1,
    partidas_completas: 1,
    porcentaje: 100,
  });
  assertEquals(ot1.por_fase.sin_fase, {
    total_partidas: 1,
    partidas_completas: 1,
    porcentaje: 100,
  });

  const ot2 = res.find((r) => r.orden_trabajo_id === "ot-2")!;
  assertEquals(ot2.total_partidas, 2);
  assertEquals(ot2.partidas_completas, 0);
  assertEquals(ot2.porcentaje, 0);
  assertEquals(ot2.por_fase.sin_fase, {
    total_partidas: 1,
    partidas_completas: 0,
    porcentaje: 0,
  });
  assertEquals(esPartidaCompleta({ orden_trabajo_id: "x", cantidad_requerida: null, cantidad_entregada: null }), false);
  // G9: requerido ausente (0) con entregado > 0 cuenta como completa (si cayera a 1, 0.5 < 1 fallaría)
  assertEquals(esPartidaCompleta({ orden_trabajo_id: "x", cantidad_requerida: null, cantidad_entregada: 0.5 }), true);
  assertEquals(esPartidaCompleta({ orden_trabajo_id: "x", estado_entrega: "completo", cantidad_requerida: 1, cantidad_entregada: 0 }), true);

  // G4: Math.round (2/3 -> 67, no 66)
  const redondeo = agruparResumenEntregas([
    { orden_trabajo_id: "ot-r", fase_clave: "corte", cantidad_requerida: 1, cantidad_entregada: 1 },
    { orden_trabajo_id: "ot-r", fase_clave: "corte", cantidad_requerida: 1, cantidad_entregada: 1 },
    { orden_trabajo_id: "ot-r", fase_clave: "corte", cantidad_requerida: 1, cantidad_entregada: 0 },
  ]);
  assertEquals(redondeo[0].porcentaje, 67);
  assertEquals(redondeo[0].por_fase.corte.porcentaje, 67);
});

Deno.test("resumen_entregas: lista vacía retorna arreglo vacío", () => {
  assertEquals(agruparResumenEntregas([]), []);
});

Deno.test("resumen_entregas (D4 y D5): pagina con range en bloques de 1000, ordena por linea_id y propaga error", async () => {
  const rangos: Array<[number, number]> = [];
  const ordenes: Array<{ col: string; asc: boolean }> = [];
  const filtros: Array<{ col: string; val: unknown }> = [];

  const totalFilas = 1250;
  const mockSupabasePaginado = {
    from(tabla: string) {
      assertEquals(tabla, "v_orden_despiece_avance");
      const chain: any = {
        select() {
          return chain;
        },
        eq(col: string, val: unknown) {
          filtros.push({ col, val });
          return chain;
        },
        order(col: string, opts: { ascending: boolean }) {
          ordenes.push({ col, asc: opts.ascending });
          return chain;
        },
        range(desde: number, hasta: number) {
          rangos.push([desde, hasta]);
          const fin = Math.min(hasta + 1, totalFilas);
          const rows = [];
          for (let i = desde; i < fin; i++) {
            rows.push({
              linea_id: `l-${String(i).padStart(4, "0")}`,
              orden_trabajo_id: i < 1000 ? "ot-a" : "ot-b",
              fase_clave: "corte",
              cantidad_requerida: 2,
              cantidad_entregada: i % 2 === 0 ? 2 : 0,
              estado_entrega: i % 2 === 0 ? "completo" : "pendiente",
            });
          }
          return Promise.resolve({ data: rows, error: null });
        },
      };
      return chain;
    },
  };

  const res = await resumenEntregasOrdenesMotor(mockSupabasePaginado, "org-A");
  assertEquals(rangos, [
    [0, 999],
    [1000, 1999],
  ]);
  assertEquals(ordenes, [
    { col: "linea_id", asc: true },
    { col: "linea_id", asc: true },
  ]);
  assertEquals(filtros, [
    { col: "organizacion_id", val: "org-A" },
    { col: "organizacion_id", val: "org-A" },
  ]);
  assertEquals(res.find((r) => r.orden_trabajo_id === "ot-a")?.total_partidas, 1000);
  assertEquals(res.find((r) => r.orden_trabajo_id === "ot-b")?.total_partidas, 250);

  // G12: error de consulta debe propagarse
  const mockSupabaseError = {
    from() {
      const chain: any = {
        select() { return chain; },
        eq() { return chain; },
        order() { return chain; },
        range() {
          return Promise.resolve({ data: null, error: new Error("Falla DB simulada") });
        },
      };
      return chain;
    },
  };
  await assertRejects(
    () => resumenEntregasOrdenesMotor(mockSupabaseError, "org-A"),
    Error,
    "Falla DB simulada",
  );
  await assertRejects(
    () => resumenEntregasOrdenesMotor(mockSupabasePaginado, ""),
    Error,
    "Organización requerida",
  );
});
