import React, { useMemo } from 'react';
import { Card, CardContent } from '../ui/card';
import { Button } from '../ui/button';
import { Badge } from '../ui/badge';
import { Switch } from '../ui/switch';
import {
  ChevronLeft,
  ChevronRight,
  Calendar,
  Copy,
  Printer,
  Plus,
  AlertTriangle,
  Clock,
  Package,
  Truck,
  CheckCircle2,
  PauseCircle,
  FileText,
} from 'lucide-react';
import {
  PlanTarea,
  diasDeSemana,
  etiquetaDia,
  rangoSemanaTexto,
  totalesPersonal,
  detectarConflictos,
  agruparPlan,
  EstadoPlanTarea,
} from '../../utils/planProduccion';

interface CuadriculaSemanalProps {
  areas: Array<{
    id: string;
    clave: string;
    nombre: string;
    frentes: Array<{ id: string; nombre: string; orden: number }>;
  }>;
  areaSeleccionadaId: string;
  onSeleccionarArea: (areaId: string) => void;
  lunesActual: string;
  onCambiarLunes: (nuevoLunes: string) => void;
  mostrarSabado: boolean;
  onToggleMostrarSabado: (mostrar: boolean) => void;
  tareas: PlanTarea[];
  cargando: boolean;
  onNuevaTarea: (dia?: string, frenteId?: string) => void;
  onEditarTarea: (tarea: PlanTarea) => void;
  onDuplicarSemana: () => void;
  onImprimir: () => void;
}

