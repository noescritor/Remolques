import { assertEquals, assertRejects } from "jsr:@std/assert@1";
import {
  AceroCfdiError,
  aplicarPreciosAceroCfdi,
  clasificarUnidadCfdi,
  evaluarBanderas,
  mapearErrorRpcAceroCfdi,
  normalizarDescripcion,
  precioDesdeConcepto,
  sugerirMaterial,
} from "./acero_cfdi.ts";
import { compararProveedores } from "../../../../src/app/utils/aceroCalc.ts";

Deno.test("normalizarDescripcion: acentos, comillas, espacios y simbolos", () => {
  assertEquals(normalizarDescripcion('CANAL "U" DE 6" (15Kg) a 12.20m'), "canal u de 6 15kg a 12.20m");
  assertEquals(normalizarDescripcion("  Lámina   calibre 14  4x10 "), "lamina calibre 14 4x10");
});

Deno.test("clasificarUnidadCfdi: H87 pieza, KGM peso requiere factor, MTR revisar unidad", () => {
  assertEquals(clasificarUnidadCfdi("H87"), { tipo: "pieza", requiere_factor: false, revisar_unidad: false });
  assertEquals(clasificarUnidadCfdi("KGM"), { tipo: "peso", requiere_factor: true, revisar_unidad: false });
  assertEquals(clasificarUnidadCfdi("MTR"), { tipo: "otra", requiere_factor: false, revisar_unidad: true });
});

Deno.test("sugerirMaterial: peso fuerte a medidas, empate devuelve null, bajo puntaje devuelve null", () => {
  const materiales = [
    { id: "m1", nombre: 'Canal "U" de 6" (15Kg) a 12.20m', tipo: "canal" },
    { id: "m2", nombre: 'Canal "U" de 6" (12Kg) a 12.20m', tipo: "canal" },
    { id: "m3", nombre: 'Placa 3/16" 4x10', tipo: "placa" },
  ];
  const s1 = sugerirMaterial('CANAL "U" DE 6" 15KG 12.20M', "30101804", materiales);
  assertEquals(s1.material_id, "m1");

  // Empate entre 15Kg y 12Kg -> null (mejor vacio que equivocado)
  const sEmpate = sugerirMaterial('CANAL U 6 12.20M', "30101804", materiales);
  assertEquals(sEmpate.material_id, null);
  assertEquals(sEmpate.empatado, true);

  // Flete no coincide con ningun material
  const sFlete = sugerirMaterial("SERVICIO DE FLETE Y MANIOBRAS", "78101800", materiales);
  assertEquals(sFlete.material_id, null);
});

Deno.test("precioDesdeConcepto: MXN, USD con/sin TC, descuento, cantidad fraccionaria y factor 6.1", () => {
  // MXN simple
  assertEquals(
    precioDesdeConcepto({ importe: 9600, cantidad: 2, moneda: "MXN", factorConversion: 1 }),
    { ok: true, precio: 4800 },
  );
  // USD con TC y descuento y cantidad fraccionaria
  assertEquals(
    precioDesdeConcepto({ importe: 1000, cantidad: 2.5, descuento: 100, moneda: "USD", tipoCambio: 20, factorConversion: 1 }),
    { ok: true, precio: 7200 },
  );
  // USD sin TC -> bloqueado con código explícito
  const sinTc = precioDesdeConcepto({ importe: 1000, cantidad: 1, moneda: "USD", tipoCambio: null, factorConversion: 1 });
  assertEquals(sinTc.ok, false);
  if (!sinTc.ok) assertEquals(sinTc.codigo, "tipo_cambio_requerido");
  // Factor 6.1 (ej. barra 6.1m o kg/pieza)
  assertEquals(
    precioDesdeConcepto({ importe: 1000, cantidad: 10, moneda: "MXN", factorConversion: 6.1 }),
    { ok: true, precio: 610 },
  );
});

Deno.test("evaluarBanderas: umbrales +29%, +30%, +31%, fecha anterior vs igual y KGM sin factor", () => {
  const b29 = evaluarBanderas({
    precioNuevo: 1290, precioActual: 1000, fechaFactura: "2026-11-20", fechaUltimoPrecioCfdi: "2026-11-20",
    yaAplicada: false, descuentoEnFactura: false, claveUnidad: "H87", factorCapturado: true, moneda: "MXN",
  });
  assertEquals(b29.variacion_alta, false);
  assertEquals(b29.fecha_anterior, false);

  const b30 = evaluarBanderas({
    precioNuevo: 1300, precioActual: 1000, fechaFactura: "2026-11-20", fechaUltimoPrecioCfdi: "2026-11-20",
    yaAplicada: false, descuentoEnFactura: false, claveUnidad: "H87", factorCapturado: true, moneda: "MXN",
  });
  assertEquals(b30.variacion_alta, false);

  const b31 = evaluarBanderas({
    precioNuevo: 1310, precioActual: 1000, fechaFactura: "2026-11-19", fechaUltimoPrecioCfdi: "2026-11-20",
    yaAplicada: false, descuentoEnFactura: true, claveUnidad: "KGM", factorCapturado: false, moneda: "MXN",
  });
  assertEquals(b31.variacion_alta, true);
  assertEquals(b31.fecha_anterior, true);
  assertEquals(b31.bloqueada_unidad, true);
  assertEquals(b31.descuento_en_factura, true);
});

Deno.test("mapearErrorRpcAceroCfdi y validacion de entrada en aplicarPreciosAceroCfdi", async () => {
  assertEquals(mapearErrorRpcAceroCfdi(new Error("partida_ya_aplicada: x")).status, 409);
  assertEquals(mapearErrorRpcAceroCfdi(new Error("fecha_anterior_a_ultimo_cfdi: x")).status, 409);
  assertEquals(mapearErrorRpcAceroCfdi(new Error("variacion_precio_alta: x")).status, 409);
  assertEquals(mapearErrorRpcAceroCfdi(new Error("proveedor_conflicto: x")).status, 409);
  assertEquals(mapearErrorRpcAceroCfdi(new Error("factura_no_encontrada: x")).status, 404);
  assertEquals(mapearErrorRpcAceroCfdi(new Error("factor_invalido: x")).status, 400);
  assertEquals(mapearErrorRpcAceroCfdi({ code: "22P02", message: "invalid" }).status, 400);

  const dummy = {} as Parameters<typeof aplicarPreciosAceroCfdi>[0];
  await assertRejects(
    () => aplicarPreciosAceroCfdi(dummy, "org-1", "u1", "no-uuid", []),
    AceroCfdiError,
    "no es válido",
  );
  await assertRejects(
    () => aplicarPreciosAceroCfdi(dummy, "org-1", "u1", "11111111-1111-4111-8111-111111111111", [
      { partida_id: "11111111-1111-4111-8111-111111111112", material_id: "11111111-1111-4111-8111-111111111113", proveedor_acero: "TPI", factor_conversion: 0 },
    ]),
    AceroCfdiError,
    "mayor a cero",
  );
});

Deno.test("Matriz mixta IVA: precio sin IVA (XML) vs precio con IVA (manual) en compararProveedores", () => {
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
