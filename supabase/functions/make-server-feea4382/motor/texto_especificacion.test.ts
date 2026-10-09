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
