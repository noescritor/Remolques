import { assertEquals, assert } from "https://deno.land/std@0.192.0/testing/asserts.ts";
import { generarPresupuestoDeCotizacion, ejecutarAprobacionCotizacion } from "./generar_presupuesto_cotizacion.ts";

function createMockSupabase(opciones: {
  cotizacionExiste?: boolean;
  itemsValidos?: boolean;
  presupuestoPrevio?: any;
}) {
  const eventos: any[] = [];
  const presupuestosEnDb: any[] = opciones.presupuestoPrevio ? [opciones.presupuestoPrevio] : [];

  const mock = {
    eventos,
    presupuestosEnDb,
    from: (table: string) => {
      if (table === "cotizaciones") {
        return {
          select: () => ({
            eq: (_col1: string, val1: string) => ({
              eq: (_col2: string, _val2: string) => ({
                single: () => {
                  if (opciones.cotizacionExiste === false) {
                    return Promise.resolve({ data: null, error: { message: "No encontrada" } });
                  }
                  return Promise.resolve({
                    data: {
                      id: val1,
                      folio: "COT-2026-0099",
                      cliente_id: "cli-abc",
                      organizacion_id: "org-xyz",
                      descripcion: "Cotización de prueba",
                      total: 250000
                    },
                    error: null
                  });
                }
              })
            })
          }),
          update: (_payload: any) => ({
            eq: () => Promise.resolve({ error: null })
          })
        };
      }

      if (table === "items_cotizacion") {
        return {
          select: () => ({
            eq: () => {
              if (opciones.itemsValidos === false) {
                return Promise.resolve({
                  data: [
                    {
                      id: "item-invalido",
                      producto_id: "prod-serv",
                      cantidad: 1,
                      descripcion: "Flete o servicio no configurable",
                      metadata: {},
                      producto: { tipo_item: "servicio", nombre: "Flete" }
                    }
                  ],
                  error: null
                });
              }
              return Promise.resolve({
                data: [
                  {
                    id: "item-1",
                    producto_id: "mod-plat",
                    cantidad: 1,
                    descripcion: "Plataforma 40 ft 2 ejes",
                    metadata: {
                      configuracion: {
                        modelo_id: "mod-plat",
                        grupos: {
                          suspension: "fleet_master",
                          eje: "fleet_master",
                          patin: "hj",
                          piso: "laminado_plastico",
                          abs: "2e_sin_retractil"
                        },
                        ajustes: []
                      }
                    },
                    producto: { tipo_item: "producto_terminado", nombre: "Plataforma 40 ft" }
                  }
                ],
                error: null
              });
            }
          })
        };
      }

      if (table === "modelos") {
        return {
          select: () => ({
            eq: (_col: string, val: string) => ({
              single: () => Promise.resolve({
                data: {
                  id: val,
                  tipo: "plataforma",
                  largo_ft: 40,
                  num_ejes: 2,
                  costos_derivados_de: null,
                  productos: { nombre: "Plataforma 40" }
                },
                error: null
              }),
              maybeSingle: () => Promise.resolve({ data: null, error: null })
            })
          })
        };
      }

      if (table === "receta_base") {
        return {
          select: () => ({
            eq: () => ({
              eq: () => Promise.resolve({
                data: [
                  {
                    material_id: "mat-acero-1",
                    cantidad: 2,
                    escala: "fija",
                    paso: ["PASO 1"],
                    uso: ["CHASIS"],
                    seccion: "acero",
                    productos: { nombre: "VIGA PRINCIPAL", unidad: "PZA", costo: 5000, descripcion: "Viga" }
                  }
                ]
              }),
              then: (resolve: any) => resolve({
                data: [
                  {
                    material_id: "mat-acero-1",
                    cantidad: 2,
                    escala: "fija",
                    paso: ["PASO 1"],
                    uso: ["CHASIS"],
                    seccion: "acero",
                    productos: { nombre: "VIGA PRINCIPAL", unidad: "PZA", costo: 5000, descripcion: "Viga" }
                  }
                ]
              })
            })
          })
        };
      }

      if (table === "costos_modelo") {
        return {
          select: () => ({
            eq: () => Promise.resolve({
              data: [
                { seccion: "pintura", concepto: "Pintura general", cantidad: 1, costo_unitario: 5000, escala: "fija" }
              ]
            })
          })
        };
      }

      if (table === "procesos_manufactura") {
        return {
          select: () => ({
            eq: () => ({
              order: () => Promise.resolve({
                data: [
                  { orden: 1, proceso: "Armado", subproceso: "Chasis", minutos: 60, tarifa_hora: 300 }
                ]
              })
            })
          })
        };
      }

      if (table === "grupos_configuracion") {
        return {
          select: () => Promise.resolve({
            data: [
              { id: "grp-susp", clave: "suspension", nombre: "Suspensión", seleccion: "unica", regla: "opcional", aplica_a: "plataforma", depende_de: null, cantidad: 2, unidad_precio: null, medidas: null },
              { id: "grp-eje", clave: "eje", nombre: "Ejes", seleccion: "unica", regla: "opcional", aplica_a: "plataforma", depende_de: null, cantidad: 2, unidad_precio: null, medidas: null },
              { id: "grp-patin", clave: "patin", nombre: "Patín", seleccion: "unica", regla: "opcional", aplica_a: "plataforma", depende_de: null, cantidad: 2, unidad_precio: null, medidas: null },
              { id: "grp-piso", clave: "piso", nombre: "Piso", seleccion: "unica", regla: "opcional", aplica_a: "plataforma", depende_de: null, cantidad: 1, unidad_precio: null, medidas: null },
              { id: "grp-abs", clave: "abs", nombre: "ABS", seleccion: "unica", regla: "opcional", aplica_a: "plataforma", depende_de: null, cantidad: 1, unidad_precio: null, medidas: null }
            ]
          })
        };
      }

      if (table === "opciones_configuracion") {
        return {
          select: () => Promise.resolve({
            data: [
              { id: "opc-susp", grupo_id: "grp-susp", clave: "fleet_master", nombre: "Fleet Master", activo: true },
              { id: "opc-eje", grupo_id: "grp-eje", clave: "fleet_master", nombre: "Fleet Master", activo: true },
              { id: "opc-patin", grupo_id: "grp-patin", clave: "hj", nombre: "HJ", activo: true },
              { id: "opc-piso", grupo_id: "grp-piso", clave: "laminado_plastico", nombre: "Laminado Plástico", activo: true },
              { id: "opc-abs", grupo_id: "grp-abs", clave: "2e_sin_retractil", nombre: "2E Sin Retráctil", activo: true }
            ]
          })
        };
      }

      if (table === "opcion_costos") {
        return {
          select: () => ({
            eq: () => Promise.resolve({
              data: [
                { grupo_clave: "suspension", opcion_clave: "fleet_master", cantidad_base: 2, escala: "fija", costo_unitario: 15000, fuente: "Factura" },
                { grupo_clave: "eje", opcion_clave: "fleet_master", cantidad_base: 2, escala: "fija", costo_unitario: 12000, fuente: "Factura" },
                { grupo_clave: "patin", opcion_clave: "hj", cantidad_base: 2, escala: "fija", costo_unitario: 5000, fuente: "Factura" },
                { grupo_clave: "piso", opcion_clave: "laminado_plastico", cantidad_base: 1, escala: "por_largo", costo_unitario: 400, fuente: "Factura" },
                { grupo_clave: "abs", opcion_clave: "2e_sin_retractil", cantidad_base: 1, escala: "fija", costo_unitario: 8000, fuente: "Factura" }
              ]
            })
          })
        };
      }

      if (table === "opcion_componentes") {
        return {
          select: () => Promise.resolve({
            data: [
              {
                opcion_id: "opc-susp",
                material_id: "mat-susp-1",
                cantidad: 2,
                escala: "fija",
                paso: ["PASO 2"],
                rol: "principal",
                uso: ["SUSPENSION"],
                opciones_configuracion: { grupo_id: "grp-susp", clave: "fleet_master" },
                productos: { nombre: "SUSPENSION FLEET MASTER", unidad: "JGO", costo: 15000 }
              }
            ]
          })
        };
      }

      if (table === "parametros_costeo") {
        return {
          select: () => ({
            eq: () => ({
              maybeSingle: () => Promise.resolve({
                data: { valor: { plataforma: 110000 } }
              })
            })
          })
        };
      }

      if (table === "presupuestos") {
        return {
          select: () => ({
            eq: (_c1: string, val1: string) => ({
              eq: (_c2: string, _val2: string) => ({
                maybeSingle: () => {
                  const encontrado = presupuestosEnDb.find((p) => p.folio === val1);
                  return Promise.resolve({ data: encontrado || null, error: null });
                }
              })
            })
          }),
          insert: (payload: any) => ({
            select: () => ({
              single: () => {
                const nuevo = { ...payload, id: `pres-${Date.now()}` };
                presupuestosEnDb.push(nuevo);
                return Promise.resolve({ data: nuevo, error: null });
              }
            })
          }),
          update: (payload: any) => ({
            eq: (_c1: string, idVal: string) => ({
              eq: () => ({
                select: () => ({
                  single: () => {
                    const idx = presupuestosEnDb.findIndex((p) => p.id === idVal);
                    if (idx >= 0) {
                      presupuestosEnDb[idx] = { ...presupuestosEnDb[idx], ...payload };
                      return Promise.resolve({ data: presupuestosEnDb[idx], error: null });
                    }
                    return Promise.resolve({ data: { ...payload, id: idVal }, error: null });
                  }
                })
              })
            })
          })
        };
      }

      if (table === "cotizacion_eventos") {
        return {
          insert: (items: any[]) => {
            eventos.push(...items);
            return Promise.resolve({ error: null });
          }
        };
      }

      return {
        select: () => ({
          eq: () => Promise.resolve({ data: [] }),
          then: (resolve: any) => resolve({ data: [] })
        })
      };
    }
  };

  return mock;
}

