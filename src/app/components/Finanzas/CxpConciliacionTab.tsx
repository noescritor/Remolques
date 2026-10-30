import React, { useState, useEffect, useCallback } from 'react';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '../ui/card';
import { Button } from '../ui/button';
import { Input } from '../ui/input';
import { Label } from '../ui/label';
import { Badge } from '../ui/badge';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../ui/select';
import { CheckCircle2, AlertTriangle, AlertCircle, RefreshCw, Save, DollarSign, Building, CreditCard, Calendar, Receipt } from 'lucide-react';
import { toast } from 'sonner';
import { BASE_URL } from '../../utils/api';
import { supabase } from '../../utils/supabase/client';
import { formatearMonedaDe, fechaLocalISO } from '../../utils/cuentasPorPagar';

interface CxpConciliacionTabProps {
  proveedores: any[];
  proveedorInicial?: string;
}

export function CxpConciliacionTab({ proveedores, proveedorInicial }: CxpConciliacionTabProps) {
  const [proveedorId, setProveedorId] = useState<string>(proveedorInicial || '');
  const [fechaCorte, setFechaCorte] = useState<string>(() => fechaLocalISO());

  const [conciliacion, setConciliacion] = useState<any>(null);
  const [cargando, setCargando] = useState(false);

  // Formulario captura estado de cuenta proveedor
  const [saldoCapturaUSD, setSaldoCapturaUSD] = useState<string>('');
  const [saldoCapturaMXN, setSaldoCapturaMXN] = useState<string>('');
  const [notasCaptura, setNotasCaptura] = useState<string>('');
  const [guardandoEC, setGuardandoEC] = useState(false);

  // Formulario ficha de crédito
  const [fichaCredito, setFichaCredito] = useState({
    razon_social: '',
    rfc: '',
    moneda_default: 'MXN',
    dias_credito: 30,
    limite_credito: '',
    limite_credito_moneda: 'MXN',
    notas_credito: '',
  });
  const [guardandoCredito, setGuardandoCredito] = useState(false);

  // Actualizar proveedor si cambia proveedorInicial
  useEffect(() => {
    if (proveedorInicial) {
      setProveedorId(proveedorInicial);
    } else if (proveedores.length > 0 && !proveedorId) {
      // Priorizar CADECO si existe en la lista para facilitar la revisión
      const cadeco = proveedores.find((p) => p.nombre?.toUpperCase().includes('CADECO'));
      setProveedorId(cadeco ? cadeco.id : proveedores[0].id);
    }
  }, [proveedorInicial, proveedores]);

  // Cargar datos de conciliación y crédito
  const cargarConciliacion = useCallback(async () => {
    if (!proveedorId) return;
    setCargando(true);
    try {
      const { data: { session } } = await supabase.auth.getSession();
      const token = session?.access_token || '';

      const [resConcil, resCredito] = await Promise.all([
        fetch(`${BASE_URL}/cxp/proveedores/${proveedorId}/conciliacion?corte=${fechaCorte}`, {
          headers: { Authorization: `Bearer ${token}` },
        }),
        fetch(`${BASE_URL}/cxp/proveedores/${proveedorId}/credito`, {
          headers: { Authorization: `Bearer ${token}` },
        }),
      ]);

      if (!resConcil.ok) {
        throw new Error(`Error ${resConcil.status} en conciliación`);
      }

      const dataConcil = await resConcil.json();
      setConciliacion(dataConcil);

      // Precargar saldos de captura si existen
      if (dataConcil.monedas?.USD?.saldoProveedor !== null) {
        setSaldoCapturaUSD(String(dataConcil.monedas.USD.saldoProveedor));
      } else {
        setSaldoCapturaUSD('');
      }

      if (dataConcil.monedas?.MXN?.saldoProveedor !== null) {
        setSaldoCapturaMXN(String(dataConcil.monedas.MXN.saldoProveedor));
      } else {
        setSaldoCapturaMXN('');
      }

      if (resCredito.ok) {
        const dataCredito = await resCredito.json();
        setFichaCredito({
          razon_social: dataCredito.razon_social || '',
          rfc: dataCredito.rfc || '',
          moneda_default: dataCredito.moneda_default || 'MXN',
          dias_credito: dataCredito.dias_credito ?? 30,
          limite_credito: dataCredito.limite_credito !== null && dataCredito.limite_credito !== undefined ? String(dataCredito.limite_credito) : '',
          limite_credito_moneda: dataCredito.limite_credito_moneda || 'MXN',
          notas_credito: dataCredito.notas_credito || '',
        });
      }
    } catch (err: any) {
      console.error('Error al cargar conciliación:', err);
      toast.error(`Error al cargar datos: ${err.message}`);
    } finally {
      setCargando(false);
    }
  }, [proveedorId, fechaCorte]);

  useEffect(() => {
    if (proveedorId) {
      cargarConciliacion();
    }
  }, [proveedorId, fechaCorte, cargarConciliacion]);

  // Guardar estado de cuenta del proveedor
  const handleGuardarEstadoCuenta = async (moneda: 'USD' | 'MXN') => {
    const valorStr = moneda === 'USD' ? saldoCapturaUSD : saldoCapturaMXN;
    if (valorStr === '' || isNaN(Number(valorStr))) {
      toast.error(`Indique un saldo válido para ${moneda}`);
      return;
    }

    setGuardandoEC(true);
    try {
      const { data: { session } } = await supabase.auth.getSession();
      const token = session?.access_token || '';

      const res = await fetch(`${BASE_URL}/cxp/proveedores/${proveedorId}/estados-cuenta`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({
          fecha: fechaCorte,
          moneda,
          saldo: Number(valorStr),
          notas: notasCaptura.trim() || undefined,
        }),
      });

      const data = await res.json();
      if (!res.ok) {
        throw new Error(data.error || 'Error al guardar estado de cuenta');
      }

      toast.success(`Estado de cuenta ${moneda} registrado a la fecha ${fechaCorte}`);
      cargarConciliacion();
    } catch (err: any) {
      console.error('Error al guardar estado de cuenta:', err);
      toast.error(`Error: ${err.message}`);
    } finally {
      setGuardandoEC(false);
    }
  };

  // Guardar ficha de crédito del proveedor
  const handleGuardarCredito = async (e: React.FormEvent) => {
    e.preventDefault();
    setGuardandoCredito(true);
    try {
      const { data: { session } } = await supabase.auth.getSession();
      const token = session?.access_token || '';

      const payload = {
        razon_social: fichaCredito.razon_social.trim() || null,
        rfc: fichaCredito.rfc.trim().toUpperCase() || null,
        moneda_default: fichaCredito.moneda_default,
        dias_credito: Number(fichaCredito.dias_credito) || 0,
        limite_credito: fichaCredito.limite_credito !== '' ? Number(fichaCredito.limite_credito) : null,
        limite_credito_moneda: fichaCredito.limite_credito !== '' ? fichaCredito.limite_credito_moneda : null,
        notas_credito: fichaCredito.notas_credito.trim() || null,
      };

      const res = await fetch(`${BASE_URL}/cxp/proveedores/${proveedorId}/credito`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify(payload),
      });

      const data = await res.json();
      if (!res.ok) {
        throw new Error(data.error || 'Error al actualizar ficha de crédito');
      }

      toast.success('Ficha de crédito del proveedor actualizada');
      cargarConciliacion();
    } catch (err: any) {
      console.error('Error al actualizar ficha de crédito:', err);
      toast.error(`Error: ${err.message}`);
    } finally {
      setGuardandoCredito(false);
    }
  };

  const provActual = proveedores.find((p) => p.id === proveedorId);

  return (
    <div className="space-y-6">
      {/* Selector de Proveedor y Fecha de Corte */}
      <Card className="bg-card border-border">
        <CardContent className="pt-6">
          <div className="flex flex-col md:flex-row items-center justify-between gap-4">
            <div className="flex flex-col sm:flex-row items-center gap-4 w-full md:w-auto">
              <div className="w-full sm:w-80">
                <Label className="text-xs font-semibold text-muted-foreground mb-1 block">
                  Proveedor a conciliar
                </Label>
                <Select value={proveedorId} onValueChange={setProveedorId}>
                  <SelectTrigger className="bg-background text-foreground border-border text-sm">
                    <SelectValue placeholder="Seleccione un proveedor" />
                  </SelectTrigger>
                  <SelectContent className="bg-card border-border text-foreground">
                    {proveedores.map((p) => (
                      <SelectItem key={p.id} value={p.id}>
                        {p.nombre} {p.razon_social ? `(${p.razon_social})` : ''}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>

              <div className="w-full sm:w-48">
                <Label className="text-xs font-semibold text-muted-foreground mb-1 block">
                  Fecha de corte
                </Label>
                <Input
                  type="date"
                  value={fechaCorte}
                  onChange={(e) => setFechaCorte(e.target.value)}
                  className="bg-background text-foreground border-border text-sm"
                />
              </div>
            </div>

            <Button
              variant="outline"
              size="sm"
              onClick={cargarConciliacion}
              disabled={cargando}
              className="text-foreground w-full md:w-auto"
            >
              <RefreshCw className={`h-4 w-4 mr-2 ${cargando ? 'animate-spin' : ''}`} />
              Recalcular Conciliación
            </Button>
          </div>
        </CardContent>
      </Card>

      {/* Grid Principal: Comparativa lado a lado + Captura de Estado de Cuenta */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Columna Izquierda / Central: Comparativa y Facturas Abiertas (2 cols) */}
        <div className="lg:col-span-2 space-y-6">
          {/* Tarjetas de Comparativa por Moneda */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {/* Moneda USD */}
            <Card className="bg-card border-border">
              <CardHeader className="pb-2">
                <div className="flex items-center justify-between">
                  <CardTitle className="text-sm font-semibold text-foreground flex items-center gap-1.5">
                    <DollarSign className="h-4 w-4 text-emerald-500" />
                    Conciliación en Dólares (USD)
                  </CardTitle>
                  {conciliacion?.monedas?.USD?.estado === 'cuadra' && (
                    <Badge className="bg-emerald-500/10 text-emerald-600 border-emerald-500/30 text-[10px] uppercase">
                      Cuadra
                    </Badge>
                  )}
                  {conciliacion?.monedas?.USD?.estado === 'leolca_mayor' && (
                    <Badge variant="destructive" className="text-[10px] uppercase">
                      Leolca mayor (+US$ {Number(conciliacion?.monedas?.USD?.diferencia || 0).toFixed(2)})
                    </Badge>
                  )}
                  {conciliacion?.monedas?.USD?.estado === 'proveedor_mayor' && (
                    <Badge className="bg-blue-500/10 text-blue-600 border-blue-500/30 text-[10px] uppercase">
                      Proveedor mayor (-US$ {Number(conciliacion?.monedas?.USD?.diferencia || 0).toFixed(2)})
                    </Badge>
                  )}
                </div>
              </CardHeader>
              <CardContent className="space-y-3">
                <div className="grid grid-cols-3 gap-2 text-center pt-2">
                  <div className="p-2 rounded bg-muted/50 border border-border">
                    <div className="text-[11px] text-muted-foreground uppercase font-medium">Saldo Leolca</div>
                    <div className="text-sm font-mono font-bold text-foreground mt-0.5">
                      {formatearMonedaDe(conciliacion?.monedas?.USD?.saldoLeolca || 0, 'USD')}
                    </div>
                  </div>
                  <div className="p-2 rounded bg-muted/50 border border-border">
                    <div className="text-[11px] text-muted-foreground uppercase font-medium">Saldo Proveedor</div>
                    <div className="text-sm font-mono font-bold text-foreground mt-0.5">
                      {conciliacion?.monedas?.USD?.saldoProveedor !== null && conciliacion?.monedas?.USD?.saldoProveedor !== undefined
                        ? formatearMonedaDe(conciliacion.monedas.USD.saldoProveedor, 'USD')
                        : 'Sin capturar'}
                    </div>
                  </div>
                  <div className={`p-2 rounded border ${
                    Math.abs(conciliacion?.monedas?.USD?.diferencia || 0) < 0.01
                      ? 'bg-emerald-500/10 border-emerald-500/30 text-emerald-600'
                      : 'bg-amber-500/10 border-amber-500/30 text-amber-600'
                  }`}>
                    <div className="text-[11px] uppercase font-medium">Diferencia</div>
                    <div className="text-sm font-mono font-bold mt-0.5">
                      {conciliacion?.monedas?.USD?.diferencia !== null && conciliacion?.monedas?.USD?.diferencia !== undefined
                        ? formatearMonedaDe(conciliacion.monedas.USD.diferencia, 'USD')
                        : '—'}
                    </div>
                  </div>
                </div>

                {conciliacion?.monedas?.USD?.fechaProveedor && (
                  <div className="text-[11px] text-muted-foreground text-center">
                    Último estado de cuenta capturado al {conciliacion.monedas.USD.fechaProveedor}
                  </div>
                )}
              </CardContent>
            </Card>

            {/* Moneda MXN */}
            <Card className="bg-card border-border">
              <CardHeader className="pb-2">
                <div className="flex items-center justify-between">
                  <CardTitle className="text-sm font-semibold text-foreground flex items-center gap-1.5">
                    <DollarSign className="h-4 w-4 text-blue-500" />
                    Conciliación en Pesos (MXN)
                  </CardTitle>
                  {conciliacion?.monedas?.MXN?.estado === 'cuadra' && (
                    <Badge className="bg-emerald-500/10 text-emerald-600 border-emerald-500/30 text-[10px] uppercase">
                      Cuadra
                    </Badge>
                  )}
                  {conciliacion?.monedas?.MXN?.estado === 'leolca_mayor' && (
                    <Badge variant="destructive" className="text-[10px] uppercase">
                      Leolca mayor (+${Number(conciliacion?.monedas?.MXN?.diferencia || 0).toFixed(2)})
                    </Badge>
                  )}
                  {conciliacion?.monedas?.MXN?.estado === 'proveedor_mayor' && (
                    <Badge className="bg-blue-500/10 text-blue-600 border-blue-500/30 text-[10px] uppercase">
                      Proveedor mayor (-${Number(conciliacion?.monedas?.MXN?.diferencia || 0).toFixed(2)})
                    </Badge>
                  )}
                </div>
              </CardHeader>
              <CardContent className="space-y-3">
                <div className="grid grid-cols-3 gap-2 text-center pt-2">
                  <div className="p-2 rounded bg-muted/50 border border-border">
                    <div className="text-[11px] text-muted-foreground uppercase font-medium">Saldo Leolca</div>
                    <div className="text-sm font-mono font-bold text-foreground mt-0.5">
                      {formatearMonedaDe(conciliacion?.monedas?.MXN?.saldoLeolca || 0, 'MXN')}
                    </div>
                  </div>
                  <div className="p-2 rounded bg-muted/50 border border-border">
                    <div className="text-[11px] text-muted-foreground uppercase font-medium">Saldo Proveedor</div>
                    <div className="text-sm font-mono font-bold text-foreground mt-0.5">
                      {conciliacion?.monedas?.MXN?.saldoProveedor !== null && conciliacion?.monedas?.MXN?.saldoProveedor !== undefined
                        ? formatearMonedaDe(conciliacion.monedas.MXN.saldoProveedor, 'MXN')
                        : 'Sin capturar'}
                    </div>
                  </div>
                  <div className={`p-2 rounded border ${
                    Math.abs(conciliacion?.monedas?.MXN?.diferencia || 0) < 0.01
                      ? 'bg-emerald-500/10 border-emerald-500/30 text-emerald-600'
                      : 'bg-amber-500/10 border-amber-500/30 text-amber-600'
                  }`}>
                    <div className="text-[11px] uppercase font-medium">Diferencia</div>
                    <div className="text-sm font-mono font-bold mt-0.5">
                      {conciliacion?.monedas?.MXN?.diferencia !== null && conciliacion?.monedas?.MXN?.diferencia !== undefined
                        ? formatearMonedaDe(conciliacion.monedas.MXN.diferencia, 'MXN')
                        : '—'}
                    </div>
                  </div>
                </div>

                {conciliacion?.monedas?.MXN?.fechaProveedor && (
                  <div className="text-[11px] text-muted-foreground text-center">
                    Último estado de cuenta capturado al {conciliacion.monedas.MXN.fechaProveedor}
                  </div>
                )}
              </CardContent>
            </Card>
          </div>

          {/* Captura de Estado de Cuenta del Proveedor */}
          <Card className="bg-card border-border">
            <CardHeader className="pb-3">
              <CardTitle className="text-base font-semibold text-foreground flex items-center gap-2">
                <Receipt className="h-4 w-4 text-primary" />
                Captura de Saldo de Estado de Cuenta del Proveedor
              </CardTitle>
              <CardDescription className="text-xs text-muted-foreground">
                Capture aquí los saldos que reporta el proveedor en su documento físico o PDF a la fecha de corte ({fechaCorte}) para generar la conciliación automática.
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div className="space-y-2 p-3 rounded-lg border border-border bg-muted/20">
                  <Label htmlFor="saldoUSD" className="text-xs font-semibold text-foreground">
                    Saldo Reportado en USD
                  </Label>
                  <div className="flex gap-2">
                    <Input
                      id="saldoUSD"
                      type="number"
                      step="0.01"
                      placeholder="0.00"
                      value={saldoCapturaUSD}
                      onChange={(e) => setSaldoCapturaUSD(e.target.value)}
                      className="bg-background text-foreground border-border text-sm font-mono"
                    />
                    <Button
                      size="sm"
                      onClick={() => handleGuardarEstadoCuenta('USD')}
                      disabled={guardandoEC || saldoCapturaUSD === ''}
                    >
                      <Save className="h-4 w-4 mr-1" />
                      Guardar USD
                    </Button>
                  </div>
                </div>

                <div className="space-y-2 p-3 rounded-lg border border-border bg-muted/20">
                  <Label htmlFor="saldoMXN" className="text-xs font-semibold text-foreground">
                    Saldo Reportado en MXN
                  </Label>
                  <div className="flex gap-2">
                    <Input
                      id="saldoMXN"
                      type="number"
                      step="0.01"
                      placeholder="0.00"
                      value={saldoCapturaMXN}
                      onChange={(e) => setSaldoCapturaMXN(e.target.value)}
                      className="bg-background text-foreground border-border text-sm font-mono"
                    />
                    <Button
                      size="sm"
                      onClick={() => handleGuardarEstadoCuenta('MXN')}
                      disabled={guardandoEC || saldoCapturaMXN === ''}
                    >
                      <Save className="h-4 w-4 mr-1" />
                      Guardar MXN
                    </Button>
                  </div>
                </div>
              </div>

              <div className="space-y-1">
                <Label htmlFor="notasEC" className="text-xs text-muted-foreground">
                  Notas de conciliación (opcional)
                </Label>
                <Input
                  id="notasEC"
                  placeholder="Ej. Recibido por correo de cobranza CADECO / Estado de cuenta corte mensual"
                  value={notasCaptura}
                  onChange={(e) => setNotasCaptura(e.target.value)}
                  className="bg-background text-foreground border-border text-xs"
                />
              </div>
            </CardContent>
          </Card>

          {/* Facturas Abiertas a la Fecha de Corte */}
          <Card className="bg-card border-border">
            <CardHeader className="pb-3">
              <CardTitle className="text-base font-semibold text-foreground flex items-center justify-between">
                <span>Facturas Abiertas al {fechaCorte} ({conciliacion?.facturas_abiertas?.length || 0})</span>
                <span className="text-xs font-normal text-muted-foreground">
                  Facturas emitidas y pagos aplicados hasta esta fecha
                </span>
              </CardTitle>
            </CardHeader>
            <CardContent>
              {cargando ? (
                <div className="py-8 text-center text-muted-foreground text-sm">Cargando facturas...</div>
              ) : !conciliacion?.facturas_abiertas || conciliacion.facturas_abiertas.length === 0 ? (
                <div className="py-8 text-center text-muted-foreground text-sm">
                  No hay facturas abiertas para este proveedor a la fecha de corte seleccionada.
                </div>
              ) : (
                <div className="overflow-x-auto">
                  <table className="w-full text-xs text-left">
                    <thead className="bg-muted text-muted-foreground uppercase font-medium border-b border-border">
                      <tr>
                        <th className="py-2.5 px-3">Folio</th>
                        <th className="py-2.5 px-3">Emisión</th>
                        <th className="py-2.5 px-3">Vencimiento</th>
                        <th className="py-2.5 px-3">Moneda</th>
                        <th className="py-2.5 px-3 text-right">Importe</th>
                        <th className="py-2.5 px-3 text-right">Pagado a Fecha</th>
                        <th className="py-2.5 px-3 text-right font-bold">Saldo a Fecha</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-border">
                      {conciliacion.facturas_abiertas.map((f: any) => {
                        const folioCompleto = `${f.sucursal ? `${f.sucursal}-` : ''}${f.folio}`;
                        return (
                          <tr key={f.id} className="hover:bg-muted/50 transition-colors text-foreground">
                            <td className="py-2.5 px-3 font-mono font-medium">{folioCompleto}</td>
                            <td className="py-2.5 px-3 whitespace-nowrap">{f.fecha_emision}</td>
                            <td className="py-2.5 px-3 whitespace-nowrap">{f.fecha_vencimiento}</td>
                            <td className="py-2.5 px-3 font-bold">{f.moneda}</td>
                            <td className="py-2.5 px-3 text-right font-mono">{formatearMonedaDe(f.importe, f.moneda)}</td>
                            <td className="py-2.5 px-3 text-right font-mono text-emerald-600">{formatearMonedaDe(f.pagado_a_fecha, f.moneda)}</td>
                            <td className="py-2.5 px-3 text-right font-mono font-bold text-foreground">{formatearMonedaDe(f.saldo_a_fecha, f.moneda)}</td>
                          </tr>
                        );
                      })}
                    </tbody>
                  </table>
                </div>
              )}
            </CardContent>
          </Card>
        </div>

        {/* Columna Derecha: Ficha de Crédito del Proveedor */}
        <div className="space-y-6">
          <Card className="bg-card border-border">
            <CardHeader className="pb-3">
              <CardTitle className="text-base font-semibold text-foreground flex items-center gap-2">
                <CreditCard className="h-4 w-4 text-primary" />
                Ficha de Crédito
              </CardTitle>
              <CardDescription className="text-xs text-muted-foreground">
                Términos comerciales y límite acordado con {provActual?.nombre || 'el proveedor'}
              </CardDescription>
            </CardHeader>
            <CardContent>
              <form onSubmit={handleGuardarCredito} className="space-y-4">
                <div className="space-y-1">
                  <Label htmlFor="razonSocial" className="text-xs font-semibold text-foreground">
                    Razón Social
                  </Label>
                  <Input
                    id="razonSocial"
                    placeholder="Ej. CADECO S.A. DE C.V."
                    value={fichaCredito.razon_social}
                    onChange={(e) => setFichaCredito({ ...fichaCredito, razon_social: e.target.value })}
                    className="bg-background text-foreground border-border text-xs"
                  />
                </div>

                <div className="space-y-1">
                  <Label htmlFor="rfc" className="text-xs font-semibold text-foreground">
                    RFC
                  </Label>
                  <Input
                    id="rfc"
                    placeholder="CAD920101XYZ"
                    value={fichaCredito.rfc}
                    onChange={(e) => setFichaCredito({ ...fichaCredito, rfc: e.target.value })}
                    className="bg-background text-foreground border-border text-xs uppercase font-mono"
                  />
                </div>

                <div className="grid grid-cols-2 gap-3">
                  <div className="space-y-1">
                    <Label className="text-xs font-semibold text-foreground">
                      Moneda Habitual
                    </Label>
                    <Select
                      value={fichaCredito.moneda_default}
                      onValueChange={(val) => setFichaCredito({ ...fichaCredito, moneda_default: val })}
                    >
                      <SelectTrigger className="bg-background text-foreground border-border text-xs">
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent className="bg-card border-border text-foreground">
                        <SelectItem value="MXN">MXN (Pesos)</SelectItem>
                        <SelectItem value="USD">USD (Dólares)</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>

                  <div className="space-y-1">
                    <Label htmlFor="diasCredito" className="text-xs font-semibold text-foreground">
                      Días de Crédito
                    </Label>
                    <Input
                      id="diasCredito"
                      type="number"
                      min="0"
                      value={fichaCredito.dias_credito}
                      onChange={(e) => setFichaCredito({ ...fichaCredito, dias_credito: Number(e.target.value) })}
                      className="bg-background text-foreground border-border text-xs font-mono"
                    />
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-3">
                  <div className="space-y-1">
                    <Label htmlFor="limiteCredito" className="text-xs font-semibold text-foreground">
                      Límite de Crédito
                    </Label>
                    <Input
                      id="limiteCredito"
                      type="number"
                      step="0.01"
                      min="0"
                      placeholder="Sin límite"
                      value={fichaCredito.limite_credito}
                      onChange={(e) => setFichaCredito({ ...fichaCredito, limite_credito: e.target.value })}
                      className="bg-background text-foreground border-border text-xs font-mono"
                    />
                  </div>

                  <div className="space-y-1">
                    <Label className="text-xs font-semibold text-foreground">
                      Moneda Límite
                    </Label>
                    <Select
                      value={fichaCredito.limite_credito_moneda}
                      onValueChange={(val) => setFichaCredito({ ...fichaCredito, limite_credito_moneda: val })}
                    >
                      <SelectTrigger className="bg-background text-foreground border-border text-xs">
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent className="bg-card border-border text-foreground">
                        <SelectItem value="MXN">MXN</SelectItem>
                        <SelectItem value="USD">USD</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>
                </div>

                <div className="space-y-1">
                  <Label htmlFor="notasCredito" className="text-xs font-semibold text-foreground">
                    Notas de Crédito y Cobranza
                  </Label>
                  <Input
                    id="notasCredito"
                    placeholder="Ej. Contacto de cobranza, días de revisión..."
                    value={fichaCredito.notas_credito}
                    onChange={(e) => setFichaCredito({ ...fichaCredito, notas_credito: e.target.value })}
                    className="bg-background text-foreground border-border text-xs"
                  />
                </div>

                <Button
                  type="submit"
                  size="sm"
                  className="w-full text-xs font-medium"
                  disabled={guardandoCredito}
                >
                  <Save className="h-4 w-4 mr-2" />
                  {guardandoCredito ? 'Guardando...' : 'Guardar Ficha de Crédito'}
                </Button>
              </form>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
}
