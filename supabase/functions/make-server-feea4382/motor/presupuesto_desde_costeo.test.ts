import { assertEquals, assert } from "https://deno.land/std@0.192.0/testing/asserts.ts";
import { costear } from "./costeo.ts";
import { resolverReceta } from "./resolver_receta.ts";
import {
  generarPresupuestoDesdeCosteo,
  clasificarKitFijo,
  clasificarOpcion,
  MAPEO_GRUPOS_OPCIONES
} from "./presupuesto_desde_costeo.ts";
import * as fixtureCosteo from "./fixtures/datos_costeo_plataforma_40x2.json" with { type: "json" };
import * as fixtureModelo from "./fixtures/datos_modelo.json" with { type: "json" };
import type { DatosCosteo, DatosModelo, Configuracion, AjusteManual } from "./tipos.ts";

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

const ajustesExcel: AjusteManual[] = [
  {
    concepto: "Líneas sin concepto en el Excel (pendiente de aclarar con el dueño)",
    cantidad: 2,
    costo_unitario: 15000
  },
  {
    concepto: "Líneas sin concepto en el Excel (pendiente de aclarar con el dueño)",
    cantidad: 1,
    costo_unitario: 1485
  }
];

Deno.test("Prueba dorada: Plataforma 40 ft 2 ejes - presupuesto exacto desde costeo", () => {
  const costeoRes = costear(datosCosteoBase, configExcel, ajustesExcel);
  const bomRes = resolverReceta(datosModeloBase, configExcel);

  const res = generarPresupuestoDesdeCosteo([
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
    cotizacion_id: "cot-12345"
  });

  const { datos, total_costo, meta } = res;

  // Imprimir resumen por sección para verificación
  console.log("\n--- RESULTADOS PRUEBA DORADA PRESUPUESTO 2R-4A ---");
  console.log(`acero:       ${datos.acero.total.toFixed(2)} (líneas: ${datos.acero.items.length})`);
  console.log(`tornilleria: ${datos.tornilleria?.total.toFixed(2)} (líneas: ${datos.tornilleria?.items.length})`);
  console.log(`luz:         ${datos.luz?.total.toFixed(2)} (líneas: ${datos.luz?.items.length})`);
  console.log(`pintura:     ${datos.pintura?.total.toFixed(2)} (líneas: ${datos.pintura?.items.length})`);
  console.log(`aire:        ${datos.aire?.total.toFixed(2)} (líneas: ${datos.aire?.items.length})`);
  console.log(`truckzone:   ${datos.truckzone.total.toFixed(2)} (líneas: ${datos.truckzone.items.length})`);
  console.log(`piso:        ${datos.piso.total.toFixed(2)} (líneas: ${datos.piso.items.length})`);
  console.log(`otros:       ${datos.otros.total.toFixed(2)} (líneas: ${datos.otros.items.length})`);
  console.log(`manoobra:    ${datos.manoobra.total.toFixed(2)} (líneas: ${datos.manoobra.items.length})`);
  console.log(`adicionales: ${datos.adicionales.total.toFixed(2)} (líneas: ${datos.adicionales.items.length})`);
  console.log(`rines:       ${datos.rines.total.toFixed(2)}`);
  console.log(`extras:      ${datos.extras.total.toFixed(2)}`);
  console.log(`piramide:    ${datos.piramide.total.toFixed(2)}`);
  console.log(`indirectos:  ${datos.indirectos.total.toFixed(2)}`);
  console.log(`TOTAL COSTO: ${total_costo.toFixed(2)}`);
  console.log("--------------------------------------------------");
  console.log("Primeras líneas de truckzone:");
  console.table(datos.truckzone.items.slice(0, 10));
  console.log("Primeras líneas de aire:");
  console.table((datos.aire?.items || []).slice(0, 10));
  console.log("--------------------------------------------------\n");

  // Verificaciones exactas
  assertEquals(datos.acero.total, 128211.69);
  assertEquals(datos.acero.items.length, 61);
  assertEquals(datos.tornilleria?.total, 40.00);
  assertEquals(datos.luz?.total, 15000.00);
  assertEquals(datos.pintura?.total, 22000.00);
  assertEquals(datos.aire?.total, 20000.00);
  assertEquals(datos.truckzone.total, 97340.96);
  assertEquals(datos.piso.total, 52060.00);
  assertEquals(datos.otros.total, 8645.98);
  assertEquals(datos.manoobra.total, 22930.00);
  assertEquals(datos.adicionales.total, 31485.00);
  assertEquals(datos.rines.total, 0);
  assertEquals(datos.extras.total, 0);
  assertEquals(datos.piramide.total, 0);
  assertEquals(datos.indirectos.total, 0);

  // total_costo exactamente igual a costeo.costo
  assertEquals(total_costo, 397713.63);
  assertEquals(total_costo, costeoRes.costo);

  // Metadatos
  assertEquals(meta.origen, "costeo");
  assertEquals(meta.cotizacion_id, "cot-12345");
  assertEquals(meta.conceptos_incluidos.length, 1);
  assertEquals(meta.conceptos_incluidos[0].costo, 397713.63);
  assertEquals(meta.conceptos_incluidos[0].precio_sugerido, 507713.63);
  assertEquals(meta.conceptos_omitidos.length, 0);
  assertEquals(meta.confianza, "estimada"); // por PUENTES DE SUSPENSIÓN sin precio
  assertEquals(meta.pendientes.length, 1);
  assert(meta.pendientes[0].toLowerCase().includes("puentes de suspensión"));
  assertEquals(meta.sin_precio, 1); // solo PUENTES DE SUSPENSIÓN
  assertEquals(meta.sin_clasificar.length, 0);
  assertEquals(meta.bom.length, 1);
  assert(meta.bom[0].lineas.length > 0);
});

