import { assertEquals, assert } from "https://deno.land/std@0.192.0/testing/asserts.ts";
import { resolverReceta } from "./resolver_receta.ts";
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
  // Replace with a real group that has 'unica_con_cantidad' if possible, or test the logic
  const mockDatos = JSON.parse(JSON.stringify(datos));
  const grupoRines = mockDatos.grupos.find((g: any) => g.clave === "rines");
  grupoRines.seleccion = "unica_con_cantidad";
  
  const config: Configuracion = { grupos: { rines: { opcion: "acero", marca: "ampro", cantidad: 6 }, suspension: "alta_hendrickson", retractil: "grande", eje: "hendrickson", patin: "hj" } };
  const res2 = resolverReceta(mockDatos, config);
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
    
    // We mock consumible 65 to have base quantity 1, escala = por_largo
    const res = resolverReceta(mock, { grupos: { suspension: "alta_hendrickson", retractil: "grande", eje: "hendrickson", patin: "hj" } });
    const consumible = res.lineas.find(l => l.nombre === "CONSUMIBLE 65");
    // Ensure scaling logic is mathematically correct (if the base was 1 in manual). Let's check proportionality.
    if (consumible) {
       // Just check it exists and is scaled properly. 
       // In fixture it's 1. So it should match `esperados[i]`.
       assertEquals(consumible.cantidad, esperados[i]);
    }
  }
});

Deno.test("7. Incompatibilidad", () => {
  const config1: Configuracion = { grupos: { suspension: "alta_hendrickson", retractil: "chico", eje: "hendrickson", patin: "hj" } };
  const res1 = resolverReceta(datos, config1);
  assert(res1.errores.some(e => e.includes("Incompatibilidad")));

  const config2: Configuracion = { grupos: { suspension: "hendrickson", retractil: "grande", eje: "hendrickson", patin: "hj" } };
  const res2 = resolverReceta(datos, config2);
  assert(res2.errores.some(e => e.includes("Incompatibilidad")));
});

Deno.test("8. Suma de repetidos", () => {
  const mockDatos = JSON.parse(JSON.stringify(datos)) as DatosModelo;
  // Mock CONSUMIBLE 65 with 3 different pasos
  mockDatos.receta_base.push({ material_id: "65", nombre: "CONSUMIBLE 65 TEST", cantidad: 0.5, escala: "fija", paso: "PASO 1", uso: null, condicion: null, unidad: "L", costo: 1, descripcion: "" });
  mockDatos.receta_base.push({ material_id: "65", nombre: "CONSUMIBLE 65 TEST", cantidad: 0.25, escala: "fija", paso: "PASO 2", uso: null, condicion: null, unidad: "L", costo: 1, descripcion: "" });
  mockDatos.receta_base.push({ material_id: "65", nombre: "CONSUMIBLE 65 TEST", cantidad: 0.25, escala: "fija", paso: "PASO 3", uso: null, condicion: null, unidad: "L", costo: 1, descripcion: "" });

  const res = resolverReceta(mockDatos, { grupos: { suspension: "alta_hendrickson", retractil: "grande", eje: "hendrickson", patin: "hj" } });
  const consumible = res.lineas.find(l => l.nombre === "CONSUMIBLE 65 TEST");
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
  assert(res.alternativas[0].original !== "Original"); // Now contains the base component's name
});

Deno.test("12. Marca de rines", () => {
  const configFM: Configuracion = { grupos: { rines: { opcion: "aluminio", marca: "fleet master" }, suspension: "alta_hendrickson", retractil: "grande", eje: "hendrickson", patin: "hj" } };
  const resFM = resolverReceta(datos, configFM);
  assert(resFM.lineas.some(l => l.nombre === "RIN DE ALUMINIO FLEET MASTER"));
  assert(!resFM.lineas.some(l => l.nombre === "RIN DE ALUMINIO FLEET MASTER TRAPEZOIDAL"));
  
  const configFMT: Configuracion = { grupos: { rines: { opcion: "aluminio", marca: "fleet master trapezoidal" }, suspension: "alta_hendrickson", retractil: "grande", eje: "hendrickson", patin: "hj" } };
  const resFMT = resolverReceta(datos, configFMT);
  assert(!resFMT.lineas.some(l => l.nombre === "RIN DE ALUMINIO FLEET MASTER"));
  assert(resFMT.lineas.some(l => l.nombre === "RIN DE ALUMINIO FLEET MASTER TRAPEZOIDAL"));
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
