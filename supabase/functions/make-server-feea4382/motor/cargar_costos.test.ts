import { assertEquals, assert } from "https://deno.land/std@0.192.0/testing/asserts.ts";
import { cargarDatosCosteo } from "./cargar_costos.ts";

Deno.test("cargarDatosCosteo: con largo_ft nulo el modelo mapeado lleva 0 y no NaN", async () => {
  const mockSupabase = {
    from: (table: string) => {
      if (table === "modelos") {
        return {
          select: () => ({
            eq: () => ({
              single: () => Promise.resolve({
                data: {
                  id: "mod-dolly-id",
                  tipo: "dolly",
                  largo_ft: null,
                  num_ejes: 2,
                  costos_derivados_de: null,
                  productos: { nombre: "DOLLY 2 EJES" }
                },
                error: null
              })
            })
          })
        };
      }
      if (table === "receta_base" || table === "costos_modelo" || table === "procesos_manufactura" || table === "grupos_configuracion" || table === "opcion_costos") {
        return {
          select: () => ({
            eq: () => ({
              eq: () => Promise.resolve({ data: [] }),
              order: () => Promise.resolve({ data: [] }),
              then: (resolve: any) => resolve({ data: [] })
            }),
            order: () => Promise.resolve({ data: [] }),
            then: (resolve: any) => resolve({ data: [] })
          })
        };
      }
      if (table === "parametros_costeo") {
        return {
          select: () => ({
            eq: () => ({
              maybeSingle: () => Promise.resolve({
                data: { valor: { plataforma: 110000, dolly: 65000 } }
              })
            })
          })
        };
      }
      return {
        select: () => ({
          eq: () => Promise.resolve({ data: [] }),
          then: (resolve: any) => resolve({ data: [] })
        })
      };
    }
  };

  const res = await cargarDatosCosteo(mockSupabase as any, "mod-dolly-id");
  assertEquals(res.modelo.largo_ft, 0);
  assert(!isNaN(res.modelo.largo_ft));
  assertEquals(res.modelo.tipo, "dolly");
  assertEquals(res.ganancia, 65000);
});

Deno.test("cargarDatosCosteo: para tipo gondola la ganancia se lee de gondola_servicios_sueldos", async () => {
  const mockSupabase = {
    from: (table: string) => {
      if (table === "modelos") {
        return {
          select: () => ({
            eq: () => ({
              single: () => Promise.resolve({
                data: {
                  id: "mod-gondola-id",
                  tipo: "gondola",
                  largo_ft: null,
                  num_ejes: 2,
                  costos_derivados_de: null,
                  productos: { nombre: "GONDOLA 2 EJES 45 M3" }
                },
                error: null
              })
            })
          })
        };
      }
      if (table === "receta_base" || table === "costos_modelo" || table === "procesos_manufactura" || table === "grupos_configuracion" || table === "opcion_costos") {
        return {
          select: () => ({
            eq: () => ({
              eq: () => Promise.resolve({ data: [] }),
              order: () => Promise.resolve({ data: [] }),
              then: (resolve: any) => resolve({ data: [] })
            }),
            order: () => Promise.resolve({ data: [] }),
            then: (resolve: any) => resolve({ data: [] })
          })
        };
      }
      if (table === "parametros_costeo") {
        return {
          select: () => ({
            eq: () => ({
              maybeSingle: () => Promise.resolve({
                data: { valor: { plataforma: 110000, dolly: 65000, gondola_servicios_sueldos: 100000 } }
              })
            })
          })
        };
      }
      return {
        select: () => ({
          eq: () => Promise.resolve({ data: [] }),
          then: (resolve: any) => resolve({ data: [] })
        })
      };
    }
  };

  const res = await cargarDatosCosteo(mockSupabase as any, "mod-gondola-id");
  assertEquals(res.modelo.largo_ft, 0);
  assert(!isNaN(res.modelo.largo_ft));
  assertEquals(res.modelo.tipo, "gondola");
  assertEquals(res.ganancia, 100000);
});
