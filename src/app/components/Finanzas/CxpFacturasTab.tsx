import React, { useState, useMemo } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '../ui/card';
import { Button } from '../ui/button';
import { Input } from '../ui/input';
import { Label } from '../ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../ui/select';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter, DialogDescription } from '../ui/dialog';
import {
  FileText,
  Plus,
  Search,
  Filter,
  DollarSign,
  ChevronDown,
  ChevronRight,
  Edit2,
  XCircle,
  Ban,
  Clock,
  CheckCircle2,
  Calendar,
} from 'lucide-react';
import { formatearMonedaDe, Moneda, fechaLocalISO } from '../../utils/cuentasPorPagar';
import { toast } from 'sonner';

interface FacturasTabProps {
  facturas: any[];
  proveedores: any[];
  cargando: boolean;
  truncado?: boolean;
  proveedorFiltro: string;
  onCambiarProveedorFiltro: (pId: string) => void;
  tipoCambioActual: number | null;
  onCrearFactura: (payload: any) => Promise<void>;
  onActualizarFactura: (id: string, payload: any) => Promise<void>;
  onCancelarFactura: (id: string) => Promise<void>;
  onRegistrarPago: (facturaId: string, payload: any) => Promise<void>;
  onAnularPago: (pagoId: string, motivo: string) => Promise<void>;
}

