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
import { BASE_URL } from '../../utils/api';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '../ui/dialog';

interface CotizacionesListProps {
  cotizaciones: Cotizacion[];
  loading: boolean;
  onNuevaCotizacion: () => void;
  onVerCotizacion: (id: string) => void;
  onDuplicarCotizacion: (id: string) => void;
  onEliminarCotizacion: (id: string) => void;
  crearPresupuesto?: any;
  productos?: any[];
}

export function CotizacionesList({
  cotizaciones,
  loading,
  onNuevaCotizacion,
  onVerCotizacion,
  onDuplicarCotizacion,
  onEliminarCotizacion,
  crearPresupuesto,
  productos = []
}: CotizacionesListProps) {
  const [busqueda, setBusqueda] = useState('');
  const [filtroEstado, setFiltroEstado] = useState<string>('todos');
  const [generandoPresupuesto, setGenerandoPresupuesto] = useState(false);
  const [cotizacionAReemplazar, setCotizacionAReemplazar] = useState<Cotizacion | null>(null);

  const ejecutarGenerarPresupuesto = async (cotizacion: Cotizacion, reemplazar = false) => {
    if (generandoPresupuesto) return;
    setGenerandoPresupuesto(true);
    try {
      const { data: sessionData } = await supabase.auth.getSession();
      const token = sessionData.session?.access_token;
      if (!token) {
        toast.error('Sesión no válida. Por favor inicia sesión nuevamente.');
        return;
      }

      const res = await fetch(`${BASE_URL}/cotizaciones/${cotizacion.id}/presupuesto`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`
        },
        body: JSON.stringify({ reemplazar })
      });

      if (res.status === 409) {
        setCotizacionAReemplazar(cotizacion);
        return;
      }

      if (res.status === 400) {
        const errData = await res.json().catch(() => ({}));
        const omitidosStr = Array.isArray(errData.conceptos_omitidos)
          ? errData.conceptos_omitidos.map((o: any) => `• ${o.descripcion}: ${o.motivo}`).join('\n')
          : '';
        toast.error(
          errData.error || 'No se pudo generar el presupuesto',
          {
            description: omitidosStr || 'Revisa la configuración de los equipos en la cotización.',
            duration: 6000
          }
        );
        return;
      }

      if (!res.ok) {
        const errData = await res.json().catch(() => ({ error: 'Error del servidor' }));
        toast.error('Error al generar presupuesto', {
          description: errData.error || `HTTP ${res.status}`,
          action: {
            label: 'Reintentar',
            onClick: () => ejecutarGenerarPresupuesto(cotizacion, reemplazar)
          }
        });
        return;
      }

      const data = await res.json();
      setCotizacionAReemplazar(null);

      const folioPres = data.presupuesto?.folio || `PRE-${cotizacion.folio}`;
      const nEquipos = data.equipos_incluidos ?? 1;
      const costoFormateado = (data.total_costo ?? 0).toLocaleString(undefined, {
        minimumFractionDigits: 2,
        maximumFractionDigits: 2
      });

      let msgExito = `Presupuesto ${folioPres} ${data.reemplazado ? 'reemplazado' : 'generado'}: ${nEquipos} equipo(s), costo $${costoFormateado}`;
      if (data.confianza && data.confianza !== 'completa') {
        msgExito += ` (Costeo ${data.confianza})`;
      }

      toast.success(msgExito, {
        description: 'Revisa el módulo de Presupuestos para ver el detalle y materiales.',
        duration: 5000
      });
    } catch (err: any) {
      console.error('[CotizacionesList] Error generando presupuesto:', err);
      toast.error('Error de red al conectar con el servidor', {
        description: err.message,
        action: {
          label: 'Reintentar',
          onClick: () => ejecutarGenerarPresupuesto(cotizacion, reemplazar)
        }
      });
    } finally {
      setGenerandoPresupuesto(false);
    }
  };

  const handleGenerarPresupuesto = (cotizacion: Cotizacion) => {
    ejecutarGenerarPresupuesto(cotizacion, false);
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

      {/* Diálogo de confirmación para reemplazar presupuesto (409) */}
      <Dialog open={!!cotizacionAReemplazar} onOpenChange={(open) => !open && setCotizacionAReemplazar(null)}>
        <DialogContent className="sm:max-w-[425px]">
          <DialogHeader>
            <DialogTitle>Presupuesto existente</DialogTitle>
            <DialogDescription>
              Ya existe un presupuesto para la cotización {cotizacionAReemplazar?.folio}. ¿Deseas reemplazarlo con los costos y configuración actuales?
            </DialogDescription>
          </DialogHeader>
          <DialogFooter className="flex gap-2 sm:justify-end">
            <Button
              variant="outline"
              onClick={() => setCotizacionAReemplazar(null)}
              disabled={generandoPresupuesto}
            >
              Cancelar
            </Button>
            <Button
              onClick={() => cotizacionAReemplazar && ejecutarGenerarPresupuesto(cotizacionAReemplazar, true)}
              disabled={generandoPresupuesto}
              className="bg-primary text-primary-foreground hover:bg-primary/90"
            >
              {generandoPresupuesto ? 'Reemplazando...' : 'Reemplazar'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}