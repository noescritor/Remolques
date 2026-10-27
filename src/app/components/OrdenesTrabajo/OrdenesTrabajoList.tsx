import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { OrdenTrabajo, Cliente } from '../../types';
import { Button } from '../ui/button';
import { Badge } from '../ui/badge';
import { Input } from '../ui/input';
import { Label } from '../ui/label';
import { Dialog, DialogContent } from '../ui/dialog';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../ui/select';
import { Printer, FileCheck, Search, Edit, Calendar } from 'lucide-react';
import { OrdenTrabajoPDF } from './OrdenTrabajoPDF';
import { LiberacionPDF } from './LiberacionPDF';
import { BASE_URL } from '../../utils/api';

interface OrdenesTrabajoListProps {
  ordenes: OrdenTrabajo[];
  clientes: Cliente[];
  loading: boolean;
  onActualizarOrden: (id: string, updates: Partial<OrdenTrabajo>) => Promise<any>;
  ajustes?: any;
}

export function OrdenesTrabajoList({ ordenes, clientes, loading, onActualizarOrden, ajustes }: OrdenesTrabajoListProps) {
  const navigate = useNavigate();
  const [searchTerm, setSearchTerm] = useState('');
  const [ordenEditando, setOrdenEditando] = useState<OrdenTrabajo | null>(null);
  const [ordenParaPDF, setOrdenParaPDF] = useState<OrdenTrabajo | null>(null);
  const [clienteLiberacion, setClienteLiberacion] = useState<string | null>(null);

  // Estados de edición básicos
  const [editNiv, setEditNiv] = useState('');
  const [editModelo, setEditModelo] = useState('');
  const [editColor, setEditColor] = useState('');
  const [editEstado, setEditEstado] = useState('');

  // Estados de edición de cabecera y nota de la ficha
  const [editPedidoRecibidoPor, setEditPedidoRecibidoPor] = useState('');
  const [editFechaInicioPrevista, setEditFechaInicioPrevista] = useState('');
  const [editFechaFinPrevista, setEditFechaFinPrevista] = useState('');
  const [editTrabajoAutorizadoPor, setEditTrabajoAutorizadoPor] = useState('');
  const [editCompiladaPor, setEditCompiladaPor] = useState('');
  const [editNota, setEditNota] = useState('');

  const ordenesFiltradas = ordenes.filter(o => {
    const query = searchTerm.toLowerCase();
    const nom = (o.nomenclatura_id || '').toLowerCase();
    const niv = (o.niv || '').toLowerCase();
    const cli = (o.cliente?.nombre_razon_social || o.cliente?.nombre || '').toLowerCase();
    const proy = (o.cotizacion?.descripcion || o.caracteristicas?.ficha?.cabecera?.nombre_proyecto || '').toLowerCase();
    return nom.includes(query) || niv.includes(query) || cli.includes(query) || proy.includes(query);
  });

  const handleEdit = (orden: OrdenTrabajo) => {
    setOrdenEditando(orden);
    setEditNiv(orden.niv || '');
    setEditModelo(orden.modelo || '');
    setEditEstado(orden.estado || 'Pendiente');

    const ficha = orden.caracteristicas?.ficha;
    const colorCar = ficha?.caracteristicas?.find((c: any) => c.etiqueta === 'COLOR')?.valor;
    setEditColor(colorCar || orden.caracteristicas?.color || '');

    setEditPedidoRecibidoPor(ficha?.cabecera?.pedido_recibido_por || '');
    setEditFechaInicioPrevista(ficha?.cabecera?.fecha_inicio_prevista || '');
    setEditFechaFinPrevista(ficha?.cabecera?.fecha_fin_prevista || '');
    setEditTrabajoAutorizadoPor(ficha?.cabecera?.trabajo_autorizado_por || '');
    setEditCompiladaPor(ficha?.cabecera?.compilada_por || '');
    setEditNota(ficha?.nota !== undefined ? ficha.nota : (orden.caracteristicas?.observaciones || ''));
  };

  const handleSave = async () => {
    if (!ordenEditando) return;

    const carActuales = ordenEditando.caracteristicas || {};
    const fichaActual = carActuales.ficha || {};

    let nuevasCarFicha = fichaActual.caracteristicas;
    if (nuevasCarFicha && Array.isArray(nuevasCarFicha)) {
      nuevasCarFicha = nuevasCarFicha.map((c: any) =>
        c.etiqueta === 'COLOR' ? { ...c, valor: editColor } : c
      );
    }

    const nuevaFicha = {
      ...fichaActual,
      cabecera: {
        ...(fichaActual.cabecera || {}),
        pedido_recibido_por: editPedidoRecibidoPor,
        fecha_inicio_prevista: editFechaInicioPrevista,
        fecha_fin_prevista: editFechaFinPrevista,
        trabajo_autorizado_por: editTrabajoAutorizadoPor,
        compilada_por: editCompiladaPor
      },
      caracteristicas: nuevasCarFicha,
      nota: editNota
    };

    await onActualizarOrden(ordenEditando.id, {
      niv: editNiv,
      modelo: editModelo,
      estado: editEstado,
      caracteristicas: {
        ...carActuales,
        color: editColor,
        ficha: nuevaFicha
      }
    });

    setOrdenEditando(null);
  };

  const handleRegenerarFicha = async (id: string) => {
    const res = await fetch(`${BASE_URL}/ordenes-trabajo/${id}/regenerar-ficha`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' }
    });
    if (!res.ok) {
      const err = await res.json().catch(() => ({}));
      throw new Error(err.error || 'Error al regenerar ficha');
    }
    const data = await res.json();
    if (data.orden) {
      setOrdenParaPDF(data.orden);
      await onActualizarOrden(id, { caracteristicas: data.orden.caracteristicas });
    }
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
          <p className="text-muted-foreground">Control de producción y formato oficial de remolque</p>
        </div>
        <div className="flex gap-4">
          <Select value={clienteLiberacion || ''} onValueChange={setClienteLiberacion}>
            <SelectTrigger className="w-64 bg-card border-border">
              <SelectValue placeholder="Liberar equipos por cliente..." />
            </SelectTrigger>
            <SelectContent>
              {clientes.map(c => (
                <SelectItem key={c.id} value={c.id}>{c.nombre_razon_social || (c as any).nombre}</SelectItem>
              ))}
            </SelectContent>
          </Select>
          <Button 
            disabled={!clienteLiberacion || ordenesParaLiberar.length === 0}
            onClick={() => window.print()}
            className="bg-green-600 hover:bg-green-700 text-white"
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
          <OrdenTrabajoPDF orden={ordenParaPDF} ajustes={ajustes} onRegenerarFicha={handleRegenerarFicha} />
        ) : null}
      </div>

      {/* Lista Principal */}
      <div className="bg-card border border-border/50 rounded-xl overflow-hidden print:hidden">
        <div className="p-4 border-b border-border">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-muted-foreground" />
            <Input 
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              placeholder="Buscar por Nomenclatura, Cliente, Proyecto o NIV..." 
              className="pl-10 bg-background border-border text-foreground"
            />
          </div>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-sm text-left text-muted-foreground">
            <thead className="text-xs text-muted-foreground uppercase bg-muted/50">
              <tr>
                <th className="px-6 py-3">ID / Nomenclatura</th>
                <th className="px-6 py-3">Cliente</th>
                <th className="px-6 py-3">Proyecto</th>
                <th className="px-6 py-3">Equipo</th>
                <th className="px-6 py-3">Estado</th>
                <th className="px-6 py-3">Fecha Pedido</th>
                <th className="px-6 py-3 text-right">Acciones</th>
              </tr>
            </thead>
            <tbody>
              {ordenesFiltradas.map(orden => {
                const ficha = orden.caracteristicas?.ficha;
                const clienteNombre = orden.cliente?.nombre_razon_social || (orden.cliente as any)?.nombre || '-';
                const proyecto = orden.cotizacion?.descripcion || ficha?.cabecera?.nombre_proyecto || '-';
                const equipo = ficha?.cantidad_texto || orden.caracteristicas?.descripcion_corta || 'Remolque';
                const fechaPedido = ficha?.cabecera?.fecha_pedido || (orden.cotizacion?.fecha ? new Date(orden.cotizacion.fecha).toLocaleDateString() : new Date(orden.created_at).toLocaleDateString());

                return (
                  <tr key={orden.id} className="border-b border-border/50 hover:bg-muted/50">
                    <td className="px-6 py-4 font-mono font-bold text-foreground">
                      {orden.nomenclatura_id}
                      {orden.niv && (
                        <div className="text-[11px] font-mono text-muted-foreground mt-0.5">
                          NIV: {orden.niv}
                        </div>
                      )}
                    </td>
                    <td className="px-6 py-4 text-foreground font-medium">{clienteNombre}</td>
                    <td className="px-6 py-4">{proyecto}</td>
                    <td className="px-6 py-4 text-foreground">{equipo}</td>
                    <td className="px-6 py-4">
                      <Badge variant="outline" className={
                        orden.estado === 'Terminado' ? 'bg-green-500/10 text-green-500 border-green-500/20' :
                        orden.estado === 'En Producción' ? 'bg-blue-500/10 text-blue-500 border-blue-500/20' :
                        orden.estado === 'Liberado' ? 'bg-purple-500/10 text-purple-500 border-purple-500/20' :
                        'bg-muted text-muted-foreground border-border'
                      }>
                        {orden.estado}
                      </Badge>
                    </td>
                    <td className="px-6 py-4 text-xs">{fechaPedido}</td>
                    <td className="px-6 py-4 text-right space-x-2">
                      <Button
                        variant="ghost"
                        size="icon"
                        onClick={() => navigate(`/plan-semanal?tab=trazabilidad&ordenId=${orden.id}`)}
                        title="Ver tareas de producción"
                      >
                        <Calendar className="w-4 h-4 text-primary" />
                      </Button>
                      <Button variant="ghost" size="icon" onClick={() => handleEdit(orden)} title="Editar datos">
                        <Edit className="w-4 h-4 text-blue-400" />
                      </Button>
                      <Button variant="ghost" size="icon" onClick={() => setOrdenParaPDF(orden)} title="Ver / Imprimir orden">
                        <Printer className="w-4 h-4 text-muted-foreground hover:text-foreground" />
                      </Button>
                    </td>
                  </tr>
                );
              })}
              {ordenesFiltradas.length === 0 && (
                <tr>
                  <td colSpan={7} className="px-6 py-12 text-center text-muted-foreground">
                    {loading ? 'Cargando órdenes de trabajo...' : 'No se encontraron órdenes de trabajo'}
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Modal Editor */}
      <Dialog open={!!ordenEditando} onOpenChange={(open) => !open && setOrdenEditando(null)}>
        <DialogContent className="bg-card border-border/50 text-foreground w-full max-w-lg max-h-[90vh] overflow-y-auto">
          <h2 className="text-xl font-bold mb-4">Editar Orden: {ordenEditando?.nomenclatura_id}</h2>
          <div className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <Label>NIV (Identificación Vehicular)</Label>
                <Input value={editNiv} onChange={e => setEditNiv(e.target.value)} className="bg-background uppercase font-mono" />
              </div>
              <div>
                <Label>Modelo (Año)</Label>
                <Input value={editModelo} onChange={e => setEditModelo(e.target.value)} className="bg-background" />
              </div>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <Label>Color de la unidad</Label>
                <Input value={editColor} onChange={e => setEditColor(e.target.value)} className="bg-background" />
              </div>
              <div>
                <Label>Estado de Producción</Label>
                <Select value={editEstado} onValueChange={setEditEstado}>
                  <SelectTrigger className="bg-background border-border">
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
            </div>

            <div className="border-t border-border pt-3 space-y-3">
              <h3 className="text-xs font-bold uppercase tracking-wider text-muted-foreground">Datos del formato impreso</h3>

              <div>
                <Label>Pedido recibido por</Label>
                <Input value={editPedidoRecibidoPor} onChange={e => setEditPedidoRecibidoPor(e.target.value)} className="bg-background" />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <Label>Fecha de inicio prevista</Label>
                  <Input value={editFechaInicioPrevista} onChange={e => setEditFechaInicioPrevista(e.target.value)} className="bg-background" placeholder="DD/MM/AA" />
                </div>
                <div>
                  <Label>Fecha finalización prevista</Label>
                  <Input value={editFechaFinPrevista} onChange={e => setEditFechaFinPrevista(e.target.value)} className="bg-background" placeholder="DD/MM/AA" />
                </div>
              </div>

              <div>
                <Label>Trabajo autorizado por</Label>
                <Input value={editTrabajoAutorizadoPor} onChange={e => setEditTrabajoAutorizadoPor(e.target.value)} className="bg-background" />
              </div>

              <div>
                <Label>Orden compilada por</Label>
                <Input value={editCompiladaPor} onChange={e => setEditCompiladaPor(e.target.value)} className="bg-background" />
              </div>

              <div>
                <Label>Nota / Observaciones (al pie de características)</Label>
                <Input value={editNota} onChange={e => setEditNota(e.target.value)} className="bg-background" placeholder="Ej. Redillas a 80 cm" />
              </div>
            </div>

            <Button onClick={handleSave} className="w-full bg-blue-600 hover:bg-blue-700 text-white mt-4">
              Guardar Cambios
            </Button>
          </div>
        </DialogContent>
      </Dialog>

      {/* Modal Visor de PDF (Orden Individual) */}
      <Dialog open={!!ordenParaPDF} onOpenChange={(open) => !open && setOrdenParaPDF(null)}>
        <DialogContent className="w-full sm:max-w-4xl max-h-[90vh] overflow-y-auto bg-card border-border p-6 print:hidden">
          <div className="flex justify-between items-center mb-4">
            <h2 className="text-lg font-bold text-foreground">Vista Previa de Orden de Trabajo</h2>
            <Button onClick={handlePrint} className="bg-primary text-primary-foreground hover:bg-primary/90">
              <Printer className="h-4 w-4 mr-2" /> Imprimir Orden
            </Button>
          </div>
          <div className="bg-white p-4 rounded shadow-xl overflow-x-auto">
            {ordenParaPDF && (
              <OrdenTrabajoPDF
                orden={ordenParaPDF}
                ajustes={ajustes}
                onRegenerarFicha={handleRegenerarFicha}
              />
            )}
          </div>
        </DialogContent>
      </Dialog>
    </div>
  );
}
