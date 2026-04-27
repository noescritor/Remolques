import { useState } from 'react';
import { Button } from '../ui/button';
import { Input } from '../ui/input';
import { Label } from '../ui/label';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from '../ui/dialog';
import { Card, CardContent } from '../ui/card';
import { Target, Calculator } from 'lucide-react';
import { formatearMoneda, calcularPrecioObjetivo } from '../../utils/calculations';

interface PrecioObjetivoProps {
  costoUnitario: number;
  onPrecioCalculado: (precio: number) => void;
}

export function PrecioObjetivo({ costoUnitario, onPrecioCalculado }: PrecioObjetivoProps) {
  const [margenDeseado, setMargenDeseado] = useState<string>('30');
  const [open, setOpen] = useState(false);

  const calcularPrecio = () => {
    const margen = parseFloat(margenDeseado) || 0;
    if (margen >= 0 && margen < 100 && costoUnitario > 0) {
      const precioCalculado = calcularPrecioObjetivo(costoUnitario, margen);
      onPrecioCalculado(precioCalculado);
      setOpen(false);
    }
  };

  const precioCalculado = calcularPrecioObjetivo(costoUnitario, parseFloat(margenDeseado) || 0);
  const utilidadUnitaria = precioCalculado - costoUnitario;

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>
        <Button
          variant="outline"
          size="sm"
          className="gap-2"
          disabled={costoUnitario <= 0}
        >
          <Target className="h-4 w-4" />
          Precio Objetivo
        </Button>
      </DialogTrigger>
      
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <Calculator className="h-5 w-5" />
            Calculadora de Precio Objetivo
          </DialogTitle>
        </DialogHeader>
        
        <div className="space-y-4">
          <Card>
            <CardContent className="p-4">
              <div className="grid grid-cols-2 gap-4 text-sm">
                <div>
                  <span className="text-muted-foreground">Costo Unitario:</span>
                  <div className="font-medium">{formatearMoneda(costoUnitario)}</div>
                </div>
                <div>
                  <span className="text-muted-foreground">Margen Deseado:</span>
                  <div className="font-medium">{margenDeseado}%</div>
                </div>
              </div>
            </CardContent>
          </Card>

          <div>
            <Label htmlFor="margen">Margen de Utilidad Deseado (%)</Label>
            <Input
              id="margen"
              type="number"
              min="0"
              max="99"
              step="0.1"
              value={margenDeseado}
              onChange={(e) => setMargenDeseado(e.target.value)}
              placeholder="30"
            />
            <p className="text-xs text-muted-foreground mt-1">
              Ingresa el porcentaje de margen que deseas obtener
            </p>
          </div>

          {parseFloat(margenDeseado) > 0 && costoUnitario > 0 && (
            <Card className="bg-green-50 border-green-200">
              <CardContent className="p-4">
                <div className="space-y-2">
                  <div className="flex justify-between items-center">
                    <span className="font-medium">Precio Sugerido:</span>
                    <span className="text-lg font-bold text-green-600">
                      {formatearMoneda(precioCalculado)}
                    </span>
                  </div>
                  <div className="flex justify-between items-center text-sm">
                    <span className="text-muted-foreground">Utilidad por unidad:</span>
                    <span className="font-medium text-green-600">
                      {formatearMoneda(utilidadUnitaria)}
                    </span>
                  </div>
                </div>
              </CardContent>
            </Card>
          )}

          <div className="flex gap-3">
            <Button variant="outline" onClick={() => setOpen(false)} className="flex-1">
              Cancelar
            </Button>
            <Button 
              onClick={calcularPrecio} 
              className="flex-1"
              disabled={parseFloat(margenDeseado) <= 0 || parseFloat(margenDeseado) >= 100 || costoUnitario <= 0}
            >
              Aplicar Precio
            </Button>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
}