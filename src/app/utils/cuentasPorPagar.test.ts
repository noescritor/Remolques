// @ts-nocheck
import { assertEquals, assertThrows, assert } from "https://deno.land/std@0.192.0/testing/asserts.ts";
import {
  saldoFactura,
  convertirAPesos,
  diasAtraso,
  cubeta,
  resumenCuenta,
  saldoAFecha,
  conciliar,
  usoDeCredito,
  formatearMonedaDe,
  fechaLocalISO,
  FacturaRef,
  PagoRef,
} from "./cuentasPorPagar.ts";

// ── 1. PRUEBAS DORADAS CON EL ESTADO DE CUENTA REAL DE CADECO AL 29/10/2026 ──

const FACTURAS_CADECO_GOLDEN: FacturaRef[] = [
  {
    id: "f-21644",
    folio: "21644",
    sucursal: "Suc 114",
    fecha_emision: "2026-06-03",
    fecha_vencimiento: "2026-07-03",
    moneda: "USD",
    importe: 2354.80,
    pagos: [{ monto: 2066.61, fecha_pago: "2026-07-10", anulado: false }], // Saldo: 288.19
  },
  {
    id: "f-21667",
    folio: "21667",
    sucursal: "Suc 114",
    fecha_emision: "2026-06-05",
    fecha_vencimiento: "2026-07-05",
    moneda: "USD",
    importe: 526.71,
  },
  {
    id: "f-21754",
    folio: "21754",
    sucursal: "Suc 114",
    fecha_emision: "2026-06-17",
    fecha_vencimiento: "2026-07-17",
    moneda: "USD",
    importe: 2354.80,
  },
  {
    id: "f-21788",
    folio: "21788",
    sucursal: "Suc 114",
    fecha_emision: "2026-06-19",
    fecha_vencimiento: "2026-07-19",
    moneda: "USD",
    importe: 265.08,
  },
  {
    id: "f-21815",
    folio: "21815",
    sucursal: "Suc 114",
    fecha_emision: "2026-06-23",
    fecha_vencimiento: "2026-07-23",
    moneda: "USD",
    importe: 711.90,
  },
  {
    id: "f-21839",
    folio: "21839",
    sucursal: "Suc 114",
    fecha_emision: "2026-06-26",
    fecha_vencimiento: "2026-07-26",
    moneda: "USD",
    importe: 364.56,
  },
  {
    id: "f-21882",
    folio: "21882",
    sucursal: "Suc 114",
    fecha_emision: "2026-06-30",
    fecha_vencimiento: "2026-07-30",
    moneda: "USD",
    importe: 141.84,
  },
  {
    id: "f-21899",
    folio: "21899",
    sucursal: "Suc 114",
    fecha_emision: "2026-07-01",
    fecha_vencimiento: "2026-07-31",
    moneda: "USD",
    importe: 2354.80,
  },
  {
    id: "f-21910",
    folio: "21910",
    sucursal: "Suc 114",
    fecha_emision: "2026-07-02",
    fecha_vencimiento: "2026-08-01",
    moneda: "USD",
    importe: 134.61,
  },
  {
    id: "f-21918",
    folio: "21918",
    sucursal: "Suc 114",
    fecha_emision: "2026-07-03",
    fecha_vencimiento: "2026-08-02",
    moneda: "USD",
    importe: 638.32,
  },
  {
    id: "f-21959",
    folio: "21959",
    sucursal: "Suc 114",
    fecha_emision: "2026-07-07",
    fecha_vencimiento: "2026-08-06",
    moneda: "USD",
    importe: 384.86,
  },
  {
    id: "f-22034",
    folio: "22034",
    sucursal: "Suc 114",
    fecha_emision: "2026-07-14",
    fecha_vencimiento: "2026-08-13",
    moneda: "USD",
    importe: 139.04,
  },
  {
    id: "f-22048",
    folio: "22048",
    sucursal: "Suc 114",
    fecha_emision: "2026-07-16",
    fecha_vencimiento: "2026-08-15",
    moneda: "USD",
    importe: 1102.00,
  },
  // Facturas en pesos (MXN)
  {
    id: "f-21778",
    folio: "21778",
    sucursal: "Suc 114",
    fecha_emision: "2026-06-19",
    fecha_vencimiento: "2026-07-19",
    moneda: "MXN",
    importe: 18008.07,
    pagos: [{ monto: 160.22, fecha_pago: "2026-07-10", anulado: false }], // Saldo: 17847.85
  },
  {
    id: "f-21912",
    folio: "21912",
    sucursal: "Suc 114",
    fecha_emision: "2026-07-02",
    fecha_vencimiento: "2026-08-01",
    moneda: "MXN",
    importe: 1439.93,
  },
  {
    id: "f-21919",
    folio: "21919",
    sucursal: "Suc 114",
    fecha_emision: "2026-07-03",
    fecha_vencimiento: "2026-08-02",
    moneda: "MXN",
    importe: 5935.21,
  },
];

