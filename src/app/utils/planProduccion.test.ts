// @ts-nocheck
// Pruebas unitarias para funciones puras de plan de producción (Deno)
// Ejecutar con: deno test src/app/utils/planProduccion.test.ts

import { assertEquals, assertObjectMatch } from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  inicioDeSemana,
  diasDeSemana,
  etiquetaDia,
  rangoSemanaTexto,
  agruparPlan,
  totalesPersonal,
  detectarConflictos,
  duplicarSemana,
  puedeCambiarEstado,
  PlanTarea,
} from "./planProduccion.ts";

Deno.test("1. inicioDeSemana - Casos dorados y cruce de mes/año", () => {
  // Semana dorada del Excel (19 a 23 de octubre 2026)
  assertEquals(inicioDeSemana("2026-10-23"), "2026-10-19"); // Viernes -> Lunes
  assertEquals(inicioDeSemana("2026-10-19"), "2026-10-19"); // Lunes -> Lunes
  assertEquals(inicioDeSemana("2026-10-21"), "2026-10-19"); // Miércoles -> Lunes
  assertEquals(inicioDeSemana("2026-10-25"), "2026-10-19"); // Domingo -> Lunes de esa misma semana

  // Cruce de mes: viernes 2 de octubre 2026 -> lunes 28 de septiembre 2026
  assertEquals(inicioDeSemana("2026-10-02"), "2026-09-28");

  // Cruce de año: viernes 1 de enero 2027 -> lunes 28 de diciembre 2026
  assertEquals(inicioDeSemana("2027-01-01"), "2026-12-28");
});

Deno.test("2. diasDeSemana y etiquetaDia - 5 y 6 días con formato Excel", () => {
  const dias5 = diasDeSemana("2026-10-19");
  assertEquals(dias5, [
    "2026-10-19",
    "2026-10-20",
    "2026-10-21",
    "2026-10-22",
    "2026-10-23",
  ]);

  const dias6 = diasDeSemana("2026-10-19", { sabado: true });
  assertEquals(dias6.length, 6);
  assertEquals(dias6[5], "2026-10-24");

  assertEquals(etiquetaDia("2026-10-19"), "LUNES 19/10/26");
  assertEquals(etiquetaDia("2026-10-20"), "MARTES 20/10/26");
  assertEquals(etiquetaDia("2026-10-21"), "MIÉRCOLES 21/10/26");
  assertEquals(etiquetaDia("2026-10-22"), "JUEVES 22/10/26");
  assertEquals(etiquetaDia("2026-10-23"), "VIERNES 23/10/26");
  assertEquals(etiquetaDia("2026-10-24"), "SÁBADO 24/10/26");
});

Deno.test("3. rangoSemanaTexto - Mismo mes, cruce de mes y cruce de año", () => {
  // Semana dorada
  assertEquals(rangoSemanaTexto("2026-10-19"), "DEL 19 AL 23 DE OCTUBRE 2026");
  assertEquals(rangoSemanaTexto("2026-10-19", { sabado: true }), "DEL 19 AL 24 DE OCTUBRE 2026");

  // Cruce de mes: septiembre a octubre 2026
  assertEquals(rangoSemanaTexto("2026-09-28"), "DEL 28 DE SEPTIEMBRE AL 2 DE OCTUBRE 2026");

  // Cruce de año: diciembre 2026 a enero 2027
  assertEquals(rangoSemanaTexto("2026-12-28"), "DEL 28 DE DICIEMBRE 2026 AL 1 DE ENERO 2027");
});

Deno.test("4. agruparPlan - Agrupación por día y frente", () => {
  const tareas: PlanTarea[] = [
    {
      id: "t1",
      fecha: "2026-10-19",
      frente_id: "f-dollys",
      descripcion: "Armado de perchas",
      estado: "planeada",
    },
    {
      id: "t2",
      fecha: "2026-10-19",
      frente_id: "f-dollys",
      descripcion: "Montaje de ejes",
      estado: "en_proceso",
    },
    {
      id: "t3",
      fecha: "2026-10-20",
      frente_id: "f-cajas",
      descripcion: "Soldadura de polineras",
      estado: "planeada",
    },
  ];

  const mapa = agruparPlan(tareas);
  assertEquals(mapa["2026-10-19"]["f-dollys"].length, 2);
  assertEquals(mapa["2026-10-20"]["f-cajas"].length, 1);
  assertEquals(mapa["2026-10-19"]["f-cajas"], undefined);
});

