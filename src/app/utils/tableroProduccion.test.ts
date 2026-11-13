// @ts-nocheck
import { assertEquals } from "jsr:@std/assert@^1.0.0";
import {
  obtenerLineaPorTipoEquipo,
  calcularSemaforo,
  calcularEtiquetaVisible,
  CeldaSemaforoInput,
  parsearFechaPartes,
  formatearFechaCorta,
  formatearFechaLarga,
  formatearFechaHoyCompleta,
  sumarDiasAFecha,
  calcularEstadoVisualCelda,
  filtrarFilasMatriz,
  agruparPorFase,
  aplicarCambioOptimistaFase,
} from "./tableroProduccion.ts";

Deno.test("tableroProduccion: mapeo de tipo de equipo a línea canónica", () => {
  assertEquals(obtenerLineaPorTipoEquipo("01"), "plataforma");
  assertEquals(obtenerLineaPorTipoEquipo("02"), "dolly");
  assertEquals(obtenerLineaPorTipoEquipo("03"), "gondola");
  assertEquals(obtenerLineaPorTipoEquipo("04"), "plataforma");
  assertEquals(obtenerLineaPorTipoEquipo("05"), "plataforma");
  assertEquals(obtenerLineaPorTipoEquipo("06"), "plataforma");
  assertEquals(obtenerLineaPorTipoEquipo("07"), "plataforma");
  assertEquals(obtenerLineaPorTipoEquipo("08"), "plataforma");
  assertEquals(obtenerLineaPorTipoEquipo("09"), "traila");

  // Fallbacks por texto
  assertEquals(obtenerLineaPorTipoEquipo("Dolly 2 ejes"), "dolly");
  assertEquals(obtenerLineaPorTipoEquipo("Góndola 30m3"), "gondola");
  assertEquals(obtenerLineaPorTipoEquipo("Gondola ligera"), "gondola");
  assertEquals(obtenerLineaPorTipoEquipo("Traila Ganadera"), "traila");
  assertEquals(obtenerLineaPorTipoEquipo("Plataforma 40 ft"), "plataforma");
  assertEquals(obtenerLineaPorTipoEquipo(null), "plataforma");
});

Deno.test("tableroProduccion: calcularSemaforo - precedencias y estados", () => {
  const hoy = "2026-11-12";

  // 1. Terminado
  const todasTerminadas: CeldaSemaforoInput[] = [
    { estado: "terminada", fecha_propuesta: "2026-11-10" },
    { estado: "terminada", fecha_propuesta: "2026-11-11" },
  ];
  assertEquals(calcularSemaforo(todasTerminadas, hoy), "terminado");

  // 2. Por iniciar
  const todasPendientes: CeldaSemaforoInput[] = [
    { estado: "pendiente" },
    { estado: "pendiente" },
  ];
  assertEquals(calcularSemaforo(todasPendientes, hoy), "por_iniciar");
  assertEquals(calcularSemaforo([], hoy), "por_iniciar");

  // 3. En tiempo (en_proceso con propuesta futura o igual a hoy)
  const enTiempo: CeldaSemaforoInput[] = [
    { estado: "terminada", fecha_propuesta: "2026-11-10" },
    { estado: "en_proceso", fecha_propuesta: "2026-11-13" },
    { estado: "pendiente" },
  ];
  assertEquals(calcularSemaforo(enTiempo, hoy), "en_tiempo");

  const enTiempoHoy: CeldaSemaforoInput[] = [
    { estado: "en_proceso", fecha_propuesta: "2026-11-12" },
  ];
  assertEquals(calcularSemaforo(enTiempoHoy, hoy), "en_tiempo");

  // 4. Atrasado (propuesta anterior a hoy)
  const atrasada: CeldaSemaforoInput[] = [
    { estado: "terminada", fecha_propuesta: "2026-11-08" },
    { estado: "en_proceso", fecha_propuesta: "2026-11-11" }, // Ayer
    { estado: "pendiente" },
  ];
  assertEquals(calcularSemaforo(atrasada, hoy), "atrasado");

  // 5. Precedencia: atrasado gana a detenido (incompleta/pausada)
  const atrasadaYDetenida: CeldaSemaforoInput[] = [
    { estado: "en_proceso", fecha_propuesta: "2026-11-10" }, // Atrasada
    { estado: "incompleta", fecha_propuesta: "2026-11-15" }, // Detenida
  ];
  assertEquals(calcularSemaforo(atrasadaYDetenida, hoy), "atrasado");

  // 6. Detenido (incompleta o pausada sin ninguna atrasada)
  const detenidaIncompleta: CeldaSemaforoInput[] = [
    { estado: "en_proceso", fecha_propuesta: "2026-11-14" },
    { estado: "incompleta", fecha_propuesta: "2026-11-15" },
  ];
  assertEquals(calcularSemaforo(detenidaIncompleta, hoy), "detenido");

  const detenidaPausada: CeldaSemaforoInput[] = [
    { estado: "pausada", fecha_propuesta: "2026-11-14" },
    { estado: "pendiente" },
  ];
  assertEquals(calcularSemaforo(detenidaPausada, hoy), "detenido");

  // 7. Soporte para formato Record<string, Celda> y conteo de tina
  const mapaCeldas: Record<string, CeldaSemaforoInput> = {
    fase_corte: { estado: "terminada" },
    fase_tina_resoldado: { estado: "en_proceso", fecha_propuesta: "2026-11-10" }, // Tina atrasada
    fase_montado: { estado: "pendiente" },
  };
  assertEquals(calcularSemaforo(mapaCeldas, hoy), "atrasado");
});

