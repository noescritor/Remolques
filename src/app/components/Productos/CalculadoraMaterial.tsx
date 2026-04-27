import { useState, useEffect } from 'react';
import { Card } from '../ui/card';
import { Input } from '../ui/input';
import { Label } from '../ui/label';
import { Button } from '../ui/button';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../ui/select';
import { Calculator, Copy, ArrowRight, Ruler, RefreshCw } from 'lucide-react';
import { toast } from "sonner";

interface CalculadoraMaterialProps {
  onAplicarCosto?: (costo: number) => void;
}

type UnidadMedida = 'cm' | 'm';

export function CalculadoraMaterial({ onAplicarCosto }: CalculadoraMaterialProps) {
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

  const handleAplicarCosto = () => {
    if (costoPieza > 0 && onAplicarCosto) {
      onAplicarCosto(costoPieza);
      toast.success(`Costo de $${costoPieza.toFixed(2)} aplicado`);
    }
  };

  const handleCopiarCosto = async () => {
    const texto = costoPieza.toFixed(2);
    
    // Intentar con Clipboard API primero
    try {
      await navigator.clipboard.writeText(texto);
      toast.success('Costo copiado al portapapeles');
      return;
    } catch (err) {
      // Fallback: crear un elemento temporal
      try {
        const textArea = document.createElement('textarea');
        textArea.value = texto;
        textArea.style.position = 'fixed';
        textArea.style.left = '-999999px';
        textArea.style.top = '-999999px';
        document.body.appendChild(textArea);
        textArea.focus();
        textArea.select();
        
        const successful = document.execCommand('copy');
        document.body.removeChild(textArea);
        
        if (successful) {
          toast.success('Costo copiado al portapapeles');
        } else {
          toast.error('No se pudo copiar al portapapeles');
        }
      } catch (fallbackErr) {
        toast.error('No se pudo copiar al portapapeles');
      }
    }
  };

  const aplicarPreset = (preset: string) => {
    switch (preset) {
      case 'vinil':
        setAnchoMaterial('60');
        setAltoMaterial('100');
        setPrecioMaterial('145');
        setUnidadMaterial('cm');
        toast.success('Preset de vinil aplicado');
        break;
      case 'papel':
        setAnchoMaterial('0.9');
        setAltoMaterial('1.2');
        setPrecioMaterial('85');
        setUnidadMaterial('m');
        toast.success('Preset de papel aplicado');
        break;
      case 'tela':
        setAnchoMaterial('1.5');
        setAltoMaterial('1');
        setPrecioMaterial('120');
        setUnidadMaterial('m');
        toast.success('Preset de tela aplicado');
        break;
    }
  };

  return (
    <Card className="p-6 bg-gradient-to-br from-blue-50 to-indigo-50 border-blue-200">
      <div className="space-y-3 mb-4">
        <div className="flex items-center gap-2">
          <div className="w-10 h-10 rounded-lg bg-blue-600 flex items-center justify-center">
            <Calculator className="w-5 h-5 text-white" />
          </div>
          <div className="flex-1">
            <h3 className="text-blue-900">Calculadora de Material</h3>
            <p className="text-blue-700 text-sm">Calcula el costo por área de tus insumos</p>
          </div>
        </div>
        
        <div className="flex gap-2">
          <Button 
            onClick={() => aplicarPreset('vinil')} 
            variant="outline" 
            size="sm"
            className="text-xs border-blue-300 text-blue-700 hover:bg-blue-50"
          >
            📐 Vinil 60×100cm
          </Button>
          <Button 
            onClick={() => aplicarPreset('papel')} 
            variant="outline" 
            size="sm"
            className="text-xs border-blue-300 text-blue-700 hover:bg-blue-50"
          >
            📄 Papel 90×120cm
          </Button>
          <Button 
            onClick={() => aplicarPreset('tela')} 
            variant="outline" 
            size="sm"
            className="text-xs border-blue-300 text-blue-700 hover:bg-blue-50"
          >
            🧵 Tela 1.5×1m
          </Button>
        </div>
      </div>

      <div className="grid md:grid-cols-2 gap-6">
        {/* Material Comprado */}
        <div className="space-y-4">
          <div className="bg-white rounded-lg p-4 border border-blue-200">
            <h4 className="text-blue-900 mb-3 flex items-center gap-2">
              <Ruler className="w-4 h-4" />
              Material Comprado
            </h4>
            
            <div className="space-y-3">
              <div>
                <Label className="text-xs text-blue-700">Unidad de medida</Label>
                <Select value={unidadMaterial} onValueChange={(v) => setUnidadMaterial(v as UnidadMedida)}>
                  <SelectTrigger className="mt-1 bg-blue-50/50 border-blue-200">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="cm">Centímetros (cm)</SelectItem>
                    <SelectItem value="m">Metros (m)</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <Label className="text-xs text-blue-700">Ancho ({unidadMaterial})</Label>
                  <Input
                    type="number"
                    value={anchoMaterial}
                    onChange={(e) => setAnchoMaterial(e.target.value)}
                    placeholder={unidadMaterial === 'cm' ? '60' : '0.6'}
                    className="mt-1 bg-blue-50/50 border-blue-200"
                    step={unidadMaterial === 'cm' ? '1' : '0.01'}
                  />
                </div>
                <div>
                  <Label className="text-xs text-blue-700">Alto ({unidadMaterial})</Label>
                  <Input
                    type="number"
                    value={altoMaterial}
                    onChange={(e) => setAltoMaterial(e.target.value)}
                    placeholder={unidadMaterial === 'cm' ? '100' : '1'}
                    className="mt-1 bg-blue-50/50 border-blue-200"
                    step={unidadMaterial === 'cm' ? '1' : '0.01'}
                  />
                </div>
              </div>

              <div>
                <Label className="text-xs text-blue-700">Precio Total ($)</Label>
                <Input
                  type="number"
                  value={precioMaterial}
                  onChange={(e) => setPrecioMaterial(e.target.value)}
                  placeholder="145.00"
                  className="mt-1 bg-blue-50/50 border-blue-200"
                  step="0.01"
                />
              </div>

              <div className="pt-2 border-t border-blue-200">
                <div className="flex justify-between text-sm">
                  <span className="text-blue-700">Área total:</span>
                  <span className="text-blue-900">{areaMaterial.toLocaleString('es-MX', { maximumFractionDigits: 2 })} cm²</span>
                </div>
                <div className="flex justify-between text-sm mt-1">
                  <span className="text-blue-700">Precio por cm²:</span>
                  <span className="text-blue-900 font-mono">${precioPorCm2.toFixed(4)}</span>
                </div>
                {areaMaterial >= 10000 && (
                  <div className="flex justify-between text-xs mt-1 text-blue-600">
                    <span>Equivalente en m²:</span>
                    <span>{(areaMaterial / 10000).toFixed(3)} m² (${(precioPorCm2 * 10000).toFixed(2)}/m²)</span>
                  </div>
                )}
              </div>
            </div>
          </div>
        </div>

        {/* Pieza/Producto */}
        <div className="space-y-4">
          <div className="bg-white rounded-lg p-4 border border-indigo-200">
            <h4 className="text-indigo-900 mb-3 flex items-center gap-2">
              <Ruler className="w-4 h-4" />
              Pieza a Fabricar
            </h4>
            
            <div className="space-y-3">
              <div>
                <Label className="text-xs text-indigo-700">Unidad de medida</Label>
                <Select value={unidadPieza} onValueChange={(v) => setUnidadPieza(v as UnidadMedida)}>
                  <SelectTrigger className="mt-1 bg-indigo-50/50 border-indigo-200">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="cm">Centímetros (cm)</SelectItem>
                    <SelectItem value="m">Metros (m)</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <Label className="text-xs text-indigo-700">Ancho ({unidadPieza})</Label>
                  <Input
                    type="number"
                    value={anchoPieza}
                    onChange={(e) => setAnchoPieza(e.target.value)}
                    placeholder={unidadPieza === 'cm' ? '12' : '0.12'}
                    className="mt-1 bg-indigo-50/50 border-indigo-200"
                    step={unidadPieza === 'cm' ? '1' : '0.01'}
                  />
                </div>
                <div>
                  <Label className="text-xs text-indigo-700">Alto ({unidadPieza})</Label>
                  <Input
                    type="number"
                    value={altoPieza}
                    onChange={(e) => setAltoPieza(e.target.value)}
                    placeholder={unidadPieza === 'cm' ? '12' : '0.12'}
                    className="mt-1 bg-indigo-50/50 border-indigo-200"
                    step={unidadPieza === 'cm' ? '1' : '0.01'}
                  />
                </div>
              </div>

              <div className="pt-2 border-t border-indigo-200">
                <div className="flex justify-between text-sm">
                  <span className="text-indigo-700">Área de la pieza:</span>
                  <span className="text-indigo-900">{areaPieza.toLocaleString('es-MX', { maximumFractionDigits: 2 })} cm²</span>
                </div>
                <div className="flex justify-between text-sm mt-1">
                  <span className="text-indigo-700">Piezas posibles:</span>
                  <span className="text-indigo-900">{piezasPosibles} unidades</span>
                </div>
                {piezasPosibles > 0 && (
                  <>
                    <div className="flex justify-between text-xs mt-1 text-indigo-600">
                      <span>Costo por pieza:</span>
                      <span>${(costoPieza).toFixed(2)}</span>
                    </div>
                    <div className="flex justify-between text-xs mt-1 text-indigo-600">
                      <span>Aprovechamiento:</span>
                      <span>{((piezasPosibles * areaPieza / areaMaterial) * 100).toFixed(1)}%</span>
                    </div>
                  </>
                )}
              </div>

              {/* Resultado Final */}
              <div className="bg-gradient-to-br from-green-50 to-emerald-50 rounded-lg p-4 border-2 border-green-300">
                <div className="text-center">
                  <p className="text-green-700 text-sm mb-1">Costo de la pieza</p>
                  <p className="text-green-900 text-3xl">${costoPieza.toFixed(2)}</p>
                  <p className="text-green-600 text-xs mt-1">
                    {areaPieza > 0 ? `${areaPieza.toFixed(2)} cm² × $${precioPorCm2.toFixed(4)}` : 'Ingresa las dimensiones'}
                  </p>
                </div>

                <div className="flex gap-2 mt-3">
                  {onAplicarCosto && (
                    <Button
                      onClick={handleAplicarCosto}
                      disabled={costoPieza === 0}
                      className="flex-1 bg-green-600 hover:bg-green-700 text-white"
                      size="sm"
                    >
                      <ArrowRight className="w-4 h-4 mr-1" />
                      Aplicar a Costo
                    </Button>
                  )}
                  <Button
                    onClick={handleCopiarCosto}
                    disabled={costoPieza === 0}
                    variant="outline"
                    className="border-green-300 text-green-700 hover:bg-green-50"
                    size="sm"
                  >
                    <Copy className="w-4 h-4" />
                  </Button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Información adicional */}
      <div className="mt-4 space-y-2">
        <div className="bg-white/70 rounded-lg p-3 border border-blue-200">
          <p className="text-xs text-blue-700">
            💡 <strong>Tip:</strong> Esta calculadora te ayuda a determinar el costo de material basado en área. 
            El número de piezas posibles es una estimación ideal sin considerar desperdicios de corte.
          </p>
        </div>
        
        <div className="bg-amber-50 rounded-lg p-3 border border-amber-200">
          <p className="text-xs text-amber-800">
            <strong>Ejemplo:</strong> Compras vinil de 60cm × 100cm por $145. Un logo de 12cm × 12cm cuesta $3.48 
            (144 cm² × $0.0242 por cm²). Puedes sacar aproximadamente 41 logos de ese material.
          </p>
        </div>
      </div>
    </Card>
  );
}
