import { assertEquals, assert } from "https://deno.land/std@0.192.0/testing/asserts.ts";
import { costear } from "./costeo.ts";
import { resolverReceta } from "./resolver_receta.ts";
import {
  calcularCantidadEscalada,
  resolverVolumenGondola,
  resolverVolumenGondolaDetallado,
  VOLUMEN_BASE_GONDOLA_M3
} from "./escalas.ts";
import { generarEspecificacion } from "./texto_especificacion.ts";
import { formatearCantidadTexto } from "./ficha_orden_trabajo.ts";
import type { DatosCosteo, Configuracion, GrupoOpcion, Opcion, LineaCosteo, DatosModelo } from "./tipos.ts";
import * as fixtureGondola from "./fixtures/datos_costeo_gondola.json" with { type: "json" };
import * as fixturePlataforma from "./fixtures/datos_costeo_plataforma_40x2.json" with { type: "json" };
import * as fixtureDolly from "./fixtures/datos_costeo_dolly.json" with { type: "json" };

const datosGondolaBase = fixtureGondola.default.gondola_a36 as unknown as DatosCosteo;
const datosGondolaHardox = fixtureGondola.default.gondola_hardox450 as unknown as DatosCosteo;
const datosPlataforma = fixturePlataforma.default as unknown as DatosCosteo;
const datosDolly = fixtureDolly.default as unknown as DatosCosteo;

// Mock de opciones con grupo volumen
const opcionesMock: Opcion[] = [
  { id: "opt-vol-45", grupo_id: "grp-vol", clave: "m3_45", nombre: "45 M3", activo: true, precio_venta: 0, clase: "estandar" },
  { id: "opt-vol-30", grupo_id: "grp-vol", clave: "m3_30", nombre: "30 M3", activo: true, precio_venta: 0, clase: "estandar" },
];
const gruposMock: GrupoOpcion[] = [
  { id: "grp-vol", clave: "volumen", nombre: "Volumen", seleccion: "unica", regla: "requerido", aplica_a: ["gondola"] },
];

// Datos de góndola con renglones de tina marcados con por_volumen
function prepararDatosGondolaConEscalas(datosBase: DatosCosteo = datosGondolaBase): DatosCosteo {
  const copia: DatosCosteo = JSON.parse(JSON.stringify(datosBase));
  // Marcar los 4 renglones de tina de acero como por_volumen (migración 20261105_02)
  for (const item of copia.receta_acero) {
    if (
      item.nombre.includes("ALMA") ||
      item.nombre.includes("SOLERAS") ||
      item.nombre.includes("BORDA") ||
      item.nombre.includes("CAJON") ||
      item.nombre.includes("CAJÓN")
    ) {
      item.escala = "por_volumen";
    }
  }
  // Asegurar que las opciones de tina_material tengan escala por_volumen (migración 20261105_03)
  for (const opt of copia.opcion_costos || []) {
    if (opt.grupo_clave === "tina_material") {
      opt.escala = "por_volumen";
    }
  }
  return copia;
}