Deno.test("tableroProduccion: calcularEtiquetaVisible - formato manual y correlativos por cliente", () => {
  // 1. Etiqueta manual gana siempre
  const manual = {
    id: "ord-1",
    etiqueta: "Traila A-05 Azul Marino",
    cliente_nombre: "Ferretería Pirámide",
    created_at: "2026-11-10T10:00:00Z",
  };
  assertEquals(
    calcularEtiquetaVisible(manual, [
      { id: "ord-1", created_at: "2026-11-10T10:00:00Z" },
      { id: "ord-2", created_at: "2026-11-11T10:00:00Z" },
    ]),
    "Traila A-05 Azul Marino"
  );

  // 2. Solo 1 orden para el cliente -> Sin número
  const unica = {
    id: "ord-1",
    etiqueta: null,
    cliente_nombre: "Efren",
    created_at: "2026-11-10T10:00:00Z",
  };
  assertEquals(calcularEtiquetaVisible(unica, [{ id: "ord-1", created_at: "2026-11-10T10:00:00Z" }]), "Efren");

  // 3. Múltiples órdenes para el mismo cliente y línea -> "Cliente #n" por created_at
  const grupo = [
    { id: "ord-b", created_at: "2026-11-10T12:00:00Z" },
    { id: "ord-a", created_at: "2026-11-10T08:00:00Z" },
    { id: "ord-c", created_at: "2026-11-11T09:00:00Z" },
  ];

  assertEquals(
    calcularEtiquetaVisible({ id: "ord-a", cliente_nombre: "Saul Salas", created_at: "2026-11-10T08:00:00Z" }, grupo),
    "Saul Salas #1"
  );
  assertEquals(
    calcularEtiquetaVisible({ id: "ord-b", cliente_nombre: "Saul Salas", created_at: "2026-11-10T12:00:00Z" }, grupo),
    "Saul Salas #2"
  );
  assertEquals(
    calcularEtiquetaVisible({ id: "ord-c", cliente_nombre: "Saul Salas", created_at: "2026-11-11T09:00:00Z" }, grupo),
    "Saul Salas #3"
  );

  // 4. Sin cliente y sin etiqueta -> Inventario
  const inventario = { id: "ord-x", etiqueta: null, cliente_nombre: null };
  assertEquals(calcularEtiquetaVisible(inventario, []), "Inventario");
});

