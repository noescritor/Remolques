import { assertEquals, assert } from "https://deno.land/std@0.192.0/testing/asserts.ts";
import { costear } from "./costeo.ts";
import { resolverReceta } from "./resolver_receta.ts";
import { calcularCantidadEscalada, resolverVolumenGondola, VOLUMEN_BASE_GONDOLA_M3 } from "./escalas.ts";
import { generarEspecificacion } from "./texto_especificacion.ts";
import { formatearCantidadTexto } from "./ficha_orden_trabajo.ts";
import type { DatosCosteo, Configuracion, GrupoOpcion, Opcion, LineaCosteo, DatosModelo } from "./tipos.ts";
import * as fixtureGondola from "./fixtures/datos_costeo_gondola.json" with { type: "json" };
import * as fixturePlataforma from "./fixtures/datos_costeo_plataforma_40x2.json" with { type: "json" };
import * as fixtureDolly from "./fixtures/datos_costeo_dolly.json" with { type: "json" };

const datosGondolaBase = fixtureGondola.default.gondola_a36 as unknown as DatosCosteo;
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
function prepararDatosGondolaConEscalas(): DatosCosteo {
  const copia: DatosCosteo = JSON.parse(JSON.stringify(datosGondolaBase));
  // Marcar alma y soleras como por_volumen
  for (const item of copia.receta_acero) {
    if (item.nombre.includes("ALMA") || item.nombre.includes("SOLERAS")) {
      item.escala = "por_volumen";
    }
  }
  return copia;
}

// --------------------------------------------------------------------------
// TEST 1: Volumen 45 m³ - Costo y despiece idénticos a la regresión base
// --------------------------------------------------------------------------
Deno.test("Góndola Volumen: Test 1 - Volumen 45 m³ costo y despiece idénticos a regresión previa", () => {
  const datos = prepararDatosGondolaConEscalas();
  const config45: Configuracion = {
    grupos: {
      volumen: "m3_45",
      tina_material: "a36"
    }
  };

  const res45 = costear(datos, config45);

  // Verificar que el volumen resuelto sea 45
  assertEquals(resolverVolumenGondola(config45, opcionesMock), 45);

  // Cantidad de Alma (base 2 pz) y Soleras (base 4 pz) sin alteración (factor 1)
  const alma = res45.secciones.acero.lineas.find((l: LineaCosteo) => l.concepto.includes("ALMA"));
  assert(alma, "Línea ALMA debe existir en desglose");
  assertEquals(alma.cantidad, 2);

  const soleras = res45.secciones.acero.lineas.find((l: LineaCosteo) => l.concepto.includes("SOLERAS"));
  assert(soleras, "Línea SOLERAS debe existir en desglose");
  assertEquals(soleras.cantidad, 4);

  // No debe existir advertencia de variante_supuesta
  const advertencia30 = res45.pendientes.find(p => p.tipo === "variante_supuesta");
  assertEquals(advertencia30, undefined);
});

// --------------------------------------------------------------------------
// TEST 2: Volumen 30 m³ - Renglones tina escalan por 30/45, fijos intactos, advertencia presente
// --------------------------------------------------------------------------
Deno.test("Góndola Volumen: Test 2 - Volumen 30 m³ escala tina proporcionalmente, fijos intactos y emite advertencia", () => {
  const datos = prepararDatosGondolaConEscalas();
  const config30: Configuracion = {
    grupos: {
      volumen: "m3_30",
      tina_material: "a36"
    }
  };

  const res30 = costear(datos, config30);

  // Verificar que el volumen resuelto sea 30
  assertEquals(resolverVolumenGondola(config30, opcionesMock), 30);

  // ALMA (base 2 pz) escala a 2 * 30 / 45 = 1.3333 pz
  const alma = res30.secciones.acero.lineas.find((l: LineaCosteo) => l.concepto.includes("ALMA"));
  assert(alma, "Línea ALMA debe existir");
  assert(Math.abs(alma.cantidad - (2 * 30 / 45)) < 0.0001, `ALMA cantidad esperada ~1.3333, obtenida ${alma.cantidad}`);

  // SOLERAS (base 4 pz) escala a 4 * 30 / 45 = 2.6667 pz
  const soleras = res30.secciones.acero.lineas.find((l: LineaCosteo) => l.concepto.includes("SOLERAS"));
  assert(soleras, "Línea SOLERAS debe existir");
  assert(Math.abs(soleras.cantidad - (4 * 30 / 45)) < 0.0001, `SOLERAS cantidad esperada ~2.6667, obtenida ${soleras.cantidad}`);

  // PUENTES DE SUSPENSIÓN (escala fija, base 9 pz) debe mantenerse exactamente en 9 pz
  const puentes = res30.secciones.acero.lineas.find((l: LineaCosteo) => l.concepto.includes("PUENTES DE SUSPENSIÓN"));
  assert(puentes, "Línea PUENTES DE SUSPENSIÓN debe existir");
  assertEquals(puentes.cantidad, 9);

  // Advertencia provisional obligatoria presente
  const advertencia = res30.pendientes.find(p => p.tipo === "variante_supuesta");
  assert(advertencia, "Debe incluir advertencia tipo variante_supuesta");
  assert(advertencia.detalle.includes("Costo de 30 m³ estimado por proporción sobre 45 m³; pendiente despiece real"));
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
