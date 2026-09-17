import React from 'react';
import { Card, CardContent } from '../ui/card';
import { Badge } from '../ui/badge';
import { Clock, AlertTriangle, FileText } from 'lucide-react';
import { OrdenTrabajo } from '../../types';
import { getClientName } from '../../utils/calculations';

interface OrderCardProps {
  orden: OrdenTrabajo;
  onDragStart: (e: React.DragEvent, id: string) => void;
  onClick: (orden: OrdenTrabajo) => void;
}

export function OrderCard({ orden, onDragStart, onClick }: OrderCardProps) {
  const getStatusColor = (estado: string) => {
    switch (estado) {
      case 'en_proceso': return 'bg-accent-green/20 text-accent-green border-accent-green/30';
      case 'pausada': return 'bg-destructive/20 text-destructive border-destructive/30';
      case 'incompleta': return 'bg-accent-yellow/20 text-accent-yellow border-accent-yellow/30';
      case 'en_espera': return 'bg-muted/50 text-muted-foreground border-border/50';
      case 'completada': return 'bg-accent-blue/20 text-accent-blue border-accent-blue/30';
      default: return 'bg-muted/20 text-muted-foreground border-border/50';
    }
  };

  const getStatusText = (estado: string) => {
    switch (estado) {
      case 'en_proceso': return 'En Proceso';
      case 'pausada': return 'Pausada';
      case 'incompleta': return 'Incompleta';
      case 'en_espera': return 'En Espera';
      case 'completada': return 'Completada';
      default: return 'Pendiente';
    }
  };

  return (
    <Card 
      className="mb-3 cursor-grab active:cursor-grabbing hover:border-primary/50 transition-colors shadow-sm bg-card/80 backdrop-blur-sm border-border/50"
      draggable
      onDragStart={(e) => onDragStart(e, orden.id)}
      onClick={() => onClick(orden)}
    >
      <CardContent className="p-3">
        <div className="flex justify-between items-start mb-2">
          <div className="font-mono text-xs font-bold bg-muted/50 px-1.5 py-0.5 rounded text-foreground">{orden.cotizacion?.folio || 'Sin Folio'}</div>
          <Badge variant="outline" className={`text-[10px] px-1.5 py-0 border ${getStatusColor(orden.estado_kanban || 'pendiente')}`}>
            {getStatusText(orden.estado_kanban || 'pendiente')}
          </Badge>
        </div>
        
        <div className="font-medium text-sm text-foreground mb-2 line-clamp-2">
          {orden.cliente?.nombre || 'Cliente Desconocido'}
        </div>

        {orden.material_faltante && (
          <div className="mt-2 bg-destructive/10 rounded p-1.5 border border-destructive/20 flex items-start gap-1.5">
            <AlertTriangle className="h-3 w-3 text-destructive shrink-0 mt-0.5" />
            <p className="text-[10px] text-destructive leading-tight">
              {orden.material_faltante}
            </p>
          </div>
        )}
      </CardContent>
    </Card>
  );
}