Deno.test("tableroProduccion: formateo de fechas y prevención de trampa UTC", () => {
  // Formato simple YYYY-MM-DD no debe retrasarse al día anterior
  assertEquals(formatearFechaCorta("2026-11-06"), "06 nov");
  assertEquals(formatearFechaCorta("2026-11-14"), "14 nov");
  assertEquals(formatearFechaCorta("2026-01-01"), "01 ene");
  assertEquals(formatearFechaCorta("2026-12-31"), "31 dic");

  // Formato largo para aria-label
  assertEquals(formatearFechaLarga("2026-11-06"), "6 de noviembre");
  assertEquals(formatearFechaLarga("2026-05-15"), "15 de mayo");

  // Formato completo para cabecera superior
  assertEquals(formatearFechaHoyCompleta("2026-11-12"), "jueves, 12 de noviembre de 2026");
  assertEquals(formatearFechaHoyCompleta("2026-11-13"), "viernes, 13 de noviembre de 2026");

  // Manejo de valores nulos o vacíos
  assertEquals(formatearFechaCorta(null), "");
  assertEquals(formatearFechaCorta(""), "");

  // Sumar y restar días
  assertEquals(sumarDiasAFecha("2026-11-14", 1), "2026-11-15");
  assertEquals(sumarDiasAFecha("2026-11-14", -1), "2026-11-13");
  assertEquals(sumarDiasAFecha("2026-11-01", -1), "2026-10-31");
  assertEquals(sumarDiasAFecha("2026-12-31", 1), "2027-01-01");
});

Deno.test("tableroProduccion: calcularEstadoVisualCelda - textos, colores y aria-labels", () => {
  const hoy = "2026-11-12";

  // 1. Terminada
  const terminada = calcularEstadoVisualCelda(
    { estado: "terminada", fecha_fin: "2026-11-06" },
    "Corte",
    hoy
  );
  assertEquals(terminada.estado, "terminada");
  assertEquals(terminada.texto, "✓ 06 nov");
  assertEquals(terminada.esVencida, false);
  assertEquals(terminada.ariaLabel, "Corte: terminada el 6 de noviembre");
  assertEquals(terminada.claseColor.includes("#22c55e") || terminada.claseColor.includes("#91FFB0"), true);

  // 2. En proceso en tiempo
  const enProceso = calcularEstadoVisualCelda(
    { estado: "en_proceso", fecha_propuesta: "2026-11-14" },
    "Dispositivo",
    hoy
  );
  assertEquals(enProceso.estado, "en_proceso");
  assertEquals(enProceso.texto, "→ 14 nov");
  assertEquals(enProceso.esVencida, false);
  assertEquals(enProceso.claseColor.includes("text-primary"), true);

  // 3. En proceso vencida (fecha_propuesta < hoy)
  const vencida = calcularEstadoVisualCelda(
    { estado: "en_proceso", fecha_propuesta: "2026-11-11" },
    "IPR",
    hoy
  );
  assertEquals(vencida.estado, "en_proceso");
  assertEquals(vencida.texto, "→ 11 nov !");
  assertEquals(vencida.esVencida, true);
  assertEquals(vencida.ariaLabel.includes("atrasada"), true);
  assertEquals(vencida.claseColor.includes("destructive") || vencida.claseColor.includes("#FF919F"), true);

  // 4. Incompleta (Material)
  const incompleta = calcularEstadoVisualCelda(
    { estado: "incompleta" },
    "Perchas",
    hoy
  );
  assertEquals(incompleta.estado, "incompleta");
  assertEquals(incompleta.texto, "Material");
  assertEquals(incompleta.claseColor.includes("border-transparent"), true);

  // 5. Pausada (Pausa)
  const pausada = calcularEstadoVisualCelda(
    { estado: "pausada" },
    "Pintura",
    hoy
  );
  assertEquals(pausada.estado, "pausada");
  assertEquals(pausada.texto, "Pausa");
  assertEquals(pausada.claseColor.includes("amber") || pausada.claseColor.includes("#FFD391"), true);

  // 6. Pendiente (·)
  const pendiente = calcularEstadoVisualCelda(
    { estado: "pendiente" },
    "Piso",
    hoy
  );
  assertEquals(pendiente.estado, "pendiente");
  assertEquals(pendiente.texto, "·");
});

