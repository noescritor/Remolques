// @ts-nocheck
import { assertEquals, assert, assertThrows } from "https://deno.land/std@0.192.0/testing/asserts.ts";
import {
  medidaFtAMm,
  determinarTipoMaterial,
  normalizarNombreMaterial,
  parsearMedidaLamina,
  costoPieza,
  compararProveedores,
  FACTOR_PLACA_DEFECTO
} from "./aceroCalc.ts";

// ─── 1. Pruebas de medidaFtAMm ──────────────────────────────────────────────────
Deno.test("aceroCalc - medidaFtAMm: tabla explícita del cliente y conversión redondeada", () => {
  // Valores explícitos del Excel del cliente
  assertEquals(medidaFtAMm(4), 1219);
  assertEquals(medidaFtAMm(5), 1523);
  assertEquals(medidaFtAMm(10), 3050);

  // Valores redondeados con round(ft * 304.8)
  assertEquals(medidaFtAMm(3), 914);
  assertEquals(medidaFtAMm(20), 6096);
  assertEquals(medidaFtAMm(40), 12192);
});

// ─── 2. Pruebas de parsearMedidaLamina ──────────────────────────────────────────
Deno.test("aceroCalc - parsearMedidaLamina: extrae medidas de los 14 nombres de placa/lámina", () => {
  const nombresValidos = [
    { nombre: 'Lamina Negra Cal. 10 4X10\'', esperado: { anchoFt: 4, largoFt: 10 } },
    { nombre: 'Placa de grado A-36 de 3/16" en 5X10\'', esperado: { anchoFt: 5, largoFt: 10 } },
    { nombre: 'Placa de grado A-36 de 3/16" en 4X10\'', esperado: { anchoFt: 4, largoFt: 10 } },
    { nombre: 'Placa de grado A-36 de 3/16" en 3X10\'', esperado: { anchoFt: 3, largoFt: 10 } },
    { nombre: 'Placa de grado A-572°50 de 1/4" en 4X40\'', esperado: { anchoFt: 4, largoFt: 40 } },
    { nombre: 'Placa de grado A-572-50 de 1/4" en 4X40\'', esperado: { anchoFt: 4, largoFt: 40 } },
    { nombre: 'Placa de grado A-36 de 1/4" en 5X20\'', esperado: { anchoFt: 5, largoFt: 20 } },
    { nombre: 'Placa de grado A-36 de 1/4" en 5X10\'', esperado: { anchoFt: 5, largoFt: 10 } },
    { nombre: 'Placa de grado A-36 de 1/4" en 4X10\'', esperado: { anchoFt: 4, largoFt: 10 } },
    { nombre: 'Placa de grado A-36 de 3/8" en 4X10\'', esperado: { anchoFt: 4, largoFt: 10 } },
    { nombre: 'Placa de grado A-36 de 1/2" en 5X20\'', esperado: { anchoFt: 5, largoFt: 20 } },
    { nombre: 'Placa de grado A-36 de 1/2" en 5X10\'', esperado: { anchoFt: 5, largoFt: 10 } },
    { nombre: 'Lamina Negra Cal. 12 4X10\'', esperado: { anchoFt: 4, largoFt: 10 } },
    { nombre: 'Lamina Negra Cal. 14 4X10\'', esperado: { anchoFt: 4, largoFt: 10 } },
  ];

  for (const { nombre, esperado } of nombresValidos) {
    const res = parsearMedidaLamina(nombre);
    assert(res !== null, `Debe extraer medidas de: ${nombre}`);
    assertEquals(res.anchoFt, esperado.anchoFt, `anchoFt incorrecto para: ${nombre}`);
    assertEquals(res.largoFt, esperado.largoFt, `largoFt incorrecto para: ${nombre}`);
  }

  // Materiales que no son lámina/placa o no tienen medida en pies deben devolver null
  assertEquals(parsearMedidaLamina('Canal "U" de 6" (15Kg) a 12.20m'), null);
  assertEquals(parsearMedidaLamina('PTR 6X4" Cal. 3/16 a 12.20m'), null);
  assertEquals(parsearMedidaLamina('PTR de 6X2" Cal. 3/16"'), null);
  assertEquals(parsearMedidaLamina('Solera 3/8 X 2"'), null);
  assertEquals(parsearMedidaLamina('Redondo 1-1/2"'), null);
  assertEquals(parsearMedidaLamina(''), null);
});