Deno.test("Regla de cantidad: cantidad 2 duplica pzas e importes con el mismo cu", () => {
  const costeoRes = costear(datosCosteoBase, configExcel, ajustesExcel);
  const bomRes = resolverReceta(datosModeloBase, configExcel);

  const res1 = generarPresupuestoDesdeCosteo([
    {
      item: { descripcion: "Plataforma", cantidad: 1, modelo_id: "mod-1" },
      costeo: costeoRes,
      bom: bomRes
    }
  ]);

  const res2 = generarPresupuestoDesdeCosteo([
    {
      item: { descripcion: "Plataforma", cantidad: 2, modelo_id: "mod-1" },
      costeo: costeoRes,
      bom: bomRes
    }
  ]);

  assertEquals(res2.total_costo, Math.round(res1.total_costo * 2 * 100) / 100);
  assertEquals(res2.datos.acero.total, Math.round(res1.datos.acero.total * 2 * 100) / 100);
  assertEquals(res2.datos.luz?.total, Math.round((res1.datos.luz?.total || 0) * 2 * 100) / 100);

  // Mismo cu en líneas
  for (let i = 0; i < res1.datos.acero.items.length; i++) {
    const it1 = res1.datos.acero.items[i];
    const it2 = res2.datos.acero.items[i];
    assertEquals(it2.cu, it1.cu);
    assertEquals(Number(it2.pzas), Number(it1.pzas) * 2);
    assertEquals(it2.importe, Math.round(it1.importe * 2 * 100) / 100);
  }
});

Deno.test("Fusión de equipos idénticos: dos equipos iguales se fusionan en una sola línea por concepto y cu", () => {
  const costeoRes = costear(datosCosteoBase, configExcel, ajustesExcel);
  const bomRes = resolverReceta(datosModeloBase, configExcel);

  const resIndividual = generarPresupuestoDesdeCosteo([
    {
      item: { descripcion: "Plataforma A", cantidad: 1, modelo_id: "mod-1" },
      costeo: costeoRes,
      bom: bomRes
    }
  ]);

  const resDosEquipos = generarPresupuestoDesdeCosteo([
    {
      item: { descripcion: "Plataforma A", cantidad: 1, modelo_id: "mod-1" },
      costeo: costeoRes,
      bom: bomRes
    },
    {
      item: { descripcion: "Plataforma B", cantidad: 1, modelo_id: "mod-1" },
      costeo: costeoRes,
      bom: bomRes
    }
  ]);

  // Debe tener el mismo número de líneas que el individual, pero con pzas duplicadas
  assertEquals(resDosEquipos.datos.acero.items.length, resIndividual.datos.acero.items.length);
  assertEquals(resDosEquipos.datos.truckzone.items.length, resIndividual.datos.truckzone.items.length);
  assertEquals(resDosEquipos.total_costo, Math.round(resIndividual.total_costo * 2 * 100) / 100);
  assertEquals(resDosEquipos.meta.conceptos_incluidos.length, 2);
});

