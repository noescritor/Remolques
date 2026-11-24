import { assertEquals, assertRejects } from "jsr:@std/assert";
import {
  AceroCfdiError,
  aplicarPreciosAceroCfdi,
  clasificarUnidadCfdi,
  eliminarCatalogoAlias,
  evaluarBanderas,
  listarCatalogoAlias,
  mapearErrorRpcAceroCfdi,
  normalizarDescripcion,
  obtenerPropuestaAceroCfdi,
  precioBaseSinIva,
  precioDesdeConcepto,
  sugerirMaterial,
} from "./acero_cfdi.ts";
import { compararProveedores } from "../../../../src/app/utils/aceroCalc.ts";

// Cliente Supabase simulado para pruebas de aislamiento, paginación y propuesta
function crearMockSupabase(tablas: Record<string, Record<string, unknown>[]>, rpcHandler?: (fn: string, args: Record<string, unknown>) => unknown) {
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
      let isDelete = false;
      let rangeStart: number | null = null;
      let rangeEnd: number | null = null;

      const exec = () => {
        const rows = state[table] || [];
        const matched = rows.filter((r) => filters.every((f) => f(r)));
        if (isDelete) {
          state[table] = rows.filter((r) => !filters.every((f) => f(r)));
          return matched;
        }
        if (rangeStart !== null && rangeEnd !== null) {
          return matched.slice(rangeStart, rangeEnd + 1);
        }
        return matched;
      };

      const builder: Record<string, unknown> = {
        select() { return builder; },
        delete() { isDelete = true; return builder; },
        eq(col: string, val: unknown) {
          filters.push((r) => r[col] === val);
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

Deno.test("normalizarDescripcion: acentos, comillas, espacios y simbolos", () => {
  assertEquals(normalizarDescripcion('  Lámina   Negra  Cal. 10 "4X10\'"  '), "lamina negra cal. 10 4x10");
  assertEquals(normalizarDescripcion("PTR de 2X4\" Cal. 9"), "ptr de 2x4 cal. 9");
});

Deno.test("clasificarUnidadCfdi: H87 pieza, KGM peso requiere factor, MTR revisar unidad", () => {
  assertEquals(clasificarUnidadCfdi("H87"), { tipo: "pieza", requiere_factor: false, revisar_unidad: false });
  assertEquals(clasificarUnidadCfdi("kgm"), { tipo: "peso", requiere_factor: true, revisar_unidad: false });
  assertEquals(clasificarUnidadCfdi("MTR"), { tipo: "otra", requiere_factor: false, revisar_unidad: true });
});

Deno.test("sugerirMaterial: medidas, umbral 0.45, margen 0.05 exacto y contradicciones (O3)", () => {
  const catalogo = [
    { id: "m1", nombre: 'Placa de grado A-36 de 1/4" en 4X10\'', tipo: "placa" },
    { id: "m2", nombre: 'Placa de grado A-36 de 1/4" en 5X10\'', tipo: "placa" },
    { id: "m3", nombre: 'Canal "U" de 6" (12Kg) a 6.10m', tipo: "canal" },
    { id: "m4", nombre: 'PTR de 4" Cal. 11', tipo: "ptr" },
    { id: "m5", nombre: "Lamina Negra Cal. 10 4X10'", tipo: "lamina" },
  ];

  // Coincidencia clara por medida 5x10
  const r1 = sugerirMaterial("PLACA ACERO A-36 1/4 5X10", null, catalogo);
  assertEquals(r1.material_id, "m2");

  // Empate cuando faltan medidas discriminadoras -> null
  const rEmpate = sugerirMaterial("PLACA GRADO A-36 1/4", null, catalogo);
  assertEquals(rEmpate.material_id, null);
  assertEquals(rEmpate.empatado, true);

  // Bajo puntaje (flete) -> null
  const rFlete = sugerirMaterial("FLETE TERRESTRE SERVICIO LOGISTICA", null, catalogo);
  assertEquals(rFlete.material_id, null);

  // Puntaje entre 0.30 y 0.45 debe dar null (mata M3: 0.45 -> 0.30)
  // "placa acero especial corte cnc industrial" vs "placa acero a36" -> comparten placa(2)+acero(1)=3, union=2+1+4+3=10 -> 0.333..0.375
  const rBajoUmbral = sugerirMaterial("PLACA ACERO ESPECIAL CORTE INDUSTRIAL", null, [
    { id: "mx", nombre: "Placa Acero Estructural", tipo: "placa" },
  ]);
  assertEquals(rBajoUmbral.material_id, null);
  assertEquals(rBajoUmbral.puntaje > 0.30 && rBajoUmbral.puntaje < 0.45, true);

  // Diferencia exacta de 0.05 en IEEE-754 (0.5 - 0.45 === 0.05) NO debe marcar empate (mata M5: < -> <=)
  // Palabras sin dígitos (peso=1 c/u) + ptr (peso=2) => descPeso=20; matA=10/20=0.50; matB=9/20=0.45 => diff=0.05 exacto
  const desc20 = "ptr aa bb cc dd ee ff gg hh ii jj kk ll mm nn oo pp qq rr";
  const rMargenExacto = sugerirMaterial(desc20, null, [
    { id: "a", nombre: "aa bb cc dd ee ff gg hh", tipo: "ptr" },
    { id: "b", nombre: "aa bb cc dd ee ff gg", tipo: "ptr" },
  ]);
  assertEquals(rMargenExacto.material_id, "a");
  assertEquals(rMargenExacto.empatado, false);

  // O3: contradicción de medida/calibre/acabado anula sugerencia
  assertEquals(sugerirMaterial("PTR 3X3 CAL 11", null, catalogo).material_id, null);
  assertEquals(sugerirMaterial("LAMINA GALVANIZADA CAL 18 4X10", null, catalogo).material_id, null);
});

Deno.test("precioDesdeConcepto: MXN, USD, descuento, limites 0 y redondeo a 4 decimales", () => {
  assertEquals(
    precioDesdeConcepto({ importe: 10000, cantidad: 4, moneda: "MXN", factorConversion: 1 }),
    { ok: true, precio: 2500 },
  );
  assertEquals(
    precioDesdeConcepto({ importe: 1000, cantidad: 2.5, descuento: 100, moneda: "USD", tipoCambio: 20, factorConversion: 1 }),
    { ok: true, precio: 7200 },
  );
  const sinTc = precioDesdeConcepto({ importe: 1000, cantidad: 1, moneda: "USD", tipoCambio: null, factorConversion: 1 });
  assertEquals(sinTc.ok, false);
  if (!sinTc.ok) assertEquals(sinTc.codigo, "tipo_cambio_requerido");

  assertEquals(
    precioDesdeConcepto({ importe: 1000, cantidad: 10, moneda: "MXN", factorConversion: 6.1 }),
    { ok: true, precio: 610 },
  );
  // Límites importe = 0 y cantidad = 0 con mensaje específico (mata M12 y M13)
  const impCero = precioDesdeConcepto({ importe: 0, cantidad: 1, moneda: "MXN", factorConversion: 1 });
  assertEquals(impCero.ok, false);
  assertEquals(impCero.error?.includes("importe"), true);
  const cantCero = precioDesdeConcepto({ importe: 100, cantidad: 0, moneda: "MXN", factorConversion: 1 });
  assertEquals(cantCero.ok, false);
  assertEquals(cantCero.error?.includes("cantidad"), true);
  // Redondeo a 4 decimales (mata M20)
  assertEquals(
    precioDesdeConcepto({ importe: 100, cantidad: 3, moneda: "MXN", factorConversion: 1 }),
    { ok: true, precio: 33.3333 },
  );
});

Deno.test("evaluarBanderas: base comun sin IVA (D1 C1/C2), umbrales +29/+30/+31%, fecha y KGM", () => {
  // D1 C1: precio actual 5473.75 CON IVA (= 4718.75 sin IVA), nuevo 3800 sin IVA => -19.47% (NO alta)
  assertEquals(Math.round((precioBaseSinIva(5473.75, true) || 0) * 100) / 100, 4718.75);
  const c1 = evaluarBanderas({
    precioNuevo: 3800, precioActual: 5473.75, precioActualIncluyeIva: true,
    fechaFactura: "2026-11-20", fechaUltimoPrecioCfdi: null,
    yaAplicada: false, descuentoEnFactura: false, claveUnidad: "H87", factorCapturado: true, moneda: "MXN",
  });
  assertEquals(c1.variacion_alta, false);
  assertEquals(c1.variacion_pct, -19.47);

  // D1 C2: precio actual 5473.75 CON IVA (= 4718.75 sin IVA), nuevo 6500 sin IVA => +37.75% (ALTA)
  const c2 = evaluarBanderas({
    precioNuevo: 6500, precioActual: 5473.75, precioActualIncluyeIva: true,
    fechaFactura: "2026-11-20", fechaUltimoPrecioCfdi: null,
    yaAplicada: false, descuentoEnFactura: false, claveUnidad: "H87", factorCapturado: true, moneda: "MXN",
  });
  assertEquals(c2.variacion_alta, true);
  assertEquals(c2.variacion_pct, 37.75);

  // Con incluye_iva = false, umbrales exactos +29%, +30%, +31%
  const b29 = evaluarBanderas({
    precioNuevo: 1290, precioActual: 1000, precioActualIncluyeIva: false,
    fechaFactura: "2026-11-20", fechaUltimoPrecioCfdi: "2026-11-20",
    yaAplicada: false, descuentoEnFactura: false, claveUnidad: "H87", factorCapturado: true, moneda: "MXN",
  });
  assertEquals(b29.variacion_alta, false);
  assertEquals(b29.fecha_anterior, false);

  const b30 = evaluarBanderas({
    precioNuevo: 1300, precioActual: 1000, precioActualIncluyeIva: false,
    fechaFactura: "2026-11-20", fechaUltimoPrecioCfdi: "2026-11-20",
    yaAplicada: false, descuentoEnFactura: false, claveUnidad: "H87", factorCapturado: true, moneda: "MXN",
  });
  assertEquals(b30.variacion_alta, false);

  const b31 = evaluarBanderas({
    precioNuevo: 1310, precioActual: 1000, precioActualIncluyeIva: false,
    fechaFactura: "2026-11-19", fechaUltimoPrecioCfdi: "2026-11-20",
    yaAplicada: false, descuentoEnFactura: true, claveUnidad: "KGM", factorCapturado: false, moneda: "MXN",
  });
  assertEquals(b31.variacion_alta, true);
  assertEquals(b31.fecha_anterior, true);
  assertEquals(b31.bloqueada_unidad, true);
  assertEquals(b31.descuento_en_factura, true);
});

Deno.test("mapearErrorRpcAceroCfdi y aplicarPreciosAceroCfdi: validaciones, default guardar_alias y factor omitido", async () => {
  assertEquals(mapearErrorRpcAceroCfdi(new Error("partida_ya_aplicada: x")).status, 409);
  assertEquals(mapearErrorRpcAceroCfdi(new Error("fecha_anterior_a_ultimo_cfdi: x")).status, 409);
  assertEquals(mapearErrorRpcAceroCfdi(new Error("variacion_precio_alta: x")).status, 409);
  assertEquals(mapearErrorRpcAceroCfdi(new Error("proveedor_conflicto: x")).status, 409);
  assertEquals(mapearErrorRpcAceroCfdi({ code: "40P01", message: "deadlock detected" }).status, 409);
  assertEquals(mapearErrorRpcAceroCfdi(new Error("factura_no_encontrada: x")).status, 404);
  assertEquals(mapearErrorRpcAceroCfdi(new Error("factor_requerido: x")).status, 400);
  assertEquals(mapearErrorRpcAceroCfdi(new Error("factor_invalido: x")).status, 400);
  assertEquals(mapearErrorRpcAceroCfdi({ code: "22P02", message: "invalid" }).status, 400);

  const facUuid = "11111111-1111-4111-8111-111111111111";
  const partUuid = "11111111-1111-4111-8111-111111111112";
  const matUuid = "11111111-1111-4111-8111-111111111113";

  let capturedRpcArgs: Record<string, unknown> | null = null;
  const mock = crearMockSupabase({}, (_fn, args) => {
    capturedRpcArgs = args;
    return { ok: true, total: 1, aplicadas: [] };
  }) as unknown as Parameters<typeof aplicarPreciosAceroCfdi>[0];

  // UUID inválido
  await assertRejects(
    () => aplicarPreciosAceroCfdi(mock, "org-1", "u1", "no-uuid", [{ partida_id: partUuid, material_id: matUuid, proveedor_acero: "TPI" }]),
    AceroCfdiError,
    "no es válido",
  );
  // Líneas vacías con UUID válido (mata M29)
  await assertRejects(
    () => aplicarPreciosAceroCfdi(mock, "org-1", "u1", facUuid, []),
    AceroCfdiError,
    "al menos una partida",
  );
  // Factor 0 rechazado (mata M30)
  await assertRejects(
    () => aplicarPreciosAceroCfdi(mock, "org-1", "u1", facUuid, [
      { partida_id: partUuid, material_id: matUuid, proveedor_acero: "TPI", factor_conversion: 0 },
    ]),
    AceroCfdiError,
    "mayor a cero",
  );
  // Default guardar_alias = true (mata M19), proveedor normalizado (O2), y factor omitido NO se vuelve 1 (D3)
  await aplicarPreciosAceroCfdi(mock, "org-1", "u1", facUuid, [
    { partida_id: partUuid, material_id: matUuid, proveedor_acero: "  tpi  " },
  ]);
  const lineaEnviada = (capturedRpcArgs!.p_lineas as Array<Record<string, unknown>>)[0];
  assertEquals(lineaEnviada.guardar_alias, true);
  assertEquals(lineaEnviada.proveedor_acero, "TPI");
  assertEquals("factor_conversion" in lineaEnviada, false);
});

Deno.test("obtenerPropuestaAceroCfdi: aislamiento org, inactivos, descuento, alias/destino_tipo/factor/proveedor y paginacion (D4)", async () => {
  const orgA = "00000000-0000-4000-8000-000000000001";
  const orgB = "00000000-0000-4000-8000-000000000002";
  const facA = "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1";
  const facB = "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb1";
  const provA = "cccccccc-cccc-4ccc-8ccc-ccccccccccc1";

  // 1001 partidas en facA para probar paginación > 1000 (mata M24)
  const partidas: Record<string, unknown>[] = [
    { id: "p-1", organizacion_id: orgA, factura_id: facA, orden: 1, tipo: "concepto", descripcion: "PLACA ESPECIAL ALIAS", cantidad: 10, precio_unitario: 20, importe: 200, clave_sat: "30102200", clave_unidad: "KGM" },
    { id: "p-2", organizacion_id: orgA, factura_id: facA, orden: 2, tipo: "concepto", descripcion: "SOLERA INACTIVA 1/2 X 3", cantidad: 1, precio_unitario: 100, importe: 100, clave_sat: null, clave_unidad: "H87" },
    { id: "p-3", organizacion_id: orgA, factura_id: facA, orden: 3, tipo: "concepto", descripcion: "TORNILLO PRODUCTO BLOQUE G", cantidad: 1, precio_unitario: 50, importe: 50, clave_sat: null, clave_unidad: "H87" },
  ];
  for (let i = 4; i <= 1001; i++) {
    partidas.push({
      id: `p-${i}`, organizacion_id: orgA, factura_id: facA, orden: i, tipo: "concepto",
      descripcion: `FLETE EXTRA ${i}`, cantidad: 1, precio_unitario: 10, importe: 10, clave_sat: null, clave_unidad: "E48",
    });
  }

  const mock = crearMockSupabase({
    facturas_proveedor: [
      // Factura A con descuento > 0.005 (sin fila tipo=descuento) para matar M22
      { id: facA, organizacion_id: orgA, proveedor_id: provA, folio: "FA-1", fecha_emision: "2026-11-20", moneda: "MXN", tipo_cambio_emision: null, uuid_fiscal: "U-1", descuento: 15.5, estado: "abierta" },
      // Factura B de otra organización para matar M23
      { id: facB, organizacion_id: orgB, proveedor_id: null, folio: "FB-1", fecha_emision: "2026-11-20", moneda: "MXN", tipo_cambio_emision: null, uuid_fiscal: "U-2", descuento: 0, estado: "abierta" },
    ],
    factura_proveedor_partidas: partidas,
    acero_materiales: [
      { id: "mat-act", organizacion_id: orgA, nombre: 'Placa de grado A-36 de 1/4" en 4X10\'', tipo: "placa", activo: true },
      // Material inactivo con nombre exacto de p-2 para matar M21
      { id: "mat-inact", organizacion_id: orgA, nombre: "Solera Inactiva 1/2 X 3", tipo: "solera", activo: false },
    ],
    acero_precios: [
      { material_id: "mat-act", proveedor: "FORTACERO", precio: 1000, incluye_iva: false },
    ],
    catalogo_alias_factura: [
      // Alias con clave_sat = null (fallback clave vacía mata M25), factor 42.5 (mata M26), proveedor FORTACERO (mata M27)
      { id: "al-1", organizacion_id: orgA, proveedor_id: provA, clave_sat: null, descripcion_normalizada: "placa especial alias", destino_tipo: "acero_material", destino_id: "mat-act", proveedor_acero: "FORTACERO", factor_conversion: 42.5 },
      // Alias de otro destino_tipo ('producto' para Bloque G) que NO debe mezclarse (mata M28)
      { id: "al-2", organizacion_id: orgA, proveedor_id: provA, clave_sat: null, descripcion_normalizada: "tornillo producto bloque g", destino_tipo: "producto", destino_id: "prod-99", proveedor_acero: "OTRO", factor_conversion: 1 },
    ],
    acero_precios_cfdi_aplicados: [],
    proveedores: [{ id: provA, organizacion_id: orgA, nombre: "SERVIACERO", rfc: "SCO900101AAA" }],
  }) as unknown as Parameters<typeof obtenerPropuestaAceroCfdi>[0];

  // Aislamiento de factura ajena (mata M23)
  await assertRejects(
    () => obtenerPropuestaAceroCfdi(mock, orgA, facB),
    AceroCfdiError,
    "Factura no encontrada",
  );

  const prop = await obtenerPropuestaAceroCfdi(mock, orgA, facA);
  // Paginación > 1000 (mata M24)
  assertEquals(prop.lineas.length, 1001);
  // Aviso de descuento por cabecera factura.descuento (mata M22)
  assertEquals(prop.factura.descuento_en_factura, true);
  // Materiales inactivos excluidos (mata M21)
  assertEquals(prop.materiales.length, 1);
  assertEquals(prop.lineas[1].material_id_sugerido, null);
  // Alias fallback clave_sat vacía + factor + proveedor (mata M25, M26, M27)
  assertEquals(prop.lineas[0].sugerencia_origen, "alias");
  assertEquals(prop.lineas[0].material_id_sugerido, "mat-act");
  assertEquals(prop.lineas[0].factor_conversion_sugerido, 42.5);
  assertEquals(prop.lineas[0].precio_neto_mxn, 850); // (200/10) * 42.5
  assertEquals(prop.lineas[0].proveedor_acero_sugerido, "FORTACERO");
  // Alias de destino_tipo='producto' NO se mezcla (mata M28)
  assertEquals(prop.lineas[2].sugerencia_origen, "ninguna");
  assertEquals(prop.lineas[2].material_id_sugerido, null);

  // O7: proveedorOverride sobreescribe el proveedor en la propuesta
  const propOverride = await obtenerPropuestaAceroCfdi(mock, orgA, facA, "tpi");
  assertEquals(propOverride.lineas[0].proveedor_acero_sugerido, "TPI");
});

Deno.test("listarCatalogoAlias y eliminarCatalogoAlias: aislamiento de organizacion (mata M18)", async () => {
  const orgA = "00000000-0000-4000-8000-000000000001";
  const orgB = "00000000-0000-4000-8000-000000000002";
  const alA = "11111111-1111-4111-8111-11111111111a";
  const alB = "22222222-2222-4222-8222-22222222222b";

  const mockObj = crearMockSupabase({
    catalogo_alias_factura: [
      { id: alA, organizacion_id: orgA, destino_tipo: "acero_material", destino_id: "m1", descripcion_normalizada: "a" },
      { id: alB, organizacion_id: orgB, destino_tipo: "acero_material", destino_id: "m2", descripcion_normalizada: "b" },
    ],
    acero_materiales: [{ id: "m1", organizacion_id: orgA, nombre: "Placa 1" }],
  });
  const mock = mockObj as unknown as Parameters<typeof eliminarCatalogoAlias>[0];

  const listA = await listarCatalogoAlias(mock, orgA, "acero_material");
  assertEquals(listA.length, 1);
  assertEquals(listA[0].destino_nombre, "Placa 1");

  // Org A NO puede borrar alias de Org B (mata M18)
  await assertRejects(
    () => eliminarCatalogoAlias(mock, orgA, alB),
    AceroCfdiError,
    "Alias no encontrado",
  );
  assertEquals(mockObj.state.catalogo_alias_factura.length, 2);

  // Org A SÍ puede borrar su propio alias
  const delRes = await eliminarCatalogoAlias(mock, orgA, alA);
  assertEquals(delRes.ok, true);
  assertEquals(mockObj.state.catalogo_alias_factura.length, 1);
});

Deno.test("Matriz mixta IVA: precio sin IVA (XML) vs precio con IVA (manual) en compararProveedores (incluye O1)", () => {
  const res = compararProveedores({
    renglones: [{ materialId: "m1", cantidad: 2 }],
    precios: [
      { material_id: "m1", proveedor: "SERVIACERO_XML", precio: 1000, incluye_iva: false },
      { material_id: "m1", proveedor: "TPI_MANUAL", precio: 1160, incluye_iva: true },
    ],
    incluyeIva: true,
    catalogoMateriales: { m1: { nombre: "Canal U 6" } },
  });
  const xml = res.proveedores.find((p) => p.proveedor === "SERVIACERO_XML")!;
  const man = res.proveedores.find((p) => p.proveedor === "TPI_MANUAL")!;
  assertEquals(Math.round(xml.total * 100) / 100, 2320);
  assertEquals(Math.round(man.total * 100) / 100, 2320);
  assertEquals(Math.round(xml.subtotal * 100) / 100, 2000);
  assertEquals(Math.round(man.subtotal * 100) / 100, 2000);

  // O1: Interruptor en falso ("Mostrar resultados sin IVA") con filas marcadas con incluye_iva=true y false
  const resSinIva = compararProveedores({
    renglones: [{ materialId: "m1", cantidad: 2 }],
    precios: [
      { material_id: "m1", proveedor: "SERVIACERO_XML", precio: 1000, incluye_iva: false },
      { material_id: "m1", proveedor: "TPI_MANUAL", precio: 1160, incluye_iva: true },
    ],
    incluyeIva: false,
    catalogoMateriales: { m1: { nombre: "Canal U 6" } },
  });
  const xmlSin = resSinIva.proveedores.find((p) => p.proveedor === "SERVIACERO_XML")!;
  const manSin = resSinIva.proveedores.find((p) => p.proveedor === "TPI_MANUAL")!;
  assertEquals(xmlSin.renglones[0].precioUnitario, 1000);
  assertEquals(manSin.renglones[0].precioUnitario, 1000);
  assertEquals(xmlSin.subtotal, 2000);
  assertEquals(manSin.subtotal, 2000);
  assertEquals(xmlSin.total, 2320);
  assertEquals(manSin.total, 2320);

  // $1,000 sin IVA (= $1,160 con IVA) vs $1,100 con IVA: el más barato real es TPI_MANUAL ($1,100)
  const res2 = compararProveedores({
    renglones: [{ materialId: "m1", cantidad: 1 }],
    precios: [
      { material_id: "m1", proveedor: "SERVIACERO_XML", precio: 1000, incluye_iva: false },
      { material_id: "m1", proveedor: "TPI_MANUAL", precio: 1100, incluye_iva: true },
    ],
    incluyeIva: true,
    catalogoMateriales: { m1: { nombre: "Canal U 6" } },
  });
  assertEquals(res2.mejorProveedorCompleto?.proveedor, "TPI_MANUAL");
  assertEquals(res2.mejorPorRenglon.renglones[0].proveedor, "TPI_MANUAL");
});
