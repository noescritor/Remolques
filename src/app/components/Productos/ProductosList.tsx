import { useState } from 'react';
import { Button } from '../ui/button';
import { Input } from '../ui/input';
import { Label } from '../ui/label';
import { Card, CardContent, CardHeader, CardTitle, CardDescription, CardFooter } from '../ui/card';
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle, DialogFooter } from '../ui/dialog';
import { AlertDialog, AlertDialogAction, AlertDialogCancel, AlertDialogContent, AlertDialogDescription, AlertDialogFooter, AlertDialogHeader, AlertDialogTitle } from '../ui/alert-dialog';
import { Badge } from '../ui/badge';
import { Plus, Search, Edit, Trash2, Package, Calculator, FolderPlus, Tag } from 'lucide-react';
import { Producto, ProductoTipo, ServicioModo, PeriodoCobro, CategoriaProducto } from '../../types';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../ui/select';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '../ui/tabs';
import { Switch } from '../ui/switch';
import { formatearMoneda } from '../../utils/calculations';

interface ProductosListProps {
  productos: Producto[];
  categorias?: CategoriaProducto[];
  loading: boolean;
  onCrearProducto: (producto: Omit<Producto, 'id'>) => void;
  onActualizarProducto: (id: string, producto: Partial<Producto>) => void;
  onEliminarProducto: (id: string) => void;
  onCrearCategoria?: (categoria: Omit<CategoriaProducto, 'id' | 'organizacion_id'>) => Promise<any>;
  onActualizarCategoria?: (id: string, categoria: Partial<CategoriaProducto>) => Promise<any>;
  onEliminarCategoria?: (id: string) => Promise<any>;
}

