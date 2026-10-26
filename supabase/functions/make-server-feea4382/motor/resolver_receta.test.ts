import { assertEquals, assert } from "https://deno.land/std@0.192.0/testing/asserts.ts";
import { resolverReceta } from "./resolver_receta.ts";
import { validarCompatibilidad, obtenerRetractilesDeClaveAbs, RETRACTILES_POR_ABS } from "./reglas_compatibilidad.ts";
import * as fixtureData from "./fixtures/datos_modelo.json" with { type: "json" };
import type { DatosModelo, Configuracion, Opcion } from "./tipos.ts";

const datos = fixtureData.default as DatosModelo;

Deno.test("1. Un grupo exclusivo, una opción", () => {
  const config: Configuracion = { grupos: { suspension: "alta_hendrickson", retractil: "grande", eje: "hendrickson", patin: "hj" } };
  const res = resolverReceta(datos, config);
  const piernas = res.lineas.filter(l => l.nombre.includes("PIERNA"));
  const platos = res.lineas.filter(l => l.nombre.includes("PLATO"));
  
  // Should only be exactly ONE matching components, not from other options
  assertEquals(piernas.length, 1);
  assertEquals(platos.length, 1);
});

Deno.test("2. por_eje (3 ejes)", () => {
  const datos3Ejes = JSON.parse(JSON.stringify(datos)) as DatosModelo;
  datos3Ejes.modelo.num_ejes = 3;
  
  const config: Configuracion = { grupos: { rines: { opcion: "acero", marca: "ampro" }, suspension: "alta_hendrickson", retractil: "grande", eje: "hendrickson", patin: "hj" } };
  const res = resolverReceta(datos3Ejes, config);
  
  const rines = res.lineas.find(l => l.nombre === "RIN DE ACERO AMPRO");
  assertEquals(rines?.cantidad, 12); // 4 per axle * 3 axles

  const piernas = res.lineas.find(l => l.nombre.includes("PIERNA"));
  // quantity in manual is 1 per axle
  assertEquals(piernas?.cantidad, 3);
});

Deno.test("3. unica_con_cantidad", () => {
  const config: Configuracion = { grupos: { rines: { opcion: "acero", marca: "ampro", cantidad: 6 }, suspension: "alta_hendrickson", retractil: "grande", eje: "hendrickson", patin: "hj" } };
  const res2 = resolverReceta(datos, config);
  assertEquals(res2.lineas.find(l => l.nombre === "RIN DE ACERO AMPRO")?.cantidad, 6);
});

Deno.test("4. sin_gancho", () => {
  const config: Configuracion = { grupos: { gancho: "sin_gancho", suspension: "alta_hendrickson", retractil: "grande", eje: "hendrickson", patin: "hj" } };
  const res = resolverReceta(datos, config);
  const kitGancho = res.lineas.find(l => l.nombre.includes("GANCHO"));
  assert(!kitGancho);
});

Deno.test("5. Redilas", () => {
  const config: Configuracion = { grupos: { redilas: "80", suspension: "alta_hendrickson", retractil: "grande", eje: "hendrickson", patin: "hj" } };
  const res = resolverReceta(datos, config);
  const tornillos = res.lineas.find(l => l.nombre === "TORNILLO CABEZA DE COCHE 1/4 X 1 1/2");
  assert(tornillos);
  assertEquals(tornillos.cantidad, 444);

  const config2: Configuracion = { grupos: { redilas: "sin_redilas", suspension: "alta_hendrickson", retractil: "grande", eje: "hendrickson", patin: "hj" } };
  const res2 = resolverReceta(datos, config2);
  const tornillos2 = res2.lineas.find(l => l.nombre === "TORNILLO CABEZA DE COCHE 1/4 X 1 1/2");
  assert(!tornillos2);
});

Deno.test("6. Escala por largo", () => {
  const largos = [35, 40, 42, 43, 45, 48];
  const esperados = [0.875, 1.0, 1.05, 1.075, 1.125, 1.2];
  
  for (let i = 0; i < largos.length; i++) {
    const mock = JSON.parse(JSON.stringify(datos)) as DatosModelo;
    mock.modelo.largo_ft = largos[i];
    
    const res = resolverReceta(mock, { grupos: { suspension: "alta_hendrickson", retractil: "grande", eje: "hendrickson", patin: "hj" } });
    const consumible = res.lineas.find(l => l.nombre === "CONSUMIBLE 65");
    assert(consumible);
    assertEquals(consumible.cantidad, esperados[i]);
  }
});

