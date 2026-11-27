import { useState, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { Button } from '../ui/button';
import { Input } from '../ui/input';
import { Label } from '../ui/label';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '../ui/table';
import { Card, CardContent, CardHeader, CardTitle } from '../ui/card';
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle, DialogFooter } from '../ui/dialog';
import { Skeleton } from '../ui/skeleton';
import {
  Search,
  Plus,
  AlertTriangle,
  CheckCircle,
  PackageMinus,
  History,
  PackageCheck,
  RefreshCw,
  Ban,
  ExternalLink,
  Loader2,
} from 'lucide-react';
import { Producto, MovimientoInventario } from '../../types';
import { toast } from 'sonner';
import { supabase } from '../../utils/supabase/client';
import {
  formatearCantidadStock,
  fetchRecepcionesAlmacenApi,
  anularRecepcionAlmacenApi,
  RecepcionAlmacenItem,
} from '../../utils/almacenApi';

interface InventarioListProps {
  productos: Producto[];
  loading: boolean;
  obtenerMovimientosInventario: () => Promise<MovimientoInventario[]>;
  registrarMovimientoInventario: (movimiento: Partial<MovimientoInventario>) => Promise<any>;
  onRecargarProductos?: () => Promise<void> | void;
}

function fmtMonedaMxn(n: number | null | undefined): string {
  if (n === null || n === undefined || !Number.isFinite(Number(n))) return '—';
  return new Intl.NumberFormat('es-MX', {
    style: 'currency',
    currency: 'MXN',
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(Number(n));
}

export function InventarioList({
  productos,
  loading,
  obtenerMovimientosInventario,
  registrarMovimientoInventario,
  onRecargarProductos,
}: InventarioListProps) {
  const navigate = useNavigate();
  const [busqueda, setBusqueda] = useState('');
  const [modalOpen, setModalOpen] = useState(false);
  const [historialOpen, setHistorialOpen] = useState(false);
  const [movimientos, setMovimientos] = useState<MovimientoInventario[]>([]);
  const [loadingHistorial, setLoadingHistorial] = useState(false);

  // Recepciones de facturas (Bloque G)
  const [recepcionesOpen, setRecepcionesOpen] = useState(false);
  const [estadoRecepciones, setEstadoRecepciones] = useState<'cargando' | 'error' | 'ok'>('cargando');
  const [errorRecepciones, setErrorRecepciones] = useState<string | null>(null);
  const [recepciones, setRecepciones] = useState<RecepcionAlmacenItem[]>([]);
  const [filtroEstadoRec, setFiltroEstadoRec] = useState<'todas' | 'recibida' | 'anulada'>('todas');

  // Diálogo de anulación de recepción
  const [recepcionAAnular, setRecepcionAAnular] = useState<RecepcionAlmacenItem | null>(null);
  const [motivoAnulacion, setMotivoAnulacion] = useState('');
  const [anulandoRec, setAnulandoRec] = useState(false);

  const [productoSeleccionado, setProductoSeleccionado] = useState<string>('');
  const [formData, setFormData] = useState({
    tipo_movimiento: 'Entrada' as 'Entrada' | 'Salida' | 'Ajuste' | 'Devolucion_Interna' | 'Devolucion_Cliente' | 'Devolucion_Proveedor',
    cantidad: 1,
    referencia: '',
  });

  // Filtramos solo los bienes (los servicios no tienen inventario)
  const bienes = productos.filter((p) => p.tipo === 'bien');
  const productosFiltrados = bienes.filter(
    (p) =>
      p.nombre.toLowerCase().includes(busqueda.toLowerCase()) ||
      (p.descripcion && p.descripcion.toLowerCase().includes(busqueda.toLowerCase()))
  );

  const cargarHistorial = async () => {
    setLoadingHistorial(true);
    try {
      const data = await obtenerMovimientosInventario();
      setMovimientos(data);
    } catch {
      toast.error('Error al cargar historial de inventario');
    } finally {
      setLoadingHistorial(false);
    }
  };

  const handleOpenHistorial = () => {
    setHistorialOpen(true);
    cargarHistorial();
  };

  const cargarRecepciones = useCallback(async (estadoFiltro: 'todas' | 'recibida' | 'anulada' = filtroEstadoRec) => {
    setEstadoRecepciones('cargando');
    setErrorRecepciones(null);
    try {
      const lista = await fetchRecepcionesAlmacenApi(supabase, {
        estado: estadoFiltro === 'todas' ? undefined : estadoFiltro,
      });
      setRecepciones(Array.isArray(lista) ? lista : []);
      setEstadoRecepciones('ok');
    } catch (err: any) {
      setErrorRecepciones(err?.message || 'No se pudieron cargar las recepciones de almacén.');
      setEstadoRecepciones('error');
    }
  }, [filtroEstadoRec]);

  const handleOpenRecepciones = () => {
    setRecepcionesOpen(true);
    cargarRecepciones(filtroEstadoRec);
  };

  const handleCambiarFiltroRecepciones = (nuevo: 'todas' | 'recibida' | 'anulada') => {
    setFiltroEstadoRec(nuevo);
    cargarRecepciones(nuevo);
  };

  const handleConfirmarAnularRecepcion = async () => {
    if (!recepcionAAnular || anulandoRec) return;
    if (!motivoAnulacion.trim()) {
      toast.error('Escribe el motivo de la anulación');
      return;
    }
    setAnulandoRec(true);
    try {
      await anularRecepcionAlmacenApi(supabase, recepcionAAnular.id, motivoAnulacion.trim());
      toast.success('Recepción anulada y existencias revertidas');
      setRecepcionAAnular(null);
      setMotivoAnulacion('');
      await cargarRecepciones(filtroEstadoRec);
      await onRecargarProductos?.();
    } catch (err: any) {
      toast.error(err?.message || 'No se pudo anular la recepción');
    } finally {
      setAnulandoRec(false);
    }
  };

  const handleGuardarAjuste = async () => {
    if (!productoSeleccionado) {
      toast.error('Selecciona un producto');
      return;
    }
    if (!Number.isFinite(formData.cantidad) || formData.cantidad <= 0) {
      toast.error('La cantidad debe ser mayor a 0');
      return;
    }

    try {
      await registrarMovimientoInventario({
        producto_id: productoSeleccionado,
        tipo_movimiento: formData.tipo_movimiento,
        cantidad: formData.cantidad,
        referencia: formData.referencia || 'Ajuste manual',
      });
      toast.success('Movimiento registrado con éxito');
      setModalOpen(false);
      setFormData({ tipo_movimiento: 'Entrada', cantidad: 1, referencia: '' });
      setProductoSeleccionado('');
    } catch (error: any) {
      console.error('Error al registrar movimiento:', error);
      const msg = error?.message || JSON.stringify(error) || 'Error desconocido';
      toast.error(`Error al registrar movimiento: ${msg}`);
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap justify-between items-center gap-3">
        <div>
          <h2 className="text-2xl font-bold tracking-tight text-foreground">Inventario</h2>
          <p className="text-muted-foreground">Gestión de existencias y almacén</p>
        </div>
        <div className="flex flex-wrap gap-2">
          <Button variant="outline" onClick={handleOpenRecepciones}>
            <PackageCheck className="w-4 h-4 mr-2" />
            Recepciones
          </Button>
          <Button variant="outline" onClick={handleOpenHistorial}>
            <History className="w-4 h-4 mr-2" />
            Historial
          </Button>
          <Button onClick={() => setModalOpen(true)}>
            <Plus className="w-4 h-4 mr-2" />
            Ajuste Manual
          </Button>
        </div>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Productos Físicos</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="flex items-center gap-2 mb-6">
            <div className="relative flex-1 max-w-sm">
              <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
              <Input
                placeholder="Buscar por nombre..."
                className="pl-8"
                value={busqueda}
                onChange={(e) => setBusqueda(e.target.value)}
              />
            </div>
          </div>

          {loading ? (
            <div className="space-y-2">
              <Skeleton className="h-12 w-full" />
              <Skeleton className="h-12 w-full" />
              <Skeleton className="h-12 w-full" />
            </div>
          ) : (
            <div className="rounded-md border border-border overflow-x-auto">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Producto</TableHead>
                    <TableHead className="text-right">Stock Actual</TableHead>
                    <TableHead className="text-right">Stock Reservado</TableHead>
                    <TableHead className="text-right">Stock Disponible</TableHead>
                    <TableHead className="text-right">Último costo compra (s/IVA)</TableHead>
                    <TableHead>Estado</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {productosFiltrados.length === 0 ? (
                    <TableRow>
                      <TableCell colSpan={6} className="text-center py-8 text-muted-foreground">
                        No se encontraron bienes en el inventario.
                      </TableCell>
                    </TableRow>
                  ) : (
                    productosFiltrados.map((producto) => {
                      const actual = Number(producto.stock_actual || 0);
                      const reservado = Number(producto.stock_reservado || 0);
                      const min = Number(producto.stock_minimo || 0);
                      const disponible = actual - reservado;

                      let estado = (
                        <span className="flex items-center text-emerald-600 dark:text-emerald-400">
                          <CheckCircle className="w-4 h-4 mr-1" /> Normal
                        </span>
                      );
                      if (disponible <= 0) {
                        estado = (
                          <span className="flex items-center text-destructive">
                            <PackageMinus className="w-4 h-4 mr-1" /> Agotado
                          </span>
                        );
                      } else if (disponible <= min) {
                        estado = (
                          <span className="flex items-center text-amber-600 dark:text-amber-400">
                            <AlertTriangle className="w-4 h-4 mr-1" /> Bajo Stock
                          </span>
                        );
                      }

                      return (
                        <TableRow key={producto.id}>
                          <TableCell className="font-medium text-foreground">
                            <div>{producto.nombre}</div>
                            {producto.unidad && (
                              <div className="text-[11px] text-muted-foreground">{producto.unidad}</div>
                            )}
                          </TableCell>
                          <TableCell className="text-right font-mono">{formatearCantidadStock(actual)}</TableCell>
                          <TableCell className="text-right font-mono text-amber-600 dark:text-amber-400">
                            {formatearCantidadStock(reservado)}
                          </TableCell>
                          <TableCell className="text-right font-mono font-bold text-foreground">
                            {formatearCantidadStock(disponible)}
                          </TableCell>
                          <TableCell className="text-right">
                            {producto.ultimo_costo_compra !== null && producto.ultimo_costo_compra !== undefined ? (
                              <div className="flex flex-col items-end">
                                <span className="font-mono font-medium text-foreground">
                                  {fmtMonedaMxn(producto.ultimo_costo_compra)}
                                </span>
                                <div className="flex items-center gap-1.5 text-[10px] text-muted-foreground">
                                  {producto.ultimo_costo_compra_fecha && (
                                    <span>{String(producto.ultimo_costo_compra_fecha).slice(0, 10)}</span>
                                  )}
                                  {producto.ultimo_costo_compra_factura_id && (
                                    <button
                                      type="button"
                                      onClick={() => navigate('/cxp?tab=facturas')}
                                      className="inline-flex items-center gap-0.5 text-primary hover:underline"
                                      title="Ver facturas de proveedores en CxP"
                                    >
                                      CxP
                                      <ExternalLink className="w-2.5 h-2.5" />
                                    </button>
                                  )}
                                </div>
                              </div>
                            ) : (
                              <span className="text-xs text-muted-foreground">—</span>
                            )}
                          </TableCell>
                          <TableCell>{estado}</TableCell>
                        </TableRow>
                      );
                    })
                  )}
                </TableBody>
              </Table>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Modal de Ajuste Manual */}
      <Dialog open={modalOpen} onOpenChange={setModalOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Registrar Movimiento Manual</DialogTitle>
            <DialogDescription>
              Ajusta el stock actual de un producto. Use Entrada para agregar y Salida para retirar.
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-4 py-4">
            <div className="space-y-2">
              <Label>Producto</Label>
              <select
                className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50"
                value={productoSeleccionado}
                onChange={(e) => setProductoSeleccionado(e.target.value)}
              >
                <option value="">Selecciona un producto...</option>
                {bienes.map((p) => (
                  <option key={p.id} value={p.id}>
                    {p.nombre} (Stock: {formatearCantidadStock(p.stock_actual || 0)})
                  </option>
                ))}
              </select>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>Tipo de Movimiento</Label>
                <select
                  className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background"
                  value={formData.tipo_movimiento}
                  onChange={(e) => setFormData({ ...formData, tipo_movimiento: e.target.value as any })}
                >
                  <option value="Entrada">Entrada (+)</option>
                  <option value="Salida">Salida (-)</option>
                  <option value="Ajuste">Ajuste / Mermas</option>
                  <option value="Devolucion_Interna">Devolución Interna</option>
                  <option value="Devolucion_Cliente">Devolución de Cliente</option>
                  <option value="Devolucion_Proveedor">Devolución a Proveedor</option>
                </select>
              </div>
              <div className="space-y-2">
                <Label>Cantidad</Label>
                <Input
                  type="number"
                  step="any"
                  min="0.0001"
                  value={formData.cantidad}
                  onChange={(e) => setFormData({ ...formData, cantidad: parseFloat(e.target.value) || 0 })}
                />
              </div>
            </div>

            <div className="space-y-2">
              <Label>Referencia / Motivo</Label>
              <Input
                placeholder="Ej. Compra de inventario, merma, etc."
                value={formData.referencia}
                onChange={(e) => setFormData({ ...formData, referencia: e.target.value })}
              />
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setModalOpen(false)}>
              Cancelar
            </Button>
            <Button onClick={handleGuardarAjuste}>Guardar Movimiento</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Modal Historial */}
      <Dialog open={historialOpen} onOpenChange={setHistorialOpen}>
        <DialogContent className="max-w-4xl max-h-[80vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>Historial de Movimientos</DialogTitle>
          </DialogHeader>
          {loadingHistorial ? (
            <div className="py-8 text-center text-muted-foreground">Cargando historial...</div>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Fecha</TableHead>
                  <TableHead>Producto</TableHead>
                  <TableHead>Tipo</TableHead>
                  <TableHead className="text-right">Cant.</TableHead>
                  <TableHead>Referencia</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {movimientos.map((mov) => (
                  <TableRow key={mov.id}>
                    <TableCell className="text-xs">{new Date(mov.created_at).toLocaleString()}</TableCell>
                    <TableCell className="font-medium text-foreground">{mov.producto?.nombre || 'Desconocido'}</TableCell>
                    <TableCell>
                      <span
                        className={`px-2 py-1 rounded-full text-xs font-semibold ${
                          mov.tipo_movimiento === 'Entrada'
                            ? 'bg-emerald-500/15 text-emerald-700 dark:text-emerald-400'
                            : mov.tipo_movimiento === 'Salida'
                              ? 'bg-destructive/15 text-destructive'
                              : mov.tipo_movimiento === 'Reserva'
                                ? 'bg-amber-500/15 text-amber-700 dark:text-amber-400'
                                : mov.tipo_movimiento === 'Liberacion'
                                  ? 'bg-primary/15 text-primary'
                                  : 'bg-muted text-muted-foreground'
                        }`}
                      >
                        {mov.tipo_movimiento}
                      </span>
                    </TableCell>
                    <TableCell className="text-right font-mono font-bold">
                      {formatearCantidadStock(mov.cantidad)}
                    </TableCell>
                    <TableCell className="text-muted-foreground text-sm">{mov.referencia}</TableCell>
                  </TableRow>
                ))}
                {movimientos.length === 0 && (
                  <TableRow>
                    <TableCell colSpan={5} className="text-center py-4 text-muted-foreground">
                      No hay movimientos registrados.
                    </TableCell>
                  </TableRow>
                )}
              </TableBody>
            </Table>
          )}
        </DialogContent>
      </Dialog>

      {/* Modal Recepciones desde facturas (Bloque G) */}
      <Dialog open={recepcionesOpen} onOpenChange={setRecepcionesOpen}>
        <DialogContent className="max-w-5xl max-h-[85vh] flex flex-col bg-card text-foreground border-border">
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2 text-foreground">
              <PackageCheck className="w-5 h-5 text-primary" />
              Recepciones de facturas en almacén
            </DialogTitle>
            <DialogDescription className="text-muted-foreground">
              Historial de facturas de proveedores recibidas en inventario. Puedes anular una recepción aplicada para revertir las existencias.
            </DialogDescription>
          </DialogHeader>

          <div className="flex flex-wrap items-center justify-between gap-2 pb-2 border-b border-border">
            <div className="flex items-center gap-1.5">
              {(['todas', 'recibida', 'anulada'] as const).map((est) => (
                <Button
                  key={est}
                  size="sm"
                  variant={filtroEstadoRec === est ? 'default' : 'outline'}
                  onClick={() => handleCambiarFiltroRecepciones(est)}
                  className="text-xs capitalize"
                >
                  {est === 'todas' ? 'Todas' : est === 'recibida' ? 'Recibidas' : 'Anuladas'}
                </Button>
              ))}
            </div>
            <Button
              size="sm"
              variant="outline"
              onClick={() => cargarRecepciones(filtroEstadoRec)}
              disabled={estadoRecepciones === 'cargando'}
              className="text-xs gap-1"
            >
              <RefreshCw className={`w-3.5 h-3.5 ${estadoRecepciones === 'cargando' ? 'animate-spin' : ''}`} />
              Actualizar
            </Button>
          </div>

          <div className="flex-1 overflow-y-auto space-y-3 py-2">
            {estadoRecepciones === 'cargando' && (
              <div className="py-10 flex items-center justify-center gap-2 text-sm text-muted-foreground">
                <Loader2 className="w-4 h-4 animate-spin" />
                Cargando recepciones...
              </div>
            )}

            {estadoRecepciones === 'error' && (
              <div className="rounded-md border border-destructive/40 bg-destructive/10 p-4 flex flex-wrap items-center justify-between gap-3">
                <div className="text-sm text-destructive">
                  <div className="font-semibold">Error al cargar recepciones</div>
                  <div className="text-xs opacity-90">{errorRecepciones}</div>
                </div>
                <Button size="sm" variant="outline" onClick={() => cargarRecepciones(filtroEstadoRec)} className="gap-1">
                  <RefreshCw className="w-3.5 h-3.5" />
                  Reintentar
                </Button>
              </div>
            )}

            {estadoRecepciones === 'ok' && recepciones.length === 0 && (
              <div className="py-10 text-center text-sm text-muted-foreground">
                No hay recepciones registradas con este filtro.
              </div>
            )}

            {estadoRecepciones === 'ok' &&
              recepciones.map((rec) => (
                <div
                  key={rec.id}
                  className={`rounded-md border p-3 space-y-2 ${
                    rec.estado === 'anulada'
                      ? 'border-border/60 bg-muted/30 opacity-80'
                      : 'border-border bg-background'
                  }`}
                >
                  <div className="flex flex-wrap items-center justify-between gap-2">
                    <div className="flex flex-wrap items-center gap-2 text-sm">
                      <span className="font-mono font-semibold text-foreground">
                        {rec.factura_folio || rec.factura_id.slice(0, 8)}
                      </span>
                      <span className="text-muted-foreground">·</span>
                      <span className="font-medium text-foreground">{rec.proveedor_nombre || 'Proveedor'}</span>
                      <span className="text-xs text-muted-foreground">
                        ({rec.created_at ? new Date(rec.created_at).toLocaleDateString('es-MX') : ''})
                      </span>
                      <span
                        className={`px-2 py-0.5 rounded text-[11px] font-medium ${
                          rec.estado === 'recibida'
                            ? 'bg-emerald-500/15 text-emerald-700 dark:text-emerald-400'
                            : 'bg-destructive/15 text-destructive'
                        }`}
                      >
                        {rec.estado === 'recibida' ? 'Recibida' : 'Anulada'}
                      </span>
                    </div>

                    {rec.estado === 'recibida' && (
                      <Button
                        size="sm"
                        variant="outline"
                        className="h-7 px-2.5 text-xs text-destructive border-destructive/40 hover:bg-destructive/10 gap-1"
                        onClick={() => {
                          setRecepcionAAnular(rec);
                          setMotivoAnulacion('');
                        }}
                      >
                        <Ban className="w-3.5 h-3.5" />
                        Anular
                      </Button>
                    )}
                  </div>

                  {rec.estado === 'anulada' && rec.motivo_anulacion && (
                    <div className="text-xs text-destructive">
                      Motivo de anulación: {rec.motivo_anulacion}
                    </div>
                  )}

                  {rec.notas && (
                    <div className="text-xs text-muted-foreground">Notas: {rec.notas}</div>
                  )}

                  <div className="rounded border border-border/60 overflow-x-auto">
                    <table className="w-full text-xs">
                      <thead className="bg-muted/40 text-muted-foreground">
                        <tr>
                          <th className="p-2 text-left">Producto</th>
                          <th className="p-2 text-right">Cantidad</th>
                          <th className="p-2 text-right">Costo unit. (MXN s/IVA)</th>
                          <th className="p-2 text-right">Importe</th>
                        </tr>
                      </thead>
                      <tbody className="divide-y divide-border/40">
                        {(rec.lineas || []).map((ln) => (
                          <tr key={ln.id}>
                            <td className="p-2 font-medium text-foreground">
                              {ln.producto_nombre || ln.producto_id}
                            </td>
                            <td className="p-2 text-right font-mono">
                              {formatearCantidadStock(ln.cantidad_recibida)}
                            </td>
                            <td className="p-2 text-right font-mono">
                              {fmtMonedaMxn(ln.costo_unitario_mxn)}
                            </td>
                            <td className="p-2 text-right font-mono">
                              {fmtMonedaMxn(ln.cantidad_recibida * ln.costo_unitario_mxn)}
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                </div>
              ))}
          </div>
        </DialogContent>
      </Dialog>

      {/* Diálogo confirmar anulación de recepción */}
      <Dialog
        open={Boolean(recepcionAAnular)}
        onOpenChange={(o) => {
          if (!o && !anulandoRec) {
            setRecepcionAAnular(null);
            setMotivoAnulacion('');
          }
        }}
      >
        <DialogContent className="bg-card text-foreground border-border">
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2 text-destructive">
              <AlertTriangle className="w-5 h-5" />
              Anular recepción de almacén
            </DialogTitle>
            <DialogDescription className="text-muted-foreground">
              Factura {recepcionAAnular?.factura_folio || ''} · {recepcionAAnular?.proveedor_nombre || ''}
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-3 py-2 text-sm">
            <div className="rounded-md border border-amber-500/40 bg-amber-500/10 p-3 text-xs text-foreground space-y-1">
              <p className="font-semibold">¿Qué ocurre al anular esta recepción?</p>
              <ul className="list-disc pl-4 space-y-0.5 text-muted-foreground">
                <li>Se restarán las cantidades recibidas del stock actual (generando movimientos de salida por anulación).</li>
                <li>Si el stock actual ya es menor a la cantidad recibida, la anulación se bloqueará para no dejar existencias negativas.</li>
                <li>Las partidas de la factura quedarán liberadas para volver a recibirlas si se corrigió un error.</li>
                <li>El último costo de compra de referencia no se revierte automáticamente.</li>
              </ul>
            </div>

            <div className="space-y-1.5">
              <Label htmlFor="motivo-anulacion-rec">Motivo de la anulación (obligatorio)</Label>
              <Input
                id="motivo-anulacion-rec"
                placeholder="Ej. Producto asignado por error, mercancía devuelta..."
                value={motivoAnulacion}
                onChange={(e) => setMotivoAnulacion(e.target.value)}
                disabled={anulandoRec}
              />
            </div>
          </div>

          <DialogFooter>
            <Button
              variant="outline"
              onClick={() => {
                setRecepcionAAnular(null);
                setMotivoAnulacion('');
              }}
              disabled={anulandoRec}
            >
              Cancelar
            </Button>
            <Button
              variant="destructive"
              onClick={handleConfirmarAnularRecepcion}
              disabled={anulandoRec || !motivoAnulacion.trim()}
            >
              {anulandoRec ? (
                <>
                  <Loader2 className="w-4 h-4 mr-1.5 animate-spin" />
                  Anulando...
                </>
              ) : (
                'Confirmar anulación'
              )}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
