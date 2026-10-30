// @ts-nocheck
import { assertEquals, assertRejects, assert } from "https://deno.land/std@0.192.0/testing/asserts.ts";
import {
  obtenerResumenCxp,
  listarFacturas,
  crearFactura,
  actualizarFactura,
  cancelarFactura,
  registrarPago,
  anularPago,
  guardarTipoCambio,
  obtenerCreditoProveedor,
  actualizarCreditoProveedor,
  guardarEstadoCuentaProveedor,
  obtenerConciliacionProveedor,
} from "./cuentas_por_pagar.ts";

function createFakeClient(opts: {
  tables?: Record<string, any[]>;
  rpcHandlers?: Record<string, (args: any) => Promise<any> | any>;
}) {
  const tables: Record<string, any[]> = opts.tables || {};
  const rpcHandlers = opts.rpcHandlers || {};

  return {
    from(tableName: string) {
      const filters: Array<{ col: string; op: string; val: any }> = [];
      let orderCol: string | null = null;
      let orderAsc = true;
      let limitCount: number | null = null;

      function getFilteredRows() {
        let res = (tables[tableName] || []).map((r) => ({ ...r }));
        for (const f of filters) {
          if (f.op === "eq") res = res.filter((r) => r[f.col] === f.val);
          if (f.op === "neq") res = res.filter((r) => r[f.col] !== f.val);
          if (f.op === "is") res = res.filter((r) => r[f.col] === f.val);
          if (f.op === "in") res = res.filter((r) => (f.val || []).includes(r[f.col]));
          if (f.op === "gte") res = res.filter((r) => r[f.col] >= f.val);
          if (f.op === "lte") res = res.filter((r) => r[f.col] <= f.val);
        }
        if (orderCol) {
          res.sort((a, b) => {
            const va = a[orderCol!] ?? "";
            const vb = b[orderCol!] ?? "";
            return orderAsc ? (va > vb ? 1 : -1) : (va < vb ? 1 : -1);
          });
        }
        if (limitCount !== null) {
          res = res.slice(0, limitCount);
        }
        return res;
      }

      const builder: any = {
        select(_fields = "*") {
          return builder;
        },
        eq(col: string, val: any) {
          filters.push({ col, op: "eq", val });
          return builder;
        },
        neq(col: string, val: any) {
          filters.push({ col, op: "neq", val });
          return builder;
        },
        is(col: string, val: any) {
          filters.push({ col, op: "is", val });
          return builder;
        },
        in(col: string, val: any[]) {
          filters.push({ col, op: "in", val });
          return builder;
        },
        gte(col: string, val: any) {
          filters.push({ col, op: "gte", val });
          return builder;
        },
        lte(col: string, val: any) {
          filters.push({ col, op: "lte", val });
          return builder;
        },
        order(col: string, options: { ascending?: boolean } = {}) {
          orderCol = col;
          orderAsc = options.ascending ?? true;
          return builder;
        },
        limit(count: number) {
          limitCount = count;
          return builder;
        },
        async single() {
          const rows = getFilteredRows();
          if (rows.length === 0) {
            return { data: null, error: { message: "Row not found", code: "PGRST116" } };
          }
          return { data: rows[0], error: null };
        },
        then(resolve: any, reject: any) {
          const rows = getFilteredRows();
          return Promise.resolve({ data: rows, error: null }).then(resolve, reject);
        },
        insert(payload: any) {
          const table = tables[tableName] || (tables[tableName] = []);
          const rows = Array.isArray(payload) ? payload : [payload];
          const inserted: any[] = [];
          for (const r of rows) {
            const newRow = { id: r.id || `gen-${Math.random()}`, ...r };
            table.push(newRow);
            inserted.push(newRow);
          }
          return {
            select() {
              return {
                single() {
                  return Promise.resolve({ data: inserted[0], error: null });
                },
                then(resolve: any, reject: any) {
                  return Promise.resolve({ data: inserted, error: null }).then(resolve, reject);
                },
              };
            },
            then(resolve: any, reject: any) {
              return Promise.resolve({ data: inserted, error: null }).then(resolve, reject);
            },
          };
        },
        update(payload: any) {
          return {
            eq(col: string, val: any) {
              filters.push({ col, op: "eq", val });
              return {
                eq(col2: string, val2: any) {
                  filters.push({ col: col2, op: "eq", val: val2 });
                  return this;
                },
                select() {
                  return {
                    single() {
                      const table = tables[tableName] || [];
                      let updatedRow: any = null;
                      for (const r of table) {
                        let match = true;
                        for (const f of filters) {
                          if (r[f.col] !== f.val) match = false;
                        }
                        if (match) {
                          Object.assign(r, payload);
                          updatedRow = { ...r };
                        }
                      }
                      return Promise.resolve({ data: updatedRow, error: null });
                    },
                  };
                },
                then(resolve: any, reject: any) {
                  return Promise.resolve({ data: null, error: null }).then(resolve, reject);
                },
              };
            },
          };
        },
        upsert(payload: any, _options?: any) {
          const table = tables[tableName] || (tables[tableName] = []);
          // Busca si ya existe
          const idx = table.findIndex((r) => {
            if (tableName === "tipos_cambio") {
              return r.organizacion_id === payload.organizacion_id && r.fecha === payload.fecha && r.moneda === payload.moneda;
            }
            if (tableName === "estados_cuenta_proveedor") {
              return r.organizacion_id === payload.organizacion_id && r.proveedor_id === payload.proveedor_id && r.fecha === payload.fecha && r.moneda === payload.moneda;
            }
            return false;
          });
          let rowResult: any;
          if (idx >= 0) {
            Object.assign(table[idx], payload);
            rowResult = table[idx];
          } else {
            rowResult = { id: `gen-${Math.random()}`, ...payload };
            table.push(rowResult);
          }
          return {
            select() {
              return {
                single() {
                  return Promise.resolve({ data: rowResult, error: null });
                },
              };
            },
          };
        },
      };

      return builder;
    },

    rpc(fnName: string, args: any) {
      if (rpcHandlers[fnName]) {
        return Promise.resolve(rpcHandlers[fnName](args));
      }
      return Promise.resolve({ data: { exito: true }, error: null });
    },
  };
}