Deno.test("7. Incompatibilidad", () => {
  const config1: Configuracion = { grupos: { suspension: "alta_hendrickson", retractil: "chico", eje: "hendrickson", patin: "hj" } };
  const res1 = resolverReceta(datos, config1);
  assert(res1.errores.some(e => e.includes("Incompatibilidad")));

  const config2: Configuracion = { grupos: { suspension: "hendrickson", retractil: "grande", eje: "hendrickson", patin: "hj" } };
  const res2 = resolverReceta(datos, config2);
  assert(res2.errores.some(e => e.includes("Incompatibilidad")));
  
  // Regla dona vs gancho
  const config3: Configuracion = { grupos: { dona: "holland", gancho: "premier_8" } };
  const res3 = resolverReceta(datos, config3);
  assert(res3.errores.some(e => e.includes("corresponde al gancho")));
});

Deno.test("8. Suma de repetidos", () => {
  const res = resolverReceta(datos, { grupos: { suspension: "alta_hendrickson", retractil: "grande", eje: "hendrickson", patin: "hj" } });
  const consumible = res.lineas.find(l => l.nombre === "CONSUMIBLE 65");
  assertEquals(consumible?.cantidad, 1.0);
  assertEquals(consumible?.paso.length, 3);
});

Deno.test("9. sin_mapear", () => {
  const res = resolverReceta(datos, { grupos: { suspension: "alta_hendrickson", retractil: "grande", eje: "hendrickson", patin: "hj" } });
  assert(res.omitidas.some(o => o.descripcion.includes("sin mapear")));
});

Deno.test("10. Operadores de condicion", () => {
  // Test '=', unknown operator, and fields 'ejes' / 'largo_ft'
  const mockDatos = JSON.parse(JSON.stringify(datos)) as DatosModelo;
  mockDatos.receta_base.push({ material_id: "EQ", nombre: "TEST EQ", cantidad: 1, escala: "fija", paso: "1", uso: null, condicion: { todas: [{ campo: "largo_ft", op: "=", valor: 40 }] }, unidad: "PZA", costo: 1, descripcion: "" });
  mockDatos.receta_base.push({ material_id: "IN", nombre: "TEST IN", cantidad: 1, escala: "fija", paso: "1", uso: null, condicion: { todas: [{ campo: "ejes", op: "in", valor: [2, 3] }] }, unidad: "PZA", costo: 1, descripcion: "" });
  mockDatos.receta_base.push({ material_id: "UK", nombre: "TEST UK", cantidad: 1, escala: "fija", paso: "1", uso: null, condicion: { todas: [{ campo: "ejes", op: "??", valor: 2 }] }, unidad: "PZA", costo: 1, descripcion: "" });

  const res = resolverReceta(mockDatos, { grupos: { suspension: "alta_hendrickson", retractil: "grande", eje: "hendrickson", patin: "hj" } });
  
  assert(res.lineas.some(l => l.nombre === "TEST EQ"));
  assert(res.lineas.some(l => l.nombre === "TEST IN"));
  assert(!res.lineas.some(l => l.nombre === "TEST UK"));
  assert(res.errores.some(e => e.includes("Operador desconocido")));
});

Deno.test("11. Sustitutos", () => {
  const res = resolverReceta(datos, { grupos: { suspension: "alta_hendrickson", retractil: "grande", eje: "hendrickson", patin: "hj" } });
  assert(res.alternativas.length > 0);
  assert(res.alternativas[0].reemplaza === null);
  assert(res.alternativas[0].posibles_reemplazos.length > 0);
});

Deno.test("12. Marca de rines", () => {
  // 4 aluminum brands, steel acurrai
  const configs = [
    { config: { grupos: { rines: { opcion: "aluminio", marca: "ampro" } } }, expected: "RIN DE ALUMINIO AMPRO" },
    { config: { grupos: { rines: { opcion: "aluminio", marca: "ampro trapezoidal" } } }, expected: "RIN DE ALUMINIO AMPRO MASTER TRAPEZOIDAL" },
    { config: { grupos: { rines: { opcion: "aluminio", marca: "fleet master" } } }, expected: "RIN DE ALUMINIO FLEET MASTER" },
    { config: { grupos: { rines: { opcion: "aluminio", marca: "fleet master trapezoidal" } } }, expected: "RIN DE ALUMINIO FLEET MASTER TRAPEZOIDAL" },
    { config: { grupos: { rines: { opcion: "acero", marca: "acurrai" } } }, expected: "RIN DE ACERO ACURRAI" }
  ];

  for (const c of configs) {
    const res = resolverReceta(datos, c.config as Configuracion);
    assert(res.lineas.some(l => l.nombre === c.expected), `Missing ${c.expected}`);
  }
});

