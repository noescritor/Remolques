// @ts-nocheck
import { assertEquals } from "https://deno.land/std@0.192.0/testing/asserts.ts";
import {
  esProductoSinCosto,
  calcularCategoriasConConteo,
  filtrarProductosCatalogo,
} from "./catalogoProductos.ts";

const CATEGORIAS_MOCK = [
  { id: "cat-terminados", nombre: "Remolques terminados", color: "#10b981" },
  { id: "cat-refacciones", nombre: "Refacciones", color: "#3b82f6" },
  { id: "cat-materias", nombre: "Materias primas", color: "#f59e0b" },
  { id: "cat-acero", nombre: "Acero", color: "#ef4444" },
  { id: "cat-vacia", nombre: "Categoría Vacía", color: "#8b5cf6" },
];

const PRODUCTOS_MOCK = [
  // 3 terminados
  { id: "p1", nombre: "Plataforma 40 ft 2 ejes", categoria_id: "cat-terminados", costo: 350000, precio_unitario: 450000 },
  { id: "p2", nombre: "Plataforma 40 ft 3 ejes", categoria_id: "cat-terminados", costo: 390000, precio_unitario: 510000 },
  { id: "p3", nombre: "Dolly H", categoria_id: "cat-terminados", costo: 180000, precio_unitario: 240000 },

  // 2 refacciones
  { id: "p4", nombre: "Lámpara LED 4 pulgadas", categoria_id: "cat-refacciones", costo: 150, precio_unitario: 220 },
  { id: "p5", nombre: "Matraca autoajustable", categoria_id: "cat-refacciones", costo: 850, precio_unitario: 1200 },

  // 5 materias primas
  { id: "p6", nombre: "Perno rey 2 pulgadas", categoria_id: "cat-materias", costo: 1200, precio_unitario: 1800 },
  { id: "p7", nombre: "Balero exterior", categoria_id: "cat-materias", costo: 350, precio_unitario: 500 },
  { id: "p8", nombre: "Retén de grasa", categoria_id: "cat-materias", costo: 90, precio_unitario: 140 },
  { id: "p9", nombre: "Tornillo 5/8 x 3", categoria_id: "cat-materias", costo: 18, precio_unitario: 30 },
  { id: "p10", nombre: "Arandela de presión", categoria_id: "cat-materias", costo: 5, precio_unitario: 10 },

  // 1 acero con categoria
  { id: "p11", nombre: "Solera 2 x 1/4", categoria_id: "cat-acero", costo: 180, precio_unitario: 250 },

  // 4 productos cargados sin categoria_id (BOM)
  { id: "p12", nombre: 'Viga IPR 4" x 102"', categoria_id: null, costo: 1250, precio_unitario: 0 },
  { id: "p13", nombre: "Pintura PPG Epóxica", categoria_id: null, costo: 0, precio_unitario: 0 }, // Sin costo cargado
  { id: "p14", nombre: "Puente suspensión PTR 6x2", categoria_id: null, costo: null, precio_unitario: 0 }, // Sin costo cargado
  { id: "p15", nombre: "Consumible microalambre", categoria_id: "ninguna", costo: 0, precio_unitario: 0 }, // Sin costo cargado
];

Deno.test("catalogoProductos - 1. esProductoSinCosto detecta null, undefined, 0 y valores no finitos", () => {
  assertEquals(esProductoSinCosto({ id: "1", nombre: "A", costo: null }), true);
  assertEquals(esProductoSinCosto({ id: "2", nombre: "B", costo: 0 }), true);
  assertEquals(esProductoSinCosto({ id: "3", nombre: "C", costo: undefined }), true);
  assertEquals(esProductoSinCosto({ id: "4", nombre: "D", costo: -50 }), true);
  assertEquals(esProductoSinCosto({ id: "5", nombre: "E", costo: 100 }), false);
  assertEquals(esProductoSinCosto(null), true);
});

Deno.test("catalogoProductos - 2. calcularCategoriasConConteo genera conteos exactos y omite categorías vacías", () => {
  const resumen = calcularCategoriasConConteo(PRODUCTOS_MOCK, CATEGORIAS_MOCK);

  assertEquals(resumen.todasCount, 15);
  assertEquals(resumen.sinCategoriaCount, 4); // p12, p13, p14, p15
  assertEquals(resumen.sinCostoCount, 3); // p13 (0), p14 (null), p15 (0)

  // cat-vacia debe ser excluida porque count === 0
  assertEquals(resumen.categoriasConDatos.length, 4);

  const term = resumen.categoriasConDatos.find((c) => c.id === "cat-terminados");
  assertEquals(term?.count, 3);

  const ref = resumen.categoriasConDatos.find((c) => c.id === "cat-refacciones");
  assertEquals(ref?.count, 2);

  const mat = resumen.categoriasConDatos.find((c) => c.id === "cat-materias");
  assertEquals(mat?.count, 5);

  const ace = resumen.categoriasConDatos.find((c) => c.id === "cat-acero");
  assertEquals(ace?.count, 1);
});

Deno.test("catalogoProductos - 3. filtrarProductosCatalogo filtra por sin_categoria y soloSinCosto", () => {
  // Filtro sin_categoria
  const sinCat = filtrarProductosCatalogo(PRODUCTOS_MOCK, { categoriaActiva: "sin_categoria" });
  assertEquals(sinCat.length, 4);

  // Filtro soloSinCosto (debe traer las 3 piezas sin costo de las 15)
  const sinCosto = filtrarProductosCatalogo(PRODUCTOS_MOCK, { soloSinCosto: true });
  assertEquals(sinCosto.length, 3);
  assertEquals(sinCosto.map((p) => p.id).sort(), ["p13", "p14", "p15"]);

  // Filtro combinado: sin_categoria + soloSinCosto + búsqueda "Pintura"
  const combo = filtrarProductosCatalogo(PRODUCTOS_MOCK, {
    categoriaActiva: "sin_categoria",
    soloSinCosto: true,
    busqueda: "pintura",
  });
  assertEquals(combo.length, 1);
  assertEquals(combo[0].id, "p13");
});