// --------------------------------------------------------------------------
// TEST 1: Volumen 45 m³ y sin volumen explícito son idénticos en secciones, pendientes, costo, precio_sugerido y confianza
// --------------------------------------------------------------------------
Deno.test("Góndola Volumen: Test 1 - Volumen 45 m³ y sin volumen explícito son idénticos en secciones, pendientes, costo, precio_sugerido y confianza", () => {
  const datosA36 = prepararDatosGondolaConEscalas(datosGondolaBase);
  const datosHardox = prepararDatosGondolaConEscalas(datosGondolaHardox);

  // 1. Fixture A-36: comparar secciones, pendientes, costo, precio_sugerido y confianza
  const configSinVolA36: Configuracion = {
    grupos: {
      tina_material: "a36"
    }
  };
  const configConVol45A36: Configuracion = {
    grupos: {
      volumen: "m3_45",
      tina_material: "a36"
    }
  };

  const resSinVolA36 = costear(datosA36, configSinVolA36);
  const resConVol45A36 = costear(datosA36, configConVol45A36);

  assertEquals(JSON.stringify(resConVol45A36.secciones), JSON.stringify(resSinVolA36.secciones));
  assertEquals(resConVol45A36.pendientes, resSinVolA36.pendientes);
  assertEquals(resConVol45A36.costo, resSinVolA36.costo);
  assertEquals(resConVol45A36.precio_sugerido, resSinVolA36.precio_sugerido);
  assertEquals(resConVol45A36.confianza, resSinVolA36.confianza);

  // 2. Fixture Hardox 450: comparar secciones, pendientes, costo, precio_sugerido y confianza
  const configSinVolHardox: Configuracion = {
    grupos: {
      tina_material: "hardox_450"
    }
  };
  const configConVol45Hardox: Configuracion = {
    grupos: {
      volumen: "m3_45",
      tina_material: "hardox_450"
    }
  };

  const resSinVolHardox = costear(datosHardox, configSinVolHardox);
  const resConVol45Hardox = costear(datosHardox, configConVol45Hardox);

  assertEquals(JSON.stringify(resConVol45Hardox.secciones), JSON.stringify(resSinVolHardox.secciones));
  assertEquals(resConVol45Hardox.pendientes, resSinVolHardox.pendientes);
  assertEquals(resConVol45Hardox.costo, resSinVolHardox.costo);
  assertEquals(resConVol45Hardox.precio_sugerido, resSinVolHardox.precio_sugerido);
  assertEquals(resConVol45Hardox.confianza, resSinVolHardox.confianza);

  // 3. Con m3_30: ningún pendiente opcion_sin_costo menciona volumen y la única diferencia en pendientes es variante_supuesta
  const config30A36: Configuracion = {
    grupos: {
      volumen: "m3_30",
      tina_material: "a36"
    }
  };
  const res30A36 = costear(datosA36, config30A36);
  assert(!res30A36.pendientes.some(p => p.detalle.includes("volumen")), "Ningún pendiente opcion_sin_costo debe mencionar volumen");
  const diffPendientes = res30A36.pendientes.filter(p => !resConVol45A36.pendientes.some(p45 => p45.detalle === p.detalle));
  assertEquals(diffPendientes.length, 1);
  assertEquals(diffPendientes[0].tipo, "variante_supuesta");
  assert(diffPendientes[0].detalle.includes("Costo de 30 m³ estimado por proporción sobre 45 m³; pendiente despiece real"));

  // 4. resolverReceta con m3_45 es idéntico en advertencias y resultado a sin volumen
  const datosModeloGondola: DatosModelo = {
    modelo: { id: "mod-gondola", tipo: "gondola", largo_ft: 0, num_ejes: 2, nombre: "GONDOLA 2 EJES" },
    receta_base: [],
    grupos: [
      { id: "grp-vol", clave: "volumen", nombre: "Volumen", seleccion: "unica", regla: "requerido", aplica_a: ["gondola"] },
      { id: "grp-tina", clave: "tina_material", nombre: "Material Tina", seleccion: "unica", regla: "requerido", aplica_a: ["gondola"] },
    ],
    opciones: [
      { id: "opt-vol-45", grupo_id: "grp-vol", clave: "m3_45", nombre: "45 M3", activo: true, precio_venta: 0, clase: "estandar" },
      { id: "opt-vol-30", grupo_id: "grp-vol", clave: "m3_30", nombre: "30 M3", activo: true, precio_venta: 0, clase: "estandar" },
      { id: "opt-tina-a36", grupo_id: "grp-tina", clave: "a36", nombre: "A-36", activo: true, precio_venta: 0, clase: "estandar" },
    ],
    opcion_componentes: [
      {
        opcion_id: "opt-tina-a36",
        grupo_clave: "tina_material",
        opcion_clave: "a36",
        material_id: "mat-placa-tina",
        cantidad: 9,
        escala: "por_volumen",
        paso: "armado",
        uso: "Tina A-36",
        rol: "principal",
        nombre: "Placa Tina A36",
        unidad: "PZA",
        costo: 1000,
        descripcion: null
      }
    ]
  };

  const resRecetaSinVol = resolverReceta(datosModeloGondola, { grupos: { tina_material: "a36" } });
  const resRecetaConVol45 = resolverReceta(datosModeloGondola, { grupos: { tina_material: "a36", volumen: "m3_45" } });

  assertEquals(resRecetaConVol45.advertencias, resRecetaSinVol.advertencias);
  assertEquals(resRecetaConVol45.lineas, resRecetaSinVol.lineas);
  assertEquals(resRecetaConVol45.completo, resRecetaSinVol.completo);
});

