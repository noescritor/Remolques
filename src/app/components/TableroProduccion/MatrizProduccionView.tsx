import React, { useState, useMemo } from 'react';
import {
  FaseMatriz,
  FilaMatriz,
  ResumenMatriz,
} from '../../utils/tableroApi';
import { CeldaFaseMenu } from './CeldaFaseMenu';
import {
  formatearFechaCorta,
  obtenerHoyMexico,
  EstadoFase,
} from '../../utils/tableroProduccion';
import { Input } from '../ui/input';
import { Button } from '../ui/button';
import { Badge } from '../ui/badge';
import {
  AlertTriangle,
  ChevronRight,
  ChevronDown,
  Layers,
  Sparkles,
} from 'lucide-react';
import { cn } from '../ui/utils';

interface MatrizProduccionViewProps {
  lineaClave: string;
  fases: FaseMatriz[];
  filas: FilaMatriz[];
  resumen: ResumenMatriz;
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
  onGuardarPlaneacion: (
    ordenId: string,
    cambios: {
      fecha_compromiso?: string | null;
      etiqueta?: string | null;
      material_faltante?: string | null;
    }
  ) => Promise<void>;
  onSeleccionarOrden?: (fila: FilaMatriz) => void;
}

export function MatrizProduccionView({
  lineaClave,
  fases,
  filas,
  resumen,
  hoy = obtenerHoyMexico(),
  onCambiarFase,
  onGuardarPlaneacion,
  onSeleccionarOrden,
}: MatrizProduccionViewProps) {
  // Fases principales para las columnas de la matriz
  const fasesPrincipales = useMemo(() => {
    return fases
      .filter((f) => f.grupo === 'principal')
      .sort((a, b) => a.orden - b.orden);
  }, [fases]);

  // Fases de tina (para góndola)
  const fasesTina = useMemo(() => {
    return fases
      .filter((f) => f.grupo === 'tina')
      .sort((a, b) => a.orden - b.orden);
  }, [fases]);

  // Cuello de botella en resumen
  const maxWip = useMemo(() => {
    let max = 0;
    for (const f of fasesPrincipales) {
      const c = resumen?.wip_por_fase?.[f.id] || 0;
      if (c > max) max = c;
    }
    return max;
  }, [fasesPrincipales, resumen]);

  // Estado de filas de tina expandidas (por orden_id)
  const [tinasExpandidas, setTinasExpandidas] = useState<Record<string, boolean>>({});

  const toggleTina = (ordenId: string, e: React.MouseEvent) => {
    e.stopPropagation();
    setTinasExpandidas((prev) => ({
      ...prev,
      [ordenId]: !prev[ordenId],
    }));
  };

  // Edición inline de material_faltante
  const [editandoMaterialId, setEditandoMaterialId] = useState<string | null>(null);
  const [valorMaterialTemp, setValorMaterialTemp] = useState<string>('');

  const iniciarEdicionMaterial = (fila: FilaMatriz) => {
    setEditandoMaterialId(fila.orden_id);
    setValorMaterialTemp(fila.material_faltante || '');
  };

  const guardarMaterial = async (fila: FilaMatriz) => {
    const val = valorMaterialTemp.trim() || null;
    setEditandoMaterialId(null);
    if (val !== (fila.material_faltante || null)) {
      await onGuardarPlaneacion(fila.orden_id, { material_faltante: val });
    }
  };

  const cancelarEdicionMaterial = () => {
    setEditandoMaterialId(null);
    setValorMaterialTemp('');
  };

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
    <div className="relative border border-border/70 rounded-xl overflow-hidden bg-card shadow-sm flex flex-col">
      <div className="overflow-x-auto w-full max-h-[calc(100vh-280px)]">
        <table className="w-full border-collapse text-left text-sm whitespace-nowrap">
          {/* ENCABEZADOS DE COLUMNA */}
          <thead className="bg-muted/80 backdrop-blur-xs sticky top-0 z-30 border-b border-border text-xs text-muted-foreground">
            <tr>
              {/* Columna fija izquierda: Equipo */}
              <th className="sticky left-0 z-40 bg-muted px-4 py-3 font-semibold text-foreground border-r border-border min-w-[220px] max-w-[280px]">
                Equipo
              </th>

              {/* Avance */}
              <th className="px-3 py-3 font-semibold text-foreground text-center border-r border-border/50 min-w-[70px]">
                Avance
              </th>

              {/* Compromiso */}
              <th className="px-3 py-3 font-semibold text-foreground text-center border-r border-border/50 min-w-[95px]">
                Compromiso
              </th>

              {/* Fases Principales */}
              {fasesPrincipales.map((fase) => (
                <th
                  key={fase.id}
                  className="px-2 py-2 font-medium text-foreground text-center border-r border-border/40 min-w-[90px]"
                >
                  <div className="text-[11px] font-semibold truncate max-w-[110px]" title={fase.nombre}>
                    {fase.orden}. {fase.nombre}
                  </div>
                  <div className="text-[10px] text-muted-foreground font-normal">
                    {fase.duracion_dias || 1}d
                  </div>
                </th>
              ))}

              {/* Material faltante / Observaciones */}
              <th className="px-4 py-3 font-semibold text-foreground min-w-[220px]">
                {lineaClave === 'dolly' ? 'Observaciones' : 'Material faltante'}
              </th>
            </tr>

            {/* FILA DE RESUMEN "EN PROCESO AHORA" / CUELLO DE BOTELLA */}
            <tr className="bg-muted/40 border-b border-border/60 text-xs">
              <td className="sticky left-0 z-40 bg-muted/90 px-4 py-2 font-medium text-muted-foreground border-r border-border">
                <div className="flex items-center gap-1.5 text-xs text-foreground font-semibold">
                  <Sparkles className="w-3.5 h-3.5 text-primary" />
                  En proceso ahora
                </div>
              </td>
              <td className="px-3 py-2 text-center text-xs text-muted-foreground border-r border-border/50">
                —
              </td>
              <td className="px-3 py-2 text-center text-xs text-muted-foreground border-r border-border/50">
                —
              </td>
              {fasesPrincipales.map((fase) => {
                const count = resumen?.wip_por_fase?.[fase.id] || 0;
                const esCuelloBotella = count > 0 && count === maxWip;

                return (
                  <td
                    key={fase.id}
                    className={cn(
                      'px-2 py-1.5 text-center font-semibold text-xs border-r border-border/40 transition-colors',
                      esCuelloBotella
                        ? 'bg-amber-500/20 text-amber-900 dark:text-amber-200 border-b-2 border-b-amber-500 font-bold'
                        : count > 0
                        ? 'text-foreground'
                        : 'text-muted-foreground/50'
                    )}
                    title={esCuelloBotella ? `Mayor carga en proceso (${count} equipos)` : undefined}
                  >
                    <div className="flex items-center justify-center gap-1">
                      <span>{count}</span>
                      {esCuelloBotella && (
                        <span className="inline-block w-1.5 h-1.5 rounded-full bg-amber-500" />
                      )}
                    </div>
                  </td>
                );
              })}
              <td className="px-4 py-2 text-xs text-muted-foreground">
                Total en planta: <strong className="text-foreground">{resumen?.en_planta ?? filas.length}</strong>
              </td>
            </tr>
          </thead>

          {/* CUERPO DE LA MATRIZ */}
          <tbody className="divide-y divide-border/50">
            {filas.length === 0 ? (
              <tr>
                <td
                  colSpan={fasesPrincipales.length + 4}
                  className="py-12 text-center text-muted-foreground"
                >
                  No hay equipos en planta para los filtros seleccionados.
                </td>
              </tr>
            ) : (
              filas.map((fila) => {
                const tieneIncompletaSinTexto =
                  Object.values(fila.celdas || {}).some(
                    (c) => c?.estado === 'incompleta'
                  ) && !fila.material_faltante;

                const tinaAbierta = !!tinasExpandidas[fila.orden_id];
                const fechaCompVencida =
                  fila.fecha_compromiso && fila.fecha_compromiso < hoy;

                return (
                  <React.Fragment key={fila.orden_id}>
                    <tr className="hover:bg-muted/30 transition-colors group">
                      {/* COLUMNA STICKY EQUIPO */}
                      <td className="sticky left-0 z-20 bg-card group-hover:bg-card px-4 py-2.5 border-r border-border min-w-[220px] max-w-[280px]">
                        <div className="flex items-start gap-2">
                          {/* Punto Semáforo */}
                          <span
                            className={cn(
                              'w-2.5 h-2.5 rounded-full mt-1 shrink-0 ring-4',
                              obtenerColorSemaforo(fila.semaforo)
                            )}
                            title={`Semáforo: ${fila.semaforo}`}
                          />

                          <div className="flex-1 min-w-0">
                            {/* Etiqueta / Nombre */}
                            <button
                              type="button"
                              onClick={() => onSeleccionarOrden?.(fila)}
                              className="font-semibold text-xs text-foreground hover:text-primary transition-colors truncate block text-left w-full cursor-pointer"
                              title={fila.etiqueta}
                            >
                              {fila.etiqueta}
                            </button>

                            {/* Modelo o tipo de equipo */}
                            <div className="text-[11px] text-muted-foreground truncate">
                              {fila.modelo || fila.tipo_equipo || 'Sin modelo'}
                            </div>

                            {/* Badge Tina si aplica (Góndola) */}
                            {fila.tina && (
                              <button
                                type="button"
                                onClick={(e) => toggleTina(fila.orden_id, e)}
                                className={cn(
                                  'mt-1 inline-flex items-center gap-1 px-1.5 py-0.5 rounded text-[10px] font-medium border transition-colors cursor-pointer',
                                  tinaAbierta
                                    ? 'bg-primary/15 text-primary border-primary/30'
                                    : 'bg-muted/70 text-muted-foreground hover:bg-muted border-border/60'
                                )}
                                title="Expandir/cerrar franja de subproceso Tina"
                              >
                                {tinaAbierta ? (
                                  <ChevronDown className="w-3 h-3" />
                                ) : (
                                  <ChevronRight className="w-3 h-3" />
                                )}
                                <span>
                                  Tina {fila.tina.terminadas}/{fila.tina.total}
                                </span>
                              </button>
                            )}
                          </div>
                        </div>
                      </td>

                      {/* AVANCE */}
                      <td className="px-3 py-2 text-center border-r border-border/50 text-xs font-medium text-foreground">
                        {fila.avance?.terminadas ?? 0}/{fila.avance?.total ?? 12}
                      </td>

                      {/* COMPROMISO */}
                      <td
                        className={cn(
                          'px-3 py-2 text-center border-r border-border/50 text-xs font-medium',
                          fechaCompVencida ? 'text-destructive font-semibold' : 'text-muted-foreground'
                        )}
                      >
                        {formatearFechaCorta(fila.fecha_compromiso) || '—'}
                      </td>

                      {/* CELDAS DE FASES PRINCIPALES */}
                      {fasesPrincipales.map((fase) => {
                        const celda = fila.celdas?.[fase.id];

                        return (
                          <td
                            key={fase.id}
                            className="px-1.5 py-1 text-center border-r border-border/40"
                          >
                            <CeldaFaseMenu
                              ordenId={fila.orden_id}
                              etiquetaOrden={fila.etiqueta}
                              fase={fase}
                              celda={celda}
                              hoy={hoy}
                              onCambiarFase={onCambiarFase}
                            />
                          </td>
                        );
                      })}

                      {/* MATERIAL FALTANTE (EDICIÓN INLINE) */}
                      <td className="px-4 py-2 text-xs">
                        {editandoMaterialId === fila.orden_id ? (
                          <div className="flex items-center gap-1.5 min-w-[200px]">
                            <Input
                              autoFocus
                              value={valorMaterialTemp}
                              onChange={(e) => setValorMaterialTemp(e.target.value)}
                              onKeyDown={(e) => {
                                if (e.key === 'Enter') {
                                  e.preventDefault();
                                  guardarMaterial(fila);
                                } else if (e.key === 'Escape') {
                                  e.preventDefault();
                                  cancelarEdicionMaterial();
                                }
                              }}
                              onBlur={() => guardarMaterial(fila)}
                              placeholder="Capturar material faltante..."
                              className="h-7 text-xs px-2 py-0"
                            />
                          </div>
                        ) : (
                          <div
                            onClick={() => iniciarEdicionMaterial(fila)}
                            className="cursor-pointer group/mat flex items-center justify-between gap-2 min-h-[28px] px-2 py-1 rounded hover:bg-muted/50 border border-transparent hover:border-border/60 transition-colors"
                            title="Clic para editar material faltante"
                          >
                            {fila.material_faltante ? (
                              <span className="text-foreground truncate max-w-[280px]" title={fila.material_faltante}>
                                {fila.material_faltante}
                              </span>
                            ) : tieneIncompletaSinTexto ? (
                              <span className="text-destructive font-medium italic text-[11px] flex items-center gap-1">
                                <AlertTriangle className="w-3 h-3 shrink-0" />
                                Falta capturar qué material
                              </span>
                            ) : (
                              <span className="text-muted-foreground/60 italic text-[11px]">
                                Sin observaciones
                              </span>
                            )}
                          </div>
                        )}
                      </td>
                    </tr>

                    {/* FRANJA DE SUBPROCESO TINA (GÓNDOLA) */}
                    {fila.tina && tinaAbierta && (
                      <tr className="bg-primary/5 border-b border-primary/20">
                        {/* Columna sticky subproceso */}
                        <td className="sticky left-0 z-20 bg-primary/10 px-4 py-3 border-r border-primary/20">
                          <div className="pl-4 flex items-center gap-2">
                            <Layers className="w-4 h-4 text-primary shrink-0" />
                            <div>
                              <div className="text-xs font-bold text-foreground">
                                Subproceso: Ensamble de Tina
                              </div>
                              <div className="text-[10px] text-muted-foreground">
                                10 fases secuenciales
                              </div>
                            </div>
                          </div>
                        </td>

                        <td className="px-3 py-2 text-center text-xs text-muted-foreground border-r border-primary/20">
                          {fila.tina.terminadas}/{fila.tina.total}
                        </td>

                        <td className="px-3 py-2 text-center text-xs text-muted-foreground border-r border-primary/20">
                          —
                        </td>

                        {/* Celdas de las fases de Tina */}
                        <td
                          colSpan={fasesPrincipales.length + 1}
                          className="px-3 py-2 overflow-x-auto"
                        >
                          <div className="flex items-center gap-2 overflow-x-auto py-1">
                            {fasesTina.map((ft) => {
                              const celdaTina = fila.celdas?.[ft.id];
                              return (
                                <div key={ft.id} className="flex flex-col items-center gap-1 shrink-0">
                                  <span className="text-[10px] text-muted-foreground font-medium truncate max-w-[85px]" title={ft.nombre}>
                                    {ft.orden}. {ft.nombre}
                                  </span>
                                  <CeldaFaseMenu
                                    ordenId={fila.orden_id}
                                    etiquetaOrden={`${fila.etiqueta} (Tina)`}
                                    fase={ft}
                                    celda={celdaTina}
                                    hoy={hoy}
                                    onCambiarFase={onCambiarFase}
                                  />
                                </div>
                              );
                            })}
                          </div>
                        </td>
                      </tr>
                    )}
                  </React.Fragment>
                );
              })
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
