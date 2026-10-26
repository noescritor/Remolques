import React, { useState, useEffect, useCallback } from 'react';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '../ui/card';
import { Input } from '../ui/input';
import { Label } from '../ui/label';
import { Button } from '../ui/button';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../ui/select';
import { Switch } from '../ui/switch';
import { Tabs, TabsList, TabsTrigger, TabsContent } from '../ui/tabs';
import {
  Calculator,
  Copy,
  ArrowRight,
  Truck,
  RefreshCw,
  Wrench,
  Layers,
  GitCompare,
  Building2,
} from 'lucide-react';
import { toast } from 'sonner';
import { CosteoPlaca } from './CosteoPlaca';
import { ComparadorAcero } from './ComparadorAcero';
import { PreciosAcero } from './PreciosAcero';
import { supabase } from '../../utils/supabase/client';
import { fetchCatalogoAcero } from '../../utils/aceroApi';
import { AceroMaterialItem } from '../../../../supabase/functions/make-server-feea4382/motor/acero';

type TipoRemolque = 'Cama Baja' | 'Ganadero' | 'Caja Cerrada' | 'Cuello de Ganso';
type CapacidadEje = '3500' | '5200' | '7000' | '10000';
type TipoPiso = 'Madera de Pino' | 'Placa de Acero';

/**
 * Pestaña 1: Estimador rápido original de remolques (conservado intacto).
 */
