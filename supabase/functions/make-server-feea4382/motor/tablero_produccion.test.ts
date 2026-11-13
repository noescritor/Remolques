import { assertEquals, assertRejects } from "https://deno.land/std@0.192.0/testing/asserts.ts";
import {
  obtenerLineaPorTipoEquipo,
  calcularSemaforo,
  calcularEtiquetaVisible,
  actualizarPlaneacionMotor,
  moverOrdenMotor,
  crearOrdenManualMotor,
  obtenerMatrizProduccion,
  actualizarFaseMotor,
  obtenerHistorialOrdenMotor,
  sembrarTableroMotor,
} from "./tablero_produccion.ts";

Deno.test("tablero_produccion: mapeo de tipo_equipo a clave de línea canónica", () => {
  assertEquals(obtenerLineaPorTipoEquipo("01"), "plataforma");
  assertEquals(obtenerLineaPorTipoEquipo("02"), "dolly");
  assertEquals(obtenerLineaPorTipoEquipo("03"), "gondola");
  assertEquals(obtenerLineaPorTipoEquipo("04"), "plataforma");
  assertEquals(obtenerLineaPorTipoEquipo("05"), "plataforma");
  assertEquals(obtenerLineaPorTipoEquipo("06"), "plataforma");
  assertEquals(obtenerLineaPorTipoEquipo("07"), "plataforma");
  assertEquals(obtenerLineaPorTipoEquipo("08"), "plataforma");
  assertEquals(obtenerLineaPorTipoEquipo("09"), "traila");
  assertEquals(obtenerLineaPorTipoEquipo("Góndola 30m3"), "gondola");
  assertEquals(obtenerLineaPorTipoEquipo("Dolly H"), "dolly");
  assertEquals(obtenerLineaPorTipoEquipo("Traila Ganadera"), "traila");
  assertEquals(obtenerLineaPorTipoEquipo(null), "plataforma");
});

Deno.test("tablero_produccion: calcularSemaforo precedencias estrictas", () => {
  const hoy = "2026-11-12";

  // 1. Terminado
  assertEquals(
    calcularSemaforo(
      [
        { estado: "terminada" },
        { estado: "terminada" },
      ],
      hoy
    ),
    "terminado"
  );

  // 2. Por iniciar
  assertEquals(
    calcularSemaforo(
      [
        { estado: "pendiente" },
        { estado: "pendiente" },
      ],
      hoy
    ),
    "por_iniciar"
  );

  // 3. Atrasado tiene precedencia sobre detenido (pausada/incompleta)
  assertEquals(
    calcularSemaforo(
      [
        { estado: "terminada" },
        { estado: "en_proceso", fecha_propuesta: "2026-11-10" }, // vencida (hoy=12)
        { estado: "pausada", fecha_propuesta: "2026-11-15" },
      ],
      hoy
    ),
    "atrasado"
  );

  // 4. Detenido (incompleta o pausada sin ninguna atrasada)
  assertEquals(
    calcularSemaforo(
      [
        { estado: "terminada" },
        { estado: "en_proceso", fecha_propuesta: "2026-11-15" }, // en tiempo
        { estado: "incompleta" },
      ],
      hoy
    ),
    "detenido"
  );

  assertEquals(
    calcularSemaforo(
      [
        { estado: "terminada" },
        { estado: "pausada" },
        { estado: "pendiente" },
      ],
      hoy
    ),
    "detenido"
  );

  // 5. En tiempo (en proceso no vencida)
  assertEquals(
    calcularSemaforo(
      [
        { estado: "terminada" },
        { estado: "en_proceso", fecha_propuesta: "2026-11-14" },
        { estado: "pendiente" },
      ],
      hoy
    ),
    "en_tiempo"
  );

  // Caso vacío
  assertEquals(calcularSemaforo([], hoy), "por_iniciar");
});

