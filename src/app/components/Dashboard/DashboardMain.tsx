import { useMemo } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '../ui/card';
import { Badge } from '../ui/badge';
import { Button } from '../ui/button';
import { QuickStats } from './QuickStats';
import { QuickActions } from './QuickActions';
import { 
  FileText, 
  Users, 
  Package, 
  TrendingUp, 
  DollarSign, 
  Clock, 
  CheckCircle,
  AlertCircle,
  Plus,
  Eye,
  ArrowRight,
  Calendar,
  AlertTriangle,
  Factory
} from 'lucide-react';
import { formatearMoneda, formatearFecha } from '../../utils/calculations';
import { Cotizacion, Cliente, Producto } from '../../types';
import { PieChart, Pie, Cell, BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, LineChart, Line } from 'recharts';
import { formatDistanceToNow, isPast } from 'date-fns';
import { es } from 'date-fns/locale';

interface DashboardMainProps {
  cotizaciones: Cotizacion[];
  clientes: Cliente[];
  productos: Producto[];
  pagos: any[];
  loading: boolean;
  onNuevaCotizacion: () => void;
  onVerCotizacion: (id: string) => void;
  onNavigate: (page: string) => void;
}

const COLORS = {
  borrador: 'rgba(255,255,255,0.25)',
  enviada: '#91CAFF',
  aprobada: '#91FFB0',
  rechazada: '#FF919F',
  vencida: '#FFD391',
  pagada: '#A191FF'
};

