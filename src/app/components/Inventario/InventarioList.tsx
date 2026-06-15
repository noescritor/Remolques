import { useState, useEffect } from 'react';
import { Button } from '../ui/button';
import { Input } from '../ui/input';
import { Label } from '../ui/label';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '../ui/table';
import { Card, CardContent, CardHeader, CardTitle } from '../ui/card';
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle, DialogFooter } from '../ui/dialog';
import { Skeleton } from '../ui/skeleton';
import { Alert, AlertDescription } from '../ui/alert';
import { Search, Plus, AlertTriangle, CheckCircle, PackageMinus, PackagePlus, History } from 'lucide-react';
import { Producto, MovimientoInventario } from '../../types';
import { toast } from 'sonner';

interface InventarioListProps {
  productos: Producto[];
  loading: boolean;
  obtenerMovimientosInventario: () => Promise<MovimientoInventario[]>;
  registrarMovimientoInventario: (movimiento: Partial<MovimientoInventario>) => Promise<any>;
}

export function InventarioList({
  productos,
  loading,
  obtenerMovimientosInventario,
  registrarMovimientoInventario
}: InventarioListProps) {
  const [busqueda, setBusqueda] = useState('');
  const [modalOpen, setModalOpen] = useState(false);
  const [historialOpen, setHistorialOpen] = useState(false);
  const [movimientos, setMovimientos] = useState<MovimientoInventario[]>([]);
  const [loadingHistorial, setLoadingHistorial] = useState(false);
  
  const [productoSeleccionado, setProductoSeleccionado] = useState<string>('');
  const [formData, setFormData] = useState({
    tipo_movimiento: 'Entrada' as 'Entrada' | 'Salida' | 'Ajuste',
    cantidad: 1,
    referencia: ''
  });

  // Filtramos solo los bienes (los servicios no tienen inventario)
  const bienes = productos.filter(p => p.tipo === 'bien');
  const productosFiltrados = bienes.filter(p => 
    p.nombre.toLowerCase().includes(busqueda.toLowerCase()) ||
    (p.descripcion && p.descripcion.toLowerCase().includes(busqueda.toLowerCase()))
  );

  const cargarHistorial = async () => {
    setLoadingHistorial(true);
    try {
      const data = await obtenerMovimientosInventario();
      setMovimientos(data);
    } catch (error) {
      toast.error("Error al cargar historial de inventario");
    } finally {
      setLoadingHistorial(false);
    }
  };

  const handleOpenHistorial = () => {
    setHistorialOpen(true);
    cargarHistorial();
  };

  const handleGuardarAjuste = async () => {
    if (!productoSeleccionado) {
      toast.error("Selecciona un producto");
      return;
    }
    if (formData.cantidad <= 0) {
      toast.error("La cantidad debe ser mayor a 0");
      return;
    }

    try {
      await registrarMovimientoInventario({
        producto_id: productoSeleccionado,
        tipo_movimiento: formData.tipo_movimiento,
        cantidad: formData.cantidad,
        referencia: formData.referencia || 'Ajuste manual'
      });
      toast.success("Movimiento registrado con éxito");
      setModalOpen(false);
      setFormData({ tipo_movimiento: 'Entrada', cantidad: 1, referencia: '' });
      setProductoSeleccionado('');
    } catch (error: any) {
      console.error("Error al registrar movimiento:", error);
      const msg = error?.message || JSON.stringify(error) || "Error desconocido";
      toast.error(`Error al registrar movimiento: ${msg}`);
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h2 className="text-2xl font-bold tracking-tight">Inventario</h2>
          <p className="text-gray-500">Gestión de existencias y almacén</p>
        </div>
        <div className="flex gap-2">
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
              <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-gray-500" />
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
            <div className="rounded-md border">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Producto</TableHead>
                    <TableHead className="text-right">Stock Actual</TableHead>
                    <TableHead className="text-right">Stock Reservado</TableHead>
                    <TableHead className="text-right">Stock Disponible</TableHead>
                    <TableHead>Estado</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {productosFiltrados.length === 0 ? (
                    <TableRow>
                      <TableCell colSpan={5} className="text-center py-8 text-gray-500">
                        No se encontraron bienes en el inventario.
                      </TableCell>
                    </TableRow>
                  ) : (
                    productosFiltrados.map((producto) => {
                      const actual = producto.stock_actual || 0;
                      const reservado = producto.stock_reservado || 0;
                      const min = producto.stock_minimo || 0;
                      const disponible = actual - reservado;
                      
                      let estado = <span className="flex items-center text-green-600"><CheckCircle className="w-4 h-4 mr-1"/> Normal</span>;
                      if (disponible <= 0) {
                        estado = <span className="flex items-center text-red-600"><PackageMinus className="w-4 h-4 mr-1"/> Agotado</span>;
                      } else if (disponible <= min) {
                        estado = <span className="flex items-center text-amber-600"><AlertTriangle className="w-4 h-4 mr-1"/> Bajo Stock</span>;
                      }

                      return (
                        <TableRow key={producto.id}>
                          <TableCell className="font-medium">{producto.nombre}</TableCell>
                          <TableCell className="text-right">{actual}</TableCell>
                          <TableCell className="text-right text-orange-600">{reservado}</TableCell>
                          <TableCell className="text-right font-bold">{disponible}</TableCell>
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
                {bienes.map(p => (
                  <option key={p.id} value={p.id}>{p.nombre} (Stock: {p.stock_actual || 0})</option>
                ))}
              </select>
            </div>
            
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>Tipo de Movimiento</Label>
                <select 
                  className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background"
                  value={formData.tipo_movimiento}
                  onChange={(e) => setFormData({...formData, tipo_movimiento: e.target.value as any})}
                >
                  <option value="Entrada">Entrada (+)</option>
                  <option value="Salida">Salida (-)</option>
                  <option value="Ajuste">Ajuste / Mermas</option>
                </select>
              </div>
              <div className="space-y-2">
                <Label>Cantidad</Label>
                <Input 
                  type="number" 
                  min="1" 
                  value={formData.cantidad} 
                  onChange={(e) => setFormData({...formData, cantidad: parseInt(e.target.value) || 0})}
                />
              </div>
            </div>

            <div className="space-y-2">
              <Label>Referencia / Motivo</Label>
              <Input 
                placeholder="Ej. Compra de inventario, merma, etc." 
                value={formData.referencia}
                onChange={(e) => setFormData({...formData, referencia: e.target.value})}
              />
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setModalOpen(false)}>Cancelar</Button>
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
            <div className="py-8 text-center text-gray-500">Cargando historial...</div>
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
                {movimientos.map(mov => (
                  <TableRow key={mov.id}>
                    <TableCell>{new Date(mov.created_at).toLocaleString()}</TableCell>
                    <TableCell className="font-medium">{mov.producto?.nombre || 'Desconocido'}</TableCell>
                    <TableCell>
                      <span className={`px-2 py-1 rounded-full text-xs font-semibold ${
                        mov.tipo_movimiento === 'Entrada' ? 'bg-green-100 text-green-800' :
                        mov.tipo_movimiento === 'Salida' ? 'bg-red-100 text-red-800' :
                        mov.tipo_movimiento === 'Reserva' ? 'bg-orange-100 text-orange-800' :
                        mov.tipo_movimiento === 'Liberacion' ? 'bg-blue-100 text-blue-800' :
                        'bg-gray-100 text-gray-800'
                      }`}>
                        {mov.tipo_movimiento}
                      </span>
                    </TableCell>
                    <TableCell className="text-right font-bold">{mov.cantidad}</TableCell>
                    <TableCell className="text-gray-500 text-sm">{mov.referencia}</TableCell>
                  </TableRow>
                ))}
                {movimientos.length === 0 && (
                  <TableRow>
                    <TableCell colSpan={5} className="text-center py-4">No hay movimientos registrados.</TableCell>
                  </TableRow>
                )}
              </TableBody>
            </Table>
          )}
        </DialogContent>
      </Dialog>
    </div>
  );
}
