import React, { useEffect, useMemo, useRef, useState } from 'react';
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
import { Badge } from '../ui/badge';
import { Checkbox } from '../ui/checkbox';
import {
  AlertCircle,
  AlertTriangle,
  BookmarkCheck,
  CheckCircle2,
  ExternalLink,
  Loader2,
  PackageCheck,
  RefreshCw,
  Scale,
  Sparkles,
} from 'lucide-react';
import { toast } from 'sonner';
import {
  fetchPropuestaAlmacenApi,
  formatearCantidadStock,
  LineaRecibirAlmacen,
  PropuestaLineaAlmacen,
  PropuestaRecepcionAlmacen,
  recibirFacturaAlmacenApi,
} from '../../utils/almacenApi';

interface RecibirFacturaAlmacenModalProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  facturaId: string | null;
  facturaFolio?: string;
  supabase: any;
  onRecibido?: () => void;
  onIrAInventario?: () => void;
}

interface EstadoFilaRecepcion {
  seleccionada: boolean;
  productoId: string;
  factorStr: string;
  cantidadStr: string;
  cantidadManual: boolean;
  guardarAlias: boolean;
}

const fmtMoneda = (v: number | null | undefined) => {
  if (v === null || v === undefined || !Number.isFinite(v)) return '—';
  return new Intl.NumberFormat('es-MX', {
    style: 'currency',
    currency: 'MXN',
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(v);
};

export function RecibirFacturaAlmacenModal({
  open,
  onOpenChange,
  facturaId,
  facturaFolio,
  supabase,
  onRecibido,
  onIrAInventario,
}: RecibirFacturaAlmacenModalProps) {
  const [estadoCarga, setEstadoCarga] = useState<'cargando' | 'error' | 'ok'>('cargando');
  const [errorCarga, setErrorCarga] = useState<string | null>(null);
  const [propuesta, setPropuesta] = useState<PropuestaRecepcionAlmacen | null>(null);

  const [filas, setFilas] = useState<Record<string, EstadoFilaRecepcion>>({});
  const [busquedaProducto, setBusquedaProducto] = useState('');
  const [confirmoDoble, setConfirmoDoble] = useState(false);

  const [recibiendo, setRecibiendo] = useState(false);
  const guardandoRef = useRef(false);
  const [errorRecibir, setErrorRecibir] = useState<string | null>(null);
  const [resumenExito, setResumenExito] = useState<{
    recepcion_id: string;
    total_lineas: number;
    lineas: Array<{
      producto_nombre: string;
      cantidad_recibida: number;
      costo_unitario_mxn: number;
      costo_actualizado: boolean;
    }>;
  } | null>(null);

  const inicializarFilas = (data: PropuestaRecepcionAlmacen) => {
    const next: Record<string, EstadoFilaRecepcion> = {};
    for (const p of data.lineas) {
      const prodId = p.producto_id_sugerido || '';
      const factorInit =
        p.banderas.requiere_factor && p.banderas.bloqueada_unidad
          ? ''
          : String(p.factor_conversion_sugerido || 1);
      const cantInit =
        p.banderas.requiere_factor && p.banderas.bloqueada_unidad
          ? ''
          : p.cantidad_recibir_sugerida !== null && p.cantidad_recibir_sugerida !== undefined
          ? String(p.cantidad_recibir_sugerida)
          : String(p.cantidad_xml);
      const autoSel =
        !p.banderas.ya_recibida &&
        !p.banderas.es_servicio_probable &&
        Boolean(prodId) &&
        !p.banderas.bloqueada_tipo_cambio &&
        !p.banderas.bloqueada_unidad;
      next[p.partida_id] = {
        seleccionada: autoSel,
        productoId: prodId,
        factorStr: factorInit,
        cantidadStr: cantInit,
        cantidadManual: false,
        guardarAlias: Boolean(prodId) && !p.banderas.ya_recibida,
      };
    }
    setFilas(next);
    setConfirmoDoble(false);
  };

  const cargarPropuesta = async () => {
    if (!facturaId) return;
    setEstadoCarga('cargando');
    setErrorCarga(null);
    setErrorRecibir(null);
    setResumenExito(null);
    try {
      const data = await fetchPropuestaAlmacenApi(supabase, facturaId);
      setPropuesta(data);
      inicializarFilas(data);
      setEstadoCarga('ok');
    } catch (err: any) {
      setErrorCarga(err?.message || 'No se pudo cargar la propuesta de almacén.');
      setEstadoCarga('error');
    }
  };

  useEffect(() => {
    if (open && facturaId) {
      setBusquedaProducto('');
      cargarPropuesta();
    }
  }, [open, facturaId]);

  const productosMap = useMemo(() => {
    const m = new Map<string, PropuestaRecepcionAlmacen['productos'][number]>();
    if (!propuesta) return m;
    for (const pr of propuesta.productos) m.set(pr.id, pr);
    return m;
  }, [propuesta]);

  const productosFiltrados = useMemo(() => {
    if (!propuesta) return [];
    const q = busquedaProducto.trim().toLowerCase();
    if (!q) return propuesta.productos;
    return propuesta.productos.filter(
      (p) => p.nombre.toLowerCase().includes(q) || p.unidad.toLowerCase().includes(q)
    );
  }, [propuesta, busquedaProducto]);

  const calcularFila = (p: PropuestaLineaAlmacen) => {
    const f = filas[p.partida_id];
    if (!f || !propuesta) {
      return {
        factorValido: false,
        bloqueadaUnidad: p.banderas.requiere_factor,
        cantidadValida: false,
        costoUnitario: null as number | null,
        costoCatalogo: null as number | null,
        diferenciaPct: null as number | null,
        costoFechaAnterior: p.banderas.costo_fecha_anterior,
        foliosDup: [] as string[],
        puedeRecibir: false,
      };
    }

    const factorNum = parseFloat(f.factorStr);
    const factorValido = Number.isFinite(factorNum) && factorNum > 0;
    const bloqueadaUnidad = p.banderas.requiere_factor && !factorValido;
    const cantNum = parseFloat(f.cantidadStr);
    const cantidadValida = Number.isFinite(cantNum) && cantNum > 0;

    const mismoQueServidor =
      f.productoId === (p.producto_id_sugerido || '') &&
      factorValido &&
      Math.abs(factorNum - (p.factor_conversion_sugerido || 1)) < 1e-6;

    const prod = f.productoId ? productosMap.get(f.productoId) || null : null;
    let costoUnitario: number | null = null;
    if (mismoQueServidor) {
      costoUnitario = p.costo_unitario_mxn;
    } else if (!p.banderas.bloqueada_tipo_cambio && factorValido && p.cantidad_xml > 0 && p.importe > 0) {
      const tc = propuesta.factura.moneda === 'USD' ? Number(propuesta.factura.tipo_cambio_emision || 0) : 1;
      costoUnitario = Math.round(((p.importe / p.cantidad_xml) * tc / factorNum) * 10000) / 10000;
    }

    const costoCatalogo = prod ? prod.costo : null;
    let diferenciaPct: number | null = null;
    if (mismoQueServidor) {
      diferenciaPct = p.diferencia_costo_pct;
    } else if (costoUnitario !== null && costoCatalogo !== null && costoCatalogo > 0) {
      diferenciaPct = Math.round(((costoUnitario - costoCatalogo) / costoCatalogo) * 10000) / 100;
    }

    const fechaFac = String(propuesta.factura.fecha_emision || '').slice(0, 10);
    const fechaUlt = prod?.ultimo_costo_compra_fecha ? String(prod.ultimo_costo_compra_fecha).slice(0, 10) : null;
    const costoFechaAnterior = Boolean(fechaFac && fechaUlt && fechaFac < fechaUlt);
    const foliosDup = f.productoId ? (propuesta.folios_por_producto?.[f.productoId] || []) : [];

    const puedeRecibir =
      !p.banderas.ya_recibida &&
      !p.banderas.bloqueada_tipo_cambio &&
      !bloqueadaUnidad &&
      Boolean(f.productoId) &&
      cantidadValida &&
      costoUnitario !== null;

    return {
      factorValido,
      bloqueadaUnidad,
      cantidadValida,
      costoUnitario,
      costoCatalogo,
      diferenciaPct,
      costoFechaAnterior,
      foliosDup,
      puedeRecibir,
    };
  };

  const updateFila = (partidaId: string, patch: Partial<EstadoFilaRecepcion>) => {
    setFilas((prev) => ({
      ...prev,
      [partidaId]: {
        ...prev[partidaId],
        ...patch,
      },
    }));
    setErrorRecibir(null);
  };

  const seleccionadas = useMemo(() => {
    if (!propuesta) return [];
    return propuesta.lineas.filter((p) => {
      const f = filas[p.partida_id];
      const calc = calcularFila(p);
      return f?.seleccionada && calc.puedeRecibir;
    });
  }, [propuesta, filas, productosMap]);

  const foliosDuplicadosActivos = useMemo(() => {
    if (!propuesta) return [];
    const set = new Set<string>(propuesta.compra_ya_recibida ? propuesta.folios_compras_duplicadas : []);
    for (const p of seleccionadas) {
      const f = filas[p.partida_id];
      const fols = f?.productoId ? (propuesta.folios_por_producto?.[f.productoId] || []) : [];
      for (const fl of fols) set.add(fl);
    }
    return Array.from(set).sort();
  }, [propuesta, seleccionadas, filas]);

  const requiereConfirmarDoble = Boolean(
    propuesta && (propuesta.compra_ya_recibida || foliosDuplicadosActivos.length > 0)
  );

  const handleRecibir = async () => {
    if (!facturaId || !propuesta) return;
    if (guardandoRef.current) return;

    if (seleccionadas.length === 0) {
      setErrorRecibir('Selecciona al menos una partida válida para recibir en almacén.');
      return;
    }
    if (requiereConfirmarDoble && !confirmoDoble) {
      setErrorRecibir('Marca la casilla "Confirmo que no es la misma mercancía" para continuar.');
      return;
    }

    const lineas: LineaRecibirAlmacen[] = [];
    for (const p of seleccionadas) {
      const f = filas[p.partida_id];
      const factorNum = parseFloat(f.factorStr);
      const cantNum = parseFloat(f.cantidadStr);
      if (p.banderas.requiere_factor && (!Number.isFinite(factorNum) || factorNum <= 0)) {
        setErrorRecibir(`Captura un factor de conversión mayor a cero para "${p.descripcion}".`);
        return;
      }
      if (!Number.isFinite(cantNum) || cantNum <= 0) {
        setErrorRecibir(`La cantidad a recibir para "${p.descripcion}" debe ser mayor a cero.`);
        return;
      }
      const item: LineaRecibirAlmacen = {
        partida_id: p.partida_id,
        producto_id: f.productoId,
        cantidad_recibida: cantNum,
        guardar_alias: Boolean(f.guardarAlias),
        descripcion_normalizada: p.descripcion_normalizada,
      };
      if (Number.isFinite(factorNum) && factorNum > 0) {
        item.factor_conversion = factorNum;
        item.factor_confirmado = true;
      }
      lineas.push(item);
    }

    guardandoRef.current = true;
    setRecibiendo(true);
    setErrorRecibir(null);
    try {
      const res = await recibirFacturaAlmacenApi(supabase, facturaId, {
        lineas,
        confirmo_doble: confirmoDoble,
      });
      setResumenExito({
        recepcion_id: res.recepcion_id,
        total_lineas: res.total_lineas,
        lineas: res.lineas || [],
      });
      toast.success(`Se recibieron ${res.total_lineas} partida(s) en almacén`);
      if (onRecibido) onRecibido();
      try {
        const refreshed = await fetchPropuestaAlmacenApi(supabase, facturaId);
        setPropuesta(refreshed);
        inicializarFilas(refreshed);
      } catch {
        // conservar resumen de éxito
      }
    } catch (err: any) {
      setErrorRecibir(err?.message || 'No se pudo completar la recepción. Ningún cambio fue guardado.');
      toast.error(err?.message || 'Error al recibir factura en almacén');
    } finally {
      guardandoRef.current = false;
      setRecibiendo(false);
    }
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[1100px] max-h-[90vh] flex flex-col bg-card border-border p-4 sm:p-6">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2 text-foreground">
            <PackageCheck className="h-5 w-5 text-primary" />
            Recibir factura en almacén {facturaFolio || propuesta?.factura.folio || ''}
          </DialogTitle>
          <DialogDescription>
            Confirma el producto y las cantidades a ingresar al inventario. El costo del XML se guarda solo como último costo de compra (sin IVA) y nunca modifica precios de cotización.
          </DialogDescription>
        </DialogHeader>

        {estadoCarga === 'cargando' && (
          <div className="flex items-center justify-center py-16 text-muted-foreground gap-2 text-sm">
            <Loader2 className="h-5 w-5 animate-spin" />
            Analizando partidas y existencias del catálogo...
          </div>
        )}

        {estadoCarga === 'error' && (
          <div className="py-10 px-4 text-center space-y-3 border border-destructive/30 rounded-lg bg-destructive/10">
            <div className="inline-flex items-center gap-2 text-destructive text-sm font-medium">
              <AlertCircle className="h-4 w-4" />
              {errorCarga || 'No se pudo cargar la propuesta de almacén.'}
            </div>
            <div>
              <Button variant="outline" size="sm" onClick={cargarPropuesta} className="gap-1.5">
                <RefreshCw className="h-3.5 w-3.5" />
                Reintentar
              </Button>
            </div>
          </div>
        )}

        {estadoCarga === 'ok' && propuesta && (
          <div className="flex-1 overflow-y-auto space-y-4 pr-1">
            {/* Encabezado de factura */}
            <div className="p-3 rounded-lg border border-border bg-muted/30 flex flex-col sm:flex-row sm:items-center justify-between gap-2 text-xs">
              <div className="space-y-1">
                <div className="font-semibold text-foreground">
                  {propuesta.factura.proveedor_nombre || 'Proveedor'}
                </div>
                <div className="flex flex-wrap items-center gap-2 text-muted-foreground">
                  <span>Folio: <strong className="text-foreground">{propuesta.factura.folio}</strong></span>
                  <span>· Fecha: <strong className="text-foreground">{String(propuesta.factura.fecha_emision || '').slice(0, 10)}</strong></span>
                  <span>
                    · Moneda: <strong className="text-foreground">{propuesta.factura.moneda}</strong>
                    {propuesta.factura.moneda === 'USD' && propuesta.factura.tipo_cambio_emision
                      ? ` (TC ${propuesta.factura.tipo_cambio_emision})`
                      : ''}
                  </span>
                </div>
              </div>
              <Input
                value={busquedaProducto}
                onChange={(e) => setBusquedaProducto(e.target.value)}
                placeholder="Filtrar productos del catálogo..."
                className="h-8 text-xs sm:w-64 bg-background"
              />
            </div>

            {propuesta.factura.descuento_en_factura && (
              <div className="flex items-start gap-2 p-2.5 rounded-md border border-amber-500/40 bg-amber-500/10 text-xs text-foreground">
                <AlertTriangle className="h-4 w-4 text-amber-600 dark:text-amber-400 shrink-0 mt-0.5" />
                <span>
                  Esta factura trae descuentos globales; el costo unitario se calcula sobre el importe bruto del concepto.
                </span>
              </div>
            )}

            {requiereConfirmarDoble && (
              <div
                role="alert"
                className="p-3 rounded-md border border-destructive/40 bg-destructive/10 space-y-2 text-xs text-foreground"
              >
                <div className="flex items-start gap-2 font-semibold text-destructive">
                  <AlertTriangle className="h-4 w-4 shrink-0 mt-0.5" />
                  <span>
                    Posible doble conteo de inventario: ya existen compras marcadas como Recibidas con esta mercancía
                    {foliosDuplicadosActivos.length > 0 ? ` (${foliosDuplicadosActivos.join(', ')})` : ''}.
                  </span>
                </div>
                <label className="flex items-center gap-2 cursor-pointer text-foreground">
                  <Checkbox
                    checked={confirmoDoble}
                    onCheckedChange={(v) => {
                      setConfirmoDoble(Boolean(v));
                      setErrorRecibir(null);
                    }}
                  />
                  <span>Confirmo que no es la misma mercancía</span>
                </label>
              </div>
            )}

            {resumenExito && (
              <div className="p-3 rounded-md border border-emerald-500/40 bg-emerald-500/10 space-y-2 text-xs text-foreground">
                <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2">
                  <div className="flex items-center gap-2 font-semibold">
                    <CheckCircle2 className="h-4 w-4 text-emerald-600 dark:text-emerald-400 shrink-0" />
                    <span>
                      Recepción registrada: {resumenExito.total_lineas} partida(s) ingresada(s) al inventario.
                    </span>
                  </div>
                  {onIrAInventario && (
                    <Button
                      size="sm"
                      variant="outline"
                      onClick={() => {
                        onOpenChange(false);
                        onIrAInventario();
                      }}
                      className="gap-1.5 self-start sm:self-auto"
                    >
                      <ExternalLink className="h-3.5 w-3.5" />
                      Ver en Inventario
                    </Button>
                  )}
                </div>
                {resumenExito.lineas.length > 0 && (
                  <ul className="list-disc pl-5 space-y-0.5 text-[11px] text-muted-foreground">
                    {resumenExito.lineas.map((l, idx) => (
                      <li key={idx}>
                        <strong className="text-foreground">{l.producto_nombre}</strong>: +{formatearCantidadStock(l.cantidad_recibida)} · Costo s/IVA {fmtMoneda(l.costo_unitario_mxn)}
                        {!l.costo_actualizado ? ' (factura anterior, último costo conservado)' : ''}
                      </li>
                    ))}
                  </ul>
                )}
              </div>
            )}

            {errorRecibir && (
              <div
                role="alert"
                className="flex items-start gap-2 p-2.5 rounded-md border border-destructive/40 bg-destructive/10 text-xs text-destructive"
              >
                <AlertCircle className="h-4 w-4 shrink-0 mt-0.5" />
                <span>{errorRecibir}</span>
              </div>
            )}

            <div className="text-xs text-muted-foreground">
              {propuesta.lineas.length} concepto(s) en la factura · {seleccionadas.length} listo(s) para recibir
            </div>

            {propuesta.lineas.length === 0 ? (
              <div className="py-10 text-center text-sm text-muted-foreground border border-border rounded-md">
                Esta factura no tiene partidas de tipo concepto.
              </div>
            ) : (
              <div className="border border-border rounded-lg overflow-x-auto">
                <table className="w-full text-xs border-collapse">
                  <thead className="bg-muted/50 border-b border-border text-muted-foreground">
                    <tr>
                      <th className="p-2 text-left w-8">Inc.</th>
                      <th className="p-2 text-left min-w-[190px]">Concepto XML</th>
                      <th className="p-2 text-left min-w-[210px]">Producto inventario</th>
                      <th className="p-2 text-left min-w-[90px]">Factor</th>
                      <th className="p-2 text-left min-w-[100px]">Cant. a recibir</th>
                      <th className="p-2 text-right min-w-[140px]">Costo s/IVA vs Cat.</th>
                      <th className="p-2 text-left min-w-[145px]">Banderas</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-border/60">
                    {propuesta.lineas.map((p) => {
                      const f = filas[p.partida_id] || {
                        seleccionada: false,
                        productoId: '',
                        factorStr: '1',
                        cantidadStr: String(p.cantidad_xml),
                        cantidadManual: false,
                        guardarAlias: false,
                      };
                      const calc = calcularFila(p);
                      const prodActual = f.productoId ? productosMap.get(f.productoId) : null;
                      const mostrarFactor = p.banderas.requiere_factor || p.banderas.revisar_unidad || f.factorStr !== '1';

                      return (
                        <tr
                          key={p.partida_id}
                          className={
                            p.banderas.ya_recibida || p.banderas.es_servicio_probable
                              ? 'bg-muted/25 opacity-80'
                              : 'hover:bg-muted/20'
                          }
                        >
                          <td className="p-2 align-top">
                            <Checkbox
                              aria-label={`Recibir partida ${p.descripcion}`}
                              checked={f.seleccionada && calc.puedeRecibir}
                              disabled={!calc.puedeRecibir}
                              onCheckedChange={(checked) =>
                                updateFila(p.partida_id, { seleccionada: Boolean(checked) })
                              }
                            />
                          </td>

                          <td className="p-2 align-top space-y-1">
                            <div className="font-medium text-foreground break-words">{p.descripcion}</div>
                            <div className="flex flex-wrap items-center gap-1.5 text-[11px] text-muted-foreground font-mono">
                              <span>XML: {formatearCantidadStock(p.cantidad_xml)}</span>
                              <Badge variant="secondary" className="text-[10px] font-mono py-0">
                                {p.clave_unidad || 'S/U'}
                              </Badge>
                              <span>Imp: {fmtMoneda(p.importe)}</span>
                            </div>
                          </td>

                          <td className="p-2 align-top space-y-1.5">
                            <div className="flex items-center gap-1.5 flex-wrap">
                              {p.sugerencia_origen === 'alias' && (
                                <Badge variant="default" className="text-[10px] py-0 gap-1">
                                  <BookmarkCheck className="h-3 w-3" />
                                  Recordado
                                </Badge>
                              )}
                              {p.sugerencia_origen === 'similitud' && (
                                <Badge variant="secondary" className="text-[10px] py-0 gap-1">
                                  <Sparkles className="h-3 w-3" />
                                  Sugerido
                                </Badge>
                              )}
                              {p.sugerencia_origen === 'ninguna' && (
                                <Badge variant="outline" className="text-[10px] py-0 text-muted-foreground">
                                  Sin sugerencia
                                </Badge>
                              )}
                              {prodActual && (
                                <span className="text-[10px] text-muted-foreground font-mono">
                                  Stock: {formatearCantidadStock(prodActual.stock_actual)} {prodActual.unidad}
                                </span>
                              )}
                            </div>

                            <select
                              aria-label={`Producto para ${p.descripcion}`}
                              disabled={p.banderas.ya_recibida}
                              value={f.productoId}
                              onChange={(e) => {
                                const nextProd = e.target.value;
                                updateFila(p.partida_id, {
                                  productoId: nextProd,
                                  seleccionada:
                                    Boolean(nextProd) &&
                                    !calc.bloqueadaUnidad &&
                                    !p.banderas.bloqueada_tipo_cambio,
                                  guardarAlias: Boolean(nextProd),
                                });
                              }}
                              className="w-full h-8 rounded-md border border-border bg-background px-2 text-xs text-foreground"
                            >
                              <option value="">— No recibir (ignorar) —</option>
                              {productosFiltrados.map((pr) => (
                                <option key={pr.id} value={pr.id}>
                                  {pr.nombre} ({pr.unidad})
                                </option>
                              ))}
                              {f.productoId &&
                                !productosFiltrados.some((pr) => pr.id === f.productoId) &&
                                propuesta.productos
                                  .filter((pr) => pr.id === f.productoId)
                                  .map((pr) => (
                                    <option key={pr.id} value={pr.id}>
                                      {pr.nombre} ({pr.unidad})
                                    </option>
                                  ))}
                            </select>
                          </td>

                          <td className="p-2 align-top space-y-1">
                            {mostrarFactor ? (
                              <>
                                <Input
                                  aria-label={`Factor para ${p.descripcion}`}
                                  type="number"
                                  step="any"
                                  min="0.0001"
                                  disabled={p.banderas.ya_recibida}
                                  value={f.factorStr}
                                  placeholder={p.banderas.requiere_factor ? 'factor' : '1'}
                                  onChange={(e) => {
                                    const val = e.target.value;
                                    const num = parseFloat(val);
                                    const nextCant =
                                      !f.cantidadManual && Number.isFinite(num) && num > 0
                                        ? String(Math.round(p.cantidad_xml * num * 10000) / 10000)
                                        : f.cantidadStr;
                                    updateFila(p.partida_id, {
                                      factorStr: val,
                                      cantidadStr: nextCant,
                                      seleccionada:
                                        f.seleccionada ||
                                        (Boolean(f.productoId) &&
                                          Number.isFinite(num) &&
                                          num > 0 &&
                                          !p.banderas.bloqueada_tipo_cambio),
                                    });
                                  }}
                                  className={`h-8 w-20 text-xs font-mono text-right bg-background ${
                                    calc.bloqueadaUnidad ? 'border-destructive' : ''
                                  }`}
                                />
                                <div className="text-[10px] text-muted-foreground">
                                  {p.banderas.requiere_factor ? 'Obligatorio' : 'Conversión'}
                                </div>
                              </>
                            ) : (
                              <span className="text-[11px] text-muted-foreground font-mono">×1</span>
                            )}
                          </td>

                          <td className="p-2 align-top space-y-1">
                            <Input
                              aria-label={`Cantidad a recibir para ${p.descripcion}`}
                              type="number"
                              step="any"
                              min="0.0001"
                              disabled={p.banderas.ya_recibida}
                              value={f.cantidadStr}
                              onChange={(e) =>
                                updateFila(p.partida_id, {
                                  cantidadStr: e.target.value,
                                  cantidadManual: true,
                                })
                              }
                              className="h-8 w-24 text-xs font-mono text-right bg-background"
                            />
                            {prodActual && (
                              <div className="text-[10px] text-muted-foreground">{prodActual.unidad}</div>
                            )}
                          </td>

                          <td className="p-2 align-top text-right font-mono space-y-0.5">
                            <div className="font-semibold text-foreground">{fmtMoneda(calc.costoUnitario)}</div>
                            {calc.costoCatalogo !== null && (
                              <div className="text-[10px] text-muted-foreground">
                                Cat: {fmtMoneda(calc.costoCatalogo)}
                                {calc.diferenciaPct !== null && (
                                  <span
                                    className={`ml-1 ${
                                      Math.abs(calc.diferenciaPct) > 20
                                        ? 'text-amber-600 dark:text-amber-400 font-semibold'
                                        : ''
                                    }`}
                                  >
                                    ({calc.diferenciaPct > 0 ? '+' : ''}{calc.diferenciaPct}%)
                                  </span>
                                )}
                              </div>
                            )}
                          </td>

                          <td className="p-2 align-top space-y-1">
                            {p.banderas.ya_recibida && (
                              <div className="inline-flex items-center gap-1 text-[11px] text-emerald-700 dark:text-emerald-400 font-medium">
                                <CheckCircle2 className="h-3.5 w-3.5 shrink-0" />
                                Ya recibida
                              </div>
                            )}

                            {p.banderas.es_servicio_probable && !p.banderas.ya_recibida && (
                              <div className="inline-flex items-center gap-1 text-[11px] text-muted-foreground">
                                <AlertTriangle className="h-3.5 w-3.5 shrink-0" />
                                Servicio probable
                              </div>
                            )}

                            {p.banderas.bloqueada_tipo_cambio && (
                              <div className="inline-flex items-center gap-1 text-[11px] text-destructive font-medium">
                                <AlertCircle className="h-3.5 w-3.5 shrink-0" />
                                USD sin TC
                              </div>
                            )}

                            {calc.bloqueadaUnidad && !p.banderas.ya_recibida && (
                              <div className="inline-flex items-center gap-1 text-[11px] text-destructive font-medium">
                                <Scale className="h-3.5 w-3.5 shrink-0" />
                                Captura factor ({p.clave_unidad})
                              </div>
                            )}

                            {calc.costoFechaAnterior && !p.banderas.ya_recibida && (
                              <div className="inline-flex items-center gap-1 text-[11px] text-amber-700 dark:text-amber-400">
                                <AlertTriangle className="h-3.5 w-3.5 shrink-0" />
                                Factura vieja (no pisa costo)
                              </div>
                            )}

                            {calc.foliosDup.length > 0 && !p.banderas.ya_recibida && (
                              <div className="inline-flex items-center gap-1 text-[11px] text-destructive">
                                <AlertTriangle className="h-3.5 w-3.5 shrink-0" />
                                En compra {calc.foliosDup.join(', ')}
                              </div>
                            )}

                            {!p.banderas.ya_recibida && f.productoId && (
                              <label className="flex items-center gap-1.5 text-[11px] text-muted-foreground cursor-pointer">
                                <Checkbox
                                  checked={f.guardarAlias}
                                  onCheckedChange={(v) =>
                                    updateFila(p.partida_id, { guardarAlias: Boolean(v) })
                                  }
                                />
                                <span>Recordar</span>
                              </label>
                            )}
                          </td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              </div>
            )}
          </div>
        )}

        <DialogFooter className="gap-2 pt-2 border-t border-border/60">
          <Button variant="outline" onClick={() => onOpenChange(false)} disabled={recibiendo}>
            Cerrar
          </Button>
          {estadoCarga === 'ok' && propuesta && (
            <Button
              onClick={handleRecibir}
              disabled={recibiendo || seleccionadas.length === 0}
              className="gap-1.5"
            >
              {recibiendo && <Loader2 className="h-4 w-4 animate-spin" />}
              Recibir {seleccionadas.length} seleccionada{seleccionadas.length === 1 ? '' : 's'}
            </Button>
          )}
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
