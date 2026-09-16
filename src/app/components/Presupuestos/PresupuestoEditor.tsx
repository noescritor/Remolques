import { useState, useEffect } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '../ui/card';
import { Button } from '../ui/button';
import { Input } from '../ui/input';
import { Label } from '../ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../ui/select';
import { Presupuesto, Cliente, PresupuestoDatos } from '../../types';
import { defaultPresupuestoDatos } from './presupuestoTemplate';
import { ArrowLeft, Save, Plus, Trash2 } from 'lucide-react';
import { toast } from 'sonner';

interface Props {
  presupuesto: Presupuesto | null;
  clientes: Cliente[];
  onSave: (p: Partial<Presupuesto>) => Promise<any>;
  onUpdate: (id: string, p: Partial<Presupuesto>) => Promise<any>;
  onClose: () => void;
}

export function PresupuestoEditor({ presupuesto, clientes, onSave, onUpdate, onClose }: Props) {
  const [folio, setFolio] = useState(presupuesto?.folio || `PRE-${new Date().getTime().toString().slice(-6)}`);
  const [fecha, setFecha] = useState(presupuesto?.fecha ? new Date(presupuesto.fecha).toISOString().split('T')[0] : new Date().toISOString().split('T')[0]);
  const [clienteId, setClienteId] = useState(presupuesto?.cliente_id || 'ninguno');
  const [nomenclatura, setNomenclatura] = useState(presupuesto?.nomenclatura_id || '');
  const [concepto, setConcepto] = useState(presupuesto?.concepto || '');
  const [datos, setDatos] = useState<PresupuestoDatos>(
    presupuesto?.datos ? JSON.parse(JSON.stringify(presupuesto.datos)) : JSON.parse(JSON.stringify(defaultPresupuestoDatos))
  );
  const [precioVenta, setPrecioVenta] = useState(presupuesto?.precio_venta?.toString() || '0');
  const [saving, setSaving] = useState(false);

  // Calcular importe por item y total por seccion
  const updateItem = (seccion: keyof PresupuestoDatos, index: number, field: string, value: string) => {
    setDatos(prev => {
      const next = { ...prev };
      const item = next[seccion].items[index];
      
      if (field === 'pzas') item.pzas = value;
      if (field === 'material') item.material = value;
      if (field === 'cu') item.cu = parseFloat(value) || 0;

      // Calcular importe
      const pzasNum = parseFloat(item.pzas.toString()) || 0;
      item.importe = pzasNum * item.cu;

      // Recalcular total seccion
      next[seccion].total = next[seccion].items.reduce((acc, curr) => acc + (curr.importe || 0), 0);
      
      return next;
    });
  };

  const addItem = (seccion: keyof PresupuestoDatos) => {
    setDatos(prev => {
      const next = { ...prev };
      next[seccion].items.push({ pzas: '1', material: '', cu: 0, importe: 0 });
      return next;
    });
  };

  const removeItem = (seccion: keyof PresupuestoDatos, index: number) => {
    setDatos(prev => {
      const next = { ...prev };
      next[seccion].items.splice(index, 1);
      next[seccion].total = next[seccion].items.reduce((acc, curr) => acc + (curr.importe || 0), 0);
      return next;
    });
  };

  const calcularGranTotal = () => {
    return Object.values(datos).reduce((acc, sec) => acc + (sec.total || 0), 0);
  };

  const handleSave = async () => {
    setSaving(true);
    try {
      const payload: Partial<Presupuesto> = {
        folio,
        fecha: new Date(fecha).toISOString(),
        cliente_id: clienteId === 'ninguno' ? null : clienteId,
        nomenclatura_id: nomenclatura,
        concepto,
        datos,
        total_costo: calcularGranTotal(),
        precio_venta: parseFloat(precioVenta) || 0
      };

      if (presupuesto?.id) {
        await onUpdate(presupuesto.id, payload);
      } else {
        await onSave(payload);
      }
      onClose();
    } catch (error) {
      // toast ya se maneja en el hook
    } finally {
      setSaving(false);
    }
  };

  const renderSeccion = (titulo: string, key: keyof PresupuestoDatos, bgCls: string) => (
    <div className="border rounded-md overflow-hidden mb-6">
      <div className={`px-4 py-2 font-bold text-sm text-white ${bgCls} flex justify-between items-center`}>
        {titulo}
        <Button variant="ghost" size="sm" className="h-6 w-6 p-0 hover:bg-white/20 text-white" onClick={() => addItem(key)}>
          <Plus className="h-4 w-4" />
        </Button>
      </div>
      <div className="p-0 overflow-x-auto">
        <table className="w-full text-sm">
          <thead className="bg-muted/50 border-b">
            <tr>
              <th className="text-left p-2 w-20">PZAS</th>
              <th className="text-left p-2">MATERIAL / ACCESORIO</th>
              <th className="text-left p-2 w-32">$ C/U</th>
              <th className="text-left p-2 w-32">IMPORTE</th>
              <th className="w-10"></th>
            </tr>
          </thead>
          <tbody className="divide-y">
            {datos[key].items.map((item, idx) => (
              <tr key={idx} className="hover:bg-muted/30">
                <td className="p-1">
                  <Input className="h-8 text-xs" value={item.pzas} onChange={e => updateItem(key, idx, 'pzas', e.target.value)} />
                </td>
                <td className="p-1">
                  <Input className="h-8 text-xs" value={item.material} onChange={e => updateItem(key, idx, 'material', e.target.value)} />
                </td>
                <td className="p-1">
                  <Input className="h-8 text-xs text-right" type="number" value={item.cu === 0 ? '' : item.cu} onChange={e => updateItem(key, idx, 'cu', e.target.value)} placeholder="0" />
                </td>
                <td className="p-2 text-right font-medium text-muted-foreground">
                  ${(item.importe || 0).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
                </td>
                <td className="p-1 text-center">
                  <Button variant="ghost" size="sm" className="h-8 w-8 p-0 text-red-500 hover:text-red-700" onClick={() => removeItem(key, idx)}>
                    <Trash2 className="h-4 w-4" />
                  </Button>
                </td>
              </tr>
            ))}
          </tbody>
          <tfoot className="bg-muted/50 font-bold border-t border-b-0">
            <tr>
              <td colSpan={3} className="p-2 text-right">TOTAL {titulo.toUpperCase()}</td>
              <td className="p-2 text-right">${(datos[key].total || 0).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</td>
              <td></td>
            </tr>
          </tfoot>
        </table>
      </div>
    </div>
  );

  return (
    <div className="space-y-4 max-w-7xl mx-auto pb-20">
      <div className="flex justify-between items-center bg-card p-4 rounded-lg border shadow-sm sticky top-0 z-10">
        <div className="flex items-center gap-4">
          <Button variant="ghost" onClick={onClose}><ArrowLeft className="mr-2 h-4 w-4" /> Volver</Button>
          <h2 className="text-xl font-bold">
            {presupuesto ? `Editar Presupuesto ${presupuesto.folio}` : 'Nuevo Presupuesto'}
          </h2>
        </div>
        <Button onClick={handleSave} disabled={saving}>
          <Save className="mr-2 h-4 w-4" /> {saving ? 'Guardando...' : 'Guardar Presupuesto'}
        </Button>
      </div>

      <Card>
        <CardContent className="pt-6 grid grid-cols-1 md:grid-cols-4 gap-4">
          <div className="space-y-2">
            <Label>Folio</Label>
            <Input value={folio} onChange={e => setFolio(e.target.value)} />
          </div>
          <div className="space-y-2">
            <Label>Fecha</Label>
            <Input type="date" value={fecha} onChange={e => setFecha(e.target.value)} />
          </div>
          <div className="space-y-2 md:col-span-2">
            <Label>Cliente (Opcional)</Label>
            <Select value={clienteId} onValueChange={setClienteId}>
              <SelectTrigger><SelectValue placeholder="Seleccione un cliente" /></SelectTrigger>
              <SelectContent>
                <SelectItem value="ninguno">A QUIEN CORRESPONDA</SelectItem>
                {clientes.map(c => <SelectItem key={c.id} value={c.id}>{c.nombre_comercial || c.razon_social}</SelectItem>)}
              </SelectContent>
            </Select>
          </div>
          <div className="space-y-2 md:col-span-4">
            <Label>Nomenclatura / ID (Ej: 9-GA5010226-6)</Label>
            <Input value={nomenclatura} onChange={e => setNomenclatura(e.target.value)} />
          </div>
          <div className="space-y-2 md:col-span-4">
            <Label>Concepto</Label>
            <Input value={concepto} onChange={e => setConcepto(e.target.value)} placeholder="SEMIREMOLQUE TIPO: PLATAFORMA 40 FT..." />
          </div>
        </CardContent>
      </Card>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div>
          {renderSeccion('Acero', 'acero', 'bg-slate-700')}
          {renderSeccion('Pirámide', 'piramide', 'bg-slate-700')}
          {renderSeccion('Truckzone', 'truckzone', 'bg-slate-700')}
        </div>
        <div>
          {renderSeccion('Otros', 'otros', 'bg-emerald-700')}
          {renderSeccion('Piso', 'piso', 'bg-emerald-700')}
          {renderSeccion('Extras', 'extras', 'bg-teal-700')}
          {renderSeccion('Rines y Llantas', 'rines', 'bg-teal-700')}
          {renderSeccion('Mano de Obra', 'manoobra', 'bg-emerald-700')}
          {renderSeccion('Adicionales', 'adicionales', 'bg-slate-700')}
          {renderSeccion('Gastos Indirectos', 'indirectos', 'bg-slate-700')}
        </div>
      </div>

      <Card className="border-2 border-primary/20 bg-primary/5">
        <CardContent className="pt-6">
          <div className="flex flex-col md:flex-row justify-between items-end gap-6">
            <div className="w-full md:w-1/2 space-y-2">
              <Label className="text-lg text-primary">Gran Total (Costo Fabricación)</Label>
              <div className="text-3xl font-bold text-primary">
                ${calcularGranTotal().toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
              </div>
            </div>
            <div className="w-full md:w-1/2 space-y-2">
              <Label className="text-lg">Precio de Venta Sugerido / Final</Label>
              <Input 
                type="number" 
                className="text-2xl font-bold h-14" 
                value={precioVenta} 
                onChange={e => setPrecioVenta(e.target.value)} 
              />
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
