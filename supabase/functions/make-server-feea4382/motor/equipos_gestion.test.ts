import { assertEquals, assertRejects } from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  EquiposGestionError,
  validarRolAdminOPropietario,
  normalizarFechaIsoOpcional,
  mapearErrorRpcEquipos,
  cancelarOrdenTrabajoMotor,
  reactivarOrdenTrabajoMotor,
  cambiarClienteOrdenTrabajoMotor,
  listarOrdenesTrabajoMotor,
} from "./equipos_gestion.ts";
import {
  generarOrdenesDeCotizacion,
  actualizarOrdenTrabajoSegura,
} from "./generar_ordenes_cotizacion.ts";
import { actualizarPlaneacionMotor } from "./tablero_produccion.ts";

function crearMockService(opts: {
  perfiles?: Array<{ organizacion_id: string; usuario_id: string; rol: string }>;
  ordenes?: Array<Record<string, any>>;
  rpcHandler?: (fn: string, args: Record<string, any>) => { data: any; error: any };
  usuarios?: Record<string, { email?: string; user_metadata?: Record<string, any> }>;
}) {
  const perfiles = opts.perfiles || [];
  const ordenes = opts.ordenes || [];

  function filtrar(rows: any[], filtros: Array<{ op: string; col: string; val: any }>) {
    return rows.filter((row) =>
      filtros.every((f) => {
        if (f.op === "eq") return row[f.col] === f.val;
        if (f.op === "is") return f.val === null ? row[f.col] == null : row[f.col] === f.val;
        if (f.op === "not_is") return f.val === null ? row[f.col] != null : row[f.col] !== f.val;
        return true;
      })
    );
  }

  return {
    auth: {
      admin: {
        getUserById: async (uid: string) => ({
          data: { user: opts.usuarios?.[uid] || null },
          error: null,
        }),
      },
    },
    rpc: async (fn: string, args: Record<string, any>) => {
      if (opts.rpcHandler) return opts.rpcHandler(fn, args);
      return { data: null, error: null };
    },
    from: (table: string) => {
      const filtros: Array<{ op: string; col: string; val: any }> = [];
      let updatePayload: Record<string, any> | null = null;

      const getSource = () => {
        if (table === "perfiles_organizacion") return perfiles;
        if (table === "ordenes_trabajo") return ordenes;
        return [];
      };

      const chain: any = {
        select: () => chain,
        update: (p: Record<string, any>) => {
          updatePayload = p;
          return chain;
        },
        eq: (col: string, val: any) => {
          filtros.push({ op: "eq", col, val });
          return chain;
        },
        is: (col: string, val: any) => {
          filtros.push({ op: "is", col, val });
          return chain;
        },
        not: (col: string, op: string, val: any) => {
          if (op === "is") filtros.push({ op: "not_is", col, val });
          return chain;
        },
        order: () => chain,
        maybeSingle: async () => {
          const matches = filtrar(getSource(), filtros);
          if (updatePayload && matches[0]) {
            Object.assign(matches[0], updatePayload);
          }
          return { data: matches[0] || null, error: null };
        },
        single: async () => {
          const matches = filtrar(getSource(), filtros);
          if (updatePayload && matches[0]) {
            Object.assign(matches[0], updatePayload);
          }
          return {
            data: matches[0] || null,
            error: matches[0] ? null : { message: "No rows" },
          };
        },
        then: (resolve: any, reject: any) => {
          try {
            const matches = filtrar(getSource(), filtros);
            resolve({ data: matches, error: null });
          } catch (e) {
            reject(e);
          }
        },
      };
      return chain;
    },
  };
}

