// @ts-nocheck
import { assertEquals } from "https://deno.land/std@0.192.0/testing/asserts.ts";
import {
  nombreClientePresupuesto,
  coincideBusquedaPresupuesto,
  normalizarTexto
} from "./presupuestoCliente.ts";

Deno.test("presupuestoCliente: normalizarTexto elimina acentos y pasa a minúsculas", () => {
  assertEquals(normalizarTexto("FERRETERA DEL CENTRO"), "ferretera del centro");
  assertEquals(normalizarTexto("Camión y Plataforma"), "camion y plataforma");
  assertEquals(normalizarTexto("MÉXICO ÁÉÍÓÚ"), "mexico aeiou");
});

Deno.test("presupuestoCliente: nombreClientePresupuesto con cliente embebido", () => {
  const p = {
    folio: "PRE-001",
    cliente: {
      nombre_comercial: "Ferretera del Centro",
      razon_social: "FDC S.A. DE C.V."
    }
  };
  assertEquals(nombreClientePresupuesto(p), "Ferretera del Centro");
});

Deno.test("presupuestoCliente: nombreClientePresupuesto solo con cliente_id (busca en clientes)", () => {
  const clientes = [
    { id: "cli-1", nombre_comercial: "Transportes del Norte", razon_social: "TDN S.A." },
    { id: "cli-2", razon_social: "Logística Express S.A. de C.V." }
  ];
  const p1 = { folio: "PRE-002", cliente_id: "cli-1" };
  assertEquals(nombreClientePresupuesto(p1, clientes), "Transportes del Norte");

  const p2 = { folio: "PRE-003", cliente_id: "cli-2" };
  assertEquals(nombreClientePresupuesto(p2, clientes), "Logística Express S.A. de C.V.");
});

Deno.test("presupuestoCliente: nombreClientePresupuesto cliente con solo razón social", () => {
  const p = {
    folio: "PRE-004",
    cliente: {
      nombre_comercial: null,
      razon_social: "Aceros y Perfiles de México S.A. de C.V."
    }
  };
  assertEquals(nombreClientePresupuesto(p), "Aceros y Perfiles de México S.A. de C.V.");
});

Deno.test("presupuestoCliente: nombreClientePresupuesto sin cliente (null o no encontrado) devuelve 'Sin cliente'", () => {
  assertEquals(nombreClientePresupuesto(null), "Sin cliente");
  assertEquals(nombreClientePresupuesto(undefined), "Sin cliente");
  assertEquals(nombreClientePresupuesto({ folio: "PRE-005", cliente_id: null }), "Sin cliente");
  assertEquals(nombreClientePresupuesto({ folio: "PRE-006", cliente_id: "inexistente" }, []), "Sin cliente");
  assertEquals(nombreClientePresupuesto({ folio: "PRE-007", cliente: null }), "Sin cliente");
  assertEquals(nombreClientePresupuesto({ folio: "PRE-008", cliente: { nombre_comercial: "", razon_social: "" } }), "Sin cliente");
});

Deno.test("presupuestoCliente: coincideBusquedaPresupuesto con texto vacío retorna true", () => {
  const p = { folio: "PRE-001", concepto: "Plataforma 40 ft" };
  assertEquals(coincideBusquedaPresupuesto(p, [], ""), true);
  assertEquals(coincideBusquedaPresupuesto(p, [], "   "), true);
  assertEquals(coincideBusquedaPresupuesto(p, [], null), true);
  assertEquals(coincideBusquedaPresupuesto(p, [], undefined), true);
});

Deno.test("presupuestoCliente: buscar por parte del nombre del cliente ('ferretera' encuentra 'FERRETERA DEL CENTRO')", () => {
  const p = {
    folio: "PRE-001",
    concepto: "Góndola 30 m3",
    cliente: { nombre_comercial: "FERRETERA DEL CENTRO" }
  };
  assertEquals(coincideBusquedaPresupuesto(p, [], "ferretera"), true);
  assertEquals(coincideBusquedaPresupuesto(p, [], "CENTRO"), true);
  assertEquals(coincideBusquedaPresupuesto(p, [], "del"), true);
  assertEquals(coincideBusquedaPresupuesto(p, [], "ferret"), true);
  assertEquals(coincideBusquedaPresupuesto(p, [], "otra cosa"), false);
});

Deno.test("presupuestoCliente: buscar cliente insensible a acentos", () => {
  const p = {
    folio: "PRE-002",
    cliente: { razon_social: "CONSTRUCCIÓN Y LOGÍSTICA DE MÉXICO" }
  };
  assertEquals(coincideBusquedaPresupuesto(p, [], "construccion"), true);
  assertEquals(coincideBusquedaPresupuesto(p, [], "logistica"), true);
  assertEquals(coincideBusquedaPresupuesto(p, [], "mexico"), true);
});

Deno.test("presupuestoCliente: búsqueda por folio y por concepto sigue funcionando igual que hoy", () => {
  const p = {
    folio: "PRE-2026-0042",
    concepto: "Plataforma 3 ejes 43 ft con piso plástico",
    nomenclatura_id: "PLAT-3E-43FT",
    cliente_id: null
  };

  // Por folio
  assertEquals(coincideBusquedaPresupuesto(p, [], "0042"), true);
  assertEquals(coincideBusquedaPresupuesto(p, [], "pre-2026"), true);
  assertEquals(coincideBusquedaPresupuesto(p, [], "PRE"), true);

  // Por concepto
  assertEquals(coincideBusquedaPresupuesto(p, [], "plataforma"), true);
  assertEquals(coincideBusquedaPresupuesto(p, [], "43 ft"), true);
  assertEquals(coincideBusquedaPresupuesto(p, [], "plastico"), true); // Sin acento busca palabra con acento

  // Por nomenclatura
  assertEquals(coincideBusquedaPresupuesto(p, [], "PLAT-3E"), true);
  assertEquals(coincideBusquedaPresupuesto(p, [], "43ft"), true);

  // No coincide
  assertEquals(coincideBusquedaPresupuesto(p, [], "dolly"), false);
  assertEquals(coincideBusquedaPresupuesto(p, [], "gondola"), false);
});
