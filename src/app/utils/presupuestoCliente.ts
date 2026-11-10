export interface ClienteLike {
  id?: string;
  nombre_comercial?: string | null;
  razon_social?: string | null;
  nombre_razon_social?: string | null;
  [key: string]: any;
}

export interface PresupuestoLike {
  id?: string;
  cliente_id?: string | null;
  folio?: string | null;
  concepto?: string | null;
  nomenclatura_id?: string | null;
  nomenclatura?: string | null;
  cliente?: ClienteLike | null;
  [key: string]: any;
}

/**
 * Normaliza una cadena eliminando acentos/diacríticos y pasando a minúsculas
 * para búsquedas insensibles a mayúsculas y tildes.
 */
export function normalizarTexto(texto: string): string {
  return texto
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase();
}

/**
 * Obtiene el nombre del cliente para un presupuesto.
 * Usa primero presupuesto.cliente (el que ya trae el API);
 * si no viene, busca presupuesto.cliente_id en la lista de clientes;
 * el criterio de nombre es nombre_comercial || razon_social (el mismo criterio del editor y del PDF);
 * si no hay cliente, devuelve "Sin cliente".
 */
export function nombreClientePresupuesto(
  presupuesto: PresupuestoLike | null | undefined,
  clientes?: ClienteLike[] | null
): string {
  if (!presupuesto) return 'Sin cliente';

  let cli: ClienteLike | null | undefined = presupuesto.cliente;

  if (!cli && presupuesto.cliente_id && Array.isArray(clientes)) {
    cli = clientes.find(c => c && c.id === presupuesto.cliente_id);
  }

  if (!cli) return 'Sin cliente';

  const nombre = (cli.nombre_comercial || cli.razon_social || cli.nombre_razon_social || '')?.trim();
  return nombre.length > 0 ? nombre : 'Sin cliente';
}

/**
 * Determina si un presupuesto coincide con el término de búsqueda.
 * Busca, sin distinguir mayúsculas ni acentos, en:
 * - folio
 * - concepto
 * - nomenclatura (nomenclatura_id o nomenclatura)
 * - nombre del cliente
 *
 * Un texto vacío retorna true.
 */
export function coincideBusquedaPresupuesto(
  presupuesto: PresupuestoLike | null | undefined,
  clientes: ClienteLike[] | null | undefined,
  texto: string | null | undefined
): boolean {
  if (!texto || texto.trim().length === 0) {
    return true;
  }
  if (!presupuesto) {
    return false;
  }

  const queryNorm = normalizarTexto(texto.trim());

  const folioNorm = normalizarTexto(presupuesto.folio || '');
  if (folioNorm.includes(queryNorm)) return true;

  const conceptoNorm = normalizarTexto(presupuesto.concepto || '');
  if (conceptoNorm.includes(queryNorm)) return true;

  const nomNorm = normalizarTexto(presupuesto.nomenclatura_id || presupuesto.nomenclatura || '');
  if (nomNorm.includes(queryNorm)) return true;

  const nombreCli = nombreClientePresupuesto(presupuesto, clientes);
  const cliNorm = normalizarTexto(nombreCli);
  if (cliNorm.includes(queryNorm)) return true;

  return false;
}

/**
 * Genera el título para PresupuestoEditor:
 * - Nuevo presupuesto (sin presupuesto): "Nuevo Presupuesto"
 * - Presupuesto con cliente (inicial o seleccionado): "Editar Presupuesto {folio} · {nombreCliente}"
 * - Presupuesto sin cliente (o si el usuario selecciona "ninguno"): "Editar Presupuesto {folio}"
 */
export function tituloEditorPresupuesto(
  presupuesto: PresupuestoLike | null | undefined,
  clienteId: string | null | undefined,
  clientes?: ClienteLike[] | null
): string {
  if (!presupuesto) return 'Nuevo Presupuesto';
  const folio = presupuesto.folio || '';
  const idCli = (clienteId && clienteId !== 'ninguno') ? clienteId : null;
  const clientePresupuesto = (idCli && presupuesto.cliente?.id === idCli) ? presupuesto.cliente : undefined;
  const nombreCli = nombreClientePresupuesto({ cliente: clientePresupuesto, cliente_id: idCli }, clientes);
  const tieneCliente = nombreCli !== 'Sin cliente';

  return tieneCliente
    ? `Editar Presupuesto ${folio} · ${nombreCli}`
    : `Editar Presupuesto ${folio}`;
}