Deno.test("13. Opción sin receta", () => {
  const config: Configuracion = { grupos: { piso: "laminado", suspension: "alta_hendrickson", retractil: "grande", eje: "hendrickson", patin: "hj" } };
  const res = resolverReceta(datos, config);
  assert(res.advertencias.some(a => a.toLowerCase().includes("piso") || a.toLowerCase().includes("laminado")));
  assertEquals(res.completo, false);
});

Deno.test("14. Precios y secciones pendientes", () => {
  const config: Configuracion = { grupos: { suspension: "alta_hendrickson", retractil: "grande", eje: "hendrickson", patin: "hj" } };
  const res = resolverReceta(datos, config);
  assert(res.sin_precio.length > 0);
  assertEquals(res.secciones_pendientes, ["acero"]);
  assertEquals(res.completo, false);
});

Deno.test("15. Control cruzado", () => {
  const config: Configuracion = {
    grupos: {
      suspension: "fleet_master",
      eje: "fleet_master",
      patin: "hj",
      retractil: "chico"
    }
  };
  const res = resolverReceta(datos, config);

  const report = [
    "Piernas",
    "Platos",
    "Amortiguador",
    "Camara",
    "Abrazadera",
    "Eje",
    "Patin",
    "Rin",
    "Llanta",
    "CONSUMIBLE 65"
  ];

  console.log("\n--- TABLA CONTROL CRUZADO (Factura Leolca) ---");
  report.forEach(item => {
    let lines: typeof res.lineas = [];
    if (item === "Piernas") lines = res.lineas.filter(l => l.nombre.includes("PIERNA"));
    else if (item === "Platos") lines = res.lineas.filter(l => l.nombre.includes("PLATO"));
    else if (item === "Amortiguador") lines = res.lineas.filter(l => l.nombre.includes("AMORTIGUADOR"));
    else if (item === "Camara") lines = res.lineas.filter(l => l.nombre.includes("CAMARA"));
    else if (item === "Abrazadera") lines = res.lineas.filter(l => l.nombre.includes("ABRAZADERA"));
    else if (item === "Eje") lines = res.lineas.filter(l => l.nombre.startsWith("EJE "));
    else if (item === "Patin") lines = res.lineas.filter(l => l.nombre.includes("PATIN"));
    else if (item === "Rin") lines = res.lineas.filter(l => l.nombre.startsWith("RIN "));
    else if (item === "Llanta") lines = res.lineas.filter(l => l.nombre.includes("LLANTA"));
    else if (item === "CONSUMIBLE 65") lines = res.lineas.filter(l => l.nombre === "CONSUMIBLE 65");

    const qty = lines.reduce((acc, curr) => acc + curr.cantidad, 0);
    console.log(`${item.padEnd(20)} | ${qty}`);
  });
  console.log("----------------------------------------------\n");
});

Deno.test("16. Validaciones (ausente unica, desconocido, inactiva)", () => {
  const mockDatos = JSON.parse(JSON.stringify(datos)) as DatosModelo;
  // Mark something inactive
  const opt = mockDatos.opciones.find(o => o.clave === "chico");
  if (opt) opt.activo = false;

  // Pass an empty config
  const configVacia: Configuracion = { grupos: {} };
  const resVacia = resolverReceta(mockDatos, configVacia);
  // Should report missing mandatory groups (like suspension, ejes, patin, retractil)
  assert(resVacia.errores.some(e => e.includes("Falta elegir")));

  // Pass unknown group and inactive option
  const configMala: Configuracion = { grupos: { grupo_inventado: "xyz", retractil: "chico" } };
  const resMala = resolverReceta(mockDatos, configMala);
  assert(resMala.errores.some(e => e.includes("Grupo desconocido")));
  assert(resMala.errores.some(e => e.includes("está inactiva")));
});

Deno.test("17. Modelo con renglones seccion='acero' y paso nulo", () => {
  const mockDatos = JSON.parse(JSON.stringify(datos)) as DatosModelo;
  mockDatos.receta_base.push({
    material_id: "mat_acero_1",
    nombre: "VIGA PRINCIPAL ACERO",
    unidad: "PZA",
    costo: 5000,
    descripcion: "Acero estructural",
    cantidad: 2,
    escala: "fija",
    paso: null,
    uso: "Chasis",
    seccion: "acero"
  });

  const config: Configuracion = {
    grupos: {
      suspension: "alta_hendrickson",
      retractil: "grande",
      eje: "hendrickson",
      patin: "hj"
    }
  };

  const res = resolverReceta(mockDatos, config);
  assertEquals(res.secciones_pendientes, []);

  const lineaAcero = res.lineas.find(l => l.material_id === "mat_acero_1");
  assert(lineaAcero, "Debe existir la línea de acero");
  assertEquals(lineaAcero.seccion, "acero");
  assert(!lineaAcero.paso.includes(null as any), "El arreglo paso no debe contener null");
  assertEquals(lineaAcero.paso, []);
});

