import { assertEquals } from "jsr:@std/assert@1";
import {
  estatusParcialidad,
  imputarCobrosAParcialidades,
  redondear2,
  repartirEnPartesIguales,
  saldoCotizacion,
  traducirErrorCobros,
  validarAplicaciones,
  validarDatosCobro,
  validarPlanParcialidades,
} from "../../../../src/app/utils/cobros.ts";

Deno.test("redondear2 maneja centavos sin -0 ni deriva binaria", () => {
  assertEquals(redondear2(33333.335), 33333.34);
  assertEquals(redondear2(-0), 0);
  assertEquals(redondear2(NaN), 0);
});

Deno.test("saldoCotizacion: 3 pagos de 33,333.33 sobre 100,000 dejan 0.01 pendiente y excluyen anulados", () => {
  const res = saldoCotizacion(100000, [
    { monto: 33333.33, estado: "vigente" },
    { monto: 33333.33, estado: "vigente" },
    { monto: 33333.33, estado: "vigente" },
    { monto: 50000, estado: "anulado" },
  ]);
  assertEquals(res.cobrado, 99999.99);
  assertEquals(res.saldo, 0.01);
  assertEquals(res.saldo_a_favor, 0);
});

Deno.test("saldoCotizacion: excedente genera saldo_a_favor", () => {
  const res = saldoCotizacion(100000, [{ monto: 115000, estado: "vigente" }]);
  assertEquals(res.cobrado, 115000);
  assertEquals(res.saldo, 0);
  assertEquals(res.saldo_a_favor, 15000);
});

Deno.test("estatusParcialidad: vencida ayer pero no hoy", () => {
  assertEquals(estatusParcialidad(1000, 1000, "2026-11-20", "2026-11-22"), "pagada");
  assertEquals(estatusParcialidad(1000, 999.995, "2026-11-20", "2026-11-22"), "pagada");
  assertEquals(estatusParcialidad(1000, 500, "2026-11-21", "2026-11-22"), "vencida");
  assertEquals(estatusParcialidad(1000, 500, "2026-11-22", "2026-11-22"), "parcial");
  assertEquals(estatusParcialidad(1000, 1, "2026-11-22", "2026-11-22"), "parcial");
  assertEquals(estatusParcialidad(1000, 0.004, "2026-11-22", "2026-11-22"), "pendiente");
  assertEquals(estatusParcialidad(1000, 0, "2026-11-22", "2026-11-22"), "pendiente");
});

Deno.test("imputarCobrosAParcialidades: orden FIFO por fecha y numero sin mutar entrada", () => {
  const entrada = [
    { numero: 2, fecha_vencimiento: "2026-11-25", monto: 30000 },
    { numero: 1, fecha_vencimiento: "2026-11-10", monto: 30000 },
    { numero: 3, fecha_vencimiento: "2026-12-01", monto: 40000 },
  ];
  const out = imputarCobrosAParcialidades(entrada, 40000, "2026-11-22");
  assertEquals(entrada[0].numero, 2); // no mutado
  assertEquals(out[0].numero, 1);
  assertEquals(out[0].estatus, "pagada");
  assertEquals(out[0].monto_cubierto, 30000);
  assertEquals(out[1].numero, 2);
  assertEquals(out[1].estatus, "parcial");
  assertEquals(out[1].monto_cubierto, 10000);
  assertEquals(out[1].monto_pendiente, 20000);
  assertEquals(out[2].estatus, "pendiente");
});

Deno.test("repartirEnPartesIguales: 100,000 entre 3 suma exactamente 100,000", () => {
  const rep = repartirEnPartesIguales(100000, ["o1", "o2", "o3"]);
  assertEquals(rep, [
    { orden_trabajo_id: "o1", monto: 33333.34 },
    { orden_trabajo_id: "o2", monto: 33333.33 },
    { orden_trabajo_id: "o3", monto: 33333.33 },
  ]);
  assertEquals(repartirEnPartesIguales(0, ["o1"]), []);
  assertEquals(repartirEnPartesIguales(100, []), []);
});

Deno.test("validarAplicaciones: detecta duplicados, montos <= 0, orden invalida y exceso", () => {
  const validas = new Set(["o1", "o2"]);
  assertEquals(validarAplicaciones(1000, [{ orden_trabajo_id: "o1", monto: 600 }, { orden_trabajo_id: "o2", monto: 400 }], validas).valido, true);
  assertEquals(validarAplicaciones(1000, [{ orden_trabajo_id: "o1", monto: 600 }, { orden_trabajo_id: "o1", monto: 400 }], validas).valido, false);
  assertEquals(validarAplicaciones(1000, [{ orden_trabajo_id: "o3", monto: 500 }], validas).valido, false);
  assertEquals(validarAplicaciones(1000, [{ orden_trabajo_id: "o1", monto: 0 }], validas).valido, false);
  assertEquals(validarAplicaciones(1000, [{ orden_trabajo_id: "o1", monto: 1001 }], validas).valido, false);
});

Deno.test("validarPlanParcialidades: valida suma contra limite y formato de fecha", () => {
  assertEquals(
    validarPlanParcialidades([{ numero: 1, fecha_vencimiento: "2026-12-01", monto: 50000 }], 100000).valido,
    true,
  );
  assertEquals(
    validarPlanParcialidades([{ numero: 1, fecha_vencimiento: "2026-12-01", monto: 100001 }], 100000).valido,
    false,
  );
  assertEquals(
    validarPlanParcialidades([{ numero: 1, fecha_vencimiento: "01/12/2026", monto: 50000 }], 100000).valido,
    false,
  );
  assertEquals(validarPlanParcialidades([], 100000).valido, false);
});

Deno.test("validarDatosCobro: especie sin descripcion y excedente con/sin confirmacion", () => {
  assertEquals(
    validarDatosCobro({ monto: 1000, tipo_pago: "Especie", descripcion_especie: "   ", saldoPendiente: 5000 }).valido,
    false,
  );
  const sinConf = validarDatosCobro({ monto: 6000, tipo_pago: "Transferencia", saldoPendiente: 5000, permitirSaldoAFavor: false });
  assertEquals(sinConf.valido, false);
  assertEquals(sinConf.requiereConfirmacionSaldoAFavor, true);
  assertEquals(sinConf.excedente, 1000);

  const conConf = validarDatosCobro({ monto: 6000, tipo_pago: "Transferencia", saldoPendiente: 5000, permitirSaldoAFavor: true });
  assertEquals(conConf.valido, true);
  assertEquals(conConf.excedente, 1000);
});

Deno.test("traducirErrorCobros: mapea codigos de error conocidos", () => {
  assertEquals(traducirErrorCobros(new Error("saldo_excedido: xyz")).includes("saldo a favor"), true);
  assertEquals(traducirErrorCobros(new Error("cotizacion_no_cobrable")).includes("aprobadas"), true);
  assertEquals(traducirErrorCobros(new Error("especie_sin_descripcion")).includes("especie"), true);
});
