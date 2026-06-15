import { useState } from 'react';
import { Button } from '../ui/button';
import { Input } from '../ui/input';
import { Card, CardContent, CardHeader, CardTitle, CardDescription, CardFooter } from '../ui/card';
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '../ui/dialog';
import { AlertDialog, AlertDialogAction, AlertDialogCancel, AlertDialogContent, AlertDialogDescription, AlertDialogFooter, AlertDialogHeader, AlertDialogTitle } from '../ui/alert-dialog';
import { Badge } from '../ui/badge';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '../ui/tabs';
import { Label } from '../ui/label';
import { Plus, Search, Edit, Trash2, Users, Building, Mail, Phone, FolderPlus, Tag } from 'lucide-react';
import { Cliente, CategoriaCliente } from '../../types';
import { ClienteModal } from './ClienteModal';

interface ClientesListProps {
  clientes: Cliente[];
  categorias?: CategoriaCliente[];
  loading: boolean;
  onCrearCliente: (cliente: Omit<Cliente, 'id'>) => void;
  onActualizarCliente: (id: string, cliente: Partial<Cliente>) => void;
  onEliminarCliente: (id: string) => void;
  onCrearCategoria?: (categoria: Omit<CategoriaCliente, 'id' | 'organizacion_id'>) => Promise<any>;
  onActualizarCategoria?: (id: string, categoria: Partial<CategoriaCliente>) => Promise<any>;
  onEliminarCategoria?: (id: string) => Promise<any>;
}

