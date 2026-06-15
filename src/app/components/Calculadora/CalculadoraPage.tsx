import { useState, useEffect } from 'react';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '../ui/card';
import { Input } from '../ui/input';
import { Label } from '../ui/label';
import { Button } from '../ui/button';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../ui/select';
import { Calculator, Copy, ArrowRight, Ruler, RefreshCw, Package } from 'lucide-react';
import { toast } from "sonner";

type UnidadMedida = 'cm' | 'm';

export function CalculadoraPage() {
  // Unidad de medida
  const [unidadMaterial, setUnidadMaterial] = useState<UnidadMedida>('cm');
  const [unidadPieza, setUnidadPieza] = useState<UnidadMedida>('cm');
  
  // Dimensiones del material comprado
  const [anchoMaterial, setAnchoMaterial] = useState<string>('60');
  const [altoMaterial, setAltoMaterial] = useState<string>('100');
  const [precioMaterial, setPrecioMaterial] = useState<string>('145');
  
  // Dimensiones de la pieza/producto
  const [anchoPieza, setAnchoPieza] = useState<string>('12');
  const [altoPieza, setAltoPieza] = useState<string>('12');
  
  // Resultados
  const [areaMaterial, setAreaMaterial] = useState<number>(0);
  const [areaPieza, setAreaPieza] = useState<number>(0);
  const [precioPorCm2, setPrecioPorCm2] = useState<number>(0);
  const [costoPieza, setCostoPieza] = useState<number>(0);
  const [piezasPosibles, setPiezasPosibles] = useState<number>(0);

  // Calcular resultados
  useEffect(() => {
    let anchoMat = parseFloat(anchoMaterial) || 0;
    let altoMat = parseFloat(altoMaterial) || 0;
    const precioMat = parseFloat(precioMaterial) || 0;
    let anchoPie = parseFloat(anchoPieza) || 0;
    let altoPie = parseFloat(altoPieza) || 0;

    // Convertir todo a cm para cálculos uniformes
    if (unidadMaterial === 'm') {
      anchoMat = anchoMat * 100;
      altoMat = altoMat * 100;
    }
    
    if (unidadPieza === 'm') {
      anchoPie = anchoPie * 100;
      altoPie = altoPie * 100;
    }

    // Área del material (en cm²)
    const areaM = anchoMat * altoMat;
    setAreaMaterial(areaM);

    // Área de la pieza (en cm²)
    const areaP = anchoPie * altoPie;
    setAreaPieza(areaP);

    // Precio por cm²
    const precioCm2 = areaM > 0 ? precioMat / areaM : 0;
    setPrecioPorCm2(precioCm2);

    // Costo de la pieza
    const costoP = areaP * precioCm2;
    setCostoPieza(costoP);

    // Piezas que se pueden sacar (considerando solo área, sin optimización de corte)
    const piezas = areaM > 0 && areaP > 0 ? Math.floor(areaM / areaP) : 0;
    setPiezasPosibles(piezas);
  }, [anchoMaterial, altoMaterial, precioMaterial, anchoPieza, altoPieza, unidadMaterial, unidadPieza]);

  const handleCopiarCosto = async () => {
    const texto = costoPieza.toFixed(2);
    try {
      await navigator.clipboard.writeText(texto);
      toast.success('Costo copiado al portapapeles');
    } catch (err) {
      toast.error('Error al copiar al portapapeles');
    }
  };

  const handleReset = () => {
    setAnchoMaterial('60');
    setAltoMaterial('100');
    setPrecioMaterial('145');
    setAnchoPieza('12');
    setAltoPieza('12');
    setUnidadMaterial('cm');
    setUnidadPieza('cm');
  };

  return (
    <div className="space-y-6 pb-20">
      <div>
        <h1 className="text-3xl font-bold font-sans flex items-center gap-2">
          <Calculator className="h-8 w-8 text-accent-blue" />
          Calculadora de Materiales
        </h1>
        <p className="text-muted-foreground mt-1">Calcula costos de piezas individuales a partir de material en bruto (rollo o plancha)</p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        
        {/* Lado Izquierdo: Formulario */}
        <div className="space-y-6">
          <Card className="bg-white/[0.02] border-white/[0.06]">
            <CardHeader className="pb-3 border-b border-white/[0.06]">
              <div className="flex items-center gap-2">
                <div className="w-8 h-8 rounded-full bg-accent-blue/10 flex items-center justify-center">
                  <Package className="w-4 h-4 text-accent-blue" />
                </div>
                <div>
                  <CardTitle className="text-lg">Material Comprado</CardTitle>
                  <CardDescription>Dimensiones y precio del rollo o plancha completa</CardDescription>
                </div>
              </div>
            </CardHeader>
            <CardContent className="pt-6">
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label>Unidad de medida</Label>
                  <Select value={unidadMaterial} onValueChange={(v: UnidadMedida) => setUnidadMaterial(v)}>
                    <SelectTrigger>
                      <SelectValue placeholder="Seleccionar unidad" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="cm">Centímetros (cm)</SelectItem>
                      <SelectItem value="m">Metros (m)</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
                <div className="space-y-2">
                  <Label>Precio Total ($)</Label>
                  <Input 
                    type="number" 
                    value={precioMaterial} 
                    onChange={(e) => setPrecioMaterial(e.target.value)}
                    placeholder="Ej. 145"
                  />
                </div>
                <div className="space-y-2">
                  <Label>Ancho ({unidadMaterial})</Label>
                  <Input 
                    type="number" 
                    value={anchoMaterial} 
                    onChange={(e) => setAnchoMaterial(e.target.value)}
                    placeholder="Ej. 60"
                  />
                </div>
                <div className="space-y-2">
                  <Label>Alto / Largo ({unidadMaterial})</Label>
                  <Input 
                    type="number" 
                    value={altoMaterial} 
                    onChange={(e) => setAltoMaterial(e.target.value)}
                    placeholder="Ej. 100"
                  />
                </div>
              </div>
            </CardContent>
          </Card>

          <Card className="bg-white/[0.02] border-white/[0.06]">
            <CardHeader className="pb-3 border-b border-white/[0.06]">
              <div className="flex items-center gap-2">
                <div className="w-8 h-8 rounded-full bg-accent-green/10 flex items-center justify-center">
                  <Ruler className="w-4 h-4 text-accent-green" />
                </div>
                <div>
                  <CardTitle className="text-lg">Pieza a Fabricar</CardTitle>
                  <CardDescription>Dimensiones del corte individual o diseño</CardDescription>
                </div>
              </div>
            </CardHeader>
            <CardContent className="pt-6">
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div className="space-y-2 sm:col-span-2">
                  <Label>Unidad de medida</Label>
                  <Select value={unidadPieza} onValueChange={(v: UnidadMedida) => setUnidadPieza(v)}>
                    <SelectTrigger>
                      <SelectValue placeholder="Seleccionar unidad" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="cm">Centímetros (cm)</SelectItem>
                      <SelectItem value="m">Metros (m)</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
                <div className="space-y-2">
                  <Label>Ancho ({unidadPieza})</Label>
                  <Input 
                    type="number" 
                    value={anchoPieza} 
                    onChange={(e) => setAnchoPieza(e.target.value)}
                    placeholder="Ej. 12"
                  />
                </div>
                <div className="space-y-2">
                  <Label>Alto / Largo ({unidadPieza})</Label>
                  <Input 
                    type="number" 
                    value={altoPieza} 
                    onChange={(e) => setAltoPieza(e.target.value)}
                    placeholder="Ej. 12"
                  />
                </div>
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Lado Derecho: Resultados */}
        <div className="space-y-6">
          <Card className="bg-white/[0.02] border-white/[0.06] h-full flex flex-col">
            <CardHeader className="pb-4">
              <CardTitle className="text-xl">Resultados del Cálculo</CardTitle>
            </CardHeader>
            <CardContent className="flex-1 flex flex-col gap-6">
              
              <div className="grid grid-cols-2 gap-4">
                <div className="p-4 rounded-lg bg-black/40 border border-white/5">
                  <p className="text-xs text-muted-foreground uppercase tracking-wider mb-1">Costo por cm²</p>
                  <p className="text-xl font-mono font-bold">${precioPorCm2.toFixed(4)}</p>
                </div>
                <div className="p-4 rounded-lg bg-black/40 border border-white/5">
                  <p className="text-xs text-muted-foreground uppercase tracking-wider mb-1">Área total mat.</p>
                  <p className="text-xl font-mono font-bold">{areaMaterial.toLocaleString()} <span className="text-sm font-sans text-muted-foreground">cm²</span></p>
                </div>
              </div>

              <div className="p-6 rounded-xl bg-accent-blue/5 border border-accent-blue/20 flex flex-col items-center justify-center text-center">
                <p className="text-sm text-accent-blue/80 uppercase tracking-widest font-mono mb-2">Costo Exacto por Pieza</p>
                <div className="flex items-center gap-2">
                  <span className="text-5xl font-bold font-mono text-white">${costoPieza.toFixed(2)}</span>
                </div>
                <Button 
                  className="mt-4 bg-accent-blue text-black hover:bg-accent-blue/90" 
                  onClick={handleCopiarCosto}
                >
                  <Copy className="w-4 h-4 mr-2" /> Copiar Valor
                </Button>
              </div>

              <div className="mt-auto pt-6 border-t border-white/[0.06]">
                <div className="flex items-center justify-between p-4 rounded-lg bg-white/[0.02]">
                  <div>
                    <p className="text-sm font-medium">Rendimiento estimado</p>
                    <p className="text-xs text-muted-foreground">Cantidad aprox. de piezas</p>
                  </div>
                  <div className="text-2xl font-bold font-mono">{piezasPosibles} <span className="text-sm font-sans font-normal text-muted-foreground">pz</span></div>
                </div>
              </div>

              <Button variant="outline" className="w-full mt-4" onClick={handleReset}>
                <RefreshCw className="w-4 h-4 mr-2" /> Reiniciar Calculadora
              </Button>

            </CardContent>
          </Card>
        </div>

      </div>
    </div>
  );
}
