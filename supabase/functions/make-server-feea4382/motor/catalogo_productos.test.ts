// @ts-nocheck
import { assertEquals, assert } from "https://deno.land/std@0.192.0/testing/asserts.ts";
import {
  listarProductosPaginados,
  obtenerCatalogoCotizador,
} from "./catalogo_productos.ts";

function createFakeClient(opts: {
  tables?: Record<string, any[]>;
}) {
  const tables = opts.tables || {};

  return {
    from(tableName: string) {
      const filters: Array<{ col: string; op: string; val: any }> = [];
      const orderCols: Array<{ col: string; asc: boolean }> = [];
      let rangeFrom: number | null = null;
      let rangeTo: number | null = null;
      let isOr = false;
      let orClause: string | null = null;

      function getFilteredRows() {
        let res = (tables[tableName] || []).map((r) => ({ ...r }));
        for (const f of filters) {
          if (f.op === "eq") res = res.filter((r) => r[f.col] === f.val);
          if (f.op === "is") res = res.filter((r) => r[f.col] === f.val);
          if (f.op === "ilike") {
            const pattern = String(f.val).replace(/%/g, "").toLowerCase();
            res = res.filter((r) => (r[f.col] || "").toLowerCase().includes(pattern));
          }
        }
        if (orClause) {
          // Soporte básico para "costo.is.null,costo.lte.0" o "costo.is.null,costo.eq.0"
          if (
            orClause.includes("costo.is.null") &&
            (orClause.includes("costo.eq.0") || orClause.includes("costo.lte.0"))
          ) {
            res = res.filter((r) => r.costo === null || r.costo === undefined || Number(r.costo) <= 0);
          }
        }
        if (orderCols.length > 0) {
          res.sort((a, b) => {
            for (const { col, asc } of orderCols) {
              const va = a[col] ?? "";
              const vb = b[col] ?? "";
              if (va !== vb) {
                return asc ? (va > vb ? 1 : -1) : (va < vb ? 1 : -1);
              }
            }
            return 0;
          });
        }
        return res;
      }

      const builder: any = {
        select(_fields = "*", _opts: any = {}) {
          return builder;
        },
        eq(col: string, val: any) {
          filters.push({ col, op: "eq", val });
          return builder;
        },
        is(col: string, val: any) {
          filters.push({ col, op: "is", val });
          return builder;
        },
        ilike(col: string, val: any) {
          filters.push({ col, op: "ilike", val });
          return builder;
        },
        or(clause: string) {
          orClause = clause;
          return builder;
        },
        order(col: string, options: { ascending?: boolean } = {}) {
          orderCols.push({ col, asc: options.ascending ?? true });
          return builder;
        },
        range(from: number, to: number) {
          rangeFrom = from;
          rangeTo = to;
          return builder;
        },
        then(resolve: any, reject: any) {
          const allRows = getFilteredRows();
          let rows = allRows;
          if (rangeFrom !== null && rangeTo !== null) {
            rows = allRows.slice(rangeFrom, rangeTo + 1);
          }
          return Promise.resolve({
            data: rows,
            count: allRows.length,
            error: null,
          }).then(resolve, reject);
        },
      };

      return builder;
    },
  };
}

const ORG_ID = "11111111-1111-1111-1111-111111111111";

Deno.test("catalogo_productos - 1. Paginación retrocompatible supera el límite de 1000 filas en lotes de 1000", async () => {
  // Crear 1450 productos simulados en la base de datos
  const mock1450 = Array.from({ length: 1450 }, (_, i) => ({
    id: `prod-${i + 1}`,
    organizacion_id: ORG_ID,
    nombre: `Producto Insumo ${String(i + 1).padStart(4, "0")}`,
    tipo_item: "materia_prima",
    costo: i % 10 === 0 ? 0 : 100 + i,
    categoria_id: i < 10 ? "cat-1" : null,
  }));

  const fake = createFakeClient({
    tables: {
      productos: mock1450,
    },
  });

  // Llamada por omisión (sin parámetros de paginación explícitos)
  const todos = await listarProductosPaginados(fake, ORG_ID, {});

  // Debe haber consumido los dos lotes (1000 + 450) y retornado el total completo
  assertEquals(Array.isArray(todos), true);
  assertEquals(todos.length, 1450);
  assertEquals(todos[0].nombre, "Producto Insumo 0001");
  assertEquals(todos[1449].nombre, "Producto Insumo 1450");
});