export function ClientesList({
  clientes,
  categorias = [],
  loading,
  onCrearCliente,
  onActualizarCliente,
  onEliminarCliente,
  onCrearCategoria
}: ClientesListProps) {
  const [busqueda, setBusqueda] = useState('');
  const [categoriaActiva, setCategoriaActiva] = useState('todas');
  
  const [modalOpen, setModalOpen] = useState(false);
  const [modalCatOpen, setModalCatOpen] = useState(false);
  
  const [clienteEditando, setClienteEditando] = useState<Cliente | null>(null);
  const [clienteAEliminar, setClienteAEliminar] = useState<string | null>(null);
  
  const [catFormData, setCatFormData] = useState({ nombre: '', color: '#10b981' });

  const clientesFiltrados = clientes.filter(cliente => {
    if (!cliente) return false;
    const busquedaLower = busqueda.toLowerCase();
    const matchBusqueda = (cliente.nombre_razon_social || '').toLowerCase().includes(busquedaLower) ||
                          (cliente.correo || '').toLowerCase().includes(busquedaLower) ||
                          (cliente.telefono || '').includes(busqueda);
    const matchCat = categoriaActiva === 'todas' || cliente.categoria_id === categoriaActiva;
    return matchBusqueda && matchCat;
  });

  const handleSubmitCategoria = async () => {
    if (!catFormData.nombre.trim()) return;
    if (onCrearCategoria) {
      await onCrearCategoria(catFormData);
      setModalCatOpen(false);
      setCatFormData({ nombre: '', color: '#10b981' });
    }
  };

  const manejarGuardarCliente = (clienteData: Omit<Cliente, 'id'>) => {
    if (clienteEditando) {
      onActualizarCliente(clienteEditando.id, clienteData);
    } else {
      onCrearCliente(clienteData);
    }
    setModalOpen(false);
    setClienteEditando(null);
  };

  const abrirModalEdicion = (cliente: Cliente) => {
    setClienteEditando(cliente);
    setModalOpen(true);
  };

  const abrirModalCreacion = () => {
    setClienteEditando(null);
    setModalOpen(true);
  };

  if (loading) {
    return (
      <div className="grid gap-6 grid-cols-1 sm:grid-cols-2 md:grid-cols-3 xl:grid-cols-4 animate-pulse">
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
          <h1 className="text-3xl font-bold font-sans">Directorio de Clientes</h1>
          <p className="text-muted-foreground mt-1">Gestión de contactos y prospectos</p>
        </div>
        <div className="flex gap-2">
          <Button variant="outline" onClick={() => setModalCatOpen(true)} className="border-white/10 hover:bg-white/5">
            <FolderPlus className="mr-2 h-4 w-4" /> Categoría
          </Button>
          <Button onClick={abrirModalCreacion} className="bg-primary text-primary-foreground hover:bg-primary/90">
            <Plus className="mr-2 h-4 w-4" /> Nuevo Cliente
          </Button>
        </div>
      </div>

      <div className="flex flex-col sm:flex-row gap-4 justify-between items-center bg-white/[0.02] p-4 rounded-lg border border-white/[0.06]">
        <div className="relative w-full sm:w-96">
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-muted-foreground h-4 w-4" />
          <Input 
            placeholder="Buscar clientes por nombre, correo o teléfono..." 
            value={busqueda}
            onChange={(e) => setBusqueda(e.target.value)}
            className="pl-10 bg-transparent border-white/10"
          />
        </div>
        
        <Tabs value={categoriaActiva} onValueChange={setCategoriaActiva} className="w-full sm:w-auto overflow-x-auto">
          <TabsList className="bg-transparent border border-white/10">
            <TabsTrigger value="todas">Todos</TabsTrigger>
            {categorias.map(cat => (
              <TabsTrigger key={cat.id} value={cat.id}>
                <div className="w-2 h-2 rounded-full mr-2" style={{ backgroundColor: cat.color || '#fff' }} />
                {cat.nombre}
              </TabsTrigger>
            ))}
          </TabsList>
        </Tabs>
      </div>

      {clientesFiltrados.length === 0 ? (
        <div className="text-center py-20 bg-white/[0.02] rounded-xl border border-white/[0.06]">
          <Users className="mx-auto h-12 w-12 text-muted-foreground mb-4" />
          <h3 className="text-lg font-medium text-white mb-2">No se encontraron clientes</h3>
          <p className="text-muted-foreground">Prueba con otra búsqueda o añade un cliente nuevo.</p>
        </div>
      ) : (
        <div className="grid gap-6 grid-cols-1 sm:grid-cols-2 md:grid-cols-3 xl:grid-cols-4">
          {clientesFiltrados.map(cliente => {
            const cat = categorias.find(c => c.id === cliente.categoria_id);
            return (
              <Card key={cliente.id} className="bg-white/[0.02] border-white/[0.06] hover:bg-white/[0.04] transition-all flex flex-col group overflow-hidden">
                <div className="h-2 w-full" style={{ backgroundColor: cat?.color || 'rgba(255,255,255,0.1)' }}></div>
                <CardHeader className="pb-2">
                  <div className="flex justify-between items-start">
                    <div className="flex flex-col gap-1">
                      {cliente.origen_lead && (
                        <span className="text-[10px] text-muted-foreground uppercase tracking-wider">{cliente.origen_lead}</span>
                      )}
                      <Badge variant="outline" className="w-fit bg-black/40 backdrop-blur-md">
                        <Building className="w-3 h-3 mr-1" />
                        {cliente.giro_empresa || 'Empresa / Particular'}
                      </Badge>
                    </div>
                    <div className="opacity-0 group-hover:opacity-100 transition-opacity flex gap-1">
                      <Button variant="ghost" size="icon" className="h-8 w-8 hover:text-accent-blue" onClick={() => abrirModalEdicion(cliente)}><Edit className="h-4 w-4" /></Button>
                      <Button variant="ghost" size="icon" className="h-8 w-8 hover:text-accent-red" onClick={() => setClienteAEliminar(cliente.id)}><Trash2 className="h-4 w-4" /></Button>
                    </div>
                  </div>
                  <CardTitle className="text-lg text-white mt-2 line-clamp-1">{cliente.nombre_razon_social}</CardTitle>
                  <CardDescription className="line-clamp-1 text-xs">
                    {cliente.nombre_contacto || 'Sin contacto principal'}
                  </CardDescription>
                </CardHeader>
                <CardContent className="flex-1 space-y-3">
                  {cliente.correo && (
                    <div className="flex items-center text-sm text-white/70">
                      <Mail className="w-4 h-4 mr-2 text-muted-foreground" />
                      <span className="truncate">{cliente.correo}</span>
                    </div>
                  )}
                  {cliente.telefono && (
                    <div className="flex items-center text-sm text-white/70">
                      <Phone className="w-4 h-4 mr-2 text-muted-foreground" />
                      <span>{cliente.telefono}</span>
                    </div>
                  )}
                </CardContent>
                <CardFooter className="bg-black/20 py-3 border-t border-white/[0.06] flex justify-between">
                  <span className="text-xs text-white/50 flex items-center">
                    <Tag className="w-3 h-3 mr-1" />
                    {cat?.nombre || 'Sin categoría'}
                  </span>
                  <span className="text-[10px] text-muted-foreground">{cliente.tipo_pago_preferido}</span>
                </CardFooter>
              </Card>
            );
          })}
        </div>
      )}

      {/* Modal Categoría */}
      <Dialog open={modalCatOpen} onOpenChange={setModalCatOpen}>
        <DialogContent className="sm:max-w-[400px]">
          <DialogHeader><DialogTitle>Nueva Categoría de Cliente</DialogTitle></DialogHeader>
          <div className="grid gap-4 py-4">
            <div className="space-y-2">
              <Label>Nombre de la Categoría</Label>
              <Input value={catFormData.nombre} onChange={e => setCatFormData({...catFormData, nombre: e.target.value})} placeholder="Ej. VIP, Mayorista, Minorista" />
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

      <ClienteModal 
        open={modalOpen}
        onOpenChange={setModalOpen}
        cliente={clienteEditando || undefined} 
        categorias={categorias}
        onGuardar={manejarGuardarCliente} 
      />

      <AlertDialog open={!!clienteAEliminar} onOpenChange={(o) => !o && setClienteAEliminar(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>¿Eliminar cliente?</AlertDialogTitle>
            <AlertDialogDescription>Esta acción no se puede deshacer.</AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancelar</AlertDialogCancel>
            <AlertDialogAction onClick={() => { if (clienteAEliminar) { onEliminarCliente(clienteAEliminar); setClienteAEliminar(null); } }}>
              Sí, eliminar
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  );
}
