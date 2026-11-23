import React, { useEffect, useMemo, useRef, useState } from 'react';
import { AlertTriangle, CheckCircle2, DollarSign, Layers } from 'lucide-react';
import { Button } from '../ui/button';
import { Dialog, DialogContent, DialogFooter, DialogHeader, DialogTitle } from '../ui/dialog';
import { Input } from '../ui/input';
import { Label } from '../ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../ui/select';
import { Textarea } from '../ui/textarea';
import {
  type EquipoResumenCobranzaDto,
  type TipoPagoCobro,
  redondear2,
  repartirEnPartesIguales,
  traducirErrorCobros,
  validarAplicaciones,
  validarDatosCobro,
} from '../../utils/cobros';
import { formatearMoneda } from '../../utils/calculations';

interface RegistrarCobroModalProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  cotizacionId: string;
  cotizacionFolio: string;
  saldoPendiente: number;
  equipos: EquipoResumenCobranzaDto[];
  ordenActualId?: string;
  onGuardar: (payload: {
    cotizacion_id: string;
    monto: number;
    fecha: string;
    tipo_pago: TipoPagoCobro;
    referencia?: string | null;
    notas?: string | null;
    descripcion_especie?: string | null;
    aplicaciones?: Array<{ orden_trabajo_id: string; monto: number }>;
    permitir_saldo_a_favor?: boolean;
  }) => Promise<void>;
}

const TIPOS_PAGO: TipoPagoCobro[] = [
  'Transferencia',
  'Efectivo',
  'Cheque',
  'Tarjeta',
  'Crédito 30 días',
  'Especie',
];

