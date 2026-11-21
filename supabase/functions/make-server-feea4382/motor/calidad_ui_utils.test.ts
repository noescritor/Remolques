import { assertEquals } from "https://deno.land/std@0.192.0/testing/asserts.ts";
import {
  agruparResultadosPorClave,
  contarResumenPorPlantilla,
  obtenerSiguienteNoConforme,
  etiquetaResultado,
  armarLoteResultados,
  parsearLineasActividades,
  resolverPlantillaSugerida,
  traducirErrorCalidad,
  type PlantillaGrupoCalidad,
  type PlantillaCalidad,
} from "../../../../src/app/components/Calidad/calidadUtils.ts";

const GRUPOS_2_ITEMS: PlantillaGrupoCalidad[] = [
  {
    orden: 1,
    nombre: "PARTE FRONTAL",
    items: [
      { id: "it-1", orden: 1, numero: 1, texto: "Revisar soldadura" },
      { id: "it-2", orden: 2, numero: 2, texto: "Revisar pintura" },
    ],
  },
];

Deno.test("calidadUtils: conteo con 1 unidad, no_aplica y pendientes", () => {
  const res = contarResumenPorPlantilla(
    GRUPOS_2_ITEMS,
    { unidades: ["Única"] },
    [
      { item_id: "it-1", unidad: 1, resultado: "conforme" },
      { item_id: "it-2", unidad: 1, resultado: "no_aplica" },
    ],
  );
  assertEquals(res, {
    total: 2,
    capturados: 2,
    conformes: 1,
    no_conformes: 0,
    no_aplica: 1,
    pendientes: 0,
  });

  const resConPendiente = contarResumenPorPlantilla(
    GRUPOS_2_ITEMS,
    { unidades: ["Única"] },
    [{ item_id: "it-1", unidad: 1, resultado: "no_conforme" }],
  );
  assertEquals(resConPendiente.pendientes, 1);
  assertEquals(resConPendiente.no_conformes, 1);
});

Deno.test("calidadUtils: conteo con 2 unidades (Plana 1 / Plana 2) e ignora unidad fuera de rango", () => {
  const res = contarResumenPorPlantilla(
    GRUPOS_2_ITEMS,
    { unidades: ["Plana 1", "Plana 2"] },
    [
      { item_id: "it-1", unidad: 1, resultado: "conforme" },
      { item_id: "it-1", unidad: 2, resultado: "no_conforme" },
      { item_id: "it-2", unidad: 1, resultado: "no_aplica" },
      { item_id: "it-2", unidad: 3, resultado: "conforme" }, // fuera de rango
    ],
  );
  assertEquals(res.total, 4);
  assertEquals(res.capturados, 3);
  assertEquals(res.conformes, 1);
  assertEquals(res.no_conformes, 1);
  assertEquals(res.no_aplica, 1);
  assertEquals(res.pendientes, 1);
});

Deno.test("calidadUtils: mapeo de etiquetas √/X y Sí/No (Dolly)", () => {
  const cfgDefault = { etiquetas_resultado: { conforme: "√", no_conforme: "X" } };
  assertEquals(etiquetaResultado("conforme", cfgDefault), "√");
  assertEquals(etiquetaResultado("no_conforme", cfgDefault), "X");
  assertEquals(etiquetaResultado("no_aplica", cfgDefault), "N/A");
  assertEquals(etiquetaResultado(null, cfgDefault), "");

  const cfgDolly = { etiquetas_resultado: { conforme: "Sí", no_conforme: "No" } };
  assertEquals(etiquetaResultado("conforme", cfgDolly), "Sí");
  assertEquals(etiquetaResultado("no_conforme", cfgDolly), "No");
});

