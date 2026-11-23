import React, { useEffect, useRef, useState } from 'react';
import { AlertTriangle, Ban } from 'lucide-react';
import { Button } from '../ui/button';
import { Dialog, DialogContent, DialogFooter, DialogHeader, DialogTitle } from '../ui/dialog';
import { Label } from '../ui/label';
import { Textarea } from '../ui/textarea';
import { type CobroDto, traducirErrorCobros } from '../../utils/cobros';
import { formatearMoneda } from '../../utils/calculations';

interface AnularCobroModalProps {
  cobro: CobroDto | null;
  onOpenChange: (open: boolean) => void;
  onConfirmar: (pagoId: string, motivo: string) => Promise<void>;
}

export function AnularCobroModal({ cobro, onOpenChange, onConfirmar }: AnularCobroModalProps) {
  const [motivo, setMotivo] = useState('');
  const [guardando, setGuardando] = useState(false);
  const guardandoRef = useRef(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (cobro) {
      setMotivo('');
      setError(null);
      setGuardando(false);
    }
  }, [cobro]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!cobro || guardandoRef.current || guardando) return;
    if (!motivo.trim()) {
      setError('El motivo de anulación es obligatorio.');
      return;
    }
    setError(null);
    guardandoRef.current = true;
    setGuardando(true);
    try {
      await onConfirmar(cobro.id, motivo.trim());
      onOpenChange(false);
    } catch (err) {
      setError(traducirErrorCobros(err));
    } finally {
      guardandoRef.current = false;
      setGuardando(false);
    }
  };

  return (
    <Dialog open={Boolean(cobro)} onOpenChange={(next) => !guardando && onOpenChange(next)}>
      <DialogContent className="bg-card text-foreground border-border max-w-md max-h-[90vh] flex flex-col p-0 overflow-hidden">
        <DialogHeader className="px-6 pt-5 pb-3 border-b border-border shrink-0">
          <DialogTitle className="flex items-center gap-2 text-lg text-destructive">
            <Ban className="w-5 h-5" />
            Anular cobro
          </DialogTitle>
        </DialogHeader>

        <form onSubmit={handleSubmit} className="flex flex-col flex-1 min-h-0">
          <div className="px-6 py-4 space-y-4 overflow-y-auto flex-1">
            {cobro && (
              <div className="rounded-lg border border-border bg-muted/40 p-3 text-sm space-y-1">
                <div className="flex justify-between">
                  <span className="text-muted-foreground">Tipo:</span>
                  <span className="font-medium">{cobro.tipo_pago}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-muted-foreground">Fecha:</span>
                  <span>{cobro.fecha}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-muted-foreground">Monto:</span>
                  <span className="font-mono font-bold">{formatearMoneda(cobro.monto)}</span>
                </div>
              </div>
            )}

            <div className="space-y-1.5">
              <Label htmlFor="anular-motivo">Motivo de anulación (obligatorio)</Label>
              <Textarea
                id="anular-motivo"
                value={motivo}
                onChange={(e) => setMotivo(e.target.value)}
                placeholder="Ej. Transferencia duplicada, cheque devuelto, error de captura..."
                rows={3}
                required
              />
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
            <Button type="submit" variant="destructive" disabled={guardando}>
              {guardando ? 'Anulando...' : 'Confirmar anulación'}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
