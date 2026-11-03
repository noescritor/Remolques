import { assertEquals, assertRejects, assert } from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  listarDespieceOT,
  generarDespieceOT,
  registrarEntrega,
  ajustarCantidadRequerida,
  eliminarLineaManual,
  agregarLineaManual,
} from "./checklist_almacen.ts";

function createFakeClient(opts: {
  tables?: Record<string, any[]>;
  rpcHandler?: (name: string, args: any) => any;
  isServiceClient?: boolean;
}) {
  const tables: Record<string, any[]> = opts.tables || {};
  const isServiceClient = opts.isServiceClient !== false;

  return {
    from: (tableName: string) => {
      let filters: Array<{ col: string; op: string; val: any }> = [];
      let selectFields = "*";

      const builder: any = {
        select: (cols?: string) => {
          selectFields = cols || "*";
          return builder;
        },
        eq: (col: string, val: any) => {
          filters.push({ col, op: "eq", val });
          return builder;
        },
        gt: (col: string, val: any) => {
          filters.push({ col, op: "gt", val });
          return builder;
        },
        in: (col: string, vals: any[]) => {
          filters.push({ col, op: "in", val: vals });
          return builder;
        },
        order: () => builder,
        limit: () => builder,
        single: () => {
          const rows = getFilteredRows();
          return Promise.resolve({ data: rows[0] || null, error: rows.length ? null : { message: "No rows" } });
        },
        maybeSingle: () => {
          const rows = getFilteredRows();
          return Promise.resolve({ data: rows[0] || null, error: null });
        },
        insert: (vals: any | any[]) => {
          const arr = Array.isArray(vals) ? vals : [vals];
          if (!tables[tableName]) tables[tableName] = [];
          for (const item of arr) {
            tables[tableName].push({ ...item, id: item.id || `gen-${Date.now()}-${Math.random()}` });
          }
          return {
            select: () => ({
              single: () => Promise.resolve({ data: tables[tableName][tables[tableName].length - 1], error: null }),
            }),
            then: (resolve: any) => resolve({ data: arr, error: null }),
          };
        },
        update: (vals: any) => ({
          eq: (_col: string, val: any) => ({
            eq: () => ({
              select: () => ({
                single: () => Promise.resolve({ data: { ...vals, id: val }, error: null }),
              }),
            }),
          }),
        }),
        delete: () => ({
          eq: () => ({
            eq: () => Promise.resolve({ error: null }),
          }),
        }),
        then: (resolve: any) => {
          resolve({ data: getFilteredRows(), error: null });
        },
      };

      function getFilteredRows() {
        let res = (tables[tableName] || []).map((r) => ({ ...r }));
        for (const f of filters) {
          if (f.op === "eq") res = res.filter((r) => r[f.col] === f.val);
          if (f.op === "gt") res = res.filter((r) => Number(r[f.col]) > Number(f.val));
          if (f.op === "in") res = res.filter((r) => (f.val || []).includes(r[f.col]));
        }
        return res;
      }

      return builder;
    },
    rpc: (name: string, args: any) => {
      // Validar privilegios de serviceClient: usuarios autenticados normales no pueden invocar estas funciones
      if (!isServiceClient) {
        return Promise.resolve({
          data: null,
          error: { message: `permission denied for function ${name}` },
        });
      }
      if (opts.rpcHandler) {
        return opts.rpcHandler(name, args);
      }
      return Promise.resolve({ data: { success: true, ...args }, error: null });
    },
  };
}

const ORG_A = "11111111-1111-1111-1111-111111111111";