export function DashboardMain({
  cotizaciones,
  clientes,
  productos,
  pagos,
  loading,
  onNuevaCotizacion,
  onVerCotizacion,
  onNavigate
}: DashboardMainProps) {
  
  const {
    estadisticas,
    pendientesProduccion,
    perdidasDeVista,
    proximasEntregas
  } = useMemo(() => {
    if (!cotizaciones.length) {
      return {
        estadisticas: {
          totalCotizaciones: 0, totalClientes: clientes.length, totalProductos: productos.length,
          ingresosTotales: 0, ventasTotales: 0, promedioValor: 0, estadosCotizaciones: [],
          cotizacionesRecientes: [], tendenciaMensual: [], tasaAprobacion: 0
        },
        pendientesProduccion: [], perdidasDeVista: [], proximasEntregas: []
      };
    }

    const totalCotizaciones = cotizaciones.length;
    
    const ingresosTotales = cotizaciones.reduce((sum, cotizacion) => {
      const pagosCotizacion = pagos.filter(p => p?.cotizacion_id === cotizacion.id);
      const totalPagado = pagosCotizacion.reduce((pagosSum, pago) => pagosSum + (pago?.monto || 0), 0);
      return sum + totalPagado;
    }, 0);
    
    const ventasTotales = cotizaciones
      .filter(c => c.estado === 'Aprobada' || c.estado === 'Pagada')
      .reduce((sum, c) => sum + (c.total || 0), 0);
    
    const promedioValor = cotizaciones.reduce((sum, c) => sum + (c.total || 0), 0) / totalCotizaciones;

    const estadosCount = cotizaciones.reduce((acc, cotizacion) => {
      const estado = (cotizacion.estado || 'Borrador').toLowerCase();
      acc[estado] = (acc[estado] || 0) + 1;
      return acc;
    }, {} as Record<string, number>);

    const estadosCotizaciones = Object.entries(estadosCount).map(([estado, count]) => ({
      name: estado.charAt(0).toUpperCase() + estado.slice(1),
      value: count,
      color: COLORS[estado as keyof typeof COLORS] || COLORS.borrador
    }));

    const cotizacionesRecientes = [...cotizaciones]
      .sort((a, b) => new Date((b as any).created_at || b.fecha || '').getTime() - new Date((a as any).created_at || a.fecha || '').getTime())
      .slice(0, 5);

    const now = new Date();
    const tendenciaMensual = Array.from({ length: 6 }, (_, i) => {
      const fecha = new Date(now.getFullYear(), now.getMonth() - i, 1);
      const mes = fecha.toLocaleDateString('es-ES', { month: 'short' });
      const cotizacionesMes = cotizaciones.filter(c => {
        const fechaCot = new Date((c as any).created_at || c.fecha || '');
        return fechaCot.getMonth() === fecha.getMonth() && fechaCot.getFullYear() === fecha.getFullYear();
      });
      return {
        mes,
        cotizaciones: cotizacionesMes.length,
        ingresos: cotizacionesMes.reduce((sum, cotizacion) => {
          const pagosCotizacion = pagos.filter(p => {
            if (p?.cotizacion_id !== cotizacion.id) return false;
            const fechaPago = new Date(p.fecha_pago || p.fecha || '');
            return fechaPago.getMonth() === fecha.getMonth() && fechaPago.getFullYear() === fecha.getFullYear();
          });
          return sum + pagosCotizacion.reduce((ps, pago) => ps + (pago?.monto || 0), 0);
        }, 0)
      };
    }).reverse();

    const aprobadas = cotizaciones.filter(c => c.estado === 'Aprobada' || c.estado === 'Pagada').length;
    const tasaAprobacion = totalCotizaciones > 0 ? (aprobadas / totalCotizaciones) * 100 : 0;

    // --- SECCIONES NUEVAS DEL PANEL OPERATIVO ---

    // 1. Pendientes de Producción / Entrega
    const pendientes = cotizaciones.filter(c => 
      (c.estado === 'Aprobada' || c.estado === 'Pagada') && 
      (c.estado_produccion !== 'Entregado')
    ).sort((a, b) => new Date((b as any).created_at || b.fecha || '').getTime() - new Date((a as any).created_at || a.fecha || '').getTime());

    // 2. Perdidas de Vista (Borrador o Enviada por más de 5 días)
    const CINCO_DIAS_MS = 5 * 24 * 60 * 60 * 1000;
    const perdidas = cotizaciones.filter(c => {
      const fechaCot = new Date((c as any).created_at || c.fecha || '').getTime();
      const dif = now.getTime() - fechaCot;
      if (dif > CINCO_DIAS_MS) {
        if (c.estado === 'Borrador' || c.estado === 'Enviada') return true;
      }
      return false;
    }).sort((a, b) => new Date((a as any).created_at || a.fecha || '').getTime() - new Date((b as any).created_at || b.fecha || '').getTime());

    // 3. Próximas Entregas (Tienen fecha de entrega y no están entregadas)
    const entregas = cotizaciones.filter(c => 
      c.fecha_entrega && c.estado_produccion !== 'Entregado' && c.estado !== 'Cancelada'
    ).sort((a, b) => new Date(a.fecha_entrega!).getTime() - new Date(b.fecha_entrega!).getTime())
     .slice(0, 5); // top 5

    return {
      estadisticas: {
        totalCotizaciones, totalClientes: clientes.length, totalProductos: productos.length,
        ingresosTotales, ventasTotales, promedioValor, estadosCotizaciones,
        cotizacionesRecientes, tendenciaMensual, tasaAprobacion
      },
      pendientesProduccion: pendientes,
      perdidasDeVista: perdidas,
      proximasEntregas: entregas
    };
  }, [cotizaciones, clientes, productos, pagos]);

  const getBadgeVariant = (estado: string) => {
    switch (estado.toLowerCase()) {
      case 'aprobada': case 'pagada': return 'default';
      case 'enviada': return 'secondary';
      case 'borrador': return 'outline';
      case 'rechazada': case 'cancelada': return 'destructive';
      default: return 'outline';
    }
  };

  const getClientName = (id: string) => clientes.find(c => c.id === id)?.nombre_razon_social || 'Cliente Desconocido';

  if (loading) {
    return (
      <div className="space-y-6">
        <div className="grid gap-6 md:grid-cols-5">
          {[...Array(5)].map((_, i) => (
            <Card key={i} className="animate-pulse bg-card border-border">
              <CardHeader className="pb-2"><div className="h-4 bg-muted rounded w-3/4"></div></CardHeader>
              <CardContent>
                <div className="h-8 bg-muted rounded w-1/2 mb-2"></div>
                <div className="h-3 bg-muted rounded w-full"></div>
              </CardContent>
            </Card>
          ))}
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6 text-foreground bg-background min-h-screen">
      {/* Header del Dashboard */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-3xl font-bold font-sans">Dashboard</h1>
          <p className="text-muted-foreground mt-1 font-sans">Panel operativo y resumen ejecutivo</p>
        </div>
        <Button onClick={onNuevaCotizacion} className="bg-primary text-primary-foreground hover:bg-primary/90">
          <Plus className="mr-2 h-4 w-4" />
          Nueva Cotización
        </Button>
      </div>

      {/* Stat Cards (Fila Superior) */}
      <div className="grid gap-4 sm:gap-6 grid-cols-1 sm:grid-cols-2 lg:grid-cols-5">
        <Card className="bg-white/[0.02] border-white/[0.06]">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-label text-white/40 font-mono tracking-wide">TOTAL COTIZACIONES</CardTitle>
            <FileText className="h-4 w-4 text-accent-blue" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold font-mono">{estadisticas.totalCotizaciones}</div>
            <p className="text-xs text-muted-foreground mt-1">Aprobación: {estadisticas.tasaAprobacion.toFixed(1)}%</p>
          </CardContent>
        </Card>

        <Card className="bg-white/[0.02] border-white/[0.06]">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-label text-white/40 font-mono tracking-wide">INGRESOS REALES</CardTitle>
            <DollarSign className="h-4 w-4 text-accent-green" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold font-mono">{formatearMoneda(estadisticas.ingresosTotales)}</div>
            <p className="text-xs text-muted-foreground mt-1">Pagos recibidos</p>
          </CardContent>
        </Card>

        <Card className="bg-white/[0.02] border-white/[0.06]">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-label text-white/40 font-mono tracking-wide">VENTAS (APROBADAS)</CardTitle>
            <TrendingUp className="h-4 w-4 text-accent-violet" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold font-mono">{formatearMoneda(estadisticas.ventasTotales)}</div>
            <p className="text-xs text-muted-foreground mt-1">Ticket Prom: {formatearMoneda(estadisticas.promedioValor)}</p>
          </CardContent>
        </Card>

        <Card className="bg-white/[0.02] border-white/[0.06]">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-label text-white/40 font-mono tracking-wide">CLIENTES</CardTitle>
            <Users className="h-4 w-4 text-accent-yellow" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold font-mono">{estadisticas.totalClientes}</div>
            <p className="text-xs text-muted-foreground mt-1">Activos en directorio</p>
          </CardContent>
        </Card>

        <Card className="bg-white/[0.02] border-white/[0.06]">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-label text-white/40 font-mono tracking-wide">PRODUCTOS</CardTitle>
            <Package className="h-4 w-4 text-accent-pink" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold font-mono">{estadisticas.totalProductos}</div>
            <p className="text-xs text-muted-foreground mt-1">En catálogo</p>
          </CardContent>
        </Card>
      </div>

      {/* SECCIÓN NUEVA: Panel Operativo (3 Columnas) */}
      <div className="grid gap-6 grid-cols-1 md:grid-cols-3">
        {/* 1. Pendientes de Producción */}
        <Card className="bg-white/[0.02] border-white/[0.06] flex flex-col">
          <CardHeader className="pb-2">
            <CardTitle className="flex items-center gap-2 text-lg text-white">
              <Factory className="h-5 w-5 text-[#FFD391]" />
              Por Fabricar / Entregar
            </CardTitle>
          </CardHeader>
          <CardContent className="flex-1">
            <div className="space-y-3">
              {pendientesProduccion.length === 0 ? (
                <p className="text-sm text-muted-foreground">No hay pedidos pendientes.</p>
              ) : (
                pendientesProduccion.slice(0, 5).map(c => (
                  <div key={c.id} className="flex justify-between items-start border-b border-border-soft pb-2 cursor-pointer hover:opacity-80" onClick={() => onVerCotizacion(c.id)}>
                    <div>
                      <div className="font-mono text-sm font-bold text-white">{c.folio}</div>
                      <div className="text-xs text-muted-foreground truncate w-40">{getClientName(c.cliente_id)}</div>
                    </div>
                    <Badge style={{ backgroundColor: '#FFD391', color: '#000' }} className="text-[10px]">
                      {c.estado_produccion || 'Pendiente'}
                    </Badge>
                  </div>
                ))
              )}
            </div>
            {pendientesProduccion.length > 5 && (
              <Button variant="link" className="w-full mt-2 text-xs text-accent-blue" onClick={() => onNavigate('cotizaciones')}>Ver todos ({pendientesProduccion.length})</Button>
            )}
          </CardContent>
        </Card>

        {/* 2. Perdidas de Vista */}
        <Card className="bg-white/[0.02] border-white/[0.06] flex flex-col">
          <CardHeader className="pb-2">
            <CardTitle className="flex items-center gap-2 text-lg text-white">
              <AlertTriangle className="h-5 w-5 text-[#FF919F]" />
              Perdidas de Vista
            </CardTitle>
          </CardHeader>
          <CardContent className="flex-1">
            <div className="space-y-3">
              {perdidasDeVista.length === 0 ? (
                <p className="text-sm text-muted-foreground">Todo al día.</p>
              ) : (
                perdidasDeVista.slice(0, 5).map(c => (
                  <div key={c.id} className="flex justify-between items-start border-b border-border-soft pb-2 cursor-pointer hover:opacity-80" onClick={() => onVerCotizacion(c.id)}>
                    <div>
                      <div className="font-mono text-sm font-bold text-white">{c.folio}</div>
                      <div className="text-xs text-muted-foreground">Hace {formatDistanceToNow(new Date((c as any).created_at || c.fecha || ''), {locale: es})}</div>
                    </div>
                    <Badge style={{ backgroundColor: c.estado === 'Borrador' ? '#FFD391' : '#FF919F', color: '#000' }} className="text-[10px]">
                      {c.estado === 'Borrador' ? 'Sin Enviar' : 'Sin Respuesta'}
                    </Badge>
                  </div>
                ))
              )}
            </div>
            {perdidasDeVista.length > 5 && (
              <Button variant="link" className="w-full mt-2 text-xs text-accent-blue" onClick={() => onNavigate('cotizaciones')}>Ver todas ({perdidasDeVista.length})</Button>
            )}
          </CardContent>
        </Card>

        {/* 3. Fechas Críticas */}
        <Card className="bg-white/[0.02] border-white/[0.06] flex flex-col">
          <CardHeader className="pb-2">
            <CardTitle className="flex items-center gap-2 text-lg text-white">
              <Calendar className="h-5 w-5 text-[#91CAFF]" />
              Próximas Entregas
            </CardTitle>
          </CardHeader>
          <CardContent className="flex-1">
            <div className="space-y-3">
              {proximasEntregas.length === 0 ? (
                <p className="text-sm text-muted-foreground">No hay entregas programadas.</p>
              ) : (
                proximasEntregas.map(c => {
                  const past = isPast(new Date(c.fecha_entrega!));
                  const isTodayOrTomorrow = new Date(c.fecha_entrega!).getTime() - new Date().getTime() <= (2 * 24 * 60 * 60 * 1000);
                  
                  let badgeColor = '#91FFB0'; // Verde
                  if (past) badgeColor = '#FF919F'; // Rojo (Vencido)
                  else if (isTodayOrTomorrow) badgeColor = '#FFD391'; // Amarillo
                  
                  return (
                  <div key={c.id} className="flex justify-between items-start border-b border-border-soft pb-2 cursor-pointer hover:opacity-80" onClick={() => onVerCotizacion(c.id)}>
                    <div>
                      <div className="font-mono text-sm font-bold text-white">{c.folio}</div>
                      <div className="text-xs text-muted-foreground truncate w-40">{getClientName(c.cliente_id)}</div>
                    </div>
                    <div className="flex flex-col items-end">
                      <span className="text-[11px] text-white/60 font-mono mb-1">{new Date(c.fecha_entrega!).toLocaleDateString('es-ES')}</span>
                      <Badge style={{ backgroundColor: badgeColor, color: '#000' }} className="text-[10px]">
                         {past ? 'Vencida' : (isTodayOrTomorrow ? 'Urgente' : 'A tiempo')}
                      </Badge>
                    </div>
                  </div>
                )})
              )}
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Gráficos Recharts */}
      <div className="grid gap-6 grid-cols-1 lg:grid-cols-2">
        <Card className="bg-white/[0.02] border-white/[0.06]">
          <CardHeader>
            <CardTitle className="flex items-center gap-2 font-sans text-white">
              <TrendingUp className="h-5 w-5 text-accent-violet" />
              Tendencia Mensual
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="h-64">
              <ResponsiveContainer width="100%" height="100%">
                <LineChart data={estadisticas.tendenciaMensual}>
                  <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.1)" />
                  <XAxis dataKey="mes" stroke="rgba(255,255,255,0.4)" fontSize={12} />
                  <YAxis yAxisId="left" stroke="rgba(255,255,255,0.4)" fontSize={12} />
                  <YAxis yAxisId="right" orientation="right" stroke="rgba(255,255,255,0.4)" fontSize={12} />
                  <Tooltip 
                    contentStyle={{ backgroundColor: '#1a1a1a', border: '1px solid rgba(255,255,255,0.1)' }}
                    formatter={(value, name) => [
                      name === 'ingresos' ? formatearMoneda(value as number) : value,
                      name === 'ingresos' ? 'Ingresos' : 'Cotizaciones'
                    ]}
                  />
                  <Line type="monotone" dataKey="cotizaciones" stroke="#91CAFF" strokeWidth={3} dot={{ fill: '#91CAFF' }} yAxisId="left" />
                  <Line type="monotone" dataKey="ingresos" stroke="#91FFB0" strokeWidth={3} dot={{ fill: '#91FFB0' }} yAxisId="right" />
                </LineChart>
              </ResponsiveContainer>
            </div>
          </CardContent>
        </Card>

        <Card className="bg-white/[0.02] border-white/[0.06]">
          <CardHeader>
            <CardTitle className="flex items-center gap-2 font-sans text-white">
              <PieChart className="h-5 w-5 text-accent-blue" />
              Distribución por Estado
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="h-64">
              <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                  <Pie
                    data={estadisticas.estadosCotizaciones}
                    cx="50%" cy="50%" innerRadius={60} outerRadius={100} paddingAngle={2} dataKey="value"
                  >
                    {estadisticas.estadosCotizaciones.map((entry) => (
                      <Cell key={`cell-${entry.name}`} fill={entry.color} stroke="transparent" />
                    ))}
                  </Pie>
                  <Tooltip contentStyle={{ backgroundColor: '#1a1a1a', border: '1px solid rgba(255,255,255,0.1)' }} />
                </PieChart>
              </ResponsiveContainer>
            </div>
            <div className="flex flex-wrap justify-center gap-3 mt-4">
              {estadisticas.estadosCotizaciones.map((estado) => (
                <div key={`legend-${estado.name}`} className="flex items-center gap-2">
                  <div className="w-3 h-3 rounded-full" style={{ backgroundColor: estado.color }}></div>
                  <span className="text-xs text-white/60">{estado.name} ({estado.value})</span>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