Deno.test("generarPresupuestoDeCotizacion - Caso 1: cotización con equipo configurado crea presupuesto", async () => {
  const mockSupabase = createMockSupabase({});
  const res = await generarPresupuestoDeCotizacion(mockSupabase as any, {
    cotizacionId: "cot-1",
    orgId: "org-xyz",
    usuarioId: "user-1",
    reemplazar: false
  });

  assertEquals(res.estado, "creado");
  assert(res.presupuesto);
  assertEquals(res.presupuesto.folio, "PRE-COT-2026-0099");
  assertEquals(mockSupabase.presupuestosEnDb.length, 1);
  assertEquals(mockSupabase.eventos.length, 1);
  assertEquals(mockSupabase.eventos[0].evento, "Presupuesto PRE-COT-2026-0099 generado desde costeo");
  assertEquals(mockSupabase.eventos[0].usuario_id, "user-1");
});

Deno.test("generarPresupuestoDeCotizacion - Caso 2: segunda llamada sin reemplazar devuelve 'existe' y no inserta", async () => {
  const previo = { id: "pres-existente-1", folio: "PRE-COT-2026-0099", organizacion_id: "org-xyz" };
  const mockSupabase = createMockSupabase({ presupuestoPrevio: previo });

  const res = await generarPresupuestoDeCotizacion(mockSupabase as any, {
    cotizacionId: "cot-1",
    orgId: "org-xyz",
    usuarioId: "user-1",
    reemplazar: false
  });

  assertEquals(res.estado, "existe");
  assertEquals(res.presupuesto_id, "pres-existente-1");
  assertEquals(mockSupabase.presupuestosEnDb.length, 1);
  assertEquals(mockSupabase.eventos.length, 0); // No registra evento si ya existe
});