function EstimadorRapido() {
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
    if (frenosElectricos) costoAccesorios += ejes * 1200; // Módulo por eje
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
      precio = totalCosto / (1 - margen / 100);
    }
    setPrecioSugerido(precio);
    setUtilidad(precio - totalCosto);
  }, [
    tipoRemolque,
    longitud,
    numEjes,
    capacidadEje,
    tipoPiso,
    llantaRefaccion,
    frenosElectricos,
    rampas,
    margenDeseado,
  ]);

  const handleCopiarCotizacion = async () => {
    const texto = `Cotización Estimada:\nRemolque ${tipoRemolque} de ${longitud}ft\n${numEjes} Eje(s) de ${capacidadEje} lbs\nPiso: ${tipoPiso}\nPrecio Estimado: $${precioSugerido.toLocaleString('es-MX', { minimumFractionDigits: 2 })}`;
    try {
      await navigator.clipboard.writeText(texto);
      toast.success('Resumen copiado al portapapeles');
    } catch (_err) {
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
    <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
      {/* Lado Izquierdo: Formulario */}
      <div className="space-y-6">
        <Card className="bg-card/50 border-border/50">
          <CardHeader className="pb-3 border-b border-border/50">
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
                    <SelectItem value="Cama Baja">Cama Baja (Plataforma)</SelectItem>
                    <SelectItem value="Ganadero">Ganadero (Con Redilas)</SelectItem>
                    <SelectItem value="Caja Cerrada">Caja Cerrada (Seca)</SelectItem>
                    <SelectItem value="Cuello de Ganso">Cuello de Ganso (Pesado)</SelectItem>
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
                <Label>Número de Ejes</Label>
                <Select value={numEjes} onValueChange={setNumEjes}>
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="1">1 Eje</SelectItem>
                    <SelectItem value="2">2 Ejes (Tándem)</SelectItem>
                    <SelectItem value="3">3 Ejes (Triple)</SelectItem>
                  </SelectContent>
                </Select>
              </div>

              <div className="space-y-2">
                <Label>Capacidad por Eje (Lbs)</Label>
                <Select value={capacidadEje} onValueChange={(v: CapacidadEje) => setCapacidadEje(v)}>
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="3500">3,500 lbs (Ligero)</SelectItem>
                    <SelectItem value="5200">5,200 lbs (Mediano)</SelectItem>
                    <SelectItem value="7000">7,000 lbs (Pesado)</SelectItem>
                    <SelectItem value="10000">10,000 lbs (Extrapesado)</SelectItem>
                  </SelectContent>
                </Select>
              </div>

              <div className="space-y-2">
                <Label>Tipo de Piso</Label>
                <Select value={tipoPiso} onValueChange={(v: TipoPiso) => setTipoPiso(v)}>
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="Madera de Pino">Madera de Pino Tratada</SelectItem>
                    <SelectItem value="Placa de Acero">Placa de Acero Antiderrapante</SelectItem>
                  </SelectContent>
                </Select>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card className="bg-card/50 border-border/50">
          <CardHeader className="pb-3 border-b border-border/50">
            <div className="flex items-center gap-2">
              <div className="w-8 h-8 rounded-full bg-accent-blue/10 flex items-center justify-center">
                <Wrench className="w-4 h-4 text-accent-blue" />
              </div>
              <div>
                <CardTitle className="text-lg">Accesorios y Extras</CardTitle>
                <CardDescription>Equipamiento adicional</CardDescription>
              </div>
            </div>
          </CardHeader>
          <CardContent className="pt-6 space-y-4">
            <div className="flex items-center justify-between">
              <div className="space-y-0.5">
                <Label>Llanta de Refacción</Label>
                <p className="text-xs text-muted-foreground">Incluye soporte y rin con llanta montada</p>
              </div>
              <Switch checked={llantaRefaccion} onCheckedChange={setLlantaRefaccion} />
            </div>

            <div className="flex items-center justify-between">
              <div className="space-y-0.5">
                <Label>Frenos Eléctricos</Label>
                <p className="text-xs text-muted-foreground">En todos los ejes para mayor seguridad</p>
              </div>
              <Switch checked={frenosElectricos} onCheckedChange={setFrenosElectricos} />
            </div>

            <div className="flex items-center justify-between">
              <div className="space-y-0.5">
                <Label>Rampas de Carga Traseras</Label>
                <p className="text-xs text-muted-foreground">Rampas abatibles de acero reforzado</p>
              </div>
              <Switch checked={rampas} onCheckedChange={setRampas} />
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Lado Derecho: Resultados y Métricas */}
      <div className="space-y-6">
        <Card className="bg-card/50 border-border/50">
          <CardHeader className="pb-3 border-b border-border/50">
            <CardTitle className="text-lg">Desglose de Costos de Fabricación</CardTitle>
            <CardDescription>Cálculo estimado interno</CardDescription>
          </CardHeader>
          <CardContent className="pt-6 space-y-4">
            <div className="space-y-3">
              <div className="flex justify-between items-center text-sm">
                <span className="text-muted-foreground">Materiales y Componentes</span>
                <span className="font-mono font-medium">${costoMateriales.toLocaleString('es-MX', { minimumFractionDigits: 2 })}</span>
              </div>
              <div className="flex justify-between items-center text-sm">
                <span className="text-muted-foreground">Mano de Obra y Ensamble</span>
                <span className="font-mono font-medium">${costoManoObra.toLocaleString('es-MX', { minimumFractionDigits: 2 })}</span>
              </div>
              <div className="h-[1px] bg-border/50 my-2" />
              <div className="flex justify-between items-center text-base font-semibold">
                <span>Costo Total Directo</span>
                <span className="font-mono text-accent-blue">${costoTotal.toLocaleString('es-MX', { minimumFractionDigits: 2 })}</span>
              </div>
            </div>

            <div className="pt-4 border-t border-border/50">
              <div className="space-y-2">
                <Label>Margen de Ganancia Deseado (%)</Label>
                <div className="flex items-center gap-3">
                  <Input
                    type="number"
                    value={margenDeseado}
                    onChange={(e) => setMargenDeseado(e.target.value)}
                    className="w-32"
                  />
                  <span className="text-sm text-muted-foreground">
                    Utilidad: ${utilidad.toLocaleString('es-MX', { minimumFractionDigits: 2 })}
                  </span>
                </div>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Tarjeta de Precio Sugerido */}
        <Card className="border-accent-blue/30 bg-accent-blue/5">
          <CardContent className="pt-6 space-y-4">
            <div className="flex justify-between items-start">
              <div>
                <span className="text-xs uppercase tracking-wider text-muted-foreground font-semibold">
                  Precio Sugerido al Cliente
                </span>
                <div className="text-3xl font-extrabold text-foreground font-mono mt-1">
                  ${precioSugerido.toLocaleString('es-MX', { minimumFractionDigits: 2 })}
                </div>
                <span className="text-xs text-muted-foreground">Antes de IVA</span>
              </div>
              <div className="px-2.5 py-1 bg-accent-blue/10 text-accent-blue rounded-full text-xs font-semibold">
                Margen {margenDeseado}%
              </div>
            </div>

            <div className="pt-2 flex flex-col sm:flex-row gap-2">
              <Button className="w-full bg-accent-blue hover:bg-accent-blue/90 text-white" onClick={handleCopiarCotizacion}>
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
  );
}

