import { assertEquals, assertRejects } from "https://deno.land/std@0.208.0/assert/mod.ts";
import {
  clonarRecetaMotor,
  guardarLineaRecetaMotor,
  eliminarLineaRecetaMotor,
  obtenerRecetaMotor
} from "./recetas_editor.ts";
import { resolverReceta } from "./resolver_receta.ts";
import type { DatosModelo } from "./tipos.ts";

Deno.test("recetas_editor: validaciones de entrada en clonarRecetaMotor", async () => {
  const fakeServiceClient = {
    rpc: async () => ({ data: "new-mod-id", error: null })
  };

  // Falta modeloOrigenId
  await assertRejects(
    async () => {
      await clonarRecetaMotor(fakeServiceClient, {
        modeloOrigenId: "",
        productoId: "REM-PLAT-47",
        nombre: "Plataforma 47",
        largoFt: 47,
        numEjes: 2
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
        numEjes: 2
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
        numEjes: 0
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
    numEjes: 2
  });
  assertEquals(res.modelo_id, "new-mod-id");
});

Deno.test("recetas_editor: guardarLineaRecetaMotor valida escala y cantidad", async () => {
  const fakeServiceClient = {
    rpc: async () => ({ data: "new-line-id", error: null })
  };

  // Cantidad <= 0
  await assertRejects(
    async () => {
      await guardarLineaRecetaMotor(fakeServiceClient, {
        modeloId: "mod-1",
        materialId: "mat-1",
        cantidad: 0,
        escala: "fija",
        faseId: "fase-1"
      });
    },
    Error,
    "cantidad debe ser un número positivo"
  );

  // Escala inválida
  await assertRejects(
    async () => {
      await guardarLineaRecetaMotor(fakeServiceClient, {
        modeloId: "mod-1",
        materialId: "mat-1",
        cantidad: 5,
        escala: "invalida" as any,
        faseId: "fase-1"
      });
    },
    Error,
    "escala inválida"
  );

  // Éxito
  const res = await guardarLineaRecetaMotor(fakeServiceClient, {
    modeloId: "mod-1",
    materialId: "mat-1",
    cantidad: 5,
    escala: "por_largo",
    faseId: "fase-1"
  });
  assertEquals(res.linea_id, "new-line-id");
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
        seccion: "ensamble"
      }
    ],
    grupos: [],
    opciones: [],
    opcion_componentes: []
  };

  const resOrigen = resolverReceta(modeloOrigen, { grupos: {} });
  assertEquals(resOrigen.completo, true);
  const vigaOrigen = resOrigen.lineas.find(l => l.material_id === "VIGA-PERALTE");
  const llantaOrigen = resOrigen.lineas.find(l => l.material_id === "LLANTA-11R24.5");
  assertEquals(vigaOrigen?.cantidad, 40); // 40 * (40/40) = 40
  assertEquals(llantaOrigen?.cantidad, 8); // 4 * 2 = 8

  // Modelo clonado de 47 ft / 3 ejes (cama plana de 47 pies)
  const modeloClonado: DatosModelo = {
    modelo: {
      id: "mod-clon-47",
      tipo: "plataforma",
      largo_ft: 47,
      num_ejes: 3,
      nombre: "CAMA PLANA 47 FT 3 EJES"
    },
    // Misma receta base clonada
    receta_base: [...modeloOrigen.receta_base],
    grupos: [],
    opciones: [],
    opcion_componentes: []
  };

  const resClon = resolverReceta(modeloClonado, { grupos: {} });
  assertEquals(resClon.completo, true);
  const vigaClon = resClon.lineas.find(l => l.material_id === "VIGA-PERALTE");
  const llantaClon = resClon.lineas.find(l => l.material_id === "LLANTA-11R24.5");

  // Viga escala con largo: 40 * (47/40) = 47
  assertEquals(vigaClon?.cantidad, 47);
  // Llantas escala con ejes: 4 * 3 = 12
  assertEquals(llantaClon?.cantidad, 12);

  // Asegurar que el origen no se modificó
  assertEquals(modeloOrigen.receta_base[0].cantidad, 40);
  assertEquals(modeloOrigen.modelo.largo_ft, 40);
});
