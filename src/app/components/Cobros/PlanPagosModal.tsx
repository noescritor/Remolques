import React, { useEffect, useMemo, useRef, useState } from 'react';
import { AlertTriangle, Calendar, Plus, Trash2 } from 'lucide-react';
import { Button } from '../ui/button';
import { Dialog, DialogContent, DialogFooter, DialogHeader, DialogTitle } from '../ui/dialog';
import { Input } from '../ui/input';
import { Label } from '../ui/label';
import {
  type PlanPagoDto,
  hoyMexicoIso,
  redondear2,
  traducirErrorCobros,
  validarPlanParcialidades,
} from '../../utils/cobros';
import { formatearMoneda } from '../../utils/calculations';

interface ParcialidadForm {
  numero: number;
  fecha_vencimiento: string;
  monto: string;
  nota: string;
}

interface PlanPagosModalProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  cotizacionId: string;
  totalLimite: number;
  planActual: PlanPagoDto | null;
  onGuardar: (payload: {
    planId?: string;
    cotizacion_id: string;
    nombre: string;
    notas?: string | null;
    parcialidades: Array<{ numero: number; fecha_vencimiento: string; monto: number; nota?: string | null }>;
  }) => Promise<void>;
}

export function PlanPagosModal({
  open,
  onOpenChange,
  cotizacionId,
  totalLimite,
  planActual,
  onGuardar,
}: PlanPagosModalProps) {
  const [nombre, setNombre] = useState('Plan de pagos');
  const [notas, setNotas] = useState('');
  const [filas, setFilas] = useState<ParcialidadForm[]>([]);
  const [guardando, setGuardando] = useState(false);
  const guardandoRef = useRef(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (open) {
      setError(null);
      setGuardando(false);
      if (planActual) {
        setNombre(planActual.nombre || 'Plan de pagos');
        setNotas(planActual.notas || '');
        setFilas(
          planActual.parcialidades.map((p, idx) => ({
            numero: p.numero || idx + 1,
            fecha_vencimiento: String(p.fecha_vencimiento).slice(0, 10),
            monto: String(p.monto),
            nota: p.nota || '',
          })),
        );
      } else {
        const hoy = hoyMexicoIso();
        setNombre('Plan de pagos');
        setNotas('');
        setFilas([
          { numero: 1, fecha_vencimiento: hoy, monto: totalLimite > 0 ? String(redondear2(totalLimite)) : '', nota: 'Anticipo' },
        ]);
      }
    }
  }, [open, planActual, totalLimite]);

  const suma = useMemo(
    () => redondear2(filas.reduce((acc, f) => acc + (Number(f.monto) || 0), 0)),
    [filas],
  );

  const agregarFila = () => {
    const nextNum = filas.length > 0 ? Math.max(...filas.map((f) => f.numero)) + 1 : 1;
    const hoy = hoyMexicoIso();
    setFilas((prev) => [...prev, { numero: nextNum, fecha_vencimiento: hoy, monto: '', nota: '' }]);
  };

  const quitarFila = (idx: number) => {
    setFilas((prev) =>
      prev.filter((_, i) => i !== idx).map((f, i) => ({ ...f, numero: i + 1 })),
    );
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (guardandoRef.current || guardando) return;
    setError(null);

    const parcialidades = filas.map((f, idx) => ({
      numero: idx + 1,
      fecha_vencimiento: f.fecha_vencimiento,
      monto: redondear2(Number(f.monto) || 0),
      nota: f.nota.trim() || null,
    }));

    const check = validarPlanParcialidades(parcialidades, totalLimite);
    if (!check.valido) {
      setError(check.error || 'Revisa las parcialidades del plan.');
      return;
    }

    guardandoRef.current = true;
    setGuardando(true);
    try {
      await onGuardar({
        planId: planActual?.id,
        cotizacion_id: cotizacionId,
        nombre: nombre.trim() || 'Plan de pagos',
        notas: notas.trim() || null,
        parcialidades,
      });
      onOpenChange(false);
    } catch (err) {
      setError(traducirErrorCobros(err));
    } finally {
      guardandoRef.current = false;
      setGuardando(false);
    }
  };

  return (
    <Dialog open={open} onOpenChange={(next) => !guardando && onOpenChange(next)}>
      <DialogContent className="bg-card text-foreground border-border max-w-2xl max-h-[90vh] flex flex-col p-0 overflow-hidden">
        <DialogHeader className="px-6 pt-5 pb-3 border-b border-border shrink-0">
          <DialogTitle className="flex items-center gap-2 text-lg">
            <Calendar className="w-5 h-5 text-primary" />
            {planActual ? 'Editar plan de pagos' : 'Crear plan de pagos'}
          </DialogTitle>
        </DialogHeader>

        <form onSubmit={handleSubmit} className="flex flex-col flex-1 min-h-0">
          <div className="px-6 py-4 space-y-4 overflow-y-auto flex-1">
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              <div className="space-y-1.5">
                <Label htmlFor="plan-nombre">Nombre del plan</Label>
                <Input
                  id="plan-nombre"
                  value={nombre}
                  onChange={(e) => setNombre(e.target.value)}
                  required
                />
              </div>
              <div className="space-y-1.5">
                <Label htmlFor="plan-notas">Notas (opcional)</Label>
                <Input
                  id="plan-notas"
                  value={notas}
                  onChange={(e) => setNotas(e.target.value)}
                  placeholder="Acuerdo comercial..."
                />
              </div>
            </div>

            <div className="space-y-2">
              <div className="flex items-center justify-between">
                <Label>Parcialidades</Label>
                <Button type="button" size="sm" variant="outline" onClick={agregarFila}>
                  <Plus className="w-3.5 h-3.5 mr-1" /> Agregar parcialidad
                </Button>
              </div>

              <div className="space-y-2">
                {filas.map((fila, idx) => (
                  <div
                    key={idx}
                    className="grid grid-cols-1 sm:grid-cols-12 gap-2 items-center rounded-lg border border-border bg-muted/30 p-2.5"
                  >
                    <div className="sm:col-span-1 text-xs font-mono font-bold text-muted-foreground">
                      #{idx + 1}
                    </div>
                    <div className="sm:col-span-3">
                      <Input
                        type="date"
                        aria-label={`Fecha parcialidad ${idx + 1}`}
                        value={fila.fecha_vencimiento}
                        onChange={(e) =>
                          setFilas((prev) =>
                            prev.map((item, i) =>
                              i === idx ? { ...item, fecha_vencimiento: e.target.value } : item,
                            ),
                          )
                        }
                        required
                      />
                    </div>
                    <div className="sm:col-span-3">
                      <Input
                        type="number"
                        step="0.01"
                        min="0.01"
                        aria-label={`Monto parcialidad ${idx + 1}`}
                        placeholder="0.00"
                        value={fila.monto}
                        onChange={(e) =>
                          setFilas((prev) =>
                            prev.map((item, i) => (i === idx ? { ...item, monto: e.target.value } : item)),
                          )
                        }
                        required
                      />
                    </div>
                    <div className="sm:col-span-4">
                      <Input
                        placeholder="Concepto / nota"
                        value={fila.nota}
                        onChange={(e) =>
                          setFilas((prev) =>
                            prev.map((item, i) => (i === idx ? { ...item, nota: e.target.value } : item)),
                          )
                        }
                      />
                    </div>
                    <div className="sm:col-span-1 flex justify-end">
                      <Button
                        type="button"
                        size="icon"
                        variant="ghost"
                        onClick={() => quitarFila(idx)}
                        disabled={filas.length <= 1}
                        aria-label={`Eliminar parcialidad ${idx + 1}`}
                      >
                        <Trash2 className="w-4 h-4 text-muted-foreground" />
                      </Button>
                    </div>
                  </div>
                ))}
              </div>

              <div className="flex justify-between text-xs pt-1">
                <span className="text-muted-foreground">Suma del plan vs total:</span>
                <span
                  className={`font-mono font-semibold ${
                    suma > totalLimite + 0.005 ? 'text-destructive' : 'text-foreground'
                  }`}
                >
                  {formatearMoneda(suma)} / {formatearMoneda(totalLimite)}
                </span>
              </div>
            </div>

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
              {guardando ? 'Guardando...' : 'Guardar plan'}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