Deno.test("5. totalesPersonal - Operario en dos frentes el mismo día (columna TOT vs fila TOTAL DE PERSONAL)", () => {
  // Escenario dorado:
  // Operario "op-1" asignado el Lunes en f-dollys y TAMBIÉN en f-cajas el Lunes.
  // Operario "op-2" asignado el Lunes en f-dollys.
  // Operario "op-1" asignado el Martes en f-dollys.
  const tareas: PlanTarea[] = [
    {
      id: "t1",
      fecha: "2026-10-19",
      frente_id: "f-dollys",
      estado: "planeada",
      operarios: [{ id: "op-1", nombre: "Juan" }, { id: "op-2", nombre: "Pedro" }],
    },
    {
      id: "t2",
      fecha: "2026-10-19",
      frente_id: "f-cajas",
      estado: "planeada",
      operarios: [{ id: "op-1", nombre: "Juan" }],
    },
    {
      id: "t3",
      fecha: "2026-10-20",
      frente_id: "f-dollys",
      estado: "planeada",
      operarios: [{ id: "op-1", nombre: "Juan" }],
    },
    {
      id: "t-cancelada",
      fecha: "2026-10-19",
      frente_id: "f-dollys",
      estado: "cancelada",
      operarios: [{ id: "op-3", nombre: "Cancelado" }],
    },
  ];

  const totales = totalesPersonal(tareas);

  // Columna TOT (operarios distintos del área ese día):
  // Lunes: op-1 y op-2 -> exactamente 2 personas físicas (op-1 no se duplica en el TOT diario)
  assertEquals(totales.porDia["2026-10-19"], 2);
  // Martes: op-1 -> 1 persona física
  assertEquals(totales.porDia["2026-10-20"], 1);

  // Fila TOTAL DE PERSONAL por frente:
  // f-dollys: op-1 (t1), op-2 (t1), op-1 (t3) = 3 asignaciones
  assertEquals(totales.porFrente["f-dollys"], 3);
  // f-cajas: op-1 (t2) = 1 asignación
  assertEquals(totales.porFrente["f-cajas"], 1);

  // Total de asignaciones en la semana = 4 (3 en dollys + 1 en cajas)
  assertEquals(totales.totalAsignaciones, 4);

  // Operarios únicos que trabajaron en el área en la semana = 2 (op-1 y op-2)
  assertEquals(totales.operariosUnicosSemana, 2);
});

Deno.test("6. detectarConflictos - Operario asignado a más de una tarea el mismo día", () => {
  const tareas: PlanTarea[] = [
    {
      id: "t-A",
      fecha: "2026-10-19",
      frente_id: "f-1",
      estado: "planeada",
      operarios: [{ id: "op-juan" }],
    },
    {
      id: "t-B",
      fecha: "2026-10-19",
      frente_id: "f-2",
      estado: "planeada",
      operarios: [{ id: "op-juan" }],
    },
    {
      id: "t-C",
      fecha: "2026-10-20",
      frente_id: "f-1",
      estado: "planeada",
      operarios: [{ id: "op-juan" }],
    },
  ];

  const conflictos = detectarConflictos(tareas);
  assertEquals(conflictos.length, 1);
  assertEquals(conflictos[0].operarioId, "op-juan");
  assertEquals(conflictos[0].fecha, "2026-10-19");
  assertEquals(conflictos[0].tareaIds.sort(), ["t-A", "t-B"].sort());
});