// ── PRUEBAS DEL MOTOR ──

const ORG_A = "11111111-1111-1111-1111-111111111111";
const ORG_B = "22222222-2222-2222-2222-222222222222";
const PROV_A = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa";
const PROV_B = "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb";

Deno.test("motor/cuentas_por_pagar - 1. Aislamiento por organización y 404 al consultar proveedor ajeno", async () => {
  const fake = createFakeClient({
    tables: {
      proveedores: [
        { id: PROV_A, organizacion_id: ORG_A, nombre: "Proveedor A" },
        { id: PROV_B, organizacion_id: ORG_B, nombre: "Proveedor B" },
      ],
    },
  });

  // Consultar crédito con org A para proveedor de org B -> 404
  await assertRejects(
    async () => {
      await obtenerCreditoProveedor(fake, ORG_A, PROV_B);
    },
    Error,
    "Proveedor no encontrado o pertenece a otra organización"
  );

  // Crear factura en org A con proveedor de org B -> 404
  await assertRejects(
    async () => {
      await crearFactura(fake, ORG_A, {
        proveedor_id: PROV_B,
        folio: "F-101",
        fecha_emision: "2026-10-01",
        moneda: "MXN",
        importe: 1000,
      });
    },
    Error,
    "El proveedor no existe o pertenece a otra organización"
  );
});

Deno.test("motor/cuentas_por_pagar - 2. Validación de campos y fecha inválida (2026-13-45) -> 400", async () => {
  const fake = createFakeClient({
    tables: {
      proveedores: [{ id: PROV_A, organizacion_id: ORG_A, nombre: "Proveedor A" }],
    },
  });

  await assertRejects(
    async () => {
      await crearFactura(fake, ORG_A, {
        proveedor_id: PROV_A,
        folio: "F-102",
        fecha_emision: "2026-13-45",
        moneda: "MXN",
        importe: 500,
      });
    },
    Error,
    "Fecha de emisión inválida"
  );

  await assertRejects(
    async () => {
      await crearFactura(fake, ORG_A, {
        proveedor_id: PROV_A,
        folio: "   ",
        fecha_emision: "2026-10-15",
        moneda: "MXN",
        importe: 500,
      });
    },
    Error,
    "El folio de la factura es obligatorio"
  );
});

Deno.test("motor/cuentas_por_pagar - 3. Duplicado (proveedor, sucursal, folio) -> 409", async () => {
  const fake = createFakeClient({
    tables: {
      proveedores: [{ id: PROV_A, organizacion_id: ORG_A, nombre: "CADECO" }],
      facturas_proveedor: [
        {
          id: "f-existente",
          organizacion_id: ORG_A,
          proveedor_id: PROV_A,
          sucursal: "Suc 114",
          folio: "21644",
          importe: 2000,
        },
      ],
    },
  });

  await assertRejects(
    async () => {
      await crearFactura(fake, ORG_A, {
        proveedor_id: PROV_A,
        sucursal: "Suc 114",
        folio: "21644",
        fecha_emision: "2026-10-10",
        moneda: "USD",
        importe: 2000,
      });
    },
    Error,
    "Ya existe una factura con folio '21644' (sucursal Suc 114)"
  );
});

