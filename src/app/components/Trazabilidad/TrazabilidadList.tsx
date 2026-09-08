import { Clock } from 'lucide-react';
import { CotizacionEvento, Cotizacion } from '../../types';

interface TrazabilidadListProps {
  eventos: CotizacionEvento[];
  cotizaciones: Cotizacion[];
  loading: boolean;
}

export function TrazabilidadList({
  eventos,
  cotizaciones,
  loading
}: TrazabilidadListProps) {

  const cotizacionesLookup = cotizaciones.reduce((acc, c) => {
    acc[c.id] = c;
    return acc;
  }, {} as Record<string, Cotizacion>);

  if (loading) {
    return <div className="animate-pulse h-64 bg-white/[0.02] rounded-xl"></div>;
  }

  // Ordenar eventos del más reciente al más antiguo
  const eventosOrdenados = [...eventos].sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime());

  return (
    <div className="space-y-6 text-foreground bg-background min-h-screen pb-20">
      <div>
        <h1 className="text-3xl font-bold font-sans">Trazabilidad de la OC</h1>
        <p className="text-muted-foreground mt-1">Bitácora de cambios de estado y fechas de cada orden.</p>
      </div>

      {eventosOrdenados.length === 0 ? (
        <div className="text-center py-20 bg-white/[0.02] rounded-xl border border-white/[0.06]">
          <Clock className="mx-auto h-12 w-12 text-muted-foreground mb-4" />
          <h3 className="text-lg font-medium text-white mb-2">No hay eventos</h3>
          <p className="text-muted-foreground">La actividad de las órdenes aparecerá aquí.</p>
        </div>
      ) : (
        <div className="rounded-xl border border-white/[0.06] bg-white/[0.02] overflow-hidden p-6 relative">
          <div className="absolute left-[39px] top-6 bottom-6 w-px bg-white/10" />
          <div className="space-y-6">
            {eventosOrdenados.map((ev) => {
              const cot = cotizacionesLookup[ev.cotizacion_id];
              const date = new Date(ev.created_at);
              return (
                <div key={ev.id} className="flex gap-4 relative z-10">
                  <div className="w-8 h-8 rounded-full bg-white/5 border border-white/20 flex items-center justify-center flex-shrink-0 mt-0.5">
                    <div className="w-2 h-2 rounded-full bg-white/50" />
                  </div>
                  <div>
                    <div className="flex items-center gap-2 mb-1">
                      <span className="font-mono text-sm bg-white/10 px-2 py-0.5 rounded text-white">{cot?.folio || 'Desconocido'}</span>
                      <span className="text-sm font-medium text-white">{ev.evento}</span>
                    </div>
                    <div className="text-xs text-muted-foreground">
                      {date.toLocaleDateString()} a las {date.toLocaleTimeString()} · por {ev.usuario?.email || 'Sistema'}
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      )}
    </div>
  );
}
