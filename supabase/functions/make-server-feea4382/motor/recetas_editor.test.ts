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