// ─── 3. Pruebas de determinarTipoMaterial y normalizarNombreMaterial ──────────
Deno.test("aceroCalc - determinarTipoMaterial: clasifica correctamente los tipos", () => {
  assertEquals(determinarTipoMaterial('Placa de grado A-36 de 3/16" en 5X10\''), 'placa');
  assertEquals(determinarTipoMaterial('Lamina Negra Cal. 10 4X10\''), 'lamina');
  assertEquals(determinarTipoMaterial('Solera 1/2 X 3"'), 'solera');
  assertEquals(determinarTipoMaterial('Canal "U" de 6" (15Kg) a 12.20m'), 'canal');
  assertEquals(determinarTipoMaterial('PTR 6X4" Cal. 3/16 a 12.20m'), 'ptr');
  assertEquals(determinarTipoMaterial('Tubo negro mecanico Ced. 40 2"'), 'tubo');
  assertEquals(determinarTipoMaterial('Angulo 3/16 X 1-1/2" a 6.10m'), 'angulo');
  assertEquals(determinarTipoMaterial('Redondo 1-1/2"'), 'redondo');

  assertThrows(() => determinarTipoMaterial('Material Desconocido Invalido'));
});

Deno.test("aceroCalc - normalizarNombreMaterial: corrige caracter dañado en A-572°50", () => {
  assertEquals(
    normalizarNombreMaterial('Placa de grado A-572°50 de 1/4" en 4X40\''),
    'Placa de grado A-572-50 de 1/4" en 4X40\''
  );
  assertEquals(
    normalizarNombreMaterial('Placa de grado A-57250 de 1/4" en 4X40\''),
    'Placa de grado A-572-50 de 1/4" en 4X40\''
  );
});

// ─── 4. Pruebas de costoPieza ──────────────────────────────────────────────────
Deno.test("aceroCalc - costoPieza: prueba dorada del Excel (lámina 1/4\" 4X10')", () => {
  const input = {
    precioLamina: 4193.34,
    anchoLaminaMm: 1219, // 4 ft
    largoLaminaMm: 3050, // 10 ft
    anchoPiezaMm: 1250,
    largoPiezaMm: 1000,
    factor: 1.5,
  };

  const res = costoPieza(input);

  assertEquals(res.areaLaminaMm2, 3717950);
  assertEquals(res.areaPiezaMm2, 1250000);
  assertEquals(res.piezasPorArea, 2);

  // Verificación de tolerancia 1e-9 sobre el costo de la pieza
  const esperado = 2114.744012157237;
  const dif = Math.abs(res.costoPieza - esperado);
  assert(dif < 1e-9, `costoPieza ${res.costoPieza} difiere de ${esperado} en ${dif}`);

  // Costo por m²
  const m2Lamina = 3717950 / 1_000_000;
  assertEquals(res.costoPorM2, 4193.34 / m2Lamina);
});

