import { assertEquals, assertRejects } from "jsr:@std/assert";
import {
  AlmacenRecepcionError,
  VENTANA_DOBLE_CONTEO_DIAS,
  anularRecepcionAlmacen,
  cantidadARecibir,
  clasificarServicioProbable,
  costoUnitarioMxn,
  evaluarBanderasRecepcion,
  listarRecepcionesAlmacen,
  mapearErrorRpcAlmacen,
  obtenerPropuestaRecepcionAlmacen,
  recibirFacturaAlmacen,
  validarLoteRecepcion,
} from "./almacen_recepcion.ts";
import { listarCatalogoAlias } from "./acero_cfdi.ts";
import {
  cancelarFactura,
  formatearErrorRespuesta,
  guardarFacturaConPartidasMotor,
} from "./cuentas_por_pagar.ts";

function crearMockSupabase(
  tablas: Record<string, Record<string, unknown>[]>,
  rpcHandler?: (fn: string, args: Record<string, unknown>) => unknown,
) {
  const state: Record<string, Record<string, unknown>[]> = {};
  for (const [k, v] of Object.entries(tablas)) {
    state[k] = v.map((r) => ({ ...r }));
  }

  return {
    state,
    rpc(fn: string, args: Record<string, unknown>) {
      if (rpcHandler) {
        return Promise.resolve({ data: rpcHandler(fn, args), error: null });
      }
      return Promise.resolve({ data: { ok: true, fn, args }, error: null });
    },
    from(table: string) {
      const filters: Array<(r: Record<string, unknown>) => boolean> = [];
      let rangeStart: number | null = null;
      let rangeEnd: number | null = null;

      const exec = () => {
        const rows = state[table] || [];
        const matched = rows.filter((r) => filters.every((f) => f(r)));
        if (rangeStart !== null && rangeEnd !== null) {
          return matched.slice(rangeStart, rangeEnd + 1);
        }
        return matched;
      };

      const builder: Record<string, unknown> = {
        select() { return builder; },
        eq(col: string, val: unknown) {
          filters.push((r) => r[col] === val);
          return builder;
        },
        in(col: string, vals: unknown[]) {
          const set = new Set(vals);
          filters.push((r) => set.has(r[col]));
          return builder;
        },
        order() { return builder; },
        range(from: number, to: number) {
          rangeStart = from;
          rangeEnd = to;
          return builder;
        },
        maybeSingle() {
          const res = exec();
          return Promise.resolve({ data: res[0] ?? null, error: null });
        },
        then(resolve: (v: unknown) => unknown, reject?: (e: unknown) => unknown) {
          return Promise.resolve({ data: exec(), error: null }).then(resolve, reject);
        },
      };
      return builder;
    },
  };
}

Deno.test("cantidadARecibir: fraccionaria 12.5, factor 6.1, redondeo 4 dec y limites <= 0", () => {
  assertEquals(cantidadARecibir(12.5, 1), { ok: true, cantidad: 12.5 });
  assertEquals(cantidadARecibir(10, 6.1), { ok: true, cantidad: 61 });
  assertEquals(cantidadARecibir(1, 1 / 3), { ok: true, cantidad: 0.3333 });
  assertEquals(cantidadARecibir(0, 1).ok, false);
  assertEquals(cantidadARecibir(10, 0).ok, false);
});

Deno.test("costoUnitarioMxn: MXN, USD con/sin TC, factor 6.1, redondeo 4 dec y limites", () => {
  assertEquals(
    costoUnitarioMxn({ importe: 1000, cantidadXml: 10, moneda: "MXN", factorConversion: 1 }),
    { ok: true, costo: 100 },
  );
  // USD con TC 20 y factor 6.1: (610 / 10) * 20 / 6.1 = 200
  assertEquals(
    costoUnitarioMxn({ importe: 610, cantidadXml: 10, moneda: "USD", tipoCambio: 20, factorConversion: 6.1 }),
    { ok: true, costo: 200 },
  );
  const sinTc = costoUnitarioMxn({ importe: 100, cantidadXml: 1, moneda: "USD", tipoCambio: null, factorConversion: 1 });
  assertEquals(sinTc.ok, false);
  if (!sinTc.ok) assertEquals(sinTc.codigo, "tipo_cambio_requerido");

  assertEquals(
    costoUnitarioMxn({ importe: 100, cantidadXml: 3, moneda: "MXN", factorConversion: 1 }),
    { ok: true, costo: 33.3333 },
  );
  assertEquals(costoUnitarioMxn({ importe: 0, cantidadXml: 1, moneda: "MXN", factorConversion: 1 }).ok, false);
  assertEquals(costoUnitarioMxn({ importe: 100, cantidadXml: 0, moneda: "MXN", factorConversion: 1 }).ok, false);
  assertEquals(costoUnitarioMxn({ importe: 100, cantidadXml: 1, moneda: "MXN", factorConversion: 0 }).ok, false);
});