Deno.test("catalogo_productos - 2. Paginación explícita con límite, búsqueda y detección de truncado", async () => {
  const mock100 = Array.from({ length: 100 }, (_, i) => ({
    id: `prod-${i + 1}`,
    organizacion_id: ORG_ID,
    nombre: i % 2 === 0 ? `Viga IPR ${i}` : `Tornillo Grado 5 - ${i}`,
    tipo_item: "materia_prima",
    costo: i % 5 === 0 ? 0 : 250,
    categoria_id: i < 20 ? "cat-acero" : null,
  }));

  const fake = createFakeClient({
    tables: {
      productos: mock100,
    },
  });

  // Página 1 de 20
  const resP1 = await listarProductosPaginados(fake, ORG_ID, { page: 1, limit: 20 });
  assertEquals(resP1.productos.length, 20);
  assertEquals(resP1.total, 100);
  assertEquals(resP1.page, 1);
  assertEquals(resP1.truncado, true);

  // Búsqueda por texto "IPR"
  const resBusc = await listarProductosPaginados(fake, ORG_ID, { q: "IPR", limit: 100 });
  assertEquals(resBusc.productos.length, 50); // los pares son 50
  assert(resBusc.productos.every((p: any) => p.nombre.includes("IPR")));

  // Filtro sin_categoria
  const resSinCat = await listarProductosPaginados(fake, ORG_ID, { categoria: "sin_categoria", limit: 100 });
  assertEquals(resSinCat.productos.length, 80);
  assert(resSinCat.productos.every((p: any) => p.categoria_id === null));

  // Filtro sin_costo
  const resSinCosto = await listarProductosPaginados(fake, ORG_ID, { sinCosto: true, limit: 100 });
  assertEquals(resSinCosto.productos.length, 20); // 0, 5, 10... hasta 95
  assert(resSinCosto.productos.every((p: any) => p.costo === 0 || p.costo === null));
});

