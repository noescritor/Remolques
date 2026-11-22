import React, { useCallback, useEffect, useMemo, useState } from 'react';
import { Link, useNavigate, useParams, useSearchParams } from 'react-router-dom';
import {
  AlertTriangle,
  ArrowLeft,
  Calendar,
  CheckCircle2,
  ClipboardCheck,
  CreditCard,
  ExternalLink,
  FileText,
  FolderOpen,
  Info,
  Package,
  Printer,
  ShieldCheck,
  Wrench,
} from 'lucide-react';
import { Badge } from '../ui/badge';
import { Button } from '../ui/button';
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '../ui/dialog';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '../ui/tabs';
import { OrdenTrabajo } from '../../types';
import { ChecklistDespiecePanel } from '../OrdenesTrabajo/ChecklistDespiecePanel';
import { OrdenTrabajoPDF } from '../OrdenesTrabajo/OrdenTrabajoPDF';
import { OrdenCalidadTab } from '../Calidad/OrdenCalidadTab';
import { calidadApi } from '../Calidad/calidadApi';
import { expedienteApi, ResumenEntregaOrdenDto } from './expedienteApi';
import {
  estadoVacioPestana,
  FaseOrdenTablero,
  normalizarTabExpediente,
  resolverPresupuestoDeOrden,
  TabExpediente,
} from './expedienteUtils';

interface ExpedienteEquipoPageProps {
  ordenesTrabajo?: OrdenTrabajo[];
  cotizaciones?: any[];
  ajustes?: any;
  onRegenerarFicha?: (id: string) => Promise<void>;
}

const TAB_ITEMS: Array<{ id: TabExpediente; label: string }> = [
  { id: 'resumen', label: 'Resumen' },
  { id: 'cotizacion', label: 'Cotización y presupuesto' },
  { id: 'orden', label: 'Orden de trabajo' },
  { id: 'plan', label: 'Plan semanal' },
  { id: 'almacen', label: 'Almacén' },
  { id: 'calidad', label: 'Calidad' },
  { id: 'cobranza', label: 'Cobranza' },
];

function formatearMoneda(n: number | string | null | undefined): string {
  const num = Number(n ?? 0);
  if (!Number.isFinite(num)) return '$0.00';
  return num.toLocaleString('es-MX', { style: 'currency', currency: 'MXN' });
}

function etiquetaEstadoFase(estado?: string | null): string {
  if (estado === 'terminada') return 'Terminada';
  if (estado === 'en_proceso') return 'En proceso';
  if (estado === 'pausada') return 'Pausada';
  return 'Pendiente';
}