// --------------------------------------------------------------------------
// TEST 2: Volumen 30 m³ - Tina en opcion_costos y acero escalan por 30/45 con fixture real
// --------------------------------------------------------------------------
Deno.test("Góndola Volumen: Test 2 - Volumen 30 m³ escala tina opcion_costos (A-36 y Hardox) y acero proporcionalmente", () => {
  const datosA36 = prepararDatosGondolaConEscalas(datosGondolaBase);
  const datosHardox = prepararDatosGondolaConEscalas(datosGondolaHardox);

  // Tina A-36 con volumen 30 m³
  const config30A36: Configuracion = {
    grupos: {
      volumen: "m3_30",
      tina_material: "a36"
    }
  };
  const res30A36 = costear(datosA36, config30A36);
  assertEquals(resolverVolumenGondola(config30A36, opcionesMock), 30);

  // 1. Tina A-36 escala a 167,505.76 * 30 / 45 = 111,670.51
  const tinaA36_30 = res30A36.secciones.opciones.lineas.find(l => l.concepto.includes("tina_material: a36"));
  assert(tinaA36_30, "Línea tina A-36 debe existir");
  const tinaA36Esperado = Math.round((167505.76 * 30 / 45) * 100) / 100;
  assertEquals(tinaA36Esperado, 111670.51);
  assertEquals(tinaA36_30.importe, 111670.51);

  // 2. Tina Hardox 450 con volumen 30 m³
  const config30Hardox: Configuracion = {
    grupos: {
      volumen: "m3_30",
      tina_material: "hardox_450"
    }
  };
  const res30Hardox = costear(datosHardox, config30Hardox);
  const tinaHardox_30 = res30Hardox.secciones.opciones.lineas.find(l => l.concepto.includes("tina_material: hardox_450"));
  assert(tinaHardox_30, "Línea tina Hardox debe existir");
  const tinaHardoxEsperado = Math.round((286748.42 * 30 / 45) * 100) / 100;
  assertEquals(tinaHardoxEsperado, 191165.61);
  assertEquals(tinaHardox_30.importe, 191165.61);

  // 3. Renglones de acero de tina escalan por 30/45
  const alma = res30A36.secciones.acero.lineas.find((l: LineaCosteo) => l.concepto.includes("ALMA"));
  assert(alma);
  assert(Math.abs(alma.cantidad - (2 * 30 / 45)) < 0.0001, `ALMA cantidad esperada ~1.3333, obtenida ${alma.cantidad}`);

  const soleras = res30A36.secciones.acero.lineas.find((l: LineaCosteo) => l.concepto.includes("SOLERAS"));
  assert(soleras);
  assert(Math.abs(soleras.cantidad - (4 * 30 / 45)) < 0.0001, `SOLERAS cantidad esperada ~2.6667, obtenida ${soleras.cantidad}`);

  // 4. Renglón fijo de chasis (PUENTES DE SUSPENSIÓN, base 9 pz) se mantiene intacto
  const puentes = res30A36.secciones.acero.lineas.find((l: LineaCosteo) => l.concepto.includes("PUENTES DE SUSPENSIÓN"));
  assert(puentes);
  assertEquals(puentes.cantidad, 9);

  // 5. Advertencia provisional obligatoria presente
  const advertencia = res30A36.pendientes.find(p => p.tipo === "variante_supuesta");
  assert(advertencia, "Debe incluir advertencia tipo variante_supuesta");
  assert(advertencia.detalle.includes("Costo de 30 m³ estimado por proporción sobre 45 m³; pendiente despiece real"));
});

