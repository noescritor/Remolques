import React, { useMemo, useState } from 'react';
import {
  AlertTriangle,
  Ban,
  Calendar,
  CheckCircle2,
  Clock,
  CreditCard,
  DollarSign,
  Edit3,
  Info,
  Package,
  Plus,
  RefreshCw,
  Trash2,
} from 'lucide-react';
import { Badge } from '../ui/badge';
import { Button } from '../ui/button';
import { Input } from '../ui/input';
import {
  type CobranzaEquipoDto,
  type CobroDto,
  type EstatusParcialidad,
  traducirErrorCobros,
} from '../../utils/cobros';
import { formatearMoneda } from '../../utils/calculations';
import { expedienteApi } from '../Expediente/expedienteApi';
import { RegistrarCobroModal } from './RegistrarCobroModal';
import { PlanPagosModal } from './PlanPagosModal';
import { AnularCobroModal } from './AnularCobroModal';

interface CobranzaTabPanelProps {
  estado: 'cargando' | 'error' | 'ok';
  error: string | null;
  datos: CobranzaEquipoDto | null;
  onRecargar: () => Promise<void>;
}

const ESTATUS_BADGE: Record<EstatusParcialidad, { label: string; variant: 'default' | 'secondary' | 'destructive' | 'outline' }> = {
  pagada: { label: 'Pagada', variant: 'default' },
  parcial: { label: 'Parcial', variant: 'secondary' },
  vencida: { label: 'Vencida', variant: 'destructive' },
  pendiente: { label: 'Pendiente', variant: 'outline' },
};

