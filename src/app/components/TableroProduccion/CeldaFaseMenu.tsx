import React, { useState } from 'react';
import {
  calcularEstadoVisualCelda,
  formatearFechaCorta,
  sumarDiasAFecha,
  obtenerHoyMexico,
  EstadoFase,
} from '../../utils/tableroProduccion';
import { Popover, PopoverContent, PopoverTrigger } from '../ui/popover';
import { Button } from '../ui/button';
import { Input } from '../ui/input';
import {
  Check,
  Play,
  Pause,
  AlertTriangle,
  RotateCcw,
  Calendar,
  Plus,
  Minus,
} from 'lucide-react';
import { cn } from '../ui/utils';

interface CeldaFaseMenuProps {
  ordenId: string;
  etiquetaOrden: string;
  fase: {
    id: string;
    orden: number;
    nombre: string;
    grupo?: string;
    duracion_dias?: number;
  };
  celda?: {
    estado?: string | null;
    fecha_propuesta?: string | null;
    fecha_fin?: string | null;
    nota?: string | null;
  } | null;
  hoy?: string;
  disabled?: boolean;
  onCambiarFase: (
    ordenId: string,
    faseId: string,
    cambio: {
      estado: EstadoFase;
      fecha_propuesta?: string | null;
      fecha_fin?: string | null;
      nota?: string | null;
    }
  ) => Promise<void> | void;
}