Deno.test("7. duplicarSemana - Desplazamiento +7 días, reseteo a planeada y exclusión de canceladas", () => {
  const tareasSemana1: PlanTarea[] = [
    {
      id: "t1",
      fecha: "2026-10-19",
      frente_id: "f-dollys",
      orden_trabajo_id: "ot-100",
      descripcion: "Ensamble general",
      movilidad: "Grúa 1",
      observaciones: "Prioridad alta",
      estado: "terminada",
      inicio_real: "2026-10-19T08:00:00Z",
      fin_real: "2026-10-19T17:00:00Z",
      material_faltante: true,
      operarios: [{ id: "op-1", nombre: "Carlos" }],
      materiales: [
        { descripcion: "Viga IPR 4 pulg", cantidad: 2, unidad: "PZA" },
      ],
    },
    {
      id: "t-cancelada",
      fecha: "2026-10-20",
      frente_id: "f-dollys",
      estado: "cancelada",
      descripcion: "No debe copiarse",
    },
  ];

  const duplicadas = duplicarSemana(tareasSemana1, {
    desde: "2026-10-19",
    hasta: "2026-10-26",
  });

  assertEquals(duplicadas.length, 1);
  const nueva = duplicadas[0];

  // Fecha desplazada exactamente 7 días
  assertEquals(nueva.fecha, "2026-10-26");
  assertEquals(nueva.frente_id, "f-dollys");
  assertEquals(nueva.orden_trabajo_id, "ot-100");
  assertEquals(nueva.descripcion, "Ensamble general");
  assertEquals(nueva.movilidad, "Grúa 1");
  assertEquals(nueva.observaciones, "Prioridad alta");

  // Estado reseteado
  assertEquals(nueva.estado, "planeada");
  assertEquals(nueva.inicio_real, null);
  assertEquals(nueva.fin_real, null);
  assertEquals(nueva.material_faltante, false);

  // Operarios y materiales conservados
  assertEquals(nueva.operarios, ["op-1"]);
  assertEquals(nueva.materiales.length, 1);
  assertEquals(nueva.materiales[0].descripcion, "Viga IPR 4 pulg");
  assertEquals(nueva.materiales[0].cantidad, 2);
});

Deno.test("8. puedeCambiarEstado - Transiciones válidas, confirmación de reapertura y marcas de tiempo", () => {
  // planeada -> en_proceso (válido, fija inicio)
  const c1 = puedeCambiarEstado("planeada", "en_proceso");
  assertEquals(c1.valido, true);
  assertEquals(c1.fijaTiempos.fijarInicio, true);
  assertEquals(c1.fijaTiempos.fijarFin, false);

  // planeada -> cancelada (válido, sin tiempos)
  const c2 = puedeCambiarEstado("planeada", "cancelada");
  assertEquals(c2.valido, true);
  assertEquals(c2.fijaTiempos.fijarInicio, false);

  // planeada -> terminada (inválido)
  const c3 = puedeCambiarEstado("planeada", "terminada");
  assertEquals(c3.valido, false);

  // en_proceso -> pausada (válido)
  const c4 = puedeCambiarEstado("en_proceso", "pausada");
  assertEquals(c4.valido, true);

  // en_proceso -> terminada (válido, fija fin)
  const c5 = puedeCambiarEstado("en_proceso", "terminada");
  assertEquals(c5.valido, true);
  assertEquals(c5.fijaTiempos.fijarFin, true);

  // pausada -> en_proceso (válido)
  const c6 = puedeCambiarEstado("pausada", "en_proceso");
  assertEquals(c6.valido, true);

  // terminada -> en_proceso sin confirmación (bloqueado)
  const c7 = puedeCambiarEstado("terminada", "en_proceso");
  assertEquals(c7.valido, false);
  assertEquals(c7.motivo?.includes("confirmación"), true);

  // terminada -> en_proceso con confirmación (permitido)
  const c8 = puedeCambiarEstado("terminada", "en_proceso", { confirmarReapertura: true });
  assertEquals(c8.valido, true);

  // cancelada -> planeada (inválido)
  const c9 = puedeCambiarEstado("cancelada", "planeada");
  assertEquals(c9.valido, false);
});
