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
        gt(col: string, val: any) {
          filters.push((row: any) => row[col] > val);
          return queryObj;
        },
        lte(col: string, val: any) {
          filters.push((row: any) => row[col] <= val);
          return queryObj;
        },
        neq(col: string, val: any) {
          filters.push((row: any) => row[col] !== val);
          return queryObj;
        },
        in(col: string, vals: any[]) {
          filters.push((row: any) => Array.isArray(vals) && vals.includes(row[col]));
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

  // Importe de factura que no cuadra con la suma de partidas rechazado
  await assertRejects(
    async () => {
      await guardarFacturaConPartidasMotor(fake, ORG_A, null, {
        proveedor_id: PROV_A,
        folio: "FAC-100",
        fecha_emision: "2026-10-15",
        moneda: "MXN",
        importe: 5000,
        partidas: [
          {
            tipo: "concepto",
            descripcion: "Vigas",
            cantidad: 1,
            precio_unitario: 100,
            importe: 100,
          },
        ],
      });
    },
    Error,
    "no coincide con la suma calculada"
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
  <cfdi:Impuestos TotalImpuestosTrasladados="16.00">
    <cfdi:Traslados><cfdi:Traslado Impuesto="002" TasaOCuota="0.160000" Importe="16.00"/></cfdi:Traslados>
  </cfdi:Impuestos>
  <cfdi:Complemento><tfd:TimbreFiscalDigital UUID="UUID-TOTALMENTE-NUEVO-1"/></cfdi:Complemento>
</cfdi:Comprobante>`;

  const xmlDuplicado = `<?xml version="1.0" encoding="utf-8"?>
<cfdi:Comprobante Version="3.3" Folio="888" Fecha="2026-10-25" SubTotal="100.00" Total="116.00" Moneda="MXN" TipoDeComprobante="I">
  <cfdi:Emisor Rfc="PAC010203XYZ" Nombre="ACEROS CORDOBA" />
  <cfdi:Receptor Rfc="LEO120524ABC" />
  <cfdi:Conceptos><cfdi:Concepto Cantidad="1" Descripcion="Material" Importe="100.00" ValorUnitario="100.00"/></cfdi:Conceptos>
  <cfdi:Impuestos TotalImpuestosTrasladados="16.00">
    <cfdi:Traslados><cfdi:Traslado Impuesto="002" TasaOCuota="0.160000" Importe="16.00"/></cfdi:Traslados>
  </cfdi:Impuestos>
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
  assertEquals(reporte.tc_vigente.sin_tipo_cambio, false);
});

Deno.test("importarCFDIsMotor re-parsea en el servidor y rechaza XML malicioso", async () => {
  const fake = createFakeClient({
    proveedores: [
      { id: PROV_A, organizacion_id: ORG_A, rfc: "PAC010203XYZ", nombre: "ACEROS CORDOBA", dias_credito: 30 },
    ],
  });

  const xmlMalicioso = `<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE foo [ <!ENTITY xxe SYSTEM "file:///etc/passwd"> ]>
<cfdi:Comprobante Version="3.3" Folio="666" Total="100.00" Moneda="MXN">
  <cfdi:Emisor Rfc="PAC010203XYZ" Nombre="ACEROS CORDOBA"/>
  <cfdi:Conceptos><cfdi:Concepto Importe="100.00" Cantidad="1" ValorUnitario="100.00"/></cfdi:Conceptos>
</cfdi:Comprobante>`;

  const xmlValido = `<?xml version="1.0" encoding="utf-8"?>
<cfdi:Comprobante Version="3.3" Folio="777" Fecha="2026-10-25T12:00:00" SubTotal="100.00" Total="116.00" Moneda="MXN" TipoDeComprobante="I">
  <cfdi:Emisor Rfc="PAC010203XYZ" Nombre="ACEROS CORDOBA"/>
  <cfdi:Receptor Rfc="LEO120524ABC" Nombre="LEOLCA"/>
  <cfdi:Conceptos><cfdi:Concepto Cantidad="1" Descripcion="Material" Importe="100.00" ValorUnitario="100.00"/></cfdi:Conceptos>
  <cfdi:Impuestos TotalImpuestosTrasladados="16.00">
    <cfdi:Traslados><cfdi:Traslado Impuesto="002" TasaOCuota="0.160000" Importe="16.00"/></cfdi:Traslados>
  </cfdi:Impuestos>
  <cfdi:Complemento><tfd:TimbreFiscalDigital UUID="UUID-VALIDO-777"/></cfdi:Complemento>
</cfdi:Comprobante>`;

  const res = await importarCFDIsMotor(fake, ORG_A, [
    {
      nombre_archivo: "malicioso.xml",
      xml_contenido: xmlMalicioso,
      proveedor_id: PROV_A,
    },
    {
      nombre_archivo: "valido.xml",
      xml_contenido: xmlValido,
      proveedor_id: PROV_A,
    },
  ]);

  assertEquals(res.total_solicitadas, 2);
  assertEquals(res.importadas, 1);
  assertEquals(res.detalles[0].ok, false);
  assertEquals(res.detalles[0].error.includes("declaraciones DTD o entidades externas"), true);
  assertEquals(res.detalles[1].ok, true);
  assertEquals(res.detalles[1].uuid_fiscal, "UUID-VALIDO-777");
});

