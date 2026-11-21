import { assertEquals, assertRejects } from "https://deno.land/std@0.192.0/testing/asserts.ts";
import {
  CalidadError,
  mapearErrorRpcCalidad,
  calcularResumenInspeccion,
  asegurarSemillaCalidad,
  listarPlantillasCalidad,
  obtenerPlantillaCalidad,
  crearInspeccionCalidad,
  guardarPlantillaCalidad,
  publicarPlantillaCalidad,
  guardarResultadosCalidad,
  cerrarInspeccionCalidad,
  reabrirInspeccionCalidad,
  obtenerResumenCalidadOrdenes,
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

  const e5 = mapearErrorRpcCalidad({ message: "UNIDAD_INVALIDA: La unidad 3 está fuera de rango (1..2)" });
  assertEquals(e5.status, 400);
  assertEquals(e5.codigo, "UNIDAD_INVALIDA");
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

Deno.test("calidad: calcularResumenInspeccion ignora filas con unidad fuera de rango", () => {
  const res = calcularResumenInspeccion(
    10,
    ["Plana 1", "Plana 2"],
    [
      { resultado: "conforme", unidad: 1 },
      { resultado: "no_conforme", unidad: 3 },
      { resultado: "conforme", unidad: 0 },
    ],
  );
  assertEquals(res.total, 20);
  assertEquals(res.capturados, 1);
  assertEquals(res.conformes, 1);
  assertEquals(res.no_conformes, 0);
  assertEquals(res.pendientes, 19);
});

Deno.test("calidad (guardia org): listarPlantillasCalidad y obtenerPlantillaCalidad filtran por organizacion_id", async () => {
  const eqCalls: Array<{ tabla: string; col: string; val: any; head: boolean }> = [];

  const mockSupabase = {
    from: (tabla: string) => ({
      select: (_cols: string, opts?: any) => {
        const esHead = Boolean(opts?.head);
        const builder: any = {
          eq: (col: string, val: any) => {
            eqCalls.push({ tabla, col, val, head: esHead });
            return builder;
          },
          order: () => builder,
          maybeSingle: async () => {
            if (tabla === "calidad_plantillas") {
              return { data: { id: "p-1", organizacion_id: "org-esperada", config: {} }, error: null };
            }
            return { data: null, error: null };
          },
          then: (resolve: (val: any) => void) => {
            if (esHead) return resolve({ count: 1, error: null });
            return resolve({ data: [], error: null });
          },
        };
        return builder;
      },
    }),
  };

  await listarPlantillasCalidad(mockSupabase, "org-esperada");
  const filtroLista = eqCalls.some(
    (c) => !c.head && c.tabla === "calidad_plantillas" && c.col === "organizacion_id" && c.val === "org-esperada",
  );
  assertEquals(filtroLista, true, "listarPlantillasCalidad debe filtrar por organizacion_id");

  eqCalls.length = 0;
  await obtenerPlantillaCalidad(mockSupabase, "org-esperada", "p-1");
  for (const t of ["calidad_plantillas", "calidad_plantilla_grupos", "calidad_plantilla_items"]) {
    const tieneFiltro = eqCalls.some((c) => c.tabla === t && c.col === "organizacion_id" && c.val === "org-esperada");
    assertEquals(tieneFiltro, true, `obtenerPlantillaCalidad debe filtrar ${t} por organizacion_id`);
  }
});

Deno.test("calidad (guardia org): todos los RPCs de escritura/resumen reciben p_org = orgId del contexto", async () => {
  const rpcCalls: Array<{ fn: string; args: Record<string, any> }> = [];
  const mockSupabase = {
    from: (tabla: string) => ({
      select: (_cols: string, opts?: any) => {
        const builder: any = {
          eq: () => builder,
          order: () => builder,
          maybeSingle: async () => {
            if (tabla === "calidad_plantillas") return { data: { id: "p-1", config: {} }, error: null };
            if (tabla === "orden_calidad_inspecciones") return { data: { id: "i-1", orden_trabajo_id: "o-1", plantilla_id: "p-1" }, error: null };
            return { data: null, error: null };
          },
          then: (resolve: (val: any) => void) => {
            if (opts?.head) return resolve({ count: 1, error: null });
            return resolve({ data: [], error: null });
          },
        };
        return builder;
      },
    }),
  };
  const mockService = {
    rpc: async (fn: string, args: Record<string, any>) => {
      rpcCalls.push({ fn, args });
      if (fn === "cerrar_inspeccion_calidad") {
        return { data: { id: "i-1", estado: "cerrada", advertencias: { pendientes: 0, no_conformes: 0 } }, error: null };
      }
      if (fn === "resumen_calidad_ordenes") {
        return { data: [], error: null };
      }
      return { data: "id-ret", error: null };
    },
  };

  const org = "org-segura-123";
  await crearInspeccionCalidad(mockSupabase, org, { orden_trabajo_id: "o-1", formato: "entrega" }, "u-1", mockService);
  await guardarPlantillaCalidad(mockSupabase, org, "p-1", { nombre: "N" }, mockService);
  await publicarPlantillaCalidad(mockSupabase, org, "p-1", mockService);
  await guardarResultadosCalidad(mockSupabase, org, "i-1", [], "u-1", mockService);
  await cerrarInspeccionCalidad(mockSupabase, org, "i-1", {}, "u-1", mockService);
  await reabrirInspeccionCalidad(mockSupabase, org, "i-1", "u-1", mockService);
  await obtenerResumenCalidadOrdenes(mockSupabase, org, mockService);

  assertEquals(rpcCalls.length, 7);
  for (const call of rpcCalls) {
    assertEquals(call.args.p_org, org, `RPC ${call.fn} debe recibir p_org === ${org}`);
  }
});
