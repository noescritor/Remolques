import { assertEquals, assertRejects } from "jsr:@std/assert@1";
import {
  CobrosError,
  crearPlanPago,
  estatusParcialidad,
  imputarCobrosAParcialidades,
  listarPagosPaginados,
  mapearErrorRpcCobros,
  obtenerCobranzaCotizacion,
  obtenerCobranzaEquipo,
  registrarCobro,
  validarPlanParcialidades,
} from "./cobros.ts";

function makeMockSupabase(tables: Record<string, Array<Record<string, unknown>>>) {
  return {
    from(table: string) {
      const filters: Array<(row: Record<string, unknown>) => boolean> = [];
      let orderCols: Array<{ col: string; asc: boolean }> = [];
      let rangeSlice: [number, number] | null = null;
      let limitN: number | null = null;

      const exec = () => {
        let rows = [...(tables[table] || [])].filter((r) => filters.every((f) => f(r)));
        for (let i = orderCols.length - 1; i >= 0; i--) {
          const { col, asc } = orderCols[i];
          rows.sort((a, b) => {
            const va = String(a[col] ?? "");
            const vb = String(b[col] ?? "");
            return asc ? va.localeCompare(vb) : vb.localeCompare(va);
          });
        }
        if (rangeSlice) {
          rows = rows.slice(rangeSlice[0], rangeSlice[1] + 1);
        }
        if (limitN != null) {
          rows = rows.slice(0, limitN);
        }
        return rows;
      };

      const builder: Record<string, unknown> = {
        select() { return builder; },
        eq(col: string, val: unknown) {
          filters.push((r) => r[col] === val);
          return builder;
        },
        neq(col: string, val: unknown) {
          filters.push((r) => r[col] !== val);
          return builder;
        },
        is(col: string, val: unknown) {
          filters.push((r) => (r[col] ?? null) === val);
          return builder;
        },
        in(col: string, vals: unknown[]) {
          const set = new Set(vals);
          filters.push((r) => set.has(r[col]));
          return builder;
        },
        order(col: string, opts?: { ascending?: boolean }) {
          orderCols.push({ col, asc: opts?.ascending !== false });
          return builder;
        },
        range(from: number, to: number) {
          rangeSlice = [from, to];
          return builder;
        },
        limit(n: number) {
          limitN = n;
          return builder;
        },
        single() {
          const rows = exec();
          if (rows.length === 0) return Promise.resolve({ data: null, error: { message: "Not found" } });
          return Promise.resolve({ data: rows[0], error: null });
        },
        maybeSingle() {
          const rows = exec();
          return Promise.resolve({ data: rows[0] ?? null, error: null });
        },
        then(resolve: (v: { data: unknown[]; error: null }) => void) {
          return Promise.resolve({ data: exec(), error: null }).then(resolve);
        },
      };
      return builder;
    },
  } as unknown as Parameters<typeof listarPagosPaginados>[0];
}

Deno.test("mapearErrorRpcCobros mapea codigos reales de PG a HTTP status", () => {
  const e1 = mapearErrorRpcCobros(new Error("saldo_excedido: excede"));
  assertEquals(e1.status, 409);
  assertEquals(e1.codigo, "saldo_excedido");
  assertEquals(e1.extra?.requiere_confirmacion_saldo_a_favor, true);

  assertEquals(mapearErrorRpcCobros(new Error("cotizacion_no_cobrable: Solo se pueden cobrar")).status, 409);
  assertEquals(mapearErrorRpcCobros(new Error("cotizacion_no_encontrada: La cotización no existe")).status, 404);
  assertEquals(mapearErrorRpcCobros(new Error("cobro_no_encontrado: El cobro no existe")).status, 404);
  assertEquals(mapearErrorRpcCobros(new Error("plan_no_encontrado: Plan no encontrado")).status, 404);
  assertEquals(mapearErrorRpcCobros(new Error("metodo_pago_invalido: Método de pago no válido (Bitcoin)")).status, 400);
  assertEquals(mapearErrorRpcCobros(new Error("aplicacion_orden_invalida: El equipo no pertenece")).status, 400);
  assertEquals(mapearErrorRpcCobros(new Error("aplicacion_duplicada: No puedes repetir")).status, 400);
  assertEquals(mapearErrorRpcCobros(new Error("fecha_invalida: Fecha de vencimiento inválida (2026-02-31)")).status, 400);
  assertEquals(mapearErrorRpcCobros(new Error("especie_sin_descripcion: Describe el bien")).status, 400);
  assertEquals(mapearErrorRpcCobros(new Error("aplicaciones_exceden_monto: La suma")).status, 400);
  assertEquals(mapearErrorRpcCobros(new Error("motivo_requerido: El motivo")).status, 400);
});

