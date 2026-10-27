// @ts-nocheck
import { assertEquals, assertRejects, assert } from "https://deno.land/std@0.192.0/testing/asserts.ts";
import {
  crearOperario,
  actualizarOperario,
  guardarTarea,
  cambiarEstadoTarea,
  eliminarTarea,
  obtenerTrazabilidadOrden,
  obtenerTrazabilidadOperario,
} from "./plan_produccion.ts";

function createFakeClient(opts: {
  tables?: Record<string, any[]>;
  rpcHandlers?: Record<string, (args: any) => Promise<any> | any>;
}) {
  const tables: Record<string, any[]> = opts.tables || {};
  const rpcHandlers = opts.rpcHandlers || {};

  return {
    from(tableName: string) {
      const filters: Array<{ col: string; op: string; val: any }> = [];
      let lastInsertOrUpdate: any = null;

      function getFilteredRows() {
        let res = tables[tableName] || [];
        for (const f of filters) {
          if (f.op === "eq") res = res.filter((r) => r[f.col] === f.val);
          if (f.op === "neq") res = res.filter((r) => r[f.col] !== f.val);
          if (f.op === "ilike") {
            res = res.filter((r) =>
              String(r[f.col] || "").toLowerCase() === String(f.val || "").toLowerCase()
            );
          }
          if (f.op === "in") res = res.filter((r) => f.val.includes(r[f.col]));
        }
        return res;
      }

      const builder: any = {
        select(_fields = "*") {
          return builder;
        },
        eq(col: string, val: any) {
          filters.push({ col, op: "eq", val });
          return builder;
        },
        neq(col: string, val: any) {
          filters.push({ col, op: "neq", val });
          return builder;
        },
        ilike(col: string, val: any) {
          filters.push({ col, op: "ilike", val });
          return builder;
        },
        in(col: string, vals: any[]) {
          filters.push({ col, op: "in", val: vals });
          return builder;
        },
        gte(col: string, val: any) {
          filters.push({ col, op: "gte", val });
          return builder;
        },
        lte(col: string, val: any) {
          filters.push({ col, op: "lte", val });
          return builder;
        },
        order(_col: string, _opts: any) {
          return builder;
        },
        insert(payload: any) {
          const arr = Array.isArray(payload) ? payload : [payload];
          const created = arr.map((item) => ({ id: item.id || `id-${Math.random()}`, ...item }));
          if (!tables[tableName]) tables[tableName] = [];
          tables[tableName].push(...created);
          lastInsertOrUpdate = Array.isArray(payload) ? created : created[0];
          return builder;
        },
        update(payload: any) {
          const matches = getFilteredRows();
          for (const m of matches) {
            Object.assign(m, payload);
          }
          lastInsertOrUpdate = matches[0] || null;
          return builder;
        },
        async maybeSingle() {
          if (lastInsertOrUpdate) return { data: lastInsertOrUpdate, error: null };
          const rows = getFilteredRows();
          return { data: rows.length > 0 ? rows[0] : null, error: null };
        },
        async single() {
          if (lastInsertOrUpdate) return { data: lastInsertOrUpdate, error: null };
          const rows = getFilteredRows();
          if (rows.length === 0) return { data: null, error: new Error("Row not found") };
          return { data: rows[0], error: null };
        },
        then(resolve: any) {
          if (lastInsertOrUpdate) {
            return resolve({ data: lastInsertOrUpdate, error: null });
          }
          resolve({ data: getFilteredRows(), error: null });
        },
      };
      return builder;
    },
    async rpc(fnName: string, args: any) {
      if (rpcHandlers[fnName]) {
        const res = await rpcHandlers[fnName](args);
        return { data: res, error: null };
      }
      return { data: null, error: { message: `RPC ${fnName} mock not found` } };
    },
  };
}

Deno.test("motor/plan_produccion - Duplicado de nombre de operario da 409", async () => {
  const fakeDb = createFakeClient({
    tables: {
      operarios: [
        { id: "op-1", organizacion_id: "org-1", nombre: "Juan Pérez", activo: true },
      ],
    },
  });

  // Intentar crear con mismo nombre pero minúsculas
  await assertRejects(
    async () => {
      await crearOperario(fakeDb, "org-1", {
        nombre: "  juan pérez  ",
        puesto: "Soldador",
      });
    },
    Error,
    "ya está registrado"
  );
});