Deno.test("aceroCalc - costoPieza: validaciones de entrada", () => {
  // Dimensiones negativas o cero
  assertThrows(() => costoPieza({ precioLamina: 0, anchoLaminaMm: 1000, largoLaminaMm: 2000, anchoPiezaMm: 100, largoPiezaMm: 100 }));
  assertThrows(() => costoPieza({ precioLamina: 100, anchoLaminaMm: -10, largoLaminaMm: 2000, anchoPiezaMm: 100, largoPiezaMm: 100 }));
  assertThrows(() => costoPieza({ precioLamina: 100, anchoLaminaMm: 1000, largoLaminaMm: 0, anchoPiezaMm: 100, largoPiezaMm: 100 }));
  assertThrows(() => costoPieza({ precioLamina: 100, anchoLaminaMm: 1000, largoLaminaMm: 2000, anchoPiezaMm: 0, largoPiezaMm: 100 }));
  assertThrows(() => costoPieza({ precioLamina: 100, anchoLaminaMm: 1000, largoLaminaMm: 2000, anchoPiezaMm: 100, largoPiezaMm: -5 }));

  // Factor menor a 1
  assertThrows(() => costoPieza({ precioLamina: 100, anchoLaminaMm: 1000, largoLaminaMm: 2000, anchoPiezaMm: 100, largoPiezaMm: 100, factor: 0.9 }));

  // Pieza mayor que la lámina por área
  assertThrows(() => costoPieza({ precioLamina: 100, anchoLaminaMm: 1000, largoLaminaMm: 1000, anchoPiezaMm: 1500, largoPiezaMm: 1000 }));
});

// ─── 5. Pruebas de compararProveedores ─────────────────────────────────────────
Deno.test("aceroCalc - compararProveedores: prueba dorada del Excel (TPI vs SERVIACERO)", () => {
  const renglones = [
    { materialId: 'm1', cantidad: 7 },  // Placa A-572
    { materialId: 'm2', cantidad: 28 }, // Solera 1/2 X 6"
    { materialId: 'm3', cantidad: 14 }, // Canal 15Kg
    { materialId: 'm4', cantidad: 4 },  // Canal 12Kg
    { materialId: 'm5', cantidad: 50 }, // Solera 3/8 X 2"
    { materialId: 'm6', cantidad: 18 }, // PTR 6X2" Cal 3/16
    { materialId: 'm7', cantidad: 9 },  // PTR 2X4" Cal 7
  ];

  const precios = [
    // TPI
    { material_id: 'm1', proveedor: 'TPI', precio: 19528.6 },
    { material_id: 'm2', proveedor: 'TPI', precio: 5016.0 },
    { material_id: 'm3', proveedor: 'TPI', precio: 5473.75 },
    { material_id: 'm4', proveedor: 'TPI', precio: 4140.9 },
    { material_id: 'm5', proveedor: 'TPI', precio: 626.18 },
    { material_id: 'm6', proveedor: 'TPI', precio: 2143.96 },
    { material_id: 'm7', proveedor: 'TPI', precio: 2047.27 },
    // SERVIACERO (a 2 decimales tal como en el ejemplo)
    { material_id: 'm1', proveedor: 'SERVIACERO', precio: 16876.03 },
    { material_id: 'm2', proveedor: 'SERVIACERO', precio: 4697.74 },
    { material_id: 'm3', proveedor: 'SERVIACERO', precio: 4822.17 },
    { material_id: 'm4', proveedor: 'SERVIACERO', precio: 3764.12 },
    { material_id: 'm5', proveedor: 'SERVIACERO', precio: 586.43 },
    { material_id: 'm6', proveedor: 'SERVIACERO', precio: 2108.12 },
    { material_id: 'm7', proveedor: 'SERVIACERO', precio: 1337.94 },
  ];

  // Caso 1: incluyeIva = false
  const resSinIva = compararProveedores({
    renglones,
    precios,
    incluyeIva: false,
    proveedores: ['TPI', 'SERVIACERO'],
  });

  const tpiSin = resSinIva.proveedores.find((p) => p.proveedor === 'TPI');
  const servSin = resSinIva.proveedores.find((p) => p.proveedor === 'SERVIACERO');

  assert(tpiSin && servSin);
  assertEquals(tpiSin.completo, true);
  assertEquals(servSin.completo, true);
  assertEquals(tpiSin.subtotal, 458670.01);
  assertEquals(tpiSin.total, 532057.21);
  assertEquals(servSin.subtotal, 411544.91);
  assertEquals(servSin.total, 477392.1);
  assertEquals(resSinIva.mejorProveedorCompleto?.proveedor, 'SERVIACERO');
  assertEquals(tpiSin.diferenciaContraMejor, 54665.12);

  // Caso 2: incluyeIva = true (por defecto)
  const resConIva = compararProveedores({
    renglones,
    precios,
    incluyeIva: true,
    proveedores: ['TPI', 'SERVIACERO'],
  });

  const tpiCon = resConIva.proveedores.find((p) => p.proveedor === 'TPI');
  const servCon = resConIva.proveedores.find((p) => p.proveedor === 'SERVIACERO');

  assert(tpiCon && servCon);
  assertEquals(tpiCon.total, 458670.01);
  assertEquals(servCon.total, 411544.91);
  assertEquals(resConIva.mejorProveedorCompleto?.proveedor, 'SERVIACERO');
  assertEquals(tpiCon.diferenciaContraMejor, 47125.1);

  // Compra mixta: en este ejemplo Serviacero es más barato en todos los renglones,
  // por lo que el total mixto es idéntico a Serviacero y el ahorro es 0
  assertEquals(resConIva.mejorPorRenglon.total, 411544.91);
  assertEquals(resConIva.mejorPorRenglon.ahorroContraMejorCompleto, 0);
});