Deno.test("equipos_gestion: solo admin o propietario pasan validación de rol", async () => {
  const client = crearMockService({
    perfiles: [
      { organizacion_id: "org-1", usuario_id: "u-prop", rol: "propietario" },
      { organizacion_id: "org-1", usuario_id: "u-admin", rol: "admin" },
      { organizacion_id: "org-1", usuario_id: "u-vend", rol: "vendedor" },
      { organizacion_id: "org-1", usuario_id: "u-op", rol: "operario" },
    ],
  });

  assertEquals(await validarRolAdminOPropietario(client, "org-1", "u-prop"), "propietario");
  assertEquals(await validarRolAdminOPropietario(client, "org-1", "u-admin"), "admin");

  await assertRejects(
    () => validarRolAdminOPropietario(client, "org-1", "u-vend"),
    EquiposGestionError,
    "Solo administradores o propietarios"
  );
  await assertRejects(
    () => validarRolAdminOPropietario(client, "org-1", "u-op"),
    EquiposGestionError
  );
  await assertRejects(
    () => validarRolAdminOPropietario(client, "org-1", "u-otro"),
    EquiposGestionError
  );
  await assertRejects(
    () => validarRolAdminOPropietario(client, "org-1", null),
    EquiposGestionError
  );
});

Deno.test("equipos_gestion: normalizarFechaIsoOpcional valida fechas reales", () => {
  assertEquals(normalizarFechaIsoOpcional(null), null);
  assertEquals(normalizarFechaIsoOpcional(""), null);
  assertEquals(normalizarFechaIsoOpcional("2026-11-27"), "2026-11-27");

  let errFormato: any = null;
  try {
    normalizarFechaIsoOpcional("27/11/2026");
  } catch (e) {
    errFormato = e;
  }
  assertEquals(errFormato?.status, 400);

  let errCalendario: any = null;
  try {
    normalizarFechaIsoOpcional("2026-02-30");
  } catch (e) {
    errCalendario = e;
  }
  assertEquals(errCalendario?.status, 400);
});

Deno.test("equipos_gestion: mapearErrorRpcEquipos mapea todos los códigos esperados", () => {
  const eMot = mapearErrorRpcEquipos({ message: "motivo_requerido: Falta motivo" });
  assertEquals(eMot.status, 400);
  assertEquals(eMot.codigo, "motivo_requerido");

  const eCob = mapearErrorRpcEquipos({
    message: "orden_con_cobros_vigentes: Tiene cobros",
    details: JSON.stringify({ cobros_count: 2, cobros_total: 15000 }),
  });
  assertEquals(eCob.status, 409);
  assertEquals(eCob.codigo, "orden_con_cobros_vigentes");
  assertEquals(eCob.detalle?.cobros_count, 2);

  const eMat = mapearErrorRpcEquipos({
    message: "orden_con_material_entregado: Tiene material",
    details: JSON.stringify({ entregas_count: 3, cantidad_total: 12.5 }),
  });
  assertEquals(eMat.status, 409);
  assertEquals(eMat.codigo, "orden_con_material_entregado");
  assertEquals(eMat.detalle?.requiere_confirmacion_material, true);
  assertEquals(eMat.detalle?.cantidad_total, 12.5);

  const eCot = mapearErrorRpcEquipos({ message: "orden_origen_cotizacion: Viene de cotización" });
  assertEquals(eCot.status, 409);
  assertEquals(eCot.codigo, "orden_origen_cotizacion");

  const eCanc = mapearErrorRpcEquipos({ message: "orden_cancelada: Cancelado" });
  assertEquals(eCanc.status, 409);
  assertEquals(eCanc.codigo, "orden_cancelada");

  const eNotFound = mapearErrorRpcEquipos({ message: "orden_no_encontrada: No existe" });
  assertEquals(eNotFound.status, 404);
});