Deno.test("cuentasPorPagar - 1. Caso dorado CADECO al 29/10/2026 (saldos, cubetas y tipos de cambio)", () => {
  const fechaCorte = "2026-10-29";

  // Verificación de días de atraso de cada factura contra el estado de cuenta
  assertEquals(diasAtraso("2026-07-03", fechaCorte), 118);
  assertEquals(diasAtraso("2026-07-05", fechaCorte), 116);
  assertEquals(diasAtraso("2026-07-17", fechaCorte), 104);
  assertEquals(diasAtraso("2026-07-19", fechaCorte), 102);
  assertEquals(diasAtraso("2026-07-23", fechaCorte), 98);
  assertEquals(diasAtraso("2026-07-26", fechaCorte), 95);
  assertEquals(diasAtraso("2026-07-30", fechaCorte), 91);
  assertEquals(diasAtraso("2026-07-31", fechaCorte), 90);
  assertEquals(diasAtraso("2026-08-01", fechaCorte), 89);
  assertEquals(diasAtraso("2026-08-02", fechaCorte), 88);
  assertEquals(diasAtraso("2026-08-06", fechaCorte), 84);
  assertEquals(diasAtraso("2026-08-13", fechaCorte), 77);
  assertEquals(diasAtraso("2026-08-15", fechaCorte), 75);

  // Resumen con TC = 19.07
  const res1907 = resumenCuenta(FACTURAS_CADECO_GOLDEN, {
    fechaCorte,
    tcUSD: 19.07,
  });

  assertEquals(res1907.saldoUSD, 9406.71);
  assertEquals(res1907.saldoMXN, 25222.99);
  assertEquals(res1907.totalFacturasAbiertas, 16);

  // Todo en la cubeta mas_60 (las otras tres en 0)
  assertEquals(res1907.antiguedad.usd.por_vencer, 0);
  assertEquals(res1907.antiguedad.usd["1_30"], 0);
  assertEquals(res1907.antiguedad.usd["31_60"], 0);
  assertEquals(res1907.antiguedad.usd.mas_60, 9406.71);

  assertEquals(res1907.antiguedad.mxn.por_vencer, 0);
  assertEquals(res1907.antiguedad.mxn["1_30"], 0);
  assertEquals(res1907.antiguedad.mxn["31_60"], 0);
  assertEquals(res1907.antiguedad.mxn.mas_60, 25222.99);

  // Con TC 19.07: equivalente = $179,385.96 y total en pesos = $204,608.95
  assertEquals(res1907.equivalenteUSDEnPesos, 179385.96);
  assertEquals(res1907.totalEnPesos, 204608.95);

  // Resumen con TC = 17.70: equivalente = $166,498.77
  const res1770 = resumenCuenta(FACTURAS_CADECO_GOLDEN, {
    fechaCorte,
    tcUSD: 17.70,
  });
  assertEquals(res1770.equivalenteUSDEnPesos, 166498.77);
  assertEquals(res1770.totalEnPesos, 191721.76);

  // Conciliación CADECO: 11,014.44 vs 9,406.71 -> diferencia 1,607.73, leolca_mayor
  const conc = conciliar(11014.44, 9406.71);
  assertEquals(conc.diferencia, 1607.73);
  assertEquals(conc.estado, "leolca_mayor");

  // Uso de crédito CADECO (límite US$ 10,000): 94.07%
  const credito = usoDeCredito(9406.71, 10000.00);
  assertEquals(credito, 94.07);
});

Deno.test("cuentasPorPagar - 2. saldoFactura con pagos parciales y pagos anulados", () => {
  // Factura de $10,000 con abono de $3,000 activo y abono de $2,000 anulado
  const saldo = saldoFactura(10000.00, [
    { monto: 3000.00, anulado: false },
    { monto: 2000.00, anulado: true },
  ]);
  assertEquals(saldo, 7000.00);

  // Factura liquidada completamente
  const saldoCero = saldoFactura(500.50, [
    { monto: 200.00, anulado: false },
    { monto: 300.50, anulado: false },
  ]);
  assertEquals(saldoCero, 0.00);
});

Deno.test("cuentasPorPagar - 3. convertirAPesos validación y redondeo", () => {
  assertEquals(convertirAPesos(100.00, "MXN", 19.50), 100.00);
  assertEquals(convertirAPesos(100.00, "MXN", null), 100.00);
  assertEquals(convertirAPesos(100.00, "USD", 19.50), 1950.00);

  // Error si USD no tiene tipo de cambio válido
  assertThrows(
    () => convertirAPesos(100.00, "USD", null),
    Error,
    "Tipo de cambio debe ser mayor a 0"
  );
  assertThrows(
    () => convertirAPesos(100.00, "USD", 0),
    Error,
    "Tipo de cambio debe ser mayor a 0"
  );
  assertThrows(
    () => convertirAPesos(100.00, "USD", -5),
    Error,
    "Tipo de cambio debe ser mayor a 0"
  );
});

Deno.test("cuentasPorPagar - 4. Precisión de centavos (0.1 + 0.2)", () => {
  const saldo = saldoFactura(0.3, [
    { monto: 0.1, anulado: false },
    { monto: 0.2, anulado: false },
  ]);
  assertEquals(saldo, 0.00);
});

