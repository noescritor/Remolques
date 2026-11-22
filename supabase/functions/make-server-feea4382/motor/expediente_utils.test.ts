import { assertEquals } from "https://deno.land/std@0.192.0/testing/asserts.ts";
import {
  estadoVacioPestana,
  estadoVisualFase,
  faseEnCurso,
  normalizarTabExpediente,
  porcentajeEntregas,
  puedeLiberarFase,
  resolverPresupuestoDeOrden,
  resumenEntregasPorFase,
} from "../../../../src/app/components/Expediente/expedienteUtils.ts";

Deno.test("expedienteUtils: faseEnCurso prioriza en_proceso, luego primera no terminada, luego null", () => {
  assertEquals(faseEnCurso([]), null);
  assertEquals(faseEnCurso(null), null);

  // Aunque orden 1 esté pendiente, si orden 3 está en_proceso, gana orden 3
  const f1 = { fase_id: "f1", orden: 1, estado: "pendiente" };
  const f2 = { fase_id: "f2", orden: 2, estado: "terminada" };
  const f3 = { fase_id: "f3", orden: 3, estado: "en_proceso" };
  assertEquals(faseEnCurso([f3, f1, f2])?.fase_id, "f3");

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

Deno.test("expedienteUtils: estadoVisualFase distingue pasada, en_curso y futura", () => {
  const f1 = { fase_id: "f1", orden: 1, estado: "terminada" };
  const f2 = { fase_id: "f2", orden: 2, estado: "pendiente" };
  const f3 = { fase_id: "f3", orden: 3, estado: "en_proceso" };
  const f4 = { fase_id: "f4", orden: 4, estado: "pendiente" };

  assertEquals(estadoVisualFase(f1, f3), "pasada");
  assertEquals(estadoVisualFase(f2, f3), "pasada"); // orden < orden(enCurso)
  assertEquals(estadoVisualFase(f3, f3), "en_curso");
  assertEquals(estadoVisualFase(f4, f3), "futura");
  assertEquals(estadoVisualFase(f1, null), "pasada");
});

Deno.test("expedienteUtils: resumenEntregasPorFase y porcentajeEntregas cubren bordes", () => {
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

Deno.test("expedienteUtils: estadoVacioPestana y normalizarTabExpediente", () => {
  assertEquals(normalizarTabExpediente("ALMACEN"), "almacen");
  assertEquals(normalizarTabExpediente("desconocido"), "resumen");
  assertEquals(normalizarTabExpediente(null), "resumen");

  // Equipo manual sin cotización
  assertEquals(estadoVacioPestana("cotizacion", { cotizacionId: null }).vacio, true);
  assertEquals(estadoVacioPestana("cotizacion", { cotizacionId: "cot-1" }).vacio, false);

  assertEquals(estadoVacioPestana("cobranza", { cotizacionId: null }).vacio, true);
  assertEquals(estadoVacioPestana("cobranza", { cotizacionId: "cot-1", totalPagos: 0 }).vacio, true);
  assertEquals(estadoVacioPestana("cobranza", { cotizacionId: "cot-1", totalPagos: 2 }).vacio, false);

  assertEquals(estadoVacioPestana("almacen", { admiteDespiece: false }).vacio, true);
  assertEquals(estadoVacioPestana("almacen", { admiteDespiece: true, totalLineasDespiece: 0 }).vacio, true);
  assertEquals(estadoVacioPestana("almacen", { admiteDespiece: true, totalLineasDespiece: 4 }).vacio, false);

  assertEquals(estadoVacioPestana("plan", { totalTareasPlan: 0 }).vacio, true);
  assertEquals(estadoVacioPestana("plan", { totalTareasPlan: 1 }).vacio, false);
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
