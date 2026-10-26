// @ts-nocheck
import { assertEquals, assert } from "https://deno.land/std@0.192.0/testing/asserts.ts";
import {
  normalizarFilas,
  calcularSumaPiezas,
  calcularFaltantes,
  fusionarDuplicados,
  calcularMaxPiezasGrupo,
  obtenerCantidadDefecto,
  validarFilasSeleccionMixta,
  siguienteCantidad,
  completarConEstaOpcion,
  normalizarClaveOpcion,
  limpiarTextoColorPersonalizado,
  esOpcionVisible,
  filtrarOpcionesVisibles
} from "./seleccionMixta.ts";

Deno.test("seleccionMixta - normalizarFilas: maneja formatos string, objeto único y arreglo (retrocompatibilidad)", () => {
  // 1. null / undefined -> arreglo vacío
  assertEquals(normalizarFilas(undefined), []);
  assertEquals(normalizarFilas(null), []);

  // 2. String único (forma vieja) -> fila única con cantidad por defecto
  const filaStr = normalizarFilas("sin_rines", 8);
  assertEquals(filaStr, [{ opcion: "sin_rines", cantidad: 8 }]);

  // 3. Objeto único (forma previa con cantidad explícita o implícita)
  const filaObj = normalizarFilas({ opcion: "acero", marca: "Ampro", cantidad: 8 });
  assertEquals(filaObj, [{ opcion: "acero", marca: "Ampro", medida: undefined, cantidad: 8 }]);

  // 4. Arreglo mixto con strings y objetos
  const filasArr = normalizarFilas([
    "sin_rines",
    { opcion: "acero", marca: "Ampro", cantidad: 4 },
    { opcion: "aluminio", marca: "Fleet Master", cantidad: 4 }
  ]);
  assertEquals(filasArr.length, 3);
  assertEquals(filasArr[1].cantidad, 4);
  assertEquals(filasArr[2].marca, "Fleet Master");
});

Deno.test("seleccionMixta - calcularSumaPiezas y calcularFaltantes: ignora sin_* y cuenta cliente", () => {
  // Opciones sin_* suman 0
  const filasSin = [{ opcion: "sin_rines", cantidad: 8 }];
  assertEquals(calcularSumaPiezas(filasSin), 0);
  assertEquals(calcularFaltantes(8, filasSin), 8);

  // Combinación mixta de rines: 8 acero + 4 aluminio = 12
  const filasMixtas = [
    { opcion: "acero", marca: "Ampro", cantidad: 8 },
    { opcion: "aluminio", marca: "Ampro", cantidad: 4 }
  ];
  assertEquals(calcularSumaPiezas(filasMixtas), 12);
  assertEquals(calcularFaltantes(12, filasMixtas), 0);

  // Opción "cliente" cuenta para el tope (proporciona el cliente)
  const filasCliente = [
    { opcion: "acero", marca: "Ampro", cantidad: 4 },
    { opcion: "cliente", cantidad: 4 }
  ];
  assertEquals(calcularSumaPiezas(filasCliente), 8);
  assertEquals(calcularFaltantes(8, filasCliente), 0);
});

Deno.test("seleccionMixta - fusionarDuplicados: agrupa misma opción y marca sumando cantidades", () => {
  const duplicadas = [
    { opcion: "acero", marca: "Ampro", cantidad: 4 },
    { opcion: "aluminio", marca: "Ampro", cantidad: 4 },
    { opcion: "acero", marca: "Ampro", cantidad: 4 } // duplicado de la primera
  ];

  const fusionadas = fusionarDuplicados(duplicadas);
  assertEquals(fusionadas.length, 2);
  assertEquals(fusionadas[0], { opcion: "acero", marca: "Ampro", cantidad: 8 });
  assertEquals(fusionadas[1], { opcion: "aluminio", marca: "Ampro", cantidad: 4 });
});

