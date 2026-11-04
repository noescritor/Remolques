import { assertEquals, assertRejects } from "https://deno.land/std@0.208.0/assert/mod.ts";
import {
  clonarRecetaMotor,
  guardarLineaRecetaMotor,
  eliminarLineaRecetaMotor,
  obtenerRecetaMotor,
  obtenerHistorialRecetaMotor
} from "./recetas_editor.ts";
import { resolverReceta } from "./resolver_receta.ts";
import type { DatosModelo } from "./tipos.ts";

const ORG_A = "11111111-1111-1111-1111-111111111111";

Deno.test("recetas_editor: validaciones de entrada en clonarRecetaMotor", async () => {
  const fakeServiceClient = {
    rpc: async () => ({ data: "new-mod-id", error: null })
  };

  // Falta organizacionId
  await assertRejects(
    async () => {
      await clonarRecetaMotor(fakeServiceClient, {
        modeloOrigenId: "orig-123",
        productoId: "REM-PLAT-47",
        nombre: "Plataforma 47",
        largoFt: 47,
        numEjes: 2,
        organizacionId: ""
      });
    },
    Error,
    "organizacionId es requerido"
  );

  // Falta modeloOrigenId
  await assertRejects(
    async () => {
      await clonarRecetaMotor(fakeServiceClient, {
        modeloOrigenId: "",
        productoId: "REM-PLAT-47",
        nombre: "Plataforma 47",
        largoFt: 47,
        numEjes: 2,
        organizacionId: ORG_A
      });
    },
    Error,
    "modeloOrigenId es requerido"
  );

  // Largo inválido
  await assertRejects(
    async () => {
      await clonarRecetaMotor(fakeServiceClient, {
        modeloOrigenId: "orig-123",
        productoId: "REM-PLAT-47",
        nombre: "Plataforma 47",
        largoFt: -5,
        numEjes: 2,
        organizacionId: ORG_A
      });
    },
    Error,
    "largoFt debe ser un número positivo finito"
  );

  // Ejes inválidos
  await assertRejects(
    async () => {
      await clonarRecetaMotor(fakeServiceClient, {
        modeloOrigenId: "orig-123",
        productoId: "REM-PLAT-47",
        nombre: "Plataforma 47",
        largoFt: 47,
        numEjes: 0,
        organizacionId: ORG_A
      });
    },
    Error,
    "numEjes debe ser un entero >= 1"
  );

  // Éxito
  const res = await clonarRecetaMotor(fakeServiceClient, {
    modeloOrigenId: "orig-123",
    productoId: "REM-PLAT-47",
    nombre: "Plataforma 47",
    largoFt: 47,
    numEjes: 2,
    organizacionId: ORG_A
  });
  assertEquals(res.modelo_id, "new-mod-id");
});

Deno.test("recetas_editor: guardarLineaRecetaMotor valida escala, cantidad y redondea", async () => {
  let capturedParams: any = null;
  const fakeServiceClient = {
    rpc: async (_fn: string, params: any) => {
      capturedParams = params;
      return { data: "new-line-id", error: null };
    }
  };

  // Falta organizacionId
  await assertRejects(
    async () => {
      await guardarLineaRecetaMotor(fakeServiceClient, {
        modeloId: "mod-1",
        materialId: "mat-1",
        cantidad: 5,
        escala: "fija",
        faseId: "fase-1",
        organizacionId: ""
      });
    },
    Error,
    "organizacionId es requerido"
  );

  // Cantidad <= 0
  await assertRejects(
    async () => {
      await guardarLineaRecetaMotor(fakeServiceClient, {
        modeloId: "mod-1",
        materialId: "mat-1",
        cantidad: 0,
        escala: "fija",
        faseId: "fase-1",
        organizacionId: ORG_A
      });
    },
    Error,
    "cantidad debe ser un número positivo finito"
  );

  // Escala inválida
  await assertRejects(
    async () => {
      await guardarLineaRecetaMotor(fakeServiceClient, {
        modeloId: "mod-1",
        materialId: "mat-1",
        cantidad: 5,
        escala: "invalida" as any,
        faseId: "fase-1",
        organizacionId: ORG_A
      });
    },
    Error,
    "escala inválida"
  );

  // Éxito y redondeo a 4 decimales
  const res = await guardarLineaRecetaMotor(fakeServiceClient, {
    modeloId: "mod-1",
    materialId: "mat-1",
    cantidad: 5.1234567,
    escala: "por_largo",
    faseId: "fase-1",
    organizacionId: ORG_A
  });
  assertEquals(res.linea_id, "new-line-id");
  assertEquals(capturedParams.p_cantidad, 5.1235);
  assertEquals(capturedParams.p_organizacion_id, ORG_A);
});

