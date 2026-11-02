import { assertEquals, assertRejects } from "https://deno.land/std@0.208.0/assert/mod.ts";
import {
  guardarFacturaConPartidasMotor,
  previsualizarCFDIsMotor,
  importarCFDIsMotor,
  obtenerReporteFacturacion,
} from "./cuentas_por_pagar.ts";

const ORG_A = "11111111-1111-1111-1111-111111111111";
const PROV_A = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa";

function createFakeClient(initialState: any = {}) {
  const state: any = {
    proveedores: initialState.proveedores || [],
    facturas_proveedor: initialState.facturas_proveedor || [],
    facturas_proveedor_cfdi: initialState.facturas_proveedor_cfdi || [],
    factura_proveedor_partidas: initialState.factura_proveedor_partidas || [],
    tipos_cambio: initialState.tipos_cambio || [],
    v_facturas_proveedor_saldo: initialState.v_facturas_proveedor_saldo || [],
    rpcCalls: [],
  };

  return {
    state,
    from(table: string) {
      let filters: Array<(row: any) => boolean> = [];
      let selectFields = "*";
      let limitCount: number | null = null;
      let orderField: string | null = null;
      let orderAsc = true;

      const queryObj: any = {
        select(fields: string = "*") {
          selectFields = fields;
          return queryObj;
        },
        eq(col: string, val: any) {
          filters.push((row: any) => row[col] === val);
          return queryObj;
        },
        gte(col: string, val: any) {
          filters.push((row: any) => row[col] >= val);
          return queryObj;
        },
        lte(col: string, val: any) {
          filters.push((row: any) => row[col] <= val);
          return queryObj;
        },
        order(col: string, opts?: { ascending?: boolean }) {
          orderField = col;
          orderAsc = opts?.ascending !== false;
          return queryObj;
        },
        limit(n: number) {
          limitCount = n;
          return queryObj;
        },
        insert(records: any) {
          const arr = Array.isArray(records) ? records : [records];
          for (const rec of arr) {
            const row = { id: rec.id || `gen-${Math.random()}`, ...rec };
            if (!state[table]) state[table] = [];
            state[table].push(row);
          }
          return {
            select() {
              return {
                single() {
                  return Promise.resolve({ data: arr[0], error: null });
                },
              };
            },
            then(resolve: any) {
              return resolve({ data: arr, error: null });
            },
          };
        },
        then(resolve: any) {
          let rows = (state[table] || []).filter((r: any) => filters.every((fn) => fn(r)));
          if (orderField) {
            rows = [...rows].sort((a: any, b: any) => {
              if (a[orderField!] < b[orderField!]) return orderAsc ? -1 : 1;
              if (a[orderField!] > b[orderField!]) return orderAsc ? 1 : -1;
              return 0;
            });
          }
          if (limitCount !== null) {
            rows = rows.slice(0, limitCount);
          }
          return resolve({ data: rows, error: null });
        },
      };

      return queryObj;
    },
    rpc(fnName: string, params: any) {
      state.rpcCalls.push({ fnName, params });
      if (fnName === "guardar_factura_con_partidas") {
        return Promise.resolve({
          data: { ok: true, factura_id: "fact-nueva-123", importe: params.p_importe },
          error: null,
        });
      }
      return Promise.resolve({ data: null, error: null });
    },
  };
}

Deno.test("guardarFacturaConPartidasMotor valida partidas y ejecuta RPC", async () => {
  const fake = createFakeClient();

  // Partida con cantidad <= 0 rechazada
  await assertRejects(
    async () => {
      await guardarFacturaConPartidasMotor(fake, ORG_A, null, {
        proveedor_id: PROV_A,
        folio: "FAC-100",
        fecha_emision: "2026-10-15",
        moneda: "MXN",
        importe: 1160,
        partidas: [
          {
            tipo: "concepto",
            descripcion: "Vigas",
            cantidad: 0,
            precio_unitario: 100,
            importe: 0,
          },
        ],
      });
    },
    Error,
    "La cantidad de cada partida debe ser mayor a 0"
  );

  // Guardado exitoso con RPC
  const res = await guardarFacturaConPartidasMotor(fake, ORG_A, null, {
    proveedor_id: PROV_A,
    folio: "FAC-100",
    fecha_emision: "2026-10-15",
    moneda: "MXN",
    importe: 1160,
    partidas: [
      {
        tipo: "concepto",
        descripcion: "Vigas",
        cantidad: 10,
        precio_unitario: 100,
        importe: 1000,
      },
      {
        tipo: "impuesto_trasladado",
        descripcion: "IVA 16%",
        cantidad: 1,
        precio_unitario: 160,
        importe: 160,
      },
    ],
  });

  assertEquals(res.ok, true);
  assertEquals(fake.state.rpcCalls.length, 1);
  assertEquals(fake.state.rpcCalls[0].fnName, "guardar_factura_con_partidas");
  assertEquals(fake.state.rpcCalls[0].params.p_partidas.length, 2);
});

