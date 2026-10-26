import React, { useState, useMemo } from 'react';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '../ui/card';
import { Input } from '../ui/input';
import { Label } from '../ui/label';
import { Button } from '../ui/button';
import { Switch } from '../ui/switch';
import { Badge } from '../ui/badge';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../ui/select';
import {
  GitCompare,
  Plus,
  Trash2,
  FileSpreadsheet,
  Award,
  AlertTriangle,
  Sparkles,
  RefreshCw,
  Search,
} from 'lucide-react';
import { toast } from 'sonner';
import {
  compararProveedores,
  RenglonComparadorInput,
  PrecioItemInput,
} from '../../utils/aceroCalc';
import { formatearMoneda } from '../../utils/calculations';
import { AceroMaterialItem } from '../../../../supabase/functions/make-server-feea4382/motor/acero';

interface ComparadorAceroProps {
  materiales: AceroMaterialItem[];
  proveedores: string[];
  loading?: boolean;
  onRecargar?: () => void;
}

interface RenglonUI {
  id: string; // key temporal para React
  materialId: string;
  cantidad: number;
}

export function ComparadorAcero({
  materiales,
  proveedores: proveedoresCatalogo,
  loading = false,
  onRecargar,
}: ComparadorAceroProps) {
  // Lista de renglones a comparar
  const [renglones, setRenglones] = useState<RenglonUI[]>([]);

  // Interruptor de IVA: true = precios ya incluyen IVA (por defecto)
  const [incluyeIva, setIncluyeIva] = useState<boolean>(true);

  // Proveedores seleccionados para comparar (por defecto todos los que tengan al menos 1 precio)
  const [proveedoresSeleccionados, setProveedoresSeleccionados] = useState<string[]>([]);

  // Inicializar proveedores seleccionados cuando carguen del catálogo
  React.useEffect(() => {
    if (proveedoresCatalogo.length > 0 && proveedoresSeleccionados.length === 0) {
      setProveedoresSeleccionados(proveedoresCatalogo);
    }
  }, [proveedoresCatalogo]);

  // Mapa rápido de materiales
  const mapaMateriales = useMemo(() => {
    const map: Record<string, AceroMaterialItem> = {};
    for (const m of materiales) {
      map[m.id] = m;
    }
    return map;
  }, [materiales]);

  // Lista plana de precios para la función pura de cálculo
  const listaPrecios = useMemo<PrecioItemInput[]>(() => {
    const list: PrecioItemInput[] = [];
    for (const m of materiales) {
      if (m.precios) {
        for (const [prov, p] of Object.entries(m.precios)) {
          if (p.precio > 0) {
            list.push({
              material_id: m.id,
              proveedor: prov,
              precio: p.precio,
              incluye_iva: p.incluye_iva,
            });
          }
        }
      }
    }
    return list;
  }, [materiales]);

  // Agregar nuevo renglón
  const handleAgregarRenglon = () => {
    const primerMaterial = materiales[0];
    if (!primerMaterial) return;
    setRenglones((prev) => [
      ...prev,
      {
        id: `renglon-${Date.now()}-${Math.random()}`,
        materialId: primerMaterial.id,
        cantidad: 1,
      },
    ]);
  };

  // Quitar renglón
  const handleQuitarRenglon = (id: string) => {
    setRenglones((prev) => prev.filter((r) => r.id !== id));
  };

  // Actualizar renglón
  const handleCambiarRenglon = (id: string, campo: 'materialId' | 'cantidad', valor: any) => {
    setRenglones((prev) =>
      prev.map((r) => (r.id === id ? { ...r, [campo]: valor } : r))
    );
  };

  // Cargar ejemplo del Excel del cliente (7 renglones exactos)
  const handleCargarEjemploExcel = () => {
    const ejemploItems = [
      { patron: 'A-572', cantidad: 7 },
      { patron: 'Solera 1/2 X 6"', cantidad: 28 },
      { patron: 'Canal "U" de 6" (15Kg)', cantidad: 14 },
      { patron: 'Canal "U" de 6" (12Kg) a 12.20m', cantidad: 4 },
      { patron: 'Solera 3/8 X 2"', cantidad: 50 },
      { patron: 'PTR de 6X2"', cantidad: 18 },
      { patron: 'PTR de 2X4" Cal. 7', cantidad: 9 },
    ];

    const nuevosRenglones: RenglonUI[] = [];
    for (const ej of ejemploItems) {
      const match = materiales.find((m) =>
        m.nombre.toLowerCase().includes(ej.patron.toLowerCase())
      );
      if (match) {
        nuevosRenglones.push({
          id: `ejemplo-${match.id}`,
          materialId: match.id,
          cantidad: ej.cantidad,
        });
      }
    }

    if (nuevosRenglones.length === 0) {
      toast.error('No se encontraron los materiales del ejemplo en el catálogo');
      return;
    }

    setRenglones(nuevosRenglones);
    toast.success(`Ejemplo cargado: ${nuevosRenglones.length} renglones del Excel`);
  };

  // Alternar selección de un proveedor
  const handleToggleProveedor = (prov: string) => {
    setProveedoresSeleccionados((prev) =>
      prev.includes(prov) ? prev.filter((p) => p !== prov) : [...prev, prov]
    );
  };

  // Ejecutar comparación pura
  const resultado = useMemo(() => {
    const inputs: RenglonComparadorInput[] = renglones.map((r) => ({
      materialId: r.materialId,
      cantidad: r.cantidad,
    }));

    return compararProveedores({
      renglones: inputs,
      precios: listaPrecios,
      incluyeIva,
      proveedores: proveedoresSeleccionados,
      catalogoMateriales: mapaMateriales,
    });
  }, [renglones, listaPrecios, incluyeIva, proveedoresSeleccionados, mapaMateriales]);

  return (
    <div className="space-y-6">
      {/* Encabezado */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h2 className="text-xl font-bold font-sans flex items-center gap-2 text-foreground">
            <GitCompare className="h-5 w-5 text-accent-blue" />
            Comparador de Precios de Acero por Proveedor
          </h2>
          <p className="text-sm text-muted-foreground mt-0.5">
            Compara listas de materiales y cantidades entre proveedores para encontrar la mejor opción o una compra mixta óptima.
          </p>
        </div>

        <div className="flex flex-wrap items-center gap-2">
          <Button
            variant="outline"
            size="sm"
            onClick={handleCargarEjemploExcel}
            className="text-xs gap-1.5 border-accent-blue/30 text-accent-blue hover:bg-accent-blue/10"
          >
            <FileSpreadsheet className="h-4 w-4" />
            Cargar ejemplo del Excel
          </Button>
          {onRecargar && (
            <Button
              variant="outline"
              size="sm"
              onClick={onRecargar}
              disabled={loading}
              className="gap-1.5 text-xs"
            >
              <RefreshCw className={`h-4 w-4 ${loading ? 'animate-spin' : ''}`} />
              Actualizar
            </Button>
          )}
        </div>
      </div>

      {/* Barra de Controles: IVA y Proveedores */}
      <Card className="border-border bg-card">
        <CardContent className="pt-4 pb-4">
          <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
            {/* Switch de IVA */}
            <div className="flex items-center gap-3">
              <Switch
                id="iva-switch"
                checked={incluyeIva}
                onCheckedChange={setIncluyeIva}
              />
              <div>
                <Label htmlFor="iva-switch" className="text-xs font-semibold cursor-pointer">
                  {incluyeIva ? 'Los precios incluyen IVA' : 'Los precios son antes de IVA'}
                </Label>
                <p className="text-[11px] text-muted-foreground">
                  {incluyeIva
                    ? 'Total = Σ(precio × cant); Subtotal = Total / 1.16'
                    : 'Subtotal = Σ(precio × cant); Total = Subtotal × 1.16 (fórmula del Excel)'}
                </p>
              </div>
            </div>

            {/* Selector de proveedores a comparar */}
            <div className="space-y-1.5">
              <span className="text-xs font-medium text-foreground block">Proveedores a comparar:</span>
              <div className="flex flex-wrap items-center gap-1.5">
                {proveedoresCatalogo.map((prov) => {
                  const activo = proveedoresSeleccionados.includes(prov);
                  return (
                    <button
                      key={prov}
                      type="button"
                      onClick={() => handleToggleProveedor(prov)}
                      className={`text-xs px-2.5 py-1 rounded-full border transition-colors ${
                        activo
                          ? 'bg-accent-blue/10 border-accent-blue text-accent-blue font-semibold dark:bg-accent-blue/20'
                          : 'bg-muted/40 border-border text-muted-foreground hover:bg-muted'
                      }`}
                    >
                      {prov}
                    </button>
                  );
                })}
              </div>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Renglones y Tabla de Comparación */}
      <Card className="border-border bg-card">
        <CardHeader className="pb-3 border-b border-border/50 flex flex-row items-center justify-between">
          <div>
            <CardTitle className="text-base font-semibold">Materiales a Cotizar</CardTitle>
            <CardDescription className="text-xs">
              Agrega los materiales y cantidades requeridos.
            </CardDescription>
          </div>
          <Button
            size="sm"
            onClick={handleAgregarRenglon}
            className="text-xs gap-1.5 h-8 bg-accent-blue text-white hover:bg-accent-blue/90"
          >
            <Plus className="h-3.5 w-3.5" />
            Agregar material
          </Button>
        </CardHeader>

        <CardContent className="pt-4 space-y-4">
          {renglones.length === 0 ? (
            <div className="text-center py-12 px-4 border border-dashed border-border/70 rounded-xl space-y-3">
              <Search className="h-8 w-8 text-muted-foreground mx-auto opacity-40" />
              <div className="space-y-1">
                <p className="text-sm font-medium text-foreground">No hay materiales en la lista</p>
                <p className="text-xs text-muted-foreground max-w-sm mx-auto">
                  Agrega materiales manualmente o haz clic en &quot;Cargar ejemplo del Excel&quot; para ver la comparación con los datos reales del cliente.
                </p>
              </div>
              <div className="flex justify-center gap-2 pt-2">
                <Button size="sm" onClick={handleAgregarRenglon} className="text-xs gap-1.5">
                  <Plus className="h-3.5 w-3.5" />
                  Agregar primer material
                </Button>
                <Button
                  size="sm"
                  variant="outline"
                  onClick={handleCargarEjemploExcel}
                  className="text-xs gap-1.5"
                >
                  <FileSpreadsheet className="h-3.5 w-3.5" />
                  Cargar ejemplo del Excel
                </Button>
              </div>
            </div>
          ) : (
            <div className="space-y-4">
              {/* Tabla responsive contenida */}
              <div className="overflow-x-auto rounded-lg border border-border">
                <table className="w-full text-xs text-left divide-y divide-border">
                  <thead className="bg-muted/50 text-foreground font-semibold">
                    <tr>
                      <th className="py-2.5 px-3 min-w-[240px]">Material</th>
                      <th className="py-2.5 px-2 w-24 text-right">Cant.</th>
                      {resultado.proveedores.map((p) => {
                        const esMejor = resultado.mejorProveedorCompleto?.proveedor === p.proveedor;
                        return (
                          <th
                            key={p.proveedor}
                            className={`py-2.5 px-3 min-w-[140px] text-right ${
                              esMejor ? 'bg-emerald-50/50 dark:bg-emerald-950/20' : ''
                            }`}
                          >
                            <div className="flex items-center justify-end gap-1">
                              {esMejor && <Award className="h-3.5 w-3.5 text-emerald-600 inline" />}
                              <span>{p.proveedor}</span>
                            </div>
                          </th>
                        );
                      })}
                      <th className="py-2.5 px-2 w-10 text-center"></th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-border/60 bg-card">
                    {renglones.map((renglon, idx) => {
                      return (
                        <tr key={renglon.id} className="hover:bg-muted/30 transition-colors">
                          <td className="py-2 px-3">
                            <Select
                              value={renglon.materialId}
                              onValueChange={(val) =>
                                handleCambiarRenglon(renglon.id, 'materialId', val)
                              }
                            >
                              <SelectTrigger className="text-xs h-8 bg-background">
                                <SelectValue />
                              </SelectTrigger>
                              <SelectContent className="max-h-64">
                                {materiales.map((m) => (
                                  <SelectItem key={m.id} value={m.id}>
                                    {m.nombre}
                                  </SelectItem>
                                ))}
                              </SelectContent>
                            </Select>
                          </td>
                          <td className="py-2 px-2 text-right">
                            <Input
                              type="number"
                              min="1"
                              value={renglon.cantidad}
                              onChange={(e) =>
                                handleCambiarRenglon(
                                  renglon.id,
                                  'cantidad',
                                  parseInt(e.target.value, 10) || 0
                                )
                              }
                              className="text-xs font-mono h-8 text-right w-20 ml-auto"
                            />
                          </td>

                          {/* Columnas de proveedores */}
                          {resultado.proveedores.map((p) => {
                            const item = p.renglones[idx];
                            const esMejor = resultado.mejorProveedorCompleto?.proveedor === p.proveedor;

                            if (!item || item.precioUnitario === null) {
                              return (
                                <td
                                  key={p.proveedor}
                                  className={`py-2 px-3 text-right text-muted-foreground italic ${
                                    esMejor ? 'bg-emerald-50/30 dark:bg-emerald-950/10' : ''
                                  }`}
                                >
                                  sin precio
                                </td>
                              );
                            }

                            return (
                              <td
                                key={p.proveedor}
                                className={`py-2 px-3 text-right font-mono ${
                                  esMejor ? 'bg-emerald-50/30 dark:bg-emerald-950/10' : ''
                                }`}
                              >
                                <div className="font-medium text-foreground">
                                  {formatearMoneda(item.importe)}
                                </div>
                                <div className="text-[10px] text-muted-foreground">
                                  {formatearMoneda(item.precioUnitario)} c/u
                                </div>
                              </td>
                            );
                          })}

                          <td className="py-2 px-2 text-center">
                            <Button
                              variant="ghost"
                              size="icon"
                              onClick={() => handleQuitarRenglon(renglon.id)}
                              className="h-7 w-7 text-muted-foreground hover:text-destructive"
                            >
                              <Trash2 className="h-3.5 w-3.5" />
                            </Button>
                          </td>
                        </tr>
                      );
                    })}
                  </tbody>

                  {/* Fila de Compra Mixta (Mejor por renglón) */}
                  <tbody className="border-t-2 border-border bg-accent-blue/5 dark:bg-accent-blue/10">
                    <tr>
                      <td colSpan={2} className="py-2 px-3 font-semibold text-accent-blue">
                        <div className="flex items-center gap-1.5">
                          <Sparkles className="h-3.5 w-3.5" />
                          Compra mixta (mejor precio por renglón)
                        </div>
                      </td>
                      {resultado.proveedores.map((p) => {
                        // Contar cuántos renglones ganó este proveedor
                        const ganados = resultado.mejorPorRenglon.renglones.filter(
                          (m) => m.proveedor === p.proveedor
                        ).length;
                        return (
                          <td key={p.proveedor} className="py-2 px-3 text-right text-[11px]">
                            {ganados > 0 ? (
                              <Badge variant="outline" className="text-[10px] bg-background">
                                {ganados} ítem{ganados > 1 ? 's' : ''} más barato
                              </Badge>
                            ) : (
                              <span className="text-muted-foreground">-</span>
                            )}
                          </td>
                        );
                      })}
                      <td></td>
                    </tr>
                  </tbody>

                  {/* Totales y Diferencias */}
                  <tfoot className="bg-muted/60 font-semibold divide-y divide-border/80">
                    {/* Subtotal */}
                    <tr>
                      <td colSpan={2} className="py-2 px-3 text-right text-muted-foreground">
                        Subtotal:
                      </td>
                      {resultado.proveedores.map((p) => (
                        <td key={p.proveedor} className="py-2 px-3 text-right font-mono">
                          {p.completo ? formatearMoneda(p.subtotal) : '-'}
                        </td>
                      ))}
                      <td></td>
                    </tr>

                    {/* IVA */}
                    <tr>
                      <td colSpan={2} className="py-2 px-3 text-right text-muted-foreground">
                        IVA (16%):
                      </td>
                      {resultado.proveedores.map((p) => (
                        <td key={p.proveedor} className="py-2 px-3 text-right font-mono">
                          {p.completo ? formatearMoneda(p.iva) : '-'}
                        </td>
                      ))}
                      <td></td>
                    </tr>

                    {/* Total */}
                    <tr className="text-sm font-bold bg-muted/80">
                      <td colSpan={2} className="py-2.5 px-3 text-right text-foreground">
                        TOTAL:
                      </td>
                      {resultado.proveedores.map((p) => {
                        const esMejor = resultado.mejorProveedorCompleto?.proveedor === p.proveedor;
                        return (
                          <td
                            key={p.proveedor}
                            className={`py-2.5 px-3 text-right font-mono text-base ${
                              esMejor
                                ? 'text-emerald-600 dark:text-emerald-400 font-extrabold bg-emerald-500/10'
                                : 'text-foreground'
                            }`}
                          >
                            {p.completo ? formatearMoneda(p.total) : 'Incompleto'}
                          </td>
                        );
                      })}
                      <td></td>
                    </tr>

                    {/* Diferencia contra el mejor */}
                    <tr className="text-xs">
                      <td colSpan={2} className="py-2 px-3 text-right text-muted-foreground">
                        Diferencia vs Mejor:
                      </td>
                      {resultado.proveedores.map((p) => {
                        if (!p.completo) {
                          return (
                            <td key={p.proveedor} className="py-2 px-3 text-right text-muted-foreground text-[11px]">
                              <div className="flex items-center justify-end gap-1 text-amber-600 dark:text-amber-400">
                                <AlertTriangle className="h-3 w-3 inline" />
                                sin precio para {p.materialesFaltantes.length}
                              </div>
                            </td>
                          );
                        }
                        if (p.proveedor === resultado.mejorProveedorCompleto?.proveedor) {
                          return (
                            <td key={p.proveedor} className="py-2 px-3 text-right">
                              <Badge className="bg-emerald-600 text-white hover:bg-emerald-600 text-[10px]">
                                ★ MÁS ECONÓMICO
                              </Badge>
                            </td>
                          );
                        }
                        return (
                          <td key={p.proveedor} className="py-2 px-3 text-right font-mono text-destructive">
                            + {formatearMoneda(p.diferenciaContraMejor || 0)}
                          </td>
                        );
                      })}
                      <td></td>
                    </tr>
                  </tfoot>
                </table>
              </div>

              {/* Resumen de Compra Mixta vs Mejor Proveedor */}
              {resultado.mejorPorRenglon.total > 0 && (
                <div className="p-4 rounded-xl border border-accent-blue/30 bg-accent-blue/5 dark:bg-accent-blue/10 flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                  <div className="space-y-1">
                    <div className="flex items-center gap-2">
                      <Sparkles className="h-4 w-4 text-accent-blue" />
                      <span className="text-sm font-semibold text-foreground">
                        Oportunidad de Compra Mixta
                      </span>
                    </div>
                    <p className="text-xs text-muted-foreground">
                      Comprando cada material al proveedor más barato el total es{' '}
                      <strong className="text-foreground font-mono">
                        {formatearMoneda(resultado.mejorPorRenglon.total)}
                      </strong>.
                    </p>
                  </div>

                  {resultado.mejorPorRenglon.ahorroContraMejorCompleto !== null &&
                    resultado.mejorPorRenglon.ahorroContraMejorCompleto > 0 && (
                      <div className="p-2.5 rounded-lg bg-emerald-500/10 border border-emerald-500/20 text-right">
                        <span className="text-[11px] text-emerald-700 dark:text-emerald-300 block">
                          Ahorro adicional vs mejor proveedor completo:
                        </span>
                        <span className="text-lg font-mono font-bold text-emerald-600 dark:text-emerald-400">
                          {formatearMoneda(resultado.mejorPorRenglon.ahorroContraMejorCompleto)}
                        </span>
                      </div>
                    )}
                </div>
              )}
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