Deno.test("seleccionMixta - calcularMaxPiezasGrupo: calcula por_eje y fija según modelo", () => {
  const grupoRines = {
    clave: "rines",
    regla: { max_total: { por_eje: 4 } }
  };
  const modelo2Ejes = { num_ejes: 2 };
  const modelo3Ejes = { num_ejes: 3 };

  assertEquals(calcularMaxPiezasGrupo(grupoRines, modelo2Ejes), 8);
  assertEquals(calcularMaxPiezasGrupo(grupoRines, modelo3Ejes), 12);

  const grupoMatracas = {
    clave: "matracas",
    regla: JSON.stringify({ max_total: { fija: 12 } }) // regla como JSON string
  };
  assertEquals(calcularMaxPiezasGrupo(grupoMatracas, modelo2Ejes), 12);
  assertEquals(calcularMaxPiezasGrupo(grupoMatracas, modelo3Ejes), 12);
});

Deno.test("seleccionMixta - validarFilasSeleccionMixta: detecta excesos, faltantes y cantidades no válidas", () => {
  // Exceso en rines (10 piezas cuando el máximo es 8)
  const filasExceso = [
    { opcion: "acero", marca: "Ampro", cantidad: 6 },
    { opcion: "aluminio", marca: "Ampro", cantidad: 4 }
  ];
  const resExceso = validarFilasSeleccionMixta(filasExceso, 8, "Rines");
  assertEquals(resExceso.valido, false);
  assertEquals(resExceso.errores.length, 1);
  assertEquals(resExceso.errores[0], "Los rines suman 10 piezas y el máximo para este modelo es 8");

  // Faltantes (6 piezas cuando el máximo es 8) -> es advertencia, no error
  const filasFaltantes = [
    { opcion: "acero", marca: "Ampro", cantidad: 4 }
  ];
  const resFaltantes = validarFilasSeleccionMixta(filasFaltantes, 8, "Rines");
  assertEquals(resFaltantes.valido, true);
  assertEquals(resFaltantes.errores.length, 0);
  assertEquals(resFaltantes.advertencias.length, 1);
  assertEquals(resFaltantes.advertencias[0], "Faltan 4 rines por definir");

  // Cantidad no entera o menor a 1
  const filasInvalida = [
    { opcion: "acero", marca: "Ampro", cantidad: 0 }
  ];
  const resInvalida = validarFilasSeleccionMixta(filasInvalida, 8, "Rines");
  assertEquals(resInvalida.valido, false);
  assert(resInvalida.errores[0].includes("número entero mayor o igual a 1"));
});

Deno.test("seleccionMixta - siguienteCantidad y completarConEstaOpcion: comportamiento guiado", () => {
  // 1. Primera fila: sugiere el máximo (ej. 12 para 3 ejes)
  const sig1 = siguienteCantidad(12, []);
  assertEquals(sig1.cantidadSugerida, 12);
  assertEquals(sig1.yaLlegoAlMaximo, false);

  // 2. Con 8 asignadas: sugiere lo que falta (4)
  const filas8 = [{ opcion: "acero", marca: "Ampro", cantidad: 8 }];
  const sig2 = siguienteCantidad(12, filas8);
  assertEquals(sig2.cantidadSugerida, 4);
  assertEquals(sig2.yaLlegoAlMaximo, false);

  // 3. Con 12 asignadas: avisa que ya llegó al tope
  const filas12 = [
    { opcion: "acero", marca: "Ampro", cantidad: 8 },
    { opcion: "aluminio", marca: "Ampro", cantidad: 4 }
  ];
  const sig3 = siguienteCantidad(12, filas12);
  assertEquals(sig3.yaLlegoAlMaximo, true);
  assert(sig3.mensajeBloqueo?.includes("Ya llegaste al máximo de 12 piezas"));

  // 4. Completar con esta opción: reajusta la fila elegida para llenar el tope
  // Si tenemos [acero: 4, aluminio: 2] y completamos acero con tope 12 -> acero pasa a 10 (12 - 2)
  const filasIncompletas = [
    { opcion: "acero", marca: "Ampro", cantidad: 4 },
    { opcion: "aluminio", marca: "Ampro", cantidad: 2 }
  ];
  const completadas = completarConEstaOpcion(filasIncompletas, 0, 12);
  assertEquals(completadas[0].cantidad, 10);
  assertEquals(completadas[1].cantidad, 2);
  assertEquals(calcularSumaPiezas(completadas), 12);
});

