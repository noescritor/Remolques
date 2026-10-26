// @ts-nocheck
import { assertEquals, assertThrows, assert } from 'https://deno.land/std@0.208.0/assert/mod.ts';
import {
  calcularNuevoPrecio,
  parsearPrecioTexto,
  analizarLote,
  filasDesdeHoja,
  FilaLoteEntrada,
} from './preciosLote.ts';

Deno.test('preciosLote - calcularNuevoPrecio: pruebas doradas del prompt', () => {
  // 1. 1,000 + 10% = 1,100
  const r1 = calcularNuevoPrecio({
    precioActual: 1000,
    modo: 'porcentaje',
    valor: 10,
    redondeo: 'centavos',
  });
  assertEquals(r1.precioNuevo, 1100);
  assertEquals(r1.sinPrecioBase, false);

  // 2. 4,193.34 - 5% = 3,983.673
  // a) Redondeo centavos -> 3,983.67
  const r2Centavos = calcularNuevoPrecio({
    precioActual: 4193.34,
    modo: 'porcentaje',
    valor: -5,
    redondeo: 'centavos',
  });
  assertEquals(r2Centavos.precioNuevo, 3983.67);

  // b) Redondeo peso -> 3,984
  const r2Peso = calcularNuevoPrecio({
    precioActual: 4193.34,
    modo: 'porcentaje',
    valor: -5,
    redondeo: 'peso',
  });
  assertEquals(r2Peso.precioNuevo, 3984);

  // c) Redondeo multiplo5 -> 3,985
  const r2Mult5 = calcularNuevoPrecio({
    precioActual: 4193.34,
    modo: 'porcentaje',
    valor: -5,
    redondeo: 'multiplo5',
  });
  assertEquals(r2Mult5.precioNuevo, 3985);

  // 3. Precio 0 con porcentaje queda 0 y reporta sinPrecioBase
  const r3 = calcularNuevoPrecio({
    precioActual: 0,
    modo: 'porcentaje',
    valor: 15,
  });
  assertEquals(r3.precioNuevo, 0);
  assertEquals(r3.sinPrecioBase, true);

  // 4. Precio null con porcentaje no calcula y reporta sinPrecioBase
  const r4 = calcularNuevoPrecio({
    precioActual: null,
    modo: 'porcentaje',
    valor: 10,
  });
  assertEquals(r4.precioNuevo, null);
  assertEquals(r4.sinPrecioBase, true);

  // 5. Modo monto fijo (+250 / -100)
  const r5 = calcularNuevoPrecio({
    precioActual: 500,
    modo: 'monto',
    valor: 250,
  });
  assertEquals(r5.precioNuevo, 750);

  const r6 = calcularNuevoPrecio({
    precioActual: 500,
    modo: 'monto',
    valor: -100,
  });
  assertEquals(r6.precioNuevo, 400);

  // 6. Modo fijo
  const r7 = calcularNuevoPrecio({
    precioActual: null,
    modo: 'fijo',
    valor: 1250.555,
    redondeo: 'centavos',
  });
  assertEquals(r7.precioNuevo, 1250.56);
});

Deno.test('preciosLote - calcularNuevoPrecio: validaciones y errores', () => {
  // Precio negativo por resta excesiva
  assertThrows(() => {
    calcularNuevoPrecio({
      precioActual: 100,
      modo: 'monto',
      valor: -150,
    });
  });

  // Fijo negativo
  assertThrows(() => {
    calcularNuevoPrecio({
      precioActual: 100,
      modo: 'fijo',
      valor: -10,
    });
  });

  // Valor NaN
  assertThrows(() => {
    calcularNuevoPrecio({
      precioActual: 100,
      modo: 'porcentaje',
      valor: NaN,
    });
  });
});

Deno.test('preciosLote - parsearPrecioTexto: formatos aceptados y ambiguos', () => {
  // Formatos normales
  assertEquals(parsearPrecioTexto('1,234.56'), 1234.56);
  assertEquals(parsearPrecioTexto('1234.56'), 1234.56);
  assertEquals(parsearPrecioTexto('$1,234.56'), 1234.56);
  assertEquals(parsearPrecioTexto(' 1 234,56 '), 1234.56);
  assertEquals(parsearPrecioTexto('1234,56'), 1234.56);
  assertEquals(parsearPrecioTexto('100'), 100);
  assertEquals(parsearPrecioTexto(1500.5), 1500.5);

  // Vacíos -> null (sin cambio)
  assertEquals(parsearPrecioTexto(''), null);
  assertEquals(parsearPrecioTexto('   '), null);
  assertEquals(parsearPrecioTexto(null), null);
  assertEquals(parsearPrecioTexto(undefined), null);

  // Ambigüedad: '1,234' tiene 3 dígitos tras la coma sin punto ni decimales
  assertThrows(() => {
    parsearPrecioTexto('1,234');
  });

  // '5,000' es ambiguo
  assertThrows(() => {
    parsearPrecioTexto('5,000');
  });

  // Texto inválido
  assertThrows(() => {
    parsearPrecioTexto('abc');
  });
});