Deno.test("aceroCalc - compararProveedores: proveedor incompleto y compra mixta con ahorro", () => {
  const renglones = [
    { materialId: 'm1', cantidad: 10 },
    { materialId: 'm2', cantidad: 5 },
  ];

  const precios = [
    // Tanos tiene precio en m1 pero NO en m2
    { material_id: 'm1', proveedor: 'TANOS', precio: 100 },
    // Fortacero tiene precio en ambos
    { material_id: 'm1', proveedor: 'FORTACERO', precio: 150 },
    { material_id: 'm2', proveedor: 'FORTACERO', precio: 200 },
  ];

  const res = compararProveedores({
    renglones,
    precios,
    incluyeIva: true,
    proveedores: ['TANOS', 'FORTACERO'],
    catalogoMateriales: { m2: { nombre: 'Solera 1/2' } }
  });

  const tanos = res.proveedores.find((p) => p.proveedor === 'TANOS');
  const fortacero = res.proveedores.find((p) => p.proveedor === 'FORTACERO');

  assert(tanos && fortacero);
  assertEquals(tanos.completo, false);
  assertEquals(tanos.materialesFaltantes, ['Solera 1/2']);
  assertEquals(tanos.diferenciaContraMejor, null);

  assertEquals(fortacero.completo, true);
  // Fortacero total = 10*150 + 5*200 = 1500 + 1000 = 2500
  assertEquals(fortacero.total, 2500);
  assertEquals(res.mejorProveedorCompleto?.proveedor, 'FORTACERO');

  // Compra mixta: toma m1 de Tanos (100) y m2 de Fortacero (200) -> 10*100 + 5*200 = 2000
  assertEquals(res.mejorPorRenglon.total, 2000);
  // Ahorro contra Fortacero (2500 - 2000 = 500)
  assertEquals(res.mejorPorRenglon.ahorroContraMejorCompleto, 500);
});

Deno.test("aceroCalc - compararProveedores: casos borde (lista vacía, cantidad 0)", () => {
  // Lista vacía
  const resVacia = compararProveedores({
    renglones: [],
    precios: [],
    proveedores: ['TPI'],
  });
  assertEquals(resVacia.mejorProveedorCompleto, null);
  assertEquals(resVacia.mejorPorRenglon.total, 0);

  // Cantidad 0 es ignorada
  const resCero = compararProveedores({
    renglones: [{ materialId: 'm1', cantidad: 0 }],
    precios: [{ material_id: 'm1', proveedor: 'TPI', precio: 100 }],
    proveedores: ['TPI'],
  });
  assertEquals(resCero.mejorProveedorCompleto, null);
});
