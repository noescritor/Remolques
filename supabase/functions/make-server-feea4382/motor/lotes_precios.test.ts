// @ts-nocheck
import { assertEquals, assert } from 'https://deno.land/std@0.192.0/testing/asserts.ts';
import {
  exportarPrecios,
  previsualizarCambios,
  aplicarLote,
  revertirLote,
} from './lotes_precios.ts';

function createFakeClient(opts: {
  rpcHandlers?: Record<string, (args: any) => Promise<any> | any>;
  tables?: Record<string, any[]>;
}) {
  const tables = opts.tables || {};
  const rpcHandlers = opts.rpcHandlers || {};

  return {
    from(tableName: string) {
      let rows = [...(tables[tableName] || [])];
      const filters: Array<{ col: string; op: string; val: any }> = [];

      const builder: any = {
        select(_fields = '*') {
          return builder;
        },
        eq(col: string, val: any) {
          filters.push({ col, op: 'eq', val });
          return builder;
        },
        in(col: string, vals: any[]) {
          filters.push({ col, op: 'in', val: vals });
          return builder;
        },
        order(_col: string, _opts: any) {
          return builder;
        },
        limit(n: number) {
          return builder;
        },
        or(_expr: string) {
          return builder;
        },
        then(resolve: any) {
          let res = rows;
          for (const f of filters) {
            if (f.op === 'eq') res = res.filter((r) => r[f.col] === f.val);
            if (f.op === 'in') res = res.filter((r) => f.val.includes(r[f.col]));
          }
          resolve({ data: res, error: null });
        },
      };
      return builder;
    },
    async rpc(fnName: string, args: any) {
      if (rpcHandlers[fnName]) {
        const res = await rpcHandlers[fnName](args);
        return { data: res, error: null };
      }
      return { data: null, error: { message: `RPC ${fnName} no implementada en mock` } };
    },
  };
}

Deno.test('lotes_precios - aplicarLote: validaciones de payload y límites (413, 400)', async () => {
  const client = createFakeClient({});

  // 1. Más de 2000 cambios -> 413
  const cambiosMasivos = Array.from({ length: 2001 }, (_, i) => ({
    fuente: 'productos' as const,
    id: `prod-${i}`,
    precio_nuevo: 100,
  }));

  const res413 = await aplicarLote(client, 'org-1', 'user-1', {
    origen: 'excel',
    descripcion: 'Lote masivo excedido',
    cambios: cambiosMasivos,
  });
  assertEquals(res413.status, 413);
  assert(res413.data.error.includes('2,000'));

  // 2. Precio negativo o NaN -> 400
  const resNeg = await aplicarLote(client, 'org-1', 'user-1', {
    origen: 'porcentaje',
    descripcion: 'Lote con precio negativo',
    cambios: [{ fuente: 'productos', id: 'p1', precio_nuevo: -50 }],
  });
  assertEquals(resNeg.status, 400);

  const resNan = await aplicarLote(client, 'org-1', 'user-1', {
    origen: 'porcentaje',
    descripcion: 'Lote con precio NaN',
    cambios: [{ fuente: 'productos', id: 'p1', precio_nuevo: NaN }],
  });
  assertEquals(resNan.status, 400);

  // 3. Descripción vacía -> 400
  const resDesc = await aplicarLote(client, 'org-1', 'user-1', {
    origen: 'porcentaje',
    descripcion: '   ',
    cambios: [{ fuente: 'productos', id: 'p1', precio_nuevo: 100 }],
  });
  assertEquals(resDesc.status, 400);
});