Deno.test("generarPresupuestoDeCotizacion - Caso 3: con reemplazar: true reemplaza el presupuesto con el mismo id", async () => {
  const previo = { id: "pres-existente-1", folio: "PRE-COT-2026-0099", organizacion_id: "org-xyz" };
  const mockSupabase = createMockSupabase({ presupuestoPrevio: previo });

  const res = await generarPresupuestoDeCotizacion(mockSupabase as any, {
    cotizacionId: "cot-1",
    orgId: "org-xyz",
    usuarioId: "user-1",
    reemplazar: true
  });

  assertEquals(res.estado, "reemplazado");
  assertEquals(res.presupuesto_id, "pres-existente-1");
  assertEquals(res.presupuesto.id, "pres-existente-1");
  assertEquals(mockSupabase.presupuestosEnDb.length, 1);
  assertEquals(mockSupabase.eventos.length, 1);
  assertEquals(mockSupabase.eventos[0].evento, "Presupuesto PRE-COT-2026-0099 reemplazado desde costeo");
});

Deno.test("generarPresupuestoDeCotizacion - Caso 4: sin equipos elegibles devuelve 'sin_equipos'", async () => {
  const mockSupabase = createMockSupabase({ itemsValidos: false });

  const res = await generarPresupuestoDeCotizacion(mockSupabase as any, {
    cotizacionId: "cot-1",
    orgId: "org-xyz",
    usuarioId: "user-1",
    reemplazar: false
  });

  assertEquals(res.estado, "sin_equipos");
  assert(res.conceptos_omitidos && res.conceptos_omitidos.length > 0);
  assertEquals(mockSupabase.presupuestosEnDb.length, 0);
  assertEquals(mockSupabase.eventos.length, 0);
});

