import { assertEquals } from "https://deno.land/std@0.192.0/testing/asserts.ts";
import { generarEspecificacion } from "./texto_especificacion.ts";
import * as fixtures from "./fixtures/datos_modelo.json" with { type: "json" };

Deno.test("Generar texto A exacto", () => {
  const { modelo, grupos, opciones } = fixtures.default as any;

  const config = {
    grupos: {
      suspension: "alta_hendrickson",
      eje: "fleet_master",
      patin: "hj",
      retractil: "grande",
      gancho: "holland_8_10",
      redilas: "80",
      rines: { opcion: "acero", marca: "ampro" },
      llantas: "firestone"
    }
  };

  const { texto, resumen_lineas } = generarEspecificacion(modelo, config, grupos, opciones);

  assertEquals(
    texto,
    "SEMIREMOLQUE TIPO: PLATAFORMA 40 FT 2 EJES, CON SUSPENSIÓN HENDRICKSON ALTA HT300US, EJES FLEET MASTER, 2 PAR DE PATÍN HJ, SISTEMA RETRÁCTIL GRANDE, GANCHO DE ARRASTRE HOLLAND 8/10 BARRENOS, REDILAS DE 80 CM, 8 RINES DE ACERO MARCA AMPRO, 8 LLANTAS FIRESTONE"
  );
  
  // Checking exact order of resumen
  const etiquetas = resumen_lineas.map(r => r.etiqueta);
  assertEquals(etiquetas[0], "Estructura (modelo)");
  assertEquals(etiquetas[1], "Ejes");
  assertEquals(etiquetas[2], "Suspensión");
  assertEquals(etiquetas[3], "Patines");
  assertEquals(etiquetas[4], "Redilas"); // skipped frenos, instalacion, frente
});

Deno.test("Generar texto B exacto", () => {
  const { modelo, grupos, opciones } = fixtures.default as any;

  const config = {
    grupos: {
      suspension: "fleet_master",
      eje: "fleet_master",
      patin: "hj",
      retractil: "chico"
    }
  };

  const { texto } = generarEspecificacion(modelo, config, grupos, opciones);

  assertEquals(
    texto,
    "SEMIREMOLQUE TIPO: PLATAFORMA 40 FT 2 EJES, CON SUSPENSIÓN FLEET MASTER, EJES FLEET MASTER, 2 PAR DE PATÍN HJ, SISTEMA RETRÁCTIL CHICO"
  );
});

Deno.test("Generar texto con 3 ejes, sin gancho, sin redilas y arreglos en adicionales", () => {
  const { modelo, grupos, opciones } = fixtures.default as any;
  const mod3 = { ...modelo, num_ejes: 3 };

  const config = {
    grupos: {
      suspension: "fleet_master",
      eje: "fleet_master",
      gancho: "sin_gancho",
      redilas: "sin_redilas",
      rines: { opcion: "aluminio", marca: "ampro" },
      llantas: "firestone",
      adicionales: [{ opcion: "bicicletera", cantidad: 1 }]
    }
  };

  const { texto } = generarEspecificacion(mod3, config, grupos, opciones);
  
  assertEquals(texto.includes("PLATAFORMA 40 FT 3 EJES"), true);
  assertEquals(texto.includes("12 RINES DE ALUMINIO MARCA AMPRO"), true);
  assertEquals(texto.includes("12 LLANTAS FIRESTONE"), true);
  assertEquals(texto.includes("ADICIONALES BICICLETERA"), true);
  assertEquals(texto.includes("GANCHO"), false);
  assertEquals(texto.includes("REDILAS"), false);
});

Deno.test("Generar texto de encabezado para Dolly y Góndola", () => {
  const { grupos, opciones } = fixtures.default as any;

  // Dolly 2 ejes
  const modDolly = { id: "mod-dolly", tipo: "dolly", largo_ft: null, num_ejes: 2, nombre: "DOLLY 2 EJES" };
  const resDolly = generarEspecificacion(modDolly as any, { grupos: {} }, grupos, opciones);
  assertEquals(resDolly.texto.startsWith("SEMIREMOLQUE TIPO: DOLLY 2 EJES"), true);
  assertEquals(resDolly.resumen_lineas[0].valor, "DOLLY 2 EJES");

  // Góndola 3 ejes
  const modGondola = { id: "mod-gondola", tipo: "gondola", largo_ft: 30, num_ejes: 3, nombre: "GONDOLA 3 EJES" };
  const resGondola = generarEspecificacion(modGondola as any, { grupos: {} }, grupos, opciones);
  assertEquals(resGondola.texto.startsWith("SEMIREMOLQUE TIPO: GONDOLA 3 EJES"), true);
  assertEquals(resGondola.resumen_lineas[0].valor, "GONDOLA 3 EJES");

  // Tipo desconocido en mayúsculas
  const modOtro = { id: "mod-otro", tipo: "traila", largo_ft: null, num_ejes: 2, nombre: "TRAILA" };
  const resOtro = generarEspecificacion(modOtro as any, { grupos: {} }, grupos, opciones);
  assertEquals(resOtro.texto.startsWith("SEMIREMOLQUE TIPO: TRAILA"), true);
  assertEquals(resOtro.resumen_lineas[0].valor, "TRAILA");
});

