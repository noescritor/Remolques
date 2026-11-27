/**
 * Pruebas unitarias de los 12 filtros de equipos cancelados (+ listarPlanesPago)
 * usando formas reales de respuestas del cliente Supabase.
 * Cada prueba falla si se quita la guarda correspondiente.
 */
import { assertEquals, assertRejects } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { obtenerPlanSemanal, obtenerTrazabilidadOperario } from "./plan_produccion.ts";
import { listarInspeccionesCalidad } from "./calidad.ts";
import {
  obtenerCobranzaCotizacion,
  obtenerCobranzaEquipo,
  guardarValorEquipo,
  listarPlanesPago,
  CobrosError,
} from "./cobros.ts";
import {
  listarDespieceOT,
  generarDespieceOT,
  entregarFaseCompleta,
  agregarLineaManual,
} from "./checklist_almacen.ts";
import {
  actualizarOrdenTrabajoSegura,
  regenerarFichaDeOrden,
} from "./generar_ordenes_cotizacion.ts";

const ORG = "org-filtros-1";
const CANCELADA_TS = "2026-11-27T01:00:00Z";

function createQueryMock(resolver: (ctx: {
  table: string;
  op: "select" | "update" | "insert" | "delete";
  selectStr?: string;
  payload?: any;
  filters: Array<{ kind: string; col: string; val: any }>;
}) => any, rpcResolver?: (fn: string, args: any) => any) {
  return {
    rpc: async (fn: string, args: any) => {
      if (rpcResolver) return rpcResolver(fn, args);
      return { data: [], error: null };
    },
    from: (table: string) => {
      let op: "select" | "update" | "insert" | "delete" = "select";
      let selectStr: string | undefined;
      let payload: any;
      const filters: Array<{ kind: string; col: string; val: any }> = [];

      const exec = () => resolver({ table, op, selectStr, payload, filters });

      const chain: any = {
        select: (s?: string) => {
          selectStr = s;
          return chain;
        },
        update: (p: any) => {
          op = "update";
          payload = p;
          return chain;
        },
        insert: (p: any) => {
          op = "insert";
          payload = p;
          return chain;
        },
        delete: () => {
          op = "delete";
          return chain;
        },
        eq: (col: string, val: any) => {
          filters.push({ kind: "eq", col, val });
          return chain;
        },
        neq: (col: string, val: any) => {
          filters.push({ kind: "neq", col, val });
          return chain;
        },
        is: (col: string, val: any) => {
          filters.push({ kind: "is", col, val });
          return chain;
        },
        gte: (col: string, val: any) => {
          filters.push({ kind: "gte", col, val });
          return chain;
        },
        lte: (col: string, val: any) => {
          filters.push({ kind: "lte", col, val });
          return chain;
        },
        in: (col: string, val: any) => {
          filters.push({ kind: "in", col, val });
          return chain;
        },
        order: () => chain,
        limit: () => chain,
        range: () => chain,
        maybeSingle: async () => {
          const r = exec();
          if (r && "data" in r && "error" in r) return r;
          return { data: Array.isArray(r) ? r[0] ?? null : r ?? null, error: null };
        },
        single: async () => {
          const r = exec();
          if (r && "data" in r && "error" in r) return r;
          const item = Array.isArray(r) ? r[0] ?? null : r ?? null;
          return { data: item, error: item ? null : { message: "No rows" } };
        },
        then: (resolve: any, reject: any) => {
          try {
            const r = exec();
            if (r && "data" in r && "error" in r) resolve(r);
            else resolve({ data: r ?? [], error: null });
          } catch (e) {
            reject(e);
          }
        },
      };
      return chain;
    },
  };
}