Deno.test("generarPresupuestoDeCotizacion - Caso 5: registrarEvento registra el texto correcto según estado o parámetro", async () => {
  // Test con textoEvento personalizado
  const mockSupabase = createMockSupabase({});
  const res = await generarPresupuestoDeCotizacion(mockSupabase as any, {
    cotizacionId: "cot-1",
    orgId: "org-xyz",
    usuarioId: null,
    reemplazar: false,
    textoEvento: "Presupuesto PRE-COT-2026-0099 generado automáticamente al aprobar"
  });

  assertEquals(res.estado, "creado");
  assertEquals(mockSupabase.eventos.length, 1);
  assertEquals(mockSupabase.eventos[0].evento, "Presupuesto PRE-COT-2026-0099 generado automáticamente al aprobar");
});

Deno.test("ejecutarAprobacionCotizacion: aprobar con un equipo configurado crea el presupuesto automáticamente", async () => {
  const mockSupabase = createMockSupabase({});
  await ejecutarAprobacionCotizacion(mockSupabase as any, "cot-1", "org-xyz", null);

  assertEquals(mockSupabase.presupuestosEnDb.length, 1);
  assertEquals(mockSupabase.presupuestosEnDb[0].folio, "PRE-COT-2026-0099");
  assertEquals(mockSupabase.eventos.length, 2);
  assertEquals(mockSupabase.eventos[0].evento, "Cotizacion aprobada");
  assertEquals(mockSupabase.eventos[1].evento, "Presupuesto PRE-COT-2026-0099 generado automáticamente al aprobar");
});

Deno.test("ejecutarAprobacionCotizacion: aprobar con presupuesto ya existente no lo duplica ni lo pisa", async () => {
  const previo = { id: "pres-existente-1", folio: "PRE-COT-2026-0099", organizacion_id: "org-xyz", concepto: "Original" };
  const mockSupabase = createMockSupabase({ presupuestoPrevio: previo });

  await ejecutarAprobacionCotizacion(mockSupabase as any, "cot-1", "org-xyz", null);

  assertEquals(mockSupabase.presupuestosEnDb.length, 1);
  assertEquals(mockSupabase.presupuestosEnDb[0].id, "pres-existente-1");
  assertEquals(mockSupabase.presupuestosEnDb[0].concepto, "Original");
  assertEquals(mockSupabase.eventos.length, 1);
  assertEquals(mockSupabase.eventos[0].evento, "Cotizacion aprobada");
});

Deno.test("ejecutarAprobacionCotizacion: un error interno en presupuesto no impide completar la aprobación", async () => {
  const mockSupabase = createMockSupabase({});
  const mockSupabaseConError = {
    ...mockSupabase,
    from: (table: string) => {
      if (table === "presupuestos") {
        return {
          select: () => ({
            eq: () => ({
              eq: () => ({
                maybeSingle: () => Promise.resolve({ data: null, error: null })
              })
            })
          }),
          insert: () => {
            throw new Error("Simulated DB crash in presupuestos");
          }
        };
      }
      return mockSupabase.from(table);
    }
  };

  await ejecutarAprobacionCotizacion(mockSupabaseConError as any, "cot-1", "org-xyz", null);

  assertEquals(mockSupabase.eventos.length, 2);
  assertEquals(mockSupabase.eventos[0].evento, "Cotizacion aprobada");
  assert(mockSupabase.eventos[1].evento.includes("No se generó el presupuesto automático"));
});
