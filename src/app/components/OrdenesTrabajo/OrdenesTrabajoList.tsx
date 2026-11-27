import React, { useState, useEffect, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { OrdenTrabajo, Cliente } from '../../types';
import { Button } from '../ui/button';
import { Badge } from '../ui/badge';
import { Input } from '../ui/input';
import { Label } from '../ui/label';
import { Textarea } from '../ui/textarea';
import { Checkbox } from '../ui/checkbox';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription, DialogFooter } from '../ui/dialog';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../ui/select';
import {
  Printer,
  FileCheck,
  Search,
  Edit,
  Calendar,
  ClipboardCheck,
  AlertTriangle,
  FolderOpen,
  Ban,
  RotateCcw,
  UserCog,
  RefreshCw,
  Loader2,
  AlertCircle,
} from 'lucide-react';
import { toast } from 'sonner';
import { calidadApi } from '../Calidad/calidadApi';
import { avisosAlLiberar } from '../Calidad/calidadUtils';
import { OrdenTrabajoPDF } from './OrdenTrabajoPDF';
import { LiberacionPDF } from './LiberacionPDF';
import { ChecklistDespieceModal } from './ChecklistDespieceModal';
import { BASE_URL } from '../../utils/api';
import {
  listarOrdenesCanceladas,
  cancelarOrdenTrabajoApi,
  reactivarOrdenTrabajoApi,
  cambiarClienteOrdenTrabajoApi,
  formatearFechaPedidoMx,
  formatearFechaHoraMx,
  ErrorGestionEquipo,
} from '../../utils/equiposGestionApi';

interface OrdenesTrabajoListProps {
  ordenes: OrdenTrabajo[];
  clientes: Cliente[];
  loading: boolean;
  onActualizarOrden: (id: string, updates: Partial<OrdenTrabajo>) => Promise<any>;
  onRecargarOrdenes?: () => Promise<any>;
  session?: any;
  ajustes?: any;
}

