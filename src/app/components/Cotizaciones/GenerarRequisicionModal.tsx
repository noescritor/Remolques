import { useState } from 'react';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription } from '../ui/dialog';
import { Button } from '../ui/button';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../ui/select';
import { Input } from '../ui/input';
import { Label } from '../ui/label';
import { Cotizacion, Producto, Proveedor } from '../../types';
import { Loader2, Plus, Trash2 } from 'lucide-react';
import { toast } from 'sonner';

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

  const materiasPrimas = productos.filter(p => p.categoria_id === productos.find(x => x.nombre === 'Eje de 3500 lbs')?.categoria_id || true); // Default all or filter by category

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
      <DialogContent className="sm:max-w-[600px] bg-black border-white/10 text-white">
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

            {items.map((item, idx) => (
              <div key={idx} className="flex gap-4 items-end bg-white/[0.02] p-3 rounded-lg border border-white/5">
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

            {items.length === 0 && (
              <div className="text-center py-8 text-muted-foreground border border-dashed border-white/10 rounded-lg">
                Haz clic en "Agregar Material" para comenzar a armar la requisición.
              </div>
            )}
          </div>
        </div>

        <div className="flex justify-end gap-2 pt-4 border-t border-white/10">
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