Deno.test("tableroProduccion: filtrarFilasMatriz por chip y búsqueda de texto", () => {
  const filasMock = [
    {
      orden_id: "ord-1",
      etiqueta: "Transportes Azteca #1",
      cliente_nombre: "Transportes Azteca",
      cotizacion_folio: "COT-101",
      modelo: "Plataforma 40ft",
      semaforo: "atrasado",
      material_faltante: "Tornillos 1/2",
      estado_kanban: "incompleta",
      celdas: { f1: { estado: "en_proceso" } },
    },
    {
      orden_id: "ord-2",
      etiqueta: "Ferretería Pirámide",
      cliente_nombre: "Ferretería Pirámide",
      cotizacion_folio: "COT-102",
      modelo: "Dolly H",
      semaforo: "detenido",
      material_faltante: null,
      estado_kanban: "pausada",
      celdas: { f1: { estado: "pausada" } },
    },
    {
      orden_id: "ord-3",
      etiqueta: "Plana Stock 3 ejes",
      cliente_nombre: "Inventario",
      cotizacion_folio: "Manual",
      modelo: "Plataforma 43ft",
      semaforo: "en_tiempo",
      material_faltante: null,
      estado_kanban: "en_proceso",
      celdas: { f1: { estado: "en_proceso" } },
    },
  ];

  // 1. Chip 'todos'
  assertEquals(filtrarFilasMatriz(filasMock, "todos").length, 3);

  // 2. Chip 'atrasados'
  const atrasados = filtrarFilasMatriz(filasMock, "atrasados");
  assertEquals(atrasados.length, 1);
  assertEquals(atrasados[0].orden_id, "ord-1");

  // 3. Chip 'con_material'
  const conMaterial = filtrarFilasMatriz(filasMock, "con_material");
  assertEquals(conMaterial.length, 1);
  assertEquals(conMaterial[0].orden_id, "ord-1");

  // 4. Chip 'con_pausa'
  const conPausa = filtrarFilasMatriz(filasMock, "con_pausa");
  assertEquals(conPausa.length, 1);
  assertEquals(conPausa[0].orden_id, "ord-2");

  // 5. Búsqueda por cliente
  assertEquals(filtrarFilasMatriz(filasMock, "todos", "Pirámide").length, 1);
  assertEquals(filtrarFilasMatriz(filasMock, "todos", "piramide").length, 1);

  // 6. Búsqueda por folio o modelo
  assertEquals(filtrarFilasMatriz(filasMock, "todos", "COT-101").length, 1);
  assertEquals(filtrarFilasMatriz(filasMock, "todos", "43ft").length, 1);
  assertEquals(filtrarFilasMatriz(filasMock, "todos", "inexistente").length, 0);
});

