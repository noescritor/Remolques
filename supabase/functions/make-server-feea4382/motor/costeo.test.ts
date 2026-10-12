import { assertEquals, assert } from "https://deno.land/std@0.192.0/testing/asserts.ts";
import { costear, validarAjustes } from "./costeo.ts";
import * as fixtureData from "./fixtures/datos_costeo_plataforma_40x2.json" with { type: "json" };
import type { DatosCosteo, Configuracion, AjusteManual } from "./tipos.ts";

const datosBase = fixtureData.default as DatosCosteo;

Deno.test("Prueba dorada: Plataforma 40 ft 2 ejes - costeo exacto contra Excel Leolca", () => {
  const config: Configuracion = {
    grupos: {
      suspension: "fleet_master",
      eje: "fleet_master",
      patin: "hj",
      piso: "laminado_plastico",
      abs: "2e_sin_retractil"
    }
  };

  const ajustes: AjusteManual[] = [
    {
      concepto: "Líneas sin concepto en el Excel (pendiente de aclarar con el dueño)",
      cantidad: 2,
      costo_unitario: 15000
    },
    {
      concepto: "Líneas sin concepto en el Excel (pendiente de aclarar con el dueño)",
      cantidad: 1,
      costo_unitario: 1485
    }
  ];

  const res = costear(datosBase, config, ajustes);

  // Valores exactos al centavo
  assertEquals(res.secciones.acero.total, 128211.69);
  assertEquals(res.secciones.kits_fijos.total, 45685.98);
  assertEquals(res.secciones.opciones.total, 169400.96);
  assertEquals(res.secciones.mano_obra.total, 22930.00);
  assertEquals(res.secciones.ajustes.total, 31485.00);
  assertEquals(res.costo, 397713.63);
  assertEquals(res.ganancia, 110000.00);
  assertEquals(res.precio_sugerido, 507713.63);

  // Margen sobre precio ≈ 0.2166 (110,000 / 507,713.63)
  assert(res.margen_sobre_precio !== null);
  const diffMargen = Math.abs(res.margen_sobre_precio - (110000 / 507713.63));
  assert(diffMargen < 0.0001);

  // Confianza y pendientes
  assertEquals(res.confianza, "estimada");
  assertEquals(res.pendientes.length, 1);
  assertEquals(res.pendientes[0].tipo, "sin_precio");
  assert(res.pendientes[0].detalle.toLowerCase().includes("puentes de suspensión"));
});

Deno.test("Adicional 1: por_eje con 3 ejes escala proporcionalmente suspensión y ejes", () => {
  const datos3Ejes: DatosCosteo = JSON.parse(JSON.stringify(datosBase));
  datos3Ejes.modelo.num_ejes = 3;

  const config: Configuracion = {
    grupos: {
      suspension: "fleet_master",
      eje: "fleet_master"
    }
  };

  const res2 = costear(datosBase, config);
  const res3 = costear(datos3Ejes, config);

  const lineaSusp2 = res2.secciones.opciones.lineas.find(l => l.concepto.includes("suspension"));
  const lineaSusp3 = res3.secciones.opciones.lineas.find(l => l.concepto.includes("suspension"));
  assert(lineaSusp2 && lineaSusp3);
  assertEquals(lineaSusp2.cantidad, 2);
  assertEquals(lineaSusp3.cantidad, 3);
  assertEquals(lineaSusp3.importe, Math.round((lineaSusp2.importe * 1.5) * 100) / 100);

  const lineaEje2 = res2.secciones.opciones.lineas.find(l => l.concepto.includes("eje"));
  const lineaEje3 = res3.secciones.opciones.lineas.find(l => l.concepto.includes("eje"));
  assert(lineaEje2 && lineaEje3);
  assertEquals(lineaEje2.cantidad, 2);
  assertEquals(lineaEje3.cantidad, 3);
  assertEquals(lineaEje3.importe, Math.round((lineaEje2.importe * 1.5) * 100) / 100);
});

Deno.test("Adicional 2: opción elegida sin renglón en opcion_costos → pendiente opcion_sin_costo y confianza no completa", () => {
  const config: Configuracion = {
    grupos: {
      suspension: "marca_rara_no_catalogada"
    }
  };

  const res = costear(datosBase, config);
  const pendiente = res.pendientes.find(p => p.tipo === "opcion_sin_costo");
  assert(pendiente !== undefined);
  assert(pendiente.detalle.includes("marca_rara_no_catalogada"));
  assert(res.confianza !== "completa");
});

