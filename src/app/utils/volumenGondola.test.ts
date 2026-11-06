// @ts-nocheck
import { assertEquals, assert } from "https://deno.land/std@0.192.0/testing/asserts.ts";
import {
  evaluarEstadoVolumen,
  esVolumenCompleto,
  extraerCandidatoVolumen,
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
