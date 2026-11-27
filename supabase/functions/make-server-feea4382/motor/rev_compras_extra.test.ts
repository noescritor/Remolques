import { assertEquals, assertRejects } from "jsr:@std/assert";
import {
  ComprasRecepcionError,
  actualizarCompraProveedorMotor,
  crearCompraProveedorMotor,
} from "./compras_recepcion.ts";

function crearMockDb(
  tablas: Record<string, Array<Record<string, unknown>>>,
  opts: {
    onRpc?: (fn: string, args: Record<string, unknown>) => { data?: unknown; error?: unknown };
    failInsertTable?: string;
    onBeforeUpdate?: (table: string) => void;
  } = {},
) {
  const deletedLog: Array<{ table: string; filters: Record<string, unknown> }> = [];
  const updatedLog: Array<{ table: string; vals: Record<string, unknown>; filters: Record<string, unknown> }> = [];

  function aplicarFiltros(rows: Array<Record<string, unknown>>, filters: Array<(r: Record<string, unknown>) => boolean>) {
    return rows.filter((r) => filters.every((f) => f(r)));
  }

  return {
    deletedLog,
    updatedLog,
    from(table: string) {
      const filters: Array<(r: Record<string, unknown>) => boolean> = [];
      const eqMap: Record<string, unknown> = {};
      let mode: "select" | "insert" | "update" | "delete" = "select";
      let payload: unknown = null;

      const exec = () => {
        const list = tablas[table] || [];
        if (mode === "select") {
          return { data: aplicarFiltros(list, filters), error: null };
        }
        if (mode === "insert") {
          if (opts.failInsertTable === table) {
            return { data: null, error: { message: `Fallo insert en ${table}` } };
          }
          const arr = Array.isArray(payload) ? payload : [payload];
          const inserted = arr.map((r: Record<string, unknown>, i) => ({
            id: r.id || `new-${table}-${list.length + i + 1}`,
            ...r,
          }));
          tablas[table] = [...list, ...inserted];
          return { data: Array.isArray(payload) ? inserted : inserted[0], error: null };
        }
        if (mode === "update") {
          opts.onBeforeUpdate?.(table);
          const vals = payload as Record<string, unknown>;
          updatedLog.push({ table, vals: { ...vals }, filters: { ...eqMap } });
          const matched = aplicarFiltros(list, filters);
          for (const row of matched) Object.assign(row, vals);
          return { data: matched, error: null };
        }
        if (mode === "delete") {
          deletedLog.push({ table, filters: { ...eqMap } });
          tablas[table] = list.filter((r) => !filters.every((f) => f(r)));
          return { data: null, error: null };
        }
        return { data: [], error: null };
      };

      const chain: Record<string, unknown> = {
        select() {
          return chain;
        },
        insert(vals: unknown) {
          mode = "insert";
          payload = vals;
          return chain;
        },
        update(vals: Record<string, unknown>) {
          mode = "update";
          payload = vals;
          return chain;
        },
        delete() {
          mode = "delete";
          return chain;
        },
        eq(col: string, val: unknown) {
          eqMap[col] = val;
          filters.push((r) => r[col] === val);
          return chain;
        },
        in(col: string, vals: unknown[]) {
          const s = new Set(vals);
          filters.push((r) => s.has(r[col]));
          return chain;
        },
        order() {
          return chain;
        },
        limit() {
          return chain;
        },
        async single() {
          const res = exec();
          if (res.error) return { data: null, error: res.error };
          const arr = Array.isArray(res.data) ? res.data : [res.data];
          if (!arr.length || !arr[0]) return { data: null, error: { message: "Not found" } };
          return { data: arr[0], error: null };
        },
        async maybeSingle() {
          const res = exec();
          if (res.error) return { data: null, error: res.error };
          const arr = Array.isArray(res.data) ? res.data : [res.data];
          return { data: arr[0] ?? null, error: null };
        },
        then(resolve: (v: unknown) => void, reject?: (e: unknown) => void) {
          try {
            resolve(exec());
          } catch (e) {
            reject?.(e);
          }
        },
      };
      return chain;
    },
    async rpc(fn: string, args: Record<string, unknown>) {
      if (opts.onRpc) return opts.onRpc(fn, args);
      return { data: { ya_recibida: false, partidas: 1, movimientos: [] }, error: null };
    },
  };
}

// ===== Pruebas adicionales de la revisión (Claude): lógica post-recepción, usuario, cliente de servicio, POST ignora estado, filtro de organización y O1 =====
const ORG = "00000000-0000-4000-8000-000000000001";
const CID = "c1000000-0000-4000-8000-000000000010";

function escenarioRecepcion(cotEstado: string, rpcRes = { ya_recibida: false, partidas: 1, movimientos: [] as unknown[] }) {
  const tablas: Record<string, Array<Record<string, unknown>>> = {
    compras_proveedor: [{ id: CID, organizacion_id: ORG, folio: "OC-00001", estado: "Pendiente", cotizacion_id: "cot-1" }],
    cotizaciones: [{ id: "cot-1", organizacion_id: ORG, estado_produccion: cotEstado }],
  };
  const svc = crearMockDb(tablas, {
    onRpc: (_fn, args) => {
      (svc as any).args = args;
      tablas.compras_proveedor[0].estado = "Recibida";
      return { data: rpcRes, error: null };
    },
  });
  const user = crearMockDb(tablas, { onRpc: () => { throw new Error("la recepción debe usar el cliente de servicio, no el del usuario"); } });
  return { tablas, svc, user };
}

