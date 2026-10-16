import { assertEquals, assert, assertRejects } from "https://deno.land/std@0.192.0/testing/asserts.ts";
import {
  verificarPermisoEdicion,
  guardarOpcionCosto,
  obtenerResumenCatalogo,
  guardarKitCosto,
  guardarProcesoManufactura,
  guardarParametrosCosteo
} from "./catalogo_costos.ts";

function createMockSupabase(initialData: {
  perfiles_organizacion?: any[];
  grupos_configuracion?: any[];
  opciones_configuracion?: any[];
  opcion_costos?: any[];
  opcion_componentes?: any[];
  productos?: any[];
  modelos?: any[];
  costos_modelo?: any[];
  procesos_manufactura?: any[];
  parametros_costeo?: any[];
  costos_historial?: any[];
}) {
  const state: Record<string, any[]> = {
    perfiles_organizacion: [...(initialData.perfiles_organizacion || [])],
    grupos_configuracion: [...(initialData.grupos_configuracion || [])],
    opciones_configuracion: [...(initialData.opciones_configuracion || [])],
    opcion_costos: [...(initialData.opcion_costos || [])],
    opcion_componentes: [...(initialData.opcion_componentes || [])],
    productos: [...(initialData.productos || [])],
    modelos: [...(initialData.modelos || [])],
    costos_modelo: [...(initialData.costos_modelo || [])],
    procesos_manufactura: [...(initialData.procesos_manufactura || [])],
    parametros_costeo: [...(initialData.parametros_costeo || [])],
    costos_historial: [...(initialData.costos_historial || [])]
  };

  const client = {
    _state: state,
    from(tableName: string) {
      let filters: ((item: any) => boolean)[] = [];
      let sortFn: ((a: any, b: any) => number) | null = null;
      let limitCount: number | null = null;

      const builder: any = {
        select(_fields?: string) {
          return builder;
        },
        eq(field: string, value: any) {
          filters.push((item: any) => item[field] === value);
          return builder;
        },
        order(field: string, { ascending }: { ascending: boolean }) {
          sortFn = (a: any, b: any) => {
            if (a[field] < b[field]) return ascending ? -1 : 1;
            if (a[field] > b[field]) return ascending ? 1 : -1;
            return 0;
          };
          return builder;
        },
        limit(n: number) {
          limitCount = n;
          return builder;
        },
        async maybeSingle() {
          let list = (state[tableName] || []).filter(item => filters.every(f => f(item)));
          if (list.length === 0) return { data: null, error: null };
          return { data: list[0], error: null };
        },
        async single() {
          let list = (state[tableName] || []).filter(item => filters.every(f => f(item)));
          if (list.length === 0) return { data: null, error: new Error("Row not found") };
          return { data: list[0], error: null };
        },
        async then(resolve: any, _reject: any) {
          let list = (state[tableName] || []).filter(item => filters.every(f => f(item)));
          if (sortFn) list.sort(sortFn);
          if (limitCount !== null) list = list.slice(0, limitCount);
          return resolve({ data: list, error: null });
        },
        insert(items: any[]) {
          const inserted = items.map(it => {
            const row = { id: it.id || `id-${Date.now()}-${Math.random()}`, ...it };
            if (!state[tableName]) state[tableName] = [];
            state[tableName].push(row);
            return row;
          });
          return {
            select() {
              return {
                async single() {
                  return { data: inserted[0], error: null };
                }
              };
            },
            async then(resolve: any) {
              return resolve({ data: inserted, error: null });
            }
          };
        },
        update(updates: any) {
          return {
            eq(field: string, value: any) {
              filters.push((item: any) => item[field] === value);
              return {
                select() {
                  return {
                    async single() {
                      const list = (state[tableName] || []).filter(item => filters.every(f => f(item)));
                      if (list.length === 0) return { data: null, error: new Error("Row not found to update") };
                      Object.assign(list[0], updates);
                      return { data: list[0], error: null };
                    }
                  };
                },
                async then(resolve: any) {
                  const list = (state[tableName] || []).filter(item => filters.every(f => f(item)));
                  for (const it of list) Object.assign(it, updates);
                  return resolve({ data: list, error: null });
                }
              };
            }
          };
        }
      };

      return builder;
    }
  };

  return client;
}

Deno.test("Catálogo Costos - verificación de permisos: solo propietario o admin tienen permiso", async () => {
  const mockClient = createMockSupabase({
    perfiles_organizacion: [
      { usuario_id: "u-admin", organizacion_id: "org-1", rol: "admin" },
      { usuario_id: "u-prop", organizacion_id: "org-1", rol: "propietario" },
      { usuario_id: "u-user", organizacion_id: "org-1", rol: "usuario" }
    ]
  });

  const canAdmin = await verificarPermisoEdicion(mockClient, "org-1", "u-admin");
  assertEquals(canAdmin, true);

  const canProp = await verificarPermisoEdicion(mockClient, "org-1", "u-prop");
  assertEquals(canProp, true);

  const canUser = await verificarPermisoEdicion(mockClient, "org-1", "u-user");
  assertEquals(canUser, false);

  const canUnknown = await verificarPermisoEdicion(mockClient, "org-1", "u-inexistente");
  assertEquals(canUnknown, false);
});

