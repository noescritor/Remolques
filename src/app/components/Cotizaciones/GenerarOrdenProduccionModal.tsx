import { useState } from 'react';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription } from '../ui/dialog';
import { Button } from '../ui/button';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../ui/select';
import { Input } from '../ui/input';
import { Label } from '../ui/label';
import { Cotizacion, Producto } from '../../types';
import { Loader2, Plus, Trash2, Factory } from 'lucide-react';
import { toast } from 'sonner';

interface GenerarOrdenProduccionModalProps {
  cotizacion: Cotizacion;
  productos: Producto[];
  isOpen: boolean;
  onClose: () => void;
  onGenerar: (items: any[]) => Promise<void>;
}

export function GenerarOrdenProduccionModal({
  cotizacion,
  productos,
  isOpen,
  onClose,
  onGenerar
}: GenerarOrdenProduccionModalProps) {
  const [items, setItems] = useState<{ material_id: string; cantidad: number; costo_unitario: number }[]>([]);
  const [loading, setLoading] = useState(false);

  const materiasPrimas = productos.filter(p => p.categoria_id === productos.find(x => x.nombre === 'Eje de 3500 lbs')?.categoria_id || true);

  const handleAddItem = () => {
    setItems([...items, { material_id: '', cantidad: 1, costo_unitario: 0 }]);
  };

  const handleRemoveItem = (index: number) => {
    setItems(items.filter((_, i) => i !== index));
  };

  const handleItemChange = (index: number, field: string, value: any) => {
    const newItems = [...items];
    (newItems[index] as any)[field] = value;
    
    if (field === 'material_id') {
      const prod = productos.find(p => p.id === value);
      if (prod && prod.costo) {
        newItems[index].costo_unitario = prod.costo;
      }
    }
    setItems(newItems);
  };

  const handleSubmit = async () => {
    if (items.length === 0 || items.some(i => !i.material_id || i.cantidad <= 0)) {
      toast.error('Agrega al menos un material válido');
      return;
    }

    setLoading(true);
    try {
      await onGenerar(items);
      toast.success('Orden de producción iniciada y materiales descontados del inventario.');
      onClose();
    } catch (error) {
      toast.error('Error al generar orden de producción');
    } finally {
      setLoading(false);
    }
  };

  return (
    <Dialog open={isOpen} onOpenChange={(open) => !open && onClose()}>
      <DialogContent className="sm:max-w-[600px] bg-black border-white/10 text-white">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <Factory className="w-5 h-5 text-purple-400" />
            Enviar a Producción
          </DialogTitle>
          <DialogDescription>
            Registra los materiales que saldrán del almacén para fabricar la cotización {cotizacion.folio}.
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-6 py-4">
          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <Label>Materiales a Consumir (Salida de Almacén)</Label>
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
                        <SelectItem key={p.id} value={p.id}>
                          {p.nombre} {p.stock_actual !== undefined ? `(Stock: ${p.stock_actual})` : ''}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
                <div className="w-32 space-y-2">
                  <Label className="text-xs">Cant. a consumir</Label>
                  <Input 
                    type="number" 
                    min="1" 
                    value={item.cantidad} 
                    onChange={(e) => handleItemChange(idx, 'cantidad', parseFloat(e.target.value))} 
                  />
                </div>
                <Button variant="ghost" size="icon" onClick={() => handleRemoveItem(idx)} className="text-red-400 hover:text-red-300 hover:bg-red-400/10">
                  <Trash2 className="w-4 h-4" />
                </Button>
              </div>
            ))}

            {items.length === 0 && (
              <div className="text-center py-8 text-muted-foreground border border-dashed border-white/10 rounded-lg">
                No has agregado materiales. Haz clic en "Agregar Material" para descontarlos del inventario.
              </div>
            )}
          </div>
        </div>

        <div className="flex justify-end gap-2 pt-4 border-t border-white/10">
          <Button variant="ghost" onClick={onClose} disabled={loading}>Cancelar</Button>
          <Button onClick={handleSubmit} disabled={loading || items.length === 0} className="bg-purple-600 text-white hover:bg-purple-700">
            {loading && <Loader2 className="w-4 h-4 mr-2 animate-spin" />}
            Confirmar Producción
          </Button>
        </div>
      </DialogContent>
    </Dialog>
  );
}
