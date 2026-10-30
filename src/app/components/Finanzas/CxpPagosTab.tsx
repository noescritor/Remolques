import React, { useState, useEffect, useCallback } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '../ui/card';
import { Button } from '../ui/button';
import { Input } from '../ui/input';
import { Label } from '../ui/label';
import { Badge } from '../ui/badge';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter, DialogDescription } from '../ui/dialog';
import { Search, Ban, Calendar, DollarSign, Receipt, AlertCircle, RefreshCw } from 'lucide-react';
import { toast } from 'sonner';
import { BASE_URL } from '../../utils/api';
import { supabase } from '../../utils/supabase/client';
import { formatearMonedaDe } from '../../utils/cuentasPorPagar';

export function CxpPagosTab() {
  const [pagos, setPagos] = useState<any[]>([]);
  const [cargando, setCargando] = useState(true);
  const [truncado, setTruncado] = useState(false);
  const [busqueda, setBusqueda] = useState('');
  const [filtroSoloValidos, setFiltroSoloValidos] = useState(false);

  // Modal Anular
  const [modalAnular, setModalAnular] = useState(false);
  const [pagoAAnular, setPagoAAnular] = useState<any>(null);
  const [motivoAnulacion, setMotivoAnulacion] = useState('');
  const [guardandoAnulacion, setGuardandoAnulacion] = useState(false);

  const fetchPagos = useCallback(async () => {
    setCargando(true);
    try {
      const { data: { session } } = await supabase.auth.getSession();
      const token = session?.access_token || '';

      const res = await fetch(`${BASE_URL}/cxp/pagos`, {
        headers: {
          Authorization: `Bearer ${token}`,
        },
      });

      if (!res.ok) {
        throw new Error(`Error ${res.status}: ${res.statusText}`);
      }

      const data = await res.json();
      setPagos(data.pagos || []);
      setTruncado(!!data.truncado);
    } catch (err: any) {
      console.error('Error al cargar pagos:', err);
      toast.error(`Error al cargar pagos: ${err.message}`);
    } finally {
      setCargando(false);
    }
  }, []);

  useEffect(() => {
    fetchPagos();
  }, [fetchPagos]);

  const abrirModalAnular = (pago: any) => {
    setPagoAAnular(pago);
    setMotivoAnulacion('');
    setModalAnular(true);
  };

  const handleConfirmarAnulacion = async () => {
    if (!motivoAnulacion.trim()) {
      toast.error('El motivo de anulación es obligatorio');
      return;
    }

    setGuardandoAnulacion(true);
    try {
      const { data: { session } } = await supabase.auth.getSession();
      const token = session?.access_token || '';

      const res = await fetch(`${BASE_URL}/cxp/pagos/${pagoAAnular.id}/anular`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({ motivo: motivoAnulacion.trim() }),
      });

      const data = await res.json();
      if (!res.ok) {
        throw new Error(data.error || 'Error al anular pago');
      }

      toast.success('Pago anulado exitosamente. El saldo de la factura fue restaurado.');
      setModalAnular(false);
      setPagoAAnular(null);
      fetchPagos();
    } catch (err: any) {
      console.error('Error al anular pago:', err);
      toast.error(`Error: ${err.message}`);
    } finally {
      setGuardandoAnulacion(false);
    }
  };

  const pagosFiltrados = pagos.filter((p) => {
    if (filtroSoloValidos && p.anulado) return false;
    if (!busqueda) return true;
    const term = busqueda.toLowerCase();
    const provNombre = p.factura?.proveedor?.nombre?.toLowerCase() || '';
    const provRazon = p.factura?.proveedor?.razon_social?.toLowerCase() || '';
    const folio = p.factura?.folio?.toLowerCase() || '';
    const ref = p.referencia?.toLowerCase() || '';
    const rep = p.complemento_pago?.toLowerCase() || '';
    return provNombre.includes(term) || provRazon.includes(term) || folio.includes(term) || ref.includes(term) || rep.includes(term);
  });

  return (
    <div className="space-y-6">
      {/* Controles de Búsqueda y Filtros */}
      <Card className="bg-card border-border">
        <CardContent className="pt-6">
          <div className="flex flex-col md:flex-row items-center justify-between gap-4">
            <div className="relative w-full md:w-96">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
              <Input
                placeholder="Buscar por proveedor, folio, referencia, REP..."
                value={busqueda}
                onChange={(e) => setBusqueda(e.target.value)}
                className="pl-9 bg-background text-foreground border-border text-sm"
              />
            </div>

            <div className="flex items-center gap-3 w-full md:w-auto justify-end">
              <label className="flex items-center gap-2 text-sm text-foreground cursor-pointer select-none">
                <input
                  type="checkbox"
                  checked={filtroSoloValidos}
                  onChange={(e) => setFiltroSoloValidos(e.target.checked)}
                  className="rounded border-border"
                />
                Ocultar pagos anulados
              </label>

              <Button
                variant="outline"
                size="sm"
                onClick={fetchPagos}
                disabled={cargando}
                className="text-foreground"
              >
                <RefreshCw className={`h-4 w-4 mr-2 ${cargando ? 'animate-spin' : ''}`} />
                Actualizar
              </Button>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Aviso de truncado a 200 registros */}
      {truncado && (
        <div className="p-3 rounded-md bg-amber-500/10 border border-amber-500/30 text-amber-600 text-xs flex items-center gap-2">
          <AlertCircle className="h-4 w-4 shrink-0" />
          <span>Mostrando los 200 abonos más recientes. Utilice el buscador para localizar abonos específicos.</span>
        </div>
      )}

      {/* Tabla de Pagos */}
      <Card className="bg-card border-border">
        <CardHeader className="pb-3">
          <CardTitle className="text-base font-semibold text-foreground flex items-center justify-between">
            <span>Historial Cronológico de Abonos ({pagosFiltrados.length})</span>
            <span className="text-xs font-normal text-muted-foreground">
              Los pagos nunca se eliminan; anular restaura el saldo de la factura
            </span>
          </CardTitle>
        </CardHeader>
        <CardContent>
          {cargando ? (
            <div className="py-12 text-center text-muted-foreground">Cargando pagos...</div>
          ) : pagosFiltrados.length === 0 ? (
            <div className="py-12 text-center text-muted-foreground">
              No se encontraron pagos con los filtros seleccionados
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-sm text-left">
                <thead className="bg-muted text-muted-foreground text-xs uppercase font-medium border-b border-border">
                  <tr>
                    <th className="py-3 px-3">Fecha</th>
                    <th className="py-3 px-3">Proveedor</th>
                    <th className="py-3 px-3">Factura</th>
                    <th className="py-3 px-3">Método / Ref</th>
                    <th className="py-3 px-3">REP / Complemento</th>
                    <th className="py-3 px-3 text-right">Monto Original</th>
                    <th className="py-3 px-3 text-right">TC Aplicado</th>
                    <th className="py-3 px-3 text-right">Monto en Pesos</th>
                    <th className="py-3 px-3 text-center">Estado</th>
                    <th className="py-3 px-3 text-right">Acción</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-border">
                  {pagosFiltrados.map((p) => {
                    const moneda = p.factura?.moneda || 'MXN';
                    const prov = p.factura?.proveedor?.razon_social || p.factura?.proveedor?.nombre || 'Proveedor';
                    const folioCompleto = `${p.factura?.sucursal ? `${p.factura.sucursal}-` : ''}${p.factura?.folio || ''}`;

                    return (
                      <tr
                        key={p.id}
                        className={`hover:bg-muted/50 transition-colors ${
                          p.anulado ? 'opacity-60 bg-muted/20 line-through text-muted-foreground' : 'text-foreground'
                        }`}
                      >
                        <td className="py-3 px-3 whitespace-nowrap font-mono text-xs">
                          {p.fecha_pago}
                        </td>
                        <td className="py-3 px-3 font-medium">
                          {prov}
                        </td>
                        <td className="py-3 px-3 whitespace-nowrap font-mono font-medium">
                          {folioCompleto}
                        </td>
                        <td className="py-3 px-3 text-xs">
                          <div>{p.metodo_pago}</div>
                          {p.referencia && <div className="text-muted-foreground text-[11px]">Ref: {p.referencia}</div>}
                        </td>
                        <td className="py-3 px-3 font-mono text-xs text-muted-foreground">
                          {p.complemento_pago || '—'}
                        </td>
                        <td className="py-3 px-3 text-right font-mono font-semibold whitespace-nowrap">
                          {formatearMonedaDe(p.monto, moneda)}
                        </td>
                        <td className="py-3 px-3 text-right font-mono text-xs text-muted-foreground whitespace-nowrap">
                          {moneda === 'USD' && p.tipo_cambio ? `$${Number(p.tipo_cambio).toFixed(4)}` : '—'}
                        </td>
                        <td className="py-3 px-3 text-right font-mono font-bold whitespace-nowrap">
                          {formatearMonedaDe(p.monto_en_pesos, 'MXN')}
                        </td>
                        <td className="py-3 px-3 text-center">
                          {p.anulado ? (
                            <div className="inline-flex flex-col items-center">
                              <Badge variant="destructive" className="text-[10px] uppercase font-bold py-0.5 px-1.5">
                                Anulado
                              </Badge>
                              {p.anulado_motivo && (
                                <span className="text-[10px] text-muted-foreground truncate max-w-[120px] not-italic no-underline" title={p.anulado_motivo}>
                                  {p.anulado_motivo}
                                </span>
                              )}
                            </div>
                          ) : (
                            <Badge variant="outline" className="text-[10px] text-emerald-600 border-emerald-500/30 bg-emerald-500/10 font-medium">
                              Válido
                            </Badge>
                          )}
                        </td>
                        <td className="py-3 px-3 text-right whitespace-nowrap not-italic no-underline">
                          {!p.anulado && (
                            <Button
                              variant="ghost"
                              size="sm"
                              className="h-8 px-2 text-destructive hover:text-destructive hover:bg-destructive/10"
                              onClick={() => abrirModalAnular(p)}
                              title="Anular pago y restaurar saldo"
                            >
                              <Ban className="h-4 w-4 mr-1" />
                              Anular
                            </Button>
                          )}
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Diálogo de Confirmación de Anulación */}
      <Dialog open={modalAnular} onOpenChange={setModalAnular}>
        <DialogContent className="sm:max-w-[450px] bg-card border-border text-foreground">
          <DialogHeader>
            <DialogTitle className="text-destructive flex items-center gap-2">
              <Ban className="h-5 w-5" />
              Anular Pago
            </DialogTitle>
            <DialogDescription className="text-muted-foreground text-sm">
              Esta acción restaura el saldo pendiente en la factura asociada. Los pagos no se borran de la base de datos, quedan registrados como anulados por trazabilidad.
            </DialogDescription>
          </DialogHeader>

          {pagoAAnular && (
            <div className="space-y-4 py-2">
              <div className="p-3 rounded-md bg-muted text-xs space-y-1">
                <div><strong>Factura:</strong> {pagoAAnular.factura?.folio} ({pagoAAnular.factura?.proveedor?.nombre})</div>
                <div><strong>Monto:</strong> {formatearMonedaDe(pagoAAnular.monto, pagoAAnular.factura?.moneda || 'MXN')} ({pagoAAnular.fecha_pago})</div>
                {pagoAAnular.referencia && <div><strong>Referencia:</strong> {pagoAAnular.referencia}</div>}
              </div>

              <div className="space-y-2">
                <Label htmlFor="motivo" className="text-xs font-semibold">
                  Motivo de anulación <span className="text-destructive">*</span>
                </Label>
                <Input
                  id="motivo"
                  placeholder="Ej. Cheque rebotado, error en captura, pago duplicado..."
                  value={motivoAnulacion}
                  onChange={(e) => setMotivoAnulacion(e.target.value)}
                  className="bg-background text-foreground border-border"
                />
              </div>
            </div>
          )}

          <DialogFooter className="gap-2 sm:gap-0">
            <Button
              type="button"
              variant="outline"
              onClick={() => setModalAnular(false)}
              disabled={guardandoAnulacion}
            >
              Cancelar
            </Button>
            <Button
              type="button"
              variant="destructive"
              onClick={handleConfirmarAnulacion}
              disabled={guardandoAnulacion}
            >
              {guardandoAnulacion ? 'Anulando...' : 'Confirmar Anulación'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
