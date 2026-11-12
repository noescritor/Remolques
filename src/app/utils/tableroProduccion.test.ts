// @ts-nocheck
import { assertEquals } from "jsr:@std/assert@^1.0.0";
import {
  obtenerLineaPorTipoEquipo,
  calcularSemaforo,
  calcularEtiquetaVisible,
  CeldaSemaforoInput,
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
