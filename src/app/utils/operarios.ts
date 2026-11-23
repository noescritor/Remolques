/**
 * `GET /produccion/operarios` responde `{ operarios: [...] }`.
 * Esta función normaliza la respuesta a un arreglo (acepta también un arreglo directo)
 * y descarta cualquier otra forma, para que la pantalla nunca reciba un objeto donde espera una lista.
 */
export function extraerListaOperarios(res: unknown): any[] {
  if (Array.isArray(res)) return res;
  const lista = (res as { operarios?: unknown } | null | undefined)?.operarios;
  return Array.isArray(lista) ? lista : [];
}