Deno.test("seleccionMixta - 2R-10: obtenerCantidadDefecto y normalización para grupo con cantidad_defecto: 1 (retractil)", () => {
  // Grupo retractil: cantidad_defecto = 1
  const grupoRetractil = {
    clave: "retractil",
    nombre: "Sistema retráctil",
    regla: { max_total: { por_eje: 1 }, cantidad_defecto: 1 }
  };
  const modelo2Ejes = { num_ejes: 2 };
  const maxRetractil = calcularMaxPiezasGrupo(grupoRetractil, modelo2Ejes); // 2
  assertEquals(maxRetractil, 2);

  const cantDefRetractil = obtenerCantidadDefecto(grupoRetractil, maxRetractil);
  assertEquals(cantDefRetractil, 1);

  // Al reabrir equipo guardado con string viejo "chico", se normaliza con cantidad_defecto = 1
  const filasReabiertas = normalizarFilas("chico", cantDefRetractil);
  assertEquals(filasReabiertas, [{ opcion: "chico", cantidad: 1 }]);

  // Grupo matracas: cantidad_defecto = 12
  const grupoMatracas = {
    clave: "matracas",
    nombre: "Matracas",
    regla: JSON.stringify({ max_total: { fija: 20 }, cantidad_defecto: 12 })
  };
  const cantDefMatracas = obtenerCantidadDefecto(grupoMatracas, 20);
  assertEquals(cantDefMatracas, 12);

  const filasMatracas = normalizarFilas("corrediza", cantDefMatracas);
  assertEquals(filasMatracas, [{ opcion: "corrediza", cantidad: 12 }]);

  // Grupo rines: cantidad_defecto = 'max'
  const grupoRines = {
    clave: "rines",
    nombre: "Rines",
    regla: { max_total: { por_eje: 4 }, cantidad_defecto: "max" }
  };
  const cantDefRines = obtenerCantidadDefecto(grupoRines, 8);
  assertEquals(cantDefRines, 8);

  const filasRines = normalizarFilas("acero", cantDefRines);
  assertEquals(filasRines, [{ opcion: "acero", cantidad: 8 }]);

  // Validación de exceso en retráctiles (3 en 2 ejes -> error con nombre pluralizado)
  const filasExcesoRetractil = [
    { opcion: "chico", cantidad: 2 },
    { opcion: "grande", cantidad: 1 }
  ];
  const resValRetractil = validarFilasSeleccionMixta(filasExcesoRetractil, 2, "Sistema retráctil");
  assertEquals(resValRetractil.valido, false);
  assertEquals(resValRetractil.errores[0], "Los retráctiles suman 3 piezas y el máximo para este modelo es 2");
});