// 1. plan_produccion.ts L480: obtenerPlanProduccion excluye tareas ligadas a equipos cancelados
Deno.test("filtro R2 #1: plan_produccion obtenerPlanProduccion excluye tareas de equipo cancelado", async () => {
  const client = createQueryMock(({ table }) => {
    if (table === "plan_tareas") {
      return [
        {
          id: "t-act",
          orden_trabajo_id: "ot-act",
          orden_trabajo: { id: "ot-act", nomenclatura_id: "ACT-1", modelo: "M1", cancelada_el: null },
          operarios_asig: [],
        },
        {
          id: "t-can",
          orden_trabajo_id: "ot-can",
          orden_trabajo: { id: "ot-can", nomenclatura_id: "CAN-1", modelo: "M1", cancelada_el: CANCELADA_TS },
          operarios_asig: [],
        },
        {
          id: "t-sin-ot",
          orden_trabajo_id: null,
          orden_trabajo: null,
          operarios_asig: [],
        },
      ];
    }
    return [];
  });

  const tareas = await obtenerPlanSemanal(client, ORG, "2026-11-23", "2026-11-29");
  assertEquals(tareas.map((t: any) => t.id), ["t-act", "t-sin-ot"]);
});

// 2. plan_produccion.ts L947: obtenerTrazabilidadOperario excluye tareas ligadas a equipos cancelados
Deno.test("filtro R2 #2: plan_produccion obtenerTrazabilidadOperario excluye tareas de equipo cancelado", async () => {
  const client = createQueryMock(({ table }) => {
    if (table === "operarios") {
      return { id: "op-1", nombre: "Juan", puesto: "Soldador", telefono: null, activo: true };
    }
    if (table === "plan_tarea_operarios") {
      return [
        {
          tarea: {
            id: "t-act",
            orden_trabajo: { id: "ot-act", nomenclatura_id: "ACT-1", modelo: "M1", cancelada_el: null },
          },
        },
        {
          tarea: {
            id: "t-can",
            orden_trabajo: { id: "ot-can", nomenclatura_id: "CAN-1", modelo: "M1", cancelada_el: CANCELADA_TS },
          },
        },
      ];
    }
    return [];
  });

  const res = await obtenerTrazabilidadOperario(client, ORG, "op-1");
  assertEquals(res.tareas.map((t: any) => t.id), ["t-act"]);
});

// 3. calidad.ts L379: listarInspeccionesCalidad excluye inspecciones de equipos cancelados
Deno.test("filtro R2 #3: calidad listarInspeccionesCalidad excluye equipo cancelado", async () => {
  const client = createQueryMock(({ table }) => {
    if (table === "orden_calidad_inspecciones") {
      return [
        { id: "insp-act", orden_trabajo_id: "ot-act", orden: { id: "ot-act", cancelada_el: null } },
        { id: "insp-can", orden_trabajo_id: "ot-can", orden: { id: "ot-can", cancelada_el: CANCELADA_TS } },
      ];
    }
    return [];
  });

  const lista = await listarInspeccionesCalidad(client, ORG, {}, client);
  assertEquals(lista.map((i: any) => i.id), ["insp-act"]);
});

// 4. cobros.ts L390: obtenerCobranzaCotizacion filtra ordenes_trabajo con .is("cancelada_el", null)
Deno.test("filtro R2 #4: cobros obtenerCobranzaCotizacion filtra ordenes canceladas", async () => {
  const ordenesDb = [
    { id: "ot-act", organizacion_id: ORG, cotizacion_id: "cot-1", nomenclatura_id: "ACT-1", modelo: "M1", tipo_equipo: "01", cancelada_el: null },
    { id: "ot-can", organizacion_id: ORG, cotizacion_id: "cot-1", nomenclatura_id: "CAN-1", modelo: "M1", tipo_equipo: "01", cancelada_el: CANCELADA_TS },
  ];

  const client = createQueryMock(({ table, filters }) => {
    if (table === "cotizaciones") {
      return { id: "cot-1", organizacion_id: ORG, folio: "COT-1", estado: "Aprobada", total: 100000, cliente_id: null };
    }
    if (table === "ordenes_trabajo") {
      const filtraCancelada = filters.some((f) => f.kind === "is" && f.col === "cancelada_el" && f.val === null);
      return filtraCancelada ? ordenesDb.filter((o) => o.cancelada_el === null) : ordenesDb;
    }
    return [];
  });

  const res = await obtenerCobranzaCotizacion(client as any, ORG, "cot-1", "2026-11-27");
  assertEquals(res.equipos.map((e) => e.orden_trabajo_id), ["ot-act"]);
});

