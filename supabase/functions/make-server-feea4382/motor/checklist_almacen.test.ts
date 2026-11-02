import { assertEquals, assertRejects } from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  listarDespieceOT,
  registrarEntrega,
  ajustarCantidadRequerida,
  eliminarLineaManual,
} from "./checklist_almacen.ts";

function createFakeClient(opts: {
  lineas?: any[];
  entregas?: any[];
  fases?: any[];
  rpcHandler?: (name: string, args: any) => any;
}) {
  return {
    from: (table: string) => {
      let filterOrg = "";
      let filterOT = "";
      let filterLinea = "";
      let inLineas: any[] = [];

      const builder: any = {
        select: (_cols?: string, selectOpts?: any) => {
          if (selectOpts?.count === "exact" && selectOpts?.head) {
            return builder;
          }
          return builder;
        },
        eq: (col: string, val: any) => {
          if (col === "organizacion_id") filterOrg = val;
          if (col === "orden_trabajo_id") filterOT = val;
          if (col === "linea_id") filterLinea = val;
          return builder;
        },
        in: (col: string, vals: any[]) => {
          if (col === "linea_id") inLineas = vals;
          return builder;
        },
        order: () => builder,
        single: () => {
          if (table === "fases_despiece") {
            return Promise.resolve({ data: opts.fases?.[0] || { id: "f-1" }, error: null });
          }
          return Promise.resolve({ data: opts.lineas?.[0] || null, error: null });
        },
        then: (resolve: any) => {
          if (table === "v_orden_despiece_avance") {
            resolve({ data: opts.lineas || [], error: null });
          } else if (table === "orden_despiece_entregas") {
            resolve({ data: opts.entregas || [], count: opts.entregas?.length || 0, error: null });
          } else if (table === "fases_despiece") {
            resolve({ data: opts.fases || [], error: null });
          } else {
            resolve({ data: [], error: null });
          }
        },
        update: (vals: any) => ({
          eq: () => ({
            eq: () => ({
              select: () => ({
                single: () => Promise.resolve({ data: { ...vals, id: "linea-1" }, error: null }),
              }),
            }),
          }),
        }),
        delete: () => ({
          eq: () => ({
            eq: () => Promise.resolve({ error: null }),
          }),
        }),
      };
      return builder;
    },
    rpc: (name: string, args: any) => {
      if (opts.rpcHandler) {
        return opts.rpcHandler(name, args);
      }
      return Promise.resolve({ data: { success: true, args }, error: null });
    },
  };
}

Deno.test("checklist_almacen - 1. listarDespieceOT calcula métricas y porcentajes de avance", async () => {
  const lineasFicticias = [
    {
      linea_id: "l-1",
      descripcion: "ALMA VIGA",
      fase_orden: 1,
      fase_clave: "paso_1",
      fase_nombre: "Paso 1",
      cantidad_requerida: 2,
      cantidad_entregada: 2,
      cantidad_pendiente: 0,
      cantidad_reposicion: 0,
      estado_entrega: "completo",
    },
    {
      linea_id: "l-2",
      descripcion: "SOLERA",
      fase_orden: 2,
      fase_clave: "paso_2",
      fase_nombre: "Paso 2",
      cantidad_requerida: 4,
      cantidad_entregada: 2,
      cantidad_pendiente: 2,
      cantidad_reposicion: 1,
      estado_entrega: "parcial",
    },
  ];

  const client = createFakeClient({ lineas: lineasFicticias });
  const res = await listarDespieceOT(client, { otId: "ot-100", orgId: "org-1" });

  assertEquals(res.metricas.total_lineas, 2);
  assertEquals(res.metricas.lineas_completas, 1);
  assertEquals(res.metricas.total_piezas_requeridas, 6);
  assertEquals(res.metricas.total_piezas_entregadas, 4);
  assertEquals(res.metricas.total_piezas_pendientes, 2);
  assertEquals(res.metricas.total_piezas_reposicion, 1);
  assertEquals(res.metricas.porcentaje_avance, 67); // 4 / 6 = 66.6% -> 67%
});

Deno.test("checklist_almacen - 2. registrarEntrega valida cantidades positivas y maneja errores de RPC", async () => {
  const client = createFakeClient({
    rpcHandler: (name, args) => {
      if (args.p_cantidad > 5) {
        return Promise.resolve({
          data: null,
          error: { message: "excede_requerido: La cantidad 6 excede el saldo pendiente 5" },
        });
      }
      return Promise.resolve({ data: { success: true, entrega_id: "e-1", pendiente: 5 - args.p_cantidad }, error: null });
    },
  });

  // Cantidad <= 0 rechaza antes de RPC
  await assertRejects(
    async () => {
      await registrarEntrega(client, { orgId: "org-1", lineaId: "l-1", cantidad: 0 });
    },
    Error,
    "mayor a 0"
  );

  // Cantidad válida llama a RPC
  const okRes = await registrarEntrega(client, { orgId: "org-1", lineaId: "l-1", cantidad: 2 });
  assertEquals(okRes.success, true);
  assertEquals(okRes.pendiente, 3);

  // Sobre-entrega retorna el error exacto del RPC
  await assertRejects(
    async () => {
      await registrarEntrega(client, { orgId: "org-1", lineaId: "l-1", cantidad: 6 });
    },
    Error,
    "excede_requerido"
  );
});

Deno.test("checklist_almacen - 3. ajustarCantidadRequerida impide reducir por debajo de lo ya entregado", async () => {
  // Simulamos que ya se entregaron 3 piezas
  const client = createFakeClient({
    entregas: [{ cantidad: 2 }, { cantidad: 1 }],
  });

  // Intentar ajustar a 2 debe ser rechazado porque ya se entregaron 3
  await assertRejects(
    async () => {
      await ajustarCantidadRequerida(client, {
        orgId: "org-1",
        lineaId: "l-1",
        nuevaCantidad: 2,
        motivo: "Ajuste de ingeniería",
      });
    },
    Error,
    "ya se han entregado 3"
  );

  // Ajustar a 4 es válido
  const res = await ajustarCantidadRequerida(client, {
    orgId: "org-1",
    lineaId: "l-1",
    nuevaCantidad: 4,
    motivo: "Se requiere 1 pieza adicional",
  });
  assertEquals(res.cantidad_requerida, 4);
});

Deno.test("checklist_almacen - 4. eliminarLineaManual impide borrar líneas con entregas previas", async () => {
  const clientConEntregas = createFakeClient({
    entregas: [{ id: "e-1", cantidad: 1 }],
  });

  await assertRejects(
    async () => {
      await eliminarLineaManual(clientConEntregas, { orgId: "org-1", lineaId: "l-1" });
    },
    Error,
    "ya cuenta con entregas"
  );

  const clientSinEntregas = createFakeClient({ entregas: [] });
  const okDel = await eliminarLineaManual(clientSinEntregas, { orgId: "org-1", lineaId: "l-2" });
  assertEquals(okDel.success, true);
});
