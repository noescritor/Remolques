// @ts-nocheck
import { assertEquals, assertRejects, assert } from "https://deno.land/std@0.192.0/testing/asserts.ts";
import {
  obtenerCatalogoAcero,
  guardarPrecioAcero,
  crearMaterialAcero,
  actualizarMaterialAcero,
  eliminarPrecioAcero,
  obtenerHistorialAcero,
} from "./acero.ts";

/**
 * Cliente falso de Supabase para pruebas unitarias de seguridad y lógica de negocio.
 */
function createFakeSupabase(initialState: {
  materiales?: any[];
  precios?: any[];
  historial?: any[];
}) {
  const state: Record<string, any[]> = {
    acero_materiales: [...(initialState.materiales || [])],
    acero_precios: [...(initialState.precios || [])],
    acero_precios_historial: [...(initialState.historial || [])],
  };

  Object.defineProperty(state, "materiales", { get: () => state.acero_materiales });
  Object.defineProperty(state, "precios", { get: () => state.acero_precios, set: (v) => { state.acero_precios = v; } });
  Object.defineProperty(state, "historial", { get: () => state.acero_precios_historial, set: (v) => { state.acero_precios_historial = v; } });

  return {
    state,
    from(table: string) {
      const currentTable = table;
      const filters: Array<{ col: string; op: string; val: any }> = [];
      let orderBy: any = null;
      let limitVal: number | null = null;
      let lastResult: any = null;
      let pendingUpdate: any = null;
      let isDelete = false;

      function getFilteredRows() {
        let rows = state[currentTable] || [];
        for (const f of filters) {
          rows = rows.filter((r: any) => {
            if (f.op === "eq") return r[f.col] === f.val;
            if (f.op === "neq") return r[f.col] !== f.val;
            if (f.op === "ilike")
              return String(r[f.col] || "").toLowerCase() === String(f.val || "").toLowerCase();
            return true;
          });
        }
        if (limitVal !== null) {
          rows = rows.slice(0, limitVal);
        }
        return rows;
      }

      function executePending() {
        if (pendingUpdate) {
          const rows = getFilteredRows();
          for (const r of rows) {
            Object.assign(r, pendingUpdate);
          }
          lastResult = rows[0] || null;
          pendingUpdate = null;
        } else if (isDelete) {
          const toDelete = getFilteredRows();
          state[currentTable] = (state[currentTable] || []).filter(
            (r: any) => !toDelete.includes(r)
          );
          lastResult = null;
          isDelete = false;
        }
      }

      const builder: any = {
        select(_fields: string = "*") {
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
        order(col: string, options?: any) {
          orderBy = { col, ascending: options?.ascending !== false };
          return builder;
        },
        limit(n: number) {
          limitVal = n;
          return builder;
        },
        async maybeSingle() {
          executePending();
          const rows = lastResult ? [lastResult] : getFilteredRows();
          return { data: rows.length > 0 ? rows[0] : null, error: null };
        },
        async single() {
          executePending();
          const rows = lastResult ? [lastResult] : getFilteredRows();
          if (rows.length === 0) return { data: null, error: new Error("Row not found") };
          return { data: rows[0], error: null };
        },
        insert(payload: any) {
          const items = Array.isArray(payload) ? payload : [payload];
          const inserted = items.map((it: any) => ({
            id: it.id || `id-${Math.random().toString(36).substring(2, 9)}`,
            created_at: new Date().toISOString(),
            ...it,
          }));
          if (!state[currentTable]) state[currentTable] = [];
          state[currentTable].push(...inserted);
          lastResult = inserted.length === 1 ? inserted[0] : inserted;
          return builder;
        },
        upsert(payload: any, _options?: any) {
          if (!state[currentTable]) state[currentTable] = [];
          const rows = state[currentTable];
          const idx = rows.findIndex(
            (r: any) =>
              r.material_id === payload.material_id && r.proveedor === payload.proveedor
          );
          let saved: any;
          if (idx >= 0) {
            saved = { ...rows[idx], ...payload };
            rows[idx] = saved;
          } else {
            saved = {
              id: payload.id || `id-${Math.random().toString(36).substring(2, 9)}`,
              ...payload,
            };
            rows.push(saved);
          }
          lastResult = saved;
          return builder;
        },
        update(payload: any) {
          pendingUpdate = payload;
          return builder;
        },
        delete() {
          isDelete = true;
          return builder;
        },
        then(resolve: any, reject?: any) {
          executePending();
          const rows = lastResult !== null ? lastResult : getFilteredRows();
          return Promise.resolve({ data: rows, error: null }).then(resolve, reject);
        },
      };

      return builder;
    },
  };
}

Deno.test("acero backend - guardarPrecioAcero: lista blanca y rechazo de org ajena", async () => {
  const fakeDb = createFakeSupabase({
    materiales: [
      { id: "mat-1", organizacion_id: "org-propia", nombre: "Placa 4X10'", tipo: "placa", activo: true },
      { id: "mat-ajeno", organizacion_id: "org-ajena", nombre: "Placa Ajena", tipo: "placa", activo: true },
    ],
    precios: [],
    historial: [],
  });

  // 1. Material de org ajena -> 404
  await assertRejects(
    async () => {
      await guardarPrecioAcero(fakeDb, "org-propia", "usr-1", {
        material_id: "mat-ajeno",
        proveedor: "FORTACERO",
        precio: 1500,
      });
    },
    Error,
    "Material no encontrado"
  );

  // 2. Precio <= 0 -> 400
  await assertRejects(
    async () => {
      await guardarPrecioAcero(fakeDb, "org-propia", "usr-1", {
        material_id: "mat-1",
        proveedor: "FORTACERO",
        precio: -10,
      });
    },
    Error,
    "precio debe ser un número mayor a cero"
  );

  // 3. Inserción correcta con campos maliciosos ignorados
  const res = await guardarPrecioAcero(fakeDb, "org-propia", "usr-1", {
    material_id: "mat-1",
    proveedor: "FORTACERO",
    precio: 2500,
    organizacion_id: "org-hackeada", // debe ser ignorado
    id: "id-forzado", // debe ser ignorado
  });

  assertEquals(res.organizacion_id, "org-propia");
  assertEquals(res.precio, 2500);
  assertEquals(res.proveedor, "FORTACERO");

  // El historial debe tener 1 registro
  assertEquals(fakeDb.state.historial.length, 1);
  assertEquals(fakeDb.state.historial[0].precio_nuevo, 2500);
  assertEquals(fakeDb.state.historial[0].precio_anterior, null);

  // 4. Guardar el MISMO precio -> NO debe generar nueva fila en historial
  await guardarPrecioAcero(fakeDb, "org-propia", "usr-1", {
    material_id: "mat-1",
    proveedor: "FORTACERO",
    precio: 2500,
  });
  assertEquals(fakeDb.state.historial.length, 1);

  // 5. Guardar precio distinto -> SÍ genera fila en historial
  await guardarPrecioAcero(fakeDb, "org-propia", "usr-1", {
    material_id: "mat-1",
    proveedor: "FORTACERO",
    precio: 3000,
  });
  assertEquals(fakeDb.state.historial.length, 2);
  assertEquals(fakeDb.state.historial[1].precio_anterior, 2500);
  assertEquals(fakeDb.state.historial[1].precio_nuevo, 3000);
});

Deno.test("acero backend - crearMaterialAcero: deriva medidas, valida unicidad y lista blanca", async () => {
  const fakeDb = createFakeSupabase({
    materiales: [
      { id: "mat-1", organizacion_id: "org-1", nombre: "Solera 1/2 X 3\"", tipo: "solera", activo: true },
    ],
  });

  // 1. Nombre duplicado en la misma org -> 409
  await assertRejects(
    async () => {
      await crearMaterialAcero(fakeDb, "org-1", {
        nombre: "Solera 1/2 X 3\"",
      });
    },
    Error,
    "Ya existe un material con este nombre"
  );

  // 2. Creación con derivación de medidas
  const creado = await crearMaterialAcero(fakeDb, "org-1", {
    nombre: "Placa de grado A-36 de 1/4\" en 5X20'",
    ancho_ft: 999, // Debe ser ignorado
    largo_ft: 999, // Debe ser ignorado
    organizacion_id: "org-otra", // Debe ser ignorado
  });

  assertEquals(creado.organizacion_id, "org-1");
  assertEquals(creado.tipo, "placa");
  assertEquals(creado.ancho_ft, 5);
  assertEquals(creado.largo_ft, 20);
  assertEquals(creado.activo, true);
});

Deno.test("acero backend - actualizarMaterialAcero: valida unicidad, rechaza org ajena", async () => {
  const fakeDb = createFakeSupabase({
    materiales: [
      { id: "mat-1", organizacion_id: "org-1", nombre: "Solera 1/2 X 3\"", tipo: "solera", activo: true },
      { id: "mat-2", organizacion_id: "org-1", nombre: "PTR de 2X4\" Cal. 7", tipo: "ptr", activo: true },
      { id: "mat-ajeno", organizacion_id: "org-ajena", nombre: "Placa Ajena", tipo: "placa", activo: true },
    ],
  });

  // 1. Org ajena -> 404
  await assertRejects(
    async () => {
      await actualizarMaterialAcero(fakeDb, "org-1", "mat-ajeno", {
        activo: false,
      });
    },
    Error,
    "Material no encontrado"
  );

  // 2. Renombrar a un nombre que ya existe -> 409
  await assertRejects(
    async () => {
      await actualizarMaterialAcero(fakeDb, "org-1", "mat-1", {
        nombre: "PTR de 2X4\" Cal. 7",
      });
    },
    Error,
    "Ya existe un material con este nombre"
  );

  // 3. Desactivar material válido
  const actualizado = await actualizarMaterialAcero(fakeDb, "org-1", "mat-1", {
    activo: false,
    notas: "Descontinuado",
  });
  assertEquals(actualizado.activo, false);
  assertEquals(actualizado.notas, "Descontinuado");
});

Deno.test("acero backend - eliminarPrecioAcero: escribe historial y elimina", async () => {
  const fakeDb = createFakeSupabase({
    materiales: [
      { id: "mat-1", organizacion_id: "org-1", nombre: "Placa 4X10'", tipo: "placa", activo: true },
    ],
    precios: [
      { id: "p-1", organizacion_id: "org-1", material_id: "mat-1", proveedor: "FORTACERO", precio: 2000 },
    ],
    historial: [],
  });

  const res = await eliminarPrecioAcero(fakeDb, "org-1", "usr-1", "mat-1", "FORTACERO");
  assertEquals(res.ok, true);
  assertEquals(res.deleted, true);

  // Debe haberse eliminado de precios
  assertEquals(fakeDb.state.precios.length, 0);

  // Debe haberse registrado en historial con precio_nuevo = 0
  assertEquals(fakeDb.state.historial.length, 1);
  assertEquals(fakeDb.state.historial[0].precio_anterior, 2000);
  assertEquals(fakeDb.state.historial[0].precio_nuevo, 0);
});