export function ProductosList({
  productos,
  categorias = [],
  loading,
  onCrearProducto,
  onActualizarProducto,
  onEliminarProducto,
  onCrearCategoria,
  onActualizarCategoria,
  onEliminarCategoria
}: ProductosListProps) {
  const [busqueda, setBusqueda] = useState('');
  const [categoriaActiva, setCategoriaActiva] = useState('todas');
  
  // Modals
  const [modalOpen, setModalOpen] = useState(false);
  const [modalCatOpen, setModalCatOpen] = useState(false);
  const [productoEditando, setProductoEditando] = useState<Producto | null>(null);
  const [productoAEliminar, setProductoAEliminar] = useState<string | null>(null);
  const [mostrarCalculadora, setMostrarCalculadora] = useState(false);
  
  // Form Producto
  const [formData, setFormData] = useState({
    tipo: 'bien' as ProductoTipo,
    nombre: '',
    descripcion: '',
    unidad: 'pz',
    precio_unitario: 0,
    costo: 0,
    tasa_iva: 0.16,
    categoria_id: 'ninguna',
    servicio: {
      modo: 'unico' as ServicioModo,
      setup_precio: 0, setup_costo: 0, recur_precio: 0, recur_costo: 0,
      periodo: 'mensual' as PeriodoCobro, min_meses: 1, por_asiento: false,
      asientos_incluidos: 1, precio_por_asiento: 0
    }
  });
  const [errores, setErrores] = useState<string[]>([]);

  // Form Categoria
  const [catFormData, setCatFormData] = useState({ nombre: '', color: '#3b82f6' });

  // Filter products
  const productosFiltrados = productos.filter(producto => {
    if (!producto) return false;
    const matchBusqueda = (producto.nombre || '').toLowerCase().includes(busqueda.toLowerCase());
    const matchCat = categoriaActiva === 'todas' || producto.categoria_id === categoriaActiva;
    return matchBusqueda && matchCat;
  });

  const handleSubmitCategoria = async () => {
    if (!catFormData.nombre.trim()) return;
    if (onCrearCategoria) {
      await onCrearCategoria(catFormData);
      setModalCatOpen(false);
      setCatFormData({ nombre: '', color: '#3b82f6' });
    }
  };

  const handleEditar = (producto: Producto) => {
    setProductoEditando(producto);
    setFormData({
      tipo: producto.tipo || 'bien',
      nombre: producto.nombre || '',
      descripcion: producto.descripcion || '',
      unidad: producto.unidad || 'pz',
      precio_unitario: producto.precio_unitario || 0,
      costo: producto.costo || 0,
      tasa_iva: producto.tasa_iva || 0.16,
      categoria_id: producto.categoria_id || 'ninguna',
      servicio: producto.servicio || {
        modo: 'unico', setup_precio: 0, setup_costo: 0, recur_precio: 0, recur_costo: 0,
        periodo: 'mensual', min_meses: 1, por_asiento: false, asientos_incluidos: 1, precio_por_asiento: 0
      }
    });
    setModalOpen(true);
  };

  const handleGuardar = () => {
    if (!formData.nombre.trim()) {
      setErrores(['El nombre es requerido']);
      return;
    }
    
    const productPayload: any = {
      tipo: formData.tipo,
      nombre: formData.nombre,
      descripcion: formData.descripcion,
      unidad: formData.unidad,
      precio_unitario: formData.precio_unitario,
      costo: formData.costo,
      tasa_iva: formData.tasa_iva,
      categoria_id: formData.categoria_id === 'ninguna' ? null : formData.categoria_id,
    };

    if (formData.tipo === 'servicio') {
      productPayload.servicio = formData.servicio;
    }

    if (productoEditando) {
      onActualizarProducto(productoEditando.id, productPayload);
    } else {
      onCrearProducto(productPayload);
    }
    setModalOpen(false);
  };

  if (loading) {
    return (
      <div className="grid gap-6 grid-cols-2 md:grid-cols-3 lg:grid-cols-4 animate-pulse">
        {[...Array(8)].map((_, i) => (
          <div key={i} className="h-48 bg-muted rounded-xl"></div>
        ))}
      </div>
    );
  }

  return (
    <div className="space-y-6 text-foreground bg-background min-h-screen pb-20">
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-3xl font-bold font-sans">Productos y Servicios</h1>
          <p className="text-muted-foreground mt-1">Catálogo y listas de precios</p>
        </div>
        <div className="flex gap-2">
          <Button variant="outline" onClick={() => setModalCatOpen(true)} className="border-white/10 hover:bg-white/5">
            <FolderPlus className="mr-2 h-4 w-4" /> Categoría
          </Button>
          <Button onClick={() => { setProductoEditando(null); setModalOpen(true); }} className="bg-primary text-primary-foreground hover:bg-primary/90">
            <Plus className="mr-2 h-4 w-4" /> Nuevo Producto
          </Button>
        </div>
      </div>

      <div className="flex flex-col sm:flex-row gap-4 justify-between items-center bg-white/[0.02] p-4 rounded-lg border border-white/[0.06]">
        <div className="relative w-full sm:w-96">
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-muted-foreground h-4 w-4" />
          <Input 
            placeholder="Buscar por nombre..." 
            value={busqueda}
            onChange={(e) => setBusqueda(e.target.value)}
            className="pl-10 bg-transparent border-white/10"
          />
        </div>
        
        <Tabs value={categoriaActiva} onValueChange={setCategoriaActiva} className="w-full sm:w-auto overflow-x-auto">
          <TabsList className="bg-transparent border border-white/10">
            <TabsTrigger value="todas">Todas</TabsTrigger>
            {categorias.map(cat => (
              <TabsTrigger key={cat.id} value={cat.id}>
                <div className="w-2 h-2 rounded-full mr-2" style={{ backgroundColor: cat.color || '#fff' }} />
                {cat.nombre}
              </TabsTrigger>
            ))}
          </TabsList>
        </Tabs>
      </div>

      {productosFiltrados.length === 0 ? (
        <div className="text-center py-20 bg-white/[0.02] rounded-xl border border-white/[0.06]">
          <Package className="mx-auto h-12 w-12 text-muted-foreground mb-4" />
          <h3 className="text-lg font-medium text-white mb-2">No se encontraron productos</h3>
          <p className="text-muted-foreground">Prueba con otra búsqueda o añade un producto nuevo.</p>
        </div>
      ) : (
        <div className="grid gap-6 grid-cols-1 sm:grid-cols-2 md:grid-cols-3 xl:grid-cols-4">
          {productosFiltrados.map(producto => {
            const cat = categorias.find(c => c.id === producto.categoria_id);
            return (
              <Card key={producto.id} className="bg-white/[0.02] border-white/[0.06] hover:bg-white/[0.04] transition-all flex flex-col group overflow-hidden">
                <div className="h-2 w-full" style={{ backgroundColor: cat?.color || 'rgba(255,255,255,0.1)' }}></div>
                <CardHeader className="pb-2">
                  <div className="flex justify-between items-start">
                    <Badge variant="outline" className="mb-2 bg-black/40 backdrop-blur-md">
                      {producto.tipo === 'bien' ? 'Producto' : 'Servicio'}
                    </Badge>
                    <div className="opacity-0 group-hover:opacity-100 transition-opacity flex gap-1">
                      <Button variant="ghost" size="icon" className="h-8 w-8 hover:text-accent-blue" onClick={() => handleEditar(producto)}><Edit className="h-4 w-4" /></Button>
                      <Button variant="ghost" size="icon" className="h-8 w-8 hover:text-accent-red" onClick={() => setProductoAEliminar(producto.id)}><Trash2 className="h-4 w-4" /></Button>
                    </div>
                  </div>
                  <CardTitle className="text-lg text-white line-clamp-1">{producto.nombre}</CardTitle>
                  <CardDescription className="line-clamp-2 text-xs min-h-[32px]">{producto.descripcion || 'Sin descripción'}</CardDescription>
                </CardHeader>
                <CardContent className="flex-1">
                  <div className="mt-4 flex items-end justify-between">
                    <div>
                      <p className="text-[10px] text-muted-foreground uppercase tracking-widest font-mono mb-1">Precio Unit.</p>
                      <p className="text-xl font-bold font-mono text-accent-green">{formatearMoneda(producto.precio_unitario || 0)}</p>
                    </div>
                    {producto.costo ? (
                      <div className="text-right">
                        <p className="text-[10px] text-muted-foreground uppercase tracking-widest font-mono mb-1">Costo</p>
                        <p className="text-sm font-mono text-white/70">{formatearMoneda(producto.costo)}</p>
                      </div>
                    ) : null}
                  </div>
                </CardContent>
                <CardFooter className="bg-black/20 py-3 border-t border-white/[0.06] flex justify-between">
                  <span className="text-xs text-white/50 flex items-center">
                    <Tag className="w-3 h-3 mr-1" />
                    {cat?.nombre || 'Sin categoría'}
                  </span>
                  <span className="text-xs text-white/50">{producto.unidad}</span>
                </CardFooter>
              </Card>
            );
          })}
        </div>
      )}

      {/* Modal Producto */}
      <Dialog open={modalOpen} onOpenChange={setModalOpen}>
        <DialogContent className="sm:max-w-[600px] max-h-[90vh] overflow-y-auto bg-background border-border">
          <DialogHeader>
            <DialogTitle>{productoEditando ? 'Editar Producto' : 'Nuevo Producto'}</DialogTitle>
          </DialogHeader>
          <div className="grid gap-4 py-4">
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>Tipo</Label>
                <Select value={formData.tipo} onValueChange={(v: ProductoTipo) => setFormData({...formData, tipo: v})}>
                  <SelectTrigger><SelectValue /></SelectTrigger>
                  <SelectContent>
                    <SelectItem value="bien">Bien Físico</SelectItem>
                    <SelectItem value="servicio">Servicio</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-2">
                <Label>Categoría</Label>
                <Select value={formData.categoria_id} onValueChange={(v) => setFormData({...formData, categoria_id: v})}>
                  <SelectTrigger><SelectValue /></SelectTrigger>
                  <SelectContent>
                    <SelectItem value="ninguna">Sin categoría</SelectItem>
                    {categorias.map(c => <SelectItem key={c.id} value={c.id}>{c.nombre}</SelectItem>)}
                  </SelectContent>
                </Select>
              </div>
            </div>
            <div className="space-y-2">
              <Label>Nombre</Label>
              <Input value={formData.nombre} onChange={e => setFormData({...formData, nombre: e.target.value})} />
            </div>
            <div className="space-y-2">
              <Label>Descripción</Label>
              <Input value={formData.descripcion} onChange={e => setFormData({...formData, descripcion: e.target.value})} />
            </div>
            <div className="grid grid-cols-3 gap-4">
              <div className="space-y-2">
                <Label>Unidad</Label>
                <Input value={formData.unidad} onChange={e => setFormData({...formData, unidad: e.target.value})} placeholder="pz, m2, hrs..." />
              </div>
              <div className="space-y-2">
                <Label>Precio Unitario</Label>
                <Input type="number" value={formData.precio_unitario || ''} onChange={e => setFormData({...formData, precio_unitario: Number(e.target.value)})} />
              </div>
              <div className="space-y-2">
                <Label>Costo (opcional)</Label>
                <Input type="number" value={formData.costo || ''} onChange={e => setFormData({...formData, costo: Number(e.target.value)})} />
              </div>
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setModalOpen(false)}>Cancelar</Button>
            <Button onClick={handleGuardar}>Guardar</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Modal Categoría */}
      <Dialog open={modalCatOpen} onOpenChange={setModalCatOpen}>
        <DialogContent className="sm:max-w-[400px]">
          <DialogHeader><DialogTitle>Nueva Categoría</DialogTitle></DialogHeader>
          <div className="grid gap-4 py-4">
            <div className="space-y-2">
              <Label>Nombre</Label>
              <Input value={catFormData.nombre} onChange={e => setCatFormData({...catFormData, nombre: e.target.value})} />
            </div>
            <div className="space-y-2">
              <Label>Color Identificador</Label>
              <div className="flex gap-2">
                <Input type="color" className="w-16 h-10 p-1" value={catFormData.color} onChange={e => setCatFormData({...catFormData, color: e.target.value})} />
                <Input type="text" className="flex-1" value={catFormData.color} onChange={e => setCatFormData({...catFormData, color: e.target.value})} />
              </div>
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setModalCatOpen(false)}>Cancelar</Button>
            <Button onClick={handleSubmitCategoria}>Guardar</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Modal Confirmar Eliminar */}
      <AlertDialog open={!!productoAEliminar} onOpenChange={(o) => !o && setProductoAEliminar(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>¿Eliminar producto?</AlertDialogTitle>
            <AlertDialogDescription>Esta acción no se puede deshacer.</AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancelar</AlertDialogCancel>
            <AlertDialogAction onClick={() => { if (productoAEliminar) { onEliminarProducto(productoAEliminar); setProductoAEliminar(null); } }}>
              Sí, eliminar
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  );
}