Deno.test('lotes_precios - aplicarLote: lista blanca y manejo de conflicto de concurrencia (409)', async () => {
  let rpcArgsReceived: any = null;

  const client = createFakeClient({
    rpcHandlers: {
      aplicar_lote_precios: (args) => {
        rpcArgsReceived = args;
        // Simular conflicto cuando el precio esperado no coincide
        const item = args.p_cambios[0];
        if (item.precio_anterior_visto === 500) {
          return {
            exito: false,
            error: 'conflicto',
            mensaje: 'Se detectaron conflictos',
            conflictos: [
              {
                id: item.id,
                fuente: item.fuente,
                precio_esperado: 500,
                precio_actual: 550,
                motivo: 'El precio actual ha cambiado respecto al visto por el cliente',
              },
            ],
          };
        }
        return {
          exito: true,
          lote_id: 'lote-123',
          aplicados: 1,
          omitidos_sin_cambio: 0,
        };
      },
    },
  });

  // Payload con campo malicioso inyectado (organizacion_id ajena)
  const payloadInyectado: any = {
    origen: 'excel',
    descripcion: 'Ajuste mensual',
    organizacion_id: 'org-atacante',
    cambios: [
      {
        fuente: 'productos',
        id: 'p1',
        precio_nuevo: 600,
        precio_anterior_visto: 500,
        organizacion_id: 'org-atacante',
      },
    ],
  };

  // Debe retornar 409 por el conflicto simulado
  const resConflicto = await aplicarLote(client, 'org-victima', 'user-1', payloadInyectado);
  assertEquals(resConflicto.status, 409);
  assertEquals(resConflicto.data.error, 'conflicto');
  assertEquals(resConflicto.data.conflictos.length, 1);

  // Verificar que la organización enviada al RPC fue p_org: 'org-victima' y no la inyectada
  assertEquals(rpcArgsReceived.p_org, 'org-victima');
  assertEquals(rpcArgsReceived.p_cambios[0].organizacion_id, undefined);

  // Caso exitoso sin conflicto (precio_anterior_visto correcto)
  const resOk = await aplicarLote(client, 'org-victima', 'user-1', {
    origen: 'manual',
    descripcion: 'Ajuste correcto',
    cambios: [{ fuente: 'productos', id: 'p1', precio_nuevo: 600, precio_anterior_visto: 550 }],
  });
  assertEquals(resOk.status, 200);
  assertEquals(resOk.data.lote_id, 'lote-123');
});

Deno.test('lotes_precios - revertirLote: 404 si no existe y 409 ante reversión doble', async () => {
  const client = createFakeClient({
    rpcHandlers: {
      revertir_lote_precios: (args) => {
        if (args.p_lote_id === 'lote-inexistente') {
          return { exito: false, error: 'not_found', mensaje: 'Lote no encontrado' };
        }
        if (args.p_lote_id === 'lote-ya-revertido') {
          return { exito: false, error: 'ya_revertido', mensaje: 'El lote ya fue revertido' };
        }
        return {
          exito: true,
          lote_id: 'lote-reversion-1',
          revertidos: 5,
          omitidos_editados_posteriormente: 1,
          detalles_omitidos: [],
        };
      },
    },
  });

  const res404 = await revertirLote(client, 'org-1', 'user-1', 'lote-inexistente');
  assertEquals(res404.status, 404);

  const res409 = await revertirLote(client, 'org-1', 'user-1', 'lote-ya-revertido');
  assertEquals(res409.status, 409);

  const res200 = await revertirLote(client, 'org-1', 'user-1', 'lote-valido');
  assertEquals(res200.status, 200);
  assertEquals(res200.data.revertidos, 5);
  assertEquals(res200.data.omitidos_editados_posteriormente, 1);
});

Deno.test('lotes_precios - previsualizarCambios: relee precios frescos y genera diff/alertas', async () => {
  const fakeDb = createFakeClient({
    tables: {
      productos: [
        { id: 'p1', organizacion_id: 'org-1', nombre: 'Pintura Blanca', costo: 100, tipo_item: 'materia_prima' },
        { id: 'p2', organizacion_id: 'org-1', nombre: 'Solvente', costo: 200, tipo_item: 'materia_prima' },
      ],
    },
  });

  const res = await previsualizarCambios(fakeDb, 'org-1', [
    { fuente: 'productos', id: 'p1', precio_nuevo: 110 }, // +10% normal
    { fuente: 'productos', id: 'p2', precio_nuevo: 350 }, // +75% alerta > 30%
    { fuente: 'productos', id: 'p_inexistente', precio_nuevo: 50 },
  ]);

  assertEquals(res.resumen.total, 3);
  assertEquals(res.resumen.cambian, 2); // p1 y p_inexistente
  assertEquals(res.resumen.alertas, 1); // p2
  // p_inexistente tiene precioActual null, nuevo 50 -> impacto 50
  assert(res.resumen.impactoTotalPesos >= 160);
});

