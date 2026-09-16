import React, { useState } from 'react';
import { FaseProduccion, OrdenTrabajo } from '../../types';
import { OrderCard } from './OrderCard';

interface KanbanBoardProps {
  fases: FaseProduccion[];
  ordenes: OrdenTrabajo[];
  onMoverOrden: (ordenId: string, faseId: string | null, estado: string) => void;
  onOrderClick: (orden: OrdenTrabajo) => void;
}

export function KanbanBoard({ fases, ordenes, onMoverOrden, onOrderClick }: KanbanBoardProps) {
  const [draggedOrderId, setDraggedOrderId] = useState<string | null>(null);
  const [dragOverColumn, setDragOverColumn] = useState<string | null>(null); // column id or 'pendientes'

  // Pre-process columns
  const columnas = [
    { id: 'pendientes', nombre: 'Por Iniciar', orden: -1 },
    ...fases.sort((a, b) => a.orden - b.orden)
  ];

  const getOrdenesPorFase = (faseId: string) => {
    if (faseId === 'pendientes') {
      return ordenes.filter(o => !o.fase_actual_id);
    }
    return ordenes.filter(o => o.fase_actual_id === faseId);
  };

  const handleDragStart = (e: React.DragEvent, id: string) => {
    setDraggedOrderId(id);
    e.dataTransfer.effectAllowed = 'move';
    // Small delay to prevent the dragged element from disappearing
    setTimeout(() => {
      if (e.target instanceof HTMLElement) {
        e.target.style.opacity = '0.5';
      }
    }, 0);
  };

  const handleDragEnd = (e: React.DragEvent) => {
    if (e.target instanceof HTMLElement) {
      e.target.style.opacity = '1';
    }
    setDraggedOrderId(null);
    setDragOverColumn(null);
  };

  const handleDragOver = (e: React.DragEvent, columnId: string) => {
    e.preventDefault();
    if (dragOverColumn !== columnId) {
      setDragOverColumn(columnId);
    }
  };

  const handleDrop = (e: React.DragEvent, columnId: string) => {
    e.preventDefault();
    setDragOverColumn(null);
    
    if (draggedOrderId) {
      const orden = ordenes.find(o => o.id === draggedOrderId);
      if (orden) {
        const currentFaseId = orden.fase_actual_id || 'pendientes';
        if (currentFaseId !== columnId) {
          const newFaseId = columnId === 'pendientes' ? null : columnId;
          const newEstado = columnId === 'pendientes' ? 'pendiente' : 'en_proceso'; // Auto en_proceso when moving to a phase
          onMoverOrden(draggedOrderId, newFaseId, newEstado);
        }
      }
    }
  };

  return (
    <div className="flex h-full w-full overflow-x-auto overflow-y-hidden gap-4 pb-4 px-1 snap-x">
      {columnas.map(col => {
        const columnOrders = getOrdenesPorFase(col.id);
        const isDragOver = dragOverColumn === col.id;
        
        return (
          <div 
            key={col.id} 
            className={\`flex flex-col flex-shrink-0 w-72 max-h-full bg-muted/20 rounded-xl border \${isDragOver ? 'border-primary/50 bg-primary/5' : 'border-border/50'} transition-colors snap-center\`}
            onDragOver={(e) => handleDragOver(e, col.id)}
            onDrop={(e) => handleDrop(e, col.id)}
            onDragLeave={() => setDragOverColumn(null)}
          >
            <div className="p-3 border-b border-border/50 flex items-center justify-between sticky top-0 bg-background/50 backdrop-blur rounded-t-xl z-10">
              <h3 className="font-semibold text-sm text-foreground flex items-center gap-2">
                {col.orden > 0 && <span className="text-xs bg-muted/50 text-muted-foreground w-5 h-5 flex items-center justify-center rounded-full">{col.orden}</span>}
                {col.nombre}
              </h3>
              <span className="text-xs font-medium text-muted-foreground bg-muted/30 px-1.5 py-0.5 rounded-full">
                {columnOrders.length}
              </span>
            </div>
            
            <div className="flex-1 overflow-y-auto p-2 min-h-[150px]">
              {columnOrders.map(orden => (
                <OrderCard 
                  key={orden.id} 
                  orden={orden} 
                  onDragStart={handleDragStart} 
                  onClick={onOrderClick}
                />
              ))}
              
              {columnOrders.length === 0 && (
                <div className="h-full flex items-center justify-center border-2 border-dashed border-border/30 rounded-lg text-xs text-muted-foreground/50 m-2 min-h-[100px]">
                  Arrastrar orden aquí
                </div>
              )}
            </div>
          </div>
        );
      })}
    </div>
  );
}