Deno.test('preciosLote - analizarLote: alertas, errores, sin cambio y resumen', () => {
  const filas: FilaLoteEntrada[] = [
    // 1. Sin cambio
    {
      id: 'p1',
      fuente: 'productos',
      descripcion: 'Lámina 1',
      precioActual: 1000,
      precioNuevo: 1000,
    },
    // 2. Sin cambio por null
    {
      id: 'p2',
      fuente: 'productos',
      descripcion: 'Lámina 2',
      precioActual: 2000,
      precioNuevo: null,
    },
    // 3. Cambio normal (10%)
    {
      id: 'p3',
      fuente: 'opcion_costos',
      descripcion: 'Opción A',
      precioActual: 500,
      precioNuevo: 550,
    },
    // 4. Alerta: variación mayor a 30% (+50%)
    {
      id: 'p4',
      fuente: 'costos_modelo',
      descripcion: 'Mano de obra',
      precioActual: 100,
      precioNuevo: 150,
    },
    // 5. Alerta: nuevo precio es 0
    {
      id: 'p5',
      fuente: 'acero_precios',
      descripcion: 'Solera',
      precioActual: 300,
      precioNuevo: 0,
    },
    // 6. Alerta: nuevo precio > 5x actual (6x)
    {
      id: 'p6',
      fuente: 'acero_precios',
      descripcion: 'PTR',
      precioActual: 200,
      precioNuevo: 1200,
    },
    // 7. Error: id vacío
    {
      id: '',
      fuente: 'productos',
      descripcion: 'Sin ID',
      precioActual: 100,
      precioNuevo: 110,
    },
    // 8. Error: fuente inválida
    {
      id: 'p8',
      fuente: 'otra_tabla' as any,
      descripcion: 'Fuente mala',
      precioActual: 100,
      precioNuevo: 110,
    },
    // 9. Error: precio negativo
    {
      id: 'p9',
      fuente: 'productos',
      descripcion: 'Negativo',
      precioActual: 100,
      precioNuevo: -50,
    },
  ];

  const resultado = analizarLote({ filas });
  const { resumen, filas: rFilas } = resultado;

  assertEquals(resumen.total, 9);
  assertEquals(resumen.sinCambio, 2);
  assertEquals(resumen.cambian, 1); // p3
  assertEquals(resumen.alertas, 3); // p4, p5, p6
  assertEquals(resumen.errores, 3); // p7, p8, p9

  // Impacto en pesos aproximado:
  // p3: |550 - 500| = 50
  // p4: |150 - 100| = 50
  // p5: |0 - 300| = 300
  // p6: |1200 - 200| = 1000
  // Total = 50 + 50 + 300 + 1000 = 1400
  assertEquals(resumen.impactoTotalPesos, 1400);

  // Verificar estados individuales
  assertEquals(rFilas[0].estado, 'sinCambio');
  assertEquals(rFilas[1].estado, 'sinCambio');
  assertEquals(rFilas[2].estado, 'cambia');
  assertEquals(rFilas[3].estado, 'alerta');
  assert(rFilas[3].alertas[0].includes('30%'));
  assertEquals(rFilas[4].estado, 'alerta');
  assert(rFilas[4].alertas.some((a) => a.includes('$0.00')));
  assertEquals(rFilas[5].estado, 'alerta');
  assert(rFilas[5].alertas.some((a) => a.includes('5 veces')));
  assertEquals(rFilas[6].estado, 'error');
  assertEquals(rFilas[7].estado, 'error');
  assertEquals(rFilas[8].estado, 'error');
});

Deno.test('preciosLote - filasDesdeHoja: mapeo y reporte de número de fila en archivo', () => {
  const hojaRaw = [
    // Fila 2 de archivo: válida
    {
      id: 'prod-01',
      descripcion: 'Pintura',
      contexto: 'Acabados',
      unidad: 'Litro',
      'Precio Actual': '250.00',
      'Precio Nuevo': '275.00',
    },
    // Fila 3 de archivo: error 1 (precio nuevo corrupto)
    {
      id: 'prod-02',
      descripcion: 'Thinner',
      'Precio Actual': '80.00',
      'Precio Nuevo': 'no_es_numero',
    },
    // Fila 4 de archivo: error 2 (id vacío)
    {
      id: '   ',
      descripcion: 'Sin Id',
      'Precio Nuevo': '100.00',
    },
    // Fila 5 de archivo: error 3 (precio ambiguo 1,234)
    {
      id: 'prod-04',
      descripcion: 'Solera',
      'Precio Nuevo': '1,234',
    },
  ];

  const filas = filasDesdeHoja(hojaRaw, 'productos');
  assertEquals(filas.length, 4);

  const analisis = analizarLote({ filas });
  assertEquals(analisis.resumen.errores, 3);

  // Comprobar que los errores conservan y reportan el número de fila del archivo
  const errores = analisis.filas.filter((f) => f.estado === 'error');
  assertEquals(errores[0].filaArchivo, 3);
  assertEquals(errores[1].filaArchivo, 4);
  assertEquals(errores[2].filaArchivo, 5);
});