Deno.test("clasificarServicioProbable: fletes, maniobras, E48 y clave SAT 78xx vs bienes", () => {
  assertEquals(clasificarServicioProbable({ descripcion: "FLETE TERRESTRE EXPRESS", claveUnidad: "H87" }), true);
  assertEquals(clasificarServicioProbable({ descripcion: "MANIOBRAS DE DESCARGA", claveUnidad: "H87" }), true);
  assertEquals(clasificarServicioProbable({ descripcion: "ALGO GENERICO", claveUnidad: "E48" }), true);
  assertEquals(clasificarServicioProbable({ descripcion: "ACARREO LOCAL", claveSat: "78101800", claveUnidad: "H87" }), true);
  assertEquals(clasificarServicioProbable({ descripcion: "TORNILLO GALVANIZADO 1/2", claveSat: "31161500", claveUnidad: "H87" }), false);
});

Deno.test("evaluarBanderasRecepcion: KGM bloqueada, fecha anterior vs igual, USD sin TC y doble conteo", () => {
  const b1 = evaluarBanderasRecepcion({
    yaRecibida: false, compraYaRecibida: true, posibleCompraDuplicada: true,
    fechaFactura: "2026-11-19", ultimoCostoFecha: "2026-11-20",
    claveUnidad: "KGM", factorCapturado: false, moneda: "USD", tipoCambio: null,
    descuentoEnFactura: true, esServicioProbable: false,
  });
  assertEquals(b1.compra_ya_recibida, true);
  assertEquals(b1.posible_compra_duplicada, true);
  assertEquals(b1.costo_fecha_anterior, true);
  assertEquals(b1.requiere_factor, true);
  assertEquals(b1.bloqueada_unidad, true);
  assertEquals(b1.bloqueada_tipo_cambio, true);
  assertEquals(b1.descuento_en_factura, true);

  // Fecha igual NO es anterior
  const b2 = evaluarBanderasRecepcion({
    yaRecibida: false, compraYaRecibida: false, posibleCompraDuplicada: false,
    fechaFactura: "2026-11-20", ultimoCostoFecha: "2026-11-20",
    claveUnidad: "H87", factorCapturado: true, moneda: "MXN", tipoCambio: null,
    descuentoEnFactura: false, esServicioProbable: false,
  });
  assertEquals(b2.costo_fecha_anterior, false);
  assertEquals(b2.bloqueada_unidad, false);
});

Deno.test("validarLoteRecepcion y mapearErrorRpcAlmacen: 2 partidas mismo producto permitidas, duplicada bloqueada, factor omitido", () => {
  const facId = "11111111-1111-4111-8111-111111111111";
  const p1 = "11111111-1111-4111-8111-111111111112";
  const p2 = "11111111-1111-4111-8111-111111111113";

  // Dos partidas distintas con el MISMO producto_id -> permitido (se suman en stock)
  const okLote = validarLoteRecepcion(facId, [
    { partida_id: p1, producto_id: "prod-1", cantidad_recibida: 12.5 },
    { partida_id: p2, producto_id: "prod-1", factor_conversion: 6.1 },
  ]);
  assertEquals(okLote.length, 2);
  assertEquals("factor_conversion" in okLote[0], false); // omitido NO se vuelve 1
  assertEquals(okLote[0].guardar_alias, true);
  assertEquals(okLote[1].factor_conversion, 6.1);
  assertEquals(okLote[1].factor_confirmado, true);

  // Misma partida duplicada -> 400
  assertRejects(
    async () => validarLoteRecepcion(facId, [
      { partida_id: p1, producto_id: "prod-1" },
      { partida_id: p1, producto_id: "prod-2" },
    ]),
    AlmacenRecepcionError,
    "repetida",
  );

  // Mapeo de errores SQL
  assertEquals(mapearErrorRpcAlmacen(new Error("factura_no_encontrada: x")).status, 404);
  assertEquals(mapearErrorRpcAlmacen(new Error("recepcion_no_encontrada: x")).status, 404);
  assertEquals(mapearErrorRpcAlmacen(new Error("partida_ya_recibida: x")).status, 409);
  assertEquals(mapearErrorRpcAlmacen(new Error("compra_ya_recibida: x")).status, 409);
  assertEquals(mapearErrorRpcAlmacen(new Error("stock_insuficiente: x")).status, 409);
  assertEquals(mapearErrorRpcAlmacen({ code: "40P01", message: "deadlock" }).status, 409);
  assertEquals(mapearErrorRpcAlmacen({ code: "23505", message: "dup" }).status, 409);
  assertEquals(mapearErrorRpcAlmacen(new Error("factor_requerido: x")).status, 400);
  assertEquals(mapearErrorRpcAlmacen(new Error("producto_no_es_bien: x")).status, 400);
  assertEquals(mapearErrorRpcAlmacen(new Error("motivo_requerido: x")).status, 400);
  assertEquals(mapearErrorRpcAlmacen({ code: "22P02", message: "bad uuid" }).status, 400);
});

