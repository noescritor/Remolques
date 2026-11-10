// @ts-nocheck
import { assertEquals } from "https://deno.land/std@0.192.0/testing/asserts.ts";
import {
  mensajeCosteoIncompleto,
  obtenerSeccionesFaltantes,
  decidirPrecioItem,
  textoConfianza,
  traducirTipoPendiente
} from "./costeo.ts";

Deno.test("mensajeCosteoIncompleto: costeo normal o con precio retorna null", () => {
  // 1. Costeo con confianza 'completa' y precio_sugerido
  assertEquals(mensajeCosteoIncompleto({
    confianza: "completa",
    precio_sugerido: 500000,
    costo: 390000
  }), null);

  // 2. Costeo con confianza 'estimada' y precio_sugerido
  assertEquals(mensajeCosteoIncompleto({
    confianza: "estimada",
    precio_sugerido: 564872.19,
    costo: 454872.19
  }), null);

  // 3. Costeo null o undefined
  assertEquals(mensajeCosteoIncompleto(null), null);
  assertEquals(mensajeCosteoIncompleto(undefined), null);

  // 4. Costeo completo aun si precio_sugerido fuera 0 (no nulo)
  assertEquals(mensajeCosteoIncompleto({
    confianza: "completa",
    precio_sugerido: 0,
    costo: 0
  }), null);
});

Deno.test("mensajeCosteoIncompleto: 1 sección faltante", () => {
  // Falta solo acero
  assertEquals(
    mensajeCosteoIncompleto({
      confianza: "incompleta",
      precio_sugerido: null,
      secciones_faltantes: ["acero"]
    }),
    "Sin precio sugerido: falta acero de este modelo"
  );

  // Falta solo kits
  assertEquals(
    mensajeCosteoIncompleto({
      confianza: "incompleta",
      precio_sugerido: null,
      secciones_faltantes: ["kits"]
    }),
    "Sin precio sugerido: faltan kits de este modelo"
  );

  // Falta solo mano de obra
  assertEquals(
    mensajeCosteoIncompleto({
      confianza: "incompleta",
      precio_sugerido: null,
      secciones_faltantes: ["mano_obra"]
    }),
    "Sin precio sugerido: falta mano de obra de este modelo"
  );
});

Deno.test("mensajeCosteoIncompleto: 2 secciones faltantes", () => {
  // Acero y kits
  assertEquals(
    mensajeCosteoIncompleto({
      confianza: "incompleta",
      precio_sugerido: null,
      secciones_faltantes: ["acero", "kits"]
    }),
    "Sin precio sugerido: faltan acero y kits de este modelo"
  );

  // Acero y mano de obra
  assertEquals(
    mensajeCosteoIncompleto({
      confianza: "incompleta",
      precio_sugerido: null,
      secciones_faltantes: ["acero", "mano_obra"]
    }),
    "Sin precio sugerido: faltan acero y mano de obra de este modelo"
  );

  // Kits y mano de obra
  assertEquals(
    mensajeCosteoIncompleto({
      confianza: "incompleta",
      precio_sugerido: null,
      secciones_faltantes: ["kits", "mano_obra"]
    }),
    "Sin precio sugerido: faltan kits y mano de obra de este modelo"
  );
});

Deno.test("mensajeCosteoIncompleto: 3 secciones faltantes (caso plataforma 43 ft antes de migración)", () => {
  assertEquals(
    mensajeCosteoIncompleto({
      confianza: "incompleta",
      precio_sugerido: null,
      secciones_faltantes: ["acero", "kits", "mano_obra"]
    }),
    "Sin precio sugerido: faltan acero, kits y mano de obra de este modelo"
  );
});

Deno.test("mensajeCosteoIncompleto: deducción automática desde pendientes cuando no viene secciones_faltantes", () => {
  // Costeo incompleto con los 3 pendientes clásicos del motor
  const costeoConPendientes = {
    confianza: "incompleta",
    precio_sugerido: null,
    pendientes: [
      { tipo: "modelo_sin_costos", detalle: "Falta despiece de acero para este modelo" },
      { tipo: "modelo_sin_costos", detalle: "Faltan costos fijos de modelo para este modelo" },
      { tipo: "modelo_sin_costos", detalle: "Faltan procesos de manufactura para este modelo" }
    ]
  };

  assertEquals(
    mensajeCosteoIncompleto(costeoConPendientes),
    "Sin precio sugerido: faltan acero, kits y mano de obra de este modelo"
  );

  // Costeo incompleto solo con acero faltante
  const soloAcero = {
    confianza: "incompleta",
    precio_sugerido: null,
    pendientes: [
      { tipo: "modelo_sin_costos", detalle: "Falta despiece de acero para este modelo" }
    ]
  };

  assertEquals(
    mensajeCosteoIncompleto(soloAcero),
    "Sin precio sugerido: falta acero de este modelo"
  );
});
