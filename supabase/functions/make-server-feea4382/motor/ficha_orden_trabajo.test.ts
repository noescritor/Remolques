import { assertEquals } from "https://deno.land/std@0.168.0/testing/asserts.ts";
import { construirFichaOrdenTrabajo, formatearCantidadTexto } from "./ficha_orden_trabajo.ts";
import type { DatosModelo } from "./tipos.ts";

// Cargar fixture real de catálogo
const rawDatosModelo = JSON.parse(
  await Deno.readTextFile(new URL("./fixtures/datos_modelo.json", import.meta.url))
);

Deno.test("Prueba obligatoria formato real (Plana #2)", () => {
  const item = {
    descripcion: "Plataforma 40 ft 2 ejes",
    configuracion: {
      grupos: {
        eje: "fleet_master",
        suspension: "fleet_master",
        patin: "hj",
        piso: "plastico_cafe",
        riel: "con_riel",
        matracas: { opcion: "corrediza", cantidad: 10 },
        gancho: "holland_8_10",
        frente: { opcion: "concha_laminada", medida: "1.20" },
        retractil: { opcion: "retractil", cantidad: 1 },
        color: "rojo",
        redilas: "80",
        adicionales: [
          { opcion: "caja_herr_chica", cantidad: 1 }
        ]
      }
    }
  };

  const cotizacion = {
    folio: "COT-2025-001",
    descripcion: "Plana #2",
    fecha: "2025-12-02",
    firma_fecha: "2025-12-02"
  };

  const cliente = {
    nombre_razon_social: "AGUSTIN ANDRADE",
    telefono: "775 144 0407",
    correo: ""
  };

  const ficha = construirFichaOrdenTrabajo({
    item,
    cotizacion,
    cliente,
    datosModelo: rawDatosModelo as DatosModelo
  });

  // Cabecera
  assertEquals(ficha.cabecera.cliente, "AGUSTIN ANDRADE");
  assertEquals(ficha.cabecera.telefono, "775 144 0407");
  assertEquals(ficha.cabecera.numero_pedido, "COT-2025-001");
  assertEquals(ficha.cabecera.nombre_proyecto, "Plana #2");
  assertEquals(ficha.cabecera.fecha_pedido, "02/12/25");
  assertEquals(ficha.cabecera.pedido_recibido_por, "");

  // Cantidad texto
  assertEquals(ficha.cantidad_texto, "Una Plataforma 40 ft 2 ejes");

  // 14 Características
  const carValores = ficha.caracteristicas.map(c => c.valor);
  assertEquals(carValores, [
    "Fleet Master",
    "Fleet Master",
    "Dos HJ",
    "Plástico café",
    "Con 10 winches",
    "Holland",
    "Concha a 1.20 mts.",
    "Uno",
    "Uno",
    "Una",
    "Un par",
    "Rojo",
    "No aplica",
    "No aplica"
  ]);

  // 4 Accesorios Extra
  const accValores = ficha.accesorios_extra.map(a => a.valor);
  assertEquals(accValores, [
    "No aplica",
    "No aplica",
    "No aplica",
    "No aplica"
  ]);

  // Nota
  assertEquals(ficha.nota, "Redillas a 80 cm");

  // Congelado
  assertEquals(Object.isFrozen(ficha), true);
});

Deno.test("Dolly 2 ejes sin piso, frente ni patines", () => {
  const datosDolly: DatosModelo = {
    ...rawDatosModelo,
    modelo: {
      id: "mod-dolly",
      tipo: "dolly",
      largo_ft: 0,
      num_ejes: 2,
      nombre: "DOLLY 2 EJES"
    }
  };

  const item = {
    descripcion: "Dolly 2 ejes",
    configuracion: {
      grupos: {
        eje: "fleet_master",
        suspension: "fleet_master",
        color: "blanco"
      }
    }
  };

  const ficha = construirFichaOrdenTrabajo({
    item,
    cotizacion: { folio: "COT-100", descripcion: "Dolly H" },
    cliente: { nombre_razon_social: "Transportes MX" },
    datosModelo: datosDolly
  });

  assertEquals(ficha.cantidad_texto, "Un Dolly 2 ejes");

  const mapaCar = Object.fromEntries(ficha.caracteristicas.map(c => [c.etiqueta, c.valor]));
  assertEquals(mapaCar["EJES"], "Fleet Master");
  assertEquals(mapaCar["SUSPENSIÓN"], "Fleet Master");
  assertEquals(mapaCar["PATINES"], "No aplica");
  assertEquals(mapaCar["PISO"], "No aplica");
  assertEquals(mapaCar["FRENTE"], "No aplica");
  assertEquals(mapaCar["PORTALLANTAS"], "No aplica");
  assertEquals(mapaCar["LODERAS"], "Un par");
  assertEquals(mapaCar["COLOR"], "Blanco");
});

