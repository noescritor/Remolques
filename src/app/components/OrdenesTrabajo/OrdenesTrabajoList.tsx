import React, { useState } from 'react';
import { OrdenTrabajo, Cliente } from '../../types';
import { Button } from '../ui/button';
import { Badge } from '../ui/badge';
import { Input } from '../ui/input';
import { Label } from '../ui/label';
import { Dialog, DialogContent } from '../ui/dialog';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../ui/select';
import { Printer, FileCheck, CheckCircle, Search, Edit } from 'lucide-react';
import { OrdenTrabajoPDF } from './OrdenTrabajoPDF';
import { LiberacionPDF } from './LiberacionPDF';

interface OrdenesTrabajoListProps {
  ordenes: OrdenTrabajo[];
  clientes: Cliente[];
  loading: boolean;
  onActualizarOrden: (id: string, updates: Partial<OrdenTrabajo>) => Promise<any>;
}

export function OrdenesTrabajoList({ ordenes, clientes, loading, onActualizarOrden }: OrdenesTrabajoListProps) {
  const [searchTerm, setSearchTerm] = useState('');
  const [ordenEditando, setOrdenEditando] = useState<OrdenTrabajo | null>(null);
  const [ordenParaPDF, setOrdenParaPDF] = useState<OrdenTrabajo | null>(null);
  const [clienteLiberacion, setClienteLiberacion] = useState<string | null>(null);

  // Estados de edición
  const [editNiv, setEditNiv] = useState('');
  const [editModelo, setEditModelo] = useState('');
  const [editColor, setEditColor] = useState('');
  const [editEstado, setEditEstado] = useState('');

  const ordenesFiltradas = ordenes.filter(o => 
    o.nomenclatura_id.toLowerCase().includes(searchTerm.toLowerCase()) ||
    o.niv?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    o.cliente?.nombre.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const handleEdit = (orden: OrdenTrabajo) => {
    setOrdenEditando(orden);
    setEditNiv(orden.niv || '');
    setEditModelo(orden.modelo || '');
    setEditColor(orden.caracteristicas?.color || '');
    setEditEstado(orden.estado || 'Pendiente');
  };

  const handleSave = async () => {
    if (!ordenEditando) return;
    await onActualizarOrden(ordenEditando.id, {
      niv: editNiv,
      modelo: editModelo,
      estado: editEstado,
      caracteristicas: { ...ordenEditando.caracteristicas, color: editColor }
    });
    setOrdenEditando(null);
  };

  const handlePrint = () => window.print();

  const ordenesParaLiberar = clienteLiberacion 
    ? ordenes.filter(o => o.cliente_id === clienteLiberacion && o.estado === 'Terminado')
    : [];

  return (
    <div className="space-y-6 pb-20 print:pb-0">
      <div className="flex justify-between items-center print:hidden">
        <div>
          <h1 className="text-3xl font-bold text-foreground mb-2">Órdenes de Trabajo</h1>
          <p className="text-gray-400">Control de producción y nomenclatura oficial</p>
        </div>
        <div className="flex gap-4">
          <Select value={clienteLiberacion || ''} onValueChange={setClienteLiberacion}>
            <SelectTrigger className="w-64 bg-slate-900 border-border">
              <SelectValue placeholder="Liberar equipos por cliente..." />
            </SelectTrigger>
            <SelectContent>
              {clientes.map(c => (
                <SelectItem key={c.id} value={c.id}>{c.nombre}</SelectItem>
              ))}
            </SelectContent>
          </Select>
          <Button 
            disabled={!clienteLiberacion || ordenesParaLiberar.length === 0}
            onClick={() => window.print()}
            className="bg-green-600 hover:bg-green-700 text-foreground"
          >
            <FileCheck className="w-4 h-4 mr-2" />
            Imprimir Liberación ({ordenesParaLiberar.length})
          </Button>
        </div>
      </div>

      {/* Vistas PDF (Solo visibles al imprimir) */}
      <div className="hidden print:block">
        {clienteLiberacion && ordenesParaLiberar.length > 0 ? (
          <LiberacionPDF ordenes={ordenesParaLiberar} />
        ) : ordenParaPDF ? (
          <OrdenTrabajoPDF orden={ordenParaPDF} />
        ) : null}
      </div>

      {/* Lista Principal */}
      <div className="bg-slate-900 border border-border rounded-xl overflow-hidden print:hidden">
        <div className="p-4 border-b border-border">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-gray-500" />
            <Input 
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              placeholder="Buscar por Nomenclatura, NIV o Cliente..." 
              className="pl-10 bg-slate-800 border-border text-foreground"
            />
          </div>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-sm text-left text-gray-300">
            <thead className="text-xs text-gray-400 uppercase bg-slate-800/50">
              <tr>
                <th className="px-6 py-3">ID / Nomenclatura</th>
                <th className="px-6 py-3">Cliente</th>
                <th className="px-6 py-3">Tipo / Descripción</th>
                <th className="px-6 py-3">NIV / Modelo</th>
                <th className="px-6 py-3">Estado</th>
                <th className="px-6 py-3 text-right">Acciones</th>
              </tr>
            </thead>
            <tbody>
              {ordenesFiltradas.map(orden => (
                <tr key={orden.id} className="border-b border-white/5 hover:bg-card/50">
                  <td className="px-6 py-4 font-mono font-bold text-foreground">{orden.nomenclatura_id}</td>
                  <td className="px-6 py-4">{orden.cliente?.nombre}</td>
                  <td className="px-6 py-4">{orden.caracteristicas?.descripcion_corta}</td>
                  <td className="px-6 py-4">
                    {orden.niv ? (
                      <span className="font-mono text-xs">{orden.niv}</span>
                    ) : (
                      <span className="text-gray-500 italic">Sin asignar</span>
                    )}
                    <div className="text-xs text-gray-500 mt-1">{orden.modelo || 'Sin modelo'}</div>
                  </td>
                  <td className="px-6 py-4">
                    <Badge variant="outline" className={
                      orden.estado === 'Terminado' ? 'bg-green-500/10 text-green-500 border-green-500/20' :
                      orden.estado === 'En Producción' ? 'bg-blue-500/10 text-blue-500 border-blue-500/20' :
                      orden.estado === 'Liberado' ? 'bg-purple-500/10 text-purple-500 border-purple-500/20' :
                      'bg-slate-500/10 text-slate-300 border-slate-500/20'
                    }>
                      {orden.estado}
                    </Badge>
                  </td>
                  <td className="px-6 py-4 text-right space-x-2">
                    <Button variant="ghost" size="icon" onClick={() => handleEdit(orden)}>
                      <Edit className="w-4 h-4 text-blue-400" />
                    </Button>
                    <Button variant="ghost" size="icon" onClick={() => setOrdenParaPDF(orden)}>
                      <Printer className="w-4 h-4 text-gray-400" />
                    </Button>
                  </td>
                </tr>
              ))}
              {ordenesFiltradas.length === 0 && (
                <tr>
                  <td colSpan={6} className="px-6 py-12 text-center text-gray-500">
                    No se encontraron órdenes de trabajo
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Modal Editor */}
      <Dialog open={!!ordenEditando} onOpenChange={(open) => !open && setOrdenEditando(null)}>
        <DialogContent className="bg-slate-900 border-border text-foreground w-full max-w-md">
          <h2 className="text-xl font-bold mb-4">Editar Orden: {ordenEditando?.nomenclatura_id}</h2>
          <div className="space-y-4">
            <div>
              <Label>NIV (Número de Identificación Vehicular)</Label>
              <Input value={editNiv} onChange={e => setEditNiv(e.target.value)} className="bg-slate-800 uppercase font-mono" />
            </div>
            <div>
              <Label>Modelo (Año)</Label>
              <Input value={editModelo} onChange={e => setEditModelo(e.target.value)} className="bg-slate-800" />
            </div>
            <div>
              <Label>Color de la unidad</Label>
              <Input value={editColor} onChange={e => setEditColor(e.target.value)} className="bg-slate-800" />
            </div>
            <div>
              <Label>Estado de Producción</Label>
              <Select value={editEstado} onValueChange={setEditEstado}>
                <SelectTrigger className="bg-slate-800 border-border">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="Pendiente">Pendiente</SelectItem>
                  <SelectItem value="En Producción">En Producción</SelectItem>
                  <SelectItem value="Terminado">Terminado</SelectItem>
                  <SelectItem value="Liberado">Liberado</SelectItem>
                </SelectContent>
              </Select>
            </div>
            <Button onClick={handleSave} className="w-full bg-blue-600 hover:bg-blue-700 text-foreground">
              Guardar Cambios
            </Button>
          </div>
        </DialogContent>
      </Dialog>

      {/* Modal Visor de PDF (Orden Individual) */}
      <Dialog open={!!ordenParaPDF} onOpenChange={(open) => !open && setOrdenParaPDF(null)}>
        <DialogContent className="w-full sm:max-w-4xl max-h-[90vh] overflow-y-auto bg-slate-900 border-border p-6 print:hidden">
          <div className="flex justify-between items-center mb-4">
            <h2 className="text-lg font-bold text-foreground">Vista Previa de Orden de Trabajo</h2>
            <Button onClick={handlePrint} className="bg-white text-black hover:bg-slate-200">
              <Printer className="h-4 w-4 mr-2" /> Imprimir Orden
            </Button>
          </div>
          <div className="bg-white p-4 rounded shadow-xl overflow-x-auto">
            {ordenParaPDF && <OrdenTrabajoPDF orden={ordenParaPDF} />}
          </div>
        </DialogContent>
      </Dialog>
    </div>
  );
}