Deno.test("tablero_produccion: calcularEtiquetaVisible reglas manual y numeración", () => {
  // 1. Etiqueta manual gana siempre
  assertEquals(
    calcularEtiquetaVisible(
      { id: "ord-1", etiqueta: "Chasis Especial", cliente_nombre: "Transportes García" },
      [
        { id: "ord-1", created_at: "2026-11-01" },
        { id: "ord-2", created_at: "2026-11-02" },
      ]
    ),
    "Chasis Especial"
  );

  // 2. Un solo equipo del cliente -> sin número
  assertEquals(
    calcularEtiquetaVisible(
      { id: "ord-1", cliente_nombre: "Efren" },
      [{ id: "ord-1", created_at: "2026-11-01" }]
    ),
    "Efren"
  );

  // 3. Múltiples equipos del mismo cliente -> #1, #2, #3 por created_at
  const grupo = [
    { id: "ord-b", created_at: "2026-11-05T10:00:00Z" },
    { id: "ord-a", created_at: "2026-11-01T10:00:00Z" },
    { id: "ord-c", created_at: "2026-11-10T10:00:00Z" },
  ];

  assertEquals(
    calcularEtiquetaVisible({ id: "ord-a", cliente_nombre: "Saul Salas" }, grupo),
    "Saul Salas #1"
  );
  assertEquals(
    calcularEtiquetaVisible({ id: "ord-b", cliente_nombre: "Saul Salas" }, grupo),
    "Saul Salas #2"
  );
  assertEquals(
    calcularEtiquetaVisible({ id: "ord-c", cliente_nombre: "Saul Salas" }, grupo),
    "Saul Salas #3"
  );

  // 4. Sin cliente y sin etiqueta -> Inventario
  assertEquals(
    calcularEtiquetaVisible({ id: "ord-x", cliente_nombre: null }, []),
    "Inventario"
  );
});

Deno.test("tablero_produccion: actualizarPlaneacionMotor lista blanca estricta", async () => {
  const dbMock = {
    updated: null as any,
    from: (table: string) => {
      assertEquals(table, "ordenes_trabajo");
      return {
        update: (payload: any) => {
          dbMock.updated = payload;
          return {
            eq: (_c1: string, _v1: string) => ({
              eq: (_c2: string, _v2: string) => ({
                select: () => ({
                  maybeSingle: () =>
                    Promise.resolve({
                      data: { id: "ord-1", ...payload },
                      error: null,
                    }),
                }),
              }),
            }),
          };
        },
      };
    },
  };

  // Rechaza campo no permitido (por ejemplo, estado_kanban o precio)
  await assertRejects(
    async () => {
      await actualizarPlaneacionMotor(dbMock, "org-1", "ord-1", {
        fecha_compromiso: "2026-12-01",
        estado_kanban: "incompleta", // PROHIBIDO
      });
    },
    Error,
    "Campo 'estado_kanban' no permitido en planeación"
  );

  // Acepta solo los tres campos permitidos
  const res = await actualizarPlaneacionMotor(dbMock, "org-1", "ord-1", {
    fecha_compromiso: "2026-12-01",
    etiqueta: "Plana Urgente",
    material_faltante: "Faltan 2 patines Jost",
  });

  assertEquals(res.ok, true);
  assertEquals(dbMock.updated, {
    fecha_compromiso: "2026-12-01",
    etiqueta: "Plana Urgente",
    material_faltante: "Faltan 2 patines Jost",
  });
});

Deno.test("tablero_produccion: moverOrdenMotor rechaza pendientes y usa en_proceso", async () => {
  let rpcLlamada: any = null;
  const dbMock = {
    rpc: (nombre: string, params: any) => {
      rpcLlamada = { nombre, params };
      return Promise.resolve({
        data: {
          ok: true,
          celda: { fase_id: params.p_fase, estado: params.p_estado },
          orden: { id: params.p_orden, estado: "En Producción", estado_kanban: "en_proceso" },
          avisos: [],
        },
        error: null,
      });
    },
  };

  // 1. Mover a 'pendientes' debe responder 400
  await assertRejects(
    async () => {
      await moverOrdenMotor(dbMock, "org-1", "ord-1", "pendientes");
    },
    Error,
    "No se puede mover la orden a pendientes directamente"
  );

  // 2. Mover a una fase concreta invoca la RPC con 'en_proceso'
  const res = await moverOrdenMotor(
    dbMock,
    "org-1",
    "ord-1",
    "fase-corte-uuid",
    "user-1"
  );

  assertEquals(res.ok, true);
  assertEquals(rpcLlamada.nombre, "actualizar_fase_orden");
  assertEquals(rpcLlamada.params.p_fase, "fase-corte-uuid");
  assertEquals(rpcLlamada.params.p_estado, "en_proceso");
  assertEquals(rpcLlamada.params.p_usuario, "user-1");
});

