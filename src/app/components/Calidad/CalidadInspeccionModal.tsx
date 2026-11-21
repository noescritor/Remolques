import React, { useEffect, useMemo, useRef, useState } from 'react';
import {
  AlertTriangle,
  ArrowDown,
  Check,
  CheckCircle2,
  Loader2,
  Lock,
  Printer,
  RefreshCw,
  RotateCcw,
  Save,
  XCircle,
} from 'lucide-react';
import { toast } from 'sonner';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '../ui/dialog';
import { Button } from '../ui/button';
import { Input } from '../ui/input';
import { Label } from '../ui/label';
import { Badge } from '../ui/badge';
import { calidadApi } from './calidadApi';
import { CalidadImpresion } from './CalidadImpresion';
import {
  PlantillaCalidad,
  PlantillaGrupoCalidad,
  ResultadoInspeccionCalidad,
  ResultadoValor,
  agruparResultadosPorClave,
  armarLoteResultados,
  claveResultado,
  contarResumenGrupo,
  contarResumenPorPlantilla,
  normalizarConfigPlantilla,
  obtenerSiguienteNoConforme,
} from './calidadUtils';

interface CalidadInspeccionModalProps {
  inspeccionId: string | null;
  open: boolean;
  ajustes?: any;
  onClose: () => void;
  onActualizado?: () => void;
  onAbrirInspeccion?: (nuevoId: string) => void;
}

type EstadoGuardado = 'idle' | 'guardando' | 'guardado' | 'error';

