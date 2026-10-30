import React, { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '../ui/card';
import { Button } from '../ui/button';
import { Input } from '../ui/input';
import { Label } from '../ui/label';
import {
  DollarSign,
  Calendar,
  AlertTriangle,
  ArrowRight,
  TrendingUp,
  Clock,
  Save,
  CheckCircle,
} from 'lucide-react';
import { formatearMonedaDe, Moneda } from '../../utils/cuentasPorPagar';
import { toast } from 'sonner';

interface ResumenTabProps {
  resumenData: any;
  cargando: boolean;
  fechaCorte: string;
  onCambiarFechaCorte: (fecha: string) => void;
  tipoCambio: number | string;
  onCambiarTipoCambio: (tc: string) => void;
  onGuardarTipoCambioHoy: () => Promise<void>;
  guardandoTC: boolean;
  onSeleccionarProveedor: (proveedorId: string) => void;
}

export function CxpResumenTab({
  resumenData,
  cargando,
  fechaCorte,
  onCambiarFechaCorte,
  tipoCambio,
  onCambiarTipoCambio,
  onGuardarTipoCambioHoy,
  guardandoTC,
  onSeleccionarProveedor,
}: ResumenTabProps) {
  const general = resumenData?.resumenGeneral || {
    saldoUSD: 0,
    saldoMXN: 0,
    equivalenteUSDEnPesos: null,
    totalEnPesos: null,
    antiguedad: {
      usd: { por_vencer: 0, '1_30': 0, '31_60': 0, mas_60: 0 },
      mxn: { por_vencer: 0, '1_30': 0, '31_60': 0, mas_60: 0 },
      pesos: null,
    },
    totalFacturasAbiertas: 0,
  };

  const porProveedor: any[] = resumenData?.porProveedor || [];
  const tcActual = resumenData?.tc;
  const tieneUSDSinTC = general.saldoUSD > 0 && (tcActual === null || tcActual === undefined || tcActual <= 0);

  return (
    <div className="space-y-6">
      {/* Barra de Controles: Tipo de Cambio y Fecha de Corte */}
      <Card className="bg-card border-border/50">
        <CardContent className="p-4">
          <div className="flex flex-col md:flex-row md:items-end justify-between gap-4">
            <div className="flex flex-wrap items-end gap-3">
              <div className="space-y-1.5">
                <Label htmlFor="tc-input" className="text-xs font-semibold text-foreground flex items-center gap-1.5">
                  <TrendingUp className="w-3.5 h-3.5 text-primary" />
                  Tipo de Cambio USD / MXN
                </Label>
                <div className="flex items-center gap-2">
                  <div className="relative">
                    <span className="absolute left-2.5 top-1/2 -translate-y-1/2 text-xs text-muted-foreground">$</span>
                    <Input
                      id="tc-input"
                      type="number"
                      step="0.0001"
                      min="0.0001"
                      value={tipoCambio}
                      onChange={(e) => onCambiarTipoCambio(e.target.value)}
                      placeholder="Ej. 19.50"
                      className="w-32 pl-6 font-mono text-sm h-9 bg-background"
                    />
                  </div>
                  <Button
                    type="button"
                    variant="outline"
                    size="sm"
                    onClick={onGuardarTipoCambioHoy}
                    disabled={guardandoTC || !tipoCambio || Number(tipoCambio) <= 0}
                    className="h-9 text-xs gap-1.5 border-border hover:bg-muted"
                  >
                    <Save className="w-3.5 h-3.5" />
                    {guardandoTC ? 'Guardando...' : 'Fijar TC de hoy'}
                  </Button>
                </div>
                {tcActual ? (
                  <p className="text-[11px] text-muted-foreground font-mono">
                    TC de referencia activo: ${Number(tcActual).toFixed(4)} MXN
                  </p>
                ) : (
                  <p className="text-[11px] text-amber-600 dark:text-amber-400 font-medium">
                    Sin tipo de cambio registrado
                  </p>
                )}
              </div>
            </div>

            <div className="flex items-end gap-3">
              <div className="space-y-1.5">
                <Label htmlFor="corte-input" className="text-xs font-semibold text-foreground flex items-center gap-1.5">
                  <Calendar className="w-3.5 h-3.5 text-primary" />
                  Fecha de Corte
                </Label>
                <Input
                  id="corte-input"
                  type="date"
                  value={fechaCorte}
                  onChange={(e) => onCambiarFechaCorte(e.target.value)}
                  className="w-40 font-mono text-sm h-9 bg-background"
                />
              </div>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Aviso claro si hay facturas en USD y falta tipo de cambio */}
      {tieneUSDSinTC && (
        <div className="p-4 rounded-lg bg-amber-500/10 border border-amber-500/30 flex items-start gap-3">
          <AlertTriangle className="w-5 h-5 text-amber-600 dark:text-amber-400 shrink-0 mt-0.5" />
          <div className="text-xs text-amber-900 dark:text-amber-200 space-y-1">
            <p className="font-semibold text-sm">
              Hay facturas pendientes en dólares (US$ {formatearMonedaDe(general.saldoUSD, 'USD')}) sin tipo de cambio
            </p>
            <p>
              Para calcular el equivalente en pesos y el total consolidado a pagar, capture el tipo de cambio del día en el control superior y haga clic en "Fijar TC de hoy".
            </p>
          </div>
        </div>
      )}

      {/* 3 Tarjetas de Métricas de Saldo */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        {/* Saldo USD */}
        <Card className="bg-card border-border/50 shadow-sm">
          <CardHeader className="pb-2">
            <CardTitle className="text-xs font-semibold text-muted-foreground uppercase tracking-wider flex items-center justify-between">
              <span>Saldo en Dólares</span>
              <span className="text-[10px] bg-primary/10 text-primary px-2 py-0.5 rounded-full font-mono">USD</span>
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold font-mono text-foreground">
              {formatearMonedaDe(general.saldoUSD, 'USD')}
            </div>
            <div className="mt-1 text-xs text-muted-foreground font-mono">
              {general.equivalenteUSDEnPesos !== null ? (
                <span>≈ {formatearMonedaDe(general.equivalenteUSDEnPesos, 'MXN')} MXN</span>
              ) : (
                <span className="text-amber-600 dark:text-amber-400">TC requerido para conversión</span>
              )}
            </div>
          </CardContent>
        </Card>

        {/* Saldo MXN */}
        <Card className="bg-card border-border/50 shadow-sm">
          <CardHeader className="pb-2">
            <CardTitle className="text-xs font-semibold text-muted-foreground uppercase tracking-wider flex items-center justify-between">
              <span>Saldo en Pesos</span>
              <span className="text-[10px] bg-muted text-muted-foreground px-2 py-0.5 rounded-full font-mono">MXN</span>
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold font-mono text-foreground">
              {formatearMonedaDe(general.saldoMXN, 'MXN')}
            </div>
            <div className="mt-1 text-xs text-muted-foreground">
              Facturas emitidas en moneda nacional
            </div>
          </CardContent>
        </Card>

        {/* Total Consolidado en Pesos */}
        <Card className="bg-card border-border/50 shadow-sm">
          <CardHeader className="pb-2">
            <CardTitle className="text-xs font-semibold text-muted-foreground uppercase tracking-wider flex items-center justify-between">
              <span>Total Consolidado a Pagar</span>
              <DollarSign className="w-4 h-4 text-emerald-600 dark:text-emerald-400" />
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold font-mono text-emerald-600 dark:text-emerald-400">
              {general.totalEnPesos !== null ? (
                formatearMonedaDe(general.totalEnPesos, 'MXN')
              ) : (
                <span className="text-muted-foreground text-lg">Incompleto (Falta TC)</span>
              )}
            </div>
            <div className="mt-1 text-xs text-muted-foreground">
              {general.totalFacturasAbiertas} {general.totalFacturasAbiertas === 1 ? 'factura abierta' : 'facturas abiertas'}
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Fila de Cuatro Celdas de Antigüedad de Saldos */}
      <Card className="bg-card border-border/50">
        <CardHeader className="pb-3 border-b border-border/50">
          <CardTitle className="text-sm font-semibold text-foreground flex items-center gap-2">
            <Clock className="w-4 h-4 text-primary" />
            Antigüedad de Saldos (al corte {fechaCorte})
          </CardTitle>
        </CardHeader>
        <CardContent className="pt-4">
          <div className="grid grid-cols-2 lg:grid-cols-4 gap-3">
            {/* Por Vencer */}
            <div className="p-3.5 rounded-lg border border-border/60 bg-muted/20">
              <span className="text-xs font-semibold text-muted-foreground uppercase tracking-wider">
                Por vencer
              </span>
              <div className="mt-2 text-lg font-bold font-mono text-foreground">
                {general.antiguedad.pesos ? (
                  formatearMonedaDe(general.antiguedad.pesos.por_vencer, 'MXN')
                ) : (
                  formatearMonedaDe(general.antiguedad.mxn.por_vencer, 'MXN')
                )}
              </div>
              <div className="text-[11px] text-muted-foreground font-mono mt-0.5 space-x-1.5">
                {general.antiguedad.usd.por_vencer > 0 && (
                  <span>US$ {formatearMonedaDe(general.antiguedad.usd.por_vencer, 'USD')}</span>
                )}
                <span>MXN {formatearMonedaDe(general.antiguedad.mxn.por_vencer, 'MXN')}</span>
              </div>
            </div>

            {/* 1 a 30 días */}
            <div className="p-3.5 rounded-lg border border-border/60 bg-muted/20">
              <span className="text-xs font-semibold text-muted-foreground uppercase tracking-wider">
                1 a 30 días
              </span>
              <div className="mt-2 text-lg font-bold font-mono text-foreground">
                {general.antiguedad.pesos ? (
                  formatearMonedaDe(general.antiguedad.pesos['1_30'], 'MXN')
                ) : (
                  formatearMonedaDe(general.antiguedad.mxn['1_30'], 'MXN')
                )}
              </div>
              <div className="text-[11px] text-muted-foreground font-mono mt-0.5 space-x-1.5">
                {general.antiguedad.usd['1_30'] > 0 && (
                  <span>US$ {formatearMonedaDe(general.antiguedad.usd['1_30'], 'USD')}</span>
                )}
                <span>MXN {formatearMonedaDe(general.antiguedad.mxn['1_30'], 'MXN')}</span>
              </div>
            </div>

            {/* 31 a 60 días */}
            <div className="p-3.5 rounded-lg border border-border/60 bg-muted/20">
              <span className="text-xs font-semibold text-muted-foreground uppercase tracking-wider">
                31 a 60 días
              </span>
              <div className="mt-2 text-lg font-bold font-mono text-foreground">
                {general.antiguedad.pesos ? (
                  formatearMonedaDe(general.antiguedad.pesos['31_60'], 'MXN')
                ) : (
                  formatearMonedaDe(general.antiguedad.mxn['31_60'], 'MXN')
                )}
              </div>
              <div className="text-[11px] text-muted-foreground font-mono mt-0.5 space-x-1.5">
                {general.antiguedad.usd['31_60'] > 0 && (
                  <span>US$ {formatearMonedaDe(general.antiguedad.usd['31_60'], 'USD')}</span>
                )}
                <span>MXN {formatearMonedaDe(general.antiguedad.mxn['31_60'], 'MXN')}</span>
              </div>
            </div>

            {/* Más de 60 días */}
            <div className={`p-3.5 rounded-lg border ${
              (general.antiguedad.usd.mas_60 > 0 || general.antiguedad.mxn.mas_60 > 0)
                ? 'border-destructive/40 bg-destructive/5'
                : 'border-border/60 bg-muted/20'
            }`}>
              <div className="flex items-center justify-between">
                <span className={`text-xs font-semibold uppercase tracking-wider ${
                  (general.antiguedad.usd.mas_60 > 0 || general.antiguedad.mxn.mas_60 > 0)
                    ? 'text-destructive font-bold'
                    : 'text-muted-foreground'
                }`}>
                  Más de 60 días
                </span>
                {(general.antiguedad.usd.mas_60 > 0 || general.antiguedad.mxn.mas_60 > 0) && (
                  <span className="text-[10px] bg-destructive/10 text-destructive px-1.5 py-0.2 rounded font-medium">
                    Vencido Crítico
                  </span>
                )}
              </div>
              <div className={`mt-2 text-lg font-bold font-mono ${
                (general.antiguedad.usd.mas_60 > 0 || general.antiguedad.mxn.mas_60 > 0)
                  ? 'text-destructive'
                  : 'text-foreground'
              }`}>
                {general.antiguedad.pesos ? (
                  formatearMonedaDe(general.antiguedad.pesos.mas_60, 'MXN')
                ) : (
                  formatearMonedaDe(general.antiguedad.mxn.mas_60, 'MXN')
                )}
              </div>
              <div className="text-[11px] text-muted-foreground font-mono mt-0.5 space-x-1.5">
                {general.antiguedad.usd.mas_60 > 0 && (
                  <span>US$ {formatearMonedaDe(general.antiguedad.usd.mas_60, 'USD')}</span>
                )}
                <span>MXN {formatearMonedaDe(general.antiguedad.mxn.mas_60, 'MXN')}</span>
              </div>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Tabla por Proveedor */}
      <Card className="bg-card border-border/50 overflow-hidden">
        <CardHeader className="pb-3 border-b border-border/50">
          <CardTitle className="text-sm font-semibold text-foreground flex items-center justify-between">
            <span>Saldos y Crédito por Proveedor ({porProveedor.length})</span>
            <span className="text-xs font-normal text-muted-foreground">
              Haga clic en una fila para ver sus facturas
            </span>
          </CardTitle>
        </CardHeader>
        <CardContent className="p-0">
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs border-collapse">
              <thead>
                <tr className="bg-muted/40 border-b border-border text-muted-foreground font-medium">
                  <th className="py-2.5 px-4">Proveedor</th>
                  <th className="py-2.5 px-4 text-right">Saldo USD</th>
                  <th className="py-2.5 px-4 text-right">Saldo MXN</th>
                  <th className="py-2.5 px-4 text-right">Total en Pesos</th>
                  <th className="py-2.5 px-4 text-center">Atraso Máx.</th>
                  <th className="py-2.5 px-4">Uso de Crédito</th>
                  <th className="py-2.5 px-4 text-center">Acción</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border/50">
                {cargando ? (
                  <tr>
                    <td colSpan={7} className="py-8 text-center text-muted-foreground">
                      Cargando resumen de cuentas por pagar...
                    </td>
                  </tr>
                ) : porProveedor.length === 0 ? (
                  <tr>
                    <td colSpan={7} className="py-8 text-center text-muted-foreground">
                      No hay facturas con saldo pendiente al corte seleccionado.
                    </td>
                  </tr>
                ) : (
                  porProveedor.map((p) => {
                    const usoPct = p.usoCreditoPct || 0;
                    const tieneLimite = p.limite_credito && p.limite_credito > 0;
                    const barraColor = usoPct >= 90 ? 'bg-destructive' : usoPct >= 70 ? 'bg-amber-500' : 'bg-primary';

                    return (
                      <tr
                        key={p.proveedor_id}
                        onClick={() => onSeleccionarProveedor(p.proveedor_id)}
                        className="hover:bg-muted/30 cursor-pointer transition-colors"
                      >
                        <td className="py-3 px-4">
                          <div className="font-semibold text-foreground">{p.nombre}</div>
                          {p.razon_social && p.razon_social !== p.nombre && (
                            <div className="text-[11px] text-muted-foreground truncate max-w-xs">{p.razon_social}</div>
                          )}
                          {p.rfc && (
                            <div className="text-[10px] text-muted-foreground font-mono">{p.rfc}</div>
                          )}
                        </td>
                        <td className="py-3 px-4 text-right font-mono text-foreground font-medium">
                          {p.saldoUSD > 0 ? formatearMonedaDe(p.saldoUSD, 'USD') : '--'}
                        </td>
                        <td className="py-3 px-4 text-right font-mono text-foreground font-medium">
                          {p.saldoMXN > 0 ? formatearMonedaDe(p.saldoMXN, 'MXN') : '--'}
                        </td>
                        <td className="py-3 px-4 text-right font-mono font-bold text-foreground">
                          {p.totalEnPesos !== null ? formatearMonedaDe(p.totalEnPesos, 'MXN') : (
                            <span className="text-amber-600 font-normal text-xs">TC Pendiente</span>
                          )}
                        </td>
                        <td className="py-3 px-4 text-center">
                          {p.facturaMasVencidaDias > 0 ? (
                            <span className={`px-2 py-0.5 rounded text-[11px] font-mono font-semibold ${
                              p.facturaMasVencidaDias > 60
                                ? 'bg-destructive/10 text-destructive'
                                : 'bg-amber-500/10 text-amber-600'
                            }`}>
                              {p.facturaMasVencidaDias}d
                            </span>
                          ) : (
                            <span className="px-2 py-0.5 rounded text-[11px] font-mono text-muted-foreground bg-muted">
                              Al día
                            </span>
                          )}
                        </td>
                        <td className="py-3 px-4 min-w-[140px]">
                          {tieneLimite ? (
                            <div className="space-y-1">
                              <div className="flex justify-between text-[11px] font-mono">
                                <span className="text-muted-foreground">
                                  Límite: {p.limite_credito_moneda === 'USD' ? 'US$' : '$'}{Number(p.limite_credito).toLocaleString('es-MX')}
                                </span>
                                <span className={usoPct >= 90 ? 'text-destructive font-bold' : 'text-foreground'}>
                                  {usoPct.toFixed(1)}%
                                </span>
                              </div>
                              <div className="w-full bg-muted rounded-full h-1.5 overflow-hidden">
                                <div
                                  className={`h-full ${barraColor}`}
                                  style={{ width: `${Math.min(100, usoPct)}%` }}
                                />
                              </div>
                            </div>
                          ) : (
                            <span className="text-[11px] text-muted-foreground italic">Sin límite fijado</span>
                          )}
                        </td>
                        <td className="py-3 px-4 text-center">
                          <Button
                            variant="ghost"
                            size="sm"
                            className="h-7 px-2 text-xs text-primary hover:text-primary hover:bg-primary/10 gap-1"
                            onClick={(e) => {
                              e.stopPropagation();
                              onSeleccionarProveedor(p.proveedor_id);
                            }}
                          >
                            <span>Facturas ({p.totalFacturasAbiertas})</span>
                            <ArrowRight className="w-3 h-3" />
                          </Button>
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