Deno.test("checklist_almacen - 1. listarDespieceOT calcula métricas y porcentajes de avance", async () => {
  const lineasFicticias = [
    {
      linea_id: "l-1",
      descripcion: "ALMA VIGA",
      fase_orden: 1,
      fase_clave: "paso_1",
      fase_nombre: "Paso 1",
      cantidad_requerida: 2,
      cantidad_entregada: 2,
      cantidad_pendiente: 0,
      cantidad_reposicion: 0,
      estado_entrega: "completo",
      orden_trabajo_id: "ot-100",
      organizacion_id: ORG_A,
    },
    {
      linea_id: "l-2",
      descripcion: "SOLERA",
      fase_orden: 2,
      fase_clave: "paso_2",
      fase_nombre: "Paso 2",
      cantidad_requerida: 4,
      cantidad_entregada: 2,
      cantidad_pendiente: 2,
      cantidad_reposicion: 1,
      estado_entrega: "parcial",
      orden_trabajo_id: "ot-100",
      organizacion_id: ORG_A,
    },
  ];

  const client = createFakeClient({
    tables: {
      v_orden_despiece_avance: lineasFicticias,
      orden_despiece_entregas: [],
      fases_despiece: [],
    },
  });

  const res = await listarDespieceOT(client, { otId: "ot-100", orgId: ORG_A });

  assertEquals(res.metricas.total_lineas, 2);
  assertEquals(res.metricas.lineas_completas, 1);
  assertEquals(res.metricas.total_piezas_requeridas, 6);
  assertEquals(res.metricas.total_piezas_entregadas, 4);
  assertEquals(res.metricas.total_piezas_pendientes, 2);
  assertEquals(res.metricas.total_piezas_reposicion, 1);
  assertEquals(res.metricas.porcentaje_avance, 67); // 4 / 6 = 66.6% -> 67%
});

Deno.test("checklist_almacen - 2. Seguridad RPC: cliente no privilegiado (userClient) es rechazado por falta de permisos", async () => {
  const userClient = createFakeClient({ isServiceClient: false });

  await assertRejects(
    async () => {
      await registrarEntrega(userClient, { orgId: ORG_A, lineaId: "l-1", cantidad: 1 });
    },
    Error,
    "permission denied"
  );
});

Deno.test("checklist_almacen - 3. registrarEntrega valida cantidades positivas y maneja errores de RPC", async () => {
  const serviceClient = createFakeClient({
    rpcHandler: (name, args) => {
      if (args.p_cantidad > 5) {
        return Promise.resolve({
          data: null,
          error: { message: "excede_requerido: La cantidad 6 excede el saldo pendiente 5" },
        });
      }
      return Promise.resolve({
        data: { success: true, entrega_id: "e-1", pendiente: 5 - args.p_cantidad },
        error: null,
      });
    },
  });

  // Cantidad <= 0 rechaza antes de RPC
  await assertRejects(
    async () => {
      await registrarEntrega(serviceClient, { orgId: ORG_A, lineaId: "l-1", cantidad: 0 });
    },
    Error,
    "mayor a 0"
  );

  // Cantidad válida llama a RPC
  const okRes = await registrarEntrega(serviceClient, { orgId: ORG_A, lineaId: "l-1", cantidad: 2 });
  assertEquals(okRes.success, true);
  assertEquals(okRes.pendiente, 3);

  // Sobre-entrega retorna el error exacto del RPC
  await assertRejects(
    async () => {
      await registrarEntrega(serviceClient, { orgId: ORG_A, lineaId: "l-1", cantidad: 6 });
    },
    Error,
    "excede_requerido"
  );
});