Deno.test("obtenerPropuestaRecepcionAlmacen: org ajena, solo bienes activos, alias producto vs acero, doble conteo 60d y paginacion", async () => {
  const orgA = "00000000-0000-4000-8000-000000000001";
  const orgB = "00000000-0000-4000-8000-000000000002";
  const facA = "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1";
  const facB = "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb1";
  const provA = "cccccccc-cccc-4ccc-8ccc-ccccccccccc1";

  const partidas: Record<string, unknown>[] = [
    // P1: alias producto con factor 0.1 en KGM (100 kg * 0.1 = 10 LT, costo = 2000/100 / 0.1 = 200)
    { id: "p-1", organizacion_id: orgA, factura_id: facA, orden: 1, tipo: "concepto", descripcion: "PINTURA EPOXICA INDUSTRIAL", cantidad: 100, precio_unitario: 20, importe: 2000, clave_sat: "31211500", clave_unidad: "KGM" },
    // P2: servicio probable (flete) -> no sugiere producto
    { id: "p-2", organizacion_id: orgA, factura_id: facA, orden: 2, tipo: "concepto", descripcion: "FLETE TERRESTRE", cantidad: 1, precio_unitario: 500, importe: 500, clave_sat: "78101800", clave_unidad: "E48" },
    // P3: coincide con alias de acero_material (NO debe usarse porque destino_tipo != 'producto')
    { id: "p-3", organizacion_id: orgA, factura_id: facA, orden: 3, tipo: "concepto", descripcion: "SOLO ALIAS ACERO", cantidad: 1, precio_unitario: 100, importe: 100, clave_sat: null, clave_unidad: "H87" },
    // P4: producto con compra recibida hace 10 días (debe activar posible_compra_duplicada) vs compra hace 90 días (NO debe)
    { id: "p-4", organizacion_id: orgA, factura_id: facA, orden: 4, tipo: "concepto", descripcion: "TORNILLO GALVANIZADO 1/2", cantidad: 12.5, precio_unitario: 12, importe: 150, clave_sat: null, clave_unidad: "H87" },
  ];
  // 1001 partidas totales para verificar paginación > 1000
  for (let i = 5; i <= 1001; i++) {
    partidas.push({
      id: `p-${i}`, organizacion_id: orgA, factura_id: facA, orden: i, tipo: "concepto",
      descripcion: `CONCEPTO EXTRA ${i}`, cantidad: 1, precio_unitario: 10, importe: 10, clave_sat: null, clave_unidad: "H87",
    });
  }

  const mock = crearMockSupabase({
    facturas_proveedor: [
      { id: facA, organizacion_id: orgA, proveedor_id: provA, compra_id: null, folio: "FG-A", fecha_emision: "2026-11-20", moneda: "MXN", tipo_cambio_emision: null, uuid_fiscal: "U-A", descuento: 25, estado: "abierta" },
      { id: facB, organizacion_id: orgB, proveedor_id: null, compra_id: null, folio: "FG-B", fecha_emision: "2026-11-20", moneda: "MXN", tipo_cambio_emision: null, uuid_fiscal: "U-B", descuento: 0, estado: "abierta" },
    ],
    factura_proveedor_partidas: partidas,
    productos: [
      { id: "prod-pintura", organizacion_id: orgA, nombre: "Pintura Epoxica Gris", unidad: "LT", tipo: "bien", tipo_item: "materia_prima", costo: 180, stock_actual: 5, ultimo_costo_compra: 190, ultimo_costo_compra_fecha: "2026-11-25", activo: true },
      { id: "prod-tornillo", organizacion_id: orgA, nombre: "Tornillo Galvanizado 1/2", unidad: "PZA", tipo: "bien", tipo_item: "materia_prima", costo: 10, stock_actual: 20, ultimo_costo_compra: null, ultimo_costo_compra_fecha: null, activo: true },
      { id: "prod-serv", organizacion_id: orgA, nombre: "Flete Terrestre", unidad: "SERV", tipo: "servicio", tipo_item: "materia_prima", costo: 500, stock_actual: 0, ultimo_costo_compra: null, ultimo_costo_compra_fecha: null, activo: true },
      { id: "prod-inact", organizacion_id: orgA, nombre: "Solo Alias Acero", unidad: "PZA", tipo: "bien", tipo_item: "materia_prima", costo: 50, stock_actual: 0, ultimo_costo_compra: null, ultimo_costo_compra_fecha: null, activo: false },
    ],
    catalogo_alias_factura: [
      { id: "al-g1", organizacion_id: orgA, proveedor_id: provA, clave_sat: null, descripcion_normalizada: "pintura epoxica industrial", destino_tipo: "producto", destino_id: "prod-pintura", factor_conversion: 0.1 },
      { id: "al-f1", organizacion_id: orgA, proveedor_id: provA, clave_sat: null, descripcion_normalizada: "solo alias acero", destino_tipo: "acero_material", destino_id: "prod-tornillo", factor_conversion: 1 },
    ],
    almacen_recepcion_lineas: [],
    proveedores: [{ id: provA, organizacion_id: orgA, nombre: "PROVEEDOR G" }],
    compras_proveedor: [
      // Compra reciente (10 días antes) en orgA -> SÍ activa posible_compra_duplicada
      { id: "oc-reciente", organizacion_id: orgA, proveedor_id: provA, folio: "OC-RECIENTE", estado: "Recibida", fecha: "2026-11-10T10:00:00Z" },
      // Compra vieja (90 días antes) en orgA -> NO debe activar
      { id: "oc-vieja", organizacion_id: orgA, proveedor_id: provA, folio: "OC-VIEJA-90D", estado: "Recibida", fecha: "2026-08-01T10:00:00Z" },
      // Compra reciente en orgB -> NO debe cruzar organizaciones
      { id: "oc-orgb", organizacion_id: orgB, proveedor_id: provA, folio: "OC-ORGB", estado: "Recibida", fecha: "2026-11-15T10:00:00Z" },
    ],
    compra_items: [
      { id: "ci-1", compra_id: "oc-reciente", material_id: "prod-tornillo" },
      { id: "ci-2", compra_id: "oc-vieja", material_id: "prod-pintura" },
      { id: "ci-3", compra_id: "oc-orgb", material_id: "prod-pintura" },
    ],
  }) as unknown as Parameters<typeof obtenerPropuestaRecepcionAlmacen>[0];

  // Aislamiento de factura ajena
  await assertRejects(
    () => obtenerPropuestaRecepcionAlmacen(mock, orgA, facB),
    AlmacenRecepcionError,
    "Factura no encontrada",
  );

  const prop = await obtenerPropuestaRecepcionAlmacen(mock, orgA, facA);
  // Paginación > 1000
  assertEquals(prop.lineas.length, 1001);
  // Solo bienes activos (excluye servicio e inactivo)
  assertEquals(prop.productos.length, 2);
  // Descuento en factura detectado
  assertEquals(prop.factura.descuento_en_factura, true);
  // P1: alias producto, factor 0.1, cantidad 10, costo 200, fecha anterior (2026-11-20 < 2026-11-25), SIN duplicada (OC vieja 90d y orgB ignoradas)
  assertEquals(prop.lineas[0].sugerencia_origen, "alias");
  assertEquals(prop.lineas[0].producto_id_sugerido, "prod-pintura");
  assertEquals(prop.lineas[0].cantidad_recibir_sugerida, 10);
  assertEquals(prop.lineas[0].costo_unitario_mxn, 200);
  assertEquals(prop.lineas[0].banderas.costo_fecha_anterior, true);
  assertEquals(prop.lineas[0].banderas.posible_compra_duplicada, false);
  // P2: servicio probable
  assertEquals(prop.lineas[1].banderas.es_servicio_probable, true);
  assertEquals(prop.lineas[1].producto_id_sugerido, null);
  // P3: alias de acero_material NO se mezcla
  assertEquals(prop.lineas[2].sugerencia_origen, "ninguna");
  assertEquals(prop.lineas[2].producto_id_sugerido, null);
  // P4: sugerido por similitud + doble conteo (b) por OC-RECIENTE
  assertEquals(prop.lineas[3].producto_id_sugerido, "prod-tornillo");
  assertEquals(prop.lineas[3].banderas.posible_compra_duplicada, true);
  assertEquals(prop.folios_compras_duplicadas, ["OC-RECIENTE"]);
  assertEquals(prop.posible_compra_duplicada, true);

  // listarCatalogoAlias con destino_tipo='producto' resuelve destino_nombre desde productos
  const aliasProd = await listarCatalogoAlias(mock, orgA, "producto");
  assertEquals(aliasProd.length, 1);
  assertEquals(aliasProd[0].destino_nombre, "Pintura Epoxica Gris");
});