export function CalculadoraPage() {
  const [materiales, setMateriales] = useState<AceroMaterialItem[]>([]);
  const [proveedores, setProveedores] = useState<string[]>([]);
  const [loading, setLoading] = useState<boolean>(true);

  const cargarCatalogo = useCallback(async () => {
    try {
      setLoading(true);
      const data = await fetchCatalogoAcero(supabase);
      setMateriales(data.materiales || []);
      setProveedores(data.proveedores || []);
    } catch (err: any) {
      console.error('[CalculadoraPage] Error cargando catálogo de acero:', err);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    cargarCatalogo();
  }, [cargarCatalogo]);

  return (
    <div className="space-y-6 pb-20">
      <div>
        <h1 className="text-3xl font-bold font-sans flex items-center gap-2">
          <Calculator className="h-8 w-8 text-accent-blue" />
          Calculadoras y Precios de Acero
        </h1>
        <p className="text-muted-foreground mt-1">
          Estimador rápido de remolques, costeo de piezas de placa/lámina y comparador de proveedores de acero.
        </p>
      </div>

      <Tabs defaultValue="estimador" className="space-y-6">
        <TabsList className="bg-muted p-1 rounded-xl flex-wrap h-auto gap-1">
          <TabsTrigger value="estimador" className="text-xs sm:text-sm gap-1.5 py-1.5 px-3">
            <Truck className="h-4 w-4" />
            Estimador rápido
          </TabsTrigger>
          <TabsTrigger value="placa" className="text-xs sm:text-sm gap-1.5 py-1.5 px-3">
            <Layers className="h-4 w-4" />
            Costeo de placa
          </TabsTrigger>
          <TabsTrigger value="comparador" className="text-xs sm:text-sm gap-1.5 py-1.5 px-3">
            <GitCompare className="h-4 w-4" />
            Comparador de acero
          </TabsTrigger>
          <TabsTrigger value="precios" className="text-xs sm:text-sm gap-1.5 py-1.5 px-3">
            <Building2 className="h-4 w-4" />
            Precios de acero
          </TabsTrigger>
        </TabsList>

        <TabsContent value="estimador" className="space-y-6">
          <EstimadorRapido />
        </TabsContent>

        <TabsContent value="placa" className="space-y-6">
          <CosteoPlaca
            materiales={materiales}
            proveedores={proveedores}
            loading={loading}
            onRecargar={cargarCatalogo}
          />
        </TabsContent>

        <TabsContent value="comparador" className="space-y-6">
          <ComparadorAcero
            materiales={materiales}
            proveedores={proveedores}
            loading={loading}
            onRecargar={cargarCatalogo}
          />
        </TabsContent>

        <TabsContent value="precios" className="space-y-6">
          <PreciosAcero
            materiales={materiales}
            proveedores={proveedores}
            supabase={supabase}
            loading={loading}
            onRecargar={cargarCatalogo}
          />
        </TabsContent>
      </Tabs>
    </div>
  );
}
