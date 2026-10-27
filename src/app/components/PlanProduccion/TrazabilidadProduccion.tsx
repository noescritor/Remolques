import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '../ui/card';
import { Button } from '../ui/button';
import { Input } from '../ui/input';
import { Label } from '../ui/label';
import { Badge } from '../ui/badge';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../ui/select';
import {
  FileText,
  User,
  Calendar,
  Clock,
  Package,
  History,
  CheckCircle2,
  AlertTriangle,
  ArrowRight,
  Filter,
} from 'lucide-react';
import { toast } from 'sonner';
import { BASE_URL } from '../../utils/api';
import { supabase } from '../../utils/supabase/client';
import { OperarioRef } from '../../utils/planProduccion';

interface TrazabilidadProduccionProps {
  ordenesTrabajo: Array<{
    id: string;
    nomenclatura_id?: string;
    modelo?: string;
    cliente?: { nombre_razon_social?: string; nombre?: string };
    cotizacion?: { folio?: string };
  }>;
  operarios: OperarioRef[];
  ordenIdInicial?: string | null;
}

export function TrazabilidadProduccion({
  ordenesTrabajo,
  operarios,
  ordenIdInicial,
}: TrazabilidadProduccionProps) {
  const [subTab, setSubTab] = useState<'orden' | 'operario'>('orden');

  // Vista Por Orden
  const [ordenSeleccionadaId, setOrdenSeleccionadaId] = useState<string>(ordenIdInicial || '');
  const [cargandoOrden, setCargandoOrden] = useState(false);
  const [datosOrden, setDatosOrden] = useState<{
    orden: any;
    tareas: any[];
    bitacora: any[];
  } | null>(null);

  // Vista Por Operario
  const [operarioSeleccionadoId, setOperarioSeleccionadoId] = useState<string>('');
  const [fechaDesde, setFechaDesde] = useState('');
  const [fechaHasta, setFechaHasta] = useState('');
  const [cargandoOperario, setCargandoOperario] = useState(false);
  const [datosOperario, setDatosOperario] = useState<{
    operario: any;
    tareas: any[];
  } | null>(null);

  useEffect(() => {
    if (ordenIdInicial) {
      setOrdenSeleccionadaId(ordenIdInicial);
      setSubTab('orden');
    }
  }, [ordenIdInicial]);

  // Cargar trazabilidad de la orden seleccionada
  useEffect(() => {
    if (!ordenSeleccionadaId) {
      setDatosOrden(null);
      return;
    }

    const cargar = async () => {
      try {
        setCargandoOrden(true);
        const { data: { session } } = await supabase.auth.getSession();
        const token = session?.access_token;

        const res = await fetch(`${BASE_URL}/produccion/trazabilidad/orden/${ordenSeleccionadaId}`, {
          headers: { Authorization: `Bearer ${token}` },
        });

        if (!res.ok) {
          const err = await res.json().catch(() => ({}));
          throw new Error(err.error || 'Error al obtener trazabilidad');
        }

        const data = await res.json();
        setDatosOrden(data);
      } catch (err: any) {
        toast.error('Error al cargar trazabilidad de orden', { description: err.message });
      } finally {
        setCargandoOrden(false);
      }
    };

    cargar();
  }, [ordenSeleccionadaId]);

  // Cargar trazabilidad del operario seleccionado
  const cargarTrazabilidadOperario = async () => {
    if (!operarioSeleccionadoId) {
      toast.error('Selecciona un operario');
      return;
    }

    try {
      setCargandoOperario(true);
      const { data: { session } } = await supabase.auth.getSession();
      const token = session?.access_token;

      const params = new URLSearchParams();
      if (fechaDesde) params.append('desde', fechaDesde);
      if (fechaHasta) params.append('hasta', fechaHasta);

      const res = await fetch(
        `${BASE_URL}/produccion/trazabilidad/operario/${operarioSeleccionadoId}?${params.toString()}`,
        {
          headers: { Authorization: `Bearer ${token}` },
        }
      );

      if (!res.ok) {
        const err = await res.json().catch(() => ({}));
        throw new Error(err.error || 'Error al obtener tareas del operario');
      }

      const data = await res.json();
      setDatosOperario(data);
    } catch (err: any) {
      toast.error('Error al cargar trazabilidad del operario', { description: err.message });
    } finally {
      setCargandoOperario(false);
    }
  };

  const getEstadoBadge = (estado: string) => {
    switch (estado) {
      case 'terminada':
        return <Badge variant="outline" className="bg-accent-blue/15 text-accent-blue border-accent-blue/30 text-[10px]">Terminada</Badge>;
      case 'en_proceso':
        return <Badge variant="outline" className="bg-accent-green/15 text-accent-green border-accent-green/30 text-[10px]">En Proceso</Badge>;
      case 'pausada':
        return <Badge variant="outline" className="bg-accent-yellow/15 text-accent-yellow border-accent-yellow/30 text-[10px]">Pausada</Badge>;
      case 'cancelada':
        return <Badge variant="destructive" className="text-[10px]">Cancelada</Badge>;
      default:
        return <Badge variant="outline" className="text-[10px]">Planeada</Badge>;
    }
  };

  return (
    <div className="space-y-4">
      {/* Selector de Sub-pestaña */}
      <div className="bg-card border border-border/50 rounded-xl p-3 shadow-sm flex items-center justify-between">
        <div className="flex gap-2">
          <Button
            variant={subTab === 'orden' ? 'default' : 'outline'}
            size="sm"
            onClick={() => setSubTab('orden')}
            className={`text-xs gap-1.5 h-8 ${subTab === 'orden' ? 'bg-primary text-primary-foreground font-semibold' : ''}`}
          >
            <FileText className="w-3.5 h-3.5" />
            Por Orden de Trabajo
          </Button>
          <Button
            variant={subTab === 'operario' ? 'default' : 'outline'}
            size="sm"
            onClick={() => setSubTab('operario')}
            className={`text-xs gap-1.5 h-8 ${subTab === 'operario' ? 'bg-primary text-primary-foreground font-semibold' : ''}`}
          >
            <User className="w-3.5 h-3.5" />
            Por Operario de Taller
          </Button>
        </div>

        <span className="text-xs text-muted-foreground hidden sm:inline">
          Trazabilidad histórica de labores, materiales y eventos
        </span>
      </div>

      {/* ── SUB-PESTAÑA 1: POR ORDEN DE TRABAJO ── */}
      {subTab === 'orden' && (
        <div className="space-y-4">
          <Card className="border-border/50 bg-card">
            <CardHeader className="pb-3">
              <CardTitle className="text-sm font-bold flex items-center gap-2">
                <FileText className="w-4 h-4 text-primary" />
                Seleccionar Orden de Trabajo
              </CardTitle>
              <CardDescription className="text-xs">
                Visualiza cada fase, frente, operario y material involucrado en la fabricación del remolque.
              </CardDescription>
            </CardHeader>
            <CardContent>
              <div className="max-w-md">
                <Select value={ordenSeleccionadaId} onValueChange={setOrdenSeleccionadaId}>
                  <SelectTrigger className="bg-background text-xs">
                    <SelectValue placeholder="Selecciona una orden de trabajo..." />
                  </SelectTrigger>
                  <SelectContent>
                    {ordenesTrabajo.map((ot) => {
                      const cliente = ot.cliente?.nombre_razon_social || ot.cliente?.nombre || 'Cliente';
                      const folio = ot.nomenclatura_id || ot.cotizacion?.folio || 'OT';
                      return (
                        <SelectItem key={ot.id} value={ot.id} className="text-xs">
                          {folio} — {cliente} {ot.modelo ? `(${ot.modelo})` : ''}
                        </SelectItem>
                      );
                    })}
                  </SelectContent>
                </Select>
              </div>
            </CardContent>
          </Card>

          {cargandoOrden && (
            <div className="text-center py-10 text-muted-foreground text-xs">
              Cargando trazabilidad de la orden...
            </div>
          )}

          {datosOrden && !cargandoOrden && (
            <div className="space-y-4">
              {/* Resumen de la Orden */}
              <div className="bg-card border border-border/50 rounded-xl p-4 shadow-sm flex flex-wrap items-center justify-between gap-3 text-xs">
                <div>
                  <span className="text-muted-foreground">Folio / Nomenclatura:</span>
                  <p className="font-bold text-sm text-foreground">
                    {datosOrden.orden.nomenclatura_id || 'Sin Folio'}
                  </p>
                </div>
                <div>
                  <span className="text-muted-foreground">Modelo de Unidad:</span>
                  <p className="font-bold text-foreground">
                    {datosOrden.orden.modelo || 'Remolque Estándar'}
                  </p>
                </div>
                <div>
                  <span className="text-muted-foreground">Cliente:</span>
                  <p className="font-bold text-foreground">
                    {datosOrden.orden.cliente?.nombre_razon_social || 'Cliente'}
                  </p>
                </div>
                <div>
                  <span className="text-muted-foreground">Total de Tareas Ejecutadas:</span>
                  <p className="font-bold text-primary font-mono text-center">
                    {datosOrden.tareas.length}
                  </p>
                </div>
              </div>

              {/* Línea de Tiempo de Tareas */}
              <Card className="border-border/50 bg-card">
                <CardHeader className="pb-3">
                  <CardTitle className="text-sm font-bold flex items-center gap-2">
                    <History className="w-4 h-4 text-primary" />
                    Línea de Tiempo de Producción ({datosOrden.tareas.length} tareas)
                  </CardTitle>
                </CardHeader>
                <CardContent className="space-y-4">
                  {datosOrden.tareas.length > 0 ? (
                    <div className="relative pl-6 border-l-2 border-border/60 space-y-6">
                      {datosOrden.tareas.map((t, idx) => {
                        const opsTexto = (t.operarios || [])
                          .map((o: any) => o.nombre)
                          .filter(Boolean)
                          .join(', ');

                        return (
                          <div key={t.id || idx} className="relative group">
                            {/* Círculo indicador */}
                            <div className="absolute -left-[31px] top-1.5 w-4 h-4 rounded-full bg-background border-2 border-primary flex items-center justify-center">
                              <div className="w-1.5 h-1.5 rounded-full bg-primary" />
                            </div>

                            <div className="bg-background border border-border/60 rounded-xl p-3 shadow-xs space-y-2 text-xs">
                              <div className="flex flex-wrap items-center justify-between gap-2">
                                <div className="flex items-center gap-2">
                                  <span className="font-bold text-foreground">
                                    {t.fecha}
                                  </span>
                                  <Badge variant="secondary" className="text-[10px]">
                                    {t.frente?.area?.nombre || 'Área'} / {t.frente?.nombre || 'Frente'}
                                  </Badge>
                                </div>
                                <div>{getEstadoBadge(t.estado)}</div>
                              </div>

                              {t.descripcion && (
                                <p className="font-semibold text-foreground text-xs">
                                  {t.descripcion}
                                </p>
                              )}

                              <div className="grid grid-cols-1 sm:grid-cols-2 gap-2 text-muted-foreground text-[11px] pt-1 border-t border-border/30">
                                <div>
                                  <span className="font-bold text-foreground">Operarios: </span>
                                  <span>{opsTexto || 'Sin operario asignado'}</span>
                                </div>
                                {t.movilidad && (
                                  <div>
                                    <span className="font-bold text-foreground">Movilidad: </span>
                                    <span>{t.movilidad}</span>
                                  </div>
                                )}
                              </div>

                              {/* Materiales utilizados en esta tarea */}
                              {t.materiales && t.materiales.length > 0 && (
                                <div className="pt-1.5 border-t border-border/30">
                                  <span className="font-bold text-foreground text-[11px] flex items-center gap-1 mb-1">
                                    <Package className="w-3 h-3 text-primary" />
                                    Materiales requeridos:
                                  </span>
                                  <div className="flex flex-wrap gap-1">
                                    {t.materiales.map((m: any, mIdx: number) => (
                                      <Badge
                                        key={mIdx}
                                        variant="outline"
                                        className="text-[10px] bg-muted/30 font-normal"
                                      >
                                        {m.cantidad} {m.unidad} — {m.descripcion}
                                      </Badge>
                                    ))}
                                  </div>
                                </div>
                              )}

                              {/* Tiempos reales */}
                              {(t.inicio_real || t.fin_real) && (
                                <div className="text-[10px] text-muted-foreground flex gap-4 pt-1">
                                  {t.inicio_real && (
                                    <span>Inicio real: {new Date(t.inicio_real).toLocaleString()}</span>
                                  )}
                                  {t.fin_real && (
                                    <span className="text-accent-green font-medium">
                                      Fin real: {new Date(t.fin_real).toLocaleString()}
                                    </span>
                                  )}
                                </div>
                              )}
                            </div>
                          </div>
                        );
                      })}
                    </div>
                  ) : (
                    <p className="text-center text-muted-foreground text-xs py-4 italic">
                      No hay tareas de producción registradas para esta orden de trabajo
                    </p>
                  )}
                </CardContent>
              </Card>

              {/* Bitácora de Auditoría de la Orden */}
              {datosOrden.bitacora && datosOrden.bitacora.length > 0 && (
                <Card className="border-border/50 bg-card">
                  <CardHeader className="pb-3">
                    <CardTitle className="text-sm font-bold flex items-center gap-2">
                      <History className="w-4 h-4 text-muted-foreground" />
                      Bitácora de Modificaciones ({datosOrden.bitacora.length} eventos)
                    </CardTitle>
                  </CardHeader>
                  <CardContent>
                    <div className="space-y-1.5 text-[11px]">
                      {datosOrden.bitacora.map((ev: any, idx: number) => (
                        <div
                          key={ev.id || idx}
                          className="flex items-center justify-between p-2 rounded bg-muted/20 border border-border/30"
                        >
                          <div className="flex items-center gap-2">
                            <Badge variant="outline" className="text-[9px] uppercase">
                              {ev.evento}
                            </Badge>
                            <span className="font-medium text-foreground">
                              {ev.descripcion_tarea || 'Tarea'}
                            </span>
                            {ev.detalle?.estado_nuevo && (
                              <span className="text-muted-foreground">
                                → Cambio a {ev.detalle.estado_nuevo}
                              </span>
                            )}
                          </div>
                          <span className="text-muted-foreground font-mono text-[10px]">
                            {new Date(ev.creado_el).toLocaleString()}
                          </span>
                        </div>
                      ))}
                    </div>
                  </CardContent>
                </Card>
              )}
            </div>
          )}
        </div>
      )}

      {/* ── SUB-PESTAÑA 2: POR OPERARIO ── */}
      {subTab === 'operario' && (
        <div className="space-y-4">
          <Card className="border-border/50 bg-card">
            <CardHeader className="pb-3">
              <CardTitle className="text-sm font-bold flex items-center gap-2">
                <User className="w-4 h-4 text-primary" />
                Historial de Tareas por Operario
              </CardTitle>
              <CardDescription className="text-xs">
                Consulta en qué remolques, fechas y frentes ha colaborado un trabajador.
              </CardDescription>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-1 sm:grid-cols-4 gap-3">
                <div className="sm:col-span-2">
                  <Label className="text-xs font-semibold">Operario *</Label>
                  <Select value={operarioSeleccionadoId} onValueChange={setOperarioSeleccionadoId}>
                    <SelectTrigger className="bg-background text-xs mt-1">
                      <SelectValue placeholder="Selecciona un operario..." />
                    </SelectTrigger>
                    <SelectContent>
                      {operarios.map((o) => (
                        <SelectItem key={o.id} value={o.id} className="text-xs">
                          {o.nombre} {o.puesto ? `(${o.puesto})` : ''}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>

                <div>
                  <Label className="text-xs font-semibold">Desde (Opcional)</Label>
                  <Input
                    type="date"
                    value={fechaDesde}
                    onChange={(e) => setFechaDesde(e.target.value)}
                    className="bg-background text-xs mt-1"
                  />
                </div>

                <div>
                  <Label className="text-xs font-semibold">Hasta (Opcional)</Label>
                  <div className="flex gap-2 mt-1">
                    <Input
                      type="date"
                      value={fechaHasta}
                      onChange={(e) => setFechaHasta(e.target.value)}
                      className="bg-background text-xs"
                    />
                    <Button
                      type="button"
                      size="sm"
                      onClick={cargarTrazabilidadOperario}
                      disabled={cargandoOperario || !operarioSeleccionadoId}
                      className="text-xs bg-primary text-primary-foreground shrink-0"
                    >
                      <Filter className="w-3 h-3 mr-1" />
                      Filtrar
                    </Button>
                  </div>
                </div>
              </div>
            </CardContent>
          </Card>

          {cargandoOperario && (
            <div className="text-center py-10 text-muted-foreground text-xs">
              Cargando tareas del operario...
            </div>
          )}

          {datosOperario && !cargandoOperario && (
            <Card className="border-border/50 bg-card">
              <CardHeader className="pb-3">
                <CardTitle className="text-sm font-bold flex items-center justify-between">
                  <span>
                    Tareas Asignadas a {datosOperario.operario?.nombre} ({datosOperario.tareas.length})
                  </span>
                  {datosOperario.operario?.puesto && (
                    <Badge variant="outline" className="text-xs font-normal">
                      {datosOperario.operario.puesto}
                    </Badge>
                  )}
                </CardTitle>
              </CardHeader>
              <CardContent>
                {datosOperario.tareas.length > 0 ? (
                  <div className="space-y-2">
                    {datosOperario.tareas.map((t, idx) => (
                      <div
                        key={t.id || idx}
                        className="p-3 rounded-lg border border-border/50 bg-background text-xs space-y-1.5"
                      >
                        <div className="flex justify-between items-start">
                          <div>
                            <span className="font-bold text-foreground">{t.fecha}</span>
                            <span className="text-muted-foreground mx-1.5">•</span>
                            <span className="font-medium text-primary">
                              {t.frente?.area?.nombre} / {t.frente?.nombre}
                            </span>
                          </div>
                          <div>{getEstadoBadge(t.estado)}</div>
                        </div>

                        {t.descripcion && (
                          <p className="font-semibold text-foreground text-xs">{t.descripcion}</p>
                        )}

                        {t.orden_trabajo && (
                          <p className="text-[11px] text-muted-foreground">
                            OT: <span className="font-mono text-foreground">{t.orden_trabajo.nomenclatura_id || t.orden_trabajo.modelo}</span>
                          </p>
                        )}

                        {t.materiales && t.materiales.length > 0 && (
                          <div className="text-[10px] text-muted-foreground flex gap-1 items-center flex-wrap">
                            <Package className="w-3 h-3 text-muted-foreground/70" />
                            {t.materiales.map((m: any, mIdx: number) => (
                              <span key={mIdx} className="bg-muted px-1.5 py-0.2 rounded">
                                {m.cantidad} {m.unidad} {m.descripcion}
                              </span>
                            ))}
                          </div>
                        )}
                      </div>
                    ))}
                  </div>
                ) : (
                  <p className="text-center text-muted-foreground text-xs py-6 italic">
                    No se encontraron tareas registradas para este operario en el periodo seleccionado
                  </p>
                )}
              </CardContent>
            </Card>
          )}
        </div>
      )}
    </div>
  );
}