export function ExpedienteEquipoPage({
  ordenesTrabajo = [],
  cotizaciones = [],
  ajustes,
  onRegenerarFicha,
}: ExpedienteEquipoPageProps) {
  const { ordenId } = useParams<{ ordenId: string }>();
  const navigate = useNavigate();
  const [searchParams, setSearchParams] = useSearchParams();

  const tabActiva = normalizarTabExpediente(searchParams.get('tab'));

  const [loading, setLoading] = useState(true);
  const [errorCarga, setErrorCarga] = useState<string | null>(null);
  const [ordenRemota, setOrdenRemota] = useState<any | null>(null);
  const [totalEquiposCotizacion, setTotalEquiposCotizacion] = useState<number>(1);
  const [presupuestos, setPresupuestos] = useState<any[]>([]);
  const [pagos, setPagos] = useState<any[]>([]);
  const [tareasPlan, setTareasPlan] = useState<any[]>([]);
  const [inspeccionesCalidad, setInspeccionesCalidad] = useState<any[]>([]);
  const [resumenEntrega, setResumenEntrega] = useState<ResumenEntregaOrdenDto | null>(null);
  const [fasesEquipo, setFasesEquipo] = useState<FaseOrdenTablero[]>([]);
  const [materialFaltanteTablero, setMaterialFaltanteTablero] = useState<string | null>(null);
  const [fechaCompromisoTablero, setFechaCompromisoTablero] = useState<string | null>(null);
  const [etiquetaTablero, setEtiquetaTablero] = useState<string | null>(null);
  const [modalPdfAbierto, setModalPdfAbierto] = useState(false);

  const ordenLocal = useMemo(
    () => ordenesTrabajo.find((o) => o.id === ordenId) || null,
    [ordenesTrabajo, ordenId]
  );

  const orden = ordenRemota || ordenLocal;

  const cotizacionVinculada = useMemo(() => {
    if (!orden?.cotizacion_id) return null;
    return (
      cotizaciones.find((c) => c.id === orden.cotizacion_id) ||
      orden.cotizacion ||
      null
    );
  }, [cotizaciones, orden]);

  const lineaClave = useMemo(() => {
    if ((orden as any)?.linea?.clave) return String((orden as any).linea.clave).toLowerCase();
    const modelo = `${orden?.modelo || ''} ${orden?.tipo_equipo || ''}`.toLowerCase();
    if (modelo.includes('gondola') || modelo.includes('góndola')) return 'gondola';
    if (modelo.includes('dolly')) return 'dolly';
    if (modelo.includes('traila')) return 'traila';
    if (modelo.includes('cama')) return 'cama_baja';
    return 'plataforma';
  }, [orden]);

  const presupuestoVinculado = useMemo(
    () => resolverPresupuestoDeOrden(orden, presupuestos),
    [orden, presupuestos]
  );

  const cambiarTab = (nuevaTab: string) => {
    const valida = normalizarTabExpediente(nuevaTab);
    setSearchParams(
      (prev) => {
        const next = new URLSearchParams(prev);
        next.set('tab', valida);
        return next;
      },
      { replace: true }
    );
  };

  const volver = () => {
    if (window.history.length > 1) {
      navigate(-1);
    } else {
      navigate('/tablero-produccion');
    }
  };

  const refrescarResumenSilencioso = useCallback(async () => {
    if (!ordenId) return;
    try {
      const [resEnt, insps] = await Promise.all([
        expedienteApi.resumenEntregasOrdenes().catch(() => []),
        calidadApi.listarInspecciones({ orden_trabajo_id: ordenId }).catch(() => []),
      ]);
      const miResumen = (resEnt || []).find((r) => r.orden_trabajo_id === ordenId) || null;
      setResumenEntrega(miResumen);
      setInspeccionesCalidad(insps || []);
    } catch {
      // Silencioso en refresco de fondo
    }
  }, [ordenId]);

  useEffect(() => {
    if (!ordenId) return;
    let activo = true;
    setLoading(true);
    setErrorCarga(null);

    const cargar = async () => {
      try {
        const [ordenesRes, presupuestosRes, trazRes, resEntRes, inspsRes] = await Promise.all([
          expedienteApi.listarOrdenesTrabajo(),
          expedienteApi.listarPresupuestos().catch(() => []),
          expedienteApi.trazabilidadOrden(ordenId).catch(() => []),
          expedienteApi.resumenEntregasOrdenes().catch(() => []),
          calidadApi.listarInspecciones({ orden_trabajo_id: ordenId }).catch(() => []),
        ]);
        if (!activo) return;

        const listaOrdenes = Array.isArray(ordenesRes) ? ordenesRes : [];
        const encontrada = listaOrdenes.find((o: any) => o.id === ordenId) || null;
        if (!encontrada && !ordenLocal) {
          setErrorCarga('No se encontró la orden de trabajo solicitada.');
          setLoading(false);
          return;
        }
        const ordActual = encontrada || ordenLocal;
        setOrdenRemota(encontrada);
        setPresupuestos(Array.isArray(presupuestosRes) ? presupuestosRes : []);
        setTareasPlan(Array.isArray(trazRes) ? trazRes : []);
        setInspeccionesCalidad(Array.isArray(inspsRes) ? inspsRes : []);

        const miResumen =
          (resEntRes || []).find((r: ResumenEntregaOrdenDto) => r.orden_trabajo_id === ordenId) ||
          null;
        setResumenEntrega(miResumen);

        if (ordActual?.cotizacion_id) {
          const mismosCot = listaOrdenes.filter(
            (o: any) => o.cotizacion_id === ordActual.cotizacion_id
          ).length;
          setTotalEquiposCotizacion(Math.max(1, mismosCot));

          const pagosRes = await expedienteApi
            .pagosPorCotizacion(ordActual.cotizacion_id)
            .catch(() => []);
          if (activo) setPagos(Array.isArray(pagosRes) ? pagosRes : []);
        } else {
          setPagos([]);
          setTotalEquiposCotizacion(1);
        }

        const clave = ordActual?.linea?.clave || lineaClave;
        const matrizRes = await expedienteApi.matrizLinea(clave).catch(() => null);
        if (activo && matrizRes?.filas) {
          const fila = matrizRes.filas.find((f: any) => f.orden_id === ordenId);
          if (fila) {
            setMaterialFaltanteTablero(fila.material_faltante || null);
            setFechaCompromisoTablero(fila.fecha_compromiso || null);
            setEtiquetaTablero(fila.etiqueta || null);
            const fasesLista: FaseOrdenTablero[] = (matrizRes.fases || [])
              .filter((f: any) => f.grupo === 'principal')
              .sort((a: any, b: any) => a.orden - b.orden)
              .map((f: any) => ({
                fase_id: f.id,
                nombre: f.nombre,
                orden: f.orden,
                estado: fila.fases?.[f.id]?.estado || 'pendiente',
              }));
            setFasesEquipo(fasesLista);
          }
        }
      } catch (err: any) {
        if (activo) {
          setErrorCarga(err?.message || 'Error al cargar el expediente del equipo');
        }
      } finally {
        if (activo) setLoading(false);
      }
    };

    cargar();
    return () => {
      activo = false;
    };
  }, [ordenId]);

  const calidadVigenteResumen = useMemo(() => {
    const porFormato = new Map<string, any>();
    for (const insp of inspeccionesCalidad) {
      const prev = porFormato.get(insp.formato);
      const intento = Number(insp.intento) || 1;
      if (!prev || intento > (Number(prev.intento) || 1)) {
        porFormato.set(insp.formato, insp);
      }
    }
    const vigentes = Array.from(porFormato.values());
    const ncTotal = vigentes.reduce(
      (acc, i) => acc + (Number(i.resumen?.no_conformes) || 0),
      0
    );
    return { vigentes, ncTotal };
  }, [inspeccionesCalidad]);

  if (loading && !orden) {
    return (
      <div className="p-6 max-w-6xl mx-auto">
        <div className="rounded-xl border border-border bg-card p-8 text-center text-sm text-muted-foreground">
          Cargando expediente del equipo...
        </div>
      </div>
    );
  }

  if (errorCarga && !orden) {
    return (
      <div className="p-6 max-w-4xl mx-auto space-y-4">
        <Button variant="outline" size="sm" onClick={volver}>
          <ArrowLeft className="w-4 h-4 mr-1.5" />
          Volver
        </Button>
        <div className="rounded-xl border border-destructive/40 bg-destructive/10 p-6 text-destructive flex items-center gap-3">
          <AlertTriangle className="w-5 h-5 shrink-0" />
          <div>
            <div className="font-semibold">No se pudo abrir el expediente</div>
            <div className="text-sm">{errorCarga}</div>
          </div>
        </div>
      </div>
    );
  }

  if (!orden) return null;

  const clienteNombre =
    orden.cliente?.nombre_razon_social ||
    (orden.cliente as any)?.nombre ||
    etiquetaTablero ||
    orden.etiqueta ||
    (orden.origen === 'manual' ? 'Inventario / Manual en planta' : 'Sin cliente');
  const tituloEquipo = etiquetaTablero || orden.etiqueta || orden.nomenclatura_id || 'Equipo';
  const fechaCompromiso = fechaCompromisoTablero || (orden as any).fecha_compromiso || null;
  const materialFaltante = materialFaltanteTablero || (orden as any).material_faltante || null;

  const vacioCotizacion = estadoVacioPestana('cotizacion', { cotizacionId: orden.cotizacion_id });
  const vacioPlan = estadoVacioPestana('plan', { totalTareasPlan: tareasPlan.length });
  const vacioCobranza = estadoVacioPestana('cobranza', {
    cotizacionId: orden.cotizacion_id,
    totalPagos: pagos.length,
  });

  return (
    <div className="min-h-screen bg-background text-foreground flex flex-col">
      {/* Encabezado fijo */}
      <header className="sticky top-0 z-20 bg-background/95 backdrop-blur border-b border-border px-4 sm:px-6 py-3">
        <div className="max-w-6xl mx-auto space-y-2">
          <div className="flex flex-wrap items-center justify-between gap-3">
            <div className="flex items-center gap-3 min-w-0">
              <Button variant="outline" size="sm" onClick={volver} className="shrink-0">
                <ArrowLeft className="w-4 h-4 mr-1.5" />
                Volver
              </Button>
              <div className="min-w-0">
                <div className="flex items-center gap-2 flex-wrap">
                  <FolderOpen className="w-4 h-4 text-primary shrink-0" />
                  <h1 className="text-base sm:text-lg font-bold truncate">{tituloEquipo}</h1>
                  <Badge variant="outline" className="text-[11px] font-mono">
                    {orden.nomenclatura_id}
                  </Badge>
                  <Badge variant="secondary" className="text-[11px]">
                    {orden.estado || 'Pendiente'}
                  </Badge>
                </div>
                <div className="flex flex-wrap items-center gap-x-3 gap-y-0.5 text-xs text-muted-foreground mt-0.5">
                  <span>Cliente: {clienteNombre}</span>
                  <span>Modelo: {orden.modelo || orden.tipo_equipo || '—'}</span>
                  {orden.niv && <span className="font-mono">NIV: {orden.niv}</span>}
                  <span className="capitalize">Línea: {orden.linea?.nombre || lineaClave}</span>
                  {fechaCompromiso && <span>Compromiso: {fechaCompromiso}</span>}
                </div>
              </div>
            </div>
          </div>

          {materialFaltante && (
            <div className="rounded-md border border-amber-500/40 bg-amber-500/10 px-3 py-1.5 text-xs text-foreground flex items-center gap-2">
              <AlertTriangle className="w-4 h-4 text-amber-500 shrink-0" />
              <span>
                <strong>Material faltante (tablero):</strong> {materialFaltante}
              </span>
            </div>
          )}
        </div>
      </header>

      {/* Contenido con pestañas */}
      <main className="flex-1 px-4 sm:px-6 py-4 max-w-6xl w-full mx-auto">
        <Tabs value={tabActiva} onValueChange={cambiarTab} className="w-full">
          <div className="overflow-x-auto pb-1">
            <TabsList className="inline-flex w-max min-w-full sm:w-auto bg-muted border border-border">
              {TAB_ITEMS.map((t) => (
                <TabsTrigger key={t.id} value={t.id} className="text-xs sm:text-sm whitespace-nowrap">
                  {t.label}
                </TabsTrigger>
              ))}
            </TabsList>
          </div>

          {/* 1. RESUMEN */}
          <TabsContent value="resumen" className="mt-4 space-y-4">
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div className="rounded-xl border border-border bg-card p-4 space-y-2">
                <div className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">
                  Ficha del equipo
                </div>
                <div className="text-sm space-y-1">
                  <div>
                    <span className="text-muted-foreground">Cliente: </span>
                    <span className="font-medium">{clienteNombre}</span>
                  </div>
                  <div>
                    <span className="text-muted-foreground">Modelo: </span>
                    <span className="font-medium">{orden.modelo || orden.tipo_equipo || '—'}</span>
                  </div>
                  <div>
                    <span className="text-muted-foreground">NIV: </span>
                    <span className="font-mono">{orden.niv || 'Sin asignar'}</span>
                  </div>
                  <div>
                    <span className="text-muted-foreground">Origen: </span>
                    <span>{orden.cotizacion_id ? 'Cotización' : 'Manual en planta'}</span>
                  </div>
                  <div>
                    <span className="text-muted-foreground">Fecha compromiso: </span>
                    <span>{fechaCompromiso || 'Sin definir'}</span>
                  </div>
                </div>
              </div>

              <div className="rounded-xl border border-border bg-card p-4 space-y-2">
                <div className="text-xs font-semibold uppercase tracking-wider text-muted-foreground flex items-center gap-1.5">
                  <Package className="w-3.5 h-3.5 text-primary" />
                  Entregas de almacén
                </div>
                {resumenEntrega && resumenEntrega.total_partidas > 0 ? (
                  <div className="space-y-2">
                    <div className="text-2xl font-bold font-mono text-foreground">
                      {resumenEntrega.partidas_completas} / {resumenEntrega.total_partidas}{' '}
                      <span className="text-sm font-normal text-muted-foreground">
                        partidas completas ({resumenEntrega.porcentaje ?? 0}%)
                      </span>
                    </div>
                    <Button size="sm" variant="outline" onClick={() => cambiarTab('almacen')}>
                      Ir a liberar material
                    </Button>
                  </div>
                ) : (
                  <div className="space-y-2">
                    <div className="text-sm text-muted-foreground">Sin entregas o despiece pendiente.</div>
                    <Button size="sm" variant="outline" onClick={() => cambiarTab('almacen')}>
                      Abrir almacén
                    </Button>
                  </div>
                )}
              </div>

              <div className="rounded-xl border border-border bg-card p-4 space-y-2">
                <div className="text-xs font-semibold uppercase tracking-wider text-muted-foreground flex items-center gap-1.5">
                  <ShieldCheck className="w-3.5 h-3.5 text-primary" />
                  Calidad
                </div>
                {calidadVigenteResumen.vigentes.length > 0 ? (
                  <div className="space-y-2">
                    <div className="text-sm space-y-1">
                      {calidadVigenteResumen.vigentes.map((insp: any) => (
                        <div key={insp.id} className="flex items-center justify-between">
                          <span className="font-mono text-xs">
                            {insp.folio} ({insp.formato === 'control_total' ? 'Control total' : 'Entrega'})
                          </span>
                          <Badge variant="outline" className="text-[10px]">
                            {insp.estado === 'cerrada' ? 'Cerrada' : 'En proceso'} ·{' '}
                            {insp.resumen?.capturados ?? 0}/{insp.resumen?.total ?? 0}
                          </Badge>
                        </div>
                      ))}
                    </div>
                    {calidadVigenteResumen.ncTotal > 0 && (
                      <div className="text-xs text-destructive font-medium">
                        {calidadVigenteResumen.ncTotal} no conforme(s) registrado(s)
                      </div>
                    )}
                    <Button size="sm" variant="outline" onClick={() => cambiarTab('calidad')}>
                      Abrir calidad
                    </Button>
                  </div>
                ) : (
                  <div className="space-y-2">
                    <div className="text-sm text-muted-foreground">Sin inspecciones iniciadas.</div>
                    <Button size="sm" variant="outline" onClick={() => cambiarTab('calidad')}>
                      Ir a calidad
                    </Button>
                  </div>
                )}
              </div>
            </div>

            <div className="rounded-xl border border-border bg-card p-4 space-y-3">
              <div className="text-xs font-semibold uppercase tracking-wider text-muted-foreground flex items-center gap-1.5">
                <Wrench className="w-3.5 h-3.5 text-primary" />
                Fases de producción
              </div>
              {fasesEquipo.length === 0 ? (
                <div className="text-sm text-muted-foreground">
                  No hay fases registradas en el tablero para este equipo.
                </div>
              ) : (
                <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-2">
                  {fasesEquipo.map((f) => (
                    <div
                      key={f.fase_id || f.nombre}
                      className={`rounded-lg border p-2.5 text-xs ${
                        f.estado === 'en_proceso'
                          ? 'border-primary bg-primary/10'
                          : f.estado === 'terminada'
                            ? 'border-border bg-muted/40'
                            : 'border-border/60 bg-background'
                      }`}
                    >
                      <div className="font-semibold truncate">{f.nombre}</div>
                      <div className="text-[11px] text-muted-foreground mt-0.5">
                        {etiquetaEstadoFase(f.estado)}
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </TabsContent>

          {/* 2. COTIZACIÓN Y PRESUPUESTO */}
          <TabsContent value="cotizacion" className="mt-4">
            {vacioCotizacion.vacio ? (
              <div className="rounded-xl border border-dashed border-border bg-card p-8 text-center space-y-2">
                <Info className="w-8 h-8 text-muted-foreground mx-auto" />
                <div className="font-semibold text-foreground">{vacioCotizacion.titulo}</div>
                <p className="text-sm text-muted-foreground max-w-md mx-auto">
                  {vacioCotizacion.mensaje}
                </p>
              </div>
            ) : (
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="rounded-xl border border-border bg-card p-5 space-y-3">
                  <div className="flex items-center justify-between">
                    <span className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">
                      Cotización de origen
                    </span>
                    <Badge variant="outline">{cotizacionVinculada?.estado || '—'}</Badge>
                  </div>
                  <div className="text-lg font-bold font-mono">
                    {cotizacionVinculada?.folio || orden.cotizacion_id}
                  </div>
                  <div className="text-sm space-y-1 text-muted-foreground">
                    <div>Fecha: {cotizacionVinculada?.fecha || '—'}</div>
                    <div>
                      Total:{' '}
                      <span className="font-semibold text-foreground">
                        {formatearMoneda(cotizacionVinculada?.total)}
                      </span>
                    </div>
                  </div>
                  <Button asChild size="sm" variant="outline">
                    <Link to={`/cotizaciones/${orden.cotizacion_id}`}>
                      Ver cotización <ExternalLink className="w-3.5 h-3.5 ml-1.5" />
                    </Link>
                  </Button>
                </div>

                <div className="rounded-xl border border-border bg-card p-5 space-y-3">
                  <div className="flex items-center justify-between">
                    <span className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">
                      Presupuesto vinculado
                    </span>
                    {presupuestoVinculado && (
                      <Badge variant="outline">{(presupuestoVinculado as any).estado || 'Generado'}</Badge>
                    )}
                  </div>
                  {presupuestoVinculado ? (
                    <>
                      <div className="text-lg font-bold font-mono">
                        {presupuestoVinculado.folio}
                      </div>
                      <div className="text-sm text-muted-foreground">
                        Ligado a la cotización {cotizacionVinculada?.folio || orden.cotizacion_id}.
                      </div>
                      <Button asChild size="sm" variant="outline">
                        <Link to="/presupuestos">
                          Ir a presupuestos <ExternalLink className="w-3.5 h-3.5 ml-1.5" />
                        </Link>
                      </Button>
                    </>
                  ) : (
                    <div className="text-sm text-muted-foreground">
                      No se encontró un presupuesto con folio{' '}
                      <span className="font-mono">
                        PRE-{cotizacionVinculada?.folio || orden.cotizacion_id}
                      </span>{' '}
                      para esta cotización.
                    </div>
                  )}
                </div>
              </div>
            )}
          </TabsContent>

          {/* 3. ORDEN DE TRABAJO */}
          <TabsContent value="orden" className="mt-4">
            <div className="rounded-xl border border-border bg-card p-5 space-y-4">
              <div className="flex flex-wrap items-center justify-between gap-3">
                <div>
                  <h2 className="text-base font-bold flex items-center gap-2">
                    <FileText className="w-4 h-4 text-primary" />
                    Orden de trabajo {orden.nomenclatura_id}
                  </h2>
                  <p className="text-xs text-muted-foreground mt-0.5">
                    Estado: {orden.estado} · Pedido: {orden.fecha_pedido || '—'} · Entrega:{' '}
                    {orden.fecha_entrega || '—'}
                  </p>
                </div>
                <Button onClick={() => setModalPdfAbierto(true)}>
                  <Printer className="w-4 h-4 mr-1.5" />
                  Ver / Imprimir Orden de Trabajo
                </Button>
              </div>
              <div className="grid grid-cols-1 sm:grid-cols-3 gap-3 text-sm border-t border-border/60 pt-3">
                <div>
                  <span className="text-xs text-muted-foreground block">Modelo</span>
                  <span className="font-medium">{orden.modelo || orden.tipo_equipo || '—'}</span>
                </div>
                <div>
                  <span className="text-xs text-muted-foreground block">NIV</span>
                  <span className="font-mono">{orden.niv || 'Sin asignar'}</span>
                </div>
                <div>
                  <span className="text-xs text-muted-foreground block">Notas</span>
                  <span>{orden.notas || 'Sin notas'}</span>
                </div>
              </div>
            </div>
          </TabsContent>

          {/* 4. PLAN SEMANAL */}
          <TabsContent value="plan" className="mt-4 space-y-3">
            <div className="flex items-center justify-between">
              <h2 className="text-sm font-semibold text-foreground flex items-center gap-2">
                <Calendar className="w-4 h-4 text-primary" />
                Tareas de plan semanal
              </h2>
              <Button asChild size="sm" variant="outline">
                <Link to={`/plan-semanal?tab=trazabilidad&ordenId=${orden.id}`}>
                  Abrir en Plan Semanal <ExternalLink className="w-3.5 h-3.5 ml-1.5" />
                </Link>
              </Button>
            </div>
            {vacioPlan.vacio ? (
              <div className="rounded-xl border border-dashed border-border bg-card p-8 text-center space-y-2">
                <Info className="w-8 h-8 text-muted-foreground mx-auto" />
                <div className="font-semibold">{vacioPlan.titulo}</div>
                <p className="text-sm text-muted-foreground max-w-md mx-auto">
                  {vacioPlan.mensaje}
                </p>
              </div>
            ) : (
              <div className="space-y-2">
                {tareasPlan.map((t: any) => (
                  <div
                    key={t.id}
                    className="rounded-lg border border-border bg-card p-3 flex flex-wrap items-center justify-between gap-2 text-sm"
                  >
                    <div>
                      <div className="font-medium">{t.descripcion || t.actividad || 'Tarea'}</div>
                      <div className="text-xs text-muted-foreground">
                        Semana: {t.semana || t.fecha_inicio || '—'} · Área/Frente:{' '}
                        {t.area_nombre || t.frente_nombre || '—'} · Operario:{' '}
                        {t.operario_nombre || 'Sin asignar'}
                      </div>
                    </div>
                    <Badge variant="outline">{t.estado || 'Pendiente'}</Badge>
                  </div>
                ))}
              </div>
            )}
          </TabsContent>

          {/* 5. ALMACÉN */}
          <TabsContent value="almacen" className="mt-4">
            <div className="rounded-xl border border-border bg-card p-4 sm:p-5">
              <ChecklistDespiecePanel
                orden={orden}
                activo={tabActiva === 'almacen'}
                modoEmbebido
                fasesProduccion={fasesEquipo}
                onActualizado={refrescarResumenSilencioso}
              />
            </div>
          </TabsContent>

          {/* 6. CALIDAD */}
          <TabsContent value="calidad" className="mt-4">
            <div className="rounded-xl border border-border bg-card p-4 sm:p-5">
              <OrdenCalidadTab
                orden={{
                  id: orden.id,
                  etiqueta: tituloEquipo,
                  modelo: orden.modelo,
                  tipo_equipo: orden.tipo_equipo,
                  linea_clave: lineaClave,
                }}
                ajustes={ajustes}
                onActualizado={refrescarResumenSilencioso}
                onIrAPlantillas={() => navigate('/calidad/plantillas')}
              />
            </div>
          </TabsContent>

          {/* 7. COBRANZA (SOLO LECTURA) */}
          <TabsContent value="cobranza" className="mt-4 space-y-4">
            <div className="rounded-lg border border-border bg-muted/40 p-3 text-xs text-muted-foreground flex items-center gap-2">
              <Info className="w-4 h-4 text-primary shrink-0" />
              <span>
                El plan de pagos y la cartera por equipo llegan con el bloque de cobranza.
                {totalEquiposCotizacion > 1
                  ? ` Esta cotización cubre ${totalEquiposCotizacion} equipos; los pagos mostrados corresponden al total de la cotización.`
                  : ''}
              </span>
            </div>

            {vacioCobranza.vacio ? (
              <div className="rounded-xl border border-dashed border-border bg-card p-8 text-center space-y-2">
                <CreditCard className="w-8 h-8 text-muted-foreground mx-auto" />
                <div className="font-semibold">{vacioCobranza.titulo}</div>
                <p className="text-sm text-muted-foreground max-w-md mx-auto">
                  {vacioCobranza.mensaje}
                </p>
              </div>
            ) : (
              <div className="rounded-xl border border-border bg-card p-4 space-y-3">
                <div className="flex items-center justify-between">
                  <h2 className="text-sm font-bold flex items-center gap-2">
                    <CreditCard className="w-4 h-4 text-primary" />
                    Pagos de la cotización
                  </h2>
                  <Badge variant="outline" className="font-mono">
                    {cotizacionVinculada?.folio || orden.cotizacion_id}
                  </Badge>
                </div>
                <div className="divide-y divide-border/60">
                  {pagos.map((p: any) => (
                    <div key={p.id} className="py-2.5 flex flex-wrap items-center justify-between gap-2 text-sm">
                      <div>
                        <div className="font-medium flex items-center gap-1.5">
                          <CheckCircle2 className="w-3.5 h-3.5 text-primary" />
                          {p.metodo_pago || p.metodo || 'Pago'}
                          {p.referencia ? ` · Ref: ${p.referencia}` : ''}
                        </div>
                        <div className="text-xs text-muted-foreground">
                          Fecha: {p.fecha || p.created_at?.slice(0, 10) || '—'}
                        </div>
                      </div>
                      <div className="font-mono font-bold text-foreground">
                        {formatearMoneda(p.monto)}
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </TabsContent>
        </Tabs>
      </main>

      <Dialog open={modalPdfAbierto} onOpenChange={setModalPdfAbierto}>
        <DialogContent className="max-w-4xl max-h-[90vh] overflow-y-auto bg-background border-border">
          <DialogHeader>
            <DialogTitle>Orden de Trabajo — {orden.nomenclatura_id}</DialogTitle>
          </DialogHeader>
          <OrdenTrabajoPDF
            orden={orden}
            ajustes={ajustes}
            onRegenerarFicha={onRegenerarFicha}
          />
        </DialogContent>
      </Dialog>
    </div>
  );
}