Deno.test("18. Modelo sin acero marca secciones_pendientes = ['acero']", () => {
  const mockDatos = JSON.parse(JSON.stringify(datos)) as DatosModelo;
  mockDatos.receta_base = mockDatos.receta_base.filter(r => r.seccion !== "acero");

  const config: Configuracion = {
    grupos: {
      suspension: "alta_hendrickson",
      retractil: "grande",
      eje: "hendrickson",
      patin: "hj"
    }
  };

  const res = resolverReceta(mockDatos, config);
  assertEquals(res.secciones_pendientes, ["acero"]);
});

Deno.test("19. 2R-8: Rines mixtos (8 acero + 4 aluminio) generan ambas líneas BOM y no degradan completo", () => {
  const datos3Ejes = JSON.parse(JSON.stringify(datos)) as DatosModelo;
  datos3Ejes.modelo.num_ejes = 3;

  // Asignar regla max_total al grupo rines en la fixture
  const grpRines = datos3Ejes.grupos.find(g => g.clave === "rines");
  if (grpRines) {
    grpRines.regla = { max_total: { por_eje: 4 } };
    grpRines.seleccion = "multiple_con_cantidad";
  }

  const config: Configuracion = {
    grupos: {
      suspension: "alta_hendrickson",
      retractil: "grande",
      eje: "hendrickson",
      patin: "hj",
      rines: [
        { opcion: "acero", marca: "Ampro", cantidad: 8 },
        { opcion: "aluminio", marca: "Ampro", cantidad: 4 }
      ]
    }
  };

  const res = resolverReceta(datos3Ejes, config);
  const lineaAcero = res.lineas.find(l => l.nombre === "RIN DE ACERO AMPRO");
  const lineaAluminio = res.lineas.find(l => l.nombre === "RIN DE ALUMINIO AMPRO");

  assert(lineaAcero, "Debe existir línea de rines de acero");
  assertEquals(lineaAcero.cantidad, 8);
  assert(lineaAluminio, "Debe existir línea de rines de aluminio");
  assertEquals(lineaAluminio.cantidad, 4);

  assertEquals(res.errores.filter(e => e.toLowerCase().includes("rin")), []);
  assert(!res.advertencias.some(a => a.toLowerCase().includes("rin")));
});

Deno.test("20. 2R-8: Duplicados en la misma opción y marca se fusionan antes de procesar", () => {
  const datos3Ejes = JSON.parse(JSON.stringify(datos)) as DatosModelo;
  datos3Ejes.modelo.num_ejes = 3;

  const grpRines = datos3Ejes.grupos.find(g => g.clave === "rines");
  if (grpRines) grpRines.regla = { max_total: { por_eje: 4 } };

  const config: Configuracion = {
    grupos: {
      suspension: "alta_hendrickson",
      retractil: "grande",
      eje: "hendrickson",
      patin: "hj",
      rines: [
        { opcion: "acero", marca: "Ampro", cantidad: 4 },
        { opcion: "acero", marca: "Ampro", cantidad: 4 }
      ]
    }
  };

  const res = resolverReceta(datos3Ejes, config);
  const lineasAcero = res.lineas.filter(l => l.nombre === "RIN DE ACERO AMPRO");
  assertEquals(lineasAcero.length, 1);
  assertEquals(lineasAcero[0].cantidad, 8);
});

Deno.test("21. 2R-8: Exceso de piezas arroja error exacto y piezas faltantes arroja advertencia", () => {
  const datos2Ejes = JSON.parse(JSON.stringify(datos)) as DatosModelo;
  datos2Ejes.modelo.num_ejes = 2; // máx rines = 8

  const grpRines = datos2Ejes.grupos.find(g => g.clave === "rines");
  if (grpRines) grpRines.regla = { max_total: { por_eje: 4 } };

  // 10 piezas cuando el máximo es 8 -> error
  const configExceso: Configuracion = {
    grupos: {
      suspension: "alta_hendrickson",
      retractil: "grande",
      eje: "hendrickson",
      patin: "hj",
      rines: [
        { opcion: "acero", marca: "Ampro", cantidad: 6 },
        { opcion: "aluminio", marca: "Ampro", cantidad: 4 }
      ]
    }
  };
  const resExceso = resolverReceta(datos2Ejes, configExceso);
  assert(resExceso.errores.some(e => e === "Los rines suman 10 piezas y el máximo para este modelo es 8"));
  assertEquals(resExceso.completo, false);

  // 4 piezas cuando el máximo es 8 -> advertencia, no error
  const configFaltante: Configuracion = {
    grupos: {
      suspension: "alta_hendrickson",
      retractil: "grande",
      eje: "hendrickson",
      patin: "hj",
      rines: [
        { opcion: "acero", marca: "Ampro", cantidad: 4 }
      ]
    }
  };
  const resFaltante = resolverReceta(datos2Ejes, configFaltante);
  assertEquals(resFaltante.errores.filter(e => e.includes("suman")), []);
  assert(resFaltante.advertencias.some(a => a === "Faltan 4 rines por definir"));
});