// 5. cobros.ts L551: obtenerCobranzaEquipo rechaza con 404 si la orden está cancelada
Deno.test("filtro R2 #5: cobros obtenerCobranzaEquipo rechaza orden cancelada con 404", async () => {
  const client = createQueryMock(({ table }) => {
    if (table === "ordenes_trabajo") {
      return { id: "ot-can", organizacion_id: ORG, nomenclatura_id: "CAN-1", modelo: "M1", tipo_equipo: "01", cotizacion_id: null, cancelada_el: CANCELADA_TS };
    }
    return null;
  });

  const err = await assertRejects(
    () => obtenerCobranzaEquipo(client as any, ORG, "ot-can"),
    CobrosError
  );
  assertEquals(err.status, 404);
});

// 6. cobros.ts L611: guardarValorEquipo rechaza con 409 orden_cancelada si la orden está cancelada
Deno.test("filtro R2 #6: cobros guardarValorEquipo rechaza orden cancelada con 409", async () => {
  const client = createQueryMock(({ table }) => {
    if (table === "ordenes_trabajo") {
      return { id: "ot-can", cancelada_el: CANCELADA_TS };
    }
    return null;
  });

  const err = await assertRejects(
    () => guardarValorEquipo(client as any, ORG, "ot-can", 50000),
    CobrosError
  );
  assertEquals(err.status, 409);
  assertEquals(err.codigo, "orden_cancelada");
});

// Extra R2: listarPlanesPago oculta planes de equipos cancelados y conserva planes por cotización
Deno.test("filtro R2 #6b: cobros listarPlanesPago oculta plan de equipo cancelado y conserva plan de cotización", async () => {
  const client = createQueryMock(({ table }) => {
    if (table === "planes_pago") {
      return [
        { id: "pl-cot", cotizacion_id: "cot-1", orden_trabajo_id: null, orden_trabajo: null, plan_pagos_parcialidades: [] },
        { id: "pl-act", cotizacion_id: "cot-1", orden_trabajo_id: "ot-act", orden_trabajo: { id: "ot-act", cancelada_el: null }, plan_pagos_parcialidades: [] },
        { id: "pl-can", cotizacion_id: "cot-1", orden_trabajo_id: "ot-can", orden_trabajo: { id: "ot-can", cancelada_el: CANCELADA_TS }, plan_pagos_parcialidades: [] },
      ];
    }
    return [];
  });

  const planes = await listarPlanesPago(client as any, ORG, { cotizacionId: "cot-1" });
  assertEquals(planes.map((p: any) => p.id), ["pl-cot", "pl-act"]);
});

// 7. checklist_almacen.ts L73: listarDespieceOT rechaza orden cancelada
Deno.test("filtro R2 #7: checklist_almacen listarDespieceOT rechaza orden cancelada", async () => {
  const client = createQueryMock(({ table }) => {
    if (table === "ordenes_trabajo") {
      return { id: "ot-can", cancelada_el: CANCELADA_TS };
    }
    return [];
  });

  await assertRejects(
    () => listarDespieceOT(client, { otId: "ot-can", orgId: ORG }),
    Error,
    "orden_cancelada"
  );
});

// 8. checklist_almacen.ts L189: generarDespieceOT rechaza orden cancelada
Deno.test("filtro R2 #8: checklist_almacen generarDespieceOT rechaza orden cancelada", async () => {
  const client = createQueryMock(({ table }) => {
    if (table === "ordenes_trabajo") {
      return { id: "ot-can", cotizacion_id: null, modelo: "M1", caracteristicas: {}, organizacion_id: ORG, cancelada_el: CANCELADA_TS };
    }
    return [];
  });

  await assertRejects(
    () => generarDespieceOT(client, { otId: "ot-can", orgId: ORG }),
    Error,
    "orden_cancelada"
  );
});