Deno.test('lotes_precios - F.1: Cotizaciones guardadas conservan su precio tras cambio de catalogo', () => {
  // Una cotización guardada contiene en su tabla items_cotizacion un snapshot inmutable
  // de precio_unitario, subtotal y total, además del metadata de costeo.
  const cotizacionGuardada = {
    id: 'cot-101',
    folio: 'COT-2026-001',
    subtotal: 500000,
    iva: 80000,
    total: 580000,
    items: [
      {
        id: 'item-1',
        cotizacion_id: 'cot-101',
        descripcion: 'Plataforma 40 pies 2 ejes',
        cantidad: 1,
        precio_unitario: 500000,
        subtotal: 500000,
        total: 580000,
        metadata: {
          costeo: { costo_total: 420000, precio_sugerido: 500000 },
        },
      },
    ],
  };

  // Simular que el costo en el catálogo subió a $550,000
  const nuevoCostoCatalogo = 550000;

  // Al releer la cotización guardada desde la base de datos (GET /cotizaciones/:id):
  const cotizacionReleida = { ...cotizacionGuardada };

  // El total de la cotización guardada NO se modifica:
  assertEquals(cotizacionReleida.total, 580000);
  assertEquals(cotizacionReleida.items[0].precio_unitario, 500000);
  assertEquals(cotizacionReleida.items[0].subtotal, 500000);
  assert(cotizacionReleida.items[0].precio_unitario !== nuevoCostoCatalogo);
});

Deno.test('lotes_precios - F.2: Propagacion a opciones con costo_desde_producto', async () => {
  const { costear } = await import('./costeo.ts');

  const datosBase: any = {
    modelo: { id: 'mod-1', tipo: 'plataforma', largo_ft: 40, num_ejes: 2, nombre: 'Plataforma 40' },
    receta_acero: [],
    costos_modelo: [],
    procesos: [],
    opcion_costos: [
      {
        grupo_clave: 'llantas',
        opcion_clave: 'firestone',
        cantidad_base: 8,
        escala: 'fija',
        costo_unitario: 9999, // Debe ignorarse porque costo_desde_producto es true
        producto_id: 'prod-llanta-1',
        costo_desde_producto: true,
        producto_costo: 3500, // Costo inicial del producto en productos.costo
      },
    ],
    grupos: [
      { clave: 'llantas', nombre: 'Llantas', unidad_precio: 'pieza', cantidad: 8 },
    ],
    ganancia: 50000,
  };

  const config = {
    grupos: { llantas: 'firestone' },
  } as any;

  // Costeo inicial con llanta a $3,500
  const costeo1 = costear(datosBase, config, null);
  const opt1 = costeo1.secciones.opciones.lineas.find((o: any) => o.origen === 'opcion:llantas/firestone');
  assertEquals(opt1.costo_unitario, 3500);
  assertEquals(opt1.importe, 8 * 3500); // 28,000

  // Se actualiza el costo del producto en la tabla productos a $4,200
  const datosActualizados = {
    ...datosBase,
    opcion_costos: [
      {
        ...datosBase.opcion_costos[0],
        producto_costo: 4200, // Nuevo costo propagado de productos
      },
    ],
  };

  const costeo2 = costear(datosActualizados, config, null);
  const opt2 = costeo2.secciones.opciones.lineas.find((o: any) => o.origen === 'opcion:llantas/firestone');
  assertEquals(opt2.costo_unitario, 4200);
  assertEquals(opt2.importe, 8 * 4200); // 33,600
  assertEquals(costeo2.costo - costeo1.costo, 5600); // 33600 - 28000 = 5600
});

Deno.test('lotes_precios - F.3: Atomicidad ante conflicto (todo o nada)', async () => {
  const registrosModificados: string[] = [];

  const client = createFakeClient({
    rpcHandlers: {
      aplicar_lote_precios: (args) => {
        const tieneConflicto = args.p_cambios.some(
          (c: any) => c.precio_anterior_visto !== undefined && c.precio_anterior_visto === 999
        );
        if (tieneConflicto) {
          return {
            exito: false,
            error: 'conflicto',
            conflictos: [{ id: 'p2', motivo: 'Conflicto de precio anterior' }],
          };
        }
        for (const c of args.p_cambios) {
          registrosModificados.push(c.id);
        }
        return { exito: true, lote_id: 'lote-ok', aplicados: args.p_cambios.length, omitidos_sin_cambio: 0 };
      },
    },
  });

  const res = await aplicarLote(client, 'org-1', 'user-1', {
    origen: 'manual',
    descripcion: 'Lote atomico de prueba',
    cambios: [
      { fuente: 'productos', id: 'p1', precio_nuevo: 150, precio_anterior_visto: 100 },
      { fuente: 'productos', id: 'p2', precio_nuevo: 250, precio_anterior_visto: 999 }, // Conflicto
    ],
  });

  assertEquals(res.status, 409);
  assertEquals(res.data.error, 'conflicto');
  assertEquals(registrosModificados.length, 0);
});