Deno.test("22. 2R-8: Opción cliente en rines no arroja advertencia de sin receta y cuenta para el tope", () => {
  const datos2Ejes = JSON.parse(JSON.stringify(datos)) as DatosModelo;
  datos2Ejes.modelo.num_ejes = 2;

  const grpRines = datos2Ejes.grupos.find(g => g.clave === "rines");
  if (grpRines) grpRines.regla = { max_total: { por_eje: 4 } };

  const config: Configuracion = {
    grupos: {
      suspension: "alta_hendrickson",
      retractil: "grande",
      eje: "hendrickson",
      patin: "hj",
      rines: [
        { opcion: "cliente", cantidad: 8 }
      ]
    }
  };
  const res = resolverReceta(datos2Ejes, config);
  assert(!res.advertencias.some(a => a.includes("cliente")));
  assertEquals(res.errores.filter(e => e.toLowerCase().includes("rin")), []);
});

Deno.test("23. 2R-8: Regla 3 - Filas sin cantidad en grupos con max_total (retrocompatibilidad y validación)", () => {
  const datos2Ejes = JSON.parse(JSON.stringify(datos)) as DatosModelo;
  datos2Ejes.modelo.num_ejes = 2; // máx rines = 8

  const grpRines = datos2Ejes.grupos.find(g => g.clave === "rines");
  if (grpRines) {
    grpRines.regla = { max_total: { por_eje: 4 } };
    grpRines.seleccion = "multiple_con_cantidad";
  }

  // 1. String 'acero' sin cantidad en 2 ejes → sin error ni advertencia de piezas
  const err1: string[] = [];
  const adv1: string[] = [];
  validarCompatibilidad({ grupos: { rines: "acero" } }, datos2Ejes, err1, adv1);
  assertEquals(err1, []);
  assertEquals(adv1, []);

  // 2. { opcion: "acero", marca: "Ampro" } sin cantidad en 2 ejes → sin error ni advertencia
  const err2: string[] = [];
  const adv2: string[] = [];
  validarCompatibilidad({ grupos: { rines: { opcion: "acero", marca: "Ampro" } } }, datos2Ejes, err2, adv2);
  assertEquals(err2, []);
  assertEquals(adv2, []);

  // También probado a través de resolverReceta completo
  const resObj = resolverReceta(datos2Ejes, {
    grupos: {
      suspension: "alta_hendrickson",
      retractil: "grande",
      eje: "hendrickson",
      patin: "hj",
      rines: { opcion: "acero", marca: "Ampro" }
    }
  });
  assertEquals(resObj.errores.filter(e => e.toLowerCase().includes("rin")), []);
  assertEquals(resObj.advertencias.filter(a => a.toLowerCase().includes("rin")), []);

  // 3. Dos filas sin cantidad → error "Indica la cantidad de cada fila"
  const err3: string[] = [];
  const adv3: string[] = [];
  validarCompatibilidad({
    grupos: {
      rines: [
        { opcion: "acero", marca: "Ampro" },
        { opcion: "aluminio", marca: "Ampro" }
      ]
    }
  }, datos2Ejes, err3, adv3);
  assertEquals(err3.length, 1);
  assert(err3[0].toLowerCase().includes("indica la cantidad de cada fila"));

  // 4. Una fila con cantidad 4 y otra sin cantidad → error "Indica la cantidad de cada fila"
  const err4: string[] = [];
  const adv4: string[] = [];
  validarCompatibilidad({
    grupos: {
      rines: [
        { opcion: "acero", marca: "Ampro", cantidad: 4 },
        { opcion: "aluminio", marca: "Ampro" }
      ]
    }
  }, datos2Ejes, err4, adv4);
  assertEquals(err4.length, 1);
  assert(err4[0].toLowerCase().includes("indica la cantidad de cada fila"));
});