// --------------------------------------------------------------------------
// TEST 2b: Comparación de costo total 45 vs 30 con tina A-36
// --------------------------------------------------------------------------
Deno.test("Góndola Volumen: Test 2b - Comparación de costo total 45 vs 30 con tina A-36", () => {
  const datos = prepararDatosGondolaConEscalas(datosGondolaBase);
  const config45: Configuracion = {
    grupos: {
      volumen: "m3_45",
      tina_material: "a36",
      suspension: "fleet_master",
      eje: "fleet_master"
    }
  };
  const config30: Configuracion = {
    grupos: {
      volumen: "m3_30",
      tina_material: "a36",
      suspension: "fleet_master",
      eje: "fleet_master"
    }
  };

  const res45 = costear(datos, config45);
  const res30 = costear(datos, config30);

  // Reducción en tina A-36: 167,505.76 - 111,670.51 = 55,835.25
  const tina45 = res45.secciones.opciones.lineas.find(l => l.concepto.includes("tina_material: a36"))!.importe;
  const tina30 = res30.secciones.opciones.lineas.find(l => l.concepto.includes("tina_material: a36"))!.importe;
  const ahorroTina = Math.round((tina45 - tina30) * 100) / 100;
  assertEquals(ahorroTina, 55835.25);

  // Reducción en acero base de tina: ~18,458.53 a 18,458.67
  const ahorroAcero = Math.round((res45.secciones.acero.total - res30.secciones.acero.total) * 100) / 100;
  assert(ahorroAcero >= 18458.50 && ahorroAcero <= 18458.70, `Ahorro de acero esperado ~18,458.53/67, obtenido ${ahorroAcero}`);

  // Reducción total de costo combina ambos rubros (~74,293.78)
  const ahorroTotal = Math.round((res45.costo - res30.costo) * 100) / 100;
  const ahorroEsperado = Math.round((ahorroAcero + ahorroTina) * 100) / 100;
  assertEquals(ahorroTotal, ahorroEsperado);
  assert(ahorroTotal >= 74293.70 && ahorroTotal <= 74294.00, `Ahorro total esperado ~74,293.78, obtenido ${ahorroTotal}`);
});

// --------------------------------------------------------------------------
// TEST 3: Sin grupo volumen explícito - Toma defecto 45 m³ sin advertencias
// --------------------------------------------------------------------------
Deno.test("Góndola Volumen: Test 3 - Ausencia de grupo volumen toma 45 m³ por defecto sin advertencias", () => {
  const datos = prepararDatosGondolaConEscalas();
  const configVacia: Configuracion = { grupos: {} };

  const resDefecto = costear(datos, configVacia);

  assertEquals(resolverVolumenGondola(configVacia, opcionesMock), VOLUMEN_BASE_GONDOLA_M3);

  // Cantidad de ALMA intacta (2 pz)
  const alma = resDefecto.secciones.acero.lineas.find((l: LineaCosteo) => l.concepto.includes("ALMA"));
  assert(alma);
  assertEquals(alma.cantidad, 2);

  // Cero advertencias de variante_supuesta
  const advertencias = resDefecto.pendientes.filter(p => p.tipo === "variante_supuesta");
  assertEquals(advertencias.length, 0);
});

// --------------------------------------------------------------------------
// TEST 4: Plataforma y Dolly no son afectados por escala de volumen
// --------------------------------------------------------------------------
Deno.test("Góndola Volumen: Test 4 - Plataforma y Dolly no son alterados", () => {
  const configPlat: Configuracion = {
    grupos: {
      suspension: "fleet_master",
      eje: "fleet_master",
      patin: "hj",
      piso: "laminado_plastico",
      abs: "2e_sin_retractil"
    }
  };

  const resPlat = costear(datosPlataforma, configPlat);
  assertEquals(resPlat.secciones.acero.total, 128211.69);
  assert(!resPlat.pendientes.some(p => p.tipo === "variante_supuesta"));

  const configDolly: Configuracion = {
    grupos: {
      suspension: "muelles",
      quinta_rueda: "holland",
      lanza: "fija"
    }
  };
  const resDolly = costear(datosDolly, configDolly);
  assert(!resDolly.pendientes.some(p => p.tipo === "variante_supuesta"));
});

