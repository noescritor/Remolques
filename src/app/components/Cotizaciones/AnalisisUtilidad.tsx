import { Card, CardContent, CardHeader, CardTitle } from '../ui/card';
import { Badge } from '../ui/badge';
import { formatearMoneda } from '../../utils/calculations';
import { TrendingUp, TrendingDown, DollarSign, Calculator } from 'lucide-react';

interface AnalisisUtilidadProps {
  analisis: {
    ingresoSinIva: number;
    costosDirectos: number;
    costosIndirectos: number;
    comisiones: number;
    utilidadBruta: number;
    margenBruto: number;
  };
}

export function AnalisisUtilidad({ analisis }: AnalisisUtilidadProps) {
  const {
    ingresoSinIva,
    costosDirectos,
    costosIndirectos,
    comisiones,
    utilidadBruta,
    margenBruto
  } = analisis;

  const totalCostos = costosDirectos + costosIndirectos + comisiones;

  const getMargenVariant = (margen: number) => {
    if (margen >= 30) return 'default';
    if (margen >= 20) return 'secondary';
    if (margen >= 10) return 'outline';
    return 'destructive';
  };

  const getMargenIcon = (margen: number) => {
    return margen > 0 ? <TrendingUp className="h-4 w-4" /> : <TrendingDown className="h-4 w-4" />;
  };

  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
      {/* Ingresos */}
      <Card>
        <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
          <CardTitle className="text-sm font-medium">Ingresos (Sin IVA)</CardTitle>
          <DollarSign className="h-4 w-4 text-muted-foreground" />
        </CardHeader>
        <CardContent>
          <div className="text-2xl font-bold text-green-600">
            {formatearMoneda(ingresoSinIva)}
          </div>
          <p className="text-xs text-muted-foreground">
            Subtotal de venta
          </p>
        </CardContent>
      </Card>

      {/* Costos Totales */}
      <Card>
        <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
          <CardTitle className="text-sm font-medium">Costos Totales</CardTitle>
          <Calculator className="h-4 w-4 text-muted-foreground" />
        </CardHeader>
        <CardContent>
          <div className="text-2xl font-bold text-red-600">
            {formatearMoneda(totalCostos)}
          </div>
          <p className="text-xs text-muted-foreground">
            Directos: {formatearMoneda(costosDirectos)} | 
            Indirectos: {formatearMoneda(costosIndirectos + comisiones)}
          </p>
        </CardContent>
      </Card>

      {/* Utilidad Bruta */}
      <Card>
        <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
          <CardTitle className="text-sm font-medium">Utilidad Bruta</CardTitle>
          {getMargenIcon(utilidadBruta)}
        </CardHeader>
        <CardContent>
          <div className={`text-2xl font-bold ${utilidadBruta >= 0 ? 'text-green-600' : 'text-red-600'}`}>
            {formatearMoneda(utilidadBruta)}
          </div>
          <p className="text-xs text-muted-foreground">
            Ingresos - Costos totales
          </p>
        </CardContent>
      </Card>

      {/* Margen Bruto */}
      <Card>
        <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
          <CardTitle className="text-sm font-medium">Margen Bruto</CardTitle>
          <Badge variant={getMargenVariant(margenBruto)}>
            {margenBruto.toFixed(1)}%
          </Badge>
        </CardHeader>
        <CardContent>
          <div className={`text-2xl font-bold ${margenBruto >= 0 ? 'text-green-600' : 'text-red-600'}`}>
            {margenBruto.toFixed(1)}%
          </div>
          <p className="text-xs text-muted-foreground">
            Utilidad / Ingresos
          </p>
        </CardContent>
      </Card>
    </div>
  );
}