Deno.test("R-C1: recepción con cotización sin faltantes pasa a 'Listo para producción' y registra el evento", async () => {
  const e = escenarioRecepcion("Compra en curso");
  const eventos: Array<Record<string, unknown>> = [];
  await actualizarCompraProveedorMotor(e.user as any, e.svc as any, ORG, "u-1", CID, { estado: "Recibida" }, {
    calcularRequisicion: async () => [{ estado: "ok", faltante: 0 }],
    registrarEvento: async (_sb, ev) => { eventos.push(ev); },
  });
  assertEquals(e.tablas.cotizaciones[0].estado_produccion, "Listo para producción");
  assertEquals(eventos.length, 1);
  assertEquals(eventos[0].usuario_id, "u-1");
  assertEquals((e.svc as any).args.p_usuario, "u-1");
});

Deno.test("R-C2: con faltantes, o con una receta sin configurar, o ya recibida, NO cambia el estado de producción", async () => {
  for (const [faltantes, rpcRes] of [
    [[{ estado: "ok", faltante: 3 }], { ya_recibida: false, partidas: 1, movimientos: [] }],
    [[{ estado: "sin_receta" }, { estado: "ok", faltante: 0 }], { ya_recibida: false, partidas: 1, movimientos: [] }],
    [[{ estado: "ok", faltante: 0 }], { ya_recibida: true, partidas: 0, movimientos: [] }],
  ] as const) {
    const e = escenarioRecepcion("Compra en curso", rpcRes as any);
    let llamadas = 0;
    await actualizarCompraProveedorMotor(e.user as any, e.svc as any, ORG, "u-1", CID, { estado: "Recibida" }, {
      calcularRequisicion: async () => { llamadas++; return faltantes as any; },
    });
    assertEquals(e.tablas.cotizaciones[0].estado_produccion, "Compra en curso");
    if ((rpcRes as any).ya_recibida) assertEquals(llamadas, 0);
  }
});

Deno.test("R-C3: POST ignora un 'estado' enviado por el cliente y siempre crea Pendiente", async () => {
  const tablas: Record<string, Array<Record<string, unknown>>> = {
    productos: [{ id: "p1", organizacion_id: ORG }],
    compras_proveedor: [],
    compra_items: [],
  };
  const db = crearMockDb(tablas);
  const compra = await crearCompraProveedorMotor(db as any, ORG, "u-1", {
    estado: "Recibida",
    items: [{ material_id: "p1", cantidad: 2, costo_unitario: 0 }],
  });
  assertEquals(compra.estado, "Pendiente");
  assertEquals(tablas.compra_items.length, 1);
});

Deno.test("R-C4: el PUT no recepcional filtra por organización al actualizar", async () => {
  const tablas: Record<string, Array<Record<string, unknown>>> = {
    compras_proveedor: [{ id: CID, organizacion_id: ORG, folio: "OC-00001", estado: "Pendiente", cotizacion_id: null }],
  };
  const db = crearMockDb(tablas);
  await actualizarCompraProveedorMotor(db as any, db as any, ORG, "u-1", CID, { fecha_vencimiento_pago: "2026-12-31" });
  const upd = db.updatedLog.find((u) => u.table === "compras_proveedor");
  assertEquals(upd?.filters.organizacion_id, ORG);
});

Deno.test("R-C5 (O1): carrera recibir vs cancelar -> UPDATE condicional rechaza con 409 sin pisar 'Recibida'", async () => {
  // Caso 1: otra petición recibe la compra entre la lectura previa y el UPDATE de Cancelada
  const tablasCarrera: Record<string, Array<Record<string, unknown>>> = {
    compras_proveedor: [{ id: CID, organizacion_id: ORG, folio: "OC-00001", estado: "Pendiente", cotizacion_id: null }],
  };
  const dbCarrera = crearMockDb(tablasCarrera, {
    onBeforeUpdate: (table) => {
      if (table === "compras_proveedor") {
        // Simular que la otra sesión acaba de marcarla Recibida
        tablasCarrera.compras_proveedor[0].estado = "Recibida";
      }
    },
  });

  const err = await assertRejects(
    () => actualizarCompraProveedorMotor(dbCarrera as any, dbCarrera as any, ORG, "u-1", CID, { estado: "Cancelada" }),
    ComprasRecepcionError,
    "La compra cambió de estado; recarga e inténtalo de nuevo",
  );
  assertEquals(err.status, 409);
  assertEquals(tablasCarrera.compras_proveedor[0].estado, "Recibida");
  const updLog = dbCarrera.updatedLog.find((u) => u.table === "compras_proveedor");
  assertEquals(updLog?.filters.estado, "Pendiente");

  // Caso 2: sin carrera, Pendiente -> Cancelada funciona normal
  const tablasOk: Record<string, Array<Record<string, unknown>>> = {
    compras_proveedor: [{ id: CID, organizacion_id: ORG, folio: "OC-00001", estado: "Pendiente", cotizacion_id: null }],
  };
  const dbOk = crearMockDb(tablasOk);
  const res = await actualizarCompraProveedorMotor(dbOk as any, dbOk as any, ORG, "u-1", CID, { estado: "Cancelada" });
  assertEquals(res.estado, "Cancelada");
});
