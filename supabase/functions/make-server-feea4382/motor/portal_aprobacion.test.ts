import { assertEquals, assert } from "https://deno.land/std@0.192.0/testing/asserts.ts";
import {
  aprobarPorPortal,
  rechazarPorPortal,
  solicitarCambiosPorPortal,
} from "./portal_aprobacion.ts";
import { ejecutarAprobacionCotizacion } from "./generar_presupuesto_cotizacion.ts";

interface CotizacionRow {
  id: string;
  organizacion_id: string;
  token_publico: string;
  token_expira_en: string | null;
  estado: string;
  estado_produccion?: string;
  firma_imagen?: string | null;
  firma_nombre?: string | null;
  firma_fecha?: string | null;
  firma_ip?: string | null;
  comentario_cliente?: string | null;
}

function crearMockSupabasePortal(cotInicial: CotizacionRow | null, opciones?: { simularCarrera?: boolean }) {
  const cot = cotInicial ? { ...cotInicial } : null;
  const eventos: any[] = [];
  let carreraDisparada = false;

  const supabase = {
    cot,
    eventos,
    from: (table: string) => {
      if (table === "cotizaciones") {
        return {
          select: (_cols?: string) => {
            const filtros: Record<string, any> = {};
            const builder = {
              eq: (col: string, val: any) => {
                filtros[col] = val;
                return builder;
              },
              single: async () => {
                if (!cot) return { data: null, error: { message: "No encontrada" } };
                return { data: { ...cot }, error: null };
              },
              maybeSingle: async () => {
                if (!cot) return { data: null, error: null };
                if (filtros.token_publico && filtros.token_publico !== cot.token_publico) {
                  return { data: null, error: null };
                }
                if (filtros.id && filtros.id !== cot.id) {
                  return { data: null, error: null };
                }
                return { data: { ...cot }, error: null };
              },
            };
            return builder;
          },
          update: (payload: Record<string, any>) => {
            const filtros: Record<string, any> = {};
            const builder = {
              eq: (col: string, val: any) => {
                filtros[col] = val;
                return builder;
              },
              select: (_cols?: string) => builder,
              single: async () => {
                if (!cot) return { data: null, error: { message: "No encontrada" } };
                return { data: { ...cot }, error: null };
              },
              maybeSingle: async () => {
                if (!cot) return { data: null, error: null };
                if (filtros.id && filtros.id !== cot.id) return { data: null, error: null };
                if (opciones?.simularCarrera && !carreraDisparada) {
                  carreraDisparada = true;
                  cot.estado = "Aprobada";
                  return { data: null, error: null };
                }
                if (filtros.estado && filtros.estado !== cot.estado) {
                  return { data: null, error: null };
                }
                Object.assign(cot, payload);
                return { data: { ...cot }, error: null };
              },
              then: (resolve: (val: any) => void) => {
                if (cot && (!filtros.id || filtros.id === cot.id)) {
                  Object.assign(cot, payload);
                }
                resolve({ error: null });
              },
            };
            return builder;
          },
        };
      }

      if (table === "cotizacion_eventos") {
        return {
          select: (_cols?: string) => ({
            eq: (_col: string, val: any) => Promise.resolve({
              data: eventos.filter((e) => e.cotizacion_id === val),
              error: null,
            }),
          }),
          insert: async (rows: any[]) => {
            eventos.push(...rows);
            return { error: null };
          },
        };
      }

      if (table === "items_cotizacion") {
        return {
          select: () => ({
            eq: () => Promise.resolve({ data: [], error: null }),
          }),
        };
      }

      throw new Error(`Tabla no mockeada: ${table}`);
    },
  };

  return supabase;
}

const FECHA_FIJA = new Date("2026-11-21T15:00:00.000Z");

Deno.test("portal_aprobacion: éxito con estado Enviada registra firma, evento y efectos", async () => {
  const mock = crearMockSupabasePortal({
    id: "cot-1",
    organizacion_id: "org-1",
    token_publico: "tok-valido",
    token_expira_en: "2026-12-21T00:00:00.000Z",
    estado: "Enviada",
  });

  let efectosLlamados = 0;
  const res = await aprobarPorPortal(
    mock,
    {
      token: "tok-valido",
      firma_nombre: "  Carlos Méndez  ",
      firma_imagen: "data:image/png;base64,AAA=",
      firma_ip: "187.10.20.30",
    },
    {
      ahora: () => FECHA_FIJA,
      aplicarEfectos: async () => {
        efectosLlamados++;
      },
    },
  );

  assertEquals(res.status, 200);
  assertEquals(res.body.success, true);
  assertEquals(mock.cot?.estado, "Aprobada");
  assertEquals(mock.cot?.firma_nombre, "Carlos Méndez");
  assertEquals(mock.cot?.firma_ip, "187.10.20.30");
  assertEquals(mock.cot?.firma_fecha, FECHA_FIJA.toISOString());
  assertEquals(efectosLlamados, 1);
  assertEquals(mock.eventos.length, 1);
  assert(mock.eventos[0].evento.includes("Aprobada por el cliente desde el portal"));
  assert(mock.eventos[0].evento.includes("Carlos Méndez"));
  assert(mock.eventos[0].evento.includes("187.10.20.30"));
});

