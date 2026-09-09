import { useState, useEffect } from 'react';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '../ui/card';
import { Input } from '../ui/input';
import { Label } from '../ui/label';
import { Button } from '../ui/button';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../ui/select';
import { Switch } from '../ui/switch';
import { Calculator, Copy, ArrowRight, Truck, RefreshCw, Wrench } from 'lucide-react';
import { toast } from "sonner";

type TipoRemolque = 'Cama Baja' | 'Ganadero' | 'Caja Cerrada' | 'Cuello de Ganso';
type CapacidadEje = '3500' | '5200' | '7000' | '10000';
type TipoPiso = 'Madera de Pino' | 'Placa de Acero';

export function CalculadoraPage() {
  // Configuración del Remolque
  const [tipoRemolque, setTipoRemolque] = useState<TipoRemolque>('Cama Baja');
  const [longitud, setLongitud] = useState<string>('16'); // pies
  const [numEjes, setNumEjes] = useState<string>('2');
  const [capacidadEje, setCapacidadEje] = useState<CapacidadEje>('3500');
  const [tipoPiso, setTipoPiso] = useState<TipoPiso>('Madera de Pino');
  
  // Accesorios
  const [llantaRefaccion, setLlantaRefaccion] = useState<boolean>(true);
  const [frenosElectricos, setFrenosElectricos] = useState<boolean>(true);
  const [rampas, setRampas] = useState<boolean>(false);
  
  // Finanzas
  const [margenDeseado, setMargenDeseado] = useState<string>('30'); // %

  // Resultados
  const [costoMateriales, setCostoMateriales] = useState<number>(0);
  const [costoManoObra, setCostoManoObra] = useState<number>(0);
  const [costoTotal, setCostoTotal] = useState<number>(0);
  const [precioSugerido, setPrecioSugerido] = useState<number>(0);
  const [utilidad, setUtilidad] = useState<number>(0);

  // Calcular resultados
  useEffect(() => {
    const long = parseFloat(longitud) || 0;
    const ejes = parseInt(numEjes) || 0;
    
    // 1. Costo Base Estructural (Acero principal) basado en longitud y tipo
    let costoBaseAcero = long * 1200; // $1,200 MXN por pie lineal
    if (tipoRemolque === 'Ganadero') costoBaseAcero *= 1.3; // Más acero para las redilas
    if (tipoRemolque === 'Caja Cerrada') costoBaseAcero *= 1.5; // Estructura completa
    if (tipoRemolque === 'Cuello de Ganso') costoBaseAcero *= 1.4; // Estructura reforzada

    // 2. Costo de Ejes y Suspensión
    let costoPorEje = 0;
    if (capacidadEje === '3500') costoPorEje = 3500;
    if (capacidadEje === '5200') costoPorEje = 5500;
    if (capacidadEje === '7000') costoPorEje = 8000;
    if (capacidadEje === '10000') costoPorEje = 15000;
    const costoEjes = ejes * costoPorEje;

    // 3. Costo de Llantas y Rines (2 por eje)
    const costoLlantas = ejes * 2 * 1500; 

    // 4. Costo de Piso
    let costoPiso = 0;
    if (tipoPiso === 'Madera de Pino') costoPiso = long * 250; // $250 por pie
    if (tipoPiso === 'Placa de Acero') costoPiso = long * 600; // $600 por pie

    // 5. Costo de Accesorios
    let costoAccesorios = 0;
    if (llantaRefaccion) costoAccesorios += 1800;
    if (frenosElectricos) costoAccesorios += (ejes * 1200); // Módulo por eje
    if (rampas) costoAccesorios += 3500;

    // Consolidar Materiales
    const totalMateriales = costoBaseAcero + costoEjes + costoLlantas + costoPiso + costoAccesorios;
    setCostoMateriales(totalMateriales);

    // Mano de Obra (Aprox 30% del costo de materiales, o fijo por tipo/pie)
    let manoObra = long * 500; // $500 por pie
    if (tipoRemolque === 'Caja Cerrada' || tipoRemolque === 'Ganadero') manoObra *= 1.4;
    setCostoManoObra(manoObra);

    // Costo Total
    const totalCosto = totalMateriales + manoObra;
    setCostoTotal(totalCosto);

    // Precio Sugerido (Fórmula de margen: Precio = Costo / (1 - Margen%))
    const margen = parseFloat(margenDeseado) || 0;
    let precio = totalCosto;
    if (margen > 0 && margen < 100) {
      precio = totalCosto / (1 - (margen / 100));
    }
    setPrecioSugerido(precio);
    setUtilidad(precio - totalCosto);

  }, [tipoRemolque, longitud, numEjes, capacidadEje, tipoPiso, llantaRefaccion, frenosElectricos, rampas, margenDeseado]);

  const handleCopiarCotizacion = async () => {
    const texto = `Cotización Estimada:\nRemolque ${tipoRemolque} de ${longitud}ft\n${numEjes} Eje(s) de ${capacidadEje} lbs\nPiso: ${tipoPiso}\nPrecio Estimado: $${precioSugerido.toLocaleString('es-MX', { minimumFractionDigits: 2 })}`;
    try {
      await navigator.clipboard.writeText(texto);
      toast.success('Resumen copiado al portapapeles');
    } catch (err) {
      toast.error('Error al copiar al portapapeles');
    }
  };

  const handleReset = () => {
    setTipoRemolque('Cama Baja');
    setLongitud('16');
    setNumEjes('2');
    setCapacidadEje('3500');
    setTipoPiso('Madera de Pino');
    setLlantaRefaccion(true);
    setFrenosElectricos(true);
    setRampas(false);
    setMargenDeseado('30');
  };

  return (
    <div className="space-y-6 pb-20">
      <div>
        <h1 className="text-3xl font-bold font-sans flex items-center gap-2">
          <Calculator className="h-8 w-8 text-accent-blue" />
          Calculadora de Remolques
        </h1>
        <p className="text-muted-foreground mt-1">Estima los costos de fabricación y obtén el precio sugerido de venta.</p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        
        {/* Lado Izquierdo: Formulario */}
        <div className="space-y-6">
          <Card className="bg-white/[0.02] border-white/[0.06]">
            <CardHeader className="pb-3 border-b border-white/[0.06]">
              <div className="flex items-center gap-2">
                <div className="w-8 h-8 rounded-full bg-accent-blue/10 flex items-center justify-center">
                  <Truck className="w-4 h-4 text-accent-blue" />
                </div>
                <div>
                  <CardTitle className="text-lg">Configuración Principal</CardTitle>
                  <CardDescription>Especificaciones base del remolque</CardDescription>
                </div>
              </div>
            </CardHeader>
            <CardContent className="pt-6">
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div className="space-y-2 sm:col-span-2">
                  <Label>Tipo de Remolque</Label>
                  <Select value={tipoRemolque} onValueChange={(v: TipoRemolque) => setTipoRemolque(v)}>
                    <SelectTrigger>
                      <SelectValue placeholder="Seleccionar tipo" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="Cama Baja">Cama Baja / Utilitario</SelectItem>
                      <SelectItem value="Ganadero">Ganadero</SelectItem>
                      <SelectItem value="Caja Cerrada">Caja Cerrada</SelectItem>
                      <SelectItem value="Cuello de Ganso">Cuello de Ganso (Heavy Duty)</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
                
                <div className="space-y-2">
                  <Label>Longitud (Pies)</Label>
                  <Input 
                    type="number" 
                    value={longitud} 
                    onChange={(e) => setLongitud(e.target.value)}
                    placeholder="Ej. 16"
                  />
                </div>
                
                <div className="space-y-2">
                  <Label>Tipo de Piso</Label>
                  <Select value={tipoPiso} onValueChange={(v: TipoPiso) => setTipoPiso(v)}>
                    <SelectTrigger>
                      <SelectValue placeholder="Seleccionar piso" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="Madera de Pino">Madera de Pino Tratada</SelectItem>
                      <SelectItem value="Placa de Acero">Placa de Acero Antideslizante</SelectItem>
                    </SelectContent>
                  </Select>
                </div>

                <div className="space-y-2">
                  <Label>Número de Ejes</Label>
                  <Select value={numEjes} onValueChange={setNumEjes}>
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="1">1 Eje</SelectItem>
                      <SelectItem value="2">2 Ejes</SelectItem>
                      <SelectItem value="3">3 Ejes</SelectItem>
                    </SelectContent>
                  </Select>
                </div>

                <div className="space-y-2">
                  <Label>Capacidad por Eje</Label>
                  <Select value={capacidadEje} onValueChange={(v: CapacidadEje) => setCapacidadEje(v)}>
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="3500">3,500 lbs</SelectItem>
                      <SelectItem value="5200">5,200 lbs</SelectItem>
                      <SelectItem value="7000">7,000 lbs</SelectItem>
                      <SelectItem value="10000">10,000 lbs Dually</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
              </div>
            </CardContent>
          </Card>

          <Card className="bg-white/[0.02] border-white/[0.06]">
            <CardHeader className="pb-3 border-b border-white/[0.06]">
              <div className="flex items-center gap-2">
                <div className="w-8 h-8 rounded-full bg-accent-green/10 flex items-center justify-center">
                  <Wrench className="w-4 h-4 text-accent-green" />
                </div>
                <div>
                  <CardTitle className="text-lg">Accesorios y Extras</CardTitle>
                  <CardDescription>Opciones adicionales para el cliente</CardDescription>
                </div>
              </div>
            </CardHeader>
            <CardContent className="pt-6 space-y-4">
              <div className="flex items-center justify-between">
                <div className="space-y-0.5">
                  <Label className="text-base">Llanta de Refacción</Label>
                  <p className="text-sm text-muted-foreground">Incluye rin, llanta y base soldada.</p>
                </div>
                <Switch checked={llantaRefaccion} onCheckedChange={setLlantaRefaccion} />
              </div>
              <div className="flex items-center justify-between">
                <div className="space-y-0.5">
                  <Label className="text-base">Frenos Eléctricos</Label>
                  <p className="text-sm text-muted-foreground">Módulo de frenado instalado por eje.</p>
                </div>
                <Switch checked={frenosElectricos} onCheckedChange={setFrenosElectricos} />
              </div>
              <div className="flex items-center justify-between">
                <div className="space-y-0.5">
                  <Label className="text-base">Rampas de Carga</Label>
                  <p className="text-sm text-muted-foreground">Rampas traseras ocultas o abatibles.</p>
                </div>
                <Switch checked={rampas} onCheckedChange={setRampas} />
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Lado Derecho: Resultados */}
        <div className="space-y-6">
          <Card className="bg-white/[0.02] border-white/[0.06] h-full flex flex-col">
            <CardHeader className="pb-4 border-b border-white/[0.06] flex flex-row items-center justify-between">
              <CardTitle className="text-xl">Análisis de Costos</CardTitle>
              <div className="flex items-center gap-2">
                <Label>Margen:</Label>
                <div className="relative w-20">
                  <Input 
                    type="number" 
                    value={margenDeseado} 
                    onChange={(e) => setMargenDeseado(e.target.value)}
                    className="pr-6 h-8"
                  />
                  <span className="absolute right-2 top-1.5 text-sm text-muted-foreground">%</span>
                </div>
              </div>
            </CardHeader>
            <CardContent className="flex-1 flex flex-col gap-6 pt-6">
              
              <div className="grid grid-cols-2 gap-4">
                <div className="p-4 rounded-lg bg-black/40 border border-white/5">
                  <p className="text-xs text-muted-foreground uppercase tracking-wider mb-1">Costo Materiales</p>
                  <p className="text-lg font-mono">${costoMateriales.toLocaleString('es-MX', { minimumFractionDigits: 2 })}</p>
                </div>
                <div className="p-4 rounded-lg bg-black/40 border border-white/5">
                  <p className="text-xs text-muted-foreground uppercase tracking-wider mb-1">Mano de Obra (Est.)</p>
                  <p className="text-lg font-mono">${costoManoObra.toLocaleString('es-MX', { minimumFractionDigits: 2 })}</p>
                </div>
              </div>

              <div className="flex items-center justify-between p-4 rounded-lg bg-white/[0.02] border border-white/[0.06]">
                <span className="font-medium">Costo de Producción Total</span>
                <span className="text-xl font-mono">${costoTotal.toLocaleString('es-MX', { minimumFractionDigits: 2 })}</span>
              </div>

              <div className="p-6 rounded-xl bg-accent-blue/5 border border-accent-blue/20 flex flex-col items-center justify-center text-center mt-auto">
                <p className="text-sm text-accent-blue/80 uppercase tracking-widest font-mono mb-2">Precio Sugerido Venta</p>
                <div className="flex items-center gap-2">
                  <span className="text-5xl font-bold font-mono text-white">${precioSugerido.toLocaleString('es-MX', { minimumFractionDigits: 2 })}</span>
                </div>
                <p className="text-sm text-accent-green mt-3">Utilidad Proyectada: ${utilidad.toLocaleString('es-MX', { minimumFractionDigits: 2 })}</p>
                
                <Button 
                  className="mt-6 bg-accent-blue text-black hover:bg-accent-blue/90 w-full" 
                  onClick={handleCopiarCotizacion}
                >
                  <Copy className="w-4 h-4 mr-2" /> Copiar Resumen
                </Button>
              </div>

              <Button variant="outline" className="w-full mt-2" onClick={handleReset}>
                <RefreshCw className="w-4 h-4 mr-2" /> Restablecer Valores
              </Button>

            </CardContent>
          </Card>
        </div>

      </div>
    </div>
  );
}
