import { assertEquals } from "https://deno.land/std@0.192.0/testing/asserts.ts";
import {
  esPartidaCompletaLinea,
  estadoVacioPestana,
  estadoVisualFase,
  extraerTareasPlan,
  faseEnCurso,
  normalizarTabExpediente,
  porcentajeEntregas,
  puedeLiberarFase,
  resolverPresupuestoDeOrden,
  resumenEntregasPorFase,
} from "../../../../src/app/components/Expediente/expedienteUtils.ts";

Deno.test("expedienteUtils: faseEnCurso prioriza en_proceso, luego primera no terminada, orden ausente y luego null", () => {
  assertEquals(faseEnCurso([]), null);
  assertEquals(faseEnCurso(null), null);

  // Aunque orden 1 esté pendiente, si orden 3 está en_proceso, gana orden 3
  const f1 = { fase_id: "f1", orden: 1, estado: "pendiente" };
  const f2 = { fase_id: "f2", orden: 2, estado: "terminada" };
  const f3 = { fase_id: "f3", orden: 3, estado: "en_proceso" };
  assertEquals(faseEnCurso([f3, f1, f2])?.fase_id, "f3");

  // E7: orden ausente cae al final (999), no antes que orden: 1
  assertEquals(
    faseEnCurso([
      { fase_id: "f-sin-orden", estado: "pendiente" },
      { fase_id: "f-primera", orden: 1, estado: "pendiente" },
    ])?.fase_id,
    "f-primera",
  );

  // Sin en_proceso: primera no terminada según orden ascendente
  assertEquals(
    faseEnCurso([
      { fase_id: "f3", orden: 3, estado: "pendiente" },
      { fase_id: "f1", orden: 1, estado: "terminada" },
      { fase_id: "f2", orden: 2, estado: "pausada" },
    ])?.fase_id,
    "f2",
  );

  // Todas terminadas -> null
  assertEquals(
    faseEnCurso([
      { fase_id: "f1", orden: 1, estado: "terminada" },
      { fase_id: "f2", orden: 2, estado: "terminada" },
    ]),
    null,
  );
});

Deno.test("expedienteUtils: estadoVisualFase cubre pasada, en_curso, futura y bordes E8-E12", () => {
  const f1 = { fase_id: "f1", orden: 1, estado: "terminada" };
  const f2 = { fase_id: "f2", orden: 2, estado: "pendiente" };
  const f3 = { fase_id: "f3", orden: 3, estado: "en_proceso" };
  const f4 = { fase_id: "f4", orden: 4, estado: "pendiente" };

  assertEquals(estadoVisualFase(f1, f3), "pasada");
  assertEquals(estadoVisualFase(f2, f3), "pasada"); // orden < orden(enCurso)
  assertEquals(estadoVisualFase(f3, f3), "en_curso");
  assertEquals(estadoVisualFase(f4, f3), "futura");

  // E8: fase terminada posterior a la en curso sigue siendo pasada
  assertEquals(estadoVisualFase({ fase_id: "f5", orden: 5, estado: "terminada" }, f3), "pasada");

  // E9: sin fase en curso, incluso una pendiente devuelve pasada
  assertEquals(estadoVisualFase(f2, null), "pasada");

  // E11: mismo orden pero distinto fase_id NO es en_curso
  assertEquals(estadoVisualFase({ fase_id: "f3-otra", orden: 3, estado: "pendiente" }, f3), "futura");

  // E12: sin ids, compara por orden
  assertEquals(estadoVisualFase({ orden: 3, estado: "pendiente" }, { orden: 3, estado: "en_proceso" }), "en_curso");
});

Deno.test("expedienteUtils: resumenEntregasPorFase y porcentajeEntregas cubren bordes y E18", () => {
  // Sin líneas -> porcentaje null (no 0%)
  const vacio = resumenEntregasPorFase([]);
  assertEquals(vacio.total_partidas, 0);
  assertEquals(vacio.partidas_completas, 0);
  assertEquals(porcentajeEntregas(vacio), null);

  // Nada entregado -> 0%
  const nada = resumenEntregasPorFase([
    { fase_clave: "corte", cantidad_requerida: 5, cantidad_entregada: 0 },
  ]);
  assertEquals(porcentajeEntregas(nada), 0);

  // Requerido 0 con entregado 0 -> NO completa (consistente con estado_entrega = 'pendiente')
  assertEquals(esPartidaCompletaLinea({ cantidad_requerida: 0, cantidad_entregada: 0 }), false);
  assertEquals(esPartidaCompletaLinea({ estado_entrega: "completo", cantidad_requerida: 0, cantidad_entregada: 0 }), true);

  // E18: 2/3 -> 67 (Math.round, no floor)
  assertEquals(porcentajeEntregas({ total_partidas: 3, partidas_completas: 2 }), 67);

  // Todo entregado + sobre-entrega + manual + anulada excluida
  const mix = resumenEntregasPorFase([
    { fase_clave: "corte", cantidad_requerida: 4, cantidad_entregada: 4 },
    { fase_clave: "corte", cantidad_requerida: 2, cantidad_entregada: 5 }, // sobre-entrega -> completa
    { fase_clave: "armado", cantidad_requerida: 3, cantidad_entregada: 1 }, // parcial
    { fase_clave: "armado", cantidad_requerida: 10, cantidad_entregada: 0, anulada: true }, // excluida
    { fase_clave: "", cantidad_requerida: 1, cantidad_entregada: 1 }, // manual sin fase -> sin_fase
  ]);

  assertEquals(mix.total_partidas, 4);
  assertEquals(mix.partidas_completas, 3);
  assertEquals(porcentajeEntregas(mix), 75);
  assertEquals(mix.por_fase.corte, { total_partidas: 2, partidas_completas: 2, porcentaje: 100 });
  assertEquals(mix.por_fase.armado, { total_partidas: 1, partidas_completas: 0, porcentaje: 0 });
  assertEquals(mix.por_fase.sin_fase, { total_partidas: 1, partidas_completas: 1, porcentaje: 100 });
});

