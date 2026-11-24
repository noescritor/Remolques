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
import { Label } from '../ui/label';
import { Badge } from '../ui/badge';
import { Checkbox } from '../ui/checkbox';
import {
  AlertCircle,
  AlertTriangle,
  ArrowRight,
  BookmarkCheck,
  CheckCircle2,
  ExternalLink,
  Loader2,
  RefreshCw,
  Scale,
  Sparkles,
} from 'lucide-react';
import { toast } from 'sonner';
import {
  aplicarPreciosAceroCfdiApi,
  fetchPropuestaAceroCfdi,
  LineaAplicarAceroCfdi,
  PropuestaAceroCfdi,
  PropuestaPartidaAcero,
} from '../../utils/aceroApi';

interface AplicarPreciosAceroCfdiModalProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  facturaId: string | null;
  facturaFolio?: string;
  supabase: any;
  onAplicado?: () => void;
  onIrAMatriz?: () => void;
}

interface EstadoFila {
  seleccionada: boolean;
  materialId: string;
  factorStr: string;
  recordarAlias: boolean;
  confirmarFechaAnterior: boolean;
  confirmarVariacionAlta: boolean;
}

const TASA_IVA_ACERO = 0.16;
const UMBRAL_VARIACION_PRECIO = 0.30;

