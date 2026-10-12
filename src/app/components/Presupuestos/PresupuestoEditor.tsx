import { useState } from 'react';
import { Card, CardContent } from '../ui/card';
import { Button } from '../ui/button';
import { Input } from '../ui/input';
import { Label } from '../ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../ui/select';
import { Presupuesto, Cliente, PresupuestoDatos, PresupuestoSeccion } from '../../types';
import { defaultPresupuestoDatos } from './presupuestoTemplate';
import { ArrowLeft, Save, Plus, Trash2, AlertTriangle, CheckCircle2 } from 'lucide-react';

interface Props {
  presupuesto: Presupuesto | null;
  clientes: Cliente[];
  onSave: (p: Partial<Presupuesto>) => Promise<any>;
  onUpdate: (id: string, p: Partial<Presupuesto>) => Promise<any>;
  onClose: () => void;
}

const SECCIONES_PRESUPUESTO: (keyof PresupuestoDatos)[] = [
  'acero',
  'tornilleria',
  'piramide',
  'truckzone',
  'luz',
  'aire',
  'pintura',
  'piso',
  'otros',
  'extras',
  'rines',
  'manoobra',
  'adicionales',
  'indirectos'
];

export function PresupuestoEditor({ presupuesto, clientes, onSave, onUpdate, onClose }: Props) {
  const [folio, setFolio] = useState(presupuesto?.folio || `PRE-${new Date().getTime().toString().slice(-6)}`);
  const [fecha, setFecha] = useState(presupuesto?.fecha ? new Date(presupuesto.fecha).toISOString().split('T')[0] : new Date().toISOString().split('T')[0]);
  const [clienteId, setClienteId] = useState(presupuesto?.cliente_id || 'ninguno');
  const [nomenclatura, setNomenclatura] = useState(presupuesto?.nomenclatura_id || '');
  const [concepto, setConcepto] = useState(presupuesto?.concepto || '');
  const [datos, setDatos] = useState<PresupuestoDatos>(() => {
    const raw = presupuesto?.datos ? JSON.parse(JSON.stringify(presupuesto.datos)) : JSON.parse(JSON.stringify(defaultPresupuestoDatos));
    const merged: any = { ...raw };
    for (const key of SECCIONES_PRESUPUESTO) {
      if (!merged[key] || !Array.isArray(merged[key].items)) {
        merged[key] = { items: [], total: 0 };
      }
    }
    return merged as PresupuestoDatos;
  });
  const [precioVenta, setPrecioVenta] = useState(presupuesto?.precio_venta?.toString() || '0');
  const [saving, setSaving] = useState(false);

  // Calcular importe por item y total por seccion
  const updateItem = (seccion: keyof PresupuestoDatos, index: number, field: string, value: string) => {
    setDatos(prev => {
      const next = { ...prev };
      const sec = next[seccion] ? { ...next[seccion] } : { items: [], total: 0 };
      const items = [...(sec.items || [])];
      const item = { ...items[index] };
      
      if (field === 'pzas') item.pzas = value;
      if (field === 'material') item.material = value;
      if (field === 'cu') {
        const valCu = parseFloat(value) || 0;
        item.cu = valCu;
        if (valCu > 0 && item.sin_precio) {
          delete item.sin_precio;
        }
      }

      // Calcular importe
      const pzasNum = parseFloat(item.pzas.toString()) || 0;
      item.importe = pzasNum * item.cu;

      items[index] = item;
      sec.items = items;
      sec.total = items.reduce((acc, curr) => acc + (curr.importe || 0), 0);
      next[seccion] = sec;
      
      return next;
    });
  };

  const addItem = (seccion: keyof PresupuestoDatos) => {
    setDatos(prev => {
      const next = { ...prev };
      const sec = next[seccion] ? { ...next[seccion] } : { items: [], total: 0 };
      const items = [...(sec.items || [])];
      items.push({ pzas: '1', material: '', cu: 0, importe: 0 });
      sec.items = items;
      next[seccion] = sec;
      return next;
    });
  };

  const removeItem = (seccion: keyof PresupuestoDatos, index: number) => {
    setDatos(prev => {
      const next = { ...prev };
      const sec = next[seccion] ? { ...next[seccion] } : { items: [], total: 0 };
      const items = [...(sec.items || [])];
      items.splice(index, 1);
      sec.items = items;
      sec.total = items.reduce((acc, curr) => acc + (curr.importe || 0), 0);
      next[seccion] = sec;
      return next;
    });
  };

  const calcularGranTotal = () => {
    return SECCIONES_PRESUPUESTO.reduce((acc, key) => {
      const sec = datos[key] as PresupuestoSeccion | undefined;
      return acc + (sec?.total || 0);
    }, 0);
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
    } catch {
      // toast ya se maneja en el hook
    } finally {
      setSaving(false);
    }
  };

  const meta = datos.meta;
  const esCostoEstimado = !!(meta?.confianza && meta.confianza !== 'completa');
  const totalSinPrecio = SECCIONES_PRESUPUESTO.reduce((acc, key) => {
    const sec = datos[key] as PresupuestoSeccion | undefined;
    return acc + (sec?.items || []).filter(i => i.sin_precio).length;
  }, 0);

  const renderSeccion = (titulo: string, key: keyof PresupuestoDatos) => {
    const sec = (datos[key] as PresupuestoSeccion) || { items: [], total: 0 };
    const items = sec.items || [];
    return (
      <div className="border border-border rounded-md overflow-hidden mb-6 bg-card">
        <div className="px-4 py-2 font-bold text-sm bg-muted text-foreground flex justify-between items-center border-b border-border">
          <span>{titulo}</span>
          <Button variant="ghost" size="sm" className="h-6 w-6 p-0 hover:bg-muted-foreground/10 text-foreground" onClick={() => addItem(key)}>
            <Plus className="h-4 w-4" />
          </Button>
        </div>
        <div className="p-0 overflow-x-auto">
          <table className="w-full text-sm">
            <thead className="bg-muted/50 border-b border-border">
              <tr>
                <th className="text-left p-2 w-20 text-muted-foreground font-medium">PZAS</th>
                <th className="text-left p-2 text-muted-foreground font-medium">MATERIAL / ACCESORIO</th>
                <th className="text-left p-2 w-32 text-muted-foreground font-medium">$ C/U</th>
                <th className="text-left p-2 w-32 text-muted-foreground font-medium">IMPORTE</th>
                <th className="w-10"></th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border">
              {items.map((item, idx) => {
                const isSinPrecio = !!item.sin_precio;
                return (
                  <tr key={idx} className={`hover:bg-muted/30 transition-colors ${isSinPrecio ? 'bg-amber-500/10' : ''}`}>
                    <td className="p-1">
                      <Input className="h-8 text-xs bg-background" value={item.pzas} onChange={e => updateItem(key, idx, 'pzas', e.target.value)} />
                    </td>
                    <td className="p-1">
                      <div className="flex items-center gap-1.5">
                        <Input className="h-8 text-xs bg-background" value={item.material} onChange={e => updateItem(key, idx, 'material', e.target.value)} />
                        {isSinPrecio && (
                          <span className="shrink-0 text-[10px] font-semibold px-1.5 py-0.5 rounded bg-amber-500/20 text-amber-700 dark:text-amber-300 border border-amber-500/30" title="Sin precio registrado">
                            Sin precio
                          </span>
                        )}
                      </div>
                    </td>
                    <td className="p-1">
                      <Input
                        className={`h-8 text-xs text-right bg-background ${isSinPrecio ? 'border-amber-500/50 focus-visible:ring-amber-500' : ''}`}
                        type="number"
                        value={item.cu === 0 ? '' : item.cu}
                        onChange={e => updateItem(key, idx, 'cu', e.target.value)}
                        placeholder="0"
                      />
                    </td>
                    <td className="p-2 text-right font-medium text-foreground">
                      ${(item.importe || 0).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
                    </td>
                    <td className="p-1 text-center">
                      <Button variant="ghost" size="sm" className="h-8 w-8 p-0 text-destructive hover:text-destructive/80 hover:bg-destructive/10" onClick={() => removeItem(key, idx)}>
                        <Trash2 className="h-4 w-4" />
                      </Button>
                    </td>
                  </tr>
                );
              })}
              {items.length === 0 && (
                <tr>
                  <td colSpan={5} className="p-3 text-center text-xs text-muted-foreground italic">
                    Sin partidas en esta sección
                  </td>
                </tr>
              )}
            </tbody>
            <tfoot className="bg-muted/50 font-bold border-t border-border">
              <tr>
                <td colSpan={3} className="p-2 text-right text-xs">TOTAL {titulo.toUpperCase()}</td>
                <td className="p-2 text-right text-xs">${(sec.total || 0).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</td>
                <td></td>
              </tr>
            </tfoot>
          </table>
        </div>
      </div>
    );
  };

  return (
    <div className="space-y-4 max-w-7xl mx-auto pb-20">
      <div className="flex justify-between items-center bg-card p-4 rounded-lg border border-border shadow-sm sticky top-0 z-10">
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

      {meta && (
        <div className={`p-4 rounded-lg border text-sm space-y-3 ${esCostoEstimado ? 'border-amber-500/40 bg-amber-500/10' : 'border-emerald-500/40 bg-emerald-500/10'}`}>
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2 font-semibold text-foreground">
              {esCostoEstimado ? (
                <AlertTriangle className="h-4 w-4 text-amber-600 dark:text-amber-400 shrink-0" />
              ) : (
                <CheckCircle2 className="h-4 w-4 text-emerald-600 dark:text-emerald-400 shrink-0" />
              )}
              <span>
                Confianza del costeo: {meta.confianza === 'completa' ? 'Completo' : 'Costeo estimado'}
              </span>
            </div>
            {meta.generado_en && (
              <span className="text-xs text-muted-foreground">
                Generado: {new Date(meta.generado_en).toLocaleString()}
              </span>
            )}
          </div>

          {totalSinPrecio > 0 && (
            <div className="text-xs text-amber-700 dark:text-amber-300 font-medium">
              Hay {totalSinPrecio} {totalSinPrecio === 1 ? 'partida' : 'partidas'} sin precio registrado. Puedes capturar el costo unitario directamente en la tabla.
            </div>
          )}

          {Array.isArray(meta.pendientes) && meta.pendientes.length > 0 && (
            <div className="space-y-1">
              <span className="text-xs font-semibold block text-foreground">Pendientes detectados:</span>
              <ul className="list-disc list-inside text-xs text-muted-foreground space-y-0.5">
                {meta.pendientes.map((p: string, idx: number) => (
                  <li key={idx}>{p}</li>
                ))}
              </ul>
            </div>
          )}

          {Array.isArray(meta.conceptos_omitidos) && meta.conceptos_omitidos.length > 0 && (
            <div className="space-y-1">
              <span className="text-xs font-semibold block text-foreground">Conceptos de la cotización omitidos:</span>
              <ul className="list-disc list-inside text-xs text-muted-foreground space-y-0.5">
                {meta.conceptos_omitidos.map((o: any, idx: number) => (
                  <li key={idx}>
                    {o.descripcion ? `${o.descripcion}: ` : ''}{o.motivo}
                  </li>
                ))}
              </ul>
            </div>
          )}
        </div>
      )}

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
          {renderSeccion('Acero', 'acero')}
          {renderSeccion('Tornillería', 'tornilleria')}
          {renderSeccion('Pirámide', 'piramide')}
          {renderSeccion('Truckzone', 'truckzone')}
          {renderSeccion('Luz', 'luz')}
          {renderSeccion('Aire', 'aire')}
          {renderSeccion('Pintura', 'pintura')}
        </div>
        <div>
          {renderSeccion('Piso', 'piso')}
          {renderSeccion('Otros', 'otros')}
          {renderSeccion('Extras', 'extras')}
          {renderSeccion('Rines y Llantas', 'rines')}
          {renderSeccion('Mano de Obra', 'manoobra')}
          {renderSeccion('Adicionales', 'adicionales')}
          {renderSeccion('Gastos Indirectos', 'indirectos')}
        </div>
      </div>

      <Card className="border-2 border-primary/20 bg-primary/5">
        <CardContent className="pt-6">
          <div className="flex flex-col md:flex-row justify-between items-end gap-6">
            <div className="w-full md:w-1/2 space-y-2">
              <Label className="text-lg text-primary font-semibold">
                {esCostoEstimado ? 'Gran Total (Costo estimado)' : 'Gran Total (Costo Fabricación)'}
              </Label>
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