Deno.test("tablero_produccion: crearOrdenManualMotor valida cliente_id o etiqueta y genera nomenclatura INV", async () => {
  let insertedData: any = null;
  let rpcFasesCreated = false;

  const dbMock = {
    rpc: (nombre: string, params: any) => {
      if (nombre === "obtener_siguiente_produccion") {
        return Promise.resolve({ data: 42, error: null });
      }
      if (nombre === "crear_fases_orden") {
        rpcFasesCreated = true;
        return Promise.resolve({ data: 12, error: null });
      }
      return Promise.resolve({ data: null, error: null });
    },
    from: (table: string) => {
      if (table === "lineas_producto") {
        return {
          select: () => ({
            eq: () => ({
              eq: () => ({
                maybeSingle: () =>
                  Promise.resolve({
                    data: { id: "linea-plat-uuid", clave: "plataforma", nombre: "Plataforma" },
                    error: null,
                  }),
              }),
            }),
          }),
        };
      }
      if (table === "ordenes_trabajo") {
        return {
          insert: (records: any[]) => {
            insertedData = records[0];
            return {
              select: () => ({
                single: () =>
                  Promise.resolve({
                    data: { id: "ord-nueva-uuid", ...insertedData },
                    error: null,
                  }),
              }),
            };
          },
        };
      }
      return {};
    },
  };

  // 1. Falla si falta cliente_id y etiqueta
  await assertRejects(
    async () => {
      await crearOrdenManualMotor(dbMock, "org-1", {
        linea: "plataforma",
      });
    },
    Error,
    "Se requiere cliente_id o etiqueta"
  );

  // 2. Crea exitosamente con etiqueta (sin cliente) -> prefijo INV y nomenclatura correcta
  const res = await crearOrdenManualMotor(dbMock, "org-1", {
    linea: "plataforma",
    etiqueta: "Plana Stock 40ft",
  });

  assertEquals(res.ok, true);
  assertEquals(rpcFasesCreated, true);
  assertEquals(insertedData.origen, "manual");
  assertEquals(insertedData.cotizacion_id, null);
  assertEquals(insertedData.cliente_id, null);
  assertEquals(insertedData.etiqueta, "Plana Stock 40ft");
  assertEquals(insertedData.linea_producto_id, "linea-plat-uuid");
  // Nomenclatura debe contener 42-INV01
  assertEquals(insertedData.nomenclatura_id.startsWith("42-INV01"), true);
});

