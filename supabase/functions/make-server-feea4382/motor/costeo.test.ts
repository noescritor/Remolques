import { assertEquals, assert } from "https://deno.land/std@0.192.0/testing/asserts.ts";
import { costear, validarAjustes } from "./costeo.ts";
import * as fixtureData from "./fixtures/datos_costeo_plataforma_40x2.json" with { type: "json" };
import * as fixtureDolly from "./fixtures/datos_costeo_dolly.json" with { type: "json" };
import * as fixtureGondola from "./fixtures/datos_costeo_gondola.json" with { type: "json" };
import type { DatosCosteo, Configuracion, AjusteManual } from "./tipos.ts";

const datosBase = fixtureData.default as DatosCosteo;
const datosDolly = fixtureDolly.default as DatosCosteo;
const datosGondolaA36 = fixtureGondola.default.gondola_a36 as unknown as DatosCosteo;
const datosGondolaHardox = fixtureGondola.default.gondola_hardox450 as unknown as DatosCosteo;

Deno.test("Prueba dorada: Plataforma 40 ft 2 ejes - costeo exacto contra Excel Leolca", () => {
  const config: Configuracion = {
    grupos: {
      suspension: "fleet_master",
      eje: "fleet_master",
      patin: "hj",
      piso: "laminado_plastico",
      abs: "2e_sin_retractil"
    }
  };

  const ajustes: AjusteManual[] = [
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

  const res = costear(datosBase, config, ajustes);

  // Valores exactos al centavo
  assertEquals(res.secciones.acero.total, 128211.69);
  assertEquals(res.secciones.kits_fijos.total, 45685.98);
  assertEquals(res.secciones.opciones.total, 169400.96);
  assertEquals(res.secciones.mano_obra.total, 22930.00);
  assertEquals(res.secciones.ajustes.total, 31485.00);
  assertEquals(res.costo, 397713.63);
  assertEquals(res.ganancia, 110000.00);
  assertEquals(res.precio_sugerido, 507713.63);

  // Margen sobre precio ≈ 0.2166 (110,000 / 507,713.63)
  assert(res.margen_sobre_precio !== null);
  const diffMargen = Math.abs(res.margen_sobre_precio - (110000 / 507713.63));
  assert(diffMargen < 0.0001);

  // Confianza y pendientes
  assertEquals(res.confianza, "estimada");
  assertEquals(res.pendientes.length, 1);
  assertEquals(res.pendientes[0].tipo, "sin_precio");
  assert(res.pendientes[0].detalle.toLowerCase().includes("puentes de suspensión"));
  assert(!res.pendientes.some(p => p.tipo === "variante_supuesta"));
});

Deno.test("Adicional 1: por_eje con 3 ejes escala proporcionalmente suspensión y ejes", () => {
  const datos3Ejes: DatosCosteo = JSON.parse(JSON.stringify(datosBase));
  datos3Ejes.modelo.num_ejes = 3;

  const config: Configuracion = {
    grupos: {
      suspension: "fleet_master",
      eje: "fleet_master"
    }
  };

  const res2 = costear(datosBase, config);
  const res3 = costear(datos3Ejes, config);

  const lineaSusp2 = res2.secciones.opciones.lineas.find(l => l.concepto.includes("suspension"));
  const lineaSusp3 = res3.secciones.opciones.lineas.find(l => l.concepto.includes("suspension"));
  assert(lineaSusp2 && lineaSusp3);
  assertEquals(lineaSusp2.cantidad, 2);
  assertEquals(lineaSusp3.cantidad, 3);
  assertEquals(lineaSusp3.importe, Math.round((lineaSusp2.importe * 1.5) * 100) / 100);

  const lineaEje2 = res2.secciones.opciones.lineas.find(l => l.concepto.includes("eje"));
  const lineaEje3 = res3.secciones.opciones.lineas.find(l => l.concepto.includes("eje"));
  assert(lineaEje2 && lineaEje3);
  assertEquals(lineaEje2.cantidad, 2);
  assertEquals(lineaEje3.cantidad, 3);
  assertEquals(lineaEje3.importe, Math.round((lineaEje2.importe * 1.5) * 100) / 100);
});

Deno.test("Adicional 2: opción elegida sin renglón en opcion_costos → pendiente opcion_sin_costo y confianza no completa", () => {
  const config: Configuracion = {
    grupos: {
      suspension: "marca_rara_no_catalogada"
    }
  };

  const res = costear(datosBase, config);
  const pendiente = res.pendientes.find(p => p.tipo === "opcion_sin_costo");
  assert(pendiente !== undefined);
  assert(pendiente.detalle.includes("marca_rara_no_catalogada"));
  assert(res.confianza !== "completa");
});

Deno.test("Adicional 3: modelo sin acero o procesos → confianza incompleta y precio_sugerido null", () => {
  const datosSinAcero: DatosCosteo = {
    ...datosBase,
    receta_acero: []
  };

  const resSinAcero = costear(datosSinAcero, { grupos: {} });
  assertEquals(resSinAcero.confianza, "incompleta");
  assertEquals(resSinAcero.precio_sugerido, null);
  assert(resSinAcero.pendientes.some(p => p.tipo === "modelo_sin_costos"));

  const datosSinProcesos: DatosCosteo = {
    ...datosBase,
    procesos: []
  };

  const resSinProcesos = costear(datosSinProcesos, { grupos: {} });
  assertEquals(resSinProcesos.confianza, "incompleta");
  assertEquals(resSinProcesos.precio_sugerido, null);
  assert(resSinProcesos.pendientes.some(p => p.tipo === "modelo_sin_costos"));
});

Deno.test("Adicional 4: ganancia nula → precio_sugerido null y pendiente ganancia_no_definida", () => {
  const datosSinGanancia: DatosCosteo = {
    ...datosBase,
    ganancia: null
  };

  const res = costear(datosSinGanancia, { grupos: {} });
  assertEquals(res.precio_sugerido, null);
  assertEquals(res.margen_sobre_precio, null);
  assert(res.pendientes.some(p => p.tipo === "ganancia_no_definida"));
});

Deno.test("Adicional 5: ajustes con descuento negativo resta del costo", () => {
  const config: Configuracion = {
    grupos: {
      suspension: "fleet_master"
    }
  };

  const resSinAjustes = costear(datosBase, config, []);
  const ajusteDescuento: AjusteManual[] = [
    { concepto: "Descuento por volumen", cantidad: 1, costo_unitario: -15000 }
  ];

  const resConDescuento = costear(datosBase, config, ajusteDescuento);
  assertEquals(resConDescuento.secciones.ajustes.total, -15000);
  assertEquals(resConDescuento.costo, Math.round((resSinAjustes.costo - 15000) * 100) / 100);
});

Deno.test("Adicional 6: validación de ajustes rechaza entradas no numéricas o inválidas", () => {
  // Ajustes no arreglo
  assertEquals(validarAjustes("no es un arreglo").valido, false);
  assertEquals(validarAjustes(12345).valido, false);

  // Ajuste con concepto inválido
  assertEquals(validarAjustes([{ concepto: 123, cantidad: 1, costo_unitario: 100 }]).valido, false);

  // Ajuste con cantidad <= 0 o no finita
  assertEquals(validarAjustes([{ concepto: "test", cantidad: 0, costo_unitario: 100 }]).valido, false);
  assertEquals(validarAjustes([{ concepto: "test", cantidad: -2, costo_unitario: 100 }]).valido, false);
  assertEquals(validarAjustes([{ concepto: "test", cantidad: NaN, costo_unitario: 100 }]).valido, false);
  assertEquals(validarAjustes([{ concepto: "test", cantidad: Infinity, costo_unitario: 100 }]).valido, false);

  // Ajuste con costo_unitario no numérico o no finito
  assertEquals(validarAjustes([{ concepto: "test", cantidad: 1, costo_unitario: "100" }]).valido, false);
  assertEquals(validarAjustes([{ concepto: "test", cantidad: 1, costo_unitario: NaN }]).valido, false);

  // Ajustes válidos (incluso con costo negativo para descuento)
  assertEquals(validarAjustes(undefined).valido, true);
  assertEquals(validarAjustes(null).valido, true);
  assertEquals(validarAjustes([]).valido, true);
  assertEquals(validarAjustes([{ concepto: "Descuento", cantidad: 1, costo_unitario: -500 }]).valido, true);
});

Deno.test("Adicional 7: cuando todos los materiales de acero tienen precio asignado → confianza completa", () => {
  const datosCompletos: DatosCosteo = JSON.parse(JSON.stringify(datosBase));
  // Asignar precio al puente de suspensión
  const puente = datosCompletos.receta_acero.find(r => r.nombre.includes("PUENTES DE SUSPENSIÓN"));
  assert(puente !== undefined);
  puente.costo = 700;
  puente.descripcion = 'PTR a 2 x 6"';

  const config: Configuracion = {
    grupos: {
      suspension: "fleet_master",
      eje: "fleet_master",
      patin: "hj",
      piso: "laminado_plastico",
      abs: "2e_sin_retractil"
    }
  };

  const res = costear(datosCompletos, config);
  assertEquals(res.pendientes.length, 0);
  assertEquals(res.confianza, "completa");
  assert(res.precio_sugerido !== null);
});

Deno.test("Adicional 8: las 12 líneas de kits fijos traen el campo seccion poblado", () => {
  const res = costear(datosBase, { grupos: {} });
  assertEquals(res.secciones.kits_fijos.lineas.length, 12);
  for (const l of res.secciones.kits_fijos.lineas) {
    assert(typeof l.seccion === "string" && l.seccion.length > 0);
  }
  // Verificar secciones esperadas en la fixture
  const secciones = res.secciones.kits_fijos.lineas.map(l => l.seccion);
  assert(secciones.includes("tornilleria"));
  assert(secciones.includes("luz"));
  assert(secciones.includes("pintura"));
  assert(secciones.includes("consumibles"));
  assert(secciones.includes("otros"));
});

Deno.test("Adicional 9: modelo con costos_derivados_de sale estimada con variante_supuesta y con precio_sugerido", () => {
  const datosDerivados: DatosCosteo = JSON.parse(JSON.stringify(datosBase));
  datosDerivados.costos_derivados_de = {
    id: "00000000-0000-0000-0000-000000000040",
    nombre: "PLATAFORMA 2 40 FT"
  };

  const config: Configuracion = {
    grupos: {
      suspension: "fleet_master",
      eje: "fleet_master",
      patin: "hj",
      piso: "laminado_plastico",
      abs: "2e_sin_retractil"
    }
  };

  const res = costear(datosDerivados, config);
  assertEquals(res.confianza, "estimada");
  assert(res.precio_sugerido !== null);

  const pendiente = res.pendientes.find(p => p.tipo === "variante_supuesta");
  assert(pendiente !== undefined);
  assert(pendiente.detalle.includes("PLATAFORMA 2 40 FT"));
  assert(pendiente.detalle.includes("no hay desglose propio de esta variante"));
});

Deno.test("Adicional 10: con escala por_largo el piso de 45 ft cuesta 45/40 del de 40 ft", () => {
  const datos40: DatosCosteo = JSON.parse(JSON.stringify(datosBase));
  const optPiso40 = datos40.opcion_costos.find(oc => oc.grupo_clave === "piso" && oc.opcion_clave === "laminado_plastico");
  assert(optPiso40);
  optPiso40.escala = "por_largo";

  const datos45: DatosCosteo = JSON.parse(JSON.stringify(datos40));
  datos45.modelo.largo_ft = 45;

  const config: Configuracion = {
    grupos: {
      piso: "laminado_plastico"
    }
  };

  const res40 = costear(datos40, config);
  const res45 = costear(datos45, config);

  const linea40 = res40.secciones.opciones.lineas.find(l => l.concepto.includes("piso"));
  const linea45 = res45.secciones.opciones.lineas.find(l => l.concepto.includes("piso"));

  assert(linea40 && linea45);
  assertEquals(linea40.cantidad, 1);
  assertEquals(linea40.importe, 52060.00);

  assertEquals(linea45.cantidad, 45 / 40.0);
  assertEquals(linea45.importe, 52060.00 * (45 / 40.0)); // 58,567.50
});

Deno.test("Prueba dorada: Dolly 2 ejes - costeo exacto contra Excel Leolca", () => {
  const config: Configuracion = {
    grupos: {
      quinta: "holland",
      abs: "2e_sin_retractil"
    }
  };

  const ajustes: AjusteManual[] = [
    {
      concepto: "Dona 6 barrenos (sin mapear)",
      cantidad: 1,
      costo_unitario: 5176
    }
  ];

  const res = costear(datosDolly, config, ajustes);

  // Verificaciones exactas
  assertEquals(res.secciones.acero.total, 27018.80);
  assertEquals(res.secciones.kits_fijos.total, 20089.14);
  assertEquals(res.secciones.opciones.total, 47375.00);
  assertEquals(res.secciones.ajustes.total, 5176.00);
  assertEquals(res.secciones.mano_obra.total, 11249.90);
  assertEquals(res.costo, 110908.84);
  assertEquals(res.ganancia, 65000.00);
  assertEquals(res.precio_sugerido, 175908.84);

  // Margen sobre precio ≈ 0.3695 (65,000 / 175,908.84)
  assert(res.margen_sobre_precio !== null);
  const diffMargen = Math.abs(res.margen_sobre_precio - (65000 / 175908.84));
  assert(diffMargen < 0.0001);

  // Confianza: completa si no hay pendientes
  assertEquals(res.confianza, "completa");
  assertEquals(res.pendientes.length, 0);
});

Deno.test("Prueba dorada: Góndola A-36, 2 ejes - costeo exacto contra Excel Leolca", () => {
  const config: Configuracion = {
    grupos: {
      eje: "fleet_master",
      patin: "hj",
      gancho: "holland_8_10",
      abs: "2e_1_retractil",
      retractil: "paleta",
      rines: "acero",
      llantas: "chinas",
      tina_material: "a36"
    }
  };

  const ajustes: AjusteManual[] = [
    {
      concepto: "Suspensión HJ (sin mapear)",
      cantidad: 2,
      costo_unitario: 25000
    },
    {
      concepto: "Pintura color metálico (sin mapear)",
      cantidad: 1,
      costo_unitario: 15000
    }
  ];

  const res = costear(datosGondolaA36, config, ajustes);

  // Verificaciones exactas al centavo
  assertEquals(res.secciones.acero.total, 103936.96);
  assertEquals(res.secciones.kits_fijos.total, 89045.98);
  assertEquals(res.secciones.opciones.total, 303554.72);
  assertEquals(res.secciones.mano_obra.total, 0.00);
  assertEquals(res.secciones.ajustes.total, 65000.00);
  assertEquals(res.costo, 561537.66);
  assertEquals(res.ganancia, 100000.00);
  assertEquals(res.precio_sugerido, 661537.66);

  // Margen sobre precio (100,000 / 661,537.66)
  assert(res.margen_sobre_precio !== null);
  const diffMargen = Math.abs(res.margen_sobre_precio - (100000 / 661537.66));
  assert(diffMargen < 0.0001);

  // Verificación de IVA 16% sobre chasis + tina (43,430.84)
  // Total con IVA = 661,537.66 + 43,430.84 = 704,968.50
  const chasis = res.secciones.acero.total;
  const tina = res.secciones.opciones.lineas.find(l => l.concepto.includes("tina_material: a36"))?.importe || 0;
  assertEquals(tina, 167505.76);
  const ivaChasisTina = Math.round((chasis + tina) * 0.16 * 100) / 100;
  assertEquals(ivaChasisTina, 43430.84);
  assertEquals(Math.round((res.precio_sugerido! + ivaChasisTina) * 100) / 100, 704968.50);

  // Confianza estimada debido a iva_gondola
  assertEquals(res.confianza, "estimada");
  assertEquals(res.pendientes.length, 1);
  assertEquals(res.pendientes[0].tipo, "iva_gondola");
  assert(res.pendientes[0].detalle.includes("El IVA de la góndola está por confirmar"));
});

Deno.test("Prueba dorada: Góndola Hardox 450, 3 ejes - costeo exacto contra Excel Leolca", () => {
  const config: Configuracion = {
    grupos: {
      suspension: "hendrickson",
      eje: "ampro",
      patin: "holland",
      abs: "3e_2_retractil",
      retractil: { opcion: "paleta", cantidad: 2 },
      rines: "acero",
      tina_material: "hardox_450"
    }
  };

  const ajustes: AjusteManual[] = [
    {
      concepto: "Pintura color metálico (sin mapear)",
      cantidad: 1,
      costo_unitario: 15000
    }
  ];

  const res = costear(datosGondolaHardox, config, ajustes);

  // Verificaciones exactas al centavo
  assertEquals(res.secciones.acero.total, 103936.96);
  assertEquals(res.secciones.kits_fijos.total, 88996.98);
  assertEquals(res.secciones.opciones.total, 574416.42);
  assertEquals(res.secciones.mano_obra.total, 0.00);
  assertEquals(res.secciones.ajustes.total, 15000.00);
  assertEquals(res.costo, 782350.36);
  assertEquals(res.ganancia, 100000.00);
  assertEquals(res.precio_sugerido, 882350.36);

  // Margen sobre precio (100,000 / 882,350.36)
  assert(res.margen_sobre_precio !== null);
  const diffMargen = Math.abs(res.margen_sobre_precio - (100000 / 882350.36));
  assert(diffMargen < 0.0001);

  // Verificación de IVA 16% sobre chasis + tina (62,509.66)
  // Total con IVA = 882,350.36 + 62,509.66 = 944,860.02
  const chasis = res.secciones.acero.total;
  const tina = res.secciones.opciones.lineas.find(l => l.concepto.includes("tina_material: hardox_450"))?.importe || 0;
  assertEquals(tina, 286748.42);
  const ivaChasisTina = Math.round((chasis + tina) * 0.16 * 100) / 100;
  assertEquals(ivaChasisTina, 62509.66);
  assertEquals(Math.round((res.precio_sugerido! + ivaChasisTina) * 100) / 100, 944860.02);

  // Confianza estimada debido a iva_gondola
  assertEquals(res.confianza, "estimada");
  assertEquals(res.pendientes.length, 1);
  assertEquals(res.pendientes[0].tipo, "iva_gondola");
  assert(res.pendientes[0].detalle.includes("El IVA de la góndola está por confirmar"));
});

// ==========================================
// Pruebas Sub-bloque 2R-1g: Costos de respaldo
// ==========================================

const opcionCostosRespaldo = [
  { grupo_clave: "llantas", opcion_clave: "cerex", cantidad_base: 4, escala: "por_eje", costo_unitario: 3586, fuente: "Tarifario" },
  { grupo_clave: "color", opcion_clave: "rojo_claro", cantidad_base: 1, escala: "fija", costo_unitario: 0, fuente: "Supuesto: sin costo adicional" },
  { grupo_clave: "pintura", opcion_clave: "sherwin_williams", cantidad_base: 1, escala: "fija", costo_unitario: 0, fuente: "Supuesto: sin costo adicional" },
  { grupo_clave: "plafones", opcion_clave: "ambar_laterales", cantidad_base: 1, escala: "fija", costo_unitario: 168.20, fuente: "Tarifario" },
  { grupo_clave: "redilas", opcion_clave: "70", cantidad_base: 1, escala: "fija", costo_unitario: 35000, fuente: "Tarifario" },
  { grupo_clave: "matracas", opcion_clave: "corrediza", cantidad_base: 12, escala: "fija", costo_unitario: 307.40, fuente: "Factura Leolca" }
];

const datosPlataformaConRespaldo: DatosCosteo = {
  ...datosBase,
  opcion_costos: [
    ...datosBase.opcion_costos,
    ...opcionCostosRespaldo
  ]
};

Deno.test("Sub-bloque 2R-1g: (1) Golden tests no generan pendiente costo_no_factura", () => {
  const resPlat = costear(datosBase, {
    grupos: {
      suspension: "fleet_master",
      eje: "fleet_master",
      patin: "hj",
      piso: "laminado_plastico",
      abs: "2e_sin_retractil"
    }
  });
  assert(!resPlat.pendientes.some(p => p.tipo === "costo_no_factura"));

  const resDolly = costear(datosDolly, {
    grupos: {
      suspension: "ampro",
      eje: "ampro",
      quinta: "holland_fija",
      rines: "acero",
      llantas: "chinas",
      abs: "2e_sin_retractil"
    }
  });
  assert(!resDolly.pendientes.some(p => p.tipo === "costo_no_factura"));
});

Deno.test("Sub-bloque 2R-1g: (2) Plataforma 2 ejes con llantas cerex, color y pintura", () => {
  const config: Configuracion = {
    grupos: {
      llantas: "cerex",
      color: "rojo_claro",
      pintura: "sherwin_williams"
    }
  };

  const res = costear(datosPlataformaConRespaldo, config);

  // llantas: 4 * 2 * 3,586 = 28,688; color: 0; pintura: 0
  const lineaLlantas = res.secciones.opciones.lineas.find(l => l.concepto === "llantas: cerex");
  const lineaColor = res.secciones.opciones.lineas.find(l => l.concepto === "color: rojo_claro");
  const lineaPintura = res.secciones.opciones.lineas.find(l => l.concepto === "pintura: sherwin_williams");

  assert(lineaLlantas !== undefined);
  assertEquals(lineaLlantas.cantidad, 8);
  assertEquals(lineaLlantas.costo_unitario, 3586);
  assertEquals(lineaLlantas.importe, 28688);

  assert(lineaColor !== undefined);
  assertEquals(lineaColor.importe, 0);

  assert(lineaPintura !== undefined);
  assertEquals(lineaPintura.importe, 0);

  assertEquals(res.secciones.opciones.total, 28688);

  // Un pendiente por fuente con sus opciones listadas
  const pendTarifario = res.pendientes.find(p => p.tipo === "costo_no_factura" && p.detalle.includes("Tarifario"));
  const pendSupuesto = res.pendientes.find(p => p.tipo === "costo_no_factura" && p.detalle.includes("Supuesto: sin costo adicional"));

  assert(pendTarifario !== undefined);
  assertEquals(pendTarifario.detalle, "Costos que no vienen de la Factura (por confirmar): Tarifario → llantas/cerex");

  assert(pendSupuesto !== undefined);
  assertEquals(pendSupuesto.detalle, "Costos que no vienen de la Factura (por confirmar): Supuesto: sin costo adicional → color/rojo_claro, pintura/sherwin_williams");
});

Deno.test("Sub-bloque 2R-1g: (3) Misma configuración con 3 ejes escala llantas correctamente", () => {
  const datos3e: DatosCosteo = {
    ...datosPlataformaConRespaldo,
    modelo: {
      ...datosPlataformaConRespaldo.modelo,
      num_ejes: 3
    }
  };

  const config: Configuracion = {
    grupos: {
      llantas: "cerex",
      color: "rojo_claro",
      pintura: "sherwin_williams"
    }
  };

  const res = costear(datos3e, config);

  // llantas: 4 * 3 * 3,586 = 43,032
  const lineaLlantas = res.secciones.opciones.lineas.find(l => l.concepto === "llantas: cerex");
  assert(lineaLlantas !== undefined);
  assertEquals(lineaLlantas.cantidad, 12);
  assertEquals(lineaLlantas.costo_unitario, 3586);
  assertEquals(lineaLlantas.importe, 43032);
});

Deno.test("Sub-bloque 2R-1g: (4) Plafones con cantidad personalizada multiplica importe", () => {
  const config: Configuracion = {
    grupos: {
      plafones: { opcion: "ambar_laterales", cantidad: 10 }
    }
  };

  const res = costear(datosPlataformaConRespaldo, config);
  const lineaPlafones = res.secciones.opciones.lineas.find(l => l.concepto === "plafones: ambar_laterales");
  assert(lineaPlafones !== undefined);
  assertEquals(lineaPlafones.cantidad, 10);
  assertEquals(lineaPlafones.costo_unitario, 168.20);
  assertEquals(lineaPlafones.importe, 1682.00);
});

Deno.test("Sub-bloque 2R-1g: (5) Redilas 70 suma 35,000", () => {
  const config: Configuracion = {
    grupos: {
      redilas: "70"
    }
  };

  const res = costear(datosPlataformaConRespaldo, config);
  const lineaRedilas = res.secciones.opciones.lineas.find(l => l.concepto === "redilas: 70");
  assert(lineaRedilas !== undefined);
  assertEquals(lineaRedilas.cantidad, 1);
  assertEquals(lineaRedilas.costo_unitario, 35000);
  assertEquals(lineaRedilas.importe, 35000);
});

Deno.test("Sub-bloque 2R-1g: (6) Matracas corrediza suma 12 × 307.40 = 3,688.80 y no genera costo_no_factura", () => {
  const config: Configuracion = {
    grupos: {
      matracas: "corrediza"
    }
  };

  const res = costear(datosPlataformaConRespaldo, config);
  const lineaMatracas = res.secciones.opciones.lineas.find(l => l.concepto === "matracas: corrediza");
  assert(lineaMatracas !== undefined);
  assertEquals(lineaMatracas.cantidad, 12);
  assertEquals(lineaMatracas.costo_unitario, 307.40);
  assertEquals(lineaMatracas.importe, 3688.80);

  // Fuente es Factura Leolca -> NO debe haber pendiente costo_no_factura para matracas
  const pendNoFactura = res.pendientes.find(p => p.tipo === "costo_no_factura" && p.detalle.includes("matracas"));
  assertEquals(pendNoFactura, undefined);
});

Deno.test("Sub-bloque 2R-7: opción con costo_desde_producto=true toma costo del producto y reacciona a cambios", () => {
  const datosTest: DatosCosteo = JSON.parse(JSON.stringify(datosBase));
  // Añadimos una opción ligada a producto
  datosTest.opcion_costos.push({
    grupo_clave: "llantas",
    opcion_clave: "cerex",
    cantidad_base: 8,
    escala: "fija",
    costo_unitario: 3586,
    fuente: "Producto",
    producto_id: "prod-cerex-123",
    costo_desde_producto: true,
    producto_costo: 3800
  });

  const config: Configuracion = {
    grupos: {
      llantas: "cerex"
    }
  };

  const res1 = costear(datosTest, config);
  const linea1 = res1.secciones.opciones.lineas.find(l => l.concepto === "llantas: cerex");
  assert(linea1 !== undefined);
  assertEquals(linea1.costo_unitario, 3800);
  assertEquals(linea1.importe, 8 * 3800);

  // Si cambia el costo del producto, cambia el resultado
  const opt = datosTest.opcion_costos.find(o => o.opcion_clave === "cerex")!;
  opt.producto_costo = 4200;
  const res2 = costear(datosTest, config);
  const linea2 = res2.secciones.opciones.lineas.find(l => l.concepto === "llantas: cerex");
  assert(linea2 !== undefined);
  assertEquals(linea2.costo_unitario, 4200);
  assertEquals(linea2.importe, 8 * 4200);

  // Con costo_desde_producto=false, usa costo_unitario original
  opt.costo_desde_producto = false;
  const res3 = costear(datosTest, config);
  const linea3 = res3.secciones.opciones.lineas.find(l => l.concepto === "llantas: cerex");
  assert(linea3 !== undefined);
  assertEquals(linea3.costo_unitario, 3586);
  assertEquals(linea3.importe, 8 * 3586);
});

Deno.test("Sub-bloque 2R-7: opción con costo_desde_producto=true y producto en 0 o nulo genera sin_precio y suma 0", () => {
  const datosTest: DatosCosteo = JSON.parse(JSON.stringify(datosBase));
  datosTest.opcion_costos.push({
    grupo_clave: "llantas",
    opcion_clave: "cerex",
    cantidad_base: 8,
    escala: "fija",
    costo_unitario: 3586,
    fuente: "Producto",
    producto_id: "prod-cerex-123",
    costo_desde_producto: true,
    producto_costo: 0
  });

  const config: Configuracion = {
    grupos: {
      llantas: "cerex"
    }
  };

  const res = costear(datosTest, config);
  const linea = res.secciones.opciones.lineas.find(l => l.concepto === "llantas: cerex");
  assert(linea !== undefined);
  assertEquals(linea.costo_unitario, 0);
  assertEquals(linea.importe, 0);

  const pendSinPrecio = res.pendientes.find(p => p.tipo === "sin_precio" && p.detalle.includes("llantas/cerex"));
  assert(pendSinPrecio !== undefined);
});

Deno.test("Sub-bloque 2R-7: fuentes 'Manual (usuario)' y 'Producto' NO generan costo_no_factura, mientras 'Tarifario' SÍ", () => {
  const datosTest: DatosCosteo = {
    ...datosBase,
    opcion_costos: [
      {
        grupo_clave: "llantas",
        opcion_clave: "opcion_manual_test",
        cantidad_base: 8,
        escala: "fija",
        costo_unitario: 3586,
        fuente: "Manual (usuario)"
      },
      {
        grupo_clave: "rines",
        opcion_clave: "opcion_producto_test",
        cantidad_base: 8,
        escala: "fija",
        costo_unitario: 1200,
        fuente: "Producto"
      },
      {
        grupo_clave: "gancho",
        opcion_clave: "opcion_tarifario_test",
        cantidad_base: 1,
        escala: "fija",
        costo_unitario: 8000,
        fuente: "Tarifario"
      }
    ]
  };

  const config: Configuracion = {
    grupos: {
      llantas: "opcion_manual_test",
      rines: "opcion_producto_test",
      gancho: "opcion_tarifario_test"
    }
  };

  const res = costear(datosTest, config);

  // Manual no genera
  const pendManual = res.pendientes.find(p => p.tipo === "costo_no_factura" && p.detalle.includes("Manual"));
  assertEquals(pendManual, undefined);

  // Producto no genera
  const pendProd = res.pendientes.find(p => p.tipo === "costo_no_factura" && p.detalle.includes("Producto"));
  assertEquals(pendProd, undefined);

  // Tarifario sí genera
  const pendTarifario = res.pendientes.find(p => p.tipo === "costo_no_factura" && p.detalle.includes("Tarifario"));
  assert(pendTarifario !== undefined);
  assert(pendTarifario.detalle.includes("gancho/opcion_tarifario_test"));
});

Deno.test("Sub-bloque 2R-8: rines mixtos (8 acero + 4 aluminio) en 3 ejes cuesta exactamente 8 × 1,550 + 4 × 5,500 = 34,400", () => {
  const datos3Ejes = JSON.parse(JSON.stringify(datosBase)) as DatosCosteo;
  datos3Ejes.modelo.num_ejes = 3;

  const config: Configuracion = {
    grupos: {
      rines: [
        { opcion: "acero", marca: "Ampro", cantidad: 8 },
        { opcion: "aluminio", marca: "Ampro", cantidad: 4 }
      ]
    }
  };

  const res = costear(datos3Ejes, config);
  const lineaAcero = res.secciones.opciones.lineas.find(l => l.concepto === "rines: acero");
  const lineaAluminio = res.secciones.opciones.lineas.find(l => l.concepto === "rines: aluminio");

  assert(lineaAcero);
  assertEquals(lineaAcero.cantidad, 8);
  assertEquals(lineaAcero.costo_unitario, 1550);
  assertEquals(lineaAcero.importe, 12400);

  assert(lineaAluminio);
  assertEquals(lineaAluminio.cantidad, 4);
  assertEquals(lineaAluminio.costo_unitario, 5500);
  assertEquals(lineaAluminio.importe, 22000);

  assertEquals(lineaAcero.importe + lineaAluminio.importe, 34400);
});

Deno.test("Sub-bloque 2R-8: llantas mixtas (6 firestone + 6 cerex) suman cada fila con su costo propio", () => {
  const datos3Ejes = JSON.parse(JSON.stringify(datosBase)) as DatosCosteo;
  datos3Ejes.modelo.num_ejes = 3;

  // Agregar costo de cerex a opcion_costos si no está en fixture
  const yaTieneCerex = (datos3Ejes.opcion_costos || []).some(oc => oc.grupo_clave === "llantas" && oc.opcion_clave === "cerex");
  if (!yaTieneCerex) {
    datos3Ejes.opcion_costos.push({
      grupo_clave: "llantas",
      opcion_clave: "cerex",
      costo_unitario: 3586,
      cantidad_base: 4,
      escala: "por_eje"
    });
  }

  const config: Configuracion = {
    grupos: {
      llantas: [
        { opcion: "firestone", cantidad: 6 },
        { opcion: "cerex", cantidad: 6 }
      ]
    }
  };

  const res = costear(datos3Ejes, config);
  const lineaFirestone = res.secciones.opciones.lineas.find(l => l.concepto === "llantas: firestone");
  const lineaCerex = res.secciones.opciones.lineas.find(l => l.concepto === "llantas: cerex");

  assert(lineaFirestone);
  assertEquals(lineaFirestone.cantidad, 6);
  assertEquals(lineaFirestone.costo_unitario, 8700);
  assertEquals(lineaFirestone.importe, 52200);

  assert(lineaCerex);
  assertEquals(lineaCerex.cantidad, 6);
  assertEquals(lineaCerex.costo_unitario, 3586);
  assertEquals(lineaCerex.importe, 21516);

  assertEquals(lineaFirestone.importe + lineaCerex.importe, 73716);
});

Deno.test("Sub-bloque 2R-8: matracas con cantidad explícita (corrediza × 10) vs sin cantidad (usa default 12)", () => {
  const datosTest = JSON.parse(JSON.stringify(datosBase)) as DatosCosteo;
  const yaTieneMatracas = (datosTest.opcion_costos || []).some(oc => oc.grupo_clave === "matracas" && oc.opcion_clave === "corrediza");
  if (!yaTieneMatracas) {
    datosTest.opcion_costos.push({
      grupo_clave: "matracas",
      opcion_clave: "corrediza",
      costo_unitario: 307.4,
      cantidad_base: 12,
      escala: "fija"
    });
  }

  // 1. Con cantidad explícita (10 piezas)
  const config10: Configuracion = {
    grupos: {
      matracas: { opcion: "corrediza", cantidad: 10 }
    }
  };
  const res10 = costear(datosTest, config10);
  const linea10 = res10.secciones.opciones.lineas.find(l => l.concepto === "matracas: corrediza");
  assert(linea10);
  assertEquals(linea10.cantidad, 10);
  assertEquals(linea10.costo_unitario, 307.4);
  assertEquals(linea10.importe, 3074);

  // 2. Sin cantidad explícita (debe usar default 12 y no dejar en 0)
  const configDefault: Configuracion = {
    grupos: {
      matracas: "corrediza"
    }
  };
  const resDef = costear(datosTest, configDefault);
  const lineaDef = resDef.secciones.opciones.lineas.find(l => l.concepto === "matracas: corrediza");
  assert(lineaDef);
  assertEquals(lineaDef.cantidad, 12);
  assertEquals(lineaDef.costo_unitario, 307.4);
  assertEquals(lineaDef.importe, 3688.8);
});

Deno.test("Sub-bloque 2R-12: Costeo - normalización de paleta a grande, color personalizado exento y piso plastico_negro preservado", () => {
  // 1. Dolly con paleta normaliza a grande y cuesta exactamente 8,200 (idéntico a grande)
  const resDollyPaleta = costear(datosDolly, { grupos: { retractil: "paleta" } });
  const resDollyGrande = costear(datosDolly, { grupos: { retractil: "grande" } });
  assertEquals(resDollyPaleta.costo, resDollyGrande.costo);
  const lineaRetrDolly = resDollyPaleta.secciones.opciones.lineas.find(l => l.concepto.includes("retractil"));
  assert(lineaRetrDolly);
  assertEquals(lineaRetrDolly.costo_unitario, 8200);

  // 2. Góndola con paleta normaliza a grande y cuesta exactamente 15,000 (idéntico a grande)
  const resGondolaPaleta = costear(datosGondolaA36, { grupos: { retractil: "paleta" } });
  const resGondolaGrande = costear(datosGondolaA36, { grupos: { retractil: "grande" } });
  assertEquals(resGondolaPaleta.costo, resGondolaGrande.costo);
  const lineaRetrGondola = resGondolaPaleta.secciones.opciones.lineas.find(l => l.concepto.includes("retractil"));
  assert(lineaRetrGondola);
  assertEquals(lineaRetrGondola.costo_unitario, 15000);

  // 3. Color personalizado (con texto) cuesta 0, está exento y no genera pendientes sin_precio
  const resColorPers = costear(datosBase, {
    grupos: {
      color: { opcion: "personalizado", texto: "Verde militar con franja blanca" }
    }
  });
  const pendientesColor = resColorPers.pendientes.filter(p => p.detalle.toLowerCase().includes("color"));
  assertEquals(pendientesColor.length, 0);

  // 4. Piso plastico_negro (configuración vieja) sigue costeando con su valor histórico (36,182.72)
  const datosConPiso: DatosCosteo = {
    ...datosBase,
    opcion_costos: [
      ...datosBase.opcion_costos,
      { grupo_clave: "piso", opcion_clave: "plastico_negro", cantidad_base: 1, escala: "fija", costo_unitario: 36182.72 }
    ]
  };
  const resPisoNegro = costear(datosConPiso, { grupos: { piso: "plastico_negro" } });
  const lineaPiso = resPisoNegro.secciones.opciones.lineas.find(l => l.concepto === "piso: plastico_negro");
  assert(lineaPiso);
  assertEquals(lineaPiso.costo_unitario, 36182.72);

  // 5. Pintura vieja en configuración (sherwin_williams) no genera costo ni altera totales
  const resConPintura = costear(datosBase, { grupos: { color: "blanco", pintura: "sherwin_williams" } });
  const resSinPintura = costear(datosBase, { grupos: { color: "blanco" } });
  assertEquals(resConPintura.costo, resSinPintura.costo);
});