Deno.test("portal_aprobacion: doble aprobación (secuencial y concurrente) devuelve 409 y no repite efectos", async () => {
  // Secuencial
  const mockSeq = crearMockSupabasePortal({
    id: "cot-2",
    organizacion_id: "org-1",
    token_publico: "tok-2",
    token_expira_en: "2026-12-21T00:00:00.000Z",
    estado: "Enviada",
  });

  let efectosSeq = 0;
  const deps = {
    ahora: () => FECHA_FIJA,
    aplicarEfectos: async () => {
      efectosSeq++;
    },
  };

  const res1 = await aprobarPorPortal(mockSeq, {
    token: "tok-2",
    firma_nombre: "Ana",
    firma_imagen: "data:image/png;base64,AAA=",
  }, deps);
  const res2 = await aprobarPorPortal(mockSeq, {
    token: "tok-2",
    firma_nombre: "Ana",
    firma_imagen: "data:image/png;base64,AAA=",
  }, deps);

  assertEquals(res1.status, 200);
  assertEquals(res2.status, 409);
  assertEquals(res2.body.codigo, "YA_APROBADA");
  assertEquals(efectosSeq, 1);
  assertEquals(mockSeq.eventos.length, 1);

  // Concurrente (carrera entre SELECT y UPDATE WHERE estado = 'Enviada')
  const mockRace = crearMockSupabasePortal(
    {
      id: "cot-race",
      organizacion_id: "org-1",
      token_publico: "tok-race",
      token_expira_en: "2026-12-21T00:00:00.000Z",
      estado: "Enviada",
    },
    { simularCarrera: true },
  );

  let efectosRace = 0;
  const resRace = await aprobarPorPortal(
    mockRace,
    { token: "tok-race", firma_nombre: "Luis", firma_imagen: "data:image/png;base64,AAA=" },
    {
      ahora: () => FECHA_FIJA,
      aplicarEfectos: async () => {
        efectosRace++;
      },
    },
  );

  assertEquals(resRace.status, 409);
  assertEquals(resRace.body.codigo, "YA_APROBADA");
  assertEquals(efectosRace, 0);
});

Deno.test("portal_aprobacion: estado no Enviada (Borrador / Cancelada) devuelve 409 y no modifica BD", async () => {
  for (const estado of ["Borrador", "Cancelada"]) {
    const mock = crearMockSupabasePortal({
      id: "cot-3",
      organizacion_id: "org-1",
      token_publico: "tok-3",
      token_expira_en: "2026-12-21T00:00:00.000Z",
      estado,
    });

    let efectos = 0;
    const res = await aprobarPorPortal(
      mock,
      { token: "tok-3", firma_nombre: "Pedro", firma_imagen: "data:image/png;base64,AAA=" },
      { ahora: () => FECHA_FIJA, aplicarEfectos: async () => { efectos++; } },
    );

    assertEquals(res.status, 409);
    assertEquals(res.body.codigo, "ESTADO_NO_DISPONIBLE");
    assertEquals(mock.cot?.estado, estado);
    assertEquals(efectos, 0);
    assertEquals(mock.eventos.length, 0);
  }
});

Deno.test("portal_aprobacion: token inválido devuelve 404", async () => {
  const mock = crearMockSupabasePortal(null);
  const res = await aprobarPorPortal(mock, {
    token: "inexistente",
    firma_nombre: "Pedro",
    firma_imagen: "data:image/png;base64,AAA=",
  });
  assertEquals(res.status, 404);
  assertEquals(res.body.codigo, "TOKEN_INVALIDO");
});

Deno.test("portal_aprobacion: token expirado devuelve 410", async () => {
  const mock = crearMockSupabasePortal({
    id: "cot-4",
    organizacion_id: "org-1",
    token_publico: "tok-exp",
    token_expira_en: "2026-11-20T00:00:00.000Z",
    estado: "Enviada",
  });

  const res = await aprobarPorPortal(
    mock,
    { token: "tok-exp", firma_nombre: "Pedro", firma_imagen: "data:image/png;base64,AAA=" },
    { ahora: () => FECHA_FIJA },
  );
  assertEquals(res.status, 410);
  assertEquals(res.body.codigo, "TOKEN_EXPIRADO");
  assertEquals(mock.cot?.estado, "Enviada");
});