Deno.test("24. 2R-10: Regla 3 con cantidad_defecto en retractil (1 pieza, tope por eje y validación)", () => {
  const datos2Ejes = JSON.parse(JSON.stringify(datos)) as DatosModelo;
  datos2Ejes.modelo.num_ejes = 2; // máx retráctiles = 2 (1 por eje)

  const grpRetr = datos2Ejes.grupos.find(g => g.clave === "retractil");
  if (grpRetr) {
    grpRetr.regla = { max_total: { por_eje: 1 }, cantidad_defecto: 1 };
    grpRetr.seleccion = "multiple_con_cantidad";
  }
  const grpRines = datos2Ejes.grupos.find(g => g.clave === "rines");
  if (grpRines) {
    grpRines.regla = { max_total: { por_eje: 4 }, cantidad_defecto: "max" };
    grpRines.seleccion = "multiple_con_cantidad";
  }

  // 1. rines: 'acero' sin cantidad sigue siendo el juego completo (8 en 2 ejes), sin error ni advertencia
  const errRin: string[] = [];
  const advRin: string[] = [];
  validarCompatibilidad({ grupos: { rines: "acero" } }, datos2Ejes, errRin, advRin);
  assertEquals(errRin, []);
  assertEquals(advRin, []);

  // 2. retractil: 'chico' (texto, forma vieja) vale 1 pieza y no genera advertencias ni errores
  const errRetr1: string[] = [];
  const advRetr1: string[] = [];
  validarCompatibilidad({ grupos: { retractil: "chico" } }, datos2Ejes, errRetr1, advRetr1);
  assertEquals(errRetr1, []);
  assertEquals(advRetr1, []);

  // 3. retractil: [{ chico ×1 }, { grande ×1 }] en 2 ejes = 2 (válido)
  const errRetr2: string[] = [];
  const advRetr2: string[] = [];
  validarCompatibilidad({
    grupos: {
      retractil: [
        { opcion: "chico", cantidad: 1 },
        { opcion: "grande", cantidad: 1 }
      ]
    }
  }, datos2Ejes, errRetr2, advRetr2);
  assertEquals(errRetr2, []);
  assertEquals(advRetr2, []);

  // 4. 3 retráctiles en 2 ejes → error "Los retráctiles suman 3 piezas y el máximo para este modelo es 2"
  const errRetr3: string[] = [];
  const advRetr3: string[] = [];
  validarCompatibilidad({
    grupos: {
      retractil: [
        { opcion: "chico", cantidad: 3 }
      ]
    }
  }, datos2Ejes, errRetr3, advRetr3);
  assertEquals(errRetr3, [
    "Los retráctiles suman 3 piezas y el máximo para este modelo es 2"
  ]);
});

Deno.test("25. 2R-10: resolverReceta / BOM genera líneas para 2 filas de retractil con sus cantidades", () => {
  const datos2Ejes = JSON.parse(JSON.stringify(datos)) as DatosModelo;
  datos2Ejes.modelo.num_ejes = 2;

  const grpRetr = datos2Ejes.grupos.find(g => g.clave === "retractil");
  if (grpRetr) {
    grpRetr.regla = { max_total: { por_eje: 1 }, cantidad_defecto: 1 };
    grpRetr.seleccion = "multiple_con_cantidad";
  }

  const config: Configuracion = {
    grupos: {
      suspension: "alta_hendrickson",
      eje: "hendrickson",
      patin: "hj",
      abs: "3e_2_retractil", // 2 retráctiles contemplados
      retractil: [
        { opcion: "grande", cantidad: 1 },
        { opcion: "chico", cantidad: 1 }
      ]
    }
  };

  const res = resolverReceta(datos2Ejes, config);
  const lineasGrande = res.lineas.filter(l => l.nombre.includes("SISTEMA RETRACTIL GRANDE"));
  const lineasChico = res.lineas.filter(l => l.nombre.includes("SISTEMA RETRACTIL CHICO"));

  assertEquals(lineasGrande.length, 1);
  assertEquals(lineasGrande[0].cantidad, 1);
  assertEquals(lineasChico.length, 1);
  assertEquals(lineasChico[0].cantidad, 1);

  // Opción sin receta (ej. paleta o una opción ficticia sin componentes) genera advertencia habitual
  const datosConSinReceta = JSON.parse(JSON.stringify(datos2Ejes)) as DatosModelo;
  datosConSinReceta.opciones.push({
    id: "opt-retractil-sin-receta",
    grupo_id: grpRetr!.id,
    clave: "retractil_custom",
    nombre: "Retráctil Custom",
    activo: true,
    precio_venta: 15000,
    clase: "normal"
  });
  const resSinReceta = resolverReceta(datosConSinReceta, {
    grupos: {
      suspension: "alta_hendrickson",
      eje: "hendrickson",
      patin: "hj",
      retractil: "retractil_custom"
    }
  });
  assert(resSinReceta.advertencias.some(a => a.includes("Retráctil Custom no tiene receta configurada")));
});