Deno.test("catalogo_productos - 3. Catálogo del cotizador unifica aceros y opciones con esquema real y resolución de precio vigente", async () => {
  const fake = createFakeClient({
    tables: {
      acero_materiales: [
        {
          id: "acero-1",
          organizacion_id: ORG_ID,
          nombre: 'IPR 4" x 102"',
          tipo: "viga",
          ancho_ft: 4,
          largo_ft: 8.5,
          activo: true,
          notas: "Viga para chasis",
          precios: [
            {
              id: "pr-1",
              proveedor: "PROVEEDOR CARO",
              precio: 1300.00,
              incluye_iva: false,
              fuente: "lote_acero_2026",
              actualizado_el: "2026-10-26T16:43:19.405Z",
              notas: "Precio alto",
            },
            {
              id: "pr-2",
              proveedor: "ACEROS NACIONALES",
              precio: 1250.50,
              incluye_iva: true,
              fuente: "lote_acero_2026",
              // EXACTAMENTE LA MISMA FECHA DE ACTUALIZACIÓN:
              actualizado_el: "2026-10-26T16:43:19.405Z",
              notas: "Precio mínimo",
            },
          ],
        },
        // Caso real reproducido: 3 proveedores con el mismo actualizado_el y unidad tramo
        {
          id: "acero-angulo",
          organizacion_id: ORG_ID,
          nombre: "Angulo 3/16 X 1-1/2 a 6.10m",
          tipo: "perfil",
          ancho_ft: null,
          largo_ft: null,
          activo: true,
          precios: [
            {
              id: "pr-tanos",
              proveedor: "TANOS",
              precio: 897.64,
              incluye_iva: true,
              actualizado_el: "2026-10-26T16:43:19.405Z",
            },
            {
              id: "pr-fortacero",
              proveedor: "FORTACERO",
              precio: 417.45,
              incluye_iva: true,
              actualizado_el: "2026-10-26T16:43:19.405Z",
            },
            {
              id: "pr-serviacero",
              proveedor: "SERVIACERO",
              precio: 394.49,
              incluye_iva: true,
              actualizado_el: "2026-10-26T16:43:19.405Z",
            },
          ],
        },
        // Caso de empate de precio y fecha: desempate alfabético por proveedor
        {
          id: "acero-empate",
          organizacion_id: ORG_ID,
          nombre: "Solera 1/4 X 2 a 6.10m",
          tipo: "solera",
          ancho_ft: null,
          largo_ft: null,
          activo: true,
          precios: [
            {
              id: "pr-b",
              proveedor: "ZETA ACEROS",
              precio: 500.00,
              actualizado_el: "2026-10-26T16:43:19.405Z",
            },
            {
              id: "pr-a",
              proveedor: "ALFA METALES",
              precio: 500.00,
              actualizado_el: "2026-10-26T16:43:19.405Z",
            },
          ],
        },
      ],
      opciones_configuracion: [
        {
          id: "opc-1",
          organizacion_id: ORG_ID,
          grupo_id: "grp-1",
          clave: "susp_flet_master",
          nombre: "Suspensión Flet Master 2 ejes",
          precio_venta: 45000,
          activo: true,
          aliases: ["fleet_master"],
          grupo: { id: "grp-1", clave: "suspension", nombre: "Suspensión" },
          costos: [
            { id: "c-1", tipo_modelo: "plataforma", costo_unitario: 38000, escala: "fija", fuente: "costeo_leolca" },
          ],
        },
      ],
    },
  });

  const catalogo = await obtenerCatalogoCotizador(fake, ORG_ID);

  assertEquals(catalogo.totalAceros, 3);
  assertEquals(catalogo.total_aceros, 3);
  assertEquals(catalogo.totalOpciones, 1);
  assertEquals(catalogo.total_opciones, 1);

  // 1. Acero con placa y 2 precios con idéntica fecha: elige el mínimo (1250.50 de ACEROS NACIONALES)
  const acero = catalogo.aceros.find((a: any) => a.id === "acero-1");
  assertEquals(acero.nombre, 'IPR 4" x 102"');
  assertEquals(acero.unidad, "placa"); // Derivado de ancho_ft y largo_ft
  assertEquals(acero.precio, 1250.50); // Mínimo precio
  assertEquals(acero.proveedor, "ACEROS NACIONALES");
  assertEquals(acero.incluye_iva, true);
  assertEquals(acero.total_proveedores, 2);
  assertEquals(acero.precios_todos.length, 2);

  // 2. Ángulo con 3 proveedores a la misma fecha: elige SERVIACERO a 394.49 y unidad 'tramo'
  const angulo = catalogo.aceros.find((a: any) => a.id === "acero-angulo");
  assertEquals(angulo.unidad, "tramo");
  assertEquals(angulo.precio, 394.49); // Mínimo de los 3 proveedores (394.49 < 417.45 < 897.64)
  assertEquals(angulo.proveedor, "SERVIACERO");
  assertEquals(angulo.total_proveedores, 3);
  assertEquals(angulo.precios_todos[0].proveedor, "SERVIACERO");
  assertEquals(angulo.precios_todos[1].proveedor, "FORTACERO");
  assertEquals(angulo.precios_todos[2].proveedor, "TANOS");

  // 3. Empate de precio y fecha: desempata alfabéticamente (ALFA METALES antes de ZETA ACEROS)
  const solera = catalogo.aceros.find((a: any) => a.id === "acero-empate");
  assertEquals(solera.unidad, "tramo");
  assertEquals(solera.precio, 500.00);
  assertEquals(solera.proveedor, "ALFA METALES");

  // 4. Opciones de configuración
  const opcion = catalogo.opciones[0];
  assertEquals(opcion.clave, "susp_flet_master");
  assertEquals(opcion.grupo, "Suspensión");
  assertEquals(opcion.grupo_nombre, "Suspensión");
  assertEquals(opcion.precio_venta, 45000);
  assertEquals(opcion.costo, 38000);
  assertEquals(opcion.costo_referencia, 38000);
  assertEquals(opcion.fuente, "costeo_leolca");
});