Deno.test("Góndola 3 ejes con rines y llantas mixtos", () => {
  const datosGondola: DatosModelo = {
    ...rawDatosModelo,
    modelo: {
      id: "mod-gondola",
      tipo: "gondola",
      largo_ft: 30,
      num_ejes: 3,
      nombre: "GONDOLA 30 FT 3 EJES"
    }
  };

  const item = {
    descripcion: "Góndola 3 ejes",
    configuracion: {
      grupos: {
        eje: "fleet_master",
        suspension: "fleet_master",
        color: "rojo_claro",
        pintura: "sherwin_williams",
        rines: [
          { opcion: "acero", marca: "Ampro", cantidad: 8 },
          { opcion: "aluminio", marca: "Ampro", cantidad: 4 }
        ],
        llantas: [
          { opcion: "cerex", cantidad: 8 },
          { opcion: "firestone", cantidad: 4 }
        ]
      }
    }
  };

  const ficha = construirFichaOrdenTrabajo({
    item,
    cotizacion: { folio: "COT-200" },
    cliente: { nombre_razon_social: "Minera del Norte" },
    datosModelo: datosGondola
  });

  assertEquals(ficha.cantidad_texto, "Una Góndola 30 ft 3 ejes");

  const mapaCar = Object.fromEntries(ficha.caracteristicas.map(c => [c.etiqueta, c.valor]));
  assertEquals(mapaCar["COLOR"].includes("Rojo claro"), true);
  assertEquals(mapaCar["PISO"], "No aplica");
  assertEquals(mapaCar["RIEL"], "No aplica");
  assertEquals(mapaCar["GANCHO"], "No aplica");
  assertEquals(mapaCar["FRENTE"], "No aplica");

  const mapaAcc = Object.fromEntries(ficha.accesorios_extra.map(a => [a.etiqueta, a.valor]));
  assertEquals(mapaAcc["RINES"], "8 de acero Ampro y 4 de aluminio Ampro");
  assertEquals(mapaAcc["LLANTAS"], "8 Cerex y 4 Firestone");
});

Deno.test("Dolly con ejes y suspensión no elegidos devuelve 'Por definir'", () => {
  const datosDolly: DatosModelo = {
    ...rawDatosModelo,
    modelo: {
      id: "mod-dolly",
      tipo: "dolly",
      largo_ft: 0,
      num_ejes: 2,
      nombre: "DOLLY 2 EJES"
    }
  };

  const item = {
    descripcion: "Dolly 2 ejes",
    configuracion: {
      grupos: {
        color: "blanco"
      }
    }
  };

  const ficha = construirFichaOrdenTrabajo({
    item,
    cotizacion: { folio: "COT-101", descripcion: "Dolly sin ejes" },
    cliente: { nombre_razon_social: "Transportes MX" },
    datosModelo: datosDolly
  });

  const mapaCar = Object.fromEntries(ficha.caracteristicas.map(c => [c.etiqueta, c.valor]));
  assertEquals(mapaCar["EJES"], "Por definir");
  assertEquals(mapaCar["SUSPENSIÓN"], "Por definir");
  assertEquals(mapaCar["PATINES"], "No aplica");
  assertEquals(mapaCar["PISO"], "No aplica");
  assertEquals(mapaCar["RIEL"], "No aplica");
  assertEquals(mapaCar["GANCHO"], "No aplica");
  assertEquals(mapaCar["FRENTE"], "No aplica");
});

Deno.test("Equipo sin configuración devuelve 'Por definir' sin romper", () => {
  const item = {
    descripcion: "Equipo sin configurar",
    configuracion: null
  };

  const ficha = construirFichaOrdenTrabajo({
    item,
    cotizacion: null,
    cliente: null,
    datosModelo: rawDatosModelo as DatosModelo
  });

  const mapaCar = Object.fromEntries(ficha.caracteristicas.map(c => [c.etiqueta, c.valor]));
  assertEquals(mapaCar["EJES"], "Por definir");
  assertEquals(mapaCar["SUSPENSIÓN"], "Por definir");
  assertEquals(mapaCar["PATINES"], "Por definir");
  assertEquals(mapaCar["COLOR"], "Por definir");
  assertEquals(ficha.nota, "");
});

Deno.test("Compatibilidad con configuraciones de forma vieja (strings planos)", () => {
  const item = {
    descripcion: "Plataforma vieja",
    configuracion: {
      grupos: {
        eje: "fleet_master",
        suspension: "fleet_master",
        patin: "hj",
        color: "rojo"
      }
    }
  };

  const ficha = construirFichaOrdenTrabajo({
    item,
    datosModelo: rawDatosModelo as DatosModelo
  });

  const mapaCar = Object.fromEntries(ficha.caracteristicas.map(c => [c.etiqueta, c.valor]));
  assertEquals(mapaCar["EJES"], "Fleet Master");
  assertEquals(mapaCar["SUSPENSIÓN"], "Fleet Master");
  assertEquals(mapaCar["PATINES"], "Dos HJ");
  assertEquals(mapaCar["COLOR"], "Rojo");
});

Deno.test("formatearCantidadTexto formatos válidos", () => {
  assertEquals(formatearCantidadTexto({ tipo: "plataforma", largo_ft: 40, num_ejes: 2 }), "Una Plataforma 40 ft 2 ejes");
  assertEquals(formatearCantidadTexto({ tipo: "dolly", num_ejes: 2 }), "Un Dolly 2 ejes");
  assertEquals(formatearCantidadTexto({ tipo: "gondola", num_ejes: 3 }), "Una Góndola 3 ejes");
});
