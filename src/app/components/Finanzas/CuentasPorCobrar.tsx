import { useState, useMemo } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '../ui/card';
import { Button } from '../ui/button';
import { Badge } from '../ui/badge';
import { Input } from '../ui/input';
import { Label } from '../ui/label';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from '../ui/dialog';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../ui/select';
import { DollarSign, AlertTriangle, Calendar, FileText, CheckCircle } from 'lucide-react';
import { Cotizacion, Pago, Cliente } from '../../types';
import { formatearMoneda } from '../../utils/calculations';

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
  });

  const cuentas = useMemo(() => {
    // Solo consideramos cotizaciones aprobadas, entregadas (que no sean borradores o canceladas)
    const activas = cotizaciones.filter(c => 
      c.estado !== 'Borrador' && c.estado !== 'Cancelada' && c.estado !== 'Rechazada'
    );

    return activas.map(cot => {
      const pagosCot = pagos.filter(p => p.cotizacion_id === cot.id);
      const totalPagado = pagosCot.reduce((sum, p) => sum + p.monto, 0);
      const saldoPendiente = cot.total - totalPagado;
      const cliente = clientes.find(c => c.id === cot.cliente_id);

      return {
        ...cot,
        cliente_nombre: cliente?.nombre_razon_social || 'Desconocido',
        totalPagado,
        saldoPendiente,
        pagadoCompleto: saldoPendiente <= 0
      };
    }).filter(c => c.saldoPendiente > 0) // Solo mostramos las que tienen saldo
      .sort((a, b) => new Date(a.fecha).getTime() - new Date(b.fecha).getTime()); // Las más antiguas primero
  }, [cotizaciones, pagos, clientes]);

  const totalPorCobrar = cuentas.reduce((sum, c) => sum + c.saldoPendiente, 0);

  const handleCobrar = (c: any) => {
    setCotizacionSeleccionada(c);
    setFormData({
      monto: c.saldoPendiente, // Por defecto todo el saldo
      metodo_pago: 'Transferencia',
      referencia: ''
    });
    setModalOpen(true);
  };

  const confirmarCobro = async () => {
    if (!cotizacionSeleccionada || formData.monto <= 0) return;
    try {
      await onCrearPago({
        cotizacion_id: cotizacionSeleccionada.id,
        monto: formData.monto,
        tipo_pago: formData.metodo_pago as any,
        referencia: formData.referencia,
        fecha: new Date().toISOString()
      });
      setModalOpen(false);
    } catch (e) {
      console.error(e);
    }
  };

  if (loading) return <div className="animate-pulse h-64 bg-white/[0.02] rounded-xl"></div>;

  return (
    <div className="space-y-6 text-foreground bg-background min-h-screen pb-20">
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-3xl font-bold font-sans">Cuentas por Cobrar</h1>
          <p className="text-muted-foreground mt-1">Saldos pendientes de clientes por órdenes de compra.</p>
        </div>
      </div>

      <div className="grid gap-4 md:grid-cols-3">
        <Card className="bg-white/[0.02] border-white/[0.06]">
          <CardHeader className="pb-2 flex flex-row items-center justify-between">
            <CardTitle className="text-lg text-white font-mono tracking-wide">Total por Cobrar</CardTitle>
            <DollarSign className="text-accent-blue w-5 h-5" />
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold font-mono text-white">{formatearMoneda(totalPorCobrar)}</div>
            <p className="text-xs text-muted-foreground mt-1">En {cuentas.length} órdenes pendientes</p>
          </CardContent>
        </Card>
      </div>

      {cuentas.length === 0 ? (
        <div className="text-center py-20 bg-white/[0.02] rounded-xl border border-white/[0.06]">
          <CheckCircle className="mx-auto h-12 w-12 text-accent-green mb-4" />
          <h3 className="text-lg font-medium text-white mb-2">Todo al día</h3>
          <p className="text-muted-foreground">No hay saldos pendientes por cobrar.</p>
        </div>
      ) : (
        <div className="rounded-xl border border-white/[0.06] bg-white/[0.02] overflow-hidden">
          {cuentas.map((c, i) => (
            <div key={c.id} className="p-4 flex flex-col md:flex-row md:items-center justify-between group gap-4" style={{ borderTop: i ? '1px solid rgba(255,255,255,0.06)' : 'none' }}>
              <div className="flex flex-col gap-1">
                <div className="flex items-center gap-2">
                  <span className="font-mono text-sm bg-white/10 px-2 py-0.5 rounded text-white">{c.folio}</span>
                  <span className="text-sm font-medium text-white">{c.cliente_nombre}</span>
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
                <Button onClick={() => handleCobrar(c)} className="bg-accent-blue text-white hover:bg-accent-blue/90">
                  <DollarSign className="w-4 h-4 mr-2" /> Registrar Cobro
                </Button>
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
              Folio: <span className="font-mono text-white">{cotizacionSeleccionada?.folio}</span><br/>
              Saldo actual: <span className="font-mono text-white">{formatearMoneda(cotizacionSeleccionada?.saldoPendiente || 0)}</span>
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
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-2">
              <Label>Referencia</Label>
              <Input value={formData.referencia} onChange={e => setFormData({...formData, referencia: e.target.value})} placeholder="Folio de transferencia..." />
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setModalOpen(false)}>Cancelar</Button>
            <Button onClick={confirmarCobro}>Confirmar Cobro</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
