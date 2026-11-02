import React, { useState, useEffect } from 'react';
import { OrdenTrabajo } from '../../types';
import { Button } from '../ui/button';
import { Badge } from '../ui/badge';
import { Input } from '../ui/input';
import { Label } from '../ui/label';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from '../ui/dialog';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../ui/select';
import {
  ClipboardCheck,
  PackageCheck,
  CheckCircle2,
  AlertCircle,
  Clock,
  Printer,
  RefreshCw,
  RotateCcw,
  Plus,
  Trash2,
  ChevronDown,
  ChevronRight,
  ShieldAlert,
} from 'lucide-react';
import { BASE_URL } from '../../utils/api';

interface ChecklistDespieceModalProps {
  orden: OrdenTrabajo | null;
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

export function ChecklistDespieceModal({ orden, open, onOpenChange }: ChecklistDespieceModalProps) {
  const [loading, setLoading] = useState(false);
  const [generando, setGenerando] = useState(false);
  const [datos, setDatos] = useState<any>(null);
  const [operarios, setOperarios] = useState<any[]>([]);
  const [fasesExpandidas, setFasesExpandidas] = useState<Record<string, boolean>>({});
  const [errorMsg, setErrorMsg] = useState<string | null>(null);

  // Modales secundarios
  const [modalEntregaOpen, setModalEntregaOpen] = useState(false);
  const [lineaSeleccionada, setLineaSeleccionada] = useState<any>(null);
  const [tipoEntrega, setTipoEntrega] = useState<'entrega' | 'reposicion'>('entrega');
  const [cantEntrega, setCantEntrega] = useState<number>(1);
  const [operarioId, setOperarioId] = useState<string>('');
  const [operarioNombreManual, setOperarioNombreManual] = useState<string>('');
  const [motivoEntrega, setMotivoEntrega] = useState<string>('');
  const [procesandoAccion, setProcesandoAccion] = useState(false);

  // Modal anular
  const [modalAnularOpen, setModalAnularOpen] = useState(false);
  const [entregaAAnular, setEntregaAAnular] = useState<any>(null);
  const [motivoAnulacion, setMotivoAnulacion] = useState('');

  // Modal agregar partida manual
  const [modalAgregarOpen, setModalAgregarOpen] = useState(false);
  const [manualFaseClave, setManualFaseClave] = useState('paso_1');
  const [manualDesc, setManualDesc] = useState('');
  const [manualUnidad, setManualUnidad] = useState('pz');
  const [manualCant, setManualCant] = useState(1);

  const cargarDatosDespiece = async () => {
    if (!orden) return;
    setLoading(true);
    setErrorMsg(null);
    try {
      const { supabase: supa } = await import('../../utils/supabase/client');
      const session = (await supa.auth.getSession()).data.session;
      const token = session?.access_token;
      const orgId = session?.user?.user_metadata?.organizacion_id || localStorage.getItem('org_id');

      const headers: Record<string, string> = {};
      if (token) headers['Authorization'] = `Bearer ${token}`;
      if (orgId) headers['x-org-id'] = orgId;

      const res = await fetch(`${BASE_URL}/ordenes-trabajo/${orden.id}/despiece`, { headers });
      if (!res.ok) throw new Error(`Error ${res.status}: ${res.statusText}`);
      const data = await res.json();
      setDatos(data);

      // Cargar lista de operarios si no se ha cargado
      if (operarios.length === 0) {
        const resOps = await fetch(`${BASE_URL}/operarios`, { headers });
        if (resOps.ok) {
          const opsData = await resOps.json();
          setOperarios(opsData || []);
        }
      }
    } catch (err: any) {
      console.error('Error cargando checklist:', err);
      setErrorMsg(err.message || 'Error al cargar despiece');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (open && orden) {
      cargarDatosDespiece();
    }
  }, [open, orden?.id]);

  const handleGenerarDespiece = async (forzar = false) => {
    if (!orden) return;
    setGenerando(true);
    setErrorMsg(null);
    try {
      const { supabase: supa } = await import('../../utils/supabase/client');
      const session = (await supa.auth.getSession()).data.session;
      const token = session?.access_token;
      const orgId = session?.user?.user_metadata?.organizacion_id || localStorage.getItem('org_id');

      const headers: Record<string, string> = { 'Content-Type': 'application/json' };
      if (token) headers['Authorization'] = `Bearer ${token}`;
      if (orgId) headers['x-org-id'] = orgId;

      const res = await fetch(`${BASE_URL}/ordenes-trabajo/${orden.id}/despiece/generar`, {
        method: 'POST',
        headers,
        body: JSON.stringify({ forzar }),
      });
      if (!res.ok) {
        const errJson = await res.json().catch(() => ({}));
        throw new Error(errJson.error || 'Error al generar despiece');
      }
      await cargarDatosDespiece();
    } catch (err: any) {
      console.error('Error generando despiece:', err);
      setErrorMsg(err.message || 'No se pudo generar el despiece');
    } finally {
      setGenerando(false);
    }
  };

  const handleAbrirEntrega = (linea: any, tipo: 'entrega' | 'reposicion') => {
    setLineaSeleccionada(linea);
    setTipoEntrega(tipo);
    setCantEntrega(tipo === 'entrega' ? Number(linea.cantidad_pendiente) : 1);
    setMotivoEntrega('');
    setModalEntregaOpen(true);
  };

  const handleConfirmarEntrega = async () => {
    if (!lineaSeleccionada || !orden) return;
    if (tipoEntrega === 'reposicion' && !motivoEntrega.trim()) {
      alert('El motivo de reposición es obligatorio');
      return;
    }

    setProcesandoAccion(true);
    try {
      const { supabase: supa } = await import('../../utils/supabase/client');
      const session = (await supa.auth.getSession()).data.session;
      const token = session?.access_token;
      const orgId = session?.user?.user_metadata?.organizacion_id || localStorage.getItem('org_id');

      const opSeleccionado = operarios.find((o) => o.id === operarioId);
      const nombreOp = opSeleccionado?.nombre || operarioNombreManual || 'Operario de taller';

      const headers: Record<string, string> = { 'Content-Type': 'application/json' };
      if (token) headers['Authorization'] = `Bearer ${token}`;
      if (orgId) headers['x-org-id'] = orgId;

      const res = await fetch(`${BASE_URL}/ordenes-trabajo/${orden.id}/despiece/entregar`, {
        method: 'POST',
        headers,
        body: JSON.stringify({
          linea_id: lineaSeleccionada.linea_id,
          cantidad: cantEntrega,
          tipo: tipoEntrega,
          operario_id: operarioId || null,
          operario_nombre: nombreOp,
          motivo: motivoEntrega.trim() || null,
        }),
      });

      if (!res.ok) {
        const errJson = await res.json().catch(() => ({}));
        throw new Error(errJson.error || 'Error al registrar entrega');
      }

      setModalEntregaOpen(false);
      await cargarDatosDespiece();
    } catch (err: any) {
      alert(err.message || 'Error al entregar');
    } finally {
      setProcesandoAccion(false);
    }
  };

  const handleEntregarFaseCompleta = async (faseClave: string) => {
    if (!orden) return;
    const confirm = window.confirm(
      `¿Deseas marcar como entregadas todas las piezas pendientes de la fase ${faseClave}?`
    );
    if (!confirm) return;

    setProcesandoAccion(true);
    try {
      const { supabase: supa } = await import('../../utils/supabase/client');
      const session = (await supa.auth.getSession()).data.session;
      const token = session?.access_token;
      const orgId = session?.user?.user_metadata?.organizacion_id || localStorage.getItem('org_id');

      const headers: Record<string, string> = { 'Content-Type': 'application/json' };
      if (token) headers['Authorization'] = `Bearer ${token}`;
      if (orgId) headers['x-org-id'] = orgId;

      const res = await fetch(`${BASE_URL}/ordenes-trabajo/${orden.id}/despiece/entregar-fase`, {
        method: 'POST',
        headers,
        body: JSON.stringify({
          fase_clave: faseClave,
          operario_nombre: 'Entrega por lote de fase',
        }),
      });

      if (!res.ok) {
        const errJson = await res.json().catch(() => ({}));
        throw new Error(errJson.error || 'Error al entregar fase');
      }

      await cargarDatosDespiece();
    } catch (err: any) {
      alert(err.message || 'Error al entregar fase');
    } finally {
      setProcesandoAccion(false);
    }
  };

  const handleConfirmarAnulacion = async () => {
    if (!entregaAAnular || !orden) return;
    if (!motivoAnulacion.trim()) {
      alert('El motivo de anulación es requerido');
      return;
    }

    setProcesandoAccion(true);
    try {
      const { supabase: supa } = await import('../../utils/supabase/client');
      const session = (await supa.auth.getSession()).data.session;
      const token = session?.access_token;
      const orgId = session?.user?.user_metadata?.organizacion_id || localStorage.getItem('org_id');

      const headers: Record<string, string> = { 'Content-Type': 'application/json' };
      if (token) headers['Authorization'] = `Bearer ${token}`;
      if (orgId) headers['x-org-id'] = orgId;

      const res = await fetch(`${BASE_URL}/ordenes-trabajo/${orden.id}/despiece/anular-entrega`, {
        method: 'POST',
        headers,
        body: JSON.stringify({
          entrega_id: entregaAAnular.id,
          motivo: motivoAnulacion.trim(),
        }),
      });

      if (!res.ok) {
        const errJson = await res.json().catch(() => ({}));
        throw new Error(errJson.error || 'Error al anular entrega');
      }

      setModalAnularOpen(false);
      await cargarDatosDespiece();
    } catch (err: any) {
      alert(err.message || 'Error al anular');
    } finally {
      setProcesandoAccion(false);
    }
  };

  const toggleFase = (clave: string) => {
    setFasesExpandidas((prev) => ({
      ...prev,
      [clave]: prev[clave] === undefined ? false : !prev[clave],
    }));
  };

  const metricas = datos?.metricas || {
    total_lineas: 0,
    lineas_completas: 0,
    total_piezas_requeridas: 0,
    total_piezas_entregadas: 0,
    total_piezas_pendientes: 0,
    porcentaje_avance: 0,
  };

  // Agrupar líneas por fase
  const lineas = datos?.lineas || [];
  const fases = datos?.fases || [];

  const fasesAgrupadas = fases.map((f: any) => {
    const partidasDeFase = lineas.filter((l: any) => l.fase_clave === f.clave);
    const piezasReq = partidasDeFase.reduce((acc: number, l: any) => acc + (Number(l.cantidad_requerida) || 0), 0);
    const piezasEnt = partidasDeFase.reduce((acc: number, l: any) => acc + (Number(l.cantidad_entregada) || 0), 0);
    const completa = piezasReq > 0 && piezasEnt >= piezasReq;
    const avanceFase = piezasReq > 0 ? Math.round((piezasEnt / piezasReq) * 100) : 0;

    return {
      fase: f,
      partidas: partidasDeFase,
      piezasReq,
      piezasEnt,
      completa,
      avanceFase,
    };
  });

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-5xl max-h-[92vh] overflow-y-auto bg-background text-foreground border-border p-6">
        <DialogHeader className="border-b border-border/50 pb-4">
          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
            <div>
              <DialogTitle className="text-2xl font-bold flex items-center gap-2">
                <ClipboardCheck className="h-6 w-6 text-primary" />
                Checklist de Almacén y Control de Entregas
              </DialogTitle>
              <div className="flex flex-wrap items-center gap-2 mt-1 text-xs text-muted-foreground">
                <span className="font-mono font-bold text-foreground">{orden?.nomenclatura_id}</span>
                {orden?.niv && <span>• NIV: {orden.niv}</span>}
                <span>• {orden?.modelo || 'Modelo'}</span>
                <span>• Cliente: {orden?.cliente?.nombre_razon_social || (orden?.cliente as any)?.nombre || '-'}</span>
              </div>
            </div>

            <div className="flex items-center gap-2">
              <Button
                variant="outline"
                size="sm"
                onClick={cargarDatosDespiece}
                disabled={loading}
                className="border-border text-xs"
              >
                <RefreshCw className={`h-3.5 w-3.5 mr-1.5 ${loading ? 'animate-spin' : ''}`} />
                Actualizar
              </Button>
            </div>
          </div>
        </DialogHeader>

        {errorMsg && (
          <div className="p-3 bg-destructive/10 text-destructive border border-destructive/20 rounded-md text-sm flex items-center gap-2 my-2">
            <AlertCircle className="h-4 w-4 shrink-0" />
            <span>{errorMsg}</span>
          </div>
        )}

        {/* Resumen de avance */}
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 my-4">
          <div className="bg-card/50 p-3 rounded-lg border border-border/50">
            <p className="text-[11px] text-muted-foreground uppercase tracking-wider font-mono">Piezas Requeridas</p>
            <p className="text-xl font-bold font-mono text-foreground mt-0.5">{metricas.total_piezas_requeridas}</p>
          </div>
          <div className="bg-card/50 p-3 rounded-lg border border-border/50">
            <p className="text-[11px] text-muted-foreground uppercase tracking-wider font-mono">Entregadas</p>
            <p className="text-xl font-bold font-mono text-emerald-500 mt-0.5">{metricas.total_piezas_entregadas}</p>
          </div>
          <div className="bg-card/50 p-3 rounded-lg border border-border/50">
            <p className="text-[11px] text-muted-foreground uppercase tracking-wider font-mono">Pendientes</p>
            <p className="text-xl font-bold font-mono text-amber-500 mt-0.5">{metricas.total_piezas_pendientes}</p>
          </div>
          <div className="bg-card/50 p-3 rounded-lg border border-border/50">
            <p className="text-[11px] text-muted-foreground uppercase tracking-wider font-mono">Avance de Armado</p>
            <div className="flex items-center gap-2 mt-1">
              <div className="flex-1 bg-muted rounded-full h-2.5 overflow-hidden">
                <div
                  className="bg-emerald-500 h-2.5 transition-all duration-500"
                  style={{ width: `${Math.min(100, metricas.porcentaje_avance)}%` }}
                />
              </div>
              <span className="text-xs font-mono font-bold text-foreground">{metricas.porcentaje_avance}%</span>
            </div>
          </div>
        </div>

        {/* Contenido principal */}
        {lineas.length === 0 ? (
          <div className="text-center py-12 bg-card/30 rounded-xl border border-dashed border-border/70 my-4">
            <PackageCheck className="h-12 w-12 text-muted-foreground mx-auto mb-3 opacity-60" />
            <h3 className="text-lg font-medium text-foreground mb-1">El despiece aún no ha sido cargado</h3>
            <p className="text-sm text-muted-foreground max-w-md mx-auto mb-4">
              Puedes generar el árbol de materiales por fases automáticamente a partir de la receta de producción o el presupuesto del cotizador.
            </p>
            <Button onClick={() => handleGenerarDespiece(false)} disabled={generando} className="bg-primary text-primary-foreground">
              <Plus className="h-4 w-4 mr-2" />
              {generando ? 'Generando despiece...' : 'Generar Despiece por Fases'}
            </Button>
          </div>
        ) : (
          <div className="space-y-4 my-2">
            {/* Acordeón de Fases */}
            {fasesAgrupadas.map(({ fase, partidas, piezasReq, piezasEnt, completa, avanceFase }: any) => {
              if (partidas.length === 0) return null;
              const expandida = fasesExpandidas[fase.clave] !== false; // Abierto por defecto

              return (
                <div key={fase.id} className="rounded-lg border border-border/60 overflow-hidden bg-card/30">
                  <div
                    className="p-3 bg-muted/40 flex items-center justify-between cursor-pointer select-none hover:bg-muted/60 transition-colors"
                    onClick={() => toggleFase(fase.clave)}
                  >
                    <div className="flex items-center gap-2.5">
                      {expandida ? (
                        <ChevronDown className="h-4 w-4 text-muted-foreground" />
                      ) : (
                        <ChevronRight className="h-4 w-4 text-muted-foreground" />
                      )}
                      <div>
                        <span className="font-semibold text-sm text-foreground">{fase.nombre}</span>
                        {fase.subtitulo && (
                          <span className="text-xs text-muted-foreground ml-2 hidden sm:inline">
                            — {fase.subtitulo}
                          </span>
                        )}
                      </div>
                    </div>

                    <div className="flex items-center gap-3" onClick={(e) => e.stopPropagation()}>
                      <div className="text-right text-xs font-mono">
                        <span className="text-emerald-500 font-bold">{piezasEnt}</span>
                        <span className="text-muted-foreground"> / {piezasReq} pz</span>
                      </div>

                      {completa ? (
                        <Badge variant="outline" className="bg-emerald-500/10 text-emerald-500 border-emerald-500/30 text-[10px]">
                          Completa
                        </Badge>
                      ) : (
                        <Button
                          size="sm"
                          variant="outline"
                          className="h-7 text-xs border-border hover:bg-muted"
                          onClick={() => handleEntregarFaseCompleta(fase.clave)}
                          disabled={procesandoAccion}
                        >
                          Entregar fase completa
                        </Button>
                      )}
                    </div>
                  </div>

                  {expandida && (
                    <div className="p-3 border-t border-border/40 overflow-x-auto">
                      <table className="w-full text-xs text-left">
                        <thead className="bg-muted/20 text-muted-foreground uppercase font-mono border-b border-border/40">
                          <tr>
                            <th className="p-2">Partida / Material</th>
                            <th className="p-2 text-right">Req.</th>
                            <th className="p-2 text-right">Entregado</th>
                            <th className="p-2 text-right">Pendiente</th>
                            <th className="p-2">Última Entrega</th>
                            <th className="p-2 text-right">Acción</th>
                          </tr>
                        </thead>
                        <tbody className="divide-y divide-border/30">
                          {partidas.map((l: any) => {
                            const esCompleto = l.estado_entrega === 'completo';
                            const ult = l.ultima_entrega;

                            return (
                              <tr key={l.linea_id} className="hover:bg-muted/10">
                                <td className="p-2">
                                  <div className="font-medium text-foreground">{l.descripcion}</div>
                                  <div className="flex items-center gap-1.5 mt-0.5">
                                    <span className="text-[10px] text-muted-foreground uppercase font-mono">
                                      {l.unidad || 'pz'}
                                    </span>
                                    {l.sin_costo && (
                                      <Badge
                                        variant="outline"
                                        className="text-[9px] border-amber-500/40 text-amber-500 bg-amber-500/10 px-1 py-0"
                                      >
                                        Sin costo cargado
                                      </Badge>
                                    )}
                                    {l.origen === 'manual' && (
                                      <Badge variant="secondary" className="text-[9px] px-1 py-0">
                                        Manual
                                      </Badge>
                                    )}
                                  </div>
                                </td>
                                <td className="p-2 text-right font-mono">{l.cantidad_requerida}</td>
                                <td className="p-2 text-right font-mono font-bold text-emerald-500">
                                  {l.cantidad_entregada}
                                </td>
                                <td className="p-2 text-right font-mono font-bold text-amber-500">
                                  {l.cantidad_pendiente}
                                </td>
                                <td className="p-2 text-xs text-muted-foreground">
                                  {ult ? (
                                    <div>
                                      <span>{ult.operario_nombre}</span>
                                      <div className="text-[10px] opacity-75">{ult.fecha}</div>
                                    </div>
                                  ) : (
                                    <span className="italic opacity-50">Sin entregas</span>
                                  )}
                                </td>
                                <td className="p-2 text-right space-x-1 whitespace-nowrap">
                                  {esCompleto ? (
                                    <Badge
                                      variant="outline"
                                      className="bg-emerald-500/10 text-emerald-500 border-emerald-500/20 text-[10px]"
                                    >
                                      ✓ Entregada
                                    </Badge>
                                  ) : (
                                    <Button
                                      size="sm"
                                      className="h-6 text-[11px] px-2 bg-primary text-primary-foreground"
                                      onClick={() => handleAbrirEntrega(l, 'entrega')}
                                    >
                                      Entregar
                                    </Button>
                                  )}

                                  <Button
                                    size="sm"
                                    variant="ghost"
                                    className="h-6 text-[11px] px-1.5 text-amber-500 hover:text-amber-400"
                                    onClick={() => handleAbrirEntrega(l, 'reposicion')}
                                    title="Registrar reposición por daño o sustitución"
                                  >
                                    + Reposición
                                  </Button>
                                </td>
                              </tr>
                            );
                          })}
                        </tbody>
                      </table>
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        )}

        <DialogFooter className="border-t border-border/50 pt-4 mt-4 flex items-center justify-between">
          <div className="text-xs text-muted-foreground">
            Control de despiece — Leolca Producción & Almacén
          </div>
          <Button variant="outline" onClick={() => onOpenChange(false)}>
            Cerrar
          </Button>
        </DialogFooter>

        {/* Modal Registrar Entrega / Reposición */}
        <Dialog open={modalEntregaOpen} onOpenChange={setModalEntregaOpen}>
          <DialogContent className="max-w-md bg-background border-border">
            <DialogHeader>
              <DialogTitle className="text-lg flex items-center gap-2">
                {tipoEntrega === 'entrega' ? (
                  <PackageCheck className="h-5 w-5 text-emerald-500" />
                ) : (
                  <ShieldAlert className="h-5 w-5 text-amber-500" />
                )}
                {tipoEntrega === 'entrega' ? 'Registrar Entrega de Material' : 'Registrar Reposición de Pieza'}
              </DialogTitle>
            </DialogHeader>

            <div className="space-y-4 py-2">
              <div>
                <Label className="text-xs text-muted-foreground">Pieza</Label>
                <p className="font-semibold text-sm text-foreground">{lineaSeleccionada?.descripcion}</p>
                <div className="flex gap-4 mt-1 text-xs font-mono text-muted-foreground">
                  <span>Requerida: {lineaSeleccionada?.cantidad_requerida}</span>
                  <span>Ya entregada: {lineaSeleccionada?.cantidad_entregada}</span>
                  <span className="text-amber-500 font-bold">Pendiente: {lineaSeleccionada?.cantidad_pendiente}</span>
                </div>
              </div>

              <div className="space-y-1.5">
                <Label>Cantidad a {tipoEntrega === 'entrega' ? 'entregar' : 'reponer'}</Label>
                <Input
                  type="number"
                  step="0.01"
                  min="0.01"
                  value={cantEntrega}
                  onChange={(e) => setCantEntrega(parseFloat(e.target.value))}
                  className="font-mono border-border"
                />
              </div>

              <div className="space-y-1.5">
                <Label>Operario que recibe</Label>
                <Select value={operarioId} onValueChange={setOperarioId}>
                  <SelectTrigger className="border-border">
                    <SelectValue placeholder="Seleccionar operario registrado" />
                  </SelectTrigger>
                  <SelectContent>
                    {operarios.map((op) => (
                      <SelectItem key={op.id} value={op.id}>
                        {op.nombre} {op.puesto ? `(${op.puesto})` : ''}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
                {!operarioId && (
                  <Input
                    placeholder="O escribe nombre del operario..."
                    value={operarioNombreManual}
                    onChange={(e) => setOperarioNombreManual(e.target.value)}
                    className="mt-1 text-xs border-border"
                  />
                )}
              </div>

              <div className="space-y-1.5">
                <Label>
                  Motivo {tipoEntrega === 'reposicion' ? '(Obligatorio)' : '(Opcional)'}
                </Label>
                <Input
                  placeholder={
                    tipoEntrega === 'reposicion'
                      ? 'Ej. Pieza doblada en montaje, sustitución por defecto...'
                      : 'Notas de entrega'
                  }
                  value={motivoEntrega}
                  onChange={(e) => setMotivoEntrega(e.target.value)}
                  className="border-border"
                />
              </div>
            </div>

            <DialogFooter>
              <Button variant="outline" onClick={() => setModalEntregaOpen(false)}>
                Cancelar
              </Button>
              <Button
                onClick={handleConfirmarEntrega}
                disabled={procesandoAccion}
                className={tipoEntrega === 'entrega' ? 'bg-primary text-primary-foreground' : 'bg-amber-600 hover:bg-amber-700 text-white'}
              >
                {procesandoAccion ? 'Registrando...' : 'Confirmar Entrega'}
              </Button>
            </DialogFooter>
          </DialogContent>
        </Dialog>
      </DialogContent>
    </Dialog>
  );
}