Deno.test("Adicional 3: modelo sin acero o procesos → confianza incompleta y precio_sugerido null", () => {
  const datosSinAcero: DatosCosteo = {
    ...datosBase,
    receta_acero: []
  };

  const resSinAcero = costear(datosSinAcero, { grupos: {} });
  assertEquals(resSinAcero.confianza, "incompleta");
  assertEquals(resSinAcero.precio_sugerido, null);
  assert(resSinAcero.pendientes.some(p => p.tipo === "modelo_sin_costos"));

  const datosSinProcesos: DatosCosteo = {
    ...datosBase,
    procesos: []
  };

  const resSinProcesos = costear(datosSinProcesos, { grupos: {} });
  assertEquals(resSinProcesos.confianza, "incompleta");
  assertEquals(resSinProcesos.precio_sugerido, null);
  assert(resSinProcesos.pendientes.some(p => p.tipo === "modelo_sin_costos"));
});

Deno.test("Adicional 4: ganancia nula → precio_sugerido null y pendiente ganancia_no_definida", () => {
  const datosSinGanancia: DatosCosteo = {
    ...datosBase,
    ganancia: null
  };

  const res = costear(datosSinGanancia, { grupos: {} });
  assertEquals(res.precio_sugerido, null);
  assertEquals(res.margen_sobre_precio, null);
  assert(res.pendientes.some(p => p.tipo === "ganancia_no_definida"));
});

Deno.test("Adicional 5: ajustes con descuento negativo resta del costo", () => {
  const config: Configuracion = {
    grupos: {
      suspension: "fleet_master"
    }
  };

  const resSinAjustes = costear(datosBase, config, []);
  const ajusteDescuento: AjusteManual[] = [
    { concepto: "Descuento por volumen", cantidad: 1, costo_unitario: -15000 }
  ];

  const resConDescuento = costear(datosBase, config, ajusteDescuento);
  assertEquals(resConDescuento.secciones.ajustes.total, -15000);
  assertEquals(resConDescuento.costo, Math.round((resSinAjustes.costo - 15000) * 100) / 100);
});

Deno.test("Adicional 6: validación de ajustes rechaza entradas no numéricas o inválidas", () => {
  // Ajustes no arreglo
  assertEquals(validarAjustes("no es un arreglo").valido, false);
  assertEquals(validarAjustes(12345).valido, false);

  // Ajuste con concepto inválido
  assertEquals(validarAjustes([{ concepto: 123, cantidad: 1, costo_unitario: 100 }]).valido, false);

  // Ajuste con cantidad <= 0 o no finita
  assertEquals(validarAjustes([{ concepto: "test", cantidad: 0, costo_unitario: 100 }]).valido, false);
  assertEquals(validarAjustes([{ concepto: "test", cantidad: -2, costo_unitario: 100 }]).valido, false);
  assertEquals(validarAjustes([{ concepto: "test", cantidad: NaN, costo_unitario: 100 }]).valido, false);
  assertEquals(validarAjustes([{ concepto: "test", cantidad: Infinity, costo_unitario: 100 }]).valido, false);

  // Ajuste con costo_unitario no numérico o no finito
  assertEquals(validarAjustes([{ concepto: "test", cantidad: 1, costo_unitario: "100" }]).valido, false);
  assertEquals(validarAjustes([{ concepto: "test", cantidad: 1, costo_unitario: NaN }]).valido, false);

  // Ajustes válidos (incluso con costo negativo para descuento)
  assertEquals(validarAjustes(undefined).valido, true);
  assertEquals(validarAjustes(null).valido, true);
  assertEquals(validarAjustes([]).valido, true);
  assertEquals(validarAjustes([{ concepto: "Descuento", cantidad: 1, costo_unitario: -500 }]).valido, true);
});

Deno.test("Adicional 7: cuando todos los materiales de acero tienen precio asignado → confianza completa", () => {
  const datosCompletos: DatosCosteo = JSON.parse(JSON.stringify(datosBase));
  // Asignar precio al puente de suspensión
  const puente = datosCompletos.receta_acero.find(r => r.nombre.includes("PUENTES DE SUSPENSIÓN"));
  assert(puente !== undefined);
  puente.costo = 700;
  puente.descripcion = 'PTR a 2 x 6"';

  const config: Configuracion = {
    grupos: {
      suspension: "fleet_master",
      eje: "fleet_master",
      patin: "hj",
      piso: "laminado_plastico",
      abs: "2e_sin_retractil"
    }
  };

  const res = costear(datosCompletos, config);
  assertEquals(res.pendientes.length, 0);
  assertEquals(res.confianza, "completa");
  assert(res.precio_sugerido !== null);
});