export function CxpFacturasTab({
  facturas,
  proveedores,
  cargando,
  truncado = false,
  proveedorFiltro,
  onCambiarProveedorFiltro,
  tipoCambioActual,
  onCrearFactura,
  onActualizarFactura,
  onCancelarFactura,
  onRegistrarPago,
  onAnularPago,
}: FacturasTabProps) {
  // Filtros locales
  const [estadoFiltro, setEstadoFiltro] = useState<string>('todas');
  const [monedaFiltro, setMonedaFiltro] = useState<string>('todas');
  const [soloVencidas, setSoloVencidas] = useState<boolean>(false);
  const [busqueda, setBusqueda] = useState<string>('');

  // Filas expandidas (para ver pagos)
  const [expandidas, setExpandidas] = useState<Record<string, boolean>>({});

  // Diálogo Nueva/Editar Factura
  const [modalFacturaOpen, setModalFacturaOpen] = useState(false);
  const [facturaEditando, setFacturaEditando] = useState<any | null>(null);
  const [formFactura, setFormFactura] = useState({
    proveedor_id: '',
    sucursal: '',
    folio: '',
    nota: '',
    fecha_emision: fechaLocalISO(),
    dias_credito: 30,
    fecha_vencimiento: '',
    moneda: 'MXN' as Moneda,
    importe: '',
    tipo_cambio_emision: '',
    concepto: '',
  });
  const [guardandoFactura, setGuardandoFactura] = useState(false);

  // Diálogo Registrar Pago
  const [modalPagoOpen, setModalPagoOpen] = useState(false);
  const [facturaPago, setFacturaPago] = useState<any | null>(null);
  const [formPago, setFormPago] = useState({
    fecha_pago: fechaLocalISO(),
    monto: '',
    tipo_cambio: '',
    metodo_pago: 'Transferencia',
    referencia: '',
    complemento_pago: '',
    notas: '',
  });
  const [guardandoPago, setGuardandoPago] = useState(false);

  // Diálogo Anular Pago
  const [modalAnularOpen, setModalAnularOpen] = useState(false);
  const [pagoAnulando, setPagoAnulando] = useState<any | null>(null);
  const [motivoAnular, setMotivoAnular] = useState('');
  const [anulando, setAnulando] = useState(false);

  const toggleExpand = (id: string) => {
    setExpandidas((prev) => ({ ...prev, [id]: !prev[id] }));
  };

  // Filtrado en memoria
  const facturasFiltradas = useMemo(() => {
    return facturas.filter((f) => {
      if (proveedorFiltro && proveedorFiltro !== 'todos' && f.proveedor_id !== proveedorFiltro) {
        return false;
      }
      if (monedaFiltro && monedaFiltro !== 'todas' && f.moneda !== monedaFiltro) {
        return false;
      }
      if (estadoFiltro && estadoFiltro !== 'todas') {
        if (estadoFiltro === 'abierta' && !(f.estado_calculado === 'abierta' || f.estado_calculado === 'vencida')) return false;
        if (estadoFiltro === 'vencida' && f.estado_calculado !== 'vencida') return false;
        if (estadoFiltro === 'pagada' && f.estado_calculado !== 'pagada') return false;
        if (estadoFiltro === 'cancelada' && f.estado !== 'cancelada') return false;
      }
      if (soloVencidas && !(f.dias_atraso > 0 && f.saldo > 0 && f.estado !== 'cancelada')) {
        return false;
      }
      if (busqueda.trim()) {
        const q = busqueda.toLowerCase();
        const folioStr = `${f.sucursal || ''} ${f.folio || ''}`.toLowerCase();
        const provStr = (f.proveedor?.nombre || '').toLowerCase();
        const concStr = (f.concepto || '').toLowerCase();
        if (!folioStr.includes(q) && !provStr.includes(q) && !concStr.includes(q)) {
          return false;
        }
      }
      return true;
    });
  }, [facturas, proveedorFiltro, estadoFiltro, monedaFiltro, soloVencidas, busqueda]);

  // Manejo de cálculo de vencimiento en formulario factura
  const handleEmisionOrDiasChange = (nuevaEmision: string, nuevosDias: number) => {
    try {
      const [y, m, d] = nuevaEmision.split('-').map(Number);
      const fecha = new Date(y, m - 1, d);
      fecha.setDate(fecha.getDate() + Number(nuevosDias || 0));
      const vy = fecha.getFullYear();
      const vm = String(fecha.getMonth() + 1).padStart(2, '0');
      const vd = String(fecha.getDate()).padStart(2, '0');
      return `${vy}-${vm}-${vd}`;
    } catch {
      return nuevaEmision;
    }
  };

  const abrirNuevaFactura = () => {
    const emision = fechaLocalISO();
    const vencimiento = handleEmisionOrDiasChange(emision, 30);
    setFacturaEditando(null);
    setFormFactura({
      proveedor_id: proveedorFiltro && proveedorFiltro !== 'todos' ? proveedorFiltro : (proveedores[0]?.id || ''),
      sucursal: '',
      folio: '',
      nota: '',
      fecha_emision: emision,
      dias_credito: 30,
      fecha_vencimiento: vencimiento,
      moneda: 'MXN',
      importe: '',
      tipo_cambio_emision: '',
      concepto: '',
    });
    setModalFacturaOpen(true);
  };

  const abrirEditarFactura = (f: any) => {
    setFacturaEditando(f);
    setFormFactura({
      proveedor_id: f.proveedor_id,
      sucursal: f.sucursal || '',
      folio: f.folio || '',
      nota: f.nota || '',
      fecha_emision: f.fecha_emision || '',
      dias_credito: f.dias_credito ?? 30,
      fecha_vencimiento: f.fecha_vencimiento || '',
      moneda: f.moneda || 'MXN',
      importe: String(f.importe || ''),
      tipo_cambio_emision: f.tipo_cambio_emision ? String(f.tipo_cambio_emision) : '',
      concepto: f.concepto || '',
    });
    setModalFacturaOpen(true);
  };

  const handleSubmitFactura = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!formFactura.proveedor_id) {
      toast.error('Debe seleccionar un proveedor');
      return;
    }
    if (!formFactura.folio.trim()) {
      toast.error('El folio de la factura es obligatorio');
      return;
    }
    const impNum = parseFloat(formFactura.importe);
    if (isNaN(impNum) || impNum <= 0) {
      toast.error('El importe debe ser mayor a 0');
      return;
    }

    try {
      setGuardandoFactura(true);
      if (facturaEditando) {
        await onActualizarFactura(facturaEditando.id, {
          ...formFactura,
          importe: impNum,
          dias_credito: Number(formFactura.dias_credito),
          tipo_cambio_emision: formFactura.tipo_cambio_emision ? parseFloat(formFactura.tipo_cambio_emision) : null,
        });
        toast.success('Factura actualizada con éxito');
      } else {
        await onCrearFactura({
          ...formFactura,
          importe: impNum,
          dias_credito: Number(formFactura.dias_credito),
          tipo_cambio_emision: formFactura.tipo_cambio_emision ? parseFloat(formFactura.tipo_cambio_emision) : null,
        });
        toast.success('Factura registrada con éxito');
      }
      setModalFacturaOpen(false);
    } catch (err: any) {
      toast.error('Error al guardar factura', { description: err.message });
    } finally {
      setGuardandoFactura(false);
    }
  };

  const abrirRegistrarPago = (f: any) => {
    setFacturaPago(f);
    setFormPago({
      fecha_pago: fechaLocalISO(),
      monto: String(f.saldo || ''),
      tipo_cambio: f.moneda === 'USD' && tipoCambioActual ? String(tipoCambioActual) : '',
      metodo_pago: 'Transferencia',
      referencia: '',
      complemento_pago: '',
      notas: '',
    });
    setModalPagoOpen(true);
  };

  const handleSubmitPago = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!facturaPago) return;
    const montoNum = parseFloat(formPago.monto);
    if (isNaN(montoNum) || montoNum <= 0) {
      toast.error('El monto a pagar debe ser mayor a 0');
      return;
    }
    if (montoNum > facturaPago.saldo) {
      toast.error(`El monto ($${montoNum}) excede el saldo restante ($${facturaPago.saldo})`);
      return;
    }
    if (facturaPago.moneda === 'USD') {
      const tcNum = parseFloat(formPago.tipo_cambio);
      if (isNaN(tcNum) || tcNum <= 0) {
        toast.error('El tipo de cambio del pago en USD es obligatorio y debe ser mayor a 0');
        return;
      }
    }

    try {
      setGuardandoPago(true);
      await onRegistrarPago(facturaPago.id, {
        fecha_pago: formPago.fecha_pago,
        monto: montoNum,
        tipo_cambio: facturaPago.moneda === 'USD' ? parseFloat(formPago.tipo_cambio) : null,
        metodo_pago: formPago.metodo_pago,
        referencia: formPago.referencia,
        complemento_pago: formPago.complemento_pago,
        notas: formPago.notas,
      });
      toast.success('Pago registrado con éxito');
      setModalPagoOpen(false);
    } catch (err: any) {
      toast.error('Error al registrar pago', { description: err.message });
    } finally {
      setGuardandoPago(false);
    }
  };

  const abrirAnularPago = (p: any) => {
    setPagoAnulando(p);
    setMotivoAnular('');
    setModalAnularOpen(true);
  };

  const handleConfirmarAnular = async () => {
    if (!pagoAnulando) return;
    if (!motivoAnular.trim()) {
      toast.error('Debe indicar el motivo de anulación');
      return;
    }
    try {
      setAnulando(true);
      await onAnularPago(pagoAnulando.id, motivoAnular.trim());
      toast.success('Pago anulado con éxito. El saldo fue restaurado.');
      setModalAnularOpen(false);
    } catch (err: any) {
      toast.error('Error al anular pago', { description: err.message });
    } finally {
      setAnulando(false);
    }
  };

  const handleCancelarFacturaConfirm = async (f: any) => {
    const conf = confirm(`¿Está seguro de cancelar la factura ${f.folio}? Esta acción no se puede deshacer.`);
    if (!conf) return;
    try {
      await onCancelarFactura(f.id);
      toast.success(`Factura ${f.folio} cancelada`);
    } catch (err: any) {
      toast.error('Error al cancelar factura', { description: err.message });
    }
  };

  return (
    <div className="space-y-4">
      {/* Aviso de truncado a 500 registros */}
      {truncado && (
        <div className="p-3 rounded-md bg-amber-500/10 border border-amber-500/30 text-amber-600 text-xs flex items-center gap-2">
          <Clock className="h-4 w-4 shrink-0" />
          <span>Mostrando las primeras 500 facturas. Utilice los filtros de búsqueda o proveedor para acotar los resultados.</span>
        </div>
      )}

      {/* Barra de Filtros y Botón Nueva Factura */}
      <Card className="bg-card border-border/50">
        <CardContent className="p-4">
          <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4">
            <div className="flex flex-wrap items-center gap-2.5 flex-1">
              {/* Buscador */}
              <div className="relative min-w-[200px] flex-1 max-w-xs">
                <Search className="w-3.5 h-3.5 absolute left-2.5 top-1/2 -translate-y-1/2 text-muted-foreground" />
                <Input
                  type="text"
                  placeholder="Buscar folio, proveedor, concepto..."
                  value={busqueda}
                  onChange={(e) => setBusqueda(e.target.value)}
                  className="pl-8 text-xs h-9 bg-background"
                />
              </div>

              {/* Filtro Proveedor */}
              <Select value={proveedorFiltro} onValueChange={onCambiarProveedorFiltro}>
                <SelectTrigger className="w-[180px] text-xs h-9 bg-background">
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

              {/* Filtro Estado */}
              <Select value={estadoFiltro} onValueChange={setEstadoFiltro}>
                <SelectTrigger className="w-[130px] text-xs h-9 bg-background">
                  <SelectValue placeholder="Estado" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="todas">Todos los estados</SelectItem>
                  <SelectItem value="abierta">Abiertas</SelectItem>
                  <SelectItem value="vencida">Vencidas</SelectItem>
                  <SelectItem value="pagada">Pagadas</SelectItem>
                  <SelectItem value="cancelada">Canceladas</SelectItem>
                </SelectContent>
              </Select>

              {/* Filtro Moneda */}
              <Select value={monedaFiltro} onValueChange={setMonedaFiltro}>
                <SelectTrigger className="w-[110px] text-xs h-9 bg-background">
                  <SelectValue placeholder="Moneda" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="todas">Moneda: Todas</SelectItem>
                  <SelectItem value="MXN">Solo MXN</SelectItem>
                  <SelectItem value="USD">Solo USD</SelectItem>
                </SelectContent>
              </Select>

              {/* Checkbox Solo Vencidas */}
              <label className="flex items-center gap-1.5 text-xs text-foreground cursor-pointer select-none px-2 py-1 rounded border border-border/50 bg-background hover:bg-muted">
                <input
                  type="checkbox"
                  checked={soloVencidas}
                  onChange={(e) => setSoloVencidas(e.target.checked)}
                  className="rounded border-border text-primary focus:ring-primary w-3.5 h-3.5"
                />
                <span className="text-destructive font-medium">Solo vencidas</span>
              </label>
            </div>

            <Button
              type="button"
              onClick={abrirNuevaFactura}
              className="h-9 text-xs gap-1.5 bg-primary text-primary-foreground hover:bg-primary/90 shrink-0"
            >
              <Plus className="w-4 h-4" />
              Nueva Factura
            </Button>
          </div>
        </CardContent>
      </Card>

      {/* Tabla de Facturas */}
      <Card className="bg-card border-border/50 overflow-hidden">
        <CardHeader className="py-3 px-4 border-b border-border/50 bg-muted/20">
          <CardTitle className="text-xs font-semibold text-muted-foreground uppercase tracking-wider flex items-center justify-between">
            <span>Listado de Facturas ({facturasFiltradas.length})</span>
            {tipoCambioActual && (
              <span className="text-[11px] font-mono text-muted-foreground font-normal">
                TC Revaluación: ${tipoCambioActual.toFixed(4)}
              </span>
            )}
          </CardTitle>
        </CardHeader>
        <CardContent className="p-0">
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs border-collapse">
              <thead>
                <tr className="bg-muted/40 border-b border-border text-muted-foreground font-medium">
                  <th className="py-2.5 px-3 w-8"></th>
                  <th className="py-2.5 px-3">Folio / Sucursal</th>
                  <th className="py-2.5 px-3">Proveedor</th>
                  <th className="py-2.5 px-3">Emisión / Vence</th>
                  <th className="py-2.5 px-3 text-center">Atraso</th>
                  <th className="py-2.5 px-3 text-right">Importe</th>
                  <th className="py-2.5 px-3 text-right">Pagado</th>
                  <th className="py-2.5 px-3 text-right">Saldo</th>
                  <th className="py-2.5 px-3 text-right">Saldo MXN</th>
                  <th className="py-2.5 px-3 text-center">Estado</th>
                  <th className="py-2.5 px-3 text-right">Acciones</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border/50">
                {cargando ? (
                  <tr>
                    <td colSpan={11} className="py-8 text-center text-muted-foreground">
                      Cargando facturas...
                    </td>
                  </tr>
                ) : facturasFiltradas.length === 0 ? (
                  <tr>
                    <td colSpan={11} className="py-8 text-center text-muted-foreground">
                      No se encontraron facturas con los filtros aplicados.
                    </td>
                  </tr>
                ) : (
                  facturasFiltradas.map((f) => {
                    const esExpandida = !!expandidas[f.id];
                    const pagos = f.pagos || [];
                    const tienePagosActivos = pagos.some((p: any) => !p.anulado);
                    const saldoMXN = f.moneda === 'USD'
                      ? (tipoCambioActual ? f.saldo * tipoCambioActual : null)
                      : f.saldo;

                    let badgeEstadoClass = 'bg-muted text-muted-foreground border-border';
                    if (f.estado === 'cancelada') {
                      badgeEstadoClass = 'bg-destructive/10 text-destructive border-destructive/30';
                    } else if (f.estado_calculado === 'pagada') {
                      badgeEstadoClass = 'bg-emerald-500/10 text-emerald-600 border-emerald-500/30';
                    } else if (f.estado_calculado === 'vencida') {
                      badgeEstadoClass = 'bg-destructive/10 text-destructive border-destructive/30 font-semibold';
                    } else {
                      badgeEstadoClass = 'bg-primary/10 text-primary border-primary/30';
                    }

                    return (
                      <React.Fragment key={f.id}>
                        <tr className={`hover:bg-muted/20 transition-colors ${esExpandida ? 'bg-muted/10' : ''}`}>
                          <td className="py-3 px-2 text-center">
                            {pagos.length > 0 && (
                              <button
                                type="button"
                                onClick={() => toggleExpand(f.id)}
                                className="p-1 text-muted-foreground hover:text-foreground rounded"
                                title="Ver pagos"
                              >
                                {esExpandida ? (
                                  <ChevronDown className="w-3.5 h-3.5" />
                                ) : (
                                  <ChevronRight className="w-3.5 h-3.5" />
                                )}
                              </button>
                            )}
                          </td>
                          <td className="py-3 px-3">
                            <div className="font-semibold text-foreground flex items-center gap-1.5 font-mono">
                              <span>{f.folio}</span>
                              <span className="text-[10px] px-1 py-0.2 rounded bg-muted text-muted-foreground font-normal">
                                {f.moneda}
                              </span>
                            </div>
                            {f.sucursal && (
                              <div className="text-[11px] text-muted-foreground">{f.sucursal}</div>
                            )}
                            {f.concepto && (
                              <div className="text-[11px] text-muted-foreground truncate max-w-xs">{f.concepto}</div>
                            )}
                          </td>
                          <td className="py-3 px-3">
                            <div className="font-medium text-foreground">{f.proveedor?.nombre || 'N/A'}</div>
                            {f.proveedor?.razon_social && f.proveedor.razon_social !== f.proveedor.nombre && (
                              <div className="text-[10px] text-muted-foreground truncate max-w-xs">{f.proveedor.razon_social}</div>
                            )}
                          </td>
                          <td className="py-3 px-3 font-mono text-[11px]">
                            <div>Emi: {f.fecha_emision}</div>
                            <div className="text-muted-foreground">Ven: {f.fecha_vencimiento}</div>
                          </td>
                          <td className="py-3 px-3 text-center">
                            {f.estado !== 'cancelada' && f.saldo > 0 ? (
                              f.dias_atraso > 0 ? (
                                <span className={`px-2 py-0.5 rounded text-[10px] font-mono font-semibold ${
                                  f.dias_atraso > 60
                                    ? 'bg-destructive/10 text-destructive'
                                    : 'bg-amber-500/10 text-amber-600'
                                }`}>
                                  +{f.dias_atraso}d
                                </span>
                              ) : (
                                <span className="px-1.5 py-0.5 rounded text-[10px] font-mono text-muted-foreground bg-muted">
                                  {f.dias_atraso === 0 ? 'Hoy' : `${Math.abs(f.dias_atraso)}d`}
                                </span>
                              )
                            ) : (
                              <span className="text-muted-foreground">--</span>
                            )}
                          </td>
                          <td className="py-3 px-3 text-right font-mono font-medium text-foreground">
                            {formatearMonedaDe(f.importe, f.moneda)}
                          </td>
                          <td className="py-3 px-3 text-right font-mono text-muted-foreground">
                            {f.pagado > 0 ? formatearMonedaDe(f.pagado, f.moneda) : '--'}
                          </td>
                          <td className="py-3 px-3 text-right font-mono font-bold text-foreground">
                            {formatearMonedaDe(f.saldo, f.moneda)}
                          </td>
                          <td className="py-3 px-3 text-right font-mono text-foreground">
                            {saldoMXN !== null ? (
                              <span>{formatearMonedaDe(saldoMXN, 'MXN')}</span>
                            ) : (
                              <span className="text-amber-600 text-[11px]">Falta TC</span>
                            )}
                          </td>
                          <td className="py-3 px-3 text-center">
                            <span className={`px-2 py-0.5 rounded-full text-[10px] font-medium border uppercase tracking-wider ${badgeEstadoClass}`}>
                              {f.estado_calculado || f.estado}
                            </span>
                          </td>
                          <td className="py-3 px-3 text-right">
                            <div className="flex items-center justify-end gap-1">
                              {f.estado !== 'cancelada' && f.saldo > 0 && (
                                <Button
                                  variant="outline"
                                  size="sm"
                                  onClick={() => abrirRegistrarPago(f)}
                                  className="h-7 px-2 text-xs text-primary border-primary/30 hover:bg-primary/10 gap-1"
                                >
                                  <DollarSign className="w-3 h-3" />
                                  Pagar
                                </Button>
                              )}
                              {f.estado !== 'cancelada' && (
                                <Button
                                  variant="ghost"
                                  size="sm"
                                  onClick={() => abrirEditarFactura(f)}
                                  className="h-7 w-7 p-0 text-muted-foreground hover:text-foreground"
                                  title="Editar factura"
                                >
                                  <Edit2 className="w-3.5 h-3.5" />
                                </Button>
                              )}
                              {f.estado !== 'cancelada' && (
                                <Button
                                  variant="ghost"
                                  size="sm"
                                  onClick={() => handleCancelarFacturaConfirm(f)}
                                  className="h-7 w-7 p-0 text-muted-foreground hover:text-destructive"
                                  title="Cancelar factura"
                                >
                                  <XCircle className="w-3.5 h-3.5" />
                                </Button>
                              )}
                            </div>
                          </td>
                        </tr>

                        {/* Fila expandible con pagos */}
                        {esExpandida && (
                          <tr className="bg-muted/15 border-b border-border/40">
                            <td colSpan={11} className="py-3 px-8">
                              <div className="space-y-2">
                                <div className="text-[11px] font-semibold text-muted-foreground uppercase tracking-wider flex items-center justify-between">
                                  <span>Historial de Pagos de la Factura ({pagos.length})</span>
                                  {f.moneda === 'USD' && (
                                    <span className="text-[10px] text-muted-foreground font-normal">
                                      Los pagos en USD registran el tipo de cambio del momento del pago
                                    </span>
                                  )}
                                </div>
                                <div className="rounded border border-border/50 bg-card overflow-hidden">
                                  <table className="w-full text-left text-[11px]">
                                    <thead>
                                      <tr className="bg-muted/30 border-b border-border/50 text-muted-foreground">
                                        <th className="py-1.5 px-3">Fecha de Pago</th>
                                        <th className="py-1.5 px-3 text-right">Monto</th>
                                        {f.moneda === 'USD' && <th className="py-1.5 px-3 text-right">TC Pago</th>}
                                        {f.moneda === 'USD' && <th className="py-1.5 px-3 text-right">Equivalente MXN</th>}
                                        <th className="py-1.5 px-3">Método</th>
                                        <th className="py-1.5 px-3">Referencia</th>
                                        <th className="py-1.5 px-3">Complemento (REP)</th>
                                        <th className="py-1.5 px-3 text-center">Estado</th>
                                        <th className="py-1.5 px-3 text-right">Acción</th>
                                      </tr>
                                    </thead>
                                    <tbody className="divide-y divide-border/40 font-mono">
                                      {pagos.map((p: any) => (
                                        <tr key={p.id} className={p.anulado ? 'opacity-50 line-through bg-destructive/5' : ''}>
                                          <td className="py-1.5 px-3">{p.fecha_pago}</td>
                                          <td className="py-1.5 px-3 text-right font-bold">
                                            {formatearMonedaDe(p.monto, f.moneda)}
                                          </td>
                                          {f.moneda === 'USD' && (
                                            <td className="py-1.5 px-3 text-right">
                                              {p.tipo_cambio ? `$${Number(p.tipo_cambio).toFixed(4)}` : '--'}
                                            </td>
                                          )}
                                          {f.moneda === 'USD' && (
                                            <td className="py-1.5 px-3 text-right text-muted-foreground">
                                              {p.tipo_cambio ? formatearMonedaDe(p.monto * p.tipo_cambio, 'MXN') : '--'}
                                            </td>
                                          )}
                                          <td className="py-1.5 px-3 font-sans">{p.metodo_pago}</td>
                                          <td className="py-1.5 px-3">{p.referencia || '--'}</td>
                                          <td className="py-1.5 px-3">{p.complemento_pago || '--'}</td>
                                          <td className="py-1.5 px-3 text-center font-sans">
                                            {p.anulado ? (
                                              <span className="text-[10px] text-destructive bg-destructive/10 px-1.5 py-0.2 rounded" title={p.anulado_motivo}>
                                                Anulado
                                              </span>
                                            ) : (
                                              <span className="text-[10px] text-emerald-600 bg-emerald-500/10 px-1.5 py-0.2 rounded">
                                                Activo
                                              </span>
                                            )}
                                          </td>
                                          <td className="py-1.5 px-3 text-right font-sans">
                                            {!p.anulado && (
                                              <Button
                                                variant="ghost"
                                                size="sm"
                                                onClick={() => abrirAnularPago(p)}
                                                className="h-6 px-1.5 text-[10px] text-destructive hover:bg-destructive/10"
                                              >
                                                Anular
                                              </Button>
                                            )}
                                          </td>
                                        </tr>
                                      ))}
                                    </tbody>
                                  </table>
                                </div>
                              </div>
                            </td>
                          </tr>
                        )}
                      </React.Fragment>
                    );
                  })
                )}
              </tbody>
            </table>
          </div>
        </CardContent>
      </Card>

      {/* DIÁLOGO: NUEVA / EDITAR FACTURA */}
      <Dialog open={modalFacturaOpen} onOpenChange={setModalFacturaOpen}>
        <DialogContent className="sm:max-w-lg">
          <DialogHeader>
            <DialogTitle className="text-base font-semibold">
              {facturaEditando ? 'Editar Factura de Proveedor' : 'Registrar Nueva Factura'}
            </DialogTitle>
            <DialogDescription className="text-xs text-muted-foreground">
              {facturaEditando
                ? 'Modifique los campos permitidos. Si la factura ya tiene pagos registrados, la moneda y el importe no se pueden cambiar.'
                : 'Capture los datos fiscales y comerciales de la factura emitida por el proveedor.'}
            </DialogDescription>
          </DialogHeader>

          <form onSubmit={handleSubmitFactura} className="space-y-4 py-2">
            <div className="grid grid-cols-2 gap-3">
              <div className="space-y-1 col-span-2">
                <Label className="text-xs">Proveedor *</Label>
                <Select
                  value={formFactura.proveedor_id}
                  onValueChange={(val) => setFormFactura({ ...formFactura, proveedor_id: val })}
                  disabled={facturaEditando && facturaEditando.pagos?.some((p: any) => !p.anulado)}
                >
                  <SelectTrigger className="text-xs h-9 bg-background">
                    <SelectValue placeholder="Seleccione proveedor" />
                  </SelectTrigger>
                  <SelectContent>
                    {proveedores.map((p) => (
                      <SelectItem key={p.id} value={p.id}>
                        {p.nombre} {p.razon_social ? `(${p.razon_social})` : ''}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>

              <div className="space-y-1">
                <Label className="text-xs">Folio de Factura *</Label>
                <Input
                  type="text"
                  required
                  placeholder="Ej. 21644"
                  value={formFactura.folio}
                  onChange={(e) => setFormFactura({ ...formFactura, folio: e.target.value })}
                  className="text-xs h-9 font-mono"
                />
              </div>

              <div className="space-y-1">
                <Label className="text-xs">Sucursal (Opcional)</Label>
                <Input
                  type="text"
                  placeholder="Ej. Suc 114"
                  value={formFactura.sucursal}
                  onChange={(e) => setFormFactura({ ...formFactura, sucursal: e.target.value })}
                  className="text-xs h-9 font-mono"
                />
              </div>

              <div className="space-y-1">
                <Label className="text-xs">Fecha de Emisión *</Label>
                <Input
                  type="date"
                  required
                  value={formFactura.fecha_emision}
                  onChange={(e) => {
                    const emi = e.target.value;
                    const ven = handleEmisionOrDiasChange(emi, formFactura.dias_credito);
                    setFormFactura({ ...formFactura, fecha_emision: emi, fecha_vencimiento: ven });
                  }}
                  className="text-xs h-9 font-mono"
                />
              </div>

              <div className="space-y-1">
                <Label className="text-xs">Días de Crédito *</Label>
                <Input
                  type="number"
                  min="0"
                  required
                  value={formFactura.dias_credito}
                  onChange={(e) => {
                    const dias = parseInt(e.target.value, 10) || 0;
                    const ven = handleEmisionOrDiasChange(formFactura.fecha_emision, dias);
                    setFormFactura({ ...formFactura, dias_credito: dias, fecha_vencimiento: ven });
                  }}
                  className="text-xs h-9 font-mono"
                />
              </div>

              <div className="space-y-1">
                <Label className="text-xs">Fecha de Vencimiento *</Label>
                <Input
                  type="date"
                  required
                  value={formFactura.fecha_vencimiento}
                  onChange={(e) => setFormFactura({ ...formFactura, fecha_vencimiento: e.target.value })}
                  className="text-xs h-9 font-mono"
                />
              </div>

              <div className="space-y-1">
                <Label className="text-xs">Moneda *</Label>
                <Select
                  value={formFactura.moneda}
                  onValueChange={(val: Moneda) => setFormFactura({ ...formFactura, moneda: val })}
                  disabled={facturaEditando && facturaEditando.pagos?.some((p: any) => !p.anulado)}
                >
                  <SelectTrigger className="text-xs h-9 bg-background font-mono">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="MXN">MXN (Pesos)</SelectItem>
                    <SelectItem value="USD">USD (Dólares)</SelectItem>
                  </SelectContent>
                </Select>
              </div>

              <div className="space-y-1 col-span-2">
                <Label className="text-xs">Importe Total con IVA *</Label>
                <Input
                  type="number"
                  step="0.01"
                  min="0.01"
                  required
                  placeholder="0.00"
                  value={formFactura.importe}
                  onChange={(e) => setFormFactura({ ...formFactura, importe: e.target.value })}
                  disabled={facturaEditando && facturaEditando.pagos?.some((p: any) => !p.anulado)}
                  className="text-sm h-9 font-mono"
                />
              </div>

              {formFactura.moneda === 'USD' && (
                <div className="space-y-1 col-span-2">
                  <Label className="text-xs">Tipo de Cambio de Emisión (Informativo)</Label>
                  <Input
                    type="number"
                    step="0.0001"
                    placeholder="Ej. 19.50"
                    value={formFactura.tipo_cambio_emision}
                    onChange={(e) => setFormFactura({ ...formFactura, tipo_cambio_emision: e.target.value })}
                    className="text-xs h-9 font-mono"
                  />
                </div>
              )}

              <div className="space-y-1 col-span-2">
                <Label className="text-xs">Concepto / Materiales</Label>
                <Input
                  type="text"
                  placeholder="Ej. Llantas 11R22.5, Refacciones..."
                  value={formFactura.concepto}
                  onChange={(e) => setFormFactura({ ...formFactura, concepto: e.target.value })}
                  className="text-xs h-9"
                />
              </div>

              <div className="space-y-1 col-span-2">
                <Label className="text-xs">Nota interna</Label>
                <Input
                  type="text"
                  placeholder="Observaciones de almacén o crédito..."
                  value={formFactura.nota}
                  onChange={(e) => setFormFactura({ ...formFactura, nota: e.target.value })}
                  className="text-xs h-9"
                />
              </div>
            </div>

            <DialogFooter className="pt-2">
              <Button
                type="button"
                variant="outline"
                size="sm"
                onClick={() => setModalFacturaOpen(false)}
                className="text-xs"
              >
                Cancelar
              </Button>
              <Button
                type="submit"
                size="sm"
                disabled={guardandoFactura}
                className="text-xs bg-primary text-primary-foreground hover:bg-primary/90"
              >
                {guardandoFactura ? 'Guardando...' : facturaEditando ? 'Actualizar Factura' : 'Guardar Factura'}
              </Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>

      {/* DIÁLOGO: REGISTRAR PAGO */}
      <Dialog open={modalPagoOpen} onOpenChange={setModalPagoOpen}>
        <DialogContent className="sm:max-w-md">
          <DialogHeader>
            <DialogTitle className="text-base font-semibold">
              Registrar Abono / Pago a Factura
            </DialogTitle>
            <DialogDescription className="text-xs text-muted-foreground">
              {facturaPago && (
                <span>
                  Factura {facturaPago.folio} ({facturaPago.moneda}) — Saldo actual:{' '}
                  <strong className="font-mono text-foreground font-bold">
                    {formatearMonedaDe(facturaPago.saldo, facturaPago.moneda)}
                  </strong>
                </span>
              )}
            </DialogDescription>
          </DialogHeader>

          <form onSubmit={handleSubmitPago} className="space-y-3.5 py-2">
            <div className="space-y-1">
              <Label className="text-xs">Fecha del Pago *</Label>
              <Input
                type="date"
                required
                value={formPago.fecha_pago}
                onChange={(e) => setFormPago({ ...formPago, fecha_pago: e.target.value })}
                className="text-xs h-9 font-mono"
              />
            </div>

            <div className="space-y-1">
              <Label className="text-xs">Monto a Pagar ({facturaPago?.moneda}) *</Label>
              <Input
                type="number"
                step="0.01"
                min="0.01"
                max={facturaPago?.saldo}
                required
                value={formPago.monto}
                onChange={(e) => setFormPago({ ...formPago, monto: e.target.value })}
                className="text-sm h-9 font-mono font-bold"
              />
            </div>

            {facturaPago?.moneda === 'USD' && (
              <div className="space-y-1">
                <Label className="text-xs font-semibold text-primary">
                  Tipo de Cambio del Pago (USD / MXN) *
                </Label>
                <Input
                  type="number"
                  step="0.0001"
                  min="0.0001"
                  required
                  placeholder="Ej. 19.50"
                  value={formPago.tipo_cambio}
                  onChange={(e) => setFormPago({ ...formPago, tipo_cambio: e.target.value })}
                  className="text-xs h-9 font-mono"
                />
                {formPago.tipo_cambio && formPago.monto && (
                  <p className="text-[11px] text-muted-foreground font-mono">
                    Equivalente en pesos: ${Number(parseFloat(formPago.monto) * parseFloat(formPago.tipo_cambio)).toFixed(2)} MXN
                  </p>
                )}
              </div>
            )}

            <div className="space-y-1">
              <Label className="text-xs">Método de Pago *</Label>
              <Select
                value={formPago.metodo_pago}
                onValueChange={(val) => setFormPago({ ...formPago, metodo_pago: val })}
              >
                <SelectTrigger className="text-xs h-9 bg-background">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="Transferencia">Transferencia Electrónica</SelectItem>
                  <SelectItem value="Cheque">Cheque</SelectItem>
                  <SelectItem value="Efectivo">Efectivo</SelectItem>
                  <SelectItem value="Tarjeta">Tarjeta Bancaria</SelectItem>
                  <SelectItem value="Compensacion">Compensación / Nota de Crédito</SelectItem>
                </SelectContent>
              </Select>
            </div>

            <div className="grid grid-cols-2 gap-2">
              <div className="space-y-1">
                <Label className="text-xs">Referencia / Rastreo</Label>
                <Input
                  type="text"
                  placeholder="Ej. SPEI 88219"
                  value={formPago.referencia}
                  onChange={(e) => setFormPago({ ...formPago, referencia: e.target.value })}
                  className="text-xs h-9"
                />
              </div>

              <div className="space-y-1">
                <Label className="text-xs">Folio REP / Complemento</Label>
                <Input
                  type="text"
                  placeholder="Ej. CP-99201"
                  value={formPago.complemento_pago}
                  onChange={(e) => setFormPago({ ...formPago, complemento_pago: e.target.value })}
                  className="text-xs h-9 font-mono"
                />
              </div>
            </div>

            <div className="space-y-1">
              <Label className="text-xs">Notas</Label>
              <Input
                type="text"
                placeholder="Observaciones..."
                value={formPago.notas}
                onChange={(e) => setFormPago({ ...formPago, notas: e.target.value })}
                className="text-xs h-9"
              />
            </div>

            <DialogFooter className="pt-2">
              <Button
                type="button"
                variant="outline"
                size="sm"
                onClick={() => setModalPagoOpen(false)}
                className="text-xs"
              >
                Cancelar
              </Button>
              <Button
                type="submit"
                size="sm"
                disabled={guardandoPago}
                className="text-xs bg-primary text-primary-foreground hover:bg-primary/90"
              >
                {guardandoPago ? 'Aplicando...' : 'Aplicar Abono'}
              </Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>

      {/* DIÁLOGO: ANULAR PAGO */}
      <Dialog open={modalAnularOpen} onOpenChange={setModalAnularOpen}>
        <DialogContent className="sm:max-w-md">
          <DialogHeader>
            <DialogTitle className="text-base font-semibold text-destructive flex items-center gap-2">
              <Ban className="w-4 h-4" />
              Anular Pago
            </DialogTitle>
            <DialogDescription className="text-xs text-muted-foreground">
              {pagoAnulando && (
                <span>
                  Se anulará el pago por{' '}
                  <strong className="font-mono text-foreground font-bold">
                    ${Number(pagoAnulando.monto).toLocaleString('es-MX', { minimumFractionDigits: 2 })}
                  </strong>{' '}
                  del día {pagoAnulando.fecha_pago}. El saldo de la factura será restaurado.
                </span>
              )}
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-3 py-2">
            <div className="space-y-1">
              <Label className="text-xs font-semibold">Motivo de Anulación *</Label>
              <Input
                type="text"
                required
                placeholder="Ej. Cheque rebotado, error en captura, pago duplicado..."
                value={motivoAnular}
                onChange={(e) => setMotivoAnular(e.target.value)}
                className="text-xs h-9"
              />
            </div>
          </div>

          <DialogFooter className="pt-2">
            <Button
              type="button"
              variant="outline"
              size="sm"
              onClick={() => setModalAnularOpen(false)}
              className="text-xs"
            >
              Cancelar
            </Button>
            <Button
              type="button"
              variant="destructive"
              size="sm"
              disabled={anulando || !motivoAnular.trim()}
              onClick={handleConfirmarAnular}
              className="text-xs gap-1"
            >
              {anulando ? 'Anulando...' : 'Confirmar Anulación'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