// --------------------------------------------------------------------------
// TEST 5: Consistencia de cálculo de escalas y helper unificado
// --------------------------------------------------------------------------
Deno.test("Góndola Volumen: Test 5 - Consistencia de cálculo de escalas con helper unificado", () => {
  // Con volumen 30 m³: 6 * 30 / 45 = 4
  const cantVol30 = calcularCantidadEscalada(6, "por_volumen", { volumen_m3: 30 });
  assertEquals(cantVol30, 4);

  // Con volumen 45 m³: 6 * 45 / 45 = 6
  const cantVol45 = calcularCantidadEscalada(6, "por_volumen", { volumen_m3: 45 });
  assertEquals(cantVol45, 6);

  // Con contexto vacío: por defecto 45 m³ -> 6
  const cantVolDefecto = calcularCantidadEscalada(6, "por_volumen", {});
  assertEquals(cantVolDefecto, 6);

  // Escala fija: siempre igual
  const cantFija = calcularCantidadEscalada(6, "fija", { volumen_m3: 30 });
  assertEquals(cantFija, 6);

  // Escala por_eje: 6 * 3 = 18
  const cantEjes = calcularCantidadEscalada(6, "por_eje", { num_ejes: 3 });
  assertEquals(cantEjes, 18);

  // Escala por_largo: 40 * (53 / 40) = 53
  const cantLargo = calcularCantidadEscalada(40, "por_largo", { largo_ft: 53 });
  assertEquals(cantLargo, 53);

  // Integración con resolverReceta para góndola con volumen 30 m³
  const datosModeloMock: DatosModelo = {
    modelo: { id: "mod-gondola", tipo: "gondola", largo_ft: 0, num_ejes: 2, nombre: "GONDOLA 2 EJES" },
    receta_base: [
      {
        material_id: "mat-tina-1",
        nombre: "Placa Tina",
        unidad: "PZA",
        costo: 100,
        descripcion: null,
        cantidad: 6,
        escala: "por_volumen",
        paso: null,
        uso: "Tina",
        seccion: "acero",
        condicion: null
      },
      {
        material_id: "mat-chasis-1",
        nombre: "Puente Chasis",
        unidad: "PZA",
        costo: 50,
        descripcion: null,
        cantidad: 10,
        escala: "fija",
        paso: null,
        uso: "Chasis",
        seccion: "acero",
        condicion: null
      }
    ],
    grupos: gruposMock,
    opciones: opcionesMock,
    opcion_componentes: []
  };

  const resReceta = resolverReceta(datosModeloMock, { grupos: { volumen: "m3_30" } });

  const lineaTina = resReceta.lineas.find(l => l.material_id === "mat-tina-1");
  assert(lineaTina);
  assertEquals(lineaTina.cantidad, 4); // 6 * 30 / 45 = 4

  const lineaChasis = resReceta.lineas.find(l => l.material_id === "mat-chasis-1");
  assert(lineaChasis);
  assertEquals(lineaChasis.cantidad, 10); // fija

  // Advertencia presente en resolverReceta
  assert(resReceta.advertencias.some(a => a.includes("Costo de 30 m³ estimado por proporción sobre 45 m³; pendiente despiece real")));
});

