import { assertEquals, assertRejects } from "jsr:@std/assert";
import {
  ComprasRecepcionError,
  actualizarCompraProveedorMotor,
  crearCompraProveedorMotor,
  mapearErrorRpcCompra,
  sanitizarCamposCompraUpdate,
  validarPartidasCompraNueva,
  validarTransicionEstadoCompra,
} from "./compras_recepcion.ts";

function crearMockDb(
  tablas: Record<string, Array<Record<string, unknown>>>,
  opts: {
    onRpc?: (fn: string, args: Record<string, unknown>) => { data?: unknown; error?: unknown };
    failInsertTable?: string;
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

Deno.test("mapearErrorRpcCompra: mapea todos los códigos SQL a HTTP y mensaje en español", () => {
  assertEquals(mapearErrorRpcCompra({ message: "compra_no_encontrada: x" }).status, 404);
  assertEquals(mapearErrorRpcCompra({ message: "compra_cancelada: x" }).status, 409);
  assertEquals(mapearErrorRpcCompra({ message: "compra_sin_partidas: x" }).status, 409);
  assertEquals(mapearErrorRpcCompra({ message: "producto_no_encontrado: x" }).status, 409);
  assertEquals(mapearErrorRpcCompra({ message: "cantidad_no_entera: 2.5" }).status, 400);
  assertEquals(mapearErrorRpcCompra({ message: "cantidad_invalida: 0" }).status, 400);
  assertEquals(mapearErrorRpcCompra({ code: "22P02", message: "invalid input" }).status, 400);
  assertEquals(mapearErrorRpcCompra({ code: "40P01", message: "deadlock" }).status, 409);
  assertEquals(mapearErrorRpcCompra({ code: "40001", message: "serialization" }).status, 409);
  assertEquals(mapearErrorRpcCompra({ code: "42883", message: "function does not exist" }).status, 503);
  const unk = mapearErrorRpcCompra({ message: "P0001 raw secret detail" });
  assertEquals(unk.status, 500);
  assertEquals(unk.message.includes("P0001"), false);
});

Deno.test("sanitizarCamposCompraUpdate y validarTransicionEstadoCompra", () => {
  const clean = sanitizarCamposCompraUpdate({
    id: "hack",
    organizacion_id: "otra-org",
    folio: "OC-HACK",
    created_at: "2020-01-01",
    estado: "Recibida",
    proveedor_id: "prov-1",
    fecha: "2026-11-25",
    fecha_vencimiento_pago: "2026-12-25",
  });
  assertEquals(Object.keys(clean).sort(), ["estado", "fecha", "fecha_vencimiento_pago", "proveedor_id"]);

  // Transiciones válidas
  validarTransicionEstadoCompra("Pendiente", "Recibida");
  validarTransicionEstadoCompra("Pendiente", "Cancelada");
  validarTransicionEstadoCompra("Recibida", "Recibida");

  // Transiciones prohibidas
  let e1: unknown;
  try { validarTransicionEstadoCompra("Recibida", "Pendiente"); } catch (e) { e1 = e; }
  assertEquals((e1 as ComprasRecepcionError).status, 409);

  let e2: unknown;
  try { validarTransicionEstadoCompra("Recibida", "Cancelada"); } catch (e) { e2 = e; }
  assertEquals((e2 as ComprasRecepcionError).status, 409);

  let e3: unknown;
  try { validarTransicionEstadoCompra("Cancelada", "Recibida"); } catch (e) { e3 = e; }
  assertEquals((e3 as ComprasRecepcionError).status, 409);

  let e4: unknown;
  try { validarTransicionEstadoCompra("Pendiente", "Inventado"); } catch (e) { e4 = e; }
  assertEquals((e4 as ComprasRecepcionError).status, 400);
});

Deno.test("crearCompraProveedorMotor: valida partidas, org de productos y evita compra fantasma si falla compra_items", async () => {
  const orgA = "00000000-0000-4000-8000-000000000001";
  const orgB = "00000000-0000-4000-8000-000000000002";

  // Partida con cantidad <= 0 o costo < 0
  let eCant: unknown;
  try { validarPartidasCompraNueva([{ material_id: "p1", cantidad: 0, costo_unitario: 10 }]); } catch (e) { eCant = e; }
  assertEquals((eCant as ComprasRecepcionError).status, 400);

  let eCosto: unknown;
  try { validarPartidasCompraNueva([{ material_id: "p1", cantidad: 2, costo_unitario: -1 }]); } catch (e) { eCosto = e; }
  assertEquals((eCosto as ComprasRecepcionError).status, 400);

  // Producto de otra organización rechazado antes de insertar compra
  const dbAjeno = crearMockDb({
    productos: [{ id: "p-b", organizacion_id: orgB }],
    compras_proveedor: [],
    compra_items: [],
  });
  await assertRejects(
    () =>
      crearCompraProveedorMotor(dbAjeno as any, orgA, "u1", {
        items: [{ material_id: "p-b", cantidad: 3, costo_unitario: 10 }],
      }),
    ComprasRecepcionError,
    "otra organización",
  );

  // Si falla el insert de compra_items, elimina la compra recién creada (cero compras fantasma)
  const tablasFantasma: Record<string, Array<Record<string, unknown>>> = {
    productos: [{ id: "p-a", organizacion_id: orgA }],
    compras_proveedor: [],
    compra_items: [],
  };
  const dbFailItems = crearMockDb(tablasFantasma, { failInsertTable: "compra_items" });
  await assertRejects(
    () =>
      crearCompraProveedorMotor(dbFailItems as any, orgA, "u1", {
        items: [{ material_id: "p-a", cantidad: 3, costo_unitario: 10 }],
      }),
    ComprasRecepcionError,
    "no fue creada",
  );
  assertEquals(tablasFantasma.compras_proveedor.length, 0);
  assertEquals(dbFailItems.deletedLog.length, 1);
  assertEquals(dbFailItems.deletedLog[0].filters.organizacion_id, orgA);
});

Deno.test("actualizarCompraProveedorMotor: aislamiento, lista blanca, RPC atómico, error RPC, aviso requisición", async () => {
  const orgA = "00000000-0000-4000-8000-000000000001";
  const orgB = "00000000-0000-4000-8000-000000000002";
  const cid = "c1000000-0000-4000-8000-000000000010";

  // UUID inválido -> 400
  await assertRejects(
    () => actualizarCompraProveedorMotor(crearMockDb({}) as any, crearMockDb({}) as any, orgA, null, "no-uuid", { estado: "Recibida" }),
    ComprasRecepcionError,
    "no es válido",
  );

  // Compra de otra org -> 404
  const dbOrg = crearMockDb({
    compras_proveedor: [{ id: cid, organizacion_id: orgA, folio: "OC-00001", estado: "Pendiente", cotizacion_id: null }],
  });
  await assertRejects(
    () => actualizarCompraProveedorMotor(dbOrg as any, dbOrg as any, orgB, null, cid, { estado: "Recibida" }),
    ComprasRecepcionError,
    "otra organización",
  );

  // Si RPC falla -> lanza error mapeado (409) y NO devuelve 200
  const dbRpcErr = crearMockDb(
    { compras_proveedor: [{ id: cid, organizacion_id: orgA, folio: "OC-00001", estado: "Pendiente", cotizacion_id: null }] },
    { onRpc: () => ({ data: null, error: { message: "compra_sin_partidas: sin partidas" } }) },
  );
  await assertRejects(
    () => actualizarCompraProveedorMotor(dbRpcErr as any, dbRpcErr as any, orgA, "u1", cid, { estado: "Recibida" }),
    ComprasRecepcionError,
    "no tiene partidas",
  );

  // Intento de alterar organizacion_id/folio ignorado por lista blanca; fallo en calcularRequisicion devuelve aviso (no 500)
  const tablasOk: Record<string, Array<Record<string, unknown>>> = {
    compras_proveedor: [{ id: cid, organizacion_id: orgA, folio: "OC-00001", estado: "Pendiente", cotizacion_id: "cot-1" }],
  };
  let rpcArgs: Record<string, unknown> | null = null;
  const dbOk = crearMockDb(tablasOk, {
    onRpc: (fn, args) => {
      assertEquals(fn, "recibir_compra_proveedor");
      rpcArgs = args;
      tablasOk.compras_proveedor[0].estado = "Recibida";
      return { data: { ya_recibida: false, partidas: 2, movimientos: [] }, error: null };
    },
  });
  const res = await actualizarCompraProveedorMotor(
    dbOk as any,
    dbOk as any,
    orgA,
    "u1",
    cid,
    { estado: "Recibida", organizacion_id: orgB, folio: "OC-HACK", fecha: "2026-11-25" },
    {
      calcularRequisicion: async () => {
        throw new Error("fallo red requisicion");
      },
    },
  );
  assertEquals(rpcArgs?.p_org, orgA);
  assertEquals(rpcArgs?.p_compra_id, cid);
  assertEquals(res.estado, "Recibida");
  assertEquals(res.organizacion_id, orgA);
  assertEquals(res.folio, "OC-00001");
  assertEquals(typeof res.aviso, "string");
  assertEquals(String(res.aviso).includes("fallo red requisicion"), true);

  // Transición Recibida -> Pendiente rechazada 409
  await assertRejects(
    () => actualizarCompraProveedorMotor(dbOk as any, dbOk as any, orgA, "u1", cid, { estado: "Pendiente" }),
    ComprasRecepcionError,
    "ya recibida",
  );
});
