import { assertEquals, assertRejects } from "https://deno.land/std@0.192.0/testing/asserts.ts";
import {
  CalidadError,
  mapearErrorRpcCalidad,
  calcularResumenInspeccion,
  asegurarSemillaCalidad,
  listarPlantillasCalidad,
  obtenerPlantillaCalidad,
  crearInspeccionCalidad,
  cerrarInspeccionCalidad,
} from "./calidad.ts";

Deno.test("calidad: mapearErrorRpcCalidad mapea SIN_PLANTILLA, YA_EXISTE y BLOQUEADA_POR_NO_CONFORMES a 409", () => {
  const e1 = mapearErrorRpcCalidad({ message: "SIN_PLANTILLA: falta plantilla" });
  assertEquals(e1.status, 409);
  assertEquals(e1.codigo, "SIN_PLANTILLA");

  const e2 = mapearErrorRpcCalidad({ message: "YA_EXISTE:11111111-1111-1111-1111-111111111111" });
  assertEquals(e2.status, 409);
  assertEquals(e2.codigo, "YA_EXISTE");
  assertEquals(e2.extra?.inspeccion_id, "11111111-1111-1111-1111-111111111111");

  const e3 = mapearErrorRpcCalidad({ message: "BLOQUEADA_POR_NO_CONFORMES: 2" });
  assertEquals(e3.status, 409);
  assertEquals(e3.codigo, "BLOQUEADA_POR_NO_CONFORMES");

  const e4 = mapearErrorRpcCalidad({ message: "NO_EDITABLE" });
  assertEquals(e4.status, 409);
  assertEquals(e4.codigo, "NO_EDITABLE");
});

Deno.test("calidad: calcularResumenInspeccion con 2 unidades (57 ítems x 2 = 114 esperados)", () => {
  const res = calcularResumenInspeccion(
    57,
    ["Plana 1", "Plana 2"],
    [
      { resultado: "conforme" },
      { resultado: "conforme" },
      { resultado: "no_conforme" },
      { resultado: "no_aplica" },
    ],
  );
  assertEquals(res.total, 114);
  assertEquals(res.capturados, 4);
  assertEquals(res.conformes, 2);
  assertEquals(res.no_conformes, 1);
  assertEquals(res.no_aplica, 1);
  assertEquals(res.pendientes, 110);
});

Deno.test("calidad: asegurarSemillaCalidad invoca sembrar_calidad_plantillas solo si count === 0", async () => {
  let rpcs: string[] = [];
  const mockSupabaseEmpty = {
    from: () => ({
      select: () => ({
        eq: async () => ({ count: 0, error: null }),
      }),
    }),
  };
  const mockService = {
    rpc: async (fn: string, _args: any) => {
      rpcs.push(fn);
      return { data: null, error: null };
    },
  };

  await asegurarSemillaCalidad(mockSupabaseEmpty, "org-1", mockService);
  assertEquals(rpcs, ["sembrar_calidad_plantillas"]);

  rpcs = [];
  const mockSupabaseFull = {
    from: () => ({
      select: () => ({
        eq: async () => ({ count: 5, error: null }),
      }),
    }),
  };
  await asegurarSemillaCalidad(mockSupabaseFull, "org-1", mockService);
  assertEquals(rpcs.length, 0);
});

Deno.test("calidad: listarPlantillasCalidad filtra por linea y delega a org del contexto", async () => {
  const mockSupabase = {
    from: () => ({
      select: (_cols: string, opts?: any) => {
        if (opts?.head) {
          return { eq: async () => ({ count: 2, error: null }) };
        }
        const builder: any = {
          eq: () => builder,
          order: () => builder,
          then: (resolve: (val: any) => void) =>
            resolve({
              data: [
                { id: "p1", formato: "entrega", estado: "activa", linea: { clave: "plataforma" } },
                { id: "p2", formato: "entrega", estado: "activa", linea: { clave: "dolly" } },
              ],
              error: null,
            }),
        };
        return builder;
      },
    }),
  };

  const soloDolly = await listarPlantillasCalidad(mockSupabase, "org-1", { linea: "dolly" });
  assertEquals(soloDolly.length, 1);
  assertEquals(soloDolly[0].id, "p2");
});

Deno.test("calidad: obtenerPlantillaCalidad de otra organización devuelve 404 PLANTILLA_NO_ENCONTRADA", async () => {
  const mockSupabase = {
    from: () => ({
      select: () => {
        const builder: any = {
          eq: () => builder,
          maybeSingle: async () => ({ data: null, error: null }),
        };
        return builder;
      },
    }),
  };

  await assertRejects(
    () => obtenerPlantillaCalidad(mockSupabase, "org-ajena", "p1"),
    CalidadError,
    "Plantilla de calidad no encontrada",
  );
});

Deno.test("calidad: crearInspeccionCalidad exige serviceClient y propaga SIN_PLANTILLA / YA_EXISTE", async () => {
  const mockSupabase = {
    from: () => ({
      select: () => ({
        eq: async () => ({ count: 1, error: null }),
      }),
    }),
  };

  await assertRejects(
    () => crearInspeccionCalidad(mockSupabase, "org-1", { orden_trabajo_id: "o1", formato: "entrega" }, null, {
      rpc: async () => ({ data: null, error: { message: "SIN_PLANTILLA" } }),
    }),
    CalidadError,
    "Calidad → Plantillas",
  );

  await assertRejects(
    () => crearInspeccionCalidad(mockSupabase, "org-1", { orden_trabajo_id: "o1", formato: "entrega" }, null, {
      rpc: async () => ({ data: null, error: { message: "YA_EXISTE:insp-99" } }),
    }),
    CalidadError,
    "Ya existe una inspección en proceso",
  );
});

Deno.test("calidad: cerrarInspeccionCalidad propaga advertencias y bloquea cuando bloquea_liberacion=true", async () => {
  const resOk = await cerrarInspeccionCalidad(
    {},
    "org-1",
    "insp-1",
    { liberado_por: "Supervisor" },
    "user-1",
    {
      rpc: async () => ({
        data: { id: "insp-1", estado: "cerrada", advertencias: { pendientes: 3, no_conformes: 2 } },
        error: null,
      }),
    },
  );
  assertEquals(resOk.estado, "cerrada");
  assertEquals(resOk.advertencias.no_conformes, 2);

  await assertRejects(
    () => cerrarInspeccionCalidad({}, "org-1", "insp-1", {}, "user-1", {
      rpc: async () => ({ data: null, error: { message: "BLOQUEADA_POR_NO_CONFORMES: 2" } }),
    }),
    CalidadError,
    "bloqueo de liberación",
  );
});
