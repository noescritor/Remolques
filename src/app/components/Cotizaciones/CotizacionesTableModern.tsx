import { useState } from 'react';
import { Button } from '../ui/button';
import { Checkbox } from '../ui/checkbox';
import { Badge } from '../ui/badge';
import { MoreVertical, Edit2, Copy, Trash2, FileText } from 'lucide-react';
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from '../ui/dropdown-menu';
import { formatearMoneda, formatearFecha } from '../../utils/calculations';
import { Cotizacion, EstadoCotizacion } from '../../types';
import svgPaths from '../../imports/svg-uyqp5z14td';
import { img1, img2 } from '../../imports/svg-m8ax7';

interface CotizacionesTableModernProps {
  cotizaciones: Cotizacion[];
  onVerCotizacion: (id: string) => void;
  onEditarCotizacion?: (id: string) => void;
  onDuplicarCotizacion: (id: string) => void;
  onEliminarCotizacion: (id: string) => void;

}

type SortDirection = 'asc' | 'desc' | null;
type SortField = 'folio' | 'fechaCreacion' | 'cliente' | 'descripcion' | 'total' | 'estado';

// Componente de celda moderna basada en el diseño de Figma
function ModernCell({ 
  children, 
  type = 'row',
  className = '',
  onClick
}: { 
  children: React.ReactNode;
  type?: 'header' | 'row';
  className?: string;
  onClick?: () => void;
}) {
  return (
    <div 
      className={`
        flex items-center justify-center overflow-hidden h-full
        ${onClick ? 'cursor-pointer hover:bg-white/[0.04]' : ''}
        ${className}
      `}
      onClick={onClick}
    >
      <div className="box-border flex gap-2 items-center justify-center px-3 py-0 h-full w-full">
        {children}
      </div>
    </div>
  );
}

// Componente de checkbox moderno
function ModernCheckbox({ checked, onCheckedChange }: { checked: boolean; onCheckedChange: (checked: boolean) => void }) {
  return (
    <div className="bg-white/5 rounded-sm border border-white/20 w-4 h-4 flex items-center justify-center">
      <Checkbox
        checked={checked}
        onCheckedChange={onCheckedChange}
        className="border-0 bg-transparent w-3 h-3"
      />
    </div>
  );
}

// Componente de badge/label moderno para estados
function ModernBadge({ estado }: { estado: EstadoCotizacion }) {
  const getBadgeColor = (estado: EstadoCotizacion) => {
    switch (estado.toLowerCase()) {
      case 'borrador':
        return 'bg-white/10 text-white/70 border-white/20';
      case 'enviada':
        return 'bg-accent-blue/20 text-accent-blue border-accent-blue/30';
      case 'aprobada':
        return 'bg-accent-green/20 text-accent-green border-accent-green/30';
      case 'rechazada':
      case 'cancelada':
        return 'bg-accent-red/20 text-accent-red border-accent-red/30';
      case 'vencida':
        return 'bg-orange-400/20 text-orange-400 border-orange-400/30';
      case 'pagada':
        return 'bg-emerald-400/20 text-emerald-400 border-emerald-400/30';
      default:
        return 'bg-white/10 text-white/70 border-white/20';
    }
  };

  return (
    <div className={`
      px-3 py-1 rounded-sm border text-xs font-semibold uppercase tracking-wide
      ${getBadgeColor(estado)}
    `}>
      {estado.charAt(0).toUpperCase() + estado.slice(1)}
    </div>
  );
}

// Componente de header con ordenamiento
function SortableHeader({ 
  children, 
  field, 
  currentSort, 
  onSort 
}: { 
  children: React.ReactNode;
  field: SortField;
  currentSort: { field: SortField; direction: SortDirection };
  onSort: (field: SortField) => void;
}) {
  const isActive = currentSort.field === field;
  
  return (
    <div 
      className="flex items-center gap-2 cursor-pointer hover:bg-white/[0.04] h-full w-full px-3"
      onClick={() => onSort(field)}
    >
      <div className="relative shrink-0 w-4 h-4">
        {isActive && (
          <>
            <div className="absolute left-[5px] w-2.5 h-2.5 top-[6px]">
              <div className="absolute inset-[12.5%_29.44%_12.5%_30%]">
                <img 
                  alt="" 
                  className={`block max-w-none w-full h-full ${
                    currentSort.direction === 'desc' ? 'opacity-100' : 'opacity-30'
                  }`} 
                  src={img1} 
                />
              </div>
            </div>
            <div className="absolute left-px w-2.5 h-2.5 top-0">
              <div className="absolute inset-[12.5%_29.38%_12.5%_30%]">
                <img 
                  alt="" 
                  className={`block max-w-none w-full h-full ${
                    currentSort.direction === 'asc' ? 'opacity-100' : 'opacity-30'
                  }`}
                  src={img2} 
                />
              </div>
            </div>
          </>
        )}
      </div>
      <div className="flex-grow">
        <div className="font-semibold text-white/60 text-base leading-[1.5]">
          {children}
        </div>
      </div>
    </div>
  );
}