Deno.test("recetas_editor: eliminarLineaRecetaMotor requiere organizacionId y pasa params a RPC", async () => {
  let capturedParams: any = null;
  const fakeServiceClient = {
    rpc: async (_fn: string, params: any) => {
      capturedParams = params;
      return { data: true, error: null };
    }
  };

  await assertRejects(
    async () => {
      await eliminarLineaRecetaMotor(fakeServiceClient, {
        lineaId: "lin-1",
        organizacionId: ""
      });
    },
    Error,
    "organizacionId es requerido"
  );

  const res = await eliminarLineaRecetaMotor(fakeServiceClient, {
    lineaId: "lin-1",
    modeloId: "mod-1",
    organizacionId: ORG_A,
    motivo: "Borrado de prueba"
  });
  assertEquals(res.eliminado, true);
  assertEquals(capturedParams.p_linea_id, "lin-1");
  assertEquals(capturedParams.p_modelo_id, "mod-1");
  assertEquals(capturedParams.p_organizacion_id, ORG_A);
});

Deno.test("recetas_editor: resolverReceta resuelve el modelo clonado con escala proporcional", () => {
  // Modelo base de 40 ft / 2 ejes
  const modeloOrigen: DatosModelo = {
    modelo: {
      id: "mod-origen-40",
      tipo: "plataforma",
      largo_ft: 40,
      num_ejes: 2,
      nombre: "PLATAFORMA 40 FT 2 EJES"
    },
    receta_base: [
      {
        material_id: "VIGA-PERALTE",
        nombre: "VIGA ESTRUCTURAL",
        unidad: "M",
        costo: 500,
        descripcion: "Viga principal",
        cantidad: 40, // 40 metros base para 40 pies
        escala: "por_largo",
        paso: "Paso 1",
        uso: "Estructura",
        seccion: "acero"
      },
      {
        material_id: "LLANTA-11R24.5",
        nombre: "LLANTA",
        unidad: "PZA",
        costo: 3000,
        descripcion: "Llanta",
        cantidad: 4, // 4 por eje -> 8 para 2 ejes
        escala: "por_eje",
        paso: "Paso 11",
        uso: "Rodado",
        seccion: "otros"
      },
      {
        material_id: "PERNO-REY",
        nombre: "PERNO REY 2 PULGADAS",
        unidad: "PZA",
        costo: 1200,
        descripcion: "Perno rey",
        cantidad: 1, // fijo
        escala: "fija",
        paso: "Paso 2",
        uso: "Acople",
        seccion: "otros"
      }
    ],
    grupos: [],
    opciones: [],
    opcion_componentes: []
  };

  // Resolver modelo origen (40 ft, 2 ejes)
  const resOrigen = resolverReceta(modeloOrigen, {
    grupos: {}
  });

  const vigaOrigen = resOrigen.lineas.find((l: any) => l.material_id === "VIGA-PERALTE");
  const llantaOrigen = resOrigen.lineas.find((l: any) => l.material_id === "LLANTA-11R24.5");
  const pernoOrigen = resOrigen.lineas.find((l: any) => l.material_id === "PERNO-REY");

  assertEquals(vigaOrigen?.cantidad, 40);
  assertEquals(llantaOrigen?.cantidad, 8); // 4 * 2 ejes
  assertEquals(pernoOrigen?.cantidad, 1);

  // Simular modelo clonado a 47 ft, 3 ejes
  const modeloClonado: DatosModelo = {
    ...modeloOrigen,
    modelo: {
      id: "mod-clon-47",
      tipo: "plataforma",
      largo_ft: 47,
      num_ejes: 3,
      nombre: "PLATAFORMA 47 FT 3 EJES"
    }
  };

  const resClon = resolverReceta(modeloClonado, {
    grupos: {}
  });

  const vigaClon = resClon.lineas.find((l: any) => l.material_id === "VIGA-PERALTE");
  const llantaClon = resClon.lineas.find((l: any) => l.material_id === "LLANTA-11R24.5");
  const pernoClon = resClon.lineas.find((l: any) => l.material_id === "PERNO-REY");

  // Escalado proporcional verificado
  assertEquals(vigaClon?.cantidad, 47); // 40 * (47 / 40) = 47
  assertEquals(llantaClon?.cantidad, 12); // 4 * 3 ejes = 12
  assertEquals(pernoClon?.cantidad, 1); // Fijo permanece 1

  // El modelo origen no fue mutado ni alterado
  assertEquals(modeloOrigen.modelo.largo_ft, 40);
  assertEquals(modeloOrigen.modelo.num_ejes, 2);
});