Deno.test("Catálogo Costos - validaciones: rechaza números negativos, escalas inválidas y productos inexistentes", async () => {
  const mockClient = createMockSupabase({
    productos: [
      { id: "p-1", organizacion_id: "org-1", nombre: "LLANTAS CEREX", costo: 3586 }
    ]
  });

  // Escala inválida
  await assertRejects(
    async () => {
      await guardarOpcionCosto(mockClient, "org-1", "u-1", "opt-1", {
        tipo_modelo: "plataforma",
        cantidad_base: 1,
        escala: "invalida",
        costo_unitario: 100
      });
    },
    Error,
    "escala inválida"
  );

  // Cantidad base <= 0
  await assertRejects(
    async () => {
      await guardarOpcionCosto(mockClient, "org-1", "u-1", "opt-1", {
        tipo_modelo: "plataforma",
        cantidad_base: 0,
        escala: "fija",
        costo_unitario: 100
      });
    },
    Error,
    "cantidad_base debe ser un número finito mayor a 0"
  );

  // Costo unitario negativo
  await assertRejects(
    async () => {
      await guardarOpcionCosto(mockClient, "org-1", "u-1", "opt-1", {
        tipo_modelo: "plataforma",
        cantidad_base: 1,
        escala: "fija",
        costo_unitario: -50
      });
    },
    Error,
    "costo_unitario debe ser un número finito mayor o igual a 0"
  );

  // Producto inexistente
  await assertRejects(
    async () => {
      await guardarOpcionCosto(mockClient, "org-1", "u-1", "opt-1", {
        tipo_modelo: "plataforma",
        cantidad_base: 1,
        escala: "fija",
        costo_unitario: 100,
        producto_id: "prod-fantasma"
      });
    },
    Error,
    "El producto ligado no existe en la organización"
  );
});

Deno.test("Catálogo Costos - historial registra una fila por cada campo cambiado", async () => {
  const mockClient = createMockSupabase({
    opcion_costos: [
      {
        id: "oc-1",
        organizacion_id: "org-1",
        opcion_id: "opt-1",
        tipo_modelo: "plataforma",
        cantidad_base: 1,
        escala: "fija",
        costo_unitario: 1000,
        fuente: "Factura Leolca",
        costo_desde_producto: false
      }
    ],
    opciones_configuracion: [
      { id: "opt-1", organizacion_id: "org-1", clave: "cerex", nombre: "Cerex", grupo_id: "g-1" }
    ],
    grupos_configuracion: [
      { id: "g-1", clave: "llantas", nombre: "Llantas" }
    ]
  });

  // Cambiamos costo_unitario y escala
  const res = await guardarOpcionCosto(mockClient, "org-1", "u-admin", "opt-1", {
    tipo_modelo: "plataforma",
    cantidad_base: 1,
    escala: "por_eje",
    costo_unitario: 1500
  });

  assertEquals(res.opcion_costo.costo_unitario, 1500);
  assertEquals(res.opcion_costo.escala, "por_eje");
  assertEquals(res.opcion_costo.fuente, "Manual (usuario)");

  // En el historial debe haber registros para costo_unitario, escala y fuente
  const historial = mockClient._state.costos_historial;
  assert(historial.length >= 3);

  const histCosto = historial.find((h: any) => h.campo === "costo_unitario");
  assert(histCosto);
  assertEquals(histCosto.valor_anterior, "1000");
  assertEquals(histCosto.valor_nuevo, "1500");
  assertEquals(histCosto.usuario_id, "u-admin");

  const histEscala = historial.find((h: any) => h.campo === "escala");
  assert(histEscala);
  assertEquals(histEscala.valor_anterior, "fija");
  assertEquals(histEscala.valor_nuevo, "por_eje");

  const histFuente = historial.find((h: any) => h.campo === "fuente");
  assert(histFuente);
  assertEquals(histFuente.valor_anterior, "Factura Leolca");
  assertEquals(histFuente.valor_nuevo, "Manual (usuario)");
});

Deno.test("Catálogo Costos - confirmar sin cambiar números cambia fuente a 'Manual (usuario)' y registra historial", async () => {
  const mockClient = createMockSupabase({
    opcion_costos: [
      {
        id: "oc-2",
        organizacion_id: "org-1",
        opcion_id: "opt-2",
        tipo_modelo: "dolly",
        cantidad_base: 2,
        escala: "fija",
        costo_unitario: 500,
        fuente: "Tarifario"
      }
    ],
    opciones_configuracion: [
      { id: "opt-2", organizacion_id: "org-1", clave: "opt_prueba", nombre: "Opción Prueba" }
    ]
  });

  const res = await guardarOpcionCosto(mockClient, "org-1", "u-prop", "opt-2", {
    tipo_modelo: "dolly",
    cantidad_base: 2,
    escala: "fija",
    costo_unitario: 500,
    confirmar: true
  });

  assertEquals(res.opcion_costo.fuente, "Manual (usuario)");

  const historial = mockClient._state.costos_historial;
  const histFuente = historial.find((h: any) => h.campo === "fuente");
  assert(histFuente);
  assertEquals(histFuente.valor_anterior, "Tarifario");
  assertEquals(histFuente.valor_nuevo, "Manual (usuario)");
});

