import React, { useState, useEffect } from 'react';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter, DialogDescription } from '../ui/dialog';
import { Button } from '../ui/button';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '../ui/table';
import { Input } from '../ui/input';
import { Producto } from '../../types';
import { supabase } from '../../utils/supabase/client';
import { formatearMoneda } from '../../utils/calculations';
import { ArrowRight, Loader2, Save, Trash2, Plus } from 'lucide-react';
import { useNavigate } from 'react-router-dom';

interface SubItem {
  material_id: string;
  nombre: string;
  cantidad: number;
  costo_unitario: number;
}

interface Props {
  modelo: Producto | null;
  onClose: () => void;
  productosCatalog: Producto[]; // For adding new parts
}

export function ModeloConfiguratorModal({ modelo, onClose, productosCatalog }: Props) {
  const [loading, setLoading] = useState(false);
  const [items, setItems] = useState<SubItem[]>([]);
  const [margen, setMargen] = useState(30);
  const navigate = useNavigate();

  useEffect(() => {
    if (modelo) {
      cargarReceta(modelo.id);
    }
  }, [modelo]);

  const cargarReceta = async (productoId: string) => {
    setLoading(true);
    try {
      // 2R-0: Se deshabilita la carga de producto_materiales porque la receta plana era incorrecta.
      setItems([]);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const costoTotal = items.reduce((acc, item) => acc + (item.cantidad * item.costo_unitario), 0);
  const precioSugerido = costoTotal * (1 + (margen / 100));

  const updateItem = (index: number, field: keyof SubItem, value: number) => {
    const newItems = [...items];
    newItems[index] = { ...newItems[index], [field]: value };
    setItems(newItems);
  };
  
  const removeItem = (index: number) => {
    setItems(items.filter((_, i) => i !== index));
  };

  const handleGenerarCotizacion = () => {
    if (!modelo) return;
    const cpqData = {
      producto_id: modelo.id,
      nombre: modelo.nombre,
      precio_unitario: precioSugerido,
      costo_unitario: costoTotal,
      sub_items: items
    };
    localStorage.setItem('pending_cpq', JSON.stringify(cpqData));
    navigate('/cotizaciones/nueva?from_cpq=true');
  };

  if (!modelo) return null;

  return (
    <Dialog open={!!modelo} onOpenChange={(open) => !open && onClose()}>
      <DialogContent className="max-w-4xl max-h-[90vh] flex flex-col">
        <DialogHeader>
          <DialogTitle className="text-xl">Configurador CPQ: {modelo.nombre}</DialogTitle>
          <DialogDescription>
            Ajusta los materiales, piezas y costos de fabricación para obtener un precio de venta sugerido antes de cotizar.
          </DialogDescription>
        </DialogHeader>

        {loading ? (
          <div className="flex-1 flex justify-center items-center py-12">
            <Loader2 className="w-8 h-8 animate-spin text-blue-500" />
            <span className="ml-2">Cargando receta base...</span>
          </div>
        ) : (
          <div className="flex-1 overflow-y-auto space-y-6 pr-2">
            
            <div className="border rounded-md">
              <Table>
                <TableHeader className="bg-gray-50 sticky top-0">
                  <TableRow>
                    <TableHead>Componente / Material</TableHead>
                    <TableHead className="w-24">Cantidad</TableHead>
                    <TableHead className="w-32">Costo Unitario</TableHead>
                    <TableHead className="w-32 text-right">Costo Total</TableHead>
                    <TableHead className="w-12"></TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {items.length === 0 ? (
                    <TableRow>
                      <TableCell colSpan={5} className="text-center py-8 text-gray-500">
                        No hay materiales base (BOM) configurados para este modelo.
                      </TableCell>
                    </TableRow>
                  ) : (
                    items.map((item, idx) => (
                      <TableRow key={idx}>
                        <TableCell className="font-medium text-xs">
                          {item.nombre}
                        </TableCell>
                        <TableCell>
                          <Input 
                            type="number" 
                            className="w-20 h-8 text-xs" 
                            value={item.cantidad} 
                            onChange={(e) => updateItem(idx, 'cantidad', Number(e.target.value))}
                          />
                        </TableCell>
                        <TableCell>
                          <Input 
                            type="number" 
                            className="w-24 h-8 text-xs" 
                            value={item.costo_unitario} 
                            onChange={(e) => updateItem(idx, 'costo_unitario', Number(e.target.value))}
                          />
                        </TableCell>
                        <TableCell className="text-right font-semibold text-xs">
                          {formatearMoneda(item.cantidad * item.costo_unitario)}
                        </TableCell>
                        <TableCell>
                          <Button variant="ghost" size="sm" className="h-6 w-6 p-0 text-red-500" onClick={() => removeItem(idx)}>
                            <Trash2 className="w-3 h-3" />
                          </Button>
                        </TableCell>
                      </TableRow>
                    ))
                  )}
                </TableBody>
              </Table>
            </div>

            <div className="bg-blue-50/50 p-4 rounded-lg border border-blue-100 flex flex-col md:flex-row justify-between items-center gap-4">
              <div>
                <p className="text-sm text-gray-500 font-semibold uppercase tracking-wider">Costo de Fabricación</p>
                <p className="text-2xl font-bold text-gray-800">{formatearMoneda(costoTotal)}</p>
              </div>
              
              <div className="flex items-center gap-4 border-l border-blue-200 pl-4">
                <div>
                  <p className="text-sm text-gray-500 font-semibold uppercase tracking-wider mb-1">Margen Deseado %</p>
                  <Input 
                    type="number" 
                    className="w-24 font-bold text-center" 
                    value={margen} 
                    onChange={(e) => setMargen(Number(e.target.value))}
                  />
                </div>
                <div>
                  <p className="text-sm text-blue-600 font-semibold uppercase tracking-wider">Precio de Venta (Cotización)</p>
                  <p className="text-2xl font-bold text-blue-700">{formatearMoneda(precioSugerido)}</p>
                </div>
              </div>
            </div>

          </div>
        )}

        <DialogFooter className="mt-4 pt-4 border-t">
          <Button variant="outline" onClick={onClose}>Cancelar</Button>
          <Button onClick={handleGenerarCotizacion} className="bg-accent-blue text-white hover:bg-blue-700" disabled={loading}>
            Llevar a Cotización <ArrowRight className="w-4 h-4 ml-2" />
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