Deno.test("importarCFDIsMotor con 30 conceptos de 10.005000 cuadra exactamente con total y genera ajuste", async () => {
  const fake = createFakeClient({
    proveedores: [
      { id: PROV_A, organizacion_id: ORG_A, rfc: "PAC010203XYZ", nombre: "ACEROS CORDOBA", dias_credito: 15 },
    ],
  });

  // Generar 30 conceptos de 10.005000 -> SubTotal 300.15, IVA 48.02, Total 348.17
  const conceptosXml = Array.from({ length: 30 }, (_, i) => 
    `<cfdi:Concepto ClaveProdServ="01010101" Cantidad="1" ClaveUnidad="H87" Descripcion="Tornillo especial ${i + 1}" ValorUnitario="10.005000" Importe="10.005000"/>`
  ).join("\n    ");

  const xml30Conceptos = `<?xml version="1.0" encoding="utf-8"?>
<cfdi:Comprobante Version="4.0" Folio="30CONC" Fecha="2026-10-25T12:00:00" SubTotal="300.15" Total="348.17" Moneda="MXN" TipoDeComprobante="I">
  <cfdi:Emisor Rfc="PAC010203XYZ" Nombre="ACEROS CORDOBA"/>
  <cfdi:Receptor Rfc="LEO120524ABC" Nombre="LEOLCA"/>
  <cfdi:Conceptos>
    ${conceptosXml}
  </cfdi:Conceptos>
  <cfdi:Impuestos TotalImpuestosTrasladados="48.02">
    <cfdi:Traslados>
      <cfdi:Traslado Impuesto="002" TipoFactor="Tasa" TasaOCuota="0.160000" Importe="48.02"/>
    </cfdi:Traslados>
  </cfdi:Impuestos>
  <cfdi:Complemento><tfd:TimbreFiscalDigital UUID="30-CONCEPTOS-UUID-EXACTO"/></cfdi:Complemento>
</cfdi:Comprobante>`;

  const res = await importarCFDIsMotor(fake, ORG_A, [
    {
      nombre_archivo: "factura_30_conceptos.xml",
      xml_contenido: xml30Conceptos,
      proveedor_id: PROV_A,
    },
  ]);

  assertEquals(res.total_solicitadas, 1);
  assertEquals(res.importadas, 1);
  assertEquals(res.detalles[0].ok, true);
  assertEquals(res.detalles[0].uuid_fiscal, "30-CONCEPTOS-UUID-EXACTO");

  // Verificar que el RPC recibió la llamada con los días de crédito del proveedor (15) y no 30 hardcodeados
  assertEquals(fake.state.rpcCalls.length, 1);
  assertEquals(fake.state.rpcCalls[0].params.p_dias_credito, 15);
  assertEquals(fake.state.rpcCalls[0].params.p_importe, 348.17);

  // Verificar que se incluyó una partida de ajuste por redondeo para que la suma neta sea exactamente 348.17
  const partidas = fake.state.rpcCalls[0].params.p_partidas;
  const partidaAjuste = partidas.find((p: any) => p.descripcion.includes("Ajuste por redondeo"));
  assertEquals(Boolean(partidaAjuste), true);
  assertEquals(partidaAjuste.tipo, "descuento");
  assertEquals(partidaAjuste.importe, 0.15);
});