Deno.test("26. 2R-10: Coherencia con el kit de aire (abs) y cantidad de retráctiles", () => {
  // 1. Diccionario explícito de claves actuales
  assertEquals(RETRACTILES_POR_ABS["2e_sin_retractil"], 0);
  assertEquals(RETRACTILES_POR_ABS["2e_1_retractil"], 1);
  assertEquals(RETRACTILES_POR_ABS["3e_sin_retractil"], 0);
  assertEquals(RETRACTILES_POR_ABS["3e_1_retractil"], 1);
  assertEquals(RETRACTILES_POR_ABS["3e_2_retractil"], 2);

  // 2. Función pura obtenerRetractilesDeClaveAbs
  assertEquals(obtenerRetractilesDeClaveAbs("2e_sin_retractil"), 0);
  assertEquals(obtenerRetractilesDeClaveAbs("2e_1_retractil"), 1);
  assertEquals(obtenerRetractilesDeClaveAbs("3e_1_retractil"), 1);
  assertEquals(obtenerRetractilesDeClaveAbs("3e_2_retractil"), 2);
  assertEquals(obtenerRetractilesDeClaveAbs("clave_desconocida_xyz"), null);

  // 3. Advertencia cuando el kit de aire es para 1 retráctil y se eligen 2
  const datos2Ejes = JSON.parse(JSON.stringify(datos)) as DatosModelo;
  datos2Ejes.modelo.num_ejes = 2;
  const grpRetr = datos2Ejes.grupos.find(g => g.clave === "retractil");
  if (grpRetr) {
    grpRetr.regla = { max_total: { por_eje: 1 }, cantidad_defecto: 1 };
    grpRetr.seleccion = "multiple_con_cantidad";
  }

  const errAdv: string[] = [];
  const advLista: string[] = [];
  validarCompatibilidad({
    grupos: {
      abs: "2e_1_retractil", // contempla 1 retráctil
      retractil: [
        { opcion: "grande", cantidad: 1 },
        { opcion: "chico", cantidad: 1 }
      ] // suman 2
    }
  }, datos2Ejes, errAdv, advLista);

  assertEquals(errAdv, []);
  assertEquals(advLista, [
    "El kit de aire elegido es para 1 retráctil y elegiste 2; revisa el kit de aire (no hay precio para esa combinación)"
  ]);

  // 4. Sin advertencia cuando coincide (ej. 2e_1_retractil y 1 retráctil)
  const advCoincide: string[] = [];
  validarCompatibilidad({
    grupos: {
      abs: "2e_1_retractil",
      retractil: "chico" // vale 1
    }
  }, datos2Ejes, [], advCoincide);
  assertEquals(advCoincide, []);

  // 5. Clave desconocida nueva no encaja -> no advertir
  const advDesconocida: string[] = [];
  validarCompatibilidad({
    grupos: {
      abs: "clave_nueva_especial",
      retractil: [
        { opcion: "chico", cantidad: 2 }
      ]
    }
  }, datos2Ejes, [], advDesconocida);
  assertEquals(advDesconocida, []);
});

