import { useState, useMemo } from 'react';
import { Link } from 'react-router-dom';
import { Card, CardContent, CardHeader, CardTitle } from '../ui/card';
import { Button } from '../ui/button';
import { Input } from '../ui/input';
import { Label } from '../ui/label';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from '../ui/dialog';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../ui/select';
import { DollarSign, AlertTriangle, Calendar, FileText, CheckCircle, ExternalLink } from 'lucide-react';
import { Cotizacion, Pago, Cliente } from '../../types';
import { formatearMoneda } from '../../utils/calculations';
import { saldoCotizacion, traducirErrorCobros } from '../../utils/cobros';

interface CuentasPorCobrarProps {
  cotizaciones: Cotizacion[];
  pagos: Pago[];
  clientes: Cliente[];
  loading: boolean;
  onCrearPago: (pago: Omit<Pago, 'id'>) => Promise<void>;
}

export function CuentasPorCobrar({ cotizaciones, pagos, clientes, loading, onCrearPago }: CuentasPorCobrarProps) {
  const [modalOpen, setModalOpen] = useState(false);
  const [cotizacionSeleccionada, setCotizacionSeleccionada] = useState<Cotizacion | null>(null);
  const [formData, setFormData] = useState({
    monto: 0,
    metodo_pago: 'Transferencia',
    referencia: '',
    descripcion_especie: '',
  });
  const [guardando, setGuardando] = useState(false);
  const [errorModal, setErrorModal] = useState<string | null>(null);

  const cuentas = useMemo(() => {
    const activas = cotizaciones.filter(c =>
      c.estado !== 'Borrador' && c.estado !== 'Cancelada' && c.estado !== 'Rechazada'
    );

    return activas.map(cot => {
      const pagosCot = pagos.filter(p => p.cotizacion_id === cot.id);
      const { cobrado: totalPagado, saldo: saldoPendiente } = saldoCotizacion(cot.total, pagosCot);
      const cliente = clientes.find(c => c.id === cot.cliente_id);

      return {
        ...cot,
        cliente_nombre: cliente?.nombre_razon_social || 'Desconocido',
        totalPagado,
        saldoPendiente,
        pagadoCompleto: saldoPendiente <= 0
      };
    }).filter(c => c.saldoPendiente > 0)
      .sort((a, b) => new Date(a.fecha).getTime() - new Date(b.fecha).getTime());
  }, [cotizaciones, pagos, clientes]);

  const totalPorCobrar = cuentas.reduce((sum, c) => sum + c.saldoPendiente, 0);

  const handleCobrar = (c: any) => {
    setCotizacionSeleccionada(c);
    setFormData({
      monto: c.saldoPendiente,
      metodo_pago: 'Transferencia',
      referencia: '',
      descripcion_especie: '',
    });
    setErrorModal(null);
    setModalOpen(true);
  };

  const confirmarCobro = async () => {
    if (!cotizacionSeleccionada || formData.monto <= 0 || guardando) return;
    if (formData.metodo_pago === 'Especie' && !formData.descripcion_especie.trim()) {
      setErrorModal('Describe el bien o servicio recibido en especie.');
      return;
    }
    setErrorModal(null);
    setGuardando(true);
    try {
      await onCrearPago({
        cotizacion_id: cotizacionSeleccionada.id,
        monto: formData.monto,
        tipo_pago: formData.metodo_pago as any,
        referencia: formData.referencia,
        descripcion_especie: formData.metodo_pago === 'Especie' ? formData.descripcion_especie.trim() : null,
        fecha: new Date().toISOString().slice(0, 10)
      });
      setModalOpen(false);
    } catch (e) {
      setErrorModal(traducirErrorCobros(e));
    } finally {
      setGuardando(false);
    }
  };

  if (loading) return <div className="animate-pulse h-64 bg-card/50 rounded-xl"></div>;

  return (
    <div className="space-y-6 text-foreground bg-background min-h-screen pb-20">
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-3xl font-bold font-sans">Cuentas por Cobrar</h1>
          <p className="text-muted-foreground mt-1">Saldos pendientes de clientes por órdenes de compra.</p>
        </div>
      </div>

      <div className="grid gap-4 md:grid-cols-3">
        <Card className="bg-card/50 border-border/50">
          <CardHeader className="pb-2 flex flex-row items-center justify-between">
            <CardTitle className="text-lg text-foreground font-mono tracking-wide">Total por Cobrar</CardTitle>
            <DollarSign className="text-accent-blue w-5 h-5" />
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold font-mono text-foreground">{formatearMoneda(totalPorCobrar)}</div>
            <p className="text-xs text-muted-foreground mt-1">En {cuentas.length} órdenes pendientes</p>
          </CardContent>
        </Card>
      </div>

      {cuentas.length === 0 ? (
        <div className="text-center py-20 bg-card/50 rounded-xl border border-border/50">
          <CheckCircle className="mx-auto h-12 w-12 text-accent-green mb-4" />
          <h3 className="text-lg font-medium text-foreground mb-2">Todo al día</h3>
          <p className="text-muted-foreground">No hay saldos pendientes por cobrar.</p>
        </div>
      ) : (
        <div className="rounded-xl border border-border/50 bg-card/50 overflow-hidden">
          {cuentas.map((c, i) => (
            <div key={c.id} className="p-4 flex flex-col md:flex-row md:items-center justify-between group gap-4" style={{ borderTop: i ? '1px solid rgba(255,255,255,0.06)' : 'none' }}>
              <div className="flex flex-col gap-1">
                <div className="flex items-center gap-2">
                  <span className="font-mono text-sm bg-white/10 px-2 py-0.5 rounded text-foreground">{c.folio}</span>
                  <span className="text-sm font-medium text-foreground">{c.cliente_nombre}</span>
                </div>
                <div className="text-xs text-muted-foreground mt-1 flex items-center gap-3">
                  <span className="flex items-center"><Calendar className="w-3 h-3 mr-1" /> {new Date(c.fecha).toLocaleDateString()}</span>
                  <span className="flex items-center"><FileText className="w-3 h-3 mr-1" /> Total: {formatearMoneda(c.total)}</span>
                </div>
              </div>
              <div className="flex items-center justify-between md:justify-end gap-6 w-full md:w-auto">
                <div className="text-right">
                  <div className="text-xs text-muted-foreground">Saldo Pendiente</div>
                  <div className="font-mono font-bold text-accent-red text-lg">{formatearMoneda(c.saldoPendiente)}</div>
                </div>
                <div className="flex items-center gap-2">
                  <Button variant="outline" size="sm" asChild>
                    <Link to={`/cotizaciones/${c.id}`}>
                      <ExternalLink className="w-3.5 h-3.5 mr-1" /> Ver
                    </Link>
                  </Button>
                  <Button onClick={() => handleCobrar(c)} className="bg-accent-blue text-white hover:bg-accent-blue/90">
                    <DollarSign className="w-4 h-4 mr-2" /> Registrar Cobro
                  </Button>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Modal Cobro */}
      <Dialog open={modalOpen} onOpenChange={setModalOpen}>
        <DialogContent className="bg-background border-border">
          <DialogHeader>
            <DialogTitle>Registrar Cobro</DialogTitle>
          </DialogHeader>
          <div className="grid gap-4 py-4">
            <div className="text-sm text-muted-foreground mb-2">
              Folio: <span className="font-mono text-foreground">{cotizacionSeleccionada?.folio}</span><br/>
              Saldo actual: <span className="font-mono text-foreground">{formatearMoneda(cotizacionSeleccionada?.saldoPendiente || 0)}</span>
            </div>
            <div className="space-y-2">
              <Label>Monto a Cobrar</Label>
              <Input type="number" value={formData.monto} onChange={e => setFormData({...formData, monto: Number(e.target.value)})} max={cotizacionSeleccionada?.saldoPendiente || 0} />
            </div>
            <div className="space-y-2">
              <Label>Método de Pago</Label>
              <Select value={formData.metodo_pago} onValueChange={v => setFormData({...formData, metodo_pago: v})}>
                <SelectTrigger><SelectValue /></SelectTrigger>
                <SelectContent>
                  <SelectItem value="Transferencia">Transferencia</SelectItem>
                  <SelectItem value="Tarjeta">Tarjeta</SelectItem>
                  <SelectItem value="Efectivo">Efectivo</SelectItem>
                  <SelectItem value="Cheque">Cheque</SelectItem>
                  <SelectItem value="Especie">Especie</SelectItem>
                </SelectContent>
              </Select>
            </div>
            {formData.metodo_pago === 'Especie' && (
              <div className="space-y-2">
                <Label>Descripción en especie *</Label>
                <Input
                  value={formData.descripcion_especie}
                  onChange={e => setFormData({ ...formData, descripcion_especie: e.target.value })}
                  placeholder="Describe el bien o servicio recibido..."
                />
              </div>
            )}
            <div className="space-y-2">
              <Label>Referencia</Label>
              <Input value={formData.referencia} onChange={e => setFormData({...formData, referencia: e.target.value})} placeholder="Folio de transferencia..." />
            </div>
            {errorModal && (
              <div className="rounded-md border border-destructive/40 bg-destructive/10 p-2.5 text-sm text-destructive flex items-center gap-2">
                <AlertTriangle className="w-4 h-4 shrink-0" />
                <span>{errorModal}</span>
              </div>
            )}
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setModalOpen(false)} disabled={guardando}>Cancelar</Button>
            <Button onClick={confirmarCobro} disabled={guardando}>
              {guardando ? 'Registrando...' : 'Confirmar Cobro'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