Deno.test("tableroProduccion: agruparPorFase duplica equipos con múltiples fases activas", () => {
  const fasesPrincipales = [
    { id: "f1", orden: 1, nombre: "Corte", grupo: "principal" },
    { id: "f2", orden: 2, nombre: "Ensamble", grupo: "principal" },
    { id: "f3", orden: 3, nombre: "Pintura", grupo: "principal" },
  ];

  const filas = [
    // ord-1 tiene dos fases abiertas: f1 (incompleta) y f2 (en_proceso)
    {
      orden_id: "ord-1",
      etiqueta: "Equipo Multitarea",
      modelo: "Plataforma 40",
      estado: "En Producción",
      material_faltante: "Falta soldadura",
      celdas: {
        f1: { estado: "incompleta" },
        f2: { estado: "en_proceso", fecha_propuesta: "2026-11-15" },
        f3: { estado: "pendiente" },
      },
    },
    // ord-2 no ha iniciado
    {
      orden_id: "ord-2",
      etiqueta: "Equipo Nuevo",
      modelo: "Dolly",
      estado: "Pendiente",
      material_faltante: null,
      celdas: {
        f1: { estado: "pendiente" },
        f2: { estado: "pendiente" },
        f3: { estado: "pendiente" },
      },
    },
  ];

  const columnas = agruparPorFase(filas, fasesPrincipales);

  // Columnas: Por iniciar, f1 (Corte), f2 (Ensamble), f3 (Pintura)
  assertEquals(columnas.length, 4);
  assertEquals(columnas[0].id, "por_iniciar");
  assertEquals(columnas[1].id, "f1");
  assertEquals(columnas[2].id, "f2");
  assertEquals(columnas[3].id, "f3");

  // Columna Por iniciar contiene ord-2
  assertEquals(columnas[0].tarjetas.length, 1);
  assertEquals(columnas[0].tarjetas[0].orden_id, "ord-2");

  // Columna f1 contiene ord-1 (incompleta)
  assertEquals(columnas[1].tarjetas.length, 1);
  assertEquals(columnas[1].tarjetas[0].orden_id, "ord-1");
  assertEquals(columnas[1].tarjetas[0].estado_fase, "incompleta");

  // Columna f2 contiene TAMBIÉN ord-1 (en_proceso) -> Duplicación intencional por fases en paralelo
  assertEquals(columnas[2].tarjetas.length, 1);
  assertEquals(columnas[2].tarjetas[0].orden_id, "ord-1");
  assertEquals(columnas[2].tarjetas[0].estado_fase, "en_proceso");

  // Columna f3 no contiene tarjetas
  assertEquals(columnas[3].tarjetas.length, 0);
});

Deno.test("tableroProduccion: aplicarCambioOptimistaFase actualiza celda, semáforo y permite reversa", () => {
  const fases = [
    { id: "f1", orden: 1, nombre: "Corte", grupo: "principal" },
    { id: "f2", orden: 2, nombre: "Ensamble", grupo: "principal" },
  ];

  const filas = [
    {
      orden_id: "ord-1",
      etiqueta: "Plataforma #1",
      semaforo: "por_iniciar",
      avance: { terminadas: 0, total: 2 },
      tina: null,
      celdas: {
        f1: { estado: "pendiente", fecha_propuesta: null, fecha_fin: null },
        f2: { estado: "pendiente", fecha_propuesta: null, fecha_fin: null },
      },
    },
  ];

  // Aplicar cambio optimista: iniciar f1
  const { filasActualizadas, filaAnterior } = aplicarCambioOptimistaFase(
    filas,
    "ord-1",
    "f1",
    { estado: "en_proceso", fecha_propuesta: "2026-11-15" },
    fases,
    "2026-11-12"
  );

  assertEquals(filasActualizadas[0].celdas.f1.estado, "en_proceso");
  assertEquals(filasActualizadas[0].celdas.f1.fecha_propuesta, "2026-11-15");
  assertEquals(filasActualizadas[0].semaforo, "en_tiempo");

  // Reversa usando filaAnterior
  assertEquals(filaAnterior.celdas.f1.estado, "pendiente");
  assertEquals(filaAnterior.semaforo, "por_iniciar");

  // Aplicar cambio optimista: terminar f1
  const cambioTerminar = aplicarCambioOptimistaFase(
    filasActualizadas,
    "ord-1",
    "f1",
    { estado: "terminada" },
    fases,
    "2026-11-12"
  );

  assertEquals(cambioTerminar.filasActualizadas[0].celdas.f1.estado, "terminada");
  assertEquals(cambioTerminar.filasActualizadas[0].celdas.f1.fecha_fin, "2026-11-12");
  assertEquals(cambioTerminar.filasActualizadas[0].avance.terminadas, 1);
});