Deno.test("obtenerReporteFacturacion usa diasAtraso con fecha de corte y maneja signo real de la vista", async () => {
  // En la vista real:
  // - Factura vigente que vence en 31 días: dias_vencimiento = +31, estado_vencimiento = 'al_corriente'
  // - Factura vencida hace 4 días: dias_vencimiento = -4, estado_vencimiento = 'vencida'
  const fake = createFakeClient({
    tipos_cambio: [
      { organizacion_id: ORG_A, moneda: "USD", valor: 20.00, fecha: "2026-10-20" },
    ],
    v_facturas_proveedor_saldo: [
      {
        id: "f-vigente",
        organizacion_id: ORG_A,
        proveedor_id: PROV_A,
        folio: "F-VIGENTE",
        fecha_emision: "2026-10-01",
        fecha_vencimiento: "2026-11-28", // +31 días respecto a 2026-10-28
        dias_vencimiento: 31, // Signo real de la vista (positivo = faltan días)
        estado_vencimiento: "al_corriente",
        moneda: "MXN",
        importe: 1000,
        pagado: 0,
        saldo: 1000,
        estado: "abierta",
        proveedor: { id: PROV_A, nombre: "PROV VIGENTE", rfc: "PVIG010101AAA" },
      },
      {
        id: "f-vencida",
        organizacion_id: ORG_A,
        proveedor_id: PROV_A,
        folio: "F-VENCIDA",
        fecha_emision: "2026-09-24",
        fecha_vencimiento: "2026-10-24", // -4 días respecto a 2026-10-28
        dias_vencimiento: -4, // Signo real de la vista (negativo = vencida)
        estado_vencimiento: "vencida",
        moneda: "MXN",
        importe: 2000,
        pagado: 0,
        saldo: 2000,
        estado: "abierta",
        proveedor: { id: PROV_A, nombre: "PROV VENCIDO", rfc: "PVEN020202BBB" },
      },
    ],
  });

  const reporte = await obtenerReporteFacturacion(fake, ORG_A, { corte: "2026-10-28" });

  const fVig = reporte.items.find((it: any) => it.id === "f-vigente");
  const fVen = reporte.items.find((it: any) => it.id === "f-vencida");

  // Factura vigente: dias_atraso debe ser -31 (no atrasada), estado debe ser 'abierta' (NO 'vencida')
  assertEquals(fVig.dias_atraso, -31);
  assertEquals(fVig.estado, "abierta");

  // Factura vencida: dias_atraso debe ser +4 (4 días de atraso), estado debe ser 'vencida'
  assertEquals(fVen.dias_atraso, 4);
  assertEquals(fVen.estado, "vencida");
});

Deno.test("obtenerReporteFacturacion excluye facturas canceladas de totales", async () => {
  const fake = createFakeClient({
    v_facturas_proveedor_saldo: [
      {
        id: "f-activa",
        organizacion_id: ORG_A,
        proveedor_id: PROV_A,
        folio: "F-ACTIVA",
        fecha_emision: "2026-10-01",
        fecha_vencimiento: "2026-10-31",
        moneda: "MXN",
        importe: 1000,
        pagado: 0,
        saldo: 1000,
        estado: "abierta",
        proveedor: { id: PROV_A, nombre: "ACEROS CORDOBA", rfc: "PAC010203XYZ" },
      },
      {
        id: "f-cancelada",
        organizacion_id: ORG_A,
        proveedor_id: PROV_A,
        folio: "F-CANCELADA",
        fecha_emision: "2026-10-02",
        fecha_vencimiento: "2026-11-02",
        moneda: "MXN",
        importe: 777,
        pagado: 0,
        saldo: 777,
        estado: "cancelada",
        proveedor: { id: PROV_A, nombre: "ACEROS CORDOBA", rfc: "PAC010203XYZ" },
      },
    ],
  });

  // Reporte sin filtro ("todas")
  const reporteTodas = await obtenerReporteFacturacion(fake, ORG_A, { corte: "2026-10-28" });
  assertEquals(reporteTodas.items.length, 2);
  // Los totales NO deben sumar los 777 de la cancelada
  assertEquals(reporteTodas.totales_mxn.total, 1000);
  assertEquals(reporteTodas.totales_mxn.saldo, 1000);

  // Reporte con filtro "abierta"
  const reporteAbierta = await obtenerReporteFacturacion(fake, ORG_A, { corte: "2026-10-28", estado: "abierta" });
  assertEquals(reporteAbierta.items.length, 1);
  assertEquals(reporteAbierta.items[0].id, "f-activa");
});

