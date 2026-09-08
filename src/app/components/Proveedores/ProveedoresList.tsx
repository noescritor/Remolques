import { useState } from 'react';
import { Button } from '../ui/button';
import { Input } from '../ui/input';
import { Label } from '../ui/label';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from '../ui/dialog';
import { AlertDialog, AlertDialogAction, AlertDialogCancel, AlertDialogContent, AlertDialogDescription, AlertDialogFooter, AlertDialogHeader, AlertDialogTitle } from '../ui/alert-dialog';
import { Plus, Edit, Trash2, Building2 } from 'lucide-react';
import { Proveedor, Producto } from '../../types';

interface ProveedoresListProps {
  proveedores: Proveedor[];
  productos: Producto[]; // Para buscar los nombres de los materiales
  loading: boolean;
  onCrearProveedor: (proveedor: Omit<Proveedor, 'id' | 'organizacion_id'>) => void;
  onActualizarProveedor: (id: string, proveedor: Partial<Proveedor>) => void;
  onEliminarProveedor: (id: string) => void;
}

export function ProveedoresList({
  proveedores,
  productos,
  loading,
  onCrearProveedor,
  onActualizarProveedor,
  onEliminarProveedor
}: ProveedoresListProps) {
  const [modalOpen, setModalOpen] = useState(false);
  const [proveedorEditando, setProveedorEditando] = useState<Proveedor | null>(null);
  const [proveedorAEliminar, setProveedorAEliminar] = useState<string | null>(null);

  const [formData, setFormData] = useState({
    nombre: '',
    contacto: '',
    telefono: '',
    tiempo_entrega_dias: 0,
    condiciones_pago: '',
  });

  const materialesLookup = productos.reduce((acc, p) => {
    acc[p.id] = p.nombre;
    return acc;
  }, {} as Record<string, string>);

  const handleEditar = (proveedor: Proveedor) => {
    setProveedorEditando(proveedor);
    setFormData({
      nombre: proveedor.nombre || '',
      contacto: proveedor.contacto || '',
      telefono: proveedor.telefono || '',
      tiempo_entrega_dias: proveedor.tiempo_entrega_dias || 0,
      condiciones_pago: proveedor.condiciones_pago || '',
    });
    setModalOpen(true);
  };

  const handleGuardar = () => {
    if (!formData.nombre.trim()) return;

    if (proveedorEditando) {
      onActualizarProveedor(proveedorEditando.id, formData);
    } else {
      onCrearProveedor(formData);
    }
    setModalOpen(false);
  };

  if (loading) {
    return <div className="animate-pulse h-64 bg-white/[0.02] rounded-xl"></div>;
  }

  return (
    <div className="space-y-6 text-foreground bg-background min-h-screen pb-20">
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-3xl font-bold font-sans">Proveedores</h1>
          <p className="text-muted-foreground mt-1">A quién le compramos cada material y en cuánto tiempo entrega.</p>
        </div>
        <Button onClick={() => { setProveedorEditando(null); setFormData({ nombre: '', contacto: '', telefono: '', tiempo_entrega_dias: 0, condiciones_pago: '' }); setModalOpen(true); }} className="bg-primary text-primary-foreground hover:bg-primary/90">
          <Plus className="mr-2 h-4 w-4" /> Nuevo Proveedor
        </Button>
      </div>

      {proveedores.length === 0 ? (
        <div className="text-center py-20 bg-white/[0.02] rounded-xl border border-white/[0.06]">
          <Building2 className="mx-auto h-12 w-12 text-muted-foreground mb-4" />
          <h3 className="text-lg font-medium text-white mb-2">No hay proveedores</h3>
          <p className="text-muted-foreground">Añade tu primer proveedor para comenzar.</p>
        </div>
      ) : (
        <div className="rounded-xl border border-white/[0.06] bg-white/[0.02] overflow-hidden">
          {proveedores.map((p, i) => (
            <div key={p.id} className="p-4 flex flex-col group relative" style={{ borderTop: i ? '1px solid rgba(255,255,255,0.06)' : 'none' }}>
              <div className="flex items-center justify-between mb-1">
                <span className="text-sm font-medium text-white">{p.nombre}</span>
                <div className="flex items-center gap-4">
                  <span className="text-xs font-mono text-muted-foreground">
                    entrega en {p.tiempo_entrega_dias} días · {p.condiciones_pago}
                  </span>
                  <div className="opacity-0 group-hover:opacity-100 transition-opacity flex gap-1">
                    <Button variant="ghost" size="icon" className="h-6 w-6 hover:text-accent-blue" onClick={() => handleEditar(p)}><Edit className="h-3 w-3" /></Button>
                    <Button variant="ghost" size="icon" className="h-6 w-6 hover:text-accent-red" onClick={() => setProveedorAEliminar(p.id)}><Trash2 className="h-3 w-3" /></Button>
                  </div>
                </div>
              </div>
              <div className="text-xs text-muted-foreground">{p.contacto} · {p.telefono}</div>
              <div className="text-xs mt-1 text-muted-foreground">
                Surte: {p.materiales?.map((m) => materialesLookup[m.material_id] || 'Material desconocido').join(', ') || 'Ninguno asignado'}
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Modal Proveedor */}
      <Dialog open={modalOpen} onOpenChange={setModalOpen}>
        <DialogContent className="sm:max-w-[400px] bg-background border-border">
          <DialogHeader>
            <DialogTitle>{proveedorEditando ? 'Editar Proveedor' : 'Nuevo Proveedor'}</DialogTitle>
          </DialogHeader>
          <div className="grid gap-4 py-4">
            <div className="space-y-2">
              <Label>Nombre</Label>
              <Input value={formData.nombre} onChange={e => setFormData({...formData, nombre: e.target.value})} />
            </div>
            <div className="space-y-2">
              <Label>Contacto</Label>
              <Input value={formData.contacto} onChange={e => setFormData({...formData, contacto: e.target.value})} />
            </div>
            <div className="space-y-2">
              <Label>Teléfono</Label>
              <Input value={formData.telefono} onChange={e => setFormData({...formData, telefono: e.target.value})} />
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>Días de entrega</Label>
                <Input type="number" value={formData.tiempo_entrega_dias} onChange={e => setFormData({...formData, tiempo_entrega_dias: Number(e.target.value)})} />
              </div>
              <div className="space-y-2">
                <Label>Condiciones de pago</Label>
                <Input value={formData.condiciones_pago} onChange={e => setFormData({...formData, condiciones_pago: e.target.value})} placeholder="30 días, Contado..." />
              </div>
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setModalOpen(false)}>Cancelar</Button>
            <Button onClick={handleGuardar}>Guardar</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Modal Confirmar Eliminar */}
      <AlertDialog open={!!proveedorAEliminar} onOpenChange={(o) => !o && setProveedorAEliminar(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>¿Eliminar proveedor?</AlertDialogTitle>
            <AlertDialogDescription>Esta acción no se puede deshacer.</AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancelar</AlertDialogCancel>
            <AlertDialogAction onClick={() => { if (proveedorAEliminar) { onEliminarProveedor(proveedorAEliminar); setProveedorAEliminar(null); } }}>
              Sí, eliminar
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  );
}