Deno.test("portal_aprobacion: efectos que fallan mantienen aprobación registrada, registran evento pendiente y responden 200", async () => {
  const mock = crearMockSupabasePortal({
    id: "cot-5",
    organizacion_id: "org-1",
    token_publico: "tok-5",
    token_expira_en: "2026-12-21T00:00:00.000Z",
    estado: "Enviada",
  });

  const originalConsoleError = console.error;
  console.error = () => {};
  try {
    const res = await aprobarPorPortal(
      mock,
      {
        token: "tok-5",
        firma_nombre: "María López",
        firma_imagen: "data:image/png;base64,AAA=",
        firma_ip: "10.0.0.1",
      },
      {
        ahora: () => FECHA_FIJA,
        aplicarEfectos: async () => {
          throw new Error("Fallo simulado en servicio");
        },
      },
    );

    assertEquals(res.status, 200);
    assertEquals(res.body.success, true);
    assertEquals(res.body.efectos_pendientes, true);
    assertEquals(mock.cot?.estado, "Aprobada");
    assertEquals(mock.cot?.firma_nombre, "María López");
    assertEquals(mock.eventos.length, 2);
    assert(mock.eventos[0].evento.includes("Aprobada por el cliente desde el portal"));
    assert(mock.eventos[1].evento.includes("Aprobada desde el portal — efectos pendientes: Fallo simulado en servicio"));
  } finally {
    console.error = originalConsoleError;
  }
});

Deno.test("portal_aprobacion: firma vacía o ausente devuelve 400 sin tocar BD", async () => {
  const mock = crearMockSupabasePortal({
    id: "cot-6",
    organizacion_id: "org-1",
    token_publico: "tok-6",
    token_expira_en: "2026-12-21T00:00:00.000Z",
    estado: "Enviada",
  });

  const resNombreVacio = await aprobarPorPortal(mock, {
    token: "tok-6",
    firma_nombre: "   ",
    firma_imagen: "data:image/png;base64,AAA=",
  });
  assertEquals(resNombreVacio.status, 400);
  assertEquals(resNombreVacio.body.codigo, "FIRMA_REQUERIDA");

  const resImagenAusente = await aprobarPorPortal(mock, {
    token: "tok-6",
    firma_nombre: "Juan",
    firma_imagen: "",
  });
  assertEquals(resImagenAusente.status, 400);
  assertEquals(resImagenAusente.body.codigo, "FIRMA_REQUERIDA");
  assertEquals(mock.cot?.estado, "Enviada");
});

Deno.test("portal_aprobacion: rechazo y solicitud de cambios registran eventos con IP y fecha y respetan estado Enviada", async () => {
  const mockRechazo = crearMockSupabasePortal({
    id: "cot-7",
    organizacion_id: "org-1",
    token_publico: "tok-7",
    token_expira_en: "2026-12-21T00:00:00.000Z",
    estado: "Enviada",
  });

  const resRech = await rechazarPorPortal(
    mockRechazo,
    { token: "tok-7", comentario: "Precio alto", firma_ip: "1.2.3.4" },
    { ahora: () => FECHA_FIJA },
  );
  assertEquals(resRech.status, 200);
  assertEquals(mockRechazo.cot?.estado, "Cancelada");
  assert(mockRechazo.eventos[0].evento.includes("Rechazada por el cliente desde el portal"));
  assert(mockRechazo.eventos[0].evento.includes("Precio alto"));

  const mockCambios = crearMockSupabasePortal({
    id: "cot-8",
    organizacion_id: "org-1",
    token_publico: "tok-8",
    token_expira_en: "2026-12-21T00:00:00.000Z",
    estado: "Enviada",
  });

  const resCamb = await solicitarCambiosPorPortal(
    mockCambios,
    { token: "tok-8", comentario: "Agregar redilas", firma_ip: "5.6.7.8" },
    { ahora: () => FECHA_FIJA },
  );
  assertEquals(resCamb.status, 200);
  assertEquals(mockCambios.cot?.comentario_cliente, "Agregar redilas");
  assert(mockCambios.eventos[0].evento.includes("Cambios solicitados por el cliente desde el portal"));
});

Deno.test("ejecutarAprobacionCotizacion: idempotente en reintentos, no duplica evento ni degrada estado_produccion", async () => {
  const mock = crearMockSupabasePortal({
    id: "cot-idem",
    organizacion_id: "org-1",
    token_publico: "tok-idem",
    token_expira_en: null,
    estado: "Aprobada",
    estado_produccion: "En Producción",
  });

  await ejecutarAprobacionCotizacion(mock, "cot-idem", "org-1", null);
  await ejecutarAprobacionCotizacion(mock, "cot-idem", "org-1", null);

  // No degradó estado_produccion de 'En Producción' a 'Aprobada'
  assertEquals(mock.cot?.estado_produccion, "En Producción");
  // No duplicó el evento 'Cotizacion aprobada'
  const eventosAprob = mock.eventos.filter((e) => e.evento === "Cotizacion aprobada");
  assertEquals(eventosAprob.length, 1);
});
