import { assertEquals, assertRejects } from "https://deno.land/std@0.192.0/testing/asserts.ts";
import {
  generarOrdenesDeCotizacion,
  actualizarOrdenTrabajoSegura,
  regenerarFichaDeOrden,
  sanitizarPayloadOrdenTrabajo,
} from "./generar_ordenes_cotizacion.ts";

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
          select: (_cols?: string) => ({
            eq: (c1: string, v1: string) => ({
              eq: (c2: string, v2: string) => {
                const match = ordenesEnDb.find((o) => {
                  const match1 = c1 === "id" ? o.id === v1 : c1 === "cotizacion_id" ? o.cotizacion_id === v1 : o[c1] === v1;
                  const match2 = c2 === "organizacion_id" ? o.organizacion_id === v2 : o[c2] === v2;
                  return match1 && match2;
                });
                return {
                  single: () => {
                    if (!match) return Promise.resolve({ data: null, error: { message: "No encontrada" } });
                    const cotData = opciones.cotizacionExiste === false ? null : {
                      id: "cot-123",
                      folio: "COT-2026-0001",
                      cliente_id: "cli-1",
                      organizacion_id: "org-1",
                      descripcion: "Plana #2",
                      estado: opciones.estadoCotizacion || "Aprobada",
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
                    };
                    return Promise.resolve({
                      data: {
                        ...match,
                        cliente: match.cliente || cotData?.cliente,
                        cotizacion: match.cotizacion || cotData
                      },
                      error: null
                    });
                  },
                  then: (resolve: any) => resolve({
                    data: ordenesEnDb.length > 0 ? ordenesEnDb : null,
                    error: null
                  })
                };
              }
            })
          }),
          update: (payload: any) => ({
            eq: (c1: string, v1: string) => ({
              eq: (c2: string, v2: string) => ({
                select: () => ({
                  single: () => {
                    const idx = ordenesEnDb.findIndex((o) => {
                      const match1 = c1 === "id" ? o.id === v1 : o[c1] === v1;
                      const match2 = c2 === "organizacion_id" ? o.organizacion_id === v2 : o[c2] === v2;
                      return match1 && match2;
                    });
                    if (idx === -1) return Promise.resolve({ data: null, error: { message: "No encontrada" } });
                    ordenesEnDb[idx] = { ...ordenesEnDb[idx], ...payload };
                    return Promise.resolve({ data: ordenesEnDb[idx], error: null });
                  }
                }),
                then: (resolve: any) => {
                  const idx = ordenesEnDb.findIndex((o) => {
                    const match1 = c1 === "id" ? o.id === v1 : o[c1] === v1;
                    const match2 = c2 === "organizacion_id" ? o.organizacion_id === v2 : o[c2] === v2;
                    return match1 && match2;
                  });
                  if (idx >= 0) ordenesEnDb[idx] = { ...ordenesEnDb[idx], ...payload };
                  return resolve({ data: ordenesEnDb[idx] || null, error: null });
                }
              })
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

Deno.test("Seguridad: un payload con organizacion_id ajeno NO cambia la organización ni campos protegidos", async () => {
  const mockSupabase = createMockSupabase({});
  mockSupabase.ordenesEnDb.push({
    id: "ord-sec-1",
    organizacion_id: "org-1",
    cotizacion_id: "cot-123",
    cliente_id: "cli-1",
    nomenclatura_id: "NOM-100",
    niv: "NIV-OLD",
    estado: "Pendiente",
    caracteristicas: { color: "blanco" }
  });

  const rawPayload = {
    id: "ord-hacker",
    organizacion_id: "org-hacker-maliciosa",
    cotizacion_id: "cot-hacker",
    cliente_id: "cli-hacker",
    nomenclatura_id: "NOM-HACKER",
    created_at: "2020-01-01",
    niv: "NIV-NEW-123",
    estado: "En proceso"
  };

  // Sanitizador ignora organizacion_id y campos ajenos
  const limpio = sanitizarPayloadOrdenTrabajo(rawPayload);
  assertEquals(limpio.organizacion_id, undefined);
  assertEquals(limpio.id, undefined);
  assertEquals(limpio.cotizacion_id, undefined);
  assertEquals(limpio.cliente_id, undefined);
  assertEquals(limpio.nomenclatura_id, undefined);
  assertEquals(limpio.created_at, undefined);
  assertEquals(limpio.niv, "NIV-NEW-123");
  assertEquals(limpio.estado, "En proceso");

  // Al actualizar con cliente falso, organizacion_id en BD no cambia
  await actualizarOrdenTrabajoSegura(mockSupabase, {
    id: "ord-sec-1",
    orgId: "org-1",
    rawPayload
  });

  const enDb = mockSupabase.ordenesEnDb.find((o) => o.id === "ord-sec-1");
  assertEquals(enDb.organizacion_id, "org-1");
  assertEquals(enDb.cotizacion_id, "cot-123");
  assertEquals(enDb.cliente_id, "cli-1");
  assertEquals(enDb.nomenclatura_id, "NOM-100");
  assertEquals(enDb.niv, "NIV-NEW-123");
  assertEquals(enDb.estado, "En proceso");
});

Deno.test("Regenerar ficha: orden con item_id correcto usa ese concepto exacto", async () => {
  const mockSupabase = createMockSupabase({
    items: [
      {
        id: "item-plat-1",
        producto_id: "prod-plat",
        cantidad: 1,
        descripcion: "Plataforma 40 ft 2 ejes",
        configuracion: { modelo_id: "prod-plat", grupos: { eje: "fleet_master", color: "azul" } }
      },
      {
        id: "item-gondola-2",
        producto_id: "prod-gondola",
        cantidad: 1,
        descripcion: "Góndola 30 ft 3 ejes",
        configuracion: { modelo_id: "prod-plat", grupos: { eje: "fleet_master", color: "rojo" } }
      }
    ]
  });

  mockSupabase.ordenesEnDb.push({
    id: "ord-con-item-id",
    organizacion_id: "org-1",
    cotizacion_id: "cot-123",
    caracteristicas: {
      item_id: "item-gondola-2",
      unidad: 1,
      color: "rojo"
    }
  });

  const res = await regenerarFichaDeOrden(mockSupabase, {
    id: "ord-con-item-id",
    orgId: "org-1"
  });

  assertEquals(res.ok, true);
  assertEquals(res.orden.caracteristicas.item_id, "item-gondola-2");
  assertEquals(res.orden.caracteristicas.ficha.caracteristicas.find((c: any) => c.etiqueta === "COLOR")?.valor, "Rojo");
});

Deno.test("Regenerar ficha: orden vieja sin item_id con 1 solo equipo en la cotización regenera con éxito", async () => {
  const mockSupabase = createMockSupabase({
    items: [
      {
        id: "item-unico",
        producto_id: "prod-plat",
        cantidad: 1,
        descripcion: "Plataforma 40 ft 2 ejes",
        configuracion: { modelo_id: "prod-plat", grupos: { eje: "fleet_master", color: "verde" } }
      },
      {
        id: "item-flete",
        producto_id: "prod-serv-flete",
        cantidad: 1,
        descripcion: "Flete de traslado",
        configuracion: null
      }
    ]
  });

  mockSupabase.ordenesEnDb.push({
    id: "ord-vieja-1-equipo",
    organizacion_id: "org-1",
    cotizacion_id: "cot-123",
    caracteristicas: {
      // Sin item_id
      color: "verde"
    }
  });

  const res = await regenerarFichaDeOrden(mockSupabase, {
    id: "ord-vieja-1-equipo",
    orgId: "org-1"
  });

  assertEquals(res.ok, true);
  assertEquals(res.orden.caracteristicas.item_id, "item-unico");
  assertEquals(res.orden.caracteristicas.ficha.caracteristicas.find((c: any) => c.etiqueta === "COLOR")?.valor, "Verde");
});

Deno.test("Regenerar ficha: orden vieja sin item_id con 2 equipos en la cotización responde 409", async () => {
  const mockSupabase = createMockSupabase({
    items: [
      {
        id: "item-equipo-a",
        producto_id: "prod-plat",
        cantidad: 1,
        descripcion: "Plataforma 40 ft 2 ejes",
        configuracion: { modelo_id: "prod-plat" }
      },
      {
        id: "item-equipo-b",
        producto_id: "prod-dolly",
        cantidad: 1,
        descripcion: "Dolly 2 ejes",
        configuracion: { modelo_id: "prod-dolly" }
      }
    ]
  });

  mockSupabase.ordenesEnDb.push({
    id: "ord-vieja-2-equipos",
    organizacion_id: "org-1",
    cotizacion_id: "cot-123",
    caracteristicas: {
      // Sin item_id y cotización tiene 2 equipos
      color: "amarillo"
    }
  });

  await assertRejects(
    async () => {
      await regenerarFichaDeOrden(mockSupabase, {
        id: "ord-vieja-2-equipos",
        orgId: "org-1"
      });
    },
    Error,
    "No se puede determinar el concepto de esta orden; regenérala desde la cotización"
  );
});
