import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { FilaMatriz, HistorialFaseItem, fetchHistorialOrden } from '../../utils/tableroApi';
import {
  formatearFechaCorta,
  formatearTiempoRelativo,
  formatearEstadoHistorial,
  formatearUsuarioHistorial,
  formatearFaseHistorial,
  EstadoFase,
} from '../../utils/tableroProduccion';
import {
  Sheet,
  SheetContent,
  SheetHeader,
  SheetTitle,
  SheetDescription,
} from '../ui/sheet';
import { Button } from '../ui/button';
import { Input } from '../ui/input';
import { Textarea } from '../ui/textarea';
import { Badge } from '../ui/badge';
import {
  Clock,
  Calendar,
  User,
  AlertTriangle,
  ExternalLink,
  Save,
  Layers,
  History,
  CheckCircle2,
  PlayCircle,
  PauseCircle,
  PackageX,
  RotateCcw,
} from 'lucide-react';
import { toast } from 'sonner';
import { cn } from '../ui/utils';

interface OrdenTrabajoDetalleSheetProps {
  fila: FilaMatriz | null;
  open: boolean;
  onOpenChange: (open: boolean) => void;
  token?: string;
  onGuardarPlaneacion: (
    ordenId: string,
    cambios: {
      fecha_compromiso?: string | null;
      etiqueta?: string | null;
      material_faltante?: string | null;
    }
  ) => Promise<void>;
}

