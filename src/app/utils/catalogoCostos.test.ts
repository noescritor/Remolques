// @ts-nocheck
import { assertEquals, assert } from "https://deno.land/std@0.192.0/testing/asserts.ts";
import {
  formatearMoneda,
  obtenerInsigniaFuente,
  validarOpcionEdicion,
  validarKitEdicion,
  validarProcesoEdicion,
  validarGananciaMonto,
  filtrarOpciones,
  calcularResumenCobertura
} from "./catalogoCostos.ts";

Deno.test("catalogoCostos utils - formatearMoneda formatea números correctamente a MXN", () => {
  assertEquals(formatearMoneda(0), "$0.00");
  assertEquals(formatearMoneda(null), "$0.00");
  assertEquals(formatearMoneda(undefined), "$0.00");
  const str = formatearMoneda(3586);
  assert(str.includes("3,586.00") || str.includes("3.586,00") || str.includes("3586"));
});

Deno.test("catalogoCostos utils - obtenerInsigniaFuente clasifica correctamente cada origen", () => {
  // Factura
  const insFactura = obtenerInsigniaFuente("Factura Leolca");
  assertEquals(insFactura.texto, "Factura");
  assertEquals(insFactura.esPendiente, false);

  // Manual
  const insManual = obtenerInsigniaFuente("Manual (usuario)");
  assertEquals(insManual.texto, "Manual");
  assertEquals(insManual.esPendiente, false);

  // Producto
  const insProd1 = obtenerInsigniaFuente("Producto");
  assertEquals(insProd1.texto, "Producto");
  assertEquals(insProd1.esPendiente, false);

  const insProd2 = obtenerInsigniaFuente("Tarifario", true);
  assertEquals(insProd2.texto, "Producto");
  assertEquals(insProd2.esPendiente, false);

  // Tarifario
  const insTarifario = obtenerInsigniaFuente("Tarifario");
  assertEquals(insTarifario.texto, "Tarifario");
  assertEquals(insTarifario.esPendiente, true);

  // Supuesto
  const insSupuesto = obtenerInsigniaFuente("Supuesto: sin costo adicional");
  assertEquals(insSupuesto.texto, "Supuesto");
  assertEquals(insSupuesto.esPendiente, true);

  // Sin costo
  const insSinCosto = obtenerInsigniaFuente(null);
  assertEquals(insSinCosto.texto, "Sin costo");
  assertEquals(insSinCosto.esPendiente, true);
});

Deno.test("catalogoCostos utils - validaciones de edición", () => {
  // Válido
  const valOk = validarOpcionEdicion({
    tipo_modelo: "plataforma",
    cantidad_base: 4,
    escala: "por_eje",
    costo_unitario: 3586
  });
  assertEquals(valOk.valido, true);

  // Escala errónea
  const valEscala = validarOpcionEdicion({
    tipo_modelo: "plataforma",
    cantidad_base: 1,
    escala: "falsa",
    costo_unitario: 100
  });
  assertEquals(valEscala.valido, false);

  // Cantidad <= 0
  const valCant = validarOpcionEdicion({
    tipo_modelo: "plataforma",
    cantidad_base: 0,
    escala: "fija",
    costo_unitario: 100
  });
  assertEquals(valCant.valido, false);

  // Costo negativo
  const valCosto = validarOpcionEdicion({
    tipo_modelo: "plataforma",
    cantidad_base: 1,
    escala: "fija",
    costo_unitario: -10
  });
  assertEquals(valCosto.valido, false);

  // Kit válido e inválido
  assertEquals(validarKitEdicion({ cantidad: 2, costo_unitario: 50 }).valido, true);
  assertEquals(validarKitEdicion({ cantidad: 0, costo_unitario: 50 }).valido, false);
  assertEquals(validarKitEdicion({ cantidad: 2, costo_unitario: -1 }).valido, false);

  // Proceso válido e inválido
  assertEquals(validarProcesoEdicion({ minutos: 60, tarifa_hora: 200 }).valido, true);
  assertEquals(validarProcesoEdicion({ minutos: -5, tarifa_hora: 200 }).valido, false);

  // Ganancia monto
  assertEquals(validarGananciaMonto(110000).valido, true);
  assertEquals(validarGananciaMonto(-500).valido, false);
  assertEquals(validarGananciaMonto("invalido").valido, false);
});

Deno.test("catalogoCostos utils - filtrarOpciones y calcularResumenCobertura", () => {
  const opciones = [
    { opcion_clave: "cerex", opcion_nombre: "Cerex", grupo_clave: "llantas", grupo_nombre: "Llantas", tiene_costo: true, fuente: "Tarifario", receta_piezas_count: 0 },
    { opcion_clave: "fleet_master", opcion_nombre: "Fleet Master", grupo_clave: "suspension", grupo_nombre: "Suspensión", tiene_costo: true, fuente: "Factura Leolca", receta_piezas_count: 24 },
    { opcion_clave: "rara", opcion_nombre: "Opción Rara", grupo_clave: "adicionales", grupo_nombre: "Adicionales", tiene_costo: false, fuente: null, receta_piezas_count: 0 }
  ];

  // Filtro por búsqueda
  const resBusq = filtrarOpciones(opciones, { busqueda: "cerex" });
  assertEquals(resBusq.length, 1);
  assertEquals(resBusq[0].opcion_clave, "cerex");

  // Filtro solo pendientes
  const resPend = filtrarOpciones(opciones, { soloPendientes: true });
  assertEquals(resPend.length, 2); // cerex (Tarifario) y rara (Sin costo)

  // Filtro solo sin costo
  const resSin = filtrarOpciones(opciones, { soloSinCosto: true });
  assertEquals(resSin.length, 1);
  assertEquals(resSin[0].opcion_clave, "rara");

  // Cobertura
  const cob = calcularResumenCobertura(opciones);
  assertEquals(cob.total, 3);
  assertEquals(cob.conCosto, 2);
  assertEquals(cob.sinCosto, 1);
  assertEquals(cob.conReceta, 1);
  assertEquals(cob.sinReceta, 2);
  assertEquals(cob.pctCosto, 67);
  assertEquals(cob.pctReceta, 33);
});