const fmtMoneda = (v: number | null | undefined) => {
  if (v === null || v === undefined || !Number.isFinite(v)) return '—';
  return new Intl.NumberFormat('es-MX', {
    style: 'currency',
    currency: 'MXN',
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(v);
};

export function AplicarPreciosAceroCfdiModal({
  open,
  onOpenChange,
  facturaId,
  facturaFolio,
  supabase,
  onAplicado,
  onIrAMatriz,
}: AplicarPreciosAceroCfdiModalProps) {
  const [estadoCarga, setEstadoCarga] = useState<'cargando' | 'error' | 'ok'>('cargando');
  const [errorCarga, setErrorCarga] = useState<string | null>(null);
  const [propuesta, setPropuesta] = useState<PropuestaAceroCfdi | null>(null);

  // Proveedor destino en matriz de acero
  const [proveedorModo, setProveedorModo] = useState<'existente' | 'nuevo'>('existente');
  const [proveedorSeleccionado, setProveedorSeleccionado] = useState('');
  const [proveedorNuevo, setProveedorNuevo] = useState('');

  // Estado editable por partida_id
  const [filas, setFilas] = useState<Record<string, EstadoFila>>({});
  const [busquedaMaterial, setBusquedaMaterial] = useState('');

  // Envío y resultado
  const [aplicando, setAplicando] = useState(false);
  const guardandoRef = useRef(false);
  const [errorAplicar, setErrorAplicar] = useState<string | null>(null);
  const [resultadoAplicar, setResultadoAplicar] = useState<{
    total: number;
    folio: string;
  } | null>(null);

  const proveedorFinal = useMemo(() => {
    return (proveedorModo === 'nuevo' ? proveedorNuevo : proveedorSeleccionado).trim();
  }, [proveedorModo, proveedorNuevo, proveedorSeleccionado]);

  const inicializarFilas = (data: PropuestaAceroCfdi) => {
    const provs = data.proveedores_acero || [];
    const primeraConProv = data.lineas.find((l) => l.proveedor_acero_sugerido)?.proveedor_acero_sugerido;
    const sugerido = (primeraConProv || data.factura.proveedor_nombre || '').trim();
    if (sugerido && provs.includes(sugerido)) {
      setProveedorModo('existente');
      setProveedorSeleccionado(sugerido);
      setProveedorNuevo('');
    } else if (sugerido) {
      setProveedorModo('nuevo');
      setProveedorNuevo(sugerido);
      setProveedorSeleccionado(provs[0] || '');
    } else if (provs.length > 0) {
      setProveedorModo('existente');
      setProveedorSeleccionado(provs[0]);
      setProveedorNuevo('');
    } else {
      setProveedorModo('nuevo');
      setProveedorNuevo('');
      setProveedorSeleccionado('');
    }

    const nextFilas: Record<string, EstadoFila> = {};
    for (const p of data.lineas) {
      const matId = p.material_id_sugerido || '';
      const factorInit =
        p.banderas.requiere_factor && p.banderas.bloqueada_unidad
          ? ''
          : String(p.factor_conversion_sugerido || 1);
      const puedeAutoSeleccionar =
        !p.banderas.ya_aplicada &&
        Boolean(matId) &&
        !p.banderas.bloqueada_tipo_cambio &&
        !p.banderas.bloqueada_unidad;
      nextFilas[p.partida_id] = {
        seleccionada: puedeAutoSeleccionar,
        materialId: matId,
        factorStr: factorInit,
        recordarAlias: Boolean(matId) && !p.banderas.ya_aplicada,
        confirmarFechaAnterior: false,
        confirmarVariacionAlta: false,
      };
    }
    setFilas(nextFilas);
  };

  const cargarPropuesta = async () => {
    if (!facturaId) return;
    setEstadoCarga('cargando');
    setErrorCarga(null);
    setErrorAplicar(null);
    setResultadoAplicar(null);
    try {
      const data = await fetchPropuestaAceroCfdi(supabase, facturaId);
      setPropuesta(data);
      inicializarFilas(data);
      setEstadoCarga('ok');
    } catch (err: any) {
      setErrorCarga(err?.message || 'No se pudo cargar la propuesta de precios.');
      setEstadoCarga('error');
    }
  };

  useEffect(() => {
    if (open && facturaId) {
      setBusquedaMaterial('');
      cargarPropuesta();
    }
  }, [open, facturaId]);

  const mapaPreciosActuales = useMemo(() => {
    const map = new Map<string, { precio: number; incluye_iva: boolean; precio_sin_iva: number }>();
    if (!propuesta) return map;
    for (const pr of propuesta.precios_actuales || []) {
      const precio = Number(pr.precio);
      const incluye_iva = Boolean(pr.incluye_iva);
      const precio_sin_iva =
        pr.precio_sin_iva !== null && pr.precio_sin_iva !== undefined && Number.isFinite(Number(pr.precio_sin_iva))
          ? Number(pr.precio_sin_iva)
          : incluye_iva
          ? precio / (1 + TASA_IVA_ACERO)
          : precio;
      map.set(`${pr.material_id}::${pr.proveedor.toUpperCase()}`, {
        precio,
        incluye_iva,
        precio_sin_iva,
      });
    }
    return map;
  }, [propuesta]);

  const materialesFiltrados = useMemo(() => {
    if (!propuesta) return [];
    const q = busquedaMaterial.trim().toLowerCase();
    if (!q) return propuesta.materiales;
    return propuesta.materiales.filter(
      (m) => m.nombre.toLowerCase().includes(q) || m.tipo.toLowerCase().includes(q)
    );
  }, [propuesta, busquedaMaterial]);

  const calcularFila = (p: PropuestaPartidaAcero) => {
    const f = filas[p.partida_id];
    if (!f || !propuesta) {
      return {
        precioNuevo: null as number | null,
        precioActual: null as number | null,
        precioActualIncluyeIva: null as boolean | null,
        variacionPct: null as number | null,
        variacionAlta: false,
        factorValido: false,
        bloqueadaUnidad: p.banderas.requiere_factor,
        puedeAplicar: false,
      };
    }

    const factorNum = parseFloat(f.factorStr);
    const factorValido = Number.isFinite(factorNum) && factorNum > 0;
    const bloqueadaUnidad = p.banderas.requiere_factor && !factorValido;

    let tc = 1;
    if (propuesta.factura.moneda === 'USD') {
      tc = Number(propuesta.factura.tipo_cambio_emision || 0);
    }
    const precioNuevo =
      !p.banderas.bloqueada_tipo_cambio && factorValido && p.cantidad > 0 && p.importe > 0
        ? Math.round(((p.importe / p.cantidad) * tc * factorNum) * 100) / 100
        : null;

    const actualRow =
      f.materialId && proveedorFinal
        ? mapaPreciosActuales.get(`${f.materialId}::${proveedorFinal.toUpperCase()}`) || null
        : null;

    const precioActual = actualRow ? actualRow.precio : null;
    const precioActualIncluyeIva = actualRow ? actualRow.incluye_iva : null;

    // D1: Consumir variación calculada por el servidor cuando no han cambiado material/proveedor/factor;
    // si cambiaron en vivo, usar precio_sin_iva provisto por el servidor con la misma constante TASA_IVA_ACERO.
    const mismoQueServidor =
      f.materialId === (p.material_id_sugerido || '') &&
      proveedorFinal.toUpperCase() === (p.proveedor_acero_sugerido || '').toUpperCase() &&
      factorValido &&
      Math.abs(factorNum - (p.factor_conversion_sugerido || 1)) < 1e-6;

    let variacionPct: number | null = null;
    let variacionAlta = false;
    if (mismoQueServidor) {
      variacionPct = p.banderas.variacion_pct;
      variacionAlta = p.banderas.variacion_alta;
    } else if (precioNuevo !== null && actualRow && actualRow.precio_sin_iva > 0) {
      const ratio = (precioNuevo - actualRow.precio_sin_iva) / actualRow.precio_sin_iva;
      variacionPct = Math.round(ratio * 10000) / 100;
      variacionAlta = Math.abs(ratio) > UMBRAL_VARIACION_PRECIO;
    }

    const puedeAplicar =
      !p.banderas.ya_aplicada &&
      !p.banderas.bloqueada_tipo_cambio &&
      !bloqueadaUnidad &&
      Boolean(f.materialId) &&
      precioNuevo !== null;

    return {
      precioNuevo,
      precioActual,
      precioActualIncluyeIva,
      variacionPct,
      variacionAlta,
      factorValido,
      bloqueadaUnidad,
      puedeAplicar,
    };
  };

  const updateFila = (partidaId: string, patch: Partial<EstadoFila>) => {
    setFilas((prev) => ({
      ...prev,
      [partidaId]: {
        ...prev[partidaId],
        ...patch,
      },
    }));
    setErrorAplicar(null);
  };

  const seleccionadas = useMemo(() => {
    if (!propuesta) return [];
    return propuesta.lineas.filter((p) => {
      const f = filas[p.partida_id];
      const calc = calcularFila(p);
      return f?.seleccionada && calc.puedeAplicar;
    });
  }, [propuesta, filas, proveedorFinal, mapaPreciosActuales]);

  const faltanConfirmaciones = useMemo(() => {
    for (const p of seleccionadas) {
      const f = filas[p.partida_id];
      const calc = calcularFila(p);
      if (p.banderas.fecha_anterior && !f.confirmarFechaAnterior) {
        return 'Confirma las partidas marcadas con fecha anterior al último precio XML.';
      }
      if (calc.variacionAlta && !f.confirmarVariacionAlta) {
        return 'Confirma las partidas con variación mayor al 30%.';
      }
    }
    return null;
  }, [seleccionadas, filas, proveedorFinal, mapaPreciosActuales]);

  const handleAplicar = async () => {
    if (!facturaId || !propuesta) return;
    if (guardandoRef.current) return;

    if (!proveedorFinal) {
      setErrorAplicar('Selecciona o escribe el nombre del proveedor en la matriz de acero.');
      return;
    }
    if (seleccionadas.length === 0) {
      setErrorAplicar('Selecciona al menos una partida válida para aplicar.');
      return;
    }
    if (faltanConfirmaciones) {
      setErrorAplicar(faltanConfirmaciones);
      return;
    }

    // D3: Jamás convertir en silencio un factor inválido a 1
    const lineas: LineaAplicarAceroCfdi[] = [];
    for (const p of seleccionadas) {
      const f = filas[p.partida_id];
      const factorNum = parseFloat(f.factorStr);
      if (!Number.isFinite(factorNum) || factorNum <= 0) {
        setErrorAplicar(
          `El factor de conversión para "${p.descripcion}" debe ser un número mayor a cero.`
        );
        return;
      }
      lineas.push({
        partida_id: p.partida_id,
        material_id: f.materialId,
        proveedor_acero: proveedorFinal,
        factor_conversion: factorNum,
        factor_confirmado: true,
        guardar_alias: Boolean(f.recordarAlias),
        forzar_fecha_anterior: Boolean(f.confirmarFechaAnterior),
        forzar_variacion: Boolean(f.confirmarVariacionAlta),
        descripcion_normalizada: p.descripcion_normalizada,
      });
    }

    guardandoRef.current = true;
    setAplicando(true);
    setErrorAplicar(null);
    try {
      const res = await aplicarPreciosAceroCfdiApi(supabase, facturaId, lineas);
      setResultadoAplicar({
        total: res.total ?? lineas.length,
        folio: propuesta.factura.folio,
      });
      toast.success(`Se actualizaron ${res.total ?? lineas.length} precio(s) de acero`);
      if (onAplicado) onAplicado();
      // Recargar propuesta para marcar las partidas como ya aplicadas
      try {
        const refreshed = await fetchPropuestaAceroCfdi(supabase, facturaId);
        setPropuesta(refreshed);
        inicializarFilas(refreshed);
      } catch {
        // Mantener el resumen de éxito aunque falle el refresco silencioso
      }
    } catch (err: any) {
      setErrorAplicar(err?.message || 'Error al aplicar precios. Ningún cambio fue guardado.');
      toast.error(err?.message || 'No se pudieron aplicar los precios');
    } finally {
      guardandoRef.current = false;
      setAplicando(false);
    }
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[1060px] max-h-[90vh] flex flex-col bg-card border-border p-4 sm:p-6">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2 text-foreground">
            <Sparkles className="h-5 w-5 text-primary" />
            Actualizar precios de acero desde factura {facturaFolio || propuesta?.factura.folio || ''}
          </DialogTitle>
          <DialogDescription>
            Revisa cada concepto de la factura XML, confirma el material y factor de conversión, y aplica solo los precios que quieras actualizar. Los precios de XML se guardan sin IVA.
          </DialogDescription>
        </DialogHeader>

        {estadoCarga === 'cargando' && (
          <div className="flex items-center justify-center py-16 text-muted-foreground gap-2 text-sm">
            <Loader2 className="h-5 w-5 animate-spin" />
            Analizando partidas y buscando coincidencias en el catálogo de acero...
          </div>
        )}

        {estadoCarga === 'error' && (
          <div className="py-10 px-4 text-center space-y-3 border border-destructive/30 rounded-lg bg-destructive/10">
            <div className="inline-flex items-center gap-2 text-destructive text-sm font-medium">
              <AlertCircle className="h-4 w-4" />
              {errorCarga || 'No se pudo obtener la propuesta de precios.'}
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
            {/* Resumen de factura y proveedor destino */}
            <div className="grid grid-cols-1 md:grid-cols-12 gap-3 p-3 rounded-lg border border-border bg-muted/30">
              <div className="md:col-span-6 space-y-1 text-xs">
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

              <div className="md:col-span-6 space-y-1.5">
                <Label className="text-xs font-medium text-foreground">
                  Proveedor en la matriz de acero
                </Label>
                <div className="flex flex-col sm:flex-row gap-2">
                  <select
                    aria-label="Proveedor en matriz de acero"
                    value={proveedorModo === 'nuevo' ? '__NUEVO__' : proveedorSeleccionado}
                    onChange={(e) => {
                      if (e.target.value === '__NUEVO__') {
                        setProveedorModo('nuevo');
                      } else {
                        setProveedorModo('existente');
                        setProveedorSeleccionado(e.target.value);
                      }
                      setErrorAplicar(null);
                    }}
                    className="h-9 rounded-md border border-border bg-background px-2.5 text-xs text-foreground flex-1"
                  >
                    {propuesta.proveedores_acero.map((prov) => (
                      <option key={prov} value={prov}>
                        {prov}
                      </option>
                    ))}
                    <option value="__NUEVO__">+ Nuevo proveedor...</option>
                  </select>
                  {proveedorModo === 'nuevo' && (
                    <Input
                      aria-label="Nombre del nuevo proveedor de acero"
                      value={proveedorNuevo}
                      onChange={(e) => {
                        setProveedorNuevo(e.target.value);
                        setErrorAplicar(null);
                      }}
                      placeholder="Ej. SERVIACERO"
                      className="h-9 text-xs bg-background flex-1"
                    />
                  )}
                </div>
              </div>
            </div>

            {propuesta.factura.descuento_en_factura && (
              <div className="flex items-start gap-2 p-2.5 rounded-md border border-amber-500/40 bg-amber-500/10 text-xs text-foreground">
                <AlertTriangle className="h-4 w-4 text-amber-600 dark:text-amber-400 shrink-0 mt-0.5" />
                <span>
                  Esta factura trae descuentos; revisa el precio unitario antes de aplicar.
                </span>
              </div>
            )}

            {resultadoAplicar && (
              <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2 p-3 rounded-md border border-emerald-500/40 bg-emerald-500/10 text-xs text-foreground">
                <div className="flex items-center gap-2">
                  <CheckCircle2 className="h-4 w-4 text-emerald-600 dark:text-emerald-400 shrink-0" />
                  <span>
                    <strong>{resultadoAplicar.total} precio(s) actualizado(s)</strong> en la matriz (CFDI {resultadoAplicar.folio}).
                  </span>
                </div>
                {onIrAMatriz && (
                  <Button
                    size="sm"
                    variant="outline"
                    onClick={() => {
                      onOpenChange(false);
                      onIrAMatriz();
                    }}
                    className="gap-1.5 self-start sm:self-auto"
                  >
                    <ExternalLink className="h-3.5 w-3.5" />
                    Ver en Precios de acero
                  </Button>
                )}
              </div>
            )}

            {errorAplicar && (
              <div
                role="alert"
                className="flex items-start gap-2 p-2.5 rounded-md border border-destructive/40 bg-destructive/10 text-xs text-destructive"
              >
                <AlertCircle className="h-4 w-4 shrink-0 mt-0.5" />
                <span>{errorAplicar}</span>
              </div>
            )}

            {/* Filtro rápido de catálogo de materiales */}
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2">
              <div className="text-xs text-muted-foreground">
                {propuesta.lineas.length} concepto(s) en la factura · {seleccionadas.length} listo(s) para aplicar
              </div>
              <Input
                value={busquedaMaterial}
                onChange={(e) => setBusquedaMaterial(e.target.value)}
                placeholder="Filtrar lista de materiales del catálogo..."
                className="h-8 text-xs sm:w-64 bg-background"
              />
            </div>

            {propuesta.lineas.length === 0 ? (
              <div className="py-10 text-center text-sm text-muted-foreground border border-border rounded-md">
                Esta factura no tiene partidas de tipo concepto para proponer precios.
              </div>
            ) : (
              <div className="border border-border rounded-lg overflow-x-auto">
                <table className="w-full text-xs border-collapse">
                  <thead className="bg-muted/50 border-b border-border text-muted-foreground">
                    <tr>
                      <th className="p-2 text-left w-8">Inc.</th>
                      <th className="p-2 text-left min-w-[210px]">Concepto XML</th>
                      <th className="p-2 text-left min-w-[230px]">Material en catálogo</th>
                      <th className="p-2 text-left min-w-[100px]">Factor</th>
                      <th className="p-2 text-right min-w-[155px]">Actual → Nuevo (sin IVA)</th>
                      <th className="p-2 text-left min-w-[150px]">Banderas y alias</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-border/60">
                    {propuesta.lineas.map((p) => {
                      const f = filas[p.partida_id] || {
                        seleccionada: false,
                        materialId: '',
                        factorStr: '1',
                        recordarAlias: false,
                        confirmarFechaAnterior: false,
                        confirmarVariacionAlta: false,
                      };
                      const calc = calcularFila(p);
                      const warnId = `warn-${p.partida_id}`;

                      return (
                        <tr
                          key={p.partida_id}
                          className={p.banderas.ya_aplicada ? 'bg-muted/30 opacity-75' : 'hover:bg-muted/20'}
                        >
                          <td className="p-2 align-top">
                            <Checkbox
                              aria-label={`Seleccionar partida ${p.descripcion}`}
                              aria-describedby={warnId}
                              checked={f.seleccionada && calc.puedeAplicar}
                              disabled={!calc.puedeAplicar}
                              onCheckedChange={(checked) =>
                                updateFila(p.partida_id, { seleccionada: Boolean(checked) })
                              }
                            />
                          </td>

                          <td className="p-2 align-top space-y-1">
                            <div className="font-medium text-foreground break-words">
                              {p.descripcion}
                            </div>
                            <div className="flex flex-wrap items-center gap-1.5 text-[11px] text-muted-foreground font-mono">
                              <span>Cant: {p.cantidad}</span>
                              <Badge variant="secondary" className="text-[10px] font-mono py-0">
                                {p.clave_unidad || 'S/U'}
                              </Badge>
                              <span>PU XML: {fmtMoneda(p.precio_unitario_xml)}</span>
                            </div>
                          </td>

                          <td className="p-2 align-top space-y-1.5">
                            <div className="flex items-center gap-1.5">
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
                            </div>

                            <select
                              aria-label={`Material para ${p.descripcion}`}
                              disabled={p.banderas.ya_aplicada}
                              value={f.materialId}
                              onChange={(e) => {
                                const nextMat = e.target.value;
                                updateFila(p.partida_id, {
                                  materialId: nextMat,
                                  seleccionada: Boolean(nextMat) && !calc.bloqueadaUnidad && !p.banderas.bloqueada_tipo_cambio,
                                  recordarAlias: Boolean(nextMat),
                                });
                              }}
                              className="w-full h-8 rounded-md border border-border bg-background px-2 text-xs text-foreground"
                            >
                              <option value="">— No aplicar (ignorar) —</option>
                              {materialesFiltrados.map((m) => (
                                <option key={m.id} value={m.id}>
                                  [{m.tipo}] {m.nombre}
                                </option>
                              ))}
                              {f.materialId &&
                                !materialesFiltrados.some((m) => m.id === f.materialId) &&
                                propuesta.materiales
                                  .filter((m) => m.id === f.materialId)
                                  .map((m) => (
                                    <option key={m.id} value={m.id}>
                                      [{m.tipo}] {m.nombre}
                                    </option>
                                  ))}
                            </select>
                          </td>

                          <td className="p-2 align-top space-y-1">
                            <Input
                              aria-label={`Factor de conversión para ${p.descripcion}`}
                              type="number"
                              step="0.01"
                              min="0.0001"
                              disabled={p.banderas.ya_aplicada}
                              value={f.factorStr}
                              placeholder={p.banderas.requiere_factor ? 'kg/pza' : '1'}
                              onChange={(e) => {
                                const val = e.target.value;
                                const num = parseFloat(val);
                                updateFila(p.partida_id, {
                                  factorStr: val,
                                  seleccionada:
                                    f.seleccionada ||
                                    (Boolean(f.materialId) && Number.isFinite(num) && num > 0 && !p.banderas.bloqueada_tipo_cambio),
                                });
                              }}
                              className={`h-8 w-24 text-xs font-mono text-right bg-background ${
                                calc.bloqueadaUnidad ? 'border-destructive' : ''
                              }`}
                            />
                            <div className="text-[10px] text-muted-foreground">
                              {p.banderas.requiere_factor ? 'Obligatorio (kg/pza)' : 'Unid. por pieza'}
                            </div>
                          </td>

                          <td className="p-2 align-top text-right font-mono space-y-1">
                            <div className="flex items-center justify-end gap-1">
                              <span className="text-muted-foreground">
                                {calc.precioActual !== null ? fmtMoneda(calc.precioActual) : 'Nuevo'}
                              </span>
                              <ArrowRight className="h-3 w-3 text-muted-foreground shrink-0" />
                              <span className="font-semibold text-foreground">
                                {fmtMoneda(calc.precioNuevo)}
                              </span>
                            </div>
                            {calc.precioActualIncluyeIva && (
                              <div className="text-[10px] text-muted-foreground">
                                Actual incluye IVA
                              </div>
                            )}
                            {calc.variacionPct !== null && (
                              <div
                                className={`text-[11px] font-semibold ${
                                  calc.variacionAlta
                                    ? 'text-destructive'
                                    : calc.variacionPct > 0
                                    ? 'text-amber-600 dark:text-amber-400'
                                    : 'text-emerald-600 dark:text-emerald-400'
                                }`}
                              >
                                {calc.variacionPct > 0 ? '+' : ''}
                                {calc.variacionPct}%
                              </div>
                            )}
                          </td>

                          <td id={warnId} className="p-2 align-top space-y-1.5">
                            {p.banderas.ya_aplicada && (
                              <div className="inline-flex items-center gap-1 text-[11px] text-emerald-700 dark:text-emerald-400 font-medium">
                                <CheckCircle2 className="h-3.5 w-3.5 shrink-0" />
                                Ya aplicada
                              </div>
                            )}

                            {p.banderas.bloqueada_tipo_cambio && (
                              <div className="inline-flex items-center gap-1 text-[11px] text-destructive font-medium">
                                <AlertCircle className="h-3.5 w-3.5 shrink-0" />
                                USD sin tipo de cambio
                              </div>
                            )}

                            {calc.bloqueadaUnidad && !p.banderas.ya_aplicada && (
                              <div className="inline-flex items-center gap-1 text-[11px] text-destructive font-medium">
                                <Scale className="h-3.5 w-3.5 shrink-0" />
                                Captura kg/pieza
                              </div>
                            )}

                            {p.banderas.revisar_unidad && !p.banderas.ya_aplicada && (
                              <div className="inline-flex items-center gap-1 text-[11px] text-amber-700 dark:text-amber-400">
                                <AlertTriangle className="h-3.5 w-3.5 shrink-0" />
                                Revisar unidad ({p.clave_unidad})
                              </div>
                            )}

                            {p.banderas.fecha_anterior && !p.banderas.ya_aplicada && (
                              <label className="flex items-start gap-1.5 text-[11px] text-amber-700 dark:text-amber-400 cursor-pointer">
                                <Checkbox
                                  checked={f.confirmarFechaAnterior}
                                  onCheckedChange={(v) =>
                                    updateFila(p.partida_id, { confirmarFechaAnterior: Boolean(v) })
                                  }
                                  className="mt-0.5"
                                />
                                <span>Factura más vieja que último precio (confirmar)</span>
                              </label>
                            )}

                            {calc.variacionAlta && !p.banderas.ya_aplicada && (
                              <label className="flex items-start gap-1.5 text-[11px] text-destructive cursor-pointer">
                                <Checkbox
                                  checked={f.confirmarVariacionAlta}
                                  onCheckedChange={(v) =>
                                    updateFila(p.partida_id, { confirmarVariacionAlta: Boolean(v) })
                                  }
                                  className="mt-0.5"
                                />
                                <span>Variación &gt; 30% (confirmar)</span>
                              </label>
                            )}

                            {!p.banderas.ya_aplicada && f.materialId && (
                              <label className="flex items-center gap-1.5 text-[11px] text-muted-foreground cursor-pointer">
                                <Checkbox
                                  checked={f.recordarAlias}
                                  onCheckedChange={(v) =>
                                    updateFila(p.partida_id, { recordarAlias: Boolean(v) })
                                  }
                                />
                                <span>Recordar coincidencia</span>
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
          <Button variant="outline" onClick={() => onOpenChange(false)} disabled={aplicando}>
            Cerrar
          </Button>
          {estadoCarga === 'ok' && propuesta && (
            <Button
              onClick={handleAplicar}
              disabled={aplicando || seleccionadas.length === 0 || !proveedorFinal}
              className="gap-1.5"
            >
              {aplicando && <Loader2 className="h-4 w-4 animate-spin" />}
              Aplicar {seleccionadas.length} seleccionada{seleccionadas.length === 1 ? '' : 's'}
            </Button>
          )}
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