Deno.test("equipos_gestion: cancelarOrdenTrabajoMotor valida motivo, rol y pasa confirmo_material_entregado", async () => {
  let lastArgs: any = null;
  const orden = { id: "ot-1", organizacion_id: "org-1", estado: "En Producción", cancelada_el: null };
  const client = crearMockService({
    perfiles: [{ organizacion_id: "org-1", usuario_id: "u-admin", rol: "admin" }],
    ordenes: [orden],
    rpcHandler: (fn, args) => {
      assertEquals(fn, "cancelar_orden_trabajo");
      lastArgs = args;
      if (!args.p_confirmo_material_entregado) {
        return {
          data: null,
          error: {
            message: "orden_con_material_entregado: El equipo tiene 2 entrega(s) (5 unidades)",
            details: JSON.stringify({ entregas_count: 2, cantidad_total: 5 }),
          },
        };
      }
      orden.cancelada_el = "2026-11-27T12:00:00Z" as any;
      return {
        data: { ok: true, ya_cancelada: false, entregas_vigentes: 2, cantidad_entregada_vigente: 5, orden },
        error: null,
      };
    },
  });

  // Motivo vacío -> 400
  await assertRejects(
    () =>
      cancelarOrdenTrabajoMotor(client, {
        orgId: "org-1",
        usuarioId: "u-admin",
        ordenId: "ot-1",
        motivo: "   ",
      }),
    EquiposGestionError,
    "motivo"
  );

  // Sin confirmación de material -> 409
  const err409 = await assertRejects(
    () =>
      cancelarOrdenTrabajoMotor(client, {
        orgId: "org-1",
        usuarioId: "u-admin",
        ordenId: "ot-1",
        motivo: "Error de captura",
      }),
    EquiposGestionError
  );
  assertEquals(err409.status, 409);
  assertEquals(err409.codigo, "orden_con_material_entregado");
  assertEquals(err409.detalle?.requiere_confirmacion_material, true);

  // Con confirmación -> éxito
  const res = await cancelarOrdenTrabajoMotor(client, {
    orgId: "org-1",
    usuarioId: "u-admin",
    ordenId: "ot-1",
    motivo: "Error de captura",
    confirmoMaterialEntregado: true,
  });
  assertEquals(res.ok, true);
  assertEquals(res.ya_cancelada, false);
  assertEquals(res.entregas_vigentes, 2);
  assertEquals(lastArgs?.p_confirmo_material_entregado, true);
});

Deno.test("equipos_gestion: reactivar y cambiar cliente respetan reglas de rol y origen", async () => {
  const orden = {
    id: "ot-m",
    organizacion_id: "org-1",
    origen: "manual",
    nomenclatura_id: "101-INV011126-1",
    cliente_id: null,
    etiqueta: "Stock",
    cancelada_el: "2026-11-27T12:00:00Z",
  };
  const client = crearMockService({
    perfiles: [{ organizacion_id: "org-1", usuario_id: "u-prop", rol: "propietario" }],
    ordenes: [orden],
    rpcHandler: (fn, args) => {
      if (fn === "reactivar_orden_trabajo") {
        orden.cancelada_el = null as any;
        return { data: { ok: true, ya_activa: false, orden }, error: null };
      }
      if (fn === "cambiar_cliente_orden_trabajo") {
        orden.cliente_id = args.p_cliente_id;
        orden.etiqueta = args.p_etiqueta;
        return { data: { ok: true, sin_cambios: false, orden }, error: null };
      }
      return { data: null, error: null };
    },
  });

  const react = await reactivarOrdenTrabajoMotor(client, {
    orgId: "org-1",
    usuarioId: "u-prop",
    ordenId: "ot-m",
  });
  assertEquals(react.ok, true);
  assertEquals(react.orden.cancelada_el, null);

  // Cambiar cliente sin cliente ni etiqueta -> 400
  await assertRejects(
    () =>
      cambiarClienteOrdenTrabajoMotor(client, {
        orgId: "org-1",
        usuarioId: "u-prop",
        ordenId: "ot-m",
        clienteId: null,
        etiqueta: "",
      }),
    EquiposGestionError
  );

  const cambio = await cambiarClienteOrdenTrabajoMotor(client, {
    orgId: "org-1",
    usuarioId: "u-prop",
    ordenId: "ot-m",
    clienteId: "cli-9",
    etiqueta: "Nuevo Cliente",
  });
  assertEquals(cambio.ok, true);
  assertEquals(cambio.orden.cliente_id, "cli-9");
  assertEquals(cambio.orden.nomenclatura_id, "101-INV011126-1");
});