export function CeldaFaseMenu({
  ordenId,
  etiquetaOrden,
  fase,
  celda,
  hoy = obtenerHoyMexico(),
  disabled = false,
  onCambiarFase,
}: CeldaFaseMenuProps) {
  const [abierto, setAbierto] = useState(false);
  const estadoVisual = calcularEstadoVisualCelda(celda, fase.nombre, hoy);

  const estadoActual = (celda?.estado || 'pendiente') as EstadoFase;
  const duracion = fase.duracion_dias || 1;

  // Estados locales editables en el menú
  const [fechaPropuesta, setFechaPropuesta] = useState<string>(
    celda?.fecha_propuesta || ''
  );
  const [nota, setNota] = useState<string>(celda?.nota || '');

  // Sincronizar al abrir el menú
  const handleOpenChange = (open: boolean) => {
    if (open) {
      setFechaPropuesta(celda?.fecha_propuesta || '');
      setNota(celda?.nota || '');
    }
    setAbierto(open);
  };

  const ejecutarAccion = async (nuevoEstado: EstadoFase, propsExtra?: { fecha_propuesta?: string | null; fecha_fin?: string | null; nota?: string | null }) => {
    setAbierto(false);

    let fechaFin = propsExtra?.fecha_fin;
    if (nuevoEstado === 'terminada') {
      fechaFin = fechaFin !== undefined ? fechaFin : hoy;
    } else {
      fechaFin = null;
    }

    let fProp = propsExtra?.fecha_propuesta !== undefined ? propsExtra.fecha_propuesta : (fechaPropuesta || null);
    if (nuevoEstado === 'pendiente') {
      fProp = null;
    }

    const notaFinal = propsExtra?.nota !== undefined ? propsExtra.nota : (nota.trim() || null);

    await onCambiarFase(ordenId, fase.id, {
      estado: nuevoEstado,
      fecha_propuesta: fProp,
      fecha_fin: fechaFin,
      nota: notaFinal,
    });
  };

  const ajustarDiasFechaPropuesta = (deltaDias: number) => {
    const base = fechaPropuesta || hoy;
    const nueva = sumarDiasAFecha(base, deltaDias);
    setFechaPropuesta(nueva);
  };

  const guardarAjustesEnProceso = async () => {
    await ejecutarAccion('en_proceso', {
      fecha_propuesta: fechaPropuesta || null,
      nota: nota.trim() || null,
    });
  };

  return (
    <Popover open={abierto} onOpenChange={handleOpenChange}>
      <PopoverTrigger asChild>
        <button
          type="button"
          disabled={disabled}
          aria-label={estadoVisual.ariaLabel}
          className={cn(
            'min-w-[78px] min-h-[40px] px-2 py-1 text-xs rounded-md border font-medium flex items-center justify-center transition-colors focus:outline-hidden focus:ring-2 focus:ring-ring focus:ring-offset-1 select-none',
            estadoVisual.claseColor,
            disabled && 'opacity-50 cursor-not-allowed'
          )}
        >
          <span className="truncate">{estadoVisual.texto}</span>
        </button>
      </PopoverTrigger>

      <PopoverContent className="w-80 p-3 bg-popover text-popover-foreground shadow-lg border border-border" align="center" side="bottom">
        {/* Cabecera del popover */}
        <div className="border-b border-border/50 pb-2 mb-3">
          <div className="flex items-center justify-between gap-2">
            <span className="font-semibold text-sm text-foreground truncate">
              {fase.orden}. {fase.nombre}
            </span>
            <span className={cn('text-[11px] px-2 py-0.5 rounded-full border font-medium shrink-0', estadoVisual.claseColor)}>
              {estadoVisual.texto}
            </span>
          </div>
          <p className="text-xs text-muted-foreground truncate mt-0.5" title={etiquetaOrden}>
            {etiquetaOrden}
          </p>
        </div>

        {/* Acciones contextuales según estado actual */}
        <div className="space-y-2">
          {/* CASO: PENDIENTE */}
          {estadoActual === 'pendiente' && (
            <div className="space-y-1.5">
              <Button
                type="button"
                variant="default"
                size="sm"
                className="w-full justify-start text-xs bg-primary text-primary-foreground hover:bg-primary/90 h-8"
                onClick={() =>
                  ejecutarAccion('en_proceso', {
                    fecha_propuesta: sumarDiasAFecha(hoy, duracion),
                  })
                }
              >
                <Play className="w-3.5 h-3.5 mr-2" />
                Iniciar ({duracion} {duracion === 1 ? 'día' : 'días'})
              </Button>

              <Button
                type="button"
                variant="outline"
                size="sm"
                className="w-full justify-start text-xs border-border/60 hover:bg-muted text-foreground h-8"
                onClick={() => ejecutarAccion('terminada', { fecha_fin: hoy })}
              >
                <Check className="w-3.5 h-3.5 mr-2 text-emerald-600 dark:text-emerald-400" />
                Terminar hoy
              </Button>
            </div>
          )}

          {/* CASO: EN PROCESO */}
          {estadoActual === 'en_proceso' && (
            <div className="space-y-2">
              <Button
                type="button"
                variant="default"
                size="sm"
                className="w-full justify-start text-xs bg-emerald-600 hover:bg-emerald-700 text-white h-8"
                onClick={() => ejecutarAccion('terminada', { fecha_fin: hoy })}
              >
                <Check className="w-3.5 h-3.5 mr-2" />
                Terminar hoy
              </Button>

              <div className="grid grid-cols-2 gap-1.5">
                <Button
                  type="button"
                  variant="outline"
                  size="sm"
                  className="justify-start text-xs border-destructive/40 text-destructive hover:bg-destructive/10 h-8"
                  onClick={() => ejecutarAccion('incompleta')}
                >
                  <AlertTriangle className="w-3.5 h-3.5 mr-1.5 shrink-0" />
                  Falta material
                </Button>

                <Button
                  type="button"
                  variant="outline"
                  size="sm"
                  className="justify-start text-xs border-amber-500/40 text-amber-600 dark:text-amber-400 hover:bg-amber-500/10 h-8"
                  onClick={() => ejecutarAccion('pausada')}
                >
                  <Pause className="w-3.5 h-3.5 mr-1.5 shrink-0" />
                  Pausar
                </Button>
              </div>

              {/* Ajuste de fecha propuesta */}
              <div className="rounded-md border border-border/60 p-2 bg-muted/30 space-y-1.5">
                <div className="flex items-center justify-between text-xs">
                  <span className="text-muted-foreground flex items-center gap-1 font-medium">
                    <Calendar className="w-3.5 h-3.5" />
                    Propuesta:
                  </span>
                  <span className="font-semibold text-foreground">
                    {fechaPropuesta ? formatearFechaCorta(fechaPropuesta) : 'Sin fecha'}
                  </span>
                </div>
                <div className="flex items-center gap-1">
                  <Button
                    type="button"
                    variant="outline"
                    size="sm"
                    className="h-7 px-2 text-[11px] border-border/60"
                    onClick={() => ajustarDiasFechaPropuesta(-1)}
                    title="Restar 1 día"
                  >
                    <Minus className="w-3 h-3 mr-0.5" /> 1d
                  </Button>
                  <Input
                    type="date"
                    value={fechaPropuesta}
                    onChange={(e) => setFechaPropuesta(e.target.value)}
                    className="h-7 text-xs px-2 py-0"
                  />
                  <Button
                    type="button"
                    variant="outline"
                    size="sm"
                    className="h-7 px-2 text-[11px] border-border/60"
                    onClick={() => ajustarDiasFechaPropuesta(1)}
                    title="Sumar 1 día"
                  >
                    <Plus className="w-3 h-3 mr-0.5" /> 1d
                  </Button>
                </div>
              </div>
            </div>
          )}

          {/* CASO: INCOMPLETA (MATERIAL) */}
          {estadoActual === 'incompleta' && (
            <div className="space-y-1.5">
              <Button
                type="button"
                variant="default"
                size="sm"
                className="w-full justify-start text-xs bg-primary text-primary-foreground hover:bg-primary/90 h-8"
                onClick={() => ejecutarAccion('en_proceso')}
              >
                <Play className="w-3.5 h-3.5 mr-2" />
                Reanudar (en proceso)
              </Button>

              <Button
                type="button"
                variant="outline"
                size="sm"
                className="w-full justify-start text-xs border-border/60 hover:bg-muted text-foreground h-8"
                onClick={() => ejecutarAccion('terminada', { fecha_fin: hoy })}
              >
                <Check className="w-3.5 h-3.5 mr-2 text-emerald-600 dark:text-emerald-400" />
                Terminar hoy
              </Button>
            </div>
          )}

          {/* CASO: PAUSADA */}
          {estadoActual === 'pausada' && (
            <div className="space-y-1.5">
              <Button
                type="button"
                variant="default"
                size="sm"
                className="w-full justify-start text-xs bg-primary text-primary-foreground hover:bg-primary/90 h-8"
                onClick={() => ejecutarAccion('en_proceso')}
              >
                <Play className="w-3.5 h-3.5 mr-2" />
                Reanudar (en proceso)
              </Button>

              <Button
                type="button"
                variant="outline"
                size="sm"
                className="w-full justify-start text-xs border-border/60 hover:bg-muted text-foreground h-8"
                onClick={() => ejecutarAccion('terminada', { fecha_fin: hoy })}
              >
                <Check className="w-3.5 h-3.5 mr-2 text-emerald-600 dark:text-emerald-400" />
                Terminar hoy
              </Button>
            </div>
          )}

          {/* CASO: TERMINADA */}
          {estadoActual === 'terminada' && (
            <div className="space-y-1.5">
              <Button
                type="button"
                variant="outline"
                size="sm"
                className="w-full justify-start text-xs border-border/60 hover:bg-muted text-foreground h-8"
                onClick={() =>
                  ejecutarAccion('en_proceso', {
                    fecha_propuesta: sumarDiasAFecha(hoy, duracion),
                  })
                }
              >
                <RotateCcw className="w-3.5 h-3.5 mr-2 text-primary" />
                Reabrir (en proceso)
              </Button>
            </div>
          )}

          {/* Campo de nota opcional */}
          <div className="pt-1">
            <Input
              type="text"
              placeholder="Nota u observación..."
              value={nota}
              onChange={(e) => setNota(e.target.value)}
              className="h-7 text-xs border-border/60"
            />
          </div>

          {/* Guardar si modificó fecha o nota en estado en_proceso */}
          {estadoActual === 'en_proceso' && (
            <Button
              type="button"
              variant="secondary"
              size="sm"
              className="w-full text-xs h-7 mt-1"
              onClick={guardarAjustesEnProceso}
            >
              Guardar fecha / nota
            </Button>
          )}

          {/* Separador y opción Limpiar (disponible en cualquier estado) */}
          <div className="border-t border-border/50 pt-1.5 mt-1.5">
            <Button
              type="button"
              variant="ghost"
              size="sm"
              className="w-full justify-start text-xs text-muted-foreground hover:text-destructive hover:bg-destructive/10 h-7"
              onClick={() => ejecutarAccion('pendiente')}
            >
              <RotateCcw className="w-3 h-3 mr-2 text-muted-foreground" />
              Limpiar (volver a pendiente)
            </Button>
          </div>
        </div>
      </PopoverContent>
    </Popover>
  );
}