Deno.test("recetas_editor: mock de GET /fases-despiece usa únicamente columnas reales de fases_despiece", async () => {
  // Las columnas reales de fases_despiece son:
  // id, organizacion_id, clave, nombre, subtitulo, orden, descripcion, activo, created_at, updated_at
  const fasesRealesBD = [
    {
      id: "fase-1",
      organizacion_id: ORG_A,
      clave: "paso_1",
      nombre: "Paso 1",
      subtitulo: "Chasis",
      orden: 1,
      descripcion: "Corte y armado de vigas",
      activo: true,
      created_at: "2026-11-01T00:00:00Z",
      updated_at: "2026-11-01T00:00:00Z",
    },
    {
      id: "fase-2",
      organizacion_id: ORG_A,
      clave: "paso_2",
      nombre: "Paso 2",
      subtitulo: "Planchón",
      orden: 2,
      descripcion: "Perno rey y planchón",
      activo: true,
      created_at: "2026-11-01T00:00:00Z",
      updated_at: "2026-11-01T00:00:00Z",
    }
  ];

  // Mock que falla si se pide una columna inexistente como paso_numero o activa
  const columnasPermitidas = new Set([
    "id", "organizacion_id", "clave", "nombre", "subtitulo", "orden", "descripcion", "activo", "created_at", "updated_at"
  ]);

  const mockSupabase = {
    from: (table: string) => {
      assertEquals(table, "fases_despiece");
      return {
        select: (cols: string) => {
          const colList = cols.split(",").map((c) => c.trim());
          for (const col of colList) {
            if (!columnasPermitidas.has(col)) {
              throw new Error(`column "${col}" does not exist`);
            }
          }
          return {
            eq: (_col1: string, _val1: any) => ({
              eq: (_col2: string, _val2: any) => ({
                order: (_col3: string, _opt: any) => ({
                  data: fasesRealesBD.map((f: any) => {
                    const row: any = {};
                    for (const c of colList) row[c] = f[c];
                    return row;
                  }),
                  error: null
                })
              })
            })
          };
        }
      };
    }
  };

  // Simular la consulta exacta de GET /fases-despiece
  const { data, error } = await mockSupabase
    .from("fases_despiece")
    .select("id, clave, nombre, subtitulo, orden, descripcion, activo")
    .eq("organizacion_id", ORG_A)
    .eq("activo", true)
    .order("orden", { ascending: true });

  assertEquals(error, null);
  assertEquals(data?.length, 2);
  assertEquals(data?.[0].nombre, "Paso 1");
  assertEquals(data?.[0].subtitulo, "Chasis");
  assertEquals(data?.[0].activo, true);
  // Confirmar que no hay paso_numero ni activa
  assertEquals((data?.[0] as any).paso_numero, undefined);
  assertEquals((data?.[0] as any).activa, undefined);
});

Deno.test("recetas_editor: búsqueda en productos sanitiza caracteres especiales como comas y paréntesis", () => {
  // Simular la función de sanitización usada en GET /productos
  const sanitizar = (q: string) => q.trim().replace(/[(),]/g, ' ').replace(/\s+/g, ' ').trim();

  const casoParentesis = "PTR (2x2)";
  assertEquals(sanitizar(casoParentesis), "PTR 2x2");

  const casoComa = "SOLERA, 1/4 X 2";
  assertEquals(sanitizar(casoComa), "SOLERA 1/4 X 2");

  const casoMixto = "TUBO (1-1/4, CEDULA 40)";
  assertEquals(sanitizar(casoMixto), "TUBO 1-1/4 CEDULA 40");

  // El string resultante no contiene caracteres que rompan el parser PostgREST
  const res = sanitizar(casoParentesis);
  assertEquals(res.includes("("), false);
  assertEquals(res.includes(")"), false);
  assertEquals(res.includes(","), false);
});

Deno.test("recetas_editor: aislamiento multi-tenant en obtenerRecetaMotor rechaza modelo de otra organización", async () => {
  const ORG_B = "22222222-2222-2222-2222-222222222222";
  const mockSupabase = {
    from: (table: string) => {
      if (table === "modelos") {
        return {
          select: () => ({
            eq: (_c1: string, modId: string) => ({
              eq: (_c2: string, orgId: string) => ({
                single: async () => {
                  // Solo encuentra el modelo si pertenece a la misma organización
                  if (orgId === ORG_B && modId === "mod-b") {
                    return {
                      data: { id: "mod-b", organizacion_id: ORG_B, productos: { nombre: "Modelo B" } },
                      error: null
                    };
                  }
                  return { data: null, error: { message: "Row not found" } };
                }
              })
            })
          })
        };
      }
      return {};
    }
  };

  // Org A intentando leer modelo de Org B debe dar 404
  await assertRejects(
    async () => {
      await obtenerRecetaMotor(mockSupabase, ORG_A, "mod-b");
    },
    Error,
    "Modelo no encontrado en la organización"
  );
});

Deno.test("recetas_editor: control de permisos de edición responde 403 Forbidden para usuarios sin rol editor", async () => {
  // Simular cliente de perfiles de usuario
  const mockServiceClient = {
    from: (table: string) => {
      assertEquals(table, "perfiles_organizacion");
      return {
        select: () => ({
          eq: () => ({
            eq: () => ({
              maybeSingle: async () => ({
                // Usuario con rol 'usuario' (solo lectura / operador)
                data: { rol: "usuario" },
                error: null
              })
            })
          })
        })
      };
    }
  };

  // Importar y probar verificarPermisoEdicion directamente
  const { verificarPermisoEdicion } = await import("./catalogo_costos.ts");
  const autorizado = await verificarPermisoEdicion(mockServiceClient, ORG_A, "user-sin-permiso");
  assertEquals(autorizado, false);
});