Deno.test("Filtrado de conceptos omitidos: costeo incompleta y errores del motor van a omitidos con motivo", () => {
  const costeoIncompleto = JSON.parse(JSON.stringify(costear(datosCosteoBase, configExcel)));
  costeoIncompleto.confianza = "incompleta";

  const bomConErrores = JSON.parse(JSON.stringify(resolverReceta(datosModeloBase, configExcel)));
  bomConErrores.errores = ["Conflicto incompatible de suspensión con chasis"];

  const res = generarPresupuestoDesdeCosteo([
    {
      item: { descripcion: "Equipo Incompleto", cantidad: 1, modelo_id: "mod-1" },
      costeo: costeoIncompleto,
      bom: resolverReceta(datosModeloBase, configExcel)
    },
    {
      item: { descripcion: "Equipo con Errores", cantidad: 1, modelo_id: "mod-2" },
      costeo: costear(datosCosteoBase, configExcel),
      bom: bomConErrores
    },
    {
      item: { descripcion: "Equipo Sin Modelo", cantidad: 1, modelo_id: null },
      costeo: costear(datosCosteoBase, configExcel),
      bom: null
    }
  ], {
    conceptos_omitidos: [
      { descripcion: "Mantenimiento preventivo", motivo: "no es equipo configurable" }
    ]
  });

  assertEquals(res.meta.conceptos_incluidos.length, 0);
  assertEquals(res.total_costo, 0);
  assertEquals(res.meta.confianza, "incompleta");

  const motivos = res.meta.conceptos_omitidos.map(o => o.motivo);
  assert(motivos.some(m => m.includes("no tiene costos cargados")));
  assert(motivos.some(m => m.includes("la configuración tiene errores")));
  assert(motivos.some(m => m.includes("sin configurar")));
  assert(motivos.some(m => m.includes("no es equipo configurable")));
});

Deno.test("Opción sin costo sale sin_precio: true y meta.pendientes la nombra", () => {
  const configConOpcionRara: Configuracion = {
    grupos: {
      ...configExcel.grupos,
      suspension: "suspension_sin_costo_en_bd"
    }
  };

  const costeoRes = costear(datosCosteoBase, configConOpcionRara);
  const bomRes = resolverReceta(datosModeloBase, configExcel);

  const res = generarPresupuestoDesdeCosteo([
    {
      item: { descripcion: "Plataforma Rara", cantidad: 1, modelo_id: "mod-1" },
      costeo: costeoRes,
      bom: bomRes
    }
  ]);

  const lineaSinPrecio = res.datos.truckzone.items.find(i => i.material.includes("suspension_sin_costo_en_bd"));
  assert(lineaSinPrecio !== undefined);
  assertEquals(lineaSinPrecio.cu, 0);
  assertEquals(lineaSinPrecio.importe, 0);
  assertEquals(lineaSinPrecio.sin_precio, true);

  // meta.pendientes la contiene
  assert(res.meta.pendientes.some(p => p.includes("suspension_sin_costo_en_bd")));
});

Deno.test("meta.bom trae las líneas del motor por unidad y no altera total_costo", () => {
  const costeoRes = costear(datosCosteoBase, configExcel, ajustesExcel);
  const bomRes = resolverReceta(datosModeloBase, configExcel);

  const resSinBom = generarPresupuestoDesdeCosteo([
    {
      item: { descripcion: "Plataforma", cantidad: 2, modelo_id: "mod-1" },
      costeo: costeoRes,
      bom: null
    }
  ]);

  const resConBom = generarPresupuestoDesdeCosteo([
    {
      item: { descripcion: "Plataforma", cantidad: 2, modelo_id: "mod-1" },
      costeo: costeoRes,
      bom: bomRes
    }
  ]);

  // El total_costo no cambia con o sin BOM
  assertEquals(resConBom.total_costo, resSinBom.total_costo);
  assertEquals(resConBom.meta.bom.length, 1);
  assertEquals(resConBom.meta.bom[0].cantidad, 2);
  assert(resConBom.meta.bom[0].lineas.length > 0);
});