Deno.test("recibirFacturaAlmacen, listarRecepcionesAlmacen y anularRecepcionAlmacen: validaciones y aislamiento", async () => {
  const orgA = "00000000-0000-4000-8000-000000000001";
  const orgB = "00000000-0000-4000-8000-000000000002";
  const recA = "11111111-1111-4111-8111-11111111111a";
  const facA = "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1";
  const p1 = "11111111-1111-4111-8111-111111111112";

  let lastRpc: { fn: string; args: Record<string, unknown> } | null = null;
  const mock = crearMockSupabase(
    {
      almacen_recepciones: [
        { id: recA, organizacion_id: orgA, factura_id: facA, proveedor_id: null, estado: "recibida", created_at: "2026-11-24T10:00:00Z" },
        { id: "rec-b", organizacion_id: orgB, factura_id: "fac-b", proveedor_id: null, estado: "recibida", created_at: "2026-11-24T10:00:00Z" },
      ],
      almacen_recepcion_lineas: [
        { id: "rl-1", organizacion_id: orgA, recepcion_id: recA, producto_id: "prod-1", cantidad_xml: 10, factor_conversion: 1, cantidad_recibida: 10, costo_unitario_mxn: 50, activa: true },
      ],
      facturas_proveedor: [{ id: facA, organizacion_id: orgA, folio: "FG-A", fecha_emision: "2026-11-24", moneda: "MXN" }],
      productos: [{ id: "prod-1", organizacion_id: orgA, nombre: "Tornillo", unidad: "PZA" }],
    },
    (fn, args) => {
      lastRpc = { fn, args };
      return { ok: true };
    },
  ) as unknown as Parameters<typeof recibirFacturaAlmacen>[0];

  await recibirFacturaAlmacen(mock, orgA, "u1", facA, [{ partida_id: p1, producto_id: "prod-1" }], true, "Nota");
  assertEquals(lastRpc!.fn, "recibir_factura_almacen");
  assertEquals(lastRpc!.args.p_confirmo_doble, true);

  const lista = await listarRecepcionesAlmacen(mock, orgA);
  assertEquals(lista.length, 1);
  assertEquals(lista[0].factura_folio, "FG-A");

  // Anular sin motivo -> 400
  await assertRejects(() => anularRecepcionAlmacen(mock, orgA, "u1", recA, "   "), AlmacenRecepcionError, "motivo");
  // Anular con UUID inválido -> 400
  await assertRejects(() => anularRecepcionAlmacen(mock, orgA, "u1", "bad-uuid", "error"), AlmacenRecepcionError, "no es válido");
  // Anular válido
  await anularRecepcionAlmacen(mock, orgA, "u1", recA, "Error de captura");
  assertEquals(lastRpc!.fn, "anular_recepcion_almacen");
});