// --------------------------------------------------------------------------
// TEST 5b: Consistencia exacta entre despiece (BOM) y costo (opcion_costos)
// --------------------------------------------------------------------------
Deno.test("Góndola Volumen: Test 5b - Despiece y costo usan exactamente el mismo factor 30/45", () => {
  // Despiece BOM (opcion_componentes)
  const datosModeloConOpcionTina: DatosModelo = {
    modelo: { id: "mod-gondola", tipo: "gondola", largo_ft: 0, num_ejes: 2, nombre: "GONDOLA 2 EJES" },
    receta_base: [],
    grupos: [
      { id: "grp-vol", clave: "volumen", nombre: "Volumen", seleccion: "unica", regla: "requerido", aplica_a: ["gondola"] },
      { id: "grp-tina", clave: "tina_material", nombre: "Material Tina", seleccion: "unica", regla: "requerido", aplica_a: ["gondola"] },
    ],
    opciones: [
      { id: "opt-vol-30", grupo_id: "grp-vol", clave: "m3_30", nombre: "30 M3", activo: true, precio_venta: 0, clase: "estandar" },
      { id: "opt-tina-a36", grupo_id: "grp-tina", clave: "a36", nombre: "A-36", activo: true, precio_venta: 0, clase: "estandar" },
    ],
    opcion_componentes: [
      {
        opcion_id: "opt-tina-a36",
        grupo_clave: "tina_material",
        opcion_clave: "a36",
        material_id: "mat-placa-tina",
        cantidad: 9, // 9 piezas base para 45 m³
        escala: "por_volumen",
        paso: "armado",
        uso: "Tina A-36",
        rol: "principal",
        nombre: "Placa Tina A36",
        unidad: "PZA",
        costo: 1000,
        descripcion: null
      }
    ]
  };

  const resReceta = resolverReceta(datosModeloConOpcionTina, {
    grupos: { volumen: "m3_30", tina_material: "a36" }
  });
  const lineaBOM = resReceta.lineas.find(l => l.material_id === "mat-placa-tina");
  assert(lineaBOM);
  // Cantidad en BOM: 9 * 30 / 45 = 6
  assertEquals(lineaBOM.cantidad, 6);
  const factorBOM = lineaBOM.cantidad / 9; // 6 / 9 = 2/3

  // Costo en opcion_costos
  const datosCosteoTina: DatosCosteo = {
    modelo: { id: "mod-gondola", tipo: "gondola", largo_ft: 0, num_ejes: 2, nombre: "GONDOLA 2 EJES" },
    receta_acero: [],
    costos_modelo: [],
    procesos: [],
    grupos: [],
    ganancia: 100000,
    opcion_costos: [
      {
        grupo_clave: "tina_material",
        opcion_clave: "a36",
        cantidad_base: 1,
        escala: "por_volumen",
        costo_unitario: 167505.76
      }
    ]
  };
  const resCosteo = costear(datosCosteoTina, {
    grupos: { volumen: "m3_30", tina_material: "a36" }
  });
  const lineaCosteo = resCosteo.secciones.opciones.lineas.find(l => l.concepto.includes("tina_material: a36"));
  assert(lineaCosteo);
  const factorCosto = lineaCosteo.importe / 167505.76;

  // Ambos factores deben coincidir con 30/45 (tolerancia de centavos en importe de costo: 1e-5)
  assert(Math.abs(factorBOM - (30 / 45)) < 1e-9);
  assert(Math.abs(factorCosto - (30 / 45)) < 1e-5);
  assert(Math.abs(lineaCosteo.cantidad - (30 / 45)) < 1e-9);
  assertEquals(lineaCosteo.importe, 111670.51);
});