Deno.test("listarPagosPaginados pagina >1000 filas, filtra por org y excluye anulados por defecto", async () => {
  const pagos: Array<Record<string, unknown>> = [];
  for (let i = 0; i < 1205; i++) {
    pagos.push({
      id: `p-${i}`,
      organizacion_id: "org-1",
      cotizacion_id: "cot-1",
      monto: 100,
      fecha: "2026-11-20",
      created_at: `2026-11-20T00:00:${String(i % 60).padStart(2, "0")}Z`,
      estado: i < 5 ? "anulado" : "vigente",
    });
  }
  pagos.push({
    id: "p-otra-org",
    organizacion_id: "org-2",
    cotizacion_id: "cot-1",
    monto: 999,
    fecha: "2026-11-20",
    created_at: "2026-11-20T00:00:00Z",
    estado: "vigente",
  });

  const sb = makeMockSupabase({ pagos });
  const vigentes = await listarPagosPaginados(sb, "org-1", {});
  assertEquals(vigentes.length, 1200);

  const todos = await listarPagosPaginados(sb, "org-1", { incluirAnulados: true });
  assertEquals(todos.length, 1205);
});

Deno.test("obtenerCobranzaCotizacion: aislamiento por org, 3x33333.33 y FIFO", async () => {
  const sb = makeMockSupabase({
    cotizaciones: [
      { id: "cot-1", organizacion_id: "org-1", folio: "COT-001", estado: "Aprobada", total: 100000, cliente_id: "cli-1" },
    ],
    clientes: [{ id: "cli-1", organizacion_id: "org-1", nombre_razon_social: "Cliente Uno" }],
    ordenes_trabajo: [{ id: "ord-1", organizacion_id: "org-1", cotizacion_id: "cot-1", nomenclatura_id: "N1", modelo: "M1", tipo_equipo: "Plana" }],
    equipo_valor_cobranza: [{ orden_trabajo_id: "ord-1", organizacion_id: "org-1", valor_pactado: 100000, notas: null }],
    pagos: [
      { id: "p1", organizacion_id: "org-1", cotizacion_id: "cot-1", monto: 33333.33, fecha: "2026-11-01", estado: "vigente", tipo_pago: "Transferencia" },
      { id: "p2", organizacion_id: "org-1", cotizacion_id: "cot-1", monto: 33333.33, fecha: "2026-11-02", estado: "vigente", tipo_pago: "Transferencia" },
      { id: "p3", organizacion_id: "org-1", cotizacion_id: "cot-1", monto: 33333.33, fecha: "2026-11-03", estado: "vigente", tipo_pago: "Transferencia" },
      { id: "p4", organizacion_id: "org-1", cotizacion_id: "cot-1", monto: 10000, fecha: "2026-11-04", estado: "anulado", tipo_pago: "Efectivo" },
    ],
    pago_aplicaciones: [{ id: "a1", organizacion_id: "org-1", pago_id: "p1", orden_trabajo_id: "ord-1", monto: 33333.33 }],
    planes_pago: [{ id: "pl-1", organizacion_id: "org-1", cotizacion_id: "cot-1", orden_trabajo_id: null, nombre: "Plan", activo: true }],
    plan_pagos_parcialidades: [
      { id: "pp1", organizacion_id: "org-1", plan_id: "pl-1", numero: 1, fecha_vencimiento: "2026-11-05", monto: 50000, nota: null },
      { id: "pp2", organizacion_id: "org-1", plan_id: "pl-1", numero: 2, fecha_vencimiento: "2026-11-10", monto: 50000, nota: null },
    ],
  });

  await assertRejects(
    () => obtenerCobranzaCotizacion(sb, "org-2", "cot-1", "2026-11-22"),
    CobrosError,
    "Cotización no encontrada",
  );

  const dto = await obtenerCobranzaCotizacion(sb, "org-1", "cot-1", "2026-11-22");
  assertEquals(dto.resumen.cobrado_vigente, 99999.99);
  assertEquals(dto.resumen.saldo_pendiente, 0.01);
  assertEquals(dto.resumen.sin_asignar_equipo, 66666.66);
  assertEquals(dto.equipos[0].cobrado_asignado, 33333.33);
  assertEquals(dto.plan_activo?.parcialidades[0].estatus, "pagada");
  assertEquals(dto.plan_activo?.parcialidades[1].estatus, "vencida");
});

Deno.test("crearPlanPago rechaza suma de parcialidades mayor al total", async () => {
  const sb = makeMockSupabase({
    cotizaciones: [{ id: "cot-1", organizacion_id: "org-1", total: 50000 }],
  });
  await assertRejects(
    () =>
      crearPlanPago(sb, "org-1", {
        cotizacion_id: "cot-1",
        parcialidades: [{ numero: 1, fecha_vencimiento: "2026-12-01", monto: 50001 }],
      }),
    CobrosError,
    "excede",
  );
});