Deno.test("obtenerPropuestaRecepcionAlmacen (D2/O1): ventana +-60/61d, estados, proveedor, org, inactivas, SAT 78/80/81/84, descuento y diff %", async () => {
  assertEquals(VENTANA_DOBLE_CONTEO_DIAS, 60);
  // Claves SAT de servicio 78, 80, 81, 84
  assertEquals(clasificarServicioProbable({ descripcion: "Concepto generico", claveUnidad: "H87", claveSat: "78101800" }), true);
  assertEquals(clasificarServicioProbable({ descripcion: "Concepto generico", claveUnidad: "H87", claveSat: "80101500" }), true);
  assertEquals(clasificarServicioProbable({ descripcion: "Concepto generico", claveUnidad: "H87", claveSat: "81111500" }), true);
  assertEquals(clasificarServicioProbable({ descripcion: "Concepto generico", claveUnidad: "H87", claveSat: "84111500" }), true);
  assertEquals(clasificarServicioProbable({ descripcion: "Tornillo", claveUnidad: "H87", claveSat: "31161500" }), false);

  const orgA = "00000000-0000-4000-8000-000000000001";
  const orgB = "00000000-0000-4000-8000-000000000002";
  const provA = "11111111-1111-4111-8111-111111111111";
  const provOtro = "11111111-1111-4111-8111-111111111199";
  const facA = "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb1";
  const facLigadaRec = "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb2";
  const facLigadaPend = "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb3";

  const mock = crearMockSupabase({
    facturas_proveedor: [
      {
        id: facA,
        organizacion_id: orgA,
        proveedor_id: provA,
        folio: "FG-VENTANA",
        fecha_emision: "2026-07-01",
        moneda: "MXN",
        tipo_cambio_emision: null,
        estado: "abierta",
        compra_id: null,
        descuento: 0, // 0 en cabecera, pero con partida tipo='descuento' (mata M38)
      },
      {
        id: facLigadaRec,
        organizacion_id: orgA,
        proveedor_id: provA,
        folio: "FG-LIG-REC",
        fecha_emision: "2026-07-01",
        moneda: "MXN",
        estado: "abierta",
        compra_id: "oc-lig-rec",
        descuento: 0,
      },
      {
        id: facLigadaPend,
        organizacion_id: orgA,
        proveedor_id: provA,
        folio: "FG-LIG-PEND",
        fecha_emision: "2026-07-01",
        moneda: "MXN",
        estado: "abierta",
        compra_id: "oc-lig-pend",
        descuento: 0,
      },
    ],
    proveedores: [{ id: provA, nombre: "Proveedor A" }],
    productos: [
      { id: "p-menos60", organizacion_id: orgA, nombre: "Prod Menos60", unidad: "PZA", tipo: "bien", costo: 300, stock_actual: 10, ultimo_costo_compra: null, ultimo_costo_compra_fecha: null },
      { id: "p-mas60", organizacion_id: orgA, nombre: "Prod Mas60", unidad: "PZA", tipo: "bien", costo: 100, stock_actual: 10, ultimo_costo_compra: null, ultimo_costo_compra_fecha: null },
      { id: "p-menos61", organizacion_id: orgA, nombre: "Prod Menos61", unidad: "PZA", tipo: "bien", costo: 100, stock_actual: 10, ultimo_costo_compra: null, ultimo_costo_compra_fecha: null },
      { id: "p-mas61", organizacion_id: orgA, nombre: "Prod Mas61", unidad: "PZA", tipo: "bien", costo: 100, stock_actual: 10, ultimo_costo_compra: null, ultimo_costo_compra_fecha: null },
      { id: "p-estados", organizacion_id: orgA, nombre: "Prod Estados", unidad: "PZA", tipo: "bien", costo: 100, stock_actual: 10, ultimo_costo_compra: null, ultimo_costo_compra_fecha: null },
      { id: "p-otroprov", organizacion_id: orgA, nombre: "Prod OtroProv", unidad: "PZA", tipo: "bien", costo: 100, stock_actual: 10, ultimo_costo_compra: null, ultimo_costo_compra_fecha: null },
      { id: "p-orgb", organizacion_id: orgB, nombre: "Prod OrgB", unidad: "PZA", tipo: "bien", costo: 100, stock_actual: 10, ultimo_costo_compra: null, ultimo_costo_compra_fecha: null },
    ],
    catalogo_alias_factura: [
      // Alias de orgB con mismo proveedor y descripcion (mata M10)
      { id: "al-orgb", organizacion_id: orgB, proveedor_id: provA, clave_sat: "", descripcion_normalizada: "sin alias en orga", destino_tipo: "producto", destino_id: "p-menos60", factor_conversion: 1 },
    ],
    factura_proveedor_partidas: [
      { id: "pt-m60", organizacion_id: orgA, factura_id: facA, orden: 1, tipo: "concepto", descripcion: "Prod Menos60", cantidad: 1, clave_unidad: "H87", precio_unitario: 310, importe: 310 },
      { id: "pt-p60", organizacion_id: orgA, factura_id: facA, orden: 2, tipo: "concepto", descripcion: "Prod Mas60", cantidad: 1, clave_unidad: "H87", precio_unitario: 100, importe: 100 },
      { id: "pt-m61", organizacion_id: orgA, factura_id: facA, orden: 3, tipo: "concepto", descripcion: "Prod Menos61", cantidad: 1, clave_unidad: "H87", precio_unitario: 100, importe: 100 },
      { id: "pt-p61", organizacion_id: orgA, factura_id: facA, orden: 4, tipo: "concepto", descripcion: "Prod Mas61", cantidad: 1, clave_unidad: "H87", precio_unitario: 100, importe: 100 },
      { id: "pt-est", organizacion_id: orgA, factura_id: facA, orden: 5, tipo: "concepto", descripcion: "Prod Estados", cantidad: 1, clave_unidad: "H87", precio_unitario: 100, importe: 100 },
      { id: "pt-opv", organizacion_id: orgA, factura_id: facA, orden: 6, tipo: "concepto", descripcion: "Prod OtroProv", cantidad: 1, clave_unidad: "H87", precio_unitario: 100, importe: 100 },
      { id: "pt-orba", organizacion_id: orgA, factura_id: facA, orden: 7, tipo: "concepto", descripcion: "Sin alias en orgA", cantidad: 1, clave_unidad: "H87", precio_unitario: 100, importe: 100 },
      { id: "pt-desc", organizacion_id: orgA, factura_id: facA, orden: 8, tipo: "descuento", descripcion: "Descuento comercial", cantidad: 1, clave_unidad: "H87", precio_unitario: 10, importe: 10 },
      { id: "pt-lr", organizacion_id: orgA, factura_id: facLigadaRec, orden: 1, tipo: "concepto", descripcion: "Prod Menos60", cantidad: 1, clave_unidad: "H87", precio_unitario: 100, importe: 100 },
      { id: "pt-lp", organizacion_id: orgA, factura_id: facLigadaPend, orden: 1, tipo: "concepto", descripcion: "Prod Menos60", cantidad: 1, clave_unidad: "H87", precio_unitario: 100, importe: 100 },
    ],
    almacen_recepcion_lineas: [
      // Linea inactiva (anulada) en pt-m60 NO debe marcarla como ya_recibida (mata M13)
      { id: "rl-inact", organizacion_id: orgA, partida_id: "pt-m60", activa: false },
      // Linea activa en pt-p60 SI debe marcarla como ya_recibida
      { id: "rl-act", organizacion_id: orgA, partida_id: "pt-p60", activa: true },
    ],
    compras_proveedor: [
      // 2026-07-01 - 60d = 2026-05-02 (SI dentro de ventana; mata M2)
      { id: "oc-m60", organizacion_id: orgA, proveedor_id: provA, folio: "OC-M60", estado: "Recibida", fecha: "2026-05-02" },
      // 2026-07-01 + 60d = 2026-08-30 (SI dentro de ventana hacia adelante; mata M2 y M3)
      { id: "oc-p60", organizacion_id: orgA, proveedor_id: provA, folio: "OC-P60", estado: "Recibida", fecha: "2026-08-30" },
      // 2026-07-01 - 61d = 2026-05-01 (NO dentro de ventana; mata M1)
      { id: "oc-m61", organizacion_id: orgA, proveedor_id: provA, folio: "OC-M61", estado: "Recibida", fecha: "2026-05-01" },
      // 2026-07-01 + 61d = 2026-08-31 (NO dentro de ventana; mata M1 y M3)
      { id: "oc-p61", organizacion_id: orgA, proveedor_id: provA, folio: "OC-P61", estado: "Recibida", fecha: "2026-08-31" },
      // Estados Pendiente y Cancelada dentro de ventana (NO duplican; mata M4)
      { id: "oc-pend", organizacion_id: orgA, proveedor_id: provA, folio: "OC-PEND", estado: "Pendiente", fecha: "2026-07-01" },
      { id: "oc-canc", organizacion_id: orgA, proveedor_id: provA, folio: "OC-CANC", estado: "Cancelada", fecha: "2026-07-01" },
      // Otro proveedor en misma fecha (NO duplica; mata M6)
      { id: "oc-opv", organizacion_id: orgA, proveedor_id: provOtro, folio: "OC-OPV", estado: "Recibida", fecha: "2026-07-01" },
      // Compras ligadas para compra_ya_recibida (mata M5)
      { id: "oc-lig-rec", organizacion_id: orgA, proveedor_id: provA, folio: "OC-LIG-REC", estado: "Recibida", fecha: "2026-01-01" },
      { id: "oc-lig-pend", organizacion_id: orgA, proveedor_id: provA, folio: "OC-LIG-PEND", estado: "Pendiente", fecha: "2026-01-01" },
    ],
    compra_items: [
      { id: "ci-1", compra_id: "oc-m60", material_id: "p-menos60" },
      { id: "ci-2", compra_id: "oc-p60", material_id: "p-mas60" },
      { id: "ci-3", compra_id: "oc-m61", material_id: "p-menos61" },
      { id: "ci-4", compra_id: "oc-p61", material_id: "p-mas61" },
      { id: "ci-5", compra_id: "oc-pend", material_id: "p-estados" },
      { id: "ci-6", compra_id: "oc-canc", material_id: "p-estados" },
      { id: "ci-7", compra_id: "oc-opv", material_id: "p-otroprov" },
    ],
  }) as unknown as Parameters<typeof obtenerPropuestaRecepcionAlmacen>[0];

  // Aislamiento de factura por org (mata M8)
  await assertRejects(() => obtenerPropuestaRecepcionAlmacen(mock, orgB, facA), AlmacenRecepcionError, "Factura no encontrada");

  const prop = await obtenerPropuestaRecepcionAlmacen(mock, orgA, facA);
  // Aislamiento de productos por org (mata M9)
  assertEquals(prop.productos.some((p) => p.id === "p-orgb"), false);
  // Descuento detectado por partida tipo='descuento' aunque cabecera sea 0 (mata M38)
  assertEquals(prop.factura.descuento_en_factura, true);
  // Ventana exacta +-60d (mata M1, M2, M3, M4, M6)
  assertEquals(prop.folios_compras_duplicadas, ["OC-M60", "OC-P60"]);
  const byId = new Map(prop.lineas.map((l) => [l.partida_id, l]));
  assertEquals(byId.get("pt-m60")!.banderas.posible_compra_duplicada, true);
  assertEquals(byId.get("pt-p60")!.banderas.posible_compra_duplicada, true);
  assertEquals(byId.get("pt-m61")!.banderas.posible_compra_duplicada, false);
  assertEquals(byId.get("pt-p61")!.banderas.posible_compra_duplicada, false);
  assertEquals(byId.get("pt-est")!.banderas.posible_compra_duplicada, false);
  assertEquals(byId.get("pt-opv")!.banderas.posible_compra_duplicada, false);
  // Linea inactiva (anulada) NO se marca ya_recibida; linea activa SI (mata M13)
  assertEquals(byId.get("pt-m60")!.banderas.ya_recibida, false);
  assertEquals(byId.get("pt-p60")!.banderas.ya_recibida, true);
  // Alias de orgB NO se usa en orgA (mata M10)
  assertEquals(byId.get("pt-orba")!.sugerencia_origen, "ninguna");
  // Diferencia de costo redondeada a 2 decimales exactos: (310-300)/300*100 = 3.33 (mata M37)
  assertEquals(byId.get("pt-m60")!.diferencia_costo_pct, 3.33);

  // Compra ligada Recibida vs Pendiente (mata M5)
  const propLigRec = await obtenerPropuestaRecepcionAlmacen(mock, orgA, facLigadaRec);
  assertEquals(propLigRec.compra_ya_recibida, true);
  const propLigPend = await obtenerPropuestaRecepcionAlmacen(mock, orgA, facLigadaPend);
  assertEquals(propLigPend.compra_ya_recibida, false);
});

