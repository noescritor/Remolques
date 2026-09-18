import { useState, useEffect } from 'react';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription } from '../ui/dialog';
import { Button } from '../ui/button';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../ui/select';
import { Input } from '../ui/input';
import { Label } from '../ui/label';
import { Cotizacion, Producto, Proveedor } from '../../types';
import { Loader2, Plus, Trash2 } from 'lucide-react';
import { toast } from 'sonner';
import { supabase as supa } from '../../utils/supabase/client';

interface GenerarRequisicionModalProps {
  cotizacion: Cotizacion;
  productos: Producto[];
  proveedores: Proveedor[];
  isOpen: boolean;
  onClose: () => void;
  onGenerar: (proveedorId: string, items: any[]) => Promise<void>;
}

export function GenerarRequisicionModal({
  cotizacion,
  productos,
  proveedores,
  isOpen,
  onClose,
  onGenerar
}: GenerarRequisicionModalProps) {
  const [proveedorId, setProveedorId] = useState<string>('');
  const [items, setItems] = useState<{ material_id: string; cantidad: number; costo_unitario: number }[]>([]);
  const [loading, setLoading] = useState(false);
  const [loadingReq, setLoadingReq] = useState(false);

  const materiasPrimas = productos.filter(p => p.tipo_item === 'materia_prima');

  useEffect(() => {
    if (isOpen && cotizacion) {
      cargarFaltantes();
    }
  }, [isOpen, cotizacion]);

  const cargarFaltantes = async () => {
    setLoadingReq(true);
    try {
      
      const orgId = (await supa.auth.getUser()).data.user?.user_metadata?.organizacion_id || localStorage.getItem('org_id');
      const res = await fetch(`${import.meta.env.VITE_SUPABASE_API_URL}/cotizaciones/${cotizacion.id}/requisicion`, {
        headers: { 'Authorization': `Bearer ${(await supa.auth.getSession()).data.session?.access_token}`, 'x-org-id': orgId }
      });
      if (res.ok) {
        const faltantes = await res.json();
        const itemsList = faltantes.filter((f: any) => f.faltante > 0).map((f: any) => ({
          material_id: f.material_id,
          cantidad: f.faltante,
          costo_unitario: f.costo || 0
        }));
        setItems(itemsList);
      }
    } catch (e) {
      console.error(e);
    } finally {
      setLoadingReq(false);
    }
  };

  const handleAddItem = () => {
    setItems([...items, { material_id: '', cantidad: 1, costo_unitario: 0 }]);
  };

  const handleRemoveItem = (index: number) => {
    setItems(items.filter((_, i) => i !== index));
  };

  const handleItemChange = (index: number, field: string, value: any) => {
    const newItems = [...items];
    (newItems[index] as any)[field] = value;
    
    // Autofill cost
    if (field === 'material_id') {
      const prod = productos.find(p => p.id === value);
      if (prod && prod.costo) {
        newItems[index].costo_unitario = prod.costo;
      }
    }
    setItems(newItems);
  };

  const handleSubmit = async () => {
    if (!proveedorId) {
      toast.error('Selecciona un proveedor');
      return;
    }
    if (items.length === 0 || items.some(i => !i.material_id || i.cantidad <= 0)) {
      toast.error('Agrega al menos un material válido');
      return;
    }

    setLoading(true);
    try {
      await onGenerar(proveedorId, items);
      toast.success('Orden de compra generada exitosamente');
      onClose();
    } catch (error) {
      toast.error('Error al generar orden de compra');
    } finally {
      setLoading(false);
    }
  };

  return (
    <Dialog open={isOpen} onOpenChange={(open) => !open && onClose()}>
      <DialogContent className="sm:max-w-[600px] bg-black border-border text-foreground">
        <DialogHeader>
          <DialogTitle>Generar Orden de Compra (Requisición)</DialogTitle>
          <DialogDescription>
            Genera una compra de materiales para la cotización {cotizacion.folio}.
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-6 py-4">
          <div className="space-y-2">
            <Label>Proveedor</Label>
            <Select value={proveedorId} onValueChange={setProveedorId}>
              <SelectTrigger>
                <SelectValue placeholder="Seleccionar proveedor..." />
              </SelectTrigger>
              <SelectContent>
                {proveedores.map(p => (
                  <SelectItem key={p.id} value={p.id}>{p.nombre}</SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>

          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <Label>Materiales Faltantes</Label>
              <Button size="sm" variant="outline" onClick={handleAddItem}>
                <Plus className="w-4 h-4 mr-2" /> Agregar Material
              </Button>
            </div>

            {loadingReq ? (
              <div className="flex justify-center py-4"><Loader2 className="w-6 h-6 animate-spin text-muted-foreground" /></div>
            ) : items.map((item, idx) => (
              <div key={idx} className="flex gap-4 items-end bg-card/50 p-3 rounded-lg border border-white/5">
                <div className="flex-1 space-y-2">
                  <Label className="text-xs">Materia Prima / Refacción</Label>
                  <Select value={item.material_id} onValueChange={(v) => handleItemChange(idx, 'material_id', v)}>
                    <SelectTrigger>
                      <SelectValue placeholder="Seleccionar..." />
                    </SelectTrigger>
                    <SelectContent>
                      {materiasPrimas.map(p => (
                        <SelectItem key={p.id} value={p.id}>{p.nombre}</SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
                <div className="w-24 space-y-2">
                  <Label className="text-xs">Cantidad</Label>
                  <Input 
                    type="number" 
                    min="1" 
                    value={item.cantidad} 
                    onChange={(e) => handleItemChange(idx, 'cantidad', parseFloat(e.target.value))} 
                  />
                </div>
                <div className="w-32 space-y-2">
                  <Label className="text-xs">Costo Unit.</Label>
                  <Input 
                    type="number" 
                    min="0" 
                    step="0.01" 
                    value={item.costo_unitario} 
                    onChange={(e) => handleItemChange(idx, 'costo_unitario', parseFloat(e.target.value))} 
                  />
                </div>
                <Button variant="ghost" size="icon" onClick={() => handleRemoveItem(idx)} className="text-red-400 hover:text-red-300 hover:bg-red-400/10">
                  <Trash2 className="w-4 h-4" />
                </Button>
              </div>
            ))}

            {!loadingReq && items.length === 0 && (
              <div className="text-center py-8 text-muted-foreground border border-dashed border-border rounded-lg">
                No hay faltantes calculados. Haz clic en "Agregar Material" para añadir uno manualmente.
              </div>
            )}
          </div>
        </div>

        <div className="flex justify-end gap-2 pt-4 border-t border-border">
          <Button variant="ghost" onClick={onClose} disabled={loading}>Cancelar</Button>
          <Button onClick={handleSubmit} disabled={loading || items.length === 0 || !proveedorId} className="bg-accent-blue text-white hover:bg-accent-blue/90">
            {loading && <Loader2 className="w-4 h-4 mr-2 animate-spin" />}
            Confirmar Compra
          </Button>
        </div>
      </DialogContent>
    </Dialog>
  );
}
