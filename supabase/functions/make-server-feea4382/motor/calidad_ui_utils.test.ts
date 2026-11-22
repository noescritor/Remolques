import { assertEquals } from "https://deno.land/std@0.192.0/testing/asserts.ts";
import {
  agruparResultadosPorClave,
  contarResumenPorPlantilla,
  contarResumenGrupo,
  obtenerSiguienteNoConforme,
  etiquetaResultado,
  armarLoteResultados,
  parsearLineasActividades,
  resolverPlantillaSugerida,
  traducirErrorCalidad,
  normalizarConfigPlantilla,
  avisosAlLiberar,
  puedeCerrarInspeccion,
  seleccionarUnidadObservacion,
  faltanObservacionesNoConforme,
  encolarCambioResultado,
  limpiarLoteEnviado,
  formatearFechaImpresion,
  claveResultado,
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

Deno.test("calidadUtils: conteo con 2 unidades (Plana 1 / Plana 2) e ignora unidad fuera de rango (incluye contarResumenGrupo M20)", () => {
  const res = contarResumenPorPlantilla(
    GRUPOS_2_ITEMS,
    { unidades: ["Plana 1", "Plana 2"] },
    [
      { item_id: "it-1", unidad: 1, resultado: "conforme" },
      { item_id: "it-1", unidad: 2, resultado: "no_conforme" },
      { item_id: "it-2", unidad: 1, resultado: "no_aplica" },
      { item_id: "it-2", unidad: 3, resultado: "conforme" },
    ],
  );
  assertEquals(res.total, 4);
  assertEquals(res.capturados, 3);
  assertEquals(res.conformes, 1);
  assertEquals(res.no_conformes, 1);
  assertEquals(res.no_aplica, 1);
  assertEquals(res.pendientes, 1);

  // M20: contarResumenGrupo debe respetar numUnidades = 2
  const mapa = agruparResultadosPorClave([
    { item_id: "it-1", unidad: 2, resultado: "no_conforme" },
  ]);
  const resGrupo = contarResumenGrupo(GRUPOS_2_ITEMS[0], 2, mapa);
  assertEquals(resGrupo.total, 4);
  assertEquals(resGrupo.capturados, 1);
  assertEquals(resGrupo.no_conformes, 1);
  assertEquals(resGrupo.pendientes, 3);
});

Deno.test("calidadUtils: normalizarConfigPlantilla valores por omisión (M16-M18) y unidad ausente -> 1 (M19)", () => {
  const cfgVacio = normalizarConfigPlantilla(null);
  assertEquals(cfgVacio.unidades, ["Única"]);
  assertEquals(cfgVacio.etiquetas_resultado, { conforme: "√", no_conforme: "X" });
  assertEquals(cfgVacio.bloquea_liberacion, false);

  const cfgUnidadesVacias = normalizarConfigPlantilla({ unidades: [], bloquea_liberacion: true });
  assertEquals(cfgUnidadesVacias.unidades, ["Única"]);
  assertEquals(cfgUnidadesVacias.bloquea_liberacion, true);

  // M19: unidad ausente o 0 cae a 1
  const mapa = agruparResultadosPorClave([{ item_id: "it-1", unidad: 0, resultado: "conforme" }]);
  assertEquals(mapa.has("it-1:1"), true);
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

Deno.test("calidadUtils: armarLoteResultados deduplica, hace trim a colaborador (M4) y conserva resultado=null", () => {
  const lote = armarLoteResultados([
    { item_id: "it-1", unidad: 1, resultado: "conforme", colaborador: "  Ana  " },
    { item_id: "it-1", unidad: 1, resultado: null },
    { item_id: "it-2", unidad: 2, resultado: "no_conforme", colaborador: "  Luis  ", observaciones: " Faltante " },
  ]);

  assertEquals(lote.length, 2);
  assertEquals(lote[0].resultado, null);
  assertEquals(lote[1].colaborador, "Luis");
  assertEquals(lote[1].observaciones, "Faltante");
});

Deno.test("calidadUtils: parsearLineasActividades arma lista consecutiva desde texto pegado", () => {
  const items = parsearLineasActividades("  Revisar llantas  \n\nRevisar luces\r\n  Revisar frenos ", 10);
  assertEquals(items.length, 3);
  assertEquals(items[0], { orden: 1, numero: 10, texto: "Revisar llantas", aplica_si: null });
  assertEquals(items[2], { orden: 3, numero: 12, texto: "Revisar frenos", aplica_si: null });
});

Deno.test("calidadUtils: resolverPlantillaSugerida prueba tipo_equipo 05 solo (M9), texto solo, y exige activa (M10)", () => {
  const plantillas: PlantillaCalidad[] = [
    {
      id: "pl-cb-borr",
      organizacion_id: "o1",
      linea_producto_id: "lin-cb",
      linea: { id: "lin-cb", clave: "cama_baja", nombre: "Cama baja" },
      formato: "entrega",
      nombre: "Entrega CB Borrador",
      version: 2,
      estado: "borrador",
      config: { unidades: ["Única"], etiquetas_resultado: { conforme: "√", no_conforme: "X" }, bloquea_liberacion: false },
      origen: "editor",
    },
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

  // M9: tipo_equipo === '05' SIN mencionar 'cama baja' en modelo/etiqueta
  assertEquals(
    resolverPlantillaSugerida({ tipo_equipo: "05", modelo: "Equipo 3 ejes", linea_producto_id: "lin-plat" }, plantillas, "entrega")?.id,
    "pl-cb-ent",
  );
  // Texto 'cama baja' sin tipo_equipo '05'
  assertEquals(
    resolverPlantillaSugerida({ tipo_equipo: "01", modelo: "Cama baja especial", linea_producto_id: "lin-plat" }, plantillas, "entrega")?.id,
    "pl-cb-ent",
  );
  // Fallback a línea de orden cuando no hay plantilla cama_baja en control_total
  assertEquals(
    resolverPlantillaSugerida({ tipo_equipo: "05", modelo: "Cama baja", linea_producto_id: "lin-plat" }, plantillas, "control_total")?.id,
    "pl-plat-ct",
  );
  // M10: si solo existe borrador/archivada, no la sugiere
  assertEquals(
    resolverPlantillaSugerida({ tipo_equipo: "01", linea_producto_id: "lin-cb" }, [plantillas[0]], "entrega"),
    null,
  );

  // M14-M15: mensajes de error específicos
  assertEquals(traducirErrorCalidad("SIN_PLANTILLA").includes("Calidad → Plantillas"), true);
  assertEquals(traducirErrorCalidad("YA_EXISTE").includes("Ya existe una inspección en proceso"), true);
  assertEquals(traducirErrorCalidad("UNIDAD_INVALIDA").includes("fuera del rango"), true);
});

Deno.test("calidadUtils (D4): avisosAlLiberar evalúa solo el intento vigente por formato y cuida singular/plural", () => {
  // Sin inspecciones
  assertEquals(avisosAlLiberar([]), ["Esta orden no tiene una inspección de calidad de entrega cerrada."]);

  // Entrega cerrada sin NC
  assertEquals(
    avisosAlLiberar([{ formato: "entrega", intento: 1, estado: "cerrada", resumen: { no_conformes: 0 } }]),
    [],
  );

  // Entrega cerrada con 1 NC (singular: "1 punto")
  assertEquals(
    avisosAlLiberar([{ formato: "entrega", intento: 1, estado: "cerrada", resumen: { no_conformes: 1 } }]),
    ["Esta orden tiene 1 punto marcado como No Conforme sin resolver."],
  );

  // Intento 1 cerrado con 1 NC + intento 2 abierto vacío -> vigente es intento 2 (en_proceso, 0 NC)
  assertEquals(
    avisosAlLiberar([
      { formato: "entrega", intento: 1, estado: "cerrada", resumen: { no_conformes: 1 } },
      { formato: "entrega", intento: 2, estado: "en_proceso", resumen: { no_conformes: 0 } },
    ]),
    ["Esta orden no tiene una inspección de calidad de entrega cerrada."],
  );

  // Solo control total (cerrado con 2 NC) -> falta entrega cerrada + 2 puntos NC
  assertEquals(
    avisosAlLiberar([{ formato: "control_total", intento: 1, estado: "cerrada", resumen: { no_conformes: 2 } }]),
    [
      "Esta orden no tiene una inspección de calidad de entrega cerrada.",
      "Esta orden tiene 2 puntos marcados como No Conforme sin resolver.",
    ],
  );
});

Deno.test("calidadUtils (D2): puedeCerrarInspeccion bloquea cierre si quedan cambios sin guardar", () => {
  assertEquals(puedeCerrarInspeccion(0).permitido, true);
  const res = puedeCerrarInspeccion(2);
  assertEquals(res.permitido, false);
  assertEquals(res.motivo?.includes("cambios sin guardar"), true);
});

Deno.test("calidadUtils (D3): seleccionarUnidadObservacion y faltanObservacionesNoConforme en Plana 2", () => {
  const mapaVacio = new Map();
  assertEquals(seleccionarUnidadObservacion("it-1", 2, mapaVacio), { unidadActiva: null, resultado: null });

  // Solo Plana 2 marcada como no_conforme sin observación
  const mapaPlana2 = agruparResultadosPorClave([
    { item_id: "it-1", unidad: 2, resultado: "no_conforme", observaciones: "" },
  ]);
  const sel = seleccionarUnidadObservacion("it-1", 2, mapaPlana2);
  assertEquals(sel.unidadActiva, 2);
  assertEquals(faltanObservacionesNoConforme("it-1", 2, mapaPlana2), true);

  // Al agregar observación en Plana 2, ya no falta
  mapaPlana2.set(claveResultado("it-1", 2), {
    item_id: "it-1",
    unidad: 2,
    resultado: "no_conforme",
    observaciones: "Falta soldadura",
  });
  assertEquals(faltanObservacionesNoConforme("it-1", 2, mapaPlana2), false);
});

Deno.test("calidadUtils (D1): cola de autoguardado conserva ediciones ocurridas durante el vuelo", () => {
  let cola = new Map();
  const c1 = { item_id: "it-1", unidad: 1, resultado: "conforme" as const };
  cola = encolarCambioResultado(cola, c1);
  const snapshotVuelo = new Map(cola);

  // Mientras viaja c1, usuario marca it-2 y cambia it-1
  const c1Nuevo = { item_id: "it-1", unidad: 1, resultado: "no_conforme" as const };
  const c2 = { item_id: "it-2", unidad: 1, resultado: "conforme" as const };
  cola = encolarCambioResultado(cola, c1Nuevo);
  cola = encolarCambioResultado(cola, c2);

  const restantes = limpiarLoteEnviado(cola, snapshotVuelo);
  assertEquals(restantes.size, 2);
  assertEquals(restantes.get("it-1:1")?.resultado, "no_conforme");
  assertEquals(restantes.get("it-2:1")?.resultado, "conforme");
});

Deno.test("calidadUtils (Menor 4): formatearFechaImpresion convierte YYYY-MM-DD a DD/MM/AAAA", () => {
  assertEquals(formatearFechaImpresion("2026-11-22"), "22/11/2026");
  assertEquals(formatearFechaImpresion("2026-11-22T06:00:00.000Z"), "22/11/2026");
  assertEquals(formatearFechaImpresion(null), "");
});