Deno.test("guardarFacturaConPartidasMotor maneja 409 para uq_folio y factura_cancelada, y 500 para errores internos", async () => {
  // Test uq_facturas_proveedor_folio
  const fakeFolioDup = {
    rpc() {
      return Promise.resolve({
        data: null,
        error: { message: 'duplicate key value violates unique constraint "uq_facturas_proveedor_folio"' },
      });
    },
  };

  await assertRejects(
    async () => {
      await guardarFacturaConPartidasMotor(fakeFolioDup, ORG_A, null, {
        proveedor_id: PROV_A,
        folio: "DUP-001",
        fecha_emision: "2026-10-15",
        moneda: "MXN",
        importe: 100,
        partidas: [{ tipo: "concepto", descripcion: "Item", cantidad: 1, precio_unitario: 100, importe: 100 }],
      });
    },
    Error,
    "Ya existe una factura con ese folio para este proveedor"
  );

  // Test factura_cancelada
  const fakeCancelada = {
    rpc() {
      return Promise.resolve({
        data: null,
        error: { message: 'factura_cancelada: No se puede modificar una factura que ya ha sido cancelada' },
      });
    },
  };

  await assertRejects(
    async () => {
      await guardarFacturaConPartidasMotor(fakeCancelada, ORG_A, "fact-cancelada-id", {
        proveedor_id: PROV_A,
        folio: "CANC-001",
        fecha_emision: "2026-10-15",
        moneda: "MXN",
        importe: 100,
        partidas: [{ tipo: "concepto", descripcion: "Item", cantidad: 1, precio_unitario: 100, importe: 100 }],
      });
    },
    Error,
    "No se puede modificar una factura que ya ha sido cancelada"
  );

  // Test error no controlado -> 500 genérico sin filtrar texto interno
  const fakeUnhandled = {
    rpc() {
      return Promise.resolve({
        data: null,
        error: { message: 'check constraint "factura_proveedor_partidas_cantidad_check" failed (raw postgres detail)' },
      });
    },
  };

  await assertRejects(
    async () => {
      await guardarFacturaConPartidasMotor(fakeUnhandled, ORG_A, null, {
        proveedor_id: PROV_A,
        folio: "UNH-001",
        fecha_emision: "2026-10-15",
        moneda: "MXN",
        importe: 100,
        partidas: [{ tipo: "concepto", descripcion: "Item", cantidad: 1, precio_unitario: 100, importe: 100 }],
      });
    },
    Error,
    "Error interno al guardar la factura con partidas"
  );
});

Deno.test("previsualizarCFDIsMotor detecta inconsistencia en total y marca estado inconsistente", async () => {
  const fake = createFakeClient();

  const xmlInconsistente = `<?xml version="1.0" encoding="utf-8"?>
<cfdi:Comprobante Version="3.3" Folio="999" Fecha="2026-10-25" SubTotal="100.00" Total="999.00" Moneda="MXN" TipoDeComprobante="I">
  <cfdi:Emisor Rfc="PAC010203XYZ" Nombre="ACEROS CORDOBA" />
  <cfdi:Receptor Rfc="LEO120524ABC" />
  <cfdi:Conceptos><cfdi:Concepto Cantidad="1" Descripcion="Material" Importe="100.00" ValorUnitario="100.00"/></cfdi:Conceptos>
  <cfdi:Complemento><tfd:TimbreFiscalDigital UUID="UUID-INCONSISTENTE-999"/></cfdi:Complemento>
</cfdi:Comprobante>`;

  const res = await previsualizarCFDIsMotor(fake, ORG_A, [
    { nombre: "inconsistente.xml", contenido: xmlInconsistente },
  ]);

  assertEquals(res.total_archivos, 1);
  assertEquals(res.validos_count, 0);
  assertEquals(res.resultados[0].estado, "inconsistente");
  assertEquals(res.resultados[0].motivo.includes("no coincide"), true);
});


