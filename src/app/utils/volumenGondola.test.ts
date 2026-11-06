// @ts-nocheck
import { assertEquals, assert } from "https://deno.land/std@0.192.0/testing/asserts.ts";
import {
  evaluarEstadoVolumen,
  esVolumenCompleto,
  extraerCandidatoVolumen,
  textoCampoVolumen,
  valorDesdeTextoVolumen,
} from "./volumenGondola.ts";

Deno.test("volumenGondola: Sin valor o valor vacío retorna incompleto sin error de rango", () => {

  const casos = [undefined, null, "", "   ", {}, { opcion: "personalizado" }];
  for (const c of casos) {
    const res = evaluarEstadoVolumen(c);
    assertEquals(res.completo, false);
    assertEquals(res.estado, "incompleto");
    assertEquals(res.volumen, null);
    assertEquals(esVolumenCompleto(c), false);
    assert(!res.error, "No debe marcar error de rango si está vacío");
    assert(res.mensaje?.includes("Ingresa el volumen"), "Debe invitar a ingresar volumen");
  }
});

Deno.test("volumenGondola: Valores válidos en rango [20, 60] retornan completo", () => {
  // Enteros
  const res38 = evaluarEstadoVolumen(38);
  assertEquals(res38.completo, true);
  assertEquals(res38.volumen, 38);
  assertEquals(res38.texto, "38");

  const res38Str = evaluarEstadoVolumen("38");
  assertEquals(res38Str.completo, true);
  assertEquals(res38Str.volumen, 38);

  // Decimales punto y coma
  const res37_5 = evaluarEstadoVolumen(37.5);
  assertEquals(res37_5.completo, true);
  assertEquals(res37_5.volumen, 37.5);
  assertEquals(res37_5.texto, "37.5");

  const res37_5Coma = evaluarEstadoVolumen("37,5");
  assertEquals(res37_5Coma.completo, true);
  assertEquals(res37_5Coma.volumen, 37.5);

  // Límites exactos
  const res20 = evaluarEstadoVolumen(20);
  assertEquals(res20.completo, true);
  assertEquals(res20.volumen, 20);

  const res60 = evaluarEstadoVolumen(60);
  assertEquals(res60.completo, true);
  assertEquals(res60.volumen, 60);

  // Claves históricas
  const res30 = evaluarEstadoVolumen("m3_30");
  assertEquals(res30.completo, true);
  assertEquals(res30.volumen, 30);

  const res45 = evaluarEstadoVolumen("m3_45");
  assertEquals(res45.completo, true);
  assertEquals(res45.volumen, 45);

  // Objeto con m3
  const resObj = evaluarEstadoVolumen({ opcion: "personalizado", m3: 38 });
  assertEquals(resObj.completo, true);
  assertEquals(resObj.volumen, 38);
});

Deno.test("volumenGondola: Valores fuera de rango [20, 60] o inválidos retornan error", () => {
  // Menor que mínimo
  const res10 = evaluarEstadoVolumen(10);
  assertEquals(res10.completo, false);
  assert(res10.error?.includes("debe estar entre 20 y 60"));

  const res19_9 = evaluarEstadoVolumen(19.9);
  assertEquals(res19_9.completo, false);
  assert(res19_9.error?.includes("debe estar entre 20 y 60"));

  // Mayor que máximo
  const res80 = evaluarEstadoVolumen(80);
  assertEquals(res80.completo, false);
  assert(res80.error?.includes("debe estar entre 20 y 60"));

  const res60_1 = evaluarEstadoVolumen(60.1);
  assertEquals(res60_1.completo, false);
  assert(res60_1.error?.includes("debe estar entre 20 y 60"));

  // Cero o negativo
  const res0 = evaluarEstadoVolumen(0);
  assertEquals(res0.completo, false);
  assert(res0.error?.includes("no es válido"));

  const resNeg = evaluarEstadoVolumen(-5);
  assertEquals(resNeg.completo, false);
  assert(resNeg.error?.includes("no es válido"));

  // Texto no numérico
  const resAbc = evaluarEstadoVolumen("abc");
  assertEquals(resAbc.completo, false);
  assert(resAbc.error?.includes("no es válido"));

  const resNaN = evaluarEstadoVolumen(NaN);
  assertEquals(resNaN.completo, false);
  assert(resNaN.error?.includes("no es válido"));
});

Deno.test("volumenGondola: extraerCandidatoVolumen maneja diferentes formas de guardado", () => {
  assertEquals(extraerCandidatoVolumen(38).numero, 38);
  assertEquals(extraerCandidatoVolumen("38").numero, 38);
  assertEquals(extraerCandidatoVolumen("m3_30").numero, 30);
  assertEquals(extraerCandidatoVolumen("m3_45").numero, 45);
  assertEquals(extraerCandidatoVolumen({ opcion: "personalizado", m3: 38 }).numero, 38);
  assertEquals(extraerCandidatoVolumen({ opcion: "m3_30" }).numero, 30);
  assertEquals(extraerCandidatoVolumen(null).numero, null);
});