Deno.test("equipos_gestion: listarOrdenesTrabajoMotor separa activas y canceladas", async () => {
  const client = crearMockService({
    ordenes: [
      { id: "ot-act", organizacion_id: "org-1", cancelada_el: null },
      { id: "ot-can", organizacion_id: "org-1", cancelada_el: "2026-11-27T10:00:00Z", cancelada_por: "u-1" },
    ],
    usuarios: {
      "u-1": { email: "admin@leolca.mx", user_metadata: { nombre: "Luis Admin" } },
    },
  });

  const activas = await listarOrdenesTrabajoMotor(client, "org-1");
  assertEquals(activas.length, 1);
  assertEquals(activas[0].id, "ot-act");

  const canceladas = await listarOrdenesTrabajoMotor(client, "org-1", { soloCanceladas: true });
  assertEquals(canceladas.length, 1);
  assertEquals(canceladas[0].id, "ot-can");
  assertEquals(canceladas[0].cancelada_por_nombre, "Luis Admin");
});

Deno.test("equipos_gestion: generarOrdenesDeCotizacion cuenta canceladas como existentes y explica en mensaje", async () => {
  const db: any = {
    from: (table: string) => ({
      select: () => ({
        eq: () => ({
          eq: () => {
            if (table === "cotizaciones") {
              return {
                single: async () => ({
                  data: { id: "cot-1", organizacion_id: "org-1", estado: "Aprobada", items: [] },
                  error: null,
                }),
              };
            }
            return Promise.resolve({
              data: [
                { id: "ot-1", cotizacion_id: "cot-1", organizacion_id: "org-1", cancelada_el: "2026-11-27T01:00:00Z" },
              ],
              error: null,
            });
          },
        }),
      }),
    }),
  };

  const res: any = await generarOrdenesDeCotizacion(db, {
    cotizacionId: "cot-1",
    orgId: "org-1",
  });
  assertEquals(res.creadas, 0);
  assertEquals(res.ya_existian, true);
  assertEquals(res.canceladas_existentes, 1);
  assertEquals(res.ordenes.length, 0);
  assertEquals(res.mensaje.includes("cancelada"), true);
});

Deno.test("equipos_gestion: actualizarOrdenTrabajoSegura y actualizarPlaneacionMotor rechazan orden cancelada y aceptan fecha_pedido", async () => {
  const otActiva = { id: "ot-a", organizacion_id: "org-1", cancelada_el: null, fecha_pedido: null };
  const otCancelada = { id: "ot-c", organizacion_id: "org-1", cancelada_el: "2026-11-27T00:00:00Z" };
  const client = crearMockService({ ordenes: [otActiva, otCancelada] });

  const upd1 = await actualizarOrdenTrabajoSegura(client, {
    id: "ot-a",
    orgId: "org-1",
    rawPayload: { fecha_pedido: "2026-11-20" },
  });
  assertEquals(upd1.fecha_pedido, "2026-11-20");

  const errCanc1: any = await assertRejects(() =>
    actualizarOrdenTrabajoSegura(client, {
      id: "ot-c",
      orgId: "org-1",
      rawPayload: { fecha_pedido: "2026-11-20" },
    })
  );
  assertEquals(errCanc1.status, 409);

  const upd2 = await actualizarPlaneacionMotor(client, "org-1", "ot-a", {
    fecha_pedido: "2026-11-25",
  });
  assertEquals(upd2.orden.fecha_pedido, "2026-11-25");

  const errCanc2: any = await assertRejects(() =>
    actualizarPlaneacionMotor(client, "org-1", "ot-c", {
      fecha_pedido: "2026-11-25",
    })
  );
  assertEquals(errCanc2.status, 409);
});