export function RegistrarCobroModal({
  open,
  onOpenChange,
  cotizacionId,
  cotizacionFolio,
  saldoPendiente,
  equipos,
  ordenActualId,
  onGuardar,
}: RegistrarCobroModalProps) {
  const hoyIso = new Date().toISOString().slice(0, 10);
  const [monto, setMonto] = useState<string>('');
  const [fecha, setFecha] = useState<string>(hoyIso);
  const [tipoPago, setTipoPago] = useState<TipoPagoCobro>('Transferencia');
  const [referencia, setReferencia] = useState<string>('');
  const [notas, setNotas] = useState<string>('');
  const [descripcionEspecie, setDescripcionEspecie] = useState<string>('');
  const [permitirSaldoAFavor, setPermitirSaldoAFavor] = useState<boolean>(false);
  const [asignarPorEquipo, setAsignarPorEquipo] = useState<boolean>(false);
  const [montosEquipo, setMontosEquipo] = useState<Record<string, string>>({});
  const [guardando, setGuardando] = useState<boolean>(false);
  const guardandoRef = useRef<boolean>(false);
  const [error, setError] = useState<string | null>(null);
  const [excedenteDetectado, setExcedenteDetectado] = useState<number>(0);

  useEffect(() => {
    if (open) {
      setMonto(saldoPendiente > 0 ? String(redondear2(saldoPendiente)) : '');
      setFecha(new Date().toISOString().slice(0, 10));
      setTipoPago('Transferencia');
      setReferencia('');
      setNotas('');
      setDescripcionEspecie('');
      setPermitirSaldoAFavor(false);
      setExcedenteDetectado(0);
      setError(null);
      setGuardando(false);
      if (equipos.length === 1 && ordenActualId) {
        setAsignarPorEquipo(true);
        setMontosEquipo({
          [ordenActualId]: saldoPendiente > 0 ? String(redondear2(saldoPendiente)) : '',
        });
      } else {
        setAsignarPorEquipo(false);
        setMontosEquipo({});
      }
    }
  }, [open, saldoPendiente, equipos.length, ordenActualId]);

  const montoNumerico = useMemo(() => redondear2(Number(monto) || 0), [monto]);

  const aplicacionesList = useMemo(() => {
    if (!asignarPorEquipo) return [];
    const list: Array<{ orden_trabajo_id: string; monto: number }> = [];
    for (const eq of equipos) {
      const val = redondear2(Number(montosEquipo[eq.orden_trabajo_id] || 0));
      if (val > 0) {
        list.push({ orden_trabajo_id: eq.orden_trabajo_id, monto: val });
      }
    }
    return list;
  }, [asignarPorEquipo, equipos, montosEquipo]);

  const sumaAplicada = useMemo(
    () => redondear2(aplicacionesList.reduce((acc, a) => acc + a.monto, 0)),
    [aplicacionesList],
  );

  const handleRepartirIguales = () => {
    if (equipos.length === 0 || montoNumerico <= 0) return;
    const reparto = repartirEnPartesIguales(
      montoNumerico,
      equipos.map((e) => e.orden_trabajo_id),
    );
    const next: Record<string, string> = {};
    for (const r of reparto) {
      next[r.orden_trabajo_id] = String(r.monto);
    }
    setAsignarPorEquipo(true);
    setMontosEquipo(next);
    setError(null);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (guardandoRef.current || guardando) return;
    setError(null);

    const checkCobro = validarDatosCobro({
      monto: montoNumerico,
      tipo_pago: tipoPago,
      descripcion_especie: descripcionEspecie,
      saldoPendiente,
      permitirSaldoAFavor,
    });

    if (!checkCobro.valido) {
      if (checkCobro.requiereConfirmacionSaldoAFavor) {
        setExcedenteDetectado(checkCobro.excedente || 0);
      }
      setError(checkCobro.error || 'Revisa los datos del cobro.');
      return;
    }

    if (asignarPorEquipo && aplicacionesList.length > 0) {
      const checkApps = validarAplicaciones(
        montoNumerico,
        aplicacionesList,
        new Set(equipos.map((eq) => eq.orden_trabajo_id)),
      );
      if (!checkApps.valido) {
        setError(checkApps.error || 'Aplicaciones por equipo inválidas.');
        return;
      }
    }

    guardandoRef.current = true;
    setGuardando(true);
    try {
      await onGuardar({
        cotizacion_id: cotizacionId,
        monto: montoNumerico,
        fecha,
        tipo_pago: tipoPago,
        referencia: referencia.trim() || null,
        notas: notas.trim() || null,
        descripcion_especie: tipoPago === 'Especie' ? descripcionEspecie.trim() : null,
        aplicaciones: asignarPorEquipo ? aplicacionesList : [],
        permitir_saldo_a_favor: permitirSaldoAFavor,
      });
      onOpenChange(false);
    } catch (err: any) {
      if (err?.requiere_confirmacion_saldo_a_favor || String(err?.message || '').includes('saldo_excedido')) {
        setExcedenteDetectado(redondear2(Math.max(0, montoNumerico - saldoPendiente)));
      }
      setError(traducirErrorCobros(err));
    } finally {
      guardandoRef.current = false;
      setGuardando(false);
    }
  };

  return (
    <Dialog open={open} onOpenChange={(next) => !guardando && onOpenChange(next)}>
      <DialogContent className="bg-card text-foreground border-border max-w-xl max-h-[90vh] flex flex-col p-0 overflow-hidden">
        <DialogHeader className="px-6 pt-5 pb-3 border-b border-border shrink-0">
          <DialogTitle className="flex items-center gap-2 text-lg">
            <DollarSign className="w-5 h-5 text-primary" />
            Registrar cobro · {cotizacionFolio}
          </DialogTitle>
        </DialogHeader>

        <form onSubmit={handleSubmit} className="flex flex-col flex-1 min-h-0">
          <div className="px-6 py-4 space-y-4 overflow-y-auto flex-1">
            <div className="rounded-lg border border-border bg-muted/40 p-3 flex flex-wrap items-center justify-between gap-2 text-sm">
              <span className="text-muted-foreground">Saldo pendiente actual:</span>
              <span className="font-mono font-bold text-foreground">
                {formatearMoneda(saldoPendiente)}
              </span>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              <div className="space-y-1.5">
                <Label htmlFor="cobro-monto">Monto</Label>
                <Input
                  id="cobro-monto"
                  type="number"
                  step="0.01"
                  min="0.01"
                  value={monto}
                  onChange={(e) => {
                    setMonto(e.target.value);
                    setExcedenteDetectado(0);
                    setPermitirSaldoAFavor(false);
                  }}
                  placeholder="0.00"
                  required
                />
              </div>

              <div className="space-y-1.5">
                <Label htmlFor="cobro-fecha">Fecha</Label>
                <Input
                  id="cobro-fecha"
                  type="date"
                  max={hoyIso}
                  value={fecha}
                  onChange={(e) => setFecha(e.target.value)}
                  required
                />
              </div>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              <div className="space-y-1.5">
                <Label htmlFor="cobro-tipo">Tipo de pago</Label>
                <Select value={tipoPago} onValueChange={(v) => setTipoPago(v as TipoPagoCobro)}>
                  <SelectTrigger id="cobro-tipo">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    {TIPOS_PAGO.map((tp) => (
                      <SelectItem key={tp} value={tp}>
                        {tp}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>

              <div className="space-y-1.5">
                <Label htmlFor="cobro-referencia">Referencia (opcional)</Label>
                <Input
                  id="cobro-referencia"
                  value={referencia}
                  onChange={(e) => setReferencia(e.target.value)}
                  placeholder="Folio SPEI, cheque, etc."
                />
              </div>
            </div>

            {tipoPago === 'Especie' && (
              <div className="space-y-1.5 rounded-lg border border-border bg-muted/30 p-3">
                <Label htmlFor="cobro-especie">Descripción del pago en especie (obligatoria)</Label>
                <Textarea
                  id="cobro-especie"
                  value={descripcionEspecie}
                  onChange={(e) => setDescripcionEspecie(e.target.value)}
                  placeholder="Ej. Remolque usado a cuenta, número de serie o condición..."
                  rows={2}
                  required
                />
              </div>
            )}

            <div className="space-y-1.5">
              <Label htmlFor="cobro-notas">Notas (opcional)</Label>
              <Input
                id="cobro-notas"
                value={notas}
                onChange={(e) => setNotas(e.target.value)}
                placeholder="Observaciones internas del cobro"
              />
            </div>

            {equipos.length > 0 && (
              <div className="rounded-lg border border-border p-3 space-y-3">
                <div className="flex flex-wrap items-center justify-between gap-2">
                  <label className="flex items-center gap-2 text-sm font-medium cursor-pointer">
                    <input
                      type="checkbox"
                      checked={asignarPorEquipo}
                      onChange={(e) => setAsignarPorEquipo(e.target.checked)}
                      className="rounded border-border"
                    />
                    <Layers className="w-4 h-4 text-primary" />
                    <span>Aplicar a equipos ({equipos.length})</span>
                  </label>
                  {equipos.length > 1 && (
                    <Button
                      type="button"
                      size="sm"
                      variant="outline"
                      onClick={handleRepartirIguales}
                      disabled={montoNumerico <= 0}
                    >
                      Repartir en partes iguales
                    </Button>
                  )}
                </div>

                {asignarPorEquipo && (
                  <div className="space-y-2">
                    {equipos.map((eq) => (
                      <div
                        key={eq.orden_trabajo_id}
                        className="flex flex-wrap items-center justify-between gap-2 text-sm bg-muted/30 rounded-md px-3 py-2"
                      >
                        <div className="min-w-0">
                          <div className="font-medium truncate">
                            {eq.nomenclatura_id || eq.modelo || eq.orden_trabajo_id.slice(0, 8)}
                          </div>
                          <div className="text-xs text-muted-foreground">
                            Cobrado: {formatearMoneda(eq.cobrado_asignado)}
                            {eq.valor_pactado != null ? ` · Valor: ${formatearMoneda(eq.valor_pactado)}` : ''}
                          </div>
                        </div>
                        <Input
                          type="number"
                          step="0.01"
                          min="0"
                          aria-label={`Monto para ${eq.nomenclatura_id || eq.orden_trabajo_id}`}
                          className="w-36 font-mono text-right"
                          value={montosEquipo[eq.orden_trabajo_id] ?? ''}
                          onChange={(e) =>
                            setMontosEquipo((prev) => ({
                              ...prev,
                              [eq.orden_trabajo_id]: e.target.value,
                            }))
                          }
                          placeholder="0.00"
                        />
                      </div>
                    ))}
                    <div className="flex justify-between text-xs text-muted-foreground pt-1">
                      <span>Suma aplicada a equipos:</span>
                      <span
                        className={`font-mono font-semibold ${
                          sumaAplicada > montoNumerico + 0.005 ? 'text-destructive' : 'text-foreground'
                        }`}
                      >
                        {formatearMoneda(sumaAplicada)} / {formatearMoneda(montoNumerico)}
                      </span>
                    </div>
                  </div>
                )}
              </div>
            )}

            {(excedenteDetectado > 0 || permitirSaldoAFavor) && (
              <div className="rounded-lg border border-amber-500/40 bg-amber-500/10 p-3 space-y-2 text-sm">
                <div className="flex items-start gap-2 font-medium text-foreground">
                  <AlertTriangle className="w-4 h-4 text-amber-500 shrink-0 mt-0.5" />
                  <span>
                    Este cobro supera el saldo pendiente por {formatearMoneda(excedenteDetectado || Math.max(0, montoNumerico - saldoPendiente))}.
                  </span>
                </div>
                <label className="flex items-center gap-2 cursor-pointer text-xs text-muted-foreground">
                  <input
                    type="checkbox"
                    checked={permitirSaldoAFavor}
                    onChange={(e) => setPermitirSaldoAFavor(e.target.checked)}
                    className="rounded border-border"
                  />
                  <span>Confirmo registrar el excedente como saldo a favor del cliente</span>
                </label>
              </div>
            )}

            {error && (
              <div className="rounded-lg border border-destructive/40 bg-destructive/10 p-3 text-sm text-destructive flex items-start gap-2">
                <AlertTriangle className="w-4 h-4 shrink-0 mt-0.5" />
                <span>{error}</span>
              </div>
            )}
          </div>

          <DialogFooter className="px-6 py-3 border-t border-border bg-muted/20 shrink-0 gap-2">
            <Button type="button" variant="outline" onClick={() => onOpenChange(false)} disabled={guardando}>
              Cancelar
            </Button>
            <Button type="submit" disabled={guardando}>
              <CheckCircle2 className="w-4 h-4 mr-1.5" />
              {guardando ? 'Registrando...' : 'Confirmar cobro'}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
