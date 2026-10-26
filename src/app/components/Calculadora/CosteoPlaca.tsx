import React, { useState, useMemo } from 'react';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '../ui/card';
import { Input } from '../ui/input';
import { Label } from '../ui/label';
import { Button } from '../ui/button';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../ui/select';
import { Badge } from '../ui/badge';
import { Layers, Copy, Ruler, Calculator, AlertCircle, Info, Check, RefreshCw } from 'lucide-react';
import { toast } from 'sonner';
import {
  medidaFtAMm,
  costoPieza,
  CostoPiezaResultado,
  FACTOR_PLACA_DEFECTO,
} from '../../utils/aceroCalc';
import { formatearMoneda } from '../../utils/calculations';
import { AceroMaterialItem } from '../../../../supabase/functions/make-server-feea4382/motor/acero';

interface CosteoPlacaProps {
  materiales: AceroMaterialItem[];
  proveedores: string[];
  loading?: boolean;
  onRecargar?: () => void;
}

type UnidadPieza = 'mm' | 'cm';

export function CosteoPlaca({
  materiales,
  proveedores: _provs,
  loading = false,
  onRecargar,
}: CosteoPlacaProps) {
  // Filtrar solo láminas y placas activas con dimensiones
  const laminasYPlacas = useMemo(() => {
    return materiales.filter(
      (m) =>
        m.activo &&
        (m.tipo === 'placa' || m.tipo === 'lamina') &&
        m.ancho_ft !== null &&
        m.largo_ft !== null
    );
  }, [materiales]);

  // Selección de material
  const [materialSeleccionadoId, setMaterialSeleccionadoId] = useState<string>(() => {
    // Si existe la lámina de 1/4" 4X10', seleccionarla por defecto para coincidir con la prueba dorada
    const dorada = laminasYPlacas.find(
      (m) => m.nombre.includes('1/4"') && m.nombre.includes('4X10')
    );
    return dorada?.id || laminasYPlacas[0]?.id || 'manual';
  });

  // Si no había selección inicial y llegan datos
  React.useEffect(() => {
    if (materialSeleccionadoId === 'manual' && laminasYPlacas.length > 0) {
      const dorada = laminasYPlacas.find(
        (m) => m.nombre.includes('1/4"') && m.nombre.includes('4X10')
      );
      if (dorada) setMaterialSeleccionadoId(dorada.id);
    }
  }, [laminasYPlacas]);

  const esManual = materialSeleccionadoId === 'manual';
  const materialActual = useMemo(
    () => laminasYPlacas.find((m) => m.id === materialSeleccionadoId),
    [laminasYPlacas, materialSeleccionadoId]
  );

  // Lista de proveedores disponibles para el material actual
  const proveedoresDisponibles = useMemo(() => {
    if (!materialActual || !materialActual.precios) return [];
    return Object.keys(materialActual.precios).filter(
      (prov) => materialActual.precios![prov]?.precio > 0
    );
  }, [materialActual]);

  // Proveedor seleccionado: 'MEJOR' o el nombre del proveedor
  const [proveedorSeleccionado, setProveedorSeleccionado] = useState<string>('MEJOR');

  // Encontrar el mejor precio del material actual
  const mejorPrecioInfo = useMemo(() => {
    if (!materialActual || !materialActual.precios) return null;
    let mejorProv: string | null = null;
    let minPrecio = Infinity;
    for (const [prov, p] of Object.entries(materialActual.precios)) {
      if (p.precio > 0 && p.precio < minPrecio) {
        minPrecio = p.precio;
        mejorProv = prov;
      }
    }
    if (!mejorProv || minPrecio === Infinity) return null;
    return { proveedor: mejorProv, precio: minPrecio };
  }, [materialActual]);

  // Precio resuelto de la lámina
  const precioLaminaResuelto = useMemo(() => {
    if (esManual) return 0;
    if (!materialActual || !materialActual.precios) return 0;
    if (proveedorSeleccionado === 'MEJOR') {
      return mejorPrecioInfo?.precio || 0;
    }
    return materialActual.precios[proveedorSeleccionado]?.precio || 0;
  }, [esManual, materialActual, proveedorSeleccionado, mejorPrecioInfo]);

  // Dimensiones de la lámina en mm
  const dimensionesLaminaMm = useMemo(() => {
    if (esManual || !materialActual || materialActual.ancho_ft === null || materialActual.largo_ft === null) {
      return { anchoMm: 1219, largoMm: 3050, anchoFt: 4, largoFt: 10 };
    }
    return {
      anchoMm: medidaFtAMm(materialActual.ancho_ft),
      largoMm: medidaFtAMm(materialActual.largo_ft),
      anchoFt: materialActual.ancho_ft,
      largoFt: materialActual.largo_ft,
    };
  }, [esManual, materialActual]);

  // Estado para valores manuales
  const [manualAnchoMm, setManualAnchoMm] = useState<string>('1219');
  const [manualLargoMm, setManualLargoMm] = useState<string>('3050');
  const [manualPrecio, setManualPrecio] = useState<string>('4193.34');

  // Dimensiones y parámetros de la pieza
  const [unidadPieza, setUnidadPieza] = useState<UnidadPieza>('mm');
  const [anchoPiezaStr, setAnchoPiezaStr] = useState<string>('1250');
  const [largoPiezaStr, setLargoPiezaStr] = useState<string>('1000');
  const [cantidadPiezasStr, setCantidadPiezasStr] = useState<string>('1');
  const [factorStr, setFactorStr] = useState<string>(String(FACTOR_PLACA_DEFECTO));

type CalculoResultado =
  | { exito: false; error: string }
  | ({
      exito: true;
      error: null;
      cantidad: number;
      costoTotalPiezas: number;
      anchoPiezaMm: number;
      largoPiezaMm: number;
      anchoLaminaMm: number;
      largoLaminaMm: number;
      precioLamina: number;
      factor: number;
    } & CostoPiezaResultado);

  // Cálculo en tiempo real
  const calculo = useMemo<CalculoResultado>(() => {
    const anchoLamMm = esManual ? parseFloat(manualAnchoMm) || 0 : dimensionesLaminaMm.anchoMm;
    const largoLamMm = esManual ? parseFloat(manualLargoMm) || 0 : dimensionesLaminaMm.largoMm;
    const precioLam = esManual ? parseFloat(manualPrecio) || 0 : precioLaminaResuelto;

    let anchoP = parseFloat(anchoPiezaStr) || 0;
    let largoP = parseFloat(largoPiezaStr) || 0;
    if (unidadPieza === 'cm') {
      anchoP *= 10;
      largoP *= 10;
    }

    const cantidad = parseInt(cantidadPiezasStr, 10) || 1;
    const factor = parseFloat(factorStr) || FACTOR_PLACA_DEFECTO;

    if (anchoLamMm <= 0 || largoLamMm <= 0 || precioLam <= 0) {
      return { exito: false, error: 'Faltan datos de la lámina o precio' };
    }
    if (anchoP <= 0 || largoP <= 0) {
      return { exito: false, error: 'Las dimensiones de la pieza deben ser mayores a cero' };
    }

    try {
      const res = costoPieza({
        precioLamina: precioLam,
        anchoLaminaMm: anchoLamMm,
        largoLaminaMm: largoLamMm,
        anchoPiezaMm: anchoP,
        largoPiezaMm: largoP,
        factor,
      });

      return {
        exito: true,
        ...res,
        cantidad,
        costoTotalPiezas: res.costoPieza * cantidad,
        anchoPiezaMm: anchoP,
        largoPiezaMm: largoP,
        anchoLaminaMm: anchoLamMm,
        largoLaminaMm: largoLamMm,
        precioLamina: precioLam,
        factor,
        error: null,
      };
    } catch (err: any) {
      return { exito: false, error: err.message };
    }
  }, [
    esManual,
    manualAnchoMm,
    manualLargoMm,
    manualPrecio,
    dimensionesLaminaMm,
    precioLaminaResuelto,
    anchoPiezaStr,
    largoPiezaStr,
    unidadPieza,
    cantidadPiezasStr,
    factorStr,
  ]);

  const [copiado, setCopiado] = useState(false);
  const handleCopiarCosto = async () => {
    if (!calculo.exito) return;
    const texto = calculo.costoPieza.toFixed(2);
    try {
      await navigator.clipboard.writeText(texto);
      setCopiado(true);
      toast.success(`Costo de $${texto} copiado al portapapeles`);
      setTimeout(() => setCopiado(false), 2000);
    } catch (_e) {
      toast.error('Error al copiar al portapapeles');
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h2 className="text-xl font-bold font-sans flex items-center gap-2 text-foreground">
            <Layers className="h-5 w-5 text-accent-blue" />
            Costeo de Placa y Lámina
          </h2>
          <p className="text-sm text-muted-foreground mt-0.5">
            Calcula el costo proporcional y con factor de proceso para piezas cortadas de una lámina o placa.
          </p>
        </div>
        {onRecargar && (
          <Button
            variant="outline"
            size="sm"
            onClick={onRecargar}
            disabled={loading}
            className="self-start sm:self-auto gap-1.5"
          >
            <RefreshCw className={`h-4 w-4 ${loading ? 'animate-spin' : ''}`} />
            Actualizar precios
          </Button>
        )}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
        {/* Panel izquierdo: Parámetros */}
        <div className="lg:col-span-7 space-y-6">
          {/* Card Lámina base */}
          <Card className="border-border bg-card">
            <CardHeader className="pb-3 border-b border-border/50">
              <CardTitle className="text-base font-semibold flex items-center gap-2">
                <Ruler className="h-4 w-4 text-accent-blue" />
                1. Selección de Lámina / Placa
              </CardTitle>
              <CardDescription className="text-xs">
                Elige un material del catálogo o ingresa medidas y precio manualmente.
              </CardDescription>
            </CardHeader>
            <CardContent className="pt-4 space-y-4">
              <div className="space-y-2">
                <Label className="text-xs font-medium text-foreground">Material</Label>
                <Select
                  value={materialSeleccionadoId}
                  onValueChange={setMaterialSeleccionadoId}
                >
                  <SelectTrigger className="w-full text-sm bg-background">
                    <SelectValue placeholder="Selecciona una lámina o placa" />
                  </SelectTrigger>
                  <SelectContent className="max-h-72">
                    <SelectItem value="manual" className="font-medium text-accent-blue">
                      ✍️ Precio y medida manual
                    </SelectItem>
                    {laminasYPlacas.map((m) => (
                      <SelectItem key={m.id} value={m.id}>
                        {m.nombre}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>

              {/* Si es catálogo */}
              {!esManual && materialActual && (
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 pt-1">
                  <div className="space-y-2">
                    <Label className="text-xs font-medium text-foreground">Proveedor</Label>
                    <Select
                      value={proveedorSeleccionado}
                      onValueChange={setProveedorSeleccionado}
                      disabled={proveedoresDisponibles.length === 0}
                    >
                      <SelectTrigger className="text-sm bg-background">
                        <SelectValue placeholder="Selecciona proveedor" />
                      </SelectTrigger>
                      <SelectContent>
                        {mejorPrecioInfo && (
                          <SelectItem value="MEJOR" className="font-semibold text-emerald-600 dark:text-emerald-400">
                            ★ Mejor precio ({mejorPrecioInfo.proveedor} — {formatearMoneda(mejorPrecioInfo.precio)})
                          </SelectItem>
                        )}
                        {proveedoresDisponibles.map((p) => (
                          <SelectItem key={p} value={p}>
                            {p} ({formatearMoneda(materialActual.precios?.[p]?.precio)})
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                  </div>

                  <div className="space-y-1 sm:pt-6">
                    <div className="p-2.5 rounded-lg border border-border/60 bg-muted/30 flex items-center justify-between text-xs">
                      <span className="text-muted-foreground">Medida comercial:</span>
                      <span className="font-mono font-medium text-foreground">
                        {materialActual.ancho_ft}&apos; × {materialActual.largo_ft}&apos; ({dimensionesLaminaMm.anchoMm.toLocaleString('es-MX')} × {dimensionesLaminaMm.largoMm.toLocaleString('es-MX')} mm)
                      </span>
                    </div>
                  </div>
                </div>
              )}

              {/* Si es manual */}
              {esManual && (
                <div className="grid grid-cols-1 sm:grid-cols-3 gap-3 p-3 rounded-lg border border-border/80 bg-muted/20">
                  <div className="space-y-1.5">
                    <Label className="text-xs">Ancho lámina (mm)</Label>
                    <Input
                      type="number"
                      value={manualAnchoMm}
                      onChange={(e) => setManualAnchoMm(e.target.value)}
                      placeholder="1219"
                      className="text-sm font-mono"
                    />
                  </div>
                  <div className="space-y-1.5">
                    <Label className="text-xs">Largo lámina (mm)</Label>
                    <Input
                      type="number"
                      value={manualLargoMm}
                      onChange={(e) => setManualLargoMm(e.target.value)}
                      placeholder="3050"
                      className="text-sm font-mono"
                    />
                  </div>
                  <div className="space-y-1.5">
                    <Label className="text-xs">Precio lámina ($ MXN)</Label>
                    <Input
                      type="number"
                      step="0.01"
                      value={manualPrecio}
                      onChange={(e) => setManualPrecio(e.target.value)}
                      placeholder="4193.34"
                      className="text-sm font-mono"
                    />
                  </div>
                </div>
              )}
            </CardContent>
          </Card>

          {/* Card Dimensiones de la Pieza */}
          <Card className="border-border bg-card">
            <CardHeader className="pb-3 border-b border-border/50">
              <CardTitle className="text-base font-semibold flex items-center gap-2">
                <Calculator className="h-4 w-4 text-accent-blue" />
                2. Dimensiones de la Pieza y Proceso
              </CardTitle>
              <CardDescription className="text-xs">
                Indica el tamaño del corte y el factor de merma o proceso aplicable.
              </CardDescription>
            </CardHeader>
            <CardContent className="pt-4 space-y-4">
              <div className="grid grid-cols-1 sm:grid-cols-4 gap-4">
                <div className="space-y-1.5">
                  <Label className="text-xs font-medium">Unidad de medida</Label>
                  <Select
                    value={unidadPieza}
                    onValueChange={(v: UnidadPieza) => setUnidadPieza(v)}
                  >
                    <SelectTrigger className="text-sm bg-background">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="mm">Milímetros (mm)</SelectItem>
                      <SelectItem value="cm">Centímetros (cm)</SelectItem>
                    </SelectContent>
                  </Select>
                </div>

                <div className="space-y-1.5">
                  <Label className="text-xs font-medium">Ancho pieza ({unidadPieza})</Label>
                  <Input
                    type="number"
                    step="0.1"
                    value={anchoPiezaStr}
                    onChange={(e) => setAnchoPiezaStr(e.target.value)}
                    className="text-sm font-mono"
                  />
                </div>

                <div className="space-y-1.5">
                  <Label className="text-xs font-medium">Largo pieza ({unidadPieza})</Label>
                  <Input
                    type="number"
                    step="0.1"
                    value={largoPiezaStr}
                    onChange={(e) => setLargoPiezaStr(e.target.value)}
                    className="text-sm font-mono"
                  />
                </div>

                <div className="space-y-1.5">
                  <Label className="text-xs font-medium">Piezas a cortar</Label>
                  <Input
                    type="number"
                    min="1"
                    value={cantidadPiezasStr}
                    onChange={(e) => setCantidadPiezasStr(e.target.value)}
                    className="text-sm font-mono"
                  />
                </div>
              </div>

              {/* Factor sobre costo */}
              <div className="pt-2 border-t border-border/40">
                <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2">
                  <div className="space-y-0.5">
                    <Label htmlFor="factor-input" className="text-xs font-medium text-foreground flex items-center gap-1.5">
                      Factor sobre costo (merma/proceso)
                      <Badge variant="outline" className="text-[10px] font-normal py-0">
                        Excel: 1.5
                      </Badge>
                    </Label>
                    <p className="text-[11px] text-muted-foreground flex items-center gap-1">
                      <Info className="h-3 w-3 inline flex-shrink-0" />
                      Valor del Excel del cliente; pendiente confirmar qué incluye.
                    </p>
                  </div>
                  <div className="w-28 flex-shrink-0">
                    <Input
                      id="factor-input"
                      type="number"
                      step="0.05"
                      min="1.0"
                      value={factorStr}
                      onChange={(e) => setFactorStr(e.target.value)}
                      className="text-sm font-mono text-right"
                    />
                  </div>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Panel derecho: Resultados */}
        <div className="lg:col-span-5 space-y-4">
          <Card className="border-border bg-card shadow-sm h-full flex flex-col justify-between">
            <div>
              <CardHeader className="pb-3 border-b border-border/50">
                <CardTitle className="text-base font-semibold">Resumen de Costeo</CardTitle>
                <CardDescription className="text-xs">
                  Cálculo proporcional basado en área y factor de proceso.
                </CardDescription>
              </CardHeader>
              <CardContent className="pt-4 space-y-4">
                {!calculo.exito ? (
                  <div className="p-4 rounded-lg border border-destructive/30 bg-destructive/10 text-destructive flex items-start gap-2.5 text-xs">
                    <AlertCircle className="h-4 w-4 mt-0.5 flex-shrink-0" />
                    <div>
                      <p className="font-semibold">No se pudo calcular:</p>
                      <p className="mt-0.5">{calculo.error}</p>
                    </div>
                  </div>
                ) : (
                  <div className="space-y-4">
                    {/* Costo de la pieza principal */}
                    <div className="p-4 rounded-xl border border-accent-blue/30 bg-accent-blue/5 dark:bg-accent-blue/10 space-y-2">
                      <div className="flex items-center justify-between">
                        <span className="text-xs font-medium text-muted-foreground uppercase tracking-wider">
                          Costo por pieza cortada
                        </span>
                        <Badge className="bg-accent-blue text-white text-[10px]">
                          Factor ×{calculo.factor}
                        </Badge>
                      </div>
                      <div className="flex items-baseline justify-between">
                        <span className="text-2xl sm:text-3xl font-mono font-bold text-foreground">
                          {formatearMoneda(calculo.costoPieza)}
                        </span>
                        <Button
                          size="sm"
                          variant="secondary"
                          onClick={handleCopiarCosto}
                          className="gap-1.5 text-xs h-8"
                        >
                          {copiado ? <Check className="h-3.5 w-3.5 text-emerald-600" /> : <Copy className="h-3.5 w-3.5" />}
                          {copiado ? 'Copiado' : 'Copiar'}
                        </Button>
                      </div>
                      <p className="text-[11px] text-muted-foreground">
                        Costo proporcional base: {formatearMoneda(calculo.costoProporcional)}
                      </p>
                    </div>

                    {/* Desglose detallado */}
                    <div className="space-y-2 text-xs divide-y divide-border/40">
                      <div className="flex justify-between py-1.5">
                        <span className="text-muted-foreground">Precio de lámina completa:</span>
                        <span className="font-mono font-medium text-foreground">
                          {formatearMoneda(calculo.precioLamina)}
                        </span>
                      </div>
                      <div className="flex justify-between py-1.5">
                        <span className="text-muted-foreground">Costo de lámina por m²:</span>
                        <span className="font-mono font-medium text-foreground">
                          {formatearMoneda(calculo.costoPorM2)} / m²
                        </span>
                      </div>
                      <div className="flex justify-between py-1.5">
                        <span className="text-muted-foreground">Área de la lámina:</span>
                        <span className="font-mono font-medium text-foreground">
                          {(calculo.areaLaminaMm2 / 1_000_000).toFixed(3)} m² ({calculo.anchoLaminaMm} × {calculo.largoLaminaMm} mm)
                        </span>
                      </div>
                      <div className="flex justify-between py-1.5">
                        <span className="text-muted-foreground">Área de la pieza:</span>
                        <span className="font-mono font-medium text-foreground">
                          {(calculo.areaPiezaMm2 / 1_000_000).toFixed(3)} m² ({calculo.anchoPiezaMm} × {calculo.largoPiezaMm} mm)
                        </span>
                      </div>
                      <div className="flex justify-between py-1.5">
                        <span className="text-muted-foreground">Piezas por lámina:</span>
                        <span className="font-mono font-bold text-foreground">
                          ~{calculo.piezasPorArea} piezas
                        </span>
                      </div>
                    </div>

                    <div className="p-2.5 rounded-lg bg-muted/40 text-[11px] text-muted-foreground">
                      * Piezas estimadas por área geométrica; el corte real depende del acomodo y sangría del corte (plasma/oxicorte).
                    </div>

                    {/* Total si son N piezas */}
                    {calculo.cantidad > 1 && (
                      <div className="p-3 rounded-lg border border-border/80 bg-card flex items-center justify-between text-xs">
                        <span className="font-medium text-foreground">
                          Total para {calculo.cantidad} piezas:
                        </span>
                        <span className="font-mono text-base font-bold text-foreground">
                          {formatearMoneda(calculo.costoTotalPiezas)}
                        </span>
                      </div>
                    )}
                  </div>
                )}
              </CardContent>
            </div>
          </Card>
        </div>
      </div>
    </div>
  );
}