export function OrdenTrabajoDetalleSheet({
  fila,
  open,
  onOpenChange,
  token,
  onGuardarPlaneacion,
}: OrdenTrabajoDetalleSheetProps) {
  const navigate = useNavigate();

  // Estados locales para edición
  const [etiqueta, setEtiqueta] = useState('');
  const [fechaCompromiso, setFechaCompromiso] = useState('');
  const [materialFaltante, setMaterialFaltante] = useState('');
  const [guardando, setGuardando] = useState(false);

  // Historial
  const [historial, setHistorial] = useState<HistorialFaseItem[]>([]);
  const [cargandoHistorial, setCargandoHistorial] = useState(false);

  useEffect(() => {
    if (fila && open) {
      setEtiqueta(fila.etiqueta || '');
      setFechaCompromiso(fila.fecha_compromiso ? fila.fecha_compromiso.slice(0, 10) : '');
      setMaterialFaltante(fila.material_faltante || '');

      // Cargar historial
      setCargandoHistorial(true);
      fetchHistorialOrden(fila.orden_id, token)
        .then((res) => {
          setHistorial(res.historial || []);
        })
        .catch((err) => {
          console.error('[OrdenTrabajoDetalleSheet] Error cargando historial:', err);
          toast.error('Error al cargar historial', { description: err.message });
        })
        .finally(() => setCargandoHistorial(false));
    }
  }, [fila, open, token]);

  if (!fila) return null;

  const handleGuardarCambios = async () => {
    try {
      setGuardando(true);
      await onGuardarPlaneacion(fila.orden_id, {
        etiqueta: etiqueta.trim() || fila.etiqueta,
        fecha_compromiso: fechaCompromiso || null,
        material_faltante: materialFaltante.trim() || null,
      });
      toast.success('Planeación actualizada');
    } catch (err: any) {
      toast.error('Error al guardar planeación', { description: err.message });
    } finally {
      setGuardando(false);
    }
  };

  const irATareasProduccion = () => {
    onOpenChange(false);
    navigate(`/plan-semanal?tab=trazabilidad&ordenId=${fila.orden_id}`);
  };

  const renderIconoEstado = (estado: string) => {
    switch (estado) {
      case 'terminada':
        return <CheckCircle2 className="w-4 h-4 text-emerald-500" />;
      case 'en_proceso':
        return <PlayCircle className="w-4 h-4 text-primary" />;
      case 'incompleta':
        return <PackageX className="w-4 h-4 text-destructive" />;
      case 'pausada':
        return <PauseCircle className="w-4 h-4 text-amber-500" />;
      default:
        return <RotateCcw className="w-4 h-4 text-muted-foreground" />;
    }
  };

  return (
    <Sheet open={open} onOpenChange={onOpenChange}>
      <SheetContent
        side="right"
        className="w-full sm:max-w-lg overflow-y-auto bg-card text-card-foreground border-l border-border p-6"
      >
        <SheetHeader className="pb-4 border-b border-border/60">
          <div className="flex items-center justify-between gap-2">
            <SheetTitle className="text-lg font-bold text-foreground">
              Detalle del equipo
            </SheetTitle>
            <Badge
              variant="outline"
              className={cn(
                'capitalize text-xs font-semibold',
                fila.semaforo === 'atrasado' && 'bg-destructive/10 text-destructive border-destructive/30',
                fila.semaforo === 'por_vencer' && 'bg-amber-500/10 text-amber-600 dark:text-amber-400 border-amber-500/30',
                fila.semaforo === 'en_tiempo' && 'bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border-emerald-500/30'
              )}
            >
              {fila.semaforo.replace('_', ' ')}
            </Badge>
          </div>
          <SheetDescription className="text-xs text-muted-foreground">
            Consulta la información técnica, planeación e historial de cambios de fase.
          </SheetDescription>
        </SheetHeader>

        <div className="space-y-6 pt-4">
          {/* ACCIÓN RÁPIDA: VER TAREAS DE PRODUCCIÓN */}
          <Button
            type="button"
            variant="outline"
            className="w-full justify-between text-xs h-9 border-primary/30 hover:bg-primary/5 hover:text-primary text-foreground"
            onClick={irATareasProduccion}
          >
            <span className="font-semibold">Ver tareas de producción</span>
            <ExternalLink className="w-3.5 h-3.5" />
          </Button>

          {/* DATOS GENERALES */}
          <div className="space-y-3 bg-muted/30 p-3.5 rounded-lg border border-border/50 text-xs">
            <div className="grid grid-cols-2 gap-2">
              <div>
                <span className="text-muted-foreground block text-[11px]">Cliente</span>
                <span className="font-semibold text-foreground truncate block" title={fila.cliente_nombre}>
                  {fila.cliente_nombre || 'Inventario'}
                </span>
              </div>
              <div>
                <span className="text-muted-foreground block text-[11px]">Cotización origen</span>
                <span className="font-semibold text-foreground truncate block">
                  {fila.cotizacion_folio || 'Manual en planta'}
                </span>
              </div>
              <div>
                <span className="text-muted-foreground block text-[11px]">Modelo / Tipo</span>
                <span className="font-semibold text-foreground truncate block" title={fila.modelo || fila.tipo_equipo || ''}>
                  {fila.modelo || fila.tipo_equipo || 'Sin modelo'}
                </span>
              </div>
              <div>
                <span className="text-muted-foreground block text-[11px]">Avance principal</span>
                <span className="font-semibold text-foreground">
                  {fila.avance?.terminadas ?? 0} de {fila.avance?.total ?? 12} fases
                </span>
              </div>
            </div>

            {fila.tina && (
              <div className="pt-2 border-t border-border/40 flex items-center justify-between">
                <span className="text-muted-foreground flex items-center gap-1.5">
                  <Layers className="w-3.5 h-3.5 text-primary" />
                  Subproceso Tina:
                </span>
                <span className="font-semibold text-foreground">
                  {fila.tina.terminadas}/{fila.tina.total} fases terminadas
                </span>
              </div>
            )}
          </div>

          {/* CAMPOS EDITABLES DE PLANEACIÓN */}
          <div className="space-y-3">
            <h4 className="text-xs font-bold text-foreground uppercase tracking-wider">
              Planeación del equipo
            </h4>

            {/* Etiqueta */}
            <div className="space-y-1">
              <label className="text-xs text-muted-foreground font-medium">
                Etiqueta / Identificador visible
              </label>
              <Input
                value={etiqueta}
                onChange={(e) => setEtiqueta(e.target.value)}
                placeholder="Ej. Transportes Azteca #1"
                className="h-8 text-xs"
              />
            </div>

            {/* Fecha compromiso */}
            <div className="space-y-1">
              <label className="text-xs text-muted-foreground font-medium flex items-center gap-1">
                <Calendar className="w-3.5 h-3.5" />
                Fecha de compromiso
              </label>
              <Input
                type="date"
                value={fechaCompromiso}
                onChange={(e) => setFechaCompromiso(e.target.value)}
                className="h-8 text-xs"
              />
            </div>

            {/* Material faltante / Observaciones */}
            <div className="space-y-1">
              <label className="text-xs text-muted-foreground font-medium flex items-center gap-1">
                <AlertTriangle className="w-3.5 h-3.5 text-amber-500" />
                Material faltante u observaciones
              </label>
              <Textarea
                rows={2}
                value={materialFaltante}
                onChange={(e) => setMaterialFaltante(e.target.value)}
                placeholder="Detalle de piezas o tornillería pendiente..."
                className="text-xs resize-none"
              />
            </div>

            <Button
              type="button"
              variant="default"
              size="sm"
              disabled={guardando}
              onClick={handleGuardarCambios}
              className="w-full text-xs font-semibold h-8 bg-primary text-primary-foreground hover:bg-primary/90"
            >
              <Save className="w-3.5 h-3.5 mr-1.5" />
              {guardando ? 'Guardando...' : 'Guardar cambios de planeación'}
            </Button>
          </div>

          {/* HISTORIAL VERTICAL DE CAMBIOS DE FASE */}
          <div className="space-y-3 pt-2">
            <div className="flex items-center justify-between">
              <h4 className="text-xs font-bold text-foreground uppercase tracking-wider flex items-center gap-1.5">
                <History className="w-4 h-4 text-primary" />
                Historial de cambios
              </h4>
              <span className="text-[11px] text-muted-foreground">
                {historial.length} {historial.length === 1 ? 'evento' : 'eventos'}
              </span>
            </div>

            {cargandoHistorial ? (
              <div className="py-8 text-center text-xs text-muted-foreground">
                Cargando historial de la orden...
              </div>
            ) : historial.length === 0 ? (
              <div className="py-6 text-center text-xs text-muted-foreground bg-muted/20 rounded-lg border border-border/40">
                Sin movimientos registrados todavía.
              </div>
            ) : (
              <div className="relative pl-6 space-y-4 before:absolute before:left-2.5 before:top-2 before:bottom-2 before:w-0.5 before:bg-border/70">
                {historial.map((item) => (
                  <div key={item.id} className="relative group text-xs">
                    {/* Nodo de la línea */}
                    <span className="absolute -left-6 top-1 w-3.5 h-3.5 rounded-full bg-card border-2 border-primary flex items-center justify-center shrink-0" />

                    <div className="bg-card p-2.5 rounded-lg border border-border/60 shadow-xs space-y-1">
                      <div className="flex items-center justify-between gap-1 flex-wrap">
                        <span className="font-semibold text-foreground text-xs">
                          {formatearFaseHistorial(item.fase_nombre, item.fase_orden)}
                          {item.fase_grupo === 'tina' && (
                            <span className="ml-1 text-[10px] text-primary font-medium">
                              (Tina)
                            </span>
                          )}
                        </span>
                        <span className="text-[10px] text-muted-foreground">
                          {formatearTiempoRelativo(item.fecha_cambio)}
                        </span>
                      </div>

                      {/* Transición de estados */}
                      <div className="flex items-center gap-1.5 text-[11px] font-medium pt-0.5">
                        <span className="text-muted-foreground">
                          {formatearEstadoHistorial(item.estado_anterior)}
                        </span>
                        <span className="text-muted-foreground">→</span>
                        <span className="flex items-center gap-1 font-semibold text-foreground">
                          {renderIconoEstado(item.estado_nuevo)}
                          {formatearEstadoHistorial(item.estado_nuevo)}
                        </span>
                      </div>

                      {/* Fecha propuesta si cambió */}
                      {item.fecha_propuesta && (
                        <div className="text-[11px] text-muted-foreground flex items-center gap-1">
                          <Calendar className="w-3 h-3" />
                          Propuesta: {formatearFechaCorta(item.fecha_propuesta)}
                        </div>
                      )}

                      {/* Nota */}
                      {item.nota && (
                        <p className="text-[11px] text-foreground bg-muted/40 p-1.5 rounded italic border border-border/30">
                          &quot;{item.nota}&quot;
                        </p>
                      )}

                      {/* Usuario */}
                      <div className="text-[10px] text-muted-foreground/70 flex items-center gap-1 pt-0.5">
                        <User className="w-2.5 h-2.5" />
                        {formatearUsuarioHistorial(item.usuario)}
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>
      </SheetContent>
    </Sheet>
  );
}