Deno.test("expedienteUtils: puedeLiberarFase siempre permite liberar aunque la fase sea futura", () => {
  assertEquals(puedeLiberarFase("pintura", "futura"), { permitido: true, motivo: null });
  assertEquals(puedeLiberarFase("corte", "en_curso"), { permitido: true, motivo: null });
  assertEquals(puedeLiberarFase(null, "pasada"), { permitido: true, motivo: null });
});

Deno.test("expedienteUtils: estadoVacioPestana, normalizarTabExpediente y extraerTareasPlan (E3, E21, E22, D1)", () => {
  // E3: espacios alrededor
  assertEquals(normalizarTabExpediente("  ALMACEN  "), "almacen");
  assertEquals(normalizarTabExpediente("desconocido"), "resumen");
  assertEquals(normalizarTabExpediente(null), "resumen");

  // Equipo manual sin cotización
  assertEquals(estadoVacioPestana("cotizacion", { cotizacionId: null }).vacio, true);
  assertEquals(estadoVacioPestana("cotizacion", { cotizacionId: "cot-1" }).vacio, false);

  // E21: cobranza sin cotizacionId incluso si totalPagos > 0
  assertEquals(estadoVacioPestana("cobranza", { cotizacionId: null, totalPagos: 3 }).vacio, true);
  assertEquals(estadoVacioPestana("cobranza", { cotizacionId: "cot-1", totalPagos: 0 }).vacio, true);
  assertEquals(estadoVacioPestana("cobranza", { cotizacionId: "cot-1", totalPagos: 2 }).vacio, false);

  // E22: admiteDespiece === false incluso si totalLineasDespiece > 0
  assertEquals(estadoVacioPestana("almacen", { admiteDespiece: false, totalLineasDespiece: 5 }).vacio, true);
  assertEquals(estadoVacioPestana("almacen", { admiteDespiece: true, totalLineasDespiece: 0 }).vacio, true);
  assertEquals(estadoVacioPestana("almacen", { admiteDespiece: true, totalLineasDespiece: 4 }).vacio, false);

  assertEquals(estadoVacioPestana("plan", { totalTareasPlan: 0 }).vacio, true);
  assertEquals(estadoVacioPestana("plan", { totalTareasPlan: 1 }).vacio, false);

  // D1: forma real { orden, tareas, bitacora }
  const respReal = {
    orden: { id: "ot-1" },
    tareas: [
      {
        id: "t-1",
        fecha: "2026-11-18",
        descripcion: "Armado de dispositivo plataforma",
        estado: "en_proceso",
        frente: { nombre: "DOLLYS", area: { nombre: "Nave" } },
        operarios: [{ nombre: "Carlos López" }],
      },
    ],
    bitacora: [],
  };
  assertEquals(extraerTareasPlan(respReal).length, 1);
  assertEquals(extraerTareasPlan(respReal)[0].frente.area.nombre, "Nave");
  assertEquals(extraerTareasPlan(null), []);
  assertEquals(extraerTareasPlan({}), []);
});

Deno.test("expedienteUtils: resolverPresupuestoDeOrden liga por cotizacion_id o folio PRE-", () => {
  const presupuestos = [
    { id: "pre-1", folio: "PRE-COT-001", cotizacion_id: "cot-1" },
    { id: "pre-2", folio: "PRE-COT-002", cotizacion_id: null },
  ];
  assertEquals(resolverPresupuestoDeOrden({ cotizacion_id: "cot-1" }, presupuestos)?.id, "pre-1");
  assertEquals(
    resolverPresupuestoDeOrden({ cotizacion_id: "cot-2", cotizacion: { folio: "COT-002" } }, presupuestos)?.id,
    "pre-2",
  );
  assertEquals(resolverPresupuestoDeOrden({ cotizacion_id: null }, presupuestos), null);
});
