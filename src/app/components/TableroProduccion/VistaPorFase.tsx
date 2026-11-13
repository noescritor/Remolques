import React, { useMemo } from 'react';
import {
  FaseMatriz,
  FilaMatriz,
} from '../../utils/tableroApi';
import {
  agruparPorFase,
  formatearFechaCorta,
  obtenerHoyMexico,
  EstadoFase,
} from '../../utils/tableroProduccion';
import { CeldaFaseMenu } from './CeldaFaseMenu';
import { Badge } from '../ui/badge';
import {
  Clock,
  AlertTriangle,
  Layers,
  ChevronRight,
  Sparkles,
} from 'lucide-react';
import { cn } from '../ui/utils';

interface VistaPorFaseProps {
  filas: FilaMatriz[];
  fases: FaseMatriz[];
  hoy?: string;
  onCambiarFase: (
    ordenId: string,
    faseId: string,
    cambio: {
      estado: EstadoFase;
      fecha_propuesta?: string | null;
      fecha_fin?: string | null;
      nota?: string | null;
    }
  ) => Promise<void>;
  onSeleccionarOrden: (fila: FilaMatriz) => void;
}

export function VistaPorFase({
  filas,
  fases,
  hoy = obtenerHoyMexico(),
  onCambiarFase,
  onSeleccionarOrden,
}: VistaPorFaseProps) {
  // Fases principales ordenadas
  const fasesPrincipales = useMemo(() => {
    return fases
      .filter((f) => f.grupo === 'principal')
      .sort((a, b) => a.orden - b.orden);
  }, [fases]);

  // Agrupamiento por fase activa (incluye duplicación si un equipo tiene múltiples fases activas)
  const columnas = useMemo(() => {
    const cols = agruparPorFase(filas, fasesPrincipales);
    // Solo mostrar columnas activas (con tarjetas) o la columna Por iniciar
    return cols.filter((c) => c.esPorIniciar || c.tarjetas.length > 0);
  }, [filas, fasesPrincipales]);

  // Color de punto semáforo
  const obtenerColorSemaforo = (semaforo?: string) => {
    switch (semaforo) {
      case 'atrasado':
      case 'detenido':
        return 'bg-destructive ring-destructive/30';
      case 'por_vencer':
        return 'bg-amber-500 ring-amber-500/30';
      case 'terminado':
        return 'bg-blue-500 ring-blue-500/30';
      case 'en_tiempo':
      default:
        return 'bg-emerald-500 ring-emerald-500/30';
    }
  };

  return (
    <div className="flex-1 overflow-x-auto pb-4">
      {columnas.length === 0 ? (
        <div className="p-12 text-center text-muted-foreground bg-card rounded-xl border border-border">
          No hay equipos con fases activas en este momento.
        </div>
      ) : (
        <div className="flex items-start gap-4 min-w-max">
          {columnas.map((col) => (
            <div
              key={col.id}
              className="w-72 bg-muted/40 rounded-xl border border-border/70 flex flex-col max-h-[calc(100vh-270px)] shrink-0 shadow-2xs"
            >
              {/* Encabezado de la columna */}
              <div className="p-3 border-b border-border/60 bg-muted/60 rounded-t-xl flex items-center justify-between sticky top-0 z-10 backdrop-blur-xs">
                <div className="flex items-center gap-1.5 min-w-0">
                  <span className="font-bold text-xs text-foreground truncate">
                    {col.esPorIniciar ? 'Por iniciar' : `${col.orden}. ${col.titulo}`}
                  </span>
                </div>
                <Badge
                  variant="secondary"
                  className={cn(
                    'text-[10px] h-5 px-1.5 font-semibold',
                    col.tarjetas.length > 0
                      ? 'bg-primary/15 text-primary'
                      : 'bg-muted text-muted-foreground'
                  )}
                >
                  {col.tarjetas.length}
                </Badge>
              </div>

              {/* Lista de tarjetas */}
              <div className="p-2 space-y-2.5 overflow-y-auto flex-1">
                {col.tarjetas.length === 0 ? (
                  <div className="py-8 text-center text-[11px] text-muted-foreground/70 italic">
                    Sin equipos en esta fase
                  </div>
                ) : (
                  col.tarjetas.map((tarjeta) => {
                    const celdaActual = tarjeta.fila.celdas?.[tarjeta.fase_id];
                    const esVencida =
                      tarjeta.fecha_propuesta && tarjeta.fecha_propuesta < hoy;

                    return (
                      <div
                        key={`${tarjeta.orden_id}-${tarjeta.fase_id}`}
                        className="bg-card p-3 rounded-lg border border-border/70 hover:border-primary/50 shadow-xs transition-all space-y-2 group"
                      >
                        {/* Cabecera de la tarjeta: Semáforo y Etiqueta */}
                        <div className="flex items-start justify-between gap-1.5">
                          <div className="flex items-start gap-1.5 min-w-0 flex-1">
                            <span
                              className={cn(
                                'w-2.5 h-2.5 rounded-full mt-1 shrink-0 ring-4',
                                obtenerColorSemaforo(tarjeta.fila.semaforo)
                              )}
                              title={`Semáforo: ${tarjeta.fila.semaforo}`}
                            />
                            <div className="min-w-0 flex-1">
                              <button
                                type="button"
                                onClick={() => onSeleccionarOrden(tarjeta.fila)}
                                className="font-semibold text-xs text-foreground hover:text-primary transition-colors truncate block text-left w-full cursor-pointer"
                                title={tarjeta.etiqueta}
                              >
                                {tarjeta.etiqueta}
                              </button>
                              <div className="text-[10px] text-muted-foreground truncate">
                                {tarjeta.modelo || tarjeta.fila.tipo_equipo || 'Sin modelo'}
                              </div>
                            </div>
                          </div>

                          {/* Avance */}
                          <span className="text-[10px] text-muted-foreground font-medium shrink-0">
                            {tarjeta.fila.avance?.terminadas ?? 0}/{tarjeta.fila.avance?.total ?? 12}
                          </span>
                        </div>

                        {/* Botón interactivo de fase (Menú contextual) */}
                        {!col.esPorIniciar && col.fase && (
                          <div className="pt-1 flex items-center justify-between gap-2 border-t border-border/40">
                            <span className="text-[10px] text-muted-foreground font-medium">
                              Estado de fase:
                            </span>
                            <CeldaFaseMenu
                              ordenId={tarjeta.orden_id}
                              etiquetaOrden={tarjeta.etiqueta}
                              fase={col.fase}
                              celda={celdaActual}
                              hoy={hoy}
                              onCambiarFase={onCambiarFase}
                            />
                          </div>
                        )}

                        {/* Material faltante / Observaciones */}
                        {tarjeta.material_faltante ? (
                          <div className="text-[11px] text-destructive bg-destructive/10 p-1.5 rounded flex items-start gap-1.5 border border-destructive/20">
                            <AlertTriangle className="w-3.5 h-3.5 shrink-0 mt-0.5" />
                            <span className="truncate" title={tarjeta.material_faltante}>
                              {tarjeta.material_faltante}
                            </span>
                          </div>
                        ) : tarjeta.estado_fase === 'incompleta' ? (
                          <div className="text-[11px] text-destructive italic flex items-center gap-1 font-medium">
                            <AlertTriangle className="w-3 h-3 shrink-0" />
                            Falta capturar material faltante
                          </div>
                        ) : null}

                        {/* Pie de tarjeta: Compromiso o Tina */}
                        <div className="flex items-center justify-between text-[10px] text-muted-foreground pt-1 border-t border-border/30">
                          <span>
                            Comp: {tarjeta.fila.fecha_compromiso ? formatearFechaCorta(tarjeta.fila.fecha_compromiso) : '—'}
                          </span>
                          {tarjeta.fila.tina && (
                            <span className="flex items-center gap-1 text-primary font-medium">
                              <Layers className="w-2.5 h-2.5" />
                              Tina {tarjeta.fila.tina.terminadas}/{tarjeta.fila.tina.total}
                            </span>
                          )}
                        </div>
                      </div>
                    );
                  })
                )}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