export function CuadriculaSemanal({
  areas,
  areaSeleccionadaId,
  onSeleccionarArea,
  lunesActual,
  onCambiarLunes,
  mostrarSabado,
  onToggleMostrarSabado,
  tareas,
  cargando,
  onNuevaTarea,
  onEditarTarea,
  onDuplicarSemana,
  onImprimir,
}: CuadriculaSemanalProps) {
  const areaActiva = useMemo(() => {
    return areas.find((a) => a.id === areaSeleccionadaId) || areas[0];
  }, [areas, areaSeleccionadaId]);

  const frentesActivos = useMemo(() => {
    return areaActiva?.frentes || [];
  }, [areaActiva]);

  const dias = useMemo(() => {
    return diasDeSemana(lunesActual, { sabado: mostrarSabado });
  }, [lunesActual, mostrarSabado]);

  const rangoTexto = useMemo(() => {
    return rangoSemanaTexto(lunesActual, { sabado: mostrarSabado });
  }, [lunesActual, mostrarSabado]);

  const mapaTareas = useMemo(() => {
    return agruparPlan(tareas);
  }, [tareas]);

  const totales = useMemo(() => {
    return totalesPersonal(tareas);
  }, [tareas]);

  const conflictos = useMemo(() => {
    return detectarConflictos(tareas);
  }, [tareas]);

  // Navegación de semana
  const irSemanaAnterior = () => {
    const d = new Date(lunesActual + 'T12:00:00Z');
    d.setDate(d.getDate() - 7);
    onCambiarLunes(d.toISOString().split('T')[0]);
  };

  const irSemanaSiguiente = () => {
    const d = new Date(lunesActual + 'T12:00:00Z');
    d.setDate(d.getDate() + 7);
    onCambiarLunes(d.toISOString().split('T')[0]);
  };

  const irHoy = () => {
    const hoy = new Date();
    const diaSem = hoy.getDay();
    const restar = diaSem === 0 ? 6 : diaSem - 1;
    hoy.setDate(hoy.getDate() - restar);
    onCambiarLunes(hoy.toISOString().split('T')[0]);
  };

  const getEstadoBadgeClass = (estado: EstadoPlanTarea) => {
    switch (estado) {
      case 'en_proceso':
        return 'bg-accent-green/20 text-accent-green border-accent-green/30';
      case 'pausada':
        return 'bg-accent-yellow/20 text-accent-yellow border-accent-yellow/30';
      case 'terminada':
        return 'bg-accent-blue/20 text-accent-blue border-accent-blue/30';
      case 'cancelada':
        return 'bg-destructive/20 text-destructive border-destructive/30';
      case 'planeada':
      default:
        return 'bg-muted/40 text-muted-foreground border-border/50';
    }
  };

  const getEstadoIcon = (estado: EstadoPlanTarea) => {
    switch (estado) {
      case 'en_proceso':
        return <Clock className="w-2.5 h-2.5 mr-0.5" />;
      case 'terminada':
        return <CheckCircle2 className="w-2.5 h-2.5 mr-0.5" />;
      case 'pausada':
        return <PauseCircle className="w-2.5 h-2.5 mr-0.5" />;
      default:
        return null;
    }
  };

  return (
    <div className="space-y-4">
      {/* 1. Barra Superior: Selector de Áreas, Navegación de Semana y Acciones */}
      <div className="bg-card border border-border/50 rounded-xl p-4 shadow-sm flex flex-col lg:flex-row lg:items-center justify-between gap-4">
        {/* Selector de Áreas (Pills) */}
        <div className="flex items-center gap-1.5 overflow-x-auto pb-1 lg:pb-0 scrollbar-none">
          {areas.map((a) => {
            const esActiva = a.id === areaActiva?.id;
            return (
              <button
                key={a.id}
                type="button"
                onClick={() => onSeleccionarArea(a.id)}
                className={`px-3 py-1.5 rounded-lg text-xs font-semibold whitespace-nowrap transition-colors border ${
                  esActiva
                    ? 'bg-primary text-primary-foreground border-primary shadow-sm'
                    : 'bg-muted/30 hover:bg-muted text-muted-foreground hover:text-foreground border-border/40'
                }`}
              >
                {a.nombre}
              </button>
            );
          })}
        </div>

        {/* Navegación y Rango de Fecha */}
        <div className="flex flex-wrap items-center gap-2">
          <div className="flex items-center border border-border/60 rounded-lg bg-background p-0.5">
            <Button
              variant="ghost"
              size="icon"
              onClick={irSemanaAnterior}
              className="h-7 w-7 text-muted-foreground hover:text-foreground"
              title="Semana anterior"
            >
              <ChevronLeft className="w-4 h-4" />
            </Button>
            <Button
              variant="ghost"
              size="sm"
              onClick={irHoy}
              className="h-7 px-2 text-xs font-medium text-muted-foreground hover:text-foreground"
            >
              Hoy
            </Button>
            <Button
              variant="ghost"
              size="icon"
              onClick={irSemanaSiguiente}
              className="h-7 w-7 text-muted-foreground hover:text-foreground"
              title="Semana siguiente"
            >
              <ChevronRight className="w-4 h-4" />
            </Button>
          </div>

          <div className="flex items-center gap-1.5 border border-border/60 rounded-lg px-2.5 py-1 bg-background">
            <Calendar className="w-3.5 h-3.5 text-primary" />
            <span className="text-xs font-bold text-foreground tracking-wide uppercase">
              {rangoTexto}
            </span>
          </div>

          {/* Toggle Sábado */}
          <div className="flex items-center space-x-1.5 px-2 py-1 bg-muted/20 border border-border/40 rounded-lg text-xs text-muted-foreground">
            <Switch
              id="switch-sabado"
              checked={mostrarSabado}
              onCheckedChange={onToggleMostrarSabado}
              className="scale-75"
            />
            <label htmlFor="switch-sabado" className="cursor-pointer text-[11px] select-none">
              Sábado
            </label>
          </div>

          {/* Botones de Acción */}
          <Button
            variant="outline"
            size="sm"
            onClick={onDuplicarSemana}
            className="h-8 text-xs gap-1.5 border-border/60"
            title="Duplicar semana a semana siguiente"
          >
            <Copy className="w-3.5 h-3.5" />
            <span className="hidden sm:inline">Duplicar semana</span>
          </Button>

          <Button
            variant="outline"
            size="sm"
            onClick={onImprimir}
            className="h-8 text-xs gap-1.5 border-border/60"
            title="Imprimir plan en formato horizontal"
          >
            <Printer className="w-3.5 h-3.5" />
            <span className="hidden sm:inline">Imprimir</span>
          </Button>

          <Button
            size="sm"
            onClick={() => onNuevaTarea()}
            className="h-8 text-xs gap-1.5 bg-primary text-primary-foreground font-semibold shadow-sm"
          >
            <Plus className="w-3.5 h-3.5" />
            Nueva Tarea
          </Button>
        </div>
      </div>

      {/* 2. Banner de Conflictos (si existen operarios en más de una tarea el mismo día) */}
      {conflictos.length > 0 && (
        <div className="bg-accent-yellow/15 border border-accent-yellow/30 text-accent-yellow rounded-xl p-3 text-xs flex items-center justify-between">
          <div className="flex items-center gap-2">
            <AlertTriangle className="w-4 h-4 shrink-0" />
            <span>
              <strong>Aviso de planeación:</strong> Se detectaron {conflictos.length} operario(s) asignados a más de una tarea en el mismo día.
            </span>
          </div>
          <Badge variant="outline" className="text-[10px] border-accent-yellow/40 text-accent-yellow bg-accent-yellow/10">
            {conflictos.length} coincidencia(s)
          </Badge>
        </div>
      )}

      {/* 3. Cuadrícula de Producción (Escritorio / Tablet) */}
      <div className="hidden md:block bg-card border border-border/50 rounded-xl overflow-x-auto shadow-sm">
        <table className="w-full border-collapse table-fixed text-xs">
          <thead>
            <tr className="bg-muted/40 border-b border-border/60">
              <th className="p-2.5 text-center font-bold text-foreground border-r border-border/40 w-32">
                Día / Frente
              </th>
              {frentesActivos.map((f) => (
                <th
                  key={f.id}
                  className="p-2.5 text-center font-bold text-foreground uppercase border-r border-border/40 truncate tracking-wide"
                  title={f.nombre}
                >
                  {f.nombre}
                </th>
              ))}
              <th className="p-2.5 text-center font-bold text-foreground w-16" title="Total de operarios distintos del día">
                TOT
              </th>
            </tr>
          </thead>
          <tbody>
            {dias.map((dia) => {
              const totDia = totales.porDia[dia] || 0;
              return (
                <tr key={dia} className="border-b border-border/40 align-top hover:bg-muted/5 transition-colors">
                  {/* Columna Día */}
                  <td className="p-2.5 font-bold text-center bg-muted/20 border-r border-border/40 select-none">
                    <div className="text-xs uppercase tracking-wide">{etiquetaDia(dia).split(' ')[0]}</div>
                    <div className="text-[11px] text-muted-foreground font-mono mt-0.5">
                      {etiquetaDia(dia).split(' ')[1]}
                    </div>
                  </td>

                  {/* Celdas de cada Frente */}
                  {frentesActivos.map((f) => {
                    const tareasCelda = (mapaTareas[dia] && mapaTareas[dia][f.id]) || [];

                    return (
                      <td
                        key={f.id}
                        className="p-1.5 border-r border-border/40 min-h-[90px] relative group"
                      >
                        <div className="space-y-1.5 min-h-[70px]">
                          {tareasCelda.map((t) => {
                            const opsTexto = (t.operarios || [])
                              .map((o: any) => (typeof o === 'string' ? o : o.nombre))
                              .filter(Boolean)
                              .join(', ');

                            return (
                              <div
                                key={t.id}
                                onClick={() => onEditarTarea(t)}
                                className="p-2 rounded-lg border border-border/60 bg-background hover:border-primary/60 cursor-pointer shadow-xs transition-all hover:shadow-sm space-y-1"
                              >
                                {/* Cabecera de Tarjeta: Estado y Falta Material */}
                                <div className="flex items-center justify-between gap-1">
                                  <Badge
                                    variant="outline"
                                    className={`text-[9px] px-1 py-0 border flex items-center ${getEstadoBadgeClass(t.estado)}`}
                                  >
                                    {getEstadoIcon(t.estado)}
                                    <span className="capitalize">{t.estado.replace('_', ' ')}</span>
                                  </Badge>

                                  {t.material_faltante && (
                                    <Badge
                                      variant="destructive"
                                      className="text-[9px] px-1 py-0 gap-0.5 bg-destructive/15 text-destructive border-destructive/30"
                                      title="Material Faltante"
                                    >
                                      <AlertTriangle className="w-2.5 h-2.5" />
                                      <span>Falta material</span>
                                    </Badge>
                                  )}
                                </div>

                                {/* Descripción / Labor */}
                                {t.descripcion && (
                                  <div className="font-semibold text-foreground text-[11px] line-clamp-2 leading-tight">
                                    {t.descripcion}
                                  </div>
                                )}

                                {/* Orden de Trabajo si existe */}
                                {t.orden_trabajo && (
                                  <div className="text-[10px] text-primary font-mono bg-primary/10 px-1 py-0.5 rounded flex items-center gap-1 w-fit">
                                    <FileText className="w-2.5 h-2.5" />
                                    <span>
                                      {t.orden_trabajo.nomenclatura_id || t.orden_trabajo.modelo || 'OT'}
                                    </span>
                                  </div>
                                )}

                                {/* Operarios */}
                                <div className="text-[10px] text-muted-foreground flex items-center gap-1 truncate">
                                  <span className="font-bold text-foreground">OP:</span>
                                  <span className="truncate">{opsTexto || 'Sin operario'}</span>
                                </div>

                                {/* Movilidad si existe */}
                                {t.movilidad && (
                                  <div className="text-[9px] text-muted-foreground bg-muted/40 px-1 py-0.2 rounded flex items-center gap-1 w-fit">
                                    <Truck className="w-2.5 h-2.5" />
                                    <span>{t.movilidad}</span>
                                  </div>
                                )}

                                {/* Materiales count */}
                                {t.materiales && t.materiales.length > 0 && (
                                  <div className="text-[9px] text-muted-foreground flex items-center gap-1">
                                    <Package className="w-2.5 h-2.5" />
                                    <span>{t.materiales.length} material(es)</span>
                                  </div>
                                )}
                              </div>
                            );
                          })}

                          {/* Botón flotante para agregar tarea en esta celda */}
                          <button
                            type="button"
                            onClick={() => onNuevaTarea(dia, f.id)}
                            className="w-full py-1 text-center text-muted-foreground/40 hover:text-primary hover:bg-primary/5 rounded border border-dashed border-transparent hover:border-primary/30 transition-all opacity-0 group-hover:opacity-100 text-[11px] flex items-center justify-center gap-1"
                            title={`Crear tarea en ${f.nombre} el ${etiquetaDia(dia)}`}
                          >
                            <Plus className="w-3 h-3" />
                            <span>Agregar</span>
                          </button>
                        </div>
                      </td>
                    );
                  })}

                  {/* Columna TOT (Operarios distintos del día) */}
                  <td className="p-2.5 font-bold text-center bg-muted/20 align-middle text-sm text-foreground">
                    {totDia}
                  </td>
                </tr>
              );
            })}
          </tbody>
          <tfoot>
            <tr className="bg-muted/40 font-bold border-t border-border/60">
              <td className="p-2.5 text-center uppercase text-foreground">
                TOTAL DE PERSONAL
              </td>
              {frentesActivos.map((f) => {
                const totFrente = totales.porFrente[f.id] || 0;
                return (
                  <td key={f.id} className="p-2.5 text-center text-foreground font-mono">
                    {totFrente}
                  </td>
                );
              })}
              <td className="p-2.5 text-center bg-muted/70 text-foreground font-bold text-sm" title="Total asignaciones de la semana">
                {totales.totalAsignaciones}
              </td>
            </tr>
          </tfoot>
        </table>
      </div>

      {/* 4. Vista Móvil: Lista por Día */}
      <div className="md:hidden space-y-3">
        {dias.map((dia) => {
          const totDia = totales.porDia[dia] || 0;
          return (
            <Card key={dia} className="border-border/50 bg-card">
              <div className="bg-muted/30 px-3 py-2 border-b border-border/40 flex justify-between items-center">
                <span className="font-bold text-xs uppercase text-foreground">
                  {etiquetaDia(dia)}
                </span>
                <Badge variant="outline" className="text-[10px]">
                  TOT: {totDia} operarios
                </Badge>
              </div>
              <CardContent className="p-3 space-y-2">
                {frentesActivos.map((f) => {
                  const tareasFrente = (mapaTareas[dia] && mapaTareas[dia][f.id]) || [];
                  return (
                    <div key={f.id} className="border-b border-border/30 pb-2 last:border-b-0 last:pb-0">
                      <div className="flex justify-between items-center mb-1">
                        <span className="text-[11px] font-bold text-primary uppercase">
                          {f.nombre}
                        </span>
                        <Button
                          variant="ghost"
                          size="sm"
                          onClick={() => onNuevaTarea(dia, f.id)}
                          className="h-5 px-1.5 text-[10px] text-muted-foreground"
                        >
                          + Añadir
                        </Button>
                      </div>

                      {tareasFrente.length === 0 ? (
                        <p className="text-[11px] text-muted-foreground/60 italic">Sin tareas</p>
                      ) : (
                        <div className="space-y-1.5">
                          {tareasFrente.map((t) => (
                            <div
                              key={t.id}
                              onClick={() => onEditarTarea(t)}
                              className="p-2 rounded border border-border/60 bg-background text-xs space-y-1"
                            >
                              <div className="flex justify-between items-start">
                                <span className="font-medium text-foreground">
                                  {t.descripcion || 'Labor sin descripción'}
                                </span>
                                <Badge variant="outline" className={`text-[9px] ${getEstadoBadgeClass(t.estado)}`}>
                                  {t.estado}
                                </Badge>
                              </div>
                              <div className="text-[10px] text-muted-foreground">
                                OP: {(t.operarios || []).map((o: any) => o.nombre || o).join(', ') || 'Sin asignar'}
                              </div>
                            </div>
                          ))}
                        </div>
                      )}
                    </div>
                  );
                })}
              </CardContent>
            </Card>
          );
        })}
      </div>
    </div>
  );
}