Deno.test("Sub-bloque 2R-12: normalizarClaveOpcion, limpiarTextoColorPersonalizado y calcularMaxPiezasGrupo por_num_ejes", () => {
  // 1. normalizarClaveOpcion
  assertEquals(normalizarClaveOpcion("retractil", "paleta"), "grande");
  assertEquals(normalizarClaveOpcion("retractil", "grande"), "grande");
  assertEquals(normalizarClaveOpcion("retractil", "chico"), "chico");
  assertEquals(normalizarClaveOpcion("retractil", "sin_retractil"), "sin_retractil");
  assertEquals(normalizarClaveOpcion("piso", "paleta"), "paleta");
  assertEquals(normalizarClaveOpcion("rines", "aluminio"), "aluminio");

  // 2. limpiarTextoColorPersonalizado
  assertEquals(limpiarTextoColorPersonalizado(""), "");
  assertEquals(limpiarTextoColorPersonalizado(null as any), "");
  assertEquals(limpiarTextoColorPersonalizado("   Verde militar   "), "Verde militar");
  assertEquals(limpiarTextoColorPersonalizado("<b>Blanco</b> perla <script>alert(1)</script>"), "Blanco perla alert(1)");
  assertEquals(limpiarTextoColorPersonalizado("A".repeat(100)), "A".repeat(80));

  // 3. calcularMaxPiezasGrupo con por_num_ejes (2 ejes -> 1, 3 ejes -> 2, otro -> undefined)
  const grupoRetractil = {
    clave: "retractil",
    regla: {
      max_total: { por_num_ejes: { "2": 1, "3": 2 } },
      cantidad_defecto: 1
    }
  };
  assertEquals(calcularMaxPiezasGrupo(grupoRetractil, { num_ejes: 2 }), 1);
  assertEquals(calcularMaxPiezasGrupo(grupoRetractil, { num_ejes: 3 }), 2);
  assertEquals(calcularMaxPiezasGrupo(grupoRetractil, { num_ejes: 1 }), undefined);
  assertEquals(calcularMaxPiezasGrupo(grupoRetractil, { num_ejes: 4 }), undefined);
});

Deno.test("Sub-bloque 2R-12: esOpcionVisible y filtrarOpcionesVisibles para opciones inactivas (paleta, plastico_negro)", () => {
  // 1. Opción inactiva no seleccionada -> oculta (false)
  assertEquals(esOpcionVisible({ activo: false }, false), false);

  // 2. Opción inactiva y seleccionada (equipo viejo guardado) -> visible (true)
  assertEquals(esOpcionVisible({ activo: false }, true), true);

  // 3. Opción activa -> visible (true) siempre
  assertEquals(esOpcionVisible({ activo: true }, false), true);
  assertEquals(esOpcionVisible({ activo: true }, true), true);
  assertEquals(esOpcionVisible({}, false), true);
  assertEquals(esOpcionVisible({}, true), true);
  assertEquals(esOpcionVisible(null, false), false);

  // 4. Caso real con catálogo de opciones (paleta inactiva, plastico_negro inactiva)
  const opciones = [
    { clave: "paleta", activo: false, nombre: "Paleta" },
    { clave: "grande", activo: true, nombre: "Grande" },
    { clave: "chico", activo: true, nombre: "Chico" },
    { clave: "plastico_negro", activo: false, nombre: "Plástico negro" },
    { clave: "plastico_cafe", activo: true, nombre: "Plástico café" }
  ];

  // Caso A: Creando equipo nuevo (o ninguna inactiva seleccionada) -> paleta y plastico_negro se ocultan
  const visiblesNuevo = filtrarOpcionesVisibles(opciones, clave => clave === "grande");
  assertEquals(visiblesNuevo.map(o => o.clave), ["grande", "chico", "plastico_cafe"]);

  // Caso B: Editando equipo viejo que tenía paleta guardada -> paleta es visible, plastico_negro se oculta
  const visiblesConPaleta = filtrarOpcionesVisibles(opciones, clave => clave === "paleta");
  assertEquals(visiblesConPaleta.map(o => o.clave), ["paleta", "grande", "chico", "plastico_cafe"]);

  // Caso C: Editando equipo viejo con plastico_negro guardado -> plastico_negro es visible, paleta se oculta
  const visiblesConPlastico = filtrarOpcionesVisibles(opciones, new Set(["plastico_negro"]));
  assertEquals(visiblesConPlastico.map(o => o.clave), ["grande", "chico", "plastico_negro", "plastico_cafe"]);
});