Deno.test("Catálogo Costos - crear fila nueva si no existe la opción para ese tipo", async () => {
  const mockClient = createMockSupabase({
    opcion_costos: [],
    opciones_configuracion: [
      { id: "opt-nueva", organizacion_id: "org-1", clave: "nueva", nombre: "Opción Nueva" }
    ]
  });

  const res = await guardarOpcionCosto(mockClient, "org-1", "u-admin", "opt-nueva", {
    tipo_modelo: "gondola",
    cantidad_base: 1,
    escala: "fija",
    costo_unitario: 2500
  });

  assertEquals(res.opcion_costo.opcion_id, "opt-nueva");
  assertEquals(res.opcion_costo.costo_unitario, 2500);
  assertEquals(res.opcion_costo.fuente, "Manual (usuario)");
  assertEquals(res.opcion_costo.notas, "import-2r7");

  const historial = mockClient._state.costos_historial;
  const histCreacion = historial.find((h: any) => h.campo === "creacion");
  assert(histCreacion);
});

Deno.test("Catálogo Costos - editar una opción para plataforma NO afecta a dolly ni gondola", async () => {
  const mockClient = createMockSupabase({
    opcion_costos: [
      {
        id: "oc-plat",
        organizacion_id: "org-1",
        opcion_id: "opt-compartida",
        tipo_modelo: "plataforma",
        cantidad_base: 1,
        escala: "fija",
        costo_unitario: 1000,
        fuente: "Factura Leolca"
      },
      {
        id: "oc-dolly",
        organizacion_id: "org-1",
        opcion_id: "opt-compartida",
        tipo_modelo: "dolly",
        cantidad_base: 1,
        escala: "fija",
        costo_unitario: 1000,
        fuente: "Factura Leolca"
      }
    ],
    opciones_configuracion: [
      { id: "opt-compartida", organizacion_id: "org-1", clave: "compartida", nombre: "Compartida" }
    ]
  });

  // Editamos solo la de plataforma
  await guardarOpcionCosto(mockClient, "org-1", "u-admin", "opt-compartida", {
    tipo_modelo: "plataforma",
    cantidad_base: 1,
    escala: "fija",
    costo_unitario: 1800
  });

  const plat = mockClient._state.opcion_costos.find((o: any) => o.tipo_modelo === "plataforma");
  const dolly = mockClient._state.opcion_costos.find((o: any) => o.tipo_modelo === "dolly");

  assertEquals(plat.costo_unitario, 1800);
  assertEquals(dolly.costo_unitario, 1000);
  assertEquals(dolly.fuente, "Factura Leolca");
});

Deno.test("Catálogo Costos - seguridad: opción de OTRA organización devuelve error y no inserta fila ni historial", async () => {
  const mockClient = createMockSupabase({
    opciones_configuracion: [
      { id: "opt-otra-org", organizacion_id: "org-2", clave: "cerex", nombre: "Cerex" }
    ],
    opcion_costos: [],
    costos_historial: []
  });

  await assertRejects(
    async () => {
      await guardarOpcionCosto(mockClient, "org-1", "u-admin", "opt-otra-org", {
        tipo_modelo: "plataforma",
        cantidad_base: 1,
        escala: "fija",
        costo_unitario: 1000
      });
    },
    Error,
    "La opción no existe en la organización"
  );

  assertEquals(mockClient._state.opcion_costos.length, 0);
  assertEquals(mockClient._state.costos_historial.length, 0);
});

Deno.test("Catálogo Costos - kits y procesos: validaciones y guardado con historial", async () => {
  const mockClient = createMockSupabase({
    costos_modelo: [
      { id: "kit-1", modelo_id: "mod-1", organizacion_id: "org-1", concepto: "Pernos", cantidad: 2, costo_unitario: 500 }
    ],
    procesos_manufactura: [
      { id: "proc-1", modelo_id: "mod-1", organizacion_id: "org-1", proceso: "Soldadura", subproceso: "Chasis", minutos: 120, tarifa_hora: 250 }
    ]
  });

  // Actualizar kit
  const resKit = await guardarKitCosto(mockClient, "org-1", "u-admin", "mod-1", "kit-1", {
    cantidad: 4,
    costo_unitario: 550
  });
  assertEquals(resKit.kit.cantidad, 4);
  assertEquals(resKit.kit.costo_unitario, 550);

  // Actualizar proceso
  const resProc = await guardarProcesoManufactura(mockClient, "org-1", "u-admin", "proc-1", {
    minutos: 150,
    tarifa_hora: 280
  });
  assertEquals(resProc.proceso.minutos, 150);
  assertEquals(resProc.proceso.tarifa_hora, 280);

  const historial = mockClient._state.costos_historial;
  assert(historial.some((h: any) => h.tabla === "costos_modelo" && h.campo === "costo_unitario"));
  assert(historial.some((h: any) => h.tabla === "procesos_manufactura" && h.campo === "minutos"));
});
