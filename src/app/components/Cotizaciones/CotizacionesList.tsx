import { useState } from 'react';
import { Button } from '../ui/button';
import { Input } from '../ui/input';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../ui/select';
import { Skeleton } from '../ui/skeleton';
import { Plus, Search, Filter, FileText } from 'lucide-react';
import { Cotizacion } from '../../types';
import { CotizacionesTableModern } from './CotizacionesTableModern';
import { supabase } from '../../utils/supabase/client';
import { toast } from 'sonner';
import { defaultPresupuestoDatos } from '../Presupuestos/presupuestoTemplate';

interface CotizacionesListProps {
  cotizaciones: Cotizacion[];
  loading: boolean;
  onNuevaCotizacion: () => void;
  onVerCotizacion: (id: string) => void;
  onDuplicarCotizacion: (id: string) => void;
  onEliminarCotizacion: (id: string) => void;
}

export function CotizacionesList({
  cotizaciones,
  loading,
  onNuevaCotizacion,
  onVerCotizacion,
  onDuplicarCotizacion,
  onEliminarCotizacion
}: CotizacionesListProps) {
  const [busqueda, setBusqueda] = useState('');
  const [filtroEstado, setFiltroEstado] = useState<string>('todos');

  
  const [generandoPresupuesto, setGenerandoPresupuesto] = useState(false);

  const handleGenerarPresupuesto = async (cotizacion: Cotizacion) => {
    try {
      setGenerandoPresupuesto(true);
      toast.info('Extrayendo recetas BOM para generar presupuesto...');

      // Find the first producto_terminado in the quote items
      const mainItems = cotizacion.items;
      if (!mainItems || mainItems.length === 0) {
        toast.error('La cotización no tiene items.');
        return;
      }

      // We will create a budget for the first finished product (or merge them)
      // For simplicity, let's just grab all materials required for this quote
      const requiredMaterials: { pzas: string, material: string, cu: number, importe: number }[] = [];
      let totalCosto = 0;

      for (const item of mainItems) {
        if (!item.producto_id) continue;
        
        const { data: prod } = await supabase.from('productos').select('tipo_item').eq('id', item.producto_id).single();
        if (prod && prod.tipo_item === 'producto_terminado') {
          // Fetch BOM
          const { data: receta } = await supabase.from('producto_materiales')
            .select('cantidad, material:productos(id, nombre, costo, precio_unitario)')
            .eq('producto_id', item.producto_id);
            
          if (receta && receta.length > 0) {
            for (const rm of receta) {
              const cant = Number(rm.cantidad) * item.cantidad;
              const costo = Number((rm.material as any).costo || (rm.material as any).precio_unitario || 0);
              const importe = cant * costo;
              
              requiredMaterials.push({
                pzas: cant.toString(),
                material: (rm.material as any).nombre,
                cu: costo,
                importe: importe
              });
              totalCosto += importe;
            }
          }
        }
      }

      if (requiredMaterials.length === 0) {
        toast.error('Ninguno de los items de la cotización tiene una receta (BOM) configurada en la BD.');
        return;
      }

      // Create new presupuesto payload
      const datos = JSON.parse(JSON.stringify(defaultPresupuestoDatos));
      // Empty out the default template and dump our custom BOM into 'acero' to show it cleanly
      for (const key of Object.keys(datos)) {
        datos[key].items = [];
        datos[key].total = 0;
      }
      datos.acero.items = requiredMaterials;
      datos.acero.total = totalCosto;

      const payload = {
        organizacion_id: cotizacion.organizacion_id,
        cliente_id: cotizacion.cliente_id,
        folio: 'PRE-' + cotizacion.folio,
        fecha: new Date().toISOString().split('T')[0],
        concepto: 'Presupuesto basado en Cotización ' + cotizacion.folio,
        datos: datos,
        total_costo: totalCosto,
        precio_venta: cotizacion.total_cotizacion || 0
      };

      const { error } = await supabase.from('presupuestos').insert(payload);
      if (error) throw error;

      toast.success('Presupuesto de producción generado con éxito. Revisa el módulo de Presupuestos.');

    } catch (err: any) {
      console.error(err);
      toast.error('Error generando presupuesto: ' + err.message);
    } finally {
      setGenerandoPresupuesto(false);
    }
  };

  const cotizacionesSeguras = Array.isArray(cotizaciones) ? cotizaciones : [];

  const cotizacionesFiltradas = cotizacionesSeguras.filter(cotizacion => {
    if (!cotizacion) return false;
    const busquedaLower = busqueda.toLowerCase();
    const coincideBusqueda =
      (cotizacion.folio || '').toLowerCase().includes(busquedaLower) ||
      (cotizacion.cliente?.nombre_razon_social || '').toLowerCase().includes(busquedaLower) ||
      (cotizacion.descripcion || '').toLowerCase().includes(busquedaLower);
    const coincideEstado = filtroEstado === 'todos' || cotizacion.estado === filtroEstado;
    return coincideBusqueda && coincideEstado;
  });

  if (loading) {
    return (
      <div className="space-y-6">
        <div className="flex items-center justify-between">
          <div>
            <Skeleton className="h-8 w-48" />
            <Skeleton className="h-4 w-64 mt-2" />
          </div>
          <Skeleton className="h-10 w-40" />
        </div>
        <div className="flex gap-4">
          <Skeleton className="h-10 flex-1" />
          <Skeleton className="h-10 w-48" />
        </div>
        <div className="bg-card/50 border border-border/50 rounded-lg overflow-hidden">
          <div className="border-b border-border/50 h-14">
            <Skeleton className="h-full w-full" />
          </div>
          <div className="divide-y divide-white/[0.04]">
            {[...Array(5)].map((_, i) => (
              <Skeleton key={i} className="h-16 w-full" />
            ))}
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-4 sm:space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-3xl font-bold text-foreground">Cotizaciones</h1>
          <p className="text-sm sm:text-base text-muted-foreground mt-1">
            Gestiona y da seguimiento a todas las cotizaciones
          </p>
        </div>
        <Button onClick={onNuevaCotizacion} className="bg-accent-blue hover:bg-accent-blue/90 text-white w-full sm:w-auto">
          <Plus className="mr-2 h-4 w-4" />
          Nueva Cotización
        </Button>
      </div>

      {/* Filtros */}
      <div className="flex flex-col sm:flex-row gap-3 sm:gap-4 items-stretch sm:items-center bg-card/50 p-4 rounded-lg border border-border/50">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
          <Input
            placeholder="Buscar por folio, cliente..."
            value={busqueda}
            onChange={(e) => setBusqueda(e.target.value)}
            className="pl-10 bg-transparent border-border text-foreground placeholder:text-muted-foreground"
          />
        </div>
        <Select value={filtroEstado} onValueChange={setFiltroEstado}>
          <SelectTrigger className="w-full sm:w-48 bg-transparent border-border text-foreground">
            <Filter className="mr-2 h-4 w-4 text-muted-foreground" />
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="todos">Todos los estados</SelectItem>
            <SelectItem value="Borrador">Borrador</SelectItem>
            <SelectItem value="Enviada">Enviada</SelectItem>
            <SelectItem value="Aprobada">Aprobada</SelectItem>
            <SelectItem value="Cancelada">Cancelada</SelectItem>
            <SelectItem value="Pagada">Pagada</SelectItem>
          </SelectContent>
        </Select>
      </div>

      {/* Tabla */}
      {cotizacionesFiltradas.length === 0 ? (
        <div className="bg-card/50 border border-border/50 rounded-xl p-12 text-center">
          <FileText className="mx-auto h-12 w-12 text-muted-foreground mb-4" />
          <h3 className="text-lg font-medium text-foreground mb-2">
            {busqueda || filtroEstado !== 'todos' ? 'No se encontraron cotizaciones' : 'No hay cotizaciones'}
          </h3>
          <p className="text-muted-foreground mb-6">
            {busqueda || filtroEstado !== 'todos'
              ? 'Intenta ajustar los filtros de búsqueda'
              : 'Comienza creando tu primera cotización'}
          </p>
          {!busqueda && filtroEstado === 'todos' && (
            <Button onClick={onNuevaCotizacion} className="bg-accent-blue hover:bg-accent-blue/90 text-white">
              <Plus className="mr-2 h-4 w-4" />
              Nueva Cotización
            </Button>
          )}
        </div>
      ) : (
        <CotizacionesTableModern
            onGenerarPresupuesto={handleGenerarPresupuesto}
          cotizaciones={cotizacionesFiltradas}
          onVerCotizacion={onVerCotizacion}
          onDuplicarCotizacion={onDuplicarCotizacion}
          onEliminarCotizacion={onEliminarCotizacion}
        />
      )}
    </div>
  );
}