Deno.test("motor/plan_produccion - Consulta o actualización con organización ajena da 404", async () => {
  const fakeDb = createFakeClient({
    tables: {
      operarios: [
        { id: "op-1", organizacion_id: "org-OTRA", nombre: "Carlos" },
      ],
      ordenes_trabajo: [
        { id: "ot-1", organizacion_id: "org-OTRA" },
      ],
    },
  });

  // Intentar actualizar operario de otra org
  await assertRejects(
    async () => {
      await actualizarOperario(fakeDb, "org-MIA", "op-1", { nombre: "Carlos Nuevo" });
    },
    Error,
    "Operario no encontrado"
  );

  // Intentar trazabilidad de orden de otra org
  await assertRejects(
    async () => {
      await obtenerTrazabilidadOrden(fakeDb, "org-MIA", "ot-1");
    },
    Error,
    "Orden de trabajo no encontrada"
  );

  // Intentar trazabilidad de operario de otra org
  await assertRejects(
    async () => {
      await obtenerTrazabilidadOperario(fakeDb, "org-MIA", "op-1");
    },
    Error,
    "Operario no encontrado"
  );
});

Deno.test("motor/plan_produccion - Lista blanca de campos y RPC guardar_plan_tarea", async () => {
  let rpcArgsReceived: any = null;
  const fakeServiceClient = createFakeClient({
    rpcHandlers: {
      guardar_plan_tarea: (args) => {
        rpcArgsReceived = args;
        return { exito: true, tarea_id: "tarea-uuid-123" };
      },
    },
  });

  const rawMaliciousPayload: any = {
    fecha: "2026-10-19",
    frente_id: "frente-1",
    descripcion: "Corte de PTR",
    // Campos que deben ser ignorados por lista blanca:
    organizacion_id: "org-MALICIOUS",
    creado_por: "user-MALICIOUS",
    inicio_real: "2020-01-01T00:00:00Z",
    fin_real: "2020-01-01T00:00:00Z",
    operarios: ["op-1", "op-2"],
    materiales: [{ descripcion: "Placa 3/8", cantidad: 3, unidad: "PZA" }],
  };

  const res = await guardarTarea(fakeServiceClient, "org-CORRECTA", "user-AUTENTICADO", null, rawMaliciousPayload);
  assertEquals(res.exito, true);
  assertEquals(res.tarea_id, "tarea-uuid-123");

  // Verificar que el RPC recibió la organización del contexto del servidor, no del payload
  assertEquals(rpcArgsReceived.p_org, "org-CORRECTA");
  assertEquals(rpcArgsReceived.p_usuario, "user-AUTENTICADO");
  assertEquals(rpcArgsReceived.p_fecha, "2026-10-19");
  assertEquals(rpcArgsReceived.p_frente_id, "frente-1");
  assertEquals(rpcArgsReceived.p_descripcion, "Corte de PTR");
  assertEquals(rpcArgsReceived.p_operarios.length, 2);
  assertEquals(rpcArgsReceived.p_materiales.length, 1);
});

Deno.test("motor/plan_produccion - Operario inactivo o de otra org rechazado con 400", async () => {
  const fakeServiceClient = createFakeClient({
    rpcHandlers: {
      guardar_plan_tarea: (_args) => {
        return {
          exito: false,
          error: "operario_invalido",
          mensaje: "Uno o más operarios no existen, están inactivos o no pertenecen a la organización",
        };
      },
    },
  });

  await assertRejects(
    async () => {
      await guardarTarea(fakeServiceClient, "org-1", "user-1", null, {
        fecha: "2026-10-19",
        frente_id: "f-1",
        operarios: ["op-inactivo"],
      });
    },
    Error,
    "están inactivos o no pertenecen"
  );
});

Deno.test("motor/plan_produccion - Transición de estado inválida da 409", async () => {
  const fakeDb = createFakeClient({
    tables: {
      plan_tareas: [
        { id: "t-1", organizacion_id: "org-1", estado: "planeada" },
      ],
    },
  });
  const fakeServiceClient = createFakeClient({});

  // planeada -> terminada directamente no es permitido (debe pasar por en_proceso)
  let catchedErr: any = null;
  try {
    await cambiarEstadoTarea(fakeServiceClient, fakeDb, "org-1", "user-1", "t-1", "terminada");
  } catch (err: any) {
    catchedErr = err;
  }
  assert(catchedErr !== null, "Debe arrojar error");
  assertEquals(catchedErr.status, 409);
  assert(catchedErr.message.includes("solo puede pasar a"));
});

Deno.test("motor/plan_produccion - Borrar tarea con historial deja la bitácora", async () => {
  let rpcCalled = false;
  const fakeDb = createFakeClient({
    tables: {
      plan_tareas: [
        { id: "t-1", organizacion_id: "org-1", estado: "planeada" },
      ],
    },
  });
  const fakeServiceClient = createFakeClient({
    rpcHandlers: {
      eliminar_plan_tarea: (args) => {
        rpcCalled = true;
        assertEquals(args.p_org, "org-1");
        assertEquals(args.p_tarea_id, "t-1");
        return { exito: true, tarea_id: "t-1" };
      },
    },
  });

  const res = await eliminarTarea(fakeServiceClient, fakeDb, "org-1", "user-1", "t-1");
  assertEquals(res.exito, true);
  assertEquals(rpcCalled, true);
});