Deno.test("previsualizarCFDIsMotor detecta duplicados y proveedores nuevos", async () => {
  const fake = createFakeClient({
    proveedores: [
      { id: PROV_A, organizacion_id: ORG_A, rfc: "PAC010203XYZ", nombre: "ACEROS CORDOBA", dias_credito: 45 },
    ],
    facturas_proveedor_cfdi: [
      { organizacion_id: ORG_A, uuid_fiscal: "YA-EXISTE-UUID-1234" },
    ],
  });

  const xmlNuevo = `<?xml version="1.0" encoding="utf-8"?>
<cfdi:Comprobante Version="3.3" Folio="999" Fecha="2026-10-25" SubTotal="100.00" Total="116.00" Moneda="MXN" TipoDeComprobante="I">
  <cfdi:Emisor Rfc="PAC010203XYZ" Nombre="ACEROS CORDOBA" />
  <cfdi:Receptor Rfc="LEO120524ABC" />
  <cfdi:Conceptos><cfdi:Concepto Cantidad="1" Descripcion="Material" Importe="100.00" ValorUnitario="100.00"/></cfdi:Conceptos>
  <cfdi:Complemento><tfd:TimbreFiscalDigital UUID="UUID-TOTALMENTE-NUEVO-1"/></cfdi:Complemento>
</cfdi:Comprobante>`;

  const xmlDuplicado = `<?xml version="1.0" encoding="utf-8"?>
<cfdi:Comprobante Version="3.3" Folio="888" Fecha="2026-10-25" SubTotal="100.00" Total="116.00" Moneda="MXN" TipoDeComprobante="I">
  <cfdi:Emisor Rfc="PAC010203XYZ" Nombre="ACEROS CORDOBA" />
  <cfdi:Receptor Rfc="LEO120524ABC" />
  <cfdi:Conceptos><cfdi:Concepto Cantidad="1" Descripcion="Material" Importe="100.00" ValorUnitario="100.00"/></cfdi:Conceptos>
  <cfdi:Complemento><tfd:TimbreFiscalDigital UUID="YA-EXISTE-UUID-1234"/></cfdi:Complemento>
</cfdi:Comprobante>`;

  const res = await previsualizarCFDIsMotor(fake, ORG_A, [
    { nombre: "nuevo.xml", contenido: xmlNuevo },
    { nombre: "dup.xml", contenido: xmlDuplicado },
  ]);

  assertEquals(res.total_archivos, 2);
  assertEquals(res.validos_count, 1);
  assertEquals(res.duplicados_count, 1);
  assertEquals(res.resultados[0].estado, "valido");
  assertEquals(res.resultados[0].proveedor_id, PROV_A);
  assertEquals(res.resultados[0].dias_credito, 45);
  assertEquals(res.resultados[1].estado, "duplicado");
});

Deno.test("obtenerReporteFacturacion separa totales MXN y USD y aplica tipo de cambio", async () => {
  const fake = createFakeClient({
    tipos_cambio: [
      { organizacion_id: ORG_A, moneda: "USD", valor: 20.00, fecha: "2026-10-20" },
    ],
    v_facturas_proveedor_saldo: [
      {
        id: "f-1",
        organizacion_id: ORG_A,
        proveedor_id: PROV_A,
        folio: "F-MXN",
        fecha_emision: "2026-10-01",
        fecha_vencimiento: "2026-10-31",
        moneda: "MXN",
        importe: 5000,
        pagado: 2000,
        saldo: 3000,
        estado: "abierta",
        proveedor: { id: PROV_A, nombre: "ACEROS CORDOBA", rfc: "PAC010203XYZ" },
      },
      {
        id: "f-2",
        organizacion_id: ORG_A,
        proveedor_id: PROV_A,
        folio: "F-USD",
        fecha_emision: "2026-10-05",
        fecha_vencimiento: "2026-11-05",
        moneda: "USD",
        importe: 1000,
        pagado: 0,
        saldo: 1000,
        estado: "abierta",
        proveedor: { id: PROV_A, nombre: "ACEROS CORDOBA", rfc: "PAC010203XYZ" },
      },
    ],
  });

  const reporte = await obtenerReporteFacturacion(fake, ORG_A, { corte: "2026-10-28" });

  assertEquals(reporte.totales_mxn.total, 5000);
  assertEquals(reporte.totales_mxn.pagado, 2000);
  assertEquals(reporte.totales_mxn.saldo, 3000);

  assertEquals(reporte.totales_usd.total, 1000);
  assertEquals(reporte.totales_usd.saldo, 1000);

  // Equivalente en pesos: 5000 MXN + (1000 USD * 20.00) = 25000 MXN
  assertEquals(reporte.equivalente_pesos, 25000);
  assertEquals(reporte.saldo_equivalente_pesos, 23000); // 3000 MXN + 20000 MXN
});