// 9. checklist_almacen.ts L562: entregarFaseCompleta rechaza orden cancelada
Deno.test("filtro R2 #9: checklist_almacen entregarFaseCompleta rechaza orden cancelada", async () => {
  const client = createQueryMock(({ table }) => {
    if (table === "ordenes_trabajo") {
      return { id: "ot-can", caracteristicas: { unidad: 1 }, cancelada_el: CANCELADA_TS };
    }
    if (table === "fases_despiece") {
      return { id: "f-1", clave: "paso_1", nombre: "Paso 1" };
    }
    return [];
  }, () => ({ data: { lineas_entregadas: 0, detalles: [] }, error: null }));

  await assertRejects(
    () => entregarFaseCompleta(client, { orgId: ORG, otId: "ot-can", faseClave: "paso_1", operarioNombre: "Juan" }),
    Error,
    "orden_cancelada"
  );
});

// 10. checklist_almacen.ts L665: agregarLineaManual rechaza orden cancelada
Deno.test("filtro R2 #10: checklist_almacen agregarLineaManual rechaza orden cancelada", async () => {
  const client = createQueryMock(({ table }) => {
    if (table === "ordenes_trabajo") {
      return { id: "ot-can", caracteristicas: { unidad: 1 }, cancelada_el: CANCELADA_TS };
    }
    if (table === "fases_despiece") {
      return { id: "f-1", clave: "paso_1" };
    }
    return [];
  });

  await assertRejects(
    () =>
      agregarLineaManual(client, {
        orgId: ORG,
        otId: "ot-can",
        faseClave: "paso_1",
        descripcion: "Tornillo 1/2",
        cantidadRequerida: 4,
      }),
    Error,
    "orden_cancelada"
  );
});

// 11. generar_ordenes_cotizacion.ts L447: actualizarOrdenTrabajoSegura aplica .is("cancelada_el", null) en el UPDATE (carrera entre SELECT y UPDATE)
Deno.test("filtro R2 #11: generar_ordenes_cotizacion actualizarOrdenTrabajoSegura exige .is('cancelada_el', null) en UPDATE", async () => {
  let estadoCancelada = false;
  const client = createQueryMock(({ table, op, filters }) => {
    if (table === "ordenes_trabajo" && op === "select") {
      // En el SELECT aún estaba activa; inmediatamente después otra sesión la cancela
      const row = { id: "ot-race", cancelada_el: null, caracteristicas: {} };
      estadoCancelada = true;
      return row;
    }
    if (table === "ordenes_trabajo" && op === "update") {
      const exigeNoCancelada = filters.some((f) => f.kind === "is" && f.col === "cancelada_el" && f.val === null);
      if (estadoCancelada && exigeNoCancelada) {
        return { data: null, error: { message: "No rows updated" } };
      }
      return { data: { id: "ot-race", niv: "NEW" }, error: null };
    }
    return null;
  });

  await assertRejects(() =>
    actualizarOrdenTrabajoSegura(client, {
      id: "ot-race",
      orgId: ORG,
      rawPayload: { niv: "NEW" },
    })
  );
});

// 12. generar_ordenes_cotizacion.ts L482: regenerarFichaDeOrden rechaza orden cancelada con 409
Deno.test("filtro R2 #12: generar_ordenes_cotizacion regenerarFichaDeOrden rechaza orden cancelada con 409", async () => {
  const client = createQueryMock(({ table }) => {
    if (table === "ordenes_trabajo") {
      return {
        id: "ot-can",
        organizacion_id: ORG,
        cancelada_el: CANCELADA_TS,
        cotizacion: { items: [{ id: "i-1", descripcion: "Plataforma" }] },
      };
    }
    return null;
  });

  const err: any = await assertRejects(() =>
    regenerarFichaDeOrden(client, { id: "ot-can", orgId: ORG })
  );
  assertEquals(err.status, 409);
  assertEquals(err.codigo, "orden_cancelada");
});
