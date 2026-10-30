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
  listarPagos,
  guardarTipoCambio,
  obtenerCreditoProveedor,
  actualizarCreditoProveedor,
  guardarEstadoCuentaProveedor,
  obtenerConciliacionProveedor,
  formatearErrorRespuesta,
} from "./cuentas_por_pagar.ts";

function createFakeClient(opts: {
  tables?: Record<string, any[]>;
  rpcHandlers?: Record<string, (args: any) => Promise<any> | any>;
  onRpc?: (fnName: string, args: any) => void;
}) {
  const tables: Record<string, any[]> = opts.tables || {};
  const rpcHandlers = opts.rpcHandlers || {};
  const onRpc = opts.onRpc;

  return {
    from(tableName: string) {
      const filters: Array<{ col: string; op: string; val: any }> = [];
      let orderCol: string | null = null;
      let orderAsc = true;
      let limitCount: number | null = null;
      let rangeFrom: number | null = null;
      let rangeTo: number | null = null;

      function getFilteredRows() {
        let res = (tables[tableName] || []).map((r) => ({ ...r }));
        if (
          tableName === "v_facturas_proveedor_saldo" &&
          (!tables[tableName] || tables[tableName].length === 0) &&
          tables["facturas_proveedor"]
        ) {
          res = tables["facturas_proveedor"].map((f) => {
            const pagos = f.pagos || [];
            const pagado = pagos
              .filter((p: any) => !p.anulado)
              .reduce((acc: number, p: any) => acc + Number(p.monto), 0);
            const saldo = Math.round((Number(f.importe) - pagado) * 100) / 100;
            const prov = (tables["proveedores"] || []).find((p) => p.id === f.proveedor_id);
            return {
              ...f,
              pagado,
              saldo,
              proveedor: prov || null,
            };
          });
        }
        for (const f of filters) {
          if (f.op === "eq") res = res.filter((r) => r[f.col] === f.val);
          if (f.op === "neq") res = res.filter((r) => r[f.col] !== f.val);
          if (f.op === "is") res = res.filter((r) => r[f.col] === f.val);
          if (f.op === "in") res = res.filter((r) => (f.val || []).includes(r[f.col]));
          if (f.op === "gte") res = res.filter((r) => r[f.col] >= f.val);
          if (f.op === "lte") res = res.filter((r) => r[f.col] <= f.val);
          if (f.op === "gt") res = res.filter((r) => Number(r[f.col]) > Number(f.val));
        }
        if (orderCol) {
          res.sort((a, b) => {
            const va = a[orderCol!] ?? "";
            const vb = b[orderCol!] ?? "";
            return orderAsc ? (va > vb ? 1 : -1) : (va < vb ? 1 : -1);
          });
        }
        if (rangeFrom !== null && rangeTo !== null) {
          res = res.slice(rangeFrom, rangeTo + 1);
        } else if (limitCount !== null) {
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
        gt(col: string, val: any) {
          filters.push({ col, op: "gt", val });
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
        range(from: number, to: number) {
          rangeFrom = from;
          rangeTo = to;
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
      if (onRpc) onRpc(fnName, args);
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

Deno.test("motor/cuentas_por_pagar - 8. Seguridad RPC: registrarPago y anularPago llaman exclusivamente a serviceClient, cliente de usuario es rechazado", async () => {
  let userRpcLlamadas = 0;
  let serviceRpcLlamadas = 0;

  const userClient = {
    ...createFakeClient({}),
    rpc(_fnName: string, _args: any) {
      userRpcLlamadas++;
      return Promise.resolve({
        data: null,
        error: { message: "permission denied for function " + _fnName, code: "42501" },
      });
    },
  };

  const serviceClient = {
    ...createFakeClient({
      rpcHandlers: {
        registrar_pago_factura(args: any) {
          return { data: { exito: true, pago_id: "pago-service-1", saldo_restante: 500 } };
        },
        anular_pago_factura(args: any) {
          return { data: { exito: true, pago_id: args.p_pago_id, factura_id: "fact-1", saldo_restante: 1000 } };
        },
      },
      onRpc: () => {
        serviceRpcLlamadas++;
      },
    }),
  };

  // 1. Invocar con userClient debe fallar con permission denied
  await assertRejects(
    async () => {
      await registrarPago(userClient, ORG_A, "fact-1", {
        fecha_pago: "2026-10-30",
        monto: 100,
      });
    },
    Error,
    "permission denied"
  );
  assertEquals(userRpcLlamadas, 1);
  assertEquals(serviceRpcLlamadas, 0);

  await assertRejects(
    async () => {
      await anularPago(userClient, ORG_A, "pago-1", "Error de captura");
    },
    Error,
    "permission denied"
  );
  assertEquals(userRpcLlamadas, 2);
  assertEquals(serviceRpcLlamadas, 0);

  // 2. Invocar con serviceClient debe completarse con éxito
  const resPago = await registrarPago(serviceClient, ORG_A, "fact-1", {
    fecha_pago: "2026-10-30",
    monto: 100,
  });
  assertEquals(resPago.exito, true);
  assertEquals(resPago.pago_id, "pago-service-1");
  assertEquals(serviceRpcLlamadas, 1);
  assertEquals(userRpcLlamadas, 2); // no aumentó

  const resAnular = await anularPago(serviceClient, ORG_A, "pago-service-1", "Aclaración bancaria");
  assertEquals(resAnular.exito, true);
  assertEquals(serviceRpcLlamadas, 2);
  assertEquals(userRpcLlamadas, 2); // sigue en 2, nunca llamado por serviceClient
});

Deno.test("motor/cuentas_por_pagar - 9. Validaciones de montos inválidos, finitud y enteros (0.004, Infinity, NaN, 'abc', dias_credito=30.5) -> 400", async () => {
  const fake = createFakeClient({
    tables: {
      proveedores: [{ id: PROV_A, organizacion_id: ORG_A, nombre: "Proveedor Validaciones" }],
      facturas_proveedor: [
        {
          id: "fact-val-1",
          organizacion_id: ORG_A,
          proveedor_id: PROV_A,
          folio: "F-VAL-1",
          moneda: "MXN",
          importe: 500,
          pagos: [],
        },
      ],
    },
  });

  // A. Monto de pago < 0.01 (0.004) -> 400
  const err004 = await assertRejects(
    async () => {
      await registrarPago(fake, ORG_A, "fact-val-1", {
        fecha_pago: "2026-10-30",
        monto: 0.004,
      });
    },
    Error,
    "El monto del pago debe ser un número finito mayor o igual a 0.01"
  );
  assertEquals(err004.status, 400);

  // B. Monto de pago Infinity -> 400
  const errInf = await assertRejects(
    async () => {
      await registrarPago(fake, ORG_A, "fact-val-1", {
        fecha_pago: "2026-10-30",
        monto: Infinity,
      });
    },
    Error,
    "El monto del pago debe ser un número finito mayor o igual a 0.01"
  );
  assertEquals(errInf.status, 400);

  // C. Monto de pago NaN -> 400
  const errNaN = await assertRejects(
    async () => {
      await registrarPago(fake, ORG_A, "fact-val-1", {
        fecha_pago: "2026-10-30",
        monto: NaN,
      });
    },
    Error,
    "El monto del pago debe ser un número finito mayor o igual a 0.01"
  );
  assertEquals(errNaN.status, 400);

  // D. Monto de pago "abc" -> 400
  const errAbc = await assertRejects(
    async () => {
      await registrarPago(fake, ORG_A, "fact-val-1", {
        fecha_pago: "2026-10-30",
        monto: "abc" as any,
      });
    },
    Error,
    "El monto del pago debe ser un número finito mayor o igual a 0.01"
  );
  assertEquals(errAbc.status, 400);

  // E. dias_credito = 30.5 en crearFactura -> 400
  const errDiasCrear = await assertRejects(
    async () => {
      await crearFactura(fake, ORG_A, {
        proveedor_id: PROV_A,
        folio: "F-VAL-2",
        fecha_emision: "2026-10-30",
        moneda: "MXN",
        importe: 100,
        dias_credito: 30.5,
      });
    },
    Error,
    "Los días de crédito deben ser un entero mayor o igual a 0"
  );
  assertEquals(errDiasCrear.status, 400);

  // F. dias_credito = 30.5 en actualizarFactura -> 400
  const errDiasAct = await assertRejects(
    async () => {
      await actualizarFactura(fake, ORG_A, "fact-val-1", {
        dias_credito: 30.5,
      });
    },
    Error,
    "Los días de crédito deben ser un entero mayor o igual a 0"
  );
  assertEquals(errDiasAct.status, 400);

  // G. dias_credito = 30.5 en actualizarCreditoProveedor -> 400
  const errDiasCred = await assertRejects(
    async () => {
      await actualizarCreditoProveedor(fake, ORG_A, PROV_A, {
        dias_credito: 30.5,
      });
    },
    Error,
    "dias_credito debe ser un entero >= 0"
  );
  assertEquals(errDiasCred.status, 400);

  // H. tipo_cambio finito > 0 (Infinity) en registrarPago -> 400
  const errTcInf = await assertRejects(
    async () => {
      await registrarPago(fake, ORG_A, "fact-val-1", {
        fecha_pago: "2026-10-30",
        monto: 100,
        tipo_cambio: Infinity,
      });
    },
    Error,
    "El tipo de cambio debe ser un número finito mayor a 0"
  );
  assertEquals(errTcInf.status, 400);

  // I. guardarTipoCambio con valor Infinity -> 400
  const errTcValInf = await assertRejects(
    async () => {
      await guardarTipoCambio(fake, ORG_A, {
        fecha: "2026-10-30",
        valor: Infinity,
      });
    },
    Error,
    "El valor del tipo de cambio debe ser un número finito mayor a 0"
  );
  assertEquals(errTcValInf.status, 400);

  // J. guardarEstadoCuentaProveedor con saldo NaN -> 400
  const errSaldoNaN = await assertRejects(
    async () => {
      await guardarEstadoCuentaProveedor(fake, ORG_A, PROV_A, {
        fecha: "2026-10-30",
        moneda: "MXN",
        saldo: NaN,
      });
    },
    Error,
    "El saldo debe ser un número finito"
  );
  assertEquals(errSaldoNaN.status, 400);
});

Deno.test("motor/cuentas_por_pagar - 10. formatearErrorRespuesta enmascara errores internos sin status en 500 y preserva errores 4xx", () => {
  // Error interno inesperado (ej. sintaxis SQL, desconexión de BD, permiso denegado en Postgres)
  const errInterno = new Error("syntax error at or near 'SELECT' in query_executor.c:1402");
  const res500 = formatearErrorRespuesta(errInterno);

  assertEquals(res500.status, 500);
  assertEquals(res500.body.error, "No se pudo completar la operación");
  assert(!JSON.stringify(res500.body).includes("syntax error"));
  assert(!JSON.stringify(res500.body).includes("query_executor"));

  // Error con status 400 (validación de negocio)
  const err400: any = new Error("El folio de la factura es obligatorio");
  err400.status = 400;
  const res400 = formatearErrorRespuesta(err400);
  assertEquals(res400.status, 400);
  assertEquals(res400.body.error, "El folio de la factura es obligatorio");

  // Error con status 409 (conflicto)
  const err409: any = new Error("Excede el saldo de la factura");
  err409.status = 409;
  const res409 = formatearErrorRespuesta(err409);
  assertEquals(res409.status, 409);
  assertEquals(res409.body.error, "Excede el saldo de la factura");
});

Deno.test("motor/cuentas_por_pagar - 11. Paginación y truncado: listarFacturas (500) y listarPagos (200) marcan truncado: true", async () => {
  // Crear 505 facturas
  const facturas505 = Array.from({ length: 505 }, (_, i) => ({
    id: `fact-${i + 1}`,
    organizacion_id: ORG_A,
    proveedor_id: PROV_A,
    folio: `F-${1000 + i}`,
    fecha_emision: "2026-10-01",
    fecha_vencimiento: "2026-10-31",
    moneda: "MXN",
    importe: 100,
    estado: "abierta",
    pagos: [],
  }));

  // Crear 205 pagos
  const pagos205 = Array.from({ length: 205 }, (_, i) => ({
    id: `pago-${i + 1}`,
    organizacion_id: ORG_A,
    factura_id: "fact-1",
    fecha_pago: "2026-10-15",
    monto: 10,
    anulado: false,
    factura: {
      id: "fact-1",
      folio: "F-1000",
      moneda: "MXN",
      proveedor: { id: PROV_A, nombre: "Proveedor A" },
    },
  }));

  const fake = createFakeClient({
    tables: {
      facturas_proveedor: facturas505,
      pagos_factura: pagos205,
    },
  });

  // listarFacturas con límite 500
  const resFacturas = await listarFacturas(fake, ORG_A, {}, 500);
  assertEquals(resFacturas.truncado, true);
  assertEquals(resFacturas.facturas.length, 500);

  // listarPagos con límite 200
  const resPagos = await listarPagos(fake, ORG_A, 200);
  assertEquals(resPagos.truncado, true);
  assertEquals(resPagos.pagos.length, 200);
});