Deno.test("tablero_produccion: obtenerMatrizProduccion estructura, resumen y exclusión de Liberado", async () => {
  const fasesMock = [
    { id: "f1", orden: 1, nombre: "Corte", grupo: "principal", requiere_grupo: null, duracion_dias: 2 },
    { id: "f2", orden: 2, nombre: "Ensamble", grupo: "principal", requiere_grupo: null, duracion_dias: 3 },
  ];

  const ordenesMock = [
    {
      id: "ord-1",
      nomenclatura_id: "01-CLI-1",
      etiqueta: null,
      cliente_id: "cli-1",
      cotizacion_id: "cot-1",
      modelo: "Plataforma 40ft",
      tipo_equipo: "01",
      origen: "cotizacion",
      fecha_compromiso: "2026-12-01",
      fecha_inicio: "2026-11-10",
      material_faltante: "Tornillería",
      estado: "En Producción",
      estado_kanban: "en_proceso",
      created_at: "2026-11-10T10:00:00Z",
      cliente: { id: "cli-1", nombre_razon_social: "Transportes Azteca" },
      cotizacion: { id: "cot-1", folio: "COT-101" },
    },
    {
      id: "ord-2",
      nomenclatura_id: "02-CLI-1",
      etiqueta: null,
      cliente_id: "cli-1",
      cotizacion_id: "cot-2",
      modelo: "Plataforma 40ft",
      tipo_equipo: "01",
      origen: "cotizacion",
      fecha_compromiso: "2026-12-05",
      fecha_inicio: null,
      material_faltante: null,
      estado: "Pendiente",
      estado_kanban: "pendiente",
      created_at: "2026-11-11T10:00:00Z",
      cliente: { id: "cli-1", nombre_razon_social: "Transportes Azteca" },
      cotizacion: { id: "cot-2", folio: "COT-102" },
    },
  ];

  const ordenFasesMock = [
    // ord-1: f1 terminada, f2 en_proceso atrasada
    { orden_trabajo_id: "ord-1", fase_id: "f1", estado: "terminada", fecha_propuesta: null, fecha_fin: "2026-11-11", nota: null },
    { orden_trabajo_id: "ord-1", fase_id: "f2", estado: "en_proceso", fecha_propuesta: "2026-11-05", fecha_fin: null, nota: null },
    // ord-2: ambas pendientes
    { orden_trabajo_id: "ord-2", fase_id: "f1", estado: "pendiente", fecha_propuesta: null, fecha_fin: null, nota: null },
    { orden_trabajo_id: "ord-2", fase_id: "f2", estado: "pendiente", fecha_propuesta: null, fecha_fin: null, nota: null },
  ];

  const dbMock = {
    from: (table: string) => {
      if (table === "lineas_producto") {
        return {
          select: () => ({
            eq: () => ({
              eq: () => ({
                maybeSingle: () =>
                  Promise.resolve({
                    data: { id: "linea-plat", clave: "plataforma", nombre: "Plataforma" },
                    error: null,
                  }),
              }),
            }),
          }),
        };
      }
      if (table === "fases_produccion") {
        return {
          select: () => ({
            eq: () => ({
              eq: () => Promise.resolve({ data: fasesMock, error: null }),
            }),
          }),
        };
      }
      if (table === "ordenes_trabajo") {
        return {
          select: () => ({
            eq: () => ({
              eq: () => ({
                neq: (col: string, val: string) => {
                  assertEquals(col, "estado");
                  assertEquals(val, "Liberado");
                  return {
                    order: () => Promise.resolve({ data: ordenesMock, error: null }),
                  };
                },
                order: () => Promise.resolve({ data: ordenesMock, error: null }),
              }),
            }),
          }),
        };
      }
      if (table === "orden_fases") {
        return {
          select: () => ({
            in: () => Promise.resolve({ data: ordenFasesMock, error: null }),
          }),
        };
      }
      return {};
    },
  };

  const matriz = await obtenerMatrizProduccion(dbMock, "org-1", "plataforma");

  assertEquals(matriz.linea.clave, "plataforma");
  assertEquals(matriz.fases.length, 2);
  assertEquals(matriz.filas.length, 2);

  // Ordenamiento: menos avanzado primero (ord-2 tiene 0% vs ord-1 con 50%)
  assertEquals(matriz.filas[0].orden_id, "ord-2");
  assertEquals(matriz.filas[1].orden_id, "ord-1");

  // Etiquetas generadas con numeración del cliente
  assertEquals(matriz.filas[0].etiqueta, "Transportes Azteca #2");
  assertEquals(matriz.filas[1].etiqueta, "Transportes Azteca #1");

  // Semáforo: ord-1 atrasado (f2 vencida 2026-11-05), ord-2 por_iniciar
  assertEquals(matriz.filas[1].semaforo, "atrasado");
  assertEquals(matriz.filas[0].semaforo, "por_iniciar");

  // Resumen
  assertEquals(matriz.resumen.en_planta, 2);
  assertEquals(matriz.resumen.atrasados, 1);
  assertEquals(matriz.resumen.con_material, 1); // ord-1 tiene Tornillería
  assertEquals(matriz.resumen.con_pausa, 0);
  assertEquals(matriz.resumen.wip_por_fase["f1"], 0);
  assertEquals(matriz.resumen.wip_por_fase["f2"], 1); // ord-1 en_proceso en f2
});

Deno.test("tablero_produccion: actualizarFaseMotor propaga 404 y 409 según mensaje de RPC", async () => {
  const dbMock404 = {
    rpc: () => Promise.resolve({ data: null, error: { message: "Orden de trabajo no encontrada" } }),
  };

  await assertRejects(
    async () => {
      await actualizarFaseMotor(dbMock404, "org-1", "ord-inexistente", "f1", { estado: "en_proceso" });
    },
    Error,
    "Orden de trabajo no encontrada"
  );

  const dbMock409 = {
    rpc: () => Promise.resolve({ data: null, error: { message: "La fase no pertenece a la línea de esta orden" } }),
  };

  await assertRejects(
    async () => {
      await actualizarFaseMotor(dbMock409, "org-1", "ord-1", "fase-otra-linea", { estado: "en_proceso" });
    },
    Error,
    "La fase no pertenece a la línea de esta orden"
  );
});