Deno.test("motor/cuentas_por_pagar - 4. PUT con pagos intentando cambiar moneda o importe -> 409", async () => {
  const fake = createFakeClient({
    tables: {
      facturas_proveedor: [
        {
          id: "fact-1",
          organizacion_id: ORG_A,
          proveedor_id: PROV_A,
          folio: "F-1",
          moneda: "USD",
          importe: 1000,
          pagos: [{ id: "p-1", monto: 400, anulado: false }],
        },
      ],
    },
  });

  await assertRejects(
    async () => {
      await actualizarFactura(fake, ORG_A, "fact-1", {
        moneda: "MXN",
      });
    },
    Error,
    "No se puede cambiar la moneda de una factura que ya tiene pagos registrados"
  );

  await assertRejects(
    async () => {
      await actualizarFactura(fake, ORG_A, "fact-1", {
        importe: 800,
      });
    },
    Error,
    "No se puede cambiar el importe de una factura que ya tiene pagos registrados"
  );
});

Deno.test("motor/cuentas_por_pagar - 5. Cancelar factura con pagos activos -> 409", async () => {
  const fake = createFakeClient({
    tables: {
      facturas_proveedor: [
        {
          id: "fact-1",
          organizacion_id: ORG_A,
          proveedor_id: PROV_A,
          folio: "F-1",
          pagos: [{ id: "p-1", monto: 200, anulado: false }],
        },
      ],
    },
  });

  await assertRejects(
    async () => {
      await cancelarFactura(fake, ORG_A, "fact-1");
    },
    Error,
    "No se puede cancelar una factura que tiene pagos registrados"
  );
});

Deno.test("motor/cuentas_por_pagar - 6. Registrar pago: traduce excede_saldo -> 409 y tipo_cambio_requerido -> 400", async () => {
  const fake = createFakeClient({
    rpcHandlers: {
      registrar_pago_factura(args: any) {
        if (!args.p_tipo_cambio && args.p_monto > 500) {
          return { data: { exito: false, error: "tipo_cambio_requerido", mensaje: "El tipo de cambio es obligatorio" } };
        }
        if (args.p_monto > 1000) {
          return { data: { exito: false, error: "excede_saldo", mensaje: "Excede el saldo" } };
        }
        return { data: { exito: true, pago_id: "pago-nuevo", saldo_restante: 1000 - args.p_monto } };
      },
    },
  });

  // USD sin tipo de cambio -> 400
  const errTC = await assertRejects(
    async () => {
      await registrarPago(fake, ORG_A, "fact-1", {
        fecha_pago: "2026-10-20",
        monto: 600,
        tipo_cambio: null,
      });
    },
    Error,
    "El tipo de cambio es obligatorio"
  );
  assertEquals(errTC.status, 400);

  // Pago que excede saldo -> 409
  const errExcede = await assertRejects(
    async () => {
      await registrarPago(fake, ORG_A, "fact-1", {
        fecha_pago: "2026-10-20",
        monto: 1500,
        tipo_cambio: 19.50,
      });
    },
    Error,
    "Excede el saldo"
  );
  assertEquals(errExcede.status, 409);
});

Deno.test("motor/cuentas_por_pagar - 7. Resumen sin tipo de cambio devuelve null en pesos para USD", async () => {
  const fake = createFakeClient({
    tables: {
      tipos_cambio: [], // No hay tipo de cambio registrado
      facturas_proveedor: [
        {
          id: "fact-usd",
          organizacion_id: ORG_A,
          proveedor_id: PROV_A,
          folio: "F-USD",
          moneda: "USD",
          importe: 1000,
          fecha_emision: "2026-10-01",
          fecha_vencimiento: "2026-10-31",
          estado: "abierta",
          pagos: [],
        },
        {
          id: "fact-mxn",
          organizacion_id: ORG_A,
          proveedor_id: PROV_A,
          folio: "F-MXN",
          moneda: "MXN",
          importe: 5000,
          fecha_emision: "2026-10-01",
          fecha_vencimiento: "2026-10-15",
          estado: "abierta",
          pagos: [],
        },
      ],
      proveedores: [{ id: PROV_A, organizacion_id: ORG_A, nombre: "Proveedor Mixto" }],
    },
  });

  const res = await obtenerResumenCxp(fake, ORG_A, "2026-10-30", null);

  assertEquals(res.tc, null);
  assertEquals(res.resumenGeneral.saldoUSD, 1000);
  assertEquals(res.resumenGeneral.saldoMXN, 5000);
  assertEquals(res.resumenGeneral.equivalenteUSDEnPesos, null);
  assertEquals(res.resumenGeneral.totalEnPesos, null);
  assertEquals(res.resumenGeneral.antiguedad.pesos, null);
});