Deno.test("2R-8: Generar texto con 1, 2 y 3 filas (rines, llantas y matracas)", () => {
  const { modelo, grupos, opciones } = fixtures.default as any;
  const mod3 = { ...modelo, num_ejes: 3 };

  // 1. Una sola fila (sigue igual que hoy)
  const config1 = {
    grupos: {
      rines: { opcion: "acero", marca: "Ampro", cantidad: 12 },
      llantas: { opcion: "firestone", cantidad: 12 },
      matracas: { opcion: "corrediza", cantidad: 10 }
    }
  };
  const res1 = generarEspecificacion(mod3, config1, grupos, opciones);
  assertEquals(res1.texto.includes("12 RINES DE ACERO MARCA AMPRO"), true);
  assertEquals(res1.texto.includes("12 LLANTAS FIRESTONE"), true);
  assertEquals(res1.texto.includes("10 MATRACAS CORREDIZAS"), true);
  assertEquals(res1.resumen_lineas.find(r => r.etiqueta === "Matracas / winches")?.valor, "10 CORREDIZAS");

  // 2. Dos filas (ej. 8 acero + 4 aluminio, 6 firestone + 6 cerex)
  const config2 = {
    grupos: {
      rines: [
        { opcion: "acero", marca: "Ampro", cantidad: 8 },
        { opcion: "aluminio", marca: "Ampro", cantidad: 4 }
      ],
      llantas: [
        { opcion: "firestone", cantidad: 6 },
        { opcion: "cerex", cantidad: 6 }
      ],
      matracas: { opcion: "corrediza", cantidad: 10 }
    }
  };
  const res2 = generarEspecificacion(mod3, config2, grupos, opciones);
  assertEquals(
    res2.texto.includes("8 RINES DE ACERO MARCA AMPRO Y 4 RINES DE ALUMINIO MARCA AMPRO"),
    true
  );
  assertEquals(
    res2.texto.includes("6 LLANTAS FIRESTONE Y 6 LLANTAS CEREX"),
    true
  );
  assertEquals(res2.texto.includes("10 MATRACAS CORREDIZAS"), true);

  // 3. Tres filas de rines (unidas con coma y final Y)
  const config3 = {
    grupos: {
      rines: [
        { opcion: "acero", marca: "Ampro", cantidad: 6 },
        { opcion: "aluminio", marca: "Ampro", cantidad: 4 },
        { opcion: "cliente", cantidad: 2 }
      ]
    }
  };
  const res3 = generarEspecificacion(mod3, config3, grupos, opciones);
  assertEquals(
    res3.texto.includes("6 RINES DE ACERO MARCA AMPRO, 4 RINES DE ALUMINIO MARCA AMPRO Y 2 RINES PROPORCIONADOS POR EL CLIENTE"),
    true
  );
});

Deno.test("2R-10: Texto de especificación con 1, 2 retráctiles y sin_retractil", () => {
  const { modelo, grupos, opciones } = fixtures.default as any;

  // 1. Una sola fila de 1 retráctil (como hoy) -> SISTEMA RETRÁCTIL CHICO
  const config1 = {
    grupos: {
      retractil: { opcion: "chico", cantidad: 1 }
    }
  };
  const res1 = generarEspecificacion(modelo, config1, grupos, opciones);
  assertEquals(res1.texto.includes("SISTEMA RETRÁCTIL CHICO"), true);
  assertEquals(res1.resumen_lineas.find(r => r.etiqueta === "Retráctil")?.valor, "RETRÁCTIL CHICO");

  // 2. Dos filas distintas de retráctiles (chico × 1, grande × 1) -> 2 SISTEMAS RETRÁCTILES
  const config2 = {
    grupos: {
      retractil: [
        { opcion: "chico", cantidad: 1 },
        { opcion: "grande", cantidad: 1 }
      ]
    }
  };
  const res2 = generarEspecificacion(modelo, config2, grupos, opciones);
  assertEquals(res2.texto.includes("2 SISTEMAS RETRÁCTILES"), true);
  assertEquals(res2.resumen_lineas.find(r => r.etiqueta === "Retráctil")?.valor, "2 SISTEMAS RETRÁCTILES");

  // 3. sin_retractil -> no aparece en texto ni en resumen_lineas
  const configSin = {
    grupos: {
      retractil: "sin_retractil"
    }
  };
  const resSin = generarEspecificacion(modelo, configSin, grupos, opciones);
  assertEquals(resSin.texto.includes("RETRÁCTIL"), false);
  assertEquals(resSin.resumen_lineas.find(r => r.etiqueta === "Retráctil"), undefined);
});