Deno.test("checklist_almacen - 4. generarDespieceOT: localiza presupuesto por folio PRE-*, empareja equipo por item_id y suma duplicados de forma determinista", async () => {
  const client = createFakeClient({
    tables: {
      ordenes_trabajo: [
        {
          id: "ot-1",
          cotizacion_id: "cot-10",
          modelo: "plataforma_40",
          caracteristicas: {
            item_id: "item-equipo-2",
            unidad: 2,
            modelo_id: "mod-plat-40",
          },
          organizacion_id: ORG_A,
        },
      ],
      cotizaciones: [
        {
          id: "cot-10",
          folio: "2026-0042",
          organizacion_id: ORG_A,
        },
      ],
      presupuestos: [
        {
          id: "pre-1",
          folio: "PRE-2026-0042",
          organizacion_id: ORG_A,
          datos: {
            meta: {
              cotizacion_id: "cot-10",
              bom: [
                {
                  item_id: "item-equipo-1",
                  descripcion: "CAMA BAJA",
                  lineas: [{ nombre: "PIEZA CAMA BAJA", cantidad: 1, paso: "Paso 1" }],
                },
                {
                  item_id: "item-equipo-2",
                  descripcion: "PLATAFORMA 40",
                  lineas: [
                    { material_id: "mat-1", nombre: "VIGA IPR 4X102", cantidad: 2, paso: "Paso 1" },
                    // Duplicado idéntico en otra parte de la receta (debe fusionarse a 3):
                    { material_id: "mat-1", nombre: "VIGA IPR 4X102", cantidad: 1, paso: "Paso 1" },
                    { material_id: "mat-2", nombre: "PLACA 3/8", cantidad: 4, paso: "CORTE" },
                  ],
                },
              ],
            },
          },
        },
      ],
      fases_despiece: [
        { id: "f-1", clave: "paso_1", nombre: "Corte y habilitado", organizacion_id: ORG_A },
      ],
      fases_despiece_equivalencias: [
        { paso_legacy: "CORTE", fase_id: "f-1", fases_despiece: { clave: "paso_1" }, organizacion_id: ORG_A },
      ],
      orden_despiece_lineas: [],
    },
  });

  const res = await generarDespieceOT(client, { otId: "ot-1", orgId: ORG_A });

  // 2 líneas generadas (la viga duplicada se sumó a 3, y la placa es 4)
  assertEquals(res.creadas, 2);

  const { data: lineasCreadas } = await client.from("orden_despiece_lineas").select("*");
  const viga = (lineasCreadas || []).find((l: any) => l.material_id === "mat-1");
  assert(viga, "Debe existir la viga IPR");
  assertEquals(viga.cantidad_requerida, 3); // 2 + 1 sumadas

  // Regeneración: llamar nuevamente no debe agregar duplicados ni alterar lo existente
  const res2 = await generarDespieceOT(client, { otId: "ot-1", orgId: ORG_A });
  assertEquals(res2.creadas, 0);
  assertEquals(res2.existentes, 2);
});

Deno.test("checklist_almacen - 5. ajustarCantidadRequerida invoca RPC atómica y rechaza cantidades menores a lo entregado", async () => {
  const client = createFakeClient({
    rpcHandler: (name, args) => {
      if (name === "ajustar_cantidad_despiece") {
        if (args.p_nueva_cantidad < 3) {
          return Promise.resolve({
            data: null,
            error: { message: "excede_entregado: La nueva cantidad requerida no puede ser menor a lo ya entregado (3)" },
          });
        }
        return Promise.resolve({
          data: { success: true, nueva_cantidad_requerida: args.p_nueva_cantidad },
          error: null,
        });
      }
      return Promise.resolve({ data: {}, error: null });
    },
  });

  await assertRejects(
    async () => {
      await ajustarCantidadRequerida(client, {
        orgId: ORG_A,
        lineaId: "l-1",
        nuevaCantidad: 2,
        motivo: "Reducir",
      });
    },
    Error,
    "excede_entregado"
  );

  const okAjuste = await ajustarCantidadRequerida(client, {
    orgId: ORG_A,
    lineaId: "l-1",
    nuevaCantidad: 5,
    motivo: "Se necesitan más piezas",
  });
  assertEquals(okAjuste.success, true);
  assertEquals(okAjuste.nueva_cantidad_requerida, 5);
});

Deno.test("checklist_almacen - 6. eliminarLineaManual invoca RPC atómica y rechaza partidas con historial", async () => {
  const client = createFakeClient({
    rpcHandler: (name, args) => {
      if (name === "eliminar_linea_despiece") {
        if (args.p_linea_id === "linea-con-historial") {
          return Promise.resolve({
            data: null,
            error: { message: "linea_con_historial: No se puede eliminar una partida con historial" },
          });
        }
        return Promise.resolve({
          data: { success: true, eliminada: true },
          error: null,
        });
      }
      return Promise.resolve({ data: {}, error: null });
    },
  });

  await assertRejects(
    async () => {
      await eliminarLineaManual(client, { orgId: ORG_A, lineaId: "linea-con-historial" });
    },
    Error,
    "linea_con_historial"
  );

  const resDel = await eliminarLineaManual(client, { orgId: ORG_A, lineaId: "linea-sin-historial" });
  assertEquals(resDel.success, true);
  assertEquals(resDel.eliminada, true);
});