export function CobranzaTabPanel({ estado, error, datos, onRecargar }: CobranzaTabPanelProps) {
  const [modalCobroOpen, setModalCobroOpen] = useState(false);
  const [modalPlanOpen, setModalPlanOpen] = useState(false);
  const [cobroAAnular, setCobroAAnular] = useState<CobroDto | null>(null);
  const [editandoValorOrdenId, setEditandoValorOrdenId] = useState<string | null>(null);
  const [valorInput, setValorInput] = useState('');
  const [accionError, setAccionError] = useState<string | null>(null);
  const [guardandoAccion, setGuardandoAccion] = useState(false);

  const cobCot = datos?.cobranza_cotizacion ?? null;
  const esCobrable = useMemo(() => {
    const est = cobCot?.cotizacion.estado;
    return est === 'Aprobada' || est === 'Pagada';
  }, [cobCot?.cotizacion.estado]);

  if (estado === 'cargando') {
    return (
      <div className="rounded-xl border border-border bg-card p-6 text-center text-sm text-muted-foreground">
        Cargando cobranza del equipo...
      </div>
    );
  }

  if (estado === 'error') {
    return (
      <div className="rounded-xl border border-destructive/40 bg-destructive/10 p-5 flex flex-col sm:flex-row sm:items-center justify-between gap-3">
        <div className="flex items-start gap-2.5 text-sm text-destructive">
          <AlertTriangle className="w-5 h-5 shrink-0 mt-0.5" />
          <div>
            <div className="font-semibold">No se pudo cargar la cobranza</div>
            <div className="text-xs opacity-90">{error || 'Error de red o servidor'}</div>
          </div>
        </div>
        <Button variant="outline" size="sm" onClick={() => onRecargar()}>
          <RefreshCw className="w-4 h-4 mr-1.5" /> Reintentar
        </Button>
      </div>
    );
  }

  if (!datos || datos.orden.es_manual || !cobCot) {
    return (
      <div className="rounded-xl border border-dashed border-border bg-card p-8 text-center space-y-2">
        <CreditCard className="w-8 h-8 text-muted-foreground mx-auto" />
        <div className="font-semibold text-foreground">Orden manual sin cotización vinculada</div>
        <p className="text-sm text-muted-foreground max-w-md mx-auto">
          Los cobros y planes de pago se administran sobre cotizaciones aprobadas. Esta orden de trabajo fue creada manualmente sin cotización asociada.
        </p>
      </div>
    );
  }

  const equiposMap = new Map(
    cobCot.equipos.map((e) => [e.orden_trabajo_id, e.nomenclatura_id || e.modelo || e.orden_trabajo_id.slice(0, 8)]),
  );

  const guardarValor = async (ordenId: string) => {
    if (guardandoAccion) return;
    setAccionError(null);
    setGuardandoAccion(true);
    try {
      const parsed = valorInput.trim() === '' ? null : Number(valorInput);
      await expedienteApi.guardarValorEquipo(ordenId, parsed);
      setEditandoValorOrdenId(null);
      await onRecargar();
    } catch (err) {
      setAccionError(traducirErrorCobros(err));
    } finally {
      setGuardandoAccion(false);
    }
  };

  const eliminarPlan = async () => {
    if (!cobCot.plan_activo || guardandoAccion) return;
    setAccionError(null);
    setGuardandoAccion(true);
    try {
      await expedienteApi.eliminarPlanPago(cobCot.plan_activo.id);
      await onRecargar();
    } catch (err) {
      setAccionError(traducirErrorCobros(err));
    } finally {
      setGuardandoAccion(false);
    }
  };

  return (
    <div className="space-y-4">
      {cobCot.equipos.length > 1 && (
        <div className="rounded-lg border border-border bg-muted/40 p-3 text-xs text-muted-foreground flex items-center gap-2">
          <Info className="w-4 h-4 text-primary shrink-0" />
          <span>
            Esta cotización ({cobCot.cotizacion.folio}) cubre {cobCot.equipos.length} equipos. Puedes asignar cada cobro a equipos específicos o dejarlo a nivel cotización.
          </span>
        </div>
      )}

      {accionError && (
        <div className="rounded-lg border border-destructive/40 bg-destructive/10 p-3 text-sm text-destructive flex items-center justify-between gap-2">
          <span className="flex items-center gap-2">
            <AlertTriangle className="w-4 h-4 shrink-0" />
            {accionError}
          </span>
          <Button variant="ghost" size="sm" onClick={() => setAccionError(null)}>
            Cerrar
          </Button>
        </div>
      )}

      {/* Tarjetas resumen */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3">
        <div className="rounded-xl border border-border bg-card p-4">
          <div className="text-xs text-muted-foreground">Total cotización ({cobCot.cotizacion.folio})</div>
          <div className="text-xl font-mono font-bold text-foreground mt-1">
            {formatearMoneda(cobCot.resumen.total)}
          </div>
          <Badge variant="outline" className="mt-2 text-xs">
            {cobCot.cotizacion.estado}
          </Badge>
        </div>

        <div className="rounded-xl border border-border bg-card p-4">
          <div className="text-xs text-muted-foreground">Cobrado vigente</div>
          <div className="text-xl font-mono font-bold text-foreground mt-1">
            {formatearMoneda(cobCot.resumen.cobrado_vigente)}
          </div>
          {cobCot.resumen.sin_asignar_equipo > 0 && (
            <div className="text-xs text-muted-foreground mt-1">
              Sin asignar a equipo: {formatearMoneda(cobCot.resumen.sin_asignar_equipo)}
            </div>
          )}
        </div>

        <div className="rounded-xl border border-border bg-card p-4">
          <div className="text-xs text-muted-foreground">Saldo pendiente</div>
          <div className="text-xl font-mono font-bold text-foreground mt-1">
            {formatearMoneda(cobCot.resumen.saldo_pendiente)}
          </div>
          {cobCot.resumen.saldo_a_favor > 0 && (
            <div className="text-xs text-primary font-medium mt-1">
              Saldo a favor: {formatearMoneda(cobCot.resumen.saldo_a_favor)}
            </div>
          )}
        </div>

        <div className="rounded-xl border border-border bg-card p-4 flex flex-col justify-between gap-2">
          <div className="text-xs text-muted-foreground">Cobranza de este equipo</div>
          <div>
            <div className="text-base font-mono font-bold text-foreground">
              {formatearMoneda(datos.cobrado_asignado)}
            </div>
            <div className="text-xs text-muted-foreground">
              {datos.valor_pactado != null
                ? `Valor pactado: ${formatearMoneda(datos.valor_pactado)} · Saldo: ${formatearMoneda(datos.saldo_equipo ?? 0)}`
                : 'Sin valor pactado por equipo'}
            </div>
          </div>
        </div>
      </div>

      {/* Acciones principales */}
      <div className="flex flex-wrap items-center justify-between gap-2">
        <div className="flex flex-wrap gap-2">
          <Button
            onClick={() => setModalCobroOpen(true)}
            disabled={!esCobrable}
            title={!esCobrable ? 'Solo disponible en cotizaciones aprobadas o pagadas' : undefined}
          >
            <DollarSign className="w-4 h-4 mr-1.5" />
            Registrar cobro
          </Button>
          <Button variant="outline" onClick={() => setModalPlanOpen(true)}>
            <Calendar className="w-4 h-4 mr-1.5" />
            {cobCot.plan_activo ? 'Editar plan de pagos' : 'Crear plan de pagos'}
          </Button>
        </div>
        <Button variant="ghost" size="sm" onClick={() => onRecargar()}>
          <RefreshCw className="w-3.5 h-3.5 mr-1.5" /> Actualizar
        </Button>
      </div>

      {/* Equipos de la cotización */}
      {cobCot.equipos.length > 0 && (
        <div className="rounded-xl border border-border bg-card p-4 space-y-3">
          <div className="flex items-center justify-between">
            <h3 className="text-sm font-bold flex items-center gap-2">
              <Package className="w-4 h-4 text-primary" />
              Equipos en la cotización ({cobCot.equipos.length})
            </h3>
          </div>
          <div className="divide-y divide-border/60">
            {cobCot.equipos.map((eq) => {
              const esActual = eq.orden_trabajo_id === datos.orden.id;
              const editando = editandoValorOrdenId === eq.orden_trabajo_id;
              return (
                <div key={eq.orden_trabajo_id} className="py-2.5 flex flex-wrap items-center justify-between gap-3 text-sm">
                  <div className="min-w-0">
                    <div className="font-medium flex items-center gap-2">
                      <span>{eq.nomenclatura_id || eq.modelo || eq.orden_trabajo_id.slice(0, 8)}</span>
                      {esActual && <Badge variant="secondary">Este equipo</Badge>}
                    </div>
                    <div className="text-xs text-muted-foreground">
                      Cobrado asignado: <span className="font-mono font-semibold text-foreground">{formatearMoneda(eq.cobrado_asignado)}</span>
                      {eq.valor_pactado != null && (
                        <> · Valor pactado: <span className="font-mono">{formatearMoneda(eq.valor_pactado)}</span> · Saldo: <span className="font-mono">{formatearMoneda(eq.saldo_equipo ?? 0)}</span></>
                      )}
                    </div>
                  </div>
                  <div className="flex items-center gap-2">
                    {editando ? (
                      <>
                        <Input
                          type="number"
                          step="0.01"
                          min="0"
                          className="w-32 h-8 font-mono text-right"
                          value={valorInput}
                          onChange={(e) => setValorInput(e.target.value)}
                          placeholder="Valor pactado"
                        />
                        <Button size="sm" onClick={() => guardarValor(eq.orden_trabajo_id)} disabled={guardandoAccion}>
                          Guardar
                        </Button>
                        <Button size="sm" variant="ghost" onClick={() => setEditandoValorOrdenId(null)}>
                          Cancelar
                        </Button>
                      </>
                    ) : (
                      <Button
                        size="sm"
                        variant="outline"
                        onClick={() => {
                          setEditandoValorOrdenId(eq.orden_trabajo_id);
                          setValorInput(eq.valor_pactado != null ? String(eq.valor_pactado) : '');
                        }}
                      >
                        <Edit3 className="w-3.5 h-3.5 mr-1" />
                        {eq.valor_pactado != null ? 'Editar valor' : 'Definir valor'}
                      </Button>
                    )}
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      )}

      {/* Plan de pagos */}
      <div className="rounded-xl border border-border bg-card p-4 space-y-3">
        <div className="flex flex-wrap items-center justify-between gap-2">
          <h3 className="text-sm font-bold flex items-center gap-2">
            <Calendar className="w-4 h-4 text-primary" />
            {cobCot.plan_activo ? cobCot.plan_activo.nombre : 'Plan de pagos'}
          </h3>
          {cobCot.plan_activo && (
            <div className="flex items-center gap-2">
              <Button size="sm" variant="outline" onClick={() => setModalPlanOpen(true)}>
                <Edit3 className="w-3.5 h-3.5 mr-1" /> Editar
              </Button>
              <Button size="sm" variant="ghost" onClick={eliminarPlan} disabled={guardandoAccion}>
                <Trash2 className="w-3.5 h-3.5 text-destructive" />
              </Button>
            </div>
          )}
        </div>

        {!cobCot.plan_activo ? (
          <div className="text-sm text-muted-foreground py-3 flex flex-wrap items-center justify-between gap-2">
            <span>No hay un plan de pagos configurado para esta cotización.</span>
            <Button size="sm" variant="outline" onClick={() => setModalPlanOpen(true)}>
              <Plus className="w-3.5 h-3.5 mr-1" /> Crear plan
            </Button>
          </div>
        ) : (
          <div className="divide-y divide-border/60">
            {cobCot.plan_activo.parcialidades.map((p) => {
              const estInfo = ESTATUS_BADGE[p.estatus];
              return (
                <div key={p.id || p.numero} className="py-2.5 flex flex-wrap items-center justify-between gap-2 text-sm">
                  <div className="space-y-0.5">
                    <div className="flex items-center gap-2 font-medium">
                      <span className="font-mono text-xs text-muted-foreground">#{p.numero}</span>
                      <span>Vence: {p.fecha_vencimiento}</span>
                      <Badge variant={estInfo.variant}>{estInfo.label}</Badge>
                    </div>
                    {p.nota && <div className="text-xs text-muted-foreground">{p.nota}</div>}
                  </div>
                  <div className="text-right font-mono">
                    <div className="font-bold text-foreground">{formatearMoneda(p.monto)}</div>
                    <div className="text-xs text-muted-foreground">
                      Cubierto: {formatearMoneda(p.monto_cubierto)} · Pend: {formatearMoneda(p.monto_pendiente)}
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>

      {/* Historial de cobros */}
      <div className="rounded-xl border border-border bg-card p-4 space-y-3">
        <div className="flex items-center justify-between">
          <h3 className="text-sm font-bold flex items-center gap-2">
            <CreditCard className="w-4 h-4 text-primary" />
            Historial de cobros ({cobCot.cobros.length})
          </h3>
        </div>

        {cobCot.cobros.length === 0 ? (
          <div className="text-sm text-muted-foreground py-4 text-center">
            Aún no se han registrado cobros para esta cotización.
          </div>
        ) : (
          <div className="divide-y divide-border/60">
            {cobCot.cobros.map((c) => {
              const anulado = c.estado === 'anulado';
              return (
                <div
                  key={c.id}
                  className={`py-3 flex flex-wrap items-start justify-between gap-3 text-sm ${
                    anulado ? 'opacity-65' : ''
                  }`}
                >
                  <div className="space-y-1 min-w-0">
                    <div className="flex flex-wrap items-center gap-2 font-medium">
                      {anulado ? (
                        <Clock className="w-3.5 h-3.5 text-destructive shrink-0" />
                      ) : (
                        <CheckCircle2 className="w-3.5 h-3.5 text-primary shrink-0" />
                      )}
                      <span className={anulado ? 'line-through' : ''}>{c.tipo_pago}</span>
                      {c.referencia && (
                        <span className="text-xs text-muted-foreground">· Ref: {c.referencia}</span>
                      )}
                      {anulado && <Badge variant="destructive">Anulado</Badge>}
                      {c.tipo_pago === 'Especie' && <Badge variant="secondary">En especie</Badge>}
                    </div>

                    <div className="text-xs text-muted-foreground">
                      Fecha: {c.fecha}
                      {c.notas ? ` · ${c.notas}` : ''}
                    </div>

                    {c.descripcion_especie && (
                      <div className="text-xs text-foreground bg-muted/40 rounded px-2 py-1 inline-block">
                        Especie: {c.descripcion_especie}
                      </div>
                    )}

                    {c.aplicaciones && c.aplicaciones.length > 0 && (
                      <div className="flex flex-wrap gap-1.5 pt-1">
                        {c.aplicaciones.map((app) => (
                          <Badge key={app.orden_trabajo_id} variant="outline" className="text-xs font-mono">
                            {equiposMap.get(app.orden_trabajo_id) || app.orden_trabajo_id.slice(0, 8)}:{' '}
                            {formatearMoneda(app.monto)}
                          </Badge>
                        ))}
                      </div>
                    )}

                    {anulado && c.motivo_anulacion && (
                      <div className="text-xs text-destructive">
                        Motivo de anulación: {c.motivo_anulacion}
                        {c.anulado_at ? ` (${c.anulado_at.slice(0, 10)})` : ''}
                      </div>
                    )}
                  </div>

                  <div className="flex items-center gap-3 shrink-0">
                    <div className={`font-mono font-bold text-base ${anulado ? 'line-through text-muted-foreground' : 'text-foreground'}`}>
                      {formatearMoneda(c.monto)}
                    </div>
                    {!anulado && (
                      <Button
                        size="sm"
                        variant="ghost"
                        onClick={() => setCobroAAnular(c)}
                        title="Anular cobro"
                      >
                        <Ban className="w-4 h-4 text-destructive" />
                      </Button>
                    )}
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>

      <RegistrarCobroModal
        open={modalCobroOpen}
        onOpenChange={setModalCobroOpen}
        cotizacionId={cobCot.cotizacion.id}
        cotizacionFolio={cobCot.cotizacion.folio}
        saldoPendiente={cobCot.resumen.saldo_pendiente}
        equipos={cobCot.equipos}
        ordenActualId={datos.orden.id}
        onGuardar={async (payload) => {
          await expedienteApi.registrarCobro(payload);
          await onRecargar();
        }}
      />

      <PlanPagosModal
        open={modalPlanOpen}
        onOpenChange={setModalPlanOpen}
        cotizacionId={cobCot.cotizacion.id}
        totalLimite={cobCot.resumen.total}
        planActual={cobCot.plan_activo}
        onGuardar={async (payload) => {
          if (payload.planId) {
            await expedienteApi.actualizarPlanPago(payload.planId, {
              nombre: payload.nombre,
              notas: payload.notas,
              parcialidades: payload.parcialidades,
            });
          } else {
            await expedienteApi.crearPlanPago({
              cotizacion_id: payload.cotizacion_id,
              nombre: payload.nombre,
              notas: payload.notas,
              parcialidades: payload.parcialidades,
            });
          }
          await onRecargar();
        }}
      />

      <AnularCobroModal
        cobro={cobroAAnular}
        onOpenChange={(open) => {
          if (!open) setCobroAAnular(null);
        }}
        onConfirmar={async (pagoId, motivo) => {
          await expedienteApi.anularCobro(pagoId, motivo);
          await onRecargar();
        }}
      />
    </div>
  );
}