Deno.test("D1 y O2: mapeo 23503, bloqueo de editar partidas y cancelar factura con recepción activa", async () => {
  const orgA = "00000000-0000-4000-8000-000000000001";
  const provA = "11111111-1111-4111-8111-111111111111";
  const facActiva = "cccccccc-cccc-4ccc-8ccc-ccccccccccc1";
  const facAnulada = "cccccccc-cccc-4ccc-8ccc-ccccccccccc2";

  // Mapeo 23503 en ambos formateadores -> 409 (nunca 500)
  const errAlm = mapearErrorRpcAlmacen({
    code: "23503",
    message: 'update or delete on table "factura_proveedor_partidas" violates foreign key constraint "almacen_recepcion_lineas_partida_id_fkey"',
  });
  assertEquals(errAlm.status, 409);
  assertEquals(errAlm.codigo, "factura_recibida_en_almacen");

  const errCxp = formatearErrorRespuesta({
    code: "23503",
    message: 'violates foreign key constraint "almacen_recepcion_lineas_partida_id_fkey"',
  });
  assertEquals(errCxp.status, 409);
  assertEquals(errCxp.body.error.includes("anula la recepción"), true);

  // guardarFacturaConPartidasMotor bloquea 409 si hay recepción activa, y permite si está anulada
  let rpcLlamada = false;
  const mockCxp = crearMockSupabase(
    {
      facturas_proveedor: [
        { id: facActiva, organizacion_id: orgA, estado: "abierta", pagos: [] },
        { id: facAnulada, organizacion_id: orgA, estado: "abierta", pagos: [] },
      ],
      almacen_recepciones: [
        { id: "r-act", organizacion_id: orgA, factura_id: facActiva, estado: "recibida" },
        { id: "r-anu", organizacion_id: orgA, factura_id: facAnulada, estado: "anulada" },
      ],
    },
    () => {
      rpcLlamada = true;
      return { id: facAnulada };
    },
  );
  // Agregar soporte mínimo a .single() y .update().eq().eq().select().single() para cancelarFactura
  const origFrom = (mockCxp as any).from.bind(mockCxp);
  (mockCxp as any).from = (table: string) => {
    const q = origFrom(table);
    q.single = () => q.maybeSingle();
    q.update = (vals: Record<string, unknown>) => ({
      eq: () => ({
        eq: () => ({
          select: () => ({
            single: async () => ({ data: { id: facAnulada, ...vals }, error: null }),
          }),
        }),
      }),
    });
    return q;
  };

  await assertRejects(
    () =>
      guardarFacturaConPartidasMotor(mockCxp, orgA, facActiva, {
        proveedor_id: provA,
        folio: "F-ACT",
        fecha_emision: "2026-11-20",
        moneda: "MXN",
        importe: 110,
        partidas: [{ tipo: "concepto", descripcion: "Tornillo", cantidad: 11, precio_unitario: 10, importe: 110 }],
      }),
    Error,
    "anula la recepción",
  );
  assertEquals(rpcLlamada, false);

  await guardarFacturaConPartidasMotor(mockCxp, orgA, facAnulada, {
    proveedor_id: provA,
    folio: "F-ANU",
    fecha_emision: "2026-11-20",
    moneda: "MXN",
    importe: 110,
    partidas: [{ tipo: "concepto", descripcion: "Tornillo", cantidad: 11, precio_unitario: 10, importe: 110 }],
  });
  assertEquals(rpcLlamada, true);

  // O2: cancelarFactura bloquea 409 con recepción activa y permite tras anularla
  await assertRejects(
    () => cancelarFactura(mockCxp, orgA, facActiva),
    Error,
    "Anula la recepción primero",
  );
  const canc = await cancelarFactura(mockCxp, orgA, facAnulada);
  assertEquals(canc.estado, "cancelada");
});