Deno.test("27. Sub-bloque 2R-12: Límites de retráctiles por num_ejes (2 ejes -> max 1, 3 ejes -> max 2), paleta a grande, color personalizado", () => {
  const datos2Ejes = JSON.parse(JSON.stringify(datos)) as DatosModelo;
  datos2Ejes.modelo.num_ejes = 2;

  const datos3Ejes = JSON.parse(JSON.stringify(datos)) as DatosModelo;
  datos3Ejes.modelo.num_ejes = 3;

  // 1. Plataforma 2 ejes con 2 retráctiles -> error exacto
  const err2e2r: string[] = [];
  const adv2e2r: string[] = [];
  validarCompatibilidad({
    grupos: {
      retractil: [
        { opcion: "grande", cantidad: 2 }
      ]
    }
  }, datos2Ejes, err2e2r, adv2e2r);
  assertEquals(err2e2r, [
    "Los retráctiles suman 2 piezas y el máximo para este modelo es 1"
  ]);

  // 2. Plataforma 3 ejes con 2 retráctiles -> válido
  const err3e2r: string[] = [];
  const adv3e2r: string[] = [];
  validarCompatibilidad({
    grupos: {
      retractil: [
        { opcion: "chico", cantidad: 1 },
        { opcion: "grande", cantidad: 1 }
      ]
    }
  }, datos3Ejes, err3e2r, adv3e2r);
  assertEquals(err3e2r, []);

  // 3. Plataforma 3 ejes con 3 retráctiles -> error exacto
  const err3e3r: string[] = [];
  const adv3e3r: string[] = [];
  validarCompatibilidad({
    grupos: {
      retractil: [
        { opcion: "grande", cantidad: 3 }
      ]
    }
  }, datos3Ejes, err3e3r, adv3e3r);
  assertEquals(err3e3r, [
    "Los retráctiles suman 3 piezas y el máximo para este modelo es 2"
  ]);

  // 4. 0 retráctiles (sin_retractil o sin filas) -> válido
  const err0rSin: string[] = [];
  validarCompatibilidad({
    grupos: {
      retractil: "sin_retractil"
    }
  }, datos2Ejes, err0rSin, []);
  assertEquals(err0rSin, []);

  const err0rVacio: string[] = [];
  validarCompatibilidad({
    grupos: {}
  }, datos2Ejes, err0rVacio, []);
  assertEquals(err0rVacio, []);

  // 5. Configuración vieja retractil: 'chico' -> 1 pieza, válida en 2 ejes
  const errVieja: string[] = [];
  validarCompatibilidad({
    grupos: {
      retractil: "chico"
    }
  }, datos2Ejes, errVieja, []);
  assertEquals(errVieja, []);

  // 6. Suspensión alta con retractil 'paleta' -> normaliza a 'grande' y NO arroja error de incompatibilidad
  const errPaleta: string[] = [];
  validarCompatibilidad({
    grupos: {
      suspension: "alta_hendrickson",
      retractil: "paleta"
    }
  }, datos2Ejes, errPaleta, []);
  assertEquals(errPaleta, []);

  // Contrastar con suspensión alta y retractil 'chico' -> arroja error
  const errChico: string[] = [];
  validarCompatibilidad({
    grupos: {
      suspension: "alta_hendrickson",
      retractil: "chico"
    }
  }, datos2Ejes, errChico, []);
  assertEquals(errChico, [
    "Incompatibilidad: La suspensión de clase alta requiere un retráctil grande (seleccionado: Retráctil chico (UBL))."
  ]);

  // 7. BOM: retractil 'paleta' genera línea para SISTEMA RETRACTIL GRANDE y no arroja advertencia
  const resBomPaleta = resolverReceta(datos2Ejes, {
    grupos: {
      suspension: "alta_hendrickson",
      eje: "hendrickson",
      patin: "hj",
      retractil: "paleta"
    }
  });
  const lineaBomGrande = resBomPaleta.lineas.filter(l => l.nombre.includes("SISTEMA RETRACTIL GRANDE"));
  assertEquals(lineaBomGrande.length, 1);
  assertEquals(lineaBomGrande[0].cantidad, 1);
  assertEquals(resBomPaleta.advertencias.some(a => a.includes("receta")), false);

  // 8. Color personalizado: vacío o espacios -> error; texto válido -> sin error
  const errColorVacio: string[] = [];
  validarCompatibilidad({
    grupos: {
      color: { opcion: "personalizado", texto: "   " }
    }
  }, datos2Ejes, errColorVacio, []);
  assertEquals(errColorVacio, [
    "El color personalizado requiere especificar el texto del color."
  ]);

  const errColorOk: string[] = [];
  validarCompatibilidad({
    grupos: {
      color: { opcion: "personalizado", texto: "Azul metálico" }
    }
  }, datos2Ejes, errColorOk, []);
  assertEquals(errColorOk, []);

  // 9. Coherencia kit de aire (abs) con nuevos límites
  const advAbs0: string[] = [];
  validarCompatibilidad({
    grupos: { abs: "2e_sin_retractil", retractil: "sin_retractil" }
  }, datos2Ejes, [], advAbs0);
  assertEquals(advAbs0, []);

  const advAbs1: string[] = [];
  validarCompatibilidad({
    grupos: { abs: "2e_1_retractil", retractil: "chico" }
  }, datos2Ejes, [], advAbs1);
  assertEquals(advAbs1, []);

  const advAbs2: string[] = [];
  validarCompatibilidad({
    grupos: {
      abs: "3e_2_retractil",
      retractil: [
        { opcion: "grande", cantidad: 2 }
      ]
    }
  }, datos3Ejes, [], advAbs2);
  assertEquals(advAbs2, []);
});


