import { useState, useMemo } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '../ui/card';
import { Button } from '../ui/button';
import { Input } from '../ui/input';
import { Label } from '../ui/label';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from '../ui/dialog';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../ui/select';
import { DollarSign, Calendar, FileText, CheckCircle, AlertTriangle } from 'lucide-react';
import { CompraProveedor, PagoProveedor, Proveedor, Producto } from '../../types';
import { formatearMoneda } from '../../utils/calculations';

interface CuentasPorPagarProps {
  compras: CompraProveedor[];
  pagos: PagoProveedor[];
  proveedores: Proveedor[];
  productos: Producto[];
  loading: boolean;
  onCrearPago: (pago: any) => Promise<void>;
}

export function CuentasPorPagar({ compras, pagos, proveedores, productos, loading, onCrearPago }: CuentasPorPagarProps) {
  const [modalOpen, setModalOpen] = useState(false);
  const [compraSeleccionada, setCompraSeleccionada] = useState<any>(null);
  const [formData, setFormData] = useState({
    monto: 0,
    metodo_pago: 'Transferencia',
    referencia: '',
  });

  const cuentas = useMemo(() => {
    // Solo consideramos compras no canceladas
    const activas = compras.filter(c => c.estado !== 'Cancelada');

    return activas.map(compra => {
      const pagosCompra = pagos.filter(p => p.compra_id === compra.id);
      const totalPagado = pagosCompra.reduce((sum, p) => sum + Number(p.monto), 0);
      
      const totalCompra = compra.items?.reduce((sum, item) => sum + (item.cantidad * item.costo_unitario), 0) || 0;
      const saldoPendiente = totalCompra - totalPagado;
      
      const proveedor = proveedores.find(p => p.id === compra.proveedor_id);
      
      let diasVencimiento = 0;
      if (compra.fecha_vencimiento_pago) {
        diasVencimiento = Math.ceil((new Date(compra.fecha_vencimiento_pago).getTime() - new Date().getTime()) / (1000 * 3600 * 24));
      }

      return {
        ...compra,
        proveedor_nombre: proveedor?.nombre || 'Desconocido',
        totalCompra,
        totalPagado,
        saldoPendiente,
        diasVencimiento,
        vencida: diasVencimiento < 0
      };
    }).filter(c => c.saldoPendiente > 0)
      .sort((a, b) => a.diasVencimiento - b.diasVencimiento); // Las que vencen pronto primero
  }, [compras, pagos, proveedores]);

  const totalPorPagar = cuentas.reduce((sum, c) => sum + c.saldoPendiente, 0);
  const totalVencido = cuentas.filter(c => c.vencida).reduce((sum, c) => sum + c.saldoPendiente, 0);

  const handlePagar = (c: any) => {
    setCompraSeleccionada(c);
    setFormData({
      monto: c.saldoPendiente,
      metodo_pago: 'Transferencia',
      referencia: ''
    });
    setModalOpen(true);
  };

  const confirmarPago = async () => {
    if (!compraSeleccionada || formData.monto <= 0) return;
    try {
      await onCrearPago({
        compra_id: compraSeleccionada.id,
        monto: formData.monto,
        metodo_pago: formData.metodo_pago,
        referencia: formData.referencia,
        fecha_pago: new Date().toISOString()
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
          <h1 className="text-3xl font-bold font-sans">Cuentas por Pagar</h1>
          <p className="text-muted-foreground mt-1">Obligaciones de pago a proveedores por compras.</p>
        </div>
      </div>

      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
        <Card className="bg-white/[0.02] border-white/[0.06]">
          <CardHeader className="pb-2 flex flex-row items-center justify-between">
            <CardTitle className="text-lg text-white font-mono tracking-wide">Total por Pagar</CardTitle>
            <DollarSign className="text-accent-blue w-5 h-5" />
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold font-mono text-white">{formatearMoneda(totalPorPagar)}</div>
            <p className="text-xs text-muted-foreground mt-1">En {cuentas.length} compras pendientes</p>
          </CardContent>
        </Card>
        
        <Card className="bg-white/[0.02] border-red-500/20">
          <CardHeader className="pb-2 flex flex-row items-center justify-between">
            <CardTitle className="text-lg text-white font-mono tracking-wide text-red-400">Total Vencido</CardTitle>
            <AlertTriangle className="text-red-400 w-5 h-5" />
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold font-mono text-red-400">{formatearMoneda(totalVencido)}</div>
            <p className="text-xs text-muted-foreground mt-1">Pagos con retraso</p>
          </CardContent>
        </Card>
      </div>

      {cuentas.length === 0 ? (
        <div className="text-center py-20 bg-white/[0.02] rounded-xl border border-white/[0.06]">
          <CheckCircle className="mx-auto h-12 w-12 text-accent-green mb-4" />
          <h3 className="text-lg font-medium text-white mb-2">Todo al día</h3>
          <p className="text-muted-foreground">No hay saldos pendientes por pagar a proveedores.</p>
        </div>
      ) : (
        <div className="rounded-xl border border-white/[0.06] bg-white/[0.02] overflow-hidden">
          {cuentas.map((c, i) => (
            <div key={c.id} className="p-4 flex flex-col md:flex-row md:items-center justify-between group gap-4" style={{ borderTop: i ? '1px solid rgba(255,255,255,0.06)' : 'none' }}>
              <div className="flex flex-col gap-1">
                <div className="flex items-center gap-2">
                  <span className="font-mono text-sm bg-white/10 px-2 py-0.5 rounded text-white">{c.folio}</span>
                  <span className="text-sm font-medium text-white">{c.proveedor_nombre}</span>
                </div>
                <div className="text-xs text-muted-foreground mt-1 flex items-center gap-3">
                  <span className="flex items-center"><Calendar className="w-3 h-3 mr-1" /> Vence: {c.fecha_vencimiento_pago ? new Date(c.fecha_vencimiento_pago).toLocaleDateString() : 'No definida'}</span>
                  <span className={`font-medium ${c.vencida ? 'text-red-400' : (c.diasVencimiento <= 3 ? 'text-orange-400' : 'text-accent-green')}`}>
                    {c.vencida ? `Vencida hace ${Math.abs(c.diasVencimiento)} días` : `En ${c.diasVencimiento} días`}
                  </span>
                </div>
              </div>
              <div className="flex items-center justify-between md:justify-end gap-6 w-full md:w-auto">
                <div className="text-right">
                  <div className="text-xs text-muted-foreground">Saldo Pendiente</div>
                  <div className="font-mono font-bold text-accent-blue text-lg">{formatearMoneda(c.saldoPendiente)}</div>
                </div>
                <Button onClick={() => handlePagar(c)} className="bg-accent-blue text-white hover:bg-accent-blue/90" variant={c.vencida ? 'destructive' : 'default'}>
                  <DollarSign className="w-4 h-4 mr-2" /> Pagar
                </Button>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Modal Pago */}
      <Dialog open={modalOpen} onOpenChange={setModalOpen}>
        <DialogContent className="bg-background border-border">
          <DialogHeader>
            <DialogTitle>Registrar Pago a Proveedor</DialogTitle>
          </DialogHeader>
          <div className="grid gap-4 py-4">
            <div className="text-sm text-muted-foreground mb-2">
              Folio: <span className="font-mono text-white">{compraSeleccionada?.folio}</span><br/>
              Saldo actual: <span className="font-mono text-white">{formatearMoneda(compraSeleccionada?.saldoPendiente || 0)}</span>
            </div>
            <div className="space-y-2">
              <Label>Monto a Pagar</Label>
              <Input type="number" value={formData.monto} onChange={e => setFormData({...formData, monto: Number(e.target.value)})} max={compraSeleccionada?.saldoPendiente || 0} />
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
              <Label>Referencia / Folio bancario</Label>
              <Input value={formData.referencia} onChange={e => setFormData({...formData, referencia: e.target.value})} />
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setModalOpen(false)}>Cancelar</Button>
            <Button onClick={confirmarPago}>Confirmar Pago</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