Deno.test("calidadUtils: obtenerSiguienteNoConforme recorre y da la vuelta", () => {
  const mapa = agruparResultadosPorClave([
    { item_id: "it-1", unidad: 1, resultado: "no_conforme" },
    { item_id: "it-2", unidad: 2, resultado: "no_conforme" },
  ]);

  const primero = obtenerSiguienteNoConforme(GRUPOS_2_ITEMS, 2, mapa, null);
  assertEquals(primero, { item_id: "it-1", unidad: 1, numero: 1 });

  const segundo = obtenerSiguienteNoConforme(GRUPOS_2_ITEMS, 2, mapa, primero);
  assertEquals(segundo, { item_id: "it-2", unidad: 2, numero: 2 });

  const vuelta = obtenerSiguienteNoConforme(GRUPOS_2_ITEMS, 2, mapa, segundo);
  assertEquals(vuelta, { item_id: "it-1", unidad: 1, numero: 1 });
});

Deno.test("calidadUtils: armarLoteResultados deduplica y conserva resultado=null para limpiar", () => {
  const lote = armarLoteResultados([
    { item_id: "it-1", unidad: 1, resultado: "conforme", colaborador: "  Ana  " },
    { item_id: "it-1", unidad: 1, resultado: null },
    { item_id: "it-2", unidad: 2, resultado: "no_conforme", observaciones: " Faltante " },
  ]);

  assertEquals(lote.length, 2);
  assertEquals(lote[0].resultado, null);
  assertEquals(lote[1].observaciones, "Faltante");
});

Deno.test("calidadUtils: parsearLineasActividades arma lista consecutiva desde texto pegado", () => {
  const items = parsearLineasActividades("  Revisar llantas  \n\nRevisar luces\r\n  Revisar frenos ", 10);
  assertEquals(items.length, 3);
  assertEquals(items[0], { orden: 1, numero: 10, texto: "Revisar llantas", aplica_si: null });
  assertEquals(items[2], { orden: 3, numero: 12, texto: "Revisar frenos", aplica_si: null });
});

Deno.test("calidadUtils: resolverPlantillaSugerida elige cama_baja para tipo 05 y cae a plataforma si falta", () => {
  const plantillas: PlantillaCalidad[] = [
    {
      id: "pl-plat-ent",
      organizacion_id: "o1",
      linea_producto_id: "lin-plat",
      linea: { id: "lin-plat", clave: "plataforma", nombre: "Plataforma" },
      formato: "entrega",
      nombre: "Entrega Plat",
      version: 1,
      estado: "activa",
      config: { unidades: ["Plana 1", "Plana 2"], etiquetas_resultado: { conforme: "√", no_conforme: "X" }, bloquea_liberacion: false },
      origen: "semilla",
    },
    {
      id: "pl-cb-ent",
      organizacion_id: "o1",
      linea_producto_id: "lin-cb",
      linea: { id: "lin-cb", clave: "cama_baja", nombre: "Cama baja" },
      formato: "entrega",
      nombre: "Entrega Cama baja",
      version: 1,
      estado: "activa",
      config: { unidades: ["Única"], etiquetas_resultado: { conforme: "√", no_conforme: "X" }, bloquea_liberacion: false },
      origen: "semilla",
    },
    {
      id: "pl-plat-ct",
      organizacion_id: "o1",
      linea_producto_id: "lin-plat",
      linea: { id: "lin-plat", clave: "plataforma", nombre: "Plataforma" },
      formato: "control_total",
      nombre: "CT Plat",
      version: 1,
      estado: "activa",
      config: { unidades: ["Única"], etiquetas_resultado: { conforme: "√", no_conforme: "X" }, bloquea_liberacion: false },
      origen: "semilla",
    },
  ];

  const ordenCb = { tipo_equipo: "05", modelo: "Cama baja 3 ejes", linea_producto_id: "lin-plat" };
  assertEquals(resolverPlantillaSugerida(ordenCb, plantillas, "entrega")?.id, "pl-cb-ent");
  assertEquals(resolverPlantillaSugerida(ordenCb, plantillas, "control_total")?.id, "pl-plat-ct");
  assertEquals(traducirErrorCalidad("SIN_PLANTILLA").includes("Calidad → Plantillas"), true);
});
