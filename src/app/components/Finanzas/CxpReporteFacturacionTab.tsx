import React, { useState, useEffect, useMemo } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '../ui/card';
import { Button } from '../ui/button';
import { Input } from '../ui/input';
import { Label } from '../ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../ui/select';
import {
  FileText,
  Download,
  Printer,
  Calendar,
  DollarSign,
  AlertTriangle,
  RefreshCw,
  Search,
  Filter,
} from 'lucide-react';
import { BASE_URL } from '../../utils/api';
import { formatearMonedaDe, fechaLocalISO } from '../../utils/cuentasPorPagar';
import { toast } from 'sonner';

interface ReporteFacturacionTabProps {
  proveedores: any[];
  getAuthToken: () => Promise<string>;
}

export function CxpReporteFacturacionTab({
  proveedores,
  getAuthToken,
}: ReporteFacturacionTabProps) {
  // Filtros
  const [desde, setDesde] = useState('');
  const [hasta, setHasta] = useState('');
  const [filtroFechaTipo, setFiltroFechaTipo] = useState<'emision' | 'vencimiento'>('emision');
  const [proveedorId, setProveedorId] = useState('todos');
  const [moneda, setMoneda] = useState('todas');
  const [estado, setEstado] = useState('todas');
  const [busqueda, setBusqueda] = useState('');

  // Datos del reporte
  const [cargando, setCargando] = useState(false);
  const [reporteData, setReporteData] = useState<any>(null);

  const cargarReporte = async () => {
    setCargando(true);
    try {
      const token = await getAuthToken();
      const params = new URLSearchParams();
      if (desde) params.append('desde', desde);
      if (hasta) params.append('hasta', hasta);
      params.append('filtro_fecha_tipo', filtroFechaTipo);
      if (proveedorId && proveedorId !== 'todos') params.append('proveedor_id', proveedorId);
      if (moneda && moneda !== 'todas') params.append('moneda', moneda);
      if (estado && estado !== 'todas') params.append('estado', estado);

      const res = await fetch(`${BASE_URL}/cxp/reportes/facturacion?${params.toString()}`, {
        headers: { Authorization: `Bearer ${token}` },
      });

      if (!res.ok) {
        throw new Error(`Error ${res.status}: ${res.statusText}`);
      }

      const data = await res.json();
      setReporteData(data);
    } catch (err: any) {
      console.error('Error cargando reporte de facturación:', err);
      toast.error('Error al cargar reporte de facturación', { description: err.message });
    } finally {
      setCargando(false);
    }
  };

  useEffect(() => {
    cargarReporte();
  }, [desde, hasta, filtroFechaTipo, proveedorId, moneda, estado]);

  // Filtrado local por término de búsqueda (folio, RFC, proveedor, UUID)
  const itemsFiltrados = useMemo(() => {
    if (!reporteData?.items) return [];
    if (!busqueda.trim()) return reporteData.items;

    const q = busqueda.toLowerCase();
    return reporteData.items.filter((it: any) => {
      const prov = (it.proveedor_nombre || '').toLowerCase();
      const rfc = (it.proveedor_rfc || '').toLowerCase();
      const fol = (it.folio || '').toLowerCase();
      const uuid = (it.uuid_fiscal || '').toLowerCase();
      return prov.includes(q) || rfc.includes(q) || fol.includes(q) || uuid.includes(q);
    });
  }, [reporteData, busqueda]);

  // Exportar a CSV con BOM UTF-8 (\uFEFF)
  const exportarCSV = () => {
    if (!itemsFiltrados || itemsFiltrados.length === 0) {
      toast.warning('No hay datos para exportar');
      return;
    }

    const headers = [
      'Proveedor',
      'RFC',
      'Folio / Serie',
      'UUID Fiscal',
      'Fecha Emisión',
      'Fecha Vencimiento',
      'Moneda',
      'Subtotal',
      'Impuestos Trasladados',
      'Impuestos Retenidos',
      'Total Facturado',
      'Monto Pagado',
      'Saldo Pendiente',
      'Días Atraso',
      'Estado',
    ];

    const escapeCSV = (val: any) => {
      if (val === null || val === undefined) return '""';
      const str = String(val).replace(/"/g, '""');
      return `"${str}"`;
    };

    const rows = itemsFiltrados.map((it: any) => [
      escapeCSV(it.proveedor_nombre),
      escapeCSV(it.proveedor_rfc),
      escapeCSV(`${it.sucursal ? it.sucursal + ' ' : ''}${it.folio}`),
      escapeCSV(it.uuid_fiscal || 'Sin UUID'),
      escapeCSV(it.fecha_emision),
      escapeCSV(it.fecha_vencimiento),
      escapeCSV(it.moneda),
      escapeCSV((it.subtotal !== undefined && it.subtotal !== null ? it.subtotal : it.importe).toFixed(2)),
      escapeCSV((it.impuestos_trasladados ?? 0).toFixed(2)),
      escapeCSV((it.impuestos_retenidos ?? 0).toFixed(2)),
      escapeCSV(it.importe.toFixed(2)),
      escapeCSV(it.pagado.toFixed(2)),
      escapeCSV(it.saldo.toFixed(2)),
      escapeCSV(it.dias_atraso),
      escapeCSV(it.estado),
    ]);

    const csvContent = '\uFEFF' + [headers.join(','), ...rows.map((r: string[]) => r.join(','))].join('\r\n');
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.setAttribute('href', url);
    link.setAttribute('download', `reporte_facturacion_proveedores_${fechaLocalISO()}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    URL.revokeObjectURL(url);
    toast.success('Archivo CSV descargado con éxito');
  };

  const handleImprimir = () => {
    window.print();
  };

  return (
    <div className="space-y-6">
      {/* Banner de advertencia si la consulta fue truncada */}
      {reporteData?.truncado && (
        <div className="p-3.5 rounded-xl border border-amber-500/30 bg-amber-500/10 text-amber-800 dark:text-amber-300 text-xs flex items-center gap-2.5">
          <AlertTriangle className="h-4 w-4 shrink-0 text-amber-500" />
          <span>
            <strong>Consulta truncada a 500 registros:</strong> Existen más facturas que coinciden con los filtros aplicados.
            Para ver resultados específicos, acota el rango de fechas o filtra por un proveedor en particular.
          </span>
        </div>
      )}

      {/* Barra de Filtros y Acciones */}
      <Card className="bg-card text-foreground border-border print:hidden">
        <CardHeader className="pb-3">
          <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
            <CardTitle className="text-lg font-bold flex items-center gap-2">
              <Filter className="h-5 w-5 text-primary" />
              Filtros del Reporte de Facturación
            </CardTitle>
            <div className="flex items-center gap-2">
              <Button
                variant="outline"
                size="sm"
                onClick={cargarReporte}
                disabled={cargando}
                className="text-xs"
              >
                <RefreshCw className={`h-3.5 w-3.5 mr-1.5 ${cargando ? 'animate-spin' : ''}`} />
                Actualizar
              </Button>
              <Button
                variant="outline"
                size="sm"
                onClick={exportarCSV}
                className="text-xs"
              >
                <Download className="h-3.5 w-3.5 mr-1.5" />
                Exportar CSV
              </Button>
              <Button
                variant="outline"
                size="sm"
                onClick={handleImprimir}
                className="text-xs"
              >
                <Printer className="h-3.5 w-3.5 mr-1.5" />
                Imprimir
              </Button>
            </div>
          </div>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-3 text-xs">
            {/* Tipo de Fecha */}
            <div>
              <Label className="text-xs">Filtrar fecha por</Label>
              <Select
                value={filtroFechaTipo}
                onValueChange={(val: 'emision' | 'vencimiento') => setFiltroFechaTipo(val)}
              >
                <SelectTrigger className="mt-1 h-8 text-xs bg-background">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="emision">Fecha Emisión</SelectItem>
                  <SelectItem value="vencimiento">Fecha Vencimiento</SelectItem>
                </SelectContent>
              </Select>
            </div>

            {/* Fecha Desde */}
            <div>
              <Label className="text-xs">Desde</Label>
              <Input
                type="date"
                value={desde}
                onChange={(e) => setDesde(e.target.value)}
                className="mt-1 h-8 text-xs bg-background"
              />
            </div>

            {/* Fecha Hasta */}
            <div>
              <Label className="text-xs">Hasta</Label>
              <Input
                type="date"
                value={hasta}
                onChange={(e) => setHasta(e.target.value)}
                className="mt-1 h-8 text-xs bg-background"
              />
            </div>

            {/* Proveedor */}
            <div>
              <Label className="text-xs">Proveedor</Label>
              <Select value={proveedorId} onValueChange={setProveedorId}>
                <SelectTrigger className="mt-1 h-8 text-xs bg-background">
                  <SelectValue placeholder="Todos los proveedores" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="todos">Todos los proveedores</SelectItem>
                  {proveedores.map((p) => (
                    <SelectItem key={p.id} value={p.id}>
                      {p.nombre}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            {/* Moneda */}
            <div>
              <Label className="text-xs">Moneda</Label>
              <Select value={moneda} onValueChange={setMoneda}>
                <SelectTrigger className="mt-1 h-8 text-xs bg-background">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="todas">Todas las monedas</SelectItem>
                  <SelectItem value="MXN">Solo MXN (Pesos)</SelectItem>
                  <SelectItem value="USD">Solo USD (Dólares)</SelectItem>
                </SelectContent>
              </Select>
            </div>

            {/* Estado */}
            <div>
              <Label className="text-xs">Estado</Label>
              <Select value={estado} onValueChange={setEstado}>
                <SelectTrigger className="mt-1 h-8 text-xs bg-background">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="todas">Todos los estados</SelectItem>
                  <SelectItem value="abierta">Abierta / Por pagar</SelectItem>
                  <SelectItem value="pagada_parcial">Pagada parcial</SelectItem>
                  <SelectItem value="pagada">Pagada / Liquidada</SelectItem>
                  <SelectItem value="vencida">Vencida</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>

          {/* Búsqueda rápida */}
          <div className="relative">
            <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
            <Input
              type="text"
              placeholder="Buscar por folio, proveedor, RFC o UUID..."
              value={busqueda}
              onChange={(e) => setBusqueda(e.target.value)}
              className="pl-9 h-9 text-xs bg-background"
            />
          </div>
        </CardContent>
      </Card>

      {/* Tarjetas de Métricas por Moneda */}
      {reporteData && (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          {/* Facturado MXN */}
          <Card className="bg-card text-foreground border-border">
            <CardContent className="p-4">
              <div className="flex items-center justify-between">
                <span className="text-xs text-muted-foreground font-medium">Facturado MXN</span>
                <span className="text-xs px-2 py-0.5 rounded-full bg-blue-500/10 text-blue-600 dark:text-blue-400 font-mono">
                  {reporteData.totales_mxn.cantidad} facturas
                </span>
              </div>
              <div className="text-xl font-bold font-mono mt-1 text-foreground">
                {formatearMonedaDe(reporteData.totales_mxn.total, 'MXN')}
              </div>
              <div className="flex items-center justify-between text-xs text-muted-foreground mt-2 border-t border-border pt-1.5">
                <span>Saldo: <strong className="font-mono text-red-600 dark:text-red-400">{formatearMonedaDe(reporteData.totales_mxn.saldo, 'MXN')}</strong></span>
                <span>Pagado: {formatearMonedaDe(reporteData.totales_mxn.pagado, 'MXN')}</span>
              </div>
            </CardContent>
          </Card>

          {/* Facturado USD */}
          <Card className="bg-card text-foreground border-border">
            <CardContent className="p-4">
              <div className="flex items-center justify-between">
                <span className="text-xs text-muted-foreground font-medium">Facturado USD</span>
                <span className="text-xs px-2 py-0.5 rounded-full bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 font-mono">
                  {reporteData.totales_usd.cantidad} facturas
                </span>
              </div>
              <div className="text-xl font-bold font-mono mt-1 text-foreground">
                {formatearMonedaDe(reporteData.totales_usd.total, 'USD')}
              </div>
              <div className="flex items-center justify-between text-xs text-muted-foreground mt-2 border-t border-border pt-1.5">
                <span>Saldo: <strong className="font-mono text-red-600 dark:text-red-400">{formatearMonedaDe(reporteData.totales_usd.saldo, 'USD')}</strong></span>
                <span>Pagado: {formatearMonedaDe(reporteData.totales_usd.pagado, 'USD')}</span>
              </div>
            </CardContent>
          </Card>

          {/* Total Estimado en Pesos (MXN) */}
          <Card className="bg-card text-foreground border-border">
            <CardContent className="p-4">
              <div className="flex items-center justify-between">
                <span className="text-xs text-muted-foreground font-medium">Total Estimado en Pesos</span>
                <span className="text-[11px] font-mono text-muted-foreground flex items-center gap-1.5 flex-wrap justify-end">
                  {reporteData.tc_vigente?.sin_tipo_cambio && (
                    <span className="px-1.5 py-0.5 rounded bg-amber-500/10 text-amber-600 dark:text-amber-400 text-[10px] font-sans font-medium">
                      (TC estimado / sin registro a la fecha)
                    </span>
                  )}
                  <span>TC: ${reporteData.tc_vigente.valor.toFixed(4)}</span>
                </span>
              </div>
              <div className="text-xl font-bold font-mono mt-1 text-primary">
                {formatearMonedaDe(reporteData.equivalente_pesos, 'MXN')}
              </div>
              <div className="text-xs text-muted-foreground mt-2 border-t border-border pt-1.5 truncate">
                Conversión oficial al tipo de cambio registrado
              </div>
            </CardContent>
          </Card>

          {/* Saldo Pendiente Total en Pesos */}
          <Card className="bg-card text-foreground border-border">
            <CardContent className="p-4">
              <div className="flex items-center justify-between">
                <span className="text-xs text-muted-foreground font-medium">Saldo Pendiente Estimado</span>
                <span className="text-[11px] font-mono text-red-500 font-semibold">Total por liquidar</span>
              </div>
              <div className="text-xl font-bold font-mono mt-1 text-red-600 dark:text-red-400">
                {formatearMonedaDe(reporteData.saldo_equivalente_pesos, 'MXN')}
              </div>
              <div className="text-xs text-muted-foreground mt-2 border-t border-border pt-1.5">
                MXN + (USD convertidos a pesos)
              </div>
            </CardContent>
          </Card>
        </div>
      )}

      {/* Tabla del Reporte */}
      <Card className="bg-card text-foreground border-border overflow-hidden">
        <CardHeader className="py-3 px-4 bg-muted/40 border-b border-border">
          <div className="flex items-center justify-between">
            <div className="text-sm font-semibold">
              Mostrando {itemsFiltrados.length} facturas
            </div>
            <div className="text-xs text-muted-foreground">
              Al corte de: {reporteData?.corte || fechaLocalISO()}
            </div>
          </div>
        </CardHeader>
        <CardContent className="p-0">
          <div className="overflow-x-auto">
            <table className="w-full text-xs text-left border-collapse">
              <thead className="bg-muted text-muted-foreground uppercase font-semibold tracking-wider">
                <tr>
                  <th className="p-3">Proveedor</th>
                  <th className="p-3">Folio</th>
                  <th className="p-3">UUID Fiscal</th>
                  <th className="p-3">Emisión</th>
                  <th className="p-3">Vence</th>
                  <th className="p-3">Moneda</th>
                  <th className="p-3 text-right">Subtotal</th>
                  <th className="p-3 text-right">IVA</th>
                  <th className="p-3 text-right">Total</th>
                  <th className="p-3 text-right">Pagado</th>
                  <th className="p-3 text-right">Saldo</th>
                  <th className="p-3 text-center">Atraso</th>
                  <th className="p-3 text-center">Estado</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {itemsFiltrados.length === 0 ? (
                  <tr>
                    <td colSpan={13} className="p-8 text-center text-muted-foreground">
                      No se encontraron facturas con los filtros seleccionados
                    </td>
                  </tr>
                ) : (
                  itemsFiltrados.map((it: any) => {
                    const esVencida = it.estado === 'vencida';
                    const esPagada = it.estado === 'pagada';
                    const esParcial = it.estado === 'pagada_parcial';

                    return (
                      <tr key={it.id} className="hover:bg-muted/30 transition-colors">
                        <td className="p-3">
                          <div className="font-semibold text-foreground truncate max-w-[180px]">
                            {it.proveedor_nombre}
                          </div>
                          <div className="text-[11px] font-mono text-muted-foreground">
                            {it.proveedor_rfc || 'Sin RFC'}
                          </div>
                        </td>
                        <td className="p-3 font-mono font-medium whitespace-nowrap">
                          {it.sucursal ? `${it.sucursal} ` : ''}{it.folio}
                        </td>
                        <td className="p-3 font-mono text-[11px] text-muted-foreground truncate max-w-[120px]" title={it.uuid_fiscal || 'Sin UUID'}>
                          {it.uuid_fiscal ? it.uuid_fiscal.slice(0, 13) + '...' : '-'}
                        </td>
                        <td className="p-3 whitespace-nowrap">{it.fecha_emision}</td>
                        <td className="p-3 whitespace-nowrap">{it.fecha_vencimiento}</td>
                        <td className="p-3 font-semibold font-mono">{it.moneda}</td>
                        <td className="p-3 text-right font-mono font-medium">
                          {formatearMonedaDe(it.subtotal !== undefined && it.subtotal !== null ? it.subtotal : it.importe, it.moneda)}
                        </td>
                        <td className="p-3 text-right font-mono font-medium text-muted-foreground">
                          {formatearMonedaDe(it.impuestos_trasladados ?? 0, it.moneda)}
                        </td>
                        <td className="p-3 text-right font-mono font-semibold text-foreground">
                          {formatearMonedaDe(it.importe, it.moneda)}
                        </td>
                        <td className="p-3 text-right font-mono text-muted-foreground">
                          {formatearMonedaDe(it.pagado, it.moneda)}
                        </td>
                        <td className="p-3 text-right font-mono font-bold text-foreground">
                          {formatearMonedaDe(it.saldo, it.moneda)}
                        </td>
                        <td className="p-3 text-center font-mono">
                          {it.dias_atraso > 0 ? (
                            <span className="text-red-600 dark:text-red-400 font-semibold">
                              +{it.dias_atraso} d
                            </span>
                          ) : (
                            <span className="text-muted-foreground">0 d</span>
                          )}
                        </td>
                        <td className="p-3 text-center">
                          {esPagada && (
                            <span className="inline-block px-2 py-0.5 rounded text-[11px] font-medium bg-green-500/10 text-green-700 dark:text-green-400">
                              Liquidada
                            </span>
                          )}
                          {esVencida && (
                            <span className="inline-block px-2 py-0.5 rounded text-[11px] font-medium bg-red-500/10 text-red-700 dark:text-red-400">
                              Vencida
                            </span>
                          )}
                          {esParcial && (
                            <span className="inline-block px-2 py-0.5 rounded text-[11px] font-medium bg-blue-500/10 text-blue-700 dark:text-blue-400">
                              Parcial
                            </span>
                          )}
                          {!esPagada && !esVencida && !esParcial && (
                            <span className="inline-block px-2 py-0.5 rounded text-[11px] font-medium bg-muted text-muted-foreground">
                              Abierta
                            </span>
                          )}
                        </td>
                      </tr>
                    );
                  })
                )}
              </tbody>
            </table>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