export function CalidadInspeccionModal({
  inspeccionId,
  open,
  ajustes,
  onClose,
  onActualizado,
  onAbrirInspeccion,
}: CalidadInspeccionModalProps) {
  const [loading, setLoading] = useState(false);
  const [detalle, setDetalle] = useState<any>(null);
  const [operarios, setOperarios] = useState<any[]>([]);
  const [mapaResultados, setMapaResultados] = useState<Map<string, ResultadoInspeccionCalidad>>(new Map());
  const [pendientesMap, setPendientesMap] = useState<Map<string, ResultadoInspeccionCalidad>>(new Map());
  const [estadoGuardado, setEstadoGuardado] = useState<EstadoGuardado>('idle');
  const [errorGuardado, setErrorGuardado] = useState<string | null>(null);

  // Encabezado editable
  const [evaluadoPor, setEvaluadoPor] = useState('');
  const [fechaInicio, setFechaInicio] = useState('');
  const [fechaLiberacion, setFechaLiberacion] = useState('');
  const [liberadoPor, setLiberadoPor] = useState('');

  // Impresión y confirmaciones
  const [modoImpresion, setModoImpresion] = useState<null | { enBlanco: boolean }>(null);
  const [confirmCerrarOpen, setConfirmCerrarOpen] = useState(false);
  const [cerrando, setCerrando] = useState(false);
  const [confirmGrupoId, setConfirmGrupoId] = useState<string | null>(null);
  const [grupoDefaults, setGrupoDefaults] = useState<Record<string, { colaborador: string; fecha: string }>>({});
  const [cursorNoConforme, setCursorNoConforme] = useState<{ item_id: string; unidad: number } | null>(null);
  const [avisoCierreSinGuardar, setAvisoCierreSinGuardar] = useState(false);

  const timerRef = useRef<number | null>(null);
  const pendientesRef = useRef<Map<string, ResultadoInspeccionCalidad>>(new Map());
  const itemRefs = useRef<Map<string, HTMLDivElement>>(new Map());

  const hoyIso = new Date().toISOString().split('T')[0];

  const cargar = async () => {
    if (!inspeccionId) return;
    setLoading(true);
    try {
      const [det, ops] = await Promise.all([
        calidadApi.obtenerInspeccion(inspeccionId),
        calidadApi.listarOperarios().catch(() => []),
      ]);
      setDetalle(det);
      setOperarios(Array.isArray(ops) ? ops : []);
      const mapa = agruparResultadosPorClave(det.resultados || []);
      setMapaResultados(mapa);
      setPendientesMap(new Map());
      pendientesRef.current = new Map();
      setEstadoGuardado('idle');
      setErrorGuardado(null);

      setEvaluadoPor(det.inspeccion?.evaluado_por || '');
      setFechaInicio(det.inspeccion?.fecha_inicio || '');
      setFechaLiberacion(det.inspeccion?.fecha_liberacion || '');
      setLiberadoPor(det.inspeccion?.liberado_por || '');
    } catch (e: any) {
      toast.error(e.message || 'No se pudo cargar la inspección');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (open && inspeccionId) {
      cargar();
    }
    return () => {
      if (timerRef.current) window.clearTimeout(timerRef.current);
    };
  }, [open, inspeccionId]);

  const plantilla: PlantillaCalidad | null = detalle?.plantilla || null;
  const inspeccion = detalle?.inspeccion || null;
  const orden = detalle?.orden || null;
  const config = normalizarConfigPlantilla(plantilla?.config);
  const grupos: PlantillaGrupoCalidad[] = useMemo(
    () => [...(plantilla?.grupos || [])].sort((a, b) => a.orden - b.orden),
    [plantilla],
  );
  const esCerrada = inspeccion?.estado === 'cerrada';

  const resumen = useMemo(() => {
    if (!plantilla) return { total: 0, capturados: 0, conformes: 0, no_conformes: 0, no_aplica: 0, pendientes: 0 };
    return contarResumenPorPlantilla(grupos, config, mapaResultados);
  }, [grupos, config, mapaResultados, plantilla]);

  const enviarLotePendiente = async () => {
    if (!inspeccionId) return;
    const cambios = Array.from(pendientesRef.current.values());
    if (cambios.length === 0) return;

    const lote = armarLoteResultados(cambios);
    setEstadoGuardado('guardando');
    setErrorGuardado(null);
    try {
      await calidadApi.guardarResultados(inspeccionId, lote);
      // Limpiar solo los que se enviaron (si no cambiaron mientras viajaba)
      const restantes = new Map(pendientesRef.current);
      for (const item of cambios) {
        const key = claveResultado(item.item_id, item.unidad);
        if (restantes.get(key) === item) restantes.delete(key);
      }
      pendientesRef.current = restantes;
      setPendientesMap(restantes);
      setEstadoGuardado('guardado');
      onActualizado?.();
    } catch (e: any) {
      setEstadoGuardado('error');
      setErrorGuardado(e.message || 'Error al guardar resultados');
    }
  };

  const programarAutoguardado = () => {
    if (timerRef.current) window.clearTimeout(timerRef.current);
    timerRef.current = window.setTimeout(() => {
      enviarLotePendiente();
    }, 550);
  };

  const actualizarResultado = (
    itemId: string,
    unidad: number,
    patch: Partial<ResultadoInspeccionCalidad>,
  ) => {
    if (esCerrada) return;
    const key = claveResultado(itemId, unidad);
    const actual = mapaResultados.get(key) || {
      item_id: itemId,
      unidad,
      resultado: null,
      colaborador: '',
      fecha_inspeccion: '',
      observaciones: '',
    };

    const siguiente: ResultadoInspeccionCalidad = {
      ...actual,
      ...patch,
      item_id: itemId,
      unidad,
    };

    // Fecha hoy por omisión al marcar un resultado si estaba vacía
    if (patch.resultado && !siguiente.fecha_inspeccion) {
      siguiente.fecha_inspeccion = hoyIso;
    }

    const nuevoMapa = new Map(mapaResultados);
    if (siguiente.resultado === null) {
      nuevoMapa.delete(key);
    } else {
      nuevoMapa.set(key, siguiente);
    }
    setMapaResultados(nuevoMapa);

    const nuevosPend = new Map(pendientesRef.current);
    nuevosPend.set(key, siguiente);
    pendientesRef.current = nuevosPend;
    setPendientesMap(nuevosPend);
    programarAutoguardado();
  };

  const guardarEncabezado = async () => {
    if (!inspeccionId || esCerrada) return;
    setEstadoGuardado('guardando');
    try {
      await calidadApi.actualizarEncabezadoInspeccion(inspeccionId, {
        evaluado_por: evaluadoPor,
        fecha_inicio: fechaInicio || null,
        fecha_liberacion: fechaLiberacion || null,
        liberado_por: liberadoPor,
      });
      setEstadoGuardado('guardado');
      onActualizado?.();
    } catch (e: any) {
      setEstadoGuardado('error');
      setErrorGuardado(e.message || 'Error al guardar encabezado');
    }
  };

  const marcarGrupoConforme = (grupo: PlantillaGrupoCalidad) => {
    if (esCerrada) return;
    const def = grupoDefaults[grupo.id || String(grupo.orden)] || { colaborador: '', fecha: hoyIso };
    const nuevoMapa = new Map(mapaResultados);
    const nuevosPend = new Map(pendientesRef.current);

    for (const it of grupo.items || []) {
      if (!it.id) continue;
      for (let u = 1; u <= config.unidades.length; u++) {
        const key = claveResultado(it.id, u);
        const actual = nuevoMapa.get(key);
        const actualizado: ResultadoInspeccionCalidad = {
          ...(actual || { item_id: it.id, unidad: u }),
          item_id: it.id,
          unidad: u,
          resultado: 'conforme',
          colaborador: def.colaborador || actual?.colaborador || null,
          fecha_inspeccion: def.fecha || actual?.fecha_inspeccion || hoyIso,
          observaciones: actual?.observaciones || null,
        };
        nuevoMapa.set(key, actualizado);
        nuevosPend.set(key, actualizado);
      }
    }

    setMapaResultados(nuevoMapa);
    pendientesRef.current = nuevosPend;
    setPendientesMap(nuevosPend);
    setConfirmGrupoId(null);
    programarAutoguardado();
  };

  const aplicarColaboradorYFechaAGrupo = (grupo: PlantillaGrupoCalidad) => {
    if (esCerrada) return;
    const def = grupoDefaults[grupo.id || String(grupo.orden)];
    if (!def || (!def.colaborador && !def.fecha)) return;

    const nuevoMapa = new Map(mapaResultados);
    const nuevosPend = new Map(pendientesRef.current);
    let modificados = 0;

    for (const it of grupo.items || []) {
      if (!it.id) continue;
      for (let u = 1; u <= config.unidades.length; u++) {
        const key = claveResultado(it.id, u);
        const actual = nuevoMapa.get(key);
        if (!actual?.resultado) continue;
        const actualizado: ResultadoInspeccionCalidad = {
          ...actual,
          colaborador: def.colaborador || actual.colaborador || null,
          fecha_inspeccion: def.fecha || actual.fecha_inspeccion || hoyIso,
        };
        nuevoMapa.set(key, actualizado);
        nuevosPend.set(key, actualizado);
        modificados++;
      }
    }

    if (modificados > 0) {
      setMapaResultados(nuevoMapa);
      pendientesRef.current = nuevosPend;
      setPendientesMap(nuevosPend);
      programarAutoguardado();
      toast.success(`Aplicado a ${modificados} registros del grupo`);
    } else {
      toast.info('Marca primero los resultados del grupo o usa "Todo conforme".');
    }
  };

  const saltarASiguienteNoConforme = () => {
    const sig = obtenerSiguienteNoConforme(grupos, config.unidades.length, mapaResultados, cursorNoConforme);
    if (!sig) return;
    setCursorNoConforme({ item_id: sig.item_id, unidad: sig.unidad });
    const el = itemRefs.current.get(sig.item_id);
    el?.scrollIntoView({ behavior: 'smooth', block: 'center' });
  };

  const handleCerrarInspeccion = async () => {
    if (!inspeccionId) return;
    if (pendientesRef.current.size > 0) {
      await enviarLotePendiente();
    }
    setCerrando(true);
    try {
      const res = await calidadApi.cerrarInspeccion(inspeccionId, {
        liberado_por: liberadoPor || null,
        fecha_liberacion: fechaLiberacion || null,
      });
      setConfirmCerrarOpen(false);
      const adv = res?.advertencias;
      toast.success(
        `Inspección cerrada (${adv?.pendientes || 0} pendientes, ${adv?.no_conformes || 0} no conformes)`,
      );
      await cargar();
      onActualizado?.();
    } catch (e: any) {
      toast.error(e.message || 'No se pudo cerrar la inspección');
    } finally {
      setCerrando(false);
    }
  };

  const handleReabrir = async () => {
    if (!inspeccionId) return;
    try {
      await calidadApi.reabrirInspeccion(inspeccionId);
      toast.success('Inspección reabierta');
      await cargar();
      onActualizado?.();
    } catch (e: any) {
      toast.error(e.message || 'No se pudo reabrir la inspección');
    }
  };

  const handleReinspeccion = async () => {
    if (!inspeccion) return;
    try {
      const nueva = await calidadApi.crearInspeccion({
        orden_trabajo_id: inspeccion.orden_trabajo_id,
        formato: inspeccion.formato,
      });
      toast.success(`Re-inspección ${nueva.inspeccion.folio} creada`);
      onActualizado?.();
      if (onAbrirInspeccion && nueva?.inspeccion?.id) {
        onAbrirInspeccion(nueva.inspeccion.id);
      }
    } catch (e: any) {
      toast.error(e.message || 'No se pudo crear re-inspección');
    }
  };

  const intentarCerrarDialogo = () => {
    if (pendientesRef.current.size > 0) {
      setAvisoCierreSinGuardar(true);
      return;
    }
    onClose();
  };

  const progresoPct = resumen.total > 0 ? Math.round((resumen.capturados / resumen.total) * 100) : 0;

  return (
    <>
      <Dialog open={open} onOpenChange={(v) => { if (!v) intentarCerrarDialogo(); }}>
        <DialogContent className="w-[96vw] max-w-6xl sm:max-w-6xl h-[92vh] flex flex-col p-0 overflow-hidden bg-card border-border">
          {/* Encabezado fijo */}
          <DialogHeader className="px-4 sm:px-6 pt-4 pb-3 border-b border-border shrink-0 space-y-3">
            <div className="flex flex-wrap items-center justify-between gap-2 pr-8">
              <div>
                <DialogTitle className="text-lg font-bold text-foreground flex items-center gap-2 flex-wrap">
                  <span>{inspeccion?.folio || 'Inspección de Calidad'}</span>
                  <Badge variant="outline">
                    {inspeccion?.formato === 'control_total' ? 'Control Total' : 'Entrega'}
                  </Badge>
                  {inspeccion?.intento > 1 && (
                    <Badge variant="outline">Intento {inspeccion.intento}</Badge>
                  )}
                  <Badge
                    className={
                      esCerrada
                        ? 'bg-emerald-500/15 text-emerald-600 border-emerald-500/30'
                        : 'bg-blue-500/15 text-blue-600 border-blue-500/30'
                    }
                  >
                    {esCerrada ? 'Cerrada' : 'En proceso'}
                  </Badge>
                </DialogTitle>
                <DialogDescription className="text-xs sm:text-sm text-muted-foreground mt-1">
                  {orden?.modelo || orden?.etiqueta || 'Equipo'} · Cliente: {orden?.cliente_nombre || orden?.etiqueta || 'N/D'}
                  {orden?.niv ? ` · NIV: ${orden.niv}` : ''}
                  {plantilla ? ` · Plantilla: ${plantilla.nombre} (v${plantilla.version})` : ''}
                  {plantilla?.revision_formato ? ` · Rev: ${plantilla.revision_formato}` : ''}
                  {plantilla?.fecha_revision_formato ? ` (${plantilla.fecha_revision_formato})` : ''}
                </DialogDescription>
              </div>

              {/* Indicador de autoguardado */}
              <div className="flex items-center gap-2 text-xs">
                {estadoGuardado === 'guardando' && (
                  <span className="flex items-center gap-1 text-muted-foreground">
                    <Loader2 className="h-3.5 w-3.5 animate-spin" /> Guardando...
                  </span>
                )}
                {estadoGuardado === 'guardado' && (
                  <span className="flex items-center gap-1 text-emerald-600">
                    <Check className="h-3.5 w-3.5" /> Guardado
                  </span>
                )}
                {estadoGuardado === 'error' && (
                  <div className="flex items-center gap-2 text-destructive">
                    <span>{errorGuardado || 'Error al guardar'}</span>
                    <Button size="sm" variant="outline" onClick={enviarLotePendiente}>
                      <RefreshCw className="h-3.5 w-3.5 mr-1" /> Reintentar
                    </Button>
                  </div>
                )}
              </div>
            </div>

            {/* Datos de cabecera de inspección */}
            {inspeccion && (
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-2">
                <div>
                  <Label className="text-[11px] text-muted-foreground">Evaluado por</Label>
                  <Input
                    value={evaluadoPor}
                    disabled={esCerrada}
                    onChange={(e) => setEvaluadoPor(e.target.value)}
                    onBlur={guardarEncabezado}
                    placeholder="Nombre del evaluador"
                    className="h-8 text-xs"
                  />
                </div>
                <div>
                  <Label className="text-[11px] text-muted-foreground">Fecha inicio</Label>
                  <Input
                    type="date"
                    value={fechaInicio}
                    disabled={esCerrada}
                    onChange={(e) => setFechaInicio(e.target.value)}
                    onBlur={guardarEncabezado}
                    className="h-8 text-xs"
                  />
                </div>
                <div>
                  <Label className="text-[11px] text-muted-foreground">Liberado por</Label>
                  <Input
                    value={liberadoPor}
                    disabled={esCerrada}
                    onChange={(e) => setLiberadoPor(e.target.value)}
                    onBlur={guardarEncabezado}
                    placeholder="Nombre quien libera"
                    className="h-8 text-xs"
                  />
                </div>
                <div>
                  <Label className="text-[11px] text-muted-foreground">Fecha liberación</Label>
                  <Input
                    type="date"
                    value={fechaLiberacion}
                    disabled={esCerrada}
                    onChange={(e) => setFechaLiberacion(e.target.value)}
                    onBlur={guardarEncabezado}
                    className="h-8 text-xs"
                  />
                </div>
              </div>
            )}

            {/* Barra de progreso fija y resumen */}
            <div className="flex flex-wrap items-center gap-3 pt-1">
              <div className="flex-1 min-w-[180px]">
                <div className="flex justify-between text-xs mb-1">
                  <span className="font-medium text-foreground">
                    Progreso: {resumen.capturados} / {resumen.total} ({progresoPct}%)
                  </span>
                  <span className="text-muted-foreground">Pendientes: {resumen.pendientes}</span>
                </div>
                <div className="h-2 bg-muted rounded-full overflow-hidden">
                  <div
                    className="h-full bg-primary transition-all"
                    style={{ width: `${progresoPct}%` }}
                  />
                </div>
              </div>

              <div className="flex items-center gap-2">
                <Badge
                  variant="outline"
                  className={
                    resumen.no_conformes > 0
                      ? 'border-destructive text-destructive bg-destructive/10 font-semibold'
                      : 'text-muted-foreground'
                  }
                >
                  No conformes: {resumen.no_conformes}
                </Badge>
                {resumen.no_conformes > 0 && (
                  <Button size="sm" variant="outline" onClick={saltarASiguienteNoConforme}>
                    <ArrowDown className="h-3.5 w-3.5 mr-1" />
                    Siguiente no conforme
                  </Button>
                )}
              </div>
            </div>
          </DialogHeader>

          {/* Cuerpo con scroll interno */}
          <div className="flex-1 overflow-y-auto px-4 sm:px-6 py-4 space-y-5">
            {loading ? (
              <div className="flex items-center justify-center py-16 text-muted-foreground">
                <Loader2 className="h-6 w-6 animate-spin mr-2" /> Cargando inspección...
              </div>
            ) : !plantilla ? (
              <div className="text-center py-12 text-muted-foreground">No se encontró la plantilla.</div>
            ) : (
              grupos.map((grupo) => {
                const gKey = grupo.id || String(grupo.orden);
                const resGrupo = contarResumenGrupo(grupo, config.unidades.length, mapaResultados);
                const def = grupoDefaults[gKey] || { colaborador: '', fecha: hoyIso };

                return (
                  <div key={gKey} className="border border-border rounded-lg overflow-hidden bg-background">
                    {/* Cabecera de grupo */}
                    <div className="bg-muted/60 px-3 py-2.5 border-b border-border flex flex-col lg:flex-row lg:items-center justify-between gap-2">
                      <div className="flex items-center gap-2 flex-wrap">
                        <span className="font-bold text-sm text-foreground">
                          {plantilla.formato === 'control_total'
                            ? `PROCESO ${grupo.numero_original || grupo.orden}: ${grupo.nombre}`
                            : grupo.nombre}
                        </span>
                        <Badge variant="outline" className="text-xs">
                          {resGrupo.capturados}/{resGrupo.total}
                        </Badge>
                        {resGrupo.no_conformes > 0 && (
                          <Badge className="bg-destructive/15 text-destructive border-destructive/30 text-xs">
                            {resGrupo.no_conformes} no conf.
                          </Badge>
                        )}
                        {grupo.fase_confirmada === false && (
                          <Badge variant="outline" className="text-xs text-amber-600 border-amber-500/40">
                            Fase por confirmar
                          </Badge>
                        )}
                      </div>

                      {!esCerrada && (
                        <div className="flex flex-wrap items-center gap-2">
                          <Input
                            list={`operarios-list-${gKey}`}
                            placeholder="Colaborador grupo"
                            value={def.colaborador}
                            onChange={(e) =>
                              setGrupoDefaults((prev) => ({
                                ...prev,
                                [gKey]: { ...def, colaborador: e.target.value },
                              }))
                            }
                            className="h-8 w-40 text-xs"
                          />
                          <Input
                            type="date"
                            value={def.fecha}
                            onChange={(e) =>
                              setGrupoDefaults((prev) => ({
                                ...prev,
                                [gKey]: { ...def, fecha: e.target.value },
                              }))
                            }
                            className="h-8 w-36 text-xs"
                          />
                          <Button
                            size="sm"
                            variant="outline"
                            onClick={() => aplicarColaboradorYFechaAGrupo(grupo)}
                            className="h-8 text-xs"
                          >
                            Aplicar al grupo
                          </Button>
                          {confirmGrupoId === gKey ? (
                            <div className="flex items-center gap-1">
                              <Button
                                size="sm"
                                className="h-8 text-xs"
                                onClick={() => marcarGrupoConforme(grupo)}
                              >
                                Confirmar todo conforme
                              </Button>
                              <Button
                                size="sm"
                                variant="ghost"
                                className="h-8 text-xs"
                                onClick={() => setConfirmGrupoId(null)}
                              >
                                Cancelar
                              </Button>
                            </div>
                          ) : (
                            <Button
                              size="sm"
                              variant="secondary"
                              onClick={() => setConfirmGrupoId(gKey)}
                              className="h-8 text-xs"
                            >
                              <CheckCircle2 className="h-3.5 w-3.5 mr-1" />
                              Todo conforme
                            </Button>
                          )}
                        </div>
                      )}
                    </div>

                    {/* Lista de actividades (sin scroll horizontal en móvil/tableta) */}
                    <div className="divide-y divide-border/60">
                      {[...(grupo.items || [])]
                        .sort((a, b) => a.orden - b.orden)
                        .map((item) => {
                          const itemId = item.id!;
                          const tieneNoConforme = Array.from({ length: config.unidades.length }, (_, ui) =>
                            mapaResultados.get(claveResultado(itemId, ui + 1))?.resultado === 'no_conforme',
                          ).some(Boolean);

                          const primerRes = mapaResultados.get(claveResultado(itemId, 1));
                          const faltaObsNoConf = tieneNoConforme && !String(primerRes?.observaciones || '').trim();

                          return (
                            <div
                              key={itemId}
                              ref={(el) => {
                                if (el) itemRefs.current.set(itemId, el);
                                else itemRefs.current.delete(itemId);
                              }}
                              className={`p-3 space-y-2.5 ${
                                tieneNoConforme ? 'bg-destructive/5 border-l-4 border-l-destructive' : ''
                              }`}
                            >
                              <div className="flex flex-col md:flex-row md:items-start justify-between gap-3">
                                <div className="flex-1 min-w-0">
                                  <div className="text-sm text-foreground font-medium">
                                    <span className="font-mono text-xs text-muted-foreground mr-2">
                                      #{item.numero}
                                    </span>
                                    {item.texto}
                                    {item.aplica_si && (
                                      <span className="text-xs text-muted-foreground ml-1.5">
                                        ({item.aplica_si})
                                      </span>
                                    )}
                                  </div>
                                  {faltaObsNoConf && (
                                    <p className="text-xs text-destructive mt-1 flex items-center gap-1">
                                      <AlertTriangle className="h-3.5 w-3.5" />
                                      Agrega una observación para este punto no conforme.
                                    </p>
                                  )}
                                </div>

                                {/* Botones por unidad */}
                                <div className="flex flex-col gap-2 shrink-0">
                                  {config.unidades.map((uNombre, ui) => {
                                    const unidad = ui + 1;
                                    const res = mapaResultados.get(claveResultado(itemId, unidad));
                                    const val = res?.resultado || null;

                                    const toggle = (nuevo: ResultadoValor) => {
                                      actualizarResultado(itemId, unidad, {
                                        resultado: val === nuevo ? null : nuevo,
                                      });
                                    };

                                    return (
                                      <div key={unidad} className="flex flex-wrap items-center gap-1.5">
                                        {config.unidades.length > 1 && (
                                          <span className="text-xs font-medium text-muted-foreground w-16">
                                            {uNombre}:
                                          </span>
                                        )}
                                        <div className="inline-flex rounded-md border border-border overflow-hidden">
                                          <button
                                            type="button"
                                            disabled={esCerrada}
                                            onClick={() => toggle('conforme')}
                                            className={`min-h-[40px] px-3 text-xs sm:text-sm font-semibold transition-colors ${
                                              val === 'conforme'
                                                ? 'bg-emerald-600 text-white'
                                                : 'bg-card text-foreground hover:bg-muted'
                                            }`}
                                          >
                                            {config.etiquetas_resultado.conforme}
                                          </button>
                                          <button
                                            type="button"
                                            disabled={esCerrada}
                                            onClick={() => toggle('no_conforme')}
                                            className={`min-h-[40px] px-3 text-xs sm:text-sm font-semibold border-l border-border transition-colors ${
                                              val === 'no_conforme'
                                                ? 'bg-destructive text-destructive-foreground'
                                                : 'bg-card text-foreground hover:bg-muted'
                                            }`}
                                          >
                                            {config.etiquetas_resultado.no_conforme}
                                          </button>
                                          <button
                                            type="button"
                                            disabled={esCerrada}
                                            onClick={() => toggle('no_aplica')}
                                            className={`min-h-[40px] px-2.5 text-xs font-medium border-l border-border transition-colors ${
                                              val === 'no_aplica'
                                                ? 'bg-muted-foreground text-white'
                                                : 'bg-card text-muted-foreground hover:bg-muted'
                                            }`}
                                          >
                                            N/A
                                          </button>
                                        </div>
                                      </div>
                                    );
                                  })}
                                </div>
                              </div>

                              {/* Colaborador, fecha y observaciones */}
                              <div className="grid grid-cols-1 sm:grid-cols-3 gap-2">
                                <div>
                                  <Input
                                    list={`operarios-list-${gKey}`}
                                    disabled={esCerrada}
                                    placeholder="Colaborador responsable"
                                    value={primerRes?.colaborador || ''}
                                    onChange={(e) => {
                                      const opMatch = operarios.find((o) => o.nombre === e.target.value);
                                      actualizarResultado(itemId, 1, {
                                        colaborador: e.target.value,
                                        operario_id: opMatch?.id || null,
                                      });
                                    }}
                                    className="h-9 text-xs"
                                  />
                                </div>
                                <div>
                                  <Input
                                    type="date"
                                    disabled={esCerrada}
                                    value={primerRes?.fecha_inspeccion || ''}
                                    onChange={(e) =>
                                      actualizarResultado(itemId, 1, { fecha_inspeccion: e.target.value })
                                    }
                                    className="h-9 text-xs"
                                  />
                                </div>
                                <div>
                                  <Input
                                    disabled={esCerrada}
                                    placeholder="Observaciones (opcional)"
                                    value={primerRes?.observaciones || ''}
                                    onChange={(e) =>
                                      actualizarResultado(itemId, 1, { observaciones: e.target.value })
                                    }
                                    className="h-9 text-xs"
                                  />
                                </div>
                              </div>
                            </div>
                          );
                        })}
                    </div>

                    <datalist id={`operarios-list-${gKey}`}>
                      {operarios.map((op) => (
                        <option key={op.id} value={op.nombre} />
                      ))}
                    </datalist>
                  </div>
                );
              })
            )}
          </div>

          {/* Pie fijo */}
          <DialogFooter className="px-4 sm:px-6 py-3 border-t border-border shrink-0 flex flex-wrap items-center justify-between gap-2 bg-card">
            <div className="flex flex-wrap items-center gap-2">
              {plantilla && (
                <>
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => setModoImpresion({ enBlanco: false })}
                  >
                    <Printer className="h-4 w-4 mr-1.5" />
                    Imprimir
                  </Button>
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => setModoImpresion({ enBlanco: true })}
                  >
                    <Printer className="h-4 w-4 mr-1.5" />
                    Imprimir en blanco
                  </Button>
                </>
              )}
              {!esCerrada && pendientesMap.size > 0 && (
                <Button variant="outline" size="sm" onClick={enviarLotePendiente}>
                  <Save className="h-4 w-4 mr-1.5" />
                  Guardar ({pendientesMap.size})
                </Button>
              )}
            </div>

            <div className="flex flex-wrap items-center gap-2">
              {!esCerrada ? (
                <Button size="sm" onClick={() => setConfirmCerrarOpen(true)}>
                  <Lock className="h-4 w-4 mr-1.5" />
                  Cerrar inspección
                </Button>
              ) : (
                <>
                  <Button variant="outline" size="sm" onClick={handleReabrir}>
                    <RotateCcw className="h-4 w-4 mr-1.5" />
                    Reabrir
                  </Button>
                  <Button size="sm" onClick={handleReinspeccion}>
                    <RefreshCw className="h-4 w-4 mr-1.5" />
                    Nueva re-inspección
                  </Button>
                </>
              )}
              <Button variant="ghost" size="sm" onClick={intentarCerrarDialogo}>
                Salir
              </Button>
            </div>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Confirmación de cierre con advertencias (nunca bloquea por pendientes/no conformes) */}
      <Dialog open={confirmCerrarOpen} onOpenChange={setConfirmCerrarOpen}>
        <DialogContent className="max-w-md bg-card border-border">
          <DialogHeader>
            <DialogTitle>Cerrar inspección {inspeccion?.folio}</DialogTitle>
            <DialogDescription>
              {(resumen.pendientes > 0 || resumen.no_conformes > 0)
                ? 'Esta inspección tiene observaciones que solo sirven de aviso:'
                : 'Todos los puntos están capturados sin no conformidades.'}
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-2 text-sm">
            {resumen.pendientes > 0 && (
              <div className="flex items-center gap-2 p-2.5 rounded-md bg-amber-500/10 border border-amber-500/30 text-foreground">
                <AlertTriangle className="h-4 w-4 text-amber-600 shrink-0" />
                <span>Hay <strong>{resumen.pendientes}</strong> puntos pendientes por capturar.</span>
              </div>
            )}
            {resumen.no_conformes > 0 && (
              <div className="flex items-center gap-2 p-2.5 rounded-md bg-destructive/10 border border-destructive/30 text-destructive">
                <XCircle className="h-4 w-4 shrink-0" />
                <span>Hay <strong>{resumen.no_conformes}</strong> puntos marcados como No Conforme.</span>
              </div>
            )}
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setConfirmCerrarOpen(false)} disabled={cerrando}>
              Cancelar
            </Button>
            <Button onClick={handleCerrarInspeccion} disabled={cerrando}>
              {cerrando ? <Loader2 className="h-4 w-4 animate-spin mr-1.5" /> : null}
              Confirmar cierre
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Aviso si hay cambios pendientes al salir */}
      <Dialog open={avisoCierreSinGuardar} onOpenChange={setAvisoCierreSinGuardar}>
        <DialogContent className="max-w-md bg-card border-border">
          <DialogHeader>
            <DialogTitle>Cambios sin guardar</DialogTitle>
            <DialogDescription>
              Tienes {pendientesMap.size} cambios pendientes de sincronizar. ¿Deseas guardarlos antes de salir?
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button
              variant="outline"
              onClick={() => {
                setAvisoCierreSinGuardar(false);
                onClose();
              }}
            >
              Salir sin guardar
            </Button>
            <Button
              onClick={async () => {
                await enviarLotePendiente();
                setAvisoCierreSinGuardar(false);
                if (pendientesRef.current.size === 0) onClose();
              }}
            >
              Guardar y salir
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Vista de impresión */}
      {modoImpresion && plantilla && (
        <CalidadImpresion
          plantilla={plantilla}
          inspeccion={{
            ...inspeccion,
            evaluado_por: evaluadoPor,
            fecha_inicio: fechaInicio,
            fecha_liberacion: fechaLiberacion,
            liberado_por: liberadoPor,
          }}
          orden={orden}
          resultados={Array.from(mapaResultados.values())}
          ajustes={ajustes}
          enBlanco={modoImpresion.enBlanco}
          onCerrar={() => setModoImpresion(null)}
        />
      )}
    </>
  );
}
