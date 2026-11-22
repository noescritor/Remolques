import React from 'react';
import { OrdenTrabajo } from '../../types';
import { Dialog, DialogContent } from '../ui/dialog';
import { ChecklistDespiecePanel } from './ChecklistDespiecePanel';

interface ChecklistDespieceModalProps {
  orden: OrdenTrabajo | null;
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onActualizado?: () => void;
}

export function ChecklistDespieceModal({
  orden,
  open,
  onOpenChange,
  onActualizado,
}: ChecklistDespieceModalProps) {
  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-5xl max-h-[92vh] overflow-y-auto bg-background text-foreground border-border p-6">
        <ChecklistDespiecePanel
          orden={orden}
          activo={open}
          modoEmbebido={false}
          onActualizado={onActualizado}
          onCerrarModal={() => onOpenChange(false)}
        />
      </DialogContent>
    </Dialog>
  );
}
