import { assertEquals, assert } from "https://deno.land/std@0.192.0/testing/asserts.ts";
import { resolverReceta } from "./resolver_receta.ts";
import { generarPresupuestoDesdeCosteo } from "./presupuesto_desde_costeo.ts";
import { costear } from "./costeo.ts";
import * as fixtureCosteo from "./fixtures/datos_costeo_plataforma_40x2.json" with { type: "json" };
import * as fixtureModelo from "./fixtures/datos_modelo.json" with { type: "json" };
import type { DatosCosteo, DatosModelo, Configuracion } from "./tipos.ts";
import {
  contarPiezasDistintas,
  consolidarDespiece,
  generarCsvDespiece,
  agruparLineasEquipo,
  filtrarLineas,
  formatearCantidad,
  formatearOrigen
} from "../../../../src/app/utils/despiece.ts";

const datosCosteoBase = fixtureCosteo.default as DatosCosteo;
const datosModeloBase = fixtureModelo.default as DatosModelo;

const configExcel: Configuracion = {
  grupos: {
    suspension: "fleet_master",
    eje: "fleet_master",
    patin: "hj",
    piso: "laminado_plastico",
    abs: "2e_sin_retractil"
  }
};

Deno.test("despiece.ts: formato de cantidades y orígenes", () => {
  assertEquals(formatearCantidad(1.5), "1.5");
  assertEquals(formatearCantidad(2), "2");
  assertEquals(formatearCantidad(3.14159), "3.142");
  assertEquals(formatearCantidad(0), "0");

  assertEquals(formatearOrigen(["base"]), "Base");
  assertEquals(formatearOrigen(["opcion:suspension/fleet_master"]), "Opción: suspension");
  assertEquals(formatearOrigen([]), "Base");
  assertEquals(formatearOrigen(undefined), "Base");
});

Deno.test("despiece.ts: ejecución con fixture de Plataforma 40/2", () => {
  const costeoRes = costear(datosCosteoBase, configExcel, []);
  const bomRes = resolverReceta(datosModeloBase, configExcel);

  const resPresupuesto = generarPresupuestoDesdeCosteo([
    {
      item: {
        descripcion: "Plataforma 40 ft / 2 ejes",
        cantidad: 1,
        modelo_id: "mod-plat-40-2"
      },
      costeo: costeoRes,
      bom: bomRes
    }
  ], {
    cotizacion_id: "cot-test-despiece",
    cotizacion_folio: "COT-2026-0001"
  });

  const bom = resPresupuesto.meta.bom;
  assert(bom && bom.length > 0, "Debe tener BOM");

  // 1. Contar piezas distintas
  const numDistintas = contarPiezasDistintas(bom);
  console.log("\n=======================================================");
  console.log(`[DESPIECE] Número de piezas distintas: ${numDistintas}`);
  assert(numDistintas > 0, "Debe haber piezas distintas");

  // 2. Consolidar piezas
  const consolidado = consolidarDespiece(bom);
  assertEquals(consolidado.length, numDistintas);

  console.log("\n[DESPIECE] Muestra de 5 piezas consolidadas:");
  const muestra5 = consolidado.slice(0, 5);
  for (const p of muestra5) {
    console.log(` - ${p.nombre} | ${p.unidad} | Total: ${p.cantidad_total}`);
  }

  // 3. Agrupación por sección y paso
  const lineas = bom[0].lineas;
  const porSeccion = agruparLineasEquipo(lineas, "seccion");
  const porPaso = agruparLineasEquipo(lineas, "paso");
  assert(Object.keys(porSeccion).length > 0, "Debe haber grupos por sección");
  assert(Object.keys(porPaso).length > 0, "Debe haber grupos por paso");
  console.log(`\n[DESPIECE] Secciones encontradas (${Object.keys(porSeccion).length}):`, Object.keys(porSeccion).join(", "));
  console.log(`[DESPIECE] Pasos encontrados (${Object.keys(porPaso).length}):`, Object.keys(porPaso).join(", "));

  // 4. Filtrado
  const filtradas = filtrarLineas(lineas, "amortiguador");
  assert(filtradas.length > 0, "Debe encontrar piezas con 'amortiguador'");

  // 5. Generación de CSV con BOM UTF-8
  const csv = generarCsvDespiece(bom, { cotizacionFolio: "COT-2026-0001" });
  assert(csv.startsWith("\uFEFF"), "CSV debe empezar con UTF-8 BOM");

  const lineasCsv = csv.replace("\uFEFF", "").split("\r\n");
  console.log("\n[DESPIECE] Primeras 10 líneas del CSV:");
  for (let i = 0; i < Math.min(10, lineasCsv.length); i++) {
    console.log(`[${i + 1}] ${lineasCsv[i]}`);
  }
  console.log("=======================================================\n");

  assertEquals(lineasCsv[0], "Despiece - Cotización COT-2026-0001");
  assertEquals(lineasCsv[2], "CONSOLIDADO DE MATERIALES");
  assertEquals(lineasCsv[3], "Pieza,Unidad,Cantidad total");
});
