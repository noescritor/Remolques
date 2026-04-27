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
  ArrowRight
} from 'lucide-react';
import { formatearMoneda, formatearFecha } from '../../utils/calculations';
import { Cotizacion, Cliente, Producto } from '../../types';
import { PieChart, Pie, Cell, BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, LineChart, Line } from 'recharts';

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
  borrador: '#6b7280',
  enviada: '#3b82f6',
  aprobada: '#10b981',
  rechazada: '#ef4444',
  vencida: '#f59e0b',
  pagada: '#059669'
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
  
  const estadisticas = useMemo(() => {
    if (!cotizaciones.length) {
      return {
        totalCotizaciones: 0,
        totalClientes: clientes.length,
        totalProductos: productos.length,
        ingresosTotales: 0,
        ventasTotales: 0,
        promedioValor: 0,
        estadosCotizaciones: [],
        cotizacionesRecientes: [],
        tendenciaMensual: [],
        tasaAprobacion: 0
      };
    }

    // Calcular métricas básicas
    const totalCotizaciones = cotizaciones.length;
    
    // Calcular ingresos reales basados en pagos efectivos
    const ingresosTotales = cotizaciones.reduce((sum, cotizacion) => {
      const pagosCotizacion = pagos.filter(p => p?.cotizacion_id === cotizacion.id);
      const totalPagado = pagosCotizacion.reduce((pagosSum, pago) => pagosSum + (pago?.monto || 0), 0);
      return sum + totalPagado;
    }, 0);
    
    // Calcular ventas totales (cotizaciones aprobadas/pagadas, independiente de si se cobraron)
    const ventasTotales = cotizaciones
      .filter(c => c.estado === 'aprobada' || c.estado === 'pagada')
      .reduce((sum, c) => sum + (c.total || 0), 0);
    
    const promedioValor = cotizaciones.reduce((sum, c) => sum + (c.total || 0), 0) / totalCotizaciones;

    // Estados de cotizaciones para gráfico de pie
    const estadosCount = cotizaciones.reduce((acc, cotizacion) => {
      const estado = cotizacion.estado || 'borrador';
      acc[estado] = (acc[estado] || 0) + 1;
      return acc;
    }, {} as Record<string, number>);

    const estadosCotizaciones = Object.entries(estadosCount).map(([estado, count]) => ({
      name: estado.charAt(0).toUpperCase() + estado.slice(1),
      value: count,
      color: COLORS[estado as keyof typeof COLORS] || COLORS.borrador
    }));

    // Cotizaciones recientes (últimas 5)
    const cotizacionesRecientes = [...cotizaciones]
      .sort((a, b) => new Date(b.fechaCreacion).getTime() - new Date(a.fechaCreacion).getTime())
      .slice(0, 5);

    // Tendencia mensual (últimos 6 meses)
    const now = new Date();
    const tendenciaMensual = Array.from({ length: 6 }, (_, i) => {
      const fecha = new Date(now.getFullYear(), now.getMonth() - i, 1);
      const mes = fecha.toLocaleDateString('es-ES', { month: 'short' });
      const cotizacionesMes = cotizaciones.filter(c => {
        const fechaCot = new Date(c.fechaCreacion || c.fecha || '');
        return fechaCot.getMonth() === fecha.getMonth() && 
               fechaCot.getFullYear() === fecha.getFullYear();
      });
      
      return {
        mes,
        cotizaciones: cotizacionesMes.length,
        ingresos: cotizacionesMes.reduce((sum, cotizacion) => {
          const pagosCotizacion = pagos.filter(p => {
            if (p?.cotizacion_id !== cotizacion.id) return false;
            const fechaPago = new Date(p.fecha_pago || p.fechaCreacion || '');
            return fechaPago.getMonth() === fecha.getMonth() && 
                   fechaPago.getFullYear() === fecha.getFullYear();
          });
          const totalPagadoMes = pagosCotizacion.reduce((pagosSum, pago) => pagosSum + (pago?.monto || 0), 0);
          return sum + totalPagadoMes;
        }, 0)
      };
    }).reverse();

    // Tasa de aprobación
    const aprobadas = cotizaciones.filter(c => c.estado === 'aprobada' || c.estado === 'pagada').length;
    const tasaAprobacion = totalCotizaciones > 0 ? (aprobadas / totalCotizaciones) * 100 : 0;

    return {
      totalCotizaciones,
      totalClientes: clientes.length,
      totalProductos: productos.length,
      ingresosTotales,
      ventasTotales,
      promedioValor,
      estadosCotizaciones,
      cotizacionesRecientes,
      tendenciaMensual,
      tasaAprobacion
    };
  }, [cotizaciones, clientes, productos, pagos]);

  const getBadgeVariant = (estado: string) => {
    switch (estado.toLowerCase()) {
      case 'aprobada':
      case 'pagada':
        return 'default'; // Verde
      case 'enviada':
        return 'secondary'; // Azul
      case 'borrador':
        return 'outline'; // Gris
      case 'rechazada':
        return 'destructive'; // Rojo
      default:
        return 'outline';
    }
  };

  if (loading) {
    return (
      <div className="space-y-6">
        <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-5">
          {[...Array(5)].map((_, i) => (
            <Card key={i} className="animate-pulse">
              <CardHeader className="pb-2">
                <div className="h-4 bg-gray-200 rounded w-3/4"></div>
              </CardHeader>
              <CardContent>
                <div className="h-8 bg-gray-200 rounded w-1/2 mb-2"></div>
                <div className="h-3 bg-gray-200 rounded w-full"></div>
              </CardContent>
            </Card>
          ))}
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-4 sm:space-y-6">
      {/* Header del Dashboard */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl sm:text-3xl font-bold text-gray-900">Dashboard</h1>
          <p className="text-sm sm:text-base text-gray-600 mt-1">
            Resumen ejecutivo de tu negocio
          </p>
        </div>
        <Button onClick={onNuevaCotizacion} className="bg-blue-600 hover:bg-blue-700 w-full sm:w-auto">
          <Plus className="mr-2 h-4 w-4" />
          Nueva Cotización
        </Button>
      </div>

      {/* KPIs Principales */}
      <div className="grid gap-4 sm:gap-6 grid-cols-1 sm:grid-cols-2 lg:grid-cols-5">
        <QuickStats
          title="Total Cotizaciones"
          value={estadisticas.totalCotizaciones}
          subtitle={`Tasa de aprobación: ${estadisticas.tasaAprobacion.toFixed(1)}%`}
          icon={<FileText className="w-6 h-6" />}
          color="blue"
          trend={estadisticas.tasaAprobacion > 50 ? 'up' : estadisticas.tasaAprobacion < 30 ? 'down' : 'neutral'}
          trendValue={`${estadisticas.tasaAprobacion.toFixed(1)}%`}
        />

        <QuickStats
          title="Ingresos Reales"
          value={formatearMoneda(estadisticas.ingresosTotales)}
          subtitle="Pagos recibidos"
          icon={<DollarSign className="w-6 h-6" />}
          color="green"
        />

        <QuickStats
          title="Ventas Generadas"
          value={formatearMoneda(estadisticas.ventasTotales)}
          subtitle={`Promedio: ${formatearMoneda(estadisticas.promedioValor)}`}
          icon={<TrendingUp className="w-6 h-6" />}
          color="blue"
        />

        <QuickStats
          title="Clientes Activos"
          value={estadisticas.totalClientes}
          subtitle="Gestionar clientes"
          icon={<Users className="w-6 h-6" />}
          color="purple"
        />

        <QuickStats
          title="Productos"
          value={estadisticas.totalProductos}
          subtitle="Catálogo disponible"
          icon={<Package className="w-6 h-6" />}
          color="orange"
        />
      </div>

      {/* Acciones Rápidas y Gráficos */}
      <div className="grid gap-4 sm:gap-6 grid-cols-1 lg:grid-cols-3">
        {/* Acciones Rápidas */}
        <div className="lg:col-span-1">
          <QuickActions 
            onNuevaCotizacion={onNuevaCotizacion}
            onNavigate={onNavigate}
          />
        </div>

        {/* Gráfico de Estados */}
        <div className="lg:col-span-2">
          <div className="grid gap-4 sm:gap-6 grid-cols-1 lg:grid-cols-2">
            {/* Gráfico de Estados */}
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <TrendingUp className="h-5 w-5 text-blue-600" />
                  Distribución por Estado
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div className="h-64">
                  <ResponsiveContainer width="100%" height="100%">
                    <PieChart>
                      <Pie
                        data={estadisticas.estadosCotizaciones}
                        cx="50%"
                        cy="50%"
                        innerRadius={40}
                        outerRadius={80}
                        paddingAngle={2}
                        dataKey="value"
                      >
                        {estadisticas.estadosCotizaciones.map((entry) => (
                          <Cell key={`cell-${entry.name}`} fill={entry.color} />
                        ))}
                      </Pie>
                      <Tooltip 
                        formatter={(value) => [`${value} cotizaciones`, 'Cantidad']}
                      />
                    </PieChart>
                  </ResponsiveContainer>
                </div>
                <div className="flex flex-wrap gap-2 mt-4">
                  {estadisticas.estadosCotizaciones.map((estado) => (
                    <div key={`legend-${estado.name}`} className="flex items-center gap-2">
                      <div 
                        className="w-3 h-3 rounded-full" 
                        style={{ backgroundColor: estado.color }}
                      ></div>
                      <span className="text-sm text-gray-600">
                        {estado.name} ({estado.value})
                      </span>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>

            {/* Tendencia Mensual */}
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <TrendingUp className="h-5 w-5 text-green-600" />
                  Tendencia Mensual
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div className="h-64">
                  <ResponsiveContainer width="100%" height="100%">
                    <LineChart data={estadisticas.tendenciaMensual}>
                      <CartesianGrid strokeDasharray="3 3" />
                      <XAxis dataKey="mes" />
                      <YAxis yAxisId="left" />
                      <YAxis yAxisId="right" orientation="right" />
                      <Tooltip 
                        formatter={(value, name) => [
                          name === 'ingresos' ? formatearMoneda(value as number) : value,
                          name === 'ingresos' ? 'Ingresos' : 'Cotizaciones'
                        ]}
                      />
                      <Line 
                        type="monotone" 
                        dataKey="cotizaciones" 
                        stroke="#3b82f6" 
                        strokeWidth={2}
                        dot={{ fill: '#3b82f6' }}
                        yAxisId="left"
                      />
                      <Line 
                        type="monotone" 
                        dataKey="ingresos" 
                        stroke="#10b981" 
                        strokeWidth={2}
                        dot={{ fill: '#10b981' }}
                        yAxisId="right"
                      />
                    </LineChart>
                  </ResponsiveContainer>
                </div>
              </CardContent>
            </Card>
          </div>
        </div>
      </div>

      {/* Cotizaciones Recientes */}
      <Card>
        <CardHeader className="flex flex-col sm:flex-row sm:items-center sm:justify-between space-y-2 sm:space-y-0">
          <CardTitle className="flex items-center gap-2">
            <Clock className="h-5 w-5 text-blue-600" />
            Cotizaciones Recientes
          </CardTitle>
          <Button 
            variant="outline" 
            size="sm"
            onClick={() => onNavigate('cotizaciones')}
            className="w-full sm:w-auto"
          >
            Ver todas
            <ArrowRight className="ml-2 h-4 w-4" />
          </Button>
        </CardHeader>
        <CardContent>
          <div className="space-y-3 sm:space-y-4">
            {estadisticas.cotizacionesRecientes.length === 0 ? (
              <div className="text-center py-8 text-gray-500">
                <FileText className="mx-auto h-12 w-12 text-gray-300 mb-4" />
                <p>No hay cotizaciones recientes</p>
                <Button 
                  onClick={onNuevaCotizacion}
                  className="mt-4"
                  variant="outline"
                >
                  <Plus className="mr-2 h-4 w-4" />
                  Crear primera cotización
                </Button>
              </div>
            ) : (
              estadisticas.cotizacionesRecientes.map((cotizacion) => (
                <div 
                  key={cotizacion.id}
                  className="flex flex-col sm:flex-row sm:items-center sm:justify-between p-4 border border-gray-200 rounded-lg hover:bg-gray-50 cursor-pointer transition-colors gap-3"
                  onClick={() => onVerCotizacion(cotizacion.id)}
                >
                  <div className="flex flex-col sm:flex-row sm:items-center sm:space-x-4 gap-2">
                    <div>
                      <p className="font-medium text-gray-900">
                        {cotizacion.folio}
                      </p>
                      <p className="text-sm text-gray-500">
                        {cotizacion.cliente?.nombre_razon_social || 'Sin cliente'}
                      </p>
                    </div>
                  </div>
                  <div className="flex items-center justify-between sm:space-x-4">
                    <div className="text-left sm:text-right">
                      <p className="font-medium text-gray-900">
                        {formatearMoneda(cotizacion.total || 0)}
                      </p>
                      <p className="text-sm text-gray-500">
                        {formatearFecha(cotizacion.fechaCreacion || cotizacion.fecha || '')}
                      </p>
                    </div>
                    <div className="flex items-center gap-2">
                      <Badge variant={getBadgeVariant(cotizacion.estado || 'borrador')}>
                        {(cotizacion.estado || 'borrador').charAt(0).toUpperCase() + 
                         (cotizacion.estado || 'borrador').slice(1)}
                      </Badge>
                      <Button variant="ghost" size="sm" className="hidden sm:inline-flex">
                        <Eye className="h-4 w-4" />
                      </Button>
                    </div>
                  </div>
                </div>
              ))
            )}
          </div>
        </CardContent>
      </Card>
    </div>
  );
}