Deno.test("obtenerCobranzaEquipo para orden manual retorna es_manual=true y sin cotizacion", async () => {
  const sb = makeMockSupabase({
    ordenes_trabajo: [{ id: "ord-m", organizacion_id: "org-1", cotizacion_id: null, nomenclatura_id: "MAN-1", modelo: "Custom", tipo_equipo: "Plana" }],
    equipo_valor_cobranza: [],
  });
  const res = await obtenerCobranzaEquipo(sb, "org-1", "ord-m", "2026-11-22");
  assertEquals(res.orden.es_manual, true);
  assertEquals(res.cobranza_cotizacion, null);
  assertEquals(res.valor_pactado, null);
});

Deno.test("D5 M1/M4/M7: vencida hoy vs ayer, orden FIFO por fecha y plan igual al total", () => {
  // M1: vencida ayer pero NO hoy
  assertEquals(estatusParcialidad(1000, 0, "2026-11-22", "2026-11-22"), "pendiente");
  assertEquals(estatusParcialidad(1000, 500, "2026-11-22", "2026-11-22"), "parcial");
  assertEquals(estatusParcialidad(1000, 500, "2026-11-21", "2026-11-22"), "vencida");

  // M4: imputarCobrosAParcialidades ordena por fecha_vencimiento ASC antes que numero
  const out = imputarCobrosAParcialidades(
    [
      { numero: 1, fecha_vencimiento: "2026-12-10", monto: 500 },
      { numero: 2, fecha_vencimiento: "2026-11-10", monto: 500 },
    ],
    500,
    "2026-11-22",
  );
  assertEquals(out[0].numero, 2);
  assertEquals(out[0].estatus, "pagada");
  assertEquals(out[1].numero, 1);
  assertEquals(out[1].estatus, "pendiente");

  // M7: suma exactamente igual al total es valida
  assertEquals(validarPlanParcialidades([{ numero: 1, fecha_vencimiento: "2026-12-01", monto: 100000 }], 100000).valido, true);
});

Deno.test("D5 M8: registrarCobro envia p_permitir_saldo_a_favor=false por defecto", async () => {
  let capturedParams: Record<string, unknown> | null = null;
  const mockRpcClient = {
    rpc(_fn: string, params: Record<string, unknown>) {
      capturedParams = params;
      return Promise.resolve({ data: { pago: { id: "p-1" } }, error: null });
    },
  } as unknown as Parameters<typeof registrarCobro>[0];

  await registrarCobro(mockRpcClient, "org-1", "user-1", {
    cotizacion_id: "cot-1",
    monto: 1000,
    tipo_pago: "Cheque",
  });
  assertEquals(capturedParams?.["p_permitir_saldo_a_favor"], false);
  assertEquals(capturedParams?.["p_tipo_pago"], "Cheque");
});

Deno.test("D5 M11/M12: cobrado_asignado excluye anulados y sin_asignar_equipo >= 0", async () => {
  const sb = makeMockSupabase({
    cotizaciones: [{ id: "cot-1", organizacion_id: "org-1", folio: "COT-1", estado: "Aprobada", total: 1000, cliente_id: null }],
    ordenes_trabajo: [{ id: "ord-1", organizacion_id: "org-1", cotizacion_id: "cot-1", nomenclatura_id: "N1", modelo: "M1", tipo_equipo: "Plana" }],
    equipo_valor_cobranza: [],
    pagos: [
      { id: "p-anulado", organizacion_id: "org-1", cotizacion_id: "cot-1", monto: 500, fecha: "2026-11-20", estado: "anulado", tipo_pago: "Transferencia" },
    ],
    pago_aplicaciones: [
      { id: "a-1", organizacion_id: "org-1", pago_id: "p-anulado", orden_trabajo_id: "ord-1", monto: 500 },
    ],
    planes_pago: [],
  });
  const dto = await obtenerCobranzaCotizacion(sb, "org-1", "cot-1", "2026-11-22");
  assertEquals(dto.equipos[0].cobrado_asignado, 0);
  assertEquals(dto.resumen.sin_asignar_equipo, 0);

  // M12: incluso si aplicaciones > cobrado (corrupcion hipotetica), sin_asignar_equipo no es negativo
  const sb2 = makeMockSupabase({
    cotizaciones: [{ id: "cot-1", organizacion_id: "org-1", folio: "COT-1", estado: "Aprobada", total: 1000, cliente_id: null }],
    ordenes_trabajo: [{ id: "ord-1", organizacion_id: "org-1", cotizacion_id: "cot-1", nomenclatura_id: "N1", modelo: "M1", tipo_equipo: "Plana" }],
    equipo_valor_cobranza: [],
    pagos: [{ id: "p1", organizacion_id: "org-1", cotizacion_id: "cot-1", monto: 100, fecha: "2026-11-20", estado: "vigente", tipo_pago: "Efectivo" }],
    pago_aplicaciones: [{ id: "a1", organizacion_id: "org-1", pago_id: "p1", orden_trabajo_id: "ord-1", monto: 200 }],
    planes_pago: [],
  });
  const dto2 = await obtenerCobranzaCotizacion(sb2, "org-1", "cot-1", "2026-11-22");
  assertEquals(dto2.resumen.sin_asignar_equipo, 0);
});