Deno.test("volumenGondola: textoCampoVolumen formatea correctamente valores y cotizaciones historicas", () => {
  assertEquals(textoCampoVolumen({ m3: 38 }), "38");
  assertEquals(textoCampoVolumen({ m3: 37.5 }), "37.5");
  assertEquals(textoCampoVolumen("m3_45"), "45");
  assertEquals(textoCampoVolumen("m3_30"), "30");
  assertEquals(textoCampoVolumen(45), "45");
  assertEquals(textoCampoVolumen(undefined), "");
  assertEquals(textoCampoVolumen(null), "");
  assertEquals(textoCampoVolumen(""), "");
  assertEquals(textoCampoVolumen({ opcion: "personalizado", raw: "abc" }), "abc");
  assertEquals(textoCampoVolumen({ opcion: "m3_30" }), "30");
  assertEquals(textoCampoVolumen({ opcion: "m3_45" }), "45");
  assertEquals(textoCampoVolumen({ opcion: "personalizado", raw: "37.", m3: 37 }), "37.");
});

Deno.test("volumenGondola: valorDesdeTextoVolumen convierte texto a objeto preservando raw y valores provisionales", () => {
  assertEquals(valorDesdeTextoVolumen(""), undefined);
  assertEquals(valorDesdeTextoVolumen("   "), undefined);
  assertEquals(valorDesdeTextoVolumen("37."), { opcion: "personalizado", m3: 37, raw: "37." });
  assertEquals(valorDesdeTextoVolumen("37,"), { opcion: "personalizado", m3: 37, raw: "37," });
  assertEquals(valorDesdeTextoVolumen("37,5"), { opcion: "personalizado", m3: 37.5, raw: "37,5" });
  assertEquals(valorDesdeTextoVolumen("37.5"), { opcion: "personalizado", m3: 37.5, raw: "37.5" });
  assertEquals(valorDesdeTextoVolumen("abc"), { opcion: "personalizado", raw: "abc" });
  assertEquals(valorDesdeTextoVolumen("38.0"), { opcion: "personalizado", m3: 38, raw: "38.0" });
});

Deno.test("volumenGondola: Simulación de tecleo carácter por carácter (punto, coma, decimales)", () => {
  // Teclear "37.5": secuencia "", "3", "37", "37.", "37.5"
  const secPunto = ["", "3", "37", "37.", "37.5"];
  let valPunto: any;
  for (const texto of secPunto) {
    valPunto = valorDesdeTextoVolumen(texto);
    const textoReflejado = textoCampoVolumen(valPunto);
    assertEquals(textoReflejado, texto, `El texto en el campo para '${texto}' debe coincidir exactamente`);
  }
  assertEquals(valPunto?.m3, 37.5, "El valor final de m3 para '37.5' debe ser 37.5");

  // Teclear "37,5" con coma: secuencia "", "3", "37", "37,", "37,5"
  const secComa = ["", "3", "37", "37,", "37,5"];
  let valComa: any;
  for (const texto of secComa) {
    valComa = valorDesdeTextoVolumen(texto);
    const textoReflejado = textoCampoVolumen(valComa);
    assertEquals(textoReflejado, texto, `El texto en el campo para '${texto}' debe coincidir exactamente`);
  }
  assertEquals(valComa?.m3, 37.5, "El valor final de m3 para '37,5' debe ser 37.5");

  // Teclear "38.0": secuencia "", "3", "38", "38.", "38.0"
  const secCero = ["", "3", "38", "38.", "38.0"];
  let valCero: any;
  for (const texto of secCero) {
    valCero = valorDesdeTextoVolumen(texto);
    const textoReflejado = textoCampoVolumen(valCero);
    assertEquals(textoReflejado, texto, `El texto en el campo para '${texto}' debe coincidir exactamente`);
  }
  assertEquals(valCero?.m3, 38, "El valor final de m3 para '38.0' debe ser 38");
});

Deno.test("volumenGondola: Reapertura de cotizaciones viejas con clave histórica se visualiza limpia y completa", () => {
  // Cotización guardada con clave string: { grupos: { volumen: "m3_45" } }
  const configVieja45 = { grupos: { volumen: "m3_45" } };
  const texto45 = textoCampoVolumen(configVieja45.grupos.volumen);
  assertEquals(texto45, "45", "El campo debe mostrar '45' en lugar de 'm3_45'");
  const estado45 = evaluarEstadoVolumen(configVieja45.grupos.volumen);
  assertEquals(estado45.completo, true);
  assertEquals(estado45.volumen, 45);

  // Cotización guardada con objeto de opción: { grupos: { volumen: { opcion: "m3_30" } } }
  const configVieja30 = { grupos: { volumen: { opcion: "m3_30" } } };
  const texto30 = textoCampoVolumen(configVieja30.grupos.volumen);
  assertEquals(texto30, "30", "El campo debe mostrar '30' en lugar de 'm3_30'");
  const estado30 = evaluarEstadoVolumen(configVieja30.grupos.volumen);
  assertEquals(estado30.completo, true);
  assertEquals(estado30.volumen, 30);
});