Deno.test("cuentasPorPagar - 5. diasAtraso con cruce de mes y cruce de año", () => {
  // Mismo día -> 0
  assertEquals(diasAtraso("2026-10-30", "2026-10-30"), 0);
  // Por vencer (futuro) -> negativo
  assertEquals(diasAtraso("2026-11-05", "2026-10-30"), -6);
  // Vencida en mismo mes
  assertEquals(diasAtraso("2026-10-15", "2026-10-30"), 15);
  // Cruce de mes: de febrero a marzo en año no bisiesto (2026: 28 días)
  assertEquals(diasAtraso("2026-02-28", "2026-03-01"), 1);
  // Cruce de año: de 31 de diciembre 2026 al 5 de enero 2027
  assertEquals(diasAtraso("2026-12-31", "2027-01-05"), 5);
});

Deno.test("cuentasPorPagar - 6. Clasificación de cubetas", () => {
  assertEquals(cubeta(-5), "por_vencer");
  assertEquals(cubeta(0), "por_vencer");
  assertEquals(cubeta(1), "1_30");
  assertEquals(cubeta(30), "1_30");
  assertEquals(cubeta(31), "31_60");
  assertEquals(cubeta(60), "31_60");
  assertEquals(cubeta(61), "mas_60");
  assertEquals(cubeta(120), "mas_60");
});

Deno.test("cuentasPorPagar - 7. saldoAFecha con pagos y facturas posteriores a la fecha", () => {
  const facturas: FacturaRef[] = [
    { id: "1", folio: "F1", fecha_emision: "2026-10-01", fecha_vencimiento: "2026-10-15", moneda: "USD", importe: 1000 },
    { id: "2", folio: "F2", fecha_emision: "2026-10-10", fecha_vencimiento: "2026-10-25", moneda: "USD", importe: 500 },
    { id: "3", folio: "F3", fecha_emision: "2026-10-20", fecha_vencimiento: "2026-11-05", moneda: "USD", importe: 800 }, // posterior
    { id: "4", folio: "F4", fecha_emision: "2026-10-05", fecha_vencimiento: "2026-10-20", moneda: "MXN", importe: 3000 },
  ];

  const pagos: PagoRef[] = [
    { factura_id: "1", fecha_pago: "2026-10-05", monto: 400, anulado: false },
    { factura_id: "1", fecha_pago: "2026-10-25", monto: 200, anulado: false }, // posterior a corte 2026-10-15
    { factura_id: "2", fecha_pago: "2026-10-12", monto: 100, anulado: true },  // anulado
  ];

  const corte = "2026-10-15";
  const saldos = saldoAFecha(facturas, pagos, corte);
  // A esa fecha:
  // F1: importe 1000 - pago(400) = 600
  // F2: importe 500 - pagos válidos(0) = 500
  // F3: no entra (emisión 2026-10-20 > corte)
  // Total USD = 600 + 500 = 1100
  // F4: importe 3000
  // Total MXN = 3000
  assertEquals(saldos.saldoUSD, 1100.00);
  assertEquals(saldos.saldoMXN, 3000.00);
});

Deno.test("cuentasPorPagar - 8. conciliar con tolerancia de 1 centavo", () => {
  // Cuadra exacto
  assertEquals(conciliar(5000.00, 5000.00).estado, "cuadra");
  // Cuadra con 1 centavo
  assertEquals(conciliar(5000.00, 5000.01).estado, "cuadra");
  assertEquals(conciliar(5000.01, 5000.00).estado, "cuadra");

  // Proveedor mayor
  const rProv = conciliar(5000.00, 5000.05);
  assertEquals(rProv.estado, "proveedor_mayor");
  assertEquals(rProv.diferencia, 0.05);

  // Leolca mayor
  const rLeo = conciliar(5000.10, 5000.00);
  assertEquals(rLeo.estado, "leolca_mayor");
  assertEquals(rLeo.diferencia, 0.10);
});

Deno.test("cuentasPorPagar - 9. formatearMonedaDe para MXN y USD", () => {
  assertEquals(formatearMonedaDe(1234.5, "MXN"), "$1,234.50");
  assertEquals(formatearMonedaDe(1234.5, "USD"), "US$ 1,234.50");
  assertEquals(formatearMonedaDe(0, "MXN"), "$0.00");
  assertEquals(formatearMonedaDe(0, "USD"), "US$ 0.00");
});

Deno.test("cuentasPorPagar - 10. fechaLocalISO preserva fecha local a altas horas de la noche", () => {
  // 2026-10-29 a las 23:30 hora local (no debe saltar al día siguiente)
  const fechaNoche = new Date(2026, 9, 29, 23, 30, 0);
  assertEquals(fechaLocalISO(fechaNoche), "2026-10-29");

  // Cruce de año a las 23:59
  const finAno = new Date(2026, 11, 31, 23, 59, 59);
  assertEquals(fechaLocalISO(finAno), "2026-12-31");
});

