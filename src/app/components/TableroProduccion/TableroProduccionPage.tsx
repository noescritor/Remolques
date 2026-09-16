import React, { useState, useMemo } from 'react';
import { KanbanBoard } from './KanbanBoard';
import { LineaProducto, FaseProduccion, OrdenTrabajo } from '../../types';
import { Button } from '../ui/button';
import { Input } from '../ui/input';
import { Search, LayoutDashboard } from 'lucide-react';

interface TableroProduccionPageProps {
  lineasProducto: LineaProducto[];
  fasesProduccion: FaseProduccion[];
  ordenesTrabajo: OrdenTrabajo[];
  loading: boolean;
  onMoverOrden: (ordenId: string, faseId: string | null, estado: string) => void;
}

export function TableroProduccionPage({
  lineasProducto,
  fasesProduccion,
  ordenesTrabajo,
  loading,
  onMoverOrden
}: TableroProduccionPageProps) {
  const [activeTab, setActiveTab] = useState<string>(lineasProducto[0]?.id || '');
  const [searchTerm, setSearchTerm] = useState('');

  // Auto-select first tab if activeTab is not set and lineas are loaded
  if (!activeTab && lineasProducto.length > 0) {
    setActiveTab(lineasProducto[0].id);
  }

  const handleOrderClick = (orden: OrdenTrabajo) => {
    // In a future update, we can open a modal to change its 'estado_kanban' (pausado, incompleto, material faltante)
    alert(\`Orden: \${orden.cotizacion?.folio || 'Sin folio'} - \${orden.cliente?.nombre}\`);
  };

  const filteredOrdenes = useMemo(() => {
    let filtered = ordenesTrabajo;
    
    // Filtro por linea actual
    filtered = filtered.filter(o => {
      // By default, if the order doesn't have a linea, we don't show it here. 
      // We assume during order generation or migration, linea_producto_id is set.
      return o.linea_producto_id === activeTab;
    });

    // Búsqueda
    if (searchTerm) {
      const s = searchTerm.toLowerCase();
      filtered = filtered.filter(o => 
        o.cliente?.nombre?.toLowerCase().includes(s) ||
        o.cotizacion?.folio?.toLowerCase().includes(s)
      );
    }

    return filtered;
  }, [ordenesTrabajo, activeTab, searchTerm]);

  const activeFases = useMemo(() => {
    return fasesProduccion.filter(f => f.linea_producto_id === activeTab);
  }, [fasesProduccion, activeTab]);

  if (loading) {
    return (
      <div className="flex justify-center items-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary" />
      </div>
    );
  }

  if (lineasProducto.length === 0) {
    return (
      <div className="text-center py-20 bg-card/50 rounded-xl border border-border/50">
        <LayoutDashboard className="mx-auto h-12 w-12 text-muted-foreground mb-4" />
        <h3 className="text-lg font-medium text-foreground mb-2">Tablero no configurado</h3>
        <p className="text-muted-foreground">No se encontraron líneas de producto ni fases. Importa el catálogo inicial.</p>
      </div>
    );
  }

  return (
    <div className="flex flex-col h-[calc(100vh-100px)]">
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 mb-6">
        <div>
          <h1 className="text-3xl font-bold text-foreground">Tablero de Producción</h1>
          <p className="text-muted-foreground mt-1">Seguimiento tipo Kanban de unidades en planta</p>
        </div>
        <div className="relative">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
          <Input 
            placeholder="Buscar por cliente o folio..." 
            className="pl-9 w-full md:w-64"
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
          />
        </div>
      </div>

      {/* Tabs */}
      <div className="flex overflow-x-auto gap-2 mb-6 pb-2 border-b border-border/50">
        {lineasProducto.map(linea => (
          <Button
            key={linea.id}
            variant={activeTab === linea.id ? 'default' : 'ghost'}
            className={\`\${activeTab === linea.id ? 'bg-primary text-primary-foreground' : 'text-muted-foreground hover:text-foreground'}\`}
            onClick={() => setActiveTab(linea.id)}
          >
            {linea.nombre}
          </Button>
        ))}
      </div>

      {/* Kanban Board Container (Flexible to take remaining height) */}
      <div className="flex-1 overflow-hidden bg-card/30 rounded-xl border border-border/50 p-4">
        <KanbanBoard 
          fases={activeFases}
          ordenes={filteredOrdenes}
          onMoverOrden={onMoverOrden}
          onOrderClick={handleOrderClick}
        />
      </div>
    </div>
  );
}