// Componente principal de tabla moderna
export function CotizacionesTableModern({
  cotizaciones,
  onVerCotizacion,
  onEditarCotizacion,
  onDuplicarCotizacion,
  onEliminarCotizacion
}: CotizacionesTableModernProps) {
  const [selectedItems, setSelectedItems] = useState<Set<string>>(new Set());
  const [sortConfig, setSortConfig] = useState<{ field: SortField; direction: SortDirection }>({
    field: 'fechaCreacion',
    direction: 'desc'
  });

  const handleSort = (field: SortField) => {
    setSortConfig(prev => ({
      field,
      direction: prev.field === field && prev.direction === 'asc' ? 'desc' : 'asc'
    }));
  };

  const sortedCotizaciones = [...cotizaciones].sort((a, b) => {
    if (!sortConfig.direction) return 0;
    
    let aValue: any;
    let bValue: any;
    
    switch (sortConfig.field) {
      case 'folio':
        aValue = a.folio;
        bValue = b.folio;
        break;
      case 'fechaCreacion':
        aValue = new Date(a.fecha);
        bValue = new Date(b.fecha);
        break;
      case 'cliente':
        aValue = a.cliente?.nombre_razon_social || '';
        bValue = b.cliente?.nombre_razon_social || '';
        break;
      case 'descripcion':
        aValue = a.descripcion || '';
        bValue = b.descripcion || '';
        break;
      case 'total':
        aValue = a.total;
        bValue = b.total;
        break;
      case 'estado':
        aValue = a.estado;
        bValue = b.estado;
        break;
      default:
        return 0;
    }
    
    if (aValue < bValue) return sortConfig.direction === 'asc' ? -1 : 1;
    if (aValue > bValue) return sortConfig.direction === 'asc' ? 1 : -1;
    return 0;
  });

  const handleSelectAll = (checked: boolean) => {
    if (checked) {
      setSelectedItems(new Set(cotizaciones.map(c => c.id)));
    } else {
      setSelectedItems(new Set());
    }
  };

  const handleSelectItem = (id: string, checked: boolean) => {
    const newSelected = new Set(selectedItems);
    if (checked) {
      newSelected.add(id);
    } else {
      newSelected.delete(id);
    }
    setSelectedItems(newSelected);
  };

  const isAllSelected = cotizaciones.length > 0 && selectedItems.size === cotizaciones.length;
  const isPartiallySelected = selectedItems.size > 0 && selectedItems.size < cotizaciones.length;

  return (
    <>
      {/* Vista de Cards para móvil */}
      <div className="lg:hidden space-y-3">
        {sortedCotizaciones.map((cotizacion) => (
          <div key={cotizacion.id} className="bg-white/[0.02] border border-white/[0.06] rounded-lg p-4">
            <div className="flex items-start justify-between mb-3">
              <div className="flex-1">
                <div className="font-semibold text-white">{cotizacion.folio}</div>
                <div className="text-sm text-muted-foreground mt-1">
                  {cotizacion.cliente?.nombre_razon_social || 'Sin cliente'}
                </div>
              </div>
              <DropdownMenu>
                <DropdownMenuTrigger asChild>
                  <Button variant="ghost" size="sm" className="h-8 w-8 p-0">
                    <MoreVertical className="h-4 w-4" />
                  </Button>
                </DropdownMenuTrigger>
                <DropdownMenuContent align="end">
                  <DropdownMenuItem onClick={() => onVerCotizacion(cotizacion.id)}>
                    <FileText className="mr-2 h-4 w-4" />
                    Ver detalles
                  </DropdownMenuItem>
                  {onEditarCotizacion && (
                    <DropdownMenuItem onClick={() => onEditarCotizacion(cotizacion.id)}>
                      <Edit2 className="mr-2 h-4 w-4" />
                      Editar
                    </DropdownMenuItem>
                  )}
                  <DropdownMenuItem onClick={() => onDuplicarCotizacion(cotizacion.id)}>
                    <Copy className="mr-2 h-4 w-4" />
                    Duplicar
                  </DropdownMenuItem>
                  <DropdownMenuItem 
                    onClick={() => onEliminarCotizacion(cotizacion.id)}
                    className="text-red-600"
                  >
                    <Trash2 className="mr-2 h-4 w-4" />
                    Eliminar
                  </DropdownMenuItem>
                </DropdownMenuContent>
              </DropdownMenu>
            </div>
            
            <div className="space-y-2 text-sm">
              <div className="flex justify-between">
                <span className="text-muted-foreground">Descripción:</span>
                <span className="text-white truncate ml-2">
                  {cotizacion.descripcion || 'Sin descripción'}
                </span>
              </div>
              <div className="flex justify-between">
                <span className="text-muted-foreground">Fecha:</span>
                <span className="text-white">{formatearFecha(cotizacion.fecha)}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-muted-foreground">Total:</span>
                <span className="font-semibold text-white">{formatearMoneda(cotizacion.total)}</span>
              </div>
              <div className="flex justify-between items-center">
                <span className="text-muted-foreground">Estado:</span>
                <ModernBadge estado={cotizacion.estado} />
              </div>
            </div>
            
            <Button 
              className="w-full mt-3" 
              variant="outline" 
              size="sm"
              onClick={() => onVerCotizacion(cotizacion.id)}
            >
              <FileText className="mr-2 h-4 w-4" />
              Ver cotización
            </Button>
          </div>
        ))}
      </div>

      {/* Tabla para desktop */}
      <div className="hidden lg:block bg-white/[0.02] border border-white/[0.06] rounded-lg overflow-hidden">
        {/* Tabla */}
        <div className="w-full overflow-x-auto">
          {/* Header */}
          <div className="bg-white/[0.03] border-b border-white/[0.06] h-14 grid grid-cols-[40px_120px_200px_1fr_160px_140px_120px_120px_60px] gap-0">
          <ModernCell type="header">
            <ModernCheckbox
              checked={isAllSelected}
              onCheckedChange={handleSelectAll}
            />
          </ModernCell>
          
          <ModernCell type="header">
            <SortableHeader field="folio" currentSort={sortConfig} onSort={handleSort}>
              Folio
            </SortableHeader>
          </ModernCell>
          
          <ModernCell type="header">
            <SortableHeader field="cliente" currentSort={sortConfig} onSort={handleSort}>
              Cliente
            </SortableHeader>
          </ModernCell>

          <ModernCell type="header">
            <SortableHeader field="descripcion" currentSort={sortConfig} onSort={handleSort}>
              Descripción
            </SortableHeader>
          </ModernCell>
          
          <ModernCell type="header">
            <SortableHeader field="fechaCreacion" currentSort={sortConfig} onSort={handleSort}>
              Fecha
            </SortableHeader>
          </ModernCell>

          <ModernCell type="header">
            <div className="font-semibold text-white/60 text-base cursor-pointer hover:text-white flex items-center gap-1 transition-colors group">
              Fecha Entrega
            </div>
          </ModernCell>
          
          <ModernCell type="header">
            <SortableHeader field="total" currentSort={sortConfig} onSort={handleSort}>
              Total
            </SortableHeader>
          </ModernCell>
          
          <ModernCell type="header">
            <SortableHeader field="estado" currentSort={sortConfig} onSort={handleSort}>
              Estado
            </SortableHeader>
          </ModernCell>
          
          <ModernCell type="header">
            <div className="font-semibold text-white/60 text-base">
              {/* Acciones */}
            </div>
          </ModernCell>
        </div>

        {/* Rows */}
        <div className="divide-y divide-white/[0.04]">
          {sortedCotizaciones.map((cotizacion) => (
            <div 
              key={cotizacion.id} 
              className="h-16 grid grid-cols-[40px_120px_200px_1fr_160px_140px_120px_120px_60px] gap-0 hover:bg-white/[0.04] transition-colors"
            >
              <ModernCell>
                <ModernCheckbox
                  checked={selectedItems.has(cotizacion.id)}
                  onCheckedChange={(checked) => handleSelectItem(cotizacion.id, checked)}
                />
              </ModernCell>
              
              <ModernCell onClick={() => onVerCotizacion(cotizacion.id)}>
                <div className="flex flex-col justify-center w-full">
                  <div className="font-semibold text-white text-sm">
                    {cotizacion.folio} {cotizacion.version > 1 ? `v${cotizacion.version}` : ''}
                  </div>
                  {cotizacion.cotizacion_padre_id && (
                    <div className="text-xs text-muted-foreground">Derivada</div>
                  )}
                </div>
              </ModernCell>
              
              <ModernCell onClick={() => onVerCotizacion(cotizacion.id)}>
                <div className="flex flex-col justify-center w-full">
                  <div className="font-semibold text-white text-sm">
                    {cotizacion.cliente?.nombre_razon_social || 'Sin cliente'}
                  </div>
                  <div className="text-xs text-muted-foreground">
                    {cotizacion.cliente?.correo || ''}
                  </div>
                </div>
              </ModernCell>

              <ModernCell onClick={() => onVerCotizacion(cotizacion.id)}>
                <div className="flex flex-col justify-center w-full">
                  <div className="text-sm text-white/80 truncate" title={cotizacion.descripcion || 'Sin descripción'}>
                    {cotizacion.descripcion || 'Sin descripción'}
                  </div>
                </div>
              </ModernCell>
              
              <ModernCell onClick={() => onVerCotizacion(cotizacion.id)}>
                <div className="flex flex-col justify-center w-full">
                  <div className="text-sm text-white/70">
                    {formatearFecha(cotizacion.fecha)}
                  </div>
                </div>
              </ModernCell>

              <ModernCell onClick={() => onVerCotizacion(cotizacion.id)}>
                <div className="flex flex-col justify-center w-full">
                  <div className="text-sm text-white/70">
                    {cotizacion.fecha_entrega ? new Date(cotizacion.fecha_entrega).toLocaleDateString() : '—'}
                  </div>
                </div>
              </ModernCell>
              
              <ModernCell onClick={() => onVerCotizacion(cotizacion.id)}>
                <div className="flex flex-col justify-center w-full">
                  <div className="font-semibold text-sm text-white">
                    {formatearMoneda(cotizacion.total)}
                  </div>
                </div>
              </ModernCell>
              
              <ModernCell>
                <ModernBadge estado={cotizacion.estado} />
              </ModernCell>
              
              <ModernCell>
                <DropdownMenu>
                  <DropdownMenuTrigger asChild>
                    <Button variant="ghost" className="h-8 w-8 p-0">
                      <MoreVertical className="h-4 w-4" />
                    </Button>
                  </DropdownMenuTrigger>
                  <DropdownMenuContent align="end">
                    <DropdownMenuItem onClick={() => onVerCotizacion(cotizacion.id)}>
                      <FileText className="mr-2 h-4 w-4" />
                      Ver detalles
                    </DropdownMenuItem>
                    {onEditarCotizacion && (
                      <DropdownMenuItem onClick={() => onEditarCotizacion(cotizacion.id)}>
                        <Edit2 className="mr-2 h-4 w-4" />
                        Editar
                      </DropdownMenuItem>
                    )}
                    <DropdownMenuItem onClick={() => onDuplicarCotizacion(cotizacion.id)}>
                      <Copy className="mr-2 h-4 w-4" />
                      Duplicar
                    </DropdownMenuItem>

                    <DropdownMenuItem 
                      onClick={() => onEliminarCotizacion(cotizacion.id)}
                      className="text-red-600"
                    >
                      <Trash2 className="mr-2 h-4 w-4" />
                      Eliminar
                    </DropdownMenuItem>
                  </DropdownMenuContent>
                </DropdownMenu>
              </ModernCell>
            </div>
          ))}
        </div>

          {/* Empty state */}
          {cotizaciones.length === 0 && (
            <div className="py-12 text-center text-muted-foreground">
              <FileText className="mx-auto h-12 w-12 text-muted-foreground mb-4" />
              <p className="text-lg font-medium text-white">No hay cotizaciones</p>
              <p className="text-sm">Crea tu primera cotización para comenzar</p>
            </div>
          )}
        </div>

        {/* Footer con acciones por lotes si hay elementos seleccionados */}
        {selectedItems.size > 0 && (
          <div className="bg-accent-blue/10 border-t border-accent-blue/20 px-4 py-3">
            <div className="flex items-center justify-between">
              <span className="text-sm text-accent-blue">
                {selectedItems.size} elemento{selectedItems.size !== 1 ? 's' : ''} seleccionado{selectedItems.size !== 1 ? 's' : ''}
              </span>
              <div className="flex gap-2">
                <Button variant="outline" size="sm" onClick={() => setSelectedItems(new Set())}>
                  Cancelar
                </Button>
                <Button variant="destructive" size="sm">
                  Eliminar seleccionados
                </Button>
              </div>
            </div>
          </div>
        )}
      </div>
    </>
  );
}