export function OrdenesTrabajoList({
  ordenes,
  clientes,
  loading,
  onActualizarOrden,
  onRecargarOrdenes,
  session,
  ajustes,
}: OrdenesTrabajoListProps) {
  const navigate = useNavigate();
  const [searchTerm, setSearchTerm] = useState('');
  const [verCancelados, setVerCancelados] = useState(false);

  // Estado de equipos cancelados (sin .catch(() => []))
  const [ordenesCanceladas, setOrdenesCanceladas] = useState<OrdenTrabajo[]>([]);
  const [cargandoCanceladas, setCargandoCanceladas] = useState(false);
  const [errorCanceladas, setErrorCanceladas] = useState<string | null>(null);

  // Modales existentes
  const [ordenEditando, setOrdenEditando] = useState<OrdenTrabajo | null>(null);
  const [ordenParaPDF, setOrdenParaPDF] = useState<OrdenTrabajo | null>(null);
  const [ordenParaChecklist, setOrdenParaChecklist] = useState<OrdenTrabajo | null>(null);
  const [clienteLiberacion, setClienteLiberacion] = useState<string | null>(null);
  const [avisoLiberar, setAvisoLiberar] = useState<{
    mensajes: string[];
    payload: { id: string; data: Partial<OrdenTrabajo> };
  } | null>(null);

  // Modal Cancelar equipo
  const [ordenCancelando, setOrdenCancelando] = useState<OrdenTrabajo | null>(null);
  const [motivoCancelacion, setMotivoCancelacion] = useState('');
  const [confirmoMaterial, setConfirmoMaterial] = useState(false);
  const [avisoMaterial, setAvisoMaterial] = useState<{
    mensaje: string;
    entregas_count?: number;
    cantidad_total?: number;
  } | null>(null);
  const [errorCancelacion, setErrorCancelacion] = useState<string | null>(null);
  const [enviandoCancelacion, setEnviandoCancelacion] = useState(false);

  // Modal Reactivar equipo
  const [ordenReactivando, setOrdenReactivando] = useState<OrdenTrabajo | null>(null);
  const [motivoReactivacion, setMotivoReactivacion] = useState('');
  const [errorReactivacion, setErrorReactivacion] = useState<string | null>(null);
  const [enviandoReactivacion, setEnviandoReactivacion] = useState(false);

  // Modal Cambiar cliente (solo origen = 'manual')
  const [ordenCambiandoCliente, setOrdenCambiandoCliente] = useState<OrdenTrabajo | null>(null);
  const [nuevoClienteId, setNuevoClienteId] = useState<string>('__ninguno__');
  const [nuevaEtiqueta, setNuevaEtiqueta] = useState('');
  const [motivoCambioCliente, setMotivoCambioCliente] = useState('');
  const [errorCambioCliente, setErrorCambioCliente] = useState<string | null>(null);
  const [enviandoCambioCliente, setEnviandoCambioCliente] = useState(false);

  // Estados de edición básicos
  const [editNiv, setEditNiv] = useState('');
  const [editModelo, setEditModelo] = useState('');
  const [editColor, setEditColor] = useState('');
  const [editEstado, setEditEstado] = useState('');
  const [editFechaPedido, setEditFechaPedido] = useState('');
  const [guardandoEdicion, setGuardandoEdicion] = useState(false);

  // Estados de edición de cabecera y nota de la ficha
  const [editPedidoRecibidoPor, setEditPedidoRecibidoPor] = useState('');
  const [editFechaInicioPrevista, setEditFechaInicioPrevista] = useState('');
  const [editFechaFinPrevista, setEditFechaFinPrevista] = useState('');
  const [editTrabajoAutorizadoPor, setEditTrabajoAutorizadoPor] = useState('');
  const [editCompiladaPor, setEditCompiladaPor] = useState('');
  const [editNota, setEditNota] = useState('');

  const token = session?.access_token as string | undefined;

  const cargarCanceladas = useCallback(async () => {
    setCargandoCanceladas(true);
    setErrorCanceladas(null);
    try {
      const lista = await listarOrdenesCanceladas(token);
      setOrdenesCanceladas(lista);
    } catch (err: any) {
      setErrorCanceladas(err?.message || 'No se pudieron cargar los equipos cancelados.');
    } finally {
      setCargandoCanceladas(false);
    }
  }, [token]);

  useEffect(() => {
    if (verCancelados) {
      cargarCanceladas();
    }
  }, [verCancelados, cargarCanceladas]);

  const listaBase = verCancelados
    ? ordenesCanceladas
    : ordenes.filter((o) => !o.cancelada_el);

  const ordenesFiltradas = listaBase.filter((o) => {
    const query = searchTerm.toLowerCase();
    const nom = (o.nomenclatura_id || '').toLowerCase();
    const niv = (o.niv || '').toLowerCase();
    const cli = (o.cliente?.nombre_razon_social || (o.cliente as any)?.nombre || o.etiqueta || '').toLowerCase();
    const proy = (o.cotizacion?.descripcion || o.caracteristicas?.ficha?.cabecera?.nombre_proyecto || (o.origen === 'manual' ? 'manual' : '')).toLowerCase();
    const etiq = (o.etiqueta || '').toLowerCase();
    const mot = (o.motivo_cancelacion || '').toLowerCase();
    return nom.includes(query) || niv.includes(query) || cli.includes(query) || proy.includes(query) || etiq.includes(query) || mot.includes(query);
  });

  const handleEdit = (orden: OrdenTrabajo) => {
    setOrdenEditando(orden);
    setEditNiv(orden.niv || '');
    setEditModelo(orden.modelo || '');
    setEditEstado(orden.estado || 'Pendiente');
    setEditFechaPedido(orden.fecha_pedido ? orden.fecha_pedido.slice(0, 10) : '');

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
    if (!ordenEditando || guardandoEdicion) return;

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
        compilada_por: editCompiladaPor,
      },
      caracteristicas: nuevasCarFicha,
      nota: editNota,
    };

    const payloadUpdate: Partial<OrdenTrabajo> = {
      niv: editNiv,
      modelo: editModelo,
      estado: editEstado,
      fecha_pedido: editFechaPedido || null,
      caracteristicas: {
        ...carActuales,
        color: editColor,
        ficha: nuevaFicha,
      },
    };

    if (editEstado === 'Liberado' && ordenEditando.estado !== 'Liberado') {
      try {
        const insps = await calidadApi.listarInspecciones({ orden_trabajo_id: ordenEditando.id });
        const mensajes = avisosAlLiberar(insps || []);
        if (mensajes.length > 0) {
          setAvisoLiberar({
            mensajes,
            payload: { id: ordenEditando.id, data: payloadUpdate },
          });
          return;
        }
      } catch {
        // Si falla la consulta de calidad, no bloqueamos la liberación
      }
    }

    try {
      setGuardandoEdicion(true);
      await onActualizarOrden(ordenEditando.id, payloadUpdate);
      setOrdenEditando(null);
    } finally {
      setGuardandoEdicion(false);
    }
  };

  const abrirModalCancelar = (orden: OrdenTrabajo) => {
    setOrdenCancelando(orden);
    setMotivoCancelacion('');
    setConfirmoMaterial(false);
    setAvisoMaterial(null);
    setErrorCancelacion(null);
  };

  const ejecutarCancelacion = async () => {
    if (!ordenCancelando || enviandoCancelacion) return;
    const motivoLimpio = motivoCancelacion.trim();
    if (!motivoLimpio) {
      setErrorCancelacion('El motivo de cancelación es obligatorio.');
      return;
    }
    if (avisoMaterial && !confirmoMaterial) {
      setErrorCancelacion('Marca la casilla de confirmación para cancelar con material entregado.');
      return;
    }

    setEnviandoCancelacion(true);
    setErrorCancelacion(null);
    try {
      await cancelarOrdenTrabajoApi(
        ordenCancelando.id,
        {
          motivo: motivoLimpio,
          confirmo_material_entregado: confirmoMaterial,
        },
        token
      );
      toast.success(`Equipo ${ordenCancelando.nomenclatura_id} cancelado`);
      setOrdenCancelando(null);
      if (onRecargarOrdenes) await onRecargarOrdenes();
      if (verCancelados) await cargarCanceladas();
    } catch (err: any) {
      const e = err as ErrorGestionEquipo;
      if (e.codigo === 'orden_con_material_entregado') {
        setAvisoMaterial({
          mensaje: e.message,
          entregas_count: e.detalle?.entregas_count,
          cantidad_total: e.detalle?.cantidad_total,
        });
        setErrorCancelacion(null);
      } else {
        setErrorCancelacion(e.message || 'No se pudo cancelar el equipo.');
      }
    } finally {
      setEnviandoCancelacion(false);
    }
  };

  const abrirModalReactivar = (orden: OrdenTrabajo) => {
    setOrdenReactivando(orden);
    setMotivoReactivacion('');
    setErrorReactivacion(null);
  };

  const ejecutarReactivacion = async () => {
    if (!ordenReactivando || enviandoReactivacion) return;
    setEnviandoReactivacion(true);
    setErrorReactivacion(null);
    try {
      await reactivarOrdenTrabajoApi(
        ordenReactivando.id,
        { motivo: motivoReactivacion.trim() || null },
        token
      );
      toast.success(`Equipo ${ordenReactivando.nomenclatura_id} reactivado`);
      setOrdenReactivando(null);
      await cargarCanceladas();
      if (onRecargarOrdenes) await onRecargarOrdenes();
    } catch (err: any) {
      setErrorReactivacion(err?.message || 'No se pudo reactivar el equipo.');
    } finally {
      setEnviandoReactivacion(false);
    }
  };

  const abrirModalCambiarCliente = (orden: OrdenTrabajo) => {
    setOrdenCambiandoCliente(orden);
    setNuevoClienteId(orden.cliente_id || '__ninguno__');
    setNuevaEtiqueta(orden.etiqueta || '');
    setMotivoCambioCliente('');
    setErrorCambioCliente(null);
  };

  const ejecutarCambioCliente = async () => {
    if (!ordenCambiandoCliente || enviandoCambioCliente) return;
    const clienteFinal = nuevoClienteId === '__ninguno__' ? null : nuevoClienteId;
    const etiquetaFinal = nuevaEtiqueta.trim() || null;

    if (!clienteFinal && !etiquetaFinal) {
      setErrorCambioCliente('Debes seleccionar un cliente del catálogo o capturar una etiqueta.');
      return;
    }

    setEnviandoCambioCliente(true);
    setErrorCambioCliente(null);
    try {
      await cambiarClienteOrdenTrabajoApi(
        ordenCambiandoCliente.id,
        {
          cliente_id: clienteFinal,
          etiqueta: etiquetaFinal,
          motivo: motivoCambioCliente.trim() || null,
        },
        token
      );
      toast.success(`Cliente actualizado en ${ordenCambiandoCliente.nomenclatura_id}`);
      setOrdenCambiandoCliente(null);
      if (onRecargarOrdenes) await onRecargarOrdenes();
    } catch (err: any) {
      setErrorCambioCliente(err?.message || 'No se pudo cambiar el cliente del equipo.');
    } finally {
      setEnviandoCambioCliente(false);
    }
  };

  const handleRegenerarFicha = async (id: string) => {
    const res = await fetch(`${BASE_URL}/ordenes-trabajo/${id}/regenerar-ficha`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
      },
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
    ? ordenes.filter((o) => !o.cancelada_el && o.cliente_id === clienteLiberacion && o.estado === 'Terminado')
    : [];

  return (
    <div className="space-y-6 pb-20 print:pb-0">
      <div className="flex flex-col gap-4 md:flex-row md:justify-between md:items-center print:hidden">
        <div>
          <h1 className="text-3xl font-bold text-foreground mb-1">Órdenes de Trabajo</h1>
          <p className="text-muted-foreground">Control de producción y formato oficial de remolque</p>
        </div>
        <div className="flex flex-wrap items-center gap-3">
          <Button
            type="button"
            variant={verCancelados ? 'destructive' : 'outline'}
            onClick={() => setVerCancelados((prev) => !prev)}
            data-testid="toggle-ver-cancelados"
            className="gap-2"
          >
            <Ban className="w-4 h-4" />
            {verCancelados ? 'Ver activos' : 'Ver cancelados'}
          </Button>
          {!verCancelados && (
            <>
              <Select value={clienteLiberacion || ''} onValueChange={setClienteLiberacion}>
                <SelectTrigger className="w-56 bg-card border-border">
                  <SelectValue placeholder="Liberar equipos por cliente..." />
                </SelectTrigger>
                <SelectContent>
                  {clientes.map((c) => (
                    <SelectItem key={c.id} value={c.id}>
                      {c.nombre_razon_social || (c as any).nombre}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
              <Button
                disabled={!clienteLiberacion || ordenesParaLiberar.length === 0}
                onClick={() => window.print()}
                className="bg-emerald-600 hover:bg-emerald-700 text-white gap-2"
              >
                <FileCheck className="w-4 h-4" />
                Imprimir Liberación ({ordenesParaLiberar.length})
              </Button>
            </>
          )}
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
        <div className="p-4 border-b border-border flex flex-col sm:flex-row gap-3 sm:items-center sm:justify-between">
          <div className="relative flex-1">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-muted-foreground" />
            <Input
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              placeholder={
                verCancelados
                  ? 'Buscar en cancelados por Nomenclatura, Cliente o Motivo...'
                  : 'Buscar por Nomenclatura, Cliente, Proyecto o NIV...'
              }
              className="pl-10 bg-background border-border text-foreground"
            />
          </div>
          {verCancelados && (
            <Badge variant="outline" className="bg-destructive/10 text-destructive border-destructive/30 self-start sm:self-center">
              Equipos cancelados ({ordenesCanceladas.length})
            </Badge>
          )}
        </div>

        {verCancelados && errorCanceladas ? (
          <div className="p-8 text-center space-y-3">
            <div className="inline-flex items-center gap-2 text-destructive font-medium">
              <AlertCircle className="w-5 h-5" />
              <span>{errorCanceladas}</span>
            </div>
            <div>
              <Button type="button" variant="outline" onClick={cargarCanceladas} className="gap-2">
                <RefreshCw className="w-4 h-4" />
                Reintentar
              </Button>
            </div>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm text-left text-muted-foreground">
              <thead className="text-xs text-muted-foreground uppercase bg-muted/50">
                {verCancelados ? (
                  <tr>
                    <th className="px-6 py-3">ID / Nomenclatura</th>
                    <th className="px-6 py-3">Cliente / Etiqueta</th>
                    <th className="px-6 py-3">Estado previo</th>
                    <th className="px-6 py-3">Motivo de cancelación</th>
                    <th className="px-6 py-3">Cancelado por</th>
                    <th className="px-6 py-3">Cuándo</th>
                    <th className="px-6 py-3 text-right">Acciones</th>
                  </tr>
                ) : (
                  <tr>
                    <th className="px-6 py-3">ID / Nomenclatura</th>
                    <th className="px-6 py-3">Cliente</th>
                    <th className="px-6 py-3">Proyecto</th>
                    <th className="px-6 py-3">Equipo</th>
                    <th className="px-6 py-3">Estado</th>
                    <th className="px-6 py-3">Fecha Pedido</th>
                    <th className="px-6 py-3 text-right">Acciones</th>
                  </tr>
                )}
              </thead>
              <tbody>
                {ordenesFiltradas.map((orden) => {
                  const ficha = orden.caracteristicas?.ficha;
                  const clienteNombre =
                    orden.cliente?.nombre_razon_social ||
                    (orden.cliente as any)?.nombre ||
                    orden.etiqueta ||
                    (orden.origen === 'manual' ? 'Inventario' : '-');
                  const proyecto =
                    orden.cotizacion?.descripcion ||
                    ficha?.cabecera?.nombre_proyecto ||
                    (orden.origen === 'manual' ? 'Manual' : '-');
                  const equipo =
                    orden.modelo ||
                    ficha?.cantidad_texto ||
                    orden.caracteristicas?.descripcion_corta ||
                    'Remolque';
                  const fechaPedidoTexto = orden.fecha_pedido
                    ? formatearFechaPedidoMx(orden.fecha_pedido)
                    : ficha?.cabecera?.fecha_pedido ||
                      (orden.cotizacion?.fecha
                        ? formatearFechaPedidoMx(orden.cotizacion.fecha)
                        : '—');

                  if (verCancelados) {
                    return (
                      <tr key={orden.id} className="border-b border-border/50 hover:bg-muted/50">
                        <td className="px-6 py-4 font-mono font-bold text-foreground">
                          {orden.nomenclatura_id}
                        </td>
                        <td className="px-6 py-4 text-foreground font-medium">
                          {clienteNombre}
                          {orden.modelo && (
                            <div className="text-xs text-muted-foreground">{orden.modelo}</div>
                          )}
                        </td>
                        <td className="px-6 py-4">
                          <Badge variant="outline" className="bg-muted text-muted-foreground border-border">
                            {orden.estado}
                          </Badge>
                        </td>
                        <td className="px-6 py-4 text-foreground max-w-xs">
                          {orden.motivo_cancelacion || '—'}
                        </td>
                        <td className="px-6 py-4 text-xs text-foreground">
                          {orden.cancelada_por_nombre || orden.cancelada_por || '—'}
                        </td>
                        <td className="px-6 py-4 text-xs">
                          {formatearFechaHoraMx(orden.cancelada_el)}
                        </td>
                        <td className="px-6 py-4 text-right">
                          <Button
                            type="button"
                            size="sm"
                            variant="outline"
                            onClick={() => abrirModalReactivar(orden)}
                            className="gap-1.5 border-emerald-500/40 text-emerald-600 dark:text-emerald-400 hover:bg-emerald-500/10"
                          >
                            <RotateCcw className="w-3.5 h-3.5" />
                            Reactivar
                          </Button>
                        </td>
                      </tr>
                    );
                  }

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
                      <td className="px-6 py-4 text-foreground font-medium">
                        {clienteNombre}
                        {orden.origen === 'manual' && (
                          <div className="text-[11px] text-muted-foreground">Equipo manual</div>
                        )}
                      </td>
                      <td className="px-6 py-4">{proyecto}</td>
                      <td className="px-6 py-4 text-foreground">{equipo}</td>
                      <td className="px-6 py-4">
                        <Badge
                          variant="outline"
                          className={
                            orden.estado === 'Terminado'
                              ? 'bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border-emerald-500/20'
                              : orden.estado === 'En Producción'
                              ? 'bg-blue-500/10 text-blue-600 dark:text-blue-400 border-blue-500/20'
                              : orden.estado === 'Liberado'
                              ? 'bg-purple-500/10 text-purple-600 dark:text-purple-400 border-purple-500/20'
                              : 'bg-muted text-muted-foreground border-border'
                          }
                        >
                          {orden.estado}
                        </Badge>
                      </td>
                      <td className="px-6 py-4 text-xs text-foreground">{fechaPedidoTexto}</td>
                      <td className="px-6 py-4 text-right whitespace-nowrap space-x-1">
                        <Button
                          variant="ghost"
                          size="icon"
                          onClick={() => navigate(`/expediente/${orden.id}`)}
                          title="Abrir expediente del equipo"
                        >
                          <FolderOpen className="w-4 h-4 text-primary" />
                        </Button>
                        <Button
                          variant="ghost"
                          size="icon"
                          onClick={() => navigate(`/plan-semanal?tab=trazabilidad&ordenId=${orden.id}`)}
                          title="Ver tareas de producción"
                        >
                          <Calendar className="w-4 h-4 text-primary" />
                        </Button>
                        <Button
                          variant="ghost"
                          size="icon"
                          onClick={() => setOrdenParaChecklist(orden)}
                          title="Checklist de almacén / despiece"
                        >
                          <ClipboardCheck className="w-4 h-4 text-emerald-500" />
                        </Button>
                        {orden.origen === 'manual' && (
                          <Button
                            variant="ghost"
                            size="icon"
                            onClick={() => abrirModalCambiarCliente(orden)}
                            title="Cambiar cliente del equipo manual"
                            aria-label={`Cambiar cliente ${orden.nomenclatura_id}`}
                          >
                            <UserCog className="w-4 h-4 text-amber-500" />
                          </Button>
                        )}
                        <Button
                          variant="ghost"
                          size="icon"
                          onClick={() => handleEdit(orden)}
                          title="Editar datos"
                        >
                          <Edit className="w-4 h-4 text-blue-500" />
                        </Button>
                        <Button
                          variant="ghost"
                          size="icon"
                          onClick={() => setOrdenParaPDF(orden)}
                          title="Ver / Imprimir orden"
                        >
                          <Printer className="w-4 h-4 text-muted-foreground hover:text-foreground" />
                        </Button>
                        <Button
                          variant="ghost"
                          size="icon"
                          onClick={() => abrirModalCancelar(orden)}
                          title="Cancelar equipo"
                          aria-label={`Cancelar ${orden.nomenclatura_id}`}
                        >
                          <Ban className="w-4 h-4 text-destructive" />
                        </Button>
                      </td>
                    </tr>
                  );
                })}
                {ordenesFiltradas.length === 0 && (
                  <tr>
                    <td colSpan={7} className="px-6 py-12 text-center text-muted-foreground">
                      {verCancelados
                        ? cargandoCanceladas
                          ? 'Cargando equipos cancelados...'
                          : 'No hay equipos cancelados'
                        : loading
                        ? 'Cargando órdenes de trabajo...'
                        : 'No se encontraron órdenes de trabajo'}
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Modal Editor */}
      <Dialog open={!!ordenEditando} onOpenChange={(open) => !open && setOrdenEditando(null)}>
        <DialogContent className="bg-card border-border/50 text-foreground w-full max-w-lg max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>Editar Orden: {ordenEditando?.nomenclatura_id}</DialogTitle>
            <DialogDescription>
              Actualiza identificación, estado, fecha de pedido y datos del formato impreso.
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <Label>NIV (Identificación Vehicular)</Label>
                <Input
                  value={editNiv}
                  onChange={(e) => setEditNiv(e.target.value)}
                  className="bg-background uppercase font-mono"
                />
              </div>
              <div>
                <Label>Modelo (Año)</Label>
                <Input
                  value={editModelo}
                  onChange={(e) => setEditModelo(e.target.value)}
                  className="bg-background"
                />
              </div>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <Label>Fecha de pedido</Label>
                <Input
                  type="date"
                  value={editFechaPedido}
                  onChange={(e) => setEditFechaPedido(e.target.value)}
                  className="bg-background"
                />
              </div>
              <div>
                <Label>Color de la unidad</Label>
                <Input
                  value={editColor}
                  onChange={(e) => setEditColor(e.target.value)}
                  className="bg-background"
                />
              </div>
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

            <div className="border-t border-border pt-3 space-y-3">
              <h3 className="text-xs font-bold uppercase tracking-wider text-muted-foreground">
                Datos del formato impreso
              </h3>

              <div>
                <Label>Pedido recibido por</Label>
                <Input
                  value={editPedidoRecibidoPor}
                  onChange={(e) => setEditPedidoRecibidoPor(e.target.value)}
                  className="bg-background"
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <Label>Fecha de inicio prevista</Label>
                  <Input
                    value={editFechaInicioPrevista}
                    onChange={(e) => setEditFechaInicioPrevista(e.target.value)}
                    className="bg-background"
                    placeholder="DD/MM/AA"
                  />
                </div>
                <div>
                  <Label>Fecha finalización prevista</Label>
                  <Input
                    value={editFechaFinPrevista}
                    onChange={(e) => setEditFechaFinPrevista(e.target.value)}
                    className="bg-background"
                    placeholder="DD/MM/AA"
                  />
                </div>
              </div>

              <div>
                <Label>Trabajo autorizado por</Label>
                <Input
                  value={editTrabajoAutorizadoPor}
                  onChange={(e) => setEditTrabajoAutorizadoPor(e.target.value)}
                  className="bg-background"
                />
              </div>

              <div>
                <Label>Orden compilada por</Label>
                <Input
                  value={editCompiladaPor}
                  onChange={(e) => setEditCompiladaPor(e.target.value)}
                  className="bg-background"
                />
              </div>

              <div>
                <Label>Nota / Observaciones (al pie de características)</Label>
                <Input
                  value={editNota}
                  onChange={(e) => setEditNota(e.target.value)}
                  className="bg-background"
                  placeholder="Ej. Redillas a 80 cm"
                />
              </div>
            </div>

            <Button
              onClick={handleSave}
              disabled={guardandoEdicion}
              className="w-full bg-primary text-primary-foreground hover:bg-primary/90 mt-4"
            >
              {guardandoEdicion ? 'Guardando...' : 'Guardar Cambios'}
            </Button>
          </div>
        </DialogContent>
      </Dialog>

      {/* Modal Cancelar Equipo */}
      <Dialog
        open={!!ordenCancelando}
        onOpenChange={(open) => {
          if (!open && !enviandoCancelacion) setOrdenCancelando(null);
        }}
      >
        <DialogContent className="bg-card border-border text-foreground max-w-md">
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2 text-destructive">
              <Ban className="w-5 h-5" />
              Cancelar equipo {ordenCancelando?.nomenclatura_id}
            </DialogTitle>
            <DialogDescription>
              El equipo no se borra: se ocultará de producción, almacén, calidad y cobranza, y podrás reactivarlo después desde &quot;Ver cancelados&quot;.
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-4">
            <div className="space-y-1.5">
              <Label htmlFor="motivo-cancelacion-equipo">Motivo de cancelación *</Label>
              <Textarea
                id="motivo-cancelacion-equipo"
                value={motivoCancelacion}
                onChange={(e) => setMotivoCancelacion(e.target.value)}
                placeholder="Ej. Error de captura en línea o cancelación del cliente"
                rows={3}
                className="bg-background border-border"
                disabled={enviandoCancelacion}
              />
            </div>

            {avisoMaterial && (
              <div className="p-3 rounded-lg bg-amber-500/10 border border-amber-500/30 space-y-2.5 text-sm">
                <div className="flex items-start gap-2 text-amber-700 dark:text-amber-300 font-medium">
                  <AlertTriangle className="w-4 h-4 shrink-0 mt-0.5" />
                  <span>{avisoMaterial.mensaje}</span>
                </div>
                <label className="flex items-start gap-2 text-xs text-foreground cursor-pointer">
                  <Checkbox
                    checked={confirmoMaterial}
                    onCheckedChange={(v) => setConfirmoMaterial(Boolean(v))}
                    disabled={enviandoCancelacion}
                  />
                  <span>
                    Confirmo que deseo cancelar este equipo con material entregado (el stock no se devolverá automáticamente).
                  </span>
                </label>
              </div>
            )}

            {errorCancelacion && (
              <div className="p-3 rounded-lg bg-destructive/10 border border-destructive/30 text-sm text-destructive flex items-start justify-between gap-2">
                <div className="flex items-start gap-2">
                  <AlertCircle className="w-4 h-4 shrink-0 mt-0.5" />
                  <span>{errorCancelacion}</span>
                </div>
                <Button
                  type="button"
                  size="sm"
                  variant="outline"
                  onClick={ejecutarCancelacion}
                  disabled={enviandoCancelacion}
                  className="shrink-0 gap-1"
                >
                  <RefreshCw className="w-3.5 h-3.5" />
                  Reintentar
                </Button>
              </div>
            )}
          </div>

          <DialogFooter className="gap-2">
            <Button
              type="button"
              variant="outline"
              onClick={() => setOrdenCancelando(null)}
              disabled={enviandoCancelacion}
            >
              Volver
            </Button>
            <Button
              type="button"
              variant="destructive"
              onClick={ejecutarCancelacion}
              disabled={enviandoCancelacion || (Boolean(avisoMaterial) && !confirmoMaterial)}
              className="gap-2"
            >
              {enviandoCancelacion ? (
                <>
                  <Loader2 className="w-4 h-4 animate-spin" />
                  Cancelando...
                </>
              ) : (
                <>
                  <Ban className="w-4 h-4" />
                  {avisoMaterial ? 'Confirmar cancelación' : 'Cancelar equipo'}
                </>
              )}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Modal Reactivar Equipo */}
      <Dialog
        open={!!ordenReactivando}
        onOpenChange={(open) => {
          if (!open && !enviandoReactivacion) setOrdenReactivando(null);
        }}
      >
        <DialogContent className="bg-card border-border text-foreground max-w-md">
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2">
              <RotateCcw className="w-5 h-5 text-emerald-600" />
              Reactivar equipo {ordenReactivando?.nomenclatura_id}
            </DialogTitle>
            <DialogDescription>
              El equipo volverá exactamente a su estado previo ({ordenReactivando?.estado}) conservando sus fases e historial.
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-4">
            <div className="space-y-1.5">
              <Label htmlFor="motivo-reactivacion-equipo">Nota / motivo (opcional)</Label>
              <Input
                id="motivo-reactivacion-equipo"
                value={motivoReactivacion}
                onChange={(e) => setMotivoReactivacion(e.target.value)}
                placeholder="Ej. Cliente confirmó continuación del pedido"
                className="bg-background border-border"
                disabled={enviandoReactivacion}
              />
            </div>

            {errorReactivacion && (
              <div className="p-3 rounded-lg bg-destructive/10 border border-destructive/30 text-sm text-destructive flex items-start justify-between gap-2">
                <div className="flex items-start gap-2">
                  <AlertCircle className="w-4 h-4 shrink-0 mt-0.5" />
                  <span>{errorReactivacion}</span>
                </div>
                <Button
                  type="button"
                  size="sm"
                  variant="outline"
                  onClick={ejecutarReactivacion}
                  disabled={enviandoReactivacion}
                  className="shrink-0 gap-1"
                >
                  <RefreshCw className="w-3.5 h-3.5" />
                  Reintentar
                </Button>
              </div>
            )}
          </div>

          <DialogFooter className="gap-2">
            <Button
              type="button"
              variant="outline"
              onClick={() => setOrdenReactivando(null)}
              disabled={enviandoReactivacion}
            >
              Cancelar
            </Button>
            <Button
              type="button"
              onClick={ejecutarReactivacion}
              disabled={enviandoReactivacion}
              className="gap-2 bg-emerald-600 hover:bg-emerald-700 text-white"
            >
              {enviandoReactivacion ? (
                <>
                  <Loader2 className="w-4 h-4 animate-spin" />
                  Reactivando...
                </>
              ) : (
                <>
                  <RotateCcw className="w-4 h-4" />
                  Confirmar reactivación
                </>
              )}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Modal Cambiar Cliente (equipos manuales) */}
      <Dialog
        open={!!ordenCambiandoCliente}
        onOpenChange={(open) => {
          if (!open && !enviandoCambioCliente) setOrdenCambiandoCliente(null);
        }}
      >
        <DialogContent className="bg-card border-border text-foreground max-w-md">
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2">
              <UserCog className="w-5 h-5 text-amber-500" />
              Cambiar cliente — {ordenCambiandoCliente?.nomenclatura_id}
            </DialogTitle>
            <DialogDescription>
              Disponible solo para equipos manuales. El folio del equipo no cambia y el movimiento queda registrado en bitácora.
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-4">
            <div className="space-y-1.5">
              <Label>Cliente del catálogo</Label>
              <Select
                value={nuevoClienteId}
                onValueChange={setNuevoClienteId}
                disabled={enviandoCambioCliente}
              >
                <SelectTrigger className="bg-background border-border">
                  <SelectValue placeholder="Selecciona un cliente..." />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="__ninguno__">Sin cliente (usar etiqueta)</SelectItem>
                  {clientes.map((c) => (
                    <SelectItem key={c.id} value={c.id}>
                      {c.nombre_razon_social || (c as any).nombre}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            <div className="space-y-1.5">
              <Label htmlFor="etiqueta-cambio-cliente">
                Etiqueta {nuevoClienteId === '__ninguno__' ? '*' : '(opcional)'}
              </Label>
              <Input
                id="etiqueta-cambio-cliente"
                value={nuevaEtiqueta}
                onChange={(e) => setNuevaEtiqueta(e.target.value)}
                placeholder="Ej. Stock planta / Cliente por asignar"
                className="bg-background border-border"
                disabled={enviandoCambioCliente}
              />
            </div>

            <div className="space-y-1.5">
              <Label htmlFor="motivo-cambio-cliente">Motivo del cambio (opcional)</Label>
              <Input
                id="motivo-cambio-cliente"
                value={motivoCambioCliente}
                onChange={(e) => setMotivoCambioCliente(e.target.value)}
                placeholder="Ej. Reasignación de unidad de inventario a cliente"
                className="bg-background border-border"
                disabled={enviandoCambioCliente}
              />
            </div>

            {errorCambioCliente && (
              <div className="p-3 rounded-lg bg-destructive/10 border border-destructive/30 text-sm text-destructive flex items-start justify-between gap-2">
                <div className="flex items-start gap-2">
                  <AlertCircle className="w-4 h-4 shrink-0 mt-0.5" />
                  <span>{errorCambioCliente}</span>
                </div>
                <Button
                  type="button"
                  size="sm"
                  variant="outline"
                  onClick={ejecutarCambioCliente}
                  disabled={enviandoCambioCliente}
                  className="shrink-0 gap-1"
                >
                  <RefreshCw className="w-3.5 h-3.5" />
                  Reintentar
                </Button>
              </div>
            )}
          </div>

          <DialogFooter className="gap-2">
            <Button
              type="button"
              variant="outline"
              onClick={() => setOrdenCambiandoCliente(null)}
              disabled={enviandoCambioCliente}
            >
              Cancelar
            </Button>
            <Button
              type="button"
              onClick={ejecutarCambioCliente}
              disabled={enviandoCambioCliente}
              className="gap-2"
            >
              {enviandoCambioCliente ? (
                <>
                  <Loader2 className="w-4 h-4 animate-spin" />
                  Guardando...
                </>
              ) : (
                <>
                  <UserCog className="w-4 h-4" />
                  Guardar cliente
                </>
              )}
            </Button>
          </DialogFooter>
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

      {/* Modal de Checklist y Entregas de Almacén */}
      <ChecklistDespieceModal
        orden={ordenParaChecklist}
        open={!!ordenParaChecklist}
        onOpenChange={(o) => !o && setOrdenParaChecklist(null)}
      />

      {/* Aviso no bloqueante de Calidad al liberar */}
      <Dialog open={Boolean(avisoLiberar)} onOpenChange={(o) => { if (!o) setAvisoLiberar(null); }}>
        <DialogContent className="max-w-md bg-card border-border">
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2">
              <AlertTriangle className="h-5 w-5 text-amber-600" />
              Aviso de calidad antes de liberar
            </DialogTitle>
            <DialogDescription>
              Puedes continuar con la liberación de todos modos; estas observaciones son solo informativas:
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-2 text-sm">
            {avisoLiberar?.mensajes.map((m, i) => (
              <div key={i} className="p-2.5 rounded-md bg-amber-500/10 border border-amber-500/30 text-foreground">
                {m}
              </div>
            ))}
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setAvisoLiberar(null)}>
              Cancelar
            </Button>
            <Button
              onClick={async () => {
                if (!avisoLiberar) return;
                await onActualizarOrden(avisoLiberar.payload.id, avisoLiberar.payload.data);
                setAvisoLiberar(null);
                setOrdenEditando(null);
              }}
            >
              Continuar de todos modos
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
