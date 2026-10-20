import { assertEquals, assertRejects } from "https://deno.land/std@0.192.0/testing/asserts.ts";
import { generarOrdenesDeCotizacion } from "./generar_ordenes_cotizacion.ts";

function createMockSupabase(opciones: {
  cotizacionExiste?: boolean;
  estadoCotizacion?: string;
  items?: any[];
  ordenesPrevias?: any[];
}) {
  const ordenesEnDb: any[] = opciones.ordenesPrevias ? [...opciones.ordenesPrevias] : [];
  const eventos: any[] = [];
  const updatesCotizacion: any[] = [];
  let seqCounter = 100;

  const mock = {
    ordenesEnDb,
    eventos,
    updatesCotizacion,
    rpc: (fn: string) => {
      if (fn === "obtener_siguiente_produccion") {
        seqCounter++;
        return Promise.resolve({ data: seqCounter, error: null });
      }
      return Promise.resolve({ data: null, error: null });
    },
    from: (table: string) => {
      if (table === "cotizaciones") {
        return {
          select: () => ({
            eq: (_c1: string, _v1: string) => ({
              eq: (_c2: string, _v2: string) => ({
                single: () => {
                  if (opciones.cotizacionExiste === false) {
                    return Promise.resolve({ data: null, error: { message: "No encontrada" } });
                  }
                  return Promise.resolve({
                    data: {
                      id: "cot-123",
                      folio: "COT-2026-0001",
                      cliente_id: "cli-1",
                      organizacion_id: "org-1",
                      descripcion: "Plana #2",
                      estado: opciones.estadoCotizacion || "Aprobada",
                      fecha: "2026-02-12",
                      cliente: {
                        id: "cli-1",
                        nombre_razon_social: "AGUSTIN ANDRADE",
                        telefono: "775 144 0407",
                        correo: "agustin@test.com"
                      },
                      items: opciones.items !== undefined ? opciones.items : [
                        {
                          id: "item-1",
                          producto_id: "prod-plat",
                          cantidad: 2,
                          descripcion: "Plataforma 40 ft 2 ejes",
                          configuracion: {
                            modelo_id: "prod-plat",
                            grupos: {
                              eje: "fleet_master",
                              suspension: "fleet_master",
                              patin: "hj",
                              color: "rojo"
                            }
                          }
                        }
                      ]
                    },
                    error: null
                  });
                }
              })
            })
          }),
          update: (payload: any) => {
            updatesCotizacion.push(payload);
            return {
              eq: () => Promise.resolve({ error: null })
            };
          }
        };
      }

      if (table === "ordenes_trabajo") {
        return {
          select: () => ({
            eq: (_c1: string, _v1: string) => ({
              eq: (_c2: string, _v2: string) => {
                return Promise.resolve({
                  data: ordenesEnDb.length > 0 ? ordenesEnDb : null,
                  error: null
                });
              }
            })
          }),
          insert: (nuevas: any[]) => {
            for (const n of nuevas) {
              const conId = { ...n, id: `ord-${ordenesEnDb.length + 1}` };
              ordenesEnDb.push(conId);
            }
            return {
              select: () => Promise.resolve({ data: ordenesEnDb, error: null })
            };
          }
        };
      }

      if (table === "productos") {
        return {
          select: () => ({
            in: (_col: string, ids: string[]) => {
              return Promise.resolve({
                data: ids.map((id) => ({
                  id,
                  tipo_item: id.includes("serv") ? "servicio" : "producto_terminado"
                })),
                error: null
              });
            }
          })
        };
      }

      if (table === "lineas_producto") {
        return {
          select: () => ({
            eq: () => Promise.resolve({
              data: [{ id: "linea-1", nombre: "Plataformas", prefijo: "PLA" }],
              error: null
            })
          })
        };
      }

      if (table === "fases_produccion") {
        return {
          select: () => ({
            eq: () => ({
              order: () => ({
                limit: () => Promise.resolve({
                  data: [{ id: "fase-1" }],
                  error: null
                })
              })
            })
          })
        };
      }

      if (table === "modelos") {
        return {
          select: () => ({
            eq: () => ({
              single: () => Promise.resolve({
                data: {
                  id: "prod-plat",
                  tipo: "plataforma",
                  largo_ft: 40,
                  num_ejes: 2,
                  productos: { nombre: "Plataforma 40 ft 2 ejes" }
                },
                error: null
              })
            })
          })
        };
      }

      if (table === "receta_base") {
        return {
          select: () => ({
            eq: () => Promise.resolve({ data: [], error: null })
          })
        };
      }

      if (table === "grupos_configuracion") {
        return {
          select: () => Promise.resolve({
            data: [
              { id: "g-eje", clave: "eje", nombre: "Ejes" },
              { id: "g-susp", clave: "suspension", nombre: "Suspensión" }
            ],
            error: null
          })
        };
      }

      if (table === "opciones_configuracion") {
        return {
          select: () => Promise.resolve({
            data: [
              { id: "o-eje", grupo_id: "g-eje", clave: "fleet_master", nombre: "Fleet Master" },
              { id: "o-susp", grupo_id: "g-susp", clave: "fleet_master", nombre: "Fleet Master" }
            ],
            error: null
          })
        };
      }

      if (table === "opcion_componentes") {
        return {
          select: () => Promise.resolve({ data: [], error: null })
        };
      }

      if (table === "cotizacion_eventos") {
        return {
          insert: (eventosNuevos: any[]) => {
            eventos.push(...eventosNuevos);
            return Promise.resolve({ error: null });
          }
        };
      }

      return {
        select: () => ({
          eq: () => Promise.resolve({ data: [], error: null })
        })
      };
    }
  };

  return mock;
}

