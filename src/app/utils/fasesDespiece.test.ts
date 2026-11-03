// @ts-nocheck
import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  normalizarClavePaso,
  resolverFaseDeLinea,
  agruparBOMPorFases,
  FaseDespieceItem,
  EquivalenciaPasoFase,
  LineaBOMGenerica,
} from "./fasesDespiece.ts";

const FASES_PRUEBA: FaseDespieceItem[] = [
  { id: "1", clave: "paso_1", nombre: "Paso 1", orden: 1 },
  { id: "2", clave: "paso_2", nombre: "Paso 2", orden: 2 },
  { id: "3", clave: "paso_3", nombre: "Paso 3", orden: 3 },
  { id: "4", clave: "paso_4", nombre: "Paso 4", orden: 4 },
  { id: "5", clave: "paso_5", nombre: "Paso 5", orden: 5 },
  { id: "6", clave: "paso_6", nombre: "Paso 6", orden: 6 },
  { id: "7", clave: "paso_7", nombre: "PASO 7", orden: 7 },
  { id: "8", clave: "paso_8", nombre: "PASO 8", orden: 8 },
  { id: "9", clave: "paso_9", nombre: "PASO 9", orden: 9 },
  { id: "10", clave: "paso_10", nombre: "PASO 10", orden: 10 },
  { id: "11", clave: "paso_11", nombre: "PASO 11", orden: 11 },
  { id: "12", clave: "paso_12", nombre: "PASO 12", orden: 12 },
  { id: "13", clave: "extras", nombre: "EXTRAS", orden: 13 },
  { id: "14", clave: "llantas_rines", nombre: "LLANTAS Y RINES", orden: 14 },
];

const EQUIVALENCIAS_PRUEBA: EquivalenciaPasoFase[] = [
  { paso_legacy: "PASO 1", fase_clave: "paso_1" },
  { paso_legacy: "PINTURA", fase_clave: "paso_8" },
  { paso_legacy: "AIRE", fase_clave: "paso_9" },
  { paso_legacy: "LUZ", fase_clave: "paso_10" },
  { paso_legacy: "PISOS", fase_clave: "paso_11" },
  { paso_legacy: "TERMINADO", fase_clave: "paso_12" },
  { paso_legacy: "EXTRAS", fase_clave: "extras" },
  { paso_legacy: "RINES", fase_clave: "llantas_rines" },
];

Deno.test("fasesDespiece - 1. normalizarClavePaso maneja arrays y strings", () => {
  assertEquals(normalizarClavePaso("paso 1"), "PASO 1");
  assertEquals(normalizarClavePaso(["Paso 2", "Paso 3"]), "PASO 2");
  assertEquals(normalizarClavePaso(null), "");
  assertEquals(normalizarClavePaso(undefined), "");
});

Deno.test("fasesDespiece - 2. resolverFaseDeLinea mapea por paso legacy, equivalencia o fallback", () => {
  const l1: LineaBOMGenerica = { nombre: "Solera", cantidad: 4, paso: "PASO 2" };
  assertEquals(resolverFaseDeLinea(l1, EQUIVALENCIAS_PRUEBA), "paso_2");

  const l2: LineaBOMGenerica = { nombre: "Pintura blanca", cantidad: 10, paso: "PINTURA" };
  assertEquals(resolverFaseDeLinea(l2, EQUIVALENCIAS_PRUEBA), "paso_8");

  const l3: LineaBOMGenerica = { nombre: "Válvula", cantidad: 1, paso: "AIRE" };
  assertEquals(resolverFaseDeLinea(l3, EQUIVALENCIAS_PRUEBA), "paso_9");

  const l4: LineaBOMGenerica = { nombre: "Plafón", cantidad: 4, paso: "LUZ" };
  assertEquals(resolverFaseDeLinea(l4, EQUIVALENCIAS_PRUEBA), "paso_10");

  const l5: LineaBOMGenerica = { nombre: "Fase directa", cantidad: 1, fase_clave: "paso_5" };
  assertEquals(resolverFaseDeLinea(l5, EQUIVALENCIAS_PRUEBA), "paso_5");

  const l6: LineaBOMGenerica = { nombre: "Fosfato", cantidad: 1, paso: "LIMPIEZA" };
  assertEquals(resolverFaseDeLinea(l6, EQUIVALENCIAS_PRUEBA), "paso_7");
});

Deno.test("fasesDespiece - 3. agruparBOMPorFases agrupa respetando el orden oficial y cuenta costos", () => {
  const lineas: LineaBOMGenerica[] = [
    { nombre: "Placa A-50", cantidad: 2, paso: "PASO 1", costo_unitario: 0, sin_precio: true },
    { nombre: "Solera A-529", cantidad: 4, paso: "PASO 2", costo_unitario: 4884.75 },
    { nombre: "Perno rey", cantidad: 1, paso: "PASO 3", costo_unitario: 1200 },
    { nombre: "Cargador IPR", cantidad: 38, paso: "PASO 4", costo_unitario: 500 },
    { nombre: "Válvula ABS", cantidad: 1, paso: "AIRE", costo_unitario: 2500 },
  ];

  const resumen = agruparBOMPorFases(lineas, FASES_PRUEBA, EQUIVALENCIAS_PRUEBA);

  assertEquals(resumen.totalLineas, 5);
  assertEquals(resumen.totalGeneralPiezas, 46);
  assertEquals(resumen.grupos.length, 14);

  // Grupo Paso 1: 1 línea sin costo
  const g1 = resumen.grupos.find((g) => g.fase.clave === "paso_1")!;
  assertEquals(g1.lineas.length, 1);
  assertEquals(g1.totalPiezas, 2);
  assertEquals(g1.sinCosto, 1);
  assertEquals(g1.conCosto, 0);

  // Grupo Paso 4: 1 línea con costo
  const g4 = resumen.grupos.find((g) => g.fase.clave === "paso_4")!;
  assertEquals(g4.lineas.length, 1);
  assertEquals(g4.totalPiezas, 38);
  assertEquals(g4.conCosto, 1);

  // Grupo Paso 9 (mapeado desde AIRE)
  const g9 = resumen.grupos.find((g) => g.fase.clave === "paso_9")!;
  assertEquals(g9.lineas.length, 1);
  assertEquals(g9.lineas[0].nombre, "Válvula ABS");
});