// --------------------------------------------------------------------------
// TEST 6: Nombre dinámico compuesto y visualización
// --------------------------------------------------------------------------
Deno.test("Góndola Volumen: Test 6 - Formato exacto de nombres dinámicos con volumen", () => {
  const modelo2e = { id: "gondola-2e", tipo: "gondola", largo_ft: null, num_ejes: 2, nombre: "GONDOLA 2 EJES" };
  const modelo3e = { id: "gondola-3e", tipo: "gondola", largo_ft: null, num_ejes: 3, nombre: "GONDOLA 3 EJES" };

  // 1. texto_especificacion
  const esp2e45 = generarEspecificacion(modelo2e as any, { grupos: { volumen: "m3_45" } }, gruposMock, opcionesMock);
  assertEquals(esp2e45.resumen_lineas[0].valor, "GONDOLA 2 EJES 45 M3");
  assert(esp2e45.texto.startsWith("SEMIREMOLQUE TIPO: GONDOLA 2 EJES 45 M3"));

  const esp2e30 = generarEspecificacion(modelo2e as any, { grupos: { volumen: "m3_30" } }, gruposMock, opcionesMock);
  assertEquals(esp2e30.resumen_lineas[0].valor, "GONDOLA 2 EJES 30 M3");
  assert(esp2e30.texto.startsWith("SEMIREMOLQUE TIPO: GONDOLA 2 EJES 30 M3"));

  const esp3e30 = generarEspecificacion(modelo3e as any, { grupos: { volumen: "m3_30" } }, gruposMock, opcionesMock);
  assertEquals(esp3e30.resumen_lineas[0].valor, "GONDOLA 3 EJES 30 M3");
  assert(esp3e30.texto.startsWith("SEMIREMOLQUE TIPO: GONDOLA 3 EJES 30 M3"));

  // 2. ficha_orden_trabajo
  assertEquals(formatearCantidadTexto(modelo2e, { grupos: { volumen: "m3_45" } }), "Una Góndola 2 ejes 45 m³");
  assertEquals(formatearCantidadTexto(modelo2e, { grupos: { volumen: "m3_30" } }), "Una Góndola 2 ejes 30 m³");
  assertEquals(formatearCantidadTexto(modelo3e, 30), "Una Góndola 3 ejes 30 m³");
});

// --------------------------------------------------------------------------
// TEST 7: Volumen no reconocido emite advertencia variante_supuesta y asume 45 m³
// --------------------------------------------------------------------------
Deno.test("Góndola Volumen: Test 7 - Volumen no reconocido emite advertencia variante_supuesta y asume 45 m³", () => {
  // 1. Helper directo resolverVolumenGondolaDetallado
  const configRaraString: Configuracion = { grupos: { volumen: "m3_60" } };
  const detString = resolverVolumenGondolaDetallado(configRaraString, opcionesMock);
  assertEquals(detString.volumen, 45);
  assertEquals(detString.esReconocido, false);
  assert(detString.advertencia?.includes("Volumen 'm3_60' no reconocido para góndola; se asume 45 m³ (provisional)"));

  const configRaraNumero: Configuracion = { grupos: { volumen: 60 as any } };
  const detNumero = resolverVolumenGondolaDetallado(configRaraNumero, opcionesMock);
  assertEquals(detNumero.volumen, 45);
  assertEquals(detNumero.esReconocido, false);
  assert(detNumero.advertencia?.includes("Volumen '60' no reconocido para góndola; se asume 45 m³ (provisional)"));

  // 2. Costeo: registra pendiente variante_supuesta
  const datos = prepararDatosGondolaConEscalas();
  const resCosteo = costear(datos, configRaraString);
  assertEquals(resCosteo.costo > 0, true);
  const pendienteRaro = resCosteo.pendientes.find(
    p => p.tipo === "variante_supuesta" && p.detalle.includes("Volumen 'm3_60' no reconocido")
  );
  assert(pendienteRaro, "Debe registrar pendiente tipo variante_supuesta con la advertencia de volumen no reconocido");

  // 3. Despiece (resolverReceta): registra advertencia
  const datosModelo: DatosModelo = {
    modelo: { id: "mod-gondola", tipo: "gondola", largo_ft: 0, num_ejes: 2, nombre: "GONDOLA 2 EJES" },
    receta_base: [],
    grupos: gruposMock,
    opciones: opcionesMock,
    opcion_componentes: []
  };
  const resReceta = resolverReceta(datosModelo, configRaraString);
  assert(
    resReceta.advertencias.some(a => a.includes("Volumen 'm3_60' no reconocido para góndola; se asume 45 m³ (provisional)")),
    "resolverReceta debe incluir advertencia cuando el volumen no es reconocido"
  );
});
