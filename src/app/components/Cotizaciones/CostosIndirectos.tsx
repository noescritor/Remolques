import { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '../ui/card';
import { Input } from '../ui/input';
import { Label } from '../ui/label';
import { Button } from '../ui/button';
import { Collapsible, CollapsibleContent, CollapsibleTrigger } from '../ui/collapsible';
import { ChevronDown, ChevronUp, DollarSign, CreditCard } from 'lucide-react';
import { formatearMoneda } from '../../utils/calculations';
import { CostosIndirectos as TipoCostosIndirectos, ComisionesPago } from '../../types';

interface CostosIndirectosProps {
  costosIndirectos: TipoCostosIndirectos;
  comisionesPago: ComisionesPago;
  onCostosChange: (costos: TipoCostosIndirectos) => void;
  onComisionesChange: (comisiones: ComisionesPago) => void;
  subtotal: number;
}

export function CostosIndirectos({
  costosIndirectos,
  comisionesPago,
  onCostosChange,
  onComisionesChange,
  subtotal
}: CostosIndirectosProps) {
  const [isOpen, setIsOpen] = useState(false);

  const handleCostoChange = (field: keyof TipoCostosIndirectos, value: string) => {
    const numericValue = parseFloat(value) || 0;
    onCostosChange({
      ...costosIndirectos,
      [field]: numericValue
    });
  };

  const handleComisionChange = (field: keyof ComisionesPago, value: string) => {
    const numericValue = parseFloat(value) || 0;
    onComisionesChange({
      ...comisionesPago,
      [field]: numericValue
    });
  };

  // Calcular totales
  const totalCostosIndirectos = Object.values(costosIndirectos).reduce((sum, val) => sum + (val || 0), 0);
  const comisionPorcentaje = subtotal * ((comisionesPago.porcentaje || 0) / 100);
  const totalComisiones = comisionPorcentaje + (comisionesPago.fijo || 0);
  const granTotal = totalCostosIndirectos + totalComisiones;

  return (
    <Card>
      <Collapsible open={isOpen} onOpenChange={setIsOpen}>
        <CollapsibleTrigger asChild>
          <CardHeader className="cursor-pointer hover:bg-muted/50 transition-colors">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <CardTitle className="text-lg">Costos Indirectos y Comisiones</CardTitle>
                <div className="text-sm text-muted-foreground font-normal">
                  Total: {formatearMoneda(granTotal)}
                </div>
              </div>
              {isOpen ? <ChevronUp className="h-4 w-4" /> : <ChevronDown className="h-4 w-4" />}
            </div>
          </CardHeader>
        </CollapsibleTrigger>
        
        <CollapsibleContent>
          <CardContent className="pt-0">
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
              {/* Costos Indirectos */}
              <div className="space-y-4">
                <div className="flex items-center gap-2 mb-3">
                  <DollarSign className="h-4 w-4" />
                  <h4 className="font-medium">Costos Indirectos</h4>
                  <span className="text-sm text-muted-foreground">
                    {formatearMoneda(totalCostosIndirectos)}
                  </span>
                </div>

                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <Label className="text-sm">Mano de Obra</Label>
                    <Input
                      type="number"
                      step="0.01"
                      min="0"
                      value={costosIndirectos.mano_obra || ''}
                      onChange={(e) => handleCostoChange('mano_obra', e.target.value)}
                      placeholder="0.00"
                    />
                  </div>

                  <div>
                    <Label className="text-sm">Insumos/DTF</Label>
                    <Input
                      type="number"
                      step="0.01"
                      min="0"
                      value={costosIndirectos.insumos_dtf || ''}
                      onChange={(e) => handleCostoChange('insumos_dtf', e.target.value)}
                      placeholder="0.00"
                    />
                  </div>

                  <div>
                    <Label className="text-sm">Empaque</Label>
                    <Input
                      type="number"
                      step="0.01"
                      min="0"
                      value={costosIndirectos.empaque || ''}
                      onChange={(e) => handleCostoChange('empaque', e.target.value)}
                      placeholder="0.00"
                    />
                  </div>

                  <div>
                    <Label className="text-sm">Mermas</Label>
                    <Input
                      type="number"
                      step="0.01"
                      min="0"
                      value={costosIndirectos.mermas || ''}
                      onChange={(e) => handleCostoChange('mermas', e.target.value)}
                      placeholder="0.00"
                    />
                  </div>

                  <div>
                    <Label className="text-sm">Envío</Label>
                    <Input
                      type="number"
                      step="0.01"
                      min="0"
                      value={costosIndirectos.envio || ''}
                      onChange={(e) => handleCostoChange('envio', e.target.value)}
                      placeholder="0.00"
                    />
                  </div>

                  <div>
                    <Label className="text-sm">Otros</Label>
                    <Input
                      type="number"
                      step="0.01"
                      min="0"
                      value={costosIndirectos.otros || ''}
                      onChange={(e) => handleCostoChange('otros', e.target.value)}
                      placeholder="0.00"
                    />
                  </div>
                </div>
              </div>

              {/* Comisiones de Pago */}
              <div className="space-y-4">
                <div className="flex items-center gap-2 mb-3">
                  <CreditCard className="h-4 w-4" />
                  <h4 className="font-medium">Comisiones de Pago</h4>
                  <span className="text-sm text-muted-foreground">
                    {formatearMoneda(totalComisiones)}
                  </span>
                </div>

                <div className="space-y-3">
                  <div>
                    <Label className="text-sm">Porcentaje (%)</Label>
                    <Input
                      type="number"
                      step="0.01"
                      min="0"
                      max="100"
                      value={comisionesPago.porcentaje || ''}
                      onChange={(e) => handleComisionChange('porcentaje', e.target.value)}
                      placeholder="0.00"
                    />
                    <p className="text-xs text-muted-foreground mt-1">
                      Equivale a: {formatearMoneda(comisionPorcentaje)}
                    </p>
                  </div>

                  <div>
                    <Label className="text-sm">Comisión Fija</Label>
                    <Input
                      type="number"
                      step="0.01"
                      min="0"
                      value={comisionesPago.fijo || ''}
                      onChange={(e) => handleComisionChange('fijo', e.target.value)}
                      placeholder="0.00"
                    />
                  </div>
                </div>

                <div className="pt-3 border-t">
                  <div className="flex justify-between font-medium">
                    <span>Total Comisiones:</span>
                    <span>{formatearMoneda(totalComisiones)}</span>
                  </div>
                </div>
              </div>
            </div>

            <div className="mt-6 pt-4 border-t bg-muted/20 p-4 rounded-lg">
              <div className="flex justify-between items-center font-semibold text-lg">
                <span>Total Costos Indirectos + Comisiones:</span>
                <span className="text-destructive">{formatearMoneda(granTotal)}</span>
              </div>
            </div>
          </CardContent>
        </CollapsibleContent>
      </Collapsible>
    </Card>
  );
}