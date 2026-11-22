import { assertEquals, assertRejects } from "https://deno.land/std@0.192.0/testing/asserts.ts";
import {
  agruparResumenEntregas,
  resumenEntregasOrdenesMotor,
} from "./resumen_entregas.ts";

Deno.test("resumen_entregas: agrupa por orden y por fase, excluye anuladas y cuenta sobre-entregas como completas", () => {
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
      orden_trabajo_id: "ot-2",
      fase_clave: "corte",
      cantidad_requerida: 10,
      cantidad_entregada: 0,
    },
  ]);

  assertEquals(res.length, 2);

  const ot1 = res.find((r) => r.orden_trabajo_id === "ot-1")!;
  assertEquals(ot1.total_partidas, 3);
  assertEquals(ot1.partidas_completas, 2);
  assertEquals(ot1.porcentaje, 67);
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

  const ot2 = res.find((r) => r.orden_trabajo_id === "ot-2")!;
  assertEquals(ot2.total_partidas, 1);
  assertEquals(ot2.partidas_completas, 0);
  assertEquals(ot2.porcentaje, 0);
});

Deno.test("resumen_entregas: lista vacía retorna arreglo vacío", () => {
  assertEquals(agruparResumenEntregas([]), []);
});

Deno.test("resumen_entregas (guardia org): filtra estrictamente por organizacion_id en una sola consulta", async () => {
  const filtrosAplicados: Array<{ col: string; val: unknown }> = [];
  let consultas = 0;

  const mockSupabase = {
    from(tabla: string) {
      assertEquals(tabla, "v_orden_despiece_avance");
      consultas += 1;
      const chain: any = {
        select() {
          return chain;
        },
        eq(col: string, val: unknown) {
          filtrosAplicados.push({ col, val });
          return Promise.resolve({
            data: [
              {
                orden_trabajo_id: "ot-org-a",
                fase_clave: "corte",
                cantidad_requerida: 2,
                cantidad_entregada: 2,
              },
            ],
            error: null,
          });
        },
      };
      return chain;
    },
  };

  const res = await resumenEntregasOrdenesMotor(mockSupabase, "org-A");
  assertEquals(consultas, 1);
  assertEquals(filtrosAplicados, [{ col: "organizacion_id", val: "org-A" }]);
  assertEquals(res.length, 1);
  assertEquals(res[0].orden_trabajo_id, "ot-org-a");

  await assertRejects(
    () => resumenEntregasOrdenesMotor(mockSupabase, ""),
    Error,
    "Organización requerida",
  );
});