Deno.test("Rechaza cotización si no está aprobada", async () => {
  const mockSupabase = createMockSupabase({ estadoCotizacion: "Borrador" });

  await assertRejects(
    async () => {
      await generarOrdenesDeCotizacion(mockSupabase, {
        cotizacionId: "cot-123",
        orgId: "org-1"
      });
    },
    Error,
    "Aprueba la cotización para generar la orden de trabajo"
  );
});

Deno.test("Crea una orden por unidad (cantidad 2 -> 2 órdenes)", async () => {
  const mockSupabase = createMockSupabase({
    items: [
      {
        id: "item-1",
        producto_id: "prod-plat",
        cantidad: 2,
        descripcion: "Plataforma 40 ft 2 ejes",
        configuracion: {
          modelo_id: "prod-plat",
          grupos: {
            eje: "fleet_master",
            suspension: "fleet_master"
          }
        }
      }
    ]
  });

  const res = await generarOrdenesDeCotizacion(mockSupabase, {
    cotizacionId: "cot-123",
    orgId: "org-1"
  });

  assertEquals(res.creadas, 2);
  assertEquals(res.ya_existian, false);
  assertEquals(mockSupabase.ordenesEnDb.length, 2);

  // Verificar ficha guardada en caracteristicas
  const primera = mockSupabase.ordenesEnDb[0];
  assertEquals(typeof primera.caracteristicas?.ficha, "object");
  assertEquals(primera.caracteristicas?.ficha?.cabecera?.cliente, "AGUSTIN ANDRADE");
  assertEquals(primera.caracteristicas?.ficha?.cantidad_texto.includes("Plataforma"), true);

  // Nomenclaturas distintas
  assertEquals(mockSupabase.ordenesEnDb[0].nomenclatura_id !== mockSupabase.ordenesEnDb[1].nomenclatura_id, true);

  // Evento registrado y estado actualizado
  assertEquals(mockSupabase.eventos.length, 1);
  assertEquals(mockSupabase.updatesCotizacion[0].estado_produccion, "En producción");
});

Deno.test("Idempotencia: no duplica órdenes si ya existen", async () => {
  const mockSupabase = createMockSupabase({
    ordenesPrevias: [
      { id: "ord-existente-1", nomenclatura_id: "101-AGU010226-1" }
    ]
  });

  const res = await generarOrdenesDeCotizacion(mockSupabase, {
    cotizacionId: "cot-123",
    orgId: "org-1"
  });

  assertEquals(res.creadas, 0);
  assertEquals(res.ya_existian, true);
  assertEquals(res.ordenes.length, 1);
  assertEquals(res.ordenes[0].id, "ord-existente-1");
  assertEquals(mockSupabase.eventos.length, 0); // No registra evento duplicado
});

Deno.test("Ignora conceptos que no son equipos", async () => {
  const mockSupabase = createMockSupabase({
    items: [
      {
        id: "item-flete",
        producto_id: "prod-serv-flete",
        cantidad: 1,
        descripcion: "Servicio de flete local",
        configuracion: null
      }
    ]
  });

  await assertRejects(
    async () => {
      await generarOrdenesDeCotizacion(mockSupabase, {
        cotizacionId: "cot-123",
        orgId: "org-1"
      });
    },
    Error,
    "No se encontraron equipos (productos terminados) en la cotización."
  );
});