Deno.test("Grupo desconocido cae en otros y en meta.sin_clasificar", () => {
  const costeoConGrupoExtra = JSON.parse(JSON.stringify(costear(datosCosteoBase, configExcel)));
  costeoConGrupoExtra.secciones.opciones.lineas.push({
    concepto: "grupo_extraterrestre: opcion_x",
    cantidad: 1,
    costo_unitario: 500,
    importe: 500,
    origen: "opcion:grupo_extraterrestre/opcion_x"
  });

  const res = generarPresupuestoDesdeCosteo([
    {
      item: { descripcion: "Plataforma", cantidad: 1, modelo_id: "mod-1" },
      costeo: costeoConGrupoExtra,
      bom: null
    }
  ]);

  assert(res.meta.sin_clasificar.includes("grupo_extraterrestre"));
  const itemEnOtros = res.datos.otros.items.find(i => i.material.includes("grupo_extraterrestre"));
  assert(itemEnOtros !== undefined);
  assertEquals(itemEnOtros.importe, 500);
});

Deno.test("Verificación de cada fila de la tabla de mapeo", () => {
  // 1. Kits
  assertEquals(clasificarKitFijo("tornilleria"), "tornilleria");
  assertEquals(clasificarKitFijo("luz"), "luz");
  assertEquals(clasificarKitFijo("pintura"), "pintura");
  assertEquals(clasificarKitFijo("consumibles"), "otros");
  assertEquals(clasificarKitFijo("otros"), "otros");
  assertEquals(clasificarKitFijo(undefined), "otros");

  // 2. Opciones de cada grupo
  const sinClas = new Set<string>();
  assertEquals(clasificarOpcion("opcion:suspension/fleet_master", sinClas), "truckzone");
  assertEquals(clasificarOpcion("opcion:eje/fleet_master", sinClas), "truckzone");
  assertEquals(clasificarOpcion("opcion:patin/hj", sinClas), "truckzone");
  assertEquals(clasificarOpcion("opcion:gancho/holland", sinClas), "truckzone");
  assertEquals(clasificarOpcion("opcion:retractil/estandar", sinClas), "truckzone");
  assertEquals(clasificarOpcion("opcion:riel/logistico", sinClas), "truckzone");
  assertEquals(clasificarOpcion("opcion:matracas/corrediza", sinClas), "truckzone");
  assertEquals(clasificarOpcion("opcion:quinta/placa", sinClas), "truckzone");
  assertEquals(clasificarOpcion("opcion:dona/estandar", sinClas), "truckzone");

  assertEquals(clasificarOpcion("opcion:abs/2e_sin_retractil", sinClas), "aire");
  assertEquals(clasificarOpcion("opcion:rines/acero", sinClas), "rines");
  assertEquals(clasificarOpcion("opcion:llantas/chinas", sinClas), "rines");
  assertEquals(clasificarOpcion("opcion:piso/laminado_plastico", sinClas), "piso");
  assertEquals(clasificarOpcion("opcion:pintura/poliuretano", sinClas), "pintura");
  assertEquals(clasificarOpcion("opcion:color/rojo", sinClas), "pintura");
  assertEquals(clasificarOpcion("opcion:frente/sin_frente", sinClas), "extras");
  assertEquals(clasificarOpcion("opcion:redilas/sin_redilas", sinClas), "extras");
  assertEquals(clasificarOpcion("opcion:adicionales/bicicletera", sinClas), "adicionales");
  assertEquals(clasificarOpcion("opcion:plafones/ambar", sinClas), "adicionales");

  assertEquals(clasificarOpcion("opcion:grupo_desconocido/algo", sinClas), "otros");
  assert(sinClas.has("grupo_desconocido"));
});
