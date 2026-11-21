import React, { useEffect, useState } from 'react';
import {
  AlertCircle,
  CheckCircle2,
  ClipboardCheck,
  ExternalLink,
  Loader2,
  Play,
  RefreshCw,
} from 'lucide-react';
import { toast } from 'sonner';
import { Button } from '../ui/button';
import { Badge } from '../ui/badge';
import { Card, CardContent, CardHeader, CardTitle } from '../ui/card';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../ui/select';
import { calidadApi, CalidadApiError } from './calidadApi';
import { CalidadInspeccionModal } from './CalidadInspeccionModal';
import {
  FormatoCalidad,
  PlantillaCalidad,
  resolverPlantillaSugerida,
} from './calidadUtils';

interface OrdenCalidadTabProps {
  orden: {
    id: string;
    etiqueta?: string | null;
    modelo?: string | null;
    tipo_equipo?: string | null;
    linea_producto_id?: string | null;
  };
  ajustes?: any;
  onIrAPlantillas?: () => void;
  onActualizado?: () => void;
}

export function OrdenCalidadTab({
  orden,
  ajustes,
  onIrAPlantillas,
  onActualizado,
}: OrdenCalidadTabProps) {
  const [loading, setLoading] = useState(true);
  const [inspecciones, setInspecciones] = useState<any[]>([]);
  const [plantillasActivas, setPlantillasActivas] = useState<PlantillaCalidad[]>([]);
  const [plantillaSeleccionada, setPlantillaSeleccionada] = useState<Record<FormatoCalidad, string>>({
    control_total: '',
    entrega: '',
  });
  const [creandoFormato, setCreandoFormato] = useState<FormatoCalidad | null>(null);
  const [inspeccionAbiertaId, setInspeccionAbiertaId] = useState<string | null>(null);

  const cargar = async () => {
    setLoading(true);
    try {
      const [insps, pls] = await Promise.all([
        calidadApi.listarInspecciones({ orden_trabajo_id: orden.id }),
        calidadApi.listarPlantillas({ estado: 'activa' }),
      ]);
      setInspecciones(Array.isArray(insps) ? insps : []);
      const activas = Array.isArray(pls) ? pls : [];
      setPlantillasActivas(activas);

      const sugCt = resolverPlantillaSugerida(orden, activas, 'control_total');
      const sugEnt = resolverPlantillaSugerida(orden, activas, 'entrega');
      setPlantillaSeleccionada({
        control_total: sugCt?.id || '',
        entrega: sugEnt?.id || '',
      });
    } catch (e: any) {
      toast.error(e.message || 'No se pudo cargar calidad de la orden');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (orden?.id) cargar();
  }, [orden?.id]);

  const iniciarInspeccion = async (formato: FormatoCalidad) => {
    setCreandoFormato(formato);
    try {
      const selId = plantillaSeleccionada[formato] || null;
      const creada = await calidadApi.crearInspeccion({
        orden_trabajo_id: orden.id,
        formato,
        plantilla_id: selId,
      });
      toast.success(`Inspección ${creada.inspeccion.folio} iniciada`);
      await cargar();
      onActualizado?.();
      setInspeccionAbiertaId(creada.inspeccion.id);
    } catch (e: any) {
      if (e instanceof CalidadApiError && e.codigo === 'YA_EXISTE' && e.inspeccionId) {
        toast.info('Ya existe una inspección en proceso; abriéndola.');
        setInspeccionAbiertaId(e.inspeccionId);
      } else {
        toast.error(e.message || 'No se pudo iniciar la inspección');
      }
    } finally {
      setCreandoFormato(null);
    }
  };

  const renderTarjeta = (formato: FormatoCalidad, titulo: string) => {
    const listaFormato = inspecciones
      .filter((i) => i.formato === formato)
      .sort((a, b) => (b.intento || 0) - (a.intento || 0));
    const vigente = listaFormato[0] || null;
    const opcionesFormato = plantillasActivas.filter((p) => p.formato === formato);
    const sug = resolverPlantillaSugerida(orden, plantillasActivas, formato);
    const selId = plantillaSeleccionada[formato];

    return (
      <Card key={formato} className="bg-background border-border">
        <CardHeader className="pb-2">
          <CardTitle className="text-sm font-semibold flex items-center justify-between gap-2">
            <span className="flex items-center gap-2">
              <ClipboardCheck className="h-4 w-4 text-primary" />
              {titulo}
            </span>
            {vigente && (
              <Badge
                className={
                  vigente.estado === 'cerrada'
                    ? 'bg-emerald-500/15 text-emerald-600 border-emerald-500/30'
                    : 'bg-blue-500/15 text-blue-600 border-blue-500/30'
                }
              >
                {vigente.estado === 'cerrada' ? 'Cerrada' : 'En proceso'}
              </Badge>
            )}
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-3 text-sm">
          {vigente ? (
            <>
              <div className="flex flex-wrap items-center justify-between gap-2 text-xs">
                <span className="font-mono font-semibold text-foreground">
                  {vigente.folio} (Intento {vigente.intento})
                </span>
                {vigente.resumen && (
                  <div className="flex items-center gap-2">
                    <span className="text-muted-foreground">
                      Progreso: {vigente.resumen.capturados}/{vigente.resumen.total}
                    </span>
                    {vigente.resumen.no_conformes > 0 && (
                      <Badge className="bg-destructive/15 text-destructive border-destructive/30">
                        {vigente.resumen.no_conformes} no conf.
                      </Badge>
                    )}
                  </div>
                )}
              </div>

              <div className="flex flex-wrap gap-2">
                <Button size="sm" onClick={() => setInspeccionAbiertaId(vigente.id)}>
                  Abrir inspección
                </Button>
                {vigente.estado === 'cerrada' && (
                  <Button
                    size="sm"
                    variant="outline"
                    disabled={creandoFormato === formato}
                    onClick={() => iniciarInspeccion(formato)}
                  >
                    <RefreshCw className="h-3.5 w-3.5 mr-1.5" />
                    Nueva re-inspección
                  </Button>
                )}
              </div>
            </>
          ) : (
            <>
              {!sug && opcionesFormato.length === 0 ? (
                <div className="p-3 rounded-md bg-amber-500/10 border border-amber-500/30 text-xs space-y-2">
                  <div className="flex items-start gap-2 text-foreground">
                    <AlertCircle className="h-4 w-4 text-amber-600 shrink-0 mt-0.5" />
                    <span>
                      No hay plantilla activa para esta línea y formato. Créala o duplícala desde Calidad → Plantillas.
                    </span>
                  </div>
                  {onIrAPlantillas && (
                    <Button size="sm" variant="outline" className="h-7 text-xs" onClick={onIrAPlantillas}>
                      <ExternalLink className="h-3 w-3 mr-1" /> Ir a Calidad → Plantillas
                    </Button>
                  )}
                </div>
              ) : (
                <div className="space-y-2">
                  {!sug && (
                    <div className="p-2.5 rounded-md bg-amber-500/10 border border-amber-500/30 text-xs flex items-start gap-2">
                      <AlertCircle className="h-4 w-4 text-amber-600 shrink-0 mt-0.5" />
                      <div className="space-y-1">
                        <p>Esta línea no tiene plantilla propia; puedes elegir otra plantilla activa o crear una en Calidad → Plantillas.</p>
                        {onIrAPlantillas && (
                          <button
                            type="button"
                            onClick={onIrAPlantillas}
                            className="text-primary underline font-medium"
                          >
                            Ir a Calidad → Plantillas
                          </button>
                        )}
                      </div>
                    </div>
                  )}

                  {opcionesFormato.length > 0 && (
                    <div className="space-y-1">
                      <span className="text-xs text-muted-foreground">Plantilla a utilizar:</span>
                      <Select
                        value={selId}
                        onValueChange={(v) =>
                          setPlantillaSeleccionada((prev) => ({ ...prev, [formato]: v }))
                        }
                      >
                        <SelectTrigger className="h-8 text-xs">
                          <SelectValue placeholder="Selecciona una plantilla activa" />
                        </SelectTrigger>
                        <SelectContent>
                          {opcionesFormato.map((p) => (
                            <SelectItem key={p.id} value={p.id}>
                              {p.nombre} ({p.linea?.nombre || 'Línea'} · v{p.version})
                            </SelectItem>
                          ))}
                        </SelectContent>
                      </Select>
                    </div>
                  )}

                  <Button
                    size="sm"
                    disabled={!selId || creandoFormato === formato}
                    onClick={() => iniciarInspeccion(formato)}
                  >
                    {creandoFormato === formato ? (
                      <Loader2 className="h-3.5 w-3.5 animate-spin mr-1.5" />
                    ) : (
                      <Play className="h-3.5 w-3.5 mr-1.5" />
                    )}
                    Iniciar
                  </Button>
                </div>
              )}
            </>
          )}
        </CardContent>
      </Card>
    );
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center py-8 text-sm text-muted-foreground">
        <Loader2 className="h-5 w-5 animate-spin mr-2" /> Cargando calidad...
      </div>
    );
  }

  return (
    <div className="space-y-3">
      {renderTarjeta('control_total', 'Control de calidad total')}
      {renderTarjeta('entrega', 'Calidad de entrega')}

      <CalidadInspeccionModal
        inspeccionId={inspeccionAbiertaId}
        open={Boolean(inspeccionAbiertaId)}
        ajustes={ajustes}
        onClose={() => setInspeccionAbiertaId(null)}
        onActualizado={() => {
          cargar();
          onActualizado?.();
        }}
        onAbrirInspeccion={(nuevoId) => setInspeccionAbiertaId(nuevoId)}
      />
    </div>
  );
}