Deno.test("tablero_produccion: obtenerHistorialOrdenMotor consulta fecha_cambio y mapea usuario_id / created_at", async () => {
  let selectColumns = "";
  let orderColumn = "";

  const dbMock = {
    from: (table: string) => {
      if (table === "ordenes_trabajo") {
        return {
          select: () => ({
            eq: () => ({
              eq: () => ({
                maybeSingle: () => Promise.resolve({ data: { id: "ord-1" }, error: null }),
              }),
            }),
          }),
        };
      }
      if (table === "historial_fases") {
        return {
          select: (cols: string) => {
            selectColumns = cols;
            return {
              eq: () => ({
                order: (col: string, opts: any) => {
                  orderColumn = col;
                  return Promise.resolve({
                    data: [
                      {
                        id: "h-1",
                        fase_id: "f1",
                        estado: "en_proceso",
                        estado_anterior: "pendiente",
                        fecha_propuesta: "2026-11-20",
                        nota: "Iniciando corte",
                        usuario_id: "user-123",
                        fecha_cambio: "2026-11-12T14:30:00Z",
                        fase: { nombre: "Corte", grupo: "principal", orden: 1 },
                      },
                      {
                        id: "h-2",
                        fase_id: "f2",
                        estado: "pausada",
                        estado_anterior: "en_proceso",
                        fecha_propuesta: null,
                        nota: "Falta material",
                        usuario_id: null,
                        fecha_cambio: "2026-11-12T12:00:00Z",
                        fase: { nombre: "Dispositivo", grupo: "principal", orden: 2 },
                      },
                    ],
                    error: null,
                  });
                },
              }),
            };
          },
        };
      }
      return {};
    },
  };

  const res = await obtenerHistorialOrdenMotor(dbMock, "org-1", "ord-1");
  assertEquals(res.ok, true);
  assertEquals(res.historial.length, 2);

  // Verifica que seleccionó y ordenó por fecha_cambio (no por created_at)
  assertEquals(selectColumns.includes("fecha_cambio"), true);
  assertEquals(orderColumn, "fecha_cambio");

  // Primer registro: usuario_id explícito
  const h1 = res.historial[0];
  assertEquals(h1.usuario_id, "user-123");
  assertEquals(h1.usuario, "user-123");
  assertEquals(h1.fecha_cambio, "2026-11-12T14:30:00Z");
  assertEquals(h1.created_at, "2026-11-12T14:30:00Z");

  // Segundo registro: usuario nulo -> 'Sistema'
  const h2 = res.historial[1];
  assertEquals(h2.usuario_id, null);
  assertEquals(h2.usuario, "Sistema");
});

Deno.test("tablero_produccion: motor functions priorizan serviceClient para RPCs y arrojan error si falla", async () => {
  let userRpcCalled = false;
  let serviceRpcCalled = false;

  const userClientMock = {
    rpc: (_name: string) => {
      userRpcCalled = true;
      return Promise.resolve({ data: null, error: new Error("permission denied") });
    },
  };

  const serviceClientMock = {
    rpc: (name: string, params: any) => {
      serviceRpcCalled = true;
      if (name === "actualizar_fase_orden") {
        return Promise.resolve({ data: { ok: true }, error: null });
      }
      if (name === "sembrar_tablero_produccion") {
        return Promise.resolve({ data: { sembrado: true }, error: null });
      }
      return Promise.resolve({ data: null, error: null });
    },
  };

  // 1. actualizarFaseMotor usa serviceClient
  await actualizarFaseMotor(
    userClientMock,
    "org-1",
    "ord-1",
    "f1",
    { estado: "en_proceso" },
    "user-1",
    serviceClientMock
  );
  assertEquals(userRpcCalled, false, "El cliente de usuario no debió llamar al RPC");
  assertEquals(serviceRpcCalled, true, "El serviceClient debió llamar al RPC");

  // 2. sembrarTableroMotor usa serviceClient
  userRpcCalled = false;
  serviceRpcCalled = false;
  await sembrarTableroMotor(userClientMock, "org-1", serviceClientMock);
  assertEquals(userRpcCalled, false);
  assertEquals(serviceRpcCalled, true);

  // 3. Fallo de RPC en crear_fases_orden durante crearOrdenManualMotor arroja excepción
  const failingServiceClient = {
    rpc: (name: string) => {
      if (name === "obtener_siguiente_produccion") return Promise.resolve({ data: 99, error: null });
      if (name === "crear_fases_orden") return Promise.resolve({ data: null, error: new Error("RPC crear_fases_orden falló") });
      return Promise.resolve({ data: null, error: null });
    },
  };

  const dbMockParaOrden = {
    from: (table: string) => {
      if (table === "lineas_producto") {
        return {
          select: () => ({
            eq: () => ({
              eq: () => ({
                maybeSingle: () => Promise.resolve({ data: { id: "lin-1", clave: "plataforma" }, error: null }),
              }),
            }),
          }),
        };
      }
      if (table === "ordenes_trabajo") {
        return {
          insert: () => ({
            select: () => ({
              single: () => Promise.resolve({ data: { id: "ord-test" }, error: null }),
            }),
          }),
        };
      }
      return {};
    },
  };

  await assertRejects(
    async () => {
      await crearOrdenManualMotor(
        dbMockParaOrden,
        "org-1",
        { linea: "plataforma", etiqueta: "Equipo Manual" },
        failingServiceClient
      );
    },
    Error,
    "RPC crear_fases_orden falló"
  